# Social Wave: Auth → Intros → Moments 2.0 → Language Rooms

**Date:** 2026-07-11
**Status:** Approved by user
**Repos:** `bananatalk_app` (Flutter) + `language_exchange_backend_application` (Node/Express + MongoDB)

## Why (measured 2026-07-11 against prod Mongo)

| Signal | Number | Implication |
|---|---|---|
| Users | 638 total; **515 joined in last 30 days**; 178 active last 7d | 81% of userbase is brand new — activation is the game |
| Chat pairs | 6,021; **85.6% one-sided** (no reply ever); 90.5% die ≤3 messages; 1.7% reach 20+ | Reply rate is the core leak |
| Waves | 1,091 sent; **12 ever read (1.1%)**; 2 mutual | Wave inbox (7th tab in Community) is invisible |
| Moments | **23 posts in 2.5 months**, 23 unique posters; 21/23 got likes | Creation dead, consumption appetite exists |
| Chat power features | reactions 0.8%, translations 2.2%, corrections 0.1% of 17.8k messages | Backend over-built, UX under-surfaced |

Direction chosen by user: **feature parity with HelloTalk/Tandem — but upgraded, not cloned, with better UI.** Sequenced workstreams, each shipping to main independently:

**A. Auth (smooth + cool UI) → B. Wave→Intro overhaul → C. Moments 2.0 → D. Public Language Rooms**

Backend is already feature-rich (mature Moment/Comment/Message/Conversation/Wave models, 40+ socket events, FCM with caps/quiet-hours/bundling). Most work is Flutter UX + thin backend additions. The only genuinely new backend subsystem is room-scoped sockets (D).

---

## Workstream A: Auth — smooth, cool UI, audited fixes

### A1. Fixes (from 2026-07-11 two-repo audit)

| # | Sev | Issue | Fix |
|---|---|---|---|
| 1 | Critical | OAuth users who abandon profile wizard are never re-prompted (`profileCompleted` auto-set with fields missing; no re-entry) | Backend: require all 4 core fields (gender, birth_year, native_language, language_to_learn) before marking `profileCompleted: true` (controllers/auth.js OAuth paths). Flutter: on every login, if `profileCompleted == false` route into completion wizard. Wizard progress persisted locally (SharedPreferences), resumes at abandoned step. |
| 2 | Critical | Apple token revoked only on account deletion, not logout | Backend logout endpoint calls Apple revocation API for Apple-linked accounts (reuse revocation code from deletion path, auth.js ~1685). Non-blocking with logged failure. |
| 3 | High | Refresh secret = `JWT_SECRET + '_refresh'` (User.js ~1115) | Independent `REFRESH_TOKEN_SECRET` env var. Dual-verify: try new secret, fall back to legacy derived secret during grace period — no forced logouts. |
| 4 | High | Client refresh queue hangs forever if backend stalls (api_client.dart `_refreshAccessToken`) | 30s timeout on refresh; on timeout fail all queued completers cleanly → normal auth-error path. |
| 5 | Medium | "Invalid or expired verification code" ambiguity; Flutter string-parses error messages | Backend returns structured error codes (`CODE_EXPIRED`, `CODE_INVALID`, `ACCOUNT_LOCKED`, `RATE_LIMITED`...). Flutter maps codes → precise UI actions (resend vs re-enter vs countdown). |
| 6 | Medium | Email registration wizard restarts from step 1 if app closes mid-flow | Persist step + entered data locally; resume prompt on relaunch. |

Out of scope (noted for later): GDPR 30-day soft-delete grace period; per-user post-auth rate limiting.

### A2. UI redesign

Existing shared widget system (`lib/pages/authentication/widgets/`: auth_screen_scaffold, auth_gradient_button, auth_text_field, auth_step_progress, animated_banana_title, social_login_button, username_availability_field, password_field, biometric_login_button) gets upgraded in place — one visual language across all ~12 auth screens, dark-mode parity throughout.

- **Welcome/login:** animated teal→banana gradient backdrop; refreshed animated_banana_title; Apple/Google buttons per platform guidelines; biometric login integrated into the layout.
- **Register wizard:** labeled step progress bar; one-question-per-screen rhythm; smooth page transitions; language pickers with flags + search; photo step with instant crop preview.
- **Live feedback:** inline validation as-you-type (email format, password strength meter, username availability), button loading states, success micro-animations between steps, friendly illustrated error states (lockout / rate limit / network) instead of raw snackbars.
- **Code entry:** 6-digit OTP boxes with auto-advance + paste support + visible resend countdown (email verification and password reset screens).

### A gate
E2E smoke on real device: email, Google, Apple signup; abandon-and-resume path; wrong-password/lockout/rate-limit error states. `flutter analyze` clean.

---

## Workstream B: Wave → Intro Requests

Waves become **intro requests** surfaced where users actually look.

- **Intro strip:** horizontal strip at top of chat list (`chat_list_screen.dart`): avatar, name, message preview, pending badge. Chats tab badge count includes pending intros. Strip view marks waves read (existing `PUT /community/waves/read`).
- **Push notification:** new `wave` notification type — add to backend type enum + template + caps config; sent via existing FCM service (quiet hours/caps respected).
- **Accept → conversation:** new backend endpoint `POST /community/waves/:id/accept` — creates/gets Conversation, delivers the wave's message as first chat Message from sender, marks wave read, returns conversation. App navigates straight into the conversation with reply keyboard open. Decline dismisses silently (sender never notified).
- **Mutual wave:** existing `checkMutualWave` + `mutual_wave_dialog` wired end-to-end: celebration dialog → auto-open conversation.
- **Composer:** wave sheet gains language-exchange icebreaker prompts (localized static list) instead of a blank field.
- Old waves tab → archive screen (exists: `waves_archive_screen.dart`); Community keeps a lightweight entry point.

### B gate
Wave sent on device A appears as push + intro strip item on device B; accept lands both in a live conversation. Metric to watch post-ship: wave read rate, wave→conversation conversion.

---

## Workstream C: Moments 2.0 — language-learning feed + UI refresh

Reframe from generic Instagram feed to the exchange loop. Backend Moment model already supports language, category, privacy, reactions, saves, reports, trending index.

- **For You feed (default):** ranking = posts in user's target language by native speakers + posts by learners of user's native language, blended with recency/engagement. Backend: `feed=forYou` mode on existing GET /moments using existing `{language, createdAt}` + trending indexes; no new collection. Tabs: **For You / Following / Trending** (trending endpoint exists).
- **Daily prompts (cold-start fix):** new backend `prompts` collection, seeded + localized ("Describe your weekend in Korean 🇰🇷"); `GET /moments/prompt-of-day` (per target language, rotates daily). Feed shows prompt card at top; tapping opens composer pre-filled with prompt chip; prompt id stored on the moment for grouping.
- **Corrections on posts:** correction = special comment: Comment model gains `correctionOf` fields (`originalText`, `correctedText`, `explanation`). Composer: select post sentence → edit → post. Rendered with strikethrough/diff highlighting. Notification reuses `moment_comment` type.
- **Audio moments:** ≤60s voice posts. Moment `mediaType: 'audio'` + audio upload endpoint (reuse chat voice upload pipeline/S3). Flutter reuses chat voice recorder + waveform player.
- **UI refresh:** redesigned moment card (cleaner hierarchy, language badge, correction count chip); comment pagination in UI (backend already paginates; app currently loads whole thread); moment **edit** UI (endpoint exists, UI missing); designed empty states pointing to the daily prompt.

Out of scope: video re-enable, stories changes, ML ranking.

### C gate
For You feed returns language-matched posts for a test user; prompt→post→correction→notification loop works on device. Metric: moments/week.

---

## Workstream D: Public Language Rooms

Discoverable topic/language group chats. Biggest build; only genuinely new backend subsystem.

- **Data model:** extend `Conversation` (isGroup, groupName, groupAvatar, participants, per-user unreadCount/mutedBy already exist). Add: `isPublic`, `languagePair` (e.g. `["en","ko"]`), `topic`, `description`, `owner`, `admins[]`, `memberCount`, `maxMembers` (default 100), `lastActivityAt`. Messages reuse existing pipeline (`participants[]`, `isGroupMessage`, `readBy`).
- **REST:** room directory (list/filter by language pair, search, sort by activity), room detail + member list, create room, join/leave, admin actions (remove member, mute member, edit room info).
- **Sockets (new):** room-scoped events — `room:join`, `room:leave`, `room:message`, `room:typing`, member-count presence — using socket.io rooms; client joins socket room only while room screen is open; history via REST pagination. Existing JWT socket auth + token-bucket rate limiting apply.
- **Discovery:** Community tab gains a **Rooms** tab: directory sorted by user's language pair first, member count + activity dot, search. **Seeded official rooms** per major language pair so no room is ever empty on day one.
- **Moderation (required for public rooms):** owner/admin remove + mute; per-message report (Report model already supports type `message`); server-side message rate limits.
- **Notifications:** mention-only pushes (existing mentions machinery); never per-message.
- **MVP boundary:** text/image/sticker messages; 100 members; no threads, polls, or voice in rooms v1.

### D gate
Two devices chat live in a seeded room; join/leave updates member count; mention triggers push; admin can remove a member. Metric: % of new users sending ≥1 room message in first week.

---

## Cross-cutting

- **Kill switches** (backend env, Step 13A pattern): `WAVE_INTRO_V2_ENABLED`, `MOMENTS_FEED_V2_ENABLED`, `ROOMS_ENABLED`. Flutter falls back to current behavior when off.
- **Design system:** existing tokens (teal #00BFA5 primary, banana #FFD54F accents, system typography, dark-mode variants) — refreshed compositions, no new palette.
- **Imports:** `package:` imports only (linter-enforced).
- **Testing:** TDD on backend logic (accept-intro, feed ranking, room membership/permissions); `flutter analyze` clean per commit; manual device smoke gate per workstream before the next begins.
- **Sequencing:** A → B → C → D, each landing on main as a working release. Nothing in a later workstream blocks an earlier one.

## Success metrics (re-run the 2026-07-11 queries after each ship)

| Metric | Baseline | Target |
|---|---|---|
| Wave read rate | 1.1% | >50% |
| One-sided chat pairs | 85.6% | <70% |
| Moments per week | ~2 | 25+ |
| New users sending a room message in week 1 | n/a | >20% |
