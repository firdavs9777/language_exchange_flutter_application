import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

import 'community_fixture.dart';

/// `Moments.user` is a [Community], so this delegates to [buildCommunity]
/// rather than duplicating twenty defaults.
Moments buildMoment({
  String id = 'm1',
  String userName = 'YGK',
  String nativeLanguage = 'Korean',
  String languageToLearn = 'English',
  String? languageLevel,
  String description = 'Hello there',
  String language = 'ko',
  int likeCount = 0,
  int commentCount = 0,
  List<String> images = const [],
  DateTime? createdAt,
}) {
  return Moments(
    id: id,
    user: buildCommunity(
      id: 'author-$id',
      name: userName,
      nativeLanguage: nativeLanguage,
      languageToLearn: languageToLearn,
      languageLevel: languageLevel,
      // Keeps the avatar from opening a live presence subscription that
      // outlives the test.
      showOnlineStatus: false,
    ),
    description: description,
    images: images,
    imageUrls: images,
    likeCount: likeCount,
    commentCount: commentCount,
    language: language,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 16)),
  );
}
