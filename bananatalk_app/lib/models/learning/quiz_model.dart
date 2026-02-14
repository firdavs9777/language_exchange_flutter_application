/// Quiz Model
/// Represents quizzes for placement, assessment, and practice

class Quiz {
  final String id;
  final String title;
  final String type; // placement, assessment, practice
  final String language;
  final String? level;
  final String? category;
  final String description;
  final int questionCount;
  final int timeLimit; // seconds, 0 = no limit
  final int xpReward;
  final List<QuizQuestion> questions;
  final bool isCompleted;
  final QuizResult? lastResult;

  Quiz({
    required this.id,
    required this.title,
    required this.type,
    required this.language,
    this.level,
    this.category,
    required this.description,
    required this.questionCount,
    this.timeLimit = 0,
    required this.xpReward,
    this.questions = const [],
    this.isCompleted = false,
    this.lastResult,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'practice',
      language: json['language']?.toString() ?? 'en',
      level: json['level']?.toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString() ?? '',
      questionCount: json['questionCount'] ?? 0,
      timeLimit: json['timeLimit'] ?? 0,
      xpReward: json['xpReward'] ?? 30,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] ?? false,
      lastResult: json['lastResult'] != null
          ? QuizResult.fromJson(json['lastResult'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'type': type,
      'language': language,
      if (level != null) 'level': level,
      if (category != null) 'category': category,
      'description': description,
      'questionCount': questionCount,
      'timeLimit': timeLimit,
      'xpReward': xpReward,
      'questions': questions.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
      if (lastResult != null) 'lastResult': lastResult!.toJson(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'placement':
        return 'Placement Test';
      case 'assessment':
        return 'Assessment';
      case 'practice':
        return 'Practice Quiz';
      default:
        return 'Quiz';
    }
  }

  String get timeLimitFormatted {
    if (timeLimit == 0) return 'No time limit';
    final minutes = timeLimit ~/ 60;
    final seconds = timeLimit % 60;
    if (minutes > 0 && seconds > 0) {
      return '${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes} min';
    } else {
      return '${seconds}s';
    }
  }
}

class QuizQuestion {
  final String id;
  final String type; // multiple_choice, true_false, fill_blank, matching
  final String question;
  final String? audioUrl;
  final String? imageUrl;
  final List<String>? options;
  final dynamic correctAnswer;
  final String? explanation;
  final int points;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.audioUrl,
    this.imageUrl,
    this.options,
    this.correctAnswer,
    this.explanation,
    required this.points,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'multiple_choice',
      question: json['question']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation']?.toString(),
      points: json['points'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question': question,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (options != null) 'options': options,
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      'points': points,
    };
  }
}

class QuizResult {
  final String quizId;
  final int score;
  final int totalPoints;
  final int xpEarned;
  final String? determinedLevel;
  final List<QuestionResult> results;
  final List<String> recommendations;
  final DateTime completedAt;

  QuizResult({
    required this.quizId,
    required this.score,
    required this.totalPoints,
    required this.xpEarned,
    this.determinedLevel,
    required this.results,
    this.recommendations = const [],
    required this.completedAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId']?.toString() ?? '',
      score: json['score'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      determinedLevel: json['determinedLevel']?.toString(),
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => QuestionResult.fromJson(e))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'score': score,
      'totalPoints': totalPoints,
      'xpEarned': xpEarned,
      if (determinedLevel != null) 'determinedLevel': determinedLevel,
      'results': results.map((e) => e.toJson()).toList(),
      'recommendations': recommendations,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  double get percentage => totalPoints > 0 ? score / totalPoints * 100 : 0;
}

class QuestionResult {
  final String questionId;
  final dynamic userAnswer;
  final bool isCorrect;

  QuestionResult({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId']?.toString() ?? '',
      userAnswer: json['userAnswer'],
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    };
  }
}

/// Quiz answer for submission
class QuizAnswer {
  final String questionId;
  final String selectedOption;

  QuizAnswer({
    required this.questionId,
    required this.selectedOption,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOption': selectedOption,
    };
  }
}

/// Quiz submit response
class QuizSubmitResponse {
  final int score;
  final int xpEarned;
  final String? determinedLevel;
  final List<QuestionResult> results;
  final List<String> recommendations;

  QuizSubmitResponse({
    required this.score,
    required this.xpEarned,
    this.determinedLevel,
    required this.results,
    this.recommendations = const [],
  });

  factory QuizSubmitResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResponse(
      score: json['score'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      determinedLevel: json['determinedLevel']?.toString(),
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => QuestionResult.fromJson(e))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
