# 모임 / Gatherings — Implementation Plan

**Spec:** `docs/superpowers/specs/2026-09-15-gatherings-design.md`
**Date:** 2026-09-16
**Repos:** backend (most of it) + `bananatalk_app` (Task 8)

The spec is the authority. Where this plan and the spec disagree, the spec wins.

---

## Premises re-measured before planning, 2026-09-16

Every number the spec argues from, checked against production today. All of them hold,
and two got worse:

| Spec claim | Measured today | |
|---|---|---|
| Voice rooms: 91 created, max participants 1 | **93 created, all `ended`, max participants ever 1** | **zero rooms have EVER held two people** |
| Language rooms: no group conversation ever | **max participants in any conversation: 2. Zero `isGroup`** | confirmed |
| Push reaches 35%, email 100% | **281 / 792 active (35%) push; 792 / 792 (100%) email** | confirmed exactly |
| 5 users under 18 | **5** | confirmed |

**A push-only reminder would never reach 511 of 792 active users.** That is the single
number that decides §5: email is the primary reminder channel, not a fallback.

Email template coverage was checked against the actual locale spread of active users —
`zh` (245), `en` (220), unset (94), `ar` (68), `ru` (38), `fr` (36), `ko` (15),
`zh_TW` (12). Catalogs exist for **every** one of those; only the 94 users with no
`preferredLocale` fall back to `en`, which is the intended behaviour. **§5.2's locale
requirement is already satisfied by the existing service** — no new translation work is
needed for the reminder templates beyond writing the `en` source strings.

---

## The blocking prerequisite, and how this plan handles it

Spec §7.1: **two-way audio has never been exercised in production.** 93 rooms, maximum
participants 1. The data cannot distinguish "nobody ever showed up at the same time" from
"audio never worked" — both produce exactly this table.

**This cannot be settled from a keyboard.** It needs two people on two devices in one
voice room confirming they can hear each other. That is Task 0, it belongs to the owner,
and no amount of backend work substitutes for it.

**So this plan is deliberately sequenced to not depend on the answer.** The commitment
layer — the schema, the quorum arithmetic, the reminders, the attendee card — is what is
actually novel here, and none of it touches audio. Only Task 7 (start a gathering → open a
VoiceRoom) does.

If audio turns out to be broken, Tasks 1-6 and 8 are unaffected and Task 7 becomes "fix
audio first". If this plan were sequenced the spec's way — audio check strictly first —
a broken microphone would block work that has nothing to do with microphones.

---

## Global constraints

1. **`GATHERINGS_ENABLED` defaults to false**, following `ROOMS_ENABLED` / `REELS_ENABLED`
   / `COINS_ENABLED` exactly, reported through `appConfig` so the client hides the tab.
   Every route 404s when off. This is the third feature in a row shipping behind a switch
   and the pattern is now well established in `config/limitations.js`.
2. **`language` is stored as a base code** via the matching key. `controllers/matching.js`
   compared raw strings and hid 56% of real pairs; that was fixed on 2026-09-16 and must
   not be reintroduced here. Use `lib/matchLanguage.js` `matchKey`, not `toBaseLanguage`
   directly — Cantonese must not silently fold into Chinese here either.
3. **Email is a first-class channel, not a fallback.** Any reminder that exists as a push
   and not as an email is a reminder 65% of the app never receives.
4. **No recording.** Not a toggle, not at launch.
5. **Nothing here weakens the conversation cap except the one exemption in §3.1**, and that
   exemption is deliberate and tested.

---

## Tasks

### Task 0 — two-way audio, on two real devices *(owner, blocking for Task 7 only)*

Two people, two devices, one voice room, confirm they can hear each other. Record the
result in the spec.

Everything else proceeds in parallel.

### Task 1 — the model and the pure logic

- `models/Gathering.js` — the §2 schema. `language` a base code; `status` the five-state
  machine; `repeatedFrom` a self-reference.
- `lib/gatheringQuorum.js` — **pure**: is quorum met, how many more are needed, is the
  T-2h host decision due. No clock, no database — the clock is a parameter.
- `lib/gatheringSchedule.js` — **pure**: reminder offsets and local-day rendering, reusing
  `lib/localDay.js`, which already exists and already handles the timezone-hopping problem.
- `GATHERINGS_ENABLED` in `config/limitations.js` + `appConfig`.

**Done when:** the pure units are table-tested across timezones with no mocked clock, and
`GATHERINGS_ENABLED=false` is asserted to make the config report it off.

### Task 2 — create, list, RSVP

`controllers/gatherings.js`: create, list with the §4.2 default view ("starting soon, in a
language I speak or am learning"), RSVP, cancel RSVP, approve/deny for `approval` mode.

The list query uses the same equivalence set as matching, so a gathering in
"Chinese (Simplified)" is found by someone learning "Chinese".

**Done when:** RSVP at capacity is refused; a blocked user can neither see nor join;
quorum flips `scheduled` → `confirmed`; the default view returns gatherings in the
viewer's language pair without a filter being set.

### Task 3 — the host decision and the state machine

Quorum reached → `confirmed` + notification. T-2h with quorum unmet → ask the host to run
it or cancel, **never** auto-cancel. Cancellation notifies every attendee by push **and**
email.

**Done when:** the T-2h decision is a pure function of (startsAt, quorum, attendees, now),
tested without waiting; a cancelled gathering is asserted to notify every attendee on both
channels.

### Task 4 — reminders *(the task that decides whether anyone shows up)*

`jobs/gatheringReminders.js` on the existing scheduler. 24h before: push **and** email
with an `.ics` attachment. 10 minutes before: push only — email is too slow to matter.

**The `.ics` is the highest-value line in the whole plan.** Once a gathering is in
someone's calendar, attendance stops depending on our reminders reaching them at all,
which matters enormously when a third of the audience is unreachable by push and the
email may be spam-foldered.

RSVP-triggered reminders are transactional and exempt from the frequency cap: a person who
asked to be reminded must be reminded. Creation notifications are **not** exempt.

**Done when:** the notification-contract test from spec §8 passes — a user with a token
gets both push and email; a user without one still gets the email. That test is what
protects the 511.

### Task 5 — a gathering must end in conversations

The attendee card, and the cap exemption: a first message between two attendees of the
same gathering does not consume the new-conversation quota.

`lib/conversationQuota.js` already keys the charge on the partner id, so the exemption is
a check at the decision point, not a new code path.

**Done when:** the cross-spec test passes — two attendees of the same gathering exchange a
first message with the cap ON and at the limit, and nothing is charged. A non-attendee at
the same limit is still refused.

**This is the task that justifies the feature.** Success is conversations started between
attendees within 48h, not attendance.

### Task 6 — safety

Blocking extends to gatherings (the `excludeIds` pattern from matching). Reports reuse the
existing collection. Host can remove a participant. Host reliability counter:
completed-versus-abandoned, surfaced as "has hosted 4 gatherings".

`offline_meetup` stays modelled and flagged off. **When it ships it is 18+ on both sides**
— recorded now, before it is needed, because the 5 under-18 accounts make this the most
serious risk in the design and self-declared age means gating reduces exposure rather than
eliminating it.

### Task 7 — start and end *(depends on Task 0)*

A confirmed gathering at start time opens a VoiceRoom; attendees join it; ending produces
the Task 5 attendee card.

### Task 8 — the app: 모임 replaces voice rooms

Community keeps 8 tabs. The voice-rooms entry **becomes** 모임 — list, detail, create
sheet, RSVP. Times render in the viewer's zone with the host's beneath.

The empty state is a **pre-filled create form**, not an apology: target language, tomorrow
evening local, capacity 6, quorum 3, one tap to post.

**Done when:** the tab count is unchanged, and a widget test asserts the empty state
renders a create form rather than an empty-list message.

---

## Rollout

Ship dark → owner seeds 3 gatherings → enable → watch:

1. gatherings reaching quorum (does commitment beat coincidence?)
2. **conversations started between attendees within 48h** — the number that says whether
   this was worth building

---

## The risk this plan cannot engineer away

**모임 needs a host before it needs attendees, and for the first month that host is the
owner.** Three live gatherings make the list look alive; zero makes it look abandoned, and
that impression is precisely what killed voice rooms 93 times.

No task above fixes that. It is manual, it is the highest-leverage manual work available,
and if it stops, this feature dies the way the last two did. The plan is honest about this
rather than hiding it behind a seeding task that sounds automatic.

Second risk, from spec §5.3: Gmail still spam-folders `banatalk.com`. If the reminder
email lands in spam, the primary channel is silently broken and the 511 are unreachable
after all. **Verify inbox placement before enabling**, not after.
