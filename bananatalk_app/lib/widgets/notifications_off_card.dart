import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/notification_permission.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Shown when the operating system is blocking notifications.
///
/// This is the ONLY route back for a user who has already denied: iOS and
/// Android 13+ never show the permission dialog a second time, so the priming
/// sheet is irrelevant to them and a button into system settings is all that
/// remains. In production that is 1,397 of 1,838 users — the larger group by
/// far, even though this converts far worse than priming does.
///
/// Renders nothing unless the pending action is [NotificationAction.recover],
/// so it is safe to place unconditionally.
class NotificationsOffCard extends StatelessWidget {
  const NotificationsOffCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (NotificationService().pendingAction != NotificationAction.recover) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      key: const Key('notifications-off-card'),
      color: scheme.errorContainer,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 20, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.notificationsOffTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notificationsOffBody,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('notifications-off-open'),
                onPressed: () => AppSettings.openAppSettings(
                  type: AppSettingsType.notification,
                ),
                child: Text(l10n.notificationsOffOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
