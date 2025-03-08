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
  });

  final String id;
  final String title;
  final Community user;
  final String description;
  final List<String> images;
  final List<String>? likedUsers;
  final List<Comment>? comments; // Changed to handle Comment type inline
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  factory Moments.fromJson(Map<String, dynamic> json) {
    return Moments(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
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
      description: json['description'] ?? '',
      images: List<String>.from(json['images']),
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'].whereType<String>())
          : [],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      likedUsers: json['likedUsers'] != null
          ? List<String>.from(json['likedUsers'])
          : null,
      comments: json['comments'] != null
          ? (json['comments'] as List<dynamic>) // Cast to List<dynamic>
              .expand((innerList) =>
                  List.from(innerList)) // Flatten the nested lists
              .map((x) => Comment.fromJson(
                  x as Map<String, dynamic>)) // Convert to Comment objects
              .toList()
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
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
      text: json['text'] ?? '',
      userId: json['user'] ?? '',
      momentId: json['moment'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? '1970-01-01T00:00:00.000Z'),
    );
  }
}
