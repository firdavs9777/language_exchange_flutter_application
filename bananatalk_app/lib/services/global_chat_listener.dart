import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/chat/list/list_socket_handlers.dart' show extractMessagePreview;
import 'package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey, goRouter;
import 'package:bananatalk_app/widgets/in_app_message_banner.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';

/// Global service that listens to socket events and updates unread counts
/// Works independently of UI, so badge updates even when ChatMain isn't visible
class GlobalChatListener {
  static final GlobalChatListener _instance = GlobalChatListener._internal();
  factory GlobalChatListener() => _instance;
  GlobalChatListener._internal();

  final _chatSocketService = ChatSocketService();
  StreamSubscription? _newMessageSub;
  StreamSubscription? _messageReadSub;
  Ref? _ref; // Changed from WidgetRef to Ref to work with Provider context
  bool _isInitialized = false;

  /// Initialize the global listener with Riverpod ref
  void initialize(Ref ref) {
    if (_isInitialized && _ref == ref) {
      return;
    }
    
    _ref = ref;
    _isInitialized = true;
    // Load the muted-chats list now, so the first banner already honours it.
    ref.read(notificationSettingsProvider);
    _startListening();
  }

  /// Start listening to socket events
  void _startListening() {
    if (_ref == null) {
      return;
    }

    // Cancel existing subscriptions
    _newMessageSub?.cancel();
    _messageReadSub?.cancel();

    // Listen to new messages
    _newMessageSub = _chatSocketService.onNewMessage.listen(
      (data) {
        _handleNewMessage(data);
      },
      onError: (error) {
      },
    );

    // Listen to read receipts
    _messageReadSub = _chatSocketService.onMessageRead.listen(
      (data) {
        _handleMessageRead(data);
      },
      onError: (error) {
      },
    );

  }

  void _showBanner(String senderId, dynamic messageData) {
    final overlay = callOverlayNavigatorKey.currentState?.overlay;
    if (overlay == null || messageData is! Map) return;
    final sender = messageData['sender'];
    final name = sender is Map ? (sender['name']?.toString() ?? '') : '';
    if (name.isEmpty) return;
    final avatar = sender is Map ? bannerAvatarFor(sender) : null;
    final preview = extractMessagePreview(messageData);
    InAppMessageBanner.show(
      overlay: overlay,
      senderName: name,
      preview: preview.isEmpty ? '…' : preview,
      avatarUrl: avatar,
      onTap: () => goRouter.push('/chat/$senderId'),
    );
  }

  /// Handle new message events
  void _handleNewMessage(dynamic data) {
    if (_ref == null) {
      return;
    }

    try {

      if (data == null) {
        return;
      }

      // Handle deleted messages
      if (data['type'] == 'deleted') {
        return;
      }

      // Extract message from the data structure
      final messageData = data['message'] ?? data;

      // Extract sender info
      final senderId = messageData['sender']?['_id']?.toString() ??
          messageData['sender']?.toString();

      if (senderId == null || senderId.isEmpty) {
        return;
      }

      // Get current user ID synchronously using a future
      SharedPreferences.getInstance().then((prefs) {
        final currentUserId = prefs.getString('userId');

        // Don't process own messages
        if (senderId == currentUserId) {
          return;
        }

        if (_ref == null) {
          return;
        }

        // Increment unread count - this will automatically update badgeCountProvider
        _ref!.read(chatPartnersProvider.notifier).incrementUnread(senderId);

        // Not in that chat, and the chat is not muted: show an in-app banner
        // (the server sends no push while the socket is connected).
        final conversationId = data is Map ? data['conversationId']?.toString() : null;
        final muted = conversationId != null &&
            _ref!.read(notificationSettingsProvider.notifier).isConversationMuted(conversationId);
        if (shouldShowMessageBanner(
          inThatChat: _ref!.read(chatPartnersProvider).isInChat(senderId),
          muted: muted,
        )) {
          _showBanner(senderId, messageData);
        }
        
      }).catchError((Object error) {
        // Was an empty block: a failed unread increment vanished without trace
        // on the realtime path, which is the worst place to lose an error.
        debugPrint('[globalChatListener] unread increment failed: $error');
      });
    } catch (e) {
      debugPrint('[globalChatListener] new-message handling failed: $e');
    }
  }

  /// Handle message read events
  /// Note: This event means someone READ our messages, NOT that we read theirs
  /// We use this for updating read receipts (blue ticks), not for clearing unread counts
  void _handleMessageRead(dynamic data) {
    if (_ref == null) {
      return;
    }

    try {

      final readBy = data['readBy']?.toString();

      if (readBy != null && readBy.isNotEmpty) {
        // readBy = the user who read our messages
        // This is for read receipts (double blue ticks), not for clearing our unread count
        // Our unread count is cleared when WE open a chat, not when someone reads our messages

        // Note: We could broadcast this to active chat screens for UI updates (blue ticks)
        // But we should NOT clear our unread count here - that's handled when we open chats
      } else {
      }
    } catch (e) {
    }
  }

  /// Stop listening (call on logout)
  void stop() {
    _newMessageSub?.cancel();
    _messageReadSub?.cancel();
    _newMessageSub = null;
    _messageReadSub = null;
    _isInitialized = false;
  }

  /// Dispose
  void dispose() {
    stop();
  }
}

/// Provider to initialize the global listener
/// This ensures the listener is active throughout the app's lifetime
final globalChatListenerProvider = Provider<void>((ref) {
  final listener = GlobalChatListener();
  listener.initialize(ref);
  
  // Keep the listener alive and ensure it stays initialized
  ref.onDispose(() {
    listener.dispose();
  });
  
  return;
});

/// The sender's first photo from a live message's `sender` map. The payload
/// carries `images` (not imageUrls), so it is resolved like everywhere else
/// in the app; the banner showed only initials before (2026-10-18).
String? bannerAvatarFor(Map sender) {
  try {
    final urls = Community.fromJson(Map<String, dynamic>.from(sender)).effectiveImageUrls;
    if (urls.isNotEmpty) return urls.first;
  } catch (_) {}
  final urls = sender['imageUrls'];
  if (urls is List && urls.isNotEmpty) return urls.first?.toString();
  return null;
}

/// The in-app banner shows for a message from another chat, never for the
/// chat you are in or one you muted (2026-10-18).
bool shouldShowMessageBanner({required bool inThatChat, required bool muted}) =>
    !inThatChat && !muted;
