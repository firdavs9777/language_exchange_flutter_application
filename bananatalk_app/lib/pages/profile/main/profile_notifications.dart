import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class ProfileNotifications extends ConsumerStatefulWidget {
  const ProfileNotifications({super.key});

  @override
  ConsumerState<ProfileNotifications> createState() => _ProfileNotificationsState();
}

class _ProfileNotificationsState extends ConsumerState<ProfileNotifications> {
  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _momentNotifications = true;
  bool _commentNotifications = true;
  bool _likeNotifications = true;
  bool _followerNotifications = true;
  bool _profileVisitNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Push Notifications Section
            _buildSectionHeader('Push Notifications'),
            _buildSettingTile(
              title: 'Enable Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: _pushNotifications,
              onChanged: (value) {
                setState(() => _pushNotifications = value);
              },
            ),

            Spacing.gapLG,

            // Message Notifications Section
            _buildSectionHeader('Messages'),
            _buildSettingTile(
              title: 'New Messages',
              subtitle: 'Get notified when you receive new messages',
              value: _messageNotifications,
              enabled: _pushNotifications,
              onChanged: (value) {
                setState(() => _messageNotifications = value);
              },
            ),

            Spacing.gapLG,

            // Social Notifications Section
            _buildSectionHeader('Social'),
            _buildSettingTile(
              title: 'New Moments',
              subtitle: 'Get notified about new moments from friends',
              value: _momentNotifications,
              enabled: _pushNotifications,
              onChanged: (value) {
                setState(() => _momentNotifications = value);
              },
            ),
            _buildSettingTile(
              title: 'Comments',
              subtitle: 'Get notified when someone comments on your posts',
              value: _commentNotifications,
              enabled: _pushNotifications,
              onChanged: (value) {
                setState(() => _commentNotifications = value);
              },
            ),
            _buildSettingTile(
              title: 'Likes',
              subtitle: 'Get notified when someone likes your posts',
              value: _likeNotifications,
              enabled: _pushNotifications,
              onChanged: (value) {
                setState(() => _likeNotifications = value);
              },
            ),
            _buildSettingTile(
              title: 'New Followers',
              subtitle: 'Get notified when someone follows you',
              value: _followerNotifications,
              enabled: _pushNotifications,
              onChanged: (value) {
                setState(() => _followerNotifications = value);
              },
            ),
            _buildSettingTile(
              title: 'Profile Visits',
              subtitle: 'Get notified when someone visits your profile',
              value: _profileVisitNotifications,
              enabled: _pushNotifications,
              onChanged: (value) {
                setState(() => _profileVisitNotifications = value);
              },
            ),

            Spacing.gapLG,

            // Email Notifications Section
            _buildSectionHeader('Email Notifications'),
            _buildSettingTile(
              title: 'Enable Email Notifications',
              subtitle: 'Receive important updates via email',
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
              },
            ),

            Spacing.gapXXL,

            // Save Button
            Padding(
              padding: Spacing.screenPadding,
              child: ElevatedButton(
                onPressed: _saveNotificationSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                ),
                child: Text(
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
    // TODO: Implement saving notification settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }
}
