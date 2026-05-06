# Community Restructure & Wave 1 Features — Design

**Date:** 2026-05-06
**Branch:** `refactor/community-wave-1` (off `main`)
**Scope:** `lib/pages/community/` + supporting providers/services + backend additions
**Shape:** B-roadmap — wave 1 detailed and implemented; wave 2 sketched, not implemented

## Goal

Restructure `lib/pages/community/` (~12,366 lines, 13 files) into focused subfolders with shared widgets and a dark-mode/withOpacity sweep, **and** ship five feature improvements (A. filter UX rebuild, B. waves send-side, C. voice rooms overhaul, D. mutual-interests on profile, E. online-now presence) in a single coherent wave. Mesh→SFU migration and other deferred improvements are sketched as wave 2 in this same document but not implemented.

## Non-goals (explicit)

- **No SFU migration.** Mesh WebRTC stays for wave 1. The 8-participant cap remains; UI cap is lowered to 5 to reduce mesh fragility (see Risk register).
- **No new tabs in `CommunityMain`** beyond wiring `WavesTab` (already-built). Total tabs go from 6 → 7.
- **No matching algorithm changes.** Smart match-score deferred to wave 2.
- **No moments/stories changes.** Out of scope; recent specs already covered them.
- **No backend-only work without a Flutter consumer.** Every schema/endpoint change must be exercised by the Flutter wave-1 work.
- **No localization additions for wave-2 features.** Only wave-1 strings get translated.

## Current state diagnostics

**Current files & sizes** — `lib/pages/community/` is mostly flat (12 top-level files, 10,868 lines) plus an existing `voice_rooms/` subfolder (3 files, 1,498 lines). Total **12,366 lines**. The table below mixes both for total visibility:

| File | Lines | Smell |
|---|---|---|
| `single_community.dart` | 2,532 | Profile-detail screen, embedded tabs + sections |
| `community_filter.dart` | 1,769 | Bottom sheet w/ embedded filter chips, sliders, dialogs |
| `partner_discovery_tab.dart` | 1,274 | Tab + embedded card variants |
| `nearby_tab.dart` | 1,188 | Tab + embedded location/distance widgets |
| `city_tab.dart` | 1,054 | Tab + embedded city picker |
| `genders_tab.dart` | 931 | Tab + embedded gender filter |
| `community_main.dart` | 670 | Wraps 6-tab `TabController`, search, filter button |
| `community_card.dart` | 648 | The card used in 4 tabs |
| `voice_rooms_tab.dart` | 578 | Hardcoded language list + colors, inline snackbars |
| `voice_room_screen.dart` | 556 | In-room screen, missing chat UI / hand-raise UI / host controls |
| `topics_tab.dart` | 482 | OK |
| `create_room_sheet.dart` | 364 | OK |
| `waves_tab.dart` | 320 | **Orphan** — file exists, not wired into `CommunityMain` |

**Cross-cutting smells:**

- ~30+ inline `ScaffoldMessenger.showSnackBar(...)` calls; `voice_rooms_tab.dart:100,114` are typical
- `_FilterChip` defined locally in `voice_rooms_tab.dart:514` (used 4× in same file at 196/205/223/232). `community_main.dart:666` has an unrelated `_FilterChipData` helper. Other tab/filter files use Material's built-in `FilterChip` — **not duplicated** as initially thought. C3 covers extracting the one local class to `widgets/community_filter_chip.dart` and replacing the 4 in-file uses, plus making the new shared widget reusable for future filter UIs (no app-wide hunt needed)
- Hardcoded `Colors.grey[100/300/400/600/700]` and `Colors.white` in card / filter chip / voice room participant tile
- `withOpacity()` (deprecated) sprinkled across several files; community already uses `withValues(alpha:)` in newer code (see `voice_rooms_tab.dart`) — inconsistent
- 13-language list duplicated in `voice_rooms_tab.dart:31-45` instead of consuming the existing `languages` API endpoint that the registration flow uses

**Voice room runtime gaps:**

- C-i. In-room chat: backend wired (`onVoiceRoomChat`, `sendChat`), zero UI surface
- C-ii. Hand-raise: socket event listened to but per-participant flag not stored on `RoomParticipant` (see `voice_room_manager.dart:181-187` `// could add handRaised to model` TODO)
- C-iii. Speaking indicator: `RoomParticipant.isSpeaking` exists but no audio-level wiring
- C-iv. Host controls: `kickParticipant`, `endRoom` exist on manager, no UI to invoke
- C-v. Stale rooms: no heartbeat; if creator force-quits, room stays "live" forever
- C-vi. Reconnect: socket drop = dead session, no rejoin
- C-vii. Host transfer: no logic when host leaves first

**Backend surface today (inferred from `endpoints.dart` + provider code; MongoDB MCP not connected during design):**

- `voicerooms` (GET/POST) — list, create, join, mute, etc. (mostly socket events `voiceroom:*`)
- `community/waves` (GET) — paginated received waves (`{page, limit, unreadOnly}`); `getWavesReceived()` wired in `community_provider.dart:308-335`
- `community/waves/read` (PUT) — mark waves read (optional `{waveIds}` body for selective marking); `markWavesAsRead()` wired in `community_provider.dart:338-347`
- **`community/wave`** (POST, **singular**) — send wave: body `{targetUserId, message?}`, returns `WaveResponse {waveId, isMutual, message}`. Frontend wired in `community_provider.dart:283-306` with rate-limit handling via `response.isRateLimited`. Backend implementation status not yet verified — confirm during C15
- `community/topics/:topicId/users` — topic-filtered users
- `auth/users/...` — user CRUD, visitors, VIP
- **No presence broadcast events** on `chat_socket_service` — only voice-room signaling
- **`WavesTab` is orphaned** — fully implemented widget at `lib/pages/community/waves_tab.dart` but not wired into `CommunityMain`'s `TabController`; spec adds this in C13
- **Mutual-wave UI absent** — `WaveResponse.isMutual` flag returned by `sendWave` but no Flutter consumer surfaces "it's a match"; spec adds this in C14

## Target folder layout

```
lib/pages/community/
├── widgets/                              NEW — shared building blocks
│   ├── community_snackbar.dart           showCommunitySnackBar()
│   ├── community_dialog_scaffold.dart    rounded card for dialogs/sheets
│   ├── community_empty_state.dart        unified empty state
│   ├── community_filter_chip.dart        extracted from voice_rooms_tab.dart
│   └── community_error_state.dart        unified error block
│
├── main/                                 NEW — was community_main.dart (670)
│   ├── community_main.dart               ~300
│   ├── community_app_bar.dart            search + filter
│   ├── community_tab_bar.dart            7-tab strip (adds Waves)
│   └── community_search_bar.dart
│
├── tabs/                                 NEW — flat list of 7 tabs
│   ├── partner_discovery_tab.dart        ~600 (was 1,274)
│   ├── nearby_tab.dart                   ~600 (was 1,188)
│   ├── city_tab.dart                     ~500 (was 1,054)
│   ├── genders_tab.dart                  ~500 (was 931)
│   ├── topics_tab.dart                   MOVED
│   └── waves_tab.dart                    MOVED + wired into TabController
│   (voice rooms is also a tab but lives in voice_rooms/ — see below)
│
├── card/                                 NEW — was community_card.dart (648)
│   ├── community_card.dart               ~300
│   ├── community_card_avatar.dart        avatar + presence dot (E) + VIP frame
│   ├── community_card_meta.dart          name, age, languages, level badges
│   └── community_card_actions.dart       wave button (B), message button
│
├── single/                               NEW — was single_community.dart (2,532)
│   ├── single_community_screen.dart      ~600
│   ├── single_community_header.dart      avatar, name, location, follow CTA
│   ├── single_community_languages.dart   wraps LanguageMatchCard
│   ├── single_community_engagement.dart  wraps EngagementStatsBar
│   ├── single_community_starters.dart    wraps ConversationStartersCard
│   ├── single_community_topics.dart      NEW — mutual interests (D)
│   ├── single_community_actions.dart     wave, message, more (block/report)
│   └── single_community_tabs.dart        About/Moments/Photos
│
├── filter/                               NEW — was community_filter.dart (1,769)
│   ├── community_filter_sheet.dart       ~400 — top-level sheet shell
│   ├── filter_age_section.dart           age range slider
│   ├── filter_gender_section.dart
│   ├── filter_languages_section.dart     native + learning lang pickers
│   ├── filter_country_section.dart       country picker
│   ├── filter_topics_section.dart        topic chips
│   ├── filter_level_section.dart         language level
│   ├── filter_toggles_section.dart       online-only (E), new-users, prioritize-nearby
│   └── filter_state.dart                 typed FilterState (was inline Map<String,dynamic>)
│
└── voice_rooms/                          EXPANDED in place
    ├── voice_rooms_tab.dart              ~300 (was 578)
    ├── voice_room_screen.dart            ~300 (was 556)
    ├── voice_room_header.dart            app bar + live-duration badge
    ├── voice_room_info_bar.dart          language + participant count
    ├── voice_room_participants_grid.dart grid layout
    ├── voice_room_participant_tile.dart  avatar + speaking ring + mute + hand-raise (C-ii, C-iii)
    ├── voice_room_controls.dart          mute / raise / leave bar
    ├── voice_room_host_menu.dart         NEW — kick/end/transfer entry points (C-iv)
    ├── voice_room_chat_panel.dart        NEW — in-room chat UI (C-i)
    ├── voice_room_reconnect_banner.dart  NEW — surfaces socket reconnect (C-vi)
    └── create_room_sheet.dart            MOVED
```

**Total folders inside `community/`:** 7 (`widgets/`, `main/`, `tabs/`, `card/`, `single/`, `filter/`, `voice_rooms/`). Total files end at ~50 (was 13). Each new file targets ≤400 lines. Note the naming collision: the `TabController` exposes 7 *tabs* but those tabs are spread across 2 *folders* (`tabs/` for 6 of them, `voice_rooms/` for the voice-rooms tab) — the 7-tab and 7-folder counts are coincidental, not the same list.

### What stays put (deliberately not moved)

- `lib/widgets/community/` — cross-module shared widgets (`partner_card`, `language_match_card`, `engagement_stats_bar`, `conversation_starters_card`, etc.) used by both community pages and other parts of the app. New shared community widgets created in this refactor go to `lib/pages/community/widgets/` (page-scoped) — following the chat convention of page-scoped vs. cross-module split.
- `lib/widgets/voice_room/` — same logic.
- `lib/models/community/` — models stay (`voice_room_model`, `topic_model`).
- `lib/providers/voice_room_provider.dart`, `lib/services/voice_room_manager.dart`, `lib/services/webrtc_service.dart` — all stay; they only get **additions** for C-i/ii/iii/iv/v/vi/vii.
- `lib/services/chat_socket_service.dart` — gains presence events for E and reconnect events for C-vi; stays in place.

## File-by-file refactor map (wave 1)

| Origin | Destination | Action | Size before → after |
|---|---|---|---|
| `community_main.dart` | `main/community_main.dart` + 3 splits | split | 670 → ~300 |
| `community_card.dart` | `card/community_card.dart` + 3 splits | split + dark-mode + presence dot | 648 → ~300 |
| `community_filter.dart` | `filter/*` (9 files) | split + rebuild UX (A) | 1,769 → ~400 + 8 sections |
| `single_community.dart` | `single/*` (8 files) | split + add mutual-interests (D) | 2,532 → ~600 + 7 sections |
| `partner_discovery_tab.dart` | `tabs/partner_discovery_tab.dart` | split helpers to widgets/, polish | 1,274 → ~600 |
| `nearby_tab.dart` | `tabs/nearby_tab.dart` | split helpers, polish | 1,188 → ~600 |
| `city_tab.dart` | `tabs/city_tab.dart` | split helpers, polish | 1,054 → ~500 |
| `genders_tab.dart` | `tabs/genders_tab.dart` | split helpers, polish | 931 → ~500 |
| `topics_tab.dart` | `tabs/topics_tab.dart` | move + extract `_FilterChip` use | 482 → ~400 |
| `waves_tab.dart` | `tabs/waves_tab.dart` | move + wire into `CommunityMain` (B) | 320 → ~320 |
| `voice_rooms/voice_rooms_tab.dart` | same | split, drop hardcoded language list, use shared `_FilterChip`, shared snackbar/empty/error | 578 → ~300 |
| `voice_rooms/voice_room_screen.dart` | same + 6 new files | split + add chat panel + host menu + hand-raise + speaking + reconnect banner (C-i to C-vii) | 556 → ~300 + new files |
| `voice_rooms/create_room_sheet.dart` | same | move + minor polish | 364 → ~360 |

## Cross-cutting passes

These run as their own micro-PRs before any feature work:

1. **C0 — deps + l10n keys:** add new ARB keys for waves-send, voice-room chat, host menu, online-now, reconnect banner; bump any deps as needed.
2. **C1 — `widgets/` scaffolding:** create the 5 shared widgets, no callers yet.
3. **C2 — snackbar migration:** replace ~30 inline `ScaffoldMessenger.showSnackBar(...)` calls with `showCommunitySnackBar()`.
4. **C3 — `_FilterChip` unification:** delete 3 duplicates, point to `widgets/community_filter_chip.dart`.
5. **C4 — withOpacity → withValues + dark-mode pass:** sweep across the 13 files.
6. **C5+ — file-by-file splits + feature work** (per the table above).

This mirrors the chat phase 1 C0–C5 cadence so the early commits are pure refactor with low risk.

---

## Data model & backend changes

### Inferred current backend (from `endpoints.dart` + Flutter models)

| Collection / store | Fields used by Flutter today |
|---|---|
| `users` | `_id, name, username, email, password, gender, birth_*, native_language, language_to_learn, images[], topics[], location{type,coordinates,city,country,formattedAddress}, languageLevel, vipStatus, termsAccepted, profileCompleted, followers[], following[]` |
| `voicerooms` | `_id, title, host {populated user}, topic, language, participants[{user, role, isMuted, joinedAt}], maxParticipants, isLive, createdAt` |
| `waves` | inferred: `_id, fromUserId, toUserId, emoji?, message?, isRead, createdAt` (model `Wave` referenced by `getWavesReceived()` + `markWavesAsRead()`) |
| `topics` | `_id, name, icon` (used by `Topic.defaultTopics` + `community/topics/:id/users`) |
| In-memory presence | likely tracked via chat socket connections, but **no API surface or socket events exposing it to clients** |

> **Validation needed:** confirm the `waves` collection schema and presence-store implementation against the actual database before implementing the backend pieces below. Where actual schema differs, update this spec in place.

### B — Waves (send + mutual + UI surfaces)

The Flutter side already has `sendWave({targetUserId, message?})` wired against `POST community/wave` (singular) returning `WaveResponse {waveId, isMutual, message}`. Wave 1's backend work is to **confirm the endpoint actually exists on the server** and add what's missing — not to design a new contract.

| Change | Detail |
|---|---|
| **Endpoint (existing contract)** | `POST community/wave` — body `{targetUserId, message?}`. Confirm during C15 that the server route exists with this contract; if it doesn't, implement it matching the existing Flutter shape rather than redesigning |
| **Validation** | Reject if `targetUserId == self` (400), if either user has blocked the other (403), or if a wave from this sender to this recipient was sent within `WAVE_COOLDOWN_HOURS` (env var, default 24h) (429 — Flutter already maps this to `response.isRateLimited`). Cooldown applies only to **future** sends; existing waves in the window are not retroactively invalidated when env tuned |
| **Mutual detection** | If recipient has previously waved at sender within configurable lookback (default: any time), set `isMutual: true` in response. Server work, no schema change |
| **Indexes** | Compound `{fromUserId, targetUserId, createdAt}` for the rate-limit check; `{targetUserId, isRead, createdAt: -1}` for the receive list (verify if not present) |
| **Push notification** | Reuse existing FCM pipeline. **Payload format will be designed against the actual notification handler in C15** — this spec doesn't lock the type-string format because the existing handler shape wasn't grepable from spec context. Goal: tap → community route, deep-linked to Waves tab |
| **Coalescing** | If user has > 3 unread waves in last 6h, suppress per-wave pushes and send one daily summary "{N} people waved at you" (cron-driven). Server-side flag |

### C — Voice rooms

#### C-v: Stale-room cleanup

| Change | Detail |
|---|---|
| **`voicerooms` field** | Add `lastHeartbeatAt: Date` (defaults to `createdAt` on insert) |
| **New socket event** | `voiceroom:heartbeat` — client emits every 20s while in room; server updates `lastHeartbeatAt` and `participants[]` if needed |
| **Cleanup job** | Cron every 60s: `voicerooms.updateMany({isLive: true, lastHeartbeatAt: {$lt: now-90s}}, {$set: {isLive: false}})`. Alternative: MongoDB TTL index on `lastHeartbeatAt` (60s TTL) but that **deletes** the doc — for analytics retention prefer the cron + flag approach |
| **`GET voicerooms`** | Filter to `{isLive: true, lastHeartbeatAt: {$gte: now-60s}}` for an extra safety net (in case cron is behind) |

#### C-vi: Reconnect

| Change | Detail |
|---|---|
| **New socket event** | `voiceroom:rejoin` — client emits on socket reconnect with `{roomId, lastSeenAt}`. Server checks room still exists + `isLive`, adds user back to `participants[]`, broadcasts `voiceroom:participant-joined` to others, and ACKs caller with current room state |
| **Server response** | If room ended/missing, server emits `voiceroom:ended` to the rejoining client so it cleans up |
| **Flutter trigger** | `chat_socket_service` already has reconnect logic (`enableReconnection()`); add a hook in `VoiceRoomManager` to fire `voiceroom:rejoin` whenever socket reconnects AND `_currentRoom != null` |

#### C-vii: Host transfer

**State machine for host disconnect** (resolves the C-vi × C-vii × wave race):

```
Host states: PRESENT → DISCONNECTED (grace) → PROMOTED_AWAY | RECLAIMED
                                ↑                ↓
                                └── rejoin ──────┘  (only if before grace expires)
```

- **Trigger:** Host's heartbeat misses 2 cycles (40s no `voiceroom:heartbeat`) OR explicit `voiceroom:leave`.
- **On trigger:** server starts a 30s grace timer keyed on `{roomId, hostUserId}`. Host stays in `host` field; `participants[]` unchanged. No broadcast yet.
- **During grace:**
  - If host emits `voiceroom:rejoin` (ACK) before timer fires → cancel timer, host stays. No broadcast.
  - If `voiceroom:heartbeat` resumes → cancel timer, host stays.
  - If timer fires → promote next-oldest `joinedAt` participant: update `host` field + their `role: 'host'`, broadcast `voiceroom:host-changed {newHostId, previousHostId}`. Old host moves to `role: 'guest'` (or removed if also disconnected; see below).
- **After grace expired (PROMOTED_AWAY):**
  - If old host's `voiceroom:rejoin` arrives, server treats them as a returning guest: re-add to `participants[]` with `role: 'guest'`, `isHost: false`. Server includes `youArePromoted: false` and `currentHostId: <newHostId>` in the rejoin ACK so client can demote local UI.
  - Old host's snackbar: "{newHost.name} is now the host" (same as for everyone else).
- **Empty-room edge:** if grace fires and `participants.length == 0` (everyone disconnected), set `isLive: false` and skip the broadcast.

| Change | Detail |
|---|---|
| **Server logic** | Per state machine above. Grace timer stored in-memory keyed by `{roomId, hostUserId}` |
| **New socket event** | `voiceroom:host-changed` — `{newHostId, previousHostId}`. Clients update local `RoomParticipant.isHost` + `VoiceRoom.hostId`; show snackbar |
| **Rejoin ACK extension** | `voiceroom:rejoin` ACK payload gains `{youArePromoted: bool, currentHostId: string}` so a returning ex-host can correctly resync their UI role |
| **Empty room** | If host leaves and no other participants, set `isLive: false` immediately (skip grace) |

#### C-ii / C-iii: Hand-raise + speaking

| Change | Detail |
|---|---|
| **Hand-raise** | No backend change. Server already broadcasts `voiceroom:raise-hand`. **Client-side fix:** add `isHandRaised` to `RoomParticipant` model + propagate from socket listener (`voice_room_manager.dart:181-187` currently has `// could add handRaised to model` TODO) |
| **Speaking indicator** | Client-side via `flutter_webrtc` audio level events (`getStats()` polling every 500ms; threshold 0.05 RMS). No backend change. No socket broadcast — avoids server load |

#### C-i / C-iv: chat UI / host controls

No backend changes (already wired). UI-only.

### E — Presence (online-now)

| Change | Detail |
|---|---|
| **Presence store** | Server maintains `Map<userId, {socketId, lastSeenAt}>` keyed by user. Likely already exists for chat socket; expose via API |
| **`users` field** | Add `lastSeenAt: Date` (write on disconnect) |
| **New socket events** | `presence:online {userId}`, `presence:offline {userId, lastSeenAt}` — broadcast to **followers + people who have an active conversation with** this user (NOT all-users — bandwidth). Initial `presence:bulk {onlineUserIds: [...]}` on connect, capped at 200 entries |
| **`GET community/users` augmentation** | Each user payload gains `isOnline: bool` (derived from in-memory presence store at request time) and `lastSeenAt: Date` |
| **`GET community/users?online=true`** | New query param; filters to userIds present in the in-memory store. Used by the "Online now" filter toggle (E) |
| **Flutter** | `chat_socket_service` adds `onPresenceChanged: Stream<{userId, isOnline, lastSeenAt}>`; community card avatar listens and updates green-dot in real time |

### Indexes summary (wave 1)

| Collection | Index | Reason |
|---|---|---|
| `waves` | `{fromUserId, toUserId, createdAt}` | rate-limit check |
| `waves` | `{toUserId, isRead, createdAt: -1}` | receive list (existing? confirm) |
| `voicerooms` | `{isLive, lastHeartbeatAt}` | active-rooms list + cleanup query |
| `users` | `{lastSeenAt}` | future "recently active" sort (wave 2) — add now while we're touching the field |

### Backend things NOT changing

- Auth, OAuth, VIP, ads, moments, stories, chat — all untouched.
- Existing voice room signaling (offer/answer/ice-candidate) — stays mesh until wave 2.
- `chat_socket_service` reconnect logic — reused, not rewritten.

---

## Feature designs

### A. Filter UX rebuild

**Behavior**

- Filter button in `CommunityMain` opens a redesigned bottom sheet
- Sections collapse/expand independently; only Age + Gender expanded by default
- Sticky top: live "**N partners match**" count, debounced ~300ms as filters change
- Sticky bottom: "Clear all" + "Apply" actions
- Individual "Reset" link per section header
- Persists via existing SharedPreferences key `community_filters`, but with typed `FilterState.toJson()` instead of `Map<String, dynamic>`

**Files (per layout)**

- `filter/community_filter_sheet.dart` — sheet shell + sticky bars + collapse state
- `filter/filter_state.dart` — `class FilterState { ageRange, gender, nativeLanguage, learningLanguage, country, topics, level, onlineOnly, newUsersOnly, prioritizeNearby }` + `toJson/fromJson`
- `filter/filter_<section>.dart` × 8 — each section is a `StatelessWidget` taking its slice of `FilterState` + an `onChanged` callback

**Data flow**

- `CommunityMain` owns `FilterState`; passes to sheet; sheet returns `FilterState?` on Apply (null on dismiss)
- Match-count query: lightweight `GET community/users/count?<filters>` (new endpoint; returns just `{count}`) — debounced
- Tabs receive `FilterState` and re-fetch when it changes

**Edge cases**

- Removing a topic that's currently selected → other sections auto-update
- Match-count API failure → hide the count silently; don't block applying

### B. Waves — send UI + mutual + unread badge

The Flutter `sendWave({targetUserId, message?})` and `WaveResponse {waveId, isMutual, message}` already exist (`community_provider.dart:283-306, 535-553`). Wave 1 adds the UI affordances and surfaces `isMutual`.

**Behavior**

- Wave button on every partner card (`card/community_card_actions.dart`) and on `single_community_actions.dart`
- Tap → small bottom sheet with 6 quick-reply messages (each prefixed with an emoji): `"👋 Hi!"`, `"❤️ You seem cool"`, `"😊 Hey there"`, `"🎉 Let's chat"`, `"✋ Hello"`, `"🌟 Hi from {country}"` — plus an optional free-text input. The chosen string is the `message` param to `sendWave`
- Sent → toast "Wave sent to {name}"; button greys out for cooldown window with tooltip "You can wave {name} again in {time}"
- **Mutual celebration:** if `WaveResponse.isMutual == true`, show a one-shot dialog/lottie "It's a match! 🎉 You and {name} both waved" with a "Send a message" CTA that opens chat
- Recipient: push notification → opens app on Community → Waves tab
- `CommunityMain` Waves tab gets red unread-dot badge from a new `wavesUnreadProvider` (FutureProvider that calls `getWavesReceived(unreadOnly: true)` and exposes the count)

**Files**

- New: `community/widgets/wave_button.dart`
- New: `community/widgets/send_wave_sheet.dart` — quick-replies + free-text
- New: `community/widgets/mutual_wave_dialog.dart` — one-shot "it's a match" UI
- Edit: `card/community_card_actions.dart`, `single/single_community_actions.dart` — embed wave button (with live presence dot per cross-feature interaction)
- Edit: `lib/providers/provider_root/community_provider.dart` — add `wavesUnreadProvider` FutureProvider (refresh on app resume + after `markWavesAsRead`)
- **No changes to `endpoints.dart` or `sendWave()`** — both already exist
- **No new `services/community_service.dart` method** — `sendWave` lives in the provider's `CommunityService` already

**Data flow**

- Tap → sheet opens → user picks/composes message → `communityService.sendWave(targetUserId: id, message: chosenMessage)` → API POST → on 200, success snackbar; if `isMutual`, show match dialog; if rate-limit (`isRateLimited`), error snackbar with cooldown
- Local optimistic state: button shows greyed immediately; reverts on error
- Cooldown cache: client stores `{targetUserId → lastSentAt}` in memory + `SharedPreferences` so button stays greyed without re-hitting the API on rebuild

**Edge cases**

- Self-wave → button hidden on own profile (mirror existing follow-button check)
- Recipient blocked sender → 403 → snackbar "Couldn't send wave" (don't disclose blocked status)
- Rate-limited → already mapped to `response.isRateLimited` → snackbar "You can wave {name} again in {time}"; cache the timestamp
- Network failure → snackbar "Couldn't send wave"; un-grey button
- During voice-room reconnect (C-vi): incoming waves still process via push notification path — no special handling needed
- Recipient deleted account → 404 → silent fail; we don't expose this to sender

### C. Voice rooms overhaul

#### C-i — In-room chat UI

**Behavior**

- Chat icon in `voice_room_controls.dart` (left of mute, with unread badge)
- Tap → bottom sheet panel slides up over participants grid (~50% screen height); drag-down to dismiss
- List of recent messages: avatar + name + text, newest at bottom; auto-scroll on new
- Text input at bottom; "Send" enabled when non-empty
- Plain text only for wave 1 (no media, no emoji picker)
- Ephemeral — clears on leave (already the case)

**Files**

- New: `voice_rooms/voice_room_chat_panel.dart`
- Edit: `voice_rooms/voice_room_controls.dart` — chat icon w/ badge
- Edit: `voice_rooms/voice_room_screen.dart` — host the panel as a `DraggableScrollableSheet`

#### C-ii — Hand-raise visible on tile

**Behavior**

- Hand emoji badge appears top-left of any participant who has hand raised
- Gentle pulse animation on raised participants

**Code change**

- Add `bool isHandRaised` to `RoomParticipant` model + `fromJson`
- Fix `voice_room_manager.dart:181-187` to update participant in `_participants` and call `onStateChanged`

#### C-iii — Speaking indicator (client-only)

**Behavior**

- Existing green ring on `voice_room_participant_tile.dart` lights up when participant is actively speaking
- Suppressed if participant `isMuted == true`

**Implementation**

- `WebRTCService` exposes `Stream<Map<String, double>> peerAudioLevels` (peerId → 0..1 RMS), polled every 500ms via `RTCPeerConnection.getStats()` (`audioLevel` field on inbound-rtp stats)
- `VoiceRoomManager` consumes the stream; threshold 0.05 → flips `RoomParticipant.isSpeaking`; suppress if `isMuted`
- Local user: same logic via `getStats()` on local stream
- **Perf guards:** poll only while screen is in foreground AND room has > 1 participant; back off to 1s if frame budget exceeded

#### C-iv — Host controls

**Behavior**

- When current user is host: control bar shows "End room" (red) instead of "Leave"; tapping prompts confirm dialog → `endRoom()`
- Long-press a non-host participant tile → bottom sheet with "View profile" + "Remove from room" (red, with confirm)
- Guest UI unchanged

**Files**

- New: `voice_rooms/voice_room_host_menu.dart` — end-room confirm dialog
- New: `voice_rooms/voice_room_participant_actions.dart` — long-press sheet
- Edit: `voice_rooms/voice_room_screen.dart` — show host vs guest controls based on `currentUserId == _currentRoom.hostId`

#### C-v — Stale-room cleanup

**Behavior** — invisible to user; rooms in the list are always fresh

**Implementation**

- `VoiceRoomManager` emits `voiceroom:heartbeat` every 20s via a Timer started on `joinRoom`, cancelled on `leaveRoom`/`_cleanup`
- Backend: cron + `lastHeartbeatAt` (see Data model section)
- Defensive: `voiceRoomProvider.fetchRooms()` already filters via backend

#### C-vi — Reconnect

**Behavior**

- Socket drops mid-room → yellow banner appears: "Reconnecting…"; controls disabled
- Socket recovers → banner clears; participants list re-syncs
- If room ended during the gap → snackbar "Room ended" + auto-pop the screen

**Implementation**

- New: `voice_rooms/voice_room_reconnect_banner.dart`
- `VoiceRoomManager` subscribes to `chat_socket_service.connectionState` stream
- On disconnect-while-in-room: emit local `onConnectionLost` callback → screen shows banner
- On reconnect-while-in-room: emit `voiceroom:rejoin {roomId}`; await ACK or `voiceroom:ended`
- Backend: see Data model section

#### C-vii — Host transfer

**Behavior**

- Host disconnects/leaves → after 30s grace → next-oldest participant (by `joinedAt`) becomes host
- Promoted user sees snackbar "You're now the host" + UI swaps to host controls
- Other users see snackbar "{name} is now the host"
- If host returns within the grace window, no transfer; if they return after, they come back as a guest. See state machine in **Data model & backend changes → C-vii** for the full logic (grace cancellation, post-grace rejoin ACK, empty-room edge)

**Implementation**

- Frontend: listener for `voiceroom:host-changed {newHostId}` updates `RoomParticipant.isHost` flags + `VoiceRoom.hostId`; shows appropriate snackbar
- Backend: see Data model section

### D. Mutual interests on `single_community`

**Behavior**

- New section appears on the profile detail screen, between the languages card and engagement bar
- Title: "**N interests in common**" (or "No interests in common yet")
- Up to 6 topic chips: green-bordered + check icon for shared, grey for not-shared
- "See all" if profile has > 6 topics

**Files**

- New: `single/single_community_topics.dart`
- Edit: `single/single_community_screen.dart` — insert section in the scroll body

**Data flow**

- Pure client computation: intersection of `widget.community.topics` with `userProvider.topics`
- No backend change

**Edge cases**

- Either user has zero topics → show empty state with "Add topics" CTA linking to profile edit
- Topics list is large → cap at 6 with "See all" → opens dialog with full list

### E. Online-now presence

**Behavior**

- Green dot (10×10, white border) in bottom-right of avatar on every community card and `single_community` header
- Profile detail header shows pill: "Online now" (green) or "Active {timeago}" (grey)
- Filter sheet has toggle "Online now only" → adds `?online=true` to user-list queries
- Live updates: open the tab, watch dots come/go in real time as friends connect/disconnect

**Files**

- New: `lib/providers/presence_provider.dart` — exposes `Set<String> onlineUserIds` + `Map<String, DateTime> lastSeen`
- Edit: `services/chat_socket_service.dart` — add `Stream<PresenceUpdate> onPresenceChanged`; emit on `presence:online` / `presence:offline` events
- Edit: `card/community_card_avatar.dart` — green dot via `presenceProvider`
- Edit: `single/single_community_header.dart` — pill text
- Edit: `filter/filter_toggles_section.dart` — wire `onlineOnly`
- Edit: tab fetch logic — pass `online=true` when filter active

**Data flow**

- On socket connect: server pushes initial `presence:bulk {onlineUserIds: [...]}` for the user's followers + active conversation partners
- Subsequent: `presence:online {userId}` and `presence:offline {userId, lastSeenAt}` deltas
- Provider keeps the set; widgets watch with `ref.watch(presenceProvider.select((p) => p.isOnline(userId)))` for surgical rebuilds

**Edge cases**

- App backgrounded → server marks user offline after 30s of socket idle (existing chat behavior, reuse)
- Massive followers list → server caps initial `presence:bulk` at first 200 (rest fetched on demand if user opens that profile)
- Toggle "Online now" with prioritize-nearby — both apply (server-side AND in filter)

### Cross-feature interactions

| Combination | Behavior |
|---|---|
| **Wave + presence** | Wave button shows live presence dot inside the button itself (online green / offline grey) — micro-touch |
| **Filter + presence** | "Online now" toggle in filter; visible immediately on tabs |
| **Voice rooms + presence** | Host controls don't change based on online — once you're in the room, you're "in" regardless |
| **Mutual interests + filter** | Future wave 2: filter "shares ≥ N interests with me." Out of scope wave 1 |

---

## Testing strategy

| Layer | Approach |
|---|---|
| **Refactor PRs (C0–C12)** | `flutter analyze` must be clean per PR. Manual smoke test each tab + filter sheet on iOS + Android. No new tests required (matches chat phase 1 cadence). |
| **Backend additions** | Unit tests for: `POST community/waves` (rate-limit, block, self-wave, success), `voiceroom:heartbeat`/cleanup (TTL boundaries), `voiceroom:rejoin` (room exists / ended / not in room), host-transfer (host leaves with N>1, with N=1, returns within grace), `presence:*` events (online/offline/bulk fan-out scope). |
| **Critical user flows** | Manual E2E on a staging build: send wave → notification → mark read; create room → invite second device → kill app on host → confirm 30s host transfer; rejoin after airplane-mode toggle. |
| **Speaking indicator perf** | Profile `getStats()` polling at 500ms with 8 peers on a mid-tier Android. Acceptance: < 5% CPU steady-state. If higher → drop to 1s polling. |
| **Filter perf** | Match-count debounce verified (only one in-flight request); 2G throttle test in DevTools Network. |

## Rollout & migration

- **Backend goes first.** All schema additions are nullable/default-safe (`isHandRaised: false`, `lastHeartbeatAt: createdAt`, `lastSeenAt: null`, new indexes). New endpoints are additive. Old clients keep working.
- **Frontend lands in commit waves**, not all at once. The refactor commits (C0–C12) are intentionally sequential and pure-refactor — each one safe to revert independently.
- **No feature-flag gating.** The codebase has `lib/utils/feature_gate.dart` but it's a VIP/permissions gate (`canSendMessage`, `canCreateMoment`), not a flag store, and there's no remote-config infrastructure. Wave 1 relies on **commit-revertability** — each `Cxx` commit is independently revertable. If a feature misbehaves in production, revert the relevant `Cxx` commit and ship a hotfix. Designing a flag store is itself a project and is out of scope here. Filter rebuild keeps the old code compilable (renamed) for one release as a manual fallback if needed (revert C19 to switch back).
- **SharedPreferences migration** — `community_filters` key currently holds a `Map<String, dynamic>`. The new `FilterState.fromJson` includes a backwards-compat reader that coerces the old shape. Old saved filters survive the upgrade. After 1 release we can drop the compat reader.

## Risk register

| Risk | Likelihood | Mitigation |
|---|---|---|
| Folder restructure breaks imports across the app (community is referenced from chat, profile, moments, search) | Medium | Single-PR mass-move; rely on analyzer + IDE refactor; CI run before merge. Same approach as chat C7 (27-file move) which landed cleanly. |
| Speaking-indicator polling spikes CPU on low-end devices | Medium | Throttle dynamically: poll only while screen is in foreground AND room has > 1 participant; back off to 1s if frame budget exceeded. |
| Reconnect double-cleanup race (socket reconnects after room already cleaned) | Medium | Idempotent cleanup; guard `_cleanup()` with `if (_currentRoom == null) return`. Already partially in place. |
| Presence broadcast fan-out scales poorly on a single Node process | Low–Medium | Cap initial `presence:bulk` at 200 entries; further entries fetched on demand. Document scaling concern; revisit if user count climbs. |
| Mesh WebRTC stays fragile (8 participants) | Already there | Don't widen `maxParticipants` past 5 in the create-room sheet UI even though model says 8 — set client-side cap to 5 until SFU lands (wave 2). |
| Filter rebuild changes saved-filter JSON shape, users see "no results" | Low | Backwards-compat `FilterState.fromJson` + 1 release of dual-read. Tested in unit. |
| Wave anti-spam window feels too long at 24h after testing | Medium | Server-config-driven (`WAVE_COOLDOWN_HOURS` env var), default 24h, tunable without redeploy. |
| Push notification for waves spammy if user receives many | Medium | Group/coalesce: if user has > 3 unread waves, send one summary push instead of one per wave. Server-side. |

## l10n plan

**New ARB keys (English first, then 17-locale translation in its own commit per past pattern):**

| Group | Approx. count |
|---|---|
| Waves: send button, emoji picker, success/error toasts, anti-spam tooltip, send-sheet title, badge | ~12 |
| Voice room chat: panel title, input placeholder, empty, send | ~5 |
| Voice room host: end-room confirm, kick confirm, "you're now the host", "{name} is now the host", host menu items | ~10 |
| Voice room reconnect: banner text, "room ended" snackbar, retry | ~4 |
| Mutual interests: section title, "N in common" plural, empty state CTA | ~5 |
| Presence: "Online now", "Active {time} ago", filter toggle label | ~3 |
| Filter rebuild: 8 section titles, "N partners match" plural, "Clear all", "Reset", "Apply" | ~14 |
| **Total new keys (wave 1)** | **~53** |

Translation cadence: one English-keys commit (C5) + one translate-to-17-locales commit (C6) — same as `61c87af refactor(auth): C2 — 13 new ARB keys for Phase 2 across 18 locales`.

## PR / commit breakdown

Following the chat phase 1 cadence (C-prefixed sequential commits, often one-commit-per-PR or grouped 2–3 per PR):

**Foundation (refactor-only, low risk):**

- **C0** — `chore(community)`: deps + branch setup
- **C1** — `refactor(community)`: add `widgets/` scaffolding (5 shared widgets, no callers)
- **C2** — `refactor(community)`: migrate ~30 inline snackbars to `showCommunitySnackBar`
- **C3** — `refactor(community)`: extract `_FilterChip` from `voice_rooms_tab.dart:514` to `widgets/community_filter_chip.dart`, point the 4 in-file callers at the shared widget
- **C4** — `fix(community)`: `withOpacity` → `withValues` + dark-mode pass
- **C5** — `refactor(community)`: add English ARB keys for wave 1 (~53)
- **C6** — `refactor(community)`: translate keys to 17 locales

**File splits (mechanical, low risk):**

- **C7** — `refactor(community)`: split `community_main` → `main/`
- **C8** — `refactor(community)`: split `community_card` → `card/`
- **C9** — `refactor(community)`: split `community_filter` → `filter/` + `FilterState`
- **C10** — `refactor(community)`: split `single_community` → `single/`
- **C11** — `refactor(community)`: flatten tabs into `tabs/`, extract helpers
- **C12** — `refactor(community)`: split `voice_rooms/` into focused units

**Features (visible changes — each commit has explicit acceptance criteria):**

| # | Commit | Verification (definition of done) |
|---|---|---|
| C13 | `feat(community)`: wire `WavesTab` into `CommunityMain` (7th tab + unread badge) | Tab strip shows 7 tabs; tapping Waves loads received list; unread dot appears when `wavesUnreadProvider > 0`, clears on `markWavesAsRead` |
| C14 | `feat(community)`: waves send button + quick-reply sheet + mutual-wave dialog | Wave button on every card and `single_community`; sheet picks message; success toast appears; `WaveResponse.isMutual == true` triggers match dialog with chat CTA; cooldown greys the button |
| C15 | `feat(community)` + backend: confirm/implement `POST community/wave`, rate limit, push notification | Backend rejects self/blocked/cooldown with documented codes; push notification arrives on physical device; deep-link opens Waves tab |
| C16 | `feat(community)`: mutual interests on `single_community` (D) | Section renders between languages and engagement; counts shared topics correctly across 5 test profiles; empty state shows when either has 0 topics |
| C17 | `feat(community)` + backend: presence socket events + `presence_provider` (E backend integration) | Provider state updates within 2s of a peer connecting/disconnecting; `presence:bulk` arrives on connect with at most 200 entries (order doesn't matter — set-based) |
| C18 | `feat(community)`: online-now dot + filter toggle (E frontend complete) | Green dot renders on cards for users in `presenceProvider.onlineUserIds`; toggle sends `online=true` query and filters list |
| C19 | `feat(community)`: filter rebuild — match-count, sticky bars, sectioned (A) | Sheet opens with sections collapsed; match count debounces (only 1 in-flight); Apply returns typed `FilterState`; old `Map<String,dynamic>` saved-filters survive upgrade (unit test) |

**Voice rooms overhaul:**

| # | Commit | Verification (definition of done) |
|---|---|---|
| C20 | `feat(voice-rooms)`: in-room chat panel (C-i) | Chat icon opens `DraggableScrollableSheet`; messages from socket render newest-at-bottom; sending an empty message is a no-op; closing/reopening preserves messages until leave |
| C21 | `fix(voice-rooms)`: hand-raise visible on tile (C-ii) | `RoomParticipant.isHandRaised` updates from socket; tile shows hand badge when raised; pulse animation runs while raised |
| C22 | `feat(voice-rooms)`: speaking indicator via WebRTC stats (C-iii) | Green ring lights up on talking peer; suppressed if peer `isMuted == true`; CPU < 5% steady-state on Pixel 4a with 4 peers |
| C23 | `feat(voice-rooms)`: host controls — kick + end-room (C-iv) | Host control bar shows "End room"; long-press participant tile opens kick sheet; both confirm via dialog; non-host UI unchanged |
| C24 | `feat(voice-rooms)` + backend: heartbeat + stale-room cleanup (C-v) | Client emits heartbeat every 20s while in room; cron flips `isLive: false` on rooms with `lastHeartbeatAt < now-90s`; `GET voicerooms` excludes stale rooms |
| C25 | `feat(voice-rooms)` + backend: reconnect banner + rejoin protocol (C-vi) | Airplane-mode toggle in room shows "Reconnecting…" banner; on recovery, banner clears and participants list re-syncs; if room ended during gap, snackbar + auto-pop |
| C26 | `feat(voice-rooms)` + backend: host transfer protocol (C-vii — see state machine) | Host-leaves-with-N>1 → 30s grace → next-oldest promoted → snackbars on all clients; host-rejoins-during-grace → no transfer; host-rejoins-after-grace → demoted to guest with correct local UI |

**Polish:**

- **C27** — `chore(community)`: final analyzer cleanup, docs touch-ups, manual smoke pass across all 7 tabs in iOS + Android dark + light modes

**Total: ~28 commits, ~6–8 weeks.** Mirrors chat phase 1 throughput.

---

## Future waves (not implemented in wave 1)

Sketched here so the next planning round has a head start. Each gets a one-sentence direction, no detail.

### Wave 2 — Voice rooms infrastructure

- **C-viii Mesh → SFU migration.** Pick a stack (LiveKit / Mediasoup / Daily / Agora; LiveKit is the strong default — Apache 2.0, self-hostable, good Flutter SDK). Token issuance endpoint. Replace `voiceroom:offer/answer/ice-candidate` signaling with SFU client SDK. Migration: dual-mode flag for transition; bump `maxParticipants` cap from 5 → 50 once SFU stable.

### Wave 2 — Discovery / engagement

- **Smart match-score** — server-side ranking pipeline scoring language-pair compatibility + level + topics overlap + presence + reciprocity history. New `community/users/recommended` endpoint. Card surfaces a 0-100 "match" badge.
- **Recently-active sort** — index on `lastSeenAt` (added in wave 1); `?sort=recently_active` query param; sort chip on partner_discovery.
- **Profile-visitor recall** — surface "X visited your profile" inside the community tab (already collected by `profile_visitor_service`; not yet shown here).

### Wave 2 — Voice rooms features

- **Scheduled rooms** — `voicerooms.scheduledFor: Date`; RSVP collection; reminder cron + push.
- **Mute-all (host control)** — host can mute every participant in one tap.
- **Voice room categories** — beyond filter chips: "Casual" / "Language Practice" / "Topic" / "Q&A" categorization; affects discovery surface.

### Wave 2 — Profile detail

- **Last moment / story preview embedded** in `single_community` between header and engagement.
- **Filter "shares ≥ N interests with me"** toggle (depends on wave 1's mutual interests work).
- **Common partners / friends-of-friends** — needs friends graph queries; medium-heavy.

### Wave 2 — Engagement

- **Wave history archive** — currently only "received" + read tracking; add an archive view that keeps read waves visible for some retention window.
- **Conversation-starter prompts** — lightweight prompts on cards ("Say hi in their native language" / "Ask about their last moment") — beyond what `single_community` already shows.
