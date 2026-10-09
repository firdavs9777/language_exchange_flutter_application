# First-Session Guidance: one conversation, measured

## Why

85% of signups leave on day one. D1 is 15%, D7 is 7%, and the monetization
plan is explicitly gated on D7 reaching 20%, so this is the number everything
else waits behind.

The diagnosis in `2026-10-02-monetization-growth-design.md` is not that people
are confused by the UI:

> nothing happens to a new user. Fix: make something happen in the first five
> minutes, then pull them back with a *person*, not a nag.

Most of that path is already built:

| Piece | State (2026-10-09) |
|---|---|
| New users land on Matches | built, live (`matchesLayoutEnabled: true`) |
| Daily Matches batch + reason chips | built, live |
| Opener chips in an empty conversation | built |
| Stall rescue banner | built |
| Welcome wave (one inbound wave on day one) | built, flag **off** |
| Lifecycle push day 1/3/7 | built, flag **off** |

Two gaps remain. A first-timer lands on Matches, sees six strangers and
nothing says what the screen is or that tapping **Say hi** is the thing to do.
And nothing measures the first session at all — instrumentation added on
2026-10-07 stops at `registration_completed`.

This spec closes both, for Matches only.

## Goal and non-goals

**Goal.** A first-time user sends one real message in their first session, and
we can measure what share do.

**Explicit non-goals.**

- Not a tour. No coach marks, no spotlight overlay, no dimmed scrim. The
  growth spec argues against adding friction at the moment someone is deciding
  whether to stay, and an overlay framework is the largest, most fragile way
  to build the thing it argues against.
- Not an explanation of the app. Orientation ("what is BananaTalk") is a
  different goal with a different design.
- Not AI Study or Moments. Both were raised as important and both are tracked
  in `docs/REMAINING_WORK.md`, but neither has a stated goal yet, and
  "guidance on three screens with three different goals" is three designs, not
  one. See *Follow-on surfaces*.

**Success criterion.** `first_message_sent / first_session_matches_shown`
becomes a number you can read, and the panel's contribution to it is
attributable. No target is set here: there is no baseline yet, which is the
point.

## Design

Three small pieces and one integration point outside the Matches screen. No
new navigation, no overlay, nothing that can swallow a tap or trap a user.

### 1. Eligibility is a pure predicate

```dart
bool shouldShowFirstSessionGuidance({
  required bool isNewUser,   // Community.isNewUser — exists, joined <= 6 days
  required bool hasMessaged, // local flag, set on first successful send
  required int timesShown,   // local counter
});
```

Returns true while the account is new, the user has not sent a first message,
and the panel has been shown fewer than `kMaxGuidanceViews` (3) times.

The view cap is load-bearing. Without it, someone who never messages sees the
same banner every session for six days, which is nagging rather than guidance.

It is a pure function for the same reason `photoStillRequired` and
`stepNameAt` are: a rule that lives inline in a widget drifts from the UI
silently, and this repo has already been bitten by exactly that — the
registration photo step and its submit gate disagreed for months and locked
OAuth users out.

### 2. `MatchesFirstSessionPanel`

Occupies the list header slot `matches_tab.dart` already renders at index 0
(today: "Matches today"). Two lines — what this screen is, and the one action.

No dismiss control. A dismiss button invites dismissal *instead of* acting,
and the view cap already bounds the annoyance. The panel does not block
scrolling or interaction; it is a header, not a modal.

### 3. State

`SharedPreferences`, following the existing `ai_tools_scroll_hint` precedent:

- `first_conversation_done` (bool)
- `first_session_guidance_shown_count` (int)

Local state resets on reinstall and does not follow a second device. That is
accepted: `isNewUser` bounds the error to six days, and the alternative — an
API call on every cold start — spends a network round trip on a low-stakes
decision. If the follow-on surfaces need shared state, this is the decision to
revisit first.

### 4. The integration point

`_sayHi` in `matches_tab.dart` opens `ChatScreen`. The conversion event must
fire when a message is actually **sent**, not when Say hi is tapped — tapping
is not a conversation, and a metric that counts it would flatter the panel.

`message_provider.sendMessage` is the central send path. On a successful first
send it sets `first_conversation_done` and fires `first_message_sent`. This is
the only change outside the Matches screen.

## Data flow

```
Matches loads
  -> predicate decides
  -> panel renders at index 0        [first_session_guidance_shown]
  -> user taps Say hi                [first_session_say_hi_tapped]
  -> ChatScreen opens (opener chips, already built)
  -> message sends                   [first_message_sent]  + flag set
```

`first_session_matches_shown` fires when a new user reaches Matches with at
least one card, and is the denominator.

## Instrumentation

Four events on the existing `AnalyticsService` pattern — typed methods over
`_log`, fire-and-forget, never awaited from the UI thread:

| Event | Fires when |
|---|---|
| `first_session_matches_shown` | new user reaches Matches with >= 1 card |
| `first_session_guidance_shown` | the panel renders |
| `first_session_say_hi_tapped` | Say hi tapped from a match card |
| `first_message_sent` | a first message sends successfully |

Together these answer: do new users reach Matches, do they see the panel, do
they act, and does the action complete. A leak at any step is visible.

## Error handling

- Every prefs read and write is wrapped; a storage failure defaults to **not
  showing** the panel. A hint must never be able to break the Matches screen.
- Analytics is already fire-and-forget and swallows SDK errors.
- A failed send does not set `first_conversation_done`, so the panel correctly
  persists for a user whose first attempt did not land.
- An empty or failed Matches batch shows neither the panel nor
  `first_session_matches_shown`: with no cards there is no action to point at.

## Testing

- **Unit, the predicate.** Every combination of the three inputs, including
  the view cap boundary and a non-new account that has never messaged.
- **Widget.** The panel renders for an eligible user and is absent for each
  ineligible reason.
- **Widget.** The panel does not render when the batch is empty or errored.

Not covered: the analytics calls themselves. `AnalyticsService` is a singleton
over Firebase with no injection seam — the same limitation recorded for the
voice-room fix. Adding that seam is tracked separately rather than smuggled in
here.

## Copy and localization

Two new keys in `app_en.arb`, then `flutter gen-l10n`. Other locales fall back
to English until the native-review pass in
`docs/l10n/native-qa-strings-2026-10.csv`. The copy is deliberately two short
lines to limit that debt.

Copy intent, to be finalized against the existing voice: one line naming what
the screen is ("Six people picked for you today"), one line naming the single
action and lowering its cost ("Say hi — a first message is all it takes").

## Follow-on surfaces

AI Study and Moments were both raised as important. Neither is in this spec,
because neither has a stated goal, and the goal is what determines the design:

- **Matches** had a clear one — produce a conversation — which is why a
  two-line header pointing at a single action is enough.
- **AI Study** (`lib/pages/learning/`, `lib/pages/ai/` — tutor, quiz,
  pronunciation, grammar, translation, lesson builder) has no obvious single
  action. "Do a lesson", "ask the tutor" and "review vocabulary" are different
  activation events with different value.
- **Moments** (`lib/pages/moments/feed/`) already renders `PromptOfDayCard` at
  the top of the feed, which is the same structural slot this panel uses — so
  the pattern transfers cheaply once the goal is known. Posting and reading are
  different goals.

The mechanism here is built to transfer: the predicate takes plain booleans
rather than reaching for Matches state, and the panel is a presentational
widget. What does not transfer is the decision about what each screen is for.

Both are recorded in `docs/REMAINING_WORK.md`.

## Risks

- **A header can be scrolled past.** This is the main risk and it is accepted
  deliberately: the instrumentation exists precisely so "the panel is ignored"
  is a measurable finding rather than an argument. If
  `say_hi_tapped / guidance_shown` is poor, escalating to a higher-salience
  treatment is a small step from here, and will be an informed one.
- **Local state lies after a reinstall.** Bounded to six days by `isNewUser`.
- **The panel is useless while the batch is empty.** Deliberate; see error
  handling. A new user with no matches has a supply problem, not a guidance
  problem.
