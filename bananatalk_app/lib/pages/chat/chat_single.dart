// lib/pages/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/chat_state_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/pages/chat/chat_app_bar.dart';
import 'package:bananatalk_app/pages/chat/chat_input_section.dart';
import 'package:bananatalk_app/pages/chat/chat_messages_list.dart';
import 'package:bananatalk_app/widgets/connection_status_indicator.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/message_count_provider.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/widgets/image_preview_dialog.dart';
import 'package:bananatalk_app/utils/api_error_handler.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/media_service.dart';
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:bananatalk_app/widgets/voice_recorder_widget.dart';
import 'package:bananatalk_app/services/voice_message_service.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/pages/video_editor/video_editor_screen.dart';
import 'package:bananatalk_app/pages/chat/delete_message_dialog.dart';
import 'package:bananatalk_app/pages/chat/pinned_messages_bar.dart';
import 'package:bananatalk_app/pages/chat/forward_message_dialog.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/pages/chat/gif_picker_panel.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? profilePicture;
  final bool isVip;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.profilePicture,
    this.isVip = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  String? _currentUserId;
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _showMediaPanel = false;
  bool _showStickerPanel = false;
  String? _chatWallpaper;
  bool _isSelectionMode = false;
  Set<String> _selectedMessageIds = {};
  Message? _replyingToMessage;
  bool _showPinnedBar = true; // Show pinned messages bar by default
  bool _showScrollButton = false; // Show scroll to bottom button
  String? _highlightedMessageId; // For highlighting scrolled-to message
  bool _isBlockedChat = false; // True if either user has blocked the other
  bool _isSharingLocation = false;

  // Upload progress tracking
  int _uploadBytesSent = 0;
  int _uploadTotalBytes = 0;
  String? _uploadFileName;

  // Pagination state
  int _currentPage = 1;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  late AnimationController _mediaPanelController;
  late AnimationController _stickerPanelController;

  // Store notifier references for safe access in dispose
  ChatPartnersNotifier? _chatPartnersNotifier;
  ChatStateNotifier? _chatStateNotifier;

  // Theme change listener for wallpaper sync
  StreamSubscription? _themeChangeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadCurrentUser();
    _loadChatWallpaper();
    _setupCallListeners();
    _setupScrollListener();
    _setupThemeChangeListener();
    // Set this as the active chat so global listener doesn't increment unread
    // Use post-frame callback to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chatPartnersNotifier = ref.read(chatPartnersProvider.notifier);
        _chatPartnersNotifier?.setActiveChat(widget.userId);
      }
    });
  }

  // Track keyboard height to detect open/close
  double _previousBottomInset = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ensure socket is connected when returning to chat
      final socketService = ChatSocketService();
      socketService.forceReconnect();
      if (!socketService.isConnected) {
        socketService.connect(forceReset: true);
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // When keyboard opens/closes, the body resizes and scroll position
    // needs to stay anchored to the bottom to prevent content jumping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset != _previousBottomInset) {
        _previousBottomInset = bottomInset;
        // Keyboard opened — scroll to bottom instantly to prevent jump
        if (bottomInset > 0 && _scrollController.hasClients) {
          _scrollToBottom(animated: false);
        }
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more when scrolled near top (older messages)
      if (_scrollController.position.pixels <= 100 &&
          !_isLoadingMore &&
          _hasMoreMessages) {
        _loadMoreMessages();
      }

      // Show scroll to bottom button when not at bottom
      // In non-reversed list, check if we're far from maxScrollExtent
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final showButton = (maxScroll - currentScroll) > 200;
      if (showButton != _showScrollButton) {
        setState(() {
          _showScrollButton = showButton;
        });
      }
    });
  }

  /// Scroll to bottom (newest messages)
  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    // For non-reversed list, scroll to maxScrollExtent (bottom)
    final targetPosition = _scrollController.position.maxScrollExtent;

    if (animated && targetPosition > 0) {
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetPosition);
    }
  }

  /// Scroll to a specific message by ID
  void _scrollToMessage(String messageId) {
    final params = ChatProviderParams(
      chatPartnerId: widget.userId,
      currentUserId: _currentUserId ?? '',
    );
    final messages = ref.read(chatStateProvider(params)).messages;

    // Find the message index
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      return;
    }

    // Calculate position - in reversed list, we need to account for that
    // The list is reversed, so index 0 is at the bottom
    final reversedIndex = messages.length - 1 - index;

    // Estimate position (assuming average message height of ~80)
    final estimatedPosition = reversedIndex * 80.0;

    _scrollController.animateTo(
      estimatedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Highlight the message briefly
    setState(() {
      _highlightedMessageId = messageId;
    });

    // Remove highlight after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
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

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    // Check mounted after async operation
    if (!mounted) return;

    if (userId != null) {
      setState(() => _currentUserId = userId);

      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: userId,
          ),
        ).notifier,
      );
      // Cache for safe access in dispose (ref is not usable after dispose)
      _chatStateNotifier = chatNotifier;

      await chatNotifier.initialize();
      if (!mounted) return;

      // Mark chat as visible so auto-read only happens when screen is shown
      chatNotifier.setChatVisible(true);

      // Check if either user has blocked the other
      _checkBlockStatus(userId);

      await _loadMessages();
    }
  }

  Future<void> _checkBlockStatus(String currentUserId) async {
    try {
      final result = await BlockService.checkBlockStatus(
        userId: currentUserId,
        targetUserId: widget.userId,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final blocked =
            result['isBlocked'] == true || result['isBlockedBy'] == true;
        if (blocked != _isBlockedChat) {
          setState(() => _isBlockedChat = blocked);
        }
      }
    } catch (e) {
      debugPrint('Block status check failed: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null || !mounted) return;

    final chatNotifier = ref.read(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: widget.userId,
          currentUserId: _currentUserId!,
        ),
      ).notifier,
    );

    chatNotifier.setLoading(true);

    try {
      final messageService = ref.read(messageServiceProvider);
      // Use getConversation instead of filtering all messages
      final result = await messageService.getConversation(
        senderId: _currentUserId!,
        receiverId: widget.userId,
        page: 1,
        limit: 100,
      );

      // Check mounted after async operation
      if (!mounted) return;

      final conversationMessages = result['messages'] as List<Message>;
      final pagination = result['pagination'];

      // Update pagination state
      _currentPage = 1;
      _hasMoreMessages = pagination?['hasNextPage'] ?? false;

      chatNotifier.setMessages(conversationMessages);

      ref
          .read(messageCountProvider.notifier)
          .setMessageCount(
            widget.userId,
            result['total'] ?? conversationMessages.length,
          );

      // Mark messages as read via socket (notifies backend)
      chatNotifier.markAsRead();

      // Clear unread count locally for this chat partner (updates badge)
      ref.read(chatPartnersProvider.notifier).clearUnread(widget.userId);

      // Jump to bottom instantly after list is built — no visible scroll animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom(animated: false);
        });
      });
    } catch (error) {
      if (mounted) {
        chatNotifier.setError('Failed to load messages: $error');
      }
    } finally {
      if (mounted) {
        chatNotifier.setLoading(false);
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_currentUserId == null ||
        _isLoadingMore ||
        !_hasMoreMessages ||
        !mounted)
      return;

    setState(() => _isLoadingMore = true);

    try {
      final messageService = ref.read(messageServiceProvider);
      final nextPage = _currentPage + 1;

      final result = await messageService.getConversation(
        senderId: _currentUserId!,
        receiverId: widget.userId,
        page: nextPage,
        limit: 100,
      );

      // Check mounted after async operation
      if (!mounted) return;

      final olderMessages = result['messages'] as List<Message>;
      final pagination = result['pagination'];

      if (olderMessages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }

      // Update pagination state
      _currentPage = nextPage;
      _hasMoreMessages = pagination?['hasNextPage'] ?? false;

      // Prepend older messages to existing messages
      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ).notifier,
      );

      final chatState = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ),
      );

      // Combine: older messages + existing messages
      final allMessages = [...olderMessages, ...chatState.messages];

      // Remove duplicates by id
      final seen = <String>{};
      final uniqueMessages = allMessages.where((m) => seen.add(m.id)).toList();

      chatNotifier.setMessages(uniqueMessages);
    } catch (error) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _loadChatWallpaper() async {
    try {
      // First try to load from backend
      final conversationService = ConversationService();
      final result = await conversationService.getConversationTheme(
        conversationId: widget.userId, // Using partner ID as conversation ID
      );

      if (result['success'] == true && result['data'] != null) {
        final themeData = result['data'];
        final preset = themeData['preset'] as String?;
        if (preset != null && mounted) {
          setState(() => _chatWallpaper = preset);
          // Also save to local for offline access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('chat_theme_${widget.userId}', preset);
          return;
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('chat_theme_${widget.userId}');
      if (theme != null && mounted) {
        setState(() => _chatWallpaper = theme);
      }
    } catch (e) {
      // Fallback to local storage on error
      try {
        final prefs = await SharedPreferences.getInstance();
        final theme = prefs.getString('chat_theme_${widget.userId}');
        if (theme != null && mounted) {
          setState(() => _chatWallpaper = theme);
        }
      } catch (_) {}
    }
  }

  /// Listen for theme changes from the other user
  void _setupThemeChangeListener() {
    final socketService = ChatSocketService();
    _themeChangeSubscription = socketService.onThemeChanged.listen((data) {
      if (data is Map) {
        final changedBy = data['changedBy']?.toString();
        final theme = data['theme'];

        // Check if this theme change was made by our chat partner
        if (changedBy == widget.userId && theme != null && mounted) {
          final preset = theme['preset']?.toString();
          if (preset != null) {
            setState(() => _chatWallpaper = preset);
            // Also save locally for offline access
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('chat_theme_${widget.userId}', preset);
            });
          }
        }
      }
    });
  }

  void _setupCallListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if still mounted before accessing providers
      if (!mounted) return;

      final callNotifier = ref.read(callProvider.notifier);
      // Incoming call callback is set globally in main.dart
      callNotifier.setCallErrorCallback((error) {
        if (mounted) _handleCallError(context, error);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = ref.watch(authServiceProvider);
    if (!authService.isLoggedIn && _currentUserId != null) {}
  }

  void _toggleMediaPanel() {
    setState(() {
      if (_showStickerPanel) {
        _showStickerPanel = false;
        _stickerPanelController.reverse();
      }
      _showMediaPanel = !_showMediaPanel;
      if (_showMediaPanel) {
        FocusScope.of(context).unfocus();
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
        FocusScope.of(context).unfocus();
        _stickerPanelController.forward();
      } else {
        _stickerPanelController.reverse();
      }
    });
  }

  void _hidePanels() {
    FocusScope.of(context).unfocus();
    if (_showMediaPanel) {
      setState(() => _showMediaPanel = false);
      _mediaPanelController.reverse();
    }
    if (_showStickerPanel) {
      setState(() => _showStickerPanel = false);
      _stickerPanelController.reverse();
    }
  }

  Future<void> _sendMessage({String? messageText, String? messageType}) async {
    if (_currentUserId == null || !mounted) return;

    final text = messageText ?? _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    // Clear input and hide panels IMMEDIATELY for responsive feel
    if (messageText == null) _messageController.clear();
    _stopTyping();
    _hidePanels();

    if (!mounted) return;

    final chatNotifier = ref.read(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: widget.userId,
          currentUserId: _currentUserId!,
        ),
      ).notifier,
    );

    // Handle replies via API (can't use optimistic for replies yet)
    if (_replyingToMessage != null) {
      setState(() => _isSending = true);
      try {
        final messageService = ref.read(messageServiceProvider);
        final result = await messageService.replyToMessage(
          messageId: _replyingToMessage!.id,
          message: text,
          receiver: widget.userId,
        );

        if (mounted) setState(() => _isSending = false);

        if (result['success'] == true && mounted) {
          final replyMessage = result['data'] as Message;
          final state = ref.read(
            chatStateProvider(
              ChatProviderParams(
                chatPartnerId: widget.userId,
                currentUserId: _currentUserId!,
              ),
            ),
          );

          // Dedup: socket may have already added this message before API returned
          final alreadyExists = state.messages.any(
            (m) => m.id == replyMessage.id,
          );
          if (!alreadyExists) {
            final messages = List<Message>.from(state.messages)
              ..add(replyMessage);
            messages.sort(
              (a, b) => DateTime.parse(
                a.createdAt,
              ).compareTo(DateTime.parse(b.createdAt)),
            );
            chatNotifier.setMessages(messages);
          } else {}

          if (mounted) {
            setState(() => _replyingToMessage = null);
            _messageController.clear();
            ref.refresh(userLimitsProvider(_currentUserId!));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSending = false);
          _showSendError(e.toString(), text, messageType);
        }
      }
      return;
    }

    // ⚡ INSTANT: Add message to UI immediately (no await before this!)
    final localId = chatNotifier.addOptimisticMessage(
      message: text,
      currentUserId: _currentUserId!,
      receiverId: widget.userId,
      type: messageType ?? 'text',
    );

    // Scroll to bottom after the optimistic message is rendered
    // Use double callback to ensure ListView has calculated new extent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom(animated: false);
        });
      }
    });

    // Clear reply state
    setState(() => _replyingToMessage = null);

    // Send message in background (don't await) and check limits there
    _sendMessageInBackground(text, localId, messageType);
  }

  /// Send message in background and handle result
  /// Checks limits and sends via socket - runs after optimistic UI update
  Future<void> _sendMessageInBackground(
    String text,
    String localId,
    String? messageType,
  ) async {
    if (!mounted) return;

    try {
      // Check limits in background (after UI already updated)
      final userAsync = ref.read(userProvider);
      final user = userAsync.valueOrNull;
      if (user != null && _currentUserId != null) {
        final limits = ref.read(currentUserLimitsProvider(_currentUserId!));
        if (!FeatureGate.canSendMessage(user, limits)) {
          // Remove optimistic message and show limit dialog
          final chatNotifier = ref.read(
            chatStateProvider(
              ChatProviderParams(
                chatPartnerId: widget.userId,
                currentUserId: _currentUserId!,
              ),
            ).notifier,
          );
          chatNotifier.updateOptimisticMessage(localId, failed: true);

          if (mounted) {
            await LimitExceededDialog.show(
              context: context,
              limitType: 'messages',
              limitInfo: limits?.messages,
              resetTime: limits?.resetTime,
              userId: _currentUserId!,
            );
          }
          return;
        }
      }

      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ).notifier,
      );

      final result = await chatNotifier.sendMessage(
        text,
        localId: localId,
        messageType: messageType,
      );

      // Check mounted after async operation
      if (!mounted) return;

      if (result['status'] == 'success') {
        ref
            .read(messageCountProvider.notifier)
            .refreshMessageCount(widget.userId);
        ref.refresh(userLimitsProvider(_currentUserId!));
      } else {
        // Show error to user
        _showSendError(result['error'] ?? 'Failed to send', text, messageType);
      }
    } catch (error) {
      if (ApiErrorHandler.isLimitExceededError(error) && mounted) {
        await ApiErrorHandler.handleLimitExceededError(
          context: context,
          error: error,
          userId: _currentUserId,
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

    if (errorMessage.toLowerCase().contains('until') &&
        errorMessage.toLowerCase().contains('reply')) {
      // First-chat limit - show the exact message
      displayMessage = errorMessage;
    } else if (errorMessage.toLowerCase().contains('limit')) {
      displayMessage = l10n.dailyMessageLimitExceeded;
    } else if (errorMessage.toLowerCase().contains('blocked')) {
      displayMessage = l10n.cannotSendMessageUserMayBeBlocked;
      // Disable input so user can't keep trying
      setState(() => _isBlockedChat = true);
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
          label: l10n.retry,
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              _sendMessage(messageText: originalText, messageType: messageType);
            }
          },
        ),
      ),
    );
  }

  /// Send sticker immediately on tap (Telegram-style)
  void _selectSticker(String sticker) {
    // Close panel first for smooth UX
    setState(() {
      _showStickerPanel = false;
    });
    _stickerPanelController.reverse();

    // Send immediately
    _sendMessage(messageText: sticker, messageType: 'sticker');
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
        case 'video':
          await _pickVideoFromGallery();
          break;
        case 'record_video':
          await _recordVideo();
          break;
        case 'document':
          await _pickDocument();
          break;
        case 'audio':
          await _showVoiceRecorder();
          break;
        case 'gif':
          await _pickGif();
          break;
        case 'location':
          await _shareLocation();
          break;
        case 'contact':
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            showChatSnackBar(context, message: l10n.contactSharingComingSoon, type: ChatSnackBarType.info);
          }
          break;
        default:
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            showChatSnackBar(context, message: l10n.featureComingSoon, type: ChatSnackBarType.info);
          }
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Error: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _pickGif() async {
    if (!mounted) return;
    final gif = await GifPickerPanel.show(context);
    if (gif != null && mounted) {
      // Send GIF URL as a text message with 'gif' type
      // The originalUrl is the full-size GIF
      _sendMessage(messageText: gif.originalUrl, messageType: 'gif');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        await ImagePreviewDialog.show(
          context: context,
          imageFile: file,
          onSend: (caption) async {
            await _sendMediaFile(file, 'image', caption: caption);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Failed to take photo: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        await ImagePreviewDialog.show(
          context: context,
          imageFile: file,
          onSend: (caption) async {
            await _sendMediaFile(file, 'image', caption: caption);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Failed to pick image: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // 10 minutes max per API
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);

        // Validate file size (max 1GB)
        final fileSize = await file.length();
        if (fileSize > 1024 * 1024 * 1024) {
          if (mounted) {
            showChatSnackBar(context, message: AppLocalizations.of(context)!.videoMustBeUnder1GB, type: ChatSnackBarType.error);
          }
          return;
        }

        // Open video editor for trimming and filters before sending
        await _processAndSendVideo(file);
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Failed to pick video: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10), // 10 minutes max per API
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);

        // Validate file size (max 1GB)
        final fileSize = await file.length();
        if (fileSize > 1024 * 1024 * 1024) {
          if (mounted) {
            showChatSnackBar(context, message: AppLocalizations.of(context)!.videoMustBeUnder1GB, type: ChatSnackBarType.error);
          }
          return;
        }

        // Open video editor for trimming and filters
        await _processAndSendVideo(file);
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Failed to record video: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  /// Process video through editor before sending
  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null &&
          mounted) {
        final pickedFile = result.files.single;
        final file = File(pickedFile.path!);

        // Validate file size (max 50MB)
        final fileSize = pickedFile.size;
        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            showChatSnackBar(context, message: AppLocalizations.of(context)!.documentMustBeUnder50MB, type: ChatSnackBarType.error);
          }
          return;
        }

        // Determine media type from extension
        final ext = pickedFile.extension?.toLowerCase() ?? '';
        final imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
        final videoExts = ['mp4', 'mov', 'avi', 'mkv', 'webm'];

        String mediaType = 'document';
        if (imageExts.contains(ext)) {
          mediaType = 'image';
        } else if (videoExts.contains(ext)) {
          mediaType = 'video';
        }

        await _sendMediaFile(file, mediaType);
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Failed to pick file: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _processAndSendVideo(File videoFile) async {
    // Open video editor for trimming and filters
    final editorResult = await Navigator.push<VideoEditorResult>(
      context,
      AppPageRoute(
        builder: (context) => VideoEditorScreen(
          videoFile: videoFile,
          maxDurationSeconds: 600, // 10 minutes max for chat videos
        ),
      ),
    );

    // User cancelled editing
    if (editorResult == null || !mounted) {
      return;
    }

    // Use the edited video file
    final editedVideoFile = editorResult.videoFile;

    // Compress if needed
    final compressionService = VideoCompressionService();
    final needsCompression = await compressionService.needsCompression(
      editedVideoFile,
    );

    File finalVideoFile = editedVideoFile;
    if (needsCompression) {
      // Show compression dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          final dialogDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: dialogDark ? AppColors.gray900 : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Compressing video...',
                  style: TextStyle(
                    color: dialogDark ? AppColors.white : AppColors.gray900,
                  ),
                ),
              ],
            ),
          );
        },
      );

      finalVideoFile = await compressionService.compressVideo(editedVideoFile);

      // Close compression dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    // Send the video
    await _sendVideoMessage(finalVideoFile);
  }

  Future<void> _sendVideoMessage(File videoFile) async {
    if (!mounted) return;
    setState(() => _isSending = true);

    try {
      final messageService = ref.read(messageServiceProvider);
      final result = await messageService.sendVideoMessage(
        receiver: widget.userId,
        videoFile: videoFile,
      );

      // Check mounted after async operation
      if (!mounted) return;

      setState(() => _isSending = false);

      if (result['success'] == true) {
        // Don't reload - socket already adds the sent message
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
      } else {
        if (mounted) {
          String errorMsg = result['error'] ?? 'Failed to send video';
          if (errorMsg.contains('duration') ||
              errorMsg.contains('600 seconds') ||
              errorMsg.contains('10 minutes')) {
            errorMsg = 'Video must be under 10 minutes';
          } else if (errorMsg.contains('size') ||
              errorMsg.contains('1024MB') ||
              errorMsg.contains('1GB')) {
            errorMsg = 'Video must be under 1GB. Please compress the video.';
          } else if (errorMsg.contains('format')) {
            errorMsg = 'Unsupported video format. Use MP4, MOV, or WebM.';
          }
          showChatSnackBar(context, message: errorMsg, type: ChatSnackBarType.error);
        }
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        showChatSnackBar(context, message: 'Error sending video: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _showVoiceRecorder() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecorderWidget(
        onRecordingComplete: (file, duration, waveform) async {
          Navigator.pop(context);
          await _sendVoiceMessage(file, duration, waveform);
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _sendVoiceMessage(
    File voiceFile,
    int durationSeconds,
    List<double> waveform,
  ) async {
    setState(() => _isSending = true);

    try {
      // Use VoiceMessageService to send to /messages/voice endpoint
      final result = await VoiceMessageService.sendVoiceMessage(
        receiverId: widget.userId,
        voiceFile: voiceFile,
        durationSeconds: durationSeconds,
        waveform: waveform,
      );

      setState(() => _isSending = false);

      if (result['success'] == true) {
        // Don't reload - socket already adds the sent message
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }

        // Clean up the temp file
        try {
          await voiceFile.delete();
        } catch (_) {}
      } else {
        if (mounted) {
          String errorMsg = result['error'] ?? 'Failed to send voice message';
          if (errorMsg.contains('duration')) {
            errorMsg = 'Voice message must be under 5 minutes';
          } else if (errorMsg.contains('size')) {
            errorMsg = 'Voice message file too large';
          }
          showChatSnackBar(context, message: errorMsg, type: ChatSnackBarType.error);
        }
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        showChatSnackBar(context, message: 'Error sending voice message: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _shareLocation() async {
    if (_isSharingLocation) return;
    _isSharingLocation = true;

    BuildContext? dialogContext;
    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        _isSharingLocation = false;
        if (mounted) {
          showChatSnackBar(context, message: 'Location permission is required to share location', type: ChatSnackBarType.info);
        }
        return;
      }

      if (mounted) {
        // Don't await — we dismiss it ourselves after getting the position
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (ctx) {
            dialogContext = ctx;
            return const Center(child: CircularProgressIndicator());
          },
        );
        // Let the dialog route push before continuing
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      String? address;
      String? placeName;
      try {
        await setLocaleIdentifier('en_US');
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
        // Geocoding failure is non-fatal
      }

      // Dismiss loading dialog safely using its own context
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop();
      }
      dialogContext = null;

      if (!mounted) return;

      final result = await MediaService.sendMessageWithLocation(
        receiverId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        placeName: placeName,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
      } else {
        showChatSnackBar(context, message: result['error'] ?? 'Failed to share location', type: ChatSnackBarType.error);
      }
    } catch (e) {
      // Dismiss loading dialog if still open
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop();
      }
      if (mounted) {
        showChatSnackBar(context, message: 'Failed to get location: ${e.toString()}', type: ChatSnackBarType.error);
      }
    } finally {
      _isSharingLocation = false;
    }
  }

  Future<void> _sendMediaFile(
    File file,
    String? mediaType, {
    String? caption,
  }) async {
    try {
      String? detectedType = mediaType;
      final path = file.path.toLowerCase();
      if (path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.mkv') ||
          path.contains('video')) {
        detectedType = 'video';
      } else if (detectedType == null) {
        detectedType = 'image';
      }

      final validation = MediaService.validateMediaFile(file, detectedType);
      if (!validation['valid']) {
        if (mounted) {
          showChatSnackBar(context, message: validation['error'] ?? 'Invalid file', type: ChatSnackBarType.error);
        }
        return;
      }

      // Get file info for progress display
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      setState(() {
        _isSending = true;
        _uploadFileName = fileName;
        _uploadTotalBytes = fileSize;
        _uploadBytesSent = 0;
      });

      final result = await MediaService.sendMessageWithMedia(
        receiverId: widget.userId,
        messageText: caption,
        mediaFile: file,
        mediaType: detectedType ?? 'image',
        onProgress: (bytesSent, totalBytes) {
          if (mounted) {
            setState(() {
              _uploadBytesSent = bytesSent;
              _uploadTotalBytes = totalBytes;
            });
          }
        },
      );

      setState(() {
        _isSending = false;
        _uploadFileName = null;
        _uploadBytesSent = 0;
        _uploadTotalBytes = 0;
      });

      if (result['success'] == true) {
        // Don't reload - socket already adds the sent message
        // Just scroll to bottom to show the new message
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
      } else {
        if (mounted) {
          showChatSnackBar(context, message: result['error'] ?? 'Failed to send media', type: ChatSnackBarType.error);
        }
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        showChatSnackBar(context, message: 'Error sending media: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _onTyping() async {
    if (!_isTyping && _currentUserId != null) {
      _isTyping = true;
      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ).notifier,
      );
      chatNotifier.sendTyping(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 3), () {
      if (_isTyping) _stopTyping();
    });
  }

  Future<void> _stopTyping() async {
    if (_isTyping && _currentUserId != null) {
      _isTyping = false;
      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ).notifier,
      );
      chatNotifier.sendTyping(false);
    }
    _typingTimer?.cancel();
  }

  // ==================== MESSAGE ACTIONS ====================

  /// Handle edit message action
  void _handleEditMessage(Message message) async {
    if (_currentUserId == null) return;

    // Check if message can be edited (within 15 minutes)
    try {
      final createdAt = DateTime.parse(message.createdAt);
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes >= 15) {
        showChatSnackBar(context, message: AppLocalizations.of(context)!.editWithin15Minutes, type: ChatSnackBarType.info);
        return;
      }
    } catch (e) {
      return;
    }

    // Show edit dialog
    final newText = await showDialog<String>(
      context: context,
      builder: (context) =>
          _EditMessageDialog(initialText: message.message ?? ''),
    );

    if (newText != null && newText.trim().isNotEmpty && mounted) {
      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ).notifier,
      );

      // Optimistic update
      chatNotifier.updateMessageLocally(
        message.id,
        newText: newText,
        isEdited: true,
      );

      // Call API
      final messageService = ref.read(messageServiceProvider);
      final result = await messageService.editMessage(
        messageId: message.id,
        message: newText,
      );

      if (result['success'] != true && mounted) {
        // Revert on failure
        chatNotifier.updateMessageLocally(message.id, newText: message.message);
        showChatSnackBar(context, message: result['error'] ?? 'Failed to edit message', type: ChatSnackBarType.error);
      }
    }
  }

  /// Handle delete message action
  void _handleDeleteMessage(Message message) async {
    if (_currentUserId == null) return;

    await showDeleteMessageDialog(
      context,
      message: message,
      otherUserName: widget.userName,
      onDelete: (deleteForEveryone) async {
        // Check mounted before using ref in callback
        if (!mounted) return;

        final chatNotifier = ref.read(
          chatStateProvider(
            ChatProviderParams(
              chatPartnerId: widget.userId,
              currentUserId: _currentUserId!,
            ),
          ).notifier,
        );

        // Optimistic update
        if (deleteForEveryone) {
          chatNotifier.markMessageAsDeleted(message.id);
        } else {
          chatNotifier.removeMessageLocally(message.id);
        }

        // Call API
        final messageService = ref.read(messageServiceProvider);
        final result = await messageService.deleteMessage(
          messageId: message.id,
          deleteForEveryone: deleteForEveryone,
        );

        if (result['success'] != true && mounted) {
          // Revert on failure - reload messages
          await _loadMessages();
          showChatSnackBar(context, message: result['error'] ?? 'Failed to delete message', type: ChatSnackBarType.error);
        }
      },
    );
  }

  /// Handle pin/unpin message action
  void _handlePinMessage(Message message) async {
    if (_currentUserId == null || !mounted) return;

    final chatNotifier = ref.read(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: widget.userId,
          currentUserId: _currentUserId!,
        ),
      ).notifier,
    );

    // Optimistic update
    chatNotifier.togglePinLocally(message.id);

    // Call API
    final messageService = ref.read(messageServiceProvider);
    final result = await messageService.pinMessage(messageId: message.id);

    // Check mounted after async operation
    if (!mounted) return;

    if (result['success'] != true) {
      // Revert on failure
      chatNotifier.togglePinLocally(message.id);
      showChatSnackBar(context, message: result['error'] ?? 'Failed to update pin status', type: ChatSnackBarType.error);
    } else if (mounted) {
      // Show confirmation
      showChatSnackBar(
        context,
        message: message.isPinned ? 'Message unpinned' : 'Message pinned',
        type: ChatSnackBarType.success,
      );
    }
  }

  /// Handle forward message action
  void _handleForwardMessage(Message message) async {
    if (_currentUserId == null) return;

    // Get list of chat partners from unread counts (user IDs)
    final chatPartnersState = ref.read(chatPartnersProvider);
    final userIds = chatPartnersState.unreadCounts.keys
        .where((id) => id != widget.userId) // Exclude current chat partner
        .toList();

    // If no chat partners from unread counts, try to get from current messages
    if (userIds.isEmpty) {
      // Get unique user IDs from recent conversations
      final chatState = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ),
      );

      // Get unique sender/receiver IDs that aren't current user or current chat partner
      final uniqueUserIds = <String>{};
      for (final msg in chatState.messages) {
        if (msg.sender.id != _currentUserId && msg.sender.id != widget.userId) {
          uniqueUserIds.add(msg.sender.id);
        }
        if (msg.receiver.id != _currentUserId &&
            msg.receiver.id != widget.userId) {
          uniqueUserIds.add(msg.receiver.id);
        }
      }
      userIds.addAll(uniqueUserIds);
    }

    if (userIds.isEmpty) {
      showChatSnackBar(context, message: 'No other users to forward to', type: ChatSnackBarType.info);
      return;
    }

    final messageService = ref.read(messageServiceProvider);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => ForwardMessageDialog(
        userIds: userIds,
        messageService: messageService,
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final forwardResult = await messageService.forwardMessage(
        messageId: message.id,
        receivers: result,
      );

      if (forwardResult['success'] == true && mounted) {
        showChatSnackBar(
          context,
          message: AppLocalizations.of(context)!.messageForwardedTo(result.length),
          type: ChatSnackBarType.success,
        );
      } else if (mounted) {
        showChatSnackBar(
          context,
          message: forwardResult['error'] ?? 'Failed to forward message',
          type: ChatSnackBarType.error,
        );
      }
    }
  }

  /// Handle retry sending failed message
  void _handleRetryMessage(Message message) async {
    if (_currentUserId == null || !mounted) return;

    final messageText = message.message;
    if (messageText == null || messageText.isEmpty) return;

    final chatNotifier = ref.read(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: widget.userId,
          currentUserId: _currentUserId!,
        ),
      ).notifier,
    );

    // Remove the failed message first
    chatNotifier.removeMessageLocally(message.localId ?? message.id);

    // Send again (only supports text retry for now)
    await _sendMessage(messageText: messageText);
  }

  /// Handle deleting failed message from UI
  void _handleDeleteFailedMessage(Message message) {
    if (_currentUserId == null || !mounted) return;

    final chatNotifier = ref.read(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: widget.userId,
          currentUserId: _currentUserId!,
        ),
      ).notifier,
    );

    // Remove the failed message from the UI
    chatNotifier.removeMessageLocally(message.localId ?? message.id);

    if (mounted) {
      showChatSnackBar(context, message: 'Message deleted', type: ChatSnackBarType.success);
    }
  }

  void _handleCallError(BuildContext context, String error) {
    if (error.startsWith('PERMANENTLY_DENIED:')) {
      final message = error.substring('PERMANENTLY_DENIED:'.length);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.permissionsRequired),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppSettings.openAppSettings();
              },
              child: Text(AppLocalizations.of(context)!.openSettings),
            ),
          ],
        ),
      );
    } else if (error.startsWith('DENIED:')) {
      final message = error.substring('DENIED:'.length);
      showChatSnackBar(context, message: message, type: ChatSnackBarType.info);
    } else {
      showChatSnackBar(context, message: error, type: ChatSnackBarType.error);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clear active chat so global listener can increment unread for new messages
    // Use Future.microtask to defer provider modification until after widget tree finalization
    final notifier = _chatPartnersNotifier;
    if (notifier != null) {
      Future.microtask(() => notifier.clearActiveChat());
    }

    // Mark chat as not visible so messages won't be auto-read
    // Use cached notifier since ref is not usable after dispose
    _chatStateNotifier?.setChatVisible(false);

    _typingTimer?.cancel();
    _themeChangeSubscription?.cancel();
    // Note: Don't send typing=false here since we can't safely access providers in dispose
    // The backend handles typing timeout automatically (5 seconds)
    _messageController.dispose();
    _scrollController.dispose();
    _mediaPanelController.dispose();
    _stickerPanelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chatParams = ChatProviderParams(
      chatPartnerId: widget.userId,
      currentUserId: _currentUserId!,
    );

    // Listen for new messages and auto-scroll to bottom
    ref.listen<ChatState>(chatStateProvider(chatParams), (previous, next) {
      // Check if a new message was added (not just loading initial messages)
      if (previous != null &&
          next.messages.length > previous.messages.length &&
          !next.isLoading) {
        // Only auto-scroll if user is near the bottom (not reading old messages)
        final isNearBottom =
            !_scrollController.hasClients ||
            (_scrollController.position.maxScrollExtent -
                    _scrollController.offset) <
                300;
        if (isNearBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _scrollToBottom(animated: false);
              });
            }
          });
        }
      }
    });

    final chatState = ref.watch(chatStateProvider(chatParams));

    // Check the other user's privacy settings to decide whether to show online status
    final otherUserAsync = ref.watch(singleCommunityProvider(widget.userId));
    final showOnlineStatus =
        otherUserAsync.whenOrNull(
          data: (community) => community != null
              ? PrivacyUtils.shouldShowOnlineStatus(community)
              : true,
        ) ??
        true;

    return Scaffold(
      appBar: ChatAppBar(
        userName: widget.userName,
        profilePicture: widget.profilePicture,
        isTyping: chatState.isOtherUserTyping,
        userId: widget.userId,
        isConnected: chatState.isSocketConnected,
        connectionStatus: chatState.connectionStatus,
        isOnline: showOnlineStatus ? chatState.isOtherUserOnline : null,
        lastSeen: showOnlineStatus ? chatState.otherUserLastSeen : null,
        onThemeChanged: _loadChatWallpaper,
        isVip: widget.isVip,
      ),
      body: Container(
        decoration: _getWallpaperDecoration(),
        child: GestureDetector(
          onTap: _hidePanels,
          child: ClipRect(
            child: Column(
              children: [
                const ConnectionStatusIndicator(),
                // Pinned messages bar
                if (chatState.pinnedMessages.isNotEmpty)
                  PinnedMessagesBar(
                    pinnedMessages: chatState.pinnedMessages,
                    onTap: () {
                      if (chatState.pinnedMessages.isNotEmpty) {
                        _scrollToMessage(chatState.pinnedMessages.first.id);
                      }
                    },
                    onClose: () {
                      // Unpin the message when X is clicked
                      if (chatState.pinnedMessages.isNotEmpty) {
                        _handlePinMessage(chatState.pinnedMessages.first);
                      }
                    },
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadMessages,
                        displacement: 20,
                        color: AppColors.primary,
                        child: ChatMessagesList(
                          isLoading: chatState.isLoading,
                          error: chatState.error,
                          messages: chatState.messages,
                          currentUserId: _currentUserId,
                          otherUserName: widget.userName,
                          otherUserPicture: widget.profilePicture,
                          otherUserTyping: chatState.isOtherUserTyping,
                          scrollController: _scrollController,
                          onRetry: _loadMessages,
                          isSelectionMode: _isSelectionMode,
                          selectedMessageIds: _selectedMessageIds,
                          isLoadingMore: _isLoadingMore,
                          hasMoreMessages: _hasMoreMessages,
                          headerWidget:
                              _buildUserInfoHeader(), // User info at top
                          onSelectionChanged: (msg, selected) {
                            setState(() {
                              if (selected) {
                                _selectedMessageIds.add(msg.id);
                                if (!_isSelectionMode) _isSelectionMode = true;
                              } else {
                                _selectedMessageIds.remove(msg.id);
                                if (_selectedMessageIds.isEmpty)
                                  _isSelectionMode = false;
                              }
                            });
                          },
                          onDelete: _handleDeleteMessage,
                          onEdit: _handleEditMessage,
                          onReply: (msg) =>
                              setState(() => _replyingToMessage = msg),
                          onReplyTap: _scrollToMessage,
                          onPin: _handlePinMessage,
                          onUnpin:
                              _handlePinMessage, // Same handler - it toggles
                          onForward: _handleForwardMessage,
                          onRetryMessage: _handleRetryMessage,
                          onDeleteFailedMessage: _handleDeleteFailedMessage,
                          onSendWave: _sendWaveSticker,
                        ),
                      ),
                      // Scroll to bottom button
                      if (_showScrollButton)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _buildScrollToBottomButton(),
                        ),
                    ],
                  ),
                ),
                if (_isBlockedChat)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      border: Border(
                        top: BorderSide(
                          color: context.dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block,
                          size: 18,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.cannotSendMessageUserMayBeBlocked,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ChatInputSection(
                    messageController: _messageController,
                    isSending: _isSending,
                    showMediaPanel: _showMediaPanel,
                    showStickerPanel: _showStickerPanel,
                    mediaPanelController: _mediaPanelController,
                    stickerPanelController: _stickerPanelController,
                    onSendMessage: _sendMessage,
                    onSelectSticker: _selectSticker,
                    onSendGif: (gifUrl) {
                      _hidePanels();
                      _sendMessage(messageText: gifUrl, messageType: 'gif');
                    },
                    onToggleMediaPanel: _toggleMediaPanel,
                    onToggleStickerPanel: _toggleStickerPanel,
                    onTyping: _onTyping,
                    onStopTyping: _stopTyping,
                    onHidePanels: _hidePanels,
                    onMediaOption: _handleMediaOption,
                    replyingToMessage: _replyingToMessage,
                    otherUserName: widget.userName,
                    onCancelReply: () =>
                        setState(() => _replyingToMessage = null),
                    onAudioPressed: _showVoiceRecorder,
                    uploadBytesSent: _uploadBytesSent,
                    uploadTotalBytes: _uploadTotalBytes,
                    uploadFileName: _uploadFileName,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact user info header at top of chat
  Widget _buildCompactUserInfoHeader() {
    final communityAsync = ref.watch(singleCommunityProvider(widget.userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return communityAsync.when(
      data: (user) {
        // Calculate age from birth_year
        int? age;
        if (user?.birth_year != null && user!.birth_year.isNotEmpty) {
          try {
            final birthYear = int.parse(user.birth_year);
            age = DateTime.now().year - birthYear;
          } catch (_) {}
        }

        // Get location string (respects privacy settings)
        String? location;
        if (user != null) {
          final locText = PrivacyUtils.getLocationText(user);
          if (locText.isNotEmpty) {
            location = locText;
          }
        }

        return GestureDetector(
          onTap: () => _navigateToProfile(user),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.gray900.withValues(alpha: 0.9)
                  : AppColors.white.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.gray800 : AppColors.gray200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Small profile picture
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: widget.profilePicture != null
                        ? Image.network(
                            widget.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary.withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and age
                      Row(
                        children: [
                          Text(
                            user?.name ?? widget.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.gray900,
                            ),
                          ),
                          if (age != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$age',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Location and languages in one line
                      Row(
                        children: [
                          if (location != null) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray600,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.gray400
                                      : AppColors.gray600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (location != null &&
                              (user?.native_language != null ||
                                  user?.language_to_learn != null))
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.gray500
                                      : AppColors.gray400,
                                ),
                              ),
                            ),
                          if (user?.native_language != null)
                            Text(
                              user!.native_language,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (user?.native_language != null &&
                              user?.language_to_learn != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 10,
                                color: isDark
                                    ? AppColors.gray500
                                    : AppColors.gray400,
                              ),
                            ),
                          if (user?.language_to_learn != null)
                            Text(
                              user!.language_to_learn,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon to indicate tap action
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark ? AppColors.gray500 : AppColors.gray400,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.gray900.withValues(alpha: 0.9)
              : AppColors.white.withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.gray800 : AppColors.gray200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.gray700 : AppColors.gray300,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  color: isDark ? AppColors.gray700 : AppColors.gray300,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 150,
                  height: 10,
                  color: isDark ? AppColors.gray700 : AppColors.gray200,
                ),
              ],
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Navigate to full user profile
  void _navigateToProfile(dynamic user) {
    if (user != null) {
      Navigator.push(
        context,
        AppPageRoute(builder: (_) => SingleCommunity(community: user)),
      );
    }
  }

  /// Build user info header shown at top of chat (scrollable with messages)
  Widget _buildUserInfoHeader() {
    final communityAsync = ref.watch(singleCommunityProvider(widget.userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return communityAsync.when(
      data: (user) {
        // Debug: Print user data

        // Calculate age from birth_year
        int? age;
        if (user?.birth_year != null && user!.birth_year.isNotEmpty) {
          try {
            final birthYear = int.parse(user.birth_year);
            age = DateTime.now().year - birthYear;
          } catch (_) {}
        }

        // Get location string (respects privacy settings)
        String? location;
        if (user != null) {
          final locText = PrivacyUtils.getLocationText(user);
          if (locText.isNotEmpty) {
            location = locText;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bigger profile picture (100px)
              GestureDetector(
                onTap: () => _navigateToProfile(user),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        widget.profilePicture != null &&
                            widget.profilePicture!.isNotEmpty
                        ? Image.network(
                            widget.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name and age
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.gray900,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$age',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Location
              if (location != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ],

              // Bio
              if (user?.bio != null && user!.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.05)
                        : AppColors.gray500.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.bio,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // Interests / Topics
              if (user?.topics != null && user!.topics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: user.topics.take(5).map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        topic,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 8),

              // Divider
              Divider(
                color: isDark ? AppColors.gray700 : AppColors.gray300,
                height: 1,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build empty chat state - shows user info, bio, interests, and "Say Hi" button
  Widget _buildEmptyChatWithUserInfo(ChatState chatState) {
    final communityAsync = ref.watch(singleCommunityProvider(widget.userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return communityAsync.when(
      data: (user) {
        // Debug: Print user data

        // Calculate age from birth_year
        int? age;
        if (user?.birth_year != null && user!.birth_year.isNotEmpty) {
          try {
            final birthYear = int.parse(user.birth_year);
            age = DateTime.now().year - birthYear;
          } catch (_) {}
        }

        // Get location string (respects privacy settings)
        String? location;
        if (user != null) {
          final locText = PrivacyUtils.getLocationText(user);
          if (locText.isNotEmpty) {
            location = locText;
          }
        }

        return ListView(
          reverse: true,
          controller: _scrollController,
          children: [
            // User info card with image, bio, interests
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bigger profile picture (100px)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          widget.profilePicture != null &&
                              widget.profilePicture!.isNotEmpty
                          ? Image.network(
                              widget.profilePicture!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name and age
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.userName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.gray900,
                        ),
                      ),
                      if (age != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$age',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Location
                  if (location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.gray400
                                : AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Bio
                  if (user?.bio != null && user!.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.05)
                            : AppColors.gray500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  // Interests / Topics
                  if (user?.topics != null && user!.topics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: user.topics.take(5).map((topic) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            topic,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Say Hi button - sends wave sticker
                  GestureDetector(
                    onTap: _sendWaveSticker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFCA28,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👋', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'Say Hi!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => ListView(
        reverse: true,
        controller: _scrollController,
        children: [
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (_, __) => ListView(
        reverse: true,
        controller: _scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👋', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                Text(
                  'Start a conversation with ${widget.userName}!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _sendWaveSticker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFCA28).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👋', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(
                          'Say Hi!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Send wave sticker to start conversation
  void _sendWaveSticker() {
    _sendMessage(messageText: '👋');
  }

  /// Build scroll to bottom floating button
  Widget _buildScrollToBottomButton() {
    final isDarkBtn = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _scrollToBottom,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: isDarkBtn ? AppColors.gray700 : AppColors.gray300,
            ),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
        ),
      ),
    );
  }

  BoxDecoration _getWallpaperDecoration() {
    if (_chatWallpaper == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.gray100,
      );
    }

    if (_chatWallpaper!.startsWith('gradient_')) {
      return BoxDecoration(gradient: _getGradient(_chatWallpaper!));
    }

    return BoxDecoration(color: _getColor(_chatWallpaper!));
  }

  LinearGradient? _getGradient(String gradientName) {
    const gradients = {
      'gradient_sunset': [Color(0xFFFF512F), Color(0xFFDD2476)],
      'gradient_ocean': [Color(0xFF2193B0), Color(0xFF6DD5ED)],
      'gradient_aurora': [
        Color(0xFF0F2027),
        Color(0xFF203A43),
        Color(0xFF2C5364),
      ],
      'gradient_purple': [Color(0xFF667EEA), Color(0xFF764BA2)],
      'gradient_midnight': [Color(0xFF232526), Color(0xFF414345)],
      'gradient_forest': [Color(0xFF134E5E), Color(0xFF71B280)],
      'gradient_rose': [Color(0xFFB76E79), Color(0xFFE8B4B8)],
      'gradient_candy': [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
      'gradient_neon': [Color(0xFF00F260), Color(0xFF0575E6)],
      'gradient_fire': [Color(0xFFF12711), Color(0xFFF5AF19)],
      'gradient_winter': [Color(0xFFE6DADA), Color(0xFF274046)],
      'gradient_lavender': [Color(0xFFEE9CA7), Color(0xFFFFDDE1)],
      // Legacy gradients for backwards compatibility
      'gradient_blue': [
        Color(0xFF4158D0),
        Color(0xFFC850C0),
        Color(0xFFFFCC70),
      ],
      'gradient_green': [
        Color(0xFF0F2027),
        Color(0xFF203A43),
        Color(0xFF2C5364),
      ],
      'gradient_pink': [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    };

    final colors = gradients[gradientName];
    if (colors == null) return null;

    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getColor(String colorName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 'default' and 'light' adapt to the current theme
    if (colorName == 'default' || colorName == 'light') {
      return isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5);
    }

    // Light colors get dark variants in dark mode
    if (isDark) {
      const darkOverrides = {
        'blush': Color(0xFF5C1A3A),
        'peach': Color(0xFF4A3728),
        'cream': Color(0xFF2D2D2D),
        'pink': Color(0xFF5C1A3A),
      };
      if (darkOverrides.containsKey(colorName)) {
        return darkOverrides[colorName]!;
      }
    }

    const colors = {
      'dark': Color(0xFF0D0D0D),
      'midnight': Color(0xFF1A1A2E),
      'charcoal': Color(0xFF2D2D2D),
      'navy': Color(0xFF0A1628),
      'ocean': Color(0xFF1E3A5F),
      'teal': Color(0xFF115E59),
      'forest': Color(0xFF1B4332),
      'sage': Color(0xFF4A5D4A),
      'wine': Color(0xFF4A1942),
      'plum': Color(0xFF5B2C6F),
      'rose': Color(0xFF8B3A62),
      'blush': Color(0xFFE8B4BC),
      'peach': Color(0xFFE6A67C),
      'cream': Color(0xFFF5E6D3),
      'mocha': Color(0xFF4A3728),
      // New dark-mode colors
      'slate': Color(0xFF1E293B),
      'ember': Color(0xFF3B1A1A),
      'deep_sea': Color(0xFF0B2545),
      // Legacy colors for backwards compatibility
      'blue': Color(0xFF1E3A5F),
      'pink': Color(0xFFE8B4BC),
      'green': Color(0xFF2D5A27),
      'purple': Color(0xFF6B5B95),
      'sunset': Color(0xFFFF6B6B),
    };

    return colors[colorName] ??
        (isDark ? AppColors.backgroundDark : AppColors.gray100);
  }
}

/// Simple edit message dialog
class _EditMessageDialog extends StatefulWidget {
  final String initialText;

  const _EditMessageDialog({required this.initialText});

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        AppLocalizations.of(context)!.editMessage,
        style: TextStyle(
          color: isDark ? AppColors.white : AppColors.gray900,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        minLines: 1,
        maxLength: 2000,
        style: TextStyle(color: isDark ? AppColors.white : AppColors.gray900),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterMessage,
          hintStyle: TextStyle(
            color: isDark ? AppColors.gray500 : AppColors.gray600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.gray700 : AppColors.gray300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.gray700 : AppColors.gray300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(context, text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.save,
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}
