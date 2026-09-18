# Matching: put the scorer where people are, and weight it on what replies — Design

**Date:** 2026-09-18
**Status:** approved, ready for implementation planning
**Goal:** rank the Community "All" tab with the matching scorer, and fix the two
weights that production data says are wrong.

**Scope:** backend, plus one app-side query parameter. Paired with
`2026-09-18-community-ui-design.md`, which redesigns the same screen's presentation and
shares no code with this.

**Supersedes nothing.** `2026-09-16-matching-design.md` and
`2026-09-17-matching-intent-design.md` describe the scorer this builds on.

---

## 1. Measurements

Seven read-only queries against production (`test` db, 2026-09-18), run before any of
the design below was settled.

| Measurement | Result |
|---|---|
| Users | 1,856 total · 1,508 with a photo · 238 active in 7d · 783 in 30d |
| VIP subscribers | **0** (`vipSubscription.isActive` false on 1,847, absent on 9; `userMode: 'vip'` = 0) |
| Intents set | **0 of 1,856** |
| Smart Match usage | 60 impressions, **3 distinct viewers**, ever |
| Self-learners (`native == learning`) | 84 of 1,343 usable profiles (6%) |
| Reciprocal supply | 73% of users have ≥1 perfect partner; 20% have none anywhere |
| Message concentration | top recipient messaged by **163** distinct senders; median **3** |

### 1.1 The market is 9:1 lopsided

Perfect partners available per seeker, by cohort:

| Cohort | Seekers | Partners | Per seeker |
|---|---|---|---|
| chinese → english | 370 | 39 | **0.11** |
| arabic → english | 89 | 12 | 0.13 |
| chinese → japanese | 58 | 2 | **0.03** |
| chinese → korean | 40 | 4 | 0.10 |
| russian → english | 27 | 3 | 0.11 |
| english → chinese | 39 | 370 | **9.49** |

No scoring change creates the 331 English natives that do not exist. This is the
constraint the design has to live inside, not a bug to fix.

### 1.2 What actually gets a reply

2,800 conversation pairs, bucketed by language relationship. "Reply" = both people sent
at least one message.

| Relationship | Pairs | Reply rate | Msgs/pair | Scored today |
|---|---|---|---|---|
| perfect (reciprocal) | 454 | **18.7%** | 3.3 | 50 |
| self-learner involved | 319 | 20.1% | 3.5 | 50 → now 0 (fixed, see §2) |
| unrelated | 380 | **16.3%** | 5.2 | 0, and **excluded** |
| study buddy (same target) | 314 | **16.2%** | 3.7 | **0, and excluded** |
| one-way (native of my target) | 1,273 | **12.6%** | 2.3 | **20** |

---

## 2. Findings

**2.1 The scorer is not on the screen anyone uses.** Community "All" calls
`GET /api/v1/users`, sorted `{ 'vipSubscription.isActive': -1, isOnline: -1, lastActive: -1 }`.
Language complementarity is not a factor. `controllers/matching.js` — language pair,
activity, CEFR complement, location tier, intent overlap, seen-decay, impression
logging — is reachable only from the app bar's overflow menu, and has **3 viewers ever**.

**2.2 The best-converting unscored relationship is excluded.** Study buddies (same target
language) reply at 16.2%, above the one-way tier's 12.6%. They score **zero** — no branch
covers `their learning == my learning` — and `/recommendations` then hard-filters
`languageScore > 0`, so they are removed entirely. The same is true of "unrelated" pairs
at 16.3%.

**2.3 The most-promoted relationship is the worst-converting.** One-way matches get 20
points and are 45% of all pairs, at the lowest reply rate in the dataset (12.6%). This is
the pile-on: 370 seekers chasing 39 natives who mostly do not reply. The 163-vs-3
concentration is the same fact seen from the other side.

**2.4 Perfect pairs earn their weight.** 18.7%, the best of any language-defined
relationship. The 50 stays.

**2.5 Already fixed** (backend `621d4b6`, branch `fix/matching-self-learner-pairs`): 84
self-learners were scoring a perfect 50 against each other. Recorded here because it came
out of the same measurements; it is not part of this spec's work.

---

## 3. Design

### 3.1 `sort=smart` on `GET /users`

The All tab stays on `/users`, so the filter sheet, search, and pagination keep working —
the reason `/recommendations` is not an option is that it has no filters, no pagination, a
20-item cap and a 30-minute cache.

A new `?sort=smart` runs the existing `$match` filter, then the scoring `$addFields`, then
sorts by score. The unfiltered default sort is untouched, so anything not passing
`sort=smart` behaves exactly as today.

Gated by `SMART_SORT_ENABLED` (default off until verified), matching the project's
existing kill-switch convention.

**Pagination determinism.** `randomFactor: { $multiply: [{ $rand: {} }, 5] }` re-rolls per
request, so paging with it would re-shuffle between pages and show duplicates while hiding
others. On the paginated path the jitter must come from a stable per-viewer-per-day seed,
or not at all. This is the single most likely bug in the implementation.

**No language exclusion on this path.** `/recommendations` keeps its `languageScore > 0`
filter; `sort=smart` does not adopt it. §1.2 shows unrelated pairs out-converting a tier
we actively promote, and the All tab is a browse surface with its own filters — excluding
people from it is the filter sheet's job, not the scorer's.

### 3.2 Reweighting

| Branch | Now | Proposed | Basis |
|---|---|---|---|
| perfect (reciprocal) | 50 | **50** | 18.7%, best measured |
| same target language (study buddy) | — (0) | **24** | 16.2%, new branch |
| their native is my learning | 20 | **16** | one-way, 12.6% |
| their learning is my native | 20 | **16** | one-way, 12.6% |

Ordering follows measured reply rate. Perfect stays dominant: everything else still sums
to well under 50, so a perfect partner with no bonuses outranks any partial maxed on
extras — the property the original weighting was built around.

**The two one-way directions stay equal at 16.** The measurement bucketed unordered pairs,
so it merged both directions and cannot justify splitting them. Stated rather than guessed.

### 3.3 VIP

Left as a decision rather than a silent one: `vipSubscription.isActive` is correctly wired
and simply has nothing to act on (0 subscribers ever). On the `sort=smart` path VIP becomes
a small additive bonus rather than the primary sort key, so the day someone finally
subscribes it nudges ranking instead of reordering the entire screen above language. The
legacy default sort keeps VIP-first, unchanged.

### 3.4 Impressions on the new path

`recordImpressions` runs for page 1 of a `sort=smart` response only. `/users` is called on
every scroll; logging every page would multiply the collection by the page count to answer
nothing extra. Page 1 is what "was this profile shown before they messaged" needs.

---

## 4. How we will know it worked

`MatchImpression` already stores per-signal scores. After this ships, the question the
collection can answer is whether a surfaced profile led to a conversation, per branch —
which is what would justify or overturn §3.2's numbers on real volume rather than on 2,800
historical pairs chosen by the old sort.

Success: the study-buddy branch converts at or above the one-way branch it outranks. If it
does not, the weights go back.

---

## 5. Explicitly not in this spec

- **Exposure fairness.** A nightly inbound-load field subtracted from the score, so the 39
  scarce natives rotate rather than all 370 seekers hitting the same few. This is the
  direct fix for §1.1 and §2.3 and it needs a job, a field and a backfill. Deferred
  deliberately: §3.2 is measurable on its own, and a reweight plus a fairness system
  shipping together could not be told apart.
- **Global daily appearance caps** (Redis counter on the request path).
- **Splitting the two one-way directions** — needs a directional measurement first.
- **Reducing language's overall weight.** "Unrelated" at 16.3% hints that language matters
  less than 50/24/16 implies, but that reading is the most exposed to selection bias and
  is not acted on here.

---

## 6. Risks

- **Selection bias.** Every reply rate in §1.2 is measured on pairs the *current* sort
  surfaced. One-way's 12.6% may partly reflect being over-shown rather than being bad. The
  fix for this is §4, not more analysis of the same data.
- **"Reply rate" is coarse** — both parties sent ≥1 message. It does not distinguish a
  real exchange from a single politeness reply. `msgs/pair` is reported alongside as a
  partial check.
- **Sort cost.** A computed sort cannot use an index; at 1,856 users this is free, but it
  is an in-memory sort with a 100MB ceiling and should be revisited well before ~50k.
- **Small cohorts.** chinese→japanese has 2 partners for 58 seekers. No weighting helps
  them; they will be served study buddies, which is the honest answer and the reason
  §3.2 adds that branch.
