import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';

/// Quiz Player Screen - Interactive quiz taking experience
class QuizPlayerScreen extends ConsumerStatefulWidget {
  const QuizPlayerScreen({super.key});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  final TextEditingController _fillBlankController = TextEditingController();

  // Per-question answer locking: index -> answered (locked)
  final Map<int, bool> _locked = {};
  // Per-question correctness tracked locally
  final Map<int, bool> _correctness = {};
  // Streak
  int _streak = 0;

  @override
  void dispose() {
    _fillBlankController.dispose();
    super.dispose();
  }

  void _selectAnswer(String answer, AIQuizQuestion question, int index) {
    if (_locked[index] == true) return;

    ref.read(aiQuizProvider.notifier).answerQuestion(index, answer);

    final correct = question.correctAnswer != null &&
        answer.trim().toLowerCase() == question.correctAnswer!.trim().toLowerCase();

    setState(() {
      _locked[index] = true;
      _correctness[index] = correct;
      if (correct) {
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  void _nextQuestion() {
    ref.read(aiQuizProvider.notifier).nextQuestion();
    final state = ref.read(aiQuizProvider);
    final nextIndex = state.currentIndex;
    if (_fillBlankController.text != (state.answers[nextIndex] ?? '')) {
      _fillBlankController.text = state.answers[nextIndex] ?? '';
    }
  }

  Future<void> _submitQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.aiQuizSubmitTitle),
        content: Text(AppLocalizations.of(context)!.aiQuizSubmitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(AppLocalizations.of(context)!.submit),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(aiQuizProvider.notifier).completeQuiz();
      if (success && mounted) {
        _showResults();
      }
    }
  }

  void _showResults() {
    final state = ref.read(aiQuizProvider);
    final result = state.result;
    final quiz = state.quiz;
    if (result == null || quiz == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _getScoreColor(result.percentage.toInt()).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.grade,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(result.percentage.toInt()),
                        ),
                      ),
                      Text(
                        '${result.percentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getScoreColor(result.percentage.toInt()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.percentage >= 80
                    ? 'Great job!'
                    : result.percentage >= 60
                        ? 'Good effort!'
                        : 'Keep practicing!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.correctCount} out of ${result.totalQuestions} correct',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultItem(Icons.star_rounded, '+${result.xpEarned}', 'XP', Colors.amber),
                  _buildResultItem(Icons.timer_rounded, '${(result.timeSpent / 60).floor()}m', 'Time', Colors.blue),
                  _buildResultItem(Icons.trending_up_rounded, '${result.accuracyRate.toInt()}%', 'Accuracy', Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quiz.questions.length,
                  itemBuilder: (context, i) {
                    final q = quiz.questions[i];
                    final wasCorrect = _correctness[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            wasCorrect == true ? Icons.check_circle : Icons.cancel,
                            color: wasCorrect == true ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.question,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                if (q.correctAnswer != null)
                                  Text(
                                    q.correctAnswer!,
                                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RewardedAdButton(
                  label: 'Watch Ad for +10 Bonus XP',
                  onRewarded: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('+10 Bonus XP earned! 🎉')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(aiQuizProvider.notifier).reset();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Quiz Hub',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiQuizProvider);
    final quiz = state.quiz;
    final question = state.currentQuestion;

    if (quiz == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.aiQuizTitle),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.aiQuizTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(aiQuizProvider.notifier).reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No questions available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'This quiz has no questions to display.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(aiQuizProvider.notifier).reset();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                child: Text(AppLocalizations.of(context)!.goBack),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.aiQuizExitTitle),
            content: Text(AppLocalizations.of(context)!.aiQuizExitBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: Text(AppLocalizations.of(context)!.exit),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          ref.read(aiQuizProvider.notifier).reset();
        }
        return confirmed ?? false;
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: context.surfaceColor,
          leading: IconButton(
            icon: Icon(Icons.close, color: context.textPrimary),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.aiQuizExitTitle),
                  content: Text(AppLocalizations.of(context)!.aiQuizExitBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: Text(AppLocalizations.of(context)!.exit),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                ref.read(aiQuizProvider.notifier).reset();
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            children: [
              Text(
                quiz.title,
                style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Question ${state.currentIndex + 1} of ${quiz.questions.length}',
                style: context.caption?.copyWith(color: context.textSecondary),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Progress dots
            _buildProgressDots(state, quiz),

            // Question Content
            Expanded(
              child: question != null
                  ? SingleChildScrollView(
                      padding: Spacing.paddingXL,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Type Badge + streak
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: AppRadius.borderMD,
                                ),
                                child: Text(
                                  _getQuestionTypeLabel(question.type),
                                  style: context.caption?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_streak >= 2)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: AppRadius.borderMD,
                                  ),
                                  child: Text(
                                    '🔥 $_streak',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Spacing.gapLG,

                          // Question Text
                          Text(
                            question.question,
                            style: context.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),

                          // Context if available
                          if (question.context != null) ...[
                            Spacing.gapMD,
                            Container(
                              padding: Spacing.paddingMD,
                              decoration: BoxDecoration(
                                color: context.containerColor,
                                borderRadius: AppRadius.borderSM,
                              ),
                              child: Text(
                                question.context!,
                                style: context.bodyMedium?.copyWith(
                                  color: context.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],

                          // Hint
                          if (question.hint != null) ...[
                            Spacing.gapMD,
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                                Spacing.hGapSM,
                                Expanded(
                                  child: Text(
                                    question.hint!,
                                    style: context.bodySmall?.copyWith(color: AppColors.warning),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Spacing.gapXL,

                          // Answer Options
                          _buildAnswerSection(state, question),

                          // Inline feedback after locking
                          if (_locked[state.currentIndex] == true)
                            _buildAnswerFeedback(state.currentIndex, question),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Navigation
            _buildNavigationBar(state, quiz),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(AIQuizState state, AIQuiz quiz) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: context.surfaceColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(quiz.questions.length, (i) {
            final isCurrent = i == state.currentIndex;
            final isPast = i < state.currentIndex;
            Color dotColor;
            double size;

            if (isCurrent) {
              dotColor = AppColors.error;
              size = 12;
            } else if (isPast) {
              dotColor = _correctness[i] == true ? Colors.green : Colors.red;
              size = 8;
            } else {
              dotColor = Colors.transparent;
              size = 8;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: (!isCurrent && !isPast)
                    ? Border.all(color: context.dividerColor, width: 1.5)
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnswerFeedback(int index, AIQuizQuestion question) {
    final correct = _correctness[index] ?? false;
    final feedbackText = question.explanation?.isNotEmpty == true
        ? question.explanation!
        : (question.correctAnswer != null
            ? 'Correct answer: ${question.correctAnswer}'
            : null);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: correct ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: correct ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: correct ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: correct ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
                if (feedbackText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    feedbackText,
                    style: context.bodySmall?.copyWith(color: context.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(AIQuizState state, AIQuizQuestion question) {
    final currentAnswer = state.answers[state.currentIndex];

    switch (question.type) {
      case 'multiple_choice':
        return _buildMultipleChoice(state, question, currentAnswer);
      case 'fill_blank':
        return _buildFillBlank(state, currentAnswer);
      case 'true_false':
        return _buildTrueFalse(state, question, currentAnswer);
      case 'translation':
        return _buildTranslation(state, currentAnswer);
      default:
        return _buildMultipleChoice(state, question, currentAnswer);
    }
  }

  Widget _buildMultipleChoice(AIQuizState state, AIQuizQuestion question, String? currentAnswer) {
    if (question.options == null) return const SizedBox.shrink();
    final locked = _locked[state.currentIndex] == true;

    return Column(
      children: question.options!.map((option) {
        final isSelected = currentAnswer == option;
        final isCorrectOption = question.correctAnswer != null &&
            option.trim().toLowerCase() == question.correctAnswer!.trim().toLowerCase();

        Color borderColor;
        Color bgColor;
        Widget? trailingIcon;

        if (locked) {
          if (isSelected && isCorrectOption) {
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.1);
            trailingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
          } else if (isSelected && !isCorrectOption) {
            borderColor = Colors.red;
            bgColor = Colors.red.withOpacity(0.1);
            trailingIcon = const Icon(Icons.cancel, color: Colors.red, size: 20);
          } else if (!isSelected && isCorrectOption) {
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.08);
            trailingIcon = const Icon(Icons.check_circle_outline, color: Colors.green, size: 20);
          } else {
            borderColor = context.dividerColor;
            bgColor = context.cardBackground;
            trailingIcon = null;
          }
        } else {
          borderColor = isSelected ? AppColors.error : context.dividerColor;
          bgColor = isSelected ? AppColors.error.withOpacity(0.1) : context.cardBackground;
          trailingIcon = null;
        }

        return GestureDetector(
          onTap: locked ? null : () => _selectAnswer(option, question, state.currentIndex),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: Spacing.paddingLG,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.borderMD,
              border: Border.all(
                color: borderColor,
                width: isSelected || (locked && isCorrectOption) ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (locked
                            ? (isCorrectOption ? Colors.green : Colors.red)
                            : AppColors.error)
                        : context.containerColor,
                    border: Border.all(
                      color: isSelected
                          ? (locked
                              ? (isCorrectOption ? Colors.green : Colors.red)
                              : AppColors.error)
                          : context.dividerColor,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                Spacing.hGapMD,
                Expanded(
                  child: Text(
                    option,
                    style: context.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? (locked
                              ? (isCorrectOption ? Colors.green : Colors.red)
                              : AppColors.error)
                          : context.textPrimary,
                    ),
                  ),
                ),
                if (trailingIcon != null) trailingIcon,
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillBlank(AIQuizState state, String? currentAnswer) {
    if (currentAnswer != null && _fillBlankController.text != currentAnswer) {
      _fillBlankController.text = currentAnswer;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your answer:',
          style: context.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        Spacing.gapSM,
        TextField(
          controller: _fillBlankController,
          onChanged: (value) {
            ref.read(aiQuizProvider.notifier).answerQuestion(state.currentIndex, value);
          },
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.aiQuizAnswerHint,
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.cardBackground,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderMD,
              borderSide: BorderSide(color: context.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMD,
              borderSide: BorderSide(color: context.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMD,
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalse(AIQuizState state, AIQuizQuestion question, String? currentAnswer) {
    return Row(
      children: [
        Expanded(child: _buildTrueFalseOption('True', currentAnswer == 'True', state.currentIndex, question)),
        const SizedBox(width: 12),
        Expanded(child: _buildTrueFalseOption('False', currentAnswer == 'False', state.currentIndex, question)),
      ],
    );
  }

  Widget _buildTrueFalseOption(String value, bool isSelected, int index, AIQuizQuestion question) {
    final locked = _locked[index] == true;
    final isCorrectOption = question.correctAnswer != null &&
        value.trim().toLowerCase() == question.correctAnswer!.trim().toLowerCase();

    Color borderColor;
    Color bgColor;
    Color textColor;

    if (locked) {
      if (isSelected && isCorrectOption) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
      } else if (isSelected && !isCorrectOption) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
      } else if (!isSelected && isCorrectOption) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.08);
        textColor = Colors.green;
      } else {
        borderColor = context.dividerColor;
        bgColor = context.cardBackground;
        textColor = context.textSecondary;
      }
    } else {
      if (isSelected) {
        borderColor = value == 'True' ? AppColors.success : AppColors.error;
        bgColor = (value == 'True' ? AppColors.success : AppColors.error).withOpacity(0.1);
        textColor = value == 'True' ? AppColors.success : AppColors.error;
      } else {
        borderColor = context.dividerColor;
        bgColor = context.cardBackground;
        textColor = context.textSecondary;
      }
    }

    return GestureDetector(
      onTap: locked ? null : () => _selectAnswer(value, question, index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Text(
            value,
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranslation(AIQuizState state, String? currentAnswer) {
    if (currentAnswer != null && _fillBlankController.text != currentAnswer) {
      _fillBlankController.text = currentAnswer;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your translation:',
          style: context.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        Spacing.gapSM,
        TextField(
          controller: _fillBlankController,
          maxLines: 3,
          onChanged: (value) {
            ref.read(aiQuizProvider.notifier).answerQuestion(state.currentIndex, value);
          },
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.aiQuizTranslationHint,
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.cardBackground,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderMD,
              borderSide: BorderSide(color: context.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMD,
              borderSide: BorderSide(color: context.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMD,
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(AIQuizState state, AIQuiz quiz) {
    final isLastQuestion = state.currentIndex == quiz.questions.length - 1;
    final currentLocked = _locked[state.currentIndex] == true;
    final hasAnswer = state.answers.containsKey(state.currentIndex);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: AppShadows.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLastQuestion
              ? (state.canSubmit ? _submitQuiz : null)
              : (currentLocked || hasAnswer ? _nextQuestion : null),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.gray300,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
          ),
          child: Text(
            isLastQuestion ? 'Submit' : 'Next',
            style: context.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'translation':
        return 'Translation';
      case 'true_false':
        return 'True or False';
      default:
        return type;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
