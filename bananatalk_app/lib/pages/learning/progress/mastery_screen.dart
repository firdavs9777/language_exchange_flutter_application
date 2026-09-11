import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/progress/widgets/mastery_bar.dart';
import 'package:bananatalk_app/pages/learning/progress/widgets/streak_calendar.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Per-skill mastery, built only from data the learner actually generated.
///
/// The level badge says "your level", never a CEFR certification: eight
/// placement questions and a few daily quizzes do not certify a level.
class MasteryScreen extends StatelessWidget {
  final MasterySummary? mastery;
  final VoidCallback? onRetakePlacement;
  final VoidCallback? onOpenReview;

  const MasteryScreen({
    super.key,
    this.mastery,
    this.onRetakePlacement,
    this.onOpenReview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final m = mastery;

    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.masteryTitle)),
        body: Center(
          child: Padding(
            key: const Key('mastery-empty'),
            padding: const EdgeInsets.all(32),
            child: Text(l10n.masteryEmpty, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.masteryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(m.level, style: theme.textTheme.headlineMedium),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.masteryYourLevel,
                  style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
                ),
              ),
              TextButton(
                key: const Key('mastery-level-retake'),
                onPressed: onRetakePlacement,
                child: Text(l10n.masteryRetake),
              ),
            ],
          ),
          const SizedBox(height: 24),
          KeyedSubtree(
            key: const Key('mastery-vocabulary'),
            child: MasteryBar(
              label: l10n.masteryVocabulary,
              fraction: m.vocabulary.total == 0
                  ? null
                  : m.vocabulary.mastered / m.vocabulary.total,
              caption: l10n.masteryVocabularyCaption(
                m.vocabulary.mastered,
                m.vocabulary.learning,
                m.vocabulary.due,
              ),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          if (m.vocabulary.due > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FilledButton.tonal(
                key: const Key('mastery-due-cta'),
                onPressed: onOpenReview,
                child: Text(l10n.masteryDueCta(m.vocabulary.due)),
              ),
            ),
          KeyedSubtree(
            key: const Key('mastery-grammar'),
            child: MasteryBar(
              label: l10n.masteryGrammar,
              fraction: m.grammar.total == 0 ? null : m.grammar.mastered / m.grammar.total,
              caption: l10n.masteryGrammarCaption(m.grammar.mastered, m.grammar.total),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          ...m.grammar.sections.map((s) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(s.section, style: theme.textTheme.bodyMedium)),
                    Text('${s.mastered}/${s.total}', style: theme.textTheme.bodySmall),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: const Key('mastery-listening'),
            child: MasteryBar(
              label: l10n.masteryListening,
              fraction: m.listening.accuracy,
              caption: l10n.masteryAccuracyCaption(
                ((m.listening.accuracy ?? 0) * 100).round(),
                m.listening.samples,
              ),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          KeyedSubtree(
            key: const Key('mastery-translate'),
            child: MasteryBar(
              label: l10n.masteryTranslate,
              fraction: m.translate.accuracy,
              caption: l10n.masteryAccuracyCaption(
                ((m.translate.accuracy ?? 0) * 100).round(),
                m.translate.samples,
              ),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.masteryConsistency, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          StreakCalendar(activeDays: m.consistencyDays),
        ],
      ),
    );
  }
}
