// lib/widgets/shimmer_loading.dart
import 'package:flutter/material.dart';

/// A shimmer loading effect widget for skeleton loading states
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: widget.child,
        );
      },
    );
  }
}

/// Pre-built shimmer skeleton shapes
class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerSkeleton({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  /// Circle skeleton (for avatars)
  factory ShimmerSkeleton.circle({required double radius}) {
    return ShimmerSkeleton(
      width: radius * 2,
      height: radius * 2,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Line skeleton (for text)
  factory ShimmerSkeleton.line({
    required double width,
    double height = 16,
  }) {
    return ShimmerSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Card skeleton
  factory ShimmerSkeleton.card({
    required double width,
    required double height,
    double radius = 12,
  }) {
    return ShimmerSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer loading for chat list item
class ChatListItemSkeleton extends StatelessWidget {
  const ChatListItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ShimmerSkeleton.circle(radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton.line(width: 120),
                const SizedBox(height: 8),
                ShimmerSkeleton.line(width: 200, height: 12),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerSkeleton.line(width: 40, height: 12),
              const SizedBox(height: 8),
              ShimmerSkeleton.circle(radius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading for moment card
class MomentCardSkeleton extends StatelessWidget {
  const MomentCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                ShimmerSkeleton.circle(radius: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeleton.line(width: 100),
                    const SizedBox(height: 4),
                    ShimmerSkeleton.line(width: 60, height: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            ShimmerSkeleton.line(width: double.infinity),
            const SizedBox(height: 8),
            ShimmerSkeleton.line(width: 200),
            const SizedBox(height: 12),
            // Image placeholder
            ShimmerSkeleton.card(
              width: double.infinity,
              height: 200,
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                ShimmerSkeleton.line(width: 60, height: 20),
                const SizedBox(width: 16),
                ShimmerSkeleton.line(width: 60, height: 20),
                const SizedBox(width: 16),
                ShimmerSkeleton.line(width: 60, height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading for profile header
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cover image
        ShimmerSkeleton.card(width: double.infinity, height: 150, radius: 0),
        const SizedBox(height: 16),
        // Avatar
        Transform.translate(
          offset: const Offset(0, -50),
          child: ShimmerSkeleton.circle(radius: 50),
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Column(
            children: [
              ShimmerSkeleton.line(width: 150),
              const SizedBox(height: 8),
              ShimmerSkeleton.line(width: 100, height: 14),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerSkeleton.line(width: 60),
                  const SizedBox(width: 32),
                  ShimmerSkeleton.line(width: 60),
                  const SizedBox(width: 32),
                  ShimmerSkeleton.line(width: 60),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer loading for community user card
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ShimmerSkeleton.circle(radius: 35),
          const SizedBox(height: 8),
          ShimmerSkeleton.line(width: 80),
          const SizedBox(height: 4),
          ShimmerSkeleton.line(width: 60, height: 12),
          const SizedBox(height: 8),
          ShimmerSkeleton.line(width: 100, height: 24),
        ],
      ),
    );
  }
}
