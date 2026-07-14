# Workstream E-core: Push Reach + Notification Correctness + Email Compliance — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make notifications actually reach users: fix FCM token capture (83% of users unreachable), fix the 5 push-correctness bugs found in the 2026-07-13 audit, and make marketing/digest email CAN-SPAM/GDPR-compliant with working unsubscribe.

**Architecture:** All backend fixes are small, surgical repairs to existing jobs/services (no new subsystems). The app-side token fix hardens the existing registration path (permission timing, re-registration on every launch, token-refresh listener, retry). Email compliance adds a signed unsubscribe endpoint + `List-Unsubscribe` headers reusing the existing `privacySettings` email booleans.

**Tech Stack:** Node/Express + Mongoose (backend, node:test), Flutter + firebase_messaging (app), Mailgun.

**Audit of record:** push-pipeline audit 2026-07-13 (session) + paywall/notifications/email scouts 2026-07-12 in `docs/superpowers/specs/2026-07-12-workstream-d-language-rooms-design.md` (Workstream E section).

**Repos:**
- Backend: `/Users/davis/Desktop/Personal/language_exchange_backend_application`
- App: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

**Global constraints:**
- **Branch:** `workstream-e-core` in both repos off `main`. **NO COMMITS (user instruction 2026-07-13): ignore every "Commit" step below — leave all work as uncommitted working-tree changes; single commit at the gate on user go-ahead. Branch tips must stay app=fb7b60d, backend=243eafa until then.**
- **Backend tests:** node built-in runner; run with nvm Node v24.18.0 (`~/.nvm/versions/node/v24.18.0/bin/node --experimental-test-module-mocks --test services/*.test.js test/*.test.js`). Local Node v25 is broken (`SlowBuffer`). Baseline: 1 pre-existing failure (`profileVisitCleanup`) — add no new failures.
- **App:** `package:` imports only; `flutter analyze` 0 errors per commit.
- **Verified facts (do not re-derive):** re-engagement job IS already scheduled (`jobs/scheduler.js:455`, Mon 10 AM KST) — no work needed. Streak reminders are NOT scheduled (defined `jobs/learningJobs.js:323`, exported `:418`, never called in `startLearningJobs`). Subscription-reminder crash confirmed (`jobs/notificationJobs.js:9` imports only `{ shouldNotify }`; `:197` calls `notificationService.send(...)` → ReferenceError).

---

## BACKEND PHASE

### Task 1: Fix subscription-reminder crash

**Files:** Modify `jobs/notificationJobs.js`; Test `test/notificationJobs.imports.test.js`.

- [ ] **Step 1: Write failing test** — require the module and assert the function's dependencies resolve: requiring `jobs/notificationJobs.js` and calling a small extracted helper (or at minimum `assert.equal(typeof jobs.sendSubscriptionReminders, 'function')` plus a static check that the module's source no longer references a bare `notificationService` without importing it — read the file text in the test and assert `/require\(.*notificationService.*\)/` captures the full-module import).
- [ ] **Step 2: Fix the import:** change `jobs/notificationJobs.js:9` to import the whole module and keep the destructure:

```js
const notificationService = require('../services/notificationService');
const { shouldNotify } = notificationService;
```

- [ ] **Step 3: Verify `notificationService.send` exists** (grep `services/notificationService.js` exports). If the exported API is named differently (e.g. `sendSystemNotification`), call the real function at `:197` instead — match the existing call shape used elsewhere for type `'system'`.
- [ ] **Step 4: Run test + full suite (Node v24) → green, no new failures. Commit** `fix(notifications): subscription reminders crashed on missing notificationService import`.

### Task 2: Vocab/SRS + streak reminders gated on the right settings

**Files:** Modify `services/notificationService.js` (**`_shouldSendNotification`** — the `case 'system'` at `:552-556`; NOT the small `shouldNotify` at `:22` — reviewer I1), `jobs/learningJobs.js` (SRS sender `:310`, streak sender `:349-359`); Test `test/shouldSendNotification.gates.test.js`.

Problem: SRS review reminders send as type `'system'` (`learningJobs.js:310` via `notificationService.send`), and `_shouldSendNotification` gates `'system'` on `notificationSettings.marketing` — so turning off marketing silently kills vocab reminders the user explicitly enabled. Streak reminders (Task 3) currently call `fcmService.sendToUser` directly, bypassing gating/history entirely (reviewer C2) — route them through `notificationService.send` for consistency (gate + in-app record + badge).

- [ ] **Step 1: Write failing tests** for `_shouldSendNotification`:
  - type `'srs_review'` with `vocabularyReviewReminders: true, marketing: false` → **allowed**.
  - type `'srs_review'` with `vocabularyReviewReminders: false` → blocked.
  - type `'system'` behavior unchanged (marketing-gated).
  - type `'streak_reminder'` gated on `notificationSettings.streakReminders`.
- [ ] **Step 2: Implement:** add `srs_review` + `streak_reminder` cases to `_shouldSendNotification`'s switch; switch the SRS sender to type `'srs_review'`; **rewrite `sendStreakReminders` to call `notificationService.send(userId, 'streak_reminder', ...)`** instead of raw `fcmService.sendToUser` (reviewer C2 option a — its query filter on `notificationSettings.streakReminders` can stay as a cheap pre-filter). Enum values for both types land in Task 5 (single enum edit — reviewer's sequencing note; run Task 5 before or with this task).
- [ ] **Step 3: Run green (full suite).** (No commit — gate rule.)

### Task 3: Wire streak reminders (dead code → scheduled) — in `jobs/scheduler.js`, NOT learningJobs

**Files:** Modify `jobs/scheduler.js` (reviewer C1: `startLearningJobs`'s `scheduleJob(name, intervalMs, fn)` is interval-only and CANNOT do time-of-day; the KST-timed jobs all live in `jobs/scheduler.js` with `getMillisecondsUntil(hour, minute[, day])` at `:55`).

- [ ] **Step 1:** Add `scheduleStreakReminders()` in `jobs/scheduler.js` following the `scheduleSrsReviewReminders` pattern (`:226-241`): first run at `getMillisecondsUntil(20, 0)` (20:00 KST), then 24h recursive; call `sendStreakReminders` (imported from `jobs/notificationJobs`/`learningJobs` as exported). Wire it in `startScheduler` (~`:457`) next to the other daily jobs.
- [ ] **Step 2:** `node --check`, full suite green. (No commit — gate rule.)

### Task 4: Wave daily summary at 9 AM KST (was 9 AM UTC = 6 PM KST)

**Files:** Modify `jobs/waveDailySummaryJob.js`.

- [ ] **Step 1:** Change `SUMMARY_HOUR_UTC = 9` (`:17`) → `0` (00:00 UTC == 09:00 KST). Also update the header comment (`:4`) and the log strings (`:80`, `:92`) that print the UTC hour (reviewer M2) so logs don't lie.
- [ ] **Step 2:** `node --check`, suite green. (No commit — gate rule.)

### Task 5: Notification persistence integrity — enum + fcm audit set + badge/suppression truth (THE big silent bug)

**Files:** Modify `models/Notification.js:12` (type enum), `services/fcmService.js:8-16` (`NOTIFICATION_TYPE_ENUM`) + suppression remap (`:100-111`, `:118-128`), verify `services/notificationService.js:81-83` badge ordering; Test `test/notificationTypeEnum.test.js`.

**Why this is Critical (2026-07-13 domain audit):** `_saveToHistory` (`notificationService.js:617-634`) swallows Mongoose enum ValidationErrors — so for every type missing from the enum, **the push fires but no in-app record is ever written and the badge still increments** (drift). Confirmed silently-broken live types: **`wave`** (1,091 waves sent, zero records ever), **`comment_reply`**, **`comment_reaction`**, **`comment_mention`**, **`room_mention`** (Workstream D), **`vip_renewal_warning`**. This single fix makes wave/comment/mention history appear in the app for the first time.

- [ ] **Step 1:** Grep the definitive list of types passed to `notificationService.send(...)` (build the test list **from the grep**, not from any illustrative list — reviewer I3; note `scheduled_room_started`/`scheduled_room_reminder`/`voice_room_start` go via raw `fcmService.sendToUser` and never touch the enum — leave them out).
- [ ] **Step 2: Write a failing test** asserting every grep-derived sent type ∈ `Notification` enum AND ∈ `fcmService.NOTIFICATION_TYPE_ENUM` (the caps/quiet-hours audit set — audit fix #1).
- [ ] **Step 3:** Add the missing values to both (additive; expected adds: `wave`, `comment_reply`, `comment_reaction`, `comment_mention`, `room_mention`, `vip_renewal_warning`, plus Task 2's `srs_review` + `streak_reminder`, plus Task 9's `new_follower`).
- [ ] **Step 4: Suppression truth (audit fix #7):** in the two suppressed-record branches (`fcmService.js:100-111`, `:118-128`), stop collapsing unknown types to `'system'` — persist the original type now that the enum accepts it (keep `data.originalType` for back-compat).
- [ ] **Step 5:** Verify `_updateBadgeCount` (`notificationService.js:81-83`) only increments when the history row actually persisted (audit fix #2) — make badge bump conditional on `_saveToHistory` success.
- [ ] **Step 6:** Run green (full suite). (No commit — gate rule.)

### Task 6: Email unsubscribe compliance (List-Unsubscribe + endpoint + link)

**Files:** Create `controllers/emailUnsubscribe.js`, `routes/emailUnsubscribe.js` (public, token-verified); Modify `utils/sendEmail.js`, `utils/emailTemplates.js` (`baseTemplate` footer), `jobs/promotionalEmailJob.js`, `jobs/weeklyDigestJob.js`; Test `test/emailUnsubscribe.test.js`.

Reuse the existing per-user booleans (`privacySettings.emailNotifications`, `privacySettings.weeklyDigest` — already in the User schema) — no new schema.

- [ ] **Step 1: Signed token helper** (in the controller module): `makeUnsubscribeToken(userId, emailType)` = HMAC-SHA256 over `userId:emailType` with `JWT_SECRET` (no expiry — unsubscribe links must work from old emails); `verifyUnsubscribeToken` validates and returns `{userId, emailType}`. TDD: valid round-trip; tampered token rejected.
- [ ] **Step 2: Endpoint** `GET /api/v1/email/unsubscribe?token=...` (public — no auth; the token IS the auth): on valid token set the matching boolean (`promotional` → `privacySettings.emailNotifications=false`; `digest` → `privacySettings.weeklyDigest=false`) and return a tiny confirmation HTML page ("You're unsubscribed"). Invalid token → 400. TDD the decision logic.
- [ ] **Step 3: Headers:** in `utils/sendEmail.js`, accept an optional `unsubscribeUrl` option; when present add Mailgun headers `h:List-Unsubscribe: <url>` and `h:List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058).
- [ ] **Step 4: Footer link:** `baseTemplate` accepts optional `unsubscribeUrl` and renders "Unsubscribe" in the footer when present. Transactional emails (verification/reset/security) pass nothing — no header, no link (correct: transactional mail must not carry unsubscribe).
- [ ] **Step 5: Wire senders:** generate the per-user token/URL and pass it through. **Injection points (reviewer M3):** the promo opt-out check lives inside `emailService.sendPromotionalEmail` (returns `notifications_disabled`) — inject the URL in that **service**, not the job loop; `weeklyDigestJob` **already** gates on `privacySettings.weeklyDigest` + `emailNotifications` in its query (`:66-67`) — do NOT add a redundant check, just thread the URL.
- [ ] **Step 6:** Full suite green. (No commit — gate rule.)

### Task 9: New-follower notifications stop masquerading as friend requests

**Files:** Modify `controllers/users.js:762` (follow trigger), `services/notificationService.js` (new `sendNewFollower` or type switch + `_shouldSendNotification` case), `utils/notificationTemplates.js` (template); enum value lands in Task 5. Test extends `test/shouldSendNotification.gates.test.js`.

Audit fix #6: a follow currently routes through `sendFriendRequest` → users see "friend request" for a follow. Add a distinct `new_follower` type: template ("X started following you"), gate on the existing `notificationPreferences.newFollower` pref, send from the follow path. Keep `friend_request` untouched for real friend requests.

- [ ] Steps: failing gate/template tests → implement → suite green. (No commit.)

### Task 10: Re-enable profile-visit notifications (deliberately disabled, fully built)

**Files:** Modify `controllers/profileVisits.js:67-73` (uncomment the send call).

Audit: the entire pipeline exists (enum has `profile_visit`, pref `notificationSettings.profileVisits`, cap 3/day, bundling 300s window) — only the call site is commented out ("not useful"). User verdict 2026-07-13: profile notifications are important — re-enable for all users, pref + cap gated (no VIP gate in this pass).

- [ ] **Step 1:** Uncomment/restore the `sendProfileVisit` call; confirm it goes through `notificationService.send` (gate + history + caps + bundling apply).
- [ ] **Step 2:** Sanity-test the gate: `notificationSettings.profileVisits: false` → blocked. Suite green. (No commit.)

### Task 11: Wave overflow → daily summary (stop hard-dropping waves)

**Files:** Modify `services/notificationService.js:437` (6-hour hard suppression) + `jobs/waveDailySummaryJob.js`.

Audit upgrade #4: waves beyond the burst limit are hard-suppressed for 6h today; the daily-summary job already exists. Change the overflow path so suppressed waves are counted for the (already-scheduled) daily summary instead of vanishing — i.e., the summary picks up unread waves regardless (verify its query does), and the 6h suppression window only limits *immediate* pushes, which the summary then covers.

- [ ] Steps: read both call sites → adjust so no wave is silently *never* notified → suite green. (No commit.)

**== BACKEND PHASE DONE (T1–T6, T9–T11) ==**

---

## APP PHASE

### Task 7: FCM token capture hardening (the 17% problem)

**Root cause (2026-07-13 scout, ranked):** (1) **Session restore never registers** — `splash_screen.dart:72` initializes `NotificationService` but never calls `registerToken`; `main.dart:105-107` registers only in a narrow already-active-session case. Fresh-login paths DO register (`auth_providers.dart:236-239` email; `google_login_screen.dart:219-226` and `apple_login_screen.dart:179-186` — but only after profile+terms gates). Since most app opens are session restores, this alone explains ~83% missing tokens. (2) Permission-denied users never get a token (no provisional auth; `notification_service.dart:89-90` gates `getToken` on authorized/provisional). (3) Failed register calls are silently swallowed, never retried (`notification_api_client.dart:56-82`, `notification_service.dart:535-537`). (4) `onTokenRefresh` (`notification_service.dart:264-271`) only re-registers if `_currentUserId` was set by a prior explicit `registerToken` call.

**Files:** Modify `lib/pages/home/splash_screen.dart` (~`:72-82`), `lib/main.dart` (~`:99-107`), `lib/services/notification_service.dart` (`_requestPermission`, `onTokenRefresh` handler, `_currentUserId` init), `lib/pages/authentication/login/google_login_screen.dart` + `apple_login_screen.dart` (register before the profile/terms gate, not after).

- [ ] **Step 1 (the fix that moves the number): register on session restore.** In the splash session-restore success path (after `initializeAuth()` returns true, ~`splash_screen.dart:82`), call `await notificationService.registerToken(userId)`. Keep it non-blocking for navigation (fire-and-forget with error swallow is fine — backend upserts per deviceId, so repeat calls are idempotent).
- [ ] **Step 2: token-refresh independence.** Set `_currentUserId` during `initialize()` from the stored session (not only inside `registerToken`), so `onTokenRefresh` re-registers even if rotation happens before an explicit registerToken call.
- [ ] **Step 3: provisional permission (iOS).** In `_requestPermission`, request with `provisional: true` so denied/undecided users still receive a token and quiet notifications; keep the full prompt where it is today.
- [ ] **Step 4: social-login gate order.** In Google/Apple screens, move `registerToken` to fire right after auth succeeds (before profile-completion/terms gates) so incomplete-profile users are still reachable. (Step 1 also covers them on next launch regardless.)
- [ ] **Step 5: retry-by-relaunch.** Confirm nothing marks registration "done forever" on failure — with Step 1, every launch retries naturally. Add a debug log on failure instead of the silent catch (`notification_service.dart:535-537`).
- [ ] **Step 6:** `flutter analyze` clean. (No commit — gate rule.)

### Task 12: Deep-link router coverage for every push type

**Files:** Modify `lib/services/notification_router.dart` (`:55-119`).

Audit fixes #3/#4: `room_mention` has **no router case** → tapping a room-mention push lands on `/home` instead of the room; `voice_room_start`/`scheduled_room_reminder` pushes carry `data.route` but the router switches on `type` only → also `/home`.

- [ ] **Step 1:** Add `case 'room_mention'` → navigate to the room/conversation (id from `data`).
- [ ] **Step 2:** Add a generic fallback: if `data.route` is present and no explicit case matched, navigate to `data.route` (covers voice-room types + future types).
- [ ] **Step 3:** Add cases for `new_follower` (→ `/profile/$userId`), `srs_review`/`streak_reminder` (→ AI Study/vocab review).
- [ ] **Step 4:** While here, **verify** the scheduled-room senders' legacy `user.fcmToken` (singular) usage flagged by the reviewer (`notificationService.js:896-945` `select('fcmToken ...')`) — if they query the dead singular field, their pushes never deliver; switch to the `fcmTokens` array path (small backend touch, note it in the report).
- [ ] **Step 5:** `flutter analyze` clean. (No commit.)

### Task 13: In-app notification history renders the new types properly

**Files:** Modify `lib/pages/notifications/notification_history_screen.dart` (`_getNotificationIcon`/`_getNotificationColor` `:49-89`, tap handling `:564-615`).

Audit fix #5: once Task 5 lands, wave/comment_reply/comment_reaction/comment_mention/room_mention/new_follower/srs_review/streak_reminder records appear in history for the first time — today they'd all render as a generic gray bell.

- [ ] **Step 1:** Add icon + color cases per type (wave 👋 amber, comment_reply 💬, comment_reaction, comment_mention @, room_mention #, new_follower 👤, srs_review 📚, streak_reminder 🔥 — follow the existing style).
- [ ] **Step 2:** Ensure taps route through the same deep-link logic as Task 12 (reuse, don't duplicate).
- [ ] **Step 3:** `flutter analyze` clean. (No commit.)

**== APP PHASE DONE (T7, T12–T13) ==**

---

## GATE

### Task 14: Gate + single commit + measure

- [ ] **Step 1:** Verify branch tips unmoved (app `fb7b60d`, backend `243eafa` — NO commits were allowed). Backend full suite (Node v24) — no new failures. App `flutter analyze` — 0 errors.
- [ ] **Step 2:** Whole-branch review of the uncommitted diffs (both repos), focus: no notification-type regressions; badge only bumps on persisted rows; unsubscribe endpoint can't flip flags without a valid token; token registration can't loop/spam; suppression records keep original type.
- [ ] **Step 3: Device smoke:** fresh launch (session restore) registers a token (check user doc); wave → recipient gets push AND an in-app history row (first time ever); comment reply/mention → history row + tap opens the moment; room mention tap opens the room; profile visit notification honors the pref; unsubscribe link flips the flag; forced streak/SRS run delivers with correct gating.
- [ ] **Step 4: ON USER GO-AHEAD ONLY:** single commit per repo + push branch + merge → main (pull first, per standing instruction).
- [ ] **Step 5: Measure:** token coverage weekly (`fcmTokens.0 exists / total`, baseline **109/656 = 17%**); notification-type counts (wave/comment_reply/room_mention should go from 0 → nonzero within days).

## Deferred upgrade backlog (audit-ranked, M-effort — next wave candidates)
- **"Your partner is online" push** (online-state infra exists; needs trigger + pref).
- **Weekly progress/streak digest push** (job + weekly `digest` cap exist).
- **DM message-reaction notifications** (mirror `sendCommentReaction`, offline-gated).
- **Mutual-wave celebration surface** beyond the existing dialog (template already renders match copy).
