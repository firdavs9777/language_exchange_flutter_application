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

class _ChatScreenState extends ConsumerState<ChatScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initSocket();
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
    print(token);

    if (token == null) {
      setState(() => _error = "Authentication token not found");
      return;
    }

    _socket = IO.io(
      'http://localhost:5003',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token}) // Provide authentication token
          .setQuery({'userId': _currentUserId})
          .setTimeout(500)
          .build(),
    );

    // Connection successful
    _socket?.onConnect((_) {
      print('✅ Socket connected successfully');
      setState(() {
        _error = '';
      });
    });

    // Connection error
    _socket?.onConnectError((error) {
      print('❌ Socket connection error: $error');
      setState(() {
        _error = "Connection failed: $error";
      });
    });

    // Disconnection
    _socket?.onDisconnect((reason) {
      print('❌ Socket disconnected: $reason');
    });

    // General errors
    _socket?.onError((error) {
      print('❌ Socket error: $error');
      setState(() => _error = "Connection error: $error");
    });

    // Listen for new messages from backend
    _socket?.on('message', (data) {
      print('📨 Received message: $data');
      try {
        final newMessage = Message.fromJson(data);

        // Only add if it's part of this conversation
        bool isPartOfConversation = (newMessage.sender.id == widget.userId &&
                newMessage.receiver.id == _currentUserId) ||
            (newMessage.sender.id == _currentUserId &&
                newMessage.receiver.id == widget.userId);

        if (isPartOfConversation) {
          setState(() {
            // Check if message already exists to avoid duplicates
            bool messageExists =
                _messages.any((msg) => msg.id == newMessage.id);
            if (!messageExists) {
              _messages.add(newMessage);
              _messages.sort((a, b) => DateTime.parse(a.createdAt)
                  .compareTo(DateTime.parse(b.createdAt)));
              print('✅ Message added to conversation');
            } else {
              print('⚠️ Duplicate message ignored');
            }
          });
          _scrollToBottom();
        } else {
          print('⚠️ Message not part of this conversation');
        }
      } catch (e) {
        print('❌ Error parsing message: $e');
      }
    });

    // Listen for message sent confirmation
    _socket?.on('messageSent', (data) {
      print('✅ Message sent confirmation: $data');
      try {
        final sentMessage = Message.fromJson(data);
        setState(() {
          // Check if message already exists to avoid duplicates
          bool messageExists = _messages.any((msg) => msg.id == sentMessage.id);
          if (!messageExists) {
            _messages.add(sentMessage);
            _messages.sort((a, b) => DateTime.parse(a.createdAt)
                .compareTo(DateTime.parse(b.createdAt)));
            print('✅ Sent message added to conversation');
          }
          _isSending = false;
        });
        _scrollToBottom();
      } catch (e) {
        print('❌ Error parsing sent message: $e');
        setState(() {
          _isSending = false;
        });
      }
    });

    // Listen for message errors
    _socket?.on('messageError', (data) {
      print('❌ Message error: $data');
      setState(() {
        _error = data['message'] ?? 'Unknown error occurred';
        _isSending = false;
      });

      // Restore the original message text
      if (data['originalMessage'] != null) {
        _messageController.text = data['originalMessage'];
      }
    });

    // Listen for typing events
    _socket?.on('userTyping', (data) {
      print('⌨️ User typing: $data');
      if (data['user'] == widget.userId) {
        setState(() {
          _otherUserTyping = true;
        });
      }
    });

    _socket?.on('userStopTyping', (data) {
      print('⌨️ User stopped typing: $data');
      if (data['user'] == widget.userId) {
        setState(() {
          _otherUserTyping = false;
        });
      }
    });

    // Connect to the server
    _socket?.connect();
    print('🔄 Socket connection initiated');
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

        // Filter messages for this specific conversation
        final conversationMessages = allMessages.where((message) {
          return (message.sender.id == _currentUserId &&
                  message.receiver.id == widget.userId) ||
              (message.sender.id == widget.userId &&
                  message.receiver.id == _currentUserId);
        }).toList();

        // Sort messages by creation time
        conversationMessages.sort((a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));

        setState(() {
          _messages = conversationMessages;
        });

        // Scroll to bottom after loading messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (error) {
      setState(() {
        _error = 'Failed to load messages: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _isSending ||
        _currentUserId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();
    _stopTyping();

    setState(() {
      _isSending = true;
      _error = '';
    });

    try {
      // Send message via socket
      _socket?.emit('sendMessage', {
        'sender': _currentUserId,
        'receiver': widget.userId,
        'message': messageText,
      });

      print('Sending message: $messageText to user: ${widget.userId}');
    } catch (error) {
      setState(() {
        _error = 'Failed to send message: $error';
        _isSending = false;
      });

      // Restore message text if sending failed
      _messageController.text = messageText;
    }
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

  Widget _buildMessage(Message message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: widget.profilePicture != null &&
                      widget.profilePicture!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.profilePicture!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 32,
                            height: 32,
                            color: Colors.grey[300],
                            child: Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 32,
                            height: 32,
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(DateTime.parse(message.createdAt)),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(
              message.read ? Icons.done_all : Icons.done,
              size: 16,
              color: message.read ? Colors.blue : Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_otherUserTyping) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: widget.profilePicture != null &&
                    widget.profilePicture!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.profilePicture!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'typing',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              onChanged: (text) {
                if (text.isNotEmpty) {
                  _onTyping();
                } else {
                  _stopTyping();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: widget.profilePicture != null &&
                      widget.profilePicture!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.profilePicture!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 32,
                            height: 32,
                            color: Colors.grey[300],
                            child: Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 32,
                            height: 32,
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_otherUserTyping)
                    Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Add more options (call, video, info, etc.)
              print('More options for ${widget.userName}');
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _error = '';
                                });
                                _loadMessages();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Send a message to start the conversation',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    final isMe =
                                        message.sender.id == _currentUserId;
                                    return _buildMessage(message, isMe);
                                  },
                                ),
                              ),
                              _buildTypingIndicator(),
                            ],
                          ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
