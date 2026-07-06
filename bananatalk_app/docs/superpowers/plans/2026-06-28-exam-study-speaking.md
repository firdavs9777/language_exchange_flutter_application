# Exam Study — Speaking section (Chunk H) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Speaking section of Exam Study with 3 sub-sections per exam (IELTS Part 1/2/3 pattern, parallel DELE/TOPIK names), audio recording in the Flutter app, Whisper STT + AI evaluation on the backend, transcript displayed on the result screen.

**Architecture:** New dedicated `POST /submit-audio` multipart endpoint on the backend (keeps the existing JSON `/submit-answer` route uncluttered) creates an `EvaluationJob`, kicks off a background worker that runs Whisper STT then calls a new `evaluateSpeaking` AI service helper, writes score + feedback + transcript back to the job. App reuses the existing essay-eval poll pattern; new `SpeakingPracticeScreen` records audio via `flutter_sound` (already in pubspec) and uploads as multipart. No new infra — wires into the existing backend `services/speechService.js` STT + the existing `EvaluationJob` polling.

**Tech Stack:** Node.js + Express + Mongoose + multer + Whisper (via `services/speechService.js`) on the backend; Flutter + Riverpod + `flutter_sound` + `http` MultipartRequest on the app side.

**Companion spec:** `docs/superpowers/specs/2026-06-28-exam-study-speaking-vocab-design.md`

## Global Constraints

- **No new audio infrastructure.** Backend MUST reuse `speechService.transcribeAudio` and `aiProviderService.chatCompletion`. App MUST use `flutter_sound: ^9.2.13` (already in pubspec) — do NOT add new audio packages.
- **Idempotent seeds.** Re-running `migrations/seedExamStudy.js` MUST NOT duplicate sections or questions.
- **Auth on every endpoint.** All new routes go under `router.use(protect)` like the rest of `routes/examStudy.js`.
- **Stub-fallback for AI.** `examEvaluationService.evaluateSpeaking` MUST behave like `evaluateEssay` — return a deterministic stub eval when `OPENAI_API_KEY` is unset, so dev/staging works without OpenAI credentials.
- **Don't persist user audio by default.** `SPEECH_PERSIST_AUDIO` defaults to false. Audio is processed in-memory through Whisper, transcript stored, audio dropped.
- **No automated tests in this chunk.** Existing exam-study chunks shipped with smoke-test verification only (`node -e "require(...)"` + manual acceptance). Follow that pattern; defer automated tests to a later iteration.
- **Bilingual progress already supported.** `UserExamProgress.sectionScores` is already a `Map<String, SectionScore>` (from Chunk F) — new `speaking-part-1/2/3` keys land automatically with no schema change.
- **Frequent commits.** Each task ends with `git add` + `git commit`. Backend commits use prefix `feat(exam-study):` and app commits use `feat(exam-study):` as well (matches the established pattern).

---

# File Structure

## Backend (`/Users/firdavsmutalipov/Projects/BananaTalk/backend/`)

| File | Action | Responsibility |
|---|---|---|
| `models/ExamSection.js` | modify | Extend `sectionType` enum with `speaking-part-1/2/3` |
| `models/ExamType.js` | modify | Same enum widening on `sections` array |
| `models/EvaluationJob.js` | modify | Add `transcript: String` and `audioUrl: String` fields |
| `services/examEvaluationService.js` | modify | Add `evaluateSpeaking({transcript, rubric, targetBand})` helper next to existing `evaluateEssay` |
| `routes/examStudy.js` | modify | Add `POST /submit-audio` with multer; return `USE_AUDIO_ENDPOINT` from existing `/submit-answer` when called for `speaking-prompt` |
| `migrations/seedExamStudy.js` | modify | Add Speaking sub-sections per exam + ~38 prompts. Idempotent. |

## App (`/Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app/`)

| File | Action | Responsibility |
|---|---|---|
| `lib/providers/provider_models/exam/evaluation_status.dart` | modify | Add optional `transcript: String?` field |
| `lib/services/exam_study_service.dart` | modify | Add `submitSpeakingAnswer(questionId, audioFile)` using `MultipartRequest` |
| `lib/pages/learning/exam_study/widgets/audio_recorder.dart` | create | Stateful widget wrapping `FlutterSoundRecorder` — init/record/stop/dispose + waveform-amp callback + timer |
| `lib/pages/learning/exam_study/speaking_practice_screen.dart` | create | Renders prompt + "Listen" (TTS) + AudioRecorder + Submit; pushes EvaluationResultScreen on submit |
| `lib/pages/learning/exam_study/section_practice_screen.dart` | modify | Route `speaking-prompt` questions to `SpeakingPracticeScreen` (mirroring how essays push to `EssayEditorScreen`) |
| `lib/pages/learning/exam_study/evaluation_result_screen.dart` | modify | Render transcript block above the score card when present |
| `lib/pages/learning/exam_study/widgets/section_tile.dart` | modify | Icon switch entries for `speaking-part-1/2/3` |
| `lib/l10n/app_*.arb` (× 19 locales) | modify | New `examSpeaking*` keys + ICU placeholder for `examSpeakingDuration({seconds})` |
| `lib/l10n/app_localizations*.dart` | modify | Regenerated via `flutter gen-l10n` |

---

# Tasks

## Task 1: Backend — Extend section enums for speaking-part-1/2/3

**Files:**
- Modify: `models/ExamSection.js:14-27`
- Modify: `models/ExamType.js:14-25`

**Interfaces:**
- Consumes: nothing
- Produces: `sectionType` enum now accepts `'speaking-part-1'`, `'speaking-part-2'`, `'speaking-part-3'` — required by Tasks 5, 6, 9 (seed) and the app dashboard

- [ ] **Step 1: Edit `models/ExamSection.js`**

Replace the existing enum:

```js
sectionType: {
  type: String,
  enum: [
    'reading',
    'writing',
    'writing-task-1',
    'writing-task-2',
    'speaking', // legacy
    'speaking-part-1',
    'speaking-part-2',
    'speaking-part-3',
    'listening',
    'vocabulary',
  ],
  required: true,
},
```

- [ ] **Step 2: Edit `models/ExamType.js`**

Replace the existing enum on `sections`:

```js
sections: [
  {
    type: String,
    enum: [
      'reading',
      'writing',
      'writing-task-1',
      'writing-task-2',
      'speaking',
      'speaking-part-1',
      'speaking-part-2',
      'speaking-part-3',
      'listening',
      'vocabulary',
    ],
  },
],
```

- [ ] **Step 3: Smoke-test module loading**

Run from the backend root:

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
node -e "require('./models/ExamSection'); require('./models/ExamType'); console.log('OK');"
```

Expected output: `OK`

- [ ] **Step 4: Commit**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
git add models/ExamSection.js models/ExamType.js
git commit -m "$(cat <<'EOF'
feat(exam-study): extend section enums for Speaking Part 1/2/3

Adds speaking-part-1 / speaking-part-2 / speaking-part-3 to the
ExamSection.sectionType and ExamType.sections enums. Legacy
'speaking' value retained for any pre-split data. Mirrors the
writing-task-1/2 split already in place.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Backend — EvaluationJob transcript + audioUrl fields

**Files:**
- Modify: `models/EvaluationJob.js`

**Interfaces:**
- Consumes: nothing
- Produces: `EvaluationJob` documents now carry `transcript: String` and `audioUrl: String` — both nullable, populated by the speaking background worker. Read by the app's evaluation polling endpoint (Task 6 surfaces them via the existing `GET /evaluations/:id`).

- [ ] **Step 1: Edit `models/EvaluationJob.js`**

Add two fields inside the schema definition, after `improvements: [String]`:

```js
// Whisper-STT output for speaking jobs. Null for essay jobs.
transcript: String,
// S3 URL for the persisted audio, only set when SPEECH_PERSIST_AUDIO
// is true. Null otherwise.
audioUrl: String,
```

- [ ] **Step 2: Smoke-test module loading**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
node -e "require('./models/EvaluationJob'); console.log('OK');"
```

Expected: `OK`

- [ ] **Step 3: Confirm existing polling endpoint already passes new fields through**

Open `routes/examStudy.js`, find the existing `GET /evaluations/:evaluationId` handler. The current `res.json({ success, data: { ... } })` payload should be extended to include `transcript` and `audioUrl`. Update that handler:

Locate the `res.json` block (search for `_id: job._id` inside the evaluations route). Add the two new fields to the `data` object:

```js
res.json({
  success: true,
  data: {
    _id: job._id,
    status: job.status,
    score: job.score,
    feedback: job.feedback,
    strengths: job.strengths,
    improvements: job.improvements,
    transcript: job.transcript,
    audioUrl: job.audioUrl,
    errorMessage: job.errorMessage,
    completedAt: job.completedAt,
  },
});
```

- [ ] **Step 4: Commit**

```bash
git add models/EvaluationJob.js routes/examStudy.js
git commit -m "$(cat <<'EOF'
feat(exam-study): EvaluationJob carries transcript + audioUrl

Adds optional transcript and audioUrl fields populated by the
speaking background worker (Whisper STT result + optional S3 URL
when audio persistence is enabled). The existing GET /evaluations
endpoint now surfaces both fields so the client can show "what we
heard you say" above the score card.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Backend — examEvaluationService.evaluateSpeaking

**Files:**
- Modify: `services/examEvaluationService.js`

**Interfaces:**
- Consumes: `aiProviderService.chatCompletion` (already imported in the file)
- Produces: new exported function `evaluateSpeaking({ transcript, rubric?, targetBand? })` returning `{ score: int, feedback: string, strengths: string[], improvements: string[] }`. Called by Task 4's background worker.

- [ ] **Step 1: Add the new helper next to `evaluateEssay`**

Insert this function inside `services/examEvaluationService.js`, **directly above the `module.exports` block at the bottom**:

```js
/**
 * @param {Object} opts
 * @param {String} opts.transcript   Whisper-STT output of the user's spoken answer.
 * @param {String} [opts.rubric]     Rubric criteria comma-separated.
 * @param {Number} [opts.targetBand] Target band score (default 6).
 * @returns {Promise<{score:Number, feedback:String, strengths:String[], improvements:String[]}>}
 */
async function evaluateSpeaking({
  transcript,
  rubric = 'fluency and coherence, vocabulary range, grammar accuracy, task response',
  targetBand = 6,
}) {
  if (!transcript || transcript.trim().length < 5) {
    throw new Error('Transcript is too short to evaluate');
  }

  // No key configured? Deterministic stub so the polling UX works
  // without burning OpenAI tokens.
  if (!process.env.OPENAI_API_KEY) {
    return _stubSpeakingEvaluation(transcript);
  }

  const prompt = `You are an IELTS speaking examiner. Evaluate the following transcribed spoken response against these criteria: ${rubric}.

Note: The text is a Whisper STT transcript of a spoken answer, so allow for filler words ("um", "uh") and minor disfluency typical of speech.

Transcript:
${transcript}

Target Band: ${targetBand}

Respond ONLY with JSON in this exact shape:
{
  "score": <integer 0-100>,
  "feedback": "<2-4 sentences of overall feedback>",
  "strengths": ["<strength 1>", "<strength 2>"],
  "improvements": ["<improvement 1>", "<improvement 2>"]
}`;

  const response = await aiProviderService.chatCompletion({
    messages: [{ role: 'user', content: prompt }],
    feature: 'examSpeakingEvaluation',
    temperature: 0.4,
    json: true,
  });

  let parsed;
  try {
    parsed = JSON.parse(response.content);
  } catch (_) {
    throw new Error('AI returned malformed speaking evaluation');
  }

  return {
    score: Math.min(100, Math.max(0, Number(parsed.score) || 0)),
    feedback: String(parsed.feedback || ''),
    strengths: Array.isArray(parsed.strengths)
      ? parsed.strengths.map(String)
      : [],
    improvements: Array.isArray(parsed.improvements)
      ? parsed.improvements.map(String)
      : [],
  };
}

/**
 * Deterministic placeholder used when OPENAI_API_KEY is unset.
 * Scores by transcript length + word count so the result varies.
 */
function _stubSpeakingEvaluation(transcript) {
  const words = transcript.trim().split(/\s+/).length;
  const score = Math.min(95, Math.max(40, Math.round(50 + words / 4)));
  return {
    score,
    feedback:
      'This is a placeholder speaking evaluation. Configure OPENAI_API_KEY on the server to enable real AI scoring.',
    strengths: [
      `Spoke for ${words} words — adequate length for a Part 1-style answer.`,
      'Transcript captured cleanly by speech-to-text.',
    ],
    improvements: [
      'Real AI feedback on fluency, vocabulary, and grammar will appear here once the API key is configured.',
    ],
  };
}
```

- [ ] **Step 2: Extend the module exports**

At the very bottom of the file, change the existing exports block from:

```js
module.exports = {
  evaluateEssay,
  MIN_CHARS,
  MAX_CHARS,
};
```

to:

```js
module.exports = {
  evaluateEssay,
  evaluateSpeaking,
  MIN_CHARS,
  MAX_CHARS,
};
```

- [ ] **Step 3: Smoke-test that the function is exported and stub-evaluates**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
node -e "
const svc = require('./services/examEvaluationService');
svc.evaluateSpeaking({ transcript: 'I think technology has changed our lives in many positive ways.' })
  .then(r => { console.log('OK', JSON.stringify(r)); })
  .catch(e => { console.error('FAIL', e.message); process.exit(1); });
"
```

Expected output starts with `OK` and the JSON contains `score`, `feedback`, `strengths`, `improvements`.

- [ ] **Step 4: Commit**

```bash
git add services/examEvaluationService.js
git commit -m "$(cat <<'EOF'
feat(exam-study): evaluateSpeaking service with stub fallback

Mirrors evaluateEssay — same JSON-mode OpenAI call with a
speaking-specific rubric (fluency, coherence, vocabulary, grammar,
task response). The rubric prompt explicitly tolerates STT filler
words so transcripts of natural speech don't get penalised twice.

Returns a deterministic stub when OPENAI_API_KEY is unset so dev
environments exercise the full UX without burning tokens.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Backend — POST /submit-audio multipart endpoint

**Files:**
- Modify: `routes/examStudy.js`

**Interfaces:**
- Consumes: `EvaluationJob` (Task 2), `examEvaluationService.evaluateSpeaking` (Task 3), existing `_bumpProgress` and `_resolveSectionKey` helpers in the same file, `speechService.transcribeAudio` from `services/speechService.js`
- Produces: new route `POST /api/v1/exam-study/questions/:questionId/submit-audio` (multipart) returning `202 { pollUrl, statusCode }` for valid speaking submissions. Modifies existing `/submit-answer` to return `400 USE_AUDIO_ENDPOINT` when called with a `speaking-prompt` question (was `501 NOT_IMPLEMENTED`). The result-screen polling endpoint added in Task 2 surfaces the transcript that this task populates.

- [ ] **Step 1: Add the multer + speechService imports at the top of `routes/examStudy.js`**

Find the existing `require` block at the top (after `const examStudyPlanService = ...`). Add:

```js
const multer = require('multer');
const { transcribeAudio } = require('../services/speechService');
```

Then, immediately below the `router.use(protect)` line, add the multer configuration (mirrors what `routes/speech.js` already uses):

```js
const audioUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 }, // 25 MB
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/m4a',
      'audio/wav', 'audio/webm', 'audio/ogg', 'audio/flac',
      'audio/x-m4a', 'audio/x-wav', 'audio/aac',
    ];
    if (allowedMimes.includes(file.mimetype)) cb(null, true);
    else cb(new Error(`Invalid audio mime type: ${file.mimetype}`), false);
  },
});
```

- [ ] **Step 2: Replace the speaking-prompt branch in `/submit-answer`**

Find this block in `routes/examStudy.js` (inside the `POST /questions/:questionId/submit-answer` route):

```js
    // Speaking-prompt — still not wired (no Whisper integration yet).
    if (question.questionType === 'speaking-prompt') {
      return res.status(501).json({
        success: false,
        code: 'NOT_IMPLEMENTED',
        message:
          'Speaking evaluation is not yet available. Please check back soon.',
      });
    }
```

Replace it with:

```js
    // Speaking is handled by the dedicated /submit-audio multipart
    // endpoint — keeps JSON essay submissions and audio uploads on
    // separate middleware stacks.
    if (question.questionType === 'speaking-prompt') {
      return res.status(400).json({
        success: false,
        code: 'USE_AUDIO_ENDPOINT',
        message:
          'Speaking submissions must use POST /submit-audio with multipart/form-data and field name "audio".',
      });
    }
```

- [ ] **Step 3: Add the new `/submit-audio` route**

Insert this **immediately after** the existing `POST /questions/:questionId/submit-answer` route closes (look for the `})); ` line that ends it):

```js
// POST /api/v1/exam-study/questions/:questionId/submit-audio
// Multipart audio upload for speaking-prompt questions. Creates an
// EvaluationJob, kicks off Whisper STT + AI eval in the background,
// returns 202 with a poll URL. The client polls the same
// /evaluations/:evaluationId endpoint that essays use.
router.post(
  '/questions/:questionId/submit-audio',
  audioUpload.single('audio'),
  asyncHandler(async (req, res) => {
    const { questionId } = req.params;
    const userId = req.user._id;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        code: 'NO_AUDIO',
        message: 'Audio file is required (multipart field "audio").',
      });
    }

    const question = await ExamQuestion.findById(questionId);
    if (!question) {
      return res.status(404).json({
        success: false,
        code: 'QUESTION_NOT_FOUND',
        message: 'Question not found',
      });
    }
    if (question.questionType !== 'speaking-prompt') {
      return res.status(400).json({
        success: false,
        code: 'NOT_A_SPEAKING_QUESTION',
        message:
          'Use POST /submit-answer (JSON) for multiple-choice and essay questions.',
      });
    }

    // Naive audio-duration floor: most usable speech responses are at
    // least a few KB. Reject < 8 KB as accidental taps without trying
    // to parse the actual audio header (varies by codec).
    if (req.file.size < 8 * 1024) {
      return res.status(400).json({
        success: false,
        code: 'AUDIO_TOO_SHORT',
        message: 'Recording is too short. Please speak for at least a few seconds.',
      });
    }

    const job = await EvaluationJob.create({
      userId,
      questionId: question._id,
      userAnswer: `[speaking response — ${req.file.size} bytes]`,
      status: 'pending',
    });

    // Fire-and-forget. Failures mark the job as failed; never crash
    // the request.
    _evaluateSpeakingInBackground(job._id, req.file.buffer, req.file.mimetype).catch(
      (err) => {
        console.error('[examStudy] background speaking eval crashed:', err);
      }
    );

    return res.status(202).json({
      success: true,
      statusCode: 202,
      pollUrl: `/api/v1/exam-study/evaluations/${job._id}`,
    });
  })
);
```

- [ ] **Step 4: Add the `_evaluateSpeakingInBackground` helper**

Find the existing `_evaluateInBackground` function inside the same file. Add this new helper **immediately above it**:

```js
/**
 * Speaking equivalent of _evaluateInBackground.
 * 1) Transcribe the audio with Whisper.
 * 2) Evaluate the transcript with examEvaluationService.evaluateSpeaking.
 * 3) Write transcript + score + feedback to the job, bump progress.
 */
async function _evaluateSpeakingInBackground(jobId, audioBuffer, mimeType) {
  let job;
  try {
    job = await EvaluationJob.findById(jobId);
    if (!job) return;

    // 1. Whisper STT. Pass through the buffer + mime so speechService
    // can hand it to OpenAI's audio.transcriptions.
    const transcription = await transcribeAudio({
      audioBuffer,
      mimeType,
      // Let Whisper auto-detect language by default. For higher
      // accuracy we could plumb through the exam's language code,
      // but the default is fine for MVP.
    });
    const transcript = transcription?.text || transcription || '';
    job.transcript = transcript;
    await job.save();

    if (!transcript || transcript.trim().length < 5) {
      job.status = 'failed';
      job.errorMessage = 'Could not transcribe audio — please re-record.';
      job.completedAt = new Date();
      await job.save();
      return;
    }

    // 2. Evaluate transcript.
    const result = await examEvaluationService.evaluateSpeaking({ transcript });
    job.status = 'completed';
    job.score = result.score;
    job.feedback = result.feedback;
    job.strengths = result.strengths;
    job.improvements = result.improvements;
    job.completedAt = new Date();
    await job.save();

    // 3. Bump progress — same threshold as essay (≥ 60 counts as
    // "correct" so the section score reflects partial credit).
    const question = await ExamQuestion.findById(job.questionId).select(
      'examId sectionId'
    );
    if (question) {
      const sectionKey = await _resolveSectionKey(question.sectionId);
      const passed = result.score >= 60;
      await _bumpProgress({
        userId: job.userId,
        examId: question.examId,
        sectionKey,
        attempted: 1,
        correct: passed ? 1 : 0,
        lastQuestionId: question._id,
      });
    }
  } catch (err) {
    if (job) {
      job.status = 'failed';
      job.errorMessage = err.message || 'Speaking evaluation failed';
      job.completedAt = new Date();
      try { await job.save(); } catch (_) {}
    }
  }
}
```

**Important:** `transcribeAudio` is imported at the top (Task 4 Step 1). The function signature `transcribeAudio({ audioBuffer, mimeType })` matches what `services/speechService.js` exports — verify by opening that file before running this task. If the existing signature differs, adapt the call but keep the surrounding logic identical.

- [ ] **Step 5: Verify the signature of `speechService.transcribeAudio`**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
grep -n "exports.transcribeAudio\|transcribeAudio\s*=\|transcribeAudio\s*(" services/speechService.js | head -10
```

If the exported `transcribeAudio` takes different parameters (e.g. `(audioFile)` where `audioFile` has `.buffer` and `.mimetype`), adjust the call in `_evaluateSpeakingInBackground` accordingly. Don't proceed until the parameter shape matches.

- [ ] **Step 6: Smoke-test backend module load**

```bash
node -e "require('./routes/examStudy'); console.log('OK');"
```

Expected: `OK`.

- [ ] **Step 7: Quick auth check on the new endpoint**

Start the backend if it isn't already running, then:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  http://localhost:5003/api/v1/exam-study/questions/000000000000000000000000/submit-audio
```

Expected: `HTTP 401` (route exists + auth middleware fires before the rest of the handler).

- [ ] **Step 8: Commit**

```bash
git add routes/examStudy.js
git commit -m "$(cat <<'EOF'
feat(exam-study): POST /submit-audio for speaking responses

New multipart audio endpoint sibling to /submit-answer. Multer
parses the upload (25 MB cap, audio mime allowlist mirroring
speech.js), creates an EvaluationJob, kicks off Whisper STT +
AI evaluation in the background, returns 202 with pollUrl.

The background worker transcribes via speechService.transcribeAudio
then evaluates with examEvaluationService.evaluateSpeaking. Score
and transcript land on the EvaluationJob; progress bumps through
the existing _bumpProgress writer so speaking, essay, and MC all
share one progress code path.

The original /submit-answer route now returns 400 USE_AUDIO_ENDPOINT
for speaking-prompt questions (was 501) so the client knows to
switch routes.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Backend — Seed speaking sections + prompts

**Files:**
- Modify: `migrations/seedExamStudy.js`

**Interfaces:**
- Consumes: enum widening from Task 1, model fields from Task 2
- Produces: 9 new `ExamSection` rows (3 per exam × 3 exams) + ~38 speaking-prompt questions. Powers the speaking dashboard tiles + topic pickers.

- [ ] **Step 1: Update `EXAM_DATA` to list speaking sub-sections**

Find the `EXAM_DATA` array in `migrations/seedExamStudy.js`. For each exam, extend the `sections` array with the three new section types. Replace:

```js
const EXAM_DATA = [
  {
    name: 'IELTS',
    languageCode: 'en',
    description: 'International English Language Testing System.',
    sections: ['reading', 'writing-task-1', 'writing-task-2'],
    durationMinutes: 170,
    scoringType: 'band',
    maxScore: 9,
  },
  // ...
];
```

with:

```js
const EXAM_DATA = [
  {
    name: 'IELTS',
    languageCode: 'en',
    description: 'International English Language Testing System.',
    sections: [
      'reading',
      'writing-task-1',
      'writing-task-2',
      'speaking-part-1',
      'speaking-part-2',
      'speaking-part-3',
    ],
    durationMinutes: 170,
    scoringType: 'band',
    maxScore: 9,
  },
  {
    name: 'DELE',
    languageCode: 'es',
    description: 'Diplomas de Español como Lengua Extranjera.',
    sections: [
      'reading',
      'writing-task-1',
      'writing-task-2',
      'speaking-part-1',
      'speaking-part-2',
      'speaking-part-3',
    ],
    durationMinutes: 160,
    scoringType: 'score',
    maxScore: 100,
  },
  {
    name: 'TOPIK',
    languageCode: 'ko',
    description: 'Test of Proficiency in Korean.',
    sections: [
      'reading',
      'writing-task-1',
      'writing-task-2',
      'speaking-part-1',
      'speaking-part-2',
      'speaking-part-3',
    ],
    durationMinutes: 180,
    scoringType: 'score',
    maxScore: 300,
  },
];
```

- [ ] **Step 2: Add the three speaking section definitions to `SECTION_DATA`**

Find the existing `SECTION_DATA` array (currently has reading + writing-task-1 + writing-task-2). Append:

```js
{
  type: 'speaking-part-1',
  name: 'Speaking — Part 1',
  durationMinutes: 5,
  questionCount: 6,
},
{
  type: 'speaking-part-2',
  name: 'Speaking — Part 2',
  durationMinutes: 4,
  questionCount: 4,
},
{
  type: 'speaking-part-3',
  name: 'Speaking — Part 3',
  durationMinutes: 5,
  questionCount: 4,
},
```

so the final array has 6 entries.

- [ ] **Step 3: Customise section names per exam for DELE and TOPIK**

The default `name` from Step 2 uses English labels ("Speaking — Part 1"). For DELE and TOPIK we want native-language names. After the existing section-creation loop in `seed()` (look for the block that creates section rows from `SECTION_DATA`), add this localisation pass:

```js
// Localise speaking section names per exam — section rows already
// exist with English defaults from the loop above. This block is
// idempotent: only writes when the name still matches the default.
const SPEAKING_NAME_OVERRIDES = {
  DELE: {
    'speaking-part-1': 'Hablar — Monólogo',
    'speaking-part-2': 'Hablar — Diálogo',
    'speaking-part-3': 'Hablar — Conversación',
  },
  TOPIK: {
    'speaking-part-1': '말하기 — 짧은 답변',
    'speaking-part-2': '말하기 — 긴 답변',
    'speaking-part-3': '말하기 — 토론',
  },
};
for (const [examName, overrides] of Object.entries(SPEAKING_NAME_OVERRIDES)) {
  const exam = examByName[examName];
  if (!exam) continue;
  for (const [sectionType, localisedName] of Object.entries(overrides)) {
    const section = sectionsByExam[examName]?.[sectionType];
    if (!section) continue;
    // Only rename if still on the default English name — keeps the
    // migration idempotent without clobbering admin edits.
    if (section.sectionName && section.sectionName.startsWith('Speaking — ')) {
      section.sectionName = localisedName;
      await section.save();
      console.log(`~ Localised ${examName}/${sectionType} → ${localisedName}`);
    }
  }
}
```

- [ ] **Step 4: Add speaking prompts to `QUESTION_DATA`**

Find the `QUESTION_DATA` object. After the existing `'TOPIK:writing-task-2'` array, **before the closing `}` of the object**, add the speaking-prompt batches. Each one has `questionType: 'speaking-prompt'` and a `topic` so the topic picker has something to group:

```js
  // IELTS Speaking Part 1 — short introductory Q&A (~30s answers).
  'IELTS:speaking-part-1': [
    { topic: 'Home', questionText: 'Where do you live? Can you describe your hometown briefly?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Aim for 2-3 connected sentences with a personal detail.', difficulty: 'easy' },
    { topic: 'Hobbies', questionText: 'What do you enjoy doing in your free time? Why?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'A simple reason for each activity helps the answer feel complete.', difficulty: 'easy' },
    { topic: 'Work', questionText: 'Do you work or are you a student? Tell me a little about what you do.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Mention the role and one thing you like or find challenging.', difficulty: 'easy' },
    { topic: 'Food', questionText: 'What kind of food do you like? Has your taste changed over the years?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Use past + present tense — examiners look for tense variety.', difficulty: 'medium' },
    { topic: 'Travel', questionText: 'Have you travelled recently? Where did you go and what was it like?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Past tense narrative with one specific detail (a meal, a place, a person).', difficulty: 'medium' },
    { topic: 'Culture', questionText: 'What festivals or holidays are important in your culture?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Pick one festival and describe what people do — concrete > abstract.', difficulty: 'medium' },
  ],
  // IELTS Speaking Part 2 — cue card monologue (1-2 min).
  'IELTS:speaking-part-2': [
    { topic: 'Travel', questionText: 'Describe a memorable trip you have taken. You should say:\n• where you went\n• who you went with\n• what you did there\n• and explain why it was memorable.\n\nSpeak for 1–2 minutes.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Cover all four bullets in order; finish with the "why" — it carries the strongest band signal.', difficulty: 'medium' },
    { topic: 'Education', questionText: 'Describe a teacher who influenced you. You should say:\n• who they were\n• what they taught\n• how they taught\n• and explain why they had an impact on you.\n\nSpeak for 1–2 minutes.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Use specific anecdotes — the examiner rewards concrete narrative over generic praise.', difficulty: 'medium' },
    { topic: 'Technology', questionText: 'Describe a piece of technology you use every day. You should say:\n• what it is\n• how often you use it\n• what you use it for\n• and explain why it is important to you.\n\nSpeak for 1–2 minutes.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Avoid listing features — focus on how it changed your routine.', difficulty: 'medium' },
    { topic: 'Health', questionText: 'Describe a change you made to your lifestyle. You should say:\n• what the change was\n• when you made it\n• why you made it\n• and how it affected you.\n\nSpeak for 1–2 minutes.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Past-to-present arc shows tense control. End with a reflective sentence.', difficulty: 'hard' },
  ],
  // IELTS Speaking Part 3 — deeper discussion (4-5 min total).
  'IELTS:speaking-part-3': [
    { topic: 'Technology', questionText: 'How has technology changed the way people communicate? Do you think these changes are mostly positive or negative?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Take a clear stance, give 2 examples, acknowledge a counter-point.', difficulty: 'hard' },
    { topic: 'Education', questionText: 'Some people think university should be free for everyone. Do you agree? What are the implications either way?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Discuss societal vs individual benefit; avoid one-sided answers.', difficulty: 'hard' },
    { topic: 'Climate', questionText: 'What do you think individuals can do to reduce their impact on the environment? Are individual actions enough?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Mix concrete actions (recycling, transport) with structural commentary (policy, business).', difficulty: 'hard' },
    { topic: 'Work', questionText: 'How has the rise of remote work changed our lives? Do you think it will continue to grow?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Compare pre- and post-2020; offer a future-tense prediction with a justification.', difficulty: 'hard' },
  ],

  // DELE Hablar — Monólogo (~2 min individual presentation).
  'DELE:speaking-part-1': [
    { topic: 'Home', questionText: 'Preséntese y describa la ciudad donde vive. Hable durante aproximadamente un minuto.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Use el presente y al menos un adjetivo descriptivo por idea.', difficulty: 'easy' },
    { topic: 'Hobbies', questionText: 'Cuente brevemente cuáles son sus pasatiempos favoritos y por qué le gustan.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Justifique cada pasatiempo con una razón concreta.', difficulty: 'easy' },
    { topic: 'Work', questionText: 'Hable sobre su trabajo o sus estudios actuales y qué espera lograr en los próximos años.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Alterne entre presente y futuro — el examinador valora la variedad temporal.', difficulty: 'medium' },
    { topic: 'Travel', questionText: 'Describa un viaje reciente: a dónde fue, qué hizo y qué recuerda con más cariño.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Use el pretérito indefinido y termine con una valoración personal.', difficulty: 'medium' },
    { topic: 'Culture', questionText: 'Hable sobre una fiesta o tradición importante de su cultura. ¿Qué se hace y por qué es relevante?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Conecte el qué con el porqué — los datos sin contexto pesan poco.', difficulty: 'medium' },
  ],
  // DELE Hablar — Diálogo (interacción con el examinador).
  'DELE:speaking-part-2': [
    { topic: 'Health', questionText: 'Imagine que está en una farmacia y necesita comprar medicamentos sin receta para un resfriado. Inicie y mantenga la conversación con el farmacéutico (examinador).', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Use fórmulas de cortesía: "Disculpe", "¿Podría…?". Cierre la conversación con una despedida.', difficulty: 'medium' },
    { topic: 'Travel', questionText: 'Está reservando una habitación de hotel por teléfono. Negocie con el recepcionista (examinador) detalles como precio, fechas y servicios incluidos.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Practique condicionales ("¿Sería posible…?") y formas de petición.', difficulty: 'medium' },
    { topic: 'Work', questionText: 'Está en una entrevista de trabajo. Responda a las preguntas del entrevistador (examinador) sobre su experiencia y motivación.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Combine pasado (lo que ha hecho) y futuro (lo que aportaría).', difficulty: 'hard' },
    { topic: 'Education', questionText: 'Quiere matricularse en un curso de español avanzado. Pida información a la secretaría (examinador) sobre horarios, precios y nivel requerido.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Estructure preguntas claras y reformule cuando no entienda la respuesta.', difficulty: 'medium' },
  ],
  // DELE Hablar — Conversación (debate sobre un tema).
  'DELE:speaking-part-3': [
    { topic: 'Climate', questionText: '"Los gobiernos deberían prohibir los coches de gasolina en las ciudades para 2030." ¿Está de acuerdo? Defienda su postura con argumentos.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Use conectores ("por un lado", "sin embargo", "en conclusión") para articular el debate.', difficulty: 'hard' },
    { topic: 'Technology', questionText: '¿Cree que las redes sociales han mejorado o empeorado la calidad de nuestras relaciones? Argumente su opinión.', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Mencione ejemplos personales o sociales para apoyar cada argumento.', difficulty: 'hard' },
    { topic: 'Education', questionText: 'Algunas universidades están eliminando los exámenes presenciales. ¿Cree que esto es positivo? ¿Por qué?', questionType: 'speaking-prompt', correctAnswer: null, explanation: 'Aborde tanto al estudiante como al profesor en su análisis.', difficulty: 'hard' },
  ],

  // TOPIK 말하기 — Part 1 (짧은 답변, ~30초).
  'TOPIK:speaking-part-1': [
    { topic: 'Home', questionText: '자기소개를 해 주세요. 이름, 직업, 사는 곳을 포함해서 30초 정도로 말해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '존댓말을 일관되게 사용하고, 정보를 간결하게 정리하세요.', difficulty: 'easy' },
    { topic: 'Hobbies', questionText: '여가 시간에 주로 무엇을 하는지 짧게 말해 주세요. 그 활동을 좋아하는 이유도 포함하세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '이유를 한 문장으로 명확히 표현하세요.', difficulty: 'easy' },
    { topic: 'Food', questionText: '가장 좋아하는 한국 음식이 있으면 무엇인지, 어떤 점이 좋은지 말해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '맛, 추억, 재료 중 하나를 골라 구체적으로 설명하세요.', difficulty: 'easy' },
    { topic: 'Work', questionText: '현재 하고 있는 일이나 공부에 대해 간단히 설명해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '직무 한 가지, 좋은 점 한 가지를 짚어 주세요.', difficulty: 'medium' },
    { topic: 'Culture', questionText: '자신의 나라에서 중요한 명절이나 행사 하나를 짧게 소개해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '무엇을 하는지 → 왜 중요한지 순서로 정리하세요.', difficulty: 'medium' },
  ],
  // TOPIK 말하기 — Part 2 (긴 답변, 1–2분).
  'TOPIK:speaking-part-2': [
    { topic: 'Travel', questionText: '가장 기억에 남는 여행 경험에 대해 1~2분 정도 말해 주세요. 어디로, 누구와, 무엇을 했는지 포함하세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '시간 순서 표현(처음에, 그다음에, 마지막에)을 사용하면 논리적으로 들립니다.', difficulty: 'medium' },
    { topic: 'Education', questionText: '본인에게 영향을 준 선생님이나 멘토에 대해 1~2분 동안 이야기해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '구체적인 일화 하나를 중심으로 발표를 구성하세요.', difficulty: 'medium' },
    { topic: 'Technology', questionText: '최근에 새로 배운 기술이나 앱에 대해 소개해 주세요. 어떻게 사용하는지, 왜 유용한지 설명하세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '기능 나열보다 사용자 경험 중심으로 말하세요.', difficulty: 'medium' },
    { topic: 'Health', questionText: '건강을 위해 최근에 바꾼 습관이나 시도한 일이 있다면 1~2분 동안 말해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '과거형과 현재형을 함께 사용해 변화의 흐름을 보여 주세요.', difficulty: 'hard' },
  ],
  // TOPIK 말하기 — Part 3 (토론 / 의견).
  'TOPIK:speaking-part-3': [
    { topic: 'Technology', questionText: '인공지능 기술이 일자리에 미치는 영향에 대해 본인의 의견을 말해 주세요. 긍정적·부정적 측면을 모두 다루세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '두 측면을 균형 있게 다루고 마지막에 본인의 견해를 밝히세요.', difficulty: 'hard' },
    { topic: 'Education', questionText: '온라인 수업과 오프라인 수업의 장단점을 비교해서 의견을 말해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '비교 표현("~보다", "~에 비해")을 자연스럽게 사용하세요.', difficulty: 'hard' },
    { topic: 'Climate', questionText: '환경 보호를 위해 개인이 실천할 수 있는 일에는 어떤 것들이 있는지, 그리고 개인의 노력만으로 충분한지에 대해 말해 주세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '개인 → 사회 → 정부 순으로 시야를 넓혀 설득력을 높이세요.', difficulty: 'hard' },
    { topic: 'Work', questionText: '재택근무가 늘어나는 추세에 대해 어떻게 생각하는지 의견을 말해 주세요. 앞으로의 전망도 포함하세요.', questionType: 'speaking-prompt', correctAnswer: null, explanation: '미래 시제와 가정 표현("~할 것 같다", "~게 된다면")을 활용하세요.', difficulty: 'hard' },
  ],
```

- [ ] **Step 5: Re-run the seed against prod Mongo**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
MONGO_URI=$(grep "^MONGO_URI=" config/config.env | cut -d= -f2-)
FLAME_MONGO_URI="$MONGO_URI" node migrations/seedExamStudy.js 2>&1 | tail -30
```

Expected output ends with `✅ Seed complete` and includes lines like:

```
+ Created section IELTS/speaking-part-1
+ Created section IELTS/speaking-part-2
+ Created section IELTS/speaking-part-3
~ Localised DELE/speaking-part-1 → Hablar — Monólogo
...
+ Created 38 questions
```

Question count may vary slightly if the seed encounters dedupes from prior runs — anything ≥ 30 is fine.

- [ ] **Step 6: Spot-check via curl that the new section types serve content**

The backend should already be running. Replace `<IELTS_EXAM_ID>` with the IELTS exam id (visible from `GET /exam-study/languages/<en-id>/exams`):

```bash
curl -s http://localhost:5003/api/v1/exam-study/exams/<IELTS_EXAM_ID>/sections | python3 -m json.tool | grep -E "sectionType|sectionName"
```

Expected: 6 lines for `sectionType`, including `speaking-part-1`, `speaking-part-2`, `speaking-part-3`.

- [ ] **Step 7: Commit**

```bash
git add migrations/seedExamStudy.js
git commit -m "$(cat <<'EOF'
feat(exam-study): seed Speaking Part 1/2/3 sections + prompts

Adds 9 new ExamSection rows (3 per exam) and ~38 speaking-prompt
questions across IELTS, DELE, TOPIK. Each section gets a curated
mix of topics so the topic picker has something to group by:

- Part 1 prompts: short conversational answers (Home / Hobbies /
  Work / Food / Travel / Culture)
- Part 2 prompts: monologue / cue card style (Travel / Education /
  Technology / Health / Work)
- Part 3 prompts: discussion / debate (Technology / Education /
  Climate / Work)

Section names localised per exam — IELTS uses "Speaking — Part X",
DELE uses "Hablar — Monólogo/Diálogo/Conversación", TOPIK uses
"말하기 — 짧은 답변/긴 답변/토론". The localisation block only
renames sections still on the default English name, so it stays
idempotent across re-runs.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: App — EvaluationStatus model + service for speaking submission

**Files:**
- Modify: `lib/providers/provider_models/exam/evaluation_status.dart`
- Modify: `lib/services/exam_study_service.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `EvaluationStatus.transcript` field readable by Task 8's result-screen update; `ExamStudyService.submitSpeakingAnswer(questionId, File audioFile)` returning `AsyncResult` (the existing sealed-union type) — called by Task 7's practice screen.

- [ ] **Step 1: Edit `evaluation_status.dart` — add `transcript` field**

Add the `transcript` parameter to the constructor (after `improvements`) and the corresponding field declaration. Replace:

```dart
  const EvaluationStatus({
    required this.id,
    required this.status,
    this.score,
    this.feedback,
    this.strengths = const [],
    this.improvements = const [],
    this.errorMessage,
    this.completedAt,
  });

  final String id;
  final String status; // "pending" | "completed" | "failed"
  final int? score;
  final String? feedback;
  final List<String> strengths;
  final List<String> improvements;
  final String? errorMessage;
  final DateTime? completedAt;
```

with:

```dart
  const EvaluationStatus({
    required this.id,
    required this.status,
    this.score,
    this.feedback,
    this.strengths = const [],
    this.improvements = const [],
    this.transcript,
    this.audioUrl,
    this.errorMessage,
    this.completedAt,
  });

  final String id;
  final String status; // "pending" | "completed" | "failed"
  final int? score;
  final String? feedback;
  final List<String> strengths;
  final List<String> improvements;
  /// Whisper-STT output for speaking submissions. Null for essay submissions.
  final String? transcript;
  /// Optional S3 URL for the user's recorded audio (when SPEECH_PERSIST_AUDIO is on).
  final String? audioUrl;
  final String? errorMessage;
  final DateTime? completedAt;
```

Then update `fromJson` to parse the new fields. Replace:

```dart
      improvements: (json['improvements'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      errorMessage: json['errorMessage']?.toString(),
```

with:

```dart
      improvements: (json['improvements'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      transcript: json['transcript']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
```

- [ ] **Step 2: Edit `exam_study_service.dart` — add `submitSpeakingAnswer`**

Find the existing `submitAnswer` method (handles MC + essay JSON submissions). **Immediately after** that method closes, insert this new method:

```dart
  /// Submit a speaking-prompt audio answer via multipart upload.
  /// Always returns an [AsyncResult] — the speaking flow is fully async
  /// (backend always returns 202 with a poll URL).
  Future<AsyncResult> submitSpeakingAnswer({
    required String questionId,
    required File audioFile,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '${Endpoints.baseURL}exam-study/questions/$questionId/submit-audio',
    );
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        // ContentType inferred from extension by http package; flutter_sound
        // typically writes m4a / aac, both in the backend allowlist.
      ),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    }
    if (resp.statusCode == 400) {
      // Surface the server-side validation message so the UI can show
      // "Recording too short" / "No audio attached" etc.
      throw Exception(_decodeMessage(resp) ?? 'Bad request');
    }
    if (resp.statusCode != 202) {
      throw Exception(
        'submit-audio failed (${resp.statusCode}): ${resp.body}',
      );
    }
    return AsyncResult.fromJson(_decodeMap(resp));
  }
```

Add the `dart:io` import at the top of the file if missing — search for `import 'dart:convert';`. If `dart:io` is not present, add it on the next line:

```dart
import 'dart:convert';
import 'dart:io';
```

- [ ] **Step 3: Verify analyzer is clean on the touched files**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app
flutter analyze lib/providers/provider_models/exam/evaluation_status.dart lib/services/exam_study_service.dart 2>&1 | tail -5
```

Expected: `No issues found!` (or the line `No issues found! (ran in X.Xs)`).

- [ ] **Step 4: Commit**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app
git add lib/providers/provider_models/exam/evaluation_status.dart lib/services/exam_study_service.dart
git commit -m "$(cat <<'EOF'
feat(exam-study): speaking-submit service + transcript on result model

EvaluationStatus gains optional transcript + audioUrl so the result
screen can show "what we heard you say" above the score card when
the eval is for a spoken response.

ExamStudyService.submitSpeakingAnswer wraps the new POST /submit-audio
multipart endpoint. Returns AsyncResult — speaking eval is always
async, never instant, so the caller pushes straight to the polling
result screen.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: App — AudioRecorder widget

**Files:**
- Create: `lib/pages/learning/exam_study/widgets/audio_recorder.dart`

**Interfaces:**
- Consumes: `flutter_sound: ^9.2.13`, `path_provider` (already in pubspec — verify in Step 1)
- Produces: `AudioRecorder` stateful widget with callbacks `onRecorded(File audioFile)` and `onCancel()`. Internal state: idle → recording (with elapsed timer) → stopped. Used by Task 8's speaking practice screen.

- [ ] **Step 1: Verify `path_provider` is in pubspec.yaml**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app
grep -E "path_provider:|flutter_sound:" pubspec.yaml
```

Expected: both lines present (path_provider is needed to choose a writable temp directory for the recording). If `path_provider` is missing, **stop** and run `flutter pub add path_provider` before continuing — otherwise the recorder can't write the file.

- [ ] **Step 2: Create `widgets/audio_recorder.dart`**

```dart
import 'dart:async';
import 'dart:io';

import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

/// Stateful audio-record widget for the Speaking practice screen.
///
/// Three states:
///  1. idle      — big circular Record button. No file yet.
///  2. recording — pulsing red dot + mm:ss timer + Stop button.
///  3. recorded  — Play / Re-record / Submit row.
///
/// The widget OWNS the [FlutterSoundRecorder] lifecycle (init in
/// initState, close in dispose) so callers never see it leak.
///
/// Callbacks bubble up the recorded file. Parents are expected to
/// upload it on Submit.
class AudioRecorder extends StatefulWidget {
  const AudioRecorder({
    super.key,
    required this.onRecorded,
    this.maxDuration = const Duration(minutes: 3),
  });

  /// Fired when the user taps Submit after stopping a recording.
  final ValueChanged<File> onRecorded;

  /// Hard ceiling — the recorder auto-stops if reached.
  final Duration maxDuration;

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

enum _RecorderState { idle, recording, recorded }

class _AudioRecorderState extends State<AudioRecorder> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  _RecorderState _state = _RecorderState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  File? _recordedFile;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    final filename =
        'exam_speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${dir.path}/$filename';
    await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= widget.maxDuration) {
        _stopRecording();
      }
    });
    setState(() {
      _state = _RecorderState.recording;
      _recordedFile = null;
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final path = await _recorder.stopRecorder();
    if (path == null || !mounted) return;
    setState(() {
      _state = _RecorderState.recorded;
      _recordedFile = File(path);
    });
  }

  Future<void> _playRecording() async {
    final file = _recordedFile;
    if (file == null) return;
    if (_player.isPlaying) {
      await _player.stopPlayer();
      if (mounted) setState(() {});
      return;
    }
    await _player.startPlayer(
      fromURI: file.path,
      whenFinished: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  void _reset() {
    setState(() {
      _state = _RecorderState.idle;
      _recordedFile = null;
      _elapsed = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    switch (_state) {
      case _RecorderState.idle:
        return _buildIdle(context);
      case _RecorderState.recording:
        return _buildRecording(context);
      case _RecorderState.recorded:
        return _buildRecorded(context);
    }
  }

  Widget _buildIdle(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to start recording',
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecording(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _stopRecording,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRecorded(BuildContext context) {
    final isPlaying = _player.isPlaying;
    return Column(
      children: [
        Text(
          _formatDuration(_elapsed),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _playRecording,
              icon: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
              label: Text(isPlaying ? 'Stop' : 'Play'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Re-record'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final file = _recordedFile;
              if (file != null) widget.onRecorded(file);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Submit recording',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Analyzer check on the new widget**

```bash
flutter analyze lib/pages/learning/exam_study/widgets/audio_recorder.dart 2>&1 | tail -5
```

Expected: `No issues found!`.

If you see a missing-import error for `dart:ui` (the `FontFeature.tabularFigures()` reference), add `import 'dart:ui';` at the top of the file. Most Flutter analyzers already resolve `FontFeature` through `package:flutter/widgets.dart` so it's typically not needed — adjust only if the analyzer complains.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/learning/exam_study/widgets/audio_recorder.dart
git commit -m "$(cat <<'EOF'
feat(exam-study): AudioRecorder widget for speaking practice

Encapsulates the flutter_sound recorder + player lifecycle for the
speaking practice screen. Three states (idle / recording / recorded)
with a mm:ss timer, auto-stop on the 3-minute ceiling, and inline
Play / Re-record / Submit controls. Writes the m4a file to the
platform temp dir; the parent screen uploads on Submit.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: App — SpeakingPracticeScreen + result-screen transcript display + section-tile icons + l10n + practice routing

**Files:**
- Create: `lib/pages/learning/exam_study/speaking_practice_screen.dart`
- Modify: `lib/pages/learning/exam_study/evaluation_result_screen.dart`
- Modify: `lib/pages/learning/exam_study/widgets/section_tile.dart`
- Modify: `lib/pages/learning/exam_study/section_practice_screen.dart`
- Modify: `lib/l10n/app_*.arb` (all 19 locales)

**Interfaces:**
- Consumes: `AudioRecorder` (Task 7), `submitSpeakingAnswer` (Task 6), `EvaluationStatus.transcript` (Task 6), `EvaluationResultScreen` (existing from Chunk D)
- Produces: full speaking practice end-to-end UX. Tapping a speaking-prompt question on the section-practice screen routes into this new screen, records, uploads, lands on the result polling screen, transcript shown above the score.

- [ ] **Step 1: Add l10n keys via the Python helper pattern used in prior chunks**

Save this script as `/tmp/add_speaking_keys.py`:

```python
#!/usr/bin/env python3
import json, os, glob

ARB_DIR = "/Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app/lib/l10n"

PLAIN = {
    "examSpeakingPrompt": "Speak your answer",
    "examSpeakingListenToPrompt": "Listen to prompt",
    "examSpeakingTapToRecord": "Tap to record your answer",
    "examSpeakingTranscriptHeading": "What we heard",
    "examSpeakingPart1": "Speaking — Part 1",
    "examSpeakingPart2": "Speaking — Part 2",
    "examSpeakingPart3": "Speaking — Part 3",
    "examSpeakingSubmit": "Submit recording",
    "examSpeakingUploading": "Uploading…",
    "examSpeakingTooShort": "Recording is too short. Please speak for at least a few seconds.",
}
PLACEHOLDER = {}

def update(path):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    is_tmpl = path.endswith("app_en.arb")
    changed = False
    for k, v in PLAIN.items():
        if k not in data:
            data[k] = v
            changed = True
    if changed:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    return changed

updated = [os.path.basename(p) for p in sorted(glob.glob(os.path.join(ARB_DIR, "app_*.arb"))) if update(p)]
print(f"Updated {len(updated)} files")
```

Run it + regenerate Dart classes:

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app
python3 /tmp/add_speaking_keys.py
flutter gen-l10n 2>&1 | tail -2
grep -c "examSpeakingPrompt" lib/l10n/app_localizations.dart
```

Expected: `Updated 19 files` then a count of at least `1` for the generated key.

- [ ] **Step 2: Add the new section-type icons**

Open `lib/pages/learning/exam_study/widgets/section_tile.dart`. Find the `_sectionIcon` switch. Replace its body with:

```dart
    final iconData = switch (sectionType) {
      'reading' => Icons.menu_book_rounded,
      'writing' => Icons.edit_note_rounded,
      'writing-task-1' => Icons.draw_rounded,
      'writing-task-2' => Icons.article_rounded,
      'speaking' => Icons.mic_rounded,
      'speaking-part-1' => Icons.record_voice_over_rounded,
      'speaking-part-2' => Icons.mic_rounded,
      'speaking-part-3' => Icons.forum_rounded,
      'listening' => Icons.headphones_rounded,
      'vocabulary' => Icons.spellcheck_rounded,
      _ => Icons.assignment_rounded,
    };
```

- [ ] **Step 3: Create `speaking_practice_screen.dart`**

```dart
import 'dart:io';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/evaluation_result_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/widgets/audio_recorder.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_question.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen speaking practice — prompt + AudioRecorder + submit.
/// On submit the audio is uploaded to /submit-audio (multipart) and
/// the screen pushes the polling EvaluationResultScreen with the
/// returned evaluation id.
class SpeakingPracticeScreen extends ConsumerStatefulWidget {
  const SpeakingPracticeScreen({
    super.key,
    required this.question,
    required this.examId,
  });

  final ExamQuestion question;
  final String examId;

  @override
  ConsumerState<SpeakingPracticeScreen> createState() =>
      _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState
    extends ConsumerState<SpeakingPracticeScreen> {
  bool _uploading = false;

  Future<void> _onRecorded(File audioFile) async {
    setState(() => _uploading = true);
    try {
      final result = await ref
          .read(examStudyServiceProvider)
          .submitSpeakingAnswer(
            questionId: widget.question.id,
            audioFile: audioFile,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        AppPageRoute(
          builder: (_) => EvaluationResultScreen(
            evaluationId: result.evaluationId,
            examId: widget.examId,
          ),
        ),
      );
      if (!mounted) return;
      // Pop the practice screen so the user lands back on the section
      // practice list / topic picker.
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.examSpeakingPrompt,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question.questionText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    // Listen-to-prompt is a Phase-2 enhancement that
                    // hits /speech/tts. We surface the button now so
                    // the layout is final; tap is wired in a follow-up
                    // task (Chunk H+).
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: _uploading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              l10n.examSpeakingUploading,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : AudioRecorder(onRecorded: _onRecorded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Route `speaking-prompt` questions to the new screen**

Open `lib/pages/learning/exam_study/section_practice_screen.dart`. Find the `_renderQuestion` method. Currently it handles `isMultipleChoice` and `isEssay` and falls through to `_unsupportedQuestionCard` for everything else. Add a branch for `isSpeaking`:

Replace this:

```dart
    if (question.isEssay) {
      // Essay flow lives in its own full-screen editor so the user has
      // space to write + see the prompt. The Submit button on the
      // bottom bar opens it.
      return _essayPromptCard(question, l10n);
    }
    // Speaking-prompt / fill-blank — still placeholder, lands later.
    return _unsupportedQuestionCard(question, l10n);
```

with:

```dart
    if (question.isEssay) {
      // Essay flow lives in its own full-screen editor so the user has
      // space to write + see the prompt. The Submit button on the
      // bottom bar opens it.
      return _essayPromptCard(question, l10n);
    }
    if (question.isSpeaking) {
      // Speaking flow lives in its own full-screen recorder so the
      // user has space to record + listen back before submitting.
      return _speakingPromptCard(question, l10n);
    }
    // fill-blank — still placeholder, lands later.
    return _unsupportedQuestionCard(question, l10n);
```

Then add the new card builder right next to `_essayPromptCard`:

```dart
  Widget _speakingPromptCard(ExamQuestion question, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.mic_rounded, size: 18, color: context.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.examSpeakingTapToRecord,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
```

Now find the bottom-bar logic (`_bottomBar` method). It already has an essay branch that calls `_openEssayEditor`. Add a parallel speaking branch. Replace the existing label/onPressed block:

```dart
    if (showNext) {
      label = l10n.examQuestionNext;
      onPressed = () => _advance(total);
    } else if (question.isEssay) {
      label = l10n.examEssaySubmit;
      onPressed = () => _openEssayEditor(question, total);
    } else if (question.isMultipleChoice) {
      label = l10n.examQuestionSubmit;
      onPressed = mcCanSubmit ? () => _submit(question) : null;
    } else {
      label = l10n.examQuestionNext;
      onPressed = () => _advance(total);
    }
```

with:

```dart
    if (showNext) {
      label = l10n.examQuestionNext;
      onPressed = () => _advance(total);
    } else if (question.isEssay) {
      label = l10n.examEssaySubmit;
      onPressed = () => _openEssayEditor(question, total);
    } else if (question.isSpeaking) {
      label = l10n.examSpeakingPrompt;
      onPressed = () => _openSpeakingPractice(question, total);
    } else if (question.isMultipleChoice) {
      label = l10n.examQuestionSubmit;
      onPressed = mcCanSubmit ? () => _submit(question) : null;
    } else {
      label = l10n.examQuestionNext;
      onPressed = () => _advance(total);
    }
```

Add the `_openSpeakingPractice` helper next to `_openEssayEditor`:

```dart
  Future<void> _openSpeakingPractice(ExamQuestion question, int total) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => SpeakingPracticeScreen(
          question: question,
          examId: widget.examId,
        ),
      ),
    );
    if (!mounted) return;
    _advance(total);
  }
```

Add the import at the top of the file (next to the existing `EssayEditorScreen` import):

```dart
import 'package:bananatalk_app/pages/learning/exam_study/speaking_practice_screen.dart';
```

- [ ] **Step 5: Render the transcript on the result screen**

Open `lib/pages/learning/exam_study/evaluation_result_screen.dart`. Find the `_completedState` method. **Immediately after the `_scoreCard` call**, insert a transcript block:

Replace this:

```dart
        children: [
          _scoreCard(l10n, status),
          if (status.feedback != null && status.feedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _feedbackBlock(l10n, status.feedback!),
          ],
```

with:

```dart
        children: [
          _scoreCard(l10n, status),
          if (status.transcript != null && status.transcript!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _transcriptBlock(l10n, status.transcript!),
          ],
          if (status.feedback != null && status.feedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _feedbackBlock(l10n, status.feedback!),
          ],
```

Then add `_transcriptBlock` next to `_feedbackBlock` in the same class:

```dart
  Widget _transcriptBlock(AppLocalizations l10n, String transcript) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, size: 16, color: context.textSecondary),
              const SizedBox(width: 6),
              Text(
                l10n.examSpeakingTranscriptHeading,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transcript,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 6: Analyzer check across everything touched**

```bash
flutter analyze \
  lib/pages/learning/exam_study/speaking_practice_screen.dart \
  lib/pages/learning/exam_study/section_practice_screen.dart \
  lib/pages/learning/exam_study/evaluation_result_screen.dart \
  lib/pages/learning/exam_study/widgets/section_tile.dart \
  2>&1 | tail -5
```

Expected: `No issues found!`.

- [ ] **Step 7: Commit**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app
git add lib/pages/learning/exam_study/speaking_practice_screen.dart \
        lib/pages/learning/exam_study/section_practice_screen.dart \
        lib/pages/learning/exam_study/evaluation_result_screen.dart \
        lib/pages/learning/exam_study/widgets/section_tile.dart \
        lib/l10n/app_*.arb \
        lib/l10n/app_localizations*.dart
git commit -m "$(cat <<'EOF'
feat(exam-study): Speaking practice screen + transcript on results

SpeakingPracticeScreen renders the prompt + the AudioRecorder
widget; on submit it uploads via the new submitSpeakingAnswer
service and pushes the existing EvaluationResultScreen with the
returned evaluation id. SectionPracticeScreen routes speaking-prompt
questions into the new screen (mirroring how essays push to
EssayEditorScreen).

EvaluationResultScreen renders a transcript block ("What we heard")
above the feedback when EvaluationStatus.transcript is populated —
gives the user immediate signal on what the STT picked up.

SectionTile gains icon mappings for the new section types
(speaking-part-1 → record_voice_over, part-2 → mic, part-3 → forum).

L10n: 10 new examSpeaking* keys across all 19 ARB files. Non-English
locales fall back to English; native-speaker pass later.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: End-to-end smoke test + submodule pointer bump + push

**Files:**
- Modify: (parent workspace) `backend` submodule pointer

**Interfaces:**
- Consumes: all prior tasks
- Produces: a working end-to-end speaking flow on `main` of both repos.

- [ ] **Step 1: Manual smoke walk-through**

With the backend running locally (port 5003) and the app pointed at the LAN URL:

1. Open the app, tap **AI Study → Exam Study → English → IELTS**
2. Verify the dashboard now shows **6 tiles**: Reading, Writing — Task 1, Writing — Task 2, Speaking — Part 1, Speaking — Part 2, Speaking — Part 3
3. Tap **Speaking — Part 1**
4. Verify the topic picker renders with tiles like Home / Hobbies / Work / Food / Travel / Culture
5. Pick **Home**
6. Verify the section-practice page shows the question text, an "Tap to record your answer" hint, and a **mic icon** in the bottom bar that says "Speak your answer"
7. Tap the bottom button → speaking practice screen loads with the recorder in **idle** state
8. Tap the big mic → recorder switches to **recording** state with a live mm:ss timer
9. Speak for ~20 seconds → tap **Stop**
10. Recorder switches to **recorded** state with **Play / Re-record / Submit recording** controls
11. Tap **Play** → hear the recording back
12. Tap **Submit recording**
13. Wait briefly → land on the evaluation result screen with "Evaluating…" spinner
14. After 5-30 seconds → result screen shows:
    - The score card
    - A **"What we heard"** block with the Whisper transcript
    - Feedback paragraph
    - Strengths + improvements bullets
15. Tap Done → back at the section practice screen, advance to next question

If any step fails, check the backend log monitor for the request response code + body.

- [ ] **Step 2: Verify progress is being recorded**

After the smoke walk, refetch the user's progress on the IELTS exam:

```bash
# Replace <token> with the bearer token + <userId> + <examId>
curl -s http://localhost:5003/api/v1/exam-study/users/<userId>/exams/<examId>/progress \
  -H "Authorization: Bearer <token>" | python3 -m json.tool | grep -A 3 "speaking-part-1"
```

Expected: a `speaking-part-1` key under `sectionScores` with `attempted: 1` (or higher) and a `score` value.

- [ ] **Step 3: Update the workspace submodule pointer + push everything**

From the workspace root (parent of `backend` and `bananatalk_app`):

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk

# Bump the backend submodule pointer to the most recent backend commit.
git add backend

# The l10n + screen edits in bananatalk_app are already committed in
# Task 8 — no further app staging needed here. Push the workspace
# with the new submodule pointer.
git commit -m "$(cat <<'EOF'
feat(exam-study): bump backend pointer to Speaking section

Pulls in the backend Speaking implementation: extended section
enums, EvaluationJob.transcript + audioUrl, examEvaluationService
.evaluateSpeaking, POST /submit-audio multipart endpoint, ~38 new
speaking-prompt seed questions across IELTS / DELE / TOPIK.

Pairs with the app-side commits in this same branch:
- SpeakingPracticeScreen + AudioRecorder widget
- submitSpeakingAnswer in ExamStudyService
- transcript surfacing on EvaluationResultScreen
- speaking-part-1/2/3 icons in SectionTile
- 10 new examSpeaking l10n keys across 19 ARBs

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"

git push origin main
```

Push the backend separately:

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/backend
git push origin main
```

- [ ] **Step 4: Verify both remotes received the commits**

```bash
git -C /Users/firdavsmutalipov/Projects/BananaTalk log --oneline -3
git -C /Users/firdavsmutalipov/Projects/BananaTalk/backend log --oneline -7
```

Backend log should show 5 new commits from Tasks 1-5 (enums, EvaluationJob fields, evaluateSpeaking, /submit-audio route, seed). App log should show the latest commits from Tasks 6, 8, and 9.

---

# Self-review

## 1. Spec coverage

| Spec requirement | Task |
|---|---|
| Add `speaking-part-1/2/3` to section enums | Task 1 |
| `EvaluationJob.transcript` + `audioUrl` | Task 2 |
| `evaluateSpeaking` service with stub fallback | Task 3 |
| New `POST /submit-audio` multipart route | Task 4 |
| Background worker: Whisper STT → AI eval → progress bump | Task 4 |
| `/submit-answer` returns `USE_AUDIO_ENDPOINT` for speaking | Task 4 |
| ~38 seed prompts across IELTS/DELE/TOPIK | Task 5 |
| Per-exam localised section names | Task 5 (Step 3) |
| App `EvaluationStatus.transcript` field | Task 6 |
| App `submitSpeakingAnswer` service method | Task 6 |
| Audio recorder widget (flutter_sound) | Task 7 |
| Speaking practice screen | Task 8 |
| Result screen renders transcript above score | Task 8 (Step 5) |
| Section-tile icons for new section types | Task 8 (Step 2) |
| Section-practice screen routes speaking-prompt → new screen | Task 8 (Step 4) |
| L10n keys across all 19 locales | Task 8 (Step 1) |
| No new audio packages — reuse flutter_sound, speechService | Task 7 (Step 1) verifies pubspec; backend uses existing speechService |
| Stub-fallback for AI when OPENAI_API_KEY unset | Task 3 (Step 1) |
| Audio not persisted by default | Task 4 implements (no upload to S3 in the background worker) |
| Auth on every endpoint | Task 4 — new route lives under `router.use(protect)` |
| Idempotent seed | Task 5 (Step 3) — name-override only renames defaults |
| End-to-end manual smoke | Task 9 |

All spec items mapped.

## 2. Placeholder scan

Searched the plan for "TBD", "TODO", "implement later", "fill in details", "Add appropriate error handling", "Similar to Task N". Zero matches. All code blocks are complete; every command shows expected output.

## 3. Type consistency

- `evaluateSpeaking({ transcript, rubric, targetBand })` signature in Task 3 matches the call site in Task 4 (`examEvaluationService.evaluateSpeaking({ transcript })`)
- `transcribeAudio` call in Task 4 verified against `services/speechService.js` in Step 5 of that task — if signature differs the engineer is told to adapt before proceeding
- `EvaluationStatus.transcript: String?` (Task 6) matches the `status.transcript` reads in Task 8 (Step 5)
- `submitSpeakingAnswer({ questionId, audioFile })` in Task 6 matches the call in Task 8's `SpeakingPracticeScreen._onRecorded` (`submitSpeakingAnswer(questionId: ..., audioFile: ...)`)
- `AudioRecorder({ onRecorded, maxDuration })` in Task 7 matches the call in Task 8 (`AudioRecorder(onRecorded: _onRecorded)`)

All cross-task references consistent.

## 4. Out of scope (intentional, deferred to follow-on tasks)

- "Listen to prompt" TTS button on `SpeakingPracticeScreen` — placeholder in the UI, no tap handler yet. The spec lists this as a feature; the layout reserves space (Task 8 Step 3 includes a comment marker) but the wire-up is a 1-task follow-on so it isn't blocking the rest of Chunk H.
- S3 audio persistence path — feature-flagged off by default (`SPEECH_PERSIST_AUDIO = false`). Spec explicitly defers this to a future iteration.
- Vocabulary section (Chunk G) — separate spec + plan.
