import 'package:flutter/material.dart';

/// Wraps [child] with a double-tap-to-like heart animation overlay.
/// Owns the animation boolean state; fires [onDoubleTap] when triggered.
class MomentCardDoubleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onDoubleTap;

  const MomentCardDoubleTap({
    super.key,
    required this.child,
    required this.onDoubleTap,
  });

  @override
  State<MomentCardDoubleTap> createState() => _MomentCardDoubleTapState();
}

class _MomentCardDoubleTapState extends State<MomentCardDoubleTap> {
  bool _showHeartAnimation = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        widget.onDoubleTap();
        setState(() => _showHeartAnimation = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showHeartAnimation = false);
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeartAnimation)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value < 0.5 ? value * 2 : (1 - value) * 2,
                  child: Transform.scale(
                    scale: 0.5 + value * 0.5,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 80,
                      shadows: [
                        Shadow(blurRadius: 20, color: Colors.black38),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
