# Reels Ranking & Instrumentation — Design

**Date:** 2026-09-17
**Status:** approved, ready for implementation planning
**Goal:** make the reels feed surface the best language-relevant content a viewer has
not already seen, and record enough to know whether it worked.

---

## 1. The problem

### 1.1 Ranking runs after the window is chosen

`controllers/moments.js:getReelsFeed`:

```js
const rawWindow = await Moment.find(query)
  .sort({ createdAt: -1 })
  .limit(limit)          // default 10
  .lean();

const ordered = partitionByLanguage(rawWindow, relevantLanguages);
```

The query takes the **newest `limit` moments**, then partitions them by language. The
only ordering that exists runs on a window already fixed by recency.

The consequence: **nothing outside the ten most recent posts can appear, at any
quality.** A reel posted last week that every viewer watched to the end is unreachable
the moment ten newer posts exist. "Improving the algorithm" cannot fix this, because the
algorithm is downstream of the decision that loses the content.

### 1.2 Nothing records that a reel was watched

`models/Moment.js` carries `likeCount`, `commentCount`, `saveCount` and `shareCount`.
There is no `viewCount`, no watch time, and no per-viewer record. The app does not track
one either — `reels_feed_screen.dart` has no view, watch or analytics call.

Every metric worth ranking short video on is a **rate**: completion rate, likes per view.
Without a denominator none of them can be computed, and `likeCount` alone ranks by age,
since an older post has had longer to collect likes.

`Story` already has `viewCount`. Moments and reels have nothing.

This is the same wall the matching work hit — *"no change to the algorithm can be
evaluated"* — and that spec fixed instrumentation before touching weights. The same order
applies here.

---

## 2. Decisions

| Question | Decision |
|---|---|
| What the feed optimises for | Language-relevant pool; engagement ranks **within** it |
| Follow graph | Boost, weight 15 |
| Already-seen content | Suppress hard (−60), never exclude |
| New posts | Temporary grace so they can gather signal |
| Level proximity | Included, via an explicit **proxy** (§5) |
| What counts as a view | 1 second rendered |

### 2.1 Why language gates the pool rather than scoring inside it

A reel in a language the viewer cannot read is one they scroll past. That registers as
low completion, which reads as "bad content" when it is really "wrong audience" — and
the poster is punished for it. Gating the pool keeps every completion rate in the ranking
comparable, because everyone scoring it could understand it.

It also protects the product: this is a language-exchange app, and a feed of
unintelligible viral video is a worse outcome than a quieter comprehensible one.

---

## 3. Instrumentation

### 3.1 `MomentView`

```js
{
  viewer:    ObjectId,  // indexed with moment
  moment:    ObjectId,
  watchedMs: Number,
  completed: Boolean,
  createdAt: Date,      // TTL 30 days
}
```

**A 30-day TTL, not forever.** At roughly 1,813 active users scrolling ~50 reels a day
this is ~90k rows a day. Ranking only reads the last 7 days (seen-suppression) and
aggregate counters carry the rest, so older rows have no reader and would only cost
storage and index time.

### 3.2 Counters on `Moment`

`viewCount` and `completionCount`, incremented on write. Never recomputed by scanning
`MomentView` — that scan is exactly what the TTL makes impossible, and a counter that
depends on data being deleted is a counter that silently resets.

### 3.3 A view is one second, not an impression

Counting a view when the card renders would include every reel scrolled past before the
video decoded. Those are not views; including them deflates every rate uniformly and
makes good and bad content converge.

`completed` means **≥90% of duration watched**, or **≥15 seconds** for anything longer,
so a two-minute reel is not called incomplete by someone who watched a long time.

### 3.4 Batched, not per-reel

The app accumulates events and flushes on pause, background, or every 10 events. A scroll
session becomes one request rather than fifty. A dropped batch loses signal and nothing
else; it must never block or slow scrolling.

---

## 4. Ranking

A new pure module `lib/reelsRanking.js`, in the same shape as `lib/matchLanguage.js`,
`lib/matchIntent.js` and `lib/gatheringFilters.js`: no I/O, so the rule that decides what
a learner sees is table-testable.

### 4.1 The pool

Language-relevant (viewer's target **or** native language), last 30 days, not blocked,
not the viewer's own. Roughly 200 candidates, then scored.

The pool is fetched by recency **as a bound, not as an order** — the newest 200 rather
than the newest 10. Everything inside it competes on merit.

### 4.2 Weights

| Signal | Weight | Reasoning |
|---|---|---|
| `completionRate` | 40 | The dominant quality signal in short video |
| `likesPerView` | 15 | A rate. A raw count ranks by age. |
| `recency` | 20 | Exponential decay, ~48h half-life |
| `followsAuthor` | 15 | Makes following mean something and gives creators a reason to build an audience |
| `levelProximity` | 8 | Deliberately small — it is a proxy (§5) |
| `newPostGrace` | +25 | `<20 views` and `<24h` |
| `seenRecently` | −60 | Seen in the last 7 days |

### 4.3 Why new posts need a grace period

Ranking on engagement rate is self-reinforcing: a post with no views has no rate, scores
zero, is never shown, and so never gets a rate. The grace period is the only thing that
breaks that loop. Without it the feed converges on whatever was already popular and no
new creator ever surfaces — which is the opposite of the adoption this work is for.

### 4.4 Why seen content sinks rather than disappears

With a small catalogue, excluding everything already seen empties the feed within days.
−60 sinks a seen reel below any reasonable unseen one, and surfaces it again only when
there is genuinely nothing better — which is the honest answer at that point.

### 4.5 Pagination

By **score cursor**, not `createdAt`. Paging a scored feed by time interleaves pages
incoherently: page 2 would contain older-but-higher-scoring posts that should have
appeared on page 1.

---

## 5. Level proximity is a proxy, and the spec says so

`Moment` has no difficulty field and this spec does not add one. What it uses instead:
the **author's relationship to the language they posted in**.

- Author's `native_language` matches the post language → native-speed content, harder.
- Author is a learner of it → difficulty approximated by their `languageLevel`.

Both fields already exist on `User`. This is an approximation, not a measurement, which
is why its weight is 8 — enough to break a tie between otherwise equal posts, never
enough to bury a good one. A real difficulty signal would need authoring or inference and
deserves its own spec.

---

## 6. Components

| Unit | Purpose | Depends on |
|---|---|---|
| `lib/reelsRanking.js` | score one candidate; sort a pool | nothing |
| `models/MomentView.js` | the view row, with its TTL | — |
| `controllers/moments.js` | build the pool, rank it, page it | `reelsRanking` |
| `controllers/momentViews.js` | accept a batch of view events | — |
| `models/Moment.js` | `viewCount`, `completionCount` | — |
| app: `reels_feed_screen.dart` | accumulate and flush view events | — |

---

## 7. Testing

| Property | Where |
|---|---|
| Each signal moves the score in the right direction, in isolation | `reelsRanking` table tests |
| **A viewer with no history gets a sane feed** | `reelsRanking` table test |
| A zero-view post is liftable into the pool by the grace period | `reelsRanking` table test |
| A seen post sinks but is still returned when nothing else exists | `reelsRanking` table test |
| `likesPerView` does not divide by zero on a fresh post | `reelsRanking` table test |
| A view under 1s is not counted | view-batch controller test |
| Counters increment once per event, not per batch retry | view-batch controller test |

The cold-start test matters most: every user is in that state on the day this ships, and
a ranking that only works for someone with history would degrade the feed for everyone at
the moment of release.

---

## 8. Explicitly not in this spec

- **The Instagram-like UI** for moments, stories and reels. Independent of this work and
  specced separately.
- **A real difficulty signal** for moments (§5).
- **Reweighting after launch.** The weights here are a starting position; the view rows
  are what make the first revision evidence-based rather than another guess.
- **Ranking the moments feed or stories.** Reels only. `getMoments` keeps its current
  behaviour.

---

## 9. Risk

The failure mode is the cold start, twice over. On day one no `MomentView` row exists, so
`completionRate` and `likesPerView` are zero for every candidate and the feed falls back
to recency, follows and the grace period. That is acceptable and roughly matches today's
behaviour — but it must be *deliberate*, not an accident discovered in production, which
is why §7 tests it.

The second risk is that batched view events are lost on a crash and rates read low across
the board. Rates are comparative, so uniform loss is survivable; biased loss is not. The
flush therefore triggers on pause and background, not on a timer alone, so the common
path — a user leaving the app — is captured.
