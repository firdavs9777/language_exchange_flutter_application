# Onboarding, launch pop-ups and announcements — device QA matrix

Spec: `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md`.
Plan: `docs/superpowers/plans/2026-10-12-onboarding-announcements.md`.
Needs a release build and a backend with announcements deployed. Record: date, build, device/OS, tester, pass/fail + note.
Use fresh accounts for section 1; set the launch-time conditions explicitly for sections 2-5.

## 1. New account, first week

Guide period = 7 days after signup, ending early at 3 of 4 activation actions
(message sent, moment created, lesson completed, profile = photo + bio).

| Step | Expected | Result |
|---|---|---|
| Day 0: open Matches, Moments, Chat tabs | Each shows its guide, headed "Getting started · 0 of 4" | |
| Tap a guide CTA only (no real action) | Guide stays; CTA does not retire it | |
| Send a message | Chat guide retires; counter reads 1 of 4; `activation_milestone` + `guide_retired` logged | |
| Create a moment (not like/comment) | Moments guide retires; counter 2 of 4 | |
| Complete a lesson | Counter 3 of 4; all remaining guides stop (reason `milestones`) | |
| Different account: complete profile (photo + bio) | Profile counts; photo alone or bio alone does not | |
| Different account: do nothing for 7 days (or set clock +7d) | Guides stop (reason `window`) | |
| Existing user who messaged / filled profile before this release | Matching guide does not reappear (back-fill) | |
| Kill and relaunch mid-week | Counter and retired guides persist; no duplicate `guide_retired` | |
| Sign in as a second user on same device | Activation state is per user | |

## 2. Launch pop-up order (one per launch)

Order: update -> announcement -> ads notice -> feature spotlight.

| Condition at launch | Expected | Result |
|---|---|---|
| Update available + live announcement | Only the update dialog | |
| No update, announcement live, ads notice due | Only the announcement; ads notice on a later launch | |
| Only ads notice due | Ads notice | |
| Only spotlight due | Spotlight (AI Study promo is part of this rotation) | |
| Guide period (new account), announcement + spotlight due | Neither shown; only update and ads notice are allowed | |
| Guide period, update available | Update shown | |
| Splash welcome-back pop-up also due | Never stacks with a launch pop-up (shared budget) | |
| Update dialog shown on a launch | That absence's welcome-back is not shown (one pop-up per launch, by design) | |
| Notification tap within 1 s of launch | No launch pop-up this process; it shows next launch | |

## 3. Chat tip

| Step | Expected | Result |
|---|---|---|
| New account receives first text message | Tip appears once under that message | |
| Receive a second message | No second tip | |
| Tip after guide period ends | Not shown | |
| Reopen the chat | Tip retired; no repeat | |

## 4. Notification priming

| Trigger | Expected | Result |
|---|---|---|
| First matches shown | Prime shown once; `notification_prime_shown` (first_matches) | |
| First wave sent | Prime shown if not already shown | |
| First message sent / first message received | Prime shown if not already shown | |
| Opening a chat | Does NOT trigger priming | |
| Another pop-up already shown this launch | Prime deferred (budget) | |
| Choose Allow / Not now / Later | `notification_prime_result` granted / declined / later; OS permission asked only on Allow | |
| OS permission already granted | No prime | |

## 5. Announcements (admin publish through to the device)

| Scenario | Expected | Result |
|---|---|---|
| Admin publishes (notify on) | Push arrives; respects the Announcements setting and quiet hours | |
| Tap the push | Opens `/announcement/:id` with the text in the user's language | |
| Notifications list | Exactly one announcement row, even if published twice or server restarted mid-delivery | |
| Launch app with it live | In-app pop-up appears (when no higher-priority pop-up and not in guide period); shown once per user | |
| Relaunch | Same announcement not shown again | |
| Settings -> Notifications -> Announcements off | No push; list row still written | |
| Scheduled for 5 min ahead | Nothing before start; push + pop-up after the minute tick | |
| Two announcements live at once | Higher priority first, then newer startsAt; the other on the next launch | |
| Several live across launches | One per launch, each once, until all seen | |
| Language without a translation | Default-language text, never empty | |
| Admin ends it | Not in next launch's pop-up; existing notification-list row remains and still opens | |
| Old build (before this release) | Legacy single-announcement behavior unchanged | |
| Suspended account | Suspension screen shows the ban reason | |
