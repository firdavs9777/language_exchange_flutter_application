# Remaining work — BananaTalk app

Last updated: 2026-10-13. Keep this current: tick items off in the same commit that finishes them.

See also: backend `language_exchange_backend_application/docs/REMAINING_WORK.md` (server env, prod DB, flags, ops) ·
web `docs/REMAINING_WORK.md` in the web repo (admin console, `assetlinks.json`, nginx).

## 1. Status

- **App `main` 545d1958 = 2.7.0 (10580): NOT built, NOT tagged, NOT submitted.** Android ships first, then iOS.
  Notes `docs/releases/2.7.0.md`, keystore/Play steps `docs/releases/2.7.0-handoff.md`.
- Live in the stores: 2.6.1 (10574, tag `v2.6.1`).
- Backend `main` a9a0b6e and web `main` 2ce0c93 are **deployed** (2026-10-13), so the deploy order
  backend → web → app is satisfied; 2.7.0 can ship as soon as it is built.
- All new server flags are still off (dark); see the backend file for the flag table.

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

## 3. Device / production QA

Release-mode smoke (Android, internal track — handoff §3; rows in `docs/qa/calls-matrix.md` and `docs/qa/onboarding-matrix.md`):
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
- [ ] After assetlinks deploy: `adb shell pm verify-app-links --re-verify com.bananatalk.app` then `pm get-app-links` → `verified`; only `/moment/`, `/profile/`, `/community/`, `/i/` open the app.
- [ ] Every row of `docs/qa/onboarding-matrix.md` (incl. update vs welcome-back, notification tap within 1 s).
- [ ] Guides device pass 2: re-run after the PulseHighlight ticker fix, confirm a clean log.
- [ ] Debug build: open a chat whose partner was last seen long ago (header ~99 px) → `[null-log] … from <frame>` names the source of the bare `flutter: null`; fix it or record as package noise.
- [ ] New account sends one message → `first_message_sent` observed in analytics.

After release (production data):
- [ ] One week after 2.7.0: re-measure calls answered rate (baseline 1/30, target ≥ 40 %).
- [ ] `notification_prime_shown` per new signup, before vs after (ads notice now waits for the guide period).
- [ ] `first_session_say_hi_tapped / _guidance_shown` — is the Matches header salient enough?
- [ ] `guide_cta_tapped` by `target` before adding a third destination anywhere.

## 4. Code work — open

Localization
- [ ] Shrink the 103-entry `test/l10n/no_hardcoded_text_allowlist.txt` to zero (~19 of its files are unreachable: delete or localize). M
- [ ] L14: ~54 property literals (`hintText:`/`labelText:`/`tooltip:`/`message:`) + enum labels listed in the 2026-10-11 sweep (image_viewer 'Rotate', word_card 'Listen', message_bubble 'Report', chat/moments snackbars, upload_queue progress…), with a property-literal guard. M
- [ ] Native CallKit Accept/Decline labels and missed-call subtitle are hardcoded English (`callkit_service.dart:225`); add an "Accept" key and feed them from `notificationL10n()`. S
- [ ] Russian `{coins} монет` is not plural-aware (e.g. `referralClaimed`); needs an ICU plural in the en source. S

Calls
- [ ] Request BLUETOOTH_CONNECT at runtime with the mic if the device QA shows the headset is not selectable on Android 12+. S

Auth
- [ ] Map `SOCIAL_LOGIN_REQUIRED` (email login on a Google/Apple-only account) in `auth_error_codes.dart` if a dedicated UI is wanted; today it shows the server message. S

Monetization
- [ ] `RemoveAdsButton` only under the chat-list banner (visitors-screen banner has none). S
- [ ] Widget-test gaps: limit dialog rewarded flow end-to-end, Matches extra-matches CTA wiring, drawer rows. M

Web announcements (backend + web; **no app change**)
- [ ] Show admin announcements on banatalk.com as a hero-card pop-up or a floating banner, chosen per announcement; spec `docs/superpowers/specs/2026-10-13-web-announcements-design.md`. Spec written, plan + build next. M

Later, gated on dashboard numbers (no work until then)
- Phase E (weeks 3–8): Boost price test (150 vs 100), coin-pack prices, 3-day VIP trial, interstitial frequency, more rewarded placements, smart sort when 2.6.x+ is the majority.
- Phase F (only when D7 ≥ 20 %): new-conversation cap, paid installs (Apple Search Ads RU/IN/EG), Moment Boost, AI tutor in VIP.
- Content phase spec (not written): moments / reels / stories — lead with practice-posting, demote reels.
- Guides reach only accounts in the 7-day guide period; revisit if the goal becomes reactivating dormant accounts.

## 5. Decided / won't fix

- 2.6.1 sends no `lang`: it only gets all-language announcements as pop-ups (push and list row still arrive); shows the server's English text for 409 `CALLEE_UNAVAILABLE`. Accepted; the web editor tells admins.
- Waves-side "masked" UI stays dormant: the server always reveals waves (the chat already shows the sender); visitors are the paid reveal.
- `GET /calls/current` returning `{call: null}` right after `POST /calls/initiate` is correct (it only reports calls to show or rejoin, not the caller's own ringing call).
- Backups no longer restore theme/language prefs — side effect of excluding session/secure storage (M8), accepted.
- `contactSupportToCancel` left in the ARBs though unused (harmless).
- 5 keys stay English on purpose: `vipBrandTitle`, `helpEmailSupportSubtitle`, `dailyScore`, `weeklyReportRange`, `learningXpGained`; persona fallback name 'Nana'.
- tl/tg relative times fall back to English (timeago has no locale).

## 6. Done (changelog)

- 2026-10-13 — Release prep 2.7.0 (10580): version, notes, Android handoff (7fcf15b8, 545d1958).
- 2026-10-13 — Android release audit: FCM default channel `high_importance_channel` + monochrome `ic_notification`; App Links only for routed paths + `/moment/` share link; tg-TJ locale + RTL; optional hardware features; unused permissions and dead Facebook SDK entries removed; CallKit `signature` permission; no duplicate CallKit missed-call notification; backups skip session/secure storage; Android VIP "Manage Subscription" (2dc340b8…c8df9c8d).
- 2026-10-13 — App audit fixes: rejoin with camera off and no forced speaker (0951f6f8, a61abe74, dcd9d7a8); decline message in UTF-16 units, IME-safe (83db771f, 577d3bb4); "Failed to send message" on undelivered decline text (4206a481); peer upgrade keeps route + wakelock/video service (8129f60b); missed accept + upgrade connects as video (95700b6c); launch-state reset on logout (45d6ec70); ads notice waits for the guide period (f48b74bb); quiet hours stamped with the device zone (efea3f6a); tg compact counts (b443e32a); CLDR `one` plural fix (30271353).
- 2026-10-12 — Merge ed37a53c `feat/onboarding-announcements`: activation milestones and first-week guides (A1–A7), launch pop-up budget + coordinator + priming (A8–A12), announcements screen/list/push/toggle (A11–A15), suspension screen reads `banReason` (A16, dd3d951d), Calls Phase 2 (decline with message, missed-call actions, allow calls + quiet hours, camera mid voice call, draggable self-view), localization L1–L13 (144/144 untranslated keys, EULA, exam, learning players, VIP/coins, stories…), final fix waves.
- 2026-10-10 — Guides on every tab (`GuideStore`, `PageGuide`, 14 strings × 19 locales), PulseHighlight crash fix, 33 English-only Matches keys and "null" placeholder fixed.
- 2026-10-09 — First-session guidance on Matches + events; device-log fixes: `/voicerooms` burst, chat header overflow, `null_log_trap.dart` (75b95ea5).
- 2026-10-08 — Merge ba2b9c8e calls reliability Phase 1 (A1–A14, ring duration 50 s); backend calls deployed (31e6e18).
- 2026-10-08 — Merge 12c8e2b4 auth audit: session reset, 401 redirect, registration token, biometric on Android (FlutterFragmentActivity), keychain accessibility, biometric snapshot freshness, socket re-enable.
- 2026-10-02 — Monetization & growth tranches built dark; 2.6.1 (10574) tagged and released, superseding 2.4.0 / 2.5.0 / 2.6.0.
