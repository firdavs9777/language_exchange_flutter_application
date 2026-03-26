import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileHometownEdit extends ConsumerStatefulWidget {
  const ProfileHometownEdit({Key? key, required String currentAddress})
      : super(key: key);

  @override
  ConsumerState<ProfileHometownEdit> createState() =>
      _ProfileHometownEditState();
}

class _ProfileHometownEditState extends ConsumerState<ProfileHometownEdit> {
  bool isFetchingLocation = false;
  bool isSaving = false;
  String? country;
  String? city;
  double? latitude;
  double? longitude;

  // Check location permission
  Future<bool> _handleLocationPermission() async {
    final l10n = AppLocalizations.of(context)!;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.locationServicesDisabled),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.locationPermissionDenied),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.locationPermissionPermanentlyDenied),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return false;
    }

    return true;
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() {
      isFetchingLocation = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      await setLocaleIdentifier('en_US');
      final placemarks = await placemarkFromCoordinates(
        latitude!,
        longitude!,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          country = place.country ?? l10n.unknown;
          city = place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              l10n.unknown;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.detected}: $city, $country'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.failedToGetLocation}: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() {
        isFetchingLocation = false;
      });
    }
  }

  Future<void> saveHometown() async {
    final l10n = AppLocalizations.of(context)!;
    if (country == null || city == null) return;

    setState(() => isSaving = true);
    try {
      await ref.read(authServiceProvider).updateUserHometown(
            city: city!,
            country: country!,
            latitude: latitude,
            longitude: longitude,
          );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.savedHometown}: $city, $country'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));

      Navigator.pop(context, '$city, $country');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.failedToSave}: $error'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          l10n.editHometown,
          style: context.titleLarge,
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: Spacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.useCurrentLocation,
              style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            Spacing.gapLG,

            OutlinedButton.icon(
              onPressed: isFetchingLocation ? null : getCurrentLocation,
              icon: isFetchingLocation
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.primaryColor,
                        ),
                      ),
                    )
                  : Icon(Icons.my_location, color: context.primaryColor),
              label: Text(
                isFetchingLocation ? l10n.detecting : l10n.getCurrentLocation,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
                side: BorderSide(color: context.primaryColor),
              ),
            ),

            Spacing.gapXL,
            Divider(color: context.dividerColor),
            Spacing.gapLG,

            // Display results
            if (country != null || city != null) ...[
              Container(
                padding: Spacing.paddingLG,
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: AppRadius.borderMD,
                  border: Border.all(color: context.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag_outlined, color: context.textSecondary, size: 20),
                        Spacing.hGapSM,
                        Text(
                          '${l10n.country}: ${country ?? '-'}',
                          style: context.bodyLarge,
                        ),
                      ],
                    ),
                    Spacing.gapSM,
                    Row(
                      children: [
                        Icon(Icons.location_city_outlined, color: context.textSecondary, size: 20),
                        Spacing.hGapSM,
                        Text(
                          '${l10n.city}: ${city ?? '-'}',
                          style: context.bodyLarge,
                        ),
                      ],
                    ),
                    if (latitude != null && longitude != null) ...[
                      Spacing.gapSM,
                      Row(
                        children: [
                          Icon(Icons.pin_drop_outlined, color: context.textSecondary, size: 20),
                          Spacing.hGapSM,
                          Expanded(
                            child: Text(
                              '${l10n.coordinates}: ${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                              style: context.bodySmall.copyWith(color: context.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              Container(
                padding: Spacing.paddingLG,
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: AppRadius.borderMD,
                  border: Border.all(color: context.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: context.textMuted, size: 20),
                    Spacing.hGapSM,
                    Text(
                      l10n.noLocationDetectedYet,
                      style: context.bodyMedium.copyWith(color: context.textMuted),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: (country != null && city != null && !isSaving)
                  ? saveHometown
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.gray900,
                disabledBackgroundColor: context.containerHighColor,
                disabledForegroundColor: context.textMuted,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gray900),
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: context.titleMedium.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
            ),
            Spacing.gapLG,
          ],
        ),
      ),
    );
  }
}
