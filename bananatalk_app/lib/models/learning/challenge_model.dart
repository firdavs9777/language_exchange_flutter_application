/// Challenge Model
/// Represents daily, weekly, and special challenges

class Challenge {
  final String id;
  final String title;
  final String description;
  final String type; // daily, weekly, special
  final String category;
  final ChallengeRequirement requirement;
  final int xpReward;
  final BonusReward? bonusReward;
  final String icon;
  final String difficulty; // easy, medium, hard
  final DateTime startsAt;
  final DateTime endsAt;
  final ChallengeProgress? userProgress;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.requirement,
    required this.xpReward,
    this.bonusReward,
    required this.icon,
    required this.difficulty,
    required this.startsAt,
    required this.endsAt,
    this.userProgress,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'daily',
      category: json['category']?.toString() ?? 'mixed',
      requirement: json['requirement'] != null
          ? ChallengeRequirement.fromJson(json['requirement'])
          : ChallengeRequirement.empty(),
      xpReward: json['xpReward'] ?? 0,
      bonusReward: json['bonusReward'] != null
          ? BonusReward.fromJson(json['bonusReward'])
          : null,
      icon: json['icon']?.toString() ?? 'star',
      difficulty: json['difficulty']?.toString() ?? 'easy',
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt']) ?? DateTime.now()
          : DateTime.now(),
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt']) ?? DateTime.now()
          : DateTime.now(),
      userProgress: json['userProgress'] != null
          ? ChallengeProgress.fromJson(json['userProgress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'requirement': requirement.toJson(),
      'xpReward': xpReward,
      if (bonusReward != null) 'bonusReward': bonusReward!.toJson(),
      'icon': icon,
      'difficulty': difficulty,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      if (userProgress != null) 'userProgress': userProgress!.toJson(),
    };
  }

  bool get isCompleted => userProgress?.completed ?? false;
  int get currentProgress => userProgress?.currentProgress ?? 0;
  double get progressPercentage => userProgress?.percentage ?? 0;

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endsAt)) return Duration.zero;
    return endsAt.difference(now);
  }

  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return 'Ending soon';
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'special':
        return 'Special';
      default:
        return type;
    }
  }
}

class ChallengeRequirement {
  final String type;
  final int value;

  ChallengeRequirement({
    required this.type,
    required this.value,
  });

  factory ChallengeRequirement.empty() {
    return ChallengeRequirement(type: '', value: 0);
  }

  factory ChallengeRequirement.fromJson(Map<String, dynamic> json) {
    return ChallengeRequirement(
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

class BonusReward {
  final String type;
  final int value;

  BonusReward({
    required this.type,
    required this.value,
  });

  factory BonusReward.fromJson(Map<String, dynamic> json) {
    return BonusReward(
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

  String get label {
    switch (type) {
      case 'streak_freeze':
        return '+$value Streak Freeze';
      case 'xp_boost':
        return '${value}x XP Boost';
      default:
        return '$value $type';
    }
  }
}

class ChallengeProgress {
  final int currentProgress;
  final bool completed;
  final double percentage;

  ChallengeProgress({
    required this.currentProgress,
    required this.completed,
    required this.percentage,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      currentProgress: json['currentProgress'] ?? 0,
      completed: json['completed'] ?? false,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentProgress': currentProgress,
      'completed': completed,
      'percentage': percentage,
    };
  }
}

/// Challenges response
class ChallengesResponse {
  final List<Challenge> daily;
  final List<Challenge> weekly;
  final List<Challenge> special;

  ChallengesResponse({
    required this.daily,
    required this.weekly,
    required this.special,
  });

  factory ChallengesResponse.fromJson(Map<String, dynamic> json) {
    return ChallengesResponse(
      daily: (json['daily'] as List<dynamic>?)
              ?.map((e) => Challenge.fromJson(e))
              .toList() ??
          [],
      weekly: (json['weekly'] as List<dynamic>?)
              ?.map((e) => Challenge.fromJson(e))
              .toList() ??
          [],
      special: (json['special'] as List<dynamic>?)
              ?.map((e) => Challenge.fromJson(e))
              .toList() ??
          [],
    );
  }

  List<Challenge> get all => [...daily, ...weekly, ...special];
  List<Challenge> get active => all.where((c) => c.isActive).toList();
  List<Challenge> get completed => all.where((c) => c.isCompleted).toList();
}

/// Challenge categories
enum ChallengeCategory {
  messaging(name: 'Messaging', description: 'Send messages'),
  vocabulary(name: 'Vocabulary', description: 'Add/review vocabulary'),
  lessons(name: 'Lessons', description: 'Complete lessons'),
  corrections(name: 'Corrections', description: 'Give/accept corrections'),
  social(name: 'Social', description: 'Talk to partners'),
  streak(name: 'Streak', description: 'Maintain streaks'),
  mixed(name: 'Mixed', description: 'Various activities');

  final String name;
  final String description;

  const ChallengeCategory({
    required this.name,
    required this.description,
  });
}
