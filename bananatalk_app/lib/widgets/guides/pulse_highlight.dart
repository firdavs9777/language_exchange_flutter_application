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
/// When [enabled] is false this is a pass-through: no controller is created
/// and nothing is painted, so the four pages that mount a guide conditionally
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
  AnimationController? _controller;
  int _completed = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _start();
  }

  @override
  void didUpdateWidget(PulseHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A guide can become eligible after its first frame (the state provider
    // resolves asynchronously), so enabling has to start the ring rather
    // than rely on initState having seen the final value.
    if (widget.enabled && _controller == null) {
      _start();
    } else if (!widget.enabled && _controller != null) {
      _stop();
    }
  }

  void _start() {
    _completed = 0;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _completed++;
      if (_completed >= widget.cycles) {
        _stop();
      } else {
        controller.forward(from: 0);
      }
    });
    _controller = controller;
    controller.forward();
  }

  void _stop() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;

    final radius = widget.borderRadius ?? BorderRadius.circular(999);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final t = Curves.easeOut.transform(controller.value);
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
