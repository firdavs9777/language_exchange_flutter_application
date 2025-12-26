import 'package:app_settings/app_settings.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationSettings),
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // Global toggle
            SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.enableNotifications,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(AppLocalizations.of(context)!.turnAllNotificationsOnOrOff),
              value: settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: (value) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('enabled', value);
              },
            ),
            const Divider(),

            // Notification Types
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.notificationTypes,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.chatMessages),
              subtitle: Text(AppLocalizations.of(context)!.getNotifiedWhenYouReceiveMessages),
              value: settings.chatMessages && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('chatMessages', value);
                    }
                  : null,
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.moments),
              subtitle: Text(AppLocalizations.of(context)!.likesAndCommentsOnYourMoments),
              value: settings.moments && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('moments', value);
                    }
                  : null,
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.moments),
              subtitle: Text(AppLocalizations.of(context)!.whenPeopleYouFollowPostMoments),
              value: settings.followerMoments && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('followerMoments', value);
                    }
                  : null,
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.friendRequests),
              subtitle: Text(AppLocalizations.of(context)!.whenSomeoneFollowsYou),
              value: settings.friendRequests && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('friendRequests', value);
                    }
                  : null,
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.profileVisits),
              subtitle: Text(AppLocalizations.of(context)!.whenSomeoneViewsYourProfileVIP),
              value: settings.profileVisits && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('profileVisits', value);
                    }
                  : null,
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.marketing),
              subtitle: Text(AppLocalizations.of(context)!.updatesAndPromotionalMessages),
              value: settings.marketing && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('marketing', value);
                    }
                  : null,
            ),

            const Divider(),

            // Notification Preferences
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.notificationPreferences,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.sound),
              subtitle: Text(AppLocalizations.of(context)!.playNotificationSounds),
              value: settings.sound && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('sound', value);
                    }
                  : null,
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.vibration),
              subtitle: Text(AppLocalizations.of(context)!.vibrateOnNotifications),
              value: settings.vibration && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('vibration', value);
                    }
                  : null,
            ),

            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.showPreview),
              subtitle: Text(AppLocalizations.of(context)!.showMessagePreviewInNotifications),
              value: settings.showPreview && settings.enabled,
              activeColor: const Color(0xFF00BFA5),
              onChanged: settings.enabled
                  ? (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('showPreview', value);
                    }
                  : null,
            ),

            const Divider(),

            // Muted Conversations
            if (settings.mutedConversations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.mutedConversations,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ...settings.mutedConversations.map((conversationId) {
                return ListTile(
                  leading: const Icon(Icons.volume_off),
                  title: Text('${AppLocalizations.of(context)!.conversation} $conversationId'),
                  trailing: TextButton(
                    onPressed: () {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .unmuteConversation(conversationId);
                    },
                    child: Text(AppLocalizations.of(context)!.unmute),
                  ),
                );
              }).toList(),
              const Divider(),
            ],

            // System Settings
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.systemNotificationSettings),
              subtitle: Text(AppLocalizations.of(context)!.manageNotificationsInSystemSettings),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                AppSettings.openAppSettings(
                  type: AppSettingsType.notification,
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${AppLocalizations.of(context)!.errorLoadingSettings}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .fetchSettings();
                },
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

