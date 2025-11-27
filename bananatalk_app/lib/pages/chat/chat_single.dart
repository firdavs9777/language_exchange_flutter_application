import 'package:bananatalk_app/pages/chat/chat_app_bar.dart';
import 'package:bananatalk_app/pages/chat/chat_input_section.dart';
import 'package:bananatalk_app/pages/chat/chat_messages_list.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  String _error = '';
  String? _currentUserId;
  IO.Socket? _socket;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  bool _showMediaPanel = false;
  bool _showStickerPanel = false;

  late AnimationController _mediaPanelController;
  late AnimationController _stickerPanelController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentUser();
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
    if (_currentUserId == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() => _error = "Authentication token not found");
      return;
    }

    // Get base URL from Endpoints (socket connects to root, not /api/v1/)
    final baseUrl = Endpoints.baseURL;
    final socketUrl = baseUrl.endsWith('/api/v1/') 
        ? baseUrl.substring(0, baseUrl.length - 8)
        : baseUrl.replaceAll('/api/v1/', '');
    
    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .setQuery({'userId': _currentUserId})
          .setTimeout(500)
          .build(),
    );

    _setupSocketListeners();
    _socket?.connect();
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('✅ Socket connected successfully');
      setState(() => _error = '');
    });

    _socket?.onConnectError((error) {
      print('❌ Socket connection error: $error');
      setState(() => _error = "Connection failed: $error");
    });

    _socket?.onDisconnect((reason) {
      print('❌ Socket disconnected: $reason');
    });

    _socket?.onError((error) {
      print('❌ Socket error: $error');
      setState(() => _error = "Connection error: $error");
    });

    _socket?.on('message', (data) {
      try {
        final newMessage = Message.fromJson(data);
        _handleNewMessage(newMessage);
      } catch (e) {
        print('❌ Error parsing message: $e');
      }
    });

    _socket?.on('messageSent', (data) {
      try {
        final messageData = data['message'];
        if (messageData != null) {
          final sentMessage = Message.fromJson(messageData);
          _handleNewMessage(sentMessage);
          setState(() => _isSending = false);
        }
      } catch (e) {
        print('❌ Error parsing sent message: $e');
        setState(() => _isSending = false);
      }
    });

    _socket?.on('newMessage', (data) {
      try {
        final messageData = data['message'];
        if (messageData != null) {
          final newMessage = Message.fromJson(messageData);
          _handleNewMessage(newMessage);
        }
      } catch (e) {
        print('❌ Error parsing new message: $e');
      }
    });

    _socket?.on('messageError', (data) {
      setState(() {
        _error = data['message'] ?? 'Unknown error occurred';
        _isSending = false;
      });
      if (data['originalMessage'] != null) {
        _messageController.text = data['originalMessage'];
      }
    });

    _socket?.on('userTyping', (data) {
      if (data['user'] == widget.userId) {
        setState(() => _otherUserTyping = true);
      }
    });

    _socket?.on('userStopTyping', (data) {
      if (data['user'] == widget.userId) {
        setState(() => _otherUserTyping = false);
      }
    });
  }

  void _handleNewMessage(Message newMessage) {
    bool isPartOfConversation = (newMessage.sender.id == widget.userId &&
            newMessage.receiver.id == _currentUserId) ||
        (newMessage.sender.id == _currentUserId &&
            newMessage.receiver.id == widget.userId);

    if (isPartOfConversation) {
      setState(() {
        bool messageExists = _messages.any((msg) => msg.id == newMessage.id);
        if (!messageExists) {
          _messages.add(newMessage);
          _messages.sort((a, b) => DateTime.parse(a.createdAt)
              .compareTo(DateTime.parse(b.createdAt)));
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
        final allMessages =
            await messageService.getUserMessages(id: _currentUserId);
        final conversationMessages = allMessages.where((message) {
          return (message.sender.id == _currentUserId &&
                  message.receiver.id == widget.userId) ||
              (message.sender.id == widget.userId &&
                  message.receiver.id == _currentUserId);
        }).toList();

        conversationMessages.sort((a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));

        setState(() => _messages = conversationMessages);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (error) {
      setState(() => _error = 'Failed to load messages: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage({String? messageText, String? messageType}) async {
    final text = messageText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending || _currentUserId == null) return;

    if (messageText == null) _messageController.clear();
    _stopTyping();
    _hidePanels();

    setState(() {
      _isSending = true;
      _error = '';
    });

    try {
      _socket?.emit('sendMessage', {
        'sender': _currentUserId,
        'receiver': widget.userId,
        'message': text,
        'type': messageType ?? 'text',
      });
    } catch (error) {
      setState(() {
        _error = 'Failed to send message: $error';
        _isSending = false;
      });
      if (messageText == null) _messageController.text = text;
    }
  }

  void _sendSticker(String sticker) {
    _sendMessage(messageText: sticker, messageType: 'sticker');
  }

  void _handleMediaOption(String option) {
    _hidePanels();

    final messages = {
      'camera': 'Camera feature coming soon!',
      'gallery': 'Gallery feature coming soon!',
      'document': 'Document sharing coming soon!',
      'location': 'Location sharing coming soon!',
      'contact': 'Contact sharing coming soon!',
      'audio': 'Audio recording coming soon!',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messages[option] ?? 'Feature coming soon!')),
    );
  }

  void _onTyping() {
    if (!_isTyping && _currentUserId != null) {
      _isTyping = true;
      _socket?.emit('typing', {
        'sender': _currentUserId,
        'receiver': widget.userId,
      });
    }
  }

  void _stopTyping() {
    if (_isTyping && _currentUserId != null) {
      _isTyping = false;
      _socket?.emit('stopTyping', {
        'sender': _currentUserId,
        'receiver': widget.userId,
      });
    }
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

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
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
      ),
      body: GestureDetector(
        onTap: _hidePanels,
        child: Column(
          children: [
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
            ),
          ],
        ),
      ),
    );
  }
}
