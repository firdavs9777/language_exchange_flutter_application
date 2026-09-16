# Monetization (Backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** make it possible to take a payment — cap what is actually scarce, expose paywalls where desire exists, and log every purchase and paywall event so $0 is never ambiguous again.

**Architecture:** All new limit logic is a pure function in `lib/`, wrapped by an `asyncHandler` middleware in `middleware/`, wired into existing routes. Two new append-only collections record purchase attempts and paywall events. Nothing existing is made stricter except the two caps the spec names.

**Tech Stack:** Node 24, Express, Mongoose 6, `node:test`, `mongodb-memory-server`.

**Spec:** `docs/superpowers/specs/2026-09-15-monetization-design.md`

## Global Constraints

- **Nothing is taken away.** Every allowance in `config/limitations.js` keeps its current value except the two new fields this plan adds. Task 9 pins this with a test.
- **"Free" means BOTH the `visitor` and `regular` tiers** — they get identical caps.
- **Conversation STARTS are capped; replies never are.** A start is the first message between two users with no existing `Conversation`. Re-opening a dormant conversation is a reply.
- **The cap consumes the INITIATOR's quota only.** A recipient is never rate-limited by other people's interest in them.
- **Quota resets on the user's LOCAL day**, from `User.timezone` (IANA, nullable), falling back to UTC. This deliberately diverges from `lib/dailyCompletion.js`'s UTC `toDateKey`.
- **Ad credits expire at the same local-day boundary and never accumulate.**
- Free new-conversation limit: **3/day**. Free chat-translation limit: **10/day**. VIP: unlimited (`-1`).
- All new models are **append-only logs**. No updates, no deletes.
- Every new file gets tests in `test/` run by `npm test` (`node --test`).
- Repo: `/Users/davis/Desktop/Personal/language_exchange_backend_application`.

## File Structure

| File | Responsibility |
|---|---|
| `lib/localDay.js` (new) | One job: turn a Date + IANA timezone into a `YYYY-MM-DD` local day key. |
| `lib/conversationQuota.js` (new) | One job: given a stored quota blob, today's key and a limit, say what is allowed. Pure. |
| `middleware/checkConversationStart.js` (new) | Express glue: load user, detect whether this message starts a conversation, apply the quota. |
| `models/PurchaseAttempt.js` (new) | Append-only record of every purchase verification attempt. |
| `models/PaywallEvent.js` (new) | Append-only record of paywall shown/dismissed/converted. |
| `controllers/paywallEvents.js` (new) | Single POST endpoint the app calls to record a paywall event. |
| `config/limitations.js` (modify) | Add `newConversationsPerDay` and `translationsPerDay` to the three tiers. |
| `models/User.js` (modify) | Add the `conversationQuota` sub-document. |
| `routes/messages.js` (modify) | Insert the new middleware into the POST chain. |
| `controllers/iosPurchase.js`, `controllers/androidPurchase.js` (modify) | Write a `PurchaseAttempt` on both success and failure. |
| `controllers/profileVisits.js` (modify) | Free tier sees count + most recent visitor only. |

---

### Task 1: Local-day key

**Files:**
- Create: `lib/localDay.js`
- Test: `test/localDay.test.js`

**Interfaces:**
- Produces: `localDayKey(date: Date, timezone: string|null) => string` returning `'YYYY-MM-DD'`.

- [ ] **Step 1: Write the failing test**

```js
// test/localDay.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { localDayKey } = require('../lib/localDay');

// 2026-09-16T22:30:00Z is already the 17th in Seoul (+9) and still the 16th in UTC.
const LATE = new Date('2026-09-16T22:30:00Z');

test('formats the local day as YYYY-MM-DD', () => {
  assert.equal(localDayKey(LATE, 'UTC'), '2026-09-16');
});

test('a user east of UTC has already rolled over', () => {
  assert.equal(localDayKey(LATE, 'Asia/Seoul'), '2026-09-17');
});

test('a user west of UTC has not', () => {
  assert.equal(localDayKey(new Date('2026-09-16T02:00:00Z'), 'America/New_York'), '2026-09-15');
});

test('a null timezone falls back to UTC rather than throwing', () => {
  // User.timezone defaults to null until the app reports one on launch.
  assert.equal(localDayKey(LATE, null), '2026-09-16');
});

test('a garbage timezone falls back to UTC rather than throwing', () => {
  assert.equal(localDayKey(LATE, 'Mars/Olympus_Mons'), '2026-09-16');
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/localDay.test.js`
Expected: FAIL — `Cannot find module '../lib/localDay'`

- [ ] **Step 3: Implement**

```js
// lib/localDay.js
'use strict';

/**
 * The learner's own calendar day, as 'YYYY-MM-DD'.
 *
 * Deliberately NOT lib/dailyCompletion.js's toDateKey, which is UTC because
 * the daily pack's content is global. A personal quota is different: resetting
 * someone's allowance at 09:00 local time would feel arbitrary and punitive.
 *
 * Falls back to UTC on a null or invalid timezone. User.timezone is null until
 * the app reports one on launch, so this path is common, not exceptional.
 */
const localDayKey = (date, timezone) => {
  const format = (tz) => new Intl.DateTimeFormat('en-CA', {
    timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(date);

  try {
    return format(timezone || 'UTC');
  } catch (e) {
    return format('UTC');
  }
};

module.exports = { localDayKey };
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/localDay.test.js`
Expected: PASS, 5/5

- [ ] **Step 5: Commit**

```bash
git add lib/localDay.js test/localDay.test.js
git commit -m "feat(quota): local-day key for personal allowances"
```

---

### Task 2: Conversation quota arithmetic

**Files:**
- Create: `lib/conversationQuota.js`
- Test: `test/conversationQuota.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `evaluateQuota({ quota, todayKey, limit }) => { started, adCredits, allowance, remaining, allowed, isNewDay }`.
  `quota` is the stored blob `{ dayKey, started, adCredits }` or null/undefined.
  `limit` of `-1` means unlimited.

- [ ] **Step 1: Write the failing test**

```js
// test/conversationQuota.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { evaluateQuota } = require('../lib/conversationQuota');

const TODAY = '2026-09-16';

test('a user with no quota record yet may start', () => {
  const s = evaluateQuota({ quota: null, todayKey: TODAY, limit: 3 });
  assert.equal(s.started, 0);
  assert.equal(s.allowed, true);
  assert.equal(s.remaining, 3);
});

test('yesterday\'s counters do not carry over', () => {
  const s = evaluateQuota({
    quota: { dayKey: '2026-09-15', started: 3, adCredits: 2 }, todayKey: TODAY, limit: 3,
  });
  assert.equal(s.isNewDay, true);
  assert.equal(s.started, 0);
  assert.equal(s.adCredits, 0, 'ad credits expire with the day and never accumulate');
  assert.equal(s.allowed, true);
});

test('the fourth start of the day is refused', () => {
  const s = evaluateQuota({
    quota: { dayKey: TODAY, started: 3, adCredits: 0 }, todayKey: TODAY, limit: 3,
  });
  assert.equal(s.allowed, false);
  assert.equal(s.remaining, 0);
});

test('an ad credit buys exactly one more start', () => {
  const s = evaluateQuota({
    quota: { dayKey: TODAY, started: 3, adCredits: 1 }, todayKey: TODAY, limit: 3,
  });
  assert.equal(s.allowance, 4);
  assert.equal(s.allowed, true);
  assert.equal(s.remaining, 1);
});

test('VIP is unlimited', () => {
  const s = evaluateQuota({
    quota: { dayKey: TODAY, started: 99, adCredits: 0 }, todayKey: TODAY, limit: -1,
  });
  assert.equal(s.allowed, true);
  assert.equal(s.remaining, Infinity);
});

test('remaining never goes negative', () => {
  const s = evaluateQuota({
    quota: { dayKey: TODAY, started: 10, adCredits: 0 }, todayKey: TODAY, limit: 3,
  });
  assert.equal(s.remaining, 0);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/conversationQuota.test.js`
Expected: FAIL — `Cannot find module '../lib/conversationQuota'`

- [ ] **Step 3: Implement**

```js
// lib/conversationQuota.js
'use strict';

/**
 * How many new conversations this user may still start today.
 *
 * Pure so the interesting behaviour is testable without a clock or a database.
 * A stored quota from a previous day is treated as absent: both the count AND
 * the ad credits reset, so watching five ads at midnight does not bank five
 * starts for the week.
 *
 * limit -1 means unlimited (VIP).
 */
const evaluateQuota = ({ quota, todayKey, limit }) => {
  const isNewDay = !quota || quota.dayKey !== todayKey;
  const started = isNewDay ? 0 : (quota.started || 0);
  const adCredits = isNewDay ? 0 : (quota.adCredits || 0);

  if (limit === -1) {
    return { started, adCredits, allowance: Infinity, remaining: Infinity, allowed: true, isNewDay };
  }

  const allowance = limit + adCredits;
  const remaining = Math.max(0, allowance - started);
  return { started, adCredits, allowance, remaining, allowed: remaining > 0, isNewDay };
};

module.exports = { evaluateQuota };
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/conversationQuota.test.js`
Expected: PASS, 6/6

- [ ] **Step 5: Commit**

```bash
git add lib/conversationQuota.js test/conversationQuota.test.js
git commit -m "feat(quota): new-conversation allowance arithmetic"
```

---

### Task 3: Config and User field

**Files:**
- Modify: `config/limitations.js`
- Modify: `models/User.js`
- Test: `test/monetizationLimits.test.js`

**Interfaces:**
- Produces: `LIMITS.visitor.newConversationsPerDay === 3`, `LIMITS.regular.newConversationsPerDay === 3`,
  `LIMITS.vip.newConversationsPerDay === -1`; same shape for `translationsPerDay` (10/10/-1).
  `User.conversationQuota = { dayKey: String|null, started: Number, adCredits: Number }`.

- [ ] **Step 1: Write the failing test**

```js
// test/monetizationLimits.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const LIMITS = require('../config/limitations');

test('free means BOTH visitor and regular, with identical caps', () => {
  assert.equal(LIMITS.visitor.newConversationsPerDay, 3);
  assert.equal(LIMITS.regular.newConversationsPerDay, 3);
  assert.equal(LIMITS.visitor.translationsPerDay, 10);
  assert.equal(LIMITS.regular.translationsPerDay, 10);
});

test('VIP is unlimited on both new caps', () => {
  assert.equal(LIMITS.vip.newConversationsPerDay, -1);
  assert.equal(LIMITS.vip.translationsPerDay, -1);
});

test('messaging itself is still uncapped for everyone', () => {
  // The spec caps STARTS, never replies. If this ever fails, the design has
  // been inverted into the thing it explicitly rejected.
  for (const tier of ['visitor', 'regular', 'vip']) {
    assert.equal(LIMITS[tier].messagesPerDay, -1, `${tier} messagesPerDay must stay unlimited`);
  }
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/monetizationLimits.test.js`
Expected: FAIL — `expected undefined to equal 3`

- [ ] **Step 3: Implement**

In `config/limitations.js`, inside the `visitor` block, after `wavesPerDay`:

```js
    // Monetization (2026-09-16): conversation STARTS are capped, replies are
    // not. See docs/superpowers/specs/2026-09-15-monetization-design.md §3.2.
    newConversationsPerDay: 3,
    translationsPerDay: 10,
```

Add the identical two lines to the `regular` block, and to the `vip` block add:

```js
    newConversationsPerDay: -1,
    translationsPerDay: -1,
```

In `models/User.js`, beside `regularUserLimitations`:

```js
  // Daily allowance for STARTING new conversations. Resets on the user's own
  // local day (lib/localDay.js), not UTC. adCredits are granted by watching a
  // rewarded ad and expire with the day.
  conversationQuota: {
    dayKey: { type: String, default: null },
    started: { type: Number, default: 0 },
    adCredits: { type: Number, default: 0 },
  },
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/monetizationLimits.test.js`
Expected: PASS, 3/3

- [ ] **Step 5: Commit**

```bash
git add config/limitations.js models/User.js test/monetizationLimits.test.js
git commit -m "feat(quota): new-conversation and translation caps in config"
```

---

### Task 4: The conversation-start middleware

**Files:**
- Create: `middleware/checkConversationStart.js`
- Modify: `routes/messages.js:32-40`
- Test: `test/checkConversationStart.test.js`

**Interfaces:**
- Consumes: `localDayKey` (Task 1), `evaluateQuota` (Task 2), `LIMITS` (Task 3).
- Produces: `checkConversationStart` Express middleware. On success it sets
  `req.startsNewConversation` (boolean) so the controller can increment after the
  message is actually created.

- [ ] **Step 1: Write the failing test**

```js
// test/checkConversationStart.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, User, Conversation, checkConversationStart;

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'conv_start' });
  User = require('../models/User');
  Conversation = require('../models/Conversation');
  ({ checkConversationStart } = require('../middleware/checkConversationStart'));
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([User.deleteMany({}), Conversation.deleteMany({})]);
});

const makeUser = (over = {}) => User.create({
  name: 'Quota User',
  email: `q-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1',
  gender: 'other', native_language: 'English', language_to_learn: 'Korean',
  userMode: 'regular', profileCompleted: true, timezone: 'UTC',
  ...over,
});

/** Run the middleware and report how it finished. */
const run = async (sender, receiverId) => {
  const req = { user: { id: String(sender._id) }, body: { receiver: String(receiverId) } };
  let error = null; let passed = false;
  await checkConversationStart(req, {}, (e) => { if (e) error = e; else passed = true; });
  return { req, error, passed };
};

test('the first three starts of the day pass', async () => {
  const a = await makeUser();
  for (let i = 0; i < 3; i += 1) {
    const b = await makeUser();
    const { passed, req } = await run(a, b._id);
    assert.equal(passed, true, `start ${i + 1} should pass`);
    assert.equal(req.startsNewConversation, true);
    // The controller increments; simulate it here.
    await User.updateOne({ _id: a._id }, {
      $set: { 'conversationQuota.dayKey': req.conversationDayKey },
      $inc: { 'conversationQuota.started': 1 },
    });
  }
});

test('the fourth start is refused with a 403', async () => {
  const a = await makeUser({
    conversationQuota: { dayKey: require('../lib/localDay').localDayKey(new Date(), 'UTC'), started: 3, adCredits: 0 },
  });
  const b = await makeUser();
  const { error, passed } = await run(a, b._id);
  assert.equal(passed, false);
  assert.ok(error, 'expected an ErrorResponse');
  assert.equal(error.statusCode, 403);
});

test('a REPLY in an existing conversation is never capped', async () => {
  const a = await makeUser({
    conversationQuota: { dayKey: require('../lib/localDay').localDayKey(new Date(), 'UTC'), started: 99, adCredits: 0 },
  });
  const b = await makeUser();
  await Conversation.create({ participants: [a._id, b._id], isGroup: false });

  const { passed, req } = await run(a, b._id);
  assert.equal(passed, true, 'replies must never be refused');
  assert.equal(req.startsNewConversation, false, 'and must not consume quota');
});

test('the recipient\'s quota is untouched by being messaged', async () => {
  const a = await makeUser();
  const b = await makeUser({
    conversationQuota: { dayKey: require('../lib/localDay').localDayKey(new Date(), 'UTC'), started: 3, adCredits: 0 },
  });
  // b is at their limit, but a is the initiator, so this must pass.
  const { passed } = await run(a, b._id);
  assert.equal(passed, true);
});

test('VIP is never capped', async () => {
  const a = await makeUser({
    userMode: 'vip',
    vipSubscription: { isActive: true, endDate: new Date(Date.now() + 86400000) },
    conversationQuota: { dayKey: require('../lib/localDay').localDayKey(new Date(), 'UTC'), started: 50, adCredits: 0 },
  });
  const b = await makeUser();
  const { passed } = await run(a, b._id);
  assert.equal(passed, true);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/checkConversationStart.test.js`
Expected: FAIL — `Cannot find module '../middleware/checkConversationStart'`

- [ ] **Step 3: Implement**

```js
// middleware/checkConversationStart.js
'use strict';

const asyncHandler = require('./async');
const User = require('../models/User');
const Conversation = require('../models/Conversation');
const ErrorResponse = require('../utils/errorResponse');
const LIMITS = require('../config/limitations');
const { localDayKey } = require('../lib/localDay');
const { evaluateQuota } = require('../lib/conversationQuota');

/** Mirrors getUserTier in checkLimitations.js: an expired VIP is a regular. */
const tierOf = (user) => {
  if (!user) return 'visitor';
  if (user.userMode === 'vip') {
    const v = user.vipSubscription;
    if (v && v.isActive && new Date(v.endDate) > new Date()) return 'vip';
    return 'regular';
  }
  return user.userMode || 'regular';
};

/**
 * Cap how many NEW conversations a user may start per day.
 *
 * Replies are never capped: a user who has found someone to talk to must never
 * hit a wall. Only the INITIATOR's quota is consumed, so a popular user is not
 * rate-limited by other people's interest in them.
 *
 * Sets req.startsNewConversation so the controller can increment the counter
 * AFTER the message is actually created — incrementing here would charge the
 * user for a message that then failed to send.
 */
const checkConversationStart = asyncHandler(async (req, res, next) => {
  if (!req.user || !req.user.id) {
    return next(new ErrorResponse('Authentication required', 401));
  }
  const receiver = req.body && req.body.receiver;
  if (!receiver) return next();

  const existing = await Conversation.findOne({
    participants: { $all: [req.user.id, receiver], $size: 2 },
    isGroup: false,
  }).select('_id').lean();

  if (existing) {
    req.startsNewConversation = false;
    return next();
  }

  const user = await User.findById(req.user.id)
    .select('userMode vipSubscription timezone conversationQuota');
  if (!user) return next(new ErrorResponse('User not found', 404));

  const todayKey = localDayKey(new Date(), user.timezone);
  const limit = LIMITS[tierOf(user)].newConversationsPerDay;
  const state = evaluateQuota({ quota: user.conversationQuota, todayKey, limit });

  if (!state.allowed) {
    return next(new ErrorResponse(
      'You have started the most conversations you can today. Watch an ad for one more, or go VIP for unlimited.',
      403,
      'CONVERSATION_START_LIMIT'
    ));
  }

  req.startsNewConversation = true;
  req.conversationDayKey = todayKey;
  next();
});

module.exports = { checkConversationStart, tierOf };
```

Then wire it into `routes/messages.js`, immediately after `checkMessageLimit`:

```js
const { checkConversationStart } = require('../middleware/checkConversationStart');

router.route('/').get(protect, getMessages).post(
  protect,
  messageLimiter,
  uploadSingleCompressed('attachment', 'bananatalk/messages'),
  createMessageValidation,
  validate,
  checkMessageLimit,
  checkConversationStart,
  createMessage
);
```

And in `controllers/messages.js`, immediately after `await conversation.save();` in `createMessage`:

```js
  // Charge the quota only once the message and conversation actually exist.
  if (req.startsNewConversation) {
    await User.updateOne(
      { _id: sender },
      {
        $set: { 'conversationQuota.dayKey': req.conversationDayKey },
        $inc: { 'conversationQuota.started': 1 },
      }
    );
  }
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/checkConversationStart.test.js`
Expected: PASS, 5/5

Then the whole suite: `npm test`
Expected: no NEW failures. `authSecretRotation.test.js` "both secrets meet the 32-char minimum" fails by design (local `JWT_SECRET` is deliberately short).

- [ ] **Step 5: Commit**

```bash
git add middleware/checkConversationStart.js routes/messages.js controllers/messages.js test/checkConversationStart.test.js
git commit -m "feat(quota): cap new conversations, never replies"
```

---

### Task 5: Ad credit endpoint

**Files:**
- Modify: `controllers/coins.js` (add `grantConversationCredit`)
- Modify: `routes/coins.js`
- Test: `test/adConversationCredit.test.js`

**Interfaces:**
- Consumes: `localDayKey` (Task 1).
- Produces: `POST /api/v1/coins/ad-credit/conversation` → `{ success, adCredits, remaining }`.

- [ ] **Step 1: Write the failing test**

```js
// test/adConversationCredit.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const { localDayKey } = require('../lib/localDay');

let mongod, User, grantConversationCredit;

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'ad_credit' });
  User = require('../models/User');
  ({ grantConversationCredit } = require('../controllers/coins'));
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => { await User.deleteMany({}); });

const makeUser = (over = {}) => User.create({
  name: 'Ad User', email: `ad-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '2000', birth_month: '1', birth_day: '1',
  gender: 'other', native_language: 'English', language_to_learn: 'Korean',
  userMode: 'regular', profileCompleted: true, timezone: 'UTC', ...over,
});

const call = async (user) => {
  let body = null;
  const res = { status: () => res, json: (b) => { body = b; return res; } };
  await grantConversationCredit({ user: { id: String(user._id) } }, res, (e) => { throw e; });
  return body;
};

test('watching an ad grants exactly one credit', async () => {
  const u = await makeUser();
  const body = await call(u);
  assert.equal(body.success, true);
  assert.equal(body.adCredits, 1);
  const fresh = await User.findById(u._id).select('conversationQuota');
  assert.equal(fresh.conversationQuota.adCredits, 1);
});

test('credits from a previous day are discarded, not added to', async () => {
  const u = await makeUser({
    conversationQuota: { dayKey: '2020-01-01', started: 3, adCredits: 5 },
  });
  const body = await call(u);
  assert.equal(body.adCredits, 1, 'yesterday\'s 5 credits must not survive');
  const fresh = await User.findById(u._id).select('conversationQuota');
  assert.equal(fresh.conversationQuota.started, 0, 'the day rolled over, so the count resets too');
  assert.equal(fresh.conversationQuota.dayKey, localDayKey(new Date(), 'UTC'));
});

test('credits stack within the same day', async () => {
  const u = await makeUser({
    conversationQuota: { dayKey: localDayKey(new Date(), 'UTC'), started: 3, adCredits: 1 },
  });
  const body = await call(u);
  assert.equal(body.adCredits, 2);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/adConversationCredit.test.js`
Expected: FAIL — `grantConversationCredit is not a function`

- [ ] **Step 3: Implement**

Append to `controllers/coins.js`:

```js
const { localDayKey } = require('../lib/localDay');

/**
 * @desc    Grant one extra new-conversation start in exchange for a watched ad
 * @route   POST /api/v1/coins/ad-credit/conversation
 * @access  Private
 *
 * Credits expire with the user's local day and never accumulate across days —
 * watching five ads at midnight must not bank five starts for the week.
 */
exports.grantConversationCredit = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.user.id).select('timezone conversationQuota');
  if (!user) return next(new ErrorResponse('User not found', 404));

  const todayKey = localDayKey(new Date(), user.timezone);
  const q = user.conversationQuota || {};
  const isNewDay = q.dayKey !== todayKey;

  user.conversationQuota = {
    dayKey: todayKey,
    started: isNewDay ? 0 : (q.started || 0),
    adCredits: (isNewDay ? 0 : (q.adCredits || 0)) + 1,
  };
  await user.save();

  res.status(200).json({
    success: true,
    adCredits: user.conversationQuota.adCredits,
    remaining: user.conversationQuota.adCredits,
  });
});
```

In `routes/coins.js`, beside the existing routes:

```js
router.post('/ad-credit/conversation', protect, grantConversationCredit);
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/adConversationCredit.test.js`
Expected: PASS, 3/3

- [ ] **Step 5: Commit**

```bash
git add controllers/coins.js routes/coins.js test/adConversationCredit.test.js
git commit -m "feat(ads): a watched ad buys one new conversation"
```

---

### Task 6: Purchase attempt log

**Files:**
- Create: `models/PurchaseAttempt.js`
- Modify: `controllers/iosPurchase.js`, `controllers/androidPurchase.js`
- Test: `test/purchaseAttemptLog.test.js`

**Interfaces:**
- Produces: `recordPurchaseAttempt({ userId, platform, productId, outcome, reason, req })`
  exported from `models/PurchaseAttempt.js`. `outcome` is one of `'success' | 'rejected' | 'error'`.

- [ ] **Step 1: Write the failing test**

```js
// test/purchaseAttemptLog.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, PurchaseAttempt, recordPurchaseAttempt;

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'purchase_log' });
  ({ PurchaseAttempt, recordPurchaseAttempt } = require('../models/PurchaseAttempt'));
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => { await PurchaseAttempt.deleteMany({}); });

const REQ = { headers: { 'user-agent': 'BananaTalk/2.3.0' }, ip: '203.0.113.9', body: {} };

test('a rejected purchase is recorded with its reason', async () => {
  await recordPurchaseAttempt({
    userId: new mongoose.Types.ObjectId(), platform: 'android',
    productId: 'com.bananatalk.app.vip.monthly', outcome: 'rejected',
    reason: 'receipt invalid', req: REQ,
  });
  const row = await PurchaseAttempt.findOne({});
  assert.equal(row.outcome, 'rejected');
  assert.equal(row.reason, 'receipt invalid');
  assert.equal(row.productId, 'com.bananatalk.app.vip.monthly');
});

test('a success is recorded too, so the ratio is meaningful', async () => {
  await recordPurchaseAttempt({
    userId: new mongoose.Types.ObjectId(), platform: 'ios',
    productId: 'com.bananatalk.bananatalkApp.vip.year', outcome: 'success', req: REQ,
  });
  assert.equal(await PurchaseAttempt.countDocuments({ outcome: 'success' }), 1);
});

test('client context is attached so a failure can be pinned to a build', async () => {
  await recordPurchaseAttempt({
    userId: new mongoose.Types.ObjectId(), platform: 'ios', productId: 'x',
    outcome: 'error', reason: 'boom',
    req: { ...REQ, body: { clientInfo: { platform: 'ios', appVersion: '2.3.0', appBuild: '10570' } } },
  });
  const row = await PurchaseAttempt.findOne({});
  assert.equal(row.appVersion, '2.3.0');
});

test('logging never throws, even on a malformed request', async () => {
  // Telemetry must never break the purchase it describes.
  await recordPurchaseAttempt({ userId: null, platform: 'ios', outcome: 'error', req: undefined });
  assert.ok(true, 'did not throw');
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/purchaseAttemptLog.test.js`
Expected: FAIL — `Cannot find module '../models/PurchaseAttempt'`

- [ ] **Step 3: Implement**

```js
// models/PurchaseAttempt.js
'use strict';

const mongoose = require('mongoose');

/**
 * Every purchase verification attempt, successful or not.
 *
 * Revenue was $0 for months and nobody could say why, because a FAILED purchase
 * left no trace anywhere. This is the record that turns "is it broken?" from a
 * guess into a query. Append-only: never updated, never deleted.
 */
const PurchaseAttemptSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  platform: { type: String, enum: ['ios', 'android', 'unknown'], required: true },
  productId: { type: String, default: '' },
  outcome: { type: String, enum: ['success', 'rejected', 'error'], required: true, index: true },
  reason: { type: String, default: '' },
  appVersion: { type: String, default: '' },
  appBuild: { type: String, default: '' },
  ip: { type: String, default: null },
  userAgent: { type: String, default: null },
}, { timestamps: true });

const PurchaseAttempt = mongoose.model('PurchaseAttempt', PurchaseAttemptSchema);

/**
 * Best-effort by design: a telemetry failure must never fail the purchase it
 * is describing. Mirrors securityEventContext in utils/securityLogger.js.
 */
const recordPurchaseAttempt = async ({ userId, platform, productId, outcome, reason, req }) => {
  try {
    const { securityEventContext } = require('../utils/securityLogger');
    const ctx = securityEventContext(req || {});
    await PurchaseAttempt.create({
      userId: userId || undefined,
      platform: platform || 'unknown',
      productId: productId || '',
      outcome,
      reason: reason || '',
      appVersion: ctx.appVersion,
      appBuild: ctx.appBuild,
      ip: ctx.ip,
      userAgent: ctx.userAgent,
    });
  } catch (e) {
    console.error('[PurchaseAttempt] write failed:', e.message);
  }
};

module.exports = { PurchaseAttempt, recordPurchaseAttempt };
```

In `controllers/iosPurchase.js`, inside `verifyIOSPurchase`, after the verification result is known, add on the failure branch:

```js
    await recordPurchaseAttempt({
      userId: req.user.id, platform: 'ios', productId,
      outcome: 'rejected', reason: result.error || 'verification failed', req,
    });
```

and on the success branch, after VIP is activated:

```js
    await recordPurchaseAttempt({
      userId: req.user.id, platform: 'ios', productId: finalProductId,
      outcome: 'success', req,
    });
```

Add the matching two calls in `controllers/androidPurchase.js`'s `verifyAndroidPurchase`, with `platform: 'android'`. Import in both:

```js
const { recordPurchaseAttempt } = require('../models/PurchaseAttempt');
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/purchaseAttemptLog.test.js`
Expected: PASS, 4/4

- [ ] **Step 5: Commit**

```bash
git add models/PurchaseAttempt.js controllers/iosPurchase.js controllers/androidPurchase.js test/purchaseAttemptLog.test.js
git commit -m "feat(revenue): log every purchase attempt, success or failure"
```

---

### Task 7: Paywall event log

**Files:**
- Create: `models/PaywallEvent.js`
- Create: `controllers/paywallEvents.js`
- Modify: `routes/purchases.js`
- Test: `test/paywallEventLog.test.js`

**Interfaces:**
- Produces: `POST /api/v1/purchases/paywall-event` accepting `{ placement, action }`.
  `placement` ∈ `visitor_list | conversation_cap | translation_cap | ad_removal | discovery_priority`.
  `action` ∈ `shown | dismissed | converted`.

- [ ] **Step 1: Write the failing test**

```js
// test/paywallEventLog.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, PaywallEvent, recordPaywallEvent;

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'paywall_log' });
  ({ PaywallEvent } = require('../models/PaywallEvent'));
  ({ recordPaywallEvent } = require('../controllers/paywallEvents'));
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => { await PaywallEvent.deleteMany({}); });

const call = async (body) => {
  let status = 0; let payload = null;
  const res = { status: (s) => { status = s; return res; }, json: (b) => { payload = b; return res; } };
  let err = null;
  await recordPaywallEvent(
    { user: { id: String(new mongoose.Types.ObjectId()) }, body, headers: {}, ip: '1.1.1.1' },
    res, (e) => { err = e; }
  );
  return { status, payload, err };
};

test('a shown paywall is recorded', async () => {
  const { status } = await call({ placement: 'visitor_list', action: 'shown' });
  assert.equal(status, 201);
  assert.equal(await PaywallEvent.countDocuments({ placement: 'visitor_list' }), 1);
});

test('an unknown placement is refused rather than silently stored', async () => {
  // A typo'd placement would quietly corrupt the conversion numbers this whole
  // design is meant to produce.
  const { err } = await call({ placement: 'not_a_placement', action: 'shown' });
  assert.ok(err);
  assert.equal(err.statusCode, 400);
});

test('an unknown action is refused', async () => {
  const { err } = await call({ placement: 'visitor_list', action: 'wiggled' });
  assert.ok(err);
  assert.equal(err.statusCode, 400);
});

test('all five placements from the spec are accepted', async () => {
  for (const p of ['visitor_list', 'conversation_cap', 'translation_cap', 'ad_removal', 'discovery_priority']) {
    const { status } = await call({ placement: p, action: 'shown' });
    assert.equal(status, 201, `${p} should be a valid placement`);
  }
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/paywallEventLog.test.js`
Expected: FAIL — `Cannot find module '../models/PaywallEvent'`

- [ ] **Step 3: Implement**

```js
// models/PaywallEvent.js
'use strict';

const mongoose = require('mongoose');

/** The five placements in the monetization spec §4. */
const PLACEMENTS = [
  'visitor_list', 'conversation_cap', 'translation_cap', 'ad_removal', 'discovery_priority',
];
const ACTIONS = ['shown', 'dismissed', 'converted'];

/**
 * Append-only record of paywall exposure.
 *
 * Without this, "nobody ever sees a paywall" stays a hypothesis. With it, the
 * view -> conversion rate per placement is one aggregation.
 */
const PaywallEventSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  placement: { type: String, enum: PLACEMENTS, required: true, index: true },
  action: { type: String, enum: ACTIONS, required: true },
}, { timestamps: true });

module.exports = {
  PaywallEvent: mongoose.model('PaywallEvent', PaywallEventSchema),
  PLACEMENTS,
  ACTIONS,
};
```

```js
// controllers/paywallEvents.js
'use strict';

const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const { PaywallEvent, PLACEMENTS, ACTIONS } = require('../models/PaywallEvent');

/**
 * @desc    Record that a paywall was shown, dismissed or converted
 * @route   POST /api/v1/purchases/paywall-event
 * @access  Private
 *
 * Validates the enums rather than trusting the client: a typo'd placement would
 * quietly corrupt the conversion numbers this endpoint exists to produce.
 */
exports.recordPaywallEvent = asyncHandler(async (req, res, next) => {
  const { placement, action } = req.body || {};

  if (!PLACEMENTS.includes(placement)) {
    return next(new ErrorResponse(`placement must be one of: ${PLACEMENTS.join(', ')}`, 400));
  }
  if (!ACTIONS.includes(action)) {
    return next(new ErrorResponse(`action must be one of: ${ACTIONS.join(', ')}`, 400));
  }

  await PaywallEvent.create({ userId: req.user.id, placement, action });
  res.status(201).json({ success: true });
});
```

In `routes/purchases.js`:

```js
const { recordPaywallEvent } = require('../controllers/paywallEvents');
router.post('/paywall-event', protect, recordPaywallEvent);
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/paywallEventLog.test.js`
Expected: PASS, 4/4

- [ ] **Step 5: Commit**

```bash
git add models/PaywallEvent.js controllers/paywallEvents.js routes/purchases.js test/paywallEventLog.test.js
git commit -m "feat(revenue): log paywall exposure and conversion"
```

---

### Task 8: Visitor list gating

**Files:**
- Modify: `controllers/profileVisits.js`
- Test: `test/visitorListGating.test.js`

**Interfaces:**
- Consumes: `tierOf` from `middleware/checkConversationStart.js` (Task 4).
- Produces: the visitors list response gains `{ total, locked, visitors }`. For free users
  `visitors` holds at most one entry and `locked` is the number hidden.

- [ ] **Step 1: Write the failing test**

```js
// test/visitorListGating.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { gateVisitors } = require('../controllers/profileVisits');

const rows = (n) => Array.from({ length: n }, (_, i) => ({ visitor: `v${i}`, visitedAt: new Date() }));

test('a free user sees the count and exactly one visitor', () => {
  const out = gateVisitors(rows(7), 'regular');
  assert.equal(out.total, 7);
  assert.equal(out.visitors.length, 1);
  assert.equal(out.locked, 6);
});

test('a visitor-tier user is gated the same as regular', () => {
  const out = gateVisitors(rows(4), 'visitor');
  assert.equal(out.visitors.length, 1);
  assert.equal(out.locked, 3);
});

test('VIP sees everyone', () => {
  const out = gateVisitors(rows(7), 'vip');
  assert.equal(out.visitors.length, 7);
  assert.equal(out.locked, 0);
});

test('no visitors means nothing is locked', () => {
  const out = gateVisitors([], 'regular');
  assert.equal(out.total, 0);
  assert.equal(out.locked, 0);
  assert.deepEqual(out.visitors, []);
});

test('a single visitor is fully shown to a free user', () => {
  // The teaser must not claim something is hidden when nothing is.
  const out = gateVisitors(rows(1), 'regular');
  assert.equal(out.visitors.length, 1);
  assert.equal(out.locked, 0);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node --test test/visitorListGating.test.js`
Expected: FAIL — `gateVisitors is not a function`

- [ ] **Step 3: Implement**

Add to `controllers/profileVisits.js`:

```js
/**
 * What a user may see of their visitor list.
 *
 * Free users get the count and the most recent visitor; the rest are locked.
 * This is the primary paywall in the monetization spec: 1,964 profile visits a
 * month across 382 distinct visitors is the one place where users already want
 * something specific they cannot have.
 *
 * Exported for direct testing — the gating decision must not require HTTP.
 */
exports.gateVisitors = (visits, tier) => {
  const all = Array.isArray(visits) ? visits : [];
  if (tier === 'vip') {
    return { total: all.length, locked: 0, visitors: all };
  }
  const shown = all.slice(0, 1);
  return { total: all.length, locked: Math.max(0, all.length - shown.length), visitors: shown };
};
```

Then in the existing list handler, after loading visits:

```js
const { tierOf } = require('../middleware/checkConversationStart');
// ...
const user = await User.findById(req.user.id).select('userMode vipSubscription');
res.status(200).json({ success: true, data: exports.gateVisitors(visits, tierOf(user)) });
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node --test test/visitorListGating.test.js`
Expected: PASS, 5/5

- [ ] **Step 5: Commit**

```bash
git add controllers/profileVisits.js test/visitorListGating.test.js
git commit -m "feat(vip): the visitor list is the primary paywall"
```

---

### Task 9: Pin the free tier

**Files:**
- Test: `test/freeTierUnchanged.test.js`

**Interfaces:** consumes `config/limitations.js` only.

- [ ] **Step 1: Write the test (it should pass immediately — that is the point)**

```js
// test/freeTierUnchanged.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const LIMITS = require('../config/limitations');

/**
 * The monetization spec promises "nothing is taken away". An early version of
 * the design proposed lowering free limits, and measurement killed it: waves
 * are 376 events from ONE user, moments peak at 2/day, and a profile-view cap
 * would bind on 32 people. At ~800 active users no quantity cap on these earns
 * anything, and lowering them would annoy real users for nothing.
 *
 * These values are pinned so that promise cannot quietly become false.
 */
test('free allowances are exactly what they were before monetization', () => {
  assert.equal(LIMITS.regular.momentsPerDay, 10);
  assert.equal(LIMITS.regular.profileViewsPerDay, 100);
  assert.equal(LIMITS.regular.wavesPerDay, 15);
  assert.equal(LIMITS.regular.storiesPerDay, 10);
  assert.equal(LIMITS.regular.commentsPerDay, 50);

  assert.equal(LIMITS.visitor.momentsPerDay, 5);
  assert.equal(LIMITS.visitor.wavesPerDay, 3);
  assert.equal(LIMITS.visitor.profileViewsPerDay, 20);
});
```

- [ ] **Step 2: Run it**

Run: `node --test test/freeTierUnchanged.test.js`
Expected: PASS. **If any assertion fails, do not change the test** — read `config/limitations.js`, confirm the real current value, and correct the expectation to match what shipped before this plan. The test's job is to freeze today's values, whatever they are.

- [ ] **Step 3: Run the full suite**

Run: `npm test`
Expected: no NEW failures beyond the known `JWT_SECRET` length test.

- [ ] **Step 4: Commit**

```bash
git add test/freeTierUnchanged.test.js
git commit -m "test(quota): pin the free tier so 'nothing is taken away' stays true"
```

---

## Not in this plan

- **App-side work** (paywall screens, ad flow, visitor-list blur, translation cap UI) — a
  separate plan, same pattern as the daily pack's backend/app split.
- **Store verification** (§5 of the spec): Play Console SKUs and one sandbox purchase per
  platform. Owner-executed, not code.
- **Price reconciliation** (spec §9.1) — app fallbacks 14.99/19.99/49.99 vs `/plans`
  9.99/23.99/71.99. Needs the App Store Connect values first.
- **Ad fill rate** (spec §9.2) — if ads rarely serve, the "watch an ad" exit is not real and
  the cap becomes VIP-or-nothing. Measure before the cap is switched on.
- **Discovery priority weight** — `priorityInSearch` already exists as a VIP flag;
  `controllers/matching.js` must first be fixed for the exact-string language bug (it loses
  55% of true pairs) or a priority weight will be tuning a broken ranking.

## Self-review

**Spec coverage.** §3.1 free tier → Task 3 + 9. §3.2 conversation cap → Tasks 1, 2, 4.
§3.2.1 cap mechanics (initiator-only, local day, start vs reply, credits do not accumulate)
→ Tasks 1, 2, 4, 5. §3.2.2 tiers → Task 3. §3.3 VIP visitor list → Task 8. §3.4 rewarded
ads → Task 5. §4 exposure → Task 7 (the log); the placements themselves are app-side.
§5 plumbing → owner-executed, listed above. §6 instrumentation → Tasks 6, 7. §7 testing →
each task, plus Task 9.

**Gap found and accepted:** the spec's translation cap (10/day) has config in Task 3 but no
enforcement middleware here, because translation is being moved into chat by the Study Hub
IA spec and the enforcement point moves with it. Enforcing it twice would be wrong. It
belongs in the app plan alongside that move — recorded here so it is not forgotten.

**Type consistency.** `localDayKey(date, timezone)`, `evaluateQuota({quota, todayKey, limit})`,
`tierOf(user)`, `gateVisitors(visits, tier)`, `recordPurchaseAttempt({...})` are each defined
once and referenced with the same signature everywhere.
