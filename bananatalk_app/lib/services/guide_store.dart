import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// How long after signup guides keep appearing (spec §3.2: 7 days, which is
/// also `Community.isNewUser`). Guides stop earlier at [kGuideMilestoneStop].
const int kGuideWindowDays = 7;

/// All guides stop once this many of the four activation actions are done.
const int kGuideMilestoneStop = 3;

/// A surface that can carry a first-session guide.
enum GuideSurface {
  /// Matches predates this enum and keeps its original pref keys — renaming
  /// them would reset the state for everyone mid-rollout.
  matches(
    slug: 'matches',
    action: ActivationAction.message,
    shownKey: 'first_session_guidance_shown_count',
    actedKey: 'first_conversation_done',
  ),
  aiStudy(slug: 'ai_study', action: ActivationAction.lesson),
  chats(slug: 'chats', action: ActivationAction.message),
  moments(slug: 'moments', action: ActivationAction.moment),
  profile(slug: 'profile', action: ActivationAction.profile),

  /// The long-press hint under the first received message (spec §3.3). Not
  /// a tab: retired by the long-press itself or its ✕.
  chatTip(slug: 'chat_tip');

  const GuideSurface({
    required this.slug,
    this.action,
    String? shownKey,
    String? actedKey,
  }) : _shownKey = shownKey,
       _actedKey = actedKey;

  /// Stable analytics identifier. Append-only.
  final String slug;

  /// The real action that retires this surface's guide, if any.
  final ActivationAction? action;

  final String? _shownKey;
  final String? _actedKey;

  String get shownKey => _shownKey ?? 'guide_shown_count_$slug';
  String get actedKey => _actedKey ?? 'guide_acted_$slug';
  String get retiredKey => 'guide_retired_$slug';
}

@immutable
class GuideState {
  const GuideState({required this.acted, required this.timesShown});

  final bool acted;
  final int timesShown;

  /// Storage unreadable: someone who has already acted, i.e. show nothing.
  static const unknown = GuideState(acted: true, timesShown: 0);
}

/// Local persistence for page guides. Every read and write is wrapped; a
/// wrong-typed value from an older build reads as its default.
class GuideStore {
  static Future<GuideState> read(GuideSurface surface) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool acted = false;
      int shown = 0;
      try {
        acted = prefs.getBool(surface.actedKey) ?? false;
      } catch (_) {
        acted = false;
      }
      try {
        shown = prefs.getInt(surface.shownKey) ?? 0;
      } catch (_) {
        shown = 0;
      }
      return GuideState(acted: acted, timesShown: shown);
    } catch (_) {
      return GuideState.unknown;
    }
  }

  static Future<void> markActed(GuideSurface surface) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(surface.actedKey, true);
    } catch (_) {}
  }

  static Future<void> recordShown(GuideSurface surface) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await read(surface);
      await prefs.setInt(surface.shownKey, current.timesShown + 1);
    } catch (_) {}
  }

  /// Logs `guide_retired` the first time a shown guide stops showing, once
  /// per surface ever (pref latch). setBool updates the cache synchronously,
  /// so two builds in one frame log once.
  static Future<void> recordRetired(GuideSurface surface, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool done = false;
      try {
        done = prefs.getBool(surface.retiredKey) ?? false;
      } catch (_) {
        done = false;
      }
      if (done) return;
      final write = prefs.setBool(surface.retiredKey, true);
      AnalyticsService.instance.logGuideRetired(surface.slug, reason);
      await write;
    } catch (_) {}
  }
}

/// Whether a guide should be shown. Pure; every surface reads this.
bool shouldShowGuide({
  required bool withinWindow,
  required bool acted,
  required int milestonesDone,
}) => withinWindow && !acted && milestonesDone < kGuideMilestoneStop;

/// Why a guide that was shown is now suppressed, or null when it still
/// shows or was never shown. Precedence: acted > milestones > window.
String? guideRetiredReason({
  required bool wasShown,
  required bool withinWindow,
  required bool acted,
  required int milestonesDone,
}) {
  if (!wasShown) return null;
  if (shouldShowGuide(
    withinWindow: withinWindow,
    acted: acted,
    milestonesDone: milestonesDone,
  )) {
    return null;
  }
  if (acted) return 'acted';
  if (milestonesDone >= kGuideMilestoneStop) return 'milestones';
  return 'window';
}

/// The single "first week" predicate (spec §3.2), reused by the chat tip and
/// the launch coordinator.
Future<bool> isGuidePeriod(Community? user, ActivationStore store) async {
  if (user == null) return false;
  if (!user.joinedWithinDays(kGuideWindowDays)) return false;
  return await store.doneCount() < kGuideMilestoneStop;
}

/// Waits for the user (a still-loading user must not read as "not new"),
/// back-fills the profile milestone from it, and re-evaluates whenever an
/// action is recorded.
final isGuidePeriodProvider = FutureProvider<bool>((ref) async {
  final store = ref.watch(activationStoreProvider);
  Community? user;
  try {
    user = await ref.watch(userProvider.future);
  } catch (_) {
    user = null;
  }
  if (user != null) await checkProfileComplete(user, store: store);
  // Watched only after the back-fill: the back-fill's own change event would
  // otherwise invalidate this provider mid-compute. Awaiting the first
  // emission means only later actions rebuild it.
  try {
    await ref.watch(activationDoneProvider.future);
  } catch (_) {}
  return isGuidePeriod(user, store);
});

/// Read once per page mount. Deliberately NOT invalidated after
/// `recordShown`: refetching mid-view removed the Matches panel
/// milliseconds after it appeared.
final guideStateProvider = FutureProvider.family<GuideState, GuideSurface>((
  ref,
  surface,
) {
  return GuideStore.read(surface);
});

/// One-shot per-surface "shown" latches for this app run, held outside the
/// widget (tab pages are remounted far more often than a user visits them).
/// User-scoped in session_reset.dart.
final guideRecordedProvider = StateProvider.family<bool, GuideSurface>(
  (ref, surface) => false,
);
