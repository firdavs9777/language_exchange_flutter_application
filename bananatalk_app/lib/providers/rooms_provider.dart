import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/services/room_api_client.dart';

final roomApiClientProvider = Provider<RoomApiClient>((ref) => RoomApiClient());

/// Directory state for Workstream D — Language Rooms.
///
/// The backend already returns the caller's auto-joined hub first from
/// `GET /rooms`; this notifier defensively re-pins client-side too (cheap,
/// and guards against ordering drift if that contract changes later).
class RoomsNotifier extends StateNotifier<AsyncValue<List<Room>>> {
  RoomsNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    refresh();
  }

  final RoomApiClient _apiClient;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final rooms = await _apiClient.getRooms();
      state = AsyncValue.data(_pinnedFirst(rooms));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Room> _pinnedFirst(List<Room> rooms) {
    final mine = rooms.where((r) => r.isMember).toList();
    final others = rooms.where((r) => !r.isMember).toList();
    return [...mine, ...others];
  }

  /// Optimistically flips `isMember` for a room after a successful
  /// join/leave call, avoiding a full directory refetch.
  void _setMembership(String roomId, bool isMember, int memberDelta) {
    state.whenData((rooms) {
      final updated = rooms
          .map(
            (r) => r.id == roomId
                ? r.copyWith(
                    isMember: isMember,
                    memberCount: (r.memberCount + memberDelta).clamp(
                      0,
                      1 << 30,
                    ),
                  )
                : r,
          )
          .toList();
      state = AsyncValue.data(_pinnedFirst(updated));
    });
  }

  Future<bool> join(String roomId) async {
    final ok = await _apiClient.join(roomId);
    if (ok) _setMembership(roomId, true, 1);
    return ok;
  }

  Future<bool> leave(String roomId) async {
    final ok = await _apiClient.leave(roomId);
    if (ok) _setMembership(roomId, false, -1);
    return ok;
  }
}

final roomsProvider =
    StateNotifierProvider<RoomsNotifier, AsyncValue<List<Room>>>((ref) {
  return RoomsNotifier(ref.read(roomApiClientProvider));
});
