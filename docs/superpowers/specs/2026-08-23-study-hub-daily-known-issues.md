# Study Hub Daily — known issues and deferred items

Carried out of the implementation session (2026-08-23). Nothing here blocks merge;
every item was reviewed and consciously deferred. Recorded so it is not rediscovered
from scratch later.

## Pre-existing, found while working here (NOT caused by this wave)

- **`npm test` hangs for everyone.** Not slow — a test leaves a handle open so the
  process never exits. `node --experimental-test-module-mocks --test --test-force-exit
  services/*.test.js test/*.test.js` runs the whole suite in ~5s. The `test` script in
  `package.json` lacks the flag.
- **`test/profileVisitCleanup.test.js` has never passed** — `ReferenceError: describe is
  not defined`; it never imports `describe` from `node:test`. Untouched by this branch.
- **`controllers/tutor.js:25` and `controllers/learning.js:235,346` award XP without ever
  touching the streak.** The daily drop now advances the streak correctly, but those
  surfaces still do not.

## Deferred from this wave

- Task 2 resolveLevelWithFallback recurses on an invalid `requested` rather than treating it as "nearest to default" — unspec'd, untested, reasonable.
- Task 2 nudgeLevel treats any non-'tooEasy' verdict as 'tooHard'. Covered downstream — Task 8's controller rejects anything outside ['tooEasy','tooHard'] with a 400 before calling.
- Task 3 brief's test file exercises too-few quickCheck (slice 0,2) but not 4+; `!== 3` covers it functionally.
- Task 3 no test for a null/non-object quickCheck entry or a per-entry examples[i].text failure; correct by inspection.
- Task 1 — PARKED: re-review found bare '中文' returns null (toIso has no native-script key). Ruling: deferred, not fixed. Prod language_to_learn values are English names or ISO codes (§2.1 measurement showed no native-script values) and utils/languageCodes.js documents the same; the correct home for a '中文' alias is NAME_TO_ISO in languageCodes.js, which controllers/moments.js uses for feed ranking — a wider blast radius than this wave should take unilaterally. Cost if wrong: a user whose stored value is literally '中文' gets no daily drop.
- Task 1: complete (backend commits 73f99f6..4e00b42, 1 parked)
- Task 5 eligibility uses truthy `i.approved` not `=== true`; Mongoose casts the field to Boolean so equivalent in practice.
- Task 5 the determinism test asserts two orderings agree rather than pinning a specific winner; still catches a missing _id tiebreak. Brief-prescribed test.
- Task 6 feature key 'daily_drop_generation' is not registered in config/aiConfig.js; chatCompletion falls back to `|| 1024` maxTokens and `?? 0.7` temperature, so harmless. Register it if AI fill is ever tuned per-feature.
- Task 6 generateDailyItem (the network path) has no test coverage — an explicit brief constraint, not an implementer gap.
- Task 7 exports KINDS_REQUIRED beyond the brief's stated interface; harmless constant.
- Task 8 LearningProgress.getOrCreate has a theoretical duplicate-key race under concurrent first-time requests (unique index on `user`). Pre-existing in the reused static, not introduced here.
- Task 16 submitDailyFeedback hard-casts languageLevel with no fallback; correctAnswers maps elements without per-element null-safety. Both brief-prescribed and safe against the server schema.
- Task 18 score denominator is hardcoded '$score/3' rather than item.quickCheck.length; brief-inherited latent assumption.
- Task 18 tests locate cards by text rather than a per-card Key; slightly brittle for follow-on test authors.
- Task 12 N+1 in delivery — up to 4 queries per matching user, drop lookup not cached across users sharing a (dateKey, language, level). All indexed; low thousands of point queries/hour at 875 users. Revisit at 10x scale.
- Task 12 generation re-fetches the full per-language bank once per (language, level) rather than once per language.
- Task 14 answerIndex distribution across all 540 questions skews to index 1 (0: 34.4%, 1: 58.7%, 2: 6.9%). Not degenerate, but a learner could partially game by defaulting to the middle option. Flag for the human review pass.
- Task 23 isValidTimezone accepts case-variant IANA strings and stores them unnormalized; harmless since localHourFor re-runs the same Intl check.
- Task 23 no backend test for the timezone-persistence path itself.

## Delivery is gated off

`jobs/dailyDropJob.js` (backend) now gates `runDailyDropDelivery()` behind the env var
`DAILY_DROP_DELIVERY_ENABLED`. It **defaults OFF** — delivery runs only when the value is
exactly the string `'true'`; anything else (unset, empty, `'1'`, `'yes'`, `'TRUE'`) is
treated as off. `runDailyDropGeneration()` is unaffected and keeps running nightly so the
content bank keeps rotating and drops exist the moment delivery is switched on.

Reason: the backend half of daily drop shipped ahead of the app half. Until an app build
carrying the `daily_drop` deep-link route and Today section has reached users, turning
delivery on would push a notification for a screen ~113 real users cannot open. Do not
set `DAILY_DROP_DELIVERY_ENABLED=true` on the server until that app build is out.

## Migration consequence to know before deploy

On the first `updateStreak()` after rollout, a user whose `lastActivityDate` is already
today (UTC) with no `lastStreakDateKey` yet gets one extra streak increment. Deliberate —
the alternative reset healthy streaks to 1. One-off, errs toward preserving streaks.
