import 'package:flutter/material.dart';

/// Language level badge (A1-C2)
class LanguageLevelBadge extends StatelessWidget {
  final String? level;
  final String? language;
  final bool compact;

  const LanguageLevelBadge({
    super.key,
    this.level,
    this.language,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (level == null || level!.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _getLevelColor(level!);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          level!.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            language != null ? '$level $language' : level!.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
      case 'A2':
        return const Color(0xFF4CAF50); // Green - Beginner
      case 'B1':
      case 'B2':
        return const Color(0xFFFF9800); // Orange - Intermediate
      case 'C1':
      case 'C2':
        return const Color(0xFFE91E63); // Pink - Advanced
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  static String getLevelDescription(String? level) {
    switch (level?.toUpperCase()) {
      case 'A1':
        return 'Beginner';
      case 'A2':
        return 'Elementary';
      case 'B1':
        return 'Intermediate';
      case 'B2':
        return 'Upper Intermediate';
      case 'C1':
        return 'Advanced';
      case 'C2':
        return 'Proficient';
      default:
        return 'Not specified';
    }
  }
}
