import 'dart:async';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/webrtc_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:permission_handler/permission_handler.dart';

class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  final WebRTCService _webrtcService = WebRTCService();
  ChatSocketService? _chatSocketService;
  IO.Socket? _socket;

  CallModel? currentCall;

  // Callbacks
  Function(CallModel)? onIncomingCall;
  Function(CallModel)? onCallAccepted;
  Function(CallModel)? onCallRejected;
  Function(CallModel)? onCallEnded;
  Function(String)? onCallError;

  WebRTCService get webrtcService => _webrtcService;

  Future<void> initialize(ChatSocketService chatSocketService) async {
    _chatSocketService = chatSocketService;
    _socket = chatSocketService.socket;
    await _webrtcService.initialize();
    _setupSocketListeners();
    _setupWebRTCCallbacks();
    print('✅ CallManager initialized');
  }

  void _setupSocketListeners() {
    if (_socket == null) {
      print('⚠️ Socket is null, cannot setup listeners');
      return;
    }

    // Listen for incoming call
    _socket!.on('call:incoming', (data) async {
      print('📞 Incoming call: $data');

      try {
        final call = CallModel.fromJson(
          Map<String, dynamic>.from(data),
          CallDirection.incoming,
        );
        currentCall = call;

        if (onIncomingCall != null) {
          onIncomingCall!(call);
        }
      } catch (e) {
        print('❌ Error parsing incoming call: $e');
        if (onCallError != null) {
          onCallError!('Failed to parse incoming call');
        }
      }
    });

    // Listen for call accepted (when receiver accepts)
    _socket!.on('call:accepted', (data) async {
      print('✅ Call accepted: $data');

      if (currentCall != null) {
        currentCall = currentCall!.copyWith(status: CallStatus.connecting);
        if (onCallAccepted != null) {
          onCallAccepted!(currentCall!);
        }

        // 🔧 FIX: For outgoing calls, create offer when accepted
        if (currentCall!.direction == CallDirection.outgoing) {
          try {
            await _webrtcService.createOffer(
              currentCall!.callType == CallType.video,
            );
          } catch (e) {
            print('❌ Error creating offer after acceptance: $e');
            if (onCallError != null) {
              onCallError!('Failed to establish connection');
            }
          }
        }
      }
    });

    // Listen for call rejected
    _socket!.on('call:rejected', (data) {
      print('❌ Call rejected: $data');

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
      print('📡 Received offer: $data');

      try {
        final offerData = data['offer'] ?? data;
        final offer = RTCSessionDescription(
          offerData['sdp'] ?? '',
          offerData['type'] ?? 'offer',
        );

        await _webrtcService.createAnswer(
          offer,
          currentCall?.callType == CallType.video,
        );
      } catch (e) {
        print('❌ Error handling offer: $e');
        if (onCallError != null) {
          onCallError!('Failed to process call offer');
        }
      }
    });

    // Listen for WebRTC answer
    _socket!.on('call:answer-sdp', (data) async {
      print('📡 Received answer: $data');

      try {
        final answerData = data['answer'] ?? data;
        final answer = RTCSessionDescription(
          answerData['sdp'] ?? '',
          answerData['type'] ?? 'answer',
        );

        await _webrtcService.setRemoteDescription(answer);
      } catch (e) {
        print('❌ Error handling answer: $e');
        if (onCallError != null) {
          onCallError!('Failed to process call answer');
        }
      }
    });

    // Listen for ICE candidates
    _socket!.on('call:ice-candidate', (data) async {
      print('🧊 Received ICE candidate');

      try {
        final candidateData = data['candidate'] ?? data;
        final candidate = RTCIceCandidate(
          candidateData['candidate'] ?? '',
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        );

        await _webrtcService.addIceCandidate(candidate);
      } catch (e) {
        print('❌ Error adding ICE candidate: $e');
      }
    });

    // Listen for call ended
    _socket!.on('call:ended', (data) {
      print('📴 Call ended: $data');

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
      print('📵 Call missed: $data');

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
  }

  void _setupWebRTCCallbacks() {
    _webrtcService.onOfferCreated = (RTCSessionDescription offer) {
      print('📤 Sending offer');

      if (_socket == null || currentCall == null) {
        print('⚠️ Socket or currentCall is null');
        return;
      }

      _socket!.emit('call:offer', {
        'callId': currentCall!.callId,
        'targetUserId': currentCall!.userId,
        'offer': {'type': offer.type, 'sdp': offer.sdp},
      });
    };

    _webrtcService.onAnswerCreated = (RTCSessionDescription answer) {
      print('📤 Sending answer');

      if (_socket == null || currentCall == null) {
        print('⚠️ Socket or currentCall is null');
        return;
      }

      _socket!.emit('call:answer-sdp', {
        'callId': currentCall!.callId,
        'targetUserId': currentCall!.userId,
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      });
    };

    _webrtcService.onIceCandidate = (RTCIceCandidate candidate) {
      print('📤 Sending ICE candidate');

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
      print('📺 Remote stream received');

      if (currentCall != null) {
        currentCall = currentCall!.copyWith(status: CallStatus.connected);
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
      print(
        '📞 Initiating ${callType == CallType.video ? 'video' : 'audio'} call to $targetUserId',
      );

      // Check socket connection
      if (_socket == null || !(_chatSocketService?.isConnected ?? false)) {
        final error = 'Not connected to server. Please check your connection.';
        if (onCallError != null) {
          onCallError!(error);
        }
        throw Exception(error);
      }

      // Request permissions
      print('🔐 Requesting permissions for ${callType == CallType.video ? "video" : "audio"} call');
      bool permissionsGranted = await _webrtcService.requestPermissions(
        callType == CallType.video,
      );

      if (!permissionsGranted) {
        // Check which permissions are denied for better error messages
        final micStatus = await Permission.microphone.status;
        final cameraStatus = callType == CallType.video 
            ? await Permission.camera.status 
            : PermissionStatus.granted;
        
        print('❌ Permissions denied - Mic: $micStatus, Camera: $cameraStatus');
        
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
        
        print('❌ Permission error: $error');
        if (onCallError != null) {
          onCallError!(error);
        }
        throw Exception(error);
      }
      
      print('✅ Permissions granted');

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
          if (isCompleted) return;
          isCompleted = true;

          if (response != null && response is Map) {
            if (response['status'] == 'success' ||
                response['success'] == true) {
              final callId = response['callId'] ?? response['_id'];
              if (callId != null && currentCall != null) {
                currentCall = currentCall!.copyWith(callId: callId.toString());
              }

              // ✅ Don't create offer here - wait for call:accepted event
              print('✅ Call initiated successfully, callId: ${currentCall?.callId}');
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
    } catch (e) {
      print('❌ Error initiating call: $e');
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
    if (currentCall == null) return;

    try {
      print('✅ Accepting call: ${currentCall!.callId}');

      if (_socket == null) {
        if (onCallError != null) {
          onCallError!('Not connected to server');
        }
        return;
      }

      // Request permissions
      bool permissionsGranted = await _webrtcService.requestPermissions(
        currentCall!.callType == CallType.video,
      );

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
      _socket!.emit('call:answer', {
        'callId': currentCall!.callId,
        'accept': true,
      });

      currentCall = currentCall!.copyWith(status: CallStatus.connecting);

      // Note: The offer will come via 'call:offer' event, then we create answer
    } catch (e) {
      print('❌ Error accepting call: $e');
      rejectCall();
    }
  }

  void rejectCall() {
    if (currentCall == null) return;

    print('❌ Rejecting call: ${currentCall!.callId}');

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

    print('📴 Ending call: ${currentCall!.callId}');

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
  }

  void toggleVideo() {
    _webrtcService.toggleCamera();
  }

  bool get isMuted => !_webrtcService.isMicrophoneEnabled;
  bool get isVideoEnabled => _webrtcService.isCameraEnabled;

  Future<void> switchCamera() async {
    await _webrtcService.switchCamera();
  }

  void _cleanup() {
    print('🧹 Cleaning up call resources...');
    _webrtcService.dispose();
    currentCall = null;
  }

  void dispose() {
    _cleanup();
  }
}
