// lib/pages/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/chat_state_provider.dart';
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
import 'package:bananatalk_app/screens/incoming_call_screen.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/widgets/image_preview_dialog.dart';
import 'package:bananatalk_app/utils/api_error_handler.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/media_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:bananatalk_app/widgets/voice_recorder_widget.dart';
import 'package:bananatalk_app/services/voice_message_service.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/pages/video_editor/video_editor_screen.dart';

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

      await chatNotifier.initialize();
      await _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;

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
      final conversationMessages = await messageService.getConversation(
        senderId: _currentUserId!,
        receiverId: widget.userId,
      );

      // Sort messages by creation date (oldest first for proper display)
      conversationMessages.sort(
        (a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
      );

      print(
        '📥 Loaded ${conversationMessages.length} messages for conversation',
      );
      chatNotifier.setMessages(conversationMessages);

      ref
          .read(messageCountProvider.notifier)
          .setMessageCount(widget.userId, conversationMessages.length);

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (error) {
      print('❌ Error loading messages: $error');
      chatNotifier.setError('Failed to load messages: $error');
    } finally {
      chatNotifier.setLoading(false);
    }
  }

  Future<void> _loadChatWallpaper() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('chat_theme_${widget.userId}');
      if (theme != null && mounted) {
        setState(() => _chatWallpaper = theme);
      }
    } catch (e) {
      print('Error loading chat wallpaper: $e');
    }
  }

  void _setupCallListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callNotifier = ref.read(callProvider.notifier);
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
      callNotifier.setCallErrorCallback((error) {
        if (mounted) _handleCallError(context, error);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = ref.watch(authServiceProvider);
    if (!authService.isLoggedIn && _currentUserId != null) {
      print('🚫 User logged out - disposing chat');
    }
  }

  void _toggleMediaPanel() {
    setState(() {
      if (_showStickerPanel) {
        _showStickerPanel = false;
        _stickerPanelController.reverse();
      }
      _showMediaPanel = !_showMediaPanel;
      _showMediaPanel
          ? _mediaPanelController.forward()
          : _mediaPanelController.reverse();
    });
  }

  void _toggleStickerPanel() {
    setState(() {
      if (_showMediaPanel) {
        _showMediaPanel = false;
        _mediaPanelController.reverse();
      }
      _showStickerPanel = !_showStickerPanel;
      _showStickerPanel
          ? _stickerPanelController.forward()
          : _stickerPanelController.reverse();
    });
  }

  void _hidePanels() {
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
    if (_currentUserId == null) return;

    final text = messageText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Check limits
    try {
      final userAsync = ref.read(userProvider);
      final user = await userAsync.when(
        data: (user) => user,
        loading: () => null,
        error: (_, __) => null,
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

    setState(() => _isSending = true);

    try {
      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: widget.userId,
            currentUserId: _currentUserId!,
          ),
        ).notifier,
      );

      // Handle replies via API
      if (_replyingToMessage != null) {
        final messageService = ref.read(messageServiceProvider);
        final result = await messageService.replyToMessage(
          messageId: _replyingToMessage!.id,
          message: text,
          receiver: widget.userId,
        );

        if (mounted) setState(() => _isSending = false);

        if (result['success'] == true) {
          final replyMessage = result['data'] as Message;
          final state = ref.read(
            chatStateProvider(
              ChatProviderParams(
                chatPartnerId: widget.userId,
                currentUserId: _currentUserId!,
              ),
            ),
          );

          final messages = List<Message>.from(state.messages)
            ..add(replyMessage);
          messages.sort(
            (a, b) => DateTime.parse(
              a.createdAt,
            ).compareTo(DateTime.parse(b.createdAt)),
          );
          chatNotifier.setMessages(messages);

          setState(() => _replyingToMessage = null);
          _messageController.clear();
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
        return;
      }

      // Send via socket
      final result = await chatNotifier.sendMessage(text);

      if (mounted) setState(() => _isSending = false);

      if (result['status'] == 'success') {
        print('✅ ChatScreen: Message sent successfully');
        setState(() => _replyingToMessage = null);
        ref
            .read(messageCountProvider.notifier)
            .refreshMessageCount(widget.userId);
        ref.refresh(userLimitsProvider(_currentUserId!));
      } else {
        print('❌ ChatScreen: Message send failed: ${result['error']}');
        _messageController.text = text;
        _showSendError(
          result['error'] ?? 'Failed to send message',
          text,
          messageType,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSending = false);
        _messageController.text = text;

        if (ApiErrorHandler.isLimitExceededError(error)) {
          await ApiErrorHandler.handleLimitExceededError(
            context: context,
            error: error,
            userId: _currentUserId,
          );
        } else {
          _showSendError(error.toString(), text, messageType);
        }
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

    if (errorMessage.toLowerCase().contains('limit')) {
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
          label: l10n.retry,
          textColor: Colors.white,
          onPressed: () =>
              _sendMessage(messageText: originalText, messageType: messageType),
        ),
      ),
    );
  }

  /// Send sticker directly (tap to send like WhatsApp)
  void _sendSticker(String sticker) {
    _sendMessage(messageText: sticker, messageType: 'sticker');
    // Close sticker panel after sending
    setState(() {
      _showStickerPanel = false;
    });
    _stickerPanelController.reverse();
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document picker coming soon')),
            );
          }
          break;
        case 'audio':
          await _showVoiceRecorder();
          break;
        case 'location':
          await _shareLocation();
          break;
        case 'contact':
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact sharing coming soon')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video must be under 1GB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Open video editor for trimming and filters before sending
        await _processAndSendVideo(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video must be under 1GB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Open video editor for trimming and filters
        await _processAndSendVideo(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Process video through editor before sending
  Future<void> _processAndSendVideo(File videoFile) async {
    // Open video editor for trimming and filters
    final editorResult = await Navigator.push<VideoEditorResult>(
      context,
      MaterialPageRoute(
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
    final needsCompression = await compressionService.needsCompression(editedVideoFile);

    File finalVideoFile = editedVideoFile;
    if (needsCompression) {
      // Show compression dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00BFA5)),
              const SizedBox(height: 16),
              const Text(
                'Compressing video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
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
    setState(() => _isSending = true);

    try {
      final messageService = ref.read(messageServiceProvider);
      final result = await messageService.sendVideoMessage(
        receiver: widget.userId,
        videoFile: videoFile,
      );

      setState(() => _isSending = false);

      if (result['success'] == true) {
        await _loadMessages();
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
      } else {
        if (mounted) {
          String errorMsg = result['error'] ?? 'Failed to send video';
          if (errorMsg.contains('duration') || errorMsg.contains('600 seconds') || errorMsg.contains('10 minutes')) {
            errorMsg = 'Video must be under 10 minutes';
          } else if (errorMsg.contains('size') || errorMsg.contains('1024MB') || errorMsg.contains('1GB')) {
            errorMsg = 'Video must be under 1GB. Please compress the video.';
          } else if (errorMsg.contains('format')) {
            errorMsg = 'Unsupported video format. Use MP4, MOV, or WebM.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      final result = await VoiceMessageService.sendVoiceMessage(
        receiverId: widget.userId,
        voiceFile: voiceFile,
        durationSeconds: durationSeconds,
        waveform: waveform,
      );

      setState(() => _isSending = false);

      if (result['success'] == true) {
        await _loadMessages();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending voice message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareLocation() async {
    try {
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

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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

      if (mounted) Navigator.of(context).pop();

      final result = await MediaService.sendMessageWithLocation(
        receiverId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        placeName: placeName,
      );

      if (result['success'] == true) {
        await _loadMessages();
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
        Navigator.of(context).pop();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation['error'] ?? 'Invalid file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _isSending = true);

      final result = await MediaService.sendMessageWithMedia(
        receiverId: widget.userId,
        messageText: caption,
        mediaFile: file,
        mediaType: detectedType ?? 'image',
      );

      setState(() => _isSending = false);

      if (result['success'] == true) {
        await _loadMessages();
        if (_currentUserId != null) {
          ref.refresh(userLimitsProvider(_currentUserId!));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to send media'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSending = false);
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // For reversed ListView, scroll to 0.0 (top of reversed list = bottom visually)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
    }
  }

  void _handleCallError(BuildContext context, String error) {
    if (error.startsWith('PERMANENTLY_DENIED:')) {
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
      final message = error.substring('DENIED:'.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTyping && _currentUserId != null) {
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

    final chatState = ref.watch(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: widget.userId,
          currentUserId: _currentUserId!,
        ),
      ),
    );

    print(
      '🔍 Build - Messages: ${chatState.messages.length}, Connected: ${chatState.isSocketConnected}',
    );

    return Scaffold(
      appBar: ChatAppBar(
        userName: widget.userName,
        profilePicture: widget.profilePicture,
        isTyping: chatState.isOtherUserTyping,
        userId: widget.userId,
        isConnected: chatState.isSocketConnected,
        isOnline: chatState.isOtherUserOnline,
        lastSeen: chatState.otherUserLastSeen,
        onThemeChanged: _loadChatWallpaper,
      ),
      body: Container(
        decoration: _getWallpaperDecoration(),
        child: GestureDetector(
          onTap: _hidePanels,
          child: Column(
            children: [
              ConnectionStatusIndicator(),
              Expanded(
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
                  onDelete: null,
                  onEdit: null,
                  onReply: (msg) => setState(() => _replyingToMessage = msg),
                  onPin: null,
                  onUnpin: null,
                  onForward: null,
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
                onCancelReply: () => setState(() => _replyingToMessage = null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _getWallpaperDecoration() {
    if (_chatWallpaper == null) {
      return BoxDecoration(color: Colors.grey[100]);
    }

    if (_chatWallpaper!.startsWith('gradient_')) {
      return BoxDecoration(gradient: _getGradient(_chatWallpaper!));
    }

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
