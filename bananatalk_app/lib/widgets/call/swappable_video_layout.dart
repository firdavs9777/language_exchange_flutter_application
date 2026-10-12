import 'package:flutter/material.dart';

enum PipCorner { topLeft, topRight, bottomLeft, bottomRight }

PipCorner nearestCorner(Offset center, Size area) {
  final left = center.dx < area.width / 2;
  final top = center.dy < area.height / 2;
  if (top) return left ? PipCorner.topLeft : PipCorner.topRight;
  return left ? PipCorner.bottomLeft : PipCorner.bottomRight;
}

/// Full-screen main video with a small self-view that can be dragged (it
/// snaps to the nearest corner) and tapped to swap which feed is big.
///
/// [insets] reserve space the small tile must stay clear of (the call's top
/// and control bars). [swapEnabled] should be false whenever either feed is
/// not a live video, so a swap never leaves a placeholder as the big tile.
class SwappableVideoLayout extends StatefulWidget {
  const SwappableVideoLayout({
    super.key,
    required this.remote,
    this.local,
    this.pipSize = const Size(120, 160),
    this.margin = 20,
    this.insets = EdgeInsets.zero,
    this.swapEnabled = true,
    this.localLabel,
    this.remoteLabel,
    this.swapHint,
  });

  final Widget remote;
  final Widget? local;
  final Size pipSize;
  final double margin;
  final EdgeInsets insets;
  final bool swapEnabled;
  /// Announced when the tile shows the self-view / the peer's video.
  final String? localLabel;
  final String? remoteLabel;
  final String? swapHint;

  @override
  State<SwappableVideoLayout> createState() => _SwappableVideoLayoutState();
}

class _SwappableVideoLayoutState extends State<SwappableVideoLayout> {
  PipCorner _corner = PipCorner.topRight;
  bool _swapped = false;
  Offset? _drag;

  @override
  void didUpdateWidget(SwappableVideoLayout old) {
    super.didUpdateWidget(old);
    // Never let a stale swap re-apply when swapping becomes available again.
    if ((old.swapEnabled && !widget.swapEnabled) || widget.local == null) {
      _swapped = false;
    }
  }

  Rect _bounds(Size area) {
    final m = widget.margin;
    final left = widget.insets.left + m;
    final top = widget.insets.top + m;
    final right = area.width - widget.insets.right - m - widget.pipSize.width;
    final bottom =
        area.height - widget.insets.bottom - m - widget.pipSize.height;
    // A tiny window can leave no room; collapse to the top-left corner.
    return Rect.fromLTRB(
        left, top, right < left ? left : right, bottom < top ? top : bottom);
  }

  Offset _cornerOffset(PipCorner c, Size area) {
    final b = _bounds(area);
    switch (c) {
      case PipCorner.topLeft:
        return b.topLeft;
      case PipCorner.topRight:
        return b.topRight;
      case PipCorner.bottomLeft:
        return b.bottomLeft;
      case PipCorner.bottomRight:
        return b.bottomRight;
    }
  }

  Offset _clamp(Offset p, Size area) {
    final b = _bounds(area);
    return Offset(p.dx.clamp(b.left, b.right), p.dy.clamp(b.top, b.bottom));
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.local;
    final swapped = _swapped && local != null && widget.swapEnabled;
    return LayoutBuilder(builder: (context, constraints) {
      final area = constraints.biggest;
      final main = swapped ? local : widget.remote;
      final small = local == null ? null : (swapped ? widget.remote : local);
      final pos = _drag != null
          ? _clamp(_drag!, area)
          : _cornerOffset(_corner, area);
      return Stack(children: [
        Positioned.fill(
            child: KeyedSubtree(key: const Key('call-main'), child: main)),
        if (small != null)
          AnimatedPositioned(
            duration: _drag == null
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            curve: Curves.easeOut,
            left: pos.dx,
            top: pos.dy,
            width: widget.pipSize.width,
            height: widget.pipSize.height,
            child: Semantics(
              container: true,
              button: true,
              enabled: widget.swapEnabled,
              label: swapped ? widget.remoteLabel : widget.localLabel,
              hint: widget.swapEnabled ? widget.swapHint : null,
              onTap: widget.swapEnabled
                  ? () => setState(() => _swapped = !_swapped)
                  : null,
              excludeSemantics: true,
              child: GestureDetector(
                key: const Key('call-pip'),
                onTap: widget.swapEnabled
                    ? () => setState(() => _swapped = !_swapped)
                    : null,
                onPanUpdate: (d) => setState(
                    () => _drag = _clamp((_drag ?? pos) + d.delta, area)),
                onPanEnd: (_) => setState(() {
                  final p = _clamp(_drag ?? pos, area);
                  _corner = nearestCorner(
                      p +
                          Offset(widget.pipSize.width / 2,
                              widget.pipSize.height / 2),
                      area);
                  _drag = null;
                }),
                onPanCancel: () => setState(() => _drag = null),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: small,
                  ),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}
