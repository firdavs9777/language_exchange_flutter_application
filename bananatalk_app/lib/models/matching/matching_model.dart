/// Matching Models
/// For smart partner matching and recommendations

/// Match location info
class MatchLocation {
  final String? city;
  final String? country;

  const MatchLocation({
    this.city,
    this.country,
  });

  factory MatchLocation.fromJson(Map<String, dynamic> json) {
    return MatchLocation(
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    };
  }

  String? get displayLocation {
    if (city != null && country != null) {
      return '$city, $country';
    }
    return city ?? country;
  }
}

/// Match recommendation model
class MatchRecommendation {
  final String odId;
  final String name;
  final String? username;
  final String? avatar;
  final List<String> images;
  final String nativeLanguage;
  final String languageToLearn;
  final int? level;
  final String? bio;
  final MatchLocation? location;
  final double matchScore;
  final List<String> matchReasons;
  final String? matchType; // 'perfect' or 'partial'
  final bool isOnline;
  final DateTime? lastActive;

  const MatchRecommendation({
    required this.odId,
    required this.name,
    this.username,
    this.avatar,
    this.images = const [],
    required this.nativeLanguage,
    required this.languageToLearn,
    this.level,
    this.bio,
    this.location,
    required this.matchScore,
    this.matchReasons = const [],
    this.matchType,
    this.isOnline = false,
    this.lastActive,
  });

  /// Check if this is a perfect language exchange match
  bool get isPerfectMatch => matchType == 'perfect';

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      odId: json['odId']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      images: (json['images'] as List?)?.cast<String>() ?? [],
      // Handle both camelCase and snake_case
      nativeLanguage: json['nativeLanguage']?.toString() ??
                      json['native_language']?.toString() ?? '',
      languageToLearn: json['languageToLearn']?.toString() ??
                       json['language_to_learn']?.toString() ?? '',
      level: json['level'] as int?,
      bio: json['bio'] as String?,
      location: json['location'] != null
          ? MatchLocation.fromJson(Map<String, dynamic>.from(json['location']))
          : null,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      matchReasons: (json['matchReasons'] as List?)?.cast<String>() ?? [],
      matchType: json['matchType'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'odId': odId,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      'images': images,
      'nativeLanguage': nativeLanguage,
      'languageToLearn': languageToLearn,
      if (level != null) 'level': level,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location!.toJson(),
      'matchScore': matchScore,
      'matchReasons': matchReasons,
      'isOnline': isOnline,
      if (lastActive != null) 'lastActive': lastActive!.toIso8601String(),
    };
  }

  /// Get match score as percentage string
  String get matchPercentage => '${(matchScore * 100).toInt()}%';

  /// Check if user was recently active
  bool get isRecentlyActive {
    if (lastActive == null) return false;
    final diff = DateTime.now().difference(lastActive!);
    return diff.inMinutes < 30;
  }
}

/// Matching response
class MatchingResponse {
  final bool success;
  final int count;
  final List<MatchRecommendation> data;
  final bool cached;

  const MatchingResponse({
    required this.success,
    required this.count,
    required this.data,
    this.cached = false,
  });

  factory MatchingResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'];
    List<MatchRecommendation> recommendations = [];

    if (dataList is List) {
      recommendations = dataList
          .map((e) => MatchRecommendation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return MatchingResponse(
      success: json['success'] as bool? ?? false,
      count: json['count'] as int? ?? recommendations.length,
      data: recommendations,
      cached: json['cached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'data': data.map((e) => e.toJson()).toList(),
      'cached': cached,
    };
  }
}

/// Matching filter
class MatchingFilter {
  final String? language;
  final int limit;
  final int offset;

  const MatchingFilter({
    this.language,
    this.limit = 20,
    this.offset = 0,
  });

  MatchingFilter copyWith({
    String? language,
    int? limit,
    int? offset,
    bool clearLanguage = false,
  }) {
    return MatchingFilter(
      language: clearLanguage ? null : (language ?? this.language),
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchingFilter &&
        other.language == language &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(language, limit, offset);
}
