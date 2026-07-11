import 'dart:io';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/terms_of_service_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Final step of the registration wizard: a summary card of everything the
/// wizard collected (with per-row edit shortcuts back to the owning step),
/// optional location detection, terms acceptance, and the "Start Learning"
/// CTA.
class FinishStep extends StatefulWidget {
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

  // ─── Summary (all optional — omitting them just hides the card) ─────────
  final String? summaryName;
  final String? summaryGender;
  final String? summaryBirthDate;
  final String? summaryNativeLanguage;
  final String? summaryLearningLanguage;
  final File? summaryPhoto;

  /// Called with the 0-indexed sub-step to jump back to when a summary row's
  /// edit shortcut is tapped. The parent owns the actual page index mapping.
  final ValueChanged<int>? onEditStep;

  /// Step indices for each editable field, as computed by the parent from
  /// its current `_computeSteps()` output. Null when that field isn't part
  /// of this run's steps (e.g. languages already set for a returning OAuth
  /// user) — in that case the row is still shown (read-only) but has no
  /// edit affordance.
  final int? personalInfoStepIndex;
  final int? photoStepIndex;
  final int? languageStepIndex;

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
    this.summaryName,
    this.summaryGender,
    this.summaryBirthDate,
    this.summaryNativeLanguage,
    this.summaryLearningLanguage,
    this.summaryPhoto,
    this.onEditStep,
    this.personalInfoStepIndex,
    this.photoStepIndex,
    this.languageStepIndex,
  });

  @override
  State<FinishStep> createState() => _FinishStepState();
}

class _FinishStepState extends State<FinishStep> {
  bool _hasCelebrated = false;

  // Fires a scale-in pulse + medium haptic the instant the user taps
  // "Start learning", so the tap reads as an immediate, tactile confirmation
  // rather than waiting on the network round-trip (submit is async and, on
  // success, navigates away entirely — there's no reliable "success" state
  // to observe locally in this widget once that happens). On failure the
  // parent's error snackbar still surfaces normally; this is purely a
  // delight touch on the button itself, not a correctness signal.
  void _celebrate() {
    if (_hasCelebrated) return;
    _hasCelebrated = true;
    HapticFeedback.mediumImpact();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _hasCelebrated = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasSummary = widget.summaryName != null ||
        widget.summaryGender != null ||
        widget.summaryBirthDate != null ||
        widget.summaryNativeLanguage != null ||
        widget.summaryLearningLanguage != null ||
        widget.summaryPhoto != null;

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

          const SizedBox(height: 24),

          if (hasSummary) ...[
            _SummaryCard(
              name: widget.summaryName,
              gender: widget.summaryGender,
              birthDate: widget.summaryBirthDate,
              nativeLanguage: widget.summaryNativeLanguage,
              learningLanguage: widget.summaryLearningLanguage,
              photo: widget.summaryPhoto,
              onEditPersonalInfo: widget.personalInfoStepIndex != null
                  ? () => widget.onEditStep?.call(widget.personalInfoStepIndex!)
                  : null,
              onEditPhoto: widget.photoStepIndex != null
                  ? () => widget.onEditStep?.call(widget.photoStepIndex!)
                  : null,
              onEditLanguages: widget.languageStepIndex != null
                  ? () => widget.onEditStep?.call(widget.languageStepIndex!)
                  : null,
            ),
            const SizedBox(height: 24),
          ],

          _LocationSection(
            city: widget.city,
            country: widget.country,
            isFetchingLocation: widget.isFetchingLocation,
            onDetectLocation: widget.onDetectLocation,
            showError: widget.showLocationError,
          ),

          if (widget.showLocationError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                l10n.locationOptional,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),

          const SizedBox(height: 24),

          _TermsCheckbox(
            termsAccepted: widget.termsAccepted,
            onChanged: widget.onTermsChanged,
          ),

          const SizedBox(height: 24),

          AnimatedScale(
            scale: _hasCelebrated ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AuthGradientButton(
              label: l10n.startLearning,
              icon: _hasCelebrated ? Icons.check_circle_rounded : null,
              onPressed: widget.isSubmitting
                  ? null
                  : () {
                      _celebrate();
                      widget.onSubmit();
                    },
              isLoading: widget.isSubmitting,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Summary card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String? name;
  final String? gender;
  final String? birthDate;
  final String? nativeLanguage;
  final String? learningLanguage;
  final File? photo;
  final VoidCallback? onEditPersonalInfo;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onEditLanguages;

  const _SummaryCard({
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.nativeLanguage,
    required this.learningLanguage,
    required this.photo,
    required this.onEditPersonalInfo,
    required this.onEditPhoto,
    required this.onEditLanguages,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final personalInfoValue = [
      if (gender != null && gender!.isNotEmpty) gender,
      if (birthDate != null && birthDate!.isNotEmpty) birthDate,
    ].join(' · ');
    final languagesValue = (nativeLanguage != null && nativeLanguage!.isNotEmpty) ||
            (learningLanguage != null && learningLanguage!.isNotEmpty)
        ? '${nativeLanguage ?? '—'} → ${learningLanguage ?? '—'}'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          if (photo != null || (name != null && name!.isNotEmpty))
            _SummaryRow(
              icon: Icons.person_rounded,
              label: l10n.tellUsAboutYourself,
              value: name,
              leadingAvatar: photo,
              onEdit: onEditPhoto,
              isFirst: true,
            ),
          if (personalInfoValue.isNotEmpty)
            _SummaryRow(
              icon: Icons.cake_outlined,
              label: l10n.birthDate,
              value: personalInfoValue,
              onEdit: onEditPersonalInfo,
            ),
          if (languagesValue != null)
            _SummaryRow(
              icon: Icons.language_rounded,
              label: l10n.whatAreYouLearning,
              value: languagesValue,
              onEdit: onEditLanguages,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final File? leadingAvatar;
  final VoidCallback? onEdit;
  final bool isFirst;
  final bool isLast;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.leadingAvatar,
    required this.onEdit,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          if (leadingAvatar != null)
            ClipOval(
              child: CircleAvatar(
                radius: 18,
                backgroundImage: FileImage(leadingAvatar!),
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderMD,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  (value == null || value!.isEmpty) ? '—' : value!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  AppLocalizations.of(context)!.edit,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
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
