import 'package:bananatalk_app/providers/provider_models/community_model.dart';

class Moments {
  const Moments({
    required this.id,
    required this.title,
    required this.user,
    required this.description,
    required this.images,
    required this.createdAt,
    required this.imageUrls,
    this.likedUsers,
    this.comments,
    required this.likeCount,
    required this.commentCount,
    // New fields with safe defaults
    this.language = 'en',
    this.category = 'general',
    this.privacy = 'public', // ✅ Fixed
    this.mood = '',
    this.tags = const [], // ✅ Fixed
    this.scheduledFor,
  });

  final String id;
  final String title;
  final Community user;
  final String description;
  final List<String> images;
  final List<String>? likedUsers;
  final List<Comment>? comments;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  // New fields
  final String language; // ISO 639-1 code (e.g., 'en', 'ko', 'es')
  final String category; // e.g., 'language-learning', 'travel'
  final String privacy; // 'public', 'friends', 'private'
  final String mood; // e.g., 'happy', 'sad', 'excited' (can be empty)
  final List<String> tags; // e.g., ['korean', 'study']
  final DateTime? scheduledFor; // Optional scheduled date

  factory Moments.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get string with default
    String safeString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString().isEmpty ? defaultValue : value.toString();
    }

    // Helper function to safely get list
    List<String> safeList(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      return value
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toList();
    }

    return Moments(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      user: json['user'] != null
          ? Community.fromJson(json['user'])
          : Community(
              id: '',
              name: '',
              email: '',
              mbti: '',
              bloodType: '',
              bio: '',
              images: [''],
              birth_day: '',
              birth_month: '',
              gender: '',
              birth_year: '',
              native_language: '',
              language_to_learn: '',
              imageUrls: [''],
              createdAt: '',
              version: 0,
              followers: [''],
              followings: [''],
              location: Location.defaultLocation(),
            ),
      description: json['description']?.toString() ?? '',
      images: safeList(json['images']),
      imageUrls: safeList(json['imageUrls']),

      likeCount: json['likeCount'] is int ? json['likeCount'] : 0,
      commentCount: json['commentCount'] is int ? json['commentCount'] : 0,
      likedUsers:
          json['likedUsers'] != null ? safeList(json['likedUsers']) : null,
      comments: json['comments'] != null
          ? (json['comments'] as List<dynamic>)
              .expand((innerList) => List.from(innerList))
              .map((x) => Comment.fromJson(x as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),

      // Parse new fields with safe defaults
      language: safeString(json['language'], 'en'),
      category: safeString(json['category'], 'general'),
      privacy: safeString(json['privacy'], 'public'),
      mood: safeString(json['mood'], ''),
      tags: safeList(json['tags']),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.tryParse(json['scheduledFor'].toString())
          : null,
    );
  }

  // Add toJson method for completeness
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'images': images,
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedUsers': likedUsers,
      'createdAt': createdAt.toIso8601String(),
      'language': language,
      'category': category,
      'privacy': privacy,
      if (mood.isNotEmpty) 'mood': mood,
      if (tags.isNotEmpty) 'tags': tags,
      if (scheduledFor != null) 'scheduledFor': scheduledFor!.toIso8601String(),
    };
  }
}

class Comment {
  const Comment({
    required this.text,
    required this.userId,
    required this.momentId,
    required this.createdAt,
  });

  final String text;
  final String userId;
  final String momentId;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      text: json['text']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      momentId: json['moment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'user': userId,
      'moment': momentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
