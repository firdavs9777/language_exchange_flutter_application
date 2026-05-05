import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/pages/chat/message/messages_list.dart';
import 'package:bananatalk_app/pages/chat/message/pinned_messages_bar.dart';
import 'package:bananatalk_app/widgets/connection_status_indicator.dart';

/// The central conversation area: connectivity banner + pinned-messages bar +
/// message list + scroll-to-bottom FAB.
///
/// All state (scroll controller, FAB visibility, selection set, etc.) lives in
/// [_ChatScreenState]. This widget is intentionally stateless — it receives
/// every piece of data and every callback via constructor params.
class ConversationMessagesView extends StatelessWidget {
  // Chat list data
  final bool isLoading;
  final String error;
  final List<Message> messages;
  final String? currentUserId;
  final String otherUserName;
  final String? otherUserPicture;
  final bool otherUserTyping;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final Widget headerWidget;

  // Pinned messages
  final List<Message> pinnedMessages;
  final VoidCallback onPinnedTap;
  final VoidCallback onPinnedClose;

  // Selection mode
  final bool isSelectionMode;
  final Set<String> selectedMessageIds;
  final Function(Message, bool) onSelectionChanged;

  // Message action callbacks — onRetry is Future<void> to satisfy RefreshIndicator
  final Future<void> Function() onRetry;
  final Function(Message) onDelete;
  final Function(Message) onEdit;
  final Function(Message) onReply;
  final Function(String messageId) onReplyTap;
  final Function(Message) onPin;
  final Function(Message) onUnpin;
  final Function(Message) onForward;
  final Function(Message) onRetryMessage;
  final Function(Message) onDeleteFailedMessage;
  final VoidCallback onSendWave;

  // Scroll-to-bottom FAB
  final bool showScrollToBottomFab;
  final VoidCallback onScrollToBottom;

  const ConversationMessagesView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.messages,
    this.currentUserId,
    required this.otherUserName,
    this.otherUserPicture,
    required this.otherUserTyping,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasMoreMessages,
    required this.headerWidget,
    required this.pinnedMessages,
    required this.onPinnedTap,
    required this.onPinnedClose,
    required this.isSelectionMode,
    required this.selectedMessageIds,
    required this.onSelectionChanged,
    required this.onRetry, // Future<void> — satisfies RefreshIndicator.onRefresh
    required this.onDelete,
    required this.onEdit,
    required this.onReply,
    required this.onReplyTap,
    required this.onPin,
    required this.onUnpin,
    required this.onForward,
    required this.onRetryMessage,
    required this.onDeleteFailedMessage,
    required this.onSendWave,
    required this.showScrollToBottomFab,
    required this.onScrollToBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ConnectionStatusIndicator(),
        if (pinnedMessages.isNotEmpty)
          PinnedMessagesBar(
            pinnedMessages: pinnedMessages,
            onTap: onPinnedTap,
            onClose: onPinnedClose,
          ),
        Expanded(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: onRetry,
                displacement: 20,
                color: AppColors.primary,
                child: ChatMessagesList(
                  isLoading: isLoading,
                  error: error,
                  messages: messages,
                  currentUserId: currentUserId,
                  otherUserName: otherUserName,
                  otherUserPicture: otherUserPicture,
                  otherUserTyping: otherUserTyping,
                  scrollController: scrollController,
                  onRetry: onRetry,
                  isSelectionMode: isSelectionMode,
                  selectedMessageIds: selectedMessageIds,
                  isLoadingMore: isLoadingMore,
                  hasMoreMessages: hasMoreMessages,
                  headerWidget: headerWidget,
                  onSelectionChanged: onSelectionChanged,
                  onDelete: onDelete,
                  onEdit: onEdit,
                  onReply: onReply,
                  onReplyTap: onReplyTap,
                  onPin: onPin,
                  onUnpin: onUnpin,
                  onForward: onForward,
                  onRetryMessage: onRetryMessage,
                  onDeleteFailedMessage: onDeleteFailedMessage,
                  onSendWave: onSendWave,
                ),
              ),
              if (showScrollToBottomFab)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _ScrollToBottomFab(onTap: onScrollToBottom),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 48×48 circular FAB shown when the user has scrolled >300 px above the
/// latest message. Tapping it triggers [onTap] which the parent uses to
/// animate back to the bottom of the list.
class _ScrollToBottomFab extends StatelessWidget {
  final VoidCallback onTap;

  const _ScrollToBottomFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: isDark
                ? Colors.black.withValues(alpha: 0.87)
                : Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
