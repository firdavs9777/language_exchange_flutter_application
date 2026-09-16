# Matching — Design

**Date:** 2026-09-16
**Status:** draft, open questions unresolved
**Goal:** make matching find the partners that already exist. Today it hides more than
half of them.

---

## 1. The problem, measured

Measured 2026-09-16 against production (1,813 users). The recommendation candidate pool
— `profileCompleted: true` **and** at least one photo — is **1,301 users (72%)**. Every
number below is against that real pool, not the whole user table.

`controllers/matching.js:123` scores a language match with exact string equality:

```js
{ $eq: ['$native_language', currentUser.language_to_learn] }
```

### 1.1 Exact-string comparison hides 56% of the real pairs

| Pairing rule | Perfect pairs | Users with no perfect match |
|---|---|---|
| **Exact string (today)** | **7,596** | **319 (24.5%)** |
| Normalized via `toBaseLanguage` | 17,151 (**+126%**) | 276 (21.2%) |
| Normalized + Chinese family | **18,569 (+144%)** | **249 (19.1%)** |

**9,555 genuine language-exchange pairs — 56% of all that exist — are invisible to the
algorithm**, because "Chinese (Simplified)" and "Chinese" are different strings.

`utils/languageNormalize.js` already exists and already does this. Matching simply does
not call it. `lib/dailyDropTargets.js` does.

### 1.2 Chinese is the biggest population and the most fragmented

586 of 1,776 users are native Chinese speakers — the largest single group, larger than
English (334). The raw values are split four ways:

| Value | Native | Learning |
|---|---|---|
| Chinese (Simplified) | 586 | 82 |
| Chinese (Traditional) | 17 | 35 |
| Cantonese | 3 | 16 |
| Chinese | 1 | — |

`toBaseLanguage` deliberately keeps `zh-Hans` and `zh-Hant` apart, which is right for
*study content* — they are different written languages. It is wrong for *conversation
partners*: a Simplified reader and a Traditional reader speak to each other fine. Treating
the family as mutually matchable is worth **another 1,418 pairs** and drops the
no-match population from 276 to 249.

This is the one place where matching must deliberately diverge from the study-content
normalization, and the spec is explicit about it so a future reader does not "fix" it back.

### 1.3 Nothing records what was shown to anyone

`controllers/matching.js:88-89` reads impressions from a **cache key with a 24-hour TTL**
and nothing else. There is no collection, no log, no durable record. I checked: no
impression, recommendation or match-tracking collection exists.

The consequence is the important one: **no change to the algorithm can be evaluated.**
There is no way to ask whether a recommendation led to a conversation, whether the 50-point
language weight beats the 15-point activity weight in practice, or whether the people shown
most are the people messaged most. "Smarter matching" without this is guessing with extra
steps.

1,257 conversations were created in the last 30 days. That is the outcome variable, and
today it cannot be attributed to anything.

### 1.4 A measurement trap, recorded so it is not stepped in twice

Measured across **all** users rather than the candidate pool, normalization appears to
*destroy* 20,088 pairs. It does not. 271 users have an empty-string `native_language` and
272 an empty `language_to_learn`, and under exact-string comparison `'' === ''` makes every
blank profile a **perfect language-exchange match for every other blank profile** — tens of
thousands of phantom pairs scoring the maximum 50 points.

They are excluded from recommendations today by `profileCompleted` + photo, so this is not
a live defect. But any future query that relaxes either filter will surface them at the top
of everyone's list, and any measurement that forgets the filter will conclude the opposite
of the truth. See [[project-blank-social-signups]].

---

## 2. What to change

In value order. Each step is independently shippable and independently measurable.

### 2.1 Normalize both sides of the comparison

Use `toBaseLanguage` on both the current user's languages and the candidate's, for the
perfect-match branch and both partial branches.

**Constraint: normalization must never shrink the pool.** `toBaseLanguage` returns `null`
for values it does not recognise — American Sign Language (5 native / 16 learning),
Hawaiian, Dari, British/Korean/Japanese Sign Language. A user whose language normalizes to
`null` must fall back to trimmed, case-insensitive raw comparison, not vanish. The current
exact-string rule at least matches those users to each other.

### 2.2 Treat the Chinese family as mutually matchable *for partners only*

`zh`, `zh-Hans`, `zh-Hant` and Cantonese match each other when scoring a conversation
partner. Study content keeps the existing distinction. One shared helper, used by matching
only, with the reason written next to it.

### 2.3 Record impressions durably

Persist what was shown, to whom, at what score, with the reason it scored that way. Then
the outcome — did a conversation start — becomes attributable.

This is listed third by dependency, not by importance. **It is the only change that makes
the next one knowable**, and it should ship first if anything ships alone.

### 2.4 Only then, revisit the weights

`languageMatch: 50` against a maximum of ~40 for everything else is an assumption, not a
finding. It may well be right. With §2.3 in place it becomes answerable; without it, any
reweighting is a coin flip that costs a release to discover.

---

## 3. What this spec does not decide

- **Whether matching is used at all.** No telemetry exists for the matching screens, so
  the size of the prize is unknown. If almost nobody opens them, §2.3 will say so within a
  week and the cheap fix (§2.1) will still have been worth shipping.
- **Dating vs language exchange.** The app serves both. Nothing here distinguishes a user
  looking for a partner from one looking for a tutor, and the scoring cannot express the
  difference. That is a product decision, and a real one — it likely deserves its own
  spec rather than a weight.
- Reciprocity ("do I match them as well as they match me"), which the current
  scoring does not model at all.

---

## 4. Testing

- **Pure:** the pairing rule is a function of two language pairs, so every case above is a
  table test — including the sign-language fallback and the Chinese family.
- **Regression:** a user whose language normalizes to `null` still matches the people they
  match today. This is the one that protects against §2.1's failure mode.
- **Fixture:** the exact-string rule and the new rule run against the same 1,301-user
  shape, asserting the pair count rises rather than falls.
- **Blank profiles never score as a perfect match**, whatever the candidate filter is.

---

## 5. Rollout

§2.1 and §2.2 change what users see and have no kill switch worth building — the change is
a scoring expression, and a half-applied one is incoherent. §2.3 is additive and carries no
user-visible risk.

Watch: conversations created per week (1,257/30d today) and the share of users with at
least one perfect match (80.9% after §2.2, up from 75.5%).

---

## 6. Open questions

1. **Is the Chinese family really mutually intelligible enough for partner matching?** The
   data says it doubles the pool for the largest group. A native Chinese speaker should
   confirm before shipping, because the alternative is 586 users being shown partners they
   cannot comfortably talk to.
2. **Should a user learning a language they already speak natively be matched at all?**
   Not checked; unknown how many exist.
3. **What is the right fallback for unrecognised languages** — raw comparison, or an
   explicit "other" bucket that matches nothing? Raw comparison preserves today's
   behaviour, which is the conservative choice, but it also preserves today's
   case-sensitivity.
