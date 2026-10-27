import 'dart:async';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every change also sets the iOS app icon badge to the unread-MESSAGE count,
/// the same number the server sends as `aps.badge`, so the icon does not
/// flip between "messages" (after a push) and "messages + notifications".
class BadgeCountNotifier extends StateNotifier<BadgeCount> {
  final NotificationApiClient _apiClient = NotificationApiClient();
  final NotificationService _notificationService = NotificationService();

  // Debounce timer for fetch requests
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Track last fetch time to prevent rapid API calls
  DateTime? _lastFetchTime;
  static const Duration _minFetchInterval = Duration(seconds: 3);

  // Flag to prevent concurrent fetches
  bool _isFetching = false;

  BadgeCountNotifier() : super(BadgeCount.zero()) {
    fetchBadgeCount();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Fetch badge count from backend with debouncing
  /// Uses sync endpoint to recalculate accurate counts
  Future<void> fetchBadgeCount({bool force = false}) async {
    // Cancel any pending debounced fetch
    _debounceTimer?.cancel();

    // Check if we should skip this fetch (too soon after last fetch)
    if (!force && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
        // Debounce: schedule fetch after remaining time
        _debounceTimer = Timer(
          _minFetchInterval - timeSinceLastFetch,
          () => _executeFetch(),
        );
        return;
      }
    }

    // Debounce rapid calls
    _debounceTimer = Timer(_debounceDuration, () => _executeFetch());
  }

  /// Actually execute the fetch
  Future<void> _executeFetch() async {
    // Prevent concurrent fetches
    if (_isFetching) return;
    _isFetching = true;

    try {
      // Use sync endpoint to get accurate counts from actual data
      final badgeCount = await _apiClient.syncBadges();

      final fetched = badgeCount ?? await _apiClient.getBadgeCount();
      if (fetched != null) {
        state = withChatListMessages(fetched);
        await _notificationService.updateBadgeCount(state.messages);
      }

      _lastFetchTime = DateTime.now();
    } catch (e) {
      // Silent fail - badge will update on next successful fetch
    } finally {
      _isFetching = false;
    }
  }

  /// Force immediate fetch (bypasses debounce)
  Future<void> forceFetch() async {
    _debounceTimer?.cancel();
    _isFetching = false; // Reset flag to allow fetch
    await _executeFetch();
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
      await _notificationService.updateBadgeCount(state.messages);

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
    _notificationService.updateBadgeCount(state.messages);
  }

  /// Increment notifications badge (local update)
  void incrementNotifications() {
    state = state.copyWith(notifications: state.notifications + 1);
    _notificationService.updateBadgeCount(state.messages);
  }

  /// Decrement messages badge (local update)
  void decrementMessages() {
    if (state.messages > 0) {
      state = state.copyWith(messages: state.messages - 1);
      _notificationService.updateBadgeCount(state.messages);
    }
  }

  /// Decrement notifications badge (local update)
  void decrementNotifications() {
    if (state.notifications > 0) {
      state = state.copyWith(notifications: state.notifications - 1);
      _notificationService.updateBadgeCount(state.messages);
    }
  }

  /// Set notification count directly (for syncing with actual unread count)
  void setNotificationCount(int count) {
    state = state.copyWith(notifications: count);
    _notificationService.updateBadgeCount(state.messages);
  }

  /// Unread messages summed over the chat list, once it has loaded from
  /// the server. The server's total (`sync-badges`) also counts chats with
  /// deleted or hidden partners — unread the user can never clear — so the
  /// tab badge flipped between the two numbers (live: 20 vs 8).
  int? _chatListMessages;

  /// [fetched] from the server, with the chat list's message total when known.
  @visibleForTesting
  BadgeCount withChatListMessages(BadgeCount fetched) {
    final local = _chatListMessages;
    return local == null ? fetched : fetched.copyWith(messages: local);
  }

  /// The chat list's server-backed total (see [_chatListMessages]).
  void setMessagesFromChatList(int count) {
    _chatListMessages = count;
    updateMessageCount(count);
  }

  /// Update message badge count directly (for real-time updates)
  void updateMessageCount(int count) {
    if (_chatListMessages != null) _chatListMessages = count;
    state = state.copyWith(messages: count);
    _notificationService.updateBadgeCount(state.messages);
  }

  /// Reset all badge counts (for logout)
  void reset() {
    _chatListMessages = null;
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

