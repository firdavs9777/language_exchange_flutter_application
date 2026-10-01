import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// One recommended partner from `GET matching/daily`.
class DailyMatch {
  const DailyMatch({
    required this.user,
    this.matchReasons = const [],
    this.reciprocal = false,
    this.lastActiveBucket,
    this.responseRate,
  });

  final Community user;
  final List<String> matchReasons;
  final bool reciprocal;
  final String? lastActiveBucket;
  final double? responseRate;

  factory DailyMatch.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final rawReasons = json['matchReasons'];
    final rawBucket = json['lastActiveBucket'];
    return DailyMatch(
      user: rawUser is Map<String, dynamic>
          ? Community.fromJson(rawUser)
          : Community(
              id: rawUser?.toString() ?? '',
              appleId: '',
              googleId: '',
              // Non-empty so a degenerate row never renders a blank name.
              name: 'BananaTalk user',
              email: '',
              mbti: '',
              bloodType: '',
              bio: '',
              images: [],
              birth_day: '',
              birth_month: '',
              gender: '',
              birth_year: '',
              native_language: '',
              language_to_learn: '',
              imageUrls: [],
              createdAt: '',
              version: 0,
              followers: [],
              followings: [],
              location: Location.defaultLocation(),
            ),
      matchReasons:
          rawReasons is List ? rawReasons.whereType<String>().toList() : const [],
      reciprocal: json['reciprocal'] == true,
      lastActiveBucket: rawBucket is String ? rawBucket : null,
      responseRate: (json['responseRate'] as num?)?.toDouble(),
    );
  }
}

class DailyMatchesResult {
  const DailyMatchesResult({
    this.nextRefreshAt,
    this.matches = const [],
    this.unavailable = false,
  });

  final DateTime? nextRefreshAt;
  final List<DailyMatch> matches;

  /// True when the endpoint is off (kill switch 404) or failed; the tab
  /// hides itself instead of showing an error.
  final bool unavailable;

  static const empty = DailyMatchesResult();
  static const unavailableResult = DailyMatchesResult(unavailable: true);

  factory DailyMatchesResult.fromJson(Map<String, dynamic> json) {
    final raw = json['matches'];
    final next = json['nextRefreshAt'];
    return DailyMatchesResult(
      nextRefreshAt: next == null ? null : DateTime.tryParse(next.toString()),
      matches: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(DailyMatch.fromJson)
              .toList()
          : const [],
    );
  }
}
