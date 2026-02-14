import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/leaderboard_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(leaderboardTypeProvider.notifier).state =
            _tabController.index == 0 ? 'weekly' : 'all_time';
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
    final leaderboardType = ref.watch(leaderboardTypeProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(
      LeaderboardFilter(type: leaderboardType),
    ));

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
                          'Leaderboard',
                          style: context.displayMedium.copyWith(color: Colors.white),
                        ),
                        Spacing.gapXS,
                        Text(
                          'Compete with other learners!',
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
                    tabs: const [
                      Tab(text: 'This Week'),
                      Tab(text: 'All Time'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: leaderboardAsync.when(
          data: (response) {
            if (response == null || response.entries.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(leaderboardProvider(
                  LeaderboardFilter(type: leaderboardType),
                ));
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Top 3 podium
                  if (response.entries.length >= 3)
                    _buildPodium(response.entries.take(3).toList()),
                  // User's position (if not in top entries)
                  if (response.userPosition != null &&
                      response.userPosition!.rank > 10)
                    _buildUserPosition(response.userPosition!),
                  // Rankings list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacing.gapLG,
                        Text(
                          'Rankings',
                          style: context.titleLarge,
                        ),
                        Spacing.gapMD,
                        ...response.entries
                            .skip(3)
                            .map((entry) => _buildRankingItem(entry)),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: context.textMuted),
                Spacing.gapLG,
                Text('Failed to load leaderboard',
                    style: context.bodyMedium.copyWith(color: context.textSecondary)),
                Spacing.gapLG,
                ElevatedButton(
                  onPressed: () => ref.invalidate(leaderboardProvider(
                    LeaderboardFilter(type: leaderboardType),
                  )),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
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
          if (top3.length > 1)
            _buildPodiumItem(top3[1], 2, 80, const Color(0xFFC0C0C0)),
          const SizedBox(width: 8),
          // 1st place
          _buildPodiumItem(top3[0], 1, 100, const Color(0xFFFFD700)),
          const SizedBox(width: 8),
          // 3rd place
          if (top3.length > 2)
            _buildPodiumItem(top3[2], 3, 60, const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardEntry entry,
    int rank,
    double height,
    Color medalColor,
  ) {
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
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(
                          entry.user.username,
                          rank == 1 ? 32 : 24,
                        ),
                      )
                    : _buildDefaultAvatar(
                        entry.user.username,
                        rank == 1 ? 32 : 24,
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
        // XP
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 14,
              color: Color(0xFF00BFA5),
            ),
            const SizedBox(width: 2),
            Text(
              '${entry.xp}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF00BFA5),
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

  Widget _buildUserPosition(UserPosition position) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Position',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Keep learning to climb!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00BFA5),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFF00BFA5),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${position.xp} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BFA5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(LeaderboardEntry entry) {
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF00BFA5).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF00BFA5).withOpacity(0.3))
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
                color: isCurrentUser
                    ? const Color(0xFF00BFA5)
                    : Colors.grey[700],
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
                color: isCurrentUser
                    ? const Color(0xFF00BFA5)
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: entry.user.avatar != null
                  ? Image.network(
                      entry.user.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildDefaultAvatar(entry.user.username, 20),
                    )
                  : _buildDefaultAvatar(entry.user.username, 20),
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
                        color: isCurrentUser
                            ? const Color(0xFF00BFA5)
                            : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          '(You)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF00BFA5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
                    const SizedBox(width: 8),
                    if (entry.streak > 0) ...[
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: Colors.orange[400],
                      ),
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
          // XP
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFF00BFA5),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.xp}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BFA5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String username, double fontSize) {
    return Container(
      color: const Color(0xFF00BFA5).withOpacity(0.2),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00BFA5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: context.textMuted),
            Spacing.gapLG,
            Text(
              'No rankings yet',
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              'Start learning to appear on the leaderboard!',
              style: context.bodySmall,
            ),
          ],
        ),
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
