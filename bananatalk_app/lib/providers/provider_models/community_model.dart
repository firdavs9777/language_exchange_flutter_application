class Community {
  const Community({
    required this.id,
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
  });

  final String id;
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

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['_id'] ?? '',
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
// Mapping location field
      imageUrls: (json['imageUrls'] != null
              ? List<String>.from(json['imageUrls'])
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
    return Location(
      type: json['type'] ?? '',
      coordinates: List<double>.from(json['coordinates'] ?? []),
      formattedAddress: json['formattedAddress'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipcode: json['zipcode'] ?? '',
      country: json['country'] ?? '',
    );
  }
}
