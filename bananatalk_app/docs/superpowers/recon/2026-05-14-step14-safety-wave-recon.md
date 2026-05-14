# Step 14 Safety Wave — Recon Report

**Date:** 2026-05-14
**Scope:** Four trust-critical issues from the Community audit. Recon only — facts, not fixes.
**Out of scope:** Wave rate-limit counter (#2), Wave 24h index drift (#1), Recording feature (#5), Voice room cost ceilings (#7), Nearby radius clamp (#11), Smart Match algorithm (#9), any new feature work.

---

## Cross-cutting findings

Before the per-issue deep dives, three discoveries that shape the whole wave:

### CC-1 — A Flutter AdminReportsScreen already exists

`lib/pages/reports/admin_reports_screen.dart` is a full CRUD UI: load, filter by status / type / priority, start review, resolve, dismiss. **It is not role-gated client-side** — any authenticated user can navigate to it, though every backend call returns 403 if the user's role isn't `'admin'`. Discoverable but harmless. Means we don't need to build a new admin surface from scratch — just gate the existing one and wire it in.

### CC-2 — Admin role system is minimal but functional

`models/User.js:255-259` has:
```js
role: {
  type: String,
  enum: ['user', 'admin'],
  default: 'user'
}
```

`middleware/auth.js:74-92` exposes a generic `authorize(...roles)` middleware. `routes/report.js` already uses `authorize('admin')` on every admin endpoint. No granular permissions, no audit log model, no `requireAdmin` specialized middleware — just the binary role. Promotion happens through `PUT /api/v1/auth/make-admin/:userId` (protected by `authorize('admin')`), which means bootstrapping the first admin requires a one-time direct DB edit. Not in scope for this wave.

### CC-3 — Email infrastructure is more complete than expected

- `utils/sendEmail.js` wraps Mailgun (`MAILGUN_API_KEY`, `MAILGUN_DOMAIN`, `FROM_EMAIL`, `FROM_NAME`)
- `services/emailService.js` has typed helper methods (`sendAdminDailyReport`, `sendNewUserNotification`, etc.)
- `jobs/adminReportJob.js` already sends a daily admin digest to `process.env.ADMIN_EMAIL || 'bananatalkmain@gmail.com'`
- Templates live in `utils/emailTemplates.js`

**No Slack webhook. No FCM admin channel.** Adding admin alerts on report creation is a straight extension of the existing Mailgun pattern.

### CC-4 — `getBlockedUserIds` is the canonical block primitive

`utils/blockingUtils.js:20-50` exposes a cached (TTL 120s), bidirectional helper:

```js
const getBlockedUserIds = async (userId) => {
  const user = await User.findById(userId)
    .select('blockedUsers blockedBy')
    .lean();
  const blockedByMe = (user.blockedUsers || []).map(b => /* ... */);
  const blockedMe = (user.blockedBy || []).map(b => /* ... */);
  return [...new Set([...blockedByMe, ...blockedMe])];
};
```

It returns BOTH directions (who I've blocked + who's blocked me). Already used in:
- `controllers/community.js#getNearbyUsers` (line 61)
- `controllers/community.js#getTopicUsers` (line 449)
- `controllers/matching.js` (4 endpoints)
- `controllers/messages.js#getMessages`

Pattern is: fetch IDs → inject into `$nin` filter on user reference field. Every fix in this wave should mirror this pattern exactly.

### CC-5 — Audit of all block-enforcement gaps in the codebase

Beyond the four issues in scope, the recon surfaced these other gaps in block enforcement (out of scope for this wave; noted for the queue):

| Surface | File:line | Block check today |
|---|---|---|
| Voice room socket: `user_joined` broadcast | `socket/voiceRoomHandler.js:227-235` | None — joiner identity broadcast to all in room |
| Voice room socket: `hand_raised` broadcast | `socket/voiceRoomHandler.js:447-456` | None — raiser identity broadcast to all in room |
| Voice room socket: `chat` broadcast | `socket/voiceRoomHandler.js:474-483` | None — sender identity + message broadcast to all in room |
| Voice room: `mute-all` (host) | `socket/voiceRoomHandler.js:384-414` | Only checks the actor is host; no peer block check |

These are real gaps but are about IN-ROOM broadcasts where the user is already in the room (so the listing + join filters in this wave already cover the entry path). Server-side broadcast filtering would require per-recipient filtering on socket emits — a more invasive change. Flagged for a future safety wave.

---

## Issue #8 — Voice room block check is host-only

### What exists today

Both `joinVoiceRoom` (controllers/voiceRooms.js:226-291) and `getVoiceRoomToken` (controllers/voiceRooms.js:298-343) run the same check:

```js
// Check if user is blocked by host
const host = await User.findById(room.host).select('blockedUsers');
if (host?.blockedUsers?.includes(userId)) {
  return next(new ErrorResponse('You cannot join this room', 403));
}
```

This is **unidirectional, host-only**. Three gaps:

1. **Reverse direction** — if the joiner has blocked the host, the check passes; joiner ends up in a room with someone they've blocked
2. **Peer participants** — if any current participant has blocked the joiner (or vice versa), the check passes
3. **`blockedBy`** — only `host.blockedUsers` is read; `host.blockedBy` is ignored (but `getBlockedUserIds` covers both)

### Operations missing block checks entirely

Per the audit:

| Operation | Handler location | Block check today |
|---|---|---|
| Mute/unmute self | `socket/voiceRoomHandler.js:357-378` (`voiceroom:mute`) | None |
| Mute all (host) | `socket/voiceRoomHandler.js:384-414` (`voiceroom:mute-all`) | Host-actor check only |
| Raise hand | `socket/voiceRoomHandler.js:439-461` (`voiceroom:raise_hand`) | None |
| Promote to co-host | `controllers/voiceRooms.js:493-534` (`promoteParticipant`) | None |
| RSVP scheduled room | `controllers/voiceRooms.js:565-585` (`rsvp`) | None |
| Chat in room | `socket/voiceRoomHandler.js:466-488` (`voiceroom:chat`) | None |

For this wave, the **token issuance + join** checks are the load-bearing ones. The socket-broadcast filtering (chat, hand-raise, user-joined) is out of scope (see CC-5).

### Edge cases the plan must address

**State model when a blocker tries to join a room where their blockee is a participant:**

- Today: the join succeeds (host-only check passes), and both end up in the room together with no warning
- After fix: the join should be rejected with a clear "You cannot join this room" 403, identical UX to the host-block case (don't reveal *who* is in the room — just block)

**State model when a user is already in a room and someone they blocked joins:**

- The blocker won't be allowed in (covered above)
- But what about a stale-state race: User A is in the room when User B (whom A blocked) tries to join via a stale token? LiveKit might have already validated B's token before our backend's late-arriving DB check fires
- Mitigation: the backend `getVoiceRoomToken` is the source of truth — if it returns a token, LiveKit allows the connection. A new block created mid-session won't retroactively kick anyone out (acceptable for v1; full kick-on-block-mid-session is its own design problem)

### Promote to co-host

`promoteParticipant` (controllers/voiceRooms.js:493-534) lets a host promote a participant to co-host. There's no block check — a host can technically promote someone the host has previously blocked (probably impossible in practice since they wouldn't be in the room, but worth a guard) or someone who has blocked another participant. Low risk; covered by the same `getBlockedUserIds` pattern.

---

## Issue #14 — Voice room listing doesn't filter blocked users

### What exists today

`controllers/voiceRooms.js:13-88` (getVoiceRooms) returns rooms based on:

```js
const filter = {
  status: statusQuery,
  isPublic: true,
  ...(statusFilter !== 'scheduled' && { lastHeartbeatAt: { $gte: heartbeatCutoff } })
};
if (language) filter.language = language;
if (topic) filter.topic = topic;
if (req.query.category) filter.category = req.query.category;

const [rooms, total] = await Promise.all([
  VoiceRoom.find(filter)
    .populate('host', 'name images')
    .populate('participants.user', 'name images')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limitNum)
    .lean(),
  VoiceRoom.countDocuments(filter)
]);
```

**No blocking filter at all.** A user who has blocked someone still sees that person's rooms in the list. Blocking only kicks in at join time.

### Other endpoints with the same gap

| Endpoint | Handler | Block filter? |
|---|---|---|
| `GET /api/v1/voicerooms/my` | `getMyRoom` (controllers/voiceRooms.js:541-558) | None |
| `GET /api/v1/voicerooms/:id` | `getVoiceRoom` (controllers/voiceRooms.js:95-109) | None |
| `POST /api/v1/voicerooms/:id/rsvp` | `rsvp` (controllers/voiceRooms.js:565-585) | None |

### Filter granularity options

Three possibilities:

**A) Host-only filter**
- Exclude rooms where `host` is in the bidirectional blocked list
- Simplest; one `$nin` clause
- Misses: a room where the host hasn't been blocked but a participant has

**B) Participants-only filter**
- Exclude rooms where any `participants.user` is in the blocked list
- Requires `$elemMatch` or post-fetch JS pass
- Higher cost

**C) Combined (host + participants)**
- Most defensive
- Implementation: `$nin` on host (server-side) + JS filter on already-fetched participants (since they're populated anyway)

### Performance concerns

Typical scale:
- 10-500 active rooms (heartbeat-filtered)
- 2-50 participants per room
- 0-100 blocked users per viewer (cached 2 min)

Cost of option C:
- Server-side `host: { $nin: [...] }` — adds nothing meaningful at this scale (indexed field)
- Post-fetch JS pass on participants — O(rooms × participants × blockedIds), worst case ~500 × 50 × 100 = 2.5M comparisons → ~5ms. Negligible.

No new indexes needed.

### Natural insertion point

In `getVoiceRooms`, after the filter is constructed but before the `find`:

```js
const blockedUserIds = await getBlockedUserIds(req.user.id);
if (blockedUserIds.length > 0) {
  filter.host = { $nin: blockedUserIds };
}
// ... existing find
// Post-fetch participant filter:
const visibleRooms = rooms.filter(r =>
  !(r.participants || []).some(p => blockedUserIds.includes(p.user?._id?.toString()))
);
```

`getMyRoom` and `getVoiceRoom/:id` (single-room lookups by ID) get a simpler treatment: if the requesting user has blocked the host OR is in the host's block list, return 404 (don't reveal the room exists).

---

## Issue #15 — Report system has no admin surface

### Schema (models/Report.js)

Status states: `pending` / `under_review` / `resolved` / `dismissed`
Moderator actions: `pending` / `content_removed` / `user_warned` / `user_suspended` / `user_banned` / `no_violation`
Priority: `low` / `medium` / `high` / `urgent`
Other fields: `reportedBy`, `reportedUser`, `reason` (7 enum values), `description`, `moderatorNotes`, `contentHidden`

Unique compound index on `{ reportedBy, type, reportId }` prevents duplicate reports from the same user against the same content.

No TTL. Reports persist indefinitely.

### Full route list (routes/report.js)

| Method | Route | Auth |
|---|---|---|
| POST | `/` | `protect` + rate limited |
| GET | `/my-reports` | `protect` |
| GET | `/` | `authorize('admin')` |
| GET | `/stats` | `authorize('admin')` |
| GET | `/stats/pending` | `authorize('admin')` |
| GET | `/user/:userId` | `authorize('admin')` |
| GET | `/:id` | `authorize('admin')` |
| PUT | `/:id/review` | `authorize('admin')` |
| PUT | `/:id/resolve` | `authorize('admin')` |
| PUT | `/:id/dismiss` | `authorize('admin')` |
| DELETE | `/:id` | `authorize('admin')` |

Backend auth is solid — every admin route is gated.

### The TODOs (verbatim)

`controllers/report.js:226-232` (inside `resolveReport`):

```js
// Take action based on moderator decision
if (action === 'user_banned') {
  // TODO: Implement user ban logic
  // await User.findByIdAndUpdate(report.reportedUser, { isBanned: true });
} else if (action === 'content_removed') {
  // TODO: Implement content removal logic based on type
}
```

The `User.isBanned` field does NOT exist on the User schema today. Adding it is part of this wave.

### Notifications today

- `logSecurityEvent('CONTENT_REPORTED', {...})` fires on create (line 63) — writes to server logs only
- `logSecurityEvent('REPORT_RESOLVED', ...)` fires on resolve (line 234)
- `jobs/adminReportJob.js` sends a daily digest to `ADMIN_EMAIL`
- **No per-report admin notification**. Reports sit until the daily digest catches them, then admin sees aggregate counts only.
- **No user-facing notification when a report is resolved** (reported user not told, reporter not told)

### Admin role system

Already covered in CC-2. Binary `role: 'user' | 'admin'`. `authorize('admin')` everywhere. No granular permissions.

### Existing admin actions across the codebase

| Surface | Auth |
|---|---|
| `routes/auth.js` `PUT /make-admin/:userId` | `authorize('admin')` |
| `routes/users.js` `POST /` (createUser) | `authorize('admin')` |
| `routes/users.js` `PUT /mode/:userId` (change user mode) | `authorize('admin')` |
| `routes/lessonBuilder.js` (4 routes) | `authorize('admin')` |

No `models/AdminAction.js` (audit log model). No `utils/auditLog.js`. Admin actions are invisible past the standard server log.

### Auto-action threshold — should it be in this wave?

The audit asked: "should auto-action (3 reports → auto-suspend) be in this wave or punted?"

**My take: PUNT for this wave.** Auto-suspension on N reports is a substantive product decision with risks:
- Coordinated abuse: 3 friends report a user → auto-suspend → harassment vector
- False positives: A controversial-but-not-harassing user gets auto-suspended
- Threshold tuning: 3? 5? In what window? Per-reporter weight?

The minimum viable for this wave is: **make admin manual resolution actually work** (implement the user_banned + content_removed actions) and **alert admins faster** (per-report email + push, not just daily digest). Auto-action is a follow-up wave that needs its own design pass.

---

## Issue #13 — Anonymous profile views

### What exists today

`models/ProfileVisit.js:7-56` defines `isAnonymous: { type: Boolean, default: false }`. The field is **READ** by:

- `recordVisit` (statics, line 238) — accepts `options.isAnonymous`, defaults to false
- `getRecentVisitors` aggregation (line 74) — filters `$match: { isAnonymous: false }` — anonymous visits are silently dropped from results
- `getUniqueVisitorCount` (line 131) — same filter

The field is **NEVER WRITTEN as true** anywhere in the codebase. Single call site is `controllers/profileVisits.js:43-47`:

```js
const visit = await ProfileVisit.recordVisit(profileOwnerId, visitorId, {
  source: source || 'other',
  deviceType: deviceType || 'ios',
  isAnonymous: false  // ← hardcoded
});
```

**This is the entire dormant feature.** Surfacing logic is already wired — the only missing piece is the write-side flag.

### Flutter call path

1. `lib/pages/community/single/single_community_screen.dart:113` triggers `_recordProfileVisit()` in `initState`
2. `lib/pages/community/single/single_community_screen.dart:133-140`:
   ```dart
   await ProfileVisitorService.recordProfileVisit(
     userId: _community.id,
     source: 'direct',
   );
   ```
3. `lib/services/profile_visitor_service.dart:25-70` POSTs to `/users/:userId/profile-visit` with only `source` and `deviceType` — no `isAnonymous` parameter sent

### Visitor Recall Card surfacing

`lib/pages/community/widgets/visitor_recall_card.dart:18-218`. Shows top 5 visitors as horizontal avatars + total visitor count. Loads via `ProfileVisitorService.getProfileVisitors()` in initState. Anonymous visits already wouldn't appear (filtered server-side); the card just shows the visitor count among non-anonymous records.

**Implication:** If anonymity ships, the card shows fewer avatars + the count drops (since `getUniqueVisitorCount` also filters anonymous). Two design options for the count:
- **Keep filter on count** — visited user sees only the non-anonymous count
- **Total count regardless** — visited user sees "5 people visited" but only 2 avatars, implying "3 anonymous viewers." More transparency about anonymity, but reveals interest even when identity is hidden.

For this wave I'd lean **keep filter on count** — clean UX, no surprises. The anonymous-viewer-still-counted variant is an interesting future enhancement.

### The three design options for anonymity

**A) Per-visit toggle**
- UX element on the profile-view screen
- High friction (decision required each visit)
- No precedent in the codebase for per-action privacy toggles
- Verdict: **rejected** — overhead doesn't justify granularity

**B) User preference (always anonymous)**
- New boolean in `privacySettings` (e.g., `anonymousProfileVisits`)
- Toggled once in privacy settings; applies to all profile visits
- Fits existing pattern exactly: `privacySettings` already has `showOnlineStatus`, `showCity`, `showAge`, etc.
- `lib/pages/profile/edit/privacy_edit.dart` is the natural home
- Verdict: **recommended** — minimal new UI surface, fits existing schema convention, clear mental model

**C) VIP perk**
- Tie anonymity to `userMode === 'vip'`
- Drives conversion BUT introduces perverse incentive: you can only be invisible if you pay
- Language-exchange context: hiding the viewer reduces transparency in a "I'm interested in your language" interaction
- Verdict: **rejected** — coercive feel doesn't fit the app's social posture

### Recommended option for the plan

**Option B — user preference in `privacySettings`.**

Backend changes:
- `models/User.js#privacySettings` — add `anonymousProfileVisits: { type: Boolean, default: false }`
- `controllers/profileVisits.js#recordProfileVisit` — read the visitor's `privacySettings.anonymousProfileVisits` and pass to `recordVisit`

Flutter changes:
- `lib/pages/profile/edit/privacy_edit.dart` — add the toggle row alongside the existing privacy switches
- `lib/services/profile_visitor_service.dart` — no client-side change needed; the backend resolves anonymity from the saved preference, not from the request payload

### Edge cases

**Does `lastVisited` still increment?** Yes — the visit is still recorded; only `isAnonymous = true`. Server-side filters strip it from visitor lists but the underlying record exists (for stats / future "you've visited N profiles this week" features).

**Does any other counter increment?** `getVisitStats` does NOT filter `isAnonymous`, so anonymous visits still count toward total stats. This is inconsistency in the existing code but doesn't change behavior — calling out so a future wave can normalize.

**What does the visited user see when only anonymous viewers visit?** The Visitor Recall Card returns an empty list. The card hides via `if (!_isLoaded || _visitors.isEmpty) return SizedBox.shrink()` — so no "Someone visited" message, just no card. This is acceptable; if we want to surface the "people are looking but staying invisible" signal, that's a separate UI design.

---

## Summary table

| Issue | Scope | Existing infra | Net change |
|---|---|---|---|
| #8 — Voice room block (host-only) | join, token endpoints | `getBlockedUserIds` cached helper | Add bidirectional + participant check to 2 endpoints |
| #14 — Voice room listing | `getVoiceRooms`, `getMyRoom`, `getVoiceRoom/:id`, `rsvp` | Same helper | Wire into 4 endpoints |
| #15 — Report system | Resolve TODOs + per-report alerts + role-gate Flutter screen | Mailgun + AdminReportsScreen + role middleware exist | Implement actions, add notifications, gate UI |
| #13 — Anonymity | One field, two reads (record + privacy edit) | `isAnonymous` filter already in place server-side | Add 1 field + 1 toggle + 1 backend read |

---

## Punted findings (queued, not in scope)

- Voice room socket broadcast filtering (chat, hand-raise, user-joined) — CC-5
- Voice room mute/unmute/promote/RSVP block checks — too many surfaces; just the join + listing covers entry paths
- Voice room mid-session kick when a block is created — separate design problem
- Auto-action thresholds for reports (3 reports → suspend) — needs product design pass
- Admin audit log model — would be valuable but adds scope
- Slack webhook for admin alerts — email is sufficient for v1
- VIP-only anonymity perk — explicitly rejected above

---

End recon. Awaiting plan + approval before any code changes.
