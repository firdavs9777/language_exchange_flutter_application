import 'package:bananatalk_app/utils/string_sanitizer.dart';

/// Quiet hours configuration — pauses non-urgent notifications during a window.
class QuietHours {
  final bool enabled;
  final String start; // 'HH:mm'
  final String end;
  final String timezone; // IANA
  final bool allowUrgent;

  const QuietHours({
    this.enabled = false,
    this.start = '22:00',
    this.end = '08:00',
    this.timezone = 'Asia/Seoul',
    this.allowUrgent = true,
  });

  QuietHours copyWith({
    bool? enabled,
    String? start,
    String? end,
    String? timezone,
    bool? allowUrgent,
  }) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        end: end ?? this.end,
        timezone: timezone ?? this.timezone,
        allowUrgent: allowUrgent ?? this.allowUrgent,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'start': start,
        'end': end,
        'timezone': timezone,
        'allowUrgent': allowUrgent,
      };

  factory QuietHours.fromJson(Map<String, dynamic> j) => QuietHours(
        enabled: j['enabled'] ?? false,
        start: j['start'] ?? '22:00',
        end: j['end'] ?? '08:00',
        timezone: j['timezone'] ?? 'Asia/Seoul',
        allowUrgent: j['allowUrgent'] ?? true,
      );
}

/// Notification item from history
class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final int bundleSize;
  final String? suppressedReason;

  /// Held back by the user's quiet hours (vs. the daily cap).
  bool get suppressedByQuietHours => suppressedReason == 'quiet_hours';

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
    this.bundleSize = 1,
    this.suppressedReason,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: sanitize(json['title']),
      body: sanitize(json['body']),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : {},
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      bundleSize: (json['bundleSize'] as int?) ?? 1,
      suppressedReason: json['suppressedReason'] as String?,
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
      'bundleSize': bundleSize,
      'suppressedReason': suppressedReason,
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
    int? bundleSize,
    String? suppressedReason,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      bundleSize: bundleSize ?? this.bundleSize,
      suppressedReason: suppressedReason ?? this.suppressedReason,
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
  final bool announcements;
  final bool allowCalls;
  final bool sound;
  final bool vibration;
  final bool showPreview;
  final List<String> mutedConversations;
  final QuietHours quietHours;

  /// The daily lesson ("daily drop") push: on/off, and the local hour (0-23)
  /// it arrives. The server had both; the app never showed them, so everyone
  /// got it at 19:00 with no way to move or stop it.
  final bool dailyDropReminders;
  final int dailyDropHour;

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
    this.announcements = true,
    this.allowCalls = true,
    this.quietHours = const QuietHours(),
    this.dailyDropReminders = true,
    this.dailyDropHour = 19,
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
      announcements: true,
      allowCalls: true,
      sound: true,
      vibration: true,
      showPreview: true,
      mutedConversations: [],
      quietHours: const QuietHours(),
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
      announcements: json['announcements'] ?? true,
      allowCalls: json['allowCalls'] ?? true,
      sound: json['sound'] ?? true,
      vibration: json['vibration'] ?? true,
      showPreview: json['showPreview'] ?? true,
      // Backend uses 'mutedChats', frontend uses 'mutedConversations'
      mutedConversations: json['mutedChats'] != null
          ? List<String>.from(json['mutedChats'])
          : (json['mutedConversations'] != null
              ? List<String>.from(json['mutedConversations'])
              : []),
      quietHours: json['quietHours'] != null
          ? QuietHours.fromJson(Map<String, dynamic>.from(json['quietHours']))
          : const QuietHours(),
      dailyDropReminders: json['dailyDropReminders'] ?? true,
      dailyDropHour: _hourOr19(json['dailyDropHour']),
    );
  }

  static int _hourOr19(dynamic v) {
    final h = v is num ? v.toInt() : int.tryParse('$v');
    return (h != null && h >= 0 && h <= 23) ? h : 19;
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
      'announcements': announcements,
      'allowCalls': allowCalls,
      'sound': sound,
      'vibration': vibration,
      'showPreview': showPreview,
      'mutedChats': mutedConversations, // Backend expects 'mutedChats'
      'quietHours': quietHours.toJson(),
      'dailyDropReminders': dailyDropReminders,
      'dailyDropHour': dailyDropHour,
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
    bool? announcements,
    bool? allowCalls,
    bool? sound,
    bool? vibration,
    bool? showPreview,
    List<String>? mutedConversations,
    QuietHours? quietHours,
    bool? dailyDropReminders,
    int? dailyDropHour,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      chatMessages: chatMessages ?? this.chatMessages,
      moments: moments ?? this.moments,
      followerMoments: followerMoments ?? this.followerMoments,
      friendRequests: friendRequests ?? this.friendRequests,
      profileVisits: profileVisits ?? this.profileVisits,
      marketing: marketing ?? this.marketing,
      announcements: announcements ?? this.announcements,
      allowCalls: allowCalls ?? this.allowCalls,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      showPreview: showPreview ?? this.showPreview,
      mutedConversations: mutedConversations ?? this.mutedConversations,
      quietHours: quietHours ?? this.quietHours,
      dailyDropReminders: dailyDropReminders ?? this.dailyDropReminders,
      dailyDropHour: dailyDropHour ?? this.dailyDropHour,
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
    // Handle both naming conventions from backend
    // Backend returns: unreadMessages/unreadNotifications OR messages/notifications
    return BadgeCount(
      messages: json['unreadMessages'] ?? json['messages'] ?? 0,
      notifications: json['unreadNotifications'] ?? json['notifications'] ?? 0,
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

