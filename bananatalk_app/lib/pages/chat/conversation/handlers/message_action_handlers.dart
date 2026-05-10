// lib/pages/chat/conversation/handlers/message_action_handlers.dart
//
// Free-function equivalents of the private _handle* methods that lived in
// _ChatScreenState.  Each function is a thin delegate: it receives everything
// it needs through named parameters so the orchestrator (chat_conversation_screen.dart)
// can call it in a single line.

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/chat_state_provider.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/pages/chat/dialogs/delete_message_dialog.dart';
import 'package:bananatalk_app/pages/chat/dialogs/forward_message_dialog.dart';
import 'package:bananatalk_app/pages/chat/conversation/edit_message_dialog.dart';

// ---------------------------------------------------------------------------
// handleEditMessage
// ---------------------------------------------------------------------------

Future<void> handleEditMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
  required String chatPartnerId,
  required String currentUserId,
}) async {
  // Check if message can be edited (within 15 minutes)
  try {
    final createdAt = DateTime.parse(message.createdAt);
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes >= 15) {
      showChatSnackBar(
        context,
        message: AppLocalizations.of(context)!.editWithin15Minutes,
        type: ChatSnackBarType.info,
      );
      return;
    }
  } catch (e) {
    return;
  }

  // Show edit dialog
  final newText = await showDialog<String>(
    context: context,
    builder: (context) => EditMessageDialog(initialText: message.message ?? ''),
  );

  if (newText != null && newText.trim().isNotEmpty && context.mounted) {
    final chatNotifier = ref.read(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: chatPartnerId,
          currentUserId: currentUserId,
        ),
      ).notifier,
    );

    // Optimistic update
    chatNotifier.updateMessageLocally(message.id, newText: newText, isEdited: true);

    // Call API
    final messageService = ref.read(messageServiceProvider);
    final result = await messageService.editMessage(
      messageId: message.id,
      message: newText,
    );

    if (result['success'] != true && context.mounted) {
      // Revert on failure
      chatNotifier.updateMessageLocally(message.id, newText: message.message);
      showChatSnackBar(
        context,
        message: result['error'] ?? 'Failed to edit message',
        type: ChatSnackBarType.error,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// handleDeleteMessage
// ---------------------------------------------------------------------------

Future<void> handleDeleteMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
  required String chatPartnerId,
  required String currentUserId,
  required String otherUserName,
  /// Called on API failure so the orchestrator can reload the message list.
  required Future<void> Function() onReloadMessages,
}) async {
  await showDeleteMessageDialog(
    context,
    message: message,
    otherUserName: otherUserName,
    onDelete: (deleteForEveryone) async {
      if (!context.mounted) return;

      final chatNotifier = ref.read(
        chatStateProvider(
          ChatProviderParams(
            chatPartnerId: chatPartnerId,
            currentUserId: currentUserId,
          ),
        ).notifier,
      );

      // Optimistic update
      if (deleteForEveryone) {
        chatNotifier.markMessageAsDeleted(message.id);
      } else {
        chatNotifier.removeMessageLocally(message.id);
      }

      // Call API
      final messageService = ref.read(messageServiceProvider);
      final result = await messageService.deleteMessage(
        messageId: message.id,
        deleteForEveryone: deleteForEveryone,
      );

      if (result['success'] != true && context.mounted) {
        // Revert on failure — reload messages
        final errorMessage = result['error'] ?? 'Failed to delete message';
        await onReloadMessages();
        if (context.mounted) {
          showChatSnackBar(
            context,
            message: errorMessage,
            type: ChatSnackBarType.error,
          );
        }
      }
    },
  );
}

// ---------------------------------------------------------------------------
// handlePinMessage
// ---------------------------------------------------------------------------

Future<void> handlePinMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
  required String chatPartnerId,
  required String currentUserId,
}) async {
  if (!context.mounted) return;

  final chatNotifier = ref.read(
    chatStateProvider(
      ChatProviderParams(
        chatPartnerId: chatPartnerId,
        currentUserId: currentUserId,
      ),
    ).notifier,
  );

  // Optimistic update
  chatNotifier.togglePinLocally(message.id);

  // Call API
  final messageService = ref.read(messageServiceProvider);
  final result = await messageService.pinMessage(messageId: message.id);

  if (!context.mounted) return;

  if (result['success'] != true) {
    // Revert on failure
    chatNotifier.togglePinLocally(message.id);
    showChatSnackBar(
      context,
      message: result['error'] ?? 'Failed to update pin status',
      type: ChatSnackBarType.error,
    );
  } else {
    showChatSnackBar(
      context,
      message: message.isPinned ? 'Message unpinned' : 'Message pinned',
      type: ChatSnackBarType.success,
    );
  }
}

// ---------------------------------------------------------------------------
// handleForwardMessage
// ---------------------------------------------------------------------------

Future<void> handleForwardMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
  required String chatPartnerId,
  required String currentUserId,
}) async {
  // Get list of chat partners from unread counts (user IDs)
  final chatPartnersState = ref.read(chatPartnersProvider);
  final userIds = chatPartnersState.unreadCounts.keys
      .where((id) => id != chatPartnerId)
      .toList();

  // If no chat partners from unread counts, try to get from current messages
  if (userIds.isEmpty) {
    final chatState = ref.read(
      chatStateProvider(
        ChatProviderParams(
          chatPartnerId: chatPartnerId,
          currentUserId: currentUserId,
        ),
      ),
    );

    final uniqueUserIds = <String>{};
    for (final msg in chatState.messages) {
      if (msg.sender.id != currentUserId && msg.sender.id != chatPartnerId) {
        uniqueUserIds.add(msg.sender.id);
      }
      if (msg.receiver.id != currentUserId && msg.receiver.id != chatPartnerId) {
        uniqueUserIds.add(msg.receiver.id);
      }
    }
    userIds.addAll(uniqueUserIds);
  }

  if (userIds.isEmpty) {
    showChatSnackBar(
      context,
      message: 'No other users to forward to',
      type: ChatSnackBarType.info,
    );
    return;
  }

  final messageService = ref.read(messageServiceProvider);

  final result = await showDialog<List<String>>(
    context: context,
    builder: (context) => ForwardMessageDialog(
      userIds: userIds,
      messageService: messageService,
    ),
  );

  if (result != null && result.isNotEmpty && context.mounted) {
    final forwardResult = await messageService.forwardMessage(
      messageId: message.id,
      receivers: result,
    );

    if (forwardResult['success'] == true && context.mounted) {
      showChatSnackBar(
        context,
        message: AppLocalizations.of(context)!.messageForwardedTo(result.length),
        type: ChatSnackBarType.success,
      );
    } else if (context.mounted) {
      showChatSnackBar(
        context,
        message: forwardResult['error'] ?? 'Failed to forward message',
        type: ChatSnackBarType.error,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// handleRetryMessage
// ---------------------------------------------------------------------------

Future<void> handleRetryMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
  required String chatPartnerId,
  required String currentUserId,
  /// Orchestrator's _sendMessage — signature mirrors the State method.
  required Future<void> Function({String? messageText, String? messageType}) onSendMessage,
}) async {
  if (!context.mounted) return;

  final messageText = message.message;
  if (messageText == null || messageText.isEmpty) return;

  final chatNotifier = ref.read(
    chatStateProvider(
      ChatProviderParams(
        chatPartnerId: chatPartnerId,
        currentUserId: currentUserId,
      ),
    ).notifier,
  );

  // Remove the failed message first
  chatNotifier.removeMessageLocally(message.localId ?? message.id);

  // Send again (only supports text retry for now)
  await onSendMessage(messageText: messageText);
}

// ---------------------------------------------------------------------------
// handleDeleteFailedMessage
// ---------------------------------------------------------------------------

void handleDeleteFailedMessage({
  required BuildContext context,
  required WidgetRef ref,
  required Message message,
  required String chatPartnerId,
  required String currentUserId,
}) {
  if (!context.mounted) return;

  final chatNotifier = ref.read(
    chatStateProvider(
      ChatProviderParams(
        chatPartnerId: chatPartnerId,
        currentUserId: currentUserId,
      ),
    ).notifier,
  );

  chatNotifier.removeMessageLocally(message.localId ?? message.id);

  showChatSnackBar(context, message: 'Message deleted', type: ChatSnackBarType.success);
}

// ---------------------------------------------------------------------------
// handleCallError
// ---------------------------------------------------------------------------

void handleCallError({
  required BuildContext context,
  required String error,
}) {
  if (error.startsWith('PERMANENTLY_DENIED:')) {
    final message = error.substring('PERMANENTLY_DENIED:'.length);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.permissionsRequired),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppSettings.openAppSettings();
            },
            child: Text(AppLocalizations.of(context)!.openSettings),
          ),
        ],
      ),
    );
  } else if (error.startsWith('DENIED:')) {
    final message = error.substring('DENIED:'.length);
    showChatSnackBar(context, message: message, type: ChatSnackBarType.info);
  } else {
    showChatSnackBar(context, message: error, type: ChatSnackBarType.error);
  }
}
