# Moments Completion — Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the backend half of the Moments spec, one production-safe merge at a time:
- server-side filters and search on every feed;
- scheduled moments that actually wait — switched off until the user counts;
- app moment reports that reach the moderators' desk;
- removing a voice note.

**Architecture:** Each concern is a small pure module in `lib/`, applied at the existing read and write sites in `controllers/moments.js`:
- `lib/momentFilters.js`
- `lib/momentScheduling.js`
- `lib/reportReasons.js`

Every behaviour change is behind a switch read per request:
- `MOMENT_SCHEDULING_ENFORCED`, default **off**;
- `MOMENT_REPORTS_TO_DESK`, default on and record-only.

A request without the new params returns exactly today's result.

**Tech Stack:** Node/Express/Mongoose. Tests are `node:test` with mongodb-memory-server, run with Node 24 (`~/.nvm/versions/node/v24.18.0/bin/node`).

**Spec:** `docs/superpowers/specs/2026-10-08-moments-completion-design.md` (web repo), sections 1, 2, 3 and 5 plus "Production safety". The web half is a separate plan.

## Global Constraints

- Backend repo: `/Users/davis/Desktop/Personal/language_exchange_backend_application`. It **serves the production app**.
- **Additive only.** No field is renamed or removed and no response shape changes.
- **Same request, same answer.** A request without the new params must return today's result.
- **Switches are read per request**, never at module load:
  - `MOMENT_SCHEDULING_ENFORCED` — enforcement only when `=== 'true'`;
  - `MOMENT_REPORTS_TO_DESK` — off only when `=== 'false'`.
- **No data migrations, no new indexes.** `createdAt` moves only on new writes of unpublished scheduled moments, and only while enforcement is on.
- **One merge per task, in order:** Task 1 (filters), Task 2 (scheduling), Task 3 (reports), Task 4 (audio delete). Merge with `--no-ff`. **Never** add a `Co-Authored-By` trailer.
- **Before every push:**
  - `PATH=~/.nvm/versions/node/v24.18.0/bin:$PATH npm test` — only `authSecretRotation` may fail;
  - the npm 9 check: `/private/tmp/claude-501/-Users-davis-Desktop-Personal-language-exchange-web-front/f4ebb588-39a1-4eba-864f-de64536f9fd1/scratchpad/npm9-check.sh` must print `NPM9_OK`. **Never** run `npm ci --dry-run` inside the repo; it empties `node_modules`.
- **After every push:**
  - `gh run watch` on the latest run must show success, `npm ci succeeded` and PM2 `online`;
  - `curl https://api.banatalk.com/api/v1/auth/users/6a7eb3d492fdab67baeed15f/public` must reach 200, allowing for one 404 during warm-up.
- **The app's requests, never to change:**
  - `/moments` gets only `page`, `limit`, `feed`;
  - `/trending` gets only `page`, `limit`;
  - `/explore` gets `category`, `language`, `mood`, `tags`, `page`, `limit`.

## Review Focus

1. **A search term containing regex metacharacters** (`c++`, `(hi`, `.*`). It must match literally and must not throw. *Pinned in Task 1:* "metacharacters match literally".
2. **A `q` longer than 100 characters, or whitespace-only.** Long terms are truncated; whitespace-only is not a search. *Pinned in Task 1.*
3. **`scheduledFor` sent as an unparseable string on update.** It must answer 400, not 500, and must not write. *Pinned in Task 2:* "an unparseable scheduledFor is rejected".
4. **A repeat legacy report from someone who reported before this deploy** (an embedded report exists, no `Report` row). It stays forward-only, so no row is backfilled. *Pinned in Task 3.*
5. **Deleting the audio of a moment that also has images.** `mediaType` must become `image`, not `text`. *Pinned in Task 4.*

---

### Task 1: Filters and search on every feed (`lib/momentFilters.js`)

**Files:**
- Create: `lib/momentFilters.js`
- Modify: `controllers/moments.js`:
  - `getMoments` — apply just before `const RANKING_POOL = 300;` (~line 186);
  - `getTrendingMoments` — before its `countDocuments`;
  - `exploreMoments` — replace the inline `// Apply filters` block.
- Test: `test/momentFilters.test.js`

**Interfaces — Produces:**

```js
applyMomentFilters(query: object, params: { category?, language?, mood?, tags?, q? }) => object   // new object; input not mutated
```

- [ ] **Step 1: Branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application && git checkout main && git pull --ff-only && git checkout -b feat/moment-filters
```

- [ ] **Step 2: Write the failing test** — `test/momentFilters.test.js`

```js
'use strict';

/**
 * Moment filters and search, server-side, on every feed (spec section 1).
 * The web filtered the ten moments it had loaded and built its option lists from
 * them; the server now does it for For You, Following, Trending and Explore.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const { applyMomentFilters } = require('../lib/momentFilters');

let mongod, User, Moment, controller;

const run = (fn, req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  fn({ protocol: 'https', get: () => 'api.example.com', query: {}, ...req }, res,
    (err) => (err ? resolve({ status: err.statusCode || 500, error: err.message }) : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'momentFilters' });
  User = require('../models/User');
  Moment = require('../models/Moment');
  controller = require('../controllers/moments');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => { await Promise.all([User.deleteMany({}), Moment.deleteMany({})]); });

const makeUser = (name, extra = {}) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean', ...extra,
});
const makeMoment = (user, over = {}) => Moment.create({
  user: user._id, description: over.description || 'hello world', privacy: 'public', ...over,
});
const descriptions = (out) => out.body.data.map((m) => m.description).sort();

test('applyMomentFilters: exact fields, all ignored, tags as $in, input untouched', () => {
  const base = { privacy: 'public' };
  const out = applyMomentFilters(base, { category: 'food', language: 'ko', mood: 'all', tags: 'a, b' });
  assert.deepEqual(out, { privacy: 'public', category: 'food', language: 'ko', tags: { $in: ['a', 'b'] } });
  assert.deepEqual(base, { privacy: 'public' });
  assert.deepEqual(applyMomentFilters(base, {}), { privacy: 'public' });
});

test('applyMomentFilters: q joins through $and and never replaces an existing $or', () => {
  const base = { $or: [{ privacy: 'public' }, { user: 'me' }] };
  const out = applyMomentFilters(base, { q: 'kimchi' });
  assert.deepEqual(out.$or, base.$or);
  assert.equal(out.$and.length, 1);
  assert.ok(out.$and[0].$or.some((c) => c.description));
});

test('applyMomentFilters: whitespace q is not a search; long q is truncated', () => {
  assert.equal(applyMomentFilters({}, { q: '   ' }).$and, undefined);
  const long = 'x'.repeat(250);
  const rx = applyMomentFilters({}, { q: long }).$and[0].$or[0].title;
  assert.equal(rx.source.length, 100);
});

test('metacharacters match literally', async () => {
  const u = await makeUser('a');
  await makeMoment(u, { description: 'I love c++ a lot' });
  await makeMoment(u, { description: 'I love c a lot' });
  const out = await run(controller.exploreMoments, { query: { q: 'c++' } });
  assert.equal(out.status, 200);
  assert.deepEqual(descriptions(out), ['I love c++ a lot']);
  const odd = await run(controller.exploreMoments, { query: { q: '(hi' } });
  assert.equal(odd.status, 200);
});

test('search finds Korean text, in the title, description or tags', async () => {
  const u = await makeUser('a');
  await makeMoment(u, { description: '오늘 김치를 먹었어요' });
  await makeMoment(u, { description: 'plain', title: '김치 레시피' });
  await makeMoment(u, { description: 'tagged', tags: ['김치'] });
  await makeMoment(u, { description: 'unrelated' });
  const out = await run(controller.exploreMoments, { query: { q: '김치' } });
  assert.deepEqual(descriptions(out), ['plain', 'tagged', '오늘 김치를 먹었어요']);
});

test('a search never surfaces another user\'s private moment (the $or hazard)', async () => {
  const viewer = await makeUser('viewer');
  const other = await makeUser('other');
  await makeMoment(other, { description: 'secret kimchi', privacy: 'private' });
  await makeMoment(other, { description: 'public kimchi' });
  await makeMoment(viewer, { description: 'my private kimchi', privacy: 'private' });
  const out = await run(controller.getMoments, { user: viewer, query: { q: 'kimchi' } });
  assert.deepEqual(descriptions(out), ['my private kimchi', 'public kimchi']);
});

test('each filter applies on /moments, /trending and /explore, with totals that agree', async () => {
  const u = await makeUser('a');
  await makeMoment(u, { description: 'food ko', category: 'food', language: 'ko', mood: 'happy' });
  await makeMoment(u, { description: 'travel en', category: 'travel', language: 'en', mood: 'happy' });
  for (const fn of ['getMoments', 'getTrendingMoments', 'exploreMoments']) {
    const out = await run(controller[fn], { query: { category: 'food' } });
    assert.deepEqual(descriptions(out), ['food ko'], fn);
    const byLang = await run(controller[fn], { query: { language: 'en' } });
    assert.deepEqual(descriptions(byLang), ['travel en'], fn);
  }
  const counted = await run(controller.exploreMoments, { query: { mood: 'happy' } });
  assert.equal(counted.body.data.length, 2);
});

test('no new params: every feed returns today\'s result', async () => {
  const u = await makeUser('a');
  await makeMoment(u, { description: 'one' });
  await makeMoment(u, { description: 'two', category: 'food' });
  for (const fn of ['getMoments', 'getTrendingMoments', 'exploreMoments']) {
    const out = await run(controller[fn], { query: {} });
    assert.deepEqual(descriptions(out), ['one', 'two'], fn);
  }
});

test('For You: an explicit language replaces its language scope', async () => {
  const viewer = await makeUser('viewer', { native_language: 'English', language_to_learn: 'Korean' });
  const u = await makeUser('author');
  await makeMoment(u, { description: 'korean post', language: 'ko' });
  await makeMoment(u, { description: 'japanese post', language: 'ja' });
  const scoped = await run(controller.getMoments, { user: viewer, query: { feed: 'forYou' } });
  assert.ok(!descriptions(scoped).includes('japanese post'));
  const explicit = await run(controller.getMoments, { user: viewer, query: { feed: 'forYou', language: 'ja' } });
  assert.deepEqual(descriptions(explicit), ['japanese post']);
});
```

- [ ] **Step 3: Run it — expect FAIL** (`Cannot find module '../lib/momentFilters'`)

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentFilters.test.js`

- [ ] **Step 4: Implement** — `lib/momentFilters.js`

```js
'use strict';

/**
 * Moment filters and search, applied server-side on every feed (spec section 1:
 * For You, Following, Trending, Explore). The web used to filter the ten
 * moments it had loaded; that missed everything on every other page.
 *
 * category / language / mood / tags behave exactly as exploreMoments always
 * applied them (exact match, 'all' ignored, tags a comma list matched with $in)
 * -- Explore now calls this, and its results must not change.
 *
 * q is new: a case-insensitive, escaped match on title, description or tags.
 * A regex rather than a $text index because MongoDB's text index splits words
 * on spaces, which does not work for Korean, Japanese or Chinese. Combined
 * through $and so it can never overwrite a feed's own top-level $or (public +
 * own posts) -- doing that would drop the privacy rule.
 */
const { escapeRegex } = require('./escapeRegex');

const MAX_Q = 100;

const applyMomentFilters = (query, params = {}) => {
  const out = { ...query };
  const { category, language, mood, tags, q } = params;

  if (category && category !== 'all') out.category = category;
  if (language && language !== 'all') out.language = language;
  if (mood && mood !== 'all') out.mood = mood;
  if (tags) {
    out.tags = { $in: String(tags).split(',').map((t) => t.trim()) };
  }

  const term = typeof q === 'string' ? q.trim().slice(0, MAX_Q) : '';
  if (term) {
    const rx = new RegExp(escapeRegex(term), 'i');
    out.$and = [...(out.$and || []), { $or: [{ title: rx }, { description: rx }, { tags: rx }] }];
  }
  return out;
};

module.exports = { applyMomentFilters, MAX_Q };
```

Confirm the export name first. `controllers/users.js` uses `const { escapeRegex } = require('../lib/escapeRegex');`, so the named export exists.

- [ ] **Step 5: Apply it in `controllers/moments.js`**

1. Add near the other `lib` requires:

   ```js
   const { applyMomentFilters } = require('../lib/momentFilters');
   ```

2. **`getMoments`** — immediately before `const RANKING_POOL = 300;`:

   ```js
   // Filters and search (lib/momentFilters). After the feed-mode branch, so an
   // explicit `language` REPLACES For You's own language scope rather than
   // intersecting it. The app sends only page/limit/feed here, so its requests
   // are unchanged.
   query = applyMomentFilters(query, req.query);
   ```

   `query` is declared with `let` in this function. If it is `const`, change it to `let`.

3. **`getTrendingMoments`** — immediately before `const RANKING_POOL = 300;` in that function:

   ```js
   query = applyMomentFilters(query, req.query);
   ```

4. **`exploreMoments`** — delete the inline block:

   ```js
     // Apply filters
     if (category && category !== 'all') query.category = category;
     if (language && language !== 'all') query.language = language;
     if (mood && mood !== 'all') query.mood = mood;
     if (tags) {
       const tagArray = tags.split(',').map(t => t.trim());
       query.tags = { $in: tagArray };
     }
   ```

   Replace it with:

   ```js
     // Same rules as always, now shared with every feed (lib/momentFilters),
     // plus `q`.
     query = applyMomentFilters(query, req.query);
   ```

   Then remove the now-unused `const { category, language, mood, tags } = req.query;` line.

- [ ] **Step 6: Run it — expect PASS**, then run the existing moment tests

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentFilters.test.js test/momentRanking.test.js test/momentAuthorStoryFlag.test.js`

- [ ] **Step 7: Full suite, npm 9 check, commit, merge, push, verify the deploy**

```bash
PATH=~/.nvm/versions/node/v24.18.0/bin:$PATH npm test 2>&1 | sed -n '/✖ failing tests:/,$p' | grep -E "^test at"
/private/tmp/claude-501/-Users-davis-Desktop-Personal-language-exchange-web-front/f4ebb588-39a1-4eba-864f-de64536f9fd1/scratchpad/npm9-check.sh
git add lib/momentFilters.js controllers/moments.js test/momentFilters.test.js
git commit -m "feat(moments): filters and search on every feed, server-side

category / language / mood / tags, as /explore always applied them, now work
on /moments (all feed modes) and /trending too, plus a new q: a
case-insensitive escaped match on title, description or tags. The web used
to filter only the ten moments it had loaded.

q joins through \$and so it never replaces a feed's own top-level \$or
(public + own posts); a test proves another user's private moment never
matches. An explicit language replaces For You's language scope. The app
sends none of these params to /moments or /trending and the same ones to
/explore, so its results are unchanged."
git checkout main && git merge --no-ff feat/moment-filters -m "Merge feat/moment-filters: filters and search on every feed" && git branch -d feat/moment-filters
git fetch && git log --oneline main..origin/main   # must print nothing
git push origin main
gh run watch "$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
```

---

### Task 2: Scheduled moments wait — behind `MOMENT_SCHEDULING_ENFORCED` (default off)

**Files:**
- Create: `lib/momentScheduling.js`, `scripts/countFutureScheduledMoments.js`
- Modify:
  - `controllers/moments.js`: `getMoments` (`publicQuery`, the anonymous query, `followingQuery`), `getTrendingMoments`, `exploreMoments`, `getUserMoments`, `getMoment`, `createMoment`, `updateMoment`;
  - `controllers/og.js` (`buildMomentOg`);
  - `controllers/appConfig.js`.
- Test: `test/momentScheduling.test.js`

**Interfaces — Produces:**

```js
// lib/momentScheduling.js
schedulingEnforced() => boolean                        // process.env.MOMENT_SCHEDULING_ENFORCED === 'true', per call
visibleNowFilter(now = new Date()) => { scheduledFor: { $not: { $gt: now } } }
isScheduled(moment, now = new Date()) => boolean       // scheduledFor set and in the future
```

New response field: `/app-config` `data.momentSchedulingEnforced: boolean`.

- [ ] **Step 1: Branch** (after Task 1 is merged)

```bash
git checkout main && git pull --ff-only && git checkout -b feat/moment-scheduling
```

- [ ] **Step 2: Write the failing test** — `test/momentScheduling.test.js`. It uses the same `run`, `makeUser` and `makeMoment` harness as Task 1; copy those helpers in verbatim with `dbName: 'momentScheduling'`.

```js
'use strict';

/**
 * Scheduled moments (spec section 2). The app has always stored scheduledFor,
 * but no read filtered on it -- a moment scheduled for tomorrow was public now.
 * Enforcement ships OFF; the user counts the affected rows first.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, User, Moment, controller, og, appConfig;

// --- harness: identical to test/momentFilters.test.js ---
const run = (fn, req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
    set() { return this; }, type() { return this; }, send(body) { resolve({ status: this.statusCode, body }); },
  };
  fn({ protocol: 'https', get: () => 'api.example.com', query: {}, params: {}, body: {}, ...req }, res,
    (err) => (err ? resolve({ status: err.statusCode || 500, error: err.message }) : resolve({ status: 204 })))
    .catch(reject);
});

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'momentScheduling' });
  User = require('../models/User');
  Moment = require('../models/Moment');
  controller = require('../controllers/moments');
  appConfig = require('../controllers/appConfig');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([User.deleteMany({}), Moment.deleteMany({})]);
  delete process.env.MOMENT_SCHEDULING_ENFORCED;
});

const makeUser = (name, extra = {}) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean', ...extra,
});
const tomorrow = () => new Date(Date.now() + 24 * 3600e3);
const makeMoment = (user, over = {}) => Moment.create({ user: user._id, description: 'x', privacy: 'public', ...over });
const descs = (out) => out.body.data.map((m) => m.description).sort();
const enforce = () => { process.env.MOMENT_SCHEDULING_ENFORCED = 'true'; };

test('switch OFF (default): a future moment is visible everywhere, exactly as today', async () => {
  const author = await makeUser('author');
  const viewer = await makeUser('viewer');
  await makeMoment(author, { description: 'later', scheduledFor: tomorrow() });
  await makeMoment(author, { description: 'now' });
  for (const fn of ['getMoments', 'getTrendingMoments', 'exploreMoments']) {
    assert.deepEqual(descs(await run(controller[fn], { user: viewer })), ['later', 'now'], fn);
  }
});

test('switch ON: hidden from others on every listed read, visible to its author', async () => {
  enforce();
  const author = await makeUser('author');
  const viewer = await makeUser('viewer', { following: [] });
  const later = await makeMoment(author, { description: 'later', scheduledFor: tomorrow() });
  await makeMoment(author, { description: 'now' });
  await User.updateOne({ _id: viewer._id }, { $set: { following: [author._id] } });
  const follower = await User.findById(viewer._id);

  for (const fn of ['getMoments', 'getTrendingMoments', 'exploreMoments']) {
    assert.deepEqual(descs(await run(controller[fn], { user: viewer })), ['now'], fn);
    assert.deepEqual(descs(await run(controller[fn], {})), ['now'], `${fn} anonymous`);
  }
  assert.deepEqual(descs(await run(controller.getMoments, { user: follower, query: { feed: 'following' } })), ['now']);
  assert.deepEqual(descs(await run(controller.getUserMoments, { user: viewer, params: { userId: author._id.toString() } })), ['now']);
  assert.equal((await run(controller.getMoment, { user: viewer, params: { id: later._id.toString() } })).status, 404);

  // The author still sees it.
  assert.ok(descs(await run(controller.getMoments, { user: author })).includes('later'));
  assert.ok(descs(await run(controller.getUserMoments, { user: author, params: { userId: author._id.toString() } })).includes('later'));
  assert.equal((await run(controller.getMoment, { user: author, params: { id: later._id.toString() } })).status, 200);
});

test('switch ON: it appears once scheduledFor has passed', async () => {
  enforce();
  const author = await makeUser('author');
  const viewer = await makeUser('viewer');
  await makeMoment(author, { description: 'was scheduled', scheduledFor: new Date(Date.now() - 60e3) });
  assert.deepEqual(descs(await run(controller.exploreMoments, { user: viewer })), ['was scheduled']);
});

test('switch ON: create moves createdAt to scheduledFor and skips the follower push', async () => {
  enforce();
  const author = await makeUser('author', { userMode: 'regular' });
  const notificationService = require('../services/notificationService');
  const original = notificationService.sendFollowerMoment;
  let pushed = 0;
  notificationService.sendFollowerMoment = async () => { pushed += 1; };
  try {
    const when = tomorrow();
    const out = await run(controller.createMoment, { user: author, body: { description: 'later', scheduledFor: when.toISOString() } });
    assert.equal(out.status, 201, out.error);
    const saved = await Moment.findById(out.body.data._id);
    assert.equal(saved.createdAt.getTime(), when.getTime());
    assert.equal(pushed, 0);
    const plain = await run(controller.createMoment, { user: author, body: { description: 'now' } });
    assert.equal(plain.status, 201, plain.error);
    assert.equal(pushed, 1);
  } finally {
    notificationService.sendFollowerMoment = original;
  }
});

test('switch OFF: create keeps today\'s createdAt and push', async () => {
  const author = await makeUser('author', { userMode: 'regular' });
  const notificationService = require('../services/notificationService');
  const original = notificationService.sendFollowerMoment;
  let pushed = 0;
  notificationService.sendFollowerMoment = async () => { pushed += 1; };
  try {
    const out = await run(controller.createMoment, { user: author, body: { description: 'later', scheduledFor: tomorrow().toISOString() } });
    const saved = await Moment.findById(out.body.data._id);
    assert.ok(Math.abs(saved.createdAt.getTime() - Date.now()) < 60e3);
    assert.equal(pushed, 1);
  } finally {
    notificationService.sendFollowerMoment = original;
  }
});

test('switch ON: update follows scheduledFor while unpublished, and is frozen once public', async () => {
  enforce();
  const author = await makeUser('author');
  const later = await makeMoment(author, { description: 'later', scheduledFor: tomorrow(), createdAt: tomorrow() });
  const moved = new Date(Date.now() + 48 * 3600e3);
  await run(controller.updateMoment, { user: author, params: { id: later._id.toString() }, body: { scheduledFor: moved.toISOString() } });
  assert.equal((await Moment.findById(later._id)).createdAt.getTime(), moved.getTime());

  const published = await makeMoment(author, { description: 'public', createdAt: new Date('2026-01-01T00:00:00Z') });
  await run(controller.updateMoment, { user: author, params: { id: published._id.toString() }, body: { scheduledFor: tomorrow().toISOString() } });
  assert.equal((await Moment.findById(published._id)).createdAt.toISOString(), '2026-01-01T00:00:00.000Z');
});

test('switch ON: clearing the schedule publishes now, at the top', async () => {
  enforce();
  const author = await makeUser('author');
  const later = await makeMoment(author, { description: 'later', scheduledFor: tomorrow(), createdAt: tomorrow() });
  await run(controller.updateMoment, { user: author, params: { id: later._id.toString() }, body: { scheduledFor: null } });
  const saved = await Moment.findById(later._id);
  assert.equal(saved.scheduledFor, null);
  assert.ok(Math.abs(saved.createdAt.getTime() - Date.now()) < 60e3);
});

test('update rejects a past scheduledFor, switch on or off', async () => {
  const author = await makeUser('author');
  const m = await makeMoment(author);
  const out = await run(controller.updateMoment, { user: author, params: { id: m._id.toString() }, body: { scheduledFor: '2020-01-01T00:00:00Z' } });
  assert.equal(out.status, 400);
});

test('an unparseable scheduledFor is rejected', async () => {
  const author = await makeUser('author');
  const m = await makeMoment(author, { description: 'kept' });
  const out = await run(controller.updateMoment, { user: author, params: { id: m._id.toString() }, body: { scheduledFor: 'not a date', description: 'changed' } });
  assert.equal(out.status, 400);
  assert.equal((await Moment.findById(m._id)).description, 'kept');
});

test('switch ON: the OG preview does not leak a scheduled moment', async () => {
  enforce();
  const author = await makeUser('author');
  const later = await makeMoment(author, { description: 'secret plans', scheduledFor: tomorrow() });
  og = require('../controllers/og');
  const out = await run(og.getOg, { params: { type: 'moment', id: later._id.toString() } });
  assert.ok(!String(out.body || '').includes('secret plans'));
});

test('/app-config says whether scheduling is enforced, per request', async () => {
  const off = await run(appConfig.getAppConfig, {});
  assert.equal(off.body.data.momentSchedulingEnforced, false);
  enforce();
  const on = await run(appConfig.getAppConfig, {});
  assert.equal(on.body.data.momentSchedulingEnforced, true);
});
```

Note on the OG test: `getOg` writes HTML via `res.send` / `res.type`, which the harness above stubs. If `og.js` uses different response methods (check with `grep -n "res\." controllers/og.js`), stub those as well, and record a ledger ruling if the assertion has to read a different field.

- [ ] **Step 3: Run it — expect FAIL** on every "switch ON" test, the update-rejection tests and app-config

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentScheduling.test.js`

- [ ] **Step 4: Implement `lib/momentScheduling.js`**

```js
'use strict';

/**
 * Scheduled moments (spec section 2). createMoment always stored scheduledFor,
 * but no read filtered on it and no job published later, so a moment scheduled
 * for tomorrow was public now.
 *
 * MOMENT_SCHEDULING_ENFORCED is OFF unless set to 'true' -- moments already
 * scheduled for a future time are public today and would vanish the moment
 * enforcement starts, so the user counts them first
 * (scripts/countFutureScheduledMoments.js). Read per call, never at load.
 */
const schedulingEnforced = () => process.env.MOMENT_SCHEDULING_ENFORCED === 'true';

/**
 * Not scheduled for later: null, missing and past values all pass. $not/$gt
 * rather than an $or, so it can sit beside a feed's own top-level $or and the
 * search clause without colliding with either.
 */
const visibleNowFilter = (now = new Date()) => ({ scheduledFor: { $not: { $gt: now } } });

const isScheduled = (moment, now = new Date()) =>
  Boolean(moment && moment.scheduledFor && new Date(moment.scheduledFor) > now);

module.exports = { schedulingEnforced, visibleNowFilter, isScheduled };
```

- [ ] **Step 5: Apply it in `controllers/moments.js`**

1. Add near the other `lib` requires:

   ```js
   const { schedulingEnforced, visibleNowFilter, isScheduled } = require('../lib/momentScheduling');
   ```

2. **`getMoments`.** After the `let query = excludeReels({...})` line:

   ```js
   // Scheduled moments are visible only to their author until scheduledFor
   // (lib/momentScheduling) -- applied to the public side of each query, never
   // to the author's own posts. Empty while the switch is off.
   const visibleNow = schedulingEnforced() ? visibleNowFilter() : {};
   ```

   Then spread it in three places:
   - the anonymous `query = excludeReels({ privacy: 'public', isDeleted: { $ne: true } })` gets `...visibleNow` inside its object, so the declaration above uses it too: `let query = excludeReels({ privacy: 'public', isDeleted: { $ne: true }, ...visibleNow });`;
   - `publicQuery` gets `...visibleNow`;
   - `followingQuery` gets `...visibleNow`.

   Leave `ownPostsQuery` alone.

3. **`getTrendingMoments`** and **`exploreMoments`**: add `...(schedulingEnforced() ? visibleNowFilter() : {})` inside each function's `excludeReels({...})` query object.

4. **`getUserMoments`.** Inside `if (!req.user || req.user._id.toString() !== targetUserId) { query.privacy = 'public'; }`, also add:

   ```js
       if (schedulingEnforced()) Object.assign(query, visibleNowFilter());
   ```

5. **`getMoment`.** After the `if (!moment) { ... 404 }` check:

   ```js
     // Until it is published, a scheduled moment exists only for its author.
     if (schedulingEnforced() && isScheduled(moment)
         && (!req.user || moment.user._id.toString() !== req.user._id.toString())) {
       return next(new ErrorResponse(`Moment not found with id of ${req.params.id}`, 404));
     }
   ```

6. **`createMoment`.**
   - After `momentData` is built, before the `req.files` image block:

     ```js
     // Enforced scheduling: the moment surfaces at its publish time, not buried at
     // the position it was written (feeds sort by createdAt).
     const scheduledLater = schedulingEnforced() && isScheduled({ scheduledFor });
     if (scheduledLater) momentData.createdAt = new Date(scheduledFor);
     ```

   - Wrap the follower push, `notificationService.sendFollowerMoment(...)`, in `if (!scheduledLater) { ... }`, with the comment:

     ```js
     // No push for a moment followers cannot open yet (getMoment 404s it).
     // A push at publish time is out of scope.
     ```

7. **`updateMoment`.** After the `EDITABLE_FIELDS` loop:

   ```js
     // scheduledFor: never a past or unparseable time (createMoment has always
     // rejected the past; the app's update never sends this field).
     if (updateData.scheduledFor !== undefined && updateData.scheduledFor !== null) {
       const when = new Date(updateData.scheduledFor);
       if (isNaN(when.getTime())) {
         return next(new ErrorResponse('Scheduled date is not a valid date', 400));
       }
       if (when < new Date()) {
         return next(new ErrorResponse('Scheduled date must be in the future', 400));
       }
     }
     // Enforced scheduling: while the moment is still unpublished, createdAt
     // follows its publish time -- a new future time moves it, clearing the
     // schedule publishes now. Once public, createdAt is never rewritten.
     if (schedulingEnforced() && updateData.scheduledFor !== undefined && isScheduled(moment)) {
       updateData.createdAt = updateData.scheduledFor ? new Date(updateData.scheduledFor) : new Date();
     }
   ```

- [ ] **Step 6: Apply it in `controllers/og.js` and `controllers/appConfig.js`**

1. `og.js` `buildMomentOg`. After `if (!moment) return null;`:

   ```js
     // A scheduled moment is not public yet; a share preview must not leak it.
     const { schedulingEnforced, isScheduled } = require('../lib/momentScheduling');
     if (schedulingEnforced() && isScheduled(moment)) return null;
   ```

2. `appConfig.js`, in the `data` object, after `reelsEnabled: REELS_ENABLED,`:

   ```js
         // Read per request: the web shows its schedule picker only while
         // scheduled moments actually wait (lib/momentScheduling).
         momentSchedulingEnforced: process.env.MOMENT_SCHEDULING_ENFORCED === 'true',
   ```

- [ ] **Step 7: The read-only count script** — `scripts/countFutureScheduledMoments.js`

```js
'use strict';
/**
 * READ-ONLY. How many moments MOMENT_SCHEDULING_ENFORCED=true would hide right
 * now: not deleted, scheduledFor in the future. Run before turning it on.
 *
 *   node scripts/countFutureScheduledMoments.js
 */
require('dotenv').config({ path: './config/config.env' });
const mongoose = require('mongoose');

(async () => {
  if (!process.env.MONGO_URI) {
    console.error('MONGO_URI is not set');
    process.exit(1);
  }
  await mongoose.connect(process.env.MONGO_URI);
  const Moment = require('../models/Moment');
  const now = new Date();
  const rows = await Moment.aggregate([
    { $match: { isDeleted: { $ne: true }, scheduledFor: { $gt: now } } },
    { $group: { _id: '$privacy', moments: { $sum: 1 }, likes: { $sum: { $ifNull: ['$likeCount', 0] } },
      comments: { $sum: { $ifNull: ['$commentCount', 0] } }, latest: { $max: '$scheduledFor' } } },
    { $sort: { _id: 1 } },
  ]);
  const total = rows.reduce((n, r) => n + r.moments, 0);
  console.log(`Moments enforcement would hide now: ${total}`);
  rows.forEach((r) => console.log(`  ${r._id || '(none)'}: ${r.moments} moments, ${r.likes} likes, ${r.comments} comments, last one scheduled for ${r.latest && r.latest.toISOString()}`));
  await mongoose.disconnect();
})().catch((err) => { console.error(err); process.exit(1); });
```

Add a test that the script's aggregation counts correctly. Put it in `test/momentScheduling.test.js`, with the pipeline exported for testing: move the `$match`/`$group` array into an exported `futureScheduledPipeline(now)` inside `lib/momentScheduling.js`, have the script import it, and test the pipeline against seeded data:

```js
test('the count script\'s pipeline counts only future, non-deleted moments', async () => {
  const { futureScheduledPipeline } = require('../lib/momentScheduling');
  const a = await makeUser('a');
  await makeMoment(a, { scheduledFor: tomorrow(), likeCount: 2 });
  await makeMoment(a, { scheduledFor: tomorrow(), privacy: 'friends' });
  await makeMoment(a, { scheduledFor: new Date(Date.now() - 60e3) });
  await makeMoment(a, { scheduledFor: tomorrow(), isDeleted: true });
  const rows = await Moment.aggregate(futureScheduledPipeline(new Date()));
  assert.deepEqual(rows.map((r) => [r._id, r.moments, r.likes]), [['friends', 1, 0], ['public', 1, 2]]);
});
```

The implementation in `lib/momentScheduling.js`, exported alongside the others:

```js
const futureScheduledPipeline = (now = new Date()) => [
  { $match: { isDeleted: { $ne: true }, scheduledFor: { $gt: now } } },
  { $group: { _id: '$privacy', moments: { $sum: 1 }, likes: { $sum: { $ifNull: ['$likeCount', 0] } },
    comments: { $sum: { $ifNull: ['$commentCount', 0] } }, latest: { $max: '$scheduledFor' } } },
  { $sort: { _id: 1 } },
];
```

The script then calls `Moment.aggregate(futureScheduledPipeline(now))`.

- [ ] **Step 8: Run — expect PASS**, plus the Task 1 file and existing moment tests

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentScheduling.test.js test/momentFilters.test.js test/momentUpdateWhitelist.test.js`

- [ ] **Step 9: Full suite, npm 9 check, commit, merge, push, verify** — the same commands as Task 1, Step 7, with:
  - files: `lib/momentScheduling.js scripts/countFutureScheduledMoments.js controllers/moments.js controllers/og.js controllers/appConfig.js test/momentScheduling.test.js`;
  - message: `feat(moments): scheduled moments wait -- behind MOMENT_SCHEDULING_ENFORCED, off`;
  - merge `feat/moment-scheduling`.

  The commit body must state:
  - the switch ships **off**, so production behaviour is unchanged until the user runs the count script and sets `MOMENT_SCHEDULING_ENFORCED=true`;
  - what turning it on does: reads, the OG preview, `createdAt`, the push skip;
  - that `/app-config` gains `momentSchedulingEnforced`.

---

### Task 3: App moment reports reach the moderators' desk — `MOMENT_REPORTS_TO_DESK`

**Files:**
- Create: `lib/reportReasons.js`
- Modify: `controllers/moments.js` `reportMoment` — after `await moment.save();`, before the success response.
- Test: `test/momentReportsToDesk.test.js`

**Interfaces — Produces:**

```js
toReportReason(reason) => 'spam'|'harassment'|'hate_speech'|'violence'|'false_information'|'other'|...
```

The mapping is pinned by the spec: `misinformation` → `false_information`, `inappropriate` → `other`. Every value already valid in the `Report` enum passes through unchanged. Anything unknown becomes `other`.

- [ ] **Step 1: Branch** (after Task 2 is merged)

```bash
git checkout main && git pull --ff-only && git checkout -b feat/moment-reports-to-desk
```

- [ ] **Step 2: Write the failing test** — `test/momentReportsToDesk.test.js`. Use the same harness and `makeUser` / `makeMoment` as Task 2, with `dbName: 'momentReportsToDesk'`; also require `Report = require('../models/Report')` in `before`, and add `Report.deleteMany({})` to `beforeEach`.

```js
const { toReportReason } = require('../lib/reportReasons');

test('reason mapping pinned by the spec', () => {
  assert.equal(toReportReason('misinformation'), 'false_information');
  assert.equal(toReportReason('inappropriate'), 'other');
  for (const same of ['spam', 'harassment', 'hate_speech', 'violence', 'other', 'nudity', 'false_information', 'copyright']) {
    assert.equal(toReportReason(same), same);
  }
  assert.equal(toReportReason('nonsense'), 'other');
});

test('the legacy endpoint\'s response is unchanged, and a Report row is created', async () => {
  const author = await makeUser('author');
  const reporter = await makeUser('reporter');
  const m = await makeMoment(author);
  const out = await run(controller.reportMoment, { user: reporter, params: { id: m._id.toString() }, body: { reason: 'misinformation', description: 'nope' } });
  assert.deepEqual(out.body, { success: true, message: 'Report submitted successfully. Our team will review it.' });
  const rows = await Report.find({ type: 'moment', reportId: m._id }).lean();
  assert.equal(rows.length, 1);
  assert.equal(rows[0].reason, 'false_information');
  assert.equal(String(rows[0].reportedUser), String(author._id));
  assert.equal(String(rows[0].reportedBy), String(reporter._id));
  assert.equal(rows[0].description, 'nope');
});

test('no second row when any earlier Report exists, whatever its status', async () => {
  const author = await makeUser('author');
  const reporter = await makeUser('reporter');
  const m = await makeMoment(author);
  await Report.create({ type: 'moment', reportId: m._id, reportedBy: reporter._id, reportedUser: author._id, reason: 'spam', status: 'resolved' });
  await run(controller.reportMoment, { user: reporter, params: { id: m._id.toString() }, body: { reason: 'spam' } });
  assert.equal(await Report.countDocuments({ type: 'moment', reportId: m._id }), 1);
});

test('forward-only: a reporter who reported before this deploy gets no backfilled row', async () => {
  const author = await makeUser('author');
  const reporter = await makeUser('reporter');
  const m = await makeMoment(author);
  await Moment.updateOne({ _id: m._id }, { $push: { reports: { user: reporter._id, reason: 'spam', reportedAt: new Date(), status: 'pending' } } });
  const out = await run(controller.reportMoment, { user: reporter, params: { id: m._id.toString() }, body: { reason: 'spam' } });
  assert.equal(out.body.message, 'You have already reported this moment');
  assert.equal(await Report.countDocuments({}), 0);
});

test('a duplicate-key race is swallowed', async () => {
  const author = await makeUser('author');
  const reporter = await makeUser('reporter');
  const m = await makeMoment(author);
  const original = Report.create;
  Report.create = async () => { const e = new Error('dup'); e.code = 11000; throw e; };
  try {
    const out = await run(controller.reportMoment, { user: reporter, params: { id: m._id.toString() }, body: { reason: 'spam' } });
    assert.equal(out.body.success, true);
  } finally {
    Report.create = original;
  }
});

test('record only: no admin email, no reel auto-hide', async () => {
  const author = await makeUser('author');
  const m = await makeMoment(author, { isReel: true });
  const emailService = require('../services/emailService');
  const original = emailService.sendAdminReportAlert;
  let emails = 0;
  emailService.sendAdminReportAlert = async () => { emails += 1; };
  try {
    for (const name of ['r1', 'r2', 'r3']) {
      const reporter = await makeUser(name);
      await run(controller.reportMoment, { user: reporter, params: { id: m._id.toString() }, body: { reason: 'spam' } });
    }
  } finally {
    emailService.sendAdminReportAlert = original;
  }
  assert.equal(emails, 0);
  assert.equal(await Report.countDocuments({ type: 'moment', reportId: m._id }), 3);
  assert.notEqual((await Moment.findById(m._id)).hiddenPendingReview, true);
});

test('MOMENT_REPORTS_TO_DESK=false stops the dual-write, read per request', async () => {
  const author = await makeUser('author');
  const reporter = await makeUser('reporter');
  const m = await makeMoment(author);
  process.env.MOMENT_REPORTS_TO_DESK = 'false';
  try {
    await run(controller.reportMoment, { user: reporter, params: { id: m._id.toString() }, body: { reason: 'spam' } });
  } finally {
    delete process.env.MOMENT_REPORTS_TO_DESK;
  }
  assert.equal(await Report.countDocuments({}), 0);
});

test('a Report write failure does not fail the request', async () => {
  const author = await makeUser('author');
  const reporter = await makeUser('reporter');
  const m = await makeMoment(author);
  const original = Report.create;
  Report.create = async () => { throw new Error('db down'); };
  try {
    const out = await run(controller.reportMoment, { user: reporter, params: { id: m._id.toString() }, body: { reason: 'spam' } });
    assert.equal(out.status, 200);
    assert.equal(out.body.success, true);
  } finally {
    Report.create = original;
  }
});
```

`emailService` path: confirm it with `grep -rn "sendAdminReportAlert" controllers/report.js` and use the module that call imports.

- [ ] **Step 3: Run — expect FAIL** (module missing; no `Report` rows)

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentReportsToDesk.test.js`

- [ ] **Step 4: Implement `lib/reportReasons.js`**

```js
'use strict';

/**
 * Map a moment report reason from the embedded enum the app sends
 * (models/Moment.js reports.reason) onto the Report model's enum. Pinned by
 * the user in spec section 3: misinformation -> false_information,
 * inappropriate -> other ("inappropriate" is broader than nudity). Values the
 * Report enum already has pass through; anything else is 'other'.
 */
const REPORT_REASONS = ['spam', 'harassment', 'hate_speech', 'violence', 'nudity', 'false_information', 'copyright', 'other'];
const MAP = { misinformation: 'false_information', inappropriate: 'other' };

const toReportReason = (reason) => {
  if (MAP[reason]) return MAP[reason];
  return REPORT_REASONS.includes(reason) ? reason : 'other';
};

module.exports = { toReportReason, REPORT_REASONS };
```

- [ ] **Step 5: Apply it in `reportMoment`**

Add at the top of `controllers/moments.js`:

```js
const { toReportReason } = require('../lib/reportReasons');
```

In `reportMoment`, between `await moment.save();` and the success `res.status(200).json(...)`:

```js
  // Also record it where the moderators' desk reads (the Report collection);
  // the embedded push above stays, existing code reads it. Record only: none
  // of createReport's side effects (no admin email, no reel auto-hide) -- the
  // user's choice. Forward-only: the early return above means people who
  // reported before this get no backfilled row. A failure here is logged and
  // never fails the request. Off with MOMENT_REPORTS_TO_DESK=false.
  if (process.env.MOMENT_REPORTS_TO_DESK !== 'false') {
    try {
      const Report = require('../models/Report');
      const exists = await Report.exists({ reportedBy: req.user._id, type: 'moment', reportId: moment._id });
      if (!exists) {
        await Report.create({
          type: 'moment',
          reportId: moment._id,
          reportedBy: req.user._id,
          reportedUser: moment.user,
          reason: toReportReason(reason),
          description: description || '',
        });
      }
    } catch (err) {
      if (err && err.code !== 11000) {
        console.error('moment report -> Report desk failed:', err.message || err);
      }
    }
  }
```

Use the module-level `Report` only if `controllers/moments.js` already requires it. Otherwise the inline `require` above keeps the test's `Report.create` stub in effect, because the stub is applied to the same cached module object.

- [ ] **Step 6: Run — expect PASS**

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentReportsToDesk.test.js`

- [ ] **Step 7: Full suite, npm 9 check, commit, merge, push, verify** — the same commands as Task 1, Step 7, with:
  - files: `lib/reportReasons.js controllers/moments.js test/momentReportsToDesk.test.js`;
  - message: `fix(moments): app moment reports reach the moderators' desk`;
  - merge `feat/moment-reports-to-desk`.

  The commit body states:
  - the dual-write, the reason mapping, record-only, forward-only;
  - the `MOMENT_REPORTS_TO_DESK` switch;
  - that the app's response is unchanged.

---

### Task 4: `DELETE /moments/:id/audio`

**Files:**
- Modify:
  - `controllers/moments.js` — add `deleteAudio` after `deleteVideo`;
  - `routes/moments.js` — chain `.delete(protect, deleteAudio)` onto the `/:id/audio` route, and add `deleteAudio` to the controller import list.
- Test: `test/momentDeleteAudio.test.js`

**Interfaces — Produces:** `DELETE /api/v1/moments/:id/audio` → `{ success, data: { _id, mediaType }, message }`. It is owner-only, answers 404 if the moment is missing and 400 if it has no audio. It mirrors `deleteVideo`.

- [ ] **Step 1: Branch** (after Task 3 is merged)

```bash
git checkout main && git pull --ff-only && git checkout -b feat/moment-delete-audio
```

- [ ] **Step 2: Write the failing test** — `test/momentDeleteAudio.test.js`. Same harness, `dbName: 'momentDeleteAudio'`. Stub Spaces deletion so no network is touched: `require('../utils/deleteFromSpaces')` is a function, so the test reaches through `require.cache` instead:

```js
let deleted = [];
test.before(() => {
  const p = require.resolve('../utils/deleteFromSpaces');
  require.cache[p] = { id: p, filename: p, loaded: true, exports: async (url) => { deleted.push(url); } };
});
// ...then require('../controllers/moments') AFTER this, so it picks up the stub.

const withAudio = (user, over = {}) => Moment.create({ user: user._id, description: 'voice', privacy: 'public',
  mediaType: 'audio', audio: { url: 'https://cdn.x/a.m4a', duration: 12, mimeType: 'audio/mp4', fileSize: 1000 }, ...over });

test('owner removes the voice note: audio cleared, mediaType text, file deleted', async () => {
  deleted = [];
  const owner = await makeUser('owner');
  const m = await withAudio(owner);
  const out = await run(controller.deleteAudio, { user: owner, params: { id: m._id.toString() } });
  assert.equal(out.status, 200, out.error);
  assert.equal(out.body.data.mediaType, 'text');
  const saved = await Moment.findById(m._id);
  assert.equal(saved.audio.url, null);
  assert.equal(saved.mediaType, 'text');
  assert.deepEqual(deleted, ['https://cdn.x/a.m4a']);
});

test('a moment that also has images becomes an image moment', async () => {
  const owner = await makeUser('owner');
  const m = await withAudio(owner, { images: ['https://cdn.x/p.jpg'] });
  const out = await run(controller.deleteAudio, { user: owner, params: { id: m._id.toString() } });
  assert.equal(out.body.data.mediaType, 'image');
});

test('only the owner; 404 when missing; 400 without audio', async () => {
  const owner = await makeUser('owner');
  const other = await makeUser('other');
  const m = await withAudio(owner);
  assert.equal((await run(controller.deleteAudio, { user: other, params: { id: m._id.toString() } })).status, 403);
  assert.equal((await run(controller.deleteAudio, { user: owner, params: { id: new mongoose.Types.ObjectId().toString() } })).status, 404);
  const plain = await Moment.create({ user: owner._id, description: 'text' });
  assert.equal((await run(controller.deleteAudio, { user: owner, params: { id: plain._id.toString() } })).status, 400);
});

test('the route is wired, behind protect', () => {
  const src = require('fs').readFileSync(require('path').join(__dirname, '..', 'routes', 'moments.js'), 'utf8');
  assert.match(src, /route\('\/:id\/audio'\)[\s\S]*?\.delete\(protect, deleteAudio\)/);
});
```

- [ ] **Step 3: Run — expect FAIL** (`controller.deleteAudio` is not a function)

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentDeleteAudio.test.js`

- [ ] **Step 4: Implement**

Add `deleteAudio` to `controllers/moments.js`, after `deleteVideo`:

```js
/**
 * @desc    Delete the voice note from a moment
 * @route   DELETE /api/v1/moments/:id/audio
 * @access  Private (owner)
 *
 * PUT /:id/audio could replace a voice note but nothing could remove one.
 * Mirrors deleteVideo: owner-only, Spaces file removed best-effort, mediaType
 * falls back to image or text.
 */
exports.deleteAudio = asyncHandler(async (req, res, next) => {
  const moment = await Moment.findById(req.params.id);
  if (!moment) {
    return next(new ErrorResponse(`Moment not found with id of ${req.params.id}`, 404));
  }
  if (moment.user.toString() !== req.user._id.toString()) {
    return next(new ErrorResponse('Not authorized to delete audio from this moment', 403));
  }
  if (!moment.audio || !moment.audio.url) {
    return next(new ErrorResponse('This moment does not have a voice note', 400));
  }

  try {
    await deleteFromSpaces(moment.audio.url);
  } catch (err) {
    console.error('Failed to delete audio from Spaces:', err.message);
  }

  moment.audio = { url: null, duration: null, waveform: undefined, mimeType: null, fileSize: null };
  moment.mediaType = moment.images && moment.images.length > 0 ? 'image' : 'text';
  await moment.save();

  res.status(200).json({
    success: true,
    data: { _id: moment._id, mediaType: moment.mediaType },
    message: 'Voice note deleted successfully'
  });
});
```

In `routes/moments.js`:
- add `deleteAudio,` next to `deleteVideo,` in the controller import list;
- change the audio route to:

  ```js
  router.route('/:id/audio')
    .put(
      protect,
      uploadSingle('audio', 'bananatalk/moments/audio'),
      momentAudioUpload
    )
    .delete(protect, deleteAudio);
  ```

- [ ] **Step 5: Run — expect PASS**

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/momentDeleteAudio.test.js`

- [ ] **Step 6: Full suite, npm 9 check, commit, merge, push, verify** — the same as Task 1, Step 7, with:
  - files: `controllers/moments.js routes/moments.js test/momentDeleteAudio.test.js`;
  - message: `feat(moments): DELETE /moments/:id/audio removes a voice note`;
  - merge `feat/moment-delete-audio`.

---

## After all tasks

Run the final whole-range review: a fresh reviewer on the most capable model over every merged range. Then report to the user:
- **the switch states:** `MOMENT_SCHEDULING_ENFORCED` is off; `MOMENT_REPORTS_TO_DESK` is on and record-only;
- **the exact command to run on the droplet before enabling scheduling:** `cd <app dir> && node scripts/countFutureScheduledMoments.js`.
