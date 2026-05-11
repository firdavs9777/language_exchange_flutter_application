# Step 8 — LiveKit migration (voice rooms + 1:1 voice/video calls)

**Date:** 2026-05-11
**Driver:** Davis
**Status:** Draft — pending one-pass review before plan generation
**Bootstrap PR commits (already merged on main):** `011f242` backend, `57fcb0f` Flutter

## Why this wave

The mesh-WebRTC stack (`webrtc_service.dart` + offer/answer/ICE-candidate signaling over socket.io) is the "headache part" the user called out. Symptoms today:

- Voice-room joins fail or take 5–10s when 4+ participants are present (mesh `O(n²)` connection growth)
- ICE-candidate exchange occasionally fails behind certain NATs, dropping participants silently
- Audio cuts in/out under bandwidth pressure (no congestion control)
- Reconnection after a mobile-network swap requires a full rejoin (no SFU-side state)
- 1:1 voice/video calls share the same mesh code path — same failure modes

The bootstrap commits proved that LiveKit Cloud connects cleanly through our backend. This wave replaces the mesh path with LiveKit for both **voice rooms** (existing feature, migration) and **1:1 calls** (existing feature, rewrite).

## Out of scope

- Self-hosted LiveKit. Stays on LiveKit Cloud for this wave.
- Recording, transcription, noise suppression. LiveKit supports them but we ship those in a later wave.
- Group video calls (3+ participants) — voice rooms already serve that need.
- Removing socket.io entirely. We still need it for chat, presence, and room chat messages.

## Out of scope, but minor improvements bundled in

Per the user's note to "add minor features and ui improvement or fixing bugs too when u plan":

1. **Speaking indicator** on participant avatars in voice rooms (LiveKit emits `isSpeaking` natively — UI was already there but read from manual RMS thresholds that mis-fire under headphones)
2. **Connection-quality badge** in 1:1 call screen (LiveKit emits `ConnectionQuality` enum: excellent/good/poor; replaces the manual ping-based estimator that overstated "poor")
3. **Auto-reconnect banner** on transient network drops (LiveKit reconnects in ~1–2s; we just need a banner during the gap instead of immediately ending the call)
4. **Room-end cleanup race fix** — current mesh code occasionally leaves `RTCPeerConnection`s alive after leave (`webrtc_service.dart:540`); LiveKit's `Room.disconnect()` handles this atomically
5. **iOS Bluetooth headset routing** — flutter_webrtc 1.4 fixes the AVAudioSession category bug we have in 1.2
6. **In-room reactions** (👏 ❤️ 🎉 via LiveKit data channels) — small new feature, ~50 lines, big delight win

## Wave shape (3 sub-waves)

Each sub-wave is independently shippable and revertable.

### Wave A — Voice Rooms migration (primary headache fix)
Drop-in replacement for the mesh path inside `voice_room_manager.dart`. UI and backend room model unchanged; only the audio transport changes.

### Wave B — 1:1 voice/video calls migration
Same idea for `call_manager.dart`. Reuses the CallKit native UI we already have; just swaps the audio/video pipe.

### Wave C — Polish + reactions + cleanup
Minor improvements 1–6 from above, plus deletion of dead mesh code once both A and B are live.

## Wave A — Voice Rooms migration

### Backend

**A1.** New `POST /api/v1/voicerooms/:id/token` endpoint
- Auth-gated (`protect`).
- Verifies the user can join (existing logic from `joinVoiceRoom`: room exists, not full, not blocked by host).
- Calls `mintRoomToken({ identity: user._id, name: user.name, roomName: room._id.toString(), metadata: { role: 'participant' | 'host' } })`.
- Returns `{ success: true, data: { token, url, roomName, role } }`.

**A2.** Keep `POST /voicerooms/:id/join` and `POST /voicerooms/:id/leave` (they update Mongo room state, presence, push notifications — orthogonal to media transport).

**A3.** Remove mesh signaling socket events for voice rooms:
- `voiceroom:offer`, `voiceroom:answer`, `voiceroom:ice-candidate` handlers in `socket/socketHandler.js` (or wherever they live — verify during implementation).
- Keep `voiceroom:joined`, `voiceroom:left`, `voiceroom:mute`, `voiceroom:hand-raised`, `voiceroom:chat`, `voiceroom:ended`, `voiceroom:host-changed`, `voiceroom:kicked` — they're business-logic events, not transport.

**A4.** Optional: LiveKit webhook receiver at `POST /api/v1/livekit/webhook`
- Verifies signature with `WebhookReceiver` from livekit-server-sdk
- Handles `room_finished` and `participant_left` to update Mongo state if a client crashes without sending `leave`
- Punt to Wave C if we want — Wave A can ship without it since clients still send explicit leave.

### Flutter

**A5.** New `lib/services/voice_room_livekit_manager.dart` (replaces mesh internals of `voice_room_manager.dart`)
- Holds a `LiveKitService` instance per active room
- Wires LiveKit events to existing callbacks (`onParticipantJoined`, `onParticipantLeft`, `onParticipantMuteChanged`, etc.) so the existing UI doesn't need to change
- Maps `LocalParticipant`/`RemoteParticipant` to `RoomParticipant` model the UI already consumes

**A6.** Rewrite `voice_room_manager.dart` to delegate transport to the new manager
- Keep socket.io for room chat, hand-raise, mute broadcast, host-changed, RSVP
- Remove all offer/answer/ICE-candidate code
- Remove `webrtc_service.dart` usage from this file

**A7.** Update `active_voice_room_screen.dart` (and any sub-widgets that read peer audio levels) to consume LiveKit's `Participant.isSpeaking` + `audioLevel` directly

**A8.** Update `voice_rooms_tab.dart` join flow to call the new token endpoint before connecting

**A9.** UI: minor improvement #1 — speaking indicator wired to LiveKit's `isSpeaking` event (replaces manual RMS threshold)

### Backend cleanup (Wave A)

**A10.** Delete or stub out `voiceroom:offer`/`:answer`/`:ice-candidate` socket handlers. Keep them as no-ops behind a `// removed in step 8 — LiveKit migration` comment for one release if we're cautious, then delete in Wave C.

## Wave B — 1:1 voice/video calls migration

### Backend

**B1.** New `POST /api/v1/calls/initiate`
- Body: `{ receiverId, type: 'audio' | 'video' }`
- Creates a `Call` record (status: `ringing`)
- `roomName = call:${callId}` (LiveKit room id derived from call id, unique per call)
- Mints LiveKit tokens for **both** caller and receiver
- Sends FCM data push to receiver with `{ type: 'incoming_call', callId, callerName, callerAvatar, callType, livekitToken, livekitUrl }`
- Returns `{ success: true, data: { call, token, url } }` to the caller
- Respects `notificationPreferences.calls` (we'll add this field if it doesn't exist yet)

**B2.** New `POST /api/v1/calls/:id/accept`
- Marks call status: `connected`, sets `connectedAt`
- Returns `{ success: true, data: { token, url } }` for the receiver to connect
- Sends socket event `call:accepted` to caller so they update UI

**B3.** New `POST /api/v1/calls/:id/decline`
- Marks status: `declined`
- Sends socket event `call:declined` to caller
- Sends silent FCM cancel to receiver (in case the ring is still going on another device)

**B4.** New `POST /api/v1/calls/:id/end`
- Marks status: `ended`, sets `endedAt`, computes `duration`
- Sends socket event `call:ended` to the other peer

**B5.** Remove mesh signaling for calls:
- `call:offer`, `call:answer`, `call:ice-candidate` socket handlers
- Keep `call:ring`, `call:accepted`, `call:declined`, `call:ended`, `call:peer-muted`, `call:peer-video-toggled`

**B6.** Keep `GET /calls/ice-servers` working for one release (clients may cache), but route to a 410-Gone after Wave C ships.

### Flutter

**B7.** New `lib/services/call_livekit_manager.dart` parallel to `voice_room_livekit_manager.dart`
- One participant on each side; auto-publish audio (and video if `type=video`)
- Wires LiveKit events to existing `CallManager` callbacks

**B8.** Rewrite `call_manager.dart`:
- Init: register FCM `incoming_call` listener; pre-warm CallKit; pre-fetch token from `/calls/:id/accept` only on user-accept
- Outgoing call: call `/calls/initiate` → receive token → connect to LiveKit → show `ActiveCallScreen`
- Incoming call: FCM-pushed payload has token → CallKit displays native ring → on accept, `POST /calls/:id/accept` (for analytics + state) then connect to LiveKit
- End: `Room.disconnect()` + `POST /calls/:id/end`
- Remove all WebRTC peer connection code from `call_manager.dart`

**B9.** Update `active_call_screen.dart`:
- Replace `RTCVideoView` with LiveKit's `VideoTrackRenderer` for both local + remote
- Replace mute toggle with `LocalParticipant.setMicrophoneEnabled`
- Replace video toggle with `LocalParticipant.setCameraEnabled`
- Replace speaker toggle with `Hardware.instance.selectAudioOutput()` (LiveKit's audio routing API)
- Minor improvement #2: connection-quality badge from `Participant.connectionQuality`
- Minor improvement #3: reconnect banner during `ReconnectingEvent` / cleared on `ReconnectedEvent`

**B10.** Update `incoming_call_screen.dart` to read FCM-pushed `livekitToken` from the call payload.

**B11.** CallKit integration unchanged (we keep `flutter_callkit_incoming` for native ring UI; only the action it triggers changes from "establish peer connection" to "join LiveKit room").

**B12.** Minor improvement #4: ensure `Room.disconnect()` is called from `dispose()` and on every end-call path. Add `IntegrationTest` smoke for accept→talk→end.

## Wave C — Polish, reactions, cleanup

**C1.** Minor improvement #6 — in-room reactions via LiveKit `DataPacket`
- Backend: nothing (P2P data channel)
- Flutter: small bottom-sheet picker (👏 ❤️ 🎉 🔥 😂 👍) in voice room; sender broadcasts; everyone shows a floating animated emoji over the sender's avatar for 2s

**C2.** Minor improvement #5 — iOS audio session category audit
- LiveKit 1.4 fixes Bluetooth headset routing; verify with airpods + a wired headset

**C3.** Delete dead mesh code:
- `webrtc_service.dart` — keep only if still used elsewhere (grep first); else delete
- Backend socket handlers stubbed in Wave A/B
- Old `GET /calls/ice-servers` endpoint (return 410 Gone or remove entirely)

**C4.** Tighten LiveKit webhook handler from A4 (graceful cleanup if client crashes mid-call)

**C5.** Telemetry — add events for `call_connected`, `call_quality_drop`, `room_joined` so we can watch the migration's effect

## Acceptance criteria

A voice room with 6 participants joins in under 3s and survives a 30s mobile→wifi switch on at least one device. A 1:1 video call between two devices completes accept→talk→end with native CallKit ring, no mesh code paths exercised, connection-quality badge present.

## Risk + rollback

- Each wave ships its own PR (3 PRs total). If Wave A regresses voice rooms, revert the PR and the mesh code is still in main behind a feature flag.
- We won't delete mesh code until Wave C, by which point both flows have shipped on Wave A/B.
- LiveKit Cloud free tier headroom: ~5,000 connection-min/mo. We exceed that only with sustained DAU > a few hundred. If we hit it, the user-funded $50/mo Build plan is one click.

## Open questions

(None — all answered in conversation. Listing here as a sanity check.)

- ~~LiveKit vs Agora?~~ → LiveKit (user picked).
- ~~Migrate voice rooms first or 1:1 calls first?~~ → Voice rooms (user called them the headache).
- ~~Self-host or Cloud?~~ → Cloud now, self-host path stays open.
- ~~Native iOS/Android call UI?~~ → Keep `flutter_callkit_incoming` for ring; LiveKit handles only the media.
