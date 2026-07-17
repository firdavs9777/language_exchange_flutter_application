# AI Study: Depth → Habit → Charge — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resurrect the never-worked learning loop (SRS reviews, trapped XP, unmeasured tutor), make every tutor session durable/resumable with real memory, land users on a Today habit surface, and seed curated vocab packs — so the existing cap + the in-flight Coins v1 monetize the habit.

**Architecture:** Surgical fixes to existing systems (SM-2 engine, learningTrackingService, TutorMemory prompt loop) + three small additive pieces (session persistence for one-shot chips via `AITutorSession.mode` extension, a TutorMemory decay job, a VocabPack seeder/browse). No new subsystems.

**Tech Stack:** Node/Express + Mongoose (node:test via Node v24), Flutter + Riverpod.

**Spec:** `docs/superpowers/specs/2026-07-16-ai-study-depth-habit-charge-design.md` (review round applied: C1 session-less chips, I1 non-bug removed, I2 new decay job, I3 first-run flood, minors)

**Repos:** backend `/Users/davis/Desktop/Personal/language_exchange_backend_application`, app `/Users/davis/Desktop/Personal/language_exchange_flutter_application` (git root = parent of bananatalk_app).

**Global constraints:**
- **Branch:** `workstream-h-aistudy` in both repos off main. Per-task commits. Never push (controller verifies + pushes).
- **Coins coordination (hard rule):** Coins v1 is in flight on `workstream-f-coins`. Backend: do NOT touch `models/User.js`, `config/limitations.js`, `controllers/appConfig.js`, `controllers/moments.js`, `controllers/auth.js` (coins owns them this cycle). App: the APP track starts only AFTER coins' app track lands; do NOT touch `main.dart`'s quota handler, `persona_upgrade_sheet.dart`, app-bar pills (coins owns them) — the H4 null-overlay fix in `main.dart` is executed as a follow-up patch after coins merges.
- **Backend tests:** Node v24 runner `~/.nvm/versions/node/v24.18.0/bin/node --experimental-test-module-mocks --test services/*.test.js test/*.test.js`; baseline 1 pre-existing failure (`profileVisitCleanup`); no new failures. Pure helpers in `lib/` where DB blocks unit tests (established pattern).
- **App:** `package:` imports; `flutter analyze` 0 errors per commit.
- Trust file+function names over line numbers (repo moves fast).

---

## BACKEND PHASE (branch workstream-h-aistudy)

### Task 1: SRS review contract fix (the never-worked bug) — H1
**Files:** `controllers/learning.js` (review endpoint ~:276-283), `models/Vocabulary.js` (justMastered bug :321); Test `test/srsReviewContract.test.js`.
- [ ] Backend-first compat: accept `quality` (0-5) when present; else map `correct: true→4, false→1`; 400 only when neither present. (SM-2 verified: quality<3 = lapse.)
- [ ] Fix `justMastered` always-false (`Vocabulary.js:321` checks `!this.masteredAt` after :310 set it — capture prior value before mutation).
- [ ] TDD: quality passthrough, correct-mapping, neither→400, lapse behavior, justMastered fires exactly once on the 9th-level transition.
- [ ] Full suite green. Commit `fix(srs): accept correct→quality mapping — first working review path` .

### Task 2: XP/streak wiring — H2
**Files:** `services/learningTrackingService.js` (updateStreak early-return :326-327), `controllers/tutor.js` (endSession, pronunciation summary), `services/aiConversationService.js`, `controllers/learning.js` (gradeDailyPractice ~:1668); Test `test/xpWiring.test.js`.
- [ ] `updateStreak` bootstraps a LearningProgress doc when missing (mirror awardXP :286-294).
- [ ] Session-end paths call `awardXP` + `updateStreak` fire-and-forget (try/catch, never break the session): chat/roleplay in `endSession`, pronunciation in `/pronunciation/summary`, story+photo in their generation endpoints (they're one-shots — award on completion). Sensible XP values: reuse existing xpRewards config scale.
- [ ] `gradeDailyPractice` awards XP + streak on submission (currently returns score only).
- [ ] Do NOT touch `users.totalXp` parallel fields.
- [ ] TDD pure decision helpers (xp-per-chip table, bootstrap branch). Suite green. Commit.

### Task 3: Tutor telemetry + quota-leak closure — H3
**Files:** `models/AIUsageLog.js` (add tokens/cost/meta fields), `controllers/tutor.js` + tutor services (trackUsage per chip: 'chat','roleplay','story','photo','pronunciation'), `middleware/checkTutorQuota.js` + `routes/tutor.js` (leaks); Test `test/tutorTelemetry.test.js`.
- [ ] `trackUsage` on all 5 chip endpoints with real feature names; extend schema so tokens/cost persist (strict mode currently drops them).
- [ ] Close leaks: pronunciation sentence/score gated (count once per session start, not per call — decide: gate `/pronunciation/sentence` first-call per session); photo `grade` gated with `describe`; roleplay-active chat messages no longer skip chat quota IF that skip is exploitable (verify intent — roleplay messages consume roleplay quota at start; document decision either way).
- [ ] Suite green. Commit.

### Task 4: Session persistence for one-shot chips + recap payloads — H5 backend
**Files:** `models/AITutorSession.js` (mode enum += 'story','photo','pronunciation'; artifact field), `controllers/tutor.js` (create session docs in generateStory / imageVocab / pronunciation summary; story vocabUsed → Vocabulary upsert; photo suggestedVocab → Vocabulary upsert), `listSessions` already returns all modes; Test `test/oneshotSessions.test.js`.
- [ ] Story: persist `{mode:'story', artifact:{title, paragraphs, vocabUsed}, summary}` at generation (resolves spec H5/H7 into ONE store — no separate TutorStory collection; "My Stories" = listSessions mode:story). Log decision in code comment.
- [ ] Photo: persist artifact (imageUrl ref, suggestedVocab, grammarNotes) + write suggestedVocab to Vocabulary (respect vocabularyLimit).
- [ ] Pronunciation: summary endpoint persists the session doc (scores, weakAreas) — the save-on-any-exit app change is Task 9's.
- [ ] Chat recap: `endSession` response already carries summary; ensure vocab captured during session is included in the response payload for the recap screen.
- [ ] Suite green. Commit.

### Task 5: Real memory + decay — H6
**Files:** `services/tutorService.js` (prompt builder), `models/TutorMemory.js` (`resolvedAt` on WeakAreaSchema), NEW `jobs/tutorMemoryDecayJob.js` + wire in `jobs/scheduler.js`, vocabFocus writers; Test `test/memoryDecay.test.js`.
- [ ] BUILD-TIME RE-CONFIRM (reviewer could not): `grep -rn vocabFocus services controllers jobs` + read prompt builder — then: resolve vocabFocus wordIds to actual words in the prompt; write vocabFocus from SRS state (due/lapsed words, capped ~10).
- [ ] Pass TRUE due count into the prompt (query Vocabulary dueForReview count); remove hallucinated-count behavior.
- [ ] Decay job (daily, scheduler.js KST pattern): weakAreas frequency halves when lastSeen > 14d; resolved when exercised successfully N=3 times (track via a small counter or infer); `resolvedAt` set → excluded from prompts, never auto-resurrected.
- [ ] Suite green. Commit.

### Task 6: Vocab packs — H9 backend
**Files:** NEW `models/VocabPack.js` (level, topic, words[{word, definition, example, translationHint}]), NEW `seeds/vocabPacks.js` (ADDITIVE upserts, seeds/languages.js safety pattern), routes `GET /learning/vocab-packs`, `POST /learning/vocab-packs/:id/add` (bulk-add pack words into user Vocabulary, respecting vocabularyLimit, skipping duplicates); Test `test/vocabPacks.test.js`.
- [ ] **Content source:** the controller (me) supplies `migrations/vocabPacksData.json` — headword inventory derived from the owner's reference books (coverage only), all definitions/examples GENERATED ORIGINALLY. The implementer builds the machinery against a small placeholder pack + swaps in the real data file when provided; seeder validates shape (no dup words per pack, all fields present).
- [ ] Suite green. Commit.

**== BACKEND DONE (T1–T6) ==**

## APP PHASE (branch workstream-h-aistudy — STARTS AFTER coins app track lands)

### Task 7: SRS + papercuts batch — H1 app + H4
**Files:** `learning_service.dart` (send `quality`), `vocab_card.dart` (translation contract), `vocabulary_screen.dart` (real delete — service method exists unused; row tap → detail), `tutor_chat_screen.dart` (+provider: render `state.error` as inline retry bubble), `roleplay_chat_screen.dart` (auto-end on dispose like chat), `pronunciation_session_screen.dart` (PopScope: save on ANY exit), `tutor_provider.dart` (refresh quotas after story/photo/pronunciation), `daily_practice_card.dart` (error/loading states + retry instead of shrink).
- [ ] NOT here: `main.dart` null-overlay fix (post-coins follow-up patch).
- [ ] analyze 0 errors. Commit per logical unit (2-3 commits fine).

### Task 8: Recaps, history, continue — H5 app
**Files:** NEW `session_recap_screen.dart` (summary, vocab chips, weak areas, XP earned — shown at every chip's session end), tutor home past-session list → tappable (transcript/artifact view per mode; "continue" for chat/roleplay seeds a new session with the old summary; story/photo reopen artifact), wire all 5 chips' exits through the recap.
- [ ] analyze 0 errors. Commit.

### Task 9: Today landing + due reviews — H8
**Files:** `learning_main_screen.dart` (tab order: Learn/Today first, AI second, Exam last; fix internal `animateTo` index), Learn tab: due-reviews module (CAPPED batch of 10, "more waiting" affordance), streak/XP visibility, "continue your last session" chip (listSessions[0]), DailyPracticeCard XP surfacing.
- [ ] analyze 0 errors. Commit.

### Task 10: My Stories + Word Packs — H7/H9 app
**Files:** NEW `my_stories_shelf.dart` (listSessions mode:story → reader), NEW `vocab_packs_screen.dart` (browse packs by level/topic, add-pack → success state → vocab list), entries in AI Tools tab.
- [ ] analyze 0 errors. Commit.

**== APP DONE (T7–T10) ==**

## GATE — Task 11
- [ ] Backend suite (Node v24) + analyze: no new failures / 0 errors. Branch tips only contain H commits.
- [ ] Whole-branch review both repos (focus: review-mapping correctness, XP fire-and-forget isolation, session-doc growth for one-shots, decay idempotence, pack bulk-add duplicate/limit handling, no coins-owned files touched).
- [ ] Merge order: coins (workstream-f) merges FIRST, then workstream-h (resolve any drift), then the post-coins `main.dart` follow-up patch.
- [ ] Device smoke: review a card → srsLevel advances in DB; finish sessions on all 5 chips → recap + streak tick; back-swipe pronunciation → saved; reopen a story; add a word pack → words reviewable; Today lands first with capped due list.
- [ ] Metrics (weekly): sessions/user/mo 1.5→3+, SRS reviews 0→50+/wk, streak holders 13→50+, cap-hits/day 7→20+.

## Deferred (unchanged from spec)
Achievements engine, performance-based leveling, exam-study revamp, streaming responses, users.totalXp cleanup.
