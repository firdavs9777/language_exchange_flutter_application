import 'package:flutter/material.dart';
import 'package:bananatalk_app/router/app_router.dart';

class NotificationRouter {
  /// Handle notification tap and navigate to appropriate screen
  /// Uses goRouter directly to avoid context mounting issues
  static void handleNotification(
    BuildContext? context,
    Map<String, dynamic> data,
  ) {
    final type = data['type']?.toString() ?? '';

    debugPrint('🔔 Handling notification tap: type=$type, data=$data');

    try {
      // First ensure we're on home, then push the target screen
      // This gives us a proper back stack with back button
      switch (type) {
        case 'chat_message':
          final senderId = data['senderId']?.toString();
          if (senderId != null) {
            debugPrint('📱 Navigating to chat: senderId=$senderId');
            // Go to home first, then push chat (gives back button)
            goRouter.go('/home');
            goRouter.push('/chat/$senderId');
          } else {
            debugPrint('⚠️ Missing senderId for chat navigation');
            goRouter.go('/home');
          }
          break;

        case 'moment_like':
        case 'moment_comment':
          final momentId = data['momentId']?.toString();
          if (momentId != null) {
            debugPrint('📱 Navigating to moment: momentId=$momentId');
            goRouter.go('/home');
            goRouter.push('/moment/$momentId');
          } else {
            debugPrint('⚠️ Missing momentId for moment navigation');
            goRouter.go('/home');
          }
          break;

        case 'friend_request':
        case 'profile_visit':
          final userId = data['userId']?.toString();
          if (userId != null) {
            debugPrint('📱 Navigating to profile: userId=$userId');
            goRouter.go('/home');
            goRouter.push('/profile/$userId');
          } else {
            debugPrint('⚠️ Missing userId for profile navigation');
            goRouter.go('/home');
          }
          break;

        case 'follower_moment':
          // When someone you follow posts a moment
          final momentId = data['momentId']?.toString();
          final userId = data['userId']?.toString();
          if (momentId != null) {
            debugPrint('📱 Navigating to follower moment: momentId=$momentId, userId=$userId');
            goRouter.go('/home');
            goRouter.push('/moment/$momentId');
          } else {
            debugPrint('⚠️ Missing momentId for follower moment navigation');
            goRouter.go('/home');
          }
          break;

        case 'system':
          debugPrint('📱 Navigating to home screen');
          goRouter.go('/home');
          break;

        default:
          debugPrint('⚠️ Unknown notification type: $type');
          goRouter.go('/home');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification: $e');
      try {
        goRouter.go('/home');
      } catch (navError) {
        debugPrint('❌ Error navigating to home: $navError');
      }
    }
  }
}
