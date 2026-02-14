import 'package:flutter/material.dart';

/// Level badge widget displaying user's current level
class LevelBadgeWidget extends StatelessWidget {
  final int level;
  final double size;
  final bool showLabel;

  const LevelBadgeWidget({
    super.key,
    required this.level,
    this.size = 48,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              '$level',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            'Level',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Color _getLevelColor(int level) {
    if (level < 5) return const Color(0xFF4CAF50); // Green - Beginner
    if (level < 10) return const Color(0xFF2196F3); // Blue - Intermediate
    if (level < 20) return const Color(0xFF9C27B0); // Purple - Advanced
    if (level < 30) return const Color(0xFFFF9800); // Orange - Expert
    return const Color(0xFFE91E63); // Pink - Master
  }
}

/// Small level indicator
class LevelIndicator extends StatelessWidget {
  final int level;

  const LevelIndicator({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getLevelColor(level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: _getLevelColor(level),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Lv.$level',
            style: TextStyle(
              color: _getLevelColor(level),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level < 5) return const Color(0xFF4CAF50);
    if (level < 10) return const Color(0xFF2196F3);
    if (level < 20) return const Color(0xFF9C27B0);
    if (level < 30) return const Color(0xFFFF9800);
    return const Color(0xFFE91E63);
  }
}
