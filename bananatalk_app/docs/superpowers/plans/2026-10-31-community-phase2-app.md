# Community optimization — Phase 2 app Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Community in the app becomes 4 tabs — Partners · Matches (flag) · Clubs · Rooms — with Nearby/City/Gender/Topics as chips on the one Partners list, Waves behind a header icon, and the audit's P0/P1 bugs gone.

**Architecture:** The Partners list (`partnerFilterProvider`, already a global `StateNotifierProvider`, so it survives tab switches) becomes the only people list. Gender, Same city and Topic are params on `/users` (live since backend `cc5064b`); Nearby is the one chip with its own endpoint, so it swaps the list body for the existing Nearby view. Gender/City/Topics tabs and dead code are deleted. Tab identity replaces tab indices for deep links.

**Tech Stack:** Flutter, Riverpod (`StateNotifierProvider`), `flutter_test`. Imports always `package:bananatalk_app/...`.

**Spec:** `bananatalk_app/docs/REMAINING_WORK.md` → "Community optimization (audit 2026-10-30)" → "Phase 2 — App" and the owner decisions above it.

## Global Constraints

- Worktree from `origin/main` (the clubs v2 branch touches only gatherings/moments, not these files): `git -C /Users/davis/Desktop/Personal/language_exchange_flutter_application worktree add ../wt-community-p2 -b feat/community-p2 origin/main`, then work in `/Users/davis/Desktop/Personal/wt-community-p2/bananatalk_app` and run `flutter pub get`.
- Tests: `flutter test test/community/<file>_test.dart`; before the last commit `flutter test test/community test/matching test/rooms` and `flutter analyze lib/pages/community lib/providers/provider_root/community_provider.dart` (no new issues).
- Tab order: **Matches (only while `matchesLayoutEnabled`) · Partners · Clubs (gatherings; the voice-rooms tab while `gatheringsEnabled` is off, as today) · Rooms (only while `roomsEnabled`)**. Partners chips: **All · Online · Nearby · Same city · Women · Men · New · Topic ▾** (the existing segment row All · Serious · New stays; "New" is that segment).
- Reuse l10n keys `nearby`, `topics`, `waves`, `onlineNow`, `female`, `male`, `voiceRooms`. One new key `sameCity` = "Same city" in all 19 `app_*.arb` (English text in the other 18, plus a row in the native-review CSV like earlier waves), then `flutter gen-l10n`.
- Every commit updates `bananatalk_app/docs/REMAINING_WORK.md` Phase 2 items and lists what is open in the body. No `Co-Authored-By` trailer.
- Push the branch only; no release build in this plan.

## Review Focus

1. A deep link or push to Waves, Rooms, Voice or Matches (`notification_router`, promo spotlight, `/community/waves` route) must land on the right place in the new layout, including Matches while its flag is off (→ Partners) — Task 5 test.
2. Switching chips quickly (Women → Men → Same city) must show only the last chip's people, never a mix — Task 2 test (stale response dropped).
3. A viewer with no city taps Same city: the list must still show people (server ignores the param), and the chip must not look broken — Task 3 test asserts the param is sent and the list renders.
4. Pull-to-refresh while page 2 is loading must not append page 2 to the new page 1 — Task 2 test.
5. Opening the app must not fire Community requests until Community is first shown — Task 7 test.

---

### Task 1: Filter state equality, debounced search, no rebuild storm

**Files:**
- Modify: `lib/pages/community/filter/filter_state.dart` (add `==`/`hashCode` over every field, `listEquals` for topics)
- Modify: `lib/pages/community/main/community_main.dart` (search through `Debouncer(delay: Duration(milliseconds: 350))` from `lib/services/api_client.dart`; delete the `_tabController` listener that calls `setState` (~:359) and the orphan doc line ~:228; drop `ValueKey('..._$filtersKey')` keys — Partners compares by value already)
- Test: `test/community/filter_state_equality_test.dart`, `test/community/community_search_debounce_test.dart`

**Interfaces:** Produces `FilterState` with value equality (used by Tasks 2–3).

- [ ] **Step 1:** Tests — `FilterState(gender: 'female', topics: ['a'])` equals a second instance with the same values and has the same `hashCode`; differs when `topics` differ. Widget test: pump `CommunityMain` with a fake `partnerFilterProvider` notifier counting `loadWithFilters` calls, type "abc" one char per 100 ms → exactly 1 call carrying `search: 'abc'` after 350 ms.
- [ ] **Step 2:** Run both — FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run both + `test/community/community_filter_labels_test.dart` — PASS.
- [ ] **Step 5:** Commit `fix(community): value-equal filters and debounced search stop reload storms`

### Task 2: Partners list notifier — refresh, de-dupe, server hasMore, stale responses

**Files:**
- Modify: `lib/providers/provider_root/community_provider.dart` `PartnerFilterNotifier` (~:1321-1490), `getCommunityPaginated` (~:53-176)
- Test: `test/community/partner_filter_notifier_test.dart`

**Behaviour:**
- `refresh()` returns the page-1 future, keeps the current `users` until page 1 arrives (no skeleton flash), and bumps an `int _generation`; `loadMore` drops its response when the generation changed (fixes refresh-during-loadMore).
- De-dupe with a `Set<String>` of ids.
- `hasMore` from the server's `hasMore` when present, else `page < pages`.

- [ ] **Step 1:** Tests with a fake `CommunityService` (override `getCommunityPaginated`, completers per call):
  - `refresh_keeps_rows_until_page1`: state has 20 users → `refresh()` → while pending `state.users.length == 20` → after completion equals the new page.
  - `refresh_during_loadMore_drops_page2`: start `loadMore`, call `refresh`, complete loadMore then refresh → `users` equals refresh page only.
  - `stale_filter_response_dropped`: `loadWithFilters(A)`, `loadWithFilters(B)`, complete B then A → `users` are B's.
  - `uses_server_hasMore`: response JSON `{hasMore: false, pages: 5}` page 1 → `state.hasMore == false`.
- [ ] **Step 2:** Run — FAIL (first, second, fourth).
- [ ] **Step 3:** Implement; `partner_discovery_tab.dart` `onRefresh` awaits `notifier.refresh()` (~:761).
- [ ] **Step 4:** Run + `test/community/partner_topics_filter_test.dart` — PASS.
- [ ] **Step 5:** Commit `fix(community): partners refresh keeps rows, drops stale pages, trusts server hasMore`

### Task 3: Partners chips — Nearby, Same city, Women, Men, Topic ▾; server-side New

**Files:**
- Modify: `PartnerFilterParams` (+ `bool sameCity = false` in fields, `copyWith`, `==`, `hashCode`; sent as `sameCity=true`), `getCommunityPaginated` (+ `sameCity` param)
- Modify: `lib/pages/community/tabs/partner_discovery_tab.dart`: `_buildQuickFilterChips` (~:561) adds, after Online Now: Nearby (toggle `_nearbyMode`), Same city (`_quickSameCity`), Women/Men (`_quickGender` = `'female'|'male'|null`, mutually exclusive, overrides the sheet's gender), Topic ▾ (opens `showTopicPickerSheet`, sets `_quickTopicId`, chip label = topic name); delete the client-side `newUsersOnly` filter (~:378) and send `joinedWithin: '7d'` when `widget.filters['newUsersOnly'] == true`; `_hasActiveFilters` (~:950) also counts topics, topicsAtLeast, newUsersOnly, segment ≠ all and every quick chip
- Create: `lib/pages/community/widgets/topic_picker_sheet.dart` — `Future<String?> showTopicPickerSheet(BuildContext context, {String? selectedId})`, lists `topicsProvider` (move the grid from `topics_tab.dart`)
- Modify: `lib/pages/community/filter/community_filter_sheet.dart:200-221` — the count request is built from the same `PartnerFilterParams` the list sends (`PartnerFilterParams.toQuery()` added in this task and used by both `getCommunityPaginated` and `getUsersCount`), so the default `matchLanguage` and language mapping match
- Test: `test/community/partner_quick_chips_test.dart`, `test/community/filter_count_params_test.dart`

**Interfaces:** Produces `PartnerFilterParams.sameCity`, `Map<String, String> PartnerFilterParams.toQuery({required int page, required int limit, String? sort})`, `showTopicPickerSheet`.

- [ ] **Step 1:** Tests:
  - Women chip → captured params `gender == 'female'`; tap Men → `'male'`; tap Men again → `null`.
  - Same city → `toQuery()['sameCity'] == 'true'`; list renders the fake rows.
  - `newUsersOnly` filter → `joinedWithin == '7d'` and no client-side drop of a returned row whose `createdAt` is 30 days old.
  - Filter count: with no language picked, the count query contains `matchLanguage: 'true'` and the viewer's languages, identical to the list query minus `page`/`limit`/`sort`.
  - Empty result with only a topic chip set → "clear filters" button shown.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3:** Implement; add `sameCity` to the 19 arb files and run `flutter gen-l10n`.
- [ ] **Step 4:** Run + `test/community/partner_chips_test.dart`, `community_chip_bar_test.dart` — PASS.
- [ ] **Step 5:** Commit `feat(community): Nearby, Same city, Women, Men and Topic chips on Partners`

### Task 4: Nearby as a Partners chip

**Files:**
- Move + rename: `lib/pages/community/tabs/nearby_tab.dart` → `lib/pages/community/partners/nearby_partners_view.dart` (`NearbyPartnersView({required Map<String, dynamic> filters})`; no `searchQuery`)
- Modify: `partner_discovery_tab.dart` — when `_nearbyMode`, the list area renders `NearbyPartnersView`; the search icon is hidden in Nearby mode (`CommunityAppBar` gets `bool showSearch`)
- In the view: load-more pauses 5 s after a failure and shows an inline Retry (copy `PartnerFilterNotifier.loadMoreRetryPause` behaviour, ~:125); `_onWave` (~:322) uses `showSendWaveSheet` like Partners instead of pushing chat; rows use `imageUrls` from the server; delete the empty `if` (~:276)
- Test: `test/community/nearby_partners_view_test.dart` (adapt `nearby_radius_test.dart`, `nearby_profile_center_test.dart` imports)

- [ ] **Step 1:** Tests: fake service throws on page 2 → scroll to end twice within 5 s → 1 request, Retry visible; tap Retry → 2nd request. Tap wave on a row → `SendWaveSheet` shown, no route pushed.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run + the two adapted nearby tests — PASS.
- [ ] **Step 5:** Commit `refactor(community): Nearby is a Partners chip with retry pause and the shared wave sheet`

### Task 5: Four tabs, Waves in the header, Rooms with live voice rooms, identity deep links

**Files:**
- Modify: `lib/pages/community/main/community_main.dart`: `communityTabLayout({required bool matchesLayout, required bool rooms})` returns `[if (matchesLayout) matches, partners, clubs, if (rooms) rooms]`; `CommunityTabId` = `{matches, partners, clubs, rooms}`; delete `remapTabIndexForRoomsFlag`, `partnersTabIndexIfFilterless` and the int sub-tab constants; one `int indexOfTab(CommunityTabId id, {required bool matchesLayout, required bool rooms})` (Matches → Partners when its flag is off, Rooms → Clubs when off); `TabBarView` children built from `communityTabLayout`
- Change: `communityPendingSubTabProvider` → `StateProvider<CommunityDestination?>` where `enum CommunityDestination { matches, partners, clubs, rooms, voiceRooms, waves }`; `waves` pushes `WavesScreen`, `voiceRooms` selects Rooms
- Update callers: `chat_list_screen.dart:1439`, `TabBarMenu.dart:245-250`, `matches_tab.dart:173`, `register_two_screen.dart:392`, `notification_router.dart:160,281-283` (`communitySubTabForType` returns `CommunityDestination?`), `app_router.dart:131,324,333`, `session_reset.dart:166`
- Create: `lib/pages/community/waves/waves_screen.dart` (`Scaffold` + `AppBar(title: l10n.waves)` + existing `WavesTab`)
- Modify: `community_app_bar.dart` — waves icon (`Icons.waving_hand_outlined`) with the `wavesUnreadProvider` badge, opens `WavesScreen`; the live-rooms pill now selects the Rooms tab
- Modify: `lib/pages/community/rooms/rooms_directory_screen.dart` — a "Live now" section on top (`voiceRooms` label + live rooms from the existing voice-rooms provider, hidden when none; tap opens the room; "See all" pushes today's voice-rooms screen)
- Modify: `community_tab_bar.dart` — labels from `communityTabLayout`
- Hold a skeleton tab strip until `appConfigProvider` has data (no reshuffle, no Partners load thrown away when Matches turns on)
- Test: `test/community/community_layout_test.dart` (replaces `rooms_tab_remap_test.dart`), update `live_rooms_pill_target_test.dart`, `gathering_router_test.dart`, notification router tests under `test/notifications`

- [ ] **Step 1:** Tests:
  - `communityTabLayout` for the 4 flag combinations: `[partners, clubs, rooms]`, `[partners, clubs]`, `[matches, partners, clubs, rooms]`, `[matches, partners, clubs]`.
  - `indexOfTab(matches, matchesLayout: false, rooms: true) == indexOfTab(partners, ...)`; `indexOfTab(rooms, rooms: false)` == clubs index.
  - `communitySubTabForType('lifecycle_waves') == CommunityDestination.waves`; widget test: setting `waves` pushes `WavesScreen`.
  - App bar shows the waves badge count from a fake `wavesUnreadProvider` (3 → "3").
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3:** Implement (CommunityMain no longer imports `GendersTab`, `CityTab`, `TopicsTab`, `NearbyTab`).
- [ ] **Step 4:** Run the listed tests + `flutter analyze lib` on touched files — PASS, no new issues.
- [ ] **Step 5:** Commit `feat(community): four tabs, waves in the header, live voice rooms inside Rooms`

### Task 6: Matches never blank; no requests from build

**Files:**
- Modify: `lib/pages/community/tabs/matches_tab.dart:276` (404 → the existing `_Empty` state with "Browse partners"); move `_maybeRollOver` / `_onBatchExhausted` calls out of `build` into `ref.listen`
- Modify: `partner_discovery_tab.dart:352,388` — the reload and top-up move from `Future(...)` in `build` to `ref.listen` / `didUpdateWidget`
- Test: `test/community/matches_empty_on_404_test.dart`

- [ ] **Step 1:** Test: fake `/matching/daily` throws a 404 `ApiException` → finds the "Browse partners" button, not an empty `SizedBox`.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS with `test/community/matches_panel_widget_test.dart`, `matches_first_session_wiring_test.dart`.
- [ ] **Step 5:** Commit `fix(community): matches shows an empty state on 404; no requests from build`

### Task 7: ApiClient for Community, lazy Community, polling only while visible

**Files:**
- Modify: `community_provider.dart` `getCommunityPaginated`, `getSingleCommunity`, `getNearbyUsers`, `getUsersCount`, and `lib/services/interaction_service.dart` `getExcludedUsers` → `ApiClient().get(endpoint, queryParams: ...)` (timeout, retry after token refresh); throw the `ApiResponse` error message once (no `'Failed to load community: Exception: '` wrapping)
- Modify: `lib/pages/menu_tab/TabBarMenu.dart:128-134` — Community page is a placeholder until `selectedTabProvider` first equals 1, then `CommunityMain` (stays built afterwards)
- Modify: the 30 s `/voicerooms` poll runs only while the Rooms tab is selected and the app is resumed
- Test: `test/community/community_lazy_load_test.dart`, `test/community/community_service_errors_test.dart`

- [ ] **Step 1:** Tests: pump `TabsScreen` on tab 0 with a fake service counting calls → 0 Community calls; select tab 1 → page-1 call made. A 500 from the fake client → error text equals the server message with no `Exception:` prefix.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS + `test/community/active_voice_room_count_test.dart`.
- [ ] **Step 5:** Commit `perf(community): load on first visit, poll voice rooms only while Rooms is open, ApiClient everywhere`

### Task 8: Delete what is no longer reachable

**Files (delete):** `lib/pages/community/tabs/genders_tab.dart`, `city_tab.dart`, `topics_tab.dart` (after Task 3 moved its grid), `lib/pages/community/card/community_card*.dart` + `test/community/community_card_layout_test.dart`, `lib/widgets/community/quick_action_buttons.dart`, `community_widgets.dart` barrel, `TopicChip` if unused after Task 3, and in `community_provider.dart`: `PaginatedCommunityNotifier` + state, `NearbyUsersParams`, `getCountriesList`, `getTopics` (if `topicsProvider` uses another path), `communityProvider` (+ its invalidates at `single_community_screen.dart:217,294`, `moment_card.dart:359`), `TopicUsersNotifier`/`topicUsersProvider` if nothing else reads them
- [ ] **Step 1:** `grep -rn "<symbol>" lib test` for each symbol → only its own file; delete.
- [ ] **Step 2:** `flutter analyze lib test` — no new errors; `flutter test test/community test/matching test/rooms` — PASS.
- [ ] **Step 3:** Commit `chore(community): remove tabs and widgets the 4-tab layout no longer reaches` with the line count removed in the body.

### Task 9: Record and push

- [ ] **Step 1:** Tick Phase 2 items in `docs/REMAINING_WORK.md`; add device-QA rows (each chip, deep links to Waves/Rooms/Matches, pull-to-refresh, offline retry, first launch makes no Community call) and the native-review row for `sameCity`.
- [ ] **Step 2:** Commit `docs: community phase 2 status`, push `feat/community-p2`. No merge to main until the owner asks (main is the next release build).
