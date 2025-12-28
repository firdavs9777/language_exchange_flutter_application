// lib/services/chat_socket_state_manager.dart
import 'dart:async';

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
        print('🔔 ChatSocketStateManager: Received new message event');
        print('   Data type: ${data.runtimeType}');
        print('   Data: $data');
        
        if (data is Map) {
          final type = data['type'];

          if (type == 'deleted') {
            print('   Type: deleted');
            onMessageDeleted?.call(data['data']);
          } else if (type == 'edited') {
            print('   Type: edited');
            final messageData = data['data']['message'] ?? data['data'];
            if (messageData is Map) {
              final message = Message.fromJson(
                Map<String, dynamic>.from(messageData),
              );
              onMessageEdited?.call(message);
            }
          } else {
            print('   Type: new message');
            final messageData = data['message'] ?? data;
            print('   Message data: $messageData');
            
            if (messageData is Map) {
              try {
                final message = Message.fromJson(
                  Map<String, dynamic>.from(messageData),
                );
                print('   Parsed message - From: ${message.sender.id}, To: ${message.receiver.id}');
                print('   Is relevant: ${_isRelevantMessage(message)}');
                print('   Partner ID: $chatPartnerId, Current User ID: $currentUserId');
                
                if (_isRelevantMessage(message)) {
                  print('   ✅ Calling onNewMessage callback');
                  onNewMessage?.call(message);
                } else {
                  print('   ⚠️ Message not relevant for this chat');
                }
              } catch (e, stackTrace) {
                print('❌ Error parsing message to Message object: $e');
                print('   Stack trace: $stackTrace');
              }
            } else {
              print('   ⚠️ Message data is not a Map: ${messageData.runtimeType}');
            }
          }
        } else {
          print('   ⚠️ Data is not a Map: ${data.runtimeType}');
        }
      } catch (e, stackTrace) {
        print('❌ Error parsing message: $e');
        print('   Stack trace: $stackTrace');
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
        print('❌ Error parsing sent message: $e');
      }
    });

    // Typing indicators
    _typingSub = _socketService.onTyping.listen((data) {
      final userId = data is Map ? (data['userId'] ?? data['user']) : null;
      final isTyping = data is Map ? (data['isTyping'] ?? true) : true;

      if (userId == chatPartnerId) {
        onTypingChanged?.call(isTyping);
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
  }
}
