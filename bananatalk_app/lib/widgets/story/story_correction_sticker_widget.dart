import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// A story's "correct my sentence" sticker.
///
/// Controlled: the viewer keeps the per-story state (sent, already corrected,
/// count) and passes it in, so returning to a story shows the same state.
/// Only the open/closed field and the in-flight flag live here.
class StoryCorrectionStickerWidget extends StatefulWidget {
  final StoryCorrectionSticker sticker;
  final bool isOwner;

  /// Expired / archived / highlighted story: the server refuses corrections,
  /// so only the sentence is shown.
  final bool readOnly;

  /// `false` hides the field (the server answers 403 for such stories).
  final bool allowReplies;

  /// The viewer's correction was sent in this session (as opposed to the
  /// server already knowing about an earlier one).
  final bool sent;

  /// Sends the correction. The text stays in the field unless the result is a
  /// success (the viewer then flips [sticker] to corrected).
  final Future<CorrectionResult> Function(String text)? onSubmit;

  /// `true` while the field has focus (playback pauses), `false` otherwise.
  final ValueChanged<bool>? onInteracting;

  const StoryCorrectionStickerWidget({
    super.key,
    required this.sticker,
    this.isOwner = false,
    this.readOnly = false,
    this.allowReplies = true,
    this.sent = false,
    this.onSubmit,
    this.onInteracting,
  });

  @override
  State<StoryCorrectionStickerWidget> createState() =>
      _StoryCorrectionStickerWidgetState();
}

class _StoryCorrectionStickerWidgetState
    extends State<StoryCorrectionStickerWidget> {
  static const int _maxLength = 500;

  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _open = false;
  bool _sending = false;
  bool _reportedFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focus.hasFocus == _reportedFocus) return;
    _reportedFocus = _focus.hasFocus;
    widget.onInteracting?.call(_reportedFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (_sending || text.isEmpty || widget.onSubmit == null) return;
    setState(() => _sending = true);
    _focus.unfocus();
    try {
      await widget.onSubmit!(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = widget.sticker;
    final canCorrect =
        !widget.isOwner &&
        !widget.readOnly &&
        widget.allowReplies &&
        !s.hasCorrected &&
        widget.onSubmit != null;

    Widget? footer;
    if (widget.isOwner) {
      footer = Text(
        l10n.storyCorrectionsReceived(s.correctionCount),
        style: _footerStyle,
      );
    } else if (s.hasCorrected) {
      footer = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.sent
                  ? l10n.storyCorrectionSent
                  : l10n.storyCorrectionAlready,
              style: _footerStyle,
            ),
          ),
        ],
      );
    } else if (canCorrect && !_open) {
      footer = OutlinedButton(
        onPressed: () => setState(() => _open = true),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          shape: const StadiumBorder(),
        ),
        child: Text(l10n.storyCorrectThis),
      );
    } else if (canCorrect && _open) {
      footer = Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              maxLength: _maxLength,
              maxLines: 3,
              minLines: 1,
              enabled: !_sending,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.storyCorrectionFieldHint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('correction-send'),
            tooltip: l10n.send,
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ],
      );
    }

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
                  s.sentence,
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (footer != null) ...[const SizedBox(height: 12), footer],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _footerStyle = TextStyle(color: Colors.white, fontSize: 14);
}
