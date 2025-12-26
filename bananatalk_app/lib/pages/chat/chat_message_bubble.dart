import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/media_message_widget.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/message_reaction_widget.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'user_avatar.dart';

class ChatMessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;
  final String otherUserName;
  final String? otherUserPicture;
  final Function(Message)? onDelete;
  final Function(Message)? onEdit;
  final Function(Message)? onReply;
  final Message? replyToMessage;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(Message, bool)? onSelectionChanged;
  final Function(Message)? onPin;
  final Function(Message)? onUnpin;
  final Function(Message)? onForward;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.otherUserName,
    this.otherUserPicture,
    this.onDelete,
    this.onEdit,
    this.onReply,
    this.replyToMessage,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionChanged,
    this.onPin,
    this.onUnpin,
    this.onForward,
  }) : super(key: key);

  @override
  ConsumerState<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends ConsumerState<ChatMessageBubble> {
  OverlayEntry? _reactionPickerOverlay;
  String? _currentUserId;

  // Modern chat colors (HelloTalk/KakaoTalk inspired)
  static const Color myMessageColor = Color(0xFF007AFF); // iOS blue
  static const Color otherMessageColor = Color(0xFFF0F0F0); // Light gray
  static const Color myTextColor = Color(0xFFFFFFFF); // White
  static const Color otherTextColor = Color(0xFF000000); // Black
  static const Color timestampColor = Color(0xFF8E8E93); // Gray
  static const Color replyBorderColor = Color(0xFF007AFF); // Blue
  static const Color backgroundColor = Color(0xFFF2F2F7); // System gray 6

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _hideReactionPicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = widget.message.media != null;
    final hasText = widget.message.message != null && widget.message.message!.isNotEmpty;

    return GestureDetector(
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
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: 3,
          horizontal: widget.isSelectionMode ? 4 : 16,
        ),
        decoration: widget.isSelectionMode
            ? BoxDecoration(
                color: widget.isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 8),
            ],

            // Timestamp and read status (left of my messages)
            if (widget.isMe && !widget.isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!widget.message.read)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30), // iOS red
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      formatMessageTime(widget.message.createdAt),
                      style: const TextStyle(
                        color: timestampColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
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
                    hasMedia
                        ? _buildMediaMessage(context, hasText)
                        : _buildTextMessage(context, hasText),
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
                  style: const TextStyle(
                    color: timestampColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
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
          color: widget.isMe 
              ? Colors.grey[300]?.withOpacity(0.5)
              : Colors.grey[200]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'This message was deleted',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
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
          if (widget.replyToMessage != null) _buildReplyPreview(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isMe ? myMessageColor : otherMessageColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                bottomRight: Radius.circular(widget.isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  Text(
                    widget.message.message!,
                    style: TextStyle(
                      color: widget.isMe ? myTextColor : otherTextColor,
                      fontSize: 16,
                      height: 1.35,
                      letterSpacing: -0.3,
                    ),
                  ),
                if (widget.message.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'edited',
                      style: TextStyle(
                        color: (widget.isMe ? myTextColor : otherTextColor)
                            .withOpacity(0.6),
                        fontSize: 10,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: widget.isMe ? Colors.white : replyBorderColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.replyToMessage!.sender.id == widget.message.sender.id
                ? 'You'
                : widget.otherUserName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isMe ? Colors.white : replyBorderColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.replyToMessage!.message ?? '📷 Media',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: widget.isMe ? Colors.white.withOpacity(0.8) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessage(BuildContext context, bool hasText) {
    // Show deleted message placeholder for media messages too
    if (widget.message.isDeleted && widget.message.deletedForEveryone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isMe 
              ? Colors.grey[300]?.withOpacity(0.5)
              : Colors.grey[200]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'This message was deleted',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    final mediaType = widget.message.media!.type;
    final mediaUrl = widget.message.media!.url;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      onTap: () {
        // Open media viewer
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
        } else if (mediaType == 'video') {
          // TODO: Open video player
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video player coming soon'),
              duration: Duration(seconds: 2),
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
          if (widget.replyToMessage != null) _buildReplyPreview(),

          // Media container with modern design
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                  // Gradient overlay for better text visibility
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Media type indicator
                  if (mediaType == 'video')
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
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
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatMessageTime(widget.message.createdAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.isMe && widget.message.read) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.done_all,
                              color: Colors.blue,
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
                color: widget.isMe ? myMessageColor : otherMessageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                  bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                widget.message.message!,
                style: TextStyle(
                  color: widget.isMe ? myTextColor : otherTextColor,
                  fontSize: 16,
                  height: 1.35,
                  letterSpacing: -0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    // Get the RenderBox for positioning
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    
    // Show popup menu with better positioning
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      // Fallback to bottom sheet if positioning fails
      _showMessageActions(context);
      return;
    }
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate menu position - appear near the message
    final menuWidth = 200.0;
    final menuHeight = 300.0;
    double menuX;
    
    if (widget.isMe) {
      // For my messages, show menu on the left side
      menuX = position.dx - menuWidth - 10;
      if (menuX < 10) menuX = 10; // Ensure it doesn't go off screen
    } else {
      // For other messages, show menu on the right side
      menuX = position.dx + size.width + 10;
      if (menuX + menuWidth > screenWidth - 10) {
        menuX = screenWidth - menuWidth - 10;
      }
    }
    
    final menuY = position.dy - 50;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        menuX,
        menuY,
        screenWidth - menuX - menuWidth,
        MediaQuery.of(context).size.height - menuY - menuHeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      color: Colors.white,
      items: _buildContextMenuItems(context),
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(context, value);
      }
    });
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.content_copy_rounded, size: 18, color: Colors.blue[700]),
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.copy, style: const TextStyle(fontSize: 15)),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.reply_rounded, size: 18, color: Colors.green[700]),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.reply, style: const TextStyle(fontSize: 15)),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_rounded, size: 18, color: Colors.orange[700]),
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.edit, style: const TextStyle(fontSize: 15)),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.forward_rounded, size: 18, color: Colors.purple[700]),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.forward, style: const TextStyle(fontSize: 15)),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18,
                color: Colors.amber[700],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.message.isPinned ? 'Unpin' : 'Pin',
              style: TextStyle(fontSize: 15, color: Colors.amber[700]),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flag_rounded, size: 18, color: Colors.orange[700]),
              ),
              const SizedBox(width: 12),
              Text('Report', style: TextStyle(fontSize: 15, color: Colors.orange[700])),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_rounded, size: 18, color: Colors.red[700]),
              ),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(fontSize: 15, color: Colors.red[700])),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.more_horiz_rounded, size: 18, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.moreOptions, style: const TextStyle(fontSize: 15)),
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
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Message copied'),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Message preview
                Container(
                  padding: const EdgeInsets.all(16),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                widget.isMe ? myMessageColor : Colors.grey[300],
                            child: Text(
                              widget.isMe
                                  ? 'You'[0]
                                  : widget.otherUserName.isNotEmpty
                                      ? widget.otherUserName[0].toUpperCase()
                                      : '?',
                              style: TextStyle(
                                color: widget.isMe ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isMe ? 'You' : widget.otherUserName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  formatFullDateTime(widget.message.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.message.read && widget.isMe)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.done_all,
                                    size: 14,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
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
                        const SizedBox(height: 12),
                        Text(
                          widget.message.message!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
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
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Message copied'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                  color: Colors.amber[700],
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
                    color: const Color(0xFFFF9500),
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
                    color: const Color(0xFFFF3B30),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onDelete != null) {
                        widget.onDelete!(widget.message);
                      }
                    },
                  ),

                const SizedBox(height: 16),
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
            Icon(icon, color: color ?? Colors.black87, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  bool _isSticker(String text) {
    // Check if it's a single emoji
    return text.length <= 4 &&
        RegExp(
          r'^[\u{1f300}-\u{1f9ff}\u{2600}-\u{27bf}]+$',
          unicode: true,
        ).hasMatch(text);
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
