import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Video data for moment
class MomentVideo {
  final String url;
  final String? thumbnail;
  final int? duration; // in seconds
  final int? width;
  final int? height;
  final String? mimeType;
  final int? fileSize;

  const MomentVideo({
    required this.url,
    this.thumbnail,
    this.duration,
    this.width,
    this.height,
    this.mimeType,
    this.fileSize,
  });

  factory MomentVideo.fromJson(Map<String, dynamic> json) {
    return MomentVideo(
      url: json['url']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      duration: json['duration'] is int ? json['duration'] : null,
      width: json['width'] is int ? json['width'] : null,
      height: json['height'] is int ? json['height'] : null,
      mimeType: json['mimeType']?.toString(),
      fileSize: json['fileSize'] is int ? json['fileSize'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (duration != null) 'duration': duration,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (mimeType != null) 'mimeType': mimeType,
      if (fileSize != null) 'fileSize': fileSize,
    };
  }

  /// Format duration as mm:ss
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

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
    this.privacy = 'public',
    this.mood = '',
    this.tags = const [],
    this.scheduledFor,
    // Save/Bookmark fields
    this.savedBy = const [],
    this.saveCount = 0,
    this.shareCount = 0,
    this.isSaved = false,
    // Soft delete fields
    this.isDeleted = false,
    this.deletedAt,
    // Translation fields
    this.translations = const [],
    // Video fields
    this.video,
    this.mediaType = 'image',
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

  // Save/Bookmark fields
  final List<String> savedBy; // User IDs who saved this moment
  final int saveCount; // Total saves
  final int shareCount; // Total shares
  final bool isSaved; // True if current user saved it

  // Soft delete fields
  final bool isDeleted;
  final DateTime? deletedAt;

  // Translation fields
  final List<MessageTranslation> translations;

  // Video fields
  final MomentVideo? video;
  final String mediaType; // 'image', 'video', 'text'

  /// Check if this moment has a video
  bool get hasVideo => video != null && video!.url.isNotEmpty;

  /// Check if this moment has images
  bool get hasImages => imageUrls.isNotEmpty;

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
              appleId: '',
              googleId: '',
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

      // Save/Bookmark fields
      savedBy: safeList(json['savedBy']),
      saveCount: json['saveCount'] is int ? json['saveCount'] : 0,
      shareCount: json['shareCount'] is int ? json['shareCount'] : 0,
      isSaved: json['isSaved'] == true,

      // Soft delete fields
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,

      // Translation fields
      translations: json['translations'] != null && json['translations'] is List
          ? (json['translations'] as List)
              .where((t) => t != null && t is Map<String, dynamic>)
              .map((t) => MessageTranslation.fromJson(t))
              .toList()
          : [],

      // Video fields
      video: json['video'] != null && json['video'] is Map<String, dynamic>
          ? MomentVideo.fromJson(json['video'])
          : null,
      mediaType: safeString(json['mediaType'], 'image'),
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
      'savedBy': savedBy,
      'saveCount': saveCount,
      'shareCount': shareCount,
      'isSaved': isSaved,
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (video != null) 'video': video!.toJson(),
      'mediaType': mediaType,
    };
  }

  /// Create a copy with updated fields
  Moments copyWith({
    String? id,
    String? title,
    Community? user,
    String? description,
    List<String>? images,
    List<String>? imageUrls,
    int? likeCount,
    int? commentCount,
    List<String>? likedUsers,
    List<Comment>? comments,
    DateTime? createdAt,
    String? language,
    String? category,
    String? privacy,
    String? mood,
    List<String>? tags,
    DateTime? scheduledFor,
    List<String>? savedBy,
    int? saveCount,
    int? shareCount,
    bool? isSaved,
    bool? isDeleted,
    DateTime? deletedAt,
    List<MessageTranslation>? translations,
    MomentVideo? video,
    String? mediaType,
  }) {
    return Moments(
      id: id ?? this.id,
      title: title ?? this.title,
      user: user ?? this.user,
      description: description ?? this.description,
      images: images ?? this.images,
      imageUrls: imageUrls ?? this.imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedUsers: likedUsers ?? this.likedUsers,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
      category: category ?? this.category,
      privacy: privacy ?? this.privacy,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      savedBy: savedBy ?? this.savedBy,
      saveCount: saveCount ?? this.saveCount,
      shareCount: shareCount ?? this.shareCount,
      isSaved: isSaved ?? this.isSaved,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      translations: translations ?? this.translations,
      video: video ?? this.video,
      mediaType: mediaType ?? this.mediaType,
    );
  }
}

class Comment {
  const Comment({
    required this.id,
    required this.text,
    required this.user,
    required this.momentId,
    required this.createdAt,
    this.translations = const [],
  });

  final String id;
  final String text;
  final Community user;
  final String momentId;
  final DateTime createdAt;
  final List<MessageTranslation> translations;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic>
          ? Community.fromJson(json['user'])
          : Community(
              id: json['user']?.toString() ?? '',
              appleId: '',
              googleId: '',
              name: '',
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
            ),
      momentId: json['moment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      translations: json['translations'] != null && json['translations'] is List
          ? (json['translations'] as List)
              .where((t) => t != null && t is Map<String, dynamic>)
              .map((t) => MessageTranslation.fromJson(t))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'user': user.toJson(),
      'moment': momentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Response wrapper for moments API calls that may return blocked content
class MomentsResponse {
  final bool success;
  final int count;
  final int totalMoments;
  final List<Moments> data;
  final bool blocked;
  final String? message;
  final String? error;

  MomentsResponse({
    required this.success,
    this.count = 0,
    this.totalMoments = 0,
    this.data = const [],
    this.blocked = false,
    this.message,
    this.error,
  });

  factory MomentsResponse.fromJson(Map<String, dynamic> json) {
    return MomentsResponse(
      success: json['success'] == true,
      count: json['count'] ?? 0,
      totalMoments: json['totalMoments'] ?? json['count'] ?? 0,
      data: json['data'] != null
          ? (json['data'] as List).map((m) => Moments.fromJson(m)).toList()
          : [],
      blocked: json['blocked'] == true,
      message: json['message'],
      error: json['error'],
    );
  }

  bool get isBlocked => blocked;
  bool get isEmpty => data.isEmpty;
}

/// Report reasons for moments
enum MomentReportReason {
  spam,
  inappropriate,
  harassment,
  hateSpeech,
  violence,
  misinformation,
  other;

  String get value {
    switch (this) {
      case MomentReportReason.spam:
        return 'spam';
      case MomentReportReason.inappropriate:
        return 'inappropriate';
      case MomentReportReason.harassment:
        return 'harassment';
      case MomentReportReason.hateSpeech:
        return 'hate_speech';
      case MomentReportReason.violence:
        return 'violence';
      case MomentReportReason.misinformation:
        return 'misinformation';
      case MomentReportReason.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case MomentReportReason.spam:
        return 'Spam';
      case MomentReportReason.inappropriate:
        return 'Inappropriate content';
      case MomentReportReason.harassment:
        return 'Harassment';
      case MomentReportReason.hateSpeech:
        return 'Hate speech';
      case MomentReportReason.violence:
        return 'Violence';
      case MomentReportReason.misinformation:
        return 'Misinformation';
      case MomentReportReason.other:
        return 'Other';
    }
  }
}

/// Moment categories for explore/discover
class MomentCategory {
  static const String general = 'general';
  static const String languageLearning = 'language-learning';
  static const String culture = 'culture';
  static const String food = 'food';
  static const String travel = 'travel';
  static const String music = 'music';
  static const String books = 'books';
  static const String hobbies = 'hobbies';

  static List<Map<String, String>> get all => [
        {'value': general, 'label': 'General', 'icon': '🌐'},
        {'value': languageLearning, 'label': 'Language Learning', 'icon': '📚'},
        {'value': culture, 'label': 'Culture', 'icon': '🎭'},
        {'value': food, 'label': 'Food', 'icon': '🍜'},
        {'value': travel, 'label': 'Travel', 'icon': '✈️'},
        {'value': music, 'label': 'Music', 'icon': '🎵'},
        {'value': books, 'label': 'Books', 'icon': '📖'},
        {'value': hobbies, 'label': 'Hobbies', 'icon': '🎨'},
      ];
}

/// Mood options for moments
class MomentMood {
  static const String happy = 'happy';
  static const String excited = 'excited';
  static const String grateful = 'grateful';
  static const String motivated = 'motivated';
  static const String relaxed = 'relaxed';
  static const String curious = 'curious';

  static List<Map<String, String>> get all => [
        {'value': happy, 'label': 'Happy', 'emoji': '😊'},
        {'value': excited, 'label': 'Excited', 'emoji': '🤩'},
        {'value': grateful, 'label': 'Grateful', 'emoji': '🙏'},
        {'value': motivated, 'label': 'Motivated', 'emoji': '💪'},
        {'value': relaxed, 'label': 'Relaxed', 'emoji': '😌'},
        {'value': curious, 'label': 'Curious', 'emoji': '🤔'},
      ];
}

/// Explore/Discover filter options
class MomentsExploreFilter {
  final String? category;
  final String? language;
  final String? mood;
  final List<String>? tags;
  final int page;
  final int limit;

  MomentsExploreFilter({
    this.category,
    this.language,
    this.mood,
    this.tags,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (category != null && category!.isNotEmpty) 'category': category,
      if (language != null && language!.isNotEmpty) 'language': language,
      if (mood != null && mood!.isNotEmpty) 'mood': mood,
      if (tags != null && tags!.isNotEmpty) 'tags': tags!.join(','),
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }

  MomentsExploreFilter copyWith({
    String? category,
    String? language,
    String? mood,
    List<String>? tags,
    int? page,
    int? limit,
  }) {
    return MomentsExploreFilter(
      category: category ?? this.category,
      language: language ?? this.language,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}
