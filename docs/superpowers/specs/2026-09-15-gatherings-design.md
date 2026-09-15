# 모임 / Gatherings — Design

**Date:** 2026-09-15
**Status:** approved, ready for implementation planning
**Goal:** give people a reason to meet each other, on a schedule, in a way that survives
a base of ~800 active users.

---

## 1. The problem, measured

BananaTalk has shipped two group features. **Both produced zero group interactions.**

**Voice rooms:** 91 created by 57 distinct hosts, every one now `ended`.
**Average participants 0.5. Maximum ever 1.** Not one voice room has ever held two
people. Zero were ever scheduled.

**Language rooms** (Workstream D, built on group conversations):
**zero conversations with more than two participants have ever existed.** The feature
shipped and was never used once.

The cause is structural. Both require **simultaneous presence**: someone must be online,
browsing, speaking a compatible language, at the same moment. Across ~800 active users,
40+ target languages and every timezone, that probability rounds to zero. No amount of UI
fixes it.

**The constraint this design is built around: anything depending on coincidental presence
will fail at this scale. Commitment made in advance is the only mechanic that works.**

---

## 2. What a Gathering is

One typed entity, so a new type is a row rather than a rewrite.

| Field | Purpose |
|---|---|
| `type` | `online_event` (launch), `offline_meetup`, `interest_group` (flagged off) |
| `host`, `coHosts` | mirrors the VoiceRoom ownership shape |
| `title`, `description` | |
| `language` | base code via `toBaseLanguage` — the spine of discovery |
| `level` | optional CEFR band, so beginners are not dropped into C1 conversation |
| `startsAt`, `durationMinutes` | a gathering always has a time |
| `capacity` | default 6–8. An empty 20-seat room reads as failure; a full 6-seat one reads as popular |
| `quorum` | default 3, including the host |
| `joinMode` | `open` or `approval` |
| `place` | optional; offline only |
| `repeatedFrom` | clone pointer, so "3rd week running" is displayable |
| `status` | `scheduled` → `confirmed` → `live` → `ended` / `cancelled` |

**`language` must be stored as a base code.** `controllers/matching.js` compares language
strings exactly and loses 55% of true pairs as a result; that mistake must not be repeated
here.

### 2.1 Recurrence: deliberately not built

Weekly rhythm is the right long-term shape, but true recurrence multiplies the known
failure — twelve instances with zero RSVPs each is a worse signal than one — and needs
instance materialization, per-occurrence cancellation and exception handling before a
single person has attended anything.

**Instead: "repeat this gathering."** One tap on a finished gathering clones it to the
same weekday and time next week, carrying title, description and settings, and notifies
previous attendees. `repeatedFrom` records the chain. If a host repeats three times, that
is the evidence to build real recurrence.

---

## 3. Making a gathering actually happen

**Quorum, shown publicly.** Until met, the card reads *"2 more needed to confirm"*; after,
*"Confirmed · 4 going"*. This converts RSVPing from a gamble into a contribution. Joining
an empty room is socially expensive; joining a confirmed one is not.

**Host commitment is explicit.** The host is auto-RSVP'd and counts toward quorum. At
T-2h, if quorum is unmet, the host is asked *"Only 1 person is coming. Run it anyway, or
cancel?"* — never silently auto-cancelled. A host abandoning their own gathering is the
worst outcome, so the design makes them decide out loud.

**Times always render in the viewer's local zone**, with the host's timezone beneath. An
ambiguous time across Shanghai/Seoul/Europe is a guaranteed no-show.

### 3.1 A gathering must end in conversations

When a gathering ends, every attendee gets a card of who was there, one tap to message any
of them, and **that first message is exempt from the new-conversation cap** in the
monetization spec. They did not discover each other by browsing; they spent an hour
together. Taxing that would tax the thing we most want to happen.

This is why 모임 is worth building at this scale. New conversations run 1,240/month and are
the healthiest metric in the app. A gathering of six produces fifteen possible pairs in an
hour.

**The hour is not the product. The relationships that survive it are.** Success is measured
in conversations started between attendees within 48h of a gathering ending. Attendance is
the input, not the outcome.

---

## 4. Discovery and cold start

### 4.1 Placement — and the answer to "Community feels packed"

Community has 8 tabs. **모임 is not the ninth. It replaces the voice-rooms entry.**
Gatherings are voice rooms with commitment attached, and voice rooms have failed 91 times
out of 91. Do not add a surface; replace the one that taught users the app is empty. Tab
count stays flat.

### 4.2 Default view

**"Starting soon, in a language I speak or am learning."** Not "all", not "nearby".
Language is the one axis where these users are genuinely sorted and is what makes a
stranger worth an hour. Filters for type, level and date exist, but every filter narrows an
already-thin pool, so the default must be the widest useful view rather than a blank slate
awaiting input.

### 4.3 Cold start — the real risk

Day one has zero gatherings, and an empty list is the exact impression that killed voice
rooms.

1. **The empty state is a create form, not an apology.** A pre-filled draft — your target
   language, tomorrow evening local, capacity 6, quorum 3 — one tap to post. At this scale
   most gatherings will be created by people who came looking for one.
2. **Supply-side seeding by the owner.** Three live gatherings make the list look alive;
   zero makes it look abandoned. This is manual and it is the highest-leverage manual work
   available.
3. **Demand-side push on creation**, subject to the existing frequency cap.

**Honest risk: if seeding stops, the list empties and the feature dies like the others.
모임 needs a host before it needs attendees, and for the first month that host is the
owner.**

---

## 5. Notifications and email

**This section is load-bearing, not administrative.**

Measured 2026-09-15 across 797 active users: **push reaches 278 (35%). Email reaches 797
(100%).**

**A push-only reminder means roughly two-thirds of people who RSVP are never reminded.**
They no-show, quorum collapses, hosts are stood up, and the feature dies of the same
emptiness as voice rooms. **Email is the primary reminder channel here, not a fallback.**

### 5.1 The matrix

| Event | Push | Email | In-app | Notes |
|---|---|---|---|---|
| Gathering created in your language | yes (capped) | no | yes | invitation; email would be spam |
| Join requested (host) | yes | no | yes | `sendRoomJoinRequest` exists |
| Request approved / denied | yes | no | yes | both exist |
| **Quorum reached** | yes | no | yes | "your gathering is confirmed" |
| **24h before** | yes | **yes** | yes | the critical one. Email carries the 65% push cannot reach |
| **10 minutes before** | yes | no | yes | email is too slow to matter |
| **Host decision due (T-2h)** | yes | **yes** | yes | the host is the single point of failure |
| **Cancelled** | yes | **yes** | yes | people arranged their evening around it |
| Gathering ended | yes | no | yes | the attendee card from §3.1 |

### 5.2 Requirements

- **Locale.** Both channels render in `preferredLocale`. Push templates cover 19 locales;
  email covers 8 with an `en` fallback (`services/emailTemplateService.js`). A gathering in
  Korean must not arrive as an English push.
- **Calendar attachment.** The 24h email carries an `.ics` invite. This is the single
  highest-value line in this section: once it is in someone's calendar, attendance no
  longer depends on our reminders reaching them at all.
- **Frequency cap.** Creation notifications go through the existing cap in
  `services/fcmService.js` (already suppressing ~85/month). RSVP-triggered reminders are
  transactional and exempt — a person who asked to be reminded must be reminded.
- **Unsubscribe.** Reminder emails carry the RFC-8058 headers already implemented. A user
  who unsubscribes from gathering email keeps in-app and push.
- **Delivery is now observable.** `Notification.deliveredAt` was fixed 2026-09-15 and now
  records FCM acceptance, so reminder delivery can be measured rather than assumed.

### 5.3 Known constraint

Gmail still spam-folders `banatalk.com` mail (reputation lag, documented 2026-07-14). If
reminder email lands in spam, this design's primary channel is silently broken. **Verify
inbox placement for the reminder template before launch**, and watch Postmaster
reputation during rollout.

---

## 6. Safety

**At launch (online events only):**

- **Blocking extends here** — blocked users never see each other's gatherings and cannot
  join one the other hosts. `excludeIds` in the matching pipeline is the pattern.
- **Reporting** reuses the existing `reports` collection.
- **Host powers:** remove a participant mid-gathering, plus approve/deny.
- **No recording at launch.** `canRecordVoiceRoom` exists as a VIP flag; recording
  strangers requires explicit consent from everyone present. That is a feature, not a
  toggle. Leave it off.

**Host reliability.** A host who does not appear at their own confirmed gathering has stood
up everyone who RSVP'd, and they do not come back. Track completed-versus-abandoned per
host, surface "has hosted 4 gatherings", and remove hosting ability after repeated
no-shows. Cheap to build, and it protects the scarce resource: people's willingness to
show up.

### 6.1 Minors — a hard rule recorded before it is needed

**5 active users are under 18** (of 633 complete profiles; 415 are 18–24).

For moderated online events this is manageable. For `offline_meetup` it is not: an adult
arranging to meet a minor in person, coordinated by this app, is the most serious risk in
the design.

**When `offline_meetup` ships it is 18+ on both sides — under-18 accounts cannot create,
see, or join one.** `birth_year` is collected on every complete profile, so the gate is
available.

**Limitation:** age is self-declared. Gating reduces exposure, it does not eliminate it.
This is a further reason `offline_meetup` deserves a deliberate decision rather than a flag
flip.

---

## 7. Architecture

**A Gathering is the commitment layer; VoiceRoom remains the audio layer.** At start time a
confirmed gathering opens a VoiceRoom and attendees join it.

### 7.1 Blocking prerequisite

**Two-way audio has never been exercised in production.** 91 rooms, maximum participants 1.
The rooms may have failed on presence, or audio may never have worked — the data cannot
distinguish them.

**The first task of this build is two people on two devices in one voice room confirming
they can hear each other.** If that fails, 모임 is blocked on fixing audio, and building the
scheduling layer first would be building on sand.

### 7.2 Components

**Backend**
- `models/Gathering.js` — §2 schema
- `controllers/gatherings.js` — create, list+filter, RSVP/cancel, approve/deny, repeat,
  start, end
- `lib/gatheringQuorum.js` — **pure**: quorum met, how many more needed, is the T-2h host
  decision due. Testable without a clock or a database
- `lib/gatheringSchedule.js` — **pure**: local-day rendering and the reminder offsets
- `jobs/gatheringReminders.js` — 24h and 10-minute sends, on the existing scheduler
- `GATHERINGS_ENABLED` in `config/limitations.js`, following `ROOMS_ENABLED` /
  `REELS_ENABLED` / `COINS_ENABLED` exactly, reported via `appConfig` so the client hides
  the tab

**Reused unchanged:** join-request notifications, `sendScheduledRoomStarted`, blocking,
reports, the frequency cap, `emailTemplateService`.

**App:** the voice-rooms entry becomes 모임 — list, detail, create sheet, RSVP. No new tab.

---

## 8. Testing

- **Pure units:** quorum arithmetic; the T-2h host decision; local-day rendering across
  timezones; reminder offset calculation.
- **Integration (mongodb-memory-server):** RSVP at capacity refused; a blocked user can
  neither see nor join; quorum flips `scheduled` → `confirmed`; a cancelled gathering
  notifies every attendee.
- **Cross-spec guarantee:** a first message between two attendees of the same gathering
  does **not** consume the new-conversation quota from the monetization spec.
- **Notification contract:** the 24h reminder produces both a push and an email for a user
  with a token, and an email for a user without one. This is the test that protects the 65%.
- **Regression:** `GATHERINGS_ENABLED=false` makes every route 404 and the client hides the
  tab.

---

## 9. Rollout

Ship dark → seed 3 gatherings → enable for all → watch two numbers:

1. **gatherings reaching quorum** (does commitment beat coincidence?)
2. **conversations started between attendees within 48h of a gathering ending** — the
   number that says whether this was worth building

---

## 10. Out of scope

- `offline_meetup` and `interest_group` types (modelled, flagged off)
- True recurrence (see §2.1)
- Dating-framed gatherings. Dropped deliberately: 5 minors plus a stated dating purpose
  needs 18+ enforcement and its own spec, and both stores treat dating apps under separate
  rules. Social intent is already served by discovery and matching.
- Recording
- Study Hub information architecture (separate spec)

---

## 11. Open questions

1. **Does two-way audio work?** §7.1. Blocking, and unknown today.
2. **Does reminder email reach the inbox?** §5.3. The primary channel may be silently
   spam-foldered.
3. **Who seeds, and for how long?** The design assumes owner-hosted gatherings for roughly
   the first month. If that stops, the list empties.
