import 'package:app_settings/app_settings.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationSettings, style: context.titleLarge),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // Global toggle
            Container(
              margin: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderMD,
                boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
              ),
              child: SwitchListTile(
                contentPadding: AppSpacing.paddingLG,
                title: Text(
                  AppLocalizations.of(context)!.enableNotifications,
                  style: context.titleMedium,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.turnAllNotificationsOnOrOff,
                  style: context.bodySmall,
                ),
                value: settings.enabled,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleSetting('enabled', value);
                },
              ),
            ),

            // Notification Types
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Text(
                AppLocalizations.of(context)!.notificationTypes,
                style: context.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderMD,
                boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.chatMessages,
                    subtitle: AppLocalizations.of(context)!.getNotifiedWhenYouReceiveMessages,
                    value: settings.chatMessages && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('chatMessages', value);
                    },
                  ),
                  Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.moments,
                    subtitle: AppLocalizations.of(context)!.likesAndCommentsOnYourMoments,
                    value: settings.moments && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('moments', value);
                    },
                  ),
                  Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.followerMoments,
                    subtitle: AppLocalizations.of(context)!.whenPeopleYouFollowPost,
                    value: settings.followerMoments && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('followerMoments', value);
                    },
                  ),
                  Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.friendRequests,
                    subtitle: AppLocalizations.of(context)!.whenSomeoneFollowsYou,
                    value: settings.friendRequests && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('friendRequests', value);
                    },
                  ),
                  Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.profileVisits,
                    subtitle: AppLocalizations.of(context)!.whenSomeoneViewsYourProfileVIP,
                    value: settings.profileVisits && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('profileVisits', value);
                    },
                  ),
                  Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.marketing,
                    subtitle: AppLocalizations.of(context)!.updatesAndPromotionalMessages,
                    value: settings.marketing && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('marketing', value);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Quiet Hours
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Text(
                AppLocalizations.of(context)!.quietHours,
                style: context.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderMD,
                boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: AppSpacing.paddingLG,
                    title: Text(
                      AppLocalizations.of(context)!.quietHoursEnable,
                      style: context.titleMedium,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.quietHoursSubtitle,
                      style: context.bodySmall,
                    ),
                    value: settings.quietHours.enabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) => ref
                        .read(notificationSettingsProvider.notifier)
                        .updateQuietHours(
                          settings.quietHours.copyWith(enabled: v),
                        ),
                  ),
                  if (settings.quietHours.enabled) ...[
                    Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                    ListTile(
                      contentPadding: AppSpacing.paddingLG,
                      title: Text(
                        AppLocalizations.of(context)!.quietHoursStart,
                        style: context.titleSmall,
                      ),
                      trailing: Text(
                        settings.quietHours.start,
                        style: context.bodyMedium,
                      ),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _parseHHmm(settings.quietHours.start),
                        );
                        if (t != null) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .updateQuietHours(
                                settings.quietHours.copyWith(start: _formatHHmm(t)),
                              );
                        }
                      },
                    ),
                    Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                    ListTile(
                      contentPadding: AppSpacing.paddingLG,
                      title: Text(
                        AppLocalizations.of(context)!.quietHoursEnd,
                        style: context.titleSmall,
                      ),
                      trailing: Text(
                        settings.quietHours.end,
                        style: context.bodyMedium,
                      ),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _parseHHmm(settings.quietHours.end),
                        );
                        if (t != null) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .updateQuietHours(
                                settings.quietHours.copyWith(end: _formatHHmm(t)),
                              );
                        }
                      },
                    ),
                    Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                    SwitchListTile(
                      contentPadding: AppSpacing.paddingLG,
                      title: Text(
                        AppLocalizations.of(context)!.quietHoursAllowUrgent,
                        style: context.titleSmall,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.quietHoursAllowUrgentSubtitle,
                        style: context.bodySmall,
                      ),
                      value: settings.quietHours.allowUrgent,
                      activeColor: AppColors.primary,
                      onChanged: (v) => ref
                          .read(notificationSettingsProvider.notifier)
                          .updateQuietHours(
                            settings.quietHours.copyWith(allowUrgent: v),
                          ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Notification Preferences
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Text(
                AppLocalizations.of(context)!.notificationPreferences,
                style: context.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderMD,
                boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.sound,
                    subtitle: AppLocalizations.of(context)!.playNotificationSounds,
                    value: settings.sound && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('sound', value);
                    },
                  ),
                  Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.vibration,
                    subtitle: AppLocalizations.of(context)!.vibrateOnNotifications,
                    value: settings.vibration && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('vibration', value);
                    },
                  ),
                  Divider(height: 1, indent: AppSpacing.lg, color: context.dividerColor),
                  _buildSettingsTile(
                    context: context,
                    title: AppLocalizations.of(context)!.showPreview,
                    subtitle: AppLocalizations.of(context)!.showMessagePreviewInNotifications,
                    value: settings.showPreview && settings.enabled,
                    enabled: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('showPreview', value);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Muted Conversations
            if (settings.mutedConversations.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Text(
                  AppLocalizations.of(context)!.mutedConversations,
                  style: context.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppRadius.borderMD,
                  boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
                ),
                child: Column(
                  children: settings.mutedConversations.map((conversationId) {
                    return ListTile(
                      contentPadding: AppSpacing.paddingLG,
                      leading: Icon(Icons.volume_off, color: context.textSecondary),
                      title: Text(
                        '${AppLocalizations.of(context)!.conversation} $conversationId',
                        style: context.bodyMedium,
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .unmuteConversation(conversationId);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.unmute,
                          style: context.labelMedium.copyWith(color: context.primaryColor),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],

            // System Settings
            Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderMD,
                boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
              ),
              child: ListTile(
                contentPadding: AppSpacing.paddingLG,
                leading: Icon(Icons.settings, color: context.textSecondary),
                title: Text(
                  AppLocalizations.of(context)!.systemNotificationSettings,
                  style: context.titleSmall,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.manageNotificationsInSystemSettings,
                  style: context.bodySmall,
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.textSecondary),
                onTap: () {
                  AppSettings.openAppSettings(
                    type: AppSettingsType.notification,
                  );
                },
              ),
            ),

            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                SizedBox(height: AppSpacing.lg),
                Text(
                  '${AppLocalizations.of(context)!.errorLoadingSettings}: $error',
                  style: context.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.lg),
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
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      contentPadding: AppSpacing.paddingLG,
      title: Text(
        title,
        style: context.titleSmall.copyWith(
          color: enabled ? context.textPrimary : context.textMuted,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.bodySmall.copyWith(
          color: enabled ? context.textSecondary : context.textMuted,
        ),
      ),
      value: value,
      activeColor: AppColors.primary,
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// Parse 'HH:mm' string into a TimeOfDay.
TimeOfDay _parseHHmm(String s) {
  final parts = s.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Format a TimeOfDay as zero-padded 'HH:mm'.
String _formatHHmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
