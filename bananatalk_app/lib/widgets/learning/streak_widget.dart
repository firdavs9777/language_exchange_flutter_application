import 'package:flutter/material.dart';

/// Streak indicator widget with flame icon
class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int? longestStreak;
  final bool showLongest;
  final bool compact;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    this.longestStreak,
    this.showLongest = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull(context);
  }

  Widget _buildCompact() {
    final isActive = currentStreak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFF6B00).withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: isActive ? const Color(0xFFFF6B00) : Colors.grey[400],
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '$currentStreak',
            style: TextStyle(
              color: isActive ? const Color(0xFFFF6B00) : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final isActive = currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: isActive ? Colors.white : Colors.grey[400],
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                '$currentStreak',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentStreak == 1 ? 'Day Streak' : 'Day Streak',
            style: TextStyle(
              color: isActive ? Colors.white.withOpacity(0.9) : Colors.grey[500],
              fontSize: 14,
            ),
          ),
          if (showLongest && longestStreak != null && longestStreak! > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Longest: $longestStreak days',
              style: TextStyle(
                color:
                    isActive ? Colors.white.withOpacity(0.7) : Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Streak freeze indicator
class StreakFreezeWidget extends StatelessWidget {
  final int freezeCount;

  const StreakFreezeWidget({
    super.key,
    required this.freezeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.ac_unit_rounded,
            color: Color(0xFF2196F3),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$freezeCount',
            style: const TextStyle(
              color: Color(0xFF2196F3),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
