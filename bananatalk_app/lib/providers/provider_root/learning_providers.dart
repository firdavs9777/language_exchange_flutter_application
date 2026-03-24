import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/models/learning/quiz_model.dart';
import 'package:bananatalk_app/models/learning/achievement_model.dart';
import 'package:bananatalk_app/models/learning/challenge_model.dart';
import 'package:bananatalk_app/models/learning/leaderboard_model.dart';

// ==================== PROGRESS PROVIDERS ====================

/// Learning progress provider
final learningProgressProvider = FutureProvider<LearningProgress?>((ref) async {
  try {
    final result = await LearningService.getProgress();
    if (result['success'] == true && result['data'] != null) {
      return LearningProgress.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Daily goals provider
final dailyGoalsProvider = FutureProvider<DailyGoalsResponse?>((ref) async {
  try {
    final result = await LearningService.getDailyGoals();
    if (result['success'] == true && result['data'] != null) {
      return DailyGoalsResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

// ==================== VOCABULARY PROVIDERS ====================

/// Vocabulary filter state
class VocabularyFilter {
  final String? language;
  final String? srsLevel;
  final String? search;
  final int limit;
  final int offset;

  const VocabularyFilter({
    this.language,
    this.srsLevel,
    this.search,
    this.limit = 50,
    this.offset = 0,
  });

  /// Copy with explicit null support using named parameters
  /// Use clearSrsLevel: true to explicitly set srsLevel to null
  /// Use clearSearch: true to explicitly set search to null
  VocabularyFilter copyWith({
    String? language,
    String? srsLevel,
    String? search,
    int? limit,
    int? offset,
    bool clearSrsLevel = false,
    bool clearSearch = false,
    bool clearLanguage = false,
  }) {
    return VocabularyFilter(
      language: clearLanguage ? null : (language ?? this.language),
      srsLevel: clearSrsLevel ? null : (srsLevel ?? this.srsLevel),
      search: clearSearch ? null : (search ?? this.search),
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VocabularyFilter &&
        other.language == language &&
        other.srsLevel == srsLevel &&
        other.search == search &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(language, srsLevel, search, limit, offset);
}

/// Vocabulary filter state provider
final vocabularyFilterProvider = StateProvider<VocabularyFilter>((ref) {
  return const VocabularyFilter();
});

/// Vocabulary list provider
final vocabularyListProvider =
    FutureProvider.family<List<VocabularyItem>, VocabularyFilter>(
        (ref, filter) async {
  try {
    final result = await LearningService.getVocabulary(
      language: filter.language,
      srsLevel: filter.srsLevel,
      search: filter.search,
      limit: filter.limit,
      offset: filter.offset,
    );
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => VocabularyItem.fromJson(e)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Filtered vocabulary list (uses current filter state)
final filteredVocabularyProvider =
    FutureProvider<List<VocabularyItem>>((ref) async {
  final filter = ref.watch(vocabularyFilterProvider);
  final result = await ref.watch(vocabularyListProvider(filter).future);
  return result;
});

/// Due reviews provider
final dueReviewsProvider =
    FutureProvider.family<DueWordsResponse?, String?>((ref, language) async {
  try {
    final result = await LearningService.getDueReviews(language: language);
    if (result['success'] == true && result['data'] != null) {
      return DueWordsResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Vocabulary stats provider
final vocabularyStatsProvider =
    FutureProvider.family<VocabularyStats?, String?>((ref, language) async {
  try {
    final result = await LearningService.getVocabularyStats(language: language);
    if (result['success'] == true && result['data'] != null) {
      return VocabularyStats.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Vocabulary review session state
class VocabularyReviewState {
  final List<VocabularyItem> cards;
  final int currentIndex;
  final bool isFlipped;
  final int correctCount;
  final int incorrectCount;
  final bool isComplete;
  final int? xpEarned;

  const VocabularyReviewState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.isComplete = false,
    this.xpEarned,
  });

  VocabularyItem? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  int get totalCards => cards.length;
  int get remaining => cards.length - currentIndex;

  VocabularyReviewState copyWith({
    List<VocabularyItem>? cards,
    int? currentIndex,
    bool? isFlipped,
    int? correctCount,
    int? incorrectCount,
    bool? isComplete,
    int? xpEarned,
  }) {
    return VocabularyReviewState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      isComplete: isComplete ?? this.isComplete,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }
}

/// Vocabulary review session notifier
class VocabularyReviewNotifier extends StateNotifier<VocabularyReviewState> {
  VocabularyReviewNotifier() : super(const VocabularyReviewState());

  void startSession(List<VocabularyItem> cards) {
    state = VocabularyReviewState(cards: cards);
  }

  void flipCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<void> submitAnswer(bool correct) async {
    if (state.currentCard == null) return;

    // Submit to backend
    final result = await LearningService.submitReview(
      vocabularyId: state.currentCard!.id,
      correct: correct,
    );

    final xpEarned = result['success'] == true
        ? (result['data']?['xpEarned'] ?? 0) as int
        : 0;

    // Update state
    final newCorrect = correct ? state.correctCount + 1 : state.correctCount;
    final newIncorrect =
        correct ? state.incorrectCount : state.incorrectCount + 1;
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.cards.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      isFlipped: false,
      correctCount: newCorrect,
      incorrectCount: newIncorrect,
      isComplete: isComplete,
      xpEarned: (state.xpEarned ?? 0) + xpEarned,
    );
  }

  void reset() {
    state = const VocabularyReviewState();
  }
}

/// Vocabulary review provider
final vocabularyReviewProvider =
    StateNotifierProvider<VocabularyReviewNotifier, VocabularyReviewState>(
        (ref) {
  return VocabularyReviewNotifier();
});

// ==================== LESSON PROVIDERS ====================

/// Lesson filter
class LessonFilter {
  final String? language;
  final String? level;
  final String? category;
  final int? unit;

  const LessonFilter({
    this.language,
    this.level,
    this.category,
    this.unit,
  });

  LessonFilter copyWith({
    String? language,
    String? level,
    String? category,
    int? unit,
  }) {
    return LessonFilter(
      language: language ?? this.language,
      level: level ?? this.level,
      category: category ?? this.category,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonFilter &&
        other.language == language &&
        other.level == level &&
        other.category == category &&
        other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(language, level, category, unit);
}

/// Lesson filter state provider
final lessonFilterProvider = StateProvider<LessonFilter>((ref) {
  return const LessonFilter();
});

/// Lessons list provider
final lessonsProvider =
    FutureProvider.family<List<Lesson>, LessonFilter>((ref, filter) async {
  try {
    final result = await LearningService.getLessons(
      language: filter.language,
      level: filter.level,
      category: filter.category,
      unit: filter.unit,
    );
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => Lesson.fromJson(e)).toList();
      } else if (data is Map && data['lessons'] != null) {
        return (data['lessons'] as List).map((e) => Lesson.fromJson(e)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Recommended lessons provider
final recommendedLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  try {
    final result = await LearningService.getRecommendedLessons();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => Lesson.fromJson(e)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Single lesson detail provider
final lessonDetailProvider =
    FutureProvider.family<Lesson?, String>((ref, lessonId) async {
  try {
    final result = await LearningService.getLesson(lessonId);
    if (result['success'] == true && result['data'] != null) {
      return Lesson.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Lesson player state
class LessonPlayerState {
  final Lesson? lesson;
  final List<Exercise> exercises;
  final int currentIndex;
  final String? currentAnswer;
  final bool showingResult;
  final int correctCount;
  final int incorrectCount;
  final bool isComplete;
  final int? xpEarned;
  final DateTime? startTime;
  final Map<int, LessonAnswer> collectedAnswers; // Store answers by exercise index

  const LessonPlayerState({
    this.lesson,
    this.exercises = const [],
    this.currentIndex = 0,
    this.currentAnswer,
    this.showingResult = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.isComplete = false,
    this.xpEarned,
    this.startTime,
    this.collectedAnswers = const {},
  });

  Exercise? get currentExercise =>
      exercises.isNotEmpty && currentIndex < exercises.length
          ? exercises[currentIndex]
          : null;

  int get totalExercises => exercises.length;
  double get progress =>
      totalExercises > 0 ? currentIndex / totalExercises : 0;

  LessonPlayerState copyWith({
    Lesson? lesson,
    List<Exercise>? exercises,
    int? currentIndex,
    String? currentAnswer,
    bool? showingResult,
    int? correctCount,
    int? incorrectCount,
    bool? isComplete,
    int? xpEarned,
    DateTime? startTime,
    Map<int, LessonAnswer>? collectedAnswers,
  }) {
    return LessonPlayerState(
      lesson: lesson ?? this.lesson,
      exercises: exercises ?? this.exercises,
      currentIndex: currentIndex ?? this.currentIndex,
      currentAnswer: currentAnswer,
      showingResult: showingResult ?? this.showingResult,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      isComplete: isComplete ?? this.isComplete,
      xpEarned: xpEarned ?? this.xpEarned,
      startTime: startTime ?? this.startTime,
      collectedAnswers: collectedAnswers ?? this.collectedAnswers,
    );
  }
}

/// Lesson player notifier
class LessonPlayerNotifier extends StateNotifier<LessonPlayerState> {
  LessonPlayerNotifier() : super(const LessonPlayerState());

  void startLesson(Lesson lesson) {
    state = LessonPlayerState(
      lesson: lesson,
      exercises: lesson.exercises,
      startTime: DateTime.now(),
    );
  }

  void submitAnswer(String answer) {
    if (state.currentExercise == null) return;

    final exercise = state.currentExercise!;
    final isCorrect = _checkAnswer(exercise, answer);

    // Store the answer for submission
    final newAnswers = Map<int, LessonAnswer>.from(state.collectedAnswers);
    newAnswers[state.currentIndex] = LessonAnswer(
      exerciseIndex: state.currentIndex,
      answer: answer,
      isCorrect: isCorrect,
    );


    state = state.copyWith(
      currentAnswer: answer,
      showingResult: true,
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      incorrectCount: isCorrect ? state.incorrectCount : state.incorrectCount + 1,
      collectedAnswers: newAnswers,
    );
  }

  bool _checkAnswer(Exercise exercise, String answer) {
    final exerciseType = exercise.type.toLowerCase();

    // Handle matching exercises specially
    if (exerciseType == 'matching') {
      return _checkMatchingAnswer(exercise, answer);
    }

    // Handle ordering exercises specially
    if (exerciseType == 'ordering') {
      return _checkOrderingAnswer(exercise, answer);
    }

    // For multiple choice, check if selected option is correct
    if (exercise.options.isNotEmpty) {
      final selectedOption = exercise.options.firstWhere(
        (o) => o.id == answer || o.text == answer,
        orElse: () => ExerciseOption(id: '', text: '', isCorrect: false),
      );
      if (selectedOption.id.isNotEmpty) {
        return selectedOption.isCorrect;
      }
    }

    // Fallback to comparing with correctAnswer
    if (exercise.correctAnswer != null) {
      return exercise.correctAnswer!.toLowerCase().trim() ==
          answer.toLowerCase().trim();
    }

    // Check acceptedAnswers
    if (exercise.acceptedAnswers != null && exercise.acceptedAnswers!.isNotEmpty) {
      return exercise.acceptedAnswers!.any(
        (accepted) => accepted.toLowerCase().trim() == answer.toLowerCase().trim(),
      );
    }

    return false;
  }

  bool _checkMatchingAnswer(Exercise exercise, String answer) {
    // Build correct matches map from matchingPairs
    final correctMatches = <String, String>{};
    for (var pair in exercise.matchingPairs) {
      correctMatches[pair.left.toLowerCase().trim()] = pair.right.toLowerCase().trim();
    }

    // If no matching pairs, try to build from options with matchWith
    if (correctMatches.isEmpty && exercise.options.isNotEmpty) {
      // The correctAnswer might contain the pairs info
      // For now, consider any complete matching as correct if we can't verify
      return true; // Give benefit of doubt if we can't verify
    }

    // Parse user's answer (format: "left1:right1|left2:right2")
    final userPairs = answer.split('|');
    int correctCount = 0;

    for (var pairStr in userPairs) {
      final parts = pairStr.split(':');
      if (parts.length == 2) {
        final left = parts[0].toLowerCase().trim();
        final right = parts[1].toLowerCase().trim();

        // Check if this pair is correct
        if (correctMatches[left] == right) {
          correctCount++;
        }
      }
    }

    // All pairs must be correct
    return correctCount == correctMatches.length && correctCount == userPairs.length;
  }

  bool _checkOrderingAnswer(Exercise exercise, String answer) {
    // User answer format: "item1|item2|item3"
    final userOrder = answer.split('|').map((s) => s.trim()).toList();

    // Get correct order from exercise
    List<String> correctOrder = [];

    // Try correctOrder field first
    if (exercise.correctOrder != null && exercise.correctOrder!.isNotEmpty) {
      correctOrder = exercise.correctOrder!.map((s) => s.trim()).toList();
    }
    // Try to parse correctAnswer if it looks like an array
    else if (exercise.correctAnswer != null) {
      final ca = exercise.correctAnswer!;
      // Check if it's a JSON array string like "[item1, item2, item3]"
      if (ca.startsWith('[') && ca.endsWith(']')) {
        // Parse the array
        final inner = ca.substring(1, ca.length - 1);
        correctOrder = inner.split(',').map((s) => s.trim()).toList();
      } else if (ca.contains('|')) {
        // Pipe-separated format
        correctOrder = ca.split('|').map((s) => s.trim()).toList();
      } else {
        // Single value
        correctOrder = [ca.trim()];
      }
    }


    if (correctOrder.isEmpty) {
      return true; // Give benefit of doubt
    }

    // Compare orders
    if (userOrder.length != correctOrder.length) {
      return false;
    }

    for (int i = 0; i < userOrder.length; i++) {
      if (userOrder[i].toLowerCase() != correctOrder[i].toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  void nextExercise() {
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.exercises.length;

    if (isComplete) {
      _completeLesson();
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        currentAnswer: null,
        showingResult: false,
      );
    }
  }

  Future<void> _completeLesson() async {
    if (state.lesson == null || state.startTime == null) {
      state = state.copyWith(isComplete: true);
      return;
    }

    final timeSpent = DateTime.now().difference(state.startTime!).inSeconds;

    // Get all collected answers
    final answers = state.collectedAnswers.values.toList();
    for (var i = 0; i < answers.length; i++) {
    }

    final result = await LearningService.submitLesson(
      lessonId: state.lesson!.id,
      answers: answers,
      timeSpent: timeSpent,
    );

    final xpEarned = result['success'] == true
        ? (result['data']?['xpEarned'] ?? 0) as int
        : 0;

    state = state.copyWith(
      isComplete: true,
      xpEarned: xpEarned,
    );
  }

  void reset() {
    state = const LessonPlayerState();
  }
}

/// Lesson player provider
final lessonPlayerProvider =
    StateNotifierProvider<LessonPlayerNotifier, LessonPlayerState>((ref) {
  return LessonPlayerNotifier();
});

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

// ==================== ACHIEVEMENT PROVIDERS ====================

/// Achievements provider
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  try {
    final result = await LearningService.getAchievements();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => Achievement.fromJson(e)).toList();
      } else if (data is Map && data['achievements'] != null) {
        return (data['achievements'] as List)
            .map((e) => Achievement.fromJson(e))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Unlocked achievements count (for badge)
final unlockedAchievementsCountProvider = Provider<int>((ref) {
  final achievements = ref.watch(achievementsProvider);
  return achievements.valueOrNull?.where((a) => a.isUnlocked).length ?? 0;
});

// ==================== CHALLENGE PROVIDERS ====================

/// Challenges provider
final challengesProvider = FutureProvider<List<Challenge>>((ref) async {
  try {
    final result = await LearningService.getChallenges();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => Challenge.fromJson(e)).toList();
      } else if (data is Map) {
        // Combine daily, weekly, and special challenges
        final List<Challenge> all = [];
        if (data['daily'] != null && data['daily'] is List) {
          all.addAll(
              (data['daily'] as List).map((e) => Challenge.fromJson(e)));
        }
        if (data['weekly'] != null && data['weekly'] is List) {
          all.addAll(
              (data['weekly'] as List).map((e) => Challenge.fromJson(e)));
        }
        if (data['special'] != null && data['special'] is List) {
          all.addAll(
              (data['special'] as List).map((e) => Challenge.fromJson(e)));
        }
        return all;
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Daily challenges provider
final dailyChallengesProvider = Provider<List<Challenge>>((ref) {
  final challenges = ref.watch(challengesProvider);
  return challenges.valueOrNull
          ?.where((c) => c.type.toLowerCase() == 'daily')
          .toList() ??
      [];
});

/// Weekly challenges provider
final weeklyChallengesProvider = Provider<List<Challenge>>((ref) {
  final challenges = ref.watch(challengesProvider);
  return challenges.valueOrNull
          ?.where((c) => c.type.toLowerCase() == 'weekly')
          .toList() ??
      [];
});

// ==================== LEADERBOARD PROVIDERS ====================

/// Leaderboard provider
final leaderboardProvider =
    FutureProvider.family<LeaderboardResponse?, LeaderboardFilter>(
        (ref, filter) async {
  try {
    final result = await LearningService.getLeaderboard(
      type: filter.type,
      language: filter.language,
      limit: filter.limit,
    );
    if (result['success'] == true && result['data'] != null) {
      return LeaderboardResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Selected leaderboard type
final leaderboardTypeProvider = StateProvider<String>((ref) {
  return 'weekly';
});
