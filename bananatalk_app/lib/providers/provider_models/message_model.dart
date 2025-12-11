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
  final String type; // 'text', 'image', 'audio', 'video', 'document', 'location'

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      sender: json['sender'] != null
          ? Community.fromJson(json['sender'])
          : throw Exception('Sender cannot be null'),
      receiver: json['receiver'] != null
          ? Community.fromJson(json['receiver'])
          : throw Exception('Receiver cannot be null'),
      message: json['message'], // Can be null for media-only messages
      createdAt: json['createdAt'] ?? '',
      version: json['__v'] ?? 0,
      read: json['read'] ?? false,
      media: json['media'] != null ? MessageMedia.fromJson(json['media']) : null,
      replyTo: json['replyTo'] != null ? MessageReply.fromJson(json['replyTo']) : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'],
      isDeleted: json['isDeleted'] ?? false,
      deletedForEveryone: json['deletedForEveryone'] ?? false,
      isPinned: json['pinned'] ?? false,
      pinnedAt: json['pinnedAt'],
      pinnedBy: json['pinnedBy'],
      reactions: json['reactions'] != null
          ? (json['reactions'] as List).map((r) => MessageReaction.fromJson(r)).toList()
          : [],
      type: json['type'] ?? (json['media'] != null ? json['media']['type'] ?? 'text' : 'text'),
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
    };
  }
}

class MessageMedia {
  final String url;
  final String type; // 'image', 'audio', 'video', 'document', 'location'
  final String? thumbnail;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final MediaDimensions? dimensions;
  final LocationData? location;

  MessageMedia({
    required this.url,
    required this.type,
    this.thumbnail,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.dimensions,
    this.location,
  });

  factory MessageMedia.fromJson(Map<String, dynamic> json) {
    return MessageMedia(
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      thumbnail: json['thumbnail'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      dimensions: json['dimensions'] != null
          ? MediaDimensions.fromJson(json['dimensions'])
          : null,
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
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
    };
  }
}

class MediaDimensions {
  final int width;
  final int height;

  MediaDimensions({required this.width, required this.height});

  factory MediaDimensions.fromJson(Map<String, dynamic> json) {
    return MediaDimensions(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
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
  final String message;
  final Community sender;

  MessageReply({
    required this.id,
    required this.message,
    required this.sender,
  });

  factory MessageReply.fromJson(Map<String, dynamic> json) {
    return MessageReply(
      id: json['_id'] ?? '',
      message: json['message'], // Can be null for media-only messages
      sender: Community.fromJson(json['sender']),
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
      user: Community.fromJson(json['user']),
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
