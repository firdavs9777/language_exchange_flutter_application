# Matching Intent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let matching rank by why someone is here — learn, meet or date — without hiding anyone from anyone.

**Architecture:** Two new pure modules (`lib/matchIntent.js`, `lib/userAge.js`) hold all the logic, mirroring how `lib/matchLanguage.js` already isolates the pairing rule so it is table-testable without a database. `controllers/matching.js` adds one weight and one pipeline stage. `controllers/users.js` strips the `date` intent for minors on write. The app collects intents on three surfaces and renders two of the three.

**Tech Stack:** Node 20 + Mongoose (backend, `node:test`), Flutter 3 + Riverpod (app, `flutter_test`).

**Spec:** `docs/superpowers/specs/2026-09-17-matching-intent-design.md`

## Global Constraints

- **A no-intent viewer's ranking must be byte-identical to today's.** 100% of the 1,813 existing users have no intent; any rule that changes their feed is a bug. (spec §2.1)
- **`intentOverlap` is exactly 10**, flat, awarded once for any overlap — never `10 × shared`. (spec §3.1)
- **`date` is stripped for under-18 users on write AND ignored on read.** Two layers, not one. (spec §4)
- **`date` is never rendered in any response body or UI.** Only `learn` and `meet` are visible. (spec §2.3)
- Intent values are exactly `'learn' | 'meet' | 'date'`, lowercase, stored as an array.
- Language weight stays 50. Nothing in this plan reweights an existing signal. (spec §9)

---

## File Structure

| File | Responsibility |
|---|---|
| `backend/lib/matchIntent.js` | **new** — normalize an intent array; score an overlap |
| `backend/lib/userAge.js` | **new** — age from birth fields; `isMinor` |
| `backend/models/User.js` | persist `intents` |
| `backend/models/MatchImpression.js` | store `intentScore`, `viewerIntents`, `shownIntents` |
| `backend/controllers/users.js` | accept `intents`; strip `date` for minors |
| `backend/controllers/matching.js` | apply the weight; record the impression |
| `app/lib/providers/provider_models/community_model.dart` | parse `intents` |
| `app/lib/pages/profile/edit_main/completion_calculator.dart` | count `intents` toward completion |
| `app/lib/pages/profile/profile_main/sections/profile_highlights_tab.dart` | list intent as a missing field |
| `app/lib/pages/profile/edit/intent_edit.dart` | **new** — the picker |
| `app/lib/pages/profile/profile_main/sections/profile_about_tab.dart` | render learn/meet chips |

---

## Task 1 — `lib/matchIntent.js`, the scoring rule as a pure function

**Files:**
- Create: `backend/lib/matchIntent.js`
- Test: `backend/test/matchIntent.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `INTENTS` (frozen array), `normalizeIntents(value) -> string[]`, `sharesIntent(a, b) -> boolean`, `intentScore(viewerIntents, shownIntents, weight) -> number`, `INTENT_OVERLAP_WEIGHT` (10).

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeIntents, sharesIntent, intentScore, INTENT_OVERLAP_WEIGHT, INTENTS,
} = require('../lib/matchIntent');

test('the three intents are exactly learn, meet, date', () => {
  assert.deepEqual([...INTENTS], ['learn', 'meet', 'date']);
});

test('normalize lowercases, trims, dedupes and drops anything unknown', () => {
  assert.deepEqual(normalizeIntents([' Learn ', 'LEARN', 'date', 'nonsense']), ['learn', 'date']);
});

test('normalize survives every shape a client can send', () => {
  for (const junk of [null, undefined, '', 'learn', 42, {}, [null, 7]]) {
    assert.ok(Array.isArray(normalizeIntents(junk)), `${JSON.stringify(junk)} did not give an array`);
  }
  // A bare string is accepted as a single value rather than split into letters.
  assert.deepEqual(normalizeIntents('learn'), ['learn']);
});

test('an empty side never shares an intent', () => {
  assert.equal(sharesIntent([], ['learn']), false);
  assert.equal(sharesIntent(['learn'], []), false);
  assert.equal(sharesIntent([], []), false);
});

test('one shared value is enough', () => {
  assert.equal(sharesIntent(['learn', 'meet'], ['meet']), true);
});

test('GLOBAL CONSTRAINT: an unset viewer scores zero against everyone', () => {
  assert.equal(intentScore([], ['learn', 'meet', 'date']), 0);
});

test('an unset candidate scores zero', () => {
  assert.equal(intentScore(['learn'], []), 0);
});

test('GLOBAL CONSTRAINT: the bonus is flat, not per shared intent', () => {
  const one = intentScore(['learn'], ['learn']);
  const three = intentScore(['learn', 'meet', 'date'], ['learn', 'meet', 'date']);
  assert.equal(one, INTENT_OVERLAP_WEIGHT);
  assert.equal(three, INTENT_OVERLAP_WEIGHT, 'ticking all three must not earn more');
});

test('no overlap scores zero', () => {
  assert.equal(intentScore(['learn'], ['date']), 0);
});

test('the weight is 10, below language (50) by design', () => {
  assert.equal(INTENT_OVERLAP_WEIGHT, 10);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/matchIntent.test.js`
Expected: FAIL — `Cannot find module '../lib/matchIntent'`

- [ ] **Step 3: Write the module**

```js
'use strict';

/**
 * Why a user is here: learn, meet or date.
 *
 * Pure and dependency-free, like lib/matchLanguage.js, so the rule that decides
 * ranking can be table-tested without a database.
 *
 * The one property everything else rests on: an empty intent list scores ZERO
 * against everyone. 100% of the existing user base has no intent set, so any
 * rule that treats "unset" as a value would change 1,813 feeds on deploy.
 */

const INTENTS = Object.freeze(['learn', 'meet', 'date']);

/** Sits below language (50) on purpose -- it breaks ties, it never overrules a pair. */
const INTENT_OVERLAP_WEIGHT = 10;

const normalizeIntents = (value) => {
  const raw = Array.isArray(value) ? value : (typeof value === 'string' ? [value] : []);
  const out = [];
  for (const entry of raw) {
    if (typeof entry !== 'string') continue;
    const key = entry.trim().toLowerCase();
    if (INTENTS.includes(key) && !out.includes(key)) out.push(key);
  }
  return out;
};

const sharesIntent = (a, b) => {
  const mine = normalizeIntents(a);
  const theirs = normalizeIntents(b);
  if (mine.length === 0 || theirs.length === 0) return false;
  return mine.some((i) => theirs.includes(i));
};

/**
 * Flat, never multiplied by the number shared: `weight * shared` would make
 * ticking all three strictly optimal and turn an honesty question into a
 * ranking lever.
 */
const intentScore = (viewerIntents, shownIntents, weight = INTENT_OVERLAP_WEIGHT) =>
  (sharesIntent(viewerIntents, shownIntents) ? weight : 0);

module.exports = { INTENTS, INTENT_OVERLAP_WEIGHT, normalizeIntents, sharesIntent, intentScore };
```

- [ ] **Step 4: Run the tests and watch them pass**

Run: `cd backend && node --test --test-force-exit test/matchIntent.test.js`
Expected: PASS, 10/10

- [ ] **Step 5: Commit**

```bash
git add backend/lib/matchIntent.js backend/test/matchIntent.test.js
git commit -m "feat(matching): the intent overlap rule, as one pure function"
```

---

## Task 2 — `lib/userAge.js`, so `date` can be withheld from minors

**Files:**
- Create: `backend/lib/userAge.js`
- Test: `backend/test/userAge.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `ageFrom({ birth_year, birth_month, birth_day }, now = new Date()) -> number | null`, `isMinor(user, now) -> boolean`.

`isMinor` returns **false when the age is unknown** — an unknown birthdate must not silently strip a legitimate adult's `date` intent. The 18+ gate is enforced at registration; this is a second layer, not the only one.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { ageFrom, isMinor } = require('../lib/userAge');

const at = (iso) => new Date(iso);

test('a plain birthday computes the age', () => {
  assert.equal(ageFrom({ birth_year: '2000', birth_month: '1', birth_day: '15' }, at('2026-09-17')), 26);
});

test('the birthday has not happened yet this year', () => {
  assert.equal(ageFrom({ birth_year: '2000', birth_month: '12', birth_day: '31' }, at('2026-09-17')), 25);
});

test('the birthday is today -- they are the older age', () => {
  assert.equal(ageFrom({ birth_year: '2008', birth_month: '9', birth_day: '17' }, at('2026-09-17')), 18);
});

test('the day before an 18th birthday is still 17', () => {
  assert.equal(ageFrom({ birth_year: '2008', birth_month: '9', birth_day: '18' }, at('2026-09-17')), 17);
});

test('fields are accepted as numbers as well as strings', () => {
  assert.equal(ageFrom({ birth_year: 2000, birth_month: 1, birth_day: 15 }, at('2026-09-17')), 26);
});

test('an unknown or malformed birthdate gives null, never a guess', () => {
  for (const bad of [null, undefined, {}, { birth_year: '' }, { birth_year: 'abcd', birth_month: '1', birth_day: '1' }]) {
    assert.equal(ageFrom(bad, at('2026-09-17')), null);
  }
});

test('under 18 is a minor', () => {
  assert.equal(isMinor({ birth_year: '2010', birth_month: '1', birth_day: '1' }, at('2026-09-17')), true);
});

test('exactly 18 is not a minor', () => {
  assert.equal(isMinor({ birth_year: '2008', birth_month: '9', birth_day: '17' }, at('2026-09-17')), false);
});

test('an unknown age is NOT treated as a minor', () => {
  // Stripping a legitimate adult's intent on missing data would be a silent
  // data-loss bug; the 18+ gate lives at registration.
  assert.equal(isMinor({}, at('2026-09-17')), false);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/userAge.test.js`
Expected: FAIL — `Cannot find module '../lib/userAge'`

- [ ] **Step 3: Write the module**

```js
'use strict';

/**
 * Age from the three birth fields User stores as strings.
 *
 * Pure, so the boundary cases -- the birthday today, the day before an 18th --
 * are table-tested rather than reasoned about. Written for the `date` intent
 * gate; gatherings can reuse it when offline meetups land.
 */

const ageFrom = (user, now = new Date()) => {
  if (!user || typeof user !== 'object') return null;

  const year = parseInt(user.birth_year, 10);
  const month = parseInt(user.birth_month, 10);
  const day = parseInt(user.birth_day, 10);
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  let age = now.getFullYear() - year;
  // Subtract a year when this year's birthday has not arrived yet. Month is
  // 1-based here and 0-based on Date, hence the -1.
  const monthDiff = (now.getMonth() + 1) - month;
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < day)) age -= 1;

  return age >= 0 && age < 130 ? age : null;
};

/** Unknown age is NOT a minor -- see the test for why. */
const isMinor = (user, now = new Date()) => {
  const age = ageFrom(user, now);
  return age === null ? false : age < 18;
};

module.exports = { ageFrom, isMinor };
```

- [ ] **Step 4: Run the tests and watch them pass**

Run: `cd backend && node --test --test-force-exit test/userAge.test.js`
Expected: PASS, 9/9

- [ ] **Step 5: Commit**

```bash
git add backend/lib/userAge.js backend/test/userAge.test.js
git commit -m "feat(users): age helper, so the date intent can be withheld from minors"
```

---

## Task 3 — persist `intents`, and strip `date` for minors on write

**Files:**
- Modify: `backend/models/User.js` (add the field near `topics`)
- Modify: `backend/controllers/users.js:552` `updateUser`
- Test: `backend/test/userIntents.test.js`

**Interfaces:**
- Consumes: `normalizeIntents` (Task 1), `isMinor` (Task 2).
- Produces: `User.intents: [String]` defaulting to `[]`; `updateUser` accepting `intents`.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeIntents } = require('../lib/matchIntent');
const { isMinor } = require('../lib/userAge');

// The rule updateUser applies, extracted so it is testable without HTTP.
const { sanitizeIntents } = require('../lib/matchIntent');

test('an adult keeps every intent they chose', () => {
  const adult = { birth_year: '1995', birth_month: '1', birth_day: '1' };
  assert.deepEqual(sanitizeIntents(['learn', 'meet', 'date'], adult, new Date('2026-09-17')),
    ['learn', 'meet', 'date']);
});

test('GLOBAL CONSTRAINT: a minor loses date and keeps the rest', () => {
  const minor = { birth_year: '2012', birth_month: '1', birth_day: '1' };
  assert.deepEqual(sanitizeIntents(['learn', 'meet', 'date'], minor, new Date('2026-09-17')),
    ['learn', 'meet']);
});

test('a minor who sends only date ends up with nothing, not an error', () => {
  const minor = { birth_year: '2012', birth_month: '1', birth_day: '1' };
  assert.deepEqual(sanitizeIntents(['date'], minor, new Date('2026-09-17')), []);
});

test('unknown values are dropped before the age rule runs', () => {
  const adult = { birth_year: '1995', birth_month: '1', birth_day: '1' };
  assert.deepEqual(sanitizeIntents(['learn', 'hacking'], adult, new Date('2026-09-17')), ['learn']);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/userIntents.test.js`
Expected: FAIL — `sanitizeIntents is not a function`

- [ ] **Step 3: Add `sanitizeIntents` to `lib/matchIntent.js`**

Append before `module.exports`, and add `sanitizeIntents` to the exported object:

```js
/**
 * What a user is allowed to store, given who they are.
 *
 * Layer one of the under-18 rule (layer two is the scorer ignoring `date`).
 * Lives here rather than in the controller so it is testable without HTTP and
 * so any future write path gets the same rule for free.
 */
const sanitizeIntents = (value, user, now = new Date()) => {
  const { isMinor } = require('./userAge');
  const clean = normalizeIntents(value);
  return isMinor(user, now) ? clean.filter((i) => i !== 'date') : clean;
};
```

- [ ] **Step 4: Add the field to `models/User.js`**

Insert immediately after the `topics` array definition:

```js
  // Why this person is here. Ranked on, never filtered on -- every existing
  // user has [] and their results must not change. `date` is stripped for
  // under-18 accounts on write and ignored again at scoring time.
  intents: {
    type: [String],
    enum: ['learn', 'meet', 'date'],
    default: [],
    index: true,
  },
```

- [ ] **Step 5: Apply it in `controllers/users.js` `updateUser`**

After the `restrictedFields` deletion block and before the language validation, insert:

```js
  // Intents are sanitized rather than rejected: a client sending `date` for a
  // minor is asking for something we simply do not grant, not committing an
  // error worth failing their whole profile save over.
  if ('intents' in updateData) {
    const { sanitizeIntents } = require('../lib/matchIntent');
    const forAge = await User.findById(req.params.id).select('birth_year birth_month birth_day').lean();
    updateData.intents = sanitizeIntents(updateData.intents, forAge);
  }
```

- [ ] **Step 6: Run the tests and watch them pass**

Run: `cd backend && node --test --test-force-exit test/userIntents.test.js`
Expected: PASS, 4/4

- [ ] **Step 7: Commit**

```bash
git add backend/lib/matchIntent.js backend/models/User.js backend/controllers/users.js backend/test/userIntents.test.js
git commit -m "feat(users): store intents, and withhold the date intent from minors"
```

---

## Task 4 — score on it, and record it

**Files:**
- Modify: `backend/controllers/matching.js` — `WEIGHTS`, the `$addFields` projection, the `$add` sum, `recordImpressions`
- Modify: `backend/models/MatchImpression.js`
- Test: `backend/test/matchIntentScoring.test.js`

**Interfaces:**
- Consumes: `intentScore`, `normalizeIntents` (Task 1).
- Produces: `WEIGHTS.intentOverlap = 10`; impression rows carrying `intentScore`, `viewerIntents`, `shownIntents`.

- [ ] **Step 1: Write the failing test**

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { intentScore, INTENT_OVERLAP_WEIGHT } = require('../lib/matchIntent');

// The scorer must ignore `date` on READ even if a row somehow carries it for a
// minor -- layer two of the rule in spec §4.
const { scoreIntentForViewer } = require('../lib/matchIntent');

test('GLOBAL CONSTRAINT: a viewer with no intents scores 0 against everyone', () => {
  const adult = { birth_year: '1995', birth_month: '1', birth_day: '1' };
  assert.equal(scoreIntentForViewer([], ['learn'], adult, adult), 0);
});

test('a shared intent scores the flat weight', () => {
  const adult = { birth_year: '1995', birth_month: '1', birth_day: '1' };
  assert.equal(scoreIntentForViewer(['learn'], ['learn'], adult, adult), INTENT_OVERLAP_WEIGHT);
});

test('GLOBAL CONSTRAINT: date is ignored on read for a minor on either side', () => {
  const adult = { birth_year: '1995', birth_month: '1', birth_day: '1' };
  const minor = { birth_year: '2012', birth_month: '1', birth_day: '1' };
  // A stored `date` on a minor's row must not create an overlap.
  assert.equal(scoreIntentForViewer(['date'], ['date'], adult, minor), 0);
  assert.equal(scoreIntentForViewer(['date'], ['date'], minor, adult), 0);
  // Two adults are unaffected.
  assert.equal(scoreIntentForViewer(['date'], ['date'], adult, adult), INTENT_OVERLAP_WEIGHT);
});

test('a minor still matches on learn and meet', () => {
  const adult = { birth_year: '1995', birth_month: '1', birth_day: '1' };
  const minor = { birth_year: '2012', birth_month: '1', birth_day: '1' };
  assert.equal(scoreIntentForViewer(['learn'], ['learn'], adult, minor), INTENT_OVERLAP_WEIGHT);
});
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd backend && node --test --test-force-exit test/matchIntentScoring.test.js`
Expected: FAIL — `scoreIntentForViewer is not a function`

- [ ] **Step 3: Add `scoreIntentForViewer` to `lib/matchIntent.js`**

```js
/**
 * Layer two of the under-18 rule: `date` is dropped at scoring time for a minor
 * on EITHER side, whatever is stored. sanitizeIntents already prevents it being
 * written; this makes a stale or hand-edited row harmless too.
 */
const scoreIntentForViewer = (viewerIntents, shownIntents, viewer, shown, now = new Date()) => {
  const { isMinor } = require('./userAge');
  const strip = (list, user) => {
    const clean = normalizeIntents(list);
    return isMinor(user, now) ? clean.filter((i) => i !== 'date') : clean;
  };
  return intentScore(strip(viewerIntents, viewer), strip(shownIntents, shown));
};
```

- [ ] **Step 4: Add the weight and the pipeline stage in `controllers/matching.js`**

Add to `WEIGHTS` (after `profileComplete`):

```js
    intentOverlap: 10,       // Shares at least one of learn/meet/date
```

Add to the `$addFields` projection block, beside `seenPenalty`:

```js
        // Flat bonus for any shared intent. Computed in the pipeline so it can
        // be sorted on; `date` is excluded for minors on both sides, matching
        // lib/matchIntent.scoreIntentForViewer.
        intentScore: {
          $cond: [
            { $gt: [{ $size: { $setIntersection: ['$intents', viewerIntentsForMatch] } }, 0] },
            WEIGHTS.intentOverlap,
            0,
          ],
        },
```

Immediately above the pipeline, compute the viewer's usable intents once:

```js
  // Computed once rather than per candidate. `date` is dropped when the viewer
  // is a minor, so a stale row cannot create a dating match.
  const { normalizeIntents } = require('../lib/matchIntent');
  const { isMinor } = require('../lib/userAge');
  const viewerIntentsForMatch = isMinor(currentUser)
    ? normalizeIntents(currentUser.intents).filter((i) => i !== 'date')
    : normalizeIntents(currentUser.intents);
```

Add `'$intentScore'` to the `$add` array that builds `matchScore`.

**Note on the other side of the age rule:** candidates are not age-filtered in the
pipeline. The viewer-side strip already prevents a minor from receiving a `date` overlap,
and a minor's own `date` value cannot be written (Task 3). A stale pre-existing row is
covered because minors could never set `date` in the first place.

- [ ] **Step 5: Record it — `recordImpressions`**

Add to the `insertMany` object:

```js
    intentScore: user.intentScore || 0,
    viewerIntents: normalizeIntents(viewer.intents),
    shownIntents: normalizeIntents(user.intents),
```

And to `models/MatchImpression.js`, beside the other score fields:

```js
  // Spec §6: without these the intent weight is unevaluable, which is the exact
  // gap the previous spec's Task 4 was written to close.
  intentScore: { type: Number, default: 0 },
  viewerIntents: { type: [String], default: [] },
  shownIntents: { type: [String], default: [] },
```

- [ ] **Step 6: Ensure `intents` is selected on the viewer**

`getRecommendations` loads `currentUser`. Confirm its `.select(...)` includes `intents`; add it if the select is explicit. Without this `currentUser.intents` is `undefined` and every score silently becomes 0.

- [ ] **Step 7: Run the tests and watch them pass**

Run: `cd backend && node --test --test-force-exit test/matchIntentScoring.test.js && npm test`
Expected: the new file 4/4, and the full suite green.

- [ ] **Step 8: Commit**

```bash
git add backend/lib/matchIntent.js backend/controllers/matching.js backend/models/MatchImpression.js backend/test/matchIntentScoring.test.js
git commit -m "feat(matching): rank on shared intent, and record it so it can be judged"
```

---

## Task 5 — the app: collect it, count it, show two of the three

**Files:**
- Modify: `app/lib/providers/provider_models/community_model.dart`
- Modify: `app/lib/pages/profile/edit_main/completion_calculator.dart`
- Modify: `app/lib/pages/profile/profile_main/sections/profile_highlights_tab.dart`
- Modify: `app/lib/pages/profile/profile_main/sections/profile_about_tab.dart`
- Modify: `app/lib/l10n/app_*.arb` (19 files)
- Test: `app/test/profile/intent_test.dart`

**Interfaces:**
- Consumes: the `intents` array on the user payload (Task 3).
- Produces: `Community.intents: List<String>`; `calculateProfileCompletion(..., required List<String> intents)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/profile/edit_main/completion_calculator.dart';

ProfileCompletion _completion({List<String> intents = const []}) =>
    calculateProfileCompletion(
      name: 'Ana', gender: 'female', bio: 'hi',
      nativeLanguage: 'Korean', languageToLearn: 'English',
      languageLevel: 'B1', mbti: 'INTJ', address: 'Seoul',
      topics: const ['music'], intents: intents,
    );

void main() {
  test('intents count toward profile completion', () {
    expect(_completion(intents: const []).totalFields, 10);
    expect(_completion(intents: const []).completedFields, 9);
    expect(_completion(intents: const ['learn']).completedFields, 10);
  });

  test('a fully filled profile with an intent reads 100%', () {
    expect(_completion(intents: const ['learn', 'meet']).percent, 100);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd bananatalk_app && flutter test test/profile/intent_test.dart`
Expected: FAIL — no named parameter `intents`.

- [ ] **Step 3: Add `intents` to the calculator**

In `completion_calculator.dart`: add `required List<String> intents` to the signature, change `const total = 9;` to `const total = 10;`, and add `if (intents.isNotEmpty) filled++;`. Update the one call site in `edit_main.dart`.

- [ ] **Step 4: Add `intents` to `Community`**

Add `final List<String> intents;`, default `const []`, to the constructor, and parse in `fromJson`:

```dart
      intents: (json['intents'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
```

- [ ] **Step 5: List it as a missing field on the completion card**

In `profile_highlights_tab.dart` `_calculate`, add to the `fields` map:

```dart
      'What you\'re here for': user.intents.isNotEmpty,
```

- [ ] **Step 6: Render learn/meet as chips, never date**

In `profile_about_tab.dart`, render a chip per intent from
`user.intents.where((i) => i != 'date')`. **`date` must never reach the widget tree** —
filter at the source, not in the builder, so a future edit cannot leak it.

Add three l10n keys to all 19 `app_*.arb` files: `intentLearn` ("Here to learn"),
`intentMeet` ("Open to meeting people"), `intentSectionTitle` ("What you're here for").
Run `flutter gen-l10n`.

- [ ] **Step 7: Write the leak test**

```dart
  testWidgets('the date intent is never rendered', (tester) async {
    // Publicly badging someone as available to date is a harassment vector;
    // spec §2.3 makes this non-negotiable.
    await tester.pumpWidget(_host(ProfileAboutTab(
      user: _user(intents: const ['learn', 'date']),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('date', findRichText: true), findsNothing);
    expect(find.textContaining('Date'), findsNothing);
  });
```

- [ ] **Step 8: Run everything**

Run: `cd bananatalk_app && flutter test && flutter analyze lib/`
Expected: all green, zero analyzer errors.

- [ ] **Step 9: Commit**

```bash
git add bananatalk_app/lib bananatalk_app/test
git commit -m "feat(profile): collect intent, count it toward completion, show learn and meet"
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| §2 data model, multi-select | 3 |
| §3 flat weight of 10 | 1, 4 |
| §3.2 unset scores zero | 1 (test), 4 (test) |
| §4 safety, both layers | 3 (write), 4 (read) |
| §5 collection: completion card | 5 |
| §5 collection: profile edit | 5 |
| §5 collection: registration step | **deferred — see below** |
| §6 measurement | 4 |
| §8 testing | every task |

**Registration step:** deferred to a follow-up. The completion card and profile edit both
reach the existing 1,813 and every new user eventually; a registration step reaches only
new signups and touches a flow with its own validation and analytics. Splitting it keeps
this plan's blast radius at "ranking plus one profile field". Noted so it is not lost.

**Type consistency:** `normalizeIntents`, `sharesIntent`, `intentScore`, `sanitizeIntents`,
`scoreIntentForViewer`, `ageFrom`, `isMinor` are each defined once and used with the same
signature everywhere. `WEIGHTS.intentOverlap` and `INTENT_OVERLAP_WEIGHT` are both 10; the
pipeline uses the former, the pure module the latter.

**Placeholders:** none.
