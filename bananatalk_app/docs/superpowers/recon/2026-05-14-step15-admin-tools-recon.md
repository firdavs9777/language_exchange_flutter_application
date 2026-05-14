# Step 15 — Admin Tools — Recon

Read-only reconnaissance for a planned Step 15 Admin Tools wave. No fixes proposed; just what exists today, what's missing, and the design choices the plan will face.

Goal of the wave: close the post-Step-14 gap where admins have no UI for **(a) reversing a ban**, **(b) banning a user without a report**, **(c) looking up an arbitrary user by email/name**, and **(d) reviewing what moderator actions have already happened**. Everything beyond those four columns is out of scope here.

---

## Cross-cutting findings

### CC-1. Admin endpoints today are scattered, not centralized.

There is **no dedicated admin route file** today. Admin-gated endpoints are sprinkled across existing route files:

- `routes/auth.js` — `PUT /make-admin/:userId` (promotes user to admin)
- `routes/users.js:155` — `PUT /:userId/mode` (changes `userMode` between visitor/regular/vip)
- `routes/report.js:31-39` — all the report mod endpoints (9 of them)
- `routes/lessonBuilder.js` — 5 admin endpoints for AI lesson content
- `routes/community.js` — `POST /topics/seed`

The plan needs to decide: introduce a new `routes/admin.js` for the new user management + audit log surface, or thread these onto `routes/users.js` (which already has the admin-only `PUT /:userId/mode` precedent).

### CC-2. SecurityLog exists, with a 90-day TTL.

`utils/securityLogger.js` writes to a SecurityLog Mongoose model. Event types already in use:
- `REPORT_REVIEW_STARTED`, `REPORT_RESOLVED`, `REPORT_DISMISSED` — moderator actions
- `CONTENT_REPORTED` — user actions
- `LOGIN_SUCCESS`, `LOGIN_FAILED`, `UNAUTHORIZED_ADMIN_ACCESS`, `BRUTE_FORCE_DETECTED` — auth
- `PASSWORD_CHANGED`, `EMAIL_VERIFIED`, `ACCOUNT_CREATED`, `ACCOUNT_DELETED` — account lifecycle
- Apple/Google webhook events

Schema (lines 10-45) has: `event`, `severity` (info|warning|critical), `userId`, `email`, `ip`, `userAgent`, `details` (Mixed), `timestamp`. TTL index at line 38 sets `expireAfterSeconds: 90 * 24 * 60 * 60`.

**Implication:** SecurityLog is *almost* an audit log but auto-purges after 90 days. For mod accountability ("did I ban this user three years ago, and why?") that's too short. The plan needs to decide whether the audit log is a separate durable model or a fork of SecurityLog without the TTL.

### CC-3. The Step 14 `resolveReport user_banned` flow is the canonical ban primitive.

`controllers/report.js:241-308` already implements the full ban sequence:

```js
if (action === 'user_banned') {
  await User.findByIdAndUpdate(report.reportedUser, {
    isBanned: true,
    banReason: notes || `Banned following report ${report._id}`,
    bannedAt: new Date()
  });
  // 1. End the user's active voice rooms (room.end + livekitAdmin.endRoom + 2 socket emits)
  // 2. Clear FCM tokens
  // 3. Send ban notification email via emailService.sendBanNotification
}
```

A manual-ban endpoint must mirror this. The right shape is probably a shared helper (`services/banService.js#banUser(userId, reason, moderatorId)`) so both `resolveReport` and the new manual endpoint converge on one implementation. **Risk if duplicated:** Step 15 ban flow drifts from Step 14 ban flow, leaving subtle behavioral differences (e.g. one clears FCM, one doesn't).

### CC-4. There is no inverse — no `unbanUser` primitive anywhere.

Once a user is banned, the only path back is `db.users.updateOne({...}, { $set: { isBanned: false, banReason: null, bannedAt: null } })` in Mongo shell. Every ban via the UI today is, in practice, irreversible without DB access. This is the single highest-leverage fix.

### CC-5. No `sendUnbanNotification` email helper exists.

`services/emailService.js` has the three Step 14 helpers (`sendAdminReportAlert`, `sendReportResolutionToReporter`, `sendBanNotification`). No unban counterpart. The plan needs to either add one (so users learn their account is restored) or leave silent (they discover it next time they try to log in). Adding it is the right move; silence will lead to support pings.

### CC-6. Two admin UI entry points exist today, both pointing to AdminReportsScreen.

- `lib/pages/profile/profile_main.dart` — `_buildAdminReportsEntry` (TextButton style, near logout)
- `lib/pages/profile/drawer/profile_drawer.dart` — admin entry with "Manage all reports (Admin)" subtitle + admin badge

When new admin screens (Users, Audit Log) ship, the plan needs to decide: **add each as its own row** (3 entries: Reports, Users, Audit), **consolidate into a single "Admin" entry** that opens an AdminHomeScreen with a grid of tools, or **bottom-tab style admin section** inside a single screen. The two-entry-points-for-one-screen pattern doesn't scale.

### CC-7. ReportService lives in `lib/providers/provider_root/report_provider.dart`, not `lib/services/`.

There's a legacy `lib/services/report_service.dart` (different class with overlapping name). The active one — the one `admin_reports_screen.dart` imports — is at `lib/providers/provider_root/report_provider.dart:7`. Plan must follow this convention for any new admin service (probably `lib/providers/provider_root/admin_service.dart` or extend the existing report_provider with admin methods if scope is small).

### CC-8. `make-admin/:userId` exists but is one-directional.

`PUT /api/v1/auth/make-admin/:userId` (in `routes/auth.js`) promotes to admin. There is no inverse (`make-user`, `revoke-admin`). For the Step 15 user management screen to support demotion, either we extend the existing endpoint to take a `role` body or add a separate `revoke-admin`.

---

## Per-issue findings

### Issue A. No unban UI (highest priority)

**What exists:**
- `User.isBanned: Boolean` schema field, `User.banReason: String`, `User.bannedAt: Date` (Step 14 B1)
- `protect` + `optionalAuth` middleware reject `isBanned === true` users (Step 14 B1)
- `resolveReport user_banned` sets these fields (Step 14 B5)

**What's missing:**
- No endpoint to set `isBanned: false`
- No UI surface in any admin screen
- No unban notification email
- No audit trail of unban actions

**Code consequence:** A moderator who clicks the wrong `user_banned` in the reports screen has no recourse from the app. The only path is for the user (or someone) to email the project owner, who then uses Mongo shell. For a one-person mod team this is fragile.

### Issue B. No manual ban (without a report)

**What exists:**
- Only the resolveReport flow can ban (`controllers/report.js#resolveReport`)
- This requires a Report record to exist

**What's missing:**
- No way to ban a user discovered through any other channel (DM abuse a moderator witnesses, an obviously fake account spotted in user search, off-platform escalation)
- No way to ban without writing a report against the user first

**Note:** A workaround exists today: create a synthetic Report manually via the API, then resolve it with `user_banned`. This is awkward and pollutes the report log.

### Issue C. No user search by email / id

**What exists in `controllers/users.js`:**
- `GET /api/v1/users` — list users (paginated, sorted by VIP+online+lastActive). Not admin-gated. (Line 52)
- `GET /api/v1/users/search/username` — search by username substring. Not admin-gated. (Line 65)
- `GET /api/v1/users/username/:username` — exact username lookup. (Line 68)
- `GET /api/v1/users/:id` — by ID. (Line 172)

**What's missing:**
- No search by email (an admin pasting a support ticket reporter's email has no lookup path)
- No admin-only search that returns the richer fields (`isBanned`, `role`, `bannedAt`, `banReason`, full `lastActive`)
- No way to filter the list by `role === 'admin'`, `isBanned === true`, or `userMode === 'vip'` for moderator inspection

### Issue D. No audit log surface

**What exists:**
- SecurityLog (90-day TTL, `utils/securityLogger.js`)
- `logSecurityEvent('REPORT_RESOLVED', { reportId, moderatorId, action, reportedUser })` is called on every report resolution
- No corresponding log for `make-admin`, `changeUserMode`, `content_removed` (in resolveReport, content_removed action doesn't log distinctly — it's bundled into REPORT_RESOLVED)

**What's missing:**
- A persistent (no-TTL) record of moderator actions specifically (separate from general security events)
- A UI surface to view that record (who did what, when, to whom, with what notes)
- A way to filter by moderator, action type, target user, date range

**Implication:** Mod accountability is invisible. There's no answer to "what did I do last week as admin?"

---

## Edge cases the plan must address

- **Self-promotion / self-demotion.** What happens if an admin tries to revoke their own admin role? Lock them out of admin tools mid-session. Decision: reject in the controller (`req.user.id === req.params.userId && action === 'revoke-admin'` → 403).
- **Banning an admin.** Two cases: (a) admin bans themselves — same lock-out issue; reject. (b) admin A bans admin B — should this require a higher privilege than regular ban? For v1, treat admin role and ban status as orthogonal: banning an admin sets `isBanned: true` but leaves `role: 'admin'`. They simply can't log in. Cleaner than role-gated ban authorization.
- **Banning the user_banned-from-report flow vs manual ban convergence.** Both must end voice rooms, clear FCM, and send notification. Diverging implementations is a bug magnet.
- **Unban after a user account was deleted between ban and unban.** Treat as no-op + 404 ("user not found"). Don't try to resurrect.
- **Audit log race condition.** Two admins resolve overlapping reports against the same user simultaneously. Audit log must be append-only — log both actions, don't try to dedupe.
- **Unban email when user already has fcmTokens cleared.** Email is the only channel left, which is fine. But the Flutter side won't know the user is unbanned until they next log in. v1: accept that login is the trigger; don't try to push state.
- **User search returns banned users.** Search must include `isBanned: true` users so admins can find them to unban. Default-filtering them out would defeat the purpose.
- **Audit log retention vs storage.** A year of mod actions for ~1K active users is small (~hundreds of events tops). Probably no TTL needed in v1.
- **Manual ban with no `notes`.** The Step 14 ban flow accepts an empty `notes` and writes a generic reason. New manual ban should require a non-empty reason — manual bans should always be explainable.
- **Demoting an admin who is currently using AdminReportsScreen.** Their `userProvider` is cached client-side until next fetch. The role gate fires only on initial route — they keep the screen until they navigate away. Server `authorize('admin')` blocks every API call, so they can't act, just view stale UI. Acceptable v1.

---

## Three-option design choices

### D-1. Audit log storage

| Option | Pros | Cons |
|---|---|---|
| **A. New `AdminAuditLog` Mongoose model** | Clean schema, durable (no TTL), independent indexes (moderator, target, action, date). | One more model + collection. ~3 lines of code to query a "what did X do" report. |
| **B. Reuse `SecurityLog` with a `MODERATOR_ACTION` event type** | Zero new models. Existing query interface. | 90-day TTL purges history. Could add `expireAfterSeconds: 0` conditional but mongo doesn't support partial TTL natively. |
| **C. Embed action array on each `User` doc** | Per-user audit visible directly. | Bloats user docs over time. Hard to query "all actions by moderator X." Hard to query date range. |

**Recommendation tilt: A.** The 365-day-plus retention need is real; SecurityLog's TTL is a hard wall. New model is ~50 lines + 2 indexes.

### D-2. New admin route file vs scatter

| Option | Pros | Cons |
|---|---|---|
| **A. New `routes/admin.js`** with all Step 15 endpoints | Conceptually clean. Easy to find "what admin endpoints exist." | Slight inconsistency with the existing scatter; needs a new entry in `server.js`. |
| **B. Extend existing files** (`users.js`, `report.js`) | Matches existing convention. | "Admin surface" becomes harder to enumerate; future admin endpoints have no canonical home. |
| **C. Hybrid — user management on `users.js`, audit log on new file** | Localizes user-management with related code. | Inconsistent; the boundary becomes arbitrary. |

**Recommendation tilt: A.** The scatter is itself a problem. Step 15 is the right time to introduce a dedicated admin file before the surface grows.

### D-3. User search input shape

| Option | Pros | Cons |
|---|---|---|
| **A. Single search box (email OR username OR partial name)** | Lowest friction; one box does everything. | Heuristic disambiguation server-side; ambiguous results for short queries. |
| **B. Three separate fields (email / username / name)** | Explicit; deterministic per-field. | Cluttered UI; admins know which field they have. |
| **C. Single search box + faceted filters (admin only, banned only, VIP only)** | Powerful; covers "show me all banned users" use case. | More UI surface; more state in the screen. |

**Recommendation tilt: A + simple faceted toggles (isBanned only, admins only).** Most admin lookups are "I have an email or a name fragment, find this person." Faceted "all banned users" is a real use case too — adds a row of filter chips on top of the search.

### D-4. Manual ban flow

| Option | Pros | Cons |
|---|---|---|
| **A. New endpoint `POST /admin/users/:id/ban` taking `{ reason }`** | Clean separation from reports. | Logic must mirror `resolveReport user_banned` exactly. |
| **B. Auto-create a synthetic Report, then resolve it** | Reuses existing flow. | Pollutes report log; awkward record structure; reportedBy = admin themselves. |
| **C. Extract `banUser(userId, reason, moderator)` helper, call from both** | Single source of truth for the ban side-effects. | Slight refactor of Step 14 `resolveReport` to delegate to the helper. |

**Recommendation tilt: C.** This is the safest pattern long-term: one function does the side-effects, two callers (resolveReport for the report-driven path, new endpoint for the manual path). Diff to Step 14 is ~30 lines but eliminates future drift.

### D-5. Admin entry points consolidation

| Option | Pros | Cons |
|---|---|---|
| **A. Add Users + Audit rows alongside existing Reports row in profile menu** (3 entries) | No design change; just additions. | Profile menu starts to feel admin-heavy for the (rare) admin user. |
| **B. Single "Admin Tools" entry → AdminHomeScreen with grid** | Cleaner profile menu; room to grow. | One more screen; one more tap to reach any tool. |
| **C. Bottom tab bar variant exposed only for admins** | Powerful, native-feeling. | Big change to app shell; risky to add a top-level surface for one role. |

**Recommendation tilt: B.** Sustainable; the grid screen also gives breathing room to surface counters ("3 pending reports", "12 banned users") later without crowding the profile screen.

### D-6. Unban flow — confirmation depth

| Option | Pros | Cons |
|---|---|---|
| **A. Single tap → unban** | Fast; matches the ban single-tap UX. | Misclicks are real. |
| **B. Confirmation dialog with reason field** | Explicit; auditable. | Slower; reason for unbanning is often "mistake / appeal granted." |
| **C. Confirmation dialog without reason** | Compromise — confirms, doesn't gate. | Unban audit log entries lose context. |

**Recommendation tilt: B.** Unban is rare; one extra second is fine. The reason field will be useful in the audit log when reviewing "why was this user unbanned six months later?"

---

## Punted findings (out of scope; queue for future waves)

- **Voice room live moderation.** Admin force-end any active voice room. Today this is only doable by banning the host. Rare event; defer to a "live moderation" wave if it becomes a real need. Added to `docs/manual-todos.md` Queued engineering.
- **Proactive content browse + bulk remove.** Admin browses recent moments / stories with quick-remove. Larger build; separate "proactive moderation" wave. Queued.
- **Admin dashboard with live counters** (pending reports, banned users, new signups today, active VIPs). Daily admin email already covers most of these. If the AdminHome grid (D-5 option B) lands, counter chips can be added incrementally; no separate dashboard needed in v1.
- **Bulk admin actions** (multi-select ban, multi-select unban). v1 is one-at-a-time. Bulk creates its own audit-log granularity question.
- **Per-action role gating** (e.g. only "super admins" can promote others). v1 has a single admin role; super-admin tier is product complexity Step 15 doesn't need.
- **Unban-self appeal flow.** Banned users can't currently appeal in-app; they email `appeal@banatalk.com`. Self-service appeals are a separate trust/UX investment.
- **Audit log export** (CSV download for compliance / legal). Defer until the audit log has meaningful data.
- **Search-by-IP** for ban evasion detection. Requires IP retention policy decisions; punted.
- **Username/email change history.** If a moderator bans `bob@foo.com` and the user changes email to `bob2@foo.com`, the audit trail loses them. Out of scope.

---

## What this recon does NOT cover

- The Flutter side's exact widget tree for the new screens — that's plan territory.
- Specific endpoint paths and request/response shapes — also plan territory.
- Commit-level task decomposition — also plan territory.

The plan will turn the recommendations above (D-1 through D-6) into locked decisions, with the rejected alternatives spelled out per the Step 14 plan format.
