import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Full-screen editor for attaching a poll sticker to a story.
///
/// Lets the creator enter a question and 2-4 answer options. Returns the
/// resulting [StoryPoll] via [Navigator.pop] when the user taps "Done", or
/// `null` if they cancel.
class PollStickerEditor extends StatefulWidget {
  final StoryPoll? initial;

  const PollStickerEditor({super.key, this.initial});

  @override
  State<PollStickerEditor> createState() => _PollStickerEditorState();
}

class _PollStickerEditorState extends State<PollStickerEditor> {
  static const _teal = Color(0xFF00BFA5);
  static const _maxOptions = 4;
  static const _minOptions = 2;

  late final TextEditingController _questionController;
  late final List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.initial?.question ?? '');
    final initialOptions = widget.initial?.options ?? const [];
    if (initialOptions.length >= _minOptions) {
      _optionControllers = initialOptions
          .map((o) => TextEditingController(text: o.text))
          .toList();
    } else {
      _optionControllers = [TextEditingController(), TextEditingController()];
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < _maxOptions) {
      setState(() => _optionControllers.add(TextEditingController()));
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > _minOptions) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  bool get _isValid {
    final question = _questionController.text.trim();
    final filledOptions = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .length;
    return question.isNotEmpty && filledOptions >= _minOptions;
  }

  void _done() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < _minOptions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a question and at least 2 options')),
      );
      return;
    }

    final poll = StoryPoll(
      question: question,
      options: options
          .asMap()
          .entries
          .map((e) => StoryPollOption(index: e.key, text: e.value))
          .toList(),
    );
    Navigator.pop(context, poll);
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
        title: const Text('Add Poll', style: TextStyle(color: Colors.white)),
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
                'Question',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                autofocus: true,
                maxLength: 120,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
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
              const SizedBox(height: 20),
              const Text(
                'Options',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._optionControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          maxLength: 40,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Option ${entry.key + 1}',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.grey[900],
                            counterText: '',
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
                      ),
                      if (_optionControllers.length > _minOptions)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () => _removeOption(entry.key),
                        ),
                    ],
                  ),
                );
              }),
              if (_optionControllers.length < _maxOptions)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, color: _teal),
                  label: const Text('Add option', style: TextStyle(color: _teal)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
