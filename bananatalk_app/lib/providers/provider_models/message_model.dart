import 'package:bananatalk_app/providers/provider_models/community_model.dart';

class Message {
  const Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.createdAt,
    required this.version,
    required this.read,
    this.media,
    this.replyTo,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedForEveryone = false,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.reactions = const [],
    this.type = 'text',
    this.translations = const [],
    this.corrections = const [],
    this.mentions = const [],
    this.isBookmarked = false,
    this.bookmarkedAt,
    this.poll,
    this.selfDestruct,
    this.isForwarded = false,
    this.forwardedFrom,
  });

  final String id;
  final Community sender;
  final Community receiver;
  final String? message; // Made nullable for media-only messages
  final String createdAt;
  final int version;
  final bool read;
  final MessageMedia? media;
  final MessageReply? replyTo;
  final bool isEdited;
  final String? editedAt;
  final bool isDeleted;
  final bool deletedForEveryone;
  final bool isPinned;
  final String? pinnedAt;
  final String? pinnedBy;
  final List<MessageReaction> reactions;
  final String type; // 'text', 'image', 'audio', 'video', 'document', 'location', 'voice', 'poll'
  final List<MessageTranslation> translations;
  final List<MessageCorrection> corrections;
  final List<MessageMention> mentions;
  final bool isBookmarked;
  final String? bookmarkedAt;
  final Poll? poll;
  final SelfDestructSettings? selfDestruct;
  final bool isForwarded;
  final ForwardedMessage? forwardedFrom;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      sender: _parseCommunity(json['sender']),
      receiver: _parseCommunity(json['receiver']),
      message: json['message'], // Can be null for media-only messages
      createdAt: json['createdAt'] ?? '',
      version: (json['__v'] as num?)?.toInt() ?? 0,
      read: json['read'] ?? false,
      media: json['media'] != null && json['media'] is Map<String, dynamic> 
          ? MessageMedia.fromJson(json['media']) 
          : null,
      replyTo: json['replyTo'] != null && json['replyTo'] is Map<String, dynamic> 
          ? MessageReply.fromJson(json['replyTo']) 
          : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'],
      isDeleted: json['isDeleted'] ?? false,
      deletedForEveryone: json['deletedForEveryone'] ?? false,
      isPinned: json['pinned'] ?? false,
      pinnedAt: json['pinnedAt'],
      pinnedBy: json['pinnedBy'],
      reactions: json['reactions'] != null && json['reactions'] is List
          ? (json['reactions'] as List)
              .where((r) => r != null && r is Map<String, dynamic>)
              .map((r) => MessageReaction.fromJson(r))
              .toList()
          : [],
      type: json['type'] ?? json['messageType'] ?? (json['media'] != null ? json['media']['type'] ?? 'text' : 'text'),
      translations: json['translations'] != null && json['translations'] is List
          ? (json['translations'] as List)
              .where((t) => t != null && t is Map<String, dynamic>)
              .map((t) => MessageTranslation.fromJson(t))
              .toList()
          : [],
      corrections: json['corrections'] != null && json['corrections'] is List
          ? (json['corrections'] as List)
              .where((c) => c != null && c is Map<String, dynamic>)
              .map((c) => MessageCorrection.fromJson(c))
              .toList()
          : [],
      mentions: json['mentions'] != null && json['mentions'] is List
          ? (json['mentions'] as List)
              .where((m) => m != null && m is Map<String, dynamic>)
              .map((m) => MessageMention.fromJson(m))
              .toList()
          : [],
      isBookmarked: json['isBookmarked'] ?? false,
      bookmarkedAt: json['bookmarkedAt'],
      poll: json['poll'] != null && json['poll'] is Map<String, dynamic> 
          ? Poll.fromJson(json['poll']) 
          : null,
      selfDestruct: json['selfDestruct'] != null && json['selfDestruct'] is Map<String, dynamic> 
          ? SelfDestructSettings.fromJson(json['selfDestruct']) 
          : null,
      isForwarded: json['isForwarded'] ?? false,
      forwardedFrom: json['forwardedFrom'] != null && json['forwardedFrom'] is Map<String, dynamic> 
          ? ForwardedMessage.fromJson(json['forwardedFrom']) 
          : null,
    );
  }
  
  /// Helper to parse Community safely
  static Community _parseCommunity(dynamic data) {
    if (data == null) {
      return _defaultCommunity();
    }
    if (data is Map<String, dynamic>) {
      return Community.fromJson(data);
    }
    // If it's just a string ID, create a minimal community object
    if (data is String) {
      return Community(
        id: data,
        name: '',
        email: '',
        bio: '',
        mbti: '',
        bloodType: '',
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
    return _defaultCommunity();
  }
  
  /// Default community for when data is missing
  static Community _defaultCommunity() {
    return Community(
      id: '',
      name: 'Unknown',
      email: '',
      bio: '',
      mbti: '',
      bloodType: '',
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'message': message,
      'createdAt': createdAt,
      '__v': version,
      'read': read,
      'media': media?.toJson(),
      'replyTo': replyTo?.toJson(),
      'isEdited': isEdited,
      'editedAt': editedAt,
      'isDeleted': isDeleted,
      'deletedForEveryone': deletedForEveryone,
      'pinned': isPinned,
      'pinnedAt': pinnedAt,
      'pinnedBy': pinnedBy,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'type': type,
      'translations': translations.map((t) => t.toJson()).toList(),
      'corrections': corrections.map((c) => c.toJson()).toList(),
      'mentions': mentions.map((m) => m.toJson()).toList(),
      'isBookmarked': isBookmarked,
      'bookmarkedAt': bookmarkedAt,
      'poll': poll?.toJson(),
      'selfDestruct': selfDestruct?.toJson(),
      'isForwarded': isForwarded,
      'forwardedFrom': forwardedFrom?.toJson(),
    };
  }
  
  /// Create a copy of this message with updated fields
  Message copyWith({
    String? id,
    Community? sender,
    Community? receiver,
    String? message,
    String? createdAt,
    int? version,
    bool? read,
    MessageMedia? media,
    MessageReply? replyTo,
    bool? isEdited,
    String? editedAt,
    bool? isDeleted,
    bool? deletedForEveryone,
    bool? isPinned,
    String? pinnedAt,
    String? pinnedBy,
    List<MessageReaction>? reactions,
    String? type,
    List<MessageTranslation>? translations,
    List<MessageCorrection>? corrections,
    List<MessageMention>? mentions,
    bool? isBookmarked,
    String? bookmarkedAt,
    Poll? poll,
    SelfDestructSettings? selfDestruct,
    bool? isForwarded,
    ForwardedMessage? forwardedFrom,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
      read: read ?? this.read,
      media: media ?? this.media,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      reactions: reactions ?? this.reactions,
      type: type ?? this.type,
      translations: translations ?? this.translations,
      corrections: corrections ?? this.corrections,
      mentions: mentions ?? this.mentions,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      poll: poll ?? this.poll,
      selfDestruct: selfDestruct ?? this.selfDestruct,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
    );
  }
}

class MessageMedia {
  final String url;
  final String type; // 'image', 'audio', 'video', 'document', 'location', 'voice'
  final String? thumbnail;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final MediaDimensions? dimensions;
  final LocationData? location;
  final int? duration; // For audio/video/voice in seconds
  final List<double>? waveform; // For voice messages - amplitude data (0-1)

  MessageMedia({
    required this.url,
    required this.type,
    this.thumbnail,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.dimensions,
    this.location,
    this.duration,
    this.waveform,
  });

  factory MessageMedia.fromJson(Map<String, dynamic> json) {
    return MessageMedia(
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      thumbnail: json['thumbnail'],
      fileName: json['fileName'],
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'],
      dimensions: json['dimensions'] != null
          ? MediaDimensions.fromJson(json['dimensions'])
          : null,
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
      duration: (json['duration'] as num?)?.toInt(),
      waveform: json['waveform'] != null
          ? (json['waveform'] as List).map((w) => (w as num).toDouble()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'thumbnail': thumbnail,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'dimensions': dimensions?.toJson(),
      'location': location?.toJson(),
      'duration': duration,
      'waveform': waveform,
    };
  }
}

class MediaDimensions {
  final int width;
  final int height;

  MediaDimensions({required this.width, required this.height});

  factory MediaDimensions.fromJson(Map<String, dynamic> json) {
    return MediaDimensions(
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      placeName: json['placeName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
    };
  }
}

class MessageReply {
  final String id;
  final String? message;
  final Community sender;

  MessageReply({
    required this.id,
    this.message,
    required this.sender,
  });

  factory MessageReply.fromJson(Map<String, dynamic> json) {
    return MessageReply(
      id: json['_id'] ?? '',
      message: json['message'], // Can be null for media-only messages
      sender: Message._parseCommunity(json['sender']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'message': message,
      'sender': sender.toJson(),
    };
  }
}

class MessageReaction {
  final Community user;
  final String emoji;

  MessageReaction({
    required this.user,
    required this.emoji,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      user: Message._parseCommunity(json['user']),
      emoji: json['emoji'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'emoji': emoji,
    };
  }
}

/// Translation of a message to a different language
class MessageTranslation {
  final String language; // ISO language code (e.g., 'ko', 'ja', 'es')
  final String translatedText;
  final String translatedAt;
  final String? provider; // 'google', 'deepl', 'papago'

  MessageTranslation({
    required this.language,
    required this.translatedText,
    required this.translatedAt,
    this.provider,
  });

  factory MessageTranslation.fromJson(Map<String, dynamic> json) {
    return MessageTranslation(
      language: json['language'] ?? '',
      translatedText: json['translatedText'] ?? '',
      translatedAt: json['translatedAt'] ?? '',
      provider: json['provider'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'translatedText': translatedText,
      'translatedAt': translatedAt,
      'provider': provider,
    };
  }
}

/// Correction for a message (HelloTalk style language learning)
class MessageCorrection {
  final String id;
  final Community corrector;
  final String originalText;
  final String correctedText;
  final String? explanation;
  final String createdAt;
  final bool isAccepted;

  MessageCorrection({
    required this.id,
    required this.corrector,
    required this.originalText,
    required this.correctedText,
    this.explanation,
    required this.createdAt,
    this.isAccepted = false,
  });

  factory MessageCorrection.fromJson(Map<String, dynamic> json) {
    return MessageCorrection(
      id: json['_id'] ?? '',
      corrector: Message._parseCommunity(json['corrector']),
      originalText: json['originalText'] ?? '',
      correctedText: json['correctedText'] ?? '',
      explanation: json['explanation'],
      createdAt: json['createdAt'] ?? '',
      isAccepted: json['isAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'corrector': corrector.toJson(),
      'originalText': originalText,
      'correctedText': correctedText,
      'explanation': explanation,
      'createdAt': createdAt,
      'isAccepted': isAccepted,
    };
  }
}

/// Mention of a user in a message (@username)
class MessageMention {
  final Community user;
  final String username;
  final int startIndex;
  final int endIndex;

  MessageMention({
    required this.user,
    required this.username,
    required this.startIndex,
    required this.endIndex,
  });

  factory MessageMention.fromJson(Map<String, dynamic> json) {
    return MessageMention(
      user: Message._parseCommunity(json['user']),
      username: json['username'] ?? '',
      startIndex: (json['startIndex'] as num?)?.toInt() ?? 0,
      endIndex: (json['endIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'username': username,
      'startIndex': startIndex,
      'endIndex': endIndex,
    };
  }
}

/// Self-destruct settings for disappearing messages
class SelfDestructSettings {
  final bool enabled;
  final String? expiresAt;
  final bool destructAfterRead;
  final int destructTimer; // Seconds after read
  final String? destructAt; // When destruction will happen

  SelfDestructSettings({
    this.enabled = false,
    this.expiresAt,
    this.destructAfterRead = false,
    this.destructTimer = 0,
    this.destructAt,
  });

  factory SelfDestructSettings.fromJson(Map<String, dynamic> json) {
    return SelfDestructSettings(
      enabled: json['enabled'] ?? false,
      expiresAt: json['expiresAt'],
      destructAfterRead: json['destructAfterRead'] ?? false,
      destructTimer: (json['destructTimer'] as num?)?.toInt() ?? 0,
      destructAt: json['destructAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'expiresAt': expiresAt,
      'destructAfterRead': destructAfterRead,
      'destructTimer': destructTimer,
      'destructAt': destructAt,
    };
  }
}

/// Forwarded message information
class ForwardedMessage {
  final Community sender;
  final String messageId;
  final String? originalMessage;

  ForwardedMessage({
    required this.sender,
    required this.messageId,
    this.originalMessage,
  });

  factory ForwardedMessage.fromJson(Map<String, dynamic> json) {
    return ForwardedMessage(
      sender: Message._parseCommunity(json['sender']),
      messageId: json['messageId'] ?? '',
      originalMessage: json['originalMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender.toJson(),
      'messageId': messageId,
      'originalMessage': originalMessage,
    };
  }
}

/// Poll in a chat message
class Poll {
  final String id;
  final String? messageId;
  final String? conversationId;
  final Community creator;
  final String question;
  final List<PollOption> options;
  final PollSettings settings;
  final String status; // 'active', 'closed', 'expired'
  final String? expiresAt;
  final String? closedAt;
  final Community? closedBy;
  final int totalVotes;
  final int uniqueVoters;
  final String createdAt;

  Poll({
    required this.id,
    this.messageId,
    this.conversationId,
    required this.creator,
    required this.question,
    required this.options,
    required this.settings,
    this.status = 'active',
    this.expiresAt,
    this.closedAt,
    this.closedBy,
    this.totalVotes = 0,
    this.uniqueVoters = 0,
    required this.createdAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['_id'] ?? '',
      messageId: json['message'],
      conversationId: json['conversation'],
      creator: Message._parseCommunity(json['creator']),
      question: json['question'] ?? '',
      options: (json['options'] as List?)
              ?.where((o) => o != null && o is Map<String, dynamic>)
              .map((o) => PollOption.fromJson(o))
              .toList() ??
          [],
      settings: PollSettings.fromJson(json['settings'] ?? {}),
      status: json['status'] ?? 'active',
      expiresAt: json['expiresAt'],
      closedAt: json['closedAt'],
      closedBy: json['closedBy'] != null && json['closedBy'] is Map<String, dynamic>
          ? Community.fromJson(json['closedBy'])
          : null,
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
      uniqueVoters: (json['uniqueVoters'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'message': messageId,
      'conversation': conversationId,
      'creator': creator.toJson(),
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      'settings': settings.toJson(),
      'status': status,
      'expiresAt': expiresAt,
      'closedAt': closedAt,
      'closedBy': closedBy?.toJson(),
      'totalVotes': totalVotes,
      'uniqueVoters': uniqueVoters,
      'createdAt': createdAt,
    };
  }
  
  /// Check if user has voted
  bool hasUserVoted(String userId) {
    for (final option in options) {
      if (option.voters.any((v) => v.id == userId)) {
        return true;
      }
    }
    return false;
  }
  
  /// Get user's voted option index
  int? getUserVoteIndex(String userId) {
    for (int i = 0; i < options.length; i++) {
      if (options[i].voters.any((v) => v.id == userId)) {
        return i;
      }
    }
    return null;
  }
}

/// Poll option with votes
class PollOption {
  final String text;
  final List<PollVoter> voters;
  final int voteCount;

  PollOption({
    required this.text,
    this.voters = const [],
    this.voteCount = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? '',
      voters: (json['votes'] as List?)
              ?.map((v) => PollVoter.fromJson(v))
              .toList() ??
          [],
      voteCount: (json['voteCount'] as num?)?.toInt() ?? (json['votes'] as List?)?.length ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'votes': voters.map((v) => v.toJson()).toList(),
      'voteCount': voteCount,
    };
  }
  
  /// Get percentage of votes (requires total)
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (voteCount / totalVotes) * 100;
  }
}

/// Voter in a poll
class PollVoter {
  final String id;
  final String? name;
  final String votedAt;

  PollVoter({
    required this.id,
    this.name,
    required this.votedAt,
  });

  factory PollVoter.fromJson(Map<String, dynamic> json) {
    // Handle both user object and user ID string
    if (json['user'] is Map) {
      return PollVoter(
        id: json['user']['_id'] ?? '',
        name: json['user']['name'],
        votedAt: json['votedAt'] ?? '',
      );
    }
    return PollVoter(
      id: json['user'] ?? '',
      name: null,
      votedAt: json['votedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': id,
      'votedAt': votedAt,
    };
  }
}

/// Poll settings
class PollSettings {
  final bool allowMultipleVotes;
  final int maxVotesPerUser;
  final bool isAnonymous;
  final bool showResultsBeforeVote;
  final bool allowAddOptions;
  final bool isQuiz;
  final int? correctOptionIndex;
  final String? explanation;

  PollSettings({
    this.allowMultipleVotes = false,
    this.maxVotesPerUser = 1,
    this.isAnonymous = false,
    this.showResultsBeforeVote = true,
    this.allowAddOptions = false,
    this.isQuiz = false,
    this.correctOptionIndex,
    this.explanation,
  });

  factory PollSettings.fromJson(Map<String, dynamic> json) {
    return PollSettings(
      allowMultipleVotes: json['allowMultipleVotes'] ?? false,
      maxVotesPerUser: (json['maxVotesPerUser'] as num?)?.toInt() ?? 1,
      isAnonymous: json['isAnonymous'] ?? false,
      showResultsBeforeVote: json['showResultsBeforeVote'] ?? true,
      allowAddOptions: json['allowAddOptions'] ?? false,
      isQuiz: json['isQuiz'] ?? false,
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt(),
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowMultipleVotes': allowMultipleVotes,
      'maxVotesPerUser': maxVotesPerUser,
      'isAnonymous': isAnonymous,
      'showResultsBeforeVote': showResultsBeforeVote,
      'allowAddOptions': allowAddOptions,
      'isQuiz': isQuiz,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }
}

/// Quick reply template
class QuickReply {
  final String id;
  final String text;
  final String createdBy;
  final String createdAt;
  final int useCount;

  QuickReply({
    required this.id,
    required this.text,
    required this.createdBy,
    required this.createdAt,
    this.useCount = 0,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: json['_id'] ?? '',
      text: json['text'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'useCount': useCount,
    };
  }
}

/// Bookmarked message wrapper
class BookmarkedMessage {
  final Message message;
  final String bookmarkedAt;

  BookmarkedMessage({
    required this.message,
    required this.bookmarkedAt,
  });

  factory BookmarkedMessage.fromJson(Map<String, dynamic> json) {
    final messageData = json['message'];
    if (messageData == null || messageData is! Map<String, dynamic>) {
      throw Exception('Invalid bookmarked message data');
    }
    return BookmarkedMessage(
      message: Message.fromJson(messageData),
      bookmarkedAt: json['bookmarkedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'bookmarkedAt': bookmarkedAt,
    };
  }
}
