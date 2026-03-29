/// Voice Room Model for live audio chat
class VoiceRoom {
  final String id;
  final String title;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final String topic;
  final String language;
  final List<RoomParticipant> participants;
  final int maxParticipants;
  final bool isLive;
  final DateTime createdAt;

  const VoiceRoom({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostName,
    this.hostAvatar = '',
    required this.topic,
    required this.language,
    this.participants = const [],
    this.maxParticipants = 8,
    this.isLive = true,
    required this.createdAt,
  });

  factory VoiceRoom.fromJson(Map<String, dynamic> json) {
    // Parse host — backend sends populated object {_id, name, images}
    String hostId = '';
    String hostName = '';
    String hostAvatar = '';
    final host = json['host'];
    if (host is Map<String, dynamic>) {
      hostId = host['_id']?.toString() ?? host['id']?.toString() ?? '';
      hostName = host['name']?.toString() ?? '';
      final images = host['images'];
      if (images is List && images.isNotEmpty) {
        hostAvatar = images[0]?.toString() ?? '';
      }
    } else if (host is String) {
      hostId = host;
    }
    // Fallback to flat fields if present
    if (hostId.isEmpty) hostId = json['hostId']?.toString() ?? '';
    if (hostName.isEmpty) hostName = json['hostName']?.toString() ?? '';
    if (hostAvatar.isEmpty) hostAvatar = json['hostAvatar']?.toString() ?? '';

    return VoiceRoom(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      hostId: hostId,
      hostName: hostName,
      hostAvatar: hostAvatar,
      topic: json['topic']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => RoomParticipant.fromJson(
                  e is Map<String, dynamic> ? e : <String, dynamic>{}))
              .toList() ??
          [],
      maxParticipants: json['maxParticipants'] ?? 8,
      isLive: json['isLive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'topic': topic,
      'language': language,
      'participants': participants.map((e) => e.toJson()).toList(),
      'maxParticipants': maxParticipants,
      'isLive': isLive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get participantCount => participants.length;
  bool get isFull => participantCount >= maxParticipants;

  String get participantCountText {
    return '$participantCount/$maxParticipants';
  }

  String get durationText {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Just started';
    }
  }
}

class RoomParticipant {
  final String id;
  final String name;
  final String avatar;
  final bool isSpeaking;
  final bool isMuted;
  final bool isHost;
  final DateTime joinedAt;

  const RoomParticipant({
    required this.id,
    required this.name,
    this.avatar = '',
    this.isSpeaking = false,
    this.isMuted = false,
    this.isHost = false,
    required this.joinedAt,
  });

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    // Backend sends two formats:
    // 1. GET list: {_id, name, images, role, isSpeaking} (flattened from user)
    // 2. Raw/create: {user: ObjectId or {_id, name, images}, joinedAt, isMuted, ...}
    String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    String name = json['name']?.toString() ?? '';
    String avatar = '';
    final role = json['role']?.toString() ?? '';

    // Extract avatar from images array
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      avatar = images[0]?.toString() ?? '';
    }
    avatar = avatar.isEmpty ? (json['avatar']?.toString() ?? '') : avatar;

    // Handle nested user object format
    final user = json['user'];
    if (user is Map<String, dynamic>) {
      if (id.isEmpty) id = user['_id']?.toString() ?? user['id']?.toString() ?? '';
      if (name.isEmpty) name = user['name']?.toString() ?? '';
      if (avatar.isEmpty) {
        final userImages = user['images'];
        if (userImages is List && userImages.isNotEmpty) {
          avatar = userImages[0]?.toString() ?? '';
        }
      }
    } else if (user is String && id.isEmpty) {
      id = user;
    }

    return RoomParticipant(
      id: id,
      name: name,
      avatar: avatar,
      isSpeaking: json['isSpeaking'] ?? false,
      isMuted: json['isMuted'] ?? true,
      isHost: json['isHost'] == true || role == 'host',
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isSpeaking': isSpeaking,
      'isMuted': isMuted,
      'isHost': isHost,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

/// Request model for creating a voice room
class CreateRoomRequest {
  final String title;
  final String topic;
  final String language;
  final int maxParticipants;

  const CreateRoomRequest({
    required this.title,
    required this.topic,
    required this.language,
    this.maxParticipants = 8,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'topic': topic,
      'language': language,
      'maxParticipants': maxParticipants,
    };
  }
}
