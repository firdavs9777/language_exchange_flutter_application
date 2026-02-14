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

  // Reconnection strategy - increased for better reliability
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 15; // Increased from 5 to 15 (~10 min total)
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isPermanentlyDisconnected = false; // Track if we gave up

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

  // Getters for streams
  Stream<dynamic> get onNewMessage => _newMessageController.stream;
  Stream<dynamic> get onMessageSent => _messageSentController.stream;
  Stream<dynamic> get onTyping => _typingController.stream;
  Stream<dynamic> get onStatusUpdate => _statusUpdateController.stream;
  Stream<dynamic> get onMessageRead => _messageReadController.stream;
  Stream<bool> get onConnectionStateChange => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivery =>
      _messageDeliveryController.stream;

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

      // Attempt to reconnect if we should
      if (_shouldAllowReconnection && !isConnected) {
        // Small delay to ensure network is stable
        Future.delayed(const Duration(milliseconds: 500), () {
          connect();
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

  Future<void> connect() async {
    if (_socket?.connected ?? false) {
      debugPrint('✅ Socket already connected');
      return;
    }

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

    _currentUserId = userId;
    final deviceId = await _getDeviceId();

    debugPrint('🔌 Connecting socket for user: $userId (device: $deviceId)');

    try {
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
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .enableReconnection()
            .setTimeout(20000)  // Increased connection timeout
            .setExtraHeaders({'Connection': 'keep-alive'})
            .build(),
      );

      _setupListeners();
      _socket?.connect();
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      debugPrint('✅ Socket connected');
      _reconnectAttempts = 0;
      _safeAdd(_connectionStateController, true);
      _startHeartbeat();
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

    // Message events
    _socket?.on('newMessage', (data) {
      debugPrint('📨 New message: $data');
      _safeAdd(_newMessageController, data);
    });

    _socket?.on('messageSent', (data) {
      debugPrint('📤 Message sent: $data');
      _safeAdd(_messageSentController, data);
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
    // More frequent heartbeat to prevent server-side timeout
    _heartbeatTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_socket?.connected ?? false) {
        // Send client-side keepalive ping
        _socket?.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      } else {
        timer.cancel();
        // Socket disconnected, try to reconnect
        if (_shouldAllowReconnection) {
          _scheduleReconnect();
        }
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
      debugPrint('❌ Max reconnection attempts reached');
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
      _reconnectAttempts++;
      connect();
    });
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
    debugPrint('🚫 Disabling socket reconnection');
    _shouldAllowReconnection = false;
    _reconnectTimer?.cancel();
  }

  void enableReconnection() {
    debugPrint('✅ Enabling socket reconnection');
    _shouldAllowReconnection = true;
    _reconnectAttempts = 0;
  }

  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting socket');
    _shouldAllowReconnection = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_socket?.connected ?? false) {
      _socket?.emit('logout', {});
      await Future.delayed(Duration(milliseconds: 500));
    }

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    // Don't clear _deviceId - keep it for next connection
    _reconnectAttempts = 0;
    _safeAdd(_connectionStateController, false);
  }

  Future<void> reconnect() async {
    await disconnect();
    _shouldAllowReconnection = true;
    await connect();
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
    disconnect();
  }
}
