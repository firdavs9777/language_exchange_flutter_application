import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// Every field the constructor demands, defaulted to something harmless, so a
/// test can name only the one or two fields it actually cares about.
Community buildCommunity({
  String id = 'u1',
  String name = 'Yeonwoo',
  String nativeLanguage = 'Korean',
  String languageToLearn = 'English',
  String? languageLevel,
  String bio = '',
  String birthYear = '1997',
  List<String> topics = const [],
  double? responseRate,
  String? createdAt,
  bool isOnline = false,
  bool vipSubscriptionActive = false,
  bool hasActiveStory = false,
  String city = 'Seoul',
  String country = 'South Korea',
  // Defaults to production behaviour (visible). A layout test sets this false
  // so the avatar does not open a live presence subscription that outlives the
  // test and throws "used after dispose" during teardown.
  bool showOnlineStatus = true,
}) {
  return Community(
    id: id,
    name: name,
    email: '$id@example.com',
    bio: bio,
    mbti: '',
    bloodType: '',
    images: const [],
    imageUrls: const [],
    birth_day: '1',
    birth_month: '1',
    birth_year: birthYear,
    gender: 'female',
    native_language: nativeLanguage,
    language_to_learn: languageToLearn,
    languageLevel: languageLevel,
    followers: const [],
    followings: const [],
    createdAt: createdAt ?? DateTime(2020, 1, 1).toIso8601String(),
    version: 0,
    topics: topics,
    responseRate: responseRate,
    isOnline: isOnline,
    vipSubscriptionActive: vipSubscriptionActive,
    hasActiveStory: hasActiveStory,
    privacySettings: PrivacySettings(showOnlineStatus: showOnlineStatus),
    location: Location(
      type: 'Point',
      coordinates: const [0, 0],
      formattedAddress: '$city, $country',
      street: '',
      city: city,
      state: '',
      zipcode: '',
      country: country,
    ),
  );
}
