import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey;
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call_manager.dart' show InitiateStatus;

/// The one way the UI starts a call: chat header, call buttons, call bubble
/// ("call back") and the Calls list all come through here, so busy and
/// error handling is identical everywhere.
/// Prefix of a call permission error that needs the Settings dialog.
const _permanentlyDeniedPrefix = 'PERMANENTLY_DENIED:';

class CallLauncher {
  const CallLauncher._();

  static Future<void> start(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String userName,
    String? avatar,
    required CallType type,
    void Function(CallModel call)? openActive,
  }) async {
    final notifier = ref.read(callProvider.notifier);
    final manager = notifier.callManager;

    // Errors from this start (permissions, the conversation-start cap,
    // connect failures) are shown here, once. The callback another screen
    // registered is put back afterwards so later in-call errors still reach it.
    final previous = manager.onCallError;
    void onError(String error) {
      if (context.mounted) showCallError(context, error);
    }
    // One closure object, so the restore below can recognise it.
    final void Function(String) ours = onError;

    manager.onCallError = ours;
    final InitiateStatus status;
    try {
      status = (await notifier.initiateCall(userId, userName, avatar, type)).status;
    } finally {
      if (identical(manager.onCallError, ours)) manager.onCallError = previous;
    }
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case InitiateStatus.started:
        final call = notifier.currentCall;
        if (call != null) (openActive ?? CallRoutes.openActive)(call);
      case InitiateStatus.calleeBusy:
        _snack(context, l10n.callLabelBusy(userName));
      case InitiateStatus.calleeUnavailable:
        _snack(context, l10n.callUnavailable(userName));
      case InitiateStatus.callerBusy:
        // Already in a call (here or on another device): never a second screen.
        _snack(context, l10n.callFailed);
      case InitiateStatus.permissionDenied:
      case InitiateStatus.failed:
        break; // already surfaced through the error callback
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// The app-wide in-call error presenter, registered once in main.dart.
  /// Calls accepted or started outside a chat (lock screen, Calls list,
  /// missed-call "Call back") have no screen of their own to show errors,
  /// so they go to the overlay navigator, above whatever is open.
  static void showCallErrorOnOverlay(String error) {
    final ctx = callOverlayNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) showCallError(ctx, error);
  }

  /// Permission errors arrive as `PERMANENTLY_DENIED:<msg>` / `DENIED:<msg>`.
  static void showCallError(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.startsWith(_permanentlyDeniedPrefix)) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.permissionsRequired),
          content: Text(error.substring(_permanentlyDeniedPrefix.length)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                AppSettings.openAppSettings();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
    } else if (error.startsWith('DENIED:')) {
      _snack(context, error.substring('DENIED:'.length));
    } else {
      _snack(context, error);
    }
  }
}
