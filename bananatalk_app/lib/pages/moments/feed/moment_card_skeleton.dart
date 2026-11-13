import 'package:flutter/material.dart';

import 'package:bananatalk_app/utils/theme_extensions.dart';

/// A static stand-in for a moment card while the first page loads: avatar,
/// two text bars and a 4:5 media block. No animation, so it never keeps a
/// test (or the frame scheduler) busy; colours come from the theme.
class MomentCardSkeleton extends StatelessWidget {
  const MomentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final fill = context.containerHighColor;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: bar(double.infinity, 12),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 0.25,
                        child: bar(double.infinity, 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
