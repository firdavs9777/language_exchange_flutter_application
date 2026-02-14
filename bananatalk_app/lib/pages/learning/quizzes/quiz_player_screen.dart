import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/quiz_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Quiz player screen
class QuizPlayerScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizPlayerScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuiz();
    });
  }

  void _startQuiz() async {
    final quizAsync = ref.read(quizDetailProvider(widget.quizId));
    quizAsync.whenData((quiz) {
      if (quiz != null) {
        ref.read(quizPlayerProvider.notifier).startQuiz(quiz);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizDetailProvider(widget.quizId));
    final playerState = ref.watch(quizPlayerProvider);

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          ref.read(quizPlayerProvider.notifier).reset();
        }
        return shouldExit;
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: context.surfaceColor,
          leading: IconButton(
            icon: Icon(Icons.close, color: context.textPrimary),
            onPressed: () async {
              final shouldExit = await _showExitDialog();
              if (shouldExit && mounted) {
                ref.read(quizPlayerProvider.notifier).reset();
                Navigator.pop(context);
              }
            },
          ),
          title: quizAsync.when(
            data: (quiz) => Text(
              quiz?.title ?? 'Quiz',
              style: context.titleMedium,
            ),
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Error'),
          ),
          actions: [
            if (playerState.questions.isNotEmpty && !playerState.isComplete)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${playerState.timeRemaining ~/ 60}:${(playerState.timeRemaining % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: quizAsync.when(
          data: (quiz) {
            if (quiz == null) {
              return const Center(child: Text('Quiz not found'));
            }

            if (playerState.isComplete) {
              return _buildResults(playerState, quiz);
            }

            if (playerState.questions.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
              );
            }

            return _buildQuestion(playerState);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: context.textMuted),
                Spacing.gapLG,
                Text('Failed to load quiz',
                    style: context.bodyMedium.copyWith(color: context.textSecondary)),
                Spacing.gapLG,
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(quizDetailProvider(widget.quizId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(QuizPlayerState state) {
    final question = state.currentQuestion!;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: state.currentIndex / state.questions.length,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          minHeight: 4,
        ),
        // Question counter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'Question ${state.currentIndex + 1} of ${state.questions.length}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Options
                ...(question.options ?? []).asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected =
                      state.answers[state.currentIndex]?.selectedOption ==
                          option;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        ref.read(quizPlayerProvider.notifier).selectAnswer(
                              QuizAnswer(
                                questionId: question.id,
                                selectedOption: option,
                              ),
                            );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00BFA5).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00BFA5)
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFF00BFA5)
                                    : Colors.grey[100],
                              ),
                              child: Center(
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        String.fromCharCode(65 + index),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected
                                      ? const Color(0xFF00BFA5)
                                      : Colors.black87,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              if (state.currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(quizPlayerProvider.notifier).previousQuestion();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (state.currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.answers[state.currentIndex] != null
                      ? () {
                          if (state.currentIndex < state.questions.length - 1) {
                            ref
                                .read(quizPlayerProvider.notifier)
                                .nextQuestion();
                          } else {
                            ref.read(quizPlayerProvider.notifier).submitQuiz();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    state.currentIndex < state.questions.length - 1
                        ? 'Next'
                        : 'Submit',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults(QuizPlayerState state, Quiz quiz) {
    final total = state.questions.length;
    final correct = state.correctCount;
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _getResultColor(accuracy).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: accuracy / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getResultColor(accuracy),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$accuracy%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getResultColor(accuracy),
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getResultMessage(accuracy),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultStat(
                    'Correct',
                    '$correct',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[200],
                  ),
                  _buildResultStat(
                    'Wrong',
                    '${total - correct}',
                    Colors.red,
                    Icons.cancel,
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[200],
                  ),
                  _buildResultStat(
                    'XP',
                    '+${state.xpEarned ?? 0}',
                    const Color(0xFF00BFA5),
                    Icons.star_rounded,
                  ),
                ],
              ),
            ),
            // Level result for placement quiz
            if (quiz.type == 'placement' && state.levelAssigned != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Level',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                          Text(
                            state.levelAssigned!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(quizPlayerProvider.notifier).reset();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
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

  Color _getResultColor(int accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getResultMessage(int accuracy) {
    if (accuracy >= 90) return 'Excellent!';
    if (accuracy >= 80) return 'Great Job!';
    if (accuracy >= 60) return 'Good Effort!';
    if (accuracy >= 40) return 'Keep Practicing!';
    return 'Keep Learning!';
  }

  Future<bool> _showExitDialog() async {
    final state = ref.read(quizPlayerProvider);
    if (state.questions.isEmpty || state.isComplete) {
      return true;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text(
              'Your progress will be lost if you exit now.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
