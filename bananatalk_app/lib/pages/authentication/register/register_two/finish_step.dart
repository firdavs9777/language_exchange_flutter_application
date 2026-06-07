import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Final step of the registration wizard: optional location detection,
/// terms acceptance, and the "Start Learning" CTA. Profile photo is
/// captured earlier by [ProfilePhotoStep].
class FinishStep extends StatelessWidget {
  // Location
  final String? city;
  final String? country;
  final bool isFetchingLocation;
  final VoidCallback onDetectLocation;
  final bool showLocationError;

  // Terms
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;

  // Submit
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const FinishStep({
    super.key,
    required this.city,
    required this.country,
    required this.isFetchingLocation,
    required this.onDetectLocation,
    this.showLocationError = false,
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

          const SizedBox(height: 28),

          _LocationSection(
            city: city,
            country: country,
            isFetchingLocation: isFetchingLocation,
            onDetectLocation: onDetectLocation,
            showError: showLocationError,
          ),

          if (showLocationError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                l10n.locationOptional,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
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

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Location section ────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final String? city;
  final String? country;
  final bool isFetchingLocation;
  final VoidCallback onDetectLocation;
  final bool showError;

  const _LocationSection({
    required this.city,
    required this.country,
    required this.isFetchingLocation,
    required this.onDetectLocation,
    this.showError = false,
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
          border: Border.all(
            color: showError ? Colors.red : context.dividerColor,
            width: showError ? 1.5 : 1,
          ),
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
