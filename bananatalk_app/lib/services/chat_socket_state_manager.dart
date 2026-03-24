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
  StreamSubscription? _reactionSub;
  StreamSubscription? _correctionSub;

  // Typing timeout - auto-clear after 6 seconds (backend times out at 5s)
  Timer? _typingTimeout;
  static const _typingTimeoutDuration = Duration(seconds: 6);

  // Periodic status refresh timer - keeps online status accurate
  Timer? _statusRefreshTimer;
  static const _statusRefreshInterval = Duration(seconds: 30);

  // State callbacks
  Function(bool)? onConnectionChanged;
  Function(Message)? onNewMessage;
  Function(Map<String, dynamic>)? onMessageDeleted;
  Function(Message)? onMessageEdited;
  Function(String messageId, bool isPinned)? onMessagePinned;
  Function(bool)? onTypingChanged;
  Function(bool, String?)? onStatusChanged;
  Function(List<String>)? onMessagesRead;
  Function(String messageId, List<dynamic> reactions)? onReactionUpdated;
  Function(String messageId, Map<String, dynamic> correction)? onCorrectionReceived;

  ChatSocketStateManager({
    required this.chatPartnerId,
    required this.currentUserId,
  });

  Future<void> initialize() async {
    await _socketService.connect();
    _setupSubscriptions();
    requestUserStatus();
    _startStatusRefreshTimer();

    // Immediately notify of current connection state
    // This prevents showing "connecting" if socket is already connected
    if (_socketService.isConnected) {
      onConnectionChanged?.call(true);
    }
  }

  void _startStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(_statusRefreshInterval, (_) {
      if (_socketService.isConnected) {
        requestUserStatus();
      }
    });
  }

  void _setupSubscriptions() {
    // Connection state
    _connectionSub = _socketService.onConnectionStateChange.listen((
      isConnected,
    ) {
      onConnectionChanged?.call(isConnected);
      // All reconnect actions (requestStatus, markAsRead) are handled by
      // ChatStateNotifier which checks if THIS is the active chat first
    });

    // New messages
    _newMessageSub = _socketService.onNewMessage.listen((data) {
      try {
        
        if (data is Map) {
          final type = data['type'];

          if (type == 'deleted') {
            onMessageDeleted?.call(data['data']);
          } else if (type == 'edited') {
            final messageData = data['data']['message'] ?? data['data'];
            if (messageData is Map) {
              final message = Message.fromJson(
                Map<String, dynamic>.from(messageData),
              );
              onMessageEdited?.call(message);
            }
          } else if (type == 'pinned') {
            final pinnedData = data['data'];
            if (pinnedData is Map) {
              final messageId = pinnedData['messageId']?.toString();
              final isPinned = pinnedData['pinned'] == true;
              if (messageId != null) {
                onMessagePinned?.call(messageId, isPinned);
              }
            }
          } else {
            final messageData = data['message'] ?? data;
            
            if (messageData is Map) {
              try {
              final message = Message.fromJson(
                Map<String, dynamic>.from(messageData),
              );
                
              if (_isRelevantMessage(message)) {
                onNewMessage?.call(message);
                } else {
                }
              } catch (e, stackTrace) {
              }
            } else {
              }
            }
        } else {
        }
      } catch (e, stackTrace) {
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
          // Single user status update (userStatusUpdate event)
          final statusData = data['single'];
          if (statusData['userId'] == chatPartnerId) {
            final isOnline = statusData['status'] == 'online';
            final lastSeen = statusData['lastSeen']?.toString();
            onStatusChanged?.call(isOnline, lastSeen);
          }
        } else if (data['type'] == 'onlineUsers' && data['data'] is List) {
          // Online users list (onlineUsers event)
          final users = data['data'] as List;
          final partnerData = users.firstWhere(
            (user) => user is Map && user['userId'] == chatPartnerId,
            orElse: () => null,
          );
          if (partnerData != null) {
            final isOnline = partnerData['status'] == 'online';
            final lastSeen = partnerData['lastSeen']?.toString();
            onStatusChanged?.call(isOnline, lastSeen);
          } else {
            // Partner not in online list = offline
            onStatusChanged?.call(false, null);
          }
        } else if (data.containsKey(chatPartnerId)) {
          // Bulk status update (bulkStatusUpdate event)
          // Format: { "userId": { status, lastSeen, deviceCount } }
          final statusData = data[chatPartnerId];
          if (statusData is Map) {
            final isOnline = statusData['status'] == 'online';
            final lastSeen = statusData['lastSeen']?.toString();
            onStatusChanged?.call(isOnline, lastSeen);
          }
        }
      }
    });

    // Read receipts
    _messageReadSub = _socketService.onMessageRead.listen((data) {
      if (data is Map && data['readBy'] == chatPartnerId) {
        onMessagesRead?.call([chatPartnerId]);
      }
    });

    // Reaction updates (real-time)
    _reactionSub = _socketService.onMessageReaction.listen((data) {
      if (data is Map) {
        final messageId = data['messageId']?.toString();
        final reactions = data['reactions'] as List?;
        if (messageId != null && reactions != null) {
          onReactionUpdated?.call(messageId, reactions);
        }
      }
    });

    // Correction updates (real-time, Tandem-style)
    _correctionSub = _socketService.onMessageCorrection.listen((data) {
      if (data is Map) {
        final messageId = data['messageId']?.toString();
        final correction = data['correction'];
        if (messageId != null && correction is Map<String, dynamic>) {
          onCorrectionReceived?.call(messageId, correction);
        }
      }
    });
  }

  bool _isRelevantMessage(Message message) {
    return (message.sender.id == chatPartnerId &&
            message.receiver.id == currentUserId) ||
        (message.sender.id == currentUserId &&
            message.receiver.id == chatPartnerId);
  }

  void requestUserStatus() {
    _socketService.requestStatusUpdates([chatPartnerId]);
  }

  void markAsRead() {
    _socketService.markAsRead(chatPartnerId, currentUserId);
  }

  void sendTyping(bool isTyping) {
    _socketService.sendTypingIndicator(chatPartnerId, isTyping);
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    // If socket is disconnected, try to reconnect before sending
    if (!_socketService.isConnected) {
      await _socketService.connect(forceReset: true);
      // Wait briefly for connection to establish
      if (!_socketService.isConnected) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      if (!_socketService.isConnected) {
        return {'status': 'error', 'error': 'Unable to connect to server'};
      }
    }
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
    _reactionSub?.cancel();
    _correctionSub?.cancel();
    _typingTimeout?.cancel();
    _statusRefreshTimer?.cancel();
  }
}
