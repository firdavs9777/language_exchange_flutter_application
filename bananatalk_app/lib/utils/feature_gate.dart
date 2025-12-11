import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/models/user_limits.dart';
import 'package:bananatalk_app/providers/provider_models/users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/visitor_limit_dialog.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';

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

  /// Show limit reached dialog
  static Future<void> showLimitReachedDialog({
    required BuildContext context,
    required User user,
    required String limitType,
    UserLimits? limits,
    String? errorMessage,
  }) async {
    // Import limit_exceeded_dialog (will be created next)
    // For now, use the existing visitor dialog as fallback
    if (user.isVisitor && user.visitorLimitations != null) {
      await VisitorLimitDialog.show(
        context: context,
        userId: '', // You'll need to pass the actual userId
        limitType: limitType,
        limitations: user.visitorLimitations!,
      );
    } else {
      // Show upgrade dialog for regular users who hit limits
      await _showUpgradeDialog(context, limitType, errorMessage);
    }
  }

  static Future<void> _showUpgradeDialog(
    BuildContext context,
    String limitType,
    String? errorMessage,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: Text(
          errorMessage ??
              'You have reached your daily $limitType limit. Upgrade to VIP for unlimited access!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VipPlansScreen(userId: ''),
                ),
              );
            },
            child: const Text('Upgrade to VIP'),
          ),
        ],
      ),
    );
  }

  /// Wrap a widget with feature gate logic
  static Widget wrapWithFeatureGate({
    required BuildContext context,
    required User user,
    required String feature,
    required Widget child,
    Widget? lockedWidget,
  }) {
    bool hasAccess = false;

    switch (feature) {
      case 'sendMessage':
        hasAccess = canSendMessage(user);
        break;
      case 'createMoment':
        hasAccess = canCreateMoment(user);
        break;
      case 'createStory':
        hasAccess = canCreateStory(user);
        break;
      case 'createComment':
        hasAccess = canCreateComment(user);
        break;
      case 'viewProfile':
        hasAccess = canViewProfile(user);
        break;
      default:
        hasAccess = hasVipFeature(user, feature);
    }

    if (hasAccess) {
      return child;
    }

    return lockedWidget ??
        _buildLockedFeature(
          context: context,
          feature: feature,
          user: user,
        );
  }

  /// Build a locked feature widget
  static Widget _buildLockedFeature({
    required BuildContext context,
    required String feature,
    required User user,
  }) {
    String message;
    IconData icon;

    if (user.isVisitor) {
      message = 'Upgrade to unlock this feature';
      icon = Icons.lock_outline;
    } else {
      message = 'VIP only feature';
      icon = Icons.workspace_premium;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VipPlansScreen(
                    userId: '', // You'll need to pass the actual userId
                  ),
                ),
              );
            },
            child: Text(user.isVisitor ? 'Upgrade Now' : 'Go VIP'),
          ),
        ],
      ),
    );
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
  Widget get modeBadge {
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
                'Visitor',
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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 12, color: Colors.blue),
              SizedBox(width: 4),
              Text(
                'Member',
                style: TextStyle(
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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 12, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'VIP',
                style: TextStyle(
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
