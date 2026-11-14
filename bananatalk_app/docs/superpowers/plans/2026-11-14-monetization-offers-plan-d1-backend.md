# Monetization Offers, Plan D1 (backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The server records the whole paywall funnel, decides when four passive offers show (with caps), can mask the visitor push for free users, and logs the app version on purchase attempts. All of it ships dark.

**Architecture:** `PaywallEvent` grows additively and gets a batch endpoint. A pure rules module (`lib/offerEngine.js`) decides offers; a thin service loads its inputs, reserves the day's slot in a new `offerstates` collection, and is fed by the batch endpoint. A nightly job writes per-surface conversion counts. Three switches, read at require time from `config/limitations.js`, default off.

**Tech Stack:** Node.js, Express, Mongoose, `node:test` with `mongodb-memory-server`.

**Spec:** `docs/superpowers/specs/2026-11-14-monetization-offers-design.md` (app repo, branch `docs/monetization-offers-spec`). This plan covers sections 4.1, 5 and the server half of 7. The app half (4.2, 6, app side of 5) is Plan D2.

**Repo and branch:** backend repo, new worktree `/Users/davis/Desktop/Personal/be-offers`, branch `feat/monetization-offers` from `main`.

## Global Constraints

- Three new switches, all default off: `PAYWALL_EVENTS_ENABLED`, `OFFER_ENGINE_ENABLED`, `VISITOR_PUSH_MASK_ENABLED`. Declare each with the existing `flag()` helper in `config/limitations.js` and export it.
- With all three unset, every existing response is byte-identical to `main`, no new collection is created, and no new write happens. Task 8 proves it.
- `POST /purchases/paywall-event` (singular) keeps its exact behaviour: same accepted values, same 400 text, same stored fields.
- Guarded routes answer `404 { success: false, error: 'Not found' }` while their switch is off, like `rewardedLimitsEnabledGuard` in `controllers/coins.js`.
- New user-facing error strings must not contain `limit`, `blocked`, `not found`, `unauthorized` or `401` (the app relabels them). The guard's existing `'Not found'` body is the one accepted exception: it is the established pattern and the app never shows it.
- Tests: `node --experimental-test-module-mocks --test --test-force-exit test/<file>.test.js`, one file at a time. Set env switches before requiring `config/limitations`.
- Never add a Co-Authored-By or any Claude attribution line to a commit.
- Every commit updates `docs/REMAINING_WORK.md` (tick finished items, add new open ones) and lists what is still open in the commit body.
- Do not change `config/config.env`. Do not push `main`.

## Review Focus

1. A batch with one malformed item, or 51 items, or `events` not an array: valid items are still stored in the first case; the other two answer 400 and store nothing. (Task 1)
2. Two `GET /offers` calls arriving together on a new day: both return the same offer id and exactly one reservation exists. (Task 5)
3. A `shown` event repeated many times for one offer in one day counts as one ignored view, not many. (Task 6)
4. An `offerId` in an event that belongs to another user, or is not today's offer, changes nobody's state. (Task 6)
5. A user who is VIP, banned, 47 hours old, or inside a paid reveal window gets no offer; a user with `createdAt` missing gets no offer. (Tasks 4, 5)

---

## File Structure

| File | Responsibility |
|---|---|
| `config/limitations.js` (modify) | The three flags |
| `models/PaywallEvent.js` (modify) | Wider enums, new fields, indexes; keeps `LEGACY_*` lists |
| `controllers/paywallEvents.js` (modify) | Singular endpoint unchanged; new `recordPaywallEvents` batch |
| `middleware/rateLimiter.js` (modify) | `paywallEventsLimiter` |
| `routes/purchases.js` (modify) | Batch route |
| `controllers/appConfig.js` (modify) | `paywallEventsEnabled`, `offerEngineEnabled` |
| `models/PurchaseAttempt.js` (modify) | App version from header |
| `lib/paywallFunnel.js` (create) | Pure summary of event rows into funnel rows |
| `scripts/paywallFunnel.js` (create) | CLI that loads rows and prints the summary |
| `lib/offerEngine.js` (create) | Pure rules: eligibility, lead, ranking, state transitions |
| `models/OfferState.js` (create) | One row per user, `_id` is the user id |
| `models/OfferRates.js` (create) | Single document of per-surface counts |
| `lib/offerService.js` (create) | Loads inputs, reserves, applies events |
| `controllers/offers.js`, `routes/offers.js` (create) | `GET /api/v1/offers` |
| `jobs/offerRatesJob.js` (create), `jobs/scheduler.js` (modify) | Nightly counts |
| `controllers/profileVisits.js`, `models/User.js` (modify) | `visitorsSeenAt` |
| `services/userCascadeDeleteService.js` (modify) | Remove the `offerstates` row and paywall events |
| `services/notificationService.js`, `notification_templates/*.json` (modify) | Masked visit push |
| `test/support/offersOffScenario.js`, `test/offersOffIdentity.test.js`, `scripts/dev/generateOffersOffFixtures.js` (create) | Switch-off identity |
| `docs/rollout/monetization-offers.md` (create) | Rollout steps |

---

### Task 1: Wider paywall events and the batch endpoint

**Files:**
- Modify: `config/limitations.js`, `models/PaywallEvent.js`, `controllers/paywallEvents.js`, `middleware/rateLimiter.js`, `routes/purchases.js`, `controllers/appConfig.js`
- Test: `test/paywallEventsBatch.test.js` (new); `test/paywallEventLog.test.js` must still pass unchanged

**Interfaces:**
- Produces: `PAYWALL_EVENTS_ENABLED` (limitations export); from `models/PaywallEvent.js`: `{ PaywallEvent, PLACEMENTS, ACTIONS, LEGACY_PLACEMENTS, LEGACY_ACTIONS }`; controller export `recordPaywallEvents`; app-config key `paywallEventsEnabled`.
- Stored event shape (later tasks read it): `{ userId, placement, action, flowId?, detail?, offerId?, platform?, appVersion?, clientAt?, createdAt }`.

Values:

- `LEGACY_PLACEMENTS` = today's five; `LEGACY_ACTIONS` = today's three. The singular controller validates against the `LEGACY_*` lists, so its behaviour and its 400 text do not change.
- `PLACEMENTS` = legacy five plus `wave_cap`, `extra_matches`, `moment_cap`, `comment_cap`, `story_cap`, `dm_cap`, `profile_view_cap`, `tutor_quota`, `study_lock`, `boost`, `nearby_radius`, `country_filter`, `vip_entry`, `coin_entry`, `not_enough_coins`, `matches_empty`, `other`.
- `ACTIONS` = legacy three plus `cta_vip`, `cta_coins`, `cta_ad`, `plans_viewed`, `shop_viewed`, `purchase_started`, `purchase_succeeded`, `purchase_failed`, `unlock_succeeded`.
- New schema fields, all optional: `flowId` String, `detail` String, `offerId` ObjectId, `platform` String, `appVersion` String, `clientAt` Date.
- New indexes: `{ placement: 1, action: 1, createdAt: 1 }`, `{ flowId: 1 }` sparse, `{ userId: 1, createdAt: -1 }`. Keep the two existing single-field indexes.

Batch rules (`POST /purchases/paywall-events`, body `{ events: [...] }`):

- Route order: `paywallEventsEnabledGuard`, `protect`, `paywallEventsLimiter`, `recordPaywallEvents`.
- `events` not an array, empty, or longer than 50: `400` with error `events must be an array of 1 to 50 items`; nothing stored.
- Per item: dropped when `placement` or `action` is not in the wide lists. Otherwise kept, with: `flowId` kept only if it matches `/^[A-Za-z0-9_-]{1,40}$/`; `detail` truncated to 40 chars if a string; `offerId` kept only if a valid ObjectId string; `clientAt` kept only if it parses and is within 48 hours of now.
- `platform` from `pickClientInfo(req).platform`; `appVersion` from `parseHeader(req.headers['x-app-version'])` in `lib/appVersion.js` (omit when null).
- Stored with one `insertMany(..., { ordered: false })`. Response `201 { success: true, stored, dropped }`.
- `paywallEventsLimiter`: 30 requests per 15 minutes, keyed `paywallev:<userId>`, message `Too many requests. Please try again later.`

- [ ] **Step 1: Write the failing tests** in `test/paywallEventsBatch.test.js` (boot like `test/paywallEventLog.test.js`; set `process.env.PAYWALL_EVENTS_ENABLED = 'true'` before requiring anything):

```js
test('stores valid items and counts dropped ones', async () => {
  const r = await call({ events: [
    { placement: 'wave_cap', action: 'shown', flowId: 'f-1', detail: 'send_wave_sheet' },
    { placement: 'nope', action: 'shown' },
    { placement: 'vip_entry', action: 'cta_vip', flowId: 'has space', offerId: 'xyz', clientAt: '1999-01-01T00:00:00Z' },
  ] }, { 'x-app-version': '2.2.7+10590' });
  assert.equal(r.status, 201);
  assert.deepEqual(r.payload, { success: true, stored: 2, dropped: 1 });
  const rows = await PaywallEvent.find({}).sort({ placement: 1 }).lean();
  assert.equal(rows[0].placement, 'vip_entry');
  assert.equal(rows[0].flowId, undefined);
  assert.equal(rows[0].offerId, undefined);
  assert.equal(rows[0].clientAt, undefined);
  assert.equal(rows[1].flowId, 'f-1');
  assert.equal(rows[1].appVersion, '2.2.7');
});
test('51 items, an empty list, or a non-array answer 400 and store nothing', ...);   // err.statusCode 400 three times, countDocuments 0
test('detail longer than 40 chars is cut to 40', ...);
test('the old endpoint still refuses a new placement', async () => {
  const { err } = await callSingle({ placement: 'wave_cap', action: 'shown' });
  assert.equal(err.statusCode, 400);
  assert.match(err.message, /^placement must be one of: visitor_list, conversation_cap, translation_cap, ad_removal, discovery_priority$/);
});
test('the guard answers 404 when the switch is off', ...);   // call paywallEventsEnabledGuard with the flag module mocked to false
test('app-config carries paywallEventsEnabled', ...);
```

- [ ] **Step 2: Run** `node --experimental-test-module-mocks --test --test-force-exit test/paywallEventsBatch.test.js`. Expected: FAIL (`recordPaywallEvents` is not a function).
- [ ] **Step 3: Implement** the flag, model changes, `recordPaywallEvents(req, res, next)`, `paywallEventsEnabledGuard(req, res, next)` (exported from the controller), the limiter, the route, and the app-config key (placed directly after `communityFastListEnabled`).
- [ ] **Step 4: Run** the new test file and `test/paywallEventLog.test.js`. Expected: both PASS.
- [ ] **Step 5: Commit** `feat(paywall): record the whole paywall funnel in batches (PAYWALL_EVENTS_ENABLED, off)`.

---

### Task 2: App version on purchase attempts

**Files:**
- Modify: `models/PurchaseAttempt.js`
- Test: `test/purchaseAttemptLog.test.js` (add cases)

**Interfaces:** `recordPurchaseAttempt` keeps its signature.

Rule: when `securityEventContext(req)` gives an empty `appVersion`, use `parseHeader(req.headers['x-app-version'])` for `appVersion` and `appBuild`. A `clientInfo` value still wins.

- [ ] **Step 1: Add failing tests:**

```js
test('app version comes from the X-App-Version header when the body has none', async () => {
  await recordPurchaseAttempt({ userId, platform: 'ios', productId: 'p', outcome: 'rejected', reason: 'x',
    req: { headers: { 'x-app-version': '2.2.6+10581' }, body: {} } });
  const row = await PurchaseAttempt.findOne({}).lean();
  assert.equal(row.appVersion, '2.2.6');
  assert.equal(row.appBuild, '10581');
});
test('clientInfo still wins over the header', ...);          // body.clientInfo.appVersion '9.9.9' -> '9.9.9'
test('a garbage header leaves appVersion empty and does not throw', ...);
```

- [ ] **Step 2: Run** the file. Expected: the first new test FAILS (`'' !== '2.2.6'`).
- [ ] **Step 3: Implement** the fallback inside `recordPurchaseAttempt`'s `try`.
- [ ] **Step 4: Run** the file. Expected: PASS.
- [ ] **Step 5: Commit** `fix(purchases): log the app version on purchase attempts from the request header`.

---

### Task 3: Funnel report

**Files:**
- Create: `lib/paywallFunnel.js`, `scripts/paywallFunnel.js`
- Test: `test/paywallFunnel.test.js`

**Interfaces:**
- Produces: `summarize(rows) -> { byPlacement: [...], people: {...} }`, pure, where `rows` are lean `PaywallEvent` documents.

`summarize` rules:

- A flow belongs to the placement of its earliest event. Events without a `flowId` are each their own flow.
- Per placement row: `placement`, `peopleShown` (distinct users with `shown`), `flows`, and distinct-flow counts `ctaVip`, `ctaCoins`, `ctaAd`, `dismissed`, `plansViewed`, `shopViewed`, `purchaseStarted`, `purchaseSucceeded`, `purchaseFailed`, `unlockSucceeded`, plus `conversion` = (`purchaseSucceeded` + `unlockSucceeded`) / flows that had `shown`, or `null` when no flow was shown.
- Sorted by `peopleShown` descending, then placement name.
- `people`: `{ shownAny, tappedAny, boughtAny }` as distinct user counts.

The script takes `[days]` (default 14), connects with `MONGO_URI` from `config/config.env` like the other scripts in `scripts/`, loads `createdAt >= now - days`, prints the table and the `people` line, and never writes.

- [ ] **Step 1: Write the failing test:**

```js
test('a flow is counted under the placement where it started', () => {
  const out = summarize([
    ev('u1', 'visitor_list', 'shown', 'f1', 1), ev('u1', 'visitor_list', 'cta_vip', 'f1', 2),
    ev('u1', 'vip_entry', 'plans_viewed', 'f1', 3), ev('u1', 'vip_entry', 'purchase_succeeded', 'f1', 4),
    ev('u2', 'visitor_list', 'shown', 'f2', 1), ev('u2', 'visitor_list', 'dismissed', 'f2', 2),
    ev('u3', 'wave_cap', 'shown', undefined, 1),
  ]);
  const v = out.byPlacement.find((r) => r.placement === 'visitor_list');
  assert.deepEqual({ p: v.peopleShown, f: v.flows, c: v.ctaVip, pv: v.plansViewed, ok: v.purchaseSucceeded, conv: v.conversion },
    { p: 2, f: 2, c: 1, pv: 1, ok: 1, conv: 0.5 });
  assert.equal(out.byPlacement.some((r) => r.placement === 'vip_entry'), false);
  assert.deepEqual(out.people, { shownAny: 3, tappedAny: 1, boughtAny: 1 });
});
test('no rows gives an empty table and zero people', ...);
test('a placement never shown has conversion null', ...);   // only a plans_viewed event
```

- [ ] **Step 2: Run.** Expected: FAIL (module missing).
- [ ] **Step 3: Implement** `summarize` and the script.
- [ ] **Step 4: Run.** Expected: PASS. Also run `node scripts/paywallFunnel.js 1` against the local config only if a database is reachable; otherwise skip and say so in the report.
- [ ] **Step 5: Commit** `feat(paywall): funnel report script`.

---

### Task 4: Offer rules (pure)

**Files:**
- Create: `lib/offerEngine.js`
- Test: `test/offerEngine.test.js`

**Interfaces (Produces):**

```js
const SURFACES = [   // order is the tie-break order
  { id: 'visitor_recall', placement: 'visitor_list', coinCost: UNLOCKS.who_waved.cost },   // 60
  { id: 'profile_banner', placement: 'vip_entry', coinCost: null },
  { id: 'moments_chip', placement: 'vip_entry', coinCost: null },
  { id: 'matches_empty', placement: 'matches_empty', coinCost: BOOST_COST },                // 150
];
const RULES = { minAccountAgeHours: 48, minActiveDays: 2, surfaceGapDays: 3, ignoredMax: 3,
  ignoredQuietDays: 14, purchaseQuietDays: 7, visitorMin: 2, visitorLookbackDays: 30,
  prior: 0.02, priorWeight: 20, rateWindowDays: 60, weight: { vip: 4, coins: 1 } };

utcDay(date) -> 'YYYY-MM-DD'
userEligible({ tier, isBanned, createdAt, activeDays, recentPurchase }, now) -> boolean
surfaceEligible(surfaceId, { state, newVisitors, revealed }, now) -> boolean
leadFor(surfaceId, coinBalance) -> 'coins' | 'vip'
rateOf({ shown, converted }) -> number          // (converted + 0.4) / (shown + 20)
decide({ user, state, newVisitors, revealed, coinBalance, rates }, now) -> null | { surface, placement, lead }
applySeen(state, offerId, now) -> state          // returns a new object
applyTap(state, offerId) -> state
```

`state` is the plain shape of an `OfferState` row (Task 5): `{ today: { day, offerId, surface, placement, lead, seen } | null, surfaces: { [id]: { lastOfferedAt, ignored, quietUntil } } }`. `rates` is `{ [surfaceId]: { shown, converted } }`; a missing surface counts as zeros.

Rules:

- `userEligible`: `tier !== 'vip'`, not banned, `createdAt` is a valid date at least 48 hours before `now`, `activeDays >= 2`, `recentPurchase` false.
- `surfaceEligible`: `lastOfferedAt` missing or at least 3 whole days before `now`; `quietUntil` missing or past; and for `visitor_recall` only: `revealed` false and `newVisitors >= 2`.
- `leadFor`: `coins` when the surface has a `coinCost` and `coinBalance >= coinCost`; otherwise `vip`.
- `decide`: null when the user is not eligible or no surface is; otherwise the eligible surface with the highest `rateOf(rates[id]) * weight[lead]`, ties in `SURFACES` order.
- `applySeen`: only when `state.today` exists, `String(today.offerId) === String(offerId)` and `today.seen` is not true. Sets `today.seen = true` and adds 1 to that surface's `ignored`; when it reaches 3, sets `quietUntil = now + 14 days` and `ignored = 0`. Any other input returns the state unchanged.
- `applyTap`: only when the offer id matches today's. Sets that surface's `ignored = 0` and `today.tapped = true`.

- [ ] **Step 1: Write the failing tests** (`NOW = new Date('2026-11-14T12:00:00Z')`; `base()` returns an eligible input with `coinBalance: 0`, empty state, `newVisitors: 3`):

```js
test('nobody in their first 48 hours gets an offer', () => {
  assert.equal(decide({ ...base(), user: { ...base().user, createdAt: new Date(NOW - 47 * 3600e3) } }, NOW), null);
});
test('VIP, banned, one active day, a recent purchase, or a missing createdAt all get nothing', ...);
test('with no evidence the VIP-led visitor card wins on table order', () => {
  assert.deepEqual(decide(base(), NOW), { surface: 'visitor_recall', placement: 'visitor_list', lead: 'vip' });
});
test('enough coins for the reveal makes the lead coins, and a VIP-led surface then outranks it', () => {
  assert.deepEqual(decide({ ...base(), coinBalance: 60 }, NOW), { surface: 'profile_banner', placement: 'vip_entry', lead: 'vip' });
});
test('one visitor, or an open reveal window, rules the visitor card out', ...);   // -> profile_banner
test('a surface offered 2 days ago is skipped; 3 days ago is allowed', ...);
test('evidence moves the order', () => {
  const rates = { moments_chip: { shown: 100, converted: 10 } };
  assert.equal(decide({ ...base(), rates }, NOW).surface, 'moments_chip');
});
test('rateOf with nothing is 0.02', () => assert.equal(rateOf({ shown: 0, converted: 0 }), 0.02));
test('the third ignored view quiets the surface for 14 days and resets the count', ...);
test('a second seen for the same offer changes nothing', ...);
test('seen or tap with another offer id changes nothing', ...);
test('a tap resets the ignored count', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL (module missing).
- [ ] **Step 3: Implement** `lib/offerEngine.js`. No database access, no `Date.now()`; `now` is always passed in.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(offers): pure offer rules`.

---

### Task 5: Offer state, service and `GET /offers`

**Files:**
- Create: `models/OfferState.js`, `models/OfferRates.js`, `lib/offerService.js`, `controllers/offers.js`, `routes/offers.js`
- Modify: `config/limitations.js`, `server.js` (mount `/api/v1/offers` next to `/api/v1/boosts`), `controllers/appConfig.js`, `models/User.js`, `controllers/profileVisits.js`, `services/userCascadeDeleteService.js`
- Test: `test/offersEndpoint.test.js`

**Interfaces:**
- Consumes: Task 4's `decide`, `utcDay`, `SURFACES`, `RULES`; `tierOf`, `perksFor` from `lib/tier.js`.
- Produces: `OFFER_ENGINE_ENABLED`; `offerService.getOffers(userId, now) -> Promise<Array<{ id, surface, placement, lead }>>`; `offerService.getRates() -> Promise<object>` (reads the `OfferRates` document, cached in memory for 10 minutes; `{}` when absent); app-config key `offerEngineEnabled` (after `paywallEventsEnabled`); `User.visitorsSeenAt` (Date).

Models:

- `OfferState`: `_id` is the user's ObjectId. Fields: `today: { day, offerId, surface, placement, lead, seen, tapped }`, `surfaces` (Mixed, keyed by surface id), timestamps. Options `{ collection: 'offerstates', autoCreate: false, autoIndex: false }`.
- `OfferRates`: `_id` String (`'current'`), `surfaces` Mixed, `computedAt` Date. Options `{ collection: 'offerrates', autoCreate: false, autoIndex: false }`.

`getOffers` steps:

1. Return `[]` when `PAYWALL_EVENTS_ENABLED` is off.
2. Load the user (`userMode vipSubscription whoWavedUntil isBanned createdAt coinBalance visitorsSeenAt`) and the state row. Missing user: `[]`.
3. `recentPurchase`: a `CoinTransaction` for the user with `type` `purchase` or `spend` in the last 7 days exists. (The ledger is the truth for this; it does not depend on app events. This narrows spec 5.4 on purpose.)
4. If `state.today.day === utcDay(now)`: return that stored offer, unless the user is no longer eligible (`userEligible` false), in which case `[]`.
5. Otherwise gather: `activeDays` (`UserActivityDay.countDocuments({ userId }, { limit: 2 })`), `newVisitors` (distinct non-anonymous `visitor` in `ProfileVisit` for this owner with `visitedAt` after the later of `visitorsSeenAt` and `now - 30 days`), `revealed` (`perksFor(user, now).revealWaves`), rates.
6. `decide(...)`. Null: `[]`.
7. Reserve with one conditional write: `updateOne({ _id: userId, 'today.day': { $ne: day } }, { $set: { today: { day, offerId: new ObjectId(), surface, placement, lead }, ['surfaces.' + surface + '.lastOfferedAt']: now } }, { upsert: true })`. On a duplicate-key error or zero matched documents, re-read the row and return its `today` offer (another request won the race).
8. Return `[{ id: String(offerId), surface, placement, lead }]`.

Route: `offerEngineEnabledGuard` (404 while off), `protect`, `authenticatedLimiter`. Response `200 { success: true, offers }`.

`visitorsSeenAt`: in `getProfileVisitors`, after the ownership check and only when `OFFER_ENGINE_ENABLED` is on, `User.updateOne({ _id: requesterId }, { $set: { visitorsSeenAt: new Date() } })`, not awaited, errors logged. The field must not appear in `PROFILE_UPDATE_FIELDS`.

Cascade: in `userCascadeDeleteService`, delete `offerstates` by `_id` and `paywallevents` by `userId`, each in the service's existing numbered-step style with a `stats` count.

- [ ] **Step 1: Write the failing tests** (in-memory Mongo; both switches on; a helper seeds a 5-day-old regular user with 3 activity days and 3 distinct visitors):

```js
test('an eligible user gets one offer and the slot is reserved', async () => {
  const offers = await getOffers(u._id, NOW);
  assert.equal(offers.length, 1);
  assert.deepEqual(Object.keys(offers[0]), ['id', 'surface', 'placement', 'lead']);
  assert.equal(offers[0].surface, 'visitor_recall');
  const row = await OfferState.findById(u._id).lean();
  assert.equal(row.today.day, '2026-11-14');
  assert.ok(row.surfaces.visitor_recall.lastOfferedAt);
});
test('a second call the same day returns the same id', ...);
test('two calls at once return the same id and leave one row', async () => {
  const [a, b] = await Promise.all([getOffers(u._id, NOW), getOffers(u._id, NOW)]);
  assert.equal(a[0].id, b[0].id);
  assert.equal(await OfferState.countDocuments({}), 1);
});
test('the next day picks a different surface (3-day gap)', ...);          // NOW + 1 day -> not visitor_recall
test('a coin spend in the last 7 days means no offer, even with one reserved today', ...);
test('a 47-hour-old account, a VIP, and a banned user get []', ...);
test('visitors seen after the last visit rule the visitor card out', ...); // visitorsSeenAt = NOW -> profile_banner
test('with PAYWALL_EVENTS_ENABLED off getOffers returns [] and writes nothing', ...);   // separate process env; see note
test('loading your own visitors list stamps visitorsSeenAt only when the switch is on', ...);
test('deleting the account removes the offer state and the paywall events', ...);
```

Note for the off cases: the flags are read at require time, so put switch-off cases in `test/offersEndpointOff.test.js` with the env unset.

- [ ] **Step 2: Run.** Expected: FAIL (module missing).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** both test files, plus `test/profileVisitCleanup.test.js` and `test/userPrivacyRedaction.test.js`. Expected: PASS (report any failure that also fails on `main` as pre-existing, with proof).
- [ ] **Step 5: Commit** `feat(offers): GET /offers with a reserved daily slot (OFFER_ENGINE_ENABLED, off)`.

---

### Task 6: Events feed the caps; nightly conversion counts

**Files:**
- Modify: `controllers/paywallEvents.js`, `lib/offerService.js`, `jobs/scheduler.js`
- Create: `jobs/offerRatesJob.js`
- Test: `test/offerEventsAndRates.test.js`

**Interfaces:**
- Consumes: `applySeen`, `applyTap`, `SURFACES`, `RULES` (Task 4); `OfferState`, `OfferRates`, `getRates` (Task 5).
- Produces: `offerService.applyEvents(userId, events, now) -> Promise<void>`; `offerRatesJob.run(now?) -> Promise<{ skipped: true } | { surfaces }>`; `computeRates(rows) -> { [surfaceId]: { shown, converted } }` (pure, exported for the test).

Rules:

- After the batch insert, and only when `OFFER_ENGINE_ENABLED` is on and at least one stored item has an `offerId`, the controller calls `applyEvents` without awaiting it; a failure is logged and never changes the response.
- `applyEvents` loads the user's own row once, folds the stored events in order (`shown` to `applySeen`; any `cta_*` to `applyTap`), and writes back only if something changed. An `offerId` that is not the row's `today.offerId` changes nothing, so another user's id is harmless.
- `computeRates`: input is the last 60 days of events that carry an `offerId`. The surface of an offer is the `detail` of its `shown` event, counted only when it is one of the four surface ids. `shown` = distinct offer ids with a `shown`. `converted` = distinct offer ids whose `flowId` (from any of its events) also appears on a `purchase_succeeded` or `unlock_succeeded` event in the same input window. The job therefore loads: events with `offerId`, plus success events whose `flowId` is in that set.
- `run`: `{ skipped: true }` when `OFFER_ENGINE_ENABLED` is off (no query, no write). Otherwise upserts the `OfferRates` document `{ _id: 'current', surfaces, computedAt }` and logs the duration.
- Scheduler: `scheduleOfferRates()` beside `scheduleMatchSignals()`, nightly at 04:40 KST with `getMillisecondsUntil(4, 40)`, always scheduled, same try/catch shape.

- [ ] **Step 1: Write the failing tests:**

```js
test('three days of seen-without-tap quiet the surface for 14 days', async () => { ... });   // three days: getOffers, applyEvents([shown]); gap forced by resetting lastOfferedAt
test('many shown events for one offer count once', async () => {
  await applyEvents(u._id, [shown(id), shown(id), shown(id)], NOW);
  assert.equal((await OfferState.findById(u._id).lean()).surfaces.visitor_recall.ignored, 1);
});
test('a tap resets the count', ...);
test("another user's offer id changes nothing", ...);
test('the batch endpoint answers before and regardless of applyEvents failing', ...);   // mock applyEvents to reject -> 201
test('computeRates counts shown offers per surface and conversions by flow', () => {
  const rows = [
    e({ offerId: A, action: 'shown', detail: 'visitor_recall', flowId: 'f1' }),
    e({ offerId: A, action: 'cta_coins', flowId: 'f1' }),
    e({ action: 'unlock_succeeded', flowId: 'f1' }),
    e({ offerId: B, action: 'shown', detail: 'visitor_recall', flowId: 'f2' }),
    e({ offerId: C, action: 'shown', detail: 'something_else', flowId: 'f3' }),
  ];
  assert.deepEqual(computeRates(rows), { visitor_recall: { shown: 2, converted: 1 } });
});
test('run writes the document; getRates returns it', ...);
```

Switch-off case (`run` returns `{ skipped: true }`, no `offerrates` collection) goes in `test/offersEndpointOff.test.js`.

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** this file, `test/paywallEventsBatch.test.js` and `test/offersEndpointOff.test.js`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(offers): seen and tapped events drive the caps; nightly conversion counts`.

---

### Task 7: Masked visit push for free users

**Files:**
- Modify: `config/limitations.js`, `services/notificationService.js`, `notification_templates/*.json` (all 19)
- Test: `test/profileVisitPushMask.test.js`

**Interfaces:**
- Produces: `VISITOR_PUSH_MASK_ENABLED`; new template keys `profile_visit_masked_single` and `profile_visit_masked_bundle`.

Rules, inside `sendProfileVisit`:

- Masked when the switch is on and `perksFor(profileOwner).revealWaves` is false. Decide once, before `bundlingService.collect`.
- Masked: collect with vars `{ actorId: 'masked', actorName: '', visitorImage: null }`; render `profile_visit_masked_single` or `profile_visit_masked_bundle`; `data` is exactly `{ type: 'profile_visit', screen: 'visitors', masked: 'true', bundleSize }`; no `userId`, no `bundleActors`, no `imageUrl`.
- Not masked: today's code path, unchanged byte for byte.
- English copy: single title `👀 Someone viewed your profile`, body `Tap to see your visitors`; bundle title `👀 {count} new profile visitors`, body `Tap to see your visitors`. Add both keys to every locale file with a translation in that locale; list the 18 non-English files in `docs/REMAINING_WORK.md` as machine-drafted, needing native review.
- The live app returns no route for a `profile_visit` push without `userId` (the tap just opens the app); Plan D2 routes `screen: 'visitors'`.

- [ ] **Step 1: Write the failing tests** (mock `bundlingService.collect` to call its flush with a one-item bundle, and mock `send` to capture):

```js
test('switch off: the push names the visitor exactly as today', ...);   // data.userId present, title contains the name, imageUrl set
test('switch on, free owner: no name, no photo, no ids', async () => {
  const n = await pushFor(freeOwner, visitor);
  assert.equal(n.title, '👀 Someone viewed your profile');
  assert.deepEqual(n.data, { type: 'profile_visit', screen: 'visitors', masked: 'true', bundleSize: 1 });
  assert.equal(n.imageUrl, undefined);
  assert.ok(!JSON.stringify(n).includes(String(visitor._id)));
  assert.ok(!JSON.stringify(n).includes(visitor.name));
});
test('switch on, VIP owner or owner inside a reveal window: named push', ...);
test('every locale file has both masked keys with a {count} in the bundle title', ...);
```

Use two test files if the switch must differ at require time.

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS. Also run any existing notification template test (`ls test | grep -i template`).
- [ ] **Step 5: Commit** `feat(notifications): masked visit push for free users (VISITOR_PUSH_MASK_ENABLED, off)`.

---

### Task 8: Switch-off identity, rollout guide

**Files:**
- Create: `test/support/offersOffScenario.js`, `scripts/dev/generateOffersOffFixtures.js`, `test/fixtures/offers-off/bodies.json`, `test/offersOffIdentity.test.js`, `docs/rollout/monetization-offers.md`
- Modify: `docs/REMAINING_WORK.md`

**Interfaces:** follows `test/support/matchingV2OffScenario.js` and `test/matchingV2OffIdentity.test.js` exactly (in-memory Mongo, frozen clock, fixed ids, JSON string equality). Read both before writing.

Scenario (must use only code that exists on `main`, so the same file runs on both trees): with the three new switches unset and `BOOSTS_ENABLED=true`, seed two regular users and one VIP, three profile visits and one coin transaction, then capture these bodies: `GET /app-config`; `POST /purchases/paywall-event` valid; the same with `placement: 'wave_cap'` (400); `GET /users/:id/visitors` as a free owner with and without `?reveal=1`, and as the VIP; a recorded profile visit followed by the captured push payload from a mocked `send`; `recordPurchaseAttempt` row fields except `appVersion`/`appBuild`.

- Fixtures are generated from `main` (`git stash`-free: use a temporary `git worktree add` of `main`, run the generator there, copy the JSON in). Record the `main` commit in the test header.
- Expected differences, removed and asserted separately: app-config's two new keys, both `false`.
- Further assertions: no `offerstates` or `offerrates` collection exists after the scenario and after `offerRatesJob.run()`; `visitorsSeenAt` is unset on the owner; `POST /purchases/paywall-events` and `GET /offers` answer 404.

Rollout guide contents: what runs at deploy (three new `paywallevents` indexes build; nothing else); the three switches, their order and preconditions from spec section 7 (events on once an app build with the tracker is live; engine on after 200 `shown` events; mask and wave cap are owner decisions); how to read `scripts/paywallFunnel.js`; how to turn each off; the machine-drafted locale strings.

- [ ] **Step 1: Write** the scenario and generator; generate fixtures from `main`.
- [ ] **Step 2: Write** `test/offersOffIdentity.test.js`; run it on the branch. Expected: PASS. If a body differs, fix the code, not the fixture.
- [ ] **Step 3: Run every test file this plan added or touched**, one at a time, plus `test/matchingV2OffIdentity.test.js`. Expected: all PASS.
- [ ] **Step 4: Write** the rollout guide and update `docs/REMAINING_WORK.md` (switch table gains the three switches; open items: turn-on steps, locale review, Plan D2).
- [ ] **Step 5: Commit** `test(offers): switch-off identity against main; rollout guide`.

---

## Server contract for Plan D2 (app)

- `GET /api/v1/app-config` → `paywallEventsEnabled`, `offerEngineEnabled` (booleans; absent on an old server means false).
- `POST /api/v1/purchases/paywall-events`, authenticated, header `X-App-Version` as today. Body `{ events: [{ placement, action, flowId?, detail?, offerId?, clientAt? }] }`, 1 to 50 items; 30 calls per 15 minutes. `201 { success, stored, dropped }`; `404` when off.
- For an engine offer the app sends `offerId` on every event of that flow and sets `detail` to the surface id on the `shown` event. One `shown` per offer per day is enough; repeats are harmless.
- `GET /api/v1/offers`, authenticated → `200 { success, offers: [{ id, surface, placement, lead, validUntil }] }` with zero or one item; `404` when the engine is off; `200` with an empty list when the engine is on but events are off. `surface` is one of `visitor_recall`, `profile_banner`, `moments_chip`, `matches_empty`; `lead` is `coins` or `vip`; `validUntil` is an ISO time (the next UTC midnight). The app drops an offer once `validUntil` has passed. (As built after the final review.)
- `GET /users/:userId/visitors?seen=1`: only the visitors screen adds `seen=1`. It marks the visitors as seen for the offer engine and changes nothing in the response. The recall card's preview request must not send it. (As built after the final review.)
- Masked visit push: `data = { type: 'profile_visit', screen: 'visitors', masked: 'true', bundleSize }`, no `userId`.
