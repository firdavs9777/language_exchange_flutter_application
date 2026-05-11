# Voice Rooms + Calls — Pre-Deploy Smoothness Pass

**Date:** 2026-05-12
**Scope:** Functional bugs + smoothness polish across voice rooms and 1:1 audio/video calls, ahead of today's deploy. Out of scope: refactors, new features, CallKit native reconfiguration, LiveKit SDK upgrades.

## Goal

Both subsystems should feel *clean*: when something ends, every participant cleans up at the same time, with explicit feedback. No silent failures, no flicker, no zombie LiveKit sessions, no dropped sender names.

## Approach (chosen)

**Hybrid backend + frontend pass.**

- Add a thin LiveKit *admin* layer to the backend (`RoomServiceClient` from `livekit-server-sdk`) so the server can force a LiveKit room closed when a voice room or call ends. Without this, peers that miss the socket event stay audible until they each disconnect — the failure mode you observed as "peers don't get kicked".
- Everything else is a frontend fix, a payload shape fix, or a tighter socket emit scope.

Rejected:
- **Pure frontend** (rely on every client to honor `voiceroom:ended`): leaves the zombie-LiveKit failure mode.
- **Pure backend** (force-disconnect every participant via admin SDK only): doesn't fix the UI smoothness items (modal, stale snapshot, host-changed feedback).

## Architecture changes

Two new pieces, both small:

1. `backend/services/livekitAdminService.js` — wraps `RoomServiceClient` with two methods: `endRoom(roomName)` and `disconnectParticipant(roomName, identity)`. Used only from `endVoiceRoom`, `endCall`, and the voice-room kick handler. Fails open: if LiveKit admin call errors, log and proceed (the Mongo state change + socket emits still happen).
2. `lib/widgets/voice_room/room_ended_modal.dart` — reusable `showRoomEndedModal(context, reason)` that displays the "Room ended by host" / "Call ended" modal with an OK button. Single component reused by both subsystems.

No other architectural changes.

## §1 — Voice room host-ends flow

### Fixes

**1.1 Force LiveKit room closed on `/voicerooms/:id/end`.**

In `backend/controllers/voiceRooms.js#endVoiceRoom`, after `room.end()` and before/after the socket emits, call `livekitAdminService.endRoom(roomName)`. The LiveKit room name is the voice room's `_id` (matches `voicerooms/:id/token` mint). This force-disconnects every participant at the transport layer — they can no longer hear each other regardless of socket delivery.

**1.2 Suppress host-transfer grace timer when host explicitly ends.**

In `lib/services/voice_room_manager.dart#endRoom`, *await* the `/end` POST instead of fire-and-forget, **before** disconnecting LiveKit. New order:

```
1. emit 'voiceroom:end-intent' on the socket (instant; tells backend "ignore my upcoming disconnect")
2. await POST /voicerooms/:id/end
3. (backend marks ended + force-closes LiveKit)
4. cleanup local state
```

Backend `voiceRoomHandler.js` adds a `voiceroom:end-intent` listener that sets a per-user flag (`hostEndingRooms: Set<string>`); the `disconnect` handler checks this and skips `scheduleHostTransfer` for that user+room. The flag is cleared on next connect or after 60s TTL.

If step 2 fails (network/500), surface the error to the host as a snackbar ("Couldn't end room — try again") and leave local state intact so they can retry. No partial-state UI.

**1.3 Scope the global `voiceroom:ended` emit.**

In `endVoiceRoom`, replace the bare `io.emit('voiceroom:ended', ...)` with `io.to('voicerooms:lobby').emit(...)`. The `socket/voiceRoomHandler.js` subscribes every connected socket to `voicerooms:lobby` on connect (so the rooms-list screen still gets the broadcast). Participants already in `voiceroom_${roomId}` get the room-channel emit unchanged.

**1.4 "Room ended by host" modal for peers.**

Frontend `voice_room_provider.dart#onRoomEnded` already sets `error: 'Room ended by host'`. Wire `voice_room_screen.dart` to:
- Detect the transition (currentRoom was set → now null with `error` set)
- Show `RoomEndedModal(reason: error)` *before* popping
- Pop on modal dismiss (OK button)

Replaces the current "auto-pop via ref.listen" path. Keep the auto-pop as a fallback for `onKicked` (kick gets its own different modal text: "Removed by host").

**1.5 Host-side spinner during `/end`.**

While the POST is in flight in `endRoom()`, the End-room confirmation dialog stays open with its button replaced by a `CircularProgressIndicator`. On success, dismiss and pop the room screen. On failure, dismiss the spinner and show the snackbar from 1.2.

## §2 — Voice room everyday flow

### Fixes

**2.1 `VoiceRoomHeader` consumes live state.**

In `voice_room_screen.dart`, build `VoiceRoomHeader` from `voiceRoom.currentRoom ?? widget.room` so post-promotion host name / title updates render. Same change for any other widget that captures `widget.room` directly — audit the file.

**2.2 De-duplicate room-ended + rejoin-ack race.**

In `voice_room_manager.dart#_setupConnectionListener`, when the rejoin ack returns `{ok: false, ended: true}`, set a transient `_handlingEnd` flag for 1s. The `_chatSocketService!.onVoiceRoomEnded.listen` callback checks this flag and skips if set. Prevents the double-pop you saw.

**2.3 Hand-raise event carries `isRaised`.**

Backend `voiceRoomHandler.js#voiceroom:raise_hand` currently emits `{roomId, user}` with no flag — frontend has to toggle from local state, which means desync if two clients toggle simultaneously. Add an `isRaised` boolean to the emit payload. The handler tracks it from the incoming socket event (clients send `{roomId, isRaised}` already in `toggleHandRaised`, just unused server-side).

**2.4 Friendly error when joining ended room.**

Frontend `voice_room_provider.dart#joinRoom` already catches errors; add a specific check for status 410/404 with body indicating ended → show snackbar "This room has ended" and pop. Backend `getVoiceRoom`/`joinVoiceRoom` returns 410 when `status === 'ended'`.

**2.5 Verify the post-rebuild fixes.**

Manual verification after the full rebuild (not hot reload):
- Event names: `voiceroom:user_joined` / `voiceroom:user_left` / `voiceroom:hand_raised` deliver
- `VoiceRoomChatMessage.fromJson` reads nested `user` object
- `setMicrophoneEnabled` with `stopAudioCaptureOnMute: false` keeps audio session in PlayAndRecord on mute toggle

## §3 — 1:1 calls

### Fixes

**3.1 Auto-busy when call:incoming arrives during active call.**

In `call_manager.dart#_handleIncomingSocketEvent`, replace the silent `if (currentCall != null) return` with: parse the incoming call ID, POST `calls/:incomingId/decline?reason=busy`, then return. Backend records reason=busy; caller sees `call:declined` and stops ringback immediately instead of waiting 45s.

**3.2 Idempotent `endCall` against CallKit double-fire.**

Add an `_endCallInFlight` flag at the top of `endCall()`. If true, return immediately. Set it before the POST, clear it in `_cleanup`. Also guard `rejectCall` similarly. Eliminates the "double `onCallEnded` fired" risk when CallKit's `onEnded` races with the user tapping End in-app.

**3.3 Force-close call's LiveKit room on `endCall` controller.**

Same pattern as 1.1: in `backend/controllers/callController.js#endCall`, after `call.save()` call `livekitAdminService.endRoom(_roomNameForCall(call._id))`. Ensures both peers' LiveKit transports drop even if one side missed `call:ended`.

**3.4 "Call ended" modal — same component as §1.4.**

In `active_call_screen.dart`, when `_callEnded` flips true (currently triggers a 1s delay then `Navigator.pop`), instead show `showRoomEndedModal(context, reason: 'Call ended')` — pop on OK. Reuses the §1 component, same UX.

**3.5 acceptCall failure no longer POSTs /decline.**

In `call_manager.dart#acceptCall`, replace the `rejectCall()` calls on failure paths with a local-only cleanup (`_cleanup()`) — backend will see the timeout instead of getting a noisy 409. The original purpose (notify the caller) is moot because the caller already has the call as `ringing` and will see it timeout.

**3.6 Caller's 45s timeout posts `/end` instead of just stopping locally.**

`_callTimeoutTimer` currently fires `onCallTimeout?.call()` + `endCall()`. Verify the `endCall` path actually hits the backend — if not, callee's CallKit will keep ringing. (Reading the code, `endCall` does POST `/end`, so this should already work — flag for verification only.)

## Component contracts

### `RoomEndedModal` (new)

```dart
Future<void> showRoomEndedModal(
  BuildContext context, {
  required String reason,        // "Room ended by host", "Call ended", "Removed by host"
  String? subtitle,              // optional, e.g. duration
});
```

- Material `AlertDialog`, single OK button
- Resolves when OK tapped or dialog dismissed
- Not dismissible by tap-outside (it's an explicit acknowledgement)

### `livekitAdminService` (new, backend)

```js
// backend/services/livekitAdminService.js
async function endRoom(roomName) {
  // No-throw: log and swallow if LiveKit unreachable.
}
async function disconnectParticipant(roomName, identity) {
  // No-throw.
}
module.exports = { endRoom, disconnectParticipant };
```

Implemented over `RoomServiceClient` from `livekit-server-sdk` (already a dependency for token minting).

### `voiceroom:end-intent` (new socket event)

Client → server, one-shot.
Payload: `{ roomId: string }`
Server: marks `hostEndingRooms.add(`${userId}:${roomId}`)`, TTL 60s. Used by `disconnect` handler to skip the host-transfer grace timer.

## Testing

Manual (deploy-day budget):

- **§1 host ends:** A hosts, B joins → A taps End → A sees spinner → both A and B see "Room ended by host" modal → both transports disconnected (verify in LiveKit Cloud dashboard if accessible, else verify B's audio is gone)
- **§1 race:** A hosts, B joins → kill A's network → wait 5s → A taps End → confirm peer flicker is gone
- **§2 hand raise:** A and B both raise hand → both see crown icons → both lower → both see icons removed
- **§2 stale state:** A hosts → A leaves (transfers to B) → B's title bar shows B as host (not A)
- **§3 busy:** A on call with B → C tries to call A → C immediately sees "declined"
- **§3 call end:** A calls B → B answers → either side ends → both see "Call ended" modal

## Files touched (estimate)

**Frontend:**
- `lib/services/voice_room_manager.dart` (1.2, 2.2)
- `lib/services/call_manager.dart` (3.1, 3.2, 3.5)
- `lib/pages/community/voice_rooms/voice_room_screen.dart` (1.4, 1.5, 2.1, 2.4)
- `lib/pages/community/voice_rooms/voice_room_host_menu.dart` (1.5)
- `lib/screens/active_call_screen.dart` (3.4)
- `lib/widgets/voice_room/room_ended_modal.dart` (NEW)
- `lib/providers/voice_room_provider.dart` (2.4)
- `lib/services/chat_socket_service.dart` (verify event names from prior fix)

**Backend:**
- `backend/services/livekitAdminService.js` (NEW)
- `backend/controllers/voiceRooms.js` (1.1, 1.3, 2.4)
- `backend/controllers/callController.js` (3.3)
- `backend/socket/voiceRoomHandler.js` (1.2, 2.3)

## Risk

- LiveKit admin API errors must NOT block room/call end. The fail-open design (log + continue) in `livekitAdminService` handles this.
- `voiceroom:end-intent` is a new wire event. Old clients won't emit it → fall back to current grace-timer behavior, which is the status quo. Backward compatible.
- The `voicerooms:lobby` socket room must be joined on every connect, including reconnects. Add to the post-auth join sequence in `socket/index.js` or wherever sockets initially join `user_<id>`.

## Non-goals

- Replacing CallKit / Android foreground service plumbing
- Rewriting any LiveKit transport code
- Audio session category management beyond what's already patched
- Multi-party calls (1:1 only)
- Migration off `device_info_plus 12.4.0` (the local patch stays)
