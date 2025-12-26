class Community {
  const Community({
    required this.id,
    this.appleId,
    this.googleId,
    required this.name,
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
    required this.location, // Added location
    this.privacySettings,
    this.termsAccepted = false, // Terms of Service acceptance
  });

  final String id;
  final String? appleId;
  final String? googleId;
  final String name;
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
  final Location location; // Made location nullable here
  final PrivacySettings? privacySettings;
  final bool termsAccepted; // Terms of Service acceptance status

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['_id'] ?? '',
      googleId: json['googleId'],
      appleId: json['appleId'],
      name: json['name'] ?? '',
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
          : Location.defaultLocation(), // Ensure location is not null
      imageUrls: (json['imageUrls'] != null
              ? List<String>.from(json['imageUrls'])
                  .map((url) => url.toString())
                  .where((url) =>
                      url.isNotEmpty &&
                      !url.contains(
                          'placeholder') && // Filter out placeholder images
                      !url.startsWith(
                          'placeholder_')) // Filter out placeholder_ prefix
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
      version: json['__v'] ?? 0,
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(json['privacySettings'])
          : null,
      termsAccepted: json['termsAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'name': name,
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
    };
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
