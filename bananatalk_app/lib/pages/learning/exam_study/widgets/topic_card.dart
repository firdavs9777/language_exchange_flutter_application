import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// One tile in the topic picker grid. Special-cases the "All topics"
/// option with an accented background so it pops above the regular tiles.
class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.label,
    required this.questionCount,
    required this.onTap,
    this.isAllTopics = false,
  });

  final String label;
  final int questionCount;
  final VoidCallback onTap;
  final bool isAllTopics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = isAllTopics
        ? context.primaryColor.withValues(alpha: 0.12)
        : context.surfaceColor;
    final border = isAllTopics
        ? context.primaryColor.withValues(alpha: 0.4)
        : context.dividerColor;
    final iconColor = isAllTopics ? context.primaryColor : context.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: border,
              width: isAllTopics ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconFor(label, isAllTopics),
                color: iconColor,
                size: 26,
              ),
              const Spacer(),
              Text(
                isAllTopics ? l10n.examTopicAllTopics : label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                isAllTopics
                    ? l10n.examTopicAllTopicsDescription
                    : (questionCount == 1
                        ? l10n.examTopicOneQuestion
                        : l10n.examTopicQuestionCount(questionCount)),
                style: TextStyle(
                  fontSize: 11,
                  color: context.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Heuristic — map common topic strings to representative icons so the
  /// picker doesn't look uniform. Falls back to a generic tag.
  IconData _iconFor(String topicLabel, bool isAllTopics) {
    if (isAllTopics) return Icons.grid_view_rounded;
    final t = topicLabel.toLowerCase();
    if (t.contains('climate') || t.contains('environment')) {
      return Icons.eco_rounded;
    }
    if (t.contains('travel')) return Icons.flight_takeoff_rounded;
    if (t.contains('tech')) return Icons.devices_rounded;
    if (t.contains('education') || t.contains('school')) {
      return Icons.menu_book_rounded;
    }
    if (t.contains('health') || t.contains('food')) {
      return Icons.favorite_rounded;
    }
    if (t.contains('work') || t.contains('career')) {
      return Icons.work_rounded;
    }
    if (t.contains('culture') || t.contains('art')) {
      return Icons.palette_rounded;
    }
    return Icons.tag_rounded;
  }
}
