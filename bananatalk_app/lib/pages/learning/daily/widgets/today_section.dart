import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';

/// The two "Today" cards at the top of the Learn tab (spec §4.8).
class TodaySection extends StatelessWidget {
  final DailyDropState state;
  final void Function(DailyItem) onOpen;
  final VoidCallback onPickLanguage;

  const TodaySection({
    super.key,
    required this.state,
    required this.onOpen,
    required this.onPickLanguage,
  });

  @override
  Widget build(BuildContext context) {
    if (state.needsLanguage) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('today-pick-language'),
          onPressed: onPickLanguage,
          child: Text(AppLocalizations.of(context)!.todayPickLanguage),
        ),
      );
    }

    final items = [state.grammar, state.vocabulary].whereType<DailyItem>().toList();
    if (items.isEmpty) {
      return const SizedBox(key: Key('today-empty'), height: 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isLevelFallback)
          Padding(
            key: const Key('today-level-fallback'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              AppLocalizations.of(context)!.todayLevelFallback(
                state.servedLevel!,
                state.requestedLevel!,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...items.map((item) => _TodayCard(
              item: item,
              score: state.scoreFor(item.kind),
              onTap: () => onOpen(item),
            )),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final DailyItem item;
  final int? score;
  final VoidCallback onTap;

  const _TodayCard({required this.item, required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = score != null;
    final l10n = AppLocalizations.of(context)!;
    final subtitlePrefix = item.kind == 'grammar' ? l10n.todaysGrammar : l10n.todaysVocabulary;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListTile(
        onTap: done ? null : onTap,
        leading: Icon(item.kind == 'grammar' ? Icons.rule : Icons.style),
        title: Text(item.title),
        subtitle: Text('$subtitlePrefix · ${l10n.todayMinutes(2)}'),
        trailing: done
            ? Text(
                l10n.dailyScore(score!, item.quickCheck.length),
                style: Theme.of(context).textTheme.titleMedium,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
