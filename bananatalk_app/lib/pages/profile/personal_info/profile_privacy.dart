import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        if (!mounted) return;
        if (user.privacySettings != null) {
          final s = user.privacySettings!;
          setState(() {
            _showCountryRegion = s.showCountryRegion;
            _showCity = s.showCity;
            _showAge = s.showAge;
            _showZodiac = s.showZodiac;
            _showOnlineStatus = s.showOnlineStatus;
            _showGiftingLevel = s.showGiftingLevel;
            _birthdayNotification = s.birthdayNotification;
            _personalizedAds = s.personalizedAds;
          });
        }
        if (user.location.city.isNotEmpty || user.location.country.isNotEmpty) {
          setState(() {
            _currentCity =
                user.location.city.isNotEmpty ? user.location.city : null;
            _currentCountry =
                user.location.country.isNotEmpty ? user.location.country : null;
          });
        }
      });
    } catch (_) {
      // Settings will default to true if loading fails
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocation() async {
    if (_isUpdatingLocation) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isUpdatingLocation = true);

    try {
      final locationService = LocationService();

      final hasPermission = await locationService.checkAndRequestPermission();
      if (!mounted) return;

      if (!hasPermission) {
        final permStatus = await locationService.getPermissionStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationPermissionDenied),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            action: permStatus.isPermanentlyDenied
                ? SnackBarAction(
                    label: l10n.openSettings,
                    textColor: Colors.white,
                    onPressed: () => LocationService().openSettings(),
                  )
                : null,
          ),
        );
        return;
      }

      final position =
          await locationService.getCurrentPosition(forceRefresh: true);
      if (!mounted) return;

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationServiceDisabled),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
        return;
      }

      String? city;
      String? country;
      try {
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
      } catch (_) {
        // Geocoding failed — still update coordinates
      }

      await ref.read(authServiceProvider).updateUserHometown(
            city: city ?? '',
            country: country ?? '',
            latitude: position.latitude,
            longitude: position.longitude,
          );

      ref.invalidate(userProvider);

      if (!mounted) return;
      setState(() {
        _currentCity = city;
        _currentCountry = country;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.locationUpdated)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.locationCouldNotBeUpdated}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingLocation = false);
    }
  }

  Future<void> _savePrivacySettings() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) throw Exception('User not found');

      await ref.read(authServiceProvider).updatePrivacySettings(
        privacySettings: {
          'showCountryRegion': _showCountryRegion,
          'showCity': _showCity,
          'showAge': _showAge,
          'showZodiac': _showZodiac,
          'showOnlineStatus': _showOnlineStatus,
          'showGiftingLevel': _showGiftingLevel,
          'birthdayNotification': _birthdayNotification,
          'personalizedAds': _personalizedAds,
        },
      );

      ref.invalidate(userProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.privacySettingsSaved)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.failedToSave}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        title: Text(l10n.privacyTitle, style: context.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: Spacing.paddingLG,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePrivacySettings,
              child: Text(
                l10n.saveChanges,
                style: context.titleMedium.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                    onChanged: (v) => setState(() => _showCountryRegion = v),
                  ),
                  _buildSettingTile(
                    title: l10n.showCity,
                    subtitle: l10n.showCityDesc,
                    value: _showCity,
                    onChanged: (v) => setState(() => _showCity = v),
                  ),
                  _buildSettingTile(
                    title: l10n.showAge,
                    subtitle: l10n.showAgeDesc,
                    value: _showAge,
                    onChanged: (v) => setState(() => _showAge = v),
                  ),
                  _buildSettingTile(
                    title: l10n.showZodiacSign,
                    subtitle: l10n.showZodiacSignDesc,
                    value: _showZodiac,
                    onChanged: (v) => setState(() => _showZodiac = v),
                  ),

                  Spacing.gapLG,

                  // Online Status Section
                  _buildSectionHeader(l10n.onlineStatusSection),
                  _buildSettingTile(
                    title: l10n.showOnlineStatus,
                    subtitle: l10n.showOnlineStatusDesc,
                    value: _showOnlineStatus,
                    onChanged: (v) => setState(() => _showOnlineStatus = v),
                  ),

                  Spacing.gapLG,

                  // Other Settings Section
                  _buildSectionHeader(l10n.otherSettings),
                  _buildSettingTile(
                    title: l10n.showGiftingLevel,
                    subtitle: l10n.showGiftingLevelDesc,
                    value: _showGiftingLevel,
                    onChanged: (v) => setState(() => _showGiftingLevel = v),
                  ),
                  _buildSettingTile(
                    title: l10n.birthdayNotifications,
                    subtitle: l10n.birthdayNotificationsDesc,
                    value: _birthdayNotification,
                    onChanged: (v) => setState(() => _birthdayNotification = v),
                  ),
                  _buildSettingTile(
                    title: l10n.personalizedAds,
                    subtitle: l10n.personalizedAdsDesc,
                    value: _personalizedAds,
                    onChanged: (v) => setState(() => _personalizedAds = v),
                  ),

                  Spacing.gapXXL,

                  // Bottom save button (secondary affordance)
                  Padding(
                    padding: Spacing.screenPadding,
                    child: _buildGradientSaveButton(l10n),
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
        style: context.titleMedium.copyWith(color: AppColors.primary),
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
        title: Text(title, style: context.titleSmall),
        subtitle: Text(subtitle, style: context.caption),
        value: value,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
        onChanged: _isSaving ? null : onChanged,
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
        title: Text(l10n.updateLocation, style: context.titleSmall),
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
            : const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 22),
        onTap: _isUpdatingLocation ? null : _updateLocation,
      ),
    );
  }

  Widget _buildGradientSaveButton(AppLocalizations l10n) {
    final canSave = !_isSaving;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSave ? _savePrivacySettings : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: canSave
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                    )
                  : null,
              color: canSave
                  ? null
                  : context.dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: canSave
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: canSave ? Colors.white : context.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.saveChanges,
                          style: context.titleSmall.copyWith(
                            color: canSave ? Colors.white : context.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
