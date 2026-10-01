# Matching Redesign: Daily Matches + Community Reorganization

**Date:** 2026-10-01
**Status:** Approved design, pending implementation plan
**Repos:** backend (`language_exchange_backend_application`) + app (`bananatalk_app`)

## Why

Measured on prod 2026-10-01:

- 760 MAU / 211 WAU. **88% of monthly actives follow nobody** (avg 0.5 follows),
  so every follow-gated surface (Following feed, stories feed) is empty for
  nearly everyone.
- 522 new conversations per week but only ~1,590 messages — **~3 messages per
  conversation**. Conversations start and immediately die. Only 95 distinct
  people sent any message last week.
- Content creation is near zero (16 moments, 6 stories, 0 reels last week), so
  feeds cannot carry engagement. The engine of a language-exchange app is the
  partner conversation, and that is what is broken.
- The matching machinery already built (`lib/matchScoring.js`,
  `GET /matching/recommendations` with Redis caching, match reasons and
  `MatchImpression` rows) is **off by default** (`SMART_SORT_ENABLED=false`)
  and reachable only through the Community overflow menu.

**Success metric (the only one):** share of new conversations that reach 10+
messages within 48h of starting. Computable directly from the `messages`
collection; baseline is the ~3-message median above.

**Decisions made during brainstorming:** matching before content surfaces
(content design follows in a separate spec once the graph is alive);
everything free now with clean seams to VIP-gate later; Community tab may be
restructured — but only additively on the wire, dark-launched, because the
app is in production.

## Production-safety invariants (apply to every item below)

1. **No existing endpoint, parameter or response field is removed or
   renamed.** Old builds keep working against the new backend indefinitely.
2. **All new UI ships dark** behind an app-config flag (same mechanism as
   `smartSortEnabled` / `showRoomsTab`), so rollback is a server-side flag
   flip, never an app release.
3. Rollout order: backend (invisible to old builds) → app release with the
   new layout dark → flag on → watch the metric → flag off instantly if
   anything regresses.

## Visual reference

Approved mockups (4 phone screens: Matches tab, Partners + segment chips,
new-chat opener chips, stall-rescue banner):
https://claude.ai/artifact/XFL4pbeWV9mdJmxRwSsXb5

Design tokens from the approved mocks: accent `#FFD23F` (banana yellow,
primary action), ink `#1C1B17`, surface chips `#F5F2E8`, reason-chip tint
`#FDF4D7` on `#8A6D1A` text, success green `#3F9C58`/`#EAF7EE`, muted text
`#8A8577`, hairlines `#E9E4D6`. Cards 16px radius, chips pill-shaped,
touch targets ≥44px, last-active always bucketed text, never timestamps.

## 1. Community information architecture (new builds only)

New tab bar, gated by app-config flag `communityMatchesLayout`:

```
Matches · Partners · Gatherings · Rooms · Nearby · Topics · Waves
```

| Today | Disposition |
|---|---|
| *(new)* **Matches** | New default tab: the daily batch (§2–3). The overflow-menu "Find partners" screen (`SmartMatchingScreen`) retires in the new layout; its function is superseded. |
| All | Renamed **Partners**. Keeps everything; gains the segment chips and working filters (§4). |
| Gender | **Removed as a tab** (it fires one request per gender to exist; gender is already a filter-sheet control). Endpoint untouched. |
| Gatherings / Voice Rooms | Kept as-is, same flags. Out of scope beyond placement. |
| Rooms | Kept as-is, same `roomsEnabled` flag and index remapping. |
| Nearby | Kept as-is (got the `USABLE_PROFILE` fix 2026-10-01). Same-city filtering is a later wave. |
| City | **Removed as a tab** (it filters by country despite the name, with one count request per country pin; country filtering lives in the filter sheet). Endpoint untouched. |
| Topics | Kept as-is. Shared topics remain a matching signal. |
| Waves | Kept, last position — the inbound-interest inbox. Unread badge unchanged. |

HelloTalk-inspired segments live as **chips inside Partners**, not tabs
(chips compose with the filter sheet; tabs don't): `All · Serious learners ·
New members`, next to the existing Online / Recently active / Speaks X /
Learning Y chips. "Paid Practice" (HelloTalk's tutor marketplace) is
explicitly out of scope — no tutor supply exists.

## 2. Daily Matches engine (backend)

**One new endpoint:** `GET /api/v1/matching/daily` (protected, kill-switched
by `DAILY_MATCHES_ENABLED`).

```json
{
  "success": true,
  "date": "2026-10-01",
  "matches": [
    {
      "user": { "<existing card projection: USER_LIST_FIELDS>" },
      "matchReasons": ["reciprocal_pair", "shared_topic:travel", "active_today"],
      "reciprocal": true,
      "lastActiveBucket": "today",
      "responseRate": 0.8
    }
  ],
  "nextRefreshAt": "2026-10-02T00:00:00+09:00"
}
```

- **On-demand generation, no cron.** First request of the user's day computes
  the batch; result cached (Redis, keyed `user:date`) so the batch is stable
  all day. Selection is seeded by `(userId, date)` — the same determinism
  trick `getUsers`' smart sort already uses. Users who don't open the app
  cost nothing.
- **Ranking = `lib/matchScoring.js` unchanged.** Reciprocal pairs (the +50
  tier) first, then same-target, then one-way.
- **Batch rules:** size 5–8; exclude users messaged in the last 14 days
  (logic exists in `/recommendations`); exclude users shown in a daily batch
  in the last 7 days (via `MatchImpression`); require `USABLE_PROFILE` + at
  least one photo (exists). When the reciprocal pool runs dry (it will for
  rare pairs), backfill from the same-target tier and let the reason chips
  say so honestly.
- **`matchReasons` are structured keys with params**, not prose
  (`shared_topic:travel`), so the client renders localized text and opener
  templates from them.
- **Skip/impression:** the app records skips through the existing
  `InteractionService`; impressions are written server-side on batch
  generation (the `MatchImpression` table finally gets a real job).
- **Who-viewed-me:** the existing profile-visit recording keeps running;
  surfacing it is a later VIP wave. Nothing to build now.

## 3. Matches tab + conversation companion (app)

**Matches tab:** a vertical list of today's cards — deliberately not a swipe
deck (rejection mechanics burn a 5–8 card pool instantly). Card = existing
`community_card.dart` elements (photo, name, flag, language-exchange pill,
VIP badge) plus:

- **Last-active line** from `lastActiveBucket` ("active today"). Buckets only
  — the server never exposes precise timestamps.
- **Match-reason chips** rendered from `matchReasons`.
- Actions: **👋 Wave** (existing flow) and **Say hi** → opens `ChatScreen`
  with opener chips ready. **Skip** is small and understated; it records the
  interaction.
- Exhausted batch → empty state: "That's everyone for today — fresh matches
  tomorrow", with a secondary button to Partners. Scarcity is the ritual; no
  spillover.

**Conversation companion** (all client-side, works for match-initiated and
organic chats):

1. **Opener chips:** in any chat with zero messages, 2–3 chips above the
   composer, rendered from the two profiles' overlap via localized templates.
   Tapping fills the composer **editable** — never auto-sends.
2. **Stall rescue:** computed when a chat opens — if the thread has ≤5
   messages, the last message is the other person's, and >24h have passed,
   show one banner with a topic suggestion. At most once per conversation
   (local flag). No server component.
3. **Response rate:** a nightly backend job computes, per user, the share of
   received first-messages answered within 48h (trailing 30 days; only
   exposed once ≥3 samples). The list payload starts sending `responseRate` —
   the app's "Replies fast" tag has been dead code waiting for this field.
   It also feeds ranking so ghosts sink.

## 4. Foundation fixes (backend, mostly invisible)

- `SMART_SORT_ENABLED=true` (ranked order becomes the Partners default; the
  app already requests `sort=smart` when app-config allows).
- New `GET /auth/users` params (additive): `reciprocal=true` (speaks-my-target
  AND learns-my-native — today's `matchLanguage` is OR-only),
  `activeWithin=7d` ("Serious learners" with profile-quality conditions),
  `joinedWithin=7d` ("New members" — replaces the client-side page-by-page
  fake). All three also honored by `/auth/users/count` so the filter-sheet
  count matches the list (the existing topics/count mismatch gets fixed the
  same way).
- Indexes: `createdAt`, `profileCompleted` (both missing today; the default
  sort's leading key `vipSubscription.isActive` is also unindexed — add it).
- `lastSeenAt` bucket field added to the list payload (additive).
- Fix carried from the audit, already shipped: smart-sort `loadMore`
  pagination (app `bbd583e0`), age filter, limit cap, `USABLE_PROFILE`.

## 5. Flags, rollout, metric, testing

- **Flags:** `communityMatchesLayout` (app-config; new layout per build),
  `DAILY_MATCHES_ENABLED` (backend kill switch for the endpoint).
- **Rollout:** backend deploy → verify old-build behavior byte-stable →
  app release (layout dark) → enable for all → watch.
- **Metric query** (runnable ad hoc, no analytics infra): conversations
  created in window W where the message count within 48h of creation ≥ 10,
  over all conversations created in W. Baseline captured before flag-on.
- **Testing:** node:test coverage for the daily endpoint (batch rules,
  determinism, exclusions, kill switch), the new list params, and the
  response-rate job; Flutter widget tests for the match card, segment chips,
  opener chips and stall banner; the Dart↔payload contract is asserted the
  same way this week's audit tests do it.

## Explicitly out of scope (parked with seams)

Daily push notification; AI-generated openers (VIP seam over the same
`matchReasons`); who-viewed-me UI (VIP); server-pushed stall nudges;
same-city filter + City tab revival; Paid Practice / tutor marketplace;
any bottom-nav change; moments/reels/stories redesign (separate spec, after
this ships and the graph has a pulse).
