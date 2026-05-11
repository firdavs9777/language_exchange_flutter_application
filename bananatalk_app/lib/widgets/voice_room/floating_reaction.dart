import 'package:flutter/material.dart';

/// A short-lived emoji widget that floats up from a fixed screen anchor
/// and fades out. Inserted into the root [Overlay] by
/// [showFloatingReaction] and removes itself when the animation
/// completes.
///
/// Lifecycle: 0–200ms scale-in (elasticOut) -> 0–2000ms translate Y from
/// 0 to -120 (easeOut) -> last 800ms opacity 1->0. The whole reaction
/// lives for 2 seconds.
class FloatingReaction extends StatefulWidget {
  /// Top-left screen-space position the emoji should originate from.
  /// The widget renders at this exact point and animates upward from it.
  final Offset anchor;
  final String emoji;
  final VoidCallback onComplete;

  const FloatingReaction({
    super.key,
    required this.anchor,
    required this.emoji,
    required this.onComplete,
  });

  @override
  State<FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<FloatingReaction>
    with SingleTickerProviderStateMixin {
  static const Duration _totalDuration = Duration(milliseconds: 2000);
  // Translation distance (px) the emoji travels upward over the lifetime.
  static const double _floatDistance = 120;

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _translateY;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // Scale in over the first 200ms (0..0.1 of the timeline) with an
    // elastic-out curve so the emoji "pops".
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 90,
      ),
    ]).animate(_controller);

    // Translate the entire 2000ms with easeOut.
    _translateY = Tween<double>(begin: 0, end: -_floatDistance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Hold opacity 1 for the first 60% then fade to 0 over the last 800ms.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 40,
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(() {
      if (!mounted) return;
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Centre the 40x40 emoji glyph on the anchor.
    return Positioned(
      left: widget.anchor.dx - 20,
      top: widget.anchor.dy - 20,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(0, _translateY.value),
              child: Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scale.value.clamp(0.0, 2.0),
                  child: child,
                ),
              ),
            );
          },
          child: Text(
            widget.emoji,
            style: const TextStyle(
              fontSize: 40,
              // Slight shadow keeps the emoji legible over a colourful
              // avatar background.
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Color(0x66000000),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Insert a [FloatingReaction] into the nearest Overlay, anchored at the
/// given screen-space [anchor] (top-center of the sender's avatar, or a
/// fallback position). The entry removes itself when the animation
/// completes.
void showFloatingReaction({
  required BuildContext context,
  required Offset anchor,
  required String emoji,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => FloatingReaction(
      anchor: anchor,
      emoji: emoji,
      onComplete: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
