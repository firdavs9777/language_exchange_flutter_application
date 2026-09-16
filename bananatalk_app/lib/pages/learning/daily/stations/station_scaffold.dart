import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/check_question.dart';

typedef SubmitAnswers = Future<StationResult> Function(List<int> answers);

/// The teach-then-check body shared by the vocabulary, grammar, listening and
/// wrap stations. Holds the answer state, the submit lifecycle and the error
/// path in ONE place so four stations cannot drift apart.
class CheckSequence extends StatefulWidget {
  final List<PackCheck> checks;
  final Widget? header;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const CheckSequence({
    super.key,
    required this.checks,
    required this.onSubmit,
    required this.onDone,
    this.header,
  });

  @override
  State<CheckSequence> createState() => _CheckSequenceState();
}

class _CheckSequenceState extends State<CheckSequence> {
  late final List<int?> _answers = List<int?>.filled(widget.checks.length, null);
  StationResult? _result;
  bool _submitting = false;
  bool _failed = false;

  bool get _allAnswered => !_answers.contains(null);

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      final result = await widget.onSubmit(_answers.map((a) => a ?? -1).toList());
      if (mounted) setState(() => _result = result);
    } catch (_) {
      // Keep the answers on screen: making the learner re-enter them after a
      // dropped connection is how a session gets abandoned.
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.header != null) widget.header!,
        if (widget.header != null) const SizedBox(height: 24),
        ...List.generate(widget.checks.length, (i) {
          // Null until the server answers, which is what puts CheckQuestion in
          // its marked state. The key can be shorter than the question list
          // (or absent entirely for an unscored station), so index defensively
          // rather than assuming they line up.
          final key = _result?.answerKey ?? const <int>[];
          final explanations = _result?.explanations ?? const <String>[];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: CheckQuestion(
              check: widget.checks[i],
              index: i,
              selected: _answers[i],
              correctIndex: i < key.length ? key[i] : null,
              explanation: i < explanations.length ? explanations[i] : null,
              onSelect: (o) => setState(() => _answers[i] = o),
            ),
          );
        }),
        if (_result != null)
          Padding(
            key: const Key('station-score'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.dailyScore(_result!.score, _result!.total),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        if (_failed)
          Padding(
            key: const Key('station-error'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.packSubmitFailed,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (_result == null)
          FilledButton(
            key: const Key('station-submit'),
            onPressed: (!_allAnswered || _submitting) ? null : _submit,
            child: Text(l10n.dailyCheck),
          )
        else
          FilledButton(
            key: const Key('station-continue'),
            onPressed: widget.onDone,
            child: Text(l10n.packContinue),
          ),
      ],
    );
  }
}
