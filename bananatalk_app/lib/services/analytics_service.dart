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
}
