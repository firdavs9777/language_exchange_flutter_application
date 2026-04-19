// lib/pages/chat/pinned_messages_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Bar showing pinned messages at the top of the chat
class PinnedMessagesBar extends StatelessWidget {
  final List<Message> pinnedMessages;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const PinnedMessagesBar({
    super.key,
    required this.pinnedMessages,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedMessages.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final message = pinnedMessages.first; // Show first pinned message

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Pin icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 18,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Message preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.pinnedMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                          if (pinnedMessages.length > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${pinnedMessages.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getMessagePreview(context, message),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textHint,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClose?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMessagePreview(BuildContext context, Message message) {
    // GIF messages store URL in message text — show label instead
    if (message.type == 'gif') {
      return '🎞️ ${AppLocalizations.of(context)!.gifSent}';
    }

    if (message.message != null && message.message!.isNotEmpty) {
      return message.message!;
    }

    final l10n = AppLocalizations.of(context)!;
    switch (message.type) {
      case 'image':
        return '📷 ${l10n.photoMedia}';
      case 'video':
        return '🎥 ${l10n.videoMedia}';
      case 'voice':
      case 'audio':
        return '🎵 ${l10n.voiceMessageMedia}';
      case 'document':
        return '📄 ${l10n.documentMedia}';
      case 'location':
        return '📍 ${l10n.locationMedia}';
      case 'sticker':
        return '🏷️ ${l10n.stickerMedia}';
      default:
        return l10n.messages;
    }
  }
}
