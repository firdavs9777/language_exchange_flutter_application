import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/challenge_model.dart';

/// Challenge card widget for displaying a challenge
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = challenge.isCompleted;
    final progress = challenge.progressPercentage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: isCompleted ? 0 : 2,
      color: isCompleted ? const Color(0xFF00BFA5).withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildTypeBadge(),
                            const SizedBox(width: 8),
                            _buildDifficultyBadge(),
                            const Spacer(),
                            _buildTimeRemaining(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${challenge.currentProgress}/${challenge.requirement.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? const Color(0xFF00BFA5)
                              : Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? const Color(0xFF00BFA5)
                            : _getTypeColor(challenge.type),
                      ),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Rewards
              Row(
                children: [
                  _buildRewardChip(
                    icon: Icons.star_rounded,
                    text: '+${challenge.xpReward} XP',
                    color: const Color(0xFF00BFA5),
                  ),
                  if (challenge.bonusReward != null) ...[
                    const SizedBox(width: 8),
                    _buildRewardChip(
                      icon: _getBonusIcon(challenge.bonusReward!.type),
                      text: challenge.bonusReward!.label,
                      color: const Color(0xFF9C27B0),
                    ),
                  ],
                  if (isCompleted) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final color = _getTypeColor(challenge.type);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getCategoryIcon(challenge.category),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildTypeBadge() {
    final color = _getTypeColor(challenge.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        challenge.typeLabel,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    final color = _getDifficultyColor(challenge.difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        challenge.difficultyLabel,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeRemaining() {
    final remaining = challenge.timeRemaining;
    final isUrgent = remaining.inHours < 6;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: isUrgent ? Colors.orange : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          challenge.timeRemainingFormatted,
          style: TextStyle(
            fontSize: 11,
            color: isUrgent ? Colors.orange : Colors.grey[500],
            fontWeight: isUrgent ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return const Color(0xFF2196F3);
      case 'weekly':
        return const Color(0xFF9C27B0);
      case 'special':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'hard':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'messaging':
        return Icons.chat_rounded;
      case 'vocabulary':
        return Icons.text_fields_rounded;
      case 'lessons':
        return Icons.school_rounded;
      case 'corrections':
        return Icons.spellcheck_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'mixed':
        return Icons.widgets_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  IconData _getBonusIcon(String type) {
    switch (type.toLowerCase()) {
      case 'streak_freeze':
        return Icons.ac_unit_rounded;
      case 'xp_boost':
        return Icons.bolt_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }
}

/// Compact challenge widget for dashboard
class ChallengeCompactCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onTap;

  const ChallengeCompactCard({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progressPercentage;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 4,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      challenge.isCompleted
                          ? const Color(0xFF00BFA5)
                          : _getTypeColor(challenge.type),
                    ),
                  ),
                  if (challenge.isCompleted)
                    const Icon(
                      Icons.check,
                      color: Color(0xFF00BFA5),
                      size: 18,
                    )
                  else
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${challenge.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00BFA5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return const Color(0xFF2196F3);
      case 'weekly':
        return const Color(0xFF9C27B0);
      case 'special':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }
}
