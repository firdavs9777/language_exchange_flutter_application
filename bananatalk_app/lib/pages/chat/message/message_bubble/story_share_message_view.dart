import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

/// Renders a "shared a story" DM message (created by the backend's
/// `POST /stories/:id/share` with `{sharedTo:'dm'}`, see
/// `controllers/stories.js exports.shareStory`) as a tappable story card.
///
/// The backend persists both `messageType: 'story_share'` and a
/// `storyReference {storyId, thumbnail}` on the Message it creates, so
/// detection below is signal-based (message type / stored reference)
/// rather than matching on the literal display text, which could collide
/// with a genuine chat message that happens to say the same words.
///
/// LEGACY NOTE: messages shared before the backend persisted `storyReference`
/// (and before `messageType` was set to `'story_share'`) have neither signal
/// and intentionally render as plain text rather than this card.
class StoryShareMessageView extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onLongPress;

  const StoryShareMessageView({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
  });

  /// Whether [message] is a story-share card per the shape above.
  /// Story shares are detected by messageType 'story_share' only.
  /// Story replies (type 'text' + storyReference) render via TextMessageView's reply preview.
  /// Legacy pre-fix shares render as plain text by design.
  static bool matches(Message message) {
    return !message.isDeleted && message.type == 'story_share';
  }

  @override
  State<StoryShareMessageView> createState() => _StoryShareMessageViewState();
}

class _StoryShareMessageViewState extends State<StoryShareMessageView> {
  bool _loading = false;
  bool _expired = false;

  bool get _hasStoryId =>
      widget.message.storyReference?.storyId.isNotEmpty == true;

  Future<void> _handleTap() async {
    if (_loading) return;
    if (_expired || !_hasStoryId) {
      showChatSnackBar(
        context,
        message: 'This story is no longer available',
        type: ChatSnackBarType.info,
      );
      setState(() => _expired = true);
      return;
    }

    setState(() => _loading = true);
    try {
      final storyId = widget.message.storyReference!.storyId;
      final response = await StoriesService.getStory(storyId: storyId);
      if (!mounted) return;

      if (response.success && response.data != null) {
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
      } else {
        setState(() => _expired = true);
        showChatSnackBar(
          context,
          message: 'This story is no longer available',
          type: ChatSnackBarType.info,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _expired = true);
      showChatSnackBar(
        context,
        message: 'This story is no longer available',
        type: ChatSnackBarType.info,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final thumbnail = widget.message.storyReference?.thumbnail;
    final isDisabled = _expired || !_hasStoryId;
    final senderName = widget.message.sender.name;
    final caption = widget.isMe ? 'You shared a story' : '$senderName shared a story';

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 210,
                child: isDisabled
                    ? _buildDisabledFace(isDark)
                    : (thumbnail != null && thumbnail.isNotEmpty)
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedImageWidget(
                                imageUrl: thumbnail,
                                fit: BoxFit.cover,
                                errorWidget: _buildGradientFace(),
                              ),
                              _buildLabelOverlay(),
                              if (_loading) _buildLoadingOverlay(),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildGradientFace(),
                              _buildLabelOverlay(),
                              if (_loading) _buildLoadingOverlay(),
                            ],
                          ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: isDark ? const Color(0xFF262626) : Colors.white,
                child: Text(
                  isDisabled ? 'Story expired' : caption,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDisabled
                        ? context.textSecondary
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientFace() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF962FBF), Color(0xFF4F5BD5)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
    );
  }

  Widget _buildDisabledFace(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF303030) : Colors.grey[300],
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_stories_outlined,
        color: isDark ? Colors.white38 : Colors.black26,
        size: 40,
      ),
    );
  }

  Widget _buildLabelOverlay() {
    return Positioned(
      left: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text(
              'Story',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
      ),
    );
  }
}
