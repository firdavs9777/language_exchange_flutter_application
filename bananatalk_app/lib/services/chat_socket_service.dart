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
  final _messageCorrectionController = StreamController<dynamic>.broadcast();
  final _themeChangedController = StreamController<dynamic>.broadcast();

  // Voice room stream controllers
  final _voiceRoomParticipantJoinedController = StreamController<dynamic>.broadcast();
  final _voiceRoomParticipantLeftController = StreamController<dynamic>.broadcast();
  final _voiceRoomOfferController = StreamController<dynamic>.broadcast();
  final _voiceRoomAnswerController = StreamController<dynamic>.broadcast();
  final _voiceRoomIceCandidateController = StreamController<dynamic>.broadcast();
  final _voiceRoomMuteController = StreamController<dynamic>.broadcast();
  final _voiceRoomHandRaisedController = StreamController<dynamic>.broadcast();
  final _voiceRoomChatController = StreamController<dynamic>.broadcast();
  final _voiceRoomEndedController = StreamController<dynamic>.broadcast();
  final _voiceRoomKickedController = StreamController<dynamic>.broadcast();

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
  Stream<dynamic> get onMessageCorrection => _messageCorrectionController.stream;
  Stream<dynamic> get onThemeChanged => _themeChangedController.stream;

  // Voice room stream getters
  Stream<dynamic> get onVoiceRoomParticipantJoined => _voiceRoomParticipantJoinedController.stream;
  Stream<dynamic> get onVoiceRoomParticipantLeft => _voiceRoomParticipantLeftController.stream;
  Stream<dynamic> get onVoiceRoomOffer => _voiceRoomOfferController.stream;
  Stream<dynamic> get onVoiceRoomAnswer => _voiceRoomAnswerController.stream;
  Stream<dynamic> get onVoiceRoomIceCandidate => _voiceRoomIceCandidateController.stream;
  Stream<dynamic> get onVoiceRoomMute => _voiceRoomMuteController.stream;
  Stream<dynamic> get onVoiceRoomHandRaised => _voiceRoomHandRaisedController.stream;
  Stream<dynamic> get onVoiceRoomChat => _voiceRoomChatController.stream;
  Stream<dynamic> get onVoiceRoomEnded => _voiceRoomEndedController.stream;
  Stream<dynamic> get onVoiceRoomKicked => _voiceRoomKickedController.stream;

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
        },
      );
    } catch (e) {
      // Handle MissingPluginException when plugin not properly loaded
    }
  }

  /// Handle network connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);


    if (hasConnection && _wasOffline) {
      // Network restored after being offline
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
      _deviceId = 'default_${DateTime.now().millisecondsSinceEpoch}';
      return _deviceId!;
    }
  }

  Future<void> connect({bool forceReset = false}) async {
    // FIRST: Check if reconnection is allowed (logout check)
    if (!_shouldAllowReconnection || _isPermanentlyDisconnected) {
      return;
    }

    // Prevent concurrent connection attempts
    if (_isConnecting) {
      return;
    }

    if (_socket?.connected ?? false) {
      return;
    }

    // Cooldown check - prevent rapid reconnection attempts (unless force reset)
    if (!forceReset && _lastConnectedAt != null) {
      final timeSinceLastConnect = DateTime.now().difference(_lastConnectedAt!);
      if (timeSinceLastConnect < _connectionCooldown) {
        return;
      }
    }

    _isConnecting = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
        return;
      }

      if (!_shouldAllowReconnection) {
        return;
      }

      // Reset reconnect attempts on force reset (e.g., app resume)
      // This ensures we try fresh after coming back from background
      if (forceReset) {
        _reconnectAttempts = 0;
        _isPermanentlyDisconnected = false;
        _reconnectTimer?.cancel();
      }

      _currentUserId = userId;
      final deviceId = await _getDeviceId();


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
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      _reconnectAttempts = 0;
      _isPermanentlyDisconnected = false;
      _lastConnectedAt = DateTime.now();
      _safeAdd(_connectionStateController, true);
      _startHeartbeat();
    });

    // Listen for connection verification from backend
    _socket?.on('connectionVerified', (data) {
      _reconnectAttempts = 0;
      _isPermanentlyDisconnected = false;
    });

    _socket?.onDisconnect((reason) {
      _safeAdd(_connectionStateController, false);
      _stopHeartbeat();

      if (!_shouldAllowReconnection) {
        return;
      }

      if (reason != 'io client disconnect') {
        // Clear cooldown so reconnection isn't blocked
        _lastConnectedAt = null;
        _scheduleReconnect();
      }
    });

    _socket?.onConnectError((err) {
      _safeAdd(_connectionStateController, false);
      _scheduleReconnect();
    });

    _socket?.onError((err) {
    });

    _socket?.on('ping', (_) {
      _socket?.emit('pong');
    });

    // Force disconnect from server
    _socket?.on('forceDisconnect', (data) {
      _handleForceDisconnect();
    });

    // Auth error
    _socket?.on('authError', (data) {
      _handleForceDisconnect();
    });

    // Token expiring - client should refresh token
    _socket?.on('tokenExpiring', (data) {
      // Could trigger token refresh here if needed
    });

    // Token expired - disconnect and require re-login
    _socket?.on('tokenExpired', (data) {
      _handleForceDisconnect();
    });

    // Message events
    _socket?.on('newMessage', (data) {
      _safeAdd(_newMessageController, data);
    });

    _socket?.on('messageSent', (data) {
      _safeAdd(_messageSentController, data);
    });

    // Voice message received (treat same as newMessage)
    _socket?.on('newVoiceMessage', (data) {
      // Extract message from the data wrapper
      final messageData = data is Map && data['message'] != null
          ? data['message']
          : data;
      _safeAdd(_newMessageController, messageData);
    });

    // Typing events
    _socket?.on('typing', (data) {
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': true,
      });
    });

    _socket?.on('userTyping', (data) {
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': true,
      });
    });

    _socket?.on('userStoppedTyping', (data) {
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': false,
      });
    });

    _socket?.on('stopTyping', (data) {
      _safeAdd(_typingController, {
        'userId': data['userId'] ?? data['user'],
        'isTyping': false,
      });
    });

    // Status events
    _socket?.on('bulkStatusUpdate', (data) {
      _safeAdd(_statusUpdateController, data);
    });

    _socket?.on('onlineUsers', (data) {
      _safeAdd(_statusUpdateController, {'type': 'onlineUsers', 'data': data});
    });

    _socket?.on('userStatusUpdate', (data) {
      _safeAdd(_statusUpdateController, {'single': data});
    });

    // Read receipt events
    _socket?.on('messageRead', (data) {
      _safeAdd(_messageReadController, data);
    });

    _socket?.on('messagesRead', (data) {
      _safeAdd(_messageReadController, data);
    });

    // Message edited
    _socket?.on('messageEdited', (data) {
      _safeAdd(_newMessageController, {'type': 'edited', 'data': data});
    });

    // Message deletion
    _socket?.on('messageDeleted', (data) {
      _safeAdd(_newMessageController, {'type': 'deleted', 'data': data});
    });

    // Error events
    _socket?.on('messageError', (data) {
      _safeAdd(_messageDeliveryController, {
        'status': 'error',
        'error': data['error'],
      });
    });

    // Message reaction events (real-time reaction updates)
    _socket?.on('messageReaction', (data) {
      _safeAdd(_messageReactionController, data);
    });

    // Message correction events (Tandem-style corrections)
    _socket?.on('messageCorrection', (data) {
      _safeAdd(_messageCorrectionController, data);
    });

    // Message pinned events (real-time pin updates)
    _socket?.on('messagePinned', (data) {
      _safeAdd(_newMessageController, {'type': 'pinned', 'data': data});
    });

    // Theme changed events (wallpaper sync between users)
    _socket?.on('themeChanged', (data) {
      _safeAdd(_themeChangedController, data);
    });

    // ============ Voice Room Events ============

    // Participant joined the room
    _socket?.on('voiceroom:participant-joined', (data) {
      _safeAdd(_voiceRoomParticipantJoinedController, data);
    });

    // Participant left the room
    _socket?.on('voiceroom:participant-left', (data) {
      _safeAdd(_voiceRoomParticipantLeftController, data);
    });

    // WebRTC offer from peer
    _socket?.on('voiceroom:offer', (data) {
      _safeAdd(_voiceRoomOfferController, data);
    });

    // WebRTC answer from peer
    _socket?.on('voiceroom:answer', (data) {
      _safeAdd(_voiceRoomAnswerController, data);
    });

    // ICE candidate from peer
    _socket?.on('voiceroom:ice-candidate', (data) {
      _safeAdd(_voiceRoomIceCandidateController, data);
    });

    // Participant mute state changed
    _socket?.on('voiceroom:mute', (data) {
      _safeAdd(_voiceRoomMuteController, data);
    });

    // Participant raised/lowered hand
    _socket?.on('voiceroom:hand-raised', (data) {
      _safeAdd(_voiceRoomHandRaisedController, data);
    });

    // Room chat message
    _socket?.on('voiceroom:chat', (data) {
      _safeAdd(_voiceRoomChatController, data);
    });

    // Room ended by host
    _socket?.on('voiceroom:ended', (data) {
      _safeAdd(_voiceRoomEndedController, data);
    });

    // Participant kicked from room
    _socket?.on('voiceroom:kicked', (data) {
      _safeAdd(_voiceRoomKickedController, data);
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
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _isPermanentlyDisconnected = true;
      // Don't schedule more reconnects - wait for external trigger (app resume, network change)
      return;
    }

    _reconnectTimer?.cancel();

    final delay = Duration(
      milliseconds:
          1000 * (1 << _reconnectAttempts.clamp(0, 6)), // Cap at 64 seconds
    );


    _reconnectTimer = Timer(delay, () {
      // Double-check flag before connecting (might have changed during delay)
      if (!_shouldAllowReconnection || _isPermanentlyDisconnected) {
        return;
      }
      _reconnectAttempts++;
      connect();
    });
  }

  /// Force reconnect - resets all retry counters and attempts fresh connection
  /// Use this when app resumes from background or user manually requests reconnection
  Future<void> forceReconnect() async {
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
    String? messageType,
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
        {
          'receiver': receiverId,
          'message': message,
          if (messageType != null) 'messageType': messageType,
        },
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
    } else {
    }
  }

  void requestStatusUpdates(List<String> userIds) {
    if (userIds.isEmpty) return;

    emit('requestStatusUpdates', {'userIds': userIds});
  }

  Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    if (!isConnected) {
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();

    // Use timer for timeout instead of future.timeout to avoid race condition
    Timer? timeoutTimer;

    try {
      timeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
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
    _shouldAllowReconnection = false;
    _isPermanentlyDisconnected = true;
    _isConnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void enableReconnection() {
    _shouldAllowReconnection = true;
    _isPermanentlyDisconnected = false;
    _reconnectAttempts = 0;
  }

  Future<void> disconnect() async {

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
      }
    }

    // 4. Clear all listeners to prevent callbacks from triggering reconnection
    try {
      _socket?.clearListeners();
    } catch (e) {
    }

    // 5. Disconnect and destroy socket completely
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket?.destroy();
    } catch (e) {
    }

    _socket = null;
    _currentUserId = null;
    _reconnectAttempts = 0;

    _safeAdd(_connectionStateController, false);
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
    _messageCorrectionController.close();
    disconnect();
  }
}
