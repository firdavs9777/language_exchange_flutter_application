import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// A mistake: what was written, the correction, and why. Got it counts up
/// to the server's three; Say it speaks the correction.
class MistakeRow extends StatelessWidget {
  const MistakeRow({
    super.key,
    required this.mistake,
    required this.busy,
    required this.onGotIt,
    required this.onSayIt,
  });

  final StudyMistakeItem mistake;
  final bool busy;
  final VoidCallback onGotIt;

  /// Null hides Say it (a mistake with no correction has nothing to say).
  final VoidCallback? onSayIt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = context.bodyMedium.copyWith(color: context.textMuted);
    final hasCorrection = mistake.corrected.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.myWordsYouWrote, style: label),
          Text(mistake.original, style: context.bodyMedium),
          if (hasCorrection) ...[
            const SizedBox(height: 8),
            Text(l10n.myWordsCorrection, style: label),
            Text(mistake.corrected, style: context.titleMedium),
          ],
          if (mistake.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              mistake.explanation,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: busy ? null : onGotIt,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(l10n.myWordsGotIt),
              ),
              if (mistake.successes > 0)
                Text(
                  l10n.myWordsGotItProgress(mistake.successes),
                  style: label,
                ),
              if (hasCorrection && onSayIt != null)
                TextButton(onPressed: onSayIt, child: Text(l10n.myWordsSayIt)),
            ],
          ),
        ],
      ),
    );
  }
}
