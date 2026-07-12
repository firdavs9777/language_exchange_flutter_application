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
- `Message` model already has `participants[]`, `isGroupMessage`, `readBy[]`, `mentions[]`, and media types including `image`/`sticker`/`voice`.
- Flutter chat UI: `ChatMessagesList` (`lib/pages/chat/message/messages_list.dart`) + `ChatInputBar` (`lib/pages/chat/input/chat_input_bar.dart`) support group participants, image, sticker, GIF, reply.
- `ChatSocketService` (`lib/services/chat_socket_service.dart`): JWT auth, reconnection, multi-device, event streams.
- Community directory patterns (search/filter/list/cards) in `lib/pages/community/`.
- `Report.type` enum already includes `"message"` + moderation helpers.
- Feature-flag pattern: `config/limitations.js` (`AI_QUOTA_ENABLED`). Seed pattern: `migrations/seedPrompts.js` (idempotent upsert + `--dry-run`).
- Community tab bar (`lib/pages/community/main/community_tab_bar.dart`) currently has 7 sub-tabs (All, Gender, Nearby, City, Topics, Voice Rooms, Waves).

**Build (new):**
- Conversation hub metadata fields (below).
- `normalizeLanguage()` helper + canonical language keying.
- Room REST routes/controllers (directory, detail, history, join/leave, admin).
- Socket.io room events + presence (the only genuinely new backend subsystem).
- `seedRooms.js` + daily-prompt system-message job.
- Flutter Rooms tab, room directory, room screen (assembled from reused chat components), socket room subscription methods.

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

**Room message path (correction to parent spec).** The existing group-message machinery fans out `unreadCount[]` and `readBy[]` to every participant on every message — correct for a 4-person group, wrong for a 240-member hub (write amplification, unbounded arrays). Room messages therefore use a **broadcast path**:
- Store `Message` by `conversationId` with `isGroupMessage: true`; **do not** maintain per-member `unreadCount[]`/`readBy[]` arrays for hubs.
- Live delivery via socket to members currently joined to the room; history via REST pagination.
- Unread indicator = a lazy per-user `lastReadAt` (per room) compared against `lastActivityAt` — a single timestamp, not a maintained counter.

### 2. Canonical language normalization (load-bearing)

Prod stores `English`, `en`, `English (US)`, `Chinese (Simplified)` interchangeably. A `normalizeLanguage(value) -> canonicalKey` helper — backed by the existing `languages` collection (aliases → canonical code) — is used everywhere a language is matched: seeding hub `targetLanguage`, auto-join matching against `user.language_to_learn`, and directory grouping/sort. Without normalization, auto-join silently fails to place users (68 `en`-coded and many display-name users would miss their hub).

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
- **Presence / online count** — derived from sockets currently in `room_'+id`; broadcast member-count/online deltas on join/leave. Honest "N online now."
- Existing token-bucket rate limiter applies to `room:message`.

### 5. Seeding + daily prompt (liveness engine)

- `migrations/seedRooms.js` (follows `seedPrompts.js`: idempotent upsert keyed by `targetLanguage`, `--dry-run`). Seeds ~6-8 hubs weighted to measured demand: **English Practice** (anchor), **Korean**, **Japanese**, **Chinese**, **Arabic**, **Spanish**, **German**, **French**. Each with title, description, `emojiFlag`, canonical `targetLanguage`, system `owner`, `isSeeded: true`.
- **Daily prompt job:** posts the localized prompt-of-day as a `system` message into each hub (reuses Workstream C `prompts` collection + daily rotation, selecting the prompt for the hub's `targetLanguage`). Rendered as a pinned/highlighted prompt card in the room. Guarantees fresh daily content in every hub regardless of human activity.

### 6. Flutter

- **Rooms tab** added to `community_tab_bar.dart` as an 8th sub-tab (adjacent to Voice Rooms). Hidden when `ROOMS_ENABLED` is off (client reads flag via existing config surface).
- **Room directory** — reuses community list/card/search patterns; each card shows hub name, `emojiFlag`, member count, and "N online now" activity dot; your auto-joined hub surfaces first.
- **Room screen** — assembled from reused `ChatMessagesList` + `ChatInputBar` (text/image/sticker) + new socket room subscription methods on `ChatSocketService` (`joinRoom`, `leaveRoom`, `sendRoomMessage`, room-message/typing/presence streams). Daily-prompt card pinned at top. History via REST pagination; live via socket.
- Honest liveness UI throughout: real member count, online count, daily prompt.

### 7. Moderation, notifications, kill switch

- **Moderation (required for public rooms):** per-message report (`Report.type:'message'`), owner/admin remove + mute (reuse `mutedBy`), server-side message rate limit (existing token bucket).
- **Notifications:** **mention-only** push via existing mentions machinery — never per-message (a 240-member hub cannot push every message).
- **Kill switch:** `ROOMS_ENABLED` in `config/limitations.js` (matches Step 13A `AI_QUOTA_ENABLED` pattern). Backend routes/sockets short-circuit when off; Flutter hides the Rooms tab and falls back to current behavior.

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
