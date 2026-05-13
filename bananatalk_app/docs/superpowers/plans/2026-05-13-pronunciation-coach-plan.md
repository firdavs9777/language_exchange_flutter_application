# Pronunciation Coach Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a 5-sentence pronunciation drill in AI Study where users record a target sentence, get word-level scoring with character-level diff highlighting, and have weak words folded back into `TutorMemory.weakAreas`.

**Architecture:** Three stateless backend endpoints (sentence generation, scoring, summary) wrap OpenAI Whisper + TTS. Pure JS scoring function (Levenshtein word alignment + char diff) is unit-tested in isolation. Flutter side has one `StateNotifier`-driven screen with a 6-state state machine, mirroring the existing `tutor_voice_service` recorder pattern. Weak words from each session are upserted into the existing `TutorMemory.weakAreas` field, closing the loop with chat/story which already pull weak areas into their system prompts.

**Tech Stack:** Node.js / Express / Mongoose (backend), Flutter / Riverpod / flutter_sound (mobile), OpenAI Whisper + TTS + GPT-4o-mini (AI services). Node's built-in `node:test` for backend unit tests (zero new deps).

**Spec:** `docs/superpowers/specs/2026-05-13-pronunciation-coach-design.md` (committed)

**Branch:** `feat/step11-pronunciation-coach` on both repos (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app` and `/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Pacing:** Drive uninterrupted through tasks; surface only at major gates (each commit is OK to continue without confirmation, per user's recorded preference in `feedback_pacing.md`).

---

## File Structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Create:**
- `services/pronunciationScoring.js` — pure function `score(transcript, target) → { overallScore, wordScores, transcript }`. No I/O.
- `services/pronunciationScoring.test.js` — node:test unit tests for the scoring function.

**Modify:**
- `routes/tutor.js` — add 3 routes under existing `protect` middleware.
- `controllers/tutor.js` — add 3 handlers (`generatePronunciationSentence`, `scorePronunciationAttempt`, `submitPronunciationSummary`).
- `package.json` — add `"test": "node --test services/*.test.js"` to scripts.

**Reuse (no change):**
- `services/speechService.js` — `transcribeAudio()`, `generateTTS()`.
- `services/openaiService.js` (or wherever GPT calls live) — chat completion for sentence generation.
- `models/TutorMemory.js` — `weakAreas` upsert target.
- `middleware/auth.js` — `protect` middleware.
- Existing multer audio config in `routes/tutor.js` (25MB cap, audio/* allowlist).

### Flutter (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

**Create:**
- `lib/services/pronunciation_voice_service.dart` — recorder lifecycle wrapper (parallels `tutor_voice_service.dart`).
- `lib/providers/pronunciation_provider.dart` — `PronunciationController extends StateNotifier<PronunciationState>` with `_safeSet` mounted-guard pattern. Plus state classes (`SentenceAttempt`, `ScoreResult`, etc.).
- `lib/pages/ai/tutor/pronunciation_session_screen.dart` — full-screen drill UX with 6-state machine.
- `lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart` — single-sentence widget (target text + TTS button + scored word render).
- `lib/pages/ai/tutor/widgets/pronunciation_summary_sheet.dart` — end-of-session bottom sheet.
- `test/pages/ai/tutor/pronunciation_session_screen_test.dart` — widget tests for the state machine.

**Modify:**
- `lib/providers/tutor_provider.dart` — add 3 methods to `TutorService` class (`fetchPronunciationSentence`, `scorePronunciationAttempt`, `submitPronunciationSummary`).
- `lib/pages/learning/main/sections/ai_tools_tab.dart` — add 5th chip "🎙️ Pronounce".
- `lib/l10n/app_en.arb` — ~18 new keys under `aiTutorPronounce*` prefix.

**Reuse (no change):**
- `lib/services/api_client.dart` — `postMultipart()` already exists.
- `lib/pages/ai/tutor/persona_picker_screen.dart` — `destinationAfterPick` param (added in earlier work).
- Existing `flutter_sound`, `permission_handler`, `path_provider`, `just_audio` packages.

---

## Critical decisions made in this plan (not in spec)

1. **Backend test framework: node:test (Node ≥18 built-in).** The backend has no existing test framework. Rather than adding jest + supertest as new dependencies, use the built-in `node:test` runner. Only the pure scoring service gets unit tests; route-level integration tests are deferred to manual smoke (see Task 11), consistent with spec §9's "highest ROI is the scoring tests."

2. **`TutorService` is extended in-place inside `lib/providers/tutor_provider.dart`** (not split into a separate `tutor_service.dart`). The existing file is small (~250 lines), and 3 new methods don't justify a split.

3. **`PronunciationVoiceService` is a new file**, not an extension of `tutor_voice_service.dart`. The chat-voice service has its own recorder lifecycle bound to a chat session — mixing pronunciation drills into it would entangle two distinct flows. The new file mirrors the same pattern (recorder init/dispose, single-file output, multipart upload), independently.

4. **L10n batched into the final commit** (Task 10) so each upstream commit doesn't churn the ARB file. Locale fallback (English) handles all 18 non-English locales until manually translated later.

5. **Scoring threshold constant `PRONUNCIATION_WRONG_THRESHOLD = 0.6`** lives at the top of `services/pronunciationScoring.js` as a named export — tunable in one place after we see real data.

---

## Task 0: Branch setup

**Files:** none yet

- [ ] **Step 1: Create the branch on both repos**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull && git checkout -b feat/step11-pronunciation-coach

cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull && git checkout -b feat/step11-pronunciation-coach
```

Expected: `On branch feat/step11-pronunciation-coach` in both repos.

- [ ] **Step 2: Verify Node version supports `node:test`**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application && node -v
```

Expected: `v18.x.x` or higher. If lower, install Node 20 via nvm before continuing — `node:test` is unavailable on Node <18.

No commit yet — Task 1 includes the first commit.

---

## Task 1: Pronunciation scoring service (pure function + tests)

**Files:**
- Create: `services/pronunciationScoring.js`
- Create: `services/pronunciationScoring.test.js`
- Modify: `package.json` (add test script)

Working directory: `/Users/davis/Desktop/Personal/language_exchange_backend_application`

- [ ] **Step 1: Add test script to package.json**

Edit `package.json` `scripts` block, adding:

```json
"test": "node --test services/*.test.js"
```

- [ ] **Step 2: Write the failing test file**

Create `services/pronunciationScoring.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { score, PRONUNCIATION_WRONG_THRESHOLD } = require('./pronunciationScoring');

test('exact match returns 100 and all ok', () => {
  const r = score('I walked to the park yesterday', 'I walked to the park yesterday.');
  assert.equal(r.overallScore, 100);
  assert.equal(r.wordScores.every(w => w.status === 'ok'), true);
  assert.equal(r.wordScores.every(w => w.charDiff === null), true);
});

test('one char off (par for park) marks wrong with charDiff', () => {
  const r = score('I walked to the par yesterday', 'I walked to the park yesterday.');
  const park = r.wordScores.find(w => w.word === 'park');
  assert.equal(park.status, 'wrong');
  assert.ok(Array.isArray(park.charDiff));
  assert.deepEqual(park.charDiff.map(c => c.match), [true, true, true, false]);
  assert.ok(r.overallScore >= 50 && r.overallScore < 100);
});

test('completely different word (doodle for park) marks missing', () => {
  const r = score('I walked to the doodle yesterday', 'I walked to the park yesterday.');
  const park = r.wordScores.find(w => w.word === 'park');
  assert.equal(park.status, 'missing');
  assert.equal(park.charDiff, null);
});

test('empty transcript: all words missing, score 0', () => {
  const r = score('', 'I walked to the park yesterday.');
  assert.equal(r.overallScore, 0);
  assert.equal(r.wordScores.every(w => w.status === 'missing'), true);
});

test('extra words in transcript are silently dropped', () => {
  const r = score('I walked to the park yesterday and stuff', 'I walked to the park yesterday.');
  assert.equal(r.overallScore, 100);
  assert.equal(r.wordScores.length, 6); // only target words
});

test('missing word in transcript marked missing', () => {
  const r = score('I walked to park yesterday', 'I walked to the park yesterday.');
  const the = r.wordScores.find(w => w.word === 'the');
  assert.equal(the.status, 'missing');
});

test('punctuation is stripped before comparison', () => {
  const r = score('Hello, world!', 'Hello world.');
  assert.equal(r.overallScore, 100);
});

test('case is normalized (uppercase transcript matches lowercase target)', () => {
  const r = score('HELLO WORLD', 'hello world');
  assert.equal(r.overallScore, 100);
});

test('threshold boundary: ratio 0.75 is wrong (above 0.6)', () => {
  // "park" (4) vs "par" (3) → editDist 1, ratio = 1 - 1/4 = 0.75
  const r = score('par', 'park');
  assert.equal(r.wordScores[0].status, 'wrong');
});

test('threshold boundary: ratio 0.25 is missing (below 0.6)', () => {
  // "park" (4) vs "pop" (3) → editDist 3, ratio = 1 - 3/4 = 0.25
  const r = score('pop', 'park');
  assert.equal(r.wordScores[0].status, 'missing');
});

test('longer words weighted more than shorter (yesterday wrong > the wrong)', () => {
  const longWrong = score('I walked to the park yesturday', 'I walked to the park yesterday');
  const shortWrong = score('I walked too the park yesterday', 'I walked to the park yesterday');
  // both have one near-miss; yesterday is longer → harder hit on score
  assert.ok(longWrong.overallScore < shortWrong.overallScore);
});

test('unicode (Korean) tokenization works', () => {
  const r = score('안녕하세요', '안녕하세요');
  assert.equal(r.overallScore, 100);
});

test('one-word target sentence: exact match', () => {
  const r = score('hello', 'Hello!');
  assert.equal(r.overallScore, 100);
});

test('threshold constant is exposed', () => {
  assert.equal(PRONUNCIATION_WRONG_THRESHOLD, 0.6);
});

test('returns the normalized transcript in the result', () => {
  const r = score('Hello, World!', 'hello world');
  assert.equal(typeof r.transcript, 'string');
  assert.ok(r.transcript.length > 0);
});
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
npm test
```

Expected: All tests FAIL with `Error: Cannot find module './pronunciationScoring'` or similar — `pronunciationScoring.js` doesn't exist yet.

- [ ] **Step 4: Implement pronunciationScoring.js**

Create `services/pronunciationScoring.js`:

```js
const PRONUNCIATION_WRONG_THRESHOLD = 0.6;

// Tokenize: lowercase, strip punctuation (keep letters/numbers/whitespace/apostrophes), split.
function normalize(s) {
  return (s || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s']/gu, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokens(s) {
  const n = normalize(s);
  return n.length ? n.split(' ') : [];
}

// Char-level Levenshtein edit distance.
function editDistance(a, b) {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  const dp = Array.from({ length: a.length + 1 }, (_, i) => i);
  for (let j = 1; j <= b.length; j++) {
    let prev = dp[0];
    dp[0] = j;
    for (let i = 1; i <= a.length; i++) {
      const tmp = dp[i];
      dp[i] = a[i - 1] === b[j - 1]
        ? prev
        : 1 + Math.min(prev, dp[i], dp[i - 1]);
      prev = tmp;
    }
  }
  return dp[a.length];
}

// Char-level diff producing [{char, match}] aligned to target.
function computeCharDiff(target, spoken) {
  const m = target.length, n = spoken.length;
  const dp = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = target[i - 1] === spoken[j - 1]
        ? dp[i - 1][j - 1]
        : 1 + Math.min(dp[i - 1][j - 1], dp[i - 1][j], dp[i][j - 1]);
    }
  }
  // Backtrace, marking each target character match/no-match.
  const out = new Array(m);
  let i = m, j = n;
  while (i > 0) {
    if (j > 0 && target[i - 1] === spoken[j - 1] && dp[i][j] === dp[i - 1][j - 1]) {
      out[i - 1] = { char: target[i - 1], match: true };
      i--; j--;
    } else if (j > 0 && dp[i][j] === dp[i - 1][j - 1] + 1) {
      out[i - 1] = { char: target[i - 1], match: false }; // substitution
      i--; j--;
    } else if (dp[i][j] === dp[i - 1][j] + 1) {
      out[i - 1] = { char: target[i - 1], match: false }; // deletion (target char missing in spoken)
      i--;
    } else {
      j--; // insertion (extra char in spoken) — skip, not part of target
    }
  }
  return out;
}

// Word-level Needleman-Wunsch alignment of target ↔ transcript.
// Returns: array of { targetIdx, transcriptIdx } pairs (either may be -1 for gap).
function alignWords(targetWords, transcriptWords) {
  const m = targetWords.length, n = transcriptWords.length;
  const dp = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      const cost = targetWords[i - 1] === transcriptWords[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(dp[i - 1][j - 1] + cost, dp[i - 1][j] + 1, dp[i][j - 1] + 1);
    }
  }
  const out = [];
  let i = m, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      const cost = targetWords[i - 1] === transcriptWords[j - 1] ? 0 : 1;
      if (dp[i][j] === dp[i - 1][j - 1] + cost) {
        out.unshift({ targetIdx: i - 1, transcriptIdx: j - 1 });
        i--; j--; continue;
      }
    }
    if (i > 0 && dp[i][j] === dp[i - 1][j] + 1) {
      out.unshift({ targetIdx: i - 1, transcriptIdx: -1 });
      i--; continue;
    }
    out.unshift({ targetIdx: -1, transcriptIdx: j - 1 });
    j--;
  }
  return out;
}

function score(transcript, target) {
  const targetWords = tokens(target);
  const transcriptWords = tokens(transcript);
  const transcriptNorm = transcriptWords.join(' ');

  const alignment = alignWords(targetWords, transcriptWords);
  const wordScores = [];

  for (const pair of alignment) {
    if (pair.targetIdx === -1) continue; // extra transcript word — silently drop
    const targetW = targetWords[pair.targetIdx];

    if (pair.transcriptIdx === -1) {
      wordScores.push({ word: targetW, status: 'missing', charDiff: null });
      continue;
    }

    const spokenW = transcriptWords[pair.transcriptIdx];
    if (targetW === spokenW) {
      wordScores.push({ word: targetW, status: 'ok', charDiff: null });
      continue;
    }

    const dist = editDistance(targetW, spokenW);
    const ratio = 1 - dist / Math.max(targetW.length, spokenW.length);

    if (ratio >= PRONUNCIATION_WRONG_THRESHOLD) {
      wordScores.push({
        word: targetW,
        status: 'wrong',
        charDiff: computeCharDiff(targetW, spokenW),
      });
    } else {
      wordScores.push({ word: targetW, status: 'missing', charDiff: null });
    }
  }

  // Weighted overall score.
  const verdict = { ok: 1.0, wrong: 0.5, missing: 0.0 };
  let weightedSum = 0, totalWeight = 0;
  for (const w of wordScores) {
    const weight = Math.max(1, Math.ceil(w.word.length / 4));
    weightedSum += weight * verdict[w.status];
    totalWeight += weight;
  }
  const overallScore = totalWeight > 0 ? Math.round((100 * weightedSum) / totalWeight) : 0;

  return { overallScore, wordScores, transcript: transcriptNorm };
}

module.exports = { score, PRONUNCIATION_WRONG_THRESHOLD };
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
npm test
```

Expected: All ~15 tests PASS. If any fail, fix the implementation (NOT the tests) and re-run.

- [ ] **Step 6: Commit**

```bash
git add services/pronunciationScoring.js services/pronunciationScoring.test.js package.json
git commit -m "feat(tutor): pronunciation scoring service (pure fn + unit tests)

Levenshtein word alignment + char-level diff for syllable highlighting.
PRONUNCIATION_WRONG_THRESHOLD = 0.6 separates 'wrong' (charDiff shown)
from 'missing' (too different to be meaningful). Uses node:test
built-in runner — no new deps."
```

---

## Task 2: POST /tutor/pronunciation/sentence route

**Files:**
- Modify: `routes/tutor.js`
- Modify: `controllers/tutor.js`

Working directory: `/Users/davis/Desktop/Personal/language_exchange_backend_application`

- [ ] **Step 1: Add controller handler**

Open `controllers/tutor.js`. Find the existing tutor handlers (search for `getMyMemory` or similar). Add a new handler at the end of the file (before `module.exports`):

```js
/**
 * POST /tutor/pronunciation/sentence
 * Body: { custom?: string, preferWeakWords?: boolean (default true) }
 * Returns: { sentence, level, targetLanguage, ttsAudioBase64 }
 */
exports.generatePronunciationSentence = asyncHandler(async (req, res, next) => {
  const { custom, preferWeakWords = true } = req.body || {};
  const memory = await TutorMemory.findOne({ user: req.user.id });
  if (!memory) return next(new ErrorResponse('Tutor memory not found', 404));

  const level = memory.proficiencyLevel || 'A1';
  const targetLanguage = (memory.targetLanguages && memory.targetLanguages[0]) || 'en';

  let sentence;
  if (typeof custom === 'string' && custom.trim().length > 0) {
    sentence = custom.trim().slice(0, 300); // defensive length cap
  } else {
    // Pull up to 3 weak words to optionally weave in.
    const weakWords = preferWeakWords && Array.isArray(memory.weakAreas)
      ? memory.weakAreas
          .filter(w => w.topic && w.topic.startsWith('pronunciation:'))
          .slice(0, 3)
          .map(w => w.topic.replace(/^pronunciation:/, ''))
      : [];

    const hint = weakWords.length > 0
      ? `If natural, weave in one of these tricky words: ${weakWords.join(', ')}.`
      : '';

    const prompt = `Generate ONE short ${level}-level sentence in ${targetLanguage} for pronunciation practice. Keep it 5-12 words. Prefer spelled-out numbers over digits. Return ONLY the sentence, no quotes, no commentary. ${hint}`;

    const completion = await openaiService.chatCompletion({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      maxTokens: 60,
      temperature: 0.8,
    });
    sentence = (completion?.content || '').trim().replace(/^["']|["']$/g, '');
    if (!sentence) return next(new ErrorResponse('Failed to generate sentence', 502));
  }

  // Generate TTS for the sentence.
  let ttsBuffer;
  try {
    ttsBuffer = await speechService.generateTTS({ text: sentence, language: targetLanguage });
  } catch (err) {
    return next(new ErrorResponse('Failed to generate TTS', 502));
  }
  const ttsAudioBase64 = Buffer.from(ttsBuffer).toString('base64');

  res.json({
    success: true,
    data: { sentence, level, targetLanguage, ttsAudioBase64 },
  });
});
```

Verify these are imported at top of `controllers/tutor.js` (add if missing):
```js
const TutorMemory = require('../models/TutorMemory');
const ErrorResponse = require('../utils/errorResponse');
const asyncHandler = require('../middleware/asyncHandler');
const speechService = require('../services/speechService');
const openaiService = require('../services/openaiService'); // or wherever chatCompletion lives
```

If `openaiService` doesn't have a `chatCompletion` method exposed, look for the existing GPT call pattern in `controllers/tutor.js` (used by tutor chat / story generation) and copy that pattern instead.

- [ ] **Step 2: Wire the route**

Open `routes/tutor.js`. Locate the section where existing routes are defined (e.g., the `router.post('/sessions', ...)` line). Add:

```js
router.post('/pronunciation/sentence', protect, generatePronunciationSentence);
```

Ensure `generatePronunciationSentence` is destructured from the controller import at the top of the file:
```js
const {
  // ...existing handlers,
  generatePronunciationSentence,
} = require('../controllers/tutor');
```

- [ ] **Step 3: Smoke test via curl**

Start the server (`npm run dev`) and in another terminal:

```bash
TOKEN="<paste a real bearer token from a logged-in client>"
curl -X POST http://localhost:5000/api/v1/tutor/pronunciation/sentence \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq '{sentence: .data.sentence, level: .data.level, lang: .data.targetLanguage, ttsLen: (.data.ttsAudioBase64 | length)}'
```

Expected JSON output with a real sentence, level, targetLanguage, and `ttsLen` > 0. If the response is `{"success": false}`, inspect logs for the failing step.

Also test the custom path:
```bash
curl -X POST http://localhost:5000/api/v1/tutor/pronunciation/sentence \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"custom": "Good morning, how are you?"}' | jq '.data.sentence'
```
Expected: `"Good morning, how are you?"` exactly (no GPT call, just TTS).

And 401:
```bash
curl -X POST http://localhost:5000/api/v1/tutor/pronunciation/sentence -H "Content-Type: application/json" -d '{}' -w "%{http_code}\n"
```
Expected: `401`.

- [ ] **Step 4: Commit**

```bash
git add routes/tutor.js controllers/tutor.js
git commit -m "feat(tutor): POST /tutor/pronunciation/sentence

GPT-generated sentence tuned to the user's proficiencyLevel and
targetLanguages[0]. Optionally weaves in existing weakAreas tagged
'pronunciation:*'. Custom-sentence path skips GPT, runs only TTS.
TTS returned inline as base64 to keep response to one round trip."
```

---

## Task 3: POST /tutor/pronunciation/score route

**Files:**
- Modify: `routes/tutor.js`
- Modify: `controllers/tutor.js`

- [ ] **Step 1: Add controller handler**

Append to `controllers/tutor.js`:

```js
const { score: scorePronunciation } = require('../services/pronunciationScoring');

/**
 * POST /tutor/pronunciation/score
 * Multipart: audio file + targetSentence (form field)
 * Returns: { overallScore, transcript, wordScores }
 */
exports.scorePronunciationAttempt = asyncHandler(async (req, res, next) => {
  const file = req.file;
  const { targetSentence } = req.body || {};
  if (!file) return next(new ErrorResponse('audio file is required', 400));
  if (!targetSentence || typeof targetSentence !== 'string') {
    return next(new ErrorResponse('targetSentence is required', 400));
  }

  // Transcribe via existing speechService.
  let transcript;
  try {
    transcript = await speechService.transcribeAudio({
      audioBuffer: file.buffer,
      mimeType: file.mimetype,
      filename: file.originalname || 'pronunciation.aac',
    });
  } catch (err) {
    return next(new ErrorResponse('Transcription failed', 502));
  }

  const result = scorePronunciation(transcript, targetSentence);
  res.json({ success: true, data: result });
});
```

Note: check the actual signature of `speechService.transcribeAudio` in `services/speechService.js` and adjust the call to match. If it takes a different arg shape (e.g., a file path), follow the existing tutor chat pattern in the controller for the `transcribeVoice` handler.

- [ ] **Step 2: Wire the route (reuse existing audio multer config)**

Open `routes/tutor.js`. Find the existing audio multer instance (used by the `/sessions/:id/transcribe` route). Reuse it for the new route:

```js
router.post(
  '/pronunciation/score',
  protect,
  audioUpload.single('audio'), // reuse the same multer instance used elsewhere
  scorePronunciationAttempt
);
```

Ensure `scorePronunciationAttempt` is destructured from the controller import. The multer variable name may be different (`uploadAudio`, `audioMulter`, etc.) — use whichever name the existing `/transcribe` route uses.

- [ ] **Step 3: Smoke test**

Generate a short audio sample of yourself saying "I walked to the park yesterday" (or use a pre-recorded mp3/aac), then:

```bash
TOKEN="<bearer>"
curl -X POST http://localhost:5000/api/v1/tutor/pronunciation/score \
  -H "Authorization: Bearer $TOKEN" \
  -F "audio=@/tmp/sample.aac" \
  -F "targetSentence=I walked to the park yesterday." | jq '.data | {overallScore, transcript, wordCount: (.wordScores | length)}'
```

Expected: `overallScore` between 0-100, `transcript` is your spoken words, `wordCount` ≈ 6.

Test missing-field paths:
```bash
curl -X POST http://localhost:5000/api/v1/tutor/pronunciation/score \
  -H "Authorization: Bearer $TOKEN" \
  -F "targetSentence=Hello" -w "%{http_code}\n"
```
Expected: `400` (no audio).

- [ ] **Step 4: Commit**

```bash
git add routes/tutor.js controllers/tutor.js
git commit -m "feat(tutor): POST /tutor/pronunciation/score

Multipart audio upload → Whisper transcription → pure scoring fn.
Reuses existing tutor audio multer config (25MB cap, audio/* allowlist).
Returns overallScore, transcript, and per-word verdict with charDiff
on 'wrong' words."
```

---

## Task 4: POST /tutor/pronunciation/summary route

**Files:**
- Modify: `routes/tutor.js`
- Modify: `controllers/tutor.js`

- [ ] **Step 1: Add controller handler**

Append to `controllers/tutor.js`:

```js
/**
 * POST /tutor/pronunciation/summary
 * Body: { weakWords: string[] }
 * Upserts each weakWord into TutorMemory.weakAreas with prefix 'pronunciation:'.
 */
exports.submitPronunciationSummary = asyncHandler(async (req, res, next) => {
  const raw = Array.isArray(req.body?.weakWords) ? req.body.weakWords : [];
  const weakWords = raw
    .filter(w => typeof w === 'string' && w.trim().length > 0)
    .slice(0, 5)
    .map(w => w.trim().toLowerCase());

  const memory = await TutorMemory.findOne({ user: req.user.id });
  if (!memory) return next(new ErrorResponse('Tutor memory not found', 404));

  const now = new Date();
  const updated = [];
  for (const word of weakWords) {
    const topic = `pronunciation:${word}`;
    const existing = memory.weakAreas.find(w => w.topic === topic);
    if (existing) {
      existing.frequency = (existing.frequency || 1) + 1;
      existing.lastSeen = now;
    } else {
      memory.weakAreas.push({ topic, frequency: 1, lastSeen: now });
    }
    updated.push(topic);
  }
  await memory.save();

  res.json({ success: true, data: { weakAreasUpdated: updated } });
});
```

- [ ] **Step 2: Wire the route**

In `routes/tutor.js`:

```js
router.post('/pronunciation/summary', protect, submitPronunciationSummary);
```

- [ ] **Step 3: Smoke test**

```bash
TOKEN="<bearer>"
curl -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"weakWords": ["park", "three"]}' | jq
```

Expected: `{ "success": true, "data": { "weakAreasUpdated": ["pronunciation:park", "pronunciation:three"] } }`.

Verify in MongoDB (or run `GET /tutor/me`) that `weakAreas` now contains both entries with `frequency: 1`. Run the same curl again and verify `frequency` becomes `2`.

Empty input:
```bash
curl -X POST http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"weakWords": []}' | jq
```
Expected: `success: true, weakAreasUpdated: []`.

- [ ] **Step 4: Commit**

```bash
git add routes/tutor.js controllers/tutor.js
git commit -m "feat(tutor): POST /tutor/pronunciation/summary

Upserts weak pronunciation words into TutorMemory.weakAreas with
'pronunciation:<word>' topic prefix. Increments frequency on
duplicates so the existing weak-areas memory loop (already pulled
into chat/story system prompts) naturally resurfaces them."
```

---

## Task 5: Flutter TutorService methods

**Files:**
- Modify: `lib/providers/tutor_provider.dart`

Working directory: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

- [ ] **Step 1: Add data classes**

At the top of `lib/providers/tutor_provider.dart` (after existing imports), before the `TutorService` class, add:

```dart
class PronunciationSentence {
  final String sentence;
  final String level;
  final String targetLanguage;
  final String ttsAudioBase64;

  const PronunciationSentence({
    required this.sentence,
    required this.level,
    required this.targetLanguage,
    required this.ttsAudioBase64,
  });

  factory PronunciationSentence.fromJson(Map<String, dynamic> j) =>
      PronunciationSentence(
        sentence: j['sentence']?.toString() ?? '',
        level: j['level']?.toString() ?? 'A1',
        targetLanguage: j['targetLanguage']?.toString() ?? 'en',
        ttsAudioBase64: j['ttsAudioBase64']?.toString() ?? '',
      );
}

class PronunciationWordScore {
  final String word;
  final String status; // 'ok' | 'wrong' | 'missing'
  final List<Map<String, dynamic>>? charDiff;

  const PronunciationWordScore({
    required this.word,
    required this.status,
    this.charDiff,
  });

  factory PronunciationWordScore.fromJson(Map<String, dynamic> j) {
    final cd = j['charDiff'];
    return PronunciationWordScore(
      word: j['word']?.toString() ?? '',
      status: j['status']?.toString() ?? 'missing',
      charDiff: cd is List ? cd.cast<Map<String, dynamic>>() : null,
    );
  }
}

class PronunciationScore {
  final int overallScore;
  final String transcript;
  final List<PronunciationWordScore> wordScores;

  const PronunciationScore({
    required this.overallScore,
    required this.transcript,
    required this.wordScores,
  });

  factory PronunciationScore.fromJson(Map<String, dynamic> j) =>
      PronunciationScore(
        overallScore: (j['overallScore'] as num?)?.toInt() ?? 0,
        transcript: j['transcript']?.toString() ?? '',
        wordScores: ((j['wordScores'] as List?) ?? const [])
            .map((e) => PronunciationWordScore.fromJson(
                  e as Map<String, dynamic>,
                ))
            .toList(),
      );
}
```

- [ ] **Step 2: Add the three TutorService methods**

Inside the `TutorService` class (in the same file), add at the end of the class body, before the closing brace:

```dart
Future<PronunciationSentence> fetchPronunciationSentence({String? custom}) async {
  final body = <String, dynamic>{'preferWeakWords': true};
  if (custom != null && custom.trim().isNotEmpty) body['custom'] = custom.trim();
  final res = await _api.post('tutor/pronunciation/sentence', body: body);
  if (!res.success || res.data == null) {
    throw StateError(res.error ?? 'Failed to fetch sentence');
  }
  return PronunciationSentence.fromJson(_dataObj(res.data));
}

Future<PronunciationScore> scorePronunciationAttempt({
  required String audioFilePath,
  required String targetSentence,
}) async {
  final mime = audioFilePath.toLowerCase().endsWith('.wav')
      ? 'audio/wav'
      : audioFilePath.toLowerCase().endsWith('.m4a')
          ? 'audio/m4a'
          : audioFilePath.toLowerCase().endsWith('.mp3')
              ? 'audio/mpeg'
              : 'audio/aac';
  final multipart = await http.MultipartFile.fromPath(
    'audio',
    audioFilePath,
    contentType: MediaType.parse(mime),
  );
  final res = await _api.postMultipart(
    'tutor/pronunciation/score',
    files: [multipart],
    fields: {'targetSentence': targetSentence},
  );
  if (!res.success || res.data == null) {
    throw StateError(res.error ?? 'Failed to score');
  }
  return PronunciationScore.fromJson(_dataObj(res.data));
}

Future<void> submitPronunciationSummary(List<String> weakWords) async {
  final res = await _api.post(
    'tutor/pronunciation/summary',
    body: {'weakWords': weakWords},
  );
  if (!res.success) {
    throw StateError(res.error ?? 'Failed to submit summary');
  }
}
```

Add these imports at the top of the file if not already present:
```dart
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
```

Inspect `lib/services/tutor_voice_service.dart` for the exact import / multipart pattern already used elsewhere in the codebase — match it.

- [ ] **Step 3: Verify it compiles**

```bash
flutter analyze lib/providers/tutor_provider.dart
```

Expected: `No issues found!` (or only pre-existing info-level lints).

- [ ] **Step 4: Commit**

```bash
git add lib/providers/tutor_provider.dart
git commit -m "feat(tutor): TutorService methods for pronunciation coach

fetchPronunciationSentence, scorePronunciationAttempt,
submitPronunciationSummary. Mirrors the existing tutor service
methods (sendMessage, generateStory, etc.) — multipart audio
upload via ApiClient.postMultipart for /score, JSON for the
other two."
```

---

## Task 6: PronunciationVoiceService + PronunciationController

**Files:**
- Create: `lib/services/pronunciation_voice_service.dart`
- Create: `lib/providers/pronunciation_provider.dart`

- [ ] **Step 1: Create PronunciationVoiceService**

Create `lib/services/pronunciation_voice_service.dart`:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

/// Recorder + player wrapper for the Pronunciation Coach drill.
/// Mirrors the pattern in [TutorVoiceService] but stays scoped to
/// pronunciation drills to avoid entangling the chat recorder lifecycle.
class PronunciationVoiceService {
  FlutterSoundRecorder? _recorder;
  AudioPlayer? _player;
  String? _currentRecordingPath;

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _ensureRecorder() async {
    if (_recorder != null) return;
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<String> startRecording() async {
    await _ensureRecorder();
    final tmp = await getTemporaryDirectory();
    final path =
        '${tmp.path}/pronunciation_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
    _currentRecordingPath = path;
    return path;
  }

  Future<String?> stopRecording() async {
    if (_recorder == null || !_recorder!.isRecording) return _currentRecordingPath;
    await _recorder!.stopRecorder();
    return _currentRecordingPath;
  }

  /// Plays a base64-encoded mp3 (the TTS reference audio).
  Future<void> playReference(String base64Mp3) async {
    _player ??= AudioPlayer();
    final bytes = base64Decode(base64Mp3);
    final tmp = await getTemporaryDirectory();
    final path = '${tmp.path}/ref_${DateTime.now().millisecondsSinceEpoch}.mp3';
    await File(path).writeAsBytes(bytes);
    await _player!.setFilePath(path);
    await _player!.play();
  }

  Future<void> dispose() async {
    try { await _recorder?.closeRecorder(); } catch (e) { debugPrint('[pron] recorder close: $e'); }
    _recorder = null;
    try { await _player?.dispose(); } catch (e) { debugPrint('[pron] player dispose: $e'); }
    _player = null;
  }
}
```

Add at top:
```dart
import 'dart:convert' show base64Decode;
```

- [ ] **Step 2: Create the controller**

Create `lib/providers/pronunciation_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pronunciation_voice_service.dart';
import 'tutor_provider.dart';

enum PronStatus {
  loading,
  ready,
  recording,
  scoring,
  scored,
  summary,
}

class SentenceAttempt {
  final PronunciationSentence sentence;
  final PronunciationScore? lastScore;
  final int attempts;

  const SentenceAttempt({
    required this.sentence,
    this.lastScore,
    this.attempts = 0,
  });

  SentenceAttempt copyWith({
    PronunciationSentence? sentence,
    PronunciationScore? lastScore,
    int? attempts,
  }) => SentenceAttempt(
        sentence: sentence ?? this.sentence,
        lastScore: lastScore ?? this.lastScore,
        attempts: attempts ?? this.attempts,
      );
}

class PronunciationState {
  final PronStatus status;
  final int currentIndex; // 0..4
  final List<SentenceAttempt> session;
  final String? errorMessage;
  final String? recordingPath; // current recording on disk
  final bool customDraftOpen;

  const PronunciationState({
    this.status = PronStatus.loading,
    this.currentIndex = 0,
    this.session = const [],
    this.errorMessage,
    this.recordingPath,
    this.customDraftOpen = false,
  });

  static const int sessionLength = 5;

  PronunciationState copyWith({
    PronStatus? status,
    int? currentIndex,
    List<SentenceAttempt>? session,
    String? errorMessage,
    String? recordingPath,
    bool? customDraftOpen,
    bool clearError = false,
    bool clearRecording = false,
  }) =>
      PronunciationState(
        status: status ?? this.status,
        currentIndex: currentIndex ?? this.currentIndex,
        session: session ?? this.session,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        recordingPath:
            clearRecording ? null : (recordingPath ?? this.recordingPath),
        customDraftOpen: customDraftOpen ?? this.customDraftOpen,
      );

  SentenceAttempt? get current =>
      currentIndex < session.length ? session[currentIndex] : null;
}

class PronunciationController extends StateNotifier<PronunciationState> {
  final TutorService _svc;
  final PronunciationVoiceService _voice;
  PronunciationController(this._svc, this._voice)
      : super(const PronunciationState());

  void _safeSet(PronunciationState next) {
    if (!mounted) return;
    state = next;
  }

  /// Fetches the first sentence and transitions to ready.
  Future<void> init() async {
    _safeSet(state.copyWith(status: PronStatus.loading, clearError: true));
    try {
      final s = await _svc.fetchPronunciationSentence();
      _safeSet(state.copyWith(
        session: [SentenceAttempt(sentence: s)],
        currentIndex: 0,
        status: PronStatus.ready,
      ));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.loading,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> tapRecord() async {
    if (state.status != PronStatus.ready) return;
    final granted = await _voice.requestMicPermission();
    if (!granted) {
      _safeSet(state.copyWith(errorMessage: 'mic_denied'));
      return;
    }
    try {
      final path = await _voice.startRecording();
      _safeSet(state.copyWith(
        status: PronStatus.recording,
        recordingPath: path,
        clearError: true,
      ));
    } catch (e) {
      _safeSet(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> tapStop() async {
    if (state.status != PronStatus.recording) return;
    final path = await _voice.stopRecording();
    final current = state.current;
    if (path == null || current == null) {
      _safeSet(state.copyWith(status: PronStatus.ready));
      return;
    }
    _safeSet(state.copyWith(status: PronStatus.scoring, clearError: true));
    try {
      final score = await _svc.scorePronunciationAttempt(
        audioFilePath: path,
        targetSentence: current.sentence.sentence,
      );
      final updated = [...state.session];
      updated[state.currentIndex] = current.copyWith(
        lastScore: score,
        attempts: current.attempts + 1,
      );
      _safeSet(state.copyWith(session: updated, status: PronStatus.scored));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.scored,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Retry the same sentence — back to ready, keep the score history.
  void retry() {
    if (state.status != PronStatus.scored) return;
    _safeSet(state.copyWith(status: PronStatus.ready, clearError: true));
  }

  /// Advance to next sentence, or transition to summary at the end.
  Future<void> next() async {
    if (state.status != PronStatus.scored) return;
    final isLast = state.currentIndex + 1 >= PronunciationState.sessionLength;
    if (isLast) {
      _safeSet(state.copyWith(status: PronStatus.summary));
      return;
    }
    _safeSet(state.copyWith(status: PronStatus.loading, clearError: true));
    try {
      final next = await _svc.fetchPronunciationSentence();
      final updated = [...state.session, SentenceAttempt(sentence: next)];
      _safeSet(state.copyWith(
        session: updated,
        currentIndex: state.currentIndex + 1,
        status: PronStatus.ready,
      ));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.loading,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Replace current sentence with a user-typed custom one.
  Future<void> submitCustom(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _safeSet(state.copyWith(status: PronStatus.loading, clearError: true));
    try {
      final s = await _svc.fetchPronunciationSentence(custom: trimmed);
      final updated = [...state.session];
      updated[state.currentIndex] = SentenceAttempt(sentence: s);
      _safeSet(state.copyWith(
        session: updated,
        status: PronStatus.ready,
        customDraftOpen: false,
      ));
    } catch (e) {
      _safeSet(state.copyWith(
        status: PronStatus.ready,
        errorMessage: e.toString(),
      ));
    }
  }

  void openCustomDraft() {
    _safeSet(state.copyWith(customDraftOpen: true));
  }

  void closeCustomDraft() {
    _safeSet(state.copyWith(customDraftOpen: false));
  }

  /// Plays the TTS reference for the current sentence.
  Future<void> playReference() async {
    final c = state.current;
    if (c == null || c.sentence.ttsAudioBase64.isEmpty) return;
    try {
      await _voice.playReference(c.sentence.ttsAudioBase64);
    } catch (e) {
      debugPrint('[pron] playReference: $e');
    }
  }

  /// Send the session's weak words to the backend.
  Future<void> finish() async {
    final weakWords = <String>{};
    for (final a in state.session) {
      final s = a.lastScore;
      if (s == null) continue;
      for (final w in s.wordScores) {
        if (w.status == 'wrong' || w.status == 'missing') {
          weakWords.add(w.word);
        }
      }
    }
    try {
      await _svc.submitPronunciationSummary(weakWords.take(5).toList());
    } catch (e) {
      _safeSet(state.copyWith(errorMessage: e.toString()));
      rethrow;
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }
}

final pronunciationVoiceServiceProvider =
    Provider<PronunciationVoiceService>((_) => PronunciationVoiceService());

final pronunciationControllerProvider = StateNotifierProvider.autoDispose<
    PronunciationController, PronunciationState>((ref) {
  return PronunciationController(
    ref.read(tutorServiceProvider),
    ref.read(pronunciationVoiceServiceProvider),
  );
});
```

- [ ] **Step 3: Verify it compiles**

```bash
flutter analyze lib/providers/pronunciation_provider.dart lib/services/pronunciation_voice_service.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/providers/pronunciation_provider.dart lib/services/pronunciation_voice_service.dart
git commit -m "feat(tutor): PronunciationController + voice service

State machine: loading → ready → recording → scoring → scored →
(retry | next | summary). All state writes guarded by _safeSet
mounted check (autoDispose-safe). PronunciationVoiceService
mirrors tutor_voice_service.dart but is scoped to drill flows."
```

---

## Task 7: PronunciationSessionScreen + sentence card widget

**Files:**
- Create: `lib/pages/ai/tutor/pronunciation_session_screen.dart`
- Create: `lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart`

This task delivers states 1-4 (loading, ready, recording, scoring). Task 8 builds the scored-state render. Task 9 builds the summary sheet.

- [ ] **Step 1: Create the screen shell**

Create `lib/pages/ai/tutor/pronunciation_session_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/pronunciation_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/pronunciation_sentence_card.dart';

class PronunciationSessionScreen extends ConsumerStatefulWidget {
  const PronunciationSessionScreen({super.key});

  @override
  ConsumerState<PronunciationSessionScreen> createState() =>
      _PronunciationSessionScreenState();
}

class _PronunciationSessionScreenState
    extends ConsumerState<PronunciationSessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pronunciationControllerProvider.notifier).init();
    });
  }

  Future<bool> _confirmQuit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiTutorPronounceQuitConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pronunciationControllerProvider);
    final ctrl = ref.read(pronunciationControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final isSummary = state.status == PronStatus.summary;

    return PopScope(
      canPop: isSummary,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allow = await _confirmQuit(context);
        if (allow && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.aiTutorPronounceSentenceOf(
            (state.currentIndex + 1).clamp(1, PronunciationState.sessionLength),
            PronunciationState.sessionLength,
          )),
          actions: [
            if (state.status == PronStatus.ready ||
                state.status == PronStatus.scored)
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                tooltip: 'Replay',
                onPressed: () => ctrl.playReference(),
              ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(context, state, ctrl, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PronunciationState state,
      PronunciationController ctrl, AppLocalizations l10n) {
    switch (state.status) {
      case PronStatus.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.aiTutorPronounceLoading),
            ],
          ),
        );
      case PronStatus.ready:
      case PronStatus.recording:
      case PronStatus.scoring:
      case PronStatus.scored:
        final current = state.current;
        if (current == null) return const SizedBox.shrink();
        return PronunciationSentenceCard(
          attempt: current,
          status: state.status,
          customDraftOpen: state.customDraftOpen,
          onRecord: ctrl.tapRecord,
          onStop: ctrl.tapStop,
          onReplay: ctrl.playReference,
          onRetry: ctrl.retry,
          onNext: ctrl.next,
          onOpenCustom: ctrl.openCustomDraft,
          onSubmitCustom: ctrl.submitCustom,
          onCancelCustom: ctrl.closeCustomDraft,
        );
      case PronStatus.summary:
        // Built in Task 9.
        return const Center(child: Text('Summary — TODO Task 9'));
    }
  }
}
```

- [ ] **Step 2: Create the sentence card widget**

Create `lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/pronunciation_provider.dart';
import '../../../../utils/theme_extensions.dart';
import '../../../../core/theme/app_theme.dart';

class PronunciationSentenceCard extends StatefulWidget {
  final SentenceAttempt attempt;
  final PronStatus status;
  final bool customDraftOpen;

  final VoidCallback onRecord;
  final VoidCallback onStop;
  final VoidCallback onReplay;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onOpenCustom;
  final void Function(String) onSubmitCustom;
  final VoidCallback onCancelCustom;

  const PronunciationSentenceCard({
    super.key,
    required this.attempt,
    required this.status,
    required this.customDraftOpen,
    required this.onRecord,
    required this.onStop,
    required this.onReplay,
    required this.onRetry,
    required this.onNext,
    required this.onOpenCustom,
    required this.onSubmitCustom,
    required this.onCancelCustom,
  });

  @override
  State<PronunciationSentenceCard> createState() =>
      _PronunciationSentenceCardState();
}

class _PronunciationSentenceCardState
    extends State<PronunciationSentenceCard> {
  final TextEditingController _customCtrl = TextEditingController();
  String _lastAutoPlayedSentence = '';

  @override
  void didUpdateWidget(covariant PronunciationSentenceCard old) {
    super.didUpdateWidget(old);
    // Auto-play TTS once when a new sentence enters the ready state.
    if (widget.status == PronStatus.ready &&
        widget.attempt.sentence.sentence != _lastAutoPlayedSentence) {
      _lastAutoPlayedSentence = widget.attempt.sentence.sentence;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onReplay());
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sentence text (will get rich render in Task 8 for scored state).
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.attempt.sentence.sentence,
                    textAlign: TextAlign.center,
                    style: context.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.status == PronStatus.ready && !widget.customDraftOpen)
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.aiTutorPronounceUseYourOwn),
              onPressed: widget.onOpenCustom,
            ),
          if (widget.customDraftOpen)
            _buildCustomField(context, l10n),
          const SizedBox(height: 12),
          _buildPrimaryActionRow(context, l10n),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCustomField(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _customCtrl,
            decoration: InputDecoration(
              hintText: l10n.aiTutorPronounceCustomHint,
              border: const OutlineInputBorder(),
            ),
            maxLength: 200,
            maxLines: 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: widget.onCancelCustom, child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => widget.onSubmitCustom(_customCtrl.text),
                child: const Text('Use'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionRow(BuildContext context, AppLocalizations l10n) {
    switch (widget.status) {
      case PronStatus.ready:
        return _BigRoundButton(
          icon: Icons.mic_rounded,
          label: l10n.aiTutorPronounceTapToRecord,
          onPressed: widget.onRecord,
          color: AppColors.primary,
        );
      case PronStatus.recording:
        return _BigRoundButton(
          icon: Icons.stop_rounded,
          label: l10n.aiTutorPronounceTapToStop,
          onPressed: widget.onStop,
          color: Colors.redAccent,
          pulse: true,
        );
      case PronStatus.scoring:
        return Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.aiTutorPronounceTranscribing),
          ],
        );
      case PronStatus.scored:
        // Scored render belongs to Task 8 — show placeholder action row.
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
                onPressed: widget.onRetry,
                child: Text(l10n.aiTutorPronounceTryAgain)),
            FilledButton(
                onPressed: widget.onNext,
                child: Text(l10n.aiTutorPronounceNext)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BigRoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool pulse;

  const _BigRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkResponse(
          onTap: onPressed,
          radius: 60,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: pulse ? 110 : 100,
            height: pulse ? 110 : 100,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: pulse ? 0.5 : 0.3),
                  blurRadius: pulse ? 30 : 16,
                  spreadRadius: pulse ? 8 : 2,
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: context.bodyMedium),
      ],
    );
  }
}
```

- [ ] **Step 3: Add a temporary l10n key so it compiles**

Open `lib/l10n/app_en.arb`. Add these keys (the full set lands in Task 10; just enough to compile here):

```json
"aiTutorPronounceLoading": "Picking a sentence for you…",
"aiTutorPronounceTapToRecord": "Tap to record",
"aiTutorPronounceTapToStop": "Tap to stop",
"aiTutorPronounceTranscribing": "Listening to you…",
"aiTutorPronounceTryAgain": "Try Again",
"aiTutorPronounceNext": "Next",
"aiTutorPronounceUseYourOwn": "Use my own ✏️",
"aiTutorPronounceCustomHint": "Type a sentence you want to practice",
"aiTutorPronounceSentenceOf": "Sentence {current} of {total}",
"@aiTutorPronounceSentenceOf": {
  "placeholders": {
    "current": {"type": "int"},
    "total": {"type": "int"}
  }
},
"aiTutorPronounceQuitConfirm": "Quit drill? Your progress won't be saved.",
```

- [ ] **Step 4: Regenerate l10n and verify compile**

```bash
flutter gen-l10n
flutter analyze lib/pages/ai/tutor/pronunciation_session_screen.dart lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart
```

Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/ai/tutor/pronunciation_session_screen.dart lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart lib/l10n/
git commit -m "feat(tutor): pronunciation session screen + sentence card

States 1-4: loading, ready (with TTS auto-play + custom-sentence
escape hatch), recording (pulsing red button), scoring spinner.
Scored render and summary built in follow-up commits."
```

---

## Task 8: Scored UI — word-level render with char strikethrough

**Files:**
- Modify: `lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart`

This builds the **scored** state — the rich rendering of the sentence with green/yellow/red coloring per word and red strikethrough on bad characters.

- [ ] **Step 1: Build a `_ScoredSentenceText` widget**

Add to `pronunciation_sentence_card.dart` (after the `_BigRoundButton` class):

```dart
class _ScoredSentenceText extends StatelessWidget {
  final List<PronunciationWordScore> wordScores;
  const _ScoredSentenceText({required this.wordScores});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final w in wordScores) _wordSpan(context, w),
      ],
    );
  }

  Widget _wordSpan(BuildContext context, PronunciationWordScore w) {
    Color color;
    switch (w.status) {
      case 'ok':
        color = Colors.green.shade600;
        break;
      case 'wrong':
        color = Colors.orange.shade700;
        break;
      case 'missing':
      default:
        color = Colors.red.shade600;
        break;
    }

    if (w.status != 'wrong' || w.charDiff == null) {
      return Text(
        w.word,
        style: context.headlineSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
    }

    // Render character-by-character with strikethrough on mismatches.
    return RichText(
      text: TextSpan(
        style: context.headlineSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
        children: [
          for (final c in w.charDiff!)
            TextSpan(
              text: c['char']?.toString() ?? '',
              style: (c['match'] == true)
                  ? null
                  : TextStyle(
                      color: Colors.red.shade700,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.red.shade700,
                      decorationThickness: 2,
                    ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add a `_ScoreHeader` widget**

```dart
class _ScoreHeader extends StatelessWidget {
  final int score;
  final String transcript;
  const _ScoreHeader({required this.score, required this.transcript});

  Color _scoreColor() {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 50) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: score.toDouble()),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => Text(
            value.toInt().toString(),
            style: context.displayLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: _scoreColor(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You said: "$transcript"',
          textAlign: TextAlign.center,
          style: context.bodyMedium.copyWith(color: context.textSecondary),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Wire scored state into the build method**

Modify `_buildBody` in `pronunciation_session_screen.dart` so that when status is `scored`, the body shows score header on top + scored text + action row.

Actually, since the sentence card is doing the work, modify the **card's build method**: replace the simple text block at the top of `build()` with a conditional render:

In `pronunciation_sentence_card.dart`, replace the `Expanded` block in `build()`:

```dart
Expanded(
  child: Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.status == PronStatus.scored &&
                widget.attempt.lastScore != null
            ? Column(
                children: [
                  _ScoreHeader(
                    score: widget.attempt.lastScore!.overallScore,
                    transcript: widget.attempt.lastScore!.transcript,
                  ),
                  const SizedBox(height: 24),
                  _ScoredSentenceText(
                    wordScores: widget.attempt.lastScore!.wordScores,
                  ),
                ],
              )
            : Text(
                widget.attempt.sentence.sentence,
                textAlign: TextAlign.center,
                style: context.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
      ),
    ),
  ),
),
```

- [ ] **Step 4: Verify it compiles**

```bash
flutter analyze lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart
```

Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart
git commit -m "feat(tutor): scored UI — word verdicts + char strikethrough

Green/orange/red word coloring by status. 'wrong' words render
char-by-char with red strikethrough on mismatched letters using
the charDiff payload from /score. Score number animates up with
ease-out curve."
```

---

## Task 9: Summary sheet + finish flow

**Files:**
- Create: `lib/pages/ai/tutor/widgets/pronunciation_summary_sheet.dart`
- Modify: `lib/pages/ai/tutor/pronunciation_session_screen.dart`

- [ ] **Step 1: Create the summary sheet**

Create `lib/pages/ai/tutor/widgets/pronunciation_summary_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/pronunciation_provider.dart';
import '../../../../utils/theme_extensions.dart';
import '../../../../core/theme/app_theme.dart';

class PronunciationSummarySheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const PronunciationSummarySheet({super.key, required this.onClose});

  @override
  ConsumerState<PronunciationSummarySheet> createState() =>
      _PronunciationSummarySheetState();
}

class _PronunciationSummarySheetState
    extends ConsumerState<PronunciationSummarySheet> {
  bool _saving = false;
  String? _saveError;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await ref.read(pronunciationControllerProvider.notifier).finish();
      if (mounted) widget.onClose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pronunciationControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    final scores = state.session
        .map((a) => a.lastScore?.overallScore)
        .whereType<int>()
        .toList();
    final avg = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length).round();

    final weak = <String>{};
    for (final a in state.session) {
      final s = a.lastScore;
      if (s == null) continue;
      for (final w in s.wordScores) {
        if (w.status == 'wrong' || w.status == 'missing') weak.add(w.word);
      }
    }
    final weakList = weak.take(3).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.aiTutorPronounceSummaryTitle,
              style: context.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text(l10n.aiTutorPronounceSummaryAvg, style: context.bodyMedium),
          const SizedBox(height: 4),
          Text('$avg', style: context.displayLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: avg >= 80
                ? Colors.green.shade600
                : avg >= 50
                    ? Colors.orange.shade700
                    : Colors.red.shade600,
          )),
          if (weakList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.aiTutorPronounceSummaryWeak, style: context.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final w in weakList)
                  Chip(label: Text(w), backgroundColor: Colors.orange.shade50),
              ],
            ),
          ],
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(_saveError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '…' : l10n.aiTutorPronounceSaveClose),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Replace summary placeholder in the screen**

In `pronunciation_session_screen.dart`, replace the `case PronStatus.summary:` placeholder in `_buildBody`:

```dart
case PronStatus.summary:
  return PronunciationSummarySheet(
    onClose: () {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    },
  );
```

Add the import:
```dart
import 'widgets/pronunciation_summary_sheet.dart';
```

- [ ] **Step 3: Add the summary l10n keys**

Append to `lib/l10n/app_en.arb`:

```json
"aiTutorPronounceSummaryTitle": "Drill complete",
"aiTutorPronounceSummaryAvg": "Average score",
"aiTutorPronounceSummaryWeak": "Words to practice",
"aiTutorPronounceSaveClose": "Save & Close",
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Verify it compiles**

```bash
flutter analyze lib/pages/ai/tutor/widgets/pronunciation_summary_sheet.dart lib/pages/ai/tutor/pronunciation_session_screen.dart
```

Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/ai/tutor/widgets/pronunciation_summary_sheet.dart lib/pages/ai/tutor/pronunciation_session_screen.dart lib/l10n/
git commit -m "feat(tutor): summary sheet + finish flow

End-of-session sheet shows avg score, weakest 1-3 words as chips,
'Save & Close' button that POSTs /pronunciation/summary. Save
errors stay inline on the sheet so user can retry; dropping the
write is acceptable (best-effort persistence)."
```

---

## Task 10: Chip in AI Tools + l10n + persona gating

**Files:**
- Modify: `lib/pages/learning/main/sections/ai_tools_tab.dart`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add the chip label l10n key**

Append to `lib/l10n/app_en.arb`:

```json
"aiTutorChipPronounce": "Pronounce",
"aiTutorPronounceSilent": "We didn't hear anything — try again?",
"aiTutorPronounceMicDenied": "Microphone permission is required to record.",
```

Run `flutter gen-l10n`.

- [ ] **Step 2: Add the 5th chip**

Open `lib/pages/learning/main/sections/ai_tools_tab.dart`. Find the existing chip row (4 chips: Chat / Roleplay / Story / Photo). Locate the helper `_open(...)` and the `_TutorModeChips` row.

Add a new chip entry following the same pattern as the existing 4. Find where the 4 chips are declared in the chip row (look for "Photo" or `Icons.camera_alt`). Add immediately after:

```dart
_TutorModeChip(
  emoji: '🎙️',
  label: AppLocalizations.of(context)!.aiTutorChipPronounce,
  onTap: () => _open(context, ref, const PronunciationSessionScreen()),
),
```

If the actual structure uses a list, follow that pattern. Match the exact widget type and prop names from the existing chips — don't invent.

Import at the top:
```dart
import '../../../ai/tutor/pronunciation_session_screen.dart';
```

- [ ] **Step 3: Verify persona-picker gating works**

The existing `_open(...)` function should already check `memory.persona` and bounce through `PersonaPickerScreen(destinationAfterPick: ...)` when null. Verify by reading the function body — no change needed if the pattern already covers the new screen. If the function takes a `Widget` and pushes it directly, we get the bounce for free.

- [ ] **Step 4: Visual check on simulator**

```bash
flutter run -d "iPhone 15 Pro"
```

Tap the AI Study tab → confirm 5 chips fit in the row (squeeze acceptable on iPhone SE). If text clips badly, change the layout to a 2-row wrap (3 + 2):

If the chip row uses `Row(children: [...].map((c) => Expanded(child: c)))`, wrap with `Wrap(spacing: 8, children: [...])` and remove `Expanded`.

Tap "Pronounce" → should hit persona picker if no persona is set, otherwise land on the pronunciation screen with sentence #1 loading.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/learning/main/sections/ai_tools_tab.dart lib/l10n/
git commit -m "feat(tutor): expose Pronunciation Coach chip in AI Tools

5th chip in the tutor mode row. Persona-picker bounce works
through the existing _open helper — no extra wiring needed.
Falls back to a 2-row wrap if 5 doesn't fit on the smallest
viewport (not changed by default; revisit if SE testing
shows clipping)."
```

---

## Task 11: Manual two-device smoke test

**Files:** none (manual verification)

This isn't a commit — it's the final acceptance test before declaring the feature shippable. Spec section 9 lists this as required because real audio, real OpenAI, and real microphone behavior can't be tested in CI.

- [ ] **Step 1: Deploy backend**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git push -u origin feat/step11-pronunciation-coach
```

Open a PR; merge to main (auto-deploy will publish).

- [ ] **Step 2: Build and run Flutter on a real device**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter run -d "<your physical iPhone or Android>"
```

- [ ] **Step 3: Run through the happy path**

1. Open the app → AI Study tab (now tab #1).
2. Tap "🎙️ Pronounce" chip.
3. (If first time) Persona picker appears → pick any persona.
4. Sentence loads, TTS auto-plays. Sentence is in your target language, A1/A2-ish.
5. Tap mic, speak the sentence accurately. Tap stop.
6. Score appears: word-by-word green colors, overall ≥ 80.
7. Tap "Next." New sentence loads, TTS auto-plays.
8. On sentence 3, **deliberately mispronounce one word.** Score shows the wrong word in orange with red strikethroughs on the bad characters.
9. Tap "Try Again." Re-record. Score updates.
10. After sentence 5, summary sheet appears: avg score, 1-3 weak words.
11. Tap "Save & Close." Sheet dismisses, back to AI Tools.
12. Verify via `GET /tutor/me` (or by reopening) that `weakAreas` now contains `pronunciation:<word>` entries.

- [ ] **Step 4: Run through edge cases**

1. **Silence test:** Tap mic, say nothing for 3s, tap stop. Score should be 0, all words `missing`, copy says "didn't hear anything."
2. **Custom sentence:** Tap "Use my own ✏️", type "I love pronunciation drills.", submit. TTS plays your sentence. Record it.
3. **Mid-session quit:** Start a drill, do sentence 1 + 2, tap back. Confirm dialog appears. Tap "Yes." Verify no `weakAreas` were written (`GET /tutor/me`).
4. **Mic permission denied:** Reset mic permission in iOS Settings → tap record → should see permission prompt → deny → inline banner appears with "Open Settings" link.
5. **Background mid-session:** Start a drill, swipe away the app, reopen. App should return to the AI Tools tab (session is fresh, not resumed). Acceptable behavior.

- [ ] **Step 5: Mark feature shipped**

If all happy-path + edge cases pass, the feature is ready. Open the Flutter PR:

```bash
gh pr create --title "feat(tutor): Pronunciation Coach (Step 11)" --body "$(cat <<'EOF'
## Summary
- Adds 🎙️ Pronounce drill to AI Study (chip below tutor hero)
- 5-sentence session with TTS reference + Whisper-based scoring
- Word-level verdict + char-diff syllable highlighting on wrong words
- Weak words flow back into TutorMemory.weakAreas

## Test plan
- [x] Happy path: 5 clean sentences → score ≥ 80 each → summary saves
- [x] Mispronounced word renders orange with red strikethroughs on bad chars
- [x] Silent recording → 0 score, all missing
- [x] Custom sentence flow
- [x] Mid-session quit confirm dialog
- [x] Mic permission denied path
- [ ] Translations for 18 non-English locales (deferred; English fallback works)

Specs: docs/superpowers/specs/2026-05-13-pronunciation-coach-design.md
Plan:  docs/superpowers/plans/2026-05-13-pronunciation-coach-plan.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## What's deferred (called out in spec §11)

- Phoneme-level scoring (would require Azure Pronunciation Assessment / gpt-4o-audio)
- `PronunciationAttempt` collection + progress dashboard
- Daily-plan integration (`tutor_pronunciation` task type)
- Offline mode
- Live-streaming Whisper
- Translating the ~18 ARB keys into the 18 non-English locales (English fallback works)
- Backend integration tests for the 3 routes (manual smoke is the substitute; add jest + supertest if desired later)

---

## Total estimated effort

- **Backend:** 4 commits, ~4-6 hours including OpenAI integration tweaks
- **Flutter:** 6 commits, ~8-12 hours including the scored UI render
- **Manual smoke:** 30-60 minutes
- **Total:** ~2-3 focused days
