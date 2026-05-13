# Step 9 — AI Tutor wave: What Shipped

**Date completed:** 2026-05-13
**Total commits:** 38 across both repos
**Branches merged + pushed:** 4 sub-wave merges to `main` (A1, A2, B1, B2, B3, C; each its own feature branch, all deleted post-merge)
**Result:** The AI surface went from "7 disconnected tile-based tools" to "a personalized tutor that knows the user, plus 5 features that plug into it."

---

## Why this wave

The pre-Step-9 AI surface was **broad but shallow and disconnected**. Seven AI features (AI Conversation, Grammar, Lesson Builder, Pronunciation, Quiz, Translation, Speech) each lived on their own tile, each in their own context. Users had to know which tool to open. Nothing remembered them between sessions. Nothing coordinated across features.

Step 9 introduced a **persistent, personalized AI Tutor** plus four supporting features layered on top, and made the existing 7 features smarter using the tutor's memory.

---

## Sub-wave shape

```
A1  Foundation   ── persona + chat + memory + daily plan + 3 cards
A2  Voice        ── 🎤 toggle + TTS + STT + 2 more cards
B1  Roleplay     ── 6 scenarios + goal banner + 0-100 grading
B2  Story        ── graded reader + comprehension Qs
B3  Image-vocab  ── gpt-4o vision describe-and-grade
C   Deepen       ── adaptive quiz + chat memory + translation/grammar polish
```

---

## A1 — Foundation (14 commits)

**Persona system:**
- 3 named characters with distinct teaching styles:
  - **Nana 🐻** — warm, encouraging, light emoji
  - **Sensei 🤖** — precise, exam-focused, no emoji
  - **Riko 🐙** — playful, slangy, makes jokes
- Picked at first run via `PersonaPickerScreen`, switchable from drawer
- Each persona = same `gpt-4o-mini` + a different system-prompt overlay

**TutorMemory model** (per-user, 1 Mongo doc, ~2KB):
- Persona pick, proficiency level (mirrored from `LearningProgress`), target languages, native language
- `weakAreas: [{topic, frequency, lastSeen}]` (max 10, hydrated by hooks from grammar feedback + wrong quiz answers)
- `vocabFocus: [{wordId, status, lastReviewed}]` (max 20, from `Vocabulary` collection)
- `recentChatSummaries: [{summary, createdAt}]` (rolling 5, generated when sessions end)
- `dailyPlan: {date, tasks: [...]}` (lazy-generated per UTC day)

**AITutorSession model:**
- Per-conversation doc with full message history
- `messageType` enum extended to support cards (`text` / `quiz_card` / `vocab_card` / `grammar_card`)

**Backend (~6 commits):**
- `models/TutorMemory.js`, `models/AITutorSession.js`
- `services/tutorService.js` — persona-aware prompt builder, JSON-mode `gpt-4o-mini` call wrapper, defensive parser, daily-plan generator, session summarizer
- `controllers/tutor.js` — 8 endpoints (read 4 + chat lifecycle 3 + task complete 1)
- `routes/tutor.js` + `tutorMessageLimiter` (30/min/user to cap OpenAI cost)
- Memory hooks in `controllers/grammarFeedback.js` + `controllers/learning.js` — fire-and-forget weakArea bumps on grammar mistakes + wrong quiz answers

**Flutter (~7 commits):**
- `lib/services/livekit_service.dart` ← no, scratch (that was Step 8). Step 9 Flutter:
- `lib/providers/tutor_provider.dart` — Riverpod state (memory / plan / sessions) + `TutorChatController` with optimistic user-message append
- `lib/models/tutor/tutor_memory.dart`, `tutor_session.dart`
- `lib/pages/ai/tutor/persona_picker_screen.dart`, `tutor_home_screen.dart`, `tutor_chat_screen.dart`
- `lib/widgets/tutor/quiz_card.dart`, `vocab_card.dart`, `grammar_card.dart` — interactive cards rendered inline in the chat
- Tutor hero card injected at the top of `ai_main.dart`; "Change AI tutor" entry in profile drawer
- 27 new English l10n keys (template-fallback for other locales)

**API surface added:**
```
GET    /api/v1/tutor/me                              TutorMemory (lazy-create)
PUT    /api/v1/tutor/persona                         set persona
GET    /api/v1/tutor/daily-plan                      today's plan (lazy)
PATCH  /api/v1/tutor/daily-plan/task/:type/complete  bump task progress
GET    /api/v1/tutor/sessions                        recent sessions
POST   /api/v1/tutor/sessions                        start free chat
GET    /api/v1/tutor/sessions/:id                    session detail
POST   /api/v1/tutor/sessions/:id/message            user → AI reply (may be card)
POST   /api/v1/tutor/sessions/:id/end                end + summarize + bump task
```

---

## A2 — Voice (7 commits)

**Full audio loop in the chat:**
- AppBar 🔊 toggle → voice mode
- 🎤 mic button → record (`FlutterSoundRecorder` + .aac codec) → POST `/tutor/sessions/:id/transcribe` → user message auto-sent
- When voice mode on: every new AI reply → POST `/tutor/sessions/:id/speak` → audio URL played via `just_audio`
- Existing `speechService` reused (already had Spaces upload + caching + Whisper)
- iOS audio session config + `UIBackgroundModes: voip` ← already in place from Step 8 LiveKit work

**New card types:**
- **`srs_due_card`** (orange) — "N cards waiting" + 3-row preview + "Review now" CTA
- **`mini_lesson_card`** (indigo) — title + 3 bullets + optional "Try it" CTA
- Both added to `AITutorSession.messageType` enum and `tutorService` response schema
- Chat bubble dispatcher updated to route the new types

**API additions:**
```
POST  /api/v1/tutor/sessions/:id/speak        (TTS)
POST  /api/v1/tutor/sessions/:id/transcribe   (STT, multipart audio)
```

**Files added:** `lib/services/tutor_voice_service.dart`, `lib/widgets/tutor/srs_due_card.dart`, `lib/widgets/tutor/mini_lesson_card.dart`

---

## B1 — Roleplay (5 commits)

**Six scenario library** in `services/tutorScenarios.js`:
| Scenario | Emoji | Goal |
|---|---|---|
| Order at a restaurant | 🍝 | 2-course meal + bill |
| Job interview | 💼 | Strong 5-min first impression |
| Hotel check-in | 🏨 | Confirm + ask about amenities |
| Ask for directions | 🧭 | Find the train station |
| Doctor visit | 🩺 | Describe symptom + get next steps |
| Coffee shop | ☕ | Drink + one customization |

Each has `aiRole` (system-prompt fragment), `successCriteria[]`, `minTurns`.

**Flow:**
1. User opens scenario picker from TutorHome
2. Picks scenario → `POST /tutor/sessions/roleplay` → AI greets in character
3. Conversation proceeds with `mode: 'roleplay'` — server forces text-only (cards never break character)
4. AppBar "End" → POST `/end` → `gradeScenario` judge call → bottom-sheet scoreboard with 0-100 score + 2-3 sentence feedback (color-coded green/orange/red)

**API additions:**
```
GET   /api/v1/tutor/scenarios
POST  /api/v1/tutor/sessions/roleplay  body: { scenarioId }
```

**Files added:** `services/tutorScenarios.js`, `lib/pages/ai/tutor/scenario_picker_screen.dart`, `lib/pages/ai/tutor/roleplay_chat_screen.dart` + DTOs

---

## B2 — Story generator (5 commits)

**Graded-reader generator** with built-in comprehension Qs:
- User picks word count (3/5/10) + theme (🎲 free / 🗺️ adventure / 🔍 mystery / 💌 romance / 🚀 sci-fi / ☕ slice of life)
- Backend pulls up to 15 of the user's most-recent "learning" vocab from `Vocabulary`
- AI generates a **4-paragraph story at the user's CEFR level**, weaving in vocab, plus one MCQ per paragraph and a `vocabUsed` roll-up
- Stateless — no persistence; Flutter holds it for the session

**Reader screen:**
- Paragraph-by-paragraph reveal
- Answering the comprehension Q (correct or wrong) unlocks next paragraph
- AppBar toggle reveals vocab panel (word + native-language definition)
- Final "Nice work!" summary with N/N comprehension score

**API addition:**
```
POST  /api/v1/tutor/stories/generate  body: { wordCount?, theme? }
```

**Files added:** `services/tutorStoryService.js`, `lib/pages/ai/tutor/story_setup_screen.dart`, `lib/pages/ai/tutor/story_reader_screen.dart` + DTO

---

## B3 — Image-vocab (3 commits)

**The only Step 9 feature using `gpt-4o` (not mini)** — vision support requires it.

**Two-step flow:**
1. User takes photo or picks from gallery (`image_picker`)
2. Step 1: `POST /tutor/image-vocab/describe` — AI looks at image, returns `{prompt: '<target-language ask>', suggestedVocab: [...]}` (4-6 items visible in the scene)
3. User types description in target language
4. Step 2: `POST /tutor/image-vocab/grade` — AI grades it. Returns `{score 0-100, feedback in native language, grammarNotes: [{wrong, correct, note}], missingItems: [strings]}`

**Image handling:**
- Multer memory storage, 10MB cap, JPEG/PNG/WebP/HEIC/HEIF allowed
- Image NOT persisted — in memory for request duration only
- Base64 data URL with `detail: 'low'` to cap vision-input tokens (~85 per image, $0.005-0.01 per call)

**Files added:** `services/tutorImageVocabService.js`, `lib/pages/ai/tutor/image_vocab_screen.dart`

---

## C — Deepen existing AI (4 commits)

The 7 pre-Step-9 AI features benefit from the tutor's memory infrastructure:

| # | Improvement | Where |
|---|---|---|
| C1 | **Adaptive AI quiz** — `aiQuizService` now reads `TutorMemory.weakAreas` (3rd signal on top of quiz-history accuracy + vocab SRS) | `services/aiQuizService.js` |
| C2 | **AI conversation cross-session memory** — system prompt now includes a USER MEMORY block (last-chat summary + top 2 weak areas) | `services/aiConversationService.js` |
| C3 | **Translation save-to-vocab** — one-tap bookmark button on translation results | `lib/pages/ai/translation/translation_screen.dart` |
| C4 | **Grammar feedback "Why?" block** — rule + explanation merged into one prominent panel with lightbulb header | `lib/pages/ai/grammar/grammar_feedback_screen.dart` |

---

## Tally — what's in the app now

**AI Tutor surface (Step 9):**
- 1 persona picker
- 1 tutor home screen (greeting + daily plan + 4 mode entries + recent sessions)
- 4 chat-mode screens (free chat / roleplay / story setup / story reader / image-vocab)
- 5 inline card widgets (quiz / vocab / grammar / SRS-due / mini-lesson)
- Voice service (recorder + player + STT/TTS calls)
- TutorMemory + AITutorSession Mongo models
- 6 scenarios in the catalog

**Existing AI tools (untouched UI, smarter internals):**
- AI Lessons, Grammar Check, Pronunciation, Translation, AI Quizzes, Lesson Builder

**Backend API new endpoints:**
- 14 new routes under `/api/v1/tutor/*`

**Files added:** ~17 Flutter files, ~7 Backend files

---

## Cost ballpark

Per user per session at typical usage:
- 1 chat turn: ~$0.005 (`gpt-4o-mini`, 600 max tokens)
- 1 roleplay session (8 turns + grading): ~$0.05
- 1 story generation: ~$0.02 (4 paragraphs + Qs + vocab)
- 1 image-vocab grade: ~$0.01 (`gpt-4o`, low-detail image)
- 1 voice round-trip (TTS + STT): ~$0.01 (cached TTS = free)

**100 daily-active users averaging 5 sessions/day:** ~$25–50/month total. Rate limits (30 chat msgs/min/user, plus existing route-level limiters) cap any single user's burn.

---

## Manual TODOs

- [ ] **Two-device smoke test pass** on iOS sim + physical Android — most of Step 9 hasn't been exercised on a phone yet
- [ ] **Test voice routing** with Bluetooth headset (iOS + Android) since AVAudioSession changes from Step 8 may interact
- [ ] **Verify gpt-4o vision works** end-to-end against the prod OpenAI key (no team has tested describe-a-photo on a real photo yet)
- [ ] **Optionally bump dev rate limits** in `middleware/rateLimiter.js` while iterating
- [ ] **Privacy policy delta** if you're heading to App Store: data sent to OpenAI now includes voice samples + photos
- [ ] **Cost monitoring** — keep an eye on OpenAI usage dashboard for the first week; set a budget alert at $100/mo or wherever feels safe

---

## What's deliberately not done

- **Push notifications from the tutor** — `notificationPreferences.tutor` flag exists in spec, no cron + send logic yet. Deferred to a future wave.
- **Phoneme-level pronunciation feedback** — OpenAI Whisper doesn't expose phonemes; would need a different model
- **Telemetry pipeline** — no analytics yet; we don't know which AI features users actually engage with
- **Persona-level voice variety** — TTS uses one voice across all 3 personas (Nana/Sensei/Riko all sound the same)
- **Story persistence** — generated stories live in memory only; can't revisit
- **Image-vocab "add suggested vocab to my list"** — suggested-vocab chips are display-only
- **Multilingual personas** — system prompts are English; persona "voice" works in target language but feels less localized

---

## Branches + merges (for git archaeology)

| Sub-wave | Flutter merge | Backend merge | Pushed |
|---|---|---|---|
| A1 | `85111b6` | `04f0405` | ✅ |
| A2 | `dbe7146` | `dea34b0` | ✅ |
| B1 | `5e9c6ed` | `56bbd31` | ✅ |
| B2 | `d1a9d97` | `6a782f9` | ✅ |
| B3 | `7ada79a` | `5326a75` | ✅ |
| C | `2f395a3` | `d06c392` | ✅ |

All feature branches deleted post-merge. `main` on both repos is the source of truth.

---

## Specs + plans (committed for reference)

- `docs/superpowers/specs/2026-05-12-step9-ai-tutor-foundation-design.md` (A1 spec)
- `docs/superpowers/plans/2026-05-12-step9-ai-tutor-foundation-a1.md` (A1 plan — 14 detailed tasks)

Sub-waves A2, B1, B2, B3, C had no written spec — built incrementally on top of A1's foundation.

---

## What's next (proposed)

Three honest options for Step 10, in roughly the order I'd argue for them:

1. **Stabilization + Telemetry** — two-device test pass + basic analytics (which AI features actually get used) + cost dashboard
2. **Study menu redesign** — the AI tab now has 10+ entries (6 legacy tile + 4 tutor modes + hero). The structure is hurting discoverability. Worth its own short wave. (See sibling doc.)
3. **Push notifications wave** — convert the daily plan into actual retention pushes

The "make it rich" vision the user asked for is genuinely done. Step 10 should be about making sure people *find* and *return to* what's been built.
