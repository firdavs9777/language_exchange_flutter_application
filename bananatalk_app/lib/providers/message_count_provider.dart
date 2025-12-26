import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that tracks message counts per conversation
/// Used to determine if users can initiate calls (requires 3+ messages)
class MessageCountNotifier extends StateNotifier<Map<String, int>> {
  MessageCountNotifier(this._ref) : super({});

  final Ref _ref;

  /// Get message count for a conversation between current user and another user
  /// Returns cached count or fetches from API if not cached
  Future<int> getMessageCount(String otherUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      if (currentUserId == null || currentUserId.isEmpty) {
        return 0;
      }

      // Create cache key
      final cacheKey = _getCacheKey(currentUserId, otherUserId);

      // Return cached count if available
      if (state.containsKey(cacheKey)) {
        return state[cacheKey] ?? 0;
      }

      // Fetch from API
      final messageService = _ref.read(messageServiceProvider);
      final messages = await messageService.getConversation(
        senderId: currentUserId,
        receiverId: otherUserId,
      );

      final count = messages.length;
      
      // Update cache
      state = {...state, cacheKey: count};

      return count;
    } catch (e) {
      print('❌ Error getting message count: $e');
      return 0;
    }
  }

  /// Update message count for a conversation (increment by 1)
  void incrementMessageCount(String otherUserId) {
    _updateMessageCount(otherUserId, (current) => (current ?? 0) + 1);
  }

  /// Set message count for a conversation
  void setMessageCount(String otherUserId, int count) {
    _updateMessageCount(otherUserId, (_) => count);
  }

  /// Refresh message count from API
  Future<void> refreshMessageCount(String otherUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      if (currentUserId == null || currentUserId.isEmpty) {
        return;
      }

      final messageService = _ref.read(messageServiceProvider);
      final messages = await messageService.getConversation(
        senderId: currentUserId,
        receiverId: otherUserId,
      );

      final count = messages.length;
      setMessageCount(otherUserId, count);
    } catch (e) {
      print('❌ Error refreshing message count: $e');
    }
  }

  /// Check if user can call another user (requires 3+ messages)
  Future<bool> canCall(String otherUserId) async {
    final count = await getMessageCount(otherUserId);
    return count >= 3;
  }

  /// Get cache key for a conversation
  String _getCacheKey(String userId1, String userId2) {
    // Sort user IDs to ensure consistent key regardless of order
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Update message count with a function
  Future<void> _updateMessageCount(
    String otherUserId,
    int Function(int?) updateFn,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      if (currentUserId == null || currentUserId.isEmpty) {
        return;
      }

      final cacheKey = _getCacheKey(currentUserId, otherUserId);
      final currentCount = state[cacheKey] ?? 0;
      final newCount = updateFn(currentCount);

      state = {...state, cacheKey: newCount};
    } catch (e) {
      print('❌ Error updating message count: $e');
    }
  }

  /// Clear all cached message counts
  void clear() {
    state = {};
  }
}

final messageCountProvider =
    StateNotifierProvider<MessageCountNotifier, Map<String, int>>((ref) {
  return MessageCountNotifier(ref);
});

/// Helper provider to check if calling is enabled for a specific user
final canCallProvider = Provider.family<Future<bool>, String>((ref, otherUserId) async {
  final notifier = ref.read(messageCountProvider.notifier);
  return await notifier.canCall(otherUserId);
});

