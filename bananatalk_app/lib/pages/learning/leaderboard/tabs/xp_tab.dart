import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/leaderboard_model.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_row_v1.dart';

/// XP Rankings tab with period selector
class XpLeaderboardTab extends ConsumerWidget {
  const XpLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final period = ref.watch(leaderboardPeriodProvider);
    final leaderboardAsync = ref.watch(xpLeaderboardProvider(
      LeaderboardFilter(period: period),
    ));

    return Column(
      children: [
        // Period selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              LeaderboardPeriodChip(
                label: l10n.allTime,
                isSelected: period == 'all',
                onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = 'all',
              ),
              const SizedBox(width: 8),
              LeaderboardPeriodChip(
                label: l10n.weekly,
                isSelected: period == 'weekly',
                onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = 'weekly',
              ),
              const SizedBox(width: 8),
              LeaderboardPeriodChip(
                label: l10n.monthly,
                isSelected: period == 'monthly',
                onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = 'monthly',
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
                onRefresh: () => ref.invalidate(xpLeaderboardProvider(
                  LeaderboardFilter(period: period),
                )),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stack) => buildLeaderboardErrorState(
              context,
              l10n,
              () => ref.invalidate(xpLeaderboardProvider(
                LeaderboardFilter(period: period),
              )),
            ),
          ),
        ),
      ],
    );
  }
}
