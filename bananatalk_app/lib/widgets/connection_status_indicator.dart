import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'dart:async';

class ConnectionStatusIndicator extends ConsumerStatefulWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  ConsumerState<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState
    extends ConsumerState<ConnectionStatusIndicator> {
  final _chatSocketService = ChatSocketService();
  StreamSubscription? _connectionSub;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = _chatSocketService.isConnected;
    
    _connectionSub = _chatSocketService.onConnectionStateChange.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Reconnecting...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

