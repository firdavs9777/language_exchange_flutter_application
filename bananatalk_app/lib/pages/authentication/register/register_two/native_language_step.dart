import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step where the user picks their native language and optionally their
/// proficiency level in it.
///
/// All state lives in the parent [_RegisterTwoState]. This widget
/// receives the current selection and callbacks via constructor.
class NativeLanguageStep extends StatelessWidget {
  final Language? selectedLanguage;
  final String? selectedLevel;
  final bool isLoadingLanguages;
  final VoidCallback onOpenPicker;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onNext;

  const NativeLanguageStep({
    super.key,
    required this.selectedLanguage,
    required this.selectedLevel,
    required this.isLoadingLanguages,
    required this.onOpenPicker,
    required this.onLevelChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _LanguageStepBody(
      title: l10n.whatsYourNativeLanguage,
      subtitle: l10n.helpsMatchWithLearners,
      selectedLanguage: selectedLanguage,
      selectedLevel: selectedLevel,
      isNative: true,
      isLoadingLanguages: isLoadingLanguages,
      onOpenPicker: onOpenPicker,
      onLevelChanged: onLevelChanged,
      onNext: onNext,
    );
  }
}

/// Step where the user picks the language they are learning and their
/// current proficiency level (required before advancing).
///
/// The parent enforces that the chosen language differs from the native
/// language before calling [onOpenPicker].
class LearningLanguageStep extends StatelessWidget {
  final Language? selectedLanguage;
  final String? selectedLevel;
  final bool isLoadingLanguages;
  final VoidCallback onOpenPicker;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onNext;

  const LearningLanguageStep({
    super.key,
    required this.selectedLanguage,
    required this.selectedLevel,
    required this.isLoadingLanguages,
    required this.onOpenPicker,
    required this.onLevelChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _LanguageStepBody(
      title: l10n.whatAreYouLearning,
      subtitle: l10n.connectWithNativeSpeakers,
      selectedLanguage: selectedLanguage,
      selectedLevel: selectedLevel,
      isNative: false,
      isLoadingLanguages: isLoadingLanguages,
      onOpenPicker: onOpenPicker,
      onLevelChanged: onLevelChanged,
      onNext: onNext,
    );
  }
}

// ─── Shared body ────────────────────────────────────────────────────────────

const List<String> _cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

class _LanguageStepBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Language? selectedLanguage;
  final String? selectedLevel;
  final bool isNative;
  final bool isLoadingLanguages;
  final VoidCallback onOpenPicker;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onNext;

  const _LanguageStepBody({
    required this.title,
    required this.subtitle,
    required this.selectedLanguage,
    required this.selectedLevel,
    required this.isNative,
    required this.isLoadingLanguages,
    required this.onOpenPicker,
    required this.onLevelChanged,
    required this.onNext,
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
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
          ),

          const SizedBox(height: 32),

          _LanguageCard(
            selectedLanguage: selectedLanguage,
            isLoadingLanguages: isLoadingLanguages,
            onTap: onOpenPicker,
          ),

          if (selectedLanguage != null) ...[
            const SizedBox(height: 28),
            Text(
              isNative
                  ? l10n.yourLevelIn(selectedLanguage!.name)
                  : l10n.yourCurrentLevel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._cefrLevels.map(
              (level) => _LevelTile(
                level: level,
                isSelected: selectedLevel == level,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onLevelChanged(level);
                },
              ),
            ),
          ],

          const SizedBox(height: 32),

          AuthGradientButton(
            label: l10n.continueButton,
            onPressed: onNext,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Language? selectedLanguage;
  final bool isLoadingLanguages;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.selectedLanguage,
    required this.isLoadingLanguages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoadingLanguages ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selectedLanguage != null
              ? AppColors.primary.withValues(alpha: 0.06)
              : context.cardBackground,
          borderRadius: AppRadius.borderLG,
          border: Border.all(
            color: selectedLanguage != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : context.dividerColor,
            width: selectedLanguage != null ? 2 : 1,
          ),
        ),
        child: isLoadingLanguages
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  if (selectedLanguage != null) ...[
                    Text(selectedLanguage!.flag,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLanguage!.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedLanguage!.nativeName,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: AppRadius.borderMD,
                      ),
                      child: Icon(Icons.language,
                          size: 28, color: context.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.tapToSelectLanguage,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  Icon(Icons.chevron_right, color: context.textSecondary),
                ],
              ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  String _description(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case 'A1':
        return l10n.beginner;
      case 'A2':
        return l10n.elementary;
      case 'B1':
        return l10n.intermediate;
      case 'B2':
        return l10n.upperIntermediate;
      case 'C1':
        return l10n.advanced;
      case 'C2':
        return l10n.proficient;
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : context.cardBackground,
            borderRadius: AppRadius.borderMD,
            border: Border.all(
              color: isSelected ? AppColors.primary : context.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : context.containerColor,
                  borderRadius: AppRadius.borderSM,
                ),
                alignment: Alignment.center,
                child: Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isSelected ? Colors.white : context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _description(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
