import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/vocabulary_topic_picker_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/level_card.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/cefr_topik_mapping.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 1 of the Vocabulary flow — pick a CEFR level. For Korean exams
/// each tile shows the TOPIK equivalent underneath the CEFR label.
/// Levels with no seeded words for this exam are greyed out.
class VocabularyLevelPickerScreen extends ConsumerWidget {
  const VocabularyLevelPickerScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  final String examId;
  final String examName;

  static const _allLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final levelsAsync = ref.watch(vocabularyLevelsProvider(examId));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examVocabLevelPickerTitle,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(vocabularyLevelsProvider(examId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              l10n.examVocabLevelPickerSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            levelsAsync.when(
              data: (available) => _buildGrid(context, available),
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

  Widget _buildGrid(BuildContext context, List<String> available) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allLevels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final cefr = _allLevels[index];
        final isAvailable = available.contains(cefr);
        return LevelCard(
          cefr: cefr,
          secondaryLabel: topikLabelFor(cefr, examName: examName),
          disabled: !isAvailable,
          onTap: () => _openTopicPicker(context, cefr),
        );
      },
    );
  }

  void _openTopicPicker(BuildContext context, String level) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => VocabularyTopicPickerScreen(
          examId: examId,
          examName: examName,
          level: level,
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
            onPressed: () => ref.invalidate(vocabularyLevelsProvider(examId)),
            child: Text(l10n.examStudyRetry),
          ),
        ],
      ),
    );
  }
}
