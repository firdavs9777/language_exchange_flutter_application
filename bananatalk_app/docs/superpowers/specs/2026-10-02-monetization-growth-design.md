# Monetization & Growth: Retention First, Monetize the Retained

**Date:** 2026-10-02
**Status:** Approved design (brainstorm B), pending implementation plan
**Repos:** backend (`language_exchange_backend_application`) + app (`bananatalk_app`)
**Builds on:** `2026-10-01-matching-redesign-design.md` (shipped dark, flags off)

## Goal and the honest math

**Goal:** ≥1,000,000 KRW/month (~$700) within ~6 months, led by **ads + coins**,
with VIP as a supporting "remove ads + discovery perks" tier.

**Measured 2026-10-02 (prod):**
- Revenue to date: **$0.** Live store build 2.2.4 (Play 2.2.5) has no reachable
  purchase funnel: `PaywallEvent` 0 ever, `PurchaseAttempt` 0 ever, coin
  transactions are 100% free rewards, the one "active VIP" is a manual grant.
- Users: 2,189 total; **707 new signups / 30 days (~23/day, organic)**;
  MAU 765, WAU 229, DAU 53.
- **Retention is the disease:** of 675 signups aged 8–37 days, 15% returned
  after day 1 and 7% were still active after day 7. 85% leave on day one.
- Market: China 227 MAU, then Russia/Nigeria/India/Morocco/Egypt; natives
  zh 208, ar 63, en 83, ru 43. iOS-dominant (241 iOS vs 25 Android push tokens).
  Low-ARPU geography.
- Premium AI features are unused (~13 tutor users/day, 38 translations/month):
  VIP-as-unlimited-AI has no demand to gate.
- Store: 0 ratings, no review prompt, listing EN-only.
- Ads: real AdMob units in release builds (`lib/services/ad_service.dart`);
  payout unknown (read from AdMob dashboard; recorded in the weekly dashboard
  once available).
- Costs: ~100,000 KRW/month.

**Math:** $700/month over the current base is ~$0.90 ARPU/MAU — unreachable at
765 MAU. Ads in these markets yield ~$0.05–0.15/MAU; coins need ~2–3% of MAU
paying ~$3; VIP ~1% at ~$4. **The goal requires ~3,000–3,500 MAU AND D7
retention ≥20%.** Signups already support it: 707/month compounds to 3,000+
MAU within 4–5 months if D7 goes from 7% to ~25%. Therefore: **retention
first; monetization built to earn from the retained; paid acquisition only
after D7 ≥ 20%.**

**The one scoreboard** (weekly, scripted): signups · D1 · D7 · conversation
survival (10+ msgs in 48h) · MAU · AdMob $ · coin buyers · VIP subs · store
conversion. Baselines: D1 15%, D7 7%, survival 0.0%, MAU 765, $0.

## Decisions (from brainstorming)

- Lead model: **ads + coins**; VIP supports. Conversation cap stays **off**
  until D7 ≥ 20%.
- **Profile Boost** is the #1 coin sink. **Moment Boost is deferred** until the
  content phase gives moments an audience (boosting into an empty feed feels
  like a scam, and the first purchase that feels like a scam is the last one).
- No paid installs before D7 ≥ 20%. Budget before that goes to ASO,
  localized listings, and reactivating the existing base.
- Three releases, each backend-first and dark: **2.4.0** (ship what's built),
  **2.5.0** (retention wave), **2.6.0** (monetization layer).

## Production-safety invariants (inherited) — and the live-build guarantee

Additive on the wire; every new money/retention surface behind its own
server flag with a default of off; old builds unaffected by backend deploys;
rollback = flag flip. Money paths are atomic and idempotent (the existing
coin ledger contract).

**Hard rule for this whole program: the app users have installed today
(2.2.4 iOS / 2.2.5 Android) must behave identically before and after every
backend deploy in this plan.** Concretely:

| Change | Effect on 2.2.4/2.2.5 users | Why none |
|---|---|---|
| Welcome wave | They may *receive* one as a normal 👋 (if they signed up on the old build) or *send* one as a normal mutual opportunity | It travels the existing wave path; old builds render it as any wave |
| Lifecycle push/email | They may receive it; a tap opens the app home | Old builds ignore unknown deep links; content is a normal notification |
| Referrals, boosts, new coin sinks, rewarded unlocks | Invisible | New endpoints only; nothing existing changes shape |
| Who-waved/visited reveal gating | **None** — old builds keep today's unmasked lists | Masking applies only when the client sends `?reveal=1` (new builds) |
| VIP reprice | They see the new store price on the VIP screen | Store-side price; purchase flow unchanged |
| `SMART_SORT_ENABLED` | **The ONE flag that changes old-build behavior** (their "All" list default order, with the known page-2 duplicate quirk) | Therefore it stays **off until 2.4.0 has majority adoption** — it is NOT flipped at 2.4.0 release time |
| `CONVERSATION_CAP_ENABLED` | Would block sends in old builds with no explanation | Stays off for the whole program |

Any task whose change cannot be made invisible to the live build is out of
scope for this program by definition; the reviewer rejects it.

## Release 1 — 2.4.0: ship what's built (no new product work)

- Server flags on at release: `DAILY_MATCHES_ENABLED=true`,
  `MATCHES_LAYOUT_ENABLED=true`, `SMART_SORT_ENABLED=true` (the loadMore
  pagination fix ships in this build). `CONVERSATION_CAP_ENABLED` stays false.
- Reconcile the app's hardcoded VIP fallback prices to the Release-3 prices
  (store price wins once loaded, but the fallback is what renders for the
  first second).
- Fix the ledgered copy nits from the matching spec ("refreshes at midnight"
  → derived from `nextRefreshAt` in local time; `segmentSeriousHint` no
  longer promises "replies to messages").
- Sandbox device smoke of the money path, which has never run end to end:
  buy coins → balance → hit a limit → unlock → debit → replay the receipt →
  no double credit.

## Release 2 — 2.5.0: the retention wave

**Target:** D1 15% → 30%, D7 7% → 20% within ~8 weeks of 2.4.0.
**Diagnosis:** nothing happens to a new user. Fix: make something happen in
the first five minutes, then pull them back with a *person*, not a nag.

### 2a. First session = first conversation (app)
- After profile completion, land on **Matches** with today's batch loaded
  (deterministic endpoint; no extra cost), not on a feed or list.
- Opener chips + stall rescue (already built) carry the chat.

### 2b. Welcome wave (backend, flag `WELCOME_WAVE_ENABLED`)
On profile completion, the server sends the new user **one real inbound
wave** from an active, responsive, relevant user:
- Candidate = top of the new user's daily-batch pool (reciprocal pair first)
  with `responseRate ≥ 0.5` (or null with `lastActive` today), excluding
  anyone who has received a welcome-wave duty in the last 24h, capped at **2
  duties per user per day** and **1 welcome wave per new user ever**.
- Delivered through the existing `sendWave` path (mirrors a 👋 into chat,
  one-wave-per-pair rule, push via `notificationService.sendWave`), with a
  `source: 'welcome'` marker on the `Wave` document.
- The waver is told nothing special; from their side it is a normal mutual
  opportunity. No fake accounts, no bots: if no candidate qualifies, no wave
  is sent.

### 2c. Pull-back loop (backend, flag `LIFECYCLE_PUSH_ENABLED`)
- Day 1 / 3 / 7 after signup, push + email (8-language catalogs exist), each
  carrying a specific person or count: "Your 6 matches for today are ready"
  (day 1), "{name} ({native}, learning {target}) is online now" (day 3),
  "You have {n} new waves" (day 7). Skipped for users active that day.
  Implemented as one scheduler job (`jobs/lifecycleJob.js`) reusing
  `fcmService.sendToUser` + `emailTemplateService`; dedup via a
  `lifecycleSent` map on the user.
- FCM permission timing (app): request notification permission **after the
  first wave or match arrives**, not at launch. Verify token capture at
  signup in the release smoke; token coverage is the ceiling on everything.

### 2d. Growth hygiene (app + backend)
- **In-app review prompt** (`in_app_review`) after the first conversation
  with ≥3 messages each way; at most once per 60 days; never on an error path.
- **Referral loop:** invite link (`banatalk.com/i/<code>`) → friend
  completes a profile → both get coins (inviter 100, invitee 50). Reuses the
  coin ledger (`credit` type `reward`, reason `referral`), one credit per
  invitee ever, idempotent on the invitee id. Entry point in profile menu.

**Deliberately not here:** streak gamification, an onboarding wizard rework,
content feeds. None put a human in front of the user on minute three.

## Release 3 — 2.6.0: the monetization layer

Rule: **ask for money at the moment of want, never as a wall.**

### 3a. Ads (flag `REWARDED_LIMITS_ENABLED` for the new placements)
- Banners stay where they are (moments, learning). **None in chat or Matches**
  — retention surfaces.
- **Rewarded ads at every limit moment** ("watch an ad → +1 wave / +3
  translations / +1 extra match"): generalize the existing `ad_reward` coin
  path into a `rewardedUnlock(feature)` that credits exactly the unlock cost
  and immediately spends it, so the user experiences the coin sinks for free
  first.
- **One interstitial per session** at a natural break (after the daily batch
  is exhausted, or leaving a finished chat), frequency-capped to 1/session
  for free users; VIP ad-free.

### 3b. Coins — sinks ranked by pull (packs already approved: $0.99/$3.99/$9.99)
1. **Profile Boost** — the #1 sink (3c).
2. **Extra daily matches** (+3 today): 40 coins.
3. **See who waved/viewed you** (24h reveal): 60 coins. `ProfileVisit` and
   `Wave` already record it.
4. Extra waves (10), translations (10), existing AI unlocks (keep prices).
Every sink is one atomic `debit` with a `reason` and `relatedId`; refunds are
`credit` with `reason: 'refund:<original>'`.

### 3c. Profile Boost (flag `BOOSTS_ENABLED`)
- **150 coins (~$1.49) for 24h.** Two placements: a guaranteed slot in the
  daily batch of users the booster is *relevant* to (reciprocal/same-target
  first — relevance still gates, boost wins ties and reaches further down the
  pool), plus pinned to the top of Partners.
- **Fairness caps:** max **1 boosted card per daily batch** (slots 1–5 stay
  merit-ranked); boosted cards show a small "Boosted" chip; `responseRate`
  still applies (a ghost who boosts still sinks).
- **Capacity:** ≤10 active boosts per 1,000 MAU; when sold out the shop says
  "come back tomorrow."
- **Receipt:** on expiry the booster gets "you were shown to N people" (count
  of batches/lists the boost appeared in) — the thing that makes them buy
  again.
- Model: `Boost { user, kind:'profile', startsAt, endsAt, impressions,
  coinsSpent, status }`; `getDailyMatches` reserves slot 6 for the
  highest-relevance active boost not already in the batch; `getUsers` pins
  active boosts first when `sort=smart`.
- **Moment Boost: deferred.** Model's `kind` enum reserves `'moment'`; no UI.

### 3d. VIP — repriced and repurposed
- **Monthly ~$3.99 / yearly ~$24.99** (store-localized; set in App Store
  Connect / Play Console). The quarterly SKU is retired from the UI (kept in
  `storeProducts.js` for existing receipts).
- Perks: **ad-free, unlimited daily matches, who-viewed/waved always on,
  unlimited waves, Serious-learners + reciprocal filters.** Unlimited AI stays
  included but is not the pitch.
- Entry points: the ad itself ("remove ads"), the who-viewed-me teaser, a soft
  VIP chip on the Matches empty state. **No launch-time paywall.**

### 3e. Revenue model (honest)
At 2,500 MAU with D7 ≈ 20%: ads ≈ $150–300, coins ≈ $175 (2% × $3.50), VIP ≈
$100 (1% × $3.99) → **~$450–575/month.** The goal needs ~3,500 MAU; that is
Section 4's job.

## Section 4 — Marketing plan (10 hrs/week, 100–300k KRW/month)

**Principle:** spend zero on installs until D7 ≥ 20%. Until then every won
goes to converting the free installs already arriving (707/month).

- **Weeks 1–2 (≈10h/wk, ~0 KRW):** ship 2.4.0; localize store listings to
  **zh-Hans, ar, ru** (Claude drafts copy; user pastes); screenshots from the
  new Matches UI; launch campaign to the existing 2,189 users via push (34%)
  + email (8 languages): "Daily Matches is here — 6 people chosen for you
  every day." Keep the "Learn, Meet or Date" positioning that drives organic.
- **Weeks 3–6 (≈5h/wk):** review prompt live (target 50+ ratings in a month);
  one short-form content post per week (match-of-the-week / language tip),
  also posted as an in-app reel; email re-engagement to ~1,400 inactive users
  with their daily-batch preview.
- **Weeks 7+ (100–300k KRW/mo, gated on D7 ≥ 20%):** Apple Search Ads on
  language-pair keywords in zh/ar/ru storefronts, start 100k KRW/mo, scale
  only if CPI × D7 clears ~$0.90 ARPU. No Meta/TikTok paid until Search Ads
  pays back; no influencers before 3 months of retention data.
- **Weekly dashboard script** (`scripts/growthDashboard.js`): the nine
  numbers above, one line each.

## Section 5 — Flags, rollout, kill switches

| Flag | Default | Guards |
|---|---|---|
| `WELCOME_WAVE_ENABLED` | false | 2b |
| `LIFECYCLE_PUSH_ENABLED` | false | 2c |
| `REFERRALS_ENABLED` | false | 2d referral |
| `REWARDED_LIMITS_ENABLED` | false | 3a rewarded unlocks + interstitial |
| `BOOSTS_ENABLED` | false | 3c |
| `CONVERSATION_CAP_ENABLED` | false | stays off until D7 ≥ 20% |

Order: 2.4.0 release (flags on) → backend of 2.5.0 dark → 2.5.0 release →
flags on → backend of 2.6.0 dark → 2.6.0 release → flags on. VIP pricing is
store-side (instant rollback in App Store Connect / Play Console).

## Out of scope (parked with seams)

Moment boost; conversation cap activation; who-viewed-me as a VIP-only
surface (it ships as a coin sink first); AI-feature pricing changes; content
phase (moments/reels/stories) — separate spec; Android-specific marketing
(base is iOS-dominant).
