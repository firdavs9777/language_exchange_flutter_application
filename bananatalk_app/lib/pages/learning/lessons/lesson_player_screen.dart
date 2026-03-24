import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/pages/learning/lessons/exercises/multiple_choice_widget.dart';
import 'package:bananatalk_app/pages/learning/lessons/exercises/fill_blank_widget.dart';
import 'package:bananatalk_app/pages/learning/lessons/exercises/translation_widget.dart';
import 'package:bananatalk_app/pages/learning/lessons/exercises/matching_widget.dart';
import 'package:bananatalk_app/pages/learning/lessons/exercises/ordering_widget.dart';
import 'package:bananatalk_app/widgets/ai/lesson_assistant_widget.dart';
import 'package:bananatalk_app/widgets/ai/answer_feedback_sheet.dart';
import 'package:bananatalk_app/widgets/ai/lesson_summary_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Lesson player screen
class LessonPlayerScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final Lesson? initialLesson; // Optional: pass lesson data directly to avoid re-fetching

  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
    this.initialLesson,
  });

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  int _previousIncorrectCount = 0;
  bool _summaryShown = false;
  bool _lessonStarted = false;

  @override
  void initState() {
    super.initState();
    _previousIncorrectCount = 0;
    _summaryShown = false;
    _lessonStarted = false;

    // If lesson data was passed directly, use it immediately
    if (widget.initialLesson != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(lessonPlayerProvider.notifier).startLesson(widget.initialLesson!);
        _lessonStarted = true;
      });
    }
  }

  void _tryStartLesson(Lesson lesson) {
    if (_lessonStarted) return;
    _lessonStarted = true;

    // Log details of each exercise
    for (int i = 0; i < lesson.exercises.length; i++) {
      final ex = lesson.exercises[i];
      final questionPreview = ex.question.length > 50
          ? '${ex.question.substring(0, 50)}...'
          : ex.question;

      if (ex.type.toLowerCase() == 'matching') {
        for (int j = 0; j < ex.matchingPairs.length; j++) {
        }
      }
      if (ex.type.toLowerCase() == 'ordering') {
      }
    }

    ref.read(lessonPlayerProvider.notifier).startLesson(lesson);
  }

  void _resetAndRetry() {
    setState(() {
      _lessonStarted = false;
      _previousIncorrectCount = 0;
      _summaryShown = false;
    });
    ref.read(lessonPlayerProvider.notifier).reset();
    ref.invalidate(lessonDetailProvider(widget.lessonId));
  }

  /// Check if user answered incorrectly and show AI feedback
  void _checkForWrongAnswer(LessonPlayerState state) {
    if (state.showingResult && state.incorrectCount > _previousIncorrectCount) {
      _previousIncorrectCount = state.incorrectCount;
      // User just answered incorrectly - show AI feedback
      final exercise = state.currentExercise;
      if (exercise != null && state.currentAnswer != null) {
        _showAIFeedback(state.currentIndex, state.currentAnswer!, exercise);
      }
    }
  }

  /// Show AI feedback sheet for wrong answer
  void _showAIFeedback(int exerciseIndex, String userAnswerId, Exercise exercise) {

    // Convert user answer ID to text
    String userAnswerText = userAnswerId;
    if (exercise.options.isNotEmpty) {
      final selectedOption = exercise.options.firstWhere(
        (o) => o.id == userAnswerId || o.text == userAnswerId,
        orElse: () => ExerciseOption(id: '', text: userAnswerId, isCorrect: false),
      );
      userAnswerText = selectedOption.text.isNotEmpty ? selectedOption.text : userAnswerId;
    }

    // Determine correct answer - always prefer finding the correct option
    String correctAnswer = '';
    if (exercise.options.isNotEmpty) {
      // Find the option marked as correct
      final correctOption = exercise.options.firstWhere(
        (o) => o.isCorrect,
        orElse: () => ExerciseOption(id: '', text: '', isCorrect: false),
      );
      if (correctOption.text.isNotEmpty) {
        correctAnswer = correctOption.text;
      }
    }

    // Fallback to exercise.correctAnswer if no correct option found
    if (correctAnswer.isEmpty && exercise.correctAnswer != null) {
      // Check if correctAnswer is an ID that matches an option
      if (exercise.options.isNotEmpty) {
        final matchingOption = exercise.options.firstWhere(
          (o) => o.id == exercise.correctAnswer || o.text == exercise.correctAnswer,
          orElse: () => ExerciseOption(id: '', text: '', isCorrect: false),
        );
        if (matchingOption.text.isNotEmpty) {
          correctAnswer = matchingOption.text;
        } else {
          correctAnswer = exercise.correctAnswer!;
        }
      } else {
        correctAnswer = exercise.correctAnswer!;
      }
    }

    // Last fallback - use acceptedAnswers if available
    if (correctAnswer.isEmpty && exercise.acceptedAnswers != null && exercise.acceptedAnswers!.isNotEmpty) {
      correctAnswer = exercise.acceptedAnswers!.first;
    }


    AnswerFeedbackSheet.show(
      context,
      lessonId: widget.lessonId,
      exerciseIndex: exerciseIndex,
      userAnswer: userAnswerText,
      correctAnswer: correctAnswer,
    );
  }

  /// Show AI summary sheet when lesson is complete
  void _showAISummary(int userScore) {
    if (_summaryShown) return;
    _summaryShown = true;

    // Small delay to let the results screen appear first
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        LessonSummarySheet.show(
          context,
          lessonId: widget.lessonId,
          userScore: userScore,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final playerState = ref.watch(lessonPlayerProvider);

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          ref.read(lessonPlayerProvider.notifier).reset();
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
                ref.read(lessonPlayerProvider.notifier).reset();
                Navigator.pop(context);
              }
            },
          ),
          title: lessonAsync.when(
            data: (lesson) => Text(
              lesson?.title ?? 'Lesson',
              style: context.titleMedium,
            ),
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Error'),
          ),
          actions: [
            if (playerState.exercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${playerState.currentIndex + 1}/${playerState.exercises.length}',
                    style: context.labelLarge.copyWith(color: context.textSecondary),
                  ),
                ),
              ),
          ],
        ),
        // AI Lesson Assistant FAB
        floatingActionButton: playerState.exercises.isNotEmpty && !playerState.isComplete
            ? LessonAssistantWidget(
                lessonId: widget.lessonId,
                currentExerciseIndex: playerState.currentIndex,
                exerciseQuestion: playerState.currentExercise?.question,
              )
            : null,
        body: lessonAsync.when(
          data: (lesson) {
            if (lesson == null) {
              return _buildLessonNotFound();
            }

            // Start the lesson if not already started
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _tryStartLesson(lesson);
              _checkForWrongAnswer(playerState);
            });

            if (playerState.isComplete) {
              // Show AI summary when lesson completes
              final total = playerState.exercises.length;
              final correct = playerState.correctCount;
              final accuracy = total > 0 ? (correct / total * 100).round() : 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAISummary(accuracy);
              });
              return _buildResults(playerState, lesson);
            }

            if (playerState.exercises.isEmpty) {
              // Check if lesson has no exercises
              if (lesson.exercises.isEmpty) {
                return _buildNoExercises(lesson);
              }
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return _buildExercise(playerState);
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
                Text('Failed to load lesson',
                    style: context.bodyMedium.copyWith(color: context.textSecondary)),
                Spacing.gapSM,
                Text('$error',
                    style: context.caption),
                Spacing.gapLG,
                ElevatedButton(
                  onPressed: _resetAndRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExercise(LessonPlayerState state) {
    final exercise = state.currentExercise!;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: state.currentIndex / state.exercises.length,
          backgroundColor: context.containerColor,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildExerciseWidget(exercise, state),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseWidget(Exercise exercise, LessonPlayerState state) {
    switch (exercise.type.toLowerCase()) {
      case 'multiple_choice':
        return MultipleChoiceWidget(
          key: ValueKey('multiple_choice_${state.currentIndex}'),
          exercise: exercise,
          selectedAnswer: state.currentAnswer,
          showResult: state.showingResult,
          onAnswer: (answer) {
            ref.read(lessonPlayerProvider.notifier).submitAnswer(answer);
          },
          onNext: () {
            ref.read(lessonPlayerProvider.notifier).nextExercise();
          },
        );
      case 'fill_blank':
        return FillBlankWidget(
          key: ValueKey('fill_blank_${state.currentIndex}'),
          exercise: exercise,
          currentAnswer: state.currentAnswer,
          showResult: state.showingResult,
          onAnswer: (answer) {
            ref.read(lessonPlayerProvider.notifier).submitAnswer(answer);
          },
          onNext: () {
            ref.read(lessonPlayerProvider.notifier).nextExercise();
          },
        );
      case 'translation':
        return TranslationWidget(
          key: ValueKey('translation_${state.currentIndex}'),
          exercise: exercise,
          currentAnswer: state.currentAnswer,
          showResult: state.showingResult,
          onAnswer: (answer) {
            ref.read(lessonPlayerProvider.notifier).submitAnswer(answer);
          },
          onNext: () {
            ref.read(lessonPlayerProvider.notifier).nextExercise();
          },
        );
      case 'matching':
        return MatchingWidget(
          key: ValueKey('matching_${state.currentIndex}'), // Force rebuild for each exercise
          exercise: exercise,
          showResult: state.showingResult,
          onAnswer: (answer) {
            ref.read(lessonPlayerProvider.notifier).submitAnswer(answer);
          },
          onNext: () {
            ref.read(lessonPlayerProvider.notifier).nextExercise();
          },
        );
      case 'ordering':
        return OrderingWidget(
          key: ValueKey('ordering_${state.currentIndex}'), // Force rebuild for each exercise
          exercise: exercise,
          showResult: state.showingResult,
          onAnswer: (answer) {
            ref.read(lessonPlayerProvider.notifier).submitAnswer(answer);
          },
          onNext: () {
            ref.read(lessonPlayerProvider.notifier).nextExercise();
          },
        );
      default:
        return Center(
          child: Text('Unknown exercise type: ${exercise.type}'),
        );
    }
  }

  Widget _buildResults(LessonPlayerState state, Lesson lesson) {
    final total = state.exercises.length;
    final correct = state.correctCount;
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;

    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: Spacing.paddingXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getResultColor(accuracy).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$accuracy%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _getResultColor(accuracy),
                    ),
                  ),
                ),
              ),
              Spacing.gapXL,
              Text(
                _getResultMessage(accuracy),
                style: context.displaySmall,
              ),
              Spacing.gapSM,
              Text(
                lesson.title,
                style: context.bodyMedium.copyWith(color: context.textSecondary),
              ),
              Spacing.gapXL,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResultStat('Correct', '$correct', AppColors.success),
                  Spacing.hGapLG,
                  _buildResultStat(
                      'Incorrect', '${total - correct}', AppColors.error),
                  Spacing.hGapLG,
                  _buildResultStat(
                    'XP',
                    '+${state.xpEarned ?? 0}',
                    AppColors.primary,
                  ),
                ],
              ),
              Spacing.gapXL,
            // View AI Summary button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  LessonSummarySheet.show(
                    context,
                    lessonId: widget.lessonId,
                    userScore: accuracy,
                  );
                },
                icon: const Icon(Icons.smart_toy, size: 20),
                label: const Text('View AI Summary'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.info),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderLG,
                  ),
                ),
              ),
            ),
            Spacing.gapLG,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _lessonStarted = false;
                        _previousIncorrectCount = 0;
                        _summaryShown = false;
                      });
                      ref.read(lessonPlayerProvider.notifier).reset();
                      // Lesson will restart automatically via _tryStartLesson in build
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderLG,
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Spacing.hGapLG,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(lessonPlayerProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderLG,
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Builder(
      builder: (context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
        ],
      ),
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
    return 'Try Again!';
  }

  Future<bool> _showExitDialog() async {
    final state = ref.read(lessonPlayerProvider);
    if (state.exercises.isEmpty || state.isComplete) {
      return true;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Lesson?'),
            content: const Text(
              'Your progress will not be saved if you exit now.',
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

  Widget _buildLessonNotFound() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: context.textMuted),
            Spacing.gapLG,
            Text(
              'Lesson not found',
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              'This lesson may have been removed',
              style: context.bodySmall,
            ),
            Spacing.gapXL,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
                Spacing.hGapLG,
                ElevatedButton(
                  onPressed: _resetAndRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoExercises(Lesson lesson) {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: Spacing.paddingXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: context.textMuted),
              Spacing.gapLG,
              Text(
                lesson.title,
                style: context.titleLarge,
                textAlign: TextAlign.center,
              ),
              Spacing.gapSM,
              Text(
                'This lesson has no exercises yet',
                style: context.bodyMedium.copyWith(color: context.textSecondary),
              ),
              if (lesson.introduction != null) ...[
                Spacing.gapXL,
                Container(
                  padding: Spacing.paddingLG,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Text(
                    lesson.introduction!,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
              Spacing.gapXL,
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
