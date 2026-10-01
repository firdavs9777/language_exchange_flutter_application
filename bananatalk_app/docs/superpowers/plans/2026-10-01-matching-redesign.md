# Matching Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Daily Matches tab, the reorganized Community layout, Partners segments, and the in-chat conversation companion — dark-launched, with old app builds untouched.

**Architecture:** Backend first (all additive on the wire), then app. One new endpoint (`GET /matching/daily`) built on the existing `lib/matchScoring.js` aggregation stages, cached per user per UTC day in Redis. New list params ride on the existing `buildUsersQuery`. The app's new layout is gated by an app-config flag using the exact `showRoomsTab` index-remap pattern already in `community_main.dart`.

**Tech Stack:** Node/Express/Mongoose + node:test + mongodb-memory-server (backend); Flutter/Riverpod + flutter_test (app).

**Spec:** `docs/superpowers/specs/2026-10-01-matching-redesign-design.md` (same repo, committed). Read it first — every task below implements a numbered spec section.

**Repos:**
- Backend: `/Users/davis/Desktop/Personal/language_exchange_backend_application` (deploy = push to `main`; Actions SSHes to the droplet)
- App: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

## Global Constraints

- **No existing endpoint, parameter, or response field is removed or renamed. Ever.** New response fields are additive only.
- **All new UI ships dark** behind the app-config flag `matchesLayoutEnabled`; backend endpoint behind env kill switch `DAILY_MATCHES_ENABLED` (default **false**).
- Backend tests run with Node 20 (`~/.nvm/versions/node/v20.20.2/bin/node`), Node 25 breaks `buffer-equal-constant-time`: `~/.nvm/versions/node/v20.20.2/bin/node --test --test-force-exit test/<file>.test.js`.
- Flutter: `package:` imports only, no relative `../../` paths (linter enforces). Analyzer must stay at 0 errors.
- Last-active is ALWAYS a bucket string (`'today' | 'this_week' | null`), never a timestamp, on every new payload.
- Batch size: **6** (spec says 5–8; 6 is the decision).
- Design tokens (spec "Visual reference"): accent `#FFD23F`, ink `#1C1B17`, chip surface `#F5F2E8`, reason tint `#FDF4D7` / text `#8A6D1A`, success `#3F9C58` / `#EAF7EE`, muted `#8A8577`, hairline `#E9E4D6`. Cards radius 16, chips pill, touch targets ≥44px.
- Commit messages end with: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`

## Review Focus

Spec-implied inputs no task's happy path covers — each line's pinning test is added to the owning task:

1. **Blank/equal language users** (170 blank + 25 `en→en` exist in prod): `GET /matching/daily` must return a non-error batch for them (backfill tier), never 500 or `matches: null`. → Task 4 test "a viewer with no usable language pair still gets a batch".
2. **Pool smaller than batch size** (rare pairs at 760 MAU): return what exists, no duplicates, no crash. → Task 4 test "a pool of two returns two".
3. **Same-day determinism across interactions**: after the viewer waves at match #1, re-fetching the batch the same day returns the identical list (cache + seed), not a reshuffle. → Task 5 test "the batch is stable within a day".
4. **responseRate below 3 samples stays `null`**, not 0 — a new user must not render as a ghost. → Task 3 test "fewer than three samples publishes null".
5. **Old build byte-stability**: a `GET /auth/users` request with none of the new params returns every pre-existing key unchanged (new keys additive only). → Task 2 test "legacy request shape is unchanged except additive fields".

---

## BACKEND

### Task 1: Segment + reciprocal params on the user list

**Files:**
- Modify: `controllers/users.js` (inside `buildUsersQuery`, after the language-filter block)
- Modify: `models/User.js` (index block ~line 1947)
- Test: `test/usersSegmentParams.test.js` (create)

**Interfaces:**
- Consumes: `buildUsersQuery(req)` (existing, used by `getUsers` and `getUsersCount` — both get the new params for free, which is the count-parity fix).
- Produces: query params `reciprocal=true`, `activeWithin=7d|30d`, `joinedWithin=7d|30d` on `GET /auth/users` and `GET /auth/users/count`.

- [ ] **Step 1: Write the failing test** (`test/usersSegmentParams.test.js`, copy the harness boilerplate — `run`, `makeUser`, in-memory Mongo `before/after` — from `test/usersListFilters.test.js` verbatim):

```js
test('reciprocal=true returns only perfect-pair partners', async () => {
  // viewer: native English, learning Korean
  const viewer = await makeUser('recipViewer'); // defaults: English -> Korean
  const perfect = await makeUser('recipPerfect', {
    native_language: 'Korean', language_to_learn: 'English',
  });
  const oneWay = await makeUser('recipOneWay', {
    native_language: 'Korean', language_to_learn: 'Japanese',
  });

  const { status, body } = await run(controller.getUsers,
    viewerReq(viewer, { reciprocal: 'true', excludeInteracted: 'false' }));
  assert.equal(status, 200, JSON.stringify(body));
  const names = body.data.map((u) => u.name);
  assert.ok(names.includes(perfect.name));
  assert.ok(!names.includes(oneWay.name), 'one-way partner must not pass reciprocal');
});

test('activeWithin=7d excludes stale users; joinedWithin=7d returns only new ones', async () => {
  const viewer = await makeUser('segViewer');
  const fresh = await makeUser('segFresh', { lastActive: new Date() });
  const stale = await makeUser('segStale', {
    lastActive: new Date(Date.now() - 30 * 24 * 3600 * 1000),
  });
  // joinedWithin uses createdAt, which mongoose sets on create; backdate stale's:
  await mongoose.connection.db.collection('users').updateOne(
    { _id: stale._id },
    { $set: { createdAt: new Date(Date.now() - 60 * 24 * 3600 * 1000) } });

  const active = await run(controller.getUsers,
    viewerReq(viewer, { activeWithin: '7d', excludeInteracted: 'false' }));
  const activeNames = active.body.data.map((u) => u.name);
  assert.ok(activeNames.includes(fresh.name));
  assert.ok(!activeNames.includes(stale.name));

  const joined = await run(controller.getUsers,
    viewerReq(viewer, { joinedWithin: '7d', excludeInteracted: 'false' }));
  const joinedNames = joined.body.data.map((u) => u.name);
  assert.ok(joinedNames.includes(fresh.name));
  assert.ok(!joinedNames.includes(stale.name));
});
```

- [ ] **Step 2: Run to verify failure**

Run: `~/.nvm/versions/node/v20.20.2/bin/node --test --test-force-exit test/usersSegmentParams.test.js`
Expected: FAIL — reciprocal/segment params ignored, all users returned.

- [ ] **Step 3: Implement in `buildUsersQuery`** — add AFTER the existing `matchLanguage` block (search for `// Language exchange filter`), BEFORE the gender filter:

```js
  // Strict reciprocal pair: they speak what I'm learning AND learn what I
  // speak. matchLanguage's OR stays untouched for old builds; this is the
  // additive AND the "perfect partners" surface uses. Uses the viewer's own
  // languages, same normalization as lib/matchLanguage.js.
  if (req.query.reciprocal === 'true' && req.user) {
    const { expandLanguage } = require('../lib/matchLanguage');
    const myNative = expandLanguage(req.user.native_language);
    const myLearning = expandLanguage(req.user.language_to_learn);
    if (myNative.length && myLearning.length) {
      query.$and = [
        ...(query.$and || []),
        { native_language: { $in: myLearning.map(v => new RegExp(`^${v}$`, 'i')) } },
        { language_to_learn: { $in: myNative.map(v => new RegExp(`^${v}$`, 'i')) } },
      ];
    }
  }

  // "Serious learners" / "New members" segments (spec §4). Only the two
  // values the app sends are honored; anything else is ignored.
  const WINDOWS = { '7d': 7, '30d': 30 };
  if (WINDOWS[req.query.activeWithin]) {
    query.lastActive = {
      $gte: new Date(Date.now() - WINDOWS[req.query.activeWithin] * 24 * 3600 * 1000),
    };
  }
  if (WINDOWS[req.query.joinedWithin]) {
    query.createdAt = {
      $gte: new Date(Date.now() - WINDOWS[req.query.joinedWithin] * 24 * 3600 * 1000),
    };
  }
```

> If `lib/matchLanguage.js` has no `expandLanguage` export, check its exports (`matchKey`, name-expansion helper around line 80) and use the helper that maps a stored language value to its acceptable spellings; if none fits, fall back to exact case-insensitive match on the raw strings — do NOT invent a new normalizer.

- [ ] **Step 4: Add the missing indexes** in `models/User.js` next to the existing index block (~line 1947):

```js
UserSchema.index({ createdAt: -1 }); // "New members" segment + future sorts
UserSchema.index({ profileCompleted: 1, lastActive: -1 }); // USABLE_PROFILE list scans
UserSchema.index({ 'vipSubscription.isActive': -1, isOnline: -1, lastActive: -1 }); // the default list sort's exact key order
```

- [ ] **Step 5: Run tests** — new file passes; then the neighbors: `test/usersListFilters.test.js test/usersSmartSort.test.js test/usableProfile.test.js`. All green.

- [ ] **Step 6: Commit** — `feat(community): reciprocal pair + activeWithin/joinedWithin segments on the user list`

### Task 2: lastActive bucket on list payloads

**Files:**
- Create: `lib/lastActiveBucket.js`
- Modify: `controllers/users.js` (`getUsers` response mapping; add `lastSeenAt` handling)
- Test: `test/lastActiveBucket.test.js` (create)

**Interfaces:**
- Produces: `lastActiveBucket(date) -> 'today' | 'this_week' | null`, and an additive `lastActiveBucket` field on every row of `GET /auth/users`. Task 5 reuses the helper.

- [ ] **Step 1: Failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { lastActiveBucket } = require('../lib/lastActiveBucket');

test('buckets, never timestamps', () => {
  assert.equal(lastActiveBucket(new Date()), 'today');
  assert.equal(lastActiveBucket(new Date(Date.now() - 3 * 24 * 3600 * 1000)), 'this_week');
  assert.equal(lastActiveBucket(new Date(Date.now() - 30 * 24 * 3600 * 1000)), null);
  assert.equal(lastActiveBucket(null), null);
  assert.equal(lastActiveBucket('garbage'), null);
});
```

Also, in `test/usersSegmentParams.test.js` (Task 1's file), add the byte-stability pin (Review Focus #5):

```js
test('legacy request shape is unchanged except additive fields', async () => {
  const viewer = await makeUser('legacyViewer');
  await makeUser('legacyRow');
  const { body } = await run(controller.getUsers,
    viewerReq(viewer, { excludeInteracted: 'false' }));
  const row = body.data[0];
  // Every key old builds read is still present:
  for (const key of ['_id', 'name', 'images', 'native_language',
    'language_to_learn', 'isOnline', 'lastActive', 'vipSubscription']) {
    assert.ok(key in row || row[key] === undefined,
      `pre-existing key ${key} must not be renamed`);
  }
  assert.ok(['today', 'this_week', null].includes(row.lastActiveBucket));
});
```

- [ ] **Step 2: Run, verify FAIL** (module not found).

- [ ] **Step 3: Implement `lib/lastActiveBucket.js`:**

```js
'use strict';

/**
 * The only form last-activity ever takes on a card payload. Buckets, never
 * timestamps: "active today" is a liveness signal, a precise clock reading
 * is surveillance.
 */
const DAY_MS = 24 * 60 * 60 * 1000;

function lastActiveBucket(value) {
  if (!value) return null;
  const t = new Date(value).getTime();
  if (Number.isNaN(t)) return null;
  const age = Date.now() - t;
  if (age <= DAY_MS) return 'today';
  if (age <= 7 * DAY_MS) return 'this_week';
  return null;
}

module.exports = { lastActiveBucket };
```

- [ ] **Step 4: Stamp it onto the list response** in `getUsers` — find the response mapping that builds `data` rows (after the query executes, where `processUserImages` runs) and add to each row object:

```js
const { lastActiveBucket } = require('../lib/lastActiveBucket'); // top of file
// in the row mapping:
lastActiveBucket: lastActiveBucket(user.lastActive),
```

- [ ] **Step 5: Run both test files; green. Commit** — `feat(community): bucketed lastActive on list rows`

### Task 3: responseRate — field, job, payload

**Files:**
- Modify: `models/User.js` (add field near `lastSeenAt`, ~line 788)
- Create: `services/responseRateService.js`
- Create: `jobs/responseRateJob.js`
- Modify: `jobs/scheduler.js` (register, same pattern as `waveDailySummaryJob`)
- Modify: `controllers/users.js` (`USER_LIST_FIELDS`: append `responseRate`)
- Test: `test/responseRate.test.js` (create)

**Interfaces:**
- Produces: `User.responseRate: Number|null`, `computeResponseRates() -> {updated}` (service), additive `responseRate` on `GET /auth/users` rows. Tasks 4–5 include it in match cards; the app's dead "Replies fast" tag reads it.

- [ ] **Step 1: User field** (next to `lastSeenAt`):

```js
  // Share of first-messages received that got any reply within 48h,
  // trailing 30 days. null until >=3 samples — a new user is unknown, not
  // a ghost. Written only by jobs/responseRateJob.js.
  responseRate: { type: Number, default: null, min: 0, max: 1 },
```

- [ ] **Step 2: Failing test** (in-memory harness as in Task 1; needs `Message` + `Conversation` imports):

```js
test('replying within 48h counts; fewer than three samples publishes null', async () => {
  const ghost = await makeUser('rrGhost');
  const replier = await makeUser('rrReplier');
  const senders = await Promise.all([1, 2, 3].map((i) => makeUser(`rrSender${i}`)));

  // three conversations each: replier answers, ghost never does
  for (const target of [replier, ghost]) {
    for (const s of senders) {
      const conv = await Conversation.create({ participants: [s._id, target._id], isGroup: false });
      await Message.create({
        conversationId: conv._id, sender: s._id, receiver: target._id,
        message: 'hi', messageType: 'text', participants: [],
      });
      if (target === replier) {
        await Message.create({
          conversationId: conv._id, sender: target._id, receiver: s._id,
          message: 'hello!', messageType: 'text', participants: [],
        });
      }
    }
  }
  // a user with only ONE received first-message: sample too small
  const sparse = await makeUser('rrSparse');
  const conv = await Conversation.create({ participants: [senders[0]._id, sparse._id], isGroup: false });
  await Message.create({
    conversationId: conv._id, sender: senders[0]._id, receiver: sparse._id,
    message: 'hey', messageType: 'text', participants: [],
  });

  const { computeResponseRates } = require('../services/responseRateService');
  await computeResponseRates();

  assert.equal((await User.findById(replier._id).lean()).responseRate, 1);
  assert.equal((await User.findById(ghost._id).lean()).responseRate, 0);
  assert.equal((await User.findById(sparse._id).lean()).responseRate, null,
    'fewer than three samples must stay null');
});
```

- [ ] **Step 3: Run, FAIL. Implement `services/responseRateService.js`:**

```js
'use strict';

const Message = require('../models/Message');
const User = require('../models/User');

const WINDOW_DAYS = 30;
const REPLY_HOURS = 48;
const MIN_SAMPLES = 3;

/**
 * responseRate = replied-to-within-48h / first-messages-received, trailing
 * 30 days, per user. Published only at >=3 samples; everyone else is reset
 * to null (unknown, not zero). Group/hub messages never count.
 */
async function computeResponseRates() {
  const since = new Date(Date.now() - WINDOW_DAYS * 24 * 3600 * 1000);

  const conversations = await Message.aggregate([
    { $match: { createdAt: { $gte: since }, isGroupMessage: { $ne: true } } },
    { $sort: { createdAt: 1 } },
    { $group: {
      _id: '$conversationId',
      firstSender: { $first: '$sender' },
      firstReceiver: { $first: '$receiver' },
      firstAt: { $first: '$createdAt' },
      msgs: { $push: { sender: '$sender', at: '$createdAt' } },
    } },
  ]);

  const received = new Map(); // receiverId -> { samples, replied }
  for (const conv of conversations) {
    if (!conv.firstReceiver) continue;
    const receiver = String(conv.firstReceiver);
    const deadline = conv.firstAt.getTime() + REPLY_HOURS * 3600 * 1000;
    const replied = conv.msgs.some((m) =>
      String(m.sender) === receiver && m.at.getTime() <= deadline);
    const entry = received.get(receiver) || { samples: 0, replied: 0 };
    entry.samples += 1;
    if (replied) entry.replied += 1;
    received.set(receiver, entry);
  }

  const ops = [];
  for (const [userId, { samples, replied }] of received) {
    ops.push({
      updateOne: {
        filter: { _id: userId },
        update: { $set: { responseRate: samples >= MIN_SAMPLES ? replied / samples : null } },
      },
    });
  }
  if (ops.length) await User.bulkWrite(ops, { ordered: false });
  return { updated: ops.length };
}

module.exports = { computeResponseRates, MIN_SAMPLES };
```

- [ ] **Step 4: Job + registration.** `jobs/responseRateJob.js`:

```js
'use strict';

const { computeResponseRates } = require('../services/responseRateService');

async function runResponseRateJob() {
  try {
    const { updated } = await computeResponseRates();
    console.log(`📊 responseRate recomputed for ${updated} users`);
  } catch (err) {
    console.error('responseRate job failed:', err.message);
  }
}

module.exports = { runResponseRateJob };
```

In `jobs/scheduler.js`: import it and schedule nightly exactly the way `runWeeklyDigest`/`waveDailySummaryJob` are scheduled in that file (daily timer helper already exists there — follow the `scheduleInactivityJob` pattern, 04:00 server time).

- [ ] **Step 5: Expose on the list**: in `controllers/users.js` append `responseRate` to `USER_LIST_FIELDS` (the string constant at ~line 33).

- [ ] **Step 6: Run tests (`test/responseRate.test.js` + Task 1/2 files). Green. Commit** — `feat(matching): nightly responseRate, published on list rows`

### Task 4: Daily batch logic (pure)

**Files:**
- Create: `lib/dailyMatches.js`
- Test: `test/dailyMatches.test.js` (create)

**Interfaces:**
- Consumes: `scoringStages` from `lib/matchScoring.js` is NOT used here — this module is pure selection over already-scored candidates (Task 5 does the aggregation).
- Produces:
  - `dailySeed(userId, date) -> number` (deterministic),
  - `selectDailyBatch({ candidates, seed, batchSize = 6 }) -> candidates[]`,
  - `structuredReasons(viewer, candidate) -> string[]` (keys like `reciprocal_pair`, `same_target_language`, `shared_topic:<topic>`, `active_today`, `same_city`).

- [ ] **Step 1: Failing tests:**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { dailySeed, selectDailyBatch, structuredReasons } = require('../lib/dailyMatches');

const cand = (id, score, extra = {}) => ({ _id: id, matchScore: score, ...extra });

test('the seed is stable per (user, day) and differs across days', () => {
  assert.equal(dailySeed('u1', '2026-10-01'), dailySeed('u1', '2026-10-01'));
  assert.notEqual(dailySeed('u1', '2026-10-01'), dailySeed('u1', '2026-10-02'));
  assert.notEqual(dailySeed('u1', '2026-10-01'), dailySeed('u2', '2026-10-01'));
});

test('selection is deterministic for a seed and capped at batchSize', () => {
  const pool = Array.from({ length: 40 }, (_, i) => cand(`c${i}`, 100 - i));
  const a = selectDailyBatch({ candidates: pool, seed: 7 });
  const b = selectDailyBatch({ candidates: pool, seed: 7 });
  assert.deepEqual(a.map(c => c._id), b.map(c => c._id));
  assert.equal(a.length, 6);
});

test('a pool of two returns two — no duplicates, no crash', () => {
  const out = selectDailyBatch({ candidates: [cand('a', 5), cand('b', 3)], seed: 1 });
  assert.deepEqual(new Set(out.map(c => c._id)).size, out.length);
  assert.equal(out.length, 2);
});

test('reasons are structured keys', () => {
  const viewer = {
    native_language: 'English', language_to_learn: 'Korean',
    topics: ['travel', 'movies'], location: { city: 'Seoul' },
  };
  const candidate = {
    native_language: 'Korean', language_to_learn: 'English',
    topics: ['travel'], location: { city: 'Seoul' },
    lastActive: new Date(),
  };
  const reasons = structuredReasons(viewer, candidate);
  assert.ok(reasons.includes('reciprocal_pair'));
  assert.ok(reasons.includes('shared_topic:travel'));
  assert.ok(reasons.includes('active_today'));
  assert.ok(reasons.includes('same_city'));
});
```

- [ ] **Step 2: Run, FAIL. Implement `lib/dailyMatches.js`:**

```js
'use strict';

/**
 * Pure selection for the Daily Matches batch (spec §2). No database here —
 * controllers/matching.js hands in scored candidates; this module decides
 * which 6, deterministically for the (viewer, UTC-day) pair, and says WHY
 * in structured keys the client renders through localized templates.
 */
const { matchKey } = require('./matchLanguage');
const { lastActiveBucket } = require('./lastActiveBucket');

const BATCH_SIZE = 6;

// FNV-1a over `${userId}:${date}` — the same determinism trick getUsers'
// smart sort uses, dependency-free.
function dailySeed(userId, dateString) {
  const s = `${userId}:${dateString}`;
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h;
}

// Deterministic PRNG from the seed (mulberry32).
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Jitter-rank the scored pool and take the top slice. Candidates arrive
 * pre-scored and pre-filtered (exclusions already applied); the jitter
 * keeps the same heavy hitters from owning every user's batch while the
 * seed keeps one user's batch stable all day.
 */
function selectDailyBatch({ candidates, seed, batchSize = BATCH_SIZE }) {
  const random = rng(seed);
  return [...(candidates || [])]
    .map((c) => ({ c, key: (c.matchScore || 0) + random() * 10 }))
    .sort((a, b) => b.key - a.key)
    .slice(0, batchSize)
    .map(({ c }) => c);
}

function structuredReasons(viewer, candidate) {
  const reasons = [];
  const vNative = matchKey(viewer.native_language);
  const vLearning = matchKey(viewer.language_to_learn);
  const cNative = matchKey(candidate.native_language);
  const cLearning = matchKey(candidate.language_to_learn);

  if (vNative && vLearning && cNative === vLearning && cLearning === vNative) {
    reasons.push('reciprocal_pair');
  } else if (vLearning && cNative === vLearning) {
    reasons.push('same_target_language');
  }

  const vTopics = new Set((viewer.topics || []).map(String));
  for (const topic of candidate.topics || []) {
    if (vTopics.has(String(topic)) && reasons.length < 4) {
      reasons.push(`shared_topic:${topic}`);
    }
  }

  if (lastActiveBucket(candidate.lastActive) === 'today') reasons.push('active_today');

  const vCity = viewer.location && viewer.location.city;
  const cCity = candidate.location && candidate.location.city;
  if (vCity && cCity && vCity === cCity) reasons.push('same_city');

  return reasons;
}

module.exports = { dailySeed, selectDailyBatch, structuredReasons, BATCH_SIZE };
```

- [ ] **Step 3: Run tests, green. Commit** — `feat(matching): pure daily-batch selection + structured reasons`

### Task 5: GET /matching/daily

**Files:**
- Modify: `controllers/matching.js` (new export `getDailyMatches`, reusing that file's existing candidate pipeline pieces)
- Modify: `routes/matching.js` (add route)
- Modify: `config/limitations.js` (add `DAILY_MATCHES_ENABLED`, default false, same shape as `SMART_SORT_ENABLED` line 27 + export line ~90)
- Test: `test/matchingDaily.test.js` (create)

**Interfaces:**
- Consumes: `scoringStages` (`lib/matchScoring.js`), `dailySeed/selectDailyBatch/structuredReasons/BATCH_SIZE` (Task 4), `lastActiveBucket` (Task 2), `recordImpressions` (`lib/matchImpressions.js`), `cache = require('../services/redisService')`, `USABLE_PROFILE` (`lib/userVisibility.js`), `MatchImpression` model, `getBlockedUserIds`.
- Produces: `GET /api/v1/matching/daily` →

```json
{ "success": true, "date": "2026-10-01",
  "matches": [{ "user": { "<USER_LIST_FIELDS projection>": "..." },
                "matchReasons": ["reciprocal_pair"], "reciprocal": true,
                "lastActiveBucket": "today", "responseRate": 0.8 }],
  "nextRefreshAt": "2026-10-02T00:00:00.000Z" }
```

- [ ] **Step 1: Failing tests** (in-memory harness; set `process.env.DAILY_MATCHES_ENABLED = 'true'` BEFORE requiring `config/limitations` — and note that config caches on require, so set env at the very top of the test file):

```js
test('kill switch off → 404', async () => { /* re-require with env false via
  delete require.cache — copy the pattern from test/rooms.killSwitch.test.js */ });

test('returns up to 6 usable, scored matches with structured reasons', async () => {
  const viewer = await makeUser('dmViewer'); // English -> Korean
  for (let i = 0; i < 10; i++) {
    await makeUser(`dmKorean${i}`, {
      native_language: 'Korean', language_to_learn: 'English',
      profileCompleted: true, images: ['x.jpg'], lastActive: new Date(),
    });
  }
  const { status, body } = await run(matching.getDailyMatches, viewerReq(viewer, {}));
  assert.equal(status, 200, JSON.stringify(body));
  assert.equal(body.matches.length, 6);
  assert.ok(body.matches[0].matchReasons.includes('reciprocal_pair'));
  assert.ok(['today', 'this_week', null].includes(body.matches[0].lastActiveBucket));
  assert.ok(body.matches.every(m => m.user && m.user.name));
  assert.ok(body.nextRefreshAt);
});

test('the batch is stable within a day', async () => {
  const viewer = await makeUser('dmStable');
  for (let i = 0; i < 12; i++) {
    await makeUser(`dmPool${i}`, {
      native_language: 'Korean', language_to_learn: 'English',
      profileCompleted: true, images: ['x.jpg'], lastActive: new Date(),
    });
  }
  const first = await run(matching.getDailyMatches, viewerReq(viewer, {}));
  const second = await run(matching.getDailyMatches, viewerReq(viewer, {}));
  assert.deepEqual(
    first.body.matches.map(m => m.user._id),
    second.body.matches.map(m => m.user._id));
});

test('a viewer with no usable language pair still gets a batch', async () => {
  const blankViewer = await makeUser('dmBlankView');
  blankViewer.native_language = 'English';
  blankViewer.language_to_learn = 'English'; // en→en, 25 such users in prod
  await blankViewer.save();
  for (let i = 0; i < 4; i++) {
    await makeUser(`dmAny${i}`, {
      profileCompleted: true, images: ['x.jpg'], lastActive: new Date(),
    });
  }
  const { status, body } = await run(matching.getDailyMatches, viewerReq(blankViewer, {}));
  assert.equal(status, 200, JSON.stringify(body));
  assert.ok(Array.isArray(body.matches));
  assert.ok(body.matches.length > 0, 'backfill tier must serve even en→en viewers');
});

test('users shown in a batch in the last 7 days are excluded', async () => {
  const viewer = await makeUser('dmSeen');
  const shown = await makeUser('dmShownBefore', {
    native_language: 'Korean', language_to_learn: 'English',
    profileCompleted: true, images: ['x.jpg'], lastActive: new Date(),
  });
  await MatchImpression.create({
    viewer: viewer._id, shown: shown._id, rank: 0, source: 'daily',
    createdAt: new Date(Date.now() - 2 * 24 * 3600 * 1000),
  });
  const { body } = await run(matching.getDailyMatches, viewerReq(viewer, {}));
  assert.ok(!body.matches.some(m => String(m.user._id) === String(shown._id)));
});
```

> Check `models/MatchImpression.js` required fields before writing the fixture; add `source: { type: String, default: 'recommendations' }` to the schema if no field distinguishes daily rows (additive, default preserves existing rows), and have the controller write `source: 'daily'`.

- [ ] **Step 2: Run, FAIL. Implement `getDailyMatches` in `controllers/matching.js`:**

```js
/**
 * @desc    Today's batch (spec §2). Deterministic per (viewer, UTC day),
 *          computed on first request of the day, cached until midnight UTC.
 * @route   GET /api/v1/matching/daily
 * @access  Private (DAILY_MATCHES_ENABLED)
 */
exports.getDailyMatches = asyncHandler(async (req, res, next) => {
  const { DAILY_MATCHES_ENABLED } = require('../config/limitations');
  if (!DAILY_MATCHES_ENABLED) {
    return next(new ErrorResponse('Not found', 404));
  }

  const viewer = req.user;
  const userId = viewer._id;
  const today = new Date().toISOString().slice(0, 10); // UTC day
  const cacheKey = `dailyMatches:${userId}:${today}`;

  const cached = await cache.get(cacheKey, async () => null, 1);
  if (cached) {
    return res.status(200).json({ ...cached, cached: true });
  }

  const { dailySeed, selectDailyBatch, structuredReasons, BATCH_SIZE } =
    require('../lib/dailyMatches');
  const { lastActiveBucket } = require('../lib/lastActiveBucket');
  const { USABLE_PROFILE } = require('../lib/userVisibility');

  // Exclusions: blocked (both ways), messaged in 14d, shown in a daily
  // batch in 7d, self.
  const [blockedIds, recentPartners, recentImpressions] = await Promise.all([
    getBlockedUserIds(userId).then(Array.from),
    Message.distinct('receiver', {
      sender: userId,
      createdAt: { $gte: new Date(Date.now() - 14 * 24 * 3600 * 1000) },
    }),
    MatchImpression.distinct('shown', {
      viewer: userId,
      source: 'daily',
      createdAt: { $gte: new Date(Date.now() - 7 * 24 * 3600 * 1000) },
    }),
  ]);
  const excluded = [...new Set([
    String(userId),
    ...blockedIds.map(String),
    ...recentPartners.map(String),
    ...recentImpressions.map(String),
  ])].map((id) => new mongoose.Types.ObjectId(id));

  // Scored candidate pool: same stages as /recommendations, no jitter
  // (determinism comes from selectDailyBatch's seeded jitter), capped pool.
  const POOL = 60;
  const candidates = await User.aggregate([
    { $match: {
      _id: { $nin: excluded },
      ...USABLE_PROFILE,
      'images.0': { $exists: true },
    } },
    ...scoringStages({ viewer, seenIds: [], viewerIntents: viewer.intents, randomJitter: 0 }),
    { $sort: { matchScore: -1, lastActive: -1 } },
    { $limit: POOL },
    { $project: Object.fromEntries(
      [...USER_LIST_FIELDS_ARRAY, 'matchScore', 'topics', 'responseRate']
        .map((f) => [f, 1])) },
  ]);

  // Backfill honesty (Review Focus #1): if nothing scored above zero (blank
  // or same-language viewers), the pool is simply the most recently active
  // usable profiles — the $match above already produced them; no extra query.
  const batch = selectDailyBatch({
    candidates,
    seed: dailySeed(String(userId), today),
    batchSize: BATCH_SIZE,
  });

  const vNative = matchKey(viewer.native_language);
  const vLearning = matchKey(viewer.language_to_learn);
  const matches = batch.map((c) => ({
    user: stripScoringFields(c), // remove matchScore/languageScore etc. — same stripping /recommendations does before caching
    matchReasons: structuredReasons(viewer, c),
    reciprocal: Boolean(vNative && vLearning &&
      matchKey(c.native_language) === vLearning &&
      matchKey(c.language_to_learn) === vNative),
    lastActiveBucket: lastActiveBucket(c.lastActive),
    responseRate: typeof c.responseRate === 'number' ? c.responseRate : null,
  }));

  const nextRefreshAt = new Date(`${today}T00:00:00.000Z`);
  nextRefreshAt.setUTCDate(nextRefreshAt.getUTCDate() + 1);

  const payload = { success: true, date: today, matches, nextRefreshAt };

  // Cache until UTC midnight.
  const ttlSeconds = Math.max(60, Math.floor((nextRefreshAt - Date.now()) / 1000));
  await cache.set?.(cacheKey, payload, ttlSeconds)
    ?? cache.get(cacheKey, async () => payload, ttlSeconds);

  // Impressions: fire-and-forget, source 'daily'.
  recordImpressions({ viewer, shown: batch, source: 'daily' })
    .catch((err) => console.error('daily impressions failed:', err.message));

  res.status(200).json(payload);
});
```

> Implementation notes for the engineer (verify, don't guess):
> - `USER_LIST_FIELDS_ARRAY`: build from `require('./users')`'s exported constant if exported; otherwise copy the field list from `controllers/users.js:33` into a local constant — do not diverge from it.
> - `stripScoringFields`: `controllers/matching.js` already strips scores before caching `/recommendations` (comment near line 236). Reuse that exact helper/inline shape.
> - `cache` is `services/redisService`; read its API — if it only exposes `get(key, fallbackFn, ttl)`, use the fallback-write form shown in the `??` branch and delete the `cache.set` branch.
> - `recordImpressions` currently takes `{viewer, shown}` — extend `lib/matchImpressions.js` to accept and persist `source` (additive param, default `'recommendations'`).

- [ ] **Step 3: Route** in `routes/matching.js`: `router.get('/daily', getDailyMatches);` (file already applies `protect` globally — verify, mirror `/recommendations`).

- [ ] **Step 4: Run `test/matchingDaily.test.js` + `test/matchingRecommendations.test.js`; green.**

- [ ] **Step 5: Commit** — `feat(matching): GET /matching/daily — deterministic daily batch behind DAILY_MATCHES_ENABLED`

### Task 6: appConfig flag for the new layout

**Files:**
- Modify: `config/limitations.js` (add `MATCHES_LAYOUT_ENABLED`, default false; export)
- Modify: `controllers/appConfig.js` (add `matchesLayoutEnabled: MATCHES_LAYOUT_ENABLED` beside `smartSortEnabled` at line 63)
- Test: extend `test/` appConfig test if one exists (`grep -l appConfig test/`), else add assertions to `test/matchingDaily.test.js`:

```js
test('appConfig exposes matchesLayoutEnabled', async () => {
  // re-require pattern as in the kill-switch test
  const { getAppConfig } = require('../controllers/appConfig');
  const { body } = await run(getAppConfig, { query: {}, user: null });
  assert.ok('matchesLayoutEnabled' in body.data);
});
```

- [ ] Steps: failing test → implement → green → **Commit** — `feat(config): matchesLayoutEnabled app-config flag`

---

## APP

### Task 7: AppConfig flag + design tokens

**Files:**
- Modify: `lib/models/app_config.dart` (add `matchesLayoutEnabled`, default **false** — this flag turns the layout ON, so the safe default is off; parse like `smartSortEnabled`)
- Modify: `lib/theme/app_colors.dart` (locate with `grep -rn "class AppColors" lib/`) — append the matching tokens:

```dart
  // Matching redesign tokens (spec 2026-10-01, "Visual reference")
  static const Color matchAccent = Color(0xFFFFD23F);
  static const Color matchInk = Color(0xFF1C1B17);
  static const Color matchChipSurface = Color(0xFFF5F2E8);
  static const Color matchReasonTint = Color(0xFFFDF4D7);
  static const Color matchReasonText = Color(0xFF8A6D1A);
  static const Color matchSuccess = Color(0xFF3F9C58);
  static const Color matchSuccessTint = Color(0xFFEAF7EE);
  static const Color matchMutedText = Color(0xFF8A8577);
  static const Color matchHairline = Color(0xFFE9E4D6);
```

- Test: `test/matching/app_config_flag_test.dart` — `AppConfig.fromJson({'matchesLayoutEnabled': true})` parses true; absent → false.
- [ ] Failing test → implement → `flutter test test/matching/` green → analyzer 0 errors → **Commit** — `feat(matching): layout flag + design tokens`

### Task 8: DailyMatch model + service + provider

**Files:**
- Create: `lib/providers/provider_models/daily_match_model.dart`
- Create: `lib/services/matching_daily_service.dart`
- Create: `lib/providers/provider_root/daily_matches_provider.dart`
- Test: `test/matching/daily_match_model_test.dart`

**Interfaces:**
- Produces: `DailyMatch { Community user; List<String> matchReasons; bool reciprocal; String? lastActiveBucket; double? responseRate; }`, `DailyMatchesResult { DateTime? nextRefreshAt; List<DailyMatch> matches; }`, `dailyMatchesProvider` (Riverpod `FutureProvider<DailyMatchesResult>`), `MatchingDailyService.getDaily()` hitting `GET matching/daily` **with the auth token** (copy the token pattern from `moments_providers.dart:36-50`).

- [ ] **Step 1: Failing model test** (follow the defensive-parse house style — maps parse, anything else skipped, never crash):

```dart
test('DailyMatch.fromJson tolerates junk and parses the contract', () {
  final match = DailyMatch.fromJson({
    'user': {'_id': 'u1', 'name': 'Minji', 'native_language': 'Korean',
             'language_to_learn': 'English'},
    'matchReasons': ['reciprocal_pair', 'shared_topic:travel', 42],
    'reciprocal': true,
    'lastActiveBucket': 'today',
    'responseRate': 0.8,
  });
  expect(match.user.name, 'Minji');
  expect(match.matchReasons, ['reciprocal_pair', 'shared_topic:travel']);
  expect(match.reciprocal, true);
  expect(match.lastActiveBucket, 'today');
  expect(match.responseRate, 0.8);

  // user as a bare id string must NOT crash (the Moments lesson):
  final degenerate = DailyMatch.fromJson({'user': 'u2'});
  expect(degenerate.user.name, isNotEmpty); // stub user, no throw
});
```

- [ ] **Step 2: Implement.** `fromJson` rules: `user` → `Community.fromJson` when Map, stub `Community` otherwise (copy the stub-construction from `Comment.fromJson` in `moments_model.dart:526`); `matchReasons` → `whereType<String>()`; `responseRate` → `(json['responseRate'] as num?)?.toDouble()`; `lastActiveBucket` → String or null. Service: parse `{date, matches, nextRefreshAt}`; non-200 or kill-switch 404 → `DailyMatchesResult.empty` with an `unavailable` flag the tab uses to hide itself gracefully.
- [ ] **Step 3: Test green, analyzer clean, Commit** — `feat(matching): daily matches model/service/provider`

### Task 9: Matches tab UI

**Files:**
- Create: `lib/pages/community/tabs/matches_tab.dart`
- Create: `lib/pages/community/card/match_card.dart`
- Create: `lib/pages/community/card/match_reason_chips.dart`
- Modify: `lib/l10n/app_en.arb` (then `flutter gen-l10n`; other locales fall back per existing config — check `untranslated-messages-file` handling in `l10n.yaml`, and add the same keys to the other `.arb` files with English values if the build requires full coverage)
- Test: `test/matching/match_card_test.dart`

**Interfaces:**
- Consumes: `dailyMatchesProvider`, `DailyMatch` (Task 8), tokens (Task 7), the existing wave sheet (`send_wave_sheet.dart`) and `ChatScreen` route (`chat_conversation_screen.dart:50`).
- Produces: `MatchesTab` widget (self-contained; later mounted by Task 10), `MatchCard({required DailyMatch match, required VoidCallback onSayHi, required VoidCallback onWave, required VoidCallback onSkip})`.

Card layout = mockup `Main.dc.html` (artifact linked in the spec): avatar 56, name+flag+presence dot row, pair pill, reason chips (localized from keys below), actions row — `Say hi` (accent, 44px), `Wave`, `Skip` (understated). Reason key → l10n mapping:

```json
"matchReasonReciprocal": "You're learning each other's language",
"matchReasonSameTarget": "Also learning {language}",
"matchReasonSharedTopic": "Shared interest: {topic}",
"matchReasonActiveToday": "Active today",
"matchReasonSameCity": "Lives in your city",
"matchRepliesFast": "Replies fast",
"matchesTodayTitle": "Your {count} matches today",
"matchesRefreshHint": "refreshes at midnight",
"matchesEmptyTitle": "That's everyone for today",
"matchesEmptyBody": "Fresh matches tomorrow. Meanwhile, browse all partners.",
"matchesEmptyCta": "Browse partners"
```

`shared_topic:<topic>` parses on `:`; unknown keys render nothing (forward-compatible). "Replies fast" chip shows when `responseRate != null && responseRate >= 0.7`. Skip = remove locally + call the existing `InteractionService` skip method (find with `grep -rn "skip" lib/services/interaction_service.dart`).

- [ ] Widget test (pump `MatchCard` with a reciprocal match; expect reason text, Say hi button, tap fires callback; `responseRate: 0.9` shows Replies fast; `lastActiveBucket: null` shows no presence line) → implement → green → **Commit** — `feat(matching): Matches tab, match cards, reason chips`

### Task 10: Community layout swap behind the flag

**Files:**
- Modify: `lib/pages/community/main/community_main.dart` (TabBarView children + controller length, flag-driven; follow `_syncTabCountWithRoomsFlag` and `remapTabIndexForRoomsFlag` — the file documents the index-remap contract at `community_tab_bar.dart:51-57`)
- Modify: `lib/pages/community/main/community_tab_bar.dart` (labels list, flag-driven)
- Modify: `lib/pages/community/main/community_app_bar.dart:96` (hide the "Find partners" overflow item when the new layout is on — the Matches tab replaces it)
- Test: `test/matching/community_layout_test.dart`

Behavior:
- Flag OFF (default): **exactly today's layout** — 8 tabs, byte-identical behavior. The test pins this.
- Flag ON: `Matches · Partners · Gatherings · [Rooms] · Nearby · Topics · Waves` — Matches is index 0 and initial tab; Gender and City tabs absent; `All` label becomes `Partners`; Rooms still obeys `roomsEnabled`.

- [ ] Widget test:

```dart
testWidgets('flag off keeps the legacy 8-tab layout', (tester) async { /* pump with
  AppConfig(matchesLayoutEnabled: false); expect find.text('Gender'), find.text('City') */ });
testWidgets('flag on: Matches first, Gender and City gone', (tester) async { /* pump with
  flag true; expect find.text('Matches'); expect(find.text('Gender'), findsNothing); */ });
```

- [ ] Implement → green, analyzer clean → **Commit** — `feat(community): flag-gated Matches-first layout`

### Task 11: Partners segment chips

**Files:**
- Modify: `lib/providers/provider_root/community_provider.dart` — `PartnerFilterParams` (line 1045) gains `final bool reciprocal; final String? activeWithin; final String? joinedWithin;` (constructor defaults `false`/null; include in `==`/`hashCode`/`copyWith`); `loadWithFilters`/`loadMore` pass them; `CommunityService.getCommunityPaginated` appends `reciprocal=true`, `activeWithin=7d`, `joinedWithin=7d` query params when set (find the URL builder with `grep -n getCommunityPaginated lib/providers/provider_root/community_provider.dart`).
- Modify: `lib/pages/community/tabs/partner_discovery_tab.dart` — chip row above the list (mockup `Partners.dc.html`): `All` (clears both), `Serious learners` (`activeWithin='7d'` + `reciprocal` untouched), `New members` (`joinedWithin='7d'`). Mutually exclusive chips; the explainer line under the active segment uses l10n keys:

```json
"segmentAll": "All",
"segmentSerious": "Serious learners",
"segmentNew": "New members",
"segmentSeriousHint": "Complete profile · active this week · replies to messages",
"segmentNewHint": "Joined in the last 7 days"
```

- Also send the same params to `/users/count` (the filter sheet count — find with `grep -n "users/count" lib/`), keeping count and list consistent (spec §4).
- Test: `test/matching/partner_segments_test.dart` — `PartnerFilterParams(activeWithin: '7d') != PartnerFilterParams()`; chip tap updates provider state (widget test on the chip row with a mocked notifier).

- [ ] Failing test → implement → green → **Commit** — `feat(community): Serious learners / New members segments`

### Task 12: Opener chips in new chats

**Files:**
- Create: `lib/widgets/chat/opener_chips.dart`
- Modify: `lib/pages/chat/conversation/chat_conversation_screen.dart` (render above the composer when the thread has zero messages; the screen already knows both users' profiles — find the partner `Community` object in its state)
- Modify: `lib/l10n/app_en.arb`
- Test: `test/matching/opener_chips_test.dart`

**Interfaces:**
- Produces: `OpenerChips({required Community me, required Community partner, required ValueChanged<String> onPick})` — computes 2–3 openers from overlap, `onPick` fills the composer (**editable, never auto-send**: the callback sets the text controller, nothing more).

Opener selection rules (pure, testable — put the logic in a static `List<String> buildOpeners(AppLocalizations l10n, Community me, Community partner)`):
1. If reciprocal pair → `openerReciprocal` ("Want to do half-{theirLanguage} half-{myLanguage} messages? I'll correct yours if you correct mine 😄").
2. First shared topic → `openerSharedTopic` ("I saw you're into {topic} — what got you started?").
3. Always last → `openerGeneric` ("Hi {name}! I'm learning {language} — got any tips? 👋").
Max 3, no duplicates.

```json
"openerReciprocal": "Want to do half-{theirLanguage} half-{myLanguage} messages? I'll correct yours if you correct mine 😄",
"openerSharedTopic": "I saw you're into {topic} — what got you started?",
"openerGeneric": "Hi {name}! I'm learning {language} — got any tips? 👋",
"openerChipsTitle": "Conversation starters — tap to edit before sending"
```

- [ ] Unit test `buildOpeners` (reciprocal + shared topic → 3 chips, first is reciprocal; no overlap → 1 generic) → widget test (tap chip → callback got the string, nothing sent) → implement → green → **Commit** — `feat(chat): opener chips in empty conversations`

### Task 13: Stall-rescue banner

**Files:**
- Create: `lib/widgets/chat/stall_rescue_banner.dart`
- Modify: `lib/pages/chat/conversation/chat_conversation_screen.dart` (evaluate on load)
- Test: `test/matching/stall_rescue_test.dart`

Rule (pure function `bool shouldShowStallRescue({required List<Message> messages, required String myId, required DateTime now})`): thread has 1–5 messages AND the newest message's sender is NOT me AND `now - newest.createdAt > 24h`. Shown at most once per conversation: `SharedPreferences` key `stall_rescue_shown_<conversationId>` (check before showing, set when shown). Banner copy via l10n (`stallRescueTitle`: "{name} asked you something 👀", `stallRescueHint` picks a shared topic if any, else a generic reply nudge); dismissible; tapping the suggestion fills the composer (same `onPick` contract as Task 12).

- [ ] Unit-test the predicate (their-last-message+25h → true; my-last-message → false; 6 messages → false; 2h → false) → widget test (banner renders, dismiss hides) → implement → green → **Commit** — `feat(chat): stall rescue banner`

### Task 14: Wave-flow repair on kept tabs (carried audit fixes)

**Files:**
- Modify: `lib/pages/community/tabs/nearby_tab.dart:227-236`, `lib/pages/community/tabs/topics_tab.dart:64-89`, `lib/pages/community/tabs/city_tab.dart:958-967`, `lib/pages/community/tabs/genders_tab.dart:676`
- Modify: `lib/providers/provider_root/community_provider.dart:903-911` (`wavesUnreadProvider`)
- Test: `test/matching/wave_flow_test.dart`

Fixes (from the 2026-10-01 tab audit):
1. Every wave button calls ONLY the real `sendWave` path (the backend already mirrors a 👋 into chat — `community.js:274-315`); delete the second manual `'👋'` chat message each of those four call sites sends. Surface `ALREADY_WAVED` (the sheet's handling at `send_wave_sheet.dart:160-172` is the model) instead of swallowing errors.
2. `wavesUnreadProvider` returns the server's `unreadCount` field instead of counting the returned page (it currently maxes out at 50 and reads failure as 0 — keep errors → 0 but add a code comment saying so).

- [ ] Unit test for whatever pure seam exists (e.g. the response-to-unread mapping); manual-verification note for the four call sites (each now one network call, verified by grep: `grep -n "'👋'" lib/pages/community` returns nothing) → implement → analyzer clean → **Commit** — `fix(community): single wave path everywhere, honest unread badge`

### Task 15: Rollout

**Files:**
- Create: `scripts/conversationSurvival.js` (backend repo)
- Modify (server, not repo): droplet `config/config.env`

Steps, in order — each gated on the previous:

- [ ] **1. Backend deploy:** push backend `main` (Tasks 1–6 committed). Actions deploys. Verify: `curl -s https://api.banatalk.com/api/v1/moments?limit=1` → 200.
- [ ] **2. Old-build byte-stability check:** with a prod token, fetch `GET /auth/users?limit=3` and diff the key set of a row against the same call made before deploy (keys recorded in Task 2's test). Only additions allowed (`lastActiveBucket`, `responseRate`).
- [ ] **3. Baseline metric** — `scripts/conversationSurvival.js`:

```js
'use strict';
// Share of conversations created in the window that reached >=10 messages
// within 48h of creation. Run before flag-on (baseline) and weekly after.
require('dotenv').config({ path: require('path').join(__dirname, '../config/config.env') });
const mongoose = require('mongoose');

(async () => {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;
  const days = parseInt(process.argv[2], 10) || 14;
  const since = new Date(Date.now() - days * 24 * 3600 * 1000);

  const convs = await db.collection('conversations')
    .find({ createdAt: { $gte: since }, isGroup: { $ne: true } })
    .project({ _id: 1, createdAt: 1 }).toArray();

  let survived = 0;
  for (const c of convs) {
    const cutoff = new Date(c.createdAt.getTime() + 48 * 3600 * 1000);
    const count = await db.collection('messages').countDocuments({
      conversationId: c._id, createdAt: { $lte: cutoff } });
    if (count >= 10) survived += 1;
  }
  console.log(`window ${days}d: ${convs.length} conversations, ` +
    `${survived} survived (${convs.length ? (100 * survived / convs.length).toFixed(1) : 0}%)`);
  await mongoose.disconnect();
})().catch((e) => { console.error(e); process.exit(1); });
```

Run it, record the number in the plan's execution notes.
- [ ] **4. Server env:** add `SMART_SORT_ENABLED=true`, `DAILY_MATCHES_ENABLED=true`, `MATCHES_LAYOUT_ENABLED=false` to the droplet's `config/config.env`, `pm2 restart language-app`. Verify `/matching/daily` returns a batch for the test account and `/app-config` shows `matchesLayoutEnabled: false`.
- [ ] **5. App release:** version bump, release build per `docs` / the release-build how-to (JDK 17 toolchain flag, manual keystore, tag convention). The new layout is INVISIBLE in this build (flag false).
- [ ] **6. Flag on:** once the release has meaningful adoption, set `MATCHES_LAYOUT_ENABLED=true`, pm2 restart. The new layout appears for updated builds only; old builds unchanged.
- [ ] **7. Watch:** re-run `conversationSurvival.js 14` weekly; compare to baseline. Rollback = flip `MATCHES_LAYOUT_ENABLED=false` (layout) or `DAILY_MATCHES_ENABLED=false` (endpoint) — no deploy, no release.

---

## Self-review notes

- Spec §1 → Tasks 10 (layout), 11 (segments); §2 → 4, 5; §3 → 8, 9, 12, 13 + responseRate in 3; §4 → 1, 2, 3, 6; §5 → 15; audit carry-overs → 14. "Who viewed me keeps recording" needs no task (already live); "Paid Practice/push/AI openers" are spec non-goals.
- Type consistency: `DailyMatch.lastActiveBucket` (String?) matches `lastActiveBucket()` output; `matchReasons` string keys produced in Task 4 are exactly the keys Task 9's l10n map consumes; `PartnerFilterParams` new fields match the query params Task 1 implements.
- Review Focus tests are placed: #1, #3 → Task 5; #2 → Task 4; #4 → Task 3; #5 → Task 2.
