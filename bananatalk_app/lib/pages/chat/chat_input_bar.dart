import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

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

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.messageController.text.trim().isNotEmpty;
    widget.messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContentToSend = _hasText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.dividerColor,
            width: 0.5,
          ),
        ),
        boxShadow: context.isDarkMode ? AppShadows.md : AppShadows.sm,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyingToMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: Spacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: context.isDarkMode ? 0.15 : 0.1),
                  borderRadius: AppRadius.borderMD,
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    Spacing.hGapSM,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ${widget.otherUserName ?? "user"}',
                            style: context.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Spacing.gapXXS,
                          Text(
                            widget.replyingToMessage!.message ??
                                (widget.replyingToMessage!.media != null
                                    ? '📷 Media'
                                    : 'Message'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      child: Container(
                        padding: Spacing.paddingXS,
                        decoration: BoxDecoration(
                          color: context.containerHighColor,
                          borderRadius: AppRadius.borderSM,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Media attachment button
                _ActionButton(
                  icon: Icons.add_rounded,
                  isActive: widget.showMediaPanel,
                  onPressed: widget.onToggleMediaPanel,
                  rotateWhenActive: true,
                ),

                Spacing.hGapSM,

                // Text input field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: AppRadius.borderXXL,
                      border: Border.all(
                        color: context.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.messageController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeAMessage,
                        hintStyle: context.bodyMedium.copyWith(
                          color: context.textHint,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: context.bodyMedium,
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
                  ),
                ),

                Spacing.hGapSM,

                // Emoji/Sticker button
                _ActionButton(
                  icon: widget.showStickerPanel
                      ? Icons.keyboard_rounded
                      : Icons.emoji_emotions_outlined,
                  isActive: widget.showStickerPanel,
                  onPressed: widget.onToggleStickerPanel,
                ),

                Spacing.hGapSM,

                // Send or Audio button (Telegram style)
                _SendAudioButton(
                  isSending: widget.isSending,
                  hasContent: hasContentToSend,
                  onSendPressed: () => widget.onSendMessage(),
                  onAudioPressed: widget.onAudioPressed,
                  uploadBytesSent: widget.uploadBytesSent,
                  uploadTotalBytes: widget.uploadTotalBytes,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final bool rotateWhenActive;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    this.rotateWhenActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: Spacing.paddingSM,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : context.containerColor,
          borderRadius: AppRadius.borderMD,
        ),
        child: AnimatedRotation(
          turns: rotateWhenActive && isActive ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            color: isActive ? AppColors.primary : context.textSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SendAudioButton extends StatelessWidget {
  final bool isSending;
  final bool hasContent;
  final VoidCallback onSendPressed;
  final VoidCallback? onAudioPressed;
  // Upload progress
  final int uploadBytesSent;
  final int uploadTotalBytes;

  const _SendAudioButton({
    required this.isSending,
    required this.hasContent,
    required this.onSendPressed,
    this.onAudioPressed,
    this.uploadBytesSent = 0,
    this.uploadTotalBytes = 0,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    // Allow sending text while media is uploading
    final isUploadingMedia = uploadTotalBytes > 0;
    final canSend = !isSending || isUploadingMedia;

    return GestureDetector(
      onTap: !canSend
          ? null
          : hasContent
              ? onSendPressed
              : onAudioPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: Spacing.paddingMD,
        decoration: BoxDecoration(
          gradient: hasContent
              ? LinearGradient(
                  // Show active colors when uploading media (user can still send text)
                  colors: (isSending && !isUploadingMedia)
                      ? [AppColors.gray400, AppColors.gray500]
                      : [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasContent ? null : context.containerColor,
          shape: BoxShape.circle,
          boxShadow: hasContent && canSend ? AppShadows.colored : AppShadows.none,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: _buildButtonIcon(context),
        ),
      ),
    );
  }

  Widget _buildButtonIcon(BuildContext context) {
    final isUploadingMedia = uploadTotalBytes > 0;

    // Case 1: Sending text message (not media upload) - show spinner
    if (isSending && !isUploadingMedia) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
        ),
      );
    }

    // Case 2: Has text content - show send icon (even during media upload)
    if (hasContent) {
      return const Icon(
        Icons.send_rounded,
        key: ValueKey('send'),
        color: AppColors.white,
        size: 22,
      );
    }

    // Case 3: Uploading media with no text - show upload progress in mic area
    if (isUploadingMedia) {
      return SizedBox(
        key: const ValueKey('uploading'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: uploadBytesSent / uploadTotalBytes,
          valueColor: AlwaysStoppedAnimation<Color>(context.textSecondary),
          backgroundColor: context.textMuted.withValues(alpha: 0.3),
        ),
      );
    }

    // Case 4: Default - show mic icon
    return Icon(
      Icons.mic_rounded,
      key: const ValueKey('mic'),
      color: context.textSecondary,
      size: 22,
    );
  }
}
