# Step 15 — Admin Tools Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close four moderator-tooling gaps from Step 14: no unban UI, no manual ban (without a Report record), no admin user search, no audit log of moderator actions. Land a focused admin surface (AdminHome → Users / Audit Log alongside the existing Reports screen) with the underlying durable audit log + extracted ban/unban primitives.

**Architecture:** Backend gets a new `services/banService.js` housing the shared `banUser` and `unbanUser` side-effect logic (so the existing `resolveReport user_banned` flow and the new manual-ban endpoint converge on one implementation). A new `models/AdminAuditLog.js` Mongoose model records every moderator action durably (no TTL). A new `controllers/admin.js` + `routes/admin.js` host the new endpoints under `/api/v1/admin/*`. Flutter gets an `AdminHomeScreen` (grid of admin tools) that replaces the current direct-to-reports entry, plus `AdminUsersScreen` (search + facets), `AdminUserDetailScreen` (ban/unban/role-change actions), and `AdminAuditLogScreen` (paginated history). Confirmation dialogs require a non-empty reason for destructive actions; reasons feed the audit log.

**Tech Stack:** Node.js / Express / Mongoose / MongoDB (backend); Flutter / Riverpod (mobile). No new dependencies.

**Recon reference:** `docs/superpowers/recon/2026-05-14-step15-admin-tools-recon.md` — read before executing.

**Branches:** `feat/step15-admin-tools` on both repos (separate from the `-planning` branch that holds this doc + the recon).

**Estimated commits:** 11 (B1-B6 backend, F1-F4 Flutter, G1 glue).

**Pacing:** Drive uninterrupted through tasks per the user's recorded preference. Surface only at G1 or on a genuine blocker.

---

## Hard constraints (from the user)

- **Out of scope:** Voice room live moderation, proactive content browse, admin dashboard counters, bulk admin actions, super-admin tier, unban-self appeal flow, audit log CSV export, search-by-IP, username/email change history. Anything in the recon's Punted findings list.
- **No refactoring of unrelated code.** The `resolveReport` refactor IS in scope (it extracts to `banService` — that's the whole point of D-4 option C).
- **No new dependencies without explicit user approval.**
- **Match existing commit-message style** — no Co-Authored-By trailers, no marketing copy in messages.
- **Both repos use branch `feat/step15-admin-tools`** for execution (not the planning branch).

---

## Edge cases handled

- **Admin demotes themselves.** Controller rejects with 403 ("You cannot revoke your own admin role"). Same for self-ban via the manual ban endpoint (`req.user.id === req.params.id` → 403, "You cannot ban yourself").
- **Admin A bans admin B.** Allowed. Ban sets `isBanned: true` but leaves `role: 'admin'` untouched — admin role and ban status are orthogonal. Banned admin simply can't authenticate; their role is preserved for if/when they're unbanned.
- **Manual ban path vs report ban path divergence.** Both call `banService.banUser(userId, reason, moderatorId, source)` where `source` is `'manual'` or `'report:<reportId>'`. Single side-effect implementation: set ban fields, end voice rooms, clear FCM tokens, send ban email, log audit action.
- **Unban after the user account was deleted.** `unbanUser` 404s if `findById` returns null. Audit log gets a `target_not_found` entry so the moderator's attempt is still recorded.
- **Audit log race condition.** Append-only. Two admins acting simultaneously on the same user both get entries. No dedup. Reads are sorted descending by `timestamp`.
- **Manual ban with empty reason.** Endpoint rejects with 400 — manual bans must be explainable. Report-driven bans accept null notes (existing behavior preserved).
- **Unban email when banned user has FCM tokens cleared.** Email is the only channel. Acceptable. User learns next time they try to log in OR via email.
- **Demoted admin keeps stale AdminUsersScreen open.** Client-side role gate fires only on initial route entry; server's `authorize('admin')` blocks every API call from that point. They see a static screen they can't action. Acceptable v1.
- **Search includes banned users by default.** A faceted toggle "Banned only" filters down. Default mixed view shows all so admins can find a user to unban.
- **Search by email with a partial substring.** Allowed — `$regex` against `email` field with case-insensitive flag. No fuzzy matching beyond substring.
- **Audit log retention.** No TTL in v1. At ~1K active users, ~50 mod actions/year is small storage. If the table grows past a few hundred MB later, add a TTL job.
- **Promote-to-admin endpoint conflict.** Existing `PUT /api/v1/auth/make-admin/:userId` is one-directional. The new `PUT /api/v1/admin/users/:id/role` body `{ role: 'admin' | 'user' }` supersedes it. Keep the old endpoint working for backwards compat; mark it as deprecated in a comment but do not remove this wave.

---

## Design decisions

1. **Audit log: NEW `AdminAuditLog` Mongoose model (D-1 option A).**
   - Separate collection, no TTL, durable.
   - Schema: `moderator: ObjectId`, `action: String enum`, `target: ObjectId`, `targetType: String`, `details: Mixed`, `reason: String`, `source: String` (manual / report:<id> / null), `timestamp: Date indexed`.
   - Indexes: `{ moderator: 1, timestamp: -1 }`, `{ target: 1, timestamp: -1 }`, `{ action: 1, timestamp: -1 }`.
   - **Rejected:** SecurityLog reuse — 90-day TTL purges history that needs to be durable. Embedded on User doc — bloats user, hard to query "all actions by moderator X."

2. **Admin routes: NEW `routes/admin.js` mounted at `/api/v1/admin` (D-2 option A).**
   - All Step 15 endpoints centralized here. Existing scattered admin endpoints (make-admin, mode change, report routes) stay where they are this wave; future admin work converges here.
   - **Rejected:** Extending `users.js` — admin surface becomes harder to enumerate. Hybrid scatter — arbitrary boundary.

3. **User search: single search box + faceted chip filters (D-3 option A+C hybrid).**
   - Single text input matches against `email`, `name`, `username` (case-insensitive substring).
   - Filter chips: "All" / "Banned only" / "Admins only". Mutually exclusive.
   - **Rejected:** Three separate fields — UI clutter for low value. Single box only — misses the "show me all banned users" use case which is real.

4. **Ban flow: extracted `banService.banUser` helper (D-4 option C).**
   - `services/banService.js#banUser(userId, reason, moderatorId, source)` does the full side-effect: set ban fields, end voice rooms (mirroring `endVoiceRoom` flow exactly), clear FCM, send email, log audit.
   - `controllers/report.js#resolveReport` action='user_banned' is refactored to call `banService.banUser(report.reportedUser, notes, req.user.id, \`report:${report._id}\`)`.
   - New `POST /admin/users/:id/ban` calls `banService.banUser(req.params.id, reason, req.user.id, 'manual')`.
   - **Rejected:** Duplicate logic in new endpoint — drift risk. Synthetic Report record on manual ban — pollutes report log, awkward semantics.

5. **Admin entry points: single "Admin Tools" entry → AdminHomeScreen grid (D-5 option B).**
   - Profile menu + drawer both point to AdminHomeScreen instead of AdminReportsScreen.
   - AdminHomeScreen renders a 2-column grid of cards: Reports / Users / Audit Log. Each tile shows its destination icon + label.
   - **Rejected:** Three separate menu rows — profile menu becomes admin-heavy and doesn't scale. Bottom-tab variant — too big a shell change for one role.

6. **Unban confirmation: dialog with REQUIRED reason field (D-6 option B).**
   - Tap unban → AlertDialog with TextField asking "Reason for unbanning". Save button disabled until non-empty.
   - Reason flows to `banService.unbanUser` → audit log entry → unban notification email.
   - **Rejected:** Single tap — misclicks are real. Confirm without reason — audit log loses context.

7. **Role change endpoint: extend with `{ role: 'admin' | 'user' }` body (new endpoint, supersedes make-admin).**
   - New `PUT /api/v1/admin/users/:id/role` accepts `{ role, reason }`. Reason required.
   - Self-demote rejected (`req.user.id === req.params.id && role === 'user'` → 403).
   - Existing `PUT /api/v1/auth/make-admin/:userId` left in place (no removal this wave) but documented as deprecated.

---

## File structure

### Backend (`/Users/davis/Desktop/Personal/language_exchange_backend_application`)

**Create:**
- `models/AdminAuditLog.js` — new Mongoose model + 3 indexes + static helper `logAction({ moderator, action, target, ... })`
- `services/banService.js` — `banUser(userId, reason, moderatorId, source)` + `unbanUser(userId, reason, moderatorId)` + `changeUserRole(userId, role, reason, moderatorId)` helpers
- `controllers/admin.js` — `searchUsers`, `getUserDetail`, `banUser`, `unbanUser`, `changeRole`, `getAuditLog`
- `routes/admin.js` — mount the 6 endpoints under `/api/v1/admin/*`

**Modify:**
- `controllers/report.js` — refactor `resolveReport` action='user_banned' to delegate to `banService.banUser`
- `services/emailService.js` — add `sendUnbanNotification(userId, reason)` (APPEND pattern, mirroring sendBanNotification)
- `utils/emailTemplates.js` — add `unbanNotification(reason)` template (APPEND pattern, before final `module.exports = exports;`)
- `server.js` — mount `app.use('/api/v1/admin', admin)` alongside the existing route mounts

### Flutter (`/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`)

**Create:**
- `lib/providers/provider_root/admin_provider.dart` — `AdminService` class with methods: `searchUsers({ q, banned, adminsOnly, page })`, `getUser(id)`, `banUser(id, reason)`, `unbanUser(id, reason)`, `changeRole(id, role, reason)`, `getAuditLog({ moderatorId, targetId, action, page })`
- `lib/pages/admin/admin_home_screen.dart` — 2-column grid: Reports / Users / Audit Log tiles
- `lib/pages/admin/admin_users_screen.dart` — search box + facet chips + paginated list
- `lib/pages/admin/admin_user_detail_screen.dart` — rich user card + ban/unban/role actions with confirmation dialogs
- `lib/pages/admin/admin_audit_log_screen.dart` — paginated history list

**Modify:**
- `lib/pages/profile/profile_main.dart` — change `_buildAdminReportsEntry` to point to `AdminHomeScreen` and rename to `_buildAdminToolsEntry`; copy "Admin · Tools"
- `lib/pages/profile/drawer/profile_drawer.dart` — change admin entry destination to `AdminHomeScreen`; update subtitle copy
- `lib/services/analytics_service.dart` — add `adminActionTaken(action, targetId)` event (APPEND, fire-and-forget)

**No router changes** — admin screens use `Navigator.push(MaterialPageRoute(...))` to match the existing `AdminReportsScreen` navigation pattern (no `go_router` routes for admin per the existing convention in profile_main).

---

## Critical decisions baked in

1. **Audit log is the system of record for moderator actions.** Every `banUser`, `unbanUser`, `changeUserRole`, plus the existing `resolveReport` (via the refactor) writes an `AdminAuditLog` entry before returning. If the audit log write fails, the action still completes — log failure is non-blocking, errors go to `console.error`. (Rationale: audit log write race shouldn't undo a ban.)

2. **`banService` is the single ban side-effect implementation.** Step 14's `resolveReport` is refactored to delegate; the new manual endpoint also delegates. No third caller is introduced in this wave. Any future "auto-ban after N reports" feature must also go through `banService.banUser`.

3. **Search is case-insensitive substring matching, not fuzzy.** `$regex` with the `i` flag against name / email / username. No edit-distance, no soundex, no Atlas Search. Performance is fine at ~1K users; revisit if user count grows past ~50K.

4. **All admin endpoints are gated by `authorize('admin')`.** Client-side role gate in screens is best-effort defense-in-depth only.

5. **Unban silently succeeds on already-not-banned users.** If `isBanned` is already false when unbanUser is called, no-op + audit log entry still written (action: 'unban_noop'). Avoids 400-ing on edge cases.

6. **Role-change endpoint takes `{ role, reason }`, not `{ promote: true }`.** Future-proof for additional roles (super_admin, moderator, etc.) without endpoint surgery. v1 accepts only 'admin' or 'user'.

7. **The legacy `PUT /api/v1/auth/make-admin/:userId` endpoint stays in place.** Documented as deprecated in a code comment; not removed. Old admin tooling (if any external scripts reference it) keeps working. Removal is a separate cleanup wave.

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
# Expected: no output (or only ios/Podfile.lock as known-volatile)
```

If anything other than `ios/Podfile.lock` is dirty, STOP and surface.

- [ ] **Step 2: Create execution branches from main.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull --ff-only && git checkout -b feat/step15-admin-tools

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
git checkout main && git pull --ff-only && git checkout -b feat/step15-admin-tools
```

- [ ] **Step 3: Copy plan + recon to backend.**

```bash
cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/recon/2026-05-14-step15-admin-tools-recon.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/recon/

cp /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app/docs/superpowers/plans/2026-05-14-step15-admin-tools-plan.md \
   /Users/davis/Desktop/Personal/language_exchange_backend_application/docs/superpowers/plans/

cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git add docs/superpowers/
git commit -m "docs: Step 15 admin tools recon + plan"
```

---

## Task B1: AdminAuditLog model + logAction helper

**Files:**
- Create: `models/AdminAuditLog.js`

Working dir: `/Users/davis/Desktop/Personal/language_exchange_backend_application`

- [ ] **Step 1: Create the model.**

```js
const mongoose = require('mongoose');

/**
 * AdminAuditLog — durable record of moderator actions.
 *
 * Append-only. No TTL: mod accountability needs multi-year retention.
 * At ~1K active users, expected volume is ~50-100 actions/year — tiny
 * storage cost relative to the visibility benefit.
 *
 * action enum is open-ended (anyString) but conventionally:
 *   user_banned, user_unbanned, user_warned, role_changed,
 *   content_removed, report_resolved, report_dismissed
 */
const AdminAuditLogSchema = new mongoose.Schema({
  moderator: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  action: {
    type: String,
    required: true,
    index: true,
  },
  target: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    index: true,
  },
  targetType: {
    type: String,
    default: 'user',
  },
  reason: {
    type: String,
    default: null,
  },
  source: {
    type: String,
    default: null, // 'manual' | 'report:<reportId>' | null
  },
  details: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

AdminAuditLogSchema.index({ moderator: 1, timestamp: -1 });
AdminAuditLogSchema.index({ target: 1, timestamp: -1 });
AdminAuditLogSchema.index({ action: 1, timestamp: -1 });

/**
 * Static helper. Fire-and-forget; never throws to caller.
 * Caller passes { moderator, action, target, reason, source, details }.
 */
AdminAuditLogSchema.statics.logAction = async function(entry) {
  try {
    return await this.create({
      moderator: entry.moderator,
      action: entry.action,
      target: entry.target || null,
      targetType: entry.targetType || 'user',
      reason: entry.reason || null,
      source: entry.source || null,
      details: entry.details || {},
    });
  } catch (err) {
    console.error('[AdminAuditLog] write failed:', err.message);
    return null;
  }
};

module.exports = mongoose.model('AdminAuditLog', AdminAuditLogSchema);
```

- [ ] **Step 2: Verify syntax.**

```bash
node -c models/AdminAuditLog.js
```

- [ ] **Step 3: Commit.**

```bash
git add models/AdminAuditLog.js
git commit -m "feat(admin): AdminAuditLog model + logAction helper

Durable (no TTL) record of moderator actions. Indexes on moderator,
target, action, and timestamp support 'what did mod X do' and
'who acted on user Y' queries.

Schema:
- moderator: required, indexed
- action: required, indexed (string — open-ended enum)
- target: optional ObjectId (the user acted upon)
- targetType: default 'user' (allows future content moderation)
- reason: optional moderator-supplied text
- source: 'manual' | 'report:<id>' | null
- details: Mixed bag for action-specific payload
- timestamp: indexed for descending sort

logAction static is fire-and-forget — never throws to the caller.
A failed audit write is logged to console but doesn't undo the
underlying moderator action."
```

---

## Task B2: banService — banUser + unbanUser + changeUserRole helpers

**Files:**
- Create: `services/banService.js`

- [ ] **Step 1: Create the service.**

```js
/**
 * banService — single side-effect implementation for moderator
 * actions on user accounts. Both the report-driven flow
 * (controllers/report.js#resolveReport action=user_banned, refactored
 * in B6 of this wave) and the new manual-ban endpoint
 * (controllers/admin.js#banUser) converge here.
 *
 * Side-effects on ban:
 *   1. Set User.isBanned=true, banReason, bannedAt
 *   2. End all active voice rooms hosted by the banned user
 *      (mirrors controllers/voiceRooms.js#endVoiceRoom: room.end()
 *      + livekitAdmin.endRoom() + 2 socket emits)
 *   3. Clear User.fcmTokens
 *   4. emailService.sendBanNotification
 *   5. AdminAuditLog.logAction
 *
 * Side-effects on unban:
 *   1. Set User.isBanned=false, banReason=null, bannedAt=null
 *   2. emailService.sendUnbanNotification
 *   3. AdminAuditLog.logAction
 *
 * Side-effects on role change:
 *   1. Set User.role
 *   2. AdminAuditLog.logAction
 */

const User = require('../models/User');
const VoiceRoom = require('../models/VoiceRoom');
const AdminAuditLog = require('../models/AdminAuditLog');
const livekitAdmin = require('./livekitAdminService');
const emailService = require('./emailService');

exports.banUser = async function ({ userId, reason, moderatorId, source, io }) {
  const user = await User.findById(userId);
  if (!user) {
    await AdminAuditLog.logAction({
      moderator: moderatorId,
      action: 'ban_failed_target_missing',
      target: userId,
      reason,
      source,
    });
    return { ok: false, error: 'User not found' };
  }

  await User.findByIdAndUpdate(userId, {
    isBanned: true,
    banReason: reason || 'Banned by moderator',
    bannedAt: new Date(),
  });

  // Auto-end active voice rooms hosted by the banned user.
  const activeRooms = await VoiceRoom.find({
    host: userId,
    status: { $in: ['waiting', 'active'] },
  });
  for (const room of activeRooms) {
    try {
      await room.end();
      await livekitAdmin.endRoom(String(room._id));
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
      console.error(`[banService] failed to end room ${room._id}:`, err.message);
    }
  }

  // Clear FCM tokens.
  await User.findByIdAndUpdate(userId, { $set: { fcmTokens: [] } });

  // Email (fire-and-forget).
  emailService.sendBanNotification(userId, reason).catch(err =>
    console.error('[banService] sendBanNotification failed:', err.message)
  );

  // Audit log.
  await AdminAuditLog.logAction({
    moderator: moderatorId,
    action: 'user_banned',
    target: userId,
    reason,
    source,
    details: { activeRoomsEnded: activeRooms.length },
  });

  return { ok: true };
};

exports.unbanUser = async function ({ userId, reason, moderatorId }) {
  const user = await User.findById(userId);
  if (!user) {
    await AdminAuditLog.logAction({
      moderator: moderatorId,
      action: 'unban_failed_target_missing',
      target: userId,
      reason,
    });
    return { ok: false, error: 'User not found' };
  }

  if (user.isBanned !== true) {
    await AdminAuditLog.logAction({
      moderator: moderatorId,
      action: 'unban_noop',
      target: userId,
      reason,
      details: { already_unbanned: true },
    });
    return { ok: true, noop: true };
  }

  await User.findByIdAndUpdate(userId, {
    isBanned: false,
    banReason: null,
    bannedAt: null,
  });

  emailService.sendUnbanNotification(userId, reason).catch(err =>
    console.error('[banService] sendUnbanNotification failed:', err.message)
  );

  await AdminAuditLog.logAction({
    moderator: moderatorId,
    action: 'user_unbanned',
    target: userId,
    reason,
  });

  return { ok: true };
};

exports.changeUserRole = async function ({ userId, role, reason, moderatorId }) {
  if (!['user', 'admin'].includes(role)) {
    return { ok: false, error: 'Invalid role' };
  }

  const user = await User.findById(userId);
  if (!user) return { ok: false, error: 'User not found' };

  const previousRole = user.role;
  await User.findByIdAndUpdate(userId, { role });

  await AdminAuditLog.logAction({
    moderator: moderatorId,
    action: 'role_changed',
    target: userId,
    reason,
    details: { from: previousRole, to: role },
  });

  return { ok: true, previousRole, newRole: role };
};
```

- [ ] **Step 2: Verify syntax.**

```bash
node -c services/banService.js
```

- [ ] **Step 3: Commit.**

```bash
git add services/banService.js
git commit -m "feat(admin): banService — banUser / unbanUser / changeUserRole

Single side-effect implementation for moderator actions. Both the
report-driven ban (controllers/report.js#resolveReport, refactored
in B6) and the new manual-ban endpoint (controllers/admin.js#banUser,
B4) call into here so the ban semantics are guaranteed identical.

banUser mirrors the existing Step 14 ban flow: set User.isBanned +
banReason + bannedAt, end active voice rooms via the canonical
endVoiceRoom flow (room.end + livekitAdmin.endRoom + 2 socket
emits), clear fcmTokens, send ban email, write audit log entry.

unbanUser is the inverse: unset ban fields, send unban email
(emailService.sendUnbanNotification added in B3), log. No-op on
already-unbanned users (still logs).

changeUserRole supports promoting to admin or demoting back to user.
Records previous and new role in the audit log details.

All audit log writes are fire-and-forget — failures don't undo the
underlying action.

Note: the legacy PUT /auth/make-admin/:userId endpoint stays in
place this wave for backwards compat; removal is a separate task."
```

---

## Task B3: sendUnbanNotification email helper + template

**Files:**
- Modify: `utils/emailTemplates.js`
- Modify: `services/emailService.js`

- [ ] **Step 1: Add the template (APPEND pattern).**

In `utils/emailTemplates.js`, insert before the final `module.exports = exports;` line, after the existing `exports.banNotification = ...`:

```js
exports.unbanNotification = (reason) => ({
  subject: `Your ${APP_NAME} account has been restored`,
  text: `Good news — your account has been restored.

${reason ? `Reason: ${reason}\n\n` : ''}You can log in and resume using ${APP_NAME} normally.

If you have any questions, contact support@banatalk.com.`,
  html: baseTemplate(`
    <tr>
      <td style="background: linear-gradient(135deg, #4cd964 0%, #11998e 100%); padding: 40px; text-align: center;">
        <h1 style="color: #fff; margin: 0; font-size: 28px;">Account Restored</h1>
      </td>
    </tr>
    <tr>
      <td style="padding: 40px 30px;">
        <p style="font-size: 16px; color: #555; line-height: 1.7;">Good news — your account has been restored.</p>
        ${reason ? `<p style="font-size: 16px; color: #555; line-height: 1.7;"><strong>Reason:</strong> ${reason}</p>` : ''}
        <p style="font-size: 16px; color: #555; line-height: 1.7;">You can log in and resume using ${APP_NAME} normally.</p>
        <p style="font-size: 16px; color: #555; line-height: 1.7;">If you have any questions, contact <a href="mailto:support@banatalk.com" style="color: #11998e;">support@banatalk.com</a>.</p>
      </td>
    </tr>`, '#11998e')
});
```

- [ ] **Step 2: Add the helper in emailService.js (APPEND, mirroring sendBanNotification).**

Insert after `exports.sendBanNotification = async (userId, reason) => { ... };` but before the final `module.exports = exports;`:

```js
exports.sendUnbanNotification = async (userId, reason) => {
  try {
    const user = await User.findById(userId).select('name email').lean();
    if (!user?.email) return;
    const tpl = templates.unbanNotification(reason);
    await sendEmail({
      email: user.email,
      subject: tpl.subject,
      message: tpl.text,
      html: tpl.html,
    });
  } catch (err) {
    console.error('[email] sendUnbanNotification failed:', err.message);
  }
};
```

- [ ] **Step 3: Verify.**

```bash
node -c services/emailService.js && node -c utils/emailTemplates.js
```

- [ ] **Step 4: Commit.**

```bash
git add services/emailService.js utils/emailTemplates.js
git commit -m "feat(admin): sendUnbanNotification email helper + template

APPEND pattern matching the Step 14 emailService convention — three
new helpers added before module.exports = exports without replacing
existing exports.

Template uses the same baseTemplate wrapper as the Step 14 ban
notification, swapped to a positive (#11998e green) gradient.

Called from banService.unbanUser fire-and-forget; failures log to
console and don't block the unban write."
```

---

## Task B4: controllers/admin.js + routes/admin.js + server wiring

**Files:**
- Create: `controllers/admin.js`
- Create: `routes/admin.js`
- Modify: `server.js`

- [ ] **Step 1: Create `controllers/admin.js`.**

```js
const asyncHandler = require('../middleware/async');
const User = require('../models/User');
const AdminAuditLog = require('../models/AdminAuditLog');
const ErrorResponse = require('../utils/errorResponse');
const banService = require('../services/banService');

const ADMIN_USER_FIELDS =
  'name email username images imageUrls native_language language_to_learn ' +
  'location createdAt lastActive role isBanned banReason bannedAt userMode ' +
  'vipSubscription.isActive';

/**
 * @desc    Search users (admin)
 * @route   GET /api/v1/admin/users
 * @access  Admin
 * @query   q (string), banned (bool), adminsOnly (bool), page (int), limit (int)
 */
exports.searchUsers = asyncHandler(async (req, res, next) => {
  const { q, banned, adminsOnly } = req.query;
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 20));
  const skip = (page - 1) * limit;

  const filter = {};
  if (q && q.trim()) {
    const esc = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const rx = new RegExp(esc, 'i');
    filter.$or = [{ email: rx }, { name: rx }, { username: rx }];
  }
  if (banned === 'true') filter.isBanned = true;
  if (adminsOnly === 'true') filter.role = 'admin';

  const [users, total] = await Promise.all([
    User.find(filter)
      .select(ADMIN_USER_FIELDS)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    User.countDocuments(filter),
  ]);

  res.status(200).json({
    success: true,
    data: users,
    pagination: {
      total,
      page,
      limit,
      hasMore: skip + users.length < total,
    },
  });
});

/**
 * @desc    Get user detail (admin view)
 * @route   GET /api/v1/admin/users/:id
 * @access  Admin
 */
exports.getUserDetail = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.params.id)
    .select(ADMIN_USER_FIELDS)
    .lean();
  if (!user) return next(new ErrorResponse('User not found', 404));

  // Pull recent audit log entries targeting this user.
  const recentActions = await AdminAuditLog.find({ target: req.params.id })
    .sort({ timestamp: -1 })
    .limit(20)
    .populate('moderator', 'name email')
    .lean();

  res.status(200).json({
    success: true,
    data: { ...user, recentActions },
  });
});

/**
 * @desc    Ban a user manually (no report required)
 * @route   POST /api/v1/admin/users/:id/ban
 * @access  Admin
 * @body    { reason: string }
 */
exports.banUser = asyncHandler(async (req, res, next) => {
  const { reason } = req.body;
  if (!reason || !reason.trim()) {
    return next(new ErrorResponse('Reason is required', 400));
  }
  if (req.user.id === req.params.id) {
    return next(new ErrorResponse('You cannot ban yourself', 403));
  }

  const result = await banService.banUser({
    userId: req.params.id,
    reason: reason.trim(),
    moderatorId: req.user.id,
    source: 'manual',
    io: req.app.get('io'),
  });

  if (!result.ok) {
    return next(new ErrorResponse(result.error || 'Ban failed', 404));
  }
  res.status(200).json({ success: true, message: 'User banned' });
});

/**
 * @desc    Unban a user
 * @route   POST /api/v1/admin/users/:id/unban
 * @access  Admin
 * @body    { reason: string }
 */
exports.unbanUser = asyncHandler(async (req, res, next) => {
  const { reason } = req.body;
  if (!reason || !reason.trim()) {
    return next(new ErrorResponse('Reason is required', 400));
  }

  const result = await banService.unbanUser({
    userId: req.params.id,
    reason: reason.trim(),
    moderatorId: req.user.id,
  });

  if (!result.ok) {
    return next(new ErrorResponse(result.error || 'Unban failed', 404));
  }
  res.status(200).json({
    success: true,
    message: result.noop ? 'User was not banned' : 'User unbanned',
  });
});

/**
 * @desc    Change a user's role
 * @route   PUT /api/v1/admin/users/:id/role
 * @access  Admin
 * @body    { role: 'admin' | 'user', reason: string }
 */
exports.changeRole = asyncHandler(async (req, res, next) => {
  const { role, reason } = req.body;
  if (!['admin', 'user'].includes(role)) {
    return next(new ErrorResponse('Invalid role', 400));
  }
  if (!reason || !reason.trim()) {
    return next(new ErrorResponse('Reason is required', 400));
  }
  if (req.user.id === req.params.id && role === 'user') {
    return next(new ErrorResponse('You cannot revoke your own admin role', 403));
  }

  const result = await banService.changeUserRole({
    userId: req.params.id,
    role,
    reason: reason.trim(),
    moderatorId: req.user.id,
  });

  if (!result.ok) {
    return next(new ErrorResponse(result.error || 'Role change failed', 400));
  }
  res.status(200).json({
    success: true,
    data: { previousRole: result.previousRole, newRole: result.newRole },
  });
});

/**
 * @desc    Get the audit log (paginated)
 * @route   GET /api/v1/admin/audit-log
 * @access  Admin
 * @query   moderatorId, targetId, action, page, limit
 */
exports.getAuditLog = asyncHandler(async (req, res, next) => {
  const { moderatorId, targetId, action } = req.query;
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 50));
  const skip = (page - 1) * limit;

  const filter = {};
  if (moderatorId) filter.moderator = moderatorId;
  if (targetId) filter.target = targetId;
  if (action) filter.action = action;

  const [entries, total] = await Promise.all([
    AdminAuditLog.find(filter)
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit)
      .populate('moderator', 'name email')
      .populate('target', 'name email')
      .lean(),
    AdminAuditLog.countDocuments(filter),
  ]);

  res.status(200).json({
    success: true,
    data: entries,
    pagination: {
      total,
      page,
      limit,
      hasMore: skip + entries.length < total,
    },
  });
});
```

- [ ] **Step 2: Create `routes/admin.js`.**

```js
const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  searchUsers,
  getUserDetail,
  banUser,
  unbanUser,
  changeRole,
  getAuditLog,
} = require('../controllers/admin');

router.use(protect);
router.use(authorize('admin'));

router.get('/users', searchUsers);
router.get('/users/:id', getUserDetail);
router.post('/users/:id/ban', banUser);
router.post('/users/:id/unban', unbanUser);
router.put('/users/:id/role', changeRole);

router.get('/audit-log', getAuditLog);

module.exports = router;
```

- [ ] **Step 3: Wire into `server.js`.**

Find the existing route mount block (around line 277-286). Add `const admin = require('./routes/admin');` at the top alongside the other route requires. Then in the mount block, add:

```js
app.use('/api/v1/admin', admin);
```

Place it near the bottom of the existing `app.use('/api/v1/...')` block.

- [ ] **Step 4: Verify.**

```bash
node -c controllers/admin.js && node -c routes/admin.js && node -c server.js
```

- [ ] **Step 5: Commit.**

```bash
git add controllers/admin.js routes/admin.js server.js
git commit -m "feat(admin): admin controller + routes + server wiring

New /api/v1/admin/* surface mounting six endpoints:

- GET  /users                    (search + facets)
- GET  /users/:id                (admin-view detail + recent audit log)
- POST /users/:id/ban             (manual ban, reason required)
- POST /users/:id/unban           (unban, reason required)
- PUT  /users/:id/role            (promote / demote, reason required)
- GET  /audit-log                 (paginated, filterable)

All gated by authorize('admin'). Self-actions are rejected
(ban-self → 403, demote-self → 403).

User search uses case-insensitive substring regex against email +
name + username with regex-special-char escape. Faceted filters:
banned=true, adminsOnly=true. Pagination: page + limit (max 50).

Ban / unban / role-change delegate to banService (B2) so the
side-effect implementation stays in one place. The audit log is
populated with moderator + target user references so the Flutter
side can render names without secondary lookups.

Legacy PUT /auth/make-admin/:userId is left in place this wave —
deprecation + removal is a separate task. The new PUT /admin/users/:id/role
supersedes it (takes role + reason, supports demote)."
```

---

## Task B5: Refactor `resolveReport` to delegate to banService

**Files:**
- Modify: `controllers/report.js`

- [ ] **Step 1: Replace the inline ban logic in resolveReport with banService call.**

Find the `if (action === 'user_banned') { ... }` block (currently lines ~241-283). Replace the entire ban side-effect block with:

```js
if (action === 'user_banned') {
  const banService = require('../services/banService');
  await banService.banUser({
    userId: report.reportedUser,
    reason: notes || `Banned following report ${report._id}`,
    moderatorId: req.user.id,
    source: `report:${report._id}`,
    io: req.app.get('io'),
  });
}
```

Note: this replaces the inline `User.findByIdAndUpdate(isBanned: true, ...)`, the for-loop ending voice rooms, the fcmTokens clear, and the sendBanNotification call — all of those now live in `banService.banUser`. The behavior is identical; the implementation is moved.

Move the `require('../services/banService')` to the top of the file alongside other requires (preferred to in-block require, but in-block is acceptable since this is the only call site in report.js).

- [ ] **Step 2: Verify.**

```bash
node -c controllers/report.js
```

Run a manual smoke if possible — call `resolveReport` against a test report with action='user_banned' and confirm the target user shows isBanned: true. Skip if no test fixture; rely on G1.

- [ ] **Step 3: Commit.**

```bash
git add controllers/report.js
git commit -m "refactor(admin): delegate resolveReport user_banned to banService

Same behavior, single implementation. The Step 14 inline ban flow
(set isBanned + end voice rooms + clear fcmTokens + sendBanNotification)
is now in services/banService.js#banUser; resolveReport just calls it
with source='report:<reportId>' so the audit log records which report
triggered the ban.

Eliminates the drift risk between the report-driven ban path and
the new manual ban endpoint (B4). Any future ban entry point (e.g.
auto-ban on N reports) must also call banService.banUser — that's
now the single source of truth.

Audit log entry is written by banService, replacing the previous
logSecurityEvent('REPORT_RESOLVED') for the ban case. (The
report.status='resolved' transition still fires logSecurityEvent
for non-ban resolutions.)"
```

---

## Task B6: Sanity check — server boot + endpoint smoke

**Files:** none

- [ ] **Step 1: Start the dev server locally.**

```bash
npm run dev
```

Watch for any startup errors. Expected: no errors, server listens on the configured port.

- [ ] **Step 2: Quick curl smoke against the new endpoints.**

```bash
TOKEN_ADMIN="<your admin token>"

# Search — empty query, banned facet
curl -s -H "Authorization: Bearer $TOKEN_ADMIN" \
  "http://localhost:5000/api/v1/admin/users?banned=true&limit=5" | jq '.pagination'

# Audit log — should return empty array on fresh DB
curl -s -H "Authorization: Bearer $TOKEN_ADMIN" \
  "http://localhost:5000/api/v1/admin/audit-log?limit=5" | jq '.data | length'

# Self-ban rejection
curl -s -X POST -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/admin/users/<your_own_id>/ban \
  -d '{"reason":"test self"}' | jq '.error'
# Expected: "You cannot ban yourself"

# Reason-required check
curl -s -X POST -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/admin/users/<some_other_id>/ban \
  -d '{}' | jq '.error'
# Expected: "Reason is required"
```

If any of these fail, fix before proceeding to Flutter tasks. This is the backend-only sanity gate.

- [ ] **Step 3: No commit (verification only).**

---

## Task F1: AdminService (Flutter provider) + admin user model fields

**Files:**
- Create: `lib/providers/provider_root/admin_provider.dart`
- Modify: `lib/providers/provider_models/community_model.dart` (if richer admin fields beyond Step 14 are needed in search results)

Working dir: `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`

- [ ] **Step 1: Create the service.**

Mirror the structure of `lib/providers/provider_root/report_provider.dart` — class with static-ish methods, manual header construction, calls through `http` directly (matches existing convention in that file).

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class AdminService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> searchUsers({
    String? q,
    bool bannedOnly = false,
    bool adminsOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (bannedOnly) params['banned'] = 'true';
      if (adminsOnly) params['adminsOnly'] = 'true';

      final uri = Uri.parse('${Endpoints.baseURL}admin/users')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
          'pagination': body['pagination'],
        };
      }
      return {'success': false, 'error': body['error'] ?? 'Failed to search'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId'),
        headers: headers,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error'] ?? 'Failed to load user'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> banUser(String userId, String reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId/ban'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'error': body['error'] ?? 'Ban failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> unbanUser(String userId, String reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId/unban'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'error': body['error'] ?? 'Unban failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> changeRole(
    String userId,
    String role,
    String reason,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId/role'),
        headers: headers,
        body: json.encode({'role': role, 'reason': reason}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error'] ?? 'Role change failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getAuditLog({
    String? moderatorId,
    String? targetId,
    String? action,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (moderatorId != null) params['moderatorId'] = moderatorId;
      if (targetId != null) params['targetId'] = targetId;
      if (action != null) params['action'] = action;

      final uri = Uri.parse('${Endpoints.baseURL}admin/audit-log')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
          'pagination': body['pagination'],
        };
      }
      return {'success': false, 'error': body['error'] ?? 'Failed to load log'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
```

- [ ] **Step 2: Verify.**

```bash
flutter analyze lib/providers/provider_root/admin_provider.dart 2>&1 | tail -3
```

- [ ] **Step 3: Commit.**

```bash
git add lib/providers/provider_root/admin_provider.dart
git commit -m "feat(admin): AdminService — Flutter client for /api/v1/admin/*

Six methods mapping 1:1 to the backend admin endpoints (B4):
- searchUsers({ q, bannedOnly, adminsOnly, page, limit })
- getUser(id)
- banUser(id, reason)
- unbanUser(id, reason)
- changeRole(id, role, reason)
- getAuditLog({ moderatorId, targetId, action, page, limit })

Follows the same pattern as ReportService in
lib/providers/provider_root/report_provider.dart — manual http.*
calls with header construction, returns Map<String, dynamic> with
'success' + 'data' / 'error' shape. Token is pulled from
SharedPreferences each call (matches existing convention)."
```

---

## Task F2: AdminHomeScreen + entry point consolidation

**Files:**
- Create: `lib/pages/admin/admin_home_screen.dart`
- Modify: `lib/pages/profile/profile_main.dart`
- Modify: `lib/pages/profile/drawer/profile_drawer.dart`

- [ ] **Step 1: Create AdminHomeScreen — 2-column grid of admin tools.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/pages/reports/admin_reports_screen.dart';
import 'package:bananatalk_app/pages/admin/admin_users_screen.dart';
import 'package:bananatalk_app/pages/admin/admin_audit_log_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(userProvider).valueOrNull;
      if (user?.isAdmin != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _NotAuthorizedScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: Padding(
        padding: Spacing.paddingLG,
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: Spacing.md,
          crossAxisSpacing: Spacing.md,
          children: [
            _AdminTile(
              icon: Icons.flag_outlined,
              label: 'Reports',
              color: AppColors.error,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.people_outline,
              label: 'Users',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.history_outlined,
              label: 'Audit Log',
              color: const Color(0xFF607D8B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAuditLogScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AdminTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotAuthorizedScreen extends StatelessWidget {
  const _NotAuthorizedScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text("This page isn't available."),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update `profile_main.dart`.**

Find the existing `_buildAdminReportsEntry` and the `if (user.isAdmin)` block in the body. Rename / re-target:
- Import `AdminHomeScreen` instead of `AdminReportsScreen` at the top.
- Rename `_buildAdminReportsEntry` to `_buildAdminToolsEntry`.
- Inside the button, change the destination from `AdminReportsScreen` to `AdminHomeScreen`.
- Change the label text from "Admin · Reports" to "Admin Tools".
- Change the icon to `Icons.admin_panel_settings_outlined` (already there) — no change needed there.

Update the call site inside the build method from `_buildAdminReportsEntry(context)` to `_buildAdminToolsEntry(context)`.

- [ ] **Step 3: Update `profile_drawer.dart`.**

Find the admin entry and change the destination from `AdminReportsScreen()` to `AdminHomeScreen()`. Update the subtitle from "Manage all reports (Admin)" to "Reports, users, audit log".

- [ ] **Step 4: Verify.**

```bash
flutter analyze lib/pages/admin/ lib/pages/profile/profile_main.dart lib/pages/profile/drawer/profile_drawer.dart 2>&1 | tail -5
```

- [ ] **Step 5: Commit.**

```bash
git add lib/pages/admin/admin_home_screen.dart lib/pages/profile/profile_main.dart lib/pages/profile/drawer/profile_drawer.dart
git commit -m "feat(admin): AdminHomeScreen + consolidate admin entry points

New AdminHomeScreen renders a 2-column grid of admin tools (Reports,
Users, Audit Log). The grid is the new admin landing surface,
replacing the previous direct-to-reports entry on both the profile
menu and the profile drawer.

profile_main: _buildAdminReportsEntry renamed to _buildAdminToolsEntry,
target changed from AdminReportsScreen to AdminHomeScreen, copy
updated from 'Admin · Reports' to 'Admin Tools'.

profile_drawer: admin entry retargeted similarly; subtitle copy
updated to reflect the broader tool surface.

AdminHomeScreen has its own role gate via postFrameCallback —
defense-in-depth even though the parent entry already checked
user.isAdmin. The placeholder Users + Audit tiles route to
screens added in F3 and F4."
```

---

## Task F3: AdminUsersScreen — search + facets + list + detail

**Files:**
- Create: `lib/pages/admin/admin_users_screen.dart`
- Create: `lib/pages/admin/admin_user_detail_screen.dart`

- [ ] **Step 1: Create AdminUsersScreen.**

A ConsumerStatefulWidget with:
- A search TextField at the top (debounce ~300ms before firing search)
- A horizontal ChoiceChip row: "All" / "Banned only" / "Admins only" (mutually exclusive)
- ListView.builder of user cards. Each card shows avatar + name + email + banned/admin pills + tap-to-detail
- Pagination via "Load more" button at the bottom OR scroll-to-bottom trigger
- Empty state ("No users found.")
- Error state with retry

State fields:
```dart
final _searchController = TextEditingController();
String _query = '';
String _facet = 'all'; // 'all' | 'banned' | 'admins'
List<dynamic> _users = [];
bool _isLoading = false;
bool _hasMore = false;
int _page = 1;
Timer? _debounce;
```

Tap on a row → push `AdminUserDetailScreen(userId: user['_id'])`. After returning, refresh the list (in case the user was banned/unbanned).

Implementation follows the AdminReportsScreen state pattern closely — share filter dialog conventions, ScaffoldMessenger snackbar for errors, RefreshIndicator on the list.

(Full code body ~250 lines. The agent executor can implement following the AdminReportsScreen structure; the key shape is above.)

- [ ] **Step 2: Create AdminUserDetailScreen.**

A ConsumerStatefulWidget that:
- Loads `adminService.getUser(userId)` in initState
- Renders a rich user card: avatar (CircleAvatar with initial fallback) + name + email + role pill + isBanned pill + userMode (VIP / regular / visitor) + language pair + location + joined date + last active
- Below the card, a list of action buttons:
  - "Ban user" (red, disabled if already banned) → confirmation dialog with required reason TextField
  - "Unban user" (green, disabled if not banned) → confirmation dialog with required reason
  - "Promote to admin" (only when role === 'user') → confirmation dialog with reason
  - "Revoke admin role" (only when role === 'admin' && id !== current admin's id) → confirmation dialog with reason
- Below the actions, the recent audit log entries (last 20) targeting this user, populated from `recentActions` field in the getUser response

Confirmation dialog pattern: AlertDialog with title, TextField for reason, Cancel / Confirm buttons. Confirm button disabled until reason TextField has non-whitespace content. On confirm: call `adminService.banUser` / `unbanUser` / `changeRole`, show ScaffoldMessenger snackbar with result, refresh the user data, fire `analytics.adminActionTaken(action, userId)`.

(Full code body ~300 lines. Follow the same structure as the Step 14 enriched user card.)

- [ ] **Step 3: Verify.**

```bash
flutter analyze lib/pages/admin/admin_users_screen.dart lib/pages/admin/admin_user_detail_screen.dart 2>&1 | tail -5
```

- [ ] **Step 4: Commit.**

```bash
git add lib/pages/admin/admin_users_screen.dart lib/pages/admin/admin_user_detail_screen.dart
git commit -m "feat(admin): AdminUsersScreen + AdminUserDetailScreen

AdminUsersScreen: search TextField (300ms debounce) + facet chips
(All / Banned / Admins) + paginated user list. Each row renders
avatar + name + email + isBanned/admin pills. Tap → AdminUserDetailScreen.

AdminUserDetailScreen: rich user card + action buttons (ban / unban /
promote / demote, each with a required-reason confirmation dialog) +
recent audit log entries targeting this user (last 20).

Self-ban / self-demote are visually disabled — defense-in-depth
matching the server-side rejection (controllers/admin.js).

All destructive actions write to the audit log server-side and
fire analytics adminActionTaken event (added in F4)."
```

---

## Task F4: AdminAuditLogScreen + analytics event

**Files:**
- Create: `lib/pages/admin/admin_audit_log_screen.dart`
- Modify: `lib/services/analytics_service.dart`

- [ ] **Step 1: Add the analytics event.**

In `lib/services/analytics_service.dart`, APPEND a new method after the existing events:

```dart
/// Step 15: fired when an admin takes a destructive action.
/// Helps spot unusual admin activity in Firebase Analytics.
Future<void> adminActionTaken({
  required String action,
  required String targetUserId,
}) async {
  try {
    await _analytics.logEvent(
      name: 'admin_action_taken',
      parameters: {
        'action': action,
        'target_user_id': targetUserId,
      },
    );
  } catch (e) {
    debugPrint('[analytics] adminActionTaken failed: $e');
  }
}
```

- [ ] **Step 2: Create AdminAuditLogScreen.**

A ConsumerStatefulWidget paginated list of audit log entries:
- AppBar with title "Audit Log"
- Optional filter chips at top: "All actions" / "Bans" / "Unbans" / "Role changes" (mutually exclusive)
- ListView.builder, each entry:
  - Action icon (red for ban, green for unban, blue for role change, gray for other)
  - Moderator name + "→" + target name
  - Reason (italic, muted)
  - Timestamp (relative — "2 hours ago" via package:timeago)
  - Source pill if non-null ("manual" or "report:abc123")
- Load more button at the bottom
- Empty state ("No audit log entries match the filter.")

Tap on an entry → bottom sheet with full details (raw JSON of `details` field, moderator + target full info).

(Full code body ~250 lines. Use existing timeago package already in pubspec.)

- [ ] **Step 3: Verify.**

```bash
flutter analyze lib/pages/admin/admin_audit_log_screen.dart lib/services/analytics_service.dart 2>&1 | tail -5
```

- [ ] **Step 4: Commit.**

```bash
git add lib/pages/admin/admin_audit_log_screen.dart lib/services/analytics_service.dart
git commit -m "feat(admin): AdminAuditLogScreen + adminActionTaken analytics

AdminAuditLogScreen: paginated history of moderator actions, filterable
by action type (All / Bans / Unbans / Role changes). Each entry shows
moderator + target + reason + source (manual / report:<id>) +
relative timestamp via timeago.

Bottom-sheet detail view exposes the raw details payload for entries
that carry action-specific metadata (e.g. activeRoomsEnded count).

AnalyticsService gains adminActionTaken({ action, targetUserId })
fired from AdminUserDetailScreen on every destructive action. Lets
the project owner spot unusual admin activity in Firebase Analytics."
```

---

## Task G1: Glue — smoke test + push

**Files:** none

- [ ] **Step 1: Backend smoke (curl + Mongo verification).**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
npm run dev &

TOKEN_ADMIN="<admin token>"
TARGET_USER_ID="<test target>"
SELF_USER_ID="<admin's own id>"

# Manual ban — reason required
curl -s -X POST -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/admin/users/$TARGET_USER_ID/ban \
  -d '{"reason":"Smoke test — manual ban"}' | jq

# Verify in DB: target user.isBanned === true, banReason set, bannedAt set
# Verify audit log has one entry with action='user_banned', source='manual'
# Verify ban notification email sent to target

# Self-ban — reject
curl -s -X POST -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/admin/users/$SELF_USER_ID/ban \
  -d '{"reason":"test"}' | jq '.error'
# Expected: "You cannot ban yourself"

# Unban
curl -s -X POST -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/admin/users/$TARGET_USER_ID/unban \
  -d '{"reason":"Smoke test — restored"}' | jq

# Verify isBanned false; audit log has matching unban entry; unban email sent.

# Search — banned-only
curl -s -H "Authorization: Bearer $TOKEN_ADMIN" \
  "http://localhost:5000/api/v1/admin/users?banned=true&limit=10" | jq '.pagination'

# Audit log — last 5
curl -s -H "Authorization: Bearer $TOKEN_ADMIN" \
  "http://localhost:5000/api/v1/admin/audit-log?limit=5" | jq '.data | length'

# Role change — promote
curl -s -X PUT -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/admin/users/$TARGET_USER_ID/role \
  -d '{"role":"admin","reason":"Promoting for help"}' | jq

# Self-demote — reject
curl -s -X PUT -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/admin/users/$SELF_USER_ID/role \
  -d '{"role":"user","reason":"test"}' | jq '.error'
# Expected: "You cannot revoke your own admin role"

# Resolve a report with user_banned — should still work via the refactored path
curl -s -X PUT -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/reports/<REPORT_ID>/resolve \
  -d '{"action":"user_banned","notes":"Smoke test — report-driven ban"}' | jq
# Verify the audit log entry has source='report:<reportId>' (not 'manual').
```

- [ ] **Step 2: Flutter device smoke (iOS physical + Android physical).**

1. **Admin Tools entry:** Log in as admin → Profile → confirm "Admin Tools" row appears. Tap → AdminHomeScreen loads with 3 tiles. Reports / Users / Audit Log all reachable.
2. **User search:** AdminHome → Users → type partial email → results filter. Tap a chip → list filters by facet.
3. **Manual ban:** Tap a user → AdminUserDetailScreen → Ban → empty reason → Confirm disabled. Enter reason → Confirm. Confirm snackbar, list refreshes, target user banned in DB.
4. **Unban:** From the banned user's detail screen → Unban → reason → confirm. Target user `isBanned: false`.
5. **Promote / demote:** Same flow with role-change actions. Self-demote button is disabled (or absent) on own profile.
6. **Audit log:** AdminHome → Audit Log → confirm recent actions appear sorted newest-first. Filter chip narrows to action type.
7. **Banned user UX (carry from Step 14 G1):** Take a user, ban them via the new manual flow, confirm they see AccountSuspendedScreen on their device next time they try to use the app.
8. **Stale role gate:** Log in as admin, open AdminUsersScreen, have another admin demote you via the API. Try to act — backend 403s. Acceptable v1 UX.

- [ ] **Step 3: Push both branches.**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git push -u origin feat/step15-admin-tools

cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze 2>&1 | grep -E "error •" && echo "ERRORS — fix before merge" || echo "no errors"
git push -u origin feat/step15-admin-tools
```

- [ ] **Step 4: Surface to user for review.**

Report:
- Backend commit hash + push confirmation
- Flutter commit hash + push confirmation
- Smoke test results (which ones passed, any open issues)
- Any uncertain decisions encountered during execution

Wait for the user to merge.

---

## Cadence guidance

- **B1 lands first** — AdminAuditLog model is foundational for B2 (banService writes to it).
- **B2 follows** — banService depends on B1 + B3 (sendUnbanNotification).
- **B3 is independent of B1 / B2** — can be authored in parallel; just need it merged before B2 calls into it.
- **B4 depends on B2** — controllers/admin.js calls banService.
- **B5 follows B4** — `resolveReport` refactor needs banService in place to delegate to.
- **B6 is the local sanity check** after all backend tasks land.
- **F1 depends on B4 being deployable** (Flutter calls the new endpoints).
- **F2-F4 can be authored in parallel** after F1.
- **G1 is the manual smoke + merge gate.**

## Risk + rollback

- **Highest risk: B5 `resolveReport` refactor.** Behavior change is supposed to be zero, but the inline → service call swap is non-trivial. If the refactor has a subtle bug, the report-driven ban flow could regress (and the regression wouldn't surface in code review — only in smoke). Rollback: revert B5 alone; `resolveReport` returns to inline ban logic and B4's manual ban still works on its own.
- **Mid-risk: B2 banService.** If the service has a bug, BOTH ban entry points break. Rollback: revert B2 + B5; manual ban endpoint goes away, report-driven ban returns to Step 14 behavior.
- **Mid-risk: B4 admin route mount.** A typo in `server.js` could fail to mount the new route. Rollback: revert just `server.js`; admin endpoints become 404 but don't break anything else.
- **Low risk: B1 AdminAuditLog model.** Pure addition. Rollback: revert; audit log entries don't get written but actions still complete.
- **Low risk: B3 email helper.** APPEND pattern matches Step 14 — no risk to existing email exports. Rollback: revert; unban emails don't fire.
- **Low risk: F1-F4 Flutter.** Pure additive screens. Worst case: a screen has a layout bug; the admin can hot-fix or revert.

**Emergency disable:** No env-flag kill switch for this wave. If admin actions misbehave, the underlying ban primitive is still `User.isBanned: false` via Mongo shell — same recovery path as Step 14.

**No DB migrations.** AdminAuditLog is a new collection (empty until first write); no backfill.

---

## Appendix A — what's NOT in this wave

Restated to make the boundary clear during execution:

- ❌ Voice room live moderation (force-end any room)
- ❌ Proactive content browse + bulk remove (moments / stories quick-remove)
- ❌ Admin dashboard with live counters (pending reports, banned users, new signups, active VIPs)
- ❌ Bulk admin actions (multi-select ban / unban)
- ❌ Super-admin role tier
- ❌ Unban-self / appeals flow
- ❌ Audit log CSV / JSON export
- ❌ Search-by-IP
- ❌ Username / email change history
- ❌ Deprecation / removal of legacy `PUT /auth/make-admin/:userId`

If during execution you discover something that wants to expand scope, write it to `docs/manual-todos.md` Queued engineering and continue. Do NOT expand the plan.

---

## Appendix B — verification queries (post-merge)

After Step 15 ships, the following Mongo queries are useful for routine admin operations:

```js
// All bans in the last 30 days, grouped by moderator
db.adminauditlogs.aggregate([
  { $match: { action: 'user_banned', timestamp: { $gte: new Date(Date.now() - 30*24*60*60*1000) } } },
  { $group: { _id: '$moderator', count: { $sum: 1 } } },
  { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'mod' } }
])

// Actions taken against a specific user
db.adminauditlogs.find({ target: ObjectId("...") }).sort({ timestamp: -1 })

// Currently banned users
db.users.find({ isBanned: true }, { name: 1, email: 1, bannedAt: 1, banReason: 1 }).sort({ bannedAt: -1 })

// Count current admins
db.users.countDocuments({ role: 'admin' })
```

These are reference queries, not part of the implementation. Documented here so the executor knows the canonical "did Step 15 work?" verifications.
