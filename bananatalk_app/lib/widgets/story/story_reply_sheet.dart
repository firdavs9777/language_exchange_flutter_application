import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Bottom sheet for replying to stories with quick emoji reactions
class StoryReplySheet extends StatefulWidget {
  final String userName;
  final String? userImageUrl;
  final Function(String message) onSendReply;
  final Function(String emoji) onSendReaction;
  final VoidCallback? onClose;

  const StoryReplySheet({
    Key? key,
    required this.userName,
    this.userImageUrl,
    required this.onSendReply,
    required this.onSendReaction,
    this.onClose,
  }) : super(key: key);

  @override
  State<StoryReplySheet> createState() => _StoryReplySheetState();

  /// Show the reply sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String userName,
    String? userImageUrl,
    required Function(String message) onSendReply,
    required Function(String emoji) onSendReaction,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryReplySheet(
        userName: userName,
        userImageUrl: userImageUrl,
        onSendReply: onSendReply,
        onSendReaction: onSendReaction,
        onClose: onClose,
      ),
    );
  }
}

class _StoryReplySheetState extends State<StoryReplySheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  static const List<String> _quickReactions = [
    '❤️', '😂', '😮', '🔥', '👏', '😢', '😍', '🙌'
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendReply() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSendReply(message);
      _controller.clear();
      Navigator.pop(context);
    }
  }

  void _sendReaction(String emoji) {
    HapticFeedback.lightImpact();
    widget.onSendReaction(emoji);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.gray900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? AppColors.gray600 : AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Reply to ${widget.userName}',
                      style: context.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textMuted),
                      onPressed: () {
                        widget.onClose?.call();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Quick reactions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Reactions',
                      style: context.labelSmall.copyWith(color: context.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _quickReactions.map((emoji) {
                        return _QuickReactionButton(
                          emoji: emoji,
                          onTap: () => _sendReaction(emoji),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Text input
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: context.bodyMedium,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Send a message...',
                          hintStyle: context.bodyMedium.copyWith(color: context.textMuted),
                          filled: true,
                          fillColor: context.containerColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        onPressed: _hasText ? _sendReply : null,
                        icon: Icon(
                          Icons.send_rounded,
                          color: _hasText ? AppColors.primary : context.textMuted,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _hasText
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReactionButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _QuickReactionButton({
    required this.emoji,
    required this.onTap,
  });

  @override
  State<_QuickReactionButton> createState() => _QuickReactionButtonState();
}

class _QuickReactionButtonState extends State<_QuickReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          );
        },
      ),
    );
  }
}
