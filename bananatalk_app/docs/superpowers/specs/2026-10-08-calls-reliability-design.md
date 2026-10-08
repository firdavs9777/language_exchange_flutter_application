# 1:1 voice & video calls — reliability, history, video polish

Date: 2026-10-08 · Repos: `bananatalk_app` (Flutter) + `language_exchange_backend_application` (Node) · Status: revised after spec review (rev 3)

## 1. Why

Measured in prod (2026-10-08): **1 of 30 calls answered in the last 30 days (3%)**; 0 answered Jul–Sep; 168 calls stuck `ringing` and 4 stuck `active`; **0 call messages in any conversation, ever**. Users report calls ring inconsistently and there is no call history in chat.

The audit found a stack of causes, not one bug:

- The app uses the REST + LiveKit path (`controllers/callController.js`). The legacy socket path (`socket/callHandler.js`) holds the only timeout / busy / missed / chat-message logic for initiate/answer/end, and the app never calls those handlers.
- `CallManager.initialize()` binds listeners to `chatSocketService.socket` once (`call_manager.dart:133`); `ChatSocketService` replaces that socket on resume, token refresh and login, so the app goes deaf to `call:incoming`. Foreground `incoming_call` FCM is deliberately dropped (`notification_service.dart:426`).
- iOS CallKit is given the 24-hex Mongo id; `flutter_callkit_incoming` force-unwraps `UUID(uuidString:)` → crash when a call arrives while the app is inactive/backgrounded.
- Caller's screen freezes after decline / connection loss (`_cleanup()` without `onCallEnded`, `canPop:false`, End no-ops).
- Socket handlers (`call_manager.dart:197-230`) don't check `callId`; no busy check → one call's timeout ends another.
- No server ring timeout, no `missed` status, no missed push; peer-drop never reaches the server.
- Accept/decline are emitted only to the caller → callee's other devices keep ringing; devices ringing via push (no socket) are never dismissed.
- Android: no mic/camera foreground service (media stops in background), full-screen-intent permission never requested at runtime, notification + CallKit duplicate UI; killed-state accept is lost and video joins as audio "Unknown".
- `Message.media.type` enum lacks `call` → the legacy chat message fails validation silently.
- `CallHistoryScreen` parses fields the API doesn't send → crash; not linked from navigation.
- Video: no wakelock (screen locks mid-video, iOS camera stops); 5-minute free-user cap enforced only on the receiving side (`incoming_call_screen.dart:150`), silently.
- `@parse/node-apn` is not in `package.json` (VoIP works in prod only because it was installed by hand).

## 2. Decisions

| Topic | Decision |
|---|---|
| Architecture | **Server-authoritative call state** on the existing REST + LiveKit path. Remove the legacy socket initiate/answer/end handlers; keep the in-call relays live builds use. |
| Call history | **In-conversation call messages + a Calls list** (chat-tab header icon, missed badge). |
| Second incoming call | **Busy** (no call waiting). |
| Free-user 5-min cap | **Removed** for now (0 VIP subscribers, 3% answer rate). Revisit as a VIP perk once calls work. |
| Ring timeout / reconnect grace | 45 s / 20 s. |
| Live builds (2.2.x, 2.6.1) | Must keep ringing, connecting and ending. Existing event names keep their current audience and meaning; new behaviour uses new events. |
| Phasing | **Phase 1 = reliability + history** (ships first, owns the answer-rate metric). **Phase 2 = extras** the user approved: decline with message (in-app screen), missed-call push actions, calls on/off + quiet hours, camera on mid voice call, draggable/swappable self-view. |
| Out of scope (follow-up spec) | Language-swap timer, scheduled calls, post-call summary, live captions, picture-in-picture, pre-answer camera preview, call waiting, group calls. |

## 3. Outcome table (single source of truth)

One call message is shared by both users; each side renders its own label from `outcome` + whether the viewer was the caller.

| Status / endReason | Stored `outcome` | Caller label | Receiver label | Call message? | Missed push to receiver? | Counts as missed (badge)? |
|---|---|---|---|---|---|---|
| ended / completed | `completed` | Outgoing call · m:ss | Incoming call · m:ss | yes | no | no |
| missed / timeout | `no_answer` | No answer | Missed call | yes | yes | yes |
| missed / caller_cancelled | `cancelled` | Cancelled call | Missed call | yes | yes | yes |
| rejected / rejected | `declined` | Declined | Declined call | yes | no | no |
| busy / busy (receiver in a live call) | `busy` | <name> was on another call | Missed call | yes | yes | yes |
| busy / unavailable (Phase 2: receiver has calls off / quiet hours) | — | <name> isn't taking calls (toast only) | — | **no** | no | no |
| failed / failed | — | Call failed (toast only) | — | no | no | no |
| missed / timeout, `backfilled: true` (sweeper on old records) | — | — | — | no | no | no |

"Voice"/"Video" is prefixed from the call type (e.g. "Missed video call").

## 4. Backend — Phase 1

### 4.1 State machine (`services/callStateService.js`, new)

```
initiate ─► ringing ─┬─ accept ─────────► active ── end / peer gone > 20 s ──► ended (completed)
                     ├─ decline ────────► rejected
                     ├─ caller cancel ──► missed   (caller_cancelled)
                     └─ 45 s ───────────► missed   (timeout)
initiate when the receiver has a live call ─► busy (409 CALLEE_BUSY, never rings)
initiate when the caller has a live call   ─► 409 CALLER_BUSY, no Call record
```

- Every transition is one atomic `findOneAndUpdate({ _id, status: <expected> })`. A failed precondition returns `409 CALL_STATE { status }`. This settles every race: accept vs timeout, accept vs cancel, two devices accepting, end vs webhook — whoever writes first wins, the other gets 409 (the app treats a 409 on accept as "dismiss silently").
- "Live call" = `ringing` younger than 60 s, or `active`, for that user as caller or receiver.
- **Busy is atomic:** each `User` gets `activeCallId`. Initiate claims both users with conditional updates (`findOneAndUpdate({ _id, $or: [{ activeCallId: null }, { activeCallId: <stale> }] }, { activeCallId: call._id })`, caller first, then receiver; if the receiver claim fails, release the caller and return busy). A claim is stale when its Call is terminal or ringing > 60 s. Every terminal transition clears `activeCallId` on both users (conditional on it still being this call). Two users calling each other at once: exactly one wins, the other gets busy.
- `Call` schema: add `callUuid` (UUID v4) with a **partial** unique index (`{ callUuid: { $exists: true } }`); `seenByReceiverAt`; `backfilled`; `underfilledSince`; `endReason` gains `caller_cancelled`, `unavailable`.
- The controller keeps HTTP concerns only; webhook and sweeper call the same service.
- **`/calls/:id/*` accept either the Mongo `_id` or the `callUuid`** (live iOS builds will see `id = callUuid` in VoIP pushes, §4.6).

### 4.2 Timers and sweeps

- **Ring timeout:** in-process `setTimeout(45 s)` per call → `ringing → missed (timeout)`; cleared on any transition.
- **Sweeper** (`jobs/callSweepJob.js`, every 60 s via `jobs/scheduler.js`):
  - `ringing` older than 60 s → `missed (timeout)`.
  - `active` whose LiveKit room has fewer than 2 participants (`RoomService.listParticipants`): first sighting sets `underfilledSince` on the Call; a later sweep that still sees < 2 and `underfilledSince` older than 20 s → `ended (completed)`; back to 2 clears it. Room missing → `ended`; older than 4 h → `ended`.
  - First run backfills the existing 168 + 4 records with `backfilled: true` (no message, no push).
- **LiveKit webhook** (`controllers/livekit.js`): `participant_left` (one party) starts a 20 s in-process grace; `participant_joined` for that identity cancels it; at expiry re-check with `listParticipants` before ending. `room_finished` → `ended`. Both set `endReason`, `duration` (`endTime - answeredAt`, 0 if never answered), emit events. If the webhook isn't configured (owner task) or the process restarts mid-grace, the sweeper covers it.

### 4.3 Events

Live builds listen to `call:incoming`, `call:accepted`, `call:declined`, `call:ended`, `call:missed`, `call:timeout`, `call:rejected` **without `callId` checks**. So:

- **Unchanged audience** for the existing names: `call:accepted` / `call:declined` → caller only; `call:incoming` → receiver; `call:ended` → both. **On `missed` (timeout or cancel), `call:ended` is also sent to both rooms** so a live caller stops ringback and a live receiver's `IncomingCallScreen` closes. Safe for live builds that don't check `callId`: atomic busy (§4.1) guarantees neither user has another live call at that moment.
- Accepted limitation for live builds: their *other* devices still ring after a decline/accept on one device (they only get caller-side events); the `call_cancelled` push (§4.4) dismisses them where supported.
- **New** `call:state` → both users' rooms on every transition: `{ callId, callUuid, status, outcome, endReason, duration, by }`. The new app listens only to this (plus `call:incoming`) and filters by `callId`; this is what stops the receiver's other devices.
- All payloads carry `callId` and `callUuid`.
- **In-call relays stay:** `call:mute`, `call:video-toggle`, `call:reconnecting`, `call:reconnected`, `call:failed` (`callHandler.js:434,491` etc.) are moved into a slim `socket/callRelayHandler.js`, with a participant check against the Call record. Only the legacy initiate/answer/end/missed handlers and the in-memory `activeCalls` map are deleted.
- `GET /calls/current` → the user's live call (`ringing` for me as receiver, or `active`) or `null`.

### 4.4 Dismissing devices that ring without a socket

On every exit from `ringing` (accept, decline, cancel, timeout), send a **`call_cancelled` push** `{ type: 'call_cancelled', callId, callUuid }` to the receiver's devices, **except the device that acted** (accept/decline requests carry `deviceId`):

- **Android:** data-only, high priority. Live builds ignore unknown data types (verify in the plan; if not, gate like iOS).
- **iOS VoIP:** only to tokens registered with `capabilities: ['call_cancel']`. The new app sends this in `registerVoipToken`; live builds don't, so they never get it — a live `AppDelegate` treats every VoIP push as an incoming call and would ring "Unknown". New `AppDelegate`: if a call with that `callUuid` is already reported → end it; if none is (the cancel overtook the invite) → report and immediately end (PushKit requires a report).
- On a caller cancel the receiver gets both this and the missed push; the cancel removes the ringing UI, the missed push is what stays visible.

### 4.5 Call messages

- On every terminal transition marked "Call message? yes" in §3, write **one** `Message`: `messageType: 'call'`, sender = caller, receiver = callee, `message` = plain-text fallback from the caller's perspective (e.g. "📞 Missed voice call") so validation passes and live builds show text, `media.type: 'call'` (enum extended), `media.callData` — the location live builds already read (`messages_list.dart:255` renders `CallHistoryBubble` whenever `media.callData != null`; `CallRecord.fromJson`, `call_record_model.dart:49-80`). It is a **superset** so live builds render correctly:
  `{ _id: callId, callId, callUuid, initiator: callerId, participants: [], type: 'audio'|'video', startTime, duration, status: <legacy>, outcome: <§3> }`, where legacy `status` = `missed` for `no_answer|cancelled|busy`, `rejected` for `declined`, `ended` for `completed`. The new app reads `outcome`.
- Idempotent: partial unique index on `media.callData.callId`.
- Conversation: reuse the existing one; if none exists, create it **through the same path a first text message uses**, so message-request / conversation-cap rules apply (a call from a stranger lands as a request, exactly like a first message). If that path would refuse the message, the call itself was already refused at initiate by the same rule — the plan verifies initiate applies it.
- Delivered through the normal new-message emit (chat-list preview + unread). **No chat push** for call messages.

### 4.6 Push

- Incoming-call FCM: **data-only, high priority, 45 s TTL** (Android `ttl`, APNs `apns-expiration`), with `callId`, `callUuid`, `callType`, caller name + avatar. Android loses the `notification` block (CallKit renders). iOS FCM alert fallback also gets the 45 s expiry.
- VoIP push: `id` = `callUuid` (fixes the crash for live builds too, since `/calls/:id` accepts it), `extra.callId` = Mongo id, plus `callType`, caller name/avatar.
- **Missed-call push** to the receiver per §3: "Missed voice call from X", deep link to the conversation. (Phase 2 adds Call back / Message actions.)
- `@parse/node-apn` added to `package.json`.

### 4.7 History API

- `GET /calls` (paged, 30): includes `busy`; item `{ id, callUuid, type, direction (in|out), outcome, duration, otherParty { id, name, avatar }, createdAt }` — no display labels; the app derives them from §3.
- `GET /calls/missed/count` = receiver-side calls with outcome `no_answer | cancelled | busy` and `seenByReceiverAt` null. `POST /calls/missed/seen` sets it.

### 4.8 Cap

No server-side cap exists today; nothing to remove server-side.

## 5. App — Phase 1

### 5.1 CallManager as a state follower

- One `currentCall` keyed by `callId`. Listens to `call:incoming` and `call:state`; every event whose `callId` ≠ `currentCall.callId` is ignored (except `call:incoming` when idle). Stops listening to the legacy per-outcome events.
- **Single exit path** `_finish(reason)`: stop tracks, leave LiveKit, end CallKit by `callUuid`, stop ringback/ringtone, release wakelock + foreground service, fire `onCallEnded`, pop the call screen. Runs at most once per call. The End button always closes the screen, even if `currentCall` is already null.
- Caller outcome banner (1.5 s) from §3 labels before closing.
- 409 `CALL_STATE` on accept → dismiss silently (another device won).

### 5.2 Reliable incoming

- `ChatSocketService` exposes `onSocketReplaced`, fired after every new socket instance; `CallManager` re-binds there.
- Foreground `incoming_call` FCM is handled; socket + push dedupe by `callId` → one incoming UI.
- `call_cancelled` push (data or VoIP) → end CallKit for that `callUuid` / close `IncomingCallScreen`.
- Resume and cold start: `GET /calls/current`; ringing for me → incoming UI; active → rejoin.
- Tapping an old incoming-call notification: `GET /calls/:id` first; not `ringing` → open the conversation.
- `IncomingCallScreen` closes on a terminal `call:state` for its `callId`, and after 50 s as a safety net.

### 5.3 CallKit / native

- CallKit id = `callUuid` on every path (socket, FCM, `AppDelegate.swift` VoIP).
- `extra` carries `callId`, `callUuid`, `callType`, caller name + avatar, LiveKit url/room; the LiveKit token comes from `POST /calls/:id/accept`.
- Cold start: after `runApp`, `FlutterCallkitIncoming.activeCalls()`; accepted → join; declined → `/decline`.
- `registerVoipToken` sends the real device id.

### 5.4 Android

- Foreground service during a call via **`flutter_foreground_task`** (LiveKit provides none), types `microphone` (+ `camera` for video); manifest `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `FOREGROUND_SERVICE_CAMERA`. Owner task: the Play Console foreground-service declarations for these types.
- `USE_FULL_SCREEN_INTENT` is already declared; add the runtime request (Android 14+) with an explainer, once, the first time an incoming call arrives or call settings open.

### 5.5 Reconnect

Peer disconnected or local network lost → "Reconnecting…" overlay up to 20 s (LiveKit auto-reconnects). After 20 s → `POST /end` (best effort; 409 ignored) + `_finish`.

### 5.6 Video basics

- Wakelock on during **video** calls, off in `_finish`. (Voice calls: iOS CallKit already handles proximity; Android uses the default call screen behaviour — no wakelock, so the screen can time out normally.)
- Leaving the app mid-video: camera unpublished; the peer sees an avatar tile "Camera paused"; republished on resume.
- Remove the client 5-minute cap (`_durationLimitTimer`, `setVipCall` callers).
- `ActiveCallScreen` chains `onConnectionQualityChanged` instead of overwriting it.

### 5.7 History UI

- **Conversation:** `CallHistoryBubble` renders `messageType: 'call'` with §3 labels, type + direction icon, time; tap = call back with the same type. Chat-list preview uses the label.
- **Calls list:** rebuild `CallHistoryScreen` against §4.7; phone icon in the chat-tab app bar with the missed badge; rows: avatar, name, in/out/missed arrow (missed red), type, time, duration, trailing call-back button; row tap → conversation; paging 30; opening it calls `/calls/missed/seen`.

## 6. Phase 2 (after Phase 1 ships)

- **Decline with message** — in-app `IncomingCallScreen` only (CallKit / the plugin's Android UI can't host it): 2 canned replies + custom; `POST /calls/:id/decline { message ≤ 200 }` → after the call message, a normal text message from the receiver.
- **Missed-call push actions** Call back / Message: iOS `UNNotificationCategory` registered natively; Android local-notification actions (the push is data-only); Call back from a killed app launches the app, then calls.
- **Calls on/off + quiet hours** — reuse `User.quietHours` and add a separate `notificationSettings.allowCalls` (default true). `notificationSettings.calls` keeps its current meaning (push on/off). `allowCalls:false` or inside quiet hours → `409 CALLEE_UNAVAILABLE`, `busy/unavailable` record, no message, no push (§3). Settings UI under Settings → Notifications.
- **Camera on during a voice call** — publishes video; `POST /calls/:id/upgrade` sets `type: 'video'` so history and the bubble say "Video call"; `call:state` carries the new type.
- **Draggable self-view** snapping to corners; tap to swap big/small.

## 7. Testing

- **Backend (node:test + harness):** every transition; accept-after-cancel / accept-vs-timeout / double accept → one winner + 409; mutual simultaneous calls → one busy; ring timeout → `no_answer` + exactly one message + push; sweeper backfill (no message/push) and the two-sweep active rule; webhook grace cancelled by rejoin; one message per call under retry; **live-build event audience** (`call:accepted`/`call:declined` caller-only, `call:ended` to caller on missed); `call:state` to both rooms; `/calls/:uuid/accept` works; `call_cancelled` push sent on every exit from ringing; history outcomes per §3; missed count/seen; relay handlers keep working with the participant check.
- **App (flutter test):** foreign `callId` ignored; every exit reason runs `_finish` exactly once and pops; listeners survive socket replacement; socket + push dedupe; `call_cancelled` ends CallKit; resume recovery via `/calls/current`; stale notification opens chat; 409 on accept dismisses; bubble + list labels per §3; cap removed.
- **Device QA:** `docs/qa/calls-matrix.md` — {iOS, Android 13+, Android 8} × {foreground, background, killed, after resume} × {voice, video} × {wifi, cellular}, plus busy, decline, caller cancel while callee is killed (CallKit must disappear), two devices for one user, wifi↔cellular switch, video screen stays on, camera paused/resumed, a live 2.6.1 build against the new backend.

## 8. Rollout

1. **Backend Phase 1** first (safe for live builds: event audiences unchanged, ids accepted both ways, relays kept): stops stuck calls, starts call messages and missed pushes. Owner: LiveKit webhook URL; confirm `[voipPush] initialised` after deploy.
2. **App Phase 1** release.
3. Measure one week after the app release: answered rate ≥ 40% of initiated calls (baseline 3%); stuck `ringing`/`active` = 0; call messages for 100% of terminal calls marked "yes" in §3.
4. **Phase 2** backend + app.
