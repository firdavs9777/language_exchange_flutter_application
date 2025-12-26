import 'dart:convert';

/// Notification item from history
class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : {},
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Notification settings from user preferences
class NotificationSettings {
  final bool enabled;
  final bool chatMessages;
  final bool moments;
  final bool followerMoments;
  final bool friendRequests;
  final bool profileVisits;
  final bool marketing;
  final bool sound;
  final bool vibration;
  final bool showPreview;
  final List<String> mutedConversations;

  NotificationSettings({
    required this.enabled,
    required this.chatMessages,
    required this.moments,
    required this.followerMoments,
    required this.friendRequests,
    required this.profileVisits,
    required this.marketing,
    required this.sound,
    required this.vibration,
    required this.showPreview,
    required this.mutedConversations,
  });

  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      enabled: true,
      chatMessages: true,
      moments: true,
      followerMoments: true,
      friendRequests: true,
      profileVisits: true,
      marketing: false,
      sound: true,
      vibration: true,
      showPreview: true,
      mutedConversations: [],
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      chatMessages: json['chatMessages'] ?? true,
      moments: json['moments'] ?? true,
      followerMoments: json['followerMoments'] ?? true,
      friendRequests: json['friendRequests'] ?? true,
      profileVisits: json['profileVisits'] ?? true,
      marketing: json['marketing'] ?? false,
      sound: json['sound'] ?? true,
      vibration: json['vibration'] ?? true,
      showPreview: json['showPreview'] ?? true,
      mutedConversations: json['mutedConversations'] != null
          ? List<String>.from(json['mutedConversations'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'chatMessages': chatMessages,
      'moments': moments,
      'followerMoments': followerMoments,
      'friendRequests': friendRequests,
      'profileVisits': profileVisits,
      'marketing': marketing,
      'sound': sound,
      'vibration': vibration,
      'showPreview': showPreview,
      'mutedConversations': mutedConversations,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? chatMessages,
    bool? moments,
    bool? followerMoments,
    bool? friendRequests,
    bool? profileVisits,
    bool? marketing,
    bool? sound,
    bool? vibration,
    bool? showPreview,
    List<String>? mutedConversations,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      chatMessages: chatMessages ?? this.chatMessages,
      moments: moments ?? this.moments,
      followerMoments: followerMoments ?? this.followerMoments,
      friendRequests: friendRequests ?? this.friendRequests,
      profileVisits: profileVisits ?? this.profileVisits,
      marketing: marketing ?? this.marketing,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      showPreview: showPreview ?? this.showPreview,
      mutedConversations: mutedConversations ?? this.mutedConversations,
    );
  }
}

/// Badge count for messages and notifications
class BadgeCount {
  final int messages;
  final int notifications;

  BadgeCount({
    required this.messages,
    required this.notifications,
  });

  int get total => messages + notifications;

  factory BadgeCount.zero() {
    return BadgeCount(messages: 0, notifications: 0);
  }

  factory BadgeCount.fromJson(Map<String, dynamic> json) {
    return BadgeCount(
      messages: json['messages'] ?? 0,
      notifications: json['notifications'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages,
      'notifications': notifications,
    };
  }

  BadgeCount copyWith({
    int? messages,
    int? notifications,
  }) {
    return BadgeCount(
      messages: messages ?? this.messages,
      notifications: notifications ?? this.notifications,
    );
  }
}

