# Monetization and VIP: measure the funnel, time the offers, load fast

Date: 2026-11-14. Project 3 of 5 (after moments/stories and community matching).
Repos: app `bananatalk_app/`, backend `be-integration`.

## 1. Why

Revenue is about zero and we cannot say why, because the paywall has never been measured.

Measured on production, 2026-11-14:

- 3,051 users; 656 active in 30 days, 241 in 7 days, 70 in 1 day. Of about 600 people seen in 30 days, 382 came on one day only and 46 came on 8 or more days.
- One VIP purchase ever (one day, 2026-10-18, a test account) and one coin purchase.
- `paywallevents` is empty because the app never calls `POST /purchases/paywall-event`. The only paywall analytics is a Firebase event from one sheet (`PersonaUpgradeSheet`). About 30 other entry points log nothing.
- Free limits rarely bite: 23 people hit the translation limit in 30 days; nobody hit the moments, tutor or stories limits on the sampled day.
- Surfaces with an audience: 97 weekly actives had 2+ profile visitors in 30 days; 66 people sent 5+ waves in a day (cap is off); 567 people saw daily matches.
- One account re-sends an expired VIP receipt on every launch (107 rejected attempts). `PurchaseAttempt.appVersion` is empty on every row.

Found in the code:

- There is no shared way to open the VIP screen or coin shop; each of about 30 call sites pushes the screen itself.
- The visitor paywall leaks: the `profile_visit` push gives free users the visitor's name, photo and a link to their profile.
- Waves received are always revealed. The `who_waved` coin unlock opens the visitor list only.
- A failed store product query at launch is cached as an empty list and never retried, so prices fall back to hardcoded USD.
- The VIP plans screen shows a full-screen spinner while products load.

At this size, changing prices or perks would not produce a readable result. The first job is a real funnel number per placement. The second is to stop showing offers at bad moments and show them at good ones, using what already exists.

## 2. Goals, non-goals, anti-goals

Goals:

1. Every paywall, limit dialog, unlock sheet, VIP screen and coin shop visit is recorded per placement, from first view to purchase result, and one script prints the funnel.
2. The server decides when an existing offer is shown on a small set of surfaces, with caps on how often, and learns which placements convert.
3. The VIP screen and coin shop paint at once with real prices when they are known; the expired-receipt retry stops.

Non-goals:

- No new screens, no new paywalls, no price or perk changes, no new store products.
- No change to waves received (they stay revealed), the wave cap switch, or the conversation cap switch.
- No release build, version bump or store submission.
- No web changes.

Anti-goals (these would make it a failure even if it works):

- A person in their first two days sees more upsell than today.
- Any offer logic delays or blocks sending a message, a wave, or opening a screen.
- Anything changes for the live app with the new switches off.

## 3. Constraints

- Three new server switches, all default off: `PAYWALL_EVENTS_ENABLED`, `OFFER_ENGINE_ENABLED`, `VISITOR_PUSH_MASK_ENABLED`. Each is exposed in app-config where the app needs it (`paywallEventsEnabled`, `offerEngineEnabled`).
- With every switch off, server responses are byte-identical to today, and the app sends no new request. Prove it with a switch-off identity test on the server, as in community matching.
- App refactors that run with switches off (the shared open helpers, section 4.2) must not change what the user sees or which route is pushed.
- New user-facing server error strings must avoid the substrings the app relabels (`limit`, `blocked`, `not found`, `unauthorized`, `401`).
- Do not touch reels playback files (`lib/pages/moments/reels/`, `lib/providers/reels_provider.dart`, `lib/services/reel_view_tracker.dart`).
- Every commit updates `docs/REMAINING_WORK.md` in its repo.

## 4. Part A: funnel measurement

### 4.1 Server

`PaywallEvent` grows, additively:

- `placement` gains: `wave_cap`, `extra_matches`, `moment_cap`, `comment_cap`, `story_cap`, `dm_cap`, `profile_view_cap`, `tutor_quota`, `study_lock`, `boost`, `nearby_radius`, `country_filter`, `vip_entry` (menus, pills, profile cards), `coin_entry` (balance pill, menu), `not_enough_coins`, `matches_empty`, `other`. The five existing values stay.
- `action` gains: `cta_vip`, `cta_coins`, `cta_ad`, `plans_viewed`, `shop_viewed`, `purchase_started`, `purchase_succeeded`, `purchase_failed`, `unlock_succeeded`. The three existing values stay.
- New optional fields: `flowId` (string, at most 40 chars, made by the app when an offer is first shown and carried through the VIP screen or coin shop to the purchase result), `detail` (string, at most 40: the call site or product id), `offerId` (set when the offer engine chose it), `platform`, `appVersion` (from the `X-App-Version` header), `clientAt`.
- Indexes: `{ placement: 1, action: 1, createdAt: 1 }` and `{ flowId: 1 }` (sparse). No TTL (the builder may add one of 400 days if the owner asks).

Endpoints:

- `POST /purchases/paywall-event` stays exactly as it is.
- New `POST /purchases/paywall-events` takes `{ events: [...] }`, at most 50 per call. With `PAYWALL_EVENTS_ENABLED` off it returns 404 like other guarded routes. Invalid items are dropped and counted in the response (`{ success, stored, dropped }`); one bad item never rejects the batch. Its own limiter: 30 calls per 15 minutes per user.

Also:

- `recordPurchaseAttempt` reads `appVersion` from the `X-App-Version` header when `clientInfo` is absent. This is a logging fix and needs no switch.
- `scripts/paywallFunnel.js [days]` prints, per placement: people shown, share who tapped each CTA, share who reached plans or shop, purchases started, succeeded, failed, and unlocks. It joins by `flowId`, and also prints a per-user view (people shown any paywall, people who bought). Read-only.

### 4.2 App

- One helper each: `openVipPlans(context, placement, {detail, flowId})` and `openCoinShop(context, placement, {...})`. Every existing call site moves to them and keeps its current route type and behaviour. A source-scan test fails if any file other than the helpers constructs `VipPlansScreen` or `CoinShopScreen` directly.
- `PaywallTracker`: `shown`, `dismissed`, `cta`, and the purchase and unlock results. Events queue in memory and flush every 10 seconds, when the app goes to the background, and at 20 queued. Sending is fire-and-forget; a failed flush drops the batch. Nothing is written to disk (my call: simpler, and losing a few events is acceptable).
- With `paywallEventsEnabled` off the tracker is a no-op: no queue, no timer, no request. The flag is read from the app-config the app already holds at the moment of each event, so a change takes effect on the next config refresh.
- Covered surfaces: every item in the survey list (limit dialogs, tutor and study sheets, translate sheets, masked tiles and visitor banner, extra matches, boost, remove ads, all VIP entry points, coin pill, not-enough-coins, VIP plans and payment screens, coin shop). `UnlockCta` reports coin and ad paths once, centrally.
- Dead upsell code found in the survey (`VisitorLimitDialog`, `VisitorUpgradeScreen`, `FeatureGate` dialogs, `VipPromoCard`, `VipLockBadge`, the unreachable chat limit screen, `DailyChatLimitService`) is deleted in its own commit, after a search confirms no caller.

## 5. Part B: offer timing

Today each surface decides alone, with no memory and no cap across surfaces. The engine adds one server decision for a small set of existing, passive upsell elements. It never creates a dialog; hard limits (a person hits a cap and asks for more) are not routed through it.

### 5.1 Engine-controlled surfaces (v1)

| Surface id | Existing widget | Placement | Extra trigger | Lead |
|---|---|---|---|---|
| `visitor_recall` | Visitor recall card (Partners tab) | `visitor_list` | 2+ distinct visitors since the person last opened the visitors screen (looking back at most 30 days) | `coins` when the balance covers `who_waved` (60), otherwise `vip` |
| `profile_banner` | VIP upsell banner on a partner's profile | `vip_entry` | none | `vip` |
| `moments_chip` | "Go VIP" chip in Moments | `vip_entry` | none | `vip` |
| `matches_empty` | Matches empty state (Boost / VIP buttons) | `matches_empty` | none (the widget only draws when today's cards are done) | `coins` when the balance covers a Boost (150), otherwise `vip` |

With `offerEngineEnabled` off, all four behave as today. With it on, each shows only when the engine has returned an offer for its surface. No answer yet, a failed request, or offline all mean hidden.

`lead` names the button the widget emphasises when it already has more than one; a widget with one button ignores it. There is no `ad` lead in v1: none of these four has a rewarded path.

"Last opened the visitors screen" is a new field, `User.visitorsSeenAt`, written when the owner loads their own visitors list. It is written only while `OFFER_ENGINE_ENABLED` is on, so nothing changes with the switch off.

### 5.2 Request

`GET /api/v1/offers` (authenticated; 404 with the switch off). The app calls it once per app open and again after a purchase or unlock, never more than once per 2 minutes, and never awaits it before drawing a screen.

Response: `{ offers: [{ id, surface, placement, lead }] }`, holding zero or one offer.

The request reserves the slot: the first call of a UTC day that finds an eligible surface records the choice in `offerstates` and counts it against the caps, seen or not. Later calls that day return the same offer (until a purchase or unlock ends it). This is deliberate: a lost `shown` event must never lead to showing more.

### 5.3 Rules (pure module `lib/offerEngine.js`)

Eligibility, all required:

- Not VIP (`tierOf`), not banned.
- Account older than 48 hours and active on 2 or more days (`UserActivityDay`).
- Not inside a quiet period (5.4).
- The surface's extra trigger holds.

Ranking when more than one surface is eligible: each surface has a smoothed conversion rate, `(converted + 0.02 × 20) / (shown + 20)`, where `shown` counts engine offers of that surface that were seen in the last 60 days and `converted` counts those whose flow reached `purchase_succeeded` or `unlock_succeeded`. The rate is multiplied by a fixed value weight for the lead (VIP 4, coins 1) and the highest wins; ties go in table order. Rates are recomputed nightly into one small document and held in memory. With the little data there is today the priors decide; the formula is there so the order follows evidence as it arrives.

### 5.4 Caps and state

New collection `offerstates`, one row per user: today's reserved offer, per surface `lastOfferedAt` and `ignored` (times seen without a tap), and a user-level `quietUntil`.

- At most one engine offer per person per UTC day, and the same surface at most once per 3 days.
- None of the four widgets has a close control and none is added. Instead: a surface seen 3 times in a row without a tap is quiet for 14 days; a tap resets the count.
- Any successful purchase or unlock by the person, whether or not it started from an engine offer, makes all engine offers quiet for 7 days.
- Seen and tapped come from the batch endpoint (`shown` and `cta_*` events carrying the `offerId`), so the engine needs `PAYWALL_EVENTS_ENABLED` on; with it off, `/offers` returns no offers. Purchases and unlocks are read from the server's own coin ledger (a coin purchase or spend in the last 7 days), which does not depend on the app reporting them; a new VIP is excluded anyway.
- The row is removed in the account delete cascade.

### 5.5 Visitor push for free users (separate switch)

With `VISITOR_PUSH_MASK_ENABLED` on, a free recipient's `profile_visit` push and its in-app history row carry no name, no photo and no visitor id; the text is the existing "someone viewed your profile" style string and the tap opens the visitors screen. VIP recipients and people inside a paid reveal window get today's push. Default off; this is an owner decision because it trades about 2,800 named pushes a month for a paywall that holds.

## 6. Part C: fast loading and the receipt bug

- **Prices on first paint.** The last store-localized price for each product is saved on the device (keyed by product id and storefront currency) whenever a product query succeeds. `VipPlansScreen` and the coin shop draw at once from memory, then from the saved prices, then from the hardcoded fallback, and update in place when the store answers. The full-screen spinner goes away; the buy button stays disabled until the store product is loaded, as now.
- **Retry a failed query.** An empty or failed product query is no longer kept as the answer: the next screen open (or the next launch) queries again, with at most one query in flight.
- **Expired receipt.** The launch redelivery path gets the same lapse check the manual restore path has, and remembers on disk which transaction ids the server rejected as expired, so each is sent at most once. The memory is per user and cleared on sign-out. A transaction the server has never seen is still sent.
- Not changed: when iOS finishes a transaction relative to the server answer. The survey found a possible plugin fault there, but it needs a device to confirm; it is listed as an open check, not built.

## 7. Rollout

1. Deploy the backend dark. Nothing changes.
2. Turn on `PAYWALL_EVENTS_ENABLED` once an app build with the tracker is in the store. Read `scripts/paywallFunnel.js 14` after two weeks.
3. Turn on `OFFER_ENGINE_ENABLED` after the funnel shows at least 200 `shown` events, so there is a before number.
4. `VISITOR_PUSH_MASK_ENABLED` and the existing `WAVE_CAP_ENABLED` are owner decisions to take with the funnel numbers in hand.

Success, 30 days after step 2: a conversion number exists for every placement with 50+ views; rejected "subscription expired" attempts fall to near zero; no rise in day-1 or day-7 drop-off against the 30 days before.

## 8. Left to the builder

- Exact call-site list for the helpers, and each site's placement and `detail` string.
- Storage key names, the tracker's file layout, test layout.
- Whether the nightly rate job reuses the existing scheduler slot pattern (expected: yes).

## 9. Calls I made (not the owner's decisions)

- Events are not persisted on the device.
- Waves received stay ungated.
- The engine controls four passive surfaces only; hard-limit dialogs are never suppressed.
- Asking for an offer uses up the day's slot even if the widget is never seen.
- No close buttons are added; three ignored views quiet a surface for 14 days.
- Caps are per surface, so the profile banner and the Moments chip each get a turn.
- Value weights 4 / 1 and the 2% prior are starting guesses.
- Dead upsell code is deleted rather than instrumented.
