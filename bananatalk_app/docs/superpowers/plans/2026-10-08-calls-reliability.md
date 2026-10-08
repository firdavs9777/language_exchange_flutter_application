# Calls Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make 1:1 voice/video calls ring, connect, end and get recorded reliably (answered rate from 3% to ≥ 40% of initiated calls; zero stuck `ringing`/`active` rows; a call message for every terminal call that §3 marks "yes"), without breaking live builds 2.2.x / 2.6.1. Phase 2 adds the approved extras.

**Architecture:** The backend becomes the single authority for call state: every transition is one conditional `findOneAndUpdate` in `services/callStateService.js`, busy is an atomic per-user `activeCallId` claim, and one effects module (`services/callEffects.js`) fans each transition out to socket events (legacy audiences kept + new `call:state`), one idempotent call message, and pushes. A 45 s in-process ring timer, a LiveKit-webhook 20 s grace and a 60 s sweeper close everything that a client never closes. The app's `CallManager` becomes a follower of `call:state` keyed by `callId`, with one exit path `_finish()`, injected API/platform/LiveKit seams for tests, re-binding on socket replacement, push/socket dedupe and CallKit keyed by `callUuid`.

**Tech Stack:** Backend — Node 20 / Express 4, socket.io 4, Mongoose 6, firebase-admin 13, `@parse/node-apn`, `livekit-server-sdk` 2, `node:test` + `mongodb-memory-server`. App — Flutter 3.24+, Riverpod 2, `livekit_client` 2.7, `flutter_callkit_incoming` 2.5.8, `socket_io_client` 2.0.3, `firebase_messaging` 15, new `wakelock_plus` (direct), `flutter_foreground_task` 9, `fake_async` (dev).

**Spec:** `docs/superpowers/specs/2026-10-08-calls-reliability-design.md` (rev 3.1, approved)

## Global Constraints

- Ring timeout **45 s** (server `timing.ringTimeoutMs = 45000`); the client never times out a call on its own except the 50 s safety nets below.
- Reconnect grace **20 s** — server (`timing.reconnectGraceMs = 20000`, webhook + sweeper) and app (`kReconnectGrace`, overlay then `POST /end`).
- A `ringing` call is **stale after 60 s** (`timing.staleRingingMs = 60000`): it no longer makes anyone busy, cannot be accepted, and the sweeper closes it as `missed/timeout`.
- Active cap **4 h** (`timing.activeCapMs = 14400000`) — the sweeper ends any longer call even when LiveKit cannot be reached.
- App safety nets: `IncomingCallScreen` closes after **50 s**; an outgoing call with no `call:state` re-checks `GET /calls/:id` after **50 s**; caller outcome banner shows **1.5 s**.
- Incoming-call push expiry **45 s** everywhere: Android `ttl: 45000`, APNs `apns-expiration = now + 45`, VoIP `note.expiry = now + 45`.
- Stored `outcome` values (derived by `outcomeFor(call)`, never persisted): `completed` (ended), `no_answer` (missed/timeout), `cancelled` (missed/caller_cancelled), `declined` (rejected), `busy` (busy/busy). `busy/unavailable`, `failed/failed` and anything `backfilled: true` → `null` → no message, no push.
- Legacy `callData.status`: `missed` for `no_answer|cancelled|busy`, `rejected` for `declined`, `ended` for `completed`.
- `media.callData` is exactly the superset `{ _id, callId, callUuid, initiator, participants: [], type, startTime, duration, status, outcome }`; `_id === callId === String(call._id)`, `initiator` is a string, `duration` is an **integer** number of seconds.
- Event audiences: `call:incoming` → receiver room; `call:accepted` / `call:declined` → caller room only; `call:ended` → both rooms on `ended` **and on `missed`**; `call:state` → both rooms on every transition, payload `{ callId, callUuid, status, outcome, endReason, duration, type, by }`. Every payload carries `callId` and `callUuid`. Rooms are `user_<id>`.
- In-call relays kept (moved to `socket/callRelayHandler.js`, participant-checked): `call:mute`, `call:video-toggle`, `call:reconnecting` → `call:peer-reconnecting`, `call:reconnected` → `call:peer-reconnected`, `call:failed`.
- Live-build compatibility: existing event names keep audience and meaning; `/calls/:id/*` accept the Mongo `_id` **or** the `callUuid`, case-insensitively; VoIP `id` = `callUuid`, `extra.callId` = Mongo id; `callData` stays readable by `CallRecord.fromJson` (`messages_list.dart:255`).
- `call_cancelled` push `{ type: 'call_cancelled', callId, callUuid }` on every exit from `ringing`, only to tokens whose `capabilities` include `call_cancel` (iOS VoIP **and** Android FCM — see Review Focus / contradiction #2), never to the token whose `deviceId` equals the acting request's `deviceId`; a missing `deviceId` excludes nobody.
- Missed-call push only for `no_answer`, `cancelled`, `busy`; **no chat push** for call messages.
- Busy is atomic: `User.activeCallId`, conditional claims in ascending user-id order, released on every terminal transition only when it still points at this call.
- App: `package:` imports only under `lib/` (linter `always_use_package_imports`); relative imports only for `test/helpers`.
- Every commit in either repo updates that repo's `docs/REMAINING_WORK.md` in the same commit (tick what it finishes, keep open items), lists what is still open in the commit body, and ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Backend tests run one file at a time from `/Users/davis/Desktop/Personal/language_exchange_backend_application`: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js <file>` (plain `npm test` dies under Node 25).
- App tests run from `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`: `flutter test <file>`; after any `.arb` change run `flutter gen-l10n`.

## Review Focus

1. **Uppercase UUIDs** — iOS reports CallKit ids as `UUID.uuidString` (uppercase); the server stores `callUuid` lowercase. Expected: `POST /calls/<UPPERCASE-UUID>/accept` resolves the call; the app compares CallKit ids case-insensitively. Tests: Task B2 (`findCall`), Task B6 (route), Task A3 (`CallKitIds.same`), Task A7 (cold-start entry with uppercase id).
2. **Accept/decline without `deviceId`** (every live build) — Expected: `call_cancelled` goes to every capable device; `undefined === undefined` must never exclude all tokens. Test: Task B5.
3. **Call messages vs the first-chat 5-message limit** — a caller who rang 5 times unanswered must still be able to text. Expected: `messageType: 'call'` rows are not counted on any send path. Test: Task B4.
4. **LiveKit admin errors are "unknown", not "empty room"** — unset env, network error or 5xx from `listParticipants`. Expected: neither the webhook grace nor the sweeper ends a call on them (only `not_found` or a real count < 2 does); the 4 h cap still applies. Tests: Task B7, Task B8.
5. **Lost ring timer / dangling busy claim** (process restart, deleted Call) — Expected: accepting a `ringing` call older than 60 s returns `409 CALL_STATE {status:'missed'}` and finalizes it (message + missed push) instead of creating an active call; an `activeCallId` that points at a stale or missing Call never keeps a user busy. Test: Task B2.

---

## File Structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

| File | Responsibility |
|---|---|
| `models/Call.js` (modify) | `callUuid` (lowercase, partial unique), `seenByReceiverAt`, `backfilled`, `underfilledSince`, `endReason` + `caller_cancelled`, `unavailable`; sweeper index |
| `models/User.js` (modify) | `activeCallId`; `capabilities` on `fcmTokens[]` and `voipTokens[]` |
| `models/Message.js` (modify) | `media.type` + `call`; partial unique index on `media.callData.callId` |
| `migrations/addCallIndexes.js` (create) | creates the three new indexes on prod (`npm run migrate:call-indexes`) |
| `lib/callIo.js` (create) | process-wide `setIo`/`getIo` so services, webhook and jobs can emit |
| `lib/pushCapabilities.js` (create) | `parseCapabilities(raw)` whitelist for token registration |
| `services/callStateService.js` (create) | state machine, `transition()`, `startCall()`, claims, ring timer, `outcomeFor`, id-or-uuid lookup |
| `services/callEffects.js` (create) | `afterTransition(call, ctx)`: events → message → pushes |
| `services/callEvents.js` (create) | legacy + `call:state` emits with the audiences above |
| `services/callMessageService.js` (create) | one idempotent call `Message` via the first-message conversation path |
| `services/callPushService.js` (create) | incoming (data-only, 45 s), VoIP payload, `call_cancelled`, missed push |
| `services/callLivenessService.js` (create) | LiveKit webhook: 20 s grace, `room_finished` |
| `services/livekitAdminService.js` (modify) | `countParticipants(roomName)` → `{ ok, count, missing }` |
| `services/voipPushService.js` (modify) | 45 s expiry, token filter, stubbable `send` |
| `services/fcmService.js` (modify) | export `sanitizeData`, `handleFailedTokens` |
| `services/callService.js` (modify) | history items, missed count/seen, current call |
| `controllers/callController.js` (modify) | HTTP only: initiate/accept/decline/end/current/history/missed |
| `controllers/livekit.js` (modify) | delegates `call:` rooms to `callLivenessService` |
| `controllers/notifications.js` (modify) | store `capabilities` on FCM and VoIP tokens |
| `routes/calls.js` (modify) | `/current`, `/missed/seen` before `/:id` |
| `jobs/callSweepJob.js` (create), `jobs/scheduler.js` (modify) | 60 s sweeper + legacy backfill |
| `socket/callRelayHandler.js` (create), `socket/socketHandler.js` (modify), `socket/callHandler.js` (delete) | slim relays |
| `socket/socketGuards.js`, `socket/socketHandler.js`, `controllers/messages.js` (modify) | first-chat count ignores call messages |
| `notification_templates/*.json` (modify, 19) | `missed_call_audio`, `missed_call_video` |
| `server.js` (modify) | `setIo(io)` |
| `package.json` (modify) | `@parse/node-apn`, `migrate:call-indexes` |
| `test/helpers/callKit.js` (create) | in-memory Mongo, users, fake io, controller runner |

### App (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

| File | Responsibility |
|---|---|
| `lib/l10n/app_*.arb` (modify, 19) | Phase 1 call strings |
| `lib/models/call_outcome.dart` (create) | `CallOutcome`, `CallLabels`, `formatCallDuration`, `callPreviewText` |
| `lib/models/call_record_model.dart` (modify) | `outcome`/`callUuid` on `CallRecord`; `CallLogEntry` for `GET /calls` |
| `lib/models/call_model.dart` (modify) | `callUuid`; `callerAvatar` alias |
| `lib/services/call/call_api.dart` (create) | `CallApi`, `RestCallApi`, `CallApiResult` |
| `lib/services/call/call_platform.dart` (create) | `CallPlatform`, `DeviceCallPlatform` (CallKit, tones, permissions, wakelock, FGS) |
| `lib/services/call/callkit_ids.dart` (create) | `CallKitIds`, `CallKitEntry` |
| `lib/services/call/call_routes.dart` (create) | named call routes, open/close |
| `lib/services/call/call_push_handler.dart` (create) | foreground FCM `incoming_call` / `call_cancelled` routing |
| `lib/services/call/call_launcher.dart` (create) | one place that starts a call and shows busy/errors |
| `lib/services/call/call_foreground_service.dart` (create) | Android microphone/camera foreground service |
| `lib/services/call/full_screen_intent_prompt.dart` (create) | Android 14+ full-screen-intent explainer, once |
| `lib/services/call_manager.dart` (rewrite) | follower state machine, `_finish`, dedupe, recovery |
| `lib/services/chat_socket_service.dart` (modify) | `onSocketReplaced` |
| `lib/services/callkit_service.dart` (modify) | `callUuid` ids, `extra`, entries |
| `lib/services/notification_service.dart`, `notification_router.dart`, `notification_api_client.dart` (modify) | call pushes, stale taps, capabilities |
| `lib/services/call_history_service.dart` (rewrite), `lib/providers/missed_calls_provider.dart` (create) | Calls list data + badge |
| `lib/providers/call_provider.dart`, `lib/main.dart`, `lib/services/session_activities.dart` (modify) | new manager API |
| `lib/screens/incoming_call_screen.dart`, `active_call_screen.dart`, `call_history_screen.dart` (modify/rewrite) | UI |
| `lib/widgets/call/call_history_bubble.dart`, `lib/pages/chat/...` (modify) | bubble, previews, app-bar icon |
| `ios/Runner/AppDelegate.swift`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml` (modify) | native |
| `docs/qa/calls-matrix.md` (create) | device QA matrix |
| `test/helpers/call_fakes.dart` (create) | `FakeCallApi`, `FakeCallPlatform`, `FakeLiveKit`, `CallHarness` |

---

# Phase 1 — Backend

All backend commands run from `/Users/davis/Desktop/Personal/language_exchange_backend_application`.

### Task B1: Schemas, indexes, migration, `@parse/node-apn`

**Files:**
- Modify: `models/Call.js` (whole file, 54 lines)
- Modify: `models/User.js` (`fcmTokens` 86-107, `voipTokens` 134-139)
- Modify: `models/Message.js` (`media.type` enum line 83; indexes after line 598)
- Create: `migrations/addCallIndexes.js`
- Modify: `package.json` (dependencies, scripts)
- Modify: `docs/REMAINING_WORK.md`
- Create: `test/helpers/callKit.js`
- Test: `test/callSchema.test.js`

**Interfaces:**
- Consumes: nothing new.
- Produces: `Call.callUuid: String (lowercase)`, `Call.seenByReceiverAt: Date|null`, `Call.backfilled: Boolean`, `Call.underfilledSince: Date|null`, `Call.endReason ∈ {..., 'caller_cancelled', 'unavailable'}`; `User.activeCallId: ObjectId|null`; `fcmTokens[].capabilities: [String]`, `voipTokens[].capabilities: [String]`; `Message.media.type ∈ {..., 'call'}`; indexes `call_uuid_unique`, `call_status_start`, `call_message_unique`; test helpers `startDb(dbName)`, `stopDb()`, `makeUser(name, extra)`, `fakeIo()` → `{ sent: [{rooms, event, payload}], to(room) }`, `asHandler(fn)(req)` → `{status, body|error, code}`, `silence()` → `restore()`.

- [ ] **Step 1: Write the failing test**

Create `test/helpers/callKit.js`:

```js
'use strict';

/**
 * Shared kit for the calls test files: in-memory Mongo, users, a fake socket.io
 * that records every emit with the rooms it targeted, and a runner that calls
 * an asyncHandler controller with a fake req/res.
 */

process.env.JWT_SECRET = process.env.JWT_SECRET && process.env.JWT_SECRET.length >= 32
  ? process.env.JWT_SECRET
  : 'test-secret-that-is-long-enough-to-pass-0123456789';

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod = null;

async function startDb(dbName) {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName });
}

async function stopDb() {
  await mongoose.disconnect();
  if (mongod) await mongod.stop();
}

function makeUser(name, extra = {}) {
  const User = require('../../models/User');
  return User.create({
    name,
    email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
    password: 'not-a-real-hash-0123456789',
    birth_year: '2000', birth_month: '1', birth_day: '1',
    gender: 'other', native_language: 'English', language_to_learn: 'Korean',
    ...extra,
  });
}

/** socket.io stand-in: io.to(a).to(b).emit(e, p) records { rooms: [a, b], event: e, payload: p }. */
function fakeIo() {
  const sent = [];
  const chain = (rooms) => ({
    to: (room) => chain([...rooms, room]),
    emit: (event, payload) => { sent.push({ rooms, event, payload }); return true; },
  });
  return {
    sent,
    to: (room) => chain([room]),
    in: () => ({ fetchSockets: async () => [] }),
    eventsNamed: (event) => sent.filter((s) => s.event === event),
  };
}

/** Run an asyncHandler-wrapped controller and resolve with what it answered. */
const asHandler = (fn) => (req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  const out = fn(req, res, (err) => (err
    ? resolve({ status: err.statusCode || 500, error: err.message, code: err.errorCode || null })
    : resolve({ status: 204 })));
  if (out && typeof out.catch === 'function') out.catch(reject);
});

/** Mute console noise; returns the restore function. */
function silence() {
  const saved = { log: console.log, error: console.error, warn: console.warn };
  console.log = () => {}; console.error = () => {}; console.warn = () => {};
  return () => { console.log = saved.log; console.error = saved.error; console.warn = saved.warn; };
}

module.exports = { startDb, stopDb, makeUser, fakeIo, asHandler, silence };
```

Create `test/callSchema.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { startDb, stopDb, makeUser, silence } = require('./helpers/callKit');

let restore, Call, Message;

test.before(async () => {
  restore = silence();
  await startDb('callSchema');
  Call = require('../models/Call');
  Message = require('../models/Message');
  await Promise.all([Call.syncIndexes(), Message.syncIndexes()]);
});
test.after(async () => { await stopDb(); restore(); });

test('Call.callUuid is lowercased, unique when present, optional for legacy rows', async () => {
  const a = await makeUser('a'); const b = await makeUser('b');
  const base = { participants: [a._id, b._id], initiator: a._id, type: 'audio' };
  const c1 = await Call.create({ ...base, callUuid: 'AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE' });
  assert.equal(c1.callUuid, 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee');
  await assert.rejects(
    Call.create({ ...base, callUuid: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee' }),
    (err) => err.code === 11000,
  );
  // Legacy rows have no callUuid at all; the partial index must not collide them.
  await Call.create(base);
  await Call.create(base);
});

test('Call accepts the new endReasons and bookkeeping fields with safe defaults', async () => {
  const a = await makeUser('c'); const b = await makeUser('d');
  const base = { participants: [a._id, b._id], initiator: a._id, type: 'video' };
  const fresh = await Call.create(base);
  assert.equal(fresh.backfilled, false);
  assert.equal(fresh.seenByReceiverAt, null);
  assert.equal(fresh.underfilledSince, null);
  for (const endReason of ['caller_cancelled', 'unavailable', 'timeout', 'completed']) {
    const c = await Call.create({ ...base, status: 'missed', endReason });
    assert.equal(c.endReason, endReason);
  }
});

test('Message media.type "call" validates; callData.callId is unique only when present', async () => {
  const a = await makeUser('e'); const b = await makeUser('f');
  const callId = new mongoose.Types.ObjectId().toString();
  const doc = {
    sender: a._id, receiver: b._id, message: '📞 Missed voice call', messageType: 'call',
    media: { type: 'call', callData: { _id: callId, callId } },
  };
  await Message.create(doc);
  await assert.rejects(Message.create(doc), (err) => err.code === 11000);
  await Message.create({ sender: a._id, receiver: b._id, message: 'hi' });
  await Message.create({ sender: a._id, receiver: b._id, message: 'hi again' });
});

test('User.activeCallId defaults to null; token capabilities default to []', async () => {
  const u = await makeUser('g', {
    fcmTokens: [{ token: 't', platform: 'android', deviceId: 'd1' }],
    voipTokens: [{ token: 'v', deviceId: 'd1' }],
  });
  assert.equal(u.activeCallId, null);
  assert.deepEqual([...u.fcmTokens[0].capabilities], []);
  assert.deepEqual([...u.voipTokens[0].capabilities], []);
});

test('package.json declares @parse/node-apn (VoIP only worked because it was hand-installed)', () => {
  const pkg = require('../package.json');
  assert.ok(pkg.dependencies['@parse/node-apn']);
  assert.equal(pkg.scripts['migrate:call-indexes'], 'node migrations/addCallIndexes.js');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callSchema.test.js`
Expected: FAIL — `callUuid` is not lowercased (`undefined !== 'aaaaaaaa-…'`), `endReason` `caller_cancelled` rejected by the enum validator, `media.type` `call` rejected (`` `call` is not a valid enum value ``), `activeCallId` undefined, `@parse/node-apn` missing.

- [ ] **Step 3: Implement**

Replace `models/Call.js` with:

```js
const mongoose = require('mongoose');

const callSchema = new mongoose.Schema({
  participants: [
    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }
  ],
  type: { type: String, enum: ['audio', 'video'], required: true },
  status: {
    type: String,
    enum: ['ringing', 'active', 'ended', 'missed', 'rejected', 'failed', 'busy'],
    default: 'ringing'
  },
  initiator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  // CallKit-safe id (UUID v4). The Mongo id is 24 hex and crashes
  // flutter_callkit_incoming's UUID(uuidString:)! on iOS. Absent on rows
  // created before 2026-10 — the sweeper uses that to backfill them.
  callUuid: { type: String, lowercase: true, trim: true },
  startTime: { type: Date, default: Date.now },
  answeredAt: { type: Date },
  endTime: { type: Date },
  // Whole seconds from answeredAt to endTime; 0 if never answered.
  duration: { type: Number, default: 0 },
  endReason: {
    type: String,
    enum: [
      'completed', 'caller_ended', 'receiver_ended', 'missed', 'rejected', 'failed',
      'busy', 'timeout', 'disconnect', 'caller_cancelled', 'unavailable'
    ]
  },
  // Set when the receiver opens the Calls list (POST /calls/missed/seen).
  seenByReceiverAt: { type: Date, default: null },
  // Closed by the sweeper's one-time backfill: no message, no push, no history.
  backfilled: { type: Boolean, default: false },
  // First sweep that saw fewer than 2 LiveKit participants on an active call.
  underfilledSince: { type: Date, default: null }
}, {
  timestamps: true
});

callSchema.index({ participants: 1, createdAt: -1 });
callSchema.index({ initiator: 1, createdAt: -1 });
callSchema.index({ status: 1 });
callSchema.index({ createdAt: -1 });
callSchema.index({ status: 1, startTime: 1 }, { name: 'call_status_start' });
callSchema.index(
  { callUuid: 1 },
  { name: 'call_uuid_unique', unique: true, partialFilterExpression: { callUuid: { $exists: true } } }
);

module.exports = mongoose.model('Call', callSchema);
```

In `models/User.js`, inside the `fcmTokens` item after the `active` field (line ~106), add:

```js
    // What this build understands beyond the basics; old builds send nothing
    // and get []. 'call_cancel' gates the data-only call_cancelled push: a
    // live 2.x build shows a blank "Bananatalk" banner for any unknown
    // foreground push (notification_service.dart _showLocalNotification).
    capabilities: { type: [String], default: [] },
```

Inside the `voipTokens` item after `active` (line ~138), add:

```js
    // 'call_cancel' = this AppDelegate ends (instead of rings) a call_cancelled
    // VoIP push. Live builds would ring "Unknown" for it, so they never get one.
    capabilities: { type: [String], default: [] }
```

Right after the closing `}],` of `voipTokens` (line ~139), add:

```js
  // The call that currently makes this user busy (ringing < 60 s, or active).
  // Written only by services/callStateService.js with conditional updates so
  // two simultaneous calls can never both win.
  activeCallId: { type: mongoose.Schema.Types.ObjectId, ref: 'Call', default: null },
```

In `models/Message.js` change the `media.type` enum (line 83) from

```js
      enum: ['image', 'video', 'document', 'audio', 'voice', 'location', null]
```

to

```js
      enum: ['image', 'video', 'document', 'audio', 'voice', 'location', 'call', null]
```

and after the last `MessageSchema.index(...)` (line 598) add:

```js
// One call message per call, whatever retries or racing sweeps do.
MessageSchema.index(
  { 'media.callData.callId': 1 },
  { name: 'call_message_unique', unique: true, partialFilterExpression: { 'media.callData.callId': { $exists: true } } }
);
```

Create `migrations/addCallIndexes.js`:

```js
/**
 * Migration: indexes for server-authoritative calls.
 *
 * Run with: npm run migrate:call-indexes   (safe to re-run)
 *
 *  - calls.call_uuid_unique     partial unique on callUuid (legacy rows have none)
 *  - calls.call_status_start    the sweeper's { status, startTime } scan
 *  - messages.call_message_unique  partial unique on media.callData.callId:
 *    one call message per call, enforced by the database
 */
const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', 'config', 'config.env') });

const run = async () => {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;
  await db.collection('calls').createIndex(
    { callUuid: 1 },
    { name: 'call_uuid_unique', unique: true, partialFilterExpression: { callUuid: { $exists: true } } }
  );
  await db.collection('calls').createIndex({ status: 1, startTime: 1 }, { name: 'call_status_start' });
  await db.collection('messages').createIndex(
    { 'media.callData.callId': 1 },
    { name: 'call_message_unique', unique: true, partialFilterExpression: { 'media.callData.callId': { $exists: true } } }
  );
  console.log('✅ call indexes ensured');
  await mongoose.disconnect();
};

run().catch((err) => {
  console.error('❌ addCallIndexes failed:', err.message);
  process.exit(1);
});
```

Declare the APNs dependency and the script:

```bash
npm install --save @parse/node-apn
npm pkg set scripts.migrate:call-indexes="node migrations/addCallIndexes.js"
```

(`services/voipPushService.js` uses only `new apn.Provider({ token, production })`, `new apn.Notification()` and `provider.send(note, token)`, which every published major of `@parse/node-apn` keeps.)

In `docs/REMAINING_WORK.md`, insert after the "Auth audit" section:

```markdown
## Calls reliability (2026-10-08) — plan `bananatalk_app/docs/superpowers/plans/2026-10-08-calls-reliability.md`

- [x] B1 schemas + indexes + `@parse/node-apn` declared in package.json
- [ ] B2 server-authoritative state machine + atomic busy (`activeCallId`)
- [ ] B3 events: legacy audiences kept + `call:state`
- [ ] B4 call messages in the conversation (+ first-chat limit ignores them)
- [ ] B5 pushes: data-only 45 s incoming, VoIP id = callUuid, `call_cancelled`, missed-call push
- [ ] B6 REST: busy / caller-busy, id-or-uuid, conversation cap at initiate, `GET /calls/current`
- [ ] B7 LiveKit webhook 20 s grace
- [ ] B8 60 s sweeper + backfill of the 168 ringing / 4 active legacy rows
- [ ] B9 history API + missed count/seen
- [ ] B10 slim relay handler; legacy `socket/callHandler.js` deleted
- [ ] Owner, after deploy: `npm run migrate:call-indexes` on prod; LiveKit Cloud webhook URL → `https://<api>/api/v1/livekit/webhook`; confirm `[voipPush] initialised` in prod logs
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callSchema.test.js`
Expected: 5 pass, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add models/Call.js models/User.js models/Message.js migrations/addCallIndexes.js package.json package-lock.json test/helpers/callKit.js test/callSchema.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): schemas for server-authoritative calls

Call gets a lowercase callUuid (partial unique), seenByReceiverAt,
backfilled, underfilledSince and the caller_cancelled / unavailable end
reasons. User gets activeCallId (atomic busy) and push-token capabilities.
Message accepts media.type 'call' with one message per callData.callId.
@parse/node-apn is finally a declared dependency; migrations/addCallIndexes.js
creates the indexes on prod.

Still open (calls): B2-B10; owner: migrate:call-indexes on prod, LiveKit
webhook URL, confirm [voipPush] initialised.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task B2: `callStateService` — atomic transitions, busy claims, ring timer

**Files:**
- Create: `lib/callIo.js`
- Create: `services/callStateService.js`
- Create: `services/callEffects.js` (no-op; filled by B3–B5)
- Modify: `server.js:191`
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callStateService.test.js`

**Interfaces:**
- Consumes: B1 schema fields.
- Produces:
  - `lib/callIo.js`: `setIo(io)`, `getIo() → io|null`.
  - `services/callStateService.js`: `timing { ringTimeoutMs: 45000, staleRingingMs: 60000, reconnectGraceMs: 20000, activeCapMs: 14400000 }` (mutable for tests); `TERMINAL_STATUSES`; `class CallStateError extends Error { code: 'CALL_STATE', status }`; `callQueryFor(idOrUuid) → {_id}|{callUuid}|null`; `findCall(idOrUuid) → Promise<Call|null>`; `receiverOf(call) → ObjectId`; `roomNameFor(id) → 'call:<id>'`; `isLiveCall(call, nowMs) → bool`; `outcomeFor(call) → 'completed'|'no_answer'|'cancelled'|'declined'|'busy'|null`; `claimUser(userId, callId, nowMs) → Promise<bool>`; `claimPair(callerId, receiverId, callId, nowMs) → Promise<{ok:true}|{ok:false, busyUser:'caller'|'receiver'}>`; `releaseUsers(call)`; `transition(callId, action, { by, deviceId, now }) → Promise<Call>` with `action ∈ accept|decline|cancel|timeout|end|fail`, throws `CallStateError`; `startCall({ callerId, receiverId, type, now }) → Promise<{call}|{busy:'caller'}|{busy:'receiver', call}>`; `scheduleRingTimeout(callId, ms)`, `clearRingTimer(callId)`.
  - `services/callEffects.js`: `afterTransition(call, ctx)` where `ctx = { action, from, by, deviceId }`.

- [ ] **Step 1: Write the failing test**

Create `test/callStateService.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { startDb, stopDb, makeUser, silence } = require('./helpers/callKit');

let restore, svc, Call, User;

test.before(async () => {
  restore = silence();
  await startDb('callState');
  svc = require('../services/callStateService');
  Call = require('../models/Call');
  User = require('../models/User');
  await Call.syncIndexes();
});
test.after(async () => { await stopDb(); restore(); });

const pair = async () => [await makeUser('caller'), await makeUser('callee')];
const start = async (a, b, type = 'audio') => {
  const res = await svc.startCall({ callerId: a._id, receiverId: b._id, type });
  if (res.call) svc.clearRingTimer(res.call._id);
  return res;
};
const activeCallIdOf = async (u) => (await User.findById(u._id).select('activeCallId')).activeCallId;

test('startCall: ringing call, lowercase v4 callUuid, both users claimed', async () => {
  const [a, b] = await pair();
  const { call } = await start(a, b);
  assert.equal(call.status, 'ringing');
  assert.match(call.callUuid, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  assert.equal(String(await activeCallIdOf(a)), String(call._id));
  assert.equal(String(await activeCallIdOf(b)), String(call._id));
});

test('findCall resolves the Mongo id, the uuid, and the UPPERCASE uuid (iOS)', async () => {
  const [a, b] = await pair();
  const { call } = await start(a, b);
  assert.equal(String((await svc.findCall(String(call._id)))._id), String(call._id));
  assert.equal(String((await svc.findCall(call.callUuid))._id), String(call._id));
  assert.equal(String((await svc.findCall(call.callUuid.toUpperCase()))._id), String(call._id));
  assert.equal(await svc.findCall('not-an-id'), null);
});

test('double accept: exactly one wins, the other gets CALL_STATE active', async () => {
  const [a, b] = await pair();
  const { call } = await start(a, b);
  const results = await Promise.allSettled([
    svc.transition(call._id, 'accept', { by: b._id }),
    svc.transition(call._id, 'accept', { by: b._id }),
  ]);
  assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
  const loser = results.find((r) => r.status === 'rejected').reason;
  assert.ok(loser instanceof svc.CallStateError);
  assert.equal(loser.status, 'active');
});

test('accept vs timeout race: one winner, the loser sees the winner state', async () => {
  const [a, b] = await pair();
  const { call } = await start(a, b);
  const results = await Promise.allSettled([
    svc.transition(call._id, 'accept', { by: b._id }),
    svc.transition(call._id, 'timeout', { by: 'system' }),
  ]);
  assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
  const final = await Call.findById(call._id);
  assert.ok(['active', 'missed'].includes(final.status));
});

test('accept after caller cancel → CALL_STATE missed', async () => {
  const [a, b] = await pair();
  const { call } = await start(a, b);
  await svc.transition(call._id, 'cancel', { by: a._id });
  await assert.rejects(svc.transition(call._id, 'accept', { by: b._id }),
    (err) => err instanceof svc.CallStateError && err.status === 'missed');
  const final = await Call.findById(call._id);
  assert.equal(final.endReason, 'caller_cancelled');
});

test('end: integer duration from answeredAt; both claims released', async () => {
  const [a, b] = await pair();
  const { call } = await start(a, b);
  const t0 = new Date();
  await svc.transition(call._id, 'accept', { by: b._id, now: t0 });
  const ended = await svc.transition(call._id, 'end', { by: a._id, now: new Date(t0.getTime() + 61600) });
  assert.equal(ended.status, 'ended');
  assert.equal(ended.endReason, 'completed');
  assert.equal(ended.duration, 61);
  assert.ok(Number.isInteger(ended.duration));
  assert.equal(await activeCallIdOf(a), null);
  assert.equal(await activeCallIdOf(b), null);
});

test('Review focus 5: accepting a ringing call older than 60 s → 409 missed and the call is finalized', async () => {
  const [a, b] = await pair();
  const old = new Date(Date.now() - 70 * 1000);
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio', now: old });
  svc.clearRingTimer(call._id);
  await assert.rejects(svc.transition(call._id, 'accept', { by: b._id }),
    (err) => err instanceof svc.CallStateError && err.status === 'missed');
  const final = await Call.findById(call._id);
  assert.equal(final.status, 'missed');
  assert.equal(final.endReason, 'timeout');
  assert.equal(await activeCallIdOf(b), null);
});

test('Review focus 5: a dangling or stale activeCallId never keeps a user busy', async () => {
  const [a, b] = await pair();
  await User.updateOne({ _id: b._id }, { $set: { activeCallId: new mongoose.Types.ObjectId() } }); // Call deleted
  const first = await start(a, b);
  assert.ok(first.call, 'deleted holder must not block');
  await svc.transition(first.call._id, 'cancel', { by: a._id });

  const [c, d] = await pair();
  const stale = await svc.startCall({ callerId: c._id, receiverId: d._id, type: 'audio', now: new Date(Date.now() - 61 * 1000) });
  svc.clearRingTimer(stale.call._id);
  const [e] = [await makeUser('e')];
  const second = await start(e, d);
  assert.ok(second.call, 'a ringing call older than 60 s is stale and must not block');
});

test('caller busy: no Call record is created', async () => {
  const [a, b] = await pair();
  const c = await makeUser('third');
  const { call } = await start(a, b);
  await svc.transition(call._id, 'accept', { by: b._id });
  const before = await Call.countDocuments();
  const res = await svc.startCall({ callerId: a._id, receiverId: c._id, type: 'audio' });
  assert.deepEqual(res, { busy: 'caller' });
  assert.equal(await Call.countDocuments(), before);
});

test('callee busy: a busy/busy record, the caller claim released, nobody rings', async () => {
  const [a, b] = await pair();
  const c = await makeUser('third');
  const { call } = await start(a, b);
  await svc.transition(call._id, 'accept', { by: b._id });
  const res = await svc.startCall({ callerId: c._id, receiverId: b._id, type: 'video' });
  assert.equal(res.busy, 'receiver');
  assert.equal(res.call.status, 'busy');
  assert.equal(res.call.endReason, 'busy');
  assert.equal(svc.outcomeFor(res.call), 'busy');
  assert.equal(await activeCallIdOf(c), null);
  assert.equal(String(await activeCallIdOf(b)), String(call._id));
});

test('mutual simultaneous calls: exactly one rings', async () => {
  for (let i = 0; i < 5; i++) {
    const [a, b] = await pair();
    const [r1, r2] = await Promise.all([
      svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio' }),
      svc.startCall({ callerId: b._id, receiverId: a._id, type: 'audio' }),
    ]);
    for (const r of [r1, r2]) if (r.call) svc.clearRingTimer(r.call._id);
    const ringing = [r1, r2].filter((r) => r.call && r.call.status === 'ringing');
    assert.equal(ringing.length, 1, `round ${i}: ${JSON.stringify([r1.busy, r2.busy])}`);
  }
});

test('ring timer: ringing → missed/timeout and claims released', async () => {
  const [a, b] = await pair();
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio' });
  svc.scheduleRingTimeout(call._id, 40);
  await new Promise((r) => setTimeout(r, 150));
  const final = await Call.findById(call._id);
  assert.equal(final.status, 'missed');
  assert.equal(final.endReason, 'timeout');
  assert.equal(svc.outcomeFor(final), 'no_answer');
  assert.equal(await activeCallIdOf(a), null);
});

test('outcomeFor maps every §3 row', () => {
  const o = (status, endReason, backfilled = false) => svc.outcomeFor({ status, endReason, backfilled });
  assert.equal(o('ended', 'completed'), 'completed');
  assert.equal(o('ended', 'caller_ended'), 'completed');
  assert.equal(o('missed', 'timeout'), 'no_answer');
  assert.equal(o('missed', 'caller_cancelled'), 'cancelled');
  assert.equal(o('rejected', 'rejected'), 'declined');
  assert.equal(o('busy', 'busy'), 'busy');
  assert.equal(o('busy', 'unavailable'), null);
  assert.equal(o('failed', 'failed'), null);
  assert.equal(o('missed', 'timeout', true), null);
  assert.equal(o('ringing'), null);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callStateService.test.js`
Expected: FAIL — `Cannot find module '../services/callStateService'`.

- [ ] **Step 3: Implement**

Create `lib/callIo.js`:

```js
'use strict';

/**
 * The process's socket.io server, for code that has no `req` (services,
 * the LiveKit webhook's grace timers, the call sweeper). server.js sets it
 * once; tests set a fake.
 */
let ioRef = null;

const setIo = (io) => { ioRef = io; };
const getIo = () => ioRef;

module.exports = { setIo, getIo };
```

In `server.js` replace line 191

```js
app.set('io', io);
```

with

```js
app.set('io', io);
require('./lib/callIo').setIo(io);
```

Create `services/callEffects.js`:

```js
'use strict';

/**
 * Everything a call transition causes outside the Call document. Filled in
 * by Task B3 (events), B4 (call message) and B5 (pushes).
 */
const afterTransition = async () => {};

module.exports = { afterTransition };
```

Create `services/callStateService.js`:

```js
'use strict';

/**
 * Server-authoritative 1:1 call state.
 *
 *   initiate ─► ringing ─┬─ accept ──► active ── end / peer gone > 20 s ──► ended (completed)
 *                        ├─ decline ─► rejected
 *                        ├─ cancel ──► missed (caller_cancelled)
 *                        └─ 45 s ────► missed (timeout)
 *   receiver busy ─► busy (never rings)      caller busy ─► no record
 *
 * Every transition is ONE conditional findOneAndUpdate on the expected
 * status, so accept-vs-timeout, accept-vs-cancel, double accept and
 * end-vs-webhook all have exactly one winner; the loser gets CallStateError
 * (HTTP 409 CALL_STATE). Controllers, the LiveKit webhook and the sweeper
 * all go through transition(); nothing else writes Call.status.
 */

const crypto = require('crypto');
const mongoose = require('mongoose');
const Call = require('../models/Call');
const User = require('../models/User');

const timing = {
  ringTimeoutMs: 45 * 1000,
  staleRingingMs: 60 * 1000,
  reconnectGraceMs: 20 * 1000,
  activeCapMs: 4 * 60 * 60 * 1000,
};

const TERMINAL_STATUSES = ['ended', 'missed', 'rejected', 'failed', 'busy'];

const TRANSITIONS = {
  accept: { from: ['ringing'], to: 'active' },
  decline: { from: ['ringing'], to: 'rejected', endReason: 'rejected' },
  cancel: { from: ['ringing'], to: 'missed', endReason: 'caller_cancelled' },
  timeout: { from: ['ringing'], to: 'missed', endReason: 'timeout' },
  end: { from: ['active'], to: 'ended', endReason: 'completed' },
  fail: { from: ['ringing', 'active'], to: 'failed', endReason: 'failed' },
};

class CallStateError extends Error {
  constructor(status) {
    super(`Call already ${status}`);
    this.name = 'CallStateError';
    this.code = 'CALL_STATE';
    this.status = status;
  }
}

const HEX24 = /^[0-9a-f]{24}$/i;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Live iOS builds address calls by callUuid (VoIP id), sometimes uppercase. */
const callQueryFor = (idOrUuid) => {
  const s = typeof idOrUuid === 'string' ? idOrUuid.trim() : String(idOrUuid || '');
  if (HEX24.test(s)) return { _id: s };
  if (UUID.test(s)) return { callUuid: s.toLowerCase() };
  return null;
};

const findCall = async (idOrUuid) => {
  const q = callQueryFor(idOrUuid);
  return q ? Call.findOne(q) : null;
};

const receiverOf = (call) =>
  call.participants.find((p) => String(p._id || p) !== String(call.initiator._id || call.initiator));

const roomNameFor = (id) => `call:${String(id)}`;

/** Does this call still make its participants busy? */
const isLiveCall = (call, nowMs = Date.now()) => {
  if (!call) return false;
  if (call.status === 'active') return true;
  if (call.status === 'ringing') return nowMs - new Date(call.startTime).getTime() < timing.staleRingingMs;
  return false;
};

/** Spec §3. null = no call message, no missed push, not in history. */
const outcomeFor = (call) => {
  if (!call || call.backfilled) return null;
  switch (call.status) {
    case 'ended': return 'completed';
    case 'missed': return call.endReason === 'caller_cancelled' ? 'cancelled' : 'no_answer';
    case 'rejected': return 'declined';
    case 'busy': return call.endReason === 'busy' ? 'busy' : null;
    default: return null;
  }
};

/** Claim `userId` for `callId` unless a live call holds them. Two attempts cover a lost race. */
const claimUser = async (userId, callId, nowMs = Date.now()) => {
  for (let attempt = 0; attempt < 2; attempt++) {
    const user = await User.findById(userId).select('activeCallId').lean();
    if (!user) return false;
    const current = user.activeCallId || null;
    if (current && String(current) === String(callId)) return true;
    if (current) {
      const holder = await Call.findById(current).select('status startTime').lean();
      if (isLiveCall(holder, nowMs)) return false;
    }
    const res = await User.updateOne(
      { _id: userId, activeCallId: current },
      { $set: { activeCallId: callId } }
    );
    if (res.modifiedCount === 1) return true;
  }
  return false;
};

/**
 * Claim both users in ascending id order. Caller-first would make two users
 * calling each other at the same instant BOTH busy; a global order makes
 * exactly one of them win.
 */
const claimPair = async (callerId, receiverId, callId, nowMs = Date.now()) => {
  const order = [String(callerId), String(receiverId)].sort();
  const claimed = [];
  for (const uid of order) {
    if (!(await claimUser(uid, callId, nowMs))) {
      if (claimed.length) {
        await User.updateMany({ _id: { $in: claimed }, activeCallId: callId }, { $set: { activeCallId: null } });
      }
      return { ok: false, busyUser: uid === String(callerId) ? 'caller' : 'receiver' };
    }
    claimed.push(uid);
  }
  return { ok: true };
};

const releaseUsers = (call) => User.updateMany(
  { _id: { $in: call.participants }, activeCallId: call._id },
  { $set: { activeCallId: null } }
);

const ringTimers = new Map();

const clearRingTimer = (callId) => {
  const key = String(callId);
  const t = ringTimers.get(key);
  if (t) { clearTimeout(t); ringTimers.delete(key); }
};

const runEffects = async (call, ctx) => {
  try {
    await require('./callEffects').afterTransition(call, ctx);
  } catch (err) {
    console.error('[calls] effects failed:', err.message);
  }
};

const transition = async (callId, action, opts = {}) => {
  const spec = TRANSITIONS[action];
  if (!spec) throw new Error(`Unknown call action: ${action}`);
  const now = opts.now || new Date();

  const filter = { _id: callId, status: { $in: spec.from } };
  if (action === 'accept') filter.startTime = { $gt: new Date(now.getTime() - timing.staleRingingMs) };

  const set = { status: spec.to };
  if (spec.endReason) set.endReason = spec.endReason;
  if (spec.to === 'active') {
    set.answeredAt = now;
  } else {
    set.endTime = now;
    set.underfilledSince = null;
  }

  const prev = await Call.findOneAndUpdate(filter, { $set: set }, { new: false });
  if (!prev) {
    const current = await Call.findById(callId).select('status startTime');
    if (!current) throw new CallStateError('not_found');
    if (action === 'accept' && current.status === 'ringing') {
      // Ringing past the stale window: the ring timer died with a restart.
      // Close it properly (message, missed push, caller stops ringing), then refuse.
      try {
        await transition(callId, 'timeout', { by: 'system', now });
      } catch (err) {
        if (!(err instanceof CallStateError)) throw err;
      }
      throw new CallStateError('missed');
    }
    throw new CallStateError(current.status);
  }

  clearRingTimer(callId);
  if (spec.to !== 'active') {
    const duration = prev.answeredAt
      ? Math.max(0, Math.floor((now.getTime() - new Date(prev.answeredAt).getTime()) / 1000))
      : 0;
    await Call.updateOne({ _id: callId }, { $set: { duration } });
    await releaseUsers(prev);
  }

  const call = await Call.findById(callId);
  await runEffects(call, {
    action,
    from: prev.status,
    by: opts.by ? String(opts.by) : 'system',
    deviceId: typeof opts.deviceId === 'string' && opts.deviceId ? opts.deviceId : null,
  });
  return call;
};

const scheduleRingTimeout = (callId, ms = timing.ringTimeoutMs) => {
  clearRingTimer(callId);
  const t = setTimeout(() => {
    ringTimers.delete(String(callId));
    transition(callId, 'timeout', { by: 'system' }).catch((err) => {
      if (!(err instanceof CallStateError)) console.error('[calls] ring timeout failed:', err.message);
    });
  }, ms);
  if (typeof t.unref === 'function') t.unref();
  ringTimers.set(String(callId), t);
};

const startCall = async ({ callerId, receiverId, type, now = new Date() }) => {
  const callId = new mongoose.Types.ObjectId();
  const claim = await claimPair(callerId, receiverId, callId, now.getTime());
  if (!claim.ok && claim.busyUser === 'caller') return { busy: 'caller' };

  const base = {
    _id: callId,
    participants: [callerId, receiverId],
    initiator: callerId,
    type,
    startTime: now,
    callUuid: crypto.randomUUID(),
  };

  if (!claim.ok) {
    const call = await Call.create({ ...base, status: 'busy', endReason: 'busy', endTime: now, duration: 0 });
    await runEffects(call, { action: 'busy', from: null, by: String(callerId), deviceId: null });
    return { busy: 'receiver', call };
  }

  let call;
  try {
    call = await Call.create({ ...base, status: 'ringing' });
  } catch (err) {
    await releaseUsers({ _id: callId, participants: [callerId, receiverId] });
    throw err;
  }
  scheduleRingTimeout(call._id);
  return { call };
};

module.exports = {
  timing,
  TERMINAL_STATUSES,
  CallStateError,
  callQueryFor,
  findCall,
  receiverOf,
  roomNameFor,
  isLiveCall,
  outcomeFor,
  claimUser,
  claimPair,
  releaseUsers,
  transition,
  startCall,
  scheduleRingTimeout,
  clearRingTimer,
};
```

In `docs/REMAINING_WORK.md` tick `- [x] B2 server-authoritative state machine + atomic busy (\`activeCallId\`)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callStateService.test.js`
Expected: 13 pass, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add lib/callIo.js services/callStateService.js services/callEffects.js server.js test/callStateService.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): server-authoritative call state machine with atomic busy

Every transition is one conditional findOneAndUpdate; the loser of any race
gets CallStateError (409 CALL_STATE). Busy is a per-user activeCallId claim
taken in ascending id order, so two users calling each other at once yield
exactly one ringing call. 45 s in-process ring timer; a ringing call older
than 60 s is stale (cannot be accepted, does not make anyone busy).
Calls are addressable by Mongo id or callUuid, case-insensitively.

Still open (calls): B3-B10 (nothing emits or writes messages yet; the
controller still uses the old path); owner items unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task B3: Events — legacy audiences kept, `call:state` to both

**Files:**
- Create: `services/callEvents.js`
- Modify: `services/callEffects.js`
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callEvents.test.js`

**Interfaces:**
- Consumes: `outcomeFor`, `receiverOf` (B2); `getIo()` (B2).
- Produces: `statePayload(call, ctx) → { callId, callUuid, status, outcome, endReason, duration, type, by }`; `emitTransition(io, call, ctx)`. Emits per Global Constraints.

- [ ] **Step 1: Write the failing test**

Create `test/callEvents.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser, fakeIo, silence } = require('./helpers/callKit');

let restore, svc, io;

test.before(async () => {
  restore = silence();
  await startDb('callEvents');
  svc = require('../services/callStateService');
  await require('../models/Call').syncIndexes();
  await require('../models/Message').syncIndexes();
});
test.after(async () => { await stopDb(); restore(); });
test.beforeEach(() => { io = fakeIo(); require('../lib/callIo').setIo(io); });

const ringing = async () => {
  const a = await makeUser('caller'); const b = await makeUser('callee');
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio' });
  svc.clearRingTimer(call._id);
  return { a, b, call, ra: `user_${a._id}`, rb: `user_${b._id}` };
};
const legacy = () => io.sent.filter((s) => s.event !== 'call:state' && s.event !== 'newMessage' && s.event !== 'messageSent');
const states = () => io.eventsNamed('call:state');

test('accept: call:accepted to the caller ONLY; call:state to both', async () => {
  const { b, call, ra, rb } = await ringing();
  await svc.transition(call._id, 'accept', { by: b._id });
  assert.deepEqual(legacy().map((s) => [s.event, s.rooms]), [['call:accepted', [ra]]]);
  assert.deepEqual(legacy()[0].payload, { callId: String(call._id), callUuid: call.callUuid });
  assert.equal(states().length, 1);
  assert.deepEqual(states()[0].rooms.sort(), [ra, rb].sort());
  assert.equal(states()[0].payload.status, 'active');
  assert.equal(states()[0].payload.by, String(b._id));
});

test('decline: call:declined to the caller ONLY', async () => {
  const { b, call, ra } = await ringing();
  await svc.transition(call._id, 'decline', { by: b._id });
  assert.deepEqual(legacy().map((s) => [s.event, s.rooms]), [['call:declined', [ra]]]);
  assert.equal(states()[0].payload.outcome, 'declined');
});

test('missed (cancel and timeout): call:ended to BOTH rooms so live screens close', async () => {
  for (const action of ['cancel', 'timeout']) {
    io.sent.length = 0;
    const { call, ra, rb } = await ringing();
    await svc.transition(call._id, action, { by: 'system' });
    const ended = io.eventsNamed('call:ended');
    assert.equal(ended.length, 1, action);
    assert.deepEqual(ended[0].rooms.sort(), [ra, rb].sort());
    assert.equal(ended[0].payload.callId, String(call._id));
    assert.equal(ended[0].payload.callUuid, call.callUuid);
    assert.equal(states()[0].payload.outcome, action === 'cancel' ? 'cancelled' : 'no_answer');
  }
});

test('end: call:ended to both with an integer duration', async () => {
  const { a, b, call, ra, rb } = await ringing();
  const t0 = new Date();
  await svc.transition(call._id, 'accept', { by: b._id, now: t0 });
  io.sent.length = 0;
  await svc.transition(call._id, 'end', { by: a._id, now: new Date(t0.getTime() + 5400) });
  const ended = io.eventsNamed('call:ended');
  assert.deepEqual(ended[0].rooms.sort(), [ra, rb].sort());
  assert.equal(ended[0].payload.duration, 5);
  assert.deepEqual(Object.keys(states()[0].payload).sort(),
    ['by', 'callId', 'callUuid', 'duration', 'endReason', 'outcome', 'status', 'type']);
});

test('busy: only call:state (no legacy event reaches anyone)', async () => {
  const { a, b, call } = await ringing();
  await svc.transition(call._id, 'accept', { by: b._id });
  io.sent.length = 0;
  const c = await makeUser('third');
  const res = await svc.startCall({ callerId: c._id, receiverId: b._id, type: 'audio' });
  assert.equal(res.busy, 'receiver');
  assert.deepEqual(legacy(), []);
  assert.equal(states()[0].payload.outcome, 'busy');
  assert.ok(a);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callEvents.test.js`
Expected: FAIL — no events recorded (`actual: []` for `call:accepted`).

- [ ] **Step 3: Implement**

Create `services/callEvents.js`:

```js
'use strict';

/**
 * Socket fan-out for call transitions.
 *
 * Live builds (2.2.x, 2.6.1) listen to call:accepted / call:declined /
 * call:ended WITHOUT checking callId, so those names keep exactly their old
 * audience: accepted/declined → caller only, ended → both. On `missed` we
 * also send call:ended to both rooms — a live caller stops ringback and a
 * live receiver's IncomingCallScreen closes. Safe without callId checks
 * because atomic busy guarantees neither user has another live call.
 *
 * New builds listen only to call:incoming + call:state and filter by callId.
 */

const { outcomeFor, receiverOf } = require('./callStateService');

const roomOf = (id) => `user_${String(id)}`;

const statePayload = (call, ctx = {}) => ({
  callId: String(call._id),
  callUuid: call.callUuid || null,
  status: call.status,
  outcome: outcomeFor(call),
  endReason: call.endReason || null,
  duration: Number.isFinite(call.duration) ? Math.floor(call.duration) : 0,
  type: call.type,
  by: ctx.by || 'system',
});

const emitTransition = (io, call, ctx = {}) => {
  if (!io) return;
  const callerRoom = roomOf(call.initiator);
  const receiverRoom = roomOf(receiverOf(call));
  const base = { callId: String(call._id), callUuid: call.callUuid || null };

  switch (call.status) {
    case 'active':
      io.to(callerRoom).emit('call:accepted', base);
      break;
    case 'rejected':
      io.to(callerRoom).emit('call:declined', base);
      break;
    case 'ended':
      io.to(callerRoom).to(receiverRoom).emit('call:ended', { ...base, duration: statePayload(call).duration });
      break;
    case 'missed':
      io.to(callerRoom).to(receiverRoom).emit('call:ended', { ...base, duration: 0, reason: call.endReason || null });
      break;
    default:
      break;
  }

  io.to(callerRoom).to(receiverRoom).emit('call:state', statePayload(call, ctx));
};

module.exports = { statePayload, emitTransition };
```

Replace `services/callEffects.js` with:

```js
'use strict';

/**
 * Everything a call transition causes outside the Call document, in order:
 * socket events, then (B4) the call message, then (B5) pushes. Each step is
 * isolated so one failure never blocks the next.
 */

const { getIo } = require('../lib/callIo');
const { emitTransition } = require('./callEvents');

const afterTransition = async (call, ctx) => {
  const io = getIo();
  try {
    emitTransition(io, call, ctx);
  } catch (err) {
    console.error('[calls] emit failed:', err.message);
  }
};

module.exports = { afterTransition };
```

In `docs/REMAINING_WORK.md` tick `- [x] B3 events: legacy audiences kept + \`call:state\``.

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callEvents.test.js && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callStateService.test.js`
Expected: 5 pass and 13 pass.

- [ ] **Step 5: Commit**

```bash
git add services/callEvents.js services/callEffects.js test/callEvents.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): emit call:state to both users; keep live-build event audiences

call:accepted/declined still go to the caller only, call:ended to both -
now also on missed (timeout or caller cancel) so live callers stop ringback
and live receivers' ring screens close. New call:state carries
{callId, callUuid, status, outcome, endReason, duration, type, by} on every
transition; it is what stops the receiver's other devices.

Still open (calls): B4-B10; owner items unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task B4: Call messages in the conversation

**Files:**
- Create: `services/callMessageService.js`
- Modify: `services/callEffects.js`
- Modify: `socket/socketGuards.js:56-58` and exports (line 125)
- Modify: `socket/socketHandler.js:876-879`
- Modify: `controllers/messages.js:573-576`
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callMessages.test.js`

**Interfaces:**
- Consumes: `outcomeFor`, `receiverOf` (B2); `findOrCreateDm` (`lib/dmConversation.js`); `evaluateConversationStart`, `chargeConversationStart` (`lib/conversationQuota.js`).
- Produces: `LEGACY_STATUS`, `fallbackText(outcome, type, duration) → string`, `buildCallData(call, outcome) → callData`, `writeCallMessage(call, io) → Promise<Message|null>`; `countFirstChatMessages(senderId, receiverId) → Promise<number>` (socketGuards). Emits `newMessage` → receiver room `{ message, unreadCount, senderId, hasMedia: true, mediaType: 'call' }`, `messageSent` → caller room `{ message, unreadCount: 0, receiverId, hasMedia: true, mediaType: 'call' }`.

- [ ] **Step 1: Write the failing test**

Create `test/callMessages.test.js`:

```js
'use strict';

// The conversation cap must be ON to prove a call from a stranger starts a
// conversation through the same quota path as a first text message.
process.env.CONVERSATION_CAP_ENABLED = 'true';

const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser, fakeIo, silence } = require('./helpers/callKit');

let restore, svc, msgs, io, Message, Conversation, User;

test.before(async () => {
  restore = silence();
  await startDb('callMessages');
  svc = require('../services/callStateService');
  msgs = require('../services/callMessageService');
  Message = require('../models/Message');
  Conversation = require('../models/Conversation');
  User = require('../models/User');
  await Promise.all([require('../models/Call').syncIndexes(), Message.syncIndexes(), Conversation.syncIndexes()]);
});
test.after(async () => { await stopDb(); restore(); });
test.beforeEach(() => { io = fakeIo(); require('../lib/callIo').setIo(io); });

const regular = (name) => makeUser(name, { userMode: 'regular', timezone: 'UTC', profileCompleted: true });
const ringing = async (type = 'audio') => {
  const a = await regular('caller'); const b = await regular('callee');
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type });
  svc.clearRingTimer(call._id);
  return { a, b, call };
};
const callMessagesFor = (call) => Message.find({ 'media.callData.callId': String(call._id) }).lean();

test('timeout → exactly one call message with the live-build superset', async () => {
  const { a, b, call } = await ringing();
  await svc.transition(call._id, 'timeout', { by: 'system' });
  const [m, ...rest] = await callMessagesFor(call);
  assert.equal(rest.length, 0);
  assert.equal(m.messageType, 'call');
  assert.equal(m.media.type, 'call');
  assert.equal(String(m.sender), String(a._id));
  assert.equal(String(m.receiver), String(b._id));
  assert.equal(m.message, '📞 Missed voice call');
  const d = m.media.callData;
  assert.deepEqual(Object.keys(d).sort(),
    ['_id', 'callId', 'callUuid', 'duration', 'initiator', 'outcome', 'participants', 'startTime', 'status', 'type']);
  assert.equal(d._id, String(call._id));
  assert.equal(d.callId, String(call._id));
  assert.equal(d.callUuid, call.callUuid);
  assert.equal(d.initiator, String(a._id));
  assert.deepEqual(d.participants, []);
  assert.equal(d.status, 'missed');
  assert.equal(d.outcome, 'no_answer');
  assert.ok(Number.isInteger(d.duration));
});

test('writeCallMessage is idempotent under retry', async () => {
  const { b, call } = await ringing();
  const done = await svc.transition(call._id, 'decline', { by: b._id });
  assert.equal(await msgs.writeCallMessage(done, io), null);
  assert.equal(await msgs.writeCallMessage(done, io), null);
  assert.equal((await callMessagesFor(call)).length, 1);
  assert.equal((await callMessagesFor(call))[0].media.callData.status, 'rejected');
});

test('completed: legacy status ended, integer duration, readable fallback', async () => {
  const { a, b, call } = await ringing('video');
  const t0 = new Date();
  await svc.transition(call._id, 'accept', { by: b._id, now: t0 });
  await svc.transition(call._id, 'end', { by: a._id, now: new Date(t0.getTime() + 61900) });
  const [m] = await callMessagesFor(call);
  assert.equal(m.media.callData.status, 'ended');
  assert.equal(m.media.callData.outcome, 'completed');
  assert.equal(m.media.callData.duration, 61);
  assert.equal(m.message, '📞 Video call · 1:01');
});

test('busy writes a message (legacy status missed); backfilled and failed do not', async () => {
  const { b, call } = await ringing();
  await svc.transition(call._id, 'accept', { by: b._id });
  const c = await regular('third');
  const res = await svc.startCall({ callerId: c._id, receiverId: b._id, type: 'audio' });
  const [busy] = await callMessagesFor(res.call);
  assert.equal(busy.media.callData.status, 'missed');
  assert.equal(busy.media.callData.outcome, 'busy');

  const { call: c2 } = await ringing();
  const failed = await svc.transition(c2._id, 'fail', { by: 'system' });
  assert.equal(await msgs.writeCallMessage(failed, io), null);
  assert.equal((await callMessagesFor(c2)).length, 0);

  const backfilled = { ...failed.toObject(), status: 'missed', endReason: 'timeout', backfilled: true };
  assert.equal(await msgs.writeCallMessage(backfilled, io), null);
});

test('conversation via the first-message path: created, lastMessage set, unread +1, quota charged', async () => {
  const { a, b, call } = await ringing();
  await svc.transition(call._id, 'timeout', { by: 'system' });
  const [m] = await callMessagesFor(call);
  const conv = await Conversation.findOne({ participants: { $all: [a._id, b._id], $size: 2 } });
  assert.ok(conv, 'conversation created');
  assert.equal(String(conv.lastMessage), String(m._id));
  assert.equal(conv.unreadCount.find((u) => String(u.user) === String(b._id)).count, 1);
  const caller = await User.findById(a._id);
  assert.equal(caller.conversationQuota.started, 1, 'a call to a stranger starts a conversation like a first message');
});

test('normal new-message emit: newMessage → receiver, messageSent → caller; no other chat traffic', async () => {
  const { a, b, call } = await ringing();
  await svc.transition(call._id, 'timeout', { by: 'system' });
  const nm = io.eventsNamed('newMessage');
  const ms = io.eventsNamed('messageSent');
  assert.deepEqual(nm.map((s) => s.rooms), [[`user_${b._id}`]]);
  assert.deepEqual(ms.map((s) => s.rooms), [[`user_${a._id}`]]);
  assert.equal(nm[0].payload.mediaType, 'call');
  assert.equal(nm[0].payload.senderId, String(a._id));
  assert.equal(nm[0].payload.message.media.callData.outcome, 'no_answer');
});

test('Review focus 3: call messages never count toward the first-chat 5-message limit', async () => {
  const { assertDmSendAllowed, countFirstChatMessages } = require('../socket/socketGuards');
  const a = await regular('dialer'); const b = await regular('silent');
  for (let i = 0; i < 5; i++) {
    const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio' });
    svc.clearRingTimer(call._id);
    await svc.transition(call._id, 'timeout', { by: 'system' });
  }
  assert.equal(await countFirstChatMessages(a._id, b._id), 0);
  const sender = await User.findById(a._id);
  await assertDmSendAllowed({ senderUser: sender, userId: String(a._id), receiver: String(b._id) });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callMessages.test.js`
Expected: FAIL — `Cannot find module '../services/callMessageService'`.

- [ ] **Step 3: Implement**

Create `services/callMessageService.js`:

```js
'use strict';

/**
 * One chat message per terminal call (spec §4.5).
 *
 * The message is shared by both users; each app renders its own label from
 * media.callData.outcome + whether the viewer was the caller. media.callData
 * is a SUPERSET of what live builds read (CallRecord.fromJson,
 * call_record_model.dart:49-80): `duration` is an int (read `as int?`),
 * `status` is the legacy value, `participants` is [] (they map it).
 *
 * The conversation goes through the same path as a first text message
 * (findOrCreateDm + the conversation quota), so a call from a stranger lands
 * exactly like a first message. initiateCall applies the same quota decision
 * up front, so a call that would be refused here never rings.
 *
 * No chat push: the missed-call push (callPushService) is the only push.
 */

const Message = require('../models/Message');
const { outcomeFor, receiverOf } = require('./callStateService');
const { findOrCreateDm } = require('../lib/dmConversation');
const { evaluateConversationStart, chargeConversationStart } = require('../lib/conversationQuota');

const LEGACY_STATUS = {
  completed: 'ended',
  no_answer: 'missed',
  cancelled: 'missed',
  busy: 'missed',
  declined: 'rejected',
};

const formatDuration = (seconds) => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

/** Plain-text body: required by validation and what pre-callData clients show. */
const fallbackText = (outcome, type, duration = 0) => {
  const kind = type === 'video' ? 'video' : 'voice';
  switch (outcome) {
    case 'completed': return `📞 ${kind === 'video' ? 'Video' : 'Voice'} call · ${formatDuration(duration)}`;
    case 'declined': return `📞 Declined ${kind} call`;
    case 'cancelled': return `📞 Cancelled ${kind} call`;
    default: return `📞 Missed ${kind} call`;
  }
};

const integerSeconds = (d) => (Number.isFinite(d) ? Math.max(0, Math.floor(d)) : 0);

const buildCallData = (call, outcome) => ({
  _id: String(call._id),
  callId: String(call._id),
  callUuid: call.callUuid || null,
  initiator: String(call.initiator._id || call.initiator),
  participants: [],
  type: call.type,
  startTime: call.startTime,
  duration: integerSeconds(call.duration),
  status: LEGACY_STATUS[outcome],
  outcome,
});

const writeCallMessage = async (call, io) => {
  const outcome = outcomeFor(call);
  if (!outcome) return null;

  const callerId = call.initiator._id || call.initiator;
  const receiverId = receiverOf(call);

  // Decide BEFORE the conversation exists, exactly like the text path.
  const decision = await evaluateConversationStart({ userId: String(callerId), receiverId: String(receiverId) });

  let message;
  try {
    message = await Message.create({
      sender: callerId,
      receiver: receiverId,
      message: fallbackText(outcome, call.type, integerSeconds(call.duration)),
      messageType: 'call',
      media: { type: 'call', callData: buildCallData(call, outcome) },
      createdAt: call.endTime || new Date(),
    });
  } catch (err) {
    if (err && err.code === 11000) return null; // already written for this call
    throw err;
  }

  const conversation = await findOrCreateDm(callerId, receiverId);
  conversation.lastMessage = message._id;
  conversation.lastMessageAt = message.createdAt;
  if (Array.isArray(conversation.deletedBy) && conversation.deletedBy.length > 0) {
    conversation.deletedBy = conversation.deletedBy.filter((id) => String(id) !== String(receiverId));
  }
  await conversation.updateUnreadCount(receiverId, 1);
  await conversation.save();

  if (decision.isStart && decision.allowed) {
    await chargeConversationStart(callerId, receiverId);
  }

  await message.populate('sender', 'name username images userMode');
  await message.populate('receiver', 'name username images userMode');

  if (io) {
    const unreadForReceiver = await Message.countDocuments({ receiver: receiverId, sender: callerId, read: false });
    io.to(`user_${String(receiverId)}`).emit('newMessage', {
      message, unreadCount: unreadForReceiver, senderId: String(callerId), hasMedia: true, mediaType: 'call',
    });
    io.to(`user_${String(callerId)}`).emit('messageSent', {
      message, unreadCount: 0, receiverId: String(receiverId), hasMedia: true, mediaType: 'call',
    });
  }
  return message;
};

module.exports = { LEGACY_STATUS, fallbackText, buildCallData, writeCallMessage };
```

Replace `services/callEffects.js` with:

```js
'use strict';

/**
 * Everything a call transition causes outside the Call document, in order:
 * socket events, the call message, then (B5) pushes. Each step is isolated
 * so one failure never blocks the next.
 */

const { getIo } = require('../lib/callIo');
const { emitTransition } = require('./callEvents');
const { outcomeFor } = require('./callStateService');
const callMessageService = require('./callMessageService');

const afterTransition = async (call, ctx) => {
  const io = getIo();
  try {
    emitTransition(io, call, ctx);
  } catch (err) {
    console.error('[calls] emit failed:', err.message);
  }

  if (outcomeFor(call)) {
    try {
      await callMessageService.writeCallMessage(call, io);
    } catch (err) {
      console.error('[calls] call message failed:', err.message);
    }
  }
};

module.exports = { afterTransition };
```

In `socket/socketGuards.js` add above `assertDmSendAllowed`:

```js
/**
 * Messages that count toward the first-chat limit. Call messages are written
 * by the server for every call (sender = caller); counting them would stop
 * someone who rang five times unanswered from ever sending a text.
 */
const countFirstChatMessages = (senderId, receiverId) =>
  Message.countDocuments({ sender: senderId, receiver: receiverId, messageType: { $ne: 'call' } });
```

replace line 58

```js
    const sentSoFar = await Message.countDocuments({ sender: userId, receiver });
```

with

```js
    const sentSoFar = await countFirstChatMessages(userId, receiver);
```

and add `countFirstChatMessages,` to `module.exports`.

In `socket/socketHandler.js` replace lines 876-879

```js
        const messagesSentToReceiver = await Message.countDocuments({
          sender: userId,
          receiver: receiver
        });
```

with

```js
        const messagesSentToReceiver = await countFirstChatMessages(userId, receiver);
```

and extend the existing `require('./socketGuards')` destructure (line ~30) with `countFirstChatMessages`.

In `controllers/messages.js` replace lines 573-576

```js
    const messagesSentToReceiver = await Message.countDocuments({
      sender: sender,
      receiver: receiver
    });
```

with

```js
    const messagesSentToReceiver = await countFirstChatMessages(sender, receiver);
```

and add near the top of the file `const { countFirstChatMessages } = require('../socket/socketGuards');`.

In `docs/REMAINING_WORK.md` tick `- [x] B4 call messages in the conversation (+ first-chat limit ignores them)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `for f in test/callMessages.test.js test/callEvents.test.js test/socketGuards.test.js test/socketSendPath.test.js test/chatAccess.test.js; do node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js $f || break; done`
Expected: every file passes (callMessages: 7 pass).

- [ ] **Step 5: Commit**

```bash
git add services/callMessageService.js services/callEffects.js socket/socketGuards.js socket/socketHandler.js controllers/messages.js test/callMessages.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): one call message per terminal call, via the first-message path

Completed, no-answer, cancelled, declined and busy calls now write a single
messageType 'call' message (partial unique index on callData.callId), whose
callData is a superset live builds already render (legacy status, integer
duration). The conversation is created through findOrCreateDm + the
conversation quota, then the normal newMessage / messageSent emit runs. No
chat push. The first-chat 5-message limit no longer counts call messages on
the REST, socket and voice/disappearing paths.

Still open (calls): B5-B10; owner items unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---
### Task B5: Pushes — data-only incoming (45 s), VoIP id = callUuid, `call_cancelled`, missed-call push, token capabilities

**Files:**
- Create: `services/callPushService.js`
- Create: `lib/pushCapabilities.js`
- Modify: `services/fcmService.js:486-495` (exports)
- Modify: `services/voipPushService.js:113-169`
- Modify: `controllers/notifications.js` (`registerToken` ~line 29, `registerVoipToken` 105-139)
- Modify: `services/callEffects.js`
- Modify: `notification_templates/*.json` (all 19)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callPush.test.js`

**Interfaces:**
- Consumes: `outcomeFor`, `receiverOf` (B2); `ctx.from`, `ctx.deviceId` (B2); `render(type, locale, vars)` (`notificationTemplateService`); `shouldNotify(user, 'calls')`.
- Produces:
  - `callPushService`: `CALL_PUSH_TTL_SECONDS = 45`, `CALL_CANCEL_CAPABILITY = 'call_cancel'`, `buildIncomingFcmMessage(token, platform, data, alert, nowMs)`, `buildVoipPayload(call, caller, livekitUrl)`, `sendIncomingCall({ call, caller, receiver, livekitUrl, nowMs })`, `sendCallCancelled({ call, receiver, excludeDeviceId })`, `sendMissedCall({ call, caller, receiver })`.
  - FCM `incoming_call` data: `{ type, callId, callUuid, callerId, callerName, callerAvatar, callerProfilePicture, callType, livekitUrl, roomName }` (no LiveKit token — it comes from `/accept`).
  - VoIP payload: `{ id: callUuid, callId, callUuid, nameCaller, handle, isVideo, callType, callerId, callerName, callerProfilePicture, livekitUrl, roomName, extra: { callId, callUuid, callType, callerId, callerName, callerAvatar, livekitUrl, roomName } }`; cancel VoIP payload `{ type: 'call_cancelled', id: callUuid, callId, callUuid }`.
  - Missed push: `fcmService.sendToUser(receiverId, {title, body, imageUrl}, { type: 'missed_call', callId, callUuid, callerId, callerName, callType })`.
  - `voipPushService.sendToUser(user, payload, { filter })`, `voipExpiry(nowMs)`; `fcmService.sanitizeData`, `fcmService.handleFailedTokens`.
  - `parseCapabilities(raw) → string[]` (whitelist `['call_cancel']`); `POST /notifications/register-token` and `/register-voip-token` accept `capabilities: string[]`.

- [ ] **Step 1: Write the failing test**

Create `test/callPush.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { stub } = require('./helpers/authHarness');
const { startDb, stopDb, makeUser, asHandler, silence } = require('./helpers/callKit');

const fcmSent = [];
stub('config/firebase', {
  messaging: () => ({
    sendEach: async (messages) => {
      fcmSent.push(...messages);
      return { successCount: messages.length, failureCount: 0, responses: messages.map(() => ({ success: true })) };
    },
  }),
});

let restore, push, voip, fcm, notifications, User;
const voipSent = [];
const missedSent = [];

test.before(async () => {
  restore = silence();
  await startDb('callPush');
  push = require('../services/callPushService');
  voip = require('../services/voipPushService');
  fcm = require('../services/fcmService');
  notifications = require('../controllers/notifications');
  User = require('../models/User');
  voip.send = async (token, payload) => { voipSent.push({ token, payload }); return true; };
  fcm.sendToUser = async (userId, notification, data) => { missedSent.push({ userId, notification, data }); return { success: true }; };
});
test.after(async () => { await stopDb(); restore(); });
test.beforeEach(() => { fcmSent.length = 0; voipSent.length = 0; missedSent.length = 0; });

const call = { _id: '0123456789abcdef01234567', callUuid: '6f1c2b8e-3c1d-4a8e-9b7f-0a1b2c3d4e5f', type: 'audio' };
const caller = { _id: 'aaaaaaaaaaaaaaaaaaaaaaaa', name: 'Ada', images: ['https://cdn.test/ada.jpg'] };

test('incoming FCM: Android is data-only, high priority, 45 s TTL; iOS alert expires in 45 s', () => {
  const now = 1_700_000_000_000;
  const data = { type: 'incoming_call', callId: call._id, callUuid: call.callUuid };
  const android = push.buildIncomingFcmMessage('tA', 'android', data, { title: 't', body: 'b' }, now);
  assert.equal(android.notification, undefined);
  assert.equal(android.android.priority, 'high');
  assert.equal(android.android.ttl, 45000);
  assert.equal(android.data.callUuid, call.callUuid);
  const ios = push.buildIncomingFcmMessage('tI', 'ios', data, { title: 't', body: 'b' }, now);
  assert.equal(ios.apns.headers['apns-expiration'], String(Math.floor(now / 1000) + 45));
  assert.equal(ios.apns.headers['apns-priority'], '10');
  assert.deepEqual(ios.apns.payload.aps.alert, { title: 't', body: 'b' });
});

test('VoIP payload: id is the callUuid, extra.callId is the Mongo id; expiry 45 s', () => {
  const p = push.buildVoipPayload(call, caller, 'wss://lk.test');
  assert.equal(p.id, call.callUuid);
  assert.equal(p.callId, call._id);
  assert.equal(p.extra.callId, call._id);
  assert.equal(p.extra.callUuid, call.callUuid);
  assert.equal(p.extra.callType, 'audio');
  assert.equal(p.livekitToken, undefined);
  assert.equal(voip.voipExpiry(1_700_000_000_000), 1_700_000_045);
});

test('sendIncomingCall: one FCM per active token + VoIP to every active VoIP token', async () => {
  const receiver = await makeUser('r1', {
    fcmTokens: [{ token: 'a1', platform: 'android', deviceId: 'd1' }, { token: 'i1', platform: 'ios', deviceId: 'd2' }],
    voipTokens: [{ token: 'v-legacy', deviceId: 'userIdAsDevice' }],
  });
  await push.sendIncomingCall({ call, caller, receiver, livekitUrl: 'wss://lk.test' });
  assert.deepEqual(fcmSent.map((m) => m.token).sort(), ['a1', 'i1']);
  assert.equal(fcmSent.find((m) => m.token === 'a1').data.type, 'incoming_call');
  assert.equal(fcmSent.find((m) => m.token === 'a1').data.livekitToken, undefined);
  assert.deepEqual(voipSent.map((v) => v.token), ['v-legacy']);
});

const cancelReceiver = () => makeUser('r2', {
  fcmTokens: [
    { token: 'and-capable', platform: 'android', deviceId: 'dev1', capabilities: ['call_cancel'] },
    { token: 'and-acting', platform: 'android', deviceId: 'dev2', capabilities: ['call_cancel'] },
    { token: 'and-legacy', platform: 'android', deviceId: 'dev3' },
    { token: 'ios-fcm', platform: 'ios', deviceId: 'dev4', capabilities: ['call_cancel'] },
  ],
  voipTokens: [
    { token: 'voip-capable', deviceId: 'dev4', capabilities: ['call_cancel'] },
    { token: 'voip-legacy', deviceId: 'dev5' },
  ],
});

test('call_cancelled: only capable tokens, never the acting device, Android data-only', async () => {
  const receiver = await cancelReceiver();
  await push.sendCallCancelled({ call, receiver, excludeDeviceId: 'dev2' });
  assert.deepEqual(fcmSent.map((m) => m.token), ['and-capable']);
  assert.equal(fcmSent[0].notification, undefined);
  assert.deepEqual(fcmSent[0].data, { type: 'call_cancelled', callId: call._id, callUuid: call.callUuid });
  assert.equal(fcmSent[0].android.ttl, 45000);
  assert.deepEqual(voipSent.map((v) => v.token), ['voip-capable']);
  assert.equal(voipSent[0].payload.type, 'call_cancelled');
  assert.equal(voipSent[0].payload.id, call.callUuid);
});

test('Review focus 2: no deviceId (live builds) excludes nobody', async () => {
  const receiver = await cancelReceiver();
  for (const excludeDeviceId of [undefined, null, '']) {
    fcmSent.length = 0; voipSent.length = 0;
    await push.sendCallCancelled({ call, receiver, excludeDeviceId });
    assert.deepEqual(fcmSent.map((m) => m.token).sort(), ['and-acting', 'and-capable']);
    assert.deepEqual(voipSent.map((v) => v.token), ['voip-capable']);
  }
});

test('missed push: localized template, missed_call type, respects the calls preference', async () => {
  const receiver = await makeUser('r3', { preferredLocale: 'en' });
  await push.sendMissedCall({ call: { ...call, type: 'video' }, caller, receiver });
  assert.equal(missedSent.length, 1);
  assert.equal(missedSent[0].notification.title, '📞 Ada');
  assert.equal(missedSent[0].notification.body, 'Missed video call');
  assert.equal(missedSent[0].data.type, 'missed_call');
  assert.equal(missedSent[0].data.callerId, caller._id);
  const off = await makeUser('r4', { notificationPreferences: { calls: false } });
  await push.sendMissedCall({ call, caller, receiver: off });
  assert.equal(missedSent.length, 1);
});

test('every notification template locale has both missed-call templates', () => {
  const dir = path.join(__dirname, '..', 'notification_templates');
  for (const file of fs.readdirSync(dir)) {
    const t = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
    for (const key of ['missed_call_audio', 'missed_call_video']) {
      assert.ok(t[key] && t[key].title.includes('{callerName}') && t[key].body, `${file} ${key}`);
    }
  }
});

test('token registration stores whitelisted capabilities; absent = []', async () => {
  const u = await makeUser('r5');
  const req = (body) => ({ user: { id: String(u._id) }, body });
  await asHandler(notifications.registerToken)(req({ token: 'f1', platform: 'android', deviceId: 'dx', capabilities: ['call_cancel', 'bogus'] }));
  await asHandler(notifications.registerVoipToken)(req({ voipToken: 'v1', deviceId: 'dx', capabilities: ['call_cancel'] }));
  let fresh = await User.findById(u._id);
  assert.deepEqual([...fresh.fcmTokens[0].capabilities], ['call_cancel']);
  assert.deepEqual([...fresh.voipTokens[0].capabilities], ['call_cancel']);
  await asHandler(notifications.registerVoipToken)(req({ voipToken: 'v2', deviceId: 'dx' }));
  fresh = await User.findById(u._id);
  assert.deepEqual([...fresh.voipTokens[0].capabilities], [], 'an old build re-registering the same device loses the capability');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callPush.test.js`
Expected: FAIL — `Cannot find module '../services/callPushService'`.

- [ ] **Step 3: Implement**

Create `lib/pushCapabilities.js`:

```js
'use strict';

/** What a client build can declare at token registration. Unknown values are dropped. */
const KNOWN_CAPABILITIES = ['call_cancel'];

const parseCapabilities = (raw) => (Array.isArray(raw)
  ? [...new Set(raw.filter((c) => typeof c === 'string' && KNOWN_CAPABILITIES.includes(c)))]
  : []);

module.exports = { KNOWN_CAPABILITIES, parseCapabilities };
```

In `services/fcmService.js` replace the `module.exports` block (486-495) with:

```js
module.exports = {
  sendToUser,
  sendToUsers,
  sendToTopic,
  subscribeToTopic,
  unsubscribeFromTopic,
  isCapped,
  recordSend,
  NOTIFICATION_TYPE_ENUM,
  // Used by services/callPushService.js, which builds its own data-only
  // messages but must clean dead tokens the same way.
  sanitizeData: _sanitizeData,
  handleFailedTokens: _handleFailedTokens,
};
```

In `services/voipPushService.js`:
- Above `async function send(` add:

```js
const VOIP_EXPIRY_SECONDS = 45; // = the server ring timeout; a later delivery is pointless

const voipExpiry = (nowMs = Date.now()) => Math.floor(nowMs / 1000) + VOIP_EXPIRY_SECONDS;
```

- Replace `note.expiry = Math.floor(Date.now() / 1000) + 30; // 30s — call rings limited time anyway` with `note.expiry = voipExpiry();`.
- Replace the whole `sendToUser` function and the `module.exports` line with:

```js
/**
 * Send a VoIP push to every active token a user has registered, optionally
 * narrowed by `filter(token)` (call_cancelled goes only to tokens that
 * declared the 'call_cancel' capability, minus the acting device). Calls
 * module.exports.send so tests can replace the transport.
 */
async function sendToUser(user, payload, { filter } = {}) {
  if (!user || !Array.isArray(user.voipTokens) || user.voipTokens.length === 0) {
    return false;
  }
  const active = user.voipTokens.filter((t) => t.active && t.token && (!filter || filter(t)));
  if (active.length === 0) return false;

  const results = await Promise.all(
    active.map((t) => module.exports.send(t.token, payload).catch(() => false))
  );
  return results.some(Boolean);
}

module.exports = { send, sendToUser, voipExpiry, VOIP_EXPIRY_SECONDS };
```

Create `services/callPushService.js`:

```js
'use strict';

/**
 * Call pushes (spec §4.4, §4.6).
 *
 *  - incoming_call: data-only on Android (CallKit renders; no duplicate
 *    notification), alert on iOS FCM as a fallback; both expire with the
 *    45 s ring. Plus a VoIP push whose `id` is the callUuid — that is what
 *    fixes the CallKit UUID crash for live builds too, since /calls/:id
 *    accepts the uuid.
 *  - call_cancelled: on every exit from ringing, to the receiver's devices
 *    that declared 'call_cancel', except the device that acted.
 *  - missed_call: visible, localized, for no_answer / cancelled / busy.
 */

const admin = require('../config/firebase');
const fcmService = require('./fcmService');
const voipPushService = require('./voipPushService');
const { render } = require('./notificationTemplateService');
const { shouldNotify } = require('./notificationService');

const CALL_PUSH_TTL_SECONDS = 45;
const CALL_CANCEL_CAPABILITY = 'call_cancel';

const avatarOf = (user) => (user && Array.isArray(user.images) && user.images[0]) || '';
const roomOf = (call) => `call:${String(call._id)}`;
const canCancel = (token) => Array.isArray(token.capabilities) && token.capabilities.includes(CALL_CANCEL_CAPABILITY);
// A missing/empty deviceId (every live build) must exclude nobody.
const notActingDevice = (excludeDeviceId) => (token) => !excludeDeviceId || token.deviceId !== excludeDeviceId;

const buildIncomingFcmMessage = (token, platform, data, alert, nowMs = Date.now()) => {
  const sdata = fcmService.sanitizeData(data);
  if (platform === 'android') {
    return { token, data: sdata, android: { priority: 'high', ttl: CALL_PUSH_TTL_SECONDS * 1000 } };
  }
  return {
    token,
    data: sdata,
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-expiration': String(Math.floor(nowMs / 1000) + CALL_PUSH_TTL_SECONDS),
      },
      payload: { aps: { alert: { title: alert.title, body: alert.body }, sound: 'default', 'mutable-content': 1 } },
    },
  };
};

const buildVoipPayload = (call, caller, livekitUrl) => {
  const extra = {
    callId: String(call._id),
    callUuid: call.callUuid,
    callType: call.type,
    callerId: String(caller._id),
    callerName: caller.name || '',
    callerAvatar: avatarOf(caller),
    livekitUrl: livekitUrl || '',
    roomName: roomOf(call),
  };
  return {
    id: call.callUuid,
    callId: String(call._id),
    callUuid: call.callUuid,
    nameCaller: caller.name || 'Caller',
    handle: String(caller._id),
    isVideo: call.type === 'video',
    callType: call.type,
    callerId: String(caller._id),
    callerName: caller.name || '',
    callerProfilePicture: avatarOf(caller),
    livekitUrl: livekitUrl || '',
    roomName: roomOf(call),
    extra,
  };
};

const sendFcm = async (userId, tokens, messages) => {
  if (messages.length === 0) return;
  const res = await admin.messaging().sendEach(messages);
  if (res.failureCount > 0) await fcmService.handleFailedTokens(userId, tokens, res.responses);
};

const sendIncomingCall = async ({ call, caller, receiver, livekitUrl, nowMs = Date.now() }) => {
  const data = {
    type: 'incoming_call',
    callId: String(call._id),
    callUuid: call.callUuid,
    callerId: String(caller._id),
    callerName: caller.name || '',
    callerAvatar: avatarOf(caller),
    callerProfilePicture: avatarOf(caller),
    callType: call.type,
    livekitUrl: livekitUrl || '',
    roomName: roomOf(call),
  };
  const alert = {
    title: `Incoming ${call.type === 'video' ? 'Video' : 'Audio'} Call`,
    body: `${caller.name || 'Someone'} is calling you...`,
  };
  const tokens = (receiver.fcmTokens || []).filter((t) => t.active && t.token);
  await sendFcm(receiver._id, tokens, tokens.map((t) => buildIncomingFcmMessage(t.token, t.platform, data, alert, nowMs)));
  await voipPushService.sendToUser(receiver, buildVoipPayload(call, caller, livekitUrl));
};

const sendCallCancelled = async ({ call, receiver, excludeDeviceId }) => {
  const keep = notActingDevice(excludeDeviceId);
  const data = fcmService.sanitizeData({ type: 'call_cancelled', callId: String(call._id), callUuid: call.callUuid || '' });
  const tokens = (receiver.fcmTokens || []).filter(
    (t) => t.active && t.token && t.platform === 'android' && canCancel(t) && keep(t)
  );
  await sendFcm(receiver._id, tokens, tokens.map((t) => ({
    token: t.token, data, android: { priority: 'high', ttl: CALL_PUSH_TTL_SECONDS * 1000 },
  })));
  await voipPushService.sendToUser(
    receiver,
    { type: 'call_cancelled', id: call.callUuid, callId: String(call._id), callUuid: call.callUuid },
    { filter: (t) => canCancel(t) && keep(t) }
  );
};

const sendMissedCall = async ({ call, caller, receiver }) => {
  if (!shouldNotify(receiver, 'calls')) return { skipped: true };
  const tpl = render(
    call.type === 'video' ? 'missed_call_video' : 'missed_call_audio',
    receiver.preferredLocale || 'en',
    { callerName: caller.name || 'Someone' }
  );
  return fcmService.sendToUser(
    String(receiver._id),
    { title: tpl.title, body: tpl.body, imageUrl: avatarOf(caller) || undefined },
    {
      type: 'missed_call',
      callId: String(call._id),
      callUuid: call.callUuid || '',
      callerId: String(caller._id),
      callerName: caller.name || '',
      callType: call.type,
    }
  );
};

module.exports = {
  CALL_PUSH_TTL_SECONDS,
  CALL_CANCEL_CAPABILITY,
  buildIncomingFcmMessage,
  buildVoipPayload,
  sendIncomingCall,
  sendCallCancelled,
  sendMissedCall,
};
```

Replace `services/callEffects.js` with the final version:

```js
'use strict';

/**
 * Everything a call transition causes outside the Call document, in order:
 * socket events, the call message, then pushes. Each step is isolated so one
 * failure never blocks the next. Pushes are fired, not awaited: a slow APNs
 * round-trip must not delay the accept response.
 */

const User = require('../models/User');
const { getIo } = require('../lib/callIo');
const { emitTransition } = require('./callEvents');
const { outcomeFor, receiverOf } = require('./callStateService');
const callMessageService = require('./callMessageService');
const callPushService = require('./callPushService');

const MISSED_OUTCOMES = new Set(['no_answer', 'cancelled', 'busy']);

const logPushError = (kind) => (err) => console.error(`[calls] ${kind} push failed:`, err.message);

const afterTransition = async (call, ctx) => {
  const io = getIo();
  try {
    emitTransition(io, call, ctx);
  } catch (err) {
    console.error('[calls] emit failed:', err.message);
  }

  const outcome = outcomeFor(call);
  if (outcome) {
    try {
      await callMessageService.writeCallMessage(call, io);
    } catch (err) {
      console.error('[calls] call message failed:', err.message);
    }
  }

  const leftRinging = ctx.from === 'ringing' && call.status !== 'ringing';
  const missed = MISSED_OUTCOMES.has(outcome);
  if (!leftRinging && !missed) return;

  let caller;
  let receiver;
  try {
    [caller, receiver] = await Promise.all([
      User.findById(call.initiator).select('name images'),
      User.findById(receiverOf(call)).select('name fcmTokens voipTokens notificationPreferences preferredLocale'),
    ]);
  } catch (err) {
    console.error('[calls] push lookup failed:', err.message);
    return;
  }
  if (!receiver) return;

  if (leftRinging) {
    callPushService.sendCallCancelled({ call, receiver, excludeDeviceId: ctx.deviceId })
      .catch(logPushError('call_cancelled'));
  }
  if (missed && caller) {
    callPushService.sendMissedCall({ call, caller, receiver }).catch(logPushError('missed_call'));
  }
};

module.exports = { afterTransition };
```

In `controllers/notifications.js` add at the top `const { parseCapabilities } = require('../lib/pushCapabilities');`. In `registerToken` destructure `capabilities` from `req.body` and set it on both branches:

```js
  const { token, platform, deviceId, deviceLocale, authorization, capabilities } = req.body;
  const caps = parseCapabilities(capabilities);
```

```js
    user.fcmTokens[existingTokenIndex].active = true;
    user.fcmTokens[existingTokenIndex].capabilities = caps;
```

```js
    user.fcmTokens.push({
      token,
      platform,
      deviceId,
      lastUpdated: new Date(),
      active: true,
      capabilities: caps
    });
```

In `registerVoipToken` likewise:

```js
  const { voipToken, deviceId, capabilities } = req.body;
  const caps = parseCapabilities(capabilities);
```

```js
    user.voipTokens[idx].active = voipToken.length > 0;
    user.voipTokens[idx].capabilities = caps;
```

```js
    user.voipTokens.push({
      token: voipToken,
      deviceId,
      lastUpdated: new Date(),
      active: true,
      capabilities: caps
    });
```

Add the templates to all 19 files with this one-off script (run once, not committed):

```bash
node - <<'NODE'
const fs = require('fs');
const path = require('path');
const MISSED = {
  ar: ['مكالمة صوتية فائتة', 'مكالمة فيديو فائتة'],
  de: ['Verpasster Sprachanruf', 'Verpasster Videoanruf'],
  en: ['Missed voice call', 'Missed video call'],
  es: ['Llamada de voz perdida', 'Videollamada perdida'],
  fr: ['Appel vocal manqué', 'Appel vidéo manqué'],
  hi: ['मिस्ड वॉइस कॉल', 'मिस्ड वीडियो कॉल'],
  id: ['Panggilan suara tak terjawab', 'Panggilan video tak terjawab'],
  it: ['Chiamata vocale persa', 'Videochiamata persa'],
  ja: ['不在着信（音声）', '不在着信（ビデオ）'],
  ko: ['부재중 음성 통화', '부재중 영상 통화'],
  pt: ['Chamada de voz perdida', 'Videochamada perdida'],
  ru: ['Пропущенный голосовой звонок', 'Пропущенный видеозвонок'],
  tg: ['Занги овозии беҷавоб', 'Занги видеоии беҷавоб'],
  th: ['สายที่ไม่ได้รับ', 'วิดีโอคอลที่ไม่ได้รับ'],
  tl: ['Hindi nasagot na voice call', 'Hindi nasagot na video call'],
  tr: ['Cevapsız sesli arama', 'Cevapsız görüntülü arama'],
  vi: ['Cuộc gọi thoại nhỡ', 'Cuộc gọi video nhỡ'],
  zh: ['未接语音通话', '未接视频通话'],
  zh_TW: ['未接語音來電', '未接視訊來電'],
};
const dir = path.join(process.cwd(), 'notification_templates');
for (const [locale, [audio, video]] of Object.entries(MISSED)) {
  const file = path.join(dir, `${locale}.json`);
  const t = JSON.parse(fs.readFileSync(file, 'utf8'));
  t.missed_call_audio = { title: '📞 {callerName}', body: audio };
  t.missed_call_video = { title: '📞 {callerName}', body: video };
  fs.writeFileSync(file, JSON.stringify(t, null, 2) + '\n');
}
console.log('templates updated');
NODE
```

In `docs/REMAINING_WORK.md` tick `- [x] B5 pushes: …` and add under the calls section: `- [ ] Native review of the 18 machine-drafted missed-call push strings (notification_templates/*.json)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `for f in test/callPush.test.js test/notificationTemplate.test.js test/callMessages.test.js test/callEvents.test.js test/callStateService.test.js; do node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js $f || break; done`
Expected: all pass (callPush: 8 pass).

- [ ] **Step 5: Commit**

```bash
git add services/callPushService.js lib/pushCapabilities.js services/fcmService.js services/voipPushService.js controllers/notifications.js services/callEffects.js notification_templates test/callPush.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): call pushes - data-only 45 s ring, call_cancelled, missed call

Incoming-call FCM is data-only on Android (no duplicate notification next to
CallKit) and expires with the 45 s ring on both platforms; VoIP id is now the
callUuid, extra.callId the Mongo id, expiry 45 s. Every exit from ringing
sends call_cancelled to the receiver's devices that declared 'call_cancel'
(FCM register-token and VoIP register-token now store capabilities), minus
the device that acted; a missing deviceId excludes nobody. no_answer /
cancelled / busy send a localized missed-call push (19 locales; 18 machine
drafts).

Still open (calls): B6-B10; native review of the missed-call strings;
owner items unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task B6: REST — initiate with busy / caller-busy / conversation cap, id-or-uuid, `GET /calls/current`

**Files:**
- Modify: `controllers/callController.js` (imports 12-21; `getCall` 69-90; lines 135-450 replaced)
- Modify: `services/callService.js` (add `getCurrentCall`)
- Modify: `routes/calls.js`
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callController.test.js`

**Interfaces:**
- Consumes: `startCall`, `transition`, `findCall`, `receiverOf`, `roomNameFor`, `outcomeFor`, `CallStateError`, `TERMINAL_STATUSES` (B2); `callPushService.sendIncomingCall` (B5); `evaluateConversationStart`, `CONVERSATION_START_LIMIT_MESSAGE`.
- Produces (HTTP):
  - `POST /calls/initiate { receiverId, type }` → `200 { data: { call, token, url, roomName } }` | `409 { code: 'CALLER_BUSY' }` (no record) | `409 { code: 'CALLEE_BUSY', data: { call } }` | `403 { code: 'CONVERSATION_START_LIMIT' }` | `503` (LiveKit mint failed → call `failed`). Emits `call:incoming { callId, callUuid, caller: {_id, name, profilePicture}, callType, roomName }` to the receiver room.
  - `POST /calls/:idOrUuid/accept { deviceId? }` → `200 { data: { call, token, url, roomName } }` | `409 { code: 'CALL_STATE', status }` | 403 | 404.
  - `POST /calls/:idOrUuid/decline { deviceId? }` → `200 { data: { call } }` | 409 CALL_STATE.
  - `POST /calls/:idOrUuid/end { deviceId? }` → `200 { data: { call } }`; ringing+caller → cancel, ringing+receiver → decline, active → end (+ `endRoom`), terminal → idempotent 200.
  - `GET /calls/current` → `200 { data: { call: null } }` | `{ data: { call: { id, callUuid, type, status, direction: 'in'|'out', otherParty: { id, name, avatar }, roomName, startTime }, token?, url? } }` (token/url only when `active`).
  - `GET /calls/:idOrUuid` → `200 { data: { ...call, outcome } }`.
  - `callService.getCurrentCall(userId, nowMs) → Promise<Call|null>`.

- [ ] **Step 1: Write the failing test**

Create `test/callController.test.js`:

```js
'use strict';

process.env.CONVERSATION_CAP_ENABLED = 'true';

const test = require('node:test');
const assert = require('node:assert/strict');
const { stub } = require('./helpers/authHarness');
const { startDb, stopDb, makeUser, fakeIo, asHandler, silence } = require('./helpers/callKit');

const minted = [];
stub('services/livekitService', {
  mintRoomToken: async ({ identity, roomName }) => {
    minted.push({ identity, roomName });
    return { token: `tok-${identity}`, url: 'wss://lk.test' };
  },
});
const endedRooms = [];
stub('services/livekitAdminService', {
  endRoom: async (room) => { endedRooms.push(room); },
  disconnectParticipant: async () => {},
  countParticipants: async () => ({ ok: true, count: 2, missing: false }),
});
const pushes = [];
stub('services/callPushService', {
  sendIncomingCall: async (args) => { pushes.push(['incoming', args]); },
  sendCallCancelled: async (args) => { pushes.push(['cancelled', args]); },
  sendMissedCall: async (args) => { pushes.push(['missed', args]); },
});

let restore, ctl, svc, Call, io;

test.before(async () => {
  restore = silence();
  await startDb('callController');
  ctl = require('../controllers/callController');
  svc = require('../services/callStateService');
  Call = require('../models/Call');
  await Promise.all([Call.syncIndexes(), require('../models/Message').syncIndexes()]);
});
test.after(async () => { await stopDb(); restore(); });
test.beforeEach(() => {
  io = fakeIo(); require('../lib/callIo').setIo(io);
  pushes.length = 0; minted.length = 0; endedRooms.length = 0;
});

const user = (name) => makeUser(name, { userMode: 'regular', timezone: 'UTC', profileCompleted: true });
const req = (u, { params = {}, body = {}, query = {} } = {}) => ({
  user: { id: String(u._id), _id: u._id, name: u.name }, params, body, query, app: { get: () => io },
});
const initiate = (a, b, type = 'audio') =>
  asHandler(ctl.initiateCall)(req(a, { body: { receiverId: String(b._id), type } }));
const clearTimers = async () => {
  for (const c of await Call.find({ status: 'ringing' }).select('_id')) svc.clearRingTimer(c._id);
};

test('initiate: ringing call with callUuid, caller token, call:incoming + push to the receiver', async () => {
  const a = await user('ada'); const b = await user('bo');
  const res = await initiate(a, b, 'video');
  await clearTimers();
  assert.equal(res.status, 200);
  const { call, token, url, roomName } = res.body.data;
  assert.ok(call.callUuid);
  assert.equal(token, `tok-${a._id}`);
  assert.equal(url, 'wss://lk.test');
  assert.equal(roomName, `call:${call._id}`);
  const inc = io.eventsNamed('call:incoming');
  assert.deepEqual(inc.map((e) => e.rooms), [[`user_${b._id}`]]);
  assert.equal(inc[0].payload.callUuid, call.callUuid);
  assert.equal(inc[0].payload.callType, 'video');
  const [kind, args] = pushes.find((p) => p[0] === 'incoming');
  assert.equal(kind, 'incoming');
  assert.equal(args.livekitUrl, 'wss://lk.test');
});

test('initiate while the caller is in a live call → 409 CALLER_BUSY and no record', async () => {
  const a = await user('ada'); const b = await user('bo'); const c = await user('cy');
  await initiate(a, b);
  await clearTimers();
  const before = await Call.countDocuments();
  const res = await initiate(a, c);
  assert.equal(res.status, 409);
  assert.equal(res.body.code, 'CALLER_BUSY');
  assert.equal(await Call.countDocuments(), before);
});

test('initiate to a receiver in a live call → 409 CALLEE_BUSY, busy record, never rings', async () => {
  const a = await user('ada'); const b = await user('bo'); const c = await user('cy');
  await initiate(a, b);
  await clearTimers();
  io.sent.length = 0;
  const res = await initiate(c, b);
  assert.equal(res.status, 409);
  assert.equal(res.body.code, 'CALLEE_BUSY');
  assert.equal(res.body.data.call.status, 'busy');
  assert.equal(io.eventsNamed('call:incoming').length, 0);
});

test('initiate refused by the conversation cap → 403, no call', async () => {
  const a = await user('capped');
  const b = await user('stranger');
  const User = require('../models/User');
  const { localDayKey, localDayEnd } = require('../lib/localDay');
  const now = new Date();
  await User.updateOne({ _id: a._id }, { $set: { conversationQuota: {
    dayKey: localDayKey(now, 'UTC'), started: 1000, adCredits: 0, resetAt: localDayEnd(now, 'UTC'),
  } } });
  const before = await Call.countDocuments();
  const res = await initiate(a, b);
  assert.equal(res.status, 403);
  assert.equal(res.code, 'CONVERSATION_START_LIMIT');
  assert.equal(await Call.countDocuments(), before);
});

test('Review focus 1: accept by UPPERCASE callUuid; call_cancelled excludes the acting device', async () => {
  const a = await user('ada'); const b = await user('bo');
  const { body } = await initiate(a, b);
  await clearTimers();
  const upper = body.data.call.callUuid.toUpperCase();
  const res = await asHandler(ctl.acceptCall)(req(b, { params: { id: upper }, body: { deviceId: 'dev-A' } }));
  assert.equal(res.status, 200);
  assert.equal(res.body.data.call.status, 'active');
  assert.equal(res.body.data.token, `tok-${b._id}`);
  const cancelled = pushes.find((p) => p[0] === 'cancelled');
  assert.equal(cancelled[1].excludeDeviceId, 'dev-A');
});

test('second accept → 409 CALL_STATE active; non-receiver → 403', async () => {
  const a = await user('ada'); const b = await user('bo');
  const { body } = await initiate(a, b);
  await clearTimers();
  const id = String(body.data.call._id);
  assert.equal((await asHandler(ctl.acceptCall)(req(a, { params: { id } }))).status, 403);
  await asHandler(ctl.acceptCall)(req(b, { params: { id } }));
  const again = await asHandler(ctl.acceptCall)(req(b, { params: { id } }));
  assert.equal(again.status, 409);
  assert.equal(again.body.code, 'CALL_STATE');
  assert.equal(again.body.status, 'active');
});

test('end: caller while ringing = cancelled; receiver while ringing = declined; active = ended + room closed; terminal = idempotent', async () => {
  const a = await user('ada'); const b = await user('bo');
  let { body } = await initiate(a, b); await clearTimers();
  let res = await asHandler(ctl.endCall)(req(a, { params: { id: String(body.data.call._id) } }));
  assert.equal(res.body.data.call.status, 'missed');
  assert.equal(res.body.data.call.endReason, 'caller_cancelled');

  ({ body } = await initiate(a, b)); await clearTimers();
  res = await asHandler(ctl.endCall)(req(b, { params: { id: body.data.call.callUuid } }));
  assert.equal(res.body.data.call.status, 'rejected');

  ({ body } = await initiate(a, b)); await clearTimers();
  const id = String(body.data.call._id);
  await asHandler(ctl.acceptCall)(req(b, { params: { id } }));
  res = await asHandler(ctl.endCall)(req(b, { params: { id } }));
  assert.equal(res.body.data.call.status, 'ended');
  assert.deepEqual(endedRooms, [`call:${id}`]);
  res = await asHandler(ctl.endCall)(req(a, { params: { id } }));
  assert.equal(res.status, 200);
  assert.equal(res.body.data.call.status, 'ended');
});

test('GET /calls/current: receiver sees ringing (in); caller sees null while ringing; active comes with a token', async () => {
  const a = await user('ada'); const b = await user('bo');
  const { body } = await initiate(a, b); await clearTimers();
  const id = String(body.data.call._id);
  let res = await asHandler(ctl.getCurrentCall)(req(b));
  assert.equal(res.body.data.call.id, id);
  assert.equal(res.body.data.call.direction, 'in');
  assert.equal(res.body.data.call.otherParty.name, 'ada');
  assert.equal(res.body.data.token, undefined);
  res = await asHandler(ctl.getCurrentCall)(req(a));
  assert.equal(res.body.data.call, null);
  await asHandler(ctl.acceptCall)(req(b, { params: { id } }));
  res = await asHandler(ctl.getCurrentCall)(req(a));
  assert.equal(res.body.data.call.status, 'active');
  assert.equal(res.body.data.call.direction, 'out');
  assert.equal(res.body.data.token, `tok-${a._id}`);
});

test('GET /calls/:uuid returns the call with its outcome', async () => {
  const a = await user('ada'); const b = await user('bo');
  const { body } = await initiate(a, b); await clearTimers();
  await asHandler(ctl.declineCall)(req(b, { params: { id: String(body.data.call._id) } }));
  const res = await asHandler(ctl.getCall)(req(a, { params: { id: body.data.call.callUuid } }));
  assert.equal(res.status, 200);
  assert.equal(res.body.data.status, 'rejected');
  assert.equal(res.body.data.outcome, 'declined');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callController.test.js`
Expected: FAIL — `ctl.getCurrentCall is not a function`, initiate response lacks `callUuid`, CALLER_BUSY returns 200, uppercase uuid accept → `CastError`.

- [ ] **Step 3: Implement**

In `controllers/callController.js` replace the imports (lines 12-21) with:

```js
const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const callService = require('../services/callService');
const callStateService = require('../services/callStateService');
const callPushService = require('../services/callPushService');
const Call = require('../models/Call');
const User = require('../models/User');
const { mintRoomToken } = require('../services/livekitService');
const livekitAdmin = require('../services/livekitAdminService');
const { shouldNotify } = require('../services/notificationService');
const {
  evaluateConversationStart,
  CONVERSATION_START_LIMIT_MESSAGE,
} = require('../lib/conversationQuota');

const { CallStateError, roomNameFor } = callStateService;
const HEX24 = /^[0-9a-f]{24}$/i;

/** Accept/decline/end carry the acting device so call_cancelled skips it. */
const deviceIdFrom = (req) => {
  const d = req.body && req.body.deviceId;
  return typeof d === 'string' && d.length > 0 && d.length <= 200 ? d : null;
};

const respondCallState = (res, err) => res.status(409).json({
  success: false,
  error: `Call already ${err.status}`,
  code: 'CALL_STATE',
  status: err.status,
});

const isParticipant = (call, userId) =>
  call.participants.some((p) => String(p._id || p) === String(userId));
```

Replace `getCall` (lines 69-90) with:

```js
exports.getCall = asyncHandler(async (req, res, next) => {
  const call = await callStateService.findCall(req.params.id);
  if (!call) return next(new ErrorResponse('Call not found', 404));
  if (!isParticipant(call, req.user.id)) {
    return next(new ErrorResponse('Not authorized to view this call', 403));
  }
  await call.populate('participants', 'name images');
  res.status(200).json({
    success: true,
    data: { ...call.toObject(), outcome: callStateService.outcomeFor(call) },
  });
});

/**
 * @desc    The caller's live call, for resume / cold-start recovery:
 *          ringing where I am the receiver (< 60 s), or active. Active calls
 *          come with a fresh LiveKit token so the app can rejoin.
 * @route   GET /api/v1/calls/current
 */
exports.getCurrentCall = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const call = await callService.getCurrentCall(userId);
  if (!call) return res.status(200).json({ success: true, data: { call: null } });

  const other = call.participants.find((p) => String(p._id) !== userId);
  const direction = String(call.initiator) === userId ? 'out' : 'in';
  const summary = {
    id: String(call._id),
    callUuid: call.callUuid || null,
    type: call.type,
    status: call.status,
    direction,
    otherParty: other ? {
      id: String(other._id),
      name: other.name || '',
      avatar: (Array.isArray(other.images) && other.images[0]) || null,
    } : null,
    roomName: roomNameFor(call._id),
    startTime: call.startTime,
  };
  const data = { call: summary };
  if (call.status === 'active') {
    const { token, url } = await mintRoomToken({
      identity: userId,
      name: req.user.name || 'Participant',
      roomName: summary.roomName,
      metadata: { role: direction === 'out' ? 'caller' : 'receiver', callId: summary.id },
    });
    data.token = token;
    data.url = url;
  }
  res.status(200).json({ success: true, data });
});
```

Replace everything from `const _roomNameForCall = ...` (line 139) to the end of the file with:

```js
/**
 * @desc    Initiate a 1:1 call. Busy is atomic (callStateService.startCall);
 *          the conversation cap applies exactly as for a first message.
 * @route   POST /api/v1/calls/initiate
 * @body    { receiverId, type: 'audio' | 'video' }
 */
exports.initiateCall = asyncHandler(async (req, res, next) => {
  const { receiverId, type } = req.body || {};
  const callerId = req.user.id;

  if (typeof receiverId !== 'string' || !HEX24.test(receiverId)) {
    return next(new ErrorResponse('receiverId is required', 400));
  }
  if (!['audio', 'video'].includes(type)) {
    return next(new ErrorResponse('type must be "audio" or "video"', 400));
  }
  if (receiverId === callerId) {
    return next(new ErrorResponse('Cannot call yourself', 400));
  }

  const [caller, receiver] = await Promise.all([User.findById(callerId), User.findById(receiverId)]);
  if (!receiver) return next(new ErrorResponse('Receiver not found', 404));
  if (!caller) return next(new ErrorResponse('Caller not found', 404));

  const blocked = receiver.blockedUsers?.some((b) => b.userId?.toString() === callerId)
    || caller.blockedUsers?.some((b) => b.userId?.toString() === receiverId);
  if (blocked) return next(new ErrorResponse('Cannot call this user', 403));

  // Same rule as a first text message: if the call message could not start
  // a conversation, the call must not ring either.
  const decision = await evaluateConversationStart({ userId: callerId, receiverId });
  if (!decision.allowed && decision.reason === 'limit') {
    return next(new ErrorResponse(CONVERSATION_START_LIMIT_MESSAGE, 403, 'CONVERSATION_START_LIMIT'));
  }

  const result = await callStateService.startCall({ callerId, receiverId, type });
  if (result.busy === 'caller') {
    return res.status(409).json({ success: false, error: 'You are already in a call', code: 'CALLER_BUSY' });
  }
  if (result.busy === 'receiver') {
    return res.status(409).json({
      success: false,
      error: `${receiver.name || 'They'} is on another call`,
      code: 'CALLEE_BUSY',
      data: { call: result.call },
    });
  }

  const { call } = result;
  const roomName = roomNameFor(call._id);
  let callerToken;
  try {
    callerToken = await mintRoomToken({
      identity: callerId,
      name: caller.name || 'Caller',
      roomName,
      metadata: { role: 'caller', callId: String(call._id) },
    });
  } catch (err) {
    console.error('[calls.initiate] LiveKit mint failed:', err.message);
    await callStateService.transition(call._id, 'fail', { by: 'system' }).catch(() => {});
    return next(new ErrorResponse('Could not start the call', 503));
  }

  if (shouldNotify(receiver, 'calls')) {
    callPushService.sendIncomingCall({ call, caller, receiver, livekitUrl: callerToken.url })
      .catch((err) => console.error('[calls.initiate] push error:', err.message));
  }

  const io = req.app.get('io');
  if (io) {
    io.to(`user_${receiverId}`).emit('call:incoming', {
      callId: String(call._id),
      callUuid: call.callUuid,
      caller: {
        _id: caller._id,
        name: caller.name,
        profilePicture: (caller.images && caller.images[0]) || null,
      },
      callType: type,
      roomName,
    });
  }

  res.status(200).json({
    success: true,
    data: { call, token: callerToken.token, url: callerToken.url, roomName },
  });
});

/**
 * @desc    Receiver accepts. :id is the Mongo id or the callUuid (live iOS
 *          builds get the uuid as the VoIP id).
 * @route   POST /api/v1/calls/:id/accept   body { deviceId? }
 */
exports.acceptCall = asyncHandler(async (req, res, next) => {
  const userId = req.user.id;
  const call = await callStateService.findCall(req.params.id);
  if (!call) return next(new ErrorResponse('Call not found', 404));
  const receiverId = callStateService.receiverOf(call);
  if (!receiverId || String(receiverId) !== userId) {
    return next(new ErrorResponse('Not authorized to accept this call', 403));
  }

  let updated;
  try {
    updated = await callStateService.transition(call._id, 'accept', { by: userId, deviceId: deviceIdFrom(req) });
  } catch (err) {
    if (err instanceof CallStateError) return respondCallState(res, err);
    throw err;
  }

  const roomName = roomNameFor(updated._id);
  const { token, url } = await mintRoomToken({
    identity: userId,
    name: req.user.name || 'Receiver',
    roomName,
    metadata: { role: 'receiver', callId: String(updated._id) },
  });
  res.status(200).json({ success: true, data: { call: updated, token, url, roomName } });
});

/**
 * @route   POST /api/v1/calls/:id/decline   body { deviceId? }
 */
exports.declineCall = asyncHandler(async (req, res, next) => {
  const userId = req.user.id;
  const call = await callStateService.findCall(req.params.id);
  if (!call) return next(new ErrorResponse('Call not found', 404));
  const receiverId = callStateService.receiverOf(call);
  if (!receiverId || String(receiverId) !== userId) {
    return next(new ErrorResponse('Not authorized to decline this call', 403));
  }
  try {
    const updated = await callStateService.transition(call._id, 'decline', { by: userId, deviceId: deviceIdFrom(req) });
    return res.status(200).json({ success: true, data: { call: updated } });
  } catch (err) {
    if (err instanceof CallStateError) return respondCallState(res, err);
    throw err;
  }
});

/**
 * @desc    End from either side. Ringing: the caller cancels, the receiver
 *          declines. Active: ended (completed) and the LiveKit room is
 *          closed. Terminal: idempotent 200 (live builds rely on it).
 * @route   POST /api/v1/calls/:id/end
 */
exports.endCall = asyncHandler(async (req, res, next) => {
  const userId = req.user.id;
  const found = await callStateService.findCall(req.params.id);
  if (!found) return next(new ErrorResponse('Call not found', 404));
  if (!isParticipant(found, userId)) return next(new ErrorResponse('Not authorized to end this call', 403));

  for (let attempt = 0; attempt < 2; attempt++) {
    const current = attempt === 0 ? found : await Call.findById(found._id);
    if (callStateService.TERMINAL_STATUSES.includes(current.status)) {
      return res.status(200).json({ success: true, data: { call: current } });
    }
    let action = 'end';
    if (current.status === 'ringing') action = String(current.initiator) === userId ? 'cancel' : 'decline';
    try {
      const updated = await callStateService.transition(current._id, action, { by: userId, deviceId: deviceIdFrom(req) });
      if (action === 'end' || action === 'cancel') await livekitAdmin.endRoom(roomNameFor(updated._id));
      return res.status(200).json({ success: true, data: { call: updated } });
    } catch (err) {
      if (!(err instanceof CallStateError)) throw err;
      // Lost a race (e.g. accepted between read and write): re-read once.
    }
  }
  const latest = await Call.findById(found._id);
  res.status(200).json({ success: true, data: { call: latest } });
});
```

In `services/callService.js` add before `module.exports` and export it:

```js
/**
 * The user's live call for recovery: ringing where they are the RECEIVER
 * (and younger than the 60 s stale window), or active either way.
 */
const getCurrentCall = async (userId, nowMs = Date.now()) => Call.findOne({
  participants: userId,
  $or: [
    { status: 'active' },
    { status: 'ringing', initiator: { $ne: userId }, startTime: { $gt: new Date(nowMs - 60 * 1000) } },
  ],
}).sort({ startTime: -1 }).populate('participants', 'name images');
```

```js
module.exports = {
  getCachedIceServers,
  createCall,
  updateCallStatus,
  getCallHistory,
  getMissedCallsCount,
  isUserInCall,
  getCall,
  getCurrentCall
};
```

In `routes/calls.js` add `getCurrentCall` to the destructured import and register it before `/:id`:

```js
router.get('/current', getCurrentCall);
```

(placed directly after `router.get('/ice-servers', getIceServers);`).

In `docs/REMAINING_WORK.md` tick `- [x] B6 REST: …`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `for f in test/callController.test.js test/callStateService.test.js test/callEvents.test.js; do node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js $f || break; done`
Expected: all pass (callController: 9 pass).

- [ ] **Step 5: Commit**

```bash
git add controllers/callController.js services/callService.js routes/calls.js test/callController.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): REST on the state machine - busy, id-or-uuid, /calls/current

initiate: 409 CALLER_BUSY (no record) / 409 CALLEE_BUSY (busy record,
message, missed push), the conversation cap applies as for a first message,
only the caller's LiveKit token is minted (receivers get theirs from
/accept). accept/decline/end resolve the Mongo id or the callUuid
(case-insensitive) and carry deviceId; races answer 409 CALL_STATE.
end while ringing is a cancel (caller) or decline (receiver).
GET /calls/current returns the live call (with a fresh token when active)
for resume / cold-start recovery.

Still open (calls): B7-B10; owner items unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---
### Task B7: LiveKit webhook — 20 s reconnect grace, `room_finished`

**Files:**
- Modify: `services/livekitAdminService.js` (add `countParticipants`, export)
- Create: `services/callLivenessService.js`
- Modify: `controllers/livekit.js:35-81` (`webhook`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callLiveness.test.js`

**Interfaces:**
- Consumes: `transition`, `timing.reconnectGraceMs`, `roomNameFor`, `CallStateError` (B2).
- Produces: `livekitAdmin.countParticipants(roomName) → Promise<{ ok: boolean, count: number, missing: boolean }>` (`ok:false` = unknown: env missing, network, 5xx); `callLivenessService.handleWebhookEvent(event) → Promise<boolean>` (true when the room was a call room), `startGrace(callId, identity)`, `cancelGrace(callId, identity)`, `pendingGraceCount()`.

- [ ] **Step 1: Write the failing test**

Create `test/callLiveness.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser, fakeIo, silence } = require('./helpers/callKit');

let restore, svc, admin, liveness, webhook, Call, realCountParticipants;
let nextCount = { ok: true, count: 1, missing: false };

test.before(async () => {
  restore = silence();
  delete process.env.LIVEKIT_API_KEY; delete process.env.LIVEKIT_API_SECRET; delete process.env.LIVEKIT_URL;
  await startDb('callLiveness');
  admin = require('../services/livekitAdminService');
  realCountParticipants = admin.countParticipants; // beforeEach stubs it for every test
  svc = require('../services/callStateService');
  liveness = require('../services/callLivenessService');
  webhook = require('../controllers/livekit').webhook;
  Call = require('../models/Call');
  await Promise.all([Call.syncIndexes(), require('../models/Message').syncIndexes()]);
  require('../lib/callIo').setIo(fakeIo());
});
test.after(async () => { await stopDb(); restore(); });

test('Review focus 4: countParticipants with LiveKit unconfigured is UNKNOWN, not empty', async () => {
  const r = await realCountParticipants('call:0123456789abcdef01234567');
  assert.deepEqual(r, { ok: false, count: 0, missing: false });
});

const send = (event, callId, identity) => new Promise((resolve) => {
  const res = { status() { return this; }, json(body) { resolve(body); } };
  webhook({ livekitEvent: { event, room: { name: `call:${callId}` }, participant: identity ? { identity } : undefined } }, res);
});
const active = async () => {
  const a = await makeUser('a'); const b = await makeUser('b');
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio' });
  svc.clearRingTimer(call._id);
  await svc.transition(call._id, 'accept', { by: b._id });
  return { a, b, call };
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

test.beforeEach(() => {
  svc.timing.reconnectGraceMs = 40;
  admin.countParticipants = async () => nextCount;
});

test('participant_left with no rejoin → ended (completed) after the grace', async () => {
  nextCount = { ok: true, count: 1, missing: false };
  const { b, call } = await active();
  await send('participant_left', call._id, String(b._id));
  assert.equal((await Call.findById(call._id)).status, 'active', 'not before the grace');
  await sleep(120);
  const final = await Call.findById(call._id);
  assert.equal(final.status, 'ended');
  assert.equal(final.endReason, 'completed');
});

test('participant_joined inside the grace cancels it', async () => {
  nextCount = { ok: true, count: 1, missing: false };
  const { b, call } = await active();
  await send('participant_left', call._id, String(b._id));
  await send('participant_joined', call._id, String(b._id));
  await sleep(120);
  assert.equal((await Call.findById(call._id)).status, 'active');
  assert.equal(liveness.pendingGraceCount(), 0);
});

test('at expiry the room is re-checked: 2 participants (lost joined event) keeps the call', async () => {
  nextCount = { ok: true, count: 2, missing: false };
  const { b, call } = await active();
  await send('participant_left', call._id, String(b._id));
  await sleep(120);
  assert.equal((await Call.findById(call._id)).status, 'active');
});

test('Review focus 4: at expiry an admin error leaves the call to the sweeper', async () => {
  nextCount = { ok: false, count: 0, missing: false };
  const { b, call } = await active();
  await send('participant_left', call._id, String(b._id));
  await sleep(120);
  assert.equal((await Call.findById(call._id)).status, 'active');
});

test('room_finished: active → ended, ringing → missed (caller_cancelled)', async () => {
  const { call } = await active();
  await send('room_finished', call._id);
  assert.equal((await Call.findById(call._id)).status, 'ended');

  const a = await makeUser('c'); const b = await makeUser('d');
  const { call: ringing } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio' });
  svc.clearRingTimer(ringing._id);
  await send('room_finished', ringing._id);
  const final = await Call.findById(ringing._id);
  assert.equal(final.status, 'missed');
  assert.equal(final.endReason, 'caller_cancelled');
});

test('participant_left on a ringing call starts no grace (the ring timer owns it)', async () => {
  const a = await makeUser('e'); const b = await makeUser('f');
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio' });
  svc.clearRingTimer(call._id);
  await send('participant_left', call._id, String(a._id));
  assert.equal(liveness.pendingGraceCount(), 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callLiveness.test.js`
Expected: FAIL — `admin.countParticipants is not a function` / `Cannot find module '../services/callLivenessService'`.

- [ ] **Step 3: Implement**

In `services/livekitAdminService.js` add before `module.exports` and export it (`module.exports = { endRoom, disconnectParticipant, countParticipants };`):

```js
/**
 * How many participants a room has. Three answers, never confused:
 *   { ok: true, count, missing: false }  the room exists
 *   { ok: true, count: 0, missing: true } LiveKit says not_found
 *   { ok: false, ... }                    unknown (env unset, network, 5xx):
 *                                         callers must NOT treat this as empty
 */
async function countParticipants(roomName) {
  try {
    const participants = await getClient().listParticipants(roomName);
    return { ok: true, count: Array.isArray(participants) ? participants.length : 0, missing: false };
  } catch (err) {
    const status = err?.status || err?.code;
    if (status === 404 || status === 'not_found') return { ok: true, count: 0, missing: true };
    console.error('[livekitAdmin] listParticipants failed:', roomName, err.message);
    return { ok: false, count: 0, missing: false };
  }
}
```

Create `services/callLivenessService.js`:

```js
'use strict';

/**
 * LiveKit webhook handling for call rooms ("call:<callId>").
 *
 *  participant_left (active call) → 20 s grace; participant_joined for the
 *  same identity cancels it; at expiry the room is re-checked and the call
 *  ends only on a REAL count < 2 or not_found. An unknown answer leaves it
 *  to the sweeper (jobs/callSweepJob.js), which also covers a webhook that
 *  is not configured or a restart mid-grace.
 *  room_finished → active: ended; ringing: the caller left → cancelled.
 */

const Call = require('../models/Call');
const livekitAdmin = require('./livekitAdminService');
const callState = require('./callStateService');

const HEX24 = /^[0-9a-f]{24}$/i;
const graceTimers = new Map();
const keyOf = (callId, identity) => `${String(callId)}:${identity}`;

const callIdFromRoom = (roomName) =>
  (typeof roomName === 'string' && roomName.startsWith('call:') ? roomName.slice('call:'.length) : null);

const swallowState = (promise) => promise.catch((err) => {
  if (!(err instanceof callState.CallStateError)) throw err;
});

const endIfStillUnderfilled = async (callId) => {
  const call = await Call.findById(callId).select('status');
  if (!call || call.status !== 'active') return;
  const room = await livekitAdmin.countParticipants(callState.roomNameFor(callId));
  if (!room.ok) return;
  if (!room.missing && room.count >= 2) return;
  await swallowState(callState.transition(callId, 'end', { by: 'system' }));
};

const startGrace = (callId, identity) => {
  const key = keyOf(callId, identity);
  if (graceTimers.has(key)) return;
  const t = setTimeout(() => {
    graceTimers.delete(key);
    endIfStillUnderfilled(callId).catch((err) => console.error('[calls] grace expiry failed:', err.message));
  }, callState.timing.reconnectGraceMs);
  if (typeof t.unref === 'function') t.unref();
  graceTimers.set(key, t);
};

const cancelGrace = (callId, identity) => {
  const key = keyOf(callId, identity);
  const t = graceTimers.get(key);
  if (t) { clearTimeout(t); graceTimers.delete(key); }
};

const handleWebhookEvent = async (event) => {
  const callId = callIdFromRoom(event && event.room && event.room.name);
  if (!callId || !HEX24.test(callId)) return false;
  const identity = event.participant && event.participant.identity;

  switch (event.event) {
    case 'participant_left': {
      const call = await Call.findById(callId).select('status');
      if (call && call.status === 'active' && identity) startGrace(callId, identity);
      return true;
    }
    case 'participant_joined':
      if (identity) cancelGrace(callId, identity);
      return true;
    case 'room_finished': {
      const call = await Call.findById(callId).select('status');
      if (!call) return true;
      if (call.status === 'active') await swallowState(callState.transition(callId, 'end', { by: 'system' }));
      else if (call.status === 'ringing') await swallowState(callState.transition(callId, 'cancel', { by: 'system' }));
      return true;
    }
    default:
      return true;
  }
};

module.exports = { handleWebhookEvent, startGrace, cancelGrace, pendingGraceCount: () => graceTimers.size };
```

Replace `exports.webhook` in `controllers/livekit.js` with:

```js
exports.webhook = async (req, res) => {
  const event = req.livekitEvent;
  const eventType = event.event;
  const roomName = event.room?.name;
  const participantIdentity = event.participant?.identity;

  try {
    if (roomName && roomName.startsWith('call:')) {
      // 1:1 calls: grace + state machine (services/callLivenessService.js).
      await callLiveness.handleWebhookEvent(event);
    } else if (eventType === 'room_finished' && roomName) {
      await VoiceRoom.updateOne(
        { _id: roomName, status: 'active' },
        { $set: { status: 'ended', endedAt: new Date() } }
      );
    } else if (eventType === 'participant_left' && roomName && participantIdentity) {
      await VoiceRoom.updateOne(
        { _id: roomName },
        { $pull: { participants: { user: participantIdentity } } }
      );
      const room = await VoiceRoom.findById(roomName);
      if (room && room.participants.length === 0) {
        room.status = 'ended';
        room.endedAt = new Date();
        await room.save();
      }
    }
  } catch (e) {
    console.error('[livekit-webhook] handler error for', eventType, ':', e.message);
    // Still respond 200 — LiveKit retries on non-2xx
  }

  res.status(200).json({ ok: true });
};
```

and replace `const Call = require('../models/Call');` (line 5) with `const callLiveness = require('../services/callLivenessService');`.

In `docs/REMAINING_WORK.md` tick `- [x] B7 LiveKit webhook 20 s grace`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callLiveness.test.js`
Expected: 7 pass, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add services/livekitAdminService.js services/callLivenessService.js controllers/livekit.js test/callLiveness.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): LiveKit webhook ends calls after a 20 s reconnect grace

participant_left on an active call starts a 20 s grace that a rejoin
cancels; at expiry the room is re-counted and the call ends only on a real
count < 2 or not_found. A LiveKit admin error is "unknown" and never ends a
call. room_finished ends active calls and cancels ringing ones. Peer drops
finally reach the server.

Still open (calls): B8-B10; owner: set the LiveKit Cloud webhook URL,
migrate:call-indexes, VoIP init check.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task B8: 60 s sweeper + legacy backfill

**Files:**
- Create: `jobs/callSweepJob.js`
- Modify: `jobs/scheduler.js:751` (inside `startScheduler`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callSweep.test.js`

**Interfaces:**
- Consumes: `transition`, `timing`, `roomNameFor`, `CallStateError` (B2); `countParticipants` (B7).
- Produces: `backfillLegacyCalls(now) → { ringing, active }`; `runCallSweep({ now }) → { backfilled, timedOut, ended, flagged }`; `start()`; kill switch `CALL_SWEEP_ENABLED=false`.

- [ ] **Step 1: Write the failing test**

Create `test/callSweep.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser, fakeIo, silence } = require('./helpers/callKit');

let restore, svc, admin, push, sweep, Call, Message;
let nextCount;
const pushes = [];

test.before(async () => {
  restore = silence();
  await startDb('callSweep');
  admin = require('../services/livekitAdminService');
  push = require('../services/callPushService');
  svc = require('../services/callStateService');
  sweep = require('../jobs/callSweepJob');
  Call = require('../models/Call');
  Message = require('../models/Message');
  await Promise.all([Call.syncIndexes(), Message.syncIndexes()]);
  require('../lib/callIo').setIo(fakeIo());
  admin.countParticipants = async () => nextCount;
  push.sendMissedCall = async (args) => { pushes.push(['missed', String(args.call._id)]); };
  push.sendCallCancelled = async (args) => { pushes.push(['cancelled', String(args.call._id)]); };
});
test.after(async () => { await stopDb(); restore(); });
test.beforeEach(() => { pushes.length = 0; nextCount = { ok: true, count: 2, missing: false }; });

const people = async () => [await makeUser('a'), await makeUser('b')];

test('backfill: legacy ringing/active rows close silently (no message, no push)', async () => {
  const [a, b] = await people();
  const base = { participants: [a._id, b._id], initiator: a._id, type: 'audio', startTime: new Date(Date.now() - 86400000) };
  const r = await Call.create({ ...base, status: 'ringing' });
  const x = await Call.create({ ...base, status: 'active', answeredAt: base.startTime });
  await sweep.runCallSweep();
  const [r2, x2] = await Promise.all([Call.findById(r._id), Call.findById(x._id)]);
  assert.equal(r2.status, 'missed'); assert.equal(r2.endReason, 'timeout'); assert.equal(r2.backfilled, true);
  assert.equal(x2.status, 'ended'); assert.equal(x2.backfilled, true);
  assert.equal(await Message.countDocuments({ messageType: 'call' }), 0);
  assert.deepEqual(pushes, []);
});

test('ringing older than 60 s → missed/timeout with one message and the missed push', async () => {
  const [a, b] = await people();
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'audio', now: new Date(Date.now() - 61000) });
  svc.clearRingTimer(call._id);
  await sweep.runCallSweep();
  const final = await Call.findById(call._id);
  assert.equal(final.status, 'missed');
  assert.equal(await Message.countDocuments({ 'media.callData.callId': String(call._id) }), 1);
  assert.ok(pushes.some(([k, id]) => k === 'missed' && id === String(call._id)));
});

const activeCall = async () => {
  const [a, b] = await people();
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'video' });
  svc.clearRingTimer(call._id);
  await svc.transition(call._id, 'accept', { by: b._id });
  return call;
};

test('active with < 2 participants: first sweep flags, a sweep > 20 s later ends it', async () => {
  const call = await activeCall();
  nextCount = { ok: true, count: 1, missing: false };
  const t0 = new Date();
  await sweep.runCallSweep({ now: t0 });
  let c = await Call.findById(call._id);
  assert.equal(c.status, 'active');
  assert.ok(c.underfilledSince);
  await sweep.runCallSweep({ now: new Date(t0.getTime() + 21000) });
  c = await Call.findById(call._id);
  assert.equal(c.status, 'ended');
  assert.equal(c.endReason, 'completed');
});

test('back to 2 participants clears the flag', async () => {
  const call = await activeCall();
  nextCount = { ok: true, count: 1, missing: false };
  const t0 = new Date();
  await sweep.runCallSweep({ now: t0 });
  nextCount = { ok: true, count: 2, missing: false };
  await sweep.runCallSweep({ now: new Date(t0.getTime() + 21000) });
  const c = await Call.findById(call._id);
  assert.equal(c.status, 'active');
  assert.equal(c.underfilledSince, null);
});

test('room missing → ended immediately', async () => {
  const call = await activeCall();
  nextCount = { ok: true, count: 0, missing: true };
  await sweep.runCallSweep();
  assert.equal((await Call.findById(call._id)).status, 'ended');
});

test('Review focus 4: an admin error never ends or flags an active call', async () => {
  const call = await activeCall();
  nextCount = { ok: false, count: 0, missing: false };
  const t0 = new Date();
  await sweep.runCallSweep({ now: t0 });
  await sweep.runCallSweep({ now: new Date(t0.getTime() + 30000) });
  const c = await Call.findById(call._id);
  assert.equal(c.status, 'active');
  assert.equal(c.underfilledSince, null);
});

test('active longer than 4 h ends even when LiveKit cannot be asked', async () => {
  const call = await activeCall();
  nextCount = { ok: false, count: 0, missing: false };
  await sweep.runCallSweep({ now: new Date(Date.now() + 4 * 3600 * 1000 + 1000) });
  assert.equal((await Call.findById(call._id)).status, 'ended');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callSweep.test.js`
Expected: FAIL — `Cannot find module '../jobs/callSweepJob'`.

- [ ] **Step 3: Implement**

Create `jobs/callSweepJob.js`:

```js
'use strict';

/**
 * Call sweeper (every 60 s).
 *
 *  1. Backfill: rows created before callUuid existed (the 168 ringing + 4
 *     active found on 2026-10-08) are closed silently — backfilled: true, no
 *     message, no push. Keyed on the missing callUuid, so it is idempotent
 *     and never touches a call created by this code.
 *  2. ringing older than 60 s → missed (timeout). Covers a lost ring timer.
 *  3. active:
 *     - older than 4 h → ended, whatever LiveKit says;
 *     - LiveKit room not_found → ended;
 *     - fewer than 2 participants: first sighting sets underfilledSince, a
 *       later sweep still < 2 with underfilledSince ≥ 20 s old → ended;
 *       back to 2 clears it;
 *     - LiveKit admin error → skipped (unknown is not empty).
 *
 * Kill switch: CALL_SWEEP_ENABLED=false.
 */

const Call = require('../models/Call');
const livekitAdmin = require('../services/livekitAdminService');
const callState = require('../services/callStateService');

const INTERVAL_MS = 60 * 1000;

const swallowState = (promise) => promise.catch((err) => {
  if (!(err instanceof callState.CallStateError)) throw err;
});

async function backfillLegacyCalls(now = new Date()) {
  const ringing = await Call.updateMany(
    { status: 'ringing', callUuid: { $exists: false } },
    { $set: { status: 'missed', endReason: 'timeout', endTime: now, duration: 0, backfilled: true } }
  );
  const active = await Call.updateMany(
    { status: 'active', callUuid: { $exists: false } },
    { $set: { status: 'ended', endReason: 'completed', endTime: now, duration: 0, backfilled: true } }
  );
  return { ringing: ringing.modifiedCount, active: active.modifiedCount };
}

async function runCallSweep({ now = new Date() } = {}) {
  const summary = { backfilled: await backfillLegacyCalls(now), timedOut: 0, ended: 0, flagged: 0 };

  const staleCutoff = new Date(now.getTime() - callState.timing.staleRingingMs);
  const stale = await Call.find({ status: 'ringing', startTime: { $lt: staleCutoff } }).select('_id').lean();
  for (const { _id } of stale) {
    await swallowState(callState.transition(_id, 'timeout', { by: 'system', now }));
    summary.timedOut++;
  }

  const actives = await Call.find({ status: 'active' })
    .select('_id answeredAt startTime underfilledSince').lean();
  for (const call of actives) {
    const since = new Date(call.answeredAt || call.startTime).getTime();
    if (now.getTime() - since > callState.timing.activeCapMs) {
      await swallowState(callState.transition(call._id, 'end', { by: 'system', now }));
      summary.ended++;
      continue;
    }

    const room = await livekitAdmin.countParticipants(callState.roomNameFor(call._id));
    if (!room.ok) continue;
    if (room.missing) {
      await swallowState(callState.transition(call._id, 'end', { by: 'system', now }));
      summary.ended++;
      continue;
    }
    if (room.count >= 2) {
      if (call.underfilledSince) {
        await Call.updateOne({ _id: call._id, status: 'active' }, { $set: { underfilledSince: null } });
      }
      continue;
    }
    if (!call.underfilledSince) {
      await Call.updateOne({ _id: call._id, status: 'active', underfilledSince: null }, { $set: { underfilledSince: now } });
      summary.flagged++;
      continue;
    }
    if (now.getTime() - new Date(call.underfilledSince).getTime() >= callState.timing.reconnectGraceMs) {
      await swallowState(callState.transition(call._id, 'end', { by: 'system', now }));
      summary.ended++;
    }
  }
  return summary;
}

function start() {
  const tick = () => runCallSweep()
    .then((s) => {
      if (s.backfilled.ringing || s.backfilled.active || s.timedOut || s.ended) {
        console.log('[callSweep]', JSON.stringify(s));
      }
    })
    .catch((err) => console.error('[callSweep] failed:', err.message));
  setInterval(tick, INTERVAL_MS);
  setTimeout(tick, 5000);
  console.log('📅 Call sweeper scheduled (every 60 s)');
}

module.exports = { runCallSweep, backfillLegacyCalls, start, INTERVAL_MS };
```

In `jobs/scheduler.js`, inside `startScheduler`, directly after the line `scheduleTutorMemoryDecay();` (751) add:

```js
  // 1:1 calls: stale ringing, dead active calls, legacy backfill (every 60 s)
  if (process.env.CALL_SWEEP_ENABLED !== 'false') {
    require('./callSweepJob').start();
  }
```

In `docs/REMAINING_WORK.md` tick `- [x] B8 60 s sweeper + backfill …` and add to the Flags table: `| \`CALL_SWEEP_ENABLED\` | call sweeper (default ON; set \`false\` to stop it) | on by default |`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `for f in test/callSweep.test.js test/schedulerFlagTiming.test.js; do node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js $f || break; done`
Expected: callSweep 7 pass; scheduler test still passes.

- [ ] **Step 5: Commit**

```bash
git add jobs/callSweepJob.js jobs/scheduler.js test/callSweep.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): 60 s call sweeper and silent backfill of legacy stuck calls

Rows without callUuid (the 168 ringing / 4 active found in prod) are closed
with backfilled: true - no message, no push, not in history. Ringing older
than 60 s times out; active calls end when LiveKit says the room is gone, on
a second sighting with < 2 participants 20 s apart, or after 4 h. A LiveKit
admin error is never read as an empty room. Kill switch CALL_SWEEP_ENABLED.

Still open (calls): B9-B10; owner: LiveKit webhook URL,
migrate:call-indexes, VoIP init check.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task B9: History API, missed count, mark seen

**Files:**
- Modify: `services/callService.js` (`getCallHistory` 87-120, `getMissedCallsCount` 125-137; add `markMissedSeen`, `toHistoryItem`)
- Modify: `controllers/callController.js` (`getCallHistory` 28-62, `getMissedCallsCount` 97-115; add `markMissedCallsSeen`)
- Modify: `routes/calls.js`
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callHistory.test.js`

**Interfaces:**
- Consumes: `outcomeFor` (B2).
- Produces:
  - `GET /calls?page=&limit=` (default 30, max 50) → `{ success, data: [{ id, callUuid, type, direction: 'in'|'out', outcome, duration, otherParty: { id, name, avatar }, createdAt }], pagination: { total, page, limit, hasMore } }` — statuses `ended|missed|rejected|busy`, excluding `backfilled` and `busy/unavailable`.
  - `GET /calls/missed/count` → `{ data: { count } }` = receiver-side `no_answer|cancelled|busy` with `seenByReceiverAt: null`.
  - `POST /calls/missed/seen` → `{ data: { updated } }`.
  - `callService.getCallHistory(userId, { page, limit })`, `getMissedCallsCount(userId)`, `markMissedSeen(userId, now)`, `toHistoryItem(call, userId)`.

- [ ] **Step 1: Write the failing test**

Create `test/callHistory.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser, asHandler, silence } = require('./helpers/callKit');

let restore, ctl, Call, me, ada, bo;

test.before(async () => {
  restore = silence();
  await startDb('callHistory');
  ctl = require('../controllers/callController');
  Call = require('../models/Call');
  me = await makeUser('me');
  ada = await makeUser('ada', { images: ['https://cdn.test/ada.jpg'] });
  bo = await makeUser('bo');
  const t = (m) => new Date(Date.UTC(2026, 9, 8, 12, m));
  const row = (initiator, other, status, endReason, extra = {}) => Call.create({
    participants: [initiator._id, other._id], initiator: initiator._id, type: 'audio',
    status, endReason, callUuid: require('crypto').randomUUID(), ...extra,
  });
  await row(me, ada, 'ended', 'completed', { duration: 83, createdAt: t(1) });
  await row(ada, me, 'missed', 'timeout', { createdAt: t(2) });
  await row(bo, me, 'missed', 'caller_cancelled', { type: 'video', createdAt: t(3) });
  await row(ada, me, 'busy', 'busy', { createdAt: t(4) });
  await row(ada, me, 'rejected', 'rejected', { createdAt: t(5) });
  await row(me, bo, 'missed', 'timeout', { createdAt: t(6) });              // caller side: not "missed" for me
  await row(ada, me, 'busy', 'unavailable', { createdAt: t(7) });           // Phase 2 row: hidden
  await row(ada, me, 'failed', 'failed', { createdAt: t(8) });              // hidden
  await row(ada, me, 'missed', 'timeout', { backfilled: true, createdAt: t(9) }); // hidden
});
test.after(async () => { await stopDb(); restore(); });

const req = (u, query = {}) => ({ user: { id: String(u._id) }, query, params: {}, body: {} });

test('history: §3 outcomes, direction, otherParty; hides backfilled / unavailable / failed', async () => {
  const res = await asHandler(ctl.getCallHistory)(req(me));
  assert.equal(res.status, 200);
  const items = res.body.data;
  assert.deepEqual(items.map((i) => [i.direction, i.outcome]), [
    ['out', 'no_answer'], ['in', 'declined'], ['in', 'busy'], ['in', 'cancelled'], ['in', 'no_answer'], ['out', 'completed'],
  ]);
  const completed = items[items.length - 1];
  assert.equal(completed.duration, 83);
  assert.deepEqual(completed.otherParty, { id: String(ada._id), name: 'ada', avatar: 'https://cdn.test/ada.jpg' });
  assert.deepEqual(Object.keys(completed).sort(),
    ['callUuid', 'createdAt', 'direction', 'duration', 'id', 'otherParty', 'outcome', 'type']);
  assert.equal(res.body.pagination.limit, 30);
  assert.equal(res.body.pagination.total, 6);
});

test('missed count = receiver-side no_answer + cancelled + busy, unseen; seen clears it', async () => {
  let res = await asHandler(ctl.getMissedCallsCount)(req(me));
  assert.equal(res.body.data.count, 3);
  res = await asHandler(ctl.markMissedCallsSeen)(req(me));
  assert.equal(res.body.data.updated, 3);
  res = await asHandler(ctl.getMissedCallsCount)(req(me));
  assert.equal(res.body.data.count, 0);
  res = await asHandler(ctl.getMissedCallsCount)(req(bo));
  assert.equal(res.body.data.count, 1, "bo's unanswered incoming from me");
});

test('paging: limit is capped at 50 and page 2 continues', async () => {
  const res = await asHandler(ctl.getCallHistory)(req(me, { page: '2', limit: '4' }));
  assert.equal(res.body.data.length, 2);
  assert.equal(res.body.pagination.hasMore, false);
  const capped = await asHandler(ctl.getCallHistory)(req(me, { limit: '500' }));
  assert.equal(capped.body.pagination.limit, 50);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callHistory.test.js`
Expected: FAIL — items lack `outcome`/`id`, busy rows missing, `ctl.markMissedCallsSeen is not a function`.

- [ ] **Step 3: Implement**

In `services/callService.js` add `const { outcomeFor } = require('./callStateService');` under the existing requires, and replace `getCallHistory` and `getMissedCallsCount` with:

```js
const HISTORY_STATUSES = ['ended', 'missed', 'rejected', 'busy'];

const historyFilter = (userId) => ({
  participants: userId,
  status: { $in: HISTORY_STATUSES },
  backfilled: { $ne: true },
  endReason: { $ne: 'unavailable' },
});

/** Receiver-side calls that §3 counts as missed and the user has not seen. */
const missedFilter = (userId) => ({
  participants: userId,
  initiator: { $ne: userId },
  backfilled: { $ne: true },
  seenByReceiverAt: null,
  $or: [
    { status: 'missed', endReason: { $in: ['timeout', 'caller_cancelled', 'missed'] } },
    { status: 'busy', endReason: 'busy' },
  ],
});

/** One Calls-list row. No display labels: the app derives them from §3. */
const toHistoryItem = (call, userId) => {
  const uid = String(userId);
  const other = (call.participants || []).find((p) => String(p._id || p) !== uid);
  return {
    id: String(call._id),
    callUuid: call.callUuid || null,
    type: call.type,
    direction: String(call.initiator) === uid ? 'out' : 'in',
    outcome: outcomeFor(call),
    duration: Number.isFinite(call.duration) ? Math.max(0, Math.floor(call.duration)) : 0,
    otherParty: other && other._id ? {
      id: String(other._id),
      name: other.name || '',
      avatar: (Array.isArray(other.images) && other.images[0]) || null,
    } : null,
    createdAt: call.createdAt,
  };
};

const getCallHistory = async (userId, { page = 1, limit = 30 } = {}) => {
  const skip = (page - 1) * limit;
  const filter = historyFilter(userId);
  const [calls, total] = await Promise.all([
    Call.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit)
      .populate('participants', 'name images').lean(),
    Call.countDocuments(filter),
  ]);
  return {
    items: calls.map((c) => toHistoryItem(c, userId)),
    pagination: { total, page, limit, hasMore: skip + calls.length < total },
  };
};

const getMissedCallsCount = (userId) => Call.countDocuments(missedFilter(userId));

const markMissedSeen = async (userId, now = new Date()) => {
  const res = await Call.updateMany(missedFilter(userId), { $set: { seenByReceiverAt: now } });
  return res.modifiedCount;
};
```

and add `markMissedSeen, toHistoryItem` to `module.exports`.

In `controllers/callController.js` replace `getCallHistory` and `getMissedCallsCount` with:

```js
exports.getCallHistory = asyncHandler(async (req, res) => {
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(Math.max(1, parseInt(req.query.limit, 10) || 30), 50);
  const { items, pagination } = await callService.getCallHistory(req.user.id, { page, limit });
  res.status(200).json({ success: true, data: items, pagination });
});

exports.getMissedCallsCount = asyncHandler(async (req, res) => {
  const count = await callService.getMissedCallsCount(req.user.id);
  res.status(200).json({ success: true, data: { count } });
});

/**
 * @desc    The Calls list was opened: clear the missed badge.
 * @route   POST /api/v1/calls/missed/seen
 */
exports.markMissedCallsSeen = asyncHandler(async (req, res) => {
  const updated = await callService.markMissedSeen(req.user.id);
  res.status(200).json({ success: true, data: { updated } });
});
```

In `routes/calls.js` import `markMissedCallsSeen` and register it before `/:id`, after `/missed/count`:

```js
router.post('/missed/seen', markMissedCallsSeen);
```

In `docs/REMAINING_WORK.md` tick `- [x] B9 history API + missed count/seen`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `for f in test/callHistory.test.js test/callController.test.js; do node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js $f || break; done`
Expected: callHistory 3 pass; callController still 9 pass.

- [ ] **Step 5: Commit**

```bash
git add services/callService.js controllers/callController.js routes/calls.js test/callHistory.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): history API with §3 outcomes, missed count and mark-seen

GET /calls (30 per page, max 50) returns {id, callUuid, type, direction,
outcome, duration, otherParty{id,name,avatar}, createdAt}, includes busy and
hides backfilled, unavailable and failed rows. Missed count = receiver-side
no_answer / cancelled / busy not yet seen; POST /calls/missed/seen clears it.

Still open (calls): B10; owner items unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task B10: Slim relay handler; delete the legacy socket call path

**Files:**
- Create: `socket/callRelayHandler.js`
- Modify: `socket/socketHandler.js:8` and `:407`
- Delete: `socket/callHandler.js`
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/callRelay.test.js`

**Interfaces:**
- Consumes: `transition`, `CallStateError` (B2).
- Produces: `registerCallRelayHandlers(socket, io)` registering exactly `call:mute`, `call:video-toggle`, `call:reconnecting`, `call:reconnected`, `call:failed`. Relays go to the other participant's room only; a non-participant gets `{ status: 'error' }` and nothing is relayed. `call:failed` transitions `ringing|active → failed`.

- [ ] **Step 1: Write the failing test**

Create `test/callRelay.test.js`:

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { startDb, stopDb, makeUser, fakeIo, silence } = require('./helpers/callKit');

let restore, svc, relay, Call, io;

test.before(async () => {
  restore = silence();
  await startDb('callRelay');
  svc = require('../services/callStateService');
  relay = require('../socket/callRelayHandler');
  Call = require('../models/Call');
  await Promise.all([Call.syncIndexes(), require('../models/Message').syncIndexes()]);
});
test.after(async () => { await stopDb(); restore(); });
test.beforeEach(() => { io = fakeIo(); require('../lib/callIo').setIo(io); });

const socketFor = (userId) => {
  const handlers = {};
  return { user: { id: String(userId) }, on: (event, fn) => { handlers[event] = fn; }, handlers };
};
const ack = (handler, data) => new Promise((resolve) => handler(data, resolve));
const activeCall = async () => {
  const a = await makeUser('a'); const b = await makeUser('b');
  const { call } = await svc.startCall({ callerId: a._id, receiverId: b._id, type: 'video' });
  svc.clearRingTimer(call._id);
  await svc.transition(call._id, 'accept', { by: b._id });
  return { a, b, call };
};

test('registers exactly the in-call relays (initiate/answer/end/missed are gone)', () => {
  const s = socketFor('x');
  relay.registerCallRelayHandlers(s, io);
  assert.deepEqual(Object.keys(s.handlers).sort(),
    ['call:failed', 'call:mute', 'call:reconnected', 'call:reconnecting', 'call:video-toggle']);
  assert.equal(fs.existsSync(path.join(__dirname, '..', 'socket', 'callHandler.js')), false);
});

test('mute / video-toggle / reconnecting relay to the other participant only', async () => {
  const { a, b, call } = await activeCall();
  const s = socketFor(a._id);
  relay.registerCallRelayHandlers(s, io);
  const id = String(call._id);
  assert.deepEqual(await ack(s.handlers['call:mute'], { callId: id, isMuted: true }), { status: 'success' });
  assert.deepEqual(await ack(s.handlers['call:video-toggle'], { callId: id, isVideoEnabled: false }), { status: 'success' });
  await ack(s.handlers['call:reconnecting'], { callId: id });
  assert.deepEqual(io.sent.map((e) => [e.event, e.rooms]), [
    ['call:mute', [`user_${b._id}`]],
    ['call:video-toggle', [`user_${b._id}`]],
    ['call:peer-reconnecting', [`user_${b._id}`]],
  ]);
  assert.deepEqual(io.sent[0].payload, { callId: id, userId: String(a._id), isMuted: true });
});

test('a non-participant is refused and nothing is relayed', async () => {
  const { call } = await activeCall();
  const stranger = await makeUser('z');
  const s = socketFor(stranger._id);
  relay.registerCallRelayHandlers(s, io);
  const r = await ack(s.handlers['call:mute'], { callId: String(call._id), isMuted: true });
  assert.equal(r.status, 'error');
  assert.equal(io.sent.length, 0);
  assert.equal((await ack(s.handlers['call:mute'], { callId: { $ne: null }, isMuted: true })).status, 'error');
});

test('call:failed ends the call through the state machine and relays to the peer', async () => {
  const { a, b, call } = await activeCall();
  const s = socketFor(a._id);
  relay.registerCallRelayHandlers(s, io);
  await ack(s.handlers['call:failed'], { callId: String(call._id), reason: 'ice' });
  assert.equal((await Call.findById(call._id)).status, 'failed');
  const failed = io.eventsNamed('call:failed');
  assert.deepEqual(failed.map((e) => e.rooms), [[`user_${b._id}`]]);
  assert.equal(io.eventsNamed('call:state')[0].payload.status, 'failed');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callRelay.test.js`
Expected: FAIL — `Cannot find module '../socket/callRelayHandler'`.

- [ ] **Step 3: Implement**

Create `socket/callRelayHandler.js`:

```js
'use strict';

/**
 * In-call socket relays that live builds use while connected. Everything
 * else about a call (initiate / accept / decline / end / missed / timeouts)
 * is REST + services/callStateService.js; the old socket path and its
 * in-memory activeCalls map are gone.
 *
 * Every relay checks the caller is a participant of the Call record and
 * forwards only to the other participant's room.
 */

const Call = require('../models/Call');
const callState = require('../services/callStateService');

const isHex = (v) => typeof v === 'string' && /^[0-9a-f]{24}$/i.test(v);

const participantCall = async (callId, userId) => {
  if (!isHex(callId)) return null;
  const call = await Call.findById(callId).select('participants status initiator');
  if (!call || !call.participants.some((p) => String(p) === String(userId))) return null;
  return call;
};

const otherOf = (call, userId) => call.participants.find((p) => String(p) !== String(userId));

const registerCallRelayHandlers = (socket, io) => {
  const userId = String(socket.user.id);

  const relay = (event, outEvent, isValid, shape) => {
    socket.on(event, async (data, callback) => {
      const reply = typeof callback === 'function' ? callback : () => {};
      try {
        if (!data || !isValid(data)) throw new Error('Invalid payload');
        const call = await participantCall(data.callId, userId);
        if (!call) throw new Error('Not authorized for this call');
        if (call.status !== 'active') throw new Error('Call is not active');
        const other = otherOf(call, userId);
        if (other) io.to(`user_${String(other)}`).emit(outEvent, shape(data));
        reply({ status: 'success' });
      } catch (err) {
        reply({ status: 'error', error: err.message });
      }
    });
  };

  relay('call:mute', 'call:mute', (d) => typeof d.isMuted === 'boolean',
    (d) => ({ callId: d.callId, userId, isMuted: d.isMuted }));
  relay('call:video-toggle', 'call:video-toggle', (d) => typeof d.isVideoEnabled === 'boolean',
    (d) => ({ callId: d.callId, userId, isVideoEnabled: d.isVideoEnabled }));
  relay('call:reconnecting', 'call:peer-reconnecting', () => true, (d) => ({ callId: d.callId, userId }));
  relay('call:reconnected', 'call:peer-reconnected', () => true, (d) => ({ callId: d.callId, userId }));

  socket.on('call:failed', async (data, callback) => {
    const reply = typeof callback === 'function' ? callback : () => {};
    try {
      const call = await participantCall(data && data.callId, userId);
      if (!call) throw new Error('Not authorized for this call');
      try {
        await callState.transition(call._id, 'fail', { by: userId });
      } catch (err) {
        if (!(err instanceof callState.CallStateError)) throw err;
      }
      const other = otherOf(call, userId);
      if (other) {
        io.to(`user_${String(other)}`).emit('call:failed', {
          callId: String(call._id),
          reason: (data && typeof data.reason === 'string' && data.reason.slice(0, 200)) || 'Connection failed',
        });
      }
      reply({ status: 'success' });
    } catch (err) {
      reply({ status: 'error', error: err.message });
    }
  });
};

module.exports = { registerCallRelayHandlers };
```

In `socket/socketHandler.js` replace line 8

```js
const { registerCallHandlers } = require('./callHandler');
```

with

```js
const { registerCallRelayHandlers } = require('./callRelayHandler');
```

and line 407 `registerCallHandlers(socket, io);` with `registerCallRelayHandlers(socket, io);`.

Delete the legacy handler: `git rm socket/callHandler.js`.

In `docs/REMAINING_WORK.md` tick `- [x] B10 slim relay handler; legacy \`socket/callHandler.js\` deleted`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `for f in test/callRelay.test.js test/socketHandlerBoot.test.js test/authAudit.socketDisconnect.test.js test/callSchema.test.js test/callStateService.test.js test/callEvents.test.js test/callMessages.test.js test/callPush.test.js test/callController.test.js test/callLiveness.test.js test/callSweep.test.js test/callHistory.test.js; do node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js $f || break; done`
Expected: every file passes.

- [ ] **Step 5: Commit**

```bash
git add socket/callRelayHandler.js socket/socketHandler.js test/callRelay.test.js docs/REMAINING_WORK.md
git commit -F - <<'MSG'
refactor(calls): slim participant-checked relays; delete the legacy socket path

socket/callHandler.js held the only initiate/answer/end/missed logic, which
no app build used; it is gone with its in-memory activeCalls map. The relays
live builds use in a call (mute, video-toggle, reconnecting, reconnected,
failed) move to socket/callRelayHandler.js, check participation against the
Call record and reach only the other participant. call:failed goes through
the state machine.

Backend Phase 1 is code-complete. Still open (calls): deploy; owner:
npm run migrate:call-indexes on prod, LiveKit Cloud webhook URL, confirm
[voipPush] initialised; native review of missed-call push strings; app
Phase 1; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

# Phase 1 — App

All app commands run from `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app` (the git root is its parent; `git add` paths below are relative to `bananatalk_app`).

### Task A1: Phase 1 call strings in all 19 locales

**Files:**
- Modify: `lib/l10n/app_{ar,de,en,es,fr,hi,id,it,ja,ko,pt,ru,tg,th,tl,tr,vi,zh,zh_TW}.arb`
- Regenerate: `lib/l10n/app_localizations*.dart` (`flutter gen-l10n`)
- Modify: `docs/REMAINING_WORK.md` (§0b)
- Test: `test/l10n/call_strings_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces (`AppLocalizations`): `callLabelOutgoing(String type)`, `callLabelIncoming(String type)`, `callLabelNoAnswer(String type)`, `callLabelMissed(String type)`, `callLabelCancelled(String type)`, `callLabelDeclinedOutgoing(String type)`, `callLabelDeclinedIncoming(String type)` (ICU select: `'video'` vs anything else = voice), `callLabelBusy(String name)`, `callsTitle`, `callsEmpty`, `callCameraPaused`, `callFullScreenIntentTitle`, `callFullScreenIntentBody`, `callForegroundTitle`, `callForegroundBody`.

- [ ] **Step 1: Write the failing test**

Create `test/l10n/call_strings_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

const _callKeys = [
  'callLabelOutgoing',
  'callLabelIncoming',
  'callLabelNoAnswer',
  'callLabelMissed',
  'callLabelCancelled',
  'callLabelDeclinedOutgoing',
  'callLabelDeclinedIncoming',
  'callLabelBusy',
  'callsTitle',
  'callsEmpty',
  'callCameraPaused',
  'callFullScreenIntentTitle',
  'callFullScreenIntentBody',
  'callForegroundTitle',
  'callForegroundBody',
];

void main() {
  test('every locale defines every Phase 1 call string', () {
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList();
    expect(arbs.length, 19);
    for (final file in arbs) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in _callKeys) {
        final value = map[key];
        expect(value is String && value.trim().isNotEmpty, isTrue,
            reason: '${file.path} is missing $key');
      }
      for (final key in _callKeys.where(
          (k) => k.startsWith('callLabel') && k != 'callLabelBusy')) {
        expect(
          map[key],
          allOf(contains('{type, select,'), contains('video{'),
              contains('other{')),
          reason: '${file.path} $key must select on type',
        );
      }
      expect(map['callLabelBusy'], contains('{name}'), reason: file.path);
    }
  });

  test('generated getters render both branches and the name', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.callLabelMissed('video'), 'Missed video call');
    expect(en.callLabelMissed('audio'), 'Missed voice call');
    expect(en.callLabelNoAnswer('audio'), 'Voice call · No answer');
    expect(en.callLabelBusy('Ada'), 'Ada was on another call');
    final ko = lookupAppLocalizations(const Locale('ko'));
    expect(ko.callLabelMissed('audio'), '부재중 음성 통화');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/l10n/call_strings_test.dart`
Expected: FAIL — compile error `The method 'callLabelMissed' isn't defined for the type 'AppLocalizations'`.

- [ ] **Step 3: Implement**

Run this one-off script (not committed) from the app directory; it appends the keys to each `.arb` without re-serialising the existing content:

```bash
python3 - <<'PY'
import json, pathlib

KEYS = ['callLabelOutgoing', 'callLabelIncoming', 'callLabelNoAnswer', 'callLabelMissed',
        'callLabelCancelled', 'callLabelDeclinedOutgoing', 'callLabelDeclinedIncoming',
        'callLabelBusy', 'callsTitle', 'callsEmpty', 'callCameraPaused',
        'callFullScreenIntentTitle', 'callFullScreenIntentBody',
        'callForegroundTitle', 'callForegroundBody']
SELECT = set(KEYS[:7])

# Select keys are (video, voice). Machine drafts except en; native review is an open item.
T = {
 'en': [('Outgoing video call', 'Outgoing voice call'), ('Incoming video call', 'Incoming voice call'),
        ('Video call · No answer', 'Voice call · No answer'), ('Missed video call', 'Missed voice call'),
        ('Cancelled video call', 'Cancelled voice call'), ('Video call declined', 'Voice call declined'),
        ('Declined video call', 'Declined voice call'), '{name} was on another call', 'Calls', 'No calls yet',
        'Camera paused', 'Show calls on the lock screen',
        "Allow BananaTalk to show incoming calls full screen so you don't miss them while your phone is locked.",
        'Call in progress', 'Tap to return to your call'],
 'ko': [('영상 발신 통화', '음성 발신 통화'), ('영상 수신 통화', '음성 수신 통화'),
        ('영상 통화 · 응답 없음', '음성 통화 · 응답 없음'), ('부재중 영상 통화', '부재중 음성 통화'),
        ('취소된 영상 통화', '취소된 음성 통화'), ('영상 통화 거절됨', '음성 통화 거절됨'),
        ('거절한 영상 통화', '거절한 음성 통화'), '{name}님은 다른 통화 중이었습니다', '통화', '아직 통화 기록이 없습니다',
        '카메라 일시 중지됨', '잠금 화면에 전화 표시',
        '휴대폰이 잠겨 있어도 전화를 놓치지 않도록 BananaTalk가 수신 전화를 전체 화면으로 표시하도록 허용하세요.',
        '통화 중', '탭하여 통화로 돌아가기'],
 'ja': [('発信ビデオ通話', '発信音声通話'), ('着信ビデオ通話', '着信音声通話'),
        ('ビデオ通話・応答なし', '音声通話・応答なし'), ('不在着信（ビデオ）', '不在着信（音声）'),
        ('キャンセルしたビデオ通話', 'キャンセルした音声通話'), ('ビデオ通話が拒否されました', '音声通話が拒否されました'),
        ('拒否したビデオ通話', '拒否した音声通話'), '{name}さんは別の通話中でした', '通話', 'まだ通話履歴はありません',
        'カメラ一時停止中', 'ロック画面に着信を表示',
        'スマートフォンがロックされていても着信を見逃さないよう、BananaTalkに全画面での着信表示を許可してください。',
        '通話中', 'タップして通話に戻る'],
 'zh': [('视频去电', '语音去电'), ('视频来电', '语音来电'), ('视频通话 · 无人接听', '语音通话 · 无人接听'),
        ('未接视频通话', '未接语音通话'), ('已取消的视频通话', '已取消的语音通话'), ('视频通话被拒绝', '语音通话被拒绝'),
        ('已拒绝的视频通话', '已拒绝的语音通话'), '{name}正在通话中', '通话', '暂无通话记录', '摄像头已暂停',
        '在锁屏上显示来电', '允许 BananaTalk 全屏显示来电，这样手机锁定时也不会错过来电。', '通话中', '点按返回通话'],
 'zh_TW': [('視訊撥出通話', '語音撥出通話'), ('視訊來電', '語音來電'), ('視訊通話 · 無人接聽', '語音通話 · 無人接聽'),
        ('未接視訊來電', '未接語音來電'), ('已取消的視訊通話', '已取消的語音通話'), ('視訊通話遭拒', '語音通話遭拒'),
        ('已拒接的視訊通話', '已拒接的語音通話'), '{name}正在通話中', '通話', '尚無通話紀錄', '相機已暫停',
        '在鎖定畫面顯示來電', '允許 BananaTalk 以全螢幕顯示來電，即使手機鎖定也不會錯過。', '通話中', '輕觸以返回通話'],
 'es': [('Videollamada saliente', 'Llamada de voz saliente'), ('Videollamada entrante', 'Llamada de voz entrante'),
        ('Videollamada · Sin respuesta', 'Llamada de voz · Sin respuesta'), ('Videollamada perdida', 'Llamada de voz perdida'),
        ('Videollamada cancelada', 'Llamada de voz cancelada'), ('Videollamada rechazada', 'Llamada de voz rechazada'),
        ('Rechazaste una videollamada', 'Rechazaste una llamada de voz'), '{name} estaba en otra llamada', 'Llamadas',
        'Aún no hay llamadas', 'Cámara en pausa', 'Mostrar llamadas en la pantalla de bloqueo',
        'Permite que BananaTalk muestre las llamadas entrantes a pantalla completa para que no te las pierdas con el teléfono bloqueado.',
        'Llamada en curso', 'Toca para volver a la llamada'],
 'fr': [('Appel vidéo sortant', 'Appel vocal sortant'), ('Appel vidéo entrant', 'Appel vocal entrant'),
        ('Appel vidéo · Pas de réponse', 'Appel vocal · Pas de réponse'), ('Appel vidéo manqué', 'Appel vocal manqué'),
        ('Appel vidéo annulé', 'Appel vocal annulé'), ('Appel vidéo refusé', 'Appel vocal refusé'),
        ('Appel vidéo refusé par vous', 'Appel vocal refusé par vous'), '{name} était déjà en ligne', 'Appels',
        "Aucun appel pour l'instant", 'Caméra en pause', "Afficher les appels sur l'écran de verrouillage",
        'Autorisez BananaTalk à afficher les appels entrants en plein écran pour ne pas les manquer lorsque votre téléphone est verrouillé.',
        'Appel en cours', "Touchez pour revenir à l'appel"],
 'de': [('Ausgehender Videoanruf', 'Ausgehender Sprachanruf'), ('Eingehender Videoanruf', 'Eingehender Sprachanruf'),
        ('Videoanruf · Keine Antwort', 'Sprachanruf · Keine Antwort'), ('Verpasster Videoanruf', 'Verpasster Sprachanruf'),
        ('Abgebrochener Videoanruf', 'Abgebrochener Sprachanruf'), ('Videoanruf abgelehnt', 'Sprachanruf abgelehnt'),
        ('Abgelehnter Videoanruf', 'Abgelehnter Sprachanruf'), '{name} war in einem anderen Gespräch', 'Anrufe',
        'Noch keine Anrufe', 'Kamera pausiert', 'Anrufe auf dem Sperrbildschirm anzeigen',
        'Erlaube BananaTalk, eingehende Anrufe im Vollbild anzuzeigen, damit du sie auch bei gesperrtem Telefon nicht verpasst.',
        'Anruf läuft', 'Tippen, um zum Anruf zurückzukehren'],
 'it': [('Videochiamata in uscita', 'Chiamata vocale in uscita'), ('Videochiamata in arrivo', 'Chiamata vocale in arrivo'),
        ('Videochiamata · Nessuna risposta', 'Chiamata vocale · Nessuna risposta'), ('Videochiamata persa', 'Chiamata vocale persa'),
        ('Videochiamata annullata', 'Chiamata vocale annullata'), ('Videochiamata rifiutata', 'Chiamata vocale rifiutata'),
        ('Hai rifiutato una videochiamata', 'Hai rifiutato una chiamata vocale'), "{name} era impegnato in un'altra chiamata",
        'Chiamate', 'Ancora nessuna chiamata', 'Fotocamera in pausa', 'Mostra le chiamate nella schermata di blocco',
        'Consenti a BananaTalk di mostrare le chiamate in arrivo a schermo intero, così non le perdi quando il telefono è bloccato.',
        'Chiamata in corso', 'Tocca per tornare alla chiamata'],
 'pt': [('Videochamada efetuada', 'Chamada de voz efetuada'), ('Videochamada recebida', 'Chamada de voz recebida'),
        ('Videochamada · Sem resposta', 'Chamada de voz · Sem resposta'), ('Videochamada perdida', 'Chamada de voz perdida'),
        ('Videochamada cancelada', 'Chamada de voz cancelada'), ('Videochamada recusada', 'Chamada de voz recusada'),
        ('Você recusou uma videochamada', 'Você recusou uma chamada de voz'), '{name} estava em outra chamada', 'Chamadas',
        'Nenhuma chamada ainda', 'Câmera pausada', 'Mostrar chamadas na tela de bloqueio',
        'Permita que o BananaTalk mostre chamadas recebidas em tela cheia para você não perdê-las com o celular bloqueado.',
        'Chamada em andamento', 'Toque para voltar à chamada'],
 'ru': [('Исходящий видеозвонок', 'Исходящий голосовой звонок'), ('Входящий видеозвонок', 'Входящий голосовой звонок'),
        ('Видеозвонок · Нет ответа', 'Голосовой звонок · Нет ответа'), ('Пропущенный видеозвонок', 'Пропущенный голосовой звонок'),
        ('Отменённый видеозвонок', 'Отменённый голосовой звонок'), ('Видеозвонок отклонён', 'Голосовой звонок отклонён'),
        ('Отклонённый видеозвонок', 'Отклонённый голосовой звонок'), '{name} разговаривал(а) по другой линии', 'Звонки',
        'Звонков пока нет', 'Камера приостановлена', 'Показывать звонки на экране блокировки',
        'Разрешите BananaTalk показывать входящие звонки на весь экран, чтобы не пропускать их, когда телефон заблокирован.',
        'Идёт звонок', 'Нажмите, чтобы вернуться к звонку'],
 'ar': [('مكالمة فيديو صادرة', 'مكالمة صوتية صادرة'), ('مكالمة فيديو واردة', 'مكالمة صوتية واردة'),
        ('مكالمة فيديو · لا رد', 'مكالمة صوتية · لا رد'), ('مكالمة فيديو فائتة', 'مكالمة صوتية فائتة'),
        ('مكالمة فيديو ملغاة', 'مكالمة صوتية ملغاة'), ('تم رفض مكالمة الفيديو', 'تم رفض المكالمة الصوتية'),
        ('مكالمة فيديو مرفوضة', 'مكالمة صوتية مرفوضة'), 'كان {name} في مكالمة أخرى', 'المكالمات', 'لا توجد مكالمات بعد',
        'الكاميرا متوقفة مؤقتًا', 'عرض المكالمات على شاشة القفل',
        'اسمح لـ BananaTalk بعرض المكالمات الواردة بملء الشاشة حتى لا تفوتك عندما يكون هاتفك مقفلاً.',
        'مكالمة جارية', 'انقر للعودة إلى المكالمة'],
 'hi': [('आउटगोइंग वीडियो कॉल', 'आउटगोइंग वॉइस कॉल'), ('इनकमिंग वीडियो कॉल', 'इनकमिंग वॉइस कॉल'),
        ('वीडियो कॉल · कोई जवाब नहीं', 'वॉइस कॉल · कोई जवाब नहीं'), ('मिस्ड वीडियो कॉल', 'मिस्ड वॉइस कॉल'),
        ('रद्द की गई वीडियो कॉल', 'रद्द की गई वॉइस कॉल'), ('वीडियो कॉल अस्वीकार की गई', 'वॉइस कॉल अस्वीकार की गई'),
        ('अस्वीकार की गई वीडियो कॉल', 'अस्वीकार की गई वॉइस कॉल'), '{name} दूसरी कॉल पर थे', 'कॉल', 'अभी तक कोई कॉल नहीं',
        'कैमरा रुका हुआ है', 'लॉक स्क्रीन पर कॉल दिखाएँ',
        'BananaTalk को इनकमिंग कॉल फ़ुल स्क्रीन में दिखाने दें ताकि फ़ोन लॉक होने पर भी आप कॉल न चूकें।',
        'कॉल जारी है', 'कॉल पर लौटने के लिए टैप करें'],
 'id': [('Panggilan video keluar', 'Panggilan suara keluar'), ('Panggilan video masuk', 'Panggilan suara masuk'),
        ('Panggilan video · Tidak dijawab', 'Panggilan suara · Tidak dijawab'), ('Panggilan video tak terjawab', 'Panggilan suara tak terjawab'),
        ('Panggilan video dibatalkan', 'Panggilan suara dibatalkan'), ('Panggilan video ditolak', 'Panggilan suara ditolak'),
        ('Panggilan video yang ditolak', 'Panggilan suara yang ditolak'), '{name} sedang dalam panggilan lain', 'Panggilan',
        'Belum ada panggilan', 'Kamera dijeda', 'Tampilkan panggilan di layar kunci',
        'Izinkan BananaTalk menampilkan panggilan masuk dalam layar penuh agar Anda tidak melewatkannya saat ponsel terkunci.',
        'Panggilan berlangsung', 'Ketuk untuk kembali ke panggilan'],
 'th': [('วิดีโอคอลโทรออก', 'การโทรด้วยเสียงโทรออก'), ('วิดีโอคอลสายเข้า', 'การโทรด้วยเสียงสายเข้า'),
        ('วิดีโอคอล · ไม่มีผู้รับสาย', 'การโทรด้วยเสียง · ไม่มีผู้รับสาย'), ('วิดีโอคอลที่ไม่ได้รับ', 'สายที่ไม่ได้รับ'),
        ('วิดีโอคอลที่ยกเลิก', 'การโทรด้วยเสียงที่ยกเลิก'), ('วิดีโอคอลถูกปฏิเสธ', 'การโทรด้วยเสียงถูกปฏิเสธ'),
        ('วิดีโอคอลที่ปฏิเสธ', 'การโทรด้วยเสียงที่ปฏิเสธ'), '{name} กำลังอยู่ในสายอื่น', 'การโทร', 'ยังไม่มีการโทร',
        'หยุดกล้องชั่วคราว', 'แสดงสายเรียกเข้าบนหน้าจอล็อก',
        'อนุญาตให้ BananaTalk แสดงสายเรียกเข้าแบบเต็มหน้าจอ เพื่อไม่ให้พลาดสายเมื่อโทรศัพท์ล็อกอยู่',
        'กำลังโทร', 'แตะเพื่อกลับไปยังการโทร'],
 'tl': [('Papalabas na video call', 'Papalabas na voice call'), ('Papasok na video call', 'Papasok na voice call'),
        ('Video call · Walang sumagot', 'Voice call · Walang sumagot'), ('Hindi nasagot na video call', 'Hindi nasagot na voice call'),
        ('Kinanselang video call', 'Kinanselang voice call'), ('Tinanggihan ang video call', 'Tinanggihan ang voice call'),
        ('Tinanggihang video call', 'Tinanggihang voice call'), 'Nasa ibang tawag si {name}', 'Mga tawag', 'Wala pang tawag',
        'Naka-pause ang camera', 'Ipakita ang mga tawag sa lock screen',
        'Payagan ang BananaTalk na ipakita nang full screen ang mga papasok na tawag para hindi mo makaligtaan kahit naka-lock ang phone mo.',
        'May kasalukuyang tawag', 'I-tap para bumalik sa tawag'],
 'tr': [('Giden görüntülü arama', 'Giden sesli arama'), ('Gelen görüntülü arama', 'Gelen sesli arama'),
        ('Görüntülü arama · Yanıt yok', 'Sesli arama · Yanıt yok'), ('Cevapsız görüntülü arama', 'Cevapsız sesli arama'),
        ('İptal edilen görüntülü arama', 'İptal edilen sesli arama'), ('Görüntülü arama reddedildi', 'Sesli arama reddedildi'),
        ('Reddedilen görüntülü arama', 'Reddedilen sesli arama'), '{name} başka bir aramadaydı', 'Aramalar', 'Henüz arama yok',
        'Kamera duraklatıldı', 'Aramaları kilit ekranında göster',
        "Telefonunuz kilitliyken aramaları kaçırmamanız için BananaTalk'un gelen aramaları tam ekran göstermesine izin verin.",
        'Arama sürüyor', 'Aramaya dönmek için dokunun'],
 'vi': [('Cuộc gọi video đi', 'Cuộc gọi thoại đi'), ('Cuộc gọi video đến', 'Cuộc gọi thoại đến'),
        ('Cuộc gọi video · Không trả lời', 'Cuộc gọi thoại · Không trả lời'), ('Cuộc gọi video nhỡ', 'Cuộc gọi thoại nhỡ'),
        ('Cuộc gọi video đã hủy', 'Cuộc gọi thoại đã hủy'), ('Cuộc gọi video bị từ chối', 'Cuộc gọi thoại bị từ chối'),
        ('Đã từ chối cuộc gọi video', 'Đã từ chối cuộc gọi thoại'), '{name} đang có cuộc gọi khác', 'Cuộc gọi',
        'Chưa có cuộc gọi nào', 'Đã tạm dừng camera', 'Hiển thị cuộc gọi trên màn hình khóa',
        'Cho phép BananaTalk hiển thị cuộc gọi đến toàn màn hình để bạn không bỏ lỡ khi điện thoại đang khóa.',
        'Đang trong cuộc gọi', 'Nhấn để quay lại cuộc gọi'],
 'tg': [('Занги видеоии баромадӣ', 'Занги овозии баромадӣ'), ('Занги видеоии воридотӣ', 'Занги овозии воридотӣ'),
        ('Занги видеоӣ · Ҷавоб нест', 'Занги овозӣ · Ҷавоб нест'), ('Занги видеоии беҷавоб', 'Занги овозии беҷавоб'),
        ('Занги видеоии бекоршуда', 'Занги овозии бекоршуда'), ('Занги видеоӣ рад шуд', 'Занги овозӣ рад шуд'),
        ('Занги видеоии радшуда', 'Занги овозии радшуда'), '{name} дар занги дигар буд', 'Зангҳо', 'Ҳоло зангҳо нестанд',
        'Камера таваққуф шуд', 'Нишон додани зангҳо дар экрани қулф',
        'Ба BananaTalk иҷозат диҳед, ки зангҳои воридотиро дар тамоми экран нишон диҳад, то ҳангоми қулф будани телефон онҳоро аз даст надиҳед.',
        'Занг идома дорад', 'Барои бозгашт ба занг ламс кунед'],
}

for loc, values in T.items():
    assert len(values) == len(KEYS), loc
    path = pathlib.Path(f'lib/l10n/app_{loc}.arb')
    text = path.read_text(encoding='utf-8').rstrip()
    assert text.endswith('}'), path
    body = text[:-1].rstrip()
    lines = []
    for key, value in zip(KEYS, values):
        if key in SELECT:
            video, voice = value
            value = '{type, select, video{' + video + '} other{' + voice + '}}'
        lines.append(f'  {json.dumps(key)}: {json.dumps(value, ensure_ascii=False)}')
        if loc == 'en' and key in SELECT:
            lines.append(f'  "@{key}": {{"placeholders": {{"type": {{"type": "String"}}}}}}')
        if loc == 'en' and key == 'callLabelBusy':
            lines.append('  "@callLabelBusy": {"placeholders": {"name": {"type": "String"}}}')
    path.write_text(body + ',\n' + ',\n'.join(lines) + '\n}\n', encoding='utf-8')
print('arb files updated:', len(T))
PY
flutter gen-l10n
```

In `docs/REMAINING_WORK.md` §0b replace the line starting `- [ ] App: CallManager follower …` with:

```markdown
- [ ] App (plan `docs/superpowers/plans/2026-10-08-calls-reliability.md`):
  - [x] A1 call strings in 19 locales (18 machine drafts — native review open)
  - [ ] A2 outcome model + §3 labels
  - [ ] A3 call API / platform seams, CallKit id = callUuid
  - [ ] A4 CallManager follower + single exit path; 5-minute cap removed
  - [ ] A5 re-bind call listeners when the socket is replaced
  - [ ] A6 incoming dedupe, foreground FCM, call_cancelled, stale taps, resume/cold-start recovery
  - [ ] A7 CallKit extra, cold-start activeCalls(), VoIP/FCM capabilities + real device id
  - [ ] A8 AppDelegate VoIP cancel handling + `docs/qa/calls-matrix.md`
  - [ ] A9 IncomingCallScreen closes on terminal state / after 50 s
  - [ ] A10 20 s reconnect overlay + quality callback chain + outcome banner
  - [ ] A11 video wakelock + camera paused in background
  - [ ] A12 Android microphone/camera foreground service + full-screen-intent request
  - [ ] A13 CallLauncher, call bubble labels, chat-list preview
  - [ ] A14 Calls list + chat-tab icon + missed badge
  - [ ] Phase 2: decline with message, missed-call push actions, calls on/off + quiet hours, camera mid voice call, draggable self-view
- [ ] Native review of the 18 machine-drafted call strings (`lib/l10n/app_*.arb`)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/l10n/call_strings_test.dart`
Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n test/l10n/call_strings_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): call outcome, Calls list and call-service strings in 19 locales

15 keys: seven type-selected outcome labels (§3 of the calls spec), the busy
label, Calls list title/empty state, "Camera paused", the full-screen-intent
explainer and the ongoing-call notification. English source + 18 machine
drafts, regenerated.

Still open (calls app): A2-A14; native review of the call strings;
Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A2: `CallOutcome`, §3 labels, superset parsing

**Files:**
- Create: `lib/models/call_outcome.dart`
- Modify: `lib/models/call_record_model.dart` (whole file, 106 lines)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/models/call_outcome_test.dart`

**Interfaces:**
- Consumes: A1 getters.
- Produces: `enum CallOutcome { completed, noAnswer, cancelled, declined, busy }`; `CallOutcome? callOutcomeFromWire(String?)`; `CallOutcome? legacyCallOutcome(String? status)`; `String formatCallDuration(int seconds)`; `CallLabels.label(AppLocalizations l10n, {required CallOutcome outcome, required bool viewerIsCaller, required bool isVideo, int duration = 0, String otherName = ''})`; `CallLabels.isMissedForViewer(CallOutcome, {required bool viewerIsCaller})`; `String callPreviewText(AppLocalizations l10n, Map<String, dynamic> callData, {required String? viewerId, required String otherName})`; `CallRecord.outcome`, `CallRecord.callUuid`; `class CallLogEntry { id, callUuid, type, direction, outcome, duration, otherId, otherName, otherAvatar, createdAt; factory CallLogEntry.fromJson(Map) }`.

- [ ] **Step 1: Write the failing test**

Create `test/models/call_outcome_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/models/call_record_model.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  String label(CallOutcome o, {required bool caller, bool video = false, int duration = 0}) =>
      CallLabels.label(l10n,
          outcome: o, viewerIsCaller: caller, isVideo: video, duration: duration, otherName: 'Ada');

  test('§3 labels, caller and receiver side', () {
    expect(label(CallOutcome.completed, caller: true, duration: 83), 'Outgoing voice call · 1:23');
    expect(label(CallOutcome.completed, caller: false, video: true, duration: 5), 'Incoming video call · 0:05');
    expect(label(CallOutcome.noAnswer, caller: true), 'Voice call · No answer');
    expect(label(CallOutcome.noAnswer, caller: false), 'Missed voice call');
    expect(label(CallOutcome.cancelled, caller: true), 'Cancelled voice call');
    expect(label(CallOutcome.cancelled, caller: false, video: true), 'Missed video call');
    expect(label(CallOutcome.declined, caller: true), 'Voice call declined');
    expect(label(CallOutcome.declined, caller: false), 'Declined voice call');
    expect(label(CallOutcome.busy, caller: true), 'Ada was on another call');
    expect(label(CallOutcome.busy, caller: false), 'Missed voice call');
  });

  test('missed (badge, red) only on the receiver side of no_answer / cancelled / busy', () {
    for (final o in [CallOutcome.noAnswer, CallOutcome.cancelled, CallOutcome.busy]) {
      expect(CallLabels.isMissedForViewer(o, viewerIsCaller: false), isTrue);
      expect(CallLabels.isMissedForViewer(o, viewerIsCaller: true), isFalse);
    }
    expect(CallLabels.isMissedForViewer(CallOutcome.declined, viewerIsCaller: false), isFalse);
    expect(CallLabels.isMissedForViewer(CallOutcome.completed, viewerIsCaller: false), isFalse);
  });

  test('formatCallDuration', () {
    expect(formatCallDuration(0), '0:00');
    expect(formatCallDuration(61), '1:01');
    expect(formatCallDuration(3725), '1:02:05');
  });

  test('CallRecord reads the server superset; legacy rows fall back to status', () {
    final r = CallRecord.fromJson({
      '_id': 'c1', 'callId': 'c1', 'callUuid': 'u-1', 'initiator': 'me', 'participants': [],
      'type': 'video', 'startTime': '2026-10-08T12:00:00.000Z', 'duration': 61,
      'status': 'missed', 'outcome': 'busy',
    }, 'me');
    expect(r.outcome, CallOutcome.busy);
    expect(r.callUuid, 'u-1');
    expect(r.direction, CallDirection.outgoing);
    expect(r.duration, 61);
    final legacy = CallRecord.fromJson({'_id': 'c2', 'initiator': 'x', 'type': 'audio', 'status': 'missed'}, 'me');
    expect(legacy.outcome, CallOutcome.noAnswer);
    final fractional = CallRecord.fromJson({'_id': 'c3', 'initiator': 'x', 'duration': 12.7, 'status': 'ended'}, 'me');
    expect(fractional.duration, 12);
  });

  test('callPreviewText uses the viewer perspective', () {
    final data = {'initiator': 'me', 'type': 'audio', 'status': 'missed', 'outcome': 'no_answer', 'duration': 0};
    expect(callPreviewText(l10n, data, viewerId: 'me', otherName: 'Ada'), '📞 Voice call · No answer');
    expect(callPreviewText(l10n, data, viewerId: 'other', otherName: 'Ada'), '📞 Missed voice call');
  });

  test('CallLogEntry parses GET /calls items', () {
    final e = CallLogEntry.fromJson({
      'id': 'c1', 'callUuid': 'u', 'type': 'video', 'direction': 'in', 'outcome': 'cancelled', 'duration': 0,
      'otherParty': {'id': 'u2', 'name': 'Ada', 'avatar': 'https://cdn.test/a.jpg'},
      'createdAt': '2026-10-08T12:00:00.000Z',
    });
    expect(e.direction, CallDirection.incoming);
    expect(e.outcome, CallOutcome.cancelled);
    expect(e.type, CallType.video);
    expect(e.otherName, 'Ada');
    expect(e.otherAvatar, 'https://cdn.test/a.jpg');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/call_outcome_test.dart`
Expected: FAIL — `Error when reading 'lib/models/call_outcome.dart': No such file or directory`.

- [ ] **Step 3: Implement**

Create `lib/models/call_outcome.dart`:

```dart
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_record_model.dart';

/// How a call ended, as the server stores it (spec §3). One call message is
/// shared by both users; each side renders its own label from this and
/// whether the viewer was the caller.
enum CallOutcome { completed, noAnswer, cancelled, declined, busy }

CallOutcome? callOutcomeFromWire(String? value) {
  switch (value) {
    case 'completed':
      return CallOutcome.completed;
    case 'no_answer':
      return CallOutcome.noAnswer;
    case 'cancelled':
      return CallOutcome.cancelled;
    case 'declined':
      return CallOutcome.declined;
    case 'busy':
      return CallOutcome.busy;
  }
  return null;
}

/// Rows written before `outcome` existed only carry the legacy status.
CallOutcome? legacyCallOutcome(String? status) {
  switch (status) {
    case 'ended':
    case 'answered':
      return CallOutcome.completed;
    case 'missed':
      return CallOutcome.noAnswer;
    case 'rejected':
      return CallOutcome.declined;
    case 'busy':
      return CallOutcome.busy;
  }
  return null;
}

String formatCallDuration(int seconds) {
  final d = Duration(seconds: seconds < 0 ? 0 : seconds);
  final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
  final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d.inHours > 0) return '${d.inHours}:$mm:$ss';
  return '${d.inMinutes}:$ss';
}

class CallLabels {
  const CallLabels._();

  static String label(
    AppLocalizations l10n, {
    required CallOutcome outcome,
    required bool viewerIsCaller,
    required bool isVideo,
    int duration = 0,
    String otherName = '',
  }) {
    final type = isVideo ? 'video' : 'audio';
    switch (outcome) {
      case CallOutcome.completed:
        final base = viewerIsCaller
            ? l10n.callLabelOutgoing(type)
            : l10n.callLabelIncoming(type);
        return '$base · ${formatCallDuration(duration)}';
      case CallOutcome.noAnswer:
        return viewerIsCaller
            ? l10n.callLabelNoAnswer(type)
            : l10n.callLabelMissed(type);
      case CallOutcome.cancelled:
        return viewerIsCaller
            ? l10n.callLabelCancelled(type)
            : l10n.callLabelMissed(type);
      case CallOutcome.declined:
        return viewerIsCaller
            ? l10n.callLabelDeclinedOutgoing(type)
            : l10n.callLabelDeclinedIncoming(type);
      case CallOutcome.busy:
        return viewerIsCaller
            ? l10n.callLabelBusy(otherName)
            : l10n.callLabelMissed(type);
    }
  }

  /// "Missed" in the §3 sense: red in the UI and counted by the badge.
  static bool isMissedForViewer(CallOutcome outcome,
          {required bool viewerIsCaller}) =>
      !viewerIsCaller &&
      (outcome == CallOutcome.noAnswer ||
          outcome == CallOutcome.cancelled ||
          outcome == CallOutcome.busy);
}

/// Chat-list preview for a call message, from the viewer's perspective.
String callPreviewText(
  AppLocalizations l10n,
  Map<String, dynamic> callData, {
  required String? viewerId,
  required String otherName,
}) {
  final record = CallRecord.fromJson(callData, viewerId ?? '');
  final label = CallLabels.label(
    l10n,
    outcome: record.outcome ?? CallOutcome.completed,
    viewerIsCaller: viewerId != null && record.initiatorId == viewerId,
    isVideo: record.type == CallType.video,
    duration: record.duration ?? 0,
    otherName: otherName,
  );
  return '📞 $label';
}
```

Replace `lib/models/call_record_model.dart` with:

```dart
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/utils/string_sanitizer.dart';

enum CallRecordStatus { answered, missed, rejected }

class CallParticipant {
  final String id;
  final String name;
  final String? profilePicture;

  const CallParticipant({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: sanitize(json['name'], 'Unknown'),
      profilePicture:
          json['profilePicture']?.toString() ?? json['image']?.toString(),
    );
  }
}

/// A call as embedded in a chat message (`media.callData`). The server
/// writes a superset that live builds also read, so every field here
/// tolerates the old shape.
class CallRecord {
  final String id;
  final String? callUuid;
  final List<CallParticipant> participants;
  final CallType type;
  final CallRecordStatus status;
  final CallOutcome? outcome;
  final int? duration; // whole seconds
  final DateTime startTime;
  final DateTime? endTime;
  final String initiatorId;
  final CallDirection direction;

  const CallRecord({
    required this.id,
    this.callUuid,
    required this.participants,
    required this.type,
    required this.status,
    this.outcome,
    this.duration,
    required this.startTime,
    this.endTime,
    required this.initiatorId,
    required this.direction,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json, String currentUserId) {
    final initiatorId = json['initiator']?.toString() ?? '';
    final statusStr = json['status']?.toString() ?? '';
    final CallRecordStatus status;
    switch (statusStr) {
      case 'missed':
        status = CallRecordStatus.missed;
      case 'rejected':
        status = CallRecordStatus.rejected;
      default:
        status = CallRecordStatus.answered;
    }
    final rawParticipants = json['participants'];
    return CallRecord(
      id: json['callId']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      callUuid: json['callUuid']?.toString(),
      participants: rawParticipants is List
          ? rawParticipants
              .whereType<Map>()
              .map((p) => CallParticipant.fromJson(Map<String, dynamic>.from(p)))
              .toList()
          : const [],
      type: json['type'] == 'video' ? CallType.video : CallType.audio,
      status: status,
      outcome: callOutcomeFromWire(json['outcome']?.toString()) ??
          legacyCallOutcome(statusStr),
      duration: (json['duration'] as num?)?.floor(),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ??
          DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      initiatorId: initiatorId,
      direction: initiatorId == currentUserId
          ? CallDirection.outgoing
          : CallDirection.incoming,
    );
  }

  CallParticipant? getOtherParticipant(String currentUserId) {
    if (participants.isEmpty) return null;
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  String get formattedDuration =>
      duration == null ? '' : formatCallDuration(duration!);
}

/// One row of `GET /calls` (spec §4.7). Labels are derived client-side.
class CallLogEntry {
  final String id;
  final String? callUuid;
  final CallType type;
  final CallDirection direction;
  final CallOutcome outcome;
  final int duration;
  final String otherId;
  final String otherName;
  final String? otherAvatar;
  final DateTime createdAt;

  const CallLogEntry({
    required this.id,
    this.callUuid,
    required this.type,
    required this.direction,
    required this.outcome,
    required this.duration,
    required this.otherId,
    required this.otherName,
    this.otherAvatar,
    required this.createdAt,
  });

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    final other = json['otherParty'] is Map
        ? Map<String, dynamic>.from(json['otherParty'] as Map)
        : const <String, dynamic>{};
    return CallLogEntry(
      id: json['id']?.toString() ?? '',
      callUuid: json['callUuid']?.toString(),
      type: json['type'] == 'video' ? CallType.video : CallType.audio,
      direction: json['direction'] == 'out'
          ? CallDirection.outgoing
          : CallDirection.incoming,
      outcome: callOutcomeFromWire(json['outcome']?.toString()) ??
          CallOutcome.completed,
      duration: (json['duration'] as num?)?.floor() ?? 0,
      otherId: other['id']?.toString() ?? '',
      otherName: sanitize(other['name'], 'Unknown'),
      otherAvatar: other['avatar']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
```

In `docs/REMAINING_WORK.md` tick `  - [x] A2 outcome model + §3 labels`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/models/call_outcome_test.dart && flutter analyze lib/models`
Expected: 6 tests pass; no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/models/call_outcome.dart lib/models/call_record_model.dart test/models/call_outcome_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): call outcomes and §3 labels for both sides of a call

CallOutcome + CallLabels give each viewer their own label from one shared
call message (Outgoing/Incoming · m:ss, No answer / Missed, Cancelled,
Declined, "<name> was on another call"); isMissedForViewer drives red and
the badge. CallRecord reads the server's callData superset (outcome,
callUuid, fractional durations), CallLogEntry parses GET /calls.

Still open (calls app): A3-A14; native review of call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A3: Call API and platform seams; CallKit id = `callUuid`

**Files:**
- Create: `lib/services/call/call_api.dart`
- Create: `lib/services/call/call_platform.dart`
- Create: `lib/services/call/callkit_ids.dart`
- Create: `lib/services/call/call_routes.dart`
- Modify: `lib/models/call_model.dart` (fields 17-60, `fromJson` 62-99, `copyWith` 116-152)
- Modify: `lib/services/callkit_service.dart:182-251` (`showIncomingCall`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/services/call_api_test.dart`

**Interfaces:**
- Consumes: `ApiClient.get/post`, `ApiResponse.errorCode`; `CallKitService`; `NotificationService.getDeviceId/cancelCallNotification`.
- Produces:
  - `class CallApiResult { ok, statusCode, errorCode, error, Map<String, dynamic> data; isCallStateConflict, isCalleeBusy, isCallerBusy; factory fromResponse(ApiResponse) }`.
  - `abstract class CallApi { initiate({required String receiverId, required CallType type}); accept(String callId, {String? deviceId}); decline(String callId, {String? deviceId}); end(String callId); current(); get(String callId); }` all `Future<CallApiResult>`; `class RestCallApi implements CallApi`.
  - `abstract class CallPlatform { showIncomingCallUi(CallModel); endCallUi(CallModel); activeCallUis() → Future<List<CallKitEntry>>; startRingtone(); startRingback(); stopTones(); playConnectSound(); playEndSound(); cancelIncomingNotification(); deviceId() → Future<String>; ensurePermissions({required bool video}) → Future<bool>; permissionError({required bool video, required bool accepting}) → Future<String> }`; `class DeviceCallPlatform implements CallPlatform`.
  - `CallKitIds.same(String?, String?)` (case-insensitive), `CallKitIds.uuidFor({required String callId, String? callUuid})`; `class CallKitEntry { uuid, accepted, extra; String? get callId; factory fromPlugin(Map) }`.
  - `CallRoutes.incoming/active` names, `isCallRoute`, `incomingRoute(call)`, `activeRoute(call)`, `openIncoming(call)`, `openActive(call)`, `closeAll()`.
  - `CallModel.callUuid`; `CallModel.fromJson` reads `callUuid` and `callerAvatar`.
  - `CallKitService.showIncomingCall({required String callId, String? callUuid, required String callerName, String? callerAvatar, String? callerId, bool isVideo, String? livekitUrl, String? roomName})` — CallKit id = `CallKitIds.uuidFor(...)`.

- [ ] **Step 1: Write the failing test**

Create `test/services/call_api_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String originalBaseUrl;

  setUp(() {
    originalBaseUrl = Endpoints.baseURL;
    Endpoints.baseURL = 'http://api.test/api/v1/';
    SharedPreferences.setMockInitialValues({'token': 'jwt'});
    ApiClient().clearTokenCache();
  });
  tearDown(() => Endpoints.baseURL = originalBaseUrl);

  test('accept: sends deviceId, maps 409 CALL_STATE to isCallStateConflict', () async {
    final seen = <http.Request>[];
    final result = await http.runWithClient(
      () => RestCallApi().accept('c1', deviceId: 'dev-1'),
      () => MockClient((req) async {
        seen.add(req);
        return http.Response(
          jsonEncode({'success': false, 'error': 'Call already active', 'code': 'CALL_STATE', 'status': 'active'}),
          409,
        );
      }),
    );
    expect(seen.single.url.toString(), 'http://api.test/api/v1/calls/c1/accept');
    expect(jsonDecode(seen.single.body), {'deviceId': 'dev-1'});
    expect(result.ok, isFalse);
    expect(result.isCallStateConflict, isTrue);
  });

  test('initiate: 409 CALLEE_BUSY and 200 data map', () async {
    final busy = await http.runWithClient(
      () => RestCallApi().initiate(receiverId: 'u2', type: CallType.video),
      () => MockClient((req) async => http.Response(
          jsonEncode({'success': false, 'error': 'busy', 'code': 'CALLEE_BUSY'}), 409)),
    );
    expect(busy.isCalleeBusy, isTrue);

    final ok = await http.runWithClient(
      () => RestCallApi().initiate(receiverId: 'u2', type: CallType.audio),
      () => MockClient((req) async {
        expect(jsonDecode(req.body), {'receiverId': 'u2', 'type': 'audio'});
        return http.Response(jsonEncode({
          'success': true,
          'data': {'call': {'_id': 'c9', 'callUuid': 'u-9'}, 'token': 't', 'url': 'wss://x', 'roomName': 'call:c9'},
        }), 200);
      }),
    );
    expect(ok.ok, isTrue);
    expect((ok.data['call'] as Map)['callUuid'], 'u-9');
  });

  test('Review focus 1: CallKit ids compare case-insensitively; uuidFor prefers callUuid', () {
    expect(CallKitIds.same('6F1C2B8E-3C1D-4A8E-9B7F-0A1B2C3D4E5F', '6f1c2b8e-3c1d-4a8e-9b7f-0a1b2c3d4e5f'), isTrue);
    expect(CallKitIds.same(null, 'x'), isFalse);
    expect(CallKitIds.same('', ''), isFalse);
    expect(CallKitIds.uuidFor(callId: 'abc', callUuid: 'AB-CD'), 'ab-cd');
    final derived = CallKitIds.uuidFor(callId: '0123456789abcdef01234567');
    expect(derived, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(CallKitIds.uuidFor(callId: '0123456789abcdef01234567'), derived, reason: 'deterministic');
  });

  test('CallKitEntry reads both plugin shapes (iOS "accepted", Android "isAccepted")', () {
    final ios = CallKitEntry.fromPlugin({'id': 'U-1', 'accepted': true, 'extra': {'callId': 'c1'}});
    expect(ios.accepted, isTrue);
    expect(ios.callId, 'c1');
    final android = CallKitEntry.fromPlugin({'id': 'u-2', 'isAccepted': false});
    expect(android.accepted, isFalse);
    expect(android.callId, isNull);
  });

  test('CallModel reads callUuid and the FCM callerAvatar alias', () {
    final m = CallModel.fromJson({
      'callId': 'c1', 'callUuid': 'u-1', 'callerId': 'u2', 'callerName': 'Ada',
      'callerAvatar': 'https://cdn.test/a.jpg', 'callType': 'video',
    }, CallDirection.incoming);
    expect(m.callUuid, 'u-1');
    expect(m.userProfilePicture, 'https://cdn.test/a.jpg');
    expect(m.copyWith(status: CallStatus.connecting).callUuid, 'u-1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/call_api_test.dart`
Expected: FAIL — `Error when reading 'lib/services/call/call_api.dart': No such file or directory`.

- [ ] **Step 3: Implement**

Create `lib/services/call/call_api.dart`:

```dart
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// Result of a call REST request, with the server's machine-readable codes.
class CallApiResult {
  const CallApiResult({
    required this.ok,
    required this.statusCode,
    this.errorCode,
    this.error,
    this.data = const {},
  });

  factory CallApiResult.fromResponse(ApiResponse r) => CallApiResult(
        ok: r.success,
        statusCode: r.statusCode,
        errorCode: r.errorCode,
        error: r.error,
        data: r.data is Map
            ? Map<String, dynamic>.from(r.data as Map)
            : const <String, dynamic>{},
      );

  final bool ok;
  final int statusCode;
  final String? errorCode;
  final String? error;
  final Map<String, dynamic> data;

  /// Another device (or the timeout) won the race: dismiss silently.
  bool get isCallStateConflict => statusCode == 409 && errorCode == 'CALL_STATE';
  bool get isCalleeBusy => statusCode == 409 && errorCode == 'CALLEE_BUSY';
  bool get isCallerBusy => statusCode == 409 && errorCode == 'CALLER_BUSY';
}

abstract class CallApi {
  Future<CallApiResult> initiate({required String receiverId, required CallType type});
  Future<CallApiResult> accept(String callId, {String? deviceId});
  Future<CallApiResult> decline(String callId, {String? deviceId});
  Future<CallApiResult> end(String callId);
  Future<CallApiResult> current();
  Future<CallApiResult> get(String callId);
}

class RestCallApi implements CallApi {
  RestCallApi([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  Map<String, dynamic> _device(String? deviceId) =>
      {if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId};

  @override
  Future<CallApiResult> initiate({required String receiverId, required CallType type}) async =>
      CallApiResult.fromResponse(await _client.post('calls/initiate',
          body: {'receiverId': receiverId, 'type': type.name}));

  @override
  Future<CallApiResult> accept(String callId, {String? deviceId}) async =>
      CallApiResult.fromResponse(
          await _client.post('calls/$callId/accept', body: _device(deviceId)));

  @override
  Future<CallApiResult> decline(String callId, {String? deviceId}) async =>
      CallApiResult.fromResponse(
          await _client.post('calls/$callId/decline', body: _device(deviceId)));

  @override
  Future<CallApiResult> end(String callId) async =>
      CallApiResult.fromResponse(await _client.post('calls/$callId/end'));

  @override
  Future<CallApiResult> current() async =>
      CallApiResult.fromResponse(await _client.get('calls/current'));

  @override
  Future<CallApiResult> get(String callId) async =>
      CallApiResult.fromResponse(await _client.get('calls/$callId'));
}
```

Create `lib/services/call/callkit_ids.dart`:

```dart
import 'package:uuid/uuid.dart';

/// CallKit identifiers. The plugin force-unwraps `UUID(uuidString:)` on iOS,
/// so a CallKit id must always be a UUID; iOS reports them back uppercase.
class CallKitIds {
  const CallKitIds._();

  static bool same(String? a, String? b) =>
      a != null && b != null && a.isNotEmpty && a.toLowerCase() == b.toLowerCase();

  /// The server's callUuid; for a payload from an old backend that has none,
  /// a deterministic v5 UUID of the Mongo id (never the 24-hex id itself).
  static String uuidFor({required String callId, String? callUuid}) =>
      (callUuid != null && callUuid.isNotEmpty)
          ? callUuid.toLowerCase()
          : const Uuid().v5(Namespace.url.value, 'bananatalk:call:$callId');
}

/// One call the native CallKit / Android call UI currently shows.
class CallKitEntry {
  const CallKitEntry({required this.uuid, required this.accepted, this.extra = const {}});

  factory CallKitEntry.fromPlugin(Map raw) {
    final extra = raw['extra'] is Map
        ? Map<String, dynamic>.from(raw['extra'] as Map)
        : const <String, dynamic>{};
    return CallKitEntry(
      uuid: (raw['id'] ?? '').toString(),
      accepted: raw['accepted'] == true || raw['isAccepted'] == true,
      extra: extra,
    );
  }

  final String uuid;
  final bool accepted;
  final Map<String, dynamic> extra;

  String? get callId {
    final id = extra['callId']?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }
}
```

Create `lib/services/call/call_platform.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Everything a call needs from the device, behind one seam so
/// CallManager can be tested without plugins.
abstract class CallPlatform {
  Future<void> showIncomingCallUi(CallModel call);
  Future<void> endCallUi(CallModel call);
  Future<List<CallKitEntry>> activeCallUis();
  Future<void> startRingtone();
  Future<void> startRingback();
  Future<void> stopTones();
  Future<void> playConnectSound();
  Future<void> playEndSound();
  Future<void> cancelIncomingNotification();
  Future<String> deviceId();
  Future<bool> ensurePermissions({required bool video});
  Future<String> permissionError({required bool video, required bool accepting});
}

class DeviceCallPlatform implements CallPlatform {
  AudioPlayer? _tone;
  AudioPlayer? _sound;

  Future<void> _loop(String asset) async {
    try {
      await _tone?.dispose();
      final player = AudioPlayer();
      _tone = player;
      await player.setAsset(asset);
      await player.setLoopMode(LoopMode.one);
      await player.play();
    } catch (e) {
      debugPrint('🔔 tone $asset failed: $e');
    }
  }

  Future<void> _once(String asset) async {
    try {
      await _sound?.dispose();
      final player = AudioPlayer();
      _sound = player;
      await player.setAsset(asset);
      await player.play();
    } catch (e) {
      debugPrint('🔔 sound $asset failed: $e');
    }
  }

  @override
  Future<void> startRingtone() => _loop('assets/sounds/ringtone.m4a');

  @override
  Future<void> startRingback() => _loop('assets/sounds/ringback.m4a');

  @override
  Future<void> stopTones() async {
    final player = _tone;
    _tone = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (e) {
      debugPrint('🔔 stop tones failed: $e');
    }
  }

  @override
  Future<void> playConnectSound() => _once('assets/sounds/call_connect.m4a');

  @override
  Future<void> playEndSound() => _once('assets/sounds/call_end.m4a');

  @override
  Future<void> showIncomingCallUi(CallModel call) async {
    await CallKitService().showIncomingCall(
      callId: call.callId,
      callUuid: call.callUuid,
      callerName: call.userName,
      callerAvatar: call.userProfilePicture,
      callerId: call.userId,
      isVideo: call.callType == CallType.video,
      livekitUrl: call.livekitUrl,
      roomName: call.roomName,
    );
  }

  @override
  Future<void> endCallUi(CallModel call) =>
      CallKitService().endCall(CallKitIds.uuidFor(callId: call.callId, callUuid: call.callUuid));

  @override
  Future<List<CallKitEntry>> activeCallUis() async {
    final raw = await CallKitService().getActiveCalls();
    return raw.whereType<Map>().map(CallKitEntry.fromPlugin).toList();
  }

  @override
  Future<void> cancelIncomingNotification() => NotificationService().cancelCallNotification();

  @override
  Future<String> deviceId() => NotificationService().getDeviceId();

  @override
  Future<bool> ensurePermissions({required bool video}) async {
    final mic = await Permission.microphone.status;
    final cam = video ? await Permission.camera.status : PermissionStatus.granted;
    if (mic.isGranted && cam.isGranted) return true;
    if (mic.isPermanentlyDenied || (video && cam.isPermanentlyDenied)) return false;
    final statuses = await [Permission.microphone, if (video) Permission.camera].request();
    return statuses.values.every((s) => s.isGranted);
  }

  @override
  Future<String> permissionError({required bool video, required bool accepting}) async {
    final mic = await Permission.microphone.status;
    final cam = video ? await Permission.camera.status : PermissionStatus.granted;
    final verb = accepting ? 'answer' : 'make';
    final scope = video ? 'video calls' : 'calls';
    if (video) {
      if (mic.isPermanentlyDenied && cam.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable microphone and camera access in Settings to $verb $scope.';
      }
      if (mic.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable microphone access in Settings to $verb calls.';
      }
      if (cam.isPermanentlyDenied) {
        return 'PERMANENTLY_DENIED:Please enable camera access in Settings to $verb video calls.';
      }
      if (!mic.isGranted) return 'DENIED:Microphone permission is required to $verb calls.';
      return 'DENIED:Camera permission is required to $verb video calls.';
    }
    if (mic.isPermanentlyDenied) {
      return 'PERMANENTLY_DENIED:Please enable microphone access in Settings to $verb calls.';
    }
    return 'DENIED:Microphone permission is required to $verb calls.';
  }
}
```

Create `lib/services/call/call_routes.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';

/// Call screens live on the overlay navigator under fixed route names, so
/// CallManager can close exactly them — and nothing else — from anywhere.
class CallRoutes {
  const CallRoutes._();

  static const incoming = 'call/incoming';
  static const active = 'call/active';

  static bool isCallRoute(String? name) => name == incoming || name == active;

  static Route<void> incomingRoute(CallModel call) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: incoming),
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(call: call),
      );

  static Route<void> activeRoute(CallModel call) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: active),
        fullscreenDialog: true,
        builder: (_) => ActiveCallScreen(call: call),
      );

  static void openIncoming(CallModel call) =>
      callOverlayNavigatorKey.currentState?.push(incomingRoute(call));

  static void openActive(CallModel call) =>
      callOverlayNavigatorKey.currentState?.push(activeRoute(call));

  static void closeAll() => callOverlayNavigatorKey.currentState
      ?.popUntil((route) => !isCallRoute(route.settings.name));
}
```

In `lib/models/call_model.dart`:
- add the field after `roomName` (line 41): `/// CallKit-safe UUID from the server; CallKit / Android call UI are keyed by it.\n  final String? callUuid;`
- add `this.callUuid,` to the constructor;
- in `fromJson` incoming branch change the picture lookup to
  `userProfilePicture = caller?['profilePicture']?.toString() ?? caller?['image']?.toString() ?? json['callerProfilePicture']?.toString() ?? json['callerAvatar']?.toString();`
  and add `callUuid: json['callUuid']?.toString(),` to the returned `CallModel(...)`;
- in `copyWith` add the parameter `String? callUuid,` and `callUuid: callUuid ?? this.callUuid,`.

In `lib/services/callkit_service.dart` replace the signature and first lines of `showIncomingCall` (182-198):

```dart
  Future<String> showIncomingCall({
    required String callId,
    String? callUuid,
    required String callerName,
    String? callerAvatar,
    String? callerId,
    bool isVideo = false,
    String? livekitToken,
    String? livekitUrl,
    String? roomName,
  }) async {
    // CallKit ids MUST be UUIDs (the plugin force-unwraps UUID(uuidString:)
    // on iOS); the 24-hex Mongo id crashed backgrounded iPhones.
    final uuid = CallKitIds.uuidFor(callId: callId, callUuid: callUuid);
    _activeCallUuid = uuid;

    final extra = <String, dynamic>{'callId': callId, 'callUuid': uuid};
    if (callerId != null) extra['callerId'] = callerId;
    if (livekitToken != null) extra['livekitToken'] = livekitToken;
    if (livekitUrl != null) extra['livekitUrl'] = livekitUrl;
    if (roomName != null) extra['roomName'] = roomName;
```

and add `import 'package:bananatalk_app/services/call/callkit_ids.dart';`. (`livekitToken` stays only until Task A7 removes it with the background handler.)

In `docs/REMAINING_WORK.md` tick `  - [x] A3 call API / platform seams, CallKit id = callUuid`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/call_api_test.dart && flutter analyze lib/services/call lib/models lib/services/callkit_service.dart`
Expected: 5 tests pass; no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/call/call_api.dart lib/services/call/call_platform.dart lib/services/call/callkit_ids.dart lib/services/call/call_routes.dart lib/models/call_model.dart lib/services/callkit_service.dart test/services/call_api_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): call API / platform seams; CallKit is keyed by callUuid

CallApi (REST, with CALL_STATE / CALLEE_BUSY / CALLER_BUSY decoding) and
CallPlatform (CallKit, tones, permissions, device id) are the two seams
CallManager will be tested through. CallKit ids are now always UUIDs
(server callUuid, or a deterministic v5 of the Mongo id) - the 24-hex id
crashed flutter_callkit_incoming on backgrounded iPhones - and are compared
case-insensitively because iOS reports them uppercase. Call screens get
named routes so they can be closed precisely.

Still open (calls app): A4-A14; native review of call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---
### Task A4: `CallManager` as a state follower with one exit path; 5-minute cap removed

**Files:**
- Rewrite: `lib/services/call_manager.dart` (1052 lines → new file below)
- Modify: `lib/services/callkit_service.dart:44-46, 82-108` (callbacks carry `extra`)
- Modify: `lib/providers/call_provider.dart` (whole file)
- Modify: `lib/main.dart:19, 264-292`
- Modify: `lib/services/notification_router.dart:7-8, 82-86, 434-504`
- Rewrite: `lib/screens/incoming_call_screen.dart`
- Modify: `lib/screens/active_call_screen.dart` (85-99, 162-176, 563-591 and field `_durationWarningRemaining`)
- Modify: `lib/pages/chat/header/chat_app_bar.dart:8-10, 19, 424-426, 444-454`
- Modify: `lib/screens/call_history_screen.dart:9-11, 195-234`
- Modify: `lib/services/session_activities.dart:30-31`
- Modify: `pubspec.yaml` (dev_dependencies)
- Modify: `docs/REMAINING_WORK.md`
- Create: `test/helpers/call_fakes.dart`
- Test: `test/services/call_manager_test.dart`

**Interfaces:**
- Consumes: `CallApi`, `CallApiResult`, `CallPlatform`, `CallKitEntry`, `CallRoutes` (A3); `CallOutcome`, `callOutcomeFromWire` (A2); `CallLiveKitManager`.
- Produces:
  - Enums `CallUiState`, `CallQuality` (unchanged values), `CallExitReason { localHangUp, declined, remoteState, answeredElsewhere, acceptConflict, connectionLost, error }`, `IncomingSource { socket, push, notificationTap, recovery, callKit }`, `InitiateStatus { started, calleeBusy, callerBusy, permissionDenied, failed }`.
  - `class InitiateResult { InitiateStatus status; String? error }`; `class CallFinish { CallModel call; CallExitReason reason; CallOutcome? outcome }`.
  - `class CallManagerDeps { CallApi api; CallPlatform platform; CallLiveKitManager Function() liveKitFactory; void Function() closeCallScreens; void Function(CallModel) openActiveCall; void Function(CallModel) openIncomingCall; factory CallManagerDeps.production() }`.
  - `CallManager`: `factory CallManager()`, `CallManager.forTest(CallManagerDeps)`, `static debugSetInstance(CallManager)`, `currentCall`, `Stream<CallFinish> finishes`, `onCallFinished`, `initialize(ChatSocketService)`, `bindSocket(io.Socket?)`, `handleSocketEvent(String event, dynamic data)`, `handleIncoming(Map<String, dynamic>, {IncomingSource source})`, `Future<InitiateResult> initiateCall(...)`, `Future<void> acceptCall()`, `Future<void> rejectCall()`, `Future<void> endCall()`, `handleCallKitAccept/Decline/Ended(String id, Map<String, dynamic>? extra)`, media controls as before. Removed: `setVipCall`, `onCallTimeout`, `onCallDurationWarning`, `onCallDurationLimitReached`, the 5-minute timers, the client 45 s timeout, legacy per-outcome socket listeners.
  - Constants `kOutcomeBannerDuration = 1500 ms`, `kRingSafetyTimeout = 50 s`.
  - `CallKitService.onAccepted/onDeclined/onEnded: Function(String id, Map<String, dynamic>? extra)?`.
  - `CallNotifier.initiateCall(...) → Future<InitiateResult>`; removed `setVipCall`, `setCallDurationWarningCallback`, `setCallDurationLimitCallback`.

- [ ] **Step 1: Write the failing test**

Add to `pubspec.yaml` under `dev_dependencies:` (after `flutter_test`):

```yaml
  # fakeAsync for timer-driven call tests (pinned by the Flutter SDK).
  fake_async: any
```

Run `flutter pub get`.

Create `test/helpers/call_fakes.dart`:

```dart
import 'dart:async';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_platform.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/call_livekit_manager.dart';
import 'package:bananatalk_app/services/call_manager.dart';

const kCallUuid = '6f1c2b8e-3c1d-4a8e-9b7f-0a1b2c3d4e5f';

class FakeCallApi implements CallApi {
  final List<String> calls = [];
  final Map<String, String?> deviceIds = {};
  Completer<void>? initiateGate;

  CallApiResult initiateResult = const CallApiResult(ok: true, statusCode: 200, data: {
    'call': {'_id': 'call-1', 'callUuid': kCallUuid, 'type': 'audio'},
    'token': 'tok-caller',
    'url': 'wss://lk.test',
    'roomName': 'call:call-1',
  });
  CallApiResult acceptResult = const CallApiResult(ok: true, statusCode: 200, data: {
    'token': 'tok-receiver',
    'url': 'wss://lk.test',
    'roomName': 'call:call-1',
  });
  CallApiResult declineResult = const CallApiResult(ok: true, statusCode: 200);
  CallApiResult endResult = const CallApiResult(ok: true, statusCode: 200);
  CallApiResult currentResult =
      const CallApiResult(ok: true, statusCode: 200, data: {'call': null});
  CallApiResult getResult =
      const CallApiResult(ok: true, statusCode: 200, data: {'status': 'ringing'});

  @override
  Future<CallApiResult> initiate({required String receiverId, required CallType type}) async {
    calls.add('initiate:$receiverId:${type.name}');
    if (initiateGate != null) await initiateGate!.future;
    return initiateResult;
  }

  @override
  Future<CallApiResult> accept(String callId, {String? deviceId}) async {
    calls.add('accept:$callId');
    deviceIds['accept'] = deviceId;
    return acceptResult;
  }

  @override
  Future<CallApiResult> decline(String callId, {String? deviceId}) async {
    calls.add('decline:$callId');
    deviceIds['decline'] = deviceId;
    return declineResult;
  }

  @override
  Future<CallApiResult> end(String callId) async {
    calls.add('end:$callId');
    return endResult;
  }

  @override
  Future<CallApiResult> current() async {
    calls.add('current');
    return currentResult;
  }

  @override
  Future<CallApiResult> get(String callId) async {
    calls.add('get:$callId');
    return getResult;
  }
}

class FakeCallPlatform implements CallPlatform {
  final List<String> log = [];
  List<CallKitEntry> activeEntries = const [];
  bool permissionsGranted = true;

  @override
  Future<void> showIncomingCallUi(CallModel call) async => log.add('showUi:${call.callId}');
  @override
  Future<void> endCallUi(CallModel call) async => log.add('endUi:${call.callUuid ?? call.callId}');
  @override
  Future<List<CallKitEntry>> activeCallUis() async => activeEntries;
  @override
  Future<void> startRingtone() async => log.add('ringtone');
  @override
  Future<void> startRingback() async => log.add('ringback');
  @override
  Future<void> stopTones() async => log.add('stopTones');
  @override
  Future<void> playConnectSound() async => log.add('connectSound');
  @override
  Future<void> playEndSound() async => log.add('endSound');
  @override
  Future<void> cancelIncomingNotification() async => log.add('cancelNotification');
  @override
  Future<String> deviceId() async => 'device-1';
  @override
  Future<bool> ensurePermissions({required bool video}) async => permissionsGranted;
  @override
  Future<String> permissionError({required bool video, required bool accepting}) async =>
      'DENIED:test';
}

class FakeLiveKit extends CallLiveKitManager {
  int connects = 0;
  int disconnects = 0;
  Object? connectError;
  final List<bool> cameraCalls = [];

  @override
  Future<void> connect({required String url, required String token, required CallType type}) async {
    connects++;
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> disconnect() async => disconnects++;

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  Future<void> setCameraEnabled(bool enabled) async => cameraCalls.add(enabled);
}

/// A CallManager wired to fakes, recording everything it does.
class CallHarness {
  CallHarness({
    void Function()? closeCallScreens,
    void Function(CallModel call)? openIncoming,
    void Function(CallModel call)? openActive,
  }) {
    manager = CallManager.forTest(CallManagerDeps(
      api: api,
      platform: platform,
      liveKitFactory: () {
        final lk = FakeLiveKit()..connectError = nextConnectError;
        nextConnectError = null;
        liveKits.add(lk);
        return lk;
      },
      closeCallScreens: () {
        closes++;
        closeCallScreens?.call();
      },
      openActiveCall: (c) {
        opened.add('active:${c.callId}');
        openActive?.call(c);
      },
      openIncomingCall: (c) {
        opened.add('incoming:${c.callId}');
        openIncoming?.call(c);
      },
    ));
    manager.onCallFinished = finishes.add;
  }

  final FakeCallApi api = FakeCallApi();
  final FakeCallPlatform platform = FakeCallPlatform();
  final List<FakeLiveKit> liveKits = [];
  final List<CallFinish> finishes = [];
  final List<String> opened = [];
  int closes = 0;
  Object? nextConnectError;
  late final CallManager manager;

  FakeLiveKit get liveKit => liveKits.last;

  static Map<String, dynamic> incomingPayload({String callId = 'call-1', String callType = 'audio'}) => {
        'callId': callId,
        'callUuid': kCallUuid,
        'caller': {'_id': 'u-caller', 'name': 'Ada', 'profilePicture': null},
        'callType': callType,
        'roomName': 'call:$callId',
      };

  Future<InitiateResult> startOutgoing({CallType type = CallType.audio}) =>
      manager.initiateCall('u-callee', 'Bo', null, type);

  Future<void> ringIncoming({String callType = 'audio'}) =>
      manager.handleIncoming(incomingPayload(callType: callType));

  Future<void> state(String status, {String callId = 'call-1', String? outcome, int duration = 0}) =>
      manager.handleSocketEvent('call:state', {
        'callId': callId,
        'callUuid': kCallUuid,
        'status': status,
        'outcome': outcome,
        'duration': duration,
      });
}
```

Create `test/services/call_manager_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a call:state for another callId is ignored', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.state('ended', callId: 'another-call', outcome: 'completed');
    expect(h.manager.currentCall?.callId, 'call-1');
    expect(h.finishes, isEmpty);
  });

  test('outgoing: accepted then ended via call:state → one clean finish', () async {
    final h = CallHarness();
    final r = await h.startOutgoing();
    expect(r.status, InitiateStatus.started);
    expect(h.manager.currentCall!.callUuid, kCallUuid);
    expect(h.platform.log, contains('ringback'));
    await h.state('active');
    expect(h.manager.currentCall!.status, CallStatus.connecting);
    final media = h.liveKit;
    await h.state('ended', outcome: 'completed', duration: 42);
    expect(h.finishes.single.reason, CallExitReason.remoteState);
    expect(h.finishes.single.call.duration, 42);
    expect(h.manager.currentCall, isNull);
    expect(media.disconnects, 1);
    expect(h.platform.log, contains('endUi:$kCallUuid'));
    expect(h.closes, 1);
  });

  group('every exit path runs _finish exactly once, even when another exit follows', () {
    final scenarios = <String, Future<void> Function(CallHarness h)>{
      'local hang-up': (h) async {
        await h.startOutgoing();
        await h.manager.endCall();
      },
      'decline': (h) async {
        await h.ringIncoming();
        await h.manager.rejectCall();
      },
      'remote no answer': (h) async {
        await h.startOutgoing();
        await h.state('missed', outcome: 'no_answer');
      },
      'remote declined': (h) async {
        await h.startOutgoing();
        await h.state('rejected', outcome: 'declined');
      },
      'room deleted': (h) async {
        await h.startOutgoing();
        h.liveKit.onLocalDisconnected!(lk.DisconnectReason.roomDeleted);
        await pumpEventQueue();
      },
      'LiveKit connect failure': (h) async {
        h.nextConnectError = StateError('no network');
        await h.startOutgoing();
      },
      '409 on accept': (h) async {
        h.api.acceptResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
        await h.ringIncoming();
        await h.manager.acceptCall();
      },
    };
    scenarios.forEach((name, run) {
      test(name, () async {
        final h = CallHarness();
        await run(h);
        await h.state('ended', outcome: 'completed');
        await h.manager.endCall();
        await pumpEventQueue();
        expect(h.finishes, hasLength(1));
        expect(h.manager.currentCall, isNull);
        expect(h.closes, greaterThanOrEqualTo(1));
      });
    });
  });

  test('End with no current call still closes the call screens', () async {
    final h = CallHarness();
    await h.manager.endCall();
    expect(h.closes, 1);
    expect(h.finishes, isEmpty);
  });

  test('409 CALL_STATE on accept dismisses silently and reports the device id', () async {
    final h = CallHarness();
    final errors = <String>[];
    h.manager.onCallError = errors.add;
    h.api.acceptResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALL_STATE');
    await h.ringIncoming();
    await h.manager.acceptCall();
    expect(h.finishes.single.reason, CallExitReason.acceptConflict);
    expect(errors, isEmpty);
    expect(h.api.deviceIds['accept'], 'device-1');
  });

  test('answered on another device: this device stops ringing', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.state('active');
    expect(h.finishes.single.reason, CallExitReason.answeredElsewhere);
  });

  test('the caller sees the outcome for 1.5 s before the screen closes', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.startOutgoing();
      async.flushMicrotasks();
      h.state('missed', outcome: 'no_answer');
      async.flushMicrotasks();
      expect(h.finishes.single.outcome, CallOutcome.noAnswer);
      expect(h.closes, 0);
      async.elapse(const Duration(milliseconds: 1499));
      expect(h.closes, 0);
      async.elapse(const Duration(milliseconds: 2));
      expect(h.closes, 1);
    });
  });

  test('the 5-minute free cap is gone: the client never ends a connected call', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.startOutgoing();
      async.flushMicrotasks();
      h.state('active');
      async.flushMicrotasks();
      h.liveKit.onPeerConnected!();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 6));
      expect(h.finishes, isEmpty);
      expect(h.api.calls.where((c) => c.startsWith('end:')), isEmpty);
    });
  });

  test('ring safety net: no call:state for 50 s → GET /calls/:id decides', () {
    fakeAsync((async) {
      final h = CallHarness();
      h.api.getResult = const CallApiResult(ok: true, statusCode: 200, data: {'status': 'missed', 'outcome': 'no_answer'});
      h.startOutgoing();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 49));
      expect(h.finishes, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(h.api.calls, contains('get:call-1'));
      expect(h.finishes.single.outcome, CallOutcome.noAnswer);
    });
  });

  test('socket + push for the same call → one incoming screen, one ringtone', () async {
    final h = CallHarness();
    await h.manager.handleIncoming(CallHarness.incomingPayload(), source: IncomingSource.socket);
    await h.manager.handleIncoming({
      'type': 'incoming_call', 'callId': 'call-1', 'callUuid': kCallUuid, 'callerName': 'Ada', 'callType': 'audio',
    }, source: IncomingSource.push);
    expect(h.opened, ['incoming:call-1']);
    expect(h.platform.log.where((l) => l == 'ringtone'), hasLength(1));
  });

  test('CALLEE_BUSY: calleeBusy result, no call, LiveKit untouched', () async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLEE_BUSY');
    final r = await h.startOutgoing();
    expect(r.status, InitiateStatus.calleeBusy);
    expect(h.manager.currentCall, isNull);
    expect(h.liveKits, hasLength(1), reason: 'only the idle instance from construction');
  });

  test('hanging up while /initiate is in flight cancels the call the server created', () async {
    final h = CallHarness();
    h.api.initiateGate = Completer<void>();
    final pending = h.startOutgoing();
    await pumpEventQueue();
    expect(h.api.calls, ['initiate:u-callee:audio']);
    await h.manager.endCall();
    h.api.initiateGate!.complete();
    final r = await pending;
    expect(r.status, InitiateStatus.failed);
    expect(h.api.calls, contains('end:call-1'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/call_manager_test.dart`
Expected: FAIL — compile errors: `Method not found: 'CallManager.forTest'`, `Undefined name 'CallManagerDeps'`, `'InitiateStatus' isn't a type`.

- [ ] **Step 3: Implement**

Replace `lib/services/call_manager.dart` with:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_platform.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call_livekit_manager.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';

enum CallUiState { ringing, connecting, connected, reconnecting, poorConnection, ended }

enum CallQuality { good, fair, poor }

/// Why a call left this device.
enum CallExitReason {
  localHangUp,
  declined,
  remoteState,
  answeredElsewhere,
  acceptConflict,
  connectionLost,
  error,
}

/// Where an incoming call was first heard about (socket, FCM, a tapped
/// notification, resume recovery, or CallKit). Used for dedupe decisions.
enum IncomingSource { socket, push, notificationTap, recovery, callKit }

enum InitiateStatus { started, calleeBusy, callerBusy, permissionDenied, failed }

class InitiateResult {
  const InitiateResult(this.status, [this.error]);
  final InitiateStatus status;
  final String? error;
}

/// Emitted exactly once per call when it leaves this device.
class CallFinish {
  const CallFinish({required this.call, required this.reason, this.outcome});
  final CallModel call;
  final CallExitReason reason;
  final CallOutcome? outcome;
}

class CallManagerDeps {
  const CallManagerDeps({
    required this.api,
    required this.platform,
    required this.liveKitFactory,
    required this.closeCallScreens,
    required this.openActiveCall,
    required this.openIncomingCall,
  });

  factory CallManagerDeps.production() => CallManagerDeps(
        api: RestCallApi(),
        platform: DeviceCallPlatform(),
        liveKitFactory: CallLiveKitManager.new,
        closeCallScreens: CallRoutes.closeAll,
        openActiveCall: CallRoutes.openActive,
        openIncomingCall: CallRoutes.openIncoming,
      );

  final CallApi api;
  final CallPlatform platform;
  final CallLiveKitManager Function() liveKitFactory;
  final void Function() closeCallScreens;
  final void Function(CallModel call) openActiveCall;
  final void Function(CallModel call) openIncomingCall;
}

/// How long the caller sees "No answer" / "Declined" before the screen closes.
const Duration kOutcomeBannerDuration = Duration(milliseconds: 1500);

/// Ringing out with no call:state (socket down): ask the server after this.
const Duration kRingSafetyTimeout = Duration(seconds: 50);

/// 1:1 call controller — a FOLLOWER of the server's call state.
///
/// The server decides every transition (spec §4.1); this class reacts to
/// `call:state` for its own `callId` only, and leaves a call through one
/// path, [_finish], which runs at most once per call and always closes the
/// call screens.
class CallManager with WidgetsBindingObserver {
  static CallManager _instance = CallManager._internal(CallManagerDeps.production());
  factory CallManager() => _instance;
  CallManager._internal(this._deps) : _liveKit = _deps.liveKitFactory();

  @visibleForTesting
  factory CallManager.forTest(CallManagerDeps deps) => CallManager._internal(deps);

  @visibleForTesting
  static void debugSetInstance(CallManager manager) => _instance = manager;

  final CallManagerDeps _deps;
  CallLiveKitManager _liveKit;
  io.Socket? _socket;
  bool _isInitialized = false;
  bool _appInForeground = true;

  CallModel? currentCall;
  String? _acceptingCallId;
  String? _incomingShownFor;
  final List<String> _recentlyFinished = [];
  Timer? _closeTimer;
  Timer? _ringSafetyTimer;

  final StreamController<CallFinish> _finishController = StreamController<CallFinish>.broadcast();

  /// Every call that leaves this device, once.
  Stream<CallFinish> get finishes => _finishController.stream;

  // Callbacks ----------------------------------------------------------------
  Function(CallModel)? onIncomingCall;
  Function(CallModel)? onCallAccepted;
  Function(CallModel)? onCallRejected;
  Function(CallModel)? onCallEnded;
  void Function(CallFinish)? onCallFinished;
  Function(String)? onCallError;
  Function(bool)? onPeerMuteChanged;
  Function(bool)? onPeerVideoChanged;
  Function()? onPeerReconnecting;
  Function()? onPeerReconnected;
  Function()? onReconnecting;
  Function()? onReconnected;
  Function(CallModel)? onCallConnected;
  Function(CallUiState)? onConnectionStateChanged;
  Function(CallQuality)? onCallQualityChanged;

  CallUiState _connectionState = CallUiState.ringing;
  CallQuality _callQuality = CallQuality.good;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  bool _isFrontCamera = true;

  CallUiState get connectionState => _connectionState;
  CallQuality get callQuality => _callQuality;
  CallLiveKitManager get liveKit => _liveKit;
  bool get isInitialized => _isInitialized;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;

  /// The only socket events a call listens to. Everything else (accepted,
  /// declined, ended, missed, timeout) arrives as call:state.
  static const List<String> socketEvents = [
    'call:incoming',
    'call:state',
    'call:mute',
    'call:peer-muted',
    'call:video-toggle',
    'call:peer-video-toggled',
    'call:peer-reconnecting',
    'call:peer-reconnected',
  ];

  Future<void> initialize(ChatSocketService chatSocketService) async {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    bindSocket(chatSocketService.socket);
    if (!_isInitialized) _initCallKit();
    _isInitialized = true;
  }

  /// Move the call listeners onto [socket] (and off the previous one).
  void bindSocket(io.Socket? socket) {
    if (identical(socket, _socket)) return;
    final previous = _socket;
    if (previous != null) {
      for (final event in socketEvents) {
        previous.off(event);
      }
    }
    _socket = socket;
    if (socket == null) return;
    for (final event in socketEvents) {
      socket.on(event, (data) => handleSocketEvent(event, data));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
  }

  // -- Socket ----------------------------------------------------------------

  @visibleForTesting
  Future<void> handleSocketEvent(String event, dynamic data) async {
    if (data is! Map) return;
    final m = Map<String, dynamic>.from(data);
    switch (event) {
      case 'call:incoming':
        await handleIncoming(m, source: IncomingSource.socket);
        return;
      case 'call:state':
        await _onCallState(m);
        return;
    }
    final cur = currentCall;
    if (cur == null || m['callId']?.toString() != cur.callId) return;
    switch (event) {
      case 'call:mute':
      case 'call:peer-muted':
        final muted = m['isMuted'] == true;
        currentCall = cur.copyWith(isPeerMuted: muted);
        onPeerMuteChanged?.call(muted);
      case 'call:video-toggle':
      case 'call:peer-video-toggled':
        final on = m['isVideoEnabled'] == true;
        currentCall = cur.copyWith(isPeerVideoEnabled: on);
        onPeerVideoChanged?.call(on);
      case 'call:peer-reconnecting':
        onPeerReconnecting?.call();
      case 'call:peer-reconnected':
        onPeerReconnected?.call();
    }
  }

  /// An incoming call from any source. The same callId from a second source
  /// only fills in missing fields — one incoming UI per call.
  Future<void> handleIncoming(
    Map<String, dynamic> payload, {
    IncomingSource source = IncomingSource.socket,
  }) async {
    final call = CallModel.fromJson(payload, CallDirection.incoming);
    if (call.callId.isEmpty) return;
    final cur = currentCall;
    if (cur != null) {
      if (cur.callId == call.callId) {
        currentCall = cur.copyWith(
          callUuid: cur.callUuid ?? call.callUuid,
          livekitUrl: cur.livekitUrl ?? call.livekitUrl,
          roomName: cur.roomName ?? call.roomName,
        );
        if (source == IncomingSource.notificationTap && cur.status == CallStatus.ringing) {
          _showIncoming(currentCall!);
        }
      }
      return;
    }
    if (_recentlyFinished.contains(call.callId)) return;

    _takeOverClosingScreens();
    currentCall = call.copyWith(status: CallStatus.ringing);
    onIncomingCall?.call(currentCall!);
    if (_appInForeground || source == IncomingSource.notificationTap) {
      unawaited(_deps.platform.startRingtone());
      _showIncoming(currentCall!);
    } else {
      await _deps.platform.showIncomingCallUi(currentCall!);
    }
  }

  void _showIncoming(CallModel call) {
    if (_incomingShownFor == call.callId) return;
    _incomingShownFor = call.callId;
    _deps.openIncomingCall(call);
  }

  Future<void> _onCallState(Map<String, dynamic> m) async {
    final cur = currentCall;
    final callId = m['callId']?.toString();
    if (cur == null || callId == null || callId != cur.callId) return;
    final status = m['status']?.toString();
    final outcome = callOutcomeFromWire(m['outcome']?.toString());

    if (status == 'active') {
      if (cur.direction == CallDirection.outgoing) {
        _ringSafetyTimer?.cancel();
        unawaited(_deps.platform.stopTones());
        currentCall = cur.copyWith(status: CallStatus.connecting);
        _updateConnectionState(CallUiState.connecting);
        onCallAccepted?.call(currentCall!);
      } else if (_acceptingCallId != callId) {
        await _finish(CallExitReason.answeredElsewhere);
      }
      return;
    }
    const terminal = {'ended', 'missed', 'rejected', 'busy', 'failed'};
    if (terminal.contains(status)) {
      currentCall = cur.copyWith(duration: (m['duration'] as num?)?.toInt());
      await _finish(CallExitReason.remoteState, outcome: outcome);
    }
  }

  // -- LiveKit -----------------------------------------------------------------

  void _wireLiveKit(CallLiveKitManager m) {
    m.onPeerConnected = _onPeerConnected;
    m.onPeerDisconnected = _onPeerDisconnected;
    m.onPeerMuteChanged = (muted) {
      final c = currentCall;
      if (c != null) currentCall = c.copyWith(isPeerMuted: muted);
      onPeerMuteChanged?.call(muted);
    };
    m.onPeerVideoChanged = (enabled) {
      final c = currentCall;
      if (c != null) currentCall = c.copyWith(isPeerVideoEnabled: enabled);
      onPeerVideoChanged?.call(enabled);
    };
    m.onConnectionQualityChanged = _onQuality;
    m.onReconnecting = _onLocalReconnecting;
    m.onReconnected = _onLocalReconnected;
    m.onLocalDisconnected = _onLocalDisconnected;
  }

  void _detachLiveKit(CallLiveKitManager m) {
    m.onPeerConnected = null;
    m.onPeerDisconnected = null;
    m.onPeerMuteChanged = null;
    m.onPeerVideoChanged = null;
    m.onConnectionQualityChanged = null;
    m.onReconnecting = null;
    m.onReconnected = null;
    m.onLocalDisconnected = null;
  }

  void _onPeerConnected() {
    final c = currentCall;
    if (c == null) return;
    if (c.status != CallStatus.connected) {
      currentCall = c.copyWith(status: CallStatus.connected);
      unawaited(_deps.platform.stopTones());
      unawaited(_deps.platform.playConnectSound());
      // CallLiveKitManager.connect already routed audio (speaker for video).
      _isSpeakerOn = c.callType == CallType.video;
      onCallConnected?.call(currentCall!);
    }
    _updateConnectionState(CallUiState.connected);
    onPeerReconnected?.call();
  }

  void _onPeerDisconnected() {
    if (currentCall == null) return;
    _updateConnectionState(CallUiState.reconnecting);
    onPeerReconnecting?.call();
  }

  void _onLocalReconnecting() {
    if (currentCall == null) return;
    _updateConnectionState(CallUiState.reconnecting);
    onReconnecting?.call();
  }

  void _onLocalReconnected() {
    if (currentCall == null) return;
    _updateConnectionState(CallUiState.connected);
    onReconnected?.call();
  }

  void _onLocalDisconnected(lk.DisconnectReason? reason) {
    final c = currentCall;
    if (c == null) return;
    const hangUps = {
      lk.DisconnectReason.roomDeleted,
      lk.DisconnectReason.participantRemoved,
      lk.DisconnectReason.serverShutdown,
      lk.DisconnectReason.duplicateIdentity,
    };
    if (hangUps.contains(reason)) {
      unawaited(_finish(CallExitReason.remoteState,
          outcome: c.status == CallStatus.connected ? CallOutcome.completed : null));
      return;
    }
    if (c.callId.isNotEmpty) unawaited(_deps.api.end(c.callId));
    onCallError?.call('Connection lost');
    unawaited(_finish(CallExitReason.connectionLost));
  }

  void _onQuality(lk.ConnectionQuality quality) {
    final mapped = switch (quality) {
      lk.ConnectionQuality.excellent || lk.ConnectionQuality.good => CallQuality.good,
      lk.ConnectionQuality.poor || lk.ConnectionQuality.lost => CallQuality.poor,
      _ => CallQuality.fair,
    };
    if (mapped == _callQuality) return;
    _callQuality = mapped;
    onCallQualityChanged?.call(mapped);
    if (mapped == CallQuality.poor && _connectionState == CallUiState.connected) {
      _updateConnectionState(CallUiState.poorConnection);
    } else if (mapped != CallQuality.poor && _connectionState == CallUiState.poorConnection) {
      _updateConnectionState(CallUiState.connected);
    }
  }

  void _updateConnectionState(CallUiState next) {
    if (_connectionState == next) return;
    _connectionState = next;
    onConnectionStateChanged?.call(next);
  }

  // -- CallKit ------------------------------------------------------------------

  void _initCallKit() {
    final callKit = CallKitService();
    callKit.initialize();
    callKit.onAccepted = (id, extra) => unawaited(handleCallKitAccept(id, extra));
    callKit.onDeclined = (id, extra) => unawaited(handleCallKitDecline(id, extra));
    callKit.onEnded = (id, extra) => unawaited(handleCallKitEnded(id, extra));
  }

  bool _matches(CallModel c, String id, Map<String, dynamic>? extra) =>
      id == c.callId || id == c.callUuid || extra?['callId']?.toString() == c.callId;

  Future<void> handleCallKitAccept(String id, Map<String, dynamic>? extra) async {
    final cur = currentCall;
    if (cur == null) {
      final callId = extra?['callId']?.toString();
      if (callId == null || callId.isEmpty) return;
      currentCall = CallModel.fromJson(
        {...extra!, 'callId': callId, 'callUuid': extra['callUuid'] ?? id},
        CallDirection.incoming,
      );
    } else if (!_matches(cur, id, extra) || cur.status != CallStatus.ringing) {
      return;
    }
    _incomingShownFor = currentCall!.callId; // CallKit is the incoming UI
    await acceptCall();
    final accepted = currentCall;
    if (accepted != null && accepted.status == CallStatus.connecting) {
      _deps.openActiveCall(accepted);
    }
  }

  Future<void> handleCallKitDecline(String id, Map<String, dynamic>? extra) async {
    final cur = currentCall;
    if (cur != null && _matches(cur, id, extra)) {
      await rejectCall();
      return;
    }
    final callId = extra?['callId']?.toString();
    if (cur == null && callId != null && callId.isNotEmpty) {
      unawaited(_deps.api.decline(callId, deviceId: await _deps.platform.deviceId()));
    }
  }

  Future<void> handleCallKitEnded(String id, Map<String, dynamic>? extra) async {
    final cur = currentCall;
    if (cur != null && _matches(cur, id, extra)) await endCall();
  }

  // -- Public API: lifecycle ---------------------------------------------------

  Future<InitiateResult> initiateCall(
    String targetUserId,
    String targetUserName,
    String? targetUserProfilePicture,
    CallType callType,
  ) async {
    if (currentCall != null) return const InitiateResult(InitiateStatus.callerBusy);
    final video = callType == CallType.video;
    if (!await _deps.platform.ensurePermissions(video: video)) {
      final err = await _deps.platform.permissionError(video: video, accepting: false);
      onCallError?.call(err);
      return InitiateResult(InitiateStatus.permissionDenied, err);
    }

    _takeOverClosingScreens();
    final draft = CallModel(
      callId: '',
      userId: targetUserId,
      userName: targetUserName,
      userProfilePicture: targetUserProfilePicture,
      callType: callType,
      direction: CallDirection.outgoing,
      status: CallStatus.ringing,
      startTime: DateTime.now(),
    );
    currentCall = draft;

    final res = await _deps.api.initiate(receiverId: targetUserId, type: callType);
    final callJson = res.data['call'];
    final serverId = callJson is Map ? (callJson['_id'] ?? callJson['id'])?.toString() : null;

    if (!identical(currentCall, draft)) {
      // Hung up while /initiate was in flight: cancel what the server created.
      if (res.ok && serverId != null) unawaited(_deps.api.end(serverId));
      return const InitiateResult(InitiateStatus.failed);
    }
    if (!res.ok) {
      currentCall = null;
      if (res.isCalleeBusy) return const InitiateResult(InitiateStatus.calleeBusy);
      if (res.isCallerBusy) return const InitiateResult(InitiateStatus.callerBusy);
      final err = res.error ?? 'Failed to start call';
      onCallError?.call(err);
      return InitiateResult(InitiateStatus.failed, err);
    }

    final token = res.data['token']?.toString();
    final url = res.data['url']?.toString();
    if (serverId == null || token == null || url == null) {
      currentCall = null;
      if (serverId != null) unawaited(_deps.api.end(serverId));
      onCallError?.call('Server response missing call data');
      return const InitiateResult(InitiateStatus.failed);
    }

    currentCall = draft.copyWith(
      callId: serverId,
      callUuid: (callJson as Map)['callUuid']?.toString(),
      livekitToken: token,
      livekitUrl: url,
      roomName: res.data['roomName']?.toString(),
    );

    final media = _deps.liveKitFactory();
    _liveKit = media;
    _wireLiveKit(media);
    try {
      await media.connect(url: url, token: token, type: callType);
    } catch (e) {
      debugPrint('📞 LiveKit connect failed: $e');
      unawaited(_deps.api.end(serverId));
      onCallError?.call('Failed to connect to call');
      await _finish(CallExitReason.error);
      return const InitiateResult(InitiateStatus.failed);
    }
    if (currentCall?.callId != serverId) return const InitiateResult(InitiateStatus.started);

    _isMuted = false;
    _isVideoEnabled = video;
    unawaited(_deps.platform.startRingback());
    _ringSafetyTimer = Timer(kRingSafetyTimeout, () => unawaited(_checkStillRinging(serverId)));
    return const InitiateResult(InitiateStatus.started);
  }

  Future<void> _checkStillRinging(String callId) async {
    final cur = currentCall;
    if (cur == null || cur.callId != callId || cur.status != CallStatus.ringing) return;
    final res = await _deps.api.get(callId);
    if (!res.ok || currentCall?.callId != callId) return;
    final status = res.data['status']?.toString();
    if (status == 'ringing' || status == 'active') return;
    await _finish(CallExitReason.remoteState,
        outcome: callOutcomeFromWire(res.data['outcome']?.toString()));
  }

  Future<void> acceptCall() async {
    final call = currentCall;
    if (call == null || call.direction != CallDirection.incoming) return;
    if (_acceptingCallId == call.callId) return; // double tap
    _acceptingCallId = call.callId;
    await _deps.platform.stopTones();

    final video = call.callType == CallType.video;
    if (!await _deps.platform.ensurePermissions(video: video)) {
      final err = await _deps.platform.permissionError(video: video, accepting: true);
      onCallError?.call(err);
      await rejectCall();
      return;
    }

    final res = await _deps.api.accept(call.callId, deviceId: await _deps.platform.deviceId());
    if (currentCall?.callId != call.callId) return;
    if (res.isCallStateConflict) {
      // Another device answered, or it was cancelled / timed out: dismiss silently.
      await _finish(CallExitReason.acceptConflict);
      return;
    }
    final token = res.data['token']?.toString();
    final url = res.data['url']?.toString();
    if (!res.ok || token == null || url == null) {
      onCallError?.call(res.error ?? 'Failed to accept call');
      unawaited(_deps.api.end(call.callId));
      await _finish(CallExitReason.error);
      return;
    }

    currentCall = call.copyWith(
      status: CallStatus.connecting,
      livekitToken: token,
      livekitUrl: url,
      roomName: res.data['roomName']?.toString(),
    );
    _incomingShownFor = null;
    _updateConnectionState(CallUiState.connecting);

    final media = _deps.liveKitFactory();
    _liveKit = media;
    _wireLiveKit(media);
    try {
      await media.connect(url: url, token: token, type: call.callType);
    } catch (e) {
      debugPrint('📞 LiveKit connect failed: $e');
      unawaited(_deps.api.end(call.callId));
      onCallError?.call('Failed to connect to call');
      await _finish(CallExitReason.error);
      return;
    }
    if (currentCall?.callId != call.callId) return;
    _isMuted = false;
    _isVideoEnabled = video;
    onCallAccepted?.call(currentCall!);
  }

  Future<void> rejectCall() async {
    final call = currentCall;
    if (call == null) {
      _deps.closeCallScreens();
      return;
    }
    if (call.callId.isNotEmpty) {
      final deviceId = await _deps.platform.deviceId();
      unawaited(_deps.api.decline(call.callId, deviceId: deviceId));
    }
    if (currentCall?.callId != call.callId) return;
    onCallRejected?.call(call.copyWith(status: CallStatus.rejected));
    await _finish(CallExitReason.declined);
  }

  /// Hang up. Always closes the call screen, even when there is no call.
  Future<void> endCall() async {
    final call = currentCall;
    if (call == null) {
      _deps.closeCallScreens();
      return;
    }
    unawaited(_deps.platform.playEndSound());
    if (call.callId.isNotEmpty) unawaited(_deps.api.end(call.callId));
    await _finish(CallExitReason.localHangUp,
        outcome: call.status == CallStatus.connected ? CallOutcome.completed : null);
  }

  // -- The single exit path ----------------------------------------------------

  Future<void> _finish(CallExitReason reason, {CallOutcome? outcome}) async {
    final call = currentCall;
    if (call == null) {
      _deps.closeCallScreens();
      return;
    }
    // Synchronous part first: any second exit now sees no call.
    currentCall = null;
    _remember(call.callId);
    _acceptingCallId = null;
    _incomingShownFor = null;
    _ringSafetyTimer?.cancel();
    _closeTimer?.cancel();
    final media = _liveKit;
    _detachLiveKit(media);
    _liveKit = _deps.liveKitFactory();
    _resetMediaState();

    final ended = call.copyWith(status: CallStatus.ended, endTime: DateTime.now());
    final finish = CallFinish(call: ended, reason: reason, outcome: outcome);
    onCallEnded?.call(ended);
    onCallFinished?.call(finish);
    _finishController.add(finish);

    final showBanner = reason == CallExitReason.remoteState &&
        call.direction == CallDirection.outgoing &&
        outcome != null &&
        outcome != CallOutcome.completed;
    if (showBanner) {
      _closeTimer = Timer(kOutcomeBannerDuration, _deps.closeCallScreens);
    } else {
      _deps.closeCallScreens();
    }

    await Future.wait([
      _quietly(media.disconnect),
      _quietly(_deps.platform.stopTones),
      _quietly(() => _deps.platform.endCallUi(call)),
      _quietly(_deps.platform.cancelIncomingNotification),
    ]);
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('📞 call cleanup: $e');
    }
  }

  void _resetMediaState() {
    _connectionState = CallUiState.ringing;
    _callQuality = CallQuality.good;
    _isMuted = false;
    _isVideoEnabled = true;
    _isSpeakerOn = false;
    _isFrontCamera = true;
  }

  void _remember(String callId) {
    if (callId.isEmpty) return;
    _recentlyFinished.add(callId);
    if (_recentlyFinished.length > 20) _recentlyFinished.removeAt(0);
  }

  /// A new call while the previous one's outcome banner is still up: close
  /// the old screens now rather than letting the timer close the new ones.
  void _takeOverClosingScreens() {
    final pending = _closeTimer;
    _closeTimer = null;
    if (pending != null && pending.isActive) {
      pending.cancel();
      _deps.closeCallScreens();
    }
  }

  // -- Media controls ----------------------------------------------------------

  void setMuted(bool muted) {
    _isMuted = muted;
    unawaited(_liveKit.setMuted(muted));
    _emitToPeer('call:mute', {'isMuted': muted});
  }

  void toggleMute() => setMuted(!_isMuted);

  void setVideoEnabled(bool enabled) {
    _isVideoEnabled = enabled;
    unawaited(_liveKit.setCameraEnabled(enabled));
    _emitToPeer('call:video-toggle', {'isVideoEnabled': enabled});
  }

  void toggleVideo() => setVideoEnabled(!_isVideoEnabled);

  Future<void> setSpeakerOn(bool on) async {
    _isSpeakerOn = on;
    try {
      await lk.Hardware.instance.setSpeakerphoneOn(on);
    } catch (e) {
      debugPrint('🔊 setSpeakerphoneOn failed: $e');
    }
  }

  Future<void> toggleSpeaker() => setSpeakerOn(!_isSpeakerOn);

  Future<void> switchCamera() async {
    final local = _liveKit.room?.localParticipant;
    if (local == null) return;
    for (final pub in local.videoTrackPublications) {
      final track = pub.track;
      if (track is lk.LocalVideoTrack) {
        try {
          await track.setCameraPosition(
              _isFrontCamera ? lk.CameraPosition.back : lk.CameraPosition.front);
          _isFrontCamera = !_isFrontCamera;
        } catch (e) {
          debugPrint('📞 switchCamera failed: $e');
        }
        return;
      }
    }
  }

  void _emitToPeer(String event, Map<String, dynamic> body) {
    final socket = _socket;
    final call = currentCall;
    if (socket == null || call == null || call.callId.isEmpty) return;
    socket.emit(event, {'callId': call.callId, ...body});
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_finish(CallExitReason.localHangUp));
  }
}
```

In `lib/services/callkit_service.dart`:
- replace lines 44-46 with

```dart
  Function(String callKitId, Map<String, dynamic>? extra)? onAccepted;
  Function(String callKitId, Map<String, dynamic>? extra)? onDeclined;
  Function(String callKitId, Map<String, dynamic>? extra)? onEnded;
```

- replace the `switch (event.event)` cases for accept/decline/ended/timeout (82-108) with

```dart
        case Event.actionCallAccept:
          final id = _extractId(event.body);
          if (id != null) onAccepted?.call(id, _extraOf(event.body));
          break;
        case Event.actionCallDecline:
          final id = _extractId(event.body);
          if (id != null) onDeclined?.call(id, _extraOf(event.body));
          break;
        case Event.actionCallEnded:
          final id = _extractId(event.body);
          if (id != null) onEnded?.call(id, _extraOf(event.body));
          _activeCallUuid = null;
          break;
        case Event.actionCallTimeout:
          final id = _extractId(event.body);
          if (id != null) onDeclined?.call(id, _extraOf(event.body));
          _activeCallUuid = null;
          break;
```

- add next to `_extractId`:

```dart
  Map<String, dynamic>? _extraOf(Map<String, dynamic>? body) {
    final extra = body?['extra'];
    return extra is Map ? Map<String, dynamic>.from(extra) : null;
  }
```

Replace `lib/providers/call_provider.dart` with:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call_manager.dart'
    show CallManager, CallUiState, CallQuality, InitiateResult;

class CallNotifier extends ChangeNotifier {
  final CallManager _callManager = CallManager();

  CallModel? get currentCall => _callManager.currentCall;
  bool get isInCall => currentCall != null;
  bool get isMuted => _callManager.isMuted;
  bool get isVideoEnabled => _callManager.isVideoEnabled;
  bool get isSpeakerOn => _callManager.isSpeakerOn;
  CallUiState get connectionState => _callManager.connectionState;
  CallQuality get callQuality => _callManager.callQuality;

  CallManager get callManager => _callManager;

  void setIncomingCallCallback(Function(CallModel) callback) {
    _callManager.onIncomingCall = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallAcceptedCallback(Function(CallModel) callback) {
    _callManager.onCallAccepted = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallRejectedCallback(Function(CallModel) callback) {
    _callManager.onCallRejected = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallEndedCallback(Function(CallModel) callback) {
    _callManager.onCallEnded = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallConnectedCallback(Function(CallModel) callback) {
    _callManager.onCallConnected = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallErrorCallback(Function(String) callback) {
    _callManager.onCallError = callback;
  }

  void setConnectionStateCallback(Function(CallUiState) callback) {
    _callManager.onConnectionStateChanged = (state) {
      callback(state);
      notifyListeners();
    };
  }

  void setCallQualityCallback(Function(CallQuality) callback) {
    _callManager.onCallQualityChanged = (quality) {
      callback(quality);
      notifyListeners();
    };
  }

  Future<InitiateResult> initiateCall(
    String targetUserId,
    String targetUserName,
    String? targetUserProfilePicture,
    CallType callType,
  ) async {
    final result = await _callManager.initiateCall(
        targetUserId, targetUserName, targetUserProfilePicture, callType);
    notifyListeners();
    return result;
  }

  Future<void> acceptCall() async {
    await _callManager.acceptCall();
    notifyListeners();
  }

  void rejectCall() {
    unawaited(_callManager.rejectCall().then((_) => notifyListeners()));
  }

  void endCall() {
    unawaited(_callManager.endCall().then((_) => notifyListeners()));
  }

  void toggleMute() {
    _callManager.toggleMute();
    notifyListeners();
  }

  void toggleVideo() {
    _callManager.toggleVideo();
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    await _callManager.toggleSpeaker();
    notifyListeners();
  }

  Future<void> switchCamera() => _callManager.switchCamera();

  @override
  void dispose() {
    _callManager.dispose();
    super.dispose();
  }
}

final callProvider = ChangeNotifierProvider<CallNotifier>((ref) {
  return CallNotifier();
});
```

In `lib/main.dart` delete the import on line 19 (`incoming_call_screen.dart`) and replace the `callNotifier.setIncomingCallCallback((call) { … });` block (lines 275-289) with:

```dart
      // CallManager opens the incoming screen itself (one UI per callId);
      // the callback only keeps the provider's listeners in sync.
      callNotifier.setIncomingCallCallback((_) {});
```

In `lib/services/notification_router.dart`:
- delete the imports `package:bananatalk_app/models/call_model.dart` and `package:bananatalk_app/screens/incoming_call_screen.dart`;
- change `_handleIncomingCallNotification(data);` (line 85) to `await _handleIncomingCallNotification(data);`;
- replace `_handleIncomingCallNotification` and `_showIncomingCallScreen` (434-504) with:

```dart
  /// A tapped incoming-call notification. CallManager dedupes by callId and
  /// opens the incoming screen; Task A6 adds the stale-notification check.
  static Future<void> _handleIncomingCallNotification(Map<String, dynamic> data) async {
    final callId = data['callId']?.toString() ?? '';
    if (callId.isEmpty) {
      goRouter.go('/home');
      return;
    }
    await CallManager().handleIncoming(data, source: IncomingSource.notificationTap);
  }
```

Replace `lib/screens/incoming_call_screen.dart` with:

```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call_manager.dart';

/// Incoming-call ring screen. CallManager opens it (once per callId) and
/// closes it through its single exit path.
class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _busy = false;

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final manager = CallManager();
    await manager.acceptCall();
    if (!mounted) return;
    final accepted = manager.currentCall;
    if (accepted != null &&
        accepted.callId == widget.call.callId &&
        accepted.status == CallStatus.connecting) {
      Navigator.of(context).pushReplacement(CallRoutes.activeRoute(accepted));
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final call = widget.call;
    final isVideo = call.callType == CallType.video;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      isVideo ? l10n.incomingVideoCall : l10n.incomingAudioCall,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Icon(isVideo ? Icons.videocam : Icons.phone, color: Colors.white, size: 40),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: call.userProfilePicture != null
                        ? NetworkImage(call.userProfilePicture!)
                        : null,
                    child: call.userProfilePicture == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white54)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    call.userName,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.callRinging, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallActionButton(
                      icon: Icons.call_end,
                      label: l10n.declineCall,
                      color: Colors.red,
                      onPressed: _busy ? null : () => CallManager().rejectCall(),
                    ),
                    _CallActionButton(
                      icon: isVideo ? Icons.videocam : Icons.call,
                      label: l10n.acceptCall,
                      color: Colors.green,
                      onPressed: _busy ? null : _accept,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 35),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
```

In `lib/screens/active_call_screen.dart`:
- delete the field `int? _durationWarningRemaining; // seconds remaining when warning fires`;
- replace the `callNotifier.setCallEndedCallback((call) { … });` block (85-99) with

```dart
      // CallManager closes the call screens itself (and keeps the caller's
      // outcome on screen for 1.5 s); this only freezes the controls.
      callNotifier.setCallEndedCallback((call) {
        if (mounted) {
          setState(() {
            _callEnded = true;
            _isEnding = true;
          });
        }
      });
```

- delete the two blocks `// Listen for call duration warning (1 min remaining)` … `});` and `// Listen for call duration limit reached` … `});` (162-176);
- delete the `// Duration limit warning banner (1 min remaining)` `if (_durationWarningRemaining != null) Positioned(…),` block (563-591);
- in the End button replace the comment `// Don't pop here — onCallEnded callback handles it` with `// CallManager.endCall always closes the screen, even with no call.`

In `lib/pages/chat/header/chat_app_bar.dart`:
- delete imports `package:bananatalk_app/screens/active_call_screen.dart`, `package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey;` and `package:bananatalk_app/utils/app_page_route.dart`; add `import 'package:bananatalk_app/services/call/call_routes.dart';`;
- delete the lines `// VIP gating removed — all calls treated as unlimited.` and `callNotifier.setVipCall(true);`;
- replace the `callOverlayNavigatorKey.currentState?.push(AppPageRoute(builder: (_) => ActiveCallScreen(call: currentCall), fullscreenDialog: true,),);` statement with `CallRoutes.openActive(currentCall);`.

In `lib/screens/call_history_screen.dart` delete the three imports `vip_provider.dart`, `daily_call_limit_service.dart`, `vip_locked_feature.dart`, add `import 'package:bananatalk_app/services/call/call_routes.dart';` and `import 'package:bananatalk_app/services/call_manager.dart' show InitiateStatus;`, and replace `_initiateCall` (195-234) with:

```dart
  Future<void> _initiateCall(CallRecord record) async {
    final other = record.getOtherParticipant(_currentUserId);
    if (other == null) return;
    final callNotifier = ref.read(callProvider.notifier);
    final result = await callNotifier.initiateCall(
        other.id, other.name, other.profilePicture, record.type);
    final call = callNotifier.currentCall;
    if (result.status == InitiateStatus.started && call != null) {
      CallRoutes.openActive(call);
    }
  }
```

In `lib/services/session_activities.dart` replace `if (calls.currentCall != null) calls.endCall();` with `if (calls.currentCall != null) await calls.endCall();`.

In `docs/REMAINING_WORK.md` tick `  - [x] A4 CallManager follower + single exit path; 5-minute cap removed`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/call_manager_test.dart && flutter test test/services/session_reset_test.dart test/services/sign_out_and_reset_test.dart && flutter analyze lib`
Expected: call_manager_test all pass (17 tests); session tests still pass; `flutter analyze` reports no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/call_manager.dart lib/services/callkit_service.dart lib/providers/call_provider.dart lib/main.dart lib/services/notification_router.dart lib/screens/incoming_call_screen.dart lib/screens/active_call_screen.dart lib/pages/chat/header/chat_app_bar.dart lib/screens/call_history_screen.dart lib/services/session_activities.dart pubspec.yaml pubspec.lock test/helpers/call_fakes.dart test/services/call_manager_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): CallManager follows server call state with one exit path

CallManager now reacts to call:incoming and call:state for its own callId
only (the legacy per-outcome listeners, the client 45 s timeout and the
free-user 5-minute cap are gone). Every way a call ends goes through
_finish(), which runs once, tears down LiveKit, tones, CallKit (by
callUuid) and the incoming notification, and closes the call screens -
after a 1.5 s outcome banner for the caller, immediately otherwise. End
always closes the screen, even with no call. A 409 on accept dismisses
silently; an accept on another device stops this one ringing. Socket and
push for the same call open one incoming screen. API, platform, LiveKit and
navigation are injected so all of this is unit-tested.

Still open (calls app): A5-A14; native review of call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---
### Task A5: Re-bind call listeners when the chat socket is replaced

**Files:**
- Modify: `lib/services/chat_socket_service.dart` (imports 1-8; fields ~40-90; `connect()` 273-292)
- Modify: `lib/services/call_manager.dart` (`initialize`, new `attachSocketService`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/services/call_socket_rebind_test.dart`

**Interfaces:**
- Consumes: `CallManager.bindSocket` (A4).
- Produces: `ChatSocketService.onSocketReplaced: Stream<IO.Socket>` (fires after every new socket instance is created and its base listeners are installed, before `connect()`); `@visibleForTesting ChatSocketService.debugInstallSocket(IO.Socket)`; `CallManager.attachSocketService(ChatSocketService)`.

- [ ] **Step 1: Write the failing test**

Create `test/services/call_socket_rebind_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:bananatalk_app/services/chat_socket_service.dart';

import '../helpers/call_fakes.dart';

io.Socket _offlineSocket() => io.io(
      'http://127.0.0.1:9',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('call listeners follow the chat socket across replacements', () async {
    final h = CallHarness();
    final service = ChatSocketService();
    final first = _offlineSocket();
    final second = _offlineSocket();

    service.debugInstallSocket(first);
    h.manager.attachSocketService(service);
    expect(first.hasListeners('call:incoming'), isTrue);
    expect(first.hasListeners('call:state'), isTrue);

    service.debugInstallSocket(second); // resume / token refresh / login
    await pumpEventQueue();
    expect(second.hasListeners('call:incoming'), isTrue);
    expect(second.hasListeners('call:state'), isTrue);
    expect(first.hasListeners('call:state'), isFalse);

    first.dispose();
    second.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/call_socket_rebind_test.dart`
Expected: FAIL — `The method 'debugInstallSocket' isn't defined for the type 'ChatSocketService'`.

- [ ] **Step 3: Implement**

In `lib/services/chat_socket_service.dart`:
- add `import 'package:flutter/foundation.dart' show visibleForTesting;` to the imports;
- next to the other controllers (after `_presenceBulkController`, line ~58) add:

```dart
  /// Fires with every NEW socket instance (login, resume, token refresh,
  /// forced reset). Anything that registers its own listeners on [socket]
  /// (CallManager) must re-bind here — the old instance is cleared and
  /// disposed, so its listeners die with it.
  final _socketReplacedController = StreamController<IO.Socket>.broadcast();
  Stream<IO.Socket> get onSocketReplaced => _socketReplacedController.stream;

  void _installSocket(IO.Socket socket) {
    _socket = socket;
    _setupListeners();
    _safeAdd(_socketReplacedController, socket);
  }

  @visibleForTesting
  void debugInstallSocket(IO.Socket socket) => _installSocket(socket);
```

- in `connect()` change `_socket = IO.io(` (line 273) to `final socket = IO.io(`, and replace the following

```dart
      _setupListeners();
      _socket?.connect();
```

with

```dart
      _installSocket(socket);
      _socket?.connect();
```

In `lib/services/call_manager.dart` add the field `StreamSubscription<io.Socket>? _socketReplacedSub;` next to `io.Socket? _socket;`, replace `bindSocket(chatSocketService.socket);` inside `initialize` with `attachSocketService(chatSocketService);`, and add below `initialize`:

```dart
  /// Follow the chat socket across replacements. ChatSocketService replaces
  /// its socket on resume, token refresh and login; binding once (the old
  /// behaviour) left the app deaf to call:incoming after the first resume.
  void attachSocketService(ChatSocketService service) {
    _socketReplacedSub?.cancel();
    _socketReplacedSub = service.onSocketReplaced.listen(bindSocket);
    bindSocket(service.socket);
  }
```

In `docs/REMAINING_WORK.md` tick `  - [x] A5 re-bind call listeners when the socket is replaced`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/call_socket_rebind_test.dart test/services/call_manager_test.dart test/chat/message_delivered_test.dart`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/chat_socket_service.dart lib/services/call_manager.dart test/services/call_socket_rebind_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(calls): keep listening for calls after the chat socket is replaced

ChatSocketService replaces its socket on resume, token refresh and login,
but CallManager bound its listeners once, so after the first resume the
app never heard call:incoming again. ChatSocketService now announces every
new socket (onSocketReplaced) and CallManager re-binds to it.

Still open (calls app): A6-A14; native review of call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A6: Reliable incoming — foreground FCM, `call_cancelled`, stale taps, resume / cold-start recovery

**Files:**
- Create: `lib/services/call/call_push_handler.dart`
- Modify: `lib/services/call_manager.dart` (lifecycle; add `handleCallCancelled`, `resolveIncomingTap`, `recoverCallState`, `_rejoin`, enum `IncomingTapAction`)
- Modify: `lib/services/notification_service.dart` (background handler 21-56; `_handleForegroundMessage` 400-440)
- Modify: `lib/services/notification_router.dart` (`_handleIncomingCallNotification`)
- Modify: `lib/main.dart` (imports; `_initializeCallManager`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/services/call_incoming_test.dart`

**Interfaces:**
- Consumes: `CallApi.current/get` (A3), `CallKitIds` (A3), `handleIncoming`, `_finish` (A4); `GET /calls/current` shape (B6).
- Produces: `Future<bool> handleCallPush(Map<String, dynamic> data, {CallManager? manager})`; `enum IncomingTapAction { showCall, openChat }`; `CallManager.handleCallCancelled(Map<String, dynamic>)`, `CallManager.resolveIncomingTap(Map<String, dynamic>) → Future<IncomingTapAction>`, `CallManager.recoverCallState()`.

- [ ] **Step 1: Write the failing test**

Create `test/services/call_incoming_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_push_handler.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

Map<String, dynamic> _pushData({String type = 'incoming_call', String callId = 'call-1'}) => {
      'type': type,
      'callId': callId,
      'callUuid': kCallUuid,
      'callerId': 'u-caller',
      'callerName': 'Ada',
      'callType': 'audio',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foreground incoming_call push is handled (not dropped) and deduped with the socket', () async {
    final h = CallHarness();
    expect(await handleCallPush(_pushData(), manager: h.manager), isTrue);
    await h.manager.handleSocketEvent('call:incoming', CallHarness.incomingPayload());
    expect(h.opened, ['incoming:call-1']);
    expect(await handleCallPush({'type': 'chat_message'}, manager: h.manager), isFalse);
  });

  test('call_cancelled for the ringing call ends it and its CallKit UI', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await handleCallPush(_pushData(type: 'call_cancelled'), manager: h.manager);
    expect(h.finishes.single.reason, CallExitReason.remoteState);
    expect(h.platform.log, contains('endUi:$kCallUuid'));
  });

  test('call_cancelled that overtook the invite: CallKit ended, the late invite ignored', () async {
    final h = CallHarness();
    await handleCallPush(_pushData(type: 'call_cancelled', callId: 'call-9'), manager: h.manager);
    expect(h.platform.log, contains('endUi:$kCallUuid'));
    await handleCallPush(_pushData(callId: 'call-9'), manager: h.manager);
    expect(h.manager.currentCall, isNull);
    expect(h.opened, isEmpty);
  });

  test('call_cancelled does not end a call this device is already answering', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.acceptCall();
    await handleCallPush(_pushData(type: 'call_cancelled'), manager: h.manager);
    expect(h.finishes, isEmpty);
    expect(h.manager.currentCall!.status, CallStatus.connecting);
  });

  test('tapping an old incoming-call notification opens the chat when the call is over', () async {
    final h = CallHarness();
    h.api.getResult = const CallApiResult(ok: true, statusCode: 200, data: {'status': 'missed'});
    expect(await h.manager.resolveIncomingTap(_pushData()), IncomingTapAction.openChat);
    expect(h.manager.currentCall, isNull);
    expect(h.opened, isEmpty);
  });

  test('tapping a still-ringing notification shows the incoming screen', () async {
    final h = CallHarness();
    h.manager.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(await h.manager.resolveIncomingTap(_pushData()), IncomingTapAction.showCall);
    expect(h.opened, ['incoming:call-1']);
  });

  test('resume: a call ringing for me on the server shows the incoming UI', () async {
    final h = CallHarness();
    h.api.currentResult = const CallApiResult(ok: true, statusCode: 200, data: {
      'call': {
        'id': 'call-1', 'callUuid': kCallUuid, 'type': 'video', 'status': 'ringing', 'direction': 'in',
        'otherParty': {'id': 'u-caller', 'name': 'Ada', 'avatar': null}, 'roomName': 'call:call-1',
      },
    });
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.opened, ['incoming:call-1']);
  });

  test('resume: nothing live on the server ends a stale local ring', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.recoverCallState();
    expect(h.finishes.single.reason, CallExitReason.remoteState);
  });

  test('cold start / resume: an active call is rejoined with the fresh token', () async {
    final h = CallHarness();
    h.api.currentResult = const CallApiResult(ok: true, statusCode: 200, data: {
      'call': {
        'id': 'call-1', 'callUuid': kCallUuid, 'type': 'audio', 'status': 'active', 'direction': 'out',
        'otherParty': {'id': 'u2', 'name': 'Bo', 'avatar': null}, 'roomName': 'call:call-1',
      },
      'token': 'tok-rejoin', 'url': 'wss://lk.test',
    });
    await h.manager.recoverCallState();
    expect(h.liveKit.connects, 1);
    expect(h.opened, ['active:call-1']);
    expect(h.manager.currentCall!.direction, CallDirection.outgoing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/call_incoming_test.dart`
Expected: FAIL — `Error when reading 'lib/services/call/call_push_handler.dart'` / `resolveIncomingTap` not defined.

- [ ] **Step 3: Implement**

Create `lib/services/call/call_push_handler.dart`:

```dart
import 'package:bananatalk_app/services/call_manager.dart';

/// Foreground FCM for calls. Returns true when [data] was a call push and
/// has been handled — the caller must then show nothing else for it.
///
/// incoming_call used to be dropped in the foreground on the assumption that
/// the socket had it; after a socket replacement it often had not.
Future<bool> handleCallPush(Map<String, dynamic> data, {CallManager? manager}) async {
  final m = manager ?? CallManager();
  switch (data['type']?.toString().toLowerCase()) {
    case 'incoming_call':
      await m.handleIncoming(data, source: IncomingSource.push);
      return true;
    case 'call_cancelled':
      await m.handleCallCancelled(data);
      return true;
  }
  return false;
}
```

In `lib/services/call_manager.dart`:
- add `import 'package:bananatalk_app/services/call/callkit_ids.dart';`;
- add below the `InitiateStatus` enum: `enum IncomingTapAction { showCall, openChat }`;
- add the field `bool _recovering = false;` next to `_ringSafetyTimer`;
- replace `didChangeAppLifecycleState` with

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) unawaited(recoverCallState());
  }
```

- add after `_showIncoming`:

```dart
  /// call_cancelled (FCM data push, or relayed from a VoIP push): the call
  /// left ringing elsewhere (accepted / declined on another device, the
  /// caller cancelled, or it timed out).
  Future<void> handleCallCancelled(Map<String, dynamic> data) async {
    final callId = data['callId']?.toString() ?? '';
    final callUuid = data['callUuid']?.toString();
    final cur = currentCall;
    if (cur != null && (cur.callId == callId || CallKitIds.same(cur.callUuid, callUuid))) {
      if (cur.status == CallStatus.ringing) await _finish(CallExitReason.remoteState);
      return;
    }
    // Not our current call: it may still be ringing in CallKit, or its invite
    // may arrive late — end the UI and ignore a later invite for it.
    _remember(callId);
    await _quietly(() => _deps.platform.endCallUi(CallModel(
          callId: callId,
          callUuid: callUuid,
          userId: '',
          userName: '',
          callType: CallType.audio,
          direction: CallDirection.incoming,
          startTime: DateTime.now(),
        )));
  }

  /// A tapped incoming-call notification may be minutes old: only show the
  /// call if the server says it is still ringing; otherwise open the chat.
  Future<IncomingTapAction> resolveIncomingTap(Map<String, dynamic> data) async {
    final callId = data['callId']?.toString() ?? '';
    if (callId.isEmpty) return IncomingTapAction.openChat;
    final cur = currentCall;
    if (cur != null && cur.callId == callId) {
      if (cur.status == CallStatus.ringing) _showIncoming(cur);
      return IncomingTapAction.showCall;
    }
    final res = await _deps.api.get(callId);
    if (!res.ok || res.data['status']?.toString() != 'ringing') return IncomingTapAction.openChat;
    await handleIncoming(data, source: IncomingSource.notificationTap);
    return IncomingTapAction.showCall;
  }

  /// Resume and cold start: ask the server what is live for this user.
  /// Ringing for me → incoming UI; active and not here → rejoin; nothing →
  /// a call still ringing locally is stale and ends.
  Future<void> recoverCallState() async {
    if (_recovering) return;
    _recovering = true;
    try {
      final res = await _deps.api.current();
      if (!res.ok) return;
      final raw = res.data['call'];
      final cur = currentCall;
      if (raw is! Map) {
        if (cur != null && cur.direction == CallDirection.incoming && cur.status == CallStatus.ringing) {
          await _finish(CallExitReason.remoteState);
        }
        return;
      }
      final summary = Map<String, dynamic>.from(raw);
      final other = summary['otherParty'] is Map
          ? Map<String, dynamic>.from(summary['otherParty'] as Map)
          : const <String, dynamic>{};
      final status = summary['status']?.toString();
      if (status == 'ringing' && summary['direction'] == 'in') {
        await handleIncoming({
          'callId': summary['id'],
          'callUuid': summary['callUuid'],
          'caller': {'_id': other['id'], 'name': other['name'], 'profilePicture': other['avatar']},
          'callType': summary['type'],
          'roomName': summary['roomName'],
        }, source: IncomingSource.recovery);
        return;
      }
      if (status == 'active' && cur == null) await _rejoin(summary, other, res.data);
    } finally {
      _recovering = false;
    }
  }

  Future<void> _rejoin(Map<String, dynamic> summary, Map<String, dynamic> other, Map<String, dynamic> data) async {
    final token = data['token']?.toString();
    final url = data['url']?.toString();
    final callId = summary['id']?.toString() ?? '';
    if (token == null || url == null || callId.isEmpty) return;
    final type = summary['type'] == 'video' ? CallType.video : CallType.audio;
    currentCall = CallModel(
      callId: callId,
      callUuid: summary['callUuid']?.toString(),
      userId: other['id']?.toString() ?? '',
      userName: other['name']?.toString() ?? '',
      userProfilePicture: other['avatar']?.toString(),
      callType: type,
      direction: summary['direction'] == 'out' ? CallDirection.outgoing : CallDirection.incoming,
      status: CallStatus.connecting,
      startTime: DateTime.now(),
      livekitToken: token,
      livekitUrl: url,
      roomName: summary['roomName']?.toString(),
    );
    final media = _deps.liveKitFactory();
    _liveKit = media;
    _wireLiveKit(media);
    try {
      await media.connect(url: url, token: token, type: type);
    } catch (e) {
      debugPrint('📞 rejoin failed: $e');
      await _finish(CallExitReason.connectionLost);
      return;
    }
    if (currentCall?.callId != callId) return;
    _isVideoEnabled = type == CallType.video;
    _deps.openActiveCall(currentCall!);
  }
```

In `lib/services/notification_service.dart`:
- add `import 'package:bananatalk_app/services/call/call_push_handler.dart';`;
- in `firebaseMessagingBackgroundHandler`, insert before `if (type == 'incoming_call') {`:

```dart
  // The call left ringing elsewhere: take down the native call UI. Data-only
  // and capability-gated server-side, so live builds never receive it.
  if (type == 'call_cancelled') {
    final callUuid = message.data['callUuid']?.toString();
    if (callUuid != null && callUuid.isNotEmpty && CallKitService.isCallKitAllowed) {
      await CallKitService().endCall(callUuid);
    }
    return;
  }
```

  and in the same handler's `callKitService.showIncomingCall(` call add the argument `callUuid: message.data['callUuid']?.toString(),`;
- in `_handleForegroundMessage`, insert directly after the `_processedMessageIds` cleanup block:

```dart
    // Calls: incoming_call (deduped with the socket by callId) and
    // call_cancelled belong to CallManager and never become a banner.
    if (await handleCallPush(Map<String, dynamic>.from(message.data))) return;
```

  and delete the block

```dart
    // Incoming calls in foreground are handled by the socket → IncomingCallScreen.
    // Don't show a duplicate notification banner.
    if (notificationType == 'incoming_call') {
      return;
    }
```

In `lib/services/notification_router.dart` replace `_handleIncomingCallNotification` with:

```dart
  /// A tapped incoming-call notification. It may be stale: the server is
  /// asked first; a call that is no longer ringing opens the conversation.
  static Future<void> _handleIncomingCallNotification(Map<String, dynamic> data) async {
    final action = await CallManager().resolveIncomingTap(data);
    if (action == IncomingTapAction.openChat) {
      final callerId = data['callerId']?.toString();
      goRouter.go(callerId != null && callerId.isNotEmpty ? '/chat/$callerId' : '/home');
    }
  }
```

In `lib/main.dart` add `import 'dart:async';` and, in `_initializeCallManager`, directly after `callNotifier.callManager.initialize(chatSocketService);` add:

```dart
      // Cold start: a call may be ringing for us or still active.
      unawaited(callNotifier.callManager.recoverCallState());
```

In `docs/REMAINING_WORK.md` tick `  - [x] A6 incoming dedupe, foreground FCM, call_cancelled, stale taps, resume/cold-start recovery`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/call_incoming_test.dart test/services/call_manager_test.dart test/services/notification_permission_test.dart && flutter analyze lib`
Expected: all pass; no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/call/call_push_handler.dart lib/services/call_manager.dart lib/services/notification_service.dart lib/services/notification_router.dart lib/main.dart test/services/call_incoming_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(calls): incoming calls arrive by push too, and stale ones never ring

Foreground incoming_call pushes are handled instead of dropped (deduped
with the socket by callId). call_cancelled - foreground or background -
takes down the ringing UI, and a cancel that overtakes its invite makes the
late invite a no-op. A tapped incoming-call notification asks the server
first and opens the chat if the call is over. On resume and cold start
GET /calls/current shows a call ringing for us, rejoins an active one, or
ends a local ring the server no longer has.

Still open (calls app): A7-A14; native review of call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A7: CallKit `extra`, cold-start `activeCalls()`, push capabilities + real device id

**Files:**
- Modify: `lib/services/callkit_service.dart` (`showIncomingCall` 182-251, `_uploadVoipToken` 138-153; add `buildIncomingParams`, `activeCallEntries`)
- Modify: `lib/services/notification_api_client.dart` (`registerToken` 54-80, `registerVoipToken` 104-120)
- Modify: `lib/services/notification_service.dart` (background handler `showIncomingCall` call)
- Modify: `lib/services/call/call_platform.dart` (`activeCallUis`)
- Modify: `lib/services/call_manager.dart` (`_matches`; add `reconcileCallKitOnColdStart`)
- Modify: `lib/main.dart` (`_initializeCallManager`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/services/callkit_test.dart`

**Interfaces:**
- Consumes: `CallKitIds`, `CallKitEntry` (A3); `handleCallKitAccept` (A4).
- Produces: `static CallKitParams CallKitService.buildIncomingParams({required String callId, String? callUuid, required String callerName, String? callerAvatar, String? callerId, bool isVideo, String? livekitUrl, String? roomName})` with `extra = { callId, callUuid, callType, callerName, callerAvatar?, callerId?, livekitUrl?, roomName? }` (no LiveKit token); `Future<List<CallKitEntry>> CallKitService.activeCallEntries()`; `const kCallPushCapabilities = ['call_cancel']`; register-token and register-voip-token bodies carry `capabilities`; VoIP token registered with `NotificationService().getDeviceId()`; `CallManager.reconcileCallKitOnColdStart()`.

- [ ] **Step 1: Write the failing test**

Create `test/services/callkit_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/call/callkit_ids.dart';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CallKit id is the lowercase callUuid; extra carries ids and caller, never a token', () {
    final p = CallKitService.buildIncomingParams(
      callId: 'call-1',
      callUuid: kCallUuid.toUpperCase(),
      callerName: 'Ada',
      callerAvatar: 'https://cdn.test/a.jpg',
      callerId: 'u-caller',
      isVideo: true,
      livekitUrl: 'wss://lk.test',
      roomName: 'call:call-1',
    );
    expect(p.id, kCallUuid);
    expect(p.type, 1);
    expect(p.extra, {
      'callId': 'call-1',
      'callUuid': kCallUuid,
      'callType': 'video',
      'callerName': 'Ada',
      'callerAvatar': 'https://cdn.test/a.jpg',
      'callerId': 'u-caller',
      'livekitUrl': 'wss://lk.test',
      'roomName': 'call:call-1',
    });
  });

  test('Review focus 1: cold start finds an accepted CallKit call reported in UPPERCASE and joins it', () async {
    final h = CallHarness();
    h.platform.activeEntries = [
      CallKitEntry(uuid: kCallUuid.toUpperCase(), accepted: true, extra: {
        'callId': 'call-1', 'callUuid': kCallUuid, 'callerId': 'u-caller', 'callerName': 'Ada', 'callType': 'audio',
      }),
    ];
    await h.manager.reconcileCallKitOnColdStart();
    expect(h.api.calls, ['accept:call-1']);
    expect(h.opened, ['active:call-1']);
  });

  test('cold start ignores CallKit calls that were not accepted', () async {
    final h = CallHarness();
    h.platform.activeEntries = const [CallKitEntry(uuid: kCallUuid, accepted: false, extra: {'callId': 'call-1'})];
    await h.manager.reconcileCallKitOnColdStart();
    expect(h.api.calls, isEmpty);
  });

  test('a CallKit accept with an uppercase id matches the ringing call', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.handleCallKitAccept(kCallUuid.toUpperCase(), null);
    expect(h.api.calls, ['accept:call-1']);
  });

  group('token registration declares call_cancel and the real device id', () {
    late String originalBaseUrl;
    setUp(() {
      originalBaseUrl = Endpoints.baseURL;
      Endpoints.baseURL = 'http://api.test/api/v1/';
      SharedPreferences.setMockInitialValues({'token': 'jwt'});
    });
    tearDown(() => Endpoints.baseURL = originalBaseUrl);

    test('VoIP and FCM', () async {
      final bodies = <String, dynamic>{};
      await http.runWithClient(() async {
        final api = NotificationApiClient();
        await api.registerVoipToken('voip-tok', 'device-xyz');
        await api.registerToken('fcm-tok', 'android', 'device-xyz');
      }, () => MockClient((req) async {
        bodies[req.url.path.split('/').last] = jsonDecode(req.body);
        return http.Response(jsonEncode({'success': true}), 200);
      }));
      expect(bodies['register-voip-token'], {
        'voipToken': 'voip-tok', 'deviceId': 'device-xyz', 'capabilities': ['call_cancel'],
      });
      expect(bodies['register-token']['capabilities'], ['call_cancel']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/callkit_test.dart`
Expected: FAIL — `Member not found: 'CallKitService.buildIncomingParams'`, `reconcileCallKitOnColdStart` not defined.

- [ ] **Step 3: Implement**

In `lib/services/callkit_service.dart` replace `showIncomingCall` (whole method, as changed in A3) with:

```dart
  /// The native incoming-call params. Pure, so the id/extra contract with
  /// AppDelegate.swift and CallManager is unit-tested.
  static CallKitParams buildIncomingParams({
    required String callId,
    String? callUuid,
    required String callerName,
    String? callerAvatar,
    String? callerId,
    bool isVideo = false,
    String? livekitUrl,
    String? roomName,
  }) {
    final uuid = CallKitIds.uuidFor(callId: callId, callUuid: callUuid);
    final extra = <String, dynamic>{
      'callId': callId,
      'callUuid': uuid,
      'callType': isVideo ? 'video' : 'audio',
      'callerName': callerName,
      if (callerAvatar != null) 'callerAvatar': callerAvatar,
      if (callerId != null) 'callerId': callerId,
      if (livekitUrl != null) 'livekitUrl': livekitUrl,
      if (roomName != null) 'roomName': roomName,
    };
    return CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Bananatalk',
      avatar: callerAvatar,
      handle: callerName,
      type: isVideo ? 1 : 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
      ),
      duration: 45000,
      extra: extra,
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1a1a2e',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: null,
      ),
    );
  }

  /// Show the native incoming call UI. Returns the CallKit id (the callUuid).
  /// The LiveKit token is NOT carried: it comes from POST /calls/:id/accept.
  Future<String> showIncomingCall({
    required String callId,
    String? callUuid,
    required String callerName,
    String? callerAvatar,
    String? callerId,
    bool isVideo = false,
    String? livekitUrl,
    String? roomName,
  }) async {
    final params = buildIncomingParams(
      callId: callId,
      callUuid: callUuid,
      callerName: callerName,
      callerAvatar: callerAvatar,
      callerId: callerId,
      isVideo: isVideo,
      livekitUrl: livekitUrl,
      roomName: roomName,
    );
    _activeCallUuid = params.id;
    if (!isCallKitAllowed) {
      debugPrint('📱 CallKit disabled (China/iOS) — skipping native call UI');
      return params.id!;
    }
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    return params.id!;
  }

  /// Calls the native UI currently shows (iOS reports ids uppercase).
  Future<List<CallKitEntry>> activeCallEntries() async {
    final raw = await FlutterCallkitIncoming.activeCalls();
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(CallKitEntry.fromPlugin).toList();
  }
```

Replace `_uploadVoipToken`'s `await _api.registerVoipToken(token, userId);` with

```dart
      // The real device id (same one the FCM token uses) — call_cancelled
      // skips the device that accepted/declined by this id.
      final deviceId = await NotificationService().getDeviceId();
      await _api.registerVoipToken(token, deviceId);
```

and add `import 'package:bananatalk_app/services/notification_service.dart';`.

In `lib/services/notification_api_client.dart` add below the imports:

```dart
/// Push capabilities this build understands (see backend lib/pushCapabilities.js).
/// 'call_cancel': a data-only / VoIP call_cancelled push ends the ringing UI.
const List<String> kCallPushCapabilities = ['call_cancel'];
```

and add `'capabilities': kCallPushCapabilities,` to the JSON body of both `registerToken` (after `'deviceId': deviceId,`) and `registerVoipToken` (after `'deviceId': deviceId,`).

In `lib/services/notification_service.dart` (background handler) replace the `callKitService.showIncomingCall(` argument list with:

```dart
      await callKitService.showIncomingCall(
        callId: callId,
        callUuid: message.data['callUuid']?.toString(),
        callerName: callerName,
        callerAvatar: callerAvatar,
        callerId: message.data['callerId']?.toString(),
        isVideo: callType == 'video',
        livekitUrl: livekitUrl,
        roomName: roomName,
      );
```

and delete the now-unused `final livekitToken = message.data['livekitToken']?.toString();`.

In `lib/services/call/call_platform.dart` replace the body of `activeCallUis` with `=> CallKitService().activeCallEntries();` (i.e. `Future<List<CallKitEntry>> activeCallUis() => CallKitService().activeCallEntries();`).

In `lib/services/call_manager.dart` replace `_matches` with

```dart
  bool _matches(CallModel c, String id, Map<String, dynamic>? extra) =>
      id == c.callId ||
      CallKitIds.same(id, c.callUuid) ||
      extra?['callId']?.toString() == c.callId;
```

and add after `handleCallKitEnded`:

```dart
  /// Killed-state accept: CallKit / the Android call screen was answered
  /// before Flutter ran, so the accept event was never delivered. Join it.
  /// (A decline in that state is not observable here; the server's 45 s
  /// timeout closes it.)
  Future<void> reconcileCallKitOnColdStart() async {
    final entries = await _deps.platform.activeCallUis();
    for (final entry in entries) {
      if (!entry.accepted) continue;
      final cur = currentCall;
      if (cur != null && !CallKitIds.same(cur.callUuid, entry.uuid) && cur.callId != entry.callId) continue;
      await handleCallKitAccept(entry.uuid, entry.extra);
      return;
    }
  }
```

In `lib/main.dart` replace the A6 line `unawaited(callNotifier.callManager.recoverCallState());` with:

```dart
      // Cold start: join a call accepted from CallKit while we were killed,
      // then ask the server what is live.
      final manager = callNotifier.callManager;
      unawaited(manager.reconcileCallKitOnColdStart().then((_) => manager.recoverCallState()));
```

In `docs/REMAINING_WORK.md` tick `  - [x] A7 CallKit extra, cold-start activeCalls(), VoIP/FCM capabilities + real device id`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/callkit_test.dart test/services/call_incoming_test.dart test/services/call_manager_test.dart && flutter analyze lib`
Expected: all pass; no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/callkit_service.dart lib/services/notification_api_client.dart lib/services/notification_service.dart lib/services/call/call_platform.dart lib/services/call_manager.dart lib/main.dart test/services/callkit_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(calls): killed-state accept joins the call; pushes know what this build handles

CallKit / Android call UI carry {callId, callUuid, callType, caller,
livekitUrl, roomName} (no token - /accept mints it), so a killed-state
accept joins the right call with the right type and name instead of an
audio call with "Unknown". On cold start FlutterCallkitIncoming.activeCalls()
is checked and an accepted call is joined; ids compare case-insensitively.
FCM and VoIP token registration declare capabilities ['call_cancel'] and the
VoIP token is registered under the real device id (it was the user id).

Still open (calls app): A8-A14; killed-state decline is not observable
(server timeout closes it); native review of call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A8: iOS `AppDelegate` — VoIP id/extra, `call_cancelled`, 60 s cancelled-uuid memory; QA matrix

**Files:**
- Modify: `ios/Runner/AppDelegate.swift` (whole file, 134 lines)
- Create: `docs/qa/calls-matrix.md`
- Modify: `docs/REMAINING_WORK.md`
- Test: manual (rows `IOS-1`…`IOS-6` in `docs/qa/calls-matrix.md`) + `flutter build ios --no-codesign`

**Interfaces:**
- Consumes: VoIP payloads from B5 (`{ id: callUuid, callId, callUuid, nameCaller, handle, isVideo, callType, callerId, callerName, callerProfilePicture, livekitUrl, roomName, extra }` and `{ type: 'call_cancelled', id, callId, callUuid }`); `SwiftFlutterCallkitIncomingPlugin.showCallkitIncoming(_:fromPushKit:completion:)`, `.activeCalls()`.
- Produces: CallKit calls with `id = callUuid` and `extra = { callId, callUuid, callType, callerName, callerId?, callerAvatar?, livekitUrl?, roomName? }` (same contract as `CallKitService.buildIncomingParams`); a `call_cancelled` VoIP push ends the reported call, or is reported-and-ended when it overtook the invite, and its uuid is remembered for 60 s.

- [ ] **Step 1: Write the failing test**

Create `docs/qa/calls-matrix.md`:

```markdown
# Calls — device QA matrix

Spec: `docs/superpowers/specs/2026-10-08-calls-reliability-design.md` §7.
Plan: `docs/superpowers/plans/2026-10-08-calls-reliability.md`.
Backend must be on the calls-reliability build. Record: date, build, device/OS, tester, ✅/❌ + note.

Each core cell = caller rings the device under test; check (a) it rings within 3 s,
(b) accept connects both ways (audio both directions; video both tiles),
(c) hang-up from either side closes both screens, (d) the chat shows ONE call
bubble with the right label on both sides (§3), (e) nothing keeps ringing anywhere.

## 1. Core matrix

### iOS (latest)
| App state of callee | Type | Wi-Fi | Cellular |
|---|---|---|---|
| foreground | voice | | |
| foreground | video | | |
| background | voice | | |
| background | video | | |
| killed | voice | | |
| killed | video | | |
| after resume (bg ≥ 5 min, then open) | voice | | |
| after resume (bg ≥ 5 min, then open) | video | | |

### Android 13+
| App state of callee | Type | Wi-Fi | Cellular |
|---|---|---|---|
| foreground | voice | | |
| foreground | video | | |
| background | voice | | |
| background | video | | |
| killed | voice | | |
| killed | video | | |
| after resume (bg ≥ 5 min, then open) | voice | | |
| after resume (bg ≥ 5 min, then open) | video | | |

### Android 8
| App state of callee | Type | Wi-Fi | Cellular |
|---|---|---|---|
| foreground | voice | | |
| foreground | video | | |
| background | voice | | |
| background | video | | |
| killed | voice | | |
| killed | video | | |
| after resume (bg ≥ 5 min, then open) | voice | | |
| after resume (bg ≥ 5 min, then open) | video | | |

## 2. Scenarios

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| S-1 | Busy | A↔B in a call; C calls B | C sees "B was on another call" toast, never rings B; B gets one "Missed voice call" push; bubble in B–C chat: C "B was on another call", B "Missed voice call" | |
| S-2 | Decline | A calls B; B declines | A screen shows "Voice call declined" 1.5 s then closes; B screen closes; bubble A "Voice call declined", B "Declined voice call"; no missed push | |
| S-3 | Caller cancels while callee is killed | Kill B's app; A calls, B's CallKit/Android call UI rings; A hangs up after 10 s | B's native call UI disappears within 3 s; B gets "Missed voice call" push; bubble A "Cancelled voice call", B "Missed voice call" | |
| S-4 | No answer | A calls B; nobody answers | Ends at 45 s on both; A "Voice call · No answer" 1.5 s; B missed push; Calls-list badge on B = 1 | |
| S-5 | Two devices, one user | B signed in on phone + tablet; A calls; B answers on phone | Tablet stops ringing within 3 s (socket or call_cancelled); phone connects | |
| S-6 | Two devices, second accepts late | Same as S-5, then tap Accept on tablet within 1 s | Tablet dismisses silently (409), no error toast | |
| S-7 | Wi-Fi ↔ cellular mid-call | During a connected call toggle Wi-Fi off | "Reconnecting…" overlay ≤ 20 s, then audio resumes; if it can't, both screens close after 20 s and the bubble says Outgoing/Incoming · m:ss | |
| S-8 | Peer app killed mid-call | During a call force-quit A | B shows "Reconnecting…", call ends on B within ~20-40 s (webhook/sweeper); one bubble | |
| S-9 | Video: screen stays on | 3-min video call, no touches | Screen never dims/locks on either device | |
| S-10 | Video: camera paused | During video call A switches to another app 10 s, returns | B sees A's avatar tile with "Camera paused"; A's video returns on resume | |
| S-11 | Stale notification | Miss a call (S-4), wait 2 min, tap the incoming-call notification if still present | Opens the chat with A, does not ring | |
| S-12 | Live 2.6.1 build vs new backend | B on 2.6.1 (store), A on new build; run S-2, S-3, S-4 and a completed call both directions | 2.6.1 rings, connects, ends; its other devices stop ringing where supported; bubbles render from callData on 2.6.1 | |
| S-13 | Missed-call push | S-4 with B's app in background | One "📞 A / Missed voice call" push; tapping it opens the chat with A | |
| S-14 | Cold-start accept | Kill B; A calls; B accepts from the lock screen | App opens straight into the active call with the right name and type (video stays video) | |
| S-15 | Resume recovery | B backgrounded ≥ 5 min (socket dead); A calls; B opens the app from the icon while ringing | In-app incoming screen appears; accept works | |
| S-16 | Calls list | Open chat tab → phone icon | Badge cleared after opening; rows show arrows (missed red), type, time, duration; tap row → chat; call-back button rings the same type | |

## 3. iOS-only (AppDelegate VoIP)

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| IOS-1 | VoIP while app killed | Kill app; receive a call | CallKit rings (no crash — the 24-hex id crash is gone) | |
| IOS-2 | VoIP while app backgrounded/inactive | App in background; receive a call | CallKit rings; accept joins the call | |
| IOS-3 | Cancel while ringing (killed) | S-3 on iPhone | CallKit UI ends within 3 s | |
| IOS-4 | Cancel overtakes invite | Caller starts and cancels within ~1 s while iPhone is on poor network | No lingering ring; at most a sub-second CallKit flash; a late invite does not ring | |
| IOS-5 | Answered on another device | iPhone + iPad on the same account (both new build); answer on iPad | iPhone CallKit ends; no "Unknown" call appears | |
| IOS-6 | Foreground VoIP cancel | iPhone app open on the incoming screen; answer on the other device | In-app screen closes; any CallKit flash is ≤ 1 s | |
```

Then verify the current build fails the rows this task fixes: on the current store build run **IOS-3** — expected ❌ (CallKit keeps ringing until its 45 s timeout, since nothing dismisses it).

- [ ] **Step 2: Run test to verify it fails**

Run (manual, current `main` build on an iPhone): rows **IOS-1** (backgrounded/inactive variant) and **IOS-3**.
Expected: ❌ — IOS-1 crashes when the backend sends the old 24-hex id (live) and IOS-3 keeps ringing.

- [ ] **Step 3: Implement**

Replace `ios/Runner/AppDelegate.swift` with:

```swift
import UIKit
import CallKit
import AVFAudio
import PushKit
import Flutter
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

  /// callUuids whose call_cancelled arrived before (or without) the invite.
  /// Kept 60 s so a late invite is reported and ended at once, not rung.
  private var cancelledCallUuids: [String: Date] = [:]
  private let callController = CXCallController()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // VoIP push registration. iOS 13+ requires EVERY VoIP push to report a
    // call to CallKit before the handler completes, or the app loses its
    // VoIP entitlement — including call_cancelled pushes (see below).
    let voipRegistry = PKPushRegistry(queue: .main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  // MARK: - PKPushRegistryDelegate (VoIP)

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    NSLog("📞 VoIP push token: \(deviceToken)")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    NSLog("📞 VoIP push token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// Incoming VoIP push: an incoming call (`id` = callUuid, `extra.callId` =
  /// server id) or a `call_cancelled`. The CallKit id is always a valid,
  /// lowercase UUID — the plugin force-unwraps UUID(uuidString:).
  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let dict = payload.dictionaryPayload
    let extraIn = dict["extra"] as? [String: Any] ?? [:]
    let pushType = (dict["type"] as? String) ?? "incoming_call"
    let callUuid = AppDelegate.normalizedUuid(
      (dict["callUuid"] as? String) ?? (extraIn["callUuid"] as? String) ?? (dict["id"] as? String)
    )
    let callId = (extraIn["callId"] as? String) ?? (dict["callId"] as? String) ?? callUuid
    let callerName = (dict["nameCaller"] as? String)
      ?? (dict["callerName"] as? String)
      ?? (extraIn["callerName"] as? String)
      ?? "Unknown"
    let handle = (dict["handle"] as? String) ?? (dict["callerId"] as? String) ?? callerName
    let callType = (dict["callType"] as? String) ?? (extraIn["callType"] as? String) ?? "audio"
    let isVideo = (dict["isVideo"] as? Bool) ?? (callType == "video")

    let data = flutter_callkit_incoming.Data(
      id: callUuid,
      nameCaller: callerName,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    // Same contract as CallKitService.buildIncomingParams on the Dart side.
    var extra: [String: Any] = [
      "callId": callId,
      "callUuid": callUuid,
      "callType": callType,
      "callerName": callerName,
    ]
    for key in ["callerId", "livekitUrl", "roomName"] {
      if let value = (extraIn[key] as? String) ?? (dict[key] as? String) { extra[key] = value }
    }
    if let avatar = (extraIn["callerAvatar"] as? String) ?? (dict["callerProfilePicture"] as? String) {
      extra["callerAvatar"] = avatar
    }
    data.extra = extra as NSDictionary

    if pushType == "call_cancelled" {
      if isReported(callUuid) {
        endReportedCall(callUuid)
        completion()
      } else {
        // The cancel overtook the invite. PushKit still demands a report:
        // report it, end it at once, and remember it for a late invite.
        rememberCancelled(callUuid)
        reportAndEnd(data, callUuid: callUuid, completion: completion)
      }
      return
    }

    if wasRecentlyCancelled(callUuid) {
      reportAndEnd(data, callUuid: callUuid, completion: completion)
      return
    }

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .showCallkitIncoming(data, fromPushKit: true) {
        completion()
      }
  }

  // MARK: - call_cancelled helpers

  private static func normalizedUuid(_ raw: String?) -> String {
    if let raw = raw, UUID(uuidString: raw) != nil { return raw.lowercased() }
    return UUID().uuidString.lowercased()
  }

  private func isReported(_ callUuid: String) -> Bool {
    let calls = SwiftFlutterCallkitIncomingPlugin.sharedInstance?.activeCalls() ?? []
    return calls.contains { (($0["id"] as? String) ?? "").lowercased() == callUuid }
  }

  private func endReportedCall(_ callUuid: String) {
    guard let uuid = UUID(uuidString: callUuid) else { return }
    let transaction = CXTransaction(action: CXEndCallAction(call: uuid))
    callController.request(transaction) { error in
      if let error = error { NSLog("📞 ending cancelled call failed: \(error)") }
    }
  }

  private func reportAndEnd(
    _ data: flutter_callkit_incoming.Data,
    callUuid: String,
    completion: @escaping () -> Void
  ) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .showCallkitIncoming(data, fromPushKit: true) { [weak self] in
        self?.endReportedCall(callUuid)
        completion()
      }
  }

  private func rememberCancelled(_ callUuid: String) {
    pruneCancelled()
    cancelledCallUuids[callUuid] = Date()
  }

  private func wasRecentlyCancelled(_ callUuid: String) -> Bool {
    pruneCancelled()
    return cancelledCallUuids[callUuid] != nil
  }

  private func pruneCancelled() {
    let cutoff = Date().addingTimeInterval(-60)
    cancelledCallUuids = cancelledCallUuids.filter { $0.value > cutoff }
  }
}
```

In `docs/REMAINING_WORK.md` tick `  - [x] A8 AppDelegate VoIP cancel handling + \`docs/qa/calls-matrix.md\`` and change the §0b line `- [ ] Device QA \`docs/qa/calls-matrix.md\`; …` to `- [ ] Device QA: run every row of \`docs/qa/calls-matrix.md\`; re-measure answered rate one week after release (target ≥ 40%).`

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter build ios --no-codesign --debug` (compiles the Swift), then on a device with the backend from Phase 1: rows **IOS-1 … IOS-6** and **S-3**, **S-5**, **S-14** in `docs/qa/calls-matrix.md`.
Expected: build succeeds; every listed row ✅ (record results in the file).

- [ ] **Step 5: Commit**

```bash
git add ios/Runner/AppDelegate.swift docs/qa/calls-matrix.md docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(ios): VoIP calls keyed by callUuid; call_cancelled ends the ringing call

The CallKit id is always a valid lowercase UUID (callUuid) and extra
carries callId, callUuid, type, caller and LiveKit url/room - the same
contract as CallKitService on the Dart side. A call_cancelled VoIP push
(sent only to builds that declared call_cancel) ends the reported call;
if it overtook the invite it is reported and ended at once, as PushKit
requires, and its uuid is remembered for 60 s so a late invite never rings.
docs/qa/calls-matrix.md holds the full device matrix from spec §7.

Still open (calls app): A9-A14; run the QA matrix; native review of call
strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---
### Task A9: `IncomingCallScreen` closes on a terminal state and after 50 s

**Files:**
- Modify: `lib/screens/incoming_call_screen.dart` (state class from A4)
- Modify: `lib/services/call_manager.dart` (add `expireIncoming`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/screens/incoming_call_screen_test.dart`

**Interfaces:**
- Consumes: `CallManager.finishes`, `_finish` (A4); `CallRoutes` (A3).
- Produces: `IncomingCallScreen.safetyNet = Duration(seconds: 50)`; `CallManager.expireIncoming(String callId) → Future<bool>` (true when it ended a still-ringing current call).

- [ ] **Step 1: Write the failing test**

Create `test/screens/incoming_call_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  late GlobalKey<NavigatorState> navKey;
  late CallHarness h;

  Future<void> pumpApp(WidgetTester tester) async {
    navKey = GlobalKey<NavigatorState>();
    h = CallHarness(
      closeCallScreens: () => navKey.currentState?.popUntil((r) => !CallRoutes.isCallRoute(r.settings.name)),
      openIncoming: (c) => navKey.currentState?.push(CallRoutes.incomingRoute(c)),
    );
    CallManager.debugSetInstance(h.manager);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('home')),
    ));
  }

  testWidgets('closes when call:state reports the call ended elsewhere', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsOneWidget);
    await h.state('missed', outcome: 'cancelled');
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('safety net: closes itself after 50 s if nothing ended it', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 49));
    expect(find.byType(IncomingCallScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(h.finishes.single.outcome, CallOutcome.noAnswer);
  });

  testWidgets('a screen for a call CallManager no longer has still removes itself at 50 s', (tester) async {
    await pumpApp(tester);
    final orphan = CallModel(
      callId: 'old', userId: 'u', userName: 'Ada', callType: CallType.audio,
      direction: CallDirection.incoming, startTime: DateTime.now(),
    );
    navKey.currentState!.push(CallRoutes.incomingRoute(orphan));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 51));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsNothing);
  });

  testWidgets('Decline declines on the server and closes', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(h.api.calls, contains('decline:call-1'));
    expect(find.byType(IncomingCallScreen), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/incoming_call_screen_test.dart`
Expected: FAIL — the 50 s tests time out with the screen still present (`Expected: no matching nodes … Actual: found one`); the first and last tests pass already.

- [ ] **Step 3: Implement**

In `lib/services/call_manager.dart` add after `resolveIncomingTap`:

```dart
  /// IncomingCallScreen's 50 s safety net: the server ends a ringing call at
  /// 45 s, so a call still ringing here at 50 s lost its call:state.
  Future<bool> expireIncoming(String callId) async {
    final cur = currentCall;
    if (cur == null || cur.callId != callId || cur.status != CallStatus.ringing) return false;
    await _finish(CallExitReason.remoteState, outcome: CallOutcome.noAnswer);
    return true;
  }
```

In `lib/screens/incoming_call_screen.dart` add `import 'dart:async';`, add to `IncomingCallScreen`:

```dart
  /// The server times a ring out at 45 s; this screen never outlives 50 s.
  static const Duration safetyNet = Duration(seconds: 50);
```

and replace the beginning of `_IncomingCallScreenState` (the `_busy` field) with:

```dart
class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _busy = false;
  Timer? _safetyNet;
  StreamSubscription<CallFinish>? _finishSub;

  @override
  void initState() {
    super.initState();
    _safetyNet = Timer(IncomingCallScreen.safetyNet, _expire);
    // CallManager closes call routes itself; this also covers a screen that
    // was opened for a call CallManager is not tracking.
    _finishSub = CallManager().finishes.listen((finish) {
      if (finish.call.callId == widget.call.callId) _closeSelf();
    });
  }

  @override
  void dispose() {
    _safetyNet?.cancel();
    _finishSub?.cancel();
    super.dispose();
  }

  Future<void> _expire() async {
    final ended = await CallManager().expireIncoming(widget.call.callId);
    if (!ended) _closeSelf();
  }

  void _closeSelf() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && route.isActive) Navigator.of(context).removeRoute(route);
  }
```

(`_accept` and `build` stay as written in A4.)

In `docs/REMAINING_WORK.md` tick `  - [x] A9 IncomingCallScreen closes on terminal state / after 50 s`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/screens/incoming_call_screen_test.dart test/services/call_manager_test.dart`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/incoming_call_screen.dart lib/services/call_manager.dart test/screens/incoming_call_screen_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(calls): the incoming-call screen never outlives its call

It closes on any terminal call:state for its callId (CallManager's single
exit path), removes itself if CallManager no longer tracks its call, and
gives up after 50 s even if every signal was lost (the server times out at
45 s).

Still open (calls app): A10-A14; run the QA matrix; native review of call
strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A10: 20 s reconnect grace, quality-callback chain, caller outcome banner

**Files:**
- Modify: `lib/services/call_manager.dart` (`_onPeerConnected`, `_onPeerDisconnected`, `_onLocalReconnecting`, `_onLocalReconnected`, `_onQuality`, `_finish`; new `kReconnectGrace`, `_reconnectTimer`, `onRawQualityChanged`)
- Modify: `lib/screens/active_call_screen.dart` (lines 1-16, 44-50, 120-160, 200-245, 515-560, 630-645)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/services/call_reconnect_test.dart`, `test/screens/active_call_screen_test.dart`

**Interfaces:**
- Consumes: A4 manager; `CallLabels` (A2).
- Produces: `const Duration kReconnectGrace = Duration(seconds: 20)`; `CallManager.onRawQualityChanged: void Function(lk.ConnectionQuality)?` (fired before the mapped `onCallQualityChanged` — the screen chains on it instead of overwriting `liveKit.onConnectionQualityChanged`); peer gone or local reconnecting for 20 s → `POST /end` (best effort) + `_finish(connectionLost)`.

- [ ] **Step 1: Write the failing test**

Create `test/services/call_reconnect_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

CallHarness _connected(FakeAsync async) {
  final h = CallHarness();
  h.startOutgoing();
  async.flushMicrotasks();
  h.state('active');
  async.flushMicrotasks();
  h.liveKit.onPeerConnected!();
  async.flushMicrotasks();
  return h;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('peer gone for 20 s → POST /end and one finish (connectionLost)', () {
    fakeAsync((async) {
      final h = _connected(async);
      h.liveKit.onPeerDisconnected!();
      async.elapse(const Duration(seconds: 19));
      expect(h.finishes, isEmpty);
      expect(h.manager.connectionState, CallUiState.reconnecting);
      async.elapse(const Duration(seconds: 2));
      expect(h.finishes.single.reason, CallExitReason.connectionLost);
      expect(h.api.calls.where((c) => c == 'end:call-1'), hasLength(1));
    });
  });

  test('local network back within 20 s keeps the call', () {
    fakeAsync((async) {
      final h = _connected(async);
      h.liveKit.onReconnecting!();
      async.elapse(const Duration(seconds: 10));
      h.liveKit.onReconnected!();
      async.elapse(const Duration(seconds: 30));
      expect(h.finishes, isEmpty);
      expect(h.manager.connectionState, CallUiState.connected);
    });
  });

  test('peer rejoins within 20 s keeps the call', () {
    fakeAsync((async) {
      final h = _connected(async);
      h.liveKit.onPeerDisconnected!();
      async.elapse(const Duration(seconds: 15));
      h.liveKit.onPeerConnected!();
      async.elapse(const Duration(seconds: 30));
      expect(h.finishes, isEmpty);
    });
  });

  test('quality: the raw callback is chained, the mapped one still fires', () {
    fakeAsync((async) {
      final h = _connected(async);
      final raw = <lk.ConnectionQuality>[];
      final mapped = <CallQuality>[];
      h.manager.onRawQualityChanged = raw.add;
      h.manager.onCallQualityChanged = mapped.add;
      h.liveKit.onConnectionQualityChanged!(lk.ConnectionQuality.poor);
      expect(raw, [lk.ConnectionQuality.poor]);
      expect(mapped, [CallQuality.poor]);
      expect(h.manager.connectionState, CallUiState.poorConnection);
    });
  });
}
```

Create `test/screens/active_call_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  testWidgets('shows the reconnect overlay, then the caller outcome banner', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActiveCallScreen(call: h.manager.currentCall!),
      ),
    ));
    await tester.pump();

    h.liveKit.onReconnecting!();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reconnecting...'), findsWidgets);

    await h.state('missed', outcome: 'no_answer');
    await tester.pump();
    expect(find.text('Voice call · No answer'), findsWidgets);

    // Let CallManager's 1.5 s close timer run so no timer is left pending.
    await tester.pump(const Duration(seconds: 2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/call_reconnect_test.dart test/screens/active_call_screen_test.dart`
Expected: FAIL — `onRawQualityChanged` not defined; the 20 s test sees no finish; the screen test finds `Reconnecting…` (hard-coded ellipsis) instead of the l10n string and no outcome banner.

- [ ] **Step 3: Implement**

In `lib/services/call_manager.dart`:
- below `kRingSafetyTimeout` add:

```dart
/// Peer gone or our network down this long → the call is over (spec §5.5).
const Duration kReconnectGrace = Duration(seconds: 20);
```

- add fields next to `_ringSafetyTimer`: `Timer? _reconnectTimer;` and next to the callbacks `void Function(lk.ConnectionQuality)? onRawQualityChanged;`
- add after `_updateConnectionState`:

```dart
  void _beginReconnectGrace() {
    if (_reconnectTimer?.isActive ?? false) return;
    final callId = currentCall?.callId;
    _reconnectTimer = Timer(kReconnectGrace, () {
      final c = currentCall;
      if (c == null || c.callId != callId) return;
      if (c.callId.isNotEmpty) unawaited(_deps.api.end(c.callId)); // best effort; 409 ignored
      unawaited(_finish(CallExitReason.connectionLost));
    });
  }

  void _cancelReconnectGrace() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
```

- in `_onPeerConnected` insert `_cancelReconnectGrace();` right after `if (c == null) return;`;
- in `_onPeerDisconnected` and `_onLocalReconnecting` insert `_beginReconnectGrace();` right after their `if (currentCall == null) return;`;
- in `_onLocalReconnected` insert `_cancelReconnectGrace();` right after `if (currentCall == null) return;`;
- make the first statement of `_onQuality`: `onRawQualityChanged?.call(quality);`;
- in `_finish`, after `_ringSafetyTimer?.cancel();` add `_cancelReconnectGrace();`.

In `lib/screens/active_call_screen.dart`:
- imports: change the call_manager import to `show CallManager, CallUiState, CallQuality, CallFinish, CallExitReason;` and add `import 'package:bananatalk_app/models/call_outcome.dart';`;
- delete the `_reconnectGraceSeconds` doc comment and constant (lines 13-15) and the field `Timer? _reconnectGraceTimer;` (and `_reconnectGraceTimer?.cancel();` in `dispose`);
- add fields `StreamSubscription<CallFinish>? _finishSub;` and `String? _outcomeBanner;`;
- at the end of `initState` (after the post-frame callback registration) add:

```dart
    // Caller side: show the §3 outcome ("No answer", "Declined") for the
    // 1.5 s CallManager keeps this screen up before closing it.
    _finishSub = CallManager().finishes.listen((finish) {
      if (!mounted || finish.call.callId != widget.call.callId) return;
      final outcome = finish.outcome;
      if (finish.reason != CallExitReason.remoteState ||
          finish.call.direction != CallDirection.outgoing ||
          outcome == null ||
          outcome == CallOutcome.completed) {
        return;
      }
      setState(() {
        _outcomeBanner = CallLabels.label(
          AppLocalizations.of(context)!,
          outcome: outcome,
          viewerIsCaller: true,
          isVideo: finish.call.callType == CallType.video,
          duration: finish.call.duration ?? 0,
          otherName: finish.call.userName,
        );
      });
    });
```

  and in `dispose` add `_finishSub?.cancel();`;
- in `setConnectionStateCallback`, replace `setState(() => _connState = state);` with

```dart
        setState(() {
          _connState = state;
          _isReconnecting = state == CallUiState.reconnecting;
        });
```

- replace `callManager.liveKit.onConnectionQualityChanged = (q) {` with `callManager.onRawQualityChanged = (q) {` (chained by CallManager instead of overwriting its handler), and in `dispose` replace `callManager.liveKit.onConnectionQualityChanged = null;` with `callManager.onRawQualityChanged = null;`;
- replace `_showReconnectBanner` and `_hideReconnectBanner` with:

```dart
  /// The banner only reflects state; CallManager owns the 20 s grace and
  /// ends the call (POST /end) if the connection does not come back.
  void _showReconnectBanner() => _reconnectAnimController.forward();

  void _hideReconnectBanner() => _reconnectAnimController.reverse();
```

- in the reconnect banner replace the `Text('Reconnecting…', …` string with `AppLocalizations.of(context)!.callReconnecting` (keep the style);
- in `_buildCallStatus` insert as the first statement:

```dart
    if (_outcomeBanner != null) {
      return Text(
        _outcomeBanner!,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      );
    }
```

  and replace the `const Text('Reconnecting...', …)` return with

```dart
      return Text(
        l10n.callReconnecting,
        style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
      );
```

- add `import 'dart:async';` if not present (it is, line 1).

In `docs/REMAINING_WORK.md` tick `  - [x] A10 20 s reconnect overlay + quality callback chain + outcome banner` and add to the QA note: rows S-7 and S-8.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/call_reconnect_test.dart test/screens/active_call_screen_test.dart test/services/call_manager_test.dart && flutter analyze lib/screens lib/services`
Expected: all pass; no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/call_manager.dart lib/screens/active_call_screen.dart test/services/call_reconnect_test.dart test/screens/active_call_screen_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(calls): 20 s reconnect grace, chained quality callback, outcome banner

A peer that drops or a local network that goes down shows "Reconnecting..."
for up to 20 s while LiveKit reconnects; after that the call ends through
POST /end and the single exit path instead of freezing the screen. The
screen no longer overwrites LiveKit's quality handler (which silently broke
the poor-connection state); it chains on onRawQualityChanged. Callers see
the §3 outcome ("Voice call · No answer", "Voice call declined") for 1.5 s.

Still open (calls app): A11-A14; run the QA matrix; native review of call
strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A11: Video basics — wakelock, camera paused in background

**Files:**
- Modify: `pubspec.yaml` (dependencies)
- Modify: `lib/services/call/call_platform.dart` (interface + `DeviceCallPlatform`)
- Modify: `lib/services/call_manager.dart` (`didChangeAppLifecycleState`, `initiateCall`, `acceptCall`, `_rejoin`, `_finish`; new `_onMediaConnected`, `_cameraPausedByLifecycle`)
- Modify: `lib/screens/active_call_screen.dart` (avatar column ~298-303)
- Modify: `test/helpers/call_fakes.dart` (`FakeCallPlatform`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/services/call_video_test.dart`

**Interfaces:**
- Consumes: A4/A6 manager.
- Produces: `CallPlatform.setWakelock(bool on)`; `CallManager._onMediaConnected(CallModel)` (single place for "media is up" side effects — A12 extends it); lifecycle `paused`/`hidden` during a non-ringing video call with the camera on → `setCameraEnabled(false)` + `call:video-toggle {isVideoEnabled:false}`; `resumed` → re-enable + `true`.

- [ ] **Step 1: Write the failing test**

In `test/helpers/call_fakes.dart` add to `FakeCallPlatform`:

```dart
  @override
  Future<void> setWakelock(bool on) async => log.add('wakelock:${on ? 'on' : 'off'}');
```

Create `test/services/call_video_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/call_model.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('video call keeps the screen on until it ends', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    expect(h.platform.log, contains('wakelock:on'));
    await h.manager.endCall();
    expect(h.platform.log, contains('wakelock:off'));
  });

  test('voice call never takes the wakelock', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.audio);
    await h.manager.endCall();
    expect(h.platform.log, isNot(contains('wakelock:on')));
  });

  test('leaving the app mid-video pauses the camera; coming back resumes it', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    await h.state('active');
    h.liveKit.onPeerConnected!();
    h.manager.didChangeAppLifecycleState(AppLifecycleState.inactive); // CallKit banner etc.
    expect(h.liveKit.cameraCalls, isEmpty);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(h.liveKit.cameraCalls, [false]);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(h.liveKit.cameraCalls, [false, true]);
  });

  test('a camera the user turned off stays off after resume', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    await h.state('active');
    h.manager.setVideoEnabled(false);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.paused);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(h.liveKit.cameraCalls, [false]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/call_video_test.dart`
Expected: FAIL — compile error `'FakeCallPlatform.setWakelock' isn't a valid override` (no such member in `CallPlatform`).

- [ ] **Step 3: Implement**

Add to `pubspec.yaml` dependencies (after `livekit_client`): `  wakelock_plus: ^1.3.3` and run `flutter pub get`.

In `lib/services/call/call_platform.dart` add `import 'package:wakelock_plus/wakelock_plus.dart';`, add to `CallPlatform`:

```dart
  /// Keep the screen on (video calls only; voice uses the proximity default).
  Future<void> setWakelock(bool on);
```

and to `DeviceCallPlatform`:

```dart
  @override
  Future<void> setWakelock(bool on) async {
    try {
      if (on) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('📞 wakelock failed: $e');
    }
  }
```

In `lib/services/call_manager.dart`:
- add the field `bool _cameraPausedByLifecycle = false;`;
- add after `_cancelReconnectGrace`:

```dart
  /// Media is up for [call] (outgoing connected, incoming accepted, rejoin).
  void _onMediaConnected(CallModel call) {
    if (call.callType == CallType.video) unawaited(_deps.platform.setWakelock(true));
  }
```

- call it: in `initiateCall` right after `_isVideoEnabled = video;` add `_onMediaConnected(currentCall!);`; in `acceptCall` right after `_isVideoEnabled = video;` add `_onMediaConnected(currentCall!);`; in `_rejoin` right after `_isVideoEnabled = type == CallType.video;` add `_onMediaConnected(currentCall!);`;
- in `_finish` add `_quietly(() => _deps.platform.setWakelock(false)),` to the `Future.wait` list and `_cameraPausedByLifecycle = false;` to `_resetMediaState`;
- replace `didChangeAppLifecycleState` with:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    final c = currentCall;
    final inVideoCall = c != null && c.callType == CallType.video && c.status != CallStatus.ringing;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // Backgrounded mid-video: iOS stops the camera anyway; unpublish it so
      // the peer sees a "Camera paused" tile instead of a frozen frame.
      if (inVideoCall && _isVideoEnabled && !_cameraPausedByLifecycle) {
        _cameraPausedByLifecycle = true;
        unawaited(_liveKit.setCameraEnabled(false));
        _emitToPeer('call:video-toggle', {'isVideoEnabled': false});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraPausedByLifecycle) {
        _cameraPausedByLifecycle = false;
        if (currentCall != null && _isVideoEnabled) {
          unawaited(_liveKit.setCameraEnabled(true));
          _emitToPeer('call:video-toggle', {'isVideoEnabled': true});
        }
      }
      unawaited(recoverCallState());
    }
  }
```

In `lib/screens/active_call_screen.dart`, in the avatar column shown when remote video is unavailable, replace

```dart
                      const SizedBox(height: 15),
                      _buildCallStatus(l10n),
                    ],
```

(the first occurrence, ~line 299) with

```dart
                      const SizedBox(height: 15),
                      _buildCallStatus(l10n),
                      if (isVideoCall && !_isPeerVideoEnabled && _connectedTime != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(l10n.callCameraPaused,
                                style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ],
```

In `docs/REMAINING_WORK.md` tick `  - [x] A11 video wakelock + camera paused in background`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/call_video_test.dart test/services/call_manager_test.dart test/services/call_incoming_test.dart && flutter analyze lib`
Expected: all pass (QA rows S-9, S-10 are verified on device in A8's matrix).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/call/call_platform.dart lib/services/call_manager.dart lib/screens/active_call_screen.dart test/helpers/call_fakes.dart test/services/call_video_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(calls): video calls keep the screen on; backgrounding pauses the camera

Video calls hold a wakelock from connect until _finish (voice calls keep
the normal proximity behaviour). Leaving the app mid-video unpublishes the
camera and tells the peer, who sees an avatar tile with "Camera paused";
resuming republishes it unless the user had turned it off.

Still open (calls app): A12-A14; run the QA matrix; native review of call
strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---
### Task A12: Android — microphone/camera foreground service, full-screen-intent request

**Files:**
- Modify: `pubspec.yaml` (dependencies)
- Modify: `android/app/src/main/AndroidManifest.xml` (permissions after line 48; `<service>` inside `<application>` after line 191)
- Create: `lib/services/call/call_foreground_service.dart`
- Create: `lib/services/call/full_screen_intent_prompt.dart`
- Modify: `lib/services/call/call_platform.dart` (interface + `DeviceCallPlatform`)
- Modify: `lib/services/call_manager.dart` (`CallManagerDeps`, `_onMediaConnected`, `_finish`)
- Modify: `test/helpers/call_fakes.dart`
- Modify: `docs/qa/calls-matrix.md`, `docs/REMAINING_WORK.md`
- Test: `test/services/call_android_test.dart` + manual rows `AND-1`…`AND-4`

**Interfaces:**
- Consumes: A1 strings (`callForegroundTitle/Body`, `callFullScreenIntentTitle/Body`), existing `notNow`, `openSettings`; `FlutterCallkitIncoming.canUseFullScreenIntent()/requestFullIntentPermission()`.
- Produces: `CallPlatform.startCallService({required bool video})`, `CallPlatform.stopCallService()`; `CallForegroundService.start({required bool video, required String title, required String text})`, `.stop()`; `FullScreenIntentPrompt.shouldAsk({required bool isAndroid, required bool canUse, required bool alreadyAsked})`, `.alreadyAsked()`, `.markAsked()`, `.maybeAsk(BuildContext)`; `CallManagerDeps.afterIncomingCall: void Function()` (default no-op; production asks once for the full-screen-intent permission after the first incoming call ends).

- [ ] **Step 1: Write the failing test**

In `test/helpers/call_fakes.dart`:
- add to `FakeCallPlatform`:

```dart
  @override
  Future<void> startCallService({required bool video}) async =>
      log.add('service:start:${video ? 'video' : 'audio'}');
  @override
  Future<void> stopCallService() async => log.add('service:stop');
```

- add `int afterIncomingCalls = 0;` to `CallHarness` and pass `afterIncomingCall: () => afterIncomingCalls++,` in its `CallManagerDeps(...)`.

Create `test/services/call_android_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/full_screen_intent_prompt.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('full-screen intent: ask only on Android, only when missing, only once', () {
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: true, canUse: false, alreadyAsked: false), isTrue);
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: true, canUse: true, alreadyAsked: false), isFalse);
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: true, canUse: false, alreadyAsked: true), isFalse);
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: false, canUse: false, alreadyAsked: false), isFalse);
  });

  test('the "asked" flag persists', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await FullScreenIntentPrompt.alreadyAsked(), isFalse);
    await FullScreenIntentPrompt.markAsked();
    expect(await FullScreenIntentPrompt.alreadyAsked(), isTrue);
  });

  test('foreground service runs from media-up to _finish', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    expect(h.platform.log, contains('service:start:video'));
    await h.manager.endCall();
    expect(h.platform.log, contains('service:stop'));
  });

  test('the full-screen-intent prompt hook runs after incoming calls only', () async {
    final h = CallHarness();
    await h.startOutgoing();
    await h.manager.endCall();
    expect(h.afterIncomingCalls, 0);
    await h.ringIncoming();
    await h.manager.rejectCall();
    expect(h.afterIncomingCalls, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/call_android_test.dart`
Expected: FAIL — `Error when reading 'lib/services/call/full_screen_intent_prompt.dart'` and `'startCallService' isn't a valid override`.

- [ ] **Step 3: Implement**

Add to `pubspec.yaml` dependencies (after `wakelock_plus`): `  flutter_foreground_task: ^9.1.0` and run `flutter pub get`.

In `android/app/src/main/AndroidManifest.xml` add after `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />` (line 48):

```xml
    <!-- Android 14+: a call keeps the mic (and camera for video) alive in the
         background only inside a typed foreground service. -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" />
```

and inside `<application>` after the geolocator `<service … tools:remove="android:foregroundServiceType" />` element (line ~191):

```xml
        <!-- flutter_foreground_task: ongoing-call service (lib/services/call/call_foreground_service.dart). -->
        <service
            android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
            android:foregroundServiceType="microphone|camera"
            android:exported="false" />
```

Create `lib/services/call/call_foreground_service.dart`:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point the plugin runs in its service isolate. The service exists
/// only to keep the process (and LiveKit's mic/camera) alive; it does no work.
@pragma('vm:entry-point')
void callForegroundTaskStart() {
  FlutterForegroundTask.setTaskHandler(_CallTaskHandler());
}

class _CallTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Android foreground service for the duration of a call: type microphone,
/// plus camera for video. LiveKit provides none, so without it Android stops
/// capturing a few seconds after the app leaves the foreground.
class CallForegroundService {
  const CallForegroundService._();

  static const int _serviceId = 4711;
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'bananatalk_ongoing_call',
        channelName: 'Ongoing call',
        channelDescription: 'Keeps your call running while BananaTalk is in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: false,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start({required bool video, required String title, required String text}) async {
    if (!Platform.isAndroid) return;
    _init();
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(notificationTitle: title, notificationText: text);
        return;
      }
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: title,
        notificationText: text,
        serviceTypes: [
          ForegroundServiceTypes.microphone,
          if (video) ForegroundServiceTypes.camera,
        ],
        callback: callForegroundTaskStart,
      );
    } catch (e) {
      debugPrint('📞 call foreground service failed to start: $e');
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('📞 call foreground service failed to stop: $e');
    }
  }
}
```

Create `lib/services/call/full_screen_intent_prompt.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Android 14+ revokes USE_FULL_SCREEN_INTENT by default for most apps, so
/// incoming calls on a locked phone show as a small notification. Ask once,
/// with an explainer, after the user's first incoming call has ended (never
/// on top of a ringing screen).
class FullScreenIntentPrompt {
  const FullScreenIntentPrompt._();

  static const String prefsKey = 'call_fsi_prompted';

  static bool shouldAsk({required bool isAndroid, required bool canUse, required bool alreadyAsked}) =>
      isAndroid && !canUse && !alreadyAsked;

  static Future<bool> alreadyAsked() async =>
      (await SharedPreferences.getInstance()).getBool(prefsKey) ?? false;

  static Future<void> markAsked() async =>
      (await SharedPreferences.getInstance()).setBool(prefsKey, true);

  static Future<void> maybeAsk(BuildContext context) async {
    if (!Platform.isAndroid) return;
    bool canUse = true;
    try {
      canUse = (await FlutterCallkitIncoming.canUseFullScreenIntent()) == true;
    } catch (e) {
      debugPrint('📞 canUseFullScreenIntent failed: $e');
    }
    if (!shouldAsk(isAndroid: true, canUse: canUse, alreadyAsked: await alreadyAsked())) return;
    await markAsked();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.callFullScreenIntentTitle),
        content: Text(l10n.callFullScreenIntentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.notNow)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.openSettings)),
        ],
      ),
    );
    if (allow == true) await FlutterCallkitIncoming.requestFullIntentPermission();
  }
}
```

In `lib/services/call/call_platform.dart` add imports `package:bananatalk_app/l10n/app_localizations.dart`, `package:bananatalk_app/router/app_router.dart` and `package:bananatalk_app/services/call/call_foreground_service.dart`; add to `CallPlatform`:

```dart
  /// Android ongoing-call foreground service (no-op elsewhere).
  Future<void> startCallService({required bool video});
  Future<void> stopCallService();
```

and to `DeviceCallPlatform`:

```dart
  @override
  Future<void> startCallService({required bool video}) {
    final ctx = callOverlayNavigatorKey.currentContext;
    final l10n = ctx != null ? AppLocalizations.of(ctx) : null;
    return CallForegroundService.start(
      video: video,
      title: l10n?.callForegroundTitle ?? 'Call in progress',
      text: l10n?.callForegroundBody ?? 'Tap to return to your call',
    );
  }

  @override
  Future<void> stopCallService() => CallForegroundService.stop();
```

In `lib/services/call_manager.dart`:
- add imports `package:bananatalk_app/router/app_router.dart` and `package:bananatalk_app/services/call/full_screen_intent_prompt.dart`;
- in `CallManagerDeps` add the constructor parameter `this.afterIncomingCall = CallManagerDeps._noop,`, the field `final void Function() afterIncomingCall;`, `static void _noop() {}`, and in `CallManagerDeps.production()` pass

```dart
        afterIncomingCall: () => Future<void>.delayed(const Duration(milliseconds: 600), () {
          final ctx = callOverlayNavigatorKey.currentContext;
          if (ctx != null && ctx.mounted) unawaited(FullScreenIntentPrompt.maybeAsk(ctx));
        }),
```

- extend `_onMediaConnected`:

```dart
  void _onMediaConnected(CallModel call) {
    final video = call.callType == CallType.video;
    if (video) unawaited(_deps.platform.setWakelock(true));
    unawaited(_deps.platform.startCallService(video: video));
  }
```

- in `_finish` add `_quietly(_deps.platform.stopCallService),` to the `Future.wait` list, and directly after the `if (showBanner) … else …` block add:

```dart
    if (call.direction == CallDirection.incoming) _deps.afterIncomingCall();
```

Append to `docs/qa/calls-matrix.md`:

```markdown

## 4. Android-only

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| AND-1 | Voice call in background (Android 14) | Connected voice call; press Home for 2 min; talk | Peer hears you throughout; "Call in progress" ongoing notification shown; it disappears when the call ends | |
| AND-2 | Video call in background (Android 14) | Same with video | Audio continues; peer sees "Camera paused"; camera returns on resume; no crash (camera FGS type) | |
| AND-3 | Full-screen intent prompt | Fresh install on Android 14; receive and finish one call | Explainer appears once after the call; "Open settings" lands on the full-screen-intent toggle; never shown again | |
| AND-4 | Locked-phone ring after granting | AND-3 granted; lock phone; receive a call | Full-screen call UI, no duplicate notification (incoming push is data-only) | |
```

In `docs/REMAINING_WORK.md` tick `  - [x] A12 Android microphone/camera foreground service + full-screen-intent request` and add to §1 (Owner): `- [ ] Play Console → App content → Foreground services: declare **microphone** and **camera** ("ongoing 1:1 voice/video call") before uploading the build with Task A12 — the upload is rejected without it.`

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/call_android_test.dart test/services/call_manager_test.dart test/services/call_video_test.dart && flutter build apk --debug`
Expected: tests pass; the debug APK builds (manifest + plugin resolve). Then on an Android 14 device: rows **AND-1 … AND-4** ✅.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml lib/services/call/call_foreground_service.dart lib/services/call/full_screen_intent_prompt.dart lib/services/call/call_platform.dart lib/services/call_manager.dart test/helpers/call_fakes.dart test/services/call_android_test.dart docs/qa/calls-matrix.md docs/REMAINING_WORK.md
git commit -F - <<'MSG'
fix(android): keep calls alive in the background; ask for full-screen intent

A typed foreground service (microphone, plus camera for video) runs from
media-up to _finish via flutter_foreground_task - without it Android stopped
capturing seconds after the app left the foreground. USE_FULL_SCREEN_INTENT
was declared but never requested; Android 14+ users now get a one-time
explainer after their first incoming call ends.

Still open (calls app): A13-A14; owner: Play Console foreground-service
declarations (microphone, camera); run the QA matrix; native review of
call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A13: `CallLauncher`, call bubble labels, chat-list preview

**Files:**
- Create: `lib/services/call/call_launcher.dart`
- Rewrite: `lib/widgets/call/call_history_bubble.dart`
- Modify: `lib/pages/chat/message/messages_list.dart:255-268`
- Modify: `lib/pages/chat/conversation/conversation_messages_view.dart` (fields 16-54, constructor, `ChatMessagesList(...)` at ~109)
- Modify: `lib/pages/chat/conversation/chat_conversation_screen.dart:2008` (`ConversationMessagesView(...)`)
- Modify: `lib/pages/chat/header/chat_app_bar.dart` (`_initiateCall` 415-457, delete `_handleCallError`)
- Modify: `lib/widgets/call/call_buttons.dart:68-89`
- Modify: `lib/pages/chat/models/chat_partner.dart:110` (`getMessagePreview`)
- Modify: `lib/pages/chat/list/list_socket_handlers.dart` (`ListSocketContext`, `_extractMessagePreview` → `extractMessagePreview`, two call sites)
- Modify: `lib/providers/provider_root/message_provider.dart:920-950` (`LastMessageData.callData`)
- Modify: `lib/pages/chat/list/chat_list_screen.dart` (482, 565, 589, `ListSocketContext(...)` 225)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/widgets/call_history_bubble_test.dart`, `test/chat/call_preview_test.dart`, `test/services/call_launcher_test.dart`

**Interfaces:**
- Consumes: `CallLabels`, `callPreviewText`, `CallRecord.outcome` (A2); `InitiateStatus` (A4); `CallRoutes` (A3).
- Produces: `CallLauncher.start(BuildContext, WidgetRef, {required String userId, required String userName, String? avatar, required CallType type, void Function(CallModel)? openActive})`, `CallLauncher.showCallError(BuildContext, String)`; `CallHistoryBubble({required CallRecord call, required bool isOutgoing, String otherName = '', VoidCallback? onTap})`; `getMessagePreview(Message, {String Function(Map<String, dynamic> callData)? callPreview})`; `extractMessagePreview(Map, {String Function(Map<String, dynamic>)? callPreview})`; `ListSocketContext.callPreview: String Function(Map<String, dynamic> callData, String otherName)?`; `LastMessageData.callData: Map<String, dynamic>?`; `ConversationMessagesView.onCallTap: void Function(CallRecord)?`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/call_history_bubble_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/widgets/call/call_history_bubble.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

CallRecord _record(String outcome, {String type = 'audio', int duration = 0}) => CallRecord.fromJson({
      '_id': 'c1', 'callId': 'c1', 'initiator': 'caller', 'participants': [], 'type': type,
      'startTime': '2026-10-08T12:00:00.000Z', 'duration': duration, 'status': 'missed', 'outcome': outcome,
    }, 'viewer');

void main() {
  testWidgets('receiver sees "Missed voice call" in red with the missed arrow', (tester) async {
    await tester.pumpWidget(_wrap(CallHistoryBubble(call: _record('no_answer'), isOutgoing: false, otherName: 'Ada')));
    expect(find.text('Missed voice call'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.call_missed)).color, Colors.red);
  });

  testWidgets('caller sees "Voice call · No answer", busy shows the name', (tester) async {
    await tester.pumpWidget(_wrap(CallHistoryBubble(call: _record('no_answer'), isOutgoing: true, otherName: 'Bo')));
    expect(find.text('Voice call · No answer'), findsOneWidget);
    expect(find.byIcon(Icons.call_made), findsOneWidget);
    await tester.pumpWidget(_wrap(CallHistoryBubble(call: _record('busy'), isOutgoing: true, otherName: 'Bo')));
    expect(find.text('Bo was on another call'), findsOneWidget);
  });

  testWidgets('completed video call shows direction and duration; tap calls back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(CallHistoryBubble(
      call: _record('completed', type: 'video', duration: 83), isOutgoing: true, otherName: 'Bo', onTap: () => taps++)));
    expect(find.text('Outgoing video call · 1:23'), findsOneWidget);
    await tester.tap(find.byType(CallHistoryBubble));
    expect(taps, 1);
  });
}
```

Create `test/chat/call_preview_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/pages/chat/list/list_socket_handlers.dart';
import 'package:bananatalk_app/pages/chat/models/chat_partner.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';

final _callData = {
  '_id': 'c1', 'callId': 'c1', 'initiator': 'a', 'participants': [], 'type': 'audio',
  'startTime': '2026-10-08T12:00:00.000Z', 'duration': 0, 'status': 'missed', 'outcome': 'cancelled',
};

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String preview(Map<String, dynamic> d) => callPreviewText(l10n, d, viewerId: 'b', otherName: 'U');

  test('getMessagePreview uses the viewer label for call messages', () {
    final m = Message.fromJson({
      'id': '1', 'sender': {'_id': 'a', 'name': 'U', 'images': []}, 'receiver': {'_id': 'b', 'name': 'O', 'images': []},
      'message': '📞 Cancelled voice call', 'createdAt': '2026-10-08T12:00:00.000Z', 'type': 'call', 'read': false,
      'reactions': [], 'translations': [], 'corrections': [], 'mentions': [],
      'media': {'type': 'call', 'callData': _callData},
    });
    expect(getMessagePreview(m, callPreview: preview), '📞 Missed voice call');
    expect(getMessagePreview(m), '📞 Cancelled voice call', reason: 'without a label builder the server text is used');
  });

  test('socket preview and list-API preview use it too', () {
    expect(extractMessagePreview({'message': '📞 Cancelled voice call', 'media': {'type': 'call', 'callData': _callData}},
        callPreview: preview), '📞 Missed voice call');
    final last = LastMessageData.fromJson({'message': '📞 Cancelled voice call', 'media': {'type': 'call', 'callData': _callData}});
    expect(last.callData?['outcome'], 'cancelled');
  });
}
```

Create `test/services/call_launcher_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_launcher.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  Future<List<String>> run(WidgetTester tester, CallHarness h) async {
    final opened = <String>[];
    CallManager.debugSetInstance(h.manager);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) => TextButton(
            onPressed: () => CallLauncher.start(context, ref,
                userId: 'u2', userName: 'Bo', type: CallType.audio, openActive: (c) => opened.add(c.callId)),
            child: const Text('call'),
          )),
        ),
      ),
    ));
    await tester.tap(find.text('call'));
    await tester.pump();
    await tester.pump();
    return opened;
  }

  testWidgets('busy callee → "Bo was on another call", no call screen', (tester) async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLEE_BUSY');
    final opened = await run(tester, h);
    expect(find.text('Bo was on another call'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('started → the active call screen opens for the new call', (tester) async {
    final h = CallHarness();
    final opened = await run(tester, h);
    expect(opened, ['call-1']);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/call_history_bubble_test.dart test/chat/call_preview_test.dart test/services/call_launcher_test.dart`
Expected: FAIL — `No named parameter with the name 'otherName'`, `extractMessagePreview` not found, `call_launcher.dart` missing.

- [ ] **Step 3: Implement**

Create `lib/services/call/call_launcher.dart`:

```dart
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call_manager.dart' show InitiateStatus;

/// The one way the UI starts a call: chat header, call buttons, call bubble
/// ("call back") and the Calls list all come through here, so busy and
/// error handling is identical everywhere.
class CallLauncher {
  const CallLauncher._();

  static Future<void> start(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String userName,
    String? avatar,
    required CallType type,
    void Function(CallModel call)? openActive,
  }) async {
    final notifier = ref.read(callProvider.notifier);
    notifier.setCallErrorCallback((error) {
      if (context.mounted) showCallError(context, error);
    });
    final result = await notifier.initiateCall(userId, userName, avatar, type);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (result.status) {
      case InitiateStatus.started:
        final call = notifier.currentCall;
        if (call != null) (openActive ?? CallRoutes.openActive)(call);
      case InitiateStatus.calleeBusy:
        _snack(context, l10n.callLabelBusy(userName));
      case InitiateStatus.callerBusy:
        _snack(context, l10n.callFailed);
      case InitiateStatus.permissionDenied:
      case InitiateStatus.failed:
        break; // already surfaced through the error callback
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Permission errors arrive as `PERMANENTLY_DENIED:<msg>` / `DENIED:<msg>`.
  static void showCallError(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.startsWith('PERMANENTLY_DENIED:')) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.permissionsRequired),
          content: Text(error.substring('PERMANENTLY_DENIED:'.length)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                AppSettings.openAppSettings();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
    } else if (error.startsWith('DENIED:')) {
      _snack(context, error.substring('DENIED:'.length));
    } else {
      _snack(context, error);
    }
  }
}
```

Replace `lib/widgets/call/call_history_bubble.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/models/call_record_model.dart';

/// A call message in the conversation. One message is shared by both users;
/// each side renders its own §3 label from `outcome` and who called.
class CallHistoryBubble extends StatelessWidget {
  final CallRecord call;

  /// True when the viewer sent the message, i.e. was the caller.
  final bool isOutgoing;
  final String otherName;
  final VoidCallback? onTap;

  const CallHistoryBubble({
    super.key,
    required this.call,
    required this.isOutgoing,
    this.otherName = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outcome = call.outcome ?? CallOutcome.completed;
    final isVideo = call.type == CallType.video;
    final missed = CallLabels.isMissedForViewer(outcome, viewerIsCaller: isOutgoing);
    final negative = missed || outcome == CallOutcome.declined;
    final label = CallLabels.label(
      l10n,
      outcome: outcome,
      viewerIsCaller: isOutgoing,
      isVideo: isVideo,
      duration: call.duration ?? 0,
      otherName: otherName,
    );
    final directionIcon = missed
        ? Icons.call_missed
        : (isOutgoing ? Icons.call_made : Icons.call_received);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: negative ? Colors.red.withValues(alpha: 0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: negative ? Colors.red.withValues(alpha: 0.3) : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(directionIcon, color: negative ? Colors.red : Colors.green, size: 18),
            const SizedBox(width: 6),
            Icon(isVideo ? Icons.videocam_outlined : Icons.call_outlined,
                color: negative ? Colors.red : theme.iconTheme.color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: negative ? Colors.red : null, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.jm().format(call.startTime.toLocal()),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(isVideo ? Icons.videocam : Icons.call, size: 16, color: theme.primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}
```

In `lib/pages/chat/message/messages_list.dart` replace the `CallHistoryBubble(` construction (259-266) with:

```dart
                return CallHistoryBubble(
                  key: ValueKey(message.id),
                  call: callRecord,
                  isOutgoing: isMe,
                  otherName: otherUserName,
                  onTap: onCallTap != null ? () => onCallTap!(callRecord) : null,
                );
```

In `lib/pages/chat/conversation/conversation_messages_view.dart` add the field `final void Function(CallRecord record)? onCallTap;`, the constructor parameter `this.onCallTap,`, the import `package:bananatalk_app/models/call_record_model.dart`, and pass `onCallTap: onCallTap,` in the `ChatMessagesList(` call (after `onSendWave: onSendWave,`).

In `lib/pages/chat/conversation/chat_conversation_screen.dart`, in the `ConversationMessagesView(` call (line 2008) add:

```dart
                    // Call back with the same type from a call bubble.
                    onCallTap: (record) => CallLauncher.start(
                      context,
                      ref,
                      userId: widget.userId,
                      userName: widget.userName,
                      avatar: widget.profilePicture,
                      type: record.type,
                    ),
```

and the import `package:bananatalk_app/services/call/call_launcher.dart`.

In `lib/pages/chat/header/chat_app_bar.dart` replace the body of `_initiateCall` with:

```dart
    if (userId == null) return;
    await CallLauncher.start(
      context,
      ref,
      userId: userId!,
      userName: userName,
      avatar: profilePicture,
      type: callType,
    );
```

delete `_handleCallError`, delete the imports `package:app_settings/app_settings.dart`, `package:bananatalk_app/providers/call_provider.dart` and `package:bananatalk_app/services/call/call_routes.dart` (their only users were the two removed blocks; `call_model.dart` stays for `CallType`), and add `import 'package:bananatalk_app/services/call/call_launcher.dart';`.

In `lib/widgets/call/call_buttons.dart` replace the body of `_initiateCall` with:

```dart
    await CallLauncher.start(
      context,
      ref,
      userId: recipientId,
      userName: recipientName,
      avatar: recipientProfilePicture,
      type: callType,
    );
```

add `import 'package:bananatalk_app/services/call/call_launcher.dart';`, and delete the imports `package:bananatalk_app/providers/call_provider.dart` and `package:bananatalk_app/utils/friendly_error.dart` (only the old body used them).

In `lib/pages/chat/models/chat_partner.dart` change `getMessagePreview` to:

```dart
String getMessagePreview(
  Message message, {
  String Function(Map<String, dynamic> callData)? callPreview,
}) {
  // Call messages: the viewer's own §3 label (the server text is caller-neutral).
  if (callPreview != null && message.type == 'call' && message.media?.callData != null) {
    return callPreview(message.media!.callData!);
  }

  // Check for story reference first
```

(the rest of the function unchanged).

In `lib/pages/chat/list/list_socket_handlers.dart`:
- add to `ListSocketContext` the field and constructor parameter:

```dart
  /// Viewer-perspective label for a call message (needs l10n, so the State
  /// builds it). Null → the server's plain-text fallback is shown.
  final String Function(Map<String, dynamic> callData, String otherName)? callPreview;
```

  (`this.callPreview,` — optional, after `required this.setTypingTimer,`);
- rename `_extractMessagePreview` to `extractMessagePreview` and give it the parameter and first check:

```dart
String extractMessagePreview(
  Map<dynamic, dynamic> messageData, {
  String Function(Map<String, dynamic> callData)? callPreview,
}) {
  final callData = messageData['media'] is Map ? messageData['media']['callData'] : null;
  if (callPreview != null && callData is Map) {
    return callPreview(Map<String, dynamic>.from(callData));
  }
  final rawText = messageData['message']?.toString() ?? '';
```

- in `handleNewMessage` replace `final messageText = _extractMessagePreview(messageData);` with

```dart
    final messageText = extractMessagePreview(messageData,
        callPreview: ctx.callPreview == null ? null : (d) => ctx.callPreview!(d, senderName));
```

  and in the sent-message handler (line ~173) with

```dart
    final messageText = extractMessagePreview(messageData,
        callPreview: ctx.callPreview == null ? null : (d) => ctx.callPreview!(d, receiverName));
```

In `lib/providers/provider_root/message_provider.dart` add to `LastMessageData` the field `final Map<String, dynamic>? callData;`, the constructor parameter `this.callData,` and in `fromJson`:

```dart
      callData: json['media'] is Map && (json['media'] as Map)['callData'] is Map
          ? Map<String, dynamic>.from((json['media'] as Map)['callData'] as Map)
          : null,
```

In `lib/pages/chat/list/chat_list_screen.dart`:
- add imports `package:bananatalk_app/models/call_outcome.dart`;
- add to the State:

```dart
  String _callPreview(Map<String, dynamic> callData, String otherName) =>
      callPreviewText(AppLocalizations.of(context)!, callData, viewerId: _currentUserId, otherName: otherName);
```

- line 482: `lastMessage: data.lastMessage?.displayText,` → `lastMessage: data.lastMessage?.callData != null ? _callPreview(data.lastMessage!.callData!, data.name) : data.lastMessage?.displayText,`;
- lines 565 and 589: `getMessagePreview(message)` → `getMessagePreview(message, callPreview: (d) => _callPreview(d, otherUser.name))`;
- in `ListSocketContext(` (225) add `callPreview: _callPreview,`.

In `docs/REMAINING_WORK.md` tick `  - [x] A13 CallLauncher, call bubble labels, chat-list preview`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets/call_history_bubble_test.dart test/chat/call_preview_test.dart test/services/call_launcher_test.dart test/chat && flutter analyze lib`
Expected: all pass; no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/call/call_launcher.dart lib/widgets/call/call_history_bubble.dart lib/pages/chat/message/messages_list.dart lib/pages/chat/conversation/conversation_messages_view.dart lib/pages/chat/conversation/chat_conversation_screen.dart lib/pages/chat/header/chat_app_bar.dart lib/widgets/call/call_buttons.dart lib/pages/chat/models/chat_partner.dart lib/pages/chat/list/list_socket_handlers.dart lib/providers/provider_root/message_provider.dart lib/pages/chat/list/chat_list_screen.dart test/widgets/call_history_bubble_test.dart test/chat/call_preview_test.dart test/services/call_launcher_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): call history in the conversation and the chat list

The call bubble renders each side's §3 label (Outgoing/Incoming · m:ss,
Missed, No answer, Cancelled, Declined, "<name> was on another call") with
direction and type icons, missed in red; tapping it calls back with the
same type. Chat-list previews use the same label on every path (initial
list, history rebuild, live socket). Every call entry point goes through
CallLauncher, which shows the busy toast and permission errors the same
way (call_buttons never opened the call screen before).

Still open (calls app): A14; owner: Play Console FGS declarations; run the
QA matrix; native review of call strings; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---

### Task A14: Calls list, chat-tab phone icon, missed badge

**Files:**
- Rewrite: `lib/services/call_history_service.dart`
- Create: `lib/providers/missed_calls_provider.dart`
- Rewrite: `lib/screens/call_history_screen.dart`
- Delete: `lib/services/daily_call_limit_service.dart` (its only user was the old Calls screen)
- Modify: `lib/pages/chat/list/chat_list_screen.dart` (app-bar `actions` ~1258, `initState`)
- Modify: `lib/main.dart` (`_initializeCallManager`)
- Modify: `docs/REMAINING_WORK.md`
- Test: `test/screens/call_history_screen_test.dart`

**Interfaces:**
- Consumes: `GET /calls`, `GET /calls/missed/count`, `POST /calls/missed/seen` (B9); `CallLogEntry`, `CallLabels` (A2); `CallLauncher` (A13); `CallManager.finishes` (A4).
- Produces: `class CallLogPage { List<CallLogEntry> items; bool hasMore }`; `CallHistoryService([ApiClient?])` with `pageSize = 30`, `fetchPage(int page)`, `missedCount()`, `markMissedSeen()`; `callHistoryServiceProvider`; `MissedCallsNotifier` (`refresh()`, `markSeen()`) / `missedCallsProvider: StateNotifierProvider<MissedCallsNotifier, int>`; `CallHistoryScreen` (route `/call-history`, unchanged).

- [ ] **Step 1: Write the failing test**

Create `test/screens/call_history_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/providers/missed_calls_provider.dart';
import 'package:bananatalk_app/screens/call_history_screen.dart';
import 'package:bananatalk_app/services/call_history_service.dart';

class _FakeHistory implements CallHistoryService {
  _FakeHistory(this.pages);
  final Map<int, CallLogPage> pages;
  int seen = 0;
  final requested = <int>[];

  @override
  Future<CallLogPage> fetchPage(int page) async {
    requested.add(page);
    return pages[page] ?? const CallLogPage([], false);
  }

  @override
  Future<int> missedCount() async => 2;

  @override
  Future<void> markMissedSeen() async => seen++;
}

CallLogEntry _entry(String id, String direction, String outcome, {String type = 'audio', int duration = 0}) =>
    CallLogEntry.fromJson({
      'id': id, 'type': type, 'direction': direction, 'outcome': outcome, 'duration': duration,
      'otherParty': {'id': 'u-$id', 'name': 'Ada', 'avatar': null}, 'createdAt': '2026-10-08T12:00:00.000Z',
    });

Future<void> _pump(WidgetTester tester, _FakeHistory fake) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [callHistoryServiceProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CallHistoryScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rows: §3 labels, missed in red, opening marks missed calls seen', (tester) async {
    final fake = _FakeHistory({
      1: CallLogPage([
        _entry('1', 'in', 'no_answer'),
        _entry('2', 'out', 'completed', type: 'video', duration: 83),
      ], false),
    });
    await _pump(tester, fake);
    expect(find.textContaining('Missed voice call'), findsOneWidget);
    expect(find.textContaining('Outgoing video call · 1:23'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.call_missed)).color, Colors.red);
    expect(fake.seen, 1);
    expect(fake.requested, [1]);
  });

  testWidgets('empty state', (tester) async {
    await _pump(tester, _FakeHistory({}));
    expect(find.text('No calls yet'), findsOneWidget);
  });

  test('missed badge: refresh reads the count, markSeen clears it', () async {
    final fake = _FakeHistory({});
    final container = ProviderContainer(overrides: [callHistoryServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    await container.read(missedCallsProvider.notifier).refresh();
    expect(container.read(missedCallsProvider), 2);
    await container.read(missedCallsProvider.notifier).markSeen();
    expect(container.read(missedCallsProvider), 0);
    expect(fake.seen, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/call_history_screen_test.dart`
Expected: FAIL — `Error when reading 'lib/providers/missed_calls_provider.dart'`, `CallLogPage` / `fetchPage` not defined.

- [ ] **Step 3: Implement**

Replace `lib/services/call_history_service.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/services/api_client.dart';

class CallLogPage {
  const CallLogPage(this.items, this.hasMore);
  final List<CallLogEntry> items;
  final bool hasMore;
}

/// GET /calls (30 per page), missed count and mark-seen (spec §4.7).
class CallHistoryService {
  CallHistoryService([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;
  static const int pageSize = 30;

  Future<CallLogPage> fetchPage(int page) async {
    final res = await _client.get('calls', queryParams: {'page': '$page', 'limit': '$pageSize'});
    if (!res.success || res.data is! Map) return const CallLogPage([], false);
    final body = Map<String, dynamic>.from(res.data as Map);
    final items = (body['data'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => CallLogEntry.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final hasMore = (body['pagination'] as Map?)?['hasMore'] == true;
    return CallLogPage(items, hasMore);
  }

  Future<int> missedCount() async {
    final res = await _client.get('calls/missed/count');
    if (!res.success || res.data is! Map) return 0;
    return ((res.data as Map)['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markMissedSeen() async {
    await _client.post('calls/missed/seen');
  }
}

final callHistoryServiceProvider = Provider<CallHistoryService>((ref) => CallHistoryService());
```

Create `lib/providers/missed_calls_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/services/call_history_service.dart';

/// Unseen missed calls (receiver side, §3) — the chat-tab phone-icon badge.
class MissedCallsNotifier extends StateNotifier<int> {
  MissedCallsNotifier(this._service) : super(0);

  final CallHistoryService _service;

  Future<void> refresh() async {
    try {
      state = await _service.missedCount();
    } catch (_) {
      // Keep the last known count; the badge is advisory.
    }
  }

  /// The Calls list was opened.
  Future<void> markSeen() async {
    state = 0;
    try {
      await _service.markMissedSeen();
    } catch (_) {}
  }
}

final missedCallsProvider = StateNotifierProvider<MissedCallsNotifier, int>(
  (ref) => MissedCallsNotifier(ref.watch(callHistoryServiceProvider)),
);
```

Replace `lib/screens/call_history_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/providers/missed_calls_provider.dart';
import 'package:bananatalk_app/services/call/call_launcher.dart';
import 'package:bananatalk_app/services/call_history_service.dart';
import 'package:bananatalk_app/widgets/navigation/app_back_button.dart';

/// The Calls list (spec §5.7): every call with labels derived from §3,
/// 30 per page, opening it clears the missed badge.
class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  final List<CallLogEntry> _items = [];
  final ScrollController _scroll = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(missedCallsProvider.notifier).markSeen();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final page = await ref.read(callHistoryServiceProvider).fetchPage(_page + 1);
    if (!mounted) return;
    setState(() {
      _page++;
      _items.addAll(page.items);
      _hasMore = page.hasMore;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text(l10n.callsTitle)),
      body: _items.isEmpty && !_loading
          ? Center(child: Text(l10n.callsEmpty))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, i) => i >= _items.length
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _CallLogTile(entry: _items[i]),
              ),
            ),
    );
  }
}

class _CallLogTile extends ConsumerWidget {
  const _CallLogTile({required this.entry});

  final CallLogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isCaller = entry.direction == CallDirection.outgoing;
    final isVideo = entry.type == CallType.video;
    final missed = CallLabels.isMissedForViewer(entry.outcome, viewerIsCaller: isCaller);
    final label = CallLabels.label(
      l10n,
      outcome: entry.outcome,
      viewerIsCaller: isCaller,
      isVideo: isVideo,
      duration: entry.duration,
      otherName: entry.otherName,
    );
    final time = DateFormat.MMMd().add_jm().format(entry.createdAt.toLocal());
    final avatar = entry.otherAvatar;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar == null || avatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(entry.otherName, style: TextStyle(color: missed ? Colors.red : null)),
      subtitle: Row(
        children: [
          Icon(
            missed ? Icons.call_missed : (isCaller ? Icons.call_made : Icons.call_received),
            size: 14,
            color: missed ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          Icon(isVideo ? Icons.videocam_outlined : Icons.call_outlined, size: 14),
          const SizedBox(width: 4),
          Expanded(child: Text('$label · $time', overflow: TextOverflow.ellipsis)),
        ],
      ),
      trailing: IconButton(
        icon: Icon(isVideo ? Icons.videocam : Icons.call),
        onPressed: entry.otherId.isEmpty
            ? null
            : () => CallLauncher.start(
                  context,
                  ref,
                  userId: entry.otherId,
                  userName: entry.otherName,
                  avatar: entry.otherAvatar,
                  type: entry.type,
                ),
      ),
      onTap: entry.otherId.isEmpty ? null : () => context.push('/chat/${entry.otherId}'),
    );
  }
}
```

Delete the unused limit service: `git rm lib/services/daily_call_limit_service.dart`.

In `lib/pages/chat/list/chat_list_screen.dart`:
- add the import `package:bananatalk_app/providers/missed_calls_provider.dart`;
- at the end of `initState` add:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(missedCallsProvider.notifier).refresh();
    });
```

- in the app-bar `actions:` list (line ~1258) insert before `NotificationBell(color: colors.onBackground),`:

```dart
          Builder(builder: (context) {
            final missed = ref.watch(missedCallsProvider);
            return IconButton(
              tooltip: AppLocalizations.of(context)!.callsTitle,
              onPressed: () => context.push('/call-history'),
              icon: Badge(
                isLabelVisible: missed > 0,
                label: Text(missed > 99 ? '99+' : '$missed'),
                child: Icon(Icons.call_outlined, color: colors.onBackground),
              ),
            );
          }),
```

In `lib/main.dart`, in `_initializeCallManager` after the cold-start lines add:

```dart
      // A finished incoming call may be a new missed call: refresh the badge.
      manager.finishes.listen((finish) {
        if (finish.call.direction == CallDirection.incoming) {
          appProviderContainer.read(missedCallsProvider.notifier).refresh();
        }
      });
```

with imports `package:bananatalk_app/models/call_model.dart` and `package:bananatalk_app/providers/missed_calls_provider.dart`.

In `docs/REMAINING_WORK.md` tick `  - [x] A14 Calls list + chat-tab icon + missed badge` and the parent `- [ ] App (plan …)` stays open until device QA passes.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/screens/call_history_screen_test.dart && flutter test && flutter analyze lib`
Expected: the new tests pass; the full app suite passes; no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/call_history_service.dart lib/providers/missed_calls_provider.dart lib/screens/call_history_screen.dart lib/pages/chat/list/chat_list_screen.dart lib/main.dart test/screens/call_history_screen_test.dart docs/REMAINING_WORK.md
git commit -F - <<'MSG'
feat(calls): Calls list with missed badge in the chat tab

The Calls screen is rebuilt on GET /calls: avatar, name, in/out/missed
arrow (missed in red), type, time and duration from the §3 labels, 30 per
page, row tap opens the conversation, a trailing button calls back with the
same type. A phone icon in the chat-tab app bar carries the unseen-missed
badge; opening the list marks them seen. The old screen crashed on fields
the API never sent and was not reachable from navigation.

App Phase 1 is code-complete. Still open (calls): device QA matrix
(docs/qa/calls-matrix.md); owner: Play Console FGS declarations, LiveKit
webhook URL, migrate:call-indexes, VoIP init check; native review of call
strings; measure answered rate one week after release; Phase 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
```

---
# Phase 2 — Extras (after Phase 1 ships and the answered-rate is measured)

Same rules as Phase 1 (TDD cycle, REMAINING_WORK in every commit, package imports). Each task lists its files, interfaces and the tests that must exist; code is given only where the shape is not obvious from Phase 1.

### Task P2.1 (backend): Decline with a message

**Files:** Modify `controllers/callController.js` (`declineCall`), `services/callMessageService.js` (export `writeTextAfterCall`); Test `test/callDeclineMessage.test.js`.

**Interfaces:** `POST /calls/:idOrUuid/decline { deviceId?, message? }` — `message` is trimmed, 1..200 chars, else `400 { code: 'DECLINE_MESSAGE_INVALID' }`. After the `decline` transition (which writes the call message in its effects), `writeTextAfterCall({ from: receiverId, to: callerId, text })` creates a normal `messageType: 'text'` message through the same conversation update + `newMessage`/`messageSent` emit as `writeCallMessage`, with `createdAt` 1 ms after the call message so ordering is stable. No chat push (the caller is on the call screen and sees it in the conversation).

- [ ] Step 1 — tests: (a) decline with `message: 'Can\'t talk now'` → exactly two messages, call message first then the text, text sender = receiver; (b) 201-char message → 400 and the call is still `ringing`; (c) a 409 decline (already accepted) writes no text; (d) live-build decline without `message` is unchanged.
- [ ] Step 2 — run `node --test … test/callDeclineMessage.test.js`, expect failures (a)-(b).
- [ ] Step 3 — validate before the transition; write the text only when the transition succeeded.
- [ ] Step 4 — run the new file plus `test/callController.test.js` and `test/callMessages.test.js`.
- [ ] Step 5 — commit `feat(calls): decline with a message`, tick in backend `docs/REMAINING_WORK.md`.

### Task P2.2 (app): Decline-with-message sheet on `IncomingCallScreen`

**Files:** Modify `lib/services/call/call_api.dart` (`decline(..., {String? deviceId, String? message})`), `lib/services/call_manager.dart` (`rejectCall({String? message})`), `lib/screens/incoming_call_screen.dart` (third button "Message" → bottom sheet), `lib/l10n/app_*.arb` (keys `callDeclineWithMessage`, `callDeclineReplyLater` = "Can't talk now — I'll call you back", `callDeclineReplyText` = "Can't talk now — text me?", `callDeclineCustomHint`), `test/helpers/call_fakes.dart`; Test `test/screens/incoming_call_decline_message_test.dart`.

**Interfaces:** in-app screen only (CallKit / the plugin's Android UI cannot host it). Sheet: two canned replies + a text field (max 200, counter shown). Choosing one calls `CallManager().rejectCall(message: text)`.

- [ ] Step 1 — widget tests: tapping a canned reply sends `decline:call-1` with that message and closes the screen; the custom field enforces 200 chars; all 19 locales have the 4 keys (extend `test/l10n/call_strings_test.dart`).
- [ ] Steps 2-4 — red, implement, green (`flutter test` on the two files).
- [ ] Step 5 — commit `feat(calls): decline with a message from the ring screen`; tick in app `docs/REMAINING_WORK.md`.

### Task P2.3 (backend): Missed-call push carries action metadata

**Files:** Modify `services/fcmService.js` (`TYPE_TO_CATEGORY.missed_call = 'MISSED_CALL'`), `services/callPushService.js` (`sendMissedCall`: Android tokens get a data-only message `{ type: 'missed_call', callId, callUuid, callerId, callerName, callType, title, body }` so the app can build actions; iOS keeps the alert with category `MISSED_CALL`); Test extend `test/callPush.test.js`.

**Interfaces:** iOS alert `aps.category = 'MISSED_CALL'`; Android data-only with `title`/`body` in data.

- [ ] Step 1 — tests: iOS message has `apns.payload.aps.category === 'MISSED_CALL'`; Android message has no `notification` block and carries `title`/`body` in `data`; live-build safety: Android data-only missed push goes only to tokens with capability `missed_call_actions` (live builds would otherwise show the blank-banner case), others keep the Phase 1 notification message.
- [ ] Steps 2-5 — red, implement (add `'missed_call_actions'` to `KNOWN_CAPABILITIES`), green, commit `feat(calls): missed-call push action metadata`.

### Task P2.4 (app + iOS): Call back / Message actions on the missed-call notification

**Files:** Modify `ios/Runner/AppDelegate.swift` (register `UNNotificationCategory(identifier: "MISSED_CALL", actions: [call_back (foreground), message (foreground)])` in `didFinishLaunching`), `lib/services/notification_service.dart` (foreground + background: build a local notification with Android actions `call_back` / `message` from the data-only `missed_call`), `lib/services/notification_api_client.dart` (`kCallPushCapabilities` += `'missed_call_actions'`), `lib/services/notification_router.dart` (actionId `call_back` → `PendingCallBack.store(callerId, callerName, callType)` then go `/chat/:callerId`; `message` → `/chat/:callerId`), `lib/services/call/pending_call_back.dart` (create: stores one pending call-back; `CallManager` initialization / first frame with a context runs `CallLauncher.start` and clears it — this is how "Call back from a killed app launches the app, then calls"); `docs/qa/calls-matrix.md` rows `P2-PUSH-1..3`; Tests `test/services/pending_call_back_test.dart`, `test/services/notification_router_missed_call_test.dart`.

- [ ] Step 1 — tests: router maps `_actionId: 'call_back'` to a stored pending call-back + chat route, `message` to the chat route only; `PendingCallBack.takeOnce()` returns the call once; Android local notification for `missed_call` has exactly the two actions.
- [ ] Steps 2-5 — red, implement, green, manual rows (killed app → Call back → app opens and rings the caller), commit `feat(calls): call back / message from the missed-call notification`.

### Task P2.5 (backend): Calls on/off + quiet hours → `CALLEE_UNAVAILABLE`

**Files:** Modify `models/User.js` (`notificationSettings.allowCalls: { type: Boolean, default: true }`), `controllers/notifications.js` (settings update accepts `allowCalls` boolean), `controllers/callController.js` (`initiateCall`), `services/callStateService.js` (`recordUnavailable({ callerId, receiverId, type })`); Test `test/callUnavailable.test.js`.

**Interfaces:** before `startCall`, if `receiver.notificationSettings.allowCalls === false` or `isInQuietHours(receiver, now)` (`lib/quietHours`), create a `Call { status: 'busy', endReason: 'unavailable', callUuid }` **without** claiming anyone, run effects (emits `call:state` only; `outcomeFor` → null so no message, no push) and answer `409 { code: 'CALLEE_UNAVAILABLE' }`. `notificationPreferences.calls` keeps gating only the push (see contradiction #1 in the report — the spec's `notificationSettings.calls` is actually `notificationPreferences.calls`).

- [ ] Step 1 — tests: allowCalls false → 409, record busy/unavailable, zero messages, zero pushes, not in `GET /calls`, not counted as missed; inside quiet hours (Asia/Seoul 22:00-08:00 at 23:00 KST) → same; outside → rings; allowCalls default true for existing users.
- [ ] Steps 2-5 — red, implement, green (also re-run `test/callHistory.test.js`), commit `feat(calls): calls off and quiet hours make the callee unavailable`.

### Task P2.6 (app): "Allow calls" setting + unavailable toast

**Files:** Modify notification settings model/provider/screen (Settings → Notifications: switch "Allow calls" with subtitle "Quiet hours also block calls"), `lib/services/call/call_api.dart` (`isCalleeUnavailable`), `lib/services/call_manager.dart` (`InitiateStatus.calleeUnavailable`), `lib/services/call/call_launcher.dart` (toast `callUnavailable(name)` = "{name} isn't taking calls"), `lib/l10n/app_*.arb` (`callAllowCallsTitle`, `callAllowCallsSubtitle`, `callUnavailable`); `FullScreenIntentPrompt.maybeAsk` also runs when this settings screen opens (spec §5.4); Tests `test/services/call_launcher_test.dart` (+unavailable), settings widget test.

- [ ] Steps 1-5 — tests first (toast text, setting persists via the settings API, FSI prompt hook on open), red, implement, green, commit `feat(calls): allow-calls setting and unavailable toast`.

### Task P2.7 (backend): Upgrade a voice call to video

**Files:** Modify `services/callStateService.js` (`upgradeToVideo(callId, by)`: conditional `findOneAndUpdate({ _id, status: 'active', type: 'audio' }, { type: 'video' })`, then emit `call:state` with `type: 'video'` to both rooms; 409 `CALL_STATE` otherwise), `controllers/callController.js` + `routes/calls.js` (`POST /calls/:idOrUuid/upgrade`, participant only); Test `test/callUpgrade.test.js`.

- [ ] Step 1 — tests: active audio → 200 and `call:state.type === 'video'` to both; ringing or already video → 409; non-participant → 403; the call message written at the end says `type: 'video'`.
- [ ] Steps 2-5 — red, implement, green, commit `feat(calls): upgrade a voice call to video`.

### Task P2.8 (app): Camera button during a voice call

**Files:** Modify `lib/services/call/call_api.dart` (`upgrade(callId)`), `lib/services/call_manager.dart` (`upgradeToVideo()`: permission → `api.upgrade` → `liveKit.setCameraEnabled(true)` → `currentCall.copyWith(callType: CallType.video)` → wakelock on → `startCallService(video: true)` to add the camera FGS type; `_onCallState` applies `type: 'video'` from the peer's upgrade), `lib/screens/active_call_screen.dart` (camera button on voice calls; layout switches to video tiles when `callType` becomes video); Test `test/services/call_upgrade_test.dart`.

- [ ] Steps 1-5 — tests: local upgrade calls the API, enables the camera, flips the type, restarts the service with video; a peer's `call:state {type:'video'}` flips our type without enabling our camera; 409 leaves the call audio. Commit `feat(calls): turn the camera on during a voice call`.

### Task P2.9 (app): Draggable, swappable self-view

**Files:** Create `lib/widgets/call/draggable_self_view.dart` (`DraggableSelfView({required Widget child, required Size size, Alignment initialCorner = Alignment.topRight, VoidCallback? onTap})` — drag follows the finger, on release animates to the nearest of the four corners inside the safe area); Modify `lib/screens/active_call_screen.dart` (wrap the local tile; tap toggles `_selfIsMain`, which swaps which renderer is full-screen); Test `test/widgets/draggable_self_view_test.dart`.

- [ ] Steps 1-5 — tests: dragging to the lower-left quadrant snaps to `Alignment.bottomLeft`; a tap invokes `onTap`; in the screen, tap swaps the two `VideoTrackRenderer`s (keyed `ValueKey('remote')` / `ValueKey('local')`). Commit `feat(calls): draggable, swappable self-view`.

---

## Resolved while planning

1. **Busy claim order.** Spec §4.1 says "caller first, then receiver", but that makes two users calling each other at the same instant both busy. Claims are taken in ascending user-id order (B2), which guarantees exactly one ringing call; the loser gets `CALLER_BUSY` (no record) or `CALLEE_BUSY` (busy record) depending on which claim failed.
2. **Android `call_cancelled` gating.** The live builds' **foreground** FCM handler (`notification_service.dart _handleForegroundMessage`) falls through to `_showLocalNotification`, which shows a blank "Bananatalk" banner for any unknown push. So Android is gated by the same `call_cancel` capability, sent by the new app on `register-token` (B5, A7).
3. **`/end` while ringing.** Caller → `cancel` (missed/caller_cancelled); receiver → `decline`. `room_finished` on a ringing call → `cancel`.
4. **Plain-text fallback.** The spec's "caller's perspective" conflicts with its example; the fallback is per-outcome and neutral ("📞 Missed voice call", "📞 Voice call · 1:01", "📞 Declined voice call", "📞 Cancelled voice call"). The new app always renders its own label.
5. **Backfill trigger.** "First run" is implemented as "rows without `callUuid`" — idempotent and safe across restarts; every call this code creates has a `callUuid`.
6. **Receiver LiveKit token.** Pushes no longer carry it (spec §5.3: token from `/accept`); `/initiate` mints only the caller's.
7. **Full-screen-intent prompt timing.** Asked after the first incoming call **ends**, never over a ringing screen (plus on opening call settings in Phase 2).
8. **Killed-state decline** is not observable through `activeCalls()`; such a call ends by the server's 45 s timeout (outcome `no_answer`) unless the plugin delivers the decline event.
9. **Missed-call push wording** comes from new `notification_templates` keys (`📞 {callerName}` / "Missed voice call"), localized by `preferredLocale`.

---

## Self-review

### Spec coverage

| Spec section | Covered by |
|---|---|
| §1 REST path vs legacy socket logic | B2, B6, B10 |
| §1 socket replaced → deaf to `call:incoming`; foreground FCM dropped | A5, A6 |
| §1 CallKit given the 24-hex id → crash | A3, A7, A8, B5 (VoIP `id` = callUuid) |
| §1 caller screen freezes; End no-ops | A4 (`_finish`, End always closes), A9, A10 |
| §1 handlers ignore `callId`; no busy | A4 (callId filter), B2 (atomic busy) |
| §1 no server timeout / missed / missed push; peer drop never reaches server | B2 (ring timer), B5, B7, B8, A10 |
| §1 accept/decline only to caller; push-ringing devices never dismissed | B3 (`call:state`), B5 (`call_cancelled`), A6, A8 |
| §1 Android FGS, full-screen intent, duplicate UI, killed-state accept | A12, B5 (data-only), A7 |
| §1 `Message.media.type` lacks `call` | B1 |
| §1 `CallHistoryScreen` crash / not linked | B9, A14 |
| §1 video wakelock; 5-min cap receiving-side only | A11, A4 |
| §1 `@parse/node-apn` missing | B1 |
| §2 decisions (server-authoritative, history, busy, cap removed, 45 s/20 s, live builds, phasing) | B2–B10, A4, A13–A14, Global Constraints, Phase 2 |
| §3 outcome table | B2 `outcomeFor`, B4 (message/legacy status), B5 (missed push set), B9 (history/badge), A2 (labels) |
| §4.1 state machine, 409 `CALL_STATE`, live call, `activeCallId`, schema, id-or-uuid | B1, B2, B6 |
| §4.2 ring timeout, sweeper, backfill, webhook grace | B2, B7, B8 |
| §4.3 legacy audiences, `call:ended` on missed, `call:state`, relays, `GET /calls/current` | B3, B6, B10 |
| §4.4 `call_cancelled` (Android data-only, iOS VoIP capability, acting device excluded, cancel-before-invite) | B5, A6, A7, A8 |
| §4.5 call messages (superset, legacy status map, idempotent, first-message conversation path, no chat push) | B4, B6 (cap at initiate) |
| §4.6 push (data-only, 45 s TTL, VoIP id/extra, missed push, node-apn) | B5, B1 |
| §4.7 history API, missed count/seen | B9 |
| §4.8 no server cap | verified while planning (none exists) |
| §5.1 follower, `_finish`, banner, 409 dismiss | A4, A10 |
| §5.2 `onSocketReplaced`, foreground FCM + dedupe, `call_cancelled`, resume/cold start, stale taps, 50 s screen | A5, A6, A9 |
| §5.3 CallKit `callUuid`, `extra`, `activeCalls()`, real device id | A3, A7, A8 |
| §5.4 Android FGS + full-screen intent | A12 |
| §5.5 reconnect 20 s | A10 |
| §5.6 wakelock, camera paused, cap removed, quality chain | A11, A4, A10 |
| §5.7 bubble, chat-list preview, Calls list, badge | A13, A14 |
| §6 Phase 2 (5 items) | P2.1–P2.9 |
| §7 backend tests | B1–B10 test files (each §7 case named in a test title) |
| §7 app tests | A1–A14 test files |
| §7 device QA matrix | A8 (`docs/qa/calls-matrix.md`), A12 (Android rows) |
| §8 rollout / owner tasks | REMAINING_WORK edits in B1 (migrate, webhook URL, VoIP check) and A12 (Play Console FGS) |

### Placeholder check

Searched this document for "TBD", "TODO", "add error handling", "similar to Task", "write tests for the above" and "fill in": none. Every function, type and event used in a task is defined in that task or an earlier one (CallKitEntry/CallKitIds A3; CallFinish/InitiateStatus/CallManagerDeps A4; `_onMediaConnected` A11, extended in A12; `onRawQualityChanged` A10; `countParticipants` B7 before B8 uses it; `callPushService` B5 before B6–B8 stub it).
