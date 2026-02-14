import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/achievement_model.dart';

/// Achievement card widget for displaying an achievement
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool compact;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(isUnlocked, 40),
            const SizedBox(height: 4),
            Text(
              achievement.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? null : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked ? Colors.white : Colors.grey[50],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(isUnlocked, 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? null : Colors.grey[500],
                            ),
                          ),
                        ),
                        _buildRarityBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: isUnlocked
                              ? const Color(0xFF00BFA5)
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${achievement.xpReward} XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? const Color(0xFF00BFA5)
                                : Colors.grey[400],
                          ),
                        ),
                        if (!isUnlocked && achievement.progress > 0) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildProgressBar(),
                          ),
                        ],
                        if (isUnlocked &&
                            achievement.userProgress?.unlockedAt != null) ...[
                          const Spacer(),
                          Text(
                            _formatDate(achievement.userProgress!.unlockedAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isUnlocked, double size) {
    final color = _getRarityColor(achievement.rarity);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUnlocked ? null : Colors.grey[200],
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        _getIcon(achievement.icon),
        color: isUnlocked ? Colors.white : Colors.grey[400],
        size: size * 0.5,
      ),
    );
  }

  Widget _buildRarityBadge() {
    final color = _getRarityColor(achievement.rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        achievement.rarityLabel,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: achievement.progress.clamp(0, 1),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getRarityColor(achievement.rarity).withOpacity(0.5),
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(achievement.progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF4CAF50);
      case 'rare':
        return const Color(0xFF2196F3);
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'legendary':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'footprints':
        return Icons.directions_walk_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'chat':
        return Icons.chat_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Achievement unlock animation overlay
class AchievementUnlockOverlay extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const AchievementUnlockOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor(achievement.rarity);

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _getIcon(achievement.icon),
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                achievement.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Tap to continue',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF4CAF50);
      case 'rare':
        return const Color(0xFF2196F3);
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'legendary':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'footprints':
        return Icons.directions_walk_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
