# AI Study, Plan S1 (backend, phase 1: foundations) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The study backend stops giving the tutor and the reminder push wrong data, keeps a level per language that follows results, records study events, and serves the daily pack faster.

**Architecture:** Small fixes go in place with tests and no switch. Three additions sit behind switches that default to off: a pure level module (`lib/studyLevel.js`) feeding a per-language level map on the user, a batched study event log with a funnel script, and a trim of nightly generation. Everything stays compatible with the app build people have today.

**Tech Stack:** Node.js, Express, Mongoose, `node:test` with `mongodb-memory-server`.

**Spec:** `docs/superpowers/specs/2026-11-14-ai-study-path-design.md` (app repo, branch `docs/ai-study-spec`), section 5 and the server half of 9. The app half is Plan S2; phases 2 and 3 have their own plans.

**Repo and branch:** backend repo, new worktree `/Users/davis/Desktop/Personal/be-study-s1`, branch `feat/ai-study-foundations` from `origin/main` (fetch first; another session pushes to main).

## Global Constraints

- New switches, all default off, declared with `flag()` in `config/limitations.js`: `STUDY_EVENTS_ENABLED`, `STUDY_LEVELS_V2_ENABLED`, `STUDY_NIGHTLY_TRIM_ENABLED`. Guards and readers take the value from the limitations module at call time.
- With the three switches unset, every response is byte-identical to `main` except where a task in this plan states a fix (Tasks 1 to 4). Task 8 proves it and lists the stated differences.
- Compatible with the live app: no existing response field is removed or changes type; new fields are additive.
- Guarded routes answer `404 { success: false, error: 'Not found' }` while off.
- New user-facing error strings must not contain `limit`, `blocked`, `not found`, `unauthorized` or `401`.
- Tests: `node --experimental-test-module-mocks --test --test-force-exit test/<file>.test.js`, one file at a time. Never start `server.js` and never run a script against a real database: `config/config.env` points at production.
- No AI provider is called in tests; mock it.
- Never add a Co-Authored-By or any Claude attribution line. Every commit updates `docs/REMAINING_WORK.md` and lists what is still open in its body. Stage by path. Do not push `main`.

## Review Focus

1. A free user's sixth tutor conversation in a day and an eleventh message in one conversation: both are refused with a body the live app already understands; a VIP is never refused; roleplay is unaffected. (Task 2)
2. Two station completions for one user landing together: the level record is not corrupted and moves at most one level. (Task 6)
3. A user who changes their learning language: the old language's level is kept, the new one starts unmeasured. (Task 6)
4. A vocabulary save with language `auto`, a display name, an unknown string, or nothing: stored as a code when one can be worked out, otherwise as the learner's target language; never `auto`. (Task 3)
5. A study event batch with a malformed item, 51 items, or a `clientAt` far in the past: same handling as the paywall batch endpoint. (Task 5)

---

## File Structure

| File | Responsibility |
|---|---|
| `services/tutorService.js` (modify) | Newest summary in the prompt; real review field in the daily plan |
| `services/dailyPackService.js` (modify) | Chinese pool alias; parallel build; level v2 read and update; cached weekend prompt |
| `lib/studyLanguage.js` (create) | `contentLanguagesFor(code)`, `normalizeVocabLanguage(value, user)` |
| `middleware/checkTutorQuota.js`, `controllers/tutor.js` (modify) | Allowance per conversation |
| `controllers/learning.js`, `controllers/advancedMessages.js`, other vocabulary writers (modify) | Normalised language on save |
| `scripts/normalizeVocabularyLanguages.js` (create) | Backfill, dry run by default |
| `jobs/dailyDropJob.js`, `notification_templates/*.json` (modify) | Reminder push; nightly trim; weekend prompt pre-build |
| `lib/studyLevel.js` (create) | Pure level rules |
| `models/User.js` (modify) | `studyLevels` map |
| `models/StudyEvent.js`, `controllers/studyEvents.js`, `routes/dailyStudy.js` or the study router (create/modify) | Event log and batch endpoint |
| `lib/studyFunnel.js`, `scripts/studyFunnel.js`, `scripts/studyContentGaps.js`, `scripts/pregeneratePlacementSets.js` (create) | Reports and one-off tools |
| `test/support/studyOffScenario.js`, `test/studyOffIdentity.test.js`, `docs/rollout/ai-study-foundations.md` (create) | Switch-off identity and rollout |

---

### Task 1: The tutor reads the right data; plain "Chinese" gets the Simplified pool

**Files:**
- Modify: `services/tutorService.js` (`buildSystemPrompt` around line 54; `generateDailyPlan` around line 203), `services/dailyPackService.js` (theme and grammar selection), `controllers/dailyStudy.js` only if selection needs the alias passed in
- Create: `lib/studyLanguage.js`
- Test: `test/tutorPromptData.test.js`, `test/studyLanguage.test.js`, `test/dailyPackChinesePool.test.js`

**Interfaces (Produces):** `contentLanguagesFor(code: string): string[]` — `'zh'` gives `['zh', 'zh-Hans']`; any other code gives `[code]`.

Rules:

- `buildSystemPrompt` uses the last element of `memory.recentChatSummaries` (they are stored oldest first, newest last); `'first chat'` when there is none.
- `generateDailyPlan` counts due words with the field the Vocabulary model really has, `nextReview`, and skips archived words.
- Pack content for a learner whose code is `zh` is selected from both `zh` and `zh-Hans` pools (theme packs and grammar items), preferring `zh` items when both exist at the wanted level. `toBaseLanguage` itself is not changed. The response's `language` stays `zh`.

- [ ] **Step 1: Write the failing tests.**

```js
test('the prompt carries the newest chat summary', () => {
  const memory = { recentChatSummaries: [{ summary: 'old one' }, { summary: 'newest one' }], weakAreas: [] };
  const prompt = buildSystemPrompt(memory, user);
  assert.match(prompt, /newest one/);
  assert.doesNotMatch(prompt, /old one/);
});
test('no summaries still says first chat', ...);
test('the daily plan includes a review task when words are due', async () => { ... });   // 3 Vocabulary rows with nextReview in the past -> a review task with count 3
test('archived words are not counted as due', ...);
test("contentLanguagesFor: zh -> ['zh','zh-Hans']; zh-Hans -> ['zh-Hans']; ko -> ['ko']", ...);
test('a zh learner with no zh grammar at their level is served a zh-Hans unit', ...);
test('a zh learner with zh content at their level still gets the zh item', ...);
```

- [ ] **Step 2: Run** the three files. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** them plus any existing tutor and daily pack test files (`ls test | grep -i "tutor\|dailyPack\|dailyStudy"`). Expected: PASS.
- [ ] **Step 5: Commit** `fix(study): the tutor gets the newest summary and real due words; plain Chinese learners get the Simplified pool`.

---

### Task 2: The free tutor allowance counts conversations, not messages

**Files:**
- Modify: `middleware/checkTutorQuota.js` (`checkChatQuotaSessionAware` and whatever consumes at session start), `controllers/tutor.js` if the session start path needs it, `config/limitations.js` (one constant)
- Test: `test/tutorConversationQuota.test.js`

**Interfaces (Produces):** `TUTOR_FREE_MESSAGES_PER_CONVERSATION = 10` exported from `config/limitations.js`.

Rules:

- Free chat: the daily `chat` quota (5) is consumed once per session, on that session's first learner message, not per message. A session's later messages are free until the session holds 10 learner messages.
- The eleventh learner message in a free session is refused with the same 429 body `buildQuotaExceededResponse('chat', resetAt)` plus one extra field `reason: 'conversation_full'`. A sixth session's first message is refused with today's body and `reason: 'daily_conversations'`. The live app treats both as it treats today's 429.
- Roleplay is unchanged (quota at session start, no message cap added). VIP is unchanged.
- Whether a session's first message was already charged is decided from the stored session (count of learner messages), not from a new field, so a retry of a failed first message is not charged twice.
- The quota snapshot keeps its shape; `remaining` for `chat` now means conversations left today.

- [ ] **Step 1: Write the failing tests.**

```js
test('ten messages in one conversation cost one unit of the daily allowance', ...);   // remaining 5 -> 4 after message 1, still 4 after message 10
test('the eleventh message is refused with reason conversation_full and the usual 429 shape', async () => {
  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error, 'quota_exceeded');
  assert.equal(res.body.reason, 'conversation_full');
});
test('a sixth conversation in a day is refused on its first message with reason daily_conversations', ...);
test('a VIP is never refused', ...);
test('roleplay behaves exactly as before', ...);
test('a first message retried after a failure is not charged twice', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the file plus existing quota tests (`ls test | grep -i quota`). Expected: PASS; an existing test that asserts per-message charging is updated to the new rule and listed in the report.
- [ ] **Step 5: Commit** `feat(tutor): the free allowance is 5 conversations a day of 10 messages, not 5 messages`.

---

### Task 3: Saved words carry a real language

**Files:**
- Modify: `lib/studyLanguage.js`, every writer of `Vocabulary.language` (find them: `grep -rn "Vocabulary\.\(create\|findOneAndUpdate\|updateOne\|insertMany\)\|new Vocabulary" controllers services lib`)
- Create: `scripts/normalizeVocabularyLanguages.js`
- Test: `test/vocabLanguage.test.js`

**Interfaces (Produces):** `normalizeVocabLanguage(value, user): string` — returns a code.

Rules:

- `value` that `toBaseLanguage` maps to a code gives that code (`English (US)` gives `en`, `français` gives `fr`, `en` stays `en`).
- `value` missing, `auto`, or unmappable gives `toBaseLanguage` of the user's first `language_to_learn`; if that is unknown too, `'und'`.
- Every writer passes its language through the helper. Reads that filter by language keep working for old rows: where a query matches on `language`, it matches the code and, until the backfill has run, the user's raw stored value too (the plan's implementer lists each such query in the report).
- The script: `--dry-run` (default) prints, per distinct stored value, the code it would become and the row count, and writes nothing; `--apply` updates in batches of 500 with the same mapping, using each row's owner for the fallback. It prints totals and never touches a row whose value is already its code.

- [ ] **Step 1: Write the failing tests.**

```js
test('display names, codes and local names become codes', () => {
  assert.equal(normalizeVocabLanguage('English (US)', u), 'en');
  assert.equal(normalizeVocabLanguage('français', u), 'fr');
  assert.equal(normalizeVocabLanguage('Chinese (Simplified)', u), 'zh-Hans');
});
test("auto, empty and nonsense fall back to the learner's language", () => {
  assert.equal(normalizeVocabLanguage('auto', { language_to_learn: 'Korean' }), 'ko');
  assert.equal(normalizeVocabLanguage(undefined, { language_to_learn: ['Japanese'] }), 'ja');
  assert.equal(normalizeVocabLanguage('xx??', { language_to_learn: '' }), 'und');
});
test('a word saved from chat with language auto is stored under the learner code', ...);   // call the controller
test('the due-words query still finds rows stored under the old display name', ...);
test('the backfill plan maps each stored value and leaves codes alone (dry run writes nothing)', ...);   // test the script's pure planning function
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Export the script's planning function so it is testable without a database run.
- [ ] **Step 4: Run** the file plus existing vocabulary and SRS tests (`ls test | grep -i "vocab\|srs"`). Expected: PASS.
- [ ] **Step 5: Commit** `fix(vocabulary): saved words carry a language code; backfill script (dry run by default)`.

---

### Task 4: The reminder push says something true

**Files:**
- Modify: `jobs/dailyDropJob.js` (`runDailyDropDelivery`), the daily drop template source (find `getDailyDropTemplate`), `notification_templates/*.json` (19 files)
- Test: `test/dailyPackReminder.test.js`

Rules:

- The push no longer names a lesson. English copy: title `Today's practice is ready`, body `About 5 minutes. Keep your streak going.` New template key `daily_pack_ready` in every locale file, translated; the 18 non-English strings are listed in `docs/REMAINING_WORK.md` as machine-drafted. Rendered in the person's `preferredLocale` with the existing per-key English fallback.
- "Already finished" uses the pack's own station list for that day (`lib/dailyStations.js`): no push when every station of today's pack has a completion.
- A person with no completion at all for 14 days is not pushed by this job (the lifecycle pushes cover them). (My call: a daily nag to someone who never opens it is how push permission is lost.)
- The delivery no longer needs a `DailyDrop` row to exist for the person's language and level.
- `data` keeps `type: 'daily_drop'` so the live app routes it as today.

- [ ] **Step 1: Write the failing tests** (mock `notificationService.send`):

```js
test('the push uses the pack-ready copy in the person locale and names no lesson', ...);
test('no push when all of today stations are complete; a push when one is missing', ...);
test('someone with no completion in 14 days is skipped; someone who completed 3 days ago is not', ...);
test('a learner whose language has no DailyDrop row still gets the push', ...);
test('every locale file has daily_pack_ready with a title and a body', ...);
test('data.type is still daily_drop', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the file plus existing daily drop and template tests. Expected: PASS (update tests that asserted the old title; list them).
- [ ] **Step 5: Commit** `fix(study): the daily reminder matches the pack and stops after two quiet weeks`.

---

### Task 5: Study events and the weekly funnel

**Files:**
- Create: `models/StudyEvent.js`, `controllers/studyEvents.js`, `lib/studyFunnel.js`, `scripts/studyFunnel.js`
- Modify: the study router (where `/study/pack` is mounted), `middleware/rateLimiter.js`, `controllers/appConfig.js`, `config/limitations.js`, `services/userCascadeDeleteService.js`
- Test: `test/studyEvents.test.js`, `test/studyFunnel.test.js`

**Interfaces (Produces):**
- `POST /api/v1/study/events`, authenticated, body `{ events: [{ name, language?, kind?, score?, total?, detail?, clientAt? }] }`, 1 to 50 items; `201 { success, stored, dropped }`; `404` while `STUDY_EVENTS_ENABLED` is off. App-config key `studyEventsEnabled`.
- `name` is one of: `tab_opened`, `session_started`, `step_started`, `step_finished`, `session_finished`, `feature_opened`, `level_check_started`, `level_check_finished`.
- `summarize(rows, { now }) -> { weeks: [{ weekKey, opened, started, finished, returned7 }], byLanguage: [...] }` (pure).

Rules: copy the shape of the paywall batch endpoint (`controllers/paywallEvents.js` `recordPaywallEvents`) exactly: per-item drop and count, `detail` cut to 40, `kind` cut to 24, `language` kept only if 2 to 10 characters, `score`/`total` kept only as non-negative integers up to 1000, `clientAt` within 48 hours, `platform` and `appVersion` from the request, one `insertMany` unordered, own limiter (30 calls per 15 minutes per user). Indexes `{ name: 1, createdAt: 1 }` and `{ userId: 1, createdAt: -1 }`; TTL 400 days on `createdAt`. Rows are removed with the account (stats key only when something was deleted, as the paywall cleanup does). `returned7` counts people with a `session_started` in the week who have another on a later day within 7 days.

- [ ] **Step 1: Write the failing tests**, mirroring `test/paywallEventsBatch.test.js` for the endpoint, and for the summary:

```js
test('opened, started, finished and returned are distinct people per week', () => {
  const out = summarize([
    ev('u1', 'tab_opened', '2026-11-09'), ev('u1', 'session_started', '2026-11-09'), ev('u1', 'session_finished', '2026-11-09'),
    ev('u1', 'session_started', '2026-11-11'),
    ev('u2', 'tab_opened', '2026-11-10'), ev('u2', 'session_started', '2026-11-10'),
    ev('u3', 'tab_opened', '2026-11-10'),
  ], { now: new Date('2026-11-20') });
  assert.deepEqual(pick(out.weeks[0]), { opened: 3, started: 2, finished: 1, returned7: 1 });
});
test('no rows gives no weeks', ...);
test('a second session on the same day is not a return', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** The script takes `[weeks]` (default 4) and is read-only.
- [ ] **Step 4: Run** both files. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): study event log and weekly funnel (STUDY_EVENTS_ENABLED, off)`.

---

### Task 6: A level per language that follows results

**Files:**
- Create: `lib/studyLevel.js`
- Modify: `models/User.js` (`studyLevels`), `controllers/dailyStudy.js` (`resolveTarget`, completion response), `services/dailyPackService.js` (`completeStationForUser` hook), the placement completion path (find where `languageLevel` is written: `grep -rn "languageLevel" controllers services lib models`)
- Test: `test/studyLevel.test.js`, `test/studyLevelFlow.test.js`

**Interfaces (Produces):**

```js
const LEVELS = ['A1','A2','B1','B2','C1','C2'];
// one record per language code, stored at User.studyLevels[code]
// { level, rating, measured, sessions, lastSessionDay, pendingLevel, pendingSessions, changedAt }
seed(levelOrNull, now) -> record            // unmeasured; rating at the middle of the level; default 'A2'
applyStep(record, { score, total, dateKey }, now) -> { record, change: null | { from, to } }
markMeasured(record, level, now) -> record  // a completed level check
levelFor(user, code) -> { level, measured } // reads studyLevels, else seeds from user.languageLevel without writing
```

Rules for `applyStep`:

- Steps with `total < 3` do not move the rating (too little evidence). Otherwise `fraction = score / total` and `rating += K * (fraction - 0.7)`, with `K = 0.6` while unmeasured and `K = 0.15` once measured. The rating is clamped to `[0, 6)`; a level is `LEVELS[floor(rating)]`.
- A session is a distinct `dateKey`; `sessions` counts them.
- Unmeasured: the level follows `floor(rating)` at once, but moves at most one level per session. After the third session the record becomes measured.
- Measured: when `floor(rating)` differs from the current level, it becomes `pendingLevel`; the level changes (by one step toward it) only when the pending level has held for 3 sessions and at least 7 days have passed since `changedAt`. A session where the rating is back inside the current level clears the pending state.
- A change returns `{ from, to }` so the completion response can carry `levelChange`.

Wiring, all behind `STUDY_LEVELS_V2_ENABLED` (off: today's single `languageLevel`, untouched):

- `resolveTarget` reads `levelFor(user, language)`; the pack response gains `levelMeasured` (boolean). `levelPlaced` keeps its meaning.
- Each scored station completion (not a repeat of an already completed station) applies `applyStep` to that language's record with one conditional update guarded on the record's `sessions` and `rating` as read, retried up to 3 times on a miss.
- A completed level check calls `markMeasured` for that language and no longer overwrites other languages. `languageLevel` is still written too, so the live app and the switch-off path keep working.
- A person who changes their learning language keeps the old record; the new language seeds unmeasured.

- [ ] **Step 1: Write the failing tests.**

```js
test('an unmeasured A2 learner scoring 5/5 three sessions running reaches B1 and becomes measured', ...);
test('unmeasured: never more than one level per session, even on a perfect day with four steps', ...);
test('a step with total 2 does not move the rating', ...);
test('measured: three good sessions inside 7 days do not change the level; on day 8 it moves one step', ...);
test('measured: a pending rise is cleared by a session back inside the level', ...);
test('rating never leaves [0, 6): a C2 learner at 5/5 stays C2; an A1 learner at 0/5 stays A1', ...);
test('markMeasured sets the level, centres the rating and keeps sessions', ...);
test('levelFor seeds from languageLevel as unmeasured and does not write', ...);
// flow
test('two completions landing together leave one consistent record and at most one level change', ...);
test('switching learning language keeps the first language record', ...);
test('with the switch off, completion does not touch studyLevels and the pack reads languageLevel', ...);   // separate off test file
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** `lib/studyLevel.js` is pure: no database, no `Date.now()`.
- [ ] **Step 4: Run** both files and the existing daily pack tests. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): a level per language that follows results (STUDY_LEVELS_V2_ENABLED, off)`.

---

### Task 7: A faster pack, a leaner nightly job, and the two tools

**Files:**
- Modify: `services/dailyPackService.js` (`buildPack`, `getOrCreateTranslatePrompt`), `jobs/dailyDropJob.js`
- Create: `scripts/pregeneratePlacementSets.js`, `scripts/studyContentGaps.js`, `lib/studyContentGaps.js`
- Test: `test/dailyPackParallel.test.js`, `test/dailyDropTrim.test.js`, `test/studyContentGaps.test.js`

Rules:

- `buildPack` runs its independent lookups together (theme, grammar, today's completions, due review words, the cached weekend prompt) instead of one after another. The response is unchanged: same keys, same order, same values for the same data. No switch.
- Weekend prompt: the nightly job prepares it for people who completed a station in the last 7 days and have at least 3 saved words, so the first weekend request finds it cached. A request that finds none behaves exactly as today. No switch.
- `STUDY_NIGHTLY_TRIM_ENABLED` on: the nightly job generates grammar items only for languages with no syllabus units and vocabulary items only for languages with no vocabulary pack, and logs what it skipped. Off: today's generation, unchanged.
- `scripts/pregeneratePlacementSets.js --langs zh-Hans,ko,ja,ar,es,ru --locale en [--dry-run]`: uses `services/placementSetService.js` to create sets that do not exist yet; prints one line per language; dry run lists what it would create and calls nothing. It is run by the owner on the server (it calls the AI provider).
- `summarizeGaps({ learners, grammarUnits, vocabPacks, placementSets })` (pure) returns, per language with 5 or more active learners: learners, highest grammar level available, vocabulary packs per level, whether a level-check set exists; `scripts/studyContentGaps.js` loads the inputs read-only and prints the table.

- [ ] **Step 1: Write the failing tests.**

```js
test('buildPack returns the same body as the sequential version for a seeded user', ...);   // snapshot built before the change, compared with JSON string equality
test('independent lookups start before any of them resolves', ...);                          // instrumented fakes record start order
test('the nightly run prepares weekend prompts only for recent learners with 3+ words', ...);
test('a weekend request with no cached prompt behaves as before', ...);
test('trim on: no grammar generation for a language with syllabus units, generation for one without', ...);
test('trim off: generation targets are exactly today ones', ...);
test('summarizeGaps lists zh-Hans with 25 learners, grammar to A2, no level-check set', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** `node --check` both scripts; do not run them.
- [ ] **Step 4: Run** the three files and the existing daily pack and daily drop tests. Expected: PASS.
- [ ] **Step 5: Commit** `perf(study): the pack is built in parallel and the weekend prompt is prepared overnight; nightly trim (off); content gaps and level-check tools`.

---

### Task 8: Switch-off identity and the rollout guide

**Files:**
- Create: `test/support/studyOffScenario.js`, `scripts/dev/generateStudyOffFixtures.js`, `test/fixtures/study-off/bodies.json`, `test/studyOffIdentity.test.js`, `docs/rollout/ai-study-foundations.md`
- Modify: `docs/REMAINING_WORK.md`

Follow `test/support/offersOffScenario.js` and `test/offersOffIdentity.test.js` exactly (in-memory Mongo, frozen clock, fixed ids, JSON string equality, fixtures generated from `main` in a temporary worktree of the branch's base commit, which is recorded in the test header).

Scenario, using only code that exists on `main`: one free learner of English, one of plain "Chinese", one VIP; a few vocabulary rows, one grammar unit per language, one tutor memory with two summaries. Capture: `GET /app-config`; `GET /study/pack` for each learner; one station completion; `GET /tutor/me`; one tutor message (provider mocked); `GET /learning/progress/weak-areas`; a vocabulary save with an explicit language code.

Stated differences from `main`, asserted separately and listed in the guide: app-config's new key `studyEventsEnabled` (false); the tutor prompt's summary; the daily plan's review task; the tutor quota snapshot after a first message (conversation, not message); the plain-Chinese pack when `zh` has no content at the level; vocabulary language stored as a code for a save that sent `auto`; the reminder push copy.

Further assertions: no `studyevents` collection after the scenario; `studyLevels` unset on every user; `POST /study/events` answers 404; the nightly job's targets equal `main`'s.

Guide contents: what changes for everyone at deploy (Tasks 1 to 4, and the two unflagged parts of Task 7); the three switches with order and preconditions (events once an app build that sends them is out; levels after the funnel has two weeks of data; trim after confirming nothing still calls the legacy daily endpoint); the two scripts the owner runs on the server (vocabulary backfill dry run then apply; level-check sets) and the content gaps report; the machine-drafted reminder strings; how to turn each switch off.

- [ ] **Step 1: Write** the scenario and generator; generate fixtures from the base commit.
- [ ] **Step 2: Write** the identity test; run it. Expected: PASS. A body that differs outside the stated list is a defect in the code, not the fixture.
- [ ] **Step 3: Run every test file this plan added or touched**, one at a time, plus `test/offersOffIdentity.test.js` and `test/matchingV2OffIdentity.test.js`. Expected: PASS.
- [ ] **Step 4: Write** the guide and update `docs/REMAINING_WORK.md`.
- [ ] **Step 5: Commit** `test(study): switch-off identity against main; rollout guide`.

---

## Server contract for Plan S2 (app)

- `GET /api/v1/app-config` → `studyEventsEnabled` (boolean; absent means false).
- `POST /api/v1/study/events` as in Task 5.
- `GET /api/v1/study/pack` → unchanged, plus `levelMeasured` (boolean) when levels v2 is on. A station completion response may carry `levelChange: { from, to }`.
- Tutor 429 bodies may carry `reason: 'conversation_full'` or `'daily_conversations'`.
- `GET /api/v1/learning/progress/weak-areas` is unchanged (`data: { weakAreas: [...] }`); the app is what must read that shape.
- The reminder push keeps `type: 'daily_drop'`.
