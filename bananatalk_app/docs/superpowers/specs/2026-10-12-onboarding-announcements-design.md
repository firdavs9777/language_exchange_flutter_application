# Onboarding activation, launch pop-ups, admin announcements, localization, calls Phase 2

Date: 2026-10-12 · Repos: `bananatalk_app` (Flutter), `language_exchange_backend_application` (Node), `language_exchange_web_front` (React admin) · Status: draft for review

## 1. Why

- 85% of signups leave on day one. The first-session guides (one card per tab, Matches panel) shipped on 2026-10-10, but a guide retires when its button is tapped — even if the user backs straight out — so nothing measures or rewards a real first action.
- The app's distinctive features (long-press → translate / correct) are invisible: nothing tells a new user they exist.
- Up to four pop-ups can open at launch, uncoordinated, and stack. A new user can meet three before seeing a feature.
- The in-app announcement is set through server env vars (`ANNOUNCEMENT_*`); changing it needs a config edit + restart; there is no admin UI, no scheduling, no multiple announcements, and announcements never reach the notifications list. `POST /admin/broadcast` exists but no admin page uses it.
- 74 hardcoded English strings in 56 files never reach an `.arb`, some on screens the guides lead to; the suspension notice compares a localized string against the English server message.
- Calls Phase 2 is designed (`2026-10-08-calls-reliability-design.md` §6) and approved, not built.
- The droplet shows ~7,600 PM2 restarts for `language-app` — the new announcement job runs there.

## 2. Decisions

| Topic | Decision |
|---|---|
| Activation | Four core actions recorded when they **really** happen: message sent, moment posted, lesson completed, profile complete (photo + bio). |
| Guide lifetime | A tab's guide retires on its own real action. All guides stop at **3 of 4 actions or 7 days after signup**, whichever comes first (replaces the 3-day window). Each card shows "Getting started · N of 4". No checklist screen. |
| Chat tip (P2) | Inline hint under the first received text message: "Long-press to translate or correct". Once ever; retires on first long-press or ✕; only during the guide period. |
| Launch pop-ups (P4) | At most **one pop-up per launch**, by priority: update → announcement → ads notice → feature spotlight. AI Study promo folds into the spotlight rotation. New users in the guide period see only update + ads notice. |
| Notification priming (P5) | Existing priming sheet; counts as the launch's one pop-up; triggered after the first message is sent or received and after the first match batch (the "every chat open" trigger is removed). Measured. |
| Announcements | DB-backed `Announcement` records, **several live at once**, managed from a new `/admin` page; per-language text; targeting by platform + app language + start/end; in-app pop-up and/or notification (push + permanent notifications-list entry) on publish or at the scheduled start; idempotent delivery with stats. Env-var announcement stays as fallback. |
| Localization | All 74 remaining hardcoded strings move to `.arb` in all 19 locales (machine drafts, native review stays open); suspension reason sent by the server as its own field. |
| Calls Phase 2 | Built as specified in the calls spec §6 (summarised in §8 below). |
| Ops | Investigate the PM2 restart count before shipping the announcement job; investigate the two bare `flutter: null` log lines. |
| Out of scope | Tours, carousels, profile progress bars; guides for the existing install base; a second deeper guide per tab; rich-text / A/B announcements. |

## 3. Activation and guides (app)

### 3.1 `ActivationStore` (`lib/services/activation_store.dart`)
- Enum `ActivationAction { message, moment, lesson, profile }`; per action a bool pref `activation_done_<slug>` (slugs append-only). `markDone(action)` is idempotent, returns whether it was newly set, and on a new set logs `activation_milestone {action, count}` where count is the number done after it. `doneCount()`, `isDone(action)`. Reads fail closed (treat as done) like `GuideStore`.
- User-scoped: registered in `session_reset.dart` and cleared on logout / account switch.
- Hooks (each calls `markDone` once, fire-and-forget):
  - message: inside `reportFirstMessageIfFirst()` (already called from every send path).
  - moment: after `createMoments(...)` succeeds in `create_moment.dart` `_createMoment()` and `_createMomentWithBackgroundUpload()` (create mode only, not edit).
  - lesson: in `LessonPlayerNotifier._completeLesson()` after `submitLesson` succeeds; also the quiz and vocabulary players' completion points.
  - profile: whenever the profile is loaded or saved and `effectiveImageUrls.isNotEmpty && bio.trim().isNotEmpty` (the existing completeness rule from `profile_main.dart`), via one helper `checkProfileComplete(user)` called from `profile_main.dart` and after each edit screen's save.
- Existing installs: on first read, back-fill `message` from `first_conversation_done` and `profile` from the current user, so nobody who already acted sees a stale guide.

### 3.2 Guide rule
- `kGuideWindowDays` 3 → 7. `shouldShowGuide({withinWindow, acted, milestonesDone})` → `withinWindow && !acted && milestonesDone < 3`. `isGuidePeriod(user, store)` = `joinedWithinDays(7) && doneCount() < 3` — the single predicate reused by the chat tip and the launch coordinator.
- Each surface's `acted` = its real action: aiStudy ← lesson, moments ← moment, chats ← message, profile ← profile, matches ← message (existing). `PageGuide._onCta` no longer marks acted (it still logs `guide_cta_tapped`).
- `guide_retired {surface, reason: acted | milestones | window}` logged once per surface the first time a guide that was shown is suppressed (latch pref per surface).
- `GuideCard` gains an optional footer "Getting started · {count} of 4" (`guideProgress` l10n, ICU plural-safe).

### 3.3 Chat tip
- New `GuideSurface.chatTip` (slug `chat_tip`).
- `MessageBubble`: when `!isMe`, the message has text, it is the first such message the user has seen while the tip is eligible (`isGuidePeriod && !acted(chatTip)`), render a small inline hint row under the bubble (icon + "Long-press to translate or correct" + ✕). Only one bubble per app run shows it (a run latch provider).
- Retire: first `_showContextMenu` on any message, or ✕ → `markActed(chatTip)`; ✕ logs `guide_cta_tapped {surface: chat_tip, target: dismiss}`, long-press logs `target: primary`. Shown logs `guide_shown {surface: chat_tip}`.

## 4. Launch pop-ups and priming (app)

### 4.1 `LaunchModalCoordinator` (`lib/services/launch_modal_coordinator.dart`)
- Runs once per process, post-first-frame, from the main shell (`TabBarMenu.initState`), replacing the separate `AiStudyPromoModal.showIfDue`, `AdsNoticeModal.showIfNeeded` and `_maybeShowFeatureSpotlight` calls. The version-check coordinator reports whether it showed an update dialog; the announcement call moves out of `version_check_coordinator.dart` into the coordinator.
- Candidates in order, each a `LaunchCandidate { Future<bool> isDue(); Future<void> show(context); bool allowedForNewUsers }`: update (owned by version check; if it showed, stop) → announcement → ads notice → feature spotlight. The first due candidate is shown; the rest wait for a later launch. Existing per-modal throttles are kept inside each `isDue`.
- During `isGuidePeriod`, only candidates with `allowedForNewUsers` (update, ads notice) run.
  *Amended 2026-10-13 (audit M4):* the ads notice is no longer allowed for new users — it spent the launch budget that §4.2 priming needs in the first session; it shows once after the guide period.
- AI Study promo becomes `PromoType.aiStudy` in `promo_service.dart`'s rotation, skipped when `ActivationStore.isDone(lesson)`. `AiStudyPromoModal` is deleted.
- A shared `PopupBudget` (per process) is consumed by whichever pop-up shows first — launch candidate or notification priming — so two never stack.

### 4.2 Notification priming
- `maybePrimeNotifications` callers: keep Matches (after the first match batch) and waves; remove the chat-open trigger; add "after first message sent or received" (from `reportFirstMessageIfFirst` and the first received message in an open conversation).
- Respects `PopupBudget`.
- Events: `notification_prime_shown {trigger}`, `notification_prime_result {result: granted | declined | later}`.

## 5. Announcements

### 5.1 Backend
- Model `Announcement`:
  `{ status: draft|scheduled|live|ended, priority: int (default 0), translations: { <locale>: { title ≤100, body ≤1000, buttonLabel ≤40 } }, defaultLocale, emoji, imageUrl, buttonUrl (http(s) or app deep link), platforms: ['all'|'ios'|'android'], languages: [] (empty = all app languages), startsAt, endsAt, showInApp: bool, notify: bool, createdBy, publishedBy, publishedAt, endedAt, delivery: { state: none|queued|running|done|failed, targeted, pushed, listed, failed, startedAt, finishedAt } }`, timestamps. Index `{status, startsAt, endsAt}`.
- Live = `status in (scheduled, live) && startsAt ≤ now && (endsAt null || endsAt > now)`. A minute job flips scheduled → live at `startsAt` and live → ended at `endsAt`.
- `GET /api/v1/app-config` (existing): adds `announcements: [...]` — every live, `showInApp` announcement matching the caller's platform and app language (query/header the app already sends; fall back to `defaultLocale` text), sorted priority desc, startsAt desc; each `{ id, title, body, emoji, imageUrl, buttonLabel, buttonUrl, priority }`. The existing single `announcement` field stays: the top DB announcement if any, else the env-var one — so live builds keep working.
- Admin routes (`/api/v1/admin/announcements`, `protect` + admin role, audit-logged): `GET` list (filter by status), `GET /:id`, `POST` create (draft), `PUT /:id` (draft/scheduled only; live: text/endsAt/priority only), `POST /:id/publish` (now or at `startsAt` → scheduled), `POST /:id/end`, `DELETE /:id` (draft only), `GET /:id/audience-count` (users matching targeting with an active token), image upload via the existing Spaces upload service.
- Delivery job (`services/announcementDelivery.js`): triggered when an announcement with `notify` becomes live (publish-now or the minute job). Claims delivery atomically (`delivery.state: none → running` conditional update) so a restart or double publish never sends twice; resumes `running` deliveries older than 10 min. Iterates targeted users in batches of 500 by `_id` cursor (persisting the last `_id` for resume): creates one `Notification` `{ type: 'announcement', data: { announcementId } }` per user (unique index `{user, type, data.announcementId}` partial on type announcement) and sends push via `fcmService` in the user's app language, respecting `notificationSettings` (a new `announcements` toggle, default on; quiet hours honoured for push only). Updates `delivery` counters. Existing `/admin/broadcast` is left as is.
- `GET /api/v1/announcements/:id` (authenticated user): the announcement in the user's language, for the detail screen.
- Suspension contract fix: ban responses and the suspended socket error carry `banReason` as its own field (already on the user); the app stops parsing `"Reason:"` from the message.

### 5.2 App
- `appConfig.announcements` parsed into a list; the coordinator's announcement candidate picks the highest-priority one whose id is not in the seen set (`announcements_seen_ids` pref, user-scoped); showing it adds the id. Falls back to the single `announcement` field when the list is absent (old backend).
- `AnnouncementModal` reused; its button opens `buttonUrl` (http → external browser, app link → router).
- Notifications list: `NotificationItem` type `announcement` gets its own icon; tapping (and tapping the push) opens a new `AnnouncementScreen` (fetches `GET /announcements/:id`, renders image, text, button). The push payload carries `type: announcement, announcementId`; `notification_router` routes it.
- Notification settings screen: "Announcements" toggle bound to the new backend setting.

### 5.3 Web admin (`language_exchange_web_front`)
- New nav item and route `/admin/announcements` (list) and `/admin/announcements/:id` (editor), following `AdminContent`/`AdminUsers` patterns and the existing admin RTK slice.
- List: title, status chip, targeting summary, start/end, delivery stats (targeted / pushed / listed / failed); filters by status.
- Editor: per-language tabs (title, body, button label) with the default language required; emoji; image upload; button URL; platform + language multi-select; start/end pickers; priority; switches "Show in app" / "Send notification"; live preview of the in-app pop-up; actions Save draft · Schedule · Publish now · End now. Publish with notify opens a confirm dialog showing the audience count. Validation mirrors the backend limits.

## 6. Localization (app + backend)
- All 74 remaining hardcoded strings (`docs/onboarding-audit-2026-10-10.md` §2a list, re-grepped at plan time) move to `app_en.arb` and all 18 other locales (machine drafts, recorded in `docs/l10n/native-qa-strings-2026-10.csv` for native review). Priority order: screens a guide or announcement leads to, then the rest.
- All new strings in this spec (guide progress, chat tip, priming triggers, announcement screen, settings toggle, Calls Phase 2) in all 19 locales; `test/l10n/arb_integrity_test.dart` and a new `onboarding_strings_test.dart` cover them.
- Announcement push text uses the announcement's own translations; backend notification templates get any new fixed strings in all 19 locales.

## 7. Ops investigations (before shipping the announcement job)
- **PM2 restarts:** read `pm2 describe language-app` / `pm2 logs --err` history on the droplet (owner runs the commands or grants access), classify causes (crash vs deploy restarts — each deploy is one restart), and fix any crash found as its own task. Exit criterion: the restart cause is known and recorded in `docs/REMAINING_WORK.md`; crashes fixed or ticketed.
- **`flutter: null` lines:** find the bare `print(null)` / `debugPrint` source by grep and a debug run; fix.

## 8. Calls Phase 2 (from calls spec §6)
- Decline with message — in-app `IncomingCallScreen` only: 2 canned replies + custom (≤200); `POST /calls/:id/decline { message }` → after the call message, a normal text message from the receiver.
- Missed-call push actions Call back / Message — iOS `UNNotificationCategory` registered natively; Android local-notification actions (push is data-only); Call back from a killed app launches the app then calls via `CallLauncher`.
- Calls on/off + quiet hours — reuse `User.quietHours`, add `notificationSettings.allowCalls` (default true); `allowCalls:false` or inside quiet hours → `409 CALLEE_UNAVAILABLE`, `busy/unavailable` record, no message, no push. Settings under Settings → Notifications.
- Camera on during a voice call — publishes video; `POST /calls/:id/upgrade` sets `type: 'video'`; `call:state` carries the new type; history and bubble say "Video call".
- Draggable self-view snapping to corners; tap to swap big/small.

## 9. Testing
- App: unit — `ActivationStore` (idempotent, events, back-fill, logout reset), guide rule (3-of-4, 7-day, per-surface acted), coordinator (order, one per launch, new-user filter, PopupBudget shared with priming, AI Study in rotation, skipped after a lesson), announcement selection (priority, seen set, fallback). Widget — chat tip (once, retires on long-press / ✕, guide period only), guide progress footer, announcement screen from a notification tap, settings toggle. l10n guards for every new key.
- Backend (node:test + harness): live selection by platform/language/dates/priority; app-config list + legacy single field + env fallback; admin auth + audit; publish/schedule/end transitions; minute job; delivery idempotency across restart and double publish, batching, resume, settings respected, one Notification per user; `/announcements/:id` language fallback; suspension `banReason` field; Calls Phase 2 endpoints (decline message, upgrade, CALLEE_UNAVAILABLE + quiet hours).
- Web: page tests for list, editor validation, confirm dialog with audience count, error states (existing admin test style).
- Device QA: `docs/qa/onboarding-matrix.md` — new account's first week (guides, chat tip, milestones, pop-up order, priming), announcement publish → push → notifications list → in-app pop-up, scheduled announcement, multiple live announcements across launches, ended announcement; Calls Phase 2 rows added to `docs/qa/calls-matrix.md`.

## 10. Rollout
1. Ops investigations (§7) — restart cause known before the job ships.
2. Backend (announcements, app-config list, suspension field, Calls Phase 2 endpoints) — safe for live builds (legacy fields kept, new fields additive).
3. Web admin — announcements usable immediately; notifications reach every build; pop-up list and detail screen need the new app.
4. App release with §3, §4, §5.2, §6, §8.
5. Measure one week after the app release: share of new users reaching 3 of 4 in week one (`activation_milestone`), `guide_retired` reasons, `notification_prime_result` grant rate, announcement delivery stats.
