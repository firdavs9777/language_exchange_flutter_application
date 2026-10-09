import 'package:flutter/material.dart';

/// How many times the ring expands before it goes quiet.
///
/// Finite on purpose, for two reasons. An animation that never stops keeps a
/// frame callback alive for as long as the page is on screen, and a button
/// that pulses forever reads as broken rather than inviting. Three passes is
/// enough to catch the eye on arrival.
const int kPulseCycles = 3;

/// Draws an expanding ring behind [child] to draw the eye to it.
///
/// Used to highlight the one button a guide is pointing at. The ring is
/// painted in a sibling layer under an [IgnorePointer], so it never changes
/// the child's size, hit area or layout — wrapping a button in this cannot
/// make the button stop working.
///
/// When [enabled] is false this is a pass-through: nothing is painted and the
/// controller never runs, so the four pages that mount a guide conditionally
/// pay nothing when the guide is not showing.
class PulseHighlight extends StatefulWidget {
  const PulseHighlight({
    super.key,
    required this.child,
    required this.color,
    this.enabled = true,
    this.borderRadius,
    this.cycles = kPulseCycles,
  });

  final Widget child;
  final Color color;
  final bool enabled;
  final BorderRadius? borderRadius;
  final int cycles;

  @override
  State<PulseHighlight> createState() => _PulseHighlightState();
}

class _PulseHighlightState extends State<PulseHighlight>
    with SingleTickerProviderStateMixin {
  /// Built once in initState and kept for the life of the State, whether or
  /// not it ever runs.
  ///
  /// An earlier version disposed it when the ring finished and recreated it
  /// on demand, which crashed on device within seconds of this shipping:
  /// `SingleTickerProviderStateMixin` hands out ONE ticker per State for its
  /// whole lifetime, disposed or not, so the second controller threw
  /// "multiple tickers were created" mid-build and took the page's layout
  /// with it. Guides sit at the top of pages that rebuild constantly.
  late final AnimationController _controller;

  int _completed = 0;

  /// The ring is currently expanding. Drives the painting, so a finished or
  /// never-started ring renders [PulseHighlight.child] untouched.
  bool _running = false;

  /// The ring has had its [PulseHighlight.cycles] passes on this State.
  ///
  /// Separate from `_running` because "not animating" and "already done" must
  /// not look the same: the old code could not tell them apart, so every
  /// rebuild of an enabled guide looked like a fresh start and the ring
  /// pulsed forever — the exact thing the cycle cap exists to prevent.
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addStatusListener(_onStatus);
    if (widget.enabled) {
      _running = true;
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _completed++;
    if (_completed < widget.cycles) {
      _controller.forward(from: 0);
      return;
    }
    _finished = true;
    if (mounted) setState(() => _running = false);
  }

  @override
  void didUpdateWidget(PulseHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a CHANGE in `enabled` means anything. A guide can become eligible
    // after its first frame -- the stored state resolves asynchronously, and
    // MatchCard is built with highlightSayHi false until the panel above it
    // decides to show -- so the ring has to be able to start late. Every
    // other rebuild must leave it exactly as it is.
    if (widget.enabled == oldWidget.enabled) return;

    if (widget.enabled) {
      if (_finished) return;
      _running = true;
      _controller.forward(from: 0);
    } else {
      _controller.stop();
      _running = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) return widget.child;

    final radius = widget.borderRadius ?? BorderRadius.circular(999);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_controller.value);
                return Transform.scale(
                  scale: 1 + 0.22 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.55 * (1 - t)),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
