/// Workstream D — Language Rooms.
///
/// A "hub" is a public, target-language-scoped group chat room. The backend
/// returns the caller's auto-joined hub first from `GET /rooms` — see
/// `RoomApiClient.getRooms`.
class Room {
  final String id;
  final String title;
  final String emojiFlag;
  final String targetLanguage;
  final int memberCount;
  final int onlineCount;
  final String description;
  final bool isMember;

  /// True when the caller owns or admins this hub. Parsed defensively from
  /// whichever shape the backend's room-detail response uses once the
  /// moderation endpoints land (Workstream D backend phase); defaults to
  /// `false` so the member-list moderation UI (Task 11) stays hidden for
  /// everyone until the backend actually confirms the role.
  final bool isOwnerOrAdmin;

  const Room({
    required this.id,
    required this.title,
    required this.emojiFlag,
    required this.targetLanguage,
    required this.memberCount,
    required this.onlineCount,
    required this.description,
    required this.isMember,
    this.isOwnerOrAdmin = false,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      emojiFlag: json['emojiFlag']?.toString() ?? '',
      targetLanguage: json['targetLanguage']?.toString() ?? '',
      memberCount: _asInt(json['memberCount']),
      onlineCount: _asInt(json['onlineCount']),
      description: json['description']?.toString() ?? '',
      isMember: json['isMember'] == true,
      isOwnerOrAdmin: json['isOwnerOrAdmin'] == true ||
          json['isOwner'] == true ||
          json['isAdmin'] == true,
    );
  }

  Room copyWith({
    String? id,
    String? title,
    String? emojiFlag,
    String? targetLanguage,
    int? memberCount,
    int? onlineCount,
    String? description,
    bool? isMember,
    bool? isOwnerOrAdmin,
  }) {
    return Room(
      id: id ?? this.id,
      title: title ?? this.title,
      emojiFlag: emojiFlag ?? this.emojiFlag,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      memberCount: memberCount ?? this.memberCount,
      onlineCount: onlineCount ?? this.onlineCount,
      description: description ?? this.description,
      isMember: isMember ?? this.isMember,
      isOwnerOrAdmin: isOwnerOrAdmin ?? this.isOwnerOrAdmin,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
