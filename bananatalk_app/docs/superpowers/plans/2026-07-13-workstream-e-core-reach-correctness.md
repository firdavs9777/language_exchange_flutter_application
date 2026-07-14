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
- **Branch:** `workstream-e-core` in both repos off `main`. Per-task commits.
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

### Task 2: Vocab/SRS reminders gated on the right setting

**Files:** Modify `services/notificationService.js` (~`:552` `shouldNotify` 'system' case), `jobs/learningJobs.js` (SRS sender), `models/Notification.js` (type enum); Test `test/shouldNotify.gates.test.js`.

Problem: SRS review reminders send as type `'system'`, and `shouldNotify` gates `'system'` on `notificationSettings.marketing` — so turning off marketing silently kills vocab reminders the user explicitly enabled.

- [ ] **Step 1: Write failing tests** for `shouldNotify`:
  - type `'srs_review'` with `vocabularyReviewReminders: true, marketing: false` → **allowed**.
  - type `'srs_review'` with `vocabularyReviewReminders: false` → blocked.
  - type `'system'` behavior unchanged (marketing-gated).
  - type `'streak_reminder'` gated on `notificationSettings.streakReminders` (used by Task 3).
- [ ] **Step 2: Implement:** add `srs_review` and `streak_reminder` cases to `shouldNotify` gated on `vocabularyReviewReminders` / `streakReminders`; add both to the `Notification` model type enum; switch the SRS sender in `jobs/learningJobs.js` to send type `'srs_review'` instead of `'system'`.
- [ ] **Step 3: Run green (full suite). Commit** `fix(notifications): SRS reminders gated on vocabularyReviewReminders, not marketing`.

### Task 3: Wire streak reminders (dead code → scheduled)

**Files:** Modify `jobs/learningJobs.js` (`startLearningJobs`); Test extend `test/shouldNotify.gates.test.js` or a small scheduling test.

- [ ] **Step 1:** In `startLearningJobs` (~`:387`), schedule `sendStreakReminders` daily at **20:00 KST** using the same `getMillisecondsUntil`-style pattern the other daily jobs use (the function body already filters on `notificationSettings.streakReminders` + `fcmTokens.0`). Route its send through type `'streak_reminder'` (Task 2).
- [ ] **Step 2:** `node --check`, full suite green. **Commit** `feat(notifications): schedule daily streak reminders (was dead code)`.

### Task 4: Wave daily summary at 9 AM KST (was 9 AM UTC = 6 PM KST)

**Files:** Modify `jobs/waveDailySummaryJob.js` (`SUMMARY_HOUR_UTC`).

- [ ] **Step 1:** Change `SUMMARY_HOUR_UTC = 9` → `0` (00:00 UTC == 09:00 KST) and update the comment to say "9 AM KST" explicitly, matching the other daily jobs' KST convention.
- [ ] **Step 2:** `node --check`, suite green. **Commit** `fix(notifications): wave daily summary fires 9AM KST, consistent with other daily jobs`.

### Task 5: Notification type-enum sync

**Files:** Modify `models/Notification.js` (type enum); Test `test/notificationTypeEnum.test.js`.

- [ ] **Step 1:** Grep every `type:` string actually sent through `services/notificationService.js` + `jobs/*.js` (known senders include `wave`, `comment_reply`, `comment_reaction`, `comment_mention`, `scheduled_room_started`, `scheduled_room_reminder`, `vip_renewal_warning`, `subscription_grace_period`, `subscription_expired`, plus Task 2/3's `srs_review`, `streak_reminder`). Build the definitive list.
- [ ] **Step 2: Write a failing test** that requires both the model and a hardcoded list of sent types and asserts every sent type ∈ enum.
- [ ] **Step 3:** Add the missing values to the enum (additive only — do not remove existing values; existing docs stay valid). Run green. **Commit** `fix(notifications): Notification.type enum covers all sent types`.

### Task 6: Email unsubscribe compliance (List-Unsubscribe + endpoint + link)

**Files:** Create `controllers/emailUnsubscribe.js`, `routes/emailUnsubscribe.js` (public, token-verified); Modify `utils/sendEmail.js`, `utils/emailTemplates.js` (`baseTemplate` footer), `jobs/promotionalEmailJob.js`, `jobs/weeklyDigestJob.js`; Test `test/emailUnsubscribe.test.js`.

Reuse the existing per-user booleans (`privacySettings.emailNotifications`, `privacySettings.weeklyDigest` — already in the User schema) — no new schema.

- [ ] **Step 1: Signed token helper** (in the controller module): `makeUnsubscribeToken(userId, emailType)` = HMAC-SHA256 over `userId:emailType` with `JWT_SECRET` (no expiry — unsubscribe links must work from old emails); `verifyUnsubscribeToken` validates and returns `{userId, emailType}`. TDD: valid round-trip; tampered token rejected.
- [ ] **Step 2: Endpoint** `GET /api/v1/email/unsubscribe?token=...` (public — no auth; the token IS the auth): on valid token set the matching boolean (`promotional` → `privacySettings.emailNotifications=false`; `digest` → `privacySettings.weeklyDigest=false`) and return a tiny confirmation HTML page ("You're unsubscribed"). Invalid token → 400. TDD the decision logic.
- [ ] **Step 3: Headers:** in `utils/sendEmail.js`, accept an optional `unsubscribeUrl` option; when present add Mailgun headers `h:List-Unsubscribe: <url>` and `h:List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058).
- [ ] **Step 4: Footer link:** `baseTemplate` accepts optional `unsubscribeUrl` and renders "Unsubscribe" in the footer when present. Transactional emails (verification/reset/security) pass nothing — no header, no link (correct: transactional mail must not carry unsubscribe).
- [ ] **Step 5: Wire senders:** `promotionalEmailJob` + `weeklyDigestJob` generate the per-user token/URL and pass it through; both jobs must also **check the boolean before sending** (verify the promo job's existing `privacySettings` check; add the digest check if missing).
- [ ] **Step 6:** Full suite green. **Commit** `feat(email): RFC-8058 List-Unsubscribe + signed unsubscribe endpoint for promo/digest`.

**== BACKEND PHASE DONE (T1–T6) ==**

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
- [ ] **Step 6:** `flutter analyze` clean. **Commit** `fix(push): register FCM token on session restore + provisional auth + refresh independence`.

**== APP PHASE DONE (T7) ==**

---

## GATE

### Task 8: Gate + measure

- [ ] **Step 1:** Backend full suite (Node v24) — no new failures. App `flutter analyze` — 0 errors.
- [ ] **Step 2:** Whole-branch review (both repos), focus: no notification type regressions; unsubscribe endpoint can't flip flags without a valid token; token registration can't loop/spam the API.
- [ ] **Step 3: Device smoke:** fresh launch registers a token (check the user doc); unsubscribe link from a promo email flips the flag and stops the next send; streak/SRS reminder observable via a forced run.
- [ ] **Step 4:** Merge `workstream-e-core` → main (both repos, pull first) on user go-ahead.
- [ ] **Step 5: Measure (the point of E2a):** re-run the token-coverage query weekly — `users with fcmTokens.0 exists / total`. Baseline **109/656 (17%)**. Expect a steady climb as actives relaunch.
