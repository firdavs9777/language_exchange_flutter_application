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
  Future<void> fetchBadgeCount() async {
    try {
      debugPrint('📥 Fetching badge count...');
      
      final badgeCount = await _apiClient.getBadgeCount();

      if (badgeCount != null) {
        state = badgeCount;
        debugPrint('✅ Badge count: ${badgeCount.total} (messages: ${badgeCount.messages}, notifications: ${badgeCount.notifications})');
        
        // Update iOS badge
        await _notificationService.updateBadgeCount(badgeCount.total);
      } else {
        debugPrint('⚠️ Failed to fetch badge count');
      }
    } catch (e) {
      debugPrint('❌ Error fetching badge count: $e');
    }
  }

  /// Reset specific badge type
  Future<void> resetBadge(String type) async {
    try {
      debugPrint('🔄 Resetting $type badge...');
      
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
        debugPrint('✅ Badge reset successfully');
      } else {
        debugPrint('❌ Failed to reset badge on backend');
        // Refresh from backend
        await fetchBadgeCount();
      }
    } catch (e) {
      debugPrint('❌ Error resetting badge: $e');
      await fetchBadgeCount();
    }
  }

  /// Increment messages badge (local update)
  void incrementMessages() {
    state = state.copyWith(messages: state.messages + 1);
    _notificationService.updateBadgeCount(state.total);
    debugPrint('📬 Messages badge incremented: ${state.messages}');
  }

  /// Increment notifications badge (local update)
  void incrementNotifications() {
    state = state.copyWith(notifications: state.notifications + 1);
    _notificationService.updateBadgeCount(state.total);
    debugPrint('🔔 Notifications badge incremented: ${state.notifications}');
  }

  /// Decrement messages badge (local update)
  void decrementMessages() {
    if (state.messages > 0) {
      state = state.copyWith(messages: state.messages - 1);
      _notificationService.updateBadgeCount(state.total);
      debugPrint('📬 Messages badge decremented: ${state.messages}');
    }
  }

  /// Decrement notifications badge (local update)
  void decrementNotifications() {
    if (state.notifications > 0) {
      state = state.copyWith(notifications: state.notifications - 1);
      _notificationService.updateBadgeCount(state.total);
      debugPrint('🔔 Notifications badge decremented: ${state.notifications}');
    }
  }

  /// Update message badge count directly (for real-time updates)
  void updateMessageCount(int count) {
    print('🔔 Updating message badge count to: $count');
    state = state.copyWith(messages: count);
    _notificationService.updateBadgeCount(state.total);
  }

  /// Reset all badge counts (for logout)
  void reset() {
    print('🔔 Resetting all badge counts');
    state = BadgeCount.zero();
    _notificationService.updateBadgeCount(0);
  }

  /// Reset all badges
  Future<void> resetAllBadges() async {
    try {
      debugPrint('🔄 Resetting all badges...');
      
      state = BadgeCount.zero();
      await _notificationService.updateBadgeCount(0);

      // Reset both on backend
      await _apiClient.resetBadge('messages');
      await _apiClient.resetBadge('notifications');

      debugPrint('✅ All badges reset');
    } catch (e) {
      debugPrint('❌ Error resetting all badges: $e');
    }
  }
}

/// Provider for badge counts
final badgeCountProvider =
    StateNotifierProvider<BadgeCountNotifier, BadgeCount>((ref) {
  return BadgeCountNotifier();
});

