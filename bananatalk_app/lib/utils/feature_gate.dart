import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/models/user_limits.dart';
import 'package:bananatalk_app/providers/provider_models/users_model.dart';

class FeatureGate {
  /// Check if user can send a message
  static bool canSendMessage(dynamic user, [UserLimits? limits]) {
    // If limits provided, use them (primary check)
    if (limits != null) {
      if (limits.isVIP) return true;
      return limits.canSendMessage();
    }
    
    // Fallback to user model properties
    if (user is User) {
      if (user.isVip) return true;
      if (user.isRegular) return true;
      if (user.isVisitor && user.visitorLimitations != null) {
        return user.visitorLimitations!.canSendMessage;
      }
    }
    
    // For Community or unknown types, allow if no limits provided (fail open)
    return true;
  }

  /// Check if user can create a moment
  static bool canCreateMoment(dynamic user, [UserLimits? limits]) {
    // If limits provided, use them (primary check)
    if (limits != null) {
      if (limits.isVIP) return true;
      return limits.canCreateMoment();
    }
    
    // Fallback to user model properties
    if (user is User) {
      if (user.isVip) return true;
      if (user.isRegular) return true;
      if (user.isVisitor) return false; // Visitors cannot create moments
    }
    
    // For Community or unknown types, allow if no limits provided (fail open)
    return true;
  }

  /// Check if user can create a story
  static bool canCreateStory(dynamic user, [UserLimits? limits]) {
    // If limits provided, use them (primary check)
    if (limits != null) {
      if (limits.isVIP) return true;
      return limits.canCreateStory();
    }
    
    // Fallback to user model properties
    if (user is User) {
      if (user.isVip) return true;
      if (user.isRegular) return true;
      if (user.isVisitor) return false; // Visitors cannot create stories
    }
    
    // For Community or unknown types, allow if no limits provided (fail open)
    return true;
  }

  /// Check if user can create a comment
  static bool canCreateComment(dynamic user, [UserLimits? limits]) {
    // If limits provided, use them (primary check)
    if (limits != null) {
      if (limits.isVIP) return true;
      return limits.canCreateComment();
    }
    
    // Fallback to user model properties
    if (user is User) {
      if (user.isVip) return true;
      if (user.isRegular) return true;
      if (user.isVisitor) return false; // Visitors cannot create comments
    }
    
    // For Community or unknown types, allow if no limits provided (fail open)
    return true;
  }

  /// Check if user can view a profile
  static bool canViewProfile(dynamic user, [UserLimits? limits]) {
    // If limits provided, use them (primary check)
    if (limits != null) {
      if (limits.isVIP) return true;
      return limits.canViewProfile();
    }
    
    // Fallback to user model properties
    if (user is User) {
      if (user.isVip) return true;
      if (user.isRegular) return true;
      if (user.isVisitor && user.visitorLimitations != null) {
        return user.visitorLimitations!.canViewProfile;
      }
    }
    
    // For Community or unknown types, allow if no limits provided (fail open)
    return true;
  }

  /// Check if user has access to a VIP feature
  static bool hasVipFeature(User user, String featureName) {
    if (!user.isVip) return false;
    if (user.vipFeatures == null) return false;

    switch (featureName) {
      case 'unlimitedMessages':
        return user.vipFeatures!.unlimitedMessages;
      case 'unlimitedProfileViews':
        return user.vipFeatures!.unlimitedProfileViews;
      case 'prioritySupport':
        return user.vipFeatures!.prioritySupport;
      case 'advancedSearch':
        return user.vipFeatures!.advancedSearch;
      case 'profileBoost':
        return user.vipFeatures!.profileBoost;
      case 'adFree':
        return user.vipFeatures!.adFree;
      default:
        return false;
    }
  }
}

/// Extension methods for User model
extension UserFeatureExtensions on User {
  /// Get a user-friendly display of their mode
  String get modeDisplayName {
    switch (userMode) {
      case UserMode.visitor:
        return 'Visitor';
      case UserMode.regular:
        return 'Member';
      case UserMode.vip:
        return 'VIP Member';
    }
  }

  /// Get the badge widget for the user mode
  Widget modeBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (userMode) {
      case UserMode.visitor:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                l10n.vipTierVisitor,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      case UserMode.regular:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, size: 12, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                l10n.vipTierMember,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      case UserMode.vip:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                l10n.vip,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Check if user can access a feature
  bool canAccessFeature(String feature) {
    return FeatureGate.hasVipFeature(this, feature);
  }
}
