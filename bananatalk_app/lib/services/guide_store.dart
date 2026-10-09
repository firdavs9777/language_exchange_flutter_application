import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many app launches a page guide may appear on before it stops.
///
/// Counted per launch, not per visit, so this is two launches rather than two
/// glances. Started at three and came down: three launches can span most of
/// the six days `Community.isNewUser` covers, which makes a first-session
/// nudge into a fixture of the screen.
///
/// Same cap as the Matches panel this generalises -- the two move together.
const int kMaxGuideViews = 2;

/// A surface that can carry a first-session guide.
///
/// Every top-level tab is here on purpose. A new user who only ever sees a
/// hint on Matches learns one thing the app does; the other four tabs stay
/// blank rectangles they never tap twice.
enum GuideSurface {
  /// Matches. Predates this enum, so it keeps the original pref keys —
  /// renaming them would reset the counter for everyone mid-rollout and show
  /// the panel three more times to people who had already finished with it.
  matches(
    slug: 'matches',
    shownKey: 'first_session_guidance_shown_count',
    actedKey: 'first_conversation_done',
  ),
  aiStudy(slug: 'ai_study'),
  chats(slug: 'chats'),
  moments(slug: 'moments'),
  profile(slug: 'profile');

  const GuideSurface({required this.slug, String? shownKey, String? actedKey})
      : _shownKey = shownKey,
        _actedKey = actedKey;

  /// Stable identifier reported to analytics. Changing one orphans its
  /// history in the console, so these are append-only.
  final String slug;

  final String? _shownKey;
  final String? _actedKey;

  String get shownKey => _shownKey ?? 'guide_shown_count_$slug';
  String get actedKey => _actedKey ?? 'guide_acted_$slug';
}

/// What a guide needs to know about this user on one surface.
@immutable
class GuideState {
  const GuideState({required this.acted, required this.timesShown});

  /// Whether the user has already done the thing the guide asks for.
  final bool acted;

  final int timesShown;

  /// The safe answer when storage cannot be read: someone who has already
  /// acted, i.e. show nothing. A hint must never break the page under it.
  static const unknown = GuideState(acted: true, timesShown: 0);
}

/// Local persistence for page guides, generalised from `FirstSessionStore`.
///
/// Every read and write is wrapped. A wrong type left by an older build reads
/// as its default rather than throwing — `getBool`/`getInt` throw on a type
/// mismatch, and a crash here would take the page with it.
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
    } catch (_) {
      // Best effort. A guide reappearing is a far smaller harm than a throw
      // on the path that just did the thing it asked for.
    }
  }

  static Future<void> recordShown(GuideSurface surface) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await read(surface);
      await prefs.setInt(surface.shownKey, current.timesShown + 1);
    } catch (_) {
      // Best effort; see markActed.
    }
  }
}

/// Whether a page guide should be shown.
///
/// Pure so it can be tested without driving the widget, and so the rule
/// cannot drift from the five pages that read it.
bool shouldShowGuide({
  required bool isNewUser,
  required bool acted,
  required int timesShown,
}) =>
    isNewUser && !acted && timesShown < kMaxGuideViews;

/// Read once per page mount. Deliberately NOT invalidated after
/// `recordShown`: refetching mid-view removed the Matches panel milliseconds
/// after it appeared. The new count is picked up on the next mount.
final guideStateProvider =
    FutureProvider.family<GuideState, GuideSurface>((ref, surface) {
  return GuideStore.read(surface);
});

/// One-shot per-surface latches for this app run, held outside the widget.
///
/// Pages in the tab shell are rebuilt — and in a `TabBarView` outright
/// unmounted — far more often than a user would call "a visit". Latches held
/// on State reset every time: Matches -> Partners -> Matches three times
/// inside a minute burned the whole [kMaxGuideViews] cap and re-fired the
/// shown event on each remount, inflating the funnel denominator.
///
/// Registered user-scoped in session_reset.dart so a second account in the
/// same app run starts fresh.
final guideRecordedProvider =
    StateProvider.family<bool, GuideSurface>((ref, surface) => false);
