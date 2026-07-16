# AI Study: Depth → Habit → Charge — Design

**Date:** 2026-07-16
**Status:** Approved by user (full-auto mandate; lead thrust chosen 2026-07-16: "AI Study depth → habit → charge", scope "overall features")
**Repos:** `bananatalk_app` + `language_exchange_backend_application`
**Companion workstream:** Coins v1 (approved plan `2026-07-13-coins-v1-alacarte-unlocks.md`) is EXECUTING in parallel on `workstream-f-coins` — it owns the coin shop + unlock CTAs. This spec does not duplicate it; §Charge only covers coordination.

## Why (measured 2026-07-16, prod, ~706 users)

| Signal | Number | Meaning |
|---|---|---|
| Users touching tutor chat / 7d | **201** | AI Study is the app's biggest engagement surface |
| Tutor sessions per user / month | **~1.5** | pure sampling — no habit |
| Users at the 5/day cap today | 7 | real but small paying-intent audience |
| SRS reviews EVER processed | **0** (95 vocab docs, totalReviews=0 across all) | the core learning loop has never worked once |
| XP > 0 | 18.3% of learningprogresses; **0** quizattempts, **0** achievements ever | gamification dead by construction, not by disinterest |
| tutormemories | 645 docs, written daily, READ into prompts | memory loop is real but half-fictional |
| aiusagelogs for tutor chips | **zero rows ever** | the monetized surface is unmeasured |

**Thesis:** don't build new features — *resurrect the broken loop that's already built*, make sessions accumulate into something, give users a daily reason to return, and the existing cap + coins turn habit into revenue.

## The loop this ships

```
Today tab (habit) → session that KNOWS you (depth) → ends with durable artifact
     ↑                                                        ↓
push reminders ← streak/XP tick ← vocab & review items accumulate
     → more usage → more cap-hits → coins (+sessions) / VIP (unlimited)
```

## Phase 1 — Resurrections (small fixes, outsized returns)

### H1. Fix the SRS review contract (the never-worked bug)
`learning_service.dart` sends `{correct: bool}`; `controllers/learning.js:276-283` requires `quality: 0-5` and 400s; the app swallows the error. **Fix on the backend for backward compatibility with every shipped app**: accept `quality` when present, else map `correct: true → quality 4`, `false → quality 1` (SM-2: <3 = lapse). Also fix the app to send `quality` going forward (grading UI can stay boolean; the mapping is explicit). Also fix the VocabCard manual-add contract bug (`definition` vs `translation`). Result: the SM-2 engine (`Vocabulary.processReview`, already correct) and the live 9AM-KST SRS push reminders finally do something.

### H2. Wire tutor activity into XP/streaks (the trapped-XP bug)
Session-end (all chips) calls `learningTrackingService.awardXP` + `updateStreak` (today `aiConversationService` writes `xpEarned` onto the conversation doc only). Fix `updateStreak`'s early-return when no LearningProgress doc exists (create-on-first-award — `awardXP` already bootstraps, `learningTrackingService.js:286-294`). DailyPracticeCard completion awards XP (it currently awards **zero** XP anywhere — `gradeDailyPractice` returns only score/feedback). Fix the **`justMastered` always-false bug** (`Vocabulary.js:321` checks `!this.masteredAt` after `:310` just set it) so the mastery celebration/XP bonus can actually fire. Do NOT resurrect the parallel dead `users.totalXp` fields — learningprogresses is the one system. Achievements stay out of scope (no unlock engine exists; backlog). *(Spec-review correction: the previously-listed lessonBuilder dropped-fields fix was a misattributed non-bug — `trackLessonCompletion` writes valid schema fields; item removed.)*

### H3. Instrument + tighten the quota surface
- `trackUsage` on all 5 tutor endpoints with per-chip feature names; extend `AIUsageLog` schema with tokens/cost fields (currently silently dropped by strict mode). Story stops mislogging as 'conversation'.
- Close the quota leaks: pronunciation gates only the summary call, photo gates only describe, roleplay-active chats skip the chat quota (`checkTutorQuota.js:97-100`) — meterings must match the product promise of 5/day/chip.

### H4. Papercut batch (protects everything above)
From the audit's ranked list: fake vocab delete (working service method exists, unused); invisible chat send failures (`state.error` never rendered; null-overlay upgrade-sheet no-op); pronunciation save lost on back-swipe (`PopScope`); roleplay never auto-ends on dispose (chat does); stale quota pills for story/photo/pronunciation; DailyPracticeCard collapsing to `SizedBox.shrink()` on error; dead vocab-row tap target.

## Phase 2 — Depth (sessions that accumulate)

### H5. Durable session endings + resumability
**Precondition (spec-review C1 — load-bearing):** only chat + roleplay create an `AITutorSession` today; story, photo, and pronunciation are session-less one-shots, so "recap + tappable history" is impossible for them as-is. **Design decision: persist a lightweight `AITutorSession` for those three chips too** — extend the `mode` enum (currently `['free','roleplay']`, `models/AITutorSession.js:14`) with `'story'|'photo'|'pronunciation'`, created at generation/summary time with the artifact inline (no per-turn messages needed for one-shots). Story/photo lack a server "end" hook — their session doc IS the end artifact, written in the same request.
Every chip then ends in a **session recap**: summary, vocab captured (server already extracts for chat; story NEWLY writes its `vocabUsed` to Vocabulary — target design, it currently discards it; photo NEWLY writes its suggestedVocab; pronunciation keeps its weakArea/SRS bridge but saves on ANY exit), weak areas touched, XP earned. Recaps are revisitable: the past-session list (backed by `listSessions`, which now sees all chips) becomes tappable (`GET /tutor/sessions/:id` exists with zero callers) → read-only transcript/artifact + "continue this conversation" for chat/roleplay (new session seeded with the old summary — no long-context resumption, just continuity; one-shot chips reopen their artifact instead). Roleplay auto-ends **client-side on dispose** (calling the existing `/sessions/:id/end` — there is no server auto-end), receiving its grade like chat does.

### H6. Make tutor memory real
- Resolve `vocabFocus` to actual words in the prompt (today: raw ObjectIds) AND start writing it (from SRS due/lapsed words).
- Pass the TRUE SRS due count into the prompt; delete the hallucinated `srs_due_card` behavior (schema field stays, model now told the real number).
- **Mastery/decay:** weakAreas gain `resolvedAt`; frequency decays (halve on 14 days unseen, keyed off the existing `lastSeen` field). **This requires a NEW daily pass over TutorMemory** (spec-review I2: no existing job iterates it) — hosted in `jobs/scheduler.js` alongside the other daily KST jobs. A weak area exercised successfully N times gets marked resolved and drops from prompts (never resurrects without new evidence). `proficiencyLevel` stays profile-synced (performance-based leveling = backlog, noted). H6's audit claims (vocabFocus never written / ObjectId injection / hallucinated due counts) get re-confirmed with a grep at build time — flagged honestly by the reviewer as unverifiable during the TCC lockout.

### H7. Story persistence + My Stories
New small `TutorStory` collection (user, level, title, paragraphs, vocabUsed, createdAt) written at generation; "My Stories" shelf in AI Tools; reader opens saved stories. Cheap re-read content + the natural future VIP/coins surface ("story library"). Log as feature 'story'.

## Phase 3 — Habit

### H8. "Today" is the landing experience
Reorder `learning_main_screen` tabs: the Learn tab (ProgressHero → streak → **due reviews** → DailyPracticeCard → "continue your last session" chip) becomes the default landing; Exam Study moves to last (26 users vs thousands of tutor touches — it stays, just not first). Keep the internal `animateTo(1)` "switch to AI" callback aligned with the new order (spec-review). The "continue" chip reads `listSessions` — which after H5 covers all five chips. Everything on Today awards XP/streak (H2) so the loop is visible. **First-run review flood (spec-review I3):** all 95 legacy vocab docs become due the moment H1 lands (`nextReview` defaulted to now, 0 reviews ever) — the Today due-review surface caps its batch (e.g. 10 per session, "more waiting" affordance) and the SRS push says "you have reviews waiting," never a raw count, so the backlog reads as an invitation, not a wall. No data migration needed (SM-2 reschedules naturally as reviews process). Study-plan setup friction (mandatory exam date) noted as exam-study backlog, not this wave.

### H9. Curated vocabulary packs (Intermediate + Advanced English)
Seed content for the resurrected loop, derived from the two reference books the owner supplied (Cambridge *Vocabulary in Use* Intermediate + Advanced PDFs). **Copyright boundary held explicitly:** the books are used ONLY as a coverage checklist — topic taxonomy + headword inventory per level; ALL definitions, example sentences, and translations are generated originally by us. Deliverable: level-tagged (`intermediate`/`advanced`) English vocab packs seeded server-side (additive seeder, same safety pattern as seeds/languages.js) + a "word packs" browse surface in AI Study where a user adds a pack (or single words) into their personal Vocabulary → flows straight into SRS review, vocabFocus, story generation, and Today's "learn 5 new words." Pack size target: ~300-500 headwords per level, themed by topic.

## Phase 4 — Charge (coordination only — Coins v1 owns the build)

- Coins v1 app track already adds "+3 sessions for 💎N" beside "Upgrade to VIP" in `PersonaUpgradeSheet` (the single funnel all tutor 429s flow through) — chip-specific via `triggerChip`.
- This wave's contribution to revenue is the funnel itself: more habit → more cap-hits (7/day today; success = 20+/day).
- VIP stays as-is: prior verification showed iOS/Android product IDs match the stores — the "mismatch" in the audit is app-vs-backend *fallback display* only, not a purchase blocker.
- `AI_QUOTA_ENABLED` kill switch untouched; quotas stay 5/day/chip for free tiers, VIP unlimited.

## Explicitly out of scope
Achievements unlock engine, performance-based proficiency leveling, exam-study revamp beyond tab reordering, streaming tutor responses, model upgrades, coins/VIP pricing changes, `users.totalXp` parallel fields (dead — left dead).

## Error handling & edge cases
- SRS mapping is backend-first so ALL shipped app versions are fixed at once; old apps keep sending `correct` forever — permanently supported.
- XP writes are fire-and-forget from session paths (a tracking failure never breaks a session; log + continue).
- Session-recap save failure → recap still shown from client state, retry on next open; never blocks the user.
- Memory decay job is idempotent; resolved weakAreas never resurrect without new evidence.
- Story save failure degrades to current behavior (ephemeral story) with a retry toast.
- Tab reorder respects deep links (existing routes keep working; only default index changes).

## Testing
Backend (node:test, Node v24 runner): quality-mapping (both contracts), awardXP/updateStreak bootstrap + idempotence, quota-leak closures, decay/resolve logic, TutorStory CRUD, telemetry writes per chip. App: `flutter analyze` 0 errors; provider tests where pure. Device smoke at gate: review a vocab card and see srsLevel advance in DB; finish a tutor session and see streak/XP tick + recap; back-swipe pronunciation and find it saved; reopen a story; land on Today tab.

## Success metrics (re-measure weekly)
Sessions/user/month 1.5 → 3+; SRS reviews processed 0 → 50+/week; streak holders 13 → 50+; cap-hits/day 7 → 20+; then coin purchases > 0 (Coins v1 metric) once store products exist.
