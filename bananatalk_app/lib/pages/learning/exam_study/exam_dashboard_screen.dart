import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/progress_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/section_practice_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/study_plan_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/section_tile.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_exam_progress.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exam-level dashboard: lists the sections, surfaces quick-action CTAs
/// for study plan / progress (wired in Chunks D & E), and is the entry
/// point into the section-practice screen (Chunk C).
class ExamDashboardScreen extends ConsumerWidget {
  const ExamDashboardScreen({super.key, required this.exam});

  final ExamType exam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sectionsAsync = ref.watch(sectionsForExamProvider(exam.id));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          exam.name,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sectionsForExamProvider(exam.id)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (exam.description != null && exam.description!.isNotEmpty) ...[
              Text(
                exam.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Quick actions row — non-functional in Chunk B, snackbar stubs
            // until Chunks D/E land. Visible now so the layout is final.
            _quickActionsRow(context, l10n),
            const SizedBox(height: 24),
            Text(
              l10n.examDashboardSections,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            sectionsAsync.when(
              data: (sections) => _buildSectionsGrid(context, sections, l10n),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _sectionsError(context, ref, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionsRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _actionPill(
            context,
            icon: Icons.play_circle_outline_rounded,
            label: l10n.examDashboardContinue,
            onTap: () => _openContinue(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionPill(
            context,
            icon: Icons.auto_awesome_rounded,
            label: l10n.examDashboardStartStudyPlan,
            onTap: () => _openStudyPlan(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionPill(
            context,
            icon: Icons.insights_rounded,
            label: l10n.examDashboardViewProgress,
            onTap: () => _openProgress(context),
          ),
        ),
      ],
    );
  }

  /// Resume practice on whichever section was attempted most recently.
  /// Falls back to the first section when there's no progress yet.
  Future<void> _openContinue(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    final sectionsAsync = container.read(sectionsForExamProvider(exam.id));
    final sections = sectionsAsync.valueOrNull ?? const [];
    if (sections.isEmpty) return;
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => SectionPracticeScreen(
          section: sections.first,
          examId: exam.id,
        ),
      ),
    );
  }

  void _openStudyPlan(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => StudyPlanScreen(exam: exam)),
    );
  }

  void _openProgress(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => ProgressScreen(exam: exam)),
    );
  }

  Widget _actionPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: context.primaryColor),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.primaryColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsGrid(
    BuildContext context,
    List<ExamSection> sections,
    AppLocalizations l10n,
  ) {
    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.examDashboardEmptySections,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return Consumer(
      builder: (context, ref, _) {
        // Pull progress (null when the user hasn't started this exam).
        final userId = ref.watch(authServiceProvider).userId;
        final progressAsync = userId.isNotEmpty
            ? ref.watch(
                userExamProgressProvider(
                  ProgressKey(userId: userId, examId: exam.id),
                ),
              )
            : const AsyncValue<UserExamProgress?>.data(null);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final section = sections[index];
            final progress = progressAsync.valueOrNull;
            final sectionScore = progress?.forSection(section.sectionType);
            return SectionTile(
              section: section,
              questionsDone: sectionScore?.attempted,
              questionsTotal: section.questionCount,
              onTap: () => _openPractice(context, ref, section),
            );
          },
        );
      },
    );
  }

  void _openPractice(
    BuildContext context,
    WidgetRef ref,
    ExamSection section,
  ) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => SectionPracticeScreen(
          section: section,
          examId: exam.id,
        ),
      ),
    ).then((_) {
      // Pull fresh progress when the user returns so the tile progress
      // bar reflects the questions they just answered.
      final userId = ref.read(authServiceProvider).userId;
      if (userId.isNotEmpty) {
        ref.invalidate(
          userExamProgressProvider(
            ProgressKey(userId: userId, examId: exam.id),
          ),
        );
      }
    });
  }

  Widget _sectionsError(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: context.textMuted),
          const SizedBox(height: 12),
          Text(
            l10n.examStudyError,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(sectionsForExamProvider(exam.id)),
            child: Text(l10n.examStudyRetry),
          ),
        ],
      ),
    );
  }

}
