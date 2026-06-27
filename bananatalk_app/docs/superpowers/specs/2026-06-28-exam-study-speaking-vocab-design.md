# Exam Study — Speaking + Vocabulary design spec

**Date:** 2026-06-28
**Status:** approved, ready for implementation planning
**Companion to:** `2026-06-27-exam-study-app.md` (the Phase 1 plan that shipped Chunks A–F)
**Goal:** Add the two remaining content surfaces for the Exam Study feature: **Speaking** (Part 1 / 2 / 3 per exam) and **Vocabulary** (browse + practice, level + topic filtered). Both ship across IELTS, DELE, and TOPIK.

## Locked decisions

| Question | Decision |
|---|---|
| Speaking structure | 3 sub-sections per exam (IELTS Part 1/2/3 pattern; DELE Monólogo / Diálogo / Conversación; TOPIK 짧은 답변 / 긴 답변 / 토론) |
| Vocabulary mode | Browse (word + def + example + TTS) **+** Practice (10-Q MC quiz) |
| Vocabulary scope | All 3 languages — English / Spanish / Korean |
| Korean level scale | **CEFR everywhere** (A1–C2); the Korean level picker dual-labels (e.g. "B1 / TOPIK 3–4") |
| New infra needed | **None.** Backend already has Whisper STT, TTS, audio storage, multer audio upload, AI evaluation. App already has `flutter_sound`, `audio_session`, `just_audio` in pubspec. |

## Existing infrastructure leveraged

This is the most important point of the spec. We are **wiring exam-study into existing pipelines**, not building new audio infrastructure:

| Capability | Where | Reuse for |
|---|---|---|
| Audio upload + multer | `backend/routes/speech.js` | Speaking submit endpoint |
| Whisper STT | `backend/services/speechService.js` `speechToText()` | Transcribe speaking responses |
| TTS audio + caching | `backend/services/speechService.js` `generateTTS()` | Prompt-listening on speaking + vocabulary browse |
| S3 audio storage | `backend/services/storageService.js` | Optional persistence of user submissions for review |
| AI essay-style eval | `backend/services/examEvaluationService.js` (from Chunk D) | Speaking eval reuses with a speaking-specific rubric |
| Async eval polling | `EvaluationJob` model + `/evaluations/:id` (from Chunk D) | Speaking results use the same poll pattern |
| Audio recording | `flutter_sound: ^9.2.13` (already in pubspec) | App speaking-editor screen |

---

# Part A — Speaking section

## Data model

### `ExamSection.sectionType` — extend enum

Add three values to the existing enum:

```js
enum: [
  'reading',
  'writing', 'writing-task-1', 'writing-task-2',
  'speaking', // legacy
  'speaking-part-1', 'speaking-part-2', 'speaking-part-3',
  'listening',
  'vocabulary',
],
```

Same widening on `ExamType.sections`. `UserExamProgress.sectionScores` is already a `Map<String, SectionScore>` (from Chunk F) so no schema change needed there — new keys land automatically.

### `ExamQuestion`

No schema change. Speaking prompts use `questionType: 'speaking-prompt'` (already in the enum) plus the existing `topic` field.

## Backend endpoints

### Submit a speaking answer — dedicated audio endpoint

Mixing JSON essays and multipart audio under one route makes the middleware stack messy (multer + json body parsers fighting). Cleaner: a sibling endpoint that only handles speaking submissions.

**New:** `POST /api/v1/exam-study/questions/:questionId/submit-audio` (multipart/form-data, field name `audio`)

The existing `POST /submit-answer` still handles MC + essay (JSON). It returns `400 USE_AUDIO_ENDPOINT` if called for a `speaking-prompt` question — points client at the right route. (Replaces the current `501 NOT_IMPLEMENTED` for speaking.)

Flow for `/submit-audio`:

1. Multer middleware (`multer().single('audio')`, 25 MB limit, audio mime-type filter — same config as existing `speech.js`) parses the upload
2. Validate `questionType === 'speaking-prompt'`; reject 400 otherwise
3. Validate audio: ≥2 seconds (compute from buffer length + bitrate header), ≤25 MB
4. Create an `EvaluationJob` with `status: 'pending'`; if `SPEECH_PERSIST_AUDIO` is true, upload to S3 first and store the URL on the job (otherwise just pass the buffer in-memory)
5. Fire-and-forget background eval; return `202 { pollUrl }` — identical envelope to essay
6. Background eval (`_evaluateSpeakingInBackground`):
   - `speechService.transcribeAudio(audioBuffer, { language })` → transcript string
   - `examEvaluationService.evaluateSpeaking({ transcript, rubric, targetBand })` (new helper) → score / feedback / strengths / improvements
   - Persist `transcript` on the EvaluationJob so the result screen shows "what we heard you say"
   - Same progress-bump via `_bumpProgress`

### New field on `EvaluationJob`

```js
transcript: String,  // populated for speaking jobs after Whisper STT
audioUrl: String,    // optional — S3 URL for the user's recording
```

### New helper: `examEvaluationService.evaluateSpeaking`

Mirror of `evaluateEssay` with a speaking rubric prompt: "fluency, pronunciation cues, vocabulary, grammar, task response". Same json-mode OpenAI call, same deterministic stub fallback when `OPENAI_API_KEY` is unset.

### Audio persistence

**Default: do not persist audio after evaluation.** Process the buffer in-memory through Whisper, write the transcript, drop the audio. Saves storage, keeps PII risk minimal, and the user can re-record.

Add a feature flag in `aiConfig.js`: `SPEECH_PERSIST_AUDIO = false`. When true (future iteration for "review your past answers" UX), background worker uploads to S3 via `storageService` first, stores the URL on the job.

## App flow

```
Dashboard → Speaking — Part 1 tile → Topic picker → Speaking practice screen
                                                          ↓
                                                  [Listen to prompt]   ← uses /speech/tts
                                                  [Record button]      ← flutter_sound
                                                          ↓
                                                  multipart POST → 202 + pollUrl
                                                          ↓
                                                  Evaluation result screen
                                                  (polls /evaluations/:id every 3s)
                                                          ↓
                                                  Score + feedback +
                                                  transcript ("what we heard")
```

## New / modified files (app)

- `lib/pages/learning/exam_study/speaking_practice_screen.dart` — new screen with recorder + waveform + timer + Listen-to-prompt button
- `lib/pages/learning/exam_study/widgets/audio_recorder.dart` — encapsulates `flutter_sound` lifecycle (init/record/stop/dispose) so it's testable in isolation
- `lib/pages/learning/exam_study/evaluation_result_screen.dart` — extend to render the transcript section when present
- `lib/providers/provider_models/exam/evaluation_status.dart` — add optional `transcript` field
- `lib/services/exam_study_service.dart` — `submitSpeakingAnswer(questionId, audioFile)` using `MultipartFile`
- `lib/pages/learning/exam_study/section_practice_screen.dart` — route `speaking-prompt` questions to the new screen (mirrors how essays push to `EssayEditorScreen`)
- `lib/pages/learning/exam_study/widgets/section_tile.dart` — add icons for the 3 new sectionType values (Part 1 → `Icons.record_voice_over_rounded`, Part 2 → `Icons.mic_rounded`, Part 3 → `Icons.forum_rounded`)

## Seed content

| Exam | Part 1 prompts | Part 2 (cue card) | Part 3 (discussion) |
|---|---|---|---|
| IELTS | 6 (Home / Hobbies / Work / Food / Travel / Family) | 4 cue cards (Describe a person / place / event / object) | 4 deep discussion sets |
| DELE | 5 monólogo prompts | 4 diálogo scenarios | 3 abstract discussion prompts |
| TOPIK | 5 짧은 답변 prompts | 4 긴 답변 prompts | 3 토론 prompts |

Total ~38 new speaking questions.

---

# Part B — Vocabulary section

## Data model

### New collection: `VocabularyWord`

```js
{
  word: String,             // "abundant"
  languageId: ObjectId,     // ref ExamLanguage
  examIds: [ObjectId],      // refs to ExamType (a word can apply to multiple exams)
  level: String,            // enum: A1 | A2 | B1 | B2 | C1 | C2
  topic: String,            // free-form, same vocabulary as ExamQuestion.topic
  partOfSpeech: String,     // 'adjective' | 'noun' | 'verb' | 'adverb' | 'phrase'
  definition: String,
  exampleSentence: String,
  audioUrl: String | null,  // populated lazily on first listen (TTS cached via existing AudioCache)
  createdAt: Date,
}
```

**Indexes:** `(languageId, level, topic)` (browse), `(examIds, level)` (per-exam quiz draw), text index on `word` for search (future).

### `ExamSection` extension

Each exam gets a new section row with `sectionType: 'vocabulary'`. Reuses the existing section-tile machinery — vocabulary just looks like another section in the dashboard.

`UserExamProgress.sectionScores['vocabulary']` tracks practice accuracy. No level-level breakdown in MVP (the Map could grow `vocabulary-a1` keys later if we want that).

## Backend endpoints

```
GET  /exam-study/vocabulary?language=&examId=&level=&topic=&limit=&skip=
GET  /exam-study/vocabulary/levels?examId=
GET  /exam-study/vocabulary/topics?examId=&level=
POST /exam-study/vocabulary/quiz/start          body: { examId, level, topic?, size=10 }
                                                returns: { quizId, questions: [{ id, prompt, options }] }
POST /exam-study/vocabulary/quiz/:quizId/submit body: { answers: [{ questionId, choice }] }
                                                returns: { score, results: [{ questionId, isCorrect, correctAnswer, explanation }] }
```

Quiz questions are **synthesized server-side** from the word pool — no separate quiz-question collection:
1. Pick N words from the pool matching `(examId, level, topic?)`
2. For each: create an MC stem like `"What does the word '\${word}' mean?"`, the correct option is the word's definition, 3 distractors are pulled from same-level definitions of other words
3. Cache the question pool in Redis (or in-process LRU as fallback) keyed by `quizId` for 30 minutes so submit can validate without trusting the client

`level`-based picker check: `levels?examId=` returns only levels that have ≥1 word for that exam, so empty tiles never appear on the picker.

## App flow

```
Dashboard → Vocabulary tile
              ↓
       Level picker (A1/A2/B1/B2/C1/C2) — greyed if empty
              ↓
       Topic picker (reuses TopicCard grid)
              ↓
       Browse | Practice toggle bar
        ├── Browse: word card list — word, pos, definition, example, audio button
        │   Tap card → expanded view with longer example sentences (future)
        │
        └── Practice: 10-Q MC quiz → result screen with per-question reveal
```

## New / modified files (app)

- `lib/providers/provider_models/exam/vocabulary_word.dart`
- `lib/services/exam_study_service.dart` — vocabulary fetch + quiz endpoints
- `lib/providers/provider_root/exam_study_provider.dart` — vocab list, levels, topics, quiz state notifier
- `lib/pages/learning/exam_study/vocabulary_level_picker_screen.dart`
- `lib/pages/learning/exam_study/vocabulary_topic_picker_screen.dart` (or extend existing topic_picker_screen with a vocab mode flag)
- `lib/pages/learning/exam_study/vocabulary_browse_screen.dart`
- `lib/pages/learning/exam_study/vocabulary_quiz_screen.dart`
- `lib/pages/learning/exam_study/widgets/word_card.dart`
- `lib/pages/learning/exam_study/widgets/level_card.dart`
- `lib/pages/learning/exam_study/widgets/quiz_result_card.dart`

## Korean level dual-labeling

The `level_card.dart` widget takes `(cefr: 'B1', secondaryLabel: 'TOPIK 3–4')`. The dashboard tile + picker show:

```
┌─────────────┐
│  B1         │
│  TOPIK 3–4  │   ← only when language is Korean
└─────────────┘
```

CEFR ↔ TOPIK mapping table lives in `lib/utils/cefr_topik_mapping.dart`:

| CEFR | TOPIK |
|---|---|
| A1 | TOPIK 1 |
| A2 | TOPIK 2 |
| B1 | TOPIK 3 |
| B2 | TOPIK 4 |
| C1 | TOPIK 5 |
| C2 | TOPIK 6 |

(Approximate but standard; cited in the Cambridge CEFR-TOPIK conversion guide.)

## Seed content

Per language × 6 topics × ~3 levels each × ~12 words = **~200 words per language**, **~600 total**. Sourced from:

- English: Coxhead Academic Word List + Cambridge IELTS Vocabulary
- Spanish: Instituto Cervantes DELE vocabulary lists (public)
- Korean: National Institute of Korean Language graded vocabulary lists

Seed migration adds them in chunks of 50 with progress logs.

---

# Cross-cutting concerns

## L10n

~30 new keys across both features:
- `examSpeakingPrompt`, `examSpeakingListenToPrompt`, `examSpeakingStartRecording`, `examSpeakingStopRecording`, `examSpeakingTranscriptHeading`, `examSpeakingPlayMyRecording`, `examSpeakingPart1/2/3 labels`
- `examVocabBrowse`, `examVocabPractice`, `examVocabLevelPickerTitle`, `examVocabTopicPickerTitle`, `examVocabPlayPronunciation`, `examVocabPartOfSpeech`, `examVocabExample`, `examVocabQuizComplete`, `examVocabQuizScore({score},{total})` ICU

Added via Python bulk-add script to all 19 ARB files; non-English locales fall back to English.

## Error handling

- Speaking: short audio (< 2 seconds) → 400 `INVALID_AUDIO` — likely accidental tap; recorder must show timer
- Whisper STT fails → mark job `failed` with the error message; client shows the failed-state screen with a Retry button (re-record)
- Vocab quiz submit with expired `quizId` (cache flushed) → 410 `QUIZ_EXPIRED`, client restarts the quiz
- Empty vocab pool for a given (level, topic) → returns `{ words: [], levels: [...] }` not 404 (so the level picker can still render and grey out empty topics)

## Rate limiting

Speaking submissions use the existing `aiRateLimiter('stt')` middleware. We add `aiRateLimiter('exam-speaking')` configured to **10/minute per user** to match the essay submit rate-limit.

## Testing strategy

**Manual smoke** (no automated tests in MVP):
1. Speaking: record a 30-second answer for IELTS Part 2 cue card → see "Evaluating…" → result screen with transcript visible above the score card
2. Vocabulary browse: tap Vocabulary → A1 → Climate → see word list with audio buttons → tap audio → TTS plays
3. Vocabulary quiz: practice → answer 10 questions → see results breakdown

Automated tests are deferred to a follow-on chunk (in line with the existing pattern — the rest of the exam-study feature ships without automated tests beyond `node -e require(...)` smoke checks).

# Implementation chunks

This spec is large but splits cleanly into two independent chunks:

| Chunk | Scope | Days |
|---|---|---|
| **H. Speaking** | Schema enum extension, submit-answer audio path, evaluateSpeaking service, audio recorder widget, speaking practice screen, transcript display on result, ~38 seed prompts | 2 |
| **G. Vocabulary** | VocabularyWord model + endpoints, quiz synthesis + Redis cache, level/topic pickers, browse + practice screens, CEFR↔TOPIK mapping, ~600 seed words | 2-3 |

**Suggested order:** Chunk H first (smaller, builds on the existing essay flow), then Chunk G.

# Out of scope (deliberately deferred)

- **Picture submission for Writing (Chunk I)** — separate spec when ready; uses GPT-4o vision on the existing writing submit flow
- **Mock test mode (Chunk J)** — composes all sections, needs its own design
- **SRS / spaced repetition for vocab** — could integrate with the existing `lib/pages/learning/vocabulary/` learning module; out of scope for MVP
- **Speaking peer review** — deferred; AI eval only for MVP
- **Custom audio prompts (human-recorded native speaker)** — TTS only for MVP

# Numeric defaults

| Knob | Default |
|---|---|
| Speaking audio max length | 3 minutes |
| Speaking audio min length | 2 seconds |
| Speaking eval poll interval | 3 s (same as essay) |
| Speaking poll timeout | 90 s (longer than essay — STT + eval adds time) |
| Vocab quiz size | 10 questions |
| Vocab quiz cache TTL | 30 min |
| Speaking rate limit | 10 / min per user |
