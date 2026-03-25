/// Leaderboard Model
/// Represents leaderboard entries and rankings

class LeaderboardEntry {
  final int rank;
  final LeaderboardUser user;
  final int xp;
  final int level;
  final int streak;
  final int? streakDays;      // For streak leaderboard
  final int? longestStreak;   // For longest streak
  final String? country;
  final String? nativeLanguage;
  final String? learningLanguage;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.xp,
    required this.level,
    this.streak = 0,
    this.streakDays,
    this.longestStreak,
    this.country,
    this.nativeLanguage,
    this.learningLanguage,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      user: json['user'] != null
          ? LeaderboardUser.fromJson(json['user'])
          : LeaderboardUser.empty(),
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streak: json['streak'] ?? 0,
      streakDays: json['streakDays'] as int?,
      longestStreak: json['longestStreak'] as int?,
      country: json['country'] as String?,
      nativeLanguage: json['nativeLanguage'] as String?,
      learningLanguage: json['learningLanguage'] as String?,
      isCurrentUser: json['isCurrentUser'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user': user.toJson(),
      'xp': xp,
      'level': level,
      'streak': streak,
      if (streakDays != null) 'streakDays': streakDays,
      if (longestStreak != null) 'longestStreak': longestStreak,
      if (country != null) 'country': country,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
      if (learningLanguage != null) 'learningLanguage': learningLanguage,
      'isCurrentUser': isCurrentUser,
    };
  }
}

class LeaderboardUser {
  final String id;
  final String name;
  final String? profilePicture;
  final LeaderboardLearningStats? learningStats;

  LeaderboardUser({
    required this.id,
    required this.name,
    this.profilePicture,
    this.learningStats,
  });

  /// Alias for name (for compatibility)
  String get username => name;

  /// Alias for profilePicture (for compatibility)
  String? get avatar => profilePicture;

  factory LeaderboardUser.empty() {
    return LeaderboardUser(id: '', name: 'Unknown');
  }

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? 'Unknown',
      profilePicture: json['profilePicture']?.toString() ?? json['avatar']?.toString(),
      learningStats: json['learningStats'] != null
          ? LeaderboardLearningStats.fromJson(json['learningStats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (learningStats != null) 'learningStats': learningStats!.toJson(),
    };
  }
}

class LeaderboardLearningStats {
  final int level;

  LeaderboardLearningStats({
    required this.level,
  });

  factory LeaderboardLearningStats.fromJson(Map<String, dynamic> json) {
    return LeaderboardLearningStats(
      level: json['level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
    };
  }
}

class UserPosition {
  final int rank;
  final int xp;
  final int level;

  UserPosition({
    required this.rank,
    required this.xp,
    required this.level,
  });

  factory UserPosition.fromJson(Map<String, dynamic> json) {
    return UserPosition(
      rank: json['rank'] ?? 0,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'xp': xp,
      'level': level,
    };
  }
}

/// Leaderboard response
class LeaderboardResponse {
  final List<LeaderboardEntry> leaderboard;
  final UserPosition? userPosition;
  final int total;

  LeaderboardResponse({
    required this.leaderboard,
    this.userPosition,
    required this.total,
  });

  /// Alias for leaderboard (for compatibility)
  List<LeaderboardEntry> get entries => leaderboard;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      leaderboard: (json['leaderboard'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e))
              .toList() ??
          [],
      userPosition: json['userPosition'] != null
          ? UserPosition.fromJson(json['userPosition'])
          : null,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      if (userPosition != null) 'userPosition': userPosition!.toJson(),
      'total': total,
    };
  }
}

/// Leaderboard filter
class LeaderboardFilter {
  final String type; // 'xp', 'streaks', 'friends', 'weekly', 'allTime'
  final String? period; // 'all', 'weekly', 'monthly'
  final String? streakType; // 'current', 'longest'
  final String? language;
  final int limit;
  final int page;

  const LeaderboardFilter({
    this.type = 'weekly',
    this.period,
    this.streakType,
    this.language,
    this.limit = 50,
    this.page = 1,
  });

  LeaderboardFilter copyWith({
    String? type,
    String? period,
    String? streakType,
    String? language,
    int? limit,
    int? page,
    bool clearPeriod = false,
    bool clearStreakType = false,
    bool clearLanguage = false,
  }) {
    return LeaderboardFilter(
      type: type ?? this.type,
      period: clearPeriod ? null : (period ?? this.period),
      streakType: clearStreakType ? null : (streakType ?? this.streakType),
      language: clearLanguage ? null : (language ?? this.language),
      limit: limit ?? this.limit,
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardFilter &&
        other.type == type &&
        other.period == period &&
        other.streakType == streakType &&
        other.language == language &&
        other.limit == limit &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(type, period, streakType, language, limit, page);
}

/// Leaderboard type
enum LeaderboardType {
  weekly(label: 'This Week', value: 'weekly'),
  allTime(label: 'All Time', value: 'allTime'),
  monthly(label: 'This Month', value: 'monthly');

  final String label;
  final String value;

  const LeaderboardType({
    required this.label,
    required this.value,
  });
}

/// Rank info for MyRanks
class RankInfo {
  final int rank;
  final int total;
  final int value;
  final String percentile;

  const RankInfo({
    required this.rank,
    required this.total,
    required this.value,
    required this.percentile,
  });

  factory RankInfo.fromJson(Map<String, dynamic> json) {
    return RankInfo(
      rank: json['rank'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      value: json['value'] as int? ?? 0,
      percentile: json['percentile']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'total': total,
      'value': value,
      'percentile': percentile,
    };
  }
}

/// Learning stats for MyRanks
class MyLearningStats {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int lessonsCompleted;
  final int vocabularyLearned;

  const MyLearningStats({
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.lessonsCompleted,
    required this.vocabularyLearned,
  });

  factory MyLearningStats.fromJson(Map<String, dynamic> json) {
    return MyLearningStats(
      totalXp: json['totalXp'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      vocabularyLearned: json['vocabularyLearned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXp': totalXp,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lessonsCompleted': lessonsCompleted,
      'vocabularyLearned': vocabularyLearned,
    };
  }
}

/// My ranks data
class MyRanksData {
  final RankInfo xp;
  final RankInfo streak;
  final MyLearningStats stats;

  const MyRanksData({
    required this.xp,
    required this.streak,
    required this.stats,
  });

  factory MyRanksData.fromJson(Map<String, dynamic> json) {
    return MyRanksData(
      xp: RankInfo.fromJson(json['xp'] ?? {}),
      streak: RankInfo.fromJson(json['streak'] ?? {}),
      stats: MyLearningStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xp': xp.toJson(),
      'streak': streak.toJson(),
      'stats': stats.toJson(),
    };
  }
}

/// My ranks response
class MyRanksResponse {
  final bool success;
  final MyRanksData data;

  const MyRanksResponse({
    required this.success,
    required this.data,
  });

  factory MyRanksResponse.fromJson(Map<String, dynamic> json) {
    return MyRanksResponse(
      success: json['success'] as bool? ?? false,
      data: MyRanksData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}
