import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bananatalk_app/pages/stories/create/studio/overlay_draft.dart';

Color hexColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFFFFFFFF);
}

TextStyle overlayTextStyle(OverlayDraft d, {double base = 26}) {
  final color = hexColor(d.color);
  switch (d.fontStyle) {
    case 'serif':
      return GoogleFonts.playfairDisplay(fontSize: base, color: color);
    case 'bold':
      return TextStyle(
        fontSize: base,
        color: color,
        fontWeight: FontWeight.w900,
      );
    case 'handwritten':
      return GoogleFonts.caveat(fontSize: base + 6, color: color);
    default:
      return TextStyle(
        fontSize: base,
        color: color,
        fontWeight: FontWeight.w600,
      );
  }
}

/// Interactive editing surface: background + positioned overlay drafts.
class StoryCanvas extends StatefulWidget {
  const StoryCanvas({
    super.key,
    required this.overlays,
    required this.background,
    required this.onChanged,
    required this.onEditText,
    this.interactive = true,
  });

  final List<OverlayDraft> overlays;
  final Widget background;
  final VoidCallback onChanged;
  final void Function(OverlayDraft draft) onEditText;

  /// When false, the canvas becomes a passive render surface: the
  /// background's tap-to-add-overlay is disabled and existing overlays are
  /// wrapped in [IgnorePointer] so their drag/pinch/tap gestures don't
  /// compete with a gesture layer living inside [background] (e.g. the
  /// story studio's freehand draw mode, which needs pan gestures to reach a
  /// `DrawLayer` painted inside the background instead of being intercepted
  /// here). Defaults to true (today's fully-interactive behavior).
  final bool interactive;

  @override
  State<StoryCanvas> createState() => _StoryCanvasState();
}

class _StoryCanvasState extends State<StoryCanvas> {
  OverlayDraft? _active;
  bool _overTrash = false;
  double _startScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: !widget.interactive
                  ? null
                  : () {
                      final draft = OverlayDraft(content: '');
                      setState(() => widget.overlays.add(draft));
                      widget.onChanged();
                      widget.onEditText(draft);
                    },
              child: widget.background,
            ),
            // Empty-canvas affordance: hints that the background itself is
            // tappable to add the first overlay. Non-interactive so taps
            // pass straight through to the GestureDetector above.
            if (widget.overlays.isEmpty)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      'Tap anywhere to add text',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            for (final d in widget.overlays)
              widget.interactive
                  ? _buildOverlay(d, size)
                  : IgnorePointer(child: _buildOverlay(d, size)),
            if (_active != null)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _overTrash ? Colors.red : Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlay(OverlayDraft d, Size size) {
    final child = Transform.scale(
      scale: d.scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: d.bgMode == 'none'
            ? null
            : BoxDecoration(
                color: d.bgMode == 'solid'
                    ? Colors.black.withValues(alpha: 0.75)
                    : Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
        child: Text(
          d.content,
          textAlign: TextAlign.center,
          style: d.type == 'emoji'
              ? const TextStyle(fontSize: 44)
              : overlayTextStyle(d),
        ),
      ),
    );

    return Positioned(
      left: d.x * size.width - 150,
      top: d.y * size.height - 40,
      child: SizedBox(
        width: 300,
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onEditText(d),
            onScaleStart: (_) => setState(() {
              _active = d;
              _startScale = d.scale;
            }),
            onScaleUpdate: (u) => setState(() {
              d.x += u.focalPointDelta.dx / size.width;
              d.y += u.focalPointDelta.dy / size.height;
              d.scale = _startScale * u.scale;
              d.clamp();
              // Trash hit-test: bottom-centre 72px square.
              final fp = u.focalPoint;
              _overTrash =
                  fp.dy > size.height - 96 &&
                  (fp.dx - size.width / 2).abs() < 48;
            }),
            onScaleEnd: (_) => setState(() {
              if (_overTrash) widget.overlays.remove(d);
              _active = null;
              _overTrash = false;
              widget.onChanged();
            }),
            child: child,
          ),
        ),
      ),
    );
  }
}
