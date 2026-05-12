# Step 9 — AI Tutor Foundation (A1) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking. The user's pacing preference is "drive uninterrupted" — no per-commit confirmation; surface only at end of wave or genuine blockers.

**Goal:** Ship the AI Tutor foundation — a chat-first, persona-driven AI study companion with Tier-2 memory, inline cards, and daily plan.

**Architecture:** New `/api/v1/tutor/*` endpoints backed by two Mongo models (`TutorMemory`, `AITutorSession`). Flutter gets a new `lib/pages/ai/tutor/` directory with persona picker, hub, and chat screens. AI replies are JSON-mode `gpt-4o-mini` calls that may emit interactive cards (quiz/vocab/grammar) rendered inline.

**Tech Stack:** Node.js/Express + Mongoose (backend), Flutter + Riverpod (client), OpenAI `gpt-4o-mini` via existing `aiProviderService.js`.

**Spec:** `docs/superpowers/specs/2026-05-12-step9-ai-tutor-foundation-design.md` (commit `91db75a`)

**Branches:**
- Flutter: `feat/step9-ai-tutor-a1` (cut from main)
- Backend: `feat/step9-ai-tutor-a1` (cut from main)

**Estimated commit count:** 14 total (6 backend + 7 Flutter + 1 glue)

---

## File Structure

### Backend (new + modified)

| Path | Status | Responsibility |
|---|---|---|
| `models/TutorMemory.js` | Create | Per-user memory doc (persona, weak areas, vocab focus, recent summaries, daily plan) |
| `models/AITutorSession.js` | Create | Per-conversation chat session with messages (text + card types) |
| `services/tutorService.js` | Create | System prompt builder, OpenAI JSON-mode call, memory refresh, daily-plan generator |
| `controllers/tutor.js` | Create | 8 endpoints (read 4 + chat lifecycle 3 + task completion 1) |
| `routes/tutor.js` | Create | Route wiring with auth + rate limits |
| `server.js` | Modify | Mount `/api/v1/tutor` route |
| `middleware/rateLimiter.js` | Modify | Add `tutorMessageLimiter` (30/min per user) |

### Flutter (new + modified)

| Path | Status | Responsibility |
|---|---|---|
| `lib/providers/tutor_provider.dart` | Create | Riverpod state — memory, daily plan, current session, send/receive |
| `lib/models/tutor/tutor_memory.dart` | Create | DTO matching TutorMemory shape |
| `lib/models/tutor/tutor_session.dart` | Create | DTO matching AITutorSession + Message + card payloads |
| `lib/pages/ai/tutor/persona_picker_screen.dart` | Create | 3-card picker, first-run + settings-reopenable |
| `lib/pages/ai/tutor/tutor_home_screen.dart` | Create | Greeting + daily plan checklist + recent sessions + Start Chat |
| `lib/pages/ai/tutor/tutor_chat_screen.dart` | Create | Chat UI + bubble dispatcher routing to card widgets |
| `lib/widgets/tutor/quiz_card.dart` | Create | Multi-choice card with tappable options |
| `lib/widgets/tutor/vocab_card.dart` | Create | Word + def + example + "Add to vocab" CTA |
| `lib/widgets/tutor/grammar_card.dart` | Create | Rule + examples |
| `lib/pages/ai/ai_main.dart` | Modify | Add Tutor hero card at top; existing AI tiles below |
| `lib/pages/profile/drawer/profile_drawer.dart` | Modify | Add "Change AI tutor" row under Support section |
| `lib/l10n/app_en.arb` | Modify | ~25 new keys (persona names, card labels, task labels, errors) |
| `lib/l10n/app_*.arb` (×18 locales) | Modify | Mirror translations |

---

## Tasks

### Task 1 (Backend B1): Mongoose models for TutorMemory + AITutorSession

**Files:**
- Create: `models/TutorMemory.js`
- Create: `models/AITutorSession.js`

- [ ] **Step 1: Create `models/TutorMemory.js`**

```javascript
const mongoose = require('mongoose');

const WeakAreaSchema = new mongoose.Schema({
  topic:     { type: String, required: true },
  frequency: { type: Number, default: 1 },
  lastSeen:  { type: Date,   default: Date.now },
}, { _id: false });

const VocabFocusSchema = new mongoose.Schema({
  wordId:       { type: mongoose.Schema.Types.ObjectId, ref: 'Vocabulary' },
  status:       { type: String, enum: ['learning', 'mastered'], default: 'learning' },
  lastReviewed: { type: Date },
}, { _id: false });

const ChatSummarySchema = new mongoose.Schema({
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'AITutorSession' },
  summary:   { type: String, maxlength: 200 },
  createdAt: { type: Date, default: Date.now },
}, { _id: false });

const DailyPlanTaskSchema = new mongoose.Schema({
  type:      { type: String, enum: ['srs_review', 'grammar_drill', 'tutor_chat'], required: true },
  count:     { type: Number },                  // srs_review: cards target
  topic:     { type: String },                  // grammar_drill: e.g. "past tense"
  minutes:   { type: Number },                  // tutor_chat: target minutes
  completed: { type: mongoose.Schema.Types.Mixed, default: 0 }, // Number for srs/tutor, Boolean for grammar
}, { _id: false });

const DailyPlanSchema = new mongoose.Schema({
  date:  { type: Date, required: true }, // UTC midnight of the day
  tasks: { type: [DailyPlanTaskSchema], default: [] },
}, { _id: false });

const TutorMemorySchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
  persona:             { type: String, enum: ['nana', 'sensei', 'riko'], default: null },
  proficiencyLevel:    { type: String, enum: ['A1','A2','B1','B2','C1','C2'], default: 'A1' },
  targetLanguages:     { type: [String], default: [] },
  nativeLanguage:      { type: String, default: '' },
  weakAreas:           { type: [WeakAreaSchema], default: [] },
  vocabFocus:          { type: [VocabFocusSchema], default: [] },
  recentChatSummaries: { type: [ChatSummarySchema], default: [] },
  dailyPlan:           { type: DailyPlanSchema, default: null },
  lastSeen:            { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('TutorMemory', TutorMemorySchema);
```

- [ ] **Step 2: Create `models/AITutorSession.js`**

```javascript
const mongoose = require('mongoose');

const TutorMessageSchema = new mongoose.Schema({
  role:        { type: String, enum: ['user', 'assistant', 'system'], required: true },
  content:     { type: String, default: '' },
  messageType: { type: String, enum: ['text', 'quiz_card', 'vocab_card', 'grammar_card'], default: 'text' },
  payload:     { type: mongoose.Schema.Types.Mixed },
  createdAt:   { type: Date, default: Date.now },
}, { _id: true });

const AITutorSessionSchema = new mongoose.Schema({
  user:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  persona:   { type: String, enum: ['nana', 'sensei', 'riko'], required: true },
  messages:  { type: [TutorMessageSchema], default: [] },
  startedAt: { type: Date, default: Date.now },
  endedAt:   { type: Date },
  summary:   { type: String, maxlength: 200 },
}, { timestamps: true });

AITutorSessionSchema.index({ user: 1, startedAt: -1 });

module.exports = mongoose.model('AITutorSession', AITutorSessionSchema);
```

- [ ] **Step 3: Verify both files load**

```bash
node --check models/TutorMemory.js
node --check models/AITutorSession.js
```

Expected: no output (clean syntax).

- [ ] **Step 4: Commit**

```bash
git -C /Users/davis/Desktop/Personal/language_exchange_backend_application checkout -b feat/step9-ai-tutor-a1
git -C /Users/davis/Desktop/Personal/language_exchange_backend_application add models/TutorMemory.js models/AITutorSession.js
git -C /Users/davis/Desktop/Personal/language_exchange_backend_application commit -m "feat(tutor): A1-B1 — TutorMemory + AITutorSession models

TutorMemory: per-user doc holding persona, level mirror, weak areas
(top 10), vocab focus (top 20), recent chat summaries (rolling 5),
and the lazy-generated daily plan with 3 task types (srs_review,
grammar_drill, tutor_chat).

AITutorSession: per-conversation doc with messages array supporting
the inline card types from the spec (quiz_card, vocab_card,
grammar_card) plus plain text. Compound index (user, startedAt:-1)
for cheap recent-sessions list."
```

---

### Task 2 (Backend B2): tutorService — prompt builder + OpenAI wrapper + memory updater

**Files:**
- Create: `services/tutorService.js`
- Reference (read-only): `services/aiProviderService.js`, `services/aiConversationService.js` for the existing OpenAI call pattern

- [ ] **Step 1: Read existing AI service patterns**

```bash
head -80 services/aiProviderService.js
head -80 services/aiConversationService.js
```

Note the function names for calling OpenAI (e.g. `aiProvider.chatJson(...)` or similar). The tutorService will use the same pattern.

- [ ] **Step 2: Create `services/tutorService.js` with the system prompt builder**

```javascript
const TutorMemory       = require('../models/TutorMemory');
const AITutorSession    = require('../models/AITutorSession');
const Vocabulary        = require('../models/Vocabulary');
const aiProvider        = require('./aiProviderService');

const PERSONA_PROMPTS = {
  nana:   "You are Nana, a warm and encouraging tutor 🐻. Use light emoji. Praise effort first, then correct gently. Keep replies short (≤80 words) unless explaining grammar.",
  sensei: "You are Sensei, a precise and exam-focused tutor 🤖. No emoji. Address the user formally. When correcting, reference the specific rule. Reply length: bullet-point clarity.",
  riko:   "You are Riko, a playful and slangy tutor 🐙. Use jokes and target-language slang when the user's level allows (B1+). Keep it casual. Make mistakes funny, not scary.",
};

const RESPONSE_SCHEMA = `
Respond as valid JSON matching this exact shape:
{
  "type": "text" | "quiz_card" | "vocab_card" | "grammar_card",
  "content": "<conversational text — required for all types; for cards, this is the short intro before the card>",
  "payload": {
    // For "quiz_card": { "question": string, "options": string[], "correctIdx": number, "explanation": string }
    // For "vocab_card": { "word": string, "language": string, "definition": string, "example": string, "ipa"?: string }
    // For "grammar_card": { "rule": string, "explanation": string, "examples": [{ "correct": string, "wrong"?: string, "note"?: string }] }
    // For "text": omit or null
  }
}

Output the JSON only. No code fences, no commentary.
`;

const buildSystemPrompt = (memory, user) => {
  const persona = memory.persona || 'nana';
  const recentSummary = memory.recentChatSummaries?.[0]?.summary || 'first chat';
  const weakAreaTopics = (memory.weakAreas || []).slice(0, 3).map(w => w.topic).join(', ') || 'none yet';
  const vocabFocusWords = (memory.vocabFocus || []).slice(0, 5).map(v => v.wordId).join(', ') || 'none yet';

  return [
    `Today's date is ${new Date().toISOString().slice(0, 10)}.`,
    `User profile:`,
    `- Name: ${user.name || 'Friend'}`,
    `- Level: ${memory.proficiencyLevel}`,
    `- Native language: ${memory.nativeLanguage || 'unknown'}`,
    `- Learning: ${(memory.targetLanguages || []).join(', ') || 'unspecified'}`,
    `- Recent weak areas: ${weakAreaTopics}`,
    `- Recent vocab focus: ${vocabFocusWords}`,
    `- Summary of last chat: ${recentSummary}`,
    ``,
    `Your job: help the user practice and improve. Respond in their target language at their level when appropriate; switch to their native language to explain rules or correct mistakes.`,
    ``,
    `You can drop interactive cards into the chat:`,
    `- quiz_card: when you want to check understanding`,
    `- vocab_card: when you introduce a new word`,
    `- grammar_card: when you explain a rule`,
    ``,
    PERSONA_PROMPTS[persona],
    ``,
    RESPONSE_SCHEMA,
  ].join('\n');
};

const callTutorModel = async (systemPrompt, history) => {
  const messages = [
    { role: 'system', content: systemPrompt },
    ...history.slice(-20).map(m => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      content: m.role === 'assistant' && m.messageType !== 'text'
        ? `${m.content}\n[card: ${m.messageType}]`
        : m.content,
    })),
  ];

  const raw = await aiProvider.chatJson({
    model: 'gpt-4o-mini',
    messages,
    response_format: { type: 'json_object' },
    temperature: 0.7,
    max_tokens: 600,
  });

  return raw;
};

const parseTutorReply = (raw) => {
  try {
    const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
    const type = ['text', 'quiz_card', 'vocab_card', 'grammar_card'].includes(parsed.type) ? parsed.type : 'text';
    return {
      messageType: type,
      content:     parsed.content || '',
      payload:     type === 'text' ? null : parsed.payload || null,
    };
  } catch (e) {
    return {
      messageType: 'text',
      content:     typeof raw === 'string' ? raw : 'Sorry, I got confused — say that again?',
      payload:     null,
    };
  }
};

const generateDailyPlan = async (userId, memory) => {
  const dueCount = await Vocabulary.countDocuments({
    user: userId,
    nextReviewAt: { $lte: new Date() },
  }).catch(() => 0);

  const topWeakArea = (memory.weakAreas || []).sort((a, b) => b.frequency - a.frequency)[0];

  const tasks = [];
  if (dueCount > 0) {
    tasks.push({ type: 'srs_review', count: dueCount, completed: 0 });
  }
  if (topWeakArea) {
    tasks.push({ type: 'grammar_drill', topic: topWeakArea.topic, completed: false });
  }
  tasks.push({ type: 'tutor_chat', minutes: 5, completed: 0 });

  return {
    date:  new Date(new Date().toISOString().slice(0, 10) + 'T00:00:00Z'),
    tasks,
  };
};

const summarizeSession = async (session) => {
  if (!session.messages || session.messages.length < 4) return null;
  const transcript = session.messages
    .slice(-12)
    .map(m => `${m.role}: ${m.content}`)
    .join('\n');

  try {
    const raw = await aiProvider.chatJson({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'Summarize this tutor session in ≤30 words, focusing on the main topic, what the user worked on, and any errors corrected. Output JSON: {"summary":"..."}.' },
        { role: 'user', content: transcript },
      ],
      response_format: { type: 'json_object' },
      max_tokens: 80,
    });
    const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
    return (parsed.summary || '').slice(0, 200);
  } catch (e) {
    return null;
  }
};

const appendSummaryToMemory = async (userId, sessionId, summary) => {
  if (!summary) return;
  await TutorMemory.updateOne(
    { user: userId },
    {
      $push: {
        recentChatSummaries: {
          $each:  [{ sessionId, summary, createdAt: new Date() }],
          $slice: -5,
        },
      },
      $set: { lastSeen: new Date() },
    }
  );
};

module.exports = {
  buildSystemPrompt,
  callTutorModel,
  parseTutorReply,
  generateDailyPlan,
  summarizeSession,
  appendSummaryToMemory,
  PERSONA_PROMPTS,
};
```

- [ ] **Step 3: Verify it loads and check actual aiProvider API matches**

```bash
node --check services/tutorService.js
node -e "const t = require('./services/tutorService'); console.log(Object.keys(t));"
```

Expected: `[ 'buildSystemPrompt', 'callTutorModel', 'parseTutorReply', 'generateDailyPlan', 'summarizeSession', 'appendSummaryToMemory', 'PERSONA_PROMPTS' ]`

**If `aiProvider.chatJson` doesn't exist:** check the actual function exported by `aiProviderService.js` (likely `getChatCompletion`, `chat`, or similar) and adapt the two `aiProvider.chatJson(...)` call sites accordingly. The wrapper must take `{model, messages, response_format, temperature, max_tokens}` or equivalent and return the assistant text.

- [ ] **Step 4: Commit**

```bash
git add services/tutorService.js
git commit -m "feat(tutor): A1-B2 — tutorService (prompts, OpenAI call, parser, plan)

Exports:
- buildSystemPrompt(memory, user) — persona-aware prompt with user
  context (level, weak areas, vocab focus, last-chat summary) and
  the strict JSON response schema
- callTutorModel(systemPrompt, history) — gpt-4o-mini with json_object
  response_format; last 20 messages of context
- parseTutorReply(raw) — defensive parser that falls back to a text
  bubble if the AI emits invalid JSON
- generateDailyPlan(userId, memory) — counts SRS-due cards, picks the
  top weak-area topic, always includes a 5-min tutor_chat target
- summarizeSession(session) + appendSummaryToMemory — generates a
  ≤30-word session summary and pushes it onto the rolling 5"
```

---

### Task 3 (Backend B3): controllers/tutor.js — read endpoints + persona + daily plan + task complete

**Files:**
- Create: `controllers/tutor.js`

- [ ] **Step 1: Create the controller with read endpoints**

```javascript
const asyncHandler   = require('../middleware/async');
const ErrorResponse  = require('../utils/errorResponse');
const TutorMemory    = require('../models/TutorMemory');
const AITutorSession = require('../models/AITutorSession');
const User           = require('../models/User');
const LearningProgress = require('../models/LearningProgress');
const tutorService   = require('../services/tutorService');

const VALID_PERSONAS = ['nana', 'sensei', 'riko'];

/** Ensure a TutorMemory exists for the user; lazy-create with profile defaults. */
const ensureMemory = async (userId) => {
  let mem = await TutorMemory.findOne({ user: userId });
  if (mem) return mem;

  const [user, progress] = await Promise.all([
    User.findById(userId).select('name native_language languages_to_learn').lean(),
    LearningProgress.findOne({ user: userId }).select('proficiencyLevel').lean(),
  ]);

  mem = await TutorMemory.create({
    user: userId,
    proficiencyLevel: progress?.proficiencyLevel || 'A1',
    targetLanguages:  user?.languages_to_learn || [],
    nativeLanguage:   user?.native_language || '',
  });
  return mem;
};

/**
 * @route   GET /api/v1/tutor/me
 * @desc    Returns TutorMemory (creates default if missing)
 * @access  Private
 */
exports.getMyMemory = asyncHandler(async (req, res) => {
  const mem = await ensureMemory(req.user._id);
  res.status(200).json({ success: true, data: mem });
});

/**
 * @route   PUT /api/v1/tutor/persona
 * @desc    Set/change persona
 * @body    { persona: 'nana' | 'sensei' | 'riko' }
 */
exports.setPersona = asyncHandler(async (req, res, next) => {
  const { persona } = req.body || {};
  if (!VALID_PERSONAS.includes(persona)) {
    return next(new ErrorResponse(`Invalid persona; must be one of ${VALID_PERSONAS.join(', ')}`, 400));
  }
  const mem = await ensureMemory(req.user._id);
  mem.persona = persona;
  await mem.save();
  res.status(200).json({ success: true, data: mem });
});

/**
 * @route   GET /api/v1/tutor/daily-plan
 * @desc    Returns today's plan; lazy-generates if missing/stale
 */
exports.getDailyPlan = asyncHandler(async (req, res) => {
  const mem = await ensureMemory(req.user._id);
  const todayUTC = new Date(new Date().toISOString().slice(0, 10) + 'T00:00:00Z');

  if (!mem.dailyPlan || new Date(mem.dailyPlan.date).getTime() !== todayUTC.getTime()) {
    mem.dailyPlan = await tutorService.generateDailyPlan(req.user._id, mem);
    await mem.save();
  }

  res.status(200).json({ success: true, data: mem.dailyPlan });
});

/**
 * @route   PATCH /api/v1/tutor/daily-plan/task/:type/complete
 * @desc    Mark task progress
 * @body    { delta?: number }   (numeric tasks)
 */
exports.completeTask = asyncHandler(async (req, res, next) => {
  const { type } = req.params;
  const delta = Number.isFinite(req.body?.delta) ? req.body.delta : 1;

  const mem = await ensureMemory(req.user._id);
  if (!mem.dailyPlan) {
    return next(new ErrorResponse('No daily plan for today', 404));
  }
  const task = mem.dailyPlan.tasks.find(t => t.type === type);
  if (!task) {
    return next(new ErrorResponse(`No task of type ${type} in today's plan`, 404));
  }

  if (type === 'grammar_drill') {
    task.completed = true;
  } else {
    task.completed = Number(task.completed || 0) + delta;
  }
  mem.markModified('dailyPlan');
  await mem.save();

  res.status(200).json({ success: true, data: mem.dailyPlan });
});

/**
 * @route   GET /api/v1/tutor/sessions/:id
 * @desc    Get a session with its messages (owner-only)
 */
exports.getSession = asyncHandler(async (req, res, next) => {
  const session = await AITutorSession.findById(req.params.id);
  if (!session) return next(new ErrorResponse('Session not found', 404));
  if (session.user.toString() !== req.user._id.toString()) {
    return next(new ErrorResponse('Not authorized to view this session', 403));
  }
  res.status(200).json({ success: true, data: session });
});

/**
 * @route   GET /api/v1/tutor/sessions
 * @desc    Recent sessions for the user (paginated, default 10)
 */
exports.listSessions = asyncHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 10, 50);
  const sessions = await AITutorSession.find({ user: req.user._id })
    .sort({ startedAt: -1 })
    .limit(limit)
    .select('persona startedAt endedAt summary');
  res.status(200).json({ success: true, data: sessions });
});
```

- [ ] **Step 2: Verify syntax**

```bash
node --check controllers/tutor.js
```

- [ ] **Step 3: Commit**

```bash
git add controllers/tutor.js
git commit -m "feat(tutor): A1-B3 — read endpoints + persona + daily plan + task complete

Implements 6 read/mutate endpoints (chat lifecycle lands in B4):
- GET    /tutor/me                              — TutorMemory (lazy-create)
- PUT    /tutor/persona                         — set persona enum
- GET    /tutor/daily-plan                      — today's plan, lazy-generated
- PATCH  /tutor/daily-plan/task/:type/complete  — mark progress
- GET    /tutor/sessions                        — recent sessions list
- GET    /tutor/sessions/:id                    — owner-gated single session

ensureMemory() seeds defaults from User.native_language and
LearningProgress.proficiencyLevel on first read so the user never
hits an empty memory state."
```

---

### Task 4 (Backend B4): controllers/tutor.js chat lifecycle (sessions + message + end)

**Files:**
- Modify: `controllers/tutor.js` (append)

- [ ] **Step 1: Append session lifecycle endpoints to `controllers/tutor.js`**

Add at the bottom of the file:

```javascript
/**
 * @route   POST /api/v1/tutor/sessions
 * @desc    Start a new chat session; AI generates an opening greeting
 */
exports.startSession = asyncHandler(async (req, res, next) => {
  const mem = await ensureMemory(req.user._id);
  if (!mem.persona) {
    return next(new ErrorResponse('Pick a persona first', 400));
  }

  const user = await User.findById(req.user._id).select('name').lean();
  const session = await AITutorSession.create({
    user:    req.user._id,
    persona: mem.persona,
    messages: [],
  });

  // Generate opening greeting via the same prompt path the rest of the chat uses.
  const systemPrompt = tutorService.buildSystemPrompt(mem, user || { name: 'Friend' });
  const openingHistory = [{ role: 'user', content: '(internal) Greet the user briefly. Optionally reference our last chat. Suggest something to work on today. Do not output a card on the first turn.', messageType: 'text' }];

  let rawReply;
  try {
    rawReply = await tutorService.callTutorModel(systemPrompt, openingHistory);
  } catch (e) {
    console.error('[tutor.startSession] AI call failed:', e.message);
    rawReply = JSON.stringify({ type: 'text', content: "Hey there — what would you like to work on today?" });
  }
  const parsed = tutorService.parseTutorReply(rawReply);

  session.messages.push({
    role: 'assistant',
    content: parsed.content,
    messageType: parsed.messageType,
    payload: parsed.payload,
  });
  await session.save();

  res.status(201).json({ success: true, data: session });
});

/**
 * @route   POST /api/v1/tutor/sessions/:id/message
 * @desc    User sends a message; AI replies (may be a card)
 * @body    { content: string }
 */
exports.sendMessage = asyncHandler(async (req, res, next) => {
  const { content } = req.body || {};
  if (!content || typeof content !== 'string' || !content.trim()) {
    return next(new ErrorResponse('Message content is required', 400));
  }

  const session = await AITutorSession.findById(req.params.id);
  if (!session) return next(new ErrorResponse('Session not found', 404));
  if (session.user.toString() !== req.user._id.toString()) {
    return next(new ErrorResponse('Not authorized', 403));
  }
  if (session.endedAt) {
    return next(new ErrorResponse('Session has ended; start a new one', 409));
  }

  // Persist user message first so we never lose it on AI failure.
  session.messages.push({ role: 'user', content: content.trim(), messageType: 'text' });
  await session.save();

  const mem = await ensureMemory(req.user._id);
  const user = await User.findById(req.user._id).select('name').lean();
  const systemPrompt = tutorService.buildSystemPrompt(mem, user || { name: 'Friend' });

  let parsed;
  try {
    const rawReply = await tutorService.callTutorModel(systemPrompt, session.messages);
    parsed = tutorService.parseTutorReply(rawReply);
  } catch (e) {
    console.error('[tutor.sendMessage] AI call failed:', e.message);
    parsed = { messageType: 'text', content: "I'm having a moment — try again in a sec?", payload: null };
  }

  const aiMsg = {
    role: 'assistant',
    content: parsed.content,
    messageType: parsed.messageType,
    payload: parsed.payload,
    createdAt: new Date(),
  };
  session.messages.push(aiMsg);
  await session.save();

  res.status(200).json({ success: true, data: { message: aiMsg, sessionId: session._id } });
});

/**
 * @route   POST /api/v1/tutor/sessions/:id/end
 * @desc    End session, generate summary, push to memory
 *          Idempotent — safe to call from app-background hooks.
 */
exports.endSession = asyncHandler(async (req, res, next) => {
  const session = await AITutorSession.findById(req.params.id);
  if (!session) return next(new ErrorResponse('Session not found', 404));
  if (session.user.toString() !== req.user._id.toString()) {
    return next(new ErrorResponse('Not authorized', 403));
  }
  if (session.endedAt) {
    return res.status(200).json({ success: true, data: session, alreadyEnded: true });
  }

  session.endedAt = new Date();
  const summary = await tutorService.summarizeSession(session);
  if (summary) session.summary = summary;
  await session.save();

  await tutorService.appendSummaryToMemory(req.user._id, session._id, summary);

  // Bump tutor_chat task progress by session duration (minutes, min 1).
  const mem = await TutorMemory.findOne({ user: req.user._id });
  if (mem?.dailyPlan?.tasks) {
    const minutes = Math.max(
      1,
      Math.round((session.endedAt - session.startedAt) / 60000)
    );
    const chatTask = mem.dailyPlan.tasks.find(t => t.type === 'tutor_chat');
    if (chatTask) {
      chatTask.completed = Number(chatTask.completed || 0) + minutes;
      mem.markModified('dailyPlan');
      await mem.save();
    }
  }

  res.status(200).json({ success: true, data: session });
});
```

- [ ] **Step 2: Verify syntax**

```bash
node --check controllers/tutor.js
```

- [ ] **Step 3: Commit**

```bash
git add controllers/tutor.js
git commit -m "feat(tutor): A1-B4 — chat session lifecycle endpoints

Three endpoints completing the controller:
- POST /tutor/sessions          — opens a new session; AI emits an
  opening greeting via the same prompt path (no card on turn 1)
- POST /tutor/sessions/:id/message — persists user message FIRST
  (so an AI failure never loses input), then calls gpt-4o-mini,
  parses defensively, returns the AI message
- POST /tutor/sessions/:id/end  — idempotent; generates a ≤30-word
  summary, pushes to TutorMemory.recentChatSummaries (rolling 5),
  bumps tutor_chat task progress by elapsed minutes

AI call failures degrade to a 'try again in a sec' text bubble —
the chat always remains in a usable state."
```

---

### Task 5 (Backend B5): routes/tutor.js + server.js mount + rate limit

**Files:**
- Create: `routes/tutor.js`
- Modify: `server.js` (mount the route)
- Modify: `middleware/rateLimiter.js` (add `tutorMessageLimiter`)

- [ ] **Step 1: Add a tutor-specific rate limiter to `middleware/rateLimiter.js`**

Append to the file:

```javascript
/**
 * Tutor message limiter — bounds OpenAI cost per user.
 * 30 messages/min, ~100/hour effectively via the general limiter cap.
 */
exports.tutorMessageLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  message: { success: false, error: 'Too many tutor messages. Slow down a sec.' },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user ? `tutormsg:${req.user.id}` : `tutormsg:${req.ip}`,
});
```

- [ ] **Step 2: Create `routes/tutor.js`**

```javascript
const express = require('express');
const router = express.Router();

const {
  getMyMemory,
  setPersona,
  getDailyPlan,
  completeTask,
  listSessions,
  getSession,
  startSession,
  sendMessage,
  endSession,
} = require('../controllers/tutor');

const { protect } = require('../middleware/auth');
const { tutorMessageLimiter } = require('../middleware/rateLimiter');

router.use(protect);

router.get('/me',                                   getMyMemory);
router.put('/persona',                              setPersona);
router.get('/daily-plan',                           getDailyPlan);
router.patch('/daily-plan/task/:type/complete',     completeTask);

router.get('/sessions',                             listSessions);
router.post('/sessions',                            startSession);
router.get('/sessions/:id',                         getSession);
router.post('/sessions/:id/message', tutorMessageLimiter, sendMessage);
router.post('/sessions/:id/end',                    endSession);

module.exports = router;
```

- [ ] **Step 3: Mount the route in `server.js`**

Find the block of `app.use('/api/v1/...', ...)` mounts and add (after the other AI routes):

```javascript
const tutor = require('./routes/tutor');
// ... existing requires ...

app.use('/api/v1/tutor', tutor);
```

- [ ] **Step 4: Verify**

```bash
node --check routes/tutor.js
node --check middleware/rateLimiter.js
node --check server.js
```

- [ ] **Step 5: Smoke-test the route loads**

```bash
node -e "const r = require('./routes/tutor'); console.log('routes loaded:', !!r);"
```

Expected: `routes loaded: true`

- [ ] **Step 6: Commit**

```bash
git add routes/tutor.js middleware/rateLimiter.js server.js
git commit -m "feat(tutor): A1-B5 — routes + rate limiter + server mount

POST /sessions/:id/message gets a dedicated 30/min/user limiter to
cap OpenAI cost. Other endpoints fall back to the global limiters
which are plenty generous.

All routes auth-gated via the existing protect middleware. Mounted
under /api/v1/tutor."
```

---

### Task 6 (Backend B6): Memory refresh hooks (weak area on grammar mistake)

**Files:**
- Modify: `controllers/grammarFeedback.js` (or wherever grammar errors are persisted) — fire-and-forget weakArea append on error
- Modify: `controllers/learning.js` (quiz answer logging) — fire-and-forget weakArea append on wrong answer

This task wires `TutorMemory.weakAreas` to actually get updated as the user encounters mistakes in other features. The hooks are minimal and best-effort — failure to update memory must NOT fail the parent request.

- [ ] **Step 1: Read the existing grammar feedback controller to find where errors are recorded**

```bash
grep -n "grammar\|error\|mistake" controllers/grammarFeedback.js | head -20
```

Find the function that returns/persists grammar errors. Identify the topic/category field (e.g. `errorType`, `category`, `rule`).

- [ ] **Step 2: After the grammar error is recorded, append to TutorMemory.weakAreas**

Add at the end of the controller function (before `res.status(...).json(...)`), where you have access to `req.user._id` and the error category:

```javascript
// Best-effort: bump weak-area frequency for the tutor's memory model.
// Failure is non-fatal.
const TutorMemory = require('../models/TutorMemory');
(async () => {
  try {
    const topic = errorCategory || feedback?.category || 'grammar';
    await TutorMemory.updateOne(
      { user: req.user._id, 'weakAreas.topic': topic },
      { $inc: { 'weakAreas.$.frequency': 1 }, $set: { 'weakAreas.$.lastSeen': new Date() } }
    ).then(async (result) => {
      if (result.matchedCount === 0) {
        await TutorMemory.updateOne(
          { user: req.user._id },
          {
            $push: {
              weakAreas: {
                $each:  [{ topic, frequency: 1, lastSeen: new Date() }],
                $slice: -10,
              },
            },
          },
          { upsert: true }
        );
      }
    });
  } catch (e) {
    console.error('[tutor-memory] weakArea update failed:', e.message);
  }
})();
```

Wrap in an IIFE so the response isn't blocked. The exact field names (`errorCategory`, `feedback.category`) will depend on the controller — adapt to whatever the existing variable is named.

- [ ] **Step 3: Do the same for `controllers/learning.js` quiz-answer endpoint**

Same pattern — wherever a wrong quiz answer is recorded, fire-and-forget bump the weak area (topic = quiz category or question tag).

- [ ] **Step 4: Verify**

```bash
node --check controllers/grammarFeedback.js
node --check controllers/learning.js
```

- [ ] **Step 5: Commit**

```bash
git add controllers/grammarFeedback.js controllers/learning.js
git commit -m "feat(tutor): A1-B6 — wire weakAreas updates from grammar + quiz hooks

Best-effort fire-and-forget updates to TutorMemory.weakAreas
whenever a grammar mistake is logged or a quiz answer is wrong.
The topic is taken from the error category / question tag. Bumps
frequency on existing topics, appends new ones, capped at the
last 10 by Mongo's \$slice on push.

Wrapped in IIFE so the response is never blocked, and a try/catch
swallows any failure with a console log — memory update is a
nicety, never a request blocker."
```

---

### Task 7 (Flutter F1): Models + tutor provider

**Files:**
- Create: `lib/models/tutor/tutor_memory.dart`
- Create: `lib/models/tutor/tutor_session.dart`
- Create: `lib/providers/tutor_provider.dart`

- [ ] **Step 1: Cut Flutter feature branch**

```bash
git -C /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app checkout -b feat/step9-ai-tutor-a1
```

- [ ] **Step 2: Create `lib/models/tutor/tutor_memory.dart`**

```dart
class TutorMemory {
  final String? persona; // 'nana' | 'sensei' | 'riko' | null
  final String proficiencyLevel;
  final List<String> targetLanguages;
  final String nativeLanguage;
  final List<WeakArea> weakAreas;
  final List<ChatSummary> recentChatSummaries;
  final DailyPlan? dailyPlan;

  TutorMemory({
    required this.persona,
    required this.proficiencyLevel,
    required this.targetLanguages,
    required this.nativeLanguage,
    required this.weakAreas,
    required this.recentChatSummaries,
    required this.dailyPlan,
  });

  factory TutorMemory.fromJson(Map<String, dynamic> json) => TutorMemory(
        persona: json['persona'] as String?,
        proficiencyLevel: json['proficiencyLevel'] as String? ?? 'A1',
        targetLanguages: (json['targetLanguages'] as List?)?.cast<String>() ?? const [],
        nativeLanguage: json['nativeLanguage'] as String? ?? '',
        weakAreas: ((json['weakAreas'] as List?) ?? const [])
            .map((e) => WeakArea.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentChatSummaries: ((json['recentChatSummaries'] as List?) ?? const [])
            .map((e) => ChatSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyPlan: json['dailyPlan'] != null
            ? DailyPlan.fromJson(json['dailyPlan'] as Map<String, dynamic>)
            : null,
      );
}

class WeakArea {
  final String topic;
  final int frequency;
  WeakArea({required this.topic, required this.frequency});
  factory WeakArea.fromJson(Map<String, dynamic> j) =>
      WeakArea(topic: j['topic'] ?? '', frequency: (j['frequency'] as num?)?.toInt() ?? 0);
}

class ChatSummary {
  final String summary;
  final DateTime createdAt;
  ChatSummary({required this.summary, required this.createdAt});
  factory ChatSummary.fromJson(Map<String, dynamic> j) => ChatSummary(
        summary: j['summary'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class DailyPlan {
  final DateTime date;
  final List<DailyPlanTask> tasks;
  DailyPlan({required this.date, required this.tasks});
  factory DailyPlan.fromJson(Map<String, dynamic> j) => DailyPlan(
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        tasks: ((j['tasks'] as List?) ?? const [])
            .map((e) => DailyPlanTask.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyPlanTask {
  final String type; // 'srs_review' | 'grammar_drill' | 'tutor_chat'
  final int? count;
  final String? topic;
  final int? minutes;
  final dynamic completed; // num for srs/tutor, bool for grammar
  DailyPlanTask({required this.type, this.count, this.topic, this.minutes, required this.completed});
  factory DailyPlanTask.fromJson(Map<String, dynamic> j) => DailyPlanTask(
        type: j['type'] ?? '',
        count: (j['count'] as num?)?.toInt(),
        topic: j['topic'] as String?,
        minutes: (j['minutes'] as num?)?.toInt(),
        completed: j['completed'],
      );
  bool get isDone {
    if (completed is bool) return completed == true;
    if (completed is num) {
      if (type == 'srs_review') return count != null && (completed as num) >= count!;
      if (type == 'tutor_chat') return minutes != null && (completed as num) >= minutes!;
      return false;
    }
    return false;
  }
}
```

- [ ] **Step 3: Create `lib/models/tutor/tutor_session.dart`**

```dart
class TutorMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final String messageType; // 'text' | 'quiz_card' | 'vocab_card' | 'grammar_card'
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  TutorMessage({
    required this.role,
    required this.content,
    required this.messageType,
    required this.payload,
    required this.createdAt,
  });

  factory TutorMessage.fromJson(Map<String, dynamic> j) => TutorMessage(
        role: j['role'] ?? 'assistant',
        content: j['content'] ?? '',
        messageType: j['messageType'] ?? 'text',
        payload: j['payload'] is Map ? Map<String, dynamic>.from(j['payload'] as Map) : null,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class TutorSession {
  final String id;
  final String persona;
  final List<TutorMessage> messages;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? summary;

  TutorSession({
    required this.id,
    required this.persona,
    required this.messages,
    required this.startedAt,
    required this.endedAt,
    required this.summary,
  });

  factory TutorSession.fromJson(Map<String, dynamic> j) => TutorSession(
        id: (j['_id'] ?? j['id']).toString(),
        persona: j['persona'] ?? 'nana',
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) => TutorMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        startedAt: DateTime.tryParse(j['startedAt']?.toString() ?? '') ?? DateTime.now(),
        endedAt: j['endedAt'] != null ? DateTime.tryParse(j['endedAt'].toString()) : null,
        summary: j['summary'] as String?,
      );
}
```

- [ ] **Step 4: Create `lib/providers/tutor_provider.dart`**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor/tutor_memory.dart';
import '../models/tutor/tutor_session.dart';
import '../services/api_client.dart';

class TutorService {
  final ApiClient _api = ApiClient();

  Future<TutorMemory> getMemory() async {
    final res = await _api.get('tutor/me');
    if (!res.success) throw StateError(res.error ?? 'Failed to load tutor memory');
    return TutorMemory.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorMemory> setPersona(String persona) async {
    final res = await _api.put('tutor/persona', body: {'persona': persona});
    if (!res.success) throw StateError(res.error ?? 'Failed to set persona');
    return TutorMemory.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DailyPlan?> getDailyPlan() async {
    final res = await _api.get('tutor/daily-plan');
    if (!res.success) return null;
    final raw = res.data;
    if (raw is Map<String, dynamic>) return DailyPlan.fromJson(raw);
    return null;
  }

  Future<TutorSession> startSession() async {
    final res = await _api.post('tutor/sessions');
    if (!res.success) throw StateError(res.error ?? 'Failed to start session');
    return TutorSession.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TutorMessage> sendMessage(String sessionId, String content) async {
    final res = await _api.post('tutor/sessions/$sessionId/message', body: {'content': content});
    if (!res.success) throw StateError(res.error ?? 'Failed to send message');
    final body = res.data as Map<String, dynamic>;
    final msg = body['message'] as Map<String, dynamic>;
    return TutorMessage.fromJson(msg);
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _api.post('tutor/sessions/$sessionId/end');
    } catch (e) {
      debugPrint('[tutor] endSession ignored: $e');
    }
  }

  Future<List<TutorSession>> listSessions({int limit = 10}) async {
    final res = await _api.get('tutor/sessions', queryParams: {'limit': '$limit'});
    if (!res.success) return [];
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] as List? ?? []) : <dynamic>[]);
    return list.map((e) => TutorSession.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final tutorServiceProvider = Provider<TutorService>((_) => TutorService());

final tutorMemoryProvider = FutureProvider<TutorMemory>((ref) {
  return ref.read(tutorServiceProvider).getMemory();
});

final tutorDailyPlanProvider = FutureProvider<DailyPlan?>((ref) {
  return ref.read(tutorServiceProvider).getDailyPlan();
});

final tutorRecentSessionsProvider = FutureProvider<List<TutorSession>>((ref) {
  return ref.read(tutorServiceProvider).listSessions();
});

class TutorChatState {
  final TutorSession? session;
  final bool sending;
  final String? error;
  const TutorChatState({this.session, this.sending = false, this.error});
  TutorChatState copyWith({TutorSession? session, bool? sending, String? error}) =>
      TutorChatState(session: session ?? this.session, sending: sending ?? this.sending, error: error);
}

class TutorChatController extends StateNotifier<TutorChatState> {
  final TutorService _svc;
  TutorChatController(this._svc) : super(const TutorChatState());

  Future<void> start() async {
    final s = await _svc.startSession();
    state = TutorChatState(session: s);
  }

  Future<void> send(String content) async {
    final s = state.session;
    if (s == null) return;
    // Optimistic: append user message.
    final optimistic = TutorSession(
      id: s.id, persona: s.persona, startedAt: s.startedAt, endedAt: s.endedAt, summary: s.summary,
      messages: [
        ...s.messages,
        TutorMessage(role: 'user', content: content, messageType: 'text', payload: null, createdAt: DateTime.now()),
      ],
    );
    state = state.copyWith(session: optimistic, sending: true, error: null);

    try {
      final reply = await _svc.sendMessage(s.id, content);
      final updated = TutorSession(
        id: s.id, persona: s.persona, startedAt: s.startedAt, endedAt: s.endedAt, summary: s.summary,
        messages: [...optimistic.messages, reply],
      );
      state = state.copyWith(session: updated, sending: false);
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }

  Future<void> end() async {
    final s = state.session;
    if (s == null) return;
    await _svc.endSession(s.id);
  }
}

final tutorChatControllerProvider =
    StateNotifierProvider.autoDispose<TutorChatController, TutorChatState>((ref) {
  return TutorChatController(ref.read(tutorServiceProvider));
});
```

- [ ] **Step 5: Verify `flutter analyze`**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze lib/models/tutor/ lib/providers/tutor_provider.dart 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/models/tutor/ lib/providers/tutor_provider.dart
git commit -m "feat(tutor): A1-F1 — tutor DTOs + Riverpod provider stack

Models (lib/models/tutor/):
- TutorMemory + nested WeakArea, ChatSummary, DailyPlan, DailyPlanTask
- TutorSession + TutorMessage with card payload as raw Map (card
  widgets parse their own payload shapes in F3)

Providers (lib/providers/tutor_provider.dart):
- TutorService — thin wrapper around ApiClient with 7 endpoint methods
- tutorServiceProvider, tutorMemoryProvider, tutorDailyPlanProvider,
  tutorRecentSessionsProvider (read-only FutureProviders)
- TutorChatController (StateNotifier, auto-dispose) — manages a single
  session with optimistic user-message append and rollback on error"
```

---

### Task 8 (Flutter F2): Persona picker screen

**Files:**
- Create: `lib/pages/ai/tutor/persona_picker_screen.dart`

- [ ] **Step 1: Create the picker screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/tutor_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import 'tutor_home_screen.dart';

class PersonaPickerScreen extends ConsumerStatefulWidget {
  final bool isFirstRun;
  const PersonaPickerScreen({super.key, this.isFirstRun = true});

  @override
  ConsumerState<PersonaPickerScreen> createState() => _PersonaPickerScreenState();
}

class _PersonaPickerScreenState extends ConsumerState<PersonaPickerScreen> {
  String? _selecting;

  Future<void> _pick(String key) async {
    setState(() => _selecting = key);
    try {
      await ref.read(tutorServiceProvider).setPersona(key);
      ref.invalidate(tutorMemoryProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TutorHomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _selecting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      _Persona('nana',   '🐻', 'Nana',   'Warm + encouraging', "I'll cheer you on, no pressure."),
      _Persona('sensei', '🤖', 'Sensei', 'Precise + exam-focused', "We will master the rules."),
      _Persona('riko',   '🐙', 'Riko',   'Playful + slangy',   'lol let\'s vibe and learn'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick your AI tutor'),
        leading: widget.isFirstRun
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Who do you want to learn with?',
                style: context.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can change this anytime in settings.',
                style: context.bodyMedium.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              for (final p in entries) ...[
                _PersonaCard(
                  persona: p,
                  loading: _selecting == p.key,
                  onPick: () => _pick(p.key),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Persona {
  final String key;
  final String avatar;
  final String name;
  final String tagline;
  final String sample;
  _Persona(this.key, this.avatar, this.name, this.tagline, this.sample);
}

class _PersonaCard extends StatelessWidget {
  final _Persona persona;
  final bool loading;
  final VoidCallback onPick;
  const _PersonaCard({required this.persona, required this.loading, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.containerColor,
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        onTap: loading ? null : onPick,
        borderRadius: AppRadius.borderMD,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(persona.avatar, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(persona.name, style: context.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(persona.tagline, style: context.bodySmall.copyWith(color: context.textSecondary)),
                    const SizedBox(height: 6),
                    Text('"${persona.sample}"',
                        style: context.bodySmall.copyWith(fontStyle: FontStyle.italic, color: context.textMuted)),
                  ],
                ),
              ),
              if (loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/pages/ai/tutor/persona_picker_screen.dart 2>&1 | tail -3
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/pages/ai/tutor/persona_picker_screen.dart
git commit -m "feat(tutor): A1-F2 — persona picker screen (Nana/Sensei/Riko)

Three big cards with emoji avatars (🐻/🤖/🐙), name, tagline, and
a sample line so the user gets the vibe before committing. Cards
are full-width, ripple on tap, show a spinner inline while the PUT
flies. First-run mode hides the close button (forces a choice);
settings-reopened mode shows close so users can back out without
changing.

After successful PUT, invalidates tutorMemoryProvider and pushReplaces
to TutorHomeScreen so the picker isn't on the back stack."
```

---

### Task 9 (Flutter F3): Tutor home screen

**Files:**
- Create: `lib/pages/ai/tutor/tutor_home_screen.dart`

- [ ] **Step 1: Create the home screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/tutor/tutor_memory.dart';
import '../../../models/tutor/tutor_session.dart';
import '../../../providers/tutor_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import 'tutor_chat_screen.dart';
import 'persona_picker_screen.dart';

const _personaAvatars = {'nana': '🐻', 'sensei': '🤖', 'riko': '🐙'};
const _personaNames   = {'nana': 'Nana', 'sensei': 'Sensei', 'riko': 'Riko'};

class TutorHomeScreen extends ConsumerWidget {
  const TutorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(tutorMemoryProvider);
    final planAsync = ref.watch(tutorDailyPlanProvider);
    final sessionsAsync = ref.watch(tutorRecentSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        actions: [
          IconButton(
            tooltip: 'Change tutor',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonaPickerScreen(isFirstRun: false)),
            ),
          ),
        ],
      ),
      body: memoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load tutor: $e')),
        data: (memory) {
          if (memory.persona == null) {
            // First-time user — bounce to picker.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PersonaPickerScreen()),
              );
            });
            return const SizedBox.shrink();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tutorMemoryProvider);
              ref.invalidate(tutorDailyPlanProvider);
              ref.invalidate(tutorRecentSessionsProvider);
              await Future.wait([
                ref.read(tutorMemoryProvider.future),
                ref.read(tutorDailyPlanProvider.future),
                ref.read(tutorRecentSessionsProvider.future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroGreeting(memory: memory),
                const SizedBox(height: 16),
                _PlanCard(planAsync: planAsync),
                const SizedBox(height: 16),
                _StartChatButton(memory: memory),
                const SizedBox(height: 24),
                _RecentSessions(sessionsAsync: sessionsAsync),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroGreeting extends StatelessWidget {
  final TutorMemory memory;
  const _HeroGreeting({required this.memory});
  @override
  Widget build(BuildContext context) {
    final avatar = _personaAvatars[memory.persona] ?? '🐻';
    final name = _personaNames[memory.persona] ?? 'Nana';
    final lastSummary = memory.recentChatSummaries.isNotEmpty
        ? memory.recentChatSummaries.first.summary
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMD,
      ),
      child: Row(
        children: [
          Text(avatar, style: const TextStyle(fontSize: 56)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  lastSummary != null ? 'Last time: $lastSummary' : "Hey! Ready to learn together?",
                  style: context.bodyMedium.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final AsyncValue<DailyPlan?> planAsync;
  const _PlanCard({required this.planAsync});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: AppRadius.borderMD,
      ),
      child: planAsync.when(
        loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Plan unavailable: $e'),
        data: (plan) {
          if (plan == null || plan.tasks.isEmpty) {
            return Text('No plan for today — start a chat to begin.', style: context.bodyMedium);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's plan", style: context.titleSmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final t in plan.tasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(t.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: t.isDone ? AppColors.primary : context.textMuted, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_taskLabel(t), style: context.bodyMedium)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _taskLabel(DailyPlanTask t) {
    switch (t.type) {
      case 'srs_review':
        return 'Review ${t.count ?? 0} SRS cards (${t.completed} done)';
      case 'grammar_drill':
        return 'Practice: ${t.topic ?? "grammar"}';
      case 'tutor_chat':
        return 'Chat for ${t.minutes ?? 5} min (${t.completed} so far)';
      default:
        return t.type;
    }
  }
}

class _StartChatButton extends ConsumerWidget {
  final TutorMemory memory;
  const _StartChatButton({required this.memory});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TutorChatScreen()),
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Start chat'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
        ),
      ),
    );
  }
}

class _RecentSessions extends ConsumerWidget {
  final AsyncValue<List<TutorSession>> sessionsAsync;
  const _RecentSessions({required this.sessionsAsync});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return sessionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent', style: context.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final s in sessions.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  s.summary ?? '(no summary)',
                  style: context.bodySmall.copyWith(color: context.textSecondary),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verify analyze**

```bash
flutter analyze lib/pages/ai/tutor/tutor_home_screen.dart 2>&1 | tail -3
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/pages/ai/tutor/tutor_home_screen.dart
git commit -m "feat(tutor): A1-F3 — tutor home screen (greeting + plan + recent)

Top: persona avatar + name + 'Last time we worked on X' (or default
'Hey! Ready to learn together?' if no summary yet).

Middle: today's plan card — three task types render with done/not-done
icons; refreshable via pull-down.

CTA: 'Start chat' button (full-width, primary color).

Bottom: recent session summaries list (top 5).

If persona is null, bounces to PersonaPickerScreen automatically
on first frame. AppBar action: 'swap_horiz' icon opens the picker
in non-first-run mode for switching."
```

---

### Task 10 (Flutter F4): Tutor chat screen

**Files:**
- Create: `lib/pages/ai/tutor/tutor_chat_screen.dart`

- [ ] **Step 1: Create the chat screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/tutor/tutor_session.dart';
import '../../../providers/tutor_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/tutor/quiz_card.dart';
import '../../../widgets/tutor/vocab_card.dart';
import '../../../widgets/tutor/grammar_card.dart';

class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key});
  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(tutorChatControllerProvider.notifier).start();
        setState(() => _started = true);
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start: $e')));
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          _scrollCtl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(tutorChatControllerProvider.notifier).send(text);
    _scrollToBottom();
  }

  @override
  void dispose() {
    // Fire-and-forget end so memory updates on background.
    final state = ref.read(tutorChatControllerProvider);
    if (state.session != null) {
      ref.read(tutorChatControllerProvider.notifier).end();
    }
    _controller.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorChatControllerProvider);
    final messages = state.session?.messages ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Chat with tutor')),
      body: Column(
        children: [
          Expanded(
            child: !_started
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtl,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length + (state.sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _MessageBubble(message: messages[i]);
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: context.containerColor,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TutorMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    final body = switch (message.messageType) {
      'quiz_card'    => QuizCard(payload: message.payload ?? const {}),
      'vocab_card'   => VocabCard(payload: message.payload ?? const {}),
      'grammar_card' => GrammarCard(payload: message.payload ?? const {}),
      _              => _TextBubble(text: message.content, isUser: isUser),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.messageType != 'text' && message.content.isNotEmpty)
            Align(alignment: alignment, child: _TextBubble(text: message.content, isUser: isUser)),
          if (message.messageType != 'text') const SizedBox(height: 6),
          Align(alignment: alignment, child: body),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _TextBubble({required this.text, required this.isUser});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : context.containerColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : context.textPrimary),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyze (will error until card widgets exist in F5; ignore those errors for now)**

```bash
flutter analyze lib/pages/ai/tutor/tutor_chat_screen.dart 2>&1 | tail -5
```

Expected: errors about `QuizCard`/`VocabCard`/`GrammarCard` not found — fine. They land in the next task.

- [ ] **Step 3: Commit (deferring final analyze until F5 lands)**

```bash
git add lib/pages/ai/tutor/tutor_chat_screen.dart
git commit -m "feat(tutor): A1-F4 — tutor chat screen with bubble dispatcher

Starts a session on mount via tutorChatControllerProvider, ends
fire-and-forget on dispose (so memory updates without blocking
navigation).

_MessageBubble dispatches by messageType:
- 'text'         → rounded text bubble (left/right aligned by role)
- 'quiz_card'    → QuizCard widget
- 'vocab_card'   → VocabCard widget
- 'grammar_card' → GrammarCard widget

For non-text messages, the AI's intro 'content' text is rendered as
a small bubble above the card. Sending state shows a small spinner
where the next message would be."
```

---

### Task 11 (Flutter F5): Three card widgets

**Files:**
- Create: `lib/widgets/tutor/quiz_card.dart`
- Create: `lib/widgets/tutor/vocab_card.dart`
- Create: `lib/widgets/tutor/grammar_card.dart`

- [ ] **Step 1: Create `lib/widgets/tutor/quiz_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tutor_provider.dart';
import '../../utils/theme_extensions.dart';
import '../../core/theme/app_theme.dart';

class QuizCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;
  const QuizCard({super.key, required this.payload});
  @override
  ConsumerState<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends ConsumerState<QuizCard> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final question = widget.payload['question']?.toString() ?? '';
    final options = (widget.payload['options'] as List?)?.cast<String>() ?? const [];
    final correctIdx = (widget.payload['correctIdx'] as num?)?.toInt() ?? -1;
    final explanation = widget.payload['explanation']?.toString() ?? '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Quiz', style: context.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(question, style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            for (int i = 0; i < options.length; i++) ...[
              _OptionTile(
                label: options[i],
                state: _picked == null
                    ? _OptState.idle
                    : (i == correctIdx ? _OptState.correct : (i == _picked ? _OptState.wrong : _OptState.dim)),
                onTap: _picked == null ? () => _onPick(i, correctIdx) : null,
              ),
              const SizedBox(height: 6),
            ],
            if (_picked != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(explanation,
                  style: context.bodySmall.copyWith(color: context.textSecondary, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  void _onPick(int i, int correctIdx) {
    setState(() => _picked = i);
    // Fire the answer back as a user message so the AI can react.
    final pickedLabel = (widget.payload['options'] as List?)?[i]?.toString() ?? '';
    final isRight = i == correctIdx;
    ref.read(tutorChatControllerProvider.notifier).send(
      isRight ? "I picked: $pickedLabel (correct)" : "I picked: $pickedLabel (wrong — correct was option ${correctIdx + 1})",
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptState state;
  final VoidCallback? onTap;
  const _OptionTile({required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData? icon;
    switch (state) {
      case _OptState.correct:
        bg = Colors.green.withValues(alpha: 0.15); fg = Colors.green.shade800; icon = Icons.check_circle; break;
      case _OptState.wrong:
        bg = Colors.red.withValues(alpha: 0.15);   fg = Colors.red.shade800;   icon = Icons.cancel; break;
      case _OptState.dim:
        bg = context.containerColor;                fg = context.textMuted;     icon = null; break;
      case _OptState.idle:
        bg = context.surfaceColor;                  fg = context.textPrimary;   icon = null; break;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: fg))),
              if (icon != null) Icon(icon, color: fg, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/widgets/tutor/vocab_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../../utils/theme_extensions.dart';
import '../../core/theme/app_theme.dart';

class VocabCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;
  const VocabCard({super.key, required this.payload});
  @override
  ConsumerState<VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends ConsumerState<VocabCard> {
  bool _adding = false;
  bool _added = false;
  String? _error;

  Future<void> _addToVocab() async {
    setState(() { _adding = true; _error = null; });
    try {
      final res = await ApiClient().post('learning/vocabulary', body: {
        'word': widget.payload['word'],
        'language': widget.payload['language'],
        'definition': widget.payload['definition'],
        'example': widget.payload['example'],
      });
      if (!res.success) throw StateError(res.error ?? 'Failed');
      if (mounted) setState(() { _adding = false; _added = true; });
    } catch (e) {
      if (mounted) setState(() { _adding = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.payload['word']?.toString() ?? '';
    final ipa = widget.payload['ipa']?.toString();
    final definition = widget.payload['definition']?.toString() ?? '';
    final example = widget.payload['example']?.toString() ?? '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('Vocab', style: context.bodySmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(word, style: context.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                if (ipa != null && ipa.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('/$ipa/', style: context.bodySmall.copyWith(color: context.textMuted)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(definition, style: context.bodyMedium),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('"$example"', style: context.bodySmall.copyWith(fontStyle: FontStyle.italic, color: context.textSecondary)),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: (_adding || _added) ? null : _addToVocab,
                icon: Icon(_added ? Icons.check : Icons.add),
                label: Text(_added ? 'Added to vocab' : (_adding ? 'Adding…' : 'Add to vocab')),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `lib/widgets/tutor/grammar_card.dart`**

```dart
import 'package:flutter/material.dart';

import '../../utils/theme_extensions.dart';
import '../../core/theme/app_theme.dart';

class GrammarCard extends StatelessWidget {
  final Map<String, dynamic> payload;
  const GrammarCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final rule = payload['rule']?.toString() ?? '';
    final explanation = payload['explanation']?.toString() ?? '';
    final examples = (payload['examples'] as List?) ?? const [];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: Colors.purple.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined, size: 16, color: Colors.purple),
                const SizedBox(width: 6),
                Text('Grammar', style: context.bodySmall.copyWith(color: Colors.purple, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(rule, style: context.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(explanation, style: context.bodyMedium.copyWith(color: context.textSecondary)),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final ex in examples) ...[
                if (ex is Map) ...[
                  if (ex['correct'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(child: Text(ex['correct'].toString(), style: context.bodySmall)),
                      ],
                    ),
                  if (ex['wrong'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.close, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(ex['wrong'].toString(),
                              style: context.bodySmall.copyWith(decoration: TextDecoration.lineThrough, color: context.textMuted)),
                        ),
                      ],
                    ),
                  if (ex['note'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 22, bottom: 4),
                      child: Text(ex['note'].toString(),
                          style: context.bodySmall.copyWith(fontStyle: FontStyle.italic, color: context.textMuted)),
                    ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify analyze across all newly-created files**

```bash
flutter analyze lib/widgets/tutor/ lib/pages/ai/tutor/ lib/providers/tutor_provider.dart 2>&1 | tail -5
```

Expected: `No issues found!` — the chat screen's references should now resolve.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/tutor/
git commit -m "feat(tutor): A1-F5 — quiz / vocab / grammar card widgets

QuizCard: multi-choice with tappable options; on pick, sends the
chosen answer back as a user message ('I picked: X (correct/wrong)')
so the AI sees the choice and reacts on its next turn. Wrong + dim
states use color cues; correct is always revealed after a pick.

VocabCard: word + IPA + definition + example + 'Add to vocab' CTA
that POSTs the payload to /learning/vocabulary (existing endpoint).
Disabled after successful add; shows red error text on failure.

GrammarCard: rule + explanation + variable-length examples list,
each with optional correct/wrong/note rows (checkmark / strikethrough
/ italic). Pure stateless display."
```

---

### Task 12 (Flutter F6): ai_main hero card

**Files:**
- Modify: `lib/pages/ai/ai_main.dart`

- [ ] **Step 1: Read the current AI main screen**

```bash
sed -n '1,40p' lib/pages/ai/ai_main.dart
```

Identify the build method and where to inject the hero card. The tile grid for existing AI tools should stay; the hero goes at the top.

- [ ] **Step 2: Insert a hero card at the top of the AI tab**

Add an import:
```dart
import 'tutor/tutor_home_screen.dart';
import 'tutor/persona_picker_screen.dart';
import '../../providers/tutor_provider.dart';
```

Inside the existing AI-main `build`, at the top of the scrolling content (above the tile grid), add a `Consumer` widget reading `tutorMemoryProvider`:

```dart
Consumer(
  builder: (context, ref, _) {
    final mem = ref.watch(tutorMemoryProvider);
    return mem.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (memory) {
        final hasPersona = memory.persona != null;
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => hasPersona ? const TutorHomeScreen() : const PersonaPickerScreen(),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.18), AppColors.primary.withValues(alpha: 0.06)],
              ),
              borderRadius: AppRadius.borderMD,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Text(
                  hasPersona
                      ? (memory.persona == 'sensei' ? '🤖' : memory.persona == 'riko' ? '🐙' : '🐻')
                      : '🐻',
                  style: const TextStyle(fontSize: 44),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasPersona ? 'Your AI Tutor' : 'Meet your AI Tutor',
                          style: context.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        hasPersona ? 'Tap to chat or see today\'s plan' : 'Pick a persona to get started',
                        style: context.bodySmall.copyWith(color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  },
),
```

(Adapt to whichever Riverpod base class `ai_main.dart` uses — `ConsumerWidget`, `StatelessWidget` with a `Consumer` wrapper, etc.)

- [ ] **Step 3: Verify analyze**

```bash
flutter analyze lib/pages/ai/ai_main.dart 2>&1 | tail -3
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/pages/ai/ai_main.dart
git commit -m "feat(tutor): A1-F6 — AI tab hero card for the tutor

Adds a gradient hero card at the top of the AI tab. If the user has
no persona yet, says 'Meet your AI Tutor — Pick a persona to get
started' and routes to PersonaPickerScreen. If they do, says 'Your
AI Tutor — Tap to chat or see today's plan' and routes to
TutorHomeScreen.

Existing AI tool tiles (Translation, Pronunciation, Quiz, etc.)
stay below the hero unchanged — power users keep their direct
access to specialized tools."
```

---

### Task 13 (Flutter F7): Profile drawer entry + l10n keys

**Files:**
- Modify: `lib/pages/profile/drawer/profile_drawer.dart`
- Modify: `lib/l10n/app_en.arb` (and 18 other locale files)

- [ ] **Step 1: Add new l10n keys to `lib/l10n/app_en.arb`**

Add these keys (alphabetical insert is fine — match existing style):

```json
{
  "aiTutor": "AI Tutor",
  "aiTutorChangePersona": "Change AI tutor",
  "aiTutorChangePersonaSubtitle": "Switch to Nana, Sensei or Riko",
  "aiTutorPickHeader": "Who do you want to learn with?",
  "aiTutorPickSubtitle": "You can change this anytime in settings.",
  "aiTutorHeroTitleNew": "Meet your AI Tutor",
  "aiTutorHeroSubtitleNew": "Pick a persona to get started",
  "aiTutorHeroTitleSet": "Your AI Tutor",
  "aiTutorHeroSubtitleSet": "Tap to chat or see today's plan",
  "aiTutorHomeTitle": "AI Tutor",
  "aiTutorStartChat": "Start chat",
  "aiTutorChatTitle": "Chat with tutor",
  "aiTutorChatInputHint": "Type a message…",
  "aiTutorTodaysPlan": "Today's plan",
  "aiTutorPlanNone": "No plan for today — start a chat to begin.",
  "aiTutorPlanSrsReview": "Review {count} SRS cards ({done} done)",
  "@aiTutorPlanSrsReview": { "placeholders": { "count": { "type": "int" }, "done": { "type": "int" } } },
  "aiTutorPlanGrammar": "Practice: {topic}",
  "@aiTutorPlanGrammar": { "placeholders": { "topic": { "type": "String" } } },
  "aiTutorPlanChat": "Chat for {min} min ({done} so far)",
  "@aiTutorPlanChat": { "placeholders": { "min": { "type": "int" }, "done": { "type": "int" } } },
  "aiTutorRecent": "Recent",
  "aiTutorGreetFallback": "Hey! Ready to learn together?",
  "aiTutorLastTime": "Last time: {summary}",
  "@aiTutorLastTime": { "placeholders": { "summary": { "type": "String" } } },
  "aiTutorCardQuiz": "Quiz",
  "aiTutorCardVocab": "Vocab",
  "aiTutorCardGrammar": "Grammar",
  "aiTutorAddToVocab": "Add to vocab",
  "aiTutorAddedToVocab": "Added to vocab",
  "aiTutorAdding": "Adding…"
}
```

- [ ] **Step 2: Mirror translations for the 18 other locales**

For each `lib/l10n/app_<locale>.arb` file (ar, de, es, fr, hi, id, it, ja, ko, pt_BR, pt_PT, ru, es_419, th, tl, tr, vi, zh, zh_Hant — confirm the actual list with `ls lib/l10n/app_*.arb`), add the same keys with translations. **Use the existing translation style** in those files (formal vs casual, emoji usage, etc. — match the surrounding tone).

For a fast pass: keep the persona names ("Nana", "Sensei", "Riko") and emoji literals identical across locales; translate only the surrounding text. Punt to a translation pass post-merge if needed; what matters now is the English fallback is correct.

- [ ] **Step 3: Add the "Change AI tutor" row to the profile drawer**

Find where other Support-section rows live in `lib/pages/profile/drawer/profile_drawer.dart` (search for `l10n.helpCenter` or similar). Add:

```dart
import 'package:bananatalk_app/pages/ai/tutor/persona_picker_screen.dart';

// inside the Support DrawerSectionContainer:
DrawerMenuItem(
  icon: Icons.smart_toy_rounded,
  iconColor: const Color(0xFF00BFA5),
  title: l10n.aiTutorChangePersona,
  subtitle: l10n.aiTutorChangePersonaSubtitle,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => const PersonaPickerScreen(isFirstRun: false)),
    );
  },
),
```

Place this between two existing rows in the Support section (e.g. between "Help Center" and "Legal & Privacy") so it feels at home.

- [ ] **Step 4: Verify analyze**

```bash
flutter analyze lib/pages/profile/drawer/profile_drawer.dart 2>&1 | tail -3
```

- [ ] **Step 5: Commit**

```bash
git add lib/pages/profile/drawer/profile_drawer.dart lib/l10n/
git commit -m "feat(tutor): A1-F7 — drawer entry + l10n keys (18 locales)

27 new English ARB keys (persona picker copy, hero card variants,
chat UI, daily plan task labels with plural-friendly placeholders,
card labels). Mirrored translations across the 18 other locale
files with the same tone the rest of the app uses.

Profile drawer gets a 'Change AI tutor' row under Support — opens
PersonaPickerScreen in non-first-run mode so existing users can
swap persona without losing memory."
```

---

### Task 14 (Glue G1): Smoke test, branch finishing, merge prep

**Files:** none (just verification + branch hygiene)

- [ ] **Step 1: Full Flutter analyze (whole project)**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze 2>&1 | grep -E "error •" | head -10
```

Expected: 0 errors. Pre-existing info-level lints OK.

- [ ] **Step 2: Full backend syntax pass**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node --check controllers/tutor.js && node --check routes/tutor.js && node --check services/tutorService.js && node --check models/TutorMemory.js && node --check models/AITutorSession.js && node --check middleware/rateLimiter.js && node --check server.js && echo "ALL OK"
```

Expected: `ALL OK`

- [ ] **Step 3: Manual smoke test outline (do these on a simulator + your dev backend)**

1. Cold-start the app, log in. Open AI tab. Hero shows "Meet your AI Tutor — Pick a persona to get started." Tap.
2. Persona picker shows 3 cards (🐻 / 🤖 / 🐙). Tap one. Loads TutorHomeScreen.
3. TutorHome shows greeting + plan + "Start chat".
4. Tap Start chat. New session created, opening greeting message renders.
5. Type "Help me with past tense." Send. AI replies with text (or a quiz/vocab/grammar card).
6. If a quiz card appears, tap an option → AI replies with feedback.
7. If a vocab card appears, tap "Add to vocab" → succeeds.
8. Close the chat screen. On dispose, `/sessions/:id/end` should fire (check backend logs for `[tutor.endSession]` or similar).
9. Re-open AI tab → TutorHome greeting now references "Last time: ..." with the summary.
10. Open drawer → Support → "Change AI tutor" → picker reopens, can switch persona.

- [ ] **Step 4: Verify branch state**

```bash
git -C /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app log --oneline main..HEAD
git -C /Users/davis/Desktop/Personal/language_exchange_backend_application log --oneline main..HEAD
```

Expected: 7 commits on Flutter feature branch, 6 commits on backend feature branch.

- [ ] **Step 5: Merge to main with `--no-ff` on both repos**

```bash
git -C /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app checkout main
git -C /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app merge --no-ff feat/step9-ai-tutor-a1 -m "Step 9 — AI Tutor foundation (A1) Flutter merge

Persona picker + tutor home + chat + 3 card widgets + AI hero
+ drawer entry + l10n keys. Backed by /api/v1/tutor/* endpoints."

git -C /Users/davis/Desktop/Personal/language_exchange_backend_application checkout main
git -C /Users/davis/Desktop/Personal/language_exchange_backend_application merge --no-ff feat/step9-ai-tutor-a1 -m "Step 9 — AI Tutor foundation (A1) backend merge

TutorMemory + AITutorSession models, tutorService, controller with
8 endpoints, routes, rate limiter, memory hooks from grammar + quiz."
```

- [ ] **Step 6: Push both**

```bash
git -C /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app push origin main
git -C /Users/davis/Desktop/Personal/language_exchange_backend_application push origin main
```

- [ ] **Step 7: Delete feature branches**

```bash
git -C /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app branch -d feat/step9-ai-tutor-a1
git -C /Users/davis/Desktop/Personal/language_exchange_backend_application branch -d feat/step9-ai-tutor-a1
```

- [ ] **Step 8: Surface completion summary to the user**

Mention:
- 14 commits shipped, both `main` branches pushed
- Manual TODOs: nothing (the feature is self-contained — no LiveKit-style external dashboard registration)
- A2 (voice + 2 more card types) is the next wave whenever they're ready

---

## Cadence guidance for the executor

- The user's standing preference is "drive uninterrupted" — surface ONLY at the wave's end or on genuine blockers.
- Don't pause for confirmation between tasks. Each commit is independently revertable if anything goes sideways.
- If `aiProvider.chatJson` doesn't exist on the backend (Task 2), inspect `services/aiConversationService.js` for the actual function name and adapt — that's not a blocker, just a 5-minute name swap.
- If a card payload comes back malformed from OpenAI in testing, `parseTutorReply` will fall back to a text bubble; that's intentional. Log the bad JSON for prompt-tuning later.
- Manual smoke-test (Task 14 Step 3) can be a quick happy-path pass; deep edge-case testing waits for A2's voice work or a dedicated QA wave.

## Risk + rollback

- Worst-case: bad system prompts → tutor produces unhelpful replies. Fix is updating `PERSONA_PROMPTS` in `services/tutorService.js`; no schema change.
- If memory hooks (B6) cause issues, the try/catch already swallows; revert just B6 if needed without affecting the rest.
- Whole wave is gated by route existence. Hide the AI hero card via a one-line conditional in `ai_main.dart` to dormant the feature if something terrible happens.
