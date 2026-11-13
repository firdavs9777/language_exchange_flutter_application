import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/create/sticker_editor_kit.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Full-screen editor for the quiz sticker: a question, 2-4 options and one
/// option marked correct. Returns the [StoryQuizSticker] via
/// [Navigator.pop], or null on cancel.
class QuizStickerEditor extends StatefulWidget {
  const QuizStickerEditor({super.key, this.initial});

  final StoryQuizSticker? initial;

  static const int maxQuestion = 200;
  static const int maxOption = 80;
  static const int minOptions = 2;
  static const int maxOptions = 4;

  @override
  State<QuizStickerEditor> createState() => _QuizStickerEditorState();
}

class _QuizStickerEditorState extends State<QuizStickerEditor> {
  late final TextEditingController _question;
  late final List<TextEditingController> _options;

  /// Position (in [_options], blank rows included) of the correct option.
  int? _correct;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _question = TextEditingController(text: initial?.question ?? '');
    final texts = initial?.options.map((o) => o.text).toList() ?? const [];
    _options =
        (texts.length >= QuizStickerEditor.minOptions ? texts : const ['', ''])
            .map((t) => TextEditingController(text: t))
            .toList();
    _correct = initial?.correctIndex;
    if (_correct != null && _correct! >= _options.length) _correct = null;
  }

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length < QuizStickerEditor.maxOptions) {
      setState(() => _options.add(TextEditingController()));
    }
  }

  void _removeOption(int i) {
    if (_options.length <= QuizStickerEditor.minOptions) return;
    setState(() {
      _options.removeAt(i).dispose();
      final c = _correct;
      if (c == null) return;
      if (c == i) {
        _correct = null;
      } else if (c > i) {
        _correct = c - 1;
      }
    });
  }

  String _key(TextEditingController c) => c.text.trim().toLowerCase();

  /// Non-blank option texts that repeat another option (case-insensitive,
  /// trimmed).
  bool _isDuplicate(int i) {
    final k = _key(_options[i]);
    if (k.isEmpty) return false;
    for (var j = 0; j < _options.length; j++) {
      if (j != i && _key(_options[j]) == k) return true;
    }
    return false;
  }

  bool get _isValid {
    final q = trimmedLength(_question.text);
    if (q == 0 || q > QuizStickerEditor.maxQuestion) return false;
    var filled = 0;
    for (var i = 0; i < _options.length; i++) {
      final n = trimmedLength(_options[i].text);
      if (n > QuizStickerEditor.maxOption || _isDuplicate(i)) return false;
      if (n > 0) filled++;
    }
    if (filled < QuizStickerEditor.minOptions) return false;
    final c = _correct;
    return c != null && trimmedLength(_options[c].text) > 0;
  }

  void _done() {
    if (!_isValid) return;
    final texts = <String>[];
    int? correct;
    for (var i = 0; i < _options.length; i++) {
      final t = _options[i].text.trim();
      if (t.isEmpty) continue;
      if (i == _correct) correct = texts.length;
      texts.add(t);
    }
    Navigator.pop(
      context,
      StoryQuizSticker(
        question: _question.text.trim(),
        options: [
          for (var i = 0; i < texts.length; i++)
            StoryQuizOption(index: i, text: texts[i]),
        ],
        correctIndex: correct,
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
          l10n.storyStickerQuiz,
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
                key: const Key('quiz-question'),
                controller: _question,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: stickerFieldDecoration(
                  hint: l10n.storyQuizQuestionHint,
                  error:
                      trimmedLength(_question.text) >
                      QuizStickerEditor.maxQuestion,
                ),
              ),
              StickerCounter(
                text: _question.text,
                max: QuizStickerEditor.maxQuestion,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Tooltip(
                        message: l10n.storyQuizMarkCorrect,
                        child: IconButton(
                          key: Key('quiz-correct-$i'),
                          icon: Icon(
                            _correct == i
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _correct == i
                                ? kStickerEditorTeal
                                : Colors.white54,
                          ),
                          onPressed: () => setState(() => _correct = i),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          key: Key('quiz-option-$i'),
                          controller: _options[i],
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() {}),
                          decoration: stickerFieldDecoration(
                            hint: l10n.storyQuizOptionHint((i + 1).toString()),
                            error:
                                _isDuplicate(i) ||
                                trimmedLength(_options[i].text) >
                                    QuizStickerEditor.maxOption,
                          ),
                        ),
                      ),
                      if (_options.length > QuizStickerEditor.minOptions)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _removeOption(i),
                        ),
                    ],
                  ),
                ),
              if (_options.length < QuizStickerEditor.maxOptions)
                TextButton.icon(
                  key: const Key('quiz-add-option'),
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, color: kStickerEditorTeal),
                  label: Text(
                    l10n.addOption,
                    style: const TextStyle(color: kStickerEditorTeal),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
