# Admin Console (Phase C) Implementation Plan

> **For agentic workers:** execute task-by-task with a fresh implementer per task and a review after each. Steps use `- [ ]`.

**Goal:** a web admin console at `/admin/*`, visible in the navbar only to admin users, covering everything the backend admin API already exposes plus two analytics reads over the reach data.

**Architecture:** one RTK Query slice (`adminSlice.ts`, `injectEndpoints` on `apiSlice`) with an endpoint per backend route and tag-based invalidation; a `RequireAdmin` route guard; an `AdminLayout` (left rail, content pane) built from `src/design` primitives and Tailwind; six pages under `src/components/admin/pages/`. Lazy-loaded as one chunk. All `/admin/*` routes are `noindex` (RouteMeta already does this for any path not in `SEO_PAGES`). No Bootstrap, no SCSS.

**Spec:** `docs/superpowers/specs/2026-09-22-reach-marketing-admin-design.md` §6 and §7.4–7.5.

## Global Constraints

- Frontend `/Users/davis/Desktop/Personal/language_exchange_web_front`, branch `feat/admin-console` off `main`. Backend `/Users/davis/Desktop/Personal/language_exchange_backend_application`, branch `feat/admin-analytics` off `main`. **No `Co-Authored-By` trailers on any commit.**
- Frontend tests: `CI=true npx react-scripts test --testPathPattern=<pattern>` (foreground; no `--forceExit`). Baseline 89 suites / 482 tests. TypeScript 3.7.2: no `import type`, no `export type {}`. Copy idiom `t("key") || "English"`; new keys under `admin.*` in all 18 locales via `scripts/i18n/merge-keys.js` (translate the 17); extend `localeParity.test.ts` NAMESPACES with `"admin"`.
- Backend tests: `nvm use 24` then `node --test test/<file>.test.js`; additive only.
- Render-time discipline still applies (no `window` reads during render) even though admin pages are never prerendered.
- The console offers exactly what the backend exposes; no new moderation actions.

## Backend contracts (verbatim from `routes/admin.js`, `controllers/admin.js`, `controllers/adminContent.js`)

All under `/api/v1/admin`, `protect` + `authorize('admin')`. Envelope `{ success, data, ... }`.

| Endpoint | Query / body | Response `data` |
|---|---|---|
| `GET /users` | `q`, `adminsOnly=true`, `page` (1), `limit` (20, max 50) | `User[]` (name, email, username, role, isBanned, createdAt, …); `pagination: { total, page, limit, hasMore }` |
| `GET /users/:id` | — | `{ user, recentActions[], activitySummary: { lastMessageAt, lastMomentAt, messages30d, moments30d } }` (read the controller for exact keys) |
| `POST /users/:id/ban` | body `{ reason }` (required) | `{ message: 'User banned' }` |
| `POST /users/:id/unban` | body `{ reason }` | `{ … }` |
| `PUT /users/:id/role` | body `{ role: 'admin'\|'user', reason }` | `{ previousRole, newRole, noop }`; 403 when revoking own admin |
| `GET /banned-users` | `page`, `limit`, `search` | `User[]` + `pagination` |
| `DELETE /users/:id` | body `{ reason? }` | `{ … }` hard delete |
| `GET /audit-log` | `moderatorId`, `targetId`, `action`, `page`, `limit` (50, max 100) | entries[] + `pagination` |
| `GET /stats` | — | `{ total, banned, admins, vip, newToday, newThisWeek, activeWeek, byGender[], byRole[], byMode[], topNativeLanguages[], topLearningLanguages[], generatedAt }` |
| `GET /activity` | `limit` (50) | `{ counts: { today, week, month, total }, recentlyActive[] }` |
| `GET /ai-usage` | `feature`, `from`, `to` | `{ total, byFeature, byDay }` |
| `GET /ai-usage/logs` | `feature`, `from`, `to`, `page`, `limit` | `[{ id, user: { id, name, email } \| null, feature, timestamp }]` + `pagination` |
| `GET /content/clubs` | `page`, `limit`, `reported=true` | `Club[]` with `openReports`; `count`, `total` |
| `GET /content/gatherings` | `page`, `limit`, `reported=true` | `Gathering[]` with `openReports`, `goingCount`; `count`, `total` |
| `POST /content/clubs/:id/archive` | body `{ archived = true, reason }` | `{ _id, status }` |
| `POST /content/gatherings/:id/cancel` | body `{ reason }` | `{ _id, status }` |
| **new** `GET /analytics/events` | `days` (30) | `{ byDay: [{ date, pageViews, storeTaps }], byPlacement: [{ placement, platform, taps }], topReferrers: [{ referrer, count }], topPaths: [{ path, views }] }` |
| **new** `GET /analytics/visits` | — | `WebVisit.getWeeklyStats()` output (`thisWeek`, `lastWeek`, `period`, `topCountries`, `deviceBreakdown`, `dailyBreakdown`, …) plus `newVisitorRatio` |

---

### Task 1 (backend): analytics aggregates for the Reach page

**Files:** create `controllers/adminAnalytics.js`, `test/adminAnalytics.test.js`; modify `routes/admin.js` (two `router.get` lines after `/ai-usage`).

- [ ] Test first (node:test + mongodb-memory-server, controller-level like `test/adminContent.test.js`): seed `WebEvent` docs across three days with `page_view` and `store_tap` (placements `hero`/`download-page`, platforms `ios`/`android`, referrers), call `getAnalyticsEvents({ query: { days: 7 } })` and assert `byDay` has one entry per day with correct counts, `byPlacement` groups by placement+platform, `topReferrers` and `topPaths` sorted desc; call `getAnalyticsVisits` with two `WebVisit` docs and assert `thisWeek.totalVisits === 2` and `newVisitorRatio` between 0 and 1 (0 when `totalVisits` is 0).
- [ ] Implement with `WebEvent.aggregate` (`$match createdAt >= now - days`, `$group` by `$dateToString('%Y-%m-%d')` / by `{placement, platform}` for `store_tap` / by referrer / by path for `page_view`), and `getAnalyticsVisits = async (req,res) => { const s = await WebVisit.getWeeklyStats(); res.json({ success: true, data: { ...s, newVisitorRatio: s.thisWeek.totalVisits ? s.thisWeek.newVisitors / s.thisWeek.totalVisits : 0 } }) }` (check the exact `newVisitors` key name in `models/WebVisit.js`).
- [ ] Wire routes; run the test and `npm test | tail -14`; commit `feat(admin): analytics aggregates for the web admin console (events by day/placement/referrer/path, weekly visits)`.

### Task 2 (frontend): admin slice, guard, routes, navbar entry

**Files:** create `src/store/slices/adminSlice.ts`, `src/components/admin/RequireAdmin.tsx`, `src/components/admin/AdminLayout.tsx`, `src/components/admin/pages/AdminOverview.tsx` (placeholder heading only, filled in Task 3); modify `src/store/slices/apiSlice.ts` (tagTypes + `AdminUser`, `AdminUserList`, `AdminContent`, `AdminStats`), `src/store/slices/authSlice.ts` (export `selectIsAdmin = (s) => s.auth.userInfo?.user?.role === "admin"`, drop the unused `isAdmin?: boolean` field), `src/router/routes.tsx` (lazy `/admin` layout route with child index + `reach|users|content|ai-usage|audit`), `src/components/navbar/MainNavbar.tsx` (Admin link, desktop + mobile, only when `selectIsAdmin`), locales (`admin.nav.*`).

**Interfaces:** `adminApiSlice` endpoints named exactly: `getAdminStats`, `getAdminActivity`, `searchAdminUsers({ q, adminsOnly, page, limit })`, `getAdminUser(id)`, `banAdminUser({ id, reason })`, `unbanAdminUser({ id, reason })`, `changeAdminUserRole({ id, role, reason })`, `getBannedUsers({ page, limit, search })`, `hardDeleteAdminUser({ id, reason })`, `getAuditLog({ moderatorId, targetId, action, page, limit })`, `getAiUsage({ feature, from, to })`, `getAiUsageLogs({ feature, from, to, page, limit })`, `getAdminClubs({ page, limit, reported })`, `getAdminGatherings({ page, limit, reported })`, `archiveAdminClub({ id, archived, reason })`, `cancelAdminGathering({ id, reason })`, `getAnalyticsEvents({ days })`, `getAnalyticsVisits()`. Tags: user list/detail invalidated by ban/unban/role/delete; content by archive/cancel.

- [ ] Tests first: `adminSlice.test.ts` (endpoint names exist; `banAdminUser` invalidates `AdminUser` and `AdminUserList` — assert via `endpoints.banAdminUser.matchFulfilled` + tag arrays, or by dispatching against a mocked fetch and checking a subsequent `searchAdminUsers` refetch); `RequireAdmin.test.tsx` (non-admin → redirected to `/`, admin → children render); `MainNavbar.test.tsx` add: Admin link present only when `userInfo.user.role === "admin"`; `routes.test.tsx` add: `/admin` and `/admin/users` match a non-`*` route.
- [ ] Implement; `React.lazy` for the admin chunk with a `Suspense` fallback; `RequireAdmin` uses `useSelector(selectIsAdmin)` and `<Navigate to="/" replace />`.
- [ ] Run tests, full suite; commit `feat(admin): admin slice, route guard, routes and navbar entry`.

### Task 3 (frontend): Overview and Reach pages

**Files:** `pages/AdminOverview.tsx` (stat cards from `getAdminStats` + `getAdminActivity` + `getAnalyticsVisits`), `pages/AdminReach.tsx` (30-day inline-SVG line chart of `pageViews` and `storeTaps`; table of taps by placement × platform; top referrers; top paths; visits by country/device from `getAnalyticsVisits`), `src/components/admin/parts/StatCard.tsx`, `src/components/admin/parts/LineChart.tsx` (pure SVG, no library), `src/components/admin/parts/DataTable.tsx`, `src/components/admin/parts/RefreshButton.tsx`.
- [ ] Tests: `LineChart.test.tsx` (renders a `path` per series, handles empty data without NaN), `AdminOverview.test.tsx` and `AdminReach.test.tsx` (render with mocked hooks; stat values and table rows appear; error message shown inline when `isError`). Follow the `dataviz` skill's guidance for colors and axes (brand teal for page views, banana for taps; light/dark safe).
- [ ] Commit `feat(admin): overview and reach pages`.

### Task 4 (frontend): Users page

**Files:** `pages/AdminUsers.tsx` (search box → `searchAdminUsers`, paginated `DataTable`, row click opens `UserDetailDrawer`), `src/components/admin/parts/UserDetailDrawer.tsx` (detail + recent actions + activity summary; actions: ban/unban with reason dialog, role change with reason dialog, hard delete requiring the user's email typed), `src/components/admin/parts/ConfirmDialog.tsx`, tab for banned users (`getBannedUsers`).
- [ ] Tests: search debounced; ban dialog disabled until a reason is entered; hard-delete confirm disabled until the typed email matches; errors shown inline; mutations never retried.
- [ ] Commit `feat(admin): users page with ban, role and delete flows`.

### Task 5 (frontend): Content, AI usage, Audit log pages

**Files:** `pages/AdminContent.tsx` (clubs and gatherings tabs, `reported` filter, archive/cancel with reason), `pages/AdminAiUsage.tsx` (summary + logs, `feature`/date filters), `pages/AdminAudit.tsx` (paginated table, filters `action`, `moderatorId`, `targetId`).
- [ ] Tests per page: render with mocked hooks, filters change query args, actions require a reason.
- [ ] Commit `feat(admin): content moderation, AI usage and audit log pages`.

### Task 6: verification and merge

- [ ] Frontend full suite + `GENERATE_SOURCEMAP=false npm run build` (admin chunk present in `build/static/js`, `build/index.html` does not include admin markup, `grep -c "/admin" build/sitemap.xml` = 0).
- [ ] Headless browser: log in as an admin (needs a real admin account on the API; if unavailable, verify with a mocked `userInfo` in `localStorage` that the navbar shows Admin and `/admin` renders the layout, and that a non-admin is redirected).
- [ ] Merge `feat/admin-analytics` (backend) and `feat/admin-console` (frontend) into their mains with `--no-ff`; push both.

## Not in this plan
Email/export/new moderation actions; consent-withdrawal UI (separate); Phase B marketing pages.
