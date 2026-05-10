import 'package:flutter/material.dart';

class RankBadge extends StatelessWidget {
  final int rank;
  const RankBadge({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = _color(context, rank);
    final icon = _icon(rank);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 18, color: color)
          : Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
    );
  }

  Color _color(BuildContext context, int r) {
    if (r == 1) return const Color(0xFFFFD700); // gold
    if (r == 2) return const Color(0xFFC0C0C0); // silver
    if (r == 3) return const Color(0xFFCD7F32); // bronze
    return Theme.of(context).colorScheme.primary;
  }

  IconData? _icon(int r) {
    if (r == 1) return Icons.emoji_events;
    if (r == 2 || r == 3) return Icons.workspace_premium;
    return null;
  }
}
