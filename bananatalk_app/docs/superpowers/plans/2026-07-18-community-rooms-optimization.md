# Community Rooms Optimization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use `- [ ]`. Exact current-code file:line lives in `.superpowers/sdd/rooms-audit-report.md` — the implementer of each task must read the cited finding there first.

**Goal:** Optimize the Community Rooms area (voice + text) across reliability, performance, discovery, and features, and move both room tabs next to Gender.

**Architecture:** Flutter/Riverpod client + Node/Express/Mongoose/socket.io/LiveKit backend (separate `../backend` repo). Ship in phases: reliability → performance → tab reorder+discovery → features.

**Tech Stack:** Flutter, Riverpod, livekit_client, socket.io; backend Express + socket.io + LiveKit + push (FCM).

## Global Constraints
- Light AND dark mode for every new/changed UI element.
- Do not regress existing voice/text room behavior; verify a full join→leave→re-join cycle after any manager/provider change.
- Backend changes go in `../backend` (confirm branch with user — default `feat/pkg1a-registration-parity`), need deploy to take effect; client must degrade gracefully when backend data/flag absent.
- Sequential execution only (shared working tree). Stage ONLY each task's own files by explicit path — never `git add -A`/`.`/`-u`; never `git stash`.
- Each finding's exact current code is in `.superpowers/sdd/rooms-audit-report.md`; read the cited section before editing.
- Commit trailer: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

---

## PHASE 1 — Reliability + critical UX

### Task 1: Surface kicked / room-ended reason (R1) + dark-mode card + dead-code (U1/U2)
**Files:** Modify `lib/pages/community/voice_rooms/voice_room_screen.dart` (ref.listen ~253-260), `lib/widgets/community/voice_room_card.dart:29`, `lib/pages/community/voice_rooms/voice_room_controls.dart:67`, `lib/pages/community/rooms/room_screen.dart:462`; Delete `lib/widgets/voice_room/room_chat_drawer.dart`.
- [ ] In the `ref.listen` that pops on `currentRoom==null`, read `next.error` and show a `CommunitySnackBar`/dialog with the reason before popping (guard so a normal self-leave with no error shows nothing).
- [ ] `VoiceRoomCard`: `color: Colors.white` → `context.containerColor`.
- [ ] Give the chat control button a label ("Chat") for parity; add `maxLines:1, overflow:ellipsis` to the hub AppBar title.
- [ ] Delete `room_chat_drawer.dart` (verify zero references first: `grep -rn RoomChatDrawer lib`).
- [ ] `flutter analyze` the changed files; manual: get kicked / host-ends-room → see reason.
- [ ] Commit.

### Task 2: Fix VoiceRoomManager singleton dispose landmine (R2)
**Files:** `lib/services/voice_room_manager.dart` (dispose ~523-536, initialize ~104-115).
- [ ] At the top of `dispose()`, reset `_isInitialized = false; _chatSocketService = null;` so a later `initialize()` re-subscribes.
- [ ] Verify join→leave→re-join re-subscribes socket listeners (participant/chat/mute/host events update after a re-join). `flutter analyze`.
- [ ] Commit.

### Task 3: Fix silent unmute failure on denied mic permission (R3)
**Files:** `lib/services/voice_room_manager.dart` (toggleMute ~436-448), `lib/services/voice_room_livekit_manager.dart:116-118`.
- [ ] `toggleMute`: `await` the `setMuted` publish; wrap `setMicrophoneEnabled` in try/catch; on failure revert `_isMuted`, call `onStateChanged`, and surface "Microphone permission needed" (reuse the app-settings deep link pattern from `chat_app_bar.dart`'s permission dialog).
- [ ] `flutter analyze`; manual (device): deny mic → unmute → see error + state stays muted.
- [ ] Commit.

### Task 4: Reconnect robustness (R4) + participant-left grace fallback (R5)
**Files:** `lib/services/voice_room_manager.dart` (reconnect signals ~117-161, 327-347; participant-left ~292-302; join ~376-379), `lib/providers/voice_room_provider.dart` (joinRoom ~171-189), `lib/pages/community/voice_rooms/voice_room_screen.dart` (initState callbacks ~64-111).
- [ ] Track `isReconnecting = socketReconnecting || liveKitReconnecting` (two internal booleans OR'd) instead of each overwriting the UI flag.
- [ ] Move all manager callback assignments (`onHostChanged`/`onForcedMuteSelf`/`onReactionReceived`) into the SAME post-frame block, BEFORE `joinRoom()`.
- [ ] Add a ~15s `.timeout(...)` to the REST+LiveKit connect in join; on timeout surface a retry/leave option instead of infinite loading.
- [ ] Participant-left: if LiveKit reports disconnect and no socket `voiceroom:left` arrives within ~6s, remove the participant anyway (timer per departing sid, cancelled if the socket event lands).
- [ ] `flutter analyze`; manual: airplane-mode toggle mid-room reconnects cleanly; a participant leaving clears within ~6s worst case.
- [ ] Commit.

---

## PHASE 2 — Performance

### Task 5: Split monolithic VoiceRoomNotifier into scoped providers/selectors (P1) + allocation churn (P2)
**Files:** `lib/providers/voice_room_provider.dart`, `lib/pages/community/voice_rooms/voice_room_screen.dart` (build ~248, sorted ~233-243), `voice_room_participants_grid.dart`, `voice_room_chat_panel.dart:46`, `lib/services/voice_room_manager.dart:98`.
- [ ] Introduce narrower selectors so active-speaker churn doesn't rebuild the whole screen: expose `participants`, `chatMessages`, and local mute/hand state such that the participants grid, chat panel, and controls each rebuild only on their own slice (Riverpod `select`, or per-tile `Consumer`/`Selector` keyed to one participant's fields).
- [ ] Memoize the sorted participants list; only recompute when membership/flags change (not every build). Stop allocating a fresh `List.unmodifiable` on every `participants` access when unchanged.
- [ ] Keep behavior identical — verify chat, mute, hand-raise, join/leave, active-speaker ring all still update. `flutter analyze`.
- [ ] Commit.

### Task 6: Avatar cache sizing + tab keep-alive (P3)
**Files:** `voice_room_participant_tile.dart:80-85`, `lib/widgets/community/voice_room_card.dart` (~213-218, 264-271), `lib/pages/community/voice_rooms/voice_rooms_tab.dart`, `lib/pages/community/rooms/rooms_directory_screen.dart`.
- [ ] Add device-pixel-aware `cacheWidth`/`cacheHeight` to participant + room-card avatars (or route through the app's cached-image widget if one exists — check `CachedImageWidget`).
- [ ] Opt `VoiceRoomsTab` and the Rooms directory into `AutomaticKeepAliveClientMixin` so swiping away/back doesn't refetch + skeleton-flash (call `super.build(context)`).
- [ ] `flutter analyze`; manual: swipe away from Voice Rooms and back → no reload flash.
- [ ] Commit.

---

## PHASE 3 — Tab reorder + discovery

### Task 7: Move BOTH room tabs next to Gender with identity-safe flag remap (T1) — HIGHEST-CONSEQUENCE
**Files:** `lib/pages/community/main/community_tab_bar.dart` (tab list 61-173), `lib/pages/community/main/community_main.dart` (TabBarView children 261-291, `_syncTabCountWithRoomsFlag` 68-84, `_baseTabCount` 40, `_partnersTabIndex` 43).
Target order: All(0) → Gender(1) → Voice Rooms(2) → Rooms(3, conditional) → Nearby → City → Topics → Waves.
- [ ] Move the Voice Rooms `Tab` and the conditional `if(showRoomsTab) Rooms Tab` to sit right after Gender in `community_tab_bar.dart`.
- [ ] Move the matching `TabBarView` children (`VoiceRoomsTab`, `if(roomsEnabled) RoomsDirectoryScreen`) to the IDENTICAL relative order in `community_main.dart`. (Both lists must match exactly or labels/pages desync.)
- [ ] **Identity-safe remap:** rewrite `_syncTabCountWithRoomsFlag` so on the flag flip it shifts `previousIndex` by the Rooms insertion index: when enabling, `if (previousIndex >= roomsInsertionIndex) previousIndex += 1`; when disabling, `if (previousIndex > roomsInsertionIndex) previousIndex -= 1`. Define `roomsInsertionIndex` as Rooms' new position (3).
- [ ] Write a unit test for the remap math (pure function extracted): enabling with previousIndex at/after insertion shifts +1; disabling shifts -1; before-insertion unchanged.
- [ ] Grep for any other hardcoded community tab index (`grep -rn "tabController.index ==" lib/pages/community`); re-verify `_partnersTabIndex`/`_baseTabCount`.
- [ ] `flutter analyze` + run the remap test; manual: toggle rooms flag while sitting on Nearby → visible tab does NOT swap.
- [ ] Commit.

### Task 8: "N live now" pill in Community app bar (D1)
**Files:** Modify `lib/pages/community/main/community_app_bar.dart` (~47-114); new `activeVoiceRoomCountProvider` (in `lib/providers/voice_room_provider.dart` or a small new file); optional backend `GET /voicerooms/count`.
- [ ] Add a light provider for the count of currently-live voice rooms (reuse `fetchRooms()` length, or a cheap count endpoint; poll ~30s while Community is visible).
- [ ] Render a compact pill next to NotificationBell/CoinBalancePill, hidden when count==0, tap → switch to the Voice Rooms tab.
- [ ] `flutter analyze`; manual both themes. Commit.

### Task 9: Room previews + who's-talking (D2) + Rooms directory language filter (D3)
**Files:** `lib/models/room.dart` (Room.fromJson), `lib/pages/community/rooms/room_card.dart`, `lib/widgets/community/voice_room_card.dart`, `lib/pages/community/rooms/rooms_directory_screen.dart`; backend `GET /rooms` serializer (recentMembers + lastMessage), voice room list refresh.
- [ ] `RoomCard`: show 2-3 recent-member avatars + one-line last-message snippet (add `recentMembers`/`lastMessage` to `Room` + backend `GET /rooms` payload; degrade if absent).
- [ ] `VoiceRoomCard`: animated "speaking" dot on the active participant (data already in `RoomParticipant.isSpeaking`); add a ~15-20s list refresh while the Voice Rooms tab is visible.
- [ ] Rooms directory: language filter/sort defaulting to the user's target language(s), mirroring Voice Rooms filter chips.
- [ ] `flutter analyze`; manual both themes. Commit (client and backend as separate commits in their repos).

---

## PHASE 4 — New features (Tier 1 + Tier 2)

### Task 10: Scheduled-room push reminders (F1) — Tier 1, highest ROI
**Files:** Backend: scheduled job + push fan-out for rooms with `scheduledFor` in next N min to RSVP'd users; new notification type `voiceroom_reminder`. Client: `lib/services/notification_router.dart` (route `voiceroom_reminder` → fetch room by id → `VoiceRoomScreen`).
- [ ] Backend: cron/interval job queries upcoming scheduled rooms + RSVPs, sends push (reuse existing FCM infra) with `{type:'voiceroom_reminder', roomId}`; avoid duplicate sends (mark reminded).
- [ ] Client: add the `voiceroom_reminder` case to `NotificationRouter.handleNotification` → navigate into the voice room.
- [ ] Verify deep link opens the room; `node --check` backend. Commit (both repos).

### Task 11: Post-room "connect with who you talked to" prompt (F2) — Tier 1
**Files:** `lib/pages/community/voice_rooms/voice_room_screen.dart` (_leaveRoom ~193-231); reuse the Waves/follow flow.
- [ ] On `_leaveRoom()` success, show a sheet listing other participants (from the known `participants` list) with one-tap "Add partner"/"Send wave" (reuse existing endpoints). Skip if solo/no others.
- [ ] `flutter analyze`; manual. Commit.

### Task 12: Co-host / promote-to-speaker (F3) — Tier 2
**Files:** `lib/models/community/voice_room_model.dart` (add `role` enum host/cohost/speaker/listener), `voice_room_participant_actions.dart` (host menu), `lib/services/voice_room_manager.dart` (new socket events mirroring kick/mute-all ~481-492); backend socket handlers `voiceroom:promote` / `voiceroom:invite-to-speak`.
- [ ] Add `role` to `RoomParticipant` + parse; host menu gains "Make co-host" and "Invite to speak" (for hand-raised).
- [ ] Client emits + handles the new socket events; backend authorizes (host/cohost only) and fans out. Reflect role in the participant tile badge.
- [ ] `flutter analyze` + `node --check`; manual with 2 accounts. Commit (both repos).

### Task 13: Trending/recommended rooms (F4) — Tier 2
**Files:** Backend `GET /voicerooms/recommended` (rank by target-language/topic match + participant count); client `voice_rooms_tab.dart` (~337-418) adds a "Recommended for you" row above the list.
- [ ] Backend ranking endpoint. Client: `SliverToBoxAdapter` recommended row (hide when empty), reuse `VoiceRoomCard`.
- [ ] `flutter analyze` + `node --check`. Commit (both repos).

### Task 14: Capacity waitlist (F5) — Tier 2
**Files:** Backend queue per room id + on `voiceroom:left` for a full room pop+notify front-of-queue; client `voice_room_card.dart` (~298-350) "Join waitlist" when `isFull`, plus the auto-admit push handling.
- [ ] Backend waitlist + targeted push/socket on slot free. Client: waitlist button + handle admit notification (deep link into the room).
- [ ] `flutter analyze` + `node --check`; manual. Commit (both repos).

---

## Self-Review notes
- Spec coverage: Phase1 R1-R5/U1-U2 → Tasks 1-4; Phase2 P1-P3 → Tasks 5-6; Phase3 T1/D1-D3 → Tasks 7-9; Phase4 F1-F5 → Tasks 10-14. All spec items covered.
- Highest-risk task (7, tab reorder) isolated with a unit-tested pure remap function and an explicit manual flag-flip check.
- Backend-dependent tasks (9,10,12,13,14) each note client graceful-degradation when the backend piece isn't deployed.
- Detailed current code for every finding: `.superpowers/sdd/rooms-audit-report.md`.
