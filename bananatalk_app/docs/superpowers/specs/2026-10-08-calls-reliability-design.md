# 1:1 voice & video calls — reliability, history, video polish

Date: 2026-10-08 · Repos: `bananatalk_app` (Flutter) + `language_exchange_backend_application` (Node) · Status: draft for review

## 1. Why

Measured in prod (2026-10-08): **1 of 30 calls answered in the last 30 days (3%)**; 0 answered Jul–Sep; 168 calls stuck `ringing` and 4 stuck `active`; **0 call messages in any conversation, ever**. Users report calls ring inconsistently and there is no call history in chat.

The audit found the cause is not one bug but a stack:

- The app uses the REST + LiveKit path (`controllers/callController.js`). The legacy socket path (`socket/callHandler.js`) holds the only timeout / busy / missed / chat-message logic, and the app never calls it.
- `CallManager.initialize()` binds listeners to `chatSocketService.socket` once (`call_manager.dart:133`); `ChatSocketService` replaces that socket on resume, token refresh and login, so the app goes deaf to `call:incoming`. Foreground `incoming_call` FCM is deliberately dropped (`notification_service.dart:426`).
- iOS CallKit is given the 24-hex Mongo id; `flutter_callkit_incoming` force-unwraps `UUID(uuidString:)` → crash when a call arrives while the app is inactive/backgrounded.
- Caller's screen freezes after decline / connection loss (`_cleanup()` without `onCallEnded`, `canPop:false`, End no-ops).
- Socket events don't check `callId`; no busy check → one call's timeout ends another.
- No server ring timeout, no `missed` status, no missed push; peer-drop never reaches the server.
- Accept/decline are emitted only to the caller → callee's other devices keep ringing.
- Android: no mic/camera foreground service (media stops in background), no full-screen-intent permission request, notification + CallKit duplicate UI; killed-state accept is lost and video joins as audio "Unknown".
- `Message.media.type` enum lacks `call` → the legacy chat message fails validation silently.
- `CallHistoryScreen` parses fields the API doesn't send → crash; it is not linked from navigation.
- Video: no wakelock (screen locks mid-video, iOS camera stops); 5-minute free-user cap enforced only on the receiving side (`incoming_call_screen.dart:150`), silently.
- `@parse/node-apn` is not in `package.json` (VoIP works in prod only because it was installed by hand).

## 2. Decisions

| Topic | Decision |
|---|---|
| Architecture | **Server-authoritative call state** on the existing REST + LiveKit path. Delete `socket/callHandler.js`. |
| Call history | **In-conversation call messages + a Calls list** (chat-tab header icon, missed badge). |
| Second incoming call | **Busy** (no call waiting). |
| Free-user 5-min cap | **Removed** for now (0 VIP subscribers, 3% answer rate). Revisit as a VIP perk once calls work. |
| Ring timeout | 45 s. |
| Peer reconnect grace | 20 s. |
| In scope extras | Decline with quick message; Call back / Message actions on missed-call push; Calls on/off + quiet hours; camera on mid voice call; draggable / swappable self-view. |
| Out of scope (follow-up spec) | Language-swap timer, scheduled calls, post-call summary, live captions, picture-in-picture, pre-answer camera preview, call waiting, group calls. |

## 3. Backend

### 3.1 State machine

```
initiate ─► ringing ─┬─ accept ─────────► active ── end / peer gone > 20 s ──► ended (completed)
                     ├─ decline ────────► rejected
                     ├─ caller cancel ──► missed   (endReason caller_cancelled)
                     └─ 45 s ───────────► missed   (endReason timeout)
initiate with either party in a live call, or callee has calls off ─► busy (409, never rings)
```

- Every transition is one atomic `findOneAndUpdate({ _id, status: <expected> })`. A transition whose precondition fails returns `409 CALL_STATE` with the current status (e.g. accept after cancel). Lives in a new `services/callStateService.js` used by the controller, the webhook and the sweeper; the controller keeps only HTTP concerns.
- "Live call" = `ringing` (younger than 60 s) or `active`, for either user.
- Add `caller_cancelled` and `unavailable` to `endReason`; add `callUuid` (UUID v4, unique), `seenByReceiverAt` (for the missed badge) to `Call`.

### 3.2 Timers and sweeps

- **Ring timeout:** in-process `setTimeout(45 s)` per call → `ringing → missed`. Cleared on any transition.
- **Sweeper job** (`jobs/callSweepJob.js`, every 60 s via `jobs/scheduler.js`): `ringing` older than 60 s → `missed`; `active` whose LiveKit room no longer exists (RoomService `listRooms`) or older than 4 h → `ended`. Covers restarts and the existing 168 + 4 stuck records (first run backfills them; they get no chat message and no push — `endReason: 'timeout'` with a `backfilled: true` flag).
- **LiveKit webhook** (`controllers/livekit.js`): `participant_left` for one party starts a 20 s grace; if that party has not rejoined, `active → ended (completed)`. `room_finished` → `ended`. Both now set `endReason`, `duration`, and emit events. Webhook must be configured in LiveKit Cloud (owner task) — the sweeper is the fallback when it is not.

### 3.3 Events (socket)

- Every transition emits to **both users' rooms** (`user_<caller>`, `user_<receiver>`), payload always includes `callId` and `callUuid`.
- Existing names kept for live builds: `call:incoming`, `call:accepted`, `call:declined`, `call:ended`. New: `call:busy` (to the caller), `call:missed` (to both). Old builds ignore unknown events.
- `GET /calls/current` returns the caller's or receiver's live call (ringing/active) or `null` — used by the app on resume and cold start.

### 3.4 Busy and Calls-off

- `initiateCall`: if caller or receiver has a live call, or the receiver has calls off / is in quiet hours → create a `busy` Call (`endReason: busy | unavailable`), return `409 CALLEE_BUSY` / `409 CALLEE_UNAVAILABLE` with the receiver's display name. Receiver gets a call message + a missed-call push only for `busy` (not for `unavailable`, which is the receiver's own choice).
- New user settings `callSettings: { allowCalls: true, quietHours: { enabled, start: 'HH:mm', end: 'HH:mm', tz } }` via the existing settings endpoint.

### 3.5 Call messages in the conversation

- On every terminal transition, `callStateService` writes **one** `Message` with `messageType: 'call'` into the conversation between the two users (creating the conversation if none exists), sender = caller, `call: { callId, type, outcome, duration }` where outcome ∈ `completed | missed | declined | busy | unavailable | cancelled`. Idempotent: unique index on `call.callId` (partial). Fix `Message.media.type`/schema so validation passes.
- Emitted through the normal new-message path so the chat list preview and unread count update. **No chat push** for call messages (the missed-call push covers it).
- **Decline with message:** `POST /calls/:id/decline` accepts optional `message` (≤ 200 chars) → after the call message, a normal text message from the receiver.

### 3.6 Push

- Incoming-call FCM: **data-only, high priority, TTL 45 s** (Android `ttl`, APNs `apns-expiration`), carries `callId`, `callUuid`, `callType`, caller name + avatar. Android no longer gets a `notification` block (CallKit renders the UI). iOS keeps VoIP push (PushKit) as primary; the FCM alert fallback also gets a 45 s expiry.
- VoIP push payload uses `callUuid` as the CallKit id.
- **Missed-call push** to the receiver on `missed` and `busy`: "Missed voice call from X", category/actions **Call back** and **Message**, deep link to the conversation.
- `@parse/node-apn` added to `package.json`.

### 3.7 History API

- `GET /calls` (paged, 30): includes `busy`; each item `{ id, callUuid, type, direction (in|out), outcome (per viewer: caller sees cancelled / no_answer, receiver sees missed), duration, otherParty { id, name, avatar }, createdAt }`.
- `GET /calls/missed/count` = receiver's `missed` + `busy` with `seenByReceiverAt` null. `POST /calls/missed/seen` sets it.

### 3.8 Removal

- Delete `socket/callHandler.js` and its registration; remove `call:initiate|answer|end` socket listeners. Grep confirms no app build emits them.
- Remove the free-user call-duration cap (none server-side today; app side in §4.6).

## 4. App

### 4.1 CallManager as a state follower

- One `currentCall` keyed by `callId`. Every socket/push/CallKit event whose `callId` ≠ `currentCall.callId` is ignored (except `call:incoming` when idle).
- **Single exit path** `_finish(reason)` for decline, missed, busy, unavailable, network loss, local/remote end: stop tracks, leave LiveKit, end CallKit by `callUuid`, stop ringback/ringtone, release wakelock + foreground service, fire `onCallEnded`, pop the call screen. The End button always closes the screen even if `currentCall` is already null.
- Caller outcome banner (1.5 s) before closing: "Declined", "No answer", "<name> is on another call", "<name> isn't taking calls right now", "Call ended · m:ss".

### 4.2 Reliable incoming

- `ChatSocketService` exposes `onSocketReplaced` (fires after every new socket instance is created); `CallManager` re-binds its listeners there.
- Foreground `incoming_call` FCM is handled; socket + push dedupe by `callId` → one incoming UI.
- On app resume and cold start: `GET /calls/current`; if ringing for me → show incoming UI; if active → rejoin.
- Tapping an old incoming-call notification: `GET /calls/:id` first; if not `ringing` → open the conversation instead.
- `IncomingCallScreen` closes on `call:ended|missed|declined` for its `callId` and after 50 s as a safety net.

### 4.3 CallKit / native

- CallKit id = `callUuid` everywhere (socket path, FCM path, `AppDelegate.swift` VoIP path).
- CallKit `extra` carries `callId`, `callUuid`, `callType`, caller name + avatar, LiveKit url/room (token fetched fresh on accept via `POST /calls/:id/accept`, which returns it).
- Cold start: after `runApp`, read `FlutterCallkitIncoming.activeCalls()`; an accepted call is joined, a declined one calls `/decline`.
- Decline-with-message: CallKit/Android incoming UI offers 2 canned replies + custom (l10n); sent via `/decline { message }`.
- `registerVoipToken` sends the real device id.

### 4.4 Android

- Foreground service with `microphone` (+ `camera` for video) types during a call; manifest permissions `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `FOREGROUND_SERVICE_CAMERA`.
- Request full-screen-intent permission (Android 14+) once, with an explainer, the first time the user has an incoming call or opens call settings.

### 4.5 Reconnect

- Peer disconnected → "Reconnecting…" overlay for up to 20 s; local network loss → same, LiveKit auto-reconnect. After 20 s → `POST /end` (best effort) + `_finish`.

### 4.6 Video and in-call

- Wakelock on for the whole call (video and voice), off in `_finish`.
- Proximity sensor screen-off for voice calls with the earpiece route.
- Leaving the app mid-video: camera unpublishes; the peer sees an avatar tile with "Camera paused"; republished on resume.
- **Camera on during a voice call:** camera button in voice calls; turning it on publishes video and switches the call to `type: video` locally for both (remote video tile appears). No server change needed beyond an optional `call:upgraded` event for analytics (not required).
- Draggable self-view snapping to corners; tap to swap big/small.
- Remove the client-side 5-minute cap (`_durationLimitTimer`, `setVipCall` callers).
- Fix `ActiveCallScreen` overwriting `onConnectionQualityChanged` (chain instead).

### 4.7 History UI

- **Conversation:** the existing `CallHistoryBubble` renders `messageType: 'call'`: direction + type icon, outcome text ("Voice call · 4:12", "Missed video call" red for the receiver, "Cancelled call", "Declined", "No answer"), time; tap = call back same type. Chat-list preview: "📞 Missed voice call" etc.
- **Calls list:** rebuild `CallHistoryScreen` against §3.7; entry = phone icon in the chat-tab app bar with the missed badge; rows: avatar, name, in/out/missed arrow (missed red), type, time, duration, trailing call-back button; tap row → conversation; paging 30; opening it calls `/calls/missed/seen`.
- **Call settings:** in Settings → Notifications: "Allow calls" toggle + quiet hours.

### 4.8 Live-build compatibility

Live 2.2.x / 2.6.1 builds keep working: event names unchanged, new fields additive. They render an unknown `messageType: 'call'` — verify what they show; if blank, the server adds a plain-text fallback field (`message`) such as "📞 Missed voice call" that old builds display.

## 5. Testing

- **Backend (node:test + harness):** each transition; accept-after-cancel → 409; simultaneous mutual calls → one busy; ring timeout → missed + one message + push; sweeper backfill (no message/push); webhook grace; exactly one call message per call (retry-safe); events reach both rooms; Calls-off / quiet hours → unavailable; decline with message; history outcomes per viewer; missed count/seen.
- **App (flutter test):** event for another `callId` ignored; every exit reason runs `_finish` once and pops the screen; listeners survive socket replacement; socket + push dedupe; resume recovery via `/calls/current`; stale notification tap opens chat; bubble outcomes; Calls list parsing + badge; cap removed.
- **Device QA:** `docs/qa/calls-matrix.md` — {iOS, Android 13+, Android 8} × {foreground, background, killed, after resume} × {voice, video} × {wifi, cellular}, plus decline-with-message, busy, calls off, multi-device, wifi↔cellular switch mid-call, screen stays on, camera paused/resumed.

## 6. Rollout

1. Backend first (safe for live builds): stops stuck calls, starts call messages + missed pushes. Owner: configure the LiveKit webhook URL; confirm `APNS_VOIP_*` present after deploy (`[voipPush] initialised` in logs).
2. App release with §4.
3. Success metric, measured from prod one week after the app release: answered rate ≥ 40% of initiated calls (baseline 3%); stuck `ringing`/`active` = 0; call messages present for 100% of terminal calls.
