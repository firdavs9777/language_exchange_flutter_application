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

        // Step 16 — wave deep-link to the conversation.
        case 'wave':
        case 'wave_received':
          final waverId = data['userId']?.toString();
          if (waverId != null && waverId.isNotEmpty) targetPath = '/chat/$waverId';
          break;

        // Step 16 — three previously-silent comment notification types
        // (backend fires them but the Flutter router had no case → tap
        // fell through to home). All deep-link to the moment.
        case 'comment_reply':
        case 'comment_reaction':
        case 'comment_mention':
          final momentId = data['momentId']?.toString();
          if (momentId != null) targetPath = '/moment/$momentId';
          break;

        // Workstream E-core Task 12 Step 1 — room_mention had no router
        // case at all (tap fell through to home). Payload is
        // { type: 'room_mention', userId: senderId, roomId }. There is no
        // GoRoute for a room-by-id today (RoomScreen/VoiceRoomScreen both
        // require a full room object and are reached via Navigator.push
        // from within Community), so the best available deep link is the
        // Community tab (index 1) — same "closest available surface"
        // approach as story_comment/vip_renewal_warning below.
        case 'room_mention':
          targetPath = '/tabs/1';
          break;

        // Workstream E-core Task 12 Step 3 — new follower deep-links to
        // the follower's profile (mirrors friend_request/profile_visit).
        case 'new_follower':
          final followerId = data['userId']?.toString();
          if (followerId != null) targetPath = '/profile/$followerId';
          break;

        // Workstream E-core Task 12 Step 3 — SRS/streak reminders have no
        // per-item id to deep-link to; route to the AI Study tab (index 0,
        // the app's tutor/vocab-review home) so the user lands somewhere
        // actionable instead of the generic home screen.
        case 'srs_review':
        case 'streak_reminder':
          targetPath = '/tabs/0';
          break;

        // Step 16 — forward-compat. No /story route in GoRouter today
        // (stories use Navigator.push). Fall back to the commenter's
        // profile so the tap goes somewhere meaningful.
        case 'story_comment':
          final commenterId = data['commenterId']?.toString();
          if (commenterId != null) targetPath = '/profile/$commenterId';
          break;

        // Step 16 — VIP renewal warning. No /vip route in GoRouter;
        // VisitorUpgradeScreen is reached via Navigator.push only.
        // Tap opens the app to home; push body tells user to renew.
        case 'vip_renewal_warning':
          // intentional fall-through with no targetPath
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

        default:
          // Workstream E-core Task 12 Step 2 — generic fallback: any type
          // without an explicit case above falls through here. If the
          // payload carries a `route`, resolve it to a route that actually
          // exists — pushing an unknown path renders go_router's built-in
          // "page not found" screen (the GoRouter has no errorBuilder), so
          // never push raw backend routes blindly (gate review I1).
          final route = data['route']?.toString();
          if (route != null && route.isNotEmpty) {
            targetPath = _resolveKnownRoute(route);
          }
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

  /// Map a backend-supplied `data.route` onto a route the GoRouter actually
  /// defines. Backend payloads reference paths with no GoRoute (e.g.
  /// `/voicerooms/:id`, `/community?tab=waves`) — map those to their nearest
  /// real destination; pass through paths that match a known route prefix;
  /// return null (stay on home) for anything unrecognized.
  static String? _resolveKnownRoute(String route) {
    // Known backend routes with no matching GoRoute → nearest real tab.
    if (route.startsWith('/voicerooms')) return '/tabs/1'; // Community tab
    if (route.startsWith('/community')) return '/tabs/1';
    // Prefixes that exist in app_router.dart — safe to push as-is.
    const knownPrefixes = [
      '/chat/', '/moment/', '/profile/', '/tabs/', '/matching',
      '/leaderboard', '/call-history', '/exam-study', '/home',
    ];
    for (final prefix in knownPrefixes) {
      if (route == prefix || route.startsWith(prefix)) return route;
    }
    debugPrint('🔔 Unknown notification route "$route" — staying on home');
    return null;
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
    // Step 8 / B5: pre-minted LiveKit fields delivered on the FCM payload by
    // the B1 /calls/initiate endpoint. May be null on legacy payloads — in
    // that case CallManager.acceptCall() falls back to /calls/:id/accept to
    // mint a fresh token.
    final livekitToken = data['livekitToken']?.toString();
    final livekitUrl = data['livekitUrl']?.toString();
    final roomName = data['roomName']?.toString();

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
      livekitToken: livekitToken,
      livekitUrl: livekitUrl,
      roomName: roomName,
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
