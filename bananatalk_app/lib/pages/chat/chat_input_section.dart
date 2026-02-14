import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'chat_input_bar.dart';
import 'chat_media_panel.dart';
import 'chat_sticker_panel.dart';

class ChatInputSection extends ConsumerWidget {
  final TextEditingController messageController;
  final bool isSending;
  final bool showMediaPanel;
  final bool showStickerPanel;
  final AnimationController mediaPanelController;
  final AnimationController stickerPanelController;
  final Function({String? messageText, String? messageType}) onSendMessage;
  final Function(String) onSelectSticker;
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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;
    final isVip = user?.isVip ?? false;
    final userId = user?.id ?? '';

    return Column(
      children: [
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

    return limitsAsync.when(
      data: (limits) {
        if (limits == null) return const SizedBox.shrink();

        final messageLimit = limits.messages;
        if (messageLimit.isUnlimited) return const SizedBox.shrink();

        final remaining = messageLimit.remaining;
        final isLow = remaining <= 2;
        final isOut = remaining <= 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOut
                ? const Color(0xFFFFEBEE)
                : isLow
                    ? const Color(0xFFFFF8E1)
                    : const Color(0xFFF5F5F5),
            border: Border(
              bottom: BorderSide(
                color: isOut
                    ? const Color(0xFFEF5350)
                    : isLow
                        ? const Color(0xFFFFB300)
                        : Colors.grey.shade300,
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
                color: isOut
                    ? const Color(0xFFEF5350)
                    : isLow
                        ? const Color(0xFFFF8F00)
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOut
                      ? 'Daily message limit reached'
                      : '$remaining message${remaining == 1 ? '' : 's'} remaining today',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOut
                        ? const Color(0xFFEF5350)
                        : isLow
                            ? const Color(0xFFFF8F00)
                            : Colors.grey.shade600,
                    fontWeight: isLow || isOut ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
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
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Unlimited',
                        style: TextStyle(
                          color: Colors.white,
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
