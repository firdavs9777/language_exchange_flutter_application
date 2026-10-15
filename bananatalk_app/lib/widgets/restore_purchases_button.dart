import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/purchase_restore_provider.dart';
import 'package:bananatalk_app/services/purchase_restorer.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Localized message for a restore result.
String restoreOutcomeMessage(AppLocalizations l10n, RestoreOutcome outcome) {
  switch (outcome) {
    case RestoreOutcome.restored:
      return l10n.restorePurchasesSuccess;
    case RestoreOutcome.alreadyActive:
      return l10n.restorePurchasesAlreadyActive;
    case RestoreOutcome.nothingToRestore:
      return l10n.restorePurchasesNothing;
    case RestoreOutcome.failed:
      return l10n.restorePurchasesFailed;
  }
}

/// "Restore Purchases" — App Store guideline 3.1.1 requires a visible
/// restore mechanism wherever auto-renewing subscriptions are sold.
///
/// Shows a spinner while the store and backend work, then a snackbar with
/// the result. [onRestore] replaces the real flow in tests.
class RestorePurchasesButton extends ConsumerStatefulWidget {
  const RestorePurchasesButton({super.key, this.userId, this.onRestore});

  final String? userId;
  final Future<RestoreOutcome> Function()? onRestore;

  @override
  ConsumerState<RestorePurchasesButton> createState() =>
      _RestorePurchasesButtonState();
}

class _RestorePurchasesButtonState
    extends ConsumerState<RestorePurchasesButton> {
  bool _busy = false;

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    RestoreOutcome outcome;
    try {
      outcome = await (widget.onRestore?.call() ??
          restorePurchases(ref, userId: widget.userId));
    } catch (_) {
      outcome = RestoreOutcome.failed;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = AppLocalizations.of(context)!;
    final isError = outcome == RestoreOutcome.failed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(restoreOutcomeMessage(l10n, outcome)),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton(
      key: const ValueKey('restore-purchases'),
      onPressed: _busy ? null : _restore,
      child: _busy
          ? Semantics(
              label: l10n.restorePurchasesInProgress,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Text(
              l10n.restorePurchases,
              style: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
