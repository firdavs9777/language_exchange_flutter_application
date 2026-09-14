import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/weekly_report_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The learner's week in the daily pack.
///
/// An empty week invites a start rather than reporting zeroes: "0 days · 0
/// words · 0%" reads as a failure report to someone who simply has not begun.
class WeeklyReportScreen extends StatelessWidget {
  final WeeklyReport? report;
  final VoidCallback? onStart;

  const WeeklyReportScreen({super.key, this.report, this.onStart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final r = report;

    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.weeklyReportTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (r.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.weeklyReportTitle)),
        body: Center(
          child: Padding(
            key: const Key('weekly-empty'),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.weeklyReportEmpty,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (onStart != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('weekly-start'),
                    onPressed: onStart,
                    child: Text(l10n.weeklyReportStart),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklyReportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.weeklyReportRange(r.weekStartKey, r.weekEndKey),
            style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 20),
          _Stat(
            statKey: 'weekly-days',
            value: '${r.daysStudied}',
            label: l10n.weeklyReportDays,
          ),
          _Stat(
            statKey: 'weekly-stations',
            value: '${r.stationsCompleted}',
            label: l10n.weeklyReportStations,
          ),
          _Stat(
            statKey: 'weekly-units',
            value: '${r.unitsMastered}',
            label: l10n.weeklyReportUnits,
          ),
          _Stat(
            statKey: 'weekly-words',
            value: '${r.wordsLearned}',
            label: l10n.weeklyReportWords,
          ),
          // Omitted entirely when there is nothing to measure, rather than
          // shown as 0%.
          if (r.accuracyPercent != null)
            _Stat(
              statKey: 'weekly-accuracy',
              value: '${r.accuracyPercent}%',
              label: l10n.weeklyReportAccuracy,
            ),
          if (r.bestDayKey != null) ...[
            const SizedBox(height: 12),
            Card(
              key: const Key('weekly-best-day'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.star, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.weeklyReportBestDay(r.bestDayKey!, r.bestDayStations),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String statKey;
  final String value;
  final String label;

  const _Stat({required this.statKey, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: Key(statKey),
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 72,
            child: Text(value, style: theme.textTheme.headlineSmall),
          ),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
