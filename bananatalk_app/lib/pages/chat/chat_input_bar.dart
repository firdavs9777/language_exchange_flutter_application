import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController messageController;
  final bool isSending;
  final bool showMediaPanel;
  final bool showStickerPanel;
  final Function({String? messageText, String? messageType}) onSendMessage;
  final VoidCallback onToggleMediaPanel;
  final VoidCallback onToggleStickerPanel;
  final VoidCallback onTyping;
  final VoidCallback onStopTyping;
  final VoidCallback onHidePanels;
  final Message? replyingToMessage;
  final String? otherUserName;
  final VoidCallback? onCancelReply;
  final VoidCallback? onAudioPressed;
  // Upload progress
  final int uploadBytesSent;
  final int uploadTotalBytes;
  final String? uploadFileName;

  const ChatInputBar({
    Key? key,
    required this.messageController,
    required this.isSending,
    required this.showMediaPanel,
    required this.showStickerPanel,
    required this.onSendMessage,
    required this.onToggleMediaPanel,
    required this.onToggleStickerPanel,
    required this.onTyping,
    required this.onStopTyping,
    required this.onHidePanels,
    this.replyingToMessage,
    this.otherUserName,
    this.onCancelReply,
    this.onAudioPressed,
    this.uploadBytesSent = 0,
    this.uploadTotalBytes = 0,
    this.uploadFileName,
  }) : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with TickerProviderStateMixin {
  bool _hasText = false;
  late AnimationController _sendButtonController;

  @override
  void initState() {
    super.initState();
    _hasText = widget.messageController.text.trim().isNotEmpty;
    widget.messageController.addListener(_onTextChanged);

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    if (_hasText) _sendButtonController.forward();
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.97),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: !widget.showMediaPanel && !widget.showStickerPanel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyingToMessage != null) ...[
              _buildReplyPreview(context, isDark),
              const SizedBox(height: 8),
            ],
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                _buildAttachButton(isDark),
                const SizedBox(width: 6),
                // Text field
                Expanded(child: _buildTextField(context, isDark)),
                const SizedBox(width: 6),
                // Emoji button
                _buildEmojiButton(isDark),
                const SizedBox(width: 6),
                // Send / Mic button
                _buildSendButton(context, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isDark) {
    final replyMessage = widget.replyingToMessage!;
    final replyText = replyMessage.message ??
        (replyMessage.media != null ? '📷 Media' : 'Message');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${widget.otherUserName ?? "user"}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onCancelReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachButton(bool isDark) {
    final isActive = widget.showMediaPanel;

    return GestureDetector(
      onTap: widget.onToggleMediaPanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedRotation(
          turns: isActive ? 0.125 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.add_rounded,
            color: isActive ? AppColors.primary : context.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: widget.messageController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.typeAMessage,
          hintStyle: TextStyle(
            color: context.textHint,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 11,
          ),
          isDense: true,
        ),
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 15,
          color: context.textPrimary,
          height: 1.35,
        ),
        onSubmitted: (_) => widget.onSendMessage(),
        onChanged: (text) {
          if (text.trim().isNotEmpty) {
            widget.onTyping();
          } else {
            widget.onStopTyping();
          }
        },
        onTap: widget.onHidePanels,
      ),
    );
  }

  Widget _buildEmojiButton(bool isDark) {
    final isActive = widget.showStickerPanel;

    return GestureDetector(
      onTap: widget.onToggleStickerPanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isActive ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
          color: isActive ? const Color(0xFFF59E0B) : context.textSecondary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context, bool isDark) {
    final isUploadingMedia = widget.uploadTotalBytes > 0;
    final canSend = !widget.isSending || isUploadingMedia;

    return GestureDetector(
      onTap: !canSend
          ? null
          : _hasText
              ? () {
                  HapticUtils.onMessageSend();
                  widget.onSendMessage();
                }
              : widget.onAudioPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: _hasText && canSend
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _hasText
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          boxShadow: _hasText && canSend
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: _buildSendIcon(context, isDark, isUploadingMedia, canSend),
          ),
        ),
      ),
    );
  }

  Widget _buildSendIcon(
      BuildContext context, bool isDark, bool isUploadingMedia, bool canSend) {
    // Sending text (not media upload) — spinner
    if (widget.isSending && !isUploadingMedia) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    // Has text — send arrow
    if (_hasText) {
      return const Icon(
        Icons.arrow_upward_rounded,
        key: ValueKey('send'),
        color: Colors.white,
        size: 22,
      );
    }

    // Uploading media with no text — progress ring
    if (isUploadingMedia) {
      return SizedBox(
        key: const ValueKey('uploading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: widget.uploadBytesSent / widget.uploadTotalBytes,
          valueColor: AlwaysStoppedAnimation<Color>(context.textSecondary),
          backgroundColor: context.textMuted.withValues(alpha: 0.3),
        ),
      );
    }

    // Default — mic
    return Icon(
      Icons.mic_rounded,
      key: const ValueKey('mic'),
      color: context.textSecondary,
      size: 22,
    );
  }
}
