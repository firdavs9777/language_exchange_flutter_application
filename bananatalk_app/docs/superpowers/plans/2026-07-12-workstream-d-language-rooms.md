# Workstream D: Public Language Rooms — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship discoverable, seeded, target-language group chat rooms ("hubs") that concentrate the userbase and stay alive via auto-join + presence + a daily prompt — beating the empty-room death spiral that killed voice rooms.

**Architecture:** Extend the existing `Conversation`/`Message` models with hub metadata and a broadcast message path (no per-member unread fan-out). Add room REST routes, socket.io room-scoped events with disconnect-safe presence, a seed migration (system owner + ~8 hubs), and a daily-prompt job. Flutter adds a Rooms tab + directory + room screen, reusing `ChatInputBar`/`ChatSocketService` and extending `ChatMessagesList` for multi-sender rendering. All gated by `ROOMS_ENABLED`.

**Tech Stack:** Node/Express + Mongoose + socket.io (backend), Flutter + Riverpod + socket_io_client (app), MongoDB Atlas.

**Spec:** `docs/superpowers/specs/2026-07-12-workstream-d-language-rooms-design.md`

**Repos:**
- App: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app` (branch `workstream-d-rooms`)
- Backend: `/Users/davis/Desktop/Personal/language_exchange_backend_application`

**Conventions (inherited from A–C):**
- `package:` imports only in Dart (linter-enforced) — no `../../../`.
- TDD on all backend logic. `flutter analyze` clean per commit.
- Commit policy: **follow the standing per-workstream instruction** — confirm with the user whether D allows per-task commits (B/C batched to a single commit at the gate). Default assumption below is per-task commits on the `workstream-d-rooms` branch; if batching is requested, keep branch tips frozen until the gate.
- Kill switch `ROOMS_ENABLED` must wrap every new route + socket handler.

---

## File Structure

**Backend (create):**
- `lib/normalizeLanguage.js` — canonical language resolver + alias table.
- `migrations/seedRooms.js` — upserts system owner user + hub Conversations.
- `controllers/rooms.js` — room directory/detail/history/join/leave/admin handlers.
- `routes/rooms.js` — room REST routes (mounted under `/api/v1/rooms`).
- `socket/roomHandler.js` — room-scoped socket events + presence (registered from `socketHandler.js`).
- `jobs/dailyRoomPromptJob.js` — posts daily prompt system message per hub.
- Tests: `tests/normalizeLanguage.test.js`, `tests/rooms.controller.test.js`, `tests/rooms.socket.test.js` (match existing test runner/location — verify first).

**Backend (modify):**
- `models/Conversation.js` — add hub fields.
- `models/User.js` — add `leftHubs: [ObjectId]`.
- `controllers/conversations.js:21` — exclude `roomType:'hub'` from `getConversations`.
- `socket/socketHandler.js` — register room handlers + decrement presence on `disconnect`.
- `jobs/scheduler.js` — schedule `dailyRoomPromptJob`.
- `config/limitations.js` — add `ROOMS_ENABLED`.
- `controllers/appConfig.js` — emit `roomsEnabled`.
- `server.js` / route index — mount `/api/v1/rooms`.

**App (create):**
- `lib/pages/community/rooms/rooms_directory_screen.dart` — hub list + search.
- `lib/pages/community/rooms/room_card.dart` — one hub row.
- `lib/pages/community/rooms/room_screen.dart` — hub chat screen.
- `lib/models/room.dart` — Room model.
- `lib/services/room_api_client.dart` — REST client for `/rooms`.
- `lib/providers/rooms_provider.dart` — Riverpod state.

**App (modify):**
- `lib/services/chat_socket_service.dart` — add room join/leave/send + streams.
- `lib/pages/community/main/community_tab_bar.dart` — add 8th "Rooms" tab.
- `lib/pages/community/main/community_main.dart` — wire tab view.
- `lib/pages/chat/message/messages_list.dart` — optional per-message sender attribution for hubs.
- `lib/models/app_config.dart` — parse `roomsEnabled`.

---

## BACKEND PHASE

### Task 1: Language normalization helper + alias table

**Why first:** auto-join, seeding, and directory grouping all depend on resolving dirty language values (`English`/`en`/`English (US)`/`Chinese (Simplified)`) to one canonical key. The `languages` collection has NO alias field (reviewer C1), so this is net-new.

**Files:**
- Create: `lib/normalizeLanguage.js`
- Test: `tests/normalizeLanguage.test.js`

- [ ] **Step 1: Confirm the test runner.** Check `package.json` scripts + existing `tests/` (or `__tests__/`) for the framework (jest/mocha). Match it. Run the existing suite once to confirm green baseline: `npm test`.

- [ ] **Step 2: Write the failing test.** Cover the measured dirty inputs.

```js
const { normalizeLanguage, CANONICAL } = require('../lib/normalizeLanguage');

describe('normalizeLanguage', () => {
  test('maps display names to canonical ISO', () => {
    expect(normalizeLanguage('English')).toBe('en');
    expect(normalizeLanguage('English (US)')).toBe('en');
    expect(normalizeLanguage('en')).toBe('en');
    expect(normalizeLanguage('Chinese (Simplified)')).toBe('zh');
    expect(normalizeLanguage('Korean')).toBe('ko');
  });
  test('is case/space tolerant', () => {
    expect(normalizeLanguage('  korean ')).toBe('ko');
  });
  test('returns null for empty/unknown (no auto-join)', () => {
    expect(normalizeLanguage('')).toBeNull();
    expect(normalizeLanguage(null)).toBeNull();
    expect(normalizeLanguage('Klingon')).toBeNull();
  });
});
```

- [ ] **Step 3: Run it, verify it fails** (`Cannot find module`). Run: `npm test -- normalizeLanguage`.

- [ ] **Step 4: Implement.** Hardcoded alias map keyed to the ~8 seeded hub languages plus the top prod variants. Include every dirty variant seen in prod (English/en/English (US); Chinese (Simplified)/Chinese/zh; etc.).

```js
// Canonical hub languages (must match Prompt.language ISO space + seedRooms).
const CANONICAL = ['en', 'ko', 'ja', 'zh', 'ar', 'es', 'de', 'fr'];

const ALIASES = {
  'english': 'en', 'english (us)': 'en', 'english (uk)': 'en', 'en': 'en',
  'korean': 'ko', 'ko': 'ko', '한국어': 'ko',
  'japanese': 'ja', 'ja': 'ja', '日本語': 'ja',
  'chinese': 'zh', 'chinese (simplified)': 'zh', 'chinese (traditional)': 'zh', 'zh': 'zh', '中文': 'zh',
  'arabic': 'ar', 'ar': 'ar',
  'spanish': 'es', 'es': 'es',
  'german': 'de', 'de': 'de',
  'french': 'fr', 'fr': 'fr',
};

function normalizeLanguage(value) {
  if (!value || typeof value !== 'string') return null;
  const key = value.trim().toLowerCase();
  return ALIASES[key] || null;
}

module.exports = { normalizeLanguage, CANONICAL, ALIASES };
```

- [ ] **Step 5: Run test, verify pass.** `npm test -- normalizeLanguage` → PASS.

- [ ] **Step 6: Commit.** `git add lib/normalizeLanguage.js tests/normalizeLanguage.test.js && git commit -m "feat(rooms): canonical language normalization helper"`

---

### Task 2: Conversation hub fields + User.leftHubs + DM-list exclusion

**Files:**
- Modify: `models/Conversation.js`, `models/User.js`, `controllers/conversations.js`
- Test: `tests/conversations.hubExclusion.test.js`

- [ ] **Step 1: Add hub fields to `Conversation` schema.** Additive; defaults keep existing DMs untouched.

```js
// models/Conversation.js — add to schema:
roomType: { type: String, enum: ['hub', null], default: null },
isPublic: { type: Boolean, default: false },
targetLanguage: { type: String, default: null }, // canonical key from normalizeLanguage
title: { type: String },
description: { type: String },
emojiFlag: { type: String },
owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
admins: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
memberCount: { type: Number, default: 0 },
maxMembers: { type: Number, default: 1000 },
lastActivityAt: { type: Date, default: Date.now },
isSeeded: { type: Boolean, default: false },
```

Add an index for directory queries: `ConversationSchema.index({ roomType: 1, targetLanguage: 1, memberCount: -1 });`

- [ ] **Step 2: Add `leftHubs` to `User`.** `leftHubs: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Conversation' }]` (sticky-leave marker, reviewer M2).

- [ ] **Step 3: Write failing test** for `getConversations` excluding hubs.

```js
// Seed a DM conversation and a hub conversation both containing userId.
// Assert getConversations(userId) returns the DM but NOT the hub.
test('getConversations excludes roomType:hub', async () => {
  const res = await getConversationsForUser(userId); // test helper calling the controller logic
  const ids = res.map(c => String(c._id));
  expect(ids).toContain(String(dmConv._id));
  expect(ids).not.toContain(String(hubConv._id));
});
```

- [ ] **Step 4: Run, verify fail.**

- [ ] **Step 5: Implement the filter.** In `controllers/conversations.js` (~line 21), add `roomType: { $ne: 'hub' }` to the query object.

```js
const conversations = await Conversation.find({
  participants: userId,
  deletedBy: { $ne: userId },
  roomType: { $ne: 'hub' }, // hubs live only in the Rooms tab
})
```

- [ ] **Step 6: Run, verify pass.**

- [ ] **Step 7: Commit.** `git commit -am "feat(rooms): hub fields on Conversation, User.leftHubs, exclude hubs from DM list"`

---

### Task 3: Seed migration — system owner + hubs

**Files:**
- Create: `migrations/seedRooms.js`
- Test: `tests/seedRooms.test.js` (or a manual `--dry-run` verification if seed scripts aren't unit-tested here — check how `seedPrompts.js` is tested).

- [ ] **Step 1: Study the pattern.** Read `migrations/seedPrompts.js` for the exact connect/upsert/`--dry-run`/disconnect structure and reuse it verbatim.

- [ ] **Step 2: Write `seedRooms.js`.** First upsert a reserved system owner user (fixed email, `role:'admin'`), then upsert each hub keyed by `targetLanguage`. Idempotent.

```js
// Hubs weighted to measured demand (2026-07-12). targetLanguage MUST be canonical (Task 1).
const HUBS = [
  { targetLanguage: 'en', title: 'English Practice', emojiFlag: '🇬🇧', description: '...' },
  { targetLanguage: 'ko', title: 'Korean Learners',  emojiFlag: '🇰🇷', description: '...' },
  { targetLanguage: 'ja', title: 'Japanese Learners',emojiFlag: '🇯🇵', description: '...' },
  { targetLanguage: 'zh', title: 'Chinese Corner',   emojiFlag: '🇨🇳', description: '...' },
  { targetLanguage: 'ar', title: 'Arabic Room',      emojiFlag: '🇸🇦', description: '...' },
  { targetLanguage: 'es', title: 'Spanish Room',     emojiFlag: '🇪🇸', description: '...' },
  { targetLanguage: 'de', title: 'German Room',      emojiFlag: '🇩🇪', description: '...' },
  { targetLanguage: 'fr', title: 'French Room',      emojiFlag: '🇫🇷', description: '...' },
];
const SYSTEM_OWNER = { email: 'system@bananatalk.internal', name: 'BananaTalk', role: 'admin' };
// upsert owner (findOneAndUpdate by email, upsert:true), then for each hub:
// upsert Conversation by { roomType:'hub', targetLanguage } with owner=owner._id,
// isPublic:true, isSeeded:true, participants:[], memberCount:0, maxMembers:1000.
// Support process.argv.includes('--dry-run') logging without writing.
```

- [ ] **Step 3: Dry-run locally.** `node migrations/seedRooms.js --dry-run` → logs 1 owner + 8 hubs, writes nothing.

- [ ] **Step 4: Idempotency check.** Run for real against a test/staging DB twice; second run reports "updated," not "created," and does not duplicate hubs or inflate counts.

- [ ] **Step 5: Commit.** `git commit -am "feat(rooms): seedRooms migration (system owner + 8 hubs)"`

> **Deploy note:** `node migrations/seedRooms.js` must be run on prod at ship time — add to the pending-server-steps list alongside `seedPrompts.js`.

---

### Task 4: Room REST routes + controllers (directory, detail, history, join/leave, auto-join, admin)

**Files:**
- Create: `controllers/rooms.js`, `routes/rooms.js`
- Modify: route index / `server.js` to mount `/api/v1/rooms`
- Test: `tests/rooms.controller.test.js`

Reuse existing auth middleware (`protect`, `authorize('admin')`) and message pagination from `controllers/messages.js`.

- [ ] **Step 1: Write failing tests** for the core behaviors (one `describe` per endpoint):
  - `GET /rooms` returns hubs sorted with the caller's normalized-target-language hub first.
  - **Auto-join is idempotent:** calling `GET /rooms` twice adds the user to their matching hub exactly once; `memberCount` increments by 1, not 2.
  - **Sticky-leave:** after `POST /rooms/:id/leave`, a subsequent `GET /rooms` does NOT re-add the user (checks `User.leftHubs`).
  - `POST /rooms/:id/join` re-adds and removes the hub from `leftHubs`.
  - Admin-only: `DELETE /rooms/:id/members/:userId` returns 403 for non-admin/owner, 200 for owner/admin.
  - `ROOMS_ENABLED=false` → routes return 404/short-circuit.

- [ ] **Step 2: Run, verify fail.**

- [ ] **Step 3: Implement `controllers/rooms.js`.** Key handlers:
  - `getRooms`: fetch `{ roomType:'hub' }`; run auto-join (below); sort caller's hub first then `memberCount` desc; attach live `onlineCount` (from the socket presence module — Task 5 — via a shared accessor; until Task 5 lands, return 0 and fill in during Task 5).
  - `autoJoinMatchingHub(user)`: `const key = normalizeLanguage(user.language_to_learn); if (!key) return;` find hub by `targetLanguage:key`; if user not in `participants` AND hub `_id` not in `user.leftHubs`, `$addToSet` participant + `$inc memberCount`. Idempotent via `$addToSet`.
  - `joinRoom`: `$addToSet` participant, `$pull` from `user.leftHubs`, `$inc memberCount` only if newly added.
  - `leaveRoom`: `$pull` participant, `$addToSet` hub into `user.leftHubs`, `$inc memberCount:-1` only if was a member.
  - `getRoomMessages`: reuse existing paginated message fetch, filtered by `conversationId`.
  - `removeMember`/`muteMember`/`updateRoom`: owner/admin-gated (reuse `Conversation.mutedBy` methods for mute).

- [ ] **Step 4: Implement `routes/rooms.js`** and mount it. Wrap all routes in a `ROOMS_ENABLED` guard (Task 7 exports the flag).

- [ ] **Step 5: Run tests, verify pass.**

- [ ] **Step 6: Commit.** `git commit -am "feat(rooms): REST routes — directory, history, join/leave, auto-join, admin"`

---

### Task 5: Socket room events + disconnect-safe presence + broadcast message path

**Files:**
- Create: `socket/roomHandler.js`
- Modify: `socket/socketHandler.js` (register handlers + `disconnect` cleanup)
- Test: `tests/rooms.socket.test.js`

- [ ] **Step 1: Study `socketHandler.js`.** Note JWT auth middleware, `userConnections` map, the `sendMessage` token-bucket (capacity 10, 1/s), and the `disconnect` handler. Confirm how a handler module is registered per-connection.

- [ ] **Step 2: Write failing tests** (use `socket.io-client` against an in-process server, mirroring any existing socket test; if none, drive `roomHandler` functions directly with a mocked `io`/`socket`):
  - `room:join` puts the socket in `room_<id>` and broadcasts an increased online count.
  - `room:message` persists a `Message` (isGroupMessage, conversationId) **without** writing `unreadCount[]`/`readBy[]`, and broadcasts to the room.
  - `disconnect` decrements presence for every room the socket was in (no explicit `room:leave`).

- [ ] **Step 3: Run, verify fail.**

- [ ] **Step 4: Implement `roomHandler.js`.**
  - `room:join {roomId}` → `socket.join('room_'+roomId)`; compute online = `io.sockets.adapter.rooms.get('room_'+roomId)?.size ?? 0`; `io.to('room_'+roomId).emit('room:presence', { roomId, online })`.
  - `room:message {roomId, ...}` → apply the existing per-user token bucket; create `Message` `{ conversationId: roomId, sender, isGroupMessage:true, ... }`; update hub `lastActivityAt`; `io.to('room_'+roomId).emit('room:message', message)`. **Do not** fan out `unreadCount`/`readBy`.
  - `room:typing {roomId}` → broadcast ephemeral to room (exclude sender).
  - Export a `getOnlineCount(roomId)` accessor so `controllers/rooms.js:getRooms` can attach live counts (close the Task 4 placeholder).
  - In `socketHandler.js` `disconnect`: for each room the socket was in (`socket.rooms`), after leaving, rebroadcast `room:presence`. Presence is always **derived from adapter room size at emit time** — never a stored counter (reviewer I4).

- [ ] **Step 5: Run tests, verify pass.**

- [ ] **Step 6: Wire the Task 4 online-count placeholder** to `getOnlineCount`. Re-run Task 4 tests.

- [ ] **Step 7: Commit.** `git commit -am "feat(rooms): socket room events + disconnect-safe presence + broadcast path"`

---

### Task 6: Daily prompt job

**Files:**
- Create: `jobs/dailyRoomPromptJob.js`
- Modify: `jobs/scheduler.js`
- Test: `tests/dailyRoomPromptJob.test.js`

- [ ] **Step 1: Study reuse.** Read the day-of-year rotation in `controllers/moments.js:196` and how `prompts` are queried by `language`. Confirm `Prompt.language` is ISO (same canonical space as hub `targetLanguage`).

- [ ] **Step 2: Write failing test.** For each hub, the job creates one `messageType:'system'` `Message` from the system owner with the day's prompt text for that hub's `targetLanguage`; running twice on the same day does not double-post (dedup on hub + date).

- [ ] **Step 3: Run, verify fail.**

- [ ] **Step 4: Implement.** Iterate seeded hubs; for each, select prompt via day-of-year rotation filtered to `Prompt.language === hub.targetLanguage`; if none, skip (log). Create system message, update `lastActivityAt`, broadcast via `io.to('room_'+hubId)`. Dedup guard (e.g., check no system prompt message already posted to that hub today).

- [ ] **Step 5: Schedule it** in `jobs/scheduler.js` next to the other daily jobs (KST morning), following the existing `setTimeout`/`getMillisecondsUntil` pattern.

- [ ] **Step 6: Run tests, verify pass. Commit.** `git commit -am "feat(rooms): daily prompt system message per hub"`

---

### Task 7: ROOMS_ENABLED kill switch + app-config flag + mention push

**Files:**
- Modify: `config/limitations.js`, `controllers/appConfig.js`, mention-notification path
- Test: `tests/rooms.killSwitch.test.js`

- [ ] **Step 1: Add the flag.** In `config/limitations.js`: `const ROOMS_ENABLED = String(process.env.ROOMS_ENABLED || 'true').toLowerCase() === 'true';` and export it. Confirm Task 4/5 guards import it.

- [ ] **Step 2: Emit to client.** In `controllers/appConfig.js`, add `roomsEnabled: ROOMS_ENABLED` to the response payload.

- [ ] **Step 3: Mention-only push.** Confirm hub `room:message` with `mentions[]` triggers the existing mention notification path, and that non-mention room messages send NO push (a 240-member hub must never per-message push). Add a test asserting a plain room message produces zero push sends and a mention produces one.

- [ ] **Step 4: Kill-switch test.** With `ROOMS_ENABLED=false`, room routes 404 and app-config reports `roomsEnabled:false`.

- [ ] **Step 5: Run, verify pass. Commit.** `git commit -am "feat(rooms): ROOMS_ENABLED kill switch + app-config flag + mention-only push"`

**== BACKEND PHASE DONE (T1–T7) ==**

---

## APP PHASE

### Task 8: Socket client room methods

**Files:**
- Modify: `lib/services/chat_socket_service.dart`
- Modify: `lib/models/app_config.dart` (parse `roomsEnabled`)

- [ ] **Step 1:** Add `roomsEnabled` to `AppConfig.fromJson`.
- [ ] **Step 2:** Add to `ChatSocketService`: `joinRoom(roomId)` (emit `room:join`), `leaveRoom(roomId)` (emit `room:leave`), `sendRoomMessage(roomId, payload)`, and `StreamController`s: `onRoomMessage`, `onRoomTyping`, `onRoomPresence`. Register `socket.on('room:message'|'room:typing'|'room:presence')` → add to streams. Follow the existing stream-controller + `emitWithAck` pattern already in the file.
- [ ] **Step 3:** On reconnect, if a room screen is open, re-emit `room:join` (reuse existing reconnection hook).
- [ ] **Step 4:** `flutter analyze` clean. Commit. `git commit -am "feat(rooms): socket client room join/leave/send + streams"`

---

### Task 9: Rooms tab + directory screen

**Files:**
- Create: `lib/models/room.dart`, `lib/services/room_api_client.dart`, `lib/providers/rooms_provider.dart`, `lib/pages/community/rooms/rooms_directory_screen.dart`, `lib/pages/community/rooms/room_card.dart`
- Modify: `lib/pages/community/main/community_tab_bar.dart`, `community_main.dart`

- [ ] **Step 1:** `Room` model (`fromJson`) — id, title, emojiFlag, targetLanguage, memberCount, onlineCount, description, isMember.
- [ ] **Step 2:** `room_api_client.dart` — `getRooms()`, `getRoom(id)`, `getMessages(id, page)`, `join(id)`, `leave(id)`, report/admin calls. Use the existing api_client base + `package:` imports.
- [ ] **Step 3:** `rooms_provider.dart` — Riverpod provider fetching the directory; exposes the caller's auto-joined hub first.
- [ ] **Step 4:** `rooms_directory_screen.dart` — reuse community list/search patterns; render `room_card` rows (name, flag, member count, "N online" dot); your hub pinned first; tap → `room_screen`. Empty/loading states.
- [ ] **Step 5:** Add the 8th tab to `community_tab_bar.dart` (icon `Icons.forum_rounded`, localized label) and its view in `community_main.dart`. **Hide the tab when `appConfig.roomsEnabled == false`.**
- [ ] **Step 6:** `flutter analyze` clean. Commit. `git commit -am "feat(rooms): Rooms tab + directory screen"`

---

### Task 10: Room screen (chat)

**Files:**
- Create: `lib/pages/community/rooms/room_screen.dart`
- Modify: `lib/pages/chat/message/messages_list.dart` (sender attribution)

- [ ] **Step 1:** Extend `ChatMessagesList` (reviewer M1) with an optional `isGroup`/per-message sender (name + avatar) render path. Keep the 1-on-1 path unchanged (backward compatible). `flutter analyze`.
- [ ] **Step 2:** `room_screen.dart` — on open: `join` (REST, if not member) + `chatSocket.joinRoom(id)`; load history via `getMessages` (paginated, infinite scroll); reuse `ChatInputBar` for composing (text/image/sticker); listen to `onRoomMessage`/`onRoomTyping`/`onRoomPresence` and update UI. Pinned daily-prompt card at top. On dispose: `chatSocket.leaveRoom(id)` (socket only; membership persists).
- [ ] **Step 3:** Header shows member count + live online count; overflow menu: leave hub, view members, report.
- [ ] **Step 4:** `flutter analyze` clean. Commit. `git commit -am "feat(rooms): room chat screen + multi-sender message list"`

---

### Task 11: Moderation + report UI

**Files:**
- Modify: `room_screen.dart`, member list widget
- Reuse: existing report sheet (`Report.type:'message'`)

- [ ] **Step 1:** Per-message long-press → report (reuse existing message-report flow with `type:'message'`).
- [ ] **Step 2:** For owner/admin: member list with remove + mute actions calling the Task 4 admin endpoints.
- [ ] **Step 3:** `flutter analyze` clean. Commit. `git commit -am "feat(rooms): per-message report + admin remove/mute UI"`

**== APP PHASE DONE (T8–T11) ==**

---

## GATE

### Task 12: Whole-branch review + manual device smoke + re-measure

- [ ] **Step 1: Automated gate.** Backend: `npm test` all green; `node --check` on new files. App: `flutter analyze` 0 errors; run rooms-related tests.
- [ ] **Step 2: Whole-branch code review.** Dispatch superpowers:requesting-code-review over the full D diff (both repos). Batch fixes in one pass (A/B/C pattern).
- [ ] **Step 3: Seed staging** (`node migrations/seedRooms.js`) and run the **D gate smoke** on two devices:
  - New user auto-joined to their target-language hub on first Rooms open.
  - Two devices chat live in a seeded hub; messages appear in real time.
  - Online count updates on join/leave (and on force-quit — presence decrements).
  - A mention fires exactly one push on the other device; a plain message fires none.
  - Admin removes a member; removed user loses access.
  - Daily prompt appears in each hub.
  - Hubs do NOT appear in the DM/chat list.
- [ ] **Step 4: Re-measure** the 2026-07-12 room queries after a few days live: % of new users sending ≥1 room message in week 1 (target >20%); online concurrency per hub.
- [ ] **Step 5:** On user go-ahead, merge `workstream-d-rooms` → `main` (both repos). Record server steps: run `seedRooms.js` on prod; set `ROOMS_ENABLED`.

---

## Pending server steps (accumulated)
- `node migrations/seedPrompts.js` (from Workstream C — still pending)
- `node migrations/seedRooms.js` (this workstream)
- `REFRESH_TOKEN_SECRET` set on prod (from Workstream A — still pending)
- `ROOMS_ENABLED` env (default on)
