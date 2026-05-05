import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/voice_message_player.dart';
import 'reply_preview.dart';

/// Renders voice (and audio) messages.
///
/// Delegates playback UI + waveform to [VoiceMessagePlayer].
/// Reply preview is shown above the player when present.
class VoiceMessageView extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Function(String messageId)? onReplyTap;
  final VoidCallback? onLongPress;

  const VoiceMessageView({
    super.key,
    required this.message,
    required this.isMe,
    this.onReplyTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Deleted placeholder
    if (message.isDeleted && message.deletedForEveryone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.containerColor.withValues(alpha: 0.5),
          borderRadius: AppRadius.borderLG,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 16, color: context.textSecondary),
            Spacing.hGapSM,
            Text(
              'This message was deleted',
              style: context.bodySmall.copyWith(
                color: context.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final media = message.media;
    if (media == null || media.url.isEmpty) {
      return const SizedBox.shrink();
    }

    final normalizedUrl = ImageUtils.normalizeImageUrl(media.url);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null)
            ReplyPreview(
              message: message,
              isMe: isMe,
              onReplyTap: onReplyTap,
            ),
          VoiceMessagePlayer(
            audioUrl: normalizedUrl,
            durationSeconds: media.duration ?? 0,
            waveform: media.waveform,
            isFromMe: isMe,
            messageId: message.id,
            senderId: message.sender.id,
          ),
        ],
      ),
    );
  }
}
