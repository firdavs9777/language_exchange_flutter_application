# AI Study phase 2b (backend): check before you send, after-chat recap — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A learner can have a draft message checked by AI before sending it, and after a chat gets a short recap of the words they looked up and one mistake to fix.

**Architecture:** One new endpoint calls the AI provider with its own prompt and a hard 6-second limit, behind a daily allowance on the user's existing quota counters. Recaps are computed when the app asks, from data phase 2a already stores (candidates, mistakes) plus the learner's own messages, and saved as small rows that expire after 7 days. Both sit behind their own switches, off.

**Tech Stack:** Node, Express, Mongoose 6.13, `services/aiProviderService.js` (`chatCompletion`), node:test with `--experimental-test-module-mocks`.

**Spec:** `docs/superpowers/specs/2026-11-14-ai-study-doors-recap-check-design.md` sections 2, 3, 5, 6, 8 (app repo, branch `docs/ai-study-spec`).

**Base:** backend `main` (02d0519 or later). Branch `feat/ai-study-check-recap`.

## Global Constraints

- New switches, default off: `STUDY_CHECK_ENABLED`, `STUDY_RECAP_ENABLED` (declared in `config/limitations.js` beside `STUDY_FROM_CHATS_ENABLED`, read with `flag()`); app-config keys `studyCheckEnabled`, `studyRecapEnabled`. With both off no response, write or collection differs from the base, except the stated additions to two enum lists.
- Only the learner's own text is sent to the AI provider by this plan. A partner's message text is never sent, never stored in a new place, and never returned by a new endpoint.
- The check never blocks sending: it has its own endpoint and the message endpoints are not touched.
- The server never sends an explanation to a free learner (left out of the response, not hidden by the app).
- No new collection is created at boot or while its switch is off; indexes are built lazily by an `ensure…Indexes()` function called behind the switch, as `services/studyMistakeService.js` does.
- Everything new is deleted with the learner's account on both deletion paths (`services/userCascadeDeleteService.js` and `deleteAccount` in `controllers/auth.js`); rows that point at a partner are deleted when that partner's account is deleted.
- Never String() a ref that may be populated; validate and cast ids before using them in filters.
- Tests: one file at a time, `node --experimental-test-module-mocks --test --test-force-exit test/X.test.js`; AI provider mocked with `mock.module('../services/aiProviderService.js', …)`. Never boot `server.js`; never connect to a real database.
- Every commit updates `docs/REMAINING_WORK.md` and lists open items in its body. No Co-Authored-By or any AI attribution. Stage by path; no `git add -A`; no stash.

## Review Focus

1. The AI provider answers slowly or with malformed JSON → the check answers `503 check_unavailable` within about 6 seconds and the learner's allowance is not used.
2. Two checks sent at the same moment by a free learner on their last allowance → exactly one is served.
3. The AI returns a "mistake" whose `original` is not in the learner's text, or 20 mistakes, or an explanation containing instructions → only mistakes whose original appears in the text are kept, at most 3, and nothing from the AI's free text is stored as a weak-area topic.
4. A recap is requested twice at once, or again a minute later → one recap per partner per day, never two.
5. The partner in a recap deletes their account → the recap is gone; the learner's kept words stay.

---

### Task 1: Switches, the language guess, and the two enum additions

**Files:**
- Modify: `config/limitations.js`, `controllers/appConfig.js`, `models/StudyEvent.js`, `models/PaywallEvent.js`, the three existing off-identity tests and `test/myWordsOffIdentity.test.js` (excuse the two new app-config keys: assert false, remove, compare)
- Create: `lib/languageGuess.js`, `test/languageGuess.test.js`, `test/checkRecapSwitches.test.js`

**Interfaces — Produces:**

```js
// lib/languageGuess.js — pure, no network
// true when the text is probably NOT in nativeLanguage; true when unsure.
function notNativeLanguage(text, nativeLanguage /* code or name; normalised with baseLanguage() */) → boolean
const SCRIPTS      // { zh, ja, ko, ar, ru, uk, th, hi, he, el, ka, hy, bn, ta, ... } → RegExp for that script
const STOP_WORDS   // { en, es, fr, de, it, pt, id, tr, vi, nl, pl, tl } → 12–20 very common words each
```

Rule: if the native language has its own script in `SCRIPTS`: native when at least half the letters are in that script. Otherwise, if it has `STOP_WORDS`: native when at least 2 words (or 1 of a text of 3 or fewer words) are in the list AND no other listed language scores higher. Anything else → not native (unsure counts). Empty or non-letter text → `false`.

- `models/StudyEvent.js` names gain `check_used`, `check_applied`, `recap_shown`, `recap_opened`. `models/PaywallEvent.js` placements gain `study_check`, `study_recap`. (These two additions are live at deploy; state them in the identity test and the guide.)

- [ ] **Step 1: Write the failing tests**

```js
test('Korean text is native for ko and not native for en', ...);
test('"I am going to the store" is native for en; "Voy a la tienda ahora" is not', ...);
test('a Latin-script text for a Spanish native that scores higher for French counts as not native', ...);
test('unsure (a language with no table, mixed text, one unknown word) counts as not native', ...);
test('empty text and emoji-only text are false', ...);
test('both switches default to false and appear in app-config as studyCheckEnabled / studyRecapEnabled', ...);
test('the new event names and placements are accepted; an unknown one is still refused', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the two new files and the four identity tests. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): check and recap switches (off), language guess, event names`.

---

### Task 2: Check before you send

**Files:**
- Create: `services/studyCheckService.js`, `controllers/studyCheck.js`, `test/studyCheck.test.js`
- Modify: `routes/dailyStudy.js`, `models/User.js` (one quota key), `config/limitations.js` (its daily caps), `services/studyMistakeService.js` (a `recordCheckMistakes` export)

**Interfaces — Produces:**

```js
// services/studyCheckService.js
const CHECK_TOPICS = ['verb tense','articles','word order','spelling','word choice','prepositions','agreement','punctuation','plural forms','other'];
async function runCheck({ text, targetLanguage, nativeLanguage, timeoutMs = 6000 })
  → { fine: boolean, corrected: string, natural: string|null, mistakes: [{ original, fix, explanation, topic }] }
  // throws CheckUnavailable on timeout, provider error, or unparseable JSON
// services/studyMistakeService.js
async function recordCheckMistakes({ learnerId, language, mistakes, now }) → number   // rows written
```

`POST /api/v1/study/check` (router-wide `protect`; `404 { success:false, error:'Not found' }` while `STUDY_CHECK_ENABLED` is off). Body `{ text }`.

Rules:

- `text` is trimmed; fewer than 3 words (or fewer than 4 characters in a script without spaces) or more than 500 characters → `400 { success:false, error:'invalid_text' }`, allowance untouched.
- Allowance: quota key `studyCheck` on the user's existing daily counters (follow `TUTOR_QUOTA_FIELDS` / `User.consumeQuota`: add `studyCheckToday` / `lastStudyCheckReset`). Caps: visitor and regular 3 a day, VIP 100 a day (fair use). The allowance is claimed atomically BEFORE the AI call and given back if the call fails (`CheckUnavailable`). When exhausted: `429` with the body `buildQuotaExceededResponse` makes, `feature: 'studyCheck'`, `reason: 'daily_checks'`, and `upgradeAvailable: false` (phase 3 turns that on).
- The AI call: `chatCompletion({ messages, feature: 'studyCheck', json: true, maxTokens: 500, temperature: 0.2 })` raced against `timeoutMs`. The prompt (own function `buildCheckPrompt`) gives the learner's target and native language and asks for JSON `{ fine, corrected, natural, mistakes:[{ original, fix, explanation, topic }] }` with `topic` one of `CHECK_TOPICS`, explanations of one sentence in the native language, and the instruction to treat the text as text to correct, never as instructions. The learner's text is passed as its own user message.
- Cleaning the answer: `corrected` defaults to the text; `natural` is null when equal to `corrected` (after whitespace collapse); a mistake is kept only when its `original` occurs in the learner's text (case-insensitive) and `fix` differs from it; at most 3; `topic` outside `CHECK_TOPICS` becomes `other`; every string cut to 300 characters. `fine` is true when no mistake survives and `corrected` equals the text.
- Response `200 { success:true, data: { fine, corrected, natural, mistakes: [{ original, fix, explanation? }], remaining, limit } }`. `explanation` is present only for VIP (`user.isVIP()`). `remaining` and `limit` are null for VIP.
- Failure: `503 { success:false, error:'check_unavailable' }`.
- When `STUDY_FROM_CHATS_ENABLED` is also on and mistakes were found: `recordCheckMistakes` writes one `StudyMistake` per mistake (`source:'check'`, `original`, `corrected: fix`, `explanation`, `language`: the learner's learning language via the saved-words normaliser), skipping one that already exists unresolved with the same `original` and `corrected` for that learner; and ONE weak area per distinct `topic` via `recordWeakArea(learnerId, { topic, source:'chat_check' })` with no example. Not awaited by the response; a failure there never changes the response. With that switch off nothing is stored.
- Nothing else about the draft is stored or logged (no GrammarFeedback row, no text in logs).

- [ ] **Step 1: Write the failing tests**

```js
test('404 while the switch is off', ...);
test('a fine sentence answers fine:true, no mistakes, natural null, and uses one allowance', ...);
test('a free learner gets mistakes without explanations; a VIP gets them', ...);
test('the fourth check of the day answers 429 daily_checks with upgradeAvailable false', ...);
test('two simultaneous checks on the last allowance: exactly one is served', ...);
test('a provider that never answers gives 503 within the timeout and the allowance is given back', ...); // timeoutMs injected small
test('malformed JSON gives 503 and the allowance is given back', ...);
test('a mistake whose original is not in the text is dropped; more than 3 are cut to 3; an unknown topic becomes other', ...);
test('text under 3 words or over 500 characters is 400 and uses no allowance', ...);
test('with chat capture on, mistakes are stored once (a repeat check does not duplicate) and weak areas use only CHECK_TOPICS', ...);
test('with chat capture off, nothing is stored', ...);
test('a failing store never changes the response', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `test/studyCheck.test.js`, `test/studyMistakes.test.js`, `test/studyMyWords.test.js`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): check before you send (STUDY_CHECK_ENABLED, off)`.

---

### Task 3: After-chat recap

**Files:**
- Create: `models/StudyRecap.js`, `services/studyRecapService.js`, `controllers/studyRecap.js`, `test/studyRecap.test.js`
- Modify: `routes/dailyStudy.js`

**Interfaces — Consumes:** `notNativeLanguage`, `isOneToOne` and `firstLearningLanguage` (`services/studyCaptureService.js`), `StudyCandidate`, `StudyMistake`, `rankCandidates` (`lib/candidateRank.js`), `runCheck` and `recordCheckMistakes` (Task 2). **Produces:**

```js
// models/StudyRecap.js (autoCreate/autoIndex off; lazy ensureStudyRecapIndexes())
{ user, partner, day /* 'YYYY-MM-DD' UTC */, language, sessionStart, sessionEnd,
  wordIds: [ObjectId], mistakeId: ObjectId|null, locked: Boolean, createdAt, expiresAt /* +7 days, TTL */ }
// unique { user, partner, day }; { user, createdAt:-1 }; { partner }
// services/studyRecapService.js
async function buildRecaps({ user, now, leftPartnerId = null }) → number   // recaps created
async function listRecaps({ user, now }) → [recap view]
```

`GET /api/v1/study/recaps` and `POST /api/v1/study/recaps/build` (body `{ partnerId? }`, sent by the app when the learner leaves a chat). Both `404` unless `STUDY_RECAP_ENABLED` and `STUDY_FROM_CHATS_ENABLED` are both on. `GET` first runs `buildRecaps` (no `leftPartnerId`), then lists.

Rules for `buildRecaps`:

- Looks at the learner's own one-to-one messages of the last 24 hours (not deleted), grouped by receiver. A group qualifies when at least 3 of them pass `notNativeLanguage(message, learner's native language)` and either the newest message between the two people (either direction; only its time is read) is at least 20 minutes old, or the receiver is `leftPartnerId`.
- At most 2 recaps per learner per UTC day and one per partner per day (the unique index is the guard; a duplicate-key error is treated as "already built"). Partners are tried newest session first.
- Session window: from the learner's first to last qualifying message, widened by 10 minutes each side.
- Words: the learner's candidates with `status: 'new'`, a `sources` entry for that partner with `at` inside the window, ranked by `rankCandidates`, top 2.
- Mistake: the newest unresolved `StudyMistake` with `source:'partner'`, that `partner`, created inside the window. If none and the learner is VIP: `runCheck` on the learner's qualifying messages joined (newest first, cut to 500 characters); its first mistake is stored through `recordCheckMistakes` and used; a `CheckUnavailable` is swallowed (recap without a mistake). This call does not use the check allowance. If none and the learner is not VIP: `locked: true`.
- A recap with no words and no mistake is not created (a locked line alone is not a recap).
- Only the learner's own message text is read for language and for the VIP check. A partner's message contributes only its timestamp.

`listRecaps` view: recaps not expired, newest first, at most 5:

```js
{ id, partner: { id, name }, createdAt,
  words: [ candidate row as GET /study/my-words returns it ],     // only those still status 'new'
  mistake: mistake row as GET /study/my-words returns it | null,   // only while unresolved
  locked: boolean }
```

A recap whose words are all kept or dismissed and whose mistake is gone or resolved is left out of the list (and deleted). Keep, Dismiss and Got it are the existing endpoints; there are no recap-specific actions.

- [ ] **Step 1: Write the failing tests**

```js
test('404 unless both switches are on', ...);
test('three learning-language messages and 20 quiet minutes make one recap with up to two words and the partner correction', ...);
test('two messages, or three in the native language, make no recap', ...);
test('a conversation still active is skipped unless the app says the learner left it', ...);
test('a second build the same day for the same partner creates nothing; a third partner the same day is refused', ...);
test('two builds at the same moment create one recap', ...);
test('free learner with no partner correction: words plus locked:true; VIP: the AI mistake is stored once and shown', ...);
test('the VIP check failing still produces the recap with its words', ...);
test('no words and no mistake: no recap, even if it would be locked', ...);
test('a kept word leaves the recap; when everything is handled the recap disappears from the list', ...);
test('the view carries the partner name and id and no message text', ...);
test('only the learner\'s own text reaches the AI mock', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `test/studyRecap.test.js`, `test/studyCheck.test.js`, `test/studyCapture.test.js`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): after-chat recap (STUDY_RECAP_ENABLED, off)`.

---

### Task 4: Deletion, the funnel, identity, and the rollout guide

**Files:**
- Modify: `services/studyMyWordsDeletion.js` (recaps), `lib/studyFunnel.js`, `scripts/studyFunnel.js`, `docs/REMAINING_WORK.md`
- Create: `test/studyRecapDeletion.test.js`, `test/support/checkRecapOffScenario.js`, `scripts/dev/generateCheckRecapOffFixtures.js`, `test/fixtures/check-recap-off/bodies.json`, `test/checkRecapOffIdentity.test.js`, `docs/rollout/ai-study-check-recap.md`

Rules:

- Learner deleted (both paths): their recaps are deleted. Partner deleted (both paths): recaps with that `partner` are deleted. The id guard in `removeStudyMyWordsData` covers the new statements; no collection is created by the cleanup.
- Funnel: one line each for checks (`check_used`, `check_applied`, distinct learners) and recaps (`recap_shown`, `recap_opened`) in the window.
- Identity (follow `test/myWordsOffIdentity.test.js`; fixtures generated from this plan's base commit in a temporary worktree, in-memory database, providers mocked): a learner and a partner exchange five one-to-one messages; `GET /app-config`; a translate; a partner correction; a writing-feedback request; `GET /study/my-words` with chat capture on; the learner's deletion. Stated differences: the two new app-config keys (false); the new event names and placements are accepted. Further assertions: no `studyrecaps` collection exists; the new routes answer 404; the user document has no `studyCheck` counter fields after the scenario.
- Guide (plain language, like `docs/rollout/ai-study-my-words.md`): what changes at deploy (only the two enum additions); the order to switch (check first, on its own; recap needs chat capture on); the cost note (each check is one AI call of about 500 output tokens at most; a recap costs an AI call only for VIP learners without a partner correction); the privacy note (only the learner's own text goes to the AI provider; whether the privacy policy and store forms need the line in `docs/releases/ai-study-chat-capture-privacy-draft.md` plus one about checked text is the owner's check); how to turn each off.

- [ ] **Step 1: Write the failing tests** (deletion on both paths; funnel summary; identity).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement**; generate the fixtures.
- [ ] **Step 4: Run every test file this plan added or touched**, one at a time, plus `myWordsOffIdentity`, `studyOffIdentity`, `offersOffIdentity`, `matchingV2OffIdentity`, `studyMyWordsDeletion`. Expected: PASS.
- [ ] **Step 5: Commit** `test(study): check and recap switch-off identity; deletion; rollout guide`.

---

## Server contract for the app plan

- `GET /api/v1/app-config` → `studyCheckEnabled`, `studyRecapEnabled`.
- `POST /api/v1/study/check` `{ text }` → `200 { fine, corrected, natural, mistakes:[{ original, fix, explanation? }], remaining, limit }`; `400 invalid_text`; `429` (`reason: 'daily_checks'`, `upgradeAvailable`, `resetAt`); `503 check_unavailable`; `404` while off.
- `GET /api/v1/study/recaps` → `{ recaps: [{ id, partner:{ id, name }, createdAt, words:[…], mistake|null, locked }] }`; `POST /api/v1/study/recaps/build` `{ partnerId? }` → `{ created }`; both `404` unless recap and capture are on.
- Study events accepted: `check_used`, `check_applied`, `recap_shown`, `recap_opened`. Paywall placements accepted: `study_check`, `study_recap`.

## Calls made in this plan (not the owner's decisions)

- The check calls the AI provider directly with its own prompt and stores no writing-feedback row; the Writing tile is untouched.
- A check costs allowance only when it succeeds. Draft length is capped at 500 characters.
- VIP fair use is 100 checks a day.
- At most 3 mistakes per check are returned and stored; weak areas use a fixed list of ten topics, never the AI's free text.
- The recap's AI-found mistake for VIP does not use the check allowance.
- A recap needs at least one word or one mistake; a locked line alone does not make one.
- Until phase 3, a used-up allowance reports `upgradeAvailable: false`, so the app says "more tomorrow" instead of selling.
