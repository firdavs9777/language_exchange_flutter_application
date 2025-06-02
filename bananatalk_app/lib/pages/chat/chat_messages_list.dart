import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'chat_message_bubble.dart';
import 'chat_typing_indicator.dart';
import 'chat_error_widget.dart';
import 'chat_empty_state.dart';

class ChatMessagesList extends StatelessWidget {
  final bool isLoading;
  final String error;
  final List<Message> messages;
  final String? currentUserId;
  final String otherUserName;
  final String? otherUserPicture;
  final bool otherUserTyping;
  final ScrollController scrollController;
  final VoidCallback onRetry;

  const ChatMessagesList({
    Key? key,
    required this.isLoading,
    required this.error,
    required this.messages,
    required this.currentUserId,
    required this.otherUserName,
    this.otherUserPicture,
    required this.otherUserTyping,
    required this.scrollController,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return ChatErrorWidget(error: error, onRetry: onRetry);
    }

    if (messages.isEmpty) {
      return ChatEmptyState(userName: otherUserName);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.sender.id == currentUserId;
              return ChatMessageBubble(
                message: message,
                isMe: isMe,
                otherUserName: otherUserName,
                otherUserPicture: otherUserPicture,
              );
            },
          ),
        ),
        if (otherUserTyping)
          ChatTypingIndicator(
            userName: otherUserName,
            userPicture: otherUserPicture,
          ),
      ],
    );
  }
}
