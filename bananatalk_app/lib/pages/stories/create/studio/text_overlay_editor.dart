// lib/pages/stories/create/studio/text_overlay_editor.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/stories/create/studio/overlay_draft.dart';
import 'package:bananatalk_app/pages/stories/create/studio/story_canvas.dart';

const _swatches = [
  '#FFFFFF', '#000000', '#FFD54F', '#00BFA5', '#FF5252', '#FF9800',
  '#4CAF50', '#2196F3', '#9C27B0', '#E91E63', '#795548', '#9E9E9E',
];
const _fontStyles = ['sans-serif', 'serif', 'bold', 'handwritten'];
const _quickEmojis = ['😂', '😍', '🔥', '🎉', '💯', '🙌', '😭', '🍌'];

/// Full-screen dark editing sheet for one [OverlayDraft].
///
/// The sheet is a real StatefulWidget so the TextEditingController is
/// disposed in State.dispose() — i.e. only after the route's exit transition
/// has fully unmounted the TextField (disposing in the route future's `.then`
/// raced the transition and crashed in debug). Commit runs exactly once, on
/// Done, emoji pick, or any other dismissal (system back) via PopScope.
Future<void> showTextOverlayEditor(
  BuildContext context,
  OverlayDraft draft, {
  required VoidCallback onDone,
  required VoidCallback onDeleteEmpty,
}) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black87,
    pageBuilder: (context, _, __) => _TextOverlayEditorSheet(
      draft: draft,
      onDone: onDone,
      onDeleteEmpty: onDeleteEmpty,
    ),
  );
}

class _TextOverlayEditorSheet extends StatefulWidget {
  const _TextOverlayEditorSheet({
    required this.draft,
    required this.onDone,
    required this.onDeleteEmpty,
  });

  final OverlayDraft draft;
  final VoidCallback onDone;
  final VoidCallback onDeleteEmpty;

  @override
  State<_TextOverlayEditorSheet> createState() =>
      _TextOverlayEditorSheetState();
}

class _TextOverlayEditorSheetState extends State<_TextOverlayEditorSheet> {
  late final TextEditingController _controller;
  bool _committed = false;

  OverlayDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _draft.content);
  }

  @override
  void dispose() {
    // Runs after the route (and its exit transition) has unmounted the
    // TextField — safe, unlike disposing in the dialog future's `.then`.
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    if (_committed) return;
    _committed = true;
    _draft.content = _controller.text.trim();
    if (_draft.content.isEmpty) {
      widget.onDeleteEmpty();
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    // This sheet is unconditionally dark by design (it edits text over a
    // black-ish full-screen backdrop) regardless of the device's system
    // light/dark appearance. Forcing AppTheme.dark here — on top of the
    // explicit `filled: false` below — is belt-and-suspenders: it ensures
    // any unstyled Material widget (the font-style ChoiceChips further
    // down included) resolves theme-derived defaults to dark values
    // instead of silently inheriting the app's global (possibly light)
    // theme.
    return Theme(
      data: AppTheme.dark,
      child: PopScope(
      // Covers system back / any dismissal not going through our buttons.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _commit();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            TextButton(
              onPressed: () {
                _commit();
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
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: overlayTextStyle(_draft, base: 30),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    // Same theme-leak fix as create_story_screen.dart's
                    // hashtag input: explicitly opt out of the ambient
                    // theme's default fill so a light system appearance
                    // can't paint a stray near-white box here.
                    filled: false,
                  ),
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
                            _draft
                              ..type = 'emoji'
                              ..content = e;
                            _committed = true;
                            widget.onDone();
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child:
                                Text(e, style: const TextStyle(fontSize: 28)),
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
                          _draft.bgMode == 'none'
                              ? Icons.format_color_text_rounded
                              : Icons.font_download_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() {
                          _draft.bgMode = _draft.bgMode == 'none'
                              ? 'semi'
                              : _draft.bgMode == 'semi'
                                  ? 'solid'
                                  : 'none';
                        }),
                      ),
                      for (final f in _fontStyles)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _draft.fontStyle == f,
                            onSelected: (_) =>
                                setState(() => _draft.fontStyle = f),
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
                          onTap: () => setState(() => _draft.color = s),
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: hexColor(s),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _draft.color == s
                                      ? const Color(0xFF00BFA5)
                                      : Colors.white,
                                  width: _draft.color == s ? 3 : 1.5),
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
}
