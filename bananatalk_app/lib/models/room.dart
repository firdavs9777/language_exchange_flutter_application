/// Workstream D — Language Rooms.
///
/// A "hub" is a public, target-language-scoped group chat room. The backend
/// returns the caller's auto-joined hub first from `GET /rooms` — see
/// `RoomApiClient.getRooms`.
class Room {
  final String id;
  final String title;
  final String emojiFlag;

  /// `'hub'` (public, target-language-scoped, backend-seeded) or `'topic'`
  /// (user-created, nested under a language). Old payloads that predate this
  /// field are assumed to be hubs.
  final String roomType;
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

  /// User id of the room's creator/owner. Hubs may have no owner (seeded),
  /// so this is nullable.
  final String? ownerId;

  /// `true` for backend-seeded hubs; `false` for user-created topic rooms.
  final bool isSeeded;

  /// True when the caller is banned from this (topic) room. Always `false`
  /// for hubs, which don't support banning.
  final bool isBanned;

  /// True when the caller has a pending join request on this room.
  final bool hasPendingRequest;

  /// Count of pending join requests. Only populated by the backend for the
  /// room's owner/admin — absent (and defaulted to `0`) for everyone else,
  /// so this can't be used to infer "no requests" vs. "not authorized to
  /// know" without also checking [isOwnerOrAdmin].
  final int pendingRequestCount;

  const Room({
    required this.id,
    required this.title,
    required this.emojiFlag,
    required this.targetLanguage,
    required this.memberCount,
    required this.onlineCount,
    required this.description,
    required this.isMember,
    this.roomType = 'hub',
    this.isOwnerOrAdmin = false,
    this.ownerId,
    this.isSeeded = false,
    this.isBanned = false,
    this.hasPendingRequest = false,
    this.pendingRequestCount = 0,
  });

  /// True for user-created topic rooms (as opposed to backend-seeded hubs).
  bool get isTopicRoom => roomType == 'topic';

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      emojiFlag: json['emojiFlag']?.toString() ?? '',
      roomType: json['roomType']?.toString() ?? 'hub',
      targetLanguage: json['targetLanguage']?.toString() ?? '',
      memberCount: _asInt(json['memberCount']),
      onlineCount: _asInt(json['onlineCount']),
      description: json['description']?.toString() ?? '',
      isMember: json['isMember'] == true,
      isOwnerOrAdmin: json['isOwnerOrAdmin'] == true ||
          json['isOwner'] == true ||
          json['isAdmin'] == true,
      ownerId: _ownerIdFrom(json['owner']),
      isSeeded: json['isSeeded'] == true,
      isBanned: json['isBanned'] == true,
      hasPendingRequest: json['hasPendingRequest'] == true,
      pendingRequestCount: _asInt(json['pendingRequestCount']),
    );
  }

  Room copyWith({
    String? id,
    String? title,
    String? emojiFlag,
    String? roomType,
    String? targetLanguage,
    int? memberCount,
    int? onlineCount,
    String? description,
    bool? isMember,
    bool? isOwnerOrAdmin,
    String? ownerId,
    bool? isSeeded,
    bool? isBanned,
    bool? hasPendingRequest,
    int? pendingRequestCount,
  }) {
    return Room(
      id: id ?? this.id,
      title: title ?? this.title,
      emojiFlag: emojiFlag ?? this.emojiFlag,
      roomType: roomType ?? this.roomType,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      memberCount: memberCount ?? this.memberCount,
      onlineCount: onlineCount ?? this.onlineCount,
      description: description ?? this.description,
      isMember: isMember ?? this.isMember,
      isOwnerOrAdmin: isOwnerOrAdmin ?? this.isOwnerOrAdmin,
      ownerId: ownerId ?? this.ownerId,
      isSeeded: isSeeded ?? this.isSeeded,
      isBanned: isBanned ?? this.isBanned,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// `owner` on the wire may be a raw id string or a populated user object
  /// (e.g. `{ "_id": "...", "name": "..." }`) depending on the endpoint.
  static String? _ownerIdFrom(dynamic owner) {
    if (owner == null) return null;
    if (owner is Map) {
      final id = owner['_id'] ?? owner['id'];
      return id?.toString();
    }
    return owner.toString();
  }
}
