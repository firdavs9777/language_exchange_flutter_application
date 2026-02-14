// Learning Progress Model
// Represents user's learning progress including XP, levels, streaks, and goals

/// Helper to safely parse int from dynamic (handles String, int, double, null)
int _safeInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper to safely parse double from dynamic
double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class LearningProgress {
  final String id;
  final String oduserId;
  final int totalXP;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int streakFreezes;
  final int dailyXP;
  final int weeklyXP;
  final int dailyGoal;
  final int weeklyGoal;
  final double dailyGoalProgress;
  final double weeklyGoalProgress;
  final int daysCompletedThisWeek;
  final DateTime? lastActivityDate;
  final LearningStats stats;
  final int? weeklyRank;
  final int? allTimeRank;
  final LevelInfo levelInfo;

  LearningProgress({
    required this.id,
    required this.oduserId,
    required this.totalXP,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    this.streakFreezes = 0,
    required this.dailyXP,
    required this.weeklyXP,
    required this.dailyGoal,
    required this.weeklyGoal,
    required this.dailyGoalProgress,
    required this.weeklyGoalProgress,
    required this.daysCompletedThisWeek,
    this.lastActivityDate,
    required this.stats,
    this.weeklyRank,
    this.allTimeRank,
    required this.levelInfo,
  });

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      id: json['_id']?.toString() ?? '',
      oduserId: json['user']?.toString() ?? '',
      totalXP: _safeInt(json['totalXP']),
      level: _safeInt(json['level'], 1),
      currentStreak: _safeInt(json['currentStreak']),
      longestStreak: _safeInt(json['longestStreak']),
      streakFreezes: _safeInt(json['streakFreezes']),
      dailyXP: _safeInt(json['dailyXP']),
      weeklyXP: _safeInt(json['weeklyXP']),
      dailyGoal: _safeInt(json['dailyGoal'], 50),
      weeklyGoal: _safeInt(json['weeklyGoal'], 300),
      dailyGoalProgress: _safeDouble(json['dailyGoalProgress']),
      weeklyGoalProgress: _safeDouble(json['weeklyGoalProgress']),
      daysCompletedThisWeek: _safeInt(json['daysCompletedThisWeek']),
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.tryParse(json['lastActivityDate'].toString())
          : null,
      stats: json['stats'] != null && json['stats'] is Map
          ? LearningStats.fromJson(Map<String, dynamic>.from(json['stats']))
          : LearningStats.empty(),
      weeklyRank: json['weeklyRank'] != null ? _safeInt(json['weeklyRank']) : null,
      allTimeRank: json['allTimeRank'] != null ? _safeInt(json['allTimeRank']) : null,
      levelInfo: json['levelInfo'] != null && json['levelInfo'] is Map
          ? LevelInfo.fromJson(Map<String, dynamic>.from(json['levelInfo']))
          : LevelInfo.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': oduserId,
      'totalXP': totalXP,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'streakFreezes': streakFreezes,
      'dailyXP': dailyXP,
      'weeklyXP': weeklyXP,
      'dailyGoal': dailyGoal,
      'weeklyGoal': weeklyGoal,
      'dailyGoalProgress': dailyGoalProgress,
      'weeklyGoalProgress': weeklyGoalProgress,
      'daysCompletedThisWeek': daysCompletedThisWeek,
      if (lastActivityDate != null)
        'lastActivityDate': lastActivityDate!.toIso8601String(),
      'stats': stats.toJson(),
      if (weeklyRank != null) 'weeklyRank': weeklyRank,
      if (allTimeRank != null) 'allTimeRank': allTimeRank,
      'levelInfo': levelInfo.toJson(),
    };
  }

  LearningProgress copyWith({
    String? id,
    String? oduserId,
    int? totalXP,
    int? level,
    int? currentStreak,
    int? longestStreak,
    int? streakFreezes,
    int? dailyXP,
    int? weeklyXP,
    int? dailyGoal,
    int? weeklyGoal,
    double? dailyGoalProgress,
    double? weeklyGoalProgress,
    int? daysCompletedThisWeek,
    DateTime? lastActivityDate,
    LearningStats? stats,
    int? weeklyRank,
    int? allTimeRank,
    LevelInfo? levelInfo,
  }) {
    return LearningProgress(
      id: id ?? this.id,
      oduserId: oduserId ?? this.oduserId,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      dailyXP: dailyXP ?? this.dailyXP,
      weeklyXP: weeklyXP ?? this.weeklyXP,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      dailyGoalProgress: dailyGoalProgress ?? this.dailyGoalProgress,
      weeklyGoalProgress: weeklyGoalProgress ?? this.weeklyGoalProgress,
      daysCompletedThisWeek: daysCompletedThisWeek ?? this.daysCompletedThisWeek,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      stats: stats ?? this.stats,
      weeklyRank: weeklyRank ?? this.weeklyRank,
      allTimeRank: allTimeRank ?? this.allTimeRank,
      levelInfo: levelInfo ?? this.levelInfo,
    );
  }
}

class LearningStats {
  final int totalMessages;
  final int messagesInTargetLanguage;
  final int correctionsGiven;
  final int correctionsReceived;
  final int correctionsAccepted;
  final int lessonsCompleted;
  final int quizzesTaken;
  final int vocabularyLearned;
  final int vocabularyMastered;
  final int timeSpentLearning;

  LearningStats({
    required this.totalMessages,
    required this.messagesInTargetLanguage,
    required this.correctionsGiven,
    required this.correctionsReceived,
    required this.correctionsAccepted,
    required this.lessonsCompleted,
    required this.quizzesTaken,
    required this.vocabularyLearned,
    required this.vocabularyMastered,
    required this.timeSpentLearning,
  });

  factory LearningStats.empty() {
    return LearningStats(
      totalMessages: 0,
      messagesInTargetLanguage: 0,
      correctionsGiven: 0,
      correctionsReceived: 0,
      correctionsAccepted: 0,
      lessonsCompleted: 0,
      quizzesTaken: 0,
      vocabularyLearned: 0,
      vocabularyMastered: 0,
      timeSpentLearning: 0,
    );
  }

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      totalMessages: _safeInt(json['totalMessages']),
      messagesInTargetLanguage: _safeInt(json['messagesInTargetLanguage']),
      correctionsGiven: _safeInt(json['correctionsGiven']),
      correctionsReceived: _safeInt(json['correctionsReceived']),
      correctionsAccepted: _safeInt(json['correctionsAccepted']),
      lessonsCompleted: _safeInt(json['lessonsCompleted']),
      quizzesTaken: _safeInt(json['quizzesTaken']),
      vocabularyLearned: _safeInt(json['vocabularyLearned']),
      vocabularyMastered: _safeInt(json['vocabularyMastered']),
      timeSpentLearning: _safeInt(json['timeSpentLearning']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMessages': totalMessages,
      'messagesInTargetLanguage': messagesInTargetLanguage,
      'correctionsGiven': correctionsGiven,
      'correctionsReceived': correctionsReceived,
      'correctionsAccepted': correctionsAccepted,
      'lessonsCompleted': lessonsCompleted,
      'quizzesTaken': quizzesTaken,
      'vocabularyLearned': vocabularyLearned,
      'vocabularyMastered': vocabularyMastered,
      'timeSpentLearning': timeSpentLearning,
    };
  }
}

class LevelInfo {
  final int current;
  final int xpForCurrent;
  final int xpForNext;
  final double progress;
  final int xpNeeded;

  LevelInfo({
    required this.current,
    required this.xpForCurrent,
    required this.xpForNext,
    required this.progress,
    required this.xpNeeded,
  });

  factory LevelInfo.empty() {
    return LevelInfo(
      current: 1,
      xpForCurrent: 0,
      xpForNext: 25,
      progress: 0,
      xpNeeded: 25,
    );
  }

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      current: _safeInt(json['current'], 1),
      xpForCurrent: _safeInt(json['xpForCurrent']),
      xpForNext: _safeInt(json['xpForNext'], 25),
      progress: _safeDouble(json['progress']),
      xpNeeded: _safeInt(json['xpNeeded'], 25),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'xpForCurrent': xpForCurrent,
      'xpForNext': xpForNext,
      'progress': progress,
      'xpNeeded': xpNeeded,
    };
  }
}

/// Daily goals response model
class DailyGoalsResponse {
  final int dailyGoal;
  final int weeklyGoal;
  final int dailyXP;
  final int weeklyXP;
  final double dailyProgress;
  final double weeklyProgress;

  DailyGoalsResponse({
    required this.dailyGoal,
    required this.weeklyGoal,
    required this.dailyXP,
    required this.weeklyXP,
    required this.dailyProgress,
    required this.weeklyProgress,
  });

  factory DailyGoalsResponse.fromJson(Map<String, dynamic> json) {
    return DailyGoalsResponse(
      dailyGoal: _safeInt(json['dailyGoal'], 50),
      weeklyGoal: _safeInt(json['weeklyGoal'], 300),
      dailyXP: _safeInt(json['dailyXP']),
      weeklyXP: _safeInt(json['weeklyXP']),
      dailyProgress: _safeDouble(json['dailyProgress']),
      weeklyProgress: _safeDouble(json['weeklyProgress']),
    );
  }
}

/// Goal presets
enum GoalPreset {
  casual(dailyXP: 20, weeklyXP: 100, label: 'Casual'),
  regular(dailyXP: 50, weeklyXP: 300, label: 'Regular'),
  serious(dailyXP: 100, weeklyXP: 600, label: 'Serious'),
  intense(dailyXP: 150, weeklyXP: 1000, label: 'Intense');

  final int dailyXP;
  final int weeklyXP;
  final String label;

  const GoalPreset({
    required this.dailyXP,
    required this.weeklyXP,
    required this.label,
  });
}
