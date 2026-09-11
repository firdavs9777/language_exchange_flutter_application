import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One multiple-choice check, used by every station so a question feels the
/// same wherever it came from. Replaces the list of RadioListTiles the old
/// daily-drop screen used.
///
/// Correctness is signalled by icon AND text, never by colour alone — a
/// colour-blind learner has to be able to tell a right answer from a wrong one.
class CheckQuestion extends StatelessWidget {
  final PackCheck check;
  final int index;
  final int? selected;
  final int? correctIndex;
  final String? explanation;
  final ValueChanged<int> onSelect;

  const CheckQuestion({
    super.key,
    required this.check,
    required this.index,
    required this.onSelect,
    this.selected,
    this.correctIndex,
    this.explanation,
  });

  bool get _answered => correctIndex != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(check.prompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...List.generate(check.options.length, (o) {
          final isCorrect = _answered && o == correctIndex;
          final isWrongPick = _answered && o == selected && o != correctIndex;
          final isPicked = selected == o;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: Key('check-q$index-opt$o'),
              borderRadius: BorderRadius.circular(12),
              onTap: _answered ? null : () => onSelect(o),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? theme.colorScheme.primary
                        : isWrongPick
                            ? theme.colorScheme.error
                            : (isPicked ? theme.colorScheme.primary : context.dividerColor),
                    width: (isCorrect || isWrongPick || isPicked) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(check.options[o], style: theme.textTheme.bodyLarge),
                    ),
                    if (isCorrect)
                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    if (isWrongPick)
                      Icon(Icons.cancel, color: theme.colorScheme.error, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_answered && (explanation ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              explanation!,
              key: Key('check-q$index-explanation'),
              style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
            ),
          ),
      ],
    );
  }
}
