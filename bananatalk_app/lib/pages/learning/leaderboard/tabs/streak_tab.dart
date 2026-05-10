import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_row_v1.dart';

/// Streaks tab with current/longest type selector
class StreakLeaderboardTab extends ConsumerWidget {
  const StreakLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final streakType = ref.watch(streakTypeProvider);
    final leaderboardAsync = ref.watch(streakLeaderboardProvider(streakType));

    return Column(
      children: [
        // Streak type selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              LeaderboardPeriodChip(
                label: l10n.currentStreak,
                isSelected: streakType == 'current',
                onTap: () => ref.read(streakTypeProvider.notifier).state = 'current',
              ),
              const SizedBox(width: 8),
              LeaderboardPeriodChip(
                label: l10n.longestStreak,
                isSelected: streakType == 'longest',
                onTap: () => ref.read(streakTypeProvider.notifier).state = 'longest',
              ),
            ],
          ),
        ),
        // Leaderboard content
        Expanded(
          child: leaderboardAsync.when(
            data: (response) {
              if (response == null || response.entries.isEmpty) {
                return buildLeaderboardEmptyState(context, l10n);
              }
              return LeaderboardListV1(
                response: response,
                showStreak: true,
                onRefresh: () => ref.invalidate(streakLeaderboardProvider(streakType)),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stack) => buildLeaderboardErrorState(
              context,
              l10n,
              () => ref.invalidate(streakLeaderboardProvider(streakType)),
            ),
          ),
        ),
      ],
    );
  }
}
