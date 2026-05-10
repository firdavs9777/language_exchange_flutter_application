import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

// ==================== LESSON PROVIDERS ====================

/// Lesson filter
class LessonFilter {
  final String? language;
  final String? sourceLanguage;
  final String? level;
  final String? category;
  final int? unit;

  const LessonFilter({
    this.language,
    this.sourceLanguage,
    this.level,
    this.category,
    this.unit,
  });

  LessonFilter copyWith({
    String? language,
    String? sourceLanguage,
    String? level,
    String? category,
    int? unit,
  }) {
    return LessonFilter(
      language: language ?? this.language,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
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
        other.sourceLanguage == sourceLanguage &&
        other.level == level &&
        other.category == category &&
        other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(language, sourceLanguage, level, category, unit);
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
      sourceLanguage: filter.sourceLanguage,
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
    // Get user's language pair for personalized recommendations
    final user = ref.watch(userProvider).valueOrNull;
    final result = await LearningService.getRecommendedLessons(
      language: user?.language_to_learn,
      sourceLanguage: user?.native_language,
    );
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
