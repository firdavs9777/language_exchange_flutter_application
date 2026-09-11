# Daily Learning Pack — Design

Status: approved through §5 by the product owner on 2026-09-11. §6 and §7 are new
and await review. Supersedes the two-card shape of
`2026-08-23-study-hub-daily-design.md`; that spec's backend spine is kept, not replaced.

## 1. Why

Study Hub Daily shipped on 2026-08-28 with app 2.2.3 and a push to 1,385 users.
Measured on production 2026-09-11, fourteen days in:

| Measurement | Value |
|---|---|
| Users | 1,668 (758 active in 30d, 142 in 7d) |
| Daily items in the bank | 214 — **all `en`**, all curated, 0 AI |
| Grammar bank by level | A1 60 · A2 90 · B1 62 · C1 2 · **B2 0** |
| Drops generated per day | 50 |
| Completion rows, all time | **35** across 23 distinct users |
| Users who ever finished a full day | **9** |
| Users who returned for a 2nd day | **2**. Day 3: **0** |
| Highest `currentStreak` in the database | **1** |
| Average score | grammar 1.71/3 · vocabulary 2.36/3 |
| Push-reachable | 403 users |

Two conclusions drive this design. First, supply is not the constraint: the job
generates 50 drops a day against roughly two completions. Second, the day is too
thin to come back to — two cards of three multiple-choice questions, rendered as a
`ListView` of `RadioListTile`s, with the reward (streak, XP) shown only as a line of
text after submitting.

Three structural facts also shape it:

- **The bank is English-only.** Every learner of Korean (47 active), Chinese (41) or
  Japanese (35) has only ever seen the `todayEmpty` state.
- **1,505 of 1,668 users have no `languageLevel`** (697 of the 758 active). A
  level-graded feature is currently guessing for ~92% of its audience.
- **273 saved vocabulary words are due for review right now** across 74 users, and
  nothing in the app surfaces them.

## 2. Goals and non-goals

**Goals**

1. A day worth returning to: four short stations under a week-long theme, ~7 minutes.
2. Real content, not filler — sourced from material that already exists on prod.
3. Progress a learner actually wants to open: mastery per skill, from real SRS data.
4. An app surface that looks like a flagship daily habit.
5. Keep every correctness guarantee the 2026-08-23 wave earned.

**Non-goals for this design**

- Non-English languages (English-first was chosen deliberately; §3 explains).
- CEFR certification claims.
- Monetization mechanics. A seam is identified in §6 and left unbuilt.
- Social/competitive features (leaderboards are touched only as an adjacent bug).

**Success criteria.** The measurements above are the baseline. This design succeeds
if, four weeks after launch: ≥25% of users who complete day 1 also complete day 3
(today: 0 of 23), median `currentStreak` among active learners ≥3 (today: 1 is the
maximum in the database), and ≥40% of the 273 stranded due words have been reviewed
at least once.

## 3. Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | English-first, go deep | ~322 of 758 active users (42%) learn an English variant; 1,000 curated English words and 214 items already exist. Next-largest is Korean at 47. |
| D2 | Four stations + weekly arc | The measured cliff is day 1→2. A theme that spans a week is the return reason; four stations make the day substantial without making it long. |
| D3 | Extend the existing daily-drop spine | Per-UTC-day idempotency, `resolveLevelWithFallback`, `nudgeLevel`, the `(user, dateKey, kind)` unique index and `DAILY_DROP_DELIVERY_ENABLED` all keep working. Rebuilding them is the largest avoidable risk. |
| D4 | 60-second placement on first open | Fixes the 92% unlabeled problem at the source; feeds the `nudgeLevel` loop that already exists. |
| D5 | Mastery per skill as the progress model | Derivable from real SRS data; avoids claiming CEFR proficiency from 8 questions. |
| D6 | Hero card → full-screen guided flow | Focus beats a scrolling list for completion; reuses the existing tab structure. |
| D7 | **Per-learner grammar cursor** | Everyone starts at unit 1 of a sequential syllabus. Pedagogically correct; costs grammar its place in the shared drop (see §5.2). |
| D8 | Daily Practice folded in as a weekend `translate` station | One daily ritual instead of two competing cards; the AI grading path already built keeps earning. |

## 4. Content foundation

### 4.1 Sources

| Station | Source | Status |
|---|---|---|
| Vocabulary | `vocabpacks` — 50 packs × 20 words + 8 exercises | **Live on prod** |
| Grammar | 260-unit syllabus derived from two reference grammars | Needs authoring |
| Listening | `speechService.generateTTS()` over sentences the pack already contains, cached in `audiocaches` | **No new content** |
| Review | `vocabularies` SRS fields via `lib/srsEngine.js` | **273 words already due** |
| Translate | existing AI-graded daily-practice path | Exists, moves behind a station |

### 4.2 The packs are already weekly themes

Each `VocabPack` carries a `topic` ("Work & careers", "Health & the body") and
exactly **20 words** — which is 5 words × 4 days. 25 intermediate + 25 advanced packs
is roughly a year of themed weeks per level, already written and already on prod.
Theme selection is deterministic: `weeksSinceEpoch % packCount` for the level. No
scheduling state, and the nightly job stays idempotent.

### 4.3 Level mapping

| Source grading | CEFR | Notes |
|---|---|---|
| `vocabpacks.level = intermediate` | A2, B1 | 25 packs |
| `vocabpacks.level = advanced` | B2, C1 | 25 packs |
| elementary grammar syllabus (115 units) | A1, A2 | |
| intermediate grammar syllabus (145 units) | B1, B2 | fills the current B2 hole (0 items) |

### 4.4 The A1 gap

A1 is the largest labeled group (31 of 61 labeled active users) and **no beginner
vocab pack exists**. This design authors **12 beginner packs (240 words, 96
exercises)** on the same blueprint as the 50 that exist — one quarter of themed weeks
for A1. Without them the pack does not work for beginners, so this is wave-1 content,
not a follow-up.

### 4.5 Grammar authoring, and how the reference books are used

The two PDFs supply a **syllabus**: which grammar points to teach, in what order, at
what level, grouped into 37 sections (Present, Past, Present perfect, Passive, Future,
Modals, *if* and *wish*, Reported speech, Questions, `-ing`/`to`, Articles and nouns,
Pronouns and determiners, Relative clauses, Adjectives and adverbs, Conjunctions and
prepositions, Prepositions, Phrasal verbs).

All explanations, example sentences and exercises are **authored fresh**. No prose or
exercise sentence from the books enters the database. This is the same pattern
`seeds/vocabPacks.js` already documents for the vocabulary ("headword coverage derived
from reference books, all definitions/examples/exercises generated originally"), so
the repo stays consistent and a third-party textbook stays out of the app's content.

The extraction script that derives the unit list lives with the implementation; the
derived list is an authoring input and the **authored items** are what get committed
and seeded.

**Launch volume is not the whole syllabus.** Twelve weeks of runway is 60 grammar
units per book: 60 elementary (A1/A2) + 60 intermediate (B1/B2) = **120 units** for
wave 1, continuing in the background afterwards.

### 4.6 Authoring quality gates

- Existing `validateDailyItem()` shape gate, plus `approved` / `needsReview` flags.
- **Answer-position balance.** The current bank's `answerIndex` distribution is
  34.4% / 58.7% / 6.9% across three positions — a learner can partly game it by always
  choosing the middle option. The seeder computes the distribution per option-count
  group across each batch and **refuses to write** when any position deviates from
  uniform by more than ±25% relative (for 3 options: uniform 33.3%, so the accepted
  band is 25–42%; for 4 options: 18.75–31.25%). Grouping by option count matters
  because `quickCheck.options` is not fixed at three.
- Human spot-check of N items per batch before `approved: true`.

## 5. Data model and backend

### 5.1 What changes

```
DailyItem            + syllabus: { book: 'elementary'|'intermediate',
                                   unit: Number, section: String }

DailyDrop            + weekKey: 'YYYY-Www'
                     + themePack: ref VocabPack
                     + dayInWeek: 1-7
                     + listeningItem: ref DailyItem
                     - grammarItem  (grammar is per-learner now — D7)
                       vocabItem stays

DailyDropCompletion  + item: ref DailyItem  (nullable)
                     + kind enum widens to STATION_KINDS

GrammarMastery       NEW { user, language, book, unit, section,
                           attempts, bestScore, mastered, lastSeenDateKey }
                     unique (user, language, book, unit)

LevelPlacement       NEW { user, language, answers[], score, level, takenAt }
```

`DailyDrop` stays **shared**, keyed `(dateKey, language, level)` — one document per
audience. Vocabulary and listening fit that. Grammar (D7) and review are resolved
per-user at read time and never live in it.

### 5.2 Consequences of the per-learner grammar cursor (D7)

- The nightly job stops pre-generating grammar; it still generates vocabulary and
  listening per (language, level).
- A unit is mastered at 3/3 once, or ≥2/3 on two separate days.
- The cursor is derived, not stored, so nothing can drift out of repair: it is the
  lowest unit that is **not mastered and not in cooldown**, where cooldown means
  `lastSeenDateKey` is within the last two days. A failed unit therefore returns after
  two days instead of blocking the day, and the learner meets the next unit meanwhile.
  If every unmastered unit is in cooldown, the station serves the oldest-seen
  unmastered unit rather than reporting nothing to study.
- Push copy stays personalized because `runDailyDropDelivery()` already iterates
  per user. It adds one indexed lookup per user to a loop the 2026-08-23 known-issues
  doc already flags as N+1 at 10× scale; at 758 active users this is acceptable and is
  re-examined at 5,000.

### 5.3 Two kinds lists, not one

`lib/dailyItemShape.KINDS` currently means both "what a DailyItem can be" and "what a
user can complete". Those now diverge and get split:

- `ITEM_KINDS = ['grammar', 'vocabulary']` — the `DailyItem.kind` enum, unchanged.
- `STATION_KINDS = ['grammar', 'vocabulary', 'listening', 'review', 'wrap', 'translate']`
  — the `DailyDropCompletion.kind` enum.

The station kind stays spelled **`vocabulary`**, not `vocab`: 35 completion rows
already exist on prod (14 of them `vocabulary`), and a renamed enum value would
invalidate them. `STATION_KINDS` is therefore a strict superset of `ITEM_KINDS` and
needs no data migration.

### 5.4 Per-unit progress requires the new `item` reference

`DailyDropCompletion` records `(user, dateKey, kind, score)` and **not which item was
completed**. "9 of 30 grammar points passed" is therefore not derivable from current
data; the mastery view in §7 is impossible without `item`. It is nullable, so the 35
existing rows stay valid and simply contribute no per-unit history.

### 5.5 Day completion

Applicability varies by weekday and by learner, so completion is computed
**server-side** and returned to the client, which renders the server's count and never
its own:

| Day | Stations |
|---|---|
| Mon–Thu | vocab (5 new words) · grammar · listening · review |
| Fri | **wrap quiz** · grammar · listening · review |
| Sat–Sun | **translate** · grammar · listening · review |

Always four. **An empty station auto-satisfies.** A new learner has no due words, so
review is empty; if `isDayComplete()` demanded it, *no new user could ever complete a
day* and the streak would be unreachable for exactly the people this design is trying
to retain. Empty renders as "nothing due — you're clear", never as a locked step.

### 5.6 XP and streak

+10 vocab, +10 grammar, +10 listening, +5 review, plus a day-complete bonus, all
through `learningTrackingService.awardXPWithStreak()` (merged 2026-09-11, backend
`4502ce0`), so every station ticks the streak exactly once per UTC day via
`lastStreakDateKey`.

## 6. Delivery and the monetization seam — **NEW, not yet reviewed**

**Delivery.** `runDailyDropDelivery()` and `DAILY_DROP_DELIVERY_ENABLED` are unchanged;
the kill switch remains a kill switch. Copy becomes specific rather than generic —
naming the theme and the learner's next grammar unit ("Work & careers, day 2 ·
*present perfect* next") — because the personalization is already available in a
per-user loop. Only 403 of 1,668 users are push-reachable, so the hero card carries
the same information for everyone else, and no design decision here depends on push.

The existing due-words notification in `jobs/learningJobs.js` is **deduplicated against
the daily nudge** so a learner with due words does not receive two notifications about
the same pack on the same day.

**Monetization seam, identified and left unbuilt.**
`LearningProgress.streakFreezes` already exists as a field and is unused. It is the
natural coin sink: buy a freeze, protect a streak. Coins v1 is already merged. This
design does not build it, does not gate any station behind VIP, and does not put a
paywall in the flow — a habit with 2 returning users has no retention to sell yet.
Revisit once the day-3 completion rate is non-zero.

## 7. App side — **§7.4 NEW, not yet reviewed**

### 7.1 Structure

```
lib/pages/learning/daily/
  daily_pack_hero_card.dart      ← replaces today_section.dart
  daily_pack_flow.dart           ← rail + PageView + exit guard
  stations/  vocab_station.dart  grammar_station.dart  listening_station.dart
             review_station.dart wrap_quiz_station.dart  translate_station.dart
  widgets/   station_rail.dart   word_card.dart  check_question.dart
             day_complete_sheet.dart
  placement/placement_screen.dart
lib/pages/learning/progress/
  mastery_screen.dart            widgets/mastery_bar.dart  streak_calendar.dart
lib/models/learning/daily_pack_model.dart
lib/providers/provider_root/learning/daily_pack_providers.dart
```

`today_section.dart` and `daily_drop_screen.dart` are **replaced**, not extended — one
station at a time with a progress rail is a different shell than a scrolling list.
All imports use `package:` form per the repo linter.

### 7.2 Behaviour

- **Hero card**: theme name, week dots, progress ring (server's count), streak flame,
  and a CTA naming the *next* station ("Continue · Review, 3 left") — never a generic
  "Open". Done-for-today is a satisfied state with tomorrow's teaser. Theme gradients
  come from existing `AppColors` (teal / banana / purple); no second palette.
- **Flow**: full-screen, rail on top, close button, no bottom nav. Each station commits
  independently through the existing per-kind idempotent endpoint, so **exiting
  mid-session never loses completed work**.
- **`check_question.dart`** replaces every `RadioListTile`: option chips, immediate
  correct/incorrect with **icon and text, never colour alone**, the item's
  `explanation` revealed after answering, subtle shake on wrong. Every station reuses
  it so a check feels identical regardless of source.
- **Motion**: ring fill, a `+10 XP` chip rising off the finished station, streak
  count-up in the completion sheet. Implicit animations only, no new packages.
- **Edge states**: `needsLanguage`, empty bank (existing `todayEmpty` copy), level
  fallback banner, review-empty, offline (cached pack rendered read-only; submit shows
  an explicit retry rather than queueing silently).
- **Accessibility**: ≥44pt targets, semantics labels on audio buttons, legible to
  text-scale 1.3, correctness never signalled by colour alone.

### 7.3 Progress surfaces

A two-line strip under the hero card ("84 mastered · 12 due" / "Grammar · unit 23 of
115"), and `mastery_screen.dart` behind one tap:

| Skill | Definition | Source |
|---|---|---|
| Vocabulary | mastered = `isMastered` (`srsLevel ≥ 9`); learning 1–8; new 0; due `nextReview ≤ now` | `vocabularies`, `lib/srsEngine.js` |
| Grammar | units mastered of 115/145 + per-section rings over 37 sections | `GrammarMastery` |
| Listening | rolling accuracy, last 20 stations | `DailyDropCompletion` |
| Translate | correctness rate | `DailyDropCompletion` |
| Consistency | 30-day dot calendar | `DailyDropCompletion.dateKey` (derivable today) |

One endpoint, `GET /api/v1/learning/mastery`, in at most four aggregates — not one
query per skill and not an N+1 over units.

**The stranded-words hook**: the strip states the due count and taps straight into the
review station. 273 words are already waiting, already chosen by those learners.

**Honesty guard**: the level badge reads "your level · retake", not a CEFR
certification.

### 7.4 Localization cost

19 ARB locales and a 4,738-line `app_en.arb`. The pack adds ~40–60 strings, each
needing 18 translations. This is real work and belongs in the plan as its own task,
not as an afterthought at the end.

## 8. Testing

- **Backend, pure units** (no DB): station applicability by weekday, empty-station
  auto-satisfy, cursor derivation, mastery thresholds (3/3 once vs ≥2/3 twice), theme
  rotation determinism, answer-position balance gate.
- **Backend, in-memory Mongo** (`mongodb-memory-server`, the pattern in
  `test/xpStreakTick.test.js`): day completion across a full week, new words enrolling
  into SRS at `srsLevel: 0`, review advancing through `applyReview`, re-submission
  idempotency on the widened `kind` enum, mastery endpoint aggregate shapes.
- **Flutter widget tests**: one per station using the existing injectable-callback
  pattern (`SubmitAnswers`/`SubmitFeedback`) so nothing hits the network; plus hero
  card states (fresh / partial / done / empty / needs-language), rail progress,
  completion sheet, mastery screen with empty and populated data.
  `today_section_test.dart` and `daily_drop_screen_test.dart` are rewritten;
  `daily_drop_model_test`, `daily_drop_locale_test` and `daily_drop_router_test` are
  extended.
- **Seeder dry-run** over the authored batch, asserting shape and answer balance
  before any write.

## 9. Staging

**Wave 1 — the pack (ship-able on its own)**
Placement · four stations incl. weekend translate · weekly theme from packs ·
per-learner grammar cursor · hero card and flow · mastery strip and screen ·
120 grammar units · 12 beginner vocab packs · l10n · tests.

**Wave 2 — after wave 1's data**
Weekly report card (in-app + the existing push/email paths) · remaining syllabus to
260 units · B2/C1 vocabulary depth · streak-freeze coin sink · per-section deep dives.

Content authoring is the **critical path**, not the code. It runs in parallel from day
one and gates launch.

## 10. Risks and open questions

| Risk | Mitigation |
|---|---|
| Content authoring slips and gates the whole wave | Launch volume is 120 units, not 260; authoring starts in parallel on day one; `approved` flag lets content land progressively behind a gate. |
| Seven stations' worth of new UI destabilises a working feature | Stations commit independently; the old endpoints stay; `DAILY_DROP_DELIVERY_ENABLED` still kills delivery without a deploy. |
| A learner entering at unit 1 of 145 finds it too easy | Placement sets the *book and level*; `nudgeLevel` plus "too easy" feedback skips ahead; mastery at 3/3 first try advances immediately. |
| ~7 minutes is too long for the audience that wouldn't finish 4 | Stations are independently completable and the ring shows partial credit; a 2-minute day (grammar + review) still counts for the streak. |
| Non-English learners still see nothing | Explicit non-goal (D1). The empty state remains honest. Revisit as its own wave. |

**Open questions**

1. Should the weekend `translate` station accept audio (speaking) as well as typed
   input? `speechService` supports STT and pronunciation scoring already.
2. Should the wrap quiz be a gate (must pass to advance the theme) or purely
   formative? Design currently assumes formative.
3. Do beginner packs get authored in-house or from the same reference workflow as the
   50 existing packs?

## 11. Adjacent findings (not this design's work)

- **1,318 of 2,542 `LearningProgress` rows (52%) belong to users that no longer
  exist**, 250 of them carrying XP. These rows sit on the
  `targetLanguage + weeklyXP` / `+ totalXP` leaderboard indexes, so leaderboards are
  very likely rendering ghost entries with a null populated user. `user_1` is unique
  and there are no duplicates, so this is orphan cleanup plus a check on every account
  deletion path — the same class as the ProfileVisit orphan fixed in backend `d8372f0`.
- `config/config.env` carries a **12-character `JWT_SECRET`**; the auth-hardening test
  enforces 32. Rotating invalidates all sessions, so it needs a deliberate call.
- Eight AI feature keys still fall through to `chatCompletion`'s hardcoded 1024/0.7
  defaults, pinned as `KNOWN_UNREGISTERED` in `test/aiConfigDailyDrop.test.js`.
