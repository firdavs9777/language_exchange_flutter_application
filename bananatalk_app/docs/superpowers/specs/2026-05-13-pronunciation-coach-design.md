# Pronunciation Coach — Design Spec

**Date:** 2026-05-13
**Status:** Brainstorm complete; awaiting user review before plan
**Branch (intended):** `feat/step11-pronunciation-coach` on both Flutter + backend repos
**Slot:** AI Study → 5th tutor chip (🎙️ Pronounce) below the tutor hero

---

## 1. Goal

Add a Pronunciation Coach drill to the AI Study tab so users can practice
saying a target-language sentence and get word-level feedback on what they
got wrong. The feature must:

- Reuse the existing Whisper STT plumbing (no new vendor).
- Slot cleanly into the existing tutor surface (chip below hero, persona
  gating, daily-plan friendly).
- Feed weak words back into `TutorMemory.weakAreas` so the chat / story
  modes naturally reinforce them on the next session.
- Ship in days, not weeks.

## 2. UX summary

The user opens the **🎙️ Pronounce** chip from the AI Tools row. After a
persona-picker bounce (if persona is unset, same pattern as the other
chips), they land on a 5-sentence drill. For each sentence:

1. A target sentence appears, level-tuned to the user's `proficiencyLevel`
   and biased toward existing weak words.
2. TTS auto-plays once. The user can tap 🔊 to replay.
3. The user taps the big mic button, speaks, taps stop.
4. The backend transcribes (Whisper) and scores word-by-word. Wrong words
   render with red strikethroughs on the bad characters; the score
   animates up.
5. The user taps "Try Again" (re-record same sentence) or "Next."

After sentence 5 a bottom sheet shows an average score, the weakest 1-3
words, and a "Save & Close" button. Tapping save POSTs the weak words to
the backend, which folds them into `TutorMemory.weakAreas` with a
`pronunciation:` prefix.

There's a "Use my own ✏️" escape hatch on the **ready** state that lets
the user type or paste their own target sentence (e.g., a phrase from a
class). The backend skips GPT generation in that path and just runs TTS.

## 3. Architectural decisions (locked during brainstorming)

| # | Decision | Reasoning |
|---|---|---|
| 1 | **Hybrid sentence source** (AI-generated default + user-typed escape hatch) | Matches Story / Image-Vocab feel; covers "I have a specific phrase I want to nail" without forcing content authoring. |
| 2 | **Word-level diff scoring + char-level highlighting** on wrong words | Cheapest path that reuses Whisper; honest "spelling accuracy" framing in copy avoids the phoneme-accuracy claim we can't back. |
| 3 | **Session of 5 sentences with retry, end-of-session summary** | Turns a tool into a learning session, maps to a `tutor_pronunciation` daily-plan task type later. |
| 4 | **Auto-play TTS on sentence load + replay button** | Removes the "I don't know what it should sound like" failure mode. TTS cost negligible (~$0.006 / session). |
| 5 | **Roll low-scoring words into `TutorMemory.weakAreas`** (no new collection) | Reuses existing memory loop — chat / story already pull `weakAreas` into their system prompts, so pronunciation problems naturally resurface. YAGNI on a full attempt log until we want a progress dashboard. |
| 6 | **Single-shot stateless backend (3 endpoints, no session collection)** | A drill isn't a conversation; server-side session state would be over-engineering. Each call is independent and replayable. |

## 4. File layout

### Flutter — `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

**Create:**
- `lib/pages/ai/tutor/pronunciation_session_screen.dart`
  Full-screen drill UX. Holds the 6-state state machine described in
  section 6. Wires `PronunciationController` via Riverpod.
- `lib/pages/ai/tutor/widgets/pronunciation_sentence_card.dart`
  Single-sentence widget: target text, TTS button, auto-play hook on
  first paint, scored word-by-word render.
- `lib/pages/ai/tutor/widgets/pronunciation_summary_sheet.dart`
  End-of-session bottom sheet: avg score, weakest 1-3 words, "Save &
  Close" CTA.
- `lib/providers/pronunciation_provider.dart`
  `PronunciationController extends StateNotifier<PronunciationState>` with
  `autoDispose`. **Must follow the `_safeSet` mounted-guard pattern we
  just landed in `tutor_provider.dart`** so dispose-mid-await doesn't
  trip a defunct-element assertion.

**Modify:**
- `lib/services/tutor_service.dart` (or `lib/providers/tutor_provider.dart`
  where `TutorService` lives today)
  Add three methods: `fetchSentence({level, lang, weakWords, custom})`,
  `scoreAttempt(audioFilePath, targetSentence)`, `submitSummary(weakWords)`.
- `lib/pages/learning/main/sections/ai_tools_tab.dart`
  Add 5th chip "🎙️ Pronounce" to the row, routing via `_open(...)` to
  `PronunciationSessionScreen` (same persona-picker bounce as the other
  chips).
- `lib/l10n/app_en.arb`
  New keys under the `aiTutorPronounce*` prefix:
  `aiTutorChipPronounce`, `aiTutorPronounceLoading`,
  `aiTutorPronounceTapToRecord`, `aiTutorPronounceTapToStop`,
  `aiTutorPronounceTranscribing`, `aiTutorPronounceTryAgain`,
  `aiTutorPronounceNext`, `aiTutorPronounceUseYourOwn`,
  `aiTutorPronounceCustomHint`, `aiTutorPronounceSentenceOf`
  (with placeholders), `aiTutorPronounceSummaryTitle`,
  `aiTutorPronounceSummaryAvg`, `aiTutorPronounceSummaryWeak`,
  `aiTutorPronounceSaveClose`, `aiTutorPronounceSilent`,
  `aiTutorPronounceMicDenied`, `aiTutorPronounceQuitConfirm`.
  Locale fallback applies for the 18 non-English locales (translate later).

### Backend — `/Users/davis/Desktop/Personal/language_exchange_backend_application`

**Create:**
- `services/pronunciationScoring.js`
  Pure function module. Exports `score(transcript, target)` returning
  `{ overallScore, wordScores, transcript }`. No I/O, no OpenAI — fully
  unit-testable.

**Modify:**
- `routes/tutor.js`
  Add three routes under existing `protect` middleware:
  - `POST /tutor/pronunciation/sentence` (JSON)
  - `POST /tutor/pronunciation/score` (multipart audio, reuse existing
    multer audio config — 25MB cap, audio/* mime types)
  - `POST /tutor/pronunciation/summary` (JSON)
- `controllers/tutor.js`
  Add `generatePronunciationSentence`, `scorePronunciationAttempt`,
  `submitPronunciationSummary` handlers.
- `services/speechService.js`
  No change — existing `generateTTS` and `transcribeAudio` cover both
  needs.

## 5. API contracts

### `POST /tutor/pronunciation/sentence`

**Auth:** `protect` (Bearer)
**Body:**
```json
{
  "custom": null,
  "preferWeakWords": true
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "sentence": "I walked to the park yesterday.",
    "level": "A1",
    "targetLanguage": "en",
    "ttsAudioBase64": "..."
  }
}
```

- `level` and `targetLanguage` are read from `TutorMemory`
  (`proficiencyLevel`, `targetLanguages[0]`).
- `preferWeakWords: true` (default) → the prompt asks GPT to weave in 1
  of the user's existing `weakAreas` words when possible.
- `custom: "<text>"` → server skips GPT, runs only TTS.
- `ttsAudioBase64` is the inline mp3 (~30-80KB for a typical sentence).
  Switch to a signed-URL upload path if response sizes grow.

**Errors:**
- 401 unauth → existing `protect` returns it
- 502 if OpenAI returns non-success on chat or TTS — surface a friendly
  retry message client-side

### `POST /tutor/pronunciation/score`

**Auth:** `protect` (Bearer)
**Content-Type:** `multipart/form-data`
**Fields:**
- `audio` — file (audio/mpeg, audio/m4a, audio/wav, audio/webm, audio/flac)
- `targetSentence` — string (the sentence the user was meant to say)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "overallScore": 78,
    "transcript": "I walked to the par yesterday",
    "wordScores": [
      { "word": "I",         "status": "ok",      "charDiff": null },
      { "word": "walked",    "status": "ok",      "charDiff": null },
      { "word": "to",        "status": "ok",      "charDiff": null },
      { "word": "the",       "status": "ok",      "charDiff": null },
      { "word": "park",      "status": "wrong",
        "charDiff": [
          {"char":"p","match":true},
          {"char":"a","match":true},
          {"char":"r","match":true},
          {"char":"k","match":false}
        ]},
      { "word": "yesterday", "status": "ok",      "charDiff": null }
    ]
  }
}
```

- `status` is one of `ok | wrong | missing`. Extra words spoken by the
  user are silently dropped (never penalized).
- `charDiff` is `null` for `ok` and `missing` statuses; present only on
  `wrong` so the client can render the per-character strikethrough.
- **`missing` is intentionally overloaded** — it covers both literal
  omissions (no aligned transcript word) and severe substitutions
  (ratio < 0.6, e.g. "doodle" for "park"). The product call: when the
  spoken word is *that* different from the target, a character-level
  diff is meaningless noise, so we treat it the same as silence.
  The summary copy ("We didn't hear …") is conditional on the
  *whole-transcript* empty case, not per-word.

**Errors:**
- 401 unauth
- 400 missing audio file or `targetSentence`
- 413 audio > 25MB (multer enforces)
- 502 if Whisper call fails

### `POST /tutor/pronunciation/summary`

**Auth:** `protect` (Bearer)
**Body:**
```json
{ "weakWords": ["park", "three"] }
```

**Response 200:**
```json
{
  "success": true,
  "data": { "weakAreasUpdated": ["pronunciation:park", "pronunciation:three"] }
}
```

- For each `weakWord`, upsert into `TutorMemory.weakAreas` with topic
  `pronunciation:<word>`, increment `frequency`, update `lastSeen`.
- Cap input to 5 words / call (defensive limit).
- Always returns success; idempotent.

## 6. Flutter state machine

`PronunciationController` is a `StateNotifier<PronunciationState>` with
`autoDispose`. The state shape:

```dart
enum PronStatus {
  loading,    // fetching sentence + TTS
  ready,      // waiting for user to record
  recording,  // mic is active
  scoring,    // audio sent, awaiting transcript + score
  scored,     // showing word-level breakdown
  summary,    // 5/5 done, sheet visible
}

class PronunciationState {
  final PronStatus status;
  final int currentIndex;              // 0..4
  final List<SentenceAttempt> session; // up to 5 entries
  final String? errorMessage;
  final String? customSentenceDraft;   // null unless user opened the "Use my own" field
}

class SentenceAttempt {
  final String sentence;
  final String targetLanguage;
  final String level;
  final String? ttsAudioPath;          // local file for replay
  final ScoreResult? lastScore;        // null until first attempt
  final int attempts;                  // count of records for this sentence
}
```

**Methods (every state write goes through `_safeSet` with `mounted`
check):**
- `init()` — `loading` → fetch sentence #1 → `ready`
- `tapRecord()` — `ready` → start `flutter_sound` recorder → `recording`
- `tapStop()` — `recording` → stop recorder → `scoring` → POST `/score` → `scored`
  on success. On failure, transition to `scored` with `lastScore == null`
  and `errorMessage` set; the UI renders an inline retry button that
  re-fires `/score` without re-recording.
- `retry()` — `scored` → bump `attempts` → `ready` (same sentence)
- `next()` — `scored` → `currentIndex++` → if 5, transition to `summary`;
  else fetch next sentence → `ready`
- `submitCustom(text)` — `ready` → POST `/sentence` with `{custom: text}` → `ready` with new sentence
- `finish()` — `summary` → aggregate weakWords from session → POST
  `/summary` → pop back

## 7. Scoring algorithm

Implemented in `services/pronunciationScoring.js` as a pure function.

**Inputs:** `transcript: string`, `target: string`
**Output:** `{ overallScore, wordScores, transcript }`

**Steps:**

1. **Normalize** both: lowercase, strip punctuation
   (`s/[^\p{L}\p{N}\s']//gu`), collapse whitespace, split into
   word arrays.

2. **Sequence-align** target ↔ transcript using Levenshtein edit distance
   over the *word arrays* (Needleman-Wunsch style). Each operation is
   match / substitute / insert / delete on whole words.

3. **For each aligned target word:**
   ```
   let ratio = 1 - (charLevenshtein(target, transcriptWord) / max(len_target, len_transcript))
   if no aligned transcript word          → status = "missing"
   else if ratio == 1                     → status = "ok",      charDiff = null
   else if ratio >= 0.6                   → status = "wrong",   charDiff = computeCharDiff(...)
   else                                   → status = "missing"
   ```
   Threshold `0.6` lives as a single named constant for tuning.

4. **`computeCharDiff(target, spoken)`** — character-level Levenshtein
   alignment, emit `{char: <target char>, match: bool}[]`. For
   substitution / insertion positions, mark `match: false`.

5. **`overallScore`** — weighted average:
   ```
   verdictScore = { ok: 1.0, wrong: 0.5, missing: 0.0 }
   weight(word) = max(1, ceil(word.length / 4))
   overallScore = round(100 * Σ(weight · verdictScore) / Σ(weight))
   ```

**Known v1 limitations** (called out so reviewers don't flag as bugs):
- Contractions: "I'll" vs "I will" — punctuation strip turns "I'll" into
  "ill," not "I" + "will." Acceptable for v1.
- Homophones: Whisper transcribes phonetically; "their / there / they're"
  may be scored as ok even if the user said the wrong one. Acceptable.
- Numerals: Whisper may transcribe "3" or "three" depending on context,
  and the comparison is naive — `"3"` vs `"three"` will score wrong.
  The sentence generator prefers spelled-out numbers at low levels to
  sidestep this.
- This is **spelling accuracy**, not phonetic accuracy. UI copy will say
  "Pronunciation accuracy" since that's still the user-facing concept,
  but the spec is honest about the underlying signal.

## 8. Error handling

| Failure mode | UI surface | Recovery |
|---|---|---|
| Mic permission denied | banner on first record tap | "Open Settings" CTA via `permission_handler` |
| `/sentence` network fail | toast + retry button on loading state | retry button re-fires |
| `/score` network fail | inline error on `scoring → scored` transition | retry button (audio still on disk) |
| Whisper transcript empty | score 0, all `missing`, copy: "We didn't hear anything" | "Try Again" |
| OpenAI 429 | toast "Quiet down — too many attempts" | 30s soft cooldown on the record button |
| `/summary` fails on finish | inline error on summary sheet, save stays enabled | retry; if user dismisses, drop the write (best-effort) |
| App backgrounded mid-drill | session is in-memory only; resuming starts fresh | acceptable; no persistence in v1 |
| Audio > 25MB (multer cap) | impossible in normal use (5-15s sentences); guard returns 413 | — |
| Mid-session back press | confirm dialog "Quit drill?" on sentence 1-4; pop freely on summary | — |

## 9. Testing strategy

### Backend
- **`services/pronunciationScoring.test.js`** — pure-function unit tests
  (~15 cases). Runs in <100ms.
  - Exact match → score 100
  - All-wrong nonsense → score 0
  - One char off (`park` → `par`) → ratio 0.75, status `wrong`, charDiff
    has `k:false`
  - Completely different word (`park` → `doodle`) → status `missing`
  - Silent transcript (empty string) → score 0, all `missing`
  - Word reordering → alignment still picks up matches
  - Length weighting: 1 short word wrong vs 1 long word wrong
  - Threshold boundary: ratio = 0.55 vs 0.65
  - Unicode (non-Latin scripts: KO/JA/ZH) — tokenization works
  - Multiple-word substitution
- **`routes/tutor.pronunciation.test.js`** — integration tests with
  `speechService` mocked.
  - 401 unauth on all three routes
  - `/sentence` happy path with `custom` and without
  - `/sentence` `preferWeakWords` injects weak word into prompt
  - `/score` happy path with fixture audio + mocked Whisper response
  - `/score` rejects without audio file
  - `/summary` upserts `weakAreas` with `pronunciation:` prefix +
    frequency increment

### Flutter
- **`pronunciation_session_screen_test.dart`** — widget tests on the
  state machine.
  - Transitions: loading → ready → recording → scored → next → summary
  - Custom-sentence flow opens TextField, submits, returns to ready with
    new sentence
  - Back during sentences 1-4 shows confirm dialog
  - `mounted` guard verified: dispose mid-fetch doesn't throw
- **Mocked layer:** `flutter_sound` recorder is wrapped in a thin
  service so widget tests can stub it.

### Not tested (intentional)
- Real OpenAI calls (cost + flakiness)
- Real microphone recording (platform-dependent)
- TTS audio playback (CI audio is brittle)
- Real end-to-end on a device — that's the **two-device manual smoke
  test** that wraps up Step 11.

## 10. Cost & latency ballpark

Per 5-sentence session:

| Op | Count | Unit cost | Total |
|---|---|---|---|
| GPT sentence generation | 4-5 (one cached if "Use my own") | ~$0.0003 each | ~$0.0015 |
| TTS (mp3, ~80 chars/sentence) | 5 | ~$0.0012 each | ~$0.006 |
| Whisper (5-15s audio) | 5+ (retries) | ~$0.0006/min | ~$0.001 |
| **Total per session** | | | **~$0.009** |

End-to-end latency per sentence:
- Sentence + TTS: ~2-4s (GPT) + ~1-2s (TTS) = ~3-6s
- Score (record + Whisper): ~1-3s
- Total session: ~6 sentences × ~6s = ~36s of network + however long the
  user takes to speak

## 11. Out of scope (v1)

- Pronunciation Progress dashboard (charts, hardest words rollup) —
  needs the `PronunciationAttempt` collection we deliberately skipped
- Phoneme-level scoring (would require Azure Pronunciation Assessment
  or gpt-4o-audio)
- Daily-plan integration (a `tutor_pronunciation` task type) — add as
  Step 12 after the feature proves out
- Offline mode (cached sentences for use without network)
- Live-streaming Whisper (single-shot upload only for v1)
- Group / shared sessions

## 12. Implementation order (preview for plan)

The implementation plan should follow this order to keep each commit
shippable:

1. Backend: `pronunciationScoring.js` + unit tests (no API yet)
2. Backend: 3 routes + controller handlers + integration tests
3. Flutter: `PronunciationController` + service methods (no UI)
4. Flutter: `PronunciationSessionScreen` skeleton + sentence card widget
5. Flutter: scoring UI (char strikethrough render, score animation)
6. Flutter: summary sheet + save flow
7. Flutter: chip in `ai_tools_tab.dart` + l10n keys + persona gating
8. Manual two-device smoke test
9. Backfill: translate ARB keys for the 18 non-English locales (or
   leave on template fallback for v1)

Expected size: ~9 commits, ~3-4 days of focused work.

---

## Appendix A — Why we picked the 0.6 threshold

| Pair | Char Lev | Ratio | Verdict |
|---|---|---|---|
| `park` / `park` | 0 | 1.00 | ok |
| `park` / `par` | 1 | 0.75 | wrong |
| `park` / `pak` | 1 | 0.75 | wrong |
| `park` / `bark` | 1 | 0.75 | wrong |
| `park` / `mark` | 1 | 0.75 | wrong |
| `park` / `pop` | 3 | 0.25 | missing |
| `park` / `doodle` | 5 | 0.17 | missing |

The 0.6 line cleanly separates "real attempt, one or two sounds off"
from "totally different word." It's a single named constant
(`PRONUNCIATION_WRONG_THRESHOLD`) in the scoring module — tunable in
one place after we see real data.

## Appendix B — Reused infrastructure

| Need | Existing infrastructure |
|---|---|
| Multipart audio upload | `ApiClient.postMultipart()` + `routes/tutor.js` multer config |
| Whisper transcription | `services/speechService.js#transcribeAudio` |
| TTS generation | `services/speechService.js#generateTTS` |
| Persona gating | `PersonaPickerScreen(destinationAfterPick: ...)` pattern |
| Disposed-StateNotifier safety | `_safeSet` pattern from `tutor_provider.dart` |
| Weak-areas memory loop | `TutorMemory.weakAreas` (already pulled into chat / story system prompts) |
| L10n convention | `aiTutor*` prefix in `app_en.arb` |

This spec is dense by design — the implementation plan will translate it
into ~9 bite-sized commits.
