import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'reply_preview.dart';

/// Renders GIF messages.
///
/// Displays the animated GIF via [CachedNetworkImage] inside a rounded clip.
/// A reply preview is shown above the GIF when present.
class GifMessageView extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Function(String messageId)? onReplyTap;
  final VoidCallback? onLongPress;

  const GifMessageView({
    super.key,
    required this.message,
    required this.isMe,
    this.onReplyTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final gifUrl = message.message;
    if (gifUrl == null || !gifUrl.startsWith('http')) {
      return const SizedBox.shrink();
    }

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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
              child: CachedNetworkImage(
                imageUrl: gifUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
