import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/widgets/rank_badge.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/widgets/friend_indicator.dart';

class LeaderboardRow extends StatelessWidget {
  final int rank;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int score;
  final String scoreLabel;
  final bool isFriend;
  final bool isCurrentUser;
  final int? rankChange;
  final VoidCallback? onTap;

  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.score,
    required this.scoreLabel,
    this.isFriend = false,
    this.isCurrentUser = false,
    this.rankChange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isCurrentUser ? 2 : 0,
      color: isCurrentUser
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              RankBadge(rank: rank),
              const SizedBox(width: 12),
              _buildAvatar(theme),
              const SizedBox(width: 12),
              Expanded(child: _buildName(theme)),
              _buildScore(theme),
              if (rankChange != null) ...[
                const SizedBox(width: 8),
                _buildRankChange(theme, rankChange!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImageProvider(ImageUtils.normalizeImageUrl(avatarUrl!))
          : null,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Text(
              userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildName(ThemeData theme) {
    return Row(
      children: [
        Flexible(
          child: Text(
            userName,
            style: TextStyle(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isFriend) ...[
          const SizedBox(width: 6),
          const FriendIndicator(),
        ],
      ],
    );
  }

  Widget _buildScore(ThemeData theme) {
    return Text(
      '$score $scoreLabel',
      style: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
    );
  }

  Widget _buildRankChange(ThemeData theme, int delta) {
    Color color;
    IconData icon;
    if (delta > 0) {
      color = Colors.green;
      icon = Icons.trending_up;
    } else if (delta < 0) {
      color = Colors.red;
      icon = Icons.trending_down;
    } else {
      color = theme.colorScheme.outline;
      icon = Icons.trending_flat;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 2),
          Text(
            delta == 0 ? '—' : (delta > 0 ? '+$delta' : '$delta'),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
