import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global state for chat partners and their unread counts
class ChatPartnersState {
  final Map<String, int> unreadCounts; // userId -> unread count

  /// Open conversation screens, bottom to top. Chats can stack (opening
  /// chat B from the in-app banner while in chat A); closing B must leave A
  /// active, not "no chat".
  final List<String> openChats;

  ChatPartnersState({
    Map<String, int>? unreadCounts,
    this.openChats = const [],
  }) : unreadCounts = unreadCounts ?? {};

  /// The chat on screen (top of the stack), null when not in any chat.
  String? get activeChatUserId => openChats.isEmpty ? null : openChats.last;

  ChatPartnersState copyWith({
    Map<String, int>? unreadCounts,
    List<String>? openChats,
  }) {
    return ChatPartnersState(
      unreadCounts: unreadCounts ?? this.unreadCounts,
      openChats: openChats ?? this.openChats,
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
    
  }

  void incrementUnread(String userId) {
    // Don't increment if user is currently viewing this chat (KakaoTalk-style instant read)
    if (state.isInChat(userId)) {
      return;
    }
    final currentCount = state.unreadCounts[userId] ?? 0;
    updateUnreadCount(userId, currentCount + 1);
  }

  void clearUnread(String userId) {
    updateUnreadCount(userId, 0);
  }

  /// A chat screen for [userId] opened (it is now on top).
  void setActiveChat(String userId) {
    state = state.copyWith(openChats: [...state.openChats, userId]);
  }

  /// The chat screen for [userId] closed; the one under it (if any) is
  /// active again.
  void clearActiveChat(String userId) {
    final open = List<String>.of(state.openChats);
    final index = open.lastIndexOf(userId);
    if (index < 0) return;
    open.removeAt(index);
    state = state.copyWith(openChats: open);
  }

  void reset() {
    state = ChatPartnersState();
    _ref.read(badgeCountProvider.notifier).updateMessageCount(0);
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

