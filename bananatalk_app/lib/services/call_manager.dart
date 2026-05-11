import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/call_livekit_manager.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/notification_service.dart';

enum CallUiState {
  ringing,
  connecting,
  connected,
  reconnecting,
  poorConnection,
  ended,
}

enum CallQuality { good, fair, poor }

/// Duration limit for non-VIP users (5 minutes)
const int freeCallDurationSeconds = 5 * 60;
/// Warning before call ends (1 minute remaining)
const int freeCallWarningSeconds = 4 * 60;

/// Call lifecycle and signalling controller.
///
/// As of Step 8 this delegates media transport to [CallLiveKitManager]; the
/// legacy mesh WebRTC service was removed in C3. The public API surface
/// (singleton, callbacks, [initiateCall] / [acceptCall] / [rejectCall] /
/// [endCall], etc.) is preserved for upstream callers.
class CallManager with WidgetsBindingObserver {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  bool _appInForeground = true;

  // LiveKit transport (B2). Recreated on each call boundary via [_cleanup]
  // so a fresh listener is bound per session.
  CallLiveKitManager _liveKit = CallLiveKitManager();

  ChatSocketService? _chatSocketService;
  io.Socket? _socket;
  bool _isInitialized = false;
  AudioPlayer? _ringtonePlayer;
  AudioPlayer? _soundPlayer;
  Timer? _callTimeoutTimer;
  final CallKitService _callKitService = CallKitService();

  /// Set to true while [endCall] is in flight so we can distinguish a
  /// user-initiated teardown from a remote/peer-side disconnect inside the
  /// LiveKit `onLocalDisconnected` / `onPeerDisconnected` callbacks.
  bool _localTeardownInFlight = false;

  CallModel? currentCall;

  // Callbacks ----------------------------------------------------------------
  Function(CallModel)? onIncomingCall;
  Function(CallModel)? onCallAccepted;
  Function(CallModel)? onCallRejected;
  Function(CallModel)? onCallEnded;
  Function(String)? onCallError;

  // Peer state callbacks
  Function(bool)? onPeerMuteChanged;
  Function(bool)? onPeerVideoChanged;
  Function()? onPeerReconnecting;
  Function()? onPeerReconnected;
  Function()? onCallTimeout;
  Function()? onReconnecting;
  Function()? onReconnected;
  Function(CallModel)? onCallConnected;
  Function(int remainingSeconds)? onCallDurationWarning;
  Function()? onCallDurationLimitReached;

  // Connection state & quality
  CallUiState _connectionState = CallUiState.ringing;
  CallQuality _callQuality = CallQuality.good;
  Timer? _durationLimitTimer;
  Timer? _durationWarningTimer;
  bool _isVipCall = true; // default true (no limit), set to false for free users
  Function(CallUiState)? onConnectionStateChanged;
  Function(CallQuality)? onCallQualityChanged;

  CallUiState get connectionState => _connectionState;
  CallQuality get callQuality => _callQuality;

  /// LiveKit transport for the active call. UI reads this for
  /// VideoTrackRenderer wiring (see ActiveCallScreen).
  CallLiveKitManager get liveKit => _liveKit;

  bool get isInitialized => _isInitialized;

  // Local mute/video/speaker bookkeeping. LiveKit doesn't surface these as
  // sync getters on the local participant, so we cache the last value we
  // asked it for and expose it via the public booleans the UI already reads.
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    debugPrint('📞 App lifecycle: $state, foreground: $_appInForeground');
  }

  Future<void> initialize(ChatSocketService chatSocketService) async {
    // Register lifecycle observer
    WidgetsBinding.instance.removeObserver(this); // prevent duplicates
    WidgetsBinding.instance.addObserver(this);

    if (_isInitialized &&
        _chatSocketService == chatSocketService &&
        _socket == chatSocketService.socket) {
      debugPrint('📞 CallManager already initialized, skipping');
      return;
    }

    debugPrint(
      '📞 CallManager initializing (wasInit: $_isInitialized, '
      'socketMatch: ${_socket == chatSocketService.socket})',
    );

    _chatSocketService = chatSocketService;
    _socket = chatSocketService.socket;

    _removeSocketListeners();
    _setupSocketListeners();
    _initCallKit();
    _isInitialized = true;
    debugPrint(
      '📞 CallManager initialized, socket connected: ${_socket?.connected}',
    );
  }

  // -- Socket wiring --------------------------------------------------------

  void _removeSocketListeners() {
    _socket?.off('call:incoming');
    _socket?.off('call:accepted');
    _socket?.off('call:declined');
    _socket?.off('call:rejected'); // legacy alias from mesh era
    _socket?.off('call:ended');
    _socket?.off('call:missed');
    _socket?.off('call:timeout');
    _socket?.off('call:mute');
    _socket?.off('call:video-toggle');
    _socket?.off('call:peer-muted');
    _socket?.off('call:peer-video-toggled');
    _socket?.off('call:peer-reconnecting');
    _socket?.off('call:peer-reconnected');
  }

  void _setupSocketListeners() {
    if (_socket == null) {
      debugPrint('❌ Cannot setup call listeners — socket is null');
      return;
    }
    debugPrint('📞 Setting up call socket listeners');

    _socket!.on('call:incoming', _handleIncomingSocketEvent);

    _socket!.on('call:accepted', (data) {
      debugPrint('📞 call:accepted event received: $data');
      // We don't need a fresh token here — the caller already has its own
      // token from the /initiate response and is already connected to the
      // LiveKit room. Simply transition state and fire the UI callback.
      _callTimeoutTimer?.cancel();
      stopRingtone();

      if (currentCall == null) {
        debugPrint('❌ call:accepted but currentCall is null');
        return;
      }
      currentCall = currentCall!.copyWith(status: CallStatus.connecting);
      onCallAccepted?.call(currentCall!);
    });

    // call:declined is the new wire event (B1 spec); call:rejected is the
    // legacy mesh-era event still emitted by the socket handler. Treat both
    // the same way until the mesh socket handler is stubbed in B6.
    void onDecline(dynamic data) {
      debugPrint('📞 call:declined/rejected event received: $data');
      if (currentCall == null) return;
      currentCall = currentCall!.copyWith(status: CallStatus.rejected);
      onCallRejected?.call(currentCall!);
      _cleanup();
    }
    _socket!.on('call:declined', onDecline);
    _socket!.on('call:rejected', onDecline);

    _socket!.on('call:ended', (data) {
      debugPrint('📞 call:ended event received: $data');
      if (currentCall == null) return;
      final duration = data is Map ? data['duration'] : null;
      currentCall = currentCall!.copyWith(
        status: CallStatus.ended,
        endTime: DateTime.now(),
        duration:
            duration != null ? int.tryParse(duration.toString()) : null,
      );
      onCallEnded?.call(currentCall!);
      _cleanup();
    });

    _socket!.on('call:missed', (data) {
      if (currentCall == null) return;
      currentCall = currentCall!.copyWith(
        status: CallStatus.ended,
        endTime: DateTime.now(),
      );
      onCallEnded?.call(currentCall!);
      _cleanup();
    });

    _socket!.on('call:timeout', (data) {
      if (currentCall == null) return;
      currentCall = currentCall!.copyWith(status: CallStatus.missed);
      onCallTimeout?.call();
      _cleanup();
    });

    // Peer mute / video — preserved as the fast-path UI signal alongside
    // the LiveKit TrackMuted/Subscribed events (which arrive ~100ms later).
    // Backward compat: the legacy mesh handler used `call:mute` /
    // `call:video-toggle`; the new wire spec is `call:peer-muted` /
    // `call:peer-video-toggled`. Listen on both.
    void onPeerMute(dynamic data) {
      if (data is! Map) return;
      if (data['callId'] != currentCall?.callId) return;
      final isMuted = data['isMuted'] == true;
      if (currentCall != null) {
        currentCall = currentCall!.copyWith(isPeerMuted: isMuted);
      }
      onPeerMuteChanged?.call(isMuted);
    }
    _socket!.on('call:mute', onPeerMute);
    _socket!.on('call:peer-muted', onPeerMute);

    void onPeerVideo(dynamic data) {
      if (data is! Map) return;
      if (data['callId'] != currentCall?.callId) return;
      final enabled = data['isVideoEnabled'] == true;
      if (currentCall != null) {
        currentCall = currentCall!.copyWith(isPeerVideoEnabled: enabled);
      }
      onPeerVideoChanged?.call(enabled);
    }
    _socket!.on('call:video-toggle', onPeerVideo);
    _socket!.on('call:peer-video-toggled', onPeerVideo);

    _socket!.on('call:peer-reconnecting', (data) {
      if (data is Map && data['callId'] == currentCall?.callId) {
        onPeerReconnecting?.call();
      }
    });

    _socket!.on('call:peer-reconnected', (data) {
      if (data is Map && data['callId'] == currentCall?.callId) {
        onPeerReconnected?.call();
      }
    });
  }

  Future<void> _handleIncomingSocketEvent(dynamic data) async {
    debugPrint('📞 call:incoming event received: $data');

    if (currentCall != null) {
      debugPrint('📞 Already in a call, replying busy');
      // Tell the caller we're busy so their ringback stops immediately
      // instead of running the full 45s timeout.
      try {
        final incomingCallId = (data is Map ? data['callId'] : null)?.toString();
        if (incomingCallId != null && incomingCallId.isNotEmpty) {
          unawaited(ApiClient().post('calls/$incomingCallId/decline'));
        }
      } catch (e) {
        debugPrint('📞 busy reply failed: $e');
      }
      return;
    }

    try {
      final call = CallModel.fromJson(
        Map<String, dynamic>.from(data as Map),
        CallDirection.incoming,
      );
      currentCall = call;
      startRingtone();

      debugPrint(
        '📞 Parsed incoming call from ${call.userName}, '
        'foreground: $_appInForeground, hasCallback: ${onIncomingCall != null}',
      );

      if (_appInForeground && onIncomingCall != null) {
        // Foreground: Flutter overlay screen handles UI; avoid the duplicate
        // native CallKit prompt.
        onIncomingCall!(call);
      } else {
        _callKitService.showIncomingCall(
          callId: call.callId,
          callerName: call.userName,
          callerAvatar: call.userProfilePicture,
          isVideo: call.callType == CallType.video,
        );
        // Still fire the callback so if the user brings the app to
        // foreground mid-ring they see the in-app screen too.
        onIncomingCall?.call(call);
      }
    } catch (e) {
      debugPrint('❌ Failed to parse incoming call: $e');
      onCallError?.call('Failed to parse incoming call');
    }
  }

  // -- LiveKit wiring -------------------------------------------------------

  void _setupLiveKitCallbacks() {
    _liveKit.onPeerConnected = () {
      debugPrint('📞 LiveKit: peer connected');
      // Transport-level confirmation only — UI already knows the call is
      // accepted because /accept returned (or call:accepted arrived). No
      // additional callback to fire.
      if (currentCall != null && currentCall!.status != CallStatus.connected) {
        currentCall = currentCall!.copyWith(status: CallStatus.connected);
        _applySpeakerDefault(currentCall!.callType);
        _playConnectSound();
        _startDurationLimit();
        _updateConnectionState(CallUiState.connected);
        onCallConnected?.call(currentCall!);
      }
    };

    _liveKit.onPeerDisconnected = () {
      debugPrint('📞 LiveKit: peer disconnected');
      // If we didn't initiate the teardown, treat it as the remote side
      // hanging up (or crashing).
      if (!_localTeardownInFlight && currentCall != null) {
        currentCall = currentCall!.copyWith(
          status: CallStatus.ended,
          endTime: DateTime.now(),
        );
        onCallEnded?.call(currentCall!);
        _cleanup();
      }
    };

    _liveKit.onPeerMuteChanged = (muted) {
      debugPrint('📞 LiveKit: peer mute → $muted');
      if (currentCall != null) {
        currentCall = currentCall!.copyWith(isPeerMuted: muted);
      }
      onPeerMuteChanged?.call(muted);
    };

    _liveKit.onPeerVideoChanged = (enabled) {
      debugPrint('📞 LiveKit: peer video → $enabled');
      if (currentCall != null) {
        currentCall = currentCall!.copyWith(isPeerVideoEnabled: enabled);
      }
      onPeerVideoChanged?.call(enabled);
    };

    _liveKit.onConnectionQualityChanged = (quality) {
      final mapped = _mapLiveKitQuality(quality);
      if (mapped == _callQuality) return;
      _callQuality = mapped;
      debugPrint('📞 LiveKit: quality → $quality (mapped $mapped)');
      onCallQualityChanged?.call(mapped);
      if (mapped == CallQuality.poor &&
          _connectionState == CallUiState.connected) {
        _updateConnectionState(CallUiState.poorConnection);
      } else if (mapped != CallQuality.poor &&
          _connectionState == CallUiState.poorConnection) {
        _updateConnectionState(CallUiState.connected);
      }
    };

    _liveKit.onReconnecting = () {
      debugPrint('📞 LiveKit: reconnecting');
      _updateConnectionState(CallUiState.reconnecting);
      onReconnecting?.call();
      onPeerReconnecting?.call();
    };

    _liveKit.onReconnected = () {
      debugPrint('📞 LiveKit: reconnected');
      _updateConnectionState(CallUiState.connected);
      onReconnected?.call();
      onPeerReconnected?.call();
    };

    _liveKit.onLocalDisconnected = () {
      debugPrint('📞 LiveKit: local disconnected '
          '(localTeardown=$_localTeardownInFlight)');
      if (!_localTeardownInFlight && currentCall != null) {
        currentCall = currentCall!.copyWith(
          status: CallStatus.ended,
          endTime: DateTime.now(),
        );
        onCallEnded?.call(currentCall!);
        _cleanup();
      }
    };
  }

  CallQuality _mapLiveKitQuality(lk.ConnectionQuality quality) {
    switch (quality) {
      case lk.ConnectionQuality.excellent:
      case lk.ConnectionQuality.good:
        return CallQuality.good;
      case lk.ConnectionQuality.poor:
      case lk.ConnectionQuality.lost:
        return CallQuality.poor;
      default:
        return CallQuality.fair;
    }
  }

  void _updateConnectionState(CallUiState newState) {
    if (_connectionState == newState) return;
    _connectionState = newState;
    debugPrint('📞 Connection state: $newState');
    onConnectionStateChanged?.call(newState);
  }

  // -- CallKit wiring --------------------------------------------------------

  void _initCallKit() {
    _callKitService.initialize();

    _callKitService.onAccepted = (callId) {
      debugPrint('📱 CallKit accepted: $callId');
      if (currentCall == null) return;
      stopRingtone();
      acceptCall().then((_) {
        final navState = callOverlayNavigatorKey.currentState;
        if (navState != null && currentCall != null) {
          navState.push(
            MaterialPageRoute(
              builder: (_) => ActiveCallScreen(call: currentCall!),
              fullscreenDialog: true,
            ),
          );
        }
      });
    };

    _callKitService.onDeclined = (callId) {
      debugPrint('📱 CallKit declined: $callId');
      if (currentCall == null) return;
      stopRingtone();
      rejectCall();
    };

    _callKitService.onEnded = (callId) {
      debugPrint('📱 CallKit ended: $callId');
      if (currentCall != null) endCall();
    };
  }

  // -- Public API: lifecycle ------------------------------------------------

  /// Start an outgoing call. Hits `POST /calls/initiate`, joins the returned
  /// LiveKit room with the caller token, and pushes [ActiveCallScreen] for
  /// the local user. The ringback tone runs until the receiver accepts.
  Future<void> initiateCall(
    String targetUserId,
    String targetUserName,
    String? targetUserProfilePicture,
    CallType callType,
  ) async {
    debugPrint('[Call] initiateCall target=$targetUserId type=$callType');
    try {
      // Permissions — same UX as before so existing error strings keep
      // surfacing through the UI's permission-handling flow.
      final ok = await _ensureCallPermissions(callType == CallType.video);
      if (!ok) {
        final err = await _buildPermissionError(callType, accepting: false);
        onCallError?.call(err);
        throw Exception(err);
      }

      // Provisional CallModel — we replace it with the server-authoritative
      // one as soon as POST /initiate returns.
      currentCall = CallModel(
        callId: '',
        userId: targetUserId,
        userName: targetUserName,
        userProfilePicture: targetUserProfilePicture,
        callType: callType,
        direction: CallDirection.outgoing,
        status: CallStatus.ringing,
        startTime: DateTime.now(),
      );

      final res = await ApiClient().post(
        'calls/initiate',
        body: {
          'receiverId': targetUserId,
          'type': callType.name, // 'audio' | 'video'
        },
      );

      if (!res.success || res.data is! Map) {
        final err = res.error ?? 'Failed to initiate call';
        onCallError?.call(err);
        _cleanup();
        throw Exception(err);
      }

      final data = Map<String, dynamic>.from(res.data as Map);
      final callJson = data['call'];
      final token = data['token']?.toString();
      final url = data['url']?.toString();
      final roomName = data['roomName']?.toString();

      if (token == null || url == null) {
        const err = 'Server response missing LiveKit token/url';
        onCallError?.call(err);
        _cleanup();
        throw Exception(err);
      }

      if (callJson is Map) {
        final parsed = CallModel.fromJson(
          Map<String, dynamic>.from(callJson),
          CallDirection.outgoing,
        );
        currentCall = parsed.copyWith(
          // Keep the UI's intent — server may not echo these the same way.
          userName: targetUserName,
          userProfilePicture: targetUserProfilePicture,
          livekitToken: token,
          livekitUrl: url,
          roomName: roomName,
          startTime: currentCall?.startTime ?? DateTime.now(),
        );
      } else {
        currentCall = currentCall!.copyWith(
          livekitToken: token,
          livekitUrl: url,
          roomName: roomName,
        );
      }

      // Bring up the LiveKit room. We connect *before* the receiver answers
      // so that the moment they accept, both peers are already in the room.
      _liveKit = CallLiveKitManager();
      _setupLiveKitCallbacks();
      try {
        await _liveKit.connect(url: url, token: token, type: callType);
      } catch (e) {
        debugPrint('❌ LiveKit connect failed: $e');
        onCallError?.call('Failed to connect to call');
        _cleanup();
        rethrow;
      }
      // Cache initial local track state.
      _isMuted = false;
      _isVideoEnabled = callType == CallType.video;

      // Outgoing ringback while we wait for acceptance.
      startRingback();

      // 45s no-answer timeout — preserved from mesh era.
      _callTimeoutTimer?.cancel();
      _callTimeoutTimer = Timer(const Duration(seconds: 45), () {
        debugPrint('📞 Call timeout — no answer after 45s');
        if (currentCall != null &&
            currentCall!.status == CallStatus.ringing) {
          onCallTimeout?.call();
          endCall();
        }
      });
    } catch (e) {
      if (onCallError != null && e is! TimeoutException) {
        final s = e.toString();
        if (s.contains('PERMANENTLY_DENIED:') || s.contains('DENIED:')) {
          onCallError!(s.replaceAll('Exception: ', ''));
        } else {
          onCallError!('Failed to start call: $s');
        }
      }
      _cleanup();
      rethrow;
    }
  }

  /// Accept the currently ringing incoming call. Hits `POST /calls/:id/accept`
  /// for the authoritative state transition and a fresh LiveKit token, then
  /// joins the room.
  Future<void> acceptCall() async {
    debugPrint('📞 acceptCall, currentCall: ${currentCall?.callId}');
    stopRingtone();
    if (currentCall == null) return;

    try {
      final ok = await _ensureCallPermissions(
        currentCall!.callType == CallType.video,
      );
      if (!ok) {
        final err = await _buildPermissionError(
          currentCall!.callType,
          accepting: true,
        );
        rejectCall();
        onCallError?.call(err);
        return;
      }

      final res = await ApiClient().post('calls/${currentCall!.callId}/accept');
      if (!res.success || res.data is! Map) {
        final err = res.error ?? 'Failed to accept call';
        onCallError?.call(err);
        rejectCall();
        return;
      }

      final data = Map<String, dynamic>.from(res.data as Map);
      final token = data['token']?.toString();
      final url = data['url']?.toString();
      if (token == null || url == null) {
        const err = 'Server accept response missing LiveKit token/url';
        onCallError?.call(err);
        rejectCall();
        return;
      }

      currentCall = currentCall!.copyWith(
        status: CallStatus.connecting,
        livekitToken: token,
        livekitUrl: url,
      );

      _liveKit = CallLiveKitManager();
      _setupLiveKitCallbacks();
      try {
        await _liveKit.connect(
          url: url,
          token: token,
          type: currentCall!.callType,
        );
      } catch (e) {
        debugPrint('❌ LiveKit connect failed: $e');
        onCallError?.call('Failed to connect to call');
        _cleanup();
        return;
      }

      _isMuted = false;
      _isVideoEnabled = currentCall!.callType == CallType.video;

      onCallAccepted?.call(currentCall!);
    } catch (e) {
      debugPrint('❌ acceptCall error: $e');
      rejectCall();
    }
  }

  /// Decline an incoming ringing call. Hits `POST /calls/:id/decline` and
  /// tears down local state. No LiveKit connect happens.
  void rejectCall() {
    debugPrint('[Call] rejectCall callId=${currentCall?.callId}');
    if (currentCall == null) return;
    final callId = currentCall!.callId;

    // Fire-and-forget — the receiver has already torn down locally and the
    // caller is notified via the socket emit from the controller. If the
    // request fails, the call will time out caller-side anyway.
    if (callId.isNotEmpty) {
      unawaited(ApiClient().post('calls/$callId/decline'));
    }

    currentCall = currentCall!.copyWith(status: CallStatus.rejected);
    onCallRejected?.call(currentCall!);
    _cleanup();
  }

  /// End the active or ringing call from the local side. Hits
  /// `POST /calls/:id/end` and disconnects the LiveKit room.
  void endCall() {
    debugPrint('[Call] endCall callId=${currentCall?.callId}');
    if (currentCall == null) return;

    _playEndSound();
    _localTeardownInFlight = true;

    final callId = currentCall!.callId;
    if (callId.isNotEmpty) {
      unawaited(ApiClient().post('calls/$callId/end'));
    }

    final duration =
        DateTime.now().difference(currentCall!.startTime).inSeconds;
    currentCall = currentCall!.copyWith(
      status: CallStatus.ended,
      endTime: DateTime.now(),
      duration: duration,
    );

    onCallEnded?.call(currentCall!);
    _cleanup();
  }

  // -- Public API: media controls -------------------------------------------

  /// Set the local mic mute state and broadcast to the peer on the socket
  /// for snappy cross-client UI (LiveKit's own TrackMuted reaches the peer
  /// ~100ms later).
  void setMuted(bool muted) {
    _isMuted = muted;
    _liveKit.setMuted(muted);
    _emitPeerMute(muted);
  }

  /// Toggle wrapper preserved for legacy UI bindings.
  void toggleMute() => setMuted(!_isMuted);

  /// Enable / disable the local camera (publishes/unpublishes the video
  /// track). Emits a socket hint for instant peer UI.
  void setVideoEnabled(bool enabled) {
    _isVideoEnabled = enabled;
    _liveKit.setCameraEnabled(enabled);
    _emitPeerVideo(enabled);
  }

  /// Toggle wrapper preserved for legacy UI bindings.
  void toggleVideo() => setVideoEnabled(!_isVideoEnabled);

  /// Route audio to the loudspeaker (true) or earpiece (false).
  Future<void> setSpeakerOn(bool on) async {
    _isSpeakerOn = on;
    try {
      await lk.Hardware.instance.setSpeakerphoneOn(on);
    } catch (e) {
      debugPrint('🔊 setSpeakerphoneOn failed: $e');
    }
  }

  /// Toggle wrapper preserved for legacy UI bindings.
  Future<void> toggleSpeaker() => setSpeakerOn(!_isSpeakerOn);

  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;

  /// Flip front/back camera. LiveKit exposes [setCameraPosition] as an
  /// extension on [LocalVideoTrack], which restarts the track with the
  /// new device. We toggle relative to [_isFrontCamera].
  bool _isFrontCamera = true;
  Future<void> switchCamera() async {
    final local = _liveKit.room?.localParticipant;
    if (local == null) return;
    for (final pub in local.videoTrackPublications) {
      final track = pub.track;
      if (track is lk.LocalVideoTrack) {
        try {
          final next = _isFrontCamera
              ? lk.CameraPosition.back
              : lk.CameraPosition.front;
          await track.setCameraPosition(next);
          _isFrontCamera = !_isFrontCamera;
        } catch (e) {
          debugPrint('📞 switchCamera failed: $e');
        }
        return;
      }
    }
  }

  /// Set whether the current call is from a VIP user (no duration limit).
  void setVipCall(bool isVip) {
    _isVipCall = isVip;
  }

  // -- Internals: signalling helpers ----------------------------------------

  void _emitPeerMute(bool muted) {
    if (_socket == null || currentCall == null) return;
    _socket!.emit('call:peer-muted', {
      'callId': currentCall!.callId,
      'isMuted': muted,
    });
    // Backward-compat: send the legacy event name too until B6 stubs out
    // the old socket handler.
    _socket!.emit('call:mute', {
      'callId': currentCall!.callId,
      'isMuted': muted,
    });
  }

  void _emitPeerVideo(bool enabled) {
    if (_socket == null || currentCall == null) return;
    _socket!.emit('call:peer-video-toggled', {
      'callId': currentCall!.callId,
      'isVideoEnabled': enabled,
    });
    _socket!.emit('call:video-toggle', {
      'callId': currentCall!.callId,
      'isVideoEnabled': enabled,
    });
  }

  // -- Internals: duration limits, sounds, permissions ----------------------

  void _startDurationLimit() {
    if (_isVipCall) return;
    _durationWarningTimer?.cancel();
    _durationLimitTimer?.cancel();

    _durationWarningTimer = Timer(
      const Duration(seconds: freeCallWarningSeconds),
      () {
        debugPrint('📞 Call duration warning — 1 minute remaining');
        onCallDurationWarning
            ?.call(freeCallDurationSeconds - freeCallWarningSeconds);
      },
    );
    _durationLimitTimer = Timer(
      const Duration(seconds: freeCallDurationSeconds),
      () {
        debugPrint('📞 Call duration limit reached — ending call');
        onCallDurationLimitReached?.call();
        endCall();
      },
    );
  }

  Future<void> _applySpeakerDefault(CallType callType) async {
    final shouldEnable = callType == CallType.video;
    await setSpeakerOn(shouldEnable);
  }

  /// Ensure microphone (and optionally camera) permissions are granted.
  /// Returns true iff all required permissions are granted after the request.
  /// Replaces the legacy mesh-WebRTC permissions helper that was retired in
  /// C3 — same semantics, just inlined onto `permission_handler`.
  Future<bool> _ensureCallPermissions(bool isVideo) async {
    final micStatus = await Permission.microphone.status;
    final cameraStatus = isVideo
        ? await Permission.camera.status
        : PermissionStatus.granted;

    if (micStatus.isGranted && cameraStatus.isGranted) return true;

    // Don't re-prompt if the user has permanently denied — UI surfaces a
    // settings deep-link via _buildPermissionError instead.
    if (micStatus.isPermanentlyDenied ||
        (isVideo && cameraStatus.isPermanentlyDenied)) {
      return false;
    }

    final statuses = await [
      Permission.microphone,
      if (isVideo) Permission.camera,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<String> _buildPermissionError(
    CallType callType, {
    required bool accepting,
  }) async {
    final micStatus = await Permission.microphone.status;
    final cameraStatus = callType == CallType.video
        ? await Permission.camera.status
        : PermissionStatus.granted;

    final verb = accepting ? 'answer' : 'make';
    final scope = callType == CallType.video ? 'video calls' : 'calls';

    if (callType == CallType.video) {
      if (micStatus.isPermanentlyDenied && cameraStatus.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable microphone and camera '
            'access in Settings to $verb $scope.';
      }
      if (micStatus.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable microphone access in '
            'Settings to $verb calls.';
      }
      if (cameraStatus.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable camera access in Settings '
            'to $verb video calls.';
      }
      if (!micStatus.isGranted) {
        return 'DENIED:Microphone permission is required to $verb calls.';
      }
      return 'DENIED:Camera permission is required to $verb video calls.';
    }

    if (micStatus.isPermanentlyDenied) {
      return 'PERMANENTLY_DENIED:Please enable microphone access in Settings '
          'to $verb calls.';
    }
    return 'DENIED:Microphone permission is required to $verb calls.';
  }

  // -- Ringtones ------------------------------------------------------------

  Future<void> startRingtone() async {
    try {
      _ringtonePlayer?.dispose();
      _ringtonePlayer = AudioPlayer();
      await _ringtonePlayer!.setAsset('assets/sounds/ringtone.m4a');
      await _ringtonePlayer!.setLoopMode(LoopMode.one);
      await _ringtonePlayer!.play();
      debugPrint('🔔 Ringtone started');
    } catch (e) {
      debugPrint('🔔 Failed to play ringtone: $e');
    }
  }

  Future<void> startRingback() async {
    try {
      _ringtonePlayer?.dispose();
      _ringtonePlayer = AudioPlayer();
      await _ringtonePlayer!.setAsset('assets/sounds/ringback.m4a');
      await _ringtonePlayer!.setLoopMode(LoopMode.one);
      await _ringtonePlayer!.play();
      debugPrint('🔔 Ringback started');
    } catch (e) {
      debugPrint('🔔 Failed to play ringback: $e');
    }
  }

  Future<void> _playConnectSound() async {
    try {
      _soundPlayer?.dispose();
      _soundPlayer = AudioPlayer();
      await _soundPlayer!.setAsset('assets/sounds/call_connect.m4a');
      await _soundPlayer!.play();
    } catch (e) {
      debugPrint('🔔 Failed to play connect sound: $e');
    }
  }

  Future<void> _playEndSound() async {
    try {
      _soundPlayer?.dispose();
      _soundPlayer = AudioPlayer();
      await _soundPlayer!.setAsset('assets/sounds/call_end.m4a');
      await _soundPlayer!.play();
    } catch (e) {
      debugPrint('🔔 Failed to play end sound: $e');
    }
  }

  Future<void> stopRingtone() async {
    try {
      await _ringtonePlayer?.stop();
      _ringtonePlayer?.dispose();
      _ringtonePlayer = null;
      debugPrint('🔔 Ringtone stopped');
    } catch (e) {
      debugPrint('🔔 Failed to stop ringtone: $e');
    }
  }

  // -- Cleanup --------------------------------------------------------------

  void _cleanup() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
    _durationWarningTimer?.cancel();
    _durationWarningTimer = null;
    _durationLimitTimer?.cancel();
    _durationLimitTimer = null;
    _isVipCall = true;
    _connectionState = CallUiState.ringing;
    _callQuality = CallQuality.good;
    _isMuted = false;
    _isVideoEnabled = true;
    _isSpeakerOn = false;
    stopRingtone();
    _soundPlayer?.dispose();
    _soundPlayer = null;
    _callKitService.endAllCalls();
    NotificationService().cancelCallNotification();
    currentCall = null;

    // Tear down LiveKit transport. Disconnect is async but we don't await
    // (it can take a beat on flaky networks) — the next call will create a
    // fresh CallLiveKitManager regardless.
    final oldLiveKit = _liveKit;
    _liveKit = CallLiveKitManager();
    unawaited(oldLiveKit.disconnect());

    _localTeardownInFlight = false;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
  }
}
