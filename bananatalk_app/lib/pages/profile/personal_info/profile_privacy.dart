import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/location_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePrivacy extends ConsumerStatefulWidget {
  const ProfilePrivacy({super.key});

  @override
  ConsumerState<ProfilePrivacy> createState() => _ProfilePrivacyState();
}

class _ProfilePrivacyState extends ConsumerState<ProfilePrivacy> {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUpdatingLocation = false;

  // Privacy settings — defaults match backend (all true)
  bool _showCountryRegion = true;
  bool _showCity = true;
  bool _showAge = true;
  bool _showZodiac = true;
  bool _showOnlineStatus = true;
  bool _showGiftingLevel = true;
  bool _birthdayNotification = true;
  bool _personalizedAds = true;

  // Current location info
  String? _currentCity;
  String? _currentCountry;

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
        if (mounted) {
          // Load privacy settings
          if (user.privacySettings != null) {
            final settings = user.privacySettings!;
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
          // Load current location
          if (user.location.city.isNotEmpty || user.location.country.isNotEmpty) {
            setState(() {
              _currentCity = user.location.city.isNotEmpty ? user.location.city : null;
              _currentCountry = user.location.country.isNotEmpty ? user.location.country : null;
            });
          }
        }
      });
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        title: Text(
          l10n.privacyTitle,
          style: context.titleLarge,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Section
                  _buildSectionHeader(l10n.locationSection),
                  _buildLocationTile(l10n),

                  Spacing.gapLG,

                  // Profile Visibility Section
                  _buildSectionHeader(l10n.profileVisibility),
                  _buildSettingTile(
                    title: l10n.showCountryRegion,
                    subtitle: l10n.showCountryRegionDesc,
                    value: _showCountryRegion,
                    onChanged: (value) {
                      setState(() => _showCountryRegion = value);
                    },
                  ),
                  _buildSettingTile(
                    title: l10n.showCity,
                    subtitle: l10n.showCityDesc,
                    value: _showCity,
                    onChanged: (value) {
                      setState(() => _showCity = value);
                    },
                  ),
                  _buildSettingTile(
                    title: l10n.showAge,
                    subtitle: l10n.showAgeDesc,
                    value: _showAge,
                    onChanged: (value) {
                      setState(() => _showAge = value);
                    },
                  ),
                  _buildSettingTile(
                    title: l10n.showZodiacSign,
                    subtitle: l10n.showZodiacSignDesc,
                    value: _showZodiac,
                    onChanged: (value) {
                      setState(() => _showZodiac = value);
                    },
                  ),

                  Spacing.gapLG,

                  // Online Status Section
                  _buildSectionHeader(l10n.onlineStatusSection),
                  _buildSettingTile(
                    title: l10n.showOnlineStatus,
                    subtitle: l10n.showOnlineStatusDesc,
                    value: _showOnlineStatus,
                    onChanged: (value) {
                      setState(() => _showOnlineStatus = value);
                    },
                  ),

                  Spacing.gapLG,

                  // Other Settings Section
                  _buildSectionHeader(l10n.otherSettings),
                  _buildSettingTile(
                    title: l10n.showGiftingLevel,
                    subtitle: l10n.showGiftingLevelDesc,
                    value: _showGiftingLevel,
                    onChanged: (value) {
                      setState(() => _showGiftingLevel = value);
                    },
                  ),
                  _buildSettingTile(
                    title: l10n.birthdayNotifications,
                    subtitle: l10n.birthdayNotificationsDesc,
                    value: _birthdayNotification,
                    onChanged: (value) {
                      setState(() => _birthdayNotification = value);
                    },
                  ),
                  _buildSettingTile(
                    title: l10n.personalizedAds,
                    subtitle: l10n.personalizedAdsDesc,
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
                              l10n.saveChanges,
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

  Widget _buildLocationTile(AppLocalizations l10n) {
    final hasLocation = _currentCity != null || _currentCountry != null;
    final locationDisplay = hasLocation
        ? [
            if (_currentCity != null) _currentCity!,
            if (_currentCountry != null) _currentCountry!,
          ].join(', ')
        : l10n.locationNotAvailable;

    return Container(
      color: context.cardBackground,
      child: ListTile(
        title: Text(
          l10n.updateLocation,
          style: context.titleSmall,
        ),
        subtitle: Text(
          locationDisplay,
          style: context.caption.copyWith(
            color: hasLocation ? AppColors.success : context.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isUpdatingLocation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
        onTap: _isUpdatingLocation ? null : _updateLocation,
      ),
    );
  }

  Future<void> _updateLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isUpdatingLocation = true);

    try {
      final locationService = LocationService();

      // Check and request permission
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

      // Get current position
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

      // Reverse geocode to get city and country
      String? city;
      String? country;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? place.subAdministrativeArea;
          country = place.country;
        }
      } catch (_) {
        // Geocoding failed, still update coordinates
      }

      // Update on backend
      final authService = ref.read(authServiceProvider);
      await authService.updateUserHometown(
        city: city ?? '',
        country: country ?? '',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Refresh user data
      ref.invalidate(userProvider);

      if (mounted) {
        setState(() {
          _currentCity = city;
          _currentCountry = country;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationUpdated),
            backgroundColor: AppColors.success,
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

  Future<void> _savePrivacySettings() async {
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(
            content: Text(l10n.privacySettingsSaved),
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
            content: Text('${l10n.failedToSave}: ${e.toString().replaceFirst('Exception: ', '')}'),
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
