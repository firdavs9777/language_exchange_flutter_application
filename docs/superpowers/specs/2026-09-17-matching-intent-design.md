# Matching Intent — Design

**Date:** 2026-09-17
**Status:** approved, ready for implementation planning
**Goal:** let matching tell apart the people who are here to practise a language, the
people here to make friends, and the people here to date — and rank accordingly, without
hiding anyone.

Follows [2026-09-16-matching-design.md](2026-09-16-matching-design.md), which fixed *who
can be paired*. This spec is about *why they are here*, the one deferred item that
document nominated for its own spec.

---

## 1. The problem

`pubspec.yaml` line 2 describes the product as:

> Learn, Meet or Date, the best language exchange application.

The codebase models none of those three. There is no `intent` field on `User`, no intent
UI anywhere in `lib/`, and no term in the matching score that refers to purpose. A learner
who wants grammar practice and a user who wants a date are ranked by one identical
formula:

```
languageMatch   50     activeRecently  15     sameCity        8
languagePartial 20     activeThisWeek  10     levelComplement 6
                                              profileComplete 5
                                              recentlyShown -10
```

Every one of the **1,813 users has no intent recorded**, because there is nowhere to
record one.

### 1.1 Why this costs users

The two failure modes are not symmetrical, and both are retention problems:

- A learner who wanted a study partner is messaged by someone who wanted a date. This is
  the one that makes people leave, and it disproportionately affects women.
- Someone who came to date is ranked into a feed of people who want verb drills, decides
  the app is not for them, and churns in week one.

Neither is visible in the data today, which is the second problem.

### 1.2 It is currently unmeasurable

`MatchImpression` (added by the previous spec's Task 4) records `languageScore`,
`activityScore`, `profileScore`, `locationScore` and `levelComplementScore` per shown
user. It records nothing about purpose, because there is nothing to record. Any claim
that intent-aware ranking helps would be unfalsifiable.

---

## 2. Decisions

| Question | Decision |
|---|---|
| Effect on results | **Soft signal.** Ranks; never excludes. |
| Categories | `learn`, `meet`, `date` — **multi-select** |
| Collection | Registration step, profile edit, Profile Completion card |
| Visibility | `learn`/`meet` shown as chips; `date` never rendered |
| Under-18 and `date` | Stripped server-side on write, ignored on read |

### 2.1 Soft, never hard

A no-intent viewer's feed must be **byte-identical to today's**. This is the single most
important property in the spec: 100% of the existing user base has no intent, so any rule
that filters on it would empty 1,813 feeds on deploy.

It is also the same failure mode as Global Constraint 1 of the previous matching spec — "a
normalization that quietly drops users" — and it is worth naming twice, because the
pressure to make intent a filter will return.

### 2.2 Multi-select, because the honest answer usually is

"Learn and meet" is what most language-exchange users actually want. A single choice
collects the *safest* answer rather than the true one, and the safest answer is always
`learn`, which carries no signal.

### 2.3 Why `date` is private

`learn` and `meet` are social and positive; showing them helps people self-select and
gives users a visible reason to fill the field in. A public "open to dating" badge is a
well-documented harassment vector, especially for women, and would make the field actively
unsafe to set honestly. `date` therefore influences the score and appears nowhere in any
response body that renders another user.

---

## 3. Scoring

A new pure module, `lib/matchIntent.js`, mirroring how `lib/matchLanguage.js` already
isolates the pairing rule so it can be table-tested without a database.

```
intentOverlap: 10   — viewer and candidate share at least one intent
```

### 3.1 Flat, not per-intent

`+10 × (number shared)` would make selecting all three strictly optimal, turning an
honesty question into a ranking lever. A flat bonus means someone who ticks everything
earns exactly what anyone else earns.

The residual gaming — tick all three, overlap with everyone — is accepted deliberately.
It is capped at +10, it is a fifth of the language weight, and a user open to all three
genuinely *is* broadly compatible. It is noted here so a later reader knows it was
considered rather than missed.

### 3.2 Zero when either side is unset

If the viewer has no intents, **every** candidate scores 0 on this term and ranking is
unchanged — §2.1's property, enforced by arithmetic rather than by a branch.

If the viewer has intents and a candidate does not, the candidate scores 0. They are not
penalised relative to today; others simply rank above them. That is the soft signal
working as intended.

### 3.3 Why 10

Language is 50 and dominates by design. Everything else sums to roughly 40. At 10, intent
breaks ties between otherwise comparable partners and cannot outrank a genuine language
pair — which is the recall win the previous spec measured at +144%, and which must not be
eroded two days later by a weight chosen carelessly.

---

## 4. Safety

`date` is removed from `intents` for any user under 18:

1. **On write** — the update handler strips it before persisting.
2. **On read** — the scorer ignores it even if a row somehow carries it.

Two layers because one is a single edit away from being bypassed, and because the
gatherings spec already establishes the stakes: 5 active accounts are under 18, and
adult-minor contact coordinated by this app is recorded there as the most serious risk in
the design. The same standard applies here.

No age helper exists in the codebase. `lib/userAge.js` is added as a pure function over
`birth_year` / `birth_month` / `birth_day`, testable in isolation and reusable by
gatherings later.

**Not in scope:** age-gating anything beyond the `date` intent. This spec does not change
who can message whom.

---

## 5. Collection

Three surfaces, no new interruption invented:

| Surface | Who it reaches |
|---|---|
| Registration step | Every new user |
| Profile edit field | Anyone who opens their profile |
| Profile Completion card | The existing 1,813 |

The third is the one that matters. `ProfileHighlightsTab` already computes a completion
percentage and lists what is missing; adding `intents` to `completion_calculator.dart`
makes the nag that is already on screen do the asking. The card hides itself at 100%, so
this costs nothing once answered.

---

## 6. Measurement

`MatchImpression` gains three fields:

```js
intentScore:  Number   // 0 or 10, as awarded
viewerIntents: [String]
shownIntents:  [String]
```

Without these the change is unevaluable, which is precisely the gap the previous spec's
Task 4 was written to close. Re-introducing it one spec later would be a regression in
method, not just in data.

The question these fields make answerable: **do impressions with `intentScore > 0` convert
to conversations at a higher rate than those without?** That is the number that decides
whether the weight should move, and it cannot be asked today.

---

## 7. Components

Each unit has one purpose and is independently testable.

| Unit | Purpose | Depends on |
|---|---|---|
| `lib/matchIntent.js` | normalize intents; score an overlap | nothing |
| `lib/userAge.js` | age from birth fields; `isMinor` | nothing |
| `models/User.js` | persist `intents` | — |
| `controllers/users.js` | accept intents; strip `date` for minors | `userAge` |
| `controllers/matching.js` | apply the weight; record the impression | `matchIntent` |
| `models/MatchImpression.js` | store the new fields | — |

App side: `Community` model, profile-edit section, registration step,
`completion_calculator.dart`, profile-card chips, l10n across 19 locales.

---

## 8. Testing

| Property | Where |
|---|---|
| Overlap rules, including empty-set cases | `lib/matchIntent` table tests |
| Unset viewer scores 0 against everyone | `lib/matchIntent` table tests |
| Ticking all three earns 10, not 30 | `lib/matchIntent` table tests |
| Age boundaries, incl. birthday today | `lib/userAge` table tests |
| `date` stripped for a minor on write | `controllers/users` test |
| `date` ignored on read even if stored | scorer test |
| **A no-intent viewer's ranking is unchanged** | `controllers/matching` test |

The last is the regression that protects the existing 1,813 and is the one to keep if
anything is ever cut.

---

## 9. Explicitly not in this spec

- **Reweighting** the existing 50/15/8/6. Blocked until impressions accumulate — the
  previous plan says so, and one day of data is not enough to overturn it.
- **Reciprocity scoring.** Still unmodelled.
- **Hard filtering** on intent, now or later, without new evidence.
- **Intent filters in `controllers/users.js` discovery.** Different surface, different
  spec.
- **Changing who may message whom.** Ranking only.

---

## 10. Risk

The failure mode is adoption. A soft signal over a field nobody fills in changes nothing,
and the honest outcome would be an unused column and a weight that never fires. §5 is the
mitigation — the completion card is the only surface that reaches the existing base
without inventing an interruption.

The second risk is the pressure, once adoption rises, to promote intent from a signal to a
filter because it "obviously" should be one. §2.1 and §6 exist so that decision is made
against conversion data rather than intuition.
