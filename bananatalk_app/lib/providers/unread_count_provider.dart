import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global state for chat partners and their unread counts
class ChatPartnersState {
  final Map<String, int> unreadCounts; // userId -> unread count

  ChatPartnersState({
    Map<String, int>? unreadCounts,
  }) : unreadCounts = unreadCounts ?? {};

  ChatPartnersState copyWith({
    Map<String, int>? unreadCounts,
  }) {
    return ChatPartnersState(
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  int get totalUnread =>
      unreadCounts.values.fold(0, (sum, count) => sum + count);
}

class ChatPartnersNotifier extends StateNotifier<ChatPartnersState> {
  ChatPartnersNotifier(this._ref) : super(ChatPartnersState());
  
  final Ref _ref;

  void updateUnreadCount(String userId, int count) {
    final newCounts = Map<String, int>.from(state.unreadCounts);
    if (count > 0) {
      newCounts[userId] = count;
    } else {
      newCounts.remove(userId);
    }
    state = state.copyWith(unreadCounts: newCounts);
    
    // Always sync badge count when counts change (even if not visible)
    final totalUnread = state.totalUnread;
    _ref.read(badgeCountProvider.notifier).updateMessageCount(totalUnread);
    
    print('📊 Updated unread count for $userId: $count (Total: $totalUnread)');
  }

  void incrementUnread(String userId) {
    final currentCount = state.unreadCounts[userId] ?? 0;
    updateUnreadCount(userId, currentCount + 1);
  }

  void clearUnread(String userId) {
    updateUnreadCount(userId, 0);
  }

  void reset() {
    state = ChatPartnersState();
    _ref.read(badgeCountProvider.notifier).updateMessageCount(0);
    print('📊 Chat partners state reset');
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

