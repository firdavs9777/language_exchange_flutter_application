class WeeklyDigest {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int xpEarned;
  final int lessonsCompleted;
  final int vocabularyLearned;
  final int challengesCompleted;
  final int currentStreak;
  final int longestStreak;
  final TopAchievement? topAchievement;
  final int daysActive;

  WeeklyDigest({
    required this.weekStart,
    required this.weekEnd,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.vocabularyLearned,
    required this.challengesCompleted,
    required this.currentStreak,
    required this.longestStreak,
    this.topAchievement,
    required this.daysActive,
  });

  factory WeeklyDigest.fromJson(Map<String, dynamic> json) {
    return WeeklyDigest(
      weekStart: DateTime.parse(json['weekStart']),
      weekEnd: DateTime.parse(json['weekEnd']),
      xpEarned: (json['xpEarned'] ?? 0) as int,
      lessonsCompleted: (json['lessonsCompleted'] ?? 0) as int,
      vocabularyLearned: (json['vocabularyLearned'] ?? 0) as int,
      challengesCompleted: (json['challengesCompleted'] ?? 0) as int,
      currentStreak: (json['currentStreak'] ?? 0) as int,
      longestStreak: (json['longestStreak'] ?? 0) as int,
      topAchievement: json['topAchievement'] != null
          ? TopAchievement.fromJson(json['topAchievement'])
          : null,
      daysActive: (json['daysActive'] ?? 0) as int,
    );
  }
}

class TopAchievement {
  final String id;
  final String name;
  final String? achievementCode;
  final DateTime? unlockedAt;

  TopAchievement({
    required this.id,
    required this.name,
    this.achievementCode,
    this.unlockedAt,
  });

  factory TopAchievement.fromJson(Map<String, dynamic> json) {
    return TopAchievement(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      achievementCode: json['achievementCode']?.toString(),
      unlockedAt: json['unlockedAt'] != null ? DateTime.tryParse(json['unlockedAt']) : null,
    );
  }
}
