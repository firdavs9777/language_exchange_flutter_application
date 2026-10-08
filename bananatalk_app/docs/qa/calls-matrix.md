# Calls — device QA matrix

Spec: `docs/superpowers/specs/2026-10-08-calls-reliability-design.md` §7.
Plan: `docs/superpowers/plans/2026-10-08-calls-reliability.md`.
Backend must be on the calls-reliability build. Record: date, build, device/OS, tester, ✅/❌ + note.

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
| S-7 | Wi-Fi ↔ cellular mid-call | During a connected call toggle Wi-Fi off | "Reconnecting…" overlay ≤ 20 s, then audio resumes; if it can't, both screens close after 20 s and the bubble says Outgoing/Incoming · m:ss | |
| S-8 | Peer app killed mid-call | During a call force-quit A | B shows "Reconnecting…", call ends on B within ~20-40 s (webhook/sweeper); one bubble | |
| S-9 | Video: screen stays on | 3-min video call, no touches | Screen never dims/locks on either device | |
| S-10 | Video: camera paused | During video call A switches to another app 10 s, returns | B sees A's avatar tile with "Camera paused"; A's video returns on resume | |
| S-11 | Stale notification | Miss a call (S-4), wait 2 min, tap the incoming-call notification if still present | Opens the chat with A, does not ring | |
| S-12 | Live 2.6.1 build vs new backend | B on 2.6.1 (store), A on new build; run S-2, S-3, S-4 and a completed call both directions | 2.6.1 rings, connects, ends; its other devices stop ringing where supported; bubbles render from callData on 2.6.1 | |
| S-13 | Missed-call push | S-4 with B's app in background | One "📞 A / Missed voice call" push; tapping it opens the chat with A | |
| S-14 | Cold-start accept | Kill B; A calls; B accepts from the lock screen | App opens straight into the active call with the right name and type (video stays video) | |
| S-15 | Resume recovery | B backgrounded ≥ 5 min (socket dead); A calls; B opens the app from the icon while ringing | In-app incoming screen appears; accept works | |
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

## 4. Android-only

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| AND-1 | Voice call in background (Android 14) | Connected voice call; press Home for 2 min; talk | Peer hears you throughout; "Call in progress" ongoing notification shown; it disappears when the call ends | |
| AND-2 | Video call in background (Android 14) | Same with video | Audio continues; peer sees "Camera paused"; camera returns on resume; no crash (camera FGS type) | |
| AND-3 | Full-screen intent prompt | Fresh install on Android 14; receive and finish one call | Explainer appears once after the call; "Open settings" lands on the full-screen-intent toggle; never shown again | |
| AND-4 | Locked-phone ring after granting | AND-3 granted; lock phone; receive a call | Full-screen call UI, no duplicate notification (incoming push is data-only) | |
