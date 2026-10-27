# 모임 / Gatherings & Clubs — what is implemented

**As of:** 2026-10-27, read from the code in `backend/`, `bananatalk_app/` and `front/`.
Nothing here was run against production.

**Design:** `BananaTalk/docs/superpowers/specs/2026-09-15-gatherings-design.md`
(the club amendment is §1.5, line 32)
**Plan:** `BananaTalk/docs/superpowers/plans/2026-09-16-gatherings.md`
Both live in the top-level `BananaTalk/docs` repo, not in any of the three app repos.

---

## At a glance

| Area | State |
|---|---|
| Clubs (create, join, manage, cover) | **Done**: backend, app, web |
| Gatherings (create, list, RSVP, approval, edit, cancel, end) | **Done**: backend, app, web |
| Quorum and the host's T-2h decision | **Done** |
| Reminders (24h push + email + `.ics`, 10 min push) | **Done** |
| Event notifications (created, confirmed, join request/decision, ended) | **Done** |
| Free first message between attendees | **Done** on the backend |
| Blocking, reporting, host removes someone | **Done** |
| Host reliability ("abandoned" gatherings block hosting) | **Fixed 2026-10-27** (backend `04c3832`, needs deploy) |
| "Who was there" card after a gathering | **Built 2026-10-27**: backend `people` + app card (needs backend deploy) |
| Start a gathering → open a VoiceRoom (plan Task 7) | **Not built.** Blocked on the two-phone audio test |
| "Repeat this gathering" (spec §2.1) | **Not built** |
| In-person meetups (`offline_meetup`) | Modelled, refused by the API, as the spec intends |
| Admin console (list, archive club, cancel gathering) | **Done** |

---

## Feature switch

- `GATHERINGS_ENABLED` in `backend/config/limitations.js:123` **defaults to ON**. The spec
  said OFF. The comment says you turned it on so you could create the first clubs and
  gatherings by hand.
- When it is off, every `/api/v1/gatherings` and `/api/v1/clubs` route returns 404 (the
  check runs before login), and the reminder job skips its tick.
- The app reads `gatheringsEnabled` from app config (default `true`). When it is on, the
  Gatherings tab replaces Voice rooms in Community (`lib/pages/community/main/community_main.dart:610`).
- The website has its own switch, `WEB_GATHERINGS_ENABLED`, which is **OFF**.

---

## Backend

### Files

| File | What it does |
|---|---|
| `models/Club.js` | The club: language (base code), free-text interest, owner, members with roles, `memberCount`, cover. `city` and `place` are stored |
| `models/Gathering.js` | The event: every spec §2 field, plus `club`, `topic`, `coverImage`, `hostTimezone`, `remindersSent`, `hostDecisionAskedAt`, `hostAttended`, `voiceRoom` |
| `controllers/clubs.js` | Club endpoints (below) |
| `controllers/gatherings.js` | Gathering endpoints (below) |
| `controllers/adminContent.js` | Admin: list clubs and gatherings, archive a club, cancel a gathering |
| `lib/gatheringQuorum.js` | Pure functions: quorum state, capacity, can-join, is the T-2h decision due. Default capacity 6, quorum 3. Also holds the feature-switch guard |
| `lib/gatheringSchedule.js` | Pure functions: reminder offsets (24h, 10 min) and the local day |
| `lib/gatheringFilters.js` | Fixed topic list (conversation, exam_prep, grammar, pronunciation, culture, media, games, business, travel), time windows, "has a seat" |
| `lib/gatheringInvite.js` | Builds the `.ics` calendar invite |
| `lib/gatheringAcquaintance.js` | "Did these two attend the same gathering?" for the messaging cap |
| `lib/hostReliability.js` | Can this person host? 2 gatherings of grace, then blocked above a 50% abandon rate |
| `lib/clubMembers.js` | Member preview, role counts, who can manage |
| `jobs/gatheringReminders.js` | Every 5 minutes (`jobs/scheduler.js`): 24h and 10-minute reminders and the T-2h host question. Also cancellation and time-change messages |
| `services/gatheringNotifications.js` | Created, confirmed, join request, approved/denied, ended. Written to in-app history via `notificationService` |

### Club endpoints: `/api/v1/clubs`

| Method | Path | Who |
|---|---|---|
| GET | `/` | anyone. Defaults to my languages, busiest first; `scope=all`, `scope=member`, `language`, `interest` |
| POST | `/` | anyone. The creator becomes the owner and first member |
| GET | `/:id` | anyone. Includes up to 10 upcoming gatherings and the past-gathering count |
| PATCH/PUT | `/:id` | owner or organizer. Name, description, interest, city, place. Language can't be changed |
| DELETE | `/:id` | owner only. Its gatherings are detached and keep going on their own |
| POST / DELETE | `/:id/join` | join (one tap, no approval) / leave. The owner can't leave |
| POST / DELETE | `/:id/cover` | owner or organizer |
| DELETE | `/:id/members/:userId` | owner or organizer. Only the owner can remove an organizer |
| PATCH/PUT | `/:id/members/:userId` | owner only. Makes someone an organizer or member |

Blocked owners' clubs are hidden, and you can't join them.

### Gathering endpoints: `/api/v1/gatherings`

| Method | Path | Who |
|---|---|---|
| GET | `/` | anyone. Defaults to upcoming, in my languages, soonest first. Filters: `scope=all/me`, `language`, `level`, `type`, `topic`, `when`, `hasSeat` |
| POST | `/` | anyone who can still host. Must be in the future and online only. When it belongs to a club, only members can create it. The host counts as going |
| GET | `/:id` | anyone except people the host blocked (they get 404) |
| PATCH/PUT | `/:id` | host. Capacity can't drop below the people already going. Moving the time tells everyone going |
| DELETE | `/:id` | host cancels. Everyone going gets push and email |
| POST / DELETE | `/:id/rsvp` | join (or request, in approval mode) / leave. Seats are claimed atomically. The host can't leave their own gathering |
| POST | `/:id/decision` | host answers the T-2h question: `{ run: true/false }` |
| POST | `/:id/end` | host, only after the start time. Sets `hostAttended = true` |
| POST | `/:id/requests/:userId` | host approves or denies a join request |
| DELETE | `/:id/attendees/:userId` | host removes someone |
| POST / DELETE | `/:id/cover` | host |

Status moves `scheduled → confirmed` when the people going reach quorum, and back to
`scheduled` if someone leaves or is removed. **Nothing ever sets `live`.**

### Notifications

| Event | Push | Email | In-app | Where |
|---|---|---|---|---|
| Gathering created in your language | yes (max 100 recently active users, daily cap) | no | yes | `gatheringNotifications.js` |
| Join requested (to host) | yes | no | yes | same |
| Approved / denied | yes | no | yes | same |
| Quorum reached | yes | no | yes | same |
| 24h before | yes | **yes, with `.ics`** | **no** | `gatheringReminders.js` |
| 10 min before | yes | no | **no** | same |
| Host decision due (T-2h) | yes | yes | **no** | same |
| Cancelled (host, T-2h "cancel", admin) | yes | yes | **no** | same |
| Time moved | yes | yes | **no** | same |
| Ended | yes | no | yes | `gatheringNotifications.js` |

Email strings exist for 8 locales (`email_templates/`). Push and in-app strings are in
`notification_templates/`.

### Tests

`test/`: `clubs`, `clubManagement`, `clubMembers`, `clubMemberScope`,
`clubViewerIsMember`, `gatherings`, `gatheringQuorum`, `gatheringFilters`,
`gatheringDiscoveryFilters`, `gatheringInvite`, `gatheringReminders`,
`gatheringNotifications`, `gatheringCapExemption`, `gatheringsKillSwitch`,
`webFeatureContracts`, `webFeatureFlags`, `privacyFollowups`.

---

## App (`bananatalk_app`)

- **API client:** `lib/services/gathering_api_client.dart` covers every endpoint above.
- **Model:** `lib/models/community/gathering_model.dart`.
- **Screens:** `lib/pages/community/gatherings/`
  - `gatherings_tab.dart`: Gatherings and Clubs inner tabs, a filter bar, a + button. When
    the list is empty it shows a pre-filled create form (your language, tomorrow evening,
    6 seats, quorum 3), as spec §4.3 asks
  - `gathering_card.dart`: quorum text ("N more needed" / "Confirmed"), local time with the
    host's zone, cover
  - `gathering_detail_screen.dart`: RSVP, request / withdraw a pending request, leave.
    The host gets approve/deny, the T-2h decision, End (only after the start time),
    edit, cover and cancel
  - `create_gathering_form.dart`, `create_club_sheet.dart`, `club_detail_screen.dart`,
    `club_people_section.dart`, `my_gatherings_screen.dart` (also opened from Profile:
    `lib/pages/profile/profile_main/sections/my_gatherings_entry.dart`)
  - `gathering_safety_menu.dart`: report or block for a gathering or a club (the
    `Report` model accepts `gathering` and `club`)
- **Push taps:** `lib/services/notification_router.dart:364` opens `/gathering/:id` for
  every `gathering_*` type, including `gathering_time_changed`.
- **Strings:** in all app locales (`lib/l10n/`).
- **Uncommitted right now:** changes to `gathering_model.dart`, `gathering_card.dart`,
  `gathering_detail_screen.dart`, the l10n files, and a new
  `test/community/gathering_pending_request_test.dart` (pending join request, CO2).

## Website (`front`)

`src/components/gatherings/`: home, cards, detail, create/edit forms for gatherings and
clubs, host panel, club owner actions, people, cover editor, safety menu, each with tests.
The admin console has a clubs/gatherings view (`src/components/admin/`). All of it is
behind `WEB_GATHERINGS_ENABLED`, which is off.

---

## Gaps and bugs found

Fixed 2026-10-27 (backend `04c3832`, deploy pending; the app half is in the parent repo):

1. ~~Host reliability never blocks anyone.~~ The reminder tick now closes out a gathering
   12 h past its scheduled end as `ended` + `hostAttended: false`, only for gatherings
   starting on/after 2026-10-27 (older ones, including seeded ones, never count). Those
   rows grant no cap exemption and show no guest list.
2. ~~No "who was there" card.~~ `GET /gatherings/:id` sends `people` (once it is
   live/ended, only to someone who was going, minus blocked users). The detail screen
   shows "Who was there", each with a Message button that opens the chat, plus a line
   saying the first message doesn't count toward the daily limit.
3. ~~"Cancel" at T-2h tells nobody.~~ It now calls `notifyCancellation`.
4. ~~An admin cancel tells nobody.~~ It now notifies and sets `cancelledAt`.
5. ~~"Time moved" shows UTC.~~ It uses each recipient's local time; the app routes its tap.

Still open:

6. **Some reminders don't reach in-app history.** The 24h, 10-minute, T-2h, cancel and
   time-moved messages go straight through `fcmService`, not `notificationService`, so
   they leave no in-app row, which spec §5.1 requires. Users with no push token (65%)
   only get the email, or nothing for the 10-minute one.
7. **"Has hosted N gatherings" isn't shown.** `hostRecordLabel` exists in
   `lib/hostReliability.js`, but nothing calls it.
8. **Club `city` / `place` can be set.** The spec wants them unreachable, but
   `PATCH /clubs/:id` accepts both. This only matters if in-person clubs need to stay
   off, since in-person meetups carry the 18+ rule.
9. **Not built:** "repeat this gathering" (no endpoint or button; `repeatedFrom` is never
   written), and start → VoiceRoom (plan Task 7: no start endpoint, `voiceRoom` never
   set, no `live` status). Ending a gathering relies on the clock, not on people being
   in the call.
10. **The website** has no attendee card yet (it is switched off).

## Still open outside the code

- **Two-way audio on two real phones** (plan Task 0). Only you can do this, and it
  blocks Task 7.
- **Do reminder emails reach the inbox?** (spec §5.3). Gmail has put `banatalk.com` mail
  in spam before.
- **Seeding:** the spec assumes you host the first gatherings for about a month.
- Already listed elsewhere: gathering/club cover from the camera
  (`docs/REMAINING_WORK.md:91`); add host-decision calls to the web contract tests
  (`backend/docs/REMAINING_WORK.md:139`).
