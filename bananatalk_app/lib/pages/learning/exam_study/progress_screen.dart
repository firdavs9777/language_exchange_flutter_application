import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_exam_progress.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-section progress dashboard. Surfaces the overall score, every
/// section's score/attempts, and a chip strip of weak areas (sections
/// the user hasn't started OR scoring under 70%).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.exam});

  final ExamType exam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(authServiceProvider).userId;
    final progressAsync = userId.isEmpty
        ? const AsyncValue<UserExamProgress?>.data(null)
        : ref.watch(
            userExamProgressProvider(
              ProgressKey(userId: userId, examId: exam.id),
            ),
          );
    final sectionsAsync = ref.watch(sectionsForExamProvider(exam.id));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examProgressTitle,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userId.isNotEmpty) {
            ref.invalidate(
              userExamProgressProvider(
                ProgressKey(userId: userId, examId: exam.id),
              ),
            );
          }
        },
        child: progressAsync.when(
          data: (progress) => sectionsAsync.when(
            data: (sections) =>
                _buildBody(context, l10n, progress, sections),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _errorState(context, l10n, () {
              ref.invalidate(sectionsForExamProvider(exam.id));
            }),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _errorState(context, l10n, () {
            if (userId.isNotEmpty) {
              ref.invalidate(
                userExamProgressProvider(
                  ProgressKey(userId: userId, examId: exam.id),
                ),
              );
            }
          }),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    UserExamProgress? progress,
    List<ExamSection> sections,
  ) {
    final hasStarted =
        progress != null && progress.questionsAttempted > 0;
    if (!hasStarted) {
      return _notStartedState(context, l10n);
    }

    final weakAreas = sections
        .where((s) {
          final score = progress.forSection(s.sectionType);
          return score.attempted == 0 ||
              (score.score != null && score.score! < 70);
        })
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _overallScoreCard(context, l10n, progress),
        const SizedBox(height: 20),
        _focusAreas(context, l10n, weakAreas),
        const SizedBox(height: 24),
        for (final section in sections) ...[
          _sectionRow(context, l10n, section, progress.forSection(section.sectionType)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _overallScoreCard(
    BuildContext context,
    AppLocalizations l10n,
    UserExamProgress progress,
  ) {
    final score = progress.overallScore ?? 0;
    final accent = score >= 75
        ? const Color(0xFF22C55E)
        : score >= 50
            ? const Color(0xFFFFA000)
            : context.primaryColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.examProgressOverall,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progress.overallScore == null ? '–' : '$score / 100',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.insights_rounded, color: accent, size: 52),
        ],
      ),
    );
  }

  Widget _focusAreas(
    BuildContext context,
    AppLocalizations l10n,
    List<ExamSection> weak,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.examProgressFocusAreas,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        if (weak.isEmpty)
          Text(
            l10n.examProgressNoFocusAreas,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              height: 1.4,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in weak)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFFA000).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.sectionName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFA000),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _sectionRow(
    BuildContext context,
    AppLocalizations l10n,
    ExamSection section,
    SectionScore score,
  ) {
    final pct = score.score;
    final attempted = score.attempted;
    final fraction = (section.questionCount > 0)
        ? (attempted / section.questionCount).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.sectionName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Text(
                pct == null ? '–' : '$pct%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: pct == null
                      ? context.textMuted
                      : context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.examProgressSectionAttempts(attempted, section.questionCount),
            style: TextStyle(
              fontSize: 12,
              color: context.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: context.dividerColor,
              valueColor: AlwaysStoppedAnimation(context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notStartedState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, size: 48, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.examProgressNotStartedTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.examProgressNotStartedBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(
    BuildContext context,
    AppLocalizations l10n,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.examStudyError,
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.examStudyRetry),
            ),
          ],
        ),
      ),
    );
  }
}
