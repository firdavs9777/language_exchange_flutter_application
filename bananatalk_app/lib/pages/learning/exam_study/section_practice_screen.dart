import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/essay_editor_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/question_mc_card.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_question.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_submission_result.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/services/exam_study_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section practice — pages through MC questions, posts each answer to
/// the backend, shows instant feedback, and after the last question
/// invalidates the user's progress so the dashboard updates.
///
/// Essay/speaking questions are gracefully skipped with a "coming soon"
/// chip until Chunk D wires the async-eval flow.
class SectionPracticeScreen extends ConsumerStatefulWidget {
  const SectionPracticeScreen({
    super.key,
    required this.section,
    required this.examId,
    this.topic,
  });

  final ExamSection section;
  final String examId;

  /// When non-null, the practice screen pulls only questions tagged with
  /// this topic. Null = all topics (legacy behavior).
  final String? topic;

  @override
  ConsumerState<SectionPracticeScreen> createState() =>
      _SectionPracticeScreenState();
}

class _SectionPracticeScreenState
    extends ConsumerState<SectionPracticeScreen> {
  int _index = 0;
  String? _selectedOption;
  bool _submitting = false;
  InstantResult? _lastResult;
  String? _serverConfirmedCorrectOption;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questionsAsync = ref.watch(
      questionsForSectionProvider(
        QuestionsQuery(
          sectionId: widget.section.id,
          limit: 20,
          topic: widget.topic,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.section.sectionName,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            if (widget.topic != null)
              Text(
                widget.topic!,
                style: TextStyle(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return _emptyState(l10n);
          }
          if (_index >= questions.length) {
            return _completedState(l10n);
          }
          final current = questions[_index];
          return _buildPracticeBody(current, questions.length, l10n);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _errorState(l10n),
      ),
    );
  }

  Widget _buildPracticeBody(
    ExamQuestion question,
    int total,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        _progressBar(total, l10n),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: _renderQuestion(question, l10n),
          ),
        ),
        _bottomBar(question, total, l10n),
      ],
    );
  }

  Widget _renderQuestion(ExamQuestion question, AppLocalizations l10n) {
    if (question.isMultipleChoice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionMcCard(
            question: question,
            selectedOption: _selectedOption,
            onSelect: (label) => setState(() => _selectedOption = label),
            locked: _lastResult != null,
            correctOption: _serverConfirmedCorrectOption,
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            _feedbackCard(_lastResult!, l10n),
          ],
        ],
      );
    }
    if (question.isEssay) {
      // Essay flow lives in its own full-screen editor so the user has
      // space to write + see the prompt. The Submit button on the
      // bottom bar opens it.
      return _essayPromptCard(question, l10n);
    }
    // Speaking-prompt / fill-blank — still placeholder, lands later.
    return _unsupportedQuestionCard(question, l10n);
  }

  Widget _essayPromptCard(ExamQuestion question, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 18, color: context.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.examEssayPrompt,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressBar(int total, AppLocalizations l10n) {
    final fraction = ((_index) / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      color: context.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.examPracticeProgress(_index + 1, total),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: context.dividerColor,
              valueColor: AlwaysStoppedAnimation(context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackCard(InstantResult result, AppLocalizations l10n) {
    final isCorrect = result.isCorrect;
    final color =
        isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect
                    ? l10n.examQuestionCorrect
                    : l10n.examQuestionIncorrect,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (result.explanation != null && result.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.examQuestionExplanation,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.textMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.explanation!,
              style: TextStyle(
                fontSize: 14,
                color: context.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _unsupportedQuestionCard(
    ExamQuestion question,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, size: 18, color: context.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question.isEssay
                      ? l10n.examQuestionEssayComingSoon
                      : l10n.examQuestionUnsupported,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(
    ExamQuestion question,
    int total,
    AppLocalizations l10n,
  ) {
    // After MC submit we render Next. For essay questions the bottom
    // button always says "Write essay" — pressing it opens the editor.
    final mcCanSubmit = question.isMultipleChoice &&
        _selectedOption != null &&
        _lastResult == null &&
        !_submitting;
    final showNext = _lastResult != null;

    String label;
    VoidCallback? onPressed;
    if (showNext) {
      label = l10n.examQuestionNext;
      onPressed = () => _advance(total);
    } else if (question.isEssay) {
      label = l10n.examEssaySubmit;
      onPressed = () => _openEssayEditor(question, total);
    } else if (question.isMultipleChoice) {
      label = l10n.examQuestionSubmit;
      onPressed = mcCanSubmit ? () => _submit(question) : null;
    } else {
      label = l10n.examQuestionNext;
      onPressed = () => _advance(total);
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.dividerColor)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  context.primaryColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEssayEditor(ExamQuestion question, int total) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => EssayEditorScreen(
          question: question,
          examId: widget.examId,
        ),
      ),
    );
    if (!mounted) return;
    // After the editor (and its result screen) pop, advance past this
    // essay so the user doesn't see the same prompt again on return.
    _advance(total);
  }

  Future<void> _submit(ExamQuestion question) async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(examStudyServiceProvider)
          .submitAnswer(
            questionId: question.id,
            userAnswer: _selectedOption!,
          );
      if (!mounted) return;
      if (result is InstantResult) {
        setState(() {
          _lastResult = result;
          // Backend doesn't echo the correctAnswer for MC — we know
          // the user's pick was right/wrong, so if they were wrong the
          // correct answer is whichever option they didn't pick that
          // we can't show authoritatively without a fetch. Use the
          // server's isCorrect flag to tint the row they chose; leave
          // the "correct" highlight for the user's own pick when right.
          _serverConfirmedCorrectOption =
              result.isCorrect ? _selectedOption : null;
        });
      } else {
        // AsyncResult — Chunk D will route to the eval-polling screen.
        // Shouldn't happen for MC but guard anyway.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.examQuestionEssayComingSoon)),
        );
      }
    } on ExamFeatureUnavailableException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _advance(int total) {
    setState(() {
      _index += 1;
      _selectedOption = null;
      _lastResult = null;
      _serverConfirmedCorrectOption = null;
    });
    // Invalidate progress when we leave a question so the dashboard
    // picks up the new tally even if the user backs out mid-session.
    final userId = ref.read(authServiceProvider).userId;
    if (userId.isNotEmpty) {
      ref.invalidate(
        userExamProgressProvider(
          ProgressKey(userId: userId, examId: widget.examId),
        ),
      );
    }
  }

  Widget _emptyState(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.examQuestionNoQuestions,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ),
      );

  Widget _errorState(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 40, color: context.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.examStudyError,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(
                  questionsForSectionProvider(
                    QuestionsQuery(sectionId: widget.section.id, limit: 20),
                  ),
                ),
                child: Text(l10n.examStudyRetry),
              ),
            ],
          ),
        ),
      );

  Widget _completedState(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration_rounded,
                size: 48,
                color: context.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.examPracticeFinishedTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.examPracticeFinishedBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(l10n.examPracticeBackToDashboard),
              ),
            ],
          ),
        ),
      );
}
