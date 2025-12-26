import 'dart:async';
import 'package:bananatalk_app/pages/chat/chat_app_bar.dart';
import 'package:bananatalk_app/pages/chat/chat_input_section.dart';
import 'package:bananatalk_app/pages/chat/chat_messages_list.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/socket_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/widgets/connection_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/message_count_provider.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/widgets/image_preview_dialog.dart';
import 'package:bananatalk_app/utils/api_error_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/services/media_service.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:bananatalk_app/pages/chat/forward_message_dialog.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? profilePicture;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.profilePicture,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isSendingMessage = false;
  String _error = '';
  String? _currentUserId;
  IO.Socket? _socket;
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _otherUserTyping = false;
  final _chatSocketService = ChatSocketService();
  bool _showMediaPanel = false;
  bool _showStickerPanel = false;
  bool _isSocketConnected = false;
  bool _isOtherUserOnline = false;
  String? _otherUserLastSeen;
  String? _chatWallpaper; // Selected wallpaper/theme
  String? _customWallpaperPath; // For custom image wallpapers
  bool _isSelectionMode = false;
  Set<String> _selectedMessageIds = {};
  Message? _replyingToMessage; // Message being replied to

  late AnimationController _mediaPanelController;
  late AnimationController _stickerPanelController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentUser();
    _loadChatWallpaper();
    _setupCallListeners();
  }

  void _setupCallListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callNotifier = ref.read(callProvider.notifier);
      
      // Setup incoming call callback
      callNotifier.setIncomingCallCallback((call) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncomingCallScreen(call: call),
              fullscreenDialog: true,
            ),
          );
        }
      });

      // Setup call error callback
      callNotifier.setCallErrorCallback((error) {
        if (mounted) {
          _handleCallError(context, error);
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch auth state - disconnect sockets if logged out
    final authService = ref.watch(authServiceProvider);
    if (!authService.isLoggedIn) {
      print('🚫 User logged out - disconnecting socket');
      _disconnectSocket();
    }
  }

  Future<void> _loadChatWallpaper() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try to get wallpaper for this specific conversation or user
      final conversationTheme = prefs.getString('chat_theme_${widget.userId}');

      if (conversationTheme != null) {
        if (mounted) {
          setState(() {
            _chatWallpaper = conversationTheme;
          });
        }
      }
    } catch (e) {
      print('Error loading chat wallpaper: $e');
    }
  }

  void _initializeAnimations() {
    _mediaPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _stickerPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _toggleMediaPanel() {
    setState(() {
      if (_showStickerPanel) {
        _showStickerPanel = false;
        _stickerPanelController.reverse();
      }

      _showMediaPanel = !_showMediaPanel;
      if (_showMediaPanel) {
        _mediaPanelController.forward();
      } else {
        _mediaPanelController.reverse();
      }
    });
  }

  void _toggleStickerPanel() {
    setState(() {
      if (_showMediaPanel) {
        _showMediaPanel = false;
        _mediaPanelController.reverse();
      }

      _showStickerPanel = !_showStickerPanel;
      if (_showStickerPanel) {
        _stickerPanelController.forward();
      } else {
        _stickerPanelController.reverse();
      }
    });
  }

  void _hidePanels() {
    if (_showMediaPanel) {
      setState(() {
        _showMediaPanel = false;
      });
      _mediaPanelController.reverse();
    }
    if (_showStickerPanel) {
      setState(() {
        _showStickerPanel = false;
      });
      _stickerPanelController.reverse();
    }
  }

  Future<void> _loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });

    if (_currentUserId != null) {
      await _loadMessages();
      await _initSocket();
    }
  }

  Future<void> _initSocket() async {
    if (_currentUserId == null) {
      setState(() => _error = "User ID not found");
      return;
    }

    // CRITICAL: Check if reconnection is allowed (prevents reconnection after logout)
    final socketService = SocketService();
    if (!socketService.shouldAllowReconnection) {
      print('🚫 Socket reconnection disabled (logout in progress or completed)');
      setState(() => _error = "Session expired. Please login again.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // CRITICAL: Validate token exists and is not empty
    if (token == null || token.isEmpty) {
      print('⚠️ Cannot initialize socket - token not available or cleared (logout detected)');
      setState(() => _error = "Authentication token not found. Please login again.");
      _disconnectSocket(); // Ensure socket is disconnected
      return;
    }

    try {
      // Get base URL from Endpoints (socket connects to root, not /api/v1/)
      final baseUrl = Endpoints.baseURL;
      final socketUrl = baseUrl.endsWith('/api/v1/')
          ? baseUrl.substring(0, baseUrl.length - 8)
          : baseUrl.replaceAll('/api/v1/', '');

      print('🔌 Connecting to socket: $socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .setQuery({'userId': _currentUserId})
            .setReconnectionAttempts(socketService.shouldAllowReconnection ? 5 : 0) // Disable reconnection if logout occurred
            .setReconnectionDelay(1000)
            .setTimeout(5000) // Increased timeout
            .build(),
      );

      // Register socket with global service for cleanup on logout
      SocketService().registerSocket(_socket);

      // Add disconnect handler to check token on reconnect attempts
      _socket?.onDisconnect((reason) {
        print('🔌 Socket disconnected: $reason');
        // Don't auto-reconnect if logout occurred
        if (!socketService.shouldAllowReconnection) {
          print('🚫 Preventing reconnection - logout detected');
          return;
        }
      });

      _setupSocketListeners();
      _socket?.connect();
    } catch (e) {
      print('❌ Error initializing socket: $e');
      setState(() => _error = 'Failed to connect: ${e.toString()}');
    }
  }

  /// Validate token before socket operations
  Future<bool> _validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final socketService = SocketService();
    
    // Check if reconnection is allowed (prevents operations after logout)
    if (!socketService.shouldAllowReconnection) {
      print('🚫 Token validation failed - logout detected');
      return false;
    }
    
    // Check if token exists
    if (token == null || token.isEmpty) {
      print('🚫 Token validation failed - token missing');
      return false;
    }
    
    return true;
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('✅ Socket connected successfully');
      print('🔍 Socket ID: ${_socket?.id}');
      print('🔍 Connected: ${_socket?.connected}');
      if (mounted) {
        try {
          setState(() {
            _error = '';
            _isSocketConnected = true;
          });
        } catch (e) {
          print('⚠️ setState error in onConnect: $e');
        }
      }

      // Request user status when connected
      _requestUserStatus();

      // Set our status to online
      _socket?.emit('setOnline');
    });

    // Setup user status listeners
    _setupUserStatusListeners();

    _socket?.onConnectError((error) {
      print('❌ Socket connection error: $error');
      if (mounted) {
        setState(() {
          _error = "Connection failed: $error";
          _isSending = false; // Reset sending state on connection error
          _isSocketConnected = false;
        });
      }
    });

    _socket?.onDisconnect((reason) {
      print('❌ Socket disconnected: $reason');
      if (mounted) {
        setState(() {
          _isSocketConnected = false;
        });
      }

      if (mounted && _isSending) {
        setState(() {
          _isSending = false;
          _error = 'Connection lost. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection lost. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    _socket?.onError((error) {
      print('❌ Socket error: $error');
      if (mounted) {
        setState(() {
          _error = "Connection error: $error";
          _isSending = false; // Reset sending state on socket error
          _isSocketConnected = false;
        });
      }
    });

    // Listen for incoming messages (when someone sends you a message)
    // API docs: socket.on('newMessage', (data) => { message, senderId, unreadCount })
    _socket?.on('newMessage', (data) {
      try {
        print('📨 New message received: $data');
        final messageData = data is Map ? data['message'] : null;
        if (messageData != null && messageData is Map) {
          final messageJson = Map<String, dynamic>.from(messageData);
          final newMessage = Message.fromJson(messageJson);
          _handleNewMessage(newMessage);

          // Mark as read since we're in the chat screen
          _markMessagesAsRead();
        }
      } catch (e) {
        print('❌ Error parsing new message: $e');
      }
    });

    // Listen for message sent confirmation (for syncing across devices)
    // API docs: socket.on('messageSent', (data) => { message, receiverId, unreadCount })
    _socket?.on('messageSent', (data) {
      try {
        print('📤 Message sent confirmation (multi-device sync): $data');

        final messageData = data is Map ? data['message'] : data;
        if (messageData != null && messageData is Map) {
          final messageJson = Map<String, dynamic>.from(messageData);
          final sentMessage = Message.fromJson(messageJson);
          _handleNewMessage(sentMessage);
        }
      } catch (e) {
        print('❌ Error parsing sent message sync: $e');
      }
    });

    // Legacy 'message' event support (fallback)
    _socket?.on('message', (data) {
      try {
        print('📨 Legacy message event received: $data');
        final messageJson = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final newMessage = Message.fromJson(messageJson);
        _handleNewMessage(newMessage);
      } catch (e) {
        print('❌ Error parsing legacy message: $e');
      }
    });

    // Listen for read receipts
    // API docs: socket.on('messagesRead', (data) => { readBy, count })
    _socket?.on('messagesRead', (data) {
      try {
        print('👁️ Messages read notification: $data');
        if (data is Map && data['readBy'] == widget.userId) {
          // Update UI to show messages were read
          if (mounted) {
            setState(() {
              _messages = _messages.map((msg) {
                if (msg.sender.id == _currentUserId && !msg.read) {
                  // Create updated message with read = true using toJson/fromJson
                  final json = msg.toJson();
                  json['read'] = true;
                  return Message.fromJson(json);
                }
                return msg;
              }).toList();
            });
          }
        }
      } catch (e) {
        print('❌ Error handling messages read: $e');
      }
    });

    // Listen for message edited
    // API docs: socket.on('messageEdited', (data) => { message })
    _socket?.on('messageEdited', (data) {
      try {
        print('✏️ Message edited notification: $data');
        if (data is Map && data['message'] != null) {
          final messageData = data['message'] is Map
              ? data['message']
              : Map<String, dynamic>.from(data);
          final updatedMessage = Message.fromJson(messageData);
          if (mounted) {
            setState(() {
              final index = _messages.indexWhere(
                (m) => m.id == updatedMessage.id,
              );
              if (index != -1) {
                _messages[index] = updatedMessage;
                print('✅ Message updated via socket at index $index');
              }
            });
          }
        }
      } catch (e) {
        print('❌ Error handling message edited: $e');
      }
    });

    // Listen for message deleted
    // API docs: socket.on('messageDeleted', (data) => { messageId, deletedForEveryone, message? })
    _socket?.on('messageDeleted', (data) {
      try {
        print('🗑️ Message deleted notification: $data');
        if (data is Map && data['messageId'] != null) {
          final messageId = data['messageId'].toString();
          final deletedForEveryone = data['deletedForEveryone'] ?? false;

          if (mounted) {
            setState(() {
              final index = _messages.indexWhere((msg) => msg.id == messageId);
              if (index != -1) {
                if (deletedForEveryone) {
                  // Update message to show "deleted" placeholder
                  final message = _messages[index];
                  final json = message.toJson();
                  json['isDeleted'] = true;
                  json['deletedForEveryone'] = true;
                  json['message'] = 'This message was deleted';
                  final deletedMessage = Message.fromJson(json);
                  _messages[index] = deletedMessage;
                  print(
                    '✅ Message updated to deleted state via socket at index $index',
                  );
                } else {
                  // Remove message (delete for me only)
                  _messages.removeAt(index);
                  print('✅ Message removed via socket at index $index');
                }
              }
            });
          }
        }
      } catch (e) {
        print('❌ Error handling message deleted: $e');
      }
    });

    // Listen for typing indicators
    // API docs: socket.on('userTyping', (data) => { userId })
    _socket?.on('userTyping', (data) {
      final userId = data is Map ? (data['userId'] ?? data['user']) : null;
      if (userId == widget.userId && mounted) {
        setState(() => _otherUserTyping = true);
      }
    });

    // API docs: socket.on('userStoppedTyping', (data) => { userId })
    _socket?.on('userStoppedTyping', (data) {
      final userId = data is Map ? (data['userId'] ?? data['user']) : null;
      if (userId == widget.userId && mounted) {
        setState(() => _otherUserTyping = false);
      }
    });

    // Legacy typing events (fallback)
    _socket?.on('userStopTyping', (data) {
      final userId = data is Map ? (data['userId'] ?? data['user']) : null;
      if (userId == widget.userId && mounted) {
        setState(() => _otherUserTyping = false);
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    // API docs: socket.emit('markAsRead', { senderId }, callback)
    // Validate token before marking as read
    final isValidToken = await _validateToken();
    if (!isValidToken || _socket == null || !_socket!.connected) {
      print('🚫 Cannot mark as read - token invalid or socket disconnected');
      return;
    }
    
    _socket!.emitWithAck(
      'markAsRead',
      {'senderId': widget.userId},
      ack: (response) {
        print('📖 Mark as read response: $response');
      },
    );
  }

  void _requestUserStatus() {
    // API docs: socket.emit('getUserStatus', { userId }, callback)
    if (_socket != null && _socket!.connected) {
      _socket!.emitWithAck(
        'getUserStatus',
        {'userId': widget.userId},
        ack: (response) {
          print('👤 User status response: $response');
          if (mounted && response is Map && response['status'] == 'success') {
            final data = response['data'];
            if (data is Map) {
              setState(() {
                _isOtherUserOnline = data['status'] == 'online';
                _otherUserLastSeen = data['lastSeen'];
              });
            }
          }
        },
      );
    }
  }

  void _setupUserStatusListeners() {
    // API docs: socket.on('userStatusUpdate', (data) => { userId, status, lastSeen })
    _socket?.on('userStatusUpdate', (data) {
      if (data is Map && data['userId'] == widget.userId && mounted) {
        try {
          setState(() {
            _isOtherUserOnline = data['status'] == 'online';
            _otherUserLastSeen = data['lastSeen'];
          });
        } catch (e) {
          print('⚠️ setState error in userStatusUpdate: $e');
        }
      }
    });

    // API docs: socket.on('onlineUsers', (users) => [...])
    _socket?.on('onlineUsers', (users) {
      if (users is List) {
        final isOnline = users.any(
          (user) =>
              user is Map &&
              user['userId'] == widget.userId &&
              user['status'] == 'online',
        );
        if (mounted) {
          try {
            setState(() {
              _isOtherUserOnline = isOnline;
            });
          } catch (e) {
            print('⚠️ setState error in onlineUsers: $e');
          }
        }
      }
    });
  }

  void _handleCallError(BuildContext context, String error) {
    if (error.startsWith('PERMANENTLY_DENIED:')) {
      // Show dialog with option to open settings
      final message = error.substring('PERMANENTLY_DENIED:'.length);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppSettings.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else if (error.startsWith('DENIED:')) {
      // Show snackbar for temporary denial
      final message = error.substring('DENIED:'.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Generic error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleNewMessage(Message newMessage) {
    bool isPartOfConversation =
        (newMessage.sender.id == widget.userId &&
            newMessage.receiver.id == _currentUserId) ||
        (newMessage.sender.id == _currentUserId &&
            newMessage.receiver.id == widget.userId);

    if (isPartOfConversation && mounted) {
      setState(() {
        bool messageExists = _messages.any((msg) => msg.id == newMessage.id);
        if (!messageExists) {
          _messages.add(newMessage);
          _messages.sort(
            (a, b) => DateTime.parse(
              a.createdAt,
            ).compareTo(DateTime.parse(b.createdAt)),
          );
          
          // Update message count provider
          ref.read(messageCountProvider.notifier).incrementMessageCount(
            widget.userId,
          );
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final messageService = ref.read(messageServiceProvider);

      if (_currentUserId != null) {
        final allMessages = await messageService.getUserMessages(
          id: _currentUserId,
        );
        final conversationMessages = allMessages.where((message) {
          return (message.sender.id == _currentUserId &&
                  message.receiver.id == widget.userId) ||
              (message.sender.id == widget.userId &&
                  message.receiver.id == _currentUserId);
        }).toList();

        conversationMessages.sort(
          (a, b) => DateTime.parse(
            a.createdAt,
          ).compareTo(DateTime.parse(b.createdAt)),
        );

        setState(() => _messages = conversationMessages);
        
        // Update message count provider
        if (widget.userId.isNotEmpty) {
          ref.read(messageCountProvider.notifier).setMessageCount(
            widget.userId,
            conversationMessages.length,
          );
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (error) {
      setState(() => _error = 'Failed to load messages: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelSending() {
    if (_isSending) {
      setState(() {
        _isSending = false;
        _error = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message send cancelled'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendMessage({String? messageText, String? messageType}) async {
    final text = messageText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending || _currentUserId == null) return;

    // Check limits before sending
    try {
      final userAsync = ref.read(userProvider);
      final user = await userAsync.when(
        data: (user) => user,
        loading: () => null,
        error: (error, stack) {
          print('Error loading user for limit check: $error');
          return null;
        },
      );

      if (user != null) {
        final limits = ref.read(currentUserLimitsProvider(_currentUserId!));

        if (!FeatureGate.canSendMessage(user, limits)) {
          await LimitExceededDialog.show(
            context: context,
            limitType: 'messages',
            limitInfo: limits?.messages,
            resetTime: limits?.resetTime,
            userId: _currentUserId!,
          );
          return;
        }
      }
    } catch (e) {
      print('Error checking limits: $e');
    }

    if (messageText == null) _messageController.clear();
    _stopTyping();
    _hidePanels();

    setState(() {
      _isSending = true;
      _error = '';
    });

    try {
      // Check if socket is connected
      if (_socket == null || !_socket!.connected) {
        print('⚠️ Socket not connected. Attempting to reconnect...');

        // Try to reconnect
        if (_socket == null) {
          await _initSocket();
        } else {
          _socket?.connect();
        }

        // Wait a bit for connection
        await Future.delayed(const Duration(milliseconds: 500));

        // Check again
        if (_socket == null || !_socket!.connected) {
          throw Exception(
            'Unable to establish connection. Please check your internet.',
          );
        }
      }

      print('📤 Sending message via socket...');
      print('🔍 Socket connected: ${_socket?.connected}');
      print('🔍 Socket ID: ${_socket?.id}');
      print('🔍 Receiver ID: ${widget.userId}');

      // Check if replying to a message - use API instead of socket for replies
      if (_replyingToMessage != null) {
        print('💬 Sending reply to message: ${_replyingToMessage!.id}');
        try {
          final messageService = ref.read(messageServiceProvider);
          final result = await messageService.replyToMessage(
            messageId: _replyingToMessage!.id,
            message: text,
            receiver: widget.userId,
          );

          if (mounted) {
            setState(() {
              _isSending = false;
              _replyingToMessage = null; // Clear reply state
            });
          }

          if (result['success'] == true) {
            final replyMessage = result['data'] as Message;
            _handleNewMessage(replyMessage);
            if (mounted) {
              _messageController.clear();
            }
            // Refresh limits
            if (_currentUserId != null) {
              ref.refresh(userLimitsProvider(_currentUserId!));
            }
            return;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['error'] ?? 'Failed to send reply'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isSending = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error sending reply: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Validate token before sending message
      final isValidToken = await _validateToken();
      if (!isValidToken || _socket == null || !_socket!.connected) {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _disconnectSocket();
        return;
      }

      // Use emitWithAck to get callback response from server
      // According to API docs: socket.emit('sendMessage', { receiver, message }, callback)
      _socket!.emitWithAck(
        'sendMessage',
        {
          'receiver': widget.userId,
          'message': text,
          if (_replyingToMessage != null) 'replyTo': _replyingToMessage!.id,
        },
        ack: (response) {
          print('📬 Server response received: $response');

          if (!mounted) return;

          if (response is Map) {
            final status = response['status'];

            if (status == 'success') {
              print('✅ Message sent successfully');

              setState(() {
                _isSending = false;
                _error = '';
                _replyingToMessage = null; // Clear reply state after sending
              });

              // Handle the sent message
              final messageData = response['message'];
              if (messageData != null && messageData is Map) {
                try {
                  final messageJson = Map<String, dynamic>.from(messageData);
                  final sentMessage = Message.fromJson(messageJson);
                  _handleNewMessage(sentMessage);
                  
                  // Update message count provider (already incremented in _handleNewMessage)
                  // But refresh to ensure accuracy
                  ref.read(messageCountProvider.notifier).refreshMessageCount(
                    widget.userId,
                  );
                } catch (e) {
                  print('❌ Error parsing sent message: $e');
                }
              }

              // Refresh limits after successful send
              if (_currentUserId != null) {
                ref.refresh(userLimitsProvider(_currentUserId!));
              }
            } else {
              // Error response
              final errorMessage =
                  response['error'] ?? 'Failed to send message';
              print('❌ Server error: $errorMessage');

              setState(() {
                _isSending = false;
                _error = '';
              });

              // Restore message to text field
              _messageController.text = text;

              // Show error message
              _showSendError(errorMessage, text, messageType);
            }
          } else {
            // Unexpected response format
            print('⚠️ Unexpected response format: $response');
            setState(() {
              _isSending = false;
            });
            _messageController.text = text;
          }
        },
      );

      // Timeout fallback - if callback doesn't respond in 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isSending) {
          print('⏰ Message send timeout - no callback received');
          setState(() {
            _isSending = false;
            _error = 'Message send timeout. Please try again.';
          });

          // Restore message to text field
          _messageController.text = text;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.messageSendTimeout),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: AppLocalizations.of(context)!.retry,
                  textColor: Colors.white,
                  onPressed: () =>
                      _sendMessage(messageText: text, messageType: messageType),
                ),
              ),
            );
          }
        }
      });
    } catch (error) {
      print('❌ Error sending message: $error');

      setState(() {
        _error = 'Failed to send message: ${error.toString()}';
        _isSending = false;
      });

      // Restore message to text field
      _messageController.text = text;

      // Handle 429 errors
      if (error.toString().contains('429') ||
          ApiErrorHandler.isLimitExceededError(error)) {
        if (mounted) {
          await ApiErrorHandler.handleLimitExceededError(
            context: context,
            error: error,
            userId: _currentUserId,
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.failedToSendMessage}: ${error.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              textColor: Colors.white,
              onPressed: () =>
                  _sendMessage(messageText: text, messageType: messageType),
            ),
          ),
        );
      }
    }
  }

  void _showSendError(
    String errorMessage,
    String originalText,
    String? messageType,
  ) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    String displayMessage = l10n.failedToSendMessage;

    if (errorMessage.toLowerCase().contains('limit exceeded') ||
        errorMessage.toLowerCase().contains('limit')) {
      displayMessage = l10n.dailyMessageLimitExceeded;
    } else if (errorMessage.toLowerCase().contains('blocked')) {
      displayMessage = l10n.cannotSendMessageUserMayBeBlocked;
    } else if (errorMessage.toLowerCase().contains('not found')) {
      displayMessage = l10n.userNotFound;
    } else if (errorMessage.toLowerCase().contains('unauthorized') ||
        errorMessage.toLowerCase().contains('401')) {
      displayMessage = l10n.sessionExpired;
    } else {
      displayMessage = errorMessage;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.retry,
          textColor: Colors.white,
          onPressed: () =>
              _sendMessage(messageText: originalText, messageType: messageType),
        ),
      ),
    );
  }

  void _sendSticker(String sticker) async {
    // Show confirmation dialog for stickers/emojis
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(sticker, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.sendThisSticker,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _sendMessage(messageText: sticker, messageType: 'sticker');
    }
  }

  Future<void> _handleMediaOption(String option) async {
    _hidePanels();

    try {
      switch (option) {
        case 'camera':
          await _pickImageFromCamera();
          break;
        case 'gallery':
          await _pickImageFromGallery();
          break;
        case 'document':
          await _pickDocument();
          break;
        case 'audio':
          await _pickAudio();
          break;
        case 'location':
          await _shareLocation();
          break;
        case 'contact':
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact sharing coming soon!')),
            );
          }
          break;
        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Feature coming soon: $option')),
            );
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress to reduce file size
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);

        // Show preview dialog before sending
        await ImagePreviewDialog.show(
          context: context,
          imageFile: file,
          onSend: (caption) async {
            await _sendMediaFile(file, 'image', caption: caption);
          },
        );
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress to reduce file size
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);

        // Show preview dialog before sending
        await ImagePreviewDialog.show(
          context: context,
          imageFile: file,
          onSend: (caption) async {
            await _sendMediaFile(file, 'image', caption: caption);
          },
        );
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    // Note: file_picker package would be needed for document picking
    // For now, show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document picker requires file_picker package. Please add it to pubspec.yaml',
          ),
        ),
      );
    }
    // TODO: Implement document picker when file_picker is added
  }

  Future<void> _pickAudio() async {
    // Note: For audio recording, you might want to use a recording package
    // For now, we'll use image_picker to pick audio files from gallery
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Audio recording feature coming soon! Use gallery to select audio files.',
          ),
        ),
      );
    }
    // TODO: Implement audio recording/picking
  }

  Future<void> _shareLocation() async {
    try {
      // Request location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to share location',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      String? address;
      String? placeName;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          address = '${place.street}, ${place.locality}, ${place.country}';
          placeName = place.name;
        }
      } catch (e) {
        print('Error reverse geocoding: $e');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Send location
      final result = await MediaService.sendMessageWithLocation(
        receiverId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        placeName: placeName,
      );

      if (result['success'] == true) {
        // Refresh messages
        await _loadMessages();
        // Refresh limits
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to share location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMediaFile(
    File file,
    String? mediaType, {
    String? caption,
  }) async {
    try {
      // Auto-detect media type if not provided or if file is actually a video
      String? detectedType = mediaType;
      final path = file.path.toLowerCase();
      if (path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.mkv') ||
          path.contains('video') ||
          path.contains('.mov')) {
        detectedType = 'video';
      } else if (detectedType == null) {
        // Default to image if not specified
        detectedType = 'image';
      }

      // Basic validation (size check only - let backend validate file type)
      final validation = MediaService.validateMediaFile(file, detectedType);
      if (!validation['valid']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation['error'] ?? 'Invalid file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check limits before sending
      try {
        final userAsync = ref.read(userProvider);
        final user = await userAsync.when(
          data: (user) => user,
          loading: () => null,
          error: (error, stack) {
            print('Error loading user for limit check: $error');
            return null;
          },
        );

        if (user != null && _currentUserId != null) {
          final limits = ref.read(currentUserLimitsProvider(_currentUserId!));

          if (!FeatureGate.canSendMessage(user, limits)) {
            await LimitExceededDialog.show(
              context: context,
              limitType: 'messages',
              limitInfo: limits?.messages,
              resetTime: limits?.resetTime,
              userId: _currentUserId!,
            );
            return;
          }
        }
      } catch (e) {
        print('Error checking limits: $e');
      }

      // Show loading indicator
      setState(() {
        _isSending = true;
      });

      // Send media
      final result = await MediaService.sendMessageWithMedia(
        receiverId: widget.userId,
        messageText: caption, // Use the caption provided from preview
        mediaFile: file,
        mediaType: detectedType ?? validation['mediaType'] ?? 'image',
      );

      setState(() {
        _isSending = false;
      });

      if (result['success'] == true) {
        // Refresh messages
        await _loadMessages();
        // Refresh limits
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to send media'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending media: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onTyping() async {
    if (!_isTyping && _currentUserId != null) {
      _isTyping = true;
      _chatSocketService.sendTypingIndicator(widget.userId, true);
    }
    
    // Auto-stop typing after 3 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 3), () {
      if (_isTyping) {
        _stopTyping();
      }
    });
  }

  Future<void> _stopTyping() async {
    if (_isTyping && _currentUserId != null) {
      _isTyping = false;
      _chatSocketService.sendTypingIndicator(widget.userId, false);
    }
    _typingTimer?.cancel();
  }

  void _onTextChanged(String text) {
    // Send typing indicator
    if (text.isNotEmpty && !_isTyping) {
      _onTyping();
    } else if (text.isEmpty && _isTyping) {
      _stopTyping();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleMessageSelection(Message message, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedMessageIds.add(message.id);
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
      } else {
        _selectedMessageIds.remove(message.id);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      }
    });
  }

  /// Check if message can be edited (within 15 minutes)
  bool _canEditMessage(Message message) {
    if (message.isDeleted || message.media != null) {
      return false; // Cannot edit deleted messages or messages with media
    }

    try {
      final messageTime = parseToKoreaTime(message.createdAt);
      final now = getKoreaNow();
      final difference = now.difference(messageTime);
      return difference.inMinutes < 15;
    } catch (e) {
      return false;
    }
  }

  /// Check if message can be deleted for everyone (within 1 hour)
  bool _canDeleteForEveryone(Message message) {
    try {
      final messageTime = parseToKoreaTime(message.createdAt);
      final now = getKoreaNow();
      final difference = now.difference(messageTime);
      return difference.inHours < 1;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleDeleteMessage(Message message) async {
    print('🗑️ Delete message called for: ${message.id}');

    if (_currentUserId == null || message.sender.id != _currentUserId) {
      print(
        '❌ Not authorized to delete - currentUserId: $_currentUserId, senderId: ${message.sender.id}',
      );
      return; // Only sender can delete
    }

    final canDeleteForEveryone = _canDeleteForEveryone(message);
    print('✅ Can delete for everyone: $canDeleteForEveryone');

    // Show delete options dialog
    final deleteOption = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Message',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose how you want to delete this message:'),
              const SizedBox(height: 16),
              if (canDeleteForEveryone)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete for everyone'),
                  subtitle: const Text(
                    'Removes the message for both you and the recipient',
                  ),
                  onTap: () => Navigator.pop(context, 'deleteForEveryone'),
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.orange),
                title: const Text('Delete for me'),
                subtitle: const Text('Removes the message only from your chat'),
                onTap: () => Navigator.pop(context, 'deleteForMe'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (deleteOption == null) return;

    final deleteForEveryone = deleteOption == 'deleteForEveryone';

    if (deleteForEveryone && !canDeleteForEveryone) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message can only be deleted for everyone within 1 hour',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final messageService = ref.read(messageServiceProvider);
      final result = await messageService.deleteMessage(
        messageId: message.id,
        deleteForEveryone: deleteForEveryone,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (result['success'] == true) {
        print('✅ Message deleted successfully');

        if (deleteForEveryone) {
          // Update message to show "deleted" placeholder
          setState(() {
            final index = _messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              // Create updated message with deleted status
              final json = message.toJson();
              json['isDeleted'] = true;
              json['deletedForEveryone'] = true;
              json['message'] = 'This message was deleted';
              final deletedMessage = Message.fromJson(json);
              _messages[index] = deletedMessage;
              print('✅ Message updated to deleted state at index $index');
            }
          });
        } else {
          // Remove message from local list (delete for me only)
          setState(() {
            final beforeCount = _messages.length;
            _messages.removeWhere((m) => m.id == message.id);
            final afterCount = _messages.length;
            print(
              '✅ Messages: $beforeCount -> $afterCount (removed: ${beforeCount - afterCount})',
            );
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Message deleted successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete message'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleEditMessage(Message message) async {
    print('✏️ Edit message called for: ${message.id}');

    if (_currentUserId == null || message.sender.id != _currentUserId) {
      print(
        '❌ Not authorized to edit - currentUserId: $_currentUserId, senderId: ${message.sender.id}',
      );
      return; // Only sender can edit
    }

    if (!_canEditMessage(message)) {
      print('❌ Cannot edit - time limit exceeded or invalid message');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message can only be edited within 15 minutes of sending',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Show edit dialog
    final editedText = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final textController = TextEditingController(
          text: message.message ?? '',
        );
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Edit Message',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterYourMessage,
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {}); // Update character count
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${textController.text.length}/2000',
                      style: TextStyle(
                        fontSize: 12,
                        color: textController.text.length > 2000
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      textController.text.trim().isNotEmpty &&
                          textController.text.length <= 2000
                      ? () {
                          Navigator.pop(context, textController.text.trim());
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (editedText == null || editedText == message.message) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final messageService = ref.read(messageServiceProvider);
      final result = await messageService.editMessage(
        messageId: message.id,
        message: editedText,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (result['success'] == true) {
        // Update message in local list
        print('✅ Edit API response: ${result['data']}');

        // Handle both Message object and Map response
        Message updatedMessage;
        if (result['data'] is Message) {
          updatedMessage = result['data'] as Message;
        } else if (result['data'] is Map) {
          updatedMessage = Message.fromJson(
            result['data'] as Map<String, dynamic>,
          );
        } else {
          print('❌ Unexpected data type: ${result['data'].runtimeType}');
          return;
        }

        print(
          '✅ Message updated: ${updatedMessage.id}, new text: ${updatedMessage.message}',
        );

        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
            print('✅ Message updated in list at index $index');
          } else {
            print('⚠️ Message not found in list to update');
            // Add it if not found (shouldn't happen, but just in case)
            _messages.add(updatedMessage);
            _messages.sort(
              (a, b) => DateTime.parse(
                a.createdAt,
              ).compareTo(DateTime.parse(b.createdAt)),
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Message edited successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to edit message'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error editing message: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleReplyMessage(Message message) {
    print('💬 Reply to message: ${message.id}');
    setState(() {
      _replyingToMessage = message;
    });
    // Focus on input field
    FocusScope.of(context).requestFocus(FocusNode());
    // Scroll to bottom to show reply preview
    _scrollToBottom();
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  Future<void> _handleForwardMessage(Message message) async {
    print('📤 Forward message: ${message.id}');

    // Get list of chat partners/users to forward to
    try {
      final messageService = ref.read(messageServiceProvider);
      final allMessages = await messageService.getUserMessages(
        id: _currentUserId,
      );

      // Extract unique user IDs from messages (excluding current user and current chat partner)
      final Set<String> userIds = {};
      for (final msg in allMessages) {
        if (msg.sender.id != _currentUserId && msg.sender.id != widget.userId) {
          userIds.add(msg.sender.id);
        }
        if (msg.receiver.id != _currentUserId &&
            msg.receiver.id != widget.userId) {
          userIds.add(msg.receiver.id);
        }
      }

      if (userIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No other users to forward to'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Show dialog to select users
      final selectedUserIds = await showDialog<List<String>>(
        context: context,
        builder: (context) => ForwardMessageDialog(
          userIds: userIds.toList(),
          messageService: messageService,
        ),
      );

      if (selectedUserIds == null || selectedUserIds.isEmpty) return;

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Forward message
      final result = await messageService.forwardMessage(
        messageId: message.id,
        receivers: selectedUserIds,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Message forwarded successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to forward message'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error forwarding message: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handlePinMessage(Message message) async {
    try {
      // TODO: Implement pin message API call
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pin message feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pin message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUnpinMessage(Message message) async {
    try {
      // TODO: Implement unpin message API call
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unpin message feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unpin message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _disconnectSocket() {
    // Unregister from global socket service
    SocketService().unregisterSocket(_socket);

    // Remove all socket listeners before disconnecting
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    // Send stop typing when leaving chat
    if (_isTyping) {
      _chatSocketService.sendTypingIndicator(widget.userId, false);
    }
    _disconnectSocket();
    _messageController.dispose();
    _scrollController.dispose();
    _mediaPanelController.dispose();
    _stickerPanelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        userName: widget.userName,
        profilePicture: widget.profilePicture,
        isTyping: _otherUserTyping,
        userId: widget.userId,
        isConnected: _isSocketConnected,
        isOnline: _isOtherUserOnline,
        lastSeen: _otherUserLastSeen,
        onThemeChanged: _loadChatWallpaper, // Reload wallpaper when changed
      ),
      body: Container(
        decoration: _getWallpaperDecoration(),
        child: GestureDetector(
          onTap: _hidePanels,
          child: Column(
            children: [
              // Add connection status indicator
              ConnectionStatusIndicator(),
              
              Expanded(
                child: ChatMessagesList(
                  isLoading: _isLoading,
                  error: _error,
                  messages: _messages,
                  currentUserId: _currentUserId,
                  otherUserName: widget.userName,
                  otherUserPicture: widget.profilePicture,
                  otherUserTyping: _otherUserTyping,
                  scrollController: _scrollController,
                  onRetry: _loadMessages,
                  isSelectionMode: _isSelectionMode,
                  selectedMessageIds: _selectedMessageIds,
                  onSelectionChanged: _handleMessageSelection,
                  onDelete: _handleDeleteMessage,
                  onEdit: _handleEditMessage,
                  onReply: _handleReplyMessage,
                  onPin: _handlePinMessage,
                  onUnpin: _handleUnpinMessage,
                  onForward: _handleForwardMessage,
                ),
              ),
              ChatInputSection(
                messageController: _messageController,
                isSending: _isSending,
                showMediaPanel: _showMediaPanel,
                showStickerPanel: _showStickerPanel,
                mediaPanelController: _mediaPanelController,
                stickerPanelController: _stickerPanelController,
                onSendMessage: _sendMessage,
                onSendSticker: _sendSticker,
                onToggleMediaPanel: _toggleMediaPanel,
                onToggleStickerPanel: _toggleStickerPanel,
                onTyping: _onTyping,
                onStopTyping: _stopTyping,
                onHidePanels: _hidePanels,
                onMediaOption: _handleMediaOption,
                replyingToMessage: _replyingToMessage,
                otherUserName: widget.userName,
                onCancelReply: _cancelReply,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get wallpaper decoration
  BoxDecoration _getWallpaperDecoration() {
    if (_chatWallpaper == null) {
      return BoxDecoration(color: Colors.grey[100]); // Default
    }

    // Handle gradient wallpapers
    if (_chatWallpaper!.startsWith('gradient_')) {
      return BoxDecoration(gradient: _getGradient(_chatWallpaper!));
    }

    // Handle solid color wallpapers
    return BoxDecoration(color: _getColor(_chatWallpaper!));
  }

  LinearGradient? _getGradient(String gradientName) {
    switch (gradientName) {
      case 'gradient_blue':
        return const LinearGradient(
          colors: [Color(0xFF4158D0), Color(0xFFC850C0), Color(0xFFFFCC70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_green':
        return const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_pink':
        return const LinearGradient(
          colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_purple':
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'dark':
        return const Color(0xFF1A1A2E);
      case 'light':
        return const Color(0xFFFFFFFF);
      case 'blue':
        return const Color(0xFF1E3A5F);
      case 'pink':
        return const Color(0xFFE8B4BC);
      case 'green':
        return const Color(0xFF2D5A27);
      case 'purple':
        return const Color(0xFF6B5B95);
      case 'sunset':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey[100]!;
    }
  }
}
