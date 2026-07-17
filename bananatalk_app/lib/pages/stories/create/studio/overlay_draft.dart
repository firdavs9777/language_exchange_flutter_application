/// Mutable draft of one story overlay while editing on the canvas.
/// Serializes 1:1 into the backend `Story.overlays[]` schema; the immutable
/// render-side twin is `StoryOverlay` in story_model.dart.
class OverlayDraft {
  OverlayDraft({
    this.type = 'text',
    required this.content,
    this.x = 0.5,
    this.y = 0.4,
    this.scale = 1.0,
    this.color = '#FFFFFF',
    this.fontStyle = 'sans-serif',
    this.bgMode = 'none',
  });

  String type; // 'text' | 'emoji'
  String content;
  double x; // 0..1 fraction of canvas width (centre of overlay)
  double y; // 0..1 fraction of canvas height
  double scale; // 0.5..3.0
  String color; // #RRGGBB
  String fontStyle; // sans-serif | serif | bold | handwritten
  String bgMode; // none | semi | solid

  void clamp() {
    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
    scale = scale.clamp(0.5, 3.0);
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'x': x,
        'y': y,
        'scale': scale,
        'color': color,
        'fontStyle': fontStyle,
        'bgMode': bgMode,
      };
}
