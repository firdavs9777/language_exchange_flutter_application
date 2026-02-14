// lib/services/chat_socket_state_manager.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

class ChatSocketStateManager {
  final ChatSocketService _socketService = ChatSocketService();
  final String chatPartnerId;
  final String currentUserId;

  // Stream subscriptions
  StreamSubscription? _connectionSub;
  StreamSubscription? _newMessageSub;
  StreamSubscription? _messageSentSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _messageReadSub;

  // Typing timeout - auto-clear after 6 seconds (backend times out at 5s)
  Timer? _typingTimeout;
  static const _typingTimeoutDuration = Duration(seconds: 6);

  // State callbacks
  Function(bool)? onConnectionChanged;
  Function(Message)? onNewMessage;
  Function(Map<String, dynamic>)? onMessageDeleted;
  Function(Message)? onMessageEdited;
  Function(bool)? onTypingChanged;
  Function(bool, String?)? onStatusChanged;
  Function(List<String>)? onMessagesRead;

  ChatSocketStateManager({
    required this.chatPartnerId,
    required this.currentUserId,
  });

  Future<void> initialize() async {
    await _socketService.connect();
    _setupSubscriptions();
    _requestUserStatus();
  }

  void _setupSubscriptions() {
    // Connection state
    _connectionSub = _socketService.onConnectionStateChange.listen((
      isConnected,
    ) {
      onConnectionChanged?.call(isConnected);
      if (isConnected) {
        _requestUserStatus();
      }
    });

    // New messages
    _newMessageSub = _socketService.onNewMessage.listen((data) {
      try {
        debugPrint('🔔 ChatSocketStateManager: Received new message event');
        debugPrint('   Data type: ${data.runtimeType}');
        debugPrint('   Data: $data');
        
        if (data is Map) {
          final type = data['type'];

          if (type == 'deleted') {
            debugPrint('   Type: deleted');
            onMessageDeleted?.call(data['data']);
          } else if (type == 'edited') {
            debugPrint('   Type: edited');
            final messageData = data['data']['message'] ?? data['data'];
            if (messageData is Map) {
              final message = Message.fromJson(
                Map<String, dynamic>.from(messageData),
              );
              onMessageEdited?.call(message);
            }
          } else {
            debugPrint('   Type: new message');
            final messageData = data['message'] ?? data;
            debugPrint('   Message data: $messageData');
            
            if (messageData is Map) {
              try {
              final message = Message.fromJson(
                Map<String, dynamic>.from(messageData),
              );
                debugPrint('   Parsed message - From: ${message.sender.id}, To: ${message.receiver.id}');
                debugPrint('   Is relevant: ${_isRelevantMessage(message)}');
                debugPrint('   Partner ID: $chatPartnerId, Current User ID: $currentUserId');
                
              if (_isRelevantMessage(message)) {
                  debugPrint('   ✅ Calling onNewMessage callback');
                onNewMessage?.call(message);
                } else {
                  debugPrint('   ⚠️ Message not relevant for this chat');
                }
              } catch (e, stackTrace) {
                debugPrint('❌ Error parsing message to Message object: $e');
                debugPrint('   Stack trace: $stackTrace');
              }
            } else {
              debugPrint('   ⚠️ Message data is not a Map: ${messageData.runtimeType}');
              }
            }
        } else {
          debugPrint('   ⚠️ Data is not a Map: ${data.runtimeType}');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error parsing message: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
    });

    // Message sent (multi-device sync)
    _messageSentSub = _socketService.onMessageSent.listen((data) {
      try {
        final messageData = data is Map ? data['message'] : data;
        if (messageData is Map) {
          final message = Message.fromJson(
            Map<String, dynamic>.from(messageData),
          );
          if (_isRelevantMessage(message)) {
            onNewMessage?.call(message);
          }
        }
      } catch (e) {
        debugPrint('❌ Error parsing sent message: $e');
      }
    });

    // Typing indicators with auto-timeout safety
    _typingSub = _socketService.onTyping.listen((data) {
      final userId = data is Map ? (data['userId'] ?? data['user']) : null;
      final isTyping = data is Map ? (data['isTyping'] ?? true) : true;

      if (userId == chatPartnerId) {
        // Cancel existing timeout
        _typingTimeout?.cancel();

        if (isTyping) {
          // Set typing to true and start auto-clear timeout
          onTypingChanged?.call(true);
          _typingTimeout = Timer(_typingTimeoutDuration, () {
            debugPrint('⌨️ Typing timeout - auto-clearing indicator');
            onTypingChanged?.call(false);
          });
        } else {
          // Explicitly stopped typing
          onTypingChanged?.call(false);
        }
      }
    });

    // Status updates
    _statusSub = _socketService.onStatusUpdate.listen((data) {
      if (data is Map) {
        if (data['single'] != null) {
          final statusData = data['single'];
          if (statusData['userId'] == chatPartnerId) {
            final isOnline = statusData['status'] == 'online';
            final lastSeen = statusData['lastSeen'];
            onStatusChanged?.call(isOnline, lastSeen);
          }
        } else if (data['type'] == 'onlineUsers' && data['data'] is List) {
          final users = data['data'] as List;
          final isOnline = users.any(
            (user) =>
                user is Map &&
                user['userId'] == chatPartnerId &&
                user['status'] == 'online',
          );
          onStatusChanged?.call(isOnline, null);
        }
      }
    });

    // Read receipts
    _messageReadSub = _socketService.onMessageRead.listen((data) {
      if (data is Map && data['readBy'] == chatPartnerId) {
        onMessagesRead?.call([chatPartnerId]);
      }
    });
  }

  bool _isRelevantMessage(Message message) {
    return (message.sender.id == chatPartnerId &&
            message.receiver.id == currentUserId) ||
        (message.sender.id == currentUserId &&
            message.receiver.id == chatPartnerId);
  }

  void _requestUserStatus() {
    _socketService.requestStatusUpdates([chatPartnerId]);
  }

  void markAsRead() {
    _socketService.markAsRead(chatPartnerId, currentUserId);
  }

  void sendTyping(bool isTyping) {
    _socketService.sendTypingIndicator(chatPartnerId, isTyping);
  }

  Future<Map<String, dynamic>> sendMessage(String message) {
    return _socketService.sendMessage(
      receiverId: chatPartnerId,
      message: message,
    );
  }

  bool get isConnected => _socketService.isConnected;

  void dispose() {
    _connectionSub?.cancel();
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _typingSub?.cancel();
    _statusSub?.cancel();
    _messageReadSub?.cancel();
    _typingTimeout?.cancel();
  }
}
