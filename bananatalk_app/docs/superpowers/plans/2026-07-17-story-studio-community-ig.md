# Story Studio + IG-style Community Detail + Moments Freshness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild story creation into an Instagram-grade editor (movable/colored text, filters, drawing, location, mentions, in-app sharing), restyle community detail IG-style with story rings in the community list, and make the moments feed self-refresh.

**Architecture:** The app model (`StoryOverlay`, `StoryMention`, `StoryLocation`), `StoriesService.createStory(overlays/mentions/location)`, the viewer's `ViewerOverlayLayer`, and backend `POST /stories/:id/share` (DM mode) ALREADY exist. The work is: a new `lib/pages/stories/create/studio/` editor module feeding those existing pipes; small additive backend parsers (mentions, location, overlays-on-video/text); a privacy-aware `hasActiveStory` flag; UI restyles; provider freshness.

**Tech Stack:** Flutter + Riverpod, existing deps only (`image_cropper`, `geolocator`, `geocoding`, `shared_preferences`). Backend Node/Express + Mongoose, `node --test` suite.

## Global Constraints

- `package:` imports only in Dart; new editor files live under `lib/pages/stories/create/studio/`
- Design tokens: teal `#00BFA5`, banana `#FFD54F`; dark-mode parity on all new UI
- Backend changes are additive — old app versions must keep working
- Overlay clamps mirror backend schema: x,y ∈ [0,1], scale ∈ [0.5,3.0]
- `flutter analyze` 0 errors/warnings on touched files; backend `node --check` + tests pass
- Do not start the backend server locally (config.env → production Mongo)
- Commit per task; trailer: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- App repo: `/Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app`; backend: `../backend`

---

### Task 1: Overlay draft model (editable canvas state)

**Files:**
- Create: `lib/pages/stories/create/studio/overlay_draft.dart`
- Test: `test/stories/overlay_draft_test.dart`

**Interfaces:**
- Produces: `class OverlayDraft { String type; String content; double x, y, scale; String color; String fontStyle; String bgMode; Map<String, dynamic> toJson(); }` with named ctor defaults (`type:'text'`, `x:0.5`, `y:0.4`, `scale:1.0`, `color:'#FFFFFF'`, `fontStyle:'sans-serif'`, `bgMode:'none'`) and `void clamp()` enforcing the global bounds. Tasks 2–4 consume this exact shape; `toJson()` keys match backend `overlays[]` schema (`type,content,x,y,scale,color,fontStyle,bgMode`).

- [ ] **Step 1: Write the failing test**

```dart
// test/stories/overlay_draft_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/stories/create/studio/overlay_draft.dart';

void main() {
  test('defaults + toJson match backend schema keys', () {
    final d = OverlayDraft(content: 'hello');
    final j = d.toJson();
    expect(j['type'], 'text');
    expect(j['content'], 'hello');
    expect(j['x'], 0.5);
    expect(j['y'], 0.4);
    expect(j['scale'], 1.0);
    expect(j['color'], '#FFFFFF');
    expect(j['fontStyle'], 'sans-serif');
    expect(j['bgMode'], 'none');
  });

  test('clamp enforces x,y in [0,1] and scale in [0.5,3.0]', () {
    final d = OverlayDraft(content: 'x')
      ..x = 1.4
      ..y = -0.2
      ..scale = 9;
    d.clamp();
    expect(d.x, 1.0);
    expect(d.y, 0.0);
    expect(d.scale, 3.0);
    d.scale = 0.1;
    d.clamp();
    expect(d.scale, 0.5);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stories/overlay_draft_test.dart`
Expected: FAIL — `overlay_draft.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/pages/stories/create/studio/overlay_draft.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stories/overlay_draft_test.dart` → PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/stories/create/studio/overlay_draft.dart test/stories/overlay_draft_test.dart
git commit -m "feat(story-studio): OverlayDraft model with backend-schema serialization"
```

---

### Task 2: StoryCanvas — drag / pinch / tap-to-add / drag-to-trash

**Files:**
- Create: `lib/pages/stories/create/studio/story_canvas.dart`

**Interfaces:**
- Consumes: `OverlayDraft` (Task 1).
- Produces: `class StoryCanvas extends StatefulWidget { final List<OverlayDraft> overlays; final Widget background; final VoidCallback onChanged; final void Function(OverlayDraft) onEditText; }` — renders `background` full-bleed with overlays positioned by fraction, supports drag (updates x/y), pinch (scale), tap overlay → `onEditText(draft)`, tap empty canvas → `onEditText(new draft)` after appending it, and a bottom trash zone that removes an overlay dropped on it. Font mapping helper `TextStyle overlayTextStyle(OverlayDraft d, {double base = 26})` is exported for reuse by the toolbar preview.

- [ ] **Step 1: Implement the widget**

```dart
// lib/pages/stories/create/studio/story_canvas.dart
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
          fontSize: base, color: color, fontWeight: FontWeight.w900);
    case 'handwritten':
      return GoogleFonts.caveat(fontSize: base + 6, color: color);
    default:
      return TextStyle(
          fontSize: base, color: color, fontWeight: FontWeight.w600);
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
  });

  final List<OverlayDraft> overlays;
  final Widget background;
  final VoidCallback onChanged;
  final void Function(OverlayDraft draft) onEditText;

  @override
  State<StoryCanvas> createState() => _StoryCanvasState();
}

class _StoryCanvasState extends State<StoryCanvas> {
  OverlayDraft? _active;
  bool _overTrash = false;
  double _startScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      return Stack(fit: StackFit.expand, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final draft = OverlayDraft(content: '');
            widget.overlays.add(draft);
            widget.onEditText(draft);
          },
          child: widget.background,
        ),
        for (final d in widget.overlays) _buildOverlay(d, size),
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
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white),
              ),
            ),
          ),
      ]);
    });
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
              _overTrash = fp.dy > size.height - 96 &&
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
```

- [ ] **Step 2: Verify + commit**

Run: `flutter analyze lib/pages/stories/create/studio/` → 0 issues.

```bash
git add lib/pages/stories/create/studio/story_canvas.dart
git commit -m "feat(story-studio): interactive canvas — drag, pinch, tap-to-add, drag-to-trash"
```

---

### Task 3: Text editing sheet — content, 12 colors, 4 font styles, bg mode, emoji

**Files:**
- Create: `lib/pages/stories/create/studio/text_overlay_editor.dart`

**Interfaces:**
- Consumes: `OverlayDraft`, `overlayTextStyle` (Tasks 1–2).
- Produces: `Future<void> showTextOverlayEditor(BuildContext context, OverlayDraft draft, {required VoidCallback onDone, required VoidCallback onDeleteEmpty})` — full-screen dark sheet: TextField bound to `draft.content`, horizontal color swatches (12), font-style chips, bg-mode cycle button, emoji quick row (converts draft to `type:'emoji'` with the emoji as content). Closing with empty text calls `onDeleteEmpty` (canvas removes the draft).

- [ ] **Step 1: Implement**

```dart
// lib/pages/stories/create/studio/text_overlay_editor.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/stories/create/studio/overlay_draft.dart';
import 'package:bananatalk_app/pages/stories/create/studio/story_canvas.dart';

const _swatches = [
  '#FFFFFF', '#000000', '#FFD54F', '#00BFA5', '#FF5252', '#FF9800',
  '#4CAF50', '#2196F3', '#9C27B0', '#E91E63', '#795548', '#9E9E9E',
];
const _fontStyles = ['sans-serif', 'serif', 'bold', 'handwritten'];
const _quickEmojis = ['😂', '😍', '🔥', '🎉', '💯', '🙌', '😭', '🍌'];

Future<void> showTextOverlayEditor(
  BuildContext context,
  OverlayDraft draft, {
  required VoidCallback onDone,
  required VoidCallback onDeleteEmpty,
}) {
  final controller = TextEditingController(text: draft.content);
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black87,
    pageBuilder: (context, _, __) => StatefulBuilder(
      builder: (context, setState) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            TextButton(
              onPressed: () {
                draft.content = controller.text.trim();
                if (draft.content.isEmpty) {
                  onDeleteEmpty();
                } else {
                  onDone();
                }
                Navigator.pop(context);
              },
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: overlayTextStyle(draft, base: 30),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 40,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final e in _quickEmojis)
                        GestureDetector(
                          onTap: () {
                            draft
                              ..type = 'emoji'
                              ..content = e;
                            onDone();
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(e, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                    ]),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      IconButton(
                        icon: Icon(
                          draft.bgMode == 'none'
                              ? Icons.format_color_text_rounded
                              : Icons.font_download_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() {
                          draft.bgMode = draft.bgMode == 'none'
                              ? 'semi'
                              : draft.bgMode == 'semi'
                                  ? 'solid'
                                  : 'none';
                        }),
                      ),
                      for (final f in _fontStyles)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: draft.fontStyle == f,
                            onSelected: (_) =>
                                setState(() => draft.fontStyle = f),
                          ),
                        ),
                    ]),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    children: [
                      for (final s in _swatches)
                        GestureDetector(
                          onTap: () => setState(() => draft.color = s),
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: hexColor(s),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: draft.color == s
                                      ? const Color(0xFF00BFA5)
                                      : Colors.white,
                                  width: draft.color == s ? 3 : 1.5),
                            ),
                          ),
                        ),
                    ]),
              ),
            ]),
          ),
        ]),
      ),
    ),
  );
}
```

- [ ] **Step 2: Verify + commit**

Run: `flutter analyze lib/pages/stories/create/studio/` → 0 issues.

```bash
git add lib/pages/stories/create/studio/text_overlay_editor.dart
git commit -m "feat(story-studio): text editor sheet — colors, font styles, bg mode, emoji"
```

---

### Task 4: Wire studio into create screen; overlays on ALL backend create paths

**Files:**
- Modify: `lib/pages/stories/create/create_story_screen.dart` (text-type compose block ~lines 320–390 and preview stage)
- Modify: `../backend/controllers/stories.js` (video path ~line 352-406 and text path: accept `overlays` exactly like image path line 277/329)

**Interfaces:**
- Consumes: `StoryCanvas`, `showTextOverlayEditor`, `OverlayDraft`.
- Produces: create screen holds `final List<OverlayDraft> _overlays = [];` and posts `overlays: _overlays.map((o) => o.toJson()).toList()` through the EXISTING `StoriesService.createStory(overlays: ...)` param for image, video, and text stories. The hardcoded single overlay (`textColor: '#FFFFFF'`, screen line ~351) is deleted.

- [ ] **Step 1 (backend): accept overlays on video/text create paths**

In `../backend/controllers/stories.js`, in the video-create handler (the block starting ~line 352) and the text-create handler, add the same line used by the image path:

```javascript
const overlays = Array.isArray(req.body.overlays) ? req.body.overlays : [];
```

and include `overlays,` in the corresponding `Story.create({...})` call (mirror of line 329).

Run: `node --check controllers/stories.js` → OK. Commit (backend repo):

```bash
git add controllers/stories.js
git commit -m "feat(stories): accept overlays on video and text create paths (parity with image)"
```

- [ ] **Step 2 (app): replace the single-text-overlay flow with the canvas**

In `create_story_screen.dart`:
1. Import the three studio files; add `final List<OverlayDraft> _overlays = [];`.
2. Wrap the media/text preview stage in `StoryCanvas(overlays: _overlays, background: <existing preview widget>, onChanged: () => setState(() {}), onEditText: _editOverlay)` where:

```dart
void _editOverlay(OverlayDraft draft) {
  showTextOverlayEditor(
    context,
    draft,
    onDone: () => setState(() {}),
    onDeleteEmpty: () => setState(() => _overlays.remove(draft)),
  );
}
```

3. Delete the `_textOverlayController`-based block that builds the hardcoded `textColor: '#FFFFFF'` overlay (~line 326–351); pass instead, on every `createStory(...)` call site (image, video, text):

```dart
overlays: _overlays.map((o) => o.toJson()).toList(),
```

- [ ] **Step 3: Verify + commit**

Run: `flutter analyze lib/pages/stories/create/` → 0 issues. Manual: create a text story with 2 moved/re-colored texts → view it → overlays render at matching positions (viewer already renders `overlays[]`).

```bash
git add lib/pages/stories/create/
git commit -m "feat(story-studio): canvas editor wired into create screen; multi-overlay post"
```

---

### Task 5: Filters + crop

**Files:**
- Create: `lib/pages/stories/create/studio/filter_bar.dart`
- Modify: `lib/pages/stories/create/create_story_screen.dart` (image preview + upload path)

**Interfaces:**
- Produces: `class StoryFilter { final String name; final List<double>? matrix; }`, `const List<StoryFilter> kStoryFilters` (none/warm/cool/mono/fade/vivid), widget `FilterBar({required int selected, required ValueChanged<int> onSelect, required ImageProvider preview})`, and `Future<File> bakeImage(GlobalKey repaintKey, File fallback)` which captures the RepaintBoundary (filter + drawings applied) to a temp PNG file; on any capture failure returns `fallback` (original file) so posting never breaks.

- [ ] **Step 1: Implement filter_bar.dart**

```dart
// lib/pages/stories/create/studio/filter_bar.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class StoryFilter {
  const StoryFilter(this.name, this.matrix);
  final String name;
  final List<double>? matrix; // null = no filter
}

const kStoryFilters = <StoryFilter>[
  StoryFilter('Normal', null),
  StoryFilter('Warm', [
    1.15, 0, 0, 0, 10, 0, 1.05, 0, 0, 5, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Cool', [
    0.95, 0, 0, 0, 0, 0, 1.0, 0, 0, 5, 0, 0, 1.15, 0, 10, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Mono', [
    0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0,
    0.33, 0.59, 0.11, 0, 0, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Fade', [
    0.9, 0, 0, 0, 25, 0, 0.9, 0, 0, 25, 0, 0, 0.9, 0, 25, 0, 0, 0, 1, 0,
  ]),
  StoryFilter('Vivid', [
    1.25, 0, 0, 0, -10, 0, 1.25, 0, 0, -10, 0, 0, 1.25, 0, -10, 0, 0, 0, 1, 0,
  ]),
];

/// Wraps [child] in the selected filter's ColorFiltered (identity when null).
Widget applyStoryFilter(int index, Widget child) {
  final m = kStoryFilters[index].matrix;
  if (m == null) return child;
  return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.preview,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  final ImageProvider preview;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: kStoryFilters.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onSelect(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected == i
                          ? const Color(0xFF00BFA5)
                          : Colors.white24,
                      width: selected == i ? 2.5 : 1),
                ),
                clipBehavior: Clip.hardEdge,
                child: applyStoryFilter(
                    i, Image(image: preview, fit: BoxFit.cover)),
              ),
              const SizedBox(height: 4),
              Text(kStoryFilters[i].name,
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Captures the composed (filtered + drawn-on) image; falls back to the
/// original file on any failure so posting never breaks.
Future<File> bakeImage(GlobalKey repaintKey, File fallback) async {
  try {
    final boundary = repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return fallback;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return fallback;
    final dir = await getTemporaryDirectory();
    final f = File(
        '${dir.path}/story_baked_${DateTime.now().millisecondsSinceEpoch}.png');
    await f.writeAsBytes(bytes.buffer.asUint8List());
    return f;
  } catch (_) {
    return fallback;
  }
}
```

- [ ] **Step 2: Wire into create screen**

In `create_story_screen.dart` image flow: wrap the image preview in `RepaintBoundary(key: _bakeKey, child: applyStoryFilter(_filterIndex, <preview>))`; show `FilterBar` under the canvas when media is an image; add a crop IconButton calling the already-shipped `ImageCropper().cropImage(sourcePath: file.path)` and replacing the selected file; before upload, if `_filterIndex != 0` (or Task 6 drawing exists) call `bakeImage(_bakeKey, originalFile)` and upload the baked file.

- [ ] **Step 3: Verify + commit**

`flutter analyze lib/pages/stories/create/` → 0 issues; manual: pick image → Vivid → post → story shows filtered image.

```bash
git add lib/pages/stories/create/
git commit -m "feat(story-studio): 6 filter presets, crop, RepaintBoundary bake on upload"
```

---

### Task 6: Drawing layer

**Files:**
- Create: `lib/pages/stories/create/studio/draw_layer.dart`
- Modify: `lib/pages/stories/create/create_story_screen.dart` (toolbar toggle + stack insert INSIDE the RepaintBoundary from Task 5)

**Interfaces:**
- Produces: `class DrawStroke { final List<Offset> points; final Color color; final double width; final bool highlighter; }`, `class DrawLayer extends StatefulWidget { final List<DrawStroke> strokes; final bool enabled; final Color color; final double width; final bool highlighter; final VoidCallback onChanged; }` (paints all strokes; when `enabled`, pan gestures append a new stroke), plus `class DrawToolbar` (8 colors, width slider 2–14, pen/highlighter toggle, undo button that pops `strokes`). Strokes render under the RepaintBoundary so `bakeImage` flattens them automatically.

- [ ] **Step 1: Implement draw_layer.dart**

```dart
// lib/pages/stories/create/studio/draw_layer.dart
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
```

- [ ] **Step 2: Wire + verify + commit**

Create screen: `_drawMode` bool toggled from a brush IconButton in the top bar; `DrawLayer` sits inside the RepaintBoundary stack ABOVE the filtered image but BELOW `StoryCanvas` overlays; `DrawToolbar` replaces FilterBar while `_drawMode`. Baking (Task 5) flattens strokes; text-type stories get the same stack over the gradient. `flutter analyze` → 0 issues.

```bash
git add lib/pages/stories/create/
git commit -m "feat(story-studio): freehand drawing — pen/highlighter, undo, baked into media"
```

---

### Task 7: Location sticker

**Files:**
- Create: `lib/pages/stories/create/studio/location_picker_sheet.dart`
- Modify: `lib/pages/stories/create/create_story_screen.dart` (sticker row button; pass `location:` to `createStory`)
- Modify: `../backend/controllers/stories.js` (parse `location` from body on all three create paths)

**Interfaces:**
- Consumes: existing `StoryLocation` model (story_model.dart) and `createStory(location: ...)` param.
- Produces: `Future<StoryLocation?> showLocationPickerSheet(BuildContext context)` — "current location" row (geolocator → geocoding reverse for display name) + free-text search field (geocoding forward lookup, first 5 results). Permission denied → search-only (no error dialog). Backend: `location` accepted as JSON `{ name, coordinates: [lng, lat] }` merged into `Story.create`.

- [ ] **Step 1 (backend): parse location on create paths**

Add next to the overlays parsing on each create path:

```javascript
let location;
if (req.body.location) {
  try {
    const raw = typeof req.body.location === 'string'
      ? JSON.parse(req.body.location) : req.body.location;
    if (raw && typeof raw.name === 'string' && raw.name.trim()) {
      location = { name: raw.name.trim().slice(0, 120) };
      if (Array.isArray(raw.coordinates) && raw.coordinates.length === 2) {
        location.coordinates = {
          type: 'Point',
          coordinates: [Number(raw.coordinates[0]), Number(raw.coordinates[1])],
        };
      }
    }
  } catch (e) { /* ignore malformed location — story posts without it */ }
}
```

Include `...(location ? { location } : {}),` in each `Story.create({...})`. `node --check controllers/stories.js` → OK; commit `feat(stories): accept location tag on story create`.

- [ ] **Step 2 (app): picker sheet**

```dart
// lib/pages/stories/create/studio/location_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

Future<StoryLocation?> showLocationPickerSheet(BuildContext context) {
  return showModalBottomSheet<StoryLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => const _LocationSheet(),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _controller = TextEditingController();
  List<StoryLocation> _results = [];
  bool _busy = false;

  Future<void> _useCurrent() async {
    setState(() => _busy = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return; // fall back to search-only silently
      }
      final pos = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.isNotEmpty ? placemarks.first : null;
      final name = [p?.locality, p?.country]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (mounted && name.isNotEmpty) {
        Navigator.pop(
            context,
            StoryLocation(
                name: name, longitude: pos.longitude, latitude: pos.latitude));
      }
    } catch (_) {
      // search-only fallback
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 3) return;
    setState(() => _busy = true);
    try {
      final locs = await locationFromAddress(q.trim());
      final results = <StoryLocation>[];
      for (final l in locs.take(5)) {
        final pm = await placemarkFromCoordinates(l.latitude, l.longitude);
        final p = pm.isNotEmpty ? pm.first : null;
        final name = [p?.name, p?.locality, p?.country]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(', ');
        results.add(StoryLocation(
            name: name.isEmpty ? q.trim() : name,
            longitude: l.longitude,
            latitude: l.latitude));
      }
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search a place…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.my_location_rounded,
                color: Color(0xFF00BFA5)),
            title: const Text('Use current location'),
            trailing: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _busy ? null : _useCurrent,
          ),
          for (final r in _results)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(context, r),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
```

NOTE: check `StoryLocation`'s actual constructor in `story_model.dart` before implementing — if its fields differ (e.g. `coordinates` list instead of `longitude/latitude`), adapt the two construction sites above to the real signature; do NOT change the model.

- [ ] **Step 3: Wire + verify + commit**

Create screen: 📍 button in the sticker row → `showLocationPickerSheet`; result stored in `_pickedLocation` and shown as a removable pill chip above the sticker row; pass `location: _pickedLocation` to every `createStory` call. `flutter analyze` → 0 issues.

```bash
git add lib/pages/stories/create/
git commit -m "feat(story-studio): location sticker — current-location + place search"
```

---

### Task 8: Mentions — backend parse, validate, notify

**Files:**
- Modify: `../backend/controllers/stories.js` (parse `mentions` on all create paths)
- Modify: `../backend/utils/notificationTemplates.js` + `../backend/config/notificationCaps.js` (add `story_mention`, cap `storyMention: 5` daily)
- Test: `../backend/test/storyMentions.test.js`

**Interfaces:**
- Produces: create accepts `mentions` as JSON array `[{ user: '<id>', x: 0..100, y: 0..100 }]`, max 5, silently dropping entries whose user id doesn't exist; stores into the existing `Story.mentions` schema (user, position.x, position.y). After story create, fires `notificationService.sendToUser(mentionedUserId, ...)` (match the existing helper used by `sendWave` in `../backend/services/notificationService.js` — reuse its exported send pattern) with template type `story_mention`, route `/stories/<storyId>`.

- [ ] **Step 1: Write failing test**

```javascript
// ../backend/test/storyMentions.test.js
const test = require('node:test');
const assert = require('node:assert');
const { parseMentions } = require('../controllers/stories');

test('parseMentions caps at 5 and clamps position', () => {
  const raw = JSON.stringify(
    Array.from({ length: 7 }, (_, i) => ({
      user: `64b7f0000000000000000${i}0a`,
      x: 150,
      y: -20,
    }))
  );
  const parsed = parseMentions(raw);
  assert.strictEqual(parsed.length, 5);
  assert.strictEqual(parsed[0].position.x, 100);
  assert.strictEqual(parsed[0].position.y, 0);
});

test('parseMentions returns [] on malformed input', () => {
  assert.deepStrictEqual(parseMentions('not-json'), []);
  assert.deepStrictEqual(parseMentions(undefined), []);
  assert.deepStrictEqual(parseMentions(JSON.stringify({ nope: 1 })), []);
});
```

Run: `cd ../backend && node --test test/storyMentions.test.js` → FAIL (parseMentions not exported).

- [ ] **Step 2: Implement**

In `controllers/stories.js` add near `parseStickerFields`:

```javascript
// Parse client-declared mentions: [{ user, x(0-100), y(0-100) }] — max 5.
// Pure input-shaping; existence check happens at the create call site.
function parseMentions(raw) {
  if (!raw) return [];
  let data = raw;
  if (typeof data === 'string') {
    try { data = JSON.parse(data); } catch (e) { return []; }
  }
  if (!Array.isArray(data)) return [];
  return data
    .filter(m => m && typeof m.user === 'string' && m.user.trim())
    .slice(0, 5)
    .map(m => ({
      user: m.user.trim(),
      position: {
        x: Math.min(100, Math.max(0, Number(m.x) || 0)),
        y: Math.min(100, Math.max(0, Number(m.y) || 0)),
      },
    }));
}
```

Export it in the module exports (`exports.parseMentions = parseMentions;`). At each create path: `const mentions = parseMentions(req.body.mentions);` then before `Story.create`, filter to existing users:

```javascript
let validMentions = [];
if (mentions.length > 0) {
  const User = require('../models/User');
  const found = await User.find({ _id: { $in: mentions.map(m => m.user) } })
    .select('_id').lean();
  const ids = new Set(found.map(u => u._id.toString()));
  validMentions = mentions.filter(m => ids.has(m.user));
}
```

Include `mentions: validMentions,` in `Story.create`. After create, notify (fire-and-forget, mirroring the follower-moment pattern in `controllers/moments.js:522-528`):

```javascript
const notificationService = require('../services/notificationService');
validMentions.forEach(m => {
  notificationService.sendStoryMention(m.user, req.user._id.toString(), story._id.toString())
    .catch(err => console.error('story mention notification failed:', err.message));
});
```

Add `sendStoryMention(recipientId, senderId, storyId)` to `services/notificationService.js` copying the structure of `sendWave` (same suppression/caps plumbing), template type `story_mention`, route `/stories/${storyId}`; add `storyMention: 5` to the `daily` object in `config/notificationCaps.js` and a `getStoryMentionTemplate` in `utils/notificationTemplates.js` mirroring `getWaveTemplate` ("{name} mentioned you in their story").

- [ ] **Step 3: Verify + commit**

`node --test test/storyMentions.test.js` → PASS; `node --check controllers/stories.js services/notificationService.js utils/notificationTemplates.js` → OK.

```bash
git add controllers/stories.js services/notificationService.js utils/notificationTemplates.js config/notificationCaps.js test/storyMentions.test.js
git commit -m "feat(stories): mentions — parse+validate on create, story_mention notification"
```

---

### Task 9: Mentions — app picker + tappable viewer pills

**Files:**
- Create: `lib/pages/stories/create/studio/mention_picker_sheet.dart`
- Modify: `lib/pages/stories/create/create_story_screen.dart` (@ button; pass `mentions:` to `createStory`)
- Modify: `lib/pages/stories/viewer/story_viewer_screen.dart` (render mention pills; tap → profile)

**Interfaces:**
- Consumes: existing `StoryMention` model, `createStory(mentions: ...)`, existing followings search (`communityServiceProvider.getSingleCommunity` / the search used by `chat_list_search_bar` — locate the followings-list service call in `lib/providers/provider_root/community_provider.dart` and reuse it; do not add a new endpoint).
- Produces: `Future<StoryMention?> showMentionPickerSheet(BuildContext context, WidgetRef ref)` — searchable list of the user's followings; returns a `StoryMention` for the picked user (default position x:50,y:80). Viewer: for each `story.mentions`, a `Positioned` pill `@name` at (x%,y%) that pushes `SingleCommunity` on tap (fetch via `communityServiceProvider.getSingleCommunity(id: mention.userId)` — match `StoryMention`'s real field name).

- [ ] **Step 1: Implement sheet (searchable followings list → returns pick)**

Structure mirrors `location_picker_sheet.dart`: a `TextField` filter over `ref.watch(<followingsProvider>)` list, each row = avatar + name, tap → `Navigator.pop(context, StoryMention(...))`. Read `StoryMention`'s constructor in `story_model.dart` first and construct with its exact fields.

- [ ] **Step 2: Create screen wiring**

`@` button in sticker row → sheet → append to `List<StoryMention> _mentions` (cap 5 with a snackbar past that), removable chips; pass `mentions: _mentions` on all `createStory` calls.

- [ ] **Step 3: Viewer pills**

In `story_viewer_screen.dart`, inside the same Stack that hosts `ViewerOverlayLayer` (~line 803), add:

```dart
for (final m in story.mentions)
  Positioned(
    left: (m.x / 100) * MediaQuery.of(context).size.width - 40,
    top: (m.y / 100) * MediaQuery.of(context).size.height - 14,
    child: GestureDetector(
      onTap: () => _openMentionProfile(m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('@${m.username}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    ),
  ),
```

(`m.x/m.y/m.username` — adapt to `StoryMention`'s real getters.) `_openMentionProfile` pauses the story timer (reuse the existing pause-during-question mechanism), fetches the community, pushes `SingleCommunity`.

- [ ] **Step 4: Verify + commit**

`flutter analyze` on the three files → 0 issues; manual: post story mentioning a user → pill renders → tap opens profile; mentioned account receives push.

```bash
git add lib/pages/stories/
git commit -m "feat(story-studio): @mentions — picker, capped at 5, tappable viewer pills"
```

---

### Task 10: Send story to friends in-app

**Files:**
- Create: `lib/pages/stories/viewer/story_share_sheet.dart`
- Modify: `lib/pages/stories/viewer/story_viewer_screen.dart` (share button → sheet)
- Modify: `lib/services/stories_service.dart` (ensure `shareStory` posts `{sharedTo:'dm', receiverId}` to `stories/:id/share`; add if missing)
- Modify: `lib/pages/chat/message/message_bubble.dart` (render story-share messages as a story card)

**Interfaces:**
- Consumes: backend `POST /api/v1/stories/:id/share` (exists — creates the DM Message + socket emit, `controllers/stories.js:~995`); chat partner list from the chat-list provider already used by `chat_list_screen.dart`.
- Produces: `Future<void> showStoryShareSheet(BuildContext context, WidgetRef ref, Story story)` — horizontal recent-partners row + search, multi-select, Send button loops `StoriesService.shareStory(storyId: story.id, receiverId: partner.id)`. Chat renders the resulting message as a card (thumbnail or gradient+text snippet, "View story" → `story/:id` fetch → viewer; on 404/expired show a disabled "Story expired" card).

- [ ] **Step 1:** Read the Message the backend creates in `shareStory` (`sed -n '1035,1065p' ../backend/controllers/stories.js`) to learn its `messageType`/payload fields. The bubble renderer keys off those exact fields.
- [ ] **Step 2:** Implement `story_share_sheet.dart` (mirror the friends-picker layout of `mention_picker_sheet.dart`; reuse the chat partners provider); wire the viewer's share icon: first row "Send to friends" (this sheet), second row "More" (existing share_plus path).
- [ ] **Step 3:** In `message_bubble.dart`, add a branch before the default text renderer: if the message matches the story-share type from Step 1, render the card; tap → `StoriesService.getStory(id)`; 404/expired → grey "Story expired" card (no navigation).
- [ ] **Step 4:** `flutter analyze` → 0 issues; manual: share own story to a friend → card appears in their chat → tap opens viewer. Commit `feat(stories): in-app share to friends with chat story card`.

---

### Task 11: hasActiveStory flag + story rings in Community AND Chat

**Files:**
- Modify: `../backend/controllers/community.js` (list endpoint(s) returning user collections)
- Modify: `../backend` chat-partners endpoint — the same handler that got the privacy-filtered `country` field in commit `a3ef753` ("chat-partners payload for identity flags"); locate via `grep -rn "chat-partners\|chatPartners" ../backend/controllers/` and stamp `hasActiveStory` there with the same helper
- Test: `../backend/test/hasActiveStory.test.js`
- Modify (app): `lib/widgets/community/compact_user_tile.dart`, `lib/widgets/community/partner_list_item.dart`, `lib/widgets/community/partner_card.dart` (avatar wrap + tap)
- Modify (app): `lib/pages/chat/list/chat_list_tile.dart` — wrap the partner avatar in `StoryGradientRing` when `partner.hasActiveStory`; **avatar tap → story viewer**, tile tap → conversation (unchanged); add `hasActiveStory` to the `ChatPartner` model (`lib/pages/chat/models/chat_partner.dart`) parsed as `json['hasActiveStory'] == true`

**Interfaces:**
- Produces (backend): every user object in community list/detail payloads gains `hasActiveStory: Boolean`. Helper in new file `../backend/lib/activeStoryFlags.js`:

```javascript
// lib/activeStoryFlags.js
const Story = require('../models/Story');

/**
 * Returns Set<userIdString> of users (from userIds) who have >=1 active,
 * unexpired story VISIBLE to viewerId: privacy 'public' always; 'friends'
 * only when the viewer follows the owner (followingIds contains owner).
 * close_friends stories never light the ring for non-close viewers.
 */
async function usersWithVisibleActiveStory(userIds, viewerId, followingIds = []) {
  if (!userIds.length) return new Set();
  const now = new Date();
  const following = new Set(followingIds.map(String));
  const stories = await Story.find({
    user: { $in: userIds },
    isActive: true,
    expiresAt: { $gt: now },
    privacy: { $in: ['public', 'friends'] },
  }).select('user privacy').lean();
  const result = new Set();
  for (const s of stories) {
    const owner = s.user.toString();
    if (s.privacy === 'public' || following.has(owner)) result.add(owner);
  }
  return result;
}

module.exports = { usersWithVisibleActiveStory };
```

- App: in each of the three community widgets, wrap the avatar in the existing `StoryGradientRing` (from `lib/widgets/story/story_gradient_ring.dart` — read its constructor first) when `community.hasActiveStory == true` (add the field to `Community.fromJson` as `json['hasActiveStory'] == true`), and avatar-tap opens the story viewer route used by the stories feed for that user; non-avatar taps keep opening the profile.

- [ ] **Step 1:** Test for the helper (mock via an in-memory filter is impractical without DB; instead unit-test the pure decision): extract `visibleOwners(stories, followingSet)` as a pure function inside the same file, export it, and test: public → always in; friends + followed → in; friends + not followed → out; close_friends → never queried (assert query filter excludes it by testing the exported `VISIBLE_PRIVACIES = ['public','friends']` constant).
- [ ] **Step 2:** Wire into `controllers/community.js` list handler: collect page's user ids → `usersWithVisibleActiveStory(ids, req.user?._id, req.user?.followings || [])` → stamp `hasActiveStory` on each serialized user. ONE query per page — no N+1.
- [ ] **Step 3:** App model field + ring wraps + avatar-tap navigation.
- [ ] **Step 4:** `node --test test/hasActiveStory.test.js` PASS, `node --check` OK, `flutter analyze` 0 issues; commit backend `feat(community): hasActiveStory flag (privacy-aware, batched)` and app `feat(community): story rings on avatars, tap-to-view`.

---

### Task 12: Community detail — Instagram-style restyle

**Files:**
- Modify: `lib/pages/community/single/single_community_header.dart` (avatar+stats row, bio)
- Modify: `lib/pages/community/single/single_community_actions.dart` (full-width 3-button row)
- Modify: `lib/pages/community/single/single_community_screen.dart` (tabs: Moments grid / About)
- Modify: `lib/pages/community/single/single_community_moments.dart` (3-col grid; text moments reuse the colored-tile pattern from `profile_moments_tab.dart` — extract `_TextMomentTile` there into `lib/widgets/moments/text_moment_tile.dart` and import it in BOTH places)

**Interfaces:**
- Consumes: `userMomentsProvider(userId)` (exists), highlights row widget from profile (locate `highlights_row.dart` usage in `profile_main.dart` and reuse with this user's id), `hasActiveStory` + ring (Task 11).
- Produces: shared widget `TextMomentTile({required String text, required String backgroundColor})` in `lib/widgets/moments/text_moment_tile.dart` (move the existing private `_TextMomentTile` implementation verbatim, made public; update `profile_moments_tab.dart` import).

Layout contract (top→bottom): SliverAppBar (name only) → header row [ringed avatar 84px — **tap opens this user's active story in the viewer when `hasActiveStory`, else opens the profile-photo view** | three stat Columns: Posts (`moments.length`), Followers, Following — **display-only**] → name+flags line → collapsed bio (3 lines, "more" expands) → action row [Follow(filled teal) | Message(outlined) | 👋(outlined square)] → highlights row → TabBar [grid icon | info icon] → TabBarView [3-col moments grid | existing about+topics content].

- [ ] **Step 1:** Extract `TextMomentTile` to the shared path; update profile import; `flutter analyze` both → 0 issues; commit `refactor(moments): share TextMomentTile`.
- [ ] **Step 2:** Restyle header/actions/tabs per the layout contract (keep all existing follow/unfollow/message/wave handlers — restyle only, logic untouched).
- [ ] **Step 3:** Moments grid tab: `GridView.builder` (3 col, 1:1, spacing 2) — image → `CachedImageWidget`, text → `TextMomentTile`; tap → existing `SingleMoment` navigation.
- [ ] **Step 4:** `flutter analyze lib/pages/community/single/` → 0 issues; manual light+dark screenshots; commit `feat(community): Instagram-style profile detail`.

---

### Task 13: Moments feed freshness (stale-while-revalidate)

**Files:**
- Modify: `lib/providers/provider_root/moments_providers.dart`
- Modify: `lib/pages/moments/feed/moments_main.dart` (tab visibility hook)

**Interfaces:**
- Produces: `final momentsFeedFreshnessProvider = StateProvider<DateTime?>((ref) => null);` recording last successful fetch, and top-level `void refreshMomentsIfStale(WidgetRef ref, {Duration maxAge = const Duration(seconds: 60)})`:

```dart
void refreshMomentsIfStale(WidgetRef ref,
    {Duration maxAge = const Duration(seconds: 60)}) {
  final last = ref.read(momentsFeedFreshnessProvider);
  if (last != null && DateTime.now().difference(last) < maxAge) return;
  ref.invalidate(forYouMomentsProvider);
  ref.invalidate(momentsFeedProvider);
}
```

Each feed provider sets `ref.read(momentsFeedFreshnessProvider.notifier).state = DateTime.now();` after a successful fetch (inside the provider body via `ref` — use `Future.microtask` to avoid modifying during build if the analyzer complains).

- [ ] **Step 1:** Add provider + helper; call `refreshMomentsIfStale(ref)` from `moments_main.dart` in (a) `initState` post-frame and (b) a `selectedTabProvider` listener firing when the Moments tab index becomes active (`ref.listen` in build — mirror how `TabBarMenu` exposes the index).
- [ ] **Step 2:** Ensure both feed `.when(...)` calls in `moments_feed_widget.dart`/`moments_main.dart` pass `skipLoadingOnRefresh: true, skipLoadingOnReload: true` so revalidation is invisible.
- [ ] **Step 3:** `flutter analyze` → 0 issues; manual: post a moment from another account → return to Moments tab after >60s → new moment appears without spinner. Commit `feat(moments): stale-while-revalidate feed freshness (60s TTL, refresh-on-focus)`.

---

### Task 14: Final gate — combined verification

- [ ] `flutter analyze lib/pages/stories lib/pages/community lib/pages/moments lib/widgets` → 0 errors/warnings introduced (pre-existing infos allowed).
- [ ] `flutter test test/stories/ test/moments/` → PASS.
- [ ] Backend: `node --check` on every touched file; `node --test test/storyMentions.test.js test/hasActiveStory.test.js` → PASS; full `npm test` → no new failures.
- [ ] Manual QA checklist (device/simulator, light + dark): multi-text story with colors/fonts moved+resized; delete-by-trash; filter+drawing baked; location + mention pills render in viewer; mention push received; in-app share card in chat (+ expired state); community rings show only privacy-visible stories; community detail matches layout contract; moments feed silently refreshes on tab return.
- [ ] Commit any fixes; report per-feature status honestly (works / not verified).

---

### Task 15: Own story on the Profile page

**Files:**
- Modify: `lib/pages/profile/profile_main/sections/profile_tab_bar.dart` (or wherever ProfileMain's avatar renders — locate via ProfileTabBar usage in profile_main.dart)
- Consume: own active stories from the same provider the stories feed uses for "my story" (locate the my-stories/user-stories provider in the stories feed; do NOT add endpoints)

Behavior: when the logged-in user has ≥1 active story, wrap the profile avatar in `StoryGradientRing`; tap → open the story viewer on OWN stories (which already supports the viewers-list sheet); when no active story, keep the existing tap→ProfilePictureEdit behavior. Ring must render in light + dark. `flutter analyze` 0 new issues.

### Task 16: Profile page optimization pass

**Files:** `lib/pages/profile/profile_main.dart` + its `profile_main/sections/*` widgets (visual/perf polish ONLY — no feature changes)

Scope: consistent section spacing (20px rhythm), const-ify what the analyzer suggests in touched files, ensure every section renders correctly in dark mode (no hardcoded whites/greys — use theme extensions), soften the stats row + action buttons styling to match the app's teal/banana tokens, and make the SliverAppBar title show the avatar thumbnail when scrolled past the header (small IG-style polish; skip if it requires restructuring the scroll view). No layout rewrites. `flutter analyze` 0 new issues on touched files.

### Task 17: Coins v2 — earn loop + history (make coins worth engaging with)

**17a Backend:**
- `POST /api/v1/coins/daily-reward` — +10 coins once per UTC day, enforced server-side via coinLedger idempotency (`iapTransactionId`-style key `daily-<userId>-<YYYY-MM-DD>` in metadata, reason `daily_reward`); response `{success, balance, credited, alreadyClaimed}`.
- `GET /api/v1/coins/daily-reward/status` → `{claimedToday: bool}` (query today's ledger row).
- `POST /api/v1/coins/ad-reward` — +5 coins per rewarded-ad watch, hard cap 5/day server-side (count today's `ad_reward` ledger rows), idempotency key `ad-<userId>-<date>-<n>`. KNOWN LIMIT (flag in code comment + report): no SSV ad verification; the daily cap bounds abuse.
- Routes behind existing auth + coinsEnabledGuard. Tests: `test/coinDailyReward.test.js` — once-per-day idempotency + ad cap logic (pure parts).
**17b App:**
- Coin shop: new "Earn free coins" section above the packs — Daily Reward card (claim button, disabled+countdown label when claimed; refreshes balance) and Watch-Ad card reusing the existing `RewardedAdButton`/AdService rewarded flow → on reward callback call ad-reward endpoint → refresh balance; hide when ads unavailable.
- Transactions history: new `coin_history_screen.dart` (list from the existing `CoinApiClient` transactions endpoint — verify name; rows: reason icon, +/- amount, date), linked from the shop's balance row (chevron).
- All new UI dark/light correct, teal/banana tokens. `flutter analyze` 0 new issues; reuse coinBalanceProvider/refreshCoinBalance.

### Task 14 (gate) — ADDITIONS
- Dedicated light+dark sweep, story surfaces in BOTH themes: create canvas/toolbars/sheets, viewer incl. pills/location, share sheet, rings (community list, community detail, chat list, profile), highlights.
- Story delete E2E: delete story with media → 200 even if Spaces slow; deleted story pulled from highlight; delete from viewer + from highlights editor.
- Coins v2: daily reward double-claim rejected; ad reward capped; history renders.

### Task 18: Moments main + detail audit & fixes (comments/replies focus)

**Phase A — audit (read-only, produce findings list):** sweep `lib/pages/moments/feed/*` (moments_main, moments_feed_widget, prompt_of_day_card), `lib/pages/moments/single/single_moment.dart`, `lib/pages/comments/comments_main.dart`, and the comments providers. Hunt specifically for: reply threading correctness (parentComment wiring, reply-to-reply, reply counts), comment edit/delete/react flows (silent refresh — no spinner flash; optimistic updates reverting correctly on failure), pagination (load-more duplicates/ordering), keyboard handling in the comment composer (inset overlap, dismiss), translation flows in comments, stale counts after actions (like/comment counts on the card vs detail), dark-mode issues (hardcoded colors), obvious jank (missing const, rebuild storms via ref.watch scope, ListView without keys), and dead/duplicated code between feed card and detail card.
**Phase B — fix:** apply Critical/Important findings + cheap UI polish (Minor) in the same pass; anything structural gets reported, not rewritten. `flutter analyze` 0 new issues on touched files; `flutter test test/moments/ test/stories/` green. Both phases in one subagent report with a findings table (found → fixed/deferred).
