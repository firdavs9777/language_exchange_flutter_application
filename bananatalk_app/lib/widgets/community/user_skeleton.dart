import 'package:flutter/material.dart';
import 'package:bananatalk_app/widgets/shimmer_loading.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Skeleton placeholder for list-based user views (City detail, Topics detail).
class UserListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const UserListSkeleton({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: context.dividerColor),
      itemBuilder: (_, __) => const _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton.circle(radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton.line(width: 140, height: 14),
                const SizedBox(height: 8),
                ShimmerSkeleton.line(width: 200, height: 12),
                const SizedBox(height: 6),
                ShimmerSkeleton.line(width: 110, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShimmerSkeleton(
            width: 36,
            height: 36,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for grid-based user views (Gender, Nearby, Topics).
class UserGridSkeleton extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const UserGridSkeleton({
    super.key,
    this.count = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.72,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 100),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const _SkeletonGridCard(),
    );
  }
}

class _SkeletonGridCard extends StatelessWidget {
  const _SkeletonGridCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShimmerSkeleton(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(20),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerSkeleton.line(width: 100, height: 12),
                const SizedBox(height: 6),
                ShimmerSkeleton.line(width: 70, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
