import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/pages/learning/achievements/achievements_screen.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/srs_dashboard_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocab_packs_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_screen.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Streak / level / daily-XP summary with shortcuts to the detail screens.
/// [progress] null (not loaded, failed, or a brand-new account) shows "–"
/// placeholders; the shortcuts work either way.
class ProgressCard extends StatelessWidget {
  final LearningProgress? progress;
  final VoidCallback onFullReport;

  const ProgressCard({super.key, required this.progress, required this.onFullReport});

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, AppPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const none = '–';
    final p = progress;
    final goal = p == null || p.dailyGoal <= 0 ? 1 : p.dailyGoal;
    final frac = p == null ? 0.0 : (p.dailyXP / goal).clamp(0.0, 1.0);

    Widget stat(String value, String? label) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            if (label != null)
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.studyProgressTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: stat(p == null ? none : '${p.currentStreak}', l.streak)),
              Expanded(child: stat(p == null ? none : l.studyLevelShort(p.level), null)),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p == null ? '$none XP' : '${p.dailyXP} / ${p.dailyGoal} XP',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: frac, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: Text(l.studyFullReport), onPressed: onFullReport),
              ActionChip(
                  label: Text(l.achievements),
                  onPressed: () => _go(context, const AchievementsScreen())),
              ActionChip(
                  label: Text(l.vocabulary),
                  onPressed: () => _go(context, const VocabularyScreen())),
              ActionChip(
                  label: Text(l.review),
                  onPressed: () => _go(context, const SrsDashboardScreen())),
              // Packs follow the learner's target language server-side; this
              // was otherwise only reachable from the English exam row.
              ActionChip(
                  key: const Key('progress-vocab-packs'),
                  label: Text(l.vocabularyPacks),
                  onPressed: () => _go(context, const VocabPacksScreen())),
            ],
          ),
        ],
      ),
    );
  }
}
