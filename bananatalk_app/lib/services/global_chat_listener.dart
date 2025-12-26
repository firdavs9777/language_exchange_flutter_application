import 'dart:async';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
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
      print('🌐 Global chat listener already initialized');
      return;
    }
    
    _ref = ref;
    _isInitialized = true;
    _startListening();
    print('🌐 Global chat listener initialized successfully');
  }

  /// Start listening to socket events
  void _startListening() {
    if (_ref == null) {
      print('❌ Global chat listener: Ref is null, cannot start listening');
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
        print('❌ Global listener error on newMessage stream: $error');
      },
    );

    // Listen to read receipts
    _messageReadSub = _chatSocketService.onMessageRead.listen(
      (data) {
        _handleMessageRead(data);
      },
      onError: (error) {
        print('❌ Global listener error on messageRead stream: $error');
      },
    );

    print('🌐 Global chat listener started listening to socket events');
    print('🌐 Socket connected: ${_chatSocketService.isConnected}');
  }

  /// Handle new message events
  void _handleNewMessage(dynamic data) {
    if (_ref == null) {
      print('❌ Global listener: Ref is null, cannot handle new message');
      return;
    }

    try {
      print('🌐 Global listener: Received new message event: $data');

      if (data == null) {
        print('⚠️ Global listener: Message data is null');
        return;
      }

      // Handle deleted messages
      if (data['type'] == 'deleted') {
        print('ℹ️ Global listener: Message deletion event, skipping');
        return;
      }

      // Extract message from the data structure
      final messageData = data['message'] ?? data;

      // Extract sender info
      final senderId = messageData['sender']?['_id']?.toString() ??
          messageData['sender']?.toString();

      if (senderId == null || senderId.isEmpty) {
        print('⚠️ Global listener: No sender ID found in message');
        return;
      }

      // Get current user ID synchronously using a future
      SharedPreferences.getInstance().then((prefs) {
        final currentUserId = prefs.getString('userId');

        // Don't process own messages
        if (senderId == currentUserId) {
          print('ℹ️ Global listener: Ignoring own message from $senderId');
          return;
        }

        if (_ref == null) {
          print('❌ Global listener: Ref became null during async operation');
          return;
        }

        // Increment unread count - this will automatically update badgeCountProvider
        _ref!.read(chatPartnersProvider.notifier).incrementUnread(senderId);
        
        // Get updated count for logging
        final chatState = _ref!.read(chatPartnersProvider);
        final newCount = chatState.unreadCounts[senderId] ?? 0;
        print('🌐 Global listener: ✅ Incremented unread count for $senderId -> $newCount (Total: ${chatState.totalUnread})');
      }).catchError((error) {
        print('❌ Global listener: Error getting current user ID: $error');
      });
    } catch (e, stackTrace) {
      print('❌ Global listener error handling new message: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Handle message read events
  void _handleMessageRead(dynamic data) {
    if (_ref == null) {
      print('❌ Global listener: Ref is null, cannot handle message read');
      return;
    }

    try {
      print('🌐 Global listener: Received message read event: $data');

      final readBy = data['readBy']?.toString();
      final readerId = data['readerId']?.toString(); // The user who read the messages

      if (readBy != null && readBy.isNotEmpty) {
        // Clear unread count for the chat partner whose messages were read
        _ref!.read(chatPartnersProvider.notifier).clearUnread(readBy);
        
        // Get updated state for logging
        final chatState = _ref!.read(chatPartnersProvider);
        print('🌐 Global listener: ✅ Cleared unread count for $readBy (Total: ${chatState.totalUnread})');
      } else if (readerId != null && readerId.isNotEmpty) {
        // Alternative: if 'readBy' is not present but 'readerId' is
        // This means messages sent by 'readerId' were read by someone else
        // In this case, we might want to clear unread for the reader, not the sender
        print('ℹ️ Global listener: Received readerId $readerId but no readBy field');
      } else {
        print('⚠️ Global listener: No readBy or readerId in message read event');
      }
    } catch (e, stackTrace) {
      print('❌ Global listener error handling message read: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Stop listening (call on logout)
  void stop() {
    _newMessageSub?.cancel();
    _messageReadSub?.cancel();
    _newMessageSub = null;
    _messageReadSub = null;
    _isInitialized = false;
    print('🌐 Global chat listener stopped');
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

