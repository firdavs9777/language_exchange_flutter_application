import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/notification_permission.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Offer notification permission at the first moment it is obviously useful.
///
/// Shows at most once ever: dismissal marks the prompt spent, because asking
/// again on every conversation open is how an app teaches people to refuse
/// reflexively. A user who is already `authorized` never sees this.
Future<void> maybePrimeNotifications(BuildContext context) async {
  final service = NotificationService();
  final action = service.pendingAction;
  if (!shouldPrimeNotifications(action)) return;
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 40,
              color: Theme.of(sheetContext).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.notifyRepliesTitle,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(l10n.notifyRepliesBody, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(l10n.notifyRepliesEnable),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: Text(l10n.notifyRepliesLater),
            ),
          ],
        ),
      ),
    ),
  );

  if (accepted == true) {
    await service.requestFullAuthorization();
  } else {
    // Covers an explicit decline AND a swipe-dismiss (null).
    await service.markPromptDeclined();
  }
}
