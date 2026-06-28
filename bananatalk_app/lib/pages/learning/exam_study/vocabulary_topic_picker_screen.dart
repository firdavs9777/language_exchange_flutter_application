import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/vocabulary_mode_screen.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/cefr_topik_mapping.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 2 of the Vocabulary flow — pick a topic (or "All topics") within
/// the chosen level. Pushes the Browse/Practice mode screen on tap.
class VocabularyTopicPickerScreen extends ConsumerWidget {
  const VocabularyTopicPickerScreen({
    super.key,
    required this.examId,
    required this.examName,
    required this.level,
  });

  final String examId;
  final String examName;
  final String level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topicsAsync = ref.watch(
      vocabularyTopicsProvider(
        VocabularyTopicsKey(examId: examId, level: level),
      ),
    );
    final secondary = topikLabelFor(level, examName: examName);
    final levelLabel = secondary != null ? '$level · $secondary' : level;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          levelLabel,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(
          vocabularyTopicsProvider(
            VocabularyTopicsKey(examId: examId, level: level),
          ),
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              l10n.examVocabTopicPickerTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 20),
            topicsAsync.when(
              data: (topics) => _buildList(context, topics, l10n),
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

  Widget _buildList(BuildContext context, List<String> topics, AppLocalizations l10n) {
    final tiles = <Widget>[
      _tile(context, l10n.examVocabAllTopics, null),
      const SizedBox(height: 10),
    ];
    for (final t in topics) {
      tiles.add(_tile(context, t, t));
      tiles.add(const SizedBox(height: 10));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tiles,
    );
  }

  Widget _tile(BuildContext context, String label, String? topic) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMode(context, topic),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dividerColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: context.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMode(BuildContext context, String? topic) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => VocabularyModeScreen(
          examId: examId,
          examName: examName,
          level: level,
          topic: topic,
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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
            onPressed: () => ref.invalidate(
              vocabularyTopicsProvider(
                VocabularyTopicsKey(examId: examId, level: level),
              ),
            ),
            child: Text(l10n.examStudyRetry),
          ),
        ],
      ),
    );
  }
}
