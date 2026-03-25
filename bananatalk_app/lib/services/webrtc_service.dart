import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Multi-peer support for voice rooms
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};

  // Callbacks for multi-peer
  Function(String peerId, RTCSessionDescription)? onMultiPeerOfferCreated;
  Function(String peerId, RTCSessionDescription)? onMultiPeerAnswerCreated;
  Function(String peerId, RTCIceCandidate)? onMultiPeerIceCandidate;
  Function(String peerId, MediaStream)? onMultiPeerRemoteStream;
  Function(String peerId)? onMultiPeerConnected;
  Function(String peerId)? onMultiPeerDisconnected;

  // TURN server configuration
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:64.23.181.246:3478',
        'username': 'bananatalk',
        'credential': 'BananaTalk2025!'
      }
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  // Callbacks
  Function(RTCSessionDescription)? onOfferCreated;
  Function(RTCSessionDescription)? onAnswerCreated;
  Function(RTCIceCandidate)? onIceCandidate;
  Function(MediaStream)? onRemoteStream;
  Function()? onConnectionStateChange;

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<bool> requestPermissions(bool isVideo) async {
    
    // Check current permission status first
    final micStatus = await Permission.microphone.status;
    
    final cameraStatus = isVideo ? await Permission.camera.status : PermissionStatus.granted;
    if (isVideo) {
    }
    
    // If already granted, return true
    if (micStatus.isGranted && cameraStatus.isGranted) {
      return true;
    }
    
    // If permanently denied, return false immediately (don't request again)
    if (micStatus.isPermanentlyDenied || (isVideo && cameraStatus.isPermanentlyDenied)) {
      return false;
    }
    
    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      if (isVideo) Permission.camera,
    ].request();

    statuses.forEach((permission, status) {
    });

    bool allGranted = statuses.values.every((status) => status.isGranted);
    return allGranted;
  }
  
  /// Check if permissions are permanently denied
  Future<bool> arePermissionsPermanentlyDenied(bool isVideo) async {
    final micStatus = await Permission.microphone.status;
    final cameraStatus = isVideo ? await Permission.camera.status : PermissionStatus.granted;
    
    return micStatus.isPermanentlyDenied || 
           (isVideo && cameraStatus.isPermanentlyDenied);
  }

  Future<void> createOffer(bool isVideo) async {
    try {

      // Get user media
      final constraints = <String, dynamic>{
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = _localStream;

      // Create peer connection
      _peerConnection = await createPeerConnection(_iceServers, _config);

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Setup callbacks
      _setupPeerConnectionListeners();

      // Create offer
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });

      await _peerConnection!.setLocalDescription(offer);

      if (onOfferCreated != null) {
        onOfferCreated!(offer);
      }

    } catch (e) {
      rethrow;
    }
  }

  Future<void> createAnswer(
    RTCSessionDescription offer,
    bool isVideo,
  ) async {
    try {

      // Get user media
      final constraints = <String, dynamic>{
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = _localStream;

      // Create peer connection
      _peerConnection = await createPeerConnection(_iceServers, _config);

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Setup callbacks
      _setupPeerConnectionListeners();

      // Set remote description (offer)
      await _peerConnection!.setRemoteDescription(offer);

      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });

      await _peerConnection!.setLocalDescription(answer);

      if (onAnswerCreated != null) {
        onAnswerCreated!(answer);
      }

    } catch (e) {
      rethrow;
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      await _peerConnection?.setRemoteDescription(description);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      if (_peerConnection != null) {
        await _peerConnection!.addCandidate(candidate);
      }
    } catch (e) {
    }
  }

  void _setupPeerConnectionListeners() {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (onIceCandidate != null) {
        onIceCandidate!(candidate);
      }
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;

        if (onRemoteStream != null) {
          onRemoteStream!(_remoteStream!);
        }
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      if (onConnectionStateChange != null) {
        onConnectionStateChange!();
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
    };

    _peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
    };
  }

  void toggleMicrophone() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        bool enabled = audioTracks[0].enabled;
        audioTracks[0].enabled = !enabled;
      }
    }
  }

  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        bool enabled = videoTracks[0].enabled;
        videoTracks[0].enabled = !enabled;
      }
    }
  }

  bool get isMicrophoneEnabled {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        return audioTracks[0].enabled;
      }
    }
    return false;
  }

  bool get isCameraEnabled {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        return videoTracks[0].enabled;
      }
    }
    return false;
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
      }
    }
  }

  Future<void> dispose() async {
    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _remoteStream?.getTracks().forEach((track) => track.stop());
      _remoteStream?.dispose();
      await _peerConnection?.close();
      _peerConnection = null;
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (e) {
    }
  }

  bool get isConnected =>
      _peerConnection?.connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  // ============ Multi-Peer Methods for Voice Rooms ============

  /// Initialize local stream for voice room (audio only)
  Future<void> initLocalStreamForRoom() async {
    if (_localStream != null) return;

    final constraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = _localStream;
  }

  /// Create offer for a specific peer in multi-peer mode
  Future<void> createOfferForPeer(String peerId) async {
    try {
      // Ensure local stream is initialized
      await initLocalStreamForRoom();

      // Create peer connection for this peer
      final pc = await createPeerConnection(_iceServers, _config);
      _peerConnections[peerId] = pc;

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });

      // Setup listeners for this peer
      _setupMultiPeerListeners(peerId, pc);

      // Create offer
      RTCSessionDescription offer = await pc.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });

      await pc.setLocalDescription(offer);
      onMultiPeerOfferCreated?.call(peerId, offer);
    } catch (e) {
      rethrow;
    }
  }

  /// Create answer for a specific peer's offer in multi-peer mode
  Future<void> createAnswerForPeer(
    String peerId,
    RTCSessionDescription offer,
  ) async {
    try {
      // Ensure local stream is initialized
      await initLocalStreamForRoom();

      // Create peer connection for this peer
      final pc = await createPeerConnection(_iceServers, _config);
      _peerConnections[peerId] = pc;

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });

      // Setup listeners for this peer
      _setupMultiPeerListeners(peerId, pc);

      // Set remote description (offer)
      await pc.setRemoteDescription(offer);

      // Create answer
      RTCSessionDescription answer = await pc.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });

      await pc.setLocalDescription(answer);
      onMultiPeerAnswerCreated?.call(peerId, answer);
    } catch (e) {
      rethrow;
    }
  }

  /// Set remote description for a specific peer
  Future<void> setRemoteDescriptionForPeer(
    String peerId,
    RTCSessionDescription description,
  ) async {
    final pc = _peerConnections[peerId];
    if (pc != null) {
      await pc.setRemoteDescription(description);
    }
  }

  /// Add ICE candidate for a specific peer
  Future<void> addIceCandidateForPeer(
    String peerId,
    RTCIceCandidate candidate,
  ) async {
    final pc = _peerConnections[peerId];
    if (pc != null) {
      await pc.addCandidate(candidate);
    }
  }

  /// Disconnect from a specific peer
  Future<void> disconnectFromPeer(String peerId) async {
    final pc = _peerConnections.remove(peerId);
    await pc?.close();

    final stream = _remoteStreams.remove(peerId);
    stream?.getTracks().forEach((track) => track.stop());
    stream?.dispose();
  }

  /// Cleanup all multi-peer connections
  Future<void> disposeMultiPeer() async {
    // Close all peer connections
    for (final entry in _peerConnections.entries) {
      await entry.value.close();
    }
    _peerConnections.clear();

    // Dispose all remote streams
    for (final stream in _remoteStreams.values) {
      stream.getTracks().forEach((track) => track.stop());
      await stream.dispose();
    }
    _remoteStreams.clear();

    // Dispose local stream
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;
  }

  void _setupMultiPeerListeners(String peerId, RTCPeerConnection pc) {
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      onMultiPeerIceCandidate?.call(peerId, candidate);
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[peerId] = event.streams[0];
        onMultiPeerRemoteStream?.call(peerId, event.streams[0]);
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onMultiPeerConnected?.call(peerId);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        onMultiPeerDisconnected?.call(peerId);
      }
    };
  }

  /// Get the number of active peer connections
  int get peerCount => _peerConnections.length;

  /// Check if connected to a specific peer
  bool isPeerConnected(String peerId) {
    final pc = _peerConnections[peerId];
    return pc?.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected;
  }

  /// Get remote stream for a specific peer
  MediaStream? getRemoteStream(String peerId) => _remoteStreams[peerId];
}

