import 'dart:async';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/widgets/limit_indicator.dart';
import 'package:bananatalk_app/widgets/connection_status_indicator.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

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
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs
  ColorScheme get colorScheme => Theme.of(context).colorScheme;
  Color get textPrimary => context.textPrimary;
  Color get secondaryText => context.textSecondary;
  Color get mutedText => context.textMuted;

  late Future<List<Message>> _messagesFuture;
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  List<ChatPartner> _chatPartners = [];
  String? _currentUserId;
  String? _activeUserId;
  final _chatSocketService = ChatSocketService();
  Map<String, Map<String, dynamic>> _userStatuses = {};
  Map<String, bool> _typingUsers = {};
  Timer? _typingTimer;
  Timer? _sendTypingTimer;

  // Stream subscriptions for socket events
  StreamSubscription? _newMessageSub;
  StreamSubscription? _messageSentSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _messageReadSub;
  StreamSubscription? _connectionStateSub;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchMessages();
    _subscribeToSocketEvents();

    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch auth state - disconnect sockets if logged out
    final authService = ref.watch(authServiceProvider);
    if (!authService.isLoggedIn) {
      print('🚫 User logged out - socket should be disconnected');
    }
    // Check if user changed and reconnect socket if needed
    _checkUserChange();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - checking connection');
      _checkUserChange();

      // Reconnect socket if disconnected - but only if reconnection is allowed
      if (_chatSocketService.shouldAllowReconnection) {
        // Validate token still exists before reconnecting
        SharedPreferences.getInstance().then((prefs) {
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            if (!_chatSocketService.isConnected) {
              print('🔌 Socket disconnected - reconnecting');
              _chatSocketService.connect();
            }
          } else {
            print('🚫 Token missing - logout detected, not reconnecting');
          }
        });
      } else {
        print('🚫 Reconnection disabled - logout detected');
      }
    }
  }

  Future<void> _checkUserChange() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');

    // If user ID changed (logout/login with different account)
    if (_currentUserId != null && _currentUserId != currentUserId) {
      print(
        '🔄 User changed from $_currentUserId to $currentUserId - reconnecting socket',
      );

      // Disconnect old socket
      await _chatSocketService.disconnect();

      // Clear old data
      setState(() {
        _chatPartners = [];
        _userStatuses = {};
        _typingUsers = {};
        _currentUserId = currentUserId;
      });

      // Reinitialize with new user
      await _fetchMessages();
      _subscribeToSocketEvents();
    }
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
    // Cancel all stream subscriptions
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _typingSub?.cancel();
    _statusSub?.cancel();
    _messageReadSub?.cancel();
    _connectionStateSub?.cancel();

    // DON'T disconnect socket here - let it persist
    // _chatSocketService.disconnect();

    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _typingTimer?.cancel();
    _sendTypingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _subscribeToSocketEvents() {
    // Cancel existing subscriptions
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _typingSub?.cancel();
    _statusSub?.cancel();
    _messageReadSub?.cancel();
    _connectionStateSub?.cancel();

    // Subscribe to socket events
    _newMessageSub = _chatSocketService.onNewMessage.listen(_handleNewMessage);
    _messageSentSub = _chatSocketService.onMessageSent.listen(
      _handleMessageSent,
    );
    _typingSub = _chatSocketService.onTyping.listen((data) {
      // Handle both typing and userTyping events
      if (data['isTyping'] == false) {
        _handleUserStoppedTyping(data);
      } else {
        _handleUserTyping(data);
      }
    });
    _statusSub = _chatSocketService.onStatusUpdate.listen((data) {
      // Check if it's a bulk update or single update
      if (data is Map && data.containsKey('userId')) {
        _handleStatusUpdate(data);
      } else if (data is List) {
        for (var userData in data) {
          _handleStatusUpdate(userData);
        }
      } else {
        _handleBulkStatusUpdate(data);
      }
    });
    _messageReadSub = _chatSocketService.onMessageRead.listen((data) {
      // Handle both messageRead and messagesRead events
      if (data['readBy'] != null) {
        _handleMessagesRead(data);
      } else {
        _handleMessageRead(data);
      }
    });
    _connectionStateSub = _chatSocketService.onConnectionStateChange.listen((
      isConnected,
    ) {
      print('🔌 Connection state changed: $isConnected');
      if (isConnected && _chatPartners.isNotEmpty) {
        _chatSocketService.requestStatusUpdates(
          _chatPartners.map((p) => p.id).toList(),
        );
      }
    });
  }

  void _syncUnreadCountsFromProvider(ChatPartnersState providerState) {
    // Sync local unread counts with provider state
    if (_chatPartners.isEmpty) return;
    
    bool needsUpdate = false;
    final updatedPartners = _chatPartners.map((partner) {
      final providerCount = providerState.unreadCounts[partner.id] ?? 0;
      if (partner.unreadCount != providerCount) {
        print('🔄 Syncing unread count from provider: ${partner.name} - ${partner.unreadCount} -> $providerCount');
        needsUpdate = true;
        return partner.copyWith(unreadCount: providerCount);
      }
      return partner;
    }).toList();
    
    if (needsUpdate && mounted) {
      setState(() {
        _chatPartners = updatedPartners;
      });
    }
  }

  void _syncUnreadCounts() {
    // Only sync if we have partners to avoid unnecessary updates
    if (_chatPartners.isEmpty) return;

    final notifier = ref.read(chatPartnersProvider.notifier);
    final currentState = ref.read(chatPartnersProvider);

    // Sync: prefer provider count (which includes real-time updates from GlobalChatListener)
    // Only update provider if local count is higher (meaning we have new unread from API load)
    // Otherwise, update local state to match provider (real-time updates take precedence)
    bool localStateChanged = false;
    final updatedPartners = <ChatPartner>[];

    for (final partner in _chatPartners) {
      final providerCount = currentState.unreadCounts[partner.id] ?? 0;
      final localCount = partner.unreadCount;

      if (localCount > providerCount) {
        // Local count is higher (e.g., from initial API load), update provider
        print('📊 Syncing local count to provider: ${partner.name} - $localCount (provider had $providerCount)');
        notifier.updateUnreadCount(partner.id, localCount);
        updatedPartners.add(partner); // Keep local count
      } else if (localCount != providerCount) {
        // Provider count is different (real-time update), update local state
        print('📊 Syncing provider count to local: ${partner.name} - $providerCount (local had $localCount)');
        updatedPartners.add(partner.copyWith(unreadCount: providerCount));
          localStateChanged = true;
      } else {
        // Counts match, keep as is
        updatedPartners.add(partner);
      }
    }

    // Also remove any partners that are no longer in the list
    final partnerIds = _chatPartners.map((p) => p.id).toSet();
    for (final userId in currentState.unreadCounts.keys) {
      if (!partnerIds.contains(userId)) {
        notifier.clearUnread(userId);
      }
    }

    // Update UI if local state changed
    if (localStateChanged && mounted) {
      setState(() {
        _chatPartners = updatedPartners;
      });
    }

    // Badge count is now automatically updated in the notifier
  }

  void _handleUserTyping(dynamic data) {
    try {
      final String userId = data['userId'].toString() ?? '';
      final bool isTyping = data['isTyping'] ?? true;
      if (userId.isEmpty || userId == _currentUserId) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _typingUsers[userId] = true;
        print('✅ User $userId started typing');
      });
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
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
      print('📨 Processing new message: $data');

      if (data == null) return;

      // Extract message from the data structure
      final messageData = data['message'] ?? data;

      // Extract sender info
      final senderId =
          messageData['sender']?['_id']?.toString() ??
          messageData['sender']?.toString();
      final senderName =
          messageData['sender']?['name']?.toString() ?? 'Unknown';
      final senderAvatar = messageData['sender']?['image']?.toString();
      final senderImageUrls =
          (messageData['sender']?['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final messageText = messageData['message']?.toString() ?? '';
      final createdAt = messageData['createdAt'] != null
          ? DateTime.parse(messageData['createdAt'].toString())
          : DateTime.now();

      if (senderId == null || senderId.isEmpty) {
        print('⚠️ No sender ID in message');
        return;
      }

      // Don't process own messages
      if (senderId == _currentUserId) {
        print('ℹ️ Skipping own message');
        return;
      }

      print('✅ New message from: $senderName ($senderId)');

      if (!mounted) return;

      // Read current count from provider (GlobalChatListener may have already updated it)
      final providerState = ref.read(chatPartnersProvider);
      final currentProviderCount = providerState.unreadCounts[senderId] ?? 0;

      setState(() {
        int partnerIndex = _chatPartners.indexWhere((p) => p.id == senderId);

        if (partnerIndex != -1) {
          print('📝 Updating existing chat partner at index $partnerIndex');
          final existingPartner = _chatPartners[partnerIndex];

          // Use provider count instead of calculating locally to avoid double-counting
          // GlobalChatListener already incremented it, so we use the provider's value
          final updatedPartner = existingPartner.copyWith(
            lastMessage: messageText,
            lastMessageTime: createdAt,
            unreadCount:
                currentProviderCount, // Use provider count, not local + 1
          );

          _chatPartners.removeAt(partnerIndex);
          _chatPartners.insert(0, updatedPartner);

          // Don't update provider here - GlobalChatListener already handled it
          // Just sync the local UI state with the provider
          print(
            '✅ Moved chat to top with unread count: ${updatedPartner.unreadCount} (from provider)',
          );
        } else {
          print('➕ Creating new chat partner');
          final newPartner = ChatPartner(
            id: senderId,
            name: senderName,
            avatar: senderAvatar,
            lastMessage: messageText,
            lastMessageTime: createdAt,
            unreadCount: currentProviderCount, // Use provider count
            imageUrls: senderImageUrls,
            status: 'online',
          );

          _chatPartners.insert(0, newPartner);

          // Don't update provider here - GlobalChatListener already handled it
          print(
            '✅ Added new chat partner at top with count: $currentProviderCount (from provider)',
          );
        }
      });

      print('✅ Chat list updated successfully');
    } catch (e, stackTrace) {
      print('❌ Error handling new message: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _handleMessageSent(dynamic data) {
    try {
      print('📤 Processing sent message: $data');

      if (data == null) return;

      final messageData = data['message'] ?? data;

      final receiverId =
          messageData['receiver']?['_id']?.toString() ??
          messageData['receiver']?.toString();
      final receiverName =
          messageData['receiver']?['name']?.toString() ?? 'Unknown';
      final receiverAvatar = messageData['receiver']?['image']?.toString();
      final receiverImageUrls =
          (messageData['receiver']?['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final messageText = messageData['message']?.toString() ?? '';
      final createdAt = messageData['createdAt'] != null
          ? DateTime.parse(messageData['createdAt'].toString())
          : DateTime.now();

      if (receiverId == null || receiverId.isEmpty) {
        print('⚠️ No receiver ID in sent message');
        return;
      }

      print('✅ Sent message to: $receiverName ($receiverId)');

      if (!mounted) return;

      setState(() {
        int partnerIndex = _chatPartners.indexWhere((p) => p.id == receiverId);

        if (partnerIndex != -1) {
          print('📝 Updating existing chat partner for sent message');
          final existingPartner = _chatPartners[partnerIndex];
          final updatedPartner = existingPartner.copyWith(
            lastMessage: messageText,
            lastMessageTime: createdAt,
          );

          _chatPartners.removeAt(partnerIndex);
          _chatPartners.insert(0, updatedPartner);
        } else {
          print('➕ Creating new chat partner for sent message');
          final newPartner = ChatPartner(
            id: receiverId,
            name: receiverName,
            avatar: receiverAvatar,
            lastMessage: messageText,
            lastMessageTime: createdAt,
            unreadCount: 0,
            imageUrls: receiverImageUrls,
            status: 'online',
          );

          _chatPartners.insert(0, newPartner);
        }
      });

      _syncUnreadCounts(); // Sync after update
      print('✅ Chat list updated for sent message');
    } catch (e, stackTrace) {
      print('❌ Error handling sent message: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _handleStatusUpdate(dynamic data) {
    try {
      final userId = data['userId'];
      final status = data['status'];
      final lastSeen = data['lastSeen'];

      if (userId == null) return;

      if (!mounted) return;

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

      if (!mounted) return;

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
    print('User ${data['userId']} stopped typing');
  }

  void _handleMessagesRead(dynamic data) {
    try {
      print('👁️ Messages marked as read: $data');

      final readBy = data['readBy']?.toString();

      if (readBy != null && readBy.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          int index = _chatPartners.indexWhere((p) => p.id == readBy);
          if (index != -1) {
            _chatPartners[index] = _chatPartners[index].copyWith(
              unreadCount: 0,
            );

            // Update provider
            ref.read(chatPartnersProvider.notifier).clearUnread(readBy);
            print('✅ Reset unread count for user: $readBy');
          }
        });
      }
    } catch (e) {
      print('❌ Error handling messages read: $e');
    }
  }

  void _handleMessageRead(dynamic data) {
    try {
      final senderId = data['senderId'];

      if (senderId == null) return;

      if (!mounted) return;

      setState(() {
        final partnerIndex = _chatPartners.indexWhere((p) => p.id == senderId);
        if (partnerIndex != -1) {
          _chatPartners[partnerIndex] = _chatPartners[partnerIndex].copyWith(
            unreadCount: 0,
          );

          // Update provider
          ref.read(chatPartnersProvider.notifier).clearUnread(senderId);
        }
      });
    } catch (e) {
      print('❌ Error handling message read: $e');
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

      // Connect socket if not connected
      if (!_chatSocketService.isConnected) {
        await _chatSocketService.connect();
      }

      _messagesFuture = messageService.getUserMessages(id: userId);
      final messages = await _messagesFuture;
      _processChatPartners(messages);

      // Request status updates after chat partners are loaded
      if (_chatSocketService.isConnected && _chatPartners.isNotEmpty) {
        _chatSocketService.requestStatusUpdates(
          _chatPartners.map((p) => p.id).toList(),
        );
      }
    } catch (error) {
      setState(() {
        _error = 'Failed to load messages: $error';
      });
      // Attempt to reconnect socket if disconnected
      if (!_chatSocketService.isConnected) {
        await _chatSocketService.connect();
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
            avatar: otherUser.imageUrls.isNotEmpty
                ? otherUser.imageUrls[0]
                : null,
            lastMessage: message.message,
            unreadCount: isUnread ? 1 : 0,
            lastMessageTime: messageDate,
            imageUrls: otherUser.imageUrls,
            status: statusDisplay,
            lastSeen: lastSeen,
          );
        } else {
          final shouldUpdateMessage =
              existingPartner.lastMessageTime == null ||
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

    final sortedPartners = partnersMap.values.toList()
      ..sort((a, b) {
        final aTime = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        final bTime = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

    if (mounted) {
      // Get provider counts and update partners with correct unread counts
      final providerState = ref.read(chatPartnersProvider);
      final updatedPartners = sortedPartners.map((partner) {
        // Use provider count if available, otherwise use calculated count
        final providerCount = providerState.unreadCounts[partner.id];
        if (providerCount != null && providerCount != partner.unreadCount) {
          print('📊 Updating unread count for ${partner.name}: ${partner.unreadCount} -> $providerCount (from provider)');
          return partner.copyWith(unreadCount: providerCount);
        }
        return partner;
      }).toList();

      setState(() {
        _chatPartners = updatedPartners;
      });

      // Sync calculated counts to provider (only if provider doesn't have them)
      final notifier = ref.read(chatPartnersProvider.notifier);
      for (final partner in updatedPartners) {
        if (partner.unreadCount > 0 && 
            (providerState.unreadCounts[partner.id] == null || 
             providerState.unreadCounts[partner.id]! < partner.unreadCount)) {
          print('📊 Syncing unread count to provider for ${partner.name}: ${partner.unreadCount}');
          notifier.updateUnreadCount(partner.id, partner.unreadCount);
        }
      }

      if (_chatSocketService.isConnected && _chatPartners.isNotEmpty) {
        try {
          _chatSocketService.requestStatusUpdates(
            _chatPartners.map((p) => p.id).toList(),
          );
        } catch (e) {
          print('❌ Error requesting status updates: $e');
        }
      }
    }
  }

  void _processChatPartnersWithStatus() {
    final now = DateTime.now();

    if (!mounted) return;

    setState(() {
      _chatPartners = _chatPartners.map((partner) {
        String userStatus = _userStatuses[partner.id]?['status'] ?? 'offline';
        DateTime? lastSeen = _userStatuses[partner.id]?['lastSeen'];

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
      if (partner.name.toLowerCase().contains(normalizedQuery)) return true;

      if (partner.lastMessage?.toLowerCase().contains(normalizedQuery) ==
          true) {
        return true;
      }

      return false;
    }).toList();
  }

  Future<void> _forceRefresh() async {
    print('🔄 Force refreshing chat...');

    // Get fresh credentials
    final prefs = await SharedPreferences.getInstance();
    final newUserId = prefs.getString('userId');
    final newToken = prefs.getString('token');

    if (newUserId == null || newToken == null) {
      print('❌ Cannot refresh - missing credentials');
      setState(() {
        _error = 'Please login again';
      });
      return;
    }

    // Disconnect old socket
    await _chatSocketService.disconnect();

    // Clear all data
    setState(() {
      _chatPartners = [];
      _userStatuses = {};
      _typingUsers = {};
      _currentUserId = newUserId;
      _error = '';
    });

    // Fetch messages with new credentials
    await _fetchMessages();
    _subscribeToSocketEvents();
  }

  Future<void> _refresh() async {
    await _forceRefresh();
  }

  void _onSelectUser(String userId, String userName, String? profilePicture) {
    setState(() {
      _activeUserId = userId;
    });

    // Mark as read using socket service
    if (_chatSocketService.isConnected && _currentUserId != null) {
      _chatSocketService.markAsRead(userId, _currentUserId!);
    }

    setState(() {
      final partnerIndex = _chatPartners.indexWhere((p) => p.id == userId);
      if (partnerIndex != -1) {
        _chatPartners[partnerIndex] = _chatPartners[partnerIndex].copyWith(
          unreadCount: 0,
        );

        // Update provider
        ref.read(chatPartnersProvider.notifier).clearUnread(userId);
      }
    });

    // No animation code needed here - it's handled by the route!
    context
        .push(
          '/chat/$userId',
          extra: {'userName': userName, 'profilePicture': profilePicture},
        )
        .then((_) {
          setState(() {
            _activeUserId = null;
          });
        });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        // Vibrant green - active online status
        return const Color(0xFF00E676); // Material Design Green A400
      case 'away':
      case 'busy':
      case 'dnd':
        // Amber/Orange for away/busy
        return const Color(0xFFFFB300); // Material Design Amber A700
      case 'recently online':
        // Cyan for recently online
        return const Color(0xFF00B8D4); // Material Design Cyan A700
      case 'offline':
      default:
        // Muted gray for offline
        return const Color(0xFF9E9E9E); // Material Design Gray 500
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchConversations,
          hintStyle: TextStyle(color: mutedText, fontSize: 16),
          prefixIcon: Icon(Icons.search, color: mutedText, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: mutedText, size: 20),
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
          fillColor: colorScheme.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: TextStyle(fontSize: 16),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildUsersList() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    List<ChatPartner> displayPartners = _filteredChatPartners;

    // ================= NO SEARCH RESULT =================
    if (_searchQuery.isNotEmpty && displayPartners.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: colors.outline),
              const SizedBox(height: 16),
              Text('No matching conversations', style: textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ================= EMPTY STATE =================
    if (displayPartners.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 56, color: colors.outline),
              const SizedBox(height: 16),
              Text('No conversations yet', style: textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Start chatting to see messages here',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.outlineVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ================= LIST =================
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: displayPartners.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.3,
          indent: 88,
          color: colors.outlineVariant.withOpacity(0.3),
        ),
        itemBuilder: (context, index) {
          final partner = displayPartners[index];
          final isActive = _activeUserId == partner.id;

          return InkWell(
            onTap: () =>
                _onSelectUser(partner.id, partner.name, partner.avatar),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // ================= AVATAR =================
                  Stack(
                    children: [
                      CachedCircleAvatar(
                        imageUrl:
                            partner.avatar != null && partner.avatar!.isNotEmpty
                            ? partner.avatar
                            : null,
                        radius: 26,
                        backgroundColor: colors.surfaceVariant,
                        errorWidget: Text(
                          partner.name.isNotEmpty
                              ? partner.name[0].toUpperCase()
                              : '?',
                          style: textTheme.titleMedium,
                        ),
                      ),

                      // Online status indicator
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _getStatusColor(partner.status),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.background,
                              width: 2.5,
                            ),
                            // Add subtle shadow for online status
                            boxShadow: partner.status.toLowerCase() == 'online'
                                ? [
                                    BoxShadow(
                                      color: _getStatusColor(
                                        partner.status,
                                      ).withOpacity(0.6),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // ================= CONTENT =================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Time
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                partner.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (partner.lastMessageTime != null)
                              Text(
                                _formatTime(partner.lastMessageTime!),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.outlineVariant,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Last message + unread
                        Row(
                          children: [
                            Expanded(
                              child: _typingUsers[partner.id] == true
                                  ? _buildTypingIndicator()
                                  : Text(
                                      partner.lastMessage ?? 'No messages yet',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: partner.unreadCount > 0
                                            ? colors.onBackground
                                            : colors.outlineVariant,
                                        fontWeight: partner.unreadCount > 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                            ),
                            if (partner.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  partner.unreadCount > 99
                                      ? '99+'
                                      : partner.unreadCount.toString(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.onError,
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
          );
        },
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
              color: colorScheme.outlineVariant,
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Watch provider to sync unread counts - this will rebuild when provider changes
    final chatPartnersState = ref.watch(chatPartnersProvider);
    
    // Sync local unread counts with provider
    // Use a separate method to avoid setState during build
    _syncUnreadCountsFromProvider(chatPartnersState);

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        actions: [
          if (_currentUserId != null)
            Builder(
              builder: (context) {
                final limitsAsync = ref.watch(
                  userLimitsProvider(_currentUserId!),
                );
                return limitsAsync.when(
                  data: (limits) {
                    if (limits.isVIP) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: LimitIndicator(
                        limit: limits.messages,
                        label: AppLocalizations.of(context)!.messages,
                        compact: true,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Add connection status indicator
          ConnectionStatusIndicator(),

          // Existing body content
          Expanded(
            child: _isLoading
                // ---------- Loading ----------
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                // ---------- Error ----------
                : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 40, color: colors.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Connection error',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.outlineVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _refresh,
                            child: Text(AppLocalizations.of(context)!.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                // ---------- Content ----------
                : RefreshIndicator(
                    onRefresh: _refresh,
                    backgroundColor: colors.surface,
                    color: colors.primary,
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        Expanded(child: _buildUsersList()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
