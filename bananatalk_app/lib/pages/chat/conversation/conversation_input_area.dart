import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/pages/chat/input/chat_input_section.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Bottom section of the conversation screen.
///
/// When the current user is blocked by (or has blocked) the partner, renders
/// a read-only "cannot send message" banner.  Otherwise renders the full
/// [ChatInputSection] with media / sticker panels, reply preview, and the
/// upload-progress indicator.
///
/// All mutable state lives in [_ChatScreenState]; this widget is stateless.
class ConversationInputArea extends StatelessWidget {
  final bool isBlockedChat;

  // Passed through to ChatInputSection when not blocked
  final TextEditingController messageController;
  final bool isSending;
  final bool showMediaPanel;
  final bool showStickerPanel;
  final AnimationController mediaPanelController;
  final AnimationController stickerPanelController;
  final Function({String? messageText, String? messageType}) onSendMessage;
  final Function(String) onSelectSticker;
  final Function(String gifUrl)? onSendGif;
  final VoidCallback onToggleMediaPanel;
  final VoidCallback onToggleStickerPanel;
  final VoidCallback onTyping;
  final VoidCallback onStopTyping;
  final VoidCallback onHidePanels;
  final Function(String) onMediaOption;
  final Message? replyingToMessage;
  final String? otherUserName;
  final VoidCallback? onCancelReply;
  final VoidCallback? onAudioPressed;
  final int uploadBytesSent;
  final int uploadTotalBytes;
  final String? uploadFileName;

  const ConversationInputArea({
    super.key,
    required this.isBlockedChat,
    required this.messageController,
    required this.isSending,
    required this.showMediaPanel,
    required this.showStickerPanel,
    required this.mediaPanelController,
    required this.stickerPanelController,
    required this.onSendMessage,
    required this.onSelectSticker,
    this.onSendGif,
    required this.onToggleMediaPanel,
    required this.onToggleStickerPanel,
    required this.onTyping,
    required this.onStopTyping,
    required this.onHidePanels,
    required this.onMediaOption,
    this.replyingToMessage,
    this.otherUserName,
    this.onCancelReply,
    this.onAudioPressed,
    required this.uploadBytesSent,
    required this.uploadTotalBytes,
    this.uploadFileName,
  });

  @override
  Widget build(BuildContext context) {
    if (isBlockedChat) {
      return _BlockedBanner();
    }

    return ChatInputSection(
      messageController: messageController,
      isSending: isSending,
      showMediaPanel: showMediaPanel,
      showStickerPanel: showStickerPanel,
      mediaPanelController: mediaPanelController,
      stickerPanelController: stickerPanelController,
      onSendMessage: onSendMessage,
      onSelectSticker: onSelectSticker,
      onSendGif: onSendGif,
      onToggleMediaPanel: onToggleMediaPanel,
      onToggleStickerPanel: onToggleStickerPanel,
      onTyping: onTyping,
      onStopTyping: onStopTyping,
      onHidePanels: onHidePanels,
      onMediaOption: onMediaOption,
      replyingToMessage: replyingToMessage,
      otherUserName: otherUserName,
      onCancelReply: onCancelReply,
      onAudioPressed: onAudioPressed,
      uploadBytesSent: uploadBytesSent,
      uploadTotalBytes: uploadTotalBytes,
      uploadFileName: uploadFileName,
    );
  }
}

/// Read-only banner shown when the chat is blocked in either direction.
class _BlockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: context.containerColor,
        border: Border(
          top: BorderSide(color: context.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 18, color: context.textSecondary),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.cannotSendMessageUserMayBeBlocked,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
