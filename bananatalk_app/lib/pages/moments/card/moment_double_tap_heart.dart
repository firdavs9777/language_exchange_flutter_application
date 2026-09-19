import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show TickerCanceled;

/// Wraps media so a double-tap likes it, with a heart that says so.
///
/// The gesture already worked before this existed; what was missing was any
/// feedback at all. A gesture with no response reads as one that did not
/// register, so people tap again — which, on a toggle, un-likes.
class MomentDoubleTapHeart extends StatefulWidget {
  const MomentDoubleTapHeart({
    super.key,
    required this.child,
    required this.isLiked,
    required this.onLike,
  });

  final Widget child;

  /// When true the double-tap does nothing at all.
  ///
  /// A double-tap is a LIKE gesture, not a toggle: making it un-like turns an
  /// enthusiastic second tap into an undo, and animating a removal confirms
  /// the wrong action.
  final bool isLiked;

  final VoidCallback onLike;

  @override
  State<MomentDoubleTapHeart> createState() => _MomentDoubleTapHeartState();
}

class _MomentDoubleTapHeartState extends State<MomentDoubleTapHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _showing = false;

  @override
  void initState() {
    super.initState();
    // Built here rather than as a `late final` initialiser. A lazy field is
    // first touched in dispose() when the burst never ran -- an already-liked
    // moment returns early -- and constructing a ticker at teardown looks up
    // TickerMode on a deactivated element.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDoubleTap() async {
    if (widget.isLiked) return;
    widget.onLike();

    // Read BEFORE any await: after one, this State may be looking up an
    // ancestor of a widget that has since been deactivated.
    // The same check otp_code_field.dart makes — the action still happens,
    // only the motion is skipped.
    if (MediaQuery.of(context).disableAnimations) return;

    setState(() => _showing = true);
    try {
      await _controller.forward(from: 0);
    } on TickerCanceled {
      // The widget left the tree mid-burst. Nothing to clean up beyond the
      // flag below, and nothing worth surfacing.
    }
    if (mounted) setState(() => _showing = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opaque, not the default deferToChild: the media area must absorb the
      // double-tap across its whole frame, including any transparent region.
      // With deferToChild a tap landing on a gap between painted pixels does
      // nothing at all.
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showing)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  // Up fast, then fade — the shape of a reaction rather than a
                  // progress indicator.
                  final scale = 0.6 + (t < 0.3 ? t / 0.3 : 1.0) * 0.6;
                  final opacity = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4);
                  return Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.favorite,
                        key: Key('double-tap-heart'),
                        color: Colors.white,
                        size: 92,
                        shadows: [
                          Shadow(color: Colors.black38, blurRadius: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
