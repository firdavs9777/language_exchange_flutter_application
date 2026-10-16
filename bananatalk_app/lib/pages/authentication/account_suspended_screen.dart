import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Step 14 (safety wave) — terminal screen shown when the server returns
/// 403 with body.error starting with AppLocalizations.of(context)!.suspendedTitle.
/// Pushed via callOverlayNavigatorKey with pushAndRemoveUntil so the user
/// can't navigate back into the authenticated app. No appeal flow is wired
/// in v1 — user must email bananatalkmain@gmail.com.
class AccountSuspendedScreen extends StatelessWidget {
  final String? reason;
  const AccountSuspendedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.block_rounded,
                size: 72,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.suspendedTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _displayReason(context, reason),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context)!.suspendedContact,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [raw] is the server's `banReason` (spec §5.1), already just the reason.
  String _displayReason(BuildContext context, String? raw) {
    final l10n = AppLocalizations.of(context)!;
    final reason = raw?.trim() ?? '';
    if (reason.isEmpty) return l10n.suspendedNoAccess;
    return '${l10n.suspendedReason} $reason';
  }
}
