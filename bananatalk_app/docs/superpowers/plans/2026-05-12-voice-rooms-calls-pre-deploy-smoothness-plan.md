# Voice Rooms + Calls — Pre-Deploy Smoothness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the failure modes the user observed when a voice-room host ends the room (zombie LiveKit sessions, host-transfer flicker, no peer feedback) and apply the parallel cleanup to 1:1 calls. Ship today.

**Architecture:** Hybrid — backend gains a thin LiveKit admin layer to force-close rooms server-side (using `livekit-server-sdk`'s `RoomServiceClient`, already on the dependency tree). Everything else is a frontend payload/UX fix or a tighter socket-emit scope. One new shared modal widget is reused by both subsystems.

**Tech Stack:** Flutter + Riverpod (frontend), Node.js + Express + Socket.io (backend), LiveKit Cloud (transport), `livekit_client ^2.7.0` (Flutter), `livekit-server-sdk` (Node).

**Spec:** `docs/superpowers/specs/2026-05-12-voice-rooms-calls-pre-deploy-smoothness-design.md`

**Testing note:** This is integration-heavy work over real sockets, real LiveKit Cloud, and CallKit. Unit tests would mock so much of the behavior that they'd add no signal. Each task ends with a **manual verification step** on a real device (or two devices for cross-client tests). Commits are per-task so a regression is easy to bisect.

---

## File map

**Backend, new:**
- `backend/services/livekitAdminService.js` — wrapper over `RoomServiceClient`

**Backend, modified:**
- `backend/controllers/voiceRooms.js` — wire admin endRoom, scope global emit
- `backend/controllers/callController.js` — wire admin endRoom for calls
- `backend/socket/voiceRoomHandler.js` — `voiceroom:end-intent` listener, hand-raise `isRaised` flag
- `backend/socket/socketHandler.js` — auto-join `voicerooms:lobby` on connect

**Frontend, new:**
- `lib/widgets/voice_room/room_ended_modal.dart` — shared "Ended" modal

**Frontend, modified:**
- `lib/services/voice_room_manager.dart` — emit end-intent, await POST, race guard
- `lib/services/call_manager.dart` — busy reply, idempotent endCall, acceptCall fix
- `lib/pages/community/voice_rooms/voice_room_screen.dart` — modal wiring, live-state header
- `lib/pages/community/voice_rooms/voice_room_host_menu.dart` — end-room spinner
- `lib/screens/active_call_screen.dart` — call-ended modal
- `lib/providers/voice_room_provider.dart` — friendly "room ended" error path

---

## Task 1: Backend — `livekitAdminService` wrapper

**Files:**
- Create: `backend/services/livekitAdminService.js`

- [ ] **Step 1: Verify `livekit-server-sdk` is already installed**

Run: `node -e "console.log(require('livekit-server-sdk').RoomServiceClient)"` from `backend/`
Expected: prints `[class RoomServiceClient]` (or similar). If "Cannot find module", run `npm install livekit-server-sdk` first.

- [ ] **Step 2: Create the service**

```js
// backend/services/livekitAdminService.js

/**
 * LiveKit admin service.
 *
 * Force-end a LiveKit room or boot a participant from server-side.
 * Fails open: any error is logged and swallowed so it never blocks the
 * Mongo state change or socket fan-out that called it.
 */

const { RoomServiceClient } = require('livekit-server-sdk');

let _client;

const getClient = () => {
  if (_client) return _client;
  const apiKey = process.env.LIVEKIT_API_KEY;
  const apiSecret = process.env.LIVEKIT_API_SECRET;
  const url = process.env.LIVEKIT_URL;
  if (!apiKey || !apiSecret || !url) {
    throw new Error('LiveKit env not configured (LIVEKIT_API_KEY/SECRET/URL)');
  }
  // RoomServiceClient wants the HTTP base URL, not the WSS one.
  const httpUrl = url.replace(/^wss:/, 'https:').replace(/^ws:/, 'http:');
  _client = new RoomServiceClient(httpUrl, apiKey, apiSecret);
  return _client;
};

/**
 * Force-close a LiveKit room. All participants are disconnected at the
 * transport layer. Idempotent — closing an already-closed room is a no-op.
 */
async function endRoom(roomName) {
  try {
    await getClient().deleteRoom(roomName);
  } catch (err) {
    // 404 / room-not-found is benign (already closed)
    const status = err?.status || err?.code;
    if (status !== 404 && status !== 'not_found') {
      console.error('[livekitAdmin] endRoom failed:', roomName, err.message);
    }
  }
}

/**
 * Boot a single participant from a room. Used for voice-room kick. No-throw.
 */
async function disconnectParticipant(roomName, identity) {
  try {
    await getClient().removeParticipant(roomName, identity);
  } catch (err) {
    console.error(
      '[livekitAdmin] disconnectParticipant failed:',
      roomName, identity, err.message
    );
  }
}

module.exports = { endRoom, disconnectParticipant };
```

- [ ] **Step 3: Smoke-test the import**

Run from `backend/`:
```
node -e "const a = require('./services/livekitAdminService'); console.log(Object.keys(a))"
```
Expected: `[ 'endRoom', 'disconnectParticipant' ]`

- [ ] **Step 4: Commit**

```bash
cd backend
git add services/livekitAdminService.js
git commit -m "feat(livekit): admin service for force-end + force-disconnect"
```

---

## Task 2: Backend — force-close LiveKit room on `/voicerooms/:id/end`

**Files:**
- Modify: `backend/controllers/voiceRooms.js` — `endVoiceRoom` (around line 395)

- [ ] **Step 1: Add the import at the top of the file**

Find the `require` block at the top of `backend/controllers/voiceRooms.js`. Add:

```js
const livekitAdmin = require('../services/livekitAdminService');
```

- [ ] **Step 2: Call `endRoom` in `endVoiceRoom` after `room.end()` and before socket emits**

Locate `exports.endVoiceRoom = asyncHandler(async (req, res, next) => {` (~line 396) and insert one line after `await room.end();`:

```js
await room.end();

// Force-close the LiveKit room so any client that ignored the socket
// event still loses its transport. Fails open (see livekitAdminService).
await livekitAdmin.endRoom(String(roomId));

// Emit socket event
const io = req.app.get('io');
```

(Use `String(roomId)` because that's the LiveKit room name our token mint uses for voice rooms — confirm by grepping for `roomName:` in `voicerooms/:id/token` controller; the value passed there is the same `String(req.params.id)`.)

- [ ] **Step 3: Manual verification**

Restart backend. Open LiveKit Cloud dashboard if you have access (or just observe peer behavior).
- A creates a room, B joins → both see each other
- A taps End
- B's audio session should drop within ~1s, even if B's socket event was lost

- [ ] **Step 4: Commit**

```bash
cd backend
git add controllers/voiceRooms.js
git commit -m "fix(voice-rooms): force-close LiveKit room on host end"
```

---

## Task 3: Backend — force-close LiveKit room on `/calls/:id/end`

**Files:**
- Modify: `backend/controllers/callController.js` — `endCall` (around line 375)

- [ ] **Step 1: Add the import**

Top of `callController.js`, alongside the existing `livekitService` require:

```js
const livekitAdmin = require('../services/livekitAdminService');
```

- [ ] **Step 2: Call `endRoom` after `call.save()`**

Locate `exports.endCall = asyncHandler(async (req, res, next) => {` and find:

```js
call.duration = Math.floor((call.endTime - durationStart) / 1000);
await call.save();
```

Insert after:

```js
await call.save();

// Force-close the LiveKit room so neither peer can keep talking if a
// `call:ended` socket event was lost.
await livekitAdmin.endRoom(_roomNameForCall(call._id));

const io = req.app.get('io');
```

- [ ] **Step 3: Manual verification**

- A calls B → B accepts → both connected
- A hangs up
- B's audio should stop; the active-call screen should pop (current behavior + transport-level enforcement)

- [ ] **Step 4: Commit**

```bash
cd backend
git add controllers/callController.js
git commit -m "fix(calls): force-close LiveKit room on call end"
```

---

## Task 4: Backend — scope global `voiceroom:ended` to a lobby channel

**Files:**
- Modify: `backend/socket/socketHandler.js:248` — add lobby join after `user_<id>` join
- Modify: `backend/controllers/voiceRooms.js` — `endVoiceRoom` and any other site that does `io.emit('voiceroom:ended', ...)`

- [ ] **Step 1: Subscribe every socket to `voicerooms:lobby` on connect**

In `backend/socket/socketHandler.js`, find line ~248:

```js
const userRoom = `user_${userId}`;
await socket.join(userRoom);
console.log(`👤 User ${userId} joined room: ${userRoom}`);
```

Add directly after:

```js
// Broadcast channel for room-list updates (voiceroom:ended, etc.). All
// connected sockets subscribe so rooms-tab lists stay in sync without
// io.emit() waking every user for every event.
await socket.join('voicerooms:lobby');
```

- [ ] **Step 2: Replace global emits in `voiceRooms.js`**

In `backend/controllers/voiceRooms.js`, find every `io.emit('voiceroom:ended', ...)`. There are at least three: the `endVoiceRoom` controller (~line 419), the auto-end-existing-room block in `createVoiceRoom` (~line 166-ish — verify), and the leave handler at ~line 377.

Replace each with:

```js
io.to('voicerooms:lobby').emit('voiceroom:ended', { roomId });
```

Leave the room-channel-scoped `io.to('voiceroom_${roomId}').emit(...)` calls untouched.

- [ ] **Step 3: Replace global emits in `voiceRoomHandler.js`**

Same change in `backend/socket/voiceRoomHandler.js` for the lines at ~49, ~295, and ~588 (verify with grep). Each `io.emit('voiceroom:ended', ...)` becomes `io.to('voicerooms:lobby').emit('voiceroom:ended', ...)`.

Run to verify nothing was missed:
```
cd backend && grep -rn "io.emit('voiceroom:ended'" socket/ controllers/
```
Expected: no matches.

- [ ] **Step 4: Manual verification**

- Open the rooms tab on a second device that isn't in any room
- Have a host create + immediately end a room
- The rooms-tab list should still update (room disappears) — proves the lobby channel works

- [ ] **Step 5: Commit**

```bash
cd backend
git add socket/socketHandler.js socket/voiceRoomHandler.js controllers/voiceRooms.js
git commit -m "perf(voice-rooms): scope ended-broadcast to voicerooms:lobby channel"
```

---

## Task 5: Backend — `voiceroom:end-intent` event suppresses grace timer

**Files:**
- Modify: `backend/socket/voiceRoomHandler.js` — add listener + check in disconnect handler

- [ ] **Step 1: Add a TTL'd set at the top of the file**

At the top of `backend/socket/voiceRoomHandler.js` (near other Map declarations around line 12):

```js
// Hosts that just sent `voiceroom:end-intent` — their imminent disconnect
// should NOT trigger the 30s host-transfer grace timer. Key: `${userId}:${roomId}`.
// Auto-expires after 60s so a missed teardown can't pin the entry forever.
const hostEndIntents = new Map(); // key -> setTimeout handle

function markHostEndIntent(userId, roomId) {
  const key = `${userId}:${roomId}`;
  // Refresh any existing TTL
  const existing = hostEndIntents.get(key);
  if (existing) clearTimeout(existing);
  const handle = setTimeout(() => hostEndIntents.delete(key), 60 * 1000);
  hostEndIntents.set(key, handle);
}

function hasHostEndIntent(userId, roomId) {
  return hostEndIntents.has(`${userId}:${roomId}`);
}

function clearHostEndIntent(userId, roomId) {
  const key = `${userId}:${roomId}`;
  const existing = hostEndIntents.get(key);
  if (existing) clearTimeout(existing);
  hostEndIntents.delete(key);
}
```

- [ ] **Step 2: Add the listener inside `registerVoiceRoomHandlers`**

Inside `registerVoiceRoomHandlers(socket, io)`, alongside the other `socket.on` registrations, add:

```js
socket.on('voiceroom:end-intent', ({ roomId } = {}) => {
  if (!roomId) return;
  markHostEndIntent(userId, String(roomId));
});
```

- [ ] **Step 3: Check the flag in the disconnect handler**

Find the disconnect handler (around line 546). Inside the `if (isHost) { ... }` branch (around line 559) that calls `scheduleHostTransfer`, add a guard:

```js
if (isHost) {
  // If the host explicitly ended the room moments ago, do NOT schedule
  // a host-transfer for their disconnect — the room is dying anyway.
  if (hasHostEndIntent(userId, roomId)) {
    clearHostEndIntent(userId, roomId);
    // Skip both the grace timer and the user_left emit; the /end controller
    // handles the room-ended broadcast.
    continue;
  }

  scheduleHostTransfer(io, roomId, userId);
  // ... existing emit ...
}
```

Note: the existing code uses `try { ... } catch` inside a `for (const room of rooms)` loop, so `continue` is correct (skips to next room).

- [ ] **Step 4: Manual verification**

This is hard to test in isolation but a smoke test:
- A hosts, B joins
- A taps End → both should leave with no flicker. Specifically: B should NOT see a brief "you are now host" event before being kicked.

- [ ] **Step 5: Commit**

```bash
cd backend
git add socket/voiceRoomHandler.js
git commit -m "fix(voice-rooms): suppress host-transfer grace timer on explicit end"
```

---

## Task 6: Backend — hand-raise event carries `isRaised`

**Files:**
- Modify: `backend/socket/voiceRoomHandler.js` — `voiceroom:raise_hand` handler (~line 409)

- [ ] **Step 1: Read `isRaised` from the client payload and pass it on**

Locate the existing handler (~line 409):

```js
socket.on('voiceroom:raise_hand', async (data) => {
  try {
    const { roomId } = data;
    if (!roomId) return;
    const user = await User.findById(userId).select('name images');
    io.to(`voiceroom_${roomId}`).emit('voiceroom:hand_raised', {
      roomId,
      user: { _id: userId, name: user?.name, images: user?.images }
    });
  } catch (error) {
    socket.emit('voiceroom:error', { message: error.message });
  }
});
```

Replace with:

```js
socket.on('voiceroom:raise_hand', async (data) => {
  try {
    const { roomId, isRaised } = data || {};
    if (!roomId) return;
    const user = await User.findById(userId).select('name images');
    io.to(`voiceroom_${roomId}`).emit('voiceroom:hand_raised', {
      roomId,
      userId,
      isRaised: isRaised === true,
      user: { _id: userId, name: user?.name, images: user?.images },
    });
  } catch (error) {
    socket.emit('voiceroom:error', { message: error.message });
  }
});
```

Note: the frontend already emits `voiceroom:raise-hand` with `isRaised` (verify in `voice_room_manager.dart#toggleHandRaised`). The backend listener name in the existing code is `voiceroom:raise_hand` (underscore). If frontend sends dash and backend listens for underscore, this never worked — fix that too in Task 8 below.

- [ ] **Step 2: Manual verification**

(Wait until frontend Task 8 lands.) A and B both raise hands → both see the other's crown icon. A lowers → A's crown disappears for B.

- [ ] **Step 3: Commit**

```bash
cd backend
git add socket/voiceRoomHandler.js
git commit -m "fix(voice-rooms): hand-raise event includes isRaised flag + userId"
```

---

## Task 7: Frontend — shared `RoomEndedModal` widget

**Files:**
- Create: `bananatalk_app/lib/widgets/voice_room/room_ended_modal.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/widgets/voice_room/room_ended_modal.dart

import 'package:flutter/material.dart';

/// Shows a non-dismissible "ended" modal with an OK button.
///
/// Used by voice rooms when the host ends ("Room ended by host"), by
/// 1:1 calls when either peer hangs up ("Call ended"), and by the kick
/// flow ("Removed by host"). The dialog is intentionally explicit —
/// users should acknowledge the end of session before the screen pops.
Future<void> showRoomEndedModal(
  BuildContext context, {
  required String reason,
  String? subtitle,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(reason),
      content: subtitle != null ? Text(subtitle) : null,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/widgets/voice_room/room_ended_modal.dart
```
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
cd bananatalk_app
git add lib/widgets/voice_room/room_ended_modal.dart
git commit -m "feat(voice-rooms): shared RoomEndedModal widget"
```

---

## Task 8: Frontend — `voice_room_manager.endRoom` awaits POST and emits intent

**Files:**
- Modify: `lib/services/voice_room_manager.dart` — `endRoom`, `toggleHandRaised`

- [ ] **Step 1: Change `endRoom` to return a `Future<bool>` and await the POST**

Locate `void endRoom() { ... }` (~line 498) and replace with:

```dart
/// End the room (host only). Returns true on success, false if the
/// backend rejected the call. On failure, local state is preserved so
/// the host can retry. On success, performs full local cleanup.
Future<bool> endRoom() async {
  debugPrint('[VR] endRoom id=${_currentRoom?.id}');
  final roomId = _currentRoom?.id;
  if (roomId == null) return false;

  // Tell backend "ignore my upcoming disconnect's grace timer" so the
  // moment we tear down LiveKit, no participant gets promoted to host
  // of a room that's about to end.
  _socket?.emit('voiceroom:end-intent', {'roomId': roomId});

  try {
    final res = await ApiClient().post('voicerooms/$roomId/end');
    if (!res.success) {
      debugPrint('[VR] endRoom POST failed: ${res.error}');
      return false;
    }
  } catch (e) {
    debugPrint('[VR] endRoom threw: $e');
    return false;
  }

  // Backend has marked ended + force-closed LiveKit + emitted sockets.
  // Safe to tear down local transport now (idempotent if LiveKit already
  // booted us).
  unawaited(_liveKit.disconnect());
  _cleanup();
  return true;
}
```

- [ ] **Step 2: Fix the hand-raise emit event name**

Find `void toggleHandRaised() { ... }` (~line 451). The current emit uses `voiceroom:raise-hand` (dash). Change to underscore to match the backend handler:

```dart
void toggleHandRaised() {
  _isHandRaised = !_isHandRaised;

  _socket?.emit('voiceroom:raise_hand', {
    'roomId': _currentRoom?.id,
    'isRaised': _isHandRaised,
  });

  onStateChanged?.call();
}
```

- [ ] **Step 3: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/services/voice_room_manager.dart
```
Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
cd bananatalk_app
git add lib/services/voice_room_manager.dart
git commit -m "fix(voice-rooms): await endRoom POST, emit end-intent, hand-raise event"
```

---

## Task 9: Frontend — `voice_room_provider.endRoom` propagates result

**Files:**
- Modify: `lib/providers/voice_room_provider.dart` — `endRoom` method (~line 226)

- [ ] **Step 1: Make `endRoom` async + return `bool`**

Locate `void endRoom() { _manager.endRoom(); }` (~line 226) and replace with:

```dart
Future<bool> endRoom() async {
  return _manager.endRoom();
}
```

- [ ] **Step 2: Run analyzer + fix any callers**

```
cd bananatalk_app && flutter analyze
```
Expected: errors only at the call site in `voice_room_host_menu.dart` (we'll fix it in Task 10).

- [ ] **Step 3: Commit**

```bash
cd bananatalk_app
git add lib/providers/voice_room_provider.dart
git commit -m "fix(voice-rooms): endRoom returns success bool"
```

---

## Task 10: Frontend — host menu spinner + error feedback during end

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_room_host_menu.dart` — `showEndRoomConfirm`

- [ ] **Step 1: Replace the dialog with one that handles in-flight + error state**

Locate `Future<void> showEndRoomConfirm(BuildContext context, WidgetRef ref) async { ... }` (line ~83) and replace the entire function with:

```dart
Future<void> showEndRoomConfirm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final rootMessenger = ScaffoldMessenger.maybeOf(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (statefulCtx, setLocalState) {
          bool ending = false;

          Future<void> handleEnd() async {
            setLocalState(() => ending = true);
            final ok = await ref.read(voiceRoomProvider).endRoom();
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            if (ok) {
              // Pop the room screen too. The provider's onRoomEnded path
              // already clears state; this just dismisses the screen.
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
            } else {
              rootMessenger?.showSnackBar(
                SnackBar(
                  content: Text(l10n.voiceRoomEndFailed),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.voiceRoomEndConfirm),
            content: Text(l10n.voiceRoomEndConfirmBody),
            actions: [
              TextButton(
                onPressed: ending ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: ending ? null : handleEnd,
                child: ending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(l10n.voiceRoomEnd),
              ),
            ],
          );
        },
      );
    },
  );
}
```

- [ ] **Step 2: Add the missing `voiceRoomEndFailed` localization key**

In `bananatalk_app/lib/l10n/app_en.arb`, add (alphabetical):

```json
"voiceRoomEndFailed": "Couldn't end room. Please try again.",
"@voiceRoomEndFailed": {
  "description": "Snackbar shown when POST /voicerooms/:id/end fails"
},
```

Run codegen:
```
cd bananatalk_app && flutter gen-l10n
```

If your project doesn't auto-fan to other locales, the English fallback applies. Add translations later if needed — not blocking deploy.

- [ ] **Step 3: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/pages/community/voice_rooms/voice_room_host_menu.dart
```
Expected: 0 errors.

- [ ] **Step 4: Manual verification**

- A creates room, B joins
- A opens host menu → End Room → confirm
- Spinner appears in the End button
- On network success: dialog closes, screen pops
- Force a failure (disable wifi briefly, retry): snackbar appears, dialog stays so user can cancel/retry

- [ ] **Step 5: Commit**

```bash
cd bananatalk_app
git add lib/pages/community/voice_rooms/voice_room_host_menu.dart \
        lib/l10n/app_en.arb \
        lib/l10n/app_localizations*.dart
git commit -m "feat(voice-rooms): end-room spinner + error snackbar"
```

---

## Task 11: Frontend — "Room ended by host" modal for peers

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart` — `ref.listen` block (~line 244)

- [ ] **Step 1: Replace `ref.listen` auto-pop with modal-then-pop**

Locate the existing block:

```dart
// Auto-pop when room ends (including during reconnect gap)
ref.listen<VoiceRoomNotifier>(voiceRoomProvider, (previous, next) {
  final wasInRoom = previous?.currentRoom != null;
  final nowOutOfRoom = next.currentRoom == null;
  if (wasInRoom && nowOutOfRoom && context.mounted) {
    Navigator.of(context).maybePop();
  }
});
```

Replace with:

```dart
// Auto-pop when room ends. If the room ended because the host pressed
// End (or we were kicked), show an acknowledgement modal first so the
// user sees an explicit reason rather than the screen vanishing.
ref.listen<VoiceRoomNotifier>(voiceRoomProvider, (previous, next) async {
  final wasInRoom = previous?.currentRoom != null;
  final nowOutOfRoom = next.currentRoom == null;
  if (!(wasInRoom && nowOutOfRoom)) return;
  if (!context.mounted) return;

  // The host's own end flow already popped via the host menu (see
  // showEndRoomConfirm); skip the modal for the host since they
  // explicitly initiated the action.
  if (isHost) {
    Navigator.of(context).maybePop();
    return;
  }

  final reason = next.error ?? 'Room ended';
  await showRoomEndedModal(context, reason: reason);
  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).maybePop();
  }
});
```

- [ ] **Step 2: Add the import**

At the top of `voice_room_screen.dart`:

```dart
import 'package:bananatalk_app/widgets/voice_room/room_ended_modal.dart';
```

- [ ] **Step 3: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/pages/community/voice_rooms/voice_room_screen.dart
```
Expected: 0 errors.

- [ ] **Step 4: Manual verification**

- A hosts, B joins → A ends → B sees "Room ended by host" with OK button → tap OK → B returns to rooms list
- Same flow but A kicks B → B sees "You were removed from the room" with OK

- [ ] **Step 5: Commit**

```bash
cd bananatalk_app
git add lib/pages/community/voice_rooms/voice_room_screen.dart
git commit -m "feat(voice-rooms): peer modal on room end + kick"
```

---

## Task 12: Frontend — header consumes live room state

**Files:**
- Modify: `lib/pages/community/voice_rooms/voice_room_screen.dart`

- [ ] **Step 1: Pass live room into the header**

Find where `VoiceRoomHeader(room: widget.room, ...)` is built (around line 262 in the existing file). Change to:

```dart
appBar: VoiceRoomHeader(
  room: voiceRoom.currentRoom ?? widget.room,
  onLeave: _leaveRoom,
  pulseAnimation: _pulseAnimation,
),
```

Also audit the same file for any other `widget.room` usages that should use the live state — `VoiceRoomInfoBar(room: widget.room)` (~line 271), `VoiceRoomParticipantsGrid(room: widget.room, ...)` (~line 274). Change both to `voiceRoom.currentRoom ?? widget.room`.

- [ ] **Step 2: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/pages/community/voice_rooms/voice_room_screen.dart
```
Expected: 0 errors.

- [ ] **Step 3: Manual verification**

- A hosts → B joins → A leaves (host transfer to B) → B's title bar should show B as host (crown next to B's name), not A

- [ ] **Step 4: Commit**

```bash
cd bananatalk_app
git add lib/pages/community/voice_rooms/voice_room_screen.dart
git commit -m "fix(voice-rooms): header/info/grid consume live room state"
```

---

## Task 13: Frontend — de-dupe ended-vs-rejoin-ack race

**Files:**
- Modify: `lib/services/voice_room_manager.dart`

- [ ] **Step 1: Add a transient handling flag**

Near the top of the class with the other private fields (~line 60):

```dart
// Set briefly when we've handled a room-ended signal so a duplicate
// (e.g. rejoin ack + late ended event) doesn't double-fire onRoomEnded.
bool _handlingEnd = false;
```

- [ ] **Step 2: Guard `onRoomEnded` in the ended-event listener**

Find `_endedSub = _chatSocketService!.onVoiceRoomEnded.listen((data) { ... });` (~line 241) and replace with:

```dart
_endedSub = _chatSocketService!.onVoiceRoomEnded.listen((data) {
  if (_handlingEnd) return;
  _handlingEnd = true;
  Future.delayed(const Duration(seconds: 1), () => _handlingEnd = false);
  onRoomEnded?.call();
  _cleanup();
});
```

- [ ] **Step 3: Same guard in the rejoin-ack failure path**

Find the rejoin emitWithAck callback (~line 137-159). Inside the `if (m['ended'] == true || m['ok'] == false)` branch, before `onRoomEnded?.call()`, add:

```dart
if (_handlingEnd) return;
_handlingEnd = true;
Future.delayed(const Duration(seconds: 1), () => _handlingEnd = false);
```

- [ ] **Step 4: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/services/voice_room_manager.dart
```
Expected: 0 errors.

- [ ] **Step 5: Manual verification**

Hard to trigger reliably (requires network jitter). Smoke test: A hosts, B joins, A ends — should never see B's screen pop twice.

- [ ] **Step 6: Commit**

```bash
cd bananatalk_app
git add lib/services/voice_room_manager.dart
git commit -m "fix(voice-rooms): dedupe room-ended events across rejoin race"
```

---

## Task 14: Frontend — friendly error when joining ended room

**Files:**
- Modify: `lib/providers/voice_room_provider.dart` — joinRoom error path (audit current flow first)

- [ ] **Step 1: Locate `joinRoom` in the provider**

```
cd bananatalk_app && grep -n "joinRoom\|Future<void> joinRoom" lib/providers/voice_room_provider.dart
```

You'll find a public `joinRoom` method that calls `_manager.joinRoom(...)` inside a try/catch.

- [ ] **Step 2: Recognize "room ended" responses**

Backend `joinVoiceRoom` returns a 4xx error response when the room is ended. Inspect the error string and surface a friendly message via `_state.copyWith(error: ...)`. Replace the existing catch block in `joinRoom` with:

```dart
} catch (e) {
  final msg = e.toString();
  String friendly;
  if (msg.contains('410') ||
      msg.toLowerCase().contains('ended') ||
      msg.contains('404')) {
    friendly = 'This room has ended';
  } else {
    friendly = 'Failed to join room';
  }
  _state = _state.copyWith(error: friendly);
  notifyListeners();
  rethrow;
}
```

(Keep the rethrow — the screen that called `joinRoom` decides what to do with the exception; the state-error is what powers a snackbar or empty-state.)

- [ ] **Step 3: Manual verification**

- Create a room, end it (status=ended in DB), then in a second device tap the (stale) listing for that room
- The join should fail gracefully with "This room has ended" rather than a raw error

- [ ] **Step 4: Commit**

```bash
cd bananatalk_app
git add lib/providers/voice_room_provider.dart
git commit -m "fix(voice-rooms): friendly error when joining an ended room"
```

---

## Task 15: Frontend — call_manager auto-busy on incoming during active call

**Files:**
- Modify: `lib/services/call_manager.dart` — `_handleIncomingSocketEvent` (~line 273)

- [ ] **Step 1: Replace silent drop with a busy POST**

Locate the early-return:

```dart
if (currentCall != null) {
  debugPrint('📞 Already in a call, ignoring incoming');
  return;
}
```

Replace with:

```dart
if (currentCall != null) {
  debugPrint('📞 Already in a call, replying busy');
  // Tell the caller we're busy so their ringback stops immediately
  // instead of running the full 45s timeout.
  try {
    final incomingCallId = (data is Map ? data['callId'] : null)?.toString();
    if (incomingCallId != null && incomingCallId.isNotEmpty) {
      unawaited(ApiClient().post('calls/$incomingCallId/decline'));
    }
  } catch (e) {
    debugPrint('📞 busy reply failed: $e');
  }
  return;
}
```

(Note: backend's `declineCall` records status=rejected. Caller sees `call:declined` socket event. That's the existing path — no backend change needed.)

- [ ] **Step 2: Manual verification**

- A and B on call
- C calls A → C should see "declined" within ~1 second instead of ringing for 45s

- [ ] **Step 3: Commit**

```bash
cd bananatalk_app
git add lib/services/call_manager.dart
git commit -m "fix(calls): auto-busy reply when incoming arrives during active call"
```

---

## Task 16: Frontend — idempotent `endCall` / `rejectCall`

**Files:**
- Modify: `lib/services/call_manager.dart` — `endCall` (~line 681), `rejectCall` (~line 662)

- [ ] **Step 1: Add an in-flight flag at the top of the class**

Near the other private fields (~line 60), add:

```dart
// Set while a user-initiated teardown is in progress. Distinct from
// _localTeardownInFlight (which gates the LiveKit-fired disconnect
// callbacks) — this one guards against double-tap of the End button
// or CallKit `onEnded` racing with the in-app End.
bool _endInFlight = false;
```

- [ ] **Step 2: Guard `endCall`**

Replace the existing `void endCall() { ... }` with:

```dart
void endCall() {
  if (_endInFlight) {
    debugPrint('[Call] endCall ignored (already in flight)');
    return;
  }
  _endInFlight = true;
  debugPrint('[Call] endCall callId=${currentCall?.callId}');
  if (currentCall == null) {
    _endInFlight = false;
    return;
  }

  _playEndSound();
  _localTeardownInFlight = true;

  final callId = currentCall!.callId;
  if (callId.isNotEmpty) {
    unawaited(ApiClient().post('calls/$callId/end'));
  }

  final duration =
      DateTime.now().difference(currentCall!.startTime).inSeconds;
  currentCall = currentCall!.copyWith(
    status: CallStatus.ended,
    endTime: DateTime.now(),
    duration: duration,
  );

  onCallEnded?.call(currentCall!);
  _cleanup();
}
```

- [ ] **Step 3: Same guard in `rejectCall`**

Replace the existing `void rejectCall() { ... }` with:

```dart
void rejectCall() {
  if (_endInFlight) {
    debugPrint('[Call] rejectCall ignored (already in flight)');
    return;
  }
  _endInFlight = true;
  debugPrint('[Call] rejectCall callId=${currentCall?.callId}');
  if (currentCall == null) {
    _endInFlight = false;
    return;
  }
  final callId = currentCall!.callId;

  if (callId.isNotEmpty) {
    unawaited(ApiClient().post('calls/$callId/decline'));
  }

  currentCall = currentCall!.copyWith(status: CallStatus.rejected);
  onCallRejected?.call(currentCall!);
  _cleanup();
}
```

- [ ] **Step 4: Clear the flag in `_cleanup`**

Locate `void _cleanup() { ... }` (~line 961) and add at the bottom, right after `_localTeardownInFlight = false;`:

```dart
_endInFlight = false;
```

- [ ] **Step 5: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/services/call_manager.dart
```
Expected: 0 errors.

- [ ] **Step 6: Manual verification**

- Make a call → start tapping End rapidly → only one `[Call] endCall` log line should reach the network
- On iOS: while ringing, decline via CallKit *and* in-app simultaneously → no crash, no double-callback

- [ ] **Step 7: Commit**

```bash
cd bananatalk_app
git add lib/services/call_manager.dart
git commit -m "fix(calls): idempotent endCall/rejectCall against double-fire"
```

---

## Task 17: Frontend — acceptCall failure path no longer posts /decline

**Files:**
- Modify: `lib/services/call_manager.dart` — `acceptCall` (~line 592)

- [ ] **Step 1: Replace the three `rejectCall()` calls in `acceptCall` with local cleanup**

Locate `Future<void> acceptCall() async { ... }` and find every site that calls `rejectCall()` in the failure branches (there are three: permissions denied, accept POST failed, LiveKit connect failed — plus one in the outer catch).

For each, replace `rejectCall();` with:

```dart
_cleanup();
```

Keep the `onCallError?.call(err)` line(s) above.

Rationale: the backend's `acceptCall` endpoint will have already changed the call to status=active (or failed). Posting `/decline` after that returns 409 (call already accepted). The user already sees the error via `onCallError`; the caller will see the call eventually end via timeout.

- [ ] **Step 2: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/services/call_manager.dart
```
Expected: 0 errors.

- [ ] **Step 3: Manual verification**

- Force `acceptCall` permissions to be denied (revoke mic in iOS Settings) → tap Accept → error toast appears, no 409 spam in the network log

- [ ] **Step 4: Commit**

```bash
cd bananatalk_app
git add lib/services/call_manager.dart
git commit -m "fix(calls): acceptCall failure path skips /decline POST"
```

---

## Task 18: Frontend — "Call ended" modal in active_call_screen

**Files:**
- Modify: `lib/screens/active_call_screen.dart`

- [ ] **Step 1: Add the import**

```dart
import 'package:bananatalk_app/widgets/voice_room/room_ended_modal.dart';
```

- [ ] **Step 2: Replace the delayed-pop with modal-then-pop**

In `initState`, find the `setCallEndedCallback` registration (~line 84). The current body does:

```dart
callNotifier.setCallEndedCallback((call) {
  if (mounted) {
    setState(() {
      _callEnded = true;
      _isEnding = true;
    });
  }
  // Brief delay so user sees "Call ended" before screen closes
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      Navigator.of(context).pop();
    }
  });
});
```

Replace with:

```dart
callNotifier.setCallEndedCallback((call) async {
  if (!mounted) return;
  setState(() {
    _callEnded = true;
    _isEnding = true;
  });
  // Brief settle so any animations finish before the modal appears.
  await Future.delayed(const Duration(milliseconds: 250));
  if (!mounted) return;
  await showRoomEndedModal(
    context,
    reason: 'Call ended',
    subtitle: call.duration != null
        ? 'Duration: ${_formatDuration(call.duration!)}'
        : null,
  );
  if (mounted) Navigator.of(context).pop();
});
```

- [ ] **Step 3: Add the `_formatDuration` helper**

Inside `_ActiveCallScreenState`, add near the top of the methods:

```dart
String _formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
```

- [ ] **Step 4: Run analyzer**

```
cd bananatalk_app && flutter analyze lib/screens/active_call_screen.dart
```
Expected: 0 errors (or only pre-existing info-level lints).

- [ ] **Step 5: Manual verification**

- A calls B → B accepts → talk for a few seconds → A hangs up
- A sees "Call ended" + Duration → tap OK → returns to chat
- Same flow but reverse: B hangs up → A sees "Call ended" modal

- [ ] **Step 6: Commit**

```bash
cd bananatalk_app
git add lib/screens/active_call_screen.dart
git commit -m "feat(calls): show Call ended modal with duration on hangup"
```

---

## Task 19: Final integration smoke test

No code — verification only. Run this on **two real devices** (or one real + one simulator with the device_info_plus patch applied; do NOT use hot reload — full restart so pub-cache patches are in the build).

- [ ] **§1 happy path:** A hosts → B joins → A ends → both see modal → both transports drop within 1s
- [ ] **§1 race:** A hosts → kill A's wifi for 5s → A ends → no peer flicker, B still gets ended modal once
- [ ] **§1 retry:** A hosts → A ends with wifi off → snackbar shows, dialog stays → enable wifi → tap End again → succeeds
- [ ] **§2 hand raise:** A and B both raise → both see crowns → both lower → both see crowns removed
- [ ] **§2 host transfer:** A hosts → A leaves (not end, just leaves) → B's header shows B as host
- [ ] **§2 join ended:** A creates + ends room → B taps the stale listing → friendly "This room has ended" snackbar
- [ ] **§3 busy:** A and B on call → C calls A → C immediately sees declined
- [ ] **§3 call end:** A calls B → B answers → A hangs up → both see Call ended modal with duration
- [ ] **§3 CallKit race (iOS only):** A calls B → B declines via CallKit AND in-app within 1s of each other → no crash, no error toast

If any of these regress, the relevant task's commit can be reverted in isolation.

- [ ] **Final commit (if all green):**

No extra files to commit; just verify `git log` shows the 18 task commits cleanly and push.

```bash
git log --oneline -20
git push
```

---

## Self-review notes

**Spec coverage:**
- §1.1 force-close LiveKit on /end → Task 2 ✓
- §1.2 suppress grace timer → Tasks 5 + 8 ✓
- §1.3 scope global emit → Task 4 ✓
- §1.4 peer modal → Tasks 7 + 11 ✓
- §1.5 host spinner → Task 10 ✓
- §2.1 header live state → Task 12 ✓
- §2.2 dedup race → Task 13 ✓
- §2.3 hand-raise isRaised → Tasks 6 + 8 ✓
- §2.4 friendly join-ended → Task 14 ✓
- §2.5 verify post-rebuild → Task 19 ✓
- §3.1 busy → Task 15 ✓
- §3.2 idempotent endCall → Task 16 ✓
- §3.3 force-close LiveKit on call end → Task 3 ✓
- §3.4 call ended modal → Task 18 ✓
- §3.5 acceptCall no decline → Task 17 ✓
- §3.6 timeout posts /end → Task 19 (verification only; existing endCall already POSTs)

All 16 numbered spec items mapped.

**Type/name consistency:**
- `showRoomEndedModal(context, reason: ..., subtitle: ...)` — defined in Task 7, called identically in Tasks 11 and 18.
- `livekitAdmin.endRoom(roomName)` — defined in Task 1, called the same way in Tasks 2 and 3.
- `endRoom()` returns `Future<bool>` — defined in Task 8 (manager) and Task 9 (provider). Called as `await ref.read(voiceRoomProvider).endRoom()` in Task 10. ✓
- `voiceroom:end-intent` — emitted in Task 8, listened in Task 5. ✓
- `voiceroom:raise_hand` — frontend emits in Task 8 (changed from dash), backend listens in Task 6. ✓

No placeholders. All steps have concrete code.
