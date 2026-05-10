import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/leaderboard_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_row_v1.dart';

/// My Ranks tab showing user's personal rank and stats
class MyRanksLeaderboardTab extends ConsumerWidget {
  const MyRanksLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myRanksAsync = ref.watch(myRanksProvider);

    return myRanksAsync.when(
      data: (data) {
        if (data == null) {
          return buildLeaderboardEmptyState(context, l10n);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myRanksProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // XP Rank Card
              _RankCard(
                icon: Icons.star_rounded,
                iconColor: AppColors.primary,
                title: l10n.xpRank,
                rank: data.xp.rank,
                total: data.xp.total,
                value: '${data.xp.value} XP',
                percentile: data.xp.percentile,
              ),
              const SizedBox(height: 16),
              // Streak Rank Card
              _RankCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
                title: l10n.streakRank,
                rank: data.streak.rank,
                total: data.streak.total,
                value: '${data.streak.value} ${l10n.days}',
                percentile: data.streak.percentile,
              ),
              const SizedBox(height: 24),
              // Stats Section
              Text(
                l10n.learningStats,
                style: context.titleLarge,
              ),
              const SizedBox(height: 16),
              _StatsGrid(stats: data.stats),
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
        () => ref.invalidate(myRanksProvider),
      ),
    );
  }
}

/// Rank card for My Ranks tab
class _RankCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int rank;
  final int total;
  final String value;
  final String percentile;

  const _RankCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.rank,
    required this.total,
    required this.value,
    required this.percentile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '#$rank ${l10n.outOf(total)}',
                  style: context.bodySmall.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: context.titleMedium.copyWith(color: iconColor)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.topPercent(percentile),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stats grid for My Ranks tab
class _StatsGrid extends StatelessWidget {
  final MyLearningStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.star_rounded,
          iconColor: AppColors.primary,
          label: l10n.totalXp,
          value: '${stats.totalXp}',
        ),
        _StatCard(
          icon: Icons.local_fire_department_rounded,
          iconColor: Colors.orange,
          label: l10n.currentStreak,
          value: '${stats.currentStreak} ${l10n.days}',
        ),
        _StatCard(
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.amber,
          label: l10n.longestStreak,
          value: '${stats.longestStreak} ${l10n.days}',
        ),
        _StatCard(
          icon: Icons.school_rounded,
          iconColor: Colors.blue,
          label: l10n.lessonsCompleted,
          value: '${stats.lessonsCompleted}',
        ),
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(value, style: context.titleMedium),
          Text(label, style: context.bodySmall.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }
}
