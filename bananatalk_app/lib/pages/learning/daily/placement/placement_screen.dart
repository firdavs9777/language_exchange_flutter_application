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
    try {
      final submitter = widget.submit ?? LearningService.submitPlacement;
      final result = await submitter(List<int>.from(_answers));
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _answer(int option) async {
    _answers.add(option);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.placementTitle),
        actions: [
          TextButton(
            key: const Key('placement-skip'),
            onPressed: _finish,
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
            onSelect: _answer,
          ),
        ],
      ),
    );
  }
}
