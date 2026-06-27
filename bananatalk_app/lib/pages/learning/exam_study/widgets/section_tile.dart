import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Section tile in the exam dashboard grid. Chunk B renders it with a
/// "Not started" subtitle — Chunk C swaps in real progress numbers via the
/// userExamProgressProvider.
class SectionTile extends StatelessWidget {
  const SectionTile({
    super.key,
    required this.section,
    required this.onTap,
    this.questionsDone,
    this.questionsTotal,
  });

  final ExamSection section;
  final VoidCallback onTap;
  final int? questionsDone;
  final int? questionsTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final hasProgress = questionsDone != null &&
        questionsTotal != null &&
        questionsTotal! > 0;
    final subtitle = hasProgress
        ? l10n.examSectionProgress(questionsDone!, questionsTotal!)
        : l10n.examSectionNotStarted;
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
              _sectionIcon(context, section.sectionType),
              const SizedBox(height: 12),
              Text(
                section.sectionName,
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
                subtitle,
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

  /// Pick an icon based on the section type. Falls back to a generic
  /// "assignment" glyph for anything unrecognized (forward-compat).
  Widget _sectionIcon(BuildContext context, String sectionType) {
    final iconData = switch (sectionType) {
      'reading' => Icons.menu_book_rounded,
      // Plain `writing` is the legacy single-section value; new content
      // splits into writing-task-1 (short response / letter) and
      // writing-task-2 (long-form essay).
      'writing' => Icons.edit_note_rounded,
      'writing-task-1' => Icons.draw_rounded,
      'writing-task-2' => Icons.article_rounded,
      'speaking' => Icons.mic_rounded,
      'listening' => Icons.headphones_rounded,
      'vocabulary' => Icons.spellcheck_rounded,
      _ => Icons.assignment_rounded,
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, size: 20, color: context.primaryColor),
    );
  }
}
