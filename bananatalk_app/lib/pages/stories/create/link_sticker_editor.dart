import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Attach a link to a story.
///
/// The URL is validated here as well as on the server. Not duplication for its
/// own sake: telling someone their address is wrong while they are still
/// looking at the field is worth far more than a rejection after they have
/// finished recording, and the server stays authoritative because a client
/// check is advice, not a guarantee.
///
/// http and https only — `javascript:` and `data:` are the classic payload
/// schemes for a tap target on someone else's screen.
Future<StoryLink?> showLinkStickerEditor(
  BuildContext context, {
  StoryLink? initial,
}) {
  return showModalBottomSheet<StoryLink>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _LinkStickerEditor(initial: initial),
  );
}

/// Whether [raw] is a link we are willing to show to other people.
///
/// Exposed for tests: the refusal list is the part that matters, and asserting
/// it through a rendered sheet would be brittle.
bool isAcceptableStoryLink(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  if (!uri.hasScheme) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  return uri.host.isNotEmpty;
}

class _LinkStickerEditor extends StatefulWidget {
  const _LinkStickerEditor({this.initial});

  final StoryLink? initial;

  @override
  State<_LinkStickerEditor> createState() => _LinkStickerEditorState();
}

class _LinkStickerEditorState extends State<_LinkStickerEditor> {
  late final TextEditingController _url =
      TextEditingController(text: widget.initial?.url ?? '');
  late final TextEditingController _label = TextEditingController(
    text: widget.initial?.displayText ?? '',
  );
  bool _showError = false;

  @override
  void dispose() {
    _url.dispose();
    _label.dispose();
    super.dispose();
  }

  void _save() {
    if (!isAcceptableStoryLink(_url.text)) {
      setState(() => _showError = true);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final label = _label.text.trim();
    Navigator.pop(
      context,
      StoryLink(
        url: _url.text.trim(),
        displayText: label.isEmpty ? l10n.storyLinkButtonDefault : label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const white = TextStyle(color: Colors.white);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.storyLinkAdd,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 16),
          TextField(
            key: const Key('story-link-url'),
            controller: _url,
            autofocus: true,
            style: white,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            decoration: InputDecoration(
              labelText: l10n.storyLinkUrlLabel,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'https://',
              hintStyle: const TextStyle(color: Colors.white30),
              errorText: _showError ? l10n.storyLinkInvalid : null,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00BFA5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('story-link-label'),
            controller: _label,
            style: white,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: l10n.storyLinkButtonLabel,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: l10n.storyLinkButtonDefault,
              hintStyle: const TextStyle(color: Colors.white30),
              counterStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00BFA5)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('story-link-save'),
            onPressed: _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
