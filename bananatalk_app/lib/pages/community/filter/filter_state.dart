class FilterState {
  final int minAge;
  final int maxAge;
  final String? gender;
  final String? nativeLanguage;
  final String? learningLanguage;
  final String? country;
  final List<String> topics;
  final String? languageLevel;
  final bool onlineOnly;
  final bool newUsersOnly;
  final bool prioritizeNearby;

  const FilterState({
    this.minAge = 18,
    this.maxAge = 100,
    this.gender,
    this.nativeLanguage,
    this.learningLanguage,
    this.country,
    this.topics = const [],
    this.languageLevel,
    this.onlineOnly = false,
    this.newUsersOnly = false,
    this.prioritizeNearby = false,
  });

  FilterState copyWith({
    int? minAge,
    int? maxAge,
    String? gender,
    String? nativeLanguage,
    String? learningLanguage,
    String? country,
    List<String>? topics,
    String? languageLevel,
    bool? onlineOnly,
    bool? newUsersOnly,
    bool? prioritizeNearby,
  }) =>
      FilterState(
        minAge: minAge ?? this.minAge,
        maxAge: maxAge ?? this.maxAge,
        gender: gender ?? this.gender,
        nativeLanguage: nativeLanguage ?? this.nativeLanguage,
        learningLanguage: learningLanguage ?? this.learningLanguage,
        country: country ?? this.country,
        topics: topics ?? this.topics,
        languageLevel: languageLevel ?? this.languageLevel,
        onlineOnly: onlineOnly ?? this.onlineOnly,
        newUsersOnly: newUsersOnly ?? this.newUsersOnly,
        prioritizeNearby: prioritizeNearby ?? this.prioritizeNearby,
      );

  Map<String, dynamic> toJson() => {
        'minAge': minAge,
        'maxAge': maxAge,
        'gender': gender,
        'nativeLanguage': nativeLanguage,
        'learningLanguage': learningLanguage,
        'country': country,
        'topics': topics,
        'languageLevel': languageLevel,
        'onlineOnly': onlineOnly,
        'newUsersOnly': newUsersOnly,
        'prioritizeNearby': prioritizeNearby,
      };

  /// Backwards-compat reader for the old `Map<String, dynamic>` shape stored
  /// under SharedPreferences key `community_filters`.
  factory FilterState.fromJson(Map<String, dynamic> json) => FilterState(
        minAge: (json['minAge'] as num?)?.toInt() ?? 18,
        maxAge: (json['maxAge'] as num?)?.toInt() ?? 100,
        gender: json['gender'] as String?,
        nativeLanguage: json['nativeLanguage'] as String?,
        learningLanguage: json['learningLanguage'] as String?,
        country: json['country'] as String?,
        topics: List<String>.from(json['topics'] ?? const []),
        languageLevel: json['languageLevel'] as String?,
        onlineOnly: json['onlineOnly'] as bool? ?? false,
        newUsersOnly: json['newUsersOnly'] as bool? ?? false,
        prioritizeNearby: json['prioritizeNearby'] as bool? ?? false,
      );

  static const FilterState defaults = FilterState();
}
