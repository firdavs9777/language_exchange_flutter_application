import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';
import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/router/app_router.dart';

class NotificationRouter {
  /// Handle notification tap and navigate to appropriate screen
  /// Uses goRouter directly to avoid context mounting issues
  static Future<void> handleNotification(
    BuildContext? context,
    Map<String, dynamic> data,
  ) async {
    final type = data['type']?.toString() ?? '';

    // ---- Action-button branching (iOS categories / Android actions) ----
    // `_actionId` and `_input` are injected by NotificationService when a
    // local-notification action is fired. They are not present on plain taps
    // or on FCM message-opened events, in which case actionId is null and we
    // fall through to default type-based routing.
    final actionId = data['_actionId'] as String?;
    if (actionId == 'reply') {
      // Inline reply from notification text input — send via API and skip
      // navigation so the user stays in their previous app/context. iOS
      // brings the app to foreground (foreground option); Android stays in
      // background.
      final replyText = (data['_input'] as String?)?.trim();
      final senderId = data['senderId']?.toString();
      if (replyText != null && replyText.isNotEmpty && senderId != null) {
        try {
          await NotificationApiClient().sendQuickReply(
            receiverId: senderId,
            message: replyText,
          );
        } catch (e) {
          debugPrint('❌ Failed to send quick reply: $e');
        }
      }
      return;
    }
    if (actionId == 'profile') {
      final userId = (data['actorId'] ?? data['senderId'] ?? data['userId'])
          ?.toString();
      if (userId != null && userId.isNotEmpty) {
        goRouter.go('/profile/$userId');
      } else {
        goRouter.go('/home');
      }
      return;
    }
    // 'view' falls through to default type-based routing below — same as a
    // plain tap. Any other unknown actionId likewise falls through.

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

        case 'incoming_call':
          debugPrint('📞 Incoming call notification tapped');
          _handleIncomingCallNotification(data);
          return;

        case 'missed_call':
          // Navigate to chat with the caller
          final callerId = data['callerId']?.toString();
          if (callerId != null) targetPath = '/chat/$callerId';
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

  /// Handle incoming call notification tap.
  /// If CallManager already has an active incoming call (socket reconnected),
  /// show the IncomingCallScreen. Otherwise, build a CallModel from the
  /// notification payload and display it.
  static void _handleIncomingCallNotification(Map<String, dynamic> data) {
    final callManager = CallManager();

    // If CallManager already has an active call from the socket, use that
    if (callManager.currentCall != null &&
        callManager.currentCall!.status == CallStatus.ringing) {
      _showIncomingCallScreen(callManager.currentCall!);
      return;
    }

    // Build CallModel from notification payload for terminated-app case
    final callId = data['callId']?.toString() ?? '';
    final callerId = data['callerId']?.toString() ?? '';
    final callerName = data['callerName']?.toString() ?? 'Unknown';
    final callerProfilePicture = data['callerProfilePicture']?.toString() ?? data['callerAvatar']?.toString();
    final callTypeStr = data['callType']?.toString() ?? 'audio';

    if (callId.isEmpty) {
      // No valid call data — just go home
      goRouter.go('/home');
      return;
    }

    final call = CallModel(
      callId: callId,
      userId: callerId,
      userName: callerName,
      userProfilePicture: callerProfilePicture,
      callType: callTypeStr == 'video' ? CallType.video : CallType.audio,
      direction: CallDirection.incoming,
      status: CallStatus.ringing,
      startTime: DateTime.now(),
    );

    // Store in CallManager so accept/reject socket events work
    callManager.currentCall = call;
    callManager.startRingtone();

    _showIncomingCallScreen(call);
  }

  static void _showIncomingCallScreen(CallModel call) {
    final navState = callOverlayNavigatorKey.currentState;
    if (navState != null) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(call: call),
          fullscreenDialog: true,
        ),
      );
    } else {
      debugPrint('❌ Cannot show incoming call screen — no overlay navigator');
      goRouter.go('/home');
    }
  }
}
