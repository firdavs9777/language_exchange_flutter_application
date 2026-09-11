import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One skill's progress: a bar plus the counts behind it. The caption carries
/// the real numbers, because a bar alone cannot be read precisely.
class MasteryBar extends StatelessWidget {
  final String label;
  final String caption;
  final double? fraction;
  final String? emptyLabel;

  const MasteryBar({
    super.key,
    required this.label,
    required this.caption,
    this.fraction,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notStarted = fraction == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: notStarted ? 0 : fraction!.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: context.dividerColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notStarted ? (emptyLabel ?? caption) : caption,
            style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
