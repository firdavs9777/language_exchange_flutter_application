# Onboarding, launch pop-ups and announcements — device QA matrix

Spec: `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md`.
Plan: `docs/superpowers/plans/2026-10-12-onboarding-announcements.md`.
Rows re-checked against the code on 2026-10-15 (app `main` 5873205a, backend 9d36fe0, web a944011).
Needs a release build and a backend with announcements deployed. Record: date, build, device/OS, tester, pass/fail + note.
Use fresh accounts for section 1; set the launch-time conditions explicitly for sections 2-5.

Preconditions:
- **Matches rows need `MATCHES_LAYOUT_ENABLED=true`** on the backend (default false; it gates the Matches tab, its guide,
  the "Say hi" ring, `first_session_*` events and the `first_matches` prime). **The live 2.6.1 reads this flag too**, so flipping it on prod
  launches the Matches layout for everyone — use a local backend (`study-hub-matrix.md` §0 option A) or skip the Matches rows.
- **AI Study has two guides**, picked by `STUDY_HUB_ENABLED` (see `study-hub-matrix.md` §0; a flip applies from the second cold start):
  off (2.7.0 default) "Practise before you have to" with "Open AI Tools" / "Exam Study"; on "Your daily language gym" with
  "Start today's pack" / "See all features".
- **Section 4 can only pass on iOS** — see the note there.

## 1. New account, first week

Guide period = 7 days after signup, ending early at 3 of 4 activation actions
(message sent, moment created, lesson completed, profile = photo + bio). Guides show only while fewer than 3 are done.

| Step | Expected | Result |
|---|---|---|
| Day 0: open AI Study, Community → Matches, Chats, Moments (Moments sub-tab, not Reels), Profile | Each shows its guide with "Getting started · 0 of 4" under the body. Chats only while the chat list is empty; Profile only until photo + bio; Matches needs a non-empty batch | |
| Matches: tap "Say hi" on the top card while the panel shows | Say hi ringed (pulse); `first_session_guidance_shown` on show, `first_session_say_hi_tapped` (position) on tap | |
| Tap a guide CTA only (no real action) | Guide stays; CTA does not retire it | |
| AI Study guide buttons | Hub on: "Start today's pack" opens the pack (known: dead tap while the pack is loading), "See all features" scrolls to the groups. Legacy: "Open AI Tools" / "Exam Study" switch sub-tabs. Neither retires the guide | |
| Send a message | Chats and Matches guides retire; others read 1 of 4; `activation_milestone` (message, 1), `guide_retired` (chats / matches, `acted` — only for guides already shown), `first_message_sent` | |
| Create a moment (not like/comment) | Moments guide retires (`guide_retired` moments/acted); counter 2 of 4. A reel also counts; a story does not | |
| Complete a lesson (or a quiz, a vocab review card, a daily-pack station, or get one AI tutor/roleplay reply) | `activation_milestone` (lesson, 3); every guide disappears; `guide_retired` ai_study/`acted`, profile/`milestones` | |
| Different account, tutor only: get one AI tutor reply | AI Study guide retires (ai_study/acted); counter +1 | |
| Different account: complete profile (photo + bio) | Profile counts; photo alone or bio alone does not | |
| Different account: do nothing for 7 days (or set clock +7d) | Guides stop (reason `window`) | |
| Existing user who messaged / filled profile before this release (same device, upgraded in place) | Matching guide does not reappear (back-fill) | |
| Kill and relaunch mid-week | Counter and retired guides persist; no duplicate `guide_retired` | |
| Log out, sign in as a second user on the same device | Second user starts clean (0 of 4, no retired guides). Logging back into the first user resets its state too: only profile is re-detected from the server; message is not recovered. Priming and ads notice do not repeat on this install | |
| Hub on, inside the guide period | No announcement carousel on AI Study; after the guide period, live announcements appear there until dismissed | |
| Guides pass 2 (debug build): visit every tab with a guide showing | No ticker/animation errors in the log (PulseHighlight fix e5b0c5c1) | |

## 2. Launch pop-up order (one per launch)

Order: update -> announcement -> ads notice -> feature spotlight.

| Condition at launch | Expected | Result |
|---|---|---|
| Update available + live announcement | Only the update dialog | |
| No update, announcement live, ads notice due | Only the announcement; ads notice on a later launch | |
| Account past the guide period, only ads notice due | Ads notice (once per install) | |
| Only spotlight due | Spotlight, at most once per day; the AI Study promo is in the rotation only while no lesson is done | |
| Guide period (new account), announcement + spotlight + ads notice due | None of them shown. Only the update dialog can show in the guide period; the slot stays free for notification priming | |
| Guide period, update available | Update shown | |
| Splash welcome-back pop-up also due | Never stacks with a launch pop-up (shared budget) | |
| Update dialog shown on a launch | Welcome-back not shown on this launch; it shows on the next launch (unless an update dialog shows again) | |
| Notification tap within 1 s of launch | No launch pop-up this process; it shows next launch | |

## 3. Chat tip

| Step | Expected | Result |
|---|---|---|
| New account receives first text message | Tip appears once under that message | |
| Receive a second message | No second tip | |
| Tip after guide period ends | Not shown | |
| Reopen the chat without long-pressing | Tip still there (showing it does not retire it) | |
| Long-press any message (or tap ✕), then reopen and relaunch | Gone for good; `guide_cta_tapped` chat_tip / primary (or dismiss) | |
| Second 1:1 chat with a received message, same run | The tip can move to that chat (one tip per app run). Group chats never show it | |

## 4. Notification priming

**Android: no prime is expected on 2.7.0 as of 2026-10-15.** firebase_messaging on Android only reports authorized/denied, never
"not asked", so a fresh Android 13+ install reads as denied → `recover` → no prime (and Android ≤ 12 is authorized by default).
Run this section on iOS; on Android just record that no prime shows. Code item in REMAINING_WORK.

| Trigger | Expected | Result |
|---|---|---|
| Community tab selected, first matches shown | Prime shown once; `notification_prime_shown` (first_matches) | |
| Waves tab first shows received waves | Prime shown if not already shown (`first_wave`) | |
| First message sent / first message received (live, while that chat is open — not a push) | Prime shown if not already shown | |
| Opening a chat | Does NOT trigger priming | |
| Another pop-up already shown this launch | Prime deferred (budget) | |
| Choose "Turn on" / "Not now" / swipe away | Turn on → OS dialog → `notification_prime_result` granted (allow) / declined (deny). Not now or swipe → `later`, no OS dialog, never offered again on this install | |
| OS permission fully granted | No prime. iOS quiet (provisional) permission granted at first launch still gets the prime | |

## 5. Announcements (admin publish through to the device)

| Scenario | Expected | Result |
|---|---|---|
| Admin publishes (notify on) | Push arrives. With the Announcements toggle off or in quiet hours the push is dropped, not delayed. Push text uses the user's stored server language; pop-up and detail use the app language | |
| Tap the push | Opens `/announcement/:id` in the app language | |
| Open the announcement from the push, then relaunch | No pop-up (opening it marks it seen) | |
| Notifications list | Exactly one announcement row, even if published twice or server restarted mid-delivery | |
| Launch app with it live (Show in app on) | Pop-up ~1 s after the tab bar appears (when no higher-priority pop-up and not in guide period); shown once per user | |
| Show in app off, notify on | Push + list row, no launch pop-up | |
| Relaunch | Same announcement not shown again | |
| Settings -> Notifications -> Announcements off | No push; list row still written | |
| Settings -> Notifications -> master switch off | Announcements toggle greyed and off; no push; list row still written | |
| Scheduled for 5 min ahead | Nothing before start; after start the pop-up shows on the next launch, push within ~60 s | |
| Two announcements live at once | Higher priority first, then newer startsAt; the other on the next launch | |
| Several live across launches | One per launch, each once, until all seen | |
| Language without a translation | Default-language text, never empty | |
| Languages = [ko], device app language en | No pop-up. Push and list row only for users whose stored language is ko (English targeting also catches users with none) | |
| Platforms = Web only (or iOS only, tested on Android) | Nothing on that device | |
| Banner-style announcement | Nothing on the device (no pop-up, push or list row) — web only | |
| Admin ends it | Not in next launch's pop-up; existing notification-list row remains and still opens | |
| Old build (2.6.1) | Gets only announcements with no language targeting, pop-up style, app platforms, as the legacy single pop-up; button hidden unless it is an http(s) link | |
| Suspended account | Suspension screen shows the ban reason; no reason set → generic "no access" text | |
