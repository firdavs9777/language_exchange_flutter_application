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

    try {
      String? targetPath;

      switch (type) {
        case 'chat_message':
          final senderId = data['senderId']?.toString();
          if (senderId != null) targetPath = '/chat/$senderId';
          break;

        case 'moment_like':
        case 'moment_comment':
        case 'follower_moment':
          final momentId = data['momentId']?.toString();
          if (momentId != null) targetPath = '/moment/$momentId';
          break;

        case 'friend_request':
        case 'profile_visit':
          final userId = data['userId']?.toString();
          if (userId != null) targetPath = '/profile/$userId';
          break;
      }

      // Navigate to home first, then push the target screen after
      // a frame delay to ensure the home route is fully settled.
      // This creates a proper back stack so the back button works.
      goRouter.go('/home');
      if (targetPath != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          goRouter.push(targetPath!);
        });
      }
    } catch (e) {
      try {
        goRouter.go('/home');
      } catch (navError) {
      }
    }
  }
}
