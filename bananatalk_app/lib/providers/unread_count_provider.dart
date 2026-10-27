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

  /// Partner id → conversation id, from the chat list. Mute is stored per
  /// conversation, but most socket events (photo, voice, reply, forward,
  /// story reply) carry no conversationId.
  final Map<String, String> _conversationIds = {};

  void rememberConversation(String partnerId, String? conversationId) {
    if (conversationId != null && conversationId.isNotEmpty) {
      _conversationIds[partnerId] = conversationId;
    }
  }

  String? conversationIdFor(String partnerId) => _conversationIds[partnerId];

  /// When each chat was last read on this device.
  final Map<String, DateTime> _readHereAt = {};

  /// How long a local read beats the server's count: the list can be
  /// fetched before the server has processed the read.
  static const readSyncGrace = Duration(seconds: 15);

  void clearUnread(String userId) {
    _readHereAt[userId] = DateTime.now();
    updateUnreadCount(userId, 0);
  }

  /// Takes the server's unread count per chat and returns the count to show.
  /// The server wins (reads on web or another device, messages that arrived
  /// while the socket was down) except for the chat on screen (always 0)
  /// and a chat read here moments ago (the read may not have landed yet).
  /// Before, any local count — including the 0s kept on purpose — always
  /// won, so counts drifted until the app restarted.
  Map<String, int> applyServerCounts(
    Map<String, int> serverCounts, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final counts = Map<String, int>.from(state.unreadCounts);
    final shown = <String, int>{};
    serverCounts.forEach((userId, serverCount) {
      final readAt = _readHereAt[userId];
      final int count;
      if (state.isInChat(userId)) {
        count = 0;
      } else if (readAt != null && at.difference(readAt) < readSyncGrace) {
        count = counts[userId] ?? 0;
      } else {
        count = serverCount < 0 ? 0 : serverCount;
      }
      counts[userId] = count;
      shown[userId] = count;
    });
    state = state.copyWith(unreadCounts: counts);
    _ref
        .read(badgeCountProvider.notifier)
        .setMessagesFromChatList(state.totalUnread);
    return shown;
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
    _readHereAt.clear();
    _conversationIds.clear();
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

