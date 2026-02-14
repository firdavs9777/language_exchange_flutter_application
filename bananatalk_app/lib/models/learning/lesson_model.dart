// Lesson Model
// Represents lessons, exercises, and curriculum structure

import 'package:flutter/foundation.dart';

/// Helper to safely parse int from dynamic (handles String, int, double, null)
int _safeInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class Lesson {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String language;
  final String level; // A1, A2, B1, B2, C1, C2
  final String category;
  final String topic;
  final String? icon;
  final int estimatedMinutes;
  final int xpReward;
  final bool isPremium;
  final LessonUnit unit;
  final int orderInUnit;
  final String? introduction;
  final List<LessonContent> content;
  final List<Exercise> exercises;
  final int perfectBonus;
  final LessonProgress? userProgress;

  Lesson({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.language,
    required this.level,
    required this.category,
    required this.topic,
    this.icon,
    required this.estimatedMinutes,
    required this.xpReward,
    this.isPremium = false,
    required this.unit,
    required this.orderInUnit,
    this.introduction,
    this.content = const [],
    this.exercises = const [],
    this.perfectBonus = 5,
    this.userProgress,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      level: json['level']?.toString() ?? 'A1',
      category: json['category']?.toString() ?? 'general',
      topic: json['topic']?.toString() ?? '',
      icon: json['icon']?.toString(),
      estimatedMinutes: _safeInt(json['estimatedMinutes'], 10),
      xpReward: _safeInt(json['xpReward'], 20),
      isPremium: json['isPremium'] ?? false,
      unit: json['unit'] != null && json['unit'] is Map
          ? LessonUnit.fromJson(Map<String, dynamic>.from(json['unit']))
          : LessonUnit.empty(),
      orderInUnit: _safeInt(json['orderInUnit']),
      introduction: json['introduction']?.toString(),
      content: json['content'] != null && json['content'] is List
          ? (json['content'] as List<dynamic>)
              .map((e) => LessonContent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      exercises: json['exercises'] != null && json['exercises'] is List
          ? (json['exercises'] as List<dynamic>)
              .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      perfectBonus: _safeInt(json['perfectBonus'], 5),
      userProgress: json['userProgress'] != null && json['userProgress'] is Map
          ? LessonProgress.fromJson(Map<String, dynamic>.from(json['userProgress']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'language': language,
      'level': level,
      'category': category,
      'topic': topic,
      if (icon != null) 'icon': icon,
      'estimatedMinutes': estimatedMinutes,
      'xpReward': xpReward,
      'isPremium': isPremium,
      'unit': unit.toJson(),
      'orderInUnit': orderInUnit,
      if (introduction != null) 'introduction': introduction,
      'content': content.map((e) => e.toJson()).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'perfectBonus': perfectBonus,
      if (userProgress != null) 'userProgress': userProgress!.toJson(),
    };
  }

  bool get isCompleted => userProgress?.status == 'completed';
  int? get bestScore => userProgress?.score;
}

class LessonUnit {
  final int number;
  final String name;

  LessonUnit({
    required this.number,
    required this.name,
  });

  factory LessonUnit.empty() {
    return LessonUnit(number: 1, name: 'Basics');
  }

  factory LessonUnit.fromJson(Map<String, dynamic> json) {
    return LessonUnit(
      number: _safeInt(json['number'], 1),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
    };
  }
}

class LessonContent {
  final String type; // text, example, audio, tip, video, image
  final String? title;
  final String body;
  final String? translation;
  final String? audioUrl;
  final String? videoUrl;
  final String? imageUrl;
  final int order;

  LessonContent({
    required this.type,
    this.title,
    required this.body,
    this.translation,
    this.audioUrl,
    this.videoUrl,
    this.imageUrl,
    required this.order,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      type: json['type']?.toString() ?? 'text',
      title: json['title']?.toString(),
      body: json['body']?.toString() ?? json['text']?.toString() ?? '',
      translation: json['translation']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      order: _safeInt(json['order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (title != null) 'title': title,
      'body': body,
      if (translation != null) 'translation': translation,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'order': order,
    };
  }
}

class Exercise {
  final String type; // multiple_choice, fill_blank, translation, matching, ordering
  final String question;
  final String instruction;
  final String? explanation;
  final List<ExerciseOption> options;
  final String? correctAnswer;
  final List<String>? acceptedAnswers;
  final List<MatchingPair> matchingPairs;
  final List<String>? scrambledItems;
  final List<String>? correctOrder;
  final String? hint;
  final String? audioUrl;
  final String? imageUrl;
  final int points;
  final int order;

  Exercise({
    required this.type,
    required this.question,
    this.instruction = '',
    this.explanation,
    this.options = const [],
    this.correctAnswer,
    this.acceptedAnswers,
    this.matchingPairs = const [],
    this.scrambledItems,
    this.correctOrder,
    this.hint,
    this.audioUrl,
    this.imageUrl,
    required this.points,
    required this.order,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Parse options safely
    List<ExerciseOption> parseOptions() {
      final optionsData = json['options'];
      if (optionsData == null || optionsData is! List) return [];
      return optionsData
          .asMap()
          .map((i, e) => MapEntry(i, ExerciseOption.fromJson(
              e is Map ? Map<String, dynamic>.from(e) : {'text': e.toString()},
              index: i)))
          .values
          .toList();
    }

    // Parse matching pairs safely
    List<MatchingPair> parseMatchingPairs() {
      final exerciseType = json['type']?.toString() ?? '';
      final pairsData = json['pairs'] ?? json['matchingPairs'];

      // Debug logging for matching exercises
      if (exerciseType.toLowerCase() == 'matching') {
        debugPrint('🔧 Parsing MATCHING exercise:');
        debugPrint('🔧 Raw json keys: ${json.keys.toList()}');
        debugPrint('🔧 pairs field: ${json['pairs']}');
        debugPrint('🔧 matchingPairs field: ${json['matchingPairs']}');
        debugPrint('🔧 items field: ${json['items']}');
        debugPrint('🔧 leftItems field: ${json['leftItems']}');
        debugPrint('🔧 rightItems field: ${json['rightItems']}');
        debugPrint('🔧 leftColumn field: ${json['leftColumn']}');
        debugPrint('🔧 rightColumn field: ${json['rightColumn']}');
        debugPrint('🔧 options field: ${json['options']}');
      }

      if (pairsData != null && pairsData is List && pairsData.isNotEmpty) {
        debugPrint('🔧 Using pairs/matchingPairs field with ${pairsData.length} items');
        return pairsData
            .map((e) => MatchingPair.fromJson(
                e is Map ? Map<String, dynamic>.from(e) : {'left': '', 'right': ''}))
            .toList();
      }

      // Try 'items' field
      final items = json['items'];
      if (items != null && items is List && items.isNotEmpty) {
        debugPrint('🔧 Using items field with ${items.length} items');
        return items
            .map((e) => MatchingPair.fromJson(
                e is Map ? Map<String, dynamic>.from(e) : {'left': '', 'right': ''}))
            .toList();
      }

      // Try leftItems/rightItems as separate arrays
      final leftItems = json['leftItems'] ?? json['leftColumn'];
      final rightItems = json['rightItems'] ?? json['rightColumn'];
      if (leftItems != null && rightItems != null &&
          leftItems is List && rightItems is List &&
          leftItems.isNotEmpty && rightItems.isNotEmpty) {
        debugPrint('🔧 Using leftItems/rightItems with ${leftItems.length} + ${rightItems.length} items');
        final pairs = <MatchingPair>[];
        final minLen = leftItems.length < rightItems.length ? leftItems.length : rightItems.length;
        for (int i = 0; i < minLen; i++) {
          pairs.add(MatchingPair(
            left: leftItems[i].toString(),
            right: rightItems[i].toString(),
          ));
        }
        return pairs;
      }

      // Try to construct pairs from options (AI might generate options for matching)
      final options = json['options'];
      if (options != null && options is List && options.isNotEmpty) {
        debugPrint('🔧 Trying to construct pairs from ${options.length} options');
        final firstOpt = options.first;

        // Check if options have text/matchWith structure (AI-generated matching)
        if (firstOpt is Map && firstOpt['text'] != null && firstOpt['matchWith'] != null) {
          debugPrint('🔧 Found text/matchWith structure in options');
          final pairs = <MatchingPair>[];
          for (var opt in options) {
            if (opt is Map && opt['text'] != null && opt['matchWith'] != null) {
              pairs.add(MatchingPair(
                left: opt['text'].toString(),
                right: opt['matchWith'].toString(),
              ));
            }
          }
          if (pairs.isNotEmpty) {
            debugPrint('🔧 Constructed ${pairs.length} pairs from text/matchWith options');
            return pairs;
          }
        }

        // Check if options have left/right structure
        if (firstOpt is Map && (firstOpt['left'] != null || firstOpt['right'] != null)) {
          return options
              .map((e) => MatchingPair.fromJson(
                  e is Map ? Map<String, dynamic>.from(e) : {'left': '', 'right': ''}))
              .toList();
        }

        // Check if options have term/definition structure (another common format)
        if (firstOpt is Map && firstOpt['term'] != null && firstOpt['definition'] != null) {
          debugPrint('🔧 Found term/definition structure in options');
          final pairs = <MatchingPair>[];
          for (var opt in options) {
            if (opt is Map && opt['term'] != null && opt['definition'] != null) {
              pairs.add(MatchingPair(
                left: opt['term'].toString(),
                right: opt['definition'].toString(),
              ));
            }
          }
          if (pairs.isNotEmpty) {
            debugPrint('🔧 Constructed ${pairs.length} pairs from term/definition options');
            return pairs;
          }
        }
      }

      debugPrint('🔧 No matching pairs found');
      return [];
    }

    return Exercise(
      type: json['type']?.toString() ?? 'multiple_choice',
      question: json['question']?.toString() ?? json['targetText']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? _getDefaultInstruction(json['type']?.toString() ?? ''),
      explanation: json['explanation']?.toString(),
      options: parseOptions(),
      correctAnswer: json['correctAnswer']?.toString(),
      acceptedAnswers: (json['acceptedAnswers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      matchingPairs: parseMatchingPairs(),
      scrambledItems: (json['scrambledItems'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctOrder: (json['correctOrder'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      hint: json['hint']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      points: _safeInt(json['points'], 10),
      order: _safeInt(json['order']),
    );
  }

  static String _getDefaultInstruction(String type) {
    switch (type.toLowerCase()) {
      case 'multiple_choice':
        return 'Choose the correct answer';
      case 'fill_blank':
        return 'Fill in the blank';
      case 'translation':
        return 'Translate the following';
      case 'matching':
        return 'Match the items';
      case 'ordering':
        return 'Put the items in the correct order';
      default:
        return 'Complete the exercise';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'question': question,
      'instruction': instruction,
      if (explanation != null) 'explanation': explanation,
      'options': options.map((e) => e.toJson()).toList(),
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      if (acceptedAnswers != null) 'acceptedAnswers': acceptedAnswers,
      'pairs': matchingPairs.map((e) => e.toJson()).toList(),
      if (scrambledItems != null) 'scrambledItems': scrambledItems,
      if (correctOrder != null) 'correctOrder': correctOrder,
      if (hint != null) 'hint': hint,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'points': points,
      'order': order,
    };
  }
}

class ExerciseOption {
  final String id;
  final String text;
  final bool isCorrect;

  ExerciseOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory ExerciseOption.fromJson(Map<String, dynamic> json, {int index = 0}) {
    return ExerciseOption(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? 'opt_$index',
      text: json['text']?.toString() ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

class MatchingPair {
  final String left;
  final String right;

  MatchingPair({
    required this.left,
    required this.right,
  });

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      left: json['left']?.toString() ?? '',
      right: json['right']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'right': right,
    };
  }
}

class LessonProgress {
  final String status; // not_started, in_progress, completed
  final DateTime? completedAt;
  final int? score;
  final bool perfectScore;

  LessonProgress({
    required this.status,
    this.completedAt,
    this.score,
    this.perfectScore = false,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      status: json['status']?.toString() ?? 'not_started',
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      score: json['score'],
      perfectScore: json['perfectScore'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (score != null) 'score': score,
      'perfectScore': perfectScore,
    };
  }
}

/// Lesson submission result
class LessonSubmitResult {
  final int score;
  final int totalPoints;
  final int earnedPoints;
  final int xpEarned;
  final bool perfectScore;
  final List<ExerciseResult> results;
  final int? newLevel;
  final List<dynamic> achievementsUnlocked;

  LessonSubmitResult({
    required this.score,
    required this.totalPoints,
    required this.earnedPoints,
    required this.xpEarned,
    required this.perfectScore,
    required this.results,
    this.newLevel,
    this.achievementsUnlocked = const [],
  });

  factory LessonSubmitResult.fromJson(Map<String, dynamic> json) {
    return LessonSubmitResult(
      score: json['score'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      earnedPoints: json['earnedPoints'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      perfectScore: json['perfectScore'] ?? false,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => ExerciseResult.fromJson(e))
              .toList() ??
          [],
      newLevel: json['newLevel'],
      achievementsUnlocked: json['achievementsUnlocked'] ?? [],
    );
  }
}

class ExerciseResult {
  final int exerciseIndex;
  final bool correct;
  final int points;
  final dynamic correctAnswer;

  ExerciseResult({
    required this.exerciseIndex,
    required this.correct,
    required this.points,
    this.correctAnswer,
  });

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      exerciseIndex: json['exerciseIndex'] ?? 0,
      correct: json['correct'] ?? false,
      points: json['points'] ?? 0,
      correctAnswer: json['correctAnswer'],
    );
  }
}

/// Lessons response with units
class LessonsResponse {
  final List<Lesson> lessons;
  final List<UnitSummary> units;
  final UserLessonStats? userStats;

  LessonsResponse({
    required this.lessons,
    required this.units,
    this.userStats,
  });

  factory LessonsResponse.fromJson(Map<String, dynamic> json) {
    return LessonsResponse(
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => Lesson.fromJson(e))
              .toList() ??
          [],
      units: (json['units'] as List<dynamic>?)
              ?.map((e) => UnitSummary.fromJson(e))
              .toList() ??
          [],
      userStats: json['userStats'] != null
          ? UserLessonStats.fromJson(json['userStats'])
          : null,
    );
  }
}

class UnitSummary {
  final int number;
  final String name;
  final int lessonsCount;
  final int completedCount;

  UnitSummary({
    required this.number,
    required this.name,
    required this.lessonsCount,
    required this.completedCount,
  });

  factory UnitSummary.fromJson(Map<String, dynamic> json) {
    return UnitSummary(
      number: json['number'] ?? 0,
      name: json['name']?.toString() ?? '',
      lessonsCount: json['lessonsCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
    );
  }

  double get progress =>
      lessonsCount > 0 ? completedCount / lessonsCount : 0;
}

class UserLessonStats {
  final int totalCompleted;
  final String? currentLevel;

  UserLessonStats({
    required this.totalCompleted,
    this.currentLevel,
  });

  factory UserLessonStats.fromJson(Map<String, dynamic> json) {
    return UserLessonStats(
      totalCompleted: json['totalCompleted'] ?? 0,
      currentLevel: json['currentLevel']?.toString(),
    );
  }
}

/// Lesson answer for submission
class LessonAnswer {
  final String? exerciseId;
  final int? exerciseIndex;
  final dynamic answer;
  final bool? isCorrect;

  LessonAnswer({
    this.exerciseId,
    this.exerciseIndex,
    required this.answer,
    this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      if (exerciseId != null) 'exerciseId': exerciseId,
      if (exerciseIndex != null) 'exerciseIndex': exerciseIndex,
      'answer': answer,
      if (isCorrect != null) 'isCorrect': isCorrect,
    };
  }
}
