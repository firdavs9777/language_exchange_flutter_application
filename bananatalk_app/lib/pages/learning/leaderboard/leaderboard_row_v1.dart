// TODO(C10): replaced by polished version in widgets/leaderboard_row.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/leaderboard_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Period/Type selection chip — shared across XP and Streak tabs
class LeaderboardPeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const LeaderboardPeriodChip({
    super.key,
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
          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Reusable leaderboard list widget
class LeaderboardListV1 extends StatelessWidget {
  final LeaderboardResponse response;
  final bool showStreak;
  final VoidCallback onRefresh;

  const LeaderboardListV1({
    super.key,
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
            LeaderboardPodiumV1(
              entries: response.entries.take(3).toList(),
              showStreak: showStreak,
            ),
          // User's position (if not in top entries)
          if (response.userPosition != null && response.userPosition!.rank > 10)
            LeaderboardUserPositionCard(position: response.userPosition!),
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
                  (entry) => LeaderboardRankingItem(entry: entry, showStreak: showStreak),
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
class LeaderboardPodiumV1 extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final bool showStreak;

  const LeaderboardPodiumV1({super.key, required this.entries, this.showStreak = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            LeaderboardPodiumItemV1(
              entry: entries[1],
              rank: 2,
              height: 80,
              medalColor: const Color(0xFFC0C0C0),
              showStreak: showStreak,
            ),
          const SizedBox(width: 8),
          // 1st place
          LeaderboardPodiumItemV1(
            entry: entries[0],
            rank: 1,
            height: 100,
            medalColor: const Color(0xFFFFD700),
            showStreak: showStreak,
          ),
          const SizedBox(width: 8),
          // 3rd place
          if (entries.length > 2)
            LeaderboardPodiumItemV1(
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
class LeaderboardPodiumItemV1 extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color medalColor;
  final bool showStreak;

  const LeaderboardPodiumItemV1({
    super.key,
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
                        errorBuilder: (_, __, ___) => LeaderboardDefaultAvatar(
                          username: entry.user.username,
                          fontSize: rank == 1 ? 32 : 24,
                        ),
                      )
                    : LeaderboardDefaultAvatar(
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
                medalColor.withValues(alpha: 0.7),
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
class LeaderboardUserPositionCard extends StatelessWidget {
  final UserPosition position;

  const LeaderboardUserPositionCard({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
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
class LeaderboardRankingItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool showStreak;

  const LeaderboardRankingItem({super.key, required this.entry, this.showStreak = false});

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
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
                color: isCurrentUser ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: isCurrentUser ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: entry.user.avatar != null
                  ? Image.network(
                      entry.user.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          LeaderboardDefaultAvatar(username: entry.user.username, fontSize: 20),
                    )
                  : LeaderboardDefaultAvatar(username: entry.user.username, fontSize: 20),
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
                        color: _getLevelColor(entry.level).withValues(alpha: 0.1),
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

/// Default avatar widget
class LeaderboardDefaultAvatar extends StatelessWidget {
  final String username;
  final double fontSize;

  const LeaderboardDefaultAvatar({super.key, required this.username, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
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
Widget buildLeaderboardEmptyState(BuildContext context, AppLocalizations l10n) {
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
Widget buildLeaderboardEmptyFriendsState(BuildContext context, AppLocalizations l10n) {
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
Widget buildLeaderboardErrorState(
    BuildContext context, AppLocalizations l10n, VoidCallback onRetry) {
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
