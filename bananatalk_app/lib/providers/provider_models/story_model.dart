import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// Story model representing a single story with all features
class Story {
  final String id;
  final Community user;
  
  // Media
  final String mediaUrl;
  final List<String> mediaUrls;
  final String mediaType; // 'image', 'video', 'text'
  
  // Text story
  final String? text;
  final String backgroundColor;
  final String textColor;
  final String fontStyle; // 'normal', 'bold', 'italic', 'handwriting'
  
  // Privacy
  final StoryPrivacy privacy;
  
  // Views
  final List<StoryView> views;
  final int viewCount;
  
  // Reactions
  final List<StoryReaction> reactions;
  final int reactionCount;
  final String? userReaction; // Current user's reaction
  
  // Replies
  final int replyCount;
  
  // Mentions
  final List<StoryMention> mentions;
  
  // Location
  final StoryLocation? location;
  
  // Link sticker
  final StoryLink? link;
  
  // Poll
  final StoryPoll? poll;
  
  // Question box
  final StoryQuestionBox? questionBox;
  
  // Music
  final StoryMusic? music;
  
  // Hashtags
  final List<String> hashtags;
  
  // Highlight reference
  final String? highlightId;
  
  // Archive
  final bool isArchived;
  final DateTime? archivedAt;
  
  // Shares
  final int shareCount;
  
  // Settings
  final bool allowReplies;
  final bool allowSharing;
  
  // Status
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;

  const Story({
    required this.id,
    required this.user,
    required this.mediaUrl,
    this.mediaUrls = const [],
    required this.mediaType,
    this.text,
    this.backgroundColor = '#000000',
    this.textColor = '#FFFFFF',
    this.fontStyle = 'normal',
    this.privacy = StoryPrivacy.everyone,
    this.views = const [],
    this.viewCount = 0,
    this.reactions = const [],
    this.reactionCount = 0,
    this.userReaction,
    this.replyCount = 0,
    this.mentions = const [],
    this.location,
    this.link,
    this.poll,
    this.questionBox,
    this.music,
    this.hashtags = const [],
    this.highlightId,
    this.isArchived = false,
    this.archivedAt,
    this.shareCount = 0,
    this.allowReplies = true,
    this.allowSharing = true,
    this.isActive = true,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['_id']?.toString() ?? '',
      user: json['user'] != null
          ? Community.fromJson(json['user'])
          : _defaultUser(),
      mediaUrl: json['mediaUrl']?.toString() ?? json['media']?.toString() ?? '',
      mediaUrls: json['mediaUrls'] != null
          ? (json['mediaUrls'] as List).map((e) => e.toString()).toList()
          : [],
      mediaType: json['mediaType']?.toString() ?? 'image',
      text: json['text']?.toString(),
      backgroundColor: json['backgroundColor']?.toString() ?? '#000000',
      textColor: json['textColor']?.toString() ?? '#FFFFFF',
      fontStyle: json['fontStyle']?.toString() ?? 'normal',
      privacy: StoryPrivacy.fromString(json['privacy']?.toString()),
      views: json['views'] != null
          ? (json['views'] as List).map((v) => StoryView.fromJson(v)).toList()
          : [],
      viewCount: json['viewCount'] ?? json['views']?.length ?? 0,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List).map((r) => StoryReaction.fromJson(r)).toList()
          : [],
      reactionCount: json['reactionCount'] ?? json['reactions']?.length ?? 0,
      userReaction: json['userReaction']?.toString(),
      replyCount: json['replyCount'] ?? 0,
      mentions: json['mentions'] != null
          ? (json['mentions'] as List).map((m) => StoryMention.fromJson(m)).toList()
          : [],
      location: json['location'] != null ? StoryLocation.fromJson(json['location']) : null,
      link: json['link'] != null ? StoryLink.fromJson(json['link']) : null,
      poll: json['poll'] != null ? StoryPoll.fromJson(json['poll']) : null,
      questionBox: json['questionBox'] != null ? StoryQuestionBox.fromJson(json['questionBox']) : null,
      music: json['music'] != null ? StoryMusic.fromJson(json['music']) : null,
      hashtags: json['hashtags'] != null
          ? (json['hashtags'] as List).map((h) => h.toString()).toList()
          : [],
      highlightId: json['highlight']?.toString(),
      isArchived: json['isArchived'] == true,
      archivedAt: json['archivedAt'] != null
          ? DateTime.tryParse(json['archivedAt'].toString())
          : null,
      shareCount: json['shareCount'] ?? 0,
      allowReplies: json['allowReplies'] != false,
      allowSharing: json['allowSharing'] != false,
      isActive: json['isActive'] != false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString()) ?? DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static Community _defaultUser() => Community(
    id: '', appleId: '', googleId: '', name: '', email: '',
    mbti: '', bloodType: '', bio: '', images: [], birth_day: '',
    birth_month: '', gender: '', birth_year: '', native_language: '',
    language_to_learn: '', imageUrls: [], createdAt: '', version: 0,
    followers: [], followings: [], location: Location.defaultLocation(),
  );

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user.toJson(),
      'mediaUrl': mediaUrl,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType,
      'text': text,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontStyle': fontStyle,
      'privacy': privacy.value,
      'viewCount': viewCount,
      'reactionCount': reactionCount,
      'userReaction': userReaction,
      'replyCount': replyCount,
      'mentions': mentions.map((m) => m.toJson()).toList(),
      'location': location?.toJson(),
      'link': link?.toJson(),
      'poll': poll?.toJson(),
      'questionBox': questionBox?.toJson(),
      'music': music?.toJson(),
      'hashtags': hashtags,
      'highlight': highlightId,
      'isArchived': isArchived,
      'archivedAt': archivedAt?.toIso8601String(),
      'shareCount': shareCount,
      'allowReplies': allowReplies,
      'allowSharing': allowSharing,
      'isActive': isActive,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool hasViewed(String userId) => views.any((v) => v.userId == userId);
  
  Duration get remainingTime {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return Duration.zero;
    return expiresAt.difference(now);
  }
  
  bool get isStillActive => isActive && !isArchived && expiresAt.isAfter(DateTime.now());

  Story copyWith({
    String? id,
    Community? user,
    String? mediaUrl,
    List<String>? mediaUrls,
    String? mediaType,
    String? text,
    String? backgroundColor,
    String? textColor,
    String? fontStyle,
    StoryPrivacy? privacy,
    List<StoryView>? views,
    int? viewCount,
    List<StoryReaction>? reactions,
    int? reactionCount,
    String? userReaction,
    int? replyCount,
    List<StoryMention>? mentions,
    StoryLocation? location,
    StoryLink? link,
    StoryPoll? poll,
    StoryQuestionBox? questionBox,
    StoryMusic? music,
    List<String>? hashtags,
    String? highlightId,
    bool? isArchived,
    DateTime? archivedAt,
    int? shareCount,
    bool? allowReplies,
    bool? allowSharing,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      user: user ?? this.user,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      text: text ?? this.text,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontStyle: fontStyle ?? this.fontStyle,
      privacy: privacy ?? this.privacy,
      views: views ?? this.views,
      viewCount: viewCount ?? this.viewCount,
      reactions: reactions ?? this.reactions,
      reactionCount: reactionCount ?? this.reactionCount,
      userReaction: userReaction ?? this.userReaction,
      replyCount: replyCount ?? this.replyCount,
      mentions: mentions ?? this.mentions,
      location: location ?? this.location,
      link: link ?? this.link,
      poll: poll ?? this.poll,
      questionBox: questionBox ?? this.questionBox,
      music: music ?? this.music,
      hashtags: hashtags ?? this.hashtags,
      highlightId: highlightId ?? this.highlightId,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      shareCount: shareCount ?? this.shareCount,
      allowReplies: allowReplies ?? this.allowReplies,
      allowSharing: allowSharing ?? this.allowSharing,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Story view record
class StoryView {
  final String? id;
  final String userId;
  final Community? user;
  final DateTime viewedAt;
  final int? viewDuration;

  const StoryView({
    this.id,
    required this.userId,
    this.user,
    required this.viewedAt,
    this.viewDuration,
  });

  factory StoryView.fromJson(Map<String, dynamic> json) {
    return StoryView(
      id: json['_id']?.toString(),
      userId: json['user'] is Map ? json['user']['_id']?.toString() ?? '' : json['user']?.toString() ?? '',
      user: json['user'] is Map ? Community.fromJson(json['user']) : null,
      viewedAt: json['viewedAt'] != null
          ? DateTime.tryParse(json['viewedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      viewDuration: json['viewDuration'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user': userId,
    'viewedAt': viewedAt.toIso8601String(),
    'viewDuration': viewDuration,
  };
}

/// User's story collection
class UserStories {
  final Community user;
  final List<Story> stories;
  final bool hasUnviewed;
  final int unviewedCount;
  final Story? latestStory;

  const UserStories({
    required this.user,
    required this.stories,
    this.hasUnviewed = false,
    this.unviewedCount = 0,
    this.latestStory,
  });

  factory UserStories.fromJson(Map<String, dynamic> json, String currentUserId) {
    final stories = json['stories'] != null
        ? (json['stories'] as List).map((s) => Story.fromJson(s)).toList()
        : <Story>[];

    final activeStories = stories.where((s) => s.isStillActive).toList();
    final unviewedCount = activeStories.where((s) => !s.hasViewed(currentUserId)).length;

    // API returns hasUnviewed as a number (count), not boolean
    final apiUnviewedCount = json['hasUnviewed'] is int 
        ? json['hasUnviewed'] as int 
        : (json['hasUnviewed'] is bool && json['hasUnviewed'] == true ? 1 : 0);
    final finalUnviewedCount = apiUnviewedCount > 0 ? apiUnviewedCount : unviewedCount;
    
    return UserStories(
      user: json['user'] != null
          ? Community.fromJson(json['user'])
          : stories.isNotEmpty ? stories.first.user : Story._defaultUser(),
      stories: stories,
      hasUnviewed: finalUnviewedCount > 0,
      unviewedCount: finalUnviewedCount,
      latestStory: json['latestStory'] != null 
          ? Story.fromJson(json['latestStory'])
          : (activeStories.isNotEmpty ? activeStories.last : null),
    );
  }

  List<Story> get activeStories => stories.where((s) => s.isStillActive).toList();
}

/// Story privacy settings
enum StoryPrivacy {
  everyone,
  friends,
  closeFriends;

  String get value {
    switch (this) {
      case StoryPrivacy.everyone: return 'public';
      case StoryPrivacy.friends: return 'friends';
      case StoryPrivacy.closeFriends: return 'close_friends';
    }
  }

  String get displayName {
    switch (this) {
      case StoryPrivacy.everyone: return 'Everyone';
      case StoryPrivacy.friends: return 'Friends Only';
      case StoryPrivacy.closeFriends: return 'Close Friends';
    }
  }

  static StoryPrivacy fromString(String? value) {
    switch (value) {
      case 'friends': return StoryPrivacy.friends;
      case 'close_friends': return StoryPrivacy.closeFriends;
      default: return StoryPrivacy.everyone;
    }
  }
}

/// Reaction on a story
class StoryReaction {
  final String? id;
  final String userId;
  final Community? user;
  final String emoji;
  final DateTime reactedAt;

  const StoryReaction({
    this.id,
    required this.userId,
    this.user,
    required this.emoji,
    required this.reactedAt,
  });

  factory StoryReaction.fromJson(Map<String, dynamic> json) {
    return StoryReaction(
      id: json['_id']?.toString(),
      userId: json['user'] is Map ? json['user']['_id']?.toString() ?? '' : json['user']?.toString() ?? '',
      user: json['user'] is Map ? Community.fromJson(json['user']) : null,
      emoji: json['emoji']?.toString() ?? '❤️',
      reactedAt: json['reactedAt'] != null
          ? DateTime.tryParse(json['reactedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user': userId,
    'emoji': emoji,
    'reactedAt': reactedAt.toIso8601String(),
  };
}

/// Common reaction emojis
class StoryReactionEmojis {
  static const List<String> all = ['❤️', '😂', '😮', '😢', '😡', '🔥', '👏', '🎉', '💯', '👀'];
}

/// Mention in a story
class StoryMention {
  final String userId;
  final Community? user;
  final String username;
  final double x; // 0-100 percentage
  final double y; // 0-100 percentage

  const StoryMention({
    required this.userId,
    this.user,
    required this.username,
    required this.x,
    required this.y,
  });

  factory StoryMention.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>?;
    return StoryMention(
      userId: json['user'] is Map ? json['user']['_id']?.toString() ?? '' : json['user']?.toString() ?? '',
      user: json['user'] is Map ? Community.fromJson(json['user']) : null,
      username: json['username']?.toString() ?? '',
      x: (position?['x'] ?? json['x'] ?? 50).toDouble(),
      y: (position?['y'] ?? json['y'] ?? 50).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': userId,
    'username': username,
    'position': {'x': x, 'y': y},
  };
}

/// Location in a story
class StoryLocation {
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? placeId;

  const StoryLocation({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.placeId,
  });

  factory StoryLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final coordsList = coords?['coordinates'] as List?;
    
    return StoryLocation(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      latitude: coordsList != null && coordsList.length > 1 ? coordsList[1].toDouble() : null,
      longitude: coordsList != null && coordsList.isNotEmpty ? coordsList[0].toDouble() : null,
      placeId: json['placeId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    if (latitude != null && longitude != null)
      'coordinates': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    'placeId': placeId,
  };
}

/// Link sticker in a story
class StoryLink {
  final String url;
  final String? title;
  final String displayText;

  const StoryLink({
    required this.url,
    this.title,
    this.displayText = 'Learn More',
  });

  factory StoryLink.fromJson(Map<String, dynamic> json) {
    return StoryLink(
      url: json['url']?.toString() ?? '',
      title: json['title']?.toString(),
      displayText: json['displayText']?.toString() ?? 'Learn More',
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'displayText': displayText,
  };
}

/// Poll in a story
class StoryPoll {
  final String question;
  final List<StoryPollOption> options;
  final bool isAnonymous;
  final DateTime? expiresAt;
  final int? userVoteIndex;

  const StoryPoll({
    required this.question,
    required this.options,
    this.isAnonymous = false,
    this.expiresAt,
    this.userVoteIndex,
  });

  factory StoryPoll.fromJson(Map<String, dynamic> json) {
    return StoryPoll(
      question: json['question']?.toString() ?? '',
      options: json['options'] != null
          ? (json['options'] as List).asMap().entries.map((e) => 
              StoryPollOption.fromJson(e.value, e.key)).toList()
          : [],
      isAnonymous: json['isAnonymous'] == true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      userVoteIndex: json['userVoteIndex'],
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options.map((o) => o.toJson()).toList(),
    'isAnonymous': isAnonymous,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);
  
  bool get hasUserVoted => userVoteIndex != null;
}

/// Poll option
class StoryPollOption {
  final int index;
  final String text;
  final int voteCount;
  final double percentage;
  final bool voted;

  const StoryPollOption({
    required this.index,
    required this.text,
    this.voteCount = 0,
    this.percentage = 0,
    this.voted = false,
  });

  factory StoryPollOption.fromJson(Map<String, dynamic> json, int index) {
    return StoryPollOption(
      index: json['index'] ?? index,
      text: json['text']?.toString() ?? '',
      voteCount: json['voteCount'] ?? json['votes']?.length ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      voted: json['voted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'text': text,
    'voteCount': voteCount,
  };
}

/// Question box in a story
class StoryQuestionBox {
  final String prompt;
  final List<StoryQuestionResponse> responses;

  const StoryQuestionBox({
    required this.prompt,
    this.responses = const [],
  });

  factory StoryQuestionBox.fromJson(Map<String, dynamic> json) {
    return StoryQuestionBox(
      prompt: json['prompt']?.toString() ?? 'Ask me anything!',
      responses: json['responses'] != null
          ? (json['responses'] as List).map((r) => StoryQuestionResponse.fromJson(r)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'responses': responses.map((r) => r.toJson()).toList(),
  };
}

/// Question response
class StoryQuestionResponse {
  final String? userId;
  final Community? user;
  final String text;
  final DateTime respondedAt;
  final bool isAnonymous;

  const StoryQuestionResponse({
    this.userId,
    this.user,
    required this.text,
    required this.respondedAt,
    this.isAnonymous = false,
  });

  factory StoryQuestionResponse.fromJson(Map<String, dynamic> json) {
    return StoryQuestionResponse(
      userId: json['user'] is Map ? json['user']['_id']?.toString() : json['user']?.toString(),
      user: json['user'] is Map ? Community.fromJson(json['user']) : null,
      text: json['text']?.toString() ?? '',
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isAnonymous: json['isAnonymous'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': userId,
    'text': text,
    'respondedAt': respondedAt.toIso8601String(),
    'isAnonymous': isAnonymous,
  };
}

/// Music in a story
class StoryMusic {
  final String trackId;
  final String title;
  final String artist;
  final String? coverUrl;
  final String? previewUrl;
  final int startTime;
  final int duration;

  const StoryMusic({
    required this.trackId,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.previewUrl,
    this.startTime = 0,
    this.duration = 15,
  });

  factory StoryMusic.fromJson(Map<String, dynamic> json) {
    return StoryMusic(
      trackId: json['trackId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString(),
      previewUrl: json['previewUrl']?.toString(),
      startTime: json['startTime'] ?? 0,
      duration: json['duration'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() => {
    'trackId': trackId,
    'title': title,
    'artist': artist,
    'coverUrl': coverUrl,
    'previewUrl': previewUrl,
    'startTime': startTime,
    'duration': duration,
  };
}

/// Story Highlight
class StoryHighlight {
  final String id;
  final String userId;
  final String title;
  final String? coverImage;
  final List<Story> stories;
  final int storyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoryHighlight({
    required this.id,
    required this.userId,
    required this.title,
    this.coverImage,
    this.stories = const [],
    this.storyCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoryHighlight.fromJson(Map<String, dynamic> json) {
    return StoryHighlight(
      id: json['_id']?.toString() ?? '',
      userId: json['user'] is Map ? json['user']['_id']?.toString() ?? '' : json['user']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverImage: json['coverImage']?.toString(),
      stories: json['stories'] != null
          ? (json['stories'] as List).map((s) => Story.fromJson(s)).toList()
          : [],
      storyCount: json['storyCount'] ?? json['stories']?.length ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user': userId,
    'title': title,
    'coverImage': coverImage,
    'storyCount': storyCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Response wrappers
class StoriesResponse {
  final bool success;
  final int count;
  final List<UserStories> data;
  final bool blocked;
  final String? message;
  final String? error;

  StoriesResponse({
    required this.success,
    this.count = 0,
    this.data = const [],
    this.blocked = false,
    this.message,
    this.error,
  });

  factory StoriesResponse.fromJson(Map<String, dynamic> json, String currentUserId) {
    return StoriesResponse(
      success: json['success'] == true,
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? (json['data'] as List).map((d) => UserStories.fromJson(d, currentUserId)).toList()
          : [],
      blocked: json['blocked'] == true,
      message: json['message'],
      error: json['error'],
    );
  }
}

class SingleStoryResponse {
  final bool success;
  final Story? data;
  final bool blocked;
  final String? error;

  SingleStoryResponse({required this.success, this.data, this.blocked = false, this.error});

  factory SingleStoryResponse.fromJson(Map<String, dynamic> json) {
    return SingleStoryResponse(
      success: json['success'] == true,
      data: json['data'] != null ? Story.fromJson(json['data']) : null,
      blocked: json['blocked'] == true,
      error: json['error'],
    );
  }
}

class HighlightsResponse {
  final bool success;
  final int count;
  final List<StoryHighlight> data;
  final String? error;

  HighlightsResponse({required this.success, this.count = 0, this.data = const [], this.error});

  factory HighlightsResponse.fromJson(Map<String, dynamic> json) {
    return HighlightsResponse(
      success: json['success'] == true,
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? (json['data'] as List).map((h) => StoryHighlight.fromJson(h)).toList()
          : [],
      error: json['error'],
    );
  }
}

class ArchiveResponse {
  final bool success;
  final int count;
  final int total;
  final int pages;
  final List<Story> data;
  final String? error;

  ArchiveResponse({
    required this.success,
    this.count = 0,
    this.total = 0,
    this.pages = 1,
    this.data = const [],
    this.error,
  });

  factory ArchiveResponse.fromJson(Map<String, dynamic> json) {
    return ArchiveResponse(
      success: json['success'] == true,
      count: json['count'] ?? 0,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
      data: json['data'] != null
          ? (json['data'] as List).map((s) => Story.fromJson(s)).toList()
          : [],
      error: json['error'],
    );
  }
}
