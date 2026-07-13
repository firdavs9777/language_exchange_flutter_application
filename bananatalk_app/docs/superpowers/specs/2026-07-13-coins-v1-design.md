# Coins v1 — Foundation + À La Carte Unlocks — Design

**Date:** 2026-07-13
**Status:** Approved by user (2026-07-13)
**Supersedes/narrows:** `2026-06-21-vip-coins-boost-design.md` (that draft led with *boost*; this v1 leads with *unlocks* to validate willingness-to-pay first). Boost/gifting are Phase 2+.
**Repos:** `bananatalk_app` (Flutter) + `language_exchange_backend_application` (Node/Express + MongoDB)

## Why (measured 2026-07-13, prod `test` db)

- **0 VIP subscriptions ever, 0 transactions** despite a fully-wired, well-surfaced paywall (verified: iOS + Android product IDs match the stores; ~22 paywall entry points). The problem is **willingness to pay a subscription**, not plumbing.
- **Gamification loop is dead** — only 4 users have a streak, 27 have any XP (max 100). So coins earned via learning streaks would reward a near-zero behavior → v1 is **buy-only**, not earn.
- Social graph is thin (70/668 have followers) → gifting deferred.

**Bet:** users who won't commit to a $10/mo sub *will* make small impulse purchases to pay-per-use at the exact moments they hit a wall. v1 exists to **prove or disprove that cheaply** before building boost/gifts.

## Goal

Ship the leanest coin system that answers "will anyone buy a coin?": buy coin packs via IAP, spend coins to unlock extra uses of already-gated features (translations, tutor sessions, etc.) at the limit moments the paywall already hits. VIP stays unchanged.

## Scope

**In (v1):** `coinBalance` + `CoinTransaction` ledger; coin balance/history/verify-purchase APIs; **consumable** IAP (3 packs); à-la-carte **unlock** endpoint + bonus-quota honored by the existing `consumeQuota`; coin balance pill; coin shop screen; unlock CTA added to the existing limit modals. Kill switch `COINS_ENABLED`.

**Out (deferred to Phase 2+):** profile/moment/story boost, gifting, cosmetics, VIP monthly coin allowance, coin earning via engagement, web UI.

## Components

### 1. Data model
- **`User.coinBalance`** — Number, default 0.
- **`CoinTransaction`** collection: `{ userId(ix), type: 'purchase'|'spend'|'refund', amount(signed), balanceAfter, reason, relatedId, metadata(Mixed), createdAt(ix) }`. **Unique sparse index on `metadata.iapTransactionId`** → purchase idempotency. Serves history + audit. **Idempotency id is pinned per platform:** iOS = StoreKit `transactionId` of the consumable (not `originalTransactionId`); Android = `purchaseToken`. Credit is **transactional** (ledger insert + balance `$inc` in one Mongo session — prod is a replica set) so a crash can't leave a purchase row without its balance increment.
- **Paid bonus is a persistent consumable pool, NOT extra daily quota.** New `User.coinBonus` (Map String→Number). An unlock `$inc`s `coinBonus[featureKey]`. Enforcement everywhere: use the free daily cap first; once exhausted, if `coinBonus[featureKey] > 0` allow and atomically decrement. The pool **does not reset daily** (paid uses never evaporate at midnight). **Critical:** the quota engine is NOT unified — `consumeQuota` (`models/User.js:1821`) governs only the 5 tutor chips; **translations** go through `canTranslate()`/`incrementTranslationCount`, **moments** through `canCreateMoment()`/`incrementMomentCount`. The bonus pool must be honored in **all three** paths (a single `consumeQuota` edit would silently deliver nothing for translation/moment unlocks). featureKeys are the real ones: `chat`/`roleplay`/`story`/`photo`/`pronunciation` (tutor, each independent), `translation`, `moment`. **VIP unlimited fast-path is untouched.**

### 2. Backend API (new `routes/coins.js` → `/api/v1/coins`, gated by `COINS_ENABLED`)
- `GET /coins/balance` → `{ balance }`.
- `GET /coins/transactions?cursor=&limit=20` → paginated ledger.
- `POST /coins/verify-purchase` `{ platform, productId, receipt, transactionId }` → idempotent verify + credit. Reuses the existing receipt-verification code in `controllers/iosPurchase.js` / `androidPurchase.js`, adding a **consumable** path. On verify-fail after store charge: refund path + "try again".
- `POST /coins/unlock` `{ featureKey, packSize }` → **atomic** debit `findOneAndUpdate({_id, coinBalance:{$gte:cost}}, {$inc:{coinBalance:-cost}})`; on success `$inc bonusQuota[featureKey]` + write a `spend` CoinTransaction; return `{ newBalance, bonusGranted }`. 402 on insufficient coins.

### 3. IAP — 3 consumable coin packs
| Pack | iOS productId | Android productId | Price | Coins |
|---|---|---|---|---|
| Small | `com.bananatalk.bananatalkApp.coins.100` | `com.bananatalk.app.coins.100` | $0.99 | 100 |
| Medium | `com.bananatalk.bananatalkApp.coins.500` | `com.bananatalk.app.coins.500` | $3.99 | 500 (+25) |
| Large | `com.bananatalk.bananatalkApp.coins.1500` | `com.bananatalk.app.coins.1500` | $9.99 | 1500 (+250) |

Extend `IOSPurchaseService`/`AndroidPurchaseService` for **consumables** (`purchaseConsumable` + `consumePurchase` after server verify so users can rebuy). ⚠️ **Store dependency:** these 3 products must be created as consumables in App Store Connect + Play Console before the flow works live (user task, mirrors the VIP setup).

### 4. Unlock catalog (tunable constants, backend `config/coinCatalog.js`)
| featureKey | grant | cost (coins) |
|---|---|---|
| `translation` | +10 | 50 |
| `moment` | +3 | 40 |
| `chat` / `roleplay` / `story` / `photo` / `pronunciation` (each tutor chip) | +3 | 80 |
Grants add to the persistent `coinBonus` pool (not daily). Costs live server-side; the app reads them via `GET /coins/unlock-catalog` so they never drift. The tutor 429 response identifies which chip is exhausted, and the unlock grants that specific chip.

**Refund on verify-fail:** if `verify-purchase` can't verify a receipt after the store charged, it credits nothing and returns a retryable error; the client leaves the IAP un-consumed so the store can refund/retry (no coins granted without a valid receipt).

### 5. App UI
- **Coin balance pill** (`💎 247`) in chat/community/AI-study app bars → tap opens the shop. `userProvider` extended with `coinBalance`.
- **Coin shop** (`lib/pages/coins/coin_shop_screen.dart`) — 3 pack cards (mirror the VIP plan grid + gradient CTA).
- **Unlock CTA at limit moments** — the existing modals gain a second action beside "Go VIP": *"Unlock N for 💎X"* → debit via `/coins/unlock` → retry the action inline. Entry points (from the 2026-07-13 paywall audit): `translation_bottom_sheet.dart`, `persona_upgrade_sheet.dart` (tutor 429), `limit_exceeded_dialog.dart` (moments/messages).

### 6. Kill switch
`COINS_ENABLED` in `config/limitations.js` (server gate on all coin routes); app-config emits `coinsEnabled`; Flutter hides the pill/shop/unlock CTAs when off. Mirrors `ROOMS_ENABLED`.

## Error handling & edge cases
- **Atomic debit** prevents multi-device double-spend (balance-guarded `findOneAndUpdate`).
- **IAP idempotency** via unique `metadata.iapTransactionId`; replays return the existing credit, no double-credit.
- **Verify-fail after charge** → refund path + surfaced "try again".
- **Visitor accounts** cannot purchase/unlock (regular+ only); show the VIP-style upgrade nudge.
- **Paid `coinBonus` pool is persistent** — it does NOT reset daily (paid uses never evaporate at midnight). Free daily counters reset as before; the pool only drains when consumed. Consume is atomic (free-counter increment OR pool decrement, each a single `findOneAndUpdate`, never composed with a stale `save()`).
- **`COINS_ENABLED=false`** → routes 404, app hides all coin UI.
- **Node caveat:** local Node v25 breaks backend scripts/tests (`SlowBuffer`); use nvm **Node v24.18.0** for `npm test`.

## Testing
- Backend TDD (node:test, `test/*.test.js`): ledger atomic credit/debit + idempotency; `consumeQuota` honoring `bonusQuota`; unlock atomic debit + insufficient-coins 402; verify-purchase idempotency.
- `flutter analyze` clean; `package:` imports only.
- Device smoke = sandbox coin purchase → balance updates → unlock at a real limit → action proceeds.

## Success metric
**Coin purchases > 0** (the whole point) + unlock-spend rate at limit moments. If users buy, Phase 2 (boost → gifts) is justified; if not, we learned it in days, not weeks.

## Phase 2+ (not now)
Profile/moment/story boost (generalized "promote your content"), gifting to partners, cosmetics/gifting-level, VIP monthly coin allowance, earn-via-engagement.
