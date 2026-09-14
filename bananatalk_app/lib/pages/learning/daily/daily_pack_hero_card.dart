import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The Learn tab's daily entry point. Replaces TodaySection's two ListTiles.
///
/// The CTA names the NEXT station rather than saying "Open": a learner who can
/// see that only "Review, 3 left" stands between them and a finished day is
/// being given a reason, not a button.
class DailyPackHeroCard extends StatelessWidget {
  final DailyPack pack;
  final MasterySummary? mastery;
  final VoidCallback onOpen;
  final VoidCallback onPickLanguage;
  final VoidCallback onOpenProgress;

  /// Opens the placement test. Offered only when the learner has no level of
  /// their own — see [DailyPack.levelPlaced].
  final VoidCallback onTakePlacement;

  const DailyPackHeroCard({
    super.key,
    required this.pack,
    required this.onOpen,
    required this.onPickLanguage,
    required this.onOpenProgress,
    required this.onTakePlacement,
    this.mastery,
  });

  String _stationLabel(AppLocalizations l10n, String kind) {
    switch (kind) {
      case 'vocabulary':
        return l10n.packStationVocabulary;
      case 'grammar':
        return l10n.packStationGrammar;
      case 'listening':
        return l10n.packStationListening;
      case 'review':
        return l10n.packStationReview;
      case 'wrap':
        return l10n.packStationWrap;
      case 'translate':
        return l10n.packStationTranslate;
      default:
        return kind;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (pack.needsLanguage) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('today-pick-language'),
          onPressed: onPickLanguage,
          child: Text(l10n.todayPickLanguage),
        ),
      );
    }

    if (pack.theme == null && pack.stations.isEmpty) {
      return Padding(
        key: const Key('today-empty'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(l10n.todayEmpty, style: theme.textTheme.bodyMedium),
      );
    }

    final next = pack.nextStation;
    final m = mastery;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.tertiary.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pack.theme?.topic ?? l10n.today,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${pack.doneCount}/${pack.stations.length}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                if (pack.isLevelFallback)
                  Padding(
                    key: const Key('today-level-fallback'),
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.todayLevelFallback(pack.servedLevel!, pack.requestedLevel!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (!pack.levelPlaced)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('hero-take-placement'),
                        onPressed: onTakePlacement,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.straighten, size: 18),
                        label: Text(l10n.packTakePlacement),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (next == null || pack.packComplete)
                  Row(
                    key: const Key('hero-done'),
                    children: [
                      Icon(Icons.check_circle, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.packDoneForToday)),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('hero-cta'),
                      onPressed: onOpen,
                      child: Text(l10n.packContinueTo(_stationLabel(l10n, next.kind))),
                    ),
                  ),
              ],
            ),
          ),
          if (m != null)
            InkWell(
              key: const Key('hero-progress-strip'),
              onTap: onOpenProgress,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.masteryVocabularyCaption(
                              m.vocabulary.mastered,
                              m.vocabulary.learning,
                              m.vocabulary.due,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            l10n.masteryGrammarCaption(m.grammar.mastered, m.grammar.total),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
