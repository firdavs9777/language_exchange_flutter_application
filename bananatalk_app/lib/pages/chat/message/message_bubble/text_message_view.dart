import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/linkified_text.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/pages/chat/message/bubble/word_long_press_handler.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'reply_preview.dart';

/// Renders text messages including:
///   - Deleted-message placeholder
///   - Wave-sticker greeting card (👋)
///   - Sticker / emoji-only (large, no bubble)
///   - Standard text bubble: link detection, edited label, link preview card
///
/// Story reference preview and reply pill are rendered above the bubble when present.
class TextMessageView extends StatefulWidget {
  final Message message;
  final bool isMe;
  final Color myMessageColor;
  final Color otherMessageColor;
  final Color myTextColor;
  final Color otherTextColor;
  final BorderRadius bubbleRadius;
  final Function(String messageId)? onReplyTap;
  final VoidCallback? onLongPress;

  const TextMessageView({
    super.key,
    required this.message,
    required this.isMe,
    required this.myMessageColor,
    required this.otherMessageColor,
    required this.myTextColor,
    required this.otherTextColor,
    required this.bubbleRadius,
    this.onReplyTap,
    this.onLongPress,
  });

  @override
  State<TextMessageView> createState() => _TextMessageViewState();
}

class _TextMessageViewState extends State<TextMessageView> {
  /// Key forwarded to the inner [Text] / [Text.rich] inside [LinkifiedText]
  /// so that [WordLongPressHandler] can hit-test word boundaries.
  final GlobalKey _textKey = GlobalKey();

  // ---------- helpers ----------

  static String? _extractFirstUrl(String? text) {
    if (text == null || text.isEmpty) return null;
    final match = LinkifiedText.urlRegex.firstMatch(text);
    if (match == null) return null;
    var url = match.group(0)!;
    if (url.toLowerCase().startsWith('www.')) url = 'https://$url';
    return url;
  }

  static bool _isSticker(String text) {
    final emojiPattern = RegExp(
      r'^(?:[\u{1f300}-\u{1f9ff}]|[\u{2600}-\u{27bf}]|[\u{2300}-\u{23ff}]|[\u{2b50}]|[\u{2764}]|[\u{fe0f}]|[\u{200d}]|[\u{1f3fb}-\u{1f3ff}])+$',
      unicode: true,
    );
    return text.length <= 12 && emojiPattern.hasMatch(text);
  }

  static bool _isWaveSticker(String text) {
    final t = text.trim();
    return t == '👋' || t == '👋🏻' || t == '👋🏼' || t == '👋🏽' || t == '👋🏾' || t == '👋🏿';
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

  Widget _buildWaveStickerCard(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isMe
                ? [const Color(0xFFFFE082), const Color(0xFFFFCA28)]
                : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (widget.isMe ? const Color(0xFFFFCA28) : const Color(0xFF90CAF9))
                  .withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👋', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 8),
            Text(
              'Hi!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isMe ? const Color(0xFF5D4037) : const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryReferencePreview(BuildContext context) {
    final ref = widget.message.storyReference!;
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
                  color: widget.isMe
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

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final text = widget.message.message ?? '';

    // Deleted placeholder
    if (widget.message.isDeleted && widget.message.deletedForEveryone) {
      return _buildDeletedPlaceholder(context);
    }

    // Wave sticker
    if (_isWaveSticker(text)) {
      return _buildWaveStickerCard(context);
    }

    // Emoji-only sticker (no bubble background)
    if (_isSticker(text)) {
      return Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message.storyReference != null)
            _buildStoryReferencePreview(context),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(text, style: const TextStyle(fontSize: 64)),
          ),
        ],
      );
    }

    // Standard text bubble — wrap with WordLongPressHandler to enable
    // per-word long-press → save to vocabulary.  The outer GestureDetector
    // (onLongPress: widget.onLongPress) handles the message-level context
    // menu; WordLongPressHandler intercepts long-press-start to detect words.
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: WordLongPressHandler(
        text: text,
        textKey: _textKey,
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (widget.message.storyReference != null)
              _buildStoryReferencePreview(context),
            if (widget.message.replyTo != null)
              ReplyPreview(
                message: widget.message,
                isMe: widget.isMe,
                onReplyTap: widget.onReplyTap,
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isMe ? widget.myMessageColor : widget.otherMessageColor,
                borderRadius: widget.bubbleRadius,
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (text.isNotEmpty)
                    LinkifiedText(
                      textKey: _textKey,
                      text: text,
                      style: context.bodyMedium.copyWith(
                        color: widget.isMe ? widget.myTextColor : widget.otherTextColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      linkStyle: context.bodyMedium.copyWith(
                        color: widget.isMe
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF1E88E5),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: widget.isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF1E88E5),
                      ),
                    ),
                  if (widget.message.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'edited',
                        style: context.captionSmall.copyWith(
                          color: (widget.isMe ? widget.myTextColor : widget.otherTextColor)
                              .withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  // Inline link preview card
                  if (_extractFirstUrl(text) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnyLinkPreview(
                          link: _extractFirstUrl(text)!,
                          displayDirection:
                              UIDirection.uiDirectionHorizontal,
                          bodyMaxLines: 2,
                          titleStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.isMe ? widget.myTextColor : widget.otherTextColor,
                          ),
                          bodyStyle: TextStyle(
                            fontSize: 12,
                            color: (widget.isMe ? widget.myTextColor : widget.otherTextColor)
                                .withValues(alpha: 0.7),
                          ),
                          errorWidget: const SizedBox.shrink(),
                          cache: const Duration(days: 7),
                          backgroundColor: Colors.transparent,
                          borderRadius: 0,
                          removeElevation: true,
                        ),
                      ),
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
