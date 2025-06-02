import 'package:flutter/material.dart';
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
