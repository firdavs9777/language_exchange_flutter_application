# Workstream D: Public Language Rooms — Design

**Date:** 2026-07-12
**Status:** Approved by user (2026-07-12)
**Parent spec:** `docs/superpowers/specs/2026-07-11-social-wave-design.md` (Workstream D section)
**Repos:** `bananatalk_app` (Flutter) + `language_exchange_backend_application` (Node/Express + MongoDB)
**Branch:** `workstream-d-rooms`

## Thesis

The build is mostly assembly — a 2026-07-12 codebase scout found ~80% of the required infrastructure already exists (Conversation/Message group fields, reusable chat UI, JWT socket client, community directory patterns, feature-flag + seed-migration patterns). The hard part is **not** engineering; it is the **empty-room problem**. Design v1 entirely around liveness.

## Why this departs from the parent spec (measured 2026-07-12 against prod Mongo, `test` db, 657 users)

The parent spec proposed user-creatable, `languagePair`-scoped rooms. Prod data contradicts both choices:

| Signal | Number | Implication |
|---|---|---|
| **Voice rooms ever created** (the existing analog, 3.5 months) | 51 | Users will create rooms |
| **Max participants in ANY voice room, ever** | **2** | User-created rooms die alone |
| Avg peak participants / room | 1.08 | ~92% were solo — creator sat alone and left |
| Voice rooms that ever got a 2nd person | **4 of 51 (8%)** | Cold-start is the killer, not tooling |
| Group `Conversation`s ever created | **0** | Group-chat code exists but is unused — no legacy to honor |
| Weekly-active users | ~178 | Too small to fragment across pair-rooms |
| Learners of English | 240 | Demand concentrates hard by **target language** |
| Learners of Korean / Japanese | 58 / 39 | Clear secondary hubs |
| Language field values | `English`, `en`, `English (US)`, `Chinese (Simplified)`, 96 empty, 68 `en/en` | Language data is **dirty** — matching must normalize |

**Three decisions locked with the user:**

1. **Target-language hubs, seeded-only.** ~6-8 official "Learn English / Korean / Japanese…" rooms, always visible. **No user-created rooms in v1** (revisit once hubs are proven alive). This concentrates ~178 weekly-actives where they can actually meet, instead of shattering them across `languagePair` shards.
2. **Auto-join the matching hub.** On first Rooms open, the user is already a member of the hub matching `normalize(language_to_learn)`. Member counts are real on day one; presence and pushes work immediately. Users may join other hubs manually and leave any hub.
3. **Daily prompt pre-warming.** A system message posts the localized prompt-of-day into each hub daily (reuses the Workstream C `prompts` collection). Every hub has fresh content daily even when no human is talking.

## Codebase reality (scout, 2026-07-12) — reuse vs. build

**Reuse (do not rebuild):**
- `Conversation` model already has `isGroup`, `groupName`, `groupAvatar`, `participants`, per-user `unreadCount`, `mutedBy` (+ mute/unmute methods).
- `Message` model already has `participants[]`, `isGroupMessage`, `readBy[]`, `mentions[]`, `messageType` values `sticker`/`system`, and media `type` values `image`/`voice`/…. (Note: `sticker`/`system` are `messageType`, not media `type` — reviewer I5.)
- `ChatInputBar` (`lib/pages/chat/input/chat_input_bar.dart`): image, sticker, GIF, reply — reuse verified. `ChatSocketService` (`lib/services/chat_socket_service.dart`): JWT auth, reconnection, multi-device, extensible event streams — reuse verified.
- Community directory patterns (search/filter/list/cards) in `lib/pages/community/`.
- `Report.type` enum already includes `"message"` + moderation helpers.
- Server-side feature-flag pattern: `config/limitations.js` (`AI_QUOTA_ENABLED`). Seed pattern: `migrations/seedPrompts.js` (idempotent upsert + `--dry-run`). Scheduler host: `jobs/scheduler.js`. `prompts` collection + day-of-year rotation.
- Community tab bar (`lib/pages/community/main/community_tab_bar.dart`) currently has 7 sub-tabs (All, Gender, Nearby, City, Topics, Voice Rooms, Waves).

**Build (new) — corrected after spec review:**
- Conversation hub metadata fields (below) + `User.leftHubs` (sticky-leave, reviewer M2).
- `normalizeLanguage()` helper **+ a new alias table** — the `languages` collection has no alias field, so this is net-new, not reuse (reviewer C1).
- `roomType:'hub'` exclusion filter on `getConversations` so hubs don't leak into DMs (reviewer C2).
- Room REST routes/controllers (directory, detail, history, join/leave, admin).
- Socket.io room events + presence with `disconnect`-safe online count (the only genuinely new backend subsystem; reviewer I4).
- `seedRooms.js` (hubs + reserved **system owner user**, reviewer I2) + daily-prompt job in `jobs/scheduler.js` (reviewer I3).
- `roomsEnabled` added to the app-config endpoint for client flag delivery (reviewer I1).
- Flutter Rooms tab, room directory, room screen; **`ChatMessagesList` extended with per-message sender attribution** for many-member hubs (reviewer M1); socket room subscription methods.

## Components

### 1. Data model — extend `Conversation`, reuse `Message`

New fields on `Conversation` (all additive; defaults keep existing DMs/groups untouched):
- `roomType: 'hub'` (discriminator; absent/`null` = normal conversation)
- `isPublic: Boolean`
- `targetLanguage: String` — **canonical** key (e.g. `en`, `ko`, `ja`). Hubs are keyed by target language, **not** a `languagePair`.
- `title`, `description`, `emojiFlag` (display)
- `owner` (system/admin user id), `admins: [userId]`
- `memberCount: Number` (denormalized; hubs can be large — English is already 240)
- `maxMembers: Number` — hubs use a high/soft cap (e.g. 1000); the parent spec's 100 cap was for user-rooms, which v1 does not ship
- `lastActivityAt: Date`
- `isSeeded: Boolean`
- `leftHubs` — **on `User`**, not Conversation: `leftHubs: [conversationId]` records hubs a user explicitly left, so auto-join (below) never re-adds them. Without this, removing the user from `participants` on leave is indistinguishable from "never joined" and re-auto-joins them on next `GET /rooms`. (Reviewer M2.)

**Room message path (correction to parent spec).** The existing group-message machinery fans out `unreadCount[]` and `readBy[]` to every participant on every message — correct for a 4-person group, wrong for a 240-member hub (write amplification, unbounded arrays). Room messages therefore use a **broadcast path**:
- Store `Message` by `conversationId` with `isGroupMessage: true`; **do not** maintain per-member `unreadCount[]`/`readBy[]` arrays for hubs.
- Live delivery via socket to members currently joined to the room; history via REST pagination.
- Unread indicator = a lazy per-user `lastReadAt` (per room) compared against `lastActivityAt` — a single timestamp, not a maintained counter.
- **Hubs must NOT leak into the DM/conversation list (reviewer C2).** `getConversations` (`controllers/conversations.js:21`) currently queries `{ participants: userId }` with no room filter, so an auto-joined hub would appear mixed into DMs (with a meaningless `otherParticipant`). Add `roomType: { $ne: 'hub' }` to that query **and** filter hubs out of the Flutter conversation list. Hubs surface only in the Rooms tab.

### 2. Canonical language normalization (load-bearing — NET-NEW, not reuse)

Prod stores `English`, `en`, `English (US)`, `Chinese (Simplified)` interchangeably. A `normalizeLanguage(value) -> canonicalKey` helper maps every dirty variant to one canonical code, used everywhere a language is matched: seeding hub `targetLanguage`, auto-join matching against `user.language_to_learn`, and directory grouping/sort. Without normalization, auto-join silently fails to place users (68 `en`-coded and many display-name users would miss their hub).

**Correction (reviewer C1):** the existing `languages` collection (`models/Language.js`) has only `code`/`name`/`nativeName`/`flag` — **no alias field**, so it cannot resolve dirty variants. The alias table is therefore **new work**: either extend `Language` with `aliases: [String]` (seeded alongside rooms) or ship a hardcoded alias map inside `normalizeLanguage()`. This is the single most load-bearing new piece and must be treated as Build, not Reuse. Its seeding is part of the `seedRooms.js` migration scope. The `Prompt.language` field (ISO-639-1) and hub `targetLanguage` **must share this same canonical keyspace**, or daily-prompt selection silently returns nothing (see §5).

### 3. Backend REST + auto-join

- `GET /rooms` — hub directory; sorted with the user's `normalize(language_to_learn)` hub first, then by `memberCount`/`lastActivityAt`; includes live online count.
- `GET /rooms/:id` — room detail + member summary.
- `GET /rooms/:id/messages` — paginated history (reuse existing message pagination).
- `POST /rooms/:id/join`, `POST /rooms/:id/leave` — membership; update `memberCount`.
- **Auto-join:** on first Rooms open (or first `GET /rooms`), idempotently add the user to the hub matching their normalized target language. Idempotent = safe to call repeatedly; no duplicate membership.
- Admin actions: `DELETE /rooms/:id/members/:userId` (remove), mute member (reuse `mutedBy` + mute methods), `PUT /rooms/:id` (edit hub info). Owner/admin only.

All routes gated by `ROOMS_ENABLED`.

### 4. Sockets (new subsystem)

Socket.io room-scoped events on top of the existing JWT-authenticated socket:
- `room:join` / `room:leave` — `socket.join('room_'+id)` / `leave`; client joins only while the room screen is open.
- `room:message` — broadcast to the socket room; persisted via the broadcast path above.
- `room:typing` — ephemeral, room-scoped.
- **Presence / online count (reviewer I4)** — computed from **live socket-room membership at query time** (the io adapter's room size), NOT a maintained counter. The `disconnect` handler must remove the socket from all its rooms and rebroadcast the delta, so an ungracefully-dropped/backgrounded app (no explicit `room:leave`) does not inflate "N online" forever.
- **Rate limiting (reviewer M3):** reuses the existing per-user token bucket (`socketHandler.js`, capacity 10, 1/s refill). Note it is a single per-user bucket shared across all messaging — heavy hub posting also throttles that user's DMs. Acceptable at ~178 WAU; documented, not a room-scoped limiter in v1.

### 5. Seeding + daily prompt (liveness engine)

- **System owner account (reviewer I2 — hard dependency).** No system/owner user exists today (`User.role` is only `user`/`admin`; voice rooms use a real-user host). `seedRooms.js` must **first upsert a reserved system user** (fixed `_id`/email, `role: 'admin'`) to own the hubs, then seed hubs referencing it. Alternative: `owner: null` + an `admins: []` list of real admin accounts. The spec picks the reserved-system-user approach so daily-prompt system messages have a stable sender.
- `migrations/seedRooms.js` (follows `seedPrompts.js`: idempotent upsert keyed by canonical `targetLanguage`, `--dry-run`). Seeds ~6-8 hubs weighted to measured demand: **English Practice** (anchor), **Korean**, **Japanese**, **Chinese**, **Arabic**, **Spanish**, **German**, **French**. Each with title, description, `emojiFlag`, canonical `targetLanguage`, `owner` = system user, `isSeeded: true`. Also seeds the language alias table (reviewer C1) if that approach is chosen.
- **Daily prompt job (reviewer I3):** hosted in the existing **`jobs/scheduler.js`** (setInterval-based, alongside `scheduleDailyCounterReset` etc.) — the spec names this host rather than leaving scheduling to guesswork. It posts the localized prompt-of-day as a `messageType: 'system'` message (from the system user) into each hub, reusing the Workstream C `prompts` collection + the existing day-of-year rotation (`controllers/moments.js:196`). **Prompt selection joins on canonical language:** `Prompt.language` (ISO-639-1) and hub `targetLanguage` must be the same canonical key (§2), or selection silently returns nothing. Rendered as a pinned/highlighted prompt card. Guarantees fresh daily content in every hub regardless of human activity.

### 6. Flutter

- **Rooms tab** added to `community_tab_bar.dart` as an 8th sub-tab (adjacent to Voice Rooms). Hidden when `ROOMS_ENABLED` is off — see the flag-delivery note in §7 (reviewer I1); the app-config endpoint must be extended to emit `roomsEnabled`, since the existing `AI_QUOTA_ENABLED` flag is server-only and never reaches the client.
- **Room directory** — reuses community list/card/search patterns; each card shows hub name, `emojiFlag`, member count, and "N online now" activity dot; your auto-joined hub surfaces first.
- **Room screen** — assembled from `ChatInputBar` (reuse verified) + new socket room subscription methods on `ChatSocketService` (`joinRoom`, `leaveRoom`, `sendRoomMessage`, room-message/typing/presence streams — the socket service is explicitly extensible). **`ChatMessagesList` needs a small extension (reviewer M1):** it is currently built 1-on-1 (`otherUserName`/`otherUserPicture`, no per-message sender), so hub rendering must add **sender attribution** (name + avatar per message). Reuse is viable but this is a small build, not pure reuse. Daily-prompt card pinned at top. History via REST pagination; live via socket.
- **Media clarification (reviewer I5):** in `Message`, `sticker` and `system` are `messageType` values (not media `type` values — media `type` is `image`/`video`/`audio`/`voice`/…). The daily-prompt uses `messageType: 'system'` (exists); room stickers use `messageType: 'sticker'` (exists). Model these as messageTypes, not media types.
- Honest liveness UI throughout: real member count, online count, daily prompt.

### 7. Moderation, notifications, kill switch

- **Moderation (required for public rooms):** per-message report (`Report.type:'message'`), owner/admin remove + mute (reuse `mutedBy`), server-side message rate limit (existing token bucket).
- **Notifications:** **mention-only** push via existing mentions machinery — never per-message (a 240-member hub cannot push every message).
- **Kill switch:** `ROOMS_ENABLED` in `config/limitations.js` (server-side gate on routes/sockets — matches the Step 13A `AI_QUOTA_ENABLED` pattern). **Client delivery (reviewer I1):** `AI_QUOTA_ENABLED` is consumed only server-side and never sent to clients, so it is NOT a precedent for a client flag. The app-config endpoint (`controllers/appConfig.js`, parsed by `lib/models/app_config.dart`) must be **extended to emit `roomsEnabled`**; Flutter reads it there to show/hide the Rooms tab. (Fallback option: key the tab off whether `GET /rooms` returns hubs — 404/empty = hidden.)

### 8. MVP boundary

In: text/image/sticker messages; seeded hubs only; auto-join; presence/online count; daily prompt; mention pushes; report + admin remove/mute.
Out (v1): user-created rooms, `languagePair` rooms, threads, polls, voice, per-message pushes, ML ranking.

## Error handling & edge cases

- **Dirty/empty language** (`""`, `en/en`): `normalizeLanguage` returns null → user is not auto-joined to any hub but can browse/join manually (these are the Workstream A incomplete-profile cohort; not a room concern to fix).
- **Auto-join idempotency:** repeated `GET /rooms` must not duplicate membership or inflate `memberCount`.
- **Leave then re-open:** leaving a hub is respected; re-open does not silently re-auto-join a hub the user explicitly left (track an `autoJoined`/`leftHubs` marker so leave is sticky).
- **Kill switch off mid-session:** Flutter tolerates a missing Rooms tab and route 404s gracefully.
- **Rate limit hit:** room message send surfaces the existing rate-limit path, not a crash.
- **Socket drop:** rejoin `room_'+id` on reconnect if the room screen is still open (reuse existing reconnection).

## Testing

- **Backend TDD** on: `normalizeLanguage` (alias table + dirty inputs), auto-join idempotency + sticky-leave, room membership/permissions (admin-only actions), broadcast message path (no `unreadCount[]` fan-out), rate limiting.
- `flutter analyze` clean per commit; `package:` imports only (linter-enforced).
- Manual device smoke = the D gate below.

## D gate (manual, before merge)

Two devices chat live in a seeded hub; a new user is auto-joined to their target-language hub on first open; online count updates on join/leave; a mention fires a push on the other device; an admin removes a member; daily prompt appears in each hub. `flutter analyze` clean.

**Metric to watch post-ship:** % of new users sending ≥1 room message in week 1 (target >20%). Re-run the 2026-07-12 queries after ship.

## Cross-cutting (inherited)

- Kill switch `ROOMS_ENABLED`; design tokens (teal #00BFA5, banana #FFD54F, dark-mode parity); `package:` imports; TDD on backend logic; per-workstream manual smoke gate.
- Server steps still pending from prior workstreams (track, don't block): `seedPrompts.js` run, `REFRESH_TOKEN_SECRET` set. `seedRooms.js` joins that list.

---

# Workstream E: Monetization + Engagement Plumbing (VIP · Marketing Push · Lifecycle Email)

**Added 2026-07-12** at user request — investigate VIP functionality, in-app/push notifications for marketing/promotion, and email sending/scheduling; propose upgrades/fixes. Grounded in a three-way codebase scout + prod measurement (`test` db, 656 users, ~178 WAU). This is a separate concern from Language Rooms and will likely become its own implementation plan; captured here because it was scoped in the same session.

## Measured reality (2026-07-12, prod)

| Signal | Number | Implication |
|---|---|---|
| **Active VIP subscriptions** | **0** | Full IAP + paywall built, has never converted a single user |
| VIP transactions ever recorded | **0** | Purchase funnel produces nothing — likely blocked, not just unpopular |
| Users reachable by push (have an FCM token) | **109 / 656 (17%)** | 83% unreachable — any push-marketing plan is dead until token capture is fixed |
| `notificationSettings.marketing == true` | **656 / 656 (100%)** | Everyone is opted-in; **in-app** broadcast reaches all even while push is broken |
| Users who received an inactivity email | **416 / 656 (63%)** | Lifecycle email is genuinely LIVE and firing broadly |
| Notifications by type | system 381 (vocab-review reminders, ~10% read), friend_request 94, moment_like 66 | Low read rates; "system" is spaced-repetition, not marketing |

**The through-line:** all three subsystems are heavily *built* but barely *converting/reaching*. The work is fixing wiring and closing the last mile, not green-field construction.

## E1. VIP / Monetization — built, $0 earned

**What exists (verified):** `vipSubscription` model (plan, billing dates, grace period, warnings, transactions), `vipFeatures` flags, iOS StoreKit 2 + Android Play Billing receipt verification (`controllers/iosPurchase.js`, `androidPurchase.js`), `POST /purchases/{ios,android}/verify` + webhooks, hourly `subscriptionExpiryJob` with grace period + auto-downgrade, 4 Flutter paywall screens (plans/payment/status/visitor-upgrade), admin manual-grant route. A daily-quota engine (`visitorLimitations`/`regularUserLimitations`) covers messages, translations, tutor chat, roleplay, story-gen, pronunciation.

**Why 0 conversions — the fix list:**

- **[FIX-E1a · S · HIGH] Price / product-ID mismatch (likely the reason purchases fail).** Flutter shows **$14.99 / $19.99 / $49.99** (`vip_subscription.dart`) while backend config enforces **$9.99 / $23.99 / $71.99** (`iosPurchase.js`), and product IDs are frontend-hardcoded vs backend env-configurable. A product-ID mismatch means the store call can fail outright. **Verify against the actual App Store / Play Console product IDs and reconcile all three (store, app, backend) to one source of truth.** This is the first thing to check — it may be a hard purchase blocker, not cosmetic.
- **[FIX-E1b · S · HIGH] VIP value prop is switched off.** `config/limitations.js` gives all tiers (visitor/regular/vip) identical 5/day tutor quotas — comment: *"VIP gating disabled product-wide."* So VIP's headline benefit (unlimited AI tutor) does nothing; only translation is actually VIP-gated. Restore `vip.tutorDailyQuotas = -1` (unlimited) and confirm the UI handles unlimited. Without a real benefit, the paywall has nothing to sell. **Coordinate with the [[project_step13a_shipped]] quota work + `AI_QUOTA_ENABLED` kill switch.**
- **[FIX-E1c · M · MED] IAP not idempotent.** `activateVIP` doesn't dedupe on `transactionId` before saving — a client retry double-activates. Guard on existing `transactions[].transactionId`.
- **[UPGRADE-E1d · S · MED] Dead VIP features.** 8 features declared in config (`adFree`, `prioritySupport`, `readReceipts`, `undoMessage`…) are enforced nowhere. Either mark "coming soon," remove, or implement — today they're aspirational and dilute the pitch.
- **Out of scope here:** the Coins + Boost system (2026-06-21 spec) is 0% built; that's a separate large workstream, not a fix.

**Decision needed from user:** is the goal to *revive subscriptions* (fix E1a+E1b so the existing paywall converts) or to *rethink VIP* entirely (per the [[project_ai_study_open_gaps]] "VIP rethink" gap)? The fixes above assume the former (cheap, high-leverage); a rethink is a brainstorming track of its own.

## E2. Notifications — rich engine, can't reach anyone, no campaign tool

**What exists (verified):** mature FCM service (`services/fcmService.js`) with per-user multi-device tokens, frequency caps (`config/notificationCaps.js`), quiet hours (timezone-aware), bundling; in-app notification center (`notifications` collection + Flutter history screen); an **admin broadcast endpoint** (`POST /notifications/broadcast`, admin-only) with 3 audience segments (vip/active/inactive) that always respects the marketing opt-in.

**Fix list:**

- **[FIX-E2a · M · HIGH] Push reachability (17%).** Only 109/656 users have an FCM token. Audit the Flutter token-registration path (`POST /notifications/register-token`) — permission prompt timing, token-refresh on launch, silent failures. This gates *every* push strategy; nothing else in E2 matters until reach improves.
- **[FIX-E2b · S · HIGH] Re-engagement job is dead code.** `sendReengagementNotifications()` is implemented but never scheduled in `jobs/scheduler.js`. Wire it in (respects existing 6-day dedup + prefs). Immediate win-back value for the large dormant cohort.
- **[UPGRADE-E2c · M · HIGH] Marketing is developer-only.** Broadcasts today require CLI/Postman. Add an **admin campaign UI** (compose → pick segment → preview → send) over the existing endpoint, and log campaigns to `AdminAuditLog`. Leverage that **in-app broadcast reaches 100%** even while push is at 17%.
- **[UPGRADE-E2d · L · MED] Segmentation is 3 coarse cohorts.** Extend beyond vip/active/inactive to language ("learners of Spanish"), engagement ("never posted"), lifecycle ("onboarded, never chatted"). FCM topic functions (`sendToTopic`) exist but are unused — a possible substrate.
- **[FIX-E2e · S · MED] Type-enum mismatch.** `wave`, `comment_reply/reaction/mention` are sent but absent from `Notification.type` enum → breaks type audits. Sync the enum.
- **[FIX-E2f · M · LOW] Bundling is in-memory** (lost on restart) — persist if it proves lossy at scale.

## E3. Email — live and branded, but non-compliant and buggy

**What exists (verified):** Mailgun transport (`utils/sendEmail.js`), 18 branded responsive HTML templates, full transactional set (verification, reset, welcome, login alert), and a real lifecycle suite scheduled via `jobs/scheduler.js` (setTimeout-based, KST): inactivity 3-tier, weekly digest, weekly promotional, admin reports. **20 scheduled jobs total.**

**Fix list:**

- **[FIX-E3a · S · HIGH] Broken subscription-expiry notifications.** `jobs/subscriptionExpiryJob.js:178,200` call an **undefined `sendPushNotification()`** → VIP grace-period/expiry notices silently fail. Replace with `notificationService.sendVipRenewalWarning()`. (Directly undercuts E1 monetization — expiring users aren't told to renew.)
- **[FIX-E3b · S · HIGH] No unsubscribe = compliance + deliverability risk.** Missing RFC 8058 `List-Unsubscribe` header and no in-body unsubscribe link on promo/digest email → CAN-SPAM/GDPR exposure and Gmail/Outlook bulk-filtering. Add the header in `sendEmail.js` + an unsubscribe route + per-type opt-out field on `User`.
- **[UPGRADE-E3c · M · MED] 4 engagement emails dead-wired.** `sendNewFollowerEmail`, `sendNewMessageEmail`, `sendCorrectionEmail`, `sendVipSubscriptionEmail` have templates but no trigger. Wire to their events (message email → inactive users only, to avoid spam). Retention lever.
- **[UPGRADE-E3d · M · MED] No bounce/complaint handling.** Add a Mailgun webhook; on hard bounce mark email invalid + stop sending; on complaint disable promo. Prevents wasted sends + blacklisting.
- **[UPGRADE-E3e · L · LOW] Scheduler fragility.** 20 jobs on chained `setTimeout` — no persistence, drifts on server-time change, silent missed runs. Migrate to `node-cron`. Also remove unused SendGrid config. Infra hardening, not urgent.

## E4. Recommended sequencing (pending user priority call)

A tight, high-leverage first cut — mostly S-effort fixes that unblock revenue and reach:

1. **Revenue unblock:** E1a (price/product-ID) → E1b (VIP quota value) → E3a (renewal emails). Cheap, and nothing sells until done.
2. **Reach + win-back:** E2a (token capture) + E2b (turn on re-engagement) + E3b (unsubscribe compliance).
3. **Marketing capability:** E2c (admin campaign UI) leaning on 100% in-app reach; E3c (engagement emails).
4. **Later / larger:** E2d segmentation, E3d bounce handling, E3e cron migration, VIP rethink or Coins/Boost (separate specs).

## E gate (per shipped fix)

- E1a/E1b: a test account completes a real IAP on device and receives VIP; VIP account gets unlimited tutor while free account is capped.
- E2a: FCM-token coverage rises materially after the registration fix (re-measure the 17%).
- E2b/E2c: a scheduled re-engagement push and an admin-composed broadcast both deliver (push to token-holders, in-app to all).
- E3a/E3b: expiry email fires; every marketing/digest email carries a working unsubscribe.
- **Metrics to re-measure post-ship:** active VIP subscriptions (from 0), FCM-token coverage (from 17%), dormant-user return rate.

## Open questions for the user (E)

1. **VIP direction:** fix the existing paywall to convert (assumed), or rethink VIP first?
2. **Scope of E now:** ship the "revenue unblock + reach" first cut (E1a/b, E2a/b, E3a/b) as its own workstream, or fold specific items into Rooms (e.g., ship E2c campaign UI alongside Rooms since both touch admin + notifications)?
3. **Coins/Boost:** in or out for this cycle? (Currently 0% built; large.)
