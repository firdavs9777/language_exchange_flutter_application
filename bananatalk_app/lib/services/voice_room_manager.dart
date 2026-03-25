import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/services/webrtc_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Chat message in voice room
class VoiceRoomChatMessage {
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;

  const VoiceRoomChatMessage({
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
  });

  factory VoiceRoomChatMessage.fromJson(Map<String, dynamic> json) {
    return VoiceRoomChatMessage(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Voice Room Manager - handles voice room orchestration
class VoiceRoomManager {
  static final VoiceRoomManager _instance = VoiceRoomManager._internal();
  factory VoiceRoomManager() => _instance;
  VoiceRoomManager._internal();

  final WebRTCService _webrtcService = WebRTCService();
  ChatSocketService? _chatSocketService;
  IO.Socket? _socket;
  bool _isInitialized = false;

  VoiceRoom? _currentRoom;
  List<RoomParticipant> _participants = [];
  List<VoiceRoomChatMessage> _chatMessages = [];
  bool _isMuted = true; // Start muted by default
  bool _isHandRaised = false;

  // Stream subscriptions
  StreamSubscription? _participantJoinedSub;
  StreamSubscription? _participantLeftSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceCandidateSub;
  StreamSubscription? _muteSub;
  StreamSubscription? _handRaisedSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _kickedSub;

  // Callbacks
  Function(RoomParticipant)? onParticipantJoined;
  Function(String participantId)? onParticipantLeft;
  Function(VoiceRoomChatMessage)? onChatMessage;
  Function()? onRoomEnded;
  Function()? onKicked;
  Function()? onStateChanged;

  // Getters
  WebRTCService get webrtcService => _webrtcService;
  VoiceRoom? get currentRoom => _currentRoom;
  List<RoomParticipant> get participants => List.unmodifiable(_participants);
  List<VoiceRoomChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  bool get isMuted => _isMuted;
  bool get isHandRaised => _isHandRaised;
  bool get isInRoom => _currentRoom != null;

  Future<void> initialize(ChatSocketService chatSocketService) async {
    if (_isInitialized && _chatSocketService == chatSocketService) {
      return;
    }

    _chatSocketService = chatSocketService;
    _socket = chatSocketService.socket;
    await _webrtcService.initialize();
    _setupSocketListeners();
    _setupWebRTCCallbacks();
    _isInitialized = true;
  }

  void _setupSocketListeners() {
    if (_chatSocketService == null) return;

    // Participant joined
    _participantJoinedSub = _chatSocketService!.onVoiceRoomParticipantJoined.listen((data) {
      final participant = RoomParticipant.fromJson(Map<String, dynamic>.from(data));
      _participants.add(participant);
      onParticipantJoined?.call(participant);
      onStateChanged?.call();

      // Create offer for the new participant
      _webrtcService.createOfferForPeer(participant.id);
    });

    // Participant left
    _participantLeftSub = _chatSocketService!.onVoiceRoomParticipantLeft.listen((data) {
      final userId = data['userId']?.toString() ?? '';
      _participants.removeWhere((p) => p.id == userId);
      _webrtcService.disconnectFromPeer(userId);
      onParticipantLeft?.call(userId);
      onStateChanged?.call();
    });

    // WebRTC offer from peer
    _offerSub = _chatSocketService!.onVoiceRoomOffer.listen((data) async {
      final peerId = data['fromUserId']?.toString() ?? '';
      final offerData = data['offer'];
      if (peerId.isEmpty || offerData == null) return;

      final offer = RTCSessionDescription(
        offerData['sdp'] ?? '',
        offerData['type'] ?? 'offer',
      );

      await _webrtcService.createAnswerForPeer(peerId, offer);
    });

    // WebRTC answer from peer
    _answerSub = _chatSocketService!.onVoiceRoomAnswer.listen((data) async {
      final peerId = data['fromUserId']?.toString() ?? '';
      final answerData = data['answer'];
      if (peerId.isEmpty || answerData == null) return;

      final answer = RTCSessionDescription(
        answerData['sdp'] ?? '',
        answerData['type'] ?? 'answer',
      );

      await _webrtcService.setRemoteDescriptionForPeer(peerId, answer);
    });

    // ICE candidate from peer
    _iceCandidateSub = _chatSocketService!.onVoiceRoomIceCandidate.listen((data) async {
      final peerId = data['fromUserId']?.toString() ?? '';
      final candidateData = data['candidate'];
      if (peerId.isEmpty || candidateData == null) return;

      final candidate = RTCIceCandidate(
        candidateData['candidate'] ?? '',
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await _webrtcService.addIceCandidateForPeer(peerId, candidate);
    });

    // Participant mute state
    _muteSub = _chatSocketService!.onVoiceRoomMute.listen((data) {
      final participantId = data['userId']?.toString() ?? '';
      final isMuted = data['isMuted'] == true;

      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = RoomParticipant(
          id: _participants[index].id,
          name: _participants[index].name,
          avatar: _participants[index].avatar,
          isSpeaking: _participants[index].isSpeaking,
          isMuted: isMuted,
          isHost: _participants[index].isHost,
          joinedAt: _participants[index].joinedAt,
        );
        onStateChanged?.call();
      }
    });

    // Hand raised
    _handRaisedSub = _chatSocketService!.onVoiceRoomHandRaised.listen((data) {
      final participantId = data['userId']?.toString() ?? '';
      final isHandRaised = data['isRaised'] == true;

      // Update participant if needed (could add handRaised to model)
      onStateChanged?.call();
    });

    // Chat message
    _chatSub = _chatSocketService!.onVoiceRoomChat.listen((data) {
      final message = VoiceRoomChatMessage.fromJson(Map<String, dynamic>.from(data));
      _chatMessages.add(message);
      onChatMessage?.call(message);
      onStateChanged?.call();
    });

    // Room ended
    _endedSub = _chatSocketService!.onVoiceRoomEnded.listen((data) {
      onRoomEnded?.call();
      _cleanup();
    });

    // Kicked from room
    _kickedSub = _chatSocketService!.onVoiceRoomKicked.listen((data) {
      onKicked?.call();
      _cleanup();
    });
  }

  void _setupWebRTCCallbacks() {
    // When we create an offer for a peer
    _webrtcService.onMultiPeerOfferCreated = (peerId, offer) {
      _socket?.emit('voiceroom:offer', {
        'roomId': _currentRoom?.id,
        'targetUserId': peerId,
        'offer': {'type': offer.type, 'sdp': offer.sdp},
      });
    };

    // When we create an answer for a peer
    _webrtcService.onMultiPeerAnswerCreated = (peerId, answer) {
      _socket?.emit('voiceroom:answer', {
        'roomId': _currentRoom?.id,
        'targetUserId': peerId,
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      });
    };

    // When we have an ICE candidate for a peer
    _webrtcService.onMultiPeerIceCandidate = (peerId, candidate) {
      _socket?.emit('voiceroom:ice-candidate', {
        'roomId': _currentRoom?.id,
        'targetUserId': peerId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
  }

  /// Join a voice room
  Future<void> joinRoom(VoiceRoom room) async {
    if (_socket == null || !(_chatSocketService?.isConnected ?? false)) {
      throw Exception('Not connected to server');
    }

    // Request permissions
    final permissionsGranted = await _webrtcService.requestPermissions(false);
    if (!permissionsGranted) {
      throw Exception('Microphone permission required');
    }

    // Initialize local stream
    await _webrtcService.initLocalStreamForRoom();

    _currentRoom = room;
    _participants = List.from(room.participants);
    _chatMessages = [];
    _isMuted = true;
    _isHandRaised = false;

    // Emit join event
    _socket!.emit('voiceroom:join', {'roomId': room.id});

    // Create offers for existing participants
    for (final participant in _participants) {
      if (participant.id != _chatSocketService?.currentUserId) {
        await _webrtcService.createOfferForPeer(participant.id);
      }
    }

    onStateChanged?.call();
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    if (_currentRoom == null) return;

    _socket?.emit('voiceroom:leave', {'roomId': _currentRoom!.id});
    _cleanup();
  }

  /// Toggle mute state
  void toggleMute() {
    _webrtcService.toggleMicrophone();
    _isMuted = !_webrtcService.isMicrophoneEnabled;

    _socket?.emit('voiceroom:mute', {
      'roomId': _currentRoom?.id,
      'isMuted': _isMuted,
    });

    onStateChanged?.call();
  }

  /// Toggle hand raised
  void toggleHandRaised() {
    _isHandRaised = !_isHandRaised;

    _socket?.emit('voiceroom:raise-hand', {
      'roomId': _currentRoom?.id,
      'isRaised': _isHandRaised,
    });

    onStateChanged?.call();
  }

  /// Send chat message
  void sendChat(String message) {
    if (message.trim().isEmpty || _currentRoom == null) return;

    _socket?.emit('voiceroom:chat', {
      'roomId': _currentRoom!.id,
      'message': message.trim(),
    });
  }

  /// Kick a participant (host only)
  void kickParticipant(String participantId) {
    _socket?.emit('voiceroom:kick', {
      'roomId': _currentRoom?.id,
      'targetUserId': participantId,
    });
  }

  /// End the room (host only)
  void endRoom() {
    _socket?.emit('voiceroom:end', {'roomId': _currentRoom?.id});
    _cleanup();
  }

  void _cleanup() {
    _webrtcService.disposeMultiPeer();
    _currentRoom = null;
    _participants = [];
    _chatMessages = [];
    _isMuted = true;
    _isHandRaised = false;
    onStateChanged?.call();
  }

  void dispose() {
    _participantJoinedSub?.cancel();
    _participantLeftSub?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _iceCandidateSub?.cancel();
    _muteSub?.cancel();
    _handRaisedSub?.cancel();
    _chatSub?.cancel();
    _endedSub?.cancel();
    _kickedSub?.cancel();
    _cleanup();
  }
}
