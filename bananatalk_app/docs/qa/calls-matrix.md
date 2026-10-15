# Calls — device QA matrix

Spec: `docs/superpowers/specs/2026-10-08-calls-reliability-design.md` §7.
Plan: `docs/superpowers/plans/2026-10-08-calls-reliability.md`.
Backend: prod `main` (calls Phase 1 + 2 deployed). Rows re-checked against the code on 2026-10-15 (app `main` 5873205a).
Record: date, build, device/OS, tester, ✅/❌ + note. Ring timeout is 45 s on the server; the app's 50 s is only a safety net.

Each core cell = caller rings the device under test; check (a) it rings within 3 s,
(b) accept connects both ways (audio both directions; video both tiles),
(c) hang-up from either side closes both screens, (d) the chat shows ONE call
bubble with the right label on both sides (§3), (e) nothing keeps ringing anywhere.

## 1. Core matrix

### iOS (latest)
| App state of callee | Type | Wi-Fi | Cellular |
|---|---|---|---|
| foreground | voice | | |
| foreground | video | | |
| background | voice | | |
| background | video | | |
| killed | voice | | |
| killed | video | | |
| after resume (bg ≥ 5 min, then open) | voice | | |
| after resume (bg ≥ 5 min, then open) | video | | |

### Android 13+
| App state of callee | Type | Wi-Fi | Cellular |
|---|---|---|---|
| foreground | voice | | |
| foreground | video | | |
| background | voice | | |
| background | video | | |
| killed | voice | | |
| killed | video | | |
| after resume (bg ≥ 5 min, then open) | voice | | |
| after resume (bg ≥ 5 min, then open) | video | | |

### Android 8
| App state of callee | Type | Wi-Fi | Cellular |
|---|---|---|---|
| foreground | voice | | |
| foreground | video | | |
| background | voice | | |
| background | video | | |
| killed | voice | | |
| killed | video | | |
| after resume (bg ≥ 5 min, then open) | voice | | |
| after resume (bg ≥ 5 min, then open) | video | | |

## 2. Scenarios

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| S-1 | Busy | A↔B in a call; C calls B | C sees "B was on another call" toast, never rings B; B gets one "Missed voice call" push; bubble in B–C chat: C "B was on another call", B "Missed voice call" | |
| S-2 | Decline | A calls B; B declines | A screen shows "Voice call declined" 1.5 s then closes; B screen closes; bubble A "Voice call declined", B "Declined voice call"; no missed push | |
| S-3 | Caller cancels while callee is killed | Kill B's app; A calls, B's CallKit/Android call UI rings; A hangs up after 10 s | B's native call UI disappears within 3 s; B gets "Missed voice call" push; bubble A "Cancelled voice call", B "Missed voice call" | |
| S-4 | No answer | A calls B; nobody answers | Ends at 45 s on both; A "Voice call · No answer" 1.5 s; B missed push; Calls-list badge on B = 1 | |
| S-5 | Two devices, one user | B signed in on phone + tablet; A calls; B answers on phone | Tablet stops ringing within 3 s (socket or call_cancelled); phone connects | |
| S-6 | Two devices, second accepts late | Same as S-5, then tap Accept on tablet within 1 s | Tablet dismisses silently (409), no error toast | |
| S-7 | Wi-Fi ↔ cellular mid-call | During a connected call toggle Wi-Fi off | "Reconnecting..." overlay ≤ 20 s, then audio resumes; if it can't, both screens close after 20 s ("Connection lost", English only) and the bubble says "Outgoing voice call · m:ss" / "Incoming voice call · m:ss" | |
| S-8 | Peer app killed mid-call | During a call force-quit A | B shows "Reconnecting...", call ends on B within ~20-40 s (webhook/sweeper); one bubble | |
| S-9 | Video: screen stays on | 3-min video call, no touches | Screen never dims/locks on either device | |
| S-10 | Video: camera paused | During video call A switches to another app 10 s, returns | B sees A's avatar tile with "Camera paused"; A's video returns on resume | |
| S-11 | Stale notification | Miss a call (S-4), wait 2 min, tap the incoming-call notification if still present | Opens the chat with A, does not ring | |
| S-12 | Live 2.6.1 build vs new backend | B on 2.6.1 (store), A on new build; run S-2, S-3, S-4 and a completed call both directions | 2.6.1 rings, connects, ends; its other devices stop ringing where supported; bubbles render from callData on 2.6.1 | |
| S-13 | Missed-call push | S-4 with B's app in background | One "📞 A / Missed voice call" push; tapping it opens the chat with A | |
| S-14 | Cold-start accept | Kill B; A calls; B accepts from the lock screen | App opens straight into the active call with the right name and type (video stays video) | |
| S-15 | Resume recovery: one ring UI | B backgrounded ≥ 5 min (socket dead); A calls; the native ring (CallKit / Android call screen) shows; B opens the app from the icon while it rings | iOS: exactly one ring UI — CallKit stays the only one (no in-app screen, no second ringtone) and accepting it joins the call. Android: the in-app incoming screen shows and only the native ringtone plays (see AND-8). If no native ring was showing (either OS), the in-app screen appears with its own ringtone; accept works | |
| S-16 | Calls list | Open chat tab → phone icon | Badge cleared after opening; rows show arrows (missed red), type, time, duration; tap row → chat; call-back button rings the same type | |

## 3. iOS-only (AppDelegate VoIP)

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| IOS-1 | VoIP while app killed | Kill app; receive a call | CallKit rings (no crash — the 24-hex id crash is gone) | |
| IOS-2 | VoIP while app backgrounded/inactive | App in background; receive a call | CallKit rings; accept joins the call | |
| IOS-3 | Cancel while ringing (killed) | S-3 on iPhone; repeat 5× in a row | CallKit UI ends within 3 s; no second ring; VoIP pushes keep arriving after repeated caller cancels (6th call still rings) | |
| IOS-4 | Cancel overtakes invite | Caller starts and cancels within ~1 s while iPhone is on poor network | No lingering ring; at most a sub-second CallKit flash; a late invite does not ring | |
| IOS-5 | Answered on another device | iPhone + iPad on the same account (both new build); answer on iPad; repeat 5× | iPhone CallKit ends; no "Unknown" call appears; VoIP pushes keep arriving on the iPhone afterwards | |
| IOS-6 | Foreground VoIP cancel | iPhone app open on the incoming screen; answer on the other device | In-app screen closes; any CallKit flash is ≤ 1 s | |
| IOS-7 | Unanswered call, app killed | Kill app; A calls; nobody answers | Rings until ~45 s, no second ring, no "Unknown" entry in Recents | |
| IOS-8 | Foreground VoIP: one ring UI | iPhone app open in a chat; A calls (repeat 5×) | Exactly one ring UI: CallKit's banner; an in-app screen that appeared first closes and its ringtone stops; accept from the banner joins the call; End on the CallKit UI ends it. Also with a Focus mode that silences calls: CallKit reports the call but shows no banner, so the in-app ring closes and only Recents/notification remains — verify this is acceptable (else scope the close to a visible CallKit UI) | |
| IOS-9 | In-app accept with CallKit up | Get both UIs as in IOS-8 on an old build, or accept from the in-app screen right as CallKit appears | CallKit ring stops at once; the call stays up (no instant hang-up from CallKit's echo) | |

## 4. Android-only

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| AND-1 | Voice call in background (Android 14) | Connected voice call; press Home for 2 min; talk | Peer hears you throughout; "Call in progress" ongoing notification shown; it disappears when the call ends | |
| AND-2 | Video call in background (Android 14) | Same with video | Audio continues; peer sees "Camera paused"; camera returns on resume; no crash (camera FGS type) | |
| AND-3 | Full-screen intent prompt | Fresh install on Android 14; receive one call (answered, declined or missed) | Only if BananaTalk is NOT already allowed under Settings → Apps → Special app access → Full-screen notifications: "Show calls on the lock screen" appears once, ~1 s after the call ends; "Open Settings" lands on the toggle; "Not Now" also counts — never shown again. If already allowed (Play may pre-grant it after the declaration), no explainer is expected | |
| AND-4 | Locked-phone ring after granting | AND-3 granted; lock phone; receive a call | Full-screen call UI, no duplicate notification (incoming push is data-only) | |
| AND-5 | Accept from the lock screen (Android 14) | Lock B; A calls (voice, then video); B accepts from the lock-screen call UI; then press Home | No crash; once the app is in front the "Call in progress" notification appears; audio keeps flowing after Home | |
| AND-6 | Camera revoked mid-call | During a video call open Settings → BananaTalk → Permissions → Camera → Deny; reopen BananaTalk | No crash; if the app restarts, no "Call in progress" notification is left without a call; a new video call asks for the camera again | |
| AND-7 | Swipe away mid-call | Connected call; swipe BananaTalk out of Recents | "Call in progress" notification disappears and does not come back; peer sees the call end within ~20 s | |
| AND-8 | Background, then open during the ring | B's app in background; A calls; the native call screen / heads-up rings; B opens BananaTalk from the icon or Recents while it rings (also: heads-up collapsed into the shade first; and after a force-stop) | The in-app incoming screen is always visible and only the native ringtone plays (no second ringtone); answering in-app stops the native ring and joins; declining declines; once answered, nothing from the native UI ends the call | |
| AND-9 | No duplicate missed notification from CallKit | Android 13+, app swiped away; delay the cancel (Doze, or airplane mode during the ring, back on after > 50 s); A calls and cancels | Exactly one missed-call notification — the app's own, with Call back / Message; no plain CallKit "Missed call" | |
| AND-10 | Release build: native call UI is signature-protected | Play internal-track build, app killed, phone locked; receive calls; use Accept and Decline from the full-screen UI and from the heads-up notification | All four work; Decline leaves A with "Voice call declined" | |
| AND-11 | Bluetooth headset (Android 12+) | Pair a BT headset; voice call, then video call | Record whether the headset is selectable and used. If not → open item "request BLUETOOTH_CONNECT at runtime" | |

## 5. Phase 2 (decline message, push actions, calls off, camera, self-view)

Backend with C1–C4 deployed; app with C5–C10. Record as above.

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| CALL2-1 | Decline with a canned reply | B's app open; A calls; B taps Message → first canned reply | A's screen shows "Voice call declined" for 1.5 s, then closes; A's chat shows the call bubble ("Voice call declined"), then B's text below it; B sees "Declined voice call" then its own text, same order | |
| CALL2-2 | Decline with a custom reply | As CALL2-1, type past the limit (include emoji) | Field stops at 200 UTF-16 units (an emoji counts as 2+), never splitting an emoji; the text that arrives equals what the field showed; the decline always goes through | |
| CALL2-3 | Missed push actions, iOS killed | Kill B's app; A calls, cancels | Missed notification shows Call back / Message (long-press); Call back opens the app on A's chat and rings A (same voice/video type); Message opens the chat | |
| CALL2-4 | Missed push actions, iOS background + foreground | Repeat with B in background, then in foreground (banner) | Same as CALL2-3; no duplicate notification | |
| CALL2-5 | Missed push actions, Android 13+ killed / background / foreground | Repeat CALL2-3 on Android | One notification with two buttons; Call back starts the call after the app opens; Message opens the chat | |
| CALL2-6 | Live build unaffected | B on 2.6.1 (Android + iOS); A misses a call to B | B gets the same missed notification as today (no blank one) | |
| CALL2-7 | Calls off | B: Profile tab → ☰ menu → Preferences → Notifications → Calls → "Allow calls" off; A calls | A sees "B isn't taking calls right now"; B's phone does nothing; no bubble on either side; turning it back on lets A's next call ring | |
| CALL2-8 | Quiet hours | B: Profile → ☰ → Preferences → Notifications → Quiet Hours → Enable, window covering now, **"Allow urgent notifications" OFF**; A calls. Then (a) turn Allow urgent back on, A calls; (b) disable quiet hours, A calls | With Allow urgent off: same as CALL2-7. (a) and (b): rings. (Allow urgent is ON by default, so default quiet hours never hold calls — not a fail) | |
| CALL2-9 | Camera on mid voice call | Voice call connected; A taps Camera (grant permission on first use) | B sees A's video; B's controls become video controls; B can turn its camera on; after hang-up the bubbles say "Outgoing video call · m:ss" / "Incoming video call · m:ss" and the Calls list row shows the video icon | |
| CALL2-10 | Camera on, permission denied | As CALL2-9 with camera permission denied | One permission message (not two); the call continues as voice | |
| CALL2-11 | Upgrade against a live peer | A on the new build, B on 2.6.1; A taps Camera | B's call keeps going (audio); B shows no video — accepted limitation | |
| CALL2-12 | Self-view | Video call; drag the self-view to each corner; tap it | Snaps to the nearest corner; tap swaps big/small; tap again swaps back | |
| CALL2-13 | Android background after upgrade | CALL2-9 on Android 14, press Home for 1 min, return | Audio continues; camera pauses and returns; no crash (camera FGS type) | |
| CALL2-14 | Android missed call: Doze + aggressive OEM | B on a Xiaomi or Samsung, app swiped away, phone idle ≥ 30 min (Doze); A calls, cancels. Repeat with airplane mode on during the avatar download | The missed notification still appears with Call back / Message; with the failed avatar a plain missed notification still appears (never nothing) | |
| CALL2-15 | One action fires once | From CALL2-3/5 tap Call back once, then also tap the notification body / reopen from Recents | Exactly one chat screen and one outgoing call | |
| CALL2-16 | iOS foreground banners unchanged | B in foreground: receive a moment like, a follow, an announcement, then a missed call | Only the missed call shows a banner (with buttons); the others only change the badge, as before; Xcode console shows no "completion handler called twice" | |
| CALL2-17 | Camera re-enable on a video call, network blip | Video call; A turns camera off; turn on Wi-Fi off/airplane for 2 s; A turns camera on | Camera and the on-screen camera state always match (never "off" on A while B sees A's video) | |
| CALL2-18 | Swap does not come back by itself | Video call; tap self-view to swap; peer turns camera off, then on after 30 s | Layout returns to peer-big and stays there until A taps again | |
| CALL2-19 | Decline message vs caller hang-up | B opens the Message sheet; A hangs up before B sends | Sheet and incoming screen close; no decline is sent and no text arrives; A's screen closes at once (no banner); bubble A "Cancelled voice call", B "Missed voice call"; B gets one missed-call notification | |
| CALL2-20 | Call back to an unavailable callee | A has Allow calls off; B taps Call back on A's missed call | B sees the localized "isn't taking calls right now" message; no crash | |
| CALL2-21 | Peer upgrade while phone at the ear | Voice call, B holds the phone to the ear; A taps Camera | B's audio **stays on the earpiece** and B's screen stays on (no timeout while watching A); when B taps "Video On", B's audio moves to the loudspeaker once; turning the camera off and on again does not move it a second time (there is no speaker button in the video layout) | |
| CALL2-22 | Upgrade with a Bluetooth headset | Voice call on a BT headset; either side upgrades to video | iOS: audio stays on the headset; hang-up restores normal routing. **Android 12+: known risk** — the code forces the loudspeaker on the side that turns its camera on (`setSpeakerOn(true)` → flutter_webrtc selects Speakerphone), and the headset may not be selectable at all (BLUETOOTH_CONNECT never requested). Record what happens; a fail is the open item in REMAINING_WORK, not a regression | |
| CALL2-23 | Rejoin after kill (camera off, no forced speaker) | On the CALLEE that accepted from the lock-screen / native call UI: video call connected; kill the app; reopen within ~15 s (server ends it after a 20 s grace) | Rejoins with the camera off (video layout, peer sees "Camera paused"), audio route unchanged; "Video On" moves audio to the loudspeaker once. Caller side and in-app accepts never rejoin (by design): the peer sees the call end after ~20 s. Fixed 2026-10-15 (91b5002d: cold start no longer re-accepts an active call). Also confirm: answering from the lock screen while the app is killed still connects (S-14). iOS may end the CallKit call itself when the process dies; if so iOS cannot rejoin (no native entry) — record which | |
| CALL2-24 | Decline message with Korean/Japanese IME | B opens Message, types Korean up to ~200 units, keeps composing past the limit, then commits | Never cut mid-composition; after commit the field is ≤ 200 units with the cursor in place; the text arrives whole | |
| CALL2-25 | Decline message not delivered | A blocks B (second device / web) while the call rings — or B is non-VIP at the daily message cap; B declines with a message | B's screen closes, then a "Failed to send message" snackbar; A sees "Voice call declined" and no text; the decline itself stands | |
| CALL2-26 | Missed accept, then upgrade, connects as video | A calls B; A turns airplane mode on ~3 s just as B accepts, then off; once connected B taps Camera | A switches to the video layout with its camera off, audio route unchanged; "Video On" then moves audio to the loudspeaker once; history says video | |
| CALL2-27 | Peer upgrade keeps route, wakelock, video service (Android 14) | Voice call, B on Android 14 at the ear; A taps Camera; B leaves the screen untouched 2 min, then Home for 1 min, returns | B stays on the earpiece, screen never dims, audio continues in background, no crash, "Call in progress" stays; "Video On" afterwards works | |
| CALL2-28 | Quiet hours use the phone's timezone | B's phone set to a far zone (e.g. America/New_York); quiet hours = the next hour in local time, Allow urgent OFF, save; A calls; then move the window off local now | First call refused ("B isn't taking calls right now"); after the change it rings | |
