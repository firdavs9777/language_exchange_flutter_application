# Daily Learning Pack — Backend Implementation Plan (Wave 1, Plan 1 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the two-card daily drop into a four-station daily pack under a weekly theme, with placement, per-learner grammar progression, and a mastery endpoint — all server-side, so the Flutter plan can build against locked response shapes.

**Architecture:** Extend the existing daily-drop spine rather than replace it (spec D3). Every new decision lives in a pure `lib/` module that is unit-tested without a database; services and controllers stay thin orchestration over those. `DailyDrop` remains the shared per-(date, language, level) document for vocabulary; grammar and review resolve per-user at read time.

**Tech Stack:** Node 24.18.0, Express, Mongoose 6, `node:test` runner (`npm test`), `mongodb-memory-server` ^10.4.3 for integration tests. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-11-daily-learning-pack-design.md`

**Repo:** `/Users/davis/Desktop/Personal/language_exchange_backend_application` (all paths below are relative to it). Branch from `main` as `feat/daily-pack-backend`.

## Global Constraints

- **Node 24.18.0.** Run the suite with `npm test` (which is `node --experimental-test-module-mocks --test --test-force-exit services/*.test.js test/*.test.js`). Single files: `node --test test/<file>.test.js`.
- **No new dependencies.** `mongodb-memory-server` is already a devDependency.
- **`'use strict';` at the top of every new `lib/` module** — matches `lib/dailyCompletion.js`, `lib/dailyLevels.js`, `lib/dailyItemShape.js`.
- **Pure logic goes in `lib/`, tested with no DB.** Anything touching Mongo is tested with `mongodb-memory-server` following the pattern in `test/xpStreakTick.test.js`.
- **Station kind stays spelled `vocabulary`, never `vocab`.** 35 completion rows exist on prod (14 of them `vocabulary`); renaming the enum value would invalidate them. `STATION_KINDS` is a strict superset of `ITEM_KINDS`.
- **All dates are UTC `'YYYY-MM-DD'` keys** via `toDateKey()` from `lib/dailyCompletion.js`. Never `setHours`, never server-local days — that exact bug reset healthy streaks once already.
- **`dateKey` for any write is derived server-side.** Never trust a client-supplied date on a completion, or a client farms streak and XP with a fabricated date sequence.
- **`answerIndex` is never serialized to the client.** The server scores submissions (see `serializeItem` in `controllers/dailyStudy.js`).
- **XP always flows through `learningTrackingService.awardXPWithStreak()`** (backend `4502ce0`), so every station ticks the streak once per UTC day via `lastStreakDateKey`.
- **Answer-position balance:** authored batches must keep every `answerIndex` position within ±25% relative of uniform, grouped by option count (3 options → 25–42%).
- **Content copyright boundary:** reference grammars supply the syllabus (unit list, order, section grouping) only. Every explanation, example and exercise is authored fresh. No book prose or exercise sentence enters the database. Mirror the comment block at the top of `models/VocabPack.js`.

## Deviations from the spec (decided while planning)

1. **No `DailyDrop.listeningItem`.** The spec proposed a `DailyItem` ref. Listening content is fully determined by the week's pack plus `dayInWeek`, so it is derived at read time instead — one fewer ref to populate, generate and keep consistent. `DailyDrop` gains only `weekKey`, `themePack` and `dayInWeek`.
2. **`VocabPack.level` needs a third enum value.** The spec's 12 beginner packs cannot be stored today: the enum is `['intermediate', 'advanced']`. Task 11 adds `'beginner'`.
3. **The three open questions in spec §10 are resolved as follows** for wave 1, since they block task boundaries: the weekend `translate` station is **typed input only** (no speech — `speechService` STT stays out of scope); the Friday wrap quiz is **formative**, never a gate; the 12 beginner packs are authored through the **same workflow as the existing 50** (`migrations/vocabPacksData.json` + `seeds/vocabPacks.js`).

---

## File Structure

| File | Responsibility |
|---|---|
| Create `lib/dailyStations.js` | `STATION_KINDS`, which stations apply on a given weekday, day-completion over applicable stations |
| Create `lib/dailyTheme.js` | Week key, deterministic theme rotation, day-in-week, which 5 words of 20 |
| Create `lib/grammarCursor.js` | Mastery threshold and next-unit selection with cooldown |
| Create `lib/answerBalance.js` | Answer-position distribution gate for authored batches |
| Create `lib/vocabChecks.js` | Deterministic definition-to-word questions from pack words |
| Create `lib/placementScoring.js` | Placement answers → CEFR level + book |
| Create `models/GrammarMastery.js` | Per-user per-unit grammar mastery |
| Create `models/LevelPlacement.js` | Placement audit record |
| Modify `models/DailyItem.js` | `+ syllabus { book, unit, section }` |
| Modify `models/DailyDrop.js` | `+ weekKey, themePack, dayInWeek`; `grammarItem` deprecated |
| Modify `models/DailyDropCompletion.js` | `+ item` ref; `kind` enum from `STATION_KINDS` |
| Modify `models/VocabPack.js` | `level` enum gains `'beginner'` |
| Create `services/dailyPackService.js` | Compose the day's four stations for one user |
| Create `services/masteryService.js` | The four mastery aggregates |
| Modify `controllers/dailyStudy.js` | `getDailyPack`, `completeStation`, placement handlers |
| Modify `routes/dailyStudy.js` | New routes |
| Modify `jobs/dailyDropJob.js` | Generate vocabulary themes only; stop pre-generating grammar |
| Create `seeds/dailyGrammarItems.js` | Seed authored grammar units with the balance gate |
| Create `migrations/dailyGrammarData.json` | Authored grammar units (content, produced by Plan 3) |

---

### Task 1: Station kinds and weekday applicability

**Files:**
- Create: `lib/dailyStations.js`
- Test: `test/dailyStations.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `STATION_KINDS: string[]` — `['grammar','vocabulary','listening','review','wrap','translate']`
  - `stationsForDay(dateKey: string): string[]` — the four applicable station kinds, in display order
  - `isPackComplete(applicable: string[], completions: {kind:string}[], emptyStations: string[]): boolean`

- [ ] **Step 1: Write the failing test**

```javascript
// test/dailyStations.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { STATION_KINDS, stationsForDay, isPackComplete } = require('../lib/dailyStations');

test('station kinds keep the legacy vocabulary spelling', () => {
  // 35 completion rows exist on prod, 14 of them kind 'vocabulary'.
  assert.ok(STATION_KINDS.includes('vocabulary'));
  assert.ok(!STATION_KINDS.includes('vocab'));
});

test('Monday through Thursday serve new words', () => {
  // 2026-09-07 is a Monday, 2026-09-10 a Thursday.
  for (const d of ['2026-09-07', '2026-09-08', '2026-09-09', '2026-09-10']) {
    assert.deepEqual(stationsForDay(d), ['vocabulary', 'grammar', 'listening', 'review']);
  }
});

test('Friday swaps new words for the theme wrap quiz', () => {
  assert.deepEqual(stationsForDay('2026-09-11'), ['wrap', 'grammar', 'listening', 'review']);
});

test('the weekend swaps in the translate station', () => {
  assert.deepEqual(stationsForDay('2026-09-12'), ['translate', 'grammar', 'listening', 'review']);
  assert.deepEqual(stationsForDay('2026-09-13'), ['translate', 'grammar', 'listening', 'review']);
});

test('every day has exactly four stations', () => {
  for (const d of ['2026-09-07','2026-09-08','2026-09-09','2026-09-10','2026-09-11','2026-09-12','2026-09-13']) {
    assert.equal(stationsForDay(d).length, 4);
  }
});

test('the pack completes when every applicable station is done', () => {
  const applicable = ['vocabulary', 'grammar', 'listening', 'review'];
  const done = applicable.map((kind) => ({ kind }));
  assert.equal(isPackComplete(applicable, done, []), true);
});

test('an empty station auto-satisfies so a new learner can finish a day', () => {
  // A brand-new learner has no due words. If review blocked completion, NO new
  // user could ever complete a day and the streak would be unreachable.
  const applicable = ['vocabulary', 'grammar', 'listening', 'review'];
  const done = [{ kind: 'vocabulary' }, { kind: 'grammar' }, { kind: 'listening' }];
  assert.equal(isPackComplete(applicable, done, ['review']), true);
});

test('an empty station does not excuse the others', () => {
  const applicable = ['vocabulary', 'grammar', 'listening', 'review'];
  assert.equal(isPackComplete(applicable, [{ kind: 'vocabulary' }], ['review']), false);
});

test('a completion for a station that does not apply today is ignored', () => {
  const applicable = ['wrap', 'grammar', 'listening', 'review'];
  const done = [{ kind: 'vocabulary' }, { kind: 'grammar' }, { kind: 'listening' }, { kind: 'review' }];
  assert.equal(isPackComplete(applicable, done, []), false);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/dailyStations.test.js`
Expected: FAIL — `Cannot find module '../lib/dailyStations'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/dailyStations.js
'use strict';

// Superset of ITEM_KINDS in lib/dailyItemShape.js. 'vocabulary' keeps its
// legacy spelling because prod completion rows already use it.
const STATION_KINDS = ['grammar', 'vocabulary', 'listening', 'review', 'wrap', 'translate'];

// Every day serves four stations. Only the first slot varies: new words on
// weekdays, the theme wrap quiz on Friday, productive practice at the weekend.
const FIRST_SLOT_BY_DOW = {
  0: 'translate',   // Sunday
  1: 'vocabulary',
  2: 'vocabulary',
  3: 'vocabulary',
  4: 'vocabulary',
  5: 'wrap',        // Friday
  6: 'translate',   // Saturday
};

const dayOfWeek = (dateKey) => new Date(`${dateKey}T00:00:00Z`).getUTCDay();

const stationsForDay = (dateKey) => [
  FIRST_SLOT_BY_DOW[dayOfWeek(dateKey)],
  'grammar',
  'listening',
  'review',
];

/**
 * The pack is complete when every applicable station is either completed or
 * empty. Empty must count as satisfied: a new learner has no due words, and
 * requiring review would make the streak unreachable for exactly the learners
 * this feature is trying to retain.
 */
const isPackComplete = (applicable, completions, emptyStations) => {
  const done = new Set((completions || []).map((c) => c.kind));
  const empty = new Set(emptyStations || []);
  return (applicable || []).every((k) => done.has(k) || empty.has(k));
};

module.exports = { STATION_KINDS, stationsForDay, isPackComplete, dayOfWeek };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/dailyStations.test.js`
Expected: PASS, 8 tests

- [ ] **Step 5: Commit**

```bash
git add lib/dailyStations.js test/dailyStations.test.js
git commit -m "feat(daily-pack): station kinds and weekday applicability"
```

---

### Task 2: Weekly theme rotation

**Files:**
- Create: `lib/dailyTheme.js`
- Test: `test/dailyTheme.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `weekKeyFor(dateKey: string): string` — ISO-style `'YYYY-Www'`
  - `dayInWeek(dateKey: string): number` — 1 (Mon) … 7 (Sun)
  - `themeIndexFor(dateKey: string, packCount: number): number`
  - `wordSliceFor(words: T[], dateKey: string, perDay = 5): T[]`

- [ ] **Step 1: Write the failing test**

```javascript
// test/dailyTheme.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { weekKeyFor, dayInWeek, themeIndexFor, wordSliceFor } = require('../lib/dailyTheme');

test('dayInWeek runs Monday=1 to Sunday=7', () => {
  assert.equal(dayInWeek('2026-09-07'), 1); // Monday
  assert.equal(dayInWeek('2026-09-11'), 5); // Friday
  assert.equal(dayInWeek('2026-09-13'), 7); // Sunday
});

test('every day of one week shares a week key', () => {
  const keys = ['2026-09-07','2026-09-08','2026-09-09','2026-09-10','2026-09-11','2026-09-12','2026-09-13']
    .map(weekKeyFor);
  assert.equal(new Set(keys).size, 1);
});

test('the next Monday starts a new week key', () => {
  assert.notEqual(weekKeyFor('2026-09-13'), weekKeyFor('2026-09-14'));
});

test('theme selection is stable within a week and rotates across weeks', () => {
  assert.equal(themeIndexFor('2026-09-07', 25), themeIndexFor('2026-09-13', 25));
  assert.notEqual(themeIndexFor('2026-09-07', 25), themeIndexFor('2026-09-14', 25));
});

test('theme index always lands inside the pack list', () => {
  for (const d of ['2026-01-01', '2026-09-11', '2027-06-30']) {
    const i = themeIndexFor(d, 25);
    assert.ok(i >= 0 && i < 25, `${d} produced ${i}`);
  }
});

test('an empty pack list yields no theme rather than dividing by zero', () => {
  assert.equal(themeIndexFor('2026-09-11', 0), null);
});

test('a 20-word pack is served five words a day, Monday to Thursday', () => {
  const words = Array.from({ length: 20 }, (_, i) => ({ word: `w${i}` }));
  assert.deepEqual(wordSliceFor(words, '2026-09-07').map((w) => w.word), ['w0','w1','w2','w3','w4']);
  assert.deepEqual(wordSliceFor(words, '2026-09-10').map((w) => w.word), ['w15','w16','w17','w18','w19']);
});

test('a short pack yields a short slice rather than undefined entries', () => {
  const words = Array.from({ length: 7 }, (_, i) => ({ word: `w${i}` }));
  assert.deepEqual(wordSliceFor(words, '2026-09-08').map((w) => w.word), ['w5', 'w6']);
  assert.deepEqual(wordSliceFor(words, '2026-09-10'), []);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/dailyTheme.test.js`
Expected: FAIL — `Cannot find module '../lib/dailyTheme'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/dailyTheme.js
'use strict';

const DAY_MS = 86400000;
// A Monday, used as the epoch for week arithmetic so week 0 starts on a Monday.
const WEEK_EPOCH = Date.UTC(2024, 0, 1); // 2024-01-01 was a Monday

const utc = (dateKey) => new Date(`${dateKey}T00:00:00Z`).getTime();

/** Monday = 1 … Sunday = 7 (getUTCDay gives Sunday = 0). */
const dayInWeek = (dateKey) => {
  const dow = new Date(`${dateKey}T00:00:00Z`).getUTCDay();
  return dow === 0 ? 7 : dow;
};

const weeksSinceEpoch = (dateKey) =>
  Math.floor((utc(dateKey) - (dayInWeek(dateKey) - 1) * DAY_MS - WEEK_EPOCH) / (7 * DAY_MS));

/** Stable label for the Monday-anchored week containing dateKey. */
const weekKeyFor = (dateKey) => {
  const monday = new Date(utc(dateKey) - (dayInWeek(dateKey) - 1) * DAY_MS);
  const year = monday.getUTCFullYear();
  const jan1 = Date.UTC(year, 0, 1);
  const week = Math.floor((monday.getTime() - jan1) / (7 * DAY_MS)) + 1;
  return `${year}-W${String(week).padStart(2, '0')}`;
};

/**
 * Deterministic rotation over the level's packs — no scheduling state to
 * maintain, so the nightly job stays idempotent and a re-run picks the same
 * theme. Returns null for an empty pack list.
 */
const themeIndexFor = (dateKey, packCount) => {
  if (!packCount || packCount <= 0) return null;
  return ((weeksSinceEpoch(dateKey) % packCount) + packCount) % packCount;
};

/** The five of twenty words this weekday teaches. Short packs just run out. */
const wordSliceFor = (words, dateKey, perDay = 5) => {
  const start = (dayInWeek(dateKey) - 1) * perDay;
  return (words || []).slice(start, start + perDay);
};

module.exports = { weekKeyFor, dayInWeek, themeIndexFor, wordSliceFor, weeksSinceEpoch };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/dailyTheme.test.js`
Expected: PASS, 8 tests

- [ ] **Step 5: Commit**

```bash
git add lib/dailyTheme.js test/dailyTheme.test.js
git commit -m "feat(daily-pack): deterministic weekly theme rotation"
```

---

### Task 3: Grammar mastery threshold and cursor

**Files:**
- Create: `lib/grammarCursor.js`
- Test: `test/grammarCursor.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `isMastered(row: {bestScore?:number, passDays?:string[]}): boolean`
  - `nextUnit({ units, mastery, todayKey, cooldownDays = 2 }): number | null`
  - `applyAttempt(row, { score, total, dateKey }): {attempts, bestScore, passDays, mastered, lastSeenDateKey}`

- [ ] **Step 1: Write the failing test**

```javascript
// test/grammarCursor.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { isMastered, nextUnit, applyAttempt } = require('../lib/grammarCursor');

test('a perfect first attempt masters the unit immediately', () => {
  const row = applyAttempt(null, { score: 3, total: 3, dateKey: '2026-09-11' });
  assert.equal(row.mastered, true);
  assert.equal(isMastered(row), true);
});

test('one pass at two of three does not master the unit', () => {
  const row = applyAttempt(null, { score: 2, total: 3, dateKey: '2026-09-11' });
  assert.equal(row.mastered, false);
});

test('two passes on separate days master the unit', () => {
  let row = applyAttempt(null, { score: 2, total: 3, dateKey: '2026-09-11' });
  row = applyAttempt(row, { score: 2, total: 3, dateKey: '2026-09-12' });
  assert.equal(row.mastered, true);
});

test('two passes on the SAME day do not master the unit', () => {
  let row = applyAttempt(null, { score: 2, total: 3, dateKey: '2026-09-11' });
  row = applyAttempt(row, { score: 2, total: 3, dateKey: '2026-09-11' });
  assert.equal(row.mastered, false, 'same-day repeats must not shortcut mastery');
});

test('a failing attempt records the visit without mastering', () => {
  const row = applyAttempt(null, { score: 1, total: 3, dateKey: '2026-09-11' });
  assert.equal(row.mastered, false);
  assert.equal(row.attempts, 1);
  assert.equal(row.lastSeenDateKey, '2026-09-11');
});

test('a fresh learner starts at the first unit', () => {
  assert.equal(nextUnit({ units: [1, 2, 3], mastery: [], todayKey: '2026-09-11' }), 1);
});

test('the cursor skips mastered units', () => {
  const mastery = [{ unit: 1, mastered: true, lastSeenDateKey: '2026-09-01' }];
  assert.equal(nextUnit({ units: [1, 2, 3], mastery, todayKey: '2026-09-11' }), 2);
});

test('a unit failed today is in cooldown, so the learner meets the next one', () => {
  const mastery = [{ unit: 1, mastered: false, lastSeenDateKey: '2026-09-11' }];
  assert.equal(nextUnit({ units: [1, 2, 3], mastery, todayKey: '2026-09-11' }), 2);
});

test('a failed unit comes back after the cooldown', () => {
  const mastery = [{ unit: 1, mastered: false, lastSeenDateKey: '2026-09-08' }];
  assert.equal(nextUnit({ units: [1, 2, 3], mastery, todayKey: '2026-09-11' }), 1);
});

test('when every unmastered unit is in cooldown the oldest-seen one is served', () => {
  // Never report "nothing to study" — that would strand the station and block
  // the day for a learner who simply had a bad session.
  const mastery = [
    { unit: 1, mastered: false, lastSeenDateKey: '2026-09-10' },
    { unit: 2, mastered: false, lastSeenDateKey: '2026-09-11' },
  ];
  assert.equal(nextUnit({ units: [1, 2], mastery, todayKey: '2026-09-11' }), 1);
});

test('a learner who mastered the whole book gets null', () => {
  const mastery = [{ unit: 1, mastered: true }, { unit: 2, mastered: true }];
  assert.equal(nextUnit({ units: [1, 2], mastery, todayKey: '2026-09-11' }), null);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/grammarCursor.test.js`
Expected: FAIL — `Cannot find module '../lib/grammarCursor'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/grammarCursor.js
'use strict';

const DAY_MS = 86400000;
const PASS_RATIO = 2 / 3;   // >= 2 of 3 counts as a pass
const PASSES_NEEDED = 2;    // ... on two separate days

const daysBetween = (a, b) =>
  Math.round((new Date(`${b}T00:00:00Z`) - new Date(`${a}T00:00:00Z`)) / DAY_MS);

/** Mastered by one perfect attempt, or two passing attempts on separate days. */
const isMastered = (row) => {
  if (!row) return false;
  if (row.mastered) return true;
  if (row.perfect) return true;
  return (row.passDays || []).length >= PASSES_NEEDED;
};

const applyAttempt = (row, { score, total, dateKey }) => {
  const prev = row || { attempts: 0, bestScore: 0, passDays: [], mastered: false };
  const passed = total > 0 && score / total >= PASS_RATIO;
  const perfect = total > 0 && score === total;

  // Separate DAYS, not separate attempts: retrying the same unit twice in one
  // sitting must not buy mastery.
  const passDays = passed && !(prev.passDays || []).includes(dateKey)
    ? [...(prev.passDays || []), dateKey]
    : (prev.passDays || []);

  const next = {
    attempts: (prev.attempts || 0) + 1,
    bestScore: Math.max(prev.bestScore || 0, score),
    passDays,
    perfect: Boolean(prev.perfect || perfect),
    lastSeenDateKey: dateKey,
  };
  next.mastered = isMastered(next);
  return next;
};

/**
 * The learner's next grammar unit: the lowest unit that is neither mastered
 * nor in cooldown. Cooldown keeps a just-failed unit from being served again
 * the same day while still letting the learner make progress elsewhere.
 *
 * If every unmastered unit is in cooldown we serve the oldest-seen one rather
 * than returning null — a station with nothing in it would block the day for
 * someone who simply had a bad session. null means the book is finished.
 */
const nextUnit = ({ units, mastery, todayKey, cooldownDays = 2 }) => {
  const byUnit = new Map((mastery || []).map((m) => [m.unit, m]));
  const ordered = [...(units || [])].sort((a, b) => a - b);

  const unmastered = ordered.filter((u) => !isMastered(byUnit.get(u)));
  if (unmastered.length === 0) return null;

  const ready = unmastered.filter((u) => {
    const seen = byUnit.get(u) && byUnit.get(u).lastSeenDateKey;
    return !seen || daysBetween(seen, todayKey) >= cooldownDays;
  });
  if (ready.length) return ready[0];

  return [...unmastered].sort((a, b) => {
    const as = (byUnit.get(a) || {}).lastSeenDateKey || '';
    const bs = (byUnit.get(b) || {}).lastSeenDateKey || '';
    return as < bs ? -1 : as > bs ? 1 : a - b;
  })[0];
};

module.exports = { isMastered, applyAttempt, nextUnit, PASS_RATIO, PASSES_NEEDED };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/grammarCursor.test.js`
Expected: PASS, 11 tests

- [ ] **Step 5: Commit**

```bash
git add lib/grammarCursor.js test/grammarCursor.test.js
git commit -m "feat(daily-pack): grammar mastery thresholds and cursor with cooldown"
```

---

### Task 4: Answer-position balance gate

**Files:**
- Create: `lib/answerBalance.js`
- Test: `test/answerBalance.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `checkAnswerBalance(items, { tolerance = 0.25 }): { ok: boolean, groups: {...}[], errors: string[] }`

- [ ] **Step 1: Write the failing test**

```javascript
// test/answerBalance.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { checkAnswerBalance } = require('../lib/answerBalance');

const itemWith = (indices, optionCount = 3) => ({
  quickCheck: indices.map((answerIndex) => ({
    prompt: 'p', options: Array.from({ length: optionCount }, (_, i) => `o${i}`), answerIndex,
  })),
});

test('an evenly spread batch passes', () => {
  const items = [itemWith([0, 1, 2]), itemWith([1, 2, 0]), itemWith([2, 0, 1])];
  assert.equal(checkAnswerBalance(items).ok, true);
});

test("the current production skew fails", () => {
  // Measured on prod: 34.4% / 58.7% / 6.9% across 540 questions.
  const indices = [];
  for (let i = 0; i < 34; i++) indices.push(0);
  for (let i = 0; i < 59; i++) indices.push(1);
  for (let i = 0; i < 7; i++) indices.push(2);
  const result = checkAnswerBalance([itemWith(indices)]);
  assert.equal(result.ok, false);
  assert.match(result.errors.join(' '), /position 1/);
});

test('four-option questions are judged against their own uniform, not 33%', () => {
  // 25% uniform; a flat 25-42% band would wrongly reject this.
  const indices = [];
  for (let i = 0; i < 25; i++) indices.push(0, 1, 2, 3);
  assert.equal(checkAnswerBalance([itemWith(indices, 4)]).ok, true);
});

test('option counts are grouped separately', () => {
  const good3 = itemWith([0, 1, 2]);
  const skewed4 = itemWith(Array.from({ length: 40 }, () => 0), 4);
  const result = checkAnswerBalance([good3, skewed4]);
  assert.equal(result.ok, false);
  assert.equal(result.groups.length, 2);
});

test('a batch too small to judge passes rather than blocking a seed', () => {
  assert.equal(checkAnswerBalance([itemWith([0])]).ok, true);
});

test('an empty batch is vacuously fine', () => {
  assert.equal(checkAnswerBalance([]).ok, true);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/answerBalance.test.js`
Expected: FAIL — `Cannot find module '../lib/answerBalance'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/answerBalance.js
'use strict';

// Below this many questions in a group the distribution is noise, not skew.
const MIN_SAMPLE = 12;

/**
 * Guards the authoring gate from spec §4.6. The live bank sits at
 * 34.4% / 58.7% / 6.9%, which lets a learner score by always picking the
 * middle option. Grouped by option count because quickCheck.options is not
 * fixed at three, so uniform is 1/n, not a hardcoded 33%.
 */
const checkAnswerBalance = (items, { tolerance = 0.25 } = {}) => {
  const groups = new Map();

  for (const item of items || []) {
    for (const q of (item && item.quickCheck) || []) {
      const n = Array.isArray(q.options) ? q.options.length : 0;
      if (n < 2) continue;
      if (!groups.has(n)) groups.set(n, { optionCount: n, total: 0, counts: new Array(n).fill(0) });
      const g = groups.get(n);
      g.total += 1;
      if (Number.isInteger(q.answerIndex) && q.answerIndex >= 0 && q.answerIndex < n) {
        g.counts[q.answerIndex] += 1;
      }
    }
  }

  const errors = [];
  const report = [];

  for (const g of groups.values()) {
    const uniform = 1 / g.optionCount;
    const lo = uniform * (1 - tolerance);
    const hi = uniform * (1 + tolerance);
    const shares = g.counts.map((c) => (g.total ? c / g.total : 0));
    report.push({ ...g, shares, band: [lo, hi] });

    if (g.total < MIN_SAMPLE) continue;
    shares.forEach((share, i) => {
      if (share < lo || share > hi) {
        errors.push(
          `${g.optionCount}-option questions: position ${i} holds ${(share * 100).toFixed(1)}% `
          + `of answers, outside the ${(lo * 100).toFixed(1)}-${(hi * 100).toFixed(1)}% band`
        );
      }
    });
  }

  return { ok: errors.length === 0, groups: report, errors };
};

module.exports = { checkAnswerBalance, MIN_SAMPLE };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/answerBalance.test.js`
Expected: PASS, 6 tests

- [ ] **Step 5: Commit**

```bash
git add lib/answerBalance.js test/answerBalance.test.js
git commit -m "feat(daily-pack): answer-position balance gate for authored batches"
```

---

### Task 5: Placement scoring

**Files:**
- Create: `lib/placementScoring.js`
- Test: `test/placementScoring.test.js`

**Interfaces:**
- Consumes: `LEVELS`, `DEFAULT_LEVEL` from `lib/dailyLevels.js`.
- Produces:
  - `PLACEMENT_QUESTIONS: {id, level, prompt, options, answerIndex}[]` — 8 items, ascending difficulty
  - `levelFromPlacement(answers: number[]): { level: string, book: 'elementary'|'intermediate', correct: number }`
  - `bookForLevel(level: string): 'elementary'|'intermediate'`

- [ ] **Step 1: Write the failing test**

```javascript
// test/placementScoring.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { PLACEMENT_QUESTIONS, levelFromPlacement, bookForLevel } = require('../lib/placementScoring');
const { LEVELS } = require('../lib/dailyLevels');

test('the placement is eight questions of ascending difficulty', () => {
  assert.equal(PLACEMENT_QUESTIONS.length, 8);
  const order = PLACEMENT_QUESTIONS.map((q) => LEVELS.indexOf(q.level));
  assert.deepEqual(order, [...order].sort((a, b) => a - b));
});

test('every placement question is answerable and well formed', () => {
  for (const q of PLACEMENT_QUESTIONS) {
    assert.ok(q.prompt && q.prompt.length > 0);
    assert.ok(q.options.length >= 3);
    assert.ok(q.answerIndex >= 0 && q.answerIndex < q.options.length);
    assert.ok(LEVELS.includes(q.level));
  }
});

test('placement answer positions are balanced', () => {
  const { checkAnswerBalance } = require('../lib/answerBalance');
  // Same fairness rule as the content bank; 8 questions is below MIN_SAMPLE so
  // assert the spread directly instead.
  const counts = [0, 0, 0];
  PLACEMENT_QUESTIONS.forEach((q) => { counts[q.answerIndex] += 1; });
  assert.ok(Math.max(...counts) <= 4, `answer positions too skewed: ${counts}`);
  assert.equal(typeof checkAnswerBalance, 'function');
});

test('all wrong places the learner at the floor', () => {
  const answers = PLACEMENT_QUESTIONS.map((q) => (q.answerIndex + 1) % q.options.length);
  assert.equal(levelFromPlacement(answers).level, 'A1');
});

test('all correct places the learner at the ceiling of the test', () => {
  const answers = PLACEMENT_QUESTIONS.map((q) => q.answerIndex);
  const { level, correct } = levelFromPlacement(answers);
  assert.equal(correct, 8);
  assert.equal(level, 'B2');
});

test('a partial score lands mid-scale', () => {
  const answers = PLACEMENT_QUESTIONS.map((q, i) => (i < 4 ? q.answerIndex : -1));
  assert.equal(levelFromPlacement(answers).level, 'A2');
});

test('a skipped placement falls back to the default level', () => {
  const { level } = levelFromPlacement([]);
  assert.equal(level, require('../lib/dailyLevels').DEFAULT_LEVEL);
});

test('the book follows from the level', () => {
  assert.equal(bookForLevel('A1'), 'elementary');
  assert.equal(bookForLevel('A2'), 'elementary');
  assert.equal(bookForLevel('B1'), 'intermediate');
  assert.equal(bookForLevel('C1'), 'intermediate');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/placementScoring.test.js`
Expected: FAIL — `Cannot find module '../lib/placementScoring'`

- [ ] **Step 3: Write minimal implementation**

Author the eight questions originally — do not lift them from a textbook.

```javascript
// lib/placementScoring.js
'use strict';

const { DEFAULT_LEVEL } = require('./dailyLevels');

// Eight original items, ascending. Answer positions are deliberately spread so
// the test cannot be passed by always choosing one column.
const PLACEMENT_QUESTIONS = [
  { id: 'p1', level: 'A1', prompt: 'She ___ to work every morning.',
    options: ['go', 'goes', 'going'], answerIndex: 1 },
  { id: 'p2', level: 'A1', prompt: 'There ___ two windows in this room.',
    options: ['are', 'is', 'be'], answerIndex: 0 },
  { id: 'p3', level: 'A2', prompt: 'I ___ my keys, so I had to wait outside.',
    options: ['am losing', 'lose', 'lost'], answerIndex: 2 },
  { id: 'p4', level: 'A2', prompt: 'This soup is ___ than the one we had yesterday.',
    options: ['saltier', 'more salty', 'saltiest'], answerIndex: 0 },
  { id: 'p5', level: 'B1', prompt: 'We ___ here since 2019.',
    options: ['live', 'have lived', 'are living'], answerIndex: 1 },
  { id: 'p6', level: 'B1', prompt: 'If it rains tomorrow, we ___ the picnic.',
    options: ['cancelled', 'will cancel', 'would cancel'], answerIndex: 1 },
  { id: 'p7', level: 'B2', prompt: 'By the time the guests arrived, she ___ everything.',
    options: ['had prepared', 'has prepared', 'was preparing'], answerIndex: 0 },
  { id: 'p8', level: 'B2', prompt: 'He denied ___ anything about the missing file.',
    options: ['to know', 'know', 'knowing'], answerIndex: 2 },
];

// The placement stops at B2; C1/C2 are not claimable from eight questions.
const LADDER = ['A1', 'A1', 'A2', 'A2', 'B1', 'B1', 'B2', 'B2', 'B2'];

const levelFromPlacement = (answers) => {
  const given = Array.isArray(answers) ? answers : [];
  if (given.length === 0) return { level: DEFAULT_LEVEL, book: bookForLevel(DEFAULT_LEVEL), correct: 0 };

  const correct = PLACEMENT_QUESTIONS.reduce(
    (n, q, i) => (given[i] === q.answerIndex ? n + 1 : n), 0
  );
  const level = LADDER[correct];
  return { level, book: bookForLevel(level), correct };
};

const bookForLevel = (level) => (level === 'A1' || level === 'A2' ? 'elementary' : 'intermediate');

module.exports = { PLACEMENT_QUESTIONS, levelFromPlacement, bookForLevel, LADDER };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/placementScoring.test.js`
Expected: PASS, 8 tests

- [ ] **Step 5: Commit**

```bash
git add lib/placementScoring.js test/placementScoring.test.js
git commit -m "feat(daily-pack): 8-question placement scoring"
```

---

### Task 6: Model changes

**Files:**
- Create: `models/GrammarMastery.js`, `models/LevelPlacement.js`
- Modify: `models/DailyItem.js`, `models/DailyDrop.js`, `models/DailyDropCompletion.js`, `models/VocabPack.js`
- Test: `test/dailyPackModels.test.js`

**Interfaces:**
- Consumes: `STATION_KINDS` (Task 1).
- Produces: Mongoose models `GrammarMastery`, `LevelPlacement`; widened `DailyDropCompletion.kind`; `DailyItem.syllabus`; `DailyDrop.weekKey/themePack/dayInWeek`; `VocabPack.level` accepting `'beginner'`.

- [ ] **Step 1: Write the failing test**

```javascript
// test/dailyPackModels.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const DailyItem = require('../models/DailyItem');
const DailyDrop = require('../models/DailyDrop');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const VocabPack = require('../models/VocabPack');
const GrammarMastery = require('../models/GrammarMastery');

let mongod;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'dailypack_models_test' });
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });

const userId = () => new mongoose.Types.ObjectId();

test('a completion accepts the new station kinds', async () => {
  for (const kind of ['listening', 'review', 'wrap', 'translate']) {
    const row = await DailyDropCompletion.create({
      user: userId(), dateKey: '2026-09-11', kind, score: 1,
    });
    assert.equal(row.kind, kind);
  }
});

test('a completion still accepts the legacy kinds prod already wrote', async () => {
  for (const kind of ['grammar', 'vocabulary']) {
    const row = await DailyDropCompletion.create({ user: userId(), dateKey: '2026-09-12', kind });
    assert.equal(row.kind, kind);
  }
});

test('a completion records which item it was', async () => {
  const item = new mongoose.Types.ObjectId();
  const row = await DailyDropCompletion.create({
    user: userId(), dateKey: '2026-09-11', kind: 'grammar', item,
  });
  assert.equal(String(row.item), String(item));
});

test('item stays optional so the 35 existing prod rows remain valid', async () => {
  const row = await DailyDropCompletion.create({ user: userId(), dateKey: '2026-09-11', kind: 'grammar' });
  assert.equal(row.item, undefined);
});

test('a daily item carries its syllabus position', async () => {
  const item = await DailyItem.create({
    language: 'en', level: 'A2', kind: 'grammar', title: 'present perfect',
    explanation: { en: 'x' },
    examples: [{ text: 'a' }, { text: 'b' }],
    quickCheck: [
      { prompt: 'q1', options: ['a', 'b', 'c'], answerIndex: 0 },
      { prompt: 'q2', options: ['a', 'b', 'c'], answerIndex: 1 },
      { prompt: 'q3', options: ['a', 'b', 'c'], answerIndex: 2 },
    ],
    source: 'curated',
    syllabus: { book: 'elementary', unit: 15, section: 'Present perfect' },
  });
  assert.equal(item.syllabus.unit, 15);
  assert.equal(item.syllabus.book, 'elementary');
});

test('a drop carries its week and theme', async () => {
  const pack = await VocabPack.create({
    level: 'intermediate', topic: 'Work & careers',
    words: [{ word: 'w', definition: 'd', example: 'e' }],
  });
  const drop = await DailyDrop.create({
    dateKey: '2026-09-11', language: 'en', level: 'A2',
    weekKey: '2026-W37', themePack: pack._id, dayInWeek: 5,
  });
  assert.equal(drop.weekKey, '2026-W37');
  assert.equal(String(drop.themePack), String(pack._id));
});

test('vocab packs accept the beginner level the A1 gap needs', async () => {
  const pack = await VocabPack.create({
    level: 'beginner', topic: 'Everyday objects',
    words: [{ word: 'cup', definition: 'a small container', example: 'a cup of tea' }],
  });
  assert.equal(pack.level, 'beginner');
});

test('grammar mastery is unique per user, language, book and unit', async () => {
  // init() waits for the unique index to exist; without it the second create
  // can succeed and the test passes for the wrong reason.
  await GrammarMastery.init();
  const user = userId();
  const base = { user, language: 'en', book: 'elementary', unit: 3, section: 'Past' };
  await GrammarMastery.create(base);
  await assert.rejects(() => GrammarMastery.create(base), /E11000/);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/dailyPackModels.test.js`
Expected: FAIL — `Cannot find module '../models/GrammarMastery'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// models/GrammarMastery.js
const mongoose = require('mongoose');

/**
 * Per-user progress through the grammar syllabus (spec §5.2). The cursor is
 * DERIVED from these rows by lib/grammarCursor.nextUnit — deliberately not
 * stored, so there is no second source of truth to drift or repair.
 */
const GrammarMasterySchema = new mongoose.Schema({
  user:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  language: { type: String, required: true },
  book:     { type: String, enum: ['elementary', 'intermediate'], required: true },
  unit:     { type: Number, required: true },
  section:  { type: String, default: '' },
  attempts: { type: Number, default: 0 },
  bestScore: { type: Number, default: 0 },
  // Distinct UTC day keys on which the learner passed. Two separate days are
  // required for mastery, so same-day retries cannot shortcut it.
  passDays: { type: [String], default: [] },
  perfect:  { type: Boolean, default: false },
  mastered: { type: Boolean, default: false },
  lastSeenDateKey: { type: String, default: null },
}, { timestamps: true });

GrammarMasterySchema.index({ user: 1, language: 1, book: 1, unit: 1 }, { unique: true });
// Supports the mastery aggregate in services/masteryService.js.
GrammarMasterySchema.index({ user: 1, language: 1, mastered: 1 });

module.exports = mongoose.model('GrammarMastery', GrammarMasterySchema);
```

```javascript
// models/LevelPlacement.js
const mongoose = require('mongoose');
const { LEVELS } = require('../lib/dailyLevels');

/**
 * Audit record for a placement run. User.languageLevel is the live value this
 * writes; this collection exists so a level can be explained ("you answered 5
 * of 8 on 11 Sep") and so scoring changes can be re-evaluated against history.
 */
const LevelPlacementSchema = new mongoose.Schema({
  user:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  language: { type: String, required: true },
  answers:  { type: [Number], default: [] },
  correct:  { type: Number, default: 0 },
  level:    { type: String, enum: LEVELS, required: true },
  book:     { type: String, enum: ['elementary', 'intermediate'], required: true },
  takenAt:  { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('LevelPlacement', LevelPlacementSchema);
```

Then the four edits:

```javascript
// models/DailyItem.js — add above `source`, inside DailyItemSchema
  // Position in the authored syllabus (spec §4.5). Present on grammar items;
  // absent on vocabulary items, which are theme-driven rather than sequential.
  syllabus: {
    book:    { type: String, enum: ['elementary', 'intermediate'], default: null },
    unit:    { type: Number, default: null },
    section: { type: String, default: '' },
  },
```

```javascript
// models/DailyItem.js — add after the existing indexes
// Sequential syllabus lookup for the per-learner grammar cursor.
DailyItemSchema.index({ language: 1, 'syllabus.book': 1, 'syllabus.unit': 1, approved: 1 });
```

```javascript
// models/DailyDrop.js — add to DailyDropSchema
  weekKey:   { type: String, default: null },   // 'YYYY-Www', from lib/dailyTheme
  themePack: { type: mongoose.Schema.Types.ObjectId, ref: 'VocabPack', default: null },
  dayInWeek: { type: Number, default: null },   // 1 = Monday ... 7 = Sunday
  // grammarItem is retained for the pre-pack rows but no longer written:
  // grammar is resolved per learner at read time (spec D7).
```

```javascript
// models/DailyDropCompletion.js — replace the KINDS import and the kind field
const { STATION_KINDS } = require('../lib/dailyStations');
// ...
  kind: { type: String, enum: STATION_KINDS, required: true },
  // Which item this completion was for. Nullable: the 35 rows written before
  // the pack existed have no item, and per-unit history simply starts now.
  item: { type: mongoose.Schema.Types.ObjectId, ref: 'DailyItem', default: undefined },
```

```javascript
// models/VocabPack.js — widen the level enum
    enum: ['beginner', 'intermediate', 'advanced'],
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/dailyPackModels.test.js`
Expected: PASS, 8 tests

- [ ] **Step 5: Run the whole suite — nothing else may break**

Run: `npm test`
Expected: the pre-existing `authSecretRotation` "both secrets meet the 32-char minimum" failure (local `JWT_SECRET` is 12 chars) and **no others**.

- [ ] **Step 6: Commit**

```bash
git add models/GrammarMastery.js models/LevelPlacement.js models/DailyItem.js \
        models/DailyDrop.js models/DailyDropCompletion.js models/VocabPack.js \
        test/dailyPackModels.test.js
git commit -m "feat(daily-pack): models for stations, syllabus, mastery and placement"
```

---

### Task 7a: Vocabulary and wrap check builder

Pack words carry no answer key, so `scoreQuickCheck` has nothing to score against
— without this the vocabulary and wrap stations would always return 0. This builds
`quickCheck`-shaped questions from pack words deterministically, so the same day
always produces the same questions and the server can score a submission it did
not send twice.

**Files:**
- Create: `lib/vocabChecks.js`
- Test: `test/vocabChecks.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `buildWordChecks(targets, pool, { optionCount = 3, seed = '' }): {prompt, options, answerIndex, targetWord}[]`

- [ ] **Step 1: Write the failing test**

```javascript
// test/vocabChecks.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { buildWordChecks } = require('../lib/vocabChecks');

const w = (n) => ({ word: `word${n}`, definition: `definition ${n}`, example: `Example ${n}.` });
const pool = Array.from({ length: 20 }, (_, i) => w(i));

test('one check per target word, asking the definition', () => {
  const checks = buildWordChecks([w(0), w(1)], pool, { seed: '2026-09-07' });
  assert.equal(checks.length, 2);
  assert.match(checks[0].prompt, /definition 0/);
});

test('the correct option is the target word and the key points at it', () => {
  const checks = buildWordChecks([w(3)], pool, { seed: '2026-09-07' });
  assert.equal(checks[0].options[checks[0].answerIndex], 'word3');
});

test('distractors come from the pool and never repeat the answer', () => {
  const checks = buildWordChecks([w(3)], pool, { seed: '2026-09-07' });
  assert.equal(checks[0].options.length, 3);
  assert.equal(new Set(checks[0].options).size, 3);
});

test('the same seed always builds the same questions', () => {
  const a = buildWordChecks([w(3), w(4)], pool, { seed: '2026-09-07' });
  const b = buildWordChecks([w(3), w(4)], pool, { seed: '2026-09-07' });
  assert.deepEqual(a, b);
});

test('a different seed moves the answer position, so no column is always right', () => {
  const positions = new Set();
  for (const seed of ['2026-09-07', '2026-09-08', '2026-09-09', '2026-09-10', '2026-09-11']) {
    buildWordChecks(pool.slice(0, 5), pool, { seed }).forEach((c) => positions.add(c.answerIndex));
  }
  assert.ok(positions.size >= 2, `answer always landed in position(s) ${[...positions]}`);
});

test('a pool too small for distractors yields fewer options rather than duplicates', () => {
  const checks = buildWordChecks([w(0)], [w(0), w(1)], { seed: 's' });
  assert.equal(new Set(checks[0].options).size, checks[0].options.length);
  assert.ok(checks[0].options.includes('word0'));
});

test('no targets yields no checks', () => {
  assert.deepEqual(buildWordChecks([], pool, { seed: 's' }), []);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/vocabChecks.test.js`
Expected: FAIL — `Cannot find module '../lib/vocabChecks'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/vocabChecks.js
'use strict';

/**
 * Deterministic definition-to-word questions built from pack words.
 *
 * Pack words have no answer key, so the vocabulary and wrap stations would be
 * unscorable without this. Determinism matters twice: the learner must see the
 * same questions if they reopen the station, and completion re-derives the key
 * server-side rather than trusting anything the client returns.
 *
 * The seed also rotates the answer position, so the fairness problem measured
 * in the authored bank (59% of answers in one column) cannot reappear here.
 */

// Small deterministic string hash — no Math.random, so runs are reproducible.
const hash = (str) => {
  let h = 2166136261;
  for (let i = 0; i < str.length; i += 1) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return Math.abs(h);
};

const buildWordChecks = (targets, pool, { optionCount = 3, seed = '' } = {}) =>
  (targets || []).map((target, i) => {
    const distractors = (pool || [])
      .filter((p) => p.word !== target.word)
      .sort((a, b) => hash(`${seed}:${a.word}`) - hash(`${seed}:${b.word}`))
      .slice(0, Math.max(0, optionCount - 1))
      .map((p) => p.word);

    const options = [...distractors];
    const answerIndex = hash(`${seed}:${target.word}:${i}`) % (options.length + 1);
    options.splice(answerIndex, 0, target.word);

    return {
      prompt: `Which word means "${target.definition}"?`,
      options,
      answerIndex,
      targetWord: target.word,
    };
  });

module.exports = { buildWordChecks, hash };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/vocabChecks.test.js`
Expected: PASS, 7 tests

- [ ] **Step 5: Commit**

```bash
git add lib/vocabChecks.js test/vocabChecks.test.js
git commit -m "feat(daily-pack): deterministic word checks for vocabulary and wrap"
```

---

### Task 7: Pack composition service

**Files:**
- Create: `services/dailyPackService.js`
- Test: `test/dailyPackService.test.js`

**Interfaces:**
- Consumes: `stationsForDay`, `isPackComplete` (Task 1); `themeIndexFor`, `wordSliceFor`, `weekKeyFor`, `dayInWeek` (Task 2); `nextUnit` (Task 3); `bookForLevel` (Task 5); models from Task 6; `resolveLevelWithFallback` from `lib/dailyLevels.js`.
- Produces: `buildPack({ userId, language, level, dateKey, locale }): Promise<Pack>` where

```
Pack = {
  dateKey, weekKey, dayInWeek, language, requestedLevel, servedLevel,
  theme: { id, topic, level } | null,
  stations: [{ kind, status: 'todo'|'done'|'empty', score, total, payload }],
  packComplete: boolean,
}
```

- [ ] **Step 1: Write the failing test**

```javascript
// test/dailyPackService.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const VocabPack = require('../models/VocabPack');
const DailyItem = require('../models/DailyItem');
const Vocabulary = require('../models/Vocabulary');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const GrammarMastery = require('../models/GrammarMastery');
const { buildPack } = require('../services/dailyPackService');

let mongod;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'dailypack_service_test' });
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });

test.beforeEach(async () => {
  await Promise.all([
    VocabPack.deleteMany({}), DailyItem.deleteMany({}), Vocabulary.deleteMany({}),
    DailyDropCompletion.deleteMany({}), GrammarMastery.deleteMany({}),
  ]);
});

const words = (n) => Array.from({ length: n }, (_, i) => ({
  word: `word${i}`, definition: `definition ${i}`, example: `Example sentence ${i}.`,
}));

const quickCheck = () => [
  { prompt: 'q1', options: ['a', 'b', 'c'], answerIndex: 0 },
  { prompt: 'q2', options: ['a', 'b', 'c'], answerIndex: 1 },
  { prompt: 'q3', options: ['a', 'b', 'c'], answerIndex: 2 },
];

const seedGrammar = (unit) => DailyItem.create({
  language: 'en', level: 'A2', kind: 'grammar', title: `unit ${unit}`,
  explanation: { en: 'explanation' }, examples: [{ text: 'one' }, { text: 'two' }],
  quickCheck: quickCheck(), source: 'curated', approved: true,
  syllabus: { book: 'elementary', unit, section: 'Present' },
});

test('a Monday pack serves the first five words of the theme', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'Work & careers', words: words(20) });
  await seedGrammar(1);
  const pack = await buildPack({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-07',
  });
  const vocab = pack.stations.find((s) => s.kind === 'vocabulary');
  assert.equal(pack.theme.topic, 'Work & careers');
  assert.deepEqual(vocab.payload.words.map((w) => w.word), ['word0','word1','word2','word3','word4']);
});

test('Thursday serves the last five words of the same theme', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'Work & careers', words: words(20) });
  await seedGrammar(1);
  const pack = await buildPack({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-10',
  });
  const vocab = pack.stations.find((s) => s.kind === 'vocabulary');
  assert.deepEqual(vocab.payload.words.map((w) => w.word), ['word15','word16','word17','word18','word19']);
});

test('Friday serves the wrap quiz over the whole week instead of new words', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'Work & careers', words: words(20) });
  await seedGrammar(1);
  const pack = await buildPack({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-11',
  });
  assert.equal(pack.stations.some((s) => s.kind === 'vocabulary'), false);
  const wrap = pack.stations.find((s) => s.kind === 'wrap');
  assert.ok(wrap.payload.questions.length > 0);
});

test('grammar follows the learner cursor, not the calendar', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'T', words: words(20) });
  await seedGrammar(1); await seedGrammar(2); await seedGrammar(3);
  const user = new mongoose.Types.ObjectId();
  await GrammarMastery.create({
    user, language: 'en', book: 'elementary', unit: 1, mastered: true, lastSeenDateKey: '2026-09-01',
  });
  const pack = await buildPack({ userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07' });
  const grammar = pack.stations.find((s) => s.kind === 'grammar');
  assert.equal(grammar.payload.unit, 2, 'mastered unit 1 must be skipped');
});

test('two learners on the same day can be on different grammar units', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'T', words: words(20) });
  await seedGrammar(1); await seedGrammar(2);
  const ahead = new mongoose.Types.ObjectId();
  await GrammarMastery.create({
    user: ahead, language: 'en', book: 'elementary', unit: 1, mastered: true, lastSeenDateKey: '2026-09-01',
  });
  const a = await buildPack({ userId: ahead, language: 'en', level: 'A2', dateKey: '2026-09-07' });
  const b = await buildPack({ userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-07' });
  assert.equal(a.stations.find((s) => s.kind === 'grammar').payload.unit, 2);
  assert.equal(b.stations.find((s) => s.kind === 'grammar').payload.unit, 1);
});

test('the review station is empty for a learner with no due words', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'T', words: words(20) });
  await seedGrammar(1);
  const pack = await buildPack({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-07',
  });
  assert.equal(pack.stations.find((s) => s.kind === 'review').status, 'empty');
});

test('the review station serves due words when they exist', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'T', words: words(20) });
  await seedGrammar(1);
  const user = new mongoose.Types.ObjectId();
  await Vocabulary.create({
    user, word: 'reluctant', translation: 'unwilling', language: 'en',
    nextReview: new Date('2026-09-01'), isArchived: false, isMastered: false,
    srsLevel: 1, easeFactor: 2.5, interval: 1,
  });
  const pack = await buildPack({ userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07' });
  const review = pack.stations.find((s) => s.kind === 'review');
  assert.equal(review.status, 'todo');
  assert.equal(review.payload.words[0].word, 'reluctant');
});

test('a day with an empty review station can still be complete', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'T', words: words(20) });
  await seedGrammar(1);
  const user = new mongoose.Types.ObjectId();
  for (const kind of ['vocabulary', 'grammar', 'listening']) {
    await DailyDropCompletion.create({ user, dateKey: '2026-09-07', kind, score: 3 });
  }
  const pack = await buildPack({ userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07' });
  assert.equal(pack.packComplete, true);
});

test('listening derives two clips from the theme without any new content', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'T', words: words(20) });
  await seedGrammar(1);
  const pack = await buildPack({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-07',
  });
  const listening = pack.stations.find((s) => s.kind === 'listening');
  assert.equal(listening.payload.clips.length, 2);
  assert.ok(listening.payload.clips[0].text.length > 0);
});

test('no vocab pack at all yields an honest empty theme rather than a crash', async () => {
  await seedGrammar(1);
  const pack = await buildPack({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-07',
  });
  assert.equal(pack.theme, null);
  assert.equal(pack.stations.find((s) => s.kind === 'vocabulary').status, 'empty');
});

test('answer indexes never reach the client', async () => {
  await VocabPack.create({ level: 'intermediate', topic: 'T', words: words(20) });
  await seedGrammar(1);
  const pack = await buildPack({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', dateKey: '2026-09-07',
  });
  assert.equal(JSON.stringify(pack).includes('answerIndex'), false);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/dailyPackService.test.js`
Expected: FAIL — `Cannot find module '../services/dailyPackService'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// services/dailyPackService.js
'use strict';

const VocabPack = require('../models/VocabPack');
const DailyItem = require('../models/DailyItem');
const Vocabulary = require('../models/Vocabulary');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const GrammarMastery = require('../models/GrammarMastery');

const { stationsForDay, isPackComplete } = require('../lib/dailyStations');
const { weekKeyFor, dayInWeek, themeIndexFor, wordSliceFor } = require('../lib/dailyTheme');
const { nextUnit } = require('../lib/grammarCursor');
const { bookForLevel } = require('../lib/placementScoring');
const { buildWordChecks } = require('../lib/vocabChecks');

const REVIEW_LIMIT = 5;
const LISTENING_CLIPS = 2;
const WRAP_QUESTIONS = 10;

// CEFR level -> which pack grading serves it (spec §4.3).
const PACK_LEVELS_FOR_CEFR = {
  A1: ['beginner'],
  A2: ['beginner', 'intermediate'],
  B1: ['intermediate'],
  B2: ['advanced'],
  C1: ['advanced'],
  C2: ['advanced'],
};

/** Deterministic theme for this (level, week) — no scheduling state. */
const resolveTheme = async ({ level, dateKey }) => {
  const packLevels = PACK_LEVELS_FOR_CEFR[level] || ['intermediate'];
  const packs = await VocabPack.find({ level: { $in: packLevels }, isActive: true })
    .sort({ _id: 1 }).lean();
  const index = themeIndexFor(dateKey, packs.length);
  return index === null ? null : packs[index];
};

const resolveGrammar = async ({ userId, language, level, dateKey }) => {
  const book = bookForLevel(level);
  const units = await DailyItem.find({
    language, kind: 'grammar', approved: true, 'syllabus.book': book,
  }).select('syllabus').lean();
  if (units.length === 0) return null;

  const mastery = await GrammarMastery.find({ user: userId, language, book })
    .select('unit mastered lastSeenDateKey passDays perfect').lean();

  const unit = nextUnit({
    units: units.map((u) => u.syllabus.unit), mastery, todayKey: dateKey,
  });
  if (unit === null) return null;

  return DailyItem.findOne({
    language, kind: 'grammar', approved: true, 'syllabus.book': book, 'syllabus.unit': unit,
  }).lean();
};

const serializeChecks = (quickCheck) =>
  (quickCheck || []).map((q) => ({ prompt: q.prompt, options: q.options }));

const explanationFor = (item, locale) => {
  const ex = item.explanation;
  if (!ex) return '';
  if (ex instanceof Map) return ex.get(locale) || ex.get('en') || '';
  return ex[locale] || ex.en || '';
};

const buildPack = async ({ userId, language, level, dateKey, locale = 'en' }) => {
  const applicable = stationsForDay(dateKey);
  const theme = await resolveTheme({ level, dateKey });
  const grammarItem = applicable.includes('grammar')
    ? await resolveGrammar({ userId, language, level, dateKey })
    : null;

  const completions = await DailyDropCompletion.find({ user: userId, dateKey })
    .select('kind score item').lean();
  const doneByKind = new Map(completions.map((c) => [c.kind, c]));

  const dueWords = await Vocabulary.find({
    user: userId, isArchived: false, isMastered: false,
    nextReview: { $lte: new Date(`${dateKey}T23:59:59Z`) },
  }).sort({ nextReview: 1 }).limit(REVIEW_LIMIT).lean();

  const themeWords = theme ? wordSliceFor(theme.words, dateKey) : [];
  const clipSource = theme ? (theme.words || []).slice(0, LISTENING_CLIPS) : [];

  const payloads = {
    vocabulary: () => (themeWords.length === 0 ? null : {
      words: themeWords.map((w) => ({
        word: w.word, definition: w.definition, example: w.example,
        translationHint: w.translationHint || '',
      })),
      // answerIndex is stripped — completion re-derives the key server-side.
      checks: buildWordChecks(themeWords, theme.words, { seed: dateKey })
        .map((c) => ({ prompt: c.prompt, options: c.options })),
    }),
    grammar: () => (!grammarItem ? null : {
      itemId: grammarItem._id,
      unit: grammarItem.syllabus.unit,
      section: grammarItem.syllabus.section,
      title: grammarItem.title,
      explanation: explanationFor(grammarItem, locale),
      examples: (grammarItem.examples || []).map((e) => ({ text: e.text })),
      checks: serializeChecks(grammarItem.quickCheck),
    }),
    listening: () => (clipSource.length === 0 ? null : {
      clips: clipSource.map((w, i) => ({ id: `${dateKey}-${i}`, text: w.example, word: w.word })),
    }),
    review: () => (dueWords.length === 0 ? null : {
      words: dueWords.map((v) => ({
        id: v._id, word: v.word, translation: v.translation, srsLevel: v.srsLevel,
      })),
    }),
    wrap: () => (!theme ? null : {
      // The whole week's 20 words, mixed. answerIndex withheld as everywhere.
      questions: buildWordChecks(
        (theme.words || []).slice(0, WRAP_QUESTIONS), theme.words, { seed: `wrap-${dateKey}` }
      ).map((c) => ({ prompt: c.prompt, options: c.options })),
    }),
    translate: () => (!theme ? null : {
      // The existing AI-graded daily-practice path supplies the sentence; the
      // station only needs a prompt to render.
      prompt: (theme.words[0] && theme.words[0].example) || '',
    }),
  };

  const emptyStations = [];
  const stations = applicable.map((kind) => {
    const payload = (payloads[kind] || (() => null))();
    const done = doneByKind.get(kind);
    if (!payload) emptyStations.push(kind);
    return {
      kind,
      status: done ? 'done' : (payload ? 'todo' : 'empty'),
      score: done ? done.score : null,
      payload,
    };
  });

  return {
    dateKey,
    weekKey: weekKeyFor(dateKey),
    dayInWeek: dayInWeek(dateKey),
    language,
    requestedLevel: level,
    servedLevel: grammarItem ? grammarItem.level : level,
    theme: theme ? { id: theme._id, topic: theme.topic, level: theme.level } : null,
    stations,
    packComplete: isPackComplete(applicable, completions, emptyStations),
  };
};

module.exports = { buildPack, resolveTheme, resolveGrammar, PACK_LEVELS_FOR_CEFR };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/dailyPackService.test.js`
Expected: PASS, 11 tests

- [ ] **Step 5: Commit**

```bash
git add services/dailyPackService.js test/dailyPackService.test.js
git commit -m "feat(daily-pack): compose the day's four stations per learner"
```

---

### Task 8: Station completion, SRS enrolment and XP

**Files:**
- Modify: `controllers/dailyStudy.js` (add `getDailyPack`, `completeStation`)
- Modify: `routes/dailyStudy.js`
- Test: `test/dailyPackCompletion.test.js`

**Interfaces:**
- Consumes: `buildPack` (Task 7); `applyAttempt` (Task 3); `applyReview` from `lib/srsEngine.js`; `learningTrackingService.awardXPWithStreak`.
- Produces:
  - `GET /api/v1/study/pack` → the `Pack` shape from Task 7
  - `POST /api/v1/study/pack/:station/complete` with body `{ answers: number[] }` → `{ score, total, packComplete, xpAwarded, streak, stationsRemaining }`

- [ ] **Step 1: Write the failing test**

```javascript
// test/dailyPackCompletion.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const Vocabulary = require('../models/Vocabulary');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const GrammarMastery = require('../models/GrammarMastery');
const { completeStationForUser } = require('../services/dailyPackService');

let mongod;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'dailypack_complete_test' });
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([
    Vocabulary.deleteMany({}), DailyDropCompletion.deleteMany({}), GrammarMastery.deleteMany({}),
  ]);
});

test('finishing the vocabulary station enrols its words into SRS', async () => {
  const user = new mongoose.Types.ObjectId();
  await completeStationForUser({
    userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07', station: 'vocabulary',
    answers: [0, 0, 0, 0, 0],
    words: [
      { word: 'ambition', definition: 'a strong wish', example: 'Her ambition is clear.' },
      { word: 'colleague', definition: 'someone you work with', example: 'My colleague helped.' },
    ],
  });
  const saved = await Vocabulary.find({ user }).lean();
  assert.equal(saved.length, 2);
  assert.equal(saved[0].srsLevel, 0, 'new words enter SRS at level 0');
  assert.ok(saved[0].nextReview, 'and are scheduled for review');
});

test('re-finishing the same station on the same day does not duplicate words', async () => {
  const user = new mongoose.Types.ObjectId();
  const args = {
    userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07', station: 'vocabulary',
    answers: [0], words: [{ word: 'ambition', definition: 'd', example: 'e' }],
  };
  await completeStationForUser(args);
  await completeStationForUser(args);
  assert.equal((await Vocabulary.find({ user }).lean()).length, 1);
  assert.equal((await DailyDropCompletion.find({ user, kind: 'vocabulary' }).lean()).length, 1);
});

test('a grammar station records an attempt against the unit', async () => {
  const user = new mongoose.Types.ObjectId();
  await completeStationForUser({
    userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07', station: 'grammar',
    answers: [0, 1, 2], quickCheck: [
      { options: ['a','b','c'], answerIndex: 0 },
      { options: ['a','b','c'], answerIndex: 1 },
      { options: ['a','b','c'], answerIndex: 2 },
    ], unit: 4, section: 'Past', book: 'elementary',
  });
  const row = await GrammarMastery.findOne({ user, unit: 4 }).lean();
  assert.equal(row.attempts, 1);
  assert.equal(row.bestScore, 3);
  assert.equal(row.mastered, true, '3 of 3 masters on the first attempt');
});

test('a wrong grammar attempt is recorded without mastering', async () => {
  const user = new mongoose.Types.ObjectId();
  await completeStationForUser({
    userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07', station: 'grammar',
    answers: [1, 1, 1], quickCheck: [
      { options: ['a','b','c'], answerIndex: 0 },
      { options: ['a','b','c'], answerIndex: 1 },
      { options: ['a','b','c'], answerIndex: 2 },
    ], unit: 4, section: 'Past', book: 'elementary',
  });
  const row = await GrammarMastery.findOne({ user, unit: 4 }).lean();
  assert.equal(row.mastered, false);
  assert.equal(row.bestScore, 1);
  assert.equal(row.lastSeenDateKey, '2026-09-07');
});

test('the review station advances SRS through the shared engine', async () => {
  const user = new mongoose.Types.ObjectId();
  const word = await Vocabulary.create({
    user, word: 'reluctant', translation: 'unwilling', language: 'en',
    srsLevel: 1, easeFactor: 2.5, interval: 1,
    nextReview: new Date('2026-09-01'), isArchived: false, isMastered: false,
  });
  await completeStationForUser({
    userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07', station: 'review',
    reviews: [{ id: String(word._id), correct: true }],
  });
  const after = await Vocabulary.findById(word._id).lean();
  assert.ok(after.srsLevel > 1, 'a correct review promotes the word');
  assert.ok(new Date(after.nextReview) > new Date('2026-09-07'));
});

test('the score is computed server-side from the stored answer key', async () => {
  const user = new mongoose.Types.ObjectId();
  const result = await completeStationForUser({
    userId: user, language: 'en', level: 'A2', dateKey: '2026-09-07', station: 'grammar',
    answers: [0, 0, 0], quickCheck: [
      { options: ['a','b','c'], answerIndex: 0 },
      { options: ['a','b','c'], answerIndex: 1 },
      { options: ['a','b','c'], answerIndex: 2 },
    ], unit: 1, section: 'Present', book: 'elementary',
  });
  assert.equal(result.score, 1);
  assert.equal(result.total, 3);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/dailyPackCompletion.test.js`
Expected: FAIL — `completeStationForUser is not a function`

- [ ] **Step 3: Write minimal implementation**

Append to `services/dailyPackService.js`:

```javascript
const { applyAttempt } = require('../lib/grammarCursor');
const { applyReview } = require('../lib/srsEngine');
const { scoreQuickCheck } = require('../lib/dailyCompletion');
const learningTracking = require('./learningTrackingService');

const STATION_XP = { vocabulary: 10, grammar: 10, listening: 10, review: 5, wrap: 15, translate: 10 };

/**
 * Commit one station. Each station commits independently so an abandoned
 * session keeps whatever the learner finished — 21 of the 23 learners who ever
 * opened the old drop never came back, and losing partial work is one reason to
 * not bother returning.
 *
 * The unique (user, dateKey, kind) index makes this idempotent: a retry
 * re-reports the score without double-writing SRS rows or double-awarding XP.
 */
const completeStationForUser = async ({
  userId, language, level, dateKey, station,
  answers = [], quickCheck = [], words = [], reviews = [],
  unit = null, section = '', book = null,
}) => {
  const existing = await DailyDropCompletion.findOne({ user: userId, dateKey, kind: station }).lean();

  let score = 0;
  let total = 0;

  if (station === 'grammar' || station === 'wrap' || station === 'vocabulary') {
    total = quickCheck.length || answers.length;
    score = quickCheck.length ? scoreQuickCheck(quickCheck, answers) : 0;
  } else if (station === 'review') {
    total = reviews.length;
    score = reviews.filter((r) => r.correct).length;
  } else {
    total = answers.length;
    score = answers.filter((a) => a === 1).length;
  }

  if (existing) {
    return { score: existing.score, total, alreadyDone: true, xpAwarded: 0 };
  }

  await DailyDropCompletion.updateOne(
    { user: userId, dateKey, kind: station },
    { $setOnInsert: { user: userId, dateKey, kind: station, score, completedAt: new Date() } },
    { upsert: true }
  );

  // New words enter SRS so they return in the review station two days later —
  // this is the loop that makes review non-empty by day 2.
  if (station === 'vocabulary' && words.length) {
    await Vocabulary.bulkWrite(words.map((w) => ({
      updateOne: {
        filter: { user: userId, word: w.word },
        update: {
          $setOnInsert: {
            user: userId, word: w.word, translation: w.definition, language,
            notes: w.definition, examples: w.example ? [{ sentence: w.example }] : [],
            context: { source: 'daily_pack' },
            srsLevel: 0, easeFactor: 2.5, interval: 0, nextReview: new Date(),
            isArchived: false, isMastered: false,
          },
        },
        upsert: true,
      },
    })), { ordered: false });
  }

  if (station === 'grammar' && unit !== null && book) {
    const row = await GrammarMastery.findOne({ user: userId, language, book, unit });
    const next = applyAttempt(row ? row.toObject() : null, { score, total, dateKey });
    await GrammarMastery.updateOne(
      { user: userId, language, book, unit },
      { $set: { ...next, section } },
      { upsert: true }
    );
  }

  if (station === 'review' && reviews.length) {
    for (const r of reviews) {
      const v = await Vocabulary.findOne({ _id: r.id, user: userId });
      if (!v) continue;
      const updated = applyReview(v.toObject(), r.correct ? 5 : 2);
      await Vocabulary.updateOne({ _id: v._id }, { $set: updated });
    }
  }

  const xp = STATION_XP[station] || 0;
  const award = xp > 0
    ? await learningTracking.awardXPWithStreak(userId, xp, `daily_pack_${station}`, language)
    : null;

  return {
    score,
    total,
    alreadyDone: false,
    xpAwarded: (award && award.xpAwarded) || 0,
    streak: award && award.streakResult ? award.streakResult.currentStreak : null,
  };
};

module.exports.completeStationForUser = completeStationForUser;
module.exports.STATION_XP = STATION_XP;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/dailyPackCompletion.test.js`
Expected: PASS, 6 tests

- [ ] **Step 5: Wire the controller and routes**

```javascript
// controllers/dailyStudy.js — add near the other requires
const { buildPack, completeStationForUser, answerKeyFor } = require('../services/dailyPackService');
const { STATION_KINDS } = require('../lib/dailyStations');

// @desc    Today's four-station pack for the caller
// @route   GET /api/v1/study/pack
exports.getDailyPack = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.user.id).select('language_to_learn languageLevel');
  const { language, level } = resolveTarget(user, req.query);
  if (!language) {
    return res.status(200).json({ success: true, data: { needsLanguage: true } });
  }
  const pack = await buildPack({
    userId: req.user.id, language, level,
    dateKey: toDateKey(new Date()), locale: req.query.locale || 'en',
  });
  res.status(200).json({ success: true, data: pack });
});

// @desc    Commit one station
// @route   POST /api/v1/study/pack/:station/complete
exports.completeStation = asyncHandler(async (req, res, next) => {
  const { station } = req.params;
  if (!STATION_KINDS.includes(station)) {
    return next(new ErrorResponse(`station must be one of ${STATION_KINDS.join(', ')}`, 400));
  }
  const user = await User.findById(req.user.id).select('language_to_learn languageLevel');
  const { language, level } = resolveTarget(user);
  // dateKey is server-derived; a client-supplied date would let a caller farm
  // streak and XP with a fabricated sequence.
  const dateKey = toDateKey(new Date());

  // Re-derive the day's content so answers are scored against the server's
  // own key rather than anything the client sent.
  const pack = await buildPack({ userId: req.user.id, language, level, dateKey });
  const slot = pack.stations.find((s) => s.kind === station);
  if (!slot) return next(new ErrorResponse('station does not apply today', 400));
  if (!slot.payload) return next(new ErrorResponse('station is empty today', 400));

  const source = await answerKeyFor({
    station, pack, userId: req.user.id, language, level, dateKey,
  });

  const result = await completeStationForUser({
    userId: req.user.id, language, level, dateKey, station,
    answers: Array.isArray(req.body.answers) ? req.body.answers : [],
    reviews: Array.isArray(req.body.reviews) ? req.body.reviews : [],
    ...source,
  });

  const after = await buildPack({ userId: req.user.id, language, level, dateKey });
  res.status(200).json({
    success: true,
    data: {
      ...result,
      packComplete: after.packComplete,
      stationsRemaining: after.stations.filter((s) => s.status === 'todo').map((s) => s.kind),
    },
  });
});
```

Add `answerKeyFor` to `services/dailyPackService.js` — the answer key never leaves the server, so it is fetched separately from the serialized payload:

```javascript
/**
 * The scoring key for a station, loaded server-side. buildPack deliberately
 * strips answerIndex from what the client sees, so completion re-reads it here.
 */
const answerKeyFor = async ({ station, pack, userId, language, level, dateKey }) => {
  if (station === 'grammar') {
    const item = await resolveGrammar({ userId, language, level, dateKey });
    return item
      ? { quickCheck: item.quickCheck, unit: item.syllabus.unit, section: item.syllabus.section,
          book: item.syllabus.book }
      : {};
  }
  if (station === 'vocabulary') {
    const theme = await resolveTheme({ level, dateKey });
    if (!theme) return { words: [], quickCheck: [] };
    const words = wordSliceFor(theme.words, dateKey);
    // Same seed as buildPack, so the key matches the questions the learner saw.
    return { words, quickCheck: buildWordChecks(words, theme.words, { seed: dateKey }) };
  }
  if (station === 'wrap') {
    const theme = await resolveTheme({ level, dateKey });
    if (!theme) return { words: [], quickCheck: [] };
    return {
      words: theme.words || [],
      quickCheck: buildWordChecks(
        (theme.words || []).slice(0, WRAP_QUESTIONS), theme.words, { seed: `wrap-${dateKey}` }
      ),
    };
  }
  return {};
};

module.exports.answerKeyFor = answerKeyFor;
```

```javascript
// routes/dailyStudy.js — replace the destructured import and add routes
const {
  getDailyDrop, completeDailyItem, submitDailyFeedback, getDailyArchive,
  getDailyPack, completeStation,
} = require('../controllers/dailyStudy');

// The pack. The /daily routes below stay for app builds already in the field.
router.get('/pack', getDailyPack);
router.post('/pack/:station/complete', completeStation);
```

- [ ] **Step 6: Run the whole suite**

Run: `npm test`
Expected: only the pre-existing `JWT_SECRET` failure.

- [ ] **Step 7: Commit**

```bash
git add services/dailyPackService.js controllers/dailyStudy.js routes/dailyStudy.js \
        test/dailyPackCompletion.test.js
git commit -m "feat(daily-pack): per-station completion with SRS enrolment and XP"
```

---

### Task 9: Placement endpoints

**Files:**
- Modify: `controllers/dailyStudy.js`, `routes/dailyStudy.js`
- Test: `test/placementEndpoints.test.js`

**Interfaces:**
- Consumes: `PLACEMENT_QUESTIONS`, `levelFromPlacement` (Task 5); `LevelPlacement` (Task 6).
- Produces:
  - `GET /api/v1/study/placement` → `{ questions: [{id, prompt, options}] }` (no answer keys)
  - `POST /api/v1/study/placement` body `{ answers: number[] }` → `{ level, book, correct }`, writes `User.languageLevel` and a `LevelPlacement` row

- [ ] **Step 1: Write the failing test**

```javascript
// test/placementEndpoints.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { PLACEMENT_QUESTIONS } = require('../lib/placementScoring');
const { serializePlacement, applyPlacement } = require('../controllers/dailyStudy');

test('serialized placement questions carry no answer key', () => {
  const out = serializePlacement();
  assert.equal(out.length, 8);
  assert.equal(JSON.stringify(out).includes('answerIndex'), false);
  assert.ok(out[0].prompt && out[0].options.length >= 3);
});

test('applyPlacement turns answers into a level and a book', () => {
  const answers = PLACEMENT_QUESTIONS.map((q) => q.answerIndex);
  const out = applyPlacement(answers);
  assert.equal(out.correct, 8);
  assert.equal(out.level, 'B2');
  assert.equal(out.book, 'intermediate');
});

test('a skipped placement yields the default level, not a crash', () => {
  const out = applyPlacement([]);
  assert.equal(out.level, require('../lib/dailyLevels').DEFAULT_LEVEL);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/placementEndpoints.test.js`
Expected: FAIL — `serializePlacement is not a function`

- [ ] **Step 3: Write minimal implementation**

```javascript
// controllers/dailyStudy.js — add
const LevelPlacement = require('../models/LevelPlacement');
const { PLACEMENT_QUESTIONS, levelFromPlacement } = require('../lib/placementScoring');

/** Questions without their answer key — exported for direct unit testing. */
exports.serializePlacement = () =>
  PLACEMENT_QUESTIONS.map((q) => ({ id: q.id, prompt: q.prompt, options: q.options }));

/** Pure scoring wrapper, exported so the mapping is testable without HTTP. */
exports.applyPlacement = (answers) => levelFromPlacement(answers);

// @desc    The placement questions
// @route   GET /api/v1/study/placement
exports.getPlacement = asyncHandler(async (req, res) => {
  res.status(200).json({ success: true, data: { questions: exports.serializePlacement() } });
});

// @desc    Submit placement answers; sets the caller's level
// @route   POST /api/v1/study/placement
exports.submitPlacement = asyncHandler(async (req, res, next) => {
  const answers = Array.isArray(req.body.answers) ? req.body.answers : [];
  if (answers.length > PLACEMENT_QUESTIONS.length) {
    return next(new ErrorResponse('too many answers', 400));
  }
  const user = await User.findById(req.user.id).select('language_to_learn languageLevel');
  const { language } = resolveTarget(user);
  const { level, book, correct } = exports.applyPlacement(answers);

  await User.updateOne({ _id: req.user.id }, { $set: { languageLevel: level } });
  await LevelPlacement.create({
    user: req.user.id, language: language || 'en', answers, correct, level, book,
  });

  res.status(200).json({ success: true, data: { level, book, correct, total: PLACEMENT_QUESTIONS.length } });
});
```

```javascript
// routes/dailyStudy.js — add to the destructured import and the routes
  getPlacement, submitPlacement,
// ...
router.get('/placement', getPlacement);
router.post('/placement', submitPlacement);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/placementEndpoints.test.js`
Expected: PASS, 3 tests

- [ ] **Step 5: Commit**

```bash
git add controllers/dailyStudy.js routes/dailyStudy.js test/placementEndpoints.test.js
git commit -m "feat(daily-pack): placement endpoints set the learner's level"
```

---

### Task 10: Mastery endpoint

**Files:**
- Create: `services/masteryService.js`
- Modify: `controllers/learning.js`, `routes/learning.js`
- Test: `test/masteryService.test.js`

**Interfaces:**
- Consumes: `Vocabulary`, `GrammarMastery`, `DailyDropCompletion`, `DailyItem`; `bookForLevel` (Task 5).
- Produces: `buildMastery({ userId, language, level, todayKey }): Promise<Mastery>` and `GET /api/v1/learning/mastery`, where

```
Mastery = {
  level, book,
  vocabulary: { mastered, learning, fresh, due },
  grammar: { mastered, total, sections: [{ section, mastered, total }] },
  listening: { accuracy, samples },
  translate: { accuracy, samples },
  consistency: { days: ['YYYY-MM-DD'], currentStreak },
}
```

- [ ] **Step 1: Write the failing test**

```javascript
// test/masteryService.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const Vocabulary = require('../models/Vocabulary');
const GrammarMastery = require('../models/GrammarMastery');
const DailyItem = require('../models/DailyItem');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const { buildMastery } = require('../services/masteryService');

let mongod;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'mastery_test' });
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([
    Vocabulary.deleteMany({}), GrammarMastery.deleteMany({}),
    DailyItem.deleteMany({}), DailyDropCompletion.deleteMany({}),
  ]);
});

const vocab = (user, over = {}) => Vocabulary.create({
  user, word: `w${Math.random()}`, translation: 't', language: 'en',
  srsLevel: 0, easeFactor: 2.5, interval: 0, nextReview: new Date('2030-01-01'),
  isArchived: false, isMastered: false, ...over,
});

test('vocabulary buckets split mastered, learning, fresh and due', async () => {
  const user = new mongoose.Types.ObjectId();
  await vocab(user, { srsLevel: 9, isMastered: true });
  await vocab(user, { srsLevel: 4 });
  await vocab(user, { srsLevel: 0 });
  await vocab(user, { srsLevel: 2, nextReview: new Date('2020-01-01') });
  const m = await buildMastery({ userId: user, language: 'en', level: 'A2', todayKey: '2026-09-11' });
  assert.equal(m.vocabulary.mastered, 1);
  assert.equal(m.vocabulary.learning, 2); // srsLevel 4 and 2
  assert.equal(m.vocabulary.fresh, 1);
  assert.equal(m.vocabulary.due, 1);
});

test('grammar reports mastered out of the book total, broken down by section', async () => {
  const user = new mongoose.Types.ObjectId();
  const mk = (unit, section) => DailyItem.create({
    language: 'en', level: 'A1', kind: 'grammar', title: `u${unit}`,
    explanation: { en: 'x' }, examples: [{ text: 'a' }, { text: 'b' }],
    quickCheck: [
      { prompt: 'q', options: ['a','b','c'], answerIndex: 0 },
      { prompt: 'q', options: ['a','b','c'], answerIndex: 1 },
      { prompt: 'q', options: ['a','b','c'], answerIndex: 2 },
    ],
    source: 'curated', approved: true, syllabus: { book: 'elementary', unit, section },
  });
  await mk(1, 'Present'); await mk(2, 'Present'); await mk(3, 'Past');
  await GrammarMastery.create({
    user, language: 'en', book: 'elementary', unit: 1, section: 'Present', mastered: true,
  });
  const m = await buildMastery({ userId: user, language: 'en', level: 'A1', todayKey: '2026-09-11' });
  assert.equal(m.grammar.total, 3);
  assert.equal(m.grammar.mastered, 1);
  const present = m.grammar.sections.find((s) => s.section === 'Present');
  assert.deepEqual([present.mastered, present.total], [1, 2]);
});

test('listening accuracy comes from completion scores', async () => {
  const user = new mongoose.Types.ObjectId();
  await DailyDropCompletion.create({ user, dateKey: '2026-09-10', kind: 'listening', score: 2 });
  await DailyDropCompletion.create({ user, dateKey: '2026-09-11', kind: 'listening', score: 1 });
  const m = await buildMastery({ userId: user, language: 'en', level: 'A2', todayKey: '2026-09-11' });
  assert.equal(m.listening.samples, 2);
  assert.equal(m.listening.accuracy, 0.75); // (2+1) of (2+2)
});

test('consistency lists the days the learner completed something', async () => {
  const user = new mongoose.Types.ObjectId();
  await DailyDropCompletion.create({ user, dateKey: '2026-09-10', kind: 'grammar', score: 3 });
  await DailyDropCompletion.create({ user, dateKey: '2026-09-10', kind: 'review', score: 1 });
  await DailyDropCompletion.create({ user, dateKey: '2026-09-11', kind: 'grammar', score: 2 });
  const m = await buildMastery({ userId: user, language: 'en', level: 'A2', todayKey: '2026-09-11' });
  assert.deepEqual(m.consistency.days, ['2026-09-10', '2026-09-11']);
});

test('a learner with no history gets zeroes, not nulls or a crash', async () => {
  const m = await buildMastery({
    userId: new mongoose.Types.ObjectId(), language: 'en', level: 'A2', todayKey: '2026-09-11',
  });
  assert.deepEqual(m.vocabulary, { mastered: 0, learning: 0, fresh: 0, due: 0 });
  assert.equal(m.grammar.mastered, 0);
  assert.equal(m.listening.samples, 0);
  assert.deepEqual(m.consistency.days, []);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/masteryService.test.js`
Expected: FAIL — `Cannot find module '../services/masteryService'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// services/masteryService.js
'use strict';

const mongoose = require('mongoose');
const Vocabulary = require('../models/Vocabulary');
const GrammarMastery = require('../models/GrammarMastery');
const DailyItem = require('../models/DailyItem');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const { bookForLevel } = require('../lib/placementScoring');

const CONSISTENCY_DAYS = 30;
const ACCURACY_WINDOW = 20;
const QUESTIONS_PER_STATION = { listening: 2, translate: 1 };

const accuracyFrom = (rows, perStation) => {
  const capped = rows.slice(0, ACCURACY_WINDOW);
  if (capped.length === 0) return { accuracy: null, samples: 0 };
  const scored = capped.reduce((n, r) => n + (r.score || 0), 0);
  return { accuracy: scored / (capped.length * perStation), samples: capped.length };
};

/**
 * Spec §7.3. Four aggregates, not one query per skill and not an N+1 over
 * units — the mastery screen is opened often and must stay cheap.
 */
const buildMastery = async ({ userId, language, level, todayKey }) => {
  const book = bookForLevel(level);

  const [vocabBuckets, units, mastered, completions] = await Promise.all([
    Vocabulary.aggregate([
      { $match: { user: new mongoose.Types.ObjectId(String(userId)), isArchived: false } },
      { $group: {
        _id: null,
        mastered: { $sum: { $cond: [{ $eq: ['$isMastered', true] }, 1, 0] } },
        learning: { $sum: { $cond: [{ $and: [{ $ne: ['$isMastered', true] }, { $gt: ['$srsLevel', 0] }] }, 1, 0] } },
        fresh:    { $sum: { $cond: [{ $and: [{ $ne: ['$isMastered', true] }, { $lte: ['$srsLevel', 0] }] }, 1, 0] } },
        due:      { $sum: { $cond: [{ $and: [
                      { $ne: ['$isMastered', true] },
                      { $lte: ['$nextReview', new Date(`${todayKey}T23:59:59Z`)] },
                    ] }, 1, 0] } },
      } },
    ]),
    DailyItem.find({ language, kind: 'grammar', approved: true, 'syllabus.book': book })
      .select('syllabus.unit syllabus.section').lean(),
    GrammarMastery.find({ user: userId, language, book, mastered: true }).select('unit section').lean(),
    DailyDropCompletion.find({ user: userId }).select('kind score dateKey').sort({ dateKey: -1 }).lean(),
  ]);

  const v = vocabBuckets[0] || {};
  const masteredUnits = new Set(mastered.map((m) => m.unit));

  const bySection = new Map();
  for (const u of units) {
    const key = (u.syllabus && u.syllabus.section) || '';
    if (!bySection.has(key)) bySection.set(key, { section: key, mastered: 0, total: 0 });
    const row = bySection.get(key);
    row.total += 1;
    if (masteredUnits.has(u.syllabus.unit)) row.mastered += 1;
  }

  const byKind = (kind) => completions.filter((c) => c.kind === kind);
  const days = [...new Set(completions.map((c) => c.dateKey))].sort().slice(-CONSISTENCY_DAYS);

  return {
    level,
    book,
    vocabulary: {
      mastered: v.mastered || 0, learning: v.learning || 0,
      fresh: v.fresh || 0, due: v.due || 0,
    },
    grammar: {
      mastered: masteredUnits.size,
      total: units.length,
      sections: [...bySection.values()],
    },
    listening: accuracyFrom(byKind('listening'), QUESTIONS_PER_STATION.listening),
    translate: accuracyFrom(byKind('translate'), QUESTIONS_PER_STATION.translate),
    consistency: { days, currentStreak: null },
  };
};

module.exports = { buildMastery, CONSISTENCY_DAYS, ACCURACY_WINDOW };
```

```javascript
// controllers/learning.js — add near the other requires and exports
const { buildMastery } = require('../services/masteryService');
const { toDateKey } = require('../lib/dailyCompletion');

// @desc    Per-skill mastery summary
// @route   GET /api/v1/learning/mastery
exports.getMastery = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user.id).select('language_to_learn languageLevel');
  const raw = Array.isArray(user.language_to_learn) ? user.language_to_learn[0] : user.language_to_learn;
  const data = await buildMastery({
    userId: req.user.id,
    language: require('../utils/languageNormalize').toBaseLanguage(raw) || 'en',
    level: user.languageLevel || require('../lib/dailyLevels').DEFAULT_LEVEL,
    todayKey: toDateKey(new Date()),
  });
  res.status(200).json({ success: true, data });
});
```

```javascript
// routes/learning.js — add alongside the other learning routes
router.get('/mastery', getMastery);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/masteryService.test.js`
Expected: PASS, 5 tests

- [ ] **Step 5: Commit**

```bash
git add services/masteryService.js controllers/learning.js routes/learning.js \
        test/masteryService.test.js
git commit -m "feat(daily-pack): per-skill mastery endpoint"
```

---

### Task 11: Grammar seeder with the balance gate

**Files:**
- Create: `seeds/dailyGrammarItems.js`
- Create: `migrations/dailyGrammarData.json` (authored content — Plan 3 fills it; commit a 3-unit sample now so the seeder is testable)
- Test: `test/dailyGrammarSeeder.test.js`

**Interfaces:**
- Consumes: `validateDailyItemsData` from `lib/dailyItemShape.js`; `checkAnswerBalance` (Task 4).
- Produces: `validateGrammarBatch(items): { ok, errors }` and a runnable `node seeds/dailyGrammarItems.js [--dry-run]`.

- [ ] **Step 1: Write the failing test**

```javascript
// test/dailyGrammarSeeder.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { validateGrammarBatch } = require('../seeds/dailyGrammarItems');

const unit = (n, answerIndexes) => ({
  language: 'en', level: 'A1', kind: 'grammar', title: `unit ${n}`,
  explanation: { en: 'A short original explanation.' },
  examples: [{ text: 'First example.' }, { text: 'Second example.' }],
  quickCheck: answerIndexes.map((answerIndex, i) => ({
    prompt: `q${i}`, options: ['a', 'b', 'c'], answerIndex,
  })),
  source: 'curated',
  syllabus: { book: 'elementary', unit: n, section: 'Present' },
});

test('a well-formed, balanced batch validates', () => {
  const items = [unit(1, [0,1,2]), unit(2, [1,2,0]), unit(3, [2,0,1]), unit(4, [0,1,2]),
                 unit(5, [1,2,0])];
  assert.deepEqual(validateGrammarBatch(items), { ok: true, errors: [] });
});

test('a batch missing the syllabus position is rejected', () => {
  const bad = unit(1, [0,1,2]); delete bad.syllabus;
  const out = validateGrammarBatch([bad]);
  assert.equal(out.ok, false);
  assert.match(out.errors.join(' '), /syllabus/);
});

test('a shape violation from the shared validator is reported', () => {
  const bad = unit(1, [0,1]); // only 2 quickCheck entries
  const out = validateGrammarBatch([bad]);
  assert.equal(out.ok, false);
  assert.match(out.errors.join(' '), /quickCheck must be an array of exactly 3/);
});

test('a batch skewed toward one answer position is refused', () => {
  const items = Array.from({ length: 6 }, (_, i) => unit(i + 1, [1, 1, 1]));
  const out = validateGrammarBatch(items);
  assert.equal(out.ok, false);
  assert.match(out.errors.join(' '), /position/);
});

test('duplicate units in one batch are refused', () => {
  const out = validateGrammarBatch([unit(1, [0,1,2]), unit(1, [1,2,0])]);
  assert.equal(out.ok, false);
  assert.match(out.errors.join(' '), /duplicate/i);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/dailyGrammarSeeder.test.js`
Expected: FAIL — `Cannot find module '../seeds/dailyGrammarItems'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// seeds/dailyGrammarItems.js
/**
 * DailyItem grammar seeder. ADDITIVE ONLY.
 *
 * Reads migrations/dailyGrammarData.json. The reference grammars supply the
 * SYLLABUS only — which points to teach, in what order, at what level. Every
 * explanation, example and quick check in that file is original content. This
 * mirrors the copyright boundary documented in models/VocabPack.js.
 *
 * Safety pattern (mirrors seeds/vocabPacks.js):
 * - validates the ENTIRE batch before writing anything (no half-seeds)
 * - refuses a batch whose answer positions are skewed (lib/answerBalance.js)
 * - upserts on (language, level, kind, title), so re-running is idempotent
 * - prints a per-unit audit line and exits non-zero on failure
 *
 * Usage: node seeds/dailyGrammarItems.js [--dry-run]
 */
'use strict';

const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', 'config', 'config.env') });

const { validateDailyItemsData } = require('../lib/dailyItemShape');
const { checkAnswerBalance } = require('../lib/answerBalance');

const DATA_PATH = path.join(__dirname, '..', 'migrations', 'dailyGrammarData.json');

const validateGrammarBatch = (items) => {
  const errors = [...validateDailyItemsData(items)];

  (items || []).forEach((it, i) => {
    const s = it && it.syllabus;
    if (!s || !['elementary', 'intermediate'].includes(s.book)) {
      errors.push(`[${i}] syllabus.book must be 'elementary' or 'intermediate'`);
    }
    if (!s || !Number.isInteger(s.unit) || s.unit < 1) {
      errors.push(`[${i}] syllabus.unit must be a positive integer`);
    }
  });

  const seen = new Set();
  (items || []).forEach((it, i) => {
    const s = it && it.syllabus;
    if (!s) return;
    const key = `${it.language}/${s.book}/${s.unit}`;
    if (seen.has(key)) errors.push(`[${i}] duplicate unit ${key} in this batch`);
    seen.add(key);
  });

  const balance = checkAnswerBalance(items || []);
  errors.push(...balance.errors);

  return { ok: errors.length === 0, errors };
};

const run = async () => {
  const dryRun = process.argv.includes('--dry-run');
  const items = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));

  const { ok, errors } = validateGrammarBatch(items);
  if (!ok) {
    console.error(`✗ refusing to seed ${items.length} items:`);
    errors.forEach((e) => console.error(`   ${e}`));
    process.exit(1);
  }
  console.log(`✓ ${items.length} grammar units validated (shape + answer balance)`);
  if (dryRun) { console.log('dry run — nothing written'); return; }

  const DailyItem = require('../models/DailyItem');
  await mongoose.connect(process.env.MONGO_URI);
  for (const it of items) {
    await DailyItem.updateOne(
      { language: it.language, level: it.level, kind: it.kind, title: it.title },
      { $set: { ...it, approved: true, needsReview: true } },
      { upsert: true }
    );
    console.log(`  ${it.syllabus.book} u${it.syllabus.unit} · ${it.level} · ${it.title}`);
  }
  await mongoose.disconnect();
  console.log('done');
};

if (require.main === module) {
  run().catch((e) => { console.error('FATAL', e.message); process.exit(1); });
}

module.exports = { validateGrammarBatch, DATA_PATH };
```

Commit a 3-unit sample `migrations/dailyGrammarData.json` so the seeder runs; Plan 3 replaces it with the 120-unit batch.

```json
[
  {
    "language": "en", "level": "A1", "kind": "grammar", "source": "curated",
    "title": "am / is / are",
    "explanation": { "en": "Use am with I, is with he, she and it, and are with you, we and they. The verb changes to match the subject, not the rest of the sentence." },
    "examples": [
      { "text": "I am at work." },
      { "text": "She is a nurse." },
      { "text": "They are late again." }
    ],
    "quickCheck": [
      { "prompt": "She ___ my sister.", "options": ["am", "is", "are"], "answerIndex": 1, "explanation": "Third person singular takes is." },
      { "prompt": "We ___ ready.", "options": ["are", "is", "am"], "answerIndex": 0, "explanation": "We takes are." },
      { "prompt": "I ___ tired today.", "options": ["is", "are", "am"], "answerIndex": 2, "explanation": "I always takes am." }
    ],
    "syllabus": { "book": "elementary", "unit": 1, "section": "Present" }
  },
  {
    "language": "en", "level": "A1", "kind": "grammar", "source": "curated",
    "title": "present continuous (I am doing)",
    "explanation": { "en": "Use am, is or are plus the -ing form for something happening now or around now. It describes an action in progress rather than a habit." },
    "examples": [
      { "text": "He is waiting outside." },
      { "text": "I am reading a good book at the moment." },
      { "text": "They are building a new station." }
    ],
    "quickCheck": [
      { "prompt": "Listen! Someone ___ the piano.", "options": ["plays", "is playing", "play"], "answerIndex": 1, "explanation": "Happening right now." },
      { "prompt": "I ___ for my results this week.", "options": ["am waiting", "wait", "waits"], "answerIndex": 0, "explanation": "Around now, still in progress." },
      { "prompt": "Where ___ you going?", "options": ["is", "am", "are"], "answerIndex": 2, "explanation": "You takes are." }
    ],
    "syllabus": { "book": "elementary", "unit": 3, "section": "Present" }
  },
  {
    "language": "en", "level": "A1", "kind": "grammar", "source": "curated",
    "title": "past simple (worked, got, went)",
    "explanation": { "en": "Use the past simple for a finished action at a finished time. Regular verbs add -ed; many common verbs are irregular and must be learned." },
    "examples": [
      { "text": "We walked home after the film." },
      { "text": "She went to Rome last spring." },
      { "text": "I got your message yesterday." }
    ],
    "quickCheck": [
      { "prompt": "They ___ the train at six.", "options": ["catched", "caught", "catch"], "answerIndex": 1, "explanation": "Catch is irregular: caught." },
      { "prompt": "I ___ dinner an hour ago.", "options": ["cooked", "cook", "am cooking"], "answerIndex": 0, "explanation": "Finished time: an hour ago." },
      { "prompt": "He ___ to the doctor on Monday.", "options": ["goes", "going", "went"], "answerIndex": 2, "explanation": "Go is irregular: went." }
    ],
    "syllabus": { "book": "elementary", "unit": 11, "section": "Past" }
  }
]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/dailyGrammarSeeder.test.js`
Expected: PASS, 5 tests

- [ ] **Step 5: Verify the seeder refuses nothing valid**

Run: `node seeds/dailyGrammarItems.js --dry-run`
Expected: `✓ 3 grammar units validated (shape + answer balance)` then `dry run — nothing written`

- [ ] **Step 6: Commit**

```bash
git add seeds/dailyGrammarItems.js migrations/dailyGrammarData.json test/dailyGrammarSeeder.test.js
git commit -m "feat(daily-pack): grammar seeder with shape and answer-balance gates"
```

---

### Task 12: Nightly job — themes only, no grammar pre-generation

**Files:**
- Modify: `jobs/dailyDropJob.js`
- Test: `test/dailyDropJobThemes.test.js`

**Interfaces:**
- Consumes: `weekKeyFor`, `dayInWeek`, `themeIndexFor` (Task 2); `resolveTheme` (Task 7).
- Produces: `generateThemeDrops({ dateKey })` — upserts one `DailyDrop` per (language, level) carrying `weekKey`, `themePack` and `dayInWeek`. No grammar item is written.

- [ ] **Step 1: Write the failing test**

```javascript
// test/dailyDropJobThemes.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const VocabPack = require('../models/VocabPack');
const DailyDrop = require('../models/DailyDrop');
const { generateThemeDrops } = require('../jobs/dailyDropJob');

let mongod;
test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'dropjob_test' });
});
test.after(async () => { await mongoose.disconnect(); await mongod.stop(); });
test.beforeEach(async () => {
  await Promise.all([VocabPack.deleteMany({}), DailyDrop.deleteMany({})]);
  await VocabPack.create({
    level: 'intermediate', topic: 'Work & careers',
    words: [{ word: 'w', definition: 'd', example: 'e' }],
  });
});

test('the job records the week theme for a level', async () => {
  await generateThemeDrops({ dateKey: '2026-09-07', languages: ['en'], levels: ['A2'] });
  const drop = await DailyDrop.findOne({ dateKey: '2026-09-07', language: 'en', level: 'A2' }).lean();
  assert.equal(drop.weekKey, require('../lib/dailyTheme').weekKeyFor('2026-09-07'));
  assert.equal(drop.dayInWeek, 1);
  assert.ok(drop.themePack);
});

test('the job no longer pre-generates a grammar item', async () => {
  await generateThemeDrops({ dateKey: '2026-09-07', languages: ['en'], levels: ['A2'] });
  const drop = await DailyDrop.findOne({ dateKey: '2026-09-07' }).lean();
  assert.ok(!drop.grammarItem, 'grammar is resolved per learner at read time (spec D7)');
});

test('running the job twice is idempotent', async () => {
  await generateThemeDrops({ dateKey: '2026-09-07', languages: ['en'], levels: ['A2'] });
  await generateThemeDrops({ dateKey: '2026-09-07', languages: ['en'], levels: ['A2'] });
  assert.equal(await DailyDrop.countDocuments({ dateKey: '2026-09-07' }), 1);
});

test('a level with no packs is skipped without throwing', async () => {
  await VocabPack.deleteMany({});
  await generateThemeDrops({ dateKey: '2026-09-07', languages: ['en'], levels: ['A2'] });
  assert.equal(await DailyDrop.countDocuments({ dateKey: '2026-09-07' }), 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/dailyDropJobThemes.test.js`
Expected: FAIL — `generateThemeDrops is not a function`

- [ ] **Step 3: Write minimal implementation**

```javascript
// jobs/dailyDropJob.js — add, and export alongside the existing functions
const DailyDrop = require('../models/DailyDrop');
const { weekKeyFor, dayInWeek } = require('../lib/dailyTheme');
const { resolveTheme } = require('../services/dailyPackService');

/**
 * Pre-record the week's theme per (language, level). Grammar is deliberately
 * absent: it is resolved per learner from their own cursor (spec D7), so there
 * is nothing shared to pre-generate.
 */
const generateThemeDrops = async ({ dateKey, languages = ['en'], levels }) => {
  const { LEVELS } = require('../lib/dailyLevels');
  const targetLevels = levels || LEVELS;
  let written = 0;

  for (const language of languages) {
    for (const level of targetLevels) {
      const theme = await resolveTheme({ level, dateKey });
      if (!theme) continue;
      await DailyDrop.updateOne(
        { dateKey, language, level },
        { $set: {
          weekKey: weekKeyFor(dateKey),
          themePack: theme._id,
          dayInWeek: dayInWeek(dateKey),
        } },
        { upsert: true }
      );
      written += 1;
    }
  }
  console.log(`[DailyDrop] themes recorded for ${dateKey}: ${written}`);
  return { written };
};

module.exports.generateThemeDrops = generateThemeDrops;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/dailyDropJobThemes.test.js`
Expected: PASS, 4 tests

- [ ] **Step 5: Run the whole suite and confirm the pack is consistent end to end**

Run: `npm test`
Expected: only the pre-existing `JWT_SECRET` failure. Note the new test count in the commit message.

- [ ] **Step 6: Commit**

```bash
git add jobs/dailyDropJob.js test/dailyDropJobThemes.test.js
git commit -m "feat(daily-pack): nightly job records weekly themes, not grammar"
```

---

## Deferred to Plan 2 (Flutter) and Plan 3 (content)

- **Plan 2 — app**: hero card, guided flow, six station widgets, `check_question.dart`, placement screen, mastery screen, ~40–60 new strings across 19 ARB locales, rewrites of `today_section_test.dart` and `daily_drop_screen_test.dart`. Build against the `GET /study/pack`, `POST /study/pack/:station/complete`, `GET|POST /study/placement` and `GET /learning/mastery` shapes locked by this plan.
- **Plan 3 — content**: 120 authored grammar units into `migrations/dailyGrammarData.json` (60 elementary, 60 intermediate), 12 beginner vocab packs into `migrations/vocabPacksData.json`, each batch passing `node seeds/dailyGrammarItems.js --dry-run` and the answer-balance gate.
- **Listening audio**: the station currently returns clip *text*. Wiring `speechService.generateTTS()` plus `audiocaches` reuse is a Plan 2 dependency (the app can render text-only clips first, which keeps this plan shippable).

## Self-review notes

- **Spec coverage**: §4.6 authoring gates → Tasks 4, 11. §5.1 schema → Task 6. §5.2 cursor → Tasks 3, 7. §5.3 kinds split → Tasks 1, 6. §5.4 `item` ref → Task 6. §5.5 applicability and empty auto-satisfy → Tasks 1, 7. §5.6 XP → Task 8. §7.3 mastery → Task 10. §4.2 themes → Tasks 2, 12. D4 placement → Tasks 5, 9. §6 delivery copy is **not** in this plan — it needs the app shipped first to be worth changing, and is listed in spec §9 as wave 2.
- **Type consistency**: `STATION_KINDS` (Task 1) is the single source for the completion enum (Task 6) and route validation (Task 8). `bookForLevel` (Task 5) is used by Tasks 7 and 10. `applyAttempt` (Task 3) is used only by Task 8. `resolveTheme`/`resolveGrammar` (Task 7) are reused by Tasks 8 and 12 rather than reimplemented.
- **Gap found and closed during self-review**: pack words carry no answer key, so
  `scoreQuickCheck` had nothing to score and the vocabulary and wrap stations would
  have always returned 0. Task 7a builds the key deterministically from the same seed
  buildPack uses, so the server scores exactly the questions the learner saw without
  trusting the client's copy.
- **Known rough edge**: Task 8's `completeStation` calls `buildPack` twice (before and after committing) to report `stationsRemaining` from the server's own view. That is two extra reads per submission — acceptable at 758 active users, and the alternative (trusting a client-computed remainder) is the class of bug this plan is trying to avoid.
