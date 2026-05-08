import 'package:flutter/material.dart';

/// Typed representation of a story overlay loaded from JSON.
class StoryOverlay {
  final String type; // 'text' | 'emoji'
  final String content;
  final double x; // 0..1
  final double y; // 0..1
  final double scale;
  final double rotation; // degrees
  final String color; // hex like '#FFFFFF'
  final String fontStyle;
  final String bgMode; // 'none' | 'semi' | 'solid'

  const StoryOverlay({
    required this.type,
    required this.content,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0,
    this.color = '#FFFFFF',
    this.fontStyle = 'sans-serif',
    this.bgMode = 'none',
  });

  factory StoryOverlay.fromJson(Map<String, dynamic> json) => StoryOverlay(
        type: json['type']?.toString() ?? 'text',
        content: json['content']?.toString() ?? '',
        x: (json['x'] as num?)?.toDouble() ?? 0.5,
        y: (json['y'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        color: json['color']?.toString() ?? '#FFFFFF',
        fontStyle: json['fontStyle']?.toString() ?? 'sans-serif',
        bgMode: json['bgMode']?.toString() ?? 'none',
      );
}

/// Renders all story overlays (text + emoji) on top of story media.
/// Overlays use normalized 0..1 coordinates resolved against the widget's
/// actual layout size via [LayoutBuilder].
class ViewerOverlayLayer extends StatelessWidget {
  final List<StoryOverlay> overlays;

  const ViewerOverlayLayer({super.key, required this.overlays});

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final padded = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(padded, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (overlays.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (_, constraints) {
        return Stack(
          children: overlays.map((o) {
            final left = o.x * constraints.maxWidth;
            final top = o.y * constraints.maxHeight;
            final color = _parseColor(o.color);

            Widget body;
            if (o.type == 'emoji') {
              // Emoji / sticker — render as plain text with scaled font size
              body = Text(
                o.content,
                style: TextStyle(fontSize: 36 * o.scale),
              );
            } else {
              // Text overlay
              final base = TextStyle(color: color, fontSize: 24 * o.scale);
              final styled = switch (o.fontStyle) {
                'bold' => base.copyWith(fontWeight: FontWeight.bold),
                'serif' => base.copyWith(fontFamily: 'serif'),
                'handwritten' => base.copyWith(
                    fontFamily: 'Caveat',
                    fontStyle: FontStyle.italic,
                  ),
                _ => base.copyWith(fontWeight: FontWeight.w500),
              };
              body = Text(o.content, style: styled);
            }

            // Background decorations
            if (o.bgMode == 'semi') {
              body = Container(
                color: Colors.black.withValues(alpha: 0.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: body,
              );
            } else if (o.bgMode == 'solid') {
              final bgColor = color.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white;
              body = Container(
                color: bgColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: body,
              );
            }

            // Approximate centering: shift left 60px and up 20px so the
            // overlay's centre aligns with the normalized coordinate.
            return Positioned(
              left: left - 60,
              top: top - 20,
              child: Transform.rotate(
                angle: o.rotation * 3.14159265358979 / 180,
                child: body,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
