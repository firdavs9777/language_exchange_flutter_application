import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';

/// Lesson card widget for displaying a lesson item
class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;
  final bool showProgress;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.isCompleted;
    final isLocked = lesson.isPremium; // TODO: Check user premium status

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isLocked ? 0 : 1,
      color: isLocked ? Colors.grey[100] : Colors.white,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(isCompleted, isLocked),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isLocked ? Colors.grey[500] : null,
                            ),
                          ),
                        ),
                        if (isCompleted && lesson.bestScore != null)
                          _buildScoreBadge(lesson.bestScore!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.access_time,
                          '${lesson.estimatedMinutes} min',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.star_rounded,
                          '+${lesson.xpReward} XP',
                          color: const Color(0xFF00BFA5),
                        ),
                        const Spacer(),
                        _buildLevelBadge(lesson.level),
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

  Widget _buildIcon(bool isCompleted, bool isLocked) {
    IconData icon;
    Color color;
    Color bgColor;

    if (isLocked) {
      icon = Icons.lock_rounded;
      color = Colors.grey[400]!;
      bgColor = Colors.grey[200]!;
    } else if (isCompleted) {
      icon = Icons.check_circle_rounded;
      color = const Color(0xFF00BFA5);
      bgColor = const Color(0xFF00BFA5).withOpacity(0.1);
    } else {
      icon = _getCategoryIcon(lesson.category);
      color = _getCategoryColor(lesson.category);
      bgColor = color.withOpacity(0.1);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    Color color;
    if (score >= 100) {
      color = const Color(0xFFFFD700); // Gold for perfect
    } else if (score >= 80) {
      color = const Color(0xFF00BFA5);
    } else if (score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (score >= 100)
            const Icon(
              Icons.workspace_premium_rounded,
              size: 12,
              color: Color(0xFFFFD700),
            )
          else
            Icon(
              Icons.grade_rounded,
              size: 12,
              color: color,
            ),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    final effectiveColor = color ?? Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: effectiveColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: effectiveColor,
            fontWeight: color != null ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getLevelColor(level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: _getLevelColor(level),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return Icons.spellcheck_rounded;
      case 'vocabulary':
        return Icons.text_fields_rounded;
      case 'conversation':
        return Icons.chat_rounded;
      case 'listening':
        return Icons.headphones_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'writing':
        return Icons.edit_rounded;
      case 'pronunciation':
        return Icons.mic_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return const Color(0xFF9C27B0);
      case 'vocabulary':
        return const Color(0xFF2196F3);
      case 'conversation':
        return const Color(0xFF00BFA5);
      case 'listening':
        return const Color(0xFFFF9800);
      case 'reading':
        return const Color(0xFF4CAF50);
      case 'writing':
        return const Color(0xFFE91E63);
      case 'pronunciation':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF607D8B);
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return const Color(0xFF4CAF50);
      case 'A2':
        return const Color(0xFF8BC34A);
      case 'B1':
        return const Color(0xFFFF9800);
      case 'B2':
        return const Color(0xFFFF5722);
      case 'C1':
        return const Color(0xFF9C27B0);
      case 'C2':
        return const Color(0xFF673AB7);
      default:
        return Colors.grey;
    }
  }
}

/// Unit header for lesson list
class LessonUnitHeader extends StatelessWidget {
  final UnitSummary unit;

  const LessonUnitHeader({
    super.key,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${unit.number}',
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
                  unit.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${unit.completedCount}/${unit.lessonsCount} lessons',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: unit.progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00BFA5),
                  ),
                ),
                Text(
                  '${(unit.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
