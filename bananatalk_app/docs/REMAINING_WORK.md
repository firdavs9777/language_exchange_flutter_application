# Remaining work — BananaTalk app

Last updated: 2026-10-13. Keep this current: tick items off in the same commit that finishes them.

---

## Release — onboarding, announcements, localization, Calls Phase 2 (branch `feat/onboarding-announcements`)

The 2026-10-12 plan (`docs/superpowers/plans/2026-10-12-onboarding-announcements.md`, 61 tasks: O, B, W,
A, L, C) is **DONE** and through its final review and fix wave. What is left is release work:

- [ ] **Deploy in order: backend → web admin → app.** The new app on the old backend gets 404s on
      `/announcements/:id` and `/calls/:id/upgrade` and silently drops decline messages.
- [ ] **After the backend deploy:** the log shows `[index] announcement_once_per_user ensured` and
      `db.notifications.getIndexes()` lists `announcement_once_per_user` (if not: run
      `node migrations/addAnnouncementNotificationIndex.js` on the server).
- [ ] **Release build** (manual signing — keystore MacBook; `reference_release_build`), then store submit.
- [ ] **Device QA:** every row of `docs/qa/onboarding-matrix.md` and `docs/qa/calls-matrix.md` §5
      (CALL2-1…CALL2-20), plus the camera-upgrade speaker route and an upgrade POST that times out.
- [ ] **Native review** of the machine-drafted strings (`docs/l10n/native-qa-strings-2026-10.csv`).
- Live 2.6.1 caveats after the backend deploy (accepted, tell admins):
  - 2.6.1 sends no `lang`: it only ever gets announcements that target **all languages**; a
    language-targeted announcement never pops up on 2.6.1 (push and list row still arrive).
  - 2.6.1 shows the server's **English** text for the new 409 `CALLEE_UNAVAILABLE` ("X isn't taking
    calls right now").

## Audit fixes, 2026-10-13 (branch `fix/audit-2026-10-13`) — report of ed37a53c

- [x] **I1** Rejoin after process death published the camera without asking (incl. a voice call the
      peer upgraded). Rejoin now connects with the camera off (audio still routed as for video, call
      type kept); the user turns it on via `enableCamera()` (permission check).
- [ ] **Device QA (I1):** voice call, peer turns the camera on, kill this app in the background (iOS:
      CallKit keeps the call), reopen → call rejoins as video, *own camera off*, no camera prompt,
      speaker on; tap Video On → permission prompt if never granted, then the peer sees the camera.
      Same for a native video call whose camera was switched off before the kill.
- [x] **M1** Decline-with-message: client counted graphemes, server counts UTF-16 units → decline failed.
      Sheet now limits in UTF-16 units (`Utf16LengthLimitingTextInputFormatter`), `RestCallApi.decline`
      clamps grapheme-safely, and a 400 on a message decline is re-sent without the message.
- [ ] Backend (optional): clamp the decline message instead of refusing the decline with a 400.
- [x] **Decline message delivery** (from the backend audit): `data.messageDelivered: false` on a 200
      decline (text dropped: blocked / daily cap), and a 400-refused message, now show the callee a
      short "Failed to send message" snackbar (existing key, all 19 locales). Missing field = delivered.
- [ ] Device QA (decline delivery): decline with a message to a caller who blocked you / past the
      daily cap → call stops ringing for the caller, you see "Failed to send message".
- [x] **M2** Peer upgrade forced the loudspeaker on and skipped wakelock + video call service. Now:
      route untouched until this user turns the camera on (first `enableCamera` routes to speaker),
      wakelock on + call service restarted as video (deferred to resume in the background; the
      resume start now uses the call type, not the camera state).
- [ ] **Device QA (M2):** re-run CALL2-21 (`docs/qa/calls-matrix.md`, expectation updated) and CALL2-13
      for a *peer* upgrade (Android FGS camera type with the local camera off, then on).
- [x] **M3** `VersionCheckCoordinator.lastCheckShowedUpdate` survived logout; now reset in `resetLaunchProcessState`.
- [x] **M4** Ads notice used up a new user's notification priming. `AdsNoticeCandidate.allowedForNewUsers`
      is now false: inside the guide period no launch candidate runs, the budget stays for priming;
      the notice shows once after the guide period (spec §4.1 amended).
- [ ] Data check (M4): after release, compare `notification_prime_shown` per new signup before/after.
- [x] **M5** Caller that missed the accept treated the upgrade `active` as the accept and stayed on voice.
      The ringing→connecting branch now also applies `type: video` (as a peer upgrade: camera off).
- [x] **Quiet hours timezone** (from the backend audit): every settings save now stamps
      `quietHours.timezone` with the device IANA zone (`lib/services/device_timezone.dart`, the same
      source as the top-level timezone report) instead of the model's Asia/Seoul default; a saved
      zone never wins over the device zone; unknown device zone keeps the saved one.
- [ ] Device QA (quiet hours tz): phone in a non-Seoul zone, enable quiet hours 22:00–08:00 → server
      `notificationSettings.quietHours.timezone` is the phone's zone; pushes held in local night.
- [x] **M6** `tg` crashed on four compact-number strings (`NumberFormat.compact(locale:'tg')`). The four
      keys now take a pre-formatted `countLabel` from `lib/utils/number_format_locale.dart` (English
      fallback, like the date helper); guard `test/l10n/number_format_locale_test.dart` fails on any
      `NumberFormat` in generated l10n or a runtime-locale `NumberFormat` outside the helper.

## Android release audit, 2026-10-13 (2.7.0, branch `fix/audit-2026-10-13`) — `android-report` of ed37a53c

- [x] **I1** FCM default channel was `bananatalk_notifications` (never created) → background/killed pushes
      landed in "Miscellaneous" without heads-up. Now `high_importance_channel`. Backend `channelId`
      change is separate (backend repo).
- [x] **M1** Monochrome `@drawable/ic_notification` (chat bubble, white on transparent) for the FCM
      default icon and both flutter_local_notifications inits; backend already requests it.
- [ ] Device QA (I1/M1): kill the app, receive a chat push → heads-up banner, white bubble icon in the
      status bar; Settings → app notifications lists "High Importance Notifications", not Miscellaneous.
- [x] **I3 (code)** The https App Link filter claims only `/moment/`, `/profile/`, `/community/`, `/i/`
      (what `deep_link_parser` routes), so `/privacy-policy`, `/terms-of-use` and the rest of the site
      stay in the browser once links verify. The save-sheet share link used `/moments/<id>`, which the
      app never routed; it now uses `/moment/<id>` like every other share.
- [ ] **I3 (owner)** Paste the upload-key and Play app-signing SHA-256 into the web repo's
      `public/.well-known/assetlinks.json` (live file still has `TODO_SHA256_*`), deploy, then
      `adb shell pm verify-app-links --re-verify com.bananatalk.app` + `pm get-app-links`.
- [x] **M2** `tg-TJ` in `locales_config.xml` (Android 13+ App languages); `android:supportsRtl="true"`.
- [x] **M3** bluetooth, location (+gps/network), wifi declared `required="false"`.
- [x] **M9** bogus `showOnLockScreen` removed; the merged literal `Manifest.permission.CAPTURE_AUDIO_OUTPUT`
      removed with `tools:node="remove"`.
- [ ] Verify (M3): `aapt2 dump badging` on the signed bundle lists no `uses-implied-feature` as required.
- [x] **M4** Removed READ_CONTACTS, READ_PHONE_STATE, SYSTEM_ALERT_WINDOW,
      REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, READ_MEDIA_IMAGES/VIDEO/AUDIO (no lib/ use, no plugin path
      the app reaches); BLUETOOTH/BLUETOOTH_ADMIN capped at API 30.
- [ ] Owner (M4): Play Console — withdraw the Photo & Video permissions declaration once 2.7.0 is live;
      update the Data safety form (contacts and phone state no longer collected).
- [ ] Device QA (M4): Android 12+ call with a Bluetooth headset — headset selectable? (BLUETOOTH_CONNECT
      is declared but never requested at runtime; request it with the mic if not.) Pick photo/video for a
      moment, story, chat, avatar on Android 13+ and on Android 9.
- [x] **M5** Dead Facebook SDK manifest entries (incl. an exported activity whose class is not in the
      APK) and placeholder strings removed.
- [x] **M6** `${applicationId}.PERMISSION_CALL` (guards the exported CallKit activity/receiver/service)
      overridden from `normal` to `signature`; the plugin's own intents are explicit and in-app.
- [ ] Device QA (M6, release build): incoming call from killed + locked → full-screen UI, Accept and
      Decline from the CallKit screen and from the notification both reach the app.
- [x] **M7** flutter_callkit_incoming 2.5.8 drew its own Android missed-call notification after its 50 s
      timeout (duplicate of the app-drawn one, and its Call back did nothing): `showNotification: false`
      on Android (the plugin honours it in `showMissCallNotification`). iOS unchanged.
- [ ] Localize the native CallKit Accept/Decline labels and missed-call subtitle (hardcoded English;
      `textAccept`/`textDecline` could come from `notificationL10n()`; no "Accept" key exists yet).
- [ ] Device QA (M7): Android, let an incoming call ring out with the push delayed (airplane mode on the
      callee after the ring starts) → exactly one missed-call notification, with Call back / Message.
- [x] **M8** Auto Backup / device transfer no longer copy `FlutterSharedPreferences.xml` (session tokens),
      `FlutterSecureStorage.xml` / `FlutterSecureKeyStorage.xml` (biometric): `backup_rules.xml` (API ≤30)
      and `data_extraction_rules.xml` (31+). Side effect: theme/language prefs are not restored either.
- [ ] Device QA (M8): `adb shell bmgr backupnow com.bananatalk.app` then restore on a fresh install →
      app starts logged out, no biometric error.
- [x] **VIP cancel (checklist 11)** Android VIP screens now show "Manage Subscription", which opens
      `https://play.google.com/store/account/subscriptions?package=<applicationId>` (was "contact support
      to cancel"); iOS unchanged. `contactSupportToCancel` is now unused in code (left in the ARBs).
- [ ] Device QA (VIP): Android VIP subscriber → Manage Subscription opens Play's subscription page for
      BananaTalk.
- [ ] **B1** version + notes

## Open work, by who can act

**You — consoles, keys, money, store** (§1)
- Build + submit (see Release above) · store prices (VIP $3.99 / $24.99) · Play Console foreground-service
  declarations (upload is REJECTED without them) · Android App Links SHA-256 · droplet
  `config.env` duplicate keys then Day-0 flags · LiveKit webhook + `APNS_VOIP_*` on prod ·
  AdMob earnings · native review of the machine-drafted strings

**You — a device in your hand** (§0, §0b, §0c, §0d)
- Re-run after the PulseHighlight ticker fix and confirm a clean log
- Send one message on a new account so `first_message_sent` is finally observed
- Biometric smoke: Android 7–8, Android 13+, iPhone Face ID
- `docs/qa/calls-matrix.md` every row (incl. §5 CALL2-1…20); `docs/qa/onboarding-matrix.md`; decide on
  IOS-8 (Focus mode silences CallKit)

**Me — code, ready to start** (§5)
- Localization is done except the **103 allowlisted `Text` literals** and the follow-up sweep (`L14`:
  property literals — `hintText:`/`labelText:`/`tooltip:`/`message:` — with a guard), see §5.
- Built on this branch, no longer open: the long-press tooltip on the first received message (A7) and
  Calls Phase 2 (decline with message, missed-call push actions, quiet hours, camera mid voice call,
  draggable self-view — C1–C10).

**Me — waiting on data, not on work** (§0c)
- Read `guide_cta_tapped` by `target` before adding a third destination anywhere
- Decide whether guides should reach the existing install base (they are gated on
  `isNewUser`, so today only accounts ≤7 days old see one)

**Unexplained — no owner yet** (§0b)
- [x] `flutter: null` lines — debug-only trap added (`lib/utils/null_log_trap.dart`); source not yet named, needs a device run (2026-10-12)
- [ ] Device: open a chat whose partner was last seen long ago (header ~99px) in a debug build and confirm the `[null-log] … from <frame>` line names the source; then fix it (our frame) or record package noise
- [x] PM2 restarts — cause recorded in backend docs/ops/2026-10-pm2-restarts.md (2026-10-12)
- [ ] PM2 restarts follow-ups (backend REMAINING_WORK): deploy-time EADDRINUSE crash, mongoose DocumentArray crash during deploy, droplet OOM (960 MB), attribute 6,862 spike-day exits

---

Context: all three tranches of `docs/superpowers/plans/2026-10-02-monetization-growth.md` are built and
deployed **dark** (every new server flag is off). Backend `main` c5ef2fe is live. App `v2.6.1` (10574) is
tagged and supersedes the never-submitted 2.4.0 / 2.5.0 / 2.6.0. Nothing below affects users on the live
store builds (2.2.4 / 2.2.5) until a flag is turned on.

## 0. Auth audit (2026-10-08) — fix before the next release

App (backend items in the backend repo's `docs/REMAINING_WORK.md`):
- [x] **Signup wipes the Google photo** — wizard sends `'images': []` to `updatedetails`.
- [x] **Logout `prefs.clear()`** — loses theme, language, remembered email, biometric flag; leaves the biometric secure-storage token.
- [x] **Previous user's data survives logout / account deletion** — coins, blocked users, tutor, matches, visitors, notification settings, waves unread; deletion invalidates nothing. One shared session-reset helper.
- [x] **Session dying mid-use leaves empty screens** — `onAuthenticationError` never wired (no redirect to login on 401).
- [x] Splash hangs if Back is pressed on the Terms screen (`splash_screen.dart:155`).
- [x] Typed birth date `1995.13.40` passes step 1, fails at submit (step 1 uses `DateTime(y,m,d)` rollover).
- [x] Double-tap Login / Google / Apple re-runs login (loading flag cleared before navigation).
- [x] Suspension handler clears only `token`/`userId` (refresh token, ApiClient cache, socket, push token remain).
- [x] Small: 423 lockout message replaced by generic text; raw exception text shown; a flaky `getLoggedInUser` after login logs the user out.
- [x] Backend forward-compat: verify-code `registrationToken` kept in memory and sent with `/register` (bound to the verified email); register/reset `refreshToken` already stored; OAuth-only email-login 400 message shown; app never sends `email` to `updatedetails`. Backend can flip `REGISTRATION_TOKEN_REQUIRED=true` once a build with this is the majority.
- [x] Biometric re-login after logout — logout no longer revokes the refresh token the biometric snapshot holds; biometric login refreshes with it; definitive rejection wipes the snapshot + flag, offline keeps it.
- [x] Android biometric never worked: `MainActivity` was a `FlutterActivity` (local_auth needs a FragmentActivity) — now `FlutterFragmentActivity` + AppCompat launch/normal themes. Needs an on-device check on Android 7–8 and 13+.
- [x] iOS biometric snapshot keychain: `unlocked_this_device`, not synchronizable (was readable while locked); clear() also removes items stored under the old accessibility.
- [x] Biometric prompt errors surfaced (not available / not enrolled / locked out / permanently locked / no passcode) instead of a silent dead button; "Continue as" shown only when enabled + enrolled + snapshot readable. 5 new l10n keys are machine drafts in 18 locales — native review open.
- [x] Biometric snapshot freshness: follows every new session for the same account (password/Google/Apple/Facebook login, register, reset, password change) and any refresh-token rotation; a different account signing in wipes it. Password change now stores the server's new refresh token (it was dropped → logout at next expiry).
- [x] Biometric sign-in left the chat socket disabled (logout's `disableReconnection()` was never undone) — real-time chat stayed offline until an app restart.
- [ ] **On-device biometric smoke** (Android 7–8, Android 13+, iPhone Face ID): enable → logout → Continue as → chat receives live messages; second account logs in by password → Continue-as gone.
- [x] Splash profile-incomplete loop — leaving the mandatory wizard unfinished now signs out fully (splash, login screen and the wizard's own exit share `signOutAndReset`).
- [x] Previous account's uploads / call / voice room survived logout — every session teardown now ends them first (still authenticated); uploads are abandoned at their next step and never write into the next account's queue.

## 0b. Calls reliability (2026-10-08) — spec `docs/superpowers/specs/2026-10-08-calls-reliability-design.md`

Baseline: 1/30 calls answered in 30 days, 168 stuck ringing, 0 call messages ever.
- [ ] Backend: server-authoritative call state, timeouts/sweeper, busy + calls-off, call messages, push TTL/missed push, history API, delete legacy callHandler.
- [ ] App (plan `docs/superpowers/plans/2026-10-08-calls-reliability.md`):
  - [x] A1 call strings in 19 locales (18 machine drafts — native review open)
  - [x] A2 outcome model + §3 labels
  - [x] A3 call API / platform seams, CallKit id = callUuid
  - [x] A4 CallManager follower + single exit path; 5-minute cap removed
  - [x] A5 re-bind call listeners when the socket is replaced
  - [x] A6 incoming dedupe, foreground FCM, call_cancelled, stale taps, resume/cold-start recovery (also: stale socket after logout never emitted to; resume rejoins only calls accepted on this device)
  - [x] A7 CallKit extra, cold-start activeCalls(), VoIP/FCM capabilities + real device id
  - [x] A8 AppDelegate VoIP cancel handling + `docs/qa/calls-matrix.md`
  - [x] A9 IncomingCallScreen closes on terminal state / after 50 s
  - [x] A10 20 s reconnect overlay + quality callback chain + outcome banner (also: expireIncoming skips an in-flight accept; outgoing 50 s check re-arms once at 65 s; QA rows S-7, S-8; the app does not emit `call:reconnecting`/`reconnected` relays yet)
  - [x] A11 video wakelock + camera paused in background
  - [x] A12 Android microphone/camera foreground service + full-screen-intent request (QA rows AND-1…AND-7; channel name/description strings are 18 more machine drafts; start/stop serialized, permission check inside the queue, a start superseded by a stop never runs)
  - [x] A13 CallLauncher, call bubble labels, chat-list preview (the Calls list start was folded into CallLauncher; the launcher restores the screen's own error callback after each start)
    - [x] fold `startCallFromCallsList` (Calls list busy / start-limit messages, A4 review) and the chat header's ignored `InitiateResult` into `CallLauncher`
  - [x] A14 Calls list + chat-tab icon + missed badge
  - [x] Final whole-branch review fixes: one ring UI per call (native ring present → no in-app screen / Dart ringtone; native ring appearing later closes the in-app one; in-app accept dismisses the native ring and ignores its echo; a leftover native decline never ends a call answered here, a native End still hangs up a call answered there); cold start skips a stale accepted CallKit entry; a `failed` call:state shows "Call failed" to the caller; LiveKit connect superseded mid-connect never publishes mic/camera; th missed voice label (QA rows S-15 updated, IOS-8, IOS-9, AND-8); re-review: the native-ring-only rule is iOS-only (Android keeps the in-app screen, native ringtone only), and CallKit reporting a call after an in-app accept is ended at once
  - Phase 2:
    - [x] App plumbing: `CallApi.decline(message)` / `upgrade`, `CallManager.rejectCall(message:)` / `upgradeToVideo` / `onCallTypeChanged` (a late `call:state` never revives an ended call), callee-unavailable snack, 13 strings x 19 locales
    - [x] Decline-with-message sheet on the incoming screen (2 canned + custom, 200-char cap; sheet closes if the call ends under it)
    - [x] Missed-call push actions (code): Call back / Message on iOS (category MISSED_CALL, AppDelegate catches remote taps, `bananatalk/missed_call_actions` channel) and Android (data-only push drawn by the app, fail-safe to a plain notification, also from the killed-app handler); capability `missed_call_actions` declared; each call's tap routed once and held until the app is past the splash; signed out / blocked caller → app just opens; `/chat/:userId?call=` starts the call via `CallLauncher`
      - [ ] Device QA CALL2-3..CALL2-6: Call back + Message from killed / background / foreground on iOS and Android; Android Doze + an aggressive OEM (Xiaomi/Samsung) killed-app draw; one action fires once (no second chat or call); signed out → app just opens; 409 callee-unavailable snack after Call back
      - [ ] Device QA (iOS, AppDelegate is now the notification-center delegate): foreground pushes still badge-only (no banner/sound) for every type except the missed-call copy, which shows a banner with Call back / Message; tapping a local notification now routes (it did nothing before); no "completion handler called twice" warning in the console
    - [x] Calls on/off + quiet-hours settings UI (C8: "Allow calls" switch + quiet-hours note; reads `notificationSettings.allowCalls`, default true)
      - [x] Final fix wave: the note now reads "With “Allow urgent notifications” off, calls are held during quiet hours too." (19 locales, machine drafts in the QA CSV) — matches the backend ruling that quiet hours hold calls only when `allowUrgent` is false, and no longer contradicts the "Allow urgent" subtitle
    - [x] Camera button mid voice call + peer-upgrade UI (C9: connected voice calls only; peer upgrade switches layout but the local camera stays off until tapped; refused upgrade shows `callCameraFailed` (new, 19 locales, machine drafts in QA CSV); turning the camera on from the video toggle also runs the permission check)
    - [x] Final fix wave (calls): a voice call that becomes video (local or peer upgrade) routes audio to the speaker like a call started as video, and a rollback restores the previous route; the screen reads the route from `CallManager`. An upgrade POST with no definite answer (timeout, network, 5xx) re-checks `GET /calls/:id` and only rolls back if the server says audio; if that read fails too the optimistic video state is kept. A reopened call screen shows the real local camera state (off after a peer upgrade)
    - [ ] Device QA of camera upgrade: both directions, permission denied, rollback on server refusal, speaker route after upgrade and after rollback, upgrade POST timing out, upgrade racing call end
    - [x] Draggable self-view (C10: `SwappableVideoLayout`; snaps to corners clear of the top/control bars, re-snaps on rotation, tap swaps big/small only while both feeds are live; semantics label + swap hint, 2 new strings x 19 locales, machine drafts in QA CSV)
    - [ ] Device QA of the self-view: drag/snap on small + large phones, rotation, swap with real tracks, TalkBack/VoiceOver
    - [x] Device QA matrix rows CALL2-1…CALL2-20 written (`docs/qa/calls-matrix.md` §5)
    - [ ] Device QA CALL2-1…CALL2-20 (owner, after a release build)
    - [ ] Deploy backend C1–C4 BEFORE the app release (additive; old clients unchanged)
    - [ ] Native review of the 13 Phase 2 call strings
- [ ] Device QA IOS-8: with a Focus mode silencing calls, CallKit shows no banner and the in-app ring closes — decide whether that is acceptable.
- [ ] Native review of the 18 machine-drafted call strings (`lib/l10n/app_*.arb`)
- [ ] Owner: LiveKit webhook URL in LiveKit Cloud; confirm `APNS_VOIP_*` on prod.
- [ ] Device QA: run every row of `docs/qa/calls-matrix.md` (IOS-3/IOS-5 repeat runs prove VoIP delivery survives repeated cancels); re-measure answered rate one week after release (target ≥ 40%).
- [x] Calls: Dart `CallKitService` ring duration aligned with the server (verified 2026-10-12:
      `callkit_service.dart:230` is `duration: 50000`, outlasting the server's 45 s ring).

### Device-log audit, 2026-10-09 (iPhone 15 Pro, hot restart + one outbound audio call)

- [x] **`GET /voicerooms` fires in bursts instead of once per 30s.** Fixed 2026-10-09: the provider is
      held open for one poll interval after the last listener leaves, so a rebuild reuses the count. The log shows ~14 back-to-back
      requests ~570ms apart, continuing during an active call. `activeVoiceRoomCountProvider`
      (`lib/providers/active_voice_room_count_provider.dart`) is a `StreamProvider.autoDispose` whose
      body does `yield await fetchCount()` before the 30s periodic stream, and it is watched by
      `community_app_bar.dart:158`. Every dispose → recreate re-runs that immediate fetch, so a
      rebuilding app bar turns a 30s poll into a burst. `autoDispose` is deliberate (stop polling when
      unwatched) — the fix is to stop paying a network round trip per re-subscribe, e.g. a short
      `keepAlive` or caching the last count with a staleness check, not removing `autoDispose`.
- [x] **`RenderFlex overflowed by 1.1 pixels`, `chat_app_bar.dart:76`.** Fixed 2026-10-09: the status
      line is now `OnlineStatusLine`, a widget testable at the reported 99.2px constraint, with the
      label in a `Flexible` + ellipsis. The online/last-seen Row is a
      7px dot + gap + an unconstrained `Text` carrying `_formatLastSeen()`. With
      `mainAxisSize: MainAxisSize.min` inside a ~99px-bounded parent, a long "last seen…" string has
      nowhere to go. Wrap the `Text` in `Flexible` with `overflow: TextOverflow.ellipsis`. Reproduces on
      a 99.2px constraint; wider headers hide it, so it is screen-size dependent.
- [~] **Two bare `flutter: null` lines** after the overflow. Grep of `lib/` found no bare print; a
      debug-only trap (`null_log_trap.dart`, `kDebugMode` + zone in `main.dart`) now prints
      `[null-log] … from <frame>` after any bare null. Open: confirm on a device run which frame it names.

Checked and NOT a bug, recorded so it is not re-reported: `GET /calls/current` returning `{call: null}`
immediately after a successful `POST /calls/initiate`. `callService.getCurrentCall` deliberately matches
a ringing call only when `initiator: { $ne: userId }` — `/current` answers "should I be shown an incoming
call or rejoin", and the caller already has the call on screen.

## 0d. Activation, launch pop-ups, announcements — app (2026-10-12) — spec `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md` §3 §4 §5.2

- [x] A1 analytics: `activation_milestone`, `guide_retired`, `notification_prime_shown`, `notification_prime_result`
- [x] A2 `ActivationStore` (4 actions, back-fill, fail closed, user-scoped)
- [x] A3 hooks: message, moment (direct + upload queue), lesson / quiz / vocab review, profile complete
- [x] A4 guide rule: 7 days, stop at 3 of 4, `isGuidePeriod`, `GuideSurface.chatTip`, `guide_retired` latch
- [x] A5 strings: 6 keys × 19 locales + native-QA rows (108 machine-draft rows still need native review)
- [x] A6 guide UI: "Getting started · N of 4", retire on real action, CTA no longer retires, Matches on the same rule
- [x] A7 chat tip under the first received text message
- [x] A8 `PopupBudget` + `LaunchModalCoordinator`
- [x] A9 priming: budget, triggers (first matches / first wave / first message sent / received), events; chat-open trigger removed
- [x] A10 AI Study promo folded into the spotlight rotation; `AiStudyPromoModal` deleted
- [x] A11 `Announcement` model, `appConfig.announcements`, `lang` on app-config, seen set
- [x] A12 launch wiring: announcement / ads notice / spotlight candidates; version check reports the update dialog; splash welcome-back shares the budget
- [x] A13 `AnnouncementScreen` at `/announcement/:id`
- [x] A14 notifications list `announcement` type + push routing
- [x] A15 Settings → Notifications "Announcements" toggle
- [x] A16 suspension screen reads `banReason` (REST 403 only; no app socket-suspended handler exists; falls back to the old "Reason:" suffix until the backend ships)
- [x] A12 fix round 1: empty `bananatalk:///` links ignored (never handed to the OS), external launch failures caught, spotlight re-checks the route after picking
- [x] Final fix wave (launch): logout / account switch re-arms `PopupBudget` and TabsScreen's run-once latch (`resetLaunchProcessState` in `resetUserSession`), so a second account in the same process gets its launch pop-up and priming; welcome-back is marked only when its sheet actually shows (an update dialog that spends the budget leaves it armed); a `bananatalk://` link with no matching route does nothing instead of opening go_router's not-found page; the moment milestone survives leaving the composer mid-request; missed-call taps without a call id dedupe on caller + push time (caller-only keys expire after 30 s), so a second missed call from the same caller still routes
- [ ] Device QA rows in `docs/qa/onboarding-matrix.md` (owner, after a release build) — matrix file created in A1; incl. 2 new launch rows (update vs welcome-back, notification tap within 1 s)

## 0c. First-session guidance (2026-10-09) — spec `docs/superpowers/specs/2026-10-09-first-session-guidance-design.md`

Baseline: 85% of signups leave on day one; D1 15%, D7 7%. The first-conversation path is ~80% built
(land on Matches, opener chips, stall banner — all live) but nothing points a first-timer at the one
action, and nothing measures the first session: the 2026-10-07 funnel events stop at
`registration_completed`.

- [x] Matches: `shouldShowFirstSessionGuidance` pure predicate (isNewUser / hasMessaged / timesShown, cap 3)
- [x] Matches: `MatchesFirstSessionPanel` in the existing index-0 header slot; no dismiss, no overlay
- [x] Prefs state `first_conversation_done` + `first_session_guidance_shown_count`
- [x] `message_provider.sendMessage`: set the flag and fire `first_message_sent` on a first successful send
- [x] Four events: `first_session_matches_shown` / `_guidance_shown` / `_say_hi_tapped` / `first_message_sent`
- [x] Two `app_en.arb` keys + `flutter gen-l10n` (18 locales fall back to English until native review)
- [ ] Read `say_hi_tapped / guidance_shown` before deciding whether a header is salient enough
      (implemented 2026-10-09 on branch feat/first-session-guidance; needs real first-session data)

Blocked on nobody, but the two flags that create social pull are still off — `WELCOME_WAVE_ENABLED`
and `LIFECYCLE_PUSH_ENABLED`, both Day-0 in section 1 below. Guidance measured without them understates
the path.

### Every tab (2026-10-10)

Matches alone taught a new user one thing the app does; the other four tabs were rectangles they
opened once. Generalised into `lib/services/guide_store.dart` + `lib/widgets/guides/`, one card per
top-level tab, same rule and same cap-3 as Matches. `test/guides/every_tab_has_a_guide_test.dart`
fails if a tab loses its guide or a sixth one arrives without one.

- [x] `GuideSurface` / `GuideStore` / `shouldShowGuide` — per-surface prefs, Matches keeps its
      original keys so the rollout does not reset anyone's counter
- [x] `GuideCard` (gradient tint, icon chip, fade-in-up) + `PulseHighlight` (ring on the CTA, 3 passes
      then quiet — finite so it never holds a frame callback)
- [x] `PageGuide` — one widget owns eligibility, the cap, the per-run latch and both events
- [x] Lifetime is a **3-day window from signup** (`kGuideWindowDays`), not a count of launches.
      A count could not say how long a guide would live — two launches is three minutes for one
      user and most of a week for another. Matches' predicate now delegates to the generic one, so
      all five retire on the same day. `timesShown` is still recorded and reported; it no longer
      gates. `Community.isNewUser` stays at 7 days: it also drives matching and the analytics
      cohort, where a wider window is correct.
- [x] Matches renders through `GuideCard` too, so the five cards cannot drift apart visually, and
      `MatchCard.highlightSayHi` rings the TOP card's Say hi while the panel is up — the panel names
      the action, the ring says which button that is
- [x] Matches panel also offers the live tab (Gatherings, or Voice Rooms with the switch off) as a
      quiet secondary, labelled with that tab's own label and routed via `communityPendingSubTabProvider`
      — a new user whose six matches are all asleep otherwise has nothing else on that screen to do
- [x] AI Study → AI Tools **and Exam Study** (two destinations; `guide_cta_tapped` carries
      `target` so the console says which one people actually want); Chats → Community/Matches;
      Moments → composer; Profile → edit
- [x] `guide_shown` / `guide_cta_tapped`, both carrying `surface`, kept separate from the
      `first_session_*` events so neither funnel is polluted
- [x] 12 `app_en.arb` keys + `flutter gen-l10n`
- [x] All 14 guide strings translated into the other 18 locales (`test/l10n/guide_strings_test.dart`
      fails if a key goes missing, is left as the English text, or loses its ICU plural arms)
- [ ] Native review of the translated sets — these are my drafts, not a native pass. Two of my own
      slips were caught only by a script check: Korean 새 inside a Japanese string, and a stray 材
      at the start of a Russian one. `arb_integrity_test.dart` now fails on any character from a
      script a locale should not contain.
- [x] **33 Matches/Partners keys that existed in all 19 locales but held the ENGLISH text** —
      `matchSayHi`, `matchesTodayTitle`, every `matchReason*`, `partnerTag*`, `segment*`,
      `opener*`, `stallRescue*`. The whole first-session surface was English for 18 locales.
- [x] `selectUpToImages` rendered the literal word **"null"** to Tagalog and Turkish users
      ("Select up to null images") — a locale used `{count}`, which the template never declares.
      `test/l10n/arb_integrity_test.dart` now scans the GENERATED Dart for it.
- [x] **All 106 `exam*` keys translated** — the Exam Study screen the AI Study guide's secondary
      button opens: entry path, essay evaluation (incl. the VIP upsell, which was asking people to
      pay in English), progress, study plan, speaking, tips, vocabulary.
- [x] 144 of 144 never-translated live keys done. The 5 left in English are deliberate:
      `vipBrandTitle` (brand), `helpEmailSupportSubtitle` (an address), and the pure-placeholder
      `dailyScore` / `weeklyReportRange` / `learningXpGained`.
- [x] `conversation_empty_state.dart` localized — it was hardcoded English on the screen a
      first message starts on, so a Korean user followed a Korean guide into an English screen
- [x] `create_moment.dart` — 18 strings localized (the Moments guide's destination). Six already
      had translated keys sitting unused; the file was already localized in 26 other places, so
      these were leftovers rather than an un-localized screen.
- [x] `terms_of_service_screen.dart` — 43 strings, the worst single file and in the signup path.
      **The EULA body is my draft translation and needs counsel or native review per market
      before release.** The alternative was an English-only EULA in a 19-locale app.
- [ ] **~145 hardcoded English strings left** (`docs/onboarding-audit-2026-10-10.md` §2a).
      gen-l10n cannot see these — they never reach an .arb. Next: the three learning players
      (AI Study's destination), `waves_tab.dart`, then the VIP/paywall copy.
- [ ] Audit follow-ups, ranked in `docs/onboarding-audit-2026-10-10.md` §3: long-press tooltip on
      the first received message (translate/correct are invisible — cheapest large win, reuses
      GuideStore with one new surface), activation milestones over a fixed window, collapsing the
      four launch modals into the existing spotlight, notification permission priming.
- [x] Device pass 1 (2026-10-10): cards confirmed on AI Study, Chats, Moments, Profile; `guide_shown`
      fired once per surface. Found a crash — `PulseHighlight` recreated its controller on every
      rebuild, which `SingleTickerProviderStateMixin` forbids; the ErrorWidget that replaced the
      subtree then "overflowed" the page Column by ~99,000px. Fixed, 5 lifecycle tests added.
- [ ] Device pass 2: re-run after the ticker fix and confirm the log is clean
- [ ] Decide from `guide_cta_tapped` whether any surface needs a second, deeper guide. One card per
      tab, but AI Study's now carries two destinations: the tutor (primary, ringed) and Exam Study
      (secondary, quieter). Read `target` before adding a third anywhere.
- [ ] Guides are gated on the 7-day guide period, so the existing install base never sees one. Revisit
      if the goal becomes activating dormant accounts rather than day-one retention.

## 5. Localization debt (2026-10-11 → ongoing)

Two distinct failures, counted separately because the tooling sees one and not the other.

- [x] **Present-but-untranslated keys: 144 of 144 done.** Keys existed in every locale holding the
      English text. `flutter gen-l10n` counts MISSING keys and says nothing about these, so they
      were invisible. Covered the Matches surface, all 106 `exam*` keys, and the rest. The 5 left
      in English are deliberate: `vipBrandTitle` (brand), `helpEmailSupportSubtitle` (an address),
      and the pure-placeholder `dailyScore` / `weeklyReportRange` / `learningXpGained`.
- [ ] **Hardcoded strings: 184 left** by `test/l10n/hardcoded_text_scanner.dart` (any English literal in the first argument of `Text(`/`SelectableText(`; index keys like `m['error']` ignored, ternaries and `??` included; excludes `TextSpan`, `hintText`, `labelText`, `tooltip`, `title:`; counted over lib/ minus lib/l10n, brand words like VIP/GIPHY included). Earlier figures (384, 74) used narrower definitions and are not comparable. Done in L13b (the sweep of English the scanner cannot see): 80 new keys in all 19 locales (`_keysByTask['L13b']`); existing keys (wave, message, skip, sort, levelBeginner/Intermediate/Advanced, saved, gallery, option, vocabWatchAdBonus, ...) were reused after checking their ja/ko/zh/de meaning. Localized: stories hintText/tooltip/label/`_error`/StoriesSnackbar (11 files), AI `_error` fallbacks and the free-attempt/bonus ad labels, coin-history reason labels, visitor-upgrade benefit rows, feature-gate messages, `RewardedAdButton` default label, ads-notice perks, visitor-limit dialog, welcome-back rows, my-reports info rows, image-preview/report-dialog hints, desktop voice-recorder tooltip, vocab-pack level chips, `_NotAuthorizedScreen`, and the coin-shop ad button. Relative times (`timeago`) are now localized for the 16 app locales timeago supports (`lib/utils/time_ago.dart`; tl and tg fall back to English; compact style only exists for en/es, other locales show the regular phrase), all 7 call sites moved. L12 cleanups done (`_exceptionPrefix` doc, dead `_reasons` labels, report-type terms harmonized: zh Story 故事, zh_TW User 用戶, ko Moment 모멘트). The VIP payment debug block is `kDebugMode`-only and its `_allowedTexts` exemption is gone. `api_error_handler.parseError` now requires its default message. Still open after L13b, none of it in the original list: the **103 allowlisted `Text` literals**, and English found while sweeping that was never collected: tooltips/labels in image_viewer ('Rotate'), word_card ('Listen'), message_bubble ('Report'), quick_replies_panel, create_poll_dialog, visitor_usage_indicator, limit_indicator, voice_recorder_mobile, daily_goal_widget, lesson_assistant_widget, engagement_stats_bar, notification_bell, upload_progress_indicator, ai_quiz_screen, vocabulary_review_screen ('Didn't know'), study_plan_setup_screen hint, and enum labels in leaderboard_model/learning_progress_model; `message:` snackbars in chat (bookmarks, wallpaper picker, chat list, media, forwarding, story-unavailable), moments (create_moment, notification_preferences_screen), community_filter_sheet, blocked_content_widget, partner_list_item, and the upload_queue_service progress strings. Next: a second sweep (`L14`) over those, using a property-literal scanner so they are guarded too. Done in L13a: guard `test/l10n/no_hardcoded_text_test.dart` fails on any new Text literal and on any allowlist entry that no longer matches, so the list only shrinks; allowlist `test/l10n/no_hardcoded_text_allowlist.txt` holds **103 entries** (184 scanner hits minus 81 English by design: staff-only admin console, livekit debug screen, VIP debug diagnostics, brand/unit-only words), matched by path + text, not line number. Also: key-coverage guard (every en key added since f3742650 must be in a `_keysByTask` list or another l10n test; it caught 5 L2 keys never listed), `_mayMatchEnglish` is now per (key, locale), CSV normalized to CRLF record endings, direct `formatDateForLocale` test. Done in L12: shared widgets, auth, calls, errors (29 new keys incl. 9 beyond the brief table: commonReportSubmittedSuccessfully, commonErrorLoadingFile, commonReportReasonCopyright, and commonReportTypeUser/Moment/Comment/Message/Story/Content so the report dialog's `_typeLabel` argument is localized too; 31 scanner hits incl. 5 beyond the table; reuses tryAgain, connecting, preview, additionalDetailsOptional, submitReport, ok, somethingWentWrong, operationCompleted and reportReason* for the report-dialog reason labels while the reason codes sent to the API stay raw). Done in L11: VIP, coins, limits and launch pop-ups (29 new keys incl. 3 beyond the brief table: vipCoinsPerAdInfo, vipUpgradeUnlockMore, vipUpgradeNow; promoAnnouncementGotIt dropped per preflight ruling R3; reuses vip, goVip, vipBestValue, or, ok, upgradeToVip, maybeLater, limitDailyReachedTitle, limitDesc*, waveLimitBody, somethingWentWrong, aiToolsVipUpgradeDescription; announcement_modal secondary button now uses `close` because `dismiss` means reject in ja/ko/zh/de). Done in L10: Stories and video editor (32 new keys incl. 8 beyond the brief table: storySent [the existing `sent` key takes an {emoji} placeholder so it was not reused], storyProcessing, storyHd, storyVideoMeta, storyUserFallback, storySendCount, storyFailedToDelete, storyAnonymous; 59 literals incl. 7 beyond the table; reuses unknown). Done in L9: Notifications, profile, settings, reports (40 new keys incl. 15 beyond the brief table: profileThanksForWatching, profileNotificationsOn/Off, profileMaximumReached, profilePickYourInterests, profileDeselectToChooseAnother, profileTapTopicsMatchVibe, profileEnjoyingPremium, profileUnlockUnlimited, profileBirthYear, profileReportTypeUser/Moment/Comment/Message/Story, profileReportReasonCopyright; 42 literals incl. 9 beyond the table; reuses momentsPullDownRefresh, delete, newUser, unsavedChanges, native, profileCompletion, somethingWentWrong, profile, vipMember, upgradeToVip, and the profile-completion field labels reuse profilePicture/nameLabel/bio/nativeLanguage/learningLanguageLabel/location/topics/mbti/intentSectionTitle; report type/reason labels localized). Done in L8: AI Study conversation, grammar, lesson builder, pronunciation, translation (53 new keys incl. 10 beyond the brief table: aiNoCompletedConversations, aiNoActiveConversations, aiStartInLanguage, aiSelect, aiIssuesCount, aiGenerateLesson, aiGeneratingEllipsis, aiAnalyzing, aiExcellentPronunciation, aiGoodJob; 68 literals incl. 11 beyond the table; reuses aiWhy, selectLanguage, aiTutorPronounceTapToRecord/Stop, aiKeepPracticing, failedToSave). Done in L7: AI Study quizzes, tutor and lesson sheets (42 new keys incl. 6 beyond the brief table: aiGreatJob, aiGoodEffort, aiKeepPracticing, aiFailedToGetHint, aiFailedToGetAnswer, aiFailedToExplain; 56 literals incl. 7 beyond the table; reuses submit, nextButton, lessonCorrect, lessonIncorrect). Done in L6: Learn achievements, challenges and progress widgets (23 new keys incl. 4 beyond the brief table; 28 literals incl. 8 beyond the table; `+N XP` reuses `learningXpGained`; unlock date now uses locale `formatDateForLocale`). Also in L6: challenge tabs/type/descriptions and vocabulary relative dates localized (11 more keys). Done in L5: Learn lessons, vocabulary, exam study (24 new keys + examSpeakingSubmit, which was English in all 19 locales, now translated; 37 literals incl. 9 beyond the brief table). Open from L5: `ai_tools_tab.dart` persona fallback name 'Nana' in `aiTutorHeroTitleSet(name ?? 'Nana')` is a name, left as is. Done in L4: Community and matching (18 keys incl. 3 beyond the brief; 33 literals incl. 8 beyond the brief table). Open from L4 (out of scanner scope, L13 sweep): see commit body. Done in L3: moments, reels and video players (19 keys; 33 literals incl. 9 beyond the brief table). Done in L1: chat list, input, conversation and paywall (26 keys). Done in L2: chat messages, bubbles, wallpaper picker, translation sheet (25 keys). These never reach an `.arb`.
- [x] Final fix wave (deferred minors): Tajik date crash — every `DateFormat.x(runtimeLocale)` in lib/ now goes through `lib/utils/date_format_locale.dart` (gathering card, birthdate edit, blocked users), guarded by a test that fails on a new unguarded call; visitors time badge is one line, ellipsized, max 96 px; time_ago tests for zh_TW→zh, zh→zh_cn, tg→en; profile completion keyed by `ProfileCompletionField`, not by localized labels, and its status line localized (reuses `justGettingStarted`/`lookingGood`/`almostThere`, already in 19 locales); `FeatureGate` and `LimitExceededDialog` share `limitTypeDescription`
- [ ] 54 property literals (`hintText:`/`labelText:`/`tooltip:`) are not covered by the guard; the 103-entry allowlist should shrink to zero (about 19 of its files are unreachable: delete or localize).
      Done so far: the EULA screen (43), the four learning players + waves (45 keys), the coin
      shop / VIP banner / chat paywall (29), Explore + Facebook login + suspension notice (26),
      both correction sheets + the translation sheet (16), the Moments composer (18), the chat
      empty state (3).
- [ ] **Native review** of everything above — all of it is my drafting, not a native pass.
      `docs/l10n/native-qa-strings-2026-10.csv`. **The EULA body needs counsel or native review
      per market before release**, which is a different bar from UI copy.
- [ ] `account_suspended_screen._displayReason` slices the server message by searching for the
      literal `"Reason:"`. That comparison is now against the LOCALISED string while the server
      sends English, so outside English the match fails and the raw server text is shown — the
      same thing it did before for any non-matching message, but wrong either way. The fix
      belongs in the server contract (send the reason as its own field), not in the copy.

Guards added, each for a failure that survives to release on its own:
`test/l10n/guide_strings_test.dart` (missing key, key left as English, plural losing its ICU arms)
and `test/l10n/no_hardcoded_text_test.dart` (new English `Text` literal outside the 103-entry shrink-only allowlist), `test/l10n/arb_integrity_test.dart` (a placeholder gen-l10n never generated, which renders as
the literal word "null" — two locales were asking people to "Select up to null images"; and any
character from a script a locale should not contain, which caught Korean 새 inside a Japanese
string and a stray 材 in a Russian one).

## 1. Owner (needs the keystore MacBook, store consoles or droplet)

- [ ] **Calls release gate** — backend calls work is DEPLOYED (main `31e6e18`, 2026-10-08; 172 legacy stuck calls backfilled, 0 stuck). Still confirm `[voipPush] initialised` shows in prod logs. A new app on the old backend gets no `call:state` (calls never leave ringing on the caller) and the Calls list parses the old history shape.
- [ ] Commit `ios/Podfile.lock` separately before the iOS build: `pod install` adds the missing `in_app_review` pod (keep it out of feature commits).

- [ ] Play Console → App content → Foreground services: declare **microphone**, **camera** and **phone call** ("ongoing 1:1 voice/video call"; `FOREGROUND_SERVICE_PHONE_CALL` comes from flutter_callkit_incoming) before uploading the build with Task A12 — the upload is rejected without it.
- [ ] **Store prices** — App Store Connect + Play Console: VIP monthly **$3.99**, yearly **$24.99** (quarterly untouched; hidden in the app).
- [ ] **Build + submit 2.6.1** — follow `docs/releases/2.6.1-handoff.md` (TestFlight smoke: sandbox coin purchase, cold-start push tap, one Boost purchase while `BOOSTS_ENABLED` is flipped for 10 minutes).
- [ ] **Android App Links** — `public/.well-known/assetlinks.json` in the web repo still has `TODO_SHA256_*`. Paste the upload-key and app-signing-key SHA-256 from Play Console → App integrity → App signing. Until then no `https://banatalk.com/...` link opens the Android app.
- [ ] **Droplet `config/config.env`** — each `*_ENABLED` key must appear once (dotenv is first-key-wins; `DAILY_MATCHES_ENABLED` / `MATCHES_LAYOUT_ENABLED` were set but still read false).
- [ ] **Flags after store approval** (then `pm2 restart language-app --update-env`):
  - Day 0: `DAILY_MATCHES_ENABLED`, `MATCHES_LAYOUT_ENABLED`, `WELCOME_WAVE_ENABLED`, `LIFECYCLE_PUSH_ENABLED`, `REFERRALS_ENABLED`
  - Day 3: `BOOSTS_ENABLED`, `REWARDED_LIMITS_ENABLED`, `COIN_RECONCILE_ENABLED`
  - Keep OFF: `WAVE_CAP_ENABLED` (decision: waves stay unlimited for now), `SMART_SORT_ENABLED` (until 2.6.x is the majority build — see dashboard `buildMix`), `CONVERSATION_CAP_ENABLED` (until D7 ≥ 20%)
- [ ] **AdMob earnings** — lifetime + last 30 days (the one revenue number not measurable from the DB).
- [ ] **Native-language review** — `docs/l10n/native-qa-strings-2026-10.csv` (1,248 machine-drafted strings, 18 locales; fill the last column). Store listings: backend repo `docs/marketing/2026-10-store-listings-{zh,ar,ru}.md`.
- [ ] Optional: apply the web repo's `deploy/nginx.snippet.conf` on the droplet (serves the Apple association file as `application/json`, real 404s).

## 2. Claude, once 2.6.1 is approved and Day-0 flags are on

- [ ] Verify `/app-config`; sandbox signup receives a welcome wave within a minute; watch the first hourly lifecycle run.
- [ ] Baseline row: `node scripts/growthDashboard.js` (backend), then weekly.
- [ ] Launch campaign: `node scripts/sendCampaign.js --campaign daily_matches --dry-run`, then `--send --yes`.
- [ ] Day 3: verify Boost / rewarded unlock / reconciliation in prod.

## 3. Next phases (decided by the dashboard numbers)

- **Phase E (weeks 3–8):** Boost price test (150 vs 100), coin-pack prices, 3-day VIP trial, interstitial frequency, more rewarded placements, wave cap only if waves are heavily used, smart sort when 2.6.x is the majority.
- **Phase F (only when D7 ≥ 20%):** new-conversation cap (freemium), paid installs (Apple Search Ads in RU / IN / EG), Moment Boost with the content phase, AI tutor bundled into VIP.
- **Content phase spec** (not written yet): moments / reels / stories — lead with practice-posting, demote reels.

## 4. Known gaps (deferred on purpose; none affects a user while flags are off)

App:
- Waves-side "masked" UI is dormant: the server always reveals waves (ruling — the chat already shows the sender). Visitors are the paid reveal.
- `RemoveAdsButton` only under the chat-list banner (visitors screen banner has none).
- Russian `{coins} монет` is not plural-aware (needs ICU plural in the en source).
- Widget-test gaps: the limit dialog's rewarded flow end-to-end, the Matches extra-matches CTA wiring, the drawer rows.
- Non-English strings above are machine-drafted.

Backend (details in `docs/REMAINING_WORK.md` there):
- Rewarded ads have no server-side verification (SSV); the per-feature daily cap is the only guard.
- A booster only appears in daily batches generated after the purchase (batches are cached per day).
- Non-VIP visitors page is server-limited to 1 row, so the masked tile says "Someone viewed your profile" even when several did.
- Dashboard D1/D7 use latest activity (trend, not exact day-N return).
