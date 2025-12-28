// lib/providers/chat_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/chat_socket_state_manager.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSocketConnected;
  final bool isOtherUserTyping;
  final bool isOtherUserOnline;
  final String? otherUserLastSeen;
  final String error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSocketConnected = false,
    this.isOtherUserTyping = false,
    this.isOtherUserOnline = false,
    this.otherUserLastSeen,
    this.error = '',
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSocketConnected,
    bool? isOtherUserTyping,
    bool? isOtherUserOnline,
    String? otherUserLastSeen,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
      otherUserLastSeen: otherUserLastSeen ?? this.otherUserLastSeen,
      error: error ?? this.error,
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  final String chatPartnerId;
  final String currentUserId;
  ChatSocketStateManager? _socketManager;

  ChatStateNotifier({
    required this.chatPartnerId,
    required this.currentUserId,
  }) : super(ChatState());

  Future<void> initialize() async {
    _socketManager = ChatSocketStateManager(
      chatPartnerId: chatPartnerId,
      currentUserId: currentUserId,
    );

    _socketManager!.onConnectionChanged = (isConnected) {
      state = state.copyWith(
        isSocketConnected: isConnected,
        error: isConnected ? '' : state.error,
      );
      if (isConnected) {
        _socketManager!.markAsRead();
      }
    };

    _socketManager!.onNewMessage = (message) {
      final messages = List<Message>.from(state.messages);
      if (!messages.any((m) => m.id == message.id)) {
        messages.add(message);
        messages.sort((a, b) => 
          DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt))
        );
        state = state.copyWith(messages: messages);
        _socketManager!.markAsRead();
      }
    };

    _socketManager!.onMessageDeleted = (data) {
      final messageId = data['messageId']?.toString();
      final deletedForEveryone = data['deletedForEveryone'] ?? false;
      
      if (messageId != null) {
        final messages = List<Message>.from(state.messages);
        final index = messages.indexWhere((m) => m.id == messageId);
        
        if (index != -1) {
          if (deletedForEveryone) {
            final json = messages[index].toJson();
            json['isDeleted'] = true;
            json['deletedForEveryone'] = true;
            json['message'] = 'This message was deleted';
            messages[index] = Message.fromJson(json);
          } else {
            messages.removeAt(index);
          }
          state = state.copyWith(messages: messages);
        }
      }
    };

    _socketManager!.onMessageEdited = (message) {
      final messages = List<Message>.from(state.messages);
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = message;
        state = state.copyWith(messages: messages);
      }
    };

    _socketManager!.onTypingChanged = (isTyping) {
      state = state.copyWith(isOtherUserTyping: isTyping);
    };

    _socketManager!.onStatusChanged = (isOnline, lastSeen) {
      state = state.copyWith(
        isOtherUserOnline: isOnline,
        otherUserLastSeen: lastSeen,
      );
    };

    _socketManager!.onMessagesRead = (userIds) {
      final messages = state.messages.map((msg) {
        if (msg.sender.id == currentUserId && !msg.read) {
          final json = msg.toJson();
          json['read'] = true;
          return Message.fromJson(json);
        }
        return msg;
      }).toList();
      state = state.copyWith(messages: messages);
    };

    await _socketManager!.initialize();
  }

  void setMessages(List<Message> messages) {
    state = state.copyWith(messages: messages);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void sendTyping(bool isTyping) {
    _socketManager?.sendTyping(isTyping);
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    if (_socketManager == null) {
      return {'status': 'error', 'error': 'Socket not initialized'};
    }
    return await _socketManager!.sendMessage(message);
  }

  void markAsRead() {
    _socketManager?.markAsRead();
  }

  @override
  void dispose() {
    _socketManager?.dispose();
    super.dispose();
  }
}

// Provider
final chatStateProvider = StateNotifierProvider.family<ChatStateNotifier, ChatState, Map<String, String>>(
  (ref, params) => ChatStateNotifier(
    chatPartnerId: params['chatPartnerId']!,
    currentUserId: params['currentUserId']!,
  ),
);