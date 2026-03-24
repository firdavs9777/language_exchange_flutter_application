import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      } else {
        // Use default settings if fetch fails
        state = AsyncValue.data(NotificationSettings.defaultSettings());
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

