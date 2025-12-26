import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Global socket service to manage socket connections and cleanup
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Keep track of all active socket instances
  final List<IO.Socket?> _activeSockets = [];
  
  // Flag to prevent auto-reconnection after logout
  bool _shouldAllowReconnection = true;

  /// Register a socket instance
  void registerSocket(IO.Socket? socket) {
    if (socket != null && !_activeSockets.contains(socket)) {
      _activeSockets.add(socket);
      print('🔌 Socket registered. Total active: ${_activeSockets.length}');
    }
  }

  /// Unregister a socket instance
  void unregisterSocket(IO.Socket? socket) {
    _activeSockets.remove(socket);
    print('🔌 Socket unregistered. Total active: ${_activeSockets.length}');
  }

  /// Disconnect all active sockets (called on logout)
  /// Sends explicit logout event to backend before disconnecting
  Future<void> disconnectAll() async {
    print('🔌 Disconnecting all sockets (${_activeSockets.length} active)');
    
    // Prevent auto-reconnection after logout
    _shouldAllowReconnection = false;
    print('🚫 Auto-reconnection disabled');
    
    // Send explicit logout event to each connected socket BEFORE disconnecting
    for (var socket in _activeSockets) {
      try {
        if (socket != null && socket.connected) {
          print('👋 Sending logout event to socket ${socket.id}');
          
          // Emit logout event with acknowledgment
          socket.emitWithAck('logout', {}, ack: (data) {
            print('✅ Logout acknowledged: $data');
          });
          
          // Wait briefly to ensure event is sent
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Now disconnect
          socket.disconnect();
          socket.dispose();
          print('✅ Socket ${socket.id} disconnected');
        }
      } catch (e) {
        print('❌ Error disconnecting socket: $e');
        // Force disconnect even if error
        try {
          socket?.disconnect();
          socket?.dispose();
        } catch (_) {}
      }
    }
    
    _activeSockets.clear();
    print('✅ All sockets disconnected and cleared');
  }
  
  /// Re-enable reconnection (called on new login)
  void enableReconnection() {
    _shouldAllowReconnection = true;
    print('✅ Auto-reconnection re-enabled');
  }
  
  /// Check if reconnection is allowed
  bool get shouldAllowReconnection => _shouldAllowReconnection;

  /// Check if there are any active connections
  bool get hasActiveConnections => _activeSockets.any((s) => s?.connected == true);

  /// Get count of active connections
  int get activeConnectionCount => _activeSockets.where((s) => s?.connected == true).length;
}

