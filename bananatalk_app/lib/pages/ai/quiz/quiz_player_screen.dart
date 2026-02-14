import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Quiz Player Screen - Interactive quiz taking experience
class QuizPlayerScreen extends ConsumerStatefulWidget {
  const QuizPlayerScreen({super.key});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  final TextEditingController _fillBlankController = TextEditingController();

  @override
  void dispose() {
    _fillBlankController.dispose();
    super.dispose();
  }

  void _selectAnswer(String answer) {
    final state = ref.read(aiQuizProvider);
    ref.read(aiQuizProvider.notifier).answerQuestion(state.currentIndex, answer);
  }

  void _nextQuestion() {
    ref.read(aiQuizProvider.notifier).nextQuestion();
  }

  void _previousQuestion() {
    ref.read(aiQuizProvider.notifier).previousQuestion();
  }

  Future<void> _submitQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: const Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Submit'),
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
    if (result == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
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
                        fontSize: 36,
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
            const SizedBox(height: 20),
            Text(
              result.percentage >= 80
                  ? 'Great job!'
                  : result.percentage >= 60
                      ? 'Good effort!'
                      : 'Keep practicing!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.correctCount} out of ${result.totalQuestions} correct',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResultItem(
                  Icons.star_rounded,
                  '+${result.xpEarned}',
                  'XP',
                  Colors.amber,
                ),
                _buildResultItem(
                  Icons.timer_rounded,
                  '${(result.timeSpent / 60).floor()}m',
                  'Time',
                  Colors.blue,
                ),
              ],
            ),
            if (result.feedback.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  result.feedback,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
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
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
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
          title: const Text('Quiz'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle empty questions case
    if (quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
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
              Icon(
                Icons.quiz_rounded,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No questions available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This quiz has no questions to display.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(aiQuizProvider.notifier).reset();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Go Back'),
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
            title: const Text('Exit Quiz?'),
            content: const Text('Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Exit'),
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
                  title: const Text('Exit Quiz?'),
                  content: const Text('Your progress will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Exit'),
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
            // Progress Bar
            LinearProgressIndicator(
              value: quiz.questions.isNotEmpty
                  ? (state.currentIndex + 1) / quiz.questions.length
                  : 0.0,
              backgroundColor: context.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
            ),

            // Question Content
            Expanded(
              child: question != null
                  ? SingleChildScrollView(
                      padding: Spacing.paddingXL,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
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
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                Spacing.hGapSM,
                                Expanded(
                                  child: Text(
                                    question.hint!,
                                    style: context.bodySmall?.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Spacing.gapXL,

                          // Answer Options
                          _buildAnswerSection(state, question),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Navigation Buttons
            _buildNavigationBar(state, quiz),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSection(AIQuizState state, AIQuizQuestion question) {
    final currentAnswer = state.answers[state.currentIndex];

    switch (question.type) {
      case 'multiple_choice':
        return _buildMultipleChoice(question, currentAnswer);
      case 'fill_blank':
        return _buildFillBlank(state, currentAnswer);
      case 'true_false':
        return _buildTrueFalse(currentAnswer);
      case 'translation':
        return _buildTranslation(state, currentAnswer);
      default:
        return _buildMultipleChoice(question, currentAnswer);
    }
  }

  Widget _buildMultipleChoice(AIQuizQuestion question, String? currentAnswer) {
    if (question.options == null) return const SizedBox.shrink();

    return Column(
      children: question.options!.map((option) {
        final isSelected = currentAnswer == option;
        return GestureDetector(
          onTap: () => _selectAnswer(option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: Spacing.paddingLG,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.error.withOpacity(0.1)
                  : context.cardBackground,
              borderRadius: AppRadius.borderMD,
              border: Border.all(
                color: isSelected
                    ? AppColors.error
                    : context.dividerColor,
                width: isSelected ? 2 : 1,
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
                        ? AppColors.error
                        : context.containerColor,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.error
                          : context.dividerColor,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                Spacing.hGapMD,
                Expanded(
                  child: Text(
                    option,
                    style: context.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.error
                          : context.textPrimary,
                    ),
                  ),
                ),
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
            ref.read(aiQuizProvider.notifier).answerQuestion(
              state.currentIndex,
              value,
            );
          },
          decoration: InputDecoration(
            hintText: 'Type your answer...',
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

  Widget _buildTrueFalse(String? currentAnswer) {
    return Row(
      children: [
        Expanded(
          child: _buildTrueFalseOption('True', currentAnswer == 'True'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTrueFalseOption('False', currentAnswer == 'False'),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOption(String value, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? (value == 'True' ? AppColors.success : AppColors.error).withOpacity(0.1)
              : context.cardBackground,
          borderRadius: AppRadius.borderMD,
          border: Border.all(
            color: isSelected
                ? (value == 'True' ? AppColors.success : AppColors.error)
                : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            value,
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (value == 'True' ? AppColors.success : AppColors.error)
                  : context.textSecondary,
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
            ref.read(aiQuizProvider.notifier).answerQuestion(
              state.currentIndex,
              value,
            );
          },
          decoration: InputDecoration(
            hintText: 'Type your translation...',
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
    final isFirstQuestion = state.currentIndex == 0;
    final isLastQuestion = state.currentIndex == quiz.questions.length - 1;

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
      child: Row(
        children: [
          // Previous Button
          if (!isFirstQuestion)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textSecondary,
                  side: BorderSide(color: context.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                ),
                child: const Text('Previous'),
              ),
            )
          else
            const Spacer(),
          Spacing.hGapMD,

          // Next/Submit Button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLastQuestion
                  ? (state.canSubmit ? _submitQuiz : null)
                  : _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
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
        ],
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
