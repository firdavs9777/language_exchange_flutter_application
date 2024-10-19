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
  final List<String>? comments;
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
              followings: ['']),
      description: json['description'] ?? '',
      images: List<String>.from(json['images']),
      imageUrls: List<String>.from(json['imageUrls']),
      // Handle null case for followings
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0, // Default to 0 if null
      likedUsers: json['likedUsers'] != null
          ? List<String>.from(json['likedUsers'])
          : null,
      // comments: json['comments'] != null
      //     ? List<String>.from(json['comments'])
      //     : null, // Handle null case for likedUsers
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
