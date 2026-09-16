# Monetization — Design

**Date:** 2026-09-15
**Status:** approved, ready for implementation planning
**Goal:** take the first payment. Revenue today is $0 across two fully-built systems.

---

## 1. The problem, measured

BananaTalk has a VIP subscription and a coin economy, both code-complete for months.
Neither has ever taken a payment:

- **VIP: 0 subscriptions, ever.**
- **Coins: 22 ledger entries, ever — all rewards.** 16 daily logins, 6 ad rewards.
  **Zero purchases.**

Three causes were considered and all three are live:

1. **Nobody can pay** — the purchase path has never completed end to end.
2. **Nothing is worth paying for** — VIP sells quantities nobody exhausts.
3. **Nobody sees a paywall** — few entry points, and no limit ever binds.

They multiply rather than add. Fixing any one alone still yields $0.

### 1.1 Cause 2 and 3 share a root: the limits never bind

Measured over 30 days against 796 active users:

| Limit | Free allowance | Actual usage | Headroom |
|---|---|---|---|
| Waves | 15/day | 0.016/user/day | ~940x |
| Moments | 10/day | 0.001/user/day | ~10,000x |
| Profile views | 100/day | 0.08/user/day | ~1,200x |

**No user has ever hit a wall, so no user has ever seen a paywall.** VIP's proposition
today is "unlimited quantities of things you never run out of", which is not a product.

### 1.2 Lowering the limits was considered and rejected

An early version of this design proposed lowering free limits so they bind. Measurement
killed it:

- **Waves: 376 events from exactly one user.** No demand to monetize.
- **Moments: 34 posts in 30 days, busiest user-day is 2.** A cap is unreachable.
- **Profile views: 1,964 events, 382 distinct users** — real traffic, but a 10/day cap
  would bind on only 34 user-days across 32 people.

At this scale **no quantity limit on these features produces meaningful revenue**, and
lowering them would annoy real users for nothing. The free tier keeps every allowance it
has today.

### 1.3 What IS scarce

Two signals carry real volume:

- **New conversations: 1,240 in 30 days**, median 2 per active initiator, p90 of 7.
  The healthiest number in the app.
- **Profile visits: 1,964 in 30 days across 382 distinct visitors.**

These are what the design monetizes.

---

## 2. Approach

Bundle value that already exists, fix the plumbing, instrument everything. No new
learning features. Small enough to ride the release already waiting on a signed build.

Rejected alternatives:

- **Build the correction loop first** (HelloTalk's real differentiator, which we lack).
  Right idea, wrong order: weeks before a single dollar, and it bets that corrections
  drive payment before we have proven anyone will pay for anything. This becomes the
  next project, funded by what we learn here.
- **Diagnose-only release.** Cleanest evidence, but spends a release cycle learning what
  this approach also learns while shipping value.

---

## 3. The offer

### 3.1 Free tier — nothing is taken away

Every current allowance is unchanged, plus:

| Capability | Free |
|---|---|
| Profile visitors | Count + most recent visitor; older ones shown blurred with names hidden |
| Chat translation | 5/day (pre-existing — see below) |
| **New conversations** | **3/day** (replies always unlimited) |
| Ads | On |
| Nearby radius | 50 km |

**CORRECTED 2026-09-16, during implementation.** This section originally specified a new
10/day translation cap. It was written without knowing that **a 5/day cap already exists
and is already enforced** — `test/coinBonus.enforcement.test.js:40` pins
`REGULAR_TRANSLATION_CAP = 5` as the free allowance a user consumes before the coinBonus
pool starts paying.

Raising 5 -> 10 would have *weakened* a paywall inside a monetization design, doubled the
AI translation cost we pay, and broken five passing tests to do it. **The existing 5/day
stands and needs no new code in either plan.**

That leaves exactly **one** new cap in this design: **new conversations**.

### 3.2 The new-conversation cap is the core mechanic

**Cap conversation STARTS. Never cap replies.**

A 3/day cap binds on 43% of active initiator-days, so the wall is real. Replies stay
unlimited to anyone, forever, so **every existing relationship is untouched**.

This monetizes *discovery* while protecting *relationships* — the thing that retains.
A user who has found someone to talk to never hits a wall.

Capping messages instead was rejected: HelloTalk can cap messages because a blocked
conversation is replaceable among millions of users. With 796 active users the blocked
conversation may be the only one that person has, and ~1/3 of signups are already lost
in the first hour.

### 3.2.1 Cap mechanics — precise definition

Four details a planner would otherwise have to guess:

- **Initiator only.** A conversation start consumes the quota of the user who sends the
  first message. The recipient's quota is untouched, so a popular user is never rate-limited
  by other people's interest in them.
- **Reset boundary: the user's local day**, not UTC. The daily pack uses a UTC `dateKey`
  because content is global; a personal quota that resets at 09:00 local time would feel
  arbitrary and punitive. This is a deliberate divergence from `lib/dailyCompletion.js`'s
  `toDateKey` and needs its own helper.
- **What counts as a "start":** the first message in a conversation with no prior messages
  between those two users. Re-opening a dormant conversation is a reply, not a start.
- **Ad credits expire at the same local-day boundary** and do not accumulate. Watching
  five ads at midnight does not bank five starts for the week.

### 3.2.2 Tiers

`config/limitations.js` has three tiers: `visitor`, `regular`, `vip`. This design's "free"
means **both `visitor` and `regular`** — they get the same caps. Splitting them would create
a middle tier nobody asked for and nobody can buy.

### 3.3 VIP

- **Full visitor list** — the primary draw
- **Unlimited new conversations**
- **Unlimited chat translation**
- **Priority in discovery** (`priorityInSearch` already exists; a weight in the existing
  matching score, not a new system)
- **No ads**
- **Nearby radius 500 km** (already built)

### 3.4 Rewarded ads

**Watch an ad -> +1 new conversation today.**

Today an ad grants coins nobody spends (6 rewards, 30 coins, 0 purchases). Tied to a
conversation start, the ad buys something people demonstrably want 1,240 times a month.
Coins remain for their existing a-la-carte unlocks; this design does not extend them.

---

## 4. Exposure

Five placements, each tied to a moment the user is already having:

1. **Visitor list** — "3 people viewed you this week", faces blurred. Primary paywall.
2. **New-conversation cap** — on the 4th start of the day. Two exits: watch an ad, or VIP.
3. **Chat translation cap** — at the 5th translation, mid-conversation, highest intent.
   (Already enforced today via the coinBonus path; only the paywall UI is new.)
4. **Ad removal** — offered from the ad itself, not a settings page.
5. **Nearby / discovery** — "appear higher to people learning your language", and the
   radius wall at 50 km.

### 4.1 Hard constraint: nothing in the first session

No paywall may be shown before day 2, or before the user has taken the action that makes
it meaningful (you cannot be shown the visitor wall until someone has actually visited
you).

~17% of signups delete their account within an hour of joining, median account age at
deletion 18 minutes. A paywall in front of someone still deciding whether to keep the app
converts nobody and confirms their suspicion. This costs short-term conversion
deliberately.

---

## 5. Plumbing

Google Play service-account credentials are confirmed present on prod by the owner.
Still unverified:

1. **Android SKUs exist in Play Console** — never confirmed.
   `com.bananatalk.app.vip.{monthly,quarterly,yearly}`,
   `com.bananatalk.app.coins.{100,500,1500}`.
2. **One successful sandbox purchase per platform, end to end** — buy, verify receipt,
   confirm VIP actually activates. This round trip has never been completed.

Note `lib/googlePlayReceipt.js` throws when credentials are absent — it fails closed,
which is right for security and fatal for revenue. Its behaviour should be covered by a
test so a future env change cannot silently reintroduce the failure.

---

## 6. Instrumentation

The reason $0 was ambiguous for months is that **a failed purchase leaves no trace**.

**Purchase attempt log.** Every attempt records: user, platform, product ID, outcome,
failure reason, app version. Written on both success and failure, at the verification
endpoint, so a client that never reaches the server is distinguishable from one whose
receipt was rejected.

**Paywall event log.** Which placement, shown or dismissed or converted. Without this,
"nobody sees a paywall" stays a hypothesis.

Both follow the pattern established by `securityEventContext` (2026-09-15): client
context attached at the call site, best-effort, never able to break the operation it
describes.

**The first queries to run after release:**
- purchase attempts grouped by outcome and platform
- paywall views by placement, and view -> conversion rate
- new-conversation cap hits, and the ad-vs-VIP split of how people get past it

---

## 7. Testing

- **Pure units:** cap arithmetic (is this the 4th start today?), ad-credit grant and
  expiry, paywall eligibility including the first-session rule.
- **Integration (mongodb-memory-server):** a conversation start at the cap is refused
  while a reply in an existing conversation is not — the single most important guarantee
  in this design.
- **Contract:** purchase-attempt log written on both success and failure paths.
- **Regression:** free allowances unchanged from today's `config/limitations.js` for every
  field this design does not name. A test that pins them, so "nothing is taken away"
  cannot quietly become false.

---

## 8. Out of scope

- The correction loop (next project)
- 모임 / community meetups (separate spec, same conversation)
- Study Hub information architecture (separate spec)
- Matching quality beyond the `priorityInSearch` weight. **Note:** a separate,
  already-identified bug — `controllers/matching.js` compares languages as exact strings
  and loses 2,342 of 4,259 true pairs (55%) — is queued as an immediate fix, not part of
  this design.
- Extending the coin economy

---

## 9. Open questions

1. **Price.** The app's fallback prices (14.99/19.99/49.99) and the backend's `/plans`
   (9.99/23.99/71.99) disagree; App Store Connect is authoritative and must be reconciled
   before launch.
2. **Ad inventory.** 6 ad rewards in the ledger suggests very low ad volume. If ads rarely
   fill, the "watch an ad" exit is not a real exit and the cap becomes VIP-or-nothing.
   Worth measuring fill rate before the cap ships.

3. **The data this paywall sells is already free, and that is unresolved.**
   *(Found by the whole-branch review, 2026-09-16.)* Every profile visit sends a
   `profile_visit` push carrying the visitor's **name** and photo, and `send()` persists it
   to notification history for every non-`chat_message` type. `GET /notifications/history`
   has no tier gate, and both notification preferences default to true. So a free user reads
   a complete, durable, unpaginated list of everyone who viewed them in their notification
   tab, while the paid visitor screen shows one.

   Pre-existing, and nothing in the backend branch closes it. **The primary paywall of this
   design is worth nothing until it is closed**, and closing it is a product decision rather
   than a bug fix: do we stop naming visitors in pushes? That costs a genuinely engaging
   notification — 2,808 profile-visit pushes in 30 days, the second-highest volume in the
   app — to protect a paywall that has earned nothing yet. **Decide before launch.**

4. **Rewarded ads are unverified.** `POST /purchases/ad-credit/conversation` takes no
   ad-network receipt — it trusts that the client calling it really watched an ad. Real proof
   needs server-side verification (SSV) from AdMob/AppLovin, which requires their callback
   contract. Until then the `AD_REWARD_DAILY_CAP` clamp (5/day) is the only thing bounding
   abuse.

   *(This was claimed as "recorded in the spec's open questions" during implementation and
   was not actually written here until the whole-branch review caught the omission. Noted
   because a known hole in a money path that lives only in a scratch ledger is a hole nobody
   finds again.)*

5. **An expired VIP keeps unlimited translation.** `models/User.js`'s `canTranslate` and
   `incrementTranslationCount` branch on `userMode === 'vip'` with no expiry check, unlike
   `isVIP()`, `getUserTier` and the new `tierOf`. Between a lapse and the expiry job running,
   a user is simultaneously downgraded (conversation cap binds, visitor list locks) and not
   (translation stays unlimited). Ten sibling occurrences of the pattern exist. Its own
   change, not this design's.

6. **The `translation_cap` placement can never fire.** It is a valid `PaywallEvent`
   placement, but nothing emits a "you hit the translation wall" signal — translation
   enforcement lives entirely in the coinBonus free-then-pool path. That metric will read
   zero views forever, and zero must not be misread as "nobody hits that wall."

7. **`lib/googlePlayReceipt.js`'s fail-closed behaviour is still untested.** §5 asks for a
   test so a future env change cannot silently reintroduce the failure that plausibly caused
   the original $0. No such test exists. It is the cheapest item in this spec and it guards
   the most expensive failure mode.
