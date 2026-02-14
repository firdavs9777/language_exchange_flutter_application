/// Achievement Model
/// Represents achievements and badges in the gamification system

class Achievement {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final int xpReward;
  final String rarity; // common, rare, epic, legendary
  final AchievementRequirement requirement;
  final AchievementProgress? userProgress;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.xpReward,
    required this.rarity,
    required this.requirement,
    this.userProgress,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      icon: json['icon']?.toString() ?? 'star',
      xpReward: json['xpReward'] ?? 0,
      rarity: json['rarity']?.toString() ?? 'common',
      requirement: json['requirement'] != null
          ? AchievementRequirement.fromJson(json['requirement'])
          : AchievementRequirement.empty(),
      userProgress: json['userProgress'] != null
          ? AchievementProgress.fromJson(json['userProgress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'xpReward': xpReward,
      'rarity': rarity,
      'requirement': requirement.toJson(),
      if (userProgress != null) 'userProgress': userProgress!.toJson(),
    };
  }

  bool get isUnlocked => userProgress?.unlocked ?? false;
  double get progress => userProgress?.percentage ?? 0;

  String get rarityLabel {
    switch (rarity) {
      case 'common':
        return 'Common';
      case 'rare':
        return 'Rare';
      case 'epic':
        return 'Epic';
      case 'legendary':
        return 'Legendary';
      default:
        return rarity;
    }
  }
}

class AchievementRequirement {
  final String type;
  final int value;

  AchievementRequirement({
    required this.type,
    required this.value,
  });

  factory AchievementRequirement.empty() {
    return AchievementRequirement(type: '', value: 0);
  }

  factory AchievementRequirement.fromJson(Map<String, dynamic> json) {
    return AchievementRequirement(
      type: json['type']?.toString() ?? '',
      value: json['value'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }
}

class AchievementProgress {
  final bool unlocked;
  final DateTime? unlockedAt;
  final int progress;
  final double percentage;

  AchievementProgress({
    required this.unlocked,
    this.unlockedAt,
    required this.progress,
    required this.percentage,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      unlocked: json['unlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'])
          : null,
      progress: json['progress'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlocked': unlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
      'progress': progress,
      'percentage': percentage,
    };
  }
}

/// Achievements response
class AchievementsResponse {
  final List<Achievement> achievements;
  final AchievementStats stats;
  final Map<String, CategoryStats> byCategory;

  AchievementsResponse({
    required this.achievements,
    required this.stats,
    required this.byCategory,
  });

  factory AchievementsResponse.fromJson(Map<String, dynamic> json) {
    final byCategoryJson = json['byCategory'] as Map<String, dynamic>?;
    final byCategory = <String, CategoryStats>{};
    if (byCategoryJson != null) {
      byCategoryJson.forEach((key, value) {
        byCategory[key] = CategoryStats.fromJson(value);
      });
    }

    return AchievementsResponse(
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => Achievement.fromJson(e))
              .toList() ??
          [],
      stats: json['stats'] != null
          ? AchievementStats.fromJson(json['stats'])
          : AchievementStats.empty(),
      byCategory: byCategory,
    );
  }
}

class AchievementStats {
  final int total;
  final int unlocked;
  final double percentage;

  AchievementStats({
    required this.total,
    required this.unlocked,
    required this.percentage,
  });

  factory AchievementStats.empty() {
    return AchievementStats(total: 0, unlocked: 0, percentage: 0);
  }

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    return AchievementStats(
      total: json['total'] ?? 0,
      unlocked: json['unlocked'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class CategoryStats {
  final int total;
  final int unlocked;

  CategoryStats({
    required this.total,
    required this.unlocked,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      total: json['total'] ?? 0,
      unlocked: json['unlocked'] ?? 0,
    );
  }

  double get percentage => total > 0 ? unlocked / total : 0;
}

/// Achievement categories
enum AchievementCategory {
  beginner(name: 'Beginner', description: 'First-time accomplishments'),
  vocabulary(name: 'Vocabulary', description: 'Vocabulary milestones'),
  lessons(name: 'Lessons', description: 'Lesson completion milestones'),
  streaks(name: 'Streaks', description: 'Streak achievements'),
  social(name: 'Social', description: 'Conversation/correction related'),
  milestones(name: 'Milestones', description: 'XP and level milestones');

  final String name;
  final String description;

  const AchievementCategory({
    required this.name,
    required this.description,
  });
}
