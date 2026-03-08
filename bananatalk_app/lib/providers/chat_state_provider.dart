// lib/providers/chat_state_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/chat_socket_state_manager.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';

/// Connection status enum for clearer state management
enum ConnectionStatus {
  connected,
  connecting,
  reconnecting,
  disconnected,
}

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSocketConnected;
  final ConnectionStatus? connectionStatus; // Nullable - null means don't show status
  final bool isOtherUserTyping;
  final bool isOtherUserOnline;
  final String? otherUserLastSeen;
  final String error;
  final Message? editingMessage; // Message currently being edited

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSocketConnected = false,
    this.connectionStatus, // Default null - don't show connection status initially
    this.isOtherUserTyping = false,
    this.isOtherUserOnline = false,
    this.otherUserLastSeen,
    this.error = '',
    this.editingMessage,
  });

  /// Get all pinned messages (not deleted)
  List<Message> get pinnedMessages =>
      messages.where((m) => m.isPinned && !m.isDeleted).toList();

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSocketConnected,
    ConnectionStatus? connectionStatus,
    bool clearConnectionStatus = false, // Set to true to explicitly set null
    bool? isOtherUserTyping,
    bool? isOtherUserOnline,
    String? otherUserLastSeen,
    String? error,
    Message? editingMessage,
    bool clearEditingMessage = false, // Set to true to explicitly clear editing
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      connectionStatus: clearConnectionStatus ? null : (connectionStatus ?? this.connectionStatus),
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
      otherUserLastSeen: otherUserLastSeen ?? this.otherUserLastSeen,
      error: error ?? this.error,
      editingMessage: clearEditingMessage ? null : (editingMessage ?? this.editingMessage),
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> with WidgetsBindingObserver {
  final String chatPartnerId;
  final String currentUserId;
  final Ref? _ref; // Reference to check active chat
  ChatSocketStateManager? _stateManager;
  bool _isInitialized = false;
  Timer? _disconnectDebounceTimer;

  // Track app foreground state
  bool _isAppInForeground = true;

  // How long to wait before showing reconnecting status (avoids flickering)
  static const _disconnectDebounceDelay = Duration(seconds: 3);

  ChatStateNotifier({
    required this.chatPartnerId,
    required this.currentUserId,
    Ref? ref,
  }) : _ref = ref, super(ChatState()) {
    debugPrint('🎯 ChatStateNotifier created for partner: $chatPartnerId');
    // Start observing app lifecycle
    WidgetsBinding.instance.addObserver(this);
  }

  /// Check if THIS chat is the currently active one (from global provider)
  bool get _isThisChatActive {
    if (_ref == null) return false;
    try {
      final activeChatId = _ref!.read(chatPartnersProvider).activeChatUserId;
      return activeChatId == chatPartnerId;
    } catch (e) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;
    debugPrint('📱 App lifecycle changed: $state (foreground: $_isAppInForeground, activeChat: ${_isThisChatActive ? chatPartnerId : "other"})');

    // When returning to foreground and THIS chat is the active one, mark messages as read
    if (_isAppInForeground && !wasInForeground && _isThisChatActive) {
      debugPrint('📱 App resumed with THIS chat active - marking messages as read');
      _stateManager?.markAsRead();
    }
  }

  /// Call this when chat screen becomes visible (kept for compatibility but not used for read logic)
  void setChatVisible(bool visible) {
    debugPrint('👁️ Chat visibility changed: $visible (activeChat check: ${_isThisChatActive})');

    // If becoming visible and app is in foreground and THIS is the active chat, mark as read
    if (visible && _isAppInForeground && _isInitialized && _isThisChatActive) {
      debugPrint('👁️ Chat now visible - marking messages as read');
      _stateManager?.markAsRead();
    }
  }

  /// Check if we should auto-mark messages as read
  /// Only mark as read if THIS chat is the active one AND app is in foreground
  bool get _shouldAutoMarkAsRead => _isThisChatActive && _isAppInForeground;

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

      if (isConnected) {
        // Connected - cancel any pending disconnect timer and clear status
        _disconnectDebounceTimer?.cancel();
        state = state.copyWith(
          isSocketConnected: true,
          clearConnectionStatus: true, // Hide connection status when connected
        );

        // Auto-mark as read when socket reconnects (only if chat visible & app foreground)
        if (state.messages.isNotEmpty && _shouldAutoMarkAsRead) {
          debugPrint('🔌 Socket reconnected & chat visible - marking messages as read');
          _stateManager?.markAsRead();
        } else if (state.messages.isNotEmpty) {
          debugPrint('🔌 Socket reconnected but chat not visible or app backgrounded - NOT marking as read');
        }
      } else {
        // Disconnected - debounce before showing reconnecting status
        // This prevents flickering during brief disconnections
        _disconnectDebounceTimer?.cancel();
        _disconnectDebounceTimer = Timer(_disconnectDebounceDelay, () {
          // Only show reconnecting if still disconnected after delay
          if (!(_stateManager?.isConnected ?? false)) {
            state = state.copyWith(
              isSocketConnected: false,
              connectionStatus: ConnectionStatus.reconnecting,
            );
          }
        });
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

      // Only auto-mark as read if chat is visible AND app is in foreground
      // This ensures notifications are sent when app is backgrounded
      if (message.sender.id == chatPartnerId) {
        if (_shouldAutoMarkAsRead) {
          debugPrint('   📖 Auto-marking message as read (chat visible & app foreground)');
          _stateManager?.markAsRead();
        } else {
          debugPrint('   🔔 NOT marking as read - not active chat or app backgrounded');
          debugPrint('      Active chat: $_isThisChatActive, App foreground: $_isAppInForeground');
        }
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

    _stateManager!.onReactionUpdated = (messageId, reactions) {
      debugPrint('💬 Updating reactions for message: $messageId');
      // Update the message with new reactions
      final updatedMessages = state.messages.map((msg) {
        if (msg.id == messageId) {
          // Parse reactions from the socket data using MessageReaction.fromJson
          final parsedReactions = reactions.map((r) {
            if (r is Map) {
              try {
                return MessageReaction.fromJson(Map<String, dynamic>.from(r));
              } catch (e) {
                debugPrint('⚠️ Error parsing reaction: $e');
                return null;
              }
            }
            return null;
          }).whereType<MessageReaction>().toList();

          return msg.copyWith(reactions: parsedReactions);
        }
        return msg;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
      debugPrint('✅ Reactions updated for message $messageId');
    };

    _stateManager!.onMessagePinned = (messageId, isPinned) {
      debugPrint('📌 Message pinned update: $messageId -> $isPinned');
      final updatedMessages = state.messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(isPinned: isPinned);
        }
        return msg;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
      debugPrint('✅ Pin status updated for message $messageId');
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

  // ==================== MESSAGE ACTIONS ====================

  /// Start editing a message
  void setEditingMessage(Message message) {
    debugPrint('✏️ Starting to edit message: ${message.id}');
    state = state.copyWith(editingMessage: message);
  }

  /// Cancel editing
  void clearEditingMessage() {
    debugPrint('✏️ Cancelled editing');
    state = state.copyWith(clearEditingMessage: true);
  }

  /// Update a message locally (optimistic update for edit/pin)
  void updateMessageLocally(String messageId, {
    String? newText,
    bool? isPinned,
    bool? isEdited,
    bool? isDeleted,
  }) {
    final updatedMessages = state.messages.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(
          message: newText ?? msg.message,
          isPinned: isPinned ?? msg.isPinned,
          isEdited: isEdited ?? msg.isEdited,
          isDeleted: isDeleted ?? msg.isDeleted,
        );
      }
      return msg;
    }).toList();
    state = state.copyWith(messages: updatedMessages);
  }

  /// Remove a message locally (optimistic delete for "delete for me")
  void removeMessageLocally(String messageId) {
    debugPrint('🗑️ Removing message locally: $messageId');
    final updatedMessages = state.messages.where((msg) => msg.id != messageId).toList();
    state = state.copyWith(messages: updatedMessages);
  }

  /// Mark a message as deleted (for "delete for everyone")
  void markMessageAsDeleted(String messageId) {
    debugPrint('🗑️ Marking message as deleted: $messageId');
    updateMessageLocally(messageId, isDeleted: true);
  }

  /// Toggle pin status locally
  void togglePinLocally(String messageId) {
    final message = state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );
    debugPrint('📌 Toggling pin for message: $messageId (currently: ${message.isPinned})');
    updateMessageLocally(messageId, isPinned: !message.isPinned);
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing ChatStateNotifier for $chatPartnerId');
    WidgetsBinding.instance.removeObserver(this);
    _disconnectDebounceTimer?.cancel();
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
        ref: ref, // Pass ref to check active chat
      );
    });
