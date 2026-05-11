import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/services/voice_room_livekit_manager.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

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

/// Voice Room Manager — orchestrates voice-room business logic.
///
/// Transport (audio in/out, active speakers, transport-level presence) is
/// delegated to [VoiceRoomLiveKitManager]. Socket.io is retained for the
/// business-event channel: chat, hand-raise, host transfer, room-ended,
/// kicked, mute broadcasts (for cross-client snappiness).
class VoiceRoomManager {
  static final VoiceRoomManager _instance = VoiceRoomManager._internal();
  factory VoiceRoomManager() => _instance;
  VoiceRoomManager._internal();

  /// LiveKit-backed transport. Replaces the prior mesh-WebRTC peer fan-out
  /// driven by offer/answer/ICE socket signaling.
  final VoiceRoomLiveKitManager _liveKit = VoiceRoomLiveKitManager();

  ChatSocketService? _chatSocketService;
  sio.Socket? _socket;
  bool _isInitialized = false;

  VoiceRoom? _currentRoom;
  List<RoomParticipant> _participants = [];
  List<VoiceRoomChatMessage> _chatMessages = [];
  bool _isMuted = true; // Start muted by default
  bool _isHandRaised = false;

  // Timers
  Timer? _heartbeatTimer;

  // Stream subscriptions (socket.io business events only)
  StreamSubscription? _participantJoinedSub;
  StreamSubscription? _participantLeftSub;
  StreamSubscription? _muteSub;
  StreamSubscription? _handRaisedSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _kickedSub;
  StreamSubscription? _hostChangedSub;
  StreamSubscription<bool>? _connectionSub;

  // Reconnect state
  bool _isReconnecting = false;
  bool get isReconnecting => _isReconnecting;

  // Callbacks
  Function(String newHostId, String? previousHostId)? onHostChanged;
  Function(RoomParticipant)? onParticipantJoined;
  Function(String participantId)? onParticipantLeft;
  Function(VoiceRoomChatMessage)? onChatMessage;
  Function()? onRoomEnded;
  Function()? onKicked;
  Function()? onStateChanged;
  Function()? onConnectionChanged;
  /// Called when the host issues a mute-all and this user was forcibly muted.
  Function()? onForcedMuteSelf;
  /// Fired when a remote participant sends an in-room emoji reaction over
  /// the LiveKit data channel. [participantId] is the sender's user id;
  /// [emoji] is the rendered glyph. UI consumers should anchor a floating
  /// emoji at the sender's avatar. Self-display is the caller's job
  /// (LiveKit doesn't echo data packets to the publisher).
  Function(String participantId, String emoji)? onReactionReceived;

  // Getters
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
    _setupSocketListeners();
    _setupLiveKitCallbacks();
    _setupConnectionListener();
    _isInitialized = true;
  }

  void _setupConnectionListener() {
    _connectionSub?.cancel();
    _connectionSub = _chatSocketService!.onConnectionStateChange.listen((connected) {
      if (_currentRoom == null) return;

      if (!connected) {
        _isReconnecting = true;
        onConnectionChanged?.call();
        onStateChanged?.call();
        return;
      }

      // Reconnected — refresh socket reference then emit rejoin with ACK
      _socket = _chatSocketService!.socket;

      final payload = {
        'roomId': _currentRoom!.id,
        'lastSeenAt': DateTime.now().toIso8601String(),
      };

      _socket?.emitWithAck(
        'voiceroom:rejoin',
        payload,
        ack: (ackData) {
          _isReconnecting = false;
          if (ackData is Map) {
            final m = Map<String, dynamic>.from(ackData);
            if (m['ended'] == true || m['ok'] == false) {
              onRoomEnded?.call();
              _cleanup();
              return;
            }
            // Update hostId if demoted during reconnect gap
            if (m['currentHostId'] != null && _currentRoom != null) {
              _currentRoom = _currentRoom!.copyWith(
                hostId: m['currentHostId'].toString(),
              );
            }
          }
          onConnectionChanged?.call();
          onStateChanged?.call();
        },
      );
    });
  }

  void _setupSocketListeners() {
    if (_chatSocketService == null) return;

    // Participant joined — business-layer source of truth for avatar/joinedAt/host.
    // LiveKit's own ParticipantConnected event may arrive earlier and seed a
    // stub; this event hydrates it with the canonical Mongo fields.
    _participantJoinedSub = _chatSocketService!.onVoiceRoomParticipantJoined.listen((data) {
      final participant = RoomParticipant.fromJson(Map<String, dynamic>.from(data));
      final existing = _participants.indexWhere((p) => p.id == participant.id);
      if (existing != -1) {
        // Preserve any LiveKit-driven runtime state (speaking/mute) we may
        // have already learned from the transport layer before this event.
        final prev = _participants[existing];
        _participants[existing] = participant.copyWith(
          isSpeaking: prev.isSpeaking,
          isMuted: prev.isMuted,
        );
      } else {
        _participants.add(participant);
      }
      onParticipantJoined?.call(participant);
      onStateChanged?.call();
    });

    // Participant left
    _participantLeftSub = _chatSocketService!.onVoiceRoomParticipantLeft.listen((data) {
      final userId = data['userId']?.toString() ?? '';
      _participants.removeWhere((p) => p.id == userId);
      onParticipantLeft?.call(userId);
      onStateChanged?.call();
    });

    // Participant mute state — broadcast for snappy cross-client UI;
    // LiveKit's TrackMuted event lags by ~100ms and also updates this.
    _muteSub = _chatSocketService!.onVoiceRoomMute.listen((data) {
      final participantId = data['userId']?.toString() ?? '';
      final isMuted = data['isMuted'] == true;
      final forced = data['forced'] == true;

      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = _participants[index].copyWith(isMuted: isMuted);
      }

      // If this is a forced mute aimed at the local user, mute the mic too
      if (forced && isMuted) {
        final myId = _chatSocketService?.currentUserId;
        if (myId != null && participantId == myId) {
          _liveKit.setMuted(true);
          _isMuted = true;
          onForcedMuteSelf?.call();
        }
      }

      onStateChanged?.call();
    });

    // Hand raised
    _handRaisedSub = _chatSocketService!.onVoiceRoomHandRaised.listen((data) {
      final participantId = data['userId']?.toString() ?? '';
      final isRaised = data['isRaised'] == true;
      if (participantId.isEmpty) return;
      final i = _participants.indexWhere((p) => p.id == participantId);
      if (i != -1) {
        _participants[i] = _participants[i].copyWith(isHandRaised: isRaised);
        onStateChanged?.call();
      }
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

    // Host transferred
    _hostChangedSub = _chatSocketService!.onVoiceRoomHostChanged.listen((data) {
      if (_currentRoom == null) return;
      final m = data is Map ? Map<String, dynamic>.from(data) : null;
      if (m == null) return;
      final newHostId = m['newHostId']?.toString() ?? '';
      final previousHostId = m['previousHostId']?.toString();
      if (newHostId.isEmpty) return;

      // Update room hostId
      _currentRoom = _currentRoom!.copyWith(hostId: newHostId);

      // Flip isHost flags on participants
      for (var i = 0; i < _participants.length; i++) {
        final p = _participants[i];
        if (p.id == newHostId) {
          _participants[i] = p.copyWith(isHost: true);
        } else if (p.isHost) {
          _participants[i] = p.copyWith(isHost: false);
        }
      }

      onHostChanged?.call(newHostId, previousHostId);
      onStateChanged?.call();
    });
  }

  void _setupLiveKitCallbacks() {
    // Transport-level join. Socket `voiceroom:joined` is the authoritative
    // source for full participant data; if LiveKit beats it here, insert a
    // stub so the speaking/mute deltas have somewhere to land. The socket
    // event will then merge in avatar/joinedAt/isHost.
    _liveKit.onParticipantJoined = (participant) {
      final existing = _participants.indexWhere((p) => p.id == participant.id);
      if (existing == -1) {
        _participants.add(participant);
        onStateChanged?.call();
      }
    };

    _liveKit.onParticipantLeft = (participantId) {
      // Don't remove on LiveKit-only signal — wait for the authoritative
      // socket `voiceroom:left`. (Transport disconnect can be transient
      // during reconnect; socket event is the canonical leave.)
      // We DO clear their speaking flag, though, so the UI doesn't pulse.
      final i = _participants.indexWhere((p) => p.id == participantId);
      if (i != -1 && _participants[i].isSpeaking) {
        _participants[i] = _participants[i].copyWith(isSpeaking: false);
        onStateChanged?.call();
      }
    };

    _liveKit.onParticipantSpeakingChanged = (participantId, isSpeaking) {
      final i = _participants.indexWhere((p) => p.id == participantId);
      if (i == -1) return;
      final p = _participants[i];
      // Suppress speaking pulse for muted users (defense-in-depth; LiveKit
      // shouldn't emit them as active speakers but UI shouldn't trust that).
      final effective = isSpeaking && !p.isMuted;
      if (p.isSpeaking != effective) {
        _participants[i] = p.copyWith(isSpeaking: effective);
        onStateChanged?.call();
      }
    };

    _liveKit.onParticipantMuteChanged = (participantId, isMuted) {
      final i = _participants.indexWhere((p) => p.id == participantId);
      if (i == -1) return;
      final p = _participants[i];
      if (p.isMuted != isMuted) {
        _participants[i] = p.copyWith(isMuted: isMuted);
        onStateChanged?.call();
      }
    };

    _liveKit.onRoomReconnecting = () {
      _isReconnecting = true;
      onConnectionChanged?.call();
      onStateChanged?.call();
    };

    _liveKit.onRoomReconnected = () {
      _isReconnecting = false;
      onConnectionChanged?.call();
      onStateChanged?.call();
    };

    _liveKit.onRoomDisconnected = () {
      // Transport disconnect doesn't itself end the room — the socket
      // `voiceroom:ended` does. Just surface the reconnecting flag.
      if (_currentRoom != null) {
        _isReconnecting = true;
        onConnectionChanged?.call();
        onStateChanged?.call();
      }
    };

    _liveKit.onReactionReceived = (participantId, emoji) {
      onReactionReceived?.call(participantId, emoji);
    };
  }

  /// Join a voice room.
  ///
  /// 1. `POST voicerooms/:id/join` to mutate Mongo state and obtain the
  ///    authoritative participant list (avatars, host, joinedAt).
  /// 2. Connect to LiveKit (muted) for media transport.
  /// 3. Announce join on the socket business channel so other clients
  ///    receive `voiceroom:joined` for their own UI.
  Future<void> joinRoom(VoiceRoom room) async {
    debugPrint('[VR] joinRoom id=${room.id} title=${room.title}');
    if (_socket == null || !(_chatSocketService?.isConnected ?? false)) {
      debugPrint('[VR] joinRoom FAILED: socket not connected');
      throw Exception('Not connected to server');
    }

    // Seed local state from the room snapshot the caller already holds.
    _currentRoom = room;
    _participants = List.from(room.participants);
    _chatMessages = [];
    _isMuted = true;
    _isHandRaised = false;

    // 1) Persist join via REST, 2) connect transport — run in parallel.
    final joinFuture = ApiClient().post('voicerooms/${room.id}/join');
    final connectFuture = _liveKit.connect(roomId: room.id);
    final joinRes = await joinFuture;
    await connectFuture;

    if (joinRes.success && joinRes.data != null) {
      // The /join endpoint returns the updated room (with full participant
      // list). Reseed from it so we have canonical avatars + joinedAt.
      final data = joinRes.data;
      Map<String, dynamic>? roomJson;
      if (data is Map<String, dynamic>) {
        if (data['participants'] is List) {
          roomJson = data;
        } else if (data['data'] is Map<String, dynamic>) {
          roomJson = Map<String, dynamic>.from(data['data']);
        }
      }
      if (roomJson != null) {
        try {
          final updated = VoiceRoom.fromJson(roomJson);
          _currentRoom = updated;
          _participants = List.from(updated.participants);
        } catch (e) {
          debugPrint('VoiceRoomManager: failed to parse join response: $e');
        }
      }
    }

    // Announce on the socket business channel for cross-client notification.
    _socket!.emit('voiceroom:join', {'roomId': room.id});

    // Heartbeat keeps the server-side presence record fresh.
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_currentRoom != null && _socket != null) {
        _socket!.emit('voiceroom:heartbeat', {'roomId': _currentRoom!.id});
      }
    });

    onStateChanged?.call();
  }

  /// Leave the current room — disconnect LiveKit first to silence the mic
  /// promptly, then notify the server via socket + REST.
  Future<void> leaveRoom() async {
    debugPrint('[VR] leaveRoom id=${_currentRoom?.id}');
    if (_currentRoom == null) return;
    final roomId = _currentRoom!.id;

    await _liveKit.disconnect();
    _socket?.emit('voiceroom:leave', {'roomId': roomId});
    // Fire-and-forget the REST leave; cleanup local state immediately so the
    // UI doesn't sit in a half-left state if the request is slow.
    unawaited(ApiClient().post('voicerooms/$roomId/leave'));
    _cleanup();
  }

  /// Toggle mute state — flips the LiveKit local mic, then broadcasts on
  /// the socket for snappy cross-client UI (LiveKit's own TrackMuted
  /// event reaches peers ~100ms later).
  void toggleMute() {
    _isMuted = !_isMuted;
    _liveKit.setMuted(_isMuted);

    debugPrint('Voice room mute toggled: isMuted=$_isMuted');

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

  /// Broadcast an in-room emoji reaction over the LiveKit data channel.
  /// Peer-to-peer; the backend is not involved. LiveKit does NOT echo data
  /// to the publisher, so the caller is responsible for self-display.
  Future<void> sendReaction(String emoji) async {
    if (_currentRoom == null) return;
    await _liveKit.sendReaction(emoji);
  }

  /// Mute all participants (host only)
  void muteAll() {
    if (_currentRoom == null) return;
    _socket?.emit('voiceroom:mute-all', {'roomId': _currentRoom!.id});
  }

  /// Kick a participant (host only)
  void kickParticipant(String participantId) {
    _socket?.emit('voiceroom:kick', {
      'roomId': _currentRoom?.id,
      'targetUserId': participantId,
    });
  }

  /// End the room (host only). Disconnects LiveKit, fires the REST
  /// `POST /voicerooms/:id/end` (backend marks status='ended', emits
  /// voiceroom:ended to subscribers + globally so every client list
  /// drops the row), and clears local state.
  void endRoom() {
    debugPrint('[VR] endRoom id=${_currentRoom?.id}');
    final roomId = _currentRoom?.id;
    if (roomId == null) return;
    unawaited(_liveKit.disconnect());
    // REST is authoritative for ending the room — the backend marks it
    // 'ended' and fans out voiceroom:ended over sockets. Fire-and-forget
    // so the local UI clears immediately; if the request fails the
    // room will linger as 'active' in DB and the host can retry from
    // the rooms tab.
    unawaited(ApiClient().post('voicerooms/$roomId/end'));
    _cleanup();
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _currentRoom = null;
    _participants = [];
    _chatMessages = [];
    _isMuted = true;
    _isHandRaised = false;
    onStateChanged?.call();
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _participantJoinedSub?.cancel();
    _participantLeftSub?.cancel();
    _muteSub?.cancel();
    _handRaisedSub?.cancel();
    _chatSub?.cancel();
    _endedSub?.cancel();
    _kickedSub?.cancel();
    _hostChangedSub?.cancel();
    _connectionSub?.cancel();
    unawaited(_liveKit.disconnect());
    _cleanup();
  }
}
