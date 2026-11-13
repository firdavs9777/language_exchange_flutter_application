import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// A story's "word of the story" sticker with a Save word action.
///
/// Controlled: the viewer keeps whether the word was saved (keyed by story
/// id) and does the vocabulary call; this widget only guards double taps.
class StoryWordStickerWidget extends StatefulWidget {
  final StoryWordSticker sticker;
  final bool isOwner;

  /// Expired / archived / highlighted story: no action is offered.
  final bool readOnly;

  /// The word is already in the viewer's vocabulary.
  final bool saved;

  /// Saves the word. A failure is reported by the viewer; the button stays.
  final Future<void> Function()? onSave;

  const StoryWordStickerWidget({
    super.key,
    required this.sticker,
    this.isOwner = false,
    this.readOnly = false,
    this.saved = false,
    this.onSave,
  });

  @override
  State<StoryWordStickerWidget> createState() => _StoryWordStickerWidgetState();
}

class _StoryWordStickerWidgetState extends State<StoryWordStickerWidget> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving || widget.onSave == null) return;
    setState(() => _saving = true);
    try {
      await widget.onSave!();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = widget.sticker;
    final canSave =
        !widget.isOwner && !widget.readOnly && widget.onSave != null;

    Widget? footer;
    if (widget.saved) {
      footer = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.addedToVocabulary,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      );
    } else if (canSave) {
      footer = OutlinedButton(
        key: const Key('word-save'),
        onPressed: _saving ? null : _save,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          shape: const StadiumBorder(),
        ),
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.storySaveWord),
      );
    }

    final example = s.example;
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.meaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (example != null && example.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    example,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (footer != null) ...[const SizedBox(height: 12), footer],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
