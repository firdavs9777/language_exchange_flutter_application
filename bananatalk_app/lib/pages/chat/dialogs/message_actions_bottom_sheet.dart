// lib/pages/chat/message_actions_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

/// Telegram-style bottom sheet for message actions
class MessageActionsBottomSheet extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final VoidCallback? onTranslate;
  final Function(String emoji)? onReaction;

  const MessageActionsBottomSheet({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    this.onReply,
    this.onForward,
    this.onEdit,
    this.onCopy,
    this.onPin,
    this.onDelete,
    this.onTranslate,
    this.onReaction,
  });

  /// Check if message can be edited (within 15 minutes)
  bool get canEdit {
    if (!isMe || message.isDeleted) return false;
    if (message.type != 'text' || message.message == null) return false;

    try {
      final createdAt = DateTime.parse(message.createdAt);
      final diff = DateTime.now().difference(createdAt);
      return diff.inMinutes < 15;
    } catch (e) {
      return false;
    }
  }

  /// Check if message can be deleted for everyone (within 1 hour)
  bool get canDeleteForEveryone {
    if (!isMe || message.isDeleted) return false;

    try {
      final createdAt = DateTime.parse(message.createdAt);
      final diff = DateTime.now().difference(createdAt);
      return diff.inHours < 1;
    } catch (e) {
      return false;
    }
  }

  /// Get remaining time for edit
  String? get editTimeRemaining {
    if (!canEdit) return null;

    try {
      final createdAt = DateTime.parse(message.createdAt);
      final diff = DateTime.now().difference(createdAt);
      final remaining = 15 - diff.inMinutes;
      return '${remaining}m left';
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.gray700 : AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Message preview
            if (message.message != null && message.message!.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.gray800 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isMe ? theme.primaryColor : Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe ? AppLocalizations.of(context)!.you : message.sender.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isMe ? theme.primaryColor : Colors.green,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.message!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? AppColors.gray300 : AppColors.gray700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Quick reactions row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                  // Check if user already reacted with this emoji
                  final hasReacted = message.reactions.any(
                    (r) => r.user.id == currentUserId && r.emoji == emoji,
                  );

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onReaction?.call(emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasReacted
                            ? theme.primaryColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: isDark ? AppColors.gray800 : AppColors.gray200,
            ),

            // Action items
            _buildActionItem(
              context,
              icon: Icons.reply_rounded,
              label: AppLocalizations.of(context)!.reply,
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),

            if (message.message != null && message.message!.isNotEmpty)
              _buildActionItem(
                context,
                icon: Icons.copy_rounded,
                label: AppLocalizations.of(context)!.copy,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.message!));
                  Navigator.pop(context);
                  onCopy?.call();
                  showChatSnackBar(context, message: AppLocalizations.of(context)!.messageCopied, type: ChatSnackBarType.success);
                },
              ),

            if (message.message != null && message.message!.isNotEmpty)
              _buildActionItem(
                context,
                icon: Icons.translate_rounded,
                label: AppLocalizations.of(context)!.translate,
                onTap: () {
                  Navigator.pop(context);
                  onTranslate?.call();
                },
              ),

            _buildActionItem(
              context,
              icon: Icons.forward_rounded,
              label: AppLocalizations.of(context)!.forward,
              onTap: () {
                Navigator.pop(context);
                onForward?.call();
              },
            ),

            _buildActionItem(
              context,
              icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              label: message.isPinned ? AppLocalizations.of(context)!.unpin : AppLocalizations.of(context)!.pin,
              onTap: () {
                Navigator.pop(context);
                onPin?.call();
              },
            ),

            if (canEdit)
              _buildActionItem(
                context,
                icon: Icons.edit_rounded,
                label: AppLocalizations.of(context)!.edit,
                subtitle: editTimeRemaining,
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),

            if (isMe && !message.isDeleted)
              _buildActionItem(
                context,
                icon: Icons.delete_rounded,
                label: AppLocalizations.of(context)!.delete,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDestructive ? AppColors.error : (isDark ? AppColors.white : AppColors.gray900);

    return InkWell(
      onTap: () {
        HapticUtils.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.gray500 : AppColors.gray600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Show the message actions bottom sheet
Future<void> showMessageActionsBottomSheet(
  BuildContext context, {
  required Message message,
  required bool isMe,
  required String currentUserId,
  VoidCallback? onReply,
  VoidCallback? onForward,
  VoidCallback? onEdit,
  VoidCallback? onCopy,
  VoidCallback? onPin,
  VoidCallback? onDelete,
  VoidCallback? onTranslate,
  Function(String emoji)? onReaction,
}) {
  HapticUtils.onLongPress();

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => MessageActionsBottomSheet(
      message: message,
      isMe: isMe,
      currentUserId: currentUserId,
      onReply: onReply,
      onForward: onForward,
      onEdit: onEdit,
      onCopy: onCopy,
      onPin: onPin,
      onDelete: onDelete,
      onTranslate: onTranslate,
      onReaction: onReaction,
    ),
  );
}
