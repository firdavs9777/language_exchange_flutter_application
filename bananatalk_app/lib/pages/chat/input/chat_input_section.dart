import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'chat_input_bar.dart';
import '../panels/chat_media_panel.dart';
import '../panels/chat_sticker_panel.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ChatInputSection extends ConsumerWidget {
  final TextEditingController messageController;
  final bool isSending;
  final bool showMediaPanel;
  final bool showStickerPanel;
  final AnimationController mediaPanelController;
  final AnimationController stickerPanelController;
  final Function({String? messageText, String? messageType}) onSendMessage;
  final Function(String) onSelectSticker;
  final Function(String gifUrl)? onSendGif;
  final VoidCallback onToggleMediaPanel;
  final VoidCallback onToggleStickerPanel;
  final VoidCallback onTyping;
  final VoidCallback onStopTyping;
  final VoidCallback onHidePanels;
  final Function(String) onMediaOption;
  final Message? replyingToMessage;
  final String? otherUserName;
  final VoidCallback? onCancelReply;
  final VoidCallback? onAudioPressed;
  // Upload progress
  final int uploadBytesSent;
  final int uploadTotalBytes;
  final String? uploadFileName;

  const ChatInputSection({
    super.key,
    required this.messageController,
    required this.isSending,
    required this.showMediaPanel,
    required this.showStickerPanel,
    required this.mediaPanelController,
    required this.stickerPanelController,
    required this.onSendMessage,
    required this.onSelectSticker,
    this.onSendGif,
    required this.onToggleMediaPanel,
    required this.onToggleStickerPanel,
    required this.onTyping,
    required this.onStopTyping,
    required this.onHidePanels,
    required this.onMediaOption,
    this.replyingToMessage,
    this.otherUserName,
    this.onCancelReply,
    this.onAudioPressed,
    this.uploadBytesSent = 0,
    this.uploadTotalBytes = 0,
    this.uploadFileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;
    final isVip = user?.isVip ?? false;
    final userId = user?.id ?? '';

    return Column(
      children: [
        // Upload progress indicator
        if (isSending && uploadTotalBytes > 0)
          _UploadProgressBanner(
            fileName: uploadFileName,
            bytesSent: uploadBytesSent,
            totalBytes: uploadTotalBytes,
          ),
        // Message limit indicator for non-VIP users
        if (!isVip && userId.isNotEmpty)
          _MessageLimitIndicator(userId: userId),
        ChatInputBar(
          messageController: messageController,
          isSending: isSending,
          showMediaPanel: showMediaPanel,
          showStickerPanel: showStickerPanel,
          onSendMessage: onSendMessage,
          onToggleMediaPanel: onToggleMediaPanel,
          onToggleStickerPanel: onToggleStickerPanel,
          onTyping: onTyping,
          onStopTyping: onStopTyping,
          onHidePanels: onHidePanels,
          replyingToMessage: replyingToMessage,
          otherUserName: otherUserName,
          onCancelReply: onCancelReply,
          onAudioPressed: onAudioPressed,
          uploadBytesSent: uploadBytesSent,
          uploadTotalBytes: uploadTotalBytes,
          uploadFileName: uploadFileName,
        ),
        if (showMediaPanel)
          ChatMediaPanel(
            animationController: mediaPanelController,
            onMediaOption: onMediaOption,
          ),
        if (showStickerPanel)
          ChatStickerPanel(
            animationController: stickerPanelController,
            onSendSticker: onSelectSticker,
            onSendGif: onSendGif,
          ),
      ],
    );
  }
}

/// Shows remaining messages for non-VIP users
class _MessageLimitIndicator extends ConsumerWidget {
  final String userId;

  const _MessageLimitIndicator({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(userLimitsProvider(userId));
    final isDark = context.isDarkMode;

    return limitsAsync.when(
      data: (limits) {
        if (limits == null) return const SizedBox.shrink();

        final messageLimit = limits.messages;
        if (messageLimit.isUnlimited) return const SizedBox.shrink();

        final remaining = messageLimit.remaining;
        final isLow = remaining <= 2;
        final isOut = remaining <= 0;

        final statusColor = isOut
            ? AppColors.error
            : isLow
                ? AppColors.warning
                : context.textSecondary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOut
                ? AppColors.error.withValues(alpha: isDark ? 0.15 : 0.08)
                : isLow
                    ? AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.08)
                    : context.containerColor,
            border: Border(
              bottom: BorderSide(
                color: isOut
                    ? AppColors.error.withValues(alpha: 0.5)
                    : isLow
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : context.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOut
                    ? Icons.error_outline
                    : isLow
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOut
                      ? 'Daily message limit reached'
                      : '$remaining message${remaining == 1 ? '' : 's'} remaining today',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: isLow || isOut ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) => VipPlansScreen(userId: userId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 12,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Unlimited',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Shows upload progress banner (KakaoTalk style)
class _UploadProgressBanner extends StatelessWidget {
  final String? fileName;
  final int bytesSent;
  final int totalBytes;

  const _UploadProgressBanner({
    this.fileName,
    required this.bytesSent,
    required this.totalBytes,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getMediaType(String? name) {
    if (name == null) return 'media';
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) return 'photo';
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'm4a', 'wav', 'aac'].contains(ext)) return 'audio';
    return 'file';
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalBytes > 0 ? bytesSent / totalBytes : 0.0;
    final percentage = (progress * 100).toInt();
    final mediaType = _getMediaType(fileName);
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: isDark ? 0.15 : 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.info.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 18,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sending $mediaType...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percentage%  ${_formatFileSize(bytesSent)} / ${_formatFileSize(totalBytes)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.info.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}
