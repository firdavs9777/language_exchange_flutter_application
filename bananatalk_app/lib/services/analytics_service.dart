import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin Firebase Analytics wrapper for Step 13A VIP-gating events.
/// Methods are typed so call sites can't misspell event names or
/// forget required params.
///
/// All methods are async-fire-and-forget; we never await analytics
/// from the UI thread. On SDK error, debug-print and move on —
/// never block the user.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();
  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  Future<void> _log(String name, Map<String, Object?> params) async {
    try {
      final clean = <String, Object>{};
      params.forEach((k, v) {
        if (v != null) clean[k] = v;
      });
      await _fa.logEvent(name: name, parameters: clean);
    } catch (e) {
      if (kDebugMode) debugPrint('[analytics] $name failed: $e');
    }
  }

  // ─── Registration funnel ──────────────────────────────────────
  //
  // The signup wizard had NO instrumentation at all, while 282 of 298 social
  // accounts that reached it never came back. We knew the loss and not the
  // cause. [step] is 0-indexed and [stepName] comes from
  // RegistrationSteps.stepNameAt, so the funnel cannot report a step the user
  // was not on. [entry] is email | google | apple | completion -- the step
  // COUNT differs per entry (a provider photo removes a step), so comparing
  // raw step numbers across entries would be meaningless without it.

  Future<void> registrationStarted({
    required String entry,
    required int totalSteps,
  }) => _log('registration_started', {
    'entry': entry,
    'total_steps': totalSteps,
  });

  Future<void> registrationStepViewed({
    required String entry,
    required int step,
    required String stepName,
    required int totalSteps,
  }) => _log('registration_step_viewed', {
    'entry': entry,
    'step': step,
    'step_name': stepName,
    'total_steps': totalSteps,
  });

  /// A submit attempt refused by a client-side gate. This is the event that
  /// turns "they vanished" into "they were blocked, on this field".
  Future<void> registrationBlocked({
    required String entry,
    required String reason,
    required String stepName,
  }) => _log('registration_blocked', {
    'entry': entry,
    'reason': reason,
    'step_name': stepName,
  });

  /// The user chose to leave the wizard rather than finish it.
  Future<void> registrationAbandoned({
    required String entry,
    required int step,
    required String stepName,
  }) => _log('registration_abandoned', {
    'entry': entry,
    'step': step,
    'step_name': stepName,
  });

  Future<void> registrationCompleted({
    required String entry,
    required int totalSteps,
  }) => _log('registration_completed', {
    'entry': entry,
    'total_steps': totalSteps,
  });

  // ─── Step 13A events ──────────────────────────────────────────

  Future<void> tutorChipUsed({required String chipName, required String userTier}) =>
      _log('tutor_chip_used', {'chip_name': chipName, 'user_tier': userTier});

  /// Fired at the meaningful end-of-flow action for each chip:
  ///   Chat        → session end (user navigates away or explicit end)
  ///   Roleplay    → end-of-session score request
  ///   Story       → reaching the final comprehension question / score screen
  ///   Photo       → after the describe response is rendered + user dismisses
  ///   Pronounce   → Save & Close on the summary sheet
  Future<void> tutorChipCompleted({required String chipName, required String userTier}) =>
      _log('tutor_chip_completed', {'chip_name': chipName, 'user_tier': userTier});

  Future<void> quotaRemainingShown({required String chipName, required int remainingCount}) =>
      _log('quota_remaining_shown', {'chip_name': chipName, 'remaining_count': remainingCount});

  Future<void> quotaHit({required String chipName, required String tier}) =>
      _log('quota_hit', {'chip_name': chipName, 'tier': tier});

  Future<void> paywallShown({required String triggerChip, required String reason}) =>
      _log('paywall_shown', {'trigger_chip': triggerChip, 'reason': reason});

  Future<void> paywallCtaTapped({required String chipName}) =>
      _log('paywall_cta_tapped', {'chip_name': chipName});

  Future<void> subscriptionPurchased({required String plan, required String platform}) =>
      _log('subscription_purchased', {'plan': plan, 'platform': platform});

  Future<void> subscriptionPurchaseFailed({
    required String plan,
    required String platform,
    required String errorCode,
  }) =>
      _log('subscription_purchase_failed', {
        'plan': plan,
        'platform': platform,
        'error_code': errorCode,
      });

  /// Step 15: fired when an admin takes a destructive action
  /// (user_banned, user_unbanned, role_changed). Helps spot unusual
  /// admin activity in Firebase Analytics.
  Future<void> adminActionTaken({
    required String action,
    required String targetUserId,
  }) =>
      _log('admin_action_taken', {
        'action': action,
        'target_user_id': targetUserId,
      });
}
