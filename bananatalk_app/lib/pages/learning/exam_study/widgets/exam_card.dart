import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// One exam in the picker list (IELTS / DELE / TOPIK). Shows the name in
/// bold, optional description below, and a meta strip with duration /
/// section count / max score.
class ExamCard extends StatelessWidget {
  const ExamCard({super.key, required this.exam, required this.onTap});

  final ExamType exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final metaChips = <Widget>[];
    if (exam.durationMinutes != null) {
      metaChips.add(_metaChip(
        context,
        Icons.schedule_rounded,
        l10n.examMetaDuration(exam.durationMinutes!),
      ));
    }
    if (exam.sections.isNotEmpty) {
      metaChips.add(_metaChip(
        context,
        Icons.list_alt_rounded,
        l10n.examMetaSections(exam.sections.length),
      ));
    }
    if (exam.maxScore != null) {
      metaChips.add(_metaChip(
        context,
        Icons.military_tech_rounded,
        l10n.examMetaMaxScore(_formatScore(exam.maxScore!)),
      ));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.dividerColor, width: 1),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (exam.description != null &&
                        exam.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        exam.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (metaChips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: metaChips),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: context.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// IELTS uses fractional band scores ("9.0"); TOEFL/TOPIK use ints.
  String _formatScore(num value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
