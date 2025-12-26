import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

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
  final Message? replyingToMessage;
  final String? otherUserName;
  final VoidCallback? onCancelReply;

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
    this.replyingToMessage,
    this.otherUserName,
    this.onCancelReply,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (replyingToMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ${otherUserName ?? "user"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            replyingToMessage!.message ?? 
                            (replyingToMessage!.media != null ? '📷 Media' : 'Message'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onCancelReply,
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            // Input row
            Row(
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
                    hintText: AppLocalizations.of(context)!.typeAMessage,
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
          ],
        ),
      ),
    );
  }
}
