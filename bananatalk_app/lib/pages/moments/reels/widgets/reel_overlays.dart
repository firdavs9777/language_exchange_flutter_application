import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Presentation pieces for the full-screen reel viewer, kept out of
/// `reels_feed_screen.dart` so that file stays about feed behaviour rather
/// than animation bookkeeping.

/// Top and bottom scrims.
///
/// The overlay text used to rely on per-`Text` drop shadows, which still
/// disappears against a bright frame. A gradient behind the chrome keeps the
/// back button, author row and caption legible over any video, and reads as
/// deliberate rather than patched.
class ReelScrim extends StatelessWidget {
  const ReelScrim({super.key, required this.alignment});

  /// [Alignment.topCenter] or [Alignment.bottomCenter].
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final fromTop = alignment == Alignment.topCenter;
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          height: fromTop ? 140 : 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
              end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: fromTop ? 0.55 : 0.70),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim playback bar pinned to the bottom edge, with drag-to-scrub.
///
/// Rebuilds off the controller's own listener rather than the feed's state so
/// a position tick never rebuilds the whole page.
class ReelProgressBar extends StatefulWidget {
  const ReelProgressBar({super.key, required this.controller});

  final VideoPlayerController? controller;

  @override
  State<ReelProgressBar> createState() => _ReelProgressBarState();
}

class _ReelProgressBarState extends State<ReelProgressBar> {
  bool _dragging = false;
  double _dragFraction = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_tick);
  }

  @override
  void didUpdateWidget(ReelProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_tick);
      widget.controller?.addListener(_tick);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted && !_dragging) setState(() {});
  }

  void _seekToFraction(double fraction) {
    final controller = widget.controller;
    final total = controller?.value.duration;
    if (controller == null || total == null || total == Duration.zero) return;
    final clamped = fraction.clamp(0.0, 1.0);
    controller.seekTo(
      Duration(milliseconds: (total.inMilliseconds * clamped).round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final value = controller?.value;
    final total = value?.duration ?? Duration.zero;
    final ready = value != null && value.isInitialized && total > Duration.zero;

    final playedFraction = !ready
        ? 0.0
        : _dragging
            ? _dragFraction
            : (value.position.inMilliseconds / total.inMilliseconds)
                .clamp(0.0, 1.0);

    // A generous invisible hit area over a hairline bar: easy to grab without
    // a chunky control sitting on top of the video.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void updateFromDx(double dx) {
          setState(() => _dragFraction = (dx / width).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: ready
              ? (details) {
                  setState(() {
                    _dragging = true;
                    _dragFraction = playedFraction;
                  });
                  updateFromDx(details.localPosition.dx);
                }
              : null,
          onHorizontalDragUpdate:
              ready ? (details) => updateFromDx(details.localPosition.dx) : null,
          onHorizontalDragEnd: ready
              ? (_) {
                  _seekToFraction(_dragFraction);
                  setState(() => _dragging = false);
                }
              : null,
          child: SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: _dragging ? 5 : 2.5,
                child: Stack(
                  children: [
                    Container(color: Colors.white.withValues(alpha: 0.28)),
                    FractionallySizedBox(
                      widthFactor: playedFraction,
                      child: Container(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The heart that blooms where you double-tapped.
///
/// Positioned at the tap point rather than screen centre — that's what makes
/// the gesture feel like it landed on the video instead of firing a generic
/// animation.
class ReelHeartBurst extends StatefulWidget {
  const ReelHeartBurst({super.key, required this.at, required this.onDone});

  final Offset at;
  final VoidCallback onDone;

  @override
  State<ReelHeartBurst> createState() => _ReelHeartBurstState();
}

class _ReelHeartBurstState extends State<ReelHeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 850),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Overshoot then settle, drifting upward while fading — a flat linear
    // scale is what makes these animations look cheap.
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(_c);

    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_c);

    final rise = Tween<double>(begin: 0, end: -46)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_c);

    return Positioned(
      left: widget.at.dx - 50,
      top: widget.at.dy - 50,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Transform.translate(
            offset: Offset(0, rise.value),
            child: Transform.scale(
              scale: scale.value,
              child: Opacity(
                opacity: opacity.value,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 100,
                    shadows: [Shadow(blurRadius: 18, color: Colors.black45)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Play/pause confirmation: a glyph that pops and fades instead of a static
/// icon parked over the frame, so the tap visibly registers.
class ReelPlayPauseFlash extends StatelessWidget {
  const ReelPlayPauseFlash({
    super.key,
    required this.isPaused,
    required this.showPersistent,
  });

  /// True when the video is paused (glyph = play).
  final bool isPaused;

  /// While paused the glyph stays put, so it's obvious the reel is stopped
  /// rather than stalled on a slow network.
  final bool showPersistent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedScale(
          scale: showPersistent ? 1.0 : 1.35,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: showPersistent ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round translucent toggle used for the sound control.
class ReelCircleButton extends StatelessWidget {
  const ReelCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
