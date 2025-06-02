import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final bool isSending;
  final bool showMediaPanel;
  final bool showStickerPanel;
  final Function({String? messageText, String? messageType}) onSendMessage;
  final VoidCallback onToggleMediaPanel;
  final VoidCallback onToggleStickerPanel;
  final VoidCallback onTyping;
  final VoidCallback onStopTyping;
  final VoidCallback onHidePanels;

  const ChatInputBar({
    Key? key,
    required this.messageController,
    required this.isSending,
    required this.showMediaPanel,
    required this.showStickerPanel,
    required this.onSendMessage,
    required this.onToggleMediaPanel,
    required this.onToggleStickerPanel,
    required this.onTyping,
    required this.onStopTyping,
    required this.onHidePanels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Media attachment button
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: onToggleMediaPanel,
                icon: AnimatedRotation(
                  turns: showMediaPanel ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.add,
                    color: showMediaPanel
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                    size: 26,
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: showMediaPanel
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Text input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16),
                  onSubmitted: (_) => onSendMessage(),
                  onChanged: (text) {
                    if (text.trim().isNotEmpty) {
                      onTyping();
                    } else {
                      onStopTyping();
                    }
                  },
                  onTap: onHidePanels,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Emoji/Sticker button
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: onToggleStickerPanel,
                icon: Icon(
                  showStickerPanel ? Icons.keyboard : Icons.emoji_emotions,
                  color: showStickerPanel
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: showStickerPanel
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSending
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withBlue(255),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: isSending ? null : () => onSendMessage(),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
