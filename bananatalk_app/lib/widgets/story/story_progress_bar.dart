import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Segmented progress bar for story viewer (Instagram-style)
class StoryProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentSegment;
  final double currentProgress;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double spacing;

  const StoryProgressBar({
    Key? key,
    required this.totalSegments,
    required this.currentSegment,
    this.currentProgress = 0.0,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x4DFFFFFF),
    this.height = 2.5,
    this.spacing = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSegments, (index) {
        final isCompleted = index < currentSegment;
        final isCurrent = index == currentSegment;
        final isUpcoming = index > currentSegment;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: Stack(
                children: [
                  // Background
                  Container(
                    color: inactiveColor,
                  ),
                  // Progress
                  if (isCompleted || isCurrent)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: isCompleted ? 1.0 : currentProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Animated progress bar that auto-advances
class AnimatedStoryProgressBar extends StatefulWidget {
  final int totalSegments;
  final int currentSegment;
  final Duration segmentDuration;
  final VoidCallback? onSegmentComplete;
  final bool isPaused;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedStoryProgressBar({
    Key? key,
    required this.totalSegments,
    required this.currentSegment,
    this.segmentDuration = const Duration(seconds: 5),
    this.onSegmentComplete,
    this.isPaused = false,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x4DFFFFFF),
  }) : super(key: key);

  @override
  State<AnimatedStoryProgressBar> createState() => _AnimatedStoryProgressBarState();
}

class _AnimatedStoryProgressBarState extends State<AnimatedStoryProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.segmentDuration,
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSegmentComplete?.call();
      }
    });

    if (!widget.isPaused) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedStoryProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle pause/resume
    if (widget.isPaused && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.isPaused && !_controller.isAnimating) {
      _controller.forward();
    }

    // Handle segment change
    if (widget.currentSegment != oldWidget.currentSegment) {
      _controller.reset();
      if (!widget.isPaused) {
        _controller.forward();
      }
    }

    // Handle duration change
    if (widget.segmentDuration != oldWidget.segmentDuration) {
      _controller.duration = widget.segmentDuration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return StoryProgressBar(
          totalSegments: widget.totalSegments,
          currentSegment: widget.currentSegment,
          currentProgress: _controller.value,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
        );
      },
    );
  }
}

/// Linear progress indicator with smooth animation
class SmoothLinearProgress extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final Color valueColor;
  final double height;
  final Duration animationDuration;

  const SmoothLinearProgress({
    Key? key,
    required this.value,
    this.backgroundColor = const Color(0x4DFFFFFF),
    this.valueColor = Colors.white,
    this.height = 2.5,
    this.animationDuration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: AnimatedFractionallySizedBox(
          duration: animationDuration,
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: valueColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated fraction sized box for smooth progress
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final AlignmentGeometry alignment;
  final double? widthFactor;
  final double? heightFactor;
  final Widget? child;

  const AnimatedFractionallySizedBox({
    Key? key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    this.child,
    required Duration duration,
    Curve curve = Curves.linear,
  }) : super(key: key, duration: duration, curve: curve);

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  AlignmentGeometryTween? _alignment;
  Tween<double>? _widthFactor;
  Tween<double>? _heightFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _alignment = visitor(
      _alignment,
      widget.alignment,
      (dynamic value) => AlignmentGeometryTween(begin: value as AlignmentGeometry),
    ) as AlignmentGeometryTween?;

    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;

    _heightFactor = visitor(
      _heightFactor,
      widget.heightFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: _alignment?.evaluate(animation) ?? widget.alignment,
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      heightFactor: _heightFactor?.evaluate(animation) ?? widget.heightFactor,
      child: widget.child,
    );
  }
}
