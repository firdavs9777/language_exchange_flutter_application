import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/services/location_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _isUpdatingLocation = false;
  String? _savingKey; // tracks which toggle is currently saving

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
    HapticFeedback.selectionClick();
    setState(() => _savingKey = setting);

    // Optimistic local update
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

    try {
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

      await ref
          .read(authServiceProvider)
          .updatePrivacySettings(privacySettings: privacySettingsMap);

      ref.invalidate(userProvider);
      await ref.read(userProvider.future);

      if (!mounted) return;
      setState(() => _savingKey = null);
      _showSavedSnackBar();
    } catch (e) {
      // Revert on error
      if (!mounted) return;
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
        _savingKey = null;
      });

      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _updateLocation() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    setState(() => _isUpdatingLocation = true);

    try {
      final locationService = LocationService();

      final hasPermission = await locationService.checkAndRequestPermission();
      if (!hasPermission) {
        if (mounted) {
          final permStatus = await locationService.getPermissionStatus();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.locationPermissionDenied)),
                ],
              ),
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
        }
        return;
      }

      final position = await locationService.getCurrentPosition(
        forceRefresh: true,
      );
      if (position == null) {
        if (mounted) _showWarningSnackBar(l10n.locationServiceDisabled);
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
      } catch (_) {}

      final authService = ref.read(authServiceProvider);
      await authService.updateUserHometown(
        city: city ?? '',
        country: country ?? '',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      ref.invalidate(userProvider);

      if (mounted) _showSuccessSnackBar(l10n.locationUpdated);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          '${l10n.locationCouldNotBeUpdated}: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingLocation = false);
    }
  }

  void _showSavedSnackBar() {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.privacySettingsSaved,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.privacyTitle,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: userAsync.when(
        data: (user) => _buildContent(user, l10n),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Loading settings...',
                style: context.bodySmall.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: context.bodySmall.copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.refresh(userProvider),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.retry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Community user, AppLocalizations l10n) {
    final locationText =
        user.location.city.isNotEmpty && user.location.country.isNotEmpty
        ? '${user.location.city}, ${user.location.country}'
        : user.location.country.isNotEmpty
        ? user.location.country
        : l10n.locationNotAvailable;
    final hasLocation =
        user.location.city.isNotEmpty || user.location.country.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-save banner
          _buildAutoSaveBanner(),
          const SizedBox(height: 20),

          // Location section
          _buildSectionTitle(
            l10n.locationSection,
            Icons.location_on_rounded,
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildLocationCard(l10n, locationText, hasLocation),

          const SizedBox(height: 12),

          _buildSectionContainer([
            _buildToggleTile(
              icon: Icons.public_rounded,
              iconColor: const Color(0xFF2196F3),
              title: l10n.showCountryRegion,
              subtitle: l10n.showCountryRegionDesc,
              value: _showCountryRegion,
              settingKey: 'showCountryRegion',
              isFirst: true,
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.location_city_rounded,
              iconColor: const Color(0xFF2196F3),
              title: l10n.showCity,
              subtitle: l10n.showCityDesc,
              value: _showCity,
              settingKey: 'showCity',
              isLast: true,
            ),
          ]),

          const SizedBox(height: 24),

          // Profile Visibility
          _buildSectionTitle(
            l10n.profileVisibility,
            Icons.visibility_rounded,
            const Color(0xFF7C4DFF),
          ),
          const SizedBox(height: 10),
          _buildSectionContainer([
            _buildToggleTile(
              icon: Icons.cake_rounded,
              iconColor: const Color(0xFFE91E63),
              title: l10n.showAge,
              subtitle: l10n.showAgeDesc,
              value: _showAge,
              settingKey: 'showAge',
              isFirst: true,
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF7C4DFF),
              title: l10n.showZodiacSign,
              subtitle: l10n.showZodiacSignDesc,
              value: _showZodiac,
              settingKey: 'showZodiac',
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
              settingKey: 'showOnlineStatus',
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
              settingKey: 'showGiftingLevel',
              isFirst: true,
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.celebration_rounded,
              iconColor: const Color(0xFFE91E63),
              title: l10n.birthdayNotifications,
              subtitle: l10n.birthdayNotificationsDesc,
              value: _birthdayNotification,
              settingKey: 'birthdayNotification',
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.campaign_rounded,
              iconColor: const Color(0xFF7C4DFF),
              title: l10n.personalizedAds,
              subtitle: l10n.personalizedAdsDesc,
              value: _personalizedAds,
              settingKey: 'personalizedAds',
              isLast: true,
            ),
          ]),
        ],
      ),
    );
  }

  // ========== AUTO-SAVE BANNER ==========
  Widget _buildAutoSaveBanner() {
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
              Icons.bolt_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-save enabled',
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Changes are saved instantly when you toggle.',
                  style: context.captionSmall.copyWith(
                    color: context.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
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
    required String settingKey,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaving = _savingKey == settingKey;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 18 : 0),
      topRight: Radius.circular(isFirst ? 18 : 0),
      bottomLeft: Radius.circular(isLast ? 18 : 0),
      bottomRight: Radius.circular(isLast ? 18 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSaving
            ? null
            : () => _updatePrivacySetting(settingKey, !value),
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
              if (isSaving)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else
                Switch.adaptive(
                  value: value,
                  onChanged: (newVal) =>
                      _updatePrivacySetting(settingKey, newVal),
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
  Widget _buildLocationCard(
    AppLocalizations l10n,
    String locationText,
    bool hasLocation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            locationText,
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
