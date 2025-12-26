import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'chat_input_bar.dart';
import 'chat_media_panel.dart';
import 'chat_sticker_panel.dart';

class ChatInputSection extends StatelessWidget {
  final TextEditingController messageController;
  final bool isSending;
  final bool showMediaPanel;
  final bool showStickerPanel;
  final AnimationController mediaPanelController;
  final AnimationController stickerPanelController;
  final Function({String? messageText, String? messageType}) onSendMessage;
  final Function(String) onSendSticker;
  final VoidCallback onToggleMediaPanel;
  final VoidCallback onToggleStickerPanel;
  final VoidCallback onTyping;
  final VoidCallback onStopTyping;
  final VoidCallback onHidePanels;
  final Function(String) onMediaOption;
  final Message? replyingToMessage;
  final String? otherUserName;
  final VoidCallback? onCancelReply;

  const ChatInputSection({
    Key? key,
    required this.messageController,
    required this.isSending,
    required this.showMediaPanel,
    required this.showStickerPanel,
    required this.mediaPanelController,
    required this.stickerPanelController,
    required this.onSendMessage,
    required this.onSendSticker,
    required this.onToggleMediaPanel,
    required this.onToggleStickerPanel,
    required this.onTyping,
    required this.onStopTyping,
    required this.onHidePanels,
    required this.onMediaOption,
    this.replyingToMessage,
    this.otherUserName,
    this.onCancelReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatInputBar(
          messageController: messageController,
          isSending: isSending,
          showMediaPanel: showMediaPanel,
          showStickerPanel: showStickerPanel,
          onSendMessage: onSendMessage,
          onToggleMediaPanel: onToggleMediaPanel,
          onToggleStickerPanel: onToggleStickerPanel,
          onTyping: onTyping,
          onStopTyping: onStopTyping,
          onHidePanels: onHidePanels,
          replyingToMessage: replyingToMessage,
          otherUserName: otherUserName,
          onCancelReply: onCancelReply,
        ),
        if (showMediaPanel)
          ChatMediaPanel(
            animationController: mediaPanelController,
            onMediaOption: onMediaOption,
          ),
        if (showStickerPanel)
          ChatStickerPanel(
            animationController: stickerPanelController,
            onSendSticker: onSendSticker,
          ),
      ],
    );
  }
}
