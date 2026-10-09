# Remaining work — monetization & growth

Last updated: 2026-10-10. Keep this file current: tick items off in the same commit that finishes them.

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
  - [ ] Phase 2: decline with message, missed-call push actions, calls on/off + quiet hours, camera mid voice call, draggable self-view
- [ ] Device QA IOS-8: with a Focus mode silencing calls, CallKit shows no banner and the in-app ring closes — decide whether that is acceptable.
- [ ] Native review of the 18 machine-drafted call strings (`lib/l10n/app_*.arb`)
- [ ] Owner: LiveKit webhook URL in LiveKit Cloud; confirm `APNS_VOIP_*` on prod.
- [ ] Device QA: run every row of `docs/qa/calls-matrix.md` (IOS-3/IOS-5 repeat runs prove VoIP delivery survives repeated cancels); re-measure answered rate one week after release (target ≥ 40%).
- [ ] Calls: Dart `CallKitService` still sets the native ring `duration: 45000`; iOS VoIP path now uses 50 s (server owns the 45 s ring) — align the Dart side so iOS/Android never time out before the server.

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
- [ ] **Two bare `flutter: null` lines** after the overflow, source unidentified. Not from
      `matching_provider.dart` (those prints all carry an emoji prefix). Needs the action that produced
      them to locate.

Checked and NOT a bug, recorded so it is not re-reported: `GET /calls/current` returning `{call: null}`
immediately after a successful `POST /calls/initiate`. `callService.getCurrentCall` deliberately matches
a ringing call only when `initiator: { $ne: userId }` — `/current` answers "should I be shown an incoming
call or rejoin", and the caller already has the call on screen.

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
- [x] Matches renders through `GuideCard` too, so the five cards cannot drift apart visually, and
      `MatchCard.highlightSayHi` rings the TOP card's Say hi while the panel is up — the panel names
      the action, the ring says which button that is
- [x] AI Study → AI Tools; Chats → Community/Matches; Moments → composer; Profile → edit
- [x] `guide_shown` / `guide_cta_tapped`, both carrying `surface`, kept separate from the
      `first_session_*` events so neither funnel is polluted
- [x] 12 `app_en.arb` keys + `flutter gen-l10n`
- [ ] Native review of the 12 new guide strings (19 locales fall back to English)
- [x] Device pass 1 (2026-10-10): cards confirmed on AI Study, Chats, Moments, Profile; `guide_shown`
      fired once per surface. Found a crash — `PulseHighlight` recreated its controller on every
      rebuild, which `SingleTickerProviderStateMixin` forbids; the ErrorWidget that replaced the
      subtree then "overflowed" the page Column by ~99,000px. Fixed, 5 lifecycle tests added.
- [ ] Device pass 2: re-run after the ticker fix and confirm the log is clean
- [ ] Decide from `guide_cta_tapped` whether any surface needs a second, deeper guide. Deliberately
      one card per tab for now — AI Study in particular has three plausible activations ("do a lesson",
      "ask the tutor", "review vocabulary") and this picks the tutor.
- [ ] Guides are gated on `isNewUser` (≤6 days), so the existing install base never sees one. Revisit
      if the goal becomes activating dormant accounts rather than day-one retention.

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
