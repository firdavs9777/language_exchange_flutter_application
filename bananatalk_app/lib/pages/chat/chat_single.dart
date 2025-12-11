import 'package:bananatalk_app/pages/chat/chat_app_bar.dart';
import 'package:bananatalk_app/pages/chat/chat_input_section.dart';
import 'package:bananatalk_app/pages/chat/chat_messages_list.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/utils/api_error_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/services/media_service.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

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
    if (_currentUserId == null) {
      setState(() => _error = "User ID not found");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() => _error = "Authentication token not found");
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
            .setTimeout(5000) // Increased timeout
            .build(),
      );

      _setupSocketListeners();
      _socket?.connect();
    } catch (e) {
      print('❌ Error initializing socket: $e');
      setState(() => _error = 'Failed to connect: ${e.toString()}');
    }
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
        final messageJson = data is Map 
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final newMessage = Message.fromJson(messageJson);
        _handleNewMessage(newMessage);
      } catch (e) {
        print('❌ Error parsing message: $e');
      }
    });

    _socket?.on('messageSent', (data) {
      try {
        final messageData = data is Map ? data['message'] : data;
        if (messageData != null) {
          Map<String, dynamic> messageJson;
          if (messageData is Map) {
            messageJson = Map<String, dynamic>.from(messageData);
          } else {
            messageJson = {
              '_id': '',
              'sender': <String, dynamic>{},
              'receiver': <String, dynamic>{},
              'message': '',
              'createdAt': DateTime.now().toIso8601String(),
              '__v': 0,
              'read': false,
            };
          }
          final sentMessage = Message.fromJson(messageJson);
          _handleNewMessage(sentMessage);
          setState(() {
            _isSending = false;
            _error = ''; // Clear any previous errors
          });
        } else {
          setState(() => _isSending = false);
        }
      } catch (e) {
        print('❌ Error parsing sent message: $e');
        setState(() {
          _isSending = false;
          _error = 'Failed to parse sent message';
        });
      }
    });

    _socket?.on('newMessage', (data) {
      try {
        final messageData = data is Map ? data['message'] : null;
        if (messageData != null && messageData is Map) {
          final messageJson = Map<String, dynamic>.from(messageData);
          final newMessage = Message.fromJson(messageJson);
          _handleNewMessage(newMessage);
        }
      } catch (e) {
        print('❌ Error parsing new message: $e');
      }
    });

    _socket?.on('messageError', (data) {
      print('❌ Message error received: $data');
      
      String errorMessage = 'Failed to send message';
      
      if (data is Map) {
        // Try to extract a user-friendly error message
        final error = data['error'] ?? data['message'];
        if (error != null) {
          final errorStr = error.toString();
          print('🔍 Parsing error: $errorStr');
          
          // Handle specific backend errors
          if (errorStr.toLowerCase().contains('isblocked') || 
              errorStr.toLowerCase().contains('blocked')) {
            errorMessage = 'Cannot send message. User may be blocked.';
            print('✅ Matched blocked error - showing user-friendly message');
          } else if (errorStr.toLowerCase().contains('limit') || 
                     errorStr.toLowerCase().contains('429')) {
            errorMessage = 'Daily message limit reached. Please try again later.';
          } else if (errorStr.toLowerCase().contains('not found') || 
                     errorStr.toLowerCase().contains('404')) {
            errorMessage = 'User not found.';
          } else if (errorStr.toLowerCase().contains('unauthorized') || 
                     errorStr.toLowerCase().contains('401')) {
            errorMessage = 'Authentication failed. Please log in again.';
          } else {
            // For backend errors like "is not a function", show generic message
            errorMessage = 'Failed to send message. Please try again.';
          }
        } else {
          print('⚠️ No error field found in data');
        }
      } else if (data != null) {
        final errorStr = data.toString();
        if (errorStr.toLowerCase().contains('isblocked') || 
            errorStr.toLowerCase().contains('blocked')) {
          errorMessage = 'Cannot send message. User may be blocked.';
        } else {
          errorMessage = 'Failed to send message. Please try again.';
        }
      }
      
      print('📱 Showing error message to user: $errorMessage');
      
      setState(() {
        _isSending = false;
        // Don't set _error here - it will block the UI
        // Instead, show a snackbar
      });
      
      // Show error to user via snackbar (non-blocking)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Retry sending if there's text in the controller
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage();
                }
              },
            ),
          ),
        );
      }
      
      // Restore original message if provided
      if (data is Map && data['originalMessage'] != null) {
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
      // If limit check fails, allow sending (fail open)
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
        throw Exception('Socket not connected. Please check your connection.');
      }
      
      _socket!.emit('sendMessage', {
        'sender': _currentUserId,
        'receiver': widget.userId,
        'message': text,
        'type': messageType ?? 'text',
      });
      
      // Don't set _isSending to false here - wait for socket response
      // The socket will emit 'messageSent' or 'messageError' which will handle the state
      
      // Refresh limits after sending (optimistically)
      if (_currentUserId != null) {
        // Don't await - do it in background
        try {
          ref.refresh(userLimitsProvider(_currentUserId!));
        } catch (e) {
          // Ignore errors in background refresh
          print('Error refreshing limits: $e');
        }
      }
    } catch (error) {
      setState(() {
        _error = 'Failed to send message: ${error.toString()}';
        _isSending = false;
      });
      
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
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      if (messageText == null) _messageController.text = text;
    }
  }

  void _sendSticker(String sticker) {
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

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await _sendMediaFile(file, 'image');
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

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await _sendMediaFile(file, 'image');
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
          content: Text('Document picker requires file_picker package. Please add it to pubspec.yaml'),
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
          content: Text('Audio recording feature coming soon! Use gallery to select audio files.'),
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
              content: Text('Location permission is required to share location'),
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
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
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

  Future<void> _sendMediaFile(File file, String? mediaType) async {
    try {
      // Basic validation (size check only - let backend validate file type)
      final validation = MediaService.validateMediaFile(file, mediaType);
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
        messageText: null, // Can add optional text later
        mediaFile: file,
        mediaType: validation['mediaType'],
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
        userId: widget.userId,
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
