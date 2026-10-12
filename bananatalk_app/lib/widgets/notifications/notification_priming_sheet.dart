import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/services/notification_permission.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Single-flight guard: `pendingAction` only clears after the sheet closes, so
/// without this a second caller (chat / Matches / Waves) could stack a sheet.
class PrimeGate {
  bool _inFlight = false;

  /// True if the caller may proceed (and now holds the gate).
  bool tryEnter() {
    if (_inFlight) return false;
    _inFlight = true;
    return true;
  }

  void exit() => _inFlight = false;
}

final PrimeGate _primeGate = PrimeGate();

/// `notification_prime_result` value for how the sheet closed.
String primeResultFor({required bool? accepted, required bool granted}) =>
    accepted == true ? (granted ? 'granted' : 'declined') : 'later';

/// Whether a message that just appeared in an open conversation is a live
/// incoming one (not history, not pagination, not mine).
bool isLiveIncoming({
  required Set<String> beforeIds,
  required String id,
  required String senderId,
  required String? me,
  required String createdAt,
  required DateTime openedAt,
}) {
  if (beforeIds.contains(id)) return false;
  if (me != null && senderId == me) return false;
  final at = DateTime.tryParse(createdAt);
  if (at == null) return false;
  return !at.isBefore(openedAt.subtract(const Duration(seconds: 10)));
}

/// Offer notification permission at a moment it is obviously useful
/// (spec 4.2: first match batch, first wave, first message sent or
/// received). Shows at most once ever, and only if this launch's
/// [PopupBudget] is unspent. The budget is consumed only when the sheet will
/// actually show.
Future<void> maybePrimeNotifications(
  BuildContext context, {
  String trigger = 'unspecified',
}) async {
  final service = NotificationService();
  final action = service.pendingAction;
  if (!shouldPrimeNotifications(action)) return;
  if (!context.mounted) return;
  // Never interrupt a call.
  if (CallManager().currentCall != null) return;
  if (!_primeGate.tryEnter()) return;
  try {
    if (!PopupBudget.tryConsume()) return;
    AnalyticsService.instance.logNotificationPrimeShown(trigger);
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
      // The contract's results are granted|declined|later, so when the OS
      // prompt could not be raised (no messaging) or threw, nothing was
      // answered and no result is logged.
      final available = service.isMessagingAvailable;
      try {
        final granted = await service.requestFullAuthorization();
        if (available) {
          AnalyticsService.instance.logNotificationPrimeResult(
              primeResultFor(accepted: true, granted: granted));
        }
      } catch (_) {}
    } else {
      // Covers an explicit decline AND a swipe-dismiss (null).
      await service.markPromptDeclined();
      AnalyticsService.instance.logNotificationPrimeResult(
          primeResultFor(accepted: accepted, granted: false));
    }
  } finally {
    _primeGate.exit();
  }
}

/// Default for MatchesTab: after the first non-empty match batch.
Future<void> primeAfterFirstMatches(BuildContext context) =>
    maybePrimeNotifications(context, trigger: 'first_matches');

/// Default for WavesTab: after the first wave received.
Future<void> primeAfterFirstWave(BuildContext context) =>
    maybePrimeNotifications(context, trigger: 'first_wave');
