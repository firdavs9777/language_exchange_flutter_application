# Step 14 — Safety Wave Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close four trust-critical privacy/safety gaps surfaced in the Community audit. Make blocked users genuinely invisible in voice rooms (listing + join + token), implement the dormant `isAnonymous` profile-view feature behind a privacy toggle, make the existing report system actually act on resolutions, and route per-report alerts to admin email instead of just a daily digest.

**Architecture:** All four issues thread through code that already exists. The wave is a series of targeted bolts onto existing infrastructure — `getBlockedUserIds` is the canonical block primitive (`utils/blockingUtils.js`, used in 6+ places), Mailgun is the canonical email primitive (`utils/sendEmail.js`, used by daily admin digest), `privacySettings` is the canonical user-preference sub-doc (`models/User.js`, 8 existing toggles), and `AdminReportsScreen` already exists in Flutter (just not role-gated). No new vendors. No new dependencies. The only new schema fields are `User.isBanned: Boolean` and `User.privacySettings.anonymousProfileVisits: Boolean`.

**Tech Stack:** Node.js / Express / Mongoose / MongoDB (backend); Flutter / Riverpod (mobile). Mailgun for email. No new dependencies.

**Recon reference:** `docs/superpowers/recon/2026-05-14-step14-safety-wave-recon.md` — read this for the full state-of-the-world before executing.

**Branches:** `feat/step14-safety-wave` on both repos.

**Estimated commits:** 8 (B1-B5 backend, F1-F2 Flutter, G1 glue).

**Pacing:** Drive uninterrupted through tasks per the user's recorded preference. Surface only at G1 or on a genuine blocker.

---

## Hard constraints (from the user)

- **Out of scope:** Wave rate-limit counter (#2), Wave 24h index drift (#1), Recording feature (#5), Voice room cost ceilings (#7), Nearby radius silent clamp (#11), Smart Match algorithm (#9), any new feature work, any AI Study work.
- **No refactoring of unrelated code.**
- **No new dependencies without explicit user approval.**
- **Match existing commit-message style** — no Co-Authored-By trailers, no marketing copy in messages.
- **Both repos use branch `feat/step14-safety-wave`** for execution (not the planning branch).

---

## Edge cases handled

- **User A is in a voice room; User B (whom A blocked) tries to join.** The `joinVoiceRoom` + `getVoiceRoomToken` checks reject B's request with 403 ("You cannot join this room"). The error copy is identical to the host-block case so we don't reveal who specifically caused the block. A is not notified (the rejection is silent from their perspective — B just never appears).
- **User A is in a voice room; User B is already in the same room when A subsequently blocks B.** Mid-session blocks do NOT retroactively kick. The existing block enforcement happens at entry; existing participants stay. Documented as a known v1 limitation (mid-session kick is a separate design problem).
- **Anonymous profile view — does `lastVisited` increment?** Yes. The visit is recorded; only `isAnonymous = true`. The record exists for stats / future features. Server-side filters (`getRecentVisitors`, `getUniqueVisitorCount`) already strip anonymous visits from the visited user's view.
- **Anonymous viewer counts toward profile-view daily limits?** Yes — the rate-limit check fires before recordVisit, regardless of anonymity. Anonymity is a privacy toggle, not a rate-limit bypass.
- **Admin manually resolves a report → notifications.** Reporter receives an email confirming the report was reviewed (without revealing the action taken). Reported user receives an email ONLY if action is `user_warned`, `user_suspended`, or `user_banned` — explaining the action and providing appeal contact. No notification on `no_violation` or `content_removed` (content removal is self-evident).
- **Race condition: two reports against the same user land within seconds.** Reports are stored independently (the unique index is on `{reportedBy, type, reportId}` — different reporters can both report the same target/content). Admin email is sent for each report individually; no dedup. Auto-action on N reports is OUT OF SCOPE.
- **An admin marks a user banned.** `User.isBanned = true` is set. The next time the user authenticates or hits any protected route, the auth middleware returns 403 with a "Your account has been suspended" message. Their active voice rooms (where they're the host) get auto-ended via the new ban flow. FCM tokens are cleared. They can no longer log in until `isBanned` is flipped back manually by an admin.
- **Anonymous view + Visitor Recall Card.** When only anonymous viewers visit, the card returns an empty visitor list and the existing `if (_visitors.isEmpty) return SizedBox.shrink()` hides the card entirely. The visited user sees no signal that anonymous viewers exist. Acceptable v1 — surfacing "Someone visited" without identity is a future enhancement.

---

## Design decisions

1. **Issue #13 anonymity pattern: USER PREFERENCE (option B).**
   - New `User.privacySettings.anonymousProfileVisits: Boolean, default false`
   - Toggled once in `lib/pages/profile/edit/privacy_edit.dart` alongside the existing 8 privacy toggles
   - Backend `recordVisit` reads the viewer's preference and passes `isAnonymous` accordingly
   - **Rationale:** Fits the existing `privacySettings` sub-doc convention exactly. Symmetric with `showOnlineStatus`, `showCity`, etc. Per-visit toggle (option A) adds friction with no precedent. VIP-only (option C) is coercive and reduces transparency in a language-exchange social context.

2. **Issue #15 admin UI: ROLE-GATE EXISTING FLUTTER SCREEN.**
   - `lib/pages/reports/admin_reports_screen.dart` already exists as a full CRUD UI
   - Add a route guard reading `userProvider.value?.role == 'admin'`; non-admins get a 404-style screen
   - Add an entrypoint in `lib/pages/profile/profile_main.dart` (admin-only menu row, hidden for non-admins)
   - **Rationale:** Building a separate web dashboard is greenfield and out of scope. The existing screen is functional; we just need to gate it client-side (backend is already gated). Per-report email alerts handle the urgency case so admins don't need to be glued to the dashboard.

3. **Issue #15 auto-action threshold: PUNT.**
   - This wave implements manual `resolveReport` actions (`user_banned`, `content_removed`) + per-report admin email alerts
   - Auto-suspend on N reports within window is NOT implemented
   - **Rationale:** Auto-action has real abuse vectors (coordinated reporting → harassment vector). Threshold tuning is a product decision (3 reports? 5? per-reporter weight?). Punting until v1 manual flow has run in production for ~30 days and we have data on report volume + resolution patterns.

4. **Issue #14 listing filter: HOST + PARTICIPANTS (combined).**
   - `getVoiceRooms`: server-side `$nin` on host + post-fetch JS filter on participants
   - `getMyRoom`, `getVoiceRoom/:id`: return 404 if requesting user is in any block relationship with the host
   - `rsvp`: reject 403 if user has blocked the host or vice versa
   - **Rationale:** Most defensive; performance cost is negligible at current scale (10-500 rooms, post-fetch JS pass ~5ms worst case). Host-only filter (option A) misses peer-blocked cases. Participants-only filter (option B) requires `$elemMatch` and misses simple host blocks. Combined is the right floor.

---

## File structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Modify:**
- `models/User.js` — add `isBanned: Boolean, default false`; add `privacySettings.anonymousProfileVisits: Boolean, default false`
- `middleware/auth.js` — extend `protect` to return 403 when `user.isBanned === true`
- `controllers/voiceRooms.js` — gate listings with `getBlockedUserIds`; bidirectional + participant block check in `joinVoiceRoom` + `getVoiceRoomToken`
- `controllers/profileVisits.js#recordProfileVisit` — read viewer's `privacySettings.anonymousProfileVisits` and pass to `recordVisit`
- `controllers/report.js#resolveReport` — implement `user_banned` (set flag, kick from rooms, clear FCM tokens) and `content_removed` (delete by type); call notification helpers
- `controllers/report.js#createReport` — fire admin email per report
- `services/emailService.js` — new helper `sendAdminReportAlert(report)` for per-report admin alerts; new helper `sendReportResolutionToReporter(report)`; new helper `sendBanNotification(user, reason)`
- `utils/emailTemplates.js` — three new templates (admin alert, reporter confirmation, ban notice)

**No new files on backend.**

### Flutter (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

**Modify:**
- `lib/models/users_model.dart` (or wherever `User`/`Community` model lives) — add `anonymousProfileVisits` boolean field if mapping from `privacySettings`; add `isBanned` field on the same model so login flow can detect it
- `lib/pages/profile/edit/privacy_edit.dart` — add toggle row for "Visit profiles anonymously"
- `lib/services/auth_service.dart` (or wherever login response is parsed) — detect `isBanned: true` and route to a "your account has been suspended" screen
- `lib/pages/reports/admin_reports_screen.dart` — add role check on entry, redirect non-admins
- `lib/pages/profile/profile_main.dart` — show admin-only menu row when `userProvider.value?.role == 'admin'`

**Create:**
- `lib/pages/auth/account_suspended_screen.dart` — full-screen "your account has been suspended" view; shows ban reason + appeal contact

---

## Critical decisions baked in

1. **`User.isBanned` is the canonical ban flag.** A new field, defaulting false. The auth middleware reads it on every protected request. Setting it via `resolveReport` action `user_banned` cascades to: end the user's active voice rooms, clear their FCM tokens, log the action. Un-banning is admin-only (no self-service appeal flow in this wave).

2. **Anonymity preference is server-resolved.** The Flutter side does NOT pass `isAnonymous` in the profile-visit request payload. The backend reads the viewer's `privacySettings.anonymousProfileVisits` server-side and writes the visit accordingly. This means a user's anonymity preference is enforced even if they're using an older client that doesn't know about the toggle.

3. **Email is the only admin notification channel for this wave.** No Slack, no FCM push, no in-app admin notification. Mailgun + `ADMIN_EMAIL` env var is already wired; we extend it. Slack/push are queued for a future wave if email proves too slow.

4. **Role gating on admin screen is best-effort defense-in-depth, not the security boundary.** The backend `authorize('admin')` middleware is the actual gate. Client-side gating is UX — non-admins shouldn't be able to navigate to the admin screen, but if they do (deep link, stale build, etc.), the backend rejects every call. Don't rely on the client gate.

5. **Auto-end voice rooms on ban.** When `user_banned` action fires on a user who's currently hosting a voice room, that room is force-ended (status = 'ended', socket event broadcast). Participants get the standard room-ended UX (kicked back to lobby). Not notifying participants why (don't reveal the host was banned).

---

## Task 0: Branch setup

**Files:** none

- [ ] **Step 1: Verify clean working trees on both repos.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git status --short
# Expected: no output

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git status --short
# Expected: no output
```

If either is dirty, STOP and surface to user.

- [ ] **Step 2: Create branches.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull && git checkout -b feat/step14-safety-wave

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull && git checkout -b feat/step14-safety-wave
```

No commit yet.

- [ ] **Step 3: Copy plan + recon docs into backend.**

```bash
cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/recon/2026-05-14-step14-safety-wave-recon.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/recon/

cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/plans/2026-05-14-step14-safety-wave-plan.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/plans/
```

Commit on backend:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add docs/superpowers/recon/ docs/superpowers/plans/
git commit -m "docs: Step 14 safety wave recon + plan"
```

---

## Task B1: `isBanned` field + auth middleware check + `anonymousProfileVisits` field

**Files:**
- Modify: `models/User.js`
- Modify: `middleware/auth.js`

Working dir: `/Users/davis/Desktop/Personal/language_exchange_backend_application`

- [ ] **Step 1: Add `isBanned` field to User schema.**

Find the existing schema near the `role` field (line ~255). Add right after:

```js
isBanned: {
  type: Boolean,
  default: false,
  index: true
},
banReason: {
  type: String,
  default: null
},
bannedAt: {
  type: Date,
  default: null
}
```

- [ ] **Step 2: Add `anonymousProfileVisits` to `privacySettings`.**

Find the `privacySettings` sub-doc in `models/User.js`. Add a new field alongside the existing 8 toggles:

```js
anonymousProfileVisits: {
  type: Boolean,
  default: false
}
```

- [ ] **Step 3: Extend `protect` middleware to reject banned users.**

Open `middleware/auth.js`. Find the `protect` function (around line 29 or 65 — wherever `req.user = await User.findById(decoded.id)` is set). After the user is loaded, add:

```js
if (req.user?.isBanned === true) {
  return next(new ErrorResponse(
    `Your account has been suspended.${req.user.banReason ? ' Reason: ' + req.user.banReason : ''}`,
    403
  ));
}
```

Apply this check to BOTH middleware functions in `middleware/auth.js`:

- `exports.protect` (line 10) — fires after `req.user = await User.findById(decoded.id)` at line 29. Strict 401 on auth failure; needs the isBanned guard immediately after the user is loaded (before `next()`).
- `exports.optionalAuth` (line 46) — fires after `req.user = await User.findById(decoded.id)` at line 65. Soft (sets `req.user = null` on failure); the isBanned guard here should also fire as 403 since a banned user shouldn't be able to access *anything*, even routes that allow unauthenticated access.

- [ ] **Step 4: Verify syntax.**

```bash
node -c models/User.js && node -c middleware/auth.js
```

- [ ] **Step 5: Commit.**

```bash
git add models/User.js middleware/auth.js
git commit -m "feat(safety): add isBanned + anonymousProfileVisits schema fields

User.isBanned (default false) flags suspended accounts. protect
middleware now returns 403 if isBanned === true, blocking the user
from every protected route. Companion fields banReason (optional
message shown to the user) and bannedAt (timestamp).

User.privacySettings.anonymousProfileVisits (default false) is the
viewer-side toggle for hiding profile visits from the visited
user's recall card. Backend resolution lands in B4."
```

---

## Task B2: Wire `getBlockedUserIds` into voice room listings

**Files:**
- Modify: `controllers/voiceRooms.js`

- [ ] **Step 1: Add the import + helper.**

Top of file:

```js
const { getBlockedUserIds } = require('../utils/blockingUtils');
```

- [ ] **Step 2: Filter `getVoiceRooms`.**

Find the existing handler (lines 13-88). Right after the `skip`/`limit`/`statusQuery` setup but before the `filter` const, add:

```js
const blockedUserIds = await getBlockedUserIds(req.user.id);
```

In the `filter` object, add (only if there are any blocked users):

```js
...(blockedUserIds.length > 0 && {
  host: { $nin: blockedUserIds }
}),
```

After the `find` + `populate`, before the `formattedRooms` map, add the participant filter:

```js
const visibleRooms = blockedUserIds.length > 0
  ? rooms.filter(r =>
      !(r.participants || []).some(p =>
        blockedUserIds.includes(p.user?._id?.toString())
      )
    )
  : rooms;
```

Then change `rooms.map(...)` to `visibleRooms.map(...)`. Adjust the `total` count to reflect the filter (acceptable: keep the unfiltered total for pagination; client may see a discrepancy between `data.length` and `pagination.total`, which is fine for blocked-user filtering).

- [ ] **Step 3: Filter `getMyRoom` (lines 541-558).**

If the user's room has a host they've blocked (or vice versa), return null:

```js
// At the top of the function, after fetching the room:
const blockedUserIds = await getBlockedUserIds(req.user.id);
if (room && blockedUserIds.includes(room.host?.toString())) {
  return res.status(200).json({ success: true, data: null });
}
```

- [ ] **Step 4: Filter `getVoiceRoom/:id` (lines 95-109).**

After fetching the room, before returning:

```js
const blockedUserIds = await getBlockedUserIds(req.user.id);
if (blockedUserIds.includes(room.host?.toString())) {
  return next(new ErrorResponse('Voice room not found', 404));
}
const hasBlockedParticipant = (room.participants || []).some(p =>
  blockedUserIds.includes(p.user?.toString())
);
if (hasBlockedParticipant) {
  return next(new ErrorResponse('Voice room not found', 404));
}
```

404 instead of 403 — don't reveal the room exists.

- [ ] **Step 5: Filter `rsvp` (lines 565-585).**

Before the RSVP write:

```js
const blockedUserIds = await getBlockedUserIds(req.user.id);
if (blockedUserIds.includes(room.host?.toString())) {
  return next(new ErrorResponse('Voice room not found', 404));
}
```

- [ ] **Step 6: Verify.**

```bash
node -c controllers/voiceRooms.js
```

- [ ] **Step 7: Commit.**

```bash
git add controllers/voiceRooms.js
git commit -m "fix(safety): filter blocked users from voice room listings

Audit issue #14. getVoiceRooms, getMyRoom, getVoiceRoom/:id, and
rsvp now use getBlockedUserIds (bidirectional, cached 2min) to
exclude rooms involving blocked-pair users.

getVoiceRooms: \$nin on host + post-fetch JS filter on participants.
getMyRoom: returns null if user's room host is in block relationship.
getVoiceRoom/:id: returns 404 (not 403) so we don't reveal existence.
rsvp: 404 on blocked host.

Pagination total is intentionally unfiltered; client sees data.length
< pagination.total, which is the correct behavior for invisible-block
filtering."
```

---

## Task B3: Bidirectional + participant block check in voice room join/token

**Files:**
- Modify: `controllers/voiceRooms.js`

- [ ] **Step 1: Replace host-only block check in `joinVoiceRoom` (around lines 257-261).**

The existing check:

```js
const host = await User.findById(room.host).select('blockedUsers');
if (host?.blockedUsers?.includes(userId)) {
  return next(new ErrorResponse('You cannot join this room', 403));
}
```

Replace with:

```js
const blockedUserIds = await getBlockedUserIds(userId);
// Block the join if the joiner is in any block relationship with the host
if (blockedUserIds.includes(room.host?.toString())) {
  return next(new ErrorResponse('You cannot join this room', 403));
}
// Block the join if the joiner has any current participant on their block list
const hasBlockedParticipant = (room.participants || []).some(p =>
  blockedUserIds.includes(p.user?.toString())
);
if (hasBlockedParticipant) {
  return next(new ErrorResponse('You cannot join this room', 403));
}
```

- [ ] **Step 2: Same replacement in `getVoiceRoomToken` (around lines 320-323).**

Identical block — copy-paste from Step 1.

- [ ] **Step 3: Verify.**

```bash
node -c controllers/voiceRooms.js
```

- [ ] **Step 4: Commit.**

```bash
git add controllers/voiceRooms.js
git commit -m "fix(safety): bidirectional + participant block check on voice room join

Audit issue #8. joinVoiceRoom + getVoiceRoomToken now use the
canonical getBlockedUserIds helper (bidirectional, includes both
blockedUsers and blockedBy) instead of the host-only blockedUsers
read. Additionally checks if any current participant is in the
joiner's block relationship.

Error copy unchanged ('You cannot join this room') so the rejection
doesn't reveal who caused the block.

Note: in-room socket broadcasts (chat, hand-raise, user-joined)
still don't filter blocked users in-room. That's CC-5 from the
recon — queued for a future safety wave."
```

---

## Task B4: `recordProfileVisit` honors anonymity preference

**Files:**
- Modify: `controllers/profileVisits.js`

- [ ] **Step 1: Read viewer's preference and pass through.**

Find `recordProfileVisit` (lines 12-76). Locate the `ProfileVisit.recordVisit` call (lines 43-47):

```js
const visit = await ProfileVisit.recordVisit(profileOwnerId, visitorId, {
  source: source || 'other',
  deviceType: deviceType || 'ios',
  isAnonymous: false
});
```

Replace `isAnonymous: false` with a server-side read of the viewer's preference:

```js
// Read viewer's anonymity preference server-side. Older clients won't
// pass an isAnonymous flag in the request; preference applies regardless.
const viewer = await User.findById(visitorId)
  .select('privacySettings.anonymousProfileVisits')
  .lean();
const isAnonymous = viewer?.privacySettings?.anonymousProfileVisits === true;

const visit = await ProfileVisit.recordVisit(profileOwnerId, visitorId, {
  source: source || 'other',
  deviceType: deviceType || 'ios',
  isAnonymous
});
```

If `User` isn't already required at top of file, add it.

- [ ] **Step 2: Verify.**

```bash
node -c controllers/profileVisits.js
```

- [ ] **Step 3: Commit.**

```bash
git add controllers/profileVisits.js
git commit -m "feat(safety): honor anonymousProfileVisits preference in recordVisit

Audit issue #13. The isAnonymous field on ProfileVisit was previously
hardcoded to false at the only call site. Backend now reads the
viewer's privacySettings.anonymousProfileVisits and passes it through.

Server-side resolution means the preference applies even when older
clients don't send an explicit flag. getRecentVisitors already
filters anonymous visits server-side (\$match: { isAnonymous: false }),
so anonymity surfaces automatically once the write side flips."
```

---

## Task B5: Implement `resolveReport` actions + admin email alerts

**Files:**
- Modify: `controllers/report.js`
- Modify: `services/emailService.js`
- Modify: `utils/emailTemplates.js`
- Modify: `models/VoiceRoom.js` (no schema change — adding a static method)

- [ ] **Step 1: Add email templates.**

In `utils/emailTemplates.js`, add three new template functions:

```js
exports.adminReportAlert = (report, reporterName, reportedUserName) => ({
  subject: `[Report] ${report.reason} — ${reportedUserName}`,
  text: `New report against ${reportedUserName} by ${reporterName}.

Reason: ${report.reason}
Priority: ${report.priority}
Description: ${report.description || '(none)'}

View in admin: ${process.env.APP_URL || 'https://banatalk.com'}/admin/reports/${report._id}

This is an automated alert. The full report is also included in
the daily admin digest.`,
  html: `<p><strong>New report</strong> against ${reportedUserName} by ${reporterName}.</p>
<ul>
  <li>Reason: ${report.reason}</li>
  <li>Priority: ${report.priority}</li>
  <li>Description: ${report.description || '(none)'}</li>
</ul>
<p>View in admin: <a href="${process.env.APP_URL || 'https://banatalk.com'}/admin/reports/${report._id}">${report._id}</a></p>`
});

exports.reportResolutionToReporter = (report) => ({
  subject: 'Your report has been reviewed',
  text: `We've reviewed the report you submitted on ${report.createdAt.toDateString()}.

Our team has reviewed the content and taken appropriate action where warranted.
For your privacy, we don't share specific outcomes, but every report helps
keep BananaTalk safe.

Thank you for helping the community.`,
  html: `<p>We've reviewed the report you submitted on ${report.createdAt.toDateString()}.</p>
<p>Our team has reviewed the content and taken appropriate action where warranted. For your privacy, we don't share specific outcomes, but every report helps keep BananaTalk safe.</p>
<p>Thank you for helping the community.</p>`
});

exports.banNotification = (reason) => ({
  subject: 'Your BananaTalk account has been suspended',
  text: `Your account has been suspended following a review of reports made against it.

${reason ? `Reason: ${reason}\n\n` : ''}If you believe this was made in error, contact appeal@banatalk.com with your username.`,
  html: `<p>Your account has been suspended following a review of reports made against it.</p>
${reason ? `<p><strong>Reason:</strong> ${reason}</p>` : ''}
<p>If you believe this was made in error, contact <a href="mailto:appeal@banatalk.com">appeal@banatalk.com</a> with your username.</p>`
});
```

- [ ] **Step 2: Add typed helpers in `services/emailService.js`.**

**Important — module pattern:** `services/emailService.js` does NOT use a `module.exports = { ... }` block. Every existing helper is defined as `exports.xxx = async (...) => {...}` and the file ends with `module.exports = exports;` (line 296). **Do NOT add a new `module.exports = { ... }` block** — it would wipe out every existing export (sendWelcomeEmail, sendAdminDailyReport, sendNewUserNotification, etc.) and break the daily admin digest + every login/password/follow email.

**Correct pattern:** define the three new helpers as `exports.xxx = ...` and APPEND them after the existing helpers (after `sendNewUserNotification`, line 270; before the final `module.exports = exports;` line). The trailing `module.exports = exports;` re-export will pick them up automatically.

Append (do not replace) after the existing helpers:

```js
// Step 14 (safety wave) — per-report admin alerts + resolution emails.
exports.sendAdminReportAlert = async (report) => {
  const adminEmail = process.env.ADMIN_EMAIL || 'bananatalkmain@gmail.com';
  if (!adminEmail) return;
  if (process.env.ADMIN_REPORT_ALERTS_ENABLED === 'false') return;  // emergency kill switch
  try {
    const [reporter, reportedUser] = await Promise.all([
      User.findById(report.reportedBy).select('name').lean(),
      User.findById(report.reportedUser).select('name').lean(),
    ]);
    const tpl = templates.adminReportAlert(
      report,
      reporter?.name || 'Unknown',
      reportedUser?.name || 'Unknown'
    );
    await sendEmail({
      email: adminEmail,
      subject: tpl.subject,
      message: tpl.text,
      html: tpl.html,
    });
  } catch (err) {
    console.error('[email] sendAdminReportAlert failed:', err.message);
  }
};

exports.sendReportResolutionToReporter = async (report) => {
  try {
    const reporter = await User.findById(report.reportedBy).select('name email').lean();
    if (!reporter?.email) return;
    const tpl = templates.reportResolutionToReporter(report);
    await sendEmail({
      email: reporter.email,
      subject: tpl.subject,
      message: tpl.text,
      html: tpl.html,
    });
  } catch (err) {
    console.error('[email] sendReportResolutionToReporter failed:', err.message);
  }
};

exports.sendBanNotification = async (userId, reason) => {
  try {
    const user = await User.findById(userId).select('name email').lean();
    if (!user?.email) return;
    const tpl = templates.banNotification(reason);
    await sendEmail({
      email: user.email,
      subject: tpl.subject,
      message: tpl.text,
      html: tpl.html,
    });
  } catch (err) {
    console.error('[email] sendBanNotification failed:', err.message);
  }
};
```

**Verify before next step:** open `services/emailService.js`, confirm the final line is still `module.exports = exports;` and that the three new helpers sit between `sendNewUserNotification` (last existing helper, line ~270) and that final re-export. Confirm `User` is already required at the top of the file (it should be — existing helpers reference it). If not, add `const User = require('../models/User');`.

- [ ] **Step 3: Fire admin alert on report creation.**

In `controllers/report.js#createReport` (line ~63 where `logSecurityEvent` is called):

```js
// Existing line:
logSecurityEvent('CONTENT_REPORTED', { /* ... */ });

// NEW — fire admin email (fire-and-forget; don't block the response)
emailService.sendAdminReportAlert(report).catch(err =>
  console.error('Admin alert failed:', err.message)
);
```

Add `const emailService = require('../services/emailService');` at top of file if not already present.

- [ ] **Step 4: Implement `user_banned` action in `resolveReport`.**

Find the TODO block (lines 226-232). Replace with:

**Important — eviction must match the canonical end-room flow** at `controllers/voiceRooms.js#endVoiceRoom` (line 397+): `room.end()` instance method + `livekitAdmin.endRoom(...)` + 2 socket emits (`voiceroom:ended` to both `voiceroom_<id>` and `voicerooms:lobby`). Just setting `status: 'ended'` via `updateMany` would leave participants connected to LiveKit audio until inactivity timeout.

Top of file, add the requires (only if not already present):

```js
const VoiceRoom = require('../models/VoiceRoom');
const livekitAdmin = require('../services/livekitAdminService');
```

Replace the TODO block with:

```js
if (action === 'user_banned') {
  await User.findByIdAndUpdate(report.reportedUser, {
    isBanned: true,
    banReason: notes || `Banned following report ${report._id}`,
    bannedAt: new Date()
  });

  // Auto-end the banned user's active voice rooms. Mirror the
  // canonical flow in controllers/voiceRooms.js#endVoiceRoom (line 397+):
  // room.end() → livekitAdmin.endRoom() → socket emits to room channel + lobby.
  // This evicts participants from LiveKit audio AND notifies the lobby
  // so the listing updates in real time.
  const activeRooms = await VoiceRoom.find({
    host: report.reportedUser,
    status: { $in: ['waiting', 'active'] },
  });
  const io = req.app.get('io');
  for (const room of activeRooms) {
    try {
      await room.end();                                 // sets status='ended', endedAt=now via instance method
      await livekitAdmin.endRoom(String(room._id));     // terminates LiveKit room (fails open per livekitAdminService)
      if (io) {
        io.to(`voiceroom_${room._id}`).emit('voiceroom:ended', {
          roomId: String(room._id),
          endedBy: 'admin',
        });
        io.to('voicerooms:lobby').emit('voiceroom:ended', {
          roomId: String(room._id),
        });
      }
    } catch (err) {
      console.error(`[ban] failed to end room ${room._id}:`, err.message);
      // Don't abort the whole ban flow on a single room failure.
    }
  }

  // Clear FCM tokens so banned user stops getting push.
  await User.findByIdAndUpdate(report.reportedUser, {
    $set: { fcmTokens: [] }
  });

  // Send the banned user an email explaining the ban.
  emailService.sendBanNotification(report.reportedUser, notes).catch(err =>
    console.error('Ban notification failed:', err.message)
  );
}

if (action === 'content_removed') {
  // Delete the reported content based on type
  if (report.type === 'moment') {
    const Moment = require('../models/Moment');
    await Moment.findByIdAndDelete(report.reportId).catch(() => {});
  } else if (report.type === 'story') {
    const Story = require('../models/Story');
    await Story.findByIdAndDelete(report.reportId).catch(() => {});
  } else if (report.type === 'comment') {
    const Comment = require('../models/Comment');
    await Comment.findByIdAndDelete(report.reportId).catch(() => {});
  } else if (report.type === 'message') {
    const Message = require('../models/Message');
    await Message.findByIdAndUpdate(report.reportId, { deleted: true }).catch(() => {});
  }
  // No-op for type === 'profile' (handle via user_warned / user_banned instead)
}

if (['user_banned', 'user_suspended', 'user_warned'].includes(action)) {
  // Send the reporter a confirmation email
  emailService.sendReportResolutionToReporter(report).catch(err =>
    console.error('Reporter notification failed:', err.message)
  );
}
```

- [ ] **Step 5: Verify.**

```bash
node -c controllers/report.js && node -c services/emailService.js && node -c utils/emailTemplates.js
```

- [ ] **Step 6: Commit.**

```bash
git add controllers/report.js services/emailService.js utils/emailTemplates.js
git commit -m "feat(safety): implement resolveReport actions + admin email alerts

Audit issue #15. The user_banned and content_removed TODOs in
resolveReport are now implemented:

user_banned:
- Sets User.isBanned = true (field added in B1)
- Sets banReason from moderator notes
- Auto-ends any active voice rooms hosted by the banned user
- Clears the user's FCM tokens
- Emails the user the ban + appeal contact

content_removed:
- Deletes the reported content based on type (moment, story, comment)
- Soft-deletes messages (sets deleted: true)
- Profile reports route to user_warned/user_banned actions instead

Notifications:
- createReport fires sendAdminReportAlert per-report (Mailgun + ADMIN_EMAIL)
- resolveReport fires sendReportResolutionToReporter on user-action
  resolutions (warned/suspended/banned). no_violation and
  content_removed don't notify reporter (avoid information leak).

Three new email templates: adminReportAlert, reportResolutionToReporter,
banNotification. Three new typed helpers in services/emailService.js.
All fire-and-forget — admin alerts can't block report creation."
```

---

## Task F1: Anonymity toggle in Flutter privacy settings

**Files:**
- Modify: `lib/pages/profile/edit/privacy_edit.dart`
- Modify: any model that maps `privacySettings` from JSON (likely `lib/models/users_model.dart` or `lib/providers/provider_models/users_model.dart`)

Working dir: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

- [ ] **Step 1: Add the field to the user model.**

Find the `User` / `Community` model that has fields like `showOnlineStatus`. Add an `anonymousProfileVisits` boolean alongside it. Wire it into the `fromJson` factory and `toJson` method.

- [ ] **Step 2: Add the toggle row in `privacy_edit.dart`.**

Find the existing privacy toggles (rows for `showOnlineStatus`, `showCity`, etc.). Add a new row:

```dart
SwitchListTile(
  title: const Text('Visit profiles anonymously'),
  subtitle: const Text(
    'Your name won\'t appear in the visited user\'s recent-visitors list.',
  ),
  value: _anonymousProfileVisits,
  onChanged: (value) {
    setState(() => _anonymousProfileVisits = value);
  },
),
```

Wire `_anonymousProfileVisits` into the screen's state + initial load + save call.

- [ ] **Step 3: Verify.**

```bash
flutter analyze lib/pages/profile/edit/privacy_edit.dart 2>&1 | tail -3
```

- [ ] **Step 4: Commit.**

```bash
git add lib/pages/profile/edit/privacy_edit.dart lib/models/ lib/providers/
git commit -m "feat(safety): privacy toggle for anonymous profile visits

Audit issue #13. New SwitchListTile in privacy_edit.dart toggles
the User.privacySettings.anonymousProfileVisits boolean. Default
off so existing users aren't surprised by a behavior change.

Backend already reads this preference server-side (B4) and writes
ProfileVisit.isAnonymous accordingly. getRecentVisitors already
filters \$match: { isAnonymous: false } so the recall card updates
automatically — no Flutter changes needed downstream.

Copy: 'Visit profiles anonymously' / 'Your name won't appear in
the visited user's recent-visitors list.' Matches the tone of the
existing privacy toggles."
```

---

## Task F2: Role-gate AdminReportsScreen + admin entrypoint + suspended screen

**Files:**
- Modify: `lib/pages/reports/admin_reports_screen.dart`
- Modify: `lib/pages/profile/profile_main.dart`
- Modify: `lib/services/auth_service.dart` (or wherever login response is parsed)
- Create: `lib/pages/auth/account_suspended_screen.dart`

- [ ] **Step 1: Add role check on AdminReportsScreen.**

In the screen's `initState` (or just inside `build` for a Consumer wrapper), read `userProvider.value?.role` and if not `'admin'`, navigate away:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final user = ref.read(userProvider).valueOrNull;
    if (user?.role != 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _NotAuthorizedScreen()),
      );
    }
  });
}
```

Add a private `_NotAuthorizedScreen` at the bottom of the file showing "This page isn't available."

- [ ] **Step 2: Add admin entrypoint in `profile_main.dart`.**

Find the existing profile menu rows (settings, etc.). Add a conditional row:

```dart
Consumer(
  builder: (context, ref, _) {
    final user = ref.watch(userProvider).valueOrNull;
    if (user?.role != 'admin') return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings_outlined),
      title: const Text('Admin · Reports'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
      ),
    );
  },
),
```

Import `AdminReportsScreen` at top of file.

- [ ] **Step 3: Create the suspended screen.**

`lib/pages/auth/account_suspended_screen.dart`:

```dart
import 'package:flutter/material.dart';

class AccountSuspendedScreen extends StatelessWidget {
  final String? reason;
  const AccountSuspendedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Your account has been suspended',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                reason != null && reason!.isNotEmpty
                    ? 'Reason: $reason'
                    : 'Your account is no longer accessible.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                "If you believe this was made in error, contact appeal@banatalk.com with your username.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Detect 403 ban response in API client + route to suspended screen.**

Two changes — ApiClient detection, then main.dart wiring. Mirror the Step 13A F4 paywall pattern exactly: use the existing `callOverlayNavigatorKey` from `lib/router/app_router.dart` (purpose-built for overlays above GoRouter; same key used by `PersonaUpgradeSheet`).

**a) ApiClient detection.** In `lib/services/api_client.dart`:

Add a new callback field alongside the existing ones (near `onAuthenticationError`, `onQuotaExceeded`):

```dart
/// Step 14: called when the server returns 403 with body.error
/// starting with "Your account has been suspended" — the banned-user
/// indicator from the protect middleware after Step 14 B1.
Function(String reason)? onAccountSuspended;
```

In the 403 branch of `_handleResponse`, BEFORE the existing 403 logic:

```dart
final errorMessage = body['error']?.toString() ?? '';
if (errorMessage.startsWith('Your account has been suspended')) {
  onAccountSuspended?.call(errorMessage);
  return build(
    success: false,
    error: errorMessage,
    statusCode: 403,
  );
}
// existing 403 path follows
```

**b) main.dart wiring.** Right after the existing `onQuotaExceeded` wiring (the Step 13A F4 paywall hook), add:

```dart
apiClient.onAccountSuspended = (reason) async {
  // 1) Clear the stored token using the existing logout method.
  //    AuthService.logout() handles secureStorage + state cleanup.
  try {
    await ref.read(authServiceProvider).logout();
  } catch (e) {
    debugPrint('[suspended] logout failed: $e');
  }

  // 2) Invalidate user-related providers so any cached identity is dropped.
  ref.invalidate(userProvider);

  // 3) Push AccountSuspendedScreen via the global overlay navigator
  //    (sits above GoRouter — same pattern as the persona paywall).
  //    pushReplacement (not push) so user can't navigate back to the
  //    authenticated app. AccountSuspendedScreen is terminal for v1.
  final overlayNav = callOverlayNavigatorKey.currentState;
  if (overlayNav != null) {
    overlayNav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AccountSuspendedScreen(reason: reason),
      ),
      (_) => false,  // clear the entire route stack
    );
  }
};
```

Add the imports at top of `main.dart`:
```dart
import 'package:bananatalk_app/pages/auth/account_suspended_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
```

(`callOverlayNavigatorKey` is already imported from Step 13A.)

**Note on `ref` access:** `main.dart`'s callback closure needs access to `ref`. The Step 13A wiring already established a pattern — verify how `onQuotaExceeded` accesses providers there and mirror it (likely via a top-level `WidgetsBinding`-scoped ref or by reading from `ProviderContainer` directly).

- [ ] **Step 5: Verify.**

```bash
flutter analyze lib/pages/reports/ lib/pages/auth/ lib/pages/profile/profile_main.dart lib/services/api_client.dart 2>&1 | tail -5
```

- [ ] **Step 6: Commit.**

```bash
git add lib/pages/reports/admin_reports_screen.dart lib/pages/profile/profile_main.dart lib/pages/auth/account_suspended_screen.dart lib/services/api_client.dart lib/main.dart
git commit -m "feat(safety): role-gate admin reports + suspended account screen

Audit issue #15 (Flutter side).

AdminReportsScreen: added a postFrameCallback role check; non-admins
are pushed to a 'this page isn't available' screen on entry.
Backend authorize('admin') is still the actual security boundary;
the client gate is UX defense-in-depth so admins navigate cleanly
and non-admins can't snoop the UI.

ProfileMain: new admin-only menu row (Consumer-wrapped, hidden
for non-admins) routes to AdminReportsScreen.

AccountSuspendedScreen: new full-screen 'your account has been
suspended' view with the ban reason + appeal contact. ApiClient
gains an onAccountSuspended callback; main.dart wires it to clear
the auth token and push the screen when a 403 'Your account has
been suspended' response arrives."
```

---

## Task G1: Glue — smoke test + push

**Files:** none (this is the merge gate)

- [ ] **Step 1: Backend smoke tests.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
npm run dev &

TOKEN_USER="<token of a regular user>"
TOKEN_ADMIN="<token of an admin user>"
TOKEN_BLOCKED="<token of a user who has been blocked by TOKEN_USER>"

# Voice room listing — blocked rooms should not appear
curl -s -H "Authorization: Bearer $TOKEN_BLOCKED" http://localhost:5000/api/v1/voicerooms?status=all | jq '.data | length'

# Voice room join — blocked join should be 403
curl -s -X POST -H "Authorization: Bearer $TOKEN_BLOCKED" http://localhost:5000/api/v1/voicerooms/<HOST_ROOM_ID>/join | jq '.error'
# Expected: "You cannot join this room"

# Anonymous profile visit — set preference + verify recordVisit honors it
curl -s -X PUT -H "Authorization: Bearer $TOKEN_USER" -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/users/me/privacy \
  -d '{"anonymousProfileVisits": true}' | jq '.data.privacySettings.anonymousProfileVisits'
# Expected: true
# Then visit a profile; check the ProfileVisit record has isAnonymous: true

# Report flow — admin email fires + resolveReport user_banned works
curl -s -X POST -H "Authorization: Bearer $TOKEN_USER" -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/reports \
  -d '{"type": "profile", "reportId": "<target_user_id>", "reportedUser": "<target_user_id>", "reason": "harassment"}' | jq '.success'
# Expected: true. Check inbox for admin alert email.

curl -s -X PUT -H "Authorization: Bearer $TOKEN_ADMIN" -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/reports/<REPORT_ID>/resolve \
  -d '{"action": "user_banned", "notes": "Confirmed harassment"}' | jq '.success'
# Verify target user has isBanned: true in DB.
# Verify their voice rooms ended.
# Verify they receive a "Your account has been suspended" email.

# Banned user can't login
curl -s -H "Authorization: Bearer <banned_user_token>" http://localhost:5000/api/v1/tutor/me | jq '.error'
# Expected: "Your account has been suspended..."
```

- [ ] **Step 2: Flutter smoke (iOS physical + Android physical).**

1. **Anonymous toggle:** Profile → Edit Privacy → flip "Visit profiles anonymously" ON → save. View someone else's profile. Other user opens Community → confirm Visitor Recall Card does NOT show your avatar. Flip OFF → re-visit → confirm card now shows you.

2. **Admin entrypoint:** Log in as admin → Profile → confirm "Admin · Reports" row appears. Tap → confirm AdminReportsScreen loads. Log in as non-admin → confirm row is hidden.

3. **Admin reports screen as non-admin:** Hard-code the route navigation (or use deeplink). Confirm immediate redirect to "This page isn't available."

4. **Banned user UX:** As admin, resolve a report with `user_banned`. Have the banned user attempt any action in the Flutter app. Confirm they see AccountSuspendedScreen with the ban reason. Confirm token is cleared (relaunching app → login screen, not auto-logged-in).

5. **Voice room visibility:** User A blocks User B. User B hosts a voice room. User A opens Voice Rooms tab → confirm B's room is NOT in the list. User A attempts to deep-link to the room ID → 404.

6. **Banned host mid-session UX:** With User A as host of an active voice room with at least one participant (User C, unrelated), admin bans User A via `resolveReport` action `user_banned`. Verify:
   - Within ~1 second, User C is evicted from the LiveKit audio session (mic/audio drops, transport closes)
   - User C's Flutter UI lands back on the Voice Rooms lobby tab
   - The end-of-room message shown to User C is acceptable — NO misleading "host disconnected, will return in 30s" copy (which would imply graceful disconnect rather than ban). Existing `voiceroom:ended` event copy should just say "Room ended" or equivalent.
   - The room no longer appears in the lobby listing
   - User A, on their device, sees AccountSuspendedScreen on their next interaction

- [ ] **Step 3: Push both branches.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git push -u origin feat/step14-safety-wave

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze 2>&1 | grep -E "error •" && echo "ERRORS — fix before merge" || echo "no errors"
git push -u origin feat/step14-safety-wave
```

- [ ] **Step 4: Open PRs.**

```bash
gh pr create --title "feat: Step 14 safety wave (voice room blocks + reports + anonymity)" \
  --body "Step 14 safety wave. See docs/superpowers/plans/2026-05-14-step14-safety-wave-plan.md."
```

Same on backend.

---

## Cadence guidance

- **B1 lands first** — adds the `isBanned` field + middleware check + `anonymousProfileVisits` schema field. Everything else depends on these.
- **B2 + B3 are tight pair** (voice room block enforcement). Can be authored in parallel but commit B2 (listing) first so the join path (B3) has the listing filter to reference.
- **B4 is independent** of the voice room work; can land any time after B1.
- **B5 is the heaviest** — email helpers + templates + resolveReport actions. Land after B1 (depends on `isBanned`).
- **F1 is independent** — toggle in privacy_edit.
- **F2 depends on B1** (needs the suspended-account 403 response from middleware) but can be authored in parallel.
- **G1 is the manual smoke + merge gate.**

## Risk + rollback

- **Highest risk: B5 `resolveReport` content removal.** Mistakes here delete real user data. Rollback: revert B5; resolved reports stay in the DB but the deleted content is gone forever (no restore path). Mitigation: test each `report.type` path on a staging environment with non-prod data first.
- **Mid-risk: B1 `isBanned` middleware check.** A bug in the middleware (e.g., misread of `req.user`) could block all users from every protected route. Rollback: revert B1; defaults set false so no users are accidentally banned. Mitigation: the protect path returns 403 only when `req.user.isBanned === true` (strict equality, not truthy check) and `req.user` is loaded — if either is null/undefined, the check passes silently.
- **Low risk: B2-B3 voice room filters.** Worst case: legitimate rooms get filtered out. Rollback: revert the two commits; behavior reverts to current (overly-permissive) state. Mitigation: the filter is opt-in (only fires when `blockedUserIds.length > 0`), so users with no blocks see no change.
- **Low risk: B4 anonymity preference.** A bug means visits stay non-anonymous (matches current state). Rollback: revert; behavior reverts to current.
- **Low risk: F1 + F2.** Pure additive Flutter changes. Rollback: revert; UI reverts to current.

**Emergency disable** (for B5): if admin email volume is too high, set `ADMIN_REPORT_ALERTS_ENABLED=false` in `.env` and the `sendAdminReportAlert` helper short-circuits. (Add this env-flag guard at the top of the helper.)

**No DB migrations.** Both new schema fields (`isBanned`, `anonymousProfileVisits`) default false; existing users get the default on first read. No backfill needed.

---

## Appendix A — what's NOT in this wave

Restated to make the boundary clear during execution:

- ❌ Wave rate-limit counter fix (audit issue #2)
- ❌ Wave 24h index drift fix (audit issue #1)
- ❌ Recording feature (audit issue #5)
- ❌ Voice room cost ceilings (audit issue #7)
- ❌ Nearby radius silent clamp (audit issue #11)
- ❌ Smart Match algorithm completeness (audit issue #9)
- ❌ Auto-action on N reports (deliberately punted in §15 design decision)
- ❌ Admin audit log model
- ❌ Slack/webhook admin notification
- ❌ Voice room socket broadcast filtering (CC-5)
- ❌ Voice room mid-session kick-on-block
- ❌ Any AI Study work

If during execution you discover something that wants to expand scope, write it to `docs/manual-todos.md` under Queued engineering and continue. Do NOT expand the plan.

## Appendix B — admin bootstrap

To promote the first admin (one-time setup):

```bash
# Connect to Mongo
mongo "mongodb://..."

# Promote the user
db.users.updateOne({ email: "you@example.com" }, { $set: { role: "admin" } })
```

After that, additional admins can be promoted via `PUT /api/v1/auth/make-admin/:userId` from the existing admin's session. No new code needed for bootstrap; this is documented here so the executor knows what to tell the user.
