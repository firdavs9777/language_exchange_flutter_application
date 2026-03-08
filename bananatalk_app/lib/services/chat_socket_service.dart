// lib/services/chat_socket_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal() {
    // Initialize network connectivity listener
    _initConnectivityListener();
  }

  IO.Socket? _socket;
  String? _currentUserId;
  String? _deviceId;
  bool _shouldAllowReconnection = true;
  bool _isConnecting = false; // Prevent concurrent connection attempts

  // Reconnection strategy - increased for better reliability
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10; // Reduced to avoid excessive retries
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isPermanentlyDisconnected = false; // Track if we gave up

  // Connection cooldown - prevent rapid reconnection attempts
  DateTime? _lastConnectedAt;
  static const _connectionCooldown = Duration(seconds: 3);

  // Network connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  // Stream controllers for events
  final _newMessageController = StreamController<dynamic>.broadcast();
  final _messageSentController = StreamController<dynamic>.broadcast();
  final _typingController = StreamController<dynamic>.broadcast();
  final _statusUpdateController = StreamController<dynamic>.broadcast();
  final _messageReadController = StreamController<dynamic>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _messageDeliveryController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageReactionController = StreamController<dynamic>.broadcast();
  final _themeChangedController = StreamController<dynamic>.broadcast();

  // Getters for streams
  Stream<dynamic> get onNewMessage => _newMessageController.stream;
  Stream<dynamic> get onMessageSent => _messageSentController.stream;
  Stream<dynamic> get onTyping => _typingController.stream;
  Stream<dynamic> get onStatusUpdate => _statusUpdateController.stream;
  Stream<dynamic> get onMessageRead => _messageReadController.stream;
  Stream<bool> get onConnectionStateChange => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivery =>
      _messageDeliveryController.stream;
  Stream<dynamic> get onMessageReaction => _messageReactionController.stream;
  Stream<dynamic> get onThemeChanged => _themeChangedController.stream;

  bool get isConnected => _socket?.connected ?? false;
  bool get shouldAllowReconnection => _shouldAllowReconnection;
  IO.Socket? get socket => _socket;
  String? get currentUserId => _currentUserId;

  String get _baseUrl {
    final baseUrl = Endpoints.baseURL;
    if (baseUrl.endsWith('/api/v1/')) {
      return baseUrl.substring(0, baseUrl.length - 8);
    }
    return baseUrl.replaceAll('/api/v1/', '');
  }

  /// Initialize network connectivity listener
  /// Auto-reconnects when network becomes available
  void _initConnectivityListener() {
    try {
      _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _handleConnectivityChange(results);
        },
        onError: (error) {
          debugPrint('⚠️ Connectivity listener error: $error');
        },
      );
    } catch (e) {
      // Handle MissingPluginException when plugin not properly loaded
      debugPrint('⚠️ Could not initialize connectivity listener: $e');
      debugPrint('⚠️ Network auto-reconnect disabled. Full rebuild required.');
    }
  }

  /// Handle network connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    debugPrint('📶 Network connectivity changed: $results (connected: $hasConnection)');

    if (hasConnection && _wasOffline) {
      // Network restored after being offline
      debugPrint('📶 Network restored, attempting socket reconnection...');
      _wasOffline = false;

      // Reset reconnect attempts since this is a fresh network connection
      _reconnectAttempts = 0;
      _isPermanentlyDisconnected = false;

      // Attempt to reconnect if we should - but only if not already connecting/connected
      if (_shouldAllowReconnection && !isConnected && !_isConnecting) {
        // Longer delay to let other connection attempts finish first
        Future.delayed(const Duration(seconds: 2), () {
          // Double-check conditions after delay
          if (!isConnected && !_isConnecting && _shouldAllowReconnection) {
            connect();
          }
        });
      }
    } else if (!hasConnection) {
      // Went offline
      debugPrint('📶 Network lost');
      _wasOffline = true;
      _safeAdd(_connectionStateController, false);
    }
  }

  // Get unique device ID with persistence
  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have a cached device ID
      final cachedDeviceId = prefs.getString('deviceId');
      if (cachedDeviceId != null && cachedDeviceId.isNotEmpty) {
        _deviceId = cachedDeviceId;
        return _deviceId!;
      }

      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'ios_default';
      } else {
        _deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Cache the device ID
      await prefs.setString('deviceId', _deviceId!);
      return _deviceId!;
    } catch (e) {
      debugPrint('❌ Error getting device ID: $e');
      _deviceId = 'default_${DateTime.now().millisecondsSinceEpoch}';
      return _deviceId!;
    }
  }

  Future<void> connect({bool forceReset = false}) async {
    // FIRST: Check if reconnection is allowed (logout check)
    if (!_shouldAllowReconnection || _isPermanentlyDisconnected) {
      debugPrint('🚫 Socket connection blocked - reconnection disabled (user logged out)');
      return;
    }

    // Prevent concurrent connection attempts
    if (_isConnecting) {
      debugPrint('⏳ Connection already in progress, skipping');
      return;
    }

    if (_socket?.connected ?? false) {
      debugPrint('✅ Socket already connected');
      return;
    }

    // Cooldown check - prevent rapid reconnection attempts (unless force reset)
    if (!forceReset && _lastConnectedAt != null) {
      final timeSinceLastConnect = DateTime.now().difference(_lastConnectedAt!);
      if (timeSinceLastConnect < _connectionCooldown) {
        debugPrint('⏳ Connection cooldown active, skipping (${timeSinceLastConnect.inMilliseconds}ms since last connect)');
        return;
      }
    }

    _isConnecting = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
        debugPrint('❌ Cannot connect socket - missing credentials');
        return;
      }

      if (!_shouldAllowReconnection) {
        debugPrint('❌ Socket reconnection disabled (logout detected)');
        return;
      }

      // Reset reconnect attempts on force reset (e.g., app resume)
      // This ensures we try fresh after coming back from background
      if (forceReset) {
        debugPrint('🔄 Force reset - clearing reconnect attempts');
        _reconnectAttempts = 0;
        _isPermanentlyDisconnected = false;
        _reconnectTimer?.cancel();
      }

      _currentUserId = userId;
      final deviceId = await _getDeviceId();

      debugPrint('🔌 Connecting socket for user: $userId (device: $deviceId)');

      // IMPORTANT: Disconnect old socket first
      if (_socket != null) {
        _socket?.clearListeners();
        _socket?.disconnect();
        _socket?.dispose();
        _socket = null;
      }

      _socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .setQuery({'userId': userId, 'deviceId': deviceId})
            .setReconnectionAttempts(
              _shouldAllowReconnection ? _maxReconnectAttempts : 0,
            )
            .setReconnectionDelay(2000) // Increased from 1000
            .setReconnectionDelayMax(10000) // Increased from 5000
            .enableReconnection()
            .setTimeout(20000)
            .setExtraHeaders({'Connection': 'keep-alive'})
            .build(),
      );

      _setupListeners();
      _socket?.connect();
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      debugPrint('✅ Socket connected');
      _reconnectAttempts = 0;
      _isPermanentlyDisconnected = false;
      _lastConnectedAt = DateTime.now();
      _safeAdd(_connectionStateController, true);
      _startHeartbeat();
    });

    // Listen for connection verification from backend
    _socket?.on('connectionVerified', (data) {
      debugPrint('✅ Connection verified by server: $data');
      _reconnectAttempts = 0;
      _isPermanentlyDisconnected = false;
    });

    _socket?.onDisconnect((reason) {
      debugPrint('❌ Socket disconnected: $reason');
      _safeAdd(_connectionStateController, false);
      _stopHeartbeat();

      if (!_shouldAllowReconnection) {
        debugPrint('🚫 Preventing reconnection - logout detected');
        return;
      }

      if (reason != 'io client disconnect') {
        // Clear cooldown so reconnection isn't blocked
        _lastConnectedAt = null;
        _scheduleReconnect();
      }
    });

    _socket?.onConnectError((err) {
      debugPrint('❌ Connection error: $err');
      _safeAdd(_connectionStateController, false);
      _scheduleReconnect();
    });

    _socket?.onError((err) {
      debugPrint('❌ Socket error: $err');
    });

    _socket?.on('ping', (_) {
      _socket?.emit('pong');
    });

    // Force disconnect from server
    _socket?.on('forceDisconnect', (data) {
      debugPrint('🚫 Force disconnected from server: ${data['reason']}');
      _handleForceDisconnect();
    });

    // Auth error
    _socket?.on('authError', (data) {
      debugPrint('🚫 Auth error: ${data['message']}');
      _handleForceDisconnect();
    });

    // Token expiring - client should refresh token
    _socket?.on('tokenExpiring', (data) {
      debugPrint('⚠️ Token expiring soon: ${data['expiresIn']}s remaining');
      // Could trigger token refresh here if needed
    });

    // Token expired - disconnect and require re-login
    _socket?.on('tokenExpired', (data) {
      debugPrint('🚫 Token expired: ${data['reason']}');
      _handleForceDisconnect();
    });

    // Message events
    _socket?.on('newMessage', (data) {
      debugPrint('📨 New message: $data');
      _safeAdd(_newMessageController, data);
    });

    _socket?.on('messageSent', (data) {
      debugPrint('📤 Message sent: $data');
      _safeAdd(_messageSentController, data);
    });

    // Voice message received (treat same as newMessage)
    _socket?.on('newVoiceMessage', (data) {
      debugPrint('🎤 New voice message: $data');
      // Extract message from the data wrapper
      final messageData = data is Map && data['message'] != null
          ? data['message']
          : data;
      _safeAdd(_newMessageController, messageData);
    });

    // Typing events
    _socket?.on('typing', (data) {
      debugPrint('⌨️ Typing event: $data');
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': true,
      });
    });

    _socket?.on('userTyping', (data) {
      debugPrint('⌨️ User typing: $data');
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': true,
      });
    });

    _socket?.on('userStoppedTyping', (data) {
      debugPrint('⌨️ User stopped typing: $data');
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': false,
      });
    });

    _socket?.on('stopTyping', (data) {
      debugPrint('⌨️ Stop typing: $data');
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': false,
      });
    });

    // Status events
    _socket?.on('bulkStatusUpdate', (data) {
      debugPrint('📊 Status update: $data');
      _safeAdd(_statusUpdateController, data);
    });

    _socket?.on('onlineUsers', (data) {
      debugPrint('👥 Online users: $data');
      _safeAdd(_statusUpdateController, {'type': 'onlineUsers', 'data': data});
    });

    _socket?.on('userStatusUpdate', (data) {
      debugPrint('📡 User status update: $data');
      _safeAdd(_statusUpdateController, {'single': data});
    });

    // Read receipt events
    _socket?.on('messageRead', (data) {
      debugPrint('👁️ Message read: $data');
      _safeAdd(_messageReadController, data);
    });

    _socket?.on('messagesRead', (data) {
      debugPrint('👁️ Messages read: $data');
      _safeAdd(_messageReadController, data);
    });

    // Message edited
    _socket?.on('messageEdited', (data) {
      debugPrint('✏️ Message edited: $data');
      _safeAdd(_newMessageController, {'type': 'edited', 'data': data});
    });

    // Message deletion
    _socket?.on('messageDeleted', (data) {
      debugPrint('🗑️ Message deleted: $data');
      _safeAdd(_newMessageController, {'type': 'deleted', 'data': data});
    });

    // Error events
    _socket?.on('messageError', (data) {
      debugPrint('❌ Message error: $data');
      _safeAdd(_messageDeliveryController, {
        'status': 'error',
        'error': data['error'],
      });
    });

    // Message reaction events (real-time reaction updates)
    _socket?.on('messageReaction', (data) {
      debugPrint('💬 Message reaction: $data');
      _safeAdd(_messageReactionController, data);
    });

    // Message pinned events (real-time pin updates)
    _socket?.on('messagePinned', (data) {
      debugPrint('📌 Message pinned: $data');
      _safeAdd(_newMessageController, {'type': 'pinned', 'data': data});
    });

    // Theme changed events (wallpaper sync between users)
    _socket?.on('themeChanged', (data) {
      debugPrint('🎨 Theme changed: $data');
      _safeAdd(_themeChangedController, data);
    });
  }

  // Safe add to stream controller (prevents adding to closed controllers)
  void _safeAdd<T>(StreamController<T> controller, T data) {
    if (!controller.isClosed) {
      controller.add(data);
    }
  }

  // Refresh connection with new token (call after token refresh)
  Future<void> refreshConnection() async {
    debugPrint('🔄 Refreshing socket connection with new token');
    _shouldAllowReconnection = true;
    _reconnectAttempts = 0;

    // Disconnect current socket
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    // Reconnect with fresh token
    await connect();
  }

  // Handle force disconnect
  void _handleForceDisconnect() {
    _shouldAllowReconnection = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _safeAdd(_connectionStateController, false);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Send keepalive ping every 25 seconds to prevent server timeout
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_socket?.connected ?? false) {
        // Send client-side keepalive ping (silent - no debug log to reduce noise)
        _socket?.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      } else {
        timer.cancel();
        // Don't schedule reconnect here - socket library handles it automatically
        // This prevents duplicate reconnection attempts
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  void _scheduleReconnect() {
    if (!_shouldAllowReconnection) {
      debugPrint('🚫 Reconnection disabled');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached - waiting for app resume or network change');
      _isPermanentlyDisconnected = true;
      // Don't schedule more reconnects - wait for external trigger (app resume, network change)
      return;
    }

    _reconnectTimer?.cancel();

    final delay = Duration(
      milliseconds:
          1000 * (1 << _reconnectAttempts.clamp(0, 6)), // Cap at 64 seconds
    );

    debugPrint(
      '🔄 Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)',
    );

    _reconnectTimer = Timer(delay, () {
      // Double-check flag before connecting (might have changed during delay)
      if (!_shouldAllowReconnection || _isPermanentlyDisconnected) {
        debugPrint('🚫 Reconnect timer fired but reconnection is disabled - aborting');
        return;
      }
      _reconnectAttempts++;
      connect();
    });
  }

  /// Force reconnect - resets all retry counters and attempts fresh connection
  /// Use this when app resumes from background or user manually requests reconnection
  Future<void> forceReconnect() async {
    debugPrint('🔄 Force reconnecting socket...');
    _shouldAllowReconnection = true;
    _reconnectAttempts = 0;
    _isPermanentlyDisconnected = false;
    _reconnectTimer?.cancel();

    // Disconnect existing socket cleanly
    if (_socket != null) {
      _socket?.clearListeners();
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }

    await connect(forceReset: true);
  }

  // Send message with acknowledgment (race condition fixed)
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    if (!isConnected) {
      return {'status': 'error', 'error': 'Not connected to server'};
    }

    final completer = Completer<Map<String, dynamic>>();

    // Use timer for timeout instead of future.timeout to avoid race condition
    Timer? timeoutTimer;

    try {
      // Set up timeout timer
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete({'status': 'error', 'error': 'Request timeout'});
        }
      });

      _socket?.emitWithAck(
        'sendMessage',
        {'receiver': receiverId, 'message': message},
        ack: (response) {
          // Cancel timeout timer on ack
          timeoutTimer?.cancel();

          if (!completer.isCompleted) {
            if (response != null) {
              completer.complete(Map<String, dynamic>.from(response));
            } else {
              completer.complete({
                'status': 'error',
                'error': 'No response from server',
              });
            }
          }
        },
      );

      return await completer.future;
    } catch (e) {
      // Cancel timeout timer on exception
      timeoutTimer?.cancel();

      if (!completer.isCompleted) {
        completer.complete({'status': 'error', 'error': e.toString()});
      }
      return completer.future;
    }
  }

  void emit(String event, dynamic data) {
    if (_socket?.connected ?? false) {
      _socket?.emit(event, data);
      debugPrint('📡 Emitted $event: $data');
    } else {
      debugPrint('⚠️ Cannot emit $event - socket not connected');
    }
  }

  void requestStatusUpdates(List<String> userIds) {
    if (userIds.isEmpty) return;

    debugPrint('📊 Requesting status for ${userIds.length} users');
    emit('requestStatusUpdates', {'userIds': userIds});
  }

  Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    if (!isConnected) {
      debugPrint('⚠️ Cannot get user status - socket not connected');
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();

    // Use timer for timeout instead of future.timeout to avoid race condition
    Timer? timeoutTimer;

    try {
      timeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          debugPrint('⏰ Get user status timeout');
          completer.complete(null);
        }
      });

      _socket?.emitWithAck(
        'getUserStatus',
        {'userId': userId},
        ack: (response) {
          timeoutTimer?.cancel();

          if (!completer.isCompleted) {
            if (response != null && response is Map) {
              completer.complete(Map<String, dynamic>.from(response));
            } else {
              completer.complete(null);
            }
          }
        },
      );

      return await completer.future;
    } catch (e) {
      timeoutTimer?.cancel();
      debugPrint('❌ Error getting user status: $e');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return null;
    }
  }

  void markAsRead(String chatPartnerId, String currentUserId) {
    emit('markAsRead', {
      'senderId': chatPartnerId,
      'receiverId': currentUserId,
    });
  }

  void sendTypingIndicator(String receiverId, bool isTyping) {
    if (isTyping) {
      emit('typing', {'receiver': receiverId});
    } else {
      emit('stopTyping', {'receiver': receiverId});
    }
  }

  void disableReconnection() {
    debugPrint('🚫 Disabling socket reconnection (logout)');
    _shouldAllowReconnection = false;
    _isPermanentlyDisconnected = true;
    _isConnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void enableReconnection() {
    debugPrint('✅ Enabling socket reconnection');
    _shouldAllowReconnection = true;
    _isPermanentlyDisconnected = false;
    _reconnectAttempts = 0;
  }

  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting socket completely');

    // 1. FIRST: Disable all reconnection flags
    _shouldAllowReconnection = false;
    _isPermanentlyDisconnected = true;
    _isConnecting = false;

    // 2. Cancel all timers immediately
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    // 3. Send logout event if connected
    if (_socket?.connected ?? false) {
      try {
        _socket?.emit('logout', {});
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('⚠️ Error sending logout event: $e');
      }
    }

    // 4. Clear all listeners to prevent callbacks from triggering reconnection
    try {
      _socket?.clearListeners();
    } catch (e) {
      debugPrint('⚠️ Error clearing listeners: $e');
    }

    // 5. Disconnect and destroy socket completely
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket?.destroy();
    } catch (e) {
      debugPrint('⚠️ Error disposing socket: $e');
    }

    _socket = null;
    _currentUserId = null;
    _reconnectAttempts = 0;

    _safeAdd(_connectionStateController, false);
    debugPrint('✅ Socket fully disconnected - reconnection disabled');
  }

  Future<void> reconnect() async {
    await disconnect();
    _shouldAllowReconnection = true;
    _isPermanentlyDisconnected = false;
    await connect(forceReset: true);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _connectivitySubscription?.cancel();
    _newMessageController.close();
    _messageSentController.close();
    _typingController.close();
    _statusUpdateController.close();
    _messageReadController.close();
    _connectionStateController.close();
    _messageDeliveryController.close();
    _messageReactionController.close();
    disconnect();
  }
}
