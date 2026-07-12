import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// REST client for Workstream D — Language Rooms (`/api/v1/rooms`).
///
/// Thin wrapper over [ApiClient] (auth headers, token refresh, rate-limit
/// handling already live there) — mirrors the pattern used by
/// `VoiceRoomNotifier` in `lib/providers/voice_room_provider.dart`.
class RoomApiClient {
  final ApiClient _apiClient = ApiClient();

  /// GET /rooms — hub directory. Caller's auto-joined hub is returned
  /// first by the backend.
  Future<List<Room>> getRooms() async {
    try {
      final response = await _apiClient.get('rooms');
      if (!response.success) {
        debugPrint('[RoomApiClient] getRooms failed: ${response.error}');
        return [];
      }
      final data = _extractList(response.data);
      return data
          .map((r) => Room.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      debugPrint('[RoomApiClient] getRooms error: $e');
      return [];
    }
  }

  /// GET /rooms/:id — hub detail.
  Future<Room?> getRoom(String id) async {
    try {
      final response = await _apiClient.get('rooms/$id');
      if (!response.success) return null;
      final data = response.data is Map && response.data['data'] is Map
          ? response.data['data']
          : response.data;
      if (data is! Map) return null;
      return Room.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('[RoomApiClient] getRoom error: $e');
      return null;
    }
  }

  /// GET /rooms/:id/messages?page=N — paginated message history (same
  /// message shape as existing 1-on-1 chat messages).
  ///
  /// Returns the raw decoded list of message maps; parsing into the shared
  /// `Message` model happens in the room screen (Task 10), which already
  /// knows that shape.
  Future<List<Map<String, dynamic>>> getMessages(
    String id, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        'rooms/$id/messages',
        queryParams: {'page': page.toString()},
      );
      if (!response.success) {
        debugPrint('[RoomApiClient] getMessages failed: ${response.error}');
        return [];
      }
      final data = _extractList(response.data);
      return data.map((m) => Map<String, dynamic>.from(m as Map)).toList();
    } catch (e) {
      debugPrint('[RoomApiClient] getMessages error: $e');
      return [];
    }
  }

  /// POST /rooms/:id/join
  Future<bool> join(String id) async {
    try {
      final response = await _apiClient.post('rooms/$id/join');
      return response.success;
    } catch (e) {
      debugPrint('[RoomApiClient] join error: $e');
      return false;
    }
  }

  /// POST /rooms/:id/leave
  Future<bool> leave(String id) async {
    try {
      final response = await _apiClient.post('rooms/$id/leave');
      return response.success;
    } catch (e) {
      debugPrint('[RoomApiClient] leave error: $e');
      return false;
    }
  }

  // ---- Admin (Task 10/11) — stubbed now, wired up to real UI later. ----

  /// DELETE /rooms/:id/members/:userId — owner/admin removes a member.
  Future<bool> removeMember(String roomId, String userId) async {
    try {
      final response = await _apiClient.delete('rooms/$roomId/members/$userId');
      return response.success;
    } catch (e) {
      debugPrint('[RoomApiClient] removeMember error: $e');
      return false;
    }
  }

  /// POST /rooms/:id/members/:userId/mute — owner/admin mutes a member.
  /// TODO(Task 11): confirm exact mute route/payload with backend once its
  /// admin endpoints land; wire this into the member-list moderation UI.
  Future<bool> muteMember(
    String roomId,
    String userId, {
    bool muted = true,
  }) async {
    try {
      final response = await _apiClient.post(
        'rooms/$roomId/members/$userId/mute',
        body: {'muted': muted},
      );
      return response.success;
    } catch (e) {
      debugPrint('[RoomApiClient] muteMember error: $e');
      return false;
    }
  }

  /// PUT /rooms/:id — owner/admin updates hub metadata (title/description).
  /// TODO(Task 10/11): wire into a real settings UI when it's built.
  Future<bool> updateRoom(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.put('rooms/$id', body: updates);
      return response.success;
    } catch (e) {
      debugPrint('[RoomApiClient] updateRoom error: $e');
      return false;
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }
    return const [];
  }
}
