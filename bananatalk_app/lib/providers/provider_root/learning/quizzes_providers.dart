import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/quiz_model.dart';

// ==================== QUIZ PROVIDERS ====================

/// Quizzes list provider
final quizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  try {
    final result = await LearningService.getQuizzes();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => Quiz.fromJson(e)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Single quiz detail provider
final quizDetailProvider =
    FutureProvider.family<Quiz?, String>((ref, quizId) async {
  try {
    final result = await LearningService.getQuiz(quizId);
    if (result['success'] == true && result['data'] != null) {
      return Quiz.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Quiz player state
class QuizPlayerState {
  final Quiz? quiz;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<int, QuizAnswer> answers;
  final bool isComplete;
  final int correctCount;
  final int? xpEarned;
  final String? levelAssigned;
  final int timeRemaining;
  final DateTime? startTime;

  const QuizPlayerState({
    this.quiz,
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.isComplete = false,
    this.correctCount = 0,
    this.xpEarned,
    this.levelAssigned,
    this.timeRemaining = 0,
    this.startTime,
  });

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  int get totalQuestions => questions.length;
  double get progress =>
      totalQuestions > 0 ? currentIndex / totalQuestions : 0;

  QuizPlayerState copyWith({
    Quiz? quiz,
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<int, QuizAnswer>? answers,
    bool? isComplete,
    int? correctCount,
    int? xpEarned,
    String? levelAssigned,
    int? timeRemaining,
    DateTime? startTime,
  }) {
    return QuizPlayerState(
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
      correctCount: correctCount ?? this.correctCount,
      xpEarned: xpEarned ?? this.xpEarned,
      levelAssigned: levelAssigned ?? this.levelAssigned,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      startTime: startTime ?? this.startTime,
    );
  }
}

/// Quiz player notifier
class QuizPlayerNotifier extends StateNotifier<QuizPlayerState> {
  QuizPlayerNotifier() : super(const QuizPlayerState());

  void startQuiz(Quiz quiz) {
    state = QuizPlayerState(
      quiz: quiz,
      questions: quiz.questions,
      timeRemaining: quiz.timeLimit * 60,
      startTime: DateTime.now(),
    );
  }

  void selectAnswer(QuizAnswer answer) {
    final newAnswers = Map<int, QuizAnswer>.from(state.answers);
    newAnswers[state.currentIndex] = answer;

    state = state.copyWith(answers: newAnswers);
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> submitQuiz() async {
    if (state.quiz == null || state.startTime == null) {
      _calculateResults();
      return;
    }

    final timeSpent = DateTime.now().difference(state.startTime!).inSeconds;
    final answersList = state.answers.values.toList();

    final result = await LearningService.submitQuiz(
      quizId: state.quiz!.id,
      answers: answersList,
      timeSpent: timeSpent,
    );

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      state = state.copyWith(
        isComplete: true,
        correctCount: data['correctCount'] ?? _calculateCorrectCount(),
        xpEarned: data['xpEarned'] ?? 0,
        levelAssigned: data['levelAssigned'],
      );
    } else {
      _calculateResults();
    }
  }

  void _calculateResults() {
    state = state.copyWith(
      isComplete: true,
      correctCount: _calculateCorrectCount(),
    );
  }

  int _calculateCorrectCount() {
    int correct = 0;
    for (var entry in state.answers.entries) {
      final questionIndex = entry.key;
      final answer = entry.value;
      if (questionIndex < state.questions.length) {
        final question = state.questions[questionIndex];
        if (question.correctAnswer == answer.selectedOption) {
          correct++;
        }
      }
    }
    return correct;
  }

  void reset() {
    state = const QuizPlayerState();
  }
}

/// Quiz player provider
final quizPlayerProvider =
    StateNotifierProvider<QuizPlayerNotifier, QuizPlayerState>((ref) {
  return QuizPlayerNotifier();
});
