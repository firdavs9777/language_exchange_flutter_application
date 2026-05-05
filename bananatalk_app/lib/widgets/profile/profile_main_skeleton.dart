import 'package:flutter/material.dart';
import 'package:bananatalk_app/widgets/shimmer_loading.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class ProfileMainSkeleton extends StatelessWidget {
  const ProfileMainSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
        child: Column(
          children: [
            ShimmerSkeleton.circle(radius: 60),
            const SizedBox(height: 16),
            ShimmerSkeleton.line(width: 180, height: 22),
            const SizedBox(height: 10),
            ShimmerSkeleton.line(width: 240, height: 14),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatTile()),
                const SizedBox(width: 8),
                Expanded(child: _StatTile()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _StatTile()),
                const SizedBox(width: 8),
                Expanded(child: _StatTile()),
              ],
            ),
            const SizedBox(height: 24),
            ShimmerSkeleton.card(width: double.infinity, height: 86, radius: 20),
            const SizedBox(height: 16),
            ShimmerSkeleton.card(width: double.infinity, height: 120, radius: 20),
            const SizedBox(height: 16),
            ShimmerSkeleton.card(width: double.infinity, height: 200, radius: 20),
            const SizedBox(height: 16),
            ShimmerSkeleton.line(width: 160, height: 22),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: List.generate(
                6,
                (_) => ShimmerSkeleton.card(
                  width: double.infinity,
                  height: double.infinity,
                  radius: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton.line(width: 40, height: 24),
          const SizedBox(height: 8),
          ShimmerSkeleton.line(width: 70, height: 12),
        ],
      ),
    );
  }
}
