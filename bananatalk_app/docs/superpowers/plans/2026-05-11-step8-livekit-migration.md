# Step 8 — LiveKit migration: implementation plan

**Spec:** `docs/superpowers/specs/2026-05-11-step8-livekit-migration-design.md`
**Bootstrap commits already on main:** `011f242` backend, `57fcb0f` Flutter, `77408c8` spec
**Branch:** `feat/step8-livekit-migration` (cut from main)
**Repos:** Flutter (`bananatalk_app`) + Backend (`language_exchange_backend_application`) — each task notes which repo(s) it touches.

## Conventions

- One commit per task. Commit subject: `feat(livekit): <task-id> — <one-line summary>`
- Backend commits go in the backend repo with the same task id.
- After each Wave (A, B, C) → spec-compliance reviewer pass + code-quality reviewer pass, dispatched in parallel.
- After all three waves merged → tag `v1.4.0-livekit` on Flutter and ship.
\=
---

## Wave A — Voice Rooms migration

### A1 — Backend: token endpoint for voice rooms
**Repo:** backend
**Files:** `controllers/voiceRooms.js`, `routes/voiceRooms.js`
- Add `getVoiceRoomToken(req, res)` controller. Re-use the access check from `joinVoiceRoom` (room exists, status=active, not full, not blocked).
- Mint token with `livekitService.mintRoomToken({ identity: req.user._id, name: req.user.name, roomName: room._id.toString(), metadata: { role } })`.
- `role` is `'host'` if `room.host.toString() === req.user._id.toString()`, else `'participant'`.
- Route: `POST /api/v1/voicerooms/:id/token` (auth-gated).
- Response: `{ success: true, data: { token, url, roomName, role } }`.
**Verify:** curl with two different users on the same room id returns two distinct JWTs.

### A2 — Flutter: voice_room_livekit_manager.dart
**Repo:** Flutter
**Files:** `lib/services/voice_room_livekit_manager.dart` (new), no changes to others in this task
- Class `VoiceRoomLiveKitManager` wraps `LiveKitService`.
- `Future<void> connect({ required String roomId })` → calls `ApiClient().post('voicerooms/$roomId/token')` → connects to LiveKit.
- Exposes callbacks: `onParticipantJoined(RoomParticipant)`, `onParticipantLeft(String userId)`, `onParticipantSpeakingChanged(String userId, bool isSpeaking)`, `onParticipantMuteChanged(String userId, bool isMuted)`, `onRoomReconnecting()`, `onRoomReconnected()`, `onRoomDisconnected()`.
- Maps LiveKit `Participant.identity` ↔ our `RoomParticipant.userId` (they're the same Mongo `_id`).
- Helper `RoomParticipant _toRoomParticipant(Participant p)` that derives display fields from `p.metadata` (host role) and live track state.
**Verify:** unit-level smoke — wire up against the bootstrap test screen, confirm callbacks fire on join/leave.

### A3 — Flutter: rewrite voice_room_manager.dart to delegate transport
**Repo:** Flutter
**Files:** `lib/services/voice_room_manager.dart`
- Replace `_webrtcService` field with `VoiceRoomLiveKitManager _liveKit`.
- Remove all `_offerSub`, `_answerSub`, `_iceCandidateSub` subscriptions and their handlers.
- Remove `_setupSocketListeners` mesh signaling cases.
- `joinRoom(VoiceRoom room)` now calls `_liveKit.connect(roomId: room.id)` *and* `POST /voicerooms/:id/join` (Mongo state) in parallel.
- `leaveRoom()` calls `_liveKit.disconnect()` + `POST /voicerooms/:id/leave`.
- `toggleMute()` delegates to `_liveKit.setMicrophoneEnabled(!isMuted)`. Still broadcasts `voiceroom:mute` socket event so UI on other clients updates immediately (LiveKit also surfaces this via `TrackMutedEvent` ~100ms later — keep socket for UI snappiness).
- Wire `_liveKit.onParticipantJoined/Left/SpeakingChanged` to existing callbacks consumed by the UI.
- Keep socket.io subscriptions for chat, hand-raise broadcast, host-changed, kicked, room-ended (business events).
**Verify:** `flutter analyze lib/services/voice_room_manager.dart` clean. Compile.

### A4 — Flutter: rooms tab + active room screen updates
**Repo:** Flutter
**Files:** `lib/pages/community/widgets/voice_rooms_tab.dart`, `lib/pages/community/active_voice_room_screen.dart`
- Voice rooms tab: nothing changes for the list view; the join handler already calls `voiceRoomManager.joinRoom()` which now does the right thing.
- Active room screen: remove any `RTCVideoView` or direct `flutter_webrtc` usage (voice rooms are audio-only so this is mostly imports + dead helpers).
- Bind speaking indicator on participant avatars to the new `onParticipantSpeakingChanged` callback (replaces the manual RMS threshold in `_onAudioLevel`).
**Verify:** open a room, see your own avatar speaking indicator light up when you talk; mute it and it stops.

### A5 — Flutter: speaking indicator polish (minor improvement #1)
**Repo:** Flutter
**Files:** `lib/widgets/voice_room/participant_avatar.dart` (or wherever the avatar lives — verify path)
- Replace `_speakingThreshold` RMS comparison with the boolean from `onParticipantSpeakingChanged`.
- Use a Material 3 green ring around the avatar (1.5dp), fading in/out with a 150ms `AnimatedContainer`.
- Delete the now-unused audio-level stream wiring through `voice_room_manager`.
**Verify:** visual — looks good on two devices; doesn't false-fire on headphone hiss.

### A6 — Backend: stub mesh signaling socket events
**Repo:** backend
**Files:** `socket/socketHandler.js` (or wherever voiceroom socket events are wired — search and confirm)
- Remove `socket.on('voiceroom:offer', ...)`, `voiceroom:answer`, `voiceroom:ice-candidate` handlers. Replace with a single `socket.onAny((event) => ...)` log warning if a client still emits them (to catch stragglers in telemetry).
- Keep all business-logic events (joined, left, mute, hand-raised, chat, ended, host-changed, kicked).
**Verify:** node server boots; no clients hit the warning log after Flutter A3 ships.

### Wave A review gate
- Two reviewers dispatched in parallel:
  1. **spec-compliance reviewer** — verify A1-A6 match the spec
  2. **code-quality reviewer** — voice_room_livekit_manager + rewritten voice_room_manager
- Surface findings, fix in follow-up commits (not amends per project rule), then proceed to Wave B.

---

## Wave B — 1:1 voice/video calls migration

### B1 — Backend: call lifecycle endpoints + token minting
**Repo:** backend
**Files:** `controllers/callController.js`, `routes/calls.js`, `services/callService.js`, `services/notificationService.js`
- `POST /calls/initiate` — body `{ receiverId, type }`. Creates Call (status=ringing), generates `roomName = 'call:' + callId`. Mints token for caller. Sends FCM data push to receiver with `{ type: 'incoming_call', callId, callerName, callerAvatar, callType, livekitToken: <receiverToken>, livekitUrl }`. Returns `{ data: { call, token, url } }`. Gate by `notificationPreferences.calls`.
- `POST /calls/:id/accept` — set status=connected, connectedAt=now. Returns `{ data: { token, url } }` for receiver. Socket emit `call:accepted` to caller.
- `POST /calls/:id/decline` — set status=declined. Socket emit `call:declined` to caller. Send silent FCM cancel to receiver's other devices.
- `POST /calls/:id/end` — set status=ended, endedAt, duration. Socket emit `call:ended` to both peers.
- **Add field** `notificationPreferences.calls: Boolean` to User model with default true (matches the pattern from C7 of Step 2).
**Verify:** curl-test all four endpoints with two test users.

### B2 — Flutter: call_livekit_manager.dart
**Repo:** Flutter
**Files:** `lib/services/call_livekit_manager.dart` (new)
- Class `CallLiveKitManager` (parallel structure to `VoiceRoomLiveKitManager`).
- `connect({ required String url, required String token, required CallType type })` → join LiveKit room, auto-publish audio, publish video if `type == video`.
- Callbacks: `onPeerConnected()`, `onPeerDisconnected()`, `onPeerMuteChanged(bool)`, `onPeerVideoChanged(bool)`, `onConnectionQualityChanged(ConnectionQuality)`, `onReconnecting()`, `onReconnected()`.
- Single remote peer (1:1) — guard for the n=1 case.
**Verify:** wired against the smoke-test screen with `type=video`, two devices see each other's video.

### B3 — Flutter: rewrite call_manager.dart to use LiveKit
**Repo:** Flutter
**Files:** `lib/services/call_manager.dart`
- Replace `_webrtcService` with `_liveKit: CallLiveKitManager`.
- Remove all mesh peer connection / offer / answer / ICE-candidate code.
- Outgoing call: `POST /calls/initiate` → receive token → `_liveKit.connect(url, token, type)` → push `ActiveCallScreen`.
- Incoming call: FCM payload has `livekitToken` + `livekitUrl`. CallKit shows ring. On accept → `POST /calls/:id/accept` (state) then `_liveKit.connect(url, token, type)`. On decline → `POST /calls/:id/decline` and dismiss CallKit.
- End call: `_liveKit.disconnect()` + `POST /calls/:id/end`.
- Remove `_socket.on('call:offer', ...)` etc. Keep `call:accepted`, `call:declined`, `call:ended`, `call:peer-muted`, `call:peer-video-toggled`.
**Verify:** make outgoing + accept incoming on a second device. End on either side cleans up everything.

### B4 — Flutter: active_call_screen.dart — LiveKit renderers + minor improvements
**Repo:** Flutter
**Files:** `lib/screens/active_call_screen.dart`
- Replace `RTCVideoView(localRenderer)` with `VideoTrackRenderer(localTrack)`; same for remote.
- Mute toggle → `LocalParticipant.setMicrophoneEnabled`.
- Video toggle → `LocalParticipant.setCameraEnabled`.
- Speaker toggle → `Hardware.instance.setSpeakerphoneOn(bool)`.
- **Minor improvement #2:** connection-quality badge (top-right) — small icon mapping `ConnectionQuality.excellent → green dot`, `good → yellow`, `poor → orange triangle`.
- **Minor improvement #3:** reconnect banner — full-width yellow strip at top "Reconnecting…" shown while `_liveKit.onReconnecting` true; auto-hide on `onReconnected`. If reconnect doesn't succeed in 15s → end the call with reason "connection lost".
**Verify:** kill wifi mid-call on one device — see banner appear then call survives the switch to mobile.

### B5 — Flutter: incoming_call_screen.dart — FCM-pushed token
**Repo:** Flutter
**Files:** `lib/screens/incoming_call_screen.dart`
- Read `livekitToken` and `livekitUrl` from the FCM call payload (now part of `CallModel.fromFcmPayload`).
- On accept tap: pass token directly to `CallManager.acceptCall(call)` (which handles the connect).
- On decline tap: `CallManager.declineCall(call)`.
**Verify:** receive an incoming call → screen shows caller info, both buttons work.

### B6 — Backend: stub mesh call signaling
**Repo:** backend
**Files:** `socket/socketHandler.js`
- Remove `call:offer`, `call:answer`, `call:ice-candidate` handlers. Same `onAny` warning pattern as A6.
- Mark `GET /api/v1/calls/ice-servers` as deprecated in code comment; we'll remove in Wave C after one release.
**Verify:** server boots; no warning logs from clients after Wave B ships.

### Wave B review gate
- Same two-reviewer pattern (spec compliance + code quality).

---

## Wave C — Polish, reactions, cleanup

### C1 — Flutter: in-room reactions via data channel (minor improvement #6)
**Repo:** Flutter
**Files:** `lib/widgets/voice_room/reaction_picker.dart` (new), `lib/widgets/voice_room/floating_reaction.dart` (new), `lib/services/voice_room_livekit_manager.dart` (extend)
- Bottom-sheet picker with 6 emojis: 👏 ❤️ 🎉 🔥 😂 👍
- `VoiceRoomLiveKitManager.sendReaction(String emoji)` → `room.localParticipant.publishData(utf8.encode(jsonEncode({type: 'reaction', emoji})))`
- Listen `DataReceivedEvent` → if `type == 'reaction'`, emit `onReactionReceived(participantId, emoji)`.
- `FloatingReaction` widget — animated emoji that fades up and out over 2s, anchored at the sender's avatar.
**Verify:** two devices, tap a reaction, animation plays on both.

### C2 — Flutter: iOS audio session audit (minor improvement #5)
**Repo:** Flutter
**Files:** `lib/services/livekit_service.dart`, `ios/Runner/Info.plist` (verify), `ios/Podfile` (verify)
- Confirm flutter_webrtc 1.4 fixes the Bluetooth headset routing issue.
- If `audio_session` package still needed, configure `AVAudioSessionCategoryPlayAndRecord` with `.allowBluetooth | .allowBluetoothA2DP` options.
- Test matrix: wired headset, AirPods, AirPods Pro, speakerphone, earpiece — all should route correctly.
**Verify:** manual run-through on a physical iOS device for each headset type.

### C3 — Backend + Flutter: delete dead mesh code
**Repo:** both
**Files:** Flutter — `lib/services/webrtc_service.dart`; backend — `controllers/callController.js` (`getIceServers`), `routes/calls.js` (`GET /ice-servers`), socket handlers stubbed in A6/B6.
- `grep -r flutter_webrtc lib/ --include="*.dart"` — any remaining import after Wave A+B is dead code.
- Delete `webrtc_service.dart` entirely if no remaining importers.
- Remove `/calls/ice-servers` endpoint (or return 410 Gone).
- Remove the `onAny` warning stubs from A6/B6 if no client warnings have fired in production for 1 week (else keep one more release).
**Verify:** flutter analyze still clean; backend tests pass.

### C4 — Backend: LiveKit webhook receiver
**Repo:** backend
**Files:** `routes/livekit.js`, `controllers/livekit.js`
- `POST /api/v1/livekit/webhook` — verify signature with `new WebhookReceiver(apiKey, apiSecret)`.
- Handle events:
  - `room_finished` → update Mongo `VoiceRoom.status = 'ended'` if not already
  - `participant_left` → remove from `VoiceRoom.participants` if still present (handles client crashes)
  - `participant_joined` → optional analytics
- Register webhook URL in LiveKit Cloud dashboard.
**Verify:** kill a Flutter app mid-voice-room → backend cleans up the participant within 30s.

### C5 — Both: telemetry events
**Repo:** both
**Files:** Flutter — `lib/services/livekit_service.dart` + analytics hooks; backend — controllers
- Emit events: `call_initiated`, `call_connected`, `call_quality_drop`, `call_ended`, `room_joined`, `room_left`, `room_reaction_sent`.
- Send to whatever analytics pipeline already exists (verify during implementation).
**Verify:** events show up in the analytics dashboard.

### C6 — Final: branch finishing
**Repo:** both
- Run full `flutter analyze` and backend tests on both repos.
- Open PRs:
  - Flutter: `feat: Step 8 — LiveKit migration (voice rooms + 1:1 calls)`
  - Backend: `feat: Step 8 — LiveKit migration endpoints + cleanup`
- Cross-link the two PRs in their descriptions.
- After merge, tag Flutter `v1.4.0-livekit`.

### Wave C review gate
Final spec-compliance + code-quality reviewer pass, then merge.

---

## Cadence guidance for the executor

- Drive A1 → A6 in order; each is a clean revert. Don't start A3 until A1 + A2 are committed (A3 needs the new manager class).
- B1 can start in parallel with A6 once A1-A5 are green.
- Wave C tasks are mostly independent and parallelizable.
- Don't pause between tasks for confirmation — that's the user's standing preference. Surface only at end-of-wave review gates or genuine blockers.
- If a backend change is needed mid-Flutter-task, do the backend commit first (same task id), then the Flutter commit.

## Estimated commit count
- Wave A: 6 commits (+ ~2 review-fix commits expected) = ~8
- Wave B: 6 commits (+ ~2 review-fix commits expected) = ~8
- Wave C: 6 commits = ~6
- **Total: ~22 commits across both repos**
