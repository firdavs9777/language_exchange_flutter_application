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
**Backend — modify:** `models/User.js` (`coinBalance` + `coinBonus` Map + bonus honored in `consumeQuota` [tutor], `canTranslate`/`incrementTranslationCount` [translation], `canCreateMoment`/`incrementMomentCount` [moment]), `controllers/iosPurchase.js` + `controllers/androidPurchase.js` (extract a shared consumable-receipt verifier, VIP path unchanged), `config/limitations.js` (`COINS_ENABLED`), `controllers/appConfig.js` (`coinsEnabled`), `server.js` (mount `/api/v1/coins`).
**App — create:** `lib/models/coin_pack.dart`, `lib/models/coin_transaction.dart`, `lib/services/coin_api_client.dart`, `lib/providers/coins_provider.dart`, `lib/pages/coins/coin_shop_screen.dart`, `lib/widgets/coins/coin_balance_pill.dart`, `lib/widgets/coins/unlock_cta.dart`.
**App — modify:** `lib/services/ios_purchase_service.dart` + `android_purchase_service.dart` (consumable flow), `lib/models/app_config.dart` (`coinsEnabled`), the 3 limit modals (`translation_bottom_sheet.dart`, `persona_upgrade_sheet.dart`, `limit_exceeded_dialog.dart`), the app bars carrying the pill, `userProvider` (`coinBalance`).

---

## BACKEND PHASE (repo: language_exchange_backend_application)

### Task 1: CoinTransaction model + coinLedger helper (atomic, idempotent)

**Files:** Create `models/CoinTransaction.js`, `lib/coinLedger.js`; Modify `models/User.js` (add `coinBalance`); Test `test/coinLedger.test.js`.

- [ ] **Step 1: Add `coinBalance` to User.** `coinBalance: { type: Number, default: 0, min: 0 }`.
- [ ] **Step 2: Create `CoinTransaction` model** per spec (`userId` ix, `type` enum `['purchase','spend','refund']`, `amount`, `balanceAfter`, `reason`, `relatedId`, `metadata` Mixed, `createdAt` ix). Add `CoinTransactionSchema.index({ 'metadata.iapTransactionId': 1 }, { unique: true, sparse: true })`.
  - **Idempotency identifier (reviewer C3 — pin it exactly):** `metadata.iapTransactionId` MUST be the per-purchase store identifier, and the client MUST send the identical value on every retry: **iOS** = the StoreKit `transactionId` of the *consumable* purchase (NOT `originalTransactionId`); **Android** = the `purchaseToken`. Document this in the model file. Task 5's verify must read the platform-appropriate field into this key.
- [ ] **Step 3: Confirm prod is a replica set (it is — Atlas `replicaSet=atlas-bnfxlc-shard-0`), so Mongo multi-document transactions are available.** `credit` will use a session/transaction so the ledger insert + balance `$inc` commit atomically (reviewer C2).
- [ ] **Step 4: Write failing tests** for `lib/coinLedger.js`. Pure decision logic (insufficient-balance branch, signed amounts, balanceAfter math) as node:test units; the two DB-level guarantees (balance-guarded debit, dup-key credit idempotency) get an **integration test** (Task 1b) since they cannot be exercised as pure units (reviewer M2). Unit tests here:
  - `debit` returns `{ok:false}` (no mutation) when balance < cost; returns correct `balanceAfter` when sufficient.
  - `credit` computes correct `balanceAfter` and marks the txn `purchase`.
- [ ] **Step 5: Run tests, verify fail** (`~/.nvm/versions/node/v24.18.0/bin/node --experimental-test-module-mocks --test test/coinLedger.test.js`).
- [ ] **Step 6: Implement `lib/coinLedger.js` (crash-safe).**
  - `debit(userId, cost, {reason, relatedId})`: `User.findOneAndUpdate({_id, coinBalance:{$gte:cost}}, {$inc:{coinBalance:-cost}}, {new:true})`; if null → `{ok:false}` (insufficient); else write a `spend` txn with `balanceAfter = doc.coinBalance`.
  - `credit(userId, amount, {reason, metadata})` — **transactional, reconcile-safe (reviewer C2):** open a session; within `withTransaction`: insert the `purchase` txn (unique `metadata.iapTransactionId`) AND `$inc` the balance together, so a crash rolls back both. On duplicate-key (already credited), abort and **return the existing txn** — the prior transaction guarantees the balance was applied, so there is no "txn written but balance never incremented" window.
- [ ] **Step 7: Run unit tests green. Commit** `feat(coins): CoinTransaction model + crash-safe idempotent coinLedger`.

### Task 1b: Ledger integration test (DB-level money guarantees)

**Files:** Test `test/coinLedger.integration.test.js` (uses `mongodb-memory-server` if present, else the MCP Atlas-local deployment; check `package.json` devDeps first — if no ephemeral Mongo is available, add `mongodb-memory-server` as a devDependency).

- [ ] **Step 1: Write failing integration tests** against a real Mongo:
  - concurrent `debit` calls racing the same balance never drive it negative (fire N parallel debits > balance; exactly `floor(balance/cost)` succeed).
  - `credit` called twice with the same `iapTransactionId` increments the balance exactly once (idempotency) — including a simulated retry.
  - a `credit` transaction that throws mid-way leaves balance AND ledger unchanged (rollback).
- [ ] **Step 2: Run fail → confirm green → Commit** `test(coins): integration tests for debit-guard + credit idempotency`.

### Task 2: Coin catalog + COINS_ENABLED + app-config flag

**Files:** Create `config/coinCatalog.js`; Modify `config/limitations.js`, `controllers/appConfig.js`; Test `test/coinCatalog.test.js`.

- [ ] **Step 1:** `config/coinCatalog.js` — export `PACKS` (id → coins, per spec table) and `UNLOCKS` keyed by the **real featureKeys** (reviewer I2): `translation:{cost:50,grant:10}`, `moment:{cost:40,grant:3}`, and each tutor chip `chat`/`roleplay`/`story`/`photo`/`pronunciation`:`{cost:80,grant:3}`. Plus `getUnlock(featureKey)` → cost/grant or null for unknown. Test: `getUnlock('translation')` + `getUnlock('roleplay')` return correct values; unknown key → null.
- [ ] **Step 2:** `config/limitations.js` — add `const COINS_ENABLED = String(process.env.COINS_ENABLED || 'true').toLowerCase()==='true';` + export.
- [ ] **Step 3:** `controllers/appConfig.js` — add `coinsEnabled: COINS_ENABLED` to the response.
- [ ] **Step 4:** Run tests green. **Commit** `feat(coins): coin catalog constants + COINS_ENABLED flag + app-config`.

### Task 3: Persistent bonus-credit pool honored at ALL THREE enforcement sites

> **Reviewer C1 (the load-bearing fix):** `consumeQuota` governs ONLY the 5 tutor chips (`models/User.js:1821`, keyed off `TUTOR_QUOTA_FIELDS` at `:8-14`, enforced via an atomic `$expr` filter ~`:1876-1881`, wired at `middleware/checkTutorQuota.js:39`). **Translations** are gated separately by `user.canTranslate()` (`models/User.js:1178`) + `incrementTranslationCount` (called in `controllers/advancedMessages.js:185`). **Moments** by `user.canCreateMoment()` (`:1471`) + `incrementMomentCount` (`middleware/checkLimitations.js:55`, `routes/moments.js:59`). Editing only `consumeQuota` would debit coins for translation/moment unlocks and deliver NOTHING → coins lost without value. The bonus must be honored in all three paths.

> **Design change (reviewer I4 + M3a):** the paid bonus is a **persistent consumable pool**, NOT a daily-reset counter. A paid unlock adds to `User.coinBonus[featureKey]` (a real, declared schema field). Enforcement everywhere is: *if the free daily cap is still available, use it (free); otherwise if `coinBonus[featureKey] > 0`, allow and atomically decrement the pool.* This (a) means paid unlocks never evaporate at midnight (removes the top complaint/refund vector), and (b) keeps the free daily counters untouched.

**Files:** Modify `models/User.js` — declare `coinBonus` (Map of String→Number, default `{}`); update `consumeQuota` (tutor), `canTranslate`+`incrementTranslationCount` (translation), `canCreateMoment`+`incrementMomentCount` (moment) to consult+decrement the pool. Test `test/coinBonus.enforcement.test.js`.

- [ ] **Step 1: READ** all three enforcement paths named above and note the exact allow-decision + increment sites. Confirm `coinBonus` must be an explicitly-declared field (the `regularUserLimitations` subschema at `:440-499` is strict → an undeclared nested `$inc` would be dropped by Mongoose).
- [ ] **Step 2: Declare `coinBonus`** on the User schema: `coinBonus: { type: Map, of: Number, default: {} }`.
- [ ] **Step 3: Define atomic consume — NEVER compose `$inc` with `this.save()` (reviewer NEW-C1).** The pool decrement and the free-counter increment must each be a single atomic `findOneAndUpdate`, and the request must NOT afterwards `save()` a stale in-memory copy of these fields (a trailing `save()` would overwrite the atomic decrement with the pre-decrement value → unlimited free bonus). Pattern per feature (`consume(featureKey)`):
  1. **Free path (atomic):** `findOneAndUpdate({_id, <freeCounter> < cap}, {$inc:{<freeCounter>:+1}})`. If it returns a doc → allowed via free quota, done.
  2. **Pool path (atomic), only if free returned null:** `findOneAndUpdate({_id, ['coinBonus.'+featureKey]:{$gte:1}}, {$inc:{['coinBonus.'+featureKey]:-1}})`. If doc → allowed via paid pool. If null → blocked.
  Exactly one bucket is consumed per request; both ops are atomic so concurrent requests can't double-spend or lost-update. **featureKeys are the REAL keys (reviewer I2):** `chat`/`roleplay`/`story`/`photo`/`pronunciation` (each independent), `translation`, `moment`.
  - **Tutor** (`consumeQuota`, already a pure atomic `findOneAndUpdate` with no `save()`): add the pool path as the second atomic op in its cap-hit branch — composes cleanly.
  - **Translation** (`canTranslate`+`incrementTranslationCount`) and **Moment** (`canCreateMoment`+`incrementMomentCount`): these currently do read-modify-`this.save()` (`models/User.js` ~`:1207` / ~`:1493`, saved by controllers at `advancedMessages.js:245` / `moments.js:461`). **Rewrite them into the atomic two-step above** and **remove the read-modify-`save()` of these counters** so nothing overwrites the pool. Mirror the `consumeQuota` shape.
- [ ] **Step 4: Write failing tests** — pure decision logic for the bucket choice, PLUS **concurrency integration tests (reviewer NEW-C1)** for BOTH the translation and moment paths against a real Mongo: "free cap exhausted, `coinBonus[key]=1`, two concurrent consume calls → pool ends at exactly 0 and exactly one call is allowed" (proves no `save()`-overwrite and no double-spend). Also: free-cap-available uses free path (pool untouched); pool persists across the daily reset; VIP fast-path unchanged.
- [ ] **Step 5: Run fail → implement all three sites atomically (no trailing `save()` of these counters; VIP fast-path and daily reset untouched) → run green.**
- [ ] **Step 6: Commit** `feat(coins): atomic free-then-pool consume for tutor/translation/moment (no save() overwrite)`.

> **Tutor granularity (reviewer I2):** `persona_upgrade_sheet.dart` fires on a generic tutor 429, but the 5 chips cap independently. The 429 response already identifies the exhausted `featureKey` — the unlock grants that specific chip. Task 9 passes the featureKey from the 429 to the unlock call.

### Task 4: Carve out a reusable consumable receipt verifier

> **Reviewer I1 — scope up:** this is NOT a one-line export. `verifyIOSPurchase` (`controllers/iosPurchase.js:312`, a 913-line controller) verifies the receipt (StoreKit2 ~`:202`, legacy ~`:257`) then INLINE derives the plan and calls `user.activateVIP(...)` ~`:498`. Android (`androidPurchase.js`, ~472 lines) mirrors this. There is no pure verify function to import — it must be carefully extracted, leaving the VIP path behaviorally identical.

**Files:** Modify `controllers/iosPurchase.js`, `controllers/androidPurchase.js`; Test `test/coinPurchaseVerify.test.js`, `test/vipActivation.regression.test.js`.

- [ ] **Step 1: READ** both verify controllers fully; identify the exact receipt-verification core vs. the subscription/`activateVIP` side effects.
- [ ] **Step 2: Extract** `verifyConsumableReceipt({platform, productId, receipt, purchaseIdentifier})` returning `{valid, productId, transactionId}` — where `transactionId` is the pinned per-platform idempotency id (iOS StoreKit `transactionId`; Android `purchaseToken`, reviewer C3). NO `activateVIP` side effects. Refactor the existing VIP verify to call the shared core so its behavior is unchanged.
- [ ] **Step 3: Write failing tests** (mock the platform verifier): valid → `{valid:true, productId, transactionId}`; invalid → `{valid:false}`; coin-pack productId maps to coins via `coinCatalog.PACKS`. **Plus a VIP-activation regression test** asserting the existing subscription verify still activates VIP after the extraction (reviewer I1).
- [ ] **Step 4: Run fail → implement → run green (including the VIP regression).**
- [ ] **Step 5: Commit** `refactor(iap): extract shared consumable receipt verifier (VIP path unchanged)`.

### Task 5: Coins routes + controllers

**Files:** Create `controllers/coins.js`, `routes/coins.js`; Modify `server.js`; Test `test/coins.controller.test.js`.

- [ ] **Step 1: Write failing tests** for the controller decisions (extract pure helpers where DB blocks direct testing; DB-level guarantees are covered by Task 1b):
  - `verify-purchase`: valid receipt credits coins once; **replay with same idempotency id does not double-credit** (via ledger).
  - `verify-purchase` with a receipt that **fails verification after a store charge** → returns a `try again` error and writes NO credit (refund path, reviewer M3b).
  - `unlock`: sufficient balance → debit `UNLOCKS[featureKey].cost`, `$inc coinBonus[featureKey]` by `.grant`, return newBalance; **insufficient → 402, no debit, no grant** (debit and grant must not half-apply — grant only if debit `ok`).
  - unknown `featureKey` → 400.
  - `COINS_ENABLED=false` → all routes 404.
  - **visitor userMode → 403 on purchase AND unlock, enforced server-side** (reviewer M3c — not just client-hidden).
- [ ] **Step 2: Run fail.**
- [ ] **Step 3: Implement `controllers/coins.js`:**
  - `getBalance`, `getTransactions` (cursor pagination), `getUnlockCatalog` (so the app reads live cost/grant — see Task 9).
  - `verifyPurchase`: `verifyConsumableReceipt` → if `!valid` return 400 "purchase could not be verified, try again" (client's IAP stays un-consumed so the store can refund/retry) → if valid `coinLedger.credit` keyed on the pinned idempotency id.
  - `unlock`: reject if `userMode === 'visitor'` (403); look up `getUnlock(featureKey)` (400 if unknown); `coinLedger.debit(cost)` → if `!ok` 402; on ok atomically `$inc coinBonus[featureKey]` by `grant` and return `{newBalance, granted}`.
  - `routes/coins.js` wrapped by `coinsEnabledGuard` + `protect`; mount `/api/v1/coins` in `server.js`.
- [ ] **Step 4: Run green. Commit** `feat(coins): coins REST — balance, transactions, catalog, verify-purchase, unlock`.

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
- [ ] **Step 3:** Place the pill in the high-traffic app bars. **Note (reviewer I3):** there is NO single shared "VIP pill" widget — VIP entry points are scattered (e.g. `chat_list_screen.dart`, `learning_main_screen.dart`, `community_app_bar.dart`). So this means editing each of those app bars individually to add `CoinBalancePill`; budget for ~3 separate edits, not one shared host. VIP + coins coexist.
- [ ] **Step 4:** `flutter analyze` clean. **Commit** `feat(coins): balance pill + coin shop screen`.

### Task 9: Unlock CTA in the limit modals

**Files:** Create `lib/widgets/coins/unlock_cta.dart`; Modify `lib/.../translation_bottom_sheet.dart`, `persona_upgrade_sheet.dart`, `limit_exceeded_dialog.dart` (confirm exact paths from the 2026-07-13 paywall audit).

- [ ] **Step 1:** `unlock_cta.dart` — a button "Unlock {grant} for 💎{cost}" that calls `coinApi.unlock(featureKey)`; reads cost/grant from the backend catalog (`getUnlockCatalog`) so values never drift; on 402 → route to coin shop ("Get more coins"); on success → callback so the caller retries the gated action inline.
- [ ] **Step 2:** Wire it into each of the 3 modals as a **second** action beside the existing "Go VIP" (do not remove the VIP CTA). Map each modal to its real `featureKey`: `translation_bottom_sheet.dart` → `translation`; `limit_exceeded_dialog.dart` → `moment`; `persona_upgrade_sheet.dart` → **the specific tutor chip from the 429 response** (`chat`/`roleplay`/`story`/`photo`/`pronunciation`), not a generic "tutor" key (reviewer I2). Hidden when `!coinsEnabled`.
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
