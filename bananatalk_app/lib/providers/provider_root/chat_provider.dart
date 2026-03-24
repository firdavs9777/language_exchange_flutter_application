import 'package:bananatalk_app/providers/provider_models/chat_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatProvider = ChangeNotifierProvider<ChatNotifier>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends ChangeNotifier {
  IO.Socket? _socket;
  List<ChatMessage> _messages = [];
  bool _isConnected = false;

  List<ChatMessage> get messages => _messages;

  ChatNotifier() {
    _initSocket();
  }

  void _initSocket() {
    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket?.onConnect((_) {
      _isConnected = true;
    });

    _socket?.on('initialMessages', (data) {
      _messages = List<Map<String, dynamic>>.from(data)
          .map((messageData) => ChatMessage.fromJson(messageData))
          .toList();
      notifyListeners();
    });

    _socket?.on('receiveMessage', (data) {
      _messages.add(ChatMessage.fromJson(data));
      notifyListeners();
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
    });

    _socket?.onError((error) {
      // Handle error scenarios here
    });

    _socket?.connect();
  }

  void sendMessage(String sender, String message) {
    if (_isConnected) {
      final newMessage = ChatMessage(
        sender: sender,
        message: message,
        timestamp: DateTime.now(),
        isSentByMe: true,
      );
      _socket?.emit('sendMessage', newMessage.toJson());
      _messages.add(newMessage);
      notifyListeners();
    } else {
      // Handle case when socket is not connected
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}
