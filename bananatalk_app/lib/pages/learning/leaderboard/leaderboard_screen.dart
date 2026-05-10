import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/leaderboard_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Leaderboard screen with rankings
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(leaderboardTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              elevation: 0,
              backgroundColor: context.surfaceColor,
              floating: true,
              pinned: true,
              expandedHeight: 200,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        Spacing.gapSM,
                        Text(
                          l10n.leaderboard,
                          style: context.displayMedium.copyWith(color: Colors.white),
                        ),
                        Spacing.gapXS,
                        Text(
                          l10n.competeWithLearners,
                          style: context.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: context.surfaceColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.textSecondary,
                    indicatorColor: AppColors.primary,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: l10n.xpRankings),
                      Tab(text: l10n.streaks),
                      Tab(text: l10n.friends),
                      Tab(text: l10n.myRanks),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _XpRankingsTab(),
            _StreaksTab(),
            _FriendsTab(),
            _MyRanksTab(),
          ],
        ),
      ),
    );
  }
}

/// XP Rankings Tab with period selector
class _XpRankingsTab extends ConsumerWidget {
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
              _PeriodChip(
                label: l10n.allTime,
                isSelected: period == 'all',
                onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = 'all',
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: l10n.weekly,
                isSelected: period == 'weekly',
                onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = 'weekly',
              ),
              const SizedBox(width: 8),
              _PeriodChip(
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
                return _buildEmptyState(context, l10n);
              }
              return _LeaderboardList(
                response: response,
                onRefresh: () => ref.invalidate(xpLeaderboardProvider(
                  LeaderboardFilter(period: period),
                )),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stack) => _buildErrorState(
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

/// Streaks Tab with type selector
class _StreaksTab extends ConsumerWidget {
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
              _PeriodChip(
                label: l10n.currentStreak,
                isSelected: streakType == 'current',
                onTap: () => ref.read(streakTypeProvider.notifier).state = 'current',
              ),
              const SizedBox(width: 8),
              _PeriodChip(
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
                return _buildEmptyState(context, l10n);
              }
              return _LeaderboardList(
                response: response,
                showStreak: true,
                onRefresh: () => ref.invalidate(streakLeaderboardProvider(streakType)),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stack) => _buildErrorState(
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

/// Friends Tab
class _FriendsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final leaderboardAsync = ref.watch(friendsLeaderboardProvider);

    return leaderboardAsync.when(
      data: (response) {
        if (response == null || response.entries.isEmpty) {
          return _buildEmptyFriendsState(context, l10n);
        }
        return _LeaderboardList(
          response: response,
          onRefresh: () => ref.invalidate(friendsLeaderboardProvider),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => _buildErrorState(
        context,
        l10n,
        () => ref.invalidate(friendsLeaderboardProvider),
      ),
    );
  }
}

/// My Ranks Tab
class _MyRanksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myRanksAsync = ref.watch(myRanksProvider);

    return myRanksAsync.when(
      data: (data) {
        if (data == null) {
          return _buildEmptyState(context, l10n);
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
      error: (error, stack) => _buildErrorState(
        context,
        l10n,
        () => ref.invalidate(myRanksProvider),
      ),
    );
  }
}

/// Period/Type selection chip
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Reusable leaderboard list widget
class _LeaderboardList extends StatelessWidget {
  final LeaderboardResponse response;
  final bool showStreak;
  final VoidCallback onRefresh;

  const _LeaderboardList({
    required this.response,
    this.showStreak = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Top 3 podium
          if (response.entries.length >= 3)
            _Podium(entries: response.entries.take(3).toList(), showStreak: showStreak),
          // User's position (if not in top entries)
          if (response.userPosition != null && response.userPosition!.rank > 10)
            _UserPositionCard(position: response.userPosition!),
          // Rankings list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacing.gapLG,
                Text(
                  AppLocalizations.of(context)!.rankings,
                  style: context.titleLarge,
                ),
                Spacing.gapMD,
                ...response.entries.skip(3).map(
                  (entry) => _RankingItem(entry: entry, showStreak: showStreak),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Podium widget for top 3
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final bool showStreak;

  const _Podium({required this.entries, this.showStreak = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (entries.length > 1)
            _PodiumItem(
              entry: entries[1],
              rank: 2,
              height: 80,
              medalColor: const Color(0xFFC0C0C0),
              showStreak: showStreak,
            ),
          const SizedBox(width: 8),
          // 1st place
          _PodiumItem(
            entry: entries[0],
            rank: 1,
            height: 100,
            medalColor: const Color(0xFFFFD700),
            showStreak: showStreak,
          ),
          const SizedBox(width: 8),
          // 3rd place
          if (entries.length > 2)
            _PodiumItem(
              entry: entries[2],
              rank: 3,
              height: 60,
              medalColor: const Color(0xFFCD7F32),
              showStreak: showStreak,
            ),
        ],
      ),
    );
  }
}

/// Individual podium item
class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color medalColor;
  final bool showStreak;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    required this.medalColor,
    this.showStreak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Stack(
          children: [
            Container(
              width: rank == 1 ? 72 : 56,
              height: rank == 1 ? 72 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: 3),
              ),
              child: ClipOval(
                child: entry.user.avatar != null
                    ? Image.network(
                        entry.user.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _DefaultAvatar(
                          username: entry.user.username,
                          fontSize: rank == 1 ? 32 : 24,
                        ),
                      )
                    : _DefaultAvatar(
                        username: entry.user.username,
                        fontSize: rank == 1 ? 32 : 24,
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.user.username,
            style: TextStyle(
              fontSize: rank == 1 ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        // XP or Streak
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showStreak ? Icons.local_fire_department_rounded : Icons.star_rounded,
              size: 14,
              color: showStreak ? Colors.orange : AppColors.primary,
            ),
            const SizedBox(width: 2),
            Text(
              showStreak ? '${entry.streakDays ?? entry.streak}' : '${entry.xp}',
              style: TextStyle(
                fontSize: 12,
                color: showStreak ? Colors.orange : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Podium stand
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor,
                medalColor.withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// User position card
class _UserPositionCard extends StatelessWidget {
  final UserPosition position;

  const _UserPositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${position.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourPosition,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.keepLearning,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 4),
              Text(
                '${position.xp} XP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ranking item
class _RankingItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool showStreak;

  const _RankingItem({required this.entry, this.showStreak = false});

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? AppColors.primary : Colors.grey[700],
              ),
            ),
          ),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser ? AppColors.primary : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: entry.user.avatar != null
                  ? Image.network(
                      entry.user.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _DefaultAvatar(username: entry.user.username, fontSize: 20),
                    )
                  : _DefaultAvatar(username: entry.user.username, fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '(${AppLocalizations.of(context)!.you})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getLevelColor(entry.level).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Lv.${entry.level}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getLevelColor(entry.level),
                        ),
                      ),
                    ),
                    if (!showStreak && entry.streak > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department_rounded,
                          size: 14, color: Colors.orange[400]),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.streak}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // XP or Streak value
          Row(
            children: [
              Icon(
                showStreak ? Icons.local_fire_department_rounded : Icons.star_rounded,
                size: 16,
                color: showStreak ? Colors.orange : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                showStreak ? '${entry.streakDays ?? entry.streak}' : '${entry.xp}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: showStreak ? Colors.orange : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level >= 50) return const Color(0xFF9C27B0);
    if (level >= 30) return const Color(0xFFFF9800);
    if (level >= 10) return const Color(0xFF2196F3);
    return const Color(0xFF4CAF50);
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
            color: Colors.black.withOpacity(0.05),
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
              color: iconColor.withOpacity(0.1),
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
                  color: iconColor.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.03),
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

/// Default avatar widget
class _DefaultAvatar extends StatelessWidget {
  final String username;
  final double fontSize;

  const _DefaultAvatar({required this.username, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Empty state widget
Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.leaderboard_outlined, size: 64, color: context.textMuted),
        Spacing.gapLG,
        Text(l10n.noRankingsYet, style: context.titleLarge),
        Spacing.gapSM,
        Text(l10n.startLearningToAppear, style: context.bodySmall),
      ],
    ),
  );
}

/// Empty friends state
Widget _buildEmptyFriendsState(BuildContext context, AppLocalizations l10n) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: context.textMuted),
        Spacing.gapLG,
        Text(l10n.noFriendsYet, style: context.titleLarge),
        Spacing.gapSM,
        Text(l10n.addFriendsToCompete, style: context.bodySmall),
      ],
    ),
  );
}

/// Error state widget
Widget _buildErrorState(BuildContext context, AppLocalizations l10n, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: context.textMuted),
        Spacing.gapLG,
        Text(l10n.failedToLoadLeaderboard,
            style: context.bodyMedium.copyWith(color: context.textSecondary)),
        Spacing.gapLG,
        ElevatedButton(
          onPressed: onRetry,
          child: Text(l10n.retry),
        ),
      ],
    ),
  );
}
