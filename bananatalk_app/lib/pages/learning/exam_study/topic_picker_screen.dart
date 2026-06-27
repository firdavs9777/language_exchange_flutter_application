import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/section_practice_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/topic_card.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_topic.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interstitial between a section tile tap and the actual practice
/// screen. Renders an "All topics" tile + one tile per distinct topic
/// returned by the backend. Tapping a tile pushes the practice screen
/// pre-filtered to that topic.
class TopicPickerScreen extends ConsumerWidget {
  const TopicPickerScreen({
    super.key,
    required this.section,
    required this.examId,
  });

  final ExamSection section;
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topicsAsync = ref.watch(topicsForSectionProvider(section.id));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          section.sectionName,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(topicsForSectionProvider(section.id)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              l10n.examTopicPickerTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.examTopicPickerSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            topicsAsync.when(
              data: (topics) => _buildGrid(context, topics),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _errorState(context, ref, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<ExamTopic> topics) {
    final l10n = AppLocalizations.of(context)!;
    // "All topics" always first so the user can opt out of filtering
    // without scanning the whole grid.
    final cards = <Widget>[
      TopicCard(
        label: l10n.examTopicAllTopics,
        questionCount: 0,
        isAllTopics: true,
        onTap: () => _openPractice(context, topic: null),
      ),
      ...topics.map(
        (t) => TopicCard(
          label: t.topic,
          questionCount: t.questionCount,
          onTap: () => _openPractice(context, topic: t.topic),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, i) => cards[i],
    );
  }

  void _openPractice(BuildContext context, {required String? topic}) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => SectionPracticeScreen(
          section: section,
          examId: examId,
          topic: topic,
        ),
      ),
    );
  }

  Widget _errorState(
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
            onPressed: () =>
                ref.invalidate(topicsForSectionProvider(section.id)),
            child: Text(l10n.examStudyRetry),
          ),
        ],
      ),
    );
  }
}
