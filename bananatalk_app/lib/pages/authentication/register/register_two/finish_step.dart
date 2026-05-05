import 'dart:io';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Final step of the registration wizard: profile photo upload, optional
/// location detection, terms acceptance, and the "Start Learning" CTA.
///
/// All state (images list, termsAccepted, location data, submitting flag)
/// lives in the parent [_RegisterTwoState]. This widget is purely
/// presentational; mutations happen through callbacks.
class FinishStep extends StatelessWidget {
  // Photos
  final List<File> selectedImages;
  final bool showPhotoError;
  final VoidCallback onPickImage;
  final void Function(int index) onRemoveImage;

  // Location
  final String? city;
  final String? country;
  final bool isFetchingLocation;
  final VoidCallback onDetectLocation;

  // Terms
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;

  // Submit
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const FinishStep({
    super.key,
    required this.selectedImages,
    required this.showPhotoError,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.city,
    required this.country,
    required this.isFetchingLocation,
    required this.onDetectLocation,
    required this.termsAccepted,
    required this.onTermsChanged,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Text(
            l10n.almostDone,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.addPhotoLocationForMatches,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
          ),

          const SizedBox(height: 28),

          _PhotoSection(
            selectedImages: selectedImages,
            showPhotoError: showPhotoError,
            onPickImage: onPickImage,
            onRemoveImage: onRemoveImage,
          ),

          const SizedBox(height: 20),

          _LocationSection(
            city: city,
            country: country,
            isFetchingLocation: isFetchingLocation,
            onDetectLocation: onDetectLocation,
          ),

          const SizedBox(height: 24),

          _TermsCheckbox(
            termsAccepted: termsAccepted,
            onChanged: onTermsChanged,
          ),

          const SizedBox(height: 24),

          AuthGradientButton(
            label: l10n.startLearning,
            onPressed: isSubmitting ? null : onSubmit,
            isLoading: isSubmitting,
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              l10n.locationOptional,
              style: TextStyle(fontSize: 12, color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Photo section ──────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  final List<File> selectedImages;
  final bool showPhotoError;
  final VoidCallback onPickImage;
  final void Function(int index) onRemoveImage;

  const _PhotoSection({
    required this.selectedImages,
    required this.showPhotoError,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (selectedImages.isEmpty) {
      return GestureDetector(
        onTap: onPickImage,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: showPhotoError
                ? AppColors.error.withValues(alpha: 0.05)
                : context.cardBackground,
            borderRadius: AppRadius.borderLG,
            border: Border.all(
              color: showPhotoError ? AppColors.error : context.dividerColor,
              width: showPhotoError ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderMD,
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    size: 26, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.addProfilePhoto,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.requiredUpTo6Photos,
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedImages.length +
                (selectedImages.length < 6 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < selectedImages.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.borderMD,
                        child: Image.file(
                          selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: AppRadius.borderMD,
                      border: Border.all(color: context.dividerColor),
                    ),
                    child:
                        Icon(Icons.add, size: 28, color: context.iconColor),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─── Location section ────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final String? city;
  final String? country;
  final bool isFetchingLocation;
  final VoidCallback onDetectLocation;

  const _LocationSection({
    required this.city,
    required this.country,
    required this.isFetchingLocation,
    required this.onDetectLocation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: isFetchingLocation ? null : onDetectLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: city != null
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : context.containerColor,
                borderRadius: AppRadius.borderMD,
              ),
              child: isFetchingLocation
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      city != null
                          ? Icons.location_on
                          : Icons.location_off_outlined,
                      color: city != null
                          ? AppColors.primary
                          : context.iconColor,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city != null && country != null
                        ? '$city, $country'
                        : l10n.tapToDetectLocation,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: city != null
                          ? context.textPrimary
                          : context.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.optionalHelpsNearbyPartners,
                    style: TextStyle(fontSize: 12, color: context.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.gps_fixed, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Terms checkbox ──────────────────────────────────────────────────────────

class _TermsCheckbox extends StatelessWidget {
  final bool termsAccepted;
  final ValueChanged<bool> onChanged;

  const _TermsCheckbox({
    required this.termsAccepted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => onChanged(!termsAccepted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: termsAccepted
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: termsAccepted
                ? AppColors.primary.withValues(alpha: 0.3)
                : context.dividerColor,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: termsAccepted,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const TermsOfServiceScreen(isPreRegistration: true),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textPrimary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: l10n.iAgreeToThe),
                      TextSpan(
                        text: l10n.termsOfService,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
