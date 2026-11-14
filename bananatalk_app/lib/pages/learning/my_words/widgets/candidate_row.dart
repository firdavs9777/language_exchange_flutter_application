import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// A word looked up in a chat: keep it, dismiss it, or hear it said.
/// Text wraps; nothing around it has a fixed height.
class CandidateRow extends StatelessWidget {
  const CandidateRow({
    super.key,
    required this.candidate,
    required this.busy,
    required this.onKeep,
    required this.onDismiss,
    required this.onSayIt,
  });

  final WordCandidate candidate;
  final bool busy;
  final VoidCallback onKeep, onDismiss, onSayIt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pos = candidate.partOfSpeech;
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
          Text(candidate.text, style: context.titleMedium),
          if (candidate.translation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              candidate.translation,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
          ],
          if (pos != null) ...[
            const SizedBox(height: 4),
            Text(
              pos,
              style: context.bodyMedium.copyWith(color: context.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: busy ? null : onKeep,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(l10n.myWordsKeep),
              ),
              TextButton(
                onPressed: busy ? null : onDismiss,
                child: Text(l10n.myWordsDismiss),
              ),
              TextButton(onPressed: onSayIt, child: Text(l10n.myWordsSayIt)),
            ],
          ),
        ],
      ),
    );
  }
}
