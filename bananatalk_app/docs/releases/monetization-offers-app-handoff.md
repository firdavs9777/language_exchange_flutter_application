# Monetization offers (app side, Plan D2) - handoff

Branch `feat/monetization-offers-app` (base app main c2c6082d). Not built, not versioned, not submitted, not pushed. The server half is deployed with every switch off. Server guide: `docs/rollout/monetization-offers.md` in the backend repo.

**Nothing in this build was checked on a device.** Every claim below comes from reading the code, grep and automated tests.

Goal of this build: give every paywall a funnel number (events), let the server pick one passive upsell per user per day (offers), open the right screen from the masked visit push, and fix three store/receipt problems that need no switch. The first two pieces are behind two settings the app reads from the server (`paywallEventsEnabled`, `offerEngineEnabled` in app-config). Both are off in production today.

## 1. What changes for every user of this build, with no switch involved

Parts with no flag. These are the visible or behavioural differences from the current release:

1. **The VIP plans screen no longer shows a full-screen spinner.** It draws at once. Prices come from the store when it has answered, otherwise from the last price the store gave this device (saved on the device, kept across sign-out), otherwise from the plan's list price, as today. The monthly-equivalent and savings figures follow the same rule. The coin shop price text follows the same rule. The payment screen uses the same price as the plans screen. A saved price is only a placeholder: as soon as the store answers with a non-empty list containing the product, the store price is shown. (Code: `lib/pages/vip/vip_price.dart`, `lib/pages/vip/vip_plans_screen.dart`, `lib/services/store_price_cache.dart`.)
2. **A failed price lookup is retried.** If the store product list is empty or the lookup threw, the store service asks again on the next store init and when the plans screen or coin shop opens (once per open; a query already running is shared, never two at once). Before, an empty first answer stayed empty for the session. Tapping Continue on the plans screen before the store has answered goes to the payment screen exactly as before; the payment screen then does its own init and load, and shows its existing error if the product is missing. Because the spinner is gone, Continue is now reachable earlier. (Code: `lib/services/product_query_gate.dart`, `ios_purchase_service.dart`, `android_purchase_service.dart`.)
3. **The expired-receipt retry stops.** The app used to send an old subscription receipt to the server at every launch, and the server refused it every time. Now, only when the server answers HTTP 400 with exactly "Subscription has expired", that receipt (keyed by transaction id, or a hash of the receipt, plus its renewal time) is remembered for this account (`expired_receipts_v1_<userId>`, newest 50) and not sent again. A real renewal has a new renewal time, so it is a new key and is delivered. On iOS a receipt that is clearly lapsed by its own dates (3-day grace) is skipped without a request and is not remembered. A network error, or any other text, is never remembered. The manual Restore button and the payment screen never consult the memory. (Code: `lib/services/expired_receipt_memo.dart`, `purchase_redelivery.dart`, `providers/provider_root/purchase_restore_provider.dart`.)
4. **Dead screens and helpers are removed** (no caller existed): `VisitorLimitDialog`, `VisitorUpgradeScreen`, `DailyChatLimitService`, the unreachable daily-chat-limit branch in `chat_screen_wrapper.dart`, `VipPromoCard`, `VipLockBadge`, and the uncalled `FeatureGate` helpers. No user could reach them.

Internal differences, listed so none is a surprise later (nothing visible, no request):

- **Shared open helpers.** Every site that opened the VIP plans or the coin shop now goes through `openVipPlans` / `openCoinShop` (`lib/services/paywall/paywall_navigation.dart`), keeping the route class each site used (Material or `AppPageRoute`). A source-scan test (`test/paywall/paywall_open_scan_test.dart`) keeps it that way.
- **`LimitExceededDialog` is now a stateful widget** (to log from `initState` / `dispose`); its constructor and `show` are unchanged.
- **`UnlockCta` gained optional `flow` and `onCtaTapped`**; `CoinShopScreen` catches, logs and rethrows a thrown purchase error (behaviour unchanged).
- **`ProfileVisitorsScreen` and `BoostScreen` gained an optional `flow`.** Only the engine's recall card and Matches-empty Boost button pass one (under Show); every other caller passes nothing and gets today's behaviour.
- **`MaskedPersonTile` is now a stateful widget** so its unlock button and "Go VIP" share one flow on the tile's placement (the waves tab reports `other` for both). Nothing visible changes.
- **`offersProvider` is touched with the engine off** (see section 3): the first-frame refresh in `TabBarMenu.dart:150`, the resume refresh in `main.dart:289`, and the after-purchase refresh construct the notifier and its flag listener; no request is made.
- **`paywallLog` with the events flag off builds nothing**: it calls the test spy, reads `paywallEventsEnabledProvider` and returns. No tracker, no API client, no lifecycle observer.
- **New prefs keys** `store_prices_v1` (device level, survives sign-out) and per-account `expired_receipts_v1_<userId>`.
- **New route `/visitors`** (only a masked visit push can reach it today). If the signed-in profile cannot load (push tapped offline) it opens the list for the user id saved in prefs, or goes to the tabs when there is none.
- **Provider bookkeeping.** `paywallTrackerProvider`, `offersProvider`, `offerGateProvider`, `offersApiProvider` are user-scoped (reset on sign-out); the two flag providers, `offersClockProvider` and `savedStorePricesProvider` are app-scoped (`lib/services/session_reset.dart`).
- **No new strings, no new screens, no new dialogs.** `git diff c2c6082d..HEAD --stat -- bananatalk_app/lib/l10n` should show no change, so there is no native review of app strings.

## 2. What each switch turns on

| Server switch (app-config key) | What the app does when it is on |
|---|---|
| `PAYWALL_EVENTS_ENABLED` (`paywallEventsEnabled`) | The tracker batches funnel events in memory and sends them to `POST /purchases/paywall-events` (flush at 20 queued, 10 s after the first, and when the app leaves the foreground; chunks of 50; failures dropped; nothing written to disk). Events: `shown`, `dismissed`, `cta_vip`, `cta_coins`, `cta_ad`, `plans_viewed`, `shop_viewed`, `purchase_started`, `purchase_succeeded`, `purchase_failed`, `unlock_succeeded`, one flow id per showing, placement per entry point. |
| `OFFER_ENGINE_ENABLED` (`offerEngineEnabled`) | The app asks `GET /offers` (first frame, resume, flag turning on, after a purchase / unlock / boost; at most once per 2 minutes unless forced) and drives four passive surfaces from the one offer: visitor recall card, profile VIP banner, Moments "Go VIP" chip, Matches empty-state Boost/VIP buttons. A surface the offer does not name is hidden; the offer drops at `validUntil`. Events of an engine flow carry `offerId`; the `shown` event carries the surface id in `detail`. The visitors screen sends `?seen=1`. |
| `VISITOR_PUSH_MASK_ENABLED` (no app key) | Server-only. A masked visit push (`screen: visitors`, `masked: 'true'`, no `userId`) opens `/visitors`. The route is in this build, with no flag. |

## 3. Flag-off check (both switches false, today's production): evidence

Verified by reading the code and by grep (`grep -rn "paywallEventsURL\|offersURL\|PaywallApi\|OffersApi\|seen=1" lib/`). Paths are under `bananatalk_app/`.

**Every place that can call `POST /purchases/paywall-events`.** There is exactly one: `PaywallApi.send` (`lib/services/paywall/paywall_api.dart:13`, `Endpoints.paywallEventsURL` defined at `lib/service/endpoints.dart:50`). Its only caller is the tracker's `send` (`lib/services/paywall/paywall_tracker.dart:120-121`). The tracker is reached only through `paywallLog` (`:142`), which returns before reading the tracker provider while `paywallEventsEnabledProvider` is false (`:146`), so with the flag off the tracker is never built. The tracker sends only from `flush()` (`:71`), whose only callers are `log()` at queue size 20 (`:64`), the 10 s timer set in `log()` (`:68`), and `_PauseFlush` on app pause (`:111`). Both `log()` (`:50`) and `flush()` (`:74`) re-check `enabled` first and drop the queue when it is false; `enabled` reads `paywallEventsEnabledProvider` (`:121`), which is false while app-config is loading, errored, absent, or the key is false (`lib/providers/provider_root/app_config_providers.dart:47-52`; parser `json['paywallEventsEnabled'] == true`, `lib/models/app_config.dart:220`). A disposed tracker (sign-out) drops its queue and stops a flush between chunks. So with the flag off nothing is built, queued or sent, including a queue left from earlier in the run when the flag was on.

**Every place that can call `GET /offers`.** There is exactly one: `OffersApi.fetch` (`lib/services/offers/offers_api.dart:17`, not deduplicated, `Endpoints.offersURL` at `endpoints.dart:52`), called only from `OffersNotifier.refresh` (`lib/services/offers/offers_provider.dart:62`). Before any request `refresh` returns on `if (!_enabled()) return;` (`offers_provider.dart:56`; the lapsed-offer drop above it touches only local state, which is always null with the engine off); `_enabled` reads `offerEngineEnabledProvider` (`:97`), same shape as above. Its callers: first frame `lib/pages/menu_tab/TabBarMenu.dart:150`; resume `lib/main.dart:289` via `refreshOffersIfSignedIn` (`main.dart:285`, called at `:326`; also token-guarded); the flag listener `offers_provider.dart:102` (fires only when the flag turns true); `refreshOffersAfterPurchase` (`offers_provider.dart:226`) from `vip_payment_screen.dart:248,459`, `coin_shop_screen.dart:159`, `boost_screen.dart:156`, `unlock_cta.dart:196`. Every one goes through the same guard, so with the engine off no request is made.

**Where `seen=1` is added.** One place: `ProfileVisitorService.getProfileVisitors` adds `seen=1` only when its `seen` argument is true (`lib/services/profile_visitor_service.dart:89`; the argument defaults to false). The only caller that passes it is the visitors screen, `lib/pages/profile/visitors_screen.dart:126`, with `seen = config?.offerEngineEnabled ?? false` (`:118`), so it is false when the engine is off, when app-config fails, and when the key is absent. The recall card (`lib/pages/community/widgets/visitor_recall_card.dart:33,71`) calls the fetcher with no `seen`, and hands the same default to the visitors screen it pushes (`:188`; its `flow` is null unless the gate is Show, `:189`). `seen=1` appears nowhere else in `lib/`.

**The Legacy branch of each surface.** `offerGateProvider` returns `OfferGateLegacy` first when the engine is off (`offers_provider.dart:133`). No surface branches on Legacy by name: each hides only on `OfferGateHidden` and otherwise builds today's widget, so Legacy builds the pre-engine tree.

| Surface | Code | Legacy behaviour |
|---|---|---|
| Visitor recall card | `visitor_recall_card.dart:56-58` (load unless Hidden), `:157-164` (`ref.listen`; shrink only on Hidden), `:168-169` (`offerFlow`/`offerLead` only under Show) | Loads and draws as before; tap pushes the visitors screen as before; no engine `cta_*` / `shown`. |
| Profile VIP banner | `lib/widgets/vip_upsell_banner.dart:26-28`; call site `lib/pages/community/single/single_community_overview.dart:35-36` (gap dropped only on Hidden) | VIP check first (unchanged), then today's banner and today's 16 px gap. |
| Moments "Go VIP" chip | `lib/pages/moments/feed/moments_main.dart:809-811` | Today's chip. (The added `Key('moments-go-vip')` is a test seam only.) |
| Matches empty state | `lib/pages/community/tabs/matches_tab.dart:549-551` (`showButtons = showBoost && gate is! OfferGateHidden`), pair at `:576` | Boost and VIP buttons drawn exactly when `boostsEnabled` allows, as today. |

`OfferShownReporter` (which logs `shown`) is built only under Show, so it is not in the tree with the engine off. Under Show it logs only while its route is current and, for a surface inside a top-level tab, while that tab is selected (tabs stay mounted while hidden).

**Routes pushed by the migrated sites.** `openVipPlans` / `openCoinShop` take a `PaywallRoute { material, app }` argument (`lib/services/paywall/paywall_navigation.dart`) and every site passes the class it used before (table in task-2-report.md); `Navigator.of(context)` is resolved synchronously first, or a captured navigator is passed. The pushed screens are the same `VipPlansScreen` / `CoinShopScreen` types. `test/paywall/paywall_navigation_test.dart` passes, and the existing `boost_ui_test` passes unchanged.

**Push routing.** `profile_visit` returns `/visitors` only when `data['screen'] == 'visitors'` or `data['masked'] == 'true'` (`lib/services/notification_router.dart:324-328`); a named visit push (has `userId`, neither key) still returns `/profile/<userId>` (`:329-330`). `friend_request` is split into its own unchanged case. The `/visitors` route has an async redirect to `/splash` when prefs `userId` is empty (`lib/router/app_router.dart:496`).

**Result:** no flag-safety failure found. One accepted internal difference with the flags off: the three refresh entry points construct `offersProvider` and its listener with the engine off (no request). The two earlier ones (the tracker built on the first `paywallLog`, and `flush()` not re-checking the flag) were fixed in the final fix wave.

## 4. Order with the backend rollout

1. Backend is deployed first, every switch dark (done).
2. Release this build and let it be adopted.
3. `PAYWALL_EVENTS_ENABLED` on only after this build is in the store. Wait two weeks, then read `node scripts/paywallFunnel.js 14` on the server and save the output with the date.
4. `OFFER_ENGINE_ENABLED` on only after this build is out (it sends `?seen=1`; older builds never do, so visitors would count as new for 30 days) and the funnel shows at least 200 `shown` events. **Do not switch the engine on before this build is out.**
5. `VISITOR_PUSH_MASK_ENABLED` last, after an owner decision with the funnel numbers, and after a native read of the 18 machine-drafted push strings. Tapping the masked push does nothing in older builds, so wait until this build is widely adopted.

## 5. Device checks before release (none run yet)

Use a test server. Switch by editing `config/config.env` and `pm2 restart language-app --update-env`; the app reads app-config at start and on resume.

Events (`PAYWALL_EVENTS_ENABLED` on):
- [ ] A sandbox purchase from three different entry points (for example the Moments Go-VIP chip, a limit dialog, the visitors unlock banner; one coin purchase too). On the server `node scripts/paywallFunnel.js 1` shows each flow under the right placement (`shown` / `cta_*` / `plans_viewed` / `purchase_started` / `purchase_succeeded`), one flow id per attempt, and a cancelled attempt ends as `dismissed`, not as a failure.
- [ ] Kill the app with events queued: the queue is lost by design; nothing breaks on the next start.

Offers (`OFFER_ENGINE_ENABLED` on, events on):
- [ ] The four surfaces with the engine on and off (visitor recall card, profile banner, Moments chip, Matches empty Boost/VIP buttons): with the engine off all four look and act as the current release; with it on only the surface the offer names is drawn, and its taps log `cta_*` with the offer id.
- [ ] `shown` for an offer surface is logged only when the surface is on screen: an offer for the Moments chip while the app opens on another tab logs nothing until the Moments tab is selected.
- [ ] Unlock visitors after tapping the recall card, and buy a boost from the Matches-empty Boost button: the funnel counts the offer as converted (same flow id as its `shown`).
- [ ] Cold start with the engine on: legacy elements may flash for a moment before app-config arrives (the gate is Legacy until the flag is known); confirm it is brief and nothing logs an engine event during it.
- [ ] After the offer's `validUntil` (UTC midnight) the surface disappears without a restart, and a new offer is fetched on resume.
- [ ] Visitors screen opened with the engine on: the request carries `seen=1`; the recall card and the Community preview do not.
- [ ] A purchase or unlock refreshes the offer (the surface can change right after).

Push:
- [ ] Masked push tap from a cold start: opens the visitors list. While signed out: goes to splash (no crash). Tapped offline: the list (or the tabs), never a blank screen. A named push (with `userId`) still opens that profile.

Store and receipts (no flag):
- [ ] Prices on a cold open with the network off: the VIP plans screen shows the last saved prices at once, no spinner. A fresh install with no network shows list prices.
- [ ] Plans screen with the network on: no spinner; saved prices swap to store prices when the store answers (watch for a one-frame flash of list prices on a cold start before the saved ones load).
- [ ] The account that used to produce rejected "subscription expired" attempts no longer produces them after the first launch of this build (server logs).
- [ ] A real renewal after a lapse is still delivered (a renewed transaction for an account with an expired entry in its memory reaches verification).
- [ ] Tapping Continue on the plans screen before the store answers: goes to the payment screen as before; paying then shows the existing error if the product is not available; no crash, no double query.
- [ ] iOS: restore and a normal purchase still complete (see open item 2).

## 6. Known limits and open items

1. **Device checks above have not been run.** Store purchase wiring (VIP and coin screens), the translation sheet's limit state and the watch-ad button are not widget-testable; only their pure mappings are tested.
2. **iOS transaction finish.** Whether iOS re-emits the old transaction because the plugin's finish call fails. `completePurchase` timing was deliberately left unchanged.
3. **36 unused localization keys** after the dead-code removal (list in `docs/REMAINING_WORK.md`); remove from every `app_*.arb` and the generated files in a localization pass.
4. **Matches empty state, `lead`.** The Boost and VIP buttons share one style, so the server's lead choice (`coins` or `vip`) changes nothing visible there.
5. **Matches empty state, boosts off.** An offer for `matches_empty` while `boostsEnabled` is off draws no buttons.
6. **The backend's 18 machine-drafted push strings** (`profile_visit_masked_single` / `_bundle` in the 18 non-English notification templates) need a native read before the mask is turned on.
7. **The engine must not be switched on before this build is out** (it needs `seen=1`).
8. **OWNER DECISIONS to take before `OFFER_ENGINE_ENABLED` goes on:**
   - (a) With the engine on, people who get no offer (VIPs, accounts under 48 hours, recent coin buyers) lose the visitor recall card and the Matches-empty Boost shortcut, which everyone sees today.
   - (b) `profile_banner` draws only on a VIP partner's profile, so with almost no VIPs a reserved `profile_banner` day shows nothing.
   - (c) A pending purchase that never confirms counts as a conversion.
9. **Smaller notes from the tasks:**
   - `GET /offers` goes through `ApiClient.get`, which has no opt-out of the global rate-limit toast; a 429 with the engine on would show it.
   - The flag listener can call `refresh()` with no token if the flag flips after sign-out; it would get a 401. Resume and first-frame paths are token-guarded or run when signed in.
   - With the engine on, the gate is Legacy until app-config arrives, so legacy elements can show for the first moments of a cold start.
   - With an unavailable store, the price provider returns an empty list rather than an error, so the plans retry state is reachable only when the provider throws.
   - `initializeStore` with an available store and no products repeats `isAvailable()` and the query on each call until products arrive (bounded to one flight).
   - A plan switch logs `purchase_started` after the switch call returns.
   - Several new tests were written after the code (no red-first run); revert or mutation checks were used instead (per task in `.superpowers/sdd/2026-11-14-monetization-offers-plan-d2-app/`).
   - `scripts/paywallFunnel.js` (server) has never run against a real database; its first run is its test.
10. **Known gaps in the funnel and the plans screen:**
   - Placements whose entry point is always visible (`extra_matches`, `coin_entry`, `ad_removal`, `nearby_radius`, `country_filter`, and `vip_entry` / `matches_empty` with the engine off) log no `shown`, so the funnel shows taps and purchases for them but no conversion rate.
   - Continue on the VIP plans screen is reachable before the store answers (design section 6 said the button stays disabled) and ends in the payment screen's existing error.
   - The visitors and boost screens opened from an offer log their own `shown` on the offer flow too, so that flow carries two `shown` events, both with the surface id in `detail` (the screen's `shown` takes the flow's detail). Count offer impressions per flow, not per `shown` row.

## 7. Checks run on this branch

Final fix wave (I-1..I-4, M-1..M-8, D-1), on top of Task 9's HEAD f4e762d0:

- `flutter analyze`: 0 errors; the same 3 warnings, all pre-existing in tests this work did not touch: `test/chat/chat_state_edit_failed_test.dart:3:8` (unused import) and `:92:18` (unused element parameter), `test/moments/moments_main_layout_test.dart:4:8` (unused import).
- Full `flutter test`: 4,153 passed, 1 failed. The failure is `test/services/session_reset_test.dart` ("every provider in lib/ is classified user- or app-scoped"): `Expected: empty`, `Actual: ['alreadyWavedProvider', 'userMomentsPagedProvider', 'userMomentsTotalProvider']`. It fails the same way on main; the list did not grow.

Task 9 (HEAD 6c64910f): analyze 1,119 issues, 0 errors, the same 3 warnings; full test 4,136 passed, 1 failed (the same session_reset_test names).

## 8. Release steps still to do (owner)

Merge, version bump, release build (the signed build is manual; see the release how-to), store submission, the device checks above, then the server switches in the order of section 4. Not pushed, not built, no version bump.
