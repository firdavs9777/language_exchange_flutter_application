class VipSubscription {
  final String id;
  final String plan;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool autoRenew;
  final String? paymentMethod;
  final DateTime? lastPaymentDate;
  final DateTime? nextBillingDate;
  final double? amount;
  final String? status;

  VipSubscription({
    required this.id,
    required this.plan,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.autoRenew = true,
    this.paymentMethod,
    this.lastPaymentDate,
    this.nextBillingDate,
    this.amount,
    this.status,
  });

  factory VipSubscription.fromJson(Map<String, dynamic> json) {
    return VipSubscription(
      id: json['_id'] ?? json['id'] ?? '',
      plan: json['plan'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      isActive: json['isActive'] ?? json['status'] == 'active' ?? true,
      autoRenew: json['autoRenew'] ?? true,
      paymentMethod: json['paymentMethod'],
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'])
          : null,
      nextBillingDate: json['nextBillingDate'] != null
          ? DateTime.parse(json['nextBillingDate'])
          : null,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'plan': plan,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'paymentMethod': paymentMethod,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'nextBillingDate': nextBillingDate?.toIso8601String(),
      'amount': amount,
      'status': status,
    };
  }
}

class VipFeatures {
  final bool unlimitedMessages;
  final bool unlimitedMoments;
  final bool unlimitedStories;
  final bool unlimitedComments;
  final bool unlimitedProfileViews;
  final bool prioritySupport;
  final bool advancedSearch;
  final bool translationFeature;
  final bool customBadge;
  final bool profileBoost;
  final bool adFree;

  VipFeatures({
    this.unlimitedMessages = false,
    this.unlimitedMoments = false,
    this.unlimitedStories = false,
    this.unlimitedComments = false,
    this.unlimitedProfileViews = false,
    this.prioritySupport = false,
    this.advancedSearch = false,
    this.translationFeature = false,
    this.customBadge = false,
    this.profileBoost = false,
    this.adFree = false,
  });

  factory VipFeatures.fromJson(Map<String, dynamic> json) {
    return VipFeatures(
      unlimitedMessages: json['unlimitedMessages'] ?? false,
      unlimitedMoments: json['unlimitedMoments'] ?? false,
      unlimitedStories: json['unlimitedStories'] ?? false,
      unlimitedComments: json['unlimitedComments'] ?? false,
      unlimitedProfileViews: json['unlimitedProfileViews'] ?? false,
      prioritySupport: json['prioritySupport'] ?? false,
      advancedSearch: json['advancedSearch'] ?? false,
      translationFeature: json['translationFeature'] ?? false,
      customBadge: json['customBadge'] ?? false,
      profileBoost: json['profileBoost'] ?? false,
      adFree: json['adFree'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlimitedMessages': unlimitedMessages,
      'unlimitedMoments': unlimitedMoments,
      'unlimitedStories': unlimitedStories,
      'unlimitedComments': unlimitedComments,
      'unlimitedProfileViews': unlimitedProfileViews,
      'prioritySupport': prioritySupport,
      'advancedSearch': advancedSearch,
      'translationFeature': translationFeature,
      'customBadge': customBadge,
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
