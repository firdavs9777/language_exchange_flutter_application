import 'package:flutter/material.dart';

import '../../utils/theme_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Inline grammar card the tutor drops into chat when explaining a
/// rule. Pure stateless display — variable-length examples list, each
/// row optionally showing a correct/wrong/note breakdown.
class GrammarCard extends StatelessWidget {
  final Map<String, dynamic> payload;
  const GrammarCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final rule = payload['rule']?.toString() ?? '';
    final explanation = payload['explanation']?.toString() ?? '';
    final examples = (payload['examples'] as List?) ?? const [];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 16, color: Colors.purple),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.aiTutorCardGrammar,
                  style: context.bodySmall.copyWith(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(rule,
                style: context.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(explanation,
                style: context.bodyMedium.copyWith(color: context.textSecondary)),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final ex in examples)
                if (ex is Map) _ExampleRow(example: ex.cast<String, dynamic>()),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final Map<String, dynamic> example;
  const _ExampleRow({required this.example});

  @override
  Widget build(BuildContext context) {
    final correct = example['correct']?.toString();
    final wrong = example['wrong']?.toString();
    final note = example['note']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (correct != null && correct.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(child: Text(correct, style: context.bodySmall)),
              ],
            ),
          if (wrong != null && wrong.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.close, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    wrong,
                    style: context.bodySmall.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: context.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(
                note,
                style: context.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
