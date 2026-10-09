# First-Session Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A first-time user is pointed at the one action that starts a conversation, and we can measure what share of them take it.

**Architecture:** A pure eligibility predicate decides whether to show a two-line panel in the list-header slot `matches_tab.dart` already renders at index 0. Local `SharedPreferences` holds "has messaged" and a view counter. Four fire-and-forget analytics events span the funnel, with the conversion event fired from the central send path so it counts a message **sent**, not a Say hi **tapped**.

**Tech Stack:** Flutter, Riverpod (`FutureProvider`, `ConsumerStatefulWidget`), `shared_preferences`, `firebase_analytics` via the existing `AnalyticsService` wrapper, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-09-first-session-guidance-design.md`

## Global Constraints

- Guidance is **not a tour**: no overlay, no scrim, no coach marks, no interaction blocking. The panel is a list header.
- The panel has **no dismiss control**. The view cap bounds the annoyance.
- `kMaxGuidanceViews = 3`.
- Eligibility uses the existing `Community.isNewUser` (joined ≤ 6 days). Do not add a second account-age rule.
- `first_message_sent` fires on a **successful send**, never on a tap.
- Every `SharedPreferences` read and write is wrapped; failure defaults to **not showing** the panel. A hint must never break Matches.
- Analytics is fire-and-forget and never awaited from the UI thread, matching `AnalyticsService._log`.
- New copy is **two short lines**, added to `lib/l10n/app_en.arb` only; other locales fall back to English until the native review in `docs/l10n/native-qa-strings-2026-10.csv`.
- Run `flutter gen-l10n` after editing the `.arb`; never hand-edit `lib/l10n/app_localizations*.dart`.

## Review Focus

1. **`SharedPreferences` throws or is unavailable** — the panel must be absent and Matches must still render, not crash or spin. (Task 2)
2. **`createdAt` is empty or unparseable** — `isNewUser` returns false, so no panel; must not throw. (Task 2)
3. **A long localized label in a narrow panel** — the same class of bug as the 2026-10-09 `chat_app_bar` overflow; the panel must not overflow at a phone width. (Task 4)
4. **The same session rebuilding repeatedly** — `timesShown` must increment once per session, not once per rebuild, or the cap burns in seconds. (Task 5)
5. **Two sends in quick succession** — `first_conversation_done` is written once and `first_message_sent` fires once, not per message forever. (Task 6)

---

### Task 1: First-session store

**Files:**
- Create: `lib/pages/community/first_session/first_session_store.dart`
- Test: `test/community/first_session_store_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `class FirstSessionState { final bool hasMessaged; final int timesShown; const FirstSessionState({required this.hasMessaged, required this.timesShown}); }`, `class FirstSessionStore { static Future<FirstSessionState> read(); static Future<void> markMessaged(); static Future<void> recordShown(); }`, and the prefs keys `kPrefHasMessaged = 'first_conversation_done'`, `kPrefTimesShown = 'first_session_guidance_shown_count'`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';

/// Local state, deliberately: it resets on reinstall and does not follow a
/// second device, which `Community.isNewUser` bounds to six days. The
/// alternative spends a network round trip on every cold start for a
/// low-stakes decision.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install reports no message and no views', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await FirstSessionStore.read();
    expect(s.hasMessaged, isFalse);
    expect(s.timesShown, 0);
  });

  test('markMessaged persists', () async {
    SharedPreferences.setMockInitialValues({});
    await FirstSessionStore.markMessaged();
    expect((await FirstSessionStore.read()).hasMessaged, isTrue);
  });

  test('recordShown increments', () async {
    SharedPreferences.setMockInitialValues({});
    await FirstSessionStore.recordShown();
    await FirstSessionStore.recordShown();
    expect((await FirstSessionStore.read()).timesShown, 2);
  });

  test('a non-int counter left by an older build reads as zero', () async {
    SharedPreferences.setMockInitialValues(
        {kPrefTimesShown: 'not-a-number', kPrefHasMessaged: 'yes'});
    final s = await FirstSessionStore.read();
    expect(s.timesShown, 0);
    expect(s.hasMessaged, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/community/first_session_store_test.dart`
Expected: FAIL — `Error when reading '.../first_session_store.dart'`

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/foundation.dart';
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
/// as its default rather than throwing -- `getBool`/`getInt` throw on a type
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/community/first_session_store_test.dart`
Expected: PASS, 4 tests

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/first_session/first_session_store.dart test/community/first_session_store_test.dart
git commit -m "feat(matches): first-session prefs store, error-safe"
```

---

### Task 2: Eligibility predicate

**Files:**
- Create: `lib/pages/community/first_session/first_session_guidance.dart`
- Test: `test/community/first_session_guidance_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `const int kMaxGuidanceViews`, `bool shouldShowFirstSessionGuidance({required bool isNewUser, required bool hasMessaged, required int timesShown})`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';

/// The rule that decides whether a first-timer sees the panel. Pure, because
/// a rule living inline in a widget drifts from the UI silently -- the
/// registration photo step and its submit gate disagreed for months and
/// locked OAuth users out of signup entirely.
void main() {
  group('shouldShowFirstSessionGuidance', () {
    test('a brand-new user who has not messaged sees it', () {
      expect(
        shouldShowFirstSessionGuidance(
            isNewUser: true, hasMessaged: false, timesShown: 0),
        isTrue,
      );
    });

    test('a user who has already messaged never sees it', () {
      expect(
        shouldShowFirstSessionGuidance(
            isNewUser: true, hasMessaged: true, timesShown: 0),
        isFalse,
      );
    });

    test('an established account never sees it', () {
      expect(
        shouldShowFirstSessionGuidance(
            isNewUser: false, hasMessaged: false, timesShown: 0),
        isFalse,
      );
    });

    test('it stops after the view cap, so it guides rather than nags', () {
      expect(
        shouldShowFirstSessionGuidance(
            isNewUser: true, hasMessaged: false, timesShown: kMaxGuidanceViews - 1),
        isTrue,
      );
      expect(
        shouldShowFirstSessionGuidance(
            isNewUser: true, hasMessaged: false, timesShown: kMaxGuidanceViews),
        isFalse,
      );
    });

    test('a corrupt negative counter does not resurrect it past the cap', () {
      expect(
        shouldShowFirstSessionGuidance(
            isNewUser: true, hasMessaged: false, timesShown: -5),
        isTrue,
      );
    });
  });

  // Review Focus 1: storage unavailable must hide the panel, never break
  // Matches. FirstSessionState.unknown encodes that, so the predicate must
  // read it as "nothing to show".
  group('the unknown-storage state hides the panel', () {
    test('unknown reads as already-messaged, so nothing is shown', () {
      const unknown = FirstSessionState.unknown;
      expect(
        shouldShowFirstSessionGuidance(
          isNewUser: true,
          hasMessaged: unknown.hasMessaged,
          timesShown: unknown.timesShown,
        ),
        isFalse,
      );
    });
  });

  // Review Focus 2: a missing or malformed createdAt must mean "not new",
  // not an exception. Community.isNewUser is the only account-age rule and
  // had no test of its own.
  group('Community.isNewUser tolerates a bad createdAt', () {
    Community withCreatedAt(String v) => Community(
          id: 'u', appleId: '', googleId: '', name: 'n', email: '', mbti: '',
          bloodType: '', bio: '', images: const [], birth_day: '',
          birth_month: '', gender: '', birth_year: '', native_language: '',
          language_to_learn: '', imageUrls: const [], createdAt: v, version: 0,
          followers: const [], followings: const [],
          location: Location.defaultLocation(),
        );

    test('an empty createdAt is not new', () {
      expect(withCreatedAt('').isNewUser, isFalse);
    });

    test('an unparseable createdAt is not new, and does not throw', () {
      expect(withCreatedAt('not-a-date').isNewUser, isFalse);
    });

    test('a recent createdAt is new', () {
      final recent =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      expect(withCreatedAt(recent).isNewUser, isTrue);
    });

    test('an old createdAt is not new', () {
      final old =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      expect(withCreatedAt(old).isNewUser, isFalse);
    });
  });
}
```

The two extra groups import the store and the model:

```dart
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
```

This is why the store is Task 1: the predicate's tests consume
`FirstSessionState.unknown`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/community/first_session_guidance_test.dart`
Expected: FAIL — `Error: Method not found: 'shouldShowFirstSessionGuidance'`

- [ ] **Step 3: Write minimal implementation**

```dart
/// How many times the first-session panel may be shown before it stops.
///
/// Without a cap, someone who never messages sees the same banner every
/// session for the six days `Community.isNewUser` covers, which is nagging
/// rather than guidance.
const int kMaxGuidanceViews = 3;

/// Whether the Matches first-session panel should be shown.
///
/// Pure so it can be tested without driving the widget, and so the rule
/// cannot drift from the UI that reads it.
bool shouldShowFirstSessionGuidance({
  required bool isNewUser,
  required bool hasMessaged,
  required int timesShown,
}) =>
    isNewUser && !hasMessaged && timesShown < kMaxGuidanceViews;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/community/first_session_guidance_test.dart`
Expected: PASS, 5 tests

- [ ] **Step 5: Commit**

```bash
git add lib/pages/community/first_session/first_session_guidance.dart test/community/first_session_guidance_test.dart
git commit -m "feat(matches): first-session guidance eligibility rule"
```

---

### Task 3: Funnel events

**Files:**
- Modify: `lib/services/analytics_service.dart` (add after the registration funnel block)

**Interfaces:**
- Consumes: nothing.
- Produces: on `AnalyticsService.instance` — `Future<void> firstSessionMatchesShown({required int matchCount})`, `Future<void> firstSessionGuidanceShown({required int timesShown})`, `Future<void> firstSessionSayHiTapped({required int position})`, `Future<void> firstMessageSent()`.

- [ ] **Step 1: Add the four methods**

Insert immediately before the `// ─── Step 13A events ───` divider:

```dart
  // ─── First session ────────────────────────────────────────────
  //
  // Registration instrumentation (2026-10-07) stops at
  // registration_completed; nothing measured what happened next, while 85% of
  // signups left on day one. These four span the one journey that matters on
  // day one: reach Matches, see the nudge, act, and complete.
  //
  // first_message_sent is deliberately NOT fired on a Say hi tap. A tap is not
  // a conversation, and a metric that counted it would flatter the panel.

  Future<void> firstSessionMatchesShown({required int matchCount}) =>
      _log('first_session_matches_shown', {'match_count': matchCount});

  Future<void> firstSessionGuidanceShown({required int timesShown}) =>
      _log('first_session_guidance_shown', {'times_shown': timesShown});

  Future<void> firstSessionSayHiTapped({required int position}) =>
      _log('first_session_say_hi_tapped', {'position': position});

  Future<void> firstMessageSent() => _log('first_message_sent', {});
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/services/analytics_service.dart`
Expected: no `error` or `warning` lines

- [ ] **Step 3: Commit**

```bash
git add lib/services/analytics_service.dart
git commit -m "feat(analytics): first-session funnel events"
```

---

### Task 4: The panel widget and its copy

**Files:**
- Create: `lib/pages/community/first_session/matches_first_session_panel.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/community/matches_first_session_panel_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks (presentational only).
- Produces: `class MatchesFirstSessionPanel extends StatelessWidget { const MatchesFirstSessionPanel({super.key, required this.matchCount}); final int matchCount; }`.

- [ ] **Step 1: Add the two strings**

In `lib/l10n/app_en.arb`, before the closing `}`, add a comma to the current last entry and append:

```json
  "firstSessionMatchesTitle": "{count} people picked for you today",
  "@firstSessionMatchesTitle": {
    "description": "First line of the first-session panel on the Matches tab",
    "placeholders": {
      "count": { "type": "int" }
    }
  },
  "firstSessionMatchesBody": "Say hi — a first message is all it takes."
```

- [ ] **Step 2: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: completes without error; `l10n.firstSessionMatchesTitle` and `l10n.firstSessionMatchesBody` exist. Other locales fall back to English.

- [ ] **Step 3: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/first_session/matches_first_session_panel.dart';

Widget _host({required double width, int matchCount = 6}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MatchesFirstSessionPanel(matchCount: matchCount),
          ),
        ),
      ),
    );

void main() {
  testWidgets('it names the count and the one action', (tester) async {
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    expect(find.textContaining('6'), findsWidgets);
    expect(find.textContaining('Say hi'), findsOneWidget);
  });

  testWidgets('it does not overflow at a narrow phone width', (tester) async {
    // Same failure class as the chat_app_bar overflow found on 2026-10-09:
    // unconstrained text in a bounded row.
    await tester.pumpWidget(_host(width: 280));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('it has no dismiss control', (tester) async {
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    // A dismiss invites dismissal INSTEAD of acting; the view cap bounds the
    // annoyance instead.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/community/matches_first_session_panel_test.dart`
Expected: FAIL — `Error when reading '.../matches_first_session_panel.dart'`

- [ ] **Step 5: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The first-session nudge on the Matches tab.
///
/// Deliberately a list header, not an overlay: the growth spec argues against
/// adding friction at the moment someone is deciding whether to stay, and an
/// overlay is the largest way to build the thing it argues against. It points
/// at one action instead of narrating the screen.
///
/// No dismiss control -- a dismiss invites dismissal instead of acting, and
/// `kMaxGuidanceViews` already bounds how often this appears.
class MatchesFirstSessionPanel extends StatelessWidget {
  const MatchesFirstSessionPanel({super.key, required this.matchCount});

  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.waving_hand_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          // Flexible so a longer localized string wraps instead of overflowing.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.firstSessionMatchesTitle(matchCount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.firstSessionMatchesBody,
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/community/matches_first_session_panel_test.dart`
Expected: PASS, 3 tests

- [ ] **Step 7: Commit**

```bash
git add lib/pages/community/first_session/matches_first_session_panel.dart lib/l10n/ test/community/matches_first_session_panel_test.dart
git commit -m "feat(matches): first-session panel widget and copy"
```

---

### Task 5: Wire the panel and three events into the Matches tab

**Files:**
- Modify: `lib/pages/community/tabs/matches_tab.dart`
- Test: `test/community/matches_first_session_wiring_test.dart`

**Interfaces:**
- Consumes: `shouldShowFirstSessionGuidance`, `kMaxGuidanceViews` (Task 1); `FirstSessionStore`, `FirstSessionState` (Task 2); `firstSessionMatchesShown`, `firstSessionGuidanceShown`, `firstSessionSayHiTapped` (Task 3); `MatchesFirstSessionPanel` (Task 4).
- Produces: `final firstSessionStateProvider = FutureProvider<FirstSessionState>((ref) => FirstSessionStore.read());` exported from `lib/pages/community/first_session/first_session_store.dart`.

- [ ] **Step 1: Add the provider to the store file**

Append to `lib/pages/community/first_session/first_session_store.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read once per Matches mount. Not autoDispose-cached across rebuilds on
/// purpose: `recordShown` invalidates it so the cap advances.
final firstSessionStateProvider =
    FutureProvider<FirstSessionState>((ref) => FirstSessionStore.read());
```

Move the `import` to the top of the file with the others.

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';

/// The session guard: `timesShown` must advance once per SESSION, not once
/// per rebuild. A ListView header rebuilds on every scroll frame, so an
/// unguarded increment would burn the three-view cap in seconds and the
/// panel would never be seen again.
void main() {
  test('the cap survives a rebuild-heavy session', () {
    var recorded = 0;
    var alreadyRecordedThisSession = false;

    void onPanelBuilt() {
      if (alreadyRecordedThisSession) return;
      alreadyRecordedThisSession = true;
      recorded++;
    }

    for (var frame = 0; frame < 50; frame++) {
      if (shouldShowFirstSessionGuidance(
          isNewUser: true, hasMessaged: false, timesShown: recorded)) {
        onPanelBuilt();
      }
    }

    expect(recorded, 1, reason: 'one session must cost one view, not fifty');
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/community/matches_first_session_wiring_test.dart`
Expected: PASS immediately — this test pins the guard's logic, not the widget. If it fails, the guard shape below is wrong; fix the test before continuing.

- [ ] **Step 4: Wire the Matches tab**

In `lib/pages/community/tabs/matches_tab.dart`:

Add imports:

```dart
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/pages/community/first_session/matches_first_session_panel.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
```

Add to `_MatchesTabState`:

```dart
  /// One view per session, not per rebuild: the ListView header rebuilds on
  /// every scroll frame and would otherwise burn kMaxGuidanceViews instantly.
  bool _guidanceRecordedThisSession = false;
  bool _matchesShownReported = false;

  void _recordGuidanceShown(int timesShown) {
    if (_guidanceRecordedThisSession) return;
    _guidanceRecordedThisSession = true;
    AnalyticsService.instance.firstSessionGuidanceShown(timesShown: timesShown);
    FirstSessionStore.recordShown()
        .then((_) => ref.invalidate(firstSessionStateProvider));
  }

  void _reportMatchesShown(int count) {
    if (_matchesShownReported || count == 0) return;
    _matchesShownReported = true;
    AnalyticsService.instance.firstSessionMatchesShown(matchCount: count);
  }
```

In `build`, immediately before `child: ListView.builder(`, compute eligibility:

```dart
          final isNew = ref.watch(userProvider).maybeWhen(
                data: (u) => u.isNewUser,
                orElse: () => false,
              );
          final session = ref.watch(firstSessionStateProvider).maybeWhen(
                data: (s) => s,
                orElse: () => FirstSessionState.unknown,
              );
          final showGuidance = shouldShowFirstSessionGuidance(
            isNewUser: isNew,
            hasMessaged: session.hasMessaged,
            timesShown: session.timesShown,
          );
          if (isNew) _reportMatchesShown(matches.length);
```

An empty or errored batch never reaches this code: `matches_tab.dart` takes a
separate `_Empty` / `_LoadError` branch that renders no list header, so the
panel cannot appear there and `first_session_matches_shown` cannot fire. That
is the behaviour the spec asks for -- do NOT add the panel to the empty state.
A new user with no matches has a supply problem, not a guidance problem.

Inside `itemBuilder`, in the `if (i == 0)` branch, insert the panel as the first child of the existing `Column`:

```dart
                      if (showGuidance) ...[
                        Builder(builder: (_) {
                          _recordGuidanceShown(session.timesShown);
                          return MatchesFirstSessionPanel(
                            matchCount: matches.length,
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
```

In `_sayHi`, before `Navigator.push`, add:

```dart
    AnalyticsService.instance.firstSessionSayHiTapped(
      position: _visibleMatches.indexOf(m),
    );
```

If no `_visibleMatches` field exists, pass `position: 0` rather than inventing one — position is a nice-to-have, the event is not.

- [ ] **Step 5: Run the analyzer and the suite**

Run: `flutter analyze` then `flutter test`
Expected: 0 errors, 0 warnings; all tests pass

- [ ] **Step 6: Commit**

```bash
git add lib/pages/community/ test/community/matches_first_session_wiring_test.dart
git commit -m "feat(matches): show the first-session panel and report the funnel"
```

---

### Task 6: Fire the conversion event from the send path

**Files:**
- Modify: `lib/providers/provider_root/message_provider.dart:174` (`sendMessage`)
- Test: `test/community/first_session_conversion_test.dart`

**Interfaces:**
- Consumes: `FirstSessionStore.markMessaged` (Task 2), `firstMessageSent` (Task 3).
- Produces: nothing for later tasks.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';

/// The conversion event counts a message SENT, not a Say hi TAPPED. It must
/// also fire once: the flag is the guard, so a chatty user does not report
/// first_message_sent forever.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the first send marks the flag; later sends are no longer first',
      () async {
    SharedPreferences.setMockInitialValues({});

    expect((await FirstSessionStore.read()).hasMessaged, isFalse,
        reason: 'before any send this is the first');

    await FirstSessionStore.markMessaged();

    expect((await FirstSessionStore.read()).hasMessaged, isTrue,
        reason: 'a second send must see itself as not-first');
  });

  test('marking twice stays true and does not throw', () async {
    SharedPreferences.setMockInitialValues({});
    await FirstSessionStore.markMessaged();
    await FirstSessionStore.markMessaged();
    expect((await FirstSessionStore.read()).hasMessaged, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/community/first_session_conversion_test.dart`
Expected: PASS if Task 2 is merged. This pins the once-only contract the wiring below relies on; if it fails, Task 2 is wrong.

- [ ] **Step 3: Wire the send path**

In `lib/providers/provider_root/message_provider.dart`, add imports:

```dart
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
```

Add this private helper to the same class as `sendMessage`:

```dart
  /// Report the first message this user ever sends, once.
  ///
  /// Fired here rather than from the Say hi button because a tap is not a
  /// conversation -- counting taps would flatter the first-session panel.
  /// Best effort: analytics and prefs must never fail a send.
  Future<void> _reportFirstMessageIfFirst() async {
    try {
      final state = await FirstSessionStore.read();
      if (state.hasMessaged) return;
      await FirstSessionStore.markMessaged();
      AnalyticsService.instance.firstMessageSent();
    } catch (_) {
      // Never let reporting break sending.
    }
  }
```

In `sendMessage`, at **every** branch that returns `{'success': true, ...}` (there are two — the multipart path and the JSON path, both gated on `response.statusCode == 201`), insert immediately before the `return`:

```dart
          unawaited(_reportFirstMessageIfFirst());
```

Add `import 'dart:async';` if `unawaited` is not already imported.

- [ ] **Step 4: Run the analyzer and the suite**

Run: `flutter analyze` then `flutter test`
Expected: 0 errors, 0 warnings; all tests pass

- [ ] **Step 5: Tick the plan items and commit**

Tick the §0c boxes in `docs/REMAINING_WORK.md` that this plan completes, and summarise what remains in the commit body, per `CLAUDE.md`.

```bash
git add lib/providers/provider_root/message_provider.dart test/community/first_session_conversion_test.dart docs/REMAINING_WORK.md
git commit -m "feat(matches): fire first_message_sent from the send path"
```

---

## Verification

After Task 6:

- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `flutter test` — all pass
- [ ] Manual: a fresh account lands on Matches and sees the panel; sending one message makes it disappear permanently
- [ ] Manual: an account older than 6 days never sees it
- [ ] Firebase: the four events arrive, and `first_message_sent / first_session_matches_shown` is readable

Note that `WELCOME_WAVE_ENABLED` and `LIFECYCLE_PUSH_ENABLED` are still off. They are the two pieces that create social pull, both Day-0 in the rollout plan, and the funnel measured without them understates the path.
