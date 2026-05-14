# Step 17 — Memory Loop Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the memory loop for Pronunciation users by routing their weak words into the existing SM-2 spaced repetition queue, then surface that queue on the AI Study tab so users see what's due for review the moment they open the app.

**Architecture:** Most of the work is already done. `models/Vocabulary.js` implements full SM-2 (srsLevel, easeFactor, interval, nextReview, processReview, getDueForReview). `GET /api/v1/learning/vocabulary/review` returns due items. Flutter has `VocabularyReviewScreen` + `SrsDueCard` + `dueReviewsProvider`. Two gaps remain: (1) `submitPronunciationSummary` writes to `TutorMemory.weakAreas` but never to `Vocabulary`, so Pronounce-chip users never feed the SRS engine; (2) the existing review surfaces live under `/learning/vocabulary/` and aren't reachable from the tutor tab. This wave fixes both — one backend bridge + one Flutter card insertion. No new model, no new endpoint, no decay job.

**Tech Stack:** Node.js / Express / Mongoose (backend); Flutter / Riverpod (mobile). No new dependencies.

**Recon reference:** `docs/superpowers/recon/2026-05-14-step17-memory-loop-recon.md`.

**Branches:** `feat/step17-memory-loop` on both repos.

**Estimated commits:** 4 (B1 backend bridge, F1 Flutter card insertion, G1 glue, plus docs).

**Pacing:** Drive uninterrupted per the user's recorded preference. Surface only at G1 or on a genuine blocker.

---

## Hard constraints

- **Out of scope:** Chat → Vocabulary auto-extraction (Step 18 candidate), backfill of existing `TutorMemory.weakAreas pronunciation:*` items into Vocabulary, translation backfill for empty-translation records, AI Study bottom-nav badge polish, word lemmatization, `vocabFocus` dead-field cleanup on TutorMemory.
- **No new dependencies.**
- **No new model or endpoint.** Reuse Vocabulary + the existing /learning/vocabulary/review endpoint exactly as-is.
- **Match existing commit-message style** — no Co-Authored-By, no marketing copy.
- **Both repos use branch `feat/step17-memory-loop`** for execution.

---

## Edge cases handled

- **First-time Pronunciation submission.** User struggles with 3 words → those 3 words land in `Vocabulary` with `srsLevel: 0` and `nextReview: now`. Next tutor-tab open, the Review card appears.
- **Repeat weak word.** Second pronunciation session with the same word → `findOneAndUpdate` with `$setOnInsert` is a no-op for the SRS fields. `TutorMemory.weakAreas` frequency still increments — that's the visible "you keep getting this wrong" signal. Vocabulary's SRS handles the recall side.
- **Translation missing.** Pronunciation bridge inserts with `translation: ''`. Review screen reads it. If the review screen crashes on empty translation, that's a smoke finding — likely it renders "(no translation)" or skips the back side.
- **User with no `language_to_learn`.** Should not exist, but guard. Read from `req.user.language_to_learn`; fall back to `'en'` if missing. Skip insert if both target and native are absent.
- **Vocabulary already exists for the word.** `findOneAndUpdate` upsert finds it. `$setOnInsert` is a no-op. Existing SRS state preserved.
- **`dueReviewsProvider` returns null / loading / error.** Tutor tab `when` branch — render nothing for non-data states. No card flicker.
- **Due count below threshold.** Card hidden. User must visit `/learning/vocabulary/` SRS dashboard to see all due items (existing surface).

---

## Design decisions

1. **D-1 translation handling: LEAVE EMPTY (`translation: ''`).** Bridge inserts blank; review screen handles inline. **Rejected:** inline OpenAI translation call (latency + cost), skip-insert when no translation (defeats the bridge).

2. **D-2 review card threshold: SHOW WHEN `dueCount >= 3`.** Matches the earlier scope pick. **Rejected:** show at 1+ (noisy), always show with empty state (wastes vertical space).

3. **D-3 card widget: REUSE EXISTING `SrsDueCard` from `lib/widgets/tutor/`.** Zero new widget code. **Rejected:** new `TutorTabReviewCard` (duplication; refactor later if visual smoke says misfit).

4. **D-4 chat auto-extraction: PUNT TO STEP 18.** This wave covers Pronunciation only. **Rejected:** include LLM-based session-end extraction now (needs UX design + cost evaluation).

5. **D-5 no decay job.** SM-2 naturally produces due-now items via `nextReview <= now`. No active decay computation needed. Originally-planned daily job removed from scope.

---

## File structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Modify:**
- `controllers/tutor.js` — after the existing `TutorMemory.weakAreas` upsert loop in `submitPronunciationSummary` (line ~666), add a parallel loop that upserts each weak word into `Vocabulary`.

**No new files.**

### Flutter (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

**Modify:**
- `lib/pages/learning/main/sections/ai_tools_tab.dart` — insert `SrsDueCard` (Consumer-wrapped) between `_AITutorHero` (line ~49) and `_TutorModeChips` (line ~53). Card renders only when `dueCount >= 3`.
- Possibly: `lib/widgets/tutor/srs_due_card.dart` — if the existing widget's threshold is hardcoded differently, surface the threshold as a constructor parameter.

**No new files.**

---

## Critical decisions baked in

1. **`Vocabulary` is the only mastery store.** No new `Mastery` model. The pronunciation bridge writes directly to `Vocabulary` with `context.source: 'pronunciation'` so admins / future analytics can filter by entry origin.

2. **`$setOnInsert` semantics for the bridge.** Re-running the bridge on the same word does not reset SRS progress. Only the initial insert sets srsLevel / nextReview / easeFactor. Update of `TutorMemory.weakAreas` frequency is a separate concern.

3. **Tutor tab card is a thin pass-through.** No new state, no new fetch. The `dueReviewsProvider` already exists and is invalidated whenever the user completes a review. Card just `ref.watch`es and conditionally renders.

4. **No fallback to `/learning/vocabulary/` in the tutor tab.** When `dueCount < 3` (or zero), the card is hidden. Users with fewer due items can still navigate to the SRS dashboard from the learning surface — that path is unchanged.

---

## Task 0: Branch setup

- [ ] **Step 1: Verify clean working trees.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application && git status --short
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app && git status --short
```

- [ ] **Step 2: Create execution branches from main.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull --ff-only && git checkout -b feat/step17-memory-loop

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull --ff-only && git checkout -b feat/step17-memory-loop
```

- [ ] **Step 3: Copy plan + recon to backend.**

```bash
cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/recon/2026-05-14-step17-memory-loop-recon.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/recon/

cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/plans/2026-05-14-step17-memory-loop-plan.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/plans/

cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add docs/superpowers/
git commit -m "docs: Step 17 memory loop recon + plan"
```

---

## Task B1: Pronunciation → Vocabulary bridge

**Files:**
- Modify: `controllers/tutor.js`

- [ ] **Step 1: Locate `submitPronunciationSummary` (line ~660-700).** Find the existing `for (const word of weakWords) { ... mem.weakAreas.push ... }` loop.

- [ ] **Step 2: Add a parallel Vocabulary upsert** immediately after the TutorMemory.weakAreas upsert loop, before `await mem.save()`. The Vocabulary collection uses unique key `(user, word)` and SM-2 fields default appropriately, so a `$setOnInsert` upsert is idempotent.

```js
// Step 17 — bridge into the SRS queue. Pronunciation weak words are
// the canonical 'I'm bad at this' signal; routing them into Vocabulary
// so they enter the existing spaced-repetition flow. Existing entries
// are not reset ($setOnInsert is a no-op when matched).
const Vocabulary = require('../models/Vocabulary');
const targetLang = req.user?.language_to_learn || 'en';
const nativeLang = mem?.nativeLanguage || 'en';
const now = new Date();

await Promise.all(weakWords.map(word =>
  Vocabulary.findOneAndUpdate(
    { user: req.user._id, word },
    {
      $setOnInsert: {
        user: req.user._id,
        word,
        translation: '', // empty — user can fill during review
        language: targetLang,
        nativeLanguage: nativeLang,
        partOfSpeech: 'other',
        context: { source: 'conversation' }, // Vocabulary.context.source enum
        srsLevel: 0,
        easeFactor: 2.5,
        interval: 0,
        nextReview: now,
        isArchived: false,
        isMastered: false,
      },
    },
    { upsert: true, new: false }
  ).catch(err => {
    console.error(`[pronounce-bridge] vocab upsert failed for ${word}:`, err.message);
    return null;
  })
));
```

Note on `context.source`: the enum at `models/Vocabulary.js:68` lists `['conversation', 'lesson', 'manual', 'quiz', 'import']`. There's no `'pronunciation'` value. Two options:
- (a) use `'conversation'` (treat Pronounce as a conversational signal — closest existing fit)
- (b) extend the enum to add `'pronunciation'`

For this wave: option (a). Avoids schema change. Add an issue to `docs/manual-todos.md` to extend the enum in a future cleanup if filtering by Pronounce-sourced vocab becomes useful.

- [ ] **Step 3: Verify Vocabulary require is at top of file** (Mongoose model loading). If `Vocabulary` isn't already required at top of `controllers/tutor.js`, add it to the require block.

- [ ] **Step 4: Verify syntax.**

```bash
node -c controllers/tutor.js
```

- [ ] **Step 5: Commit.**

```bash
git add controllers/tutor.js
git commit -m "feat(memory-loop): route pronunciation weak words into SRS queue

Bug fix / feature: Pronunciation chip flagged weak words to
TutorMemory.weakAreas (with 'pronunciation:' prefix) but never wrote
them to Vocabulary. The SM-2 spaced repetition queue (the entire
memory loop infrastructure) sat unused for Pronunciation-only users.

Fix: in submitPronunciationSummary, after the weakAreas upsert loop,
upsert each weak word into Vocabulary with srsLevel:0 and
nextReview:now (immediately due). Existing entries are no-op'd via
\$setOnInsert.

Translation is left empty — review screen surfaces this; user fills
in during review if they want. context.source = 'conversation' (the
closest existing enum value; extending the enum to add 'pronunciation'
is queued as a small cleanup).

Loop closes for Pronounce users: after this commit, three botched
words today → three SRS items due tomorrow → Step 17 F1 surfaces
the Review card on the tutor tab."
```

---

## Task F1: Surface SrsDueCard on the tutor tab

**Files:**
- Modify: `lib/pages/learning/main/sections/ai_tools_tab.dart`
- Possibly modify: `lib/widgets/tutor/srs_due_card.dart` (if threshold isn't already parameterized)

Working dir: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

- [ ] **Step 1: Inspect `SrsDueCard` to understand its API.**

```bash
head -60 lib/widgets/tutor/srs_due_card.dart
```

Note the constructor signature. If it already accepts due-count + words as parameters and renders only when non-empty, perfect. If it does its own internal fetch, the call site in the tutor tab needs to handle conditional rendering externally.

- [ ] **Step 2: Identify the insertion point in `ai_tools_tab.dart`.**

Around line 49-53 (between `_AITutorHero` and `_TutorModeChips`). The exact structure depends on whether the build method uses `Column` children or a `SliverList`. Read the file to confirm.

- [ ] **Step 3: Insert a Consumer-wrapped SrsDueCard.**

```dart
Consumer(
  builder: (context, ref, _) {
    final dueAsync = ref.watch(dueReviewsProvider(null));
    return dueAsync.when(
      data: (response) {
        final count = response?.words?.length ?? 0;
        if (count < 3) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SrsDueCard(/* pass the response */),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  },
),
const SizedBox(height: 12),
```

The exact prop shape passed to `SrsDueCard` depends on what its constructor expects. If it expects `dueCount` + `previewWords`, build them from `response`. If it expects the raw `DueWordsResponse`, pass it whole.

If `SrsDueCard` already handles the count threshold internally and is "always-on" when wrapped around the provider read, drop the `if (count < 3)` guard and let the card decide.

Imports to add at top of `ai_tools_tab.dart`:

```dart
import 'package:bananatalk_app/widgets/tutor/srs_due_card.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
```

- [ ] **Step 4: Verify `SrsDueCard`'s tap behavior.** Confirm it navigates to `VocabularyReviewScreen`. If it doesn't (e.g., its existing "Review now" button only triggers a chat message in TutorChatScreen), wire the tap to push `VocabularyReviewScreen` — or parameterize the `onTap` and pass the navigation from the tutor tab call site.

- [ ] **Step 5: Analyze.**

```bash
flutter analyze lib/pages/learning/main/sections/ai_tools_tab.dart lib/widgets/tutor/srs_due_card.dart 2>&1 | tail -3
```

- [ ] **Step 6: Commit.**

```bash
git add lib/pages/learning/main/sections/ai_tools_tab.dart lib/widgets/tutor/srs_due_card.dart
git commit -m "feat(memory-loop): surface SrsDueCard on AI Study tab

The existing SrsDueCard widget was only rendered inside TutorChatScreen.
Users who opened AI Study and looked at the tutor tab got no signal
that they had words due for review unless they happened to open the
Chat chip.

Insert SrsDueCard at the top of ai_tools_tab.dart between the persona
hero and the chip grid. Card is Consumer-wrapped and renders only
when dueCount >= 3 (matches the locked threshold from the recon).
Loading and error states render nothing — no flicker.

Tap deep-links to VocabularyReviewScreen (existing screen at
lib/pages/learning/vocabulary/). The SM-2 review flow + flip
animation are unchanged from the existing surface.

Memory loop closes for Pronounce users: pronunciation weak words
now enter SRS queue (B1) → tutor tab surfaces the review card →
user reviews → SM-2 schedules next review based on quality."
```

---

## Task G1: Smoke + push + merge

- [ ] **Step 1: Backend smoke.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
npm run dev &

TOKEN_USER="<test user token>"

# Submit a pronunciation summary with 2 weak words
curl -s -X POST -H "Authorization: Bearer $TOKEN_USER" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -d '{"weakWords":["park","river"]}' | jq

# Verify in Mongo:
#   db.tutormemories.findOne({ user: ObjectId("<user_id>") })
#   - weakAreas array should now contain { topic: 'pronunciation:park', ... } and { topic: 'pronunciation:river', ... }
#
#   db.vocabularies.find({ user: ObjectId("<user_id>"), word: { $in: ['park', 'river'] }})
#   - Two documents should exist with srsLevel: 0, nextReview: ~now,
#     context.source: 'conversation', translation: ''

# Re-submit same words
curl -s -X POST -H "Authorization: Bearer $TOKEN_USER" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/tutor/pronunciation/summary \
  -d '{"weakWords":["park","river"]}' | jq

# Verify Vocabulary docs unchanged (srsLevel still 0, nextReview unchanged)
# Verify TutorMemory.weakAreas frequency incremented

# Verify the review queue endpoint sees them
curl -s -H "Authorization: Bearer $TOKEN_USER" \
  http://localhost:5000/api/v1/learning/vocabulary/review?limit=5 | jq '.data.words | map(.word)'
# Expected: ["park", "river"] (or whatever order; both should appear)
```

- [ ] **Step 2: Flutter device smoke (physical iOS + Android).**

1. **Pronounce a couple of weak words.** Trigger Pronunciation chip, deliberately mispronounce 2-3 words, complete the session, hit "Save & Close."
2. **Open AI Study tab.** Should see the `SrsDueCard` at the top showing "X words due" (or similar copy from the existing widget).
3. **Tap the card.** Should navigate to `VocabularyReviewScreen`. Flash-card UI works; user marks Knew it / Forgot.
4. **Return to AI Study tab.** Due count should reflect items reviewed (re-fetched via `dueReviewsProvider` invalidation).
5. **Reduce due count below threshold.** Once `dueCount < 3`, the card disappears from the tutor tab.

- [ ] **Step 3: Push branches.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git push -u origin feat/step17-memory-loop

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze 2>&1 | grep -E "error •" && echo "ERRORS — fix before merge" || echo "no errors"
git push -u origin feat/step17-memory-loop
```

- [ ] **Step 4: Merge both to main + push.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull --ff-only
git merge --no-ff feat/step17-memory-loop -m "Merge feat/step17-memory-loop into main"
git push origin main

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull --ff-only
git merge --no-ff feat/step17-memory-loop -m "Merge feat/step17-memory-loop into main"
git push origin main
```

---

## Cadence guidance

- **B1 lands first** — Pronunciation bridge needs to be deployable before F1 has anything to surface.
- **F1 follows** — but doesn't strictly depend on B1 being deployed; users with existing Vocabulary entries already have due items that will surface immediately.
- **G1 = smoke + merge gate.**

## Risk + rollback

- **Mid risk: B1 bridge.** A bug in the Vocabulary upsert could (a) crash `submitPronunciationSummary` and break Pronounce chip end-of-session, or (b) silently fail without writing. Mitigation: each upsert is wrapped in its own `.catch()` so one failed word doesn't break the others; the per-call failure logs to console but doesn't reject the response. Rollback: revert B1; Pronounce still works, SRS queue just doesn't get fed from Pronounce.
- **Low risk: F1 card insertion.** Adds a Consumer-wrapped widget. Worst case: visual misfit. Rollback: revert; card disappears from tutor tab.

**Emergency disable:** No env-flag kill switch. If B1 misbehaves, revert.

**No DB migrations.** Lazy upsert handles all cases.

---

## Appendix A — what's NOT in this wave

- ❌ Chat → Vocabulary auto-extraction (Step 18 candidate)
- ❌ Backfill of existing TutorMemory.weakAreas → Vocabulary
- ❌ Translation backfill for empty-translation Vocabulary records
- ❌ AI Study bottom-nav badge polish (dot indicator on the tab icon)
- ❌ Word lemmatization
- ❌ Adding `'pronunciation'` to Vocabulary.context.source enum (queued)
- ❌ Cleanup of dead `TutorMemory.vocabFocus` field

Anything that wants to expand scope during execution → `docs/manual-todos.md` Queued engineering.
