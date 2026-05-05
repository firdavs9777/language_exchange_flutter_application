import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/media_message_widget.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/pages/stories/story_viewer_screen.dart';
import 'package:bananatalk_app/widgets/message_reaction_widget.dart';
import 'package:bananatalk_app/widgets/video_player_screen.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/forwarded_message_indicator.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/widgets/linkified_text.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bananatalk_app/widgets/translation_bottom_sheet.dart';
import 'package:bananatalk_app/widgets/correction_bottom_sheet.dart';
import 'package:bananatalk_app/services/correction_service.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'user_avatar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ChatMessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;
  final String otherUserName;
  final String? otherUserPicture;
  final Function(Message)? onDelete;
  final Function(Message)? onEdit;
  final Function(Message)? onReply;
  final Function(String messageId)? onReplyTap; // Tap on reply preview to scroll
  final Message? replyToMessage;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(Message, bool)? onSelectionChanged;
  final Function(Message)? onPin;
  final Function(Message)? onUnpin;
  final Function(Message)? onForward;
  final Function(Message)? onRetry; // Retry sending failed message
  final Function(Message)? onDeleteFailed; // Delete failed message from UI
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.otherUserName,
    this.otherUserPicture,
    this.onDelete,
    this.onEdit,
    this.onReply,
    this.onReplyTap,
    this.replyToMessage,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionChanged,
    this.onPin,
    this.onUnpin,
    this.onForward,
    this.onRetry,
    this.onDeleteFailed,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  }) : super(key: key);

  @override
  ConsumerState<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends ConsumerState<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _reactionPickerOverlay;
  String? _currentUserId;
  final GlobalKey _bubbleKey = GlobalKey();

  // Swipe-to-reply state
  double _swipeOffset = 0;
  static const double _swipeThreshold = 60.0;
  late AnimationController _swipeAnimController;
  late Animation<double> _swipeAnimation;

  // Theme-aware chat colors - Light and modern design
  Color _myMessageColor(BuildContext context) => context.isDarkMode ? AppColors.chatBubbleMineDark : AppColors.chatBubbleMine;
  Color _otherMessageColor(BuildContext context) => context.isDarkMode ? AppColors.chatBubbleOtherDark : AppColors.chatBubbleOther;
  Color _myTextColor(BuildContext context) => AppColors.chatTextMine;
  Color _otherTextColor(BuildContext context) => context.isDarkMode ? AppColors.white : AppColors.chatTextOther;
  Color _timestampColor(BuildContext context) => context.textSecondary;
  Color _replyBorderColor(BuildContext context) => AppColors.primary;
  Color _sendingColor(BuildContext context) => context.textSecondary;
  Color _failedColor(BuildContext context) => AppColors.error;

  BorderRadius _bubbleRadius() {
    const double big = 18.0;
    const double small = 4.0;

    if (widget.isMe) {
      // Own messages - tail on bottom-right
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return AppRadius.chatBubbleMine; // solo message
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(big),
          topRight: Radius.circular(big),
          bottomLeft: Radius.circular(big),
          bottomRight: Radius.circular(big),
        );
      } else if (widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(big),
          topRight: Radius.circular(small),
          bottomLeft: Radius.circular(big),
          bottomRight: Radius.circular(small),
        );
      } else {
        return const BorderRadius.only(
          topLeft: Radius.circular(big),
          topRight: Radius.circular(small),
          bottomLeft: Radius.circular(big),
          bottomRight: Radius.circular(small),
        );
      }
    } else {
      // Other user messages - tail on bottom-left
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return AppRadius.chatBubbleOther; // solo message
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(big),
          topRight: Radius.circular(big),
          bottomLeft: Radius.circular(big),
          bottomRight: Radius.circular(big),
        );
      } else if (widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(small),
          topRight: Radius.circular(big),
          bottomLeft: Radius.circular(small),
          bottomRight: Radius.circular(big),
        );
      } else {
        return const BorderRadius.only(
          topLeft: Radius.circular(small),
          topRight: Radius.circular(big),
          bottomLeft: Radius.circular(small),
          bottomRight: Radius.circular(big),
        );
      }
    }
  }

  String? _extractFirstUrl(String? text) {
    if (text == null || text.isEmpty) return null;
    final match = LinkifiedText.urlRegex.firstMatch(text);
    if (match == null) return null;
    var url = match.group(0)!;
    if (url.toLowerCase().startsWith('www.')) {
      url = 'https://$url';
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _initSwipeAnimation();
  }

  void _initSwipeAnimation() {
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _swipeAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOut),
    );
    _swipeAnimController.addListener(() {
      setState(() {
        _swipeOffset = _swipeAnimation.value;
      });
    });
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _hideReactionPicker();
    _swipeAnimController.dispose();
    super.dispose();
  }

  /// Handle horizontal drag for swipe-to-reply (swipe LEFT)
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.isSelectionMode) return;

    // Only allow swiping left (negative delta)
    final newOffset = (_swipeOffset + details.delta.dx).clamp(-_swipeThreshold * 1.5, 0.0);
    setState(() {
      _swipeOffset = newOffset;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isSelectionMode) return;

    // Check if swiped left past threshold (negative value)
    if (_swipeOffset <= -_swipeThreshold) {
      // Trigger reply
      HapticFeedback.mediumImpact();
      widget.onReply?.call(widget.message);
    }

    // Animate back to original position
    _swipeAnimation = Tween<double>(begin: _swipeOffset, end: 0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOut),
    );
    _swipeAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = widget.message.media != null;
    final hasText = widget.message.message != null && widget.message.message!.isNotEmpty;

    // Calculate reply icon opacity based on swipe progress (using absolute value for left swipe)
    final swipeProgress = _swipeOffset.abs();
    final replyIconOpacity = (swipeProgress / _swipeThreshold).clamp(0.0, 1.0);
    final replyIconScale = (0.5 + (replyIconOpacity * 0.5)).clamp(0.5, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onLongPress: widget.isSelectionMode
          ? () {
              if (widget.onSelectionChanged != null) {
                widget.onSelectionChanged!(widget.message, !widget.isSelected);
              }
            }
          : () => _showContextMenu(context),
      onDoubleTap: widget.isSelectionMode
          ? null
          : () => _showContextMenu(context),
      onTap: widget.isSelectionMode
          ? () {
              if (widget.onSelectionChanged != null) {
                widget.onSelectionChanged!(widget.message, !widget.isSelected);
              }
            }
          : () {
              // Single tap - show reaction picker
              _showReactionPicker(context);
            },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Reply icon indicator (appears when swiping LEFT - on the right side)
          if (_swipeOffset < 0)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Transform.scale(
                  scale: replyIconScale,
                  child: Opacity(
                    opacity: replyIconOpacity,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: swipeProgress >= _swipeThreshold
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.reply_rounded,
                        color: swipeProgress >= _swipeThreshold
                            ? AppColors.white
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Message content with swipe transform
          Transform.translate(
            offset: Offset(_swipeOffset, 0),
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: (!widget.isFirstInGroup || !widget.isLastInGroup) ? 1 : 3,
                horizontal: widget.isSelectionMode ? 4 : 16,
              ),
              decoration: widget.isSelectionMode
                  ? BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: AppRadius.borderSM,
                    )
                  : null,
              child: Column(
          crossAxisAlignment: widget.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Selection checkbox
                if (widget.isSelectionMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) {
                        if (widget.onSelectionChanged != null) {
                          widget.onSelectionChanged!(widget.message, value ?? false);
                        }
                      },
                    ),
                  ),
                ],

                // Avatar for other user (left side)
                if (!widget.isMe && !widget.isSelectionMode) ...[
                  if (widget.isLastInGroup)
                    GestureDetector(
                      onTap: () => _navigateToProfile(context),
                      child: UserAvatar(
                        profilePicture: widget.otherUserPicture,
                        userName: widget.otherUserName,
                        radius: 18,
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  Spacing.hGapSM,
                ],

                // Timestamp and sending status (left of my messages)
                if (widget.isMe && !widget.isSelectionMode && widget.isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Sending status indicator
                        _buildSendingStatus(),
                        // Unread "1" badge removed per user request - keeping tick marks only
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatMessageTime(widget.message.createdAt),
                              style: context.captionSmall.copyWith(
                                color: widget.message.isFailed ? _failedColor(context) : _timestampColor(context),
                              ),
                            ),
                            // Checkmarks for sent status
                            if (widget.message.sendingStatus == MessageSendingStatus.none) ...[
                              Spacing.hGapXXS,
                              Icon(
                                widget.message.read ? Icons.done_all : Icons.done,
                                size: 14,
                                color: widget.message.read ? _myMessageColor(context) : _timestampColor(context),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                // Message bubble
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Column(
                      crossAxisAlignment: widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Forwarded indicator
                        if (widget.message.isForwarded)
                          ForwardedMessageIndicator(
                            forwardedFrom: widget.message.forwardedFrom,
                            isMe: widget.isMe,
                          ),
                        // Message content with pin indicator
                        Stack(
                          key: _bubbleKey,
                          children: [
                            hasMedia
                                ? _buildMediaMessage(context, hasText)
                                : _buildTextMessage(context, hasText),
                            // Pin indicator
                            if (widget.message.isPinned)
                              Positioned(
                                top: 4,
                                right: widget.isMe ? 4 : null,
                                left: widget.isMe ? null : 4,
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                        // Corrections are now shown as separate messages in the chat list
                      ],
                    ),
                  ),
                ),

                // Timestamp (right of other user's messages)
                if (!widget.isMe && !widget.isSelectionMode && widget.isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      formatMessageTime(widget.message.createdAt),
                      style: context.captionSmall.copyWith(
                        color: _timestampColor(context),
                      ),
                    ),
                  ),
              ],
            ),
            // Reactions below the message row — outside the avatar Row
            // so they don't push the avatar down
            if (widget.message.reactions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: 2,
                  // Indent reactions to align under the message bubble (past avatar)
                  left: !widget.isMe && !widget.isSelectionMode ? 44 : 0,
                ),
                child: MessageReactionWidget(
                  reactions: widget.message.reactions,
                  currentUserId: _currentUserId,
                  onReactionTap: (emoji) => _handleReactionTap(emoji),
                ),
              ),
          ],
        ),
      ),
          ), // Transform.translate ends
        ], // Stack children ends
      ), // Stack ends
    );
  }

  /// Build sending status indicator for optimistic messages
  Widget _buildSendingStatus() {
    final status = widget.message.sendingStatus;

    if (status == MessageSendingStatus.none) {
      return const SizedBox.shrink();
    }

    if (status == MessageSendingStatus.sending) {
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(_sendingColor(context)),
              ),
            ),
            Spacing.hGapXS,
            Text(
              'Sending...',
              style: context.captionSmall.copyWith(
                color: _sendingColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (status == MessageSendingStatus.failed) {
      return GestureDetector(
        onTap: () => _showFailedMessageOptions(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _failedColor(context).withValues(alpha: 0.1),
            borderRadius: AppRadius.borderSM,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 12,
                color: _failedColor(context),
              ),
              Spacing.hGapXS,
              Text(
                'Failed · Tap for options',
                style: context.captionSmall.copyWith(
                  color: _failedColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Show options for failed message (retry or delete)
  void _showFailedMessageOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Message failed to send',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(),
              // Retry option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh, color: AppColors.primary),
                ),
                title: Text(l10n?.retry ?? 'Retry'),
                subtitle: const Text('Try sending this message again'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onRetry?.call(widget.message);
                },
              ),
              // Delete option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
                title: Text(
                  l10n?.delete ?? 'Delete',
                  style: const TextStyle(color: AppColors.error),
                ),
                subtitle: const Text('Remove this message'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDeleteFailed?.call(widget.message);
                },
              ),
              const SizedBox(height: 8),
              // Cancel button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    _hideReactionPicker();
    HapticFeedback.lightImpact();

    // Use the bubble key for accurate position
    final RenderBox? renderBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    // Show reaction picker above the message
    final overlay = Overlay.of(context);
    const pickerHeight = 56.0;
    const pickerWidth = 260.0;
    final pickerY = position.dy - pickerHeight - 10;

    // Align picker with message bubble side
    double pickerX;
    if (widget.isMe) {
      pickerX = (screenWidth - pickerWidth - 16).clamp(16.0, screenWidth - pickerWidth - 16);
    } else {
      pickerX = 56.0; // Past avatar
    }

    _reactionPickerOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible scrim to dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideReactionPicker,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: pickerX,
            top: pickerY > 0 ? pickerY : position.dy + size.height + 10,
            child: Material(
              color: Colors.transparent,
              child: ReactionPicker(
                onEmojiSelected: (emoji) {
                  _handleReactionTap(emoji);
                  _hideReactionPicker();
                },
                currentReactions: widget.message.reactions
                    .where((r) => r.user.id == _currentUserId)
                    .map((r) => r.emoji)
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_reactionPickerOverlay!);

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _hideReactionPicker();
    });
  }

  void _hideReactionPicker() {
    _reactionPickerOverlay?.remove();
    _reactionPickerOverlay = null;
  }

  void _showTranslation(BuildContext context) {
    final text = widget.message.message;
    if (text == null || text.isEmpty) return;
    showTranslationBottomSheet(
      context,
      messageId: widget.message.id,
      originalText: text,
    );
  }

  Future<void> _handleReactionTap(String emoji) async {
    if (_currentUserId == null) return;
    
    // Check if user already reacted with this emoji
    final existingReaction = widget.message.reactions.firstWhere(
      (r) => r.user.id == _currentUserId && r.emoji == emoji,
      orElse: () => MessageReaction(
        user: Community(
          id: '',
          name: '',
          email: '',
          bio: '',
          mbti: '',
          bloodType: '',
          images: [],
          birth_day: '',
          birth_month: '',
          gender: '',
          birth_year: '',
          native_language: '',
          language_to_learn: '',
          followers: [],
          followings: [],
          imageUrls: [],
          createdAt: '',
          version: 0,
          location: Location.defaultLocation(),
        ),
        emoji: '',
      ),
    );
    
    try {
      final messageService = ref.read(messageServiceProvider);
      
      if (existingReaction.emoji.isNotEmpty) {
        // Remove reaction
        await messageService.removeReaction(
          messageId: widget.message.id,
          emoji: emoji,
        );
      } else {
        // Add reaction
        await messageService.addReaction(
          messageId: widget.message.id,
          emoji: emoji,
        );
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Failed to update reaction: $e', type: ChatSnackBarType.error);
      }
    }
  }

  Widget _buildTextMessage(BuildContext context, bool hasText) {
    // Show deleted message placeholder
    if (widget.message.isDeleted && widget.message.deletedForEveryone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.containerColor.withValues(alpha: 0.5),
          borderRadius: AppRadius.borderLG,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: context.textSecondary,
            ),
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
    // Check if it's a wave sticker (👋) - show special "Hi!" greeting card
    if (_isWaveSticker(widget.message.message ?? '')) {
      return _buildWaveStickerCard(context);
    }

    if (_isSticker(widget.message.message ?? '')) {
      // Stickers/emojis without bubble - larger size
      // But still show story reference if present
      return Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message.storyReference != null) _buildStoryReferencePreview(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              widget.message.message!,
              style: const TextStyle(fontSize: 64),
            ),
          ),
        ],
      );
    }

    // GIF messages - show the GIF image without bubble background
    if (widget.message.type == 'gif' && widget.message.message != null && widget.message.message!.startsWith('http')) {
      return GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
            child: CachedNetworkImage(
              imageUrl: widget.message.message!,
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
                child: const Center(child: Icon(Icons.broken_image_rounded, size: 32)),
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Story reference preview
          if (widget.message.storyReference != null) _buildStoryReferencePreview(),

          // Story reference preview
          if (widget.message.storyReference != null) _buildStoryReferencePreview(),
          // Reply preview if this message is a reply
          if (widget.message.replyTo != null) _buildReplyPreview(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isMe ? _myMessageColor(context) : _otherMessageColor(context),
              borderRadius: _bubbleRadius(),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  LinkifiedText(
                    text: widget.message.message!,
                    style: context.bodyMedium.copyWith(
                      color: widget.isMe ? _myTextColor(context) : _otherTextColor(context),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    linkStyle: context.bodyMedium.copyWith(
                      color: widget.isMe ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E88E5),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: widget.isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1E88E5),
                    ),
                  ),
                if (widget.message.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'edited',
                      style: context.captionSmall.copyWith(
                        color: (widget.isMe ? _myTextColor(context) : _otherTextColor(context))
                            .withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                // Link preview
                if (_extractFirstUrl(widget.message.message) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnyLinkPreview(
                        link: _extractFirstUrl(widget.message.message)!,
                        displayDirection: UIDirection.uiDirectionHorizontal,
                        bodyMaxLines: 2,
                        titleStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isMe ? _myTextColor(context) : _otherTextColor(context),
                        ),
                        bodyStyle: TextStyle(
                          fontSize: 12,
                          color: (widget.isMe ? _myTextColor(context) : _otherTextColor(context)).withValues(alpha: 0.7),
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
    );
  }

  /// Tandem-style correction card below the message bubble
  Widget _buildCorrectionDisplay(BuildContext context) {
    final correction = widget.message.corrections.last;
    final isDark = context.isDarkMode;
    final diffs = CorrectionService.getDifferences(
      correction.originalText,
      correction.correctedText,
    );

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.green.withValues(alpha: 0.25)
              : Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.spellcheck_rounded,
                size: 14,
                color: Colors.green[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Corrected by ${correction.corrector.name}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[600],
                ),
              ),
              if (correction.isAccepted) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 12, color: Colors.green[600]),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Diff display
          Text.rich(
            TextSpan(
              children: diffs.map((diff) {
                switch (diff.type) {
                  case DiffType.unchanged:
                    return TextSpan(
                      text: '${diff.text} ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.gray300 : AppColors.gray700,
                      ),
                    );
                  case DiffType.deleted:
                    return TextSpan(
                      text: '${diff.text} ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[400],
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.red[400],
                      ),
                    );
                  case DiffType.added:
                    return TextSpan(
                      text: '${diff.text} ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    );
                }
              }).toList(),
            ),
          ),
          // Explanation
          if (correction.explanation != null && correction.explanation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              correction.explanation!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.gray400 : AppColors.gray600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryReferencePreview() {
    final ref = widget.message.storyReference!;
    return GestureDetector(
      onTap: () => _openStoryFromReference(ref),
      child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.auto_stories, size: 20),
                  ),
                ),
              ),
            ),
          if (ref.thumbnail == null || ref.thumbnail!.isEmpty)
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                color: widget.isMe ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7) : Theme.of(context).textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _openStoryFromReference(StoryReference ref) async {
    if (ref.storyId.isEmpty) return;
    try {
      final response = await StoriesService.getStory(storyId: ref.storyId);
      if (response.success && response.data != null) {
        final story = response.data!;
        if (context.mounted) {
          final userStories = UserStories(
            user: story.user,
            stories: [story],
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryViewerScreen(
                userStories: [userStories],
                initialUserIndex: 0,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          showChatSnackBar(context, message: 'Story is no longer available', type: ChatSnackBarType.info);
        }
      }
    } catch (e) {
      debugPrint('Failed to open story: $e');
    }
  }

  Widget _buildReplyPreview() {
    final replyTo = widget.message.replyTo!;
    final isDark = context.isDarkMode;

    // Determine if the original message was from the current user
    final isReplyFromMe = replyTo.sender.id == widget.message.sender.id;
    final senderName = isReplyFromMe
        ? 'You'
        : (replyTo.sender.name.isNotEmpty ? replyTo.sender.name : 'User');

    // Get the reply message preview
    String replyPreview = replyTo.message ?? '';
    if (replyPreview.isEmpty) {
      replyPreview = '📷 Media';
    }

    // Colors for Telegram-style reply preview
    final Color borderColor;
    final Color backgroundColor;
    final Color nameColor;
    final Color textColor;

    if (widget.isMe) {
      // My message bubble (usually green/primary colored)
      borderColor = AppColors.white.withValues(alpha: 0.9);
      backgroundColor = AppColors.black.withValues(alpha: 0.15);
      nameColor = AppColors.white;
      textColor = AppColors.white.withValues(alpha: 0.9);
    } else {
      // Other's message bubble
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
        widget.onReplyTap?.call(replyTo.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Reply content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name with reply icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: 12,
                        color: nameColor,
                      ),
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
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
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

  Widget _buildMediaMessage(BuildContext context, bool hasText) {
    // Show deleted message placeholder for media messages too
    if (widget.message.isDeleted && widget.message.deletedForEveryone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.containerColor.withValues(alpha: 0.5),
          borderRadius: AppRadius.borderLG,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: context.textSecondary,
            ),
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
    
    final mediaType = widget.message.media!.type;
    final mediaUrl = widget.message.media!.url;

    // Location messages have their own simple layout
    if (mediaType == 'location') {
      return _buildLocationMessageBubble(context, hasText);
    }

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      onTap: () {
        // Open media viewer
        if (mediaType == 'image' && mediaUrl.isNotEmpty) {
          Navigator.push(
            context,
            AppPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: [mediaUrl],
                initialIndex: 0,
              ),
            ),
          );
        } else if (mediaType == 'video' && mediaUrl.isNotEmpty) {
          Navigator.push(
            context,
            AppPageRoute(
              builder: (context) => VideoPlayerScreen(
                videoUrl: mediaUrl,
                thumbnail: widget.message.media?.thumbnail,
                title: widget.message.media?.fileName,
              ),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Story reference preview
          if (widget.message.storyReference != null) _buildStoryReferencePreview(),
          // Reply preview if this message is a reply
          if (widget.message.replyTo != null) _buildReplyPreview(),

          // Media container with modern design
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
                    media: widget.message.media!,
                    isSentByMe: widget.isMe,
                    onTap: () {
                      if (mediaType == 'image' && mediaUrl != null) {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ImageGallery(
                              imageUrls: [mediaUrl],
                              initialIndex: 0,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  // Gradient overlay for better text visibility (ignore pointer to allow taps through)
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
                  // Media type indicator
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
                            formatMessageTime(widget.message.createdAt),
                            style: context.captionSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.isMe && widget.message.read) ...[
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
          if (hasText)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isMe ? _myMessageColor(context) : _otherMessageColor(context),
                borderRadius: _bubbleRadius(),
                boxShadow: AppShadows.sm,
              ),
              child: LinkifiedText(
                text: widget.message.message!,
                style: context.bodyMedium.copyWith(
                  color: widget.isMe ? _myTextColor(context) : _otherTextColor(context),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build a clean location message bubble (without gradient overlays)
  Widget _buildLocationMessageBubble(BuildContext context, bool hasText) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Story reference preview
          if (widget.message.storyReference != null) _buildStoryReferencePreview(),
          // Reply preview if this message is a reply
          if (widget.message.replyTo != null) _buildReplyPreview(),

          // Location card
          MediaMessageWidget(
            media: widget.message.media!,
            isSentByMe: widget.isMe,
            onTap: () {}, // Location widget handles its own tap
          ),

          // Text caption below location
          if (hasText)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isMe ? _myMessageColor(context) : _otherMessageColor(context),
                borderRadius: _bubbleRadius(),
              ),
              child: LinkifiedText(
                text: widget.message.message!,
                style: context.bodyMedium.copyWith(
                  color: widget.isMe ? _myTextColor(context) : _otherTextColor(context),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatMessageTime(widget.message.createdAt),
                  style: context.captionSmall.copyWith(
                    color: _timestampColor(context),
                  ),
                ),
                if (widget.isMe && widget.message.read) ...[
                  Spacing.hGapXS,
                  Icon(Icons.done_all, size: 14, color: AppColors.info),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SingleCommunity(community: widget.message.sender),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    _hideReactionPicker();
    HapticFeedback.mediumImpact();

    // Use the bubble key to get position of actual message bubble, not the full row
    final RenderBox? renderBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasText = widget.message.message != null && widget.message.message!.isNotEmpty;

    // Check if user can edit (within 15 minutes)
    bool canEdit = false;
    if (widget.isMe && !widget.message.isDeleted && widget.message.type == 'text') {
      try {
        final diff = DateTime.now().difference(DateTime.parse(widget.message.createdAt));
        canEdit = diff.inMinutes < 15;
      } catch (_) {}
    }

    // Build menu items list: Reply, Copy, Correct, Translate, Pin/Unpin, Edit, Delete
    final menuItems = <_ContextMenuItem>[];

    menuItems.add(_ContextMenuItem(
      icon: Icons.reply_rounded,
      label: 'Reply',
      onTap: () {
        _hideReactionPicker();
        widget.onReply?.call(widget.message);
      },
    ));

    if (hasText) {
      menuItems.add(_ContextMenuItem(
        icon: Icons.copy_rounded,
        label: 'Copy',
        onTap: () {
          _hideReactionPicker();
          Clipboard.setData(ClipboardData(text: widget.message.message!));
          showChatSnackBar(context, message: 'Copied', type: ChatSnackBarType.success);
        },
      ));
    }

    if (hasText && !widget.isMe) {
      menuItems.add(_ContextMenuItem(
        icon: Icons.spellcheck_rounded,
        label: 'Correct',
        onTap: () {
          _hideReactionPicker();
          showCorrectionBottomSheet(
            context,
            messageId: widget.message.id,
            originalText: widget.message.message!,
            senderName: widget.otherUserName,
          );
        },
      ));
    }

    if (hasText) {
      menuItems.add(_ContextMenuItem(
        icon: Icons.translate_rounded,
        label: 'Translate',
        onTap: () {
          _hideReactionPicker();
          _showTranslation(context);
        },
      ));
    }

    menuItems.add(_ContextMenuItem(
      icon: widget.message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
      label: widget.message.isPinned ? 'Unpin' : 'Pin',
      onTap: () {
        _hideReactionPicker();
        if (widget.message.isPinned) {
          widget.onUnpin?.call(widget.message);
        } else {
          widget.onPin?.call(widget.message);
        }
      },
    ));

    if (canEdit) {
      menuItems.add(_ContextMenuItem(
        icon: Icons.edit_rounded,
        label: 'Edit',
        onTap: () {
          _hideReactionPicker();
          widget.onEdit?.call(widget.message);
        },
      ));
    }

    if (widget.isMe && !widget.message.isDeleted) {
      menuItems.add(_ContextMenuItem(
        icon: Icons.delete_rounded,
        label: 'Delete',
        isDestructive: true,
        onTap: () {
          _hideReactionPicker();
          widget.onDelete?.call(widget.message);
        },
      ));
    }

    // Calculate menu size
    const itemHeight = 44.0;
    const menuPaddingV = 8.0;
    final menuHeight = (menuItems.length * itemHeight) + (menuPaddingV * 2);
    const menuWidth = 160.0;

    // Position: below the message bubble, aligned to same side
    double menuX;
    if (widget.isMe) {
      // My bubble is right-aligned → menu right-aligned below
      menuX = (position.dx + size.width - menuWidth).clamp(8.0, screenSize.width - menuWidth - 8);
    } else {
      // Other's bubble is left-aligned → menu left-aligned below
      menuX = position.dx.clamp(8.0, screenSize.width - menuWidth - 8);
    }

    // Vertical: directly below the bubble with small gap, clamped to screen
    final menuY = (position.dy + size.height + 6).clamp(40.0, screenSize.height - menuHeight - 40);

    _reactionPickerOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Scrim - tap to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideReactionPicker,
              child: Container(color: AppColors.black.withValues(alpha: 0.3)),
            ),
          ),
          // Vertical context menu
          Positioned(
            left: menuX,
            top: menuY,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: menuWidth,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: menuPaddingV),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: menuItems.map((item) {
                    final color = item.isDestructive
                        ? AppColors.error
                        : (isDark ? AppColors.gray200 : AppColors.gray900);
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        item.onTap();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: itemHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(item.icon, size: 20, color: color),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reactionPickerOverlay!);
  }

  bool _isSticker(String text) {
    // Check if it's a single emoji or short emoji sequence (1-3 emojis)
    // Unicode ranges for emojis including variation selectors and skin tones
    final emojiPattern = RegExp(
      r'^(?:[\u{1f300}-\u{1f9ff}]|[\u{2600}-\u{27bf}]|[\u{2300}-\u{23ff}]|[\u{2b50}]|[\u{2764}]|[\u{fe0f}]|[\u{200d}]|[\u{1f3fb}-\u{1f3ff}])+$',
      unicode: true,
    );
    // Also check it's short enough (max ~12 chars for compound emoji like family)
    return text.length <= 12 && emojiPattern.hasMatch(text);
  }

  /// Check if message is a wave sticker (👋 emoji variants)
  bool _isWaveSticker(String text) {
    final trimmed = text.trim();
    // Check for wave hand emoji (with or without skin tone modifiers)
    return trimmed == '👋' ||
        trimmed == '👋🏻' ||
        trimmed == '👋🏼' ||
        trimmed == '👋🏽' ||
        trimmed == '👋🏾' ||
        trimmed == '👋🏿';
  }

  /// Build a compact wave sticker card with "Hi!" greeting
  Widget _buildWaveStickerCard(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isMe
                ? [const Color(0xFFFFE082), const Color(0xFFFFCA28)] // Gold/yellow gradient
                : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)], // Light blue gradient
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
            // Waving hand
            const Text(
              '👋',
              style: TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 8),
            // "Hi!" text
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

  /// Check if message can be edited (within 15 minutes)
  bool _canEditMessage() {
    if (widget.message.isDeleted || widget.message.media != null) {
      return false; // Cannot edit deleted messages or messages with media
    }

    try {
      final messageTime = parseToKoreaTime(widget.message.createdAt);
      final now = getKoreaNow();
      final difference = now.difference(messageTime);
      return difference.inMinutes < 15;
    } catch (e) {
      return false;
    }
  }
}

class _ContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
