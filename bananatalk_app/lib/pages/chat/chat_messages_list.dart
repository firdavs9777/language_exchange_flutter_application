import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
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
  final bool isSelectionMode;
  final Set<String> selectedMessageIds;
  final Function(Message, bool)? onSelectionChanged;
  final Function(Message)? onDelete;
  final Function(Message)? onEdit;
  final Function(Message)? onReply;
  final Function(String messageId)? onReplyTap; // Scroll to replied message
  final Function(Message)? onPin;
  final Function(Message)? onUnpin;
  final Function(Message)? onForward;
  final Function(Message)? onRetryMessage; // Retry sending failed message
  final Function(Message)? onDeleteFailedMessage; // Delete failed message
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final Widget? headerWidget; // User info card shown at top when scrolled up
  final VoidCallback? onSendWave; // Send wave emoji to start chatting

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
    this.isSelectionMode = false,
    this.selectedMessageIds = const {},
    this.onSelectionChanged,
    this.onDelete,
    this.onEdit,
    this.onReply,
    this.onReplyTap,
    this.onPin,
    this.onUnpin,
    this.onForward,
    this.onRetryMessage,
    this.onDeleteFailedMessage,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.headerWidget,
    this.onSendWave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return ChatErrorWidget(error: error, onRetry: onRetry);
    }

    // Always show header when provided (user info at top of chat)
    final hasHeader = headerWidget != null;

    // When messages is empty but we have a header, show the header with empty state
    if (messages.isEmpty) {
      if (hasHeader) {
        return ListView(
          controller: scrollController,
          children: [
            // User info header at top
            headerWidget!,
            // Say Hi prompt - tappable to send wave
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSendWave,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppColors.primary.withValues(alpha: 0.2),
                    highlightColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '👋',
                            style: TextStyle(fontSize: 56),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to say hi!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send a wave to start chatting',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return ChatEmptyState(userName: otherUserName, onSendWave: onSendWave);
    }

    // Build list with header at top, then messages chronologically (oldest to newest)
    // Calculate indices: header at 0, then messages, then loading indicator at end
    final headerOffset = hasHeader ? 1 : 0;
    final totalItems = headerOffset + messages.length + (isLoadingMore ? 1 : 0);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            reverse: false, // Normal order - header at top, newest at bottom
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // Header at index 0
              if (hasHeader && index == 0) {
                return headerWidget!;
              }

              // Loading indicator at the end (for loading older messages)
              if (isLoadingMore && index == totalItems - 1) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              // Get message - adjust index for header offset
              final messageIndex = index - headerOffset;
              if (messageIndex < 0 || messageIndex >= messages.length) {
                return const SizedBox.shrink(); // Safety check
              }
              final message = messages[messageIndex];
              final isMe = message.sender.id == currentUserId;
              return ChatMessageBubble(
                key: ValueKey(message.id), // Key for scrolling to message
                message: message,
                isMe: isMe,
                otherUserName: otherUserName,
                otherUserPicture: otherUserPicture,
                isSelectionMode: isSelectionMode,
                isSelected: selectedMessageIds.contains(message.id),
                onSelectionChanged: onSelectionChanged,
                onDelete: onDelete,
                onEdit: onEdit,
                onReply: onReply,
                onReplyTap: onReplyTap,
                onPin: onPin,
                onUnpin: onUnpin,
                onForward: onForward,
                onRetry: onRetryMessage,
                onDeleteFailed: onDeleteFailedMessage,
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
