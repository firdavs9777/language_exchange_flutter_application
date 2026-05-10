import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_row_v1.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/widgets/leaderboard_row.dart';

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
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(streakLeaderboardProvider(streakType)),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (response.entries.length >= 3)
                      LeaderboardPodiumV1(
                        entries: response.entries.take(3).toList(),
                        showStreak: true,
                      ),
                    if (response.userPosition != null &&
                        response.userPosition!.rank > 10)
                      LeaderboardUserPositionCard(
                          position: response.userPosition!),
                    ...response.entries.skip(3).map(
                          (entry) => LeaderboardRow(
                            rank: entry.rank,
                            userId: entry.user.id,
                            userName: entry.user.username,
                            avatarUrl: entry.user.avatar,
                            score: entry.streakDays ?? entry.streak,
                            scoreLabel: l10n.days,
                            isCurrentUser: entry.isCurrentUser,
                          ),
                        ),
                    const SizedBox(height: 80),
                  ],
                ),
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
