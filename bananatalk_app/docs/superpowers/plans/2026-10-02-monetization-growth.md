# Monetization & Growth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn a $0, 7%-D7 app into one that keeps new users (D7 ≥ 20%) and earns from the retained via rewarded ads, coin sinks (Profile Boost first), and a repriced VIP — in three flag-gated releases.

**Architecture:** Three tranches, each backend-first and dark: **A (2.4.0)** ships what exists; **B (2.5.0)** the retention wave (welcome wave, lifecycle push/email, first-session landing, review prompt, referrals); **C (2.6.0)** the monetization layer (Profile Boost, new coin sinks, rewarded-at-limit, interstitial, VIP reprice). Every money path uses the existing atomic coin ledger (`lib/coinLedger.js` `debit`/`credit`). Every new surface has its own server flag defaulting to off.

**Tech Stack:** Node/Express/Mongoose + node:test + mongodb-memory-server (backend, Node 20 for tests); Flutter/Riverpod + flutter_test + google_mobile_ads + in_app_purchase + in_app_review (app).

**Spec:** `docs/superpowers/specs/2026-10-02-monetization-growth-design.md` — read it first; the spec is the binding authority.

**Repos:** backend `/Users/davis/Desktop/Personal/language_exchange_backend_application` (push to `main` = auto-deploy); app `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`.

**Execution note:** run each tranche as its own SDD run on branch `feat/growth-<tranche>` in both repos; a tranche is "done" when its backend is deployed dark and its app build is cut. Tranche B does not start until 2.4.0 is in the store.

## Global Constraints

- **LIVE-BUILD GUARANTEE (overrides everything below): users on the installed 2.2.4 / 2.2.5 builds must behave identically before and after every backend deploy in this plan.** No existing endpoint, parameter, or response field changes shape or semantics for a request that does not send a new parameter. `SMART_SORT_ENABLED` is the one flag that would change old-build behavior and is therefore NOT flipped at 2.4.0 release time (only after majority adoption of 2.4.0); `CONVERSATION_CAP_ENABLED` stays off throughout. Each task's reviewer must state in its spec-compliance verdict how a 2.2.4 client is unaffected.
- **Additive on the wire; every new surface behind its own flag, default `false`:** `WELCOME_WAVE_ENABLED`, `LIFECYCLE_PUSH_ENABLED`, `REFERRALS_ENABLED`, `REWARDED_LIMITS_ENABLED`, `BOOSTS_ENABLED`. `CONVERSATION_CAP_ENABLED` stays `false`. Flags follow the exact `SMART_SORT_ENABLED` shape in `config/limitations.js` and are exposed in `controllers/appConfig.js` next to `smartSortEnabled`.
- **Money is atomic and idempotent:** every coin movement is one `debit(userId, cost, {reason, relatedId})` or `credit(userId, amount, {type, reason, metadata})` from `lib/coinLedger.js`; never a `user.coinBalance = …; save()`.
- **Prices (coins):** Profile Boost **150 / 24h**; extra daily matches **40 → +3**; see who waved/viewed **60 → 24h**; extra wave **10 → +1**; translation **50 → +10** (existing). Referral reward: inviter **100**, invitee **50**. Rewarded-ad unlock grants exactly one unit of the feature. Caps: boosts ≤ **10 per 1,000 MAU** active; rewarded unlocks ≤ **5 per feature per user per UTC day**.
- **Welcome wave:** 1 per new user ever; a waver takes ≤ **2** duties per UTC day; candidate needs `responseRate ≥ 0.5` OR (`responseRate == null` AND active today); no fake accounts — no candidate → no wave.
- **Lifecycle:** day 1 / 3 / 7 after `createdAt`, skipped for users active that UTC day, never sent twice (per-key dedup).
- **Ads:** no banners in chat or Matches; interstitial ≤ 1 per app session; VIP ad-free. Rewarded/interstitial units are the production IDs already in `lib/services/ad_service.dart`.
- **VIP (store-side):** monthly ~$3.99, yearly ~$24.99; quarterly retired from UI, kept in `lib/storeProducts.js` for existing receipts.
- Backend tests: `~/.nvm/versions/node/v20.20.2/bin/node --test --test-force-exit test/<file>.test.js` (Node 25 breaks a transitive dep). Harness boilerplate: copy `run`/`makeUser`/MongoMemoryServer from `test/usersListFilters.test.js`.
- App: `package:` imports only; `flutter analyze --no-pub` 0 errors; l10n keys added to `lib/l10n/app_en.arb` AND mirrored to the other 18 arbs with English values, then `flutter gen-l10n` (see any 2026-10-01 matching commit for the procedure).
- Commit trailer (two lines): `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` / `Claude-Session: https://claude.ai/code/session_01C4Ca3Gefbq2PfTLbqsUtKb`.

## Review Focus

1. **Welcome wave to a blocked or just-waved pair:** a candidate who blocks the new user, or already has a wave either direction, must be skipped, and caps must hold under concurrent signups. → Task B1 test "skips blocked/already-waved and respects duty caps".
2. **Lifecycle duplicates and active users:** a user who opened the app today must get nothing; a job that runs twice in a day must not send twice. → Task B2 test "idempotent per key, skipped when active today".
3. **Boost without debit / debit without boost:** if boost creation fails after the debit, the coins are refunded; a double-tap cannot create two boosts. → Task C1 test "debit and boost are all-or-nothing; double submit yields one boost".
4. **Self-referral and replay:** a user cannot claim their own code; an invitee can be credited once ever even if the claim is retried. → Task B3 test "self-referral refused; repeat claim credits nothing".
5. **Rewarded unlock replay:** the client can call the unlock endpoint without having watched an ad; the server-side per-day cap is the only real guard, and must hold. → Task C3 test "sixth rewarded unlock in a day is refused".

---

# TRANCHE A — 2.4.0: ship what's built

### Task A1: Copy nits + VIP fallback prices (app)

**Files:**
- Modify: `lib/pages/community/tabs/matches_tab.dart` ("refreshes at midnight" → derived from `nextRefreshAt`)
- Modify: `lib/l10n/app_en.arb` (+18 mirrors): `matchesRefreshHint` → `"refreshes at {time}"` with a `time` placeholder; `segmentSeriousHint` → `"Complete profile · active this week"`
- Modify: `lib/models/vip_subscription.dart` (`VipPlan` fallback prices → monthly 3.99, yearly 24.99; quarterly hidden from `VipPlan.visible` list — add that getter if absent)
- Test: `test/matching/matches_tab_test.dart` (extend), `test/vip_plan_prices_test.dart` (create)

**Interfaces:** Produces `VipPlan.visible` (List<VipPlan> without quarterly) consumed by the VIP screens in Task C7.

- [ ] **Step 1: Failing tests**

```dart
// test/vip_plan_prices_test.dart
test('fallback prices match the store pricing decision', () {
  expect(VipPlan.monthly.price, 3.99);
  expect(VipPlan.yearly.price, 24.99);
  expect(VipPlan.visible.any((p) => p.id == 'quarterly'), isFalse);
});
```

In `matches_tab_test.dart`: pump the tab with a result whose `nextRefreshAt` is tomorrow 00:00 UTC and assert the hint text contains the LOCAL time string (`DateFormat.jm().format(nextRefreshAt.toLocal())`), not the literal "midnight".

- [ ] **Step 2: Run, verify FAIL.** `flutter test test/vip_plan_prices_test.dart test/matching/matches_tab_test.dart`
- [ ] **Step 3: Implement** (hint renders `l10n.matchesRefreshHint(DateFormat.jm().format(result.nextRefreshAt!.toLocal()))`, falling back to the old copy when `nextRefreshAt` is null).
- [ ] **Step 4: Tests green; analyzer 0 errors.**
- [ ] **Step 5: Commit** — `fix(app): local refresh time, honest segment hint, store-aligned VIP fallbacks`

### Task A2: Release 2.4.0 (ops checklist — human + Claude)

**Files:** `pubspec.yaml` (version already 2.4.0+10571 — bump build number only if a prior 2.4.0 build was uploaded), droplet `config/config.env`.

- [ ] **Step 1: Sandbox money smoke on a device** (never run end to end). Sequence on a sandbox Apple ID: Coin Shop → buy `coins.100` → balance +100 → hit a translation limit → `UnlockCta` → debit 50 → proceed → force-quit → relaunch → balance unchanged (receipt replay credits nothing). Record result in the ledger. Any failure = stop and file a bounded fix before release.
- [ ] **Step 2: Build** per the release how-to (JDK 17 toolchain flag; keystore manual), tag `v2.4.0`, submit iOS + Android.
- [ ] **Step 3: On store approval, droplet flags:** `DAILY_MATCHES_ENABLED=true`, `MATCHES_LAYOUT_ENABLED=true` (both invisible to 2.2.4); **leave `SMART_SORT_ENABLED=false`** until the dashboard shows 2.4.0 as the majority build (it changes the old build's list order); `pm2 restart language-app --update-env`; verify `/app-config` + `/matching/daily`.
- [ ] **Step 4: Baseline the scoreboard** (Task C8's script; run its first version now if C8 is done, else record D1/D7/survival/MAU by hand from the queries in the spec).

---

# TRANCHE B — 2.5.0: the retention wave

### Task B1: Welcome wave (backend)

**Files:**
- Modify: `models/Wave.js` (add `source: { type: String, enum: ['user','welcome'], default: 'user' }`)
- Modify: `models/User.js` (add `welcomeWave: { sentAt: Date, from: ObjectId }`, `welcomeWaveDuties: [{ at: Date }]` near `lastSeenAt`)
- Create: `lib/welcomeWave.js`
- Modify: `controllers/auth.js` — the three `profileCompleted = true` sites (lines ~260, ~515, ~1414/1703: check each) call `onProfileCompleted(user)` after save, fire-and-forget
- Modify: `config/limitations.js` (+`WELCOME_WAVE_ENABLED`), `controllers/appConfig.js` (+`welcomeWaveEnabled`)
- Test: `test/welcomeWave.test.js`

**Interfaces:**
- Consumes: `scoringStages` (`lib/matchScoring.js`), `USABLE_PROFILE`, `getBlockedUserIds`, `Wave`, `notificationService.sendWave(recipientId, waverId, waveId, isMutual)`.
- Produces: `pickWelcomeWaver({ newUser, candidates, now }) -> candidate|null` (pure), `sendWelcomeWave(newUserId) -> {sent: boolean, from?: id}`, `onProfileCompleted(user)`.

- [ ] **Step 1: Failing tests**

```js
// pure selection
test('picks the most relevant responsive candidate and respects caps', () => {
  const now = new Date();
  const c = (id, extra) => ({ _id: id, matchScore: 10, responseRate: 0.8, lastActive: now, welcomeWaveDuties: [], ...extra });
  const picked = pickWelcomeWaver({ newUser: { _id: 'n' }, now, candidates: [
    c('ghost', { responseRate: 0.2 }),
    c('busy', { welcomeWaveDuties: [{ at: now }, { at: now }] }),
    c('good', { matchScore: 9 }),
    c('best', { matchScore: 12 }),
  ]});
  assert.equal(picked._id, 'best');
});
test('null responseRate is acceptable only if active today', () => {
  const now = new Date();
  assert.equal(pickWelcomeWaver({ newUser: { _id: 'n' }, now, candidates: [
    { _id: 'stale', matchScore: 50, responseRate: null, lastActive: new Date(now - 3*24*3600*1000), welcomeWaveDuties: [] },
  ]}), null);
});
// integration
test('skips blocked/already-waved and respects duty caps', async () => {
  // newUser blocked by candidate A; candidate B already waved at newUser; candidate C eligible
  // expect: Wave created from C with source 'welcome'; newUser.welcomeWave.from === C; C.welcomeWaveDuties.length === 1
  // second call for the same newUser: no second wave (1 per new user ever)
});
test('flag off → no wave, no error', async () => { /* WELCOME_WAVE_ENABLED=false → sendWelcomeWave resolves {sent:false} */ });
```

- [ ] **Step 2: Run, FAIL.**
- [ ] **Step 3: Implement `lib/welcomeWave.js`:**

```js
'use strict';
const User = require('../models/User');
const Wave = require('../models/Wave');
const { scoringStages } = require('./matchScoring');
const { USABLE_PROFILE } = require('./userVisibility');
const { getBlockedUserIds } = require('../utils/blockingUtils');
const notificationService = require('../services/notificationService');

const DUTY_CAP_PER_DAY = 2;
const MIN_RESPONSE_RATE = 0.5;
const DAY_MS = 24 * 3600 * 1000;

function dutiesToday(c, now) {
  const start = new Date(now); start.setUTCHours(0, 0, 0, 0);
  return (c.welcomeWaveDuties || []).filter((d) => d.at >= start).length;
}

function pickWelcomeWaver({ newUser, candidates, now = new Date() }) {
  const eligible = (candidates || []).filter((c) => {
    if (String(c._id) === String(newUser._id)) return false;
    if (dutiesToday(c, now) >= DUTY_CAP_PER_DAY) return false;
    const rr = c.responseRate;
    if (typeof rr === 'number') return rr >= MIN_RESPONSE_RATE;
    return c.lastActive && (now - new Date(c.lastActive)) <= DAY_MS;
  });
  eligible.sort((a, b) => (b.matchScore || 0) - (a.matchScore || 0));
  return eligible[0] || null;
}

async function sendWelcomeWave(newUserId) {
  const { WELCOME_WAVE_ENABLED } = require('../config/limitations');
  if (!WELCOME_WAVE_ENABLED) return { sent: false };
  const newUser = await User.findById(newUserId);
  if (!newUser || newUser.welcomeWave?.sentAt) return { sent: false };

  const blocked = (await getBlockedUserIds(newUserId)).map(String);
  const waved = await Wave.find({ $or: [{ to: newUserId }, { from: newUserId }] }).distinct('from');
  const excluded = [...new Set([String(newUserId), ...blocked, ...waved.map(String)])];

  const candidates = await User.aggregate([
    { $match: { ...USABLE_PROFILE, 'images.0': { $exists: true },
      _id: { $nin: excluded.map((id) => new (require('mongoose').Types.ObjectId)(id)) } } },
    ...scoringStages({ viewer: newUser, seenIds: [], viewerIntents: newUser.intents, randomJitter: 0 }),
    { $sort: { matchScore: -1, lastActive: -1 } }, { $limit: 30 },
    { $project: { matchScore: 1, responseRate: 1, lastActive: 1, welcomeWaveDuties: 1 } },
  ]);
  const waver = pickWelcomeWaver({ newUser, candidates });
  if (!waver) return { sent: false };

  const wave = await Wave.create({ from: waver._id, to: newUserId, source: 'welcome' });
  await Promise.all([
    User.updateOne({ _id: newUserId, 'welcomeWave.sentAt': { $exists: false } },
      { $set: { welcomeWave: { sentAt: new Date(), from: waver._id } } }),
    User.updateOne({ _id: waver._id }, { $push: { welcomeWaveDuties: { at: new Date() } } }),
  ]);
  notificationService.sendWave(String(newUserId), String(waver._id), wave._id, false)
    .catch((err) => console.error('welcome wave push failed:', err.message));
  return { sent: true, from: waver._id };
}

function onProfileCompleted(user) {
  sendWelcomeWave(user._id).catch((err) => console.error('welcome wave failed:', err.message));
}

module.exports = { pickWelcomeWaver, sendWelcomeWave, onProfileCompleted, DUTY_CAP_PER_DAY, MIN_RESPONSE_RATE };
```

> The chat mirror: `controllers/community.js:274-315` (sendWave) mirrors a 👋 into the conversation. Reuse that block by extracting it to `lib/waveMirror.js` `mirrorWaveToChat({ fromUserId, toUserId, message })` and call it from both `sendWave` and `sendWelcomeWave` — no duplicated logic.

- [ ] **Step 4: Hook `onProfileCompleted(user)` after the `save()` at each `profileCompleted = true` site in `controllers/auth.js`** (verify there are exactly the sites listed; all call the same helper).
- [ ] **Step 5: Tests green** (`test/welcomeWave.test.js` + `test/usableProfile.test.js`). **Commit** — `feat(growth): welcome wave on profile completion (WELCOME_WAVE_ENABLED)`

### Task B2: Lifecycle push + email job (backend)

**Files:**
- Modify: `models/User.js` (+`lifecycleSent: { type: Map, of: Date, default: {} }`)
- Modify: `models/Notification.js:11` enum (+`'daily_matches'`, `'lifecycle_online'`, `'lifecycle_waves'`) — **the enum rejects unknown types silently (see memory); forgetting this loses in-app history**
- Create: `lib/lifecycle.js` (pure: which key is due), `jobs/lifecycleJob.js`
- Modify: `jobs/scheduler.js` (hourly, following `scheduleInactivityJob`'s pattern via `getMillisecondsUntil`)
- Modify: `services/email_templates/*.json` catalogs: keys `lifecycle_day1`, `lifecycle_day3`, `lifecycle_day7` (en + the 7 other existing locales; English fallback is automatic for the rest)
- Modify: `config/limitations.js` (+`LIFECYCLE_PUSH_ENABLED`), `controllers/appConfig.js`
- Test: `test/lifecycle.test.js`

**Interfaces:**
- Consumes: `fcmService.sendToUser(userId, notification, data)`, `emailTemplateService.t(key, locale, vars)`, `emailService` send fn (read `services/emailService.js` exports; use the one `inactivityEmailJob.js` uses), `getDailyMatches`' pool (for the day-3 "online now" person: pick the top reciprocal candidate with `isOnline`), `Wave.countDocuments({to, isRead:false})`.
- Produces: `dueLifecycleKey({ user, now }) -> 'day1'|'day3'|'day7'|null`, `runLifecycleJob() -> {sent}`.

- [ ] **Step 1: Failing tests**

```js
test('dueLifecycleKey picks the window and respects dedup + activity', () => {
  const now = new Date('2026-10-10T12:00:00Z');
  const user = (ageDays, extra = {}) => ({ createdAt: new Date(now - ageDays*24*3600*1000), lastActive: new Date(now - 2*24*3600*1000), lifecycleSent: new Map(), ...extra });
  assert.equal(dueLifecycleKey({ user: user(1), now }), 'day1');
  assert.equal(dueLifecycleKey({ user: user(3), now }), 'day3');
  assert.equal(dueLifecycleKey({ user: user(7), now }), 'day7');
  assert.equal(dueLifecycleKey({ user: user(5), now }), null);
  assert.equal(dueLifecycleKey({ user: user(1, { lastActive: now }), now }), null, 'active today → skip');
  assert.equal(dueLifecycleKey({ user: user(1, { lifecycleSent: new Map([['day1', now]]) }), now }), null, 'already sent');
});
test('idempotent per key, skipped when active today', async () => {
  // in-memory: a user created 1 day ago, inactive; run job twice → exactly one Notification of type daily_matches, lifecycleSent.day1 set
});
```

- [ ] **Step 2: Run, FAIL. Step 3: Implement** — `dueLifecycleKey` computes `ageDays = floor((now - createdAt)/DAY)`; key = `day${ageDays}` if in {1,3,7}, null if `lifecycleSent.has(key)` or `lastActive` is today (UTC). `runLifecycleJob`: flag check; query users `createdAt` between now-8d and now-1d, `profileCompleted: true`; for each due key build content: day1 → `daily_matches` ("Your 6 matches for today are ready", deep link `bananatalk://community/matches`); day3 → `lifecycle_online` with a real person (top reciprocal candidate online; skip the send if none); day7 → `lifecycle_waves` with `n = unread waves` (skip if 0). Send push (`fcmService.sendToUser`) + persist Notification + email via template; then `User.updateOne({_id}, {$set: {[`lifecycleSent.${key}`]: new Date()}})`. Schedule hourly.
- [ ] **Step 4: Tests green. Commit** — `feat(growth): day 1/3/7 lifecycle push + email (LIFECYCLE_PUSH_ENABLED)`

### Task B3: Referrals (backend)

**Files:**
- Modify: `models/User.js` (+`referralCode: { type: String, unique: true, sparse: true }`, `referredBy: ObjectId`, `referralCreditedAt: Date`)
- Create: `lib/referralCode.js` (pure: `generateCode(userId) -> 8-char base32 from a hash`), `controllers/referrals.js`, `routes/referrals.js` (`GET /referrals/me`, `POST /referrals/claim {code}`); mount at `/api/v1/referrals` in `server.js`
- Modify: `config/limitations.js` (+`REFERRALS_ENABLED`), `controllers/appConfig.js`
- Test: `test/referrals.test.js`

**Interfaces:** Produces `GET /referrals/me -> {code, link: 'https://bananatalk.com/i/<code>', invited: n}`; `POST /referrals/claim -> {success, credited: {inviter:100, invitee:50}}`; credits via `coinLedger.credit(userId, amount, {type:'reward', reason:'referral', metadata:{inviteeId}})`.

- [ ] **Step 1: Failing tests**

```js
test('claiming credits both sides exactly once', async () => { /* inviter code; invitee claims → inviter +100, invitee +50; claim again → 409, balances unchanged */ });
test('self-referral refused; repeat claim credits nothing', async () => { /* user claims own code → 400; a second invitee claim of the same user → 409 */ });
test('claim requires a completed profile', async () => { /* profileCompleted:false → 400 */ });
```

- [ ] **Step 2–4:** implement with the credit guarded by `User.findOneAndUpdate({ _id: invitee, referralCreditedAt: { $exists: false }, profileCompleted: true }, { $set: { referredBy, referralCreditedAt: new Date() } })` — the null result is the idempotency check; only then `credit()` both sides. **Commit** — `feat(growth): referral codes + idempotent coin credits (REFERRALS_ENABLED)`

### Task B4: First session lands on Matches + permission timing (app)

**Files:**
- Modify: the post-registration navigation (find with `grep -rn "pushAndRemoveUntil\|pushReplacement" lib/pages/authentication/register/ lib/pages/home/splash_screen.dart` — the route that opens the home shell after profile completion) → open the home shell with the Community tab selected and `initialCommunityTab: 'matches'`; thread that parameter through `TabBarMenu` to `CommunityMain`'s initial index (it already has the index-remap helpers).
- Modify: `lib/services/notification_service.dart:123` (`_requestPermission` call site): request **only after** the first wave/match arrives — add `NotificationService.requestPermissionIfPending()` called from the Waves tab badge update and from MatchesTab's first successful load; store a `notif_prompted` SharedPreferences flag so it asks once.
- Test: `test/growth/first_session_test.dart`

- [ ] **Step 1: Failing test** — pump `CommunityMain` with `initialCommunityTab: 'matches'` and the layout flag on → `MatchesTab` is visible; with flag off → legacy index 0 (Partners "All").
- [ ] **Step 2–4:** implement; `flutter test test/growth/ test/matching/` green; analyzer 0. **Commit** — `feat(app): new users land on Matches; notification prompt waits for the first wave`

### Task B5: Review prompt + referral UI (app)

**Files:**
- Modify: `pubspec.yaml` (+`in_app_review: ^2.0.9`)
- Create: `lib/services/review_prompt_service.dart` (`maybePrompt({required int myMessages, required int theirMessages})` — prompts when both ≥ 3, at most once per 60 days via SharedPreferences `review_prompt_at`)
- Modify: `lib/pages/chat/conversation/chat_conversation_screen.dart` — after a send succeeds, compute counts from the loaded thread and call `maybePrompt`
- Create: `lib/pages/profile/referral_screen.dart` (code, share sheet via `share_plus` if present else `Share` API, "invited n"); entry in the profile menu; `lib/services/deep_link_service.dart` handles `/i/<code>` → stores `pending_referral_code`; after profile completion the app calls `POST /referrals/claim`
- Test: `test/growth/review_prompt_test.dart` (pure gating), `test/growth/referral_link_test.dart` (parser extracts code)

- [ ] Failing tests → implement → green → **Commit** — `feat(app): review prompt after a real conversation; referral screen + invite links`

### Task B6: Lifecycle deep links (app)

**Files:** `lib/services/deep_link_parser.dart` (+`community/matches`, `community/waves`, `chat/<userId>` routes), push tap handler in `notification_service.dart` routes `daily_matches` → Matches tab, `lifecycle_online` → the person's chat, `lifecycle_waves` → Waves tab.
- Test: `test/growth/lifecycle_links_test.dart` (parser table test).
- [ ] Failing test → implement → green → **Commit** — `feat(app): lifecycle push deep links`

### Task B7: Release 2.5.0 (ops)

- [ ] Backend tranche merged + deployed dark → app build `v2.5.0` → on approval set `WELCOME_WAVE_ENABLED=true`, `LIFECYCLE_PUSH_ENABLED=true`, `REFERRALS_ENABLED=true` → verify a fresh sandbox signup receives a welcome wave within 1 minute → scoreboard run.

---

# TRANCHE C — 2.6.0: the monetization layer

### Task C1: Boost model + purchase + expiry (backend)

**Files:**
- Create: `models/Boost.js`, `lib/boosts.js`, `controllers/boosts.js`, `routes/boosts.js` (`POST /boosts {kind:'profile'}`, `GET /boosts/active`, `GET /boosts/history`), mount `/api/v1/boosts`
- Create: `jobs/boostExpiryJob.js` (every 10 min: expire, send receipt notification `boost_receipt` — add to the Notification enum)
- Modify: `config/limitations.js` (+`BOOSTS_ENABLED`), `controllers/appConfig.js`
- Test: `test/boosts.test.js`

**Interfaces:**
- Consumes: `coinLedger.debit/credit`.
- Produces: `Boost { user, kind:'profile'|'moment', startsAt, endsAt, impressions:Number, coinsSpent, status:'active'|'expired'|'refunded' }`; `activeBoostIds() -> Set<string>` and `recordBoostImpressions(boostIds[]) -> Promise` (used by C2); `BOOST_COST = 150`, `BOOST_HOURS = 24`, `BOOSTS_PER_1000_MAU = 10`.

- [ ] **Step 1: Failing tests**

```js
test('debit and boost are all-or-nothing; double submit yields one boost', async () => {
  // user with 150 coins; two concurrent POSTs → exactly one Boost, balance 0, second gets 409 'already boosted'
  // user with 100 coins → 402, no Boost, balance 100
});
test('capacity cap refuses when full', async () => { /* MAU stub 500 → cap 5; 5 active boosts → 6th gets 429 */ });
test('expiry marks expired and emits a receipt with the impression count', async () => { /* endsAt in the past, impressions 37 → status expired, Notification boost_receipt with 37 */ });
```

- [ ] **Step 2–4:** implement. Purchase order: `Boost.findOne({user, status:'active'})` → 409; capacity check; **debit first** (`debit(user, 150, {reason:'boost:profile'})` → 402 on insufficient); then `Boost.create` inside try; on failure `credit(user, 150, {type:'refund', reason:'refund:boost:profile'})`. The "one active boost per user" is enforced by a partial unique index `{ user: 1 }` where `status: 'active'` so the race in the test resolves to one document. **Commit** — `feat(coins): Profile Boost purchase, capacity cap, expiry receipt (BOOSTS_ENABLED)`

### Task C2: Boost placement in Matches + Partners (backend)

**Files:** `controllers/matching.js` (getDailyMatches: reserve slot 6), `controllers/users.js` (smart sort: pin active boosts first), `lib/dailyMatches.js` (+`applyBoostSlot({ batch, boosted, batchSize })` pure)
- Test: `test/boostPlacement.test.js`

- [ ] **Step 1: Failing tests** — pure: `applyBoostSlot` replaces the 6th card with the highest-relevance active booster not already present, never slots 1–5, and does nothing when no booster is relevant; integration: a boosted user with `responseRate 0.1` is NOT placed (ghost rule), a boosted reciprocal user IS, and `recordBoostImpressions` increments once per batch generation (not per cached hit).
- [ ] **Step 2–4:** implement; boosted cards carry `boosted: true` in the match payload (additive). **Commit** — `feat(matching): boosted slot 6 + Partners pin, impression counting`

### Task C3: New coin sinks + rewarded unlock (backend)

**Files:** `config/coinCatalog.js` `UNLOCKS` (+`extra_matches: {cost:40, grant:3}`, `who_waved: {cost:60, grant:1}` (24h reveal), `wave: {cost:10, grant:1}`), `controllers/coins.js` (+`rewardedUnlock` POST `/coins/rewarded-unlock {feature}` — credits exactly `UNLOCKS[feature].cost` with reason `ad_reward:<feature>` then immediately runs the same path as `unlock`; cap 5/feature/day), `controllers/matching.js` (honor `extra_matches` bonus pool: batch size 6 + granted extras today), `config/limitations.js` (+`REWARDED_LIMITS_ENABLED`)
- Test: `test/rewardedUnlock.test.js`

- [ ] **Step 1: Failing tests** — "sixth rewarded unlock in a day is refused" (429, no credit, no grant); "rewarded unlock nets zero coins and grants one unit"; "extra_matches grant raises today's batch to 9".
- [ ] **Step 2–4:** implement. **Commit** — `feat(coins): extra matches / who-waved / wave sinks + rewarded unlock (REWARDED_LIMITS_ENABLED)`

### Task C4: Who-waved/viewed reveal + VIP perks (backend)

**Files:** `controllers/community.js` getWaves (+`revealed: boolean` per wave — true when VIP or an active `who_waved` grant; otherwise the sender's name/photo are masked to `null` and `maskedCount` is returned), `controllers/users.js` profile-visits endpoint (same masking), `lib/tier.js` (VIP perk map: `adFree`, `unlimitedMatches`, `revealWaves`, `unlimitedWaves`, `advancedFilters`), `controllers/purchases.js` `/plans` (hide quarterly; prices 3.99/24.99 for the fallback display), `lib/storeProducts.js` keep quarterly ids.
- Test: `test/revealGating.test.js`

> **Compatibility rule:** masking is ADDITIVE — add `revealed`/`maskedCount` fields and null out sender fields only when the client sends `?reveal=1` (new builds). Old builds keep today's unmasked behavior; the spec's "coin sink" only has teeth once the 2.6.0 build asks for the gated shape.

- [ ] Failing tests (VIP sees all; free with grant sees all for 24h; free without sees masked + count; legacy request shape unchanged) → implement → **Commit** — `feat(monetization): who-waved reveal gating, VIP perk map, /plans reprice`

### Task C5: Boost + extra matches UI (app)

**Files:** `lib/services/boost_api_client.dart`, `lib/pages/coins/boost_screen.dart` (entry: profile menu + Matches empty-state "Get seen by more people"), `lib/pages/community/card/match_card.dart` (+"Boosted" chip when `boosted`), Matches empty state (+"+3 more matches — 40 coins" via `UnlockCta(featureKey: 'extra_matches')`), receipt notification type in the app's notification parser.
- Test: `test/growth/boost_ui_test.dart` (screen shows cost 150, confirm calls client; insufficient → opens Coin Shop).
- [ ] Failing test → implement → **Commit** — `feat(app): Profile Boost purchase + Boosted chip + extra matches CTA`

### Task C6: Rewarded-at-limit + interstitial + VIP ad-free (app)

**Files:** `lib/widgets/limit_exceeded_dialog.dart` (watch-ad path calls `POST /coins/rewarded-unlock {feature}` after `onUserEarnedReward`, then proceeds as "unlocked"), `lib/services/ad_service.dart` (+`maybeShowInterstitialOncePerSession(trigger)` with a session flag; `isAdFree` already reads VIP), Matches tab (interstitial when the batch is exhausted), chat screen (interstitial on leaving a chat with ≥10 messages — once per session total). Assert no `BannerAd` in `matches_tab.dart` / chat screen.
- Test: `test/growth/interstitial_policy_test.dart` (pure session-cap policy; VIP never).
- [ ] Failing test → implement → **Commit** — `feat(app): rewarded unlocks at limits, one interstitial per session, VIP ad-free`

### Task C7: Who-waved reveal + VIP screen (app)

**Files:** Waves tab (masked rows → "Someone waved at you" + "Reveal for 60 coins / Go VIP"), profile visitors (same), VIP screen (`VipPlan.visible`, new perk list copy, entry points: ad "remove ads" button, reveal teaser, Matches empty-state chip). l10n keys for all copy (+18 mirrors).
- Test: `test/growth/vip_screen_test.dart` (two plans shown, quarterly absent, perk list matches spec).
- [ ] Failing test → implement → **Commit** — `feat(app): wave/visit reveal gating, repriced VIP with discovery perks`

### Task C8: Growth dashboard + launch assets (ops/backend)

**Files:** backend `scripts/growthDashboard.js` (one line each: signups 7d/30d, D1, D7, conversation survival 14d, MAU, coin buyers 30d, VIP active, boosts 30d; AdMob $ and store conversion are typed in by hand from the dashboards); `docs/marketing/2026-10-store-listings-{zh,ar,ru}.md` (title/subtitle/description drafts); `docs/marketing/launch-campaign.md` (push + email copy in 8 languages reusing `emailTemplateService` keys `campaign_daily_matches`).

```js
// scripts/growthDashboard.js (extend scripts/conversationSurvival.js's pattern)
// prints: signups7 signups30 d1 d7 survival14 mau wau dau coinBuyers30 vipActive boosts30
```

- [ ] Script committed and run once (baseline row recorded in the ledger) → **Commit** — `chore(growth): weekly growth dashboard + launch assets`

### Task C9: Release 2.6.0 (ops)

- [ ] Backend tranche deployed dark → store pricing changed in App Store Connect / Play Console (monthly 3.99, yearly 24.99) → app build `v2.6.0` → on approval flip `BOOSTS_ENABLED`, `REWARDED_LIMITS_ENABLED` → sandbox smoke: buy boost → appears in a test account's batch slot 6 → expiry receipt → weekly dashboard cadence begins.

---

## Self-review notes

- Spec coverage: §Release1 → A1/A2; §2a → B4; §2b → B1; §2c → B2/B6; §2d → B5 (review+referral UI) + B3 (referral backend); §3a → C6 (+C3 endpoint); §3b → C3/C5; §3c → C1/C2/C5; §3d → C4/C7; §4 → C8 + A2/B7/C9 ops; §5 flags → each task's flag line. Moment boost: `kind` enum reserved in C1, no UI (spec: deferred).
- Interfaces: `pickWelcomeWaver`/`sendWelcomeWave` (B1) consumed only by auth hook; `dueLifecycleKey` (B2) self-contained; `Boost`, `activeBoostIds`, `recordBoostImpressions` (C1) consumed by C2; `UNLOCKS` keys `extra_matches`/`who_waved`/`wave` (C3) consumed by C5/C7 `UnlockCta(featureKey)`; `revealed`/`maskedCount` (C4) consumed by C7; `VipPlan.visible` (A1) consumed by C7.
- Review Focus pins: #1 → B1, #2 → B2, #3 → C1, #4 → B3, #5 → C3.
