import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';

typedef SubmitAnswers = Future<DailyCompletionResult> Function(String itemId, List<int> answers);
typedef SubmitFeedback = Future<String> Function(String itemId, String verdict);

/// One daily item: explanation, examples, and a 3-question check (spec §4.8).
///
/// The two submit callbacks are injectable so widget tests never hit the
/// network; production callers use the defaults.
class DailyDropScreen extends StatefulWidget {
  final DailyItem item;
  final SubmitAnswers submitAnswers;
  final SubmitFeedback submitFeedback;

  DailyDropScreen({
    super.key,
    required this.item,
    SubmitAnswers? submitAnswers,
    SubmitFeedback? submitFeedback,
  })  : submitAnswers = submitAnswers ?? LearningService.completeDailyItem,
        submitFeedback = submitFeedback ?? LearningService.submitDailyFeedback;

  @override
  State<DailyDropScreen> createState() => _DailyDropScreenState();
}

class _DailyDropScreenState extends State<DailyDropScreen> {
  late final List<int?> _answers =
      List<int?>.filled(widget.item.quickCheck.length, null);
  DailyCompletionResult? _result;
  bool _submitting = false;

  bool get _allAnswered => !_answers.contains(null);

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await widget.submitAnswers(
        widget.item.id,
        _answers.map((a) => a ?? -1).toList(),
      );
      if (mounted) setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _feedback(String verdict) async {
    await widget.submitFeedback(widget.item.id, verdict);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.explanation, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          ...item.examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.text, style: Theme.of(context).textTheme.titleSmall),
                    if (e.translation.isNotEmpty)
                      Text(e.translation, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              )),
          const Divider(height: 16),
          ...List.generate(item.quickCheck.length, (i) {
            final q = item.quickCheck[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.prompt, style: Theme.of(context).textTheme.titleSmall),
                ...List.generate(q.options.length, (o) => RadioListTile<int>(
                      key: Key('daily-q$i-opt$o'),
                      value: o,
                      groupValue: _answers[i],
                      title: Text(q.options[o]),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      onChanged: _result != null
                          ? null
                          : (v) => setState(() => _answers[i] = v),
                    )),
                const SizedBox(height: 4),
              ],
            );
          }),
          if (_result != null)
            Text('${_result!.score}/${_result!.total}',
                style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('daily-submit'),
            onPressed: (!_allAnswered || _submitting || _result != null) ? null : _submit,
            child: const Text('Check'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                key: const Key('daily-too-easy'),
                onPressed: () => _feedback('tooEasy'),
                child: const Text('Too easy'),
              ),
              TextButton(
                key: const Key('daily-too-hard'),
                onPressed: () => _feedback('tooHard'),
                child: const Text('Too hard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
