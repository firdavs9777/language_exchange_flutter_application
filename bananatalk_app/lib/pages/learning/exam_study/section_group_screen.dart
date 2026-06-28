import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/topic_picker_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/section_tile.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_exam_progress.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drill-down screen: from a grouped dashboard tile (Writing / Speaking)
/// the user picks one sub-section here (Task 1 / Task 2 — or Part 1/2/3),
/// then continues into the existing topic picker → practice flow.
class SectionGroupScreen extends ConsumerWidget {
  const SectionGroupScreen({
    super.key,
    required this.examId,
    required this.groupTitle,
    required this.subSections,
  });

  final String examId;
  final String groupTitle;
  final List<ExamSection> subSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final userId = ref.watch(authServiceProvider).userId;
    final progressAsync = userId.isNotEmpty
        ? ref.watch(
            userExamProgressProvider(
              ProgressKey(userId: userId, examId: examId),
            ),
          )
        : const AsyncValue<UserExamProgress?>.data(null);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          groupTitle,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: subSections.isEmpty
          ? Center(
              child: Text(
                l10n.examDashboardEmptySections,
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: subSections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final section = subSections[index];
                final progress = progressAsync.valueOrNull;
                final score = progress?.forSection(section.sectionType);
                return SizedBox(
                  height: 140,
                  child: SectionTile(
                    section: section,
                    questionsDone: score?.attempted,
                    questionsTotal: section.questionCount,
                    onTap: () => _openTopicPicker(context, ref, section),
                  ),
                );
              },
            ),
    );
  }

  void _openTopicPicker(
    BuildContext context,
    WidgetRef ref,
    ExamSection section,
  ) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => TopicPickerScreen(
          section: section,
          examId: examId,
        ),
      ),
    ).then((_) {
      final userId = ref.read(authServiceProvider).userId;
      if (userId.isNotEmpty) {
        ref.invalidate(
          userExamProgressProvider(
            ProgressKey(userId: userId, examId: examId),
          ),
        );
      }
    });
  }
}
