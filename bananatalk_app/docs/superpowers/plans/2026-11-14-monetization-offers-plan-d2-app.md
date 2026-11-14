# Monetization Offers, Plan D2 (app) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app reports the whole paywall funnel, shows four passive upsell elements only when the server offers them, paints store prices at once, and stops re-sending an expired receipt at every launch.

**Architecture:** One in-memory `PaywallTracker` (batched, fire-and-forget) fed through a small `PaywallFlow` value that travels from the first view to the purchase result. Two shared helpers open the VIP screen and the coin shop. A throttled `offersProvider` holds the server's single daily offer; four widgets read a per-surface gate. Store prices are saved on the device after every successful product query. The launch redelivery path learns to tell "expired" from other failures and remembers it.

**Tech Stack:** Flutter, Riverpod, `http` via the existing `ApiClient`, `shared_preferences`, `in_app_purchase`.

**Spec:** `docs/superpowers/specs/2026-11-14-monetization-offers-design.md` (sections 4.2, 5, 6). Server side is Plan D1, already built; its contract is repeated below and is binding.

**Repo and branch:** app repo, new worktree `/Users/davis/Desktop/Personal/wt-offers-app`, branch `feat/monetization-offers-app` from `main`. Code lives in `bananatalk_app/`.

## Server contract (as built)

- `GET /api/v1/app-config` → `paywallEventsEnabled`, `offerEngineEnabled` (booleans; absent means false).
- `POST /api/v1/purchases/paywall-events`, authenticated. Body `{ events: [{ placement, action, flowId?, detail?, offerId?, clientAt? }] }`, 1 to 50 items, at most 30 calls per 15 minutes. `201 { success, stored, dropped }`; `404` when off. `flowId` must match `^[A-Za-z0-9_-]{1,40}$`; `detail` at most 40 chars.
- Placements: `visitor_list`, `conversation_cap`, `translation_cap`, `ad_removal`, `discovery_priority`, `wave_cap`, `extra_matches`, `moment_cap`, `comment_cap`, `story_cap`, `dm_cap`, `profile_view_cap`, `tutor_quota`, `study_lock`, `boost`, `nearby_radius`, `country_filter`, `vip_entry`, `coin_entry`, `not_enough_coins`, `matches_empty`, `other`.
- Actions: `shown`, `dismissed`, `converted`, `cta_vip`, `cta_coins`, `cta_ad`, `plans_viewed`, `shop_viewed`, `purchase_started`, `purchase_succeeded`, `purchase_failed`, `unlock_succeeded`.
- `GET /api/v1/offers`, authenticated → `200 { success, offers: [{ id, surface, placement, lead, validUntil }] }`, zero or one item; `404` when the engine is off. `surface` is `visitor_recall`, `profile_banner`, `moments_chip` or `matches_empty`; `lead` is `coins` or `vip`; `validUntil` is an ISO time. The app drops an offer once `validUntil` has passed.
- For an engine offer the app sends `offerId` on every event of that flow and sets `detail` to the surface id on the `shown` event.
- `GET /users/:userId/visitors?seen=1`: only the visitors screen sends `seen=1`. The recall card must not.
- Masked visit push: `data = { type: 'profile_visit', screen: 'visitors', masked: 'true', bundleSize }`, no `userId`.

## Global Constraints

- With `paywallEventsEnabled` and `offerEngineEnabled` both false (today's production), the app sends no new request and no changed request, pushes the same routes, and draws the same widgets as `main`. Parts C tasks (6, 7) and the dead-code task (8) have no flag; they must not change anything a user can see except what the task states.
- No new screens, no new dialogs, no close buttons, no new user-visible strings. If a task seems to need a new string, stop and report.
- Always `package:` imports. Never run `dart format` on a file you did not create. Stage files by path; never `git add -A`.
- Do not touch `lib/pages/moments/reels/`, `lib/providers/reels_provider.dart`, `lib/services/reel_view_tracker.dart`.
- Use `ApiClient` (`lib/services/api_client.dart`) for new requests, as `lib/services/coin_api_client.dart` does. Do not copy the raw-`http` services.
- Every new top-level provider is classified in `lib/services/session_reset.dart` (user-scoped map or app-scoped set). `test/services/session_reset_test.dart` already fails on `main` for `alreadyWavedProvider`, `userMomentsPagedProvider`, `userMomentsTotalProvider`; that list must not grow.
- Never add a Co-Authored-By or any Claude attribution line to a commit. Every commit updates `docs/REMAINING_WORK.md` and lists what is still open in its body.
- No version bump, no release build, no push to `main`.
- Tests: `flutter test <file>` while working; `flutter analyze` must stay at 0 errors with no new warnings.

## Review Focus

1. The events flag turns on or off during a session (config refresh): on means later events are sent; off means the queue is dropped and nothing is sent. (Task 1)
2. An offer reaches `validUntil` while the app is open: its widget hides without a new request. (Task 4)
3. The offers request fails or the device is offline with the engine on: the four elements are hidden, nothing throws, the rest of each screen is unchanged. (Task 4)
4. A person re-subscribes after an expired receipt was remembered: the new renewal, which has the same original transaction id, is still sent. (Task 7)
5. A saved price is corrupt, or in another currency than the store now reports: corrupt data is ignored; the store's answer replaces the saved one on screen. (Task 6)
6. Sign out, sign in as someone else in the same process: no offer, queued event or expired-receipt memory carries over. (Tasks 1, 4, 7)

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/models/app_config.dart`, `lib/providers/provider_root/app_config_providers.dart` (modify) | Two flags and their providers |
| `lib/services/paywall/paywall_flow.dart` (create) | `PaywallFlow` value and placement/action constants |
| `lib/services/paywall/paywall_tracker.dart` (create) | Queue, flush, provider, top-level `paywallLog` |
| `lib/services/paywall/paywall_api.dart` (create) | `POST /purchases/paywall-events` |
| `lib/services/paywall/paywall_navigation.dart` (create) | `openVipPlans`, `openCoinShop` |
| `lib/services/offers/offer.dart`, `offers_api.dart`, `offers_provider.dart` (create) | Offer model, request, throttled state, per-surface gate |
| `lib/services/store_price_cache.dart` (create) | Saved store prices |
| `lib/services/expired_receipt_memo.dart` (create) | Remembered expired transactions |
| Existing upsell widgets, screens, purchase services (modify) | Call the above |
| `test/paywall/`, `test/offers/`, `test/purchases/` | Tests |
| `docs/releases/monetization-offers-app-handoff.md` (create) | Handoff and device checks |

---

### Task 1: Flags and the paywall tracker

**Files:**
- Modify: `lib/models/app_config.dart`, `lib/providers/provider_root/app_config_providers.dart`, `lib/services/session_reset.dart`, `lib/utils/endpoints.dart` (or wherever `Endpoints.coinsBalanceURL` lives)
- Create: `lib/services/paywall/paywall_flow.dart`, `paywall_tracker.dart`, `paywall_api.dart`
- Test: `test/paywall/paywall_flags_test.dart`, `test/paywall/paywall_tracker_test.dart`

**Interfaces (Produces):**

```dart
// app_config
final bool paywallEventsEnabled;   // json['paywallEventsEnabled'] == true
final bool offerEngineEnabled;     // json['offerEngineEnabled'] == true
final paywallEventsEnabledProvider = Provider<bool>(...);   // same shape as communityFastListEnabledProvider
final offerEngineEnabledProvider = Provider<bool>(...);

// paywall_flow.dart
class PaywallPlacement { static const visitorList = 'visitor_list'; ... one const per server placement }
class PaywallAction { static const shown = 'shown'; ... one const per server action }
class PaywallFlow {
  const PaywallFlow({required this.placement, required this.flowId, this.offerId, this.detail});
  factory PaywallFlow.start(String placement, {String? detail, String? offerId});   // new flowId
  final String placement; final String flowId; final String? offerId; final String? detail;
}

// paywall_tracker.dart
typedef PaywallSend = Future<bool> Function(List<Map<String, dynamic>> events);
class PaywallTracker {
  PaywallTracker({required PaywallSend send, required bool Function() enabled,
      DateTime Function()? now, Duration flushAfter = const Duration(seconds: 10), int maxQueue = 20});
  void log(PaywallFlow flow, String action, {String? detail});
  Future<void> flush();
  void dispose();
}
final paywallTrackerProvider = Provider<PaywallTracker>(...);          // user-scoped in session_reset
void paywallLog(PaywallFlow flow, String action, {String? detail});    // reads appProviderContainer; never throws
```

Rules:

- `flowId`: 22 url-safe characters from `Random.secure()`.
- `log` when `enabled()` is false: drops the whole queue, cancels the timer, sends nothing.
- `log` when enabled: appends `{placement, action, flowId, detail?, offerId?, clientAt}` (`detail` is the call's argument, else the flow's; cut to 40 chars; `clientAt` ISO UTC); starts the 10-second timer if none runs; flushes at once when the queue reaches 20.
- `flush`: takes the whole queue (in chunks of at most 50), calls `send`; a false result or a throw drops that chunk. No retry, nothing on disk.
- The provider flushes when the app leaves the foreground, with the same observer shape as `_PauseFlush` in `lib/services/feed_open_tracker.dart`, and disposes the tracker with the provider.
- `PaywallApi.send` posts `{events}` with `ApiClient().post(..., suppressRateLimitToast: true)` and returns `res.success`.

- [ ] **Step 1: Write the failing tests.** Flags test mirrors `test/community/community_fast_list_flag_test.dart` for both flags. Tracker test (fake `send` collecting batches, `fakeAsync` for the timer):

```dart
test('nothing is queued or sent while the flag is off', () { ... expect(sent, isEmpty); });
test('events flush after 10 seconds in one batch', () {
  fakeAsync((a) {
    t.log(PaywallFlow(placement: 'wave_cap', flowId: 'f1'), 'shown');
    t.log(PaywallFlow(placement: 'wave_cap', flowId: 'f1'), 'cta_vip', detail: 'x' * 60);
    a.elapse(const Duration(seconds: 9)); expect(sent, isEmpty);
    a.elapse(const Duration(seconds: 1));
    expect(sent.single.length, 2);
    expect(sent.single[1]['detail'].length, 40);
    expect(sent.single[0].keys, containsAll(['placement', 'action', 'flowId', 'clientAt']));
    expect(sent.single[0].containsKey('offerId'), isFalse);
  });
});
test('the 20th event flushes at once', ...);
test('more than 50 queued events go out in chunks of at most 50', ...);
test('a failed send drops the batch and the next event starts a fresh one', ...);
test('turning the flag off drops what is queued', ...);
test('turning the flag on mid-session starts sending', ...);
test('a flow started twice has two different ids of 22 url-safe characters', ...);
test('paywallLog never throws when the container is unavailable', ...);
```

- [ ] **Step 2: Run** `flutter test test/paywall/`. Expected: FAIL (files missing).
- [ ] **Step 3: Implement.** Classify `paywallTrackerProvider` as user-scoped; the two flag providers go where `communityFastListEnabledProvider` is classified.
- [ ] **Step 4: Run** `flutter test test/paywall/ test/services/session_reset_test.dart`. Expected: `test/paywall/` passes; the session reset test fails only with the three known names.
- [ ] **Step 5: Commit** `feat(paywall): event tracker behind paywallEventsEnabled (off)`.

---

### Task 2: One way to open the VIP screen and the coin shop

**Files:**
- Create: `lib/services/paywall/paywall_navigation.dart`
- Modify: `lib/pages/vip/vip_plans_screen.dart`, `lib/pages/vip/vip_payment_screen.dart`, `lib/pages/coins/coin_shop_screen.dart`, and every file that constructs `VipPlansScreen(` (27 sites) or `CoinShopScreen(` (6 sites)
- Test: `test/paywall/paywall_navigation_test.dart`, `test/paywall/paywall_open_scan_test.dart`

**Interfaces:**
- Consumes: `PaywallFlow`, `PaywallAction`, `paywallLog` (Task 1).
- Produces:

```dart
enum PaywallRoute { material, app }   // MaterialPageRoute or AppPageRoute, whichever the site uses today
Future<T?> openVipPlans<T>(BuildContext context, PaywallFlow flow,
    {String? userId, PaywallRoute route = PaywallRoute.material, bool logCta = true, NavigatorState? navigator});
Future<T?> openCoinShop<T>(BuildContext context, PaywallFlow flow,
    {PaywallRoute route = PaywallRoute.material, bool logCta = true, NavigatorState? navigator});
// screens gain an optional flow:
VipPlansScreen({Key? key, this.userId, this.flow});
VipPaymentScreen({..., this.flow});
CoinShopScreen({super.key, this.flow});
```

Rules:

- `openVipPlans` logs `cta_vip` on the flow (unless `logCta` is false), then pushes `VipPlansScreen(userId: userId, flow: flow)` with the requested route type. `openCoinShop` does the same with `cta_coins` and `CoinShopScreen(flow: flow)`.
- `VipPlansScreen` logs `plans_viewed` once in `initState`; `CoinShopScreen` logs `shop_viewed` once. A null `flow` becomes `PaywallFlow.start(PaywallPlacement.other)`.
- `VipPlansScreen` passes its flow to `VipPaymentScreen`.
- Each migrated site keeps its current route type, its current `userId` argument (null, `''` or an id, exactly as today), and whatever it awaits or pops today.
- Placement and `detail` per site:

| Site | Placement | `detail` |
|---|---|---|
| `limit_exceeded_dialog.dart` VIP button | by limit type: moment `moment_cap`, comment `comment_cap`, story `story_cap`, message/dm `dm_cap`, profile view `profile_view_cap`, wave `wave_cap`, anything else `other` | the limit type |
| `persona_upgrade_sheet.dart`, `quota_banner.dart` | `tutor_quota` | file's widget name |
| `study_upgrade_sheet.dart`, `vip_locked_feature.dart` overlay (`ai_tools_tab`) | `study_lock` | feature slug if known |
| `translate_unlock_sheet.dart`, `translation_bottom_sheet.dart` | `translation_cap` | `chat_sheet` / `bottom_sheet` |
| `api_error_handler.dart` `handleLimitExceededError` | new optional `placement` parameter, default `other`; `create_moment` passes `moment_cap`, `create_comment` `comment_cap`, `chat_conversation_screen` `dm_cap` | `api_error` |
| `masked_person_tile.dart` Go VIP, `visitors_screen.dart` banner | `visitor_list` (the tile gains an optional `placement` parameter, default `other`; `waves_tab` leaves the default) | `masked_tile` / `unlock_banner` |
| `matches_tab.dart` empty-state VIP | `matches_empty` | `vip_button` |
| `ad_widgets.dart` `RemoveAdsButton` | `ad_removal` | |
| `nearby_partners_view.dart` | `nearby_radius` | |
| `community_filter_sheet.dart` | `country_filter` | |
| `chat_input_section.dart` `_MessageLimitIndicator` | `dm_cap` | `indicator` |
| `vip_upsell_banner.dart` | `vip_entry` | `profile_banner` |
| `moments_main.dart` Go VIP chip | `vip_entry` | `moments_chip` |
| `vip_up_pill.dart`, `community_app_bar.dart`, `app_shell_drawer.dart`, `profile_highlights_tab.dart` | `vip_entry` | site name, at most 40 chars |
| any other `VipPlansScreen` site found by the scan | `vip_entry` | file name without extension |
| `coin_balance_pill.dart`, `TabBarMenu.dart` | `coin_entry` | `pill` / `menu` |
| `unlock_cta.dart` (both not-enough-coins paths) | `not_enough_coins` | the feature key |
| `boost_screen.dart` | `boost` | |

- Sites inside files Task 8 deletes (`feature_gate.dart` dialogs, `visitor_limit_dialog.dart`, `visitor_upgrade_screen.dart`, the dead branch of `chat_screen_wrapper.dart`, `VipPromoCard`) are migrated mechanically with placement `other`; Task 8 removes them.

- [ ] **Step 1: Write the failing tests.**

```dart
// paywall_navigation_test.dart
testWidgets('openVipPlans logs cta_vip then plans_viewed with one flow id and pushes the screen', ...);
testWidgets('openCoinShop logs cta_coins then shop_viewed', ...);
testWidgets('logCta: false logs only the viewed event', ...);
testWidgets('a screen built without a flow reports placement other', ...);
testWidgets('PaywallRoute.app pushes an AppPageRoute, material a MaterialPageRoute', ...);

// paywall_open_scan_test.dart (template: test/ads/interstitial_cap_wiring_test.dart)
test('only paywall_navigation.dart constructs VipPlansScreen or CoinShopScreen', () {
  // regex \b(VipPlansScreen|CoinShopScreen)\( over lib/**.dart, skipping the two screen files' own
  // class declarations and lib/services/paywall/paywall_navigation.dart; offenders listed as path:line
  expect(offenders, isEmpty, reason: offenders.join('\n'));
});
```

- [ ] **Step 2: Run** `flutter test test/paywall/`. Expected: the two new files FAIL.
- [ ] **Step 3: Implement** the helpers, the screen parameters, and migrate every site. Tests that pump a migrated widget and expect a `VipPlansScreen` on tap must still pass unchanged.
- [ ] **Step 4: Run** `flutter test test/paywall/ test/growth/ test/purchases/ test/community/ test/widgets/` and `flutter analyze`. Expected: PASS, 0 errors.
- [ ] **Step 5: Commit** `refactor(paywall): one helper opens the VIP screen and the coin shop`.

---

### Task 3: Report dialogs, sheets, unlocks and purchase results

**Files:**
- Modify: `lib/widgets/limit_exceeded_dialog.dart`, `lib/widgets/tutor/persona_upgrade_sheet.dart`, `lib/widgets/study/study_upgrade_sheet.dart`, `lib/pages/chat/dialogs/translate_unlock_sheet.dart`, the limit state of `translation_bottom_sheet.dart`, `lib/utils/api_error_handler.dart`, `lib/widgets/masked_person_tile.dart`, `lib/pages/profile/visitors_screen.dart`, `lib/pages/community/tabs/matches_tab.dart` (extra matches), `lib/pages/boost/boost_screen.dart` (find its path), `lib/widgets/coins/unlock_cta.dart`, `lib/pages/vip/vip_payment_screen.dart`, `lib/pages/coins/coin_shop_screen.dart`
- Test: `test/paywall/paywall_surfaces_test.dart`, `test/paywall/paywall_purchase_events_test.dart`

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces: `UnlockCta({..., PaywallFlow? flow})`; each dialog or sheet creates one `PaywallFlow.start(...)` when shown and hands the same flow to its `UnlockCta`, its ad button and `openVipPlans(..., logCta: true)`.

Rules:

- A dialog or sheet logs `shown` once when it appears, and `dismissed` when it closes without any CTA having been tapped (use the value the route completes with, or a local flag; one of the two events `dismissed` / `cta_*`, never both for one showing unless the person taps a CTA and comes back, in which case no `dismissed`).
- `UnlockCta`: tap logs `cta_coins`; unlock success logs `unlock_succeeded` with `detail` = feature key; a 402 goes to `openCoinShop` with a flow of placement `not_enough_coins` that keeps the same `flowId`. Without a `flow` it starts one with placement by feature key: `translation` `translation_cap`, `moment` `moment_cap`, `dm` `dm_cap`, `wave` `wave_cap`, `extra_matches` `extra_matches`, `who_waved` `visitor_list`, tutor chip keys `tutor_quota`, anything else `other`.
- Rewarded path in `limit_exceeded_dialog.dart`: tapping watch-ad logs `cta_ad`; `outcome.result == 'unlocked'` logs `unlock_succeeded` with `detail` `ad:<feature>`.
- Masked tile on the visitors screen and the visitors unlock banner: `shown` once per screen visit (not per tile), placement `visitor_list`.
- Boost screen: `shown` on open with placement `boost`; a successful boost purchase logs `unlock_succeeded` with `detail` `boost`.
- `VipPaymentScreen`, on the flow it was given: `purchase_started` (`detail` = product id) when the store purchase is requested; `purchase_succeeded` where it sets `PurchaseState.success` today (iOS and Android); `purchase_failed` on a verify failure or a caught error (`detail` = `verify` or `error`); a null purchase result (cancel) logs `dismissed`.
- `CoinShopScreen`: the same four points around `_purchase` (`detail` = pack product id; failure `detail` `verify` / `error`).
- Existing Firebase `AnalyticsService` calls stay as they are.
- With the flag off none of this produces a request (Task 1 guarantees it); do not add extra flag checks at call sites.

- [ ] **Step 1: Write the failing tests** with a recording tracker overriding `paywallTrackerProvider`:

```dart
testWidgets('limit dialog: shown, then dismissed on "Maybe later"', ... expect(actions, ['shown', 'dismissed']));
testWidgets('limit dialog: VIP button logs cta_vip and no dismissed, placement follows the limit type', ...);
testWidgets('wave limit dialog reports wave_cap', ...);
testWidgets('UnlockCta success logs cta_coins then unlock_succeeded with the feature key', ...);
testWidgets('UnlockCta 402 opens the shop as not_enough_coins with the same flow id', ...);
testWidgets('watch-ad logs cta_ad and, when unlocked, unlock_succeeded ad:<feature>', ...);
testWidgets('persona sheet, study sheet, translate sheet each log shown once', ...);
testWidgets('visitors screen with masked rows logs one shown for visitor_list', ...);
test('vip purchase: started, succeeded carry the plan product id and the flow id from the entry point', ...);
test('vip purchase cancel logs dismissed; verify failure logs purchase_failed verify', ...);
test('coin purchase: started then succeeded; failure logs purchase_failed', ...);
```

Where a screen's purchase logic cannot be driven in a widget test, extract the smallest pure function that maps an outcome to the event and test that; say so in the report.

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/paywall/ test/growth/ test/purchases/ test/widgets/` and `flutter analyze`. Expected: PASS, 0 errors.
- [ ] **Step 5: Commit** `feat(paywall): dialogs, unlocks and purchases report to the funnel`.

---

### Task 4: Server-decided offers on four surfaces

**Files:**
- Create: `lib/services/offers/offer.dart`, `offers_api.dart`, `offers_provider.dart`
- Modify: `lib/pages/community/widgets/visitor_recall_card.dart`, `lib/widgets/vip_upsell_banner.dart` (and its call site `single_community_overview.dart`), `lib/pages/moments/feed/moments_main.dart` (chip only), `lib/pages/community/tabs/matches_tab.dart` (`_Empty` buttons), `lib/pages/profile/visitors_screen.dart`, `lib/services/profile_visitor_service.dart`, `lib/pages/menu_tab/TabBarMenu.dart`, `lib/main.dart` (resume), `lib/services/session_reset.dart`, `lib/widgets/coins/unlock_cta.dart`, `lib/pages/vip/vip_payment_screen.dart`, `lib/pages/coins/coin_shop_screen.dart`
- Test: `test/offers/offers_provider_test.dart`, `test/offers/offer_surfaces_test.dart`

**Interfaces:**
- Consumes: flags and tracker (Task 1), helpers (Task 2).
- Produces:

```dart
class Offer { final String id, surface, placement, lead; final DateTime validUntil;
  static Offer? fromJson(Object? json);   // null on any missing or malformed field
  bool isValid(DateTime now); }
class OfferSurface { static const visitorRecall = 'visitor_recall', profileBanner = 'profile_banner',
  momentsChip = 'moments_chip', matchesEmpty = 'matches_empty'; }

class OffersNotifier extends StateNotifier<Offer?> {
  Future<void> refresh({bool force = false});   // at most one request per 2 minutes unless force; never throws
}
final offersProvider = StateNotifierProvider<OffersNotifier, Offer?>(...);   // user-scoped

sealed class OfferGate {}            // or three-value class
class OfferGateLegacy extends OfferGate {}     // engine off: behave as today
class OfferGateHidden extends OfferGate {}     // engine on, no valid offer for this surface
class OfferGateShow extends OfferGate { final Offer offer; final PaywallFlow flow; }
final offerGateProvider = Provider.family<OfferGate, String>(...);   // key: surface id
```

Rules:

- `refresh` does nothing when `offerEngineEnabled` is false. A failed, non-200 or malformed answer sets the state to null. `OffersApi` uses `ApiClient().get` with `deduplicate: true`.
- Called (not awaited): once after the first frame of `TabBarMenu` (next to `installPurchaseRedelivery`), on app resume (next to `refreshAppConfig`), and with `force: true` after a successful VIP purchase, coin purchase, unlock or boost.
- `offerGateProvider(surface)`: engine off → `Legacy`. Engine on → `Show` when the state's offer has that `surface` and `isValid(now)`, else `Hidden`. A timer set for `validUntil` re-evaluates the gate so an expired offer hides without a request.
- `OfferGateShow.flow` is one `PaywallFlow` per offer id for the life of the process (`placement` = offer's, `offerId` = offer id, `detail` = surface id). Each surface logs `shown` once per offer id per process when it actually builds visible.
- Surfaces:
  - **Recall card:** `Legacy` → today. `Hidden` → `SizedBox.shrink()` and no visitors request. `Show` → today's card; tapping the card logs `cta_coins` when `lead == 'coins'` else `cta_vip`, then opens the visitors screen as today. Avatar taps are unchanged and log nothing.
  - **Profile banner** and **Moments chip:** `Hidden` → not drawn (the VIP badge branch of the chip is untouched); `Show` → today's widget, opening through `openVipPlans(..., flow, logCta: true)`.
  - **Matches empty state:** only the Boost and VIP buttons are gated; the rest of the empty state always draws. `Show`: the Boost tap logs `cta_coins`, the VIP tap goes through `openVipPlans` with the offer flow. `lead` decides which of the two existing button styles each button gets (lead button takes the style the VIP button has today); no new styles.
- Visitors screen: `getProfileVisitors` gains `bool seen = false` adding `seen=1`; the screen passes `seen: true` only when `offerEngineEnabled` is true. The recall card never passes it.
- Sign-out: `offersProvider` is user-scoped, so the next user starts with no offer.

- [ ] **Step 1: Write the failing tests.**

```dart
// offers_provider_test.dart (fake api, fake clock)
test('engine off: refresh makes no request and every gate is Legacy', ...);
test('a valid offer shows its surface and hides the other three', ...);
test('two refreshes inside 2 minutes make one request; force makes a second', ...);
test('a failed or malformed answer leaves every gate Hidden and does not throw', ...);
test('an offer past validUntil is Hidden without a new request', ...);          // advance the clock
test('Offer.fromJson returns null for a missing id, unknown shape or bad date', ...);
test('one flow per offer id: same flowId across reads, new id for a new offer', ...);

// offer_surfaces_test.dart (widget tests overriding offerGateProvider and the tracker)
testWidgets('recall card: Hidden draws nothing and requests no visitors', ...);
testWidgets('recall card: Show logs shown once with offerId and detail visitor_recall, tap logs cta_vip', ...);
testWidgets('recall card: Legacy fetches and draws as today', ...);
testWidgets('profile banner and moments chip: Hidden not drawn, Legacy drawn for a non-VIP', ...);
testWidgets('matches empty: Hidden keeps the empty state but drops both buttons', ...);
testWidgets('matches empty: lead coins logs cta_coins on the Boost tap', ...);
testWidgets('visitors screen sends seen=1 only with the engine on', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/offers/ test/paywall/ test/community/ test/matching/ test/services/session_reset_test.dart` and `flutter analyze`. Expected: PASS except the three known session-reset names; 0 errors.
- [ ] **Step 5: Commit** `feat(offers): four passive upsell elements follow the server's daily offer (offerEngineEnabled, off)`.

---

### Task 5: A masked visit push opens the visitors screen

**Files:**
- Modify: `lib/services/notification_router.dart`, `lib/router/app_router.dart`
- Test: `test/notifications/profile_visit_route_test.dart`

**Interfaces:**
- Produces: go_router route `/visitors` building `ProfileVisitorsScreen(userId: <signed-in user id>)`; when no user is signed in it redirects the way other signed-in-only routes do.

Rules: in `targetPathForType`, `profile_visit` returns `/visitors` when `data['screen'] == 'visitors'` or `data['masked'] == 'true'`; otherwise today's behaviour (`/profile/$userId`, or null without a `userId`). `friend_request` is unchanged.

- [ ] **Step 1: Write the failing test:**

```dart
test('masked visit push opens the visitors list', () {
  expect(NotificationRouter.targetPathForType('profile_visit',
      {'screen': 'visitors', 'masked': 'true', 'bundleSize': 2}), '/visitors');
});
test('named visit push still opens the visitor', () {
  expect(NotificationRouter.targetPathForType('profile_visit', {'userId': 'u1', 'screen': 'profile'}), '/profile/u1');
});
test('a visit push with neither opens nothing, as before', () {
  expect(NotificationRouter.targetPathForType('profile_visit', {}), isNull);
});
test('friend_request is unchanged', ...);
```

- [ ] **Step 2: Run.** Expected: first test FAILS.
- [ ] **Step 3: Implement** the route and the case.
- [ ] **Step 4: Run** the file plus `test/growth/boost_ui_test.dart`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(notifications): a masked visit push opens the visitors list`.

---

### Task 6: Prices on first paint, and a failed price query is retried

**Files:**
- Create: `lib/services/store_price_cache.dart`
- Modify: `lib/services/ios_purchase_service.dart`, `lib/services/android_purchase_service.dart`, `lib/providers/provider_root/vip_provider.dart`, `lib/pages/vip/vip_price.dart`, `lib/pages/vip/vip_plans_screen.dart`, `lib/pages/coins/coin_shop_screen.dart`, `lib/services/session_prefs.dart`, `lib/services/session_reset.dart`
- Test: `test/purchases/store_price_cache_test.dart`, `test/purchases/vip_price_text_test.dart` (extend), `test/purchases/vip_plans_first_paint_test.dart`, `test/purchases/product_query_retry_test.dart`

**Interfaces (Produces):**

```dart
class SavedPrice { final String price; final String currencyCode; final double rawPrice; }
class StorePriceCache {
  static const prefsKey = 'store_prices_v1';                       // device-level: add to kDeviceLevelPrefsKeys
  Future<Map<String, SavedPrice>> read();                          // {} on missing or corrupt data
  Future<void> save(Iterable<ProductDetails> products);            // merges by product id; no-op for an empty list
}
final savedStorePricesProvider = FutureProvider<Map<String, SavedPrice>>(...);   // app-scoped
String vipPriceText(VipPlan plan, {ProductDetails? product, SavedPrice? saved});   // store, then saved, then '$<plan.price>'
```

Rules:

- Both purchase services call `StorePriceCache().save(products)` after a product query that returns a non-empty list (not awaited, errors swallowed).
- Retry: the `initializeStore` short-circuit becomes "available, subscribed **and** `_products` is not empty"; with an empty list it queries again. `loadProducts` while a query is running returns that query's future instead of returning at once. At most one query in flight.
- `VipPlansScreen`: no full-screen spinner. It builds its content at once from `productsAsync.valueOrNull`, then saved prices, then the hardcoded fallback, and rebuilds when the store answers. On open, if the products provider holds an empty list or an error it is invalidated once. The existing error/retry state is kept only for the case where the store reports it is unavailable after loading; what happens when a person taps buy before the store product exists stays exactly as today (find out what that is and pin it in a test).
- Per-month and savings figures use `rawPrice` and `currencyCode` from the store product, else from the saved price; with neither they are computed as today.
- Coin shop price text: store, then saved, then `'$<pack.usdPrice>'`.

- [ ] **Step 1: Write the failing tests.**

```dart
test('save then read returns price, currency and raw price per product id', ...);
test('corrupt JSON reads as empty and a later save repairs it', ...);
test('saving an empty list keeps what was there', ...);
test('a later save in another currency replaces the entry', ...);
test('vipPriceText prefers store, then saved, then the plan fallback', () {
  expect(vipPriceText(plan, product: null, saved: const SavedPrice(price: '₩5,500', currencyCode: 'KRW', rawPrice: 5500)), '₩5,500');
});
testWidgets('plans screen draws plan cards on the first frame while the store is still loading', ...);   // no CircularProgressIndicator scaffold
testWidgets('plans screen swaps a saved price for the store price when it arrives', ...);
test('an empty product result is queried again on the next initializeStore; a non-empty one is not', ...);
test('two loadProducts calls during one query share it', ...);
test('store_prices_v1 survives clearUserScopedPrefs', ...);
```

If the purchase services cannot be driven without the platform channel, extract the retry decision into a small pure function or injectable seam and test that; say so in the report.

- [ ] **Step 2: Run** `flutter test test/purchases/`. Expected: new tests FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/purchases/ test/models/ test/services/` and `flutter analyze`. Expected: PASS except the three known session-reset names; 0 errors.
- [ ] **Step 5: Commit** `perf(store): VIP and coin prices paint at once; a failed price query is retried`.

---

### Task 7: An expired receipt is sent once, not at every launch

**Files:**
- Create: `lib/services/expired_receipt_memo.dart`
- Modify: `lib/services/purchase_redelivery.dart`, `lib/services/purchase_restorer.dart`, `lib/providers/provider_root/purchase_restore_provider.dart`, `lib/services/vip_service.dart`
- Test: `test/purchases/purchase_redelivery_test.dart` (extend), `test/purchases/expired_receipt_memo_test.dart`

**Interfaces (Produces):**

```dart
class RestoreVerifyResult { ...; final bool expired; }           // existing class gains the field (default false)
bool isExpiredVerifyError(Object? error);                         // true when the text contains 'expired', any case
bool clearlyLapsed(RestoredPurchase p, DateTime now);             // the restorer's private check, made public and reused
class ExpiredReceiptMemo {
  ExpiredReceiptMemo({required String userId, SharedPreferences? prefs});
  static String keyFor(RestoredPurchase p);   // '<transactionId or receipt hash>|<renewedAt ms or 0>'
  Future<bool> contains(RestoredPurchase p);
  Future<void> add(RestoredPurchase p);       // keeps the newest 50
}
// PurchaseRedelivery: verifySubscription becomes Future<RestoreVerifyResult> Function(RestoredPurchase);
// new optional deps: Future<bool> Function(RestoredPurchase)? isKnownExpired, Future<void> Function(RestoredPurchase)? rememberExpired,
//                    bool Function(RestoredPurchase)? isLapsed
enum RedeliveryAction { ..., skippedKnownExpired, skippedLapsed }
```

Rules for `_handleSub`, in order:

1. VIP active and `verifyWhenVipActive` false → `skippedAlreadyVip` (today).
2. `isKnownExpired(purchase)` true → `skippedKnownExpired`, no request.
3. `isLapsed(purchase)` true → `rememberExpired`, then `skippedLapsed`, no request. `installPurchaseRedelivery` passes `isLapsed` only on iOS, like `checkExpiry` in the manual restore.
4. Otherwise verify. Success → today. Failure with `expired` true → `rememberExpired`, then `verifyFailed`. Any other failure → `verifyFailed`, nothing remembered.

- The memo is stored under `expired_receipts_v1_<userId>` (not device-level, so sign-out clears it). No signed-in user → no memo, behave as today.
- The key includes `renewedAt`, so a later renewal of the same subscription has a different key and is sent.
- `VipService.verifyIOSPurchase` / `verifyAndroidPurchase` keep their return maps and add `statusCode`; `verifySubscriptionWithBackend` sets `expired` from `isExpiredVerifyError(result['error'])`.
- The manual Restore button and a purchase made on the payment screen never consult the memo.
- Not changed: when iOS finishes a transaction (`completePurchase`).

- [ ] **Step 1: Write the failing tests.**

```dart
test('an expired answer is remembered and the same transaction is not sent again', () async {
  // verify returns failure(expired: true) -> verifyFailed, calls == 1; second delivery -> skippedKnownExpired, calls still 1
});
test('a network failure is not remembered; the next launch tries again', ...);
test('a lapsed purchase is skipped without a request and remembered', ...);
test('a renewal with the same transaction id but a later renewedAt is sent', ...);
test('an active VIP still short-circuits first', ...);
test('without the new dependencies the handler behaves exactly as before', ...);     // existing 10 cases keep passing
test('memo keeps the newest 50 keys', ...);
test('memo for one user is invisible to another', ...);
test('isExpiredVerifyError: "Subscription has expired" true, "Purchase verification failed" false, null false', ...);
```

- [ ] **Step 2: Run** `flutter test test/purchases/`. Expected: new tests FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/purchases/` and `flutter analyze`. Expected: PASS, 0 errors.
- [ ] **Step 5: Commit** `fix(purchases): an expired subscription receipt is sent once, not at every launch`.

---

### Task 8: Remove dead upsell code

**Files:**
- Delete: `lib/widgets/visitor_limit_dialog.dart`, `lib/pages/vip/visitor_upgrade_screen.dart`, `lib/services/daily_chat_limit_service.dart`
- Modify: `lib/utils/feature_gate.dart` (remove `showLimitReachedDialog`, `_showUpgradeDialog`, `wrapWithFeatureGate`, `_buildLockedFeature`), `lib/widgets/vip_upsell_banner.dart` (remove `VipPromoCard`), `lib/widgets/vip_locked_feature.dart` (remove `VipLockBadge`, and `VipUpgradeSheet` if the chat wrapper was its only user), `lib/pages/chat/chat_screen_wrapper.dart` (remove `_chatLimitReached` and its unreachable branch), `lib/services/notification_router.dart` (stale comment), `test/l10n/hardcoded_strings_test.dart` (file lists), `test/widgets/limit_type_description_test.dart`
- Test: `test/paywall/paywall_open_scan_test.dart` still passes; add `test/paywall/dead_upsell_removed_test.dart`

Rules:

- Before deleting each symbol, grep `lib/` and `test/` and record the result in the report. A symbol with a live caller is not deleted; report it instead.
- `limitTypeDescription`: if anything live uses it, keep it (move it next to its user if its only home was a deleted method) and point `limit_type_description_test.dart` at the new place. If nothing uses it, delete it and the test.
- Localization keys used only by deleted code stay in the ARB files; list them in `docs/REMAINING_WORK.md` as cleanup.
- This is its own commit, with no behaviour change.

- [ ] **Step 1: Write** `dead_upsell_removed_test.dart`: the three files do not exist, and a scan of `lib/` finds none of `VisitorLimitDialog`, `VisitorUpgradeScreen`, `VipPromoCard`, `VipLockBadge`, `DailyChatLimitService`, `_chatLimitReached`, `wrapWithFeatureGate`. Run it: FAIL.
- [ ] **Step 2: Delete and edit.**
- [ ] **Step 3: Run** `flutter analyze` (0 errors, no new warnings) and `flutter test test/paywall/ test/l10n/ test/widgets/`. Expected: PASS.
- [ ] **Step 4: Commit** `chore(paywall): remove unreachable upsell screens and helpers`.

---

### Task 9: Whole-app check and handoff

**Files:**
- Create: `docs/releases/monetization-offers-app-handoff.md`
- Modify: `docs/REMAINING_WORK.md`

- [ ] **Step 1: Run** `flutter analyze` and the full `flutter test`. Record totals. Expected: 0 analyzer errors, the same warnings as `main`; the only failing test is `test/services/session_reset_test.dart` with the same three names as `main`.
- [ ] **Step 2: Flag-off check.** With both flags false, confirm from the code (and state it in the handoff with file references): no call to `/purchases/paywall-events` or `/offers`; `seen=1` never sent; the four surfaces take the `Legacy` path; routes pushed by the migrated sites are the same types as before.
- [ ] **Step 3: Write the handoff:** what ships, what each flag turns on, the order from the backend rollout guide (events first; engine only after this build is out, because it needs `seen=1`), device checks (a purchase in sandbox from three entry points with the funnel script showing the flow; the four surfaces with the engine on and off; a masked push tap; prices on a cold open with the network off; the expired receipt account no longer producing rejected attempts), and what is still open (iOS transaction finish behaviour, unused localization keys, native review of the server's push strings).
- [ ] **Step 4: Update** `docs/REMAINING_WORK.md`.
- [ ] **Step 5: Commit** `docs(monetization): app handoff and device checks`.
