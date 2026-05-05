// lib/pages/chat/delete_message_dialog.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_dialog_scaffold.dart';

/// Dialog for delete options: Delete for Me vs Delete for Everyone
class DeleteMessageDialog extends StatelessWidget {
  final Message message;
  final String otherUserName;
  final Function(bool deleteForEveryone) onDelete;

  const DeleteMessageDialog({
    super.key,
    required this.message,
    required this.otherUserName,
    required this.onDelete,
  });

  /// Check if message can be deleted for everyone (within 1 hour)
  bool get canDeleteForEveryone {
    if (message.isDeleted) return false;

    try {
      final createdAt = DateTime.parse(message.createdAt);
      final diff = DateTime.now().difference(createdAt);
      return diff.inHours < 1;
    } catch (e) {
      return false;
    }
  }

  /// Get remaining time for delete for everyone
  String? deleteForEveryoneTimeRemaining(BuildContext context) {
    if (!canDeleteForEveryone) return null;

    try {
      final createdAt = DateTime.parse(message.createdAt);
      final diff = DateTime.now().difference(createdAt);
      final remainingMinutes = 60 - diff.inMinutes;

      if (remainingMinutes > 30) {
        return AppLocalizations.of(context)!.available;
      } else {
        return '${remainingMinutes}m left';
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChatDialogScaffold(
      heroIcon: Icons.delete_rounded,
      heroColor: AppColors.error,
      title: l10n.deleteMessageTitle,
      body: l10n.actionCannotBeUndone,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            icon: Icons.person_outline_rounded,
            title: l10n.deleteForMe,
            subtitle: l10n.onlyRemovesFromDevice,
            onTap: () {
              HapticUtils.onDelete();
              Navigator.pop(context);
              onDelete(false);
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.people_outline_rounded,
            title: l10n.deleteForEveryone,
            subtitle: canDeleteForEveryone
                ? 'Removes for you and $otherUserName'
                : l10n.availableWithinOneHour,
            trailing: deleteForEveryoneTimeRemaining(context),
            enabled: canDeleteForEveryone,
            onTap: () {
              HapticUtils.onDelete();
              Navigator.pop(context);
              onDelete(true);
            },
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: enabled ? context.textPrimary : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled ? context.textPrimary : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: enabled
                        ? theme.primaryColor.withValues(alpha: 0.1)
                        : context.dividerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: enabled ? theme.primaryColor : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show the delete message dialog
Future<void> showDeleteMessageDialog(
  BuildContext context, {
  required Message message,
  required String otherUserName,
  required Function(bool deleteForEveryone) onDelete,
}) {
  return showDialog(
    context: context,
    builder: (context) => DeleteMessageDialog(
      message: message,
      otherUserName: otherUserName,
      onDelete: onDelete,
    ),
  );
}
