# BananaTalk 모임: Plan

**Date:** 2026-10-27
**Builds on:** `gatherings-and-clubs-status.md` (same date), spec `2026-09-15-gatherings-design.md`, plan `2026-09-16-gatherings.md`
**Goal:** Turn "Gatherings & Clubs" into a Korean-style 모임 product for language exchange:
a 모임 (club) is the home, and 정모 / 번개 (gatherings) happen inside it, online or offline.

> **Decided 2026-10-28:** hybrid, as planned: online clubs for everyone, plus an **offline pilot in 1–2 cities**
> that you run yourself. Phase 4 stays in the plan whatever the online numbers show; a 6-week review (§4)
> adjusts the format, it does not gate Phase 4. Answers to the other open questions are in §8.

---

## 1. The purpose in one sentence

**EN:** "Join a language-exchange 모임 and practise with the same people every week, online or in person."
**KO:** "언어교환 모임에 가입하고, 매주 같은 사람들과 온라인이나 오프라인에서 대화해요."

What makes it different from 소모임 / 문토 / 당근 모임: every 모임 is built around **a language pair**
(e.g. 한국어 ↔ English), so Koreans and foreigners meet to practise each other's languages.
A club can be about any activity (running, hiking, cooking, plain conversation), but it always sets a
language pair too (decided 2026-10-28), e.g. "Hangang Running · 한국어 ↔ English". The activity is why people
come; the language pair is why they come to BananaTalk and not a general hobby app.

### How it works, in two examples

**A weekly running club (offline).** You create "Hangang Running · 한국어 ↔ English" (offline, Seoul) and schedule
a 정모 every Saturday 08:00; the app opens each next run itself. New members find the club in 찾기 (offline · area ·
language) or through your invite link, ask to join, and you approve them after seeing their profile, languages and
past attendance. Members RSVP; seats split by language side (4 + 4) with a waitlist per side. Reminders go out 24 h
and 2 h before ("Can't come? Release your seat"); the exact meeting point shows only to people going, from the day
before. On the day they check in with a QR code. Afterwards: "Who was there" with Message buttons, "Did you feel
safe?", members post their run (photo, note, distance/time) to the club feed and optionally to Moments, and last
week's runners get "Keep your seat?" for next Saturday.

**An English conversation club (online).** The same, except anyone can join without approval (the host can turn it
on), "Join now" opens a voice room at the start time, a timer switches English ↔ Korean halfway with topic cards
to talk about, times show in each viewer's zone, and afterwards "Words from tonight" can be saved to AI Study.

**Safety and security when looking at or joining a gathering:** 18+ only (profile birth date); people you blocked
are hidden; offline events only at public places in pilot cities from approved hosts; the card shows only the area,
the exact place only to confirmed attendees from the day before; host approval for every new member of an offline
club; QR check-in; report on events and in club chat (offline reports first in the admin queue); "Did you feel
safe?" after each offline event, two "no" answers pause the host. No ID check yet.

### Words we use (in the app and in the code comments)

| User-facing (KO / EN) | Code today | Meaning |
|---|---|---|
| 모임 / Club | `Club` | Persistent group: language, interest, members, owner/운영진 |
| 운영진 / Organizer | `role: organizer` | Can manage the club and schedule events |
| 정모 / Regular meetup | `Gathering` + recurrence (new) | Repeats weekly or monthly |
| 번개 / Quick meetup | `Gathering` (one-off) | Single event, often short notice |
| 모임 채팅 / Club chat | (new) | Group chat for members |
| 온라인 / 오프라인 | `type` (`online`, `offline_meetup`) | Where it happens |

Rename the "Gatherings" tab to **모임** in Korean and **Clubs** in English (decided 2026-10-28).

---

## 2. Target structure of the Community tab

```
Community
 ├─ (existing tabs)
 └─ 모임
      ├─ 내 모임 / My clubs        ← default if the user has joined any
      │     each club card shows its next 정모/번개
      ├─ 찾기 / Discover           ← default for new users
      │     filters: language pair · 온라인/지역 · interest
      │     section "이번 주 일정 / This week" (upcoming events from clubs near me or in my language)
      └─ [+]  모임 만들기 / Create a club   ·   일정 만들기 / Schedule (only inside a club you manage)
```

Rules:
- **Every gathering belongs to a club** for new events (a club can have just one person, the host).
  Existing standalone gatherings keep working. This makes the club the one container, like 소모임.
- **Voice rooms come back** as their own thing (drop-in talk now). An online 정모 *opens* a voice room
  at its start time (Phase 1). They're no longer competing for the same tab slot.
- The empty state for joining users shows **clubs to join**, not a pre-filled create form.

---

## 3. Phases

Order agreed 2026-10-27: club chat → 정모 repeat → region filter + offline → club-first tab, after the Phase 0–1 prerequisites. Rough sizes are for one developer and may be off; re-estimate after Phase 0.

### Phase 0: Decisions and cleanup (≈ 2–3 days)

| # | Task | Done when |
|---|---|---|
| 0.1 | ~~Decide online-only vs. hybrid~~ Hybrid (decided 2026-10-28) | Written in the spec as §1.6 |
| 0.2 | Deploy backend `04c3832` (host reliability, "who was there", cancel/time-moved fixes) | Live in prod, smoke-tested on one gathering |
| 0.3 | Commit or drop the uncommitted app changes (pending join request, CO2) | Clean working tree |
| 0.4 | Do the two-phone audio test (plan Task 0) | Pass/fail written down; this decides Phase 1A vs 1B |
| 0.5 | Keep `gatheringsEnabled` **off for normal users** until Phase 5 ships; allow it for an internal test group | App config supports a user allow-list (or a build flag) |
| 0.6 | Measure before choosing the pilot city and seeded pairs: users active in the last 30 days by `location.country` + `location.city`, and by `native_language` × `language_to_learn`; plus gatherings so far (created, RSVPs, attended) | Top cities and pairs written here; you pick the 1–2 pilot cities from them |

### Phase 1: An online event has somewhere to happen (≈ 1–2 weeks)

Nothing else matters if people RSVP and then have nowhere to go.

**1A, if the audio test passes (plan Task 7):**
- `POST /gatherings/:id/start` (host, from T-10 min): creates a VoiceRoom, stores `voiceRoom`, sets status `live`.
- Auto-start at start time if the host hasn't, so attendees aren't stuck.
- 10-minute reminder and the detail screen show **"Join now"** → opens the room.
- `end` becomes: host ends, or room empty for N minutes, or the 12 h close-out you already have.

**1B, if audio isn't ready (stopgap):**
- Add `meetingLink` (Meet/Zoom/Discord) on online gatherings; show it only to people going, from T-10 min.
- Label it honestly: "This 모임 meets on Google Meet."

**Also in Phase 1:**
- Fix open gap #6: send 24h, 10-min, T-2h, cancel and time-moved through `notificationService`
  so they appear in in-app history (65% of users have no push token).
- Make "Add to calendar (.ics)" a button right after RSVP, not only in the email.

**Added 2026-10-28 (Phase 1):**
- **Seats by language side, on by default.** An event's capacity splits by its club's language pair
  (e.g. 4 Korean speakers + 4 English speakers, judged by `native_language`), each side with its own waitlist.
  The card says "English speakers: 1 seat left". The host can turn it off per event. A one-sided meetup is not
  a language exchange, and no general 모임 app does this.
- **Built-in format for every 정모.** In the room: a timed language switch (default 20 min language A →
  20 min language B, host can change the split) with a visible "switch now" prompt, and topic cards drawn from
  the existing daily prompts. New hosts get a working meetup without planning one.
- **Times in the viewer's zone.** Every card, detail screen, reminder and .ics shows the viewer's local time,
  with the host's time on a second line ("Tue 21:00 KST"). Online clubs mix Korea with users abroad.
- **No-show tools.** The T-2h reminder has "Can't come? Release your seat", which promotes the next person on
  that side's waitlist and tells them. Check-in: room presence for online events (Phase 1A), QR at offline
  events (Phase 4). Check-in is what the "RSVP → came" metric (§4) counts. After a few events, a soft
  "usually comes" label on members who show up; nothing negative is shown.

Done when: a test gathering goes RSVP → reminder → join → talk → end → "Who was there", on two phones.

### Phase 2: Club chat, the retention piece (≈ 2–3 weeks)

This is what makes Korean 모임 apps sticky: people talk between meetups.

- Put the chat on the existing `club_detail_screen.dart` (a "채팅 / Chat" button or section); Phase 5 rebuilds that page later around it.
- Each club gets one group chat. First check whether the existing chat system can do group threads;
  reuse it if so, rather than building a second chat.
- Members join the chat automatically when they join the club and leave it when they leave or are removed.
- Owner/organizers can pin a notice (공지) and delete messages; members can report messages.
- Blocking: messages from people you blocked are hidden (match existing block rules).
- Event messages posted automatically into the chat: "New 정모 scheduled", "Confirmed (3/6)", "Starting in 10 min".
- Notification setting per club: all / mentions and events only / off. Default: events only.
- The daily first-message limit doesn't apply inside club chat; the existing one-to-one rules stay.

**Club feed for records (added 2026-10-28).** After an event, members post a photo + note, with optional
distance / time / pace, to the club page; one toggle also shares it to Moments. Reuse the Moments composer and
model with a `club` reference rather than a new post type; no fitness-app integration. Only members see the club
feed of a private club; organizers can remove posts; reports and blocks as in Moments.

Done when: members of a test club chat for a week and get event messages there, and post records after an event.

### Phase 3: 정모 (repeat) (≈ 1 week)

- On create: "반복 / Repeat: none · weekly · every 2 weeks · monthly", plus an end (after N times or a date).
- Store a series (`seriesId` + rule); create the **next occurrence only** when the previous one ends
  or 7 days ahead, whichever is earlier. Don't pre-create months of events. Use the existing `repeatedFrom`.
- Members who went last time get "Next 정모 is open. Keep your seat?" (one tap to RSVP).
- Editing: "this one" or "this and all future".
- "Repeat this gathering" button on ended gatherings (spec §2.1) uses the same code.

- **Word recap after each 정모** (added 2026-10-28): next to "Who was there", "Words from tonight": phrases the
  host or attendees add during the event (and later, from the room's topic cards). One tap saves them to
  AI Study vocabulary; attending counts toward XP / the streak.

Done when: a weekly 정모 runs three weeks in a row without the host re-creating it.

### Phase 4: Region filter + offline pilot (≈ 3–4 weeks, after Phases 1–3 work online)

Start in **1–2 cities**, chosen from the Phase 0.6 numbers. Owner-created clubs only at first;
open to more hosts (an owner-approved list) later.

Safety (required before any offline event is visible)
- **18+ only**, from the profile birth date. **No identity verification for the pilot** (decided 2026-10-28:
  the app is international and 본인인증 only covers Korean phone numbers). The measures below carry the safety
  load instead; revisit a verification vendor if the pilot grows past owner-run clubs or reports come in.
- Offline events must be at a **public place** (café, study room, language café). Host picks from a list
  or enters an address that's checked.
- **Exact place is shown only to people going**, from the day before; the card shows only the area (e.g. "홍대입구").
- Host checklist on create (public place, no alcohol-only meetups for the pilot, contact for problems).
- Report button on the event and in club chat; reports from offline events go to the top of the admin queue.
- After each offline event: "Did you feel safe?" (yes/no) to everyone who went. Two "no" answers pause the host.
- Legal check: terms of service and privacy policy updated for location sharing and offline meetups.

Product
- Re-enable `offline_meetup` in the API **only** for approved hosts (owner allow-list) in pilot cities.
- Club `city` / `place` become real fields (this closes open gap #8 by making it intentional).
- Region filter 온라인 / 내 지역 on the current Clubs list now; it moves into 찾기 in Phase 5.
- Offline capacity default 8, quorum 4 (planning number; adjust after the first month).

Done when: 8+ offline 정모 have run with zero unresolved safety reports.

### Phase 5: Club-first structure (≈ 1–2 weeks)

Backend
- New gatherings must have `club` (keep old standalone ones readable).
- Only owner/organizers can schedule 정모 in a club; any member can create a **번개**
  (owner can turn this off per club: `allowMemberBungae`).
- `GET /clubs` "discover" sort: language match → has an upcoming event → active members recently → member count.
- `GET /clubs/mine` with each club's next event in the response (one call for the 내 모임 list).
- Show `hostRecordLabel` ("Hosted 8 meetups") on club and gathering cards (open gap #7).

App (`lib/pages/community/gatherings/`)
- Restructure `gatherings_tab.dart` into **내 모임 / 찾기** as in §2.
- `club_detail_screen.dart` becomes the main page: header, join button, **upcoming schedule**,
  members, club chat (from Phase 2), past meetups count.
- Create flow: "Create a club" first; "Schedule" lives inside the club.
- Copy: purpose line from §1 in the header and empty states; all locales.

Done when: a new user can find a club in their language, join in one tap, and see its next 정모 in under 30 seconds.

### Phase 6: Seed and launch (runs alongside Phases 2–5)

- You run **3–5 clubs yourself**, each with a fixed weekly 정모 at the same time, e.g.
  - 한국어 ↔ English, Tue 21:00 KST (online)
  - 한국어 ↔ 日本語, Thu 21:00 KST (online)
  - Seoul language exchange, Sat 15:00 (offline, after Phase 4)
- Pin them at the top of 찾기 as "추천 모임 / Featured".
- Recruit 2–3 regular attendees per club to become 운영진 by week 4 so the clubs don't depend on you.
- Turn the feature on for everyone after Phases 2–5 ship and at least two seeded clubs have run 3 weeks.
- Website (`WEB_GATHERINGS_ENABLED`): turn on after the app, read-only discovery first (helps sharing links).
- **Growth hooks** (added 2026-10-28): club invite links through the existing `/i/` web invite and the
  `/community/` App Links, with a read-only club preview page on banatalk.com (moves web discovery earlier);
  daily matches suggest a club when the pair fits the user's languages; a weekly "Your clubs this week" email,
  since push reaches only about a third of users.

---

## 4. What to measure

| Metric | Why | Target to aim for (first 2 months) |
|---|---|---|
| RSVP → actually came | No-shows kill small meetups | ≥ 60% |
| Events reaching quorum | Is there enough density? | ≥ 70% |
| Members who come again within 14 days | The real sign it works | ≥ 35% |
| Clubs with an event in the last 14 days | Are clubs alive? | ≥ 50% of clubs |
| Club chat: members who post in a week | Is chat doing its job? | ≥ 25% |
| First message sent after "Who was there" | Friendships forming | ≥ 20% of attendees |
| Safety reports per offline event | Pilot health | Near 0; every one reviewed within 24 h |

Targets are starting guesses, not benchmarks; adjust after the first month of data.

**6-week review (decided 2026-10-28):** after six weeks of seeded online clubs, check repeat attendance
(target ≥ 35%) and the quorum rate. If they miss, change the format (time, size, the switch split, topic cards)
before opening to everyone. Phase 4 carries on either way.
Free events often see 30–45% no-shows, so plan for **5+ RSVPs to get 3 people**.

---

## 5. Cut or defer

| Defer | Why |
|---|---|
| ~~Approval mode for joining events~~ | No longer deferred (2026-10-28): **required for offline clubs/events**, optional (off by default) for online. The host sees profile, languages and past attendance before approving. |
| Full 9-topic list | Start with ~3 (conversation, culture, exam prep); clubs carry the interest now |
| `level` filter | Too few events to filter; show level as a label only |
| Paid 모임 / fees | Later, once people come back regularly |
| Web create/edit | App first; web shows discovery and links |
| Automatic host-blocking penalties | Handle by hand while you know every host |

---

## 6. Risks

| Risk | What we do |
|---|---|
| Empty clubs look dead | Rank clubs with no event in 30 days lower in 찾기 (spec §1.5; not hidden); feature seeded clubs |
| Offline safety incident | 18+ by birth date, public places, place revealed late, fast reports, "Did you feel safe?", owner-run pilot cities only; no ID check yet |
| One-sided events | Seats by language side with per-side waitlists (Phase 1) |
| Becoming a dating app | Language-pair focus, host checklist, report category "not a language meetup" |
| Chat becomes spam | Organizer moderation, per-club notification settings, report |
| Founder burnout from hosting | 운영진 hand-over by week 4 |
| Push reaches only 35% | In-app history (Phase 1), email + .ics, chat event messages |

---

## 7. Order at a glance

```
Phase 0  decisions + deploy + audio test          ┐ prerequisites
Phase 1  online event → room (or meeting link)    ┘
Phase 2  club group chat                          ┐
Phase 3  정모 repeat (weekly / monthly)            │  your order
Phase 4  region filter + offline pilot + safety   │
Phase 5  Community tab opens on 내 모임 / 찾기       ┘
Phase 6  seed 3–5 clubs + growth hooks (starts with Phase 2, runs alongside)
         → open to everyone, then the website
```

## 8. Decisions (2026-10-28)

1. Hybrid or online-only? **Hybrid, as planned.**
2. Which 1–2 cities for the offline pilot? **From prod data** (Phase 0.6); still open until the query runs.
3. Identity check for foreigners? **None for the pilot**; 18+ from the birth date plus the Phase 4 safety rules.
4. Does the existing chat support group threads? Partly: language rooms (backend `controllers/rooms.js`) are
   group chats and can likely back club chat, so Phase 2 may be nearer 1–2 weeks. Confirm at the start of Phase 2.
5. English tab name? **Clubs.**
6. Seats by language side? **Yes, on by default** (Phase 1).
7. Built-in 정모 format? **Yes, in Phase 1.**
8. Also added: viewer-local times and no-show tools (Phase 1), word recap (Phase 3), growth hooks (Phase 6),
   6-week review (§4).
9. Hobby clubs? **Yes, any activity, but every club keeps a language pair.**
10. Sharing records? **Club feed** (photo + note + optional distance/time), shareable to Moments (Phase 2).
11. Host approval? **Required offline, optional online.**
