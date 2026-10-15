import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/check_question.dart';
import 'package:bananatalk_app/services/learning_service.dart';

/// Eight questions, one screen each, to set a starting level.
///
/// 697 of 758 active learners have no level at all, so the pack is otherwise
/// guessing. Skipping is always allowed and the server falls back to its
/// default level — a forced test at the door costs more learners than a
/// slightly wrong starting level does.
class PlacementScreen extends StatefulWidget {
  final Future<List<PackCheck>> Function()? load;
  final Future<Map<String, dynamic>> Function(List<int>)? submit;
  final VoidCallback? onFinished;

  const PlacementScreen({super.key, this.load, this.submit, this.onFinished});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  List<PackCheck>? _questions;
  final List<int> _answers = [];
  int _index = 0;
  Map<String, dynamic>? _result;
  bool _failed = false;

  /// A submit is in flight; further taps and skips are ignored so a fast
  /// double tap cannot send twice.
  bool _submitting = false;
  bool _submitFailed = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final loader = widget.load ?? LearningService.getPlacement;
      final questions = await loader();
      if (mounted) setState(() => _questions = questions);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitFailed = false;
    });
    try {
      final submitter = widget.submit ?? LearningService.submitPlacement;
      // Never more answers than questions: the server rejects that with a
      // 400 on every retry.
      final result = await submitter(
          _answers.take(_questions?.length ?? _answers.length).toList());
      if (mounted) setState(() => _result = result);
    } catch (_) {
      // Stay on the last question with the answers kept, and offer a retry.
      if (mounted) setState(() => _submitFailed = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _answer(int option) async {
    if (_submitting) return;
    // Replace rather than append, so re-answering after a failed submit
    // changes that answer instead of adding a ninth.
    if (_index < _answers.length) {
      _answers[_index] = option;
    } else {
      _answers.add(option);
    }
    if (_index + 1 < (_questions?.length ?? 0)) {
      setState(() => _index += 1);
      return;
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_failed && _result == null && _questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.placementTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              key: const Key('placement-error'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.packSubmitFailed, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() => _failed = false);
                    _loadQuestions();
                  },
                  child: Text(l10n.packContinue),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_result != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_result!['level']}', style: theme.textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(l10n.placementResult, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('placement-start'),
                  onPressed: widget.onFinished ?? () => Navigator.of(context).maybePop(),
                  child: Text(l10n.placementStart),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final questions = _questions;
    if (questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.placementTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.placementTitle),
        actions: [
          TextButton(
            key: const Key('placement-skip'),
            onPressed: _submitting ? null : _finish,
            child: Text(l10n.placementSkip),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.placementProgress(_index + 1, questions.length),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 20),
          CheckQuestion(
            check: questions[_index],
            index: _index,
            selected: _index < _answers.length ? _answers[_index] : null,
            onSelect: _answer,
          ),
          if (_submitting)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_submitFailed && !_submitting)
            Padding(
              key: const Key('placement-submit-error'),
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Text(
                    l10n.packSubmitFailed,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('placement-submit-retry'),
                    onPressed: _finish,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
