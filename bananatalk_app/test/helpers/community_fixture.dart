import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

Community communityFixture({
  int daysOld = 1,
  String bio = '',
  List<String> imageUrls = const [],
  bool vip = false,
}) =>
    Community(
      id: 'me',
      appleId: '',
      googleId: '',
      name: 'Me',
      email: '',
      mbti: '',
      bloodType: '',
      bio: bio,
      images: const [],
      birth_day: '',
      birth_month: '',
      gender: '',
      birth_year: '',
      native_language: 'English',
      language_to_learn: 'Korean',
      imageUrls: imageUrls,
      createdAt:
          DateTime.now().subtract(Duration(days: daysOld)).toIso8601String(),
      version: 0,
      followers: const [],
      followings: const [],
      location: Location.defaultLocation(),
      userMode: vip ? UserMode.vip : UserMode.regular,
    );
