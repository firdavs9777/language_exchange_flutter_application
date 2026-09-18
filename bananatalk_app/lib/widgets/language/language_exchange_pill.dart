import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/language_codes.dart';

/// Dots to fill for a CEFR level, or null when we do not know the level.
///
/// Null is not zero. A profile with no level renders NO dots rather than three
/// empty ones, because an empty indicator reads as "beginner" -- a claim the
/// data has not made. The moments header shipped the opposite mistake: five
/// dots generated with a hardcoded `index < 3`, identical for a beginner and a
/// C2 speaker, on every card in the feed.
int? dotsForLevel(String? level) {
  switch (level?.trim().toUpperCase()) {
    case 'A1':
    case 'A2':
      return 1;
    case 'B1':
    case 'B2':
      return 2;
    case 'C1':
    case 'C2':
      return 3;
    default:
      return null;
  }
}

/// `KO ●●● ⇄ EN ●○○` — the single most important fact on a partner row or a
/// moment card, in one teal pill.
///
/// Lives in lib/widgets/ because both the community partner row and
/// MomentCardHeader render it. Before this, each screen had its own
/// implementation: the partner card used two neutral grey chips that said
/// nothing about proficiency, and the moments header used a green underline
/// plus five dots that were the same for everybody.
class LanguageExchangePill extends StatelessWidget {
  const LanguageExchangePill({
    super.key,
    required this.nativeLanguage,
    required this.learningLanguage,
    this.languageLevel,
    this.dense = false,
  });

  final String nativeLanguage;
  final String learningLanguage;

  /// The candidate's CEFR level in [learningLanguage]. Null renders no dots.
  final String? languageLevel;

  /// Smaller type and tighter padding, for the moment card header.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fontSize = dense ? 10.0 : 11.0;
    final filled = dotsForLevel(languageLevel);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 9,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: AppRadius.borderRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _code(LanguageCodes.displayCode(nativeLanguage), fontSize),
          // The native side is always full: it is their own language.
          _dots(3, fontSize),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(
              Icons.swap_horiz_rounded,
              size: fontSize + 2,
              color: AppColors.primary,
            ),
          ),
          _code(LanguageCodes.displayCode(learningLanguage), fontSize),
          if (filled != null) _dots(filled, fontSize),
        ],
      ),
    );
  }

  Widget _code(String code, double fontSize) => Text(
        code,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
        ),
      );

  Widget _dots(int filled, double fontSize) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.only(left: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.28),
              ),
            );
          }),
        ),
      );
}
