import 'package:bananatalk_app/models/vip_subscription.dart';

class UserLimits {
  final UserMode userMode;
  final bool isVIP;
  final LimitInfo messages;
  final LimitInfo moments;
  final LimitInfo stories;
  final LimitInfo comments;
  final LimitInfo profileViews;
  final DateTime? resetTime;

  UserLimits({
    required this.userMode,
    required this.isVIP,
    required this.messages,
    required this.moments,
    required this.stories,
    required this.comments,
    required this.profileViews,
    this.resetTime,
  });

  factory UserLimits.fromJson(Map<String, dynamic> json) {
    return UserLimits(
      userMode: UserMode.fromString(json['userMode'] ?? 'regular'),
      isVIP: json['isVIP'] ?? false,
      messages: LimitInfo.fromJson(json['limits']?['messages'] ?? {}),
      moments: LimitInfo.fromJson(json['limits']?['moments'] ?? {}),
      stories: LimitInfo.fromJson(json['limits']?['stories'] ?? {}),
      comments: LimitInfo.fromJson(json['limits']?['comments'] ?? {}),
      profileViews: LimitInfo.fromJson(json['limits']?['profileViews'] ?? {}),
      resetTime: json['resetTime'] != null
          ? DateTime.parse(json['resetTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userMode': userMode.toJson(),
      'isVIP': isVIP,
      'limits': {
        'messages': messages.toJson(),
        'moments': moments.toJson(),
        'stories': stories.toJson(),
        'comments': comments.toJson(),
        'profileViews': profileViews.toJson(),
      },
      'resetTime': resetTime?.toIso8601String(),
    };
  }

  // Helper methods
  bool canSendMessage() => messages.canPerformAction();
  bool canCreateMoment() => moments.canPerformAction();
  bool canCreateStory() => stories.canPerformAction();
  bool canCreateComment() => comments.canPerformAction();
  bool canViewProfile() => profileViews.canPerformAction();
}

class LimitInfo {
  final dynamic current; // int or 0 for VIP
  final dynamic max; // int or "unlimited" for VIP
  final dynamic remaining; // int or "unlimited" for VIP

  LimitInfo({
    required this.current,
    required this.max,
    required this.remaining,
  });

  factory LimitInfo.fromJson(Map<String, dynamic> json) {
    return LimitInfo(
      current: json['current'] ?? 0,
      max: json['max'],
      remaining: json['remaining'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'max': max,
      'remaining': remaining,
    };
  }

  bool get isUnlimited => max == 'unlimited' || remaining == 'unlimited';

  int get currentInt => current is int ? current as int : 0;

  int get maxInt {
    if (max == 'unlimited') return -1; // -1 represents unlimited
    if (max is int) return max as int;
    return 0;
  }

  int get remainingInt {
    if (remaining == 'unlimited') return -1; // -1 represents unlimited
    if (remaining is int) return remaining as int;
    return 0;
  }

  bool canPerformAction() {
    if (isUnlimited) return true;
    return remainingInt > 0;
  }

  double get usagePercentage {
    if (isUnlimited) return 0.0;
    if (maxInt <= 0) return 0.0;
    return (currentInt / maxInt).clamp(0.0, 1.0);
  }

  String get displayText {
    if (isUnlimited) return 'Unlimited';
    return '$currentInt / $maxInt';
  }

  String get remainingText {
    if (isUnlimited) return 'Unlimited';
    return '$remainingInt remaining';
  }
}

