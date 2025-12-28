// Use the StreamBuilder approach
import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final chatSocketService = ChatSocketService();
    
    return StreamBuilder<bool>(
      stream: chatSocketService.onConnectionStateChange,
      initialData: chatSocketService.isConnected,
      builder: (context, snapshot) {
        // Don't show if data hasn't loaded yet
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final isConnected = snapshot.data ?? true;
        
        if (isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          color: Colors.orange,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
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
      },
    );
  }
}