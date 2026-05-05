import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
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

  // Track initial state to detect changes
  late Map<String, bool> _initialSettings;

  String? _currentCity;
  String? _currentCountry;

  @override
  void initState() {
    super.initState();
    _initialSettings = _captureSettings();
    _loadCurrentSettings();
  }

  Map<String, bool> _captureSettings() => {
    'showCountryRegion': _showCountryRegion,
    'showCity': _showCity,
    'showAge': _showAge,
    'showZodiac': _showZodiac,
    'showOnlineStatus': _showOnlineStatus,
    'showGiftingLevel': _showGiftingLevel,
    'birthdayNotification': _birthdayNotification,
    'personalizedAds': _personalizedAds,
  };

  bool get _hasChanges {
    final current = _captureSettings();
    for (final key in current.keys) {
      if (current[key] != _initialSettings[key]) return true;
    }
    return false;
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
            _initialSettings = _captureSettings();
          });
        }
        if (user.location.city.isNotEmpty || user.location.country.isNotEmpty) {
          setState(() {
            _currentCity = user.location.city.isNotEmpty
                ? user.location.city
                : null;
            _currentCountry = user.location.country.isNotEmpty
                ? user.location.country
                : null;
          });
        }
      });
    } catch (_) {
      // Settings will default to true if loading fails
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onToggle(VoidCallback updateState) {
    HapticFeedback.selectionClick();
    setState(updateState);
  }

  Future<void> _updateLocation() async {
    if (_isUpdatingLocation) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
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

      final position = await locationService.getCurrentPosition(
        forceRefresh: true,
      );
      if (!mounted) return;

      if (position == null) {
        showProfileSnackBar(
          context,
          message: l10n.locationServiceDisabled,
          type: ProfileSnackBarType.warning,
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

      await ref
          .read(authServiceProvider)
          .updateUserHometown(
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
      showProfileSnackBar(
        context,
        message: l10n.locationUpdated,
        type: ProfileSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showProfileSnackBar(
        context,
        message:
            '${AppLocalizations.of(context)!.locationCouldNotBeUpdated}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
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

      await ref
          .read(authServiceProvider)
          .updatePrivacySettings(privacySettings: _captureSettings());

      ref.invalidate(userProvider);

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.privacySettingsSaved,
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showProfileSnackBar(
        context,
        message:
            '${AppLocalizations.of(context)!.failedToSave}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSave = _hasChanges && !_isSaving;

    return EditScreenScaffold(
      title: l10n.privacyTitle,
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _savePrivacySettings,
      showBottomSaveButton: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy info banner
                _buildPrivacyBanner(l10n),
                const SizedBox(height: 20),

                // Location section
                _buildSectionTitle(
                  l10n.locationSection,
                  Icons.location_on_rounded,
                  AppColors.primary,
                ),
                const SizedBox(height: 10),
                _buildLocationCard(l10n),

                const SizedBox(height: 24),

                // Profile Visibility
                _buildSectionTitle(
                  l10n.profileVisibility,
                  Icons.visibility_rounded,
                  const Color(0xFF2196F3),
                ),
                const SizedBox(height: 10),
                _buildSectionContainer([
                  _buildToggleTile(
                    icon: Icons.public_rounded,
                    iconColor: const Color(0xFF2196F3),
                    title: l10n.showCountryRegion,
                    subtitle: l10n.showCountryRegionDesc,
                    value: _showCountryRegion,
                    onChanged: (v) => _onToggle(() => _showCountryRegion = v),
                    isFirst: true,
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.location_city_rounded,
                    iconColor: const Color(0xFF2196F3),
                    title: l10n.showCity,
                    subtitle: l10n.showCityDesc,
                    value: _showCity,
                    onChanged: (v) => _onToggle(() => _showCity = v),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.cake_rounded,
                    iconColor: const Color(0xFFE91E63),
                    title: l10n.showAge,
                    subtitle: l10n.showAgeDesc,
                    value: _showAge,
                    onChanged: (v) => _onToggle(() => _showAge = v),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF7C4DFF),
                    title: l10n.showZodiacSign,
                    subtitle: l10n.showZodiacSignDesc,
                    value: _showZodiac,
                    onChanged: (v) => _onToggle(() => _showZodiac = v),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // Online Status
                _buildSectionTitle(
                  l10n.onlineStatusSection,
                  Icons.circle_rounded,
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 10),
                _buildSectionContainer([
                  _buildToggleTile(
                    icon: Icons.fiber_manual_record_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: l10n.showOnlineStatus,
                    subtitle: l10n.showOnlineStatusDesc,
                    value: _showOnlineStatus,
                    onChanged: (v) => _onToggle(() => _showOnlineStatus = v),
                    isFirst: true,
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // Other Settings
                _buildSectionTitle(
                  l10n.otherSettings,
                  Icons.tune_rounded,
                  const Color(0xFFFF9800),
                ),
                const SizedBox(height: 10),
                _buildSectionContainer([
                  _buildToggleTile(
                    icon: Icons.card_giftcard_rounded,
                    iconColor: const Color(0xFFFF9800),
                    title: l10n.showGiftingLevel,
                    subtitle: l10n.showGiftingLevelDesc,
                    value: _showGiftingLevel,
                    onChanged: (v) => _onToggle(() => _showGiftingLevel = v),
                    isFirst: true,
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.celebration_rounded,
                    iconColor: const Color(0xFFE91E63),
                    title: l10n.birthdayNotifications,
                    subtitle: l10n.birthdayNotificationsDesc,
                    value: _birthdayNotification,
                    onChanged: (v) =>
                        _onToggle(() => _birthdayNotification = v),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.campaign_rounded,
                    iconColor: const Color(0xFF7C4DFF),
                    title: l10n.personalizedAds,
                    subtitle: l10n.personalizedAdsDesc,
                    value: _personalizedAds,
                    onChanged: (v) => _onToggle(() => _personalizedAds = v),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 28),

                // Bottom save button
                GradientSaveButton(
                  canSave: canSave,
                  isSaving: _isSaving,
                  onPressed: _savePrivacySettings,
                ),

                if (_hasChanges) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: context.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'You have unsaved changes',
                          style: context.captionSmall.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // ========== PRIVACY BANNER ==========
  Widget _buildPrivacyBanner(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You control what others can see. Toggle items off to hide them from your public profile.',
              style: context.captionSmall.copyWith(
                color: context.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION TITLE ==========
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: context.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ========== SECTION CONTAINER ==========
  Widget _buildSectionContainer(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.dividerColor.withValues(alpha: 0.4),
      ),
    );
  }

  // ========== TOGGLE TILE ==========
  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 18 : 0),
      topRight: Radius.circular(isFirst ? 18 : 0),
      bottomLeft: Radius.circular(isLast ? 18 : 0),
      bottomRight: Radius.circular(isLast ? 18 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : () => onChanged(!value),
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.captionSmall.copyWith(
                        color: context.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                onChanged: _isSaving ? null : onChanged,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== LOCATION CARD ==========
  Widget _buildLocationCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLocation = _currentCity != null || _currentCountry != null;
    final locationDisplay = hasLocation
        ? [
            if (_currentCity != null) _currentCity!,
            if (_currentCountry != null) _currentCountry!,
          ].join(', ')
        : l10n.locationNotAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isUpdatingLocation ? null : _updateLocation,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.updateLocation,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (hasLocation)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.success,
                          )
                        else
                          Icon(
                            Icons.location_off_rounded,
                            size: 12,
                            color: context.textMuted,
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationDisplay,
                            style: context.captionSmall.copyWith(
                              color: hasLocation
                                  ? AppColors.success
                                  : context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isUpdatingLocation)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.18 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Update',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
