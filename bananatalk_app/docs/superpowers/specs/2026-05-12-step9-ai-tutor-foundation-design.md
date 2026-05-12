# Step 9 — AI Tutor Foundation (Sub-wave A1)

**Date:** 2026-05-12
**Driver:** Davis
**Status:** Draft — pending spec review + user review before plan
**Branch (planned):** `feat/step9-ai-tutor-a1` (off main)
**Scope:** Net-new AI tutor system that becomes the primary entry point for AI learning. Sub-wave A1 ships text-only; voice (A2) is a deferred follow-up wave.

---

## Why this wave

The current AI surface is **broad but shallow and disconnected**. Seven AI features (Conversation, Grammar, Lesson Builder, Pronunciation, Quiz, Translation, Speech) each live on their own tile, each in their own context. Users have to know which tool to open. Nothing remembers them between sessions. Nothing coordinates across features.

Sub-wave A1 introduces a **persistent, personalized AI Tutor** that:

- Has a chosen named persona (one of 3 characters)
- Knows the user's level, target languages, weak areas, vocab focus, and recent chat summaries
- Greets the user with a daily plan when they open the app
- Has a chat-like interface that's the primary entry to AI study
- Can drop interactive **inline cards** into chat (quiz / vocab / grammar) so learning happens inside the conversation, not by linking out

The existing 7 AI tools stay as direct-access power-user surface. The tutor becomes the recommended path.

---

## Strategic context

This is **part 1 of a 3-sub-wave arc**:

- **Sub-wave A (this spec)** — Tutor foundation. A1 ships text. A2 adds voice.
- **Sub-wave B (future)** — New AI features layered on top of the tutor: voice conversations, roleplay scenarios, story generation, image-vocab.
- **Sub-wave C (future)** — Deepen existing AI features: cross-session memory in AI Conversation, "why" explanations in Grammar feedback, adaptive Quiz, phoneme-level Pronunciation feedback.

A is the **spine**. B and C plug into the tutor's memory + persona once it exists.

---

## Sub-wave A1 scope

### Personas (3, pick-one at first-run, switchable from settings)

| Name | Avatar | Personality | Use case |
|---|---|---|---|
| **Nana** | 🐻 | Warm, encouraging, light emoji use, praises effort, gentle corrections | First-time learners, casual users |
| **Sensei** | 🤖 | Precise, exam-focused, formal, references specific rules, structured explanations | TOEFL / JLPT / IELTS prep, serious learners |
| **Riko** | 🐙 | Playful, slangy, makes jokes, uses target-language slang when level allows | Advanced users, casual fun |

Each persona = same underlying AI (`gpt-4o-mini`) + a different system prompt template. Avatars start as emoji renders in widgets; can swap to illustrated art later without backend changes.

### Memory model — `TutorMemory` (Tier 2)

Per user, single Mongo doc, ~2KB. Stored at `/api/v1/tutor/me`.

```
TutorMemory {
  user:               ObjectId (unique index)
  persona:            'nana' | 'sensei' | 'riko'  (null until first pick)
  proficiencyLevel:   'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2'  (mirrored from LearningProgress)
  targetLanguages:    [String]   (from User.languages_to_learn)
  nativeLanguage:     String     (from User.native_language)
  weakAreas:          [{ topic: String, frequency: Number, lastSeen: Date }]   // max 10
  vocabFocus:         [{ wordId: ObjectId, status: 'learning'|'mastered', lastReviewed: Date }]  // max 20
  recentChatSummaries:[{ sessionId: ObjectId, summary: String (≤200 chars), createdAt: Date }]  // rolling 5
  dailyPlan:          DailyPlan?  (subdoc, see below)
  lastSeen:           Date
  createdAt:          Date
}

DailyPlan {
  date:   ISODate (UTC midnight of the day)
  tasks:  [
    { type: 'srs_review',    count: Number,           completed: Number },
    { type: 'grammar_drill', topic:  String,          completed: Boolean },
    { type: 'tutor_chat',    minutes: Number,         completed: Number }
  ]
}
```

**How `TutorMemory` is hydrated:**
- `weakAreas` derived from `grammarFeedback` errors + quiz mistakes (last 30 days, top 10 by frequency)
- `vocabFocus` derived from `Vocabulary` collection (user's "learning" status + recent reviews)
- `recentChatSummaries` appended when an `AITutorSession` ends (rolling 5; trimmed)
- `proficiencyLevel`, `targetLanguages`, `nativeLanguage` joined from `LearningProgress` / `User` at read time (not stored), OR cached on the doc and refreshed lazily — implementer's call

### Sessions — `AITutorSession`

Per conversation. New session each time the user starts a fresh chat (or after long inactivity, e.g. 24h).

```
AITutorSession {
  user:       ObjectId (indexed)
  persona:    String   (snapshot at session start)
  messages:   [Message]
  startedAt:  Date
  endedAt:    Date?
  summary:    String?  (generated when session ends)
}

Message {
  role:        'user' | 'assistant' | 'system'
  content:     String  (text body, or empty for pure-card AI messages)
  messageType: 'text' | 'quiz_card' | 'vocab_card' | 'grammar_card'
  payload:    Mixed?  (card data; see card schemas below)
  createdAt:  Date
}
```

### Inline card schemas

**`quiz_card`** — multiple-choice question rendered inline:
```
{ question: String, options: [String], correctIdx: Number, explanation: String }
```
Flutter renders 2–4 tappable option buttons. On tap: send the answer back as a user message, AI responds with feedback.

**`vocab_card`** — word card with definition + example + "Add to vocab" button:
```
{ word: String, language: String, definition: String, example: String, ipa?: String }
```
"Add to vocab" hits existing `POST /learning/vocabulary` with the card payload.

**`grammar_card`** — concise rule + examples:
```
{ rule: String, explanation: String (≤500 chars), examples: [{ correct: String, wrong?: String, note?: String }] }
```

### API surface (sub-wave A1)

| Endpoint | Purpose | Notes |
|---|---|---|
| `GET /api/v1/tutor/me` | Returns TutorMemory (creates default if missing) | Auth-gated |
| `PUT /api/v1/tutor/persona` body: `{ persona }` | Set/change persona | Validates against the 3 enum values |
| `GET /api/v1/tutor/daily-plan` | Returns today's plan; lazy-generates if missing/stale | Comparison key: UTC midnight date string |
| `PATCH /api/v1/tutor/daily-plan/task/:type/complete` body: `{ delta? }` | Mark task progress | For `srs_review` and `tutor_chat` increments `completed` by `delta`; for `grammar_drill` flips to true |
| `POST /api/v1/tutor/sessions` | Start new chat session | Returns `{ session, openingMessage }` — AI greets with persona-flavored opener |
| `GET /api/v1/tutor/sessions/:id` | Get session with messages | Auth-gated; owner-only |
| `POST /api/v1/tutor/sessions/:id/message` body: `{ content }` | Send user message → AI reply | Returns the AI message (may be a card). Server persists both. |
| `POST /api/v1/tutor/sessions/:id/end` | End session, generate summary, update memory | Idempotent; safe to call from app-background hook |

All routes auth-gated via `protect`. Rate limits:
- `/sessions/:id/message`: 30/min per user, 200/hour, 1000/day (caps OpenAI cost)
- `/sessions`: 20/day per user (a new session every couple of hours of use)

### AI flow (per user message)

1. Flutter → `POST /tutor/sessions/:id/message { content }`
2. Backend:
   - Load `TutorMemory` + last 20 `AITutorSession.messages`
   - Build system prompt from persona template + memory context
   - Call OpenAI `gpt-4o-mini` with **JSON-mode** response schema:
     ```json
     {
       "type": "text" | "quiz_card" | "vocab_card" | "grammar_card",
       "content": "<text or short intro to the card>",
       "payload": { ... }   // present when type !== "text"
     }
     ```
   - Persist AI message to session
   - Return `{ message: AIMessage, session: { id } }` to Flutter
3. Flutter renders message via its `messageType` — text bubble or card widget

If the AI returns invalid JSON (rare with JSON-mode), parse as plain text and render as text bubble; don't crash.

### Persona system prompts (templates)

Common context block injected at the top of all three:

```
Today's date is {date}.
User profile:
- Name: {name}
- Level: {proficiencyLevel}
- Native language: {nativeLanguage}
- Learning: {targetLanguages.join(', ')}
- Recent weak areas: {top 3 from weakAreas}
- Recent vocab focus: {top 5 from vocabFocus}
- Summary of last chat: {recentChatSummaries[0]?.summary || 'first chat'}

Your job: help the user practice and improve. Respond in their target
language at their level when appropriate; switch to their native language
to explain rules or correct mistakes.

You can drop interactive cards into the chat:
- quiz_card: when you want to check understanding
- vocab_card: when you introduce a new word
- grammar_card: when you explain a rule

ALWAYS respond in the JSON schema described. Output the JSON, nothing else.
```

Then the persona overlay:

**Nana:** "You are Nana, a warm and encouraging tutor 🐻. Use light emoji. Praise effort first, then correct gently. Keep replies short (≤80 words) unless explaining grammar."

**Sensei:** "You are Sensei, a precise and exam-focused tutor 🤖. No emoji. Address the user formally. When correcting, reference the specific rule. Reply length: bullet-point clarity."

**Riko:** "You are Riko, a playful and slangy tutor 🐙. Use jokes and target-language slang when the user's level allows (B1+). Keep it casual. Make mistakes funny, not scary."

### Daily plan generation (lazy)

On first `GET /tutor/daily-plan` of the day:

1. Compute today's UTC date string. If `dailyPlan.date` matches, return as-is.
2. Otherwise, generate:
   - Count SRS-due cards from `Vocabulary` → `srs_review` task (skip if 0)
   - Pick #1 from `weakAreas` → `grammar_drill` task (skip if `weakAreas` empty)
   - Always include `tutor_chat` task (default 5 min)
3. Save to `TutorMemory.dailyPlan`, return.

UI shows as a checkable list on `TutorHomeScreen`. Tasks are completed by:
- `srs_review` — existing SRS review screen calls `PATCH /tutor/daily-plan/task/srs_review/complete { delta: N }` on session end
- `grammar_drill` — flips on completion of the relevant exercise
- `tutor_chat` — accumulates minutes from session duration on `POST /sessions/:id/end`

### Flutter surface

**New directory:** `lib/pages/ai/tutor/`

- `persona_picker_screen.dart` — 3 cards (big emoji avatar + name + 1-line vibe + "Pick"). First-run-only by default; reachable from settings.
- `tutor_home_screen.dart` — top: persona avatar + greeting (persona-flavored, generated by AI on `POST /sessions` opening message). Middle: daily plan checklist. Bottom: "Continue chat" / "New chat" + recent sessions list.
- `tutor_chat_screen.dart` — chat UI. Reuses chat-bubble layout from existing chat code where possible. Dispatcher renders the appropriate card widget for non-text message types.

**New directory:** `lib/widgets/tutor/`

- `quiz_card.dart` — question + tappable options + post-answer feedback state
- `vocab_card.dart` — word/definition/example + "Add to vocab" CTA
- `grammar_card.dart` — rule + bullet examples (correct/wrong/note)

**New provider:** `lib/providers/tutor_provider.dart` — Riverpod state for memory, current session, daily plan. Includes optimistic update on user message send + rollback on error.

**Modified file:** `lib/pages/ai/ai_main.dart` — top section becomes a tutor hero card (persona avatar + greeting + "Continue" / "Today's plan" buttons). Existing AI tool tiles stay below the hero.

**Modified file:** `lib/pages/profile/drawer/profile_drawer.dart` — add a "Change AI tutor" row under Support → reopens persona picker.

**l10n:** ~25 new English ARB keys (greeting variants, card labels, task labels, errors). 18-locale translations.

### Error handling

| Failure | Behavior |
|---|---|
| OpenAI 429 / 5xx | Persist user message, persist a fallback assistant message: "I'm having a moment — try again in a sec?" — return 200 |
| AI returns invalid JSON | Parse `response.content` as plain text, render as text bubble |
| `/tutor/me` not yet initialized | Auto-create with sensible defaults, return 200 |
| User exceeds rate limit | 429 with `Retry-After`; Flutter shows the existing rate-limit snackbar |
| Memory write fails mid-turn | Log + degrade; chat continues, memory just doesn't update this turn |
| Persona not yet picked | `POST /sessions` returns 400 `"Pick a persona first"`; Flutter routes to persona picker |

### Privacy & cost

- All user data stays in our existing Mongo. No data sent to OpenAI beyond the session prompt (which contains memory context).
- Memory context = level, weak areas (topic names, not full error history), vocab focus (word ids → resolved to text), last 5 chat summaries (short gists). No real-human chat content.
- Cost ballpark: gpt-4o-mini ≈ $0.15 input + $0.60 output per 1M tokens. A 20-message session ≈ ~$0.005. 100 DAU ≈ ~$15/mo.
- Rate limits enforce a hard ceiling per user.

---

## Out of scope (explicitly)

- 🎤 **Voice toggle (TTS + STT)** — Sub-wave A2
- **SRS-due card type** and **Mini-lesson card type** — A2
- **Push notifications from the tutor** — Sub-wave C of the bigger arc
- **Roleplay scenarios, story generation, image-vocab** — Sub-wave B of the bigger arc
- **Function calling / OpenAI tool use** — A1 uses JSON-mode structured output instead, simpler to debug
- **Per-language persona variants** (e.g. a Japanese-only sensei) — punt
- **Real illustrated avatars** — emoji v1; art swap is a non-engineering follow-up
- **Switching personas mid-session** — locked for the session's duration; new session = new persona possible
- **Tutor in onboarding** — first-run picker is post-login, not woven into auth flow

---

## Sub-wave A2 (next, ~10 commits)

- 🎤 Voice toggle on chat: TTS reads AI replies (OpenAI `tts-1`), STT captures user speech (existing Whisper plumbing)
- Card types: `srs_due_card` (review N cards inline) + `mini_lesson_card` (3-bullet teach + practice)
- Persona settings polish: avatar swap to illustrated art (designer asset drop)
- Memory refresh job (cron, daily): rolls up weakAreas + vocabFocus from accumulated activity (currently computed on read; cron makes reads faster)

---

## Acceptance criteria (A1)

1. New user signs in → opens AI tab → sees persona picker (3 cards). Picks one. Lands on TutorHome.
2. TutorHome shows persona-flavored greeting + today's plan (with SRS count, grammar topic, chat goal).
3. Tap "Start chat" → new session created → AI sends an opening message (text). User replies. AI replies, sometimes with a quiz/vocab/grammar card.
4. Tap a quiz card option → answer logged, AI follows up with feedback.
5. Tap a vocab card "Add" → word saved via existing vocab endpoint.
6. Close chat → session ends → summary generated → next time TutorHome's greeting references it ("welcome back, last time we worked on past tense...").
7. Change persona from settings → next new session uses the new prompt + avatar.
8. Persona switcher in drawer is reachable from Support section.

## Risk + rollback

- **OpenAI outage** → fallback text replies; the chat still works visually. Acceptable graceful degradation.
- **Bad persona prompt** → flip the persona via PUT or admin tool; users don't lose state.
- **Memory model regret** → schema is additive; can drop unused fields later. Worst case: drop the `TutorMemory` collection and start fresh (only loses the personalization, not chats).
- **Cost overrun** → rate limits + cap per user. Hard ceiling at $20/user/month even if abused (would require ~4000 messages — caught by limits well before).
- Whole wave is feature-flagged by route presence — if disaster, hide entry points in `ai_main.dart` and the system is dormant.

---

## Estimated commit count

**Backend (~6):**
1. TutorMemory + AITutorSession models
2. tutorService — system prompt builder, OpenAI call wrapper, JSON parser, memory updater
3. controllers/tutor.js — 7 endpoints
4. routes/tutor.js + server.js wiring
5. Daily-plan generator
6. Rate limit middleware additions

**Flutter (~7):**
1. tutor_provider.dart (state)
2. persona_picker_screen + route wire
3. tutor_home_screen + greeting + plan widget
4. tutor_chat_screen + send/receive loop
5. quiz_card + vocab_card + grammar_card widgets
6. ai_main.dart hero redesign
7. profile_drawer "Change AI tutor" row + l10n keys

**Glue (~1):** spec/plan commits, final PR.

**Total: ~14 commits, 2-3 days.**

---

## What I need from you before plan-writing

1. ✅ Sub-wave shape (A picked over B/C) — confirmed
2. ✅ Memory tier (2) — confirmed
3. ✅ Proactivity (B: reactive + daily plan, no notifications this wave) — confirmed
4. ✅ Persona (3 chars: Nana/Sensei/Riko, emoji avatars) — confirmed
5. ✅ Voice (A1 text-only, A2 voice) — confirmed
6. ✅ Tool use (inline cards via JSON-mode) — confirmed
7. ✅ Scope split (A1 14 commits, A2 ~10 commits) — confirmed

Spec is ready for review. After review passes, the next step is `writing-plans` for the A1 plan.
