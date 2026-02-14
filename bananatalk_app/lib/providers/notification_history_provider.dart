import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationHistoryState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  NotificationHistoryState({
    required this.notifications,
    required this.isLoading,
    required this.hasMore,
    required this.currentPage,
    this.error,
  });

  NotificationHistoryState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return NotificationHistoryState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class NotificationHistoryNotifier extends StateNotifier<NotificationHistoryState> {
  final NotificationApiClient _apiClient = NotificationApiClient();
  final Ref _ref;
  static const int _pageSize = 20;

  NotificationHistoryNotifier(this._ref)
      : super(NotificationHistoryState(
          notifications: [],
          isLoading: false,
          hasMore: true,
          currentPage: 0,
        )) {
    fetchHistory();
  }

  /// Fetch notification history (first page)
  Future<void> fetchHistory({bool refresh = false}) async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      debugPrint('📥 Fetching notification history (page 1)...');
      
      final notifications = await _apiClient.getHistory(
        page: 1,
        limit: _pageSize,
      );

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        hasMore: notifications.length >= _pageSize,
        currentPage: 1,
      );

      // Sync the badge count with actual unread notifications (excluding chat messages)
      final unreadCount = notifications.where((n) => !n.read).length;
      _ref.read(badgeCountProvider.notifier).setNotificationCount(unreadCount);

      debugPrint('✅ Loaded ${notifications.length} notifications ($unreadCount unread)');
    } catch (e) {
      debugPrint('❌ Error fetching notification history: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    try {
      state = state.copyWith(isLoading: true);

      final nextPage = state.currentPage + 1;
      debugPrint('📥 Loading more notifications (page $nextPage)...');

      final newNotifications = await _apiClient.getHistory(
        page: nextPage,
        limit: _pageSize,
      );

      state = state.copyWith(
        notifications: [...state.notifications, ...newNotifications],
        isLoading: false,
        hasMore: newNotifications.length >= _pageSize,
        currentPage: nextPage,
      );

      debugPrint('✅ Loaded ${newNotifications.length} more notifications');
    } catch (e) {
      debugPrint('❌ Error loading more notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      debugPrint('✅ Marking notification as read: $notificationId');

      // Check if notification was already read
      final notification = state.notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );
      final wasUnread = !notification.read;

      // Optimistically update UI
      final updatedNotifications = state.notifications.map((notif) {
        if (notif.id == notificationId) {
          return notif.copyWith(read: true);
        }
        return notif;
      }).toList();

      state = state.copyWith(notifications: updatedNotifications);

      // Decrement badge count if it was unread
      if (wasUnread) {
        _ref.read(badgeCountProvider.notifier).decrementNotifications();
      }

      // Update on backend
      final result = await _apiClient.markAsRead(notificationId);

      if (result['success'] != true) {
        debugPrint('❌ Failed to mark as read on backend');
        // Revert on failure
        await fetchHistory();
        // Refresh badge count from backend
        _ref.read(badgeCountProvider.notifier).fetchBadgeCount();
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      await fetchHistory();
      _ref.read(badgeCountProvider.notifier).fetchBadgeCount();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      debugPrint('✅ Marking all notifications as read...');

      // Optimistically update UI
      final updatedNotifications = state.notifications.map((notif) {
        return notif.copyWith(read: true);
      }).toList();

      state = state.copyWith(notifications: updatedNotifications);

      // Reset notifications badge to 0
      _ref.read(badgeCountProvider.notifier).resetBadge('notifications');

      // Update on backend
      final result = await _apiClient.markAllAsRead();

      if (result['success'] == true) {
        debugPrint('✅ All notifications marked as read');
      } else {
        debugPrint('❌ Failed to mark all as read on backend');
        // Revert on failure
        await fetchHistory();
        _ref.read(badgeCountProvider.notifier).fetchBadgeCount();
      }
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      await fetchHistory();
      _ref.read(badgeCountProvider.notifier).fetchBadgeCount();
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      debugPrint('🗑️ Clearing all notifications...');

      final result = await _apiClient.clearAll();

      if (result['success'] == true) {
        state = state.copyWith(
          notifications: [],
          hasMore: false,
          currentPage: 0,
        );
        // Reset notifications badge since all cleared
        _ref.read(badgeCountProvider.notifier).resetBadge('notifications');
        debugPrint('✅ All notifications cleared');
      } else {
        debugPrint('❌ Failed to clear notifications');
      }
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  /// Get unread count
  int get unreadCount {
    return state.notifications.where((notif) => !notif.read).length;
  }

  /// Remove a notification from the list (local only)
  void removeNotification(String notificationId) {
    final updatedNotifications = state.notifications
        .where((notif) => notif.id != notificationId)
        .toList();

    state = state.copyWith(notifications: updatedNotifications);
  }
}

/// Provider for notification history
final notificationHistoryProvider =
    StateNotifierProvider<NotificationHistoryNotifier, NotificationHistoryState>(
  (ref) {
    return NotificationHistoryNotifier(ref);
  },
);

