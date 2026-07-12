import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Full-screen editor for attaching a question box sticker to a story.
///
/// Lets the creator enter a prompt (e.g. "Ask me anything!"). Returns the
/// resulting [StoryQuestionBox] via [Navigator.pop] when the user taps
/// "Done", or `null` if they cancel.
class QuestionStickerEditor extends StatefulWidget {
  final StoryQuestionBox? initial;

  const QuestionStickerEditor({super.key, this.initial});

  @override
  State<QuestionStickerEditor> createState() => _QuestionStickerEditorState();
}

class _QuestionStickerEditorState extends State<QuestionStickerEditor> {
  static const _teal = Color(0xFF00BFA5);
  static const _quickPrompts = [
    'Ask me anything! 🎤',
    'Questions? 💬',
    'AMA! 🙋',
  ];

  late final TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text: widget.initial?.prompt ?? 'Ask me anything!',
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  bool get _isValid => _promptController.text.trim().isNotEmpty;

  void _done() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    Navigator.pop(context, StoryQuestionBox(prompt: prompt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        leadingWidth: 80,
        title: const Text('Add Question', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isValid ? _done : null,
            child: Text(
              'Done',
              style: TextStyle(
                color: _isValid ? _teal : Colors.white30,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prompt',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _promptController,
                autofocus: true,
                maxLength: 80,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Your prompt...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  counterStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _teal, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPrompts.map((text) {
                  return ActionChip(
                    label: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: Colors.grey[800],
                    onPressed: () => setState(() => _promptController.text = text),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
