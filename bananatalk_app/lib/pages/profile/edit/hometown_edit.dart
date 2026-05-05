import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileHometownEdit extends ConsumerStatefulWidget {
  final String currentAddress;
  const ProfileHometownEdit({super.key, required this.currentAddress});

  @override
  ConsumerState<ProfileHometownEdit> createState() =>
      _ProfileHometownEditState();
}

class _ProfileHometownEditState extends ConsumerState<ProfileHometownEdit> {
  bool _isFetchingLocation = false;
  bool _isSaving = false;
  String? _country;
  String? _city;
  double? _latitude;
  double? _longitude;

  Future<bool> _handleLocationPermission() async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      showProfileSnackBar(
        context,
        message: l10n.locationServicesDisabled,
        type: ProfileSnackBarType.error,
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return false;
      if (permission == LocationPermission.denied) {
        showProfileSnackBar(
          context,
          message: l10n.locationPermissionDenied,
          type: ProfileSnackBarType.error,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      showProfileSnackBar(
        context,
        message: l10n.locationPermissionPermanentlyDenied,
        type: ProfileSnackBarType.error,
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (_isFetchingLocation) return;
    HapticFeedback.lightImpact();
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isFetchingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      _latitude = position.latitude;
      _longitude = position.longitude;

      await setLocaleIdentifier('en_US');
      final placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _country = place.country ?? l10n.unknown;
          _city =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              l10n.unknown;
        });

        HapticFeedback.mediumImpact();
        showProfileSnackBar(
          context,
          message: '${l10n.detected}: $_city, $_country',
          type: ProfileSnackBarType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showProfileSnackBar(
        context,
        message:
            '${l10n.failedToGetLocation}: ${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _saveHometown() async {
    if (_isSaving) return;
    if (_country == null || _city == null) return;
    final l10n = AppLocalizations.of(context)!;

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(authServiceProvider)
          .updateUserHometown(
            city: _city!,
            country: _country!,
            latitude: _latitude,
            longitude: _longitude,
          );

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: '${l10n.hometownSavedSuccessfully}: $_city, $_country',
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context, '$_city, $_country');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showProfileSnackBar(
        context,
        message:
            '${l10n.failedToSave}: ${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasLocation = _country != null && _city != null;
    final canSave = hasLocation && !_isSaving;

    return EditScreenScaffold(
      title: l10n.editHometown,
      canSave: canSave,
      isSaving: _isSaving,
      onSave: _saveHometown,
      showBottomSaveButton: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero location card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: hasLocation
                ? _buildLocationCard(l10n)
                : _buildEmptyStateCard(l10n),
          ),

          const SizedBox(height: 24),

          // Detect location button
          _buildDetectButton(l10n),

          const SizedBox(height: 28),

          // Info hint
          _buildPrivacyHint(l10n),

          const SizedBox(height: 28),

          // Save button
          GradientSaveButton(
            canSave: canSave,
            isSaving: _isSaving,
            onPressed: _saveHometown,
          ),
        ],
      ),
    );
  }

  // ========== HERO LOCATION CARD (when detected) ==========
  Widget _buildLocationCard(AppLocalizations l10n) {
    return Container(
      key: const ValueKey('location_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pulsing location icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.75),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.detected,
                      style: context.captionSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _city!,
                      style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _country!,
                      style: context.bodyMedium.copyWith(
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pin_drop_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                      style: context.captionSmall.copyWith(
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
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

  // ========== EMPTY STATE ==========
  Widget _buildEmptyStateCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const ValueKey('empty_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.5),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.containerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              color: context.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noLocationDetectedYet,
            style: context.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tapButtonToDetectLocation,
            style: context.captionSmall.copyWith(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (widget.currentAddress.isNotEmpty &&
              widget.currentAddress != "Not Set") ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.currentAddressLabel(widget.currentAddress),
                      style: context.captionSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ========== DETECT BUTTON ==========
  Widget _buildDetectButton(AppLocalizations l10n) {
    final isFetching = _isFetchingLocation;
    final disabled = isFetching || _isSaving;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _getCurrentLocation,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFetching) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.detecting,
                    style: context.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _country != null
                        ? l10n.updateLocationCta
                        : l10n.getCurrentLocation,
                    style: context.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== PRIVACY HINT ==========
  Widget _buildPrivacyHint(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.onlyCityCountryShown,
              style: context.captionSmall.copyWith(
                color: const Color(0xFF1976D2),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
