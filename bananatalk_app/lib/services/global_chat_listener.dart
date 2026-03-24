import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        
        // Get updated count for logging
        final chatState = _ref!.read(chatPartnersProvider);
        final newCount = chatState.unreadCounts[senderId] ?? 0;
      }).catchError((error) {
      });
    } catch (e, stackTrace) {
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
      final count = data['count'];

      if (readBy != null && readBy.isNotEmpty) {
        // readBy = the user who read our messages
        // This is for read receipts (double blue ticks), not for clearing our unread count
        // Our unread count is cleared when WE open a chat, not when someone reads our messages

        // Note: We could broadcast this to active chat screens for UI updates (blue ticks)
        // But we should NOT clear our unread count here - that's handled when we open chats
      } else {
      }
    } catch (e, stackTrace) {
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

