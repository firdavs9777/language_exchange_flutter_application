# Remaining work — BananaTalk app

Last updated: 2026-10-15 (bug-fix wave). Keep this current: tick items off in the same commit that finishes them.

See also: backend `language_exchange_backend_application/docs/REMAINING_WORK.md` (server env, prod DB, flags, ops) ·
web `docs/REMAINING_WORK.md` in the web repo (admin console, `assetlinks.json`, nginx).

## 1. Status

- **App `main` = 2.7.0 (10580): NOT built, NOT tagged, NOT submitted.** Android ships first, then iOS.
  Now also includes the tab bar redesign, coffee-button removal and the AI Study hub (dark), merged 2026-10-14;
  Android audit of 2026-10-14 passed (no blockers). Notes `docs/releases/2.7.0.md`, keystore/Play steps `docs/releases/2.7.0-handoff.md` (smoke items 12–13 added).
- Live in the stores: 2.6.1 (10574, tag `v2.6.1`).
- Backend `main` 9d36fe0 (2026-10-14) and web `main` 2ce0c93 are **deployed**, so the deploy order
  backend → web → app is satisfied; 2.7.0 can ship as soon as it is built.
- All new server flags are still off (dark); see the backend file for the flag table.
- fix/moments-stories-audit merged into main (2026-10-16, web-parity P2-1); its device rows are in docs/audits/2026-10-16-web-parity/moments.md.

## 2. Owner — manual steps (in order)

1. Release build 2.7.0 (10580) on the keystore MacBook: `2.7.0-handoff.md` §1–§2 (`flutter build appbundle`, JDK 17 flag).
   On the signed bundle check `versionCode 10580`, the removed permissions are gone, and
   `aapt2 dump badging` lists no required `uses-implied-feature`. Keep `mapping.txt`.
2. Play Console → App content → **Foreground service permissions**: Microphone + Camera + Phone call
   ("ongoing 1:1 voice/video call", screen recording). Upload is REJECTED without it. Also the
   **Full-screen intent** declaration (handoff §4.1–4.2).
3. Play Console: **Data safety** (contacts and phone state no longer collected), Advertising ID = Yes (handoff §4.4–4.5).
4. **Store prices** — App Store Connect + Play Console: VIP monthly $3.99, yearly $24.99 (quarterly untouched).
5. Upload to the Play **internal testing** track, run the release-mode smoke (section 3, handoff §3), then
   staged rollout 10–20 %; watch Android vitals for R8 crashes for 24 h. Tag `v2.7.0` once accepted.
6. Paste the upload-key and Play app-signing SHA-256 into the web repo's `assetlinks.json` (web file, owner steps) — App Links stay dead until then.
7. Once 2.7.0 is live: Play Console → withdraw the **Photo & video permissions** declaration (READ_MEDIA_* removed).
8. If any internal/TestFlight build was cut from app commits a4bc467c..(before) ed37a53c, expire it.
9. iOS: commit `ios/Podfile.lock` on its own before the iOS build (`pod install` adds the missing
   `in_app_review` pod — verified 2026-10-13 it is not in the lock yet), then build + submit iOS 2.7.0.
10. **Native review** of `docs/l10n/native-qa-strings-2026-10.csv` (≈1,250 machine-drafted strings, 18 locales;
    includes the call, Phase 2, guide, biometric, onboarding strings and the ru `gatheringHostDecision` row).
    **The EULA body (terms screen) needs counsel or native review per market** — a higher bar than UI copy.
11. AdMob earnings: lifetime + last 30 days (the one revenue number not in the DB).
12. Server-side steps (flags, LiveKit webhook, `APNS_VOIP_*`, droplet `config.env`, prod queries): backend file.
13. Set `STUDY_HUB_ENABLED=true` after 2.7.0 is live (the hub ships dark in it) and QA passed (`docs/qa/study-hub-matrix.md`).

## 3. Device / production QA

**Full regression suite (whole app, 1,040 cases, one tab per area): `docs/qa/regression-suite.csv`** (also as a Google-Sheets-ready workbook). 2.7.0 release run: **`docs/qa/2.7.0-weekend-run.md`** (order, setup, flags, known failures, release-smoke rows R-1…R-12). All four matrices were re-checked against the code on 2026-10-15; rows that were wrong were corrected and ~40 rows added.

Release-mode smoke (Android, internal track — handoff §3; rows in `docs/qa/calls-matrix.md`, `docs/qa/onboarding-matrix.md`, `docs/qa/study-hub-matrix.md`):
- [ ] Incoming call, killed + locked → full-screen UI; Accept/Decline from CallKit screen and from the notification (CallKit permission is now `signature`).
- [ ] Rejoin after kill: voice call the peer upgraded → rejoins as video, own camera off, no camera prompt, no forced speaker; Video On → permission prompt, then speaker. Same for a native video call with the camera off.
- [ ] Peer upgrade: CALL2-21 and CALL2-13 (Android FGS camera type with local camera off, then on).
- [ ] Camera upgrade both directions: permission denied, server refusal rollback, speaker route after upgrade/rollback, upgrade POST timing out, upgrade racing call end.
- [ ] Decline with message: Korean/Japanese IME near 200 UTF-16 units (composition intact, cursor stays); declined to a caller who blocked you / past daily cap → "Failed to send message".
- [ ] Missed call with delayed push (airplane mode after ring starts) → exactly one notification; Call back / Message from killed / background / foreground on iOS and Android, incl. Doze and a Xiaomi/Samsung (CALL2-3…CALL2-6); 409 snack after Call back.
- [ ] iOS (AppDelegate is notification-center delegate): foreground pushes badge-only except missed-call copy; local notification tap routes; no "completion handler called twice".
- [ ] Self-view: drag/snap on small + large phones, rotation, swap with real tracks, TalkBack/VoiceOver.
- [ ] Every row of `docs/qa/calls-matrix.md` incl. §5 CALL2-1…CALL2-20 and IOS-3/IOS-5 repeat runs; decide on IOS-8 (Focus mode silences CallKit).
- [ ] Background chat push → heads-up banner, white bubble icon; system settings list "High Importance Notifications".
- [ ] Bluetooth headset during a call on Android 12+ (BLUETOOTH_CONNECT is declared, never requested — if not selectable, that is a code item).
- [ ] Photo/video pick for moment, story, chat, avatar on Android 13+ and Android 9.
- [ ] Backup: `adb shell bmgr backupnow com.bananatalk.app`, restore on a fresh install → logged out, no biometric error.
- [ ] VIP sandbox purchase; Android Manage Subscription opens Play's subscription page.
- [ ] Rewarded ad, QR scan, reel upload (video_compress), `bananatalk://` deep link.
- [ ] Biometric smoke (Android 7–8, 13+, iPhone Face ID): enable → logout → Continue as → live chat; second account by password → Continue-as gone.
- [ ] Quiet hours, phone in a non-Seoul zone, 22:00–08:00 → server `quietHours.timezone` = phone zone; pushes held in local night.
- [ ] After assetlinks deploy: `adb shell pm verify-app-links --re-verify com.bananatalk.app` then `pm get-app-links` → `verified`; only `/moment/`, `/profile/`, `/community/`, `/story/`, `/chat/`, `/i/` open the app (story/chat added in web-parity P2-2).
- [ ] Every row of `docs/qa/onboarding-matrix.md` (incl. update vs welcome-back, notification tap within 1 s).
- [ ] Guides device pass 2: re-run after the PulseHighlight ticker fix, confirm a clean log.
- [ ] Debug build: open a chat whose partner was last seen long ago (header ~99 px) → `[null-log] … from <frame>` names the source of the bare `flutter: null`; fix it or record as package noise.
- [ ] New account sends one message → `first_message_sent` observed in analytics.

- [ ] Accepted gap: a 2.7.0 profile QR (https) scanned with 2.6.1's in-app scanner shows "Invalid QR code"; the system camera opens it fine.
- [ ] Text story with poll / question / link / location (posted from web and from the app): stickers tappable, poll vote and answer work, header avatar opens the profile, reply sends (row WEB-APP-05).
After release (production data):
- [ ] One week after 2.7.0: re-measure calls answered rate (baseline 1/30, target ≥ 40 %).
- [ ] `notification_prime_shown` per new signup, before vs after (ads notice now waits for the guide period).
- [ ] `first_session_say_hi_tapped / _guidance_shown` — is the Matches header salient enough?
- [ ] `guide_cta_tapped` by `target` before adding a third destination anywhere.

## 4. Code work — open

Localization
- [x] Allowlist 103 → 17 (2026-10-15 sweep; 20 unreachable files deleted). The 17 left are all in `lib/pages/moments`, `comments`, `stories` — localize next. S–M
- [x] Localize the last 17 allowlisted files (done 2026-10-16, fix/moments-l10n-errors): image_viewer 'Rotate', reels Mute/Unmute, moment-not-found, stories 'Try again', create_moment snackbars and the voice-note retry dialog (`moment_upload_retry.dart`, ICU plural "tries left") are ARB keys; the `link_sticker_editor` 'https://' hint is allowed by design. `no_hardcoded_text_allowlist.txt` is empty. (upload_queue progress `message:` strings are never shown, so they stay.)
- [x] L14 (done 2026-10-15; property-literal guard added): ~54 property literals (`hintText:`/`labelText:`/`tooltip:`/`message:`) + enum labels listed in the 2026-10-11 sweep (image_viewer 'Rotate', word_card 'Listen', message_bubble 'Report', chat/moments snackbars, upload_queue progress…), with a property-literal guard. M
- [x] Native CallKit Accept/Decline labels and missed-call subtitle are hardcoded English (`callkit_service.dart:225`); add an "Accept" key and feed them from `notificationL10n()`. S
- [x] Coin strings are ICU plurals in all 19 locales (ru one/few/many, ar few). 
- [x] Russian number agreement (done 2026-10-16, `test/l10n/ru_plurals_test.dart`): 47 ru keys converted to one/few/many plurals ("1 просмотр / 2 просмотра / 5 просмотров", "1 минуту назад", "до 21 хештега", "увидел 1 человек"…); `views`, `minutesAgo`, `hoursAgo`, `usersWorldwide`, `usersCount`, `chatDailyLimitBody`, `learnWordsExercises` retyped String/Object → int. The rest of the ~70 were already correct (label forms "Слов: {count}", "X из {total}", abbreviations "мин"/"ч"/"дн.", fractions "{count}/500 символов"). Rows added to `docs/l10n/native-qa-strings-2026-10.csv` for native review.
- [x] `communityMembersCount` / `communityPeopleCount` number-agreed in ru (2026-10-16, fix/l10n-leftovers): `"format": "compact"` was not usable (gen-l10n would call `NumberFormat.compact(locale: 'tg')`, which throws; `number_format_locale_test` forbids it), so they follow the `clubMembers` pattern: int `count` for the plural + `countLabel` from `formatCompactNumberForLocale`. The count goes through `compactPluralCount()` (3 significant digits, like the label) so 1001 → "1 тыс. участников", not "участник". en got one/other too; other locales keep their text. Labels are now locale-aware ("1,2 тыс.", "1.2K") instead of the old "1.2k". `test/l10n/community_count_plural_test.dart`.
- [x] (2026-10-16) `clubMembers` (gatherings) had the same compact-vs-plural gap in ru: callers passed the raw `memberCount`, so 1001 read "1 тыс. участник". Now pass `compactPluralCount(club.memberCount)` in `my_gatherings_screen.dart`, `club_detail_screen.dart`, `gatherings_tab.dart`. S
- [ ] Widen the hardcoded-text guard to labels built away from their widget. Tried 2026-10-16: a third scanner for `final|var|String …title/label =` and `'label':` / `'title':` map entries finds 48 hits in lib/ — real ones in `lesson_builder_screen.dart` (6 lesson types), `ai_quiz_screen.dart` (Weak Areas / Vocab Blast / Daily Mix), `moment_filter_model.dart` (sort + time range), `moments_model.dart` (16 categories, 12 moods), `create_story_screen.dart` (Poll:/Question:), `quiz_card.dart` ("option N"); false positives from value comparisons (`g == 'male' ? l10n.male`, `switch` patterns in `personal_info_step.dart`, `voice_rooms_tab.dart`). Needs: skip literals that are `==` operands / switch patterns, then localize or snapshot the rest (most are in moments, so after the moments branch lands). Not covered either way: constructor args like `FilterChipData('…')`. M
- [x] Country names localized (2026-10-16): display-only CLDR table `lib/utils/country_names.g.dart` (18 non-English locales, regenerate with `node tool/build_country_names.js`, `--check` for staleness) used by the filter picker/chip/card, City tab, Nearby cards, `PrivacyUtils.getLocationText` callers, settings, visitors. Stored/sent values stay English. Not covered: admin screens, chat location-share address (geocoder text).
- [x] Chat wallpaper names localized (2026-10-16, fix/l10n-leftovers): 34 `wallpaperPreset*` keys × 19 locales via `wallpaperDisplayName()` (`lib/pages/chat/wallpaper/wallpaper_names.dart`); the English `label` fields are gone, stored preset ids unchanged (`test/chat/wallpaper_names_test.dart`).
- [x] Hardcoded English the guard missed (2026-10-16, fix/l10n-leftovers): City tab list titles (`cityListTitle()`, new `communityWorldwide` / `communitySearchTitle`) and filter chips (reuse `male` / `female` / `online`, new `communityFilterNew`); `test/community/community_filter_labels_test.dart`.
- [x] Friendly-error pass (done 2026-10-16, fix/friendly-errors): `friendlyErrorMessage` now keeps clean server sentences (`serverMessageOf`) and takes a `prefix:`; ~60 call sites in profile, settings, VIP, chat, community, AI tutor, exam study, lessons, voice rooms moved off `'$prefix: $e'`.
- [x] Friendly-error remainder in moments/comments/stories (done 2026-10-16, fix/moments-l10n-errors): moment card/single like, correction sheet, composer (create, queue, voice-note upload + retry reasons, video processing), comment composer, highlight create/rename/delete, comment/reply like/edit/delete, story delete, story post, archive, saved moments all render through `friendlyErrorMessage` (raw text to `debugPrint`); `moments_service`/`stories_service` return the raw `e.toString()` instead of `'Network error: $e'`. Guard: `test/moments/no_raw_error_text_test.dart`. Admin-only screens (`admin_reports_screen.dart:78`) and `livekit_test_screen` still show raw text on purpose.
- [x] English service-side sentences no longer reach the screen (done 2026-10-16, fix/service-error-text): `VideoProcessResult` carries a `VideoProcessFailure` (+ `maxDurationSeconds`) and progress is a `VideoProcessStage`; `SingleStoryResponse` carries a `StoryPostFailure`; the moment/story composers localize them via `lib/utils/media_failure_text.dart` (new key `videoTooLongMax`, rest reused). `stories_service` HTTP fallbacks ("Failed to create story (500)", "Failed to load stories/archive/highlights", "Failed to delete story") are now null or the backend's own sentence (`StoriesService.serverErrorOf`). Test: `test/moments/media_failure_text_test.dart`.
- [x] (fixed 2026-10-16, `textStoryHasContent`: blank text is fine when overlays exist) Emoji-only text stories could not be posted: `create_story_screen` sends `text: ' '` when there is no text overlay, but `StoriesService.createTextStory` refuses `text.trim().isEmpty` client-side (now shown as the localized "Please enter some text"). Let the service send the single space as the comment in the screen intends. S
- [x] Moment composer no longer sends `formattedAddress: "Location added"` (done 2026-10-16, fix/service-error-text): an empty or failed reverse lookup leaves the address null and the location goes up coordinates-only (`moment_location.dart` `momentLocationPayload`; backend `Moment.location.formattedAddress` is optional, validator only checks coordinates); the empty-placemark ", " fallback and the `'Location'` default are gone; a geocoding exception no longer fails the whole pick. The composer chip keeps the localized `locationAdded` label. Test: `test/moments/moment_location_test.dart`.
- [x] Other services no longer return `'Network error: $e'` / `'Error: $e'` (done 2026-10-16, fix/service-error-text): message_provider, report_provider, translation, bookmark, poll, conversation, correction, learning, matching, media, voice_message, block, report, notification_api_client, ai, user_limits and giphy services return the raw `e.toString()`; their screens (translation sheet, correction sheet/bubble, report dialog, reels report, AI lesson assistant/feedback/summary, vocabulary delete) render through `friendlyErrorMessage` with a localized fallback. Guard extended in `test/moments/no_raw_error_text_test.dart`.
- [x] (2026-10-16) `vip_service.dart` returns the raw error (10 sites); the payment screen shows offline / a clean server sentence / its localized generic text. `admin_provider.dart` stays raw on purpose (admin-only, allowlisted).
- [ ] VIP locks on tutor/roleplay/story/photo go through ApiClient's handler in main.dart and open `PersonaUpgradeSheet` (`triggerChip: vip_only_<slug>`), not the hub's VIP-lock sheet that Speak/Writing/Quizzes now use — decide whether to unify. S

Calls
- [x] **Rejoin after kill never happened** — fixed 2026-10-15 (91b5002d): reconcile asks `/calls/current` once and leaves an entry whose call is already `active` to `recoverCallState`; 3 reconcile-then-recover tests. Device row CALL2-23 still open. Original finding: `main.dart` runs `reconcileCallKitOnColdStart()` then `recoverCallState()`; reconcile finds the still-accepted native entry and calls `handleCallKitAccept` → `POST /accept` on a call that is already `active` → server 409 `CALL_STATE` → `_finish(acceptConflict)` ends the native entry and remembers the id, so `recoverCallState` finds no accepted entry (and `_rejoin` would skip the remembered id anyway). The peer sees "Reconnecting..." and the call ends after ~20 s. Tests only cover `recoverCallState()` alone. Fix idea: in reconcile, ask `/calls/current` first and leave an entry whose call is already `active` to `recoverCallState`. Device row: calls-matrix CALL2-23. M
- [x] Android 12+ BT headset (fixed 2026-10-15, calls batch): a local upgrade / first "Video On" calls `setSpeakerOn(true)`, which in flutter_webrtc 1.4.0 forces `Speakerphone` over a connected headset (iOS keeps BT). Prefer speaker only when no headset is connected. Device row CALL2-22. S
- [x] Request BLUETOOTH_CONNECT at runtime (done 2026-10-15) with the mic if the device QA shows the headset is not selectable on Android 12+. S

Notifications
- [x] **Android 13+ fresh installs were never asked for notification permission** — fixed 2026-10-15 (fb3dc453): Android `denied` with `notification_prompt_shown` unset → `ask`; delivery set-up (`_setUpDelivery`) now also runs after a grant from the prime. Device rows onboarding §4 still open. Original finding (since 2.4.0, 9a2368c8): firebase_messaging 15.2.10 on Android reports only authorized/denied, so "not asked yet" reads as `denied` → `NotificationAction.recover` → no priming sheet, and `NotificationService.initialize` also skips handler/local-notification set-up for `denied`. Affects chat pushes and incoming calls for every new Android 13+ user (push reach, calls answered rate). Fix idea: on Android, treat `denied` with `notification_prompt_shown` unset as `notDetermined` (Android allows the dialog twice); re-check the set-up skip. Device row: onboarding §4. M

Tab bar clearance
- [x] Fixed 2026-10-15 (ef1f9ba4, + Moments feed FAB room): every Community sub-tab, Rooms, Topics user list and Profile end on `FloatingTabBar.clearance` (+ `fabSpace` under a create FAB); FABs lift by `FloatingTabBar.fabLift`; the no-bottom-literal guard now covers them. Device row study-hub 4.8 open. Was: Community Waves (`waves_tab.dart`, vertical 8), Matches (`matches_tab.dart`, bottom 24), Gatherings (80), Nearby (100), Voice rooms (72–100) and Profile (100) use fixed bottom padding instead of `FloatingTabBar.clearance` (≈ 98 iPhone, ≈ 88 gesture, ≈ 112 3-button), so their last rows can sit under the bar. The bar ships to everyone in 2.7.0. Device row study-hub 4.8. S

Auth
- [ ] Map `SOCIAL_LOGIN_REQUIRED` (email login on a Google/Apple-only account) in `auth_error_codes.dart` if a dedicated UI is wanted; today it shows the server message. S

Monetization
- [ ] `RemoveAdsButton` only under the chat-list banner (visitors-screen banner has none). S
- [ ] Widget-test gaps: limit dialog rewarded flow end-to-end, Matches extra-matches CTA wiring, drawer rows. M

Web announcements (backend + web; **no app change**)
- [x] Show admin announcements on banatalk.com as a hero-card pop-up or a floating banner, chosen per announcement; spec `docs/superpowers/specs/2026-10-13-web-announcements-design.md`, plan `docs/superpowers/plans/2026-10-13-web-announcements.md`. Deployed 2026-10-13 (backend 8d97504, web bf9089c).
- [x] Back after logging in from an announcement link landed on /login (which bounced forward again): login, register and Google sign-in now replace the login page in history.
- [ ] QA one real web announcement as a pop-up and one as a banner, logged in and logged out. S
- [ ] Admin editor shows the App preview slot even when "Show in app and on website" is off. S
- [ ] Banner style in the app (same `displayStyle` field; the app ignores banners today). M

Android release audit 2026-10-14 (2.7.0 now includes the tab bar; hub ships dark)
- [x] Release compile + R8 pass (stops only at signing, as expected without the keystore); badging: versionCode 10580, only `faketouch` required, removed permissions absent.
- [x] AI Study cold start no longer shows a spinner (remembered flag, `StudyHubFlagCache`).
- [x] Tab bar: no rebuild per keyboard-animation frame; hidden bar excluded from TalkBack; no hide-on-scroll while TalkBack is on; unread count announced.
- [ ] 3-button navigation (Android 15, edge-to-edge): the bar's bottom ~4 dp sits in the system nav strip (`inset - 4`); consider `inset + 4` on Android after device QA. Same as the bar audited 10-13 (not a regression). S
- [ ] `FloatingTabBar.clearance` drops by the nav inset while the keyboard is open, so lists with a search field shift ~36 dp on 3-button nav. Cosmetic. S
- [ ] Below ~262 dp effective width (320 dp phone at max Display size) the bar row overflows and clips Profile. S
- [ ] TalkBack keep-visible path in `TabsScreen` has no widget test (shell not pumpable); cover in device QA.
- Note: turning `STUDY_HUB_ENABLED` off after devices cached `true` takes effect from the second launch (kill switch is one launch slow by design).

AI Study hub + floating tab bar (branch `feat/ai-study-hub`)
- [x] Design approved and spec written: `docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md`; mockup https://claude.ai/artifact/R1A8GWY8C6cqEMkfs5akEK.
- [x] Owner approved the spec as written (2026-10-14).
- [x] Implementation plan: `docs/superpowers/plans/2026-10-14-ai-study-hub.md` (10 tasks: backend config, strings, feature logic, sheet, tiles, sections, hub + flag, tab bar, coffee/clearance, QA).
- [x] Owner reviewed the plan; executing via subagents.
- [x] Task 2 done: `AppConfig.studyHubEnabled` / `studyVipOnlyFeatures`, `StudyHubMetrics`, 50 hub strings in 19 locales.
- [x] Tasks 3–4 done: feature catalogue/badges, upgrade/trial sheet + `study_*` analytics events (`study_upgrade_unlock` method `vip` = tapped through to plans).
- [x] Task 5 done: `StudyFeatureTile`, `StudyFeatureGroups` (badge-gated taps, persona picker, NEW marking), `ExamStudyScreen`.
- [x] Task 6 done: `TodayPackRow`, `RecommendedTile`, `SpotlightCarousel` (+`SpotlightDismissStore`, per-account provider reset), `ProgressCard`.
- [x] Task 7 done: `StudyHub` one-scroll page behind `studyHubEnabled`, old body moved verbatim to `LegacyStudyHub`, new guide ("Your daily language gym", pack + scroll-to-groups), tutor/roleplay reply now records `ActivationAction.lesson`, `FloatingTabBar.clearance` stub.
- [x] Task 8 done: `FloatingTabBar` widget (active capsule with tab name, 56 high, label colour checked >= 4.5:1, badges on icon / after name), hides on downward scroll (24 px, visible tab only, vertical only), any upward scroll / top / end / tab switch brings it back, hidden while the keyboard is open, `tabReselectProvider` (re-tap active tab) scrolls `StudyHub` to top. Not behind `studyHubEnabled`: every user gets the new bar.
- [x] Task 9 done: coffee button removed from the tab shell; `SupportSheet` (moved to `lib/pages/profile/support/support_sheet.dart`) opens from a new Profile drawer > Support row; every tab page (learn, AI tools, community tabs, chat list + refresh button, moments feed, reels create FAB) clears the bar with `FloatingTabBar.clearance`; static test guards the literals.
- [x] Implementation (Tasks 1-10) complete on `feat/ai-study-hub`; QA matrix written: `docs/qa/study-hub-matrix.md`. Merge, version bump and release are owner gates.
- [x] Reselect scroll-to-top on every tab: `TabReselectScrollToTop` wraps each tab page and scrolls the on-screen vertical lists (Community's visible sub-tab, chat list, moments feed/reels, profile, legacy hub); `StudyHub` keeps its own controller listener. Task 8 review fixes also landed: no capsule overflow at 320/1.3 with badges (count moves onto the icon, then the name drops), the pill hugs its tabs, keyboard close and content shrinking to fit restore a scroll-hidden bar.
- [ ] Device QA of the tab bar: hide/show feel on iOS + Android, keyboard (chat composer, search fields), no TabsScreen widget test exists (the shell needs every tab's providers). M
- [ ] Device QA of the hub and tab bar: run every row of `docs/qa/study-hub-matrix.md` (light/dark, SE width, text 1.3, ko + ar RTL, re-tap-to-top on every tab, reels FAB clearance). Widget tests now sweep every new surface for overflow at 320/360/412 × text 1.0/1.3/2.0 × en/de/ru/ko/ar (+ dark en) in the square test font; real fonts and real devices still need the pass. M
- [x] Final whole-branch review fixes (2026-10-14):
  - [x] Coin unlocks counted: tiles read the server's new `bonus` (unspent coin unlocks) — exhausted only when remaining + bonus is 0; "N left" shows remaining + bonus. Old servers (no `bonus`) behave as before.
  - [x] VIP-locked sheet no longer offers a coin unlock (coins can't lift a lock); exhausted sheet's coin unlock pops, refreshes quotas and opens the feature (tested).
  - [x] `ProgressCard` always shows (placeholders "–" when progress is missing), so its shortcuts stay reachable.
  - [x] Cold start (revised 2026-10-14 Android audit): no loader — AI Study is chosen once per launch from the last remembered `studyHubEnabled` (`StudyHubFlagCache`, device-level key), legacy when unknown; a flag change applies from the next launch. The 1.5 s loader would have put a spinner on every user's first screen while the hub is off.
  - [x] `tabReselectProvider` reset on account switch (session reset registry).
  - [x] Seen-marking no longer uses `ref` after the tile is gone; upgrade sheet scrolls on small screens / large text.
  - [x] Overflow sweep `test/learning/study_hub_overflow_sweep_test.dart` (864 cases) — no overflow found beyond the sheet fix.
- [ ] Deferred minors from the final review (not blocking 2.7.0 or the flag flip): hardcoded badge / row colours + dark-mode contrast QA; inactive badge position in RTL; `didChangeMetrics` setState on every metrics frame; programmatic scrolls can hide the bar; `tabRefreshNotifier` not folded into `tabReselectProvider`; no `TabsScreen` widget test; `SupportSheetState` is public; spotlight may repeat the launch pop-up's announcement; `_openPack` is a dead tap while the pack is loading. S each
- [x] Tab bar padding tightened (side margin 8, no gap between items, capsule padding 10; 48 hit target kept): every English tab name fits whole at 360 pt, text 1.0 (measured with real Roboto in `floating_tab_bar_fit_test`).
- [ ] Native review of the study hub strings (rows `studyGroup*`, `studyTile*`, `studyBadge*`, `studyUpgrade*`, `guideStudyHub*`, `supportBananaTalkRow*` appended to the CSV in Owner step 10). M
- [ ] Run the baseline prod queries (feature usage per user, 30 days) before release — not run during design (no prod DB access that session). S
- [x] Backend: app-config fields `studyHubEnabled` (default false) + `studyVipOnlyFeatures` (default []) and the quota snapshot `bonus` field merged to backend `main` and DEPLOYED 2026-10-14 (9d36fe0, backend PR #1); live `/api/v1/app-config` verified `studyHubEnabled: false`, `studyVipOnlyFeatures: []`.
- [x] Verify each feature's real language support against the backend to fill the coverage table (spec §4.6). S
- [ ] Delete `LearnTab` / `AIToolsTab` / `LegacyStudyHub` / `practice_entries.dart` / `study_hub_tabs.dart` once `studyHubEnabled` has been on for a full release. S
- [ ] Per-tab announcement targeting (later, not scheduled). S
- [ ] Language coverage: backend has no hard English-only restriction, so no tile shows "English only for now"; revisit if content gaps show up in baseline queries. S

Bug-fix wave 2026-10-15 (from the full regression suite + two adversarial audits; ~60 confirmed bugs, all fixed on branches, merged to `main`, unit/widget-tested; NONE seen on a device yet — every fix has a case in `docs/qa/regression-suite.csv`)
- [x] Payments: Restore Purchases button (plans + status screens) verifying the newest subscription through the purchase endpoints; redelivered transactions verified (coins credited once); one purchase guard (no stuck "canceled"); VIP users can't buy a second plan; per-month price/savings in the store currency; watch-ad button reacts to ad load; interstitial caps can't be bypassed; replayed coin receipt says "already added"; cross-account coin receipt finishes on 409.
- [x] Moments: photo/voice/video-only moments postable (backend description optional); reel needs a video; upload retries reuse the created moment (no duplicates), bad photos rejected before create; composer back goes to step 1 / asks to discard; feed pagination + server search; comment photos uploaded, GIF comments kept, empty comments refused; comment box never dead, failed comment keeps text, 500-char cap; owner can delete comments; video-editor filter row removed (never applied); story gallery videos capped 60 s; RTL story taps; processing % moves; offline card tap message.
- [x] Chats: catch-up fetch after socket reconnect/resume (+ list refetch); rate-limited send fails at once; Retry resends the failed bubble; sticker/GIF reply keeps type; Forward lists all partners (+search); translate errors shown; mic permanently denied → Open Settings; chat-list pin/mute/delete use the real conversation id, roll back + show errors.
- [x] Auth: suspended accounts refused at login (backend 403 ACCOUNT_BANNED) → suspension screen; new-device email fixed (backend); password reset clears the session; declining Terms signs out; biometric switch in Settings → Privacy + "Continue as" on Welcome; forgot-password offline panel; signup resume tied to the email; change-password rule matches the checklist/backend.
- [x] Profile/notifications: Help Center rows (support mail, bug report with device info, FAQ page); admin email comma; failed settings load can't overwrite server settings; language level rolls back on failure; one profile-completion calculator (12 fields); SupportSheet follows the app theme; announcement "seen" kept per user across logout; iOS icon badge = unread count, cleared on logout; cold-start deep links go through splash/auth and open on top of the tabs.
- [x] Community: Matches tab Retry on failure; skips hidden all day (backend filters skips); Partners wave uses /community/wave; Nearby browse-by-city loads + empty state can widen radius; Waves archive from an empty inbox (RTL-aware); "N live" opens voice rooms.
- [x] AI Study: listening station options distinct/shuffled and graded by word (backend grades 2.6.1 payloads correctly too); tutor send/start failures keep text + Retry; placement retry/no 9th answer/back; persona sheet localized + quota refresh + analytics once; weekly report error+retry; language pick refreshes the hub; Speak tile ungated; Vocab Packs for every target language; STUDY_VIP_ONLY_FEATURES enforced server-side.
- [x] Calls: one app-level call-error presenter; self-view mirrored only on the front camera; Android keeps BT/wired headsets on video calls (speaker only without a headset); BLUETOOTH_CONNECT requested with the mic (denial never blocks); a11y labels on call buttons; call strings + native CallKit labels localized.
- [x] **Deploy the backend fixes** — deployed 2026-10-15 (backend 479b2d2) (backend repo REMAINING_WORK has the list): privacy leak (moment detail/comments/og), VIP repeat-verify + expired iOS receipt, cross-account coin 409, suspended login, listening grading, matching skips, VIP-only enforcement (flag empty), photo-only moments, comment media. All are safe before the app; the app's photo-only posts and comment photos need the backend. S
- [ ] Device QA of the whole wave: run `docs/qa/regression-suite.csv` (P0 at least) on iOS + Android; the agents' manual checks are summarised per area in the suite. L
- [x] Support address decided 2026-10-16: `bananatalkmain@gmail.com` (matches banatalk.com/support). App help links, Help Center subtitle and the suspension appeal text (was `appeal@banatalk.com`) all use it in 19 locales; backend email footers/templates switched too.
- [x] Check prod `isStrongPassword` accepts symbols like `#._-` — yes, backend a1a1b8b is live in 479b2d2 (the 2026-10-08 backend rule fix may be undeployed); otherwise `New.Pass_1` fails server-side after the app now allows it. S
- [ ] Watch new-device login email volume after deploy (device check is coarse: Mobile/Desktop + IP). S
- [ ] Listening scores stored before the fix stay wrong (mastery / weekly listening stats); XP unaffected. Decide whether to reset. S
- [x] STUDY_VIP_ONLY_FEATURES on speak/writing/quizzes: those screens use raw http, so a lock shows the server message, not the upgrade sheet. Done: `AIService` tags the `vip_only_<slug>` 429 (`services/study_vip_lock.dart`) and the Speak, Writing and Quizzes screens open the hub's VIP-lock sheet (Get VIP + Not now, no coins) via `widgets/study/study_vip_lock.dart`; tested.
- [x] Android plan switching (ChangeSubscriptionParam): a VIP with a Play subscription on this Google account sees the current plan marked and "Switch plan" on the others; Play replaces the old subscription (longer plan = chargeFullPrice, shorter = deferred, shown as "Plan change scheduled"); the same plan is never re-bought; a VIP with no Play subscription still gets only the active card. iOS unchanged (StoreKit switches within the group; the VIP screen shows the active card there). `services/vip_plan_switch.dart`, tested.
- [x] (backend 019813c: plan recorded, only the current token ends VIP, CANCELED lapses at endDate; deploys with the next backend push) Backend for Android plan switches (backend repo): verify's existing-VIP branch keeps the OLD `vipSubscription.plan` (only `endDate` follows the store); the RTDN webhook deactivates VIP on CANCELED/EXPIRED for the replaced token (old token still in `transactions`), so a switcher can lose VIP — it must ignore a token that was superseded (`linkedPurchaseToken` / cancelReason 2 replaced). Also CANCELED (3) deactivates at once although the user paid to period end. Ship before the app's switch button reaches users. S–M
- [ ] Device QA of Android plan switching with a Play test account: monthly→yearly (charged, verified, VIP stays), yearly→monthly (scheduled dialog, VIP stays), same plan disabled, Restore afterwards. S
- [x] (fixed 2026-10-16: on Android the redelivery handler verifies VIP purchases for an active VIP too — `verifyWhenVipActive`) Android plan switch: a switch result that arrives after the 5-min wait goes to the redelivery handler, which skips it for an active VIP, so the new token is never verified (VIP still follows the old token until the webhook fix). S
- [ ] Restore also recovers an unconsumed Android coin pack (credited once by the ledger) — keep or restrict to subscriptions. S
- [x] iOS restore skips clearly lapsed subscriptions by heuristic — kept as a pre-check now that the backend refuses expired receipts (deployed 479b2d2); comments updated. S
- [ ] Old app builds posting a photo-only comment now get a 400 instead of a blank comment (after the backend deploy). Accepted. 
- [x] (backend 9a1acef, deploys with the next backend push) Partners waves via /community/wave don't write the UserInteraction wave record, so a waved user can reappear in Partners later (re-wave gets "already waved"). S
- [x] Tidy after merge: removed the now-unused `_setupCallListeners` / `_handleCallError` from chat_conversation_screen.dart and `setupCallListeners`/`handleCallError` in message_action_handlers.dart. S
- Not bugs (left on purpose): the daily chat-partner limit and the profile-view daily limit are dormant with the VIP paywalls (9945ac83); `aps-environment` in source is fine (App Store export sets production); Tajik in iOS `CFBundleLocalizations` only affects the per-app language list.

Suspected bugs from the full regression suite (2026-10-15, code reading only — confirm on device; each has a case in `docs/qa/regression-suite.csv`)
- [ ] **No Restore Purchases button anywhere** — `restorePurchases()` exists in both purchase services but nothing calls it; App Store guideline 3.1.1 requires one, and `coinsVerifyRetry` tells users to restore. Likely App Review risk for iOS 2.7.0. S
- [ ] Payments: failed verifies never retried (no purchase callback registered; `coin_shop_screen.dart` `_purchase` has no catch); Android `_purchasePending` never reset after timeout/abandon → later buys show "canceled" until restart; Android Manage Subscription may no-op (`canLaunchUrl` without a manifest `<queries>` block — R-3); VIP users can start a second subscription; per-month price always USD. M
- [ ] Moments: photo-only moment can't be posted (caption required, contradicts the guide copy); reel can be posted with no video; upload-queue retry and >10 MB / Android HEIC photos create duplicate caption-only posts; no visible upload progress/failure; system back on composer step 2 drops the draft; video-editor filter is preview-only; comment box can stay dead after the limit dialog and a failed comment loses its text; backend moment detail ignores privacy / auto-hide. M
- [ ] Chats: rate-limited sends hang 10 s (`messageSendError` not listened to); an open conversation doesn't re-fetch after a socket reconnect (missed messages until reopen); snackbar Retry duplicates the message; sticker/GIF sent while replying arrives as text; Forward list built only from unread partners; silent failures (translate cap with coins off, pin/mute/delete, mic permanently denied has no Settings link). M
- [ ] Auth: suspended user logging in again sees "Session expired" instead of the suspension screen (`/auth/me` 403); password reset stores a token but shows login (kill → straight in); declining Terms after email login keeps the session; no setting to turn biometric off; backend new-device email never sent (`controllers/auth.js:789` vs `:820`); Forgot-password offline panel never shows. M
- [ ] Profile: Help Center rows (Email Support, Report a Bug, FAQs) do nothing; admin email list missing a comma (`profile_drawer.dart:1161`); change-password Save stays disabled for symbols outside `@$!%*?&`; a failed notification-settings load then any toggle overwrites the server settings with defaults; two completion calculators disagree; SupportSheet follows the system theme, not the app's. S–M
- [ ] Community: Matches tab blank with no retry on any failure; skipped matches return the same day; Partners-list wave uses `/interactions/wave` (no Waves entry); Nearby "Browse by City/Country" loads nothing and the empty state can't widen the radius; Waves archive unreachable from an empty inbox; "N live" pill opens Gatherings. S–M
- [ ] AI Study: tutor chat never shows its error state; placement submit failure leaves the user stuck (and >8 answers); weekly report spins forever on error; picking a language doesn't refresh the hub chip; Speak tile gated on a quota its screen doesn't use; listening-station options never shuffled (answer always first); Vocab Packs only reachable under the English exam; `STUDY_VIP_ONLY_FEATURES` is client-side only. S–M
- [ ] Calls: in-call errors go to the last chat screen's handler (may show nothing — CALL2-10); `CallRoutes.closeAll` stops at a non-call route; self-view mirrored on the rear camera; speaker forced on every video call (BT risk beyond upgrades); missing a11y labels on call buttons. S
- [ ] Notifications / app-wide: announcement "seen" is per device and wiped at logout (repeat pop-up after re-login); iOS badge never cleared (`clearBadge` no-op); cold-start deep links skip the shell and the login redirect; Tajik missing from iOS `CFBundleLocalizations`; check exported iOS build has production `aps-environment`; some interstitials bypass the per-session cap. S–M
- [ ] Hardcoded English found across auth, chat (swipe labels, header status), calls (permission/quality strings), moments composer, profile drawer, coin shop, topics — fold into the L14 localization item. M
Moments / stories audit follow-ups (branch `fix/moments-stories-audit`, 2026-10-15)
- [ ] Profile → Edit moment: removing an existing photo is a no-op — the server ignores `images` on update and has no delete-photo endpoint. Needs a backend route (or hide the remove button). S
- [ ] Story viewer "Add to highlight" does not update the in-memory story's `highlightId`, so a second tap offers the picker again (server side dedupes). S
- [ ] Device QA for the audit: prompt label on card/detail; edit clears mood/tags, removes/adds location, reschedules/clears a schedule; text story with a poll/question; reopening a voted poll / answered question / reacted story (new and old backend); web-made text story with a hex background. S
- Note: the memory/doc claim "AI Tools = sub-tab 0, Learn = sub-tab 1" is stale — legacy AI Study has Today / Practice / Exam Study (Today first).

Later, gated on dashboard numbers (no work until then)
- Phase E (weeks 3–8): Boost price test (150 vs 100), coin-pack prices, 3-day VIP trial, interstitial frequency, more rewarded placements, smart sort when 2.6.x+ is the majority.
- Phase F (only when D7 ≥ 20 %): new-conversation cap, paid installs (Apple Search Ads RU/IN/EG), Moment Boost, AI tutor in VIP.
- Content phase spec (not written): moments / reels / stories — lead with practice-posting, demote reels.
- Guides reach only accounts in the 7-day guide period; revisit if the goal becomes reactivating dormant accounts.

Web ↔ app parity (spec `docs/superpowers/specs/2026-10-16-web-app-parity-design.md`, audits in `docs/audits/2026-10-16-web-parity/`)
- [x] Phase 0: web repo — 23 unpushed commits as one commit (web fba6208), tests restored (3,190 pass), pushed + deployed 2026-10-16.
- [ ] Phase 1: backend — profile visibility helper, blocks, chat contract, story/moment fixes, voice-note AAC transcode, email links, web-feature endpoints + flags. L
- [ ] Phase 2: app (plan `docs/superpowers/plans/2026-10-16-web-app-parity-phase2.md`). M
  - [x] P2-1 merge `fix/moments-stories-audit` (moments#6 prompt/location/isReel, moments#7 UTC scheduling) — 39 l10n conflicts, per-key ARB merge.
  - [x] P2-2 parser + Android manifest learn `/story/`, `/chat/`, legacy `bananatalk://user/` (links#1, #6, #8).
  - [x] P2-3 story share link `shareUrl('story', id)` + `/story/:id` screen (links#1, moments#1).
  - [x] P2-4 profile QR encodes `https://banatalk.com/profile/<id>`; scanner accepts both (links#8).
  - [x] P2-5 `FlutterDeepLinkingEnabled=false` / `flutter_deeplinking_enabled=false` (links#7).
  - [x] P2-6 text stories draw poll/question/link/location, header and reply bar (moments#3).
  - [ ] P2-7 invite code manual entry for new accounts (links#10).
  - [ ] P2-8 Play Install Referrer pickup (links#10).
  - [ ] P2-9 phase gate: full suite, analyze, debug build, QA rows, push.
- [ ] (app, links#15) Parser still accepts any id for /profile/ and /community/ (so /profile/edit, /profile/stats open a broken profile once App Links verify); add the ObjectId check there too after checking 2.6.1 share links only ever carry ObjectIds. S
- [ ] (web, Phase 3) /story/:id page must be live before 2.7.0 ships: 2.6.1 and iOS 2.7.0 (AASA does not claim /story/* until Phase 5) open shared story links in the browser.
- [ ] Phase 3: web bug fixes — chat, moments, community, links. L
- [ ] Phase 4: web features (flagged) — reels, gatherings/clubs, voice rooms, calls, Sign in with Apple. XL
- [ ] Phase 5: owner steps — www cert, nginx snippet + crawler rule, Play fingerprints, Apple Services ID, prod env checks. S

## 5. Decided / won't fix

- 2.6.1 sends no `lang`: it only gets all-language announcements as pop-ups (push and list row still arrive); shows the server's English text for 409 `CALLEE_UNAVAILABLE`. Accepted; the web editor tells admins.
- Waves-side "masked" UI stays dormant: the server always reveals waves (the chat already shows the sender); visitors are the paid reveal.
- `GET /calls/current` returning `{call: null}` right after `POST /calls/initiate` is correct (it only reports calls to show or rejoin, not the caller's own ringing call).
- Backups no longer restore theme/language prefs — side effect of excluding session/secure storage (M8), accepted.
- `contactSupportToCancel` left in the ARBs though unused (harmless).
- 5 keys stay English on purpose: `vipBrandTitle`, `helpEmailSupportSubtitle`, `dailyScore`, `weeklyReportRange`, `learningXpGained`; persona fallback name 'Nana'.
- tl/tg relative times fall back to English (timeago has no locale).

## 6. Done (changelog)

- 2026-10-15 — Moments/stories audit (branch `fix/moments-stories-audit`, not merged): prompt id kept on video moments, prompt chip/card/detail show "Answering: {prompt}", Moments parse prompt/promptId/location/isReel, edit can clear mood/tags and edit location/schedule (no more `images`), scheduled time sent as UTC; stories tolerate unpopulated user/story ids, send fontStyle/allowReplies/allowSharing, text stories take poll/question stickers, viewer restores own vote/answer/reaction (`userVoteIndex`/`hasAnswered`/`myReaction` with old-backend fallbacks), hex/CSS backgrounds parsed safely, question responses only from the endpoint with retry.
- 2026-10-13 — Release prep 2.7.0 (10580): version, notes, Android handoff (7fcf15b8, 545d1958).
- 2026-10-13 — Android release audit: FCM default channel `high_importance_channel` + monochrome `ic_notification`; App Links only for routed paths + `/moment/` share link; tg-TJ locale + RTL; optional hardware features; unused permissions and dead Facebook SDK entries removed; CallKit `signature` permission; no duplicate CallKit missed-call notification; backups skip session/secure storage; Android VIP "Manage Subscription" (2dc340b8…c8df9c8d).
- 2026-10-13 — App audit fixes: rejoin with camera off and no forced speaker (0951f6f8, a61abe74, dcd9d7a8); decline message in UTF-16 units, IME-safe (83db771f, 577d3bb4); "Failed to send message" on undelivered decline text (4206a481); peer upgrade keeps route + wakelock/video service (8129f60b); missed accept + upgrade connects as video (95700b6c); launch-state reset on logout (45d6ec70); ads notice waits for the guide period (f48b74bb); quiet hours stamped with the device zone (efea3f6a); tg compact counts (b443e32a); CLDR `one` plural fix (30271353).
- 2026-10-12 — Merge ed37a53c `feat/onboarding-announcements`: activation milestones and first-week guides (A1–A7), launch pop-up budget + coordinator + priming (A8–A12), announcements screen/list/push/toggle (A11–A15), suspension screen reads `banReason` (A16, dd3d951d), Calls Phase 2 (decline with message, missed-call actions, allow calls + quiet hours, camera mid voice call, draggable self-view), localization L1–L13 (144/144 untranslated keys, EULA, exam, learning players, VIP/coins, stories…), final fix waves.
- 2026-10-10 — Guides on every tab (`GuideStore`, `PageGuide`, 14 strings × 19 locales), PulseHighlight crash fix, 33 English-only Matches keys and "null" placeholder fixed.
- 2026-10-09 — First-session guidance on Matches + events; device-log fixes: `/voicerooms` burst, chat header overflow, `null_log_trap.dart` (75b95ea5).
- 2026-10-08 — Merge ba2b9c8e calls reliability Phase 1 (A1–A14, ring duration 50 s); backend calls deployed (31e6e18).
- 2026-10-08 — Merge 12c8e2b4 auth audit: session reset, 401 redirect, registration token, biometric on Android (FlutterFragmentActivity), keychain accessibility, biometric snapshot freshness, socket re-enable.
- 2026-10-02 — Monetization & growth tranches built dark; 2.6.1 (10574) tagged and released, superseding 2.4.0 / 2.5.0 / 2.6.0.
