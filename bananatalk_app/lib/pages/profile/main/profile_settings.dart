import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSettings extends ConsumerStatefulWidget {
  const ProfileSettings({super.key});

  @override
  ConsumerState<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends ConsumerState<ProfileSettings> {
  // Privacy settings state - these will be loaded from backend
  bool _showCountryRegion = true;
  bool _showCity = true;
  bool _showAge = false;
  bool _showZodiac = true;
  bool _showOnlineStatus = false;
  bool _showGiftingLevel = true;
  bool _birthdayNotification = true;
  bool _personalizedAds = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrivacySettings();
    });
  }

  Future<void> _loadPrivacySettings() async {
    final userAsync = ref.read(userProvider);
    userAsync.whenData((user) {
      if (mounted && user.privacySettings != null) {
        setState(() {
          _showCountryRegion = user.privacySettings!.showCountryRegion;
          _showCity = user.privacySettings!.showCity;
          _showAge = user.privacySettings!.showAge;
          _showZodiac = user.privacySettings!.showZodiac;
          _showOnlineStatus = user.privacySettings!.showOnlineStatus;
          _showGiftingLevel = user.privacySettings!.showGiftingLevel;
          _birthdayNotification = user.privacySettings!.birthdayNotification;
          _personalizedAds = user.privacySettings!.personalizedAds;
        });
      }
    });
  }

  Future<void> _updatePrivacySetting(String setting, bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update local state optimistically
      setState(() {
        switch (setting) {
          case 'showCountryRegion':
            _showCountryRegion = value;
            break;
          case 'showCity':
            _showCity = value;
            break;
          case 'showAge':
            _showAge = value;
            break;
          case 'showZodiac':
            _showZodiac = value;
            break;
          case 'showOnlineStatus':
            _showOnlineStatus = value;
            break;
          case 'showGiftingLevel':
            _showGiftingLevel = value;
            break;
          case 'birthdayNotification':
            _birthdayNotification = value;
            break;
          case 'personalizedAds':
            _personalizedAds = value;
            break;
        }
      });

      // Prepare privacy settings map for backend
      final privacySettingsMap = {
        'showCountryRegion': _showCountryRegion,
        'showCity': _showCity,
        'showAge': _showAge,
        'showZodiac': _showZodiac,
        'showOnlineStatus': _showOnlineStatus,
        'showGiftingLevel': _showGiftingLevel,
        'birthdayNotification': _birthdayNotification,
        'personalizedAds': _personalizedAds,
      };

      // Call backend API to update privacy settings
      await ref.read(authServiceProvider).updatePrivacySettings(
            privacySettings: privacySettingsMap,
          );

      // Refresh user provider to get updated data
      ref.invalidate(userProvider);
      await ref.read(userProvider.future);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy setting updated'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert local state on error
      setState(() {
        switch (setting) {
          case 'showCountryRegion':
            _showCountryRegion = !value;
            break;
          case 'showCity':
            _showCity = !value;
            break;
          case 'showAge':
            _showAge = !value;
            break;
          case 'showZodiac':
            _showZodiac = !value;
            break;
          case 'showOnlineStatus':
            _showOnlineStatus = !value;
            break;
          case 'showGiftingLevel':
            _showGiftingLevel = !value;
            break;
          case 'birthdayNotification':
            _birthdayNotification = !value;
            break;
          case 'personalizedAds':
            _personalizedAds = !value;
            break;
        }
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) => _buildContent(user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Community user) {
    final locationText =
        user.location.city.isNotEmpty && user.location.country.isNotEmpty
            ? '${user.location.city}, ${user.location.country}'
            : user.location.country.isNotEmpty
                ? user.location.country
                : 'Location not set';

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Display
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      locationText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Location Settings Section
              _buildSettingTile(
                title: 'Show Country/Region',
                value: _showCountryRegion,
                onChanged: (value) =>
                    _updatePrivacySetting('showCountryRegion', value),
              ),
              _buildSettingTile(
                title: 'Show City',
                value: _showCity,
                onChanged: (value) => _updatePrivacySetting('showCity', value),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to location update screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location update feature coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Update Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'BanaTalk uses location services to determine which city you live in.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),

              const Divider(height: 32),

              // Personal Information Settings
              _buildSettingTile(
                title: 'Show Age',
                value: _showAge,
                onChanged: (value) => _updatePrivacySetting('showAge', value),
              ),
              _buildSettingTile(
                title: 'Show Zodiac',
                value: _showZodiac,
                onChanged: (value) =>
                    _updatePrivacySetting('showZodiac', value),
              ),

              const Divider(height: 32),

              // Status Settings
              _buildSettingTile(
                title: 'Show Online Status',
                value: _showOnlineStatus,
                onChanged: (value) =>
                    _updatePrivacySetting('showOnlineStatus', value),
              ),

              const Divider(height: 32),

              // Gifting Level
              _buildSettingTile(
                title: 'Show My Gifting Level',
                value: _showGiftingLevel,
                onChanged: (value) =>
                    _updatePrivacySetting('showGiftingLevel', value),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'When turned off, your gifting level will only be displayed in Live & Voiceroom',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),

              const Divider(height: 32),

              // Birthday Notification
              _buildSettingTile(
                title: 'Birthday Notification',
                value: _birthdayNotification,
                onChanged: (value) =>
                    _updatePrivacySetting('birthdayNotification', value),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'After turning off, language partners and groups won\'t receive birthday reminders on your birthday',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),

              const Divider(height: 32),

              // Personalized Ads
              _buildSettingTile(
                title: 'Personalized Ads',
                value: _personalizedAds,
                onChanged: (value) =>
                    _updatePrivacySetting('personalizedAds', value),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Once turned off, ad relevance is reduced. We recommend keeping it on.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF00BFA5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
