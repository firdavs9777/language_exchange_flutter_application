# Study Hub Daily Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a daily grammar + vocabulary drop in Study Hub that gives every learner one unambiguous 2-minute action per day, delivered at their own local time.

**Architecture:** A content bank (`DailyItem`) is separated from the daily schedule (`DailyDrop`), so items recur on a cycle and AI-generated items enter the same bank as curated ones. A nightly job builds one drop per `(language, level)` by least-recently-used selection; English is served only human-reviewed items, other languages are AI-filled behind a validator. Completing both kinds marks the day done, which drives the streak. An hourly delivery job pushes each user a notification at their own local hour.

**Tech Stack:** Node 24 / Express / Mongoose / `node:test` (backend); Flutter / Riverpod / `flutter_test` (app); Firebase Cloud Messaging.

**Spec:** `docs/superpowers/specs/2026-08-23-study-hub-daily-design.md`

## Global Constraints

- **Scope boundary.** This plan implements spec §4.1–§4.9 plus prerequisites P1 and P2. Spec §4.10 B1–B4 (SRS reviews, achievements, lesson completions, quiz attempts all recording zero) are **not** in this plan — they require a diagnostic pass first, which produces its own plan. Do not attempt drive-by fixes to those paths.
- **Backend tests never touch Mongo.** `npm test` runs `node --experimental-test-module-mocks --test services/*.test.js test/*.test.js`. Every test in this plan is a pure unit test over injected data. Never write a test that requires a live database.
- **Dart imports use `package:` paths.** Never `../../../`. The linter enforces this.
- **New notification types must be added to the `Notification` enum in the same commit that first sends them.** `models/Notification.js` documents three prior incidents where a missing enum value made `_saveToHistory` throw a silently-swallowed `ValidationError`: push fired, the history row and badge increment never happened.
- **CEFR levels** are exactly `['A1','A2','B1','B2','C1','C2']`. The default for a user with no level is `'A2'`.
- **Base language codes** are lowercase BCP-47-ish. Chinese is the deliberate exception: `zh-Hans` and `zh-Hant` stay distinct.
- **Seeders are additive and idempotent**, following `seeds/vocabPacks.js`: validate the entire data file up front, refuse to write anything on any validation error, upsert on a unique key, print a per-item audit line, support `--dry-run`, exit non-zero on failure.
- **API responses** follow the existing shape: `res.status(200).json({ success: true, data })`.
- **Backend paths** are relative to `/Users/davis/Desktop/Personal/language_exchange_backend_application`. **App paths** are relative to `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`.

---

## File Structure

**Backend — create**

| File | Responsibility |
|---|---|
| `utils/languageNormalize.js` | Map any stored language string to a base code |
| `lib/dailyItemShape.js` | Validate a `DailyItem` payload; shared by seeder and AI generator |
| `lib/dailyLevels.js` | CEFR level ordering and nearest-lower-level fallback |
| `models/DailyItem.js` | The content bank |
| `models/DailyDrop.js` | The per-day schedule |
| `models/DailyDropCompletion.js` | Per-user completion rows |
| `services/dailyDropService.js` | LRU selection, drop building, per-user resolution |
| `services/dailyItemGenerator.js` | AI fill for non-English, behind the validator |
| `jobs/dailyDropJob.js` | Nightly generation + hourly local-time delivery |
| `controllers/dailyStudy.js` | The four endpoints |
| `routes/dailyStudy.js` | Route wiring |
| `migrations/dailyItemsData.json` | The 180 curated English items |
| `seeds/dailyItems.js` | Idempotent seeder for the above |
| `test/languageNormalize.test.js`, `test/dailyLevels.test.js`, `test/dailyItemShape.test.js`, `test/dailyDropSelection.test.js`, `test/dailyDropDelivery.test.js`, `test/dailyDropCompletion.test.js` | Unit tests |

**Backend — modify**

| File | Change |
|---|---|
| `models/Notification.js` | Add `'daily_drop'` to the `type` enum |
| `models/User.js` | Add `timezone` (IANA) and `notificationSettings.dailyDropHour` |
| `config/notificationCaps.js` | Add `daily_drop: 1` under `daily` |
| `utils/notificationTemplates.js` | Add `getDailyDropTemplate` |
| `jobs/scheduler.js` | Wire generation + delivery |
| `server.js` | Mount `/api/v1/study` |
| `controllers/notifications.js`, `routes/notifications.js` | Click-tracking endpoint |
| `test/notificationTypeEnum.test.js` | Add `daily_drop` |

**App — create**

| File | Responsibility |
|---|---|
| `lib/utils/language_normalize.dart` | Dart mirror of the base-code mapping |
| `lib/models/learning/daily_drop_model.dart` | `DailyItem`, `DailyDrop`, `DailyDropState` |
| `lib/providers/provider_root/learning/daily_drop_providers.dart` | Riverpod wiring |
| `lib/pages/learning/daily/daily_drop_screen.dart` | Explanation + examples + 3-question check |
| `lib/pages/learning/daily/widgets/today_section.dart` | The two Today cards |
| `lib/pages/learning/main/study_hub_tabs.dart` | Study Hub sub-tab order as a testable value |
| `test/learning/language_normalize_test.dart`, `test/learning/daily_drop_model_test.dart`, `test/learning/today_section_test.dart`, `test/learning/daily_drop_screen_test.dart`, `test/learning/study_hub_tabs_test.dart`, `test/learning/daily_drop_router_test.dart` | Tests |

**App — modify**

| File | Change |
|---|---|
| `lib/service/endpoints.dart` | Daily study endpoints |
| `lib/services/learning_service.dart` | Four API methods |
| `lib/pages/learning/main/sections/learn_tab.dart` | Insert Today section above existing content |
| `lib/pages/learning/main/learning_main_screen.dart` | Reorder sub-tabs so Today leads |
| `lib/services/notification_router.dart` | `daily_drop` deep link + click ping |
| `lib/services/notification_service.dart` | Report IANA timezone on launch |
| `lib/l10n/app_en.arb` + 18 locale ARBs | New strings |

---

## Task 1: Language normalization (backend)

Spec §4.1. Everything else depends on this.

**Files:**
- Create: `utils/languageNormalize.js`
- Test: `test/languageNormalize.test.js`

**Interfaces:**
- Consumes: nothing
- Produces: `toBaseLanguage(value: string|null|undefined) -> string|null`, `BASE_LANGUAGE_MAP: Object`

- [ ] **Step 1: Write the failing test**

Create `test/languageNormalize.test.js`. Every string below was observed in prod on 2026-08-23:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const { toBaseLanguage } = require('../utils/languageNormalize');

test('all four English variants collapse to en', () => {
  assert.equal(toBaseLanguage('English'), 'en');
  assert.equal(toBaseLanguage('English (US)'), 'en');
  assert.equal(toBaseLanguage('English (UK)'), 'en');
  assert.equal(toBaseLanguage('en'), 'en');
});

test('Chinese scripts stay distinct', () => {
  assert.equal(toBaseLanguage('Chinese (Simplified)'), 'zh-Hans');
  assert.equal(toBaseLanguage('Chinese (Traditional)'), 'zh-Hant');
});

test('other observed languages map to their base code', () => {
  assert.equal(toBaseLanguage('Korean'), 'ko');
  assert.equal(toBaseLanguage('Japanese'), 'ja');
  assert.equal(toBaseLanguage('French'), 'fr');
  assert.equal(toBaseLanguage('Russian'), 'ru');
  assert.equal(toBaseLanguage('German'), 'de');
  assert.equal(toBaseLanguage('Spanish'), 'es');
  assert.equal(toBaseLanguage('Arabic'), 'ar');
  assert.equal(toBaseLanguage('Hindi'), 'hi');
  assert.equal(toBaseLanguage('Urdu'), 'ur');
  assert.equal(toBaseLanguage('Italian'), 'it');
  assert.equal(toBaseLanguage('Filipino'), 'tl');
  assert.equal(toBaseLanguage('Afrikaans'), 'af');
});

test('matching is case and whitespace insensitive', () => {
  assert.equal(toBaseLanguage('  english  '), 'en');
  assert.equal(toBaseLanguage('KOREAN'), 'ko');
});

test('empty and missing values return null, not a default', () => {
  assert.equal(toBaseLanguage(''), null);
  assert.equal(toBaseLanguage('   '), null);
  assert.equal(toBaseLanguage(null), null);
  assert.equal(toBaseLanguage(undefined), null);
});

test('unknown values return null rather than guessing', () => {
  assert.equal(toBaseLanguage('Klingon'), null);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 languageNormalize`
Expected: FAIL — `Cannot find module '../utils/languageNormalize'`

- [ ] **Step 3: Write minimal implementation**

Create `utils/languageNormalize.js`:

```js
'use strict';

/**
 * Maps every language string observed in prod (2026-08-23) to a base code.
 *
 * Why this exists: `language_to_learn` stores "English", "English (US)",
 * "English (UK)" and "en" as four distinct values. A per-language query that
 * does not normalize misses roughly half its intended audience.
 *
 * Chinese is deliberately NOT collapsed — Simplified and Traditional are
 * different written content and both have real populations.
 */
const BASE_LANGUAGE_MAP = {
  english: 'en', 'english (us)': 'en', 'english (uk)': 'en', en: 'en',
  'chinese (simplified)': 'zh-Hans', 'zh-hans': 'zh-Hans',
  'chinese (traditional)': 'zh-Hant', 'zh-hant': 'zh-Hant',
  korean: 'ko', ko: 'ko',
  japanese: 'ja', ja: 'ja',
  french: 'fr', fr: 'fr',
  russian: 'ru', ru: 'ru',
  german: 'de', de: 'de',
  spanish: 'es', es: 'es',
  arabic: 'ar', ar: 'ar',
  hindi: 'hi', hi: 'hi',
  urdu: 'ur', ur: 'ur',
  italian: 'it', it: 'it',
  filipino: 'tl', tagalog: 'tl', tl: 'tl',
  afrikaans: 'af', af: 'af',
  turkish: 'tr', tr: 'tr',
  vietnamese: 'vi', vi: 'vi',
  thai: 'th', th: 'th',
  indonesian: 'id', id: 'id',
  portuguese: 'pt', pt: 'pt',
  tajik: 'tg', tg: 'tg',
};

const toBaseLanguage = (value) => {
  if (typeof value !== 'string') return null;
  const key = value.trim().toLowerCase();
  if (!key) return null;
  return BASE_LANGUAGE_MAP[key] || null;
};

module.exports = { toBaseLanguage, BASE_LANGUAGE_MAP };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: all `languageNormalize` tests pass, `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add utils/languageNormalize.js test/languageNormalize.test.js
git commit -m "feat(study): normalize language variants to base codes

Four English spellings coexist in language_to_learn. Any per-language
query that does not normalize misses about half its audience."
```

---

## Task 2: CEFR level ordering and fallback (backend)

Spec §4.3 "Level fallback" and §4.5.

**Files:**
- Create: `lib/dailyLevels.js`
- Test: `test/dailyLevels.test.js`

**Interfaces:**
- Consumes: nothing
- Produces: `LEVELS: string[]`, `DEFAULT_LEVEL: 'A2'`, `resolveLevelWithFallback(requested, available) -> string|null`, `nudgeLevel(current, verdict) -> string`

- [ ] **Step 1: Write the failing test**

Create `test/dailyLevels.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  LEVELS, DEFAULT_LEVEL, resolveLevelWithFallback, nudgeLevel,
} = require('../lib/dailyLevels');

test('levels are the six CEFR bands in order', () => {
  assert.deepEqual(LEVELS, ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
  assert.equal(DEFAULT_LEVEL, 'A2');
});

test('exact match wins', () => {
  assert.equal(resolveLevelWithFallback('B1', ['A1', 'A2', 'B1']), 'B1');
});

test('falls back to nearest LOWER level when requested is above the bank', () => {
  assert.equal(resolveLevelWithFallback('C1', ['A1', 'A2', 'B1']), 'B1');
  assert.equal(resolveLevelWithFallback('B2', ['A1', 'A2']), 'A2');
});

test('falls back UP when requested is below everything available', () => {
  assert.equal(resolveLevelWithFallback('A1', ['B1', 'B2']), 'B1');
});

test('empty bank resolves to null', () => {
  assert.equal(resolveLevelWithFallback('B1', []), null);
});

test('unordered available list still resolves correctly', () => {
  assert.equal(resolveLevelWithFallback('C2', ['B1', 'A1', 'A2']), 'B1');
});

test('nudge moves one band and clamps at the ends', () => {
  assert.equal(nudgeLevel('A2', 'tooEasy'), 'B1');
  assert.equal(nudgeLevel('A2', 'tooHard'), 'A1');
  assert.equal(nudgeLevel('C2', 'tooEasy'), 'C2');
  assert.equal(nudgeLevel('A1', 'tooHard'), 'A1');
});

test('nudge treats a null current level as the default', () => {
  assert.equal(nudgeLevel(null, 'tooHard'), 'A1');
  assert.equal(nudgeLevel(null, 'tooEasy'), 'B1');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyLevels`
Expected: FAIL — `Cannot find module '../lib/dailyLevels'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/dailyLevels.js`:

```js
'use strict';

const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
const DEFAULT_LEVEL = 'A2';

/**
 * Resolve the level to actually serve.
 *
 * Prefers an exact match, then the nearest LOWER level (an over-reaching
 * learner gets easier content rather than an empty screen), then the nearest
 * higher one if nothing lower exists. Returns null only for an empty bank.
 */
const resolveLevelWithFallback = (requested, available) => {
  const pool = (available || []).filter((l) => LEVELS.includes(l));
  if (pool.length === 0) return null;

  const want = LEVELS.indexOf(requested);
  if (want === -1) return resolveLevelWithFallback(DEFAULT_LEVEL, pool);
  if (pool.includes(requested)) return requested;

  const sorted = [...pool].sort((a, b) => LEVELS.indexOf(a) - LEVELS.indexOf(b));
  const lower = sorted.filter((l) => LEVELS.indexOf(l) < want);
  if (lower.length) return lower[lower.length - 1];
  return sorted[0];
};

/** Move one band on a too-easy / too-hard tap, clamped at both ends. */
const nudgeLevel = (current, verdict) => {
  const base = LEVELS.includes(current) ? current : DEFAULT_LEVEL;
  const i = LEVELS.indexOf(base);
  const next = verdict === 'tooEasy' ? i + 1 : i - 1;
  return LEVELS[Math.max(0, Math.min(LEVELS.length - 1, next))];
};

module.exports = { LEVELS, DEFAULT_LEVEL, resolveLevelWithFallback, nudgeLevel };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add lib/dailyLevels.js test/dailyLevels.test.js
git commit -m "feat(study): CEFR level ordering with nearest-lower fallback

A user who nudges past the bank's coverage gets easier content, never
an empty screen."
```

---

## Task 3: DailyItem shape validator (backend)

Spec §4.3. Shared by the seeder (Task 10) and the AI generator (Task 6), so it lands before both. Mirrors the existing `lib/vocabPackShape.js` contract.

**Files:**
- Create: `lib/dailyItemShape.js`
- Test: `test/dailyItemShape.test.js`

**Interfaces:**
- Consumes: `LEVELS` from `lib/dailyLevels.js`
- Produces: `validateDailyItem(item) -> string[]` (empty array means valid), `validateDailyItemsData(arr) -> string[]`

- [ ] **Step 1: Write the failing test**

Create `test/dailyItemShape.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const { validateDailyItem, validateDailyItemsData } = require('../lib/dailyItemShape');

const valid = () => ({
  language: 'en',
  level: 'A2',
  kind: 'grammar',
  title: 'used to vs would',
  explanation: { en: 'Both describe past habits, but only "used to" works for past states.' },
  examples: [
    { text: 'I used to live in Seoul.', translation: { en: 'past state' } },
    { text: 'We would walk home together.', translation: { en: 'repeated past action' } },
  ],
  quickCheck: [
    { prompt: 'I ___ be shy.', options: ['used to', 'would', 'use to'], answerIndex: 0, explanation: 'State, so "used to".' },
    { prompt: 'We ___ play there.', options: ['used to', 'would', 'both'], answerIndex: 2, explanation: 'Repeated action allows both.' },
    { prompt: 'She ___ have a car.', options: ['would', 'used to', 'will'], answerIndex: 1, explanation: 'Past state.' },
  ],
});

test('a well-formed item has no errors', () => {
  assert.deepEqual(validateDailyItem(valid()), []);
});

test('rejects an unknown kind', () => {
  const i = { ...valid(), kind: 'listening' };
  assert.ok(validateDailyItem(i).some((e) => e.includes('kind')));
});

test('rejects an invalid level', () => {
  const i = { ...valid(), level: 'A3' };
  assert.ok(validateDailyItem(i).some((e) => e.includes('level')));
});

test('requires a non-empty English explanation', () => {
  assert.ok(validateDailyItem({ ...valid(), explanation: {} }).some((e) => e.includes('explanation')));
  assert.ok(validateDailyItem({ ...valid(), explanation: { en: '   ' } }).some((e) => e.includes('explanation')));
});

test('requires at least two examples', () => {
  const i = { ...valid(), examples: [{ text: 'only one', translation: {} }] };
  assert.ok(validateDailyItem(i).some((e) => e.includes('examples')));
});

test('requires exactly three quickCheck entries', () => {
  const i = { ...valid(), quickCheck: valid().quickCheck.slice(0, 2) };
  assert.ok(validateDailyItem(i).some((e) => e.includes('quickCheck')));
});

test('rejects an answerIndex outside the options array', () => {
  const i = valid();
  i.quickCheck[0].answerIndex = 5;
  assert.ok(validateDailyItem(i).some((e) => e.includes('answerIndex')));
});

test('rejects a quickCheck with fewer than two options', () => {
  const i = valid();
  i.quickCheck[1].options = ['only'];
  assert.ok(validateDailyItem(i).some((e) => e.includes('options')));
});

test('rejects an over-long explanation', () => {
  const i = { ...valid(), explanation: { en: 'x'.repeat(1201) } };
  assert.ok(validateDailyItem(i).some((e) => e.includes('explanation')));
});

test('batch validation reports the index of each bad item', () => {
  const errs = validateDailyItemsData([valid(), { ...valid(), level: 'Z9' }]);
  assert.equal(errs.length, 1);
  assert.ok(errs[0].startsWith('[1]'));
});

test('batch validation rejects a non-array', () => {
  assert.ok(validateDailyItemsData({}).length > 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyItemShape`
Expected: FAIL — `Cannot find module '../lib/dailyItemShape'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/dailyItemShape.js`:

```js
'use strict';

const { LEVELS } = require('./dailyLevels');

const KINDS = ['grammar', 'vocabulary'];
const MAX_EXPLANATION = 1200;
const MAX_TITLE = 120;

const isNonEmptyString = (v) => typeof v === 'string' && v.trim().length > 0;

/** Returns an array of human-readable errors. Empty array means valid. */
const validateDailyItem = (item) => {
  const errors = [];
  if (!item || typeof item !== 'object') return ['item is not an object'];

  if (!isNonEmptyString(item.language)) errors.push('language must be a non-empty string');
  if (!LEVELS.includes(item.level)) errors.push(`level must be one of ${LEVELS.join(', ')}`);
  if (!KINDS.includes(item.kind)) errors.push(`kind must be one of ${KINDS.join(', ')}`);
  if (!isNonEmptyString(item.title)) errors.push('title must be a non-empty string');
  else if (item.title.length > MAX_TITLE) errors.push(`title exceeds ${MAX_TITLE} characters`);

  const ex = item.explanation;
  if (!ex || typeof ex !== 'object' || !isNonEmptyString(ex.en)) {
    errors.push('explanation.en must be a non-empty string');
  } else if (ex.en.length > MAX_EXPLANATION) {
    errors.push(`explanation.en exceeds ${MAX_EXPLANATION} characters`);
  }

  if (!Array.isArray(item.examples) || item.examples.length < 2) {
    errors.push('examples must be an array of at least 2 entries');
  } else {
    item.examples.forEach((e, i) => {
      if (!e || !isNonEmptyString(e.text)) errors.push(`examples[${i}].text must be a non-empty string`);
    });
  }

  if (!Array.isArray(item.quickCheck) || item.quickCheck.length !== 3) {
    errors.push('quickCheck must be an array of exactly 3 entries');
  } else {
    item.quickCheck.forEach((q, i) => {
      if (!q || typeof q !== 'object') { errors.push(`quickCheck[${i}] is not an object`); return; }
      if (!isNonEmptyString(q.prompt)) errors.push(`quickCheck[${i}].prompt must be a non-empty string`);
      if (!Array.isArray(q.options) || q.options.length < 2) {
        errors.push(`quickCheck[${i}].options must have at least 2 entries`);
        return;
      }
      if (!Number.isInteger(q.answerIndex) || q.answerIndex < 0 || q.answerIndex >= q.options.length) {
        errors.push(`quickCheck[${i}].answerIndex is outside options`);
      }
    });
  }

  return errors;
};

/** Validate a whole data file. Errors are prefixed with the item index. */
const validateDailyItemsData = (arr) => {
  if (!Array.isArray(arr)) return ['data file must be a JSON array'];
  const errors = [];
  arr.forEach((item, i) => {
    validateDailyItem(item).forEach((e) => errors.push(`[${i}] ${e}`));
  });
  return errors;
};

module.exports = { validateDailyItem, validateDailyItemsData, KINDS, MAX_EXPLANATION };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add lib/dailyItemShape.js test/dailyItemShape.test.js
git commit -m "feat(study): DailyItem shape validator

Shared gate for both the curated seeder and the AI generator, so an
unreviewed generation cannot enter the bank malformed."
```

---

## Task 4: Mongoose models (backend)

Spec §4.2.

**Files:**
- Create: `models/DailyItem.js`, `models/DailyDrop.js`, `models/DailyDropCompletion.js`

**Interfaces:**
- Consumes: `LEVELS` from `lib/dailyLevels.js`, `KINDS` from `lib/dailyItemShape.js`
- Produces: three Mongoose models

- [ ] **Step 1: Write `models/DailyItem.js`**

```js
const mongoose = require('mongoose');
const { LEVELS } = require('../lib/dailyLevels');
const { KINDS } = require('../lib/dailyItemShape');

const QuickCheckSchema = new mongoose.Schema({
  prompt: { type: String, required: true },
  options: [{ type: String }],
  answerIndex: { type: Number, required: true },
  explanation: { type: String, default: '' },
}, { _id: false });

const ExampleSchema = new mongoose.Schema({
  text: { type: String, required: true },
  translation: { type: Map, of: String, default: () => new Map() },
}, { _id: false });

const DailyItemSchema = new mongoose.Schema({
  language: { type: String, required: true },   // base code from toBaseLanguage
  level: { type: String, enum: LEVELS, required: true },
  kind: { type: String, enum: KINDS, required: true },
  title: { type: String, required: true },
  explanation: { type: Map, of: String, required: true },  // locale -> text; 'en' required
  examples: [ExampleSchema],
  quickCheck: [QuickCheckSchema],
  source: { type: String, enum: ['curated', 'ai'], required: true },
  approved: { type: Boolean, default: false },
  timesUsed: { type: Number, default: 0 },
  lastUsedDate: { type: String, default: null },  // 'YYYY-MM-DD'
}, { timestamps: true });

// Supports least-recently-used selection within a (language, level, kind) pool.
DailyItemSchema.index({ language: 1, level: 1, kind: 1, approved: 1, lastUsedDate: 1 });
// Idempotent seeding key.
DailyItemSchema.index({ language: 1, level: 1, kind: 1, title: 1 }, { unique: true });

module.exports = mongoose.model('DailyItem', DailyItemSchema);
```

- [ ] **Step 2: Write `models/DailyDrop.js`**

```js
const mongoose = require('mongoose');
const { LEVELS } = require('../lib/dailyLevels');

const DailyDropSchema = new mongoose.Schema({
  dateKey: { type: String, required: true },   // 'YYYY-MM-DD', UTC day
  language: { type: String, required: true },
  level: { type: String, enum: LEVELS, required: true },
  grammarItem: { type: mongoose.Schema.Types.ObjectId, ref: 'DailyItem', default: null },
  vocabItem: { type: mongoose.Schema.Types.ObjectId, ref: 'DailyItem', default: null },
}, { timestamps: true });

DailyDropSchema.index({ dateKey: 1, language: 1, level: 1 }, { unique: true });

module.exports = mongoose.model('DailyDrop', DailyDropSchema);
```

- [ ] **Step 3: Write `models/DailyDropCompletion.js`**

```js
const mongoose = require('mongoose');
const { KINDS } = require('../lib/dailyItemShape');

const DailyDropCompletionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  dateKey: { type: String, required: true },
  kind: { type: String, enum: KINDS, required: true },
  score: { type: Number, default: 0 },   // 0-3, from quickCheck
  completedAt: { type: Date, default: Date.now },
}, { timestamps: true });

// One completion per user per day per kind — makes re-submission idempotent.
DailyDropCompletionSchema.index({ user: 1, dateKey: 1, kind: 1 }, { unique: true });

module.exports = mongoose.model('DailyDropCompletion', DailyDropCompletionSchema);
```

- [ ] **Step 4: Verify the models load without error**

Run: `node -e "require('./models/DailyItem');require('./models/DailyDrop');require('./models/DailyDropCompletion');console.log('models ok')"`
Expected: prints `models ok`

- [ ] **Step 5: Commit**

```bash
git add models/DailyItem.js models/DailyDrop.js models/DailyDropCompletion.js
git commit -m "feat(study): DailyItem, DailyDrop and DailyDropCompletion models

Bank is split from schedule so one item can recur after a full cycle and
AI items enter the same bank as curated ones."
```

---

## Task 5: LRU drop selection (backend)

Spec §4.3. Pure function so it is unit-testable without Mongo.

**Files:**
- Create: `services/dailyDropService.js`
- Test: `test/dailyDropSelection.test.js`

**Interfaces:**
- Consumes: `resolveLevelWithFallback` from `lib/dailyLevels.js`
- Produces: `pickLeastRecentlyUsed(items) -> item|null`, `buildDropPlan({ language, level, kind, bank, dateKey }) -> { item, usedFallbackLevel }`

- [ ] **Step 1: Write the failing test**

Create `test/dailyDropSelection.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const { pickLeastRecentlyUsed, buildDropPlan } = require('../services/dailyDropService');

const item = (id, over = {}) => ({
  _id: id, language: 'en', level: 'A2', kind: 'grammar',
  approved: true, timesUsed: 0, lastUsedDate: null, ...over,
});

test('never-used items are preferred over used ones', () => {
  const picked = pickLeastRecentlyUsed([
    item('a', { lastUsedDate: '2026-08-01' }),
    item('b', { lastUsedDate: null }),
  ]);
  assert.equal(picked._id, 'b');
});

test('among used items the oldest lastUsedDate wins', () => {
  const picked = pickLeastRecentlyUsed([
    item('a', { lastUsedDate: '2026-08-10' }),
    item('b', { lastUsedDate: '2026-07-02' }),
    item('c', { lastUsedDate: '2026-08-01' }),
  ]);
  assert.equal(picked._id, 'b');
});

test('timesUsed breaks a lastUsedDate tie', () => {
  const picked = pickLeastRecentlyUsed([
    item('a', { lastUsedDate: '2026-08-01', timesUsed: 3 }),
    item('b', { lastUsedDate: '2026-08-01', timesUsed: 1 }),
  ]);
  assert.equal(picked._id, 'b');
});

test('selection is deterministic when everything ties', () => {
  const pool = [item('b'), item('a'), item('c')];
  assert.equal(pickLeastRecentlyUsed(pool)._id, pickLeastRecentlyUsed([...pool].reverse())._id);
});

test('an empty pool yields null', () => {
  assert.equal(pickLeastRecentlyUsed([]), null);
});

test('unapproved items are never picked', () => {
  assert.equal(pickLeastRecentlyUsed([item('a', { approved: false })]), null);
});

test('buildDropPlan picks from the exact level when available', () => {
  const bank = [item('a', { level: 'A2' }), item('b', { level: 'B1' })];
  const plan = buildDropPlan({ language: 'en', level: 'A2', kind: 'grammar', bank });
  assert.equal(plan.item._id, 'a');
  assert.equal(plan.usedFallbackLevel, null);
});

test('buildDropPlan reports the fallback level it actually served', () => {
  const bank = [item('a', { level: 'B1' })];
  const plan = buildDropPlan({ language: 'en', level: 'C1', kind: 'grammar', bank });
  assert.equal(plan.item._id, 'a');
  assert.equal(plan.usedFallbackLevel, 'B1');
});

test('buildDropPlan ignores items of the wrong kind or language', () => {
  const bank = [item('a', { kind: 'vocabulary' }), item('b', { language: 'ko' })];
  const plan = buildDropPlan({ language: 'en', level: 'A2', kind: 'grammar', bank });
  assert.equal(plan.item, null);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyDropSelection`
Expected: FAIL — `Cannot find module '../services/dailyDropService'`

- [ ] **Step 3: Write minimal implementation**

Create `services/dailyDropService.js`:

```js
'use strict';

const { resolveLevelWithFallback } = require('../lib/dailyLevels');

/**
 * Least-recently-used pick: never-used first, then oldest lastUsedDate, then
 * fewest timesUsed, then _id for determinism (so two runs on identical data
 * produce the same drop).
 */
const pickLeastRecentlyUsed = (items) => {
  const pool = (items || []).filter((i) => i && i.approved);
  if (pool.length === 0) return null;

  return [...pool].sort((a, b) => {
    const ad = a.lastUsedDate || '';
    const bd = b.lastUsedDate || '';
    if (ad !== bd) return ad < bd ? -1 : 1;
    if ((a.timesUsed || 0) !== (b.timesUsed || 0)) return (a.timesUsed || 0) - (b.timesUsed || 0);
    return String(a._id) < String(b._id) ? -1 : 1;
  })[0];
};

/**
 * Choose the item to serve for one (language, level, kind), applying the
 * level fallback from spec §4.3 and reporting when a fallback was used so the
 * card can say which level it is showing.
 */
const buildDropPlan = ({ language, level, kind, bank }) => {
  const scoped = (bank || []).filter(
    (i) => i && i.approved && i.language === language && i.kind === kind
  );
  if (scoped.length === 0) return { item: null, usedFallbackLevel: null };

  const available = [...new Set(scoped.map((i) => i.level))];
  const served = resolveLevelWithFallback(level, available);
  if (!served) return { item: null, usedFallbackLevel: null };

  const item = pickLeastRecentlyUsed(scoped.filter((i) => i.level === served));
  return { item, usedFallbackLevel: served === level ? null : served };
};

module.exports = { pickLeastRecentlyUsed, buildDropPlan };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add services/dailyDropService.js test/dailyDropSelection.test.js
git commit -m "feat(study): least-recently-used drop selection with level fallback

Deterministic ordering so two runs on identical data pick the same item."
```

---

## Task 6: AI fill for non-English (backend)

Spec §4.3. English never reaches this path.

**Files:**
- Create: `services/dailyItemGenerator.js`
- Test: `test/dailyItemGenerator.test.js`
- Modify: `services/dailyDropService.js` (export `isAiFillAllowed`)

**Interfaces:**
- Consumes: `validateDailyItem` from `lib/dailyItemShape.js`, `chatCompletion` + `parseJSONResponse` from `services/aiProviderService.js`
- Produces: `buildGenerationPrompt({ language, level, kind }) -> string`, `acceptGeneratedItem(raw, { language, level, kind }) -> { item, errors }`, `isAiFillAllowed(language) -> boolean`

- [ ] **Step 1: Write the failing test**

Create `test/dailyItemGenerator.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const { buildGenerationPrompt, acceptGeneratedItem, isAiFillAllowed } = require('../services/dailyItemGenerator');

const rawValid = () => ({
  title: '~고 싶다',
  explanation: { en: 'Expresses the speaker\'s own desire to do something.' },
  examples: [
    { text: '물을 마시고 싶어요.', translation: { en: 'I want to drink water.' } },
    { text: '집에 가고 싶어요.', translation: { en: 'I want to go home.' } },
  ],
  quickCheck: [
    { prompt: '먹___ 싶어요', options: ['고', '서', '지'], answerIndex: 0, explanation: 'Attaches to the verb stem.' },
    { prompt: 'Which person can ~고 싶다 describe?', options: ['first', 'third', 'any'], answerIndex: 0, explanation: 'Own desire only.' },
    { prompt: 'Formal polite ending?', options: ['싶어요', '싶다', '싶고'], answerIndex: 0, explanation: '-어요 is polite.' },
  ],
});

test('English is never AI-filled', () => {
  assert.equal(isAiFillAllowed('en'), false);
});

test('other languages are AI-fillable', () => {
  assert.equal(isAiFillAllowed('ko'), true);
  assert.equal(isAiFillAllowed('zh-Hans'), true);
});

test('the prompt names the language, level and kind', () => {
  const p = buildGenerationPrompt({ language: 'ko', level: 'A2', kind: 'grammar' });
  assert.match(p, /ko/);
  assert.match(p, /A2/);
  assert.match(p, /grammar/);
  assert.match(p, /JSON/i);
});

test('a valid generation is accepted and stamped as unreviewed AI content', () => {
  const { item, errors } = acceptGeneratedItem(rawValid(), { language: 'ko', level: 'A2', kind: 'grammar' });
  assert.deepEqual(errors, []);
  assert.equal(item.source, 'ai');
  assert.equal(item.approved, true);
  assert.equal(item.needsReview, true);
  assert.equal(item.language, 'ko');
  assert.equal(item.level, 'A2');
  assert.equal(item.kind, 'grammar');
});

test('the generator cannot override language, level or kind', () => {
  const raw = { ...rawValid(), language: 'en', level: 'C2', kind: 'vocabulary' };
  const { item } = acceptGeneratedItem(raw, { language: 'ko', level: 'A2', kind: 'grammar' });
  assert.equal(item.language, 'ko');
  assert.equal(item.level, 'A2');
  assert.equal(item.kind, 'grammar');
});

test('a malformed generation is rejected with errors and no item', () => {
  const raw = { ...rawValid(), quickCheck: [] };
  const { item, errors } = acceptGeneratedItem(raw, { language: 'ko', level: 'A2', kind: 'grammar' });
  assert.equal(item, null);
  assert.ok(errors.length > 0);
});

test('a null generation is rejected rather than throwing', () => {
  const { item, errors } = acceptGeneratedItem(null, { language: 'ko', level: 'A2', kind: 'grammar' });
  assert.equal(item, null);
  assert.ok(errors.length > 0);
});

test('an attempt to sneak English content through is rejected', () => {
  const { item, errors } = acceptGeneratedItem(rawValid(), { language: 'en', level: 'A2', kind: 'grammar' });
  assert.equal(item, null);
  assert.ok(errors.some((e) => /curated/i.test(e)));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyItemGenerator`
Expected: FAIL — `Cannot find module '../services/dailyItemGenerator'`

- [ ] **Step 3: Write minimal implementation**

Create `services/dailyItemGenerator.js`:

```js
'use strict';

const { validateDailyItem } = require('../lib/dailyItemShape');
const { chatCompletion, parseJSONResponse } = require('./aiProviderService');

/**
 * English is ~8x the next language and is served curated content only. An
 * unreviewed generation must never reach the majority audience.
 */
const isAiFillAllowed = (language) => language !== 'en';

const buildGenerationPrompt = ({ language, level, kind }) => `
You are writing one ${kind} item for learners of language code "${language}" at CEFR level ${level}.

Return ONLY a JSON object, no prose, with exactly these keys:
{
  "title": short name of the ${kind} point,
  "explanation": { "en": "2-3 sentences in English explaining it" },
  "examples": [ { "text": "sentence in the target language", "translation": { "en": "English gloss" } } ],
  "quickCheck": [ { "prompt": "...", "options": ["...","..."], "answerIndex": 0, "explanation": "..." } ]
}

Requirements: at least 2 examples; exactly 3 quickCheck entries; each quickCheck
has at least 2 options and an answerIndex pointing at the correct one; the
explanation is under 1200 characters. Example text must be in the target
language, not English.
`.trim();

/**
 * Gate a raw generation. Returns { item, errors }; item is null when rejected.
 * The caller's (language, level, kind) always wins over anything the model
 * returned, so a model cannot redirect its output at another audience.
 */
const acceptGeneratedItem = (raw, { language, level, kind }) => {
  if (!isAiFillAllowed(language)) {
    return { item: null, errors: [`${language} is curated-only; AI fill is not permitted`] };
  }
  if (!raw || typeof raw !== 'object') {
    return { item: null, errors: ['generation was empty or not an object'] };
  }

  const item = {
    language,
    level,
    kind,
    title: raw.title,
    explanation: raw.explanation,
    examples: raw.examples,
    quickCheck: raw.quickCheck,
    source: 'ai',
    approved: true,
    needsReview: true,
    timesUsed: 0,
    lastUsedDate: null,
  };

  const errors = validateDailyItem(item);
  return errors.length ? { item: null, errors } : { item, errors: [] };
};

/** Generate one item. Returns null on any failure — callers fall back to reuse. */
const generateDailyItem = async ({ language, level, kind }) => {
  if (!isAiFillAllowed(language)) return null;
  try {
    const response = await chatCompletion({
      messages: [{ role: 'user', content: buildGenerationPrompt({ language, level, kind }) }],
      feature: 'daily_drop_generation',
    });
    const raw = parseJSONResponse(response.content || response);
    const { item, errors } = acceptGeneratedItem(raw, { language, level, kind });
    if (!item) {
      console.warn(`[DailyDrop] generation rejected for ${language}/${level}/${kind}:`, errors);
      return null;
    }
    return item;
  } catch (err) {
    console.error(`[DailyDrop] generation failed for ${language}/${level}/${kind}:`, err.message);
    return null;
  }
};

module.exports = { isAiFillAllowed, buildGenerationPrompt, acceptGeneratedItem, generateDailyItem };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Add `needsReview` to the model and commit**

Add to `models/DailyItem.js`, after the `approved` line:

```js
  needsReview: { type: Boolean, default: false },
```

```bash
git add services/dailyItemGenerator.js test/dailyItemGenerator.test.js models/DailyItem.js
git commit -m "feat(study): AI fill for non-English daily items

English is curated-only and rejected by the gate. Caller's language,
level and kind always override whatever the model returned."
```

---

## Task 7: Completion scoring and streak (backend)

Spec §4.7. Pure functions first so the streak rule is testable without Mongo.

**Files:**
- Create: `lib/dailyCompletion.js`
- Test: `test/dailyDropCompletion.test.js`

**Interfaces:**
- Consumes: nothing
- Produces: `scoreQuickCheck(quickCheck, answers) -> number`, `isDayComplete(completionsForDay) -> boolean`, `nextStreak({ currentStreak, lastActivityDateKey, todayKey }) -> number`, `toDateKey(date) -> string`

- [ ] **Step 1: Write the failing test**

Create `test/dailyDropCompletion.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const { scoreQuickCheck, isDayComplete, nextStreak, toDateKey } = require('../lib/dailyCompletion');

const qc = [
  { prompt: 'q1', options: ['a', 'b'], answerIndex: 0 },
  { prompt: 'q2', options: ['a', 'b'], answerIndex: 1 },
  { prompt: 'q3', options: ['a', 'b', 'c'], answerIndex: 2 },
];

test('scores every correct answer', () => {
  assert.equal(scoreQuickCheck(qc, [0, 1, 2]), 3);
});

test('scores partial and zero correctly', () => {
  assert.equal(scoreQuickCheck(qc, [0, 0, 0]), 1);
  assert.equal(scoreQuickCheck(qc, [1, 0, 0]), 0);
});

test('missing or short answer arrays score what they can', () => {
  assert.equal(scoreQuickCheck(qc, [0]), 1);
  assert.equal(scoreQuickCheck(qc, []), 0);
  assert.equal(scoreQuickCheck(qc, null), 0);
});

test('a day is complete only when BOTH kinds are done', () => {
  assert.equal(isDayComplete([{ kind: 'grammar' }]), false);
  assert.equal(isDayComplete([{ kind: 'vocabulary' }]), false);
  assert.equal(isDayComplete([{ kind: 'grammar' }, { kind: 'vocabulary' }]), true);
});

test('duplicate rows of one kind do not complete the day', () => {
  assert.equal(isDayComplete([{ kind: 'grammar' }, { kind: 'grammar' }]), false);
});

test('a consecutive day increments the streak', () => {
  assert.equal(nextStreak({ currentStreak: 4, lastActivityDateKey: '2026-08-22', todayKey: '2026-08-23' }), 5);
});

test('a gap resets the streak to 1', () => {
  assert.equal(nextStreak({ currentStreak: 9, lastActivityDateKey: '2026-08-20', todayKey: '2026-08-23' }), 1);
});

test('same-day re-completion does not double-count', () => {
  assert.equal(nextStreak({ currentStreak: 4, lastActivityDateKey: '2026-08-23', todayKey: '2026-08-23' }), 4);
});

test('a first-ever completion starts the streak at 1', () => {
  assert.equal(nextStreak({ currentStreak: 0, lastActivityDateKey: null, todayKey: '2026-08-23' }), 1);
});

test('the streak survives a month boundary', () => {
  assert.equal(nextStreak({ currentStreak: 2, lastActivityDateKey: '2026-07-31', todayKey: '2026-08-01' }), 3);
});

test('toDateKey formats a UTC day', () => {
  assert.equal(toDateKey(new Date('2026-08-23T23:59:00Z')), '2026-08-23');
  assert.equal(toDateKey(new Date('2026-01-05T00:00:00Z')), '2026-01-05');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyDropCompletion`
Expected: FAIL — `Cannot find module '../lib/dailyCompletion'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/dailyCompletion.js`:

```js
'use strict';

const KINDS_REQUIRED = ['grammar', 'vocabulary'];

const toDateKey = (date) => new Date(date).toISOString().slice(0, 10);

const scoreQuickCheck = (quickCheck, answers) => {
  if (!Array.isArray(quickCheck) || !Array.isArray(answers)) return 0;
  return quickCheck.reduce(
    (n, q, i) => (answers[i] === q.answerIndex ? n + 1 : n),
    0
  );
};

/** The day counts only when BOTH kinds are done — that is the streak trigger. */
const isDayComplete = (completionsForDay) => {
  const kinds = new Set((completionsForDay || []).map((c) => c.kind));
  return KINDS_REQUIRED.every((k) => kinds.has(k));
};

/**
 * Streak on day completion. Idempotent for same-day re-submission, resets on
 * any gap. Date arithmetic is done in UTC on the 'YYYY-MM-DD' key.
 */
const nextStreak = ({ currentStreak, lastActivityDateKey, todayKey }) => {
  if (!lastActivityDateKey) return 1;
  if (lastActivityDateKey === todayKey) return currentStreak;

  const prev = new Date(`${lastActivityDateKey}T00:00:00Z`);
  const today = new Date(`${todayKey}T00:00:00Z`);
  const days = Math.round((today - prev) / 86400000);
  return days === 1 ? (currentStreak || 0) + 1 : 1;
};

module.exports = { scoreQuickCheck, isDayComplete, nextStreak, toDateKey, KINDS_REQUIRED };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add lib/dailyCompletion.js test/dailyDropCompletion.test.js
git commit -m "feat(study): daily completion scoring and streak rule

Both kinds required to complete a day. Same-day re-submission is
idempotent; any gap resets to 1."
```

---

## Task 8: API endpoints (backend)

Spec §4.6.

**Files:**
- Create: `controllers/dailyStudy.js`, `routes/dailyStudy.js`
- Modify: `server.js`

**Interfaces:**
- Consumes: `toBaseLanguage`, `buildDropPlan`, `scoreQuickCheck`/`isDayComplete`/`nextStreak`/`toDateKey`, `nudgeLevel`, `DEFAULT_LEVEL`
- Produces: HTTP endpoints under `/api/v1/study`

- [ ] **Step 1: Write `controllers/dailyStudy.js`**

```js
const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/User');
const LearningProgress = require('../models/LearningProgress');
const DailyItem = require('../models/DailyItem');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const { toBaseLanguage } = require('../utils/languageNormalize');
const { buildDropPlan } = require('../services/dailyDropService');
const { DEFAULT_LEVEL, nudgeLevel } = require('../lib/dailyLevels');
const {
  scoreQuickCheck, isDayComplete, nextStreak, toDateKey,
} = require('../lib/dailyCompletion');
const { XP_REWARDS } = require('../config/xpRewards');

const DAILY_DROP_XP = (XP_REWARDS && XP_REWARDS.DAILY_DROP) || 20;

/** Resolve the caller's (language, level), normalizing variants. */
const resolveTarget = (user, overrides = {}) => {
  const raw = Array.isArray(user.language_to_learn)
    ? user.language_to_learn[0]
    : user.language_to_learn;
  const language = overrides.lang || toBaseLanguage(raw);
  const level = overrides.level || user.languageLevel || DEFAULT_LEVEL;
  return { language, level };
};

const serializeItem = (item, locale) => {
  if (!item) return null;
  const explanation = item.explanation instanceof Map
    ? (item.explanation.get(locale) || item.explanation.get('en'))
    : (item.explanation[locale] || item.explanation.en);
  return {
    id: item._id,
    kind: item.kind,
    level: item.level,
    title: item.title,
    explanation,
    examples: (item.examples || []).map((e) => ({
      text: e.text,
      translation: e.translation instanceof Map
        ? (e.translation.get(locale) || e.translation.get('en') || '')
        : ((e.translation || {})[locale] || (e.translation || {}).en || ''),
    })),
    // answerIndex is deliberately withheld; the server scores submissions.
    quickCheck: (item.quickCheck || []).map((q) => ({
      prompt: q.prompt, options: q.options,
    })),
  };
};

// @desc    Today's grammar + vocabulary for the caller
// @route   GET /api/v1/study/daily
exports.getDailyDrop = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.user.id).select(
    'language_to_learn languageLevel'
  );
  const { language, level } = resolveTarget(user, req.query);
  const dateKey = req.query.date || toDateKey(new Date());
  const locale = req.query.locale || 'en';

  if (!language) {
    // 134 active users have a blank language_to_learn. Tell the client to ask
    // rather than returning an empty screen (spec §4.1).
    return res.status(200).json({
      success: true,
      data: { needsLanguage: true, dateKey, grammar: null, vocabulary: null },
    });
  }

  const bank = await DailyItem.find({ language, approved: true }).lean();
  const grammar = buildDropPlan({ language, level, kind: 'grammar', bank });
  const vocabulary = buildDropPlan({ language, level, kind: 'vocabulary', bank });

  const completions = await DailyDropCompletion.find({
    user: req.user.id, dateKey,
  }).select('kind score').lean();

  res.status(200).json({
    success: true,
    data: {
      needsLanguage: false,
      dateKey,
      language,
      requestedLevel: level,
      servedLevel: grammar.usedFallbackLevel || vocabulary.usedFallbackLevel || level,
      grammar: serializeItem(grammar.item, locale),
      vocabulary: serializeItem(vocabulary.item, locale),
      completed: completions.map((c) => ({ kind: c.kind, score: c.score })),
      dayComplete: isDayComplete(completions),
    },
  });
});

// @desc    Submit quick-check answers for one item
// @route   POST /api/v1/study/daily/:itemId/complete
exports.completeDailyItem = asyncHandler(async (req, res, next) => {
  const item = await DailyItem.findById(req.params.itemId).lean();
  if (!item) return next(new ErrorResponse('Daily item not found', 404));

  const dateKey = req.body.dateKey || toDateKey(new Date());
  const score = scoreQuickCheck(item.quickCheck, req.body.answers);

  // Unique index on (user, dateKey, kind) makes re-submission idempotent.
  await DailyDropCompletion.updateOne(
    { user: req.user.id, dateKey, kind: item.kind },
    { $setOnInsert: { user: req.user.id, dateKey, kind: item.kind, score, completedAt: new Date() } },
    { upsert: true }
  );

  const completions = await DailyDropCompletion.find({ user: req.user.id, dateKey })
    .select('kind score').lean();
  const dayComplete = isDayComplete(completions);

  let streak = null;
  let xpAwarded = 0;
  if (dayComplete) {
    const progress = await LearningProgress.findOne({ user: req.user.id });
    if (progress) {
      const lastKey = progress.lastActivityDate ? toDateKey(progress.lastActivityDate) : null;
      const updated = nextStreak({
        currentStreak: progress.currentStreak || 0,
        lastActivityDateKey: lastKey,
        todayKey: dateKey,
      });
      if (lastKey !== dateKey) {
        progress.currentStreak = updated;
        progress.lastActivityDate = new Date();
        progress.totalXP = (progress.totalXP || 0) + DAILY_DROP_XP;
        xpAwarded = DAILY_DROP_XP;
        await progress.save();
      }
      streak = progress.currentStreak;
    }
  }

  res.status(200).json({
    success: true,
    data: {
      score,
      total: (item.quickCheck || []).length,
      correctAnswers: (item.quickCheck || []).map((q) => q.answerIndex),
      dayComplete,
      streak,
      xpAwarded,
    },
  });
});

// @desc    Too easy / too hard — nudge the caller's level and re-serve
// @route   POST /api/v1/study/daily/:itemId/feedback
exports.submitDailyFeedback = asyncHandler(async (req, res, next) => {
  const { verdict } = req.body;
  if (!['tooEasy', 'tooHard'].includes(verdict)) {
    return next(new ErrorResponse('verdict must be tooEasy or tooHard', 400));
  }
  const user = await User.findById(req.user.id).select('languageLevel');
  const updated = nudgeLevel(user.languageLevel, verdict);
  user.languageLevel = updated;
  await user.save();

  res.status(200).json({ success: true, data: { languageLevel: updated } });
});

// @desc    Previous days, for catch-up
// @route   GET /api/v1/study/daily/archive
exports.getDailyArchive = asyncHandler(async (req, res, next) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 7, 30);
  const completions = await DailyDropCompletion.find({ user: req.user.id })
    .sort({ dateKey: -1 })
    .limit(limit * 2)
    .select('dateKey kind score')
    .lean();

  const byDate = new Map();
  completions.forEach((c) => {
    if (!byDate.has(c.dateKey)) byDate.set(c.dateKey, []);
    byDate.get(c.dateKey).push(c);
  });

  const data = [...byDate.entries()]
    .slice(0, limit)
    .map(([dateKey, rows]) => ({
      dateKey,
      dayComplete: isDayComplete(rows),
      kinds: rows.map((r) => ({ kind: r.kind, score: r.score })),
    }));

  res.status(200).json({ success: true, count: data.length, data });
});
```

- [ ] **Step 2: Write `routes/dailyStudy.js`**

```js
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getDailyDrop, completeDailyItem, submitDailyFeedback, getDailyArchive,
} = require('../controllers/dailyStudy');

router.use(protect);

router.get('/daily', getDailyDrop);
router.get('/daily/archive', getDailyArchive);
router.post('/daily/:itemId/complete', completeDailyItem);
router.post('/daily/:itemId/feedback', submitDailyFeedback);

module.exports = router;
```

- [ ] **Step 3: Mount the router**

In `server.js`, alongside the other `app.use('/api/v1/...')` lines (near line 330 where `learning` is mounted), add:

```js
app.use('/api/v1/study', require('./routes/dailyStudy'));
```

- [ ] **Step 4: Verify the app boots and routes resolve**

Run: `node -e "require('./routes/dailyStudy');require('./controllers/dailyStudy');console.log('routes ok')"`
Expected: prints `routes ok`

Then run the full suite to confirm nothing regressed: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add controllers/dailyStudy.js routes/dailyStudy.js server.js
git commit -m "feat(study): daily drop API

GET /daily serves today's grammar + vocabulary with answerIndex withheld
so the server does the scoring. Blank language_to_learn returns
needsLanguage rather than an empty screen."
```

---

## Task 9: Add `DAILY_DROP` XP reward (backend)

Task 8 falls back to a literal 20 if this key is absent. Make it explicit.

**Files:**
- Modify: `config/xpRewards.js`

- [ ] **Step 1: Add the reward key**

In `config/xpRewards.js`, inside the `XP_REWARDS` object, add:

```js
  DAILY_DROP: 20,
```

- [ ] **Step 2: Verify it is exported**

Run: `node -e "console.log(require('./config/xpRewards').XP_REWARDS.DAILY_DROP)"`
Expected: prints `20`

- [ ] **Step 3: Commit**

```bash
git add config/xpRewards.js
git commit -m "feat(study): XP reward for completing a daily drop"
```

---

## Task 10: Notification type, template and caps (backend)

Spec §4.9. The enum change and the first send land together — see Global Constraints.

**Files:**
- Modify: `models/Notification.js`, `utils/notificationTemplates.js`, `config/notificationCaps.js`, `test/notificationTypeEnum.test.js`
- Test: `test/dailyDropTemplate.test.js`

**Interfaces:**
- Produces: `getDailyDropTemplate({ kind, title, minutes }) -> { title, body, data }`

- [ ] **Step 1: Write the failing test**

Create `test/dailyDropTemplate.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const Notification = require('../models/Notification');
const { getDailyDropTemplate } = require('../utils/notificationTemplates');
const caps = require('../config/notificationCaps');

test('daily_drop is a valid Notification type', () => {
  const values = Notification.schema.path('type').enumValues;
  assert.ok(values.includes('daily_drop'), 'daily_drop missing from the enum');
});

test('daily_drop is capped at once per day', () => {
  assert.equal(caps.daily.daily_drop, 1);
});

test('the template names the actual content, not a generic nudge', () => {
  const t = getDailyDropTemplate({ kind: 'grammar', title: 'used to vs would', minutes: 2 });
  assert.match(t.title, /used to vs would/);
  assert.match(t.body, /2 min/);
});

test('the template routes to the daily drop screen', () => {
  const t = getDailyDropTemplate({ kind: 'vocabulary', title: 'Work & careers', minutes: 2 });
  assert.equal(t.data.type, 'daily_drop');
  assert.equal(t.data.screen, 'daily_drop');
  assert.equal(t.data.kind, 'vocabulary');
});

test('a missing title degrades to a generic but still valid template', () => {
  const t = getDailyDropTemplate({ kind: 'grammar', title: '', minutes: 2 });
  assert.ok(t.title.length > 0);
  assert.ok(t.body.length > 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyDropTemplate`
Expected: FAIL — `daily_drop missing from the enum`

- [ ] **Step 3: Make the three changes**

In `models/Notification.js`, append to the `type` enum array, following the existing commented-batch style:

```js
      // Study Hub Daily — daily grammar/vocabulary drop. Added here in the
      // same commit as the first send: an enum miss makes _saveToHistory
      // throw a silently-swallowed ValidationError (push fires, history row
      // and badge increment never happen). See test/notificationTypeEnum.test.js.
      'daily_drop',
```

In `config/notificationCaps.js`, add to the `daily` object:

```js
    daily_drop: 1,
```

In `utils/notificationTemplates.js`, add the function and export it:

```js
/**
 * Daily drop push. Names the actual content — "Today's grammar: used to vs
 * would" — because the existing generic copy ("You have words due") reads at
 * 12-16%.
 */
const getDailyDropTemplate = ({ kind, title, minutes = 2 }) => {
  const label = kind === 'grammar' ? "Today's grammar" : "Today's vocabulary";
  const name = (title || '').trim();
  return {
    title: name ? `${label}: ${name}` : `${label} is ready`,
    body: `${minutes} min — keep your streak going`,
    data: { type: 'daily_drop', screen: 'daily_drop', kind },
  };
};
```

Add `getDailyDropTemplate,` to the `module.exports` object.

In `test/notificationTypeEnum.test.js`, add `'daily_drop'` to the definitive list of types, with a comment noting `jobs/dailyDropJob.js` as the send site.

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add models/Notification.js utils/notificationTemplates.js config/notificationCaps.js test/dailyDropTemplate.test.js test/notificationTypeEnum.test.js
git commit -m "feat(study): daily_drop notification type, template and cap

Copy names the content instead of nudging generically. Enum entry lands
with the template so _saveToHistory cannot silently drop the row."
```

---

## Task 11: Timezone fields and local-hour bucketing (backend)

Spec §4.9. `quietHours.timezone` stays untouched — it keeps its quiet-hours meaning.

**Files:**
- Modify: `models/User.js`
- Create: `lib/localHour.js`
- Test: `test/dailyDropDelivery.test.js`

**Interfaces:**
- Produces: `localHourFor(date, timezone) -> number`, `isDeliveryHour(date, user) -> boolean`, `DEFAULT_DROP_HOUR = 19`

- [ ] **Step 1: Write the failing test**

Create `test/dailyDropDelivery.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const { localHourFor, isDeliveryHour, DEFAULT_DROP_HOUR } = require('../lib/localHour');

// 2026-08-23T10:00:00Z — a fixed instant, so these assertions are stable.
const instant = new Date('2026-08-23T10:00:00Z');

test('the default drop hour is 7pm local', () => {
  assert.equal(DEFAULT_DROP_HOUR, 19);
});

test('local hour differs by zone for the same instant', () => {
  assert.equal(localHourFor(instant, 'UTC'), 10);
  assert.equal(localHourFor(instant, 'Asia/Seoul'), 19);
  assert.equal(localHourFor(instant, 'Asia/Shanghai'), 18);
  assert.equal(localHourFor(instant, 'Europe/Moscow'), 13);
});

test('an unknown or missing timezone falls back to UTC rather than throwing', () => {
  assert.equal(localHourFor(instant, 'Not/AZone'), 10);
  assert.equal(localHourFor(instant, null), 10);
});

test('a Seoul user with the default hour is due at this instant', () => {
  assert.equal(isDeliveryHour(instant, { timezone: 'Asia/Seoul' }), true);
});

test('a Shanghai user with the default hour is NOT due an hour early', () => {
  assert.equal(isDeliveryHour(instant, { timezone: 'Asia/Shanghai' }), false);
});

test('an explicit dailyDropHour overrides the default', () => {
  const user = { timezone: 'Asia/Shanghai', notificationSettings: { dailyDropHour: 18 } };
  assert.equal(isDeliveryHour(instant, user), true);
});

test('a user with no timezone is treated as UTC, not Seoul', () => {
  assert.equal(isDeliveryHour(instant, { notificationSettings: { dailyDropHour: 10 } }), true);
  assert.equal(isDeliveryHour(instant, { notificationSettings: { dailyDropHour: 19 } }), false);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyDropDelivery`
Expected: FAIL — `Cannot find module '../lib/localHour'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/localHour.js`:

```js
'use strict';

const DEFAULT_DROP_HOUR = 19;

/**
 * Hour 0-23 at `date` in `timezone`.
 *
 * Falls back to UTC on an unknown zone. Deliberately NOT Asia/Seoul: the
 * existing quietHours.timezone defaults to Seoul and nothing populates it,
 * which is why every job currently fires on Korean time for an audience that
 * is mostly Chinese- and Arabic-native.
 */
const localHourFor = (date, timezone) => {
  const tz = timezone || 'UTC';
  try {
    const fmt = new Intl.DateTimeFormat('en-US', {
      timeZone: tz, hour: 'numeric', hour12: false,
    });
    return Number(fmt.format(new Date(date))) % 24;
  } catch (err) {
    return new Date(date).getUTCHours();
  }
};

/** True when `date` is this user's configured drop hour in their own zone. */
const isDeliveryHour = (date, user) => {
  const settings = (user && user.notificationSettings) || {};
  const target = Number.isInteger(settings.dailyDropHour)
    ? settings.dailyDropHour
    : DEFAULT_DROP_HOUR;
  return localHourFor(date, user && user.timezone) === target;
};

module.exports = { localHourFor, isDeliveryHour, DEFAULT_DROP_HOUR };
```

- [ ] **Step 4: Add the User fields**

In `models/User.js`, add a top-level field near `lastActive`:

```js
  // Real IANA timezone reported by the app on launch. Distinct from
  // quietHours.timezone, which keeps its quiet-hours meaning.
  timezone: { type: String, default: null },
```

And inside the `notificationSettings` object:

```js
    dailyDropHour: { type: Number, default: 19, min: 0, max: 23 },
```

- [ ] **Step 5: Run tests and commit**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

```bash
git add lib/localHour.js models/User.js test/dailyDropDelivery.test.js
git commit -m "feat(study): per-user local-hour delivery bucketing

Unknown timezone falls back to UTC, not Asia/Seoul — the Seoul default on
quietHours.timezone is why every job fires on Korean time today."
```

---

## Task 12: Generation and delivery jobs (backend)

Spec §4.3 and §4.9.

**Files:**
- Create: `jobs/dailyDropJob.js`
- Modify: `jobs/scheduler.js`

**Interfaces:**
- Consumes: everything from Tasks 1–11
- Produces: `runDailyDropGeneration()`, `runDailyDropDelivery()`

- [ ] **Step 1: Write `jobs/dailyDropJob.js`**

```js
'use strict';

const User = require('../models/User');
const DailyItem = require('../models/DailyItem');
const DailyDrop = require('../models/DailyDrop');
const DailyDropCompletion = require('../models/DailyDropCompletion');
const notificationService = require('../services/notificationService');
const templates = require('../utils/notificationTemplates');
const { toBaseLanguage } = require('../utils/languageNormalize');
const { buildDropPlan } = require('../services/dailyDropService');
const { generateDailyItem, isAiFillAllowed } = require('../services/dailyItemGenerator');
const { LEVELS, DEFAULT_LEVEL, resolveLevelWithFallback } = require('../lib/dailyLevels');
const { toDateKey } = require('../lib/dailyCompletion');
const { isDeliveryHour } = require('../lib/localHour');

const KINDS = ['grammar', 'vocabulary'];
const ALWAYS_LEVELS = ['A1', 'A2', 'B1'];

/** (language, level) pairs worth generating: what active users actually hold. */
const activeTargets = async () => {
  const since = new Date(Date.now() - 30 * 86400000);
  const users = await User.find({ lastActive: { $gte: since } })
    .select('language_to_learn languageLevel')
    .lean();

  const pairs = new Set();
  users.forEach((u) => {
    const raws = Array.isArray(u.language_to_learn) ? u.language_to_learn : [u.language_to_learn];
    raws.map(toBaseLanguage).filter(Boolean).forEach((lang) => {
      const level = LEVELS.includes(u.languageLevel) ? u.languageLevel : DEFAULT_LEVEL;
      pairs.add(`${lang}|${level}`);
      ALWAYS_LEVELS.forEach((l) => pairs.add(`${lang}|${l}`));
    });
  });

  return [...pairs].map((p) => {
    const [language, level] = p.split('|');
    return { language, level };
  });
};

const runDailyDropGeneration = async () => {
  const dateKey = toDateKey(new Date());
  console.log(`[DailyDrop] generating drops for ${dateKey}...`);

  const targets = await activeTargets();
  let written = 0;
  let generated = 0;
  let exhausted = 0;

  for (const { language, level } of targets) {
    const bank = await DailyItem.find({ language, approved: true }).lean();
    const chosen = {};

    for (const kind of KINDS) {
      let plan = buildDropPlan({ language, level, kind, bank });

      if (!plan.item && isAiFillAllowed(language)) {
        const fresh = await generateDailyItem({ language, level, kind });
        if (fresh) {
          const doc = await DailyItem.create(fresh);
          bank.push(doc.toObject());
          plan = { item: doc.toObject(), usedFallbackLevel: null };
          generated++;
        }
      }

      if (!plan.item) {
        // English never AI-fills: log the exhaustion so the bank gets extended
        // before a cohort passes the end of the cycle (spec §4.4).
        console.warn(`[DailyDrop] bank exhausted: ${language}/${level}/${kind}`);
        exhausted++;
        continue;
      }

      chosen[kind] = plan.item;
    }

    if (!chosen.grammar && !chosen.vocabulary) continue;

    await DailyDrop.updateOne(
      { dateKey, language, level },
      {
        $set: {
          grammarItem: chosen.grammar ? chosen.grammar._id : null,
          vocabItem: chosen.vocabulary ? chosen.vocabulary._id : null,
        },
      },
      { upsert: true }
    );

    const usedIds = Object.values(chosen).map((i) => i._id);
    if (usedIds.length) {
      await DailyItem.updateMany(
        { _id: { $in: usedIds } },
        { $set: { lastUsedDate: dateKey }, $inc: { timesUsed: 1 } }
      );
    }
    written++;
  }

  console.log(`[DailyDrop] drops written=${written} aiGenerated=${generated} exhausted=${exhausted}`);
};

/** Hourly. Sends to users whose LOCAL hour matches their configured slot. */
const runDailyDropDelivery = async () => {
  const now = new Date();
  const dateKey = toDateKey(now);
  const since = new Date(Date.now() - 30 * 86400000);

  const users = await User.find({
    lastActive: { $gte: since },
    'fcmTokens.0': { $exists: true },
  }).select('language_to_learn languageLevel timezone notificationSettings').lean();

  let sent = 0;
  for (const user of users) {
    if (!isDeliveryHour(now, user)) continue;

    const raw = Array.isArray(user.language_to_learn)
      ? user.language_to_learn[0] : user.language_to_learn;
    const language = toBaseLanguage(raw);
    if (!language) continue;

    // Do not nag someone who already finished today.
    const done = await DailyDropCompletion.countDocuments({ user: user._id, dateKey });
    if (done >= KINDS.length) continue;

    const level = LEVELS.includes(user.languageLevel) ? user.languageLevel : DEFAULT_LEVEL;
    const drop = await DailyDrop.findOne({ dateKey, language, level })
      .populate('grammarItem', 'title kind')
      .lean();
    if (!drop) continue;

    const item = drop.grammarItem || drop.vocabItem;
    if (!item) continue;

    await notificationService.send(
      user._id,
      'daily_drop',
      templates.getDailyDropTemplate({ kind: item.kind, title: item.title, minutes: 2 })
    );
    sent++;
  }

  console.log(`[DailyDrop] delivery: sent ${sent}`);
};

module.exports = { runDailyDropGeneration, runDailyDropDelivery, activeTargets };
```

- [ ] **Step 2: Wire into `jobs/scheduler.js`**

Add the import beside the other job imports at the top:

```js
const { runDailyDropGeneration, runDailyDropDelivery } = require('./dailyDropJob');
```

Add two scheduler functions, following the existing `scheduleSrsReviewReminders` pattern:

```js
/**
 * Daily drop generation — 00:05 KST, before any user's local delivery hour
 * in the practical range of zones.
 */
const scheduleDailyDropGeneration = () => {
  const runJob = async () => {
    console.log('\n⏰ Running scheduled daily drop generation...');
    try {
      await runDailyDropGeneration();
    } catch (error) {
      console.error('Scheduled daily drop generation failed:', error);
    }
    setTimeout(runJob, 24 * 60 * 60 * 1000);
  };
  const msUntilNextRun = getMillisecondsUntil(0, 5);
  console.log(`📅 Daily drop generation scheduled in ${Math.round(msUntilNextRun / 1000 / 60)} minutes`);
  setTimeout(runJob, msUntilNextRun);
};

/** Daily drop delivery — hourly; each user is filtered by their own local hour. */
const scheduleDailyDropDelivery = () => {
  const runJob = async () => {
    try {
      await runDailyDropDelivery();
    } catch (error) {
      console.error('Scheduled daily drop delivery failed:', error);
    }
  };
  setInterval(runJob, 60 * 60 * 1000);
  console.log('📅 Daily drop delivery scheduled (hourly)');
};
```

Call both inside the start function, beside `scheduleSrsReviewReminders()`:

```js
  scheduleDailyDropGeneration();
  scheduleDailyDropDelivery();
```

- [ ] **Step 3: Verify the job loads and the scheduler still parses**

Run: `node -e "require('./jobs/dailyDropJob');require('./jobs/scheduler');console.log('jobs ok')"`
Expected: prints `jobs ok`

- [ ] **Step 4: Run the full suite**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add jobs/dailyDropJob.js jobs/scheduler.js
git commit -m "feat(study): daily drop generation and local-time delivery jobs

Generation at 00:05 KST; delivery runs hourly and filters each user by
their own local hour. Users who already finished today are not nagged."
```

---

## Task 13: Notification click tracking (backend, prerequisite P2)

Spec §4.10 P2. `clicked` is false on all 4,564 rows because nothing ever reports a tap; without this the wave is unmeasurable.

**Files:**
- Modify: `controllers/notifications.js`, `routes/notifications.js`

**Interfaces:**
- Produces: `POST /api/v1/notifications/:id/clicked`

- [ ] **Step 1: Add the controller**

In `controllers/notifications.js`, add and export:

```js
// @desc    Record that the user tapped a notification
// @route   POST /api/v1/notifications/:id/clicked
exports.markNotificationClicked = asyncHandler(async (req, res, next) => {
  const result = await Notification.updateOne(
    { _id: req.params.id, userId: req.user.id, clicked: { $ne: true } },
    { $set: { clicked: true, clickedAt: new Date(), read: true } }
  );
  res.status(200).json({ success: true, data: { updated: result.modifiedCount === 1 } });
});
```

- [ ] **Step 2: Add the route**

In `routes/notifications.js`, add to the imports from the controller and register:

```js
router.post('/:id/clicked', markNotificationClicked);
```

- [ ] **Step 3: Verify it loads**

Run: `node -e "const c=require('./controllers/notifications');if(!c.markNotificationClicked)throw new Error('missing');console.log('ok')"`
Expected: prints `ok`

- [ ] **Step 4: Run the full suite**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add controllers/notifications.js routes/notifications.js
git commit -m "feat(notifications): record notification taps

clicked is false on all 4,564 existing rows because nothing ever reported
a tap. Without this, daily_drop effectiveness is unmeasurable."
```

---

## Task 14: Curated English bank — data and seeder (backend)

Spec §4.4. 30 days × 2 kinds × 3 levels = 180 items.

**Files:**
- Create: `migrations/dailyItemsData.json`, `seeds/dailyItems.js`
- Test: `test/dailyItemsSeedData.test.js`

**Interfaces:**
- Consumes: `validateDailyItemsData` from `lib/dailyItemShape.js`
- Produces: a seeded, approved English bank

- [ ] **Step 1: Write the failing test**

Create `test/dailyItemsSeedData.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { validateDailyItemsData } = require('../lib/dailyItemShape');

const DATA = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'migrations', 'dailyItemsData.json'), 'utf8')
);

test('the whole data file is shape-valid', () => {
  assert.deepEqual(validateDailyItemsData(DATA), []);
});

test('the bank is 30 days x 2 kinds x 3 levels', () => {
  assert.equal(DATA.length, 180);
});

test('every item is English and curated', () => {
  DATA.forEach((i, n) => {
    assert.equal(i.language, 'en', `item ${n} is not English`);
    assert.equal(i.source, 'curated', `item ${n} is not curated`);
  });
});

test('each (level, kind) pair has exactly 30 items', () => {
  const counts = {};
  DATA.forEach((i) => {
    const key = `${i.level}|${i.kind}`;
    counts[key] = (counts[key] || 0) + 1;
  });
  ['A1', 'A2', 'B1'].forEach((level) => {
    ['grammar', 'vocabulary'].forEach((kind) => {
      assert.equal(counts[`${level}|${kind}`], 30, `${level}/${kind} has ${counts[`${level}|${kind}`]}`);
    });
  });
});

test('titles are unique within a (level, kind) pool — the seeder upserts on them', () => {
  const seen = new Set();
  DATA.forEach((i) => {
    const key = `${i.language}|${i.level}|${i.kind}|${i.title}`;
    assert.ok(!seen.has(key), `duplicate title: ${key}`);
    seen.add(key);
  });
});

test('every item carries zh-Hans and ar explanations', () => {
  DATA.forEach((i, n) => {
    assert.ok(i.explanation['zh-Hans'], `item ${n} missing zh-Hans explanation`);
    assert.ok(i.explanation.ar, `item ${n} missing ar explanation`);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test 2>&1 | grep -A3 dailyItemsSeedData`
Expected: FAIL — `ENOENT: no such file or directory ... dailyItemsData.json`

- [ ] **Step 3: Author the data file**

Create `migrations/dailyItemsData.json` — a JSON array of 180 objects. Grammar is the priority: only 6 grammar lessons exist in the whole product today, so this is where new material adds real coverage rather than duplicating the 12,600 unused exam vocabulary words.

Each object has exactly this shape:

```json
{
  "language": "en",
  "level": "A2",
  "kind": "grammar",
  "title": "used to vs would",
  "explanation": {
    "en": "Both describe repeated actions in the past. Only \"used to\" can describe a past state — something that was true rather than something that happened.",
    "zh-Hans": "两者都可以表示过去反复发生的动作。但只有 \"used to\" 能表示过去的状态。",
    "ar": "كلاهما يصف أفعالًا متكررة في الماضي، لكن \"used to\" وحدها تصف حالة ماضية."
  },
  "examples": [
    { "text": "I used to live in Seoul.", "translation": { "en": "a past state", "zh-Hans": "过去的状态", "ar": "حالة ماضية" } },
    { "text": "We would walk home together every day.", "translation": { "en": "a repeated past action", "zh-Hans": "过去反复的动作", "ar": "فعل ماضٍ متكرر" } }
  ],
  "quickCheck": [
    { "prompt": "I ___ be very shy as a child.", "options": ["used to", "would", "use to"], "answerIndex": 0, "explanation": "\"Be shy\" is a state, so only \"used to\" works." },
    { "prompt": "Every summer we ___ visit my grandmother.", "options": ["used to", "would", "both are correct"], "answerIndex": 2, "explanation": "A repeated action allows either form." },
    { "prompt": "She ___ have long hair.", "options": ["would", "used to", "will"], "answerIndex": 1, "explanation": "\"Have long hair\" is a state." }
  ],
  "source": "curated",
  "approved": true
}
```

Coverage requirement — 30 distinct points per `(level, kind)`:

- **A1 grammar:** present simple, articles a/an/the, plural nouns, `be` vs `have`, possessives, this/that/these/those, question word order, prepositions of place, prepositions of time, `can` for ability, imperatives, there is / there are, present continuous, adjective order basics, object pronouns, `like` + -ing, countable vs uncountable, some/any, frequency adverbs, `going to` future, past simple of `be`, regular past simple, common irregular past, `because`/`but`/`and`, comparative adjectives, superlative adjectives, `have to`, `let's`, telling the time, basic word order S-V-O.
- **A2 grammar:** present perfect vs past simple, `used to` vs `would`, first conditional, `will` vs `going to`, comparatives with `as…as`, relative clauses with who/which/that, `too`/`enough`, past continuous, `should`/`shouldn't`, `must` vs `have to`, quantifiers, present perfect with for/since, gerund vs infinitive, reflexive pronouns, `both`/`either`/`neither`, adverbs of manner, phrasal verb basics, indirect questions, `so`/`such`, question tags, `be able to`, future time clauses, `each`/`every`, possessive pronouns, passive present simple, `enough`/`plenty of`, `still`/`yet`/`already`, order of adjectives, `would like` vs `like`, linking with `however`.
- **B1 grammar:** second conditional, third conditional, reported speech, passive past simple, `wish` + past, defining vs non-defining relative clauses, modals of deduction, past perfect, `have something done`, `used to` vs `be used to`, future perfect, future continuous, `unless`, participle clauses, inversion after negative adverbials, `enough`/`too` with infinitive, causative verbs, `despite`/`although`, mixed conditionals, `it`-cleft sentences, gerund after prepositions, verb patterns with two objects, `would rather`, `had better`, emphatic `do`, countable/uncountable shifts in meaning, `so that`/`in order to`, `as if`/`as though`, quantifier + `of`, narrative tenses together.
- **Vocabulary items** (30 per level) are themed sets: at each level pick 30 distinct everyday topics (family, food, travel, weather, work, health, shopping, technology, emotions, education, transport, housing, money, hobbies, nature, city life, clothes, time, sports, communication, relationships, cooking, holidays, media, environment, science, art, law, business, daily routine). Each item's `title` is the theme, `explanation` introduces 4–6 target words in context, `examples` show two of them in sentences, and `quickCheck` tests three.

Every `explanation` must carry `en`, `zh-Hans` and `ar` — that covers the 300 Chinese-native and 79 Arabic-native active learners.

**These items must be human-reviewed before `approved: true` is set.** Generating drafts with AI is fine; shipping them unreviewed is not — English is curated-only precisely so the majority audience never sees an unreviewed generation.

- [ ] **Step 4: Write the seeder and run it dry**

Create `seeds/dailyItems.js`, mirroring `seeds/vocabPacks.js`:

```js
/**
 * DailyItem seeder. ADDITIVE ONLY.
 *
 * Safety pattern (mirrors seeds/vocabPacks.js):
 * - validates the ENTIRE data file up front; refuses to write anything on any
 *   validation error (no half-seeds)
 * - upserts on the unique (language, level, kind, title) key — re-running is
 *   idempotent; existing items get refreshed, nothing is deleted
 * - never resets timesUsed / lastUsedDate, so re-seeding does not disturb the
 *   rotation cycle
 * - prints a per-item audit line; exits non-zero on failure
 *
 * Usage: node seeds/dailyItems.js [--dry-run]
 */

const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', 'config', 'config.env') });

const DailyItem = require('../models/DailyItem');
const { validateDailyItemsData } = require('../lib/dailyItemShape');

const DATA_PATH = path.join(__dirname, '..', 'migrations', 'dailyItemsData.json');
const DRY_RUN = process.argv.includes('--dry-run');

const run = async () => {
  const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));

  const errors = validateDailyItemsData(data);
  if (errors.length) {
    console.error(`❌ ${errors.length} validation error(s); nothing written:`);
    errors.slice(0, 20).forEach((e) => console.error('  ' + e));
    process.exit(1);
  }
  console.log(`✅ ${data.length} items validated`);

  if (DRY_RUN) {
    console.log('--dry-run: no writes performed');
    return;
  }

  await mongoose.connect(process.env.MONGO_URI);

  let upserted = 0;
  for (const item of data) {
    const key = {
      language: item.language, level: item.level, kind: item.kind, title: item.title,
    };
    // $set only content fields — timesUsed and lastUsedDate are left alone so
    // re-seeding does not disturb the rotation.
    await DailyItem.updateOne(key, {
      $set: {
        explanation: item.explanation,
        examples: item.examples,
        quickCheck: item.quickCheck,
        source: 'curated',
        approved: item.approved === true,
      },
      $setOnInsert: { timesUsed: 0, lastUsedDate: null },
    }, { upsert: true });
    upserted++;
    console.log(`  ✓ ${item.language}/${item.level}/${item.kind} — ${item.title}`);
  }

  console.log(`✅ ${upserted} items upserted`);
  await mongoose.disconnect();
};

run().catch((err) => { console.error('❌ seed failed:', err); process.exit(1); });
```

Run: `node seeds/dailyItems.js --dry-run`
Expected: `✅ 180 items validated` then `--dry-run: no writes performed`

- [ ] **Step 5: Run tests and commit**

Run: `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

```bash
git add migrations/dailyItemsData.json seeds/dailyItems.js test/dailyItemsSeedData.test.js
git commit -m "feat(study): 30-day curated English bank (180 items)

Grammar-weighted: the product has 6 grammar lessons total, so this is
where new material adds coverage rather than duplicating 12,600 unused
exam vocabulary words. Explanations carry en, zh-Hans and ar."
```

---

## Task 15: Dart language normalization (app)

Spec §4.1, client mirror.

**Files:**
- Create: `lib/utils/language_normalize.dart`
- Test: `test/learning/language_normalize_test.dart`

**Interfaces:**
- Produces: `String? toBaseLanguage(String? value)`

- [ ] **Step 1: Write the failing test**

Create `test/learning/language_normalize_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/utils/language_normalize.dart';

void main() {
  test('all four English variants collapse to en', () {
    expect(toBaseLanguage('English'), 'en');
    expect(toBaseLanguage('English (US)'), 'en');
    expect(toBaseLanguage('English (UK)'), 'en');
    expect(toBaseLanguage('en'), 'en');
  });

  test('Chinese scripts stay distinct', () {
    expect(toBaseLanguage('Chinese (Simplified)'), 'zh-Hans');
    expect(toBaseLanguage('Chinese (Traditional)'), 'zh-Hant');
  });

  test('matching is case and whitespace insensitive', () {
    expect(toBaseLanguage('  english '), 'en');
    expect(toBaseLanguage('KOREAN'), 'ko');
  });

  test('empty, null and unknown values return null', () {
    expect(toBaseLanguage(''), isNull);
    expect(toBaseLanguage('   '), isNull);
    expect(toBaseLanguage(null), isNull);
    expect(toBaseLanguage('Klingon'), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/learning/language_normalize_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:bananatalk_app/utils/language_normalize.dart'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/utils/language_normalize.dart`. Keep the map identical to `utils/languageNormalize.js` — the two must not drift:

```dart
/// Maps every language string observed in prod to a base code.
///
/// Mirrors the backend's `utils/languageNormalize.js`. Keep the two in sync:
/// `language_to_learn` stores "English", "English (US)", "English (UK)" and
/// "en" as four distinct values, and a query that does not normalize misses
/// about half its audience.
///
/// Chinese is deliberately not collapsed — Simplified and Traditional are
/// different written content.
const Map<String, String> baseLanguageMap = {
  'english': 'en', 'english (us)': 'en', 'english (uk)': 'en', 'en': 'en',
  'chinese (simplified)': 'zh-Hans', 'zh-hans': 'zh-Hans',
  'chinese (traditional)': 'zh-Hant', 'zh-hant': 'zh-Hant',
  'korean': 'ko', 'ko': 'ko',
  'japanese': 'ja', 'ja': 'ja',
  'french': 'fr', 'fr': 'fr',
  'russian': 'ru', 'ru': 'ru',
  'german': 'de', 'de': 'de',
  'spanish': 'es', 'es': 'es',
  'arabic': 'ar', 'ar': 'ar',
  'hindi': 'hi', 'hi': 'hi',
  'urdu': 'ur', 'ur': 'ur',
  'italian': 'it', 'it': 'it',
  'filipino': 'tl', 'tagalog': 'tl', 'tl': 'tl',
  'afrikaans': 'af', 'af': 'af',
  'turkish': 'tr', 'tr': 'tr',
  'vietnamese': 'vi', 'vi': 'vi',
  'thai': 'th', 'th': 'th',
  'indonesian': 'id', 'id': 'id',
  'portuguese': 'pt', 'pt': 'pt',
  'tajik': 'tg', 'tg': 'tg',
};

String? toBaseLanguage(String? value) {
  if (value == null) return null;
  final key = value.trim().toLowerCase();
  if (key.isEmpty) return null;
  return baseLanguageMap[key];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/learning/language_normalize_test.dart`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/utils/language_normalize.dart test/learning/language_normalize_test.dart
git commit -m "feat(study): Dart mirror of language normalization"
```

---

## Task 16: Models and API client (app)

Spec §4.6, client half.

**Files:**
- Create: `lib/models/learning/daily_drop_model.dart`
- Modify: `lib/service/endpoints.dart`, `lib/services/learning_service.dart`
- Test: `test/learning/daily_drop_model_test.dart`

**Interfaces:**
- Produces: `DailyItem`, `DailyDropState`, `DailyCompletionResult`; `LearningService.getDailyDrop()`, `.completeDailyItem()`, `.submitDailyFeedback()`

- [ ] **Step 1: Write the failing test**

Create `test/learning/daily_drop_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';

void main() {
  final json = {
    'needsLanguage': false,
    'dateKey': '2026-08-23',
    'language': 'en',
    'requestedLevel': 'A2',
    'servedLevel': 'A2',
    'grammar': {
      'id': 'g1',
      'kind': 'grammar',
      'level': 'A2',
      'title': 'used to vs would',
      'explanation': 'Both describe past habits.',
      'examples': [
        {'text': 'I used to live in Seoul.', 'translation': 'a past state'}
      ],
      'quickCheck': [
        {'prompt': 'I ___ be shy.', 'options': ['used to', 'would']}
      ],
    },
    'vocabulary': null,
    'completed': [
      {'kind': 'grammar', 'score': 2}
    ],
    'dayComplete': false,
  };

  test('parses a full drop', () {
    final state = DailyDropState.fromJson(json);
    expect(state.needsLanguage, isFalse);
    expect(state.dateKey, '2026-08-23');
    expect(state.grammar!.title, 'used to vs would');
    expect(state.grammar!.quickCheck.first.options.length, 2);
    expect(state.vocabulary, isNull);
    expect(state.dayComplete, isFalse);
    expect(state.scoreFor('grammar'), 2);
  });

  test('scoreFor returns null for a kind not yet completed', () {
    expect(DailyDropState.fromJson(json).scoreFor('vocabulary'), isNull);
  });

  test('a needsLanguage response parses without items', () {
    final state = DailyDropState.fromJson({
      'needsLanguage': true, 'dateKey': '2026-08-23',
      'grammar': null, 'vocabulary': null,
    });
    expect(state.needsLanguage, isTrue);
    expect(state.grammar, isNull);
  });

  test('a served level below the requested one is detectable', () {
    final state = DailyDropState.fromJson({...json, 'requestedLevel': 'C1', 'servedLevel': 'B1'});
    expect(state.isLevelFallback, isTrue);
  });

  test('matching requested and served levels are not a fallback', () {
    expect(DailyDropState.fromJson(json).isLevelFallback, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/learning/daily_drop_model_test.dart`
Expected: FAIL — URI does not exist

- [ ] **Step 3: Write the models**

Create `lib/models/learning/daily_drop_model.dart`:

```dart
/// Models for the Study Hub daily drop (spec §4.2, §4.6).
class DailyQuickCheck {
  final String prompt;
  final List<String> options;

  const DailyQuickCheck({required this.prompt, required this.options});

  factory DailyQuickCheck.fromJson(Map<String, dynamic> json) => DailyQuickCheck(
        prompt: json['prompt'] as String? ?? '',
        options: (json['options'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class DailyExample {
  final String text;
  final String translation;

  const DailyExample({required this.text, required this.translation});

  factory DailyExample.fromJson(Map<String, dynamic> json) => DailyExample(
        text: json['text'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
      );
}

class DailyItem {
  final String id;
  final String kind;
  final String level;
  final String title;
  final String explanation;
  final List<DailyExample> examples;
  final List<DailyQuickCheck> quickCheck;

  const DailyItem({
    required this.id,
    required this.kind,
    required this.level,
    required this.title,
    required this.explanation,
    required this.examples,
    required this.quickCheck,
  });

  factory DailyItem.fromJson(Map<String, dynamic> json) => DailyItem(
        id: json['id'].toString(),
        kind: json['kind'] as String? ?? '',
        level: json['level'] as String? ?? '',
        title: json['title'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        examples: (json['examples'] as List? ?? const [])
            .map((e) => DailyExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        quickCheck: (json['quickCheck'] as List? ?? const [])
            .map((e) => DailyQuickCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyDropState {
  final bool needsLanguage;
  final String dateKey;
  final String? language;
  final String? requestedLevel;
  final String? servedLevel;
  final DailyItem? grammar;
  final DailyItem? vocabulary;
  final Map<String, int> completedScores;
  final bool dayComplete;

  const DailyDropState({
    required this.needsLanguage,
    required this.dateKey,
    this.language,
    this.requestedLevel,
    this.servedLevel,
    this.grammar,
    this.vocabulary,
    this.completedScores = const {},
    this.dayComplete = false,
  });

  /// True when the server served an easier level than the one requested,
  /// so the card can say which level it is showing (spec §4.3).
  bool get isLevelFallback =>
      servedLevel != null && requestedLevel != null && servedLevel != requestedLevel;

  int? scoreFor(String kind) => completedScores[kind];

  factory DailyDropState.fromJson(Map<String, dynamic> json) {
    final completed = <String, int>{};
    for (final c in (json['completed'] as List? ?? const [])) {
      final m = c as Map<String, dynamic>;
      completed[m['kind'].toString()] = (m['score'] as num?)?.toInt() ?? 0;
    }
    return DailyDropState(
      needsLanguage: json['needsLanguage'] as bool? ?? false,
      dateKey: json['dateKey'] as String? ?? '',
      language: json['language'] as String?,
      requestedLevel: json['requestedLevel'] as String?,
      servedLevel: json['servedLevel'] as String?,
      grammar: json['grammar'] == null
          ? null
          : DailyItem.fromJson(json['grammar'] as Map<String, dynamic>),
      vocabulary: json['vocabulary'] == null
          ? null
          : DailyItem.fromJson(json['vocabulary'] as Map<String, dynamic>),
      completedScores: completed,
      dayComplete: json['dayComplete'] as bool? ?? false,
    );
  }
}

class DailyCompletionResult {
  final int score;
  final int total;
  final List<int> correctAnswers;
  final bool dayComplete;
  final int? streak;
  final int xpAwarded;

  const DailyCompletionResult({
    required this.score,
    required this.total,
    required this.correctAnswers,
    required this.dayComplete,
    this.streak,
    this.xpAwarded = 0,
  });

  factory DailyCompletionResult.fromJson(Map<String, dynamic> json) =>
      DailyCompletionResult(
        score: (json['score'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        correctAnswers: (json['correctAnswers'] as List? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        dayComplete: json['dayComplete'] as bool? ?? false,
        streak: (json['streak'] as num?)?.toInt(),
        xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      );
}
```

- [ ] **Step 4: Add endpoints and service methods, then run the test**

In `lib/service/endpoints.dart`, beside `vocabPacksURL` (line 292):

```dart
  static const String dailyDropURL = 'study/daily';
  static const String dailyArchiveURL = 'study/daily/archive';
  static String dailyCompleteURL(String id) => 'study/daily/$id/complete';
  static String dailyFeedbackURL(String id) => 'study/daily/$id/feedback';
```

In `lib/services/learning_service.dart`, following the `getVocabPacks` pattern:

```dart
  /// Today's grammar + vocabulary for the signed-in user.
  static Future<DailyDropState> getDailyDrop({String? locale}) async {
    final token = await _getToken();
    var url = Uri.parse('${Endpoints.baseURL}${Endpoints.dailyDropURL}');
    if (locale != null && locale.isNotEmpty) {
      url = url.replace(queryParameters: {'locale': locale});
    }
    final response = await http.get(url, headers: _getHeaders(token));
    final data = _safeJsonDecode(response.body);
    if (response.statusCode == 200 && data != null && data['data'] != null) {
      return DailyDropState.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(_getErrorMessage(data, 'Failed to load today\'s study'));
  }

  /// Submit quick-check answers for one item.
  static Future<DailyCompletionResult> completeDailyItem(
    String itemId,
    List<int> answers,
  ) async {
    final token = await _getToken();
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.dailyCompleteURL(itemId)}');
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'answers': answers}),
    );
    final data = _safeJsonDecode(response.body);
    if (response.statusCode == 200 && data != null && data['data'] != null) {
      return DailyCompletionResult.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(_getErrorMessage(data, 'Failed to submit answers'));
  }

  /// Too easy / too hard. Returns the user's new CEFR level.
  static Future<String> submitDailyFeedback(String itemId, String verdict) async {
    final token = await _getToken();
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.dailyFeedbackURL(itemId)}');
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'verdict': verdict}),
    );
    final data = _safeJsonDecode(response.body);
    if (response.statusCode == 200 && data != null && data['data'] != null) {
      return (data['data'] as Map<String, dynamic>)['languageLevel'] as String;
    }
    throw Exception(_getErrorMessage(data, 'Failed to update level'));
  }
```

Add the import at the top of `learning_service.dart`:

```dart
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
```

Run: `flutter test test/learning/daily_drop_model_test.dart`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/models/learning/daily_drop_model.dart lib/service/endpoints.dart lib/services/learning_service.dart test/learning/daily_drop_model_test.dart
git commit -m "feat(study): daily drop models and API client"
```

---

## Task 17: Riverpod providers (app)

**Files:**
- Create: `lib/providers/provider_root/learning/daily_drop_providers.dart`

**Interfaces:**
- Consumes: `LearningService.getDailyDrop()`
- Produces: `dailyDropProvider` (a `FutureProvider<DailyDropState>`)

- [ ] **Step 1: Write the provider**

Following the pattern in `lib/providers/provider_root/learning/vocab_packs_providers.dart`:

```dart
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today's grammar + vocabulary for the signed-in user.
final dailyDropProvider = FutureProvider<DailyDropState>((ref) async {
  return LearningService.getDailyDrop();
});
```

- [ ] **Step 2: Verify it analyzes clean**

Run: `flutter analyze lib/providers/provider_root/learning/daily_drop_providers.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/providers/provider_root/learning/daily_drop_providers.dart
git commit -m "feat(study): daily drop provider"
```

---

## Task 18: Today section widget (app)

Spec §4.8.

**Files:**
- Create: `lib/pages/learning/daily/widgets/today_section.dart`
- Test: `test/learning/today_section_test.dart`

**Interfaces:**
- Consumes: `DailyDropState`
- Produces: `TodaySection({required DailyDropState state, required void Function(DailyItem) onOpen, required VoidCallback onPickLanguage})`

- [ ] **Step 1: Write the failing test**

Create `test/learning/today_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/today_section.dart';

DailyItem _item(String kind, String title) => DailyItem(
      id: '$kind-1', kind: kind, level: 'A2', title: title,
      explanation: 'why', examples: const [], quickCheck: const [],
    );

Widget _host(DailyDropState state, {void Function(DailyItem)? onOpen, VoidCallback? onPick}) =>
    MaterialApp(
      home: Scaffold(
        body: TodaySection(
          state: state,
          onOpen: onOpen ?? (_) {},
          onPickLanguage: onPick ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('shows both cards when both items are present', (tester) async {
    await tester.pumpWidget(_host(DailyDropState(
      needsLanguage: false, dateKey: '2026-08-23',
      grammar: _item('grammar', 'used to vs would'),
      vocabulary: _item('vocabulary', 'Work & careers'),
    )));
    expect(find.text('used to vs would'), findsOneWidget);
    expect(find.text('Work & careers'), findsOneWidget);
  });

  testWidgets('tapping a card reports the item', (tester) async {
    DailyItem? opened;
    await tester.pumpWidget(_host(
      DailyDropState(
        needsLanguage: false, dateKey: '2026-08-23',
        grammar: _item('grammar', 'used to vs would'),
      ),
      onOpen: (i) => opened = i,
    ));
    await tester.tap(find.text('used to vs would'));
    await tester.pumpAndSettle();
    expect(opened?.kind, 'grammar');
  });

  testWidgets('a completed kind renders its score and does not call onOpen', (tester) async {
    var opens = 0;
    await tester.pumpWidget(_host(
      DailyDropState(
        needsLanguage: false, dateKey: '2026-08-23',
        grammar: _item('grammar', 'used to vs would'),
        completedScores: const {'grammar': 3},
      ),
      onOpen: (_) => opens++,
    ));
    expect(find.text('3/3'), findsOneWidget);
    await tester.tap(find.text('used to vs would'));
    await tester.pumpAndSettle();
    expect(opens, 0);
  });

  testWidgets('needsLanguage shows the picker prompt instead of cards', (tester) async {
    var picked = 0;
    await tester.pumpWidget(_host(
      const DailyDropState(needsLanguage: true, dateKey: '2026-08-23'),
      onPick: () => picked++,
    ));
    expect(find.byKey(const Key('today-pick-language')), findsOneWidget);
    await tester.tap(find.byKey(const Key('today-pick-language')));
    await tester.pumpAndSettle();
    expect(picked, 1);
  });

  testWidgets('a level fallback is disclosed to the user', (tester) async {
    await tester.pumpWidget(_host(DailyDropState(
      needsLanguage: false, dateKey: '2026-08-23',
      requestedLevel: 'C1', servedLevel: 'B1',
      grammar: _item('grammar', 'used to vs would'),
    )));
    expect(find.byKey(const Key('today-level-fallback')), findsOneWidget);
  });

  testWidgets('renders nothing rather than crashing when both items are null', (tester) async {
    await tester.pumpWidget(_host(
      const DailyDropState(needsLanguage: false, dateKey: '2026-08-23'),
    ));
    expect(find.byKey(const Key('today-empty')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/learning/today_section_test.dart`
Expected: FAIL — URI does not exist

- [ ] **Step 3: Write the widget**

Create `lib/pages/learning/daily/widgets/today_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The two "Today" cards at the top of the Learn tab (spec §4.8).
class TodaySection extends StatelessWidget {
  final DailyDropState state;
  final void Function(DailyItem) onOpen;
  final VoidCallback onPickLanguage;

  const TodaySection({
    super.key,
    required this.state,
    required this.onOpen,
    required this.onPickLanguage,
  });

  @override
  Widget build(BuildContext context) {
    if (state.needsLanguage) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('today-pick-language'),
          onPressed: onPickLanguage,
          child: const Text('What are you learning?'),
        ),
      );
    }

    final items = [state.grammar, state.vocabulary].whereType<DailyItem>().toList();
    if (items.isEmpty) {
      return const SizedBox(key: Key('today-empty'), height: 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isLevelFallback)
          Padding(
            key: const Key('today-level-fallback'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Showing ${state.servedLevel} — no ${state.requestedLevel} content yet',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...items.map((item) => _TodayCard(
              item: item,
              score: state.scoreFor(item.kind),
              onTap: () => onOpen(item),
            )),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final DailyItem item;
  final int? score;
  final VoidCallback onTap;

  const _TodayCard({required this.item, required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = score != null;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListTile(
        onTap: done ? null : onTap,
        leading: Icon(item.kind == 'grammar' ? Icons.rule : Icons.style),
        title: Text(item.title),
        subtitle: Text(
          item.kind == 'grammar' ? "Today's grammar · 2 min" : "Today's vocabulary · 2 min",
        ),
        trailing: done
            ? Text('$score/3', style: Theme.of(context).textTheme.titleMedium)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/learning/today_section_test.dart`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/pages/learning/daily/widgets/today_section.dart test/learning/today_section_test.dart
git commit -m "feat(study): Today section with grammar and vocabulary cards

Discloses a level fallback rather than silently serving easier content."
```

---

## Task 19: Daily drop screen (app)

Spec §4.8.

**Files:**
- Create: `lib/pages/learning/daily/daily_drop_screen.dart`
- Test: `test/learning/daily_drop_screen_test.dart`

**Interfaces:**
- Consumes: `DailyItem`, `LearningService.completeDailyItem`, `LearningService.submitDailyFeedback`
- Produces: `DailyDropScreen({required DailyItem item})`

- [ ] **Step 1: Write the failing test**

The screen takes an injectable submit callback so the test never hits the network.

Create `test/learning/daily_drop_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_drop_screen.dart';

final _item = DailyItem(
  id: 'g1', kind: 'grammar', level: 'A2', title: 'used to vs would',
  explanation: 'Both describe past habits.',
  examples: const [DailyExample(text: 'I used to live in Seoul.', translation: 'past state')],
  quickCheck: const [
    DailyQuickCheck(prompt: 'Q1', options: ['a', 'b']),
    DailyQuickCheck(prompt: 'Q2', options: ['a', 'b']),
    DailyQuickCheck(prompt: 'Q3', options: ['a', 'b']),
  ],
);

Widget _host({
  Future<DailyCompletionResult> Function(String, List<int>)? submit,
  Future<String> Function(String, String)? feedback,
}) =>
    MaterialApp(
      home: DailyDropScreen(
        item: _item,
        submitAnswers: submit ??
            (_, __) async => const DailyCompletionResult(
                  score: 2, total: 3, correctAnswers: [0, 0, 0], dayComplete: false,
                ),
        submitFeedback: feedback ?? (_, __) async => 'B1',
      ),
    );

void main() {
  testWidgets('shows the explanation and every example', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('Both describe past habits.'), findsOneWidget);
    expect(find.text('I used to live in Seoul.'), findsOneWidget);
  });

  testWidgets('submit is disabled until every question is answered', (tester) async {
    await tester.pumpWidget(_host());
    final submit = find.byKey(const Key('daily-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(Key('daily-q$i-opt0')));
      await tester.pump();
    }
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('submitting sends the chosen answers and shows the score', (tester) async {
    List<int>? sent;
    await tester.pumpWidget(_host(submit: (id, answers) async {
      sent = answers;
      return const DailyCompletionResult(
          score: 3, total: 3, correctAnswers: [1, 1, 1], dayComplete: true, streak: 4, xpAwarded: 20);
    }));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(Key('daily-q$i-opt1')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('daily-submit')));
    await tester.pumpAndSettle();

    expect(sent, [1, 1, 1]);
    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets('too hard reports the verdict', (tester) async {
    String? verdict;
    await tester.pumpWidget(_host(feedback: (id, v) async { verdict = v; return 'A1'; }));
    await tester.tap(find.byKey(const Key('daily-too-hard')));
    await tester.pumpAndSettle();
    expect(verdict, 'tooHard');
  });

  testWidgets('too easy reports the verdict', (tester) async {
    String? verdict;
    await tester.pumpWidget(_host(feedback: (id, v) async { verdict = v; return 'B1'; }));
    await tester.tap(find.byKey(const Key('daily-too-easy')));
    await tester.pumpAndSettle();
    expect(verdict, 'tooEasy');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/learning/daily_drop_screen_test.dart`
Expected: FAIL — URI does not exist

- [ ] **Step 3: Write the screen**

Create `lib/pages/learning/daily/daily_drop_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';

typedef SubmitAnswers = Future<DailyCompletionResult> Function(String itemId, List<int> answers);
typedef SubmitFeedback = Future<String> Function(String itemId, String verdict);

/// One daily item: explanation, examples, and a 3-question check (spec §4.8).
///
/// The two submit callbacks are injectable so widget tests never hit the
/// network; production callers use the defaults.
class DailyDropScreen extends StatefulWidget {
  final DailyItem item;
  final SubmitAnswers submitAnswers;
  final SubmitFeedback submitFeedback;

  DailyDropScreen({
    super.key,
    required this.item,
    SubmitAnswers? submitAnswers,
    SubmitFeedback? submitFeedback,
  })  : submitAnswers = submitAnswers ?? LearningService.completeDailyItem,
        submitFeedback = submitFeedback ?? LearningService.submitDailyFeedback;

  @override
  State<DailyDropScreen> createState() => _DailyDropScreenState();
}

class _DailyDropScreenState extends State<DailyDropScreen> {
  late final List<int?> _answers =
      List<int?>.filled(widget.item.quickCheck.length, null);
  DailyCompletionResult? _result;
  bool _submitting = false;

  bool get _allAnswered => !_answers.contains(null);

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await widget.submitAnswers(
        widget.item.id,
        _answers.map((a) => a ?? -1).toList(),
      );
      if (mounted) setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _feedback(String verdict) async {
    await widget.submitFeedback(widget.item.id, verdict);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.explanation, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          ...item.examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.text, style: Theme.of(context).textTheme.titleSmall),
                    if (e.translation.isNotEmpty)
                      Text(e.translation, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              )),
          const Divider(height: 32),
          ...List.generate(item.quickCheck.length, (i) {
            final q = item.quickCheck[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.prompt, style: Theme.of(context).textTheme.titleSmall),
                ...List.generate(q.options.length, (o) => RadioListTile<int>(
                      key: Key('daily-q$i-opt$o'),
                      value: o,
                      groupValue: _answers[i],
                      title: Text(q.options[o]),
                      onChanged: _result != null
                          ? null
                          : (v) => setState(() => _answers[i] = v),
                    )),
                const SizedBox(height: 12),
              ],
            );
          }),
          if (_result != null)
            Text('${_result!.score}/${_result!.total}',
                style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('daily-submit'),
            onPressed: (!_allAnswered || _submitting || _result != null) ? null : _submit,
            child: const Text('Check'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                key: const Key('daily-too-easy'),
                onPressed: () => _feedback('tooEasy'),
                child: const Text('Too easy'),
              ),
              TextButton(
                key: const Key('daily-too-hard'),
                onPressed: () => _feedback('tooHard'),
                child: const Text('Too hard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/learning/daily_drop_screen_test.dart`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/pages/learning/daily/daily_drop_screen.dart test/learning/daily_drop_screen_test.dart
git commit -m "feat(study): daily drop screen with 3-question check

Too easy / too hard nudges the level — the calibration path for the 809
active users who have no CEFR level set."
```

---

## Task 20: Wire Today into the Learn tab (app)

Spec §4.8.

**Files:**
- Modify: `lib/pages/learning/main/sections/learn_tab.dart`

- [ ] **Step 1: Add the imports**

At the top of `learn_tab.dart`:

```dart
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_drop_screen.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/today_section.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_drop_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
```

- [ ] **Step 2: Insert the Today section as the first child**

Inside `build`, in the `Column`'s `children:` list (around line 49), make the Today section the **first** entry so it sits above the existing quick stats. The existing `DailyPracticeCard` stays where it is, below this:

```dart
              ref.watch(dailyDropProvider).when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (state) => TodaySection(
                      state: state,
                      onOpen: (item) => Navigator.of(context)
                          .push(AppPageRoute(builder: (_) => DailyDropScreen(item: item)))
                          .then((_) => ref.invalidate(dailyDropProvider)),
                      onPickLanguage: () => _pickLearningLanguage(context, ref),
                    ),
                  ),
```

- [ ] **Step 3: Add the language-picker handler**

There is no `/settings/language` route — verified against `lib/router/app_router.dart`, which only has `/exam-study/language/:languageId`. Reuse the existing picker helper instead of adding a route.

Add to `learn_tab.dart`:

```dart
/// Ask the 134 active users with a blank `language_to_learn` what they are
/// learning, then persist it and refresh today's drop (spec §4.1).
Future<void> _pickLearningLanguage(BuildContext context, WidgetRef ref) async {
  final picked = await showLanguagePickerSheet(context);
  if (picked == null) return;
  await LearningService.setLearningLanguage(picked.name);
  ref.invalidate(dailyDropProvider);
}
```

with the imports:

```dart
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/widgets/language_selection/show_language_picker.dart';
```

Add the write method to `lib/services/learning_service.dart`, using the existing profile-update endpoint (`Endpoints.updateDetailsURL`, `'auth/updatedetails'`):

```dart
  /// Persist the user's learning target. Stores the display name, matching
  /// what `language_to_learn` already holds elsewhere in the product;
  /// the server normalizes to a base code at read time.
  static Future<void> setLearningLanguage(String languageName) async {
    final token = await _getToken();
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.updateDetailsURL}');
    final response = await http.put(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'language_to_learn': [languageName]}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save learning language');
    }
  }
```

- [ ] **Step 4: Verify analysis and the existing suite**

Run: `flutter analyze lib/pages/learning/main/sections/learn_tab.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/pages/learning/main/sections/learn_tab.dart lib/services/learning_service.dart
git commit -m "feat(study): surface Today at the top of the Learn tab

Existing AI daily practice card moves below rather than competing for
the same slot."
```

---

## Task 21: Study Hub tab bar — reachability (app)

The daily drop is worthless if nobody finds it. Study Hub is one tap from the root bottom nav (`TabBarMenu.dart:65`, `_pages[0]`), but **inside** it the tabs are `[Exam Study, AI Tools, Learn]` with no `initialIndex`, so the hub opens on Exam Study and Learn — which will host the daily drop — is the last of three.

That ordering is backwards against the usage data: Exam Study has 74 progress docs, the AI tutor has 309 sessions and 56 in the last 30 days. The hub currently lands on its least-used surface.

Verified safe to reorder: nothing deep-links to a Study Hub sub-tab index. The only index dependency in the codebase is `LearnTab(onSwitchToAI: () => _tabController.animateTo(1))` at `learning_main_screen.dart:194`. `notification_router.dart:208` lists `/exam-study` as a route prefix but never targets a tab position.

**Files:**
- Create: `lib/pages/learning/main/study_hub_tabs.dart`
- Modify: `lib/pages/learning/main/learning_main_screen.dart`
- Test: `test/learning/study_hub_tabs_test.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `enum StudyHubTab { today, aiTools, examStudy }`, `studyHubTabOrder: List<StudyHubTab>`, `int indexOfTab(StudyHubTab)`

- [ ] **Step 1: Write the failing test**

Tab order becomes a pure, testable value instead of being implicit in a widget tree.

Create `test/learning/study_hub_tabs_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_tabs.dart';

void main() {
  test('Today is the landing tab', () {
    expect(studyHubTabOrder.first, StudyHubTab.today);
    expect(indexOfTab(StudyHubTab.today), 0);
  });

  test('AI Tools stays at index 1 so the existing animateTo(1) is still correct', () {
    expect(indexOfTab(StudyHubTab.aiTools), 1);
  });

  test('Exam Study moves off the front door', () {
    expect(indexOfTab(StudyHubTab.examStudy), 2);
  });

  test('the order covers every tab exactly once', () {
    expect(studyHubTabOrder.length, StudyHubTab.values.length);
    expect(studyHubTabOrder.toSet().length, studyHubTabOrder.length);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/learning/study_hub_tabs_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:bananatalk_app/pages/learning/main/study_hub_tabs.dart'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/pages/learning/main/study_hub_tabs.dart`:

```dart
/// Study Hub sub-tab order.
///
/// Extracted from the widget tree so the order is a testable value, and so a
/// future reorder cannot silently break `animateTo` call sites that used to
/// pass magic numbers.
///
/// Today leads because it hosts the daily drop — the one action we want a
/// user to take every day. Exam Study used to lead despite having 74 progress
/// docs against the AI tutor's 309 sessions.
enum StudyHubTab { today, aiTools, examStudy }

const List<StudyHubTab> studyHubTabOrder = [
  StudyHubTab.today,
  StudyHubTab.aiTools,
  StudyHubTab.examStudy,
];

int indexOfTab(StudyHubTab tab) => studyHubTabOrder.indexOf(tab);
```

- [ ] **Step 4: Rewire `learning_main_screen.dart`**

Add the import:

```dart
import 'package:bananatalk_app/pages/learning/main/study_hub_tabs.dart';
```

Replace the `tabs:` list (lines 179–183) so the labels follow `studyHubTabOrder`:

```dart
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.todayTab),
                    Tab(text: AppLocalizations.of(context)!.aiTools),
                    Tab(text: AppLocalizations.of(context)!.examStudy),
                  ],
```

Replace the `TabBarView` children (lines 191–195), swapping the magic number for the named lookup:

```dart
          children: [
            LearnTab(
              onSwitchToAI: () => _tabController.animateTo(indexOfTab(StudyHubTab.aiTools)),
            ),
            const AIToolsTab(),
            const ExamStudyTab(),
          ],
```

- [ ] **Step 5: Run the tests and commit**

Run: `flutter test test/learning/study_hub_tabs_test.dart && flutter analyze lib/pages/learning/main/learning_main_screen.dart`
Expected: tests pass, `No issues found!`

Then the full suite, to catch anything that assumed the old order: `flutter test`
Expected: all tests pass

```bash
git add lib/pages/learning/main/study_hub_tabs.dart lib/pages/learning/main/learning_main_screen.dart test/learning/study_hub_tabs_test.dart
git commit -m "feat(study): Today leads the Study Hub tab bar

The hub opened on Exam Study (74 progress docs) while the AI tutor has
309 sessions. Tab order is now a tested value and the animateTo magic
number is a named lookup."
```

---

## Task 22: Deep link and click reporting (app)

Spec §4.9 and prerequisite P2, client half.

**Files:**
- Modify: `lib/services/notification_router.dart`
- Test: `test/learning/daily_drop_router_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/learning/daily_drop_router_test.dart`. Match the assertion style already used in `test/deep_link_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/notification_router.dart';

void main() {
  test('daily_drop resolves to the daily drop route', () {
    expect(NotificationRouter.targetPathForType('daily_drop', const {}), '/learning/daily');
  });

  test('an unknown type does not resolve to the daily route', () {
    expect(NotificationRouter.targetPathForType('mystery', const {}), isNot('/learning/daily'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/learning/daily_drop_router_test.dart`
Expected: FAIL — `targetPathForType` is not defined

- [ ] **Step 3: Add the case and the click ping**

In `lib/services/notification_router.dart`, add `'daily_drop'` to the switch beside the existing `case 'srs_review': case 'streak_reminder':` block (around line 135), mapping to `/learning/daily`.

Extract the switch body into a static `targetPathForType(String type, Map<String, dynamic> data)` so it is testable without a navigator, and have the existing handler call it.

Then report the tap. In the same place the router handles a notification open, before navigating:

```dart
    // Report the tap so click-through is measurable. `clicked` is false on
    // every historical notification because nothing ever reported one.
    final notificationId = data['notificationId']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      unawaited(NotificationApiClient.markClicked(notificationId));
    }
```

Add `markClicked` to `lib/services/notification_api_client.dart`, following the existing method style in that file, posting to `notifications/$id/clicked` and swallowing failures (a lost analytics ping must never block navigation).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/learning/daily_drop_router_test.dart`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/services/notification_router.dart lib/services/notification_api_client.dart test/learning/daily_drop_router_test.dart
git commit -m "feat(study): daily_drop deep link and notification click reporting

Taps now reach the backend so click-through becomes measurable."
```

---

## Task 23: Report the device timezone (app)

Spec §4.9. Without this every user stays on the Asia/Seoul default.

**Files:**
- Modify: `lib/services/notification_service.dart`, `lib/services/notification_api_client.dart`

- [ ] **Step 1: Send the IANA zone on launch**

In `notification_service.dart`, where the FCM token is registered on launch, also report the timezone:

```dart
    // Report the device's IANA zone so the daily drop lands in the user's
    // evening, not Korea's. Everything defaults to Asia/Seoul otherwise.
    final timezone = DateTime.now().timeZoneName;
    unawaited(NotificationApiClient.updateTimezone(timezone));
```

`DateTime.now().timeZoneName` returns an abbreviation on some platforms, so use the `flutter_timezone` package for a true IANA identifier. Add to `pubspec.yaml` under `dependencies`:

```yaml
  flutter_timezone: ^3.0.1
```

Then:

```dart
    final timezone = await FlutterTimezone.getLocalTimezone();
    unawaited(NotificationApiClient.updateTimezone(timezone));
```

- [ ] **Step 2: Add the API method**

In `notification_api_client.dart`, add `updateTimezone(String tz)` posting `{'timezone': tz}` to the existing notification-preferences endpoint, following the style of the other methods in that file.

- [ ] **Step 3: Accept the field on the backend**

In `controllers/notifications.js`, in the preferences update handler that already loops over `['enabled', 'start', 'end', 'timezone', 'allowUrgent']` (line 235), also persist a top-level `req.body.timezone` to `user.timezone` when present. Validate it with `Intl.supportedValuesOf` or a try/catch around `Intl.DateTimeFormat` so a junk value cannot poison delivery bucketing.

- [ ] **Step 4: Verify**

Run: `flutter pub get && flutter analyze lib/services/notification_service.dart`
Expected: `No issues found!`

Run (backend): `npm test 2>&1 | grep -E "^# (pass|fail)"`
Expected: `# fail 0`

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/notification_service.dart lib/services/notification_api_client.dart
git commit -m "feat(study): report the device IANA timezone on launch

Every user is Asia/Seoul today because nothing ever populated a zone."
```

---

## Task 24: Localization (app)

Every user-visible string in Tasks 18, 19 and 21 is currently a hardcoded English literal. Replace them.

**Files:**
- Modify: `lib/l10n/app_en.arb` and the 18 other locale ARBs; `today_section.dart`, `daily_drop_screen.dart`

- [ ] **Step 1: Add the keys to `app_en.arb`**

```json
  "todayTab": "Today",
  "todaysGrammar": "Today's grammar",
  "todaysVocabulary": "Today's vocabulary",
  "todayMinutes": "{count} min",
  "todayPickLanguage": "What are you learning?",
  "todayLevelFallback": "Showing {served} — no {requested} content yet",
  "dailyCheck": "Check",
  "dailyTooEasy": "Too easy",
  "dailyTooHard": "Too hard",
  "dailyScore": "{score}/{total}"
```

Include the matching `@key` metadata blocks with `placeholders` for `todayMinutes`, `todayLevelFallback` and `dailyScore`, following the existing convention in the file.

- [ ] **Step 2: Translate into all 18 other locales**

Add the same 10 keys to each of: `app_ar.arb`, `app_de.arb`, `app_es.arb`, `app_fr.arb`, `app_hi.arb`, `app_id.arb`, `app_it.arb`, `app_ja.arb`, `app_ko.arb`, `app_pt.arb`, `app_ru.arb`, `app_tg.arb`, `app_th.arb`, `app_tl.arb`, `app_tr.arb`, `app_vi.arb`, `app_zh.arb`, and the remaining locale file present in `lib/l10n/`.

- [ ] **Step 3: Regenerate and swap the literals**

Run: `flutter gen-l10n`

Then replace every hardcoded string in `today_section.dart` and `daily_drop_screen.dart` with `AppLocalizations.of(context)!.<key>`, adding the import:

```dart
import 'package:bananatalk_app/l10n/app_localizations.dart';
```

Update the two widget tests to wrap their host widget with `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales`, and assert on the English values.

- [ ] **Step 4: Verify**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` and all tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/l10n lib/pages/learning/daily test/learning
git commit -m "i18n(study): translate 10 daily-drop keys into all 19 locales"
```

---

## Task 25: Deploy checklist

Not code. Do these in order and confirm each.

> **Added during implementation.** Every one of the 180 curated items ships with
> `approved: false`, and the selection query only serves approved items — so the
> English daily drop returns nothing until a human reviews them and flips the
> flag. That is deliberate: §4.4 makes English curated-only precisely so the
> majority audience never sees unreviewed content, and the items were AI-drafted.
> Step 0 below is therefore a required gate, not optional polish.

- [ ] **Step 0: Human-review the 180 items, then approve them**

Read `migrations/dailyItemsData.json`. It is ordered A1-grammar, A1-vocabulary,
A2-grammar, A2-vocabulary, B1-grammar, B1-vocabulary, 30 items each.

Known issue to watch for while reviewing: `answerIndex` skews to the middle
option (0: 34.4%, 1: 58.7%, 2: 6.9% across all 540 questions). Not wrong, but a
learner could partially game it by always picking the middle. Rebalance as you
review if you care to.

**Approve by editing `migrations/dailyItemsData.json` and re-running the
seeder. That is the only supported path.**

Do NOT flip `approved` directly in the database. `seeds/dailyItems.js` carries
`approved` inside its `$set`, so the data file is the single source of truth:
the next seeder run — for new content, for a new language, for anything —
silently reverts every hand-approved row to `approved: false`, and the English
daily drop goes back to serving nothing with no error anywhere.

So:

1. Edit `migrations/dailyItemsData.json` so the reviewed items carry
   `"approved": true`.
2. Re-run the seeder (Step 1 below). It is idempotent.
3. Update `test/dailyItemsSeedData.test.js`, which currently asserts
   `approved === false` as the guard for this gate.

- [ ] **Step 1: Seed the English bank on prod**

```bash
node seeds/dailyItems.js --dry-run   # confirm 180 validated
node seeds/dailyItems.js
```

- [ ] **Step 2: Verify the drop generation job by hand before trusting the schedule**

```bash
node -e "require('dotenv').config({path:'config/config.env'});const m=require('mongoose');m.connect(process.env.MONGO_URI).then(async()=>{await require('./jobs/dailyDropJob').runDailyDropGeneration();process.exit(0)})"
```

Expected: `drops written=<n> aiGenerated=<n> exhausted=0` with a non-zero write count.

- [ ] **Step 3: Confirm drops exist for the top languages**

Query `dailydrops` for today's `dateKey` and check that `en` A1/A2/B1 all have both `grammarItem` and `vocabItem` set.

- [ ] **Step 4: Send one delivery to a test account and confirm the whole chain**

Confirm: push arrives, the in-app history row is created (the enum trap), the badge increments, the deep link opens the drop screen, and `clicked` flips to true on tap.

- [ ] **Step 5: Record the baseline**

Re-run the §2.4 measurement queries and record `daily_drop` sent/read/clicked after 48 hours, so §6's targets have a real starting point.

---

## Deferred: spec §4.10 B1–B4

Not in this plan. `reviewCount > 0` matches 0 of 292 vocabulary rows, `userachievements` is empty against 42 defined achievements, 0 of 28 lesson-progress rows are complete, and quiz attempts and challenge progress are both 0. Four independent zero-counts may share one root cause in the progress-write path.

Investigate with the **systematic-debugging** skill, establish the root cause, and write a separate plan from what that finds. Do not patch symptoms from inside this wave.
