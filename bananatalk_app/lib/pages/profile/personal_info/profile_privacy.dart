import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class ProfilePrivacy extends ConsumerStatefulWidget {
  const ProfilePrivacy({super.key});

  @override
  ConsumerState<ProfilePrivacy> createState() => _ProfilePrivacyState();
}

class _ProfilePrivacyState extends ConsumerState<ProfilePrivacy> {
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _allowProfileVisits = true;
  bool _showProfileVisitors = true;
  bool _allowMessages = true;
  bool _allowFriendRequests = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        title: Text(
          'Privacy',
          style: context.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online Status Section
            _buildSectionHeader('Online Status'),
            _buildSettingTile(
              title: 'Show Online Status',
              subtitle: 'Let others see when you are online',
              value: _showOnlineStatus,
              onChanged: (value) {
                setState(() => _showOnlineStatus = value);
              },
            ),
            _buildSettingTile(
              title: 'Show Last Seen',
              subtitle: 'Let others see when you were last active',
              value: _showLastSeen,
              onChanged: (value) {
                setState(() => _showLastSeen = value);
              },
            ),

            Spacing.gapLG,

            // Profile Visibility Section
            _buildSectionHeader('Profile Visibility'),
            _buildSettingTile(
              title: 'Allow Profile Visits',
              subtitle: 'Let others view your profile',
              value: _allowProfileVisits,
              onChanged: (value) {
                setState(() => _allowProfileVisits = value);
              },
            ),
            _buildSettingTile(
              title: 'Show Profile Visitors',
              subtitle: 'See who visited your profile',
              value: _showProfileVisitors,
              onChanged: (value) {
                setState(() => _showProfileVisitors = value);
              },
            ),

            Spacing.gapLG,

            // Communication Section
            _buildSectionHeader('Communication'),
            _buildSettingTile(
              title: 'Allow Messages',
              subtitle: 'Let others send you messages',
              value: _allowMessages,
              onChanged: (value) {
                setState(() => _allowMessages = value);
              },
            ),
            _buildSettingTile(
              title: 'Allow Friend Requests',
              subtitle: 'Let others send you friend requests',
              value: _allowFriendRequests,
              onChanged: (value) {
                setState(() => _allowFriendRequests = value);
              },
            ),

            Spacing.gapXXL,

            // Save Button
            Padding(
              padding: Spacing.screenPadding,
              child: ElevatedButton(
                onPressed: _savePrivacySettings,
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
  }) {
    return Container(
      color: context.cardBackground,
      child: SwitchListTile(
        title: Text(
          title,
          style: context.titleSmall,
        ),
        subtitle: Text(
          subtitle,
          style: context.caption,
        ),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _savePrivacySettings() async {
    // TODO: Implement saving privacy settings to backend
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
