# AI Study: one path, built from your own conversations, free to try then paid

Date: 2026-11-14. Project 4 (moved ahead of rooms and chats at the owner's request).
Repos: app `bananatalk_app/`, backend `be-integration`.

The owner's brief: more data and more valuable features for the AI Study tab; sophisticated underneath but easy for a language learner to follow; informed by what other apps and research show; it should earn money, with people enjoying a free trial and then paying.

## 1. What we know

### 1.1 Production, 2026-11-14 (241 people active in the last week)

- About 5% of weekly actives use any study feature in a week. In 30 days: daily pack 42 people, tutor 40, grammar units 32, saved words 28, pronunciation 19, quizzes 9, lessons 4, roleplay conversations 0, exam plans 0.
- People try once and leave: 31 of 42 daily-pack users did it on one day only; 32 of 40 tutor users had one session of two to four messages.
- Nobody has a measured level. No learner has completed a placement test; the pack serves level A2 to everyone and the progress screen says A1 for all 216 people who earned points.
- Saved words are not reviewed: 608 words across 120 people, 27 ever reviewed, none mastered, all 608 overdue.
- In-chat translation is the most used AI feature (100 people, 623 detailed translations in 30 days). Nothing from it becomes study material unless the person taps save.
- People who use a study feature are active on 4.9 days a month against 2.1 for everyone else, and 23% of them come on 8+ days against 6%. This is a correlation.
- Learners: English about 101, Chinese 25, Korean 22, Japanese 14, Arabic 6.

### 1.2 The code (survey 2026-11-14)

The hub shows a daily pack and 12 feature tiles. Several things are broken or unconnected:

- The "recommended for you" tile never shows (the app expects a list, the server sends an object).
- Achievements and challenges cannot work: nothing ever creates their rows. Both still have tiles.
- The tutor's daily plan never includes a review task (it reads a field that does not exist), the tutor is given the oldest chat summary instead of the newest, and its "weak areas" are only written by a screen that is no longer reachable.
- The free tutor allowance is 5 messages a day, not 5 conversations.
- Partner corrections are stored and never read. Translations are cached with no link to the person.
- The daily reminder push names a lesson the pack does not serve, counts the pack done at 2 of 4 steps, and is English only.
- Words saved from chat are stored with language `auto`; vocabulary rows mix `en`, `English`, `English (US)`, `français`.
- A learner whose profile says plain "Chinese" gets a separate, smaller content pool than "Chinese (Simplified)".
- One level is shared across all of a person's languages.
- Nothing is painted from disk when the tab opens, and on weekends the first pack request can wait on an AI call.
- No study screen opens or starts are recorded on the server; only completions leave a trace.

### 1.3 What others do and what research shows

Measured:

- Trials of 5 to 9 days convert better than 4 days or less and improve first renewal; education apps mostly use 5 to 9 days (RevenueCat).
- Freemium converts far fewer trials than a hard paywall (about 2% against 11%), but education converts later than other categories.
- Duolingo cut the daily goal to one lesson and separated it from the streak: two-week retention up 3.3%.
- Spaced review has a medium-to-large effect on second-language learning (48 experiments).

Reported without numbers:

- Calling the placement test "check your level" doubled how many people took it (Duolingo).
- HelloTalk caps AI correction per day; Tandem charges for explanations of corrections. Both keep chat itself free.

Not found: evidence on turning a learner's own chats into study material, on whether people pay for AI feedback on their messages, or an app benchmark for giving premium free without the store.

## 2. The idea

Three changes, in this order of importance:

1. **One path.** Opening the tab offers one short session for today, at the person's real level, that ends by pointing to the next thing. The tiles stay below it for people who want them.
2. **Your own conversations are the textbook.** The words a person looked up while chatting and the corrections partners gave them become their review and practice. No other study app has this material; an exchange app does.
3. **Free to try, then paid.** The daily session and basic review stay free. Everything with a real AI cost per use has a small free allowance and is unlimited in the existing VIP subscription, which gets a 7-day store trial offered at the moment a person has just finished something.

Underneath sits one learner record per person and language (level, word memory, weak areas) that every feature reads and writes. That is where the sophistication goes; the learner only ever sees "today's session" and "from your chats".

## 3. Goals, non-goals, anti-goals

Goals, measured 30 days after each phase is switched on:

- Share of weekly actives who start a study session in a week: from about 5% to 15%.
- Of people who do a session, the share who do one on a second day within a week: from 26% (11 of 42) to 40%.
- Saved or captured words reviewed at least once: from 4% to 40%.
- A level on record for every learner who completes two sessions.
- Trial starts and trial-to-paid conversion exist as numbers (today: none).

Non-goals:

- No new study feature types (no new game, no video lessons). No redesign of the tab's look.
- No new store products; the trial is an introductory offer on the existing VIP products.
- No change to chat, translation limits for chatting, or partner matching.
- No release build, version bump or store submission in these plans.

Anti-goals:

- A learner hits a paywall before finishing a first session.
- Anything from a partner's messages is shown to anyone but the learner who received it, or kept after either account is deleted.
- The free session gets shorter or worse than today's pack.
- AI spend per paying user is unbounded.

## 4. Constraints

- Every behaviour change ships behind a server switch that defaults to off; with the switches off, responses and screens are as today. Bug fixes listed in 5.1 are the exception and need no switch.
- Existing study data (progress, streaks, saved words, mastery) is kept and keeps working.
- Reels playback files are not touched. Every commit updates `docs/REMAINING_WORK.md`.
- New user-facing strings are allowed in this project (it changes what the tab says) and must be added for every app language, marked machine-drafted for native review.
- Apple: the trial is a store introductory offer; the paywall states the price at least as prominently as the trial; no task is required to receive what was paid for.

## 5. Phase 1: foundations (make what exists work, and measure it)

### 5.1 Fixes (no switch)

- Recommended tile reads the server's shape.
- Tutor daily plan reads the real review field; the tutor gets the newest summary.
- Achievements and Challenges tiles are hidden while nothing can populate them; the tab stops requesting achievements on open.
- Daily reminder push names the pack's actual lesson, counts completion as the pack does, and uses the person's language where a translation exists.
- Words saved from chat get the learner's target language instead of `auto`; one backfill script normalises existing vocabulary language values to codes (dry run first).
- Plain "Chinese" learners are served the Simplified pool.
- Free tutor allowance: 5 conversations a day of up to 10 messages each, replacing 5 messages a day. A conversation is one tutor session as the server already records it (free chat or roleplay); the count is sessions started that day. (My call: a 5-message cap ends a first try before it gets anywhere. This loosens a limit, so it needs no switch.)
- Server changes in this phase stay compatible with the app build people have today; app-side fixes take effect in whichever build the owner releases next.

### 5.2 A level per language, adjusted by evidence

- Level becomes per person and language. Existing single values are carried to the person's current learning language but marked unmeasured: nobody's level today rests on evidence.
- "Check your level" replaces "placement test" in the app's wording and is offered once on the first session, skippable. Sets are prepared ahead for the six most-learned languages.
- With or without the check, the level moves with results: each scored step nudges an estimate up or down, and the level changes when the estimate has stayed across a boundary for three sessions. A learner is told when it happens.
- While a level is unmeasured it settles fast: it may move one level after each of the first three sessions. Once measured (a completed check, or three sessions), it changes at most once a week.
- Rule left to the builder to specify exactly in the plan: a simple rating update per scored step within those bounds.

### 5.3 Study events on the server

- A small event log: tab opened, session started, step started and finished (with kind and score), feature opened, check-your-level started and finished. Sent in batches with the same queue-and-drop approach as paywall events. Switch `STUDY_EVENTS_ENABLED`.
- One script prints the weekly study funnel: opened, started, finished, came back within 7 days, by language.

### 5.4 Fast open

- The tab paints its top section from disk (last pack summary, streak, level) and updates in place. Per-user, cleared on sign-out.
- The pack is built with its independent parts in parallel, and the weekend AI sentence is prepared by the nightly job instead of on the first request.
- The nightly job stops generating items no pack will use.

## 6. Phase 2: the path and your own conversations

### 6.1 One learner record

Per person and language: level estimate (5.2), word memory (the existing saved-word schedule), and weak areas. Weak areas get real writers:

- grammar steps answered wrong in a session,
- errors found by writing feedback,
- corrections received from partners,
- pronunciation words scored low,
- mistakes in tutor roleplay.

Each weak area has a strength that fades over 14 days without new evidence and is cleared after three successes (the existing rule). The tutor, the session builder, the weekly report and the recommended tile all read this one record.

### 6.2 From your chats

- When a learner translates a partner's message, the words and short phrases from the breakdown that are in the language they are learning become candidates. Nothing extra is sent to an AI; the breakdown already exists.
- When a partner corrects a learner's message, the original and the correction become a mistake card and feed weak areas.
- Candidates are private to the learner. Only the word or phrase and its translation are kept: no sentence from the partner's message and no generated example in this version. Each candidate records which partner it came from, only so that it can be deleted with either account.
- Capture is on the learner's side only: these are words the learner already received and chose to translate. Whether the privacy policy and the stores' data-safety forms need a line about it is the owner's check before the switch goes on (section 12).
- A person can turn capture off in study settings. Default on, said plainly on first appearance.
- Candidates are ranked by how often the person met the word, how recently, and how close it is to their level, and the top few are offered: "From your chats: 6 words to keep". Keeping one adds it to their saved words. Ignored candidates fade out after 14 days.
- This card takes the slot of the recommended tile on the hub. Switch `STUDY_FROM_CHATS_ENABLED`.

### 6.3 Today's session

The daily pack becomes three steps of about five minutes in total, chosen by the learner record:

1. **Remember.** Up to 8 due words, the person's own chat words first, then the most overdue. The 608-word backlog is worked down a few a day instead of shown as one wall.
2. **Learn.** One new thing at the person's level: the next grammar unit, or the theme words, alternating by day, with weak areas pulled forward.
3. **Use it.** One short task that uses today's material: a listening item, a sentence to translate built from the person's words, or saying one sentence aloud. It rotates.

- Finishing step 1 keeps the streak (a one-step goal, as Duolingo's result suggests); finishing all three is the full session.
- The end screen always offers one next step: "Talk about this with your tutor" (opens the tutor already primed with today's words and weak areas), or tomorrow's preview when the tutor allowance is used.
- Existing completion, XP and streak records keep their meaning. Switch `STUDY_TODAY_V2_ENABLED`; with it off the pack is today's four stations.

### 6.4 The tutor knows the learner

The tutor's context gains today's words, the top weak areas with one example each, and the person's level for that language. Roleplay mistakes and scores write back to weak areas. No new tutor screens.

## 7. Phase 3: free, trial, paid

### 7.1 The line

| | Free | VIP (and during the trial) |
|---|---|---|
| Today's session | Full, every day | Full |
| Review of saved and chat words | In the session (up to 8 a day) | Unlimited extra review |
| From your chats | Keep up to 5 candidates a day | Unlimited, plus practice sets built from them |
| Check your level, streak, progress | Yes | Yes |
| AI tutor and roleplay | 5 conversations a day, 10 messages each | Unlimited within fair use |
| Feedback on your own writing and messages | 3 a day, corrections only | Unlimited, with the explanation of each mistake |
| Pronunciation scoring | 5 a day | Unlimited within fair use |
| Weekly report | Summary | Full, with weak areas and what to do next |

- What exists today and what is new: the tutor's 5-a-day allowance and the 5 translations a day are enforced now. Pronunciation scoring and writing feedback are effectively unmetered today, so their free allowances (5 and 3 a day) are new limits. They go on only with `STUDY_TRIAL_ENABLED`, in the same step that adds the trial, never before.
- Fair use for VIP: a daily ceiling per AI feature set high enough that a normal learner never meets it (starting values in the plan), so cost per payer is bounded.
- Existing coin unlocks for single extra uses stay as they are.
- "Explanation of each mistake" is the headline paid feature. Both exchange competitors charge for it; whether people pay is unproven, so it is measured from day one.

### 7.2 The trial

- A 7-day free trial as a store introductory offer on the monthly and yearly VIP products. The owner creates it in App Store Connect and Play Console; the app reads the offer from the store and shows it only when the store says the person is eligible.
- Where it is offered: on the end screen of a completed session (from the second completed session on), and at the moment a free allowance runs out. Never before a first session is finished, never at launch. A current VIP never sees it. When an allowance runs out the existing sheet keeps both of today's choices (coins for one more, or VIP); the trial line is added to the VIP choice when the store says the person is eligible.
- The server does not know about trials today: nothing in the purchase code reads a trial or introductory period. This phase adds it: receipt verification and the store notifications record that a subscription is in its trial and when the trial ends, the person is VIP during it, and VIP ends correctly if they cancel. Trial starts and trial-to-paid come from these records, not from the app.
- Purchases have been proven end to end once, on iOS in the sandbox (2026-10-18). Android has never been verified. A sandbox trial purchase on both platforms is a gate before the switch goes on.
- The paywall reuses the existing VIP plans screen with a study-specific header listing the four study benefits, the price, and the trial length, price first.
- A reminder push two days before the trial ends, saying what day billing starts and one thing the person did during the trial. (Honest reminders reduce refunds and bad reviews; my call.)
- All of it reports to the paywall funnel built in the monetization project (placements `study_lock`, `tutor_quota`, plus a new `study_session_end`). Switch `STUDY_TRIAL_ENABLED`.

### 7.3 Prices

Owner's decision, with this recommendation: keep the planned 3.99 monthly and 24.99 yearly in the US tier, set lower store tiers for China, Southeast Asia, the Middle East and CIS rather than trusting automatic conversion, and add no lifetime or weekly plan until there is a conversion number to compare against.

## 8. Content for the languages people learn

- English is well covered. For Chinese, Korean and Japanese: grammar units to B1 and "check your level" sets come first, since these are 61 of the weekly learners.
- No content is generated for a language with fewer than 5 active learners (existing rule), and what is generated is only what a session will serve.
- Content work is authored and reviewed outside these plans' code tasks; the plans provide the loading and the gaps report (`scripts/studyContentGaps.js`: learners by language and level against available units).

## 9. Rollout

1. Phase 1 fixes ship with the next build. Events on as soon as a build with them is out; read the funnel after two weeks.
2. Levels, then From your chats, then Today's session, each switched on separately with a week between, watching the funnel.
3. Trial last, after the session is on and the store offers exist. Success is judged on the goals in section 3.

## 10. Left to the builder

- The exact level-estimate update and thresholds; the candidate ranking formula; fair-use numbers; storage shapes; which existing endpoints grow and which are new.
- How the three session steps map onto the existing station kinds and completion records.

## 11. Calls I made (not the owner's decisions)

- "More data" is read as both: content where learners are, and measurement of what they do.
- Tutor free allowance becomes 5 conversations of 10 messages.
- Chat capture is on by default with an off switch, and keeps words and phrases only.
- Achievements and Challenges tiles are hidden rather than built out.
- The trial is the store's 7-day offer, not a free premium period granted by the app; there is no benchmark for the latter.
- Lessons, quizzes and exams stay where they are, untouched.
- An unmeasured level may move after every one of the first three sessions.
- Chat candidates keep no sentences at all in this version.

## 12. Owner's decisions needed

1. The free and paid line in 7.1.
2. Creating the 7-day introductory offers and regional prices in both stores.
3. Whether chat capture defaulting to on is acceptable, and whether the privacy policy and the stores' data-safety forms need updating for it.
4. Whether adding free allowances to pronunciation scoring and writing feedback (unmetered today) is acceptable as part of the trial step.
