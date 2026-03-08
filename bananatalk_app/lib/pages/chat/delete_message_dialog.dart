// lib/pages/chat/delete_message_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

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
  String? get deleteForEveryoneTimeRemaining {
    if (!canDeleteForEveryone) return null;

    try {
      final createdAt = DateTime.parse(message.createdAt);
      final diff = DateTime.now().difference(createdAt);
      final remainingMinutes = 60 - diff.inMinutes;

      if (remainingMinutes > 30) {
        return 'Available';
      } else {
        return '${remainingMinutes}m left';
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Delete Message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Delete for Me option
            _buildOption(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Delete for Me',
              subtitle: 'Only removes from your device',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onDelete(false);
              },
            ),

            const SizedBox(height: 12),

            // Delete for Everyone option
            _buildOption(
              context,
              icon: Icons.people_outline_rounded,
              title: 'Delete for Everyone',
              subtitle: canDeleteForEveryone
                  ? 'Removes for you and $otherUserName'
                  : 'Only available within 1 hour',
              trailing: deleteForEveryoneTimeRemaining,
              enabled: canDeleteForEveryone,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onDelete(true);
              },
            ),

            const SizedBox(height: 20),

            // Cancel button
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
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: enabled
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey,
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
                        color: enabled
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        ? theme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
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
