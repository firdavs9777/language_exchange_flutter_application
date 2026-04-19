import 'dart:math';
import 'package:flutter/material.dart';

/// A single overlay element that can be dragged, scaled, and rotated
class OverlayElement {
  String type; // 'text' or 'sticker'
  String content;
  Offset position;
  double scale;
  double rotation;
  Color color;
  String fontStyle;
  String bgMode; // 'none', 'semi', 'solid'

  OverlayElement({
    required this.type,
    required this.content,
    this.position = const Offset(0.5, 0.5),
    this.scale = 1.0,
    this.rotation = 0,
    this.color = Colors.white,
    this.fontStyle = 'sans-serif',
    this.bgMode = 'none',
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'content': content,
    'x': position.dx,
    'y': position.dy,
    'scale': scale,
    'rotation': rotation,
    'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'fontStyle': fontStyle,
    'bgMode': bgMode,
  };
}

/// Widget that renders an overlay element with drag, scale, and rotate support
class DraggableOverlay extends StatefulWidget {
  final OverlayElement element;
  final Size containerSize;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool isSelected;

  const DraggableOverlay({
    super.key,
    required this.element,
    required this.containerSize,
    required this.onDelete,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<DraggableOverlay> createState() => _DraggableOverlayState();
}

class _DraggableOverlayState extends State<DraggableOverlay> {
  late Offset _position;
  late double _scale;
  late double _rotation;
  double _baseScale = 1.0;
  double _baseRotation = 0;

  @override
  void initState() {
    super.initState();
    _position = widget.element.position;
    _scale = widget.element.scale;
    _rotation = widget.element.rotation;
  }

  @override
  Widget build(BuildContext context) {
    final left = _position.dx * widget.containerSize.width - 50;
    final top = _position.dy * widget.containerSize.height - 30;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx / widget.containerSize.width).clamp(0.0, 1.0),
              (_position.dy + details.delta.dy / widget.containerSize.height).clamp(0.0, 1.0),
            );
            widget.element.position = _position;
          });
        },
        onScaleStart: (details) {
          _baseScale = _scale;
          _baseRotation = _rotation;
        },
        onScaleUpdate: (details) {
          setState(() {
            _scale = (_baseScale * details.scale).clamp(0.3, 4.0);
            _rotation = _baseRotation + details.rotation;
            widget.element.scale = _scale;
            widget.element.rotation = _rotation;
          });
        },
        child: Transform.rotate(
          angle: _rotation,
          child: Transform.scale(
            scale: _scale,
            child: Container(
              decoration: widget.isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: widget.element.type == 'text'
                  ? _buildTextOverlay()
                  : _buildStickerOverlay(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextOverlay() {
    final e = widget.element;
    Color bgColor;
    switch (e.bgMode) {
      case 'semi':
        bgColor = Colors.black38;
        break;
      case 'solid':
        bgColor = Colors.black87;
        break;
      default:
        bgColor = Colors.transparent;
    }

    TextStyle style;
    switch (e.fontStyle) {
      case 'serif':
        style = TextStyle(fontFamily: 'Serif', color: e.color, fontSize: 20, fontWeight: FontWeight.normal);
        break;
      case 'bold':
        style = TextStyle(color: e.color, fontSize: 20, fontWeight: FontWeight.w900);
        break;
      case 'handwritten':
        style = TextStyle(fontFamily: 'Cursive', color: e.color, fontSize: 20, fontStyle: FontStyle.italic);
        break;
      default:
        style = TextStyle(color: e.color, fontSize: 20, fontWeight: FontWeight.w500);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(e.content, style: style),
    );
  }

  Widget _buildStickerOverlay() {
    return Text(
      widget.element.content,
      style: const TextStyle(fontSize: 64),
    );
  }
}

/// Toolbar for editing text overlay properties
class OverlayToolbar extends StatelessWidget {
  final OverlayElement? selectedElement;
  final VoidCallback onAddText;
  final VoidCallback onAddSticker;
  final ValueChanged<String>? onFontChanged;
  final ValueChanged<Color>? onColorChanged;
  final ValueChanged<String>? onBgModeChanged;
  final VoidCallback? onDelete;

  const OverlayToolbar({
    super.key,
    this.selectedElement,
    required this.onAddText,
    required this.onAddSticker,
    this.onFontChanged,
    this.onColorChanged,
    this.onBgModeChanged,
    this.onDelete,
  });

  static const List<Color> presetColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.pink,
    Colors.purple,
  ];

  static const List<Map<String, String>> fontStyles = [
    {'value': 'sans-serif', 'label': 'Aa'},
    {'value': 'serif', 'label': 'Aa'},
    {'value': 'bold', 'label': 'Aa'},
    {'value': 'handwritten', 'label': 'Aa'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Add text button
          IconButton(
            onPressed: onAddText,
            icon: const Icon(Icons.text_fields, color: Colors.white, size: 28),
          ),
          // Add sticker button
          IconButton(
            onPressed: onAddSticker,
            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white, size: 28),
          ),
          const Spacer(),
          // Color picker (when text selected)
          if (selectedElement?.type == 'text') ...[
            ...presetColors.map((color) => GestureDetector(
              onTap: () => onColorChanged?.call(color),
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedElement?.color == color ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            )),
          ],
          // Delete button
          if (selectedElement != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
            ),
        ],
      ),
    );
  }
}
