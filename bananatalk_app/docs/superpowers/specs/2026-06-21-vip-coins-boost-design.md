# VIP coins + profile boost — design spec

**Date**: 2026-06-21
**Status**: draft, awaiting sign-off

## Goal

Introduce coins as a secondary currency in BananaTalk, with profile boost as the first coin-spend feature. VIP subscribers get a monthly coin allowance as part of their subscription; non-VIP users buy coin packs via IAP. Boost = pin the user's profile card to the top of community discovery for N minutes.

## Decisions (locked)

| Question | Decision |
|---|---|
| VIP ↔ coins | Separate currency; VIP gets a monthly coin allowance |
| Boost mechanic | Hard pin to top of community discovery for N minutes |
| Scope | Full stack: backend + IAP + app UI + ranking change |

## Data model (Mongo / Mongoose)

### `User` additions
- `coinBalance: Number` (default 0)
- `vipCoinsLastGrantedAt: Date | null` — bookkeeping for the monthly grant

### New `CoinTransaction` collection
```
{
  userId: ObjectId (indexed),
  type: 'purchase' | 'allowance' | 'spend' | 'refund',
  amount: Number,            // signed: +100 / -180 etc.
  balanceAfter: Number,
  reason: String,            // 'iap_pack_500' | 'vip_monthly' | 'boost_60min' | ...
  relatedId: ObjectId | null, // boost id when applicable
  metadata: Mixed,           // IAP receipt / transaction id, etc.
  createdAt: Date (indexed)
}
```
Used for: history screen, idempotency (unique index on `metadata.iapTransactionId` for purchases), audit, support.

### New `Boost` collection
```
{
  userId: ObjectId (indexed),
  startedAt: Date,
  endsAt: Date (indexed),
  durationMinutes: Number,
  costCoins: Number,
  refundedAt: Date | null,
}
```
- Compound index `(endsAt, userId)` for the pin-to-top query (`endsAt > now`).
- An active boost = `endsAt > now && refundedAt == null`.

## API surface (new routes under `backend/routes/coins.js` and `backend/routes/boosts.js`)

### Coins
- `GET /api/coins/balance` → `{ balance, vipMonthlyAllowance, nextGrantAt }`
- `GET /api/coins/transactions?cursor=&limit=20` → paginated history
- `POST /api/coins/verify-purchase` body `{ platform, productId, receipt, transactionId }` → idempotent verify + credit. Reuses existing IAP verification utilities from `routes/vip.js` / `services/iap*.js`.

### Boosts
- `POST /api/boosts/activate` body `{ durationMinutes }` → debit coins, create boost, return `{ boost, newBalance }`. Reject if an active boost already exists.
- `GET /api/boosts/active` → `{ boost | null }`

### Community discovery (existing) — modify
- `GET /api/community/partners` (or wherever partner discovery is served) — fetch active boosts, return those users pinned to the top **before** the existing ranking is applied, ordered by `startedAt DESC` so the most recently boosted user lands at index 0.

### Cron / scheduled job
- Daily job in `backend/jobs/` that scans VIP users where `vipCoinsLastGrantedAt` is null OR older than 27 days, credits the monthly allowance, and updates `vipCoinsLastGrantedAt`.

## IAP

**Three new consumable products** (NOT subscriptions):

| Pack | iOS productId | Android productId | Price | Coins |
|---|---|---|---|---|
| Small | `com.bananatalk.bananatalkApp.coins.100` | `com.bananatalk.app.coins.100` | $0.99 | 100 |
| Medium | `com.bananatalk.bananatalkApp.coins.500` | `com.bananatalk.app.coins.500` | $3.99 | 500 + 25 bonus |
| Large | `com.bananatalk.bananatalkApp.coins.1500` | `com.bananatalk.app.coins.1500` | $9.99 | 1500 + 250 bonus |

Existing `IOSPurchaseService` / `AndroidPurchaseService` handle subscriptions today. Extend to handle consumables — same purchase flow but with `purchaseConsumable` instead of `buyNonConsumable`, and `consumePurchase` after server verifies the receipt so the user can buy again.

## Monthly allowance + boost pricing

| Item | Coins |
|---|---|
| **VIP monthly allowance** | 300 |
| Boost 30 min | 100 |
| Boost 60 min | 180 |
| Boost 180 min (3h) | 450 |

300/month covers roughly one 60-min boost as part of the VIP value prop. Anything else, top up via packs.

## App UI

### Coin balance pill
Small pill (`💎 247`) in the leading area of the chat list, community, and AI study app bars — placed next to or replacing the VIP-Up pill depending on whether the user is already VIP. Tap → opens coin shop. Balance polled from `userProvider` (extend it to include `coinBalance`).

### Coin shop screen (`lib/pages/coins/coin_shop_screen.dart`)
Three pack cards laid out like the VIP plan grid (horizontal 3-col). Tap a pack → IAP flow → on success, push a "Coins added!" confirmation and pop back. Same gradient CTA pattern as the VIP screen for consistency.

### Boost activation sheet (`lib/pages/community/widgets/boost_sheet.dart`)
Modal bottom sheet with three duration cards (30 / 60 / 180 min) showing cost in coins. Confirm → debit + close + show success banner. Disabled if insufficient coins (show "Get more coins" link to shop).

### Active-boost banner
When the user has an active boost, render a thin gradient banner across the top of the community tab: "🚀 You're boosted — 28 min left". Tap → reveals "Cancel boost" with no refund (or refund half — decide before code).

### Boosted partner card indicator
Boosted users appear at top of the partner-discovery list with a soft gold gradient border on their card + a small "🚀 Boosted" tag near the wave button. Existing `PartnerListItem` gets one extra optional prop `isBoosted`.

### Boost entry points
- Own-profile screen: prominent "Boost my profile" CTA card (if no active boost).
- Community discovery tab: a small "Boost" pill in the app bar (when not boosted) — same row as VIP-Up.

## Ranking change

In the existing partner-discovery service:

```js
const activeBoosts = await Boost.find({ endsAt: { $gt: new Date() }, refundedAt: null })
  .sort({ startedAt: -1 })
  .lean();
const boostedIds = activeBoosts.map(b => b.userId.toString());

// 1) fetch boosted users (preserve order)
const boostedUsers = await User.find({ _id: { $in: boostedIds } }).lean();
const boostedById = new Map(boostedUsers.map(u => [u._id.toString(), u]));
const pinned = boostedIds.map(id => boostedById.get(id)).filter(Boolean);

// 2) existing ranking for the rest (exclude already-pinned ids)
const rest = await runExistingPartnerRanking({ excludeIds: boostedIds, ...filters });

return [...pinned, ...rest];
```

Boosted users don't get pinned for themselves (filter out current user).

## Edge cases & decisions to lock before coding

| Case | Default decision |
|---|---|
| User starts a boost but server hits an error mid-create | Idempotent endpoint; client retries with same client-generated `nonce`. If charged but no boost created, server detects via nonce and either creates the boost or refunds. |
| User buys coins, IAP succeeds, server verify fails | Refund the IAP via the platform-specific path; surface "Try again" UX. |
| Multiple devices race to spend the same coin balance | Atomic Mongo update: `findOneAndUpdate({_id, coinBalance: {$gte: cost}}, {$inc: {coinBalance: -cost}})`. If null, return "Insufficient coins". |
| Boost overlaps another active one for the same user | Reject with 409. UX: hide boost CTA, show remaining time on active. |
| VIP downgrades mid-cycle | Monthly grant stops. Already-granted coins stay on the balance. |
| Visitor accounts | Cannot boost or purchase coins. Push VIP-style upgrade message. |
| Anti-abuse: rate limit boost spam | Hard cap of 3 boost activations per user per 24h, regardless of coin balance. |

## Implementation sequence

Four shippable chunks, each ~1–2 days. **Do NOT bundle all four into a single PR — review checkpoints at every chunk boundary.**

| Chunk | What ships | Touches |
|---|---|---|
| **A. Foundation** | `coinBalance` field, `CoinTransaction` collection, `GET /coins/balance`, balance pill in app bars (read-only) | Backend models + 1 route; app: user provider + pill widget |
| **B. Coin purchase** | IAP coin packs (iOS + Android products), `POST /coins/verify-purchase`, coin shop screen | Backend route + IAP utils extension; app: shop screen + IAP service extension |
| **C. Boost activation** | `Boost` collection, `POST /boosts/activate`, `GET /boosts/active`, boost sheet UI, active-boost banner, anti-abuse rate limit | Backend route + boost model; app: sheet + banner |
| **D. Ranking + monthly grant** | Partner-discovery query change, boosted-card visual indicator, monthly-allowance cron job | Backend partner-discovery service + new cron; app: partner_list_item visual change |

After Chunk D, the loop is closed: VIP user gets monthly coins → spends them on a boost → appears pinned at top of community → other users see the gold border + Boosted tag.

## Out of scope (deliberately)

- Web frontend boost UI — web is Community/Chats/Moments/Profile only per existing scope decision. Web can read coin balance from `userProvider` if it's exposed, but the boost flow and coin shop are mobile-only for now.
- Gifting coins to other users (HelloTalk has this; we ship without it).
- Coin earning via engagement (daily streak, etc.).
- Coin spend on other features beyond boost (translations, AI tutor unlocks). Architecturally supported by the `reason` field on `CoinTransaction` but no other spend paths yet.
- VIP renewal warning / lapsed-VIP flow changes.
