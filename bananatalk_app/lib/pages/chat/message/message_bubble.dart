import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/message_reaction_widget.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/forwarded_message_indicator.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/widgets/translation_bottom_sheet.dart';
import 'package:bananatalk_app/widgets/correction_bottom_sheet.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import '../header/user_avatar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/chat/message/message_context_menu_item.dart';
import 'message_bubble/text_message_view.dart';
import 'message_bubble/image_message_view.dart';
import 'message_bubble/voice_message_view.dart';
import 'message_bubble/gif_message_view.dart';

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
    super.key,
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
  });

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

  // ---------- Theme-aware colour helpers ----------

  Color _myMessageColor(BuildContext context) =>
      context.isDarkMode ? AppColors.chatBubbleMineDark : AppColors.chatBubbleMine;
  Color _otherMessageColor(BuildContext context) =>
      context.isDarkMode ? AppColors.chatBubbleOtherDark : AppColors.chatBubbleOther;
  Color _myTextColor(BuildContext context) => AppColors.chatTextMine;
  Color _otherTextColor(BuildContext context) =>
      context.isDarkMode ? AppColors.white : AppColors.chatTextOther;
  Color _timestampColor(BuildContext context) => context.textSecondary;
  Color _sendingColor(BuildContext context) => context.textSecondary;
  Color _failedColor(BuildContext context) => AppColors.error;

  // ---------- Bubble shape ----------

  BorderRadius _bubbleRadius() {
    const double big = 18.0;
    const double small = 4.0;

    if (widget.isMe) {
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return AppRadius.chatBubbleMine;
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(big),
          topRight: Radius.circular(big),
          bottomLeft: Radius.circular(big),
          bottomRight: Radius.circular(big),
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
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return AppRadius.chatBubbleOther;
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(big),
          topRight: Radius.circular(big),
          bottomLeft: Radius.circular(big),
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

  // ---------- Lifecycle ----------

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

  // ---------- Swipe-to-reply ----------

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.isSelectionMode) return;
    final newOffset =
        (_swipeOffset + details.delta.dx).clamp(-_swipeThreshold * 1.5, 0.0);
    setState(() {
      _swipeOffset = newOffset;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isSelectionMode) return;
    if (_swipeOffset <= -_swipeThreshold) {
      HapticFeedback.mediumImpact();
      widget.onReply?.call(widget.message);
    }
    _swipeAnimation =
        Tween<double>(begin: _swipeOffset, end: 0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOut),
    );
    _swipeAnimController.forward(from: 0);
  }

  // ---------- Reaction picker ----------

  void _showReactionPicker(BuildContext context) {
    _hideReactionPicker();
    HapticFeedback.lightImpact();

    final RenderBox? renderBox =
        _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    const pickerHeight = 56.0;
    const pickerWidth = 260.0;
    final pickerY = position.dy - pickerHeight - 10;

    double pickerX;
    if (widget.isMe) {
      pickerX = (screenWidth - pickerWidth - 16)
          .clamp(16.0, screenWidth - pickerWidth - 16);
    } else {
      pickerX = 56.0;
    }

    _reactionPickerOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
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

    Overlay.of(context).insert(_reactionPickerOverlay!);
    Future.delayed(const Duration(seconds: 5), _hideReactionPicker);
  }

  void _hideReactionPicker() {
    _reactionPickerOverlay?.remove();
    _reactionPickerOverlay = null;
  }

  Future<void> _handleReactionTap(String emoji) async {
    if (_currentUserId == null) return;

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
        await messageService.removeReaction(
          messageId: widget.message.id,
          emoji: emoji,
        );
      } else {
        await messageService.addReaction(
          messageId: widget.message.id,
          emoji: emoji,
        );
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context,
            message: 'Failed to update reaction: $e',
            type: ChatSnackBarType.error);
      }
    }
  }

  // ---------- Translation ----------

  void _showTranslation(BuildContext context) {
    final text = widget.message.message;
    if (text == null || text.isEmpty) return;
    showTranslationBottomSheet(
      context,
      messageId: widget.message.id,
      originalText: text,
    );
  }

  // ---------- Profile navigation ----------

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SingleCommunity(community: widget.message.sender),
      ),
    );
  }

  // ---------- Sending status ----------

  Widget _buildSendingStatus() {
    final status = widget.message.sendingStatus;

    if (status == MessageSendingStatus.none) return const SizedBox.shrink();

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
                valueColor:
                    AlwaysStoppedAnimation<Color>(_sendingColor(context)),
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
              Icon(Icons.error_outline, size: 12, color: _failedColor(context)),
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Message failed to send',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(),
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.delete_outline, color: AppColors.error),
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

  // ---------- Context menu ----------

  void _showContextMenu(BuildContext context) {
    _hideReactionPicker();
    HapticFeedback.mediumImpact();

    final RenderBox? renderBox =
        _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasText = widget.message.message != null &&
        widget.message.message!.isNotEmpty;

    bool canEdit = false;
    if (widget.isMe &&
        !widget.message.isDeleted &&
        widget.message.type == 'text') {
      try {
        final diff = DateTime.now()
            .difference(DateTime.parse(widget.message.createdAt));
        canEdit = diff.inMinutes < 15;
      } catch (_) {}
    }

    final menuItems = <MessageContextMenuItem>[];

    menuItems.add(MessageContextMenuItem(
      icon: Icons.reply_rounded,
      label: 'Reply',
      onTap: () {
        _hideReactionPicker();
        widget.onReply?.call(widget.message);
      },
    ));

    if (hasText) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.copy_rounded,
        label: 'Copy',
        onTap: () {
          _hideReactionPicker();
          Clipboard.setData(ClipboardData(text: widget.message.message!));
          showChatSnackBar(context,
              message: 'Copied', type: ChatSnackBarType.success);
        },
      ));
    }

    if (hasText && !widget.isMe) {
      menuItems.add(MessageContextMenuItem(
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
      menuItems.add(MessageContextMenuItem(
        icon: Icons.translate_rounded,
        label: 'Translate',
        onTap: () {
          _hideReactionPicker();
          _showTranslation(context);
        },
      ));
    }

    menuItems.add(MessageContextMenuItem(
      icon: widget.message.isPinned
          ? Icons.push_pin_outlined
          : Icons.push_pin_rounded,
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
      menuItems.add(MessageContextMenuItem(
        icon: Icons.edit_rounded,
        label: 'Edit',
        onTap: () {
          _hideReactionPicker();
          widget.onEdit?.call(widget.message);
        },
      ));
    }

    if (widget.isMe && !widget.message.isDeleted) {
      menuItems.add(MessageContextMenuItem(
        icon: Icons.delete_rounded,
        label: 'Delete',
        isDestructive: true,
        onTap: () {
          _hideReactionPicker();
          widget.onDelete?.call(widget.message);
        },
      ));
    }

    const itemHeight = 44.0;
    const menuPaddingV = 8.0;
    final menuHeight =
        (menuItems.length * itemHeight) + (menuPaddingV * 2);
    const menuWidth = 160.0;

    double menuX;
    if (widget.isMe) {
      menuX = (position.dx + size.width - menuWidth)
          .clamp(8.0, screenSize.width - menuWidth - 8);
    } else {
      menuX = position.dx.clamp(8.0, screenSize.width - menuWidth - 8);
    }

    final menuY = (position.dy + size.height + 6)
        .clamp(40.0, screenSize.height - menuHeight - 40);

    _reactionPickerOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideReactionPicker,
              child:
                  Container(color: AppColors.black.withValues(alpha: 0.3)),
            ),
          ),
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
                padding:
                    const EdgeInsets.symmetric(vertical: menuPaddingV),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: menuItems.map((item) {
                    final color = item.isDestructive
                        ? AppColors.error
                        : (isDark
                            ? AppColors.gray200
                            : AppColors.gray900);
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        item.onTap();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: itemHeight,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
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

  // ---------- Message content dispatcher ----------

  Widget _buildMessageContent(Message msg) {
    // Voice / audio: has media with voice|audio type
    if (msg.media != null &&
        (msg.media!.type == 'voice' || msg.media!.type == 'audio')) {
      return VoiceMessageView(
        message: msg,
        isMe: widget.isMe,
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
      );
    }

    // GIF: type field is 'gif' and message text is a URL
    if (msg.type == 'gif') {
      return GifMessageView(
        message: msg,
        isMe: widget.isMe,
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
      );
    }

    // Image / video / document / location: has media (non-voice)
    if (msg.media != null) {
      return ImageMessageView(
        message: msg,
        isMe: widget.isMe,
        myMessageColor: _myMessageColor(context),
        otherMessageColor: _otherMessageColor(context),
        myTextColor: _myTextColor(context),
        otherTextColor: _otherTextColor(context),
        timestampColor: _timestampColor(context),
        bubbleRadius: _bubbleRadius(),
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
      );
    }

    // Text (default — includes stickers, wave sticker, link preview)
    if (msg.type == 'text' || msg.type.isEmpty) {
      return TextMessageView(
        message: msg,
        isMe: widget.isMe,
        myMessageColor: _myMessageColor(context),
        otherMessageColor: _otherMessageColor(context),
        myTextColor: _myTextColor(context),
        otherTextColor: _otherTextColor(context),
        bubbleRadius: _bubbleRadius(),
        onReplyTap: widget.onReplyTap,
        onLongPress: () => _showContextMenu(context),
      );
    }

    // Unknown type — safe fallback
    return _FallbackMessageView(message: msg);
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final swipeProgress = _swipeOffset.abs();
    final replyIconOpacity =
        (swipeProgress / _swipeThreshold).clamp(0.0, 1.0);
    final replyIconScale =
        (0.5 + (replyIconOpacity * 0.5)).clamp(0.5, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onLongPress: widget.isSelectionMode
          ? () {
              widget.onSelectionChanged
                  ?.call(widget.message, !widget.isSelected);
            }
          : () => _showContextMenu(context),
      onDoubleTap:
          widget.isSelectionMode ? null : () => _showContextMenu(context),
      onTap: widget.isSelectionMode
          ? () {
              widget.onSelectionChanged
                  ?.call(widget.message, !widget.isSelected);
            }
          : () => _showReactionPicker(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Reply icon (shown while swiping left)
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
                vertical: (!widget.isFirstInGroup || !widget.isLastInGroup)
                    ? 1
                    : 3,
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
                    mainAxisAlignment: widget.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Selection checkbox
                      if (widget.isSelectionMode) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Checkbox(
                            value: widget.isSelected,
                            onChanged: (value) {
                              widget.onSelectionChanged?.call(
                                  widget.message, value ?? false);
                            },
                          ),
                        ),
                      ],

                      // Avatar for other user
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

                      // Timestamp + status (left of my messages)
                      if (widget.isMe &&
                          !widget.isSelectionMode &&
                          widget.isLastInGroup)
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 4, bottom: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildSendingStatus(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatMessageTime(
                                        widget.message.createdAt),
                                    style: context.captionSmall.copyWith(
                                      color: widget.message.isFailed
                                          ? _failedColor(context)
                                          : _timestampColor(context),
                                    ),
                                  ),
                                  if (widget.message.sendingStatus ==
                                      MessageSendingStatus.none) ...[
                                    Spacing.hGapXXS,
                                    Icon(
                                      widget.message.read
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: widget.message.read
                                          ? _myMessageColor(context)
                                          : _timestampColor(context),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Message bubble content
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Column(
                            crossAxisAlignment: widget.isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (widget.message.isForwarded)
                                ForwardedMessageIndicator(
                                  forwardedFrom:
                                      widget.message.forwardedFrom,
                                  isMe: widget.isMe,
                                ),
                              Stack(
                                key: _bubbleKey,
                                children: [
                                  _buildMessageContent(widget.message),
                                  // Pin indicator
                                  if (widget.message.isPinned)
                                    Positioned(
                                      top: 4,
                                      right: widget.isMe ? 4 : null,
                                      left: widget.isMe ? null : 4,
                                      child: Icon(
                                        Icons.push_pin_rounded,
                                        size: 14,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Timestamp (right of other user's messages)
                      if (!widget.isMe &&
                          !widget.isSelectionMode &&
                          widget.isLastInGroup)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text(
                            formatMessageTime(widget.message.createdAt),
                            style: context.captionSmall.copyWith(
                              color: _timestampColor(context),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Reactions below the message row
                  if (widget.message.reactions.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2,
                        left: !widget.isMe && !widget.isSelectionMode
                            ? 44
                            : 0,
                      ),
                      child: MessageReactionWidget(
                        reactions: widget.message.reactions,
                        currentUserId: _currentUserId,
                        onReactionTap: (emoji) =>
                            _handleReactionTap(emoji),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Fallback for unknown message types ----------

class _FallbackMessageView extends StatelessWidget {
  final Message message;

  const _FallbackMessageView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.containerColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: context.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Unsupported message type',
            style: context.bodySmall.copyWith(
              color: context.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
