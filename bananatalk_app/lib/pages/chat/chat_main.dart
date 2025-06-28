import 'dart:async';

import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/services.dart';

// Chat partner model to organize conversations
class ChatPartner {
  final String id;
  final String name;
  final String? avatar;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageTime;
  final List<String> imageUrls;
  final String status;
  final DateTime? lastSeen;

  ChatPartner({
    required this.id,
    required this.name,
    this.avatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.imageUrls = const [],
    this.status = 'online',
    this.lastSeen,
  });

  ChatPartner copyWith({
    String? id,
    String? name,
    String? avatar,
    String? lastMessage,
    int? unreadCount,
    DateTime? lastMessageTime,
    List<String>? imageUrls,
    String? status,
    DateTime? lastSeen,
  }) {
    return ChatPartner(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

class ChatMain extends ConsumerStatefulWidget {
  const ChatMain({super.key});

  @override
  ConsumerState<ChatMain> createState() => _ChatMainState();
}

class _ChatMainState extends ConsumerState<ChatMain>
    with TickerProviderStateMixin {
  late Future<List<Message>> _messagesFuture;
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  List<ChatPartner> _chatPartners = [];
  String? _currentUserId;
  String? _activeUserId;
  IO.Socket? _socket;
  Map<String, Map<String, dynamic>> _userStatuses = {};
  Map<String, bool> _typingUsers = {};
  Timer? _typingTimer;
  Timer? _sendTypingTimer;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Constants - replace with your actual base URL
  static const String BASE_URL = 'https://api.banatalk.com';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchMessages();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _disconnectSocket();
    super.dispose();
  }

  void _initializeSocket() async {
    // Disconnect existing socket if any
    _disconnectSocket();

    if (_currentUserId == null) {
      print('⚠️ Cannot initialize socket - user ID not available');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      print('⚠️ Cannot initialize socket - token not available');
      return;
    }

    try {
      _socket = IO.io(
        BASE_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .setQuery({'userId': _currentUserId})
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setTimeout(5000)
            .build(),
      );

      _socket?.onConnect((_) {
        // Request status updates for all chat partners
        if (_chatPartners.isNotEmpty && _socket != null) {
          _socket!.emit('requestStatusUpdates',
              {'userIds': _chatPartners.map((p) => p.id).toList()});
        }
      });

      // Handle new incoming messages
      _socket?.on('newMessage', (data) {
        print('📨 Received new message: $data');
        _handleNewMessage(data);
      });

      // Handle message sent acknowledgment
      _socket?.on('messageSent', (data) {
        print('📤 Message sent acknowledgment: $data');
        _handleMessageSent(data);
      });

      // Handle status updates
      _socket?.on('typing', (data) {
        print('⌨️ User typing event received: $data');
        _handleUserTyping(data);
      });

      // Handle user typing indicators
      _socket?.on('userTyping', (data) {
        print('⌨️ User typing event received: $data');
        _handleUserTyping(data);
      });

      // Handle user stopped typing
      _socket?.on('userStoppedTyping', (data) {
        print('⌨️ User stopped typing: $data');
        _handleUserStoppedTyping(data);
      });

      // Handle bulk status updates
      _socket?.on('bulkStatusUpdate', (data) {
        print('📊 Bulk status update: $data');
        _handleBulkStatusUpdate(data);
      });

      // Handle message read receipts
      _socket?.on('messageRead', (data) {
        print('👁️ Message read: $data');
        _handleMessageRead(data);
      });

      _socket?.onDisconnect((_) {
        print('❌ Disconnected from socket server');
      });
      _socket?.on('onlineUsers', (data) {
        print('👥 Received online users: $data');
        if (data is List) {
          for (var userData in data) {
            _handleStatusUpdate(userData);
          }
        }
      });

      _socket?.onConnectError((err) {
        print('❌ Connection error: $err');
        setState(() {
          _error = 'Connection error: $err';
        });
      });

      _socket?.onError((err) {
        print('❌ Socket error: $err');
      });

      _socket?.connect();
    } catch (e) {
      print('❌ Socket initialization error: $e');
    }
  }

  void _handleUserTyping(dynamic data) {
    try {
      final String userId = data['userId'].toString() ?? '';
      final bool isTyping = data['isTyping'] ?? true;
      if (userId.isEmpty || userId == _currentUserId) {
        return;
      }
      setState(() {
        _typingUsers[userId] = true;
        print('✅ User $userId started typing');
      });
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 5), () {
        setState(() {
          _typingUsers[userId] = false;
          print('⏰ Typing timeout for user $userId');
        });
      });
      print('✅ User $userId started typing');
    } catch (e) {
      print('❌ Error handling typing event: $e');
    }
  }

  void _handleNewMessage(dynamic data) {
    try {
      if (!mounted) return;

      final messageData = data['message'];
      final senderId = data['senderId'];
      final unreadCount = data['unreadCount'] ?? 1;

      if (messageData == null || senderId == null) {
        print('⚠️ Invalid message data received');
        return;
      }

      // Play notification sound/haptic feedback
      HapticFeedback.lightImpact();

      // Update chat partners list
      setState(() {
        final existingPartnerIndex =
            _chatPartners.indexWhere((p) => p.id == senderId);

        if (existingPartnerIndex != -1) {
          // Update existing partner
          final existingPartner = _chatPartners[existingPartnerIndex];
          final updatedPartner = existingPartner.copyWith(
            lastMessage: messageData['message'],
            unreadCount: unreadCount,
            lastMessageTime: DateTime.parse(messageData['createdAt']),
          );

          // Move to top of list
          _chatPartners.removeAt(existingPartnerIndex);
          _chatPartners.insert(0, updatedPartner);
        } else {
          // Add new chat partner
          final senderInfo = messageData['sender'];
          final newPartner = ChatPartner(
            id: senderId,
            name: senderInfo['name'] ?? 'Unknown',
            avatar: senderInfo['imageUrls']?.isNotEmpty == true
                ? senderInfo['imageUrls'][0]
                : null,
            lastMessage: messageData['message'],
            unreadCount: unreadCount,
            lastMessageTime: DateTime.parse(messageData['createdAt']),
            imageUrls: List<String>.from(senderInfo['imageUrls'] ?? []),
          );
          _chatPartners.insert(0, newPartner);
        }
      });
    } catch (e) {
      print('❌ Error handling new message: $e');
    }
  }

  void _handleMessageSent(dynamic data) {
    try {
      if (!mounted) return;

      final messageData = data['message'];
      final receiverId = data['receiverId'];

      if (messageData == null || receiverId == null) return;

      // Update chat partners list for sent message
      setState(() {
        final existingPartnerIndex =
            _chatPartners.indexWhere((p) => p.id == receiverId);

        if (existingPartnerIndex != -1) {
          final existingPartner = _chatPartners[existingPartnerIndex];
          final updatedPartner = existingPartner.copyWith(
            lastMessage: messageData['message'],
            lastMessageTime: DateTime.parse(messageData['createdAt']),
          );

          // Move to top of list
          _chatPartners.removeAt(existingPartnerIndex);
          _chatPartners.insert(0, updatedPartner);
        }
      });
    } catch (e) {
      print('❌ Error handling message sent: $e');
    }
  }

  void _handleStatusUpdate(dynamic data) {
    try {
      final userId = data['userId'];
      final status = data['status'];
      final lastSeen = data['lastSeen'];

      if (userId == null) return;

      setState(() {
        _userStatuses[userId] = {
          'status': status,
          'lastSeen': lastSeen != null ? DateTime.parse(lastSeen) : null,
        };
      });

      _processChatPartnersWithStatus();
    } catch (e) {
      print('❌ Error handling status update: $e');
    }
  }

  String _getStatusText(String status, DateTime? lastSeen) {
    switch (status.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'away':
        return 'Away';
      case 'busy':
      case 'dnd':
        return 'Busy';
      case 'recently online':
        return 'Recently online';
      case 'offline':
      default:
        if (lastSeen != null) {
          final now = DateTime.now();
          final difference = now.difference(lastSeen);

          if (difference.inMinutes < 1) {
            return 'Just now';
          } else if (difference.inMinutes < 60) {
            return '${difference.inMinutes}m ago';
          } else if (difference.inHours < 24) {
            return '${difference.inHours}h ago';
          } else if (difference.inDays < 7) {
            return '${difference.inDays}d ago';
          } else {
            return 'Long time ago';
          }
        }
        return 'Offline';
    }
  }

  void _handleBulkStatusUpdate(dynamic data) {
    try {
      final Map<String, dynamic> statuses = Map<String, dynamic>.from(data);

      setState(() {
        statuses.forEach((userId, statusData) {
          _userStatuses[userId] = {
            'status': statusData['status'],
            'lastSeen': statusData['lastSeen'] != null
                ? DateTime.parse(statusData['lastSeen'])
                : null,
          };
        });
      });

      _processChatPartnersWithStatus();
    } catch (e) {
      print('❌ Error handling bulk status update: $e');
    }
  }

  void _handleUserStoppedTyping(dynamic data) {
    // Handle stopped typing indicators if needed
    print('User ${data['userId']} stopped typing');
  }

  void _handleMessageRead(dynamic data) {
    try {
      final senderId = data['senderId'];

      if (senderId == null) return;

      // Update unread count to 0 for this chat partner
      setState(() {
        final partnerIndex = _chatPartners.indexWhere((p) => p.id == senderId);
        if (partnerIndex != -1) {
          _chatPartners[partnerIndex] = _chatPartners[partnerIndex].copyWith(
            unreadCount: 0,
          );
        }
      });
    } catch (e) {
      print('❌ Error handling message read: $e');
    }
  }

  void _disconnectSocket() {
    try {
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }
    } catch (e) {
      print('❌ Error disconnecting socket: $e');
      _socket = null;
    }
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final messageService = ref.read(messageServiceProvider);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      setState(() {
        _currentUserId = userId;
      });

      // Initialize socket with the new user ID
      _initializeSocket();

      _messagesFuture = messageService.getUserMessages(id: userId);
      final messages = await _messagesFuture;
      _processChatPartners(messages);

      // Request status updates after chat partners are loaded
      if (_socket != null && _socket!.connected && _chatPartners.isNotEmpty) {
        _socket!.emit('requestStatusUpdates',
            {'userIds': _chatPartners.map((p) => p.id).toList()});
      }
    } catch (error) {
      setState(() {
        _error = 'Failed to load messages: $error';
      });
      // Attempt to reconnect socket if disconnected
      if (_socket?.disconnected ?? true) {
        _initializeSocket();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processChatPartners(List<Message> messages) {
    if (_currentUserId == null) return;

    final Map<String, ChatPartner> partnersMap = {};
    final now = DateTime.now();

    for (final message in messages) {
      try {
        final isSender = message.sender.id == _currentUserId;
        final otherUser = isSender ? message.receiver : message.sender;
        final isIncoming = !isSender;
        final isUnread = isIncoming && !message.read;
        final messageDate = DateTime.parse(message.createdAt);

        final existingPartner = partnersMap[otherUser.id];
        final userStatus = _userStatuses[otherUser.id]?['status'] ?? 'offline';
        final lastSeen = _userStatuses[otherUser.id]?['lastSeen'];

        // Calculate time difference for "last seen" status
        String statusDisplay = userStatus;
        if (userStatus == 'offline' && lastSeen != null) {
          final difference = now.difference(lastSeen);
          if (difference.inMinutes < 5) {
            statusDisplay = 'recently online';
          }
        }

        if (existingPartner == null) {
          partnersMap[otherUser.id] = ChatPartner(
            id: otherUser.id,
            name: otherUser.name,
            avatar:
                otherUser.imageUrls.isNotEmpty ? otherUser.imageUrls[0] : null,
            lastMessage: message.message,
            unreadCount: isUnread ? 1 : 0,
            lastMessageTime: messageDate,
            imageUrls: otherUser.imageUrls,
            status: statusDisplay,
            lastSeen: lastSeen,
          );
        } else {
          // Only update if this message is newer
          final shouldUpdateMessage = existingPartner.lastMessageTime == null ||
              messageDate.isAfter(existingPartner.lastMessageTime!);

          partnersMap[otherUser.id] = existingPartner.copyWith(
            lastMessage: shouldUpdateMessage
                ? message.message
                : existingPartner.lastMessage,
            unreadCount: isUnread
                ? existingPartner.unreadCount + 1
                : existingPartner.unreadCount,
            lastMessageTime: shouldUpdateMessage
                ? messageDate
                : existingPartner.lastMessageTime,
            status: statusDisplay,
            lastSeen: lastSeen,
          );
        }
      } catch (e) {
        print('Error processing message: $e');
      }
    }

    // Sort by most recent message time
    final sortedPartners = partnersMap.values.toList()
      ..sort((a, b) {
        final aTime = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        final bTime = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

    if (mounted) {
      setState(() {
        _chatPartners = sortedPartners;
      });

      // Request status updates after chat partners are set
      if (_socket != null && _socket!.connected && _chatPartners.isNotEmpty) {
        try {
          _socket!.emit('requestStatusUpdates',
              {'userIds': _chatPartners.map((p) => p.id).toList()});
        } catch (e) {
          print('❌ Error requesting status updates: $e');
        }
      }
    }
  }

  void _processChatPartnersWithStatus() {
    final now = DateTime.now();

    setState(() {
      _chatPartners = _chatPartners.map((partner) {
        String userStatus = _userStatuses[partner.id]?['status'] ?? 'offline';
        DateTime? lastSeen = _userStatuses[partner.id]?['lastSeen'];

        // Calculate display status
        String statusDisplay = userStatus;
        if (userStatus == 'offline' && lastSeen != null) {
          final difference = now.difference(lastSeen);
          if (difference.inMinutes < 5) {
            statusDisplay = 'recently online';
          }
        }

        return partner.copyWith(status: statusDisplay, lastSeen: lastSeen);
      }).toList();
    });
  }

  List<ChatPartner> get _filteredChatPartners {
    if (_searchQuery.trim().isEmpty) return _chatPartners;

    String normalizedQuery = _searchQuery.toLowerCase().trim();

    return _chatPartners.where((partner) {
      // Search by name
      if (partner.name.toLowerCase().contains(normalizedQuery)) return true;

      // Search by message content
      if (partner.lastMessage?.toLowerCase().contains(normalizedQuery) ==
          true) {
        return true;
      }

      return false;
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = '';
    });
    await _fetchMessages();
  }

  void _onSelectUser(String userId, String userName, String? profilePicture) {
    setState(() {
      _activeUserId = userId;
    });

    // Mark messages as read via socket
    if (_socket != null && _socket!.connected) {
      _socket!.emit('markAsRead', {
        'senderId': userId,
        'receiverId': _currentUserId,
      });
    }

    // Update local unread count immediately
    setState(() {
      final partnerIndex = _chatPartners.indexWhere((p) => p.id == userId);
      if (partnerIndex != -1) {
        _chatPartners[partnerIndex] = _chatPartners[partnerIndex].copyWith(
          unreadCount: 0,
        );
      }
    });

    // Navigate to individual chat screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          userId: userId,
          userName: userName,
          profilePicture: profilePicture,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      // Reset active user when returning from chat
      setState(() {
        _activeUserId = null;
      });
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return const Color(0xFF10B981); // green
      case 'away':
        return const Color(0xFFF59E0B); // yellow
      case 'recently online':
        return const Color(0xFF06B6D4); // cyan
      case 'offline':
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(fontSize: 16),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildUsersList() {
    List<ChatPartner> displayPartners = _filteredChatPartners;

    if (_searchQuery.isNotEmpty && displayPartners.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.2),
                      const Color(0xFF8B5CF6).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No matching conversations',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (displayPartners.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No conversations yet',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a conversation to see it appear here',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          itemCount: displayPartners.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final partner = displayPartners[index];
            bool isActive = _activeUserId == partner.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : const Color(0xFF1A1A1D),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () =>
                      _onSelectUser(partner.id, partner.name, partner.avatar),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar with status indicator
                        Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: partner.avatar != null
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6)
                                        ],
                                      ),
                                border: isActive
                                    ? Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: partner.avatar != null &&
                                      partner.avatar!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Image.network(
                                        partner.avatar!,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 56,
                                            height: 56,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF6366F1),
                                                  Color(0xFF8B5CF6)
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                partner.name.isNotEmpty
                                                    ? partner.name[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2A2A2D),
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Color(0xFF6366F1),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        partner.name.isNotEmpty
                                            ? partner.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                            ),
                            // Status indicator
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(partner.status),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFF1A1A1D),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getStatusColor(partner.status)
                                          .withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      partner.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: isActive
                                            ? Colors.white
                                            : Colors.grey[200],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (partner.lastMessageTime != null)
                                    Text(
                                      _formatTime(partner.lastMessageTime!),
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: _typingUsers[partner.id] == true
                                        ? _buildTypingIndicator()
                                        : Text(
                                            partner.lastMessage ??
                                                'No messages yet',
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.white
                                                      .withOpacity(0.8)
                                                  : Colors.grey[400],
                                              fontSize: 14,
                                              fontWeight:
                                                  partner.unreadCount > 0
                                                      ? FontWeight.w500
                                                      : FontWeight.w400,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                  ),
                                  if (partner.unreadCount > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isActive
                                            ? const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Colors.white
                                                ],
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFFEF4444),
                                                  Color(0xFFDC2626),
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isActive
                                                ? Colors.white.withOpacity(0.3)
                                                : const Color(0xFFEF4444)
                                                    .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        partner.unreadCount > 99
                                            ? '99+'
                                            : partner.unreadCount.toString(),
                                        style: TextStyle(
                                          color: isActive
                                              ? const Color(0xFF6366F1)
                                              : Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'typing',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 6) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B), // Deep dark background
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFEC4899), // Pink
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Messages',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Loading conversations...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1D),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: LinearGradient(
                              colors: [
                                Colors.red[400]!.withOpacity(0.2),
                                Colors.red[600]!.withOpacity(0.2),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.red[400]!.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 32,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Connection Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text(
                              'Try Again',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  backgroundColor: const Color(0xFF1A1A1D),
                  color: const Color(0xFF6366F1),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(
                        child: _buildUsersList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}
