# Study Hub Daily — known issues and deferred items

Carried out of the implementation session (2026-08-23). Nothing here blocks merge;
every item was reviewed and consciously deferred. Recorded so it is not rediscovered
from scratch later.

## Pre-existing, found while working here (NOT caused by this wave)

**All four RESOLVED 2026-09-11** — backend `fix/deferred-backend-four`, merged as
`4502ce0` and deployed to production. Suite is 580/581 (the one failure is environmental,
see below).

- ~~**`npm test` hangs for everyone.**~~ FIXED (`ddb01a3`) — `--test-force-exit` added to
  the `test` script; the whole suite finishes in ~5s.
- ~~**`test/profileVisitCleanup.test.js` has never passed.**~~ FIXED (`d8372f0`) — it was
  worse than the missing `describe` import: it used Jest globals throughout, pointed
  mongoose at `process.env.MONGO_URI` (**production**) and ran `ProfileVisit.deleteMany({})`
  in `beforeEach`, and its User fixtures omitted required schema fields. Rewritten for
  `node:test` on an in-memory Mongo, and re-aimed at the real seam:
  `User.findByIdAndDelete()` never cascaded anything (there is no hook for it) — account
  deletion goes through `services/userCascadeDeleteService.js`.
  **It then exposed a real bug**, also fixed in that commit: step 13 deleted only
  `{ visitor: userId }`, so every visit made TO a deleted user's profile was left behind
  as an orphan pointing at a dead account. `controllers/auth.js:1859` always used the
  correct `$or`; the service did not.
- ~~**`controllers/tutor.js:25` and `controllers/learning.js:235,346` award XP without ever
  touching the streak.**~~ FIXED (`21787c5`) — new
  `learningTrackingService.awardXPWithStreak()` advances the streak first (so `awardXP`'s
  streak multiplier sees today's increment, matching `controllers/dailyStudy.js`), then
  awards, idempotent per UTC day via `lastStreakDateKey`. Wired into tutor chips, tutor
  daily practice, `add_vocabulary` and `add_vocab_pack`. The get-or-create of the progress
  row was also lifted out of `awardXP` so `updateStreak` shares it — it used to return
  `'Progress not found'` for a user whose first-ever activity hit it, silently awarding
  nothing.

## Deferred from this wave

- Task 2 resolveLevelWithFallback recurses on an invalid `requested` rather than treating it as "nearest to default" — unspec'd, untested, reasonable.
- Task 2 nudgeLevel treats any non-'tooEasy' verdict as 'tooHard'. Covered downstream — Task 8's controller rejects anything outside ['tooEasy','tooHard'] with a 400 before calling.
- Task 3 brief's test file exercises too-few quickCheck (slice 0,2) but not 4+; `!== 3` covers it functionally.
- Task 3 no test for a null/non-object quickCheck entry or a per-entry examples[i].text failure; correct by inspection.
- Task 1 — PARKED: re-review found bare '中文' returns null (toIso has no native-script key). Ruling: deferred, not fixed. Prod language_to_learn values are English names or ISO codes (§2.1 measurement showed no native-script values) and utils/languageCodes.js documents the same; the correct home for a '中文' alias is NAME_TO_ISO in languageCodes.js, which controllers/moments.js uses for feed ranking — a wider blast radius than this wave should take unilaterally. Cost if wrong: a user whose stored value is literally '中文' gets no daily drop.
- Task 1: complete (backend commits 73f99f6..4e00b42, 1 parked)
- Task 5 eligibility uses truthy `i.approved` not `=== true`; Mongoose casts the field to Boolean so equivalent in practice.
- Task 5 the determinism test asserts two orderings agree rather than pinning a specific winner; still catches a missing _id tiebreak. Brief-prescribed test.
- ~~Task 6 feature key 'daily_drop_generation' is not registered in config/aiConfig.js.~~ FIXED 2026-09-11 (`3b96898`) — registered at exactly those former fallback values (1024 / 0.7), so generation behavior is unchanged and the knob now exists.
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

## Delivery gate — now on by default (2026-08-28)

`jobs/dailyDropJob.js` (backend) gates `runDailyDropDelivery()` behind the env var
`DAILY_DROP_DELIVERY_ENABLED`. It originally **defaulted OFF** (delivery ran only when the
value was exactly the string `'true'`) because the backend half of daily drop had shipped
ahead of the app half — turning delivery on would have pushed a notification for a Today
screen real users' installed builds couldn't open.

That reason no longer applies: Study Hub Daily shipped in app **v2.2.3 to both the App
Store and Play Store**. The gate has been inverted accordingly and now defaults **ON** —
`DAILY_DROP_DELIVERY_ENABLED` is an emergency kill switch, not an opt-in. Delivery is
disabled only when the value is exactly the string `'false'`; anything else (unset, empty,
`'true'`, `'1'`, garbage) leaves delivery enabled. `runDailyDropGeneration()` is unaffected
either way and keeps running nightly so the content bank keeps rotating.

To pause delivery in an emergency, set `DAILY_DROP_DELIVERY_ENABLED=false` on the server.

## Migration consequence to know before deploy

On the first `updateStreak()` after rollout, a user whose `lastActivityDate` is already
today (UTC) with no `lastStreakDateKey` yet gets one extra streak increment. Deliberate —
the alternative reset healthy streaks to 1. One-off, errs toward preserving streaks.

## Found during the 2026-09-11 fix pass (open)

- **`config/config.env` carries a 12-character `JWT_SECRET`** (`REFRESH_TOKEN_SECRET` is
  64). `test/authSecretRotation.test.js` enforces a 32-char minimum, so this is now the
  suite's only failure — pre-existing and environmental, invisible until the suite could
  run to completion. If production shares that value it is a weak signing secret, and
  rotating it invalidates every live session, so it needs a deliberate call.
- **Eight AI feature keys still fall through to `chatCompletion`'s hardcoded 1024 / 0.7**:
  `idiomDetection`, `grammarExplanation`, `alternativeTranslations`,
  `contextualTranslation`, `examEssayEvaluation`, `examSpeakingEvaluation`,
  `examStudyPlan`, `pronunciationEvaluation`. Each looks tunable in `config/aiConfig.js`
  but is not. Pinned as `KNOWN_UNREGISTERED` in `test/aiConfigDailyDrop.test.js`;
  registering any of them changes a real token budget or temperature, so they were listed
  rather than silently changed. A NEW unregistered key now fails that test.
- **The `backend` gitlink has no `.gitmodules` entry**, so `git submodule` commands fail on
  it and `backend/` sits empty in a fresh clone. The pointer is still updated by hand.
