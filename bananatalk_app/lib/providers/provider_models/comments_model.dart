import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class Comments {
  const Comments(
      {required this.id,
      required this.text,
      required this.user,
      // required this.moment,
      required this.createdAt,
      required this.version});

  final String id;
  final String text;
  final Community user;
  // final Moments moment;
  final DateTime createdAt;
  final int version;

  factory Comments.fromJson(Map<String, dynamic> json) {
    // Handle null, incomplete, or string ID user data gracefully
    Community user;
    
    // Check if user is a Map (populated object)
    if (json['user'] != null && json['user'] is Map) {
      try {
        user = Community.fromJson(json['user'] as Map<String, dynamic>);
      } catch (e) {
        // If user parsing fails, try to extract what we can
        print('Error parsing user in comment: $e');
        final userData = json['user'] as Map<String, dynamic>?;
        user = Community(
          id: userData?['_id']?.toString() ?? json['user']?['_id']?.toString() ?? '',
          name: userData?['name']?.toString() ?? 'Unknown User',
          email: userData?['email']?.toString() ?? '',
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
        );
      }
    } else if (json['user'] != null && json['user'] is String) {
      // User is just an ID string (not populated) - create minimal user
      user = Community(
        id: json['user'] as String,
        name: 'User',
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
      );
    } else {
      // Create default user if user is null or unknown type
      user = Community(
        id: '',
        name: 'Unknown User',
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
      );
    }

    return Comments(
        id: json['_id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        user: user,
        // moment: Moments.fromJson(json['moment']),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        version: json['__v'] is int ? json['__v'] : 0);
  }
}
