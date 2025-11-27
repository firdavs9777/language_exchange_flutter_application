class VipSubscription {
  final String id;
  final String plan;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double amount;
  final String? paymentMethod;

  VipSubscription({
    required this.id,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.amount,
    this.paymentMethod,
  });

  factory VipSubscription.fromJson(Map<String, dynamic> json) {
    return VipSubscription(
      id: json['_id'] ?? '',
      plan: json['plan'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'plan': plan,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'amount': amount,
      'paymentMethod': paymentMethod,
    };
  }
}

class VipFeatures {
  final bool unlimitedMessages;
  final bool unlimitedProfileViews;
  final bool prioritySupport;
  final bool advancedSearch;
  final bool profileBoost;
  final bool adFree;

  VipFeatures({
    this.unlimitedMessages = false,
    this.unlimitedProfileViews = false,
    this.prioritySupport = false,
    this.advancedSearch = false,
    this.profileBoost = false,
    this.adFree = false,
  });

  factory VipFeatures.fromJson(Map<String, dynamic> json) {
    return VipFeatures(
      unlimitedMessages: json['unlimitedMessages'] ?? false,
      unlimitedProfileViews: json['unlimitedProfileViews'] ?? false,
      prioritySupport: json['prioritySupport'] ?? false,
      advancedSearch: json['advancedSearch'] ?? false,
      profileBoost: json['profileBoost'] ?? false,
      adFree: json['adFree'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlimitedMessages': unlimitedMessages,
      'unlimitedProfileViews': unlimitedProfileViews,
      'prioritySupport': prioritySupport,
      'advancedSearch': advancedSearch,
      'profileBoost': profileBoost,
      'adFree': adFree,
    };
  }
}

class VisitorLimitations {
  final int dailyMessageLimit;
  final int dailyProfileViewLimit;
  final int messagesSentToday;
  final int profileViewsToday;
  final DateTime? lastResetDate;

  VisitorLimitations({
    this.dailyMessageLimit = 5,
    this.dailyProfileViewLimit = 10,
    this.messagesSentToday = 0,
    this.profileViewsToday = 0,
    this.lastResetDate,
  });

  factory VisitorLimitations.fromJson(Map<String, dynamic> json) {
    return VisitorLimitations(
      dailyMessageLimit: json['dailyMessageLimit'] ?? 5,
      dailyProfileViewLimit: json['dailyProfileViewLimit'] ?? 10,
      messagesSentToday: json['messagesSentToday'] ?? 0,
      profileViewsToday: json['profileViewsToday'] ?? 0,
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.parse(json['lastResetDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyMessageLimit': dailyMessageLimit,
      'dailyProfileViewLimit': dailyProfileViewLimit,
      'messagesSentToday': messagesSentToday,
      'profileViewsToday': profileViewsToday,
      'lastResetDate': lastResetDate?.toIso8601String(),
    };
  }

  bool get canSendMessage => messagesSentToday < dailyMessageLimit;
  bool get canViewProfile => profileViewsToday < dailyProfileViewLimit;

  int get remainingMessages => dailyMessageLimit - messagesSentToday;
  int get remainingProfileViews => dailyProfileViewLimit - profileViewsToday;
}

enum UserMode {
  visitor,
  regular,
  vip;

  static UserMode fromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'visitor':
        return UserMode.visitor;
      case 'regular':
        return UserMode.regular;
      case 'vip':
        return UserMode.vip;
      default:
        return UserMode.regular;
    }
  }

  String toJson() => name;
}

enum VipPlan {
  monthly,
  quarterly,
  yearly;

  static VipPlan fromString(String plan) {
    switch (plan.toLowerCase()) {
      case 'monthly':
        return VipPlan.monthly;
      case 'quarterly':
        return VipPlan.quarterly;
      case 'yearly':
        return VipPlan.yearly;
      default:
        return VipPlan.monthly;
    }
  }

  String toJson() => name;

  double get price {
    switch (this) {
      case VipPlan.monthly:
        return 9.99;
      case VipPlan.quarterly:
        return 24.99;
      case VipPlan.yearly:
        return 79.99;
    }
  }

  String get displayName {
    switch (this) {
      case VipPlan.monthly:
        return 'Monthly';
      case VipPlan.quarterly:
        return 'Quarterly';
      case VipPlan.yearly:
        return 'Yearly';
    }
  }

  String get description {
    switch (this) {
      case VipPlan.monthly:
        return '\$9.99/month';
      case VipPlan.quarterly:
        return '\$24.99/3 months (Save 17%)';
      case VipPlan.yearly:
        return '\$79.99/year (Save 33%)';
    }
  }
}
