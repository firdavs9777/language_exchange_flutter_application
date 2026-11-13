import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/create/sticker_editor_kit.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Full-screen editor for the "correct my sentence" sticker. Returns the
/// [StoryCorrectionSticker] via [Navigator.pop], or null on cancel.
class CorrectionStickerEditor extends StatefulWidget {
  const CorrectionStickerEditor({
    super.key,
    this.initial,
    this.defaultLanguage,
  });

  final StoryCorrectionSticker? initial;

  /// The user's learning language (base code) for a new sticker.
  final String? defaultLanguage;

  static const int maxSentence = 300;

  @override
  State<CorrectionStickerEditor> createState() =>
      _CorrectionStickerEditorState();
}

class _CorrectionStickerEditorState extends State<CorrectionStickerEditor> {
  late final TextEditingController _sentence;
  String? _language;

  @override
  void initState() {
    super.initState();
    _sentence = TextEditingController(text: widget.initial?.sentence ?? '');
    _language = widget.initial?.language ?? widget.defaultLanguage;
  }

  @override
  void dispose() {
    _sentence.dispose();
    super.dispose();
  }

  bool get _isValid {
    final n = trimmedLength(_sentence.text);
    return n > 0 && n <= CorrectionStickerEditor.maxSentence;
  }

  void _done() {
    if (!_isValid) return;
    Navigator.pop(
      context,
      StoryCorrectionSticker(
        sentence: _sentence.text.trim(),
        language: _language,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          l10n.storyStickerCorrection,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          stickerDoneAction(
            context,
            label: l10n.done,
            enabled: _isValid,
            onTap: _done,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('correction-sentence'),
                controller: _sentence,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: stickerFieldDecoration(
                  hint: l10n.storyCorrectionSentenceHint,
                  error:
                      trimmedLength(_sentence.text) >
                      CorrectionStickerEditor.maxSentence,
                ),
              ),
              StickerCounter(
                text: _sentence.text,
                max: CorrectionStickerEditor.maxSentence,
              ),
              const SizedBox(height: 16),
              StickerLanguageField(
                code: _language,
                onChanged: (c) => setState(() => _language = c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
