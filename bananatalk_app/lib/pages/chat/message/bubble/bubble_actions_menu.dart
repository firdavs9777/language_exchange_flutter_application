import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Shows a bottom-sheet with retry / delete options for a message that failed
/// to send. Extracted from [_ChatMessageBubbleState._showFailedMessageOptions].
///
/// NOTE: [showBubbleContextMenu] was intentionally NOT extracted here.
/// The context menu references [_reactionPickerOverlay], [_bubbleKey], and
/// [_hideReactionPicker] — all mutable State fields — which would require >5
/// threaded parameters and a setter callback, making the orchestrator *more*
/// complex, not less. It remains inline per the pragmatic guardrail.
Future<void> showFailedMessageOptions({
  required BuildContext context,
  required Message message,
  required VoidCallback onRetry,
  required VoidCallback onDelete,
}) async {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  await showModalBottomSheet<void>(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                onRetry();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
              title: Text(
                l10n?.delete ?? 'Delete',
                style: const TextStyle(color: AppColors.error),
              ),
              subtitle: const Text('Remove this message'),
              onTap: () {
                Navigator.pop(context);
                onDelete();
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
