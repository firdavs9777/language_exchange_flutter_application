import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/pages/learning/models/weekly_digest.dart';

class WeeklyDigestCard extends ConsumerWidget {
  const WeeklyDigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final digest = ref.watch(weeklyDigestProvider);

    return digest.when(
      data: (d) {
        if (d.xpEarned == 0 && d.lessonsCompleted == 0 && d.vocabularyLearned == 0) {
          return const SizedBox.shrink();
        }
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _showDetail(context, d, l10n),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_view_week, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.learningWeeklyDigestTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _stat(theme, Icons.flash_on, l10n.learningWeeklyDigestXp(d.xpEarned)),
                      _stat(theme, Icons.school, l10n.learningWeeklyDigestLessons(d.lessonsCompleted)),
                      _stat(theme, Icons.book, l10n.learningWeeklyDigestVocab(d.vocabularyLearned)),
                    ],
                  ),
                  if (d.daysActive > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.learningWeeklyDigestDaysActive(d.daysActive),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 120,
          child: Card(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _stat(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  void _showDetail(BuildContext context, WeeklyDigest d, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.learningWeeklyDigestTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.flash_on, l10n.learningWeeklyDigestXp(d.xpEarned)),
            _detailRow(Icons.school, l10n.learningWeeklyDigestLessons(d.lessonsCompleted)),
            _detailRow(Icons.book, l10n.learningWeeklyDigestVocab(d.vocabularyLearned)),
            _detailRow(Icons.local_fire_department, '${l10n.learningStreakCurrent}: ${d.currentStreak}'),
            _detailRow(Icons.emoji_events_outlined, '${l10n.learningStreakLongest}: ${d.longestStreak}'),
            _detailRow(Icons.calendar_month, l10n.learningWeeklyDigestDaysActive(d.daysActive)),
            if (d.topAchievement != null) ...[
              const Divider(height: 32),
              Text(
                l10n.learningWeeklyDigestTopAchievement,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(d.topAchievement!.name),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
