import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/media_message_widget.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
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
import 'package:bananatalk_app/pages/chat/message_actions_bottom_sheet.dart';
import 'package:bananatalk_app/widgets/forwarded_message_indicator.dart';
import 'user_avatar.dart';

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
  }) : super(key: key);

  @override
  ConsumerState<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends ConsumerState<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _reactionPickerOverlay;
  String? _currentUserId;

  // Swipe-to-reply state
  double _swipeOffset = 0;
  static const double _swipeThreshold = 60.0;
  late AnimationController _swipeAnimController;
  late Animation<double> _swipeAnimation;

  // Theme-aware chat colors - Light and modern design
  Color _myMessageColor(BuildContext context) => AppColors.chatBubbleMine;
  Color _otherMessageColor(BuildContext context) => context.isDarkMode ? AppColors.gray800 : AppColors.chatBubbleOther;
  Color _myTextColor(BuildContext context) => AppColors.chatTextMine;
  Color _otherTextColor(BuildContext context) => context.isDarkMode ? AppColors.white : AppColors.chatTextOther;
  Color _timestampColor(BuildContext context) => context.textSecondary;
  Color _replyBorderColor(BuildContext context) => AppColors.primary;
  Color _sendingColor(BuildContext context) => context.textSecondary;
  Color _failedColor(BuildContext context) => AppColors.error;

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
      onTap: widget.isSelectionMode
          ? () {
              if (widget.onSelectionChanged != null) {
                widget.onSelectionChanged!(widget.message, !widget.isSelected);
              }
            }
          : () {
              // Single tap - show emoji picker (Telegram style)
              if (!hasMedia) {
                _showReactionPicker(context);
              }
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
                            ? Colors.white
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
                vertical: 3,
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
              child: Row(
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
              UserAvatar(
                profilePicture: widget.otherUserPicture,
                userName: widget.otherUserName,
                radius: 18,
              ),
              Spacing.hGapSM,
            ],

            // Timestamp and sending status (left of my messages)
            if (widget.isMe && !widget.isSelectionMode)
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
                    // Reactions below message
                    if (widget.message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: MessageReactionWidget(
                          reactions: widget.message.reactions,
                          currentUserId: _currentUserId,
                          onReactionTap: (emoji) => _handleReactionTap(emoji),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Timestamp (right of other user's messages)
            if (!widget.isMe && !widget.isSelectionMode)
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
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    // Show reaction picker above the message
    final overlay = Overlay.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final pickerHeight = 60.0;
    final pickerY = position.dy - pickerHeight - 10;
    
    _reactionPickerOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + (size.width / 2) - 120,
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
    );
    
    overlay.insert(_reactionPickerOverlay!);
    
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _hideReactionPicker();
    });
  }

  void _hideReactionPicker() {
    _reactionPickerOverlay?.remove();
    _reactionPickerOverlay = null;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          widget.message.message!,
          style: const TextStyle(fontSize: 64), // Larger emoji
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Reply preview if this message is a reply
          if (widget.message.replyTo != null) _buildReplyPreview(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isMe ? _myMessageColor(context) : _otherMessageColor(context),
              borderRadius: widget.isMe ? AppRadius.chatBubbleMine : AppRadius.chatBubbleOther,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  Text(
                    widget.message.message!,
                    style: context.bodyMedium.copyWith(
                      color: widget.isMe ? _myTextColor(context) : _otherTextColor(context),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
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
              ],
            ),
          ),
        ],
      ),
    );
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
      borderColor = Colors.white.withValues(alpha: 0.9);
      backgroundColor = Colors.black.withValues(alpha: 0.15);
      nameColor = Colors.white;
      textColor = Colors.white.withValues(alpha: 0.9);
    } else {
      // Other's message bubble
      borderColor = isReplyFromMe ? AppColors.primary : const Color(0xFF5B9BD5);
      backgroundColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : borderColor.withValues(alpha: 0.08);
      nameColor = borderColor;
      textColor = isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87;
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
            MaterialPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: [mediaUrl],
                initialIndex: 0,
              ),
            ),
          );
        } else if (mediaType == 'video' && mediaUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
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
                          MaterialPageRoute(
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
                borderRadius: widget.isMe ? AppRadius.chatBubbleMine : AppRadius.chatBubbleOther,
                boxShadow: AppShadows.sm,
              ),
              child: Text(
                widget.message.message!,
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
                borderRadius: widget.isMe ? AppRadius.chatBubbleMine : AppRadius.chatBubbleOther,
              ),
              child: Text(
                widget.message.message!,
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

  void _showContextMenu(BuildContext context) {
    // Use the new Telegram-style bottom sheet
    showMessageActionsBottomSheet(
      context,
      message: widget.message,
      isMe: widget.isMe,
      currentUserId: _currentUserId ?? '',
      onReply: () => widget.onReply?.call(widget.message),
      onForward: () => widget.onForward?.call(widget.message),
      onEdit: () => widget.onEdit?.call(widget.message),
      onCopy: () {}, // Handled inside the bottom sheet
      onPin: () {
        if (widget.message.isPinned) {
          widget.onUnpin?.call(widget.message);
        } else {
          widget.onPin?.call(widget.message);
        }
      },
      onDelete: () => widget.onDelete?.call(widget.message),
      onReaction: (emoji) => _handleReactionTap(emoji),
    );
  }

  List<PopupMenuEntry<String>> _buildContextMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];
    
    // Copy (for text messages)
    if (widget.message.message != null && widget.message.message!.isNotEmpty) {
      items.add(
        PopupMenuItem<String>(
          value: 'copy',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: Spacing.paddingSM,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: const Icon(Icons.content_copy_rounded, size: 18, color: AppColors.info),
              ),
              Spacing.hGapMD,
              Text(AppLocalizations.of(context)!.copy, style: context.bodyMedium),
            ],
          ),
        ),
      );
    }
    
    // Reply
    items.add(
      PopupMenuItem<String>(
        value: 'reply',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: Spacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: const Icon(Icons.reply_rounded, size: 18, color: AppColors.success),
            ),
            Spacing.hGapMD,
            Text(AppLocalizations.of(context)!.reply, style: context.bodyMedium),
          ],
        ),
      ),
    );
    
    // Edit (only for my messages, within 15 minutes, text only, not deleted)
    if (widget.isMe &&
        widget.message.message != null &&
        !widget.message.isDeleted &&
        widget.message.media == null &&
        _canEditMessage()) {
      items.add(
        PopupMenuItem<String>(
          value: 'edit',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: Spacing.paddingSM,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: const Icon(Icons.edit_rounded, size: 18, color: AppColors.warning),
              ),
              Spacing.hGapMD,
              Text(AppLocalizations.of(context)!.edit, style: context.bodyMedium),
            ],
          ),
        ),
      );
    }
    
    // Forward
    items.add(
      PopupMenuItem<String>(
        value: 'forward',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: Spacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: const Icon(Icons.forward_rounded, size: 18, color: AppColors.accent),
            ),
            Spacing.hGapMD,
            Text(AppLocalizations.of(context)!.forward, style: context.bodyMedium),
          ],
        ),
      ),
    );
    
    // Pin/Unpin (for all messages)
    items.add(
      PopupMenuItem<String>(
        value: widget.message.isPinned ? 'unpin' : 'pin',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: Spacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: Icon(
                widget.message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18,
                color: AppColors.secondaryDark,
              ),
            ),
            Spacing.hGapMD,
            Text(
              widget.message.isPinned ? 'Unpin' : 'Pin',
              style: context.bodyMedium.copyWith(color: AppColors.secondaryDark),
            ),
          ],
        ),
      ),
    );
    
    // Divider
    items.add(const PopupMenuDivider(height: 8));
    
    // Report (only for other user's messages)
    if (!widget.isMe) {
      items.add(
        PopupMenuItem<String>(
          value: 'report',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: Spacing.paddingSM,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: const Icon(Icons.flag_rounded, size: 18, color: AppColors.warning),
              ),
              Spacing.hGapMD,
              Text('Report', style: context.bodyMedium.copyWith(color: AppColors.warning)),
            ],
          ),
        ),
      );
    }
    
    // Delete (only for my messages, not deleted)
    if (widget.isMe && !widget.message.isDeleted) {
      items.add(
        PopupMenuItem<String>(
          value: 'delete',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: Spacing.paddingSM,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
              ),
              Spacing.hGapMD,
              Text('Delete', style: context.bodyMedium.copyWith(color: AppColors.error)),
            ],
          ),
        ),
      );
    }
    
    // More options
    items.add(
      PopupMenuItem<String>(
        value: 'more',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: Spacing.paddingSM,
              decoration: BoxDecoration(
                color: context.containerColor,
                borderRadius: AppRadius.borderSM,
              ),
              child: Icon(Icons.more_horiz_rounded, size: 18, color: context.textSecondary),
            ),
            Spacing.hGapMD,
            Text(AppLocalizations.of(context)!.moreOptions, style: context.bodyMedium),
          ],
        ),
      ),
    );
    
    return items;
  }

  void _handleContextMenuAction(BuildContext context, String? value) {
    if (value == null) return;
    
    switch (value) {
      case 'copy':
        if (widget.message.message != null && widget.message.message!.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: widget.message.message!));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.white),
                  Spacing.hGapMD,
                  const Text('Message copied'),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.gray900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderMD,
              ),
            ),
          );
        }
        break;
        
      case 'reply':
        if (widget.onReply != null) {
          widget.onReply!(widget.message);
        }
        break;
        
      case 'edit':
        if (widget.isMe && widget.onEdit != null) {
          widget.onEdit!(widget.message);
        }
        break;
        
      case 'pin':
        if (widget.onPin != null) {
          widget.onPin!(widget.message);
        }
        break;
        
      case 'unpin':
        if (widget.onUnpin != null) {
          widget.onUnpin!(widget.message);
        }
        break;
        
      case 'forward':
        if (widget.onForward != null) {
          widget.onForward!(widget.message);
        }
        break;
        
      case 'report':
        if (!widget.isMe) {
          showDialog(
            context: context,
            builder: (context) => ReportDialog(
              type: 'message',
              reportedId: widget.message.id,
              reportedUserId: widget.message.sender.id,
            ),
          );
        }
        break;
        
      case 'delete':
        if (widget.isMe && widget.onDelete != null) {
          widget.onDelete!(widget.message);
        }
        break;
        
      case 'more':
        // Show full bottom sheet with all options
        _showMessageActions(context);
        break;
    }
  }

  void _showMessageActions(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.containerHighColor,
                    borderRadius: AppRadius.borderXS,
                  ),
                ),

                // Message preview
                Container(
                  padding: Spacing.paddingLG,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: AppRadius.borderLG,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                widget.isMe ? _myMessageColor(context) : context.containerHighColor,
                            child: Text(
                              widget.isMe
                                  ? 'You'[0]
                                  : widget.otherUserName.isNotEmpty
                                      ? widget.otherUserName[0].toUpperCase()
                                      : '?',
                              style: context.labelMedium.copyWith(
                                color: widget.isMe ? AppColors.white : context.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Spacing.hGapMD,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isMe ? 'You' : widget.otherUserName,
                                  style: context.titleSmall,
                                ),
                                Text(
                                  formatFullDateTime(widget.message.createdAt),
                                  style: context.caption,
                                ),
                              ],
                            ),
                          ),
                          if (widget.message.read && widget.isMe)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: AppRadius.borderMD,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.done_all,
                                    size: 14,
                                    color: AppColors.info,
                                  ),
                                  Spacing.hGapXS,
                                  Text(
                                    'Read',
                                    style: context.captionSmall.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (widget.message.message != null &&
                          widget.message.message!.isNotEmpty) ...[
                        Spacing.gapMD,
                        Text(
                          widget.message.message!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Action buttons
                if (widget.message.message != null && widget.message.message!.isNotEmpty)
                  _buildActionTile(
                    context,
                    icon: Icons.content_copy_rounded,
                    label: AppLocalizations.of(context)!.copy,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.message.message!));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.white),
                              Spacing.hGapMD,
                              const Text('Message copied'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.gray900,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                        ),
                      );
                    },
                  ),

                if (widget.isMe && 
                    widget.message.message != null && 
                    !widget.message.isDeleted &&
                    widget.message.media == null &&
                    _canEditMessage())
                  _buildActionTile(
                    context,
                    icon: Icons.edit_rounded,
                    label: AppLocalizations.of(context)!.edit,
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onEdit != null) {
                        widget.onEdit!(widget.message);
                      }
                    },
                  ),

                _buildActionTile(
                  context,
                  icon: Icons.reply_rounded,
                  label: AppLocalizations.of(context)!.reply,
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onReply != null) {
                      widget.onReply!(widget.message);
                    }
                  },
                ),

                _buildActionTile(
                  context,
                  icon: Icons.forward_rounded,
                  label: AppLocalizations.of(context)!.forward,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forward feature coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                _buildActionTile(
                  context,
                  icon: widget.message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  label: widget.message.isPinned ? 'Unpin' : 'Pin',
                  color: AppColors.secondaryDark,
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.message.isPinned) {
                      if (widget.onUnpin != null) {
                        widget.onUnpin!(widget.message);
                      }
                    } else {
                      if (widget.onPin != null) {
                        widget.onPin!(widget.message);
                      }
                    }
                  },
                ),

                if (!widget.isMe)
                  _buildActionTile(
                    context,
                    icon: Icons.flag_rounded,
                    label: 'Report',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => ReportDialog(
                          type: 'message',
                          reportedId: widget.message.id,
                          reportedUserId: widget.message.sender.id,
                        ),
                      );
                    },
                  ),

                if (widget.isMe && !widget.message.isDeleted)
                  _buildActionTile(
                    context,
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onDelete != null) {
                        widget.onDelete!(widget.message);
                      }
                    },
                  ),

                Spacing.gapLG,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? context.textPrimary, size: 22),
            Spacing.hGapLG,
            Text(
              label,
              style: context.bodyLarge.copyWith(
                color: color ?? context.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
