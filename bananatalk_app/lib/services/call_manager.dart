import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_platform.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/call_livekit_manager.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';

enum CallUiState { ringing, connecting, connected, reconnecting, poorConnection, ended }

enum CallQuality { good, fair, poor }

/// Why a call left this device.
enum CallExitReason {
  localHangUp,
  declined,
  remoteState,
  answeredElsewhere,
  acceptConflict,
  connectionLost,
  error,
}

/// Where an incoming call was first heard about (socket, FCM, a tapped
/// notification, resume recovery, or CallKit). Used for dedupe decisions.
enum IncomingSource { socket, push, notificationTap, recovery, callKit }

enum InitiateStatus { started, calleeBusy, callerBusy, permissionDenied, failed }

/// What a tapped incoming-call notification should open.
enum IncomingTapAction { showCall, openChat }

class InitiateResult {
  const InitiateResult(this.status, [this.error]);
  final InitiateStatus status;
  final String? error;
}

/// Emitted exactly once per call when it leaves this device.
class CallFinish {
  const CallFinish({required this.call, required this.reason, this.outcome});
  final CallModel call;
  final CallExitReason reason;
  final CallOutcome? outcome;
}

class CallManagerDeps {
  const CallManagerDeps({
    required this.api,
    required this.platform,
    required this.liveKitFactory,
    required this.closeCallScreens,
    required this.openActiveCall,
    required this.openIncomingCall,
  });

  factory CallManagerDeps.production() => CallManagerDeps(
        api: RestCallApi(),
        platform: DeviceCallPlatform(),
        liveKitFactory: CallLiveKitManager.new,
        closeCallScreens: CallRoutes.closeAll,
        openActiveCall: CallRoutes.openActive,
        openIncomingCall: CallRoutes.openIncoming,
      );

  final CallApi api;
  final CallPlatform platform;
  final CallLiveKitManager Function() liveKitFactory;
  final void Function() closeCallScreens;
  final void Function(CallModel call) openActiveCall;
  final void Function(CallModel call) openIncomingCall;
}

/// How long the caller sees "No answer" / "Declined" before the screen closes.
const Duration kOutcomeBannerDuration = Duration(milliseconds: 1500);

/// Ringing out with no call:state (socket down): ask the server after this.
const Duration kRingSafetyTimeout = Duration(seconds: 50);

/// The server treats a call still `ringing` after this long as stale
/// (`timing.staleRingingMs`); GET /calls/:id may still report it ringing.
const Duration kStaleRinging = Duration(seconds: 60);

/// 1:1 call controller — a FOLLOWER of the server's call state.
///
/// The server decides every transition (spec §4.1); this class reacts to
/// `call:state` for its own `callId` only, and leaves a call through one
/// path, [_finish], which runs at most once per call and always closes the
/// call screens.
class CallManager with WidgetsBindingObserver {
  static CallManager _instance = CallManager._internal(CallManagerDeps.production());
  factory CallManager() => _instance;
  CallManager._internal(this._deps) : _liveKit = _deps.liveKitFactory();

  @visibleForTesting
  factory CallManager.forTest(CallManagerDeps deps) => CallManager._internal(deps);

  @visibleForTesting
  static void debugSetInstance(CallManager manager) => _instance = manager;

  final CallManagerDeps _deps;
  CallLiveKitManager _liveKit;
  io.Socket? _socket;
  StreamSubscription<io.Socket>? _socketReplacedSub;
  bool _isInitialized = false;
  bool _appInForeground = true;

  CallModel? currentCall;
  String? _acceptingCallId;
  String? _incomingShownFor;
  final List<String> _recentlyFinished = [];
  Timer? _closeTimer;
  Timer? _ringSafetyTimer;
  bool _recovering = false;

  final StreamController<CallFinish> _finishController = StreamController<CallFinish>.broadcast();

  /// Every call that leaves this device, once.
  Stream<CallFinish> get finishes => _finishController.stream;

  // Callbacks ----------------------------------------------------------------
  Function(CallModel)? onIncomingCall;
  Function(CallModel)? onCallAccepted;
  Function(CallModel)? onCallRejected;
  Function(CallModel)? onCallEnded;
  void Function(CallFinish)? onCallFinished;
  Function(String)? onCallError;
  Function(bool)? onPeerMuteChanged;
  Function(bool)? onPeerVideoChanged;
  Function()? onPeerReconnecting;
  Function()? onPeerReconnected;
  Function()? onReconnecting;
  Function()? onReconnected;
  Function(CallModel)? onCallConnected;
  Function(CallUiState)? onConnectionStateChanged;
  Function(CallQuality)? onCallQualityChanged;

  CallUiState _connectionState = CallUiState.ringing;
  CallQuality _callQuality = CallQuality.good;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  bool _isFrontCamera = true;

  CallUiState get connectionState => _connectionState;
  CallQuality get callQuality => _callQuality;
  CallLiveKitManager get liveKit => _liveKit;
  bool get isInitialized => _isInitialized;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;

  /// The only socket events a call listens to. Everything else (accepted,
  /// declined, ended, missed, timeout) arrives as call:state.
  static const List<String> socketEvents = [
    'call:incoming',
    'call:state',
    'call:mute',
    'call:peer-muted',
    'call:video-toggle',
    'call:peer-video-toggled',
    'call:peer-reconnecting',
    'call:peer-reconnected',
  ];

  Future<void> initialize(ChatSocketService chatSocketService) async {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    attachSocketService(chatSocketService);
    if (!_isInitialized) _initCallKit();
    _isInitialized = true;
  }

  /// Follow the chat socket across replacements. ChatSocketService replaces
  /// its socket on resume, token refresh and login; binding once (the old
  /// behaviour) left the app deaf to call:incoming after the first resume.
  void attachSocketService(ChatSocketService service) {
    _socketReplacedSub?.cancel();
    _socketReplacedSub = service.onSocketReplaced.listen(bindSocket);
    bindSocket(service.socket);
  }

  /// Move the call listeners onto [socket] (and off the previous one).
  void bindSocket(io.Socket? socket) {
    if (identical(socket, _socket)) return;
    final previous = _socket;
    if (previous != null) {
      for (final event in socketEvents) {
        previous.off(event);
      }
    }
    _socket = socket;
    if (socket == null) return;
    for (final event in socketEvents) {
      socket.on(event, (data) => handleSocketEvent(event, data));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) unawaited(recoverCallState());
  }

  // -- Socket ----------------------------------------------------------------

  @visibleForTesting
  Future<void> handleSocketEvent(String event, dynamic data) async {
    if (data is! Map) return;
    final m = Map<String, dynamic>.from(data);
    switch (event) {
      case 'call:incoming':
        await handleIncoming(m, source: IncomingSource.socket);
        return;
      case 'call:state':
        await _onCallState(m);
        return;
    }
    final cur = currentCall;
    if (cur == null || !_sameId(m['callId']?.toString(), cur.callId)) return;
    switch (event) {
      case 'call:mute':
      case 'call:peer-muted':
        final muted = m['isMuted'] == true;
        currentCall = cur.copyWith(isPeerMuted: muted);
        onPeerMuteChanged?.call(muted);
      case 'call:video-toggle':
      case 'call:peer-video-toggled':
        final on = m['isVideoEnabled'] == true;
        currentCall = cur.copyWith(isPeerVideoEnabled: on);
        onPeerVideoChanged?.call(on);
      case 'call:peer-reconnecting':
        onPeerReconnecting?.call();
      case 'call:peer-reconnected':
        onPeerReconnected?.call();
    }
  }

  /// An incoming call from any source. The same callId from a second source
  /// only fills in missing fields — one incoming UI per call.
  Future<void> handleIncoming(
    Map<String, dynamic> payload, {
    IncomingSource source = IncomingSource.socket,
  }) async {
    final call = CallModel.fromJson(payload, CallDirection.incoming);
    if (call.callId.isEmpty) return;
    final cur = currentCall;
    if (cur != null) {
      if (_sameId(cur.callId, call.callId)) {
        currentCall = cur.copyWith(
          callUuid: cur.callUuid ?? call.callUuid,
          livekitUrl: cur.livekitUrl ?? call.livekitUrl,
          roomName: cur.roomName ?? call.roomName,
        );
        if (source == IncomingSource.notificationTap && cur.status == CallStatus.ringing) {
          _showIncoming(currentCall!);
        }
      }
      return;
    }
    if (_recentlyFinished.any((id) => _sameId(id, call.callId))) return;

    _takeOverClosingScreens();
    currentCall = call.copyWith(status: CallStatus.ringing);
    onIncomingCall?.call(currentCall!);
    if (_appInForeground || source == IncomingSource.notificationTap) {
      unawaited(_deps.platform.startRingtone());
      _showIncoming(currentCall!);
    } else {
      await _deps.platform.showIncomingCallUi(currentCall!);
    }
  }

  void _showIncoming(CallModel call) {
    if (_sameId(_incomingShownFor, call.callId)) return;
    _incomingShownFor = call.callId;
    _deps.openIncomingCall(call);
  }

  /// call_cancelled (FCM data push, or relayed from a VoIP push): the call
  /// left ringing elsewhere (accepted / declined on another device, the
  /// caller cancelled, or it timed out).
  Future<void> handleCallCancelled(Map<String, dynamic> data) async {
    final callId = data['callId']?.toString() ?? '';
    final callUuid = data['callUuid']?.toString();
    final cur = currentCall;
    if (cur != null && (_sameId(cur.callId, callId) || CallKitIds.same(cur.callUuid, callUuid))) {
      // Answering on this device (accept in flight or connecting): the cancel
      // is the server telling the other devices; ignore it here.
      if (cur.status == CallStatus.ringing && !_sameId(_acceptingCallId, cur.callId)) {
        await _finish(CallExitReason.remoteState);
      }
      return;
    }
    // Not our current call: it may still be ringing in CallKit, or its invite
    // may arrive late — end the UI and ignore a later invite for it.
    _remember(callId);
    await _quietly(() => _deps.platform.endCallUi(CallModel(
          callId: callId,
          callUuid: callUuid,
          userId: '',
          userName: '',
          callType: CallType.audio,
          direction: CallDirection.incoming,
          startTime: DateTime.now(),
        )));
  }

  /// A tapped incoming-call notification may be minutes old: only show the
  /// call if the server says it is still ringing; otherwise open the chat.
  Future<IncomingTapAction> resolveIncomingTap(Map<String, dynamic> data) async {
    final callId = data['callId']?.toString() ?? '';
    if (callId.isEmpty) return IncomingTapAction.openChat;
    final cur = currentCall;
    if (cur != null && _sameId(cur.callId, callId)) {
      if (cur.status == CallStatus.ringing) _showIncoming(cur);
      return IncomingTapAction.showCall;
    }
    final res = await _deps.api.get(callId);
    if (!res.ok || res.data['status']?.toString() != 'ringing') return IncomingTapAction.openChat;
    final started = DateTime.tryParse(res.data['startTime']?.toString() ?? '');
    if (started != null && DateTime.now().difference(started) > kStaleRinging) {
      return IncomingTapAction.openChat;
    }
    await handleIncoming(_tapPayload(data, res.data), source: IncomingSource.notificationTap);
    return _sameId(currentCall?.callId, callId) ? IncomingTapAction.showCall : IncomingTapAction.openChat;
  }

  /// IncomingCallScreen's 50 s safety net: the server ends a ringing call at
  /// 45 s, so a call still ringing here at 50 s lost its call:state.
  Future<bool> expireIncoming(String callId) async {
    final cur = currentCall;
    if (cur == null || !_sameId(cur.callId, callId) || cur.status != CallStatus.ringing) return false;
    await _finish(CallExitReason.remoteState, outcome: CallOutcome.noAnswer);
    return true;
  }

  /// The tapped notification's data, with gaps filled from GET /calls/:id
  /// (initiator is a bare id; participants carry `name` and `images`).
  static Map<String, dynamic> _tapPayload(Map<String, dynamic> data, Map<String, dynamic> server) {
    final payload = Map<String, dynamic>.from(data);
    payload['callUuid'] ??= server['callUuid'];
    payload['callType'] ??= server['type'];
    final initiator = server['initiator'];
    final initiatorId = initiator is Map ? initiator['_id']?.toString() : initiator?.toString();
    final participants = server['participants'];
    if (payload['callerName'] == null && initiatorId != null && participants is List) {
      for (final p in participants.whereType<Map>()) {
        if (!_sameId(p['_id']?.toString(), initiatorId)) continue;
        final images = p['images'];
        payload['callerId'] ??= initiatorId;
        payload['callerName'] = p['name'];
        payload['callerAvatar'] ??= images is List && images.isNotEmpty ? images.first : null;
      }
    }
    return payload;
  }

  /// Resume and cold start: ask the server what is live for this user.
  /// Ringing for me → incoming UI; active and accepted on this device but
  /// not running here → rejoin; nothing → a call still ringing locally is
  /// stale and ends.
  Future<void> recoverCallState() async {
    if (_recovering) return;
    _recovering = true;
    try {
      // The answer describes the server before any call that starts while
      // the request is in flight: only act on the call we had when asking.
      final before = currentCall;
      final res = await _deps.api.current();
      if (!res.ok) return;
      final raw = res.data['call'];
      final cur = currentCall;
      final unchanged = before == null ? cur == null : _sameId(cur?.callId, before.callId);
      if (!unchanged) return;
      if (raw is! Map) {
        if (cur != null &&
            cur.direction == CallDirection.incoming &&
            cur.status == CallStatus.ringing &&
            !_sameId(_acceptingCallId, cur.callId)) {
          await _finish(CallExitReason.remoteState);
        }
        return;
      }
      final summary = Map<String, dynamic>.from(raw);
      final other = summary['otherParty'] is Map
          ? Map<String, dynamic>.from(summary['otherParty'] as Map)
          : const <String, dynamic>{};
      final status = summary['status']?.toString();
      if (status == 'ringing' && summary['direction'] == 'in') {
        await handleIncoming({
          'callId': summary['id'],
          'callUuid': summary['callUuid'],
          'caller': <String, dynamic>{
            '_id': other['id'],
            'name': other['name'],
            'profilePicture': other['avatar'],
          },
          'callType': summary['type'],
          'roomName': summary['roomName'],
        }, source: IncomingSource.recovery);
        return;
      }
      if (status == 'active' && cur == null && await _acceptedOnThisDevice(summary)) {
        if (currentCall == null) await _rejoin(summary, other, res.data);
      }
    } catch (e) {
      debugPrint('📞 call recovery failed: $e');
    } finally {
      _recovering = false;
    }
  }

  /// An active call is rejoined only when this device answered it: LiveKit
  /// identity is per user, so joining a call answered on another device
  /// would evict that device. With no call in memory, the native call UI is
  /// the only record that this device accepted it.
  Future<bool> _acceptedOnThisDevice(Map<String, dynamic> summary) async {
    final callId = summary['id']?.toString() ?? '';
    if (callId.isEmpty) return false;
    final uuid = CallKitIds.uuidFor(callId: callId, callUuid: summary['callUuid']?.toString());
    final entries = await _deps.platform.activeCallUis();
    return entries.any((e) =>
        e.accepted && (CallKitIds.same(e.uuid, uuid) || _sameId(e.callId, callId)));
  }

  Future<void> _rejoin(
    Map<String, dynamic> summary,
    Map<String, dynamic> other,
    Map<String, dynamic> data,
  ) async {
    final token = data['token']?.toString();
    final url = data['url']?.toString();
    final callId = summary['id']?.toString() ?? '';
    if (token == null || url == null || callId.isEmpty) return;
    if (_recentlyFinished.any((id) => _sameId(id, callId))) return;
    final type = summary['type'] == 'video' ? CallType.video : CallType.audio;
    _takeOverClosingScreens();
    currentCall = CallModel(
      callId: callId,
      callUuid: summary['callUuid']?.toString(),
      userId: other['id']?.toString() ?? '',
      userName: other['name']?.toString() ?? '',
      userProfilePicture: other['avatar']?.toString(),
      callType: type,
      direction: summary['direction'] == 'out' ? CallDirection.outgoing : CallDirection.incoming,
      status: CallStatus.connecting,
      startTime: DateTime.now(),
      livekitToken: token,
      livekitUrl: url,
      roomName: summary['roomName']?.toString(),
    );
    _updateConnectionState(CallUiState.connecting);
    final media = _deps.liveKitFactory();
    _liveKit = media;
    _wireLiveKit(media);
    try {
      await media.connect(url: url, token: token, type: type);
    } catch (e) {
      if (!_sameId(currentCall?.callId, callId)) return;
      debugPrint('📞 rejoin failed: $e');
      await _finish(CallExitReason.connectionLost);
      return;
    }
    if (!_sameId(currentCall?.callId, callId)) return;
    _isMuted = false;
    _isVideoEnabled = type == CallType.video;
    _deps.openActiveCall(currentCall!);
  }

  Future<void> _onCallState(Map<String, dynamic> m) async {
    final cur = currentCall;
    final callId = m['callId']?.toString();
    if (cur == null || !_sameId(callId, cur.callId)) return;
    final status = m['status']?.toString();
    final outcome = callOutcomeFromWire(m['outcome']?.toString());

    if (status == 'active') {
      if (cur.direction == CallDirection.outgoing) {
        _ringSafetyTimer?.cancel();
        unawaited(_deps.platform.stopTones());
        currentCall = cur.copyWith(status: CallStatus.connecting);
        _updateConnectionState(CallUiState.connecting);
        onCallAccepted?.call(currentCall!);
      } else if (!_sameId(_acceptingCallId, callId)) {
        await _finish(CallExitReason.answeredElsewhere);
      }
      return;
    }
    const terminal = {'ended', 'missed', 'rejected', 'busy', 'failed'};
    if (terminal.contains(status)) {
      currentCall = cur.copyWith(duration: (m['duration'] as num?)?.toInt());
      await _finish(CallExitReason.remoteState, outcome: outcome);
    }
  }

  // -- LiveKit -----------------------------------------------------------------

  void _wireLiveKit(CallLiveKitManager m) {
    m.onPeerConnected = _onPeerConnected;
    m.onPeerDisconnected = _onPeerDisconnected;
    m.onPeerMuteChanged = (muted) {
      final c = currentCall;
      if (c != null) currentCall = c.copyWith(isPeerMuted: muted);
      onPeerMuteChanged?.call(muted);
    };
    m.onPeerVideoChanged = (enabled) {
      final c = currentCall;
      if (c != null) currentCall = c.copyWith(isPeerVideoEnabled: enabled);
      onPeerVideoChanged?.call(enabled);
    };
    m.onConnectionQualityChanged = _onQuality;
    m.onReconnecting = _onLocalReconnecting;
    m.onReconnected = _onLocalReconnected;
    m.onLocalDisconnected = _onLocalDisconnected;
  }

  void _detachLiveKit(CallLiveKitManager m) {
    m.onPeerConnected = null;
    m.onPeerDisconnected = null;
    m.onPeerMuteChanged = null;
    m.onPeerVideoChanged = null;
    m.onConnectionQualityChanged = null;
    m.onReconnecting = null;
    m.onReconnected = null;
    m.onLocalDisconnected = null;
  }

  void _onPeerConnected() {
    final c = currentCall;
    if (c == null) return;
    if (c.status != CallStatus.connected) {
      currentCall = c.copyWith(status: CallStatus.connected);
      unawaited(_deps.platform.stopTones());
      unawaited(_deps.platform.playConnectSound());
      // CallLiveKitManager.connect already routed audio (speaker for video).
      _isSpeakerOn = c.callType == CallType.video;
      onCallConnected?.call(currentCall!);
    }
    _updateConnectionState(CallUiState.connected);
    onPeerReconnected?.call();
  }

  void _onPeerDisconnected() {
    if (currentCall == null) return;
    _updateConnectionState(CallUiState.reconnecting);
    onPeerReconnecting?.call();
  }

  void _onLocalReconnecting() {
    if (currentCall == null) return;
    _updateConnectionState(CallUiState.reconnecting);
    onReconnecting?.call();
  }

  void _onLocalReconnected() {
    if (currentCall == null) return;
    _updateConnectionState(CallUiState.connected);
    onReconnected?.call();
  }

  void _onLocalDisconnected(lk.DisconnectReason? reason) {
    final c = currentCall;
    if (c == null) return;
    const hangUps = {
      lk.DisconnectReason.roomDeleted,
      lk.DisconnectReason.participantRemoved,
      lk.DisconnectReason.serverShutdown,
      lk.DisconnectReason.duplicateIdentity,
    };
    if (hangUps.contains(reason)) {
      unawaited(_finish(CallExitReason.remoteState,
          outcome: c.status == CallStatus.connected ? CallOutcome.completed : null));
      return;
    }
    if (c.callId.isNotEmpty) unawaited(_deps.api.end(c.callId));
    onCallError?.call('Connection lost');
    unawaited(_finish(CallExitReason.connectionLost));
  }

  void _onQuality(lk.ConnectionQuality quality) {
    final mapped = switch (quality) {
      lk.ConnectionQuality.excellent || lk.ConnectionQuality.good => CallQuality.good,
      lk.ConnectionQuality.poor || lk.ConnectionQuality.lost => CallQuality.poor,
      _ => CallQuality.fair,
    };
    if (mapped == _callQuality) return;
    _callQuality = mapped;
    onCallQualityChanged?.call(mapped);
    if (mapped == CallQuality.poor && _connectionState == CallUiState.connected) {
      _updateConnectionState(CallUiState.poorConnection);
    } else if (mapped != CallQuality.poor && _connectionState == CallUiState.poorConnection) {
      _updateConnectionState(CallUiState.connected);
    }
  }

  void _updateConnectionState(CallUiState next) {
    if (_connectionState == next) return;
    _connectionState = next;
    onConnectionStateChanged?.call(next);
  }

  // -- CallKit ------------------------------------------------------------------

  void _initCallKit() {
    final callKit = CallKitService();
    callKit.initialize();
    callKit.onAccepted = (id, extra) => unawaited(handleCallKitAccept(id, extra));
    callKit.onDeclined = (id, extra) => unawaited(handleCallKitDecline(id, extra));
    callKit.onEnded = (id, extra) => unawaited(handleCallKitEnded(id, extra));
    callKit.onTimedOut = (id, extra) => unawaited(handleCallKitTimeout(id, extra));
  }

  /// CallKit callbacks carry the CallKit UUID (uppercase on iOS), never the
  /// server id; the server id only ever comes from `extra['callId']`.
  bool _matches(CallModel c, String callKitId, Map<String, dynamic>? extra) =>
      CallKitIds.same(callKitId, CallKitIds.uuidFor(callId: c.callId, callUuid: c.callUuid)) ||
      _sameId(extra?['callId']?.toString(), c.callId);

  /// Server call ids (24-hex) and callUuids compare case-insensitively.
  static bool _sameId(String? a, String? b) => CallKitIds.same(a, b);

  Future<void> handleCallKitAccept(String id, Map<String, dynamic>? extra) async {
    final cur = currentCall;
    if (cur == null) {
      final callId = extra?['callId']?.toString();
      if (callId == null || callId.isEmpty) return;
      currentCall = CallModel.fromJson(
        {...extra!, 'callId': callId, 'callUuid': extra['callUuid'] ?? id.toLowerCase()},
        CallDirection.incoming,
      );
    } else if (!_matches(cur, id, extra) || cur.status != CallStatus.ringing) {
      return;
    }
    _incomingShownFor = currentCall!.callId; // CallKit is the incoming UI
    await acceptCall();
    final accepted = currentCall;
    if (accepted != null && accepted.status == CallStatus.connecting) {
      _deps.openActiveCall(accepted);
    }
  }

  /// Killed-state accept: CallKit / the Android call screen was answered
  /// before Flutter ran, so the accept event was never delivered. Join it.
  /// (A decline in that state is not observable here; the server's 45 s
  /// timeout closes it.)
  Future<void> reconcileCallKitOnColdStart() async {
    final entries = await _deps.platform.activeCallUis();
    for (final entry in entries) {
      if (!entry.accepted) continue;
      final cur = currentCall;
      if (cur != null &&
          !CallKitIds.same(CallKitIds.uuidFor(callId: cur.callId, callUuid: cur.callUuid), entry.uuid) &&
          !_sameId(cur.callId, entry.callId)) {
        continue;
      }
      await handleCallKitAccept(entry.uuid, entry.extra);
      return;
    }
  }

  Future<void> handleCallKitDecline(String id, Map<String, dynamic>? extra) async {
    final cur = currentCall;
    if (cur != null && _matches(cur, id, extra)) {
      await rejectCall();
      return;
    }
    final callId = extra?['callId']?.toString();
    if (cur == null && callId != null && callId.isNotEmpty) {
      unawaited(_deps.api.decline(callId, deviceId: await _deps.platform.deviceId()));
    }
  }

  Future<void> handleCallKitEnded(String id, Map<String, dynamic>? extra) async {
    final cur = currentCall;
    if (cur != null && _matches(cur, id, extra)) await endCall();
  }

  /// The native ring UI timed out. The client never times a call out on its
  /// own: dismiss locally, post nothing — the server's timer decides.
  Future<void> handleCallKitTimeout(String id, Map<String, dynamic>? extra) async {
    final cur = currentCall;
    if (cur == null || !_matches(cur, id, extra) || cur.status != CallStatus.ringing) return;
    if (cur.direction != CallDirection.incoming) return;
    await _finish(CallExitReason.remoteState);
  }

  // -- Public API: lifecycle ---------------------------------------------------

  Future<InitiateResult> initiateCall(
    String targetUserId,
    String targetUserName,
    String? targetUserProfilePicture,
    CallType callType,
  ) async {
    if (currentCall != null) return const InitiateResult(InitiateStatus.callerBusy);
    final video = callType == CallType.video;
    if (!await _deps.platform.ensurePermissions(video: video)) {
      final err = await _deps.platform.permissionError(video: video, accepting: false);
      onCallError?.call(err);
      return InitiateResult(InitiateStatus.permissionDenied, err);
    }

    _takeOverClosingScreens();
    final draft = CallModel(
      callId: '',
      userId: targetUserId,
      userName: targetUserName,
      userProfilePicture: targetUserProfilePicture,
      callType: callType,
      direction: CallDirection.outgoing,
      status: CallStatus.ringing,
      startTime: DateTime.now(),
    );
    currentCall = draft;

    final res = await _deps.api.initiate(receiverId: targetUserId, type: callType);
    final callJson = res.data['call'];
    final serverId = callJson is Map ? (callJson['_id'] ?? callJson['id'])?.toString() : null;

    if (!identical(currentCall, draft)) {
      // Hung up while /initiate was in flight: cancel what the server created.
      if (res.ok && serverId != null) unawaited(_deps.api.end(serverId));
      return const InitiateResult(InitiateStatus.failed);
    }
    if (!res.ok) {
      currentCall = null;
      if (res.isCalleeBusy) return const InitiateResult(InitiateStatus.calleeBusy);
      if (res.isCallerBusy) return const InitiateResult(InitiateStatus.callerBusy);
      // 403 CONVERSATION_START_LIMIT: a call to a stranger counts as starting a
      // conversation. Like the chat send path, show the server's own message
      // (ApiClient skips its global 403 toast for this code).
      final err = res.error ?? 'Failed to start call';
      onCallError?.call(err);
      return InitiateResult(InitiateStatus.failed, err);
    }

    final token = res.data['token']?.toString();
    final url = res.data['url']?.toString();
    if (serverId == null || token == null || url == null) {
      currentCall = null;
      if (serverId != null) unawaited(_deps.api.end(serverId));
      onCallError?.call('Server response missing call data');
      return const InitiateResult(InitiateStatus.failed);
    }

    currentCall = draft.copyWith(
      callId: serverId,
      callUuid: (callJson as Map)['callUuid']?.toString(),
      livekitToken: token,
      livekitUrl: url,
      roomName: res.data['roomName']?.toString(),
    );

    final media = _deps.liveKitFactory();
    _liveKit = media;
    _wireLiveKit(media);
    try {
      await media.connect(url: url, token: token, type: callType);
    } catch (e) {
      // Finished while connecting (call:state, hang-up): already torn down.
      if (!_sameId(currentCall?.callId, serverId)) return const InitiateResult(InitiateStatus.failed);
      debugPrint('📞 LiveKit connect failed: $e');
      unawaited(_deps.api.end(serverId));
      onCallError?.call('Failed to connect to call');
      await _finish(CallExitReason.error);
      return const InitiateResult(InitiateStatus.failed);
    }
    if (!_sameId(currentCall?.callId, serverId)) return const InitiateResult(InitiateStatus.started);

    _isMuted = false;
    _isVideoEnabled = video;
    // Only while still ringing out: an accept that landed mid-connect must
    // not start the ringback or arm the safety net.
    if (currentCall?.status == CallStatus.ringing) {
      unawaited(_deps.platform.startRingback());
      _ringSafetyTimer = Timer(kRingSafetyTimeout, () => unawaited(_checkStillRinging(serverId)));
    }
    return const InitiateResult(InitiateStatus.started);
  }

  Future<void> _checkStillRinging(String callId) async {
    final cur = currentCall;
    if (cur == null || !_sameId(cur.callId, callId) || cur.status != CallStatus.ringing) return;
    final res = await _deps.api.get(callId);
    if (!res.ok || !_sameId(currentCall?.callId, callId)) return;
    final status = res.data['status']?.toString();
    if (status == 'ringing' || status == 'active') return;
    await _finish(CallExitReason.remoteState,
        outcome: callOutcomeFromWire(res.data['outcome']?.toString()));
  }

  Future<void> acceptCall() async {
    final call = currentCall;
    if (call == null || call.direction != CallDirection.incoming) return;
    if (_sameId(_acceptingCallId, call.callId)) return; // double tap
    _acceptingCallId = call.callId;
    await _deps.platform.stopTones();

    final video = call.callType == CallType.video;
    if (!await _deps.platform.ensurePermissions(video: video)) {
      final err = await _deps.platform.permissionError(video: video, accepting: true);
      onCallError?.call(err);
      await rejectCall();
      return;
    }

    final res = await _deps.api.accept(call.callId, deviceId: await _deps.platform.deviceId());
    if (!_sameId(currentCall?.callId, call.callId)) return;
    if (res.isCallStateConflict) {
      // Another device answered, or it was cancelled / timed out: dismiss silently.
      await _finish(CallExitReason.acceptConflict);
      return;
    }
    final token = res.data['token']?.toString();
    final url = res.data['url']?.toString();
    if (!res.ok || token == null || url == null) {
      onCallError?.call(res.error ?? 'Failed to accept call');
      unawaited(_deps.api.end(call.callId));
      await _finish(CallExitReason.error);
      return;
    }

    currentCall = call.copyWith(
      status: CallStatus.connecting,
      livekitToken: token,
      livekitUrl: url,
      roomName: res.data['roomName']?.toString(),
    );
    _incomingShownFor = null;
    _updateConnectionState(CallUiState.connecting);

    final media = _deps.liveKitFactory();
    _liveKit = media;
    _wireLiveKit(media);
    try {
      await media.connect(url: url, token: token, type: call.callType);
    } catch (e) {
      // Finished while connecting (call:state, hang-up): already torn down.
      if (!_sameId(currentCall?.callId, call.callId)) return;
      debugPrint('📞 LiveKit connect failed: $e');
      unawaited(_deps.api.end(call.callId));
      onCallError?.call('Failed to connect to call');
      await _finish(CallExitReason.error);
      return;
    }
    if (!_sameId(currentCall?.callId, call.callId)) return;
    _isMuted = false;
    _isVideoEnabled = video;
    onCallAccepted?.call(currentCall!);
  }

  Future<void> rejectCall() async {
    final call = currentCall;
    if (call == null) {
      _closeNow();
      return;
    }
    if (call.callId.isNotEmpty) {
      final deviceId = await _deps.platform.deviceId();
      unawaited(_deps.api.decline(call.callId, deviceId: deviceId));
      if (!_sameId(currentCall?.callId, call.callId)) return;
    }
    onCallRejected?.call(call.copyWith(status: CallStatus.rejected));
    await _finish(CallExitReason.declined);
  }

  /// Hang up. Always closes the call screen, even when there is no call.
  Future<void> endCall() async {
    final call = currentCall;
    if (call == null) {
      _closeNow();
      return;
    }
    unawaited(_deps.platform.playEndSound());
    if (call.callId.isNotEmpty) unawaited(_deps.api.end(call.callId));
    await _finish(CallExitReason.localHangUp,
        outcome: call.status == CallStatus.connected ? CallOutcome.completed : null);
  }

  // -- The single exit path ----------------------------------------------------

  Future<void> _finish(CallExitReason reason, {CallOutcome? outcome}) async {
    final call = currentCall;
    if (call == null) {
      _closeNow();
      return;
    }
    // Synchronous part first: any second exit now sees no call.
    currentCall = null;
    _remember(call.callId);
    _acceptingCallId = null;
    _incomingShownFor = null;
    _ringSafetyTimer?.cancel();
    _closeTimer?.cancel();
    final media = _liveKit;
    _detachLiveKit(media);
    _liveKit = _deps.liveKitFactory();
    _resetMediaState();

    final ended = call.copyWith(status: CallStatus.ended, endTime: DateTime.now());
    final finish = CallFinish(call: ended, reason: reason, outcome: outcome);
    onCallEnded?.call(ended);
    onCallFinished?.call(finish);
    _finishController.add(finish);

    final showBanner = reason == CallExitReason.remoteState &&
        call.direction == CallDirection.outgoing &&
        outcome != null &&
        outcome != CallOutcome.completed;
    if (showBanner) {
      _closeTimer = Timer(kOutcomeBannerDuration, _deps.closeCallScreens);
    } else {
      _deps.closeCallScreens();
    }

    await Future.wait([
      _quietly(media.disconnect),
      _quietly(_deps.platform.stopTones),
      _quietly(() => _deps.platform.endCallUi(call)),
      _quietly(_deps.platform.cancelIncomingNotification),
    ]);
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('📞 call cleanup: $e');
    }
  }

  /// Close the call screens now; a pending banner close is superseded.
  void _closeNow() {
    _closeTimer?.cancel();
    _closeTimer = null;
    _deps.closeCallScreens();
  }

  void _resetMediaState() {
    _connectionState = CallUiState.ringing;
    _callQuality = CallQuality.good;
    _isMuted = false;
    _isVideoEnabled = true;
    _isSpeakerOn = false;
    _isFrontCamera = true;
  }

  void _remember(String callId) {
    if (callId.isEmpty) return;
    _recentlyFinished.add(callId);
    if (_recentlyFinished.length > 20) _recentlyFinished.removeAt(0);
  }

  /// A new call while the previous one's outcome banner is still up: close
  /// the old screens now rather than letting the timer close the new ones.
  void _takeOverClosingScreens() {
    final pending = _closeTimer;
    _closeTimer = null;
    if (pending != null && pending.isActive) {
      pending.cancel();
      _deps.closeCallScreens();
    }
  }

  // -- Media controls ----------------------------------------------------------

  void setMuted(bool muted) {
    _isMuted = muted;
    unawaited(_liveKit.setMuted(muted));
    _emitToPeer('call:mute', {'isMuted': muted});
  }

  void toggleMute() => setMuted(!_isMuted);

  void setVideoEnabled(bool enabled) {
    _isVideoEnabled = enabled;
    unawaited(_liveKit.setCameraEnabled(enabled));
    _emitToPeer('call:video-toggle', {'isVideoEnabled': enabled});
  }

  void toggleVideo() => setVideoEnabled(!_isVideoEnabled);

  Future<void> setSpeakerOn(bool on) async {
    _isSpeakerOn = on;
    try {
      await lk.Hardware.instance.setSpeakerphoneOn(on);
    } catch (e) {
      debugPrint('🔊 setSpeakerphoneOn failed: $e');
    }
  }

  Future<void> toggleSpeaker() => setSpeakerOn(!_isSpeakerOn);

  Future<void> switchCamera() async {
    final local = _liveKit.room?.localParticipant;
    if (local == null) return;
    for (final pub in local.videoTrackPublications) {
      final track = pub.track;
      if (track is lk.LocalVideoTrack) {
        try {
          await track.setCameraPosition(
              _isFrontCamera ? lk.CameraPosition.back : lk.CameraPosition.front);
          _isFrontCamera = !_isFrontCamera;
        } catch (e) {
          debugPrint('📞 switchCamera failed: $e');
        }
        return;
      }
    }
  }

  void _emitToPeer(String event, Map<String, dynamic> body) {
    final socket = _socket;
    final call = currentCall;
    // After logout ChatSocketService drops its socket without telling us:
    // a socket that is not connected counts as absent.
    if (socket == null || !socket.connected || call == null || call.callId.isEmpty) return;
    socket.emit(event, {'callId': call.callId, ...body});
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_finish(CallExitReason.localHangUp));
  }
}
