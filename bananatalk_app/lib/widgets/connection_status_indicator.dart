// Use the StreamBuilder approach with debouncing
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';

/// Connection status indicator with debouncing
/// Only shows "Reconnecting" after 3 seconds of disconnection
/// to avoid flickering during brief network hiccups
class ConnectionStatusIndicator extends StatefulWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  State<ConnectionStatusIndicator> createState() => _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator> {
  final ChatSocketService _chatSocketService = ChatSocketService();
  StreamSubscription<bool>? _connectionSubscription;

  bool _showBanner = false;
  Timer? _debounceTimer;

  // How long to wait before showing the banner (avoids flickering)
  static const _debounceDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _connectionSubscription = _chatSocketService.onConnectionStateChange.listen(_onConnectionChange);
    // Check initial state
    if (!_chatSocketService.isConnected) {
      _startDebounceTimer();
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onConnectionChange(bool isConnected) {
    if (isConnected) {
      // Connected - hide banner immediately
      _debounceTimer?.cancel();
      if (_showBanner) {
        setState(() => _showBanner = false);
      }
    } else {
      // Disconnected - wait before showing banner
      _startDebounceTimer();
    }
  }

  void _startDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      // Only show banner if still disconnected after delay
      if (!_chatSocketService.isConnected && mounted) {
        setState(() => _showBanner = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: Colors.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Reconnecting to chat...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}