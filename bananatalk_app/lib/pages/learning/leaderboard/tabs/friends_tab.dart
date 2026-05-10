import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_row_v1.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/widgets/leaderboard_row.dart';

/// Friends leaderboard tab
class FriendsLeaderboardTab extends ConsumerWidget {
  const FriendsLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final leaderboardAsync = ref.watch(friendsLeaderboardProvider);

    return leaderboardAsync.when(
      data: (response) {
        if (response == null || response.entries.isEmpty) {
          return buildLeaderboardEmptyFriendsState(context, l10n);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(friendsLeaderboardProvider),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (response.entries.length >= 3)
                LeaderboardPodiumV1(
                  entries: response.entries.take(3).toList(),
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
                      score: entry.xp,
                      scoreLabel: 'XP',
                      isFriend: !entry.isCurrentUser,
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
        () => ref.invalidate(friendsLeaderboardProvider),
      ),
    );
  }
}
