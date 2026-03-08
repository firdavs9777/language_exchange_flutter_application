import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/models/notification_models.dart';

class ProfileNotifications extends ConsumerStatefulWidget {
  const ProfileNotifications({super.key});

  @override
  ConsumerState<ProfileNotifications> createState() =>
      _ProfileNotificationsState();
}

class _ProfileNotificationsState extends ConsumerState<ProfileNotifications> {
  bool _isSaving = false;

  // Local state for settings
  late bool _enabled;
  late bool _chatMessages;
  late bool _moments;
  late bool _followerMoments;
  late bool _friendRequests;
  late bool _profileVisits;
  late bool _marketing;
  late bool _sound;
  late bool _vibration;
  late bool _showPreview;

  bool _initialized = false;

  void _initializeFromSettings(NotificationSettings settings) {
    if (!_initialized) {
      _enabled = settings.enabled;
      _chatMessages = settings.chatMessages;
      _moments = settings.moments;
      _followerMoments = settings.followerMoments;
      _friendRequests = settings.friendRequests;
      _profileVisits = settings.profileVisits;
      _marketing = settings.marketing;
      _sound = settings.sound;
      _vibration = settings.vibration;
      _showPreview = settings.showPreview;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        title: Text(
          'Notifications',
          style: context.titleLarge,
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.textMuted),
              const SizedBox(height: 16),
              Text('Failed to load settings', style: context.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(notificationSettingsProvider.notifier).fetchSettings(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) {
          _initializeFromSettings(settings);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master Toggle
                _buildSectionHeader('Push Notifications'),
                _buildSettingTile(
                  title: 'Enable Push Notifications',
                  subtitle: 'Receive notifications on your device',
                  value: _enabled,
                  onChanged: (value) {
                    setState(() => _enabled = value);
                  },
                ),

                Spacing.gapLG,

                // Message Notifications Section
                _buildSectionHeader('Messages'),
                _buildSettingTile(
                  title: 'Chat Messages',
                  subtitle: 'Get notified when you receive new messages',
                  value: _chatMessages,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _chatMessages = value);
                  },
                ),

                Spacing.gapLG,

                // Social Notifications Section
                _buildSectionHeader('Social'),
                _buildSettingTile(
                  title: 'Moments',
                  subtitle: 'Get notified about new moments',
                  value: _moments,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _moments = value);
                  },
                ),
                _buildSettingTile(
                  title: 'Follower Moments',
                  subtitle: 'Get notified about moments from people you follow',
                  value: _followerMoments,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _followerMoments = value);
                  },
                ),
                _buildSettingTile(
                  title: 'Friend Requests',
                  subtitle: 'Get notified when someone sends you a request',
                  value: _friendRequests,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _friendRequests = value);
                  },
                ),
                _buildSettingTile(
                  title: 'Profile Visits',
                  subtitle: 'Get notified when someone visits your profile',
                  value: _profileVisits,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _profileVisits = value);
                  },
                ),

                Spacing.gapLG,

                // Notification Style Section
                _buildSectionHeader('Notification Style'),
                _buildSettingTile(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _sound,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _sound = value);
                  },
                ),
                _buildSettingTile(
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: _vibration,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _vibration = value);
                  },
                ),
                _buildSettingTile(
                  title: 'Show Preview',
                  subtitle: 'Show message content in notifications',
                  value: _showPreview,
                  enabled: _enabled,
                  onChanged: (value) {
                    setState(() => _showPreview = value);
                  },
                ),

                Spacing.gapLG,

                // Marketing Section
                _buildSectionHeader('Marketing'),
                _buildSettingTile(
                  title: 'Promotional Notifications',
                  subtitle: 'Receive updates about offers and features',
                  value: _marketing,
                  onChanged: (value) {
                    setState(() => _marketing = value);
                  },
                ),

                Spacing.gapXXL,

                // Save Button
                Padding(
                  padding: Spacing.screenPadding,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveNotificationSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: context.titleMedium.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),

                Spacing.gapXXL,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: context.titleMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      color: context.cardBackground,
      child: SwitchListTile(
        title: Text(
          title,
          style: context.titleSmall.copyWith(
            color: enabled ? context.textPrimary : context.textMuted,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: context.caption.copyWith(
            color: enabled ? context.textSecondary : context.textMuted,
          ),
        ),
        value: value && enabled,
        activeColor: AppColors.primary,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => _isSaving = true);

    try {
      final currentSettings = ref.read(notificationSettingsProvider).value;

      final newSettings = NotificationSettings(
        enabled: _enabled,
        chatMessages: _chatMessages,
        moments: _moments,
        followerMoments: _followerMoments,
        friendRequests: _friendRequests,
        profileVisits: _profileVisits,
        marketing: _marketing,
        sound: _sound,
        vibration: _vibration,
        showPreview: _showPreview,
        mutedConversations: currentSettings?.mutedConversations ?? [],
      );

      await ref
          .read(notificationSettingsProvider.notifier)
          .updateSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
