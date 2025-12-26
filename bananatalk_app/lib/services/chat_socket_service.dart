import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IO.Socket? _socket;
  String? _currentUserId;
  String? _deviceId;
  bool _shouldAllowReconnection = true;
  
  // Reconnection strategy
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  // Stream controllers for events
  final _newMessageController = StreamController<dynamic>.broadcast();
  final _messageSentController = StreamController<dynamic>.broadcast();
  final _typingController = StreamController<dynamic>.broadcast();
  final _statusUpdateController = StreamController<dynamic>.broadcast();
  final _messageReadController = StreamController<dynamic>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _messageDeliveryController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<dynamic> get onNewMessage => _newMessageController.stream;
  Stream<dynamic> get onMessageSent => _messageSentController.stream;
  Stream<dynamic> get onTyping => _typingController.stream;
  Stream<dynamic> get onStatusUpdate => _statusUpdateController.stream;
  Stream<dynamic> get onMessageRead => _messageReadController.stream;
  Stream<bool> get onConnectionStateChange => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivery => _messageDeliveryController.stream;

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

  // Get unique device ID
  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Unique Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'ios_default';
      } else {
        _deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      return _deviceId!;
    } catch (e) {
      print('❌ Error getting device ID: $e');
      _deviceId = 'default_${DateTime.now().millisecondsSinceEpoch}';
      return _deviceId!;
    }
  }

  Future<void> connect() async {
    if (_socket?.connected ?? false) {
      print('✅ Socket already connected');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      print('❌ Cannot connect socket - missing credentials');
      return;
    }

    if (!_shouldAllowReconnection) {
      print('❌ Socket reconnection disabled (logout detected)');
      return;
    }

    _currentUserId = userId;
    final deviceId = await _getDeviceId();

    print('🔌 Connecting socket for user: $userId (device: $deviceId)');

    try {
      _socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .setQuery({
              'userId': userId,
              'deviceId': deviceId,
            })
            .setReconnectionAttempts(_shouldAllowReconnection ? _maxReconnectAttempts : 0)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .enableReconnection()
            .setTimeout(10000)
            .build(),
      );

      _setupListeners();
      _socket?.connect();
    } catch (e) {
      print('❌ Socket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      print('✅ Socket connected');
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      _startHeartbeat();
    });

    _socket?.onDisconnect((reason) {
      print('❌ Socket disconnected: $reason');
      _connectionStateController.add(false);
      _stopHeartbeat();
      
      // Don't auto-reconnect if logout occurred
      if (!_shouldAllowReconnection) {
        print('🚫 Preventing reconnection - logout detected');
        return;
      }
      
      // Schedule reconnect for unexpected disconnections
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    _socket?.onConnectError((err) {
      print('❌ Connection error: $err');
      _connectionStateController.add(false);
      _scheduleReconnect();
    });

    _socket?.onError((err) {
      print('❌ Socket error: $err');
    });

    // Heartbeat
    _socket?.on('ping', (_) {
      _socket?.emit('pong');
    });

    // Force disconnect from server
    _socket?.on('forceDisconnect', (data) {
      print('🚫 Force disconnected from server: ${data['reason']}');
      _shouldAllowReconnection = false;
      _socket?.disconnect();
    });

    // Auth error
    _socket?.on('authError', (data) {
      print('🚫 Auth error: ${data['message']}');
      _shouldAllowReconnection = false;
      _socket?.disconnect();
    });

    // Message events
    _socket?.on('newMessage', (data) {
      print('📨 New message: $data');
      _newMessageController.add(data);
    });

    _socket?.on('messageSent', (data) {
      print('📤 Message sent: $data');
      _messageSentController.add(data);
    });

    // Typing events
    _socket?.on('typing', (data) {
      print('⌨️ Typing event: $data');
      _typingController.add(data);
    });

    _socket?.on('userTyping', (data) {
      print('⌨️ User typing: $data');
      _typingController.add(data);
    });

    _socket?.on('userStoppedTyping', (data) {
      print('⌨️ User stopped typing: $data');
      _typingController.add(data);
    });

    // Status events
    _socket?.on('bulkStatusUpdate', (data) {
      print('📊 Status update: $data');
      _statusUpdateController.add(data);
    });

    _socket?.on('onlineUsers', (data) {
      print('👥 Online users: $data');
      _statusUpdateController.add(data);
    });

    _socket?.on('userStatusUpdate', (data) {
      print('📡 User status update: $data');
      _statusUpdateController.add({'single': data});
    });

    // Read receipt events
    _socket?.on('messageRead', (data) {
      print('👁️ Message read: $data');
      _messageReadController.add(data);
    });

    _socket?.on('messagesRead', (data) {
      print('👁️ Messages read: $data');
      _messageReadController.add(data);
    });

    // Message deletion
    _socket?.on('messageDeleted', (data) {
      print('🗑️ Message deleted: $data');
      _newMessageController.add({'type': 'deleted', 'data': data});
    });

    // Error events
    _socket?.on('messageError', (data) {
      print('❌ Message error: $data');
      _messageDeliveryController.add({
        'status': 'error',
        'error': data['error'],
      });
    });
  }

  // Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 25), (timer) {
      if (_socket?.connected ?? false) {
        // Heartbeat is handled by server's ping
      } else {
        timer.cancel();
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  // Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (!_shouldAllowReconnection) {
      print('🚫 Reconnection disabled');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    
    final delay = Duration(
      milliseconds: 1000 * (1 << _reconnectAttempts), // Exponential backoff
    );
    
    print('🔄 Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  // Send message with acknowledgment
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    if (!isConnected) {
      return {
        'status': 'error',
        'error': 'Not connected to server',
      };
    }

    final completer = Completer<Map<String, dynamic>>();

    try {
      _socket?.emitWithAck('sendMessage', {
        'receiver': receiverId,
        'message': message,
      }, ack: (response) {
        if (response != null) {
          completer.complete(Map<String, dynamic>.from(response));
        } else {
          completer.complete({
            'status': 'error',
            'error': 'No response from server',
          });
        }
      });

      // Timeout after 10 seconds
      return await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () => {
          'status': 'error',
          'error': 'Request timeout',
        },
      );
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  void emit(String event, dynamic data) {
    if (_socket?.connected ?? false) {
      _socket?.emit(event, data);
      print('📡 Emitted $event: $data');
    } else {
      print('⚠️ Cannot emit $event - socket not connected');
    }
  }

  void requestStatusUpdates(List<String> userIds) {
    emit('requestStatusUpdates', {'userIds': userIds});
  }

  void markAsRead(String senderId, String receiverId) {
    emit('markAsRead', {'senderId': senderId, 'receiverId': receiverId});
  }

  void sendTypingIndicator(String receiverId, bool isTyping) {
    if (isTyping) {
      emit('typing', {'receiver': receiverId});
    } else {
      emit('stopTyping', {'receiver': receiverId});
    }
  }

  void disableReconnection() {
    print('🚫 Disabling socket reconnection');
    _shouldAllowReconnection = false;
    _reconnectTimer?.cancel();
  }

  void enableReconnection() {
    print('✅ Enabling socket reconnection');
    _shouldAllowReconnection = true;
    _reconnectAttempts = 0;
  }

  Future<void> disconnect() async {
    print('🔌 Disconnecting socket');
    _shouldAllowReconnection = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    
    // Emit logout event to server
    if (_socket?.connected ?? false) {
      _socket?.emit('logout', {});
      await Future.delayed(Duration(milliseconds: 500)); // Wait for server to process
    }
    
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    _deviceId = null;
    _reconnectAttempts = 0;
    _connectionStateController.add(false);
  }

  Future<void> reconnect() async {
    await disconnect();
    _shouldAllowReconnection = true;
    await connect();
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
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
