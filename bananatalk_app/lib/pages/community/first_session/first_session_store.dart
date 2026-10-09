import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrefHasMessaged = 'first_conversation_done';
const String kPrefTimesShown = 'first_session_guidance_shown_count';

/// What the first-session panel needs to know about this user.
@immutable
class FirstSessionState {
  const FirstSessionState({required this.hasMessaged, required this.timesShown});

  final bool hasMessaged;
  final int timesShown;

  /// The safe answer when storage cannot be read: an established user who has
  /// already messaged, i.e. show nothing. A hint must never break Matches.
  static const unknown = FirstSessionState(hasMessaged: true, timesShown: 0);
}

/// Local persistence for the first-session panel, following the existing
/// `ai_tools_scroll_hint` precedent.
///
/// Every read and write is wrapped. A wrong type left by an older build reads
/// as its default rather than throwing — `getBool`/`getInt` throw on a type
/// mismatch, and a crash here would take the Matches tab with it.
class FirstSessionStore {
  static Future<FirstSessionState> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool messaged = false;
      int shown = 0;
      try {
        messaged = prefs.getBool(kPrefHasMessaged) ?? false;
      } catch (_) {
        messaged = false;
      }
      try {
        shown = prefs.getInt(kPrefTimesShown) ?? 0;
      } catch (_) {
        shown = 0;
      }
      return FirstSessionState(hasMessaged: messaged, timesShown: shown);
    } catch (_) {
      return FirstSessionState.unknown;
    }
  }

  static Future<void> markMessaged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPrefHasMessaged, true);
    } catch (_) {
      // Best effort. The panel reappearing is a far smaller harm than a throw
      // on the message-send path.
    }
  }

  static Future<void> recordShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await read();
      await prefs.setInt(kPrefTimesShown, current.timesShown + 1);
    } catch (_) {
      // Best effort; see markMessaged.
    }
  }
}

/// Read once per Matches mount. Deliberately NOT invalidated after
/// `recordShown`: refetching mid-view removed the panel milliseconds after it
/// appeared. The new count is picked up on the next mount.
final firstSessionStateProvider =
    FutureProvider<FirstSessionState>((ref) => FirstSessionStore.read());

/// One-shot latches for this app run, held outside the widget.
///
/// MatchesTab lives in a TabBarView and keeps no alive state, so Flutter
/// unmounts it when the user moves to a non-adjacent tab and builds a fresh
/// State on return. Latches held on that State reset every time: Matches ->
/// Partners -> Matches three times inside a minute burned the whole
/// kMaxGuidanceViews cap, and re-fired first_session_matches_shown on each
/// remount, inflating the funnel denominator.
///
/// Registered user-scoped in session_reset.dart so a second account in the
/// same app run starts fresh.
final firstSessionGuidanceRecordedProvider = StateProvider<bool>((ref) => false);
final firstSessionMatchesReportedProvider = StateProvider<bool>((ref) => false);
