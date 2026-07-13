# Coins v1 (Foundation + À La Carte Unlocks) — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users buy coin packs via IAP and spend coins to unlock extra uses of already-gated features (translations, tutor sessions, moments) at the exact limit moments the paywall hits — validating willingness-to-pay before building boost/gifts.

**Architecture:** Add `coinBalance` + a `CoinTransaction` ledger to the backend; a coins REST module (balance/history/verify-purchase/unlock) reusing existing IAP receipt verification for **consumables**; a per-feature `bonusQuota` the existing `consumeQuota` engine honors so an unlock grants extra daily uses without touching VIP's unlimited fast-path. Flutter adds a coin balance pill, a coin shop, and an "Unlock N for 💎X" action inside the existing limit modals. Everything gated by `COINS_ENABLED`.

**Tech Stack:** Node/Express + Mongoose (backend, node:test runner), Flutter + Riverpod + in_app_purchase (app), MongoDB.

**Spec:** `docs/superpowers/specs/2026-07-13-coins-v1-design.md`

**Repos:**
- Backend: `/Users/davis/Desktop/Personal/language_exchange_backend_application`
- App: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

**Global constraints (read before every task):**
- **Branch:** create `workstream-f-coins` in BOTH repos off `main` before Task 1. Per-task commits.
- **Backend tests:** node's built-in runner. `npm test` = `node --experimental-test-module-mocks --test services/*.test.js test/*.test.js`. Write tests as `const { test } = require('node:test'); const assert = require('node:assert/strict');` in `test/*.test.js`. **Local Node v25 is broken** (`SlowBuffer` → jsonwebtoken crash) — run tests with nvm **Node v24.18.0**: `~/.nvm/versions/node/v24.18.0/bin/node --experimental-test-module-mocks --test ...`. Baseline has pre-existing failures in `notificationCaps`/`profileVisitCleanup` — add no NEW failures.
- **App:** `package:` imports only (linter-enforced). `flutter analyze` clean (0 errors) before each commit.
- **Kill switch:** every coin route + socketless server path gated by `COINS_ENABLED`; app hides all coin UI when `appConfig.coinsEnabled == false`.
- **Money safety:** all balance mutations are atomic and idempotent (see tasks). Never credit twice for one IAP transaction; never let balance go negative.

---

## File Structure

**Backend — create:** `models/CoinTransaction.js`, `lib/coinLedger.js` (atomic credit/debit + idempotency helper — pure, unit-testable), `controllers/coins.js`, `routes/coins.js`, `config/coinCatalog.js` (pack + unlock cost constants), tests under `test/`.
**Backend — modify:** `models/User.js` (`coinBalance` + `bonusQuota`), `models/User.js consumeQuota` (honor bonusQuota), `controllers/iosPurchase.js` + `controllers/androidPurchase.js` (export a reusable consumable-receipt verify), `config/limitations.js` (`COINS_ENABLED`), `controllers/appConfig.js` (`coinsEnabled`), `server.js` (mount `/api/v1/coins`).
**App — create:** `lib/models/coin_pack.dart`, `lib/models/coin_transaction.dart`, `lib/services/coin_api_client.dart`, `lib/providers/coins_provider.dart`, `lib/pages/coins/coin_shop_screen.dart`, `lib/widgets/coins/coin_balance_pill.dart`, `lib/widgets/coins/unlock_cta.dart`.
**App — modify:** `lib/services/ios_purchase_service.dart` + `android_purchase_service.dart` (consumable flow), `lib/models/app_config.dart` (`coinsEnabled`), the 3 limit modals (`translation_bottom_sheet.dart`, `persona_upgrade_sheet.dart`, `limit_exceeded_dialog.dart`), the app bars carrying the pill, `userProvider` (`coinBalance`).

---

## BACKEND PHASE (repo: language_exchange_backend_application)

### Task 1: CoinTransaction model + coinLedger helper (atomic, idempotent)

**Files:** Create `models/CoinTransaction.js`, `lib/coinLedger.js`; Modify `models/User.js` (add `coinBalance`); Test `test/coinLedger.test.js`.

- [ ] **Step 1: Add `coinBalance` to User.** `coinBalance: { type: Number, default: 0, min: 0 }`.
- [ ] **Step 2: Create `CoinTransaction` model** per spec (`userId` ix, `type` enum `['purchase','spend','refund']`, `amount`, `balanceAfter`, `reason`, `relatedId`, `metadata` Mixed, `createdAt` ix). Add `CoinTransactionSchema.index({ 'metadata.iapTransactionId': 1 }, { unique: true, sparse: true })`.
- [ ] **Step 3: Write failing tests** for `lib/coinLedger.js` (mock the Model layer or use dependency-injected collection so it stays a pure unit — check how existing `lib/*.js` are tested):
  - `credit(userId, amount, {reason, metadata})` increments balance and writes a `purchase` txn with correct `balanceAfter`.
  - `credit` is **idempotent** on `metadata.iapTransactionId`: a second call with the same id does NOT double-credit (duplicate-key caught → returns existing).
  - `debit(userId, cost, {reason})` uses a balance-guarded atomic update; returns `{ok:false}` when balance < cost (no mutation).
- [ ] **Step 4: Run tests, verify fail** (`~/.nvm/versions/node/v24.18.0/bin/node --experimental-test-module-mocks --test test/coinLedger.test.js`).
- [ ] **Step 5: Implement `lib/coinLedger.js`.**
  - `debit`: `User.findOneAndUpdate({_id, coinBalance:{$gte:cost}}, {$inc:{coinBalance:-cost}}, {new:true})`; if null → insufficient; else write `spend` txn with `balanceAfter`.
  - `credit`: try to insert the `purchase` txn first (unique iapTransactionId) to claim idempotency, then `$inc` balance; on duplicate-key, return the existing txn without incrementing.
- [ ] **Step 6: Run tests green. Commit** `feat(coins): CoinTransaction model + atomic idempotent coinLedger`.

### Task 2: Coin catalog + COINS_ENABLED + app-config flag

**Files:** Create `config/coinCatalog.js`; Modify `config/limitations.js`, `controllers/appConfig.js`; Test `test/coinCatalog.test.js`.

- [ ] **Step 1:** `config/coinCatalog.js` — export `PACKS` (id → coins, per spec table) and `UNLOCKS` (`{ translation:{cost:50,grant:10}, tutorChat:{cost:80,grant:3}, moment:{cost:40,grant:3} }`), plus a `getUnlock(featureKey)` helper. Test: `getUnlock('translation')` returns the right cost/grant; unknown key → null.
- [ ] **Step 2:** `config/limitations.js` — add `const COINS_ENABLED = String(process.env.COINS_ENABLED || 'true').toLowerCase()==='true';` + export.
- [ ] **Step 3:** `controllers/appConfig.js` — add `coinsEnabled: COINS_ENABLED` to the response.
- [ ] **Step 4:** Run tests green. **Commit** `feat(coins): coin catalog constants + COINS_ENABLED flag + app-config`.

### Task 3: bonusQuota honored by consumeQuota

**Files:** Modify `models/User.js` (`bonusQuota` field + `consumeQuota`); Test `test/consumeQuota.bonus.test.js`.

- [ ] **Step 1: READ `consumeQuota` (models/User.js ~1821)** and the tier-limit resolution + daily-reset logic. Note exactly where `used` is compared to the tier cap, and where the daily reset zeroes counters.
- [ ] **Step 2: Add `bonusQuota`** — a per-feature daily counter alongside `regularUserLimitations` (e.g. `regularUserLimitations.bonus: { <featureKey>: Number }`), reset on the same daily boundary as the existing counters.
- [ ] **Step 3: Write failing tests** (pure helper — extract the allow-decision if needed to test without a live DB):
  - free user at cap (used == 5, bonus 0) → blocked.
  - free user at cap with `bonus[feature] = 3` → allowed until used == 8, then blocked.
  - VIP fast-path unchanged (still unlimited, bonus irrelevant).
  - daily reset zeroes `bonus` too.
- [ ] **Step 4: Run, verify fail.**
- [ ] **Step 5: Implement:** change the cap comparison to `used < tierCap + (bonus[featureKey] || 0)`; include `bonus` in the daily reset. Do NOT alter the VIP fast-path.
- [ ] **Step 6: Run green. Commit** `feat(coins): consumeQuota honors per-feature bonusQuota`.

### Task 4: Consumable IAP verify (reuse existing receipt verification)

**Files:** Modify `controllers/iosPurchase.js`, `controllers/androidPurchase.js` (export a reusable verify fn); Test `test/coinPurchaseVerify.test.js`.

- [ ] **Step 1: READ** the existing `verifyIOSPurchase` / `verifyAndroidPurchase` to find the receipt-verification core (Apple JWS / Google Play API call) and factor out a reusable `verifyConsumableReceipt({platform, productId, receipt, transactionId})` that returns `{valid, productId, transactionId}` WITHOUT the subscription-specific `activateVIP` side effects.
- [ ] **Step 2: Write failing tests** mocking the platform verifier: valid receipt → `{valid:true, productId}`; invalid → `{valid:false}`; the coin-pack productId maps to the right coin amount via `coinCatalog.PACKS`.
- [ ] **Step 3: Run fail → implement → run green.**
- [ ] **Step 4: Commit** `feat(coins): reusable consumable receipt verification`.

### Task 5: Coins routes + controllers

**Files:** Create `controllers/coins.js`, `routes/coins.js`; Modify `server.js`; Test `test/coins.controller.test.js`.

- [ ] **Step 1: Write failing tests** for the controller decisions (extract pure helpers where DB blocks direct testing):
  - `verify-purchase`: valid receipt credits coins once; **replay with same transactionId does not double-credit** (via ledger idempotency).
  - `unlock`: sufficient balance → debit `UNLOCKS[featureKey].cost`, grant `.grant` bonus quota, return newBalance; **insufficient → 402, no debit, no grant**.
  - unknown `featureKey` → 400.
  - `COINS_ENABLED=false` → all routes 404.
  - visitor userMode → 403 on purchase/unlock.
- [ ] **Step 2: Run fail.**
- [ ] **Step 3: Implement `controllers/coins.js`:** `getBalance`, `getTransactions` (cursor pagination), `verifyPurchase` (verifyConsumableReceipt → `coinLedger.credit` with `metadata.iapTransactionId`), `unlock` (`coinLedger.debit` cost → on ok `$inc regularUserLimitations.bonus[featureKey]` by grant). `routes/coins.js` wrapped by a `coinsEnabledGuard` + `protect`; mount `/api/v1/coins` in `server.js`.
- [ ] **Step 4: Run green. Commit** `feat(coins): coins REST — balance, transactions, verify-purchase, unlock`.

**== BACKEND PHASE DONE (T1–T5) ==**

---

## APP PHASE (repo: bananatalk_app)

### Task 6: Coin models + API client + provider + app-config flag

**Files:** Create `lib/models/coin_pack.dart`, `coin_transaction.dart`, `lib/services/coin_api_client.dart`, `lib/providers/coins_provider.dart`; Modify `lib/models/app_config.dart`, `userProvider`.

- [ ] **Step 1:** `AppConfig.coinsEnabled` in `fromJson`.
- [ ] **Step 2:** models (`CoinPack`, `CoinTransaction` fromJson).
- [ ] **Step 3:** `coin_api_client.dart` — `getBalance()`, `getTransactions()`, `verifyPurchase(...)`, `unlock(featureKey, packSize)` (use the existing api_client base + auth; `package:` imports).
- [ ] **Step 4:** `coins_provider.dart` (Riverpod) exposing balance + refresh; extend `userProvider` to carry `coinBalance`.
- [ ] **Step 5:** `flutter analyze` clean. **Commit** `feat(coins): coin models + api client + provider`.

### Task 7: Consumable IAP in purchase services

**Files:** Modify `lib/services/ios_purchase_service.dart`, `android_purchase_service.dart`.

- [ ] **Step 1: READ** the current subscription purchase flow in both. Add a `purchaseCoinPack(productId)` using **`buyConsumable`** (not `buyNonConsumable`), and after backend `verify-purchase` succeeds, call `completePurchase`/`consumePurchase` so the pack is repurchasable.
- [ ] **Step 2:** Register the 3 coin-pack product IDs (spec table) in each service's product-id set.
- [ ] **Step 3:** `flutter analyze` clean. **Commit** `feat(coins): consumable IAP coin-pack purchase flow`.

### Task 8: Coin balance pill + coin shop

**Files:** Create `lib/widgets/coins/coin_balance_pill.dart`, `lib/pages/coins/coin_shop_screen.dart`; Modify the app bars (chat/community/AI-study) that host the VIP pill.

- [ ] **Step 1:** `coin_balance_pill.dart` — `💎 <balance>`; tap → push coin shop. Hidden when `!coinsEnabled`.
- [ ] **Step 2:** `coin_shop_screen.dart` — 3 pack cards (mirror `vip_plans_screen` grid + gradient CTA); tap → `purchaseCoinPack` → on success `coinsProvider.refresh()` + "Coins added!" confirmation.
- [ ] **Step 3:** Add the pill to the app bars beside/replacing the VIP pill (VIP + coins can coexist; follow the existing pill layout).
- [ ] **Step 4:** `flutter analyze` clean. **Commit** `feat(coins): balance pill + coin shop screen`.

### Task 9: Unlock CTA in the limit modals

**Files:** Create `lib/widgets/coins/unlock_cta.dart`; Modify `lib/.../translation_bottom_sheet.dart`, `persona_upgrade_sheet.dart`, `limit_exceeded_dialog.dart` (confirm exact paths from the 2026-07-13 paywall audit).

- [ ] **Step 1:** `unlock_cta.dart` — a button "Unlock {grant} for 💎{cost}" that calls `coinApi.unlock(featureKey, packSize)`; on 402 → route to coin shop ("Get more coins"); on success → callback so the caller retries the gated action inline. Reads cost/grant from backend (unlock catalog) so values don't drift.
- [ ] **Step 2:** Wire it into each of the 3 modals as a **second** action beside the existing "Go VIP" (do not remove the VIP CTA). Map each modal to its `featureKey` (translation / tutorChat / moment). Hidden when `!coinsEnabled`.
- [ ] **Step 3:** `flutter analyze` clean. **Commit** `feat(coins): 'unlock for coins' CTA in translation/tutor/creation limit modals`.

**== APP PHASE DONE (T6–T9) ==**

---

## GATE

### Task 10: Whole-branch review + gate + store setup note

- [ ] **Step 1: Automated gate.** Backend: `npm test` under Node v24 (no NEW failures vs the 1 pre-existing `profileVisitCleanup`). App: `flutter analyze` 0 errors.
- [ ] **Step 2: Whole-branch review** (both repos) via superpowers:requesting-code-review, focused on **money-safety**: atomic debit can't go negative; IAP credit idempotency (no double-credit on replay/retry); bonusQuota can't be exploited to bypass VIP fast-path or persist past daily reset; `COINS_ENABLED` gates every route. Batch-fix Critical/Important.
- [ ] **Step 3: Device smoke (sandbox):** buy a coin pack in sandbox → balance updates → hit a real translation/tutor limit → "Unlock" → coins debit → action proceeds → transaction appears in history. Confirm replaying a purchase doesn't double-credit.
- [ ] **Step 4: Merge** `workstream-f-coins` → main (both repos) on user go-ahead (pull first).

## Pending store / deploy steps (user)
- **Create 3 consumable coin-pack products** in App Store Connect + Google Play Console with the exact product IDs in the spec, priced $0.99 / $3.99 / $9.99, status Active. (Flow silently fails until these exist — same lesson as VIP.)
- Set `COINS_ENABLED` on prod (defaults on).
- Confirm the store billing agreement / payments profile is active (the outstanding VIP question — same gate applies to coins).

## Metric
Re-measure after ship: **coin purchases > 0** (the validation), unlock-spend counts by featureKey, revenue. Purchases > 0 justifies Phase 2 (boost → gifts); zero means the willingness-to-pay bet failed cheaply.
