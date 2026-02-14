/// Leaderboard Model
/// Represents leaderboard entries and rankings

class LeaderboardEntry {
  final int rank;
  final LeaderboardUser user;
  final int xp;
  final int level;
  final int streak;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.xp,
    required this.level,
    this.streak = 0,
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
  final String type; // weekly, allTime
  final String? language;
  final int limit;
  final int page;

  LeaderboardFilter({
    this.type = 'weekly',
    this.language,
    this.limit = 50,
    this.page = 1,
  });

  LeaderboardFilter copyWith({
    String? type,
    String? language,
    int? limit,
    int? page,
  }) {
    return LeaderboardFilter(
      type: type ?? this.type,
      language: language ?? this.language,
      limit: limit ?? this.limit,
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardFilter &&
        other.type == type &&
        other.language == language &&
        other.limit == limit &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(type, language, limit, page);
}

/// Leaderboard type
enum LeaderboardType {
  weekly(label: 'This Week', value: 'weekly'),
  allTime(label: 'All Time', value: 'allTime');

  final String label;
  final String value;

  const LeaderboardType({
    required this.label,
    required this.value,
  });
}
