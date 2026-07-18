# Community Rooms Optimization — Design Spec

**Date:** 2026-07-18
**Status:** Approved (design), pending implementation plan
**Source audit:** `.superpowers/sdd/rooms-audit-report.md` (full file:line findings + feature sketches)

## Background

Community has two room systems: **Voice Rooms** (LiveKit live audio — `lib/pages/community/voice_rooms/**`, `voice_room_manager.dart`, `voice_room_provider.dart`) and text **Rooms/"hubs"** (`lib/pages/community/rooms/**`, `rooms_provider.dart`, `room_api_client.dart`). A read-only audit across UX, reliability, engagement, and performance found reliability landmines, a top-tier jank source, weak discovery ("empty rooms"), a critical trap in the requested tab reorder, and 10 ranked feature opportunities.

## Goals

Optimize the whole Rooms area across four dimensions and add new engagement features, delivered in phases so reliability/perf land before the tab move and new features.

## Product decisions (locked with user)

1. **Tab layout:** move BOTH room tabs together, adjacent, right after Gender — target order: All(0) → Gender(1) → **Voice Rooms(2) → Rooms(3)** → Nearby → City → Topics → Waves. (Not just the text Rooms tab; keeps the two room concepts together and both discoverable.)
2. **Feature scope:** Tier 1 + Tier 2 from the audit (push reminders, N-live pill, room previews, who's-talking, post-room connect, co-host/promote-to-speaker, trending/recommendations, capacity waitlist). NOT Tier 3 (in-room captions, recording) this cycle.

## Non-goals
- Merging the two room data models (`Room` vs `VoiceRoom`) into one system.
- Tier 3 features: live captions, room recording/highlights (deferred — need LiveKit egress + infra).
- Video rooms / TikTok-style clips (out of scope).

## Cross-cutting constraints
- Both light and dark mode for every new/changed UI element.
- New coin/notification/backend surfaces must degrade gracefully when their data/flag is absent.
- Backend changes land in the separate `../backend` repo (branch to confirm with user) and require deploy to take effect (the app hits production `api.banatalk.com`).
- Do not regress existing voice/text room behavior; changes to the index-sensitive tab logic must be verified against the feature-flag flip.

---

## Phase 1 — Reliability + critical UX

- **R1 Surface kicked/room-ended reason.** `VoiceRoomNotifier` sets `state.error` ("Room ended by host"/"You were removed") but nothing shows it. In `VoiceRoomScreen`'s existing `ref.listen` that pops on `currentRoom==null` (`voice_room_screen.dart:253-260`), branch on `next.error` and show a `CommunitySnackBar`/dialog before popping.
- **R2 Fix `VoiceRoomManager.dispose()` singleton landmine.** `dispose()` (`voice_room_manager.dart:523-536`) cancels subscriptions/disconnects but never resets `_isInitialized`/`_chatSocketService`; since both it and `ChatSocketService` are process singletons, the next `initialize()` early-returns and never re-subscribes → rooms look connected but stop updating. Fix: reset `_isInitialized=false; _chatSocketService=null;` at the top of `dispose()`.
- **R3 Fix silent unmute failure.** `toggleMute()` (`voice_room_manager.dart:436-448`) flips `_isMuted` + notifies before publish, and calls `setMuted` unawaited with no try/catch (`voice_room_livekit_manager.dart:116-118`). On denied mic permission the user thinks they're talking. Fix: await `setMuted`, try/catch, on failure revert `_isMuted`, notify, and surface "Microphone permission needed" (Settings deep link).
- **R4 Reconnect robustness.** (a) Track reconnecting as `socketReconnecting || liveKitReconnecting` instead of two booleans overwriting each other (`voice_room_manager.dart:117-161, 327-347`). (b) Set all manager callbacks (`onHostChanged`/`onForcedMuteSelf`/`onReactionReceived`) in the SAME place, BEFORE `joinRoom()`, closing the missed-event window (`voice_room_screen.dart:64-111`). (c) Add a ~15s timeout to `joinRoom()`'s REST+LiveKit connect with a retry/leave option (`voice_room_manager.dart:376-379`, `voice_room_provider.dart:171-189`).
- **R5 Participant-left grace fallback.** If LiveKit reports a participant disconnected and no socket `voiceroom:left` arrives within ~5-8s, remove them anyway (`voice_room_manager.dart:292-302`).
- **U1 Dark-mode card bug.** `VoiceRoomCard` hardcodes `color: Colors.white` (`voice_room_card.dart:29`) → white cards in dark mode. Use `context.containerColor` (as `RoomCard` does).
- **U2 (minor, batch with U1):** delete dead `room_chat_drawer.dart` (light-themed, zero call sites); give the chat control button a label for parity (`voice_room_controls.dart:67`); add `maxLines:1/overflow:ellipsis` to the hub AppBar title (`room_screen.dart:462`); self-driving duration/countdown ticker (`voice_room_header.dart`, `scheduled_room_card.dart`).

## Phase 2 — Performance

- **P1 Split the monolithic `VoiceRoomNotifier`.** Today one `ChangeNotifier` fans every event — including per-participant active-speaker transitions (multiple/sec) — into `notifyListeners()`, and `VoiceRoomScreen.build` watches the whole thing, rebuilding the entire subtree. Split into scoped providers/selectors: `voiceRoomParticipantsProvider`, `voiceRoomChatProvider`, `voiceRoomLocalStateProvider` (mute/hand), so each consumer rebuilds only on its slice; or wrap participant tiles in per-participant `Selector`/`Consumer`. (`voice_room_provider.dart`, `voice_room_screen.dart:248`, `voice_room_participants_grid.dart`, `voice_room_chat_panel.dart:46`.)
- **P2 Kill allocation churn.** `participants` getter allocates a new `List.unmodifiable` every access (`voice_room_manager.dart:98`) and `VoiceRoomScreen` re-sorts every build (`voice_room_screen.dart:233-243`). Memoize the sorted list; only rebuild it when membership/flags actually change.
- **P3 Cheap wins.** Avatar `Image.network` → device-pixel-aware `cacheWidth` (or the app's cached-image wrapper) in participant tiles + room cards; opt Voice Rooms tab + Rooms directory into `AutomaticKeepAliveClientMixin` so a swipe-away/back doesn't refetch + skeleton-flash.

## Phase 3 — Tab reorder + discovery

- **T1 Move both room tabs after Gender** to order All → Gender → Voice Rooms → Rooms → Nearby → City → Topics → Waves. Edit BOTH lists to the identical relative order: the `Tab` list in `community_tab_bar.dart:61-173` and the `TabBarView` children in `community_main.dart:261-291`.
  - **T1-critical: identity-safe `_syncTabCountWithRoomsFlag`.** The current remap (`community_main.dart:68-84`) preserves the numeric index across the 7↔8 length change, which is only correct because Rooms is currently appended last. Once Rooms is at index 3, a flag flip (config resolve / kill switch) would silently swap the user's visible tab. Fix: remap by tab identity — when enabling, `previousIndex += 1` if `previousIndex >= roomsInsertionIndex`; when disabling, `previousIndex -= 1` if `previousIndex > roomsInsertionIndex`. Verify `_baseTabCount`, `_partnersTabIndex`, and grep for any other hardcoded community tab index. (Audit confirmed no deep-link targets a tab index; only call site `TabBarMenu.dart:55` passes none.)
- **D1 "N live now" pill** in `community_app_bar.dart` (next to NotificationBell/CoinBalancePill) showing count of currently-live voice rooms, tap → Voice Rooms tab; hidden at 0. Backed by a light polling/socket `activeVoiceRoomCountProvider` (reuse `fetchRooms()` count or a cheap `GET /voicerooms/count`).
- **D2 Room previews.** `RoomCard` (text hubs) shows 2-3 recent-member avatars + a one-line last-message snippet (needs `recentMembers` + `lastMessage` in `GET /rooms` payload + `Room.fromJson`). `VoiceRoomCard` shows an animated "speaking" dot on the active participant (data already in `RoomParticipant.isSpeaking`); requires a short (~15-20s) list refresh while the tab is visible.
- **D3 Rooms directory language filter.** `rooms_directory_screen.dart` renders every hub flat; add a language filter/sort (default to the user's target language(s)), mirroring Voice Rooms' filter chips.

## Phase 4 — New features (Tier 1 + Tier 2)

- **F1 Scheduled-room push reminders (Tier 1, highest ROI).** Backend job fans a push to all RSVP'd users N minutes before `scheduledFor` (and at start); new `voiceroom_reminder` notification type deep-links into `VoiceRoomScreen` for that room id via `notification_router.dart`. RSVP UI already exists (`create_room_sheet.dart`, `scheduled_room_card.dart`).
- **F2 Post-room "connect" prompt (Tier 1).** On `_leaveRoom()` success (`voice_room_screen.dart:193-231`), show a sheet listing the other participants with one-tap "Add partner"/"Send wave" (reuse the Waves/follow flow). Closes the language-partner loop.
- **F3 Co-host / promote-to-speaker (Tier 2).** Extend the host long-press menu (`voice_room_participant_actions.dart`) with "Make co-host" and "Invite to speak" (acts on `isHandRaised`). Add a `role` enum (host/cohost/speaker/listener) to `RoomParticipant`; new socket events `voiceroom:promote`/`voiceroom:invite-to-speak` mirroring the existing `voiceroom:kick`/`voiceroom:mute-all` pattern.
- **F4 Trending/recommended rooms (Tier 2).** A "Recommended for you" row above the room list (`voice_rooms_tab.dart:337-418`), ranked by target-language/topic match + participant count. Backend `GET /voicerooms/recommended`.
- **F5 Capacity waitlist (Tier 2).** When a room is full (`VoiceRoom.isFull`), offer "Join waitlist"; on a `voiceroom:left` freeing a slot, auto-admit + push the front-of-queue user. Backend queue keyed by room id.

---

## Sequencing rationale
Reliability + perf (Phases 1-2) first — they de-risk everything downstream and fix live user pain. Then the tab reorder + discovery (Phase 3), which must ship with the index-remap fix. New features (Phase 4) last, each independently shippable; F1 (reminders) and F2 (post-room connect) are the highest-ROI and should lead Phase 4.

## Risks / mitigations
- **Tab-reorder index bug** — the highest-consequence change; must land with the identity-based remap and be tested against a live feature-flag flip while on a shifted tab.
- **Provider split (P1)** — refactoring core room state; keep behavior identical, migrate consumers incrementally, verify participant/chat/mute all still update.
- **Singleton lifecycle (R2)** — reset-on-dispose must not break the normal in-room path; verify a full join → leave → re-join cycle.
- **Backend/deploy** — F1/F3/F4/F5 + D1/D2 backend bits need deploy; client degrades (hide pill, no previews, no reminders) when absent.
