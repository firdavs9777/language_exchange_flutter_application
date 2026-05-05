import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/story_viewer_screen.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/media_message_widget.dart';
import 'package:bananatalk_app/widgets/video_player_screen.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/linkified_text.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'reply_preview.dart';

/// Renders media messages: image, video, audio, document, location.
///
/// Tapping an image opens [ImageGallery]; tapping a video opens [VideoPlayerScreen].
/// Location and document messages delegate to [MediaMessageWidget] which owns those layouts.
/// A text caption, story-reference pill, and reply preview are shown when present.
class ImageMessageView extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Color myMessageColor;
  final Color otherMessageColor;
  final Color myTextColor;
  final Color otherTextColor;
  final Color timestampColor;
  final BorderRadius bubbleRadius;
  final Function(String messageId)? onReplyTap;
  final VoidCallback? onLongPress;

  const ImageMessageView({
    super.key,
    required this.message,
    required this.isMe,
    required this.myMessageColor,
    required this.otherMessageColor,
    required this.myTextColor,
    required this.otherTextColor,
    required this.timestampColor,
    required this.bubbleRadius,
    this.onReplyTap,
    this.onLongPress,
  });

  // ---------- helpers ----------

  bool get _hasText => message.message != null && message.message!.isNotEmpty;

  void _openImage(BuildContext context, String url) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ImageGallery(imageUrls: [url], initialIndex: 0),
      ),
    );
  }

  void _openVideo(BuildContext context, String url) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoUrl: url,
          thumbnail: message.media?.thumbnail,
          title: message.media?.fileName,
        ),
      ),
    );
  }

  // ---------- sub-builders ----------

  Widget _buildDeletedPlaceholder(BuildContext context) {
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

  Widget _buildStoryReferencePreview(BuildContext context) {
    final ref = message.storyReference!;
    return GestureDetector(
      onTap: () => _openStoryFromReference(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ref.thumbnail != null && ref.thumbnail!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CachedImageWidget(
                    imageUrl: ref.thumbnail!,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Icon(Icons.auto_stories, size: 20),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_stories, size: 20),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Replied to your story',
                style: TextStyle(
                  fontSize: 11,
                  color: isMe
                      ? Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.7)
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStoryFromReference(
      BuildContext context, StoryReference ref) async {
    if (ref.storyId.isEmpty) return;
    try {
      final response = await StoriesService.getStory(storyId: ref.storyId);
      if (response.success && response.data != null && context.mounted) {
        final userStories =
            UserStories(user: response.data!.user, stories: [response.data!]);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(
              userStories: [userStories],
              initialUserIndex: 0,
            ),
          ),
        );
      } else if (context.mounted) {
        showChatSnackBar(context,
            message: 'Story is no longer available',
            type: ChatSnackBarType.info);
      }
    } catch (e) {
      debugPrint('Failed to open story: $e');
    }
  }

  Widget _buildTextCaption(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? myMessageColor : otherMessageColor,
        borderRadius: bubbleRadius,
        boxShadow: AppShadows.sm,
      ),
      child: LinkifiedText(
        text: message.message!,
        style: context.bodyMedium.copyWith(
          color: isMe ? myTextColor : otherTextColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildLocationLayout(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.storyReference != null)
            _buildStoryReferencePreview(context),
          if (message.replyTo != null)
            ReplyPreview(
              message: message,
              isMe: isMe,
              onReplyTap: onReplyTap,
            ),
          MediaMessageWidget(
            media: message.media!,
            isSentByMe: isMe,
            onTap: () {},
          ),
          if (_hasText) _buildTextCaption(context),
          // Standalone timestamp below location card
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatMessageTime(message.createdAt),
                  style: context.captionSmall
                      .copyWith(color: timestampColor),
                ),
                if (isMe && message.read) ...[
                  Spacing.hGapXS,
                  const Icon(Icons.done_all, size: 14, color: AppColors.info),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deleted placeholder
    if (message.isDeleted && message.deletedForEveryone) {
      return _buildDeletedPlaceholder(context);
    }

    final media = message.media!;
    final mediaType = media.type;
    final mediaUrl = media.url;

    // Location has its own simple layout (no gradient overlays)
    if (mediaType == 'location') {
      return _buildLocationLayout(context);
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () {
        if (mediaType == 'image' && mediaUrl.isNotEmpty) {
          _openImage(context, mediaUrl);
        } else if (mediaType == 'video' && mediaUrl.isNotEmpty) {
          _openVideo(context, mediaUrl);
        }
      },
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.storyReference != null)
            _buildStoryReferencePreview(context),
          if (message.replyTo != null)
            ReplyPreview(
              message: message,
              isMe: isMe,
              onReplyTap: onReplyTap,
            ),
          // Media container
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderLG,
              boxShadow: AppShadows.md,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.borderLG,
              child: Stack(
                children: [
                  MediaMessageWidget(
                    media: media,
                    isSentByMe: isMe,
                    onTap: () {
                      if (mediaType == 'image' && mediaUrl.isNotEmpty) {
                        _openImage(context, mediaUrl);
                      }
                    },
                  ),
                  // Gradient overlay for text legibility
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.black.withValues(alpha: 0.3),
                            ],
                            stops: const [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Video play-button overlay
                  if (mediaType == 'video')
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: Spacing.paddingMD,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  // Timestamp overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.5),
                        borderRadius: AppRadius.borderMD,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatMessageTime(message.createdAt),
                            style: context.captionSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isMe && message.read) ...[
                            Spacing.hGapXS,
                            const Icon(
                              Icons.done_all,
                              color: AppColors.info,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Text caption below media
          if (_hasText) _buildTextCaption(context),
        ],
      ),
    );
  }
}
