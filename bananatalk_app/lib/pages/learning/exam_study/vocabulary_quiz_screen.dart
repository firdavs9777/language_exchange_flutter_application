import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/exam/vocabulary_word.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 10-Q MC vocabulary quiz with inline result screen on completion.
class VocabularyQuizScreen extends ConsumerStatefulWidget {
  const VocabularyQuizScreen({
    super.key,
    required this.examId,
    required this.level,
    this.topic,
  });

  final String examId;
  final String level;
  final String? topic;

  @override
  ConsumerState<VocabularyQuizScreen> createState() =>
      _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends ConsumerState<VocabularyQuizScreen> {
  bool _loading = true;
  String? _loadError;

  VocabularyQuizStart? _quiz;
  final Map<String, int> _selected = {};
  int _index = 0;

  bool _submitting = false;
  VocabularyQuizScore? _result;

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  Future<void> _startQuiz() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final quiz = await ref.read(examStudyServiceProvider).startVocabularyQuiz(
            examId: widget.examId,
            level: widget.level,
            topic: widget.topic,
          );
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
        _selected.clear();
        _index = 0;
        _result = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final quiz = _quiz;
    if (quiz == null) return;
    setState(() => _submitting = true);
    try {
      final answers = quiz.questions
          .map((q) => {
                'questionId': q.id,
                'choice': _selected[q.id] ?? -1,
              })
          .toList();
      final score = await ref
          .read(examStudyServiceProvider)
          .submitVocabularyQuiz(quizId: quiz.quizId, answers: answers);
      if (!mounted) return;
      setState(() {
        _result = score;
        _submitting = false;
      });
    } on VocabularyQuizExpiredException {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showExpiredDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showExpiredDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.examVocabQuizExpiredTitle),
        content: Text(l10n.examVocabQuizExpiredBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startQuiz();
            },
            child: Text(l10n.examVocabQuizRestart),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          _result != null
              ? l10n.examVocabQuizComplete
              : l10n.examVocabPractice,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _errorState(context, l10n, _loadError!);
    }
    if (_result != null) {
      return _resultView(context, l10n, _result!);
    }
    final quiz = _quiz;
    if (quiz == null || quiz.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.examVocabQuizEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return _quizView(context, l10n, quiz);
  }

  Widget _quizView(
    BuildContext context,
    AppLocalizations l10n,
    VocabularyQuizStart quiz,
  ) {
    final q = quiz.questions[_index];
    final picked = _selected[q.id];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                '${_index + 1} / ${quiz.questions.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / quiz.questions.length,
                    minHeight: 6,
                    backgroundColor: context.dividerColor,
                    valueColor:
                        AlwaysStoppedAnimation(context.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                q.prompt,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(q.options.length, (i) {
                final isPicked = picked == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selected[q.id] = i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isPicked
                              ? context.primaryColor.withValues(alpha: 0.12)
                              : context.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPicked
                                ? context.primaryColor
                                : context.dividerColor,
                            width: isPicked ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isPicked
                                    ? context.primaryColor
                                    : context.dividerColor,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isPicked
                                      ? Colors.white
                                      : context.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                q.options[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Row(
            children: [
              if (_index > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _index -= 1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.examVocabQuizPrev),
                  ),
                ),
              if (_index > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed:
                      (_submitting || picked == null) ? null : _onNextOrSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _index == quiz.questions.length - 1
                        ? (_submitting
                            ? l10n.examVocabQuizSubmitting
                            : l10n.examVocabQuizSubmit)
                        : l10n.examVocabQuizNext,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onNextOrSubmit() {
    final quiz = _quiz!;
    if (_index == quiz.questions.length - 1) {
      _submit();
    } else {
      setState(() => _index += 1);
    }
  }

  Widget _resultView(
    BuildContext context,
    AppLocalizations l10n,
    VocabularyQuizScore score,
  ) {
    final quiz = _quiz!;
    final questionsById = {for (final q in quiz.questions) q.id: q};

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                l10n.examVocabQuizScore(score.correctCount, score.total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${score.score}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(score.results.length, (i) {
          final r = score.results[i];
          final q = questionsById[r.questionId];
          final color = r.isCorrect ? Colors.green : Colors.red.shade400;
          final yourPick = _selected[r.questionId];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      r.isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q?.prompt ?? r.word ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (q != null && yourPick != null) ...[
                  const SizedBox(height: 8),
                  _answerRow(context, l10n.examVocabQuizYourAnswer,
                      q.options[yourPick], r.isCorrect ? color : Colors.red),
                ],
                if (!r.isCorrect && r.correctChoice != null && q != null) ...[
                  const SizedBox(height: 4),
                  _answerRow(context, l10n.examVocabQuizCorrectAnswer,
                      q.options[r.correctChoice!], Colors.green),
                ],
                if (r.example != null && r.example!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    r.example!,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _startQuiz,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(l10n.examVocabQuizRestart),
        ),
      ],
    );
  }

  Widget _answerRow(
      BuildContext context, String label, String value, Color color) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: context.textPrimary),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, AppLocalizations l10n, String err) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: context.textMuted),
          const SizedBox(height: 12),
          Text(
            err.contains('NOT_ENOUGH_WORDS')
                ? l10n.examVocabQuizNotEnough
                : l10n.examStudyError,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _startQuiz,
            child: Text(l10n.examStudyRetry),
          ),
        ],
      ),
    );
  }
}
