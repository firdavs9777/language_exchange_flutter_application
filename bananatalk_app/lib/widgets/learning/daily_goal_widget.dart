import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';

/// Daily and weekly goal progress widget
class DailyGoalWidget extends StatelessWidget {
  final LearningProgress progress;
  final bool showWeekly;

  const DailyGoalWidget({
    super.key,
    required this.progress,
    this.showWeekly = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Goals',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGoalRing(
                  label: 'Daily',
                  current: progress.dailyXP,
                  target: progress.dailyGoal,
                  progress: progress.dailyGoalProgress,
                  color: const Color(0xFF00BFA5),
                ),
              ),
              if (showWeekly) ...[
                const SizedBox(width: 24),
                Expanded(
                  child: _buildGoalRing(
                    label: 'Weekly',
                    current: progress.weeklyXP,
                    target: progress.weeklyGoal,
                    progress: progress.weeklyGoalProgress,
                    color: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ],
          ),
          if (showWeekly) ...[
            const SizedBox(height: 16),
            _buildWeekProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalRing({
    required String label,
    required int current,
    required int target,
    required double progress,
    required Color color,
  }) {
    final isComplete = progress >= 1.0;
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              if (isComplete)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 32,
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$current',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '/ $target',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            color: isComplete ? color : Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekProgress() {
    final daysCompleted = progress.daysCompletedThisWeek;
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0 = Monday

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final isCompleted = index < daysCompleted;
        final isToday = index == today;
        final isPast = index < today;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF00BFA5)
                    : isToday
                        ? const Color(0xFF00BFA5).withOpacity(0.2)
                        : Colors.grey[100],
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: const Color(0xFF00BFA5), width: 2)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : Text(
                        weekdays[index],
                        style: TextStyle(
                          color: isPast ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Compact goal progress indicator
class GoalProgressIndicator extends StatelessWidget {
  final int current;
  final int target;
  final Color? color;

  const GoalProgressIndicator({
    super.key,
    required this.current,
    required this.target,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? current / target : 0.0;
    final effectiveColor = color ?? const Color(0xFF00BFA5);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              backgroundColor: effectiveColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$target',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
