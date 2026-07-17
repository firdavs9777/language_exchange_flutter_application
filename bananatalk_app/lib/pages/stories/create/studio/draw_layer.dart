import 'package:flutter/material.dart';

class DrawStroke {
  DrawStroke({
    required this.color,
    required this.width,
    required this.highlighter,
  });
  final List<Offset> points = [];
  final Color color;
  final double width;
  final bool highlighter;
}

class DrawLayer extends StatefulWidget {
  const DrawLayer({
    super.key,
    required this.strokes,
    required this.enabled,
    required this.color,
    required this.width,
    required this.highlighter,
    required this.onChanged,
  });
  final List<DrawStroke> strokes;
  final bool enabled;
  final Color color;
  final double width;
  final bool highlighter;
  final VoidCallback onChanged;

  @override
  State<DrawLayer> createState() => _DrawLayerState();
}

class _DrawLayerState extends State<DrawLayer> {
  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      painter: _StrokesPainter(widget.strokes),
      size: Size.infinite,
    );
    if (!widget.enabled) return IgnorePointer(child: painter);
    return GestureDetector(
      onPanStart: (d) => setState(() {
        widget.strokes.add(DrawStroke(
            color: widget.color,
            width: widget.width,
            highlighter: widget.highlighter)
          ..points.add(d.localPosition));
      }),
      onPanUpdate: (d) =>
          setState(() => widget.strokes.last.points.add(d.localPosition)),
      onPanEnd: (_) => widget.onChanged(),
      child: painter,
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter(this.strokes);
  final List<DrawStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.highlighter ? s.color.withValues(alpha: 0.45) : s.color
        ..strokeWidth = s.highlighter ? s.width * 2.2 : s.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < s.points.length; i++) {
        if (i == 0) {
          path.moveTo(s.points[i].dx, s.points[i].dy);
        } else {
          path.lineTo(s.points[i].dx, s.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) => true;
}

class DrawToolbar extends StatelessWidget {
  const DrawToolbar({
    super.key,
    required this.color,
    required this.width,
    required this.highlighter,
    required this.onColor,
    required this.onWidth,
    required this.onHighlighter,
    required this.onUndo,
  });
  final Color color;
  final double width;
  final bool highlighter;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onWidth;
  final ValueChanged<bool> onHighlighter;
  final VoidCallback onUndo;

  static const _colors = [
    Colors.white, Colors.black, Color(0xFFFFD54F), Color(0xFF00BFA5),
    Color(0xFFFF5252), Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(children: [
        IconButton(
            onPressed: onUndo,
            icon: const Icon(Icons.undo_rounded, color: Colors.white)),
        IconButton(
          onPressed: () => onHighlighter(!highlighter),
          icon: Icon(
              highlighter ? Icons.border_color_rounded : Icons.edit_rounded,
              color: highlighter ? const Color(0xFFFFD54F) : Colors.white),
        ),
        Expanded(
          child: Slider(
            value: width,
            min: 2,
            max: 14,
            activeColor: const Color(0xFF00BFA5),
            onChanged: onWidth,
          ),
        ),
        for (final c in _colors)
          GestureDetector(
            onTap: () => onColor(c),
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                    color: color == c ? const Color(0xFF00BFA5) : Colors.white,
                    width: color == c ? 2.5 : 1),
              ),
            ),
          ),
      ]),
    );
  }
}
