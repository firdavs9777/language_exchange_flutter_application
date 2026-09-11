# Daily Learning Pack — Content Implementation Plan (Wave 1, Plan 3 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author the content wave 1 needs — 120 grammar units (60 elementary, 60 intermediate) and 12 beginner vocabulary packs (240 words, 96 exercises) — and get it validated and seeded to production.

**Architecture:** Content lives in two JSON data files consumed by idempotent seeders. Correctness is enforced by executable gates, not review alone: a shape validator, an answer-position balance gate, and coverage tests that fail until the batch is complete. Every batch is validated with `--dry-run` before it can be committed, and nothing is written to production until Task 9.

**Tech Stack:** Node 24.18.0, `node:test`, existing seeders (`seeds/dailyGrammarItems.js`, `seeds/vocabPacks.js`). `pypdf` is available for syllabus extraction. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-11-daily-learning-pack-design.md` (§4)

**Depends on:** Plan 1 Tasks 4, 6 and 11 (`lib/answerBalance.js`, the `DailyItem.syllabus` field, `seeds/dailyGrammarItems.js`). This plan can be authored in parallel with Plan 2 and is the **critical path for launch** — start it on day one.

**Repo:** `/Users/davis/Desktop/Personal/language_exchange_backend_application`. Branch from `main` as `feat/daily-pack-content`.

## Global Constraints

- **Copyright boundary, non-negotiable.** The reference grammars supply the **syllabus only**: which grammar points to teach, in what order, grouped into which sections. Every explanation, example sentence, and exercise is written fresh. **No sentence from either book may be copied into the data files**, including exercise items. This mirrors the boundary already documented at the top of `models/VocabPack.js` and `seeds/vocabPacks.js`. The PDFs stay on the operator's disk and are never committed.
- **Explanation ≤ 60 words**, plain language, no metalanguage the level cannot read. `lib/dailyItemShape.js` caps at 1,200 characters; 60 words is the editorial rule.
- **Exactly 3 examples and exactly 3 quick checks per grammar unit.** `validateDailyItem()` enforces `examples.length >= 2` and `quickCheck.length === 3`; the editorial standard is 3 and 3.
- **Every quick check carries a non-empty `explanation`** saying *why* the answer is right. The app reveals it after answering (Plan 2 Task 3), so an empty one is a blank space in the UI.
- **Answer positions balanced per batch** — `lib/answerBalance.js`, ±25% relative of uniform. For 3-option questions that is 25–42% per position. The seeder refuses the batch otherwise.
- **20 words and 8 exercises per vocabulary pack**, matching the 50 packs already on prod. Exercise types drawn from `multiple_choice`, `fill_blank`, `matching`, `error_correction`.
- **`beginner` is a new level** and must be accepted by both `models/VocabPack.js` (Plan 1 Task 6) **and** `lib/vocabPackShape.js` (Task 6 here, which hardcodes `['intermediate','advanced']` independently).
- **Dry-run before every commit.** `node seeds/dailyGrammarItems.js --dry-run` and `node seeds/vocabPacks.js --dry-run` must both pass.
- **Nothing reaches production until Task 9.** Authoring commits touch data files only.

---

## File Structure

| File | Responsibility |
|---|---|
| Create `scripts/extractGrammarSyllabus.js` | Derives the unit list from an operator-supplied PDF into a local working file (never committed) |
| Create `docs/content/grammar-authoring-rubric.md` | The editorial contract every unit is written against |
| Create `test/dailyGrammarCoverage.test.js` | Executable acceptance gate: unit counts, level spread, section spread, no gaps |
| Create `test/beginnerPackCoverage.test.js` | Executable acceptance gate for the 12 beginner packs |
| Modify `migrations/dailyGrammarData.json` | Grows from the 3-unit sample to 120 units (Tasks 2–5) |
| Modify `migrations/vocabPacksData.json` | Grows from 50 to 62 packs (Tasks 7–8) |
| Modify `lib/vocabPackShape.js` | `VALID_LEVELS` gains `'beginner'` |

---

### Task 1: Syllabus extraction and the authoring rubric

The rubric is the reason the other tasks can be short: it is the contract each batch is written against, so the batch tasks state coverage and let the gates do the checking.

**Files:**
- Create: `scripts/extractGrammarSyllabus.js`
- Create: `docs/content/grammar-authoring-rubric.md`
- Test: `test/extractGrammarSyllabus.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `parseContentsText(raw: string): { unit: number, title: string, section: string }[]` and a CLI writing a local working file.

- [ ] **Step 1: Write the failing test**

```javascript
// test/extractGrammarSyllabus.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { parseContentsText } = require('../scripts/extractGrammarSyllabus');

// Shape of a contents page: section headings on their own line, then numbered
// units beneath them.
const RAW = [
  'Contents',
  'Acknowledgements vii',
  'To the student viii',
  'Present',
  '1 am/is/are',
  '2 am/is/are (questions)',
  '3 I am doing (present continuous)',
  'Past',
  '10 was/were',
  '11 worked/got/went etc (past simple)',
  'IF YOU ARE NOT SURE WHICH UNITS TO STUDY, USE THE STUDY GUIDE ON PAGE 271 iii',
].join('\n');

test('numbered units are parsed with their titles', () => {
  const rows = parseContentsText(RAW);
  assert.equal(rows.length, 5);
  assert.deepEqual(rows[0], { unit: 1, title: 'am/is/are', section: 'Present' });
});

test('units inherit the section heading above them', () => {
  const rows = parseContentsText(RAW);
  assert.equal(rows.find((r) => r.unit === 11).section, 'Past');
});

test('front matter and footers are not mistaken for units', () => {
  const rows = parseContentsText(RAW);
  assert.equal(rows.some((r) => /Acknowledgements|STUDY GUIDE|To the student/i.test(r.title)), false);
});

test('a unit number is never taken from a page reference', () => {
  const rows = parseContentsText('Present\n1 am/is/are\nAppendix 1 Active and passive 243');
  assert.deepEqual(rows.map((r) => r.unit), [1]);
});

test('duplicate unit numbers keep the first occurrence', () => {
  const rows = parseContentsText('Present\n1 am/is/are\n1 duplicate entry');
  assert.equal(rows.length, 1);
  assert.equal(rows[0].title, 'am/is/are');
});

test('an empty input yields an empty list rather than throwing', () => {
  assert.deepEqual(parseContentsText(''), []);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/extractGrammarSyllabus.test.js`
Expected: FAIL — `Cannot find module '../scripts/extractGrammarSyllabus'`

- [ ] **Step 3: Write minimal implementation**

```javascript
// scripts/extractGrammarSyllabus.js
/**
 * Derives a grammar SYLLABUS — unit numbers, point names, section grouping —
 * from a reference grammar's contents pages.
 *
 * This exists so the derivation is reproducible and reviewable. What it
 * produces is a coverage map (which points to teach, in what order), which is
 * the factual part. Explanations, examples and exercises are authored fresh;
 * no prose from the source is read, extracted or stored.
 *
 * The output is a LOCAL WORKING FILE and is deliberately not committed: the
 * committed artefact is the authored content in migrations/dailyGrammarData.json.
 *
 * Usage:
 *   node scripts/extractGrammarSyllabus.js <pdf-path> <first-page> <last-page> > working/syllabus.json
 */
'use strict';

const FRONT_MATTER = /^(contents|thanks|acknowledgements|to the student|to the teacher|index|appendix|additional exercises|study guide|key to)/i;
const FOOTER = /^(if you are not sure)/i;

/** Contents text -> [{ unit, title, section }]. Pure, so it is unit-testable. */
const parseContentsText = (raw) => {
  const rows = [];
  const seen = new Set();
  let section = '';

  for (const line of String(raw || '').split('\n')) {
    const l = line.trim();
    if (!l || FRONT_MATTER.test(l) || FOOTER.test(l)) continue;

    const m = l.match(/^(\d{1,3})\s+(\S.*)$/);
    if (m) {
      const unit = Number(m[1]);
      const title = m[2].replace(/\s+/g, ' ').replace(/\s+\d+$/, '').trim();
      if (unit >= 1 && unit <= 200 && !seen.has(unit) && title.length > 2) {
        seen.add(unit);
        rows.push({ unit, title, section });
      }
      continue;
    }
    // A short unnumbered line is a section heading.
    if (l.length < 40 && !/^\d/.test(l)) section = l;
  }
  return rows;
};

const run = () => {
  const [pdfPath, first, last] = process.argv.slice(2);
  if (!pdfPath) {
    console.error('usage: node scripts/extractGrammarSyllabus.js <pdf-path> <first-page> <last-page>');
    process.exit(1);
  }
  const { execFileSync } = require('child_process');
  // pypdf is available in the environment; only the contents pages are read.
  const text = execFileSync('python3', ['-c', `
import pypdf, sys
r = pypdf.PdfReader(sys.argv[1])
for i in range(int(sys.argv[2]), int(sys.argv[3]) + 1):
    print(r.pages[i].extract_text() or '')
`, pdfPath, String(first || 3), String(last || 9)], { encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });

  console.log(JSON.stringify(parseContentsText(text), null, 1));
};

if (require.main === module) run();

module.exports = { parseContentsText };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/extractGrammarSyllabus.test.js`
Expected: PASS, 6 tests

- [ ] **Step 5: Derive both syllabi into a local working directory**

```bash
mkdir -p working && printf 'working/\n' >> .gitignore
node scripts/extractGrammarSyllabus.js ~/Desktop/grammar_in_use_elementary.pdf 3 8 > working/syllabus-elementary.json
node scripts/extractGrammarSyllabus.js ~/Desktop/grammar_in_use.pdf 4 9 > working/syllabus-intermediate.json
node -e "
const e=require('./working/syllabus-elementary.json'), i=require('./working/syllabus-intermediate.json');
console.log('elementary units:', e.length, '| intermediate units:', i.length);
console.log('elementary sections:', new Set(e.map(r=>r.section)).size);
console.log('intermediate sections:', new Set(i.map(r=>r.section)).size);
"
```

Expected: ~115 elementary units and ~145 intermediate units, ~21 and ~16 sections. Exact counts may vary by a unit or two with page range; that is fine — the coverage gates in Task 2 care about what gets authored, not about matching the book exactly.

- [ ] **Step 6: Write the authoring rubric**

```markdown
<!-- docs/content/grammar-authoring-rubric.md -->
# Grammar unit authoring rubric

Every unit in `migrations/dailyGrammarData.json` is written against this
contract. The seeder enforces the mechanical parts; this document carries the
editorial ones.

## Copyright boundary

The reference grammars supply **only** the syllabus: which point to teach, in
what order, under which section heading. Everything a learner reads is written
fresh. Never copy a sentence, an explanation, or an exercise item from either
book. When in doubt, write a new sentence about a different subject.

## Required shape

    {
      "language": "en",
      "level": "A1" | "A2" | "B1" | "B2",
      "kind": "grammar",
      "source": "curated",
      "title": "<the grammar point, lowercase, as a learner would search it>",
      "explanation": { "en": "<= 60 words" },
      "examples": [{ "text": "..." }, { "text": "..." }, { "text": "..." }],
      "quickCheck": [ <3 items>, ... ],
      "syllabus": { "book": "elementary" | "intermediate", "unit": <n>, "section": "<heading>" }
    }

Each `quickCheck` item:

    { "prompt": "...", "options": ["...", "...", "..."], "answerIndex": <n>,
      "explanation": "<why that answer is right, one sentence>" }

## Editorial rules

1. **Explanation ≤ 60 words.** State the rule, then the one distinction the
   learner will get wrong. No etymology, no exceptions list.
2. **Three examples, three different subjects.** Not three variations of one
   sentence. At least one should be something a person would actually say.
3. **Three checks, ascending difficulty.** The first confirms the rule; the
   third tests the distinction named in the explanation.
4. **Distractors must be plausible.** A wrong option should be the mistake a
   learner at this level actually makes — not a random word.
5. **Every check has an `explanation`.** The app shows it after answering; an
   empty one renders as a blank gap.
6. **Rotate `answerIndex`.** Across a batch, each position must hold 25–42% of
   the answers. The seeder refuses the batch otherwise.
7. **Vocabulary stays at or below the unit's level.** Do not teach `present
   perfect` with B2 vocabulary.
8. **No cultural or political specifics** that will not translate: no named
   public figures, no holidays, no place-specific assumptions.

## Level mapping

| Book | Units | CEFR |
|---|---|---|
| elementary | 1–60 (of 115) | 1–30 → A1, 31–60 → A2 |
| intermediate | 1–60 (of 145) | 1–30 → B1, 31–60 → B2 |

## Before committing a batch

    node seeds/dailyGrammarItems.js --dry-run
    node --test test/dailyGrammarCoverage.test.js
```

- [ ] **Step 7: Commit**

```bash
git add scripts/extractGrammarSyllabus.js test/extractGrammarSyllabus.test.js \
        docs/content/grammar-authoring-rubric.md .gitignore
git commit -m "feat(content): syllabus extraction and the grammar authoring rubric"
```

---

### Task 2: Coverage gates, then elementary units 1–30 (A1)

The coverage test is written **first and fails**, then content is authored until it passes. That is what makes this a TDD task rather than a writing task: the acceptance criteria are executable before any content exists.

**Files:**
- Create: `test/dailyGrammarCoverage.test.js`
- Modify: `migrations/dailyGrammarData.json`

**Interfaces:**
- Consumes: `validateGrammarBatch` from `seeds/dailyGrammarItems.js` (Plan 1 Task 11).
- Produces: 30 authored A1 units in the data file.

- [ ] **Step 1: Write the failing coverage test**

```javascript
// test/dailyGrammarCoverage.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const items = require('../migrations/dailyGrammarData.json');
const { validateGrammarBatch } = require('../seeds/dailyGrammarItems');

const byBook = (book) => items.filter((i) => i.syllabus && i.syllabus.book === book);
const byLevel = (level) => items.filter((i) => i.level === level);

test('the whole data file passes the seeder gate', () => {
  const { ok, errors } = validateGrammarBatch(items);
  assert.deepEqual(errors, [], 'batch gate must be clean');
  assert.equal(ok, true);
});

test('wave 1 authors 60 elementary units', () => {
  assert.equal(byBook('elementary').length, 60);
});

test('wave 1 authors 60 intermediate units', () => {
  assert.equal(byBook('intermediate').length, 60);
});

test('the four launch levels each get 30 units', () => {
  for (const level of ['A1', 'A2', 'B1', 'B2']) {
    assert.equal(byLevel(level).length, 30, `${level} should have 30 units`);
  }
});

test('elementary units 1-60 are present with no gaps', () => {
  const units = byBook('elementary').map((i) => i.syllabus.unit).sort((a, b) => a - b);
  assert.deepEqual(units, Array.from({ length: 60 }, (_, i) => i + 1));
});

test('intermediate units 1-60 are present with no gaps', () => {
  const units = byBook('intermediate').map((i) => i.syllabus.unit).sort((a, b) => a - b);
  assert.deepEqual(units, Array.from({ length: 60 }, (_, i) => i + 1));
});

test('units 1-30 of each book are the lower CEFR band', () => {
  // The mapping the rubric states: elementary 1-30 = A1, 31-60 = A2,
  // intermediate 1-30 = B1, 31-60 = B2.
  for (const item of items) {
    const { book, unit } = item.syllabus;
    const expected = book === 'elementary'
      ? (unit <= 30 ? 'A1' : 'A2')
      : (unit <= 30 ? 'B1' : 'B2');
    assert.equal(item.level, expected, `${book} unit ${unit} should be ${expected}`);
  }
});

test('at least six distinct sections are covered per book', () => {
  for (const book of ['elementary', 'intermediate']) {
    const sections = new Set(byBook(book).map((i) => i.syllabus.section).filter(Boolean));
    assert.ok(sections.size >= 6, `${book} covers only ${sections.size} sections`);
  }
});

test('every explanation is at most 60 words', () => {
  for (const item of items) {
    const words = item.explanation.en.trim().split(/\s+/).length;
    assert.ok(words <= 60, `"${item.title}" explanation is ${words} words`);
  }
});

test('every unit has exactly three examples with distinct subjects', () => {
  for (const item of items) {
    assert.equal(item.examples.length, 3, `"${item.title}" has ${item.examples.length} examples`);
    const firstWords = item.examples.map((e) => e.text.split(' ')[0].toLowerCase());
    assert.equal(new Set(firstWords).size, 3, `"${item.title}" reuses a subject across examples`);
  }
});

test('every quick check explains its answer', () => {
  for (const item of items) {
    item.quickCheck.forEach((q, i) => {
      assert.ok(
        typeof q.explanation === 'string' && q.explanation.trim().length > 0,
        `"${item.title}" check ${i} has no explanation`
      );
    });
  }
});

test('every quick check offers three options', () => {
  for (const item of items) {
    for (const q of item.quickCheck) {
      assert.equal(q.options.length, 3, `"${item.title}" has a check with ${q.options.length} options`);
    }
  }
});

test('no two units share a title within a book', () => {
  for (const book of ['elementary', 'intermediate']) {
    const titles = byBook(book).map((i) => i.title.toLowerCase());
    assert.equal(new Set(titles).size, titles.length, `${book} has duplicate titles`);
  }
});
```

- [ ] **Step 2: Run it and read the gap list**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: FAIL — with the 3-unit sample from Plan 1, `elementary units 1-60 are present with no gaps` and the count assertions fail. This output is the authoring worklist.

- [ ] **Step 3: Author elementary units 1–30 (A1)**

Take the first 30 entries of `working/syllabus-elementary.json` as the coverage map. Renumber to a contiguous 1–30 if the source list skips (the coverage test requires no gaps, and the learner's cursor walks `1, 2, 3…` — a gap would silently skip a unit).

Write each unit to the rubric. Two fully worked examples to set the standard:

```json
  {
    "language": "en", "level": "A1", "kind": "grammar", "source": "curated",
    "title": "there is / there are",
    "explanation": { "en": "Use there is for one thing and there are for more than one. The verb matches what comes after it, not the place: 'There are two chairs in the room', even though the room is singular." },
    "examples": [
      { "text": "There is a message for you." },
      { "text": "My street has changed — there are three new shops on it." },
      { "text": "Are there any towels in the bathroom?" }
    ],
    "quickCheck": [
      { "prompt": "___ a problem with the door.", "options": ["There is", "There are", "There be"],
        "answerIndex": 0, "explanation": "One problem, so there is." },
      { "prompt": "___ four people waiting outside.", "options": ["There is", "There was", "There are"],
        "answerIndex": 2, "explanation": "Four people is plural, so there are." },
      { "prompt": "In this box ___ two old photographs.", "options": ["there are", "it is", "there is"],
        "answerIndex": 0, "explanation": "The verb matches the photographs, not the box." }
    ],
    "syllabus": { "book": "elementary", "unit": 7, "section": "There and it" }
  },
  {
    "language": "en", "level": "A1", "kind": "grammar", "source": "curated",
    "title": "can and can't",
    "explanation": { "en": "Can means you are able to do something or are allowed to. Use the plain verb after it — never 'to'. The form never changes: he can, they can, I can." },
    "examples": [
      { "text": "She can drive, but she doesn't like motorways." },
      { "text": "We can't hear you — the line is bad." },
      { "text": "Can you open this jar for me?" }
    ],
    "quickCheck": [
      { "prompt": "He ___ swim very well.", "options": ["cans", "can", "can to"],
        "answerIndex": 1, "explanation": "Can never takes -s and never takes to." },
      { "prompt": "I ___ find my glasses anywhere.", "options": ["don't can", "can't", "not can"],
        "answerIndex": 1, "explanation": "The negative is can't, not don't can." },
      { "prompt": "___ they come with us tomorrow?", "options": ["Do can", "Can", "Are can"],
        "answerIndex": 1, "explanation": "Questions put can first; no extra auxiliary." }
    ],
    "syllabus": { "book": "elementary", "unit": 29, "section": "Modals, imperative etc." }
  }
```

- [ ] **Step 4: Validate the batch**

Run: `node seeds/dailyGrammarItems.js --dry-run`
Expected: `✓ 30 grammar units validated (shape + answer balance)`. If the balance gate refuses the batch, rotate `answerIndex` values — do **not** loosen the gate.

- [ ] **Step 5: Confirm the A1 slice of the coverage test now passes**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: the A1 count, explanation-length, examples, options and check-explanation tests PASS; the 60-unit and A2/B1/B2 tests still FAIL (Tasks 3–5 close those).

- [ ] **Step 6: Commit**

```bash
git add test/dailyGrammarCoverage.test.js migrations/dailyGrammarData.json
git commit -m "content(grammar): coverage gates and 30 A1 units"
```

---

### Task 3: Elementary units 31–60 (A2)

**Files:**
- Modify: `migrations/dailyGrammarData.json`

**Interfaces:**
- Consumes: the rubric (Task 1), the coverage gates (Task 2).
- Produces: 30 authored A2 units, `syllabus.unit` 31–60, `book: 'elementary'`.

- [ ] **Step 1: Confirm the gate still names this as the gap**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: FAIL on `the four launch levels each get 30 units` for A2 and on the elementary 1–60 contiguity test.

- [ ] **Step 2: Author units 31–60 from `working/syllabus-elementary.json`**

Same rubric. A2 units are the second half of the elementary book — past continuous, present perfect, comparatives, articles, prepositions of place and time, and the question forms. One worked example for the level's tone:

```json
  {
    "language": "en", "level": "A2", "kind": "grammar", "source": "curated",
    "title": "comparatives: -er and more",
    "explanation": { "en": "Short adjectives add -er: older, cheaper, busier. Longer ones take more: more careful, more expensive. Then use than to name what you are comparing with. A few are irregular: good becomes better, bad becomes worse." },
    "examples": [
      { "text": "This route is quicker than the main road." },
      { "text": "Her second album is more interesting than the first." },
      { "text": "My cough is worse today than it was yesterday." }
    ],
    "quickCheck": [
      { "prompt": "The blue jacket is ___ than the grey one.", "options": ["more cheap", "cheaper", "cheapest"],
        "answerIndex": 1, "explanation": "Cheap is short, so it takes -er." },
      { "prompt": "Driving at night is ___ than driving in daylight.", "options": ["more difficult", "difficulter", "most difficult"],
        "answerIndex": 0, "explanation": "Difficult is long, so it takes more." },
      { "prompt": "This year's harvest was ___ than last year's.", "options": ["gooder", "more good", "better"],
        "answerIndex": 2, "explanation": "Good is irregular: better." }
    ],
    "syllabus": { "book": "elementary", "unit": 45, "section": "Adjectives and adverbs" }
  }
```

- [ ] **Step 3: Validate**

Run: `node seeds/dailyGrammarItems.js --dry-run`
Expected: `✓ 60 grammar units validated`

- [ ] **Step 4: Confirm elementary coverage is complete**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: `wave 1 authors 60 elementary units`, `elementary units 1-60 are present with no gaps` and the A1/A2 counts all PASS. Intermediate tests still FAIL.

- [ ] **Step 5: Commit**

```bash
git add migrations/dailyGrammarData.json
git commit -m "content(grammar): 30 A2 units complete the elementary book"
```

---

### Task 4: Intermediate units 1–30 (B1)

**Files:**
- Modify: `migrations/dailyGrammarData.json`

**Interfaces:**
- Consumes: the rubric, the gates.
- Produces: 30 authored B1 units, `syllabus.unit` 1–30, `book: 'intermediate'`.

- [ ] **Step 1: Confirm the gate names B1 as the gap**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: FAIL on the B1 count and intermediate contiguity.

- [ ] **Step 2: Author units 1–30 from `working/syllabus-intermediate.json`**

The intermediate book opens on present/past contrasts, the perfect tenses, the future, and the modals — the distinctions B1 learners actually get wrong. One worked example:

```json
  {
    "language": "en", "level": "B1", "kind": "grammar", "source": "curated",
    "title": "present perfect and past simple",
    "explanation": { "en": "Use the past simple when you say, or both of you know, when it happened: 'I sent it yesterday.' Use the present perfect when the time is open or still relevant: 'I've sent it.' A finished time word forces the past simple." },
    "examples": [
      { "text": "I've read her latest book — you should try it." },
      { "text": "We finished the repairs on Tuesday." },
      { "text": "Has the plumber arrived yet, or is he still coming?" }
    ],
    "quickCheck": [
      { "prompt": "She ___ her keys, so she's waiting outside.", "options": ["has lost", "lost", "was losing"],
        "answerIndex": 0, "explanation": "The result matters now, and no time is given." },
      { "prompt": "They ___ the office in 2019.", "options": ["have moved", "moved", "have been moving"],
        "answerIndex": 1, "explanation": "In 2019 is a finished time, so past simple." },
      { "prompt": "___ you ever ___ in a hammock?", "options": ["Did / sleep", "Have / slept", "Have / sleep"],
        "answerIndex": 1, "explanation": "Ever asks about life up to now: present perfect." }
    ],
    "syllabus": { "book": "intermediate", "unit": 13, "section": "Present perfect and past" }
  }
```

- [ ] **Step 3: Validate**

Run: `node seeds/dailyGrammarItems.js --dry-run`
Expected: `✓ 90 grammar units validated`

- [ ] **Step 4: Confirm the B1 gate passes**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: the B1 count PASSES; only the B2 count and intermediate contiguity still FAIL.

- [ ] **Step 5: Commit**

```bash
git add migrations/dailyGrammarData.json
git commit -m "content(grammar): 30 B1 units"
```

---

### Task 5: Intermediate units 31–60 (B2)

This closes the hole the measurement found: production currently has **zero B2 items**.

**Files:**
- Modify: `migrations/dailyGrammarData.json`

**Interfaces:**
- Consumes: the rubric, the gates.
- Produces: 30 authored B2 units, `syllabus.unit` 31–60, `book: 'intermediate'`. After this the whole coverage test passes.

- [ ] **Step 1: Confirm B2 is the last gap**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: FAIL only on the B2 count and the intermediate 1–60 contiguity.

- [ ] **Step 2: Author units 31–60**

The second half of the intermediate book: conditionals and `wish`, the passive, reported speech, `-ing` versus `to`, relative clauses, and the preposition-heavy sections. One worked example:

```json
  {
    "language": "en", "level": "B2", "kind": "grammar", "source": "curated",
    "title": "wish and if only",
    "explanation": { "en": "Wish plus the past tense describes a present situation you want to be different: 'I wish I lived closer.' Wish plus the past perfect regrets something already done: 'I wish I hadn't said that.' Wish plus would complains about a habit." },
    "examples": [
      { "text": "I wish this printer worked properly." },
      { "text": "She wishes she had taken the earlier train." },
      { "text": "I wish he would stop humming while he reads." }
    ],
    "quickCheck": [
      { "prompt": "I wish I ___ how to fix it myself.", "options": ["know", "knew", "had known"],
        "answerIndex": 1, "explanation": "A present situation you want changed: past tense after wish." },
      { "prompt": "He wishes he ___ the contract before signing.", "options": ["had read", "read", "would read"],
        "answerIndex": 0, "explanation": "Regret about a finished action: past perfect." },
      { "prompt": "I wish the neighbours ___ their music down.", "options": ["turned", "had turned", "would turn"],
        "answerIndex": 2, "explanation": "A complaint about repeated behaviour takes would." }
    ],
    "syllabus": { "book": "intermediate", "unit": 41, "section": "if and wish" }
  }
```

- [ ] **Step 3: Validate**

Run: `node seeds/dailyGrammarItems.js --dry-run`
Expected: `✓ 120 grammar units validated (shape + answer balance)`

- [ ] **Step 4: The full coverage gate must now be green**

Run: `node --test test/dailyGrammarCoverage.test.js`
Expected: PASS, 13 tests.

- [ ] **Step 5: Run the whole backend suite**

Run: `npm test`
Expected: only the pre-existing `JWT_SECRET` failure.

- [ ] **Step 6: Commit**

```bash
git add migrations/dailyGrammarData.json
git commit -m "content(grammar): 30 B2 units — 120 total, closing the B2 hole"
```

---

### Task 6: Let the pack validator accept `beginner`

**Files:**
- Modify: `lib/vocabPackShape.js`
- Test: `test/vocabPackShape.test.js` (extend if it exists; create if not)

**Interfaces:**
- Consumes: nothing.
- Produces: `VALID_LEVELS` including `'beginner'`, so a beginner pack can pass the data-file gate.

- [ ] **Step 1: Write the failing test**

```javascript
// test/vocabPackShape.test.js  (add these; keep any existing tests in the file)
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { validateVocabPacksData } = require('../lib/vocabPackShape');

const pack = (over = {}) => ({
  level: 'beginner',
  topic: 'Everyday objects',
  words: [{ word: 'cup', definition: 'a small container you drink from', example: 'She washed the cup.' }],
  exercises: [],
  ...over,
});

test('beginner is a valid pack level', () => {
  // A1 is the largest labeled group on prod and has no pack at all; the model
  // enum and THIS validator both gate that independently.
  assert.deepEqual(validateVocabPacksData([pack()]), []);
});

test('intermediate and advanced still validate', () => {
  assert.deepEqual(validateVocabPacksData([pack({ level: 'intermediate' })]), []);
  assert.deepEqual(validateVocabPacksData([pack({ level: 'advanced', topic: 'Law & justice' })]), []);
});

test('an unknown level is still refused', () => {
  const errors = validateVocabPacksData([pack({ level: 'expert' })]);
  assert.ok(errors.length > 0);
  assert.match(errors.join(' '), /level/);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/vocabPackShape.test.js`
Expected: FAIL — `beginner is a valid pack level` reports a level error.

- [ ] **Step 3: Write minimal implementation**

```javascript
// lib/vocabPackShape.js
// A1 learners are the largest labeled group on prod and had no pack at all;
// 'beginner' packs fill that. Mirrors models/VocabPack.js's enum.
const VALID_LEVELS = ['beginner', 'intermediate', 'advanced'];
```

Also update the doc comment at the top of the file, which states the old rule:

```javascript
 * - pack: level ∈ {beginner, intermediate, advanced}, non-empty topic, ≥1 word
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/vocabPackShape.test.js`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/vocabPackShape.js test/vocabPackShape.test.js
git commit -m "feat(content): accept beginner vocab packs in the data-file gate"
```

---

### Task 7: Beginner packs 1–6 (120 words)

**Files:**
- Create: `test/beginnerPackCoverage.test.js`
- Modify: `migrations/vocabPacksData.json`

**Interfaces:**
- Consumes: `validateVocabPacksData` (Task 6).
- Produces: 6 beginner packs, 20 words and 8 exercises each, appended to the existing 50.

- [ ] **Step 1: Write the failing coverage test**

```javascript
// test/beginnerPackCoverage.test.js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const packs = require('../migrations/vocabPacksData.json');
const { validateVocabPacksData } = require('../lib/vocabPackShape');

const beginner = () => packs.filter((p) => p.level === 'beginner');

test('the whole pack data file still validates', () => {
  assert.deepEqual(validateVocabPacksData(packs), []);
});

test('the 50 existing packs are untouched', () => {
  assert.equal(packs.filter((p) => p.level === 'intermediate').length, 25);
  assert.equal(packs.filter((p) => p.level === 'advanced').length, 25);
});

test('wave 1 adds 12 beginner packs', () => {
  assert.equal(beginner().length, 12);
});

test('every beginner pack carries exactly 20 words', () => {
  for (const p of beginner()) {
    assert.equal(p.words.length, 20, `"${p.topic}" has ${p.words.length} words`);
  }
});

test('every beginner pack carries exactly 8 exercises', () => {
  for (const p of beginner()) {
    assert.equal(p.exercises.length, 8, `"${p.topic}" has ${p.exercises.length} exercises`);
  }
});

test('beginner topics are distinct and concrete', () => {
  const topics = beginner().map((p) => p.topic.toLowerCase());
  assert.equal(new Set(topics).size, topics.length, 'duplicate beginner topic');
});

test('beginner definitions stay short enough for an A1 reader', () => {
  for (const p of beginner()) {
    for (const w of p.words) {
      const words = w.definition.trim().split(/\s+/).length;
      assert.ok(words <= 12, `"${w.word}" definition is ${words} words`);
    }
  }
});

test('every beginner word has an example sentence containing the word', () => {
  for (const p of beginner()) {
    for (const w of p.words) {
      assert.ok(
        w.example.toLowerCase().includes(w.word.toLowerCase().split(' ')[0]),
        `"${w.word}" example does not use the word`
      );
    }
  }
});

test('beginner exercise answer positions are balanced', () => {
  const { checkAnswerBalance } = require('../lib/answerBalance');
  // Reuse the grammar gate by shaping multiple_choice exercises like quickChecks.
  const asChecks = beginner().map((p) => ({
    quickCheck: p.exercises
      .filter((e) => e.type === 'multiple_choice')
      .map((e) => ({ options: e.options, answerIndex: e.answerIndex })),
  }));
  const result = checkAnswerBalance(asChecks);
  assert.deepEqual(result.errors, []);
});
```

- [ ] **Step 2: Run it and read the gap list**

Run: `node --test test/beginnerPackCoverage.test.js`
Expected: FAIL — `wave 1 adds 12 beginner packs` reports 0.

- [ ] **Step 3: Author packs 1–6**

Topics for the first six, chosen because an A1 learner needs them in week one and they are concrete enough to illustrate: **Everyday objects · Family & people · Food & drink · Numbers, time & dates · Clothes & colours · The house**.

Follow the existing file's shape exactly (`level`, `topic`, `words`, `exercises`; `partOfSpeech` on a word is accepted and ignored by the model). One worked pack fragment setting the standard:

```json
  {
    "level": "beginner",
    "topic": "Everyday objects",
    "words": [
      { "word": "cup", "definition": "a small open container you drink from", "example": "She put the cup on the table.", "partOfSpeech": "noun" },
      { "word": "key", "definition": "a small metal thing that opens a lock", "example": "I can't find my key.", "partOfSpeech": "noun" },
      { "word": "bag", "definition": "a soft container you carry things in", "example": "My bag is very heavy today.", "partOfSpeech": "noun" }
    ],
    "exercises": [
      { "type": "multiple_choice", "prompt": "Which one do you drink from?", "options": ["a key", "a cup", "a bag"], "answerIndex": 1, "targetWord": "cup" },
      { "type": "fill_blank", "prompt": "I open the door with my ___.", "answer": "key", "targetWord": "key" },
      { "type": "error_correction", "prompt": "My bag are heavy.", "corrected": "My bag is heavy.", "targetWord": "bag" },
      { "type": "matching", "pairs": [
        { "term": "cup", "definition": "you drink from it" },
        { "term": "key", "definition": "it opens a lock" }
      ] }
    ]
  }
```

Each finished pack needs the full 20 words and 8 exercises; spread the eight across all four types, with roughly half `multiple_choice` so the balance gate has a sample to judge.

- [ ] **Step 4: Validate**

Run: `node seeds/vocabPacks.js --dry-run`
Expected: validation passes for all 56 packs.

- [ ] **Step 5: Confirm the shape gates pass for what exists**

Run: `node --test test/beginnerPackCoverage.test.js`
Expected: the 20-word, 8-exercise, definition-length, example and balance tests PASS; `wave 1 adds 12 beginner packs` still FAILS at 6.

- [ ] **Step 6: Commit**

```bash
git add test/beginnerPackCoverage.test.js migrations/vocabPacksData.json
git commit -m "content(vocab): beginner packs 1-6 and their coverage gates"
```

---

### Task 8: Beginner packs 7–12 (120 words)

**Files:**
- Modify: `migrations/vocabPacksData.json`

**Interfaces:**
- Consumes: the gates from Task 7.
- Produces: 6 more beginner packs — 12 total, one quarter of themed weeks for A1.

- [ ] **Step 1: Confirm the gate still reports the gap**

Run: `node --test test/beginnerPackCoverage.test.js`
Expected: FAIL on `wave 1 adds 12 beginner packs` (6 of 12).

- [ ] **Step 2: Author packs 7–12**

Topics: **The body & health · Travel & the city · Weather & seasons · Work & school · Free time & hobbies · Feelings**. Same rubric as Task 7: 20 words, 8 exercises across all four types, definitions ≤12 words, every example containing its word.

- [ ] **Step 3: Validate**

Run: `node seeds/vocabPacks.js --dry-run`
Expected: validation passes for all 62 packs.

- [ ] **Step 4: The beginner coverage gate must now be green**

Run: `node --test test/beginnerPackCoverage.test.js`
Expected: PASS, 9 tests.

- [ ] **Step 5: Run the whole backend suite**

Run: `npm test`
Expected: only the pre-existing `JWT_SECRET` failure.

- [ ] **Step 6: Commit**

```bash
git add migrations/vocabPacksData.json
git commit -m "content(vocab): beginner packs 7-12 — 12 total for A1 learners"
```

---

### Task 9: Seed production and verify

This is the only task that touches production. It runs **after** Plan 1 is merged and deployed, because the seeders write `DailyItem.syllabus` and `VocabPack.level: 'beginner'`, and both need the deployed schema.

**Files:** none — this is an operational task with a verification script.

**Interfaces:**
- Consumes: both seeders, both data files.
- Produces: 120 grammar items and 12 beginner packs on production.

- [ ] **Step 1: Confirm the deployed schema accepts the new fields**

```bash
node -e "
const m = require('./models/DailyItem');
const v = require('./models/VocabPack');
console.log('DailyItem.syllabus:', !!m.schema.path('syllabus.unit'));
console.log('VocabPack levels:', v.schema.path('level').enumValues);
"
```
Expected: `DailyItem.syllabus: true` and a level list containing `beginner`. If either is missing, **stop** — Plan 1 Task 6 is not deployed yet.

- [ ] **Step 2: Dry-run both seeders against the production config one last time**

```bash
node seeds/dailyGrammarItems.js --dry-run
node seeds/vocabPacks.js --dry-run
```
Expected: `✓ 120 grammar units validated` and clean pack validation. A dry run connects to nothing.

- [ ] **Step 3: Record the before state**

```bash
node -e "
const path=require('path');
require('dotenv').config({path:'./config/config.env'});
const {MongoClient}=require('mongodb');
(async()=>{
  const c=new MongoClient(process.env.MONGO_URI); await c.connect(); const db=c.db();
  console.log('dailyitems:', await db.collection('dailyitems').countDocuments());
  console.log('with syllabus:', await db.collection('dailyitems').countDocuments({'syllabus.unit':{\$ne:null}}));
  console.log('vocabpacks:', await db.collection('vocabpacks').countDocuments());
  console.log('beginner packs:', await db.collection('vocabpacks').countDocuments({level:'beginner'}));
  await c.close();
})();
"
```
Expected baseline (measured 2026-09-11): 214 daily items, 0 with a syllabus, 50 packs, 0 beginner.

- [ ] **Step 4: Seed**

```bash
node seeds/dailyGrammarItems.js
node seeds/vocabPacks.js
```
Both seeders upsert on their natural keys, so a re-run is idempotent and nothing is deleted.

- [ ] **Step 5: Verify the after state**

Re-run the Step 3 script.
Expected: **334** daily items (214 + 120), **120** with a syllabus, **62** packs, **12** beginner. If any number is short, the seeder's per-item audit lines name which entries did not land.

- [ ] **Step 6: Verify a real learner path end to end**

```bash
node -e "
require('dotenv').config({path:'./config/config.env'});
const mongoose=require('mongoose');
(async()=>{
  await mongoose.connect(process.env.MONGO_URI);
  const {resolveTheme, resolveGrammar}=require('./services/dailyPackService');
  const theme=await resolveTheme({level:'A1', dateKey:new Date().toISOString().slice(0,10)});
  console.log('A1 theme:', theme && theme.topic, '| level:', theme && theme.level);
  const item=await resolveGrammar({userId:new mongoose.Types.ObjectId(), language:'en', level:'A1', dateKey:new Date().toISOString().slice(0,10)});
  console.log('A1 first grammar unit:', item && item.syllabus.unit, item && item.title);
  await mongoose.disconnect();
})();
"
```
Expected: a beginner theme topic, and grammar unit **1** for a learner with no history — proof that the per-learner cursor starts at the beginning of the syllabus, which was the point of D7.

- [ ] **Step 7: Record the outcome**

Append the before/after counts and the date to `docs/superpowers/specs/2026-09-11-daily-learning-pack-design.md` under a new "Content seeded" heading, so the next person does not have to re-measure.

```bash
git add docs/superpowers/specs/2026-09-11-daily-learning-pack-design.md
git commit -m "docs(content): record the production content seed"
```

---

## Self-review notes

- **Spec coverage**: §4.1 sources → Tasks 2–8. §4.3 level mapping → the coverage test's CEFR-band assertion (Task 2). §4.4 the A1 gap → Tasks 6–8. §4.5 authoring and the copyright boundary → Task 1's rubric and extraction script. §4.6 quality gates → Tasks 2 and 7 (shape, balance, coverage). Launch volume of 120 units → Tasks 2–5.
- **Type consistency**: `validateGrammarBatch` (Plan 1 Task 11) is the single gate used by Tasks 2–5. `validateVocabPacksData` and `checkAnswerBalance` are reused rather than reimplemented in Task 7. Every level string matches `lib/dailyLevels.LEVELS`; every book string matches the `['elementary','intermediate']` enum in Plan 1 Task 6.
- **Dependency found during self-review**: `lib/vocabPackShape.js` hardcodes `VALID_LEVELS = ['intermediate','advanced']` **independently of the model enum**, so widening only `models/VocabPack.js` in Plan 1 would still have left every beginner pack rejected at the data-file gate. That is Task 6 here, and it must land before Task 7's content.
- **Renumbering caveat**: the coverage test requires contiguous units 1–60 per book because the learner's cursor walks them in order and a gap would silently skip a unit. The source lists are not contiguous once truncated at 60, so Task 2 Step 3 renumbers deliberately. `syllabus.section` keeps the original grouping, so the mastery screen's section breakdown stays meaningful.
- **Honest limit**: Tasks 2–5 and 7–8 are authoring tasks. The plan fixes the contract, the volume, the level mapping and the executable gates, and works two or three units per level in full — it does not pre-write all 120 units and 240 words. That content is the deliverable of running the tasks, and the gates are what make "done" objective rather than a matter of opinion.
