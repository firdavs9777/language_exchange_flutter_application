import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationRouter {
  /// Handle notification tap and navigate to appropriate screen
  static void handleNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    if (!context.mounted) return;

    final type = data['type']?.toString() ?? '';

    debugPrint('🔔 Handling notification tap: type=$type, data=$data');

    try {
      switch (type) {
        case 'chat_message':
          final senderId = data['senderId']?.toString();
          if (senderId != null) {
            debugPrint('📱 Navigating to chat: senderId=$senderId');
            context.go('/chat/$senderId');
          } else {
            debugPrint('⚠️ Missing senderId for chat navigation');
            context.go('/home');
          }
          break;

        case 'moment_like':
        case 'moment_comment':
          final momentId = data['momentId']?.toString();
          if (momentId != null) {
            debugPrint('📱 Navigating to moment: momentId=$momentId');
            context.go('/moment/$momentId');
          } else {
            debugPrint('⚠️ Missing momentId for moment navigation');
            context.go('/home');
          }
          break;

        case 'friend_request':
        case 'profile_visit':
          final userId = data['userId']?.toString();
          if (userId != null) {
            debugPrint('📱 Navigating to profile: userId=$userId');
            context.go('/profile/$userId');
          } else {
            debugPrint('⚠️ Missing userId for profile navigation');
            context.go('/home');
          }
          break;

        case 'follower_moment':
          // When someone you follow posts a moment
          final momentId = data['momentId']?.toString();
          final userId = data['userId']?.toString();
          if (momentId != null) {
            debugPrint('📱 Navigating to follower moment: momentId=$momentId, userId=$userId');
            context.go('/moment/$momentId');
          } else {
            debugPrint('⚠️ Missing momentId for follower moment navigation');
            context.go('/home');
          }
          break;

        case 'system':
          debugPrint('📱 Navigating to home screen');
          context.go('/home');
          break;

        default:
          debugPrint('⚠️ Unknown notification type: $type');
          context.go('/home');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification: $e');
      try {
        context.go('/home');
      } catch (navError) {
        debugPrint('❌ Error navigating to home: $navError');
      }
    }
  }
}
