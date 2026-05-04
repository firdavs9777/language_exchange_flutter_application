import 'dart:convert';

import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsNotifier
    extends StateNotifier<AsyncValue<NotificationSettings>> {
  final NotificationApiClient _apiClient = NotificationApiClient();

  NotificationSettingsNotifier() : super(const AsyncValue.loading()) {
    fetchSettings();
  }

  /// Fetch notification settings from backend
  Future<void> fetchSettings() async {
    try {
      state = const AsyncValue.loading();
      
      final settings = await _apiClient.getSettings();

      if (settings != null) {
        state = AsyncValue.data(settings);
        // Cache a quietHours snapshot for the foreground handler.
        await _cacheQuietHoursSnapshot(settings.quietHours);
      } else {
        // Use default settings if fetch fails
        final fallback = NotificationSettings.defaultSettings();
        state = AsyncValue.data(fallback);
        await _cacheQuietHoursSnapshot(fallback.quietHours);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Fallback to default settings
      state = AsyncValue.data(NotificationSettings.defaultSettings());
    }
  }

  /// Update notification settings
  Future<void> updateSettings(NotificationSettings settings) async {
    try {

      // Optimistically update UI
      state = AsyncValue.data(settings);
      // Keep the cached quietHours snapshot in sync so the foreground handler
      // sees the latest window without going through Riverpod.
      await _cacheQuietHoursSnapshot(settings.quietHours);

      final result = await _apiClient.updateSettings(settings);

      if (result['success'] == true) {
      } else {
        // Revert on failure
        await fetchSettings();
      }
    } catch (e) {
      // Revert on error
      await fetchSettings();
    }
  }

  /// Update only the quiet hours window. Persists through the standard
  /// updateSettings path so the API client and snapshot stay consistent.
  Future<void> updateQuietHours(QuietHours qh) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(quietHours: qh));
  }

  /// Persist a snapshot of the quiet-hours window for the foreground handler
  /// to read synchronously without depending on Riverpod.
  Future<void> _cacheQuietHoursSnapshot(QuietHours qh) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('qh_snapshot', jsonEncode(qh.toJson()));
    } catch (_) {
      // Best-effort cache; failures are non-fatal.
    }
  }

  /// Toggle a specific setting
  Future<void> toggleSetting(String settingName, bool value) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    NotificationSettings updatedSettings;

    switch (settingName) {
      case 'enabled':
        updatedSettings = currentSettings.copyWith(enabled: value);
        break;
      case 'chatMessages':
        updatedSettings = currentSettings.copyWith(chatMessages: value);
        break;
      case 'moments':
        updatedSettings = currentSettings.copyWith(moments: value);
        break;
      case 'followerMoments':
        updatedSettings = currentSettings.copyWith(followerMoments: value);
        break;
      case 'friendRequests':
        updatedSettings = currentSettings.copyWith(friendRequests: value);
        break;
      case 'profileVisits':
        updatedSettings = currentSettings.copyWith(profileVisits: value);
        break;
      case 'marketing':
        updatedSettings = currentSettings.copyWith(marketing: value);
        break;
      case 'sound':
        updatedSettings = currentSettings.copyWith(sound: value);
        break;
      case 'vibration':
        updatedSettings = currentSettings.copyWith(vibration: value);
        break;
      case 'showPreview':
        updatedSettings = currentSettings.copyWith(showPreview: value);
        break;
      default:
        return;
    }

    await updateSettings(updatedSettings);
  }

  /// Mute a conversation
  Future<void> muteConversation(String conversationId) async {
    try {
      
      final result = await _apiClient.muteConversation(conversationId);

      if (result['success'] == true) {
        // Refresh settings to get updated muted conversations list
        await fetchSettings();
      } else {
      }
    } catch (e) {
    }
  }

  /// Unmute a conversation
  Future<void> unmuteConversation(String conversationId) async {
    try {
      
      final result = await _apiClient.unmuteConversation(conversationId);

      if (result['success'] == true) {
        // Refresh settings to get updated muted conversations list
        await fetchSettings();
      } else {
      }
    } catch (e) {
    }
  }

  /// Check if a conversation is muted
  bool isConversationMuted(String conversationId) {
    final settings = state.value;
    if (settings == null) return false;
    return settings.mutedConversations.contains(conversationId);
  }
}

/// Provider for notification settings
final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier,
    AsyncValue<NotificationSettings>>((ref) {
  return NotificationSettingsNotifier();
});

