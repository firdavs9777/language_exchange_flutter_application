import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/webrtc_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/router/app_router.dart';

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

class CallManager with WidgetsBindingObserver {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  bool _appInForeground = true;

  WebRTCService _webrtcService = WebRTCService();
  ChatSocketService? _chatSocketService;
  IO.Socket? _socket;
  bool _isInitialized = false;
  AudioPlayer? _ringtonePlayer;
  AudioPlayer? _soundPlayer;
  Timer? _callTimeoutTimer;
  final CallKitService _callKitService = CallKitService();

  CallModel? currentCall;

  // Callbacks
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
  Timer? _qualityMonitorTimer;
  Timer? _durationLimitTimer;
  Timer? _durationWarningTimer;
  bool _isVipCall = true; // default true (no limit), set to false for free users
  Function(CallUiState)? onConnectionStateChanged;
  Function(CallQuality)? onCallQualityChanged;

  CallUiState get connectionState => _connectionState;
  CallQuality get callQuality => _callQuality;

  WebRTCService get webrtcService => _webrtcService;
  bool get isInitialized => _isInitialized;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    debugPrint('📞 App lifecycle: $state, foreground: $_appInForeground');
  }

  Future<void> initialize(ChatSocketService chatSocketService) async {
    // Register lifecycle observer
    WidgetsBinding.instance.removeObserver(this); // prevent duplicates
    WidgetsBinding.instance.addObserver(this);

    // Prevent duplicate initialization with same socket if webrtc is still alive
    if (_isInitialized && !_webrtcService.isDisposed &&
        _chatSocketService == chatSocketService && _socket == chatSocketService.socket) {
      debugPrint('📞 CallManager already initialized, skipping');
      return;
    }

    debugPrint('📞 CallManager initializing (wasInit: $_isInitialized, socketMatch: ${_socket == chatSocketService.socket})');

    _chatSocketService = chatSocketService;
    _socket = chatSocketService.socket;

    // If webrtc service was disposed (from previous call cleanup), create fresh one
    if (_webrtcService.isDisposed) {
      debugPrint('📞 WebRTC service was disposed, creating fresh one');
      _webrtcService = WebRTCService();
    }

    await _webrtcService.initialize();

    // Remove old listeners before adding new ones to prevent duplicates
    _removeSocketListeners();
    _setupSocketListeners();
    _setupWebRTCCallbacks();
    _initCallKit();
    _isInitialized = true;
    debugPrint('📞 CallManager initialized successfully, socket connected: ${_socket?.connected}');
  }

  void _removeSocketListeners() {
    _socket?.off('call:incoming');
    _socket?.off('call:accepted');
    _socket?.off('call:rejected');
    _socket?.off('call:offer');
    _socket?.off('call:answer-sdp');
    _socket?.off('call:ice-candidate');
    _socket?.off('call:ended');
    _socket?.off('call:missed');
    _socket?.off('call:mute');
    _socket?.off('call:video-toggle');
    _socket?.off('call:timeout');
    _socket?.off('call:peer-reconnecting');
    _socket?.off('call:peer-reconnected');
  }

  void _setupSocketListeners() {
    if (_socket == null) {
      debugPrint('❌ Cannot setup call listeners - socket is null');
      return;
    }
    debugPrint('📞 Setting up call socket listeners');

    // Listen for incoming call
    _socket!.on('call:incoming', (data) async {
      debugPrint('📞 call:incoming event received: $data');

      // Ignore if already in a call
      if (currentCall != null) {
        debugPrint('📞 Already in a call, ignoring incoming');
        return;
      }

      try {
        final call = CallModel.fromJson(
          Map<String, dynamic>.from(data),
          CallDirection.incoming,
        );
        currentCall = call;
        startRingtone();

        debugPrint('📞 Parsed incoming call from ${call.userName}, foreground: $_appInForeground, callback set: ${onIncomingCall != null}');

        if (_appInForeground && onIncomingCall != null) {
          // App is in foreground — show our Flutter IncomingCallScreen (full-screen overlay)
          // Don't show CallKit here to avoid two UIs competing
          onIncomingCall!(call);
        } else {
          // App is in background/terminated — show native CallKit UI
          // (works on lock screen, shows full-screen activity on Android)
          _callKitService.showIncomingCall(
            callId: call.callId,
            callerName: call.userName,
            callerAvatar: call.userProfilePicture,
            isVideo: call.callType == CallType.video,
          );
          // Also fire callback in case app comes back to foreground
          if (onIncomingCall != null) {
            onIncomingCall!(call);
          }
        }
      } catch (e) {
        debugPrint('❌ Failed to parse incoming call: $e');
        if (onCallError != null) {
          onCallError!('Failed to parse incoming call');
        }
      }
    });

    // Listen for call accepted (when receiver accepts)
    _socket!.on('call:accepted', (data) async {
      debugPrint('📞 call:accepted event received: $data');
      _callTimeoutTimer?.cancel();
      stopRingtone();

      if (currentCall != null) {
        currentCall = currentCall!.copyWith(status: CallStatus.connecting);
        if (onCallAccepted != null) {
          onCallAccepted!(currentCall!);
        }

        // For outgoing calls, create offer when accepted
        if (currentCall!.direction == CallDirection.outgoing) {
          try {
            debugPrint('📞 Creating WebRTC offer (isDisposed: ${_webrtcService.isDisposed})');
            // Ensure renderers are initialized (needed after cleanup created a fresh service)
            if (_webrtcService.isDisposed) {
              _webrtcService = WebRTCService();
            }
            await _webrtcService.initialize();
            _setupWebRTCCallbacks();
            await _webrtcService.createOffer(
              currentCall!.callType == CallType.video,
            );
            debugPrint('📞 WebRTC offer created successfully');
          } catch (e) {
            debugPrint('❌ Failed to create offer: $e');
            if (onCallError != null) {
              onCallError!('Failed to establish connection');
            }
          }
        }
      } else {
        debugPrint('❌ call:accepted but currentCall is null');
      }
    });

    // Listen for call rejected
    _socket!.on('call:rejected', (data) {

      if (currentCall != null) {
        currentCall = currentCall!.copyWith(status: CallStatus.rejected);
        if (onCallRejected != null) {
          onCallRejected!(currentCall!);
        }
        _cleanup();
      }
    });

    // Listen for WebRTC offer
    _socket!.on('call:offer', (data) async {
      debugPrint('📞 call:offer received (isDisposed: ${_webrtcService.isDisposed})');

      try {
        // Ensure renderers are initialized (needed after cleanup created a fresh service)
        if (_webrtcService.isDisposed) {
          _webrtcService = WebRTCService();
        }
        await _webrtcService.initialize();
        _setupWebRTCCallbacks();

        final offerData = data['offer'] ?? data;
        final offer = RTCSessionDescription(
          offerData['sdp'] ?? '',
          offerData['type'] ?? 'offer',
        );

        await _webrtcService.createAnswer(
          offer,
          currentCall?.callType == CallType.video,
        );
        debugPrint('📞 WebRTC answer created successfully');
      } catch (e) {
        debugPrint('❌ Failed to process call offer: $e');
        if (onCallError != null) {
          onCallError!('Failed to process call offer');
        }
      }
    });

    // Listen for WebRTC answer
    _socket!.on('call:answer-sdp', (data) async {
      debugPrint('📞 call:answer-sdp received');

      try {
        final answerData = data['answer'] ?? data;
        final answer = RTCSessionDescription(
          answerData['sdp'] ?? '',
          answerData['type'] ?? 'answer',
        );

        await _webrtcService.setRemoteDescription(answer);
        debugPrint('📞 Remote description set successfully');
      } catch (e) {
        debugPrint('❌ Failed to process call answer: $e');
        if (onCallError != null) {
          onCallError!('Failed to process call answer');
        }
      }
    });

    // Listen for ICE candidates
    _socket!.on('call:ice-candidate', (data) async {

      try {
        final candidateData = data['candidate'] ?? data;
        final candidate = RTCIceCandidate(
          candidateData['candidate'] ?? '',
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        );

        await _webrtcService.addIceCandidate(candidate);
      } catch (e) {
      }
    });

    // Listen for call ended
    _socket!.on('call:ended', (data) {
      debugPrint('📞 call:ended event received: $data');
      if (currentCall != null) {
        final duration = data is Map ? data['duration'] : null;
        currentCall = currentCall!.copyWith(
          status: CallStatus.ended,
          endTime: DateTime.now(),
          duration: duration != null ? int.tryParse(duration.toString()) : null,
        );

        if (onCallEnded != null) {
          onCallEnded!(currentCall!);
        }

        _cleanup();
      }
    });

    // 🔧 FIX: Listen for missed calls
    _socket!.on('call:missed', (data) {

      if (currentCall != null) {
        currentCall = currentCall!.copyWith(
          status: CallStatus.ended,
          endTime: DateTime.now(),
        );

        if (onCallEnded != null) {
          onCallEnded!(currentCall!);
        }

        _cleanup();
      }
    });

    // Listen for peer mute state
    _socket!.on('call:mute', (data) {
      if (data['callId'] == currentCall?.callId && data['userId'] != null) {
        final isMuted = data['isMuted'] == true;
        if (currentCall != null) {
          currentCall = currentCall!.copyWith(isPeerMuted: isMuted);
        }
        onPeerMuteChanged?.call(isMuted);
      }
    });

    // Listen for peer video state
    _socket!.on('call:video-toggle', (data) {
      if (data['callId'] == currentCall?.callId && data['userId'] != null) {
        final isVideoEnabled = data['isVideoEnabled'] == true;
        if (currentCall != null) {
          currentCall = currentCall!.copyWith(isPeerVideoEnabled: isVideoEnabled);
        }
        onPeerVideoChanged?.call(isVideoEnabled);
      }
    });

    // Listen for call timeout
    _socket!.on('call:timeout', (data) {
      if (currentCall != null) {
        currentCall = currentCall!.copyWith(status: CallStatus.missed);
        onCallTimeout?.call();
        _cleanup();
      }
    });

    // Listen for peer reconnecting
    _socket!.on('call:peer-reconnecting', (data) {
      if (data['callId'] == currentCall?.callId) {
        onPeerReconnecting?.call();
      }
    });

    // Listen for peer reconnected
    _socket!.on('call:peer-reconnected', (data) {
      if (data['callId'] == currentCall?.callId) {
        onPeerReconnected?.call();
      }
    });
  }

  void _setupWebRTCCallbacks() {
    _webrtcService.onOfferCreated = (RTCSessionDescription offer) {

      if (_socket == null || currentCall == null) {
        return;
      }

      _socket!.emit('call:offer', {
        'callId': currentCall!.callId,
        'targetUserId': currentCall!.userId,
        'offer': {'type': offer.type, 'sdp': offer.sdp},
      });
    };

    _webrtcService.onAnswerCreated = (RTCSessionDescription answer) {

      if (_socket == null || currentCall == null) {
        return;
      }

      _socket!.emit('call:answer-sdp', {
        'callId': currentCall!.callId,
        'targetUserId': currentCall!.userId,
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      });
    };

    _webrtcService.onIceCandidate = (RTCIceCandidate candidate) {

      if (_socket == null || currentCall == null) {
        return;
      }

      _socket!.emit('call:ice-candidate', {
        'callId': currentCall!.callId,
        'targetUserId': currentCall!.userId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _webrtcService.onRemoteStream = (MediaStream stream) {
      debugPrint('📞 Remote stream received! Tracks: ${stream.getTracks().map((t) => '${t.kind}:enabled=${t.enabled}').join(', ')}');
      if (currentCall != null) {
        currentCall = currentCall!.copyWith(status: CallStatus.connected);
        // Set speaker default: ON for video, OFF for audio
        _applySpeakerDefault(currentCall!.callType);
        // Play connect chime
        _playConnectSound();
        // Start duration limit for non-VIP users
        _startDurationLimit();
        if (onCallConnected != null) {
          onCallConnected!(currentCall!);
        }
      }
    };

    _webrtcService.onConnectionStateChange = () {
      debugPrint('📞 ICE connection state: ${_webrtcService.isConnected ? "CONNECTED" : "not connected"}');
    };

    _webrtcService.onIceStateChanged = (RTCIceConnectionState state) {
      debugPrint('📞 ICE state changed: $state');
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateChecking:
          _updateConnectionState(CallUiState.connecting);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _updateConnectionState(CallUiState.connected);
          _startQualityMonitoring();
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          _updateConnectionState(CallUiState.reconnecting);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _updateConnectionState(CallUiState.ended);
          break;
        default:
          break;
      }
    };
  }

  void _updateConnectionState(CallUiState newState) {
    if (_connectionState == newState) return;
    _connectionState = newState;
    debugPrint('📞 Connection state: $newState');
    onConnectionStateChanged?.call(newState);
  }

  void _startQualityMonitoring() {
    _qualityMonitorTimer?.cancel();
    _qualityMonitorTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (currentCall == null || _webrtcService.isDisposed) {
        _qualityMonitorTimer?.cancel();
        return;
      }
      try {
        final stats = await _webrtcService.getStats();
        _analyzeStats(stats);
      } catch (e) {
        debugPrint('📞 Quality monitor error: $e');
      }
    });
  }

  int _prevPacketsReceived = 0;
  int _prevPacketsLost = 0;

  void _analyzeStats(List<StatsReport> reports) {
    int totalPacketsReceived = 0;
    int totalPacketsLost = 0;

    for (final report in reports) {
      if (report.type == 'inbound-rtp' || report.type == 'ssrc') {
        final packetsReceived = int.tryParse(
            report.values['packetsReceived']?.toString() ?? '0') ?? 0;
        final packetsLost = int.tryParse(
            report.values['packetsLost']?.toString() ?? '0') ?? 0;
        totalPacketsReceived += packetsReceived;
        totalPacketsLost += packetsLost;
      }
    }

    // Calculate delta packet loss since last check
    final deltaReceived = totalPacketsReceived - _prevPacketsReceived;
    final deltaLost = totalPacketsLost - _prevPacketsLost;
    _prevPacketsReceived = totalPacketsReceived;
    _prevPacketsLost = totalPacketsLost;

    if (deltaReceived + deltaLost == 0) return;

    final lossPercent = (deltaLost / (deltaReceived + deltaLost)) * 100;

    CallQuality newQuality;
    if (lossPercent > 10) {
      newQuality = CallQuality.poor;
    } else if (lossPercent > 3) {
      newQuality = CallQuality.fair;
    } else {
      newQuality = CallQuality.good;
    }

    if (newQuality != _callQuality) {
      _callQuality = newQuality;
      debugPrint('📞 Call quality: $newQuality (loss: ${lossPercent.toStringAsFixed(1)}%)');
      onCallQualityChanged?.call(newQuality);

      // Update connection state for poor quality
      if (newQuality == CallQuality.poor && _connectionState == CallUiState.connected) {
        _updateConnectionState(CallUiState.poorConnection);
      } else if (newQuality != CallQuality.poor && _connectionState == CallUiState.poorConnection) {
        _updateConnectionState(CallUiState.connected);
      }
    }
  }

  void _initCallKit() {
    _callKitService.initialize();

    // When user accepts from native CallKit UI (background/lock screen)
    _callKitService.onAccepted = (callId) {
      debugPrint('📱 CallKit accepted: $callId');
      if (currentCall != null) {
        stopRingtone();
        acceptCall();
        // Navigate to ActiveCallScreen since IncomingCallScreen may not be showing
        final navState = callOverlayNavigatorKey.currentState;
        if (navState != null && currentCall != null) {
          navState.push(
            MaterialPageRoute(
              builder: (_) => ActiveCallScreen(call: currentCall!),
              fullscreenDialog: true,
            ),
          );
        }
      }
    };

    // When user declines from native CallKit UI
    _callKitService.onDeclined = (callId) {
      debugPrint('📱 CallKit declined: $callId');
      if (currentCall != null) {
        stopRingtone();
        rejectCall();
      }
    };

    // When call ends from native CallKit UI
    _callKitService.onEnded = (callId) {
      debugPrint('📱 CallKit ended: $callId');
      if (currentCall != null) {
        endCall();
      }
    };
  }

  Future<void> initiateCall(
    String targetUserId,
    String targetUserName,
    String? targetUserProfilePicture,
    CallType callType,
  ) async {
    try {
      // Check socket connection
      if (_socket == null || !(_chatSocketService?.isConnected ?? false)) {
        final error = 'Not connected to server. Please check your connection.';
        if (onCallError != null) {
          onCallError!(error);
        }
        throw Exception(error);
      }

      // Request permissions
      bool permissionsGranted = await _webrtcService.requestPermissions(
        callType == CallType.video,
      );

      if (!permissionsGranted) {
        // Check which permissions are denied for better error messages
        final micStatus = await Permission.microphone.status;
        final cameraStatus = callType == CallType.video 
            ? await Permission.camera.status 
            : PermissionStatus.granted;
        
        
        String error;
        if (callType == CallType.video) {
          if (micStatus.isPermanentlyDenied && cameraStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable microphone and camera access in Settings to make video calls.';
          } else if (micStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable microphone access in Settings to make calls.';
          } else if (cameraStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable camera access in Settings to make video calls.';
          } else if (!micStatus.isGranted) {
            error = 'DENIED:Microphone permission is required for calls. Please grant microphone access when prompted.';
          } else {
            error = 'DENIED:Camera permission is required for video calls. Please grant camera access when prompted.';
          }
        } else {
          // Audio call
          if (micStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable microphone access in Settings to make calls.';
          } else if (micStatus.isDenied) {
            error = 'DENIED:Microphone permission is required for calls. Please grant microphone access when prompted.';
          } else {
            error = 'DENIED:Microphone permission is required for calls.';
          }
        }
        
        if (onCallError != null) {
          onCallError!(error);
        }
        throw Exception(error);
      }
      

      // Create call model
      currentCall = CallModel(
        callId: '', // Will be set by backend
        userId: targetUserId,
        userName: targetUserName,
        userProfilePicture: targetUserProfilePicture,
        callType: callType,
        direction: CallDirection.outgoing,
        status: CallStatus.ringing,
        startTime: DateTime.now(),
      );

      // 🔧 FIX: Use Completer to wait for ack response
      final completer = Completer<void>();
      bool isCompleted = false;

      _socket!.emitWithAck(
        'call:initiate',
        {
          'targetUserId': targetUserId,
          'callType': callType == CallType.video ? 'video' : 'audio',
        },
        ack: (response) {
          debugPrint('📞 call:initiate ack received: $response');
          if (isCompleted) return;
          isCompleted = true;

          if (response != null && response is Map) {
            if (response['status'] == 'success' ||
                response['success'] == true) {
              final callId = response['callId'] ?? response['_id'];
              debugPrint('📞 Call initiated successfully, callId: $callId');
              if (callId != null && currentCall != null) {
                currentCall = currentCall!.copyWith(callId: callId.toString());
              }

              // Don't create offer here - wait for call:accepted event
              completer.complete();
            } else {
              final error = response['error'] ?? 'Failed to initiate call';
              if (onCallError != null) {
                onCallError!(error.toString());
              }
              _cleanup();
              completer.completeError(Exception(error.toString()));
            }
          } else {
            final error = 'Failed to initiate call - no response from server';
            if (onCallError != null) {
              onCallError!(error);
            }
            _cleanup();
            completer.completeError(Exception(error));
          }
        },
      );

      // Wait for ack response with timeout
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (!isCompleted) {
            isCompleted = true;
            final error = 'Call initiation timeout - server did not respond';
            if (onCallError != null) {
              onCallError!(error);
            }
            _cleanup();
            throw TimeoutException(error);
          }
        },
      );

      // Play ringback tone for outgoing call
      startRingback();

      // Start ringing timeout — auto-hangup if no answer within 45s
      _callTimeoutTimer?.cancel();
      _callTimeoutTimer = Timer(const Duration(seconds: 45), () {
        debugPrint('📞 Call timeout — no answer after 45s');
        if (currentCall != null && currentCall!.status == CallStatus.ringing) {
          onCallTimeout?.call();
          endCall();
        }
      });
    } catch (e) {
      if (onCallError != null && e is! TimeoutException) {
        // Preserve the original error if it has permission prefixes
        final errorStr = e.toString();
        if (errorStr.contains('PERMANENTLY_DENIED:') || errorStr.contains('DENIED:')) {
          // Extract just the error message without Exception wrapper
          final cleanError = errorStr.replaceAll('Exception: ', '');
          onCallError!(cleanError);
        } else {
          onCallError!('Failed to start call: $errorStr');
        }
      }
      _cleanup();
      rethrow;
    }
  }

  Future<void> acceptCall() async {
    debugPrint('📞 acceptCall called, currentCall: ${currentCall?.callId}, socket: ${_socket != null}, socketConnected: ${_socket?.connected}');
    stopRingtone();
    if (currentCall == null) return;

    try {

      if (_socket == null) {
        debugPrint('❌ acceptCall: socket is null');
        if (onCallError != null) {
          onCallError!('Not connected to server');
        }
        return;
      }

      // Request permissions
      bool permissionsGranted = await _webrtcService.requestPermissions(
        currentCall!.callType == CallType.video,
      );
      debugPrint('📞 Permissions granted: $permissionsGranted');

      if (!permissionsGranted) {
        // Check which permissions are denied for better error messages
        final micStatus = await Permission.microphone.status;
        final cameraStatus = currentCall!.callType == CallType.video 
            ? await Permission.camera.status 
            : PermissionStatus.granted;
        
        String error;
        if (currentCall!.callType == CallType.video) {
          if (micStatus.isPermanentlyDenied && cameraStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable microphone and camera access in Settings to answer video calls.';
          } else if (micStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable microphone access in Settings to answer calls.';
          } else if (cameraStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable camera access in Settings to answer video calls.';
          } else if (!micStatus.isGranted) {
            error = 'DENIED:Microphone permission is required to answer calls.';
          } else {
            error = 'DENIED:Camera permission is required to answer video calls.';
          }
        } else {
          // Audio call
          if (micStatus.isPermanentlyDenied) {
            error = 'PERMANENTLY_DENIED:Please enable microphone access in Settings to answer calls.';
          } else {
            error = 'DENIED:Microphone permission is required to answer calls.';
          }
        }
        
        rejectCall();
        if (onCallError != null) {
          onCallError!(error);
        }
        return;
      }

      // Emit answer to backend
      debugPrint('📞 Emitting call:answer with callId: ${currentCall!.callId}, accept: true');
      _socket!.emit('call:answer', {
        'callId': currentCall!.callId,
        'accept': true,
      });

      currentCall = currentCall!.copyWith(status: CallStatus.connecting);
      debugPrint('📞 Call status set to connecting, waiting for call:offer from caller');

      // Note: The offer will come via 'call:offer' event, then we create answer
    } catch (e) {
      debugPrint('❌ acceptCall error: $e');
      rejectCall();
    }
  }

  void rejectCall() {
    if (currentCall == null) return;


    if (_socket != null) {
      _socket!.emit('call:answer', {
        'callId': currentCall!.callId,
        'accept': false,
      });
    }

    currentCall = currentCall!.copyWith(status: CallStatus.rejected);

    if (onCallRejected != null) {
      onCallRejected!(currentCall!);
    }

    _cleanup();
  }

  void endCall() {
    if (currentCall == null) return;

    // Play end chime
    _playEndSound();

    if (_socket != null) {
      _socket!.emit('call:end', {'callId': currentCall!.callId});
    }

    final startTime = currentCall!.startTime;
    final duration = DateTime.now().difference(startTime).inSeconds;

    currentCall = currentCall!.copyWith(
      status: CallStatus.ended,
      endTime: DateTime.now(),
      duration: duration,
    );

    if (onCallEnded != null) {
      onCallEnded!(currentCall!);
    }

    _cleanup();
  }

  void toggleMute() {
    _webrtcService.toggleMicrophone();
    // Emit mute state to server
    if (_socket != null && currentCall != null) {
      _socket!.emit('call:mute', {
        'callId': currentCall!.callId,
        'isMuted': !_webrtcService.isMicrophoneEnabled,
      });
    }
  }

  void toggleVideo() {
    _webrtcService.toggleCamera();
    // Emit video state to server
    if (_socket != null && currentCall != null) {
      _socket!.emit('call:video-toggle', {
        'callId': currentCall!.callId,
        'isVideoEnabled': _webrtcService.isCameraEnabled,
      });
    }
  }

  bool get isMuted => !_webrtcService.isMicrophoneEnabled;
  bool get isVideoEnabled => _webrtcService.isCameraEnabled;
  bool get isSpeakerOn => _webrtcService.isSpeakerOn;

  Future<void> toggleSpeaker() async {
    await _webrtcService.setSpeakerphone(!_webrtcService.isSpeakerOn);
  }

  /// Set whether the current call is from a VIP user (no duration limit)
  void setVipCall(bool isVip) {
    _isVipCall = isVip;
  }

  /// Start call duration limit timer for non-VIP users.
  /// Called when call connects (remote stream received).
  void _startDurationLimit() {
    if (_isVipCall) return;

    _durationWarningTimer?.cancel();
    _durationLimitTimer?.cancel();

    // Warning at 4 min (1 min remaining)
    _durationWarningTimer = Timer(
      const Duration(seconds: freeCallWarningSeconds),
      () {
        debugPrint('📞 Call duration warning — 1 minute remaining');
        onCallDurationWarning?.call(freeCallDurationSeconds - freeCallWarningSeconds);
      },
    );

    // Auto-end at 5 min
    _durationLimitTimer = Timer(
      const Duration(seconds: freeCallDurationSeconds),
      () {
        debugPrint('📞 Call duration limit reached — ending call');
        onCallDurationLimitReached?.call();
        endCall();
      },
    );
  }

  /// Set speaker default based on call type: ON for video, OFF for audio
  Future<void> _applySpeakerDefault(CallType callType) async {
    final shouldEnable = callType == CallType.video;
    await _webrtcService.setSpeakerphone(shouldEnable);
  }

  Future<void> switchCamera() async {
    await _webrtcService.switchCamera();
  }

  /// Play incoming call ringtone (loops)
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

  /// Play outgoing ringback tone (loops — what caller hears while waiting)
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

  /// Play short connect chime
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

  /// Play short end chime
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

  void _cleanup() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
    _qualityMonitorTimer?.cancel();
    _qualityMonitorTimer = null;
    _durationWarningTimer?.cancel();
    _durationWarningTimer = null;
    _durationLimitTimer?.cancel();
    _durationLimitTimer = null;
    _isVipCall = true;
    _connectionState = CallUiState.ringing;
    _callQuality = CallQuality.good;
    _prevPacketsReceived = 0;
    _prevPacketsLost = 0;
    stopRingtone();
    _soundPlayer?.dispose();
    _soundPlayer = null;
    _callKitService.endAllCalls();
    NotificationService().cancelCallNotification();
    currentCall = null;
    // Dispose old service and create fresh one for next call
    final oldService = _webrtcService;
    _webrtcService = WebRTCService();
    // Delay dispose so UI can finish rendering before renderers are disposed
    Future.delayed(const Duration(milliseconds: 300), () {
      oldService.dispose();
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
  }
}
