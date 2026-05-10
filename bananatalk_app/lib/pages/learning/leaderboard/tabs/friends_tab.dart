import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_row_v1.dart';

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
        return LeaderboardListV1(
          response: response,
          onRefresh: () => ref.invalidate(friendsLeaderboardProvider),
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
