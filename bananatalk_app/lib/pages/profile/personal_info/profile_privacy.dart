import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePrivacy extends ConsumerStatefulWidget {
  const ProfilePrivacy({super.key});

  @override
  ConsumerState<ProfilePrivacy> createState() => _ProfilePrivacyState();
}

class _ProfilePrivacyState extends ConsumerState<ProfilePrivacy> {
  bool _isLoading = false;
  bool _isSaving = false;

  // Privacy settings (matching backend model)
  bool _showCountryRegion = true;
  bool _showCity = true;
  bool _showAge = false;
  bool _showZodiac = true;
  bool _showOnlineStatus = false;
  bool _showGiftingLevel = true;
  bool _birthdayNotification = true;
  bool _personalizedAds = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);

    try {
      final userAsync = ref.read(userProvider);
      userAsync.whenData((user) {
        if (user?.privacySettings != null && mounted) {
          final settings = user!.privacySettings!;
          setState(() {
            _showCountryRegion = settings.showCountryRegion;
            _showCity = settings.showCity;
            _showAge = settings.showAge;
            _showZodiac = settings.showZodiac;
            _showOnlineStatus = settings.showOnlineStatus;
            _showGiftingLevel = settings.showGiftingLevel;
            _birthdayNotification = settings.birthdayNotification;
            _personalizedAds = settings.personalizedAds;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Visibility Section
                  _buildSectionHeader('Profile Visibility'),
                  _buildSettingTile(
                    title: 'Show Country/Region',
                    subtitle: 'Display your country on your profile',
                    value: _showCountryRegion,
                    onChanged: (value) {
                      setState(() => _showCountryRegion = value);
                    },
                  ),
                  _buildSettingTile(
                    title: 'Show City',
                    subtitle: 'Display your city on your profile',
                    value: _showCity,
                    onChanged: (value) {
                      setState(() => _showCity = value);
                    },
                  ),
                  _buildSettingTile(
                    title: 'Show Age',
                    subtitle: 'Display your age on your profile',
                    value: _showAge,
                    onChanged: (value) {
                      setState(() => _showAge = value);
                    },
                  ),
                  _buildSettingTile(
                    title: 'Show Zodiac Sign',
                    subtitle: 'Display your zodiac sign on your profile',
                    value: _showZodiac,
                    onChanged: (value) {
                      setState(() => _showZodiac = value);
                    },
                  ),

                  Spacing.gapLG,

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

                  Spacing.gapLG,

                  // Other Settings Section
                  _buildSectionHeader('Other Settings'),
                  _buildSettingTile(
                    title: 'Show Gifting Level',
                    subtitle: 'Display your gifting level badge',
                    value: _showGiftingLevel,
                    onChanged: (value) {
                      setState(() => _showGiftingLevel = value);
                    },
                  ),
                  _buildSettingTile(
                    title: 'Birthday Notifications',
                    subtitle: 'Receive notifications on your birthday',
                    value: _birthdayNotification,
                    onChanged: (value) {
                      setState(() => _birthdayNotification = value);
                    },
                  ),
                  _buildSettingTile(
                    title: 'Personalized Ads',
                    subtitle: 'Allow personalized advertisements',
                    value: _personalizedAds,
                    onChanged: (value) {
                      setState(() => _personalizedAds = value);
                    },
                  ),

                  Spacing.gapXXL,

                  // Save Button
                  Padding(
                    padding: Spacing.screenPadding,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePrivacySettings,
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
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User not found');
      }

      final authService = ref.read(authServiceProvider);

      // Build privacy settings map
      final privacySettings = {
        'showCountryRegion': _showCountryRegion,
        'showCity': _showCity,
        'showAge': _showAge,
        'showZodiac': _showZodiac,
        'showOnlineStatus': _showOnlineStatus,
        'showGiftingLevel': _showGiftingLevel,
        'birthdayNotification': _birthdayNotification,
        'personalizedAds': _personalizedAds,
      };

      await authService.updatePrivacySettings(privacySettings: privacySettings);

      // Refresh user data
      ref.invalidate(userProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved'),
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
