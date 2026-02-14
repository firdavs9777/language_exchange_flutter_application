// lib/providers/chat_state_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/chat_socket_state_manager.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

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
    debugPrint('🎯 ChatStateNotifier created for partner: $chatPartnerId');
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ ChatStateNotifier already initialized');
      return;
    }

    debugPrint('🚀 Initializing ChatStateNotifier');
    debugPrint('   Partner ID: $chatPartnerId');
    debugPrint('   Current User ID: $currentUserId');

    _stateManager = ChatSocketStateManager(
      chatPartnerId: chatPartnerId,
      currentUserId: currentUserId,
    );

    // Setup callbacks
    _stateManager!.onConnectionChanged = (isConnected) {
      debugPrint('🔌 Connection changed: $isConnected');
      state = state.copyWith(isSocketConnected: isConnected);

      // Auto-mark as read when socket reconnects (catch up on missed messages)
      if (isConnected && state.messages.isNotEmpty) {
        debugPrint('🔌 Socket reconnected - marking messages as read');
        _stateManager?.markAsRead();
      }
    };

    _stateManager!.onNewMessage = (message) {
      debugPrint('📨 NEW MESSAGE RECEIVED!');
      debugPrint('   From: ${message.sender.id}');
      debugPrint('   To: ${message.receiver.id}');
      debugPrint('   Text: ${message.message}');
      debugPrint('   Current messages count: ${state.messages.length}');

      final messages = List<Message>.from(state.messages)..add(message);
      messages.sort(
        (a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
      );

      debugPrint('   New messages count: ${messages.length}');
      state = state.copyWith(messages: messages);
      debugPrint('   ✅ State updated with new message');

      // Auto-mark as read since chat is open (KakaoTalk-style instant read)
      if (message.sender.id == chatPartnerId) {
        debugPrint('   📖 Auto-marking message as read (chat is open)');
        _stateManager?.markAsRead();
      }
    };

    _stateManager!.onMessageDeleted = (data) {
      debugPrint('🗑️ Message deleted: $data');
      final messageId = data['messageId'];
      if (messageId != null) {
        final messages = state.messages
            .where((msg) => msg.id != messageId)
            .toList();
        state = state.copyWith(messages: messages);
      }
    };

    _stateManager!.onMessageEdited = (message) {
      debugPrint('✏️ Message edited: ${message.id}');
      final messages = state.messages.map((msg) {
        return msg.id == message.id ? message : msg;
      }).toList();
      state = state.copyWith(messages: messages);
    };

    _stateManager!.onTypingChanged = (isTyping) {
      debugPrint('⌨️ Typing indicator: $isTyping');
      state = state.copyWith(isOtherUserTyping: isTyping);
    };

    _stateManager!.onStatusChanged = (isOnline, lastSeen) {
      debugPrint('📡 Status changed - Online: $isOnline, Last seen: $lastSeen');
      state = state.copyWith(
        isOtherUserOnline: isOnline,
        otherUserLastSeen: lastSeen,
      );
    };

    _stateManager!.onMessagesRead = (messageIds) {
      debugPrint('👁️ Messages read by partner: $messageIds');
      // Mark all sent messages as read (the other user read them)
      final updatedMessages = state.messages.map((msg) {
        // Only update messages we sent that aren't already read
        if (msg.sender.id == currentUserId && !msg.read) {
          return msg.copyWith(read: true);
        }
        return msg;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
      debugPrint('✅ Updated ${state.messages.where((m) => m.read).length} messages as read');
    };

    await _stateManager!.initialize();
    _isInitialized = true;

    debugPrint('✅ ChatStateNotifier initialization complete');
    debugPrint('   Socket connected: ${_stateManager!.isConnected}');
  }

  void setMessages(List<Message> messages) {
    debugPrint('📝 Setting ${messages.length} messages');
    state = state.copyWith(messages: messages);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String error) {
    debugPrint('❌ Error: $error');
    state = state.copyWith(error: error);
  }

  void sendTyping(bool isTyping) {
    if (!_isInitialized || _stateManager == null) {
      debugPrint('⚠️ Cannot send typing - not initialized yet');
      return;
    }
    _stateManager!.sendTyping(isTyping);
  }

  /// Create a minimal Community object for optimistic messages
  Community _createMinimalCommunity(String id) {
    return Community(
      id: id,
      name: '',
      email: '',
      bio: '',
      mbti: '',
      bloodType: '',
      images: [],
      imageUrls: [],
      birth_day: '',
      birth_month: '',
      birth_year: '',
      gender: '',
      native_language: '',
      language_to_learn: '',
      followers: [],
      followings: [],
      createdAt: '',
      version: 0,
      location: Location.defaultLocation(),
    );
  }

  /// Add an optimistic message for instant display
  String addOptimisticMessage({
    required String message,
    required String currentUserId,
    required String receiverId,
    String type = 'text',
    MessageMedia? media,
  }) {
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final optimisticMessage = Message.optimistic(
      localId: localId,
      sender: _createMinimalCommunity(currentUserId),
      receiver: _createMinimalCommunity(receiverId),
      message: message,
      type: type,
      media: media,
    );

    debugPrint('⚡ Adding optimistic message: $localId');
    final messages = List<Message>.from(state.messages)..add(optimisticMessage);
    state = state.copyWith(messages: messages);

    return localId;
  }

  /// Update optimistic message status after server response
  void updateOptimisticMessage(String localId, {Message? confirmedMessage, bool failed = false}) {
    final messages = List<Message>.from(state.messages);
    final index = messages.indexWhere((m) => m.localId == localId || m.id == localId);

    if (index != -1) {
      if (confirmedMessage != null) {
        // Replace with confirmed message
        debugPrint('✅ Replacing optimistic message with confirmed: ${confirmedMessage.id}');
        messages[index] = confirmedMessage;
      } else if (failed) {
        // Mark as failed
        debugPrint('❌ Marking message as failed: $localId');
        messages[index] = messages[index].copyWithStatus(MessageSendingStatus.failed);
      }
      state = state.copyWith(messages: messages);
    }
  }

  /// Retry sending a failed message
  Future<Map<String, dynamic>> retrySendMessage(String localId) async {
    final message = state.messages.firstWhere(
      (m) => m.localId == localId || m.id == localId,
      orElse: () => throw Exception('Message not found'),
    );

    if (message.message == null) {
      return {'status': 'error', 'error': 'No message content'};
    }

    // Update to sending status
    updateOptimisticMessage(localId, failed: false);
    final messages = List<Message>.from(state.messages);
    final index = messages.indexWhere((m) => m.localId == localId || m.id == localId);
    if (index != -1) {
      messages[index] = messages[index].copyWithStatus(MessageSendingStatus.sending);
      state = state.copyWith(messages: messages);
    }

    return await sendMessage(message.message!, localId: localId);
  }

  Future<Map<String, dynamic>> sendMessage(String message, {String? localId}) async {
    if (!_isInitialized || _stateManager == null) {
      debugPrint('⚠️ Cannot send message - not initialized yet');
      if (localId != null) updateOptimisticMessage(localId, failed: true);
      return {'status': 'error', 'error': 'Chat not initialized'};
    }
    debugPrint('📤 Sending message: "$message"');
    final result = await _stateManager!.sendMessage(message);
    debugPrint('📤 Send result: $result');

    // If message was sent successfully, update optimistic message or add new
    debugPrint('🔍 Checking result status: ${result['status']}');
    if (result['status'] == 'success') {
      debugPrint('✅ Status is success, attempting to add message to state');
      try {
        final messageData = result['message'] ?? result['data'];
        debugPrint('🔍 Message data type: ${messageData?.runtimeType}');

        if (messageData is Map) {
          debugPrint('✅ Message data is a Map, parsing...');
          final sentMessage = Message.fromJson(
            Map<String, dynamic>.from(messageData),
          );
          debugPrint('📤 Confirmed message: ${sentMessage.id}');

          if (localId != null) {
            // Update the optimistic message with confirmed one
            updateOptimisticMessage(localId, confirmedMessage: sentMessage);
          } else {
            // No optimistic message, add directly (avoid duplicates)
            final existingIndex = state.messages.indexWhere((m) => m.id == sentMessage.id);
            if (existingIndex == -1) {
              final messages = List<Message>.from(state.messages)..add(sentMessage);
              messages.sort(
                (a, b) =>
                    DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
              );
              state = state.copyWith(messages: messages);
            }
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error processing sent message: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
    } else {
      debugPrint('⚠️ Status is not success: ${result['status']}');
      if (localId != null) {
        updateOptimisticMessage(localId, failed: true);
      }
    }

    return result;
  }

  void markAsRead() {
    if (!_isInitialized || _stateManager == null) {
      debugPrint('⚠️ Cannot mark as read - not initialized yet');
      return;
    }
    _stateManager!.markAsRead();
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing ChatStateNotifier for $chatPartnerId');
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
      debugPrint('🏭 Creating ChatStateNotifier provider');
      debugPrint('   Params: $params');

      return ChatStateNotifier(
        chatPartnerId: params.chatPartnerId,
        currentUserId: params.currentUserId,
      );
    });
