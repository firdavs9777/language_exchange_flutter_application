import 'package:bananatalk_app/models/learning/vocab_pack_model.dart';
import 'package:flutter/material.dart';

/// Plays through a pack's exercises (multiple_choice, fill_blank, matching,
/// error_correction) with inline scoring and a result summary at the end.
class VocabPackPracticeScreen extends StatefulWidget {
  final String topic;
  final List<VocabPackExercise> exercises;
  const VocabPackPracticeScreen(
      {super.key, required this.topic, required this.exercises});

  @override
  State<VocabPackPracticeScreen> createState() =>
      _VocabPackPracticeScreenState();
}

class _VocabPackPracticeScreenState extends State<VocabPackPracticeScreen> {
  int _index = 0;
  int _correct = 0;
  bool _answered = false;
  bool _lastCorrect = false;

  // per-question transient answer state
  int? _selectedOption; // multiple_choice
  final TextEditingController _textController = TextEditingController();
  final Map<String, String> _matchSelections = {}; // term -> chosen definition

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  VocabPackExercise get _current => widget.exercises[_index];
  bool get _isLast => _index == widget.exercises.length - 1;

  void _resetQuestionState() {
    _answered = false;
    _lastCorrect = false;
    _selectedOption = null;
    _textController.clear();
    _matchSelections.clear();
  }

  bool _normalizedEquals(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _checkAnswer() {
    final ex = _current;
    bool correct = false;
    switch (ex.type) {
      case 'multiple_choice':
        correct = _selectedOption != null && _selectedOption == ex.answerIndex;
        break;
      case 'fill_blank':
        correct = ex.answer != null &&
            _normalizedEquals(_textController.text, ex.answer!);
        break;
      case 'error_correction':
        correct = ex.corrected != null &&
            _normalizedEquals(_textController.text, ex.corrected!);
        break;
      case 'matching':
        final pairs = ex.pairs ?? [];
        correct = pairs.isNotEmpty &&
            pairs.every((p) =>
                _matchSelections[p.term] != null &&
                _normalizedEquals(_matchSelections[p.term]!, p.definition));
        break;
    }
    setState(() {
      _answered = true;
      _lastCorrect = correct;
      if (correct) _correct++;
    });
  }

  void _next() {
    if (_isLast) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Practice complete'),
          content: Text(
              'You got $_correct of ${widget.exercises.length} correct.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _resetQuestionState();
    });
  }

  bool _canCheck() {
    switch (_current.type) {
      case 'multiple_choice':
        return _selectedOption != null;
      case 'fill_blank':
      case 'error_correction':
        return _textController.text.trim().isNotEmpty;
      case 'matching':
        final pairs = _current.pairs ?? [];
        return pairs.isNotEmpty &&
            pairs.every((p) => _matchSelections[p.term] != null);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = _current;
    final total = widget.exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_index + 1) / total),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${_index + 1} of $total',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: _buildQuestion(ex))),
            if (_answered) _buildFeedback(ex),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _answered
                    ? _next
                    : (_canCheck() ? _checkAnswer : null),
                child: Text(_answered
                    ? (_isLast ? 'Finish' : 'Next')
                    : 'Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(VocabPackExercise ex) {
    switch (ex.type) {
      case 'multiple_choice':
        return _buildMultipleChoice(ex);
      case 'fill_blank':
        return _buildTextInput(ex, ex.prompt ?? '', 'Type the missing word');
      case 'error_correction':
        return _buildTextInput(
            ex, ex.prompt ?? '', 'Rewrite the sentence correctly');
      case 'matching':
        return _buildMatching(ex);
      default:
        return Text(ex.prompt ?? 'Unsupported exercise');
    }
  }

  Widget _buildMultipleChoice(VocabPackExercise ex) {
    final options = ex.options ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ex.prompt ?? '',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...List.generate(options.length, (i) {
          Color? tileColor;
          if (_answered) {
            if (i == ex.answerIndex) {
              tileColor = Colors.green.withValues(alpha: 0.18);
            } else if (i == _selectedOption) {
              tileColor = Colors.red.withValues(alpha: 0.15);
            }
          } else if (i == _selectedOption) {
            tileColor =
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
          }
          return Card(
            color: tileColor,
            child: RadioListTile<int>(
              value: i,
              groupValue: _selectedOption,
              onChanged: _answered
                  ? null
                  : (v) => setState(() => _selectedOption = v),
              title: Text(options[i]),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextInput(VocabPackExercise ex, String prompt, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          enabled: !_answered,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildMatching(VocabPackExercise ex) {
    final pairs = ex.pairs ?? [];
    // shuffle definitions deterministically by index offset so the answer
    // order isn't the display order
    final defs = pairs.map((p) => p.definition).toList();
    final rotated = [
      ...defs.skip(1),
      if (defs.isNotEmpty) defs.first,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Match each word to its meaning',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...pairs.map((p) {
          final chosen = _matchSelections[p.term];
          final isRight =
              chosen != null && _normalizedEquals(chosen, p.definition);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(p.term,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: chosen,
                    hint: const Text('Choose…'),
                    onChanged: _answered
                        ? null
                        : (v) => setState(() => _matchSelections[p.term] = v!),
                    items: rotated
                        .toSet()
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                  ),
                ),
                if (_answered)
                  Icon(isRight ? Icons.check_circle : Icons.cancel,
                      color: isRight ? Colors.green : Colors.red, size: 20),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeedback(VocabPackExercise ex) {
    String? solution;
    if (!_lastCorrect) {
      switch (ex.type) {
        case 'multiple_choice':
          if (ex.answerIndex != null && ex.options != null) {
            solution = 'Correct answer: ${ex.options![ex.answerIndex!]}';
          }
          break;
        case 'fill_blank':
          solution = 'Correct answer: ${ex.answer ?? ''}';
          break;
        case 'error_correction':
          solution = 'Correct: ${ex.corrected ?? ''}';
          break;
        case 'matching':
          solution = 'Review the correct matches above.';
          break;
      }
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_lastCorrect ? Colors.green : Colors.red).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_lastCorrect ? Icons.check_circle : Icons.info_outline,
              color: _lastCorrect ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lastCorrect
                  ? 'Correct!'
                  : (solution ?? 'Not quite.'),
            ),
          ),
        ],
      ),
    );
  }
}
