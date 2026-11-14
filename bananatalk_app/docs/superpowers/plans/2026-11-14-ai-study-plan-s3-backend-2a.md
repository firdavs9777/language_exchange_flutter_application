# AI Study, Plan S3 (backend, phase 2a: the learner's own words and mistakes) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The server keeps, per learner, the words they looked up while chatting and the mistakes they were corrected on, ranks them, lets the learner keep or clear them, feeds weak areas from real evidence, and tells the app what is waiting behind the "My words and mistakes" door.

**Architecture:** Two new collections (`studycandidates`, `studymistakes`) written from hooks in the existing translate and correction handlers, both created lazily and only while a switch is on. Pure modules do the ranking and the weak-area bookkeeping. A small set of endpoints under `/study` serves the new screen. Pronunciation scoring learns to record that a sentence was the learner's own.

**Tech Stack:** Node.js, Express, Mongoose, `node:test` with `mongodb-memory-server`.

**Specs:** `docs/superpowers/specs/2026-11-14-ai-study-doors-recap-check-design.md` (sections 4, 4.1, 7, 8: phase 2a) and `docs/superpowers/specs/2026-11-14-ai-study-path-design.md` (6.1, 6.2). The app half is Plan S4.

**Repo and branch:** backend repo, new worktree `/Users/davis/Desktop/Personal/be-study-2a`, branch `feat/ai-study-my-words`. Base: local `main` of `/Users/davis/Desktop/Personal/be-integration` (it holds the phase 1 merge, which this plan builds on, and is ahead of `origin/main`).

## Global Constraints

- Two new switches, default off, declared with `flag()` in `config/limitations.js`: `STUDY_FROM_CHATS_ENABLED` (capture, mistakes, weak-area writers, their endpoints) and `STUDY_DOORS_ENABLED` (only an app-config key; the server has no door logic). App-config keys `studyFromChatsEnabled`, `studyDoorsEnabled`, placed after `studyEventsEnabled`.
- With both switches unset every existing response is byte-identical to this plan's base, no new collection or index is created, and nothing new is written. The last task proves it against the base commit, following `test/studyOffIdentity.test.js`.
- New models set `autoCreate: false, autoIndex: false` and build their indexes once, lazily, on the first write while the switch is on (the pattern in `controllers/studyEvents.js`).
- A hook added to an existing handler never changes that handler's response or timing: it runs after the response is prepared, is not awaited, and logs and swallows its own errors.
- Privacy: a candidate holds a word or phrase and its translation, never a sentence from a partner's message. Everything is private to the learner. Rows are removed with the learner's account on both deletion paths (`services/userCascadeDeleteService.js` and the `modelsToClean` list in `controllers/auth.js` `deleteAccount`). When a partner's account is deleted, that partner is removed from candidates' sources (a candidate with no sources left and not kept is deleted) and mistakes that came from that partner's correction are deleted.
- Guarded routes answer `404 { success: false, error: 'Not found' }` while off. New error strings must not contain `limit`, `blocked`, `not found`, `unauthorized` or `401`.
- Tests: `node --experimental-test-module-mocks --test --test-force-exit test/<file>.test.js`, one file at a time. Never start `server.js`; never run a script against a real database; no AI provider calls in tests.
- Never add a Co-Authored-By or any Claude attribution line. Every commit updates `docs/REMAINING_WORK.md` and lists what is still open in its body. Stage by path. Do not push `main`.

## Review Focus

1. A learner translates their own message, a message in a language they are not learning, or a message in a room or group: no candidate is captured. (Task 2)
2. The same word met in two chats: one candidate with two sources; one partner deleted: the candidate stays; both deleted and not kept: gone; kept: the saved word stays. (Tasks 2, 5)
3. A translate or correction request while the capture store is failing: the original response is unchanged and nothing is thrown. (Tasks 2, 3)
4. One learner asking for, keeping, dismissing or clearing another learner's candidate or mistake: refused, nothing changes. (Task 4)
5. Keep pressed twice, or Keep on a word already in the learner's saved words: one saved word, no duplicate, review history untouched. (Task 4)

---

### Task 1: Weak areas get real writers

**Files:**
- Create: `lib/weakAreas.js`, `services/weakAreaService.js`
- Modify: `config/limitations.js`, `controllers/appConfig.js`, `services/dailyPackService.js` (grammar station completion), the writing-feedback completion path (`grep -rn "GrammarFeedback" controllers services`), `models/TutorMemory.js` only if the weak-area subdocument needs a `source` or `example` field
- Test: `test/weakAreas.test.js`, `test/weakAreaWriters.test.js`

**Interfaces (Produces):**

```js
// lib/weakAreas.js (pure)
const SOURCES = ['pack_grammar', 'writing_feedback', 'partner_correction', 'chat_check', 'pronunciation', 'roleplay'];
noteWeakArea(weakAreas, { topic, source, example }, now) -> weakAreas   // new array; never mutates
// services/weakAreaService.js
recordWeakArea(userId, { topic, source, example }) -> Promise<void>      // no-op while STUDY_FROM_CHATS_ENABLED is off; never throws
```

Rules:

- Read `lib/tutorMemoryDecay.js` and `models/TutorMemory.js` first: an existing weak area has a topic, a frequency that halves every 14 days, and is resolved after 3 successes. `noteWeakArea` raises the frequency of an existing unresolved area with the same topic (case-insensitive, trimmed) by 1 and refreshes its last-seen time; otherwise appends a new one with frequency 1. A resolved area that recurs becomes unresolved with frequency 1. `topic` is cut to 80 characters; `example` to 200; at most 30 areas are kept (lowest frequency, then oldest, dropped first).
- Writers in this task: a grammar station completed with at least one wrong answer records the unit's title as the topic (`pack_grammar`); a completed writing-feedback request records each distinct error type it reports, at most 3 per request (`writing_feedback`). Later tasks add `partner_correction`; `chat_check` and `roleplay` belong to later plans; the existing pronunciation writer is left as it is.
- Declare both switches and both app-config keys in this task.

- [ ] **Step 1: Write the failing tests.**

```js
test('a new topic is appended with frequency 1', ...);
test('the same topic in another case raises the frequency and keeps one entry', () => {
  const a = noteWeakArea([], { topic: 'Past tense', source: 'pack_grammar' }, NOW);
  const b = noteWeakArea(a, { topic: ' past TENSE ', source: 'writing_feedback' }, NOW);
  assert.equal(b.length, 1);
  assert.equal(b[0].frequency, 2);
  assert.equal(a[0].frequency, 1);          // input not mutated
});
test('a resolved area that recurs is unresolved again with frequency 1', ...);
test('the 31st area drops the weakest', ...);
test('topic and example are cut to 80 and 200 characters', ...);
test('switch off: recordWeakArea writes nothing', ...);
test('a grammar station with a wrong answer records the unit title; a perfect one records nothing', ...);
test('a writing feedback with five error types records three', ...);
test('recordWeakArea never throws when the store fails', ...);
```

- [ ] **Step 2: Run** both files. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** them plus `test/dailyPackCompletion.test.js`, `test/tutorDailyPlan.test.js` and the existing tutor memory decay tests. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): weak areas are written from pack and writing results (STUDY_FROM_CHATS_ENABLED, off)`.

---

### Task 2: Words captured from chat translations

**Files:**
- Create: `models/StudyCandidate.js`, `lib/candidateRank.js`, `services/studyCaptureService.js`
- Modify: `controllers/advancedMessages.js` (the translate handler, after the response data is built)
- Test: `test/candidateRank.test.js`, `test/studyCapture.test.js`

**Interfaces (Produces):**

```js
// models/StudyCandidate.js  (collection studycandidates, autoCreate/autoIndex false)
// { user, language, key, text, translation, partOfSpeech, sources: [{ partner, at }], seenCount, lastSeenAt,
//   status: 'new' | 'kept' | 'dismissed', vocabularyId, expiresAt, createdAt }
// indexes: unique { user, language, key }; { user, status, lastSeenAt }; TTL on expiresAt
normalizeKey(text) -> string                         // lower-cased, trimmed, inner whitespace collapsed, surrounding punctuation stripped
captureFromTranslation({ userId, message, breakdown, learnerLanguage, now }) -> Promise<number>   // candidates touched; never throws
rankCandidates(candidates, { now, level }) -> candidates   // pure, best first
```

Rules:

- Capture only when all hold: the switch is on; the message's sender is not the learner; the conversation is one-to-one (not a room or group; read how the Message or Conversation marks those); the language of the message, normalised with `toBaseLanguage`, equals the learner's first learning language. When the message's language is unknown, capture only if the request's `sourceLanguage` normalises to the learner's language.
- From the translation's `breakdown`, take items whose `word` is 2 to 40 characters after normalising and has a non-empty `meaning`; at most 8 per translation; skip pure numbers and punctuation. Each becomes or updates one candidate keyed by (learner, language, key): `seenCount` rises by 1, `lastSeenAt` becomes now, the partner is added to `sources` once (latest time kept), and `expiresAt` is set to now plus 14 days unless the candidate is kept (kept candidates never expire: `expiresAt` unset).
- A dismissed candidate that is met again stays dismissed for 14 days from its dismissal and is then treated as new.
- A word already in the learner's saved words (same word, case-insensitive) is not captured.
- Ranking score: `seenCount` capped at 5, plus 2 if seen in the last 3 days, plus 1 if it has two or more sources; ties by most recent. `level` is accepted and unused in this version (say so in a comment).
- The hook is called without awaiting, after the handler has built its response, and only when the translation succeeded.

- [ ] **Step 1: Write the failing tests.**

```js
test('normalizeKey: "  Hello!! " -> "hello"; "ice  cream" -> "ice cream"', ...);
test('a partner message in the learning language yields candidates with the partner as source', ...);
test('own message, another language, a room message: nothing captured', ...);
test('the same word from two partners is one candidate with two sources and seenCount 2', ...);
test('at most 8 items per translation; numbers and punctuation skipped', ...);
test('a word already saved is not captured', ...);
test('a dismissed word stays dismissed for 14 days, then is new again', ...);
test('ranking: seen 4 times beats seen once; recent beats old at equal counts', ...);
test('the translate response is identical with the switch on and the capture store failing', ...);
test('switch off: no studycandidates collection after a translate', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** both files and the existing translate tests (`ls test | grep -i translat`). Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): words looked up in chat become candidates`.

---

### Task 3: Mistakes from partner corrections

**Files:**
- Create: `models/StudyMistake.js`, `services/studyMistakeService.js`
- Modify: `controllers/advancedMessages.js` (`addCorrection`), `socket/socketHandler.js` (the correction path around `correction_received`)
- Test: `test/studyMistakes.test.js`

**Interfaces (Produces):**

```js
// models/StudyMistake.js  (collection studymistakes, autoCreate/autoIndex false)
// { user, language, original, corrected, explanation, source: 'partner' | 'check', partner, messageId,
//   successes, resolvedAt, createdAt }
// indexes: { user, resolvedAt, createdAt }; unique sparse { user, messageId, source }
recordPartnerCorrection({ learnerId, partnerId, message, corrected, explanation, now }) -> Promise<void>   // never throws
```

Rules:

- Written when the switch is on and a partner corrects the learner's message through either path (REST and socket), once per (message, partner correction): a second correction of the same message replaces the stored `corrected` and `explanation`.
- `original` and `corrected` are cut to 500 characters, `explanation` to 500. `language` is the learner's first learning language. Corrections where `corrected` equals `original` after trimming are ignored.
- Each new mistake also calls `recordWeakArea` with source `partner_correction`, topic = the first 80 characters of `explanation` when present, otherwise the literal topic `corrections from partners`, and `example` = `original → corrected`.
- The hook never changes the correction response or the socket events.

- [ ] **Step 1: Write the failing tests.**

```js
test('a partner correction creates one mistake for the message author', ...);
test('the socket path and the REST path both write, and a repeat replaces the text', ...);
test('a correction identical to the original is ignored', ...);
test('long texts are cut to 500 characters', ...);
test('a weak area is recorded with the explanation as topic, or the fallback topic', ...);
test('the correction response and socket payload are unchanged with the switch on', ...);
test('switch off: no studymistakes collection after a correction', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the file and the existing correction tests (`ls test | grep -i correct`). Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): partner corrections become mistakes to revisit`.

---

### Task 4: The endpoints behind "My words and mistakes"

**Files:**
- Create: `controllers/studyMyWords.js`
- Modify: the study router (where `/study/pack` and `/study/events` live), `middleware/rateLimiter.js` if a limiter is needed
- Test: `test/studyMyWords.test.js`

**Interfaces (Produces):** all authenticated, all `404` while `STUDY_FROM_CHATS_ENABLED` is off.

- `GET /api/v1/study/my-words` → `{ success, data: { counts: { candidates, mistakes, dueWords }, candidates: [...], mistakes: [...] } }`. `candidates`: up to 20, ranked, each `{ id, text, translation, partOfSpeech, seenCount, lastSeenAt }` (no partner ids). `mistakes`: up to 20 unresolved, newest first, each `{ id, original, corrected, explanation, source, createdAt, successes }`. `dueWords`: the count the existing review screen uses (non-archived, non-mastered, due now).
- `POST /api/v1/study/candidates/:id/keep` → `{ success, data: { vocabularyId } }`. Saves the word through the same path the app's "save word" uses (language from `normalizeVocabLanguage`, source `chat`), marks the candidate kept and stores the vocabulary id. Idempotent: a second keep, or a word already saved, returns the existing vocabulary id and changes nothing else.
- `POST /api/v1/study/candidates/:id/dismiss` → `{ success }`. Idempotent.
- `POST /api/v1/study/mistakes/:id/got-it` → `{ success, data: { successes, resolved } }`. Adds one success; at 3 the mistake is resolved and the matching weak area gets a success through the existing resolve rule.

Rules: every `:id` route loads the row by id AND owner; a row that is not the caller's answers `404` exactly like a missing one. Invalid ids answer `400` with error `invalid id`. The free-tier limit of 5 keeps a day is not enforced in this phase.

- [ ] **Step 1: Write the failing tests.**

```js
test('my-words returns counts and ranked candidates without partner ids', ...);
test('keep saves one vocabulary word under the learner language and marks the candidate kept', ...);
test('keep twice returns the same vocabulary id and creates nothing', ...);
test('keep on a word already saved links to the existing word and leaves its review history alone', ...);
test('dismiss hides the candidate from my-words', ...);
test('got-it three times resolves the mistake and it leaves the list', ...);
test("another learner's candidate or mistake answers 404 and is unchanged", ...);
test('an invalid id answers 400', ...);
test('switch off: every route answers 404', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the file plus `test/vocabLanguage.test.js`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): my words and mistakes endpoints`.

---

### Task 5: Deletion, and saying your own sentence

**Files:**
- Modify: `services/userCascadeDeleteService.js`, `controllers/auth.js` (`deleteAccount` list), the pronunciation model and route (`models/PronunciationAttempt.js`, `routes/speech.js` and its controller), `lib/studyFunnel.js` / `scripts/studyFunnel.js`
- Test: `test/studyMyWordsDeletion.test.js`, `test/pronunciationOwnSource.test.js`

Rules:

- Learner deleted (both paths): their candidates and mistakes are deleted; stats keys appear only when something was deleted; no collection is created by the cleanup when none exists.
- Partner deleted (both paths): that partner is pulled from every candidate's `sources`; candidates left with no sources and status other than `kept` are deleted; mistakes whose `partner` is that user are deleted. Kept candidates and the learners' saved words stay.
- `PronunciationAttempt.source` gains the value `own`. `POST /speech/pronunciation/evaluate` accepts `source: 'own'` (any other new value is refused as today's validation refuses unknown values) and stores it. No other behaviour changes; no switch (the app only sends it from the new screen).
- The study funnel script prints one extra line: pronunciation attempts in the window split into own and supplied.

- [ ] **Step 1: Write the failing tests** (behavioural, driving the real `deleteAccount` cleanup and the cascade service's function where it can load, as `test/deleteAccountStudyEvents.test.js` does):

```js
test("deleting a learner removes their candidates and mistakes, not another learner's", ...);
test('deleting a partner removes that source; a candidate with another source stays; one with none and not kept is deleted; a kept one stays', ...);
test("deleting a partner deletes mistakes from that partner's corrections", ...);
test('no studycandidates or studymistakes collection is created by a deletion when none existed', ...);
test('an attempt sent with source own is stored as own; an unknown source is refused as before', ...);
test('the funnel summary counts own and supplied attempts', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** both files plus `test/deleteAccountStudyEvents.test.js`, `test/deleteAccountPaywallData.test.js`, `test/studyFunnel.test.js`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): my words and mistakes are deleted with either account; pronunciation records an own sentence`.

---

### Task 6: Switch-off identity and the rollout guide

**Files:**
- Create: `test/support/myWordsOffScenario.js`, `scripts/dev/generateMyWordsOffFixtures.js`, `test/fixtures/my-words-off/bodies.json`, `test/myWordsOffIdentity.test.js`, `docs/rollout/ai-study-my-words.md`
- Modify: `docs/REMAINING_WORK.md`, and the other identity tests so they excuse the two new app-config keys (assert false, remove, compare), as they already do for each other's keys

Follow `test/support/studyOffScenario.js` and `test/studyOffIdentity.test.js` exactly. Fixtures are generated from this plan's base commit in a temporary worktree; record the commit in the test header.

Scenario, using only code on the base: a learner of English and a native partner in a one-to-one conversation with three partner messages; capture `GET /app-config`; a translate of a partner message (AI provider mocked); a partner correction through REST; a grammar station completion with one wrong answer; a writing-feedback request (provider mocked); a pronunciation evaluation with today's default source; the learner's account deletion. Stated differences: the two new app-config keys (false); `source: 'own'` is accepted by the pronunciation route. Further assertions: no `studycandidates` or `studymistakes` collection after the scenario; the learner's tutor memory weak areas equal the base's; the four new routes answer `404`.

Guide contents: what changes for everyone at deploy (only the accepted `own` source); the two switches (capture and its endpoints first, on its own, watched for a week through `GET /study/my-words` counts; the doors key only once the app build with the new hub is out); privacy notes for the owner (words and phrases only, learner-side, removed with either account; whether the privacy policy and store forms need a line is the owner's check before the switch goes on); how to turn each off, and that turning capture off stops new writes but keeps what was captured.

- [ ] **Step 1: Write** the scenario and generator; generate fixtures from the base commit.
- [ ] **Step 2: Write** the identity test and update the other identity tests for the new keys; run them all. Expected: PASS.
- [ ] **Step 3: Run every test file this plan added or touched**, one at a time, plus `studyOffIdentity`, `offersOffIdentity`, `matchingV2OffIdentity`, `matchingV2Switches`. Expected: PASS.
- [ ] **Step 4: Write** the guide and update `docs/REMAINING_WORK.md`.
- [ ] **Step 5: Commit** `test(study): my-words switch-off identity; rollout guide`.

---

## Server contract for Plan S4 (app)

- `GET /api/v1/app-config` → `studyFromChatsEnabled`, `studyDoorsEnabled` (booleans; absent means false).
- `GET /api/v1/study/my-words`, `POST /study/candidates/:id/keep`, `POST /study/candidates/:id/dismiss`, `POST /study/mistakes/:id/got-it` as in Task 4; all `404` while capture is off.
- `POST /api/v1/speech/pronunciation/evaluate` accepts `source: 'own'`.
- Nothing about translate, corrections or the daily pack changes for the app.
