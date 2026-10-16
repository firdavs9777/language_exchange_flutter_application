import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';

/// App Store id, used by the Settings "Rate BananaTalk" row.
const kAppStoreId = '6755862146';

/// Per-install prefs (listed in `kDeviceLevelPrefsKeys`, so they survive a
/// logout). `review_prompt_at` predates the counter and is read as-is.
const reviewPromptPrefsKey = 'review_prompt_at';
const reviewPromptCountPrefsKey = 'review_prompt_count';
const reviewPromptFirstSeenPrefsKey = 'review_prompt_first_seen_at';

const kRatePromptCooldown = Duration(days: 120);
const kRatePromptMinAccountAge = Duration(days: 3);
const kRatePromptMaxTimes = 3;
const kRatePromptStreakDays = 7;

/// Minimum messages from EACH side for the on-send conversation trigger.
const _minMessagesEach = 3;

/// The positive moments that may ask for a review. [slug] is the
/// `rate_prompt_shown` analytics `trigger` param; append-only.
enum RatePromptTrigger {
  dailyPack('daily_pack'),
  lesson('lesson'),
  streak7('streak_7'),
  firstReply('first_reply'),
  conversation('conversation');

  const RatePromptTrigger(this.slug);
  final String slug;
}

/// Pure eligibility rule (no plugins, no clock):
/// - never in the first 3 days after signup ([joinedAt]; when unknown, the
///   first time this install evaluated a prompt stands in for it),
/// - at most once per 120 days,
/// - at most 3 times ever.
///
/// There is deliberately no "do you like us?" pre-question: Apple and Google
/// both forbid gating the native dialog on sentiment.
bool isEligibleForRatePrompt({
  required DateTime now,
  required DateTime? joinedAt,
  required DateTime? lastPromptedAt,
  required int promptCount,
}) {
  if (promptCount >= kRatePromptMaxTimes) return false;
  if (joinedAt == null) return false;
  if (now.difference(joinedAt) < kRatePromptMinAccountAge) return false;
  if (lastPromptedAt != null &&
      now.difference(lastPromptedAt) < kRatePromptCooldown) {
    return false;
  }
  return true;
}

/// Whether the on-send conversation trigger counts as a real two-sided
/// conversation (both sides sent at least 3).
bool isRealConversation({required int myMessages, required int theirMessages}) =>
    myMessages >= _minMessagesEach && theirMessages >= _minMessagesEach;

/// The trigger a finished daily pack reports: a 7-day (or 14, 21...) streak
/// is the stronger moment.
RatePromptTrigger dailyPackTrigger(int? streak) =>
    (streak != null && streak > 0 && streak % kRatePromptStreakDays == 0)
        ? RatePromptTrigger.streak7
        : RatePromptTrigger.dailyPack;

/// The platform review dialog, behind a seam for tests.
abstract class AppReviewer {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class _NativeReviewer implements AppReviewer {
  const _NativeReviewer();
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();
  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

bool _productionInCall() {
  try {
    return CallManager().currentCall != null;
  } catch (_) {
    // Unknown call state: stay quiet rather than risk a dialog over a call.
    return true;
  }
}

/// Asks for a store review at a positive moment, if every rule allows it.
///
/// Order matters: cheap local rules first, then the call check, then the
/// platform, and only then the shared [PopupBudget] -- so a moment that
/// would not show anything never spends the budget.
class ReviewPromptService {
  ReviewPromptService({
    DateTime Function()? clock,
    Future<SharedPreferences> Function()? prefs,
    AppReviewer? reviewer,
    bool Function()? isInCall,
    bool Function()? tryConsumeBudget,
    void Function(String trigger)? onShown,
  })  : _clock = clock ?? DateTime.now,
        _prefs = prefs ?? SharedPreferences.getInstance,
        _reviewer = reviewer ?? const _NativeReviewer(),
        _isInCall = isInCall ?? _productionInCall,
        _tryConsumeBudget = tryConsumeBudget ?? PopupBudget.tryConsume,
        _onShown = onShown ??
            ((t) => AnalyticsService.instance.ratePromptShown(trigger: t));

  final DateTime Function() _clock;
  final Future<SharedPreferences> Function() _prefs;
  final AppReviewer _reviewer;
  final bool Function() _isInCall;
  final bool Function() _tryConsumeBudget;
  final void Function(String trigger) _onShown;

  /// One evaluation at a time per process: two positive moments landing
  /// together must not both pass the rules before either records itself.
  static bool _inFlight = false;

  @visibleForTesting
  static void debugReset() => _inFlight = false;

  /// Returns whether the native review was requested. Never throws: a review
  /// dialog must not break the screen that celebrates the moment.
  Future<bool> maybePrompt(
    RatePromptTrigger trigger, {
    DateTime? joinedAt,
  }) async {
    if (_inFlight) return false;
    _inFlight = true;
    try {
      final prefs = await _prefs();
      final now = _clock();
      var firstSeenMs = _readInt(prefs, reviewPromptFirstSeenPrefsKey);
      if (firstSeenMs == null) {
        firstSeenMs = now.millisecondsSinceEpoch;
        await prefs.setInt(reviewPromptFirstSeenPrefsKey, firstSeenMs);
      }
      final lastMs = _readInt(prefs, reviewPromptPrefsKey);
      // A legacy stamp without a counter was one prompt.
      final count = _readInt(prefs, reviewPromptCountPrefsKey) ??
          (lastMs == null ? 0 : 1);
      final ok = isEligibleForRatePrompt(
        now: now,
        joinedAt:
            joinedAt ?? DateTime.fromMillisecondsSinceEpoch(firstSeenMs),
        lastPromptedAt:
            lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
        promptCount: count,
      );
      if (!ok) return false;
      if (_isInCall()) return false;
      if (!await _reviewer.isAvailable()) return false;
      if (_isInCall()) return false;
      if (!_tryConsumeBudget()) return false;
      // Record before asking: the OS may never return, and a second ask
      // inside the window is the worse failure.
      await prefs.setInt(reviewPromptPrefsKey, now.millisecondsSinceEpoch);
      await prefs.setInt(reviewPromptCountPrefsKey, count + 1);
      try {
        _onShown(trigger.slug);
      } catch (_) {}
      await _reviewer.requestReview();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('ReviewPromptService: $e');
      return false;
    } finally {
      _inFlight = false;
    }
  }

  /// Settings row: opens the store page. Not a prompt -- never counted.
  static Future<void> openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing(appStoreId: kAppStoreId);
    } catch (e) {
      if (kDebugMode) debugPrint('ReviewPromptService.openStoreListing: $e');
    }
  }

  static int? _readInt(SharedPreferences prefs, String key) {
    try {
      return prefs.getInt(key);
    } catch (_) {
      return null;
    }
  }
}

/// Parses a `Community.createdAt` string; null when missing or malformed.
DateTime? parseJoinedAt(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return null;
  return DateTime.tryParse(createdAt);
}
