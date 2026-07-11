import 'package:flutter/material.dart';

/// Full-bleed backdrop for auth screens: a slow-drifting teal→banana gradient
/// that gently shifts alignment over 20 seconds (repeat + reverse), rendered
/// behind [child]. Colors flip for dark mode. Honors
/// `MediaQuery.disableAnimations` (reduce-motion) by holding a static
/// gradient instead of animating.
class AnimatedAuthBackground extends StatefulWidget {
  final Widget child;

  const AnimatedAuthBackground({super.key, required this.child});

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _lightColors = [Color(0xFFE0F7F4), Color(0xFFFFF8E1)];
  static const _darkColors = [Color(0xFF00BFA5), Color(0xFF00897B)];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? _darkColors : _lightColors;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (disableAnimations)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          )
        else
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final begin = Alignment.lerp(
                Alignment.topLeft,
                Alignment.bottomLeft,
                t,
              )!;
              final end = Alignment.lerp(
                Alignment.bottomRight,
                Alignment.topRight,
                t,
              )!;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: begin,
                    end: end,
                    colors: colors,
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}
