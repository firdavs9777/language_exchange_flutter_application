import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// In-bubble "replying to X" pill that appears above any message content.
///
/// Tapping scrolls the conversation to the referenced message via [onReplyTap].
class ReplyPreview extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Function(String messageId)? onReplyTap;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.isMe,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final replyTo = message.replyTo;
    if (replyTo == null) return const SizedBox.shrink();

    final isDark = context.isDarkMode;

    // Determine if the original message was from the current user
    final isReplyFromMe = replyTo.sender.id == message.sender.id;
    final senderName = isReplyFromMe
        ? 'You'
        : (replyTo.sender.name.isNotEmpty ? replyTo.sender.name : 'User');

    // Get the reply message preview text
    String replyPreview = replyTo.message ?? '';
    if (replyPreview.isEmpty) {
      replyPreview = '📷 Media';
    }

    // Telegram-style reply pill colours
    final Color borderColor;
    final Color backgroundColor;
    final Color nameColor;
    final Color textColor;

    if (isMe) {
      borderColor = AppColors.white.withValues(alpha: 0.9);
      backgroundColor = AppColors.black.withValues(alpha: 0.15);
      nameColor = AppColors.white;
      textColor = AppColors.white.withValues(alpha: 0.9);
    } else {
      borderColor = isReplyFromMe ? AppColors.primary : AppColors.info;
      backgroundColor = isDark
          ? AppColors.white.withValues(alpha: 0.08)
          : borderColor.withValues(alpha: 0.08);
      nameColor = borderColor;
      textColor = isDark ? AppColors.white.withValues(alpha: 0.8) : AppColors.gray900;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onReplyTap?.call(replyTo.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name with reply icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.reply_rounded, size: 12, color: nameColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: nameColor,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Message preview
                  Text(
                    replyPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
