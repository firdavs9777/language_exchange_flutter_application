import 'dart:async';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
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
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/pages/chat/models/chat_partner.dart';
import 'package:bananatalk_app/pages/chat/list/chat_list_tile.dart';
import 'package:bananatalk_app/pages/chat/list/chat_list_search_bar.dart';
import 'package:bananatalk_app/pages/chat/list/chat_list_filter_tabs.dart';
import 'package:bananatalk_app/pages/chat/list/chat_list_empty_state.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Derive a short human-readable preview string from a raw socket message map.
/// Used by both _handleNewMessage and _handleMessageSent.
String _extractMessagePreview(Map<dynamic, dynamic> messageData) {
  final rawText = messageData['message']?.toString() ?? '';
  final messageType = messageData['type']?.toString() ?? '';
  final mediaType = messageData['media']?['type']?.toString() ?? '';
  final hasStoryRef = messageData['storyReference'] != null &&
      messageData['storyReference']['storyId'] != null;
  final isGifUrl = rawText.startsWith('http') &&
      (rawText.contains('giphy.com') ||
          rawText.contains('.gif') ||
          rawText.contains('tenor.com') ||
          rawText.contains('gph.is') ||
          rawText.contains('media.giphy'));
  final isUrlOnly = rawText.startsWith('http') && !rawText.contains(' ');

  if (hasStoryRef) return '📖 Replied to story';
  if (messageType == 'gif' || isGifUrl) return '🎬 GIF';
  if (isUrlOnly) return '📎 Media';
  if (rawText.isNotEmpty) return rawText;

  if (messageType == 'sticker') return '😀 Sticker';
  if (messageType == 'poll') return '📊 Poll';
  if (mediaType == 'voice') return '🎤 Voice message';
  if (mediaType == 'audio') return '🎵 Audio';
  if (mediaType == 'image') return '📷 Photo';
  if (mediaType == 'video') return '🎬 Video';
  if (mediaType == 'document') return '📄 Document';
  if (mediaType == 'location') return '📍 Location';
  if (mediaType.isNotEmpty) return '📎 Attachment';
  return rawText;
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
  bool get wantKeepAlive => true;
  ColorScheme get colorScheme => Theme.of(context).colorScheme;

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
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;

        if (!_chatSocketService.isConnected) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            _chatSocketService.connect(forceReset: true);
          }
        }
      });
    }
  }

  Future<void> _checkUserChange() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');

    if (_currentUserId != null && _currentUserId != currentUserId) {
      if (!mounted) return;

      setState(() {
        _chatPartners = [];
        _userStatuses = {};
        _typingUsers = {};
        _currentUserId = currentUserId;
      });

      await _fetchMessages();
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
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _typingSub?.cancel();
    _statusSub?.cancel();
    _messageReadSub?.cancel();
    _connectionStateSub?.cancel();

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
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _typingSub?.cancel();
    _statusSub?.cancel();
    _messageReadSub?.cancel();
    _connectionStateSub?.cancel();

    void onStreamError(dynamic error, StackTrace stackTrace) {}

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
          _requestStatusUpdatesInBatches();
        }
      },
      onError: onStreamError,
      onDone: () => debugPrint('📭 Connection state stream closed'),
    );
  }

  void _requestStatusUpdatesInBatches() {
    const batchSize = 20;
    final partnerIds = _chatPartners.map((p) => p.id).toList();

    for (var i = 0; i < partnerIds.length; i += batchSize) {
      final end = (i + batchSize < partnerIds.length)
          ? i + batchSize
          : partnerIds.length;
      final batch = partnerIds.sublist(i, end);

      Future.delayed(Duration(milliseconds: i ~/ batchSize * 100), () {
        if (mounted && _chatSocketService.isConnected) {
          _chatSocketService.requestStatusUpdates(batch);
        }
      });
    }
  }

  void _syncUnreadCountsFromProvider(ChatPartnersState providerState) {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _chatPartners = List.from(updatedPartners);
          });
        }
      });
    }
  }

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

  Future<void> _silentRefresh() async {
    if (!mounted) return;

    try {
      final messageService = ref.read(messageServiceProvider);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) return;

      final chatPartners = await messageService.getChatPartners(
        id: userId,
        limit: 100,
      );
      if (mounted) {
        _processChatPartnersFromServer(chatPartners);
      }
    } catch (e) {}
  }

  void _syncUnreadCounts() {
    if (_chatPartners.isEmpty) return;

    final notifier = ref.read(chatPartnersProvider.notifier);
    final currentState = ref.read(chatPartnersProvider);

    bool localStateChanged = false;
    final updatedPartners = <ChatPartner>[];

    for (final partner in _chatPartners) {
      final providerCount = currentState.unreadCounts[partner.id] ?? 0;
      final localCount = partner.unreadCount;

      if (localCount > providerCount) {
        notifier.updateUnreadCount(partner.id, localCount);
        updatedPartners.add(partner);
      } else if (localCount != providerCount) {
        updatedPartners.add(partner.copyWith(unreadCount: providerCount));
        localStateChanged = true;
      } else {
        updatedPartners.add(partner);
      }
    }

    final partnerIds = _chatPartners.map((p) => p.id).toSet();
    for (final userId in currentState.unreadCounts.keys) {
      if (!partnerIds.contains(userId)) {
        notifier.clearUnread(userId);
      }
    }

    if (localStateChanged && mounted) {
      setState(() {
        _chatPartners = updatedPartners;
      });
    }
  }

  void _handleUserTyping(dynamic data) {
    try {
      final String userId = data['userId'].toString() ?? '';
      if (userId.isEmpty || userId == _currentUserId) return;

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

      final messageData = data['message'] ?? data;

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
      final senderIsVip =
          messageData['sender']?['userMode'] == 'vip' ||
          messageData['sender']?['vipSubscription']?['isActive'] == true;

      final createdAt = messageData['createdAt'] != null
          ? DateTime.parse(messageData['createdAt'].toString())
          : DateTime.now();
      final messageText = _extractMessagePreview(messageData);

      if (senderId == null || senderId.isEmpty) return;
      if (senderId == _currentUserId) return;
      if (!mounted) return;

      final providerState = ref.read(chatPartnersProvider);
      final currentProviderCount = providerState.unreadCounts[senderId] ?? 0;

      setState(() {
        int partnerIndex = _chatPartners.indexWhere((p) => p.id == senderId);

        if (partnerIndex != -1) {
          final existingPartner = _chatPartners[partnerIndex];
          final updatedPartner = existingPartner.copyWith(
            lastMessage: messageText,
            lastMessageTime: createdAt,
            unreadCount: currentProviderCount,
          );
          _chatPartners.removeAt(partnerIndex);
          _chatPartners.insert(0, updatedPartner);
        } else {
          final newPartner = ChatPartner(
            id: senderId,
            name: senderName,
            username: senderUsername,
            avatar: senderAvatar,
            lastMessage: messageText,
            lastMessageTime: createdAt,
            unreadCount: currentProviderCount,
            imageUrls: senderImageUrls,
            status: 'online',
            isVip: senderIsVip,
          );
          _chatPartners.insert(0, newPartner);
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
      final receiverIsVip =
          messageData['receiver']?['userMode'] == 'vip' ||
          messageData['receiver']?['vipSubscription']?['isActive'] == true;

      final createdAt = messageData['createdAt'] != null
          ? DateTime.parse(messageData['createdAt'].toString())
          : DateTime.now();
      final messageText = _extractMessagePreview(messageData);

      if (receiverId == null || receiverId.isEmpty) return;
      if (!mounted) return;

      setState(() {
        int partnerIndex =
            _chatPartners.indexWhere((p) => p.id == receiverId);

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

      _syncUnreadCounts();
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

  void _handleBulkStatusUpdate(dynamic data) {
    try {
      if (data is! Map) return;

      final Map<String, dynamic> rawData = Map<String, dynamic>.from(data);

      if (rawData.containsKey('type') && rawData['type'] == 'onlineUsers') {
        _handleOnlineUsersUpdate(rawData['data']);
        return;
      }

      if (rawData.containsKey('single')) {
        _handleSingleUserStatusUpdate(rawData['single']);
        return;
      }

      if (!mounted) return;

      setState(() {
        rawData.forEach((userId, statusData) {
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
      final readBy = data['readBy']?.toString();
      if (readBy != null && readBy.isNotEmpty) {}
    } catch (e) {}
  }

  void _handleMessageRead(dynamic data) {
    try {
      final senderId = data['senderId'];
      if (senderId == null) return;
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

      if (!_chatSocketService.isConnected) {
        await _chatSocketService.connect();
      }

      final chatPartners = await messageService.getChatPartners(
        id: userId,
        limit: 100,
      );
      _processChatPartnersFromServer(chatPartners);

      if (_chatSocketService.isConnected && _chatPartners.isNotEmpty) {
        _chatSocketService.requestStatusUpdates(
          _chatPartners.map((p) => p.id).toList(),
        );
      }
    } catch (error) {
      await _fetchMessagesLegacy();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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

  void _processChatPartnersFromServer(List<ChatPartnerData> serverPartners) {
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
        status: 'offline',
        isVip: data.isVip,
        isPinned: data.isPinned,
        isMuted: data.isMuted,
        conversationId: data.conversationId,
      );
    }).toList();

    partners.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      final aTime = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    if (mounted) {
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

      final notifier = ref.read(chatPartnersProvider.notifier);
      for (final partner in updatedPartners) {
        final providerCount = providerState.unreadCounts[partner.id];
        if (partner.unreadCount > 0 && providerCount == null) {
          notifier.updateUnreadCount(partner.id, partner.unreadCount);
        }
      }
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
      final providerState = ref.read(chatPartnersProvider);
      final updatedPartners = sortedPartners.map((partner) {
        final providerCount = providerState.unreadCounts[partner.id];
        if (providerCount != null) {
          return partner.copyWith(unreadCount: providerCount);
        }
        return partner;
      }).toList();

      setState(() {
        _chatPartners = updatedPartners;
      });

      final notifier = ref.read(chatPartnersProvider.notifier);
      for (final partner in updatedPartners) {
        final providerCount = providerState.unreadCounts[partner.id];
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
    List<ChatPartner> result = _chatPartners;

    if (_chatFilter == 'unread') {
      result = result.where((p) => p.unreadCount > 0).toList();
    } else if (_chatFilter == 'online') {
      result = result.where((p) => _isUserOnline(p)).toList();
    }

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

    setState(() {
      _chatPartners = [];
      _userStatuses = {};
      _typingUsers = {};
      _currentUserId = newUserId;
      _error = '';
    });

    await _fetchMessages();

    if (!_chatSocketService.isConnected) {
      await _chatSocketService.forceReconnect();
    }
    _subscribeToSocketEvents();
  }

  Future<void> _refresh() async {
    await _forceRefresh();
  }

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

  void _onSelectUser(String userId, String userName, String? profilePicture) {
    HapticUtils.onSelect();
    setState(() {
      _activeUserId = userId;
    });

    if (_chatSocketService.isConnected && _currentUserId != null) {
      _chatSocketService.markAsRead(userId, _currentUserId!);
    }

    setState(() {
      final partnerIndex = _chatPartners.indexWhere((p) => p.id == userId);
      if (partnerIndex != -1) {
        _chatPartners[partnerIndex] = _chatPartners[partnerIndex].copyWith(
          unreadCount: 0,
        );
        ref.read(chatPartnersProvider.notifier).clearUnread(userId);
      }
    });

    context
        .push(
          '/chat/$userId',
          extra: {'userName': userName, 'profilePicture': profilePicture},
        )
        .then((_) {
          _silentRefresh();
          setState(() {
            _activeUserId = null;
          });
        });
  }

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
                final username =
                    value.startsWith('@') ? value.substring(1) : value;
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

  Future<void> _searchAndStartChat(String username) async {
    final colors = Theme.of(context).colorScheme;
    bool dialogOpen = true;

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
      Navigator.of(context, rootNavigator: true).pop();
      dialogOpen = false;

      if (user != null) {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/chat/${user.id}').then((_) {
            _silentRefresh();
          });
        });
      } else {
        showChatSnackBar(
          context,
          message: 'User @$username not found',
          type: ChatSnackBarType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (dialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        showChatSnackBar(
          context,
          message: 'Error searching for user: $e',
          type: ChatSnackBarType.error,
        );
      });
    }
  }

  /// Get the real-time status for a user (from _userStatuses or partner.status)
  String _getRealtimeStatus(ChatPartner partner) {
    final realtimeStatus = _userStatuses[partner.id]?['status']?.toString();
    return realtimeStatus ?? partner.status;
  }

  bool _isUserOnline(ChatPartner partner) {
    return _getRealtimeStatus(partner).toLowerCase() == 'online';
  }

  // ─── Swipe action handlers ─────────────────────────────────────────────────

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
        _silentRefresh();
        if (mounted) {
          showChatSnackBar(
            context,
            message: partner.isPinned
                ? 'Conversation unpinned'
                : 'Conversation pinned',
            type: ChatSnackBarType.success,
          );
        }
      }
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
        _silentRefresh();
        if (mounted) {
          showChatSnackBar(
            context,
            message: partner.isMuted
                ? 'Notifications enabled'
                : 'Conversation muted',
            type: ChatSnackBarType.success,
          );
        }
      }
    } catch (e) {}
  }

  Future<void> _handleDeleteConversation(ChatPartner partner) async {
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

    if (confirmed != true) return;

    final conversationService = ConversationService();

    try {
      final result = await conversationService.deleteConversation(
        conversationId: partner.conversationId ?? partner.id,
      );

      if (result['success'] == true) {
        if (partner.conversationId != null) {
          _deletedConversationIds.add(partner.conversationId!);
        }
        _silentRefresh();
        if (mounted) {
          showChatSnackBar(
            context,
            message: 'Conversation deleted',
            type: ChatSnackBarType.success,
          );
        }
      }
    } catch (e) {}
  }

  // ─── Build helpers ─────────────────────────────────────────────────────────

  Widget _buildRefreshButton(ColorScheme colors) {
    return Material(
      elevation: 6,
      shadowColor: const Color(0xFF00BFA5).withValues(alpha: 0.4),
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

  Widget _buildUsersList() {
    final List<ChatPartner> displayPartners = _filteredChatPartners;

    // No search results
    if (_searchQuery.isNotEmpty && displayPartners.isEmpty) {
      final isUsernameSearch = _searchQuery.trim().startsWith('@');
      final searchTerm = isUsernameSearch
          ? _searchQuery.trim().substring(1)
          : _searchQuery.trim();

      return FadeTransition(
        opacity: _fadeAnimation,
        child: ChatListEmptyState.noResults(
          searchQuery: _searchQuery,
          onFindUser: isUsernameSearch && searchTerm.isNotEmpty
              ? () => _searchAndStartChat(searchTerm)
              : null,
        ),
      );
    }

    // Truly empty list
    if (displayPartners.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: const ChatListEmptyState.noChats(),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlidableAutoCloseBehavior(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 100),
          itemCount: displayPartners.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 0.3,
            indent: 88,
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
          itemBuilder: (context, index) {
            final partner = displayPartners[index];
            final delay =
                Duration(milliseconds: (index * 50).clamp(0, 500));

            return ChatListTile(
              partner: partner,
              isActive: _activeUserId == partner.id,
              isTyping: _typingUsers[partner.id] == true,
              realtimeStatus: _getRealtimeStatus(partner),
              onTap: () =>
                  _onSelectUser(partner.id, partner.name, partner.avatar),
              onPin: _handlePinConversation,
              onMute: _handleMuteConversation,
              onDelete: _handleDeleteConversation,
            )
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final chatPartnersState = ref.watch(chatPartnersProvider);
    _syncUnreadCountsFromProvider(chatPartnersState);

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,

      // ─── App Bar ──────────────────────────────────────────────────────────
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
          IconButton(
            icon: Icon(
              Icons.person_add_alt_1_outlined,
              color: colors.onBackground,
              size: 26,
            ),
            tooltip: 'New chat by username',
            onPressed: _showNewChatDialog,
          ),
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

      // ─── Body ─────────────────────────────────────────────────────────────
      body: Column(
        children: [
          ConnectionStatusIndicator(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: SmallBannerAdWidget(),
          ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 8,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) =>
                        const ChatListItemSkeleton(),
                  )
                : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 40,
                            color: colors.outline,
                          ),
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
                            child: Text(
                              AppLocalizations.of(context)!.retry,
                            ),
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
                            ChatListSearchBar(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              searchQuery: _searchQuery,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              onClear: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            ),
                            ChatListFilterTabs(
                              selectedFilter: _chatFilter,
                              onFilterChanged: (value) {
                                setState(() {
                                  _chatFilter = value;
                                });
                              },
                            ),
                            Expanded(child: _buildUsersList()),
                          ],
                        ),
                      ),
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
