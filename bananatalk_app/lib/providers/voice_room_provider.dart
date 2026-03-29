import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/services/voice_room_manager.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// State for voice room
class VoiceRoomState {
  final VoiceRoom? currentRoom;
  final List<RoomParticipant> participants;
  final List<VoiceRoomChatMessage> chatMessages;
  final bool isMuted;
  final bool isHandRaised;
  final bool isLoading;
  final String? error;

  const VoiceRoomState({
    this.currentRoom,
    this.participants = const [],
    this.chatMessages = const [],
    this.isMuted = true,
    this.isHandRaised = false,
    this.isLoading = false,
    this.error,
  });

  VoiceRoomState copyWith({
    VoiceRoom? currentRoom,
    List<RoomParticipant>? participants,
    List<VoiceRoomChatMessage>? chatMessages,
    bool? isMuted,
    bool? isHandRaised,
    bool? isLoading,
    String? error,
  }) {
    return VoiceRoomState(
      currentRoom: currentRoom ?? this.currentRoom,
      participants: participants ?? this.participants,
      chatMessages: chatMessages ?? this.chatMessages,
      isMuted: isMuted ?? this.isMuted,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isInRoom => currentRoom != null;
}

class VoiceRoomNotifier extends ChangeNotifier {
  final VoiceRoomManager _manager = VoiceRoomManager();
  final ApiClient _apiClient = ApiClient();

  VoiceRoomState _state = const VoiceRoomState();
  VoiceRoomState get state => _state;

  // Convenience getters
  VoiceRoom? get currentRoom => _state.currentRoom;
  List<RoomParticipant> get participants => _state.participants;
  List<VoiceRoomChatMessage> get chatMessages => _state.chatMessages;
  bool get isMuted => _state.isMuted;
  bool get isHandRaised => _state.isHandRaised;
  bool get isInRoom => _state.isInRoom;
  bool get isLoading => _state.isLoading;

  VoiceRoomManager get manager => _manager;

  VoiceRoomNotifier() {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _manager.onParticipantJoined = (participant) {
      _updateState();
    };

    _manager.onParticipantLeft = (participantId) {
      _updateState();
    };

    _manager.onChatMessage = (message) {
      _updateState();
    };

    _manager.onRoomEnded = () {
      _state = _state.copyWith(
        currentRoom: null,
        participants: [],
        chatMessages: [],
        error: 'Room ended by host',
      );
      notifyListeners();
    };

    _manager.onKicked = () {
      _state = _state.copyWith(
        currentRoom: null,
        participants: [],
        chatMessages: [],
        error: 'You were removed from the room',
      );
      notifyListeners();
    };

    _manager.onStateChanged = () {
      _updateState();
    };
  }

  void _updateState() {
    _state = _state.copyWith(
      currentRoom: _manager.currentRoom,
      participants: _manager.participants,
      chatMessages: _manager.chatMessages,
      isMuted: _manager.isMuted,
      isHandRaised: _manager.isHandRaised,
    );
    notifyListeners();
  }

  /// Create a new voice room
  Future<VoiceRoom> createRoom(CreateRoomRequest request) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _apiClient.post(
        'voicerooms',
        body: request.toJson(),
      );

      if (response.success) {
        final data = response.data is Map<String, dynamic> ? response.data : response.data['data'];
        final room = VoiceRoom.fromJson(Map<String, dynamic>.from(data));

        _state = _state.copyWith(isLoading: false);
        notifyListeners();

        return room;
      } else {
        throw Exception(response.error ?? 'Failed to create room');
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Ensure VoiceRoomManager is initialized with the socket
  Future<void> _ensureInitialized() async {
    final chatSocketService = ChatSocketService();
    await _manager.initialize(chatSocketService);
  }

  /// Join an existing voice room
  Future<void> joinRoom(VoiceRoom room) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _ensureInitialized();
      await _manager.joinRoom(room);
      _updateState();
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    await _manager.leaveRoom();
    _state = const VoiceRoomState();
    notifyListeners();
  }

  /// Toggle mute
  void toggleMute() {
    _manager.toggleMute();
    _updateState();
  }

  /// Toggle hand raised
  void toggleHandRaised() {
    _manager.toggleHandRaised();
    _updateState();
  }

  /// Send chat message
  void sendChat(String message) {
    _manager.sendChat(message);
  }

  /// Kick a participant (host only)
  void kickParticipant(String participantId) {
    _manager.kickParticipant(participantId);
  }

  /// End the room (host only)
  void endRoom() {
    _manager.endRoom();
    _state = const VoiceRoomState();
    notifyListeners();
  }

  /// Fetch available voice rooms with optional filters
  Future<List<VoiceRoom>> fetchRooms({String? language, String? topic}) async {
    try {
      final queryParams = <String, String>{};
      if (language != null && language.isNotEmpty) queryParams['language'] = language;
      if (topic != null && topic.isNotEmpty) queryParams['topic'] = topic;
      final query = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
          : '';
      final response = await _apiClient.get('voicerooms$query');

      if (response.success) {
        // response.data may be full body (with pagination) or just the data array
        List data;
        if (response.data is List) {
          data = response.data as List;
        } else if (response.data is Map && response.data['data'] is List) {
          data = response.data['data'] as List;
        } else {
          data = [];
        }
        return data.map((r) => VoiceRoom.fromJson(Map<String, dynamic>.from(r))).toList();
      }
      debugPrint('[VoiceRoom] fetchRooms failed: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('[VoiceRoom] fetchRooms error: $e');
      return [];
    }
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }
}

final voiceRoomProvider = ChangeNotifierProvider<VoiceRoomNotifier>((ref) {
  return VoiceRoomNotifier();
});
