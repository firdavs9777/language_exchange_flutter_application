import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BadgeCountNotifier extends StateNotifier<BadgeCount> {
  final NotificationApiClient _apiClient = NotificationApiClient();
  final NotificationService _notificationService = NotificationService();

  BadgeCountNotifier() : super(BadgeCount.zero()) {
    fetchBadgeCount();
  }

  /// Fetch badge count from backend
  /// Uses sync endpoint to recalculate accurate counts
  Future<void> fetchBadgeCount() async {
    try {

      // Use sync endpoint to get accurate counts from actual data
      final badgeCount = await _apiClient.syncBadges();

      if (badgeCount != null) {
        state = badgeCount;

        // Update iOS badge
        await _notificationService.updateBadgeCount(badgeCount.total);
      } else {
        // Fallback to regular getBadgeCount if sync fails
        final fallbackCount = await _apiClient.getBadgeCount();
        if (fallbackCount != null) {
          state = fallbackCount;
          await _notificationService.updateBadgeCount(fallbackCount.total);
        }
      }
    } catch (e) {
    }
  }

  /// Reset specific badge type
  Future<void> resetBadge(String type) async {
    try {
      
      // Optimistically update UI
      if (type == 'messages') {
        state = state.copyWith(messages: 0);
      } else if (type == 'notifications') {
        state = state.copyWith(notifications: 0);
      }

      // Update iOS badge
      await _notificationService.updateBadgeCount(state.total);

      // Update on backend
      final result = await _apiClient.resetBadge(type);

      if (result['success'] == true) {
      } else {
        // Refresh from backend
        await fetchBadgeCount();
      }
    } catch (e) {
      await fetchBadgeCount();
    }
  }

  /// Increment messages badge (local update)
  void incrementMessages() {
    state = state.copyWith(messages: state.messages + 1);
    _notificationService.updateBadgeCount(state.total);
  }

  /// Increment notifications badge (local update)
  void incrementNotifications() {
    state = state.copyWith(notifications: state.notifications + 1);
    _notificationService.updateBadgeCount(state.total);
  }

  /// Decrement messages badge (local update)
  void decrementMessages() {
    if (state.messages > 0) {
      state = state.copyWith(messages: state.messages - 1);
      _notificationService.updateBadgeCount(state.total);
    }
  }

  /// Decrement notifications badge (local update)
  void decrementNotifications() {
    if (state.notifications > 0) {
      state = state.copyWith(notifications: state.notifications - 1);
      _notificationService.updateBadgeCount(state.total);
    }
  }

  /// Set notification count directly (for syncing with actual unread count)
  void setNotificationCount(int count) {
    state = state.copyWith(notifications: count);
    _notificationService.updateBadgeCount(state.total);
  }

  /// Update message badge count directly (for real-time updates)
  void updateMessageCount(int count) {
    state = state.copyWith(messages: count);
    _notificationService.updateBadgeCount(state.total);
  }

  /// Reset all badge counts (for logout)
  void reset() {
    state = BadgeCount.zero();
    _notificationService.updateBadgeCount(0);
  }

  /// Reset all badges
  Future<void> resetAllBadges() async {
    try {
      
      state = BadgeCount.zero();
      await _notificationService.updateBadgeCount(0);

      // Reset both on backend
      await _apiClient.resetBadge('messages');
      await _apiClient.resetBadge('notifications');

    } catch (e) {
    }
  }
}

/// Provider for badge counts
final badgeCountProvider =
    StateNotifierProvider<BadgeCountNotifier, BadgeCount>((ref) {
  return BadgeCountNotifier();
});

