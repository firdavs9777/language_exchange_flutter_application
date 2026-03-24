/// AI-Generated Quiz Models

import 'package:flutter/foundation.dart';

class AIQuiz {
  final String id;
  final String type; // weak_areas, vocabulary, recent_content, mixed
  final String title;
  final String? description;
  final String difficulty; // easy, medium, hard, adaptive
  final List<AIQuizQuestion> questions;
  final int questionCount;
  final List<String>? focusAreas;
  final String status; // pending, in_progress, completed
  final AIQuizResult? result;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  AIQuiz({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.difficulty,
    this.questions = const [],
    required this.questionCount,
    this.focusAreas,
    required this.status,
    this.result,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory AIQuiz.fromJson(Map<String, dynamic> json) {

    // Parse questions list
    final rawQuestions = json['questions'];
    List<AIQuizQuestion> questionsList = [];

    if (rawQuestions is List) {
      for (int i = 0; i < rawQuestions.length; i++) {
        final q = rawQuestions[i];
        if (q is Map) {
          final question = AIQuizQuestion.fromJson(Map<String, dynamic>.from(q));
          questionsList.add(question);
        }
      }
    }


    // Get question count from settings or questions length
    int questionCount = 0;
    if (json['settings'] is Map && json['settings']['questionCount'] != null) {
      questionCount = json['settings']['questionCount'] ?? 0;
    } else if (json['questionCount'] != null) {
      questionCount = json['questionCount'] ?? 0;
    } else {
      questionCount = questionsList.length;
    }

    // Get difficulty from settings or direct field
    String difficulty = 'medium';
    if (json['settings'] is Map && json['settings']['difficulty'] != null) {
      difficulty = json['settings']['difficulty'].toString();
    } else if (json['difficulty'] != null) {
      difficulty = json['difficulty'].toString();
    }

    // Parse target areas as focus areas
    List<String>? focusAreas;
    if (json['targetAreas'] is List) {
      focusAreas = (json['targetAreas'] as List)
          .map((e) => e is Map ? (e['type']?.toString() ?? '') : '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (json['focusAreas'] is List) {
      focusAreas = (json['focusAreas'] as List).map((e) => e.toString()).toList();
    }

    // Map status: 'ready' from API is like 'pending' in the app
    String status = json['status']?.toString() ?? 'pending';
    if (status == 'ready') status = 'pending';

    return AIQuiz(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'mixed',
      title: json['title']?.toString() ?? 'AI Quiz',
      description: json['description']?.toString(),
      difficulty: difficulty,
      questions: questionsList,
      questionCount: questionCount,
      focusAreas: focusAreas,
      status: status,
      result: json['result'] != null
          ? AIQuizResult.fromJson(json['result'] is Map ? Map<String, dynamic>.from(json['result']) : {})
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  String get typeLabel {
    switch (type) {
      case 'weak_areas':
        return 'Weak Areas';
      case 'vocabulary':
        return 'Vocabulary';
      case 'recent_content':
        return 'Recent Content';
      case 'mixed':
        return 'Mixed Practice';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'weak_areas':
        return '🎯';
      case 'vocabulary':
        return '📚';
      case 'recent_content':
        return '🔄';
      case 'mixed':
        return '🎲';
      default:
        return '❓';
    }
  }
}

class AIQuizQuestion {
  final String id;
  final String type; // multiple_choice, fill_blank, translation, true_false
  final String question;
  final String? context;
  final List<String>? options;
  final String? correctAnswer;
  final String? explanation;
  final String? hint;
  final int points;
  final String? focusArea;

  AIQuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.context,
    this.options,
    this.correctAnswer,
    this.explanation,
    this.hint,
    required this.points,
    this.focusArea,
  });

  factory AIQuizQuestion.fromJson(Map<String, dynamic> json) {
    // Parse options - can be list of strings or list of {text, isCorrect} objects
    List<String>? optionsList;
    String? correctAnswer;

    final rawOptions = json['options'];
    if (rawOptions is List && rawOptions.isNotEmpty) {
      final firstOption = rawOptions.first;
      if (firstOption is Map && firstOption.containsKey('text')) {
        // Options are objects with {text, isCorrect}
        optionsList = rawOptions
            .map((e) => e is Map ? (e['text']?.toString() ?? '') : '')
            .where((s) => s.isNotEmpty)
            .toList();
        // Find correct answer from options
        for (final opt in rawOptions) {
          if (opt is Map && opt['isCorrect'] == true) {
            correctAnswer = opt['text']?.toString();
            break;
          }
        }
      } else {
        // Options are plain strings
        optionsList = rawOptions.map((e) => e.toString()).toList();
      }
    }

    // Get correct answer - could be in 'correctAnswer', 'targetText', or extracted from options
    correctAnswer ??= json['correctAnswer']?.toString() ?? json['targetText']?.toString();

    return AIQuizQuestion(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'multiple_choice',
      question: json['question']?.toString() ?? '',
      context: json['context']?.toString(),
      options: optionsList,
      correctAnswer: correctAnswer,
      explanation: json['explanation']?.toString(),
      hint: json['hint']?.toString(),
      points: json['points'] ?? 10,
      focusArea: json['focusArea']?.toString(),
    );
  }

  bool get isMultipleChoice => type == 'multiple_choice';
  bool get isFillBlank => type == 'fill_blank';
  bool get isTranslation => type == 'translation';
  bool get isTrueFalse => type == 'true_false';
}

class AIQuizResult {
  final int score;
  final int totalPoints;
  final int correctCount;
  final int totalQuestions;
  final int xpEarned;
  final List<QuestionAnswer> answers;
  final List<String> strengths;
  final List<String> weaknesses;
  final String feedback;
  final int timeSpent;

  AIQuizResult({
    required this.score,
    required this.totalPoints,
    required this.correctCount,
    required this.totalQuestions,
    required this.xpEarned,
    this.answers = const [],
    this.strengths = const [],
    this.weaknesses = const [],
    required this.feedback,
    required this.timeSpent,
  });

  /// Safely parse an int from dynamic value
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) {
      if (value.isFinite) return value.toInt();
      return 0;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  factory AIQuizResult.fromJson(Map<String, dynamic> json) {
    return AIQuizResult(
      score: _safeInt(json['score']),
      totalPoints: _safeInt(json['totalPoints']),
      correctCount: _safeInt(json['correctCount']),
      totalQuestions: _safeInt(json['totalQuestions']),
      xpEarned: _safeInt(json['xpEarned']),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => QuestionAnswer.fromJson(e))
              .toList() ??
          [],
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      feedback: json['feedback']?.toString() ?? '',
      timeSpent: _safeInt(json['timeSpent']),
    );
  }

  double get percentage {
    if (totalPoints <= 0) return 0.0;
    final result = (score / totalPoints) * 100;
    if (!result.isFinite) return 0.0;
    return result.clamp(0.0, 100.0);
  }

  double get accuracyRate {
    if (totalQuestions <= 0) return 0.0;
    final result = (correctCount / totalQuestions) * 100;
    if (!result.isFinite) return 0.0;
    return result.clamp(0.0, 100.0);
  }

  String get grade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }
}

class QuestionAnswer {
  final String questionId;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? explanation;

  QuestionAnswer({
    required this.questionId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.explanation,
  });

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      questionId: json['questionId']?.toString() ?? '',
      userAnswer: json['userAnswer']?.toString() ?? json['answer']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      isCorrect: json['isCorrect'] ?? false,
      explanation: json['explanation']?.toString(),
    );
  }
}

class AIQuizStats {
  final int totalQuizzes;
  final int completedQuizzes;
  final double averageScore;
  final int totalXpEarned;
  final Map<String, int> quizzesByType;
  final Map<String, double> scoresByType;
  final List<WeakArea> weakAreas;
  final int currentStreak;

  AIQuizStats({
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.averageScore,
    required this.totalXpEarned,
    this.quizzesByType = const {},
    this.scoresByType = const {},
    this.weakAreas = const [],
    this.currentStreak = 0,
  });

  factory AIQuizStats.fromJson(Map<String, dynamic> json) {
    return AIQuizStats(
      totalQuizzes: json['totalQuizzes'] ?? 0,
      completedQuizzes: json['completedQuizzes'] ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalXpEarned: json['totalXpEarned'] ?? 0,
      quizzesByType: (json['quizzesByType'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      scoresByType: (json['scoresByType'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      weakAreas: (json['weakAreas'] as List<dynamic>?)
              ?.map((e) => WeakArea.fromJson(e))
              .toList() ??
          [],
      currentStreak: json['currentStreak'] ?? 0,
    );
  }
}

class WeakArea {
  final String name;
  final String category;
  final double accuracy;
  final int attempts;
  final String recommendation;

  WeakArea({
    required this.name,
    required this.category,
    required this.accuracy,
    required this.attempts,
    required this.recommendation,
  });

  factory WeakArea.fromJson(Map<String, dynamic> json) {
    return WeakArea(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      attempts: json['attempts'] ?? 0,
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

/// Request to generate AI quiz
class GenerateQuizRequest {
  final String type;
  final int questionCount;
  final String difficulty;
  final String? language;
  final List<String>? focusAreas;
  final List<String>? vocabularyIds;

  GenerateQuizRequest({
    required this.type,
    this.questionCount = 10,
    this.difficulty = 'adaptive',
    this.language,
    this.focusAreas,
    this.vocabularyIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'questionCount': questionCount,
      'difficulty': difficulty,
      if (language != null) 'language': language,
      if (focusAreas != null) 'focusAreas': focusAreas,
      if (vocabularyIds != null) 'vocabularyIds': vocabularyIds,
    };
  }
}

/// Request to submit quiz answer
class SubmitAnswerRequest {
  final int questionIndex;
  final String answer;

  SubmitAnswerRequest({
    required this.questionIndex,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionIndex': questionIndex,
      'answer': answer,
    };
  }
}

/// Request to complete quiz
class CompleteQuizRequest {
  final List<String> answers;
  final int timeSpent;

  CompleteQuizRequest({
    required this.answers,
    required this.timeSpent,
  });

  Map<String, dynamic> toJson() {
    return {
      'answers': answers,
      'timeSpent': timeSpent,
    };
  }
}
