import 'package:bananatalk_app/models/vip_subscription.dart';

// Category Object Blueprint
class User {
  const User({
    required this.name,
    required this.password,
    required this.email,
    required this.bio,
    required this.image,
    required this.birth_day,
    required this.birth_month,
    required this.gender,
    required this.birth_year,
    required this.native_language,
    required this.language_to_learn,
    this.userMode = UserMode.regular,
    this.vipSubscription,
    this.vipFeatures,
    this.visitorLimitations,
  });

  final String name;
  final String password;
  final String email;
  final String bio;
  final String image;
  final String gender;
  final String native_language;
  final String language_to_learn;
  final String birth_year;
  final String birth_month;
  final String birth_day;
  final UserMode userMode;
  final VipSubscription? vipSubscription;
  final VipFeatures? vipFeatures;
  final VisitorLimitations? visitorLimitations;

  bool get isVip => userMode == UserMode.vip;
  bool get isVisitor => userMode == UserMode.visitor;
  bool get isRegular => userMode == UserMode.regular;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'password': password,
      'email': email,
      'birth_year': birth_year,
      'birth_month': birth_month,
      'birth_day': birth_day,
      'image': image,
      'bio': bio,
      'gender': gender,
      'native_language': native_language,
      'language_to_learn': language_to_learn,
      'userMode': userMode.toJson(),
      'vipSubscription': vipSubscription?.toJson(),
      'vipFeatures': vipFeatures?.toJson(),
      'visitorLimitations': visitorLimitations?.toJson(),
    };
  }

  User copyWith({
    String? name,
    String? password,
    String? email,
    String? bio,
    String? image,
    String? birth_day,
    String? birth_month,
    String? gender,
    String? birth_year,
    String? native_language,
    String? language_to_learn,
    UserMode? userMode,
    VipSubscription? vipSubscription,
    VipFeatures? vipFeatures,
    VisitorLimitations? visitorLimitations,
  }) {
    return User(
      name: name ?? this.name,
      password: password ?? this.password,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      image: image ?? this.image,
      birth_day: birth_day ?? this.birth_day,
      birth_month: birth_month ?? this.birth_month,
      gender: gender ?? this.gender,
      birth_year: birth_year ?? this.birth_year,
      native_language: native_language ?? this.native_language,
      language_to_learn: language_to_learn ?? this.language_to_learn,
      userMode: userMode ?? this.userMode,
      vipSubscription: vipSubscription ?? this.vipSubscription,
      vipFeatures: vipFeatures ?? this.vipFeatures,
      visitorLimitations: visitorLimitations ?? this.visitorLimitations,
    );
  }
}
