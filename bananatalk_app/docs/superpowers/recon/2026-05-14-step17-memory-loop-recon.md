# Step 17 — Memory Loop — Recon

Read-only reconnaissance for the planned Memory Loop wave. Originally scoped as a sub-wave split (17A backend foundation + 17B Flutter surface). The recon found that **most of the spaced repetition system is already built** — only narrow gaps remain. The 17A / 17B split is no longer warranted; everything collapses into a single, smaller Step 17 wave.

The headline: the `Vocabulary` Mongoose model already implements the full SM-2 spaced repetition algorithm (srsLevel, easeFactor, interval, nextReview, processReview, getDueForReview), the `GET /api/v1/learning/vocabulary/review` endpoint already returns words due for review, and Flutter already has a `VocabularyReviewScreen` with `dueReviewsProvider` plus an `SrsDueCard` widget. What's missing is the **entry points** (Pronunciation weak words don't enter the SRS queue) and the **tutor tab surface** (the review screen lives in `/learning/vocabulary/` and isn't reachable from the AI Study tab).

---

## Cross-cutting findings

### CC-1. `Vocabulary` IS the mastery model.

`models/Vocabulary.js` has a complete per-user-per-word spaced repetition implementation:

- **SRS fields** (lines 116-201):
  - `srsLevel` 0-9 (indexed)
  - `easeFactor` (2.5 default, SM-2 ease)
  - `interval` (days until next review)
  - `nextReview` (Date, indexed — the "due" timestamp)
  - `isMastered` (flag at level 9)
  - `masteredAt` (timestamp)
- **Review history** (last 10, each with quality 0-5 + responseTime + correctness)
- **Instance method `processReview(quality, responseTime)`** (line 240) — implements the SM-2 algorithm: updates srsLevel + interval + nextReview + ease based on user's recall quality
- **Static method `getDueForReview(userId, limit)`** (line 328) — the review queue query, `nextReview <= now AND !isArchived`, sorted by dueDate + srsLevel
- **Indexes for the queue lookup**: `{ user: 1, nextReview: 1, isArchived: 1 }` (line 222)
- **Uniqueness**: `{ user: 1, word: 1 }` (line 227) — same user can't save the same word twice

Implication: the plan does NOT need a new `Mastery` model. `Vocabulary` IS the model.

### CC-2. Decay job is not needed.

SM-2 doesn't require an active decay job. `nextReview` is set at `processReview` time based on the user's quality rating. Items become "due" naturally when `nextReview <= now`. No cron-based decay function is required.

Implication: the originally-planned "daily decay job" is removed from scope. The existing index + `getDueForReview` query are sufficient.

### CC-3. Two entry points exist for Vocabulary creation; both are user-action-gated, not automatic.

- **`POST /api/v1/messages/:id/vocabulary`** (`controllers/advancedMessages.js:289` → `saveToVocabulary`) — user manually taps "save to vocab" on a message. Lowercases + trims (line 308). Idempotent via uniqueness on `(user, word)`.
- **`POST /api/v1/learning/vocabulary`** (`controllers/learning.js:205` → `addVocabulary`) — direct add, used by the learning dashboard.

No automatic extraction from chat sessions. Words only enter the SRS queue when the user explicitly taps to save them.

### CC-4. Pronunciation weak words do NOT enter the SRS queue.

`controllers/tutor.js:666` (`submitPronunciationSummary`) upserts weak words into `TutorMemory.weakAreas` with the `pronunciation:` prefix. They never reach the `Vocabulary` collection. So a user who botches "park" five times gets `pronunciation:park` recorded on TutorMemory, but no entry in the SRS queue and no review surface.

**This is the single highest-leverage gap.** Pronunciation chip is the canonical "I'm bad at this" signal; routing it into the SRS queue is the entire memory-loop story for users who use Pronounce. The change is ~15 lines: in `submitPronunciationSummary`, after the `weakAreas` upsert, also upsert each weak word into `Vocabulary` with `context.source: 'pronunciation'`, `srsLevel: 0`, `nextReview: now` (immediately due).

### CC-5. Flutter has a complete review screen — but in the wrong place for AI Study.

- **`lib/pages/learning/vocabulary/vocabulary_review_screen.dart`** — full flash-card review UI, reads from `dueReviewsProvider`, calls `processReview` on user response. Flip animation already wired (via `vocabularyReviewProvider.notifier.flipCard()`).
- **`lib/pages/learning/vocabulary/srs_dashboard_screen.dart`** — stats dashboard listing due / new / mastered counts.
- **`lib/widgets/tutor/srs_due_card.dart`** — embedded card surfaced inside `TutorChatScreen` (line 17+), shows "X due reviews" + preview of 3 words + "Review now" button (line 108). Already wired into the tutor chat flow.

But the AI Study tutor tab (`lib/pages/learning/main/sections/ai_tools_tab.dart`) does not surface anything review-related. Users land on the tab, see the 5 chips (Chat / Roleplay / Story / Photo / Pronounce), and have no signal that they have words due for review unless they happen to open the Chat chip and trigger the `SrsDueCard` inside.

Implication: the Flutter side is one card widget + one slot insertion. The provider (`dueReviewsProvider`) and target screen (`VocabularyReviewScreen`) already exist.

### CC-6. `dueReviewsProvider` is a `FutureProvider.family<DueWordsResponse?, String?>` keyed on language.

`lib/providers/provider_root/learning/vocabulary_providers.dart:98`. Watches `LearningService.getDueReviews(language: ...)`. Returns null on error, `DueWordsResponse` on success — schema available in `models/learning/vocabulary_model.dart`.

For the tutor tab card: `ref.watch(dueReviewsProvider(null))` (null = all languages or default-language behavior — verify in `getDueReviews` implementation). Read `.length` on the response's word list, gate the card on `count >= 3`.

### CC-7. Chat tutor sessions do NOT extract new vocab into `Vocabulary` today.

`services/tutorMemoryService.js` and `controllers/tutor.js` were both inspected. No automatic extraction pipeline from a chat session into `Vocabulary`. The `TutorMemory.vocabFocus` array is declared but never populated.

This is the **second possible gap** but bigger scope:
- Backend: after a chat session ends (or every N messages), pass the user's recent messages to an LLM with "extract any words above the user's CEFR level that they used or were shown" → upsert into `Vocabulary`.
- Risk: noisy. The LLM might suggest words the user already knows, or proper nouns, or off-topic vocabulary. Needs tuning.
- Cost: one extra LLM call per session-end.

**Recommendation: punt to a separate wave** (Step 18 candidate). Make Step 17 about Pronunciation → SRS + tutor tab surface; chat extraction is its own product call (does the user opt in? do they review suggestions? do we surface a "save these 5 words?" prompt at session end?).

### CC-8. `SrsDueCard` already exists and is suitable for the tutor tab.

`lib/widgets/tutor/srs_due_card.dart` (lines 17-121). Renders due count + preview list + "Review now" button. Currently embedded inside `TutorChatScreen`. Can be lifted out to render at the top of `ai_tools_tab.dart` with no widget changes.

Implication: F1 reduces to "insert SrsDueCard into ai_tools_tab.dart layout at line ~53 (above `_TutorModeChips`)" — call site change, not a new widget.

### CC-9. Word normalization is inconsistent.

- `submitPronunciationSummary` lowercases + trims (line 671).
- `saveToVocabulary` (chat-tap) lowercases + trims (line 308).
- `addVocabulary` (learning dashboard) does NOT normalize.

For the Pronunciation → Vocabulary bridge, lowercase + trim before the Vocabulary lookup. Matches the chat path. The Pronunciation chip already normalizes, so the bridge gets clean input.

No lemmatization anywhere ("running" and "ran" are separate items). Acceptable for v1 — proper lemmatization needs an NLP library.

---

## Per-gap analysis

### Gap A — Pronunciation weak words don't enter SRS queue (HIGH leverage)

- **Today:** `submitPronunciationSummary` writes to `TutorMemory.weakAreas` with `pronunciation:word` prefix. No `Vocabulary` write.
- **Fix:** In the same controller, after the `weakAreas` upsert loop, run a parallel loop that upserts each weak word into `Vocabulary`. Schema:
  ```js
  await Vocabulary.findOneAndUpdate(
    { user: req.user._id, word: normalized, language: targetLang },
    {
      $setOnInsert: {
        user: req.user._id,
        word: normalized,
        language: targetLang,
        nativeLanguage: nativeLang,
        translation: '',  // empty — user can fill later
        context: { source: 'pronunciation' },
        srsLevel: 0,
        nextReview: new Date(),  // due immediately
        easeFactor: 2.5,
        interval: 0
      }
    },
    { upsert: true, new: true }
  );
  ```
- **Open question:** translation. The pronunciation flow doesn't have the translation handy. Options: (a) leave blank, user fills in during review; (b) call a translation API in the bridge; (c) skip vocab insert if user has no translation source. Lean (a) — review screen can show "(no translation yet)" and let user add inline.

### Gap B — Tutor tab doesn't surface review queue (HIGH leverage)

- **Today:** `ai_tools_tab.dart` shows 5 chips. Review entry point only exists inside `TutorChatScreen` via `SrsDueCard`.
- **Fix:** insert `SrsDueCard` at the top of `ai_tools_tab.dart` between `_AITutorHero` (line ~49) and `_TutorModeChips` (line ~53). Wrap in a `Consumer` reading `dueReviewsProvider(null)` and conditionally render when `dueCount >= 3`.
- **Open question:** does the existing `SrsDueCard` need the `>= 3` threshold built in, or does it already handle empty / low states? Verify when implementing.

### Gap C — Chat tutor sessions don't extract vocab (MEDIUM leverage, OUT OF SCOPE)

- **Today:** vocab only enters via manual "save to vocab" tap on a chat message.
- **Future fix:** auto-extraction at session-end with LLM call.
- **Why out of scope:** noisy without product tuning; needs UX decisions (auto-add silently? surface a "save these N words?" prompt? user opt-in?).
- **Queue:** add to `docs/manual-todos.md` as a Step 18 candidate.

### Gap D — Tutor tab badge / counter (LOW leverage, OPTIONAL)

- **Today:** no review-due badge on the AI Study bottom-nav tab.
- **Possible fix:** subtle dot indicator on the AI Study tab icon when due count > 0, similar to the existing unread-message badge pattern (`badgeCountProvider`).
- **Why optional:** the top-of-tab card is enough surfacing for v1. Tab badge is polish.

---

## Edge cases the plan must address

- **First-time Pronunciation use.** User does Pronounce for the first time, ends with 3 weak words. After this wave, those 3 words land in Vocabulary with `nextReview: now`. The next time the user opens the tutor tab, the Review card surfaces. Loop closes.
- **Re-submission of same weak word.** User struggles with "park" twice across two sessions. The first session creates the Vocabulary entry; the second session's `findOneAndUpdate` upsert finds the existing entry and does nothing (because `$setOnInsert` only applies on insert). The TutorMemory.weakAreas frequency still increments — that's the user-visible signal of repeated failure. Vocabulary's review queue handles the recall side.
- **Translation missing.** Vocabulary record has `translation: ''`. The review screen renders something reasonable. Verify `VocabularyReviewScreen` behavior with empty translation; if it crashes, add a "(no translation — add one?)" inline state. Possibly out of scope; surface during smoke.
- **Existing user with TutorMemory.weakAreas full of `pronunciation:*` items.** The bridge runs on NEW pronunciation submissions only. Existing weak areas stay in TutorMemory and don't backfill to Vocabulary. Acceptable for v1. A separate one-time migration script could backfill if desired.
- **User has no language_to_learn.** Edge — what language do we tag the Vocabulary entry with? Read from `req.user.language_to_learn` (User model line 568); fall back to `'en'` if missing. Should never happen on a real user but guard anyway.
- **Mastered words.** Vocabulary already flips `isMastered: true` at srsLevel 9. The due-review query excludes them automatically. No action needed.
- **Card surfacing flicker.** `dueReviewsProvider` is a FutureProvider — first read is async. The tutor tab needs to handle `loading` (don't show card), `error` (don't show card), `data with count < 3` (don't show card), `data with count >= 3` (show card). Single `when` block.
- **VIP gating.** Review queue is free for all users — not gated by quota. Confirmed by recon (no quota middleware on `/learning/vocabulary/review`).

---

## Three-option design choices

### D-1. Pronunciation → Vocabulary bridge translation handling

| Option | Pros | Cons |
|---|---|---|
| **A. Leave translation empty; review screen handles `(no translation)` inline** | Cleanest. Matches the "data flows from action, not from inference" rule. User can fill in during review or not. | Review UX has empty-state copy to add. |
| **B. Call OpenAI translation API inline** | Translation is always present at review time. | Extra latency on Pronunciation submission. Extra cost. Translation quality concerns. |
| **C. Skip Vocabulary insert when translation unknown** | No empty-state UX needed. | Defeats the purpose of the bridge — pronunciation chip users are exactly the people who'd benefit. |

**Recommendation tilt: A.** Surface empty-translation state during smoke; if review screen crashes, add a one-line fallback.

### D-2. Tutor tab Review card threshold

| Option | Pros | Cons |
|---|---|---|
| **A. Show card when `dueCount >= 3`** | Matches your earlier "≥3" pick. Avoids surface bloat when only 1-2 items are due. | A user with 2 due items doesn't see the card — needs a "where's my review queue?" answer (the SRS dashboard at `/learning/vocabulary/`). |
| **B. Show card when `dueCount >= 1`** | Always-visible surface; never hidden if anything is due. | Card always rendered when ANY item is due; possibly more noisy than needed. |
| **C. Show card always; render `0 due` state with empty message** | Persistent affordance. | Wastes vertical space when nothing's due. |

**Recommendation tilt: A (threshold 3).** Matches your earlier scope decision; preserves visual hierarchy when nothing is due.

### D-3. Card variant — reuse `SrsDueCard` or new widget?

| Option | Pros | Cons |
|---|---|---|
| **A. Reuse existing `SrsDueCard` from `lib/widgets/tutor/`** | Zero new widget code. Visual consistency with the tutor chat surface. | The card's existing styling may not fit the tutor tab visual context — verify during smoke. |
| **B. New `TutorTabReviewCard` styled to match the tab** | Pixel-perfect fit. | Duplication of logic (count read, preview list, button). |

**Recommendation tilt: A.** Reuse first; refactor later if visual review says it looks wrong.

### D-4. Should chat tutor auto-extraction be part of Step 17?

| Option | Pros | Cons |
|---|---|---|
| **A. Punt to Step 18** | Tight wave. Memory loop closes for Pronunciation users immediately. | Chat-only users still get no auto-vocab. |
| **B. Include lightweight auto-extraction (LLM at session-end)** | Memory loop closes for both surfaces. | Bigger wave. Noisy without tuning. Needs UX (silent? prompt?). |

**Recommendation tilt: A.** Punt. Step 17 ships in days; chat extraction needs product thought.

---

## Punted findings (queued for future)

- **Chat → Vocabulary auto-extraction.** Add as Step 18 candidate in `docs/manual-todos.md`.
- **Tutor tab AI Study bottom-nav badge** when items are due. Polish, separate wave.
- **Backfill script** for existing users' `TutorMemory.weakAreas pronunciation:*` items into Vocabulary. Useful but not blocking.
- **Translation backfill** for empty-translation Vocabulary records.
- **`vocabFocus` array on TutorMemory removal.** Declared, never populated, never read. Dead schema field. Could be cleaned up in a separate housekeeping commit.
- **Word lemmatization** ("running" ↔ "ran" deduplication). Needs an NLP library.

---

## What this recon does NOT cover

- Exact wording on the Review card copy ("X words to review" vs "Time to review your weak words" etc) — plan territory.
- Final visual polish of the card position in tab layout — smoke territory.
- Specific LLM extraction strategy for chat auto-extraction — out of scope.

The plan will turn the recommendations above (D-1 through D-4) into locked decisions and re-collapse Step 17 into a single small wave (no 17A / 17B split needed).
