import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// A tappable language selector card (used for both native and learning language).
class FilterLanguageSelector extends StatelessWidget {
  final Language? selectedLanguage;
  final VoidCallback onTap;
  final IconData placeholderIcon;

  const FilterLanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onTap,
    this.placeholderIcon = Icons.public,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMD,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg, vertical: Spacing.lg),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            if (selectedLanguage != null)
              Padding(
                padding: const EdgeInsets.only(right: Spacing.md),
                child: Text(
                  selectedLanguage!.flag,
                  style: const TextStyle(fontSize: 28),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: Spacing.md),
                child: Icon(
                  placeholderIcon,
                  size: 28,
                  color: context.textMuted,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedLanguage?.name ??
                        AppLocalizations.of(context)!.anyLanguage,
                    style: context.titleMedium.copyWith(
                      color: selectedLanguage != null
                          ? context.textPrimary
                          : context.textSecondary,
                    ),
                  ),
                  if (selectedLanguage != null) ...[
                    Spacing.gapXXS,
                    Text(
                      selectedLanguage!.nativeName,
                      style: context.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder card while language list is fetching.
class FilterLanguageLoadingCard extends StatelessWidget {
  const FilterLanguageLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
          Spacing.hGapLG,
          Text(
            AppLocalizations.of(context)!.loadingLanguages,
            style: context.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Error card shown when the language list fetch fails.
class FilterLanguageErrorCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const FilterLanguageErrorCard({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          Spacing.hGapMD,
          Expanded(
            child: Text(
              errorMessage,
              style: context.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.error, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
