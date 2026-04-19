import 'dart:async';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/pages/notifications/notification_history_screen.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/user_service.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/widgets/connection_status_indicator.dart';
import 'package:bananatalk_app/widgets/shimmer_loading.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

// Chat partner model to organize conversations
class ChatPartner {
  final String id;
  final String name;
  final String? username;
  final String? avatar;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageTime;
  final List<String> imageUrls;
  final String status;
  final DateTime? lastSeen;
  final bool isVip;
  final bool isPinned;
  final bool isMuted;
  final String? conversationId;

  ChatPartner({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.imageUrls = const [],
    this.status = 'online',
    this.lastSeen,
    this.isVip = false,
    this.isPinned = false,
    this.isMuted = false,
    this.conversationId,
  });

  /// Get display username with @ prefix
  String? get displayUsername => username != null ? '@$username' : null;

  ChatPartner copyWith({
    String? id,
    String? name,
    String? username,
    String? avatar,
    String? lastMessage,
    int? unreadCount,
    DateTime? lastMessageTime,
    List<String>? imageUrls,
    String? status,
    DateTime? lastSeen,
    bool? isVip,
    bool? isPinned,
    bool? isMuted,
    String? conversationId,
  }) {
    return ChatPartner(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isVip: isVip ?? this.isVip,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

/// Get a display-friendly preview of a message for the chat list
String getMessagePreview(Message message) {
  // Check for story reference first
  if (message.storyReference != null) {
    return '📖 Replied to story';
  }

  // Check message type before raw text
  final type = message.type.toLowerCase();
  switch (type) {
    case 'sticker':
      return '😀 Sticker';
    case 'poll':
      return '📊 Poll';
    case 'gif':
      return '🎬 GIF';
  }

  // Check for GIF/media URLs in message text
  final text = message.message ?? '';
  if (text.startsWith('http') && (text.contains('giphy.com') || text.contains('.gif') || text.contains('tenor.com') || text.contains('gph.is') || text.contains('media.giphy'))) {
    return '🎬 GIF';
  }
  // Also catch any URL-only messages (no readable text)
  if (text.startsWith('http') && !text.contains(' ')) {
    return '📎 Media';
  }

  // Check for text message
  if (text.isNotEmpty) {
    return text;
  }

  // Check media type
  if (message.media != null) {
    final mediaType = message.media!.type.toLowerCase();
    switch (mediaType) {
      case 'voice':
        return '🎤 Voice message';
      case 'audio':
        return '🎵 Audio';
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'document':
        return '📄 Document';
      case 'location':
        return '📍 Location';
      default:
        return '📎 Attachment';
    }
  }

  return 'Message';
}

class ChatMain extends ConsumerStatefulWidget {
  final ValueNotifier<int>? tabRefreshNotifier;

  const ChatMain({super.key, this.tabRefreshNotifier});

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
  bool _isRefreshing = false;
  String _error = '';
  String _searchQuery = '';
  String _chatFilter = 'all'; // 'all', 'unread', 'online'
  List<ChatPartner> _chatPartners = [];
  String? _currentUserId;
  String? _activeUserId;
  DateTime _lastFetchTime = DateTime.now();
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

  // Track locally deleted conversations (workaround until backend filters)
  final Set<String> _deletedConversationIds = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchMessages();
    _subscribeToSocketEvents();

    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Listen for tab switches to silently refresh
    widget.tabRefreshNotifier?.addListener(_onTabRefresh);
  }

  void _onTabRefresh() {
    if (mounted && !_isLoading) {
      _fetchMessages(silent: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch auth state - disconnect sockets if logged out
    final authService = ref.watch(authServiceProvider);
    if (!authService.isLoggedIn) {}
    // Check if user changed and reconnect socket if needed
    _checkUserChange();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUserChange();
      // Refresh chat list on resume to pick up new conversations
      _fetchMessages();

      // Reconnect socket if disconnected
      // Use forceReset to clear any failed reconnect attempts from background
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;

        // Check if socket needs reconnection
        if (!_chatSocketService.isConnected) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            // Use forceReset: true to reset reconnect attempts counter
            _chatSocketService.connect(forceReset: true);
          }
        } else {}
      });
    }
  }

  Future<void> _checkUserChange() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');

    // If user ID changed (logout/login with different account)
    if (_currentUserId != null && _currentUserId != currentUserId) {
      if (!mounted) return;

      // Clear old data
      setState(() {
        _chatPartners = [];
        _userStatuses = {};
        _typingUsers = {};
        _currentUserId = currentUserId;
      });

      // Reinitialize with new user
      await _fetchMessages();

      // Force reconnect socket with new user credentials
      await _chatSocketService.forceReconnect();
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

    // Error handler for all streams - log only, let socket service handle reconnection
    void onStreamError(dynamic error, StackTrace stackTrace) {
      // Don't attempt reconnection here - socket service handles it automatically
      // Multiple reconnection sources cause instability
    }

    // Subscribe to socket events with error handlers
    _newMessageSub = _chatSocketService.onNewMessage.listen(
      _handleNewMessage,
      onError: onStreamError,
      onDone: () => debugPrint('📭 New message stream closed'),
    );
    _messageSentSub = _chatSocketService.onMessageSent.listen(
      _handleMessageSent,
      onError: onStreamError,
      onDone: () => debugPrint('📭 Message sent stream closed'),
    );
    _typingSub = _chatSocketService.onTyping.listen(
      (data) {
        // Handle both typing and userTyping events
        if (data['isTyping'] == false) {
          _handleUserStoppedTyping(data);
        } else {
          _handleUserTyping(data);
        }
      },
      onError: onStreamError,
      onDone: () => debugPrint('📭 Typing stream closed'),
    );
    _statusSub = _chatSocketService.onStatusUpdate.listen(
      (data) {
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
      },
      onError: onStreamError,
      onDone: () => debugPrint('📭 Status stream closed'),
    );
    _messageReadSub = _chatSocketService.onMessageRead.listen(
      (data) {
        // Handle both messageRead and messagesRead events
        if (data['readBy'] != null) {
          _handleMessagesRead(data);
        } else {
          _handleMessageRead(data);
        }
      },
      onError: onStreamError,
      onDone: () => debugPrint('📭 Message read stream closed'),
    );
    _connectionStateSub = _chatSocketService.onConnectionStateChange.listen(
      (isConnected) {
        if (isConnected && _chatPartners.isNotEmpty) {
          // Batch status requests to avoid O(n) overhead
          _requestStatusUpdatesInBatches();
        }
      },
      onError: onStreamError,
      onDone: () => debugPrint('📭 Connection state stream closed'),
    );
  }

  /// Request status updates in batches to avoid performance issues
  void _requestStatusUpdatesInBatches() {
    const batchSize = 20;
    final partnerIds = _chatPartners.map((p) => p.id).toList();

    // Split into batches and request with small delays
    for (var i = 0; i < partnerIds.length; i += batchSize) {
      final end = (i + batchSize < partnerIds.length)
          ? i + batchSize
          : partnerIds.length;
      final batch = partnerIds.sublist(i, end);

      // Small delay between batches to avoid flooding
      Future.delayed(Duration(milliseconds: i ~/ batchSize * 100), () {
        if (mounted && _chatSocketService.isConnected) {
          _chatSocketService.requestStatusUpdates(batch);
        }
      });
    }
  }

  void _syncUnreadCountsFromProvider(ChatPartnersState providerState) {
    // Sync local unread counts with provider state
    if (_chatPartners.isEmpty || !mounted) return;

    bool needsUpdate = false;
    final List<ChatPartner> updatedPartners = [];

    for (final partner in _chatPartners) {
      final providerCount = providerState.unreadCounts[partner.id] ?? 0;
      if (partner.unreadCount != providerCount) {
        needsUpdate = true;
        updatedPartners.add(partner.copyWith(unreadCount: providerCount));
      } else {
        updatedPartners.add(partner);
      }
    }

    if (needsUpdate && mounted) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _chatPartners = List.from(updatedPartners);
          });
        }
      });
    }
  }

  /// Force refresh unread counts from provider (call after returning from chat)
  void _forceRefreshUnreadCounts() {
    if (!mounted) return;
    final providerState = ref.read(chatPartnersProvider);

    final List<ChatPartner> updatedPartners = _chatPartners.map((partner) {
      final providerCount = providerState.unreadCounts[partner.id] ?? 0;
      return partner.copyWith(unreadCount: providerCount);
    }).toList();

    setState(() {
      _chatPartners = updatedPartners;
    });
  }

  /// Silently refresh conversations without showing loading state
  /// Used when returning from chat detail to get latest messages
  Future<void> _silentRefresh() async {
    if (!mounted) return;

    try {
      final messageService = ref.read(messageServiceProvider);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) return;

      // Use efficient endpoint
      final chatPartners = await messageService.getChatPartners(
        id: userId,
        limit: 100,
      );
      if (mounted) {
        _processChatPartnersFromServer(chatPartners);
      }
    } catch (e) {
      // Don't show error - this is a background refresh
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
        notifier.updateUnreadCount(partner.id, localCount);
        updatedPartners.add(partner); // Keep local count
      } else if (localCount != providerCount) {
        // Provider count is different (real-time update), update local state
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
      });
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        setState(() {
          _typingUsers[userId] = false;
        });
      });
    } catch (e) {}
  }

  void _handleNewMessage(dynamic data) {
    try {
      if (data == null) return;

      // Extract message from the data structure
      final messageData = data['message'] ?? data;

      // Extract sender info
      final senderId =
          messageData['sender']?['_id']?.toString() ??
          messageData['sender']?.toString();
      final senderName =
          messageData['sender']?['name']?.toString() ?? 'Unknown';
      final senderUsername = messageData['sender']?['username']?.toString();
      final senderAvatar = messageData['sender']?['image']?.toString();
      final senderImageUrls =
          (messageData['sender']?['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      // Extract VIP status
      final senderIsVip =
          messageData['sender']?['userMode'] == 'vip' ||
          messageData['sender']?['vipSubscription']?['isActive'] == true;

      final rawMessageText = messageData['message']?.toString() ?? '';
      final createdAt = messageData['createdAt'] != null
          ? DateTime.parse(messageData['createdAt'].toString())
          : DateTime.now();

      // Check for story reference or GIF URLs
      final hasStoryRef = messageData['storyReference'] != null &&
          messageData['storyReference']['storyId'] != null;
      final isGifUrl = rawMessageText.startsWith('http') &&
          (rawMessageText.contains('giphy.com') || rawMessageText.contains('.gif') || rawMessageText.contains('tenor.com') || rawMessageText.contains('gph.is') || rawMessageText.contains('media.giphy'));
      final isUrlOnly = rawMessageText.startsWith('http') && !rawMessageText.contains(' ');

      // Get message preview based on type/media
      final messageType = messageData['type']?.toString() ?? '';
      String messageText;
      if (hasStoryRef) {
        messageText = '📖 Replied to story';
      } else if (messageType == 'gif' || isGifUrl) {
        messageText = '🎬 GIF';
      } else if (isUrlOnly) {
        messageText = '📎 Media';
      } else if (rawMessageText.isNotEmpty) {
        messageText = rawMessageText;
      } else {
        messageText = rawMessageText;
        final mediaType = messageData['media']?['type']?.toString() ?? '';

        if (messageType == 'sticker') {
          messageText = '😀 Sticker';
        } else if (messageType == 'poll') {
          messageText = '📊 Poll';
        } else if (mediaType == 'voice') {
          messageText = '🎤 Voice message';
        } else if (mediaType == 'audio') {
          messageText = '🎵 Audio';
        } else if (mediaType == 'image') {
          messageText = '📷 Photo';
        } else if (mediaType == 'video') {
          messageText = '🎬 Video';
        } else if (mediaType == 'document') {
          messageText = '📄 Document';
        } else if (mediaType == 'location') {
          messageText = '📍 Location';
        } else if (mediaType.isNotEmpty) {
          messageText = '📎 Attachment';
        }
      }

      if (senderId == null || senderId.isEmpty) {
        return;
      }

      // Don't process own messages
      if (senderId == _currentUserId) {
        return;
      }

      if (!mounted) return;

      // Read current count from provider (GlobalChatListener may have already updated it)
      final providerState = ref.read(chatPartnersProvider);
      final currentProviderCount = providerState.unreadCounts[senderId] ?? 0;

      setState(() {
        int partnerIndex = _chatPartners.indexWhere((p) => p.id == senderId);

        if (partnerIndex != -1) {
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
        } else {
          final newPartner = ChatPartner(
            id: senderId,
            name: senderName,
            username: senderUsername,
            avatar: senderAvatar,
            lastMessage: messageText,
            lastMessageTime: createdAt,
            unreadCount: currentProviderCount, // Use provider count
            imageUrls: senderImageUrls,
            status: 'online',
            isVip: senderIsVip,
          );

          _chatPartners.insert(0, newPartner);

          // Don't update provider here - GlobalChatListener already handled it
        }
      });
    } catch (e, stackTrace) {}
  }

  void _handleMessageSent(dynamic data) {
    try {
      if (data == null) return;

      final messageData = data['message'] ?? data;

      final receiverId =
          messageData['receiver']?['_id']?.toString() ??
          messageData['receiver']?.toString();
      final receiverName =
          messageData['receiver']?['name']?.toString() ?? 'Unknown';
      final receiverUsername = messageData['receiver']?['username']?.toString();
      final receiverAvatar = messageData['receiver']?['image']?.toString();
      final receiverImageUrls =
          (messageData['receiver']?['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      // Extract VIP status
      final receiverIsVip =
          messageData['receiver']?['userMode'] == 'vip' ||
          messageData['receiver']?['vipSubscription']?['isActive'] == true;

      final rawMessageText = messageData['message']?.toString() ?? '';
      final createdAt = messageData['createdAt'] != null
          ? DateTime.parse(messageData['createdAt'].toString())
          : DateTime.now();

      // Check for story reference or GIF URLs
      final hasStoryRef = messageData['storyReference'] != null &&
          messageData['storyReference']['storyId'] != null;
      final isGifUrl = rawMessageText.startsWith('http') &&
          (rawMessageText.contains('giphy.com') || rawMessageText.contains('.gif') || rawMessageText.contains('tenor.com') || rawMessageText.contains('gph.is') || rawMessageText.contains('media.giphy'));
      final isUrlOnly = rawMessageText.startsWith('http') && !rawMessageText.contains(' ');

      // Get message preview based on type/media
      final messageType = messageData['type']?.toString() ?? '';
      String messageText;
      if (hasStoryRef) {
        messageText = '📖 Replied to story';
      } else if (messageType == 'gif' || isGifUrl) {
        messageText = '🎬 GIF';
      } else if (isUrlOnly) {
        messageText = '📎 Media';
      } else if (rawMessageText.isNotEmpty) {
        messageText = rawMessageText;
      } else {
        messageText = rawMessageText;
        final mediaType = messageData['media']?['type']?.toString() ?? '';

        if (messageType == 'sticker') {
          messageText = '😀 Sticker';
        } else if (messageType == 'poll') {
          messageText = '📊 Poll';
        } else if (mediaType == 'voice') {
          messageText = '🎤 Voice message';
        } else if (mediaType == 'audio') {
          messageText = '🎵 Audio';
        } else if (mediaType == 'image') {
          messageText = '📷 Photo';
        } else if (mediaType == 'video') {
          messageText = '🎬 Video';
        } else if (mediaType == 'document') {
          messageText = '📄 Document';
        } else if (mediaType == 'location') {
          messageText = '📍 Location';
        } else if (mediaType.isNotEmpty) {
          messageText = '📎 Attachment';
        }
      }

      if (receiverId == null || receiverId.isEmpty) {
        return;
      }

      if (!mounted) return;

      setState(() {
        int partnerIndex = _chatPartners.indexWhere((p) => p.id == receiverId);

        if (partnerIndex != -1) {
          final existingPartner = _chatPartners[partnerIndex];
          final updatedPartner = existingPartner.copyWith(
            lastMessage: messageText,
            lastMessageTime: createdAt,
          );

          _chatPartners.removeAt(partnerIndex);
          _chatPartners.insert(0, updatedPartner);
        } else {
          final newPartner = ChatPartner(
            id: receiverId,
            name: receiverName,
            username: receiverUsername,
            avatar: receiverAvatar,
            lastMessage: messageText,
            lastMessageTime: createdAt,
            unreadCount: 0,
            imageUrls: receiverImageUrls,
            status: 'online',
            isVip: receiverIsVip,
          );

          _chatPartners.insert(0, newPartner);
        }
      });

      _syncUnreadCounts(); // Sync after update
    } catch (e, stackTrace) {}
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
    } catch (e) {}
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
      // Ensure data is a Map
      if (data is! Map) {
        return;
      }

      final Map<String, dynamic> rawData = Map<String, dynamic>.from(data);

      // Handle different data formats from socket events
      // 1. onlineUsers event: {'type': 'onlineUsers', 'data': [...]}
      if (rawData.containsKey('type') && rawData['type'] == 'onlineUsers') {
        _handleOnlineUsersUpdate(rawData['data']);
        return;
      }

      // 2. Single user update: {'single': {...}}
      if (rawData.containsKey('single')) {
        _handleSingleUserStatusUpdate(rawData['single']);
        return;
      }

      // 3. Direct bulk status update: {userId: {status, lastSeen}, ...}
      if (!mounted) return;

      setState(() {
        rawData.forEach((userId, statusData) {
          // Ensure statusData is a Map before accessing its properties
          if (statusData is Map) {
            final statusMap = Map<String, dynamic>.from(statusData);
            _userStatuses[userId] = {
              'status': statusMap['status'],
              'lastSeen': statusMap['lastSeen'] != null
                  ? DateTime.parse(statusMap['lastSeen'].toString())
                  : null,
            };
          }
        });
      });

      _processChatPartnersWithStatus();
    } catch (e, stackTrace) {}
  }

  void _handleOnlineUsersUpdate(dynamic data) {
    if (!mounted) return;

    // Handle list of online user IDs
    if (data is List) {
      setState(() {
        for (final userId in data) {
          if (userId is String) {
            _userStatuses[userId] = {
              'status': 'online',
              'lastSeen': DateTime.now(),
            };
          }
        }
      });
      _processChatPartnersWithStatus();
    }
  }

  void _handleSingleUserStatusUpdate(dynamic data) {
    if (!mounted || data == null) return;

    try {
      final statusMap = data is Map ? Map<String, dynamic>.from(data) : null;
      if (statusMap == null) return;

      final userId = statusMap['userId']?.toString();
      if (userId == null) return;

      setState(() {
        _userStatuses[userId] = {
          'status': statusMap['status'],
          'lastSeen': statusMap['lastSeen'] != null
              ? DateTime.parse(statusMap['lastSeen'].toString())
              : null,
        };
      });

      _processChatPartnersWithStatus();
    } catch (e) {}
  }

  void _handleUserStoppedTyping(dynamic data) {}

  void _handleMessagesRead(dynamic data) {
    try {
      // NOTE: This event means someone ELSE read OUR messages (for read receipts/blue ticks)
      // We should NOT clear our unread count here - that only happens when WE open a chat
      // This is just for updating the UI to show that the other user has read our messages
      final readBy = data['readBy']?.toString();

      if (readBy != null && readBy.isNotEmpty) {
        // No need to update local state here - read receipts are handled in chat detail
      }
    } catch (e) {}
  }

  void _handleMessageRead(dynamic data) {
    try {
      // NOTE: This event is also for read receipts - someone read our messages
      // We should NOT clear our unread count here
      final senderId = data['senderId'];

      if (senderId == null) return;

      // No need to update unread count - read receipts don't affect our unread counts
    } catch (e) {}
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!mounted) return;

    _lastFetchTime = DateTime.now();

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final messageService = ref.read(messageServiceProvider);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
      });

      // Connect socket if not connected
      if (!_chatSocketService.isConnected) {
        await _chatSocketService.connect();
      }

      // Use efficient endpoint that returns unique chat partners directly
      // This is much faster than loading all messages and grouping client-side
      final chatPartners = await messageService.getChatPartners(
        id: userId,
        limit: 100,
      );
      _processChatPartnersFromServer(chatPartners);

      // Request status updates after chat partners are loaded
      if (_chatSocketService.isConnected && _chatPartners.isNotEmpty) {
        _chatSocketService.requestStatusUpdates(
          _chatPartners.map((p) => p.id).toList(),
        );
      }
    } catch (error) {
      // Fallback to old method if new endpoint fails
      await _fetchMessagesLegacy();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Legacy method - loads individual messages (less efficient)
  Future<void> _fetchMessagesLegacy() async {
    try {
      final messageService = ref.read(messageServiceProvider);
      final userId = _currentUserId;
      if (userId == null) return;

      final messages = await messageService.getUserMessages(
        id: userId,
        limit: 200,
      );
      _processChatPartners(messages);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages: $error';
        });
      }
    }
  }

  /// Process chat partners from efficient server endpoint (aggregated data)
  void _processChatPartnersFromServer(List<ChatPartnerData> serverPartners) {
    // Filter out locally deleted conversations
    final filteredPartners = serverPartners.where((data) {
      if (data.conversationId != null &&
          _deletedConversationIds.contains(data.conversationId)) {
        return false;
      }
      return true;
    }).toList();

    final partners = filteredPartners.map((data) {
      return ChatPartner(
        id: data.id,
        name: data.name,
        username: data.username,
        avatar: data.profileImageUrl,
        lastMessage: data.lastMessage?.displayText,
        lastMessageTime: data.lastMessage?.createdAt,
        unreadCount: data.unreadCount,
        imageUrls: data.images,
        status: 'offline', // Will be updated by socket
        isVip: data.isVip,
        isPinned: data.isPinned,
        isMuted: data.isMuted,
        conversationId: data.conversationId,
      );
    }).toList();

    // Sort: pinned first, then by last message time (newest first)
    partners.sort((a, b) {
      // Pinned conversations come first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Then sort by last message time
      final aTime = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    if (mounted) {
      // Get provider counts and update partners with correct unread counts
      final providerState = ref.read(chatPartnersProvider);
      final updatedPartners = partners.map((partner) {
        final providerCount = providerState.unreadCounts[partner.id];
        if (providerCount != null) {
          return partner.copyWith(unreadCount: providerCount);
        }
        return partner;
      }).toList();

      setState(() {
        _chatPartners = updatedPartners;
      });

      // Sync unread counts to provider
      final notifier = ref.read(chatPartnersProvider.notifier);
      for (final partner in updatedPartners) {
        final providerCount = providerState.unreadCounts[partner.id];
        if (partner.unreadCount > 0 && providerCount == null) {
          notifier.updateUnreadCount(partner.id, partner.unreadCount);
        }
      }
    }
  }

  /// Process chat partners from individual messages (legacy method)
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
            username: otherUser.username,
            avatar: otherUser.imageUrls.isNotEmpty
                ? otherUser.imageUrls[0]
                : null,
            lastMessage: getMessagePreview(message),
            unreadCount: isUnread ? 1 : 0,
            lastMessageTime: messageDate,
            imageUrls: otherUser.imageUrls,
            status: statusDisplay,
            lastSeen: lastSeen,
            isVip: otherUser.isVip,
          );
        } else {
          final shouldUpdateMessage =
              existingPartner.lastMessageTime == null ||
              messageDate.isAfter(existingPartner.lastMessageTime!);

          partnersMap[otherUser.id] = existingPartner.copyWith(
            lastMessage: shouldUpdateMessage
                ? getMessagePreview(message)
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
      } catch (e) {}
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
        // ALWAYS use provider count if available (even if 0)
        // This ensures read state is preserved from chat detail
        final providerCount = providerState.unreadCounts[partner.id];
        if (providerCount != null) {
          return partner.copyWith(unreadCount: providerCount);
        }
        return partner;
      }).toList();

      setState(() {
        _chatPartners = updatedPartners;
      });

      // Sync calculated counts to provider (only if provider doesn't have them)
      // Important: Only sync if provider has NO entry for this user
      // If provider has an entry (even 0), it means user already opened chat and read messages
      // We should NOT overwrite their read state with stale API data
      final notifier = ref.read(chatPartnersProvider.notifier);
      for (final partner in updatedPartners) {
        final providerCount = providerState.unreadCounts[partner.id];
        // Only sync from API if we have NEVER tracked this user (null = no entry)
        if (partner.unreadCount > 0 && providerCount == null) {
          notifier.updateUnreadCount(partner.id, partner.unreadCount);
        }
      }

      if (_chatSocketService.isConnected && _chatPartners.isNotEmpty) {
        try {
          _chatSocketService.requestStatusUpdates(
            _chatPartners.map((p) => p.id).toList(),
          );
        } catch (e) {}
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
    // Start with all partners
    List<ChatPartner> result = _chatPartners;

    // Apply chat filter (unread, online)
    if (_chatFilter == 'unread') {
      result = result.where((p) => p.unreadCount > 0).toList();
    } else if (_chatFilter == 'online') {
      result = result.where((p) => _isUserOnline(p)).toList();
    }

    // Apply search query
    if (_searchQuery.trim().isNotEmpty) {
      String normalizedQuery = _searchQuery.toLowerCase().trim();
      String usernameQuery = normalizedQuery.startsWith('@')
          ? normalizedQuery.substring(1)
          : normalizedQuery;

      result = result.where((partner) {
        if (partner.name.toLowerCase().contains(normalizedQuery)) return true;
        if (partner.username != null &&
            partner.username!.toLowerCase().contains(usernameQuery)) {
          return true;
        }
        if (partner.lastMessage?.toLowerCase().contains(normalizedQuery) ==
            true) {
          return true;
        }
        return false;
      }).toList();
    }

    return result;
  }

  Future<void> _forceRefresh() async {
    // Get fresh credentials
    final prefs = await SharedPreferences.getInstance();
    final newUserId = prefs.getString('userId');
    final newToken = prefs.getString('token');

    if (newUserId == null || newToken == null) {
      if (mounted) {
        setState(() {
          _error = 'Please login again';
        });
      }
      return;
    }

    if (!mounted) return;

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

    // Only reconnect socket if not already connected
    if (!_chatSocketService.isConnected) {
      await _chatSocketService.forceReconnect();
    } else {}
    _subscribeToSocketEvents();
  }

  Future<void> _refresh() async {
    await _forceRefresh();
  }

  /// Handle refresh button tap with loading state
  Future<void> _onRefreshButtonTap() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await _forceRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// Build floating refresh button
  Widget _buildRefreshButton(ColorScheme colors) {
    return Material(
      elevation: 6,
      shadowColor: const Color(0xFF00BFA5).withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _isRefreshing ? null : _onRefreshButtonTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
            ),
          ),
          child: _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 26,
                ),
        ),
      ),
    );
  }

  void _onSelectUser(String userId, String userName, String? profilePicture) {
    HapticUtils.onSelect();
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
          // Silently refresh conversations when returning from chat
          // This ensures we get the latest messages without showing loading state
          _silentRefresh();
          setState(() {
            _activeUserId = null;
          });
        });
  }

  /// Show dialog to start new chat by username
  void _showNewChatDialog() {
    final colors = Theme.of(context).colorScheme;
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person_search, color: colors.primary),
            const SizedBox(width: 12),
            const Text('New Chat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter username to start a chat',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '@username',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  final username = value.trim().startsWith('@')
                      ? value.trim().substring(1)
                      : value.trim();
                  _searchAndStartChat(username);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = usernameController.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop();
                final username = value.startsWith('@')
                    ? value.substring(1)
                    : value;
                _searchAndStartChat(username);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Find User'),
          ),
        ],
      ),
    );
  }

  /// Search for a user by username and start a chat
  Future<void> _searchAndStartChat(String username) async {
    final colors = Theme.of(context).colorScheme;
    bool dialogOpen = true;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'Searching for @$username...',
                style: TextStyle(color: colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final userService = UserService();
      final user = await userService.getUserByUsername(username);

      if (!mounted) return;
      // Close loading dialog using root navigator (showDialog uses root by default)
      Navigator.of(context, rootNavigator: true).pop();
      dialogOpen = false;

      if (user != null) {
        // Found user - navigate to chat via GoRouter
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });

        // Defer navigation to next frame so dialog dismiss completes first
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/chat/${user.id}').then((_) {
            _silentRefresh();
          });
        });
      } else {
        // User not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User @$username not found'),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Use post-frame callback to avoid popping while navigator is locked
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (dialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for user: $e'),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        // Bright KakaoTalk-style green
        return const Color(0xFF4ADE80); // Tailwind green-400
      case 'away':
        // Yellow/amber for away
        return const Color(0xFFFBBF24); // Tailwind amber-400
      case 'busy':
      case 'dnd':
        // Red for busy/do not disturb
        return const Color(0xFFF87171); // Tailwind red-400
      case 'recently online':
        // Light blue for recently online
        return const Color(0xFF60A5FA); // Tailwind blue-400
      case 'offline':
      default:
        // Very subtle gray for offline - almost invisible
        return const Color(0xFFD1D5DB); // Tailwind gray-300
    }
  }

  /// Get the real-time status for a user (from _userStatuses or fallback to partner.status)
  String _getRealtimeStatus(ChatPartner partner) {
    final realtimeStatus = _userStatuses[partner.id]?['status']?.toString();
    return realtimeStatus ?? partner.status;
  }

  /// Check if user is online
  bool _isUserOnline(ChatPartner partner) {
    final status = _getRealtimeStatus(partner);
    return status.toLowerCase() == 'online';
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
          hintText: 'Search or type @username',
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

  Widget _buildChatFilterChips() {
    final filters = [
      ('all', 'All', Icons.chat_bubble_outline_rounded),
      ('unread', 'Unread', Icons.mark_email_unread_outlined),
      ('online', 'Online', Icons.circle),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label, icon) = filters[index];
          final isSelected = _chatFilter == value;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: value == 'online' ? 10 : 16,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : context.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _chatFilter = value;
              });
            },
            selectedColor: context.primaryColor,
            backgroundColor: context.containerColor,
            labelStyle: TextStyle(
              color: isSelected ? colorScheme.onPrimary : context.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide.none,
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
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
      final isUsernameSearch = _searchQuery.trim().startsWith('@');
      final searchTerm = isUsernameSearch
          ? _searchQuery.trim().substring(1)
          : _searchQuery.trim();

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
                isUsernameSearch
                    ? 'User @$searchTerm not in your chats'
                    : 'Try adjusting your search',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.outlineVariant,
                ),
              ),
              if (isUsernameSearch && searchTerm.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _searchAndStartChat(searchTerm),
                  icon: const Icon(Icons.person_search, size: 20),
                  label: Text('Find @$searchTerm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
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
      // Auto-close other slidables when opening a new one
      child: SlidableAutoCloseBehavior(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 100),
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
            final delay = Duration(milliseconds: (index * 50).clamp(0, 500));

            final item = Slidable(
              key: ValueKey(partner.id),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.75, // Increased from 0.6 to show labels fully
                children: [
                  // Pin/Unpin action
                  SlidableAction(
                    onPressed: (_) => _handlePinConversation(partner),
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    icon: partner.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    label: partner.isPinned ? 'Unpin' : 'Pin',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  // Mute/Unmute action
                  SlidableAction(
                    onPressed: (_) => _handleMuteConversation(partner),
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    icon: partner.isMuted
                        ? Icons.notifications
                        : Icons.notifications_off,
                    label: partner.isMuted ? 'Unmute' : 'Mute',
                  ),
                  // Delete action
                  SlidableAction(
                    onPressed: (_) => _handleDeleteConversation(partner),
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () =>
                    _onSelectUser(partner.id, partner.name, partner.avatar),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // ================= AVATAR =================
                      Stack(
                        children: [
                          VipAvatarFrameCompact(
                            isVip: partner.isVip,
                            size: 56,
                            child: CachedCircleAvatar(
                              imageUrl:
                                  partner.avatar != null &&
                                      partner.avatar!.isNotEmpty
                                  ? partner.avatar
                                  : null,
                              radius: 28,
                              backgroundColor: colors.surfaceVariant,
                              errorWidget: Text(
                                partner.name.isNotEmpty
                                    ? partner.name[0].toUpperCase()
                                    : '?',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Online status indicator - KakaoTalk style
                          Positioned(
                            bottom: partner.isVip ? 4 : 2,
                            right: partner.isVip ? 4 : 2,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _isUserOnline(partner) ? 16 : 12,
                              height: _isUserOnline(partner) ? 16 : 12,
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  _getRealtimeStatus(partner),
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.surface,
                                  width: 2.5,
                                ),
                                // Glow effect for online status
                                boxShadow: _isUserOnline(partner)
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4ADE80,
                                          ).withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
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
                            // Name + VIP Badge + Time
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          partner.name,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (partner.isVip) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFFD700),
                                                Color(0xFFFFA500),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.workspace_premium,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                'VIP',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Pin indicator
                                if (partner.isPinned)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.push_pin,
                                      size: 14,
                                      color: colors.primary,
                                    ),
                                  ),
                                // Mute indicator
                                if (partner.isMuted)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.notifications_off,
                                      size: 14,
                                      color: colors.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                                if (partner.lastMessageTime != null)
                                  Text(
                                    _formatTime(partner.lastMessageTime!),
                                    style: TextStyle(
                                      color: partner.unreadCount > 0
                                          ? const Color(0xFFEF4444)
                                          : colors.onSurface.withOpacity(0.4),
                                      fontSize: 12,
                                      fontWeight: partner.unreadCount > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // Last message + unread badge
                            Row(
                              children: [
                                Expanded(
                                  child: _typingUsers[partner.id] == true
                                      ? _buildTypingIndicator()
                                      : Row(
                                          children: [
                                            // Online indicator text (if online)
                                            if (_isUserOnline(partner)) ...[
                                              Container(
                                                width: 6,
                                                height: 6,
                                                margin: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4ADE80),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                            Expanded(
                                              child: Text(
                                                partner.lastMessage ??
                                                    'No messages yet',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          partner.unreadCount >
                                                              0
                                                          ? colors.onSurface
                                                          : colors.onSurface
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                      fontWeight:
                                                          partner.unreadCount >
                                                              0
                                                          ? FontWeight.w500
                                                          : FontWeight.normal,
                                                      fontSize: 13,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                // Unread count badge
                                if (partner.unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      partner.unreadCount > 99
                                          ? '99+'
                                          : partner.unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
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
            );

            return item
                .animate()
                .fadeIn(duration: 300.ms, delay: delay)
                .slideX(
                  begin: 0.05,
                  end: 0,
                  duration: 300.ms,
                  delay: delay,
                  curve: Curves.easeOutCubic,
                );
          },
        ),
      ),
    );
  }

  // ================= SWIPE ACTION HANDLERS =================

  Future<void> _handlePinConversation(ChatPartner partner) async {
    final conversationService = ConversationService();

    try {
      final result = partner.isPinned
          ? await conversationService.unpinConversation(
              conversationId: partner.conversationId ?? partner.id,
            )
          : await conversationService.pinConversation(
              conversationId: partner.conversationId ?? partner.id,
            );

      if (result['success'] == true) {
        // Refresh conversations
        _silentRefresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                partner.isPinned
                    ? 'Conversation unpinned'
                    : 'Conversation pinned',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {}
    } catch (e) {}
  }

  Future<void> _handleMuteConversation(ChatPartner partner) async {
    final conversationService = ConversationService();

    try {
      final result = partner.isMuted
          ? await conversationService.unmuteConversation(
              conversationId: partner.conversationId ?? partner.id,
            )
          : await conversationService.muteConversation(
              conversationId: partner.conversationId ?? partner.id,
            );

      if (result['success'] == true) {
        // Refresh conversations
        _silentRefresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                partner.isMuted
                    ? 'Notifications enabled'
                    : 'Conversation muted',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {}
    } catch (e) {}
  }

  Future<void> _handleDeleteConversation(ChatPartner partner) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Delete your conversation with ${partner.name}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final conversationService = ConversationService();

    try {
      final result = await conversationService.deleteConversation(
        conversationId: partner.conversationId ?? partner.id,
      );

      if (result['success'] == true) {
        // Add to locally deleted set for client-side filtering
        if (partner.conversationId != null) {
          _deletedConversationIds.add(partner.conversationId!);
        }
        // Refresh conversations
        _silentRefresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {}
    } catch (e) {}
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated dots
        _buildTypingDots(),
        const SizedBox(width: 6),
        const Text(
          'typing...',
          style: TextStyle(
            color: Color(0xFF4ADE80),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 24,
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 150)),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(value),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
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
          AppLocalizations.of(context)!.chats,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        actions: [
          // New chat button
          IconButton(
            icon: Icon(
              Icons.person_add_alt_1_outlined,
              color: colors.onBackground,
              size: 26,
            ),
            tooltip: 'New chat by username',
            onPressed: () => _showNewChatDialog(),
          ),
          // Notification bell icon with badge
          Consumer(
            builder: (context, ref, child) {
              final badgeCount = ref.watch(badgeCountProvider);
              final notificationCount = badgeCount.notifications;

              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: colors.onBackground,
                      size: 26,
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.background,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            notificationCount > 99
                                ? '99+'
                                : notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (context) => const NotificationHistoryScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ConnectionStatusIndicator(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: SmallBannerAdWidget(),
          ),
          Expanded(
            child: _isLoading
                // ---------- Loading with Shimmer ----------
                ? ListView.builder(
                    itemCount: 8,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) =>
                        const ChatListItemSkeleton(),
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
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _refresh,
                        backgroundColor: colors.surface,
                        color: colors.primary,
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            _buildChatFilterChips(),
                            Expanded(child: _buildUsersList()),
                          ],
                        ),
                      ),
                      // Floating refresh button
                      Positioned(
                        right: 16,
                        bottom: 100,
                        child: _buildRefreshButton(colors),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
