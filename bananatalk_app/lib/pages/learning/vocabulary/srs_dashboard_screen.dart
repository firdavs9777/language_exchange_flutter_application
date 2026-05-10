import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_empty_state.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_error_view.dart';

class SrsDashboardScreen extends ConsumerWidget {
  const SrsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reviewAsync = ref.watch(dueReviewsProvider(null));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learningSrsDashboardTitle)),
      body: reviewAsync.when(
        data: (response) {
          final cards = response?.dueWords ?? [];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));
          final weekEnd = today.add(const Duration(days: 7));

          final dueToday = cards.where((c) => _isDueOn(c.nextReview, today)).length;
          final dueTomorrow = cards.where((c) => _isDueOn(c.nextReview, tomorrow)).length;
          final dueThisWeek = cards.where((c) {
            final due = c.nextReview;
            if (due == null) return false;
            final dueDay = DateTime(due.year, due.month, due.day);
            return dueDay.isAfter(tomorrow) && !dueDay.isAfter(weekEnd);
          }).length;

          if (dueToday == 0 && dueTomorrow == 0 && dueThisWeek == 0) {
            return LearningEmptyState(
              icon: Icons.celebration,
              message: l10n.learningSrsAllCaughtUp,
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DueCard(
                  icon: Icons.today,
                  iconColor: Colors.orange,
                  label: l10n.learningSrsDueToday(dueToday),
                  emphasized: true,
                ),
                const SizedBox(height: 8),
                _DueCard(
                  icon: Icons.calendar_today,
                  iconColor: Theme.of(context).colorScheme.primary,
                  label: l10n.learningSrsDueTomorrow(dueTomorrow),
                ),
                const SizedBox(height: 8),
                _DueCard(
                  icon: Icons.calendar_view_week,
                  iconColor: Theme.of(context).colorScheme.outline,
                  label: l10n.learningSrsDueThisWeek(dueThisWeek),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: dueToday > 0
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VocabularyReviewScreen()),
                          )
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.learningSrsStartReview),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LearningErrorView(
          message: l10n.learningErrorGeneric,
          onRetry: () => ref.invalidate(dueReviewsProvider(null)),
          retryLabel: l10n.learningCommonRetry,
        ),
      ),
    );
  }

  bool _isDueOn(DateTime? due, DateTime dayStart) {
    if (due == null) return false;
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay == dayStart;
  }
}

class _DueCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool emphasized;

  const _DueCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: emphasized ? 2 : 0,
      color: emphasized
          ? iconColor.withValues(alpha: 0.08)
          : Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.4),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
