import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart' show CommentReaction, CommentMention;

class Comments {
  const Comments({
    required this.id,
    required this.text,
    required this.user,
    required this.createdAt,
    required this.version,
    this.translations = const [],
    this.likedUsers = const [],
    this.likeCount = 0,
    this.replyCount = 0,
    this.isEdited = false,
    this.parentComment,
    this.imageUrl,
    this.reactions = const [],
    this.reactionCount = 0,
    this.mentions = const [],
  });

  final String id;
  final String text;
  final Community user;
  final DateTime createdAt;
  final int version;
  final List<MessageTranslation> translations;
  final List<String> likedUsers;
  final int likeCount;
  final int replyCount;
  final bool isEdited;
  final String? parentComment;
  final String? imageUrl;
  final List<CommentReaction> reactions;
  final int reactionCount;
  final List<CommentMention> mentions;

  factory Comments.fromJson(Map<String, dynamic> json) {
    // Handle null, incomplete, or string ID user data gracefully
    Community user;

    // Check if user is a Map (populated object)
    if (json['user'] != null && json['user'] is Map) {
      try {
        user = Community.fromJson(json['user'] as Map<String, dynamic>);
      } catch (e) {
        // If user parsing fails, try to extract what we can
        final userData = json['user'] as Map<String, dynamic>?;
        user = Community(
          id: userData?['_id']?.toString() ??
              json['user']?['_id']?.toString() ??
              '',
          appleId: userData?['appleId']?.toString() ??
              json['user']?['appleId']?.toString() ??
              '',
          googleId: userData?['googleId']?.toString() ??
              json['user']?['googleId']?.toString() ??
              '',
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
        appleId: '',
        googleId: '',
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
        appleId: '',
        googleId: '',
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
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        version: json['__v'] is int ? json['__v'] : 0,
        translations: json['translations'] != null && json['translations'] is List
            ? (json['translations'] as List)
                .where((t) => t != null && t is Map<String, dynamic>)
                .map((t) => MessageTranslation.fromJson(t))
                .toList()
            : [],
        likedUsers: json['likedUsers'] != null && json['likedUsers'] is List
            ? (json['likedUsers'] as List)
                .map((e) => e.toString())
                .toList()
            : [],
        likeCount: json['likeCount'] is int ? json['likeCount'] : 0,
        replyCount: json['replyCount'] is int ? json['replyCount'] : 0,
        isEdited: json['isEdited'] == true,
        parentComment: json['parentComment']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
        reactions: json['reactions'] != null && json['reactions'] is List
            ? (json['reactions'] as List)
                .where((r) => r != null && r is Map<String, dynamic>)
                .map((r) => CommentReaction.fromJson(r))
                .toList()
            : [],
        reactionCount: json['reactionCount'] is int ? json['reactionCount'] : 0,
        mentions: json['mentions'] != null && json['mentions'] is List
            ? (json['mentions'] as List)
                .where((m) => m != null && m is Map<String, dynamic>)
                .map((m) => CommentMention.fromJson(m))
                .toList()
            : [],
    );
  }
}
