# Study Hub Daily — Design

**Date:** 2026-08-23
**Status:** Approved for planning
**Repos:** `language_exchange_flutter_application` (app), `language_exchange_backend_application` (backend)

---

## 1. Problem

Study Hub holds a large content library that almost nobody consumes, and no
mechanism brings a user back tomorrow.

### 1.1 Measured state (prod, 2026-08-23)

Population:

| Metric | Value |
|---|---|
| Total users | 1,263 |
| Active in 30 days | 875 |
| Active in 7 days | 251 |

Study Hub reach:

| Metric | Value |
|---|---|
| `LearningProgress` docs | 2,232 |
| Touched Study Hub in 30 days | 221 |
| Touched Study Hub in 7 days | 69 |
| Users with `currentStreak > 0` | 11 |
| Users with `currentStreak >= 7` | **0** |

Content inventory versus consumption:

| Content in DB | Count | Consumption |
|---|---|---|
| Exam questions | 19,365 | 74 `UserExamProgress` docs |
| Exam vocabulary words | 12,600 | — |
| Lessons | 84 | 28 starts, **0 completions** |
| Vocab packs | 50 (all English) | — |
| Prompts | 100 | — |
| Exam study tips | 59 | 3 `UserStudyPlan` docs |
| Achievements defined | 42 | **0 `UserAchievement` rows** |
| Challenges defined | 24 | **0 `ChallengeProgress` rows** |
| Quizzes | 0 | **0 `QuizAttempt` rows** |
| User vocabulary words | 292 (74 users) | **0 with `reviewCount > 0`** |

The single live surface is the AI tutor: 309 `AITutorSession` docs, 56 in the
last 30 days.

Lesson category breakdown (84 total): vocabulary 60, conversation 8,
**grammar 6**, listening 6, reading 3, writing 1.

### 1.2 Conclusion drawn from the data

"Add more materials" is not the primary bottleneck. A ~32,000-item library with
zero lesson completions, zero vocabulary reviews, zero quiz attempts and zero
achievements awarded indicates that (a) nothing pulls a user in on a given day,
and (b) the machinery that records progress does not work.

Grammar is the one genuine content gap: 6 grammar lessons total.

---

## 2. Audience

### 2.1 Target languages (users active in last 30 days)

| Language being learned | Count |
|---|---|
| English (`"English"` 177 + `"English (US)"` 135 + `"English (UK)"` 42 + `"en"` 41) | **395** |
| Korean | 50 |
| Japanese | 43 |
| Chinese (Simplified) | 35 |
| French | 21 |
| Russian | 20 |
| German | 16 |
| Chinese (Traditional) | 16 |
| Spanish | 13 |
| Arabic | 12 |
| *(blank string)* | 134 |

Counts are of language *selections* — `language_to_learn` is an array, so a
user learning two languages appears twice. English is the largest target by
roughly 8× the next language (395 vs. Korean's 50) and outweighs all other
targets combined.

### 2.2 Native languages (users active in last 30 days)

| Native language | Count |
|---|---|
| Chinese (Simplified) | 300 |
| Arabic | 79 |
| English (all variants) | ~140 |
| Russian | 29 |
| Spanish | 18 |
| Korean | 16 |
| Hindi | 14 |

Explanations should be localized to `zh-Hans` and `ar` before any other locale.

### 2.3 CEFR level coverage (users active in last 30 days)

| `languageLevel` | Count |
|---|---|
| `null` | **809** |
| A1 | 32 |
| A2 | 13 |
| B1 | 12 |
| B2 | 7 |
| C1 | 1 |
| C2 | 1 |

Per-level targeting cannot rely on a stored level. It needs a default plus an
in-flow calibration path.

### 2.4 Notification reach and performance

| Metric | Value |
|---|---|
| Users with an FCM token | 334 |
| Active-30 users with an FCM token | **305 of 875 (35%)** |
| `srs_review` sent / read | 186 / 23 (12%) |
| `streak_reminder` sent / read | 132 / 21 (16%) |
| `profile_visit` sent / read | 3,271 / 496 (15%) |
| `clicked = true` on any notification, any type | **0 of 4,564** |

Both learning reminder jobs are live and firing — wired at `jobs/scheduler.js`
lines 506–507, most recent `sentAt` 2026-08-23.

`clicked` being false on every row including types that are obviously tapped
means client-side click reporting was never wired. This is missing
instrumentation, **not** evidence of a zero click-through rate. No conclusion
about CTR can be drawn until it is fixed.

### 2.5 Data hazards

**Language variants are unnormalized.** `"English"`, `"English (US)"`,
`"English (UK)"` and `"en"` all exist as distinct stored values. No
normalization helper exists in either repo — confirmed by grep for
`baseLanguage` / `normalizeLanguage` / `variantOf` across `lib/` and the
backend's `utils/` and `models/Language.js`. `models/Language.js` stores
`code`, `name`, `nativeName`, `flag` with no base/variant relationship.

Any per-language query that does not normalize will miss roughly half its
intended audience.

**Timezone is nominal.** The only timezone field is
`quietHours.timezone` (`models/User.js:205`), default `'Asia/Seoul'`. It is
writable through the notification-preferences endpoint
(`controllers/notifications.js:235`) but nothing auto-populates it, so in
practice every user is Asia/Seoul. All jobs fire on fixed KST times. For an
audience that is 300 Chinese-native and 79 Arabic-native, evening reminders
land in the middle of the night.

---

## 3. Decisions taken

| Decision | Choice |
|---|---|
| Content source | Hybrid — curated core for English, AI-generated for other languages |
| Targeting granularity | Per `(language, level)` |
| Wave scope | Daily content **and** repair of the non-recording loops |

---

## 4. Design

### 4.1 Language normalization (foundation)

Blocks every other section.

- New `utils/languageNormalize.js` (backend) exporting
  `toBaseLanguage(value) -> string | null`, mapping every string observed in
  prod to a base code: the four English variants to `en`, Arabic variants to
  `ar`, and so on. Chinese is the deliberate exception — Simplified and
  Traditional map to **distinct** base codes `zh-Hans` and `zh-Hant`, because
  the written content genuinely differs and both have real populations
  (35 and 16 learners respectively).
- Mirrored `lib/utils/language_normalize.dart` for client-side resolution.
- All daily content is keyed by base code. Users resolve to a base code at
  query time; no write-side migration of `language_to_learn` is required for
  this wave.
- The 134 active users with a blank `language_to_learn` receive a one-tap
  "What are you learning?" selector on the daily card. Setting it writes
  `language_to_learn` and immediately serves that day's content.

### 4.2 Data model

Three new collections. The bank is split from the schedule so a single item can
recur after a full cycle, and so AI-generated items enter the same bank as
curated ones.

**`DailyItem`** — the content bank.

```
{
  language: String,        // base code, e.g. 'en'
  level: String,           // 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2'
  kind: String,            // 'grammar' | 'vocabulary'
  title: String,
  explanation: Map,        // locale -> text; 'en' required, 'zh-Hans' + 'ar' prioritized
  examples: [{ text, translation: Map }],
  quickCheck: [            // exactly 3
    { prompt, options: [String], answerIndex: Number, explanation: String }
  ],
  source: String,          // 'curated' | 'ai'
  approved: Boolean,
  timesUsed: Number,
  lastUsedDate: String,    // 'YYYY-MM-DD' or null
}
```

Index: `(language, level, kind, approved, lastUsedDate)` to support
least-recently-used selection.

**`DailyDrop`** — the schedule.

```
{
  dateKey: String,         // 'YYYY-MM-DD', UTC day
  language: String,
  level: String,
  grammarItem: ObjectId,   // ref DailyItem
  vocabItem: ObjectId,     // ref DailyItem
}
```

Unique index: `(dateKey, language, level)`.

**`DailyDropCompletion`** — per-user progress.

```
{
  user: ObjectId,
  dateKey: String,
  kind: String,            // 'grammar' | 'vocabulary'
  score: Number,           // 0-3, from quickCheck
  completedAt: Date,
}
```

Unique index: `(user, dateKey, kind)`.

### 4.3 Content generation and the hybrid rule

A generation job runs at 00:05 KST. For each `(language, level)` pair in the
active set — derived from normalized `language_to_learn` of users active in the
last 30 days, crossed with the levels those users actually hold (plus A1, A2
and B1 always, since A2 is the default for the 809 users with no level) — it
selects the least-recently-used approved `DailyItem` of each kind and writes a
`DailyDrop`.

**Level fallback.** A user who nudges themselves to a level with no bank
coverage (B2, C1, C2 today) is served the nearest lower level that has an item,
and the card states which level it is showing. No `(language, level)` pair ever
resolves to an empty screen.

**English is curated-only.** English is the majority target by a wide margin;
that audience is never served an unreviewed generation. If the English bank is exhausted for a
`(level, kind)`, the job reuses the least-recently-used approved item and logs
a bank-exhaustion warning rather than falling back to AI.

**Non-English is AI-filled.** When no approved item exists for a
`(language, level, kind)`, the job generates one and runs a validator before
insertion:

- schema shape matches `DailyItem`
- `explanation` non-empty, within length bounds
- exactly 3 `quickCheck` entries, each with a valid `answerIndex`
- at least 2 examples
- target-language check on example text

Items passing the validator are inserted with `source: 'ai'`, `approved: true`,
and flagged for later human review. Items failing the validator are not
inserted; the job logs and reuses the least-recently-used existing item, or
serves nothing for that pair if the bank is empty.

Hand-authoring ko/ja/zh/fr/ru/de/es/ar is not justified at 12–50 learners each.

### 4.4 English curated bank

Seed 30 days × 2 kinds × 3 levels (A1, A2, B1) = **180 items**, following the
existing `seeds/` pattern in the backend. A1/A2/B1 covers 57 of the 66 users who
have declared a level, and is where the A2 default lands new users.

Generation is AI-assisted, but every item is human-reviewed before `approved`
is set. Grammar items are the priority: only 6 grammar lessons exist today, so
this is where new material genuinely adds coverage rather than duplicating the
12,600 unused exam vocabulary words.

`explanation` is authored in `en`, `zh-Hans` and `ar` for the curated bank.

**Cycle length consequence.** A 30-day bank repeats for any user who sustains a
30-day streak. That is acceptable for this wave — the week-4 success target is
25 users at a 7-day streak, and today nobody has reached 7 — but the bank
should be extended before a meaningful cohort passes day 30. The
bank-exhaustion warning logged in §4.3 is the signal to do so.

### 4.5 Level handling

Every user without a `languageLevel` is served **A2**.

Each daily card carries a *too easy* / *too hard* control. One tap:

1. nudges the user's `languageLevel` one step in that direction (creating it if
   null),
2. re-serves that day's drop at the new level.

This is the calibration mechanism and an engagement beat in one, and it
populates `languageLevel` as a side effect rather than through a settings form
that 809 users have not filled in.

### 4.6 API

All under the existing versioned prefix.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/study/daily` | Today's grammar + vocabulary for the caller's resolved `(language, level)`, plus their completion state |
| `POST` | `/api/v1/study/daily/:itemId/complete` | Submit `quickCheck` answers; returns score, XP awarded, updated streak |
| `POST` | `/api/v1/study/daily/:itemId/feedback` | `{ verdict: 'tooEasy' \| 'tooHard' }`; nudges level, returns the re-served drop |
| `GET` | `/api/v1/study/daily/archive` | Previous days' drops with completion state, for catch-up |

`GET /daily` accepts optional `date`, `lang` and `level` overrides for testing
and for the archive view.

### 4.7 Streak and XP

Completing **both** kinds for a `dateKey` marks the day done. That is the
unambiguous daily action the hub currently lacks: it sets
`LearningProgress.lastActivityDate`, increments `currentStreak`, and awards XP
through the existing `config/xpRewards` path.

This is the anchor for the retention metric. Today zero users have reached a
7-day streak.

### 4.8 App surface

- A **Today** section at the top of
  `lib/pages/learning/main/sections/learn_tab.dart`: two cards (Today's Grammar,
  Today's Vocabulary), each a 60–90 second interaction, with a streak ring and
  a done/missed state.
- New screen `lib/pages/learning/daily/daily_drop_screen.dart` presenting the
  explanation, examples, and the 3-question quick check.
- The existing `lib/pages/learning/main/sections/daily_practice_card.dart`
  (AI daily practice) moves below the Today section rather than competing with
  it for the same slot.
- New providers under `lib/providers/provider_root/learning/` following the
  existing pattern in that directory.
- All Dart imports use `package:` paths, per project convention.

### 4.9 Notifications

**New type `daily_drop`.** It must be added to the `type` enum in
`models/Notification.js` in the same commit that first sends it.
`models/Notification.js` documents three prior incidents where a missing enum
value caused `_saveToHistory` to throw a silently-swallowed `ValidationError` —
push fired, the history row and badge increment never happened. The existing
`test/notificationTypeEnum.test.js` guards this; extend it.

Three changes matter more than the notification itself:

1. **Per-user local time.** The app reports its IANA timezone on launch,
   persisted to the user record. Two new `User` fields are required: a
   real `timezone` (distinct from the existing `quietHours.timezone`, which
   stays as-is for quiet-hours semantics) and
   `notificationSettings.dailyDropHour` (default 19:00). A delivery job runs
   hourly and sends to users whose local hour matches that setting. Fixed-KST blasting to a Chinese- and Arabic-majority
   audience is a plausible contributor to the current 12–16% read rates.
2. **Copy names the content.** "Today's grammar: *used to* vs *would* — 2 min"
   rather than "You have words due." Specificity is what the current templates
   in `utils/notificationTemplates.js` lack.
3. **Push is not the only channel.** Only 305 of 875 active users are reachable
   by push. The same drop surfaces as a Study Hub tab badge and as a line in
   the existing weekly digest email (`jobs/weeklyDigestJob.js`).

Delivery routes through `services/notificationService.send()` so it inherits
preference gating, quiet hours, history and badge increments. A daily cap for
`daily_drop` is added to `config/notificationCaps.js`.

Deep link: a new `case 'daily_drop'` in `lib/services/notification_router.dart`
opening the drop screen directly, not the hub root.

### 4.10 Loop repairs

**Prerequisites** — without these the wave cannot be targeted or measured:

- **P1. Language normalization** (§4.1).
- **P2. Notification click tracking.** `clicked` is false on all 4,564 rows
  because `lib/services/notification_router.dart` never reports a tap. Add the
  click ping and the corresponding backend endpoint. Until this lands, the
  effectiveness of the daily notification is unmeasurable.

**Bugs**, ordered by evidence strength:

- **B1. SRS review never records.** `reviewCount > 0` matches 0 of 292
  vocabulary rows; `isMastered` and `isArchived` are 0 across the board; all
  292 words are permanently due. The app has been sending 186 reminders about
  a queue no one can clear. Trace the full path from
  `lib/pages/learning/vocabulary/vocabulary_review_screen.dart` through the API
  to the `Vocabulary.nextReview` / `reviewCount` write.
- **B2. Achievements never award.** `userachievements` is empty despite 42
  defined achievements and a fully built unlock overlay in
  `lib/pages/learning/main/learning_main_screen.dart`.
- **B3. Lesson completion never records.** 28 `LessonProgress` docs across 25
  users, 0 with `completed: true`, against 84 published lessons.
- **B4. Quiz attempts and challenge progress are both 0.**

These four zero-counts may share a single root cause in the progress-write
path. They are to be investigated with the systematic-debugging skill and a
root cause established before any fix is written — not patched as four
independent symptoms.

### 4.11 Sequencing risk

§4.10 is large enough to be its own wave. If B1–B4 prove to have independent
root causes, §4.1–§4.9 ship on schedule and the remaining repairs spill to a
follow-up. This is stated up front so the spill is a visible outcome rather
than a silent scope reduction.

---

## 5. Testing

**Backend**

- Normalization table: every language string observed in prod maps to the
  expected base code, including the empty string and unknown values.
- Selection: least-recently-used ordering, no repeat within a cycle, correct
  behaviour on bank exhaustion for both the English (reuse) and non-English
  (generate) paths.
- AI validator: rejects each malformed shape it is meant to catch.
- Completion and streak math, including the both-kinds-required rule and
  same-day idempotency.
- Timezone bucketing: a user in each of several IANA zones receives exactly one
  notification per day at their local `dailyDropHour`.
- `daily_drop` appended to `test/notificationTypeEnum.test.js`.
- Notification cap and quiet-hours gating for `daily_drop`.

**App**

- Widget tests for the Today cards across loading, available, done, and missed
  states.
- Widget test for the blank-`language_to_learn` selector path.
- Router test for the `daily_drop` deep link.
- Quick-check scoring and the too-easy / too-hard re-serve flow.

---

## 6. Success criteria

Measured against the baselines in §1.1 and §2.4:

| Metric | Baseline | Target |
|---|---|---|
| Users with `currentStreak >= 7` | 0 | > 25 by week 4 |
| Study Hub 7-day actives | 69 | > 140 by week 4 |
| `daily_drop` read rate | n/a (12–16% for existing learning types) | > 25% |
| `daily_drop` click-through | unmeasurable today | measurable, with a recorded baseline |
| Vocabulary rows with `reviewCount > 0` | 0 | > 0 within a week of B1 landing |

---

## 7. Out of scope

- Per-user adaptive content selection. There is almost no per-user signal to
  adapt from until B1–B4 are fixed and data accumulates.
- Reworking the exam-question and exam-vocabulary surfaces (19,365 + 12,600
  items). Large, unused, and a separate problem from the daily loop.
- Backfilling or migrating `language_to_learn` values. Normalization happens at
  read time this wave.
- Localizing `explanation` beyond `en`, `zh-Hans` and `ar`.
