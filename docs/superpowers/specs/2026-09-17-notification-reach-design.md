# Notification reach — design

**Date:** 2026-09-17
**Status:** approved, ready for implementation plan
**Goal:** Make the daily study reminder reachable by the users who already have
the app, so that study retention becomes measurable for the first time.

## Why

BananaTalk is a daily-habit product. Its daily habit does not form. Measured
against production on 2026-09-17:

```
1,838  registered
  792  active in the last 30 days
  284  can receive a push notification at all   <-- the binding constraint
  208  of those get it at the right local hour
   53  daily-drop completions, ever, by 32 distinct people
```

Supporting distributions:

- `fcmTokens` non-empty: 441 / 1,838 (24%)
- `timezone` set: 290 / 1,838 (16%)
- `currentStreak`: 1,327 users at 0; maximum 4
- `longestStreak`: 1,093 at 0; 193 at exactly 1; then 34, 14, 9, 3 at five,
  3 at eight, 1 at nine
- Completions per user: 17 people did it once, 12 twice, 3 four times

Two readings of that last pair matter, and they pull in opposite directions:

1. **193 users reached a longest streak of exactly 1 and never returned.** That
   is the dominant failure and it is a returning problem, not a content problem
   — they came once and nothing brought them back.
2. **Seven users reached five days or more, one reached nine.** The loop is
   capable of holding people. Whatever is wrong is not that the content is
   inherently unusable.

Together they say: the loop works for the few people who stay in it, and almost
nobody is being brought back into it.

## Root cause

A single cold permission prompt at app launch cascades into every number above.

`NotificationService.initialize()` calls `_requestPermission()` unconditionally
(`lib/services/notification_service.dart:101`), and `initialize()` is invoked
from `lib/main.dart:108` and `lib/pages/home/splash_screen.dart:74` — before the
user has seen a single screen or has any reason to accept.

Denial is then terminal in three compounding ways:

- `_getFCMToken()` runs only inside the `authorized` branch. The `else` branch
  is empty and the enclosing `catch` is empty, so a denial is silent.
- `unawaited(_reportTimezone())` sits **inside the FCM token-registration
  block** (`notification_service.dart:571`). Timezone therefore depends on a
  permission it does not need. This is why the 290 users with a timezone are a
  subset of the 441 with a token.
- `lib/pages/settings/notification_preferences_screen.dart` toggles server-side
  preferences but never re-requests permission and never opens system settings.
  A user who declined has no path back, and is shown toggles that can never
  fire.

The delivery pipeline itself is sound and is NOT the problem:

- `jobs/scheduler.js` runs delivery hourly, anchored to :15 past the UTC hour
  rather than to process boot (a deliberate fix already in place).
- `jobs/dailyDropJob.js:180` selects `lastActive` within 30 days AND
  `fcmTokens.0` exists — correct, but it can only ever return the 284.
- `lib/localHour.js` fires when the user's local hour equals their configured
  hour, default 19. With no timezone it falls back to UTC, so 19:00 UTC lands at
  04:00 Seoul, 03:00 Shanghai, 00:00 Tashkent. 76 of the 284 reachable users are
  in that state.

## Design

### 1. Decouple timezone from notification permission

Promote `_reportTimezone()` to a public `reportTimezone()` and call it from the
post-login bootstrap, independent of `initialize()` and of the permission
outcome.

Timezone is useful on its own (gathering times, quiet hours, delivery bucketing)
and never required notification permission. This is the smallest change in the
document and the only one that helps every logged-in user immediately, including
those who have already denied notifications and will never be asked again.

Failures stay swallowed, as today: a lost timezone report must not block
startup.

### 2. Move the ask out of splash; prime it in chat

`initialize()` stops asking unconditionally. It reads
`FirebaseMessaging.getNotificationSettings()` and branches on
`authorizationStatus`:

| status | behaviour |
|---|---|
| `authorized` / `provisional` | proceed exactly as today — no user-visible change |
| `notDetermined` | set up local notifications and handlers, but do NOT ask; mark the ask as pending |
| `denied` | do not ask (the OS will not show the dialog); mark eligible for recovery |

The pending ask is then triggered by the user's first chat interaction, framed
honestly for chat: "Get notified when someone replies."

**Why chat rather than study**, given study is the goal: 43% of active users
sent a message in the last 30 days; 4% have ever completed a daily drop.
Priming on drop completion would reach almost nobody — it is the same
chicken-and-egg that produced these numbers. It is one OS permission, so
granting it in chat is what makes the daily study reminder possible at all.

The prime shows at most once. If the user dismisses it without granting, it does
not reappear; the recovery path below is the route thereafter.

### 3. Recovery path for users who already declined

This is the only mechanism that can help the 1,397 users who have no token
today. On iOS and Android 13+, once permission is denied the system dialog will
never be shown again, so priming is irrelevant to the existing base.

Two surfaces, both using `app_settings` (already in `pubspec.yaml`):

- A persistent card at the top of `notification_preferences_screen.dart`, shown
  only when status is `denied`, explaining that notifications are off at the
  system level with a button that opens the system screen. The existing toggles
  are disabled while in this state — showing live-looking toggles that cannot
  fire is the current bug.
- A dismissible banner on the Study "Today" screen, shown only when status is
  `denied` AND the user has completed at least one station — i.e. only to people
  who have demonstrated interest. Dismissal is permanent.

### 4. Measurement

Without these the change is unfalsifiable. Baselines recorded 2026-09-17:

| metric | today |
|---|---|
| `fcmTokens` non-empty among 30-day actives | 284 / 792 |
| `timezone` set, all users | 290 / 1,838 |
| `timezone` set among 30-day actives | 290 / 792 |
| daily-drop completions per week | ~12 (53 in 30 days) |
| users with `currentStreak` >= 1 | 23 |

Expected movement: timezone coverage should approach 100% of logged-in actives
within one release cycle (it no longer depends on anything the user must
accept). Token coverage should rise only for new and `notDetermined` users;
recovery on the denied base is expected to convert in the low single digits.

## Out of scope

Deliberately excluded so this stays one reviewable change:

- Streak mechanics — freezes, grace days, catch-up. Worth doing, but tuning a
  loop that 85% of users cannot enter teaches nothing. Revisit once reach is
  fixed and the numbers mean something.
- Study content changes. The two-option quick-check defect and the position
  clustering were fixed separately (`lib/answerShuffle.js`,
  `migrations/rebalanceGeneratedAnswers.js`).
- The safety gaps found in the same audit — gatherings/clubs have no report or
  block entry point, and block is reachable from fewer surfaces than report.
  These are real and independent; they get their own spec.
- Email or SMS as a notification fallback. A larger decision than this change.

## Testing

Testable without a device, and these are the parts that carry the logic:

- The `authorizationStatus` branch: each of the three states produces the right
  outcome, and `authorized` is byte-for-byte today's behaviour.
- The prime trigger fires once and never again after grant or dismissal.
- `reportTimezone()` runs and succeeds when permission is denied — the
  regression that this whole document exists to prevent.
- Recovery surfaces appear only in `denied`, and the preference toggles are
  disabled in that state.

Not testable here, and stated rather than implied: the OS permission dialog
itself, and whether a real device returns the expected status after a real
denial. That needs manual verification on both platforms before release.

## Risks

- **Fewer users are asked at all.** Moving the prompt out of splash means users
  who would have blindly accepted at launch are now asked later, or not at all
  if they never open a chat. The bet is that a contextual ask converts better
  than a cold one; if token coverage among new users falls instead of rising,
  the trigger is wrong and should move earlier, not back to splash.
- **Recovery converts poorly.** Sending someone to system settings is
  high-friction. The 1,397 will not return in bulk.
- **This changes no content.** If completions stay flat once reach is fixed,
  that is a real and useful answer — it means the content is the problem — and
  it is an answer currently impossible to obtain.
