import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/study_plan_setup_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/milestone_tile.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_study_plan.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vertical milestone timeline + suggested daily lessons.
///
/// Two entry paths:
/// - From the dashboard CTA: provider fetches the active plan; if none
///   exists (404 → null), we push the setup screen instead.
/// - From StudyPlanSetupScreen.pushReplacement: [initialPlan] is the
///   freshly-generated plan and we use it directly to avoid an extra
///   round-trip.
class StudyPlanScreen extends ConsumerWidget {
  const StudyPlanScreen({super.key, required this.exam, this.initialPlan});

  final ExamType exam;
  final UserStudyPlan? initialPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(authServiceProvider).userId;

    if (initialPlan != null) {
      return _scaffoldFor(context, l10n, ref, initialPlan!, userId);
    }

    if (userId.isEmpty) {
      return _emptyScaffold(context, l10n);
    }

    final planAsync = ref.watch(
      userStudyPlanProvider(ProgressKey(userId: userId, examId: exam.id)),
    );

    return planAsync.when(
      data: (plan) {
        if (plan == null) {
          return _emptyScaffold(context, l10n);
        }
        return _scaffoldFor(context, l10n, ref, plan, userId);
      },
      loading: () => Scaffold(
        backgroundColor: context.scaffoldBackground,
        appBar: _appBar(context, l10n),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: context.scaffoldBackground,
        appBar: _appBar(context, l10n),
        body: _errorBody(context, l10n, () {
          ref.invalidate(userStudyPlanProvider(
            ProgressKey(userId: userId, examId: exam.id),
          ));
        }),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, AppLocalizations l10n) {
    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      title: Text(
        l10n.examPlanTitle,
        style: TextStyle(
          color: context.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _scaffoldFor(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    UserStudyPlan plan,
    String userId,
  ) {
    final totalHours = plan.milestones.fold<num>(
      0,
      (sum, m) => sum + m.estimatedHours,
    );
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: _appBar(context, l10n),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userStudyPlanProvider(
            ProgressKey(userId: userId, examId: exam.id),
          ));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _headerCard(context, l10n, plan, totalHours),
            const SizedBox(height: 20),
            for (int i = 0; i < plan.milestones.length; i++)
              MilestoneTile(
                milestone: plan.milestones[i],
                showConnector: i != plan.milestones.length - 1,
              ),
            if (plan.dailyLessons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.examPlanDailyHeading,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              // Show first 10 lessons inline; the rest land in a future
              // "All lessons" screen if we want to expand. Keep MVP tight.
              for (final lesson in plan.dailyLessons.take(10))
                _dailyLessonRow(context, l10n, lesson),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                AppPageRoute(
                  builder: (_) => StudyPlanSetupScreen(exam: exam),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.examPlanRegenerate),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primaryColor,
                side: BorderSide(color: context.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(
    BuildContext context,
    AppLocalizations l10n,
    UserStudyPlan plan,
    num totalHours,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.15),
            context.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.examPlanTotalHours(totalHours.toInt()),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (plan.targetScore != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.examPlanTargetScore}: ${plan.targetScore}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyLessonRow(
    BuildContext context,
    AppLocalizations l10n,
    DailyLesson lesson,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              '${_formatDate(lesson.date)} · ${lesson.topic ?? lesson.section ?? ''}',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            l10n.examPlanLessonMinutes(lesson.estimatedMinutes.toInt()),
            style: TextStyle(
              fontSize: 11,
              color: context.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: _appBar(context, l10n),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: context.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.examPlanEmptyTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.examPlanEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  AppPageRoute(
                    builder: (_) => StudyPlanSetupScreen(exam: exam),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.examPlanGenerate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBody(
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

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m/$day';
  }
}
