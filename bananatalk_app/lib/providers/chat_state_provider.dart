// lib/providers/chat_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/chat_socket_state_manager.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

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
  ChatSocketStateManager? _stateManager;
  bool _isInitialized = false;

  ChatStateNotifier({required this.chatPartnerId, required this.currentUserId})
    : super(ChatState()) {
    print('🎯 ChatStateNotifier created for partner: $chatPartnerId');
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ ChatStateNotifier already initialized');
      return;
    }

    print('🚀 Initializing ChatStateNotifier');
    print('   Partner ID: $chatPartnerId');
    print('   Current User ID: $currentUserId');

    _stateManager = ChatSocketStateManager(
      chatPartnerId: chatPartnerId,
      currentUserId: currentUserId,
    );

    // Setup callbacks
    _stateManager!.onConnectionChanged = (isConnected) {
      print('🔌 Connection changed: $isConnected');
      state = state.copyWith(isSocketConnected: isConnected);
    };

    _stateManager!.onNewMessage = (message) {
      print('📨 NEW MESSAGE RECEIVED!');
      print('   From: ${message.sender.id}');
      print('   To: ${message.receiver.id}');
      print('   Text: ${message.message}');
      print('   Current messages count: ${state.messages.length}');

      final messages = List<Message>.from(state.messages)..add(message);
      messages.sort(
        (a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
      );

      print('   New messages count: ${messages.length}');
      state = state.copyWith(messages: messages);
      print('   ✅ State updated with new message');
    };

    _stateManager!.onMessageDeleted = (data) {
      print('🗑️ Message deleted: $data');
      final messageId = data['messageId'];
      if (messageId != null) {
        final messages = state.messages
            .where((msg) => msg.id != messageId)
            .toList();
        state = state.copyWith(messages: messages);
      }
    };

    _stateManager!.onMessageEdited = (message) {
      print('✏️ Message edited: ${message.id}');
      final messages = state.messages.map((msg) {
        return msg.id == message.id ? message : msg;
      }).toList();
      state = state.copyWith(messages: messages);
    };

    _stateManager!.onTypingChanged = (isTyping) {
      print('⌨️ Typing indicator: $isTyping');
      state = state.copyWith(isOtherUserTyping: isTyping);
    };

    _stateManager!.onStatusChanged = (isOnline, lastSeen) {
      print('📡 Status changed - Online: $isOnline, Last seen: $lastSeen');
      state = state.copyWith(
        isOtherUserOnline: isOnline,
        otherUserLastSeen: lastSeen,
      );
    };

    _stateManager!.onMessagesRead = (messageIds) {
      print('👁️ Messages read: $messageIds');
    };

    await _stateManager!.initialize();
    _isInitialized = true;

    print('✅ ChatStateNotifier initialization complete');
    print('   Socket connected: ${_stateManager!.isConnected}');
  }

  void setMessages(List<Message> messages) {
    print('📝 Setting ${messages.length} messages');
    state = state.copyWith(messages: messages);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String error) {
    print('❌ Error: $error');
    state = state.copyWith(error: error);
  }

  void sendTyping(bool isTyping) {
    if (!_isInitialized || _stateManager == null) {
      print('⚠️ Cannot send typing - not initialized yet');
      return;
    }
    _stateManager!.sendTyping(isTyping);
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    if (!_isInitialized || _stateManager == null) {
      print('⚠️ Cannot send message - not initialized yet');
      return {'status': 'error', 'error': 'Chat not initialized'};
    }
    print('📤 Sending message: "$message"');
    final result = await _stateManager!.sendMessage(message);
    print('📤 Send result: $result');
    
    // If message was sent successfully, add it to state immediately
    // The response has the message in 'message' field, not 'data'
    print('🔍 Checking result status: ${result['status']}');
    if (result['status'] == 'success') {
      print('✅ Status is success, attempting to add message to state');
      try {
        // Try 'message' first (socket response format), then 'data' (API format)
        final messageData = result['message'] ?? result['data'];
        print('🔍 Message data type: ${messageData?.runtimeType}');
        print('🔍 Message data: $messageData');
        
        if (messageData is Map) {
          print('✅ Message data is a Map, parsing...');
          final sentMessage = Message.fromJson(
            Map<String, dynamic>.from(messageData),
          );
          print('📤 Adding sent message to state: ${sentMessage.id}');
          print('   Message text: ${sentMessage.message}');
          print('   Current messages count: ${state.messages.length}');
          
          // Check if message already exists (avoid duplicates)
          final existingIndex = state.messages.indexWhere((m) => m.id == sentMessage.id);
          if (existingIndex == -1) {
            print('✅ Message is new, adding to state');
            final messages = List<Message>.from(state.messages)..add(sentMessage);
            messages.sort(
              (a, b) =>
                  DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
            );
            print('📝 Updating state with ${messages.length} messages');
            state = state.copyWith(messages: messages);
            print('✅ Sent message added to state. Total: ${messages.length}');
          } else {
            print('⚠️ Message already in state at index $existingIndex, skipping');
          }
        } else {
          print('⚠️ Message data is not a Map: ${messageData?.runtimeType}');
          print('   Available keys in result: ${result.keys.toList()}');
        }
      } catch (e, stackTrace) {
        print('❌ Error adding sent message to state: $e');
        print('   Stack trace: $stackTrace');
        // Don't fail the send if we can't add to state - socket event will handle it
      }
    } else {
      print('⚠️ Status is not success: ${result['status']}');
    }
    
    return result;
  }

  void markAsRead() {
    if (!_isInitialized || _stateManager == null) {
      print('⚠️ Cannot mark as read - not initialized yet');
      return;
    }
    _stateManager!.markAsRead();
  }

  @override
  void dispose() {
    print('🧹 Disposing ChatStateNotifier for $chatPartnerId');
    _stateManager?.dispose();
    super.dispose();
  }
}

// Chat provider parameters class for proper equality
class ChatProviderParams {
  final String chatPartnerId;
  final String currentUserId;

  ChatProviderParams({
    required this.chatPartnerId,
    required this.currentUserId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatProviderParams &&
          runtimeType == other.runtimeType &&
          chatPartnerId == other.chatPartnerId &&
          currentUserId == other.currentUserId;

  @override
  int get hashCode => chatPartnerId.hashCode ^ currentUserId.hashCode;

  @override
  String toString() =>
      'ChatProviderParams(chatPartnerId: $chatPartnerId, currentUserId: $currentUserId)';
}

// ✅ KEY FIX: Use StateNotifierProvider (not autoDispose) to keep the provider alive
// Use ChatProviderParams instead of Map for proper equality comparison
final chatStateProvider =
    StateNotifierProvider.family<
      ChatStateNotifier,
      ChatState,
      ChatProviderParams
    >((ref, params) {
      print('🏭 Creating ChatStateNotifier provider');
      print('   Params: $params');

      return ChatStateNotifier(
        chatPartnerId: params.chatPartnerId,
        currentUserId: params.currentUserId,
      );
    });
