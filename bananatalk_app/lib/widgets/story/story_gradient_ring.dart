import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Animated gradient ring for story avatars (Instagram-style)
class StoryGradientRing extends StatefulWidget {
  final Widget child;
  final double size;
  final double strokeWidth;
  final bool isViewed;
  final bool isCloseFriend;
  final bool hasStory;
  final bool isOwnStory;
  final bool animate;

  const StoryGradientRing({
    Key? key,
    required this.child,
    this.size = 64,
    this.strokeWidth = 3,
    this.isViewed = false,
    this.isCloseFriend = false,
    this.hasStory = true,
    this.isOwnStory = false,
    this.animate = true,
  }) : super(key: key);

  @override
  State<StoryGradientRing> createState() => _StoryGradientRingState();
}

class _StoryGradientRingState extends State<StoryGradientRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Instagram-like gradient colors
  static const List<Color> _gradientColors = [
    Color(0xFFFF6B6B), // Red-pink
    Color(0xFFFFE66D), // Yellow
    Color(0xFF4ECDC4), // Teal
    Color(0xFF45B7D1), // Light blue
    Color(0xFF96CEB4), // Mint
    Color(0xFFFF6B6B), // Red-pink (repeat for smooth loop)
  ];

  // Close friends green gradient
  static const List<Color> _closeFriendColors = [
    Color(0xFF00C853),
    Color(0xFF69F0AE),
    Color(0xFF00E676),
    Color(0xFF00C853),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.animate && !widget.isViewed && widget.hasStory && !widget.isOwnStory) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(StoryGradientRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !widget.isViewed && widget.hasStory && !widget.isOwnStory) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasStory) {
      // No story - no ring
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.child,
      );
    }

    if (widget.isOwnStory && !widget.hasStory) {
      // Own story with no content - dashed add ring
      return _buildAddStoryRing(context);
    }

    if (widget.isViewed) {
      // Viewed - gray ring
      return _buildViewedRing(context);
    }

    // Unviewed - animated gradient ring
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientRingPainter(
            colors: widget.isCloseFriend ? _closeFriendColors : _gradientColors,
            strokeWidth: widget.strokeWidth,
            rotation: widget.animate ? _controller.value * 2 * math.pi : 0,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Padding(
              padding: EdgeInsets.all(widget.strokeWidth + 2),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewedRing(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.gray600 : AppColors.gray300,
          width: widget.strokeWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: widget.child,
      ),
    );
  }

  Widget _buildAddStoryRing(BuildContext context) {
    return CustomPaint(
      painter: _DashedRingPainter(
        color: AppColors.primary,
        strokeWidth: widget.strokeWidth,
        dashCount: 12,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Padding(
          padding: EdgeInsets.all(widget.strokeWidth + 2),
          child: widget.child,
        ),
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  final double rotation;

  _GradientRingPainter({
    required this.colors,
    required this.strokeWidth,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Create rotating gradient
    final gradient = SweepGradient(
      colors: colors,
      startAngle: rotation,
      endAngle: rotation + 2 * math.pi,
      tileMode: TileMode.clamp,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.colors != colors ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final dashAngle = 2 * math.pi / dashCount;
    final gapAngle = dashAngle * 0.3;
    final drawAngle = dashAngle - gapAngle;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle - math.pi / 2;
      canvas.drawArc(rect, startAngle, drawAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashCount != dashCount;
  }
}

/// Pulse animation for new story indicator
class StoryPulseRing extends StatefulWidget {
  final Widget child;
  final double size;
  final bool isActive;

  const StoryPulseRing({
    Key? key,
    required this.child,
    this.size = 64,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<StoryPulseRing> createState() => _StoryPulseRingState();
}

class _StoryPulseRingState extends State<StoryPulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(StoryPulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.child,
      );
    }

    return SizedBox(
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(_opacityAnimation.value),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          // Child
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
