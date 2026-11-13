import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/models/blocked_user.dart';
import 'package:bananatalk_app/services/blocked_ids_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for list of blocked users
final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  
  if (userId == null) {
    return [];
  }
  
  final fetched = await BlockService.fetchBlockedUsers(userId: userId);
  if (fetched == null) return [];
  // Remembered for when the list cannot be fetched (blockedUserIdsProvider).
  await BlockedIdsStore().write(
    userId: userId,
    ids: fetched.map((u) => u.userId).where((id) => id.isNotEmpty).toSet(),
  );
  return fetched;
});

/// Provider for set of blocked user IDs (for quick lookup).
///
/// The fetched list, plus the last list fetched for this user: after a
/// successful fetch the two are the same; when the fetch failed (offline
/// cold start) the remembered list stands in, so cached lists filtered
/// through this never show someone blocked earlier.
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final blockedUsers = await ref.watch(blockedUsersProvider.future);
  final prefs = await SharedPreferences.getInstance();
  final remembered =
      await BlockedIdsStore().read(userId: prefs.getString('userId') ?? '');
  return {...blockedUsers.map((user) => user.userId), ...remembered};
});

