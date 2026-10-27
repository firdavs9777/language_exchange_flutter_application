# Remaining work — BananaTalk app

Last updated: 2026-10-27 (image memory). Keep this current: tick items off in the same commit that finishes them.

See also: backend `language_exchange_backend_application/docs/REMAINING_WORK.md` (server env, prod DB, flags, ops) ·
web `docs/REMAINING_WORK.md` in the web repo (admin console, `assetlinks.json`, nginx).

## 1. Status

- **App `main` = 2.2.6 (10581)** (owner's version name, 2026-10-18; was prepared as 2.7.0 (10580)) — being built and deployed by the owner. iOS needs a version name above the live 2.6.1. Notes `docs/releases/2.2.6.md`.
- Previously: **2.7.0 (10580): NOT built, NOT tagged, NOT submitted.** Android ships first, then iOS.
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
3a. **Play warning "Billing Library 8.0.0 or later by Nov 1, 2026"** (seen 2026-10-18): the code already uses 8.0.0 — in_app_purchase_android 0.5.0 → `com.android.billingclient:billing:8.0.0`, the only billing artifact in `:app:dependencies` (releaseRuntimeClasspath), since 2.3.0 (lock at v2.6.1 is the same). The warning comes from an OLD bundle still active on some track: Releases overview → check every track (internal, closed, open, production) for a release older than 2.3.0 and replace it with 2.7.0 (or pause that track). Billing 9: no Flutter plugin release uses it yet (latest 0.5.4 is still 8.0.0 and needs Flutter 3.41; we are on 3.38.7), so stay on 8.
4. **Store prices** — App Store Connect + Play Console: VIP monthly $3.99, yearly $24.99 (quarterly untouched).
4a. App Store Connect → 2.7.0 → Promotional Text + "What's New" for all 22 store languages: paste from `docs/releases/2.7.0-store-text.txt` (also on the Desktop). Machine-drafted; a native look at ko/ja/zh at least is worth it.
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

**Full regression suite (whole app, 1,048 cases, one tab per area): `docs/qa/regression-suite.csv`** (also as a Google-Sheets-ready workbook). 2.7.0 release run: **`docs/qa/2.7.0-weekend-run.md`** (order, setup, flags, known failures, release-smoke rows R-1…R-12). All four matrices were re-checked against the code on 2026-10-15; rows that were wrong were corrected and ~40 rows added.

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
- [ ] REFERRALS_ENABLED stays off until Android App Links verify (assetlinks fingerprints) — then device-check the invite card (row WEB-APP-07).
- [ ] Web/app parity rows WEB-APP-01…08 (docs/qa/regression-suite.csv, Tab "Web").
- [ ] Audit 2026-10-17 (evening): hub is ON in prod, so the 12 legacy-only AI Study rows (STUDY-002, 043–053) are marked NOT APPLICABLE; STUDY-054/104/112 now 'either hub state'; 39 'Hub ON' rows no longer ask for a backend flag flip or two cold starts; STUDY-112 expects all-Korean (fixed in 6ffd2aca). New rows: STUDY-118…123, COMM-108, PROF-106, APP-069. 1083 cases.
- [ ] 2026-10-17 rows in docs/qa/regression-suite.csv: 26 new (STUDY-114…117, MOM-118…125, COMM-104…107, PROF-101…105, NOTIF-078, PAY-070/071, APP-067/068) and 15 updated ("Updated 2026-10-17" in the 2.7.0 ref column) for placement review, Moments layout, visitors, privacy and Boost everywhere. Excel run sheet built from the CSV.
After release (production data):
- [ ] One week after 2.7.0: re-measure calls answered rate (baseline 1/30, target ≥ 40 %).
- [ ] `notification_prime_shown` per new signup, before vs after (ads notice now waits for the guide period).
- [ ] `first_session_say_hi_tapped / _guidance_shown` — is the Matches header salient enough?
- [ ] `guide_cta_tapped` by `target` before adding a third destination anywhere.

## 4. Code work — open

Camera on Android: app killed while the camera is open (2026-10-17, Galaxy Tab S7 FE)
- [x] Talk → Photo: taking a picture "crashed" the app. Logcat: `lmkd: Reclaim 'com.bananatalk.app' ... low watermark is breached` → `Process com.bananatalk.app has died` → restarted for the ImagePickerFileProvider. Not an exception: Android killed the backgrounded app for memory (debug build ~650 MB). `CameraRecovery` marks the screen before opening the camera; on restart the shell reads `ImagePicker.retrieveLostData()` and reopens Talk → Photo with the photo. Test `test/services/camera_recovery_test.dart`.
- [x] Same recovery for the moment composer (photo comes back in the composer; the typed caption is still lost), story camera (opens the story editor with the photo) and chat camera (reopens that chat with the photo in the send preview; `CameraRecovery.markPending(..., extra:)` keeps which chat).
- [ ] Still not recovered: camera VIDEO (moment/chat), profile photo, gathering/club cover. S–M
- [ ] Device check in a RELEASE build on the tablet: Talk → Photo → camera → photo comes back (killed or not). S
- [x] Korean: AI Study tile "롤플레이" → "일상 회화"; the two descriptions that said 롤플레이 reworded to match.
- [x] VIP price mismatch: the plans screen showed the store price (₩14,000) but the payment screen hardcoded USD ($3.99, and "$3.99/month" under it). Both now use `vipPriceText` (lib/pages/vip/vip_price.dart): the store's localized price, USD only before the store answers; the description line is the localized plan length. Test `test/purchases/vip_price_text_test.dart`.
- [x] The coin balance (app-bar pill, coin shop) was read once per session, so coins granted server-side (admin grant, another device) never showed until a full restart. It is now re-read when the app returns to the foreground and when the coin shop opens.
- [x] (owner reported done 2026-10-27) No purchase has ever reached production (0 paid VIP, 0 purchase attempts, 0 coin purchases on 2026-10-18). Do one license-tester purchase from a Play internal-testing install and one TestFlight sandbox purchase before release; check Play Console products are Active with base plans and the payments profile is verified. S
- [x] Coin unlock inside a sheet ("80 코인으로 3개 잠금 해제" on the tutor upgrade sheet): "not enough coins" (and the other unlock messages) were SnackBars shown on the screen UNDER the sheet. `UnlockCta` now shows a dialog when it sits in a popup route (sheet/dialog), with "Get more coins" → coin shop; plain screens keep the SnackBar. Test `test/coins/unlock_cta_in_sheet_test.dart`.
- [x] AI Tutor on an account with no persona: tapping the tile could go straight to the chat (cached memory from the account used before a switch / a hot reload), the server answered 400 "Pick a persona first", and the screen showed "문제가 발생했습니다 / 다시 시도" forever. The chat screen now opens the persona picker (then returns to the chat) on that refusal — by code `PERSONA_REQUIRED` (backend f88cb20) or by message for older servers. Test `test/ai/tutor_persona_required_test.dart`.
- [x] Community → Partners in a non-English UI: "Active 2h ago" / "Online now" came from an English getter on the model (`Community.lastActiveText`), and "Speaks/Learning <language>" put the stored English language name into the translated sentence. Now `Community.lastActiveLabel(l10n)` (Partners row, compact user tile, profile stats bar — which also parsed the English text for its dot colour) and `LanguageNames` (CLDR names, `lib/utils/language_names.g.dart`, regenerate with `node tool/build_language_names.js`). Test `test/utils/language_names_test.dart`.
- [x] Other places that printed the stored English language name now use `LanguageNames.of(context, …)`: profile About (native/learning rows), user profile header line and About cards, followers/following chips, partner card, language match card, Matches card "A → B", visitors list.
- [x] Community filter (selected language) and the rooms directory (headers, language chips) use `LanguageNames` too.
- [ ] Still English: the full-screen language picker (`language_picker_screen.dart`: English name + native name, A–Z index built from the English name — localizing needs a per-locale sort/index), and the English-only `conversation_starters_card.dart` openers. S
- [x] Pack topics are stored "<target-language name> (<English gloss>)" (64 glosses, all English); a non-English UI showed the English bracket (Arabic: "규칙과 예절 (Rules and manners)"). The gloss now shows only for an English UI (`lib/utils/pack_topic.dart`; Today row, pack card/flow/complete sheet, vocab packs list, detail, practice). Localized glosses would be ~1,200 strings; not planned.

Dark mode (2026-10-17, found on AI Study > Review)
- [x] Review flashcard was hardcoded white: the word (white theme text) was invisible, and so was the example on the back. `vocabulary_card.dart` (flashcard + list card) now uses theme colors.
- [x] The dark theme had no button themes, so any ElevatedButton that set only `backgroundColor` showed teal text on a teal button (e.g. Review's "Done"), app-wide. Dark theme now has the same elevated/outlined/text button themes as light. Test `test/theme/dark_mode_contrast_test.dart`.
- [x] Dark-mode pass: Grammar check (cards, input, history sheet, detail sheet), AI quiz results sheet, quiz player (question, options, counter, bottom bar, results), pronunciation results, lesson builder (chips, suggestions) now use theme colours instead of white cards with grey/black text.
- [ ] Dark-mode leftovers outside AI Study (`grep -rn "color: Colors.white," lib`); device look-through of the AI Study screens in dark mode. S

Daily lesson reminder time (2026-10-17)
- [x] Notification settings has a "Daily lesson reminder" section: on/off (`dailyDropReminders`) and "Reminder time" (`dailyDropHour`, whole hours). The server already accepted both on PUT /notifications/settings; the app never showed them, so everyone got the daily drop push at 19:00 with no way to move or stop it. 3 strings × 19 locales (CSV rows appended). Test `test/settings/daily_reminder_setting_test.dart`.
- [ ] Device check: set the time to the next hour → the daily drop push arrives then (and STUDY-042 can use it instead of a server command); switch off → no push next day. S
- [ ] Native review of `dailyReminderTitle` / `dailyReminderSubtitle` / `dailyReminderTime`. S

Android device run fixes (2026-10-17, Galaxy Tab S7 FE)
- [x] Fresh install showed the OLD AI Study page for the whole first session: the page is chosen once per launch from the loaded config or the remembered flag, and a fresh install has neither yet, so it picked legacy. It now waits for the server (up to 4 s, spinner) when nothing is remembered. Every new user was affected, not only Android.
- [x] `GET calls/current` ran at cold start while signed out and got a 401 every time; it now answers "no call" locally without a token.
- [x] Predictive back (Android 13+): `android:enableOnBackInvokedCallback="true"`; the last three WillPopScope screens (lesson player, two quiz players) moved to PopScope so the exit dialog still shows on a back swipe.
- [x] First login still showed the OLD AI Study page (2026-10-18): the page was chosen once per launch, and a stale remembered "off" or a late/failed config read kept the legacy page for the whole session. Now the page switches to the hub as soon as the server says it is on (the reverse — hub → legacy — still waits for the next launch). Tests in `test/learning/study_hub_test.dart`.
- [ ] Device check on Android 14: back swipe on a lesson / quiz shows the exit dialog (and the preview animation elsewhere); fresh install opens the new AI Study hub. S
- [ ] Logcat `BLUETOOTH_CONNECT permission is missing` at startup is the WebView (ads), not the call code, which already asks for it at call start. The headset-in-a-call check in §3 still stands.

Boost everywhere (branch `feat/boost-everywhere`, 2026-10-17; backend same branch)
- [x] Boost screen says a Boost also places you near the top of Partners and features your latest moment (`boostExplainMore`, 19 locales, CSV rows appended).
- [x] Moment cards show a "Boosted" label (`moment-boosted`) when the server marks the booster's latest moment; Partners rows already showed `boosted`. Partners paging lists a booster placed on page 1 only once.
- [x] Boost entry points beyond the profile drawer: a slim row at the top of the Partners list ("Boost my profile", or "Your boost is live · Xh left"; scrolls away; hidden while boosts are off), "Boost my profile" in the ••• menu of your own moments, and a Boost action on the "moment posted" snackbar. Existing strings only. `lib/widgets/boost/boost_entry.dart`.
- [x] The app read app-config once per launch, so a switch flipped server-side (e.g. BOOSTS_ENABLED) showed only after a full restart. It is now re-read on resume (at most every 2 min; a failed fetch keeps the loaded config; the AI Study page choice still stays fixed per launch). `refreshAppConfig`, test `test/app_config/app_config_refresh_test.dart`.
- [x] Boost progress (2026-10-18): while live, the Boost screen shows a 24 h progress bar, "Shown N times so far" with where (Partners list / Daily matches / Your moment in For You — backend `impressionsBySource`, 0e76090), a hint while it is 0, and tips with "Post a moment". After it ends (7 days): "Your last boost was shown N times" + "Boost again" on the Boost screen and the Partners entry row; the live row also shows the count. "Seen by N people" → "Shown N times" (it counts showings, not people). 9 new strings × 19 locales (CSV rows appended).
- [ ] Native review of the boost-progress strings (incl. ru plural `boostSeenBy`). S
- [ ] Device check with a test account boosted: Partners page 1 shows them 3rd with "Boosted"; their latest moment in For You shows "Boosted"; Boost screen line reads well in ko/ru/ar. S
- [ ] Native review of `boostExplainMore`. S

Placement result and test language (branch `feat/placement-review`, 2026-10-17; backend same branch)
- [x] "Find your level" result showed only the level. Now: score, "What to work on next" (missed topics, or all-right note), then every question with the pick, the right answer and why (icon + text, not colour alone). A skip or an older server shows the level only.
- [x] Placement is in the learner's target language (server-side AI set for non-English); the screen sends `?locale` on GET and POST, shows "Preparing your test…" during the first ~20 s generation, and "no level test for your language yet" (no retry) on 503 `PLACEMENT_UNAVAILABLE`.
- [x] Basque, Catalan, Galician, Latin, Welsh, Scottish Gaelic, Breton, Kurdish, Esperanto show 🌐 instead of a state flag (🇪🇸 for Basque read as "speaks Spanish"). Owner decision 2026-10-17.
- [ ] Device check: English target → review + focus card; Italian target → "Preparing your test…" then Italian questions; Basque target → unavailable message; Korean UI → Korean topics/explanations. S
- [ ] Native review of `placementScore`, `placementReviewTitle`, `placementFocusTitle`, `placementAllCorrect`, `placementNotAnswered`, `placementUnavailable`, `placementPreparing` (rows appended to the CSV). S
- [ ] English bank topics/explanations are English only (hand-written); localize them if English learners with a non-English UI need it. S
- [ ] Still offered to every unplaced learner; a target with no test now says so, but the entry itself could be hidden once the server reports `PLACEMENT_UNAVAILABLE` for the language. S

Visitors + privacy (branch `fix/visitors-privacy`, 2026-10-17; backend same branch)
- [x] Visitors screen: a free account's hidden visitors (`locked`) were dropped by the service, so it showed one person next to a count of hundreds; now a "N people viewed your profile" unlock/VIP tile. VIP lists loaded 50 and stopped; now page on scroll. Badge shows the real total.
- [x] Two quick privacy toggles could revert each other (each save read auth/me then wrote all 14 keys). Saves now run one at a time.
- [x] Own profile hid the owner's own age and location when those toggles were off.
- [x] Privacy screen failed with "User not found" when the stored userId was missing; the save falls back to auth/me's id.
- [ ] Device check: free account with several visitors → one visible + locked tile; VIP with 50+ → scrolls past 50; toggle two privacy switches fast in Profile settings → both stick after reopen. S
- [ ] Once backend 7989e9d (key-by-key privacy merge) is confirmed deployed, send only the changed keys instead of all 14. S

Moments main screen (branch `fix/moments-feed`, 2026-10-17; backend same branch)
- [x] For You showed only "Answer today's prompt to get the conversation started": the server filtered it to the viewer's native/learning language and 152 of 157 public moments are tagged `en`. Backend now ranks those languages first instead of filtering.
- [x] Every tab was re-sorted on the phone by date (default sort "Recent"), so For You and Trending never showed the server's ranking and loaded pages reshuffled as more arrived. No client-side sort any more; the filter sheet's "Sort" tab is now "Time period" only.
- [x] Layout: guide, stories (130 → 104 px) and today's prompt scroll away with the feed (NestedScrollView); one pinned 48 px row holds the tabs and the filter button; active filter chips appear under it only when set. Recent/Popular chip row and the duplicate app-bar "+" removed. Tests `test/moments/moments_main_layout_test.dart`, `moment_filter_order_test.dart`.
- [ ] Device check on a small phone (iPhone SE) and a large one, light and dark: header scrolls away, tab row pinned, pull-to-refresh from the top, paging, Reels tab grid, search mode, a long locale (ru/tl) in the tab row. S

Store rating prompt (branch `feat/rate-prompt`, not merged; App Store had 0 ratings)
- [x] Native in-app review (`in_app_review`, no sentiment pre-gate) at positive moments: daily pack finished (`streak_7` when the streak is a multiple of 7), lesson submitted, live reply in a conversation I wrote in, and the old 3+3-message conversation rule. Rules in `lib/services/review_prompt_service.dart` (`isEligibleForRatePrompt`): not in the first 3 days after signup (install first-seen stamp when `createdAt` is unknown), once per 120 days, max 3 ever; per-install prefs survive logout; never during a call; spends the shared `PopupBudget` so it never stacks (a launch pop-up this process blocks it). `rate_prompt_shown {trigger}` analytics. Drawer > Support > "Rate BananaTalk" opens the store page (App Store id 6755862146). Tests `test/growth/review_prompt_test.dart`, `review_prompt_trigger_test.dart`.
- [ ] Device check: iOS (TestFlight never shows the StoreKit sheet — check on a release build or in the simulator debug run) and Android internal track (Play shows it only for store-installed builds); "Rate BananaTalk" row opens the App Store / Play page. S
- [ ] Native review of `rateBananaTalkRow` / `rateBananaTalkRowSubtitle` (rows appended to the CSV in Owner step 10). S
- [ ] After release: `rate_prompt_shown` by `trigger` vs new store ratings per week; if one trigger dominates without ratings, drop it. S

Web parity Phase 1 — wrong domains (spec 2026-10-16, links#19)
- [x] Wrong-domain references in docs (VOICE_MESSAGES curl, PROF-068 support address) — `api.banatalk.com`, `bananatalkmain@gmail.com`.
- [ ] Story share URL still uses the parked bananatalk.com domain (`lib/pages/stories/viewer/story_viewer_screen.dart:736`) — fixed in web parity Phase 2 (story share). S

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
- [x] (stale — `RestorePurchasesButton` on VIP plans + VIP status since e35889e6) **No Restore Purchases button anywhere** — `restorePurchases()` exists in both purchase services but nothing calls it; App Store guideline 3.1.1 requires one, and `coinsVerifyRetry` tells users to restore. Likely App Review risk for iOS 2.7.0. S
- [x] (2026-10-27: most was fixed earlier, see the Payments line marked done; the rest below under "Payments (2026-10-27)") Payments: failed verifies never retried (no purchase callback registered; `coin_shop_screen.dart` `_purchase` has no catch); Android `_purchasePending` never reset after timeout/abandon → later buys show "canceled" until restart; Android Manage Subscription may no-op (`canLaunchUrl` without a manifest `<queries>` block — R-3); VIP users can start a second subscription; per-month price always USD. M
- [ ] Moments: photo-only moment can't be posted (caption required, contradicts the guide copy); reel can be posted with no video; upload-queue retry and >10 MB / Android HEIC photos create duplicate caption-only posts; no visible upload progress/failure; system back on composer step 2 drops the draft; video-editor filter is preview-only; comment box can stay dead after the limit dialog and a failed comment loses its text; backend moment detail ignores privacy / auto-hide. M
- [x] (superseded — fixed, see the Chats line marked done above) Chats: rate-limited sends hang 10 s (`messageSendError` not listened to); an open conversation doesn't re-fetch after a socket reconnect (missed messages until reopen); snackbar Retry duplicates the message; sticker/GIF sent while replying arrives as text; Forward list built only from unread partners; silent failures (translate cap with coins off, pin/mute/delete, mic permanently denied has no Settings link). M
- [ ] Auth: suspended user logging in again sees "Session expired" instead of the suspension screen (`/auth/me` 403); password reset stores a token but shows login (kill → straight in); declining Terms after email login keeps the session; no setting to turn biometric off; backend new-device email never sent (`controllers/auth.js:789` vs `:820`); Forgot-password offline panel never shows. M
- [x] (stale — all fixed in code, verified 2026-10-27) Profile: Help Center rows (Email Support, Report a Bug, FAQs) do nothing; admin email list missing a comma (`profile_drawer.dart:1161`); change-password Save stays disabled for symbols outside `@$!%*?&`; a failed notification-settings load then any toggle overwrites the server settings with defaults; two completion calculators disagree; SupportSheet follows the system theme, not the app's. S–M
- [x] (stale — all fixed in code, verified 2026-10-27) Community: Matches tab blank with no retry on any failure; skipped matches return the same day; Partners-list wave uses `/interactions/wave` (no Waves entry); Nearby "Browse by City/Country" loads nothing and the empty state can't widen the radius; Waves archive unreachable from an empty inbox; "N live" pill opens Gatherings. S–M
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
- [x] Phase 1: backend — deployed 2026-10-16 (07febec): other session's moments-stories branch merged; privacy redaction for signed-out/blocked viewers, follow only as yourself + block check; socket block check fixed; chat contract (no "Conversation started", delete/edit aliases, real unread, filters); highlights/translation; web voice notes → AAC; email links, invite OG, Pub/Sub audience; six web flags; Google one-time code; Apple web login (dark); contract tests. Verified live: signed-out /public has no coordinates/birth date/followers/presence.
- [x] Phase 2: app (plan `docs/superpowers/plans/2026-10-16-web-app-parity-phase2.md`) — done on branch `parity/app` 2026-10-16 (full suite 3,050 pass, analyze 0 errors/warnings, debug APK builds); ships with 2.7.0. M
  - [x] P2-1 merge `fix/moments-stories-audit` (moments#6 prompt/location/isReel, moments#7 UTC scheduling) — 39 l10n conflicts, per-key ARB merge.
  - [x] P2-2 parser + Android manifest learn `/story/`, `/chat/`, legacy `bananatalk://user/` (links#1, #6, #8).
  - [x] P2-3 story share link `shareUrl('story', id)` + `/story/:id` screen (links#1, moments#1).
  - [x] P2-4 profile QR encodes `https://banatalk.com/profile/<id>`; scanner accepts both (links#8).
  - [x] P2-5 `FlutterDeepLinkingEnabled=false` / `flutter_deeplinking_enabled=false` (links#7).
  - [x] P2-6 text stories draw poll/question/link/location, header and reply bar (moments#3).
  - [x] P2-7 invite code manual entry for new accounts (links#10).
  - [x] P2-8 Play Install Referrer pickup (links#10).
  - [x] P2-9 phase gate: full suite, analyze, debug build, QA rows (push by the coordinator).
- [ ] (app, links#15) Parser still accepts any id for /profile/ and /community/ (so /profile/edit, /profile/stats open a broken profile once App Links verify); add the ObjectId check there too after checking 2.6.1 share links only ever carry ObjectIds. S
- [x] (web, Phase 3 links — live 2026-10-16) /story/:id page must be live before 2.7.0 ships: 2.6.1 and iOS 2.7.0 (AASA does not claim /story/* until Phase 5) open shared story links in the browser.
- [ ] (web, Phase 3 links) Invite page "Get it on Google Play" → https://play.google.com/store/apps/details?id=com.bananatalk.app&referrer=code%3D<CODE> so P2-8 can pick the code up.
- [ ] Device QA: install from a Play internal-testing link with &referrer=code%3D<CODE>, register, coins credited (row WEB-APP-08; needs REFERRALS_ENABLED on a test backend).
- [ ] (build env) Android Studio's bundled JBR is now Java 25, which Gradle 8.11.1 cannot run on (`flutter build apk` fails in settings.gradle with "> 25.0.3"). Workaround used for the P2 gate: `cd android && JAVA_HOME=<openjdk@17> ./gradlew assembleDebug`. Fix: `flutter config --jdk-dir <openjdk@17>` (owner, machine-level) or a Gradle upgrade. S
- [x] Phase 3: web bug fixes — all four units deployed 2026-10-16 (links, community, moments, chat; web suite 3,820 pass); backend message search fixed (500 → works). Native review of new web strings open.
- [x] Phase 4: web features deployed dark 2026-10-16 — reels, gatherings/clubs, voice + language rooms, City/Genders tabs, Sign in with Apple (all behind web* flags, off); browser calls dropped by owner decision → website chats show "Call in the app" (live). Open: bundle budget over; native review of new web strings; backend voice-room speaker role/kick + raise-hand event names; city search ignores location.city.
- [x] Phase 5 step 1 (2026-10-16): banatalk.com certificate now covers www (expires 2027-01-14); renewal dry-run OK for banatalk.com.
- [x] Phase 5 step 2 (2026-10-16): website nginx config applied (www → apex 301, AASA as application/json, link-preview bots → api /og cards, dead-URL redirects); verified live. Backup on server in /root/nginx-banatalk-backup-*.conf.
- [x] `cdn.banatalk.com` certificate re-issued with a new key (2026-10-19) and live on the DO Spaces CDN (cert `cdn-banatalk-2026-10`, serial 0664…2D04, expires 2027-01-17); old cert + exposed key retired.
- [ ] **Before 2027-01-10:** renew `cdn.banatalk.com` again (manual — DNS is at Namecheap). Steps in `docs/ops/2026-10-16-web-hosting-steps.md` §9. Permanent fix: move banatalk.com DNS to DigitalOcean so it auto-renews.
- [ ] flame.banatalk.com certificate expired 2026-08-16 and fails renewal — remove it if the site is dead. S
- [x] Phase 5 steps 3–6 (2026-10-16..19): Play app-signing SHA-256 in assetlinks.json (Google reports linked); prod env checked; Sign in with Apple on the website (Services ID com.bananatalk.com); WEB_REELS / GATHERINGS / VOICE_ROOMS / LANGUAGE_ROOMS / APPLE_SIGNIN on (WEB_CALLS stays unused).
- [ ] Phase 5 what's left (owner), as of 2026-10-19:
  - [ ] Build + release 2.7.0 — run `flutter config --jdk-dir=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home` once first (see build-env line above).
  - [ ] After 2.7.0 is most of the iOS base: add `/story/*` and `/chat/*` to the web AASA; turn on `REFERRALS_ENABLED` (ops doc step 7).
  - [ ] Upload-key SHA-256 into the web `assetlinks.json` (`keytool -list -v -keystore <upload.jks>` on the keystore MacBook) — tracked in the web repo. S
  - [ ] Play RTDN: Pub/Sub push subscription to `https://api.banatalk.com/api/v1/purchases/android/webhook` with `GOOGLE_PUBSUB_SERVICE_ACCOUNT` set; check `pm2 logs language-app | grep "Google Play RTDN received"` after a test purchase. S
  - [ ] Voice rooms on the website: two-person QA (web user joins an app user's room, both hear and speak). S
  - [ ] Optional: `rm -rf build/communities` on the droplet (leftover, unserved). S
  - Website-only follow-ups (NAV-3 Learn tab / bell, NAV-4 device QA, interpolated admin-announcement sentences, native reviews of new web strings) live in the web repo's `docs/REMAINING_WORK.md`.

## 5. Decided / won't fix

- 2.6.1 sends no `lang`: it only gets all-language announcements as pop-ups (push and list row still arrive); shows the server's English text for 409 `CALLEE_UNAVAILABLE`. Accepted; the web editor tells admins.
- Waves-side "masked" UI stays dormant: the server always reveals waves (the chat already shows the sender); visitors are the paid reveal.
- `GET /calls/current` returning `{call: null}` right after `POST /calls/initiate` is correct (it only reports calls to show or rejoin, not the caller's own ringing call).
- Backups no longer restore theme/language prefs — side effect of excluding session/secure storage (M8), accepted.
- `contactSupportToCancel` left in the ARBs though unused (harmless).
- 5 keys stay English on purpose: `vipBrandTitle`, `helpEmailSupportSubtitle`, `dailyScore`, `weeklyReportRange`, `learningXpGained`; persona fallback name 'Nana'.
- tl/tg relative times fall back to English (timeago has no locale).

## 6. Done (changelog)

- 2026-10-16 — Store rating prompt (branch `feat/rate-prompt`): native review at positive moments with 3-day / 120-day / 3-ever rules, pop-up budget, call guard, `rate_prompt_shown`, Drawer "Rate BananaTalk" row in 19 locales.
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

## Moments editing (2026-10-18)
- [x] Profile → My Moments → Edit opened an old reduced edit screen (no background colours, unlike create and unlike editing from the feed). It now opens the same composer as create/feed edit (`CreateMoment(momentToEdit:)`); `moment_edit.dart` removed.
- [ ] Device check: edit a text moment from Profile → My Moments, change its background colour, save → the card and the feed show the new background. S
- [ ] Editing still cannot remove existing photos (it can only add); not asked for yet. S

## Rooms (2026-10-18)
- [x] Production had no language rooms; backend 351aa3d/1c6b537 seeded 17 hubs + 8 topic rooms, fixed the typing relay, throttled topic-room pushes, and posted a daily prompt in every hub.
- [x] App: room language flags by exact code (getFlagByName turned es→🇯🇵, ar/hi→🇨🇳, pt→🇪🇬); only a system message with a promptId takes the daily-prompt card (newest wins), other system lines stay in the history; sends wait for the server ack and a failed send keeps the text and says "Failed to send message"; room_mention pushes open the room; room cards show "Active 5m ago"; "Your hub" only on the joined hub, not every joined topic room.
- [x] Rooms have chat's photos, replies and reactions (backend ee6e92a): the composer offers camera, gallery and GIF (`ChatInputBar.roomTools`; no location/phrases/overflow); photos go through chat's preview-with-caption to `POST /rooms/:id/media`; swipe/long-press → Reply shows chat's reply preview and the quote; reactions use chat's picker and update live from the room channel (`applyReactionUpdate`).
- [x] Room safety in the app: moderators (room owner/admins, BananaTalk admins — backend d3a6243) get Delete on anyone's room message, the sender on their own, removed live for everyone (`room:messageDeleted`); live messages from people you blocked are hidden (history already was); removing a member is "Remove & ban" in every room; Pin/Edit/Forward no longer show in rooms (they did nothing). Opening a room no longer joins it ("Join Room" bar). 17 hubs + 27 topic rooms on prod.
- [ ] Not done (from the audit): real moderation in hubs (ban, maxMembers), cursor pagination, opening a room no longer auto-joins on peek, mentions never sent by the client. M–L each
- [ ] Device check (rooms photos/replies/reactions, two accounts): send a photo with a caption, reply to it, react with ❤️ → the other side sees all three live; a failed photo upload says "Failed to send message". S
- [ ] Device check: Community → Rooms shows the 17 hubs with right flags, your learning-language hub first with today's question; typing shows "<name> is typing"; airplane mode → send → "Failed to send message" and the text stays. S

## Partners row (2026-10-18)
- [x] Chips led with "Active 3h ago" + "Joined 12d ago" on nearly every row. Now (max 3, `partnerChipLabels`): exchange fit ("You're learning each other's language" / "Speaks X" / "Learning X") → shared interest (localized topic) → same city (only if the person shows their city) → replies fast → "Active now / Active today" (only if they show online status). Exact recency and account age are no longer shown to strangers. Chips are one line with "…" (no overflow at 320 px in de/ru/en).

## Nearby (2026-10-18)
- [x] Nearby looked empty: it silently kept only people tied to the viewer's learning language, free accounts were searched at 50 km whatever chip was picked (100/200 km did nothing), and without GPS it stopped at the permission screen even when the profile had a location. Now: no language filter unless chosen; chips above the account limit (server `search.maxRadiusKm`) show a lock and open VIP plans; without GPS it searches around the profile location; with GPS granted and no profile location, the device city/country is saved to the profile (so others can find them) — only after the system permission. Prod: 1,838 users have a location, 18 within 50 km of Seoul.
- [ ] Device check: Nearby with GPS on lists people; 100 km chip shows a lock → VIP plans; a fresh account that allows location gets its city on the profile. S

## VIP value (2026-10-18) — see docs/audits/2026-10-18-vip-audit.md
- [x] Owner picked 4 (2026-10-18): (1) country + "prioritize nearby" filters are VIP again, app + server (gender stays free — public Genders tab); (2) VIP daily matches 15 (backend a71aa3c); (3) honest perks in the limit dialog, VIP status and plans screens (no more "unlimited messages / profile views / priority support / unlimited waves"; now unlimited AI tutor, see everyone who viewed you, 15 daily matches, no ads) + Matches CTA "VIP: 15 matches a day" — 5 strings × 19 locales; (4) upgrade paths on dead-end limits: story limit → LimitExceededDialog, hourly AI limits → upgrade sheet (`quota_exceeded`), inline translate limit → "Go VIP · Unlimited translations".
- [x] Own profile: free users see a gold VIP card with the three strongest real perks and "Go VIP" (was a plain white row); the VIP member card no longer overflows at 320 px. Web parity for VIP/filters/nearby/limits/privacy done in web 920f288; /purchases/plans perks fixed (backend 36a3149).
- [x] Create room: the language is picked with the signup picker (flags, native names, search, every language); the server now accepts any recognised language for a user-created room (backend 468fa90; hubs stay on the 17).
- [ ] Remaining audit items (translation cap on moments/comments, tutor quota holes, wave cap / study VIP features config). S–M
- [ ] Web: language rooms and Boost do not exist on web yet (owner asked for parity). L

## AI Study hub look (2026-10-18)
- [x] "Your progress" is a purple→pink gradient card with three coloured tiles (🔥 streak, ⭐ level + total XP, 🎯 today's XP with a bar) and white shortcut pills with coloured icons (same labels/keys; overflow sweep passes).
- [x] Vocabulary packs get their own teal card right after today's pack ("Ready-made word sets by topic…" + "Browse packs"); before, only a small chip at the bottom of the progress card. 2 strings × 19 locales.
- [ ] Device look in light + dark mode; native review of `vocabPacksPromo` / `vocabPacksBrowse`. S

## Visitors coin unlock (2026-10-18)
- [x] 60 coins open the full visitors list for 24h (stacks: another unlock adds 24h). Nothing said so: before buying the copy was "See who for 60 coins", and after buying nothing showed the end, so the list locked again without warning. Now "See everyone for 24 hours for 60 💎, or go VIP", and an "Unlocked · 23h 12m left" banner with Go VIP while it is open (server `revealUntil`, backend 715ce1f). Waves are always visible (product ruling), so the unlock only concerns visitors. 2 strings × 19 locales.

## In-app message banner (2026-10-18)
- [x] A message received while the app was open showed nothing but a badge: the server sends no push while the chat socket is connected, and the app dropped foreground chat pushes. Now a banner slides down (sender, avatar, preview; tap opens that chat; swipe up or 4 s to dismiss) whenever the sender is not the chat you are in — also while chatting with someone else (HelloTalk-style). `InAppMessageBanner`, hooked in `GlobalChatListener`.
- [x] Muted chats stay silent in-app (34d5476b). Quiet hours still ignored by the banner. S

## Chat socket on Android (2026-10-18)
- [x] The socket gave up for good after 10 failed reconnects (~2 min), a Wi-Fi <-> mobile switch never reset that (only offline -> online did), and resume reconnected only from the Chats screens — so after a sleep, AI Study could stay disconnected and miss messages. Now: fast backoff then a retry every 60 s while the app is open (`reconnectDelayFor`), any connectivity change retries while disconnected, and every resume reconnects from the app root (not after logout / server forceDisconnect).
- [ ] Device check on Android: toggle Wi-Fi/mobile and airplane mode with the app open on AI Study, then have someone message you → banner arrives within ~a minute. S

## Image memory (2026-10-27)
- [x] 21 bare `NetworkImage` (CircleAvatar backgrounds: calls, matches, moments, chat search/forward, gatherings, visitors, QR sheet, story answers, admin) decoded the full-resolution original and never hit the disk cache. They now use `ImageUtils.avatarProvider` (cached, ≤200 px; 800 px on the call screens). The 12 `Image.network` sites (match card, conversation header, leaderboard, achievements, saved moments, profile moment card, announcements, video thumbnails) decode at ≤200 / ≤800 px via `cacheWidth`. Lower RAM when scrolling — the Android lmkd kill on Talk → Photo was memory.
- [ ] Device check: avatars on the call screens, conversation header, match card and the profile moment card look sharp (not soft) on a 3× phone; memory in DevTools (`flutter run --profile`) on the Galaxy Tab while scrolling Moments/Community before vs after. S
- [ ] Left full size on purpose: `report_evidence_section.dart` (admin evidence viewer). S
- [ ] Next perf candidates: 26 `shrinkWrap: true` lists and 84 eager `ListView(children:)` — convert the long/growing ones to builders; 296 `ref.watch` vs 15 `.select` — narrow watches on the chat list and feed; check the 11 `Timer.periodic` cancel in dispose / pause in background. Profile first. M

## Payments (2026-10-27)
- [x] Android coin pack whose verify failed (offline, server error, app killed) stayed bought-but-unconsumed: Play never redelivers it (StoreKit does), so buying that pack again failed as "canceled" and Play refunded it after 3 days with no coins. `AndroidPurchaseService.recoverUnfinishedCoinPacks()` queries Play's owned purchases at app start and on coin-shop open and hands unconsumed packs to the redelivery handler (verify → server credits the token once → consume). Test `test/purchases/unfinished_coin_packs_test.dart`.
- [x] Manifest `<queries>` for http/https VIEW: `canLaunchUrl` (Manage Subscription, Terms/Privacy, chat links, story link stickers) only worked because the ads SDK merged an https query; http chat links failed.
- Not a bug: the coin shop `_purchase` "has no catch" — `ApiClient.post` never throws and both purchase services catch.
- [ ] Device check (Play internal track, license tester): buy a coin pack in airplane mode right after paying (or kill the app before verify) → reopen the coin shop online → coins arrive once, the same pack can be bought again. S
- [ ] A verify network failure shows ApiClient's English "Network error. Please check your connection." in the coin shop instead of `coinsVerifyRetry`. S

## 2.2.7 audit (2026-10-27) — see docs/audits/2026-10-27-2.2.7-audit.md
- [x] (fixed 2026-10-27, one commit each) P0–P1 (13): Trending tab empty (M1); drawer Edit profile erases intents (P1); Update location blanks city/country (P2); chat list never updates live (C1); saved moments stop at 10 (M2); scheduled video posts at once (M3); Topics filter ignored (CO1); Followers list can't unfollow (P3); stacked chats lose active state (C2); history paging jumps (C3); unread counts drift (C4); pending gathering request lost (CO2); 7+ photo upload fails (P4). M–L
- [x] (fixed 2026-10-27) P2 (17): M4–M8, CO3–CO6, C5–C10, P5–P7.
- [ ] P3 minors in the audit doc (story viewer race, City tab country for free users, filter-sheet count vs list, Genders reload, topic race, Matches wave button, chat provider never disposed, shared typing timer, media screen 500 cap, setState after dispose in sends, delete-for-everyone mismatch, chat search error text, chat list 100 cap, privacy refetch revert, remove-extra-photos, account deletion order). S each
- [ ] Backend items in the audit doc (cascade delete of follows/blocks, photo limit, messageEdited populate, conversationId on all sends, sync-badges, senders paging, room hubs data). M
- [ ] Native review of `gatheringRequestPending` / `gatheringWithdrawRequest` (19 locales, written 2026-10-27 for audit CO2). S

## Gatherings + clubs (2026-10-27) — see docs/gatherings-and-clubs-status.md
- [x] Attendee card: after a gathering, someone who was there sees "Who was there" with a Message button each (reads backend `people`; `test/community/gathering_people_test.dart`). `gathering_time_changed` push taps open the gathering.
- [ ] Deploy backend `04c3832` (attendee list, no-show sweep, cancel notifications, local time in "time moved"); until then the card never shows. S
- [ ] Native review of `gatheringWhoWasThere` / `gatheringWhoWasThereHint` (19 locales, written 2026-10-27). S
- [ ] Website: no attendee card yet (behind `WEB_GATHERINGS_ENABLED`, off). S
- [ ] Backend open items for 모임 (in-app history for reminders, "has hosted N", club city/place, repeat, start → VoiceRoom) are in the backend `docs/REMAINING_WORK.md`.
- [ ] Device QA of the 2.2.7 audit fixes (two accounts): Trending tab lists moments; Saved moments past 10; schedule a VIDEO moment → appears at its time; double-tap Post → one moment; comment thread doesn't flash every 15 s; edit/delete a moment from detail → feed updates; bookmark a card, scroll away and back → still saved; Topics filter narrows Partners; Partners offline → Retry footer, no request storm; ask to join an approval gathering, reopen → "Request pending" + Withdraw; Waves past 20; visitors card total; Rooms offline → error + Retry; chat list moves rows live; open chat B from the banner inside chat A, close B → A's messages don't banner; scroll up a 300-message chat → no jump; read a chat on web → app badge clears on refresh; mute a chat, receive a photo/voice → no banner; edit a reply → quote stays; send in airplane mode, reopen chat → failed bubble + Retry still there; Followers list shows Unfollow for people you follow; drawer Edit profile keeps intents; Update location offline keeps city; add 8 photos at once; pick Korean on an English phone → next push in Korean; notification toggle offline → "Failed to update". M
