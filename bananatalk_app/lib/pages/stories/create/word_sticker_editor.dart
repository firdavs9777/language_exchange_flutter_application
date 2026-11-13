import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/create/sticker_editor_kit.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Full-screen editor for the "word of the story" sticker. Returns the
/// [StoryWordSticker] via [Navigator.pop], or null on cancel.
class WordStickerEditor extends StatefulWidget {
  const WordStickerEditor({super.key, this.initial, this.defaultLanguage});

  final StoryWordSticker? initial;

  /// The user's learning language (base code) for a new sticker.
  final String? defaultLanguage;

  static const int maxWord = 60;
  static const int maxMeaning = 120;
  static const int maxExample = 200;

  @override
  State<WordStickerEditor> createState() => _WordStickerEditorState();
}

class _WordStickerEditorState extends State<WordStickerEditor> {
  late final TextEditingController _word;
  late final TextEditingController _meaning;
  late final TextEditingController _example;
  String? _language;

  @override
  void initState() {
    super.initState();
    _word = TextEditingController(text: widget.initial?.word ?? '');
    _meaning = TextEditingController(text: widget.initial?.meaning ?? '');
    _example = TextEditingController(text: widget.initial?.example ?? '');
    _language = widget.initial?.language ?? widget.defaultLanguage;
  }

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    _example.dispose();
    super.dispose();
  }

  bool _within(TextEditingController c, int max, {bool required = true}) {
    final n = trimmedLength(c.text);
    return n <= max && (!required || n > 0);
  }

  bool get _isValid =>
      _within(_word, WordStickerEditor.maxWord) &&
      _within(_meaning, WordStickerEditor.maxMeaning) &&
      _within(_example, WordStickerEditor.maxExample, required: false);

  void _done() {
    if (!_isValid) return;
    final example = _example.text.trim();
    Navigator.pop(
      context,
      StoryWordSticker(
        word: _word.text.trim(),
        meaning: _meaning.text.trim(),
        example: example.isEmpty ? null : example,
        language: _language,
      ),
    );
  }

  Widget _field(
    Key key,
    TextEditingController controller,
    String hint,
    int max, {
    bool required = true,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: key,
          controller: controller,
          autofocus: autofocus,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
          decoration: stickerFieldDecoration(
            hint: hint,
            error: !_within(controller, max, required: false),
          ),
        ),
        StickerCounter(text: controller.text, max: max),
        const SizedBox(height: 8),
      ],
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
          l10n.storyStickerWord,
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
              _field(
                const Key('word-word'),
                _word,
                l10n.storyWordHint,
                WordStickerEditor.maxWord,
                autofocus: true,
              ),
              _field(
                const Key('word-meaning'),
                _meaning,
                l10n.storyWordMeaningHint,
                WordStickerEditor.maxMeaning,
              ),
              _field(
                const Key('word-example'),
                _example,
                l10n.storyWordExampleHint,
                WordStickerEditor.maxExample,
                required: false,
              ),
              const SizedBox(height: 8),
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
