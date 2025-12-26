import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/models/blocked_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for list of blocked users
final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  
  if (userId == null) {
    return [];
  }
  
  return await BlockService.getBlockedUsers(userId: userId);
});

/// Provider for set of blocked user IDs (for quick lookup)
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final blockedUsers = await ref.watch(blockedUsersProvider.future);
  return blockedUsers.map((user) => user.userId).toSet();
});

