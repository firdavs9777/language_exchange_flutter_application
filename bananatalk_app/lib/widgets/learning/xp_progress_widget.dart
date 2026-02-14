import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';

/// XP Progress bar widget showing current XP and progress to next level
class XpProgressWidget extends StatelessWidget {
  final LearningProgress progress;
  final bool showLabels;
  final double height;

  const XpProgressWidget({
    super.key,
    required this.progress,
    this.showLabels = true,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final levelInfo = progress.levelInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Level ${progress.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${progress.totalXP} XP',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${levelInfo.xpNeeded} XP to Level ${levelInfo.current + 1}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        Stack(
          children: [
            // Background
            Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Progress
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: height,
              width: double.infinity,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: levelInfo.progress.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00E676)],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact XP indicator for small spaces
class XpIndicator extends StatelessWidget {
  final int xp;
  final bool showIcon;

  const XpIndicator({
    super.key,
    required this.xp,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const Icon(
              Icons.star_rounded,
              color: Color(0xFF00BFA5),
              size: 16,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '+$xp XP',
            style: const TextStyle(
              color: Color(0xFF00BFA5),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
