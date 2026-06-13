import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Inline "Translate this moment" pill — sits below a moment's caption,
/// color-matched to the translation panel that replaces it on tap. Sized
/// for an easy tap-target and uses an accent-tinted background so it
/// reads as a clear affordance rather than a passive label.
class MomentTranslateChip extends StatelessWidget {
  final VoidCallback onTap;
  const MomentTranslateChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    const accent = AppColors.primary;
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              l10n.translate,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
