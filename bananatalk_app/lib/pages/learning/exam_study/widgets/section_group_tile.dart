import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Parent tile rendered on the exam dashboard for grouped sections —
/// e.g. "Writing" (Task 1 + Task 2) or "Speaking" (Part 1/2/3).
///
/// Visually mirrors [SectionTile] so the dashboard grid stays
/// uniform; tap drills into a sub-section picker.
class SectionGroupTile extends StatelessWidget {
  const SectionGroupTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.questionsDone,
    this.questionsTotal,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? questionsDone;
  final int? questionsTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final hasProgress = questionsDone != null &&
        questionsTotal != null &&
        questionsTotal! > 0;
    final progressLine = hasProgress
        ? l10n.examSectionProgress(questionsDone!, questionsTotal!)
        : subtitle;
    final progressFraction = hasProgress
        ? (questionsDone! / questionsTotal!).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerColor, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: context.primaryColor),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: context.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
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
                progressLine,
                style: TextStyle(
                  fontSize: 11,
                  color: hasProgress
                      ? context.primaryColor
                      : context.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 4,
                  backgroundColor: context.dividerColor,
                  valueColor: AlwaysStoppedAnimation(context.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
