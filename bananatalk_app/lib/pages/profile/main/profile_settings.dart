import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/services/location_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSettings extends ConsumerStatefulWidget {
  const ProfileSettings({super.key});

  @override
  ConsumerState<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends ConsumerState<ProfileSettings> {
  // Privacy settings state — defaults match backend (all true)
  bool _showCountryRegion = true;
  bool _showCity = true;
  bool _showAge = true;
  bool _showZodiac = true;
  bool _showOnlineStatus = true;
  bool _showGiftingLevel = true;
  bool _birthdayNotification = true;
  bool _personalizedAds = true;

  bool _isLoading = false;
  bool _isUpdatingLocation = false;

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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.privacySettingsSaved),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
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

  Future<void> _updateLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isUpdatingLocation = true);

    try {
      final locationService = LocationService();

      final hasPermission = await locationService.checkAndRequestPermission();
      if (!hasPermission) {
        if (mounted) {
          final permStatus = await locationService.getPermissionStatus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationPermissionDenied),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              action: permStatus.isPermanentlyDenied
                  ? SnackBarAction(
                      label: l10n.openSettings,
                      textColor: Colors.white,
                      onPressed: () => LocationService().openSettings(),
                    )
                  : null,
            ),
          );
        }
        return;
      }

      final position = await locationService.getCurrentPosition(forceRefresh: true);
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationServiceDisabled),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      String? city;
      String? country;
      try {
        // Use English locale for location names (universally readable)
        await setLocaleIdentifier('en_US');
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? place.subAdministrativeArea;
          country = place.country;
        }
      } catch (_) {}

      final authService = ref.read(authServiceProvider);
      await authService.updateUserHometown(
        city: city ?? '',
        country: country ?? '',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      ref.invalidate(userProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationUpdated),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.locationCouldNotBeUpdated}: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.privacyTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              Spacing.gapLG,
              Text('Error: $error', style: context.bodyMedium),
              Spacing.gapLG,
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
    final l10n = AppLocalizations.of(context)!;
    final locationText =
        user.location.city.isNotEmpty && user.location.country.isNotEmpty
            ? '${user.location.city}, ${user.location.country}'
            : user.location.country.isNotEmpty
                ? user.location.country
                : l10n.locationNotAvailable;

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
                  color: context.containerColor,
                  border: Border(
                    bottom: BorderSide(color: context.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: context.textSecondary),
                    Spacing.hGapSM,
                    Expanded(
                      child: Text(
                        locationText,
                        style: context.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              Spacing.gapSM,

              // Location Settings Section
              _buildSectionLabel(l10n.locationSection),
              _buildSettingTile(
                title: l10n.showCountryRegion,
                value: _showCountryRegion,
                onChanged: (value) =>
                    _updatePrivacySetting('showCountryRegion', value),
              ),
              _buildSettingTile(
                title: l10n.showCity,
                value: _showCity,
                onChanged: (value) => _updatePrivacySetting('showCity', value),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: InkWell(
                  onTap: _isUpdatingLocation ? null : _updateLocation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.updateLocation,
                          style: context.titleMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        _isUpdatingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              Divider(height: 32, color: context.dividerColor),

              // Personal Information
              _buildSectionLabel(l10n.profileVisibility),
              _buildSettingTile(
                title: l10n.showAge,
                value: _showAge,
                onChanged: (value) => _updatePrivacySetting('showAge', value),
              ),
              _buildSettingTile(
                title: l10n.showZodiacSign,
                value: _showZodiac,
                onChanged: (value) =>
                    _updatePrivacySetting('showZodiac', value),
              ),

              Divider(height: 32, color: context.dividerColor),

              // Online Status
              _buildSectionLabel(l10n.onlineStatusSection),
              _buildSettingTile(
                title: l10n.showOnlineStatus,
                subtitle: l10n.showOnlineStatusDesc,
                value: _showOnlineStatus,
                onChanged: (value) =>
                    _updatePrivacySetting('showOnlineStatus', value),
              ),

              Divider(height: 32, color: context.dividerColor),

              // Gifting Level
              _buildSectionLabel(l10n.otherSettings),
              _buildSettingTile(
                title: l10n.showGiftingLevel,
                subtitle: l10n.showGiftingLevelDesc,
                value: _showGiftingLevel,
                onChanged: (value) =>
                    _updatePrivacySetting('showGiftingLevel', value),
              ),

              Divider(height: 1, color: context.dividerColor),

              // Birthday Notification
              _buildSettingTile(
                title: l10n.birthdayNotifications,
                subtitle: l10n.birthdayNotificationsDesc,
                value: _birthdayNotification,
                onChanged: (value) =>
                    _updatePrivacySetting('birthdayNotification', value),
              ),

              Divider(height: 1, color: context.dividerColor),

              // Personalized Ads
              _buildSettingTile(
                title: l10n.personalizedAds,
                subtitle: l10n.personalizedAdsDesc,
                value: _personalizedAds,
                onChanged: (value) =>
                    _updatePrivacySetting('personalizedAds', value),
              ),

              Spacing.gapXXL,
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label,
        style: context.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: context.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
