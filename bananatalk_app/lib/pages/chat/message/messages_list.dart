import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/call/call_history_bubble.dart';
import 'package:bananatalk_app/widgets/correction_message_bubble.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/pages/chat/message/message_bubble.dart';
import 'package:bananatalk_app/pages/chat/message/typing_indicator.dart';
import 'package:bananatalk_app/pages/chat/message/conversation_empty_state.dart';
import 'package:bananatalk_app/pages/chat/error/chat_error_widget.dart';
import 'package:bananatalk_app/pages/chat/message/chat_row.dart';
import 'package:bananatalk_app/pages/chat/message/date_separator_chip.dart';

class ChatMessagesList extends StatelessWidget {
  final bool isLoading;
  final String error;
  final List<Message> messages;
  final String? currentUserId;
  final String otherUserName;
  final String? otherUserPicture;
  final String? otherUserNativeLanguage;
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
  final Function(CallRecord)? onCallTap; // Initiate call from call history bubble

  /// Workstream D — Language Rooms: multi-sender group mode. When true, each
  /// non-mine message renders with its own sender name + avatar (taken from
  /// `message.sender`) instead of the single fixed `otherUserName`/
  /// `otherUserPicture` used by 1-on-1 chats. Defaults to `false` so the
  /// existing DM path is completely unaffected.
  final bool isGroup;

  /// Long-press "Report" action for a message — used by hub/room chat
  /// (Task 11 moderation). `null` (the default) hides the option, which is
  /// how the existing 1-on-1 path stays unchanged.
  final Function(Message)? onReport;

  const ChatMessagesList({
    Key? key,
    required this.isLoading,
    required this.error,
    required this.messages,
    required this.currentUserId,
    required this.otherUserName,
    this.otherUserPicture,
    this.otherUserNativeLanguage,
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
    this.onCallTap,
    this.isGroup = false,
    this.onReport,
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
                            AppLocalizations.of(context)!.tapToSayHi,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.sendWaveToStart,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
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
      return ConversationEmptyState(userName: otherUserName, onSendWave: onSendWave);
    }

    // Build list with header at top, then messages chronologically (oldest to newest)
    // Calculate indices: header at 0, then rows (date separators + messages),
    // then loading indicator at end
    final rows = buildChatRows(messages);
    final headerOffset = hasHeader ? 1 : 0;
    final totalItems = headerOffset + rows.length + (isLoadingMore ? 1 : 0);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

              // Resolve row - adjust index for header offset
              final rowIndex = index - headerOffset;
              if (rowIndex < 0 || rowIndex >= rows.length) {
                return const SizedBox.shrink(); // Safety check
              }
              final row = rows[rowIndex];
              if (row is DateSeparatorRow) {
                return DateSeparatorChip(day: row.day);
              }
              final messageRow = row as MessageRow;
              final message = messageRow.message;
              final isMe = message.sender.id == currentUserId;
              final isFirstInGroup = messageRow.isFirstInGroup;
              final isLastInGroup = messageRow.isLastInGroup;

              // Check if this is a correction message (shown as standalone bubble)
              if (message.type == 'correction') {
                final correction = message.corrections.isNotEmpty
                    ? message.corrections.first
                    : null;
                // Find the original message this correction belongs to.
                // The correction bubble id is 'correction_<correctionId>' so
                // the original message is the one carrying that correctionId.
                final correctionId = correction?.id ?? '';
                final originalMessage = correctionId.isNotEmpty
                    ? messages.firstWhere(
                        (m) =>
                            m.type != 'correction' &&
                            m.corrections.any((c) => c.id == correctionId),
                        orElse: () => message, // fallback: shouldn't happen
                      )
                    : message;
                // isCorrector: true when current user sent the correction
                final isCorrector =
                    correction?.corrector.id == currentUserId;
                return CorrectionMessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  isMe: isMe,
                  otherUserName: otherUserName,
                  otherUserPicture: otherUserPicture,
                  otherUserNativeLanguage: otherUserNativeLanguage,
                  originalMessageId: originalMessage.id,
                  isCorrector: isCorrector,
                );
              }

              // Check if this is a call record message
              if (message.type == 'call' && message.media?.callData != null) {
                final callRecord = CallRecord.fromJson(
                  message.media!.callData!,
                  currentUserId ?? '',
                );
                return CallHistoryBubble(
                  key: ValueKey(message.id),
                  call: callRecord,
                  isOutgoing: isMe,
                  onTap: onCallTap != null
                      ? () => onCallTap!(callRecord)
                      : null,
                );
              }

              // Group (hub/room) mode: each non-mine message uses its own
              // sender's name/avatar instead of the single fixed
              // otherUserName/otherUserPicture the 1-on-1 path relies on.
              // The 1-on-1 path (isGroup == false, the default) is entirely
              // unaffected — it keeps passing the widget-level values below.
              final bubbleUserName =
                  isGroup && !isMe ? message.sender.name : otherUserName;
              final senderImages = message.sender.effectiveImageUrls;
              final bubblePicture = isGroup && !isMe
                  ? (senderImages.isNotEmpty ? senderImages.first : null)
                  : otherUserPicture;
              final bubbleNativeLanguage = isGroup && !isMe
                  ? message.sender.native_language
                  : otherUserNativeLanguage;

              final bubble = ChatMessageBubble(
                key: ValueKey(message.id), // Key for scrolling to message
                message: message,
                isMe: isMe,
                otherUserName: bubbleUserName,
                otherUserPicture: bubblePicture,
                otherUserNativeLanguage: bubbleNativeLanguage,
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
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
                // Per-message report (Task 11) — only wired for non-mine
                // messages; `null` (the DM default) hides the menu item
                // entirely, so the existing 1-on-1 context menu is unchanged.
                onReport: !isMe ? onReport : null,
              );

              if (isGroup && !isMe && isFirstInGroup) {
                return Padding(
                  padding: const EdgeInsets.only(left: 52, right: 16, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          message.sender.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                      bubble,
                    ],
                  ),
                );
              }

              return bubble;
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
