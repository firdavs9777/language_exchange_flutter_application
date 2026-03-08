import 'package:bananatalk_app/models/vip_subscription.dart';

class Community {
  const Community({
    required this.id,
    this.appleId,
    this.googleId,
    required this.name,
    this.username,
    required this.email,
    required this.bio,
    required this.mbti,
    required this.bloodType,
    required this.images,
    required this.birth_day,
    required this.birth_month,
    required this.gender,
    required this.birth_year,
    required this.native_language,
    required this.language_to_learn,
    required this.followers,
    required this.followings,
    required this.imageUrls,
    required this.createdAt,
    required this.version,
    required this.location,
    this.privacySettings,
    this.termsAccepted = false,
    // New HelloTalk-style fields
    this.topics = const [],
    this.languageLevel,
    this.responseRate,
    this.lastActive,
    this.isOnline = false,
    // VIP fields
    this.userMode = UserMode.regular,
    this.vipSubscriptionActive = false,
  });

  final String id;
  final String? appleId;
  final String? googleId;
  final String name;
  final String? username;
  final String gender;
  final String email;
  final String bio;
  final String mbti;
  final String bloodType;
  final List<String> images;
  final List<String> imageUrls;
  final List<String> followers;
  final List<String> followings;
  final String native_language;
  final String language_to_learn;
  final String birth_year;
  final String birth_month;
  final String birth_day;
  final String createdAt;
  final int version;
  final Location location;
  final PrivacySettings? privacySettings;
  final bool termsAccepted;
  // New HelloTalk-style fields
  final List<String> topics;
  final String? languageLevel; // A1, A2, B1, B2, C1, C2
  final double? responseRate; // 0-100
  final DateTime? lastActive;
  final bool isOnline;
  // VIP fields
  final UserMode userMode;
  final bool vipSubscriptionActive;

  /// Check if user is VIP (either userMode is vip OR vipSubscription.isActive is true)
  bool get isVip => userMode == UserMode.vip || vipSubscriptionActive;

  /// Get display username with @ prefix (e.g., @davis7x4k)
  String? get displayUsername => username != null ? '@$username' : null;

  /// Get effective image URLs - prefer imageUrls, fallback to images
  List<String> get effectiveImageUrls {
    if (imageUrls.isNotEmpty) {
      return imageUrls;
    }
    // Fallback to images array - include all non-empty URLs (relative or absolute)
    return images.where((url) => url.isNotEmpty).toList();
  }

  /// Get the first available profile image URL
  String? get profileImageUrl {
    final urls = effectiveImageUrls;
    if (urls.isEmpty) return null;

    final firstUrl = urls[0];
    // Return the URL - it will be normalized by ImageUtils when displayed
    return firstUrl.isNotEmpty ? firstUrl : null;
  }

  factory Community.fromJson(Map<String, dynamic> json) {
    // Debug: Print filter-relevant fields
    // Uncomment to debug filter issues:
    // debugPrint('Community.fromJson - ${json['name']}:');
    // debugPrint('  gender: ${json['gender']}');
    // debugPrint('  country: ${json['location']?['country']}');
    // debugPrint('  birth_year: ${json['birth_year']}');

    return Community(
      id: json['_id'] ?? '',
      googleId: json['googleId'],
      appleId: json['appleId'],
      name: json['name'] ?? '',
      username: json['username'],
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      images: (json['images'] != null
              ? List<String>.from(json['images'])
              : <String>[]) ??
          [],
      birth_day: json['birth_day'] ?? '',
      birth_month: json['birth_month'] ?? '',
      gender: json['gender'] ?? '',
      birth_year: json['birth_year'] ?? '',
      native_language: json['native_language'] ?? '',
      language_to_learn: json['language_to_learn'] ?? '',
      mbti: json['mbti'] ?? '',
      bloodType: json['bloodType'] ?? '',
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : Location.defaultLocation(),
      imageUrls: (json['imageUrls'] != null
              ? List<String>.from(json['imageUrls'])
                  .map((url) => url.toString())
                  .where((url) =>
                      url.isNotEmpty &&
                      !url.contains('placeholder') &&
                      !url.startsWith('placeholder_'))
                  .toList()
              : <String>[]) ??
          [],
      followers: (json['followers'] != null
              ? List<String>.from(json['followers'])
              : <String>[]) ??
          [],
      followings: (json['following'] != null
              ? List<String>.from(json['following'])
              : <String>[]) ??
          [],
      createdAt: json['createdAt'] ?? '',
      version: (json['__v'] as num?)?.toInt() ?? 0,
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(json['privacySettings'])
          : null,
      termsAccepted: json['termsAccepted'] ?? false,
      // New HelloTalk-style fields
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      languageLevel: json['languageLevel']?.toString(),
      responseRate: (json['responseRate'] as num?)?.toDouble(),
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'].toString())
          : null,
      isOnline: json['isOnline'] ?? false,
      // VIP fields
      userMode: UserMode.fromString(json['userMode'] ?? 'regular'),
      vipSubscriptionActive: json['vipSubscription']?['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'name': name,
      if (username != null) 'username': username,
      'email': email,
      'bio': bio,
      'images': images,
      'birth_day': birth_day,
      'birth_month': birth_month,
      'gender': gender,
      'birth_year': birth_year,
      'native_language': native_language,
      'language_to_learn': language_to_learn,
      'mbti': mbti,
      'bloodType': bloodType,
      'location': location.toJson(),
      'imageUrls': imageUrls,
      'followers': followers,
      'following': followings,
      'createdAt': createdAt,
      '__v': version,
      'privacySettings': privacySettings?.toJson(),
      // New HelloTalk-style fields
      'topics': topics,
      if (languageLevel != null) 'languageLevel': languageLevel,
      if (responseRate != null) 'responseRate': responseRate,
      if (lastActive != null) 'lastActive': lastActive!.toIso8601String(),
      'isOnline': isOnline,
      'userMode': userMode.toJson(),
      'vipSubscription': {'isActive': vipSubscriptionActive},
    };
  }

  /// Calculate age from birth date
  int? get age {
    try {
      final birthYear = int.tryParse(birth_year);
      if (birthYear == null) return null;
      final today = DateTime.now();
      int age = today.year - birthYear;
      final birthMonth = int.tryParse(birth_month);
      final birthDay = int.tryParse(birth_day);
      if (birthMonth != null && birthDay != null) {
        final birthday = DateTime(today.year, birthMonth, birthDay);
        if (today.isBefore(birthday)) age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  /// Get last active text (e.g., "Active 5m ago")
  String get lastActiveText {
    if (isOnline) return 'Online now';
    if (lastActive == null) return '';
    final duration = DateTime.now().difference(lastActive!);
    if (duration.inMinutes < 1) return 'Active just now';
    if (duration.inMinutes < 60) return 'Active ${duration.inMinutes}m ago';
    if (duration.inHours < 24) return 'Active ${duration.inHours}h ago';
    if (duration.inDays < 7) return 'Active ${duration.inDays}d ago';
    return 'Active ${duration.inDays ~/ 7}w ago';
  }

  /// Get language level color
  static String getLevelColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'A1':
      case 'A2':
        return '#4CAF50'; // Green - Beginner
      case 'B1':
      case 'B2':
        return '#FF9800'; // Orange - Intermediate
      case 'C1':
      case 'C2':
        return '#E91E63'; // Pink - Advanced
      default:
        return '#9E9E9E'; // Grey
    }
  }
}

class PrivacySettings {
  const PrivacySettings({
    this.showCountryRegion = true,
    this.showCity = true,
    this.showAge = false,
    this.showZodiac = true,
    this.showOnlineStatus = false,
    this.showGiftingLevel = true,
    this.birthdayNotification = true,
    this.personalizedAds = false,
  });

  final bool showCountryRegion;
  final bool showCity;
  final bool showAge;
  final bool showZodiac;
  final bool showOnlineStatus;
  final bool showGiftingLevel;
  final bool birthdayNotification;
  final bool personalizedAds;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showCountryRegion: json['showCountryRegion'] ?? true,
      showCity: json['showCity'] ?? true,
      showAge: json['showAge'] ?? false,
      showZodiac: json['showZodiac'] ?? true,
      showOnlineStatus: json['showOnlineStatus'] ?? false,
      showGiftingLevel: json['showGiftingLevel'] ?? true,
      birthdayNotification: json['birthdayNotification'] ?? true,
      personalizedAds: json['personalizedAds'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showCountryRegion': showCountryRegion,
      'showCity': showCity,
      'showAge': showAge,
      'showZodiac': showZodiac,
      'showOnlineStatus': showOnlineStatus,
      'showGiftingLevel': showGiftingLevel,
      'birthdayNotification': birthdayNotification,
      'personalizedAds': personalizedAds,
    };
  }

  PrivacySettings copyWith({
    bool? showCountryRegion,
    bool? showCity,
    bool? showAge,
    bool? showZodiac,
    bool? showOnlineStatus,
    bool? showGiftingLevel,
    bool? birthdayNotification,
    bool? personalizedAds,
  }) {
    return PrivacySettings(
      showCountryRegion: showCountryRegion ?? this.showCountryRegion,
      showCity: showCity ?? this.showCity,
      showAge: showAge ?? this.showAge,
      showZodiac: showZodiac ?? this.showZodiac,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showGiftingLevel: showGiftingLevel ?? this.showGiftingLevel,
      birthdayNotification: birthdayNotification ?? this.birthdayNotification,
      personalizedAds: personalizedAds ?? this.personalizedAds,
    );
  }
}

class Location {
  final String type;
  final List<double> coordinates;
  final String formattedAddress;
  final String street;
  final String city;
  final String state;
  final String zipcode;
  final String country;

  Location({
    required this.type,
    required this.coordinates,
    required this.formattedAddress,
    required this.street,
    required this.city,
    required this.state,
    required this.zipcode,
    required this.country,
  });
  factory Location.defaultLocation() {
    return Location(
      type: '', // Default type can be an empty string or some default type
      coordinates: [0.0, 0.0], // Default coordinates (latitude, longitude)
      formattedAddress: '',
      street: '',
      city: '',
      state: '',
      zipcode: '',
      country: '',
    );
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    // Convert coordinates to double, handling both int and double values
    List<double> coordinates = [];
    if (json['coordinates'] != null) {
      final coords = json['coordinates'] as List<dynamic>;
      coordinates = coords.map((e) => (e as num).toDouble()).toList();
    }

    return Location(
      type: json['type'] ?? '',
      coordinates: coordinates,
      formattedAddress: json['formattedAddress'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipcode: json['zipcode'] ?? '',
      country: json['country'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
      'formattedAddress': formattedAddress,
      'city': city,
      'country': country,
    };
  }
}
