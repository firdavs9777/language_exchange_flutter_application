import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global state for chat partners and their unread counts
class ChatPartnersState {
  final Map<String, int> unreadCounts; // userId -> unread count
  final String? activeChatUserId; // Currently active chat (null if not in any chat)

  ChatPartnersState({
    Map<String, int>? unreadCounts,
    this.activeChatUserId,
  }) : unreadCounts = unreadCounts ?? {};

  ChatPartnersState copyWith({
    Map<String, int>? unreadCounts,
    String? activeChatUserId,
    bool clearActiveChat = false,
  }) {
    return ChatPartnersState(
      unreadCounts: unreadCounts ?? this.unreadCounts,
      activeChatUserId: clearActiveChat ? null : (activeChatUserId ?? this.activeChatUserId),
    );
  }

  int get totalUnread =>
      unreadCounts.values.fold(0, (sum, count) => sum + count);

  bool isInChat(String userId) => activeChatUserId == userId;
}

class ChatPartnersNotifier extends StateNotifier<ChatPartnersState> {
  ChatPartnersNotifier(this._ref) : super(ChatPartnersState());
  
  final Ref _ref;

  void updateUnreadCount(String userId, int count) {
    final newCounts = Map<String, int>.from(state.unreadCounts);
    // Keep 0 values in map to prevent API sync from overwriting cleared counts
    // This is important because sync checks if entry exists before overwriting
    newCounts[userId] = count >= 0 ? count : 0;
    state = state.copyWith(unreadCounts: newCounts);
    
    // Always sync badge count when counts change (even if not visible)
    final totalUnread = state.totalUnread;
    _ref.read(badgeCountProvider.notifier).updateMessageCount(totalUnread);
    
    debugPrint('📊 Updated unread count for $userId: $count (Total: $totalUnread)');
  }

  void incrementUnread(String userId) {
    // Don't increment if user is currently viewing this chat (KakaoTalk-style instant read)
    if (state.isInChat(userId)) {
      debugPrint('📊 Skipping increment for $userId - user is currently in this chat');
      return;
    }
    final currentCount = state.unreadCounts[userId] ?? 0;
    updateUnreadCount(userId, currentCount + 1);
  }

  void clearUnread(String userId) {
    updateUnreadCount(userId, 0);
  }

  /// Set the active chat when user enters a chat screen
  void setActiveChat(String userId) {
    state = state.copyWith(activeChatUserId: userId);
    debugPrint('📊 Set active chat: $userId');
  }

  /// Clear the active chat when user leaves a chat screen
  void clearActiveChat() {
    state = state.copyWith(clearActiveChat: true);
    debugPrint('📊 Cleared active chat');
  }

  void reset() {
    state = ChatPartnersState();
    _ref.read(badgeCountProvider.notifier).updateMessageCount(0);
    debugPrint('📊 Chat partners state reset');
  }
}

final chatPartnersProvider =
    StateNotifierProvider<ChatPartnersNotifier, ChatPartnersState>((ref) {
  return ChatPartnersNotifier(ref);
});

// Derived provider for total unread count
// Note: We don't automatically update badge count here to avoid infinite loops
// Badge count is updated manually in ChatMain when counts actually change
final totalUnreadProvider = Provider<int>((ref) {
  final chatState = ref.watch(chatPartnersProvider);
  return chatState.totalUnread;
});

