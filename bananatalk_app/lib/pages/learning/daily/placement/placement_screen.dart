import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/check_question.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Eight questions, one screen each, to set a starting level.
///
/// The questions are in the learner's target language: English uses the
/// hand-written bank, every other language an AI-written set the server has
/// checked. For a language with no such set the screen says so instead of
/// offering a retry.
///
/// 697 of 758 active learners have no level at all, so the pack is otherwise
/// guessing. Skipping is always allowed and the server falls back to its
/// default level — a forced test at the door costs more learners than a
/// slightly wrong starting level does.
/// The app locale as the placement API takes it: the language code, plus
/// `zh_TW` for Traditional Chinese.
String placementLocaleTag(Locale locale) {
  if (locale.languageCode == 'zh' &&
      (locale.countryCode == 'TW' || locale.scriptCode == 'Hant')) {
    return 'zh_TW';
  }
  return locale.languageCode;
}

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
  bool _unavailable = false;
  bool _started = false;
  String _locale = 'en';

  /// A submit is in flight; further taps and skips are ignored so a fast
  /// double tap cannot send twice.
  bool _submitting = false;
  bool _submitFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _locale = placementLocaleTag(Localizations.localeOf(context));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final loader = widget.load ?? () => LearningService.getPlacement(locale: _locale);
      final questions = await loader();
      if (mounted) setState(() => _questions = questions);
    } on PlacementUnavailableException {
      if (mounted) setState(() => _unavailable = true);
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
      final submitter = widget.submit ??
          (List<int> a) => LearningService.submitPlacement(a, locale: _locale);
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

    if (_unavailable) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.placementTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              key: const Key('placement-unavailable'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.placementUnavailable, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.packContinue),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
      return _PlacementResultView(
        result: PlacementResult.fromJson(_result!),
        onStart: widget.onFinished ?? () => Navigator.of(context).maybePop(),
      );
    }

    final questions = _questions;
    if (questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.placementTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              // The first learner of a language waits while the test is written.
              Text(l10n.placementPreparing,
                  style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
            ],
          ),
        ),
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

/// Level, score, what to work on next, then every question with the learner's
/// pick and the right answer. After a skip (or from an older server) there is
/// no review, so only the level and the start button show.
class _PlacementResultView extends StatelessWidget {
  final PlacementResult result;
  final VoidCallback onStart;

  const _PlacementResultView({required this.result, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasReview = result.review.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.placementTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Center(
                    child: Text(result.level,
                        key: const Key('placement-level'),
                        style: theme.textTheme.displaySmall),
                  ),
                  if (hasReview) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        l10n.placementScore(result.correct, result.total),
                        key: const Key('placement-score'),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(l10n.placementResult,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: context.textSecondary)),
                  if (hasReview) ...[
                    const SizedBox(height: 20),
                    _FocusCard(topics: result.focusTopics),
                    const SizedBox(height: 24),
                    Text(l10n.placementReviewTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (var i = 0; i < result.review.length; i++)
                      _ReviewItem(item: result.review[i], index: i),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('placement-start'),
                  onPressed: onStart,
                  child: Text(l10n.placementStart),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final List<String> topics;

  const _FocusCard({required this.topics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      key: const Key('placement-focus'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.placementFocusTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (topics.isEmpty)
            Text(l10n.placementAllCorrect, style: theme.textTheme.bodyMedium)
          else
            for (final topic in topics)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(topic, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final PlacementReviewItem item;
  final int index;

  const _ReviewItem({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = item.correct ? theme.colorScheme.primary : theme.colorScheme.error;
    // Status as icon AND text, never colour alone.
    final status = item.correct
        ? l10n.lessonResultCorrect
        : (item.given == null ? l10n.placementNotAnswered : l10n.lessonResultIncorrect);
    return Padding(
      key: Key('placement-review-$index'),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.correct ? Icons.check_circle : Icons.cancel, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.topic.isEmpty ? status : '$status · ${item.topic}',
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckQuestion(
            check: item.check,
            index: index,
            selected: item.given,
            correctIndex: item.answerIndex,
            explanation: item.correct ? null : item.explanation,
            onSelect: (_) {},
          ),
        ],
      ),
    );
  }
}
