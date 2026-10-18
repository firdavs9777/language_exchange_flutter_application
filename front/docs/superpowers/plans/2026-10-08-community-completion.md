# Community Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Community search finds everyone, "load more" follows the server's real page count, and For You match reasons show in the reader's language.

**Architecture:** Two backend changes, each a separate merge:
- a pure `lib/defaultLanguageMatch.js`, consulted by `buildUsersQuery`;
- a pure `lib/matchReasons.js`, used by `getRecommendations`.

Two web changes:
- the `hasMore` rule in `MainCommunity.tsx`;
- a pure `lib/matchReasonChips.ts` feeding a widened `MemberCard.reasons` prop.

All backend changes are additive. The single behaviour change, search-everyone, sits behind `COMMUNITY_SEARCH_EVERYONE`.

**Tech Stack:**
- Backend: Node/Express/Mongoose, `node:test` + mongodb-memory-server. Must be run with Node 24: `~/.nvm/versions/node/v24.18.0/bin/node`.
- Web: React 18 + TypeScript (CRA), RTK Query, Jest + Testing Library, i18next with 18 locale JSONs.

**Spec:** `docs/superpowers/specs/2026-10-08-community-completion-design.md`

## Global Constraints

- Repos:
  - backend `/Users/davis/Desktop/Personal/language_exchange_backend_application`;
  - web `/Users/davis/Desktop/Personal/language_exchange_web_front`.
- Backend serves the production app:
  - **additive only** — no field renamed or removed, no response shape changed;
  - a request without `search` must produce exactly today's query.
- Kill switch: `process.env.COMMUNITY_SEARCH_EVERYONE`. `'false'` disables search-everyone. It is read **per request**, never at module load.
- `matchReasons` strings stay byte-identical: `Speaks <native>, learning <learning>` / `Native <native> speaker` / `Online now` / `Active today` / `Same country`.
- No data migrations, no new indexes.
- One backend merge per backend task (Task 1, Task 2). Merge with `git merge --no-ff`. **Never** add a `Co-Authored-By` trailer.
- Before every backend push, both must succeed:
  - `PATH=~/.nvm/versions/node/v24.18.0/bin:$PATH npm test` — only `authSecretRotation` may fail;
  - `PATH=~/.nvm/versions/node/v20.20.2/bin:$PATH npx -y npm@9.2.0 ci --omit=dev --dry-run --ignore-scripts`.
- After every backend push:
  - `gh run watch` shows the deploy succeeded, with `npm ci succeeded` and PM2 `online` in the log;
  - `curl -s -o /dev/null -w "%{http_code}" https://api.banatalk.com/api/v1/auth/users/6a7eb3d492fdab67baeed15f/public` returns `200` within a minute.
- Web checks:
  - test: `CI=true npx react-scripts test --watchAll=false`;
  - type-check: `npx react-scripts build`.
- Pushing web `main` deploys automatically.
- New web strings go in all 18 locale files under `src/utils/locales/`. `communityMain` is parity-guarded by `localeParity.test.ts`.

## Review Focus

1. **A viewer with no languages set searches.** No default match is possible, so the query must keep today's behaviour and no exception may be thrown. *Pinned in Task 1:* "viewer with no languages: search returns today's result".
2. **A name search that also has an explicit country or age filter.** Those filters must still narrow the result. *Pinned in Task 1:* "search-everyone keeps non-language filters".
3. **`search` sent as whitespace only (`"   "`).** This is not a search; the language match must stay. *Pinned in Task 1:* "whitespace search is not a search".
4. **A recommendation whose `native_language` is empty or unrecognised.** `matchReasonCodes` must not throw, and the strings must equal the legacy output. *Pinned in Task 2:* the randomized legacy-equivalence test includes empty and unrecognised languages.
5. **A reason code the web does not know**, from a newer server. The chip must fall back to the English string at the same index, not render a raw key or nothing. *Pinned in Task 4:* "unknown code falls back to the English string".

---

### Task 1: Backend — search finds everyone (behind `COMMUNITY_SEARCH_EVERYONE`)

**Files:**
- Create: `lib/defaultLanguageMatch.js`
- Modify: `controllers/users.js` — the `require` block at the top, and the language section of `buildUsersQuery` (~lines 140-180, starting at `const { nativeLanguage, learningLanguage, matchLanguage } = req.query;`)
- Test: `test/defaultLanguageMatch.test.js` (unit), `test/communitySearchEveryone.test.js` (integration)

**Interfaces:**
- Produces: `isDefaultLanguageMatch(query: object, viewer: {native_language?: string, language_to_learn?: string}) => boolean`, `searchEveryoneEnabled() => boolean` (both from `lib/defaultLanguageMatch.js`).
- Consumes: `matchKey(value) => string|null` from `lib/matchLanguage.js`, which already exists.

- [ ] **Step 1: Branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull --ff-only && git checkout -b feat/community-search-everyone
```

- [ ] **Step 2: Write the failing unit test** — `test/defaultLanguageMatch.test.js`

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { isDefaultLanguageMatch, searchEveryoneEnabled } = require('../lib/defaultLanguageMatch');

const viewer = { native_language: 'English', language_to_learn: 'Korean' };
const q = (over) => ({ matchLanguage: 'true', ...over });

test('exactly the default params count as the default', () => {
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'English', learningLanguage: 'Korean' }), viewer), true);
});

test('spelling variants of the same language still count (matchKey)', () => {
  const zh = { native_language: 'Chinese (Simplified)', language_to_learn: 'English' };
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'Chinese (Traditional)', learningLanguage: 'English' }), zh), true);
});

test('one swapped param alone is an explicit filter, even when it equals my own language', () => {
  // "Native speakers of Korean" from a Korean learner: learningLanguage=Korean only.
  assert.equal(isDefaultLanguageMatch(q({ learningLanguage: 'Korean' }), viewer), false);
  // "Partner learning English" from a native English speaker: nativeLanguage=English only.
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'English' }), viewer), false);
});

test('a param for a side the viewer has not set is explicit', () => {
  const onlyNative = { native_language: 'English', language_to_learn: '' };
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'English' }), onlyNative), true);
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'English', learningLanguage: 'Korean' }), onlyNative), false);
});

test('whitespace-only languages count as unset, on either side', () => {
  const blank = { native_language: '   ', language_to_learn: 'Korean' };
  assert.equal(isDefaultLanguageMatch(q({ learningLanguage: 'Korean' }), blank), true);
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: '  ', learningLanguage: 'Korean' }), blank), true);
});

test('two different unrecognised languages are not equal; the same one is', () => {
  const rare = { native_language: 'Dari', language_to_learn: 'Hawaiian' };
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'Klingon', learningLanguage: 'Hawaiian' }), rare), false);
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: ' dari ', learningLanguage: 'Hawaiian' }), rare), true);
});

test('a recognised and an unrecognised language are not equal', () => {
  const rare = { native_language: 'Dari', language_to_learn: 'Korean' };
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'Persian', learningLanguage: 'Korean' }), rare), false);
});

test('without matchLanguage, or without a viewer, nothing is the default', () => {
  assert.equal(isDefaultLanguageMatch({ nativeLanguage: 'English', learningLanguage: 'Korean' }, viewer), false);
  assert.equal(isDefaultLanguageMatch(q({ nativeLanguage: 'English', learningLanguage: 'Korean' }), null), false);
  assert.equal(isDefaultLanguageMatch(q({}), viewer), false);
});

test('the switch is read on every call', () => {
  const before = process.env.COMMUNITY_SEARCH_EVERYONE;
  try {
    delete process.env.COMMUNITY_SEARCH_EVERYONE;
    assert.equal(searchEveryoneEnabled(), true);
    process.env.COMMUNITY_SEARCH_EVERYONE = 'false';
    assert.equal(searchEveryoneEnabled(), false);
    process.env.COMMUNITY_SEARCH_EVERYONE = 'true';
    assert.equal(searchEveryoneEnabled(), true);
  } finally {
    if (before === undefined) delete process.env.COMMUNITY_SEARCH_EVERYONE;
    else process.env.COMMUNITY_SEARCH_EVERYONE = before;
  }
});
```

- [ ] **Step 3: Run it — expect FAIL** (`Cannot find module '../lib/defaultLanguageMatch'`)

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/defaultLanguageMatch.test.js`

- [ ] **Step 4: Implement** — `lib/defaultLanguageMatch.js`

```js
'use strict';

/**
 * Whether a community-list request's language params are the DEFAULT exchange
 * match -- the viewer's own languages, filled in by the client -- rather than a
 * language filter the member chose.
 *
 * Both clients send the default as matchLanguage=true plus BOTH of the viewer's
 * languages (whichever are set), and a single explicit filter as
 * matchLanguage=true plus ONE swapped param. So a param must be present exactly
 * when the viewer has that language set, and equal it when present. "Absent or
 * equal" would mistake "native speakers of Korean" from a Korean learner
 * (learningLanguage=Korean alone) for the default.
 *
 * Used by buildUsersQuery to let a plain name search ignore the default match
 * (spec 2026-10-08-community-completion-design.md section 1).
 */
const { matchKey } = require('./matchLanguage');

/** Set = a non-empty string after trimming, the reading `if (param)` gives. */
const isSet = (value) => typeof value === 'string' && value.trim().length > 0;

/**
 * Same language: the same non-null matchKey. matchKey is null for values it
 * does not recognise (ASL, Hawaiian, Dari are real production values), and two
 * nulls are not a match -- those fall back to a trimmed, case-insensitive
 * comparison, the fallback equivalentValues uses.
 */
const sameLanguage = (a, b) => {
  const ka = matchKey(a);
  const kb = matchKey(b);
  if (ka !== null && kb !== null) return ka === kb;
  if (ka !== null || kb !== null) return false;
  return a.trim().toLowerCase() === b.trim().toLowerCase();
};

/** One side: present iff the viewer has it set, and equal when present. */
const sideIsDefault = (param, own) => {
  if (!isSet(own)) return !isSet(param);
  return isSet(param) && sameLanguage(param, own);
};

const isDefaultLanguageMatch = (query, viewer) => {
  if (!viewer || !query || query.matchLanguage !== 'true') return false;
  if (!isSet(query.nativeLanguage) && !isSet(query.learningLanguage)) return false;
  return sideIsDefault(query.nativeLanguage, viewer.native_language)
    && sideIsDefault(query.learningLanguage, viewer.language_to_learn);
};

/** Kill switch, read per request so a restart -- not a deploy -- turns it off. */
const searchEveryoneEnabled = () => process.env.COMMUNITY_SEARCH_EVERYONE !== 'false';

module.exports = { isDefaultLanguageMatch, searchEveryoneEnabled };
```

- [ ] **Step 5: Run it — expect PASS**

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/defaultLanguageMatch.test.js`

- [ ] **Step 6: Write the failing integration test** — `test/communitySearchEveryone.test.js`

```js
'use strict';

/**
 * GET /auth/users -- a plain name search finds everyone, not only the people
 * inside the viewer's default language match. Explicit filters still apply.
 * Spec: docs/superpowers/specs/2026-10-08-community-completion-design.md (web repo), section 1.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-that-is-long-enough-to-pass';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, User, controller;

const run = (fn, req) => new Promise((resolve, reject) => {
  const res = {
    statusCode: 200,
    status(c) { this.statusCode = c; return this; },
    json(body) { resolve({ status: this.statusCode, body }); },
  };
  fn(req, res, (err) => (err ? resolve({ status: err.statusCode || 500, error: err.message }) : resolve({ status: 204 })))
    .catch(reject);
});

const realLog = console.log;
test.before(async () => {
  console.log = () => {};
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'communitySearchEveryone' });
  User = require('../models/User');
  controller = require('../controllers/users');
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); console.log = realLog; });
test.beforeEach(async () => {
  await User.deleteMany({});
  delete process.env.COMMUNITY_SEARCH_EVERYONE;
});

const makeUser = (name, extra = {}) => User.create({
  name, email: `${name.replace(/\s/g, '')}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder',
  birth_year: '1995', birth_month: '1', birth_day: '1', gender: 'other',
  native_language: 'English', language_to_learn: 'Korean',
  profileCompleted: true, ...extra,
});

const asViewer = (viewer, query) => ({
  user: { ...viewer.toObject(), id: viewer._id.toString(), _id: viewer._id },
  query: { limit: '50', excludeInteracted: 'false', ...query },
});
const names = async (viewer, query) => {
  const out = await run(controller.getUsers, asViewer(viewer, query));
  assert.equal(out.status, 200, out.error);
  return out.body.data.map((u) => u.name).sort();
};
// What both clients send by default: my own two languages.
const DEFAULT = { matchLanguage: 'true', nativeLanguage: 'English', learningLanguage: 'Korean' };

const seed = async () => {
  const viewer = await makeUser('Viewer');
  await makeUser('Kim Korean', { native_language: 'Korean', language_to_learn: 'English', location: { type: 'Point', coordinates: [127, 37], country: 'South Korea' } });
  await makeUser('Kim French', { native_language: 'French', language_to_learn: 'Spanish', location: { type: 'Point', coordinates: [2, 48], country: 'France' } });
  await makeUser('Lee Korean', { native_language: 'Korean', language_to_learn: 'English' });
  return viewer;
};

test('a name search with the default match finds people outside my languages', async () => {
  const viewer = await seed();
  assert.deepEqual(await names(viewer, { ...DEFAULT, search: 'Kim' }), ['Kim French', 'Kim Korean']);
});

test('no search, no change: the default match still narrows', async () => {
  const viewer = await seed();
  assert.deepEqual(await names(viewer, DEFAULT), ['Kim Korean', 'Lee Korean']);
});

test('a single explicit filter equal to my learning language still applies', async () => {
  const viewer = await seed();
  // "Native speakers of Korean" from a Korean learner.
  assert.deepEqual(await names(viewer, { matchLanguage: 'true', learningLanguage: 'Korean', search: 'Kim' }), ['Kim Korean']);
});

test('an explicit filter different from my own languages still applies', async () => {
  const viewer = await seed();
  assert.deepEqual(await names(viewer, { matchLanguage: 'true', learningLanguage: 'French', search: 'Kim' }), ['Kim French']);
});

test('search-everyone keeps non-language filters', async () => {
  const viewer = await seed();
  assert.deepEqual(await names(viewer, { ...DEFAULT, search: 'Kim', country: 'France' }), ['Kim French']);
});

test('reciprocal=true survives a search', async () => {
  const viewer = await seed();
  assert.deepEqual(await names(viewer, { ...DEFAULT, reciprocal: 'true', search: 'Kim' }), ['Kim Korean']);
});

test('whitespace search is not a search', async () => {
  const viewer = await seed();
  assert.deepEqual(await names(viewer, { ...DEFAULT, search: '   ' }), ['Kim Korean', 'Lee Korean']);
});

test('@username search is unchanged', async () => {
  const viewer = await seed();
  const kim = await User.findOne({ name: 'Kim French' });
  await User.updateOne({ _id: kim._id }, { $set: { username: 'kimfrench' } });
  assert.deepEqual(await names(viewer, { ...DEFAULT, search: '@kimfrench' }), ['Kim French']);
});

test('viewer with no languages: search returns today\'s result', async () => {
  await seed();
  const blank = await makeUser('Blank', { native_language: '', language_to_learn: '' });
  assert.deepEqual(await names(blank, { search: 'Kim' }), ['Kim French', 'Kim Korean']);
});

test('the kill switch restores today\'s narrowing, read per request', async () => {
  const viewer = await seed();
  process.env.COMMUNITY_SEARCH_EVERYONE = 'false';
  assert.deepEqual(await names(viewer, { ...DEFAULT, search: 'Kim' }), ['Kim Korean']);
  process.env.COMMUNITY_SEARCH_EVERYONE = 'true';
  assert.deepEqual(await names(viewer, { ...DEFAULT, search: 'Kim' }), ['Kim French', 'Kim Korean']);
});

test('the count agrees with the list', async () => {
  const viewer = await seed();
  const out = await run(controller.getUsersCount, asViewer(viewer, { ...DEFAULT, search: 'Kim' }));
  assert.equal(out.body.data.count, 2);
});
```

- [ ] **Step 7: Run it — expect FAIL** on the first test, which returns `['Kim Korean']`, and on the kill-switch test.

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/communitySearchEveryone.test.js`

- [ ] **Step 8: Wire it into `buildUsersQuery`**

1. Add the import next to the existing `require('../lib/countryNames')` line at the top of `controllers/users.js`:

   ```js
   const { isDefaultLanguageMatch, searchEveryoneEnabled } = require('../lib/defaultLanguageMatch');
   ```

2. Change the language section. Replace this line:

   ```js
     if (matchLanguage === 'true' && (nativeLanguage || learningLanguage)) {
   ```

   with:

   ```js
     // A plain name search ignores the DEFAULT exchange match, so you can find a
     // person by name whatever they speak. A language filter the member chose
     // still applies (isDefaultLanguageMatch tells the two apart), and so does
     // every other filter below. Kill switch: COMMUNITY_SEARCH_EVERYONE=false.
     const searchTerm = typeof req.query.search === 'string' ? req.query.search.trim() : '';
     const searchesEveryone = Boolean(searchTerm)
       && !searchTerm.startsWith('@')
       && Boolean(req.user)
       && searchEveryoneEnabled()
       && isDefaultLanguageMatch(req.query, req.user);

     if (searchesEveryone) {
       // No language constraint for this request.
     } else if (matchLanguage === 'true' && (nativeLanguage || learningLanguage)) {
   ```

   The existing `} else {` direct-filtering branch after it is unchanged. It now hangs off the `else if`.

- [ ] **Step 9: Run both test files — expect PASS**

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/defaultLanguageMatch.test.js test/communitySearchEveryone.test.js`

- [ ] **Step 10: Full suite + npm 9 install check** (Global Constraints). The only allowed failure is `authSecretRotation`.

```bash
PATH=~/.nvm/versions/node/v24.18.0/bin:$PATH npm test 2>&1 | sed -n '/✖ failing tests:/,$p' | grep -E "^test at"
PATH=~/.nvm/versions/node/v20.20.2/bin:$PATH npx -y npm@9.2.0 ci --omit=dev --dry-run --ignore-scripts >/dev/null && echo NPM9_OK
```

- [ ] **Step 11: Commit, merge, push, verify the deploy**

```bash
git add lib/defaultLanguageMatch.js controllers/users.js test/defaultLanguageMatch.test.js test/communitySearchEveryone.test.js
git commit -m "feat(users): a name search finds everyone, not only my language matches

A plain search was ANDed with the default exchange match, so typing a name
only found the person if they sat inside the viewer's language pairing. It now
ignores the DEFAULT match (lib/defaultLanguageMatch.js tells it apart from a
filter the member chose: each param present iff the viewer has that language,
and equal). Explicit language filters, reciprocal, country, age and the rest
still apply; @username search is unchanged.

Behind COMMUNITY_SEARCH_EVERYONE (default on; 'false' restores the old
narrowing after a restart), read per request."
git checkout main && git merge --no-ff feat/community-search-everyone -m "Merge feat/community-search-everyone: search finds everyone" && git branch -d feat/community-search-everyone
git fetch && git log --oneline main..origin/main   # must print nothing; if not, merge origin/main and re-run Step 10
git push origin main
gh run watch "$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://api.banatalk.com/api/v1/auth/users/6a7eb3d492fdab67baeed15f/public   # expect 200
```

---

### Task 2: Backend — match reasons as codes, strings unchanged

**Files:**
- Create: `lib/matchReasons.js`
- Modify: `controllers/matching.js`:
  - the `require` block;
  - the `enhancedRecommendations` map in `getRecommendations` (~line 230-238);
  - delete `function getMatchReasons` (~line 680-712), whose only caller is that map.
- Test: `test/matchReasons.test.js` (unit); append to `test/matchingRecommendations.test.js` (integration)

**Interfaces:**
- Produces:
  - `matchReasonCodes(currentUser, matchedUser, now = Date.now()) => Array<{code: 'perfect_pair', native, learning} | {code: 'native_speaker', native} | {code: 'online_now'} | {code: 'active_today'} | {code: 'same_country'}>`
  - `renderMatchReasons(codes) => string[]`
- Consumes: `matchKey`, `isPerfectPair` from `lib/matchLanguage.js`, which already exist.
- Response: each `/matching/recommendations` item gains `matchReasonCodes`. `matchReasons` is unchanged.

- [ ] **Step 1: Branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull --ff-only && git checkout -b feat/match-reason-codes
```

- [ ] **Step 2: Write the failing unit test** — `test/matchReasons.test.js`

The legacy function is copied in verbatim, so "byte-identical" is checked against the real old behaviour, not against a re-statement of it.

```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { matchKey, isPerfectPair } = require('../lib/matchLanguage');
const { matchReasonCodes, renderMatchReasons } = require('../lib/matchReasons');

// VERBATIM copy of controllers/matching.js getMatchReasons as of 2026-10-08,
// before it was split. The reference for byte-identical output.
function legacyGetMatchReasons(currentUser, matchedUser) {
  const reasons = [];
  const myLearning = matchKey(currentUser.language_to_learn);
  const theirNative = matchKey(matchedUser.native_language);
  const theirSpeaksWhatIWant = myLearning !== null && theirNative === myLearning;
  if (isPerfectPair(currentUser, matchedUser)) {
    reasons.push(`Speaks ${matchedUser.native_language}, learning ${matchedUser.language_to_learn}`);
  } else if (theirSpeaksWhatIWant) {
    reasons.push(`Native ${matchedUser.native_language} speaker`);
  }
  if (matchedUser.lastActive >= new Date(Date.now() - 5 * 60 * 1000)) {
    reasons.push('Online now');
  } else if (matchedUser.lastActive >= new Date(Date.now() - 24 * 60 * 60 * 1000)) {
    reasons.push('Active today');
  }
  if (matchedUser.location?.country === currentUser.location?.country) {
    reasons.push('Same country');
  }
  return reasons;
}

const LANGS = ['English', 'Korean', 'Chinese (Simplified)', 'Chinese (Traditional)', 'Dari', '', undefined];
const ACTIVE = [undefined, new Date(), new Date(Date.now() - 2 * 3600e3), new Date(Date.now() - 3 * 86400e3)];
const COUNTRY = [undefined, 'South Korea', 'France'];

test('strings are byte-identical to the legacy function across every combination', () => {
  let cases = 0;
  for (const vN of LANGS) for (const vL of LANGS) for (const cN of LANGS) for (const cL of LANGS)
    for (const act of ACTIVE) for (const vc of COUNTRY) for (const cc of COUNTRY) {
      const viewer = { native_language: vN, language_to_learn: vL, location: vc ? { country: vc } : undefined };
      const cand = { native_language: cN, language_to_learn: cL, lastActive: act, location: cc ? { country: cc } : undefined };
      assert.deepEqual(renderMatchReasons(matchReasonCodes(viewer, cand)), legacyGetMatchReasons(viewer, cand));
      cases += 1;
    }
  assert.ok(cases > 10000);
});

test('codes carry their parameters', () => {
  const viewer = { native_language: 'English', language_to_learn: 'Korean' };
  const pair = { native_language: 'Korean', language_to_learn: 'English', lastActive: new Date() };
  assert.deepEqual(matchReasonCodes(viewer, pair), [
    { code: 'perfect_pair', native: 'Korean', learning: 'English' },
    { code: 'online_now' },
    { code: 'same_country' }, // both locations undefined -- the legacy quirk, kept
  ]);
  const speaker = { native_language: 'Korean', language_to_learn: 'Japanese', lastActive: new Date(Date.now() - 3600e3), location: { country: 'X' } };
  assert.deepEqual(matchReasonCodes(viewer, speaker), [
    { code: 'native_speaker', native: 'Korean' },
    { code: 'active_today' },
  ]);
});

test('renderMatchReasons ignores codes it does not know', () => {
  assert.deepEqual(renderMatchReasons([{ code: 'online_now' }, { code: 'from_the_future' }]), ['Online now']);
});
```

- [ ] **Step 3: Run it — expect FAIL** (`Cannot find module '../lib/matchReasons'`)

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/matchReasons.test.js`

- [ ] **Step 4: Implement** — `lib/matchReasons.js`

```js
'use strict';

/**
 * Why a recommended member is a match, as CODES -- so a client can say it in
 * the reader's language -- plus the English rendering shipped app builds read.
 *
 * The conditions are the ones controllers/matching.js getMatchReasons used,
 * kept exactly, quirks included: `same_country` is emitted when both
 * locations' countries are undefined, because the legacy `===` was true then
 * and the English strings must stay byte-identical (test/matchReasons.test.js
 * compares against a verbatim copy of the old function).
 */
const { matchKey, isPerfectPair } = require('./matchLanguage');

const ONLINE_MS = 5 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

const matchReasonCodes = (currentUser, matchedUser, now = Date.now()) => {
  const codes = [];

  // Language exchange match, decided by the same key the score used.
  const myLearning = matchKey(currentUser.language_to_learn);
  const theirNative = matchKey(matchedUser.native_language);
  const theirSpeaksWhatIWant = myLearning !== null && theirNative === myLearning;

  if (isPerfectPair(currentUser, matchedUser)) {
    codes.push({ code: 'perfect_pair', native: matchedUser.native_language, learning: matchedUser.language_to_learn });
  } else if (theirSpeaksWhatIWant) {
    codes.push({ code: 'native_speaker', native: matchedUser.native_language });
  }

  if (matchedUser.lastActive >= new Date(now - ONLINE_MS)) {
    codes.push({ code: 'online_now' });
  } else if (matchedUser.lastActive >= new Date(now - DAY_MS)) {
    codes.push({ code: 'active_today' });
  }

  if (matchedUser.location?.country === currentUser.location?.country) {
    codes.push({ code: 'same_country' });
  }

  return codes;
};

const ENGLISH = {
  perfect_pair: (c) => `Speaks ${c.native}, learning ${c.learning}`,
  native_speaker: (c) => `Native ${c.native} speaker`,
  online_now: () => 'Online now',
  active_today: () => 'Active today',
  same_country: () => 'Same country',
};

/** The English `matchReasons` shipped app builds render. Unknown codes are skipped. */
const renderMatchReasons = (codes) =>
  codes.filter((c) => ENGLISH[c.code]).map((c) => ENGLISH[c.code](c));

module.exports = { matchReasonCodes, renderMatchReasons };
```

- [ ] **Step 5: Run it — expect PASS**

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/matchReasons.test.js`

- [ ] **Step 6: Append the failing integration test** to `test/matchingRecommendations.test.js`, at the end of the file. It reuses the file's own `call` and `makeUser`:

```js
// ------------------------------------------------------- reason codes (2026-10-08)

test('each recommendation carries matchReasonCodes alongside unchanged matchReasons', async () => {
  const viewer = await makeUser({ native_language: 'English', language_to_learn: 'Korean' });
  await makeUser({ name: 'Partner', native_language: 'Korean', language_to_learn: 'English', lastActive: new Date() });

  const { error, payload } = await call({}, viewer);
  assert.equal(error, null);
  const item = payload.data.find((u) => u.name === 'Partner');
  assert.ok(item, 'the partner is recommended');
  assert.ok(Array.isArray(item.matchReasonCodes));
  assert.equal(item.matchReasonCodes.length, item.matchReasons.length);
  assert.deepEqual(item.matchReasonCodes[0], { code: 'perfect_pair', native: 'Korean', learning: 'English' });
  assert.equal(item.matchReasons[0], 'Speaks Korean, learning English');
});
```

- [ ] **Step 7: Run it — expect FAIL** (`item.matchReasonCodes` is undefined)

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/matchingRecommendations.test.js`

- [ ] **Step 8: Wire it into `controllers/matching.js`**

1. Add to the `require` block:

   ```js
   const { matchReasonCodes, renderMatchReasons } = require('../lib/matchReasons');
   ```

2. In `getRecommendations`, replace the `enhancedRecommendations` map:

   ```js
     const enhancedRecommendations = recommendations.map(user => ({
       ...user,
       imageUrls: (user.images || []).map(image => {
         if (image.startsWith('http://') || image.startsWith('https://')) {
           return toCdnUrl(image);
         }
         return `${req.protocol}://${req.get('host')}/uploads/${encodeURIComponent(image)}`;
       }),
       matchReasons: getMatchReasons(currentUser, user)
     }));
   ```

   with:

   ```js
     // matchReasons stays byte-identical (shipped app builds render it);
     // matchReasonCodes is additive, for clients that localise.
     const enhancedRecommendations = recommendations.map(user => {
       const codes = matchReasonCodes(currentUser, user);
       return {
         ...user,
         imageUrls: (user.images || []).map(image => {
           if (image.startsWith('http://') || image.startsWith('https://')) {
             return toCdnUrl(image);
           }
           return `${req.protocol}://${req.get('host')}/uploads/${encodeURIComponent(image)}`;
         }),
         matchReasons: renderMatchReasons(codes),
         matchReasonCodes: codes,
       };
     });
   ```

3. Delete the whole `function getMatchReasons(currentUser, matchedUser) { ... }`, including its doc comment and the long comment inside it. That reasoning now lives in `lib/matchReasons.js`.

4. Confirm nothing else calls it — this must print nothing:

   ```bash
   grep -rn "getMatchReasons" controllers lib services routes
   ```

- [ ] **Step 9: Run both test files — expect PASS**

Run: `~/.nvm/versions/node/v24.18.0/bin/node --test test/matchReasons.test.js test/matchingRecommendations.test.js`

- [ ] **Step 10: Full suite + npm 9 install check** — same commands as Task 1, Step 10.

- [ ] **Step 11: Commit, merge, push, verify the deploy**

```bash
git add lib/matchReasons.js controllers/matching.js test/matchReasons.test.js test/matchingRecommendations.test.js
git commit -m "feat(matching): match reasons as codes, English strings unchanged

/recommendations items gain matchReasonCodes -- perfect_pair (native,
learning), native_speaker (native), online_now, active_today, same_country --
so the web can say them in the reader's language. matchReasons stays
byte-identical for shipped app builds: it is now rendered FROM the codes, and
test/matchReasons.test.js compares that rendering against a verbatim copy of
the old getMatchReasons over every combination of languages, activity and
country (same_country on two undefined countries included).

Cached recommendations keep serving entries without codes until their TTL;
the web falls back to the English strings for those."
git checkout main && git merge --no-ff feat/match-reason-codes -m "Merge feat/match-reason-codes: match reasons as codes" && git branch -d feat/match-reason-codes
git fetch && git log --oneline main..origin/main   # must print nothing
git push origin main
gh run watch "$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
curl -s -o /dev/null -w "%{http_code}\n" https://api.banatalk.com/api/v1/auth/users/6a7eb3d492fdab67baeed15f/public   # expect 200
```

---

### Task 3: Web — "load more" follows the server's page count

**Files:**
- Modify: `src/components/community/MainCommunity.tsx:573` (`const hasMore = ...`)
- Test: create `src/components/community/communityPaging.test.tsx`

**Interfaces:**
- Consumes: `GET /auth/users` already returns `{ total, pages, data }`. `getCommunityMembers`' `transformResponse` spreads the response, so `communityData.pages` is available.
- Produces: none for other tasks.

- [ ] **Step 1: Branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
git checkout main && git pull --ff-only && git checkout -b feat/community-completion-web
```

- [ ] **Step 2: Write the failing test** — `src/components/community/communityPaging.test.tsx`

```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { createMemoryRouter, createRoutesFromElements, Route, RouterProvider } from "react-router-dom";
import { makeStore } from "../../store";
import MainCommunity from "./MainCommunity";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => key, i18n: { language: "en" } }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));
jest.mock("./PublicCommunities", () => ({ __esModule: true, default: () => null }));
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn(), warning: jest.fn(), show: jest.fn(), dismiss: jest.fn() },
}));

const PAGE_LIMIT = 20;
const page = Array.from({ length: PAGE_LIMIT }, (unused, i) => ({
  _id: `m${i}`, name: `Member ${i}`, native_language: "Korean", language_to_learn: "English", imageUrls: [],
}));
const originalFetch = global.fetch;
let membersBody: any;

beforeEach(() => {
  (global as any).IntersectionObserver = class { observe() {} disconnect() {} unobserve() {} };
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    const body = /\/auth\/users\?/.test(url) ? membersBody : { success: true, data: [] };
    return Promise.resolve(new Response(JSON.stringify(body), { status: 200, headers: { "content-type": "application/json" } }));
  });
});
afterEach(() => { global.fetch = originalFetch; });

function renderList() {
  const router = createMemoryRouter(
    createRoutesFromElements(<Route path="/communities" element={<MainCommunity />} />),
    { initialEntries: ["/communities"] }
  );
  return render(
    <Provider store={makeStore({ auth: { userInfo: { user: { _id: "u1", native_language: "English", language_to_learn: "Korean" }, token: "t" } } } as any)}>
      <RouterProvider router={router} />
    </Provider>
  );
}

// An exactly-full LAST page used to read as "there is more": a phantom
// "load more" and one extra request for an empty page. The server says how many
// pages there are; the list believes it.
it("stops when the server says this full page is the last", async () => {
  membersBody = { success: true, total: PAGE_LIMIT, pages: 1, data: page };
  renderList();
  await waitFor(() => expect(screen.getAllByTestId("member-card-root")).toHaveLength(PAGE_LIMIT));
  expect(screen.queryByTestId("community-sentinel")).not.toBeInTheDocument();
});

it("offers more when the server says there are more pages", async () => {
  membersBody = { success: true, total: 45, pages: 3, data: page };
  renderList();
  await waitFor(() => expect(screen.getAllByTestId("member-card-root")).toHaveLength(PAGE_LIMIT));
  expect(screen.getByTestId("community-sentinel")).toBeInTheDocument();
});

it("falls back to the full-page rule when the response carries no page count", async () => {
  membersBody = { success: true, data: page };
  renderList();
  await waitFor(() => expect(screen.getAllByTestId("member-card-root")).toHaveLength(PAGE_LIMIT));
  expect(screen.getByTestId("community-sentinel")).toBeInTheDocument();
});
```

`makeStore(preloadedState?)` (`src/store/index.ts:21`) takes the preloaded state directly; `MainCommunityTabs.test.tsx` passes its signed-in state the same way.

- [ ] **Step 3: Run it — expect FAIL** on the first test, where the sentinel is present.

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern communityPaging`

- [ ] **Step 4: Implement** — replace `MainCommunity.tsx:573`:

```tsx
  const hasMore = communityData?.data?.length === PAGE_LIMIT;
```

with:

```tsx
  // The server says how many pages there are (GET /auth/users returns `pages`).
  // Guessing from a full page showed a phantom "load more" -- and fetched an
  // empty page -- whenever the last page was exactly full. The guess remains
  // only as the fallback for a response that carries no count.
  const serverPages = (communityData as any)?.pages;
  const hasMore =
    typeof serverPages === "number"
      ? page < serverPages
      : communityData?.data?.length === PAGE_LIMIT;
```

`page` is the current page number, declared above as `const page = pager.key === filterKey ? pager.page : 1;`.

- [ ] **Step 5: Run it — expect PASS**, then run the community suites so nothing regressed

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "communityPaging|community"`

- [ ] **Step 6: Commit** (on the branch; merged in Task 4)

```bash
git add src/components/community/MainCommunity.tsx src/components/community/communityPaging.test.tsx
git commit -m "fix(community): load more follows the server's page count

hasMore was guessed from a full page, so an exactly-full last page showed a
phantom load-more and fetched an empty page. GET /auth/users returns pages;
the list now believes it, and keeps the guess only for a response without it."
```

---

### Task 4: Web — localized match-reason chips

**Files:**
- Create: `src/components/community/lib/matchReasonChips.ts`, `src/components/community/lib/matchReasonChips.test.ts`
- Modify:
  - `src/components/community/MemberCard.tsx` — the `reasons` prop type (line 35), `isLanguageReason` / `orderReasons` (lines 75-81), the reason chip render, `areMemberRowsEqual`;
  - `src/components/community/MainCommunity.tsx` — the `RecommendedMember` interface (~line 88) and the `ForYouTab` `reasons={...}` (~line 170);
  - all 18 `src/utils/locales/*.json` (`communityMain.reasons.*`).
- Test: `src/components/community/MemberCard.test.tsx` (append), `src/components/community/MainCommunityTabs.test.tsx` (append)

**Interfaces:**
- Produces:
  - `export interface ReasonChip { text: string; primary: boolean }`
  - `export interface MatchReasonCode { code: string; [param: string]: any }`
  - `export function reasonChips(codes: MatchReasonCode[] | undefined, english: string[] | undefined, t: (key: string, options?: any) => string): Array<string | ReasonChip>`
  - All of these come from `src/components/community/lib/matchReasonChips.ts`.
- `MemberCard`'s `reasons?: Array<string | ReasonChip>`.

- [ ] **Step 1: Write the failing helper test** — `src/components/community/lib/matchReasonChips.test.ts`

```ts
import { reasonChips } from "./matchReasonChips";

// `t` that proves which key and values were asked for.
const t = (key: string, options?: any) =>
  options ? `${key}|${JSON.stringify(options)}` : key;

describe("reasonChips", () => {
  it("localises each code, language reasons primary", () => {
    expect(
      reasonChips(
        [{ code: "perfect_pair", native: "Korean", learning: "English" }, { code: "online_now" }],
        ["Speaks Korean, learning English", "Online now"],
        t
      )
    ).toEqual([
      { text: 'communityMain.reasons.perfect_pair|{"native":"Korean","learning":"English"}', primary: true },
      { text: "communityMain.reasons.online_now", primary: false },
    ]);
  });

  it("marks native_speaker primary too", () => {
    expect(reasonChips([{ code: "native_speaker", native: "Korean" }], ["Native Korean speaker"], t)[0]).toEqual({
      text: 'communityMain.reasons.native_speaker|{"native":"Korean"}',
      primary: true,
    });
  });

  it("unknown code falls back to the English string at the same index", () => {
    expect(
      reasonChips([{ code: "from_the_future" }, { code: "online_now" }], ["Something new", "Online now"], t)
    ).toEqual(["Something new", { text: "communityMain.reasons.online_now", primary: false }]);
  });

  it("an unknown code with no English counterpart is dropped, not shown as a raw key", () => {
    expect(reasonChips([{ code: "from_the_future" }], [], t)).toEqual([]);
  });

  it("no codes (older server or cached response): the English strings as they are", () => {
    expect(reasonChips(undefined, ["Native Korean speaker", "Online now"], t)).toEqual([
      "Native Korean speaker",
      "Online now",
    ]);
    expect(reasonChips(undefined, undefined, t)).toEqual([]);
  });

  it("a key the locale lacks falls back to the English string", () => {
    const empty = () => "";
    expect(reasonChips([{ code: "online_now" }], ["Online now"], empty)).toEqual([
      { text: "Online now", primary: false },
    ]);
  });
});
```

- [ ] **Step 2: Run it — expect FAIL** (module not found)

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern matchReasonChips`

- [ ] **Step 3: Implement** — `src/components/community/lib/matchReasonChips.ts`

```ts
/**
 * The For You card's "why this match" chips, in the reader's language.
 *
 * GET /matching/recommendations sends English `matchReasons` (shipped app
 * builds read them) and, since backend matchReasonCodes landed, the same
 * reasons as codes. The codes become localised chips; anything the web does
 * not understand -- a code from a newer server, a cached response without
 * codes, a locale missing the key -- falls back to the English string at the
 * same position rather than to a raw key or nothing.
 */

export interface ReasonChip {
  text: string;
  /** The language match: drawn first and in the brand colour. */
  primary: boolean;
}

export interface MatchReasonCode {
  code: string;
  [param: string]: any;
}

const KNOWN = ["perfect_pair", "native_speaker", "online_now", "active_today", "same_country"];
const PRIMARY = ["perfect_pair", "native_speaker"];

export function reasonChips(
  codes: MatchReasonCode[] | undefined,
  english: string[] | undefined,
  t: (key: string, options?: any) => string
): Array<string | ReasonChip> {
  const fallback = Array.isArray(english) ? english.filter(Boolean) : [];
  if (!Array.isArray(codes)) return fallback;

  const chips: Array<string | ReasonChip> = [];
  codes.forEach((entry, index) => {
    if (!entry || KNOWN.indexOf(entry.code) === -1) {
      if (fallback[index]) chips.push(fallback[index]);
      return;
    }
    const { code, ...params } = entry;
    const key = `communityMain.reasons.${code}`;
    const translated = Object.keys(params).length ? t(key, params) : t(key);
    chips.push({
      text: translated || fallback[index] || "",
      primary: PRIMARY.indexOf(code) > -1,
    });
  });
  return chips.filter((chip) => (typeof chip === "string" ? chip : chip.text));
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern matchReasonChips`

- [ ] **Step 5: Write the failing MemberCard tests** — append to `src/components/community/MemberCard.test.tsx`:

```tsx
// Reason chips may arrive as { text, primary } entries -- localised text the
// English /^Speaks |^Native / test cannot read -- and the card must take the
// flag as given.
describe("localised reason chips", () => {
  it("draws a primary entry in the primary style, first, whatever its language", () => {
    render(
      <MemberCard
        user={baseUser}
        reasons={[
          { text: "지금 온라인", primary: false },
          { text: "한국어 원어민", primary: true },
        ]}
        onOpen={jest.fn()}
        onWave={jest.fn()}
      />
    );
    const chips = screen.getByTestId("member-card-reasons").children;
    expect(chips[0]).toHaveTextContent("한국어 원어민");
    expect(chips[0]).toHaveAttribute("data-testid", "member-card-reason-primary");
    expect(chips[1]).toHaveAttribute("data-testid", "member-card-reason-secondary");
  });

  it("still reads plain English strings the old way", () => {
    render(<MemberCard user={baseUser} reasons={["Online now", "Native Korean speaker"]} onOpen={jest.fn()} onWave={jest.fn()} />);
    const chips = screen.getByTestId("member-card-reasons").children;
    expect(chips[0]).toHaveTextContent("Native Korean speaker");
    expect(chips[0]).toHaveAttribute("data-testid", "member-card-reason-primary");
  });

  it("redraws when an entry's text changes, even if the user object is reused", () => {
    const { rerender } = render(
      <MemberCard user={baseUser} reasons={[{ text: "A", primary: false }]} onOpen={jest.fn()} onWave={jest.fn()} />
    );
    rerender(<MemberCard user={baseUser} reasons={[{ text: "B", primary: false }]} onOpen={jest.fn()} onWave={jest.fn()} />);
    expect(screen.getByTestId("member-card-reasons")).toHaveTextContent("B");
  });
});
```

- [ ] **Step 6: Run it — expect FAIL**. These are TypeScript/type errors, or entries rendered as `[object Object]`.

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "community/MemberCard"`

- [ ] **Step 7: Implement in `MemberCard.tsx`**

1. Import the type at the top:

   ```tsx
   import type { ReasonChip } from "./lib/matchReasonChips";
   ```

2. Widen the prop (line 35):

   ```tsx
     reasons?: Array<string | ReasonChip>;
   ```

3. Replace `isLanguageReason` / `orderReasons` (lines 75-81) with:

   ```tsx
   const isLanguageReason = (reason: string): boolean =>
     /^Speaks |^Native /.test(reason);

   /**
    * Every reason as an entry, language match first. A plain string is English
    * from the server and is classified by its wording; an entry already knows
    * (localised text cannot be read by an English pattern).
    */
   const orderReasons = (reasons: Array<string | ReasonChip>): ReasonChip[] => {
     const chips = reasons
       .map((reason) =>
         typeof reason === "string" ? { text: reason, primary: isLanguageReason(reason) } : reason
       )
       .filter((chip) => chip && chip.text);
     return [...chips.filter((chip) => chip.primary), ...chips.filter((chip) => !chip.primary)];
   };
   ```

4. In the chip render, the `orderedReasons.map((reason) => { const primary = isLanguageReason(reason); ...` block, change it to read from the entry. Keep the existing class strings exactly:

   ```tsx
             {orderedReasons.map((reason) => {
               const primary = reason.primary;
               return (
                 <span
                   key={reason.text}
                   data-testid={primary ? "member-card-reason-primary" : "member-card-reason-secondary"}
                   className={/* unchanged: the existing primary/secondary className expression */}
                 >
                   {reason.text}
                 </span>
               );
             })}
   ```

5. In `areMemberRowsEqual`, replace the reasons comparison:

   ```tsx
     const ra = prev.reasons || [];
     const rb = next.reasons || [];
     if (ra.length !== rb.length) return false;
     if (ra.some((reason, index) => reason !== rb[index])) return false;
   ```

   with:

   ```tsx
     // Entries are compared by what they draw, not by identity: a fresh array of
     // equal chips must not re-render, a changed text or flag must.
     const ra = orderReasons(prev.reasons || []);
     const rb = orderReasons(next.reasons || []);
     if (ra.length !== rb.length) return false;
     if (ra.some((chip, index) => chip.text !== rb[index].text || chip.primary !== rb[index].primary)) {
       return false;
     }
   ```

   This stays **before** the `a === b` fast path, exactly where the old comparison was.

- [ ] **Step 8: Run MemberCard tests — expect PASS**

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern "community/MemberCard"`

- [ ] **Step 9: Write the failing For You test** — append inside `describe(...)` for the For You tab in `src/components/community/MainCommunityTabs.test.tsx`. If there is no such `describe`, add it at the end of the file, using the file's existing `recommendations`, `member` and `renderList`:

```tsx
describe("For You reason chips", () => {
  it("renders the localised key when the server sends codes", async () => {
    recommendations = [
      {
        ...member(1),
        matchReasons: ["Native Korean speaker"],
        matchReasonCodes: [{ code: "native_speaker", native: "Korean" }],
      },
    ];
    renderList(["/communities?tab=foryou"]);
    // This file's `t` mock returns "<key> <values...>".
    expect(await screen.findByText("communityMain.reasons.native_speaker Korean")).toBeInTheDocument();
  });

  it("falls back to the English strings when there are no codes", async () => {
    recommendations = [{ ...member(1), matchReasons: ["Native Korean speaker"] }];
    renderList(["/communities?tab=foryou"]);
    expect(await screen.findByText("Native Korean speaker")).toBeInTheDocument();
  });
});
```

`?tab=foryou` is the value this file's existing For You test uses (`MainCommunityTabs.test.tsx:155`).

- [ ] **Step 10: Run it — expect FAIL** on the first test, which shows the English string.

Run: `CI=true npx react-scripts test --watchAll=false --testPathPattern MainCommunityTabs`

- [ ] **Step 11: Implement in `MainCommunity.tsx`**

1. Import:

   ```tsx
   import { reasonChips, MatchReasonCode } from "./lib/matchReasonChips";
   ```

2. Extend `RecommendedMember`:

   ```tsx
   interface RecommendedMember extends CommunityMemberCard {
     matchScore?: number;
     matchReasons?: string[];
     /** Same reasons as codes, for the reader's language (absent on older/cached responses). */
     matchReasonCodes?: MatchReasonCode[];
   }
   ```

3. In `ForYouTab`, replace `reasons={member.matchReasons}` with:

   ```tsx
                 reasons={reasonChips(member.matchReasonCodes, member.matchReasons, t)}
   ```

- [ ] **Step 12: Add the locale keys.** Run this script from the web repo root. It inserts `communityMain.reasons` into all 18 files:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front/src/utils/locales && python3 - <<'PY'
import json, collections
R = {
 "eng":("Speaks {{native}}, learning {{learning}}","Native {{native}} speaker","Online now","Active today","Same country"),
 "kor":("{{native}} 사용, {{learning}} 학습 중","{{native}} 원어민","지금 온라인","오늘 활동","같은 나라"),
 "zho":("说{{native}}，在学{{learning}}","{{native}}母语者","在线","今天活跃","同一国家"),
 "zh_TW":("說{{native}}，在學{{learning}}","{{native}}母語者","線上","今天活躍","同一個國家"),
 "ar":("يتحدث {{native}} ويتعلم {{learning}}","متحدث أصلي لـ {{native}}","متصل الآن","نشط اليوم","البلد نفسه"),
 "de":("Spricht {{native}}, lernt {{learning}}","{{native}}-Muttersprachler","Jetzt online","Heute aktiv","Gleiches Land"),
 "es":("Habla {{native}}, aprende {{learning}}","Hablante nativo de {{native}}","En línea","Activo hoy","Mismo país"),
 "fr":("Parle {{native}}, apprend {{learning}}","Locuteur natif de {{native}}","En ligne","Actif aujourd'hui","Même pays"),
 "hi":("{{native}} बोलते हैं, {{learning}} सीख रहे हैं","{{native}} के मूल वक्ता","अभी ऑनलाइन","आज सक्रिय","एक ही देश"),
 "id":("Berbicara {{native}}, belajar {{learning}}","Penutur asli {{native}}","Sedang online","Aktif hari ini","Negara yang sama"),
 "it":("Parla {{native}}, impara {{learning}}","Madrelingua {{native}}","Online ora","Attivo oggi","Stesso paese"),
 "ja":("{{native}}を話し、{{learning}}を学習中","{{native}}のネイティブ","オンライン","今日アクティブ","同じ国"),
 "pt":("Fala {{native}}, aprende {{learning}}","Falante nativo de {{native}}","Online agora","Ativo hoje","Mesmo país"),
 "ru":("Говорит на {{native}}, учит {{learning}}","Носитель языка: {{native}}","Сейчас в сети","Был(а) сегодня","Та же страна"),
 "th":("พูด{{native}} กำลังเรียน{{learning}}","เจ้าของภาษา{{native}}","ออนไลน์อยู่","ใช้งานวันนี้","ประเทศเดียวกัน"),
 "tl":("Nagsasalita ng {{native}}, nag-aaral ng {{learning}}","Native speaker ng {{native}}","Online ngayon","Aktibo ngayon","Parehong bansa"),
 "tr":("{{native}} konuşuyor, {{learning}} öğreniyor","Anadili {{native}}","Şu an çevrimiçi","Bugün aktif","Aynı ülke"),
 "vi":("Nói {{native}}, đang học {{learning}}","Người bản ngữ {{native}}","Đang trực tuyến","Hoạt động hôm nay","Cùng quốc gia"),
}
KEYS = ["perfect_pair","native_speaker","online_now","active_today","same_country"]
for name, vals in R.items():
    f = f"{name}.json"
    d = json.load(open(f), object_pairs_hook=collections.OrderedDict)
    d["communityMain"]["reasons"] = collections.OrderedDict(zip(KEYS, vals))
    open(f, "w").write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print("ok")
PY
```

- [ ] **Step 13: Run the community suites, locale parity, the full suite and the build — expect PASS**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_web_front
CI=true npx react-scripts test --watchAll=false --testPathPattern "matchReasonChips|community/MemberCard|MainCommunityTabs|localeParity"
CI=true npx react-scripts test --watchAll=false 2>&1 | tail -5
npx react-scripts build 2>&1 | grep -E "Failed|Compiled|rror"
```

- [ ] **Step 14: Commit, merge, push, verify the deploy**

```bash
git add src/components/community src/utils/locales
git commit -m "feat(community): For You match reasons in the reader's language

The For You chips rendered the server's English matchReasons in all 18
locales. When the server sends matchReasonCodes (backend, this release) each
becomes a localised chip; a code the web does not know, a cached response
without codes, or a locale missing the key falls back to the English string
at the same position. MemberCard.reasons accepts { text, primary } entries
because an English /^Speaks |^Native / test cannot recognise the language
chip in Korean; plain strings keep the old rule."
git checkout main && git merge --no-ff feat/community-completion-web -m "Merge feat/community-completion-web: server paging, localized match reasons" && git branch -d feat/community-completion-web
git push origin main
gh run watch "$(gh run list --workflow deploy.yml --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
```

---

## Order

Task 1 (backend), then Task 2 (backend), then Tasks 3 and 4 (web, one branch, one merge).

Task 4's chips work against the old server too — they fall back to English — so web and backend may deploy in either order. Task 2 is listed first only so the localized chips are visible as soon as the web ships.
