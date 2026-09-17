# Reels Ranking & Instrumentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rank the reels feed on what viewers actually watch, and record enough to know whether it worked.

**Architecture:** A pure `lib/reelsRanking.js` holds the scoring rule, matching how `matchLanguage`, `matchIntent` and `gatheringFilters` already isolate decisions so they are table-testable. `getReelsFeed` stops ranking a 10-item chronological window and instead fetches ~200 language-relevant candidates, scores them, and pages by score. A new `MomentView` collection with a 30-day TTL supplies the denominator every rate needs.

**Tech Stack:** Node 20 + Mongoose (`node:test`), Flutter 3 + Riverpod (`flutter_test`).

**Spec:** `docs/superpowers/specs/2026-09-17-reels-ranking-design.md`

## Global Constraints

- **The pool is language-gated, the score is not.** Only the viewer's target or native language competes; engagement orders what is inside. (spec §2.1)
- **A view is 1 second rendered**, never an impression. `completed` is ≥90% of duration, or ≥15s for anything longer. (spec §3.3)
- **`viewCount`/`completionCount` are incremented on write, never recomputed by scanning `MomentView`** — the TTL deletes the rows a recount would need. (spec §3.2)
- **Seen content sinks (−60), it is never excluded.** With a small catalogue, exclusion empties the feed in days. (spec §4.4)
- **A zero-view post must be liftable into the pool.** Ranking on rates is self-reinforcing without the grace period. (spec §4.3)
- **The cold start must work.** On day one no view rows exist and every rate is zero; the feed must still be sane. (spec §9)
- Weights, exactly: completion 40, likesPerView 15, recency 20, follows 15, level 8, newPostGrace +25, seenRecently −60.

---

## File Structure

| File | Responsibility |
|---|---|
| `backend/lib/reelsRanking.js` | **new** — score one candidate; sort a pool. Pure. |
| `backend/models/MomentView.js` | **new** — the view row and its TTL index |
| `backend/models/Moment.js` | `viewCount`, `completionCount` |
| `backend/controllers/momentViews.js` | **new** — accept a batch of view events |
| `backend/controllers/moments.js` | build the candidate pool, rank, page |
| `backend/routes/moments.js` | the views endpoint |
| `app/lib/services/reel_view_tracker.dart` | **new** — accumulate and flush events |
| `app/lib/pages/moments/reels/reels_feed_screen.dart` | feed the tracker |

---

## Task 1 — `lib/reelsRanking.js`, the scoring rule

**Files:**
- Create: `backend/lib/reelsRanking.js`
- Test: `backend/test/reelsRanking.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `REEL_WEIGHTS` (frozen), `scoreReel(candidate, viewer, now) -> number`, `rankReels(candidates, viewer, now) -> array`.

`candidate` shape: `{ _id, user, language, createdAt, viewCount, completionCount, likeCount }`.
`viewer` shape: `{ _id, followingIds: Set|Array, seenMomentIds: Set|Array, languageLevel }`.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { scoreReel, rankReels, REEL_WEIGHTS } = require('../lib/reelsRanking');

const NOW = new Date('2026-09-17T12:00:00Z');
const hoursAgo = (h) => new Date(NOW.getTime() - h * 3600 * 1000);

const reel = (over = {}) => ({
  _id: 'r1', user: { _id: 'a1', native_language: 'Korean', languageLevel: 'C2' },
  language: 'ko', createdAt: hoursAgo(1),
  viewCount: 100, completionCount: 50, likeCount: 10, ...over,
});
const viewer = (over = {}) => ({
  _id: 'v1', followingIds: [], seenMomentIds: [], languageLevel: 'B1', ...over,
});

test('the weights are exactly what the spec fixed', () => {
  assert.equal(REEL_WEIGHTS.completion, 40);
  assert.equal(REEL_WEIGHTS.likesPerView, 15);
  assert.equal(REEL_WEIGHTS.recency, 20);
  assert.equal(REEL_WEIGHTS.follows, 15);
  assert.equal(REEL_WEIGHTS.level, 8);
  assert.equal(REEL_WEIGHTS.newPostGrace, 25);
  assert.equal(REEL_WEIGHTS.seenRecently, -60);
});

test('a higher completion rate scores higher', () => {
  const good = scoreReel(reel({ completionCount: 90 }), viewer(), NOW);
  const poor = scoreReel(reel({ completionCount: 10 }), viewer(), NOW);
  assert.ok(good > poor, `${good} should beat ${poor}`);
});

test('GLOBAL CONSTRAINT: likesPerView does not divide by zero on a fresh post', () => {
  const fresh = reel({ viewCount: 0, completionCount: 0, likeCount: 0 });
  const s = scoreReel(fresh, viewer(), NOW);
  assert.ok(Number.isFinite(s), `score was ${s}`);
});

test('GLOBAL CONSTRAINT: a zero-view post is lifted into contention', () => {
  // Without the grace period, rate-based ranking never shows a new post, so
  // it never earns a rate -- the loop that buries every new creator.
  const brandNew = reel({ _id: 'new', viewCount: 0, completionCount: 0, likeCount: 0, createdAt: hoursAgo(2) });
  const established = reel({ _id: 'old', viewCount: 500, completionCount: 100, likeCount: 20, createdAt: hoursAgo(40) });
  const ranked = rankReels([established, brandNew], viewer(), NOW);
  assert.equal(ranked[0]._id, 'new');
});

test('the grace period expires after 24h and after 20 views', () => {
  const aged = reel({ viewCount: 0, createdAt: hoursAgo(30) });
  const viewed = reel({ viewCount: 25, createdAt: hoursAgo(2) });
  const eligible = reel({ viewCount: 0, createdAt: hoursAgo(2) });
  assert.ok(scoreReel(eligible, viewer(), NOW) > scoreReel(aged, viewer(), NOW));
  assert.ok(scoreReel(eligible, viewer(), NOW) > scoreReel(viewed, viewer(), NOW));
});

test('newer beats older, all else equal', () => {
  const fresh = scoreReel(reel({ createdAt: hoursAgo(1) }), viewer(), NOW);
  const stale = scoreReel(reel({ createdAt: hoursAgo(96) }), viewer(), NOW);
  assert.ok(fresh > stale);
});

test('following the author is worth the follow weight', () => {
  const base = scoreReel(reel(), viewer(), NOW);
  const followed = scoreReel(reel(), viewer({ followingIds: ['a1'] }), NOW);
  assert.equal(Math.round(followed - base), REEL_WEIGHTS.follows);
});

test('GLOBAL CONSTRAINT: a seen reel sinks but is still returned', () => {
  const seen = reel({ _id: 'seen' });
  const unseen = reel({ _id: 'unseen' });
  const ranked = rankReels([seen, unseen], viewer({ seenMomentIds: ['seen'] }), NOW);
  assert.equal(ranked[0]._id, 'unseen');
  assert.equal(ranked.length, 2, 'sunk, not dropped');
  assert.equal(ranked[1]._id, 'seen');
});

test('a seen reel is still returned when it is all there is', () => {
  const ranked = rankReels([reel({ _id: 'seen' })], viewer({ seenMomentIds: ['seen'] }), NOW);
  assert.equal(ranked.length, 1);
});

test('GLOBAL CONSTRAINT: the cold start produces a sane order', () => {
  // Day one: no views anywhere, so every rate is zero. Recency and the grace
  // period must still order the feed rather than leaving it arbitrary.
  const cold = [
    reel({ _id: 'old', viewCount: 0, completionCount: 0, likeCount: 0, createdAt: hoursAgo(72) }),
    reel({ _id: 'new', viewCount: 0, completionCount: 0, likeCount: 0, createdAt: hoursAgo(1) }),
  ];
  const ranked = rankReels(cold, viewer(), NOW);
  assert.equal(ranked[0]._id, 'new');
  assert.ok(ranked.every((r) => Number.isFinite(r.score)));
});

test('a learner-authored reel beats a native-speed one for a B1 viewer', () => {
  const native = reel({ user: { _id: 'a1', native_language: 'Korean', languageLevel: 'C2' } });
  const learner = reel({ user: { _id: 'a2', native_language: 'English', languageLevel: 'B1' } });
  assert.ok(scoreReel(learner, viewer({ languageLevel: 'B1' }), NOW)
    > scoreReel(native, viewer({ languageLevel: 'B1' }), NOW));
});

test('rankReels attaches the score and never mutates its input', () => {
  const input = [reel()];
  const ranked = rankReels(input, viewer(), NOW);
  assert.ok(typeof ranked[0].score === 'number');
  assert.equal(input[0].score, undefined, 'input must not be mutated');
});

test('an empty pool returns an empty array, not a throw', () => {
  assert.deepEqual(rankReels([], viewer(), NOW), []);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/reelsRanking.test.js`
Expected: FAIL — `Cannot find module '../lib/reelsRanking'`

- [ ] **Step 3: Write the module**

```js
'use strict';

/**
 * How the reels feed is ordered.
 *
 * Pure and dependency-free, like lib/matchLanguage.js and lib/matchIntent.js,
 * so the rule that decides what a learner watches is table-testable.
 *
 * It does NOT choose the pool. Language gating happens in the query
 * (controllers/moments.js): a reel in a language the viewer cannot read is
 * scrolled past, which registers as low completion and reads as "bad content"
 * when it is really "wrong audience".
 */

const REEL_WEIGHTS = Object.freeze({
  completion: 40,      // the dominant quality signal in short video
  likesPerView: 15,    // a RATE -- a raw count ranks by age
  recency: 20,
  follows: 15,
  level: 8,            // small on purpose: it is a proxy, not a measurement
  newPostGrace: 25,
  seenRecently: -60,   // sinks, never excludes
});

const RECENCY_HALF_LIFE_HOURS = 48;
const GRACE_MAX_VIEWS = 20;
const GRACE_MAX_AGE_HOURS = 24;
const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

const asSet = (v) => (v instanceof Set ? v : new Set((v || []).map(String)));
const hoursBetween = (a, b) => Math.max(0, (a.getTime() - new Date(b).getTime()) / 3600000);

/**
 * Difficulty, approximated from the AUTHOR rather than the post.
 *
 * Moment has no difficulty field and this does not invent one. A native
 * speaker posting in their own language is harder listening than a B1 learner
 * posting in theirs. Weight 8 because it is a proxy: enough to break a tie,
 * never enough to bury a good reel.
 */
const levelDistance = (candidate, viewerLevel) => {
  const author = candidate.user || {};
  const authorLevel = (author.native_language && candidate.language
    && String(author.native_language).toLowerCase().startsWith(String(candidate.language).toLowerCase().slice(0, 2)))
    ? 'C2'
    : (author.languageLevel || 'B1');
  const a = LEVELS.indexOf(authorLevel);
  const v = LEVELS.indexOf(viewerLevel || 'B1');
  if (a === -1 || v === -1) return 1;
  return Math.abs(a - v) / (LEVELS.length - 1);   // 0 = same level, 1 = furthest
};

const scoreReel = (candidate, viewer, now = new Date()) => {
  const views = Math.max(0, candidate.viewCount || 0);
  const completions = Math.max(0, candidate.completionCount || 0);
  const likes = Math.max(0, candidate.likeCount || 0);

  // Guarded: a fresh post has zero views and every rate would be 0/0.
  const completionRate = views > 0 ? Math.min(1, completions / views) : 0;
  const likesPerView = views > 0 ? Math.min(1, likes / views) : 0;

  const ageHours = hoursBetween(now, candidate.createdAt || now);
  const recency = Math.pow(0.5, ageHours / RECENCY_HALF_LIFE_HOURS);

  const following = asSet(viewer.followingIds);
  const authorId = String((candidate.user && candidate.user._id) || candidate.user || '');
  const follows = following.has(authorId) ? 1 : 0;

  const seen = asSet(viewer.seenMomentIds);
  const seenRecently = seen.has(String(candidate._id)) ? 1 : 0;

  const grace = (views < GRACE_MAX_VIEWS && ageHours < GRACE_MAX_AGE_HOURS) ? 1 : 0;

  const levelFit = 1 - levelDistance(candidate, viewer.languageLevel);

  return (
    completionRate * REEL_WEIGHTS.completion
    + likesPerView * REEL_WEIGHTS.likesPerView
    + recency * REEL_WEIGHTS.recency
    + follows * REEL_WEIGHTS.follows
    + levelFit * REEL_WEIGHTS.level
    + grace * REEL_WEIGHTS.newPostGrace
    + seenRecently * REEL_WEIGHTS.seenRecently
  );
};

/** Highest first. Returns new objects; never mutates the input. */
const rankReels = (candidates, viewer, now = new Date()) =>
  (candidates || [])
    .map((c) => ({ ...c, score: scoreReel(c, viewer, now) }))
    .sort((a, b) => b.score - a.score || String(a._id).localeCompare(String(b._id)));

module.exports = { REEL_WEIGHTS, scoreReel, rankReels, RECENCY_HALF_LIFE_HOURS };
```

- [ ] **Step 4: Run the tests and watch them pass**

Run: `cd backend && node --test --test-force-exit test/reelsRanking.test.js`
Expected: PASS, 13/13

- [ ] **Step 5: Commit**

```bash
git add backend/lib/reelsRanking.js backend/test/reelsRanking.test.js
git commit -m "feat(reels): the ranking rule, as one pure function"
```

---

## Task 2 — `MomentView` and the counters

**Files:**
- Create: `backend/models/MomentView.js`
- Modify: `backend/models/Moment.js` (beside `saveCount`)
- Test: `backend/test/momentView.test.js`

**Interfaces:**
- Produces: `MomentView` model; `Moment.viewCount`, `Moment.completionCount`.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, MomentView, Moment;

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'momentViews' });
  MomentView = require('../models/MomentView');
  Moment = require('../models/Moment');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => { await MomentView.deleteMany({}); });

test('a view row stores what was watched', async () => {
  const row = await MomentView.create({
    viewer: new mongoose.Types.ObjectId(),
    moment: new mongoose.Types.ObjectId(),
    watchedMs: 4200,
    completed: true,
  });
  assert.equal(row.watchedMs, 4200);
  assert.equal(row.completed, true);
});

test('createdAt carries a TTL index, so the collection stays bounded', () => {
  const idx = MomentView.schema.indexes()
    .find(([keys]) => Object.prototype.hasOwnProperty.call(keys, 'createdAt'));
  assert.ok(idx, 'no index on createdAt');
  assert.equal(idx[1].expireAfterSeconds, 30 * 24 * 60 * 60);
});

test('(viewer, moment) is indexed — the seen-suppression lookup', () => {
  const idx = MomentView.schema.indexes()
    .find(([keys]) => keys.viewer === 1 && keys.moment === 1);
  assert.ok(idx, 'no compound (viewer, moment) index');
});

test('Moment carries the two counters, defaulting to zero', () => {
  const m = new Moment({ title: 't', description: 'd', user: new mongoose.Types.ObjectId() });
  assert.equal(m.viewCount, 0);
  assert.equal(m.completionCount, 0);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/momentView.test.js`
Expected: FAIL — `Cannot find module '../models/MomentView'`

- [ ] **Step 3: Write the model**

```js
'use strict';

const mongoose = require('mongoose');

/**
 * One reel, watched once, by one person.
 *
 * Exists because every metric worth ranking short video on is a RATE, and
 * before this there was no denominator: Moment counted likes, comments, saves
 * and shares but never a view.
 *
 * Bounded by a 30-day TTL. Ranking reads only the last 7 days (seen
 * suppression) and the aggregate counters on Moment carry the rest, so older
 * rows have no reader and would cost only storage and index time. At ~1,800
 * active users this is roughly 90k rows a day.
 */
const MomentViewSchema = new mongoose.Schema({
  viewer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  moment: { type: mongoose.Schema.Types.ObjectId, ref: 'Moment', required: true },

  /** Total milliseconds watched in this sitting. */
  watchedMs: { type: Number, default: 0, min: 0 },

  /** >= 90% of duration, or >= 15s for anything longer. Decided client-side. */
  completed: { type: Boolean, default: false },

  createdAt: { type: Date, default: Date.now },
});

// The seen-suppression lookup: "which of these did this viewer already watch".
MomentViewSchema.index({ viewer: 1, moment: 1 });
// Recent views for one viewer, newest first.
MomentViewSchema.index({ viewer: 1, createdAt: -1 });
// The TTL. 30 days, per the spec -- see the class comment for why not forever.
MomentViewSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

module.exports = mongoose.model('MomentView', MomentViewSchema);
```

- [ ] **Step 4: Add the counters to `models/Moment.js`**

Insert immediately after the `saveCount` field:

```js
  /**
   * Incremented on write, never recomputed by scanning MomentView -- that
   * collection has a 30-day TTL, so a recount would silently shrink over time.
   */
  viewCount: {
    type: Number,
    default: 0,
    min: 0
  },
  completionCount: {
    type: Number,
    default: 0,
    min: 0
  },
```

- [ ] **Step 5: Run the tests and watch them pass**

Run: `cd backend && node --test --test-force-exit test/momentView.test.js`
Expected: PASS, 4/4

- [ ] **Step 6: Commit**

```bash
git add backend/models/MomentView.js backend/models/Moment.js backend/test/momentView.test.js
git commit -m "feat(reels): record views, so a rate has a denominator"
```

---

## Task 3 — the batch endpoint

**Files:**
- Create: `backend/controllers/momentViews.js`
- Modify: `backend/routes/moments.js`
- Test: `backend/test/momentViewBatch.test.js`

**Interfaces:**
- Consumes: `MomentView`, `Moment` (Task 2).
- Produces: `POST /api/v1/moments/views` accepting `{ views: [{ momentId, watchedMs, completed }] }`.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, Moment, MomentView, User, controller;

const asHandler = (fn) => (req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  fn(req, res, (err) => (err ? resolve({ status: err.statusCode || 500, error: err.message }) : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'viewBatch' });
  Moment = require('../models/Moment');
  MomentView = require('../models/MomentView');
  User = require('../models/User');
  controller = require('../controllers/momentViews');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Moment.deleteMany({}); await MomentView.deleteMany({}); await User.deleteMany({});
});

const makeUser = () => User.create({
  name: 'V', email: `v-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean',
});
const makeMoment = (user) => Moment.create({
  title: 't', description: 'd', user: user._id, isReel: true,
});
const post = (user, body) =>
  asHandler(controller.recordViews)({ user: { _id: user._id, id: String(user._id) }, body });

test('a batch increments the counters once per event', async () => {
  const u = await makeUser();
  const m = await makeMoment(u);
  const res = await post(u, { views: [
    { momentId: String(m._id), watchedMs: 3000, completed: true },
  ] });
  assert.equal(res.status, 200);
  const after = await Moment.findById(m._id).lean();
  assert.equal(after.viewCount, 1);
  assert.equal(after.completionCount, 1);
});

test('GLOBAL CONSTRAINT: a view under one second is not counted', async () => {
  const u = await makeUser();
  const m = await makeMoment(u);
  await post(u, { views: [{ momentId: String(m._id), watchedMs: 400, completed: false }] });
  const after = await Moment.findById(m._id).lean();
  assert.equal(after.viewCount, 0, 'a scroll-past is not a view');
  assert.equal(await MomentView.countDocuments({}), 0);
});

test('an incomplete view counts as a view but not a completion', async () => {
  const u = await makeUser();
  const m = await makeMoment(u);
  await post(u, { views: [{ momentId: String(m._id), watchedMs: 2000, completed: false }] });
  const after = await Moment.findById(m._id).lean();
  assert.equal(after.viewCount, 1);
  assert.equal(after.completionCount, 0);
});

test('an unknown moment id is skipped, not fatal', async () => {
  // A batch arrives after a post was deleted. Losing one event is fine;
  // rejecting the whole batch would lose the other forty.
  const u = await makeUser();
  const m = await makeMoment(u);
  const res = await post(u, { views: [
    { momentId: String(new mongoose.Types.ObjectId()), watchedMs: 3000 },
    { momentId: String(m._id), watchedMs: 3000 },
  ] });
  assert.equal(res.status, 200);
  assert.equal((await Moment.findById(m._id).lean()).viewCount, 1);
});

test('an empty or malformed batch is accepted and does nothing', async () => {
  const u = await makeUser();
  for (const body of [{}, { views: [] }, { views: 'nonsense' }]) {
    assert.equal((await post(u, body)).status, 200);
  }
});

test('a batch is capped so one client cannot post ten thousand events', async () => {
  const u = await makeUser();
  const m = await makeMoment(u);
  const views = Array.from({ length: 300 }, () => ({ momentId: String(m._id), watchedMs: 2000 }));
  await post(u, { views });
  const after = await Moment.findById(m._id).lean();
  assert.ok(after.viewCount <= 100, `capped, got ${after.viewCount}`);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/momentViewBatch.test.js`
Expected: FAIL — `Cannot find module '../controllers/momentViews'`

- [ ] **Step 3: Write the controller**

```js
'use strict';

const asyncHandler = require('../middleware/async');
const Moment = require('../models/Moment');
const MomentView = require('../models/MomentView');

/**
 * A view is one second, not an impression.
 *
 * Counting on render would include every reel scrolled past before the video
 * decoded. Those are not views, and including them deflates every rate
 * uniformly until good and bad content converge.
 */
const MIN_VIEW_MS = 1000;

/** One scroll session is a batch; this bounds what a single client can post. */
const MAX_BATCH = 100;

/**
 * @desc    Record a batch of reel views
 * @route   POST /api/v1/moments/views
 * @access  Private
 *
 * Always 200, even for a malformed body. These events are telemetry: losing
 * one costs a data point, while failing the request costs the whole batch and
 * teaches the client to retry a payload that will fail again.
 */
exports.recordViews = asyncHandler(async (req, res) => {
  const raw = Array.isArray(req.body && req.body.views) ? req.body.views : [];
  const batch = raw.slice(0, MAX_BATCH).filter(
    (v) => v && v.momentId && Number(v.watchedMs) >= MIN_VIEW_MS
  );

  if (batch.length === 0) {
    return res.status(200).json({ success: true, recorded: 0 });
  }

  // Only ids that still exist: a batch can arrive after a post was deleted,
  // and one stale event must not cost the other thirty-nine.
  const ids = [...new Set(batch.map((v) => String(v.momentId)))];
  const live = await Moment.find({ _id: { $in: ids } }).select('_id').lean();
  const liveIds = new Set(live.map((m) => String(m._id)));
  const usable = batch.filter((v) => liveIds.has(String(v.momentId)));

  if (usable.length === 0) {
    return res.status(200).json({ success: true, recorded: 0 });
  }

  await MomentView.insertMany(
    usable.map((v) => ({
      viewer: req.user._id,
      moment: v.momentId,
      watchedMs: Math.round(Number(v.watchedMs)),
      completed: v.completed === true,
    })),
    { ordered: false }
  );

  // Counters are incremented, never recomputed from MomentView -- that
  // collection expires after 30 days and a recount would shrink silently.
  const byMoment = new Map();
  for (const v of usable) {
    const key = String(v.momentId);
    const entry = byMoment.get(key) || { views: 0, completions: 0 };
    entry.views += 1;
    if (v.completed === true) entry.completions += 1;
    byMoment.set(key, entry);
  }

  await Moment.bulkWrite(
    [...byMoment.entries()].map(([id, c]) => ({
      updateOne: {
        filter: { _id: id },
        update: { $inc: { viewCount: c.views, completionCount: c.completions } },
      },
    })),
    { ordered: false }
  );

  res.status(200).json({ success: true, recorded: usable.length });
});
```

- [ ] **Step 4: Register the route**

In `backend/routes/moments.js`, beside the other `protect`ed POST routes:

```js
const { recordViews } = require('../controllers/momentViews');
router.route('/views').post(protect, recordViews);
```

Place it **above** `router.route('/:id')` — otherwise Express matches `/views` as an id.

- [ ] **Step 5: Run the tests and watch them pass**

Run: `cd backend && node --test --test-force-exit test/momentViewBatch.test.js`
Expected: PASS, 6/6

- [ ] **Step 6: Commit**

```bash
git add backend/controllers/momentViews.js backend/routes/moments.js backend/test/momentViewBatch.test.js
git commit -m "feat(reels): accept batched view events"
```

---

## Task 4 — rank a real pool in `getReelsFeed`

**Files:**
- Modify: `backend/controllers/moments.js` (`getReelsFeed`)
- Test: `backend/test/reelsFeedRanking.test.js`

**Interfaces:**
- Consumes: `rankReels` (Task 1), `MomentView` (Task 2).
- Produces: a `getReelsFeed` that returns ranked results and a score-based `nextCursor`.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { rankReels } = require('../lib/reelsRanking');

const NOW = new Date('2026-09-17T12:00:00Z');
const hoursAgo = (h) => new Date(NOW.getTime() - h * 3600 * 1000);

test('GLOBAL CONSTRAINT: a great old reel can outrank a mediocre new one', () => {
  // The bug this whole task exists for: the old feed took the newest 10 and
  // reordered them, so nothing older than the last ten posts was reachable at
  // any quality.
  const greatButOld = {
    _id: 'great', user: { _id: 'a1' }, language: 'ko', createdAt: hoursAgo(50),
    viewCount: 400, completionCount: 380, likeCount: 90,
  };
  const mediocreButNew = {
    _id: 'meh', user: { _id: 'a2' }, language: 'ko', createdAt: hoursAgo(26),
    viewCount: 400, completionCount: 20, likeCount: 1,
  };
  const ranked = rankReels([mediocreButNew, greatButOld],
    { _id: 'v', followingIds: [], seenMomentIds: [] }, NOW);
  assert.equal(ranked[0]._id, 'great');
});

test('ranking is deterministic for identical input', () => {
  const pool = [
    { _id: 'b', user: { _id: 'a' }, language: 'ko', createdAt: hoursAgo(5), viewCount: 10, completionCount: 5, likeCount: 1 },
    { _id: 'a', user: { _id: 'a' }, language: 'ko', createdAt: hoursAgo(5), viewCount: 10, completionCount: 5, likeCount: 1 },
  ];
  const viewer = { _id: 'v', followingIds: [], seenMomentIds: [] };
  const first = rankReels(pool, viewer, NOW).map((r) => r._id);
  const second = rankReels(pool, viewer, NOW).map((r) => r._id);
  assert.deepEqual(first, second, 'a tie must break the same way every time');
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/reelsFeedRanking.test.js`
Expected: PASS already if Task 1 landed — these assert the *ranking* contract the controller depends on. If they fail, Task 1 is wrong; fix it before continuing.

- [ ] **Step 3: Rewrite the body of `getReelsFeed`**

Replace the block from `const rawWindow = await Moment.find(query)` through `const ordered = partitionByLanguage(...)` with:

```js
  // A BOUND, not an order. The pool is the newest ~200 language-relevant
  // reels; everything inside it then competes on merit. Taking the newest 10
  // and reordering them -- which is what this did -- made anything older than
  // the last ten posts unreachable at any quality.
  const POOL_SIZE = 200;

  const targetIso = toIso(req.user.language_to_learn);
  const nativeIso = toIso(req.user.native_language);
  const relevantLanguages = [targetIso, nativeIso].filter(Boolean);

  const poolQuery = { ...query };
  delete poolQuery.createdAt;          // the cursor is score-based now
  if (relevantLanguages.length) {
    poolQuery.language = { $in: relevantLanguages };
  }
  poolQuery.user = { $ne: req.user._id };

  const pool = await Moment.find(poolQuery)
    .populate('user', USER_FIELDS)
    .sort({ createdAt: -1 })
    .limit(POOL_SIZE)
    .lean();

  // Seen in the last 7 days. Read here rather than inside the scorer so the
  // scorer stays pure and table-testable.
  const SEEN_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
  const seenRows = await MomentView.find({
    viewer: req.user._id,
    createdAt: { $gte: new Date(Date.now() - SEEN_WINDOW_MS) },
  }).select('moment').lean();

  const viewerForRanking = {
    _id: req.user._id,
    followingIds: (req.user.followings || []).map(String),
    seenMomentIds: seenRows.map((r) => String(r.moment)),
    languageLevel: req.user.languageLevel,
  };

  const ranked = rankReels(pool, viewerForRanking);

  // Paged by SCORE, not createdAt: paging a scored feed by time interleaves
  // pages incoherently -- page 2 would hold higher-scoring posts that belonged
  // on page 1.
  const after = req.query.after ? Number(req.query.after) : null;
  const page = (Number.isFinite(after)
    ? ranked.filter((r) => r.score < after)
    : ranked
  ).slice(0, limit);

  const nextCursor = page.length === limit && page.length > 0
    ? String(page[page.length - 1].score)
    : null;

  const ordered = page;
```

Add at the top of the file, beside the other requires:

```js
const MomentView = require('../models/MomentView');
const { rankReels } = require('../lib/reelsRanking');
```

Ensure `req.user` carries `followings` and `languageLevel` — if the route's `protect` middleware selects specific fields, add them there. Without `followings` the follow weight silently never fires.

- [ ] **Step 4: Run the whole backend suite**

Run: `cd backend && npm test`
Expected: all green. Existing `reelsFeed` tests that asserted chronological order will fail — that behaviour is what this task replaces. Update those assertions to the ranked contract rather than weakening them.

- [ ] **Step 5: Commit**

```bash
git add backend/controllers/moments.js backend/test/reelsFeedRanking.test.js
git commit -m "feat(reels): rank a real candidate pool instead of the newest ten"
```

---

## Task 5 — the app records what was watched

**Files:**
- Create: `app/lib/services/reel_view_tracker.dart`
- Modify: `app/lib/pages/moments/reels/reels_feed_screen.dart`
- Test: `app/test/moments/reel_view_tracker_test.dart`

**Interfaces:**
- Consumes: `POST /moments/views` (Task 3).
- Produces: `ReelViewTracker` with `onReelStarted(String id)`, `onReelEnded({required Duration watched, required Duration total})`, `flush()`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/reel_view_tracker.dart';

void main() {
  late List<List<Map<String, dynamic>>> sent;
  late ReelViewTracker tracker;

  setUp(() {
    sent = [];
    tracker = ReelViewTracker(send: (batch) async => sent.add(batch));
  });

  test('a view under one second is dropped', () async {
    tracker.onReelStarted('r1');
    tracker.onReelEnded(
      watched: const Duration(milliseconds: 400),
      total: const Duration(seconds: 30),
    );
    await tracker.flush();
    expect(sent, isEmpty, reason: 'a scroll-past is not a view');
  });

  test('a view over one second is queued', () async {
    tracker.onReelStarted('r1');
    tracker.onReelEnded(
      watched: const Duration(seconds: 3),
      total: const Duration(seconds: 30),
    );
    await tracker.flush();
    expect(sent.single.single['momentId'], 'r1');
    expect(sent.single.single['watchedMs'], 3000);
    expect(sent.single.single['completed'], isFalse);
  });

  test('90% watched counts as completed', () async {
    tracker.onReelStarted('r1');
    tracker.onReelEnded(
      watched: const Duration(seconds: 27),
      total: const Duration(seconds: 30),
    );
    await tracker.flush();
    expect(sent.single.single['completed'], isTrue);
  });

  test('15 seconds completes a long reel without watching it all', () async {
    // A two-minute reel is not "incomplete" because someone watched a while.
    tracker.onReelStarted('r1');
    tracker.onReelEnded(
      watched: const Duration(seconds: 16),
      total: const Duration(minutes: 2),
    );
    await tracker.flush();
    expect(sent.single.single['completed'], isTrue);
  });

  test('events batch rather than sending one request each', () async {
    for (var i = 0; i < 3; i++) {
      tracker.onReelStarted('r$i');
      tracker.onReelEnded(
        watched: const Duration(seconds: 2),
        total: const Duration(seconds: 30),
      );
    }
    await tracker.flush();
    expect(sent.length, 1, reason: 'one request, not three');
    expect(sent.single.length, 3);
  });

  test('flushing an empty queue sends nothing', () async {
    await tracker.flush();
    expect(sent, isEmpty);
  });

  test('a failed send never throws into the UI', () async {
    final failing = ReelViewTracker(send: (_) async => throw Exception('offline'));
    failing.onReelStarted('r1');
    failing.onReelEnded(
      watched: const Duration(seconds: 3),
      total: const Duration(seconds: 30),
    );
    // Telemetry must never break scrolling.
    await expectLater(failing.flush(), completes);
  });

  test('the queue is cleared after a successful flush', () async {
    tracker.onReelStarted('r1');
    tracker.onReelEnded(
      watched: const Duration(seconds: 3),
      total: const Duration(seconds: 30),
    );
    await tracker.flush();
    await tracker.flush();
    expect(sent.length, 1, reason: 'the second flush had nothing to send');
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd bananatalk_app && flutter test test/moments/reel_view_tracker_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'reel_view_tracker'`

- [ ] **Step 3: Write the tracker**

```dart
import 'package:flutter/foundation.dart';

/// Accumulates what was actually watched, and posts it in batches.
///
/// Telemetry, deliberately: a dropped batch costs a data point and must never
/// cost a frame. Every failure path here swallows rather than rethrows.
class ReelViewTracker {
  ReelViewTracker({required this.send, this.flushEvery = 10});

  /// Injected so tests never reach the network.
  final Future<void> Function(List<Map<String, dynamic>> batch) send;

  /// Flush after this many queued events, on top of pause and background.
  final int flushEvery;

  final List<Map<String, dynamic>> _queue = [];
  String? _current;

  /// A view is one second, not an impression: counting on render would include
  /// every reel scrolled past before the video decoded, which deflates every
  /// rate uniformly.
  static const int _minViewMs = 1000;

  /// Long reels complete at 15s rather than 90% — otherwise a two-minute reel
  /// is called incomplete by someone who watched a long time.
  static const int _longReelCompleteMs = 15000;

  void onReelStarted(String momentId) => _current = momentId;

  void onReelEnded({required Duration watched, required Duration total}) {
    final id = _current;
    _current = null;
    if (id == null) return;

    final watchedMs = watched.inMilliseconds;
    if (watchedMs < _minViewMs) return;

    final totalMs = total.inMilliseconds;
    final completed = totalMs > 0
        ? (watchedMs >= totalMs * 0.9 || watchedMs >= _longReelCompleteMs)
        : false;

    _queue.add({
      'momentId': id,
      'watchedMs': watchedMs,
      'completed': completed,
    });

    if (_queue.length >= flushEvery) flush();
  }

  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();
    try {
      await send(batch);
    } catch (e) {
      // Swallowed on purpose. Re-queueing would grow without bound offline,
      // and losing telemetry is cheaper than losing the scroll.
      debugPrint('[reelViews] flush failed, ${batch.length} event(s) dropped: $e');
    }
  }
}
```

- [ ] **Step 4: Wire it into `reels_feed_screen.dart`**

- Construct a `ReelViewTracker` in `initState`, its `send` posting to `moments/views` via the existing API client.
- In the page-change handler (around `_currentIndex` assignment), call `onReelEnded` for the outgoing reel using its controller's `position` and `duration`, then `onReelStarted` for the incoming one.
- In `dispose`, and in an `AppLifecycleState.paused` observer, call `flush()`.

- [ ] **Step 5: Run every app test**

Run: `cd bananatalk_app && flutter test && flutter analyze lib/`
Expected: all green, zero analyzer errors.

- [ ] **Step 6: Commit**

```bash
git add bananatalk_app/lib bananatalk_app/test
git commit -m "feat(reels): record what was actually watched"
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| §3.1 `MomentView` + TTL | 2 |
| §3.2 counters incremented, not recomputed | 2, 3 |
| §3.3 1s threshold, 90%/15s completion | 3 (server), 5 (client) |
| §3.4 batching | 5 |
| §4.1 candidate pool, language-gated | 4 |
| §4.2 weights | 1 |
| §4.3 new-post grace | 1 (test + impl) |
| §4.4 seen sinks, never excluded | 1 (test + impl) |
| §4.5 score-cursor pagination | 4 |
| §5 level proxy | 1 (`levelDistance`) |
| §7 cold start | 1 (test) |
| §9 flush on pause/background | 5 |

**Type consistency:** `scoreReel(candidate, viewer, now)` and `rankReels(candidates, viewer, now)` keep one signature throughout. `viewer.followingIds` and `viewer.seenMomentIds` are the names used in both Task 1 and Task 4. `REEL_WEIGHTS` keys match the spec's table exactly.

**Placeholders:** none.

**One gap worth naming:** Task 4 assumes `req.user` carries `followings` and `languageLevel`. Step 3 says to check the route's field selection — if `protect` selects a narrow projection, the follow weight silently never fires. That is the same class of bug as the matching work, where `intents` was not selected and every score was quietly zero.
