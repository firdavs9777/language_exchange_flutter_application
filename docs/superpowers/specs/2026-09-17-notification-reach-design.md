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

The audit's first reading — "a cold permission prompt at splash whose denial is
terminal" — is correct for Android and WRONG for iOS. The two platforms fail in
opposite directions, and 407 of the 442 token holders are iOS:

| platform | users with a token |
|---|---|
| iOS | 407 |
| Android | 35 |

### iOS: granted silently, delivered invisibly

`_requestPermission()` passes `provisional: true`
(`lib/services/notification_service.dart:154`) and is the ONLY request path in
the app — full authorization is never requested, anywhere.

Provisional authorization is granted by iOS without showing a dialog, which is
why iOS token coverage is comparatively healthy. But provisional notifications
are delivered **quietly**: no banner, no sound, no lock-screen alert. They
accumulate in Notification Center where nobody looks.

So the daily study reminder is very likely being delivered to hundreds of iOS
users and seen by almost none of them. For a habit product this is worse than
not sending it, because it looks like it is working.

The app cannot currently tell: lines 103-104 and 675-676 treat
`AuthorizationStatus.provisional` as equivalent to `authorized`, and the status
is never persisted or sent to the backend.

### Android: the cold prompt, as originally diagnosed

`POST_NOTIFICATIONS` is correctly declared in
`android/app/src/main/AndroidManifest.xml:57`, so on Android 13+
`requestPermission()` raises a real runtime dialog — at splash, before the user
has seen anything. Denial there is permanent.

35 Android token holders is consistent with heavy denial, but the true denial
rate is **not measurable today**: tokenless users carry no platform field, so
there is no way to know how many Android users exist to have denied. Fixing that
blindness is part of this work rather than a nice-to-have.

### Both platforms: timezone and blindness

- `unawaited(_reportTimezone())` sits inside the FCM token-registration block
  (`notification_service.dart:571`), so timezone depends on a permission it does
  not need. This is why the 290 users with a timezone are a subset of the 441
  with a token.
- `notification_preferences_screen.dart` toggles server preferences but never
  re-requests permission and never opens system settings, so a denied user sees
  toggles that cannot fire.

The delivery pipeline itself is sound and is NOT the problem: `jobs/scheduler.js`
runs hourly anchored to :15 past the UTC hour; `jobs/dailyDropJob.js:180`
correctly selects active users holding a token; `lib/localHour.js` fires at the
user's configured local hour, defaulting to 19, falling back to UTC when no
timezone is known (which puts 76 reachable users at 04:00 Seoul / 03:00
Shanghai).

## Design

### 1. Decouple timezone from notification permission

Promote `_reportTimezone()` to a public `reportTimezone()` and call it from the
post-login bootstrap, independent of `initialize()` and of the permission
outcome.

Timezone is useful on its own and never required notification permission. It is
the smallest change here and the only one that helps every logged-in user
immediately — including those already denied, who will never be asked again.

Failures stay swallowed, as today: a lost timezone report must not block startup.

### 2. Make the authorization level visible

Send the resolved `authorizationStatus` to the backend alongside the token, and
store it on the user. Without this, none of the rest can be measured: provisional
and full are indistinguishable server-side today, so "407 iOS users have tokens"
cannot be turned into "how many can actually see a reminder".

This is deliberately first among the behavioural changes. It is also what makes
the iOS finding above falsifiable rather than merely argued.

### 3. Ask for what each platform actually needs, at a primed moment

`initialize()` stops requesting unconditionally. It reads
`getNotificationSettings()` and branches:

| status | behaviour |
|---|---|
| `authorized` | proceed exactly as today — no user-visible change |
| `provisional` (iOS) | keep the token and quiet delivery; mark an UPGRADE as pending |
| `notDetermined` (Android) | set up handlers but do NOT ask; mark an ASK as pending |
| `denied` | do not ask — the OS will not show the dialog; mark eligible for recovery |

The pending ask or upgrade fires on the user's first chat interaction, framed
honestly: "Get notified when someone replies." On iOS this is a second
`requestPermission()` call with `provisional: false`, which is what raises the
real dialog and converts quiet delivery into visible delivery. On Android it is
the first and only dialog, now shown in context rather than at splash.

**Why chat rather than study**, given study is the goal: 43% of active users sent
a message in the last 30 days; 4% have ever completed a daily drop. Priming on
drop completion would reach almost nobody — that is the same chicken-and-egg that
produced these numbers. It is one OS permission, so granting it in chat is what
makes the study reminder possible at all.

Shown at most once. If dismissed without granting, it does not reappear; recovery
below is the route thereafter.

### 4. Recovery path for users who already declined

The only mechanism that can help users with no token today. Once denied, iOS and
Android 13+ never show the dialog again, so priming is irrelevant to them.

Two surfaces, both using `app_settings` (already in `pubspec.yaml`):

- A card at the top of `notification_preferences_screen.dart`, shown only when
  status is `denied`, with a button opening the system screen. The existing
  toggles are disabled in that state — showing live-looking toggles that cannot
  fire is the current bug.
- A dismissible banner on the Study "Today" screen, shown only when status is
  `denied` AND the user has completed at least one station, so it reaches only
  people who have shown interest. Dismissal is permanent.

### 4. Measurement

Without these the change is unfalsifiable. Baselines recorded 2026-09-17:

| metric | today |
|---|---|
| `fcmTokens` non-empty among 30-day actives | 284 / 792 |
| `timezone` set, all users | 290 / 1,838 |
| `timezone` set among 30-day actives | 290 / 792 |
| daily-drop completions per week | ~12 (53 in 30 days) |
| users with `currentStreak` >= 1 | 23 |
| iOS token holders on `provisional` (invisible delivery) | unknown — not recorded until Design 2 lands |
| Android users with no token | unknown — tokenless users carry no platform field |

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

- **The iOS upgrade can lose what provisional already gives.** Today every iOS
  user gets a token silently. Asking for full authorization introduces a dialog
  that can be refused, and a refusal on iOS is permanent. A user who refuses is
  worse off than a provisional user, who at least receives quiet notifications.
  This is the central bet of the change: a visible reminder for some beats an
  invisible one for all. It must be measured (Design 2) before being judged, and
  the trigger moved earlier or later rather than reverted blindly.
- **Fewer Android users are asked at all.** Moving the prompt out of splash means
  users who would have blindly accepted are now asked later, or never if they do
  not open a chat. If token coverage among new Android users falls instead of
  rising, the trigger is wrong and should move earlier, not back to splash.
- **Recovery converts poorly.** Sending someone to system settings is
  high-friction. The 1,397 will not return in bulk.
- **This changes no content.** If completions stay flat once reach is fixed,
  that is a real and useful answer — it means the content is the problem — and
  it is an answer currently impossible to obtain.
