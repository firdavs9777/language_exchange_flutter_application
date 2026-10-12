# Onboarding, Announcements, Localization & Calls Phase 2 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Guides that retire on real first actions (3 of 4 or 7 days) plus a long-press chat tip; one launch pop-up per launch; admin-managed, scheduled, multi-language announcements delivered as pop-ups, push and permanent notification-list entries; every hardcoded English string localized; Calls Phase 2; and the PM2-restart / `flutter: null` investigations.

**Architecture:** App-side `ActivationStore` + guide rule + `LaunchModalCoordinator`/`PopupBudget`; backend `Announcement` model with a selection service, admin CRUD/publish routes, an idempotent resumable delivery job and a minute tick, surfaced through the existing `/app-config` (legacy single field kept); a React admin page on the existing RTK admin slice; mechanical l10n tasks with a guard test; Calls Phase 2 on the Phase 1 state machine.

**Tech Stack:** Flutter 3.24+/Riverpod 2 · Node/Express/Mongoose/node:test · React + TypeScript + RTK Query (admin) · firebase-admin, Spaces upload.

**Spec:** `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md` (approved). Shared names: §"Interface contract" below.

## Global Constraints

- Guide period: `kGuideWindowDays = 7`; all guides stop at **3 of 4** activation actions or 7 days after signup; a surface retires on its **real** action, never on a CTA tap.
- Activation actions: message, moment (create only), lesson (completed), profile (photo + non-empty bio).
- One launch pop-up per launch: update → announcement → ads notice → feature spotlight; in the guide period only update + ads notice; notification priming and the splash welcome-back pop-up share the same `PopupBudget`.
- Announcements: several live at once; selection priority desc then startsAt desc; each shown once per user (seen ids, user-scoped); legacy single `announcement` field and env-var fallback stay for old builds.
- Announcement delivery is idempotent (atomic claim) and resumable; one `Notification` row per user (`userId`), permanent (`expiresAt: null`); push respects `notificationSettings.announcements` and quiet hours; list entry always written.
- Admin routes are admin-only and audit-logged.
- Every new user-facing string in all 19 locales (machine drafts recorded in `docs/l10n/native-qa-strings-2026-10.csv`); app imports `package:` only.
- Live builds must keep working: all backend changes additive (calls: no re-sent `call:accepted`; missed-call push stays visible for builds without the `missed_call_actions` capability).
- Every commit updates that repo's `docs/REMAINING_WORK.md` and ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Backend tests: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js <file>`; app: `flutter test <file>`; web: the repo's test command per W tasks.

## Review Focus

1. A user who did the real action **before** this release (existing message/profile) must not see that tab's guide again — back-fill in A2/A3.
2. An announcement published twice, or a server restart mid-delivery, must not push twice or create two list rows — B6.
3. A user whose app language has no translation gets the default-language text, never empty — B3/B10.
4. Two pop-ups never stack on one launch, including priming and the splash welcome-back — A8/A9/A12.
5. Ending an announcement removes it from the next launch's pop-up but keeps existing notification-list entries — B7/A11.

## Execution order

O1a → O1b (owner runs the workflow) → O1c → O2 → B1–B11 → W1–W5 → A1–A16 → L1–L13 (L11 re-greps `widgets/promo/*` after A10/A12) → C1–C4 → C5–C11 (L12 lands before C9/C10).

## Rulings made while assembling

- The splash welcome-back pop-up (found by the A-part, not in the spec) consumes `PopupBudget` like every other launch pop-up — A12 owns it.
- Localization scope is the real count (402 literals localized, 151 allowlisted with reasons), not the spec's 74.
- Notification field is `userId` (model fact), not `user` as the contract said.

---

## Interface contract

Repos: APP=/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app (Flutter), BACKEND=/Users/davis/Desktop/Personal/language_exchange_backend_application (Node/Express/Mongoose, node:test; run tests `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js <file>`), WEB=/Users/davis/Desktop/Personal/language_exchange_web_front (React+TS, RTK Query admin slice src/store/slices/adminSlice, admin pages src/components/admin/pages, tests next to pages).
Every commit in each repo updates that repo's docs/REMAINING_WORK.md (tick/list open in commit body) and ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. App: package: imports only; new strings in all 19 lib/l10n/app_*.arb + `flutter gen-l10n`.

Task id prefixes: O = ops, B = backend, W = web admin, A = app activation/launch/announcements-UI, L = localization, C = calls Phase 2. Execution order: O1-O2, B*, W*, A*, L*, C*.

## Backend
- Model `models/Announcement.js` fields exactly as spec §5.1; statuses 'draft'|'scheduled'|'live'|'ended'; delivery.state 'none'|'queued'|'running'|'done'|'failed'.
- `services/announcementService.js`: `liveAnnouncementsFor({ platform, language, now }) -> Promise<Array<PublicAnnouncement>>`, `toPublic(doc, language) -> { id, title, body, emoji, imageUrl, buttonLabel, buttonUrl, priority }`, `audienceQuery(doc) -> mongo filter on User`.
- `services/announcementDelivery.js`: `deliver(announcementId) -> Promise<{targeted, pushed, listed, failed}>` (atomic claim none->running; resume running older than 10 min), `jobs/announcementJob.js` minute tick: `runAnnouncementTick(now)` flips scheduled->live (startsAt<=now) and live->ended (endsAt<=now) and calls deliver for newly-live notify announcements.
- app-config: existing `announcement` (single, legacy) + new `announcements: PublicAnnouncement[]`. Language from query param `lang` (app sends it; fallback Accept-Language, then 'en').
- Admin routes mounted at `/api/v1/admin/announcements`: GET `/`?status=, GET `/:id`, POST `/` (create draft), PUT `/:id`, POST `/:id/publish` body `{ at?: ISO }`, POST `/:id/end`, DELETE `/:id`, GET `/:id/audience-count` -> `{ count }`, POST `/upload-image` (multipart `image`) -> `{ url }`. Responses `{ success, data }`.
- User route: GET `/api/v1/announcements/:id` -> `{ success, data: PublicAnnouncement }` in the user's app language (query `lang`).
- Notification row: `Notification { user, type: 'announcement', title, body, data: { announcementId } }`; unique partial index `{ user:1, type:1, 'data.announcementId':1 }` where type 'announcement'.
- Push data payload: `{ type: 'announcement', announcementId }`.
- User setting: `notificationSettings.announcements` Boolean default true (push only; list entry always written).
- Suspension: ban/suspended responses and socket error data carry `banReason` (string|null).
- Calls Phase 2: POST `/api/v1/calls/:id/decline` body `{ message?: string<=200 }`; POST `/api/v1/calls/:id/upgrade` -> sets type 'video', emits call:state with `type`; `notificationSettings.allowCalls` Boolean default true; quiet hours from existing `User.quietHours`; initiate returns `409 { error code 'CALLEE_UNAVAILABLE' }` and records busy/unavailable (no message, no push); missed-call push data adds `actions: ['call_back','message']`, `callType`, `callerId`.

## App
- `lib/services/activation_store.dart`: `enum ActivationAction { message, moment, lesson, profile }` (slugs 'message','moment','lesson','profile'); `class ActivationStore { Future<bool> markDone(ActivationAction a); Future<bool> isDone(ActivationAction a); Future<int> doneCount(); }`; `activationStoreProvider`; `Future<void> checkProfileComplete(Community user)`.
- `lib/services/guide_store.dart`: add `GuideSurface.chatTip` (slug 'chat_tip'); `kGuideWindowDays = 7`; `bool shouldShowGuide({required bool withinWindow, required bool acted, required int milestonesDone})`; `Future<bool> isGuidePeriod(Community? user, ActivationStore store)`; `isGuidePeriodProvider` (FutureProvider<bool>).
- Analytics (`lib/services/analytics_service.dart`): `logActivationMilestone(String action, int count)`, `logGuideRetired(String surface, String reason)` reason 'acted'|'milestones'|'window', `logNotificationPrimeShown(String trigger)`, `logNotificationPrimeResult(String result)` result 'granted'|'declined'|'later'.
- `lib/services/launch_modal_coordinator.dart`: `abstract class LaunchCandidate { String get id; bool get allowedForNewUsers; Future<bool> isDue(); Future<void> show(BuildContext context); }`; `class LaunchModalCoordinator { Future<void> run(BuildContext context, {required bool guidePeriod, required bool updateShown}); }`; `class PopupBudget { static bool tryConsume(); static void debugReset(); }`.
- `lib/services/promo_service.dart`: add `PromoType.aiStudy`.
- Announcements: `lib/models/announcement.dart` `class Announcement { String id, title, body; String? emoji, imageUrl, buttonLabel, buttonUrl; int priority; factory fromJson }`; app config exposes `List<Announcement> announcements`; seen ids pref `announcements_seen_ids` (user-scoped); `lib/pages/announcements/announcement_screen.dart` route `/announcement/:id`; NotificationItem type 'announcement'; settings toggle key 'announcements'.
- Calls Phase 2 app pieces consume the backend calls contract above via existing `CallApi` / `CallManager` / `CallLauncher`.

---

# Part 1 — Ops, backend, web admin

Spec: `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md` §7, §5.1, §5.3. Contract: `parts/00-contract.md`.

Repos: `APP`=/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app, `BACKEND`=/Users/davis/Desktop/Personal/language_exchange_backend_application, `WEB`=/Users/davis/Desktop/Personal/language_exchange_web_front.

Commands (run from the repo root named in each task):
- Backend test: `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/<file>`
- Web test: `CI=true npx react-scripts test --watchAll=false <path>`
- App test: `flutter test <path>`

Branches: O1a goes straight to backend `main` (a `workflow_dispatch` workflow is only runnable from the default branch; the push also triggers `deploy.yml` = one deploy restart, expected). O1c + B* on backend `feat/announcements`. W* on web `feat/admin-announcements`. O2 on app `fix/null-log-trap`.

Order: O1a → O1b (owner runs the workflow) → O1c → O2 → B1…B11 → W1…W5. **The announcement job (B9) is not deployed until O1b is recorded** (spec §10.1).

Evidence already gathered while writing this plan (2026-10-12):
- `GET https://api.banatalk.com/health` → `environment: "production"`, `uptime: 317515` s (≈3.7 days = the 2026-10-08 calls deploy). The process is currently stable; the ~7,600 restarts are cumulative since PM2 registration.
- `server.js` logs `uncaughtException` / `unhandledRejection` with `console.log` (stdout), so `pm2 logs --err` alone **cannot** show the crashes that matter. O1a therefore reads pm2's own daemon log (`~/.pm2/pm2.log`, one `exited with code [N] via signal [S]` line per exit) and the out log too.
- `pm2 describe` prints a "Divergent env variables" block that includes secrets; the workflow uses `pm2 jlist` filtered to named fields instead, so nothing secret reaches the Actions log.
- Backend `main` has ~750 first-parent commits in 2026 → deploys alone cannot explain 7,600 restarts.

---

## Ops

### Task O1a: read-only `diagnose.yml` workflow

**Files:** Create `BACKEND/.github/workflows/diagnose.yml`; Test `BACKEND/test/diagnoseWorkflow.test.js`
**Interfaces:** Consumes repo secrets `DROPLET_HOST`, `DROPLET_USER`, `DROPLET_SSH_KEY`, `DROPLET_PORT` (same as `deploy.yml`). Produces a manual workflow "Diagnose PM2 restarts".

- [ ] Step 1: failing test `BACKEND/test/diagnoseWorkflow.test.js`

```js
'use strict';
/**
 * diagnose.yml runs on the production droplet. It must stay read-only and must
 * never print environment values into the (repo-readable) Actions log.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, '..', '.github', 'workflows', 'diagnose.yml');
const text = () => fs.readFileSync(FILE, 'utf8');

test('manual trigger only', () => {
  assert.match(text(), /^on:\s*\n\s+workflow_dispatch:/m);
  assert.doesNotMatch(text(), /^\s+(push|pull_request|schedule):/m);
});

test('never changes the droplet', () => {
  for (const bad of [
    /pm2 (restart|reload|stop|start|delete|save|flush|kill|update)/,
    /git (reset|pull|fetch|checkout|clean)/,
    /npm (ci|install|run)/,
    /\brm\b/,
    /\bsudo\b/,
  ]) assert.doesNotMatch(text(), bad, `forbidden: ${bad}`);
});

test('never prints the env block', () => {
  assert.doesNotMatch(text(), /pm2 (describe|show|env|prettylist)/);
  assert.doesNotMatch(text(), /\bprintenv\b/);
});

test('prints the evidence a diagnosis needs', () => {
  for (const s of [
    'pm2 jlist', 'restart_time', 'unstable_restarts', 'max_memory_restart', 'watch',
    'pm2.log', 'exited with code', 'pm2 logs language-app --err', '[crash]', 'Uncaught Exception',
  ]) assert.ok(text().includes(s), `missing: ${s}`);
});
```

- [ ] Step 2: run → fails `ENOENT ... diagnose.yml`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/diagnoseWorkflow.test.js`

- [ ] Step 3: create `BACKEND/.github/workflows/diagnose.yml`

```yaml
name: Diagnose PM2 restarts

# Manually triggered: GitHub UI -> Actions -> "Diagnose PM2 restarts" -> Run.
# READ-ONLY. It never pulls, installs, restarts or edits anything on the
# droplet, and it never prints environment values: PM2's describe command
# dumps the process env (secrets) into the log, so process facts come from
# `pm2 jlist` filtered to named fields below.
#
# Why each section exists (spec 2026-10-12 §7):
#  - pm2.log has one "exited with code [N] via signal [S]" line per exit; that
#    is the only place a deploy restart (SIGINT, code 0) and a crash (code 1)
#    can be told apart after the fact.
#  - server.js logged crashes to STDOUT before O1c, so the out log is read too.
#  - after O1c every crash writes one `[crash]` line to stderr; counted below.
on:
  workflow_dispatch:
    inputs:
      lines:
        description: 'Lines to print from the error log'
        required: false
        default: '500'

concurrency:
  group: diagnose-production
  cancel-in-progress: false

jobs:
  diagnose:
    name: Read PM2 state on droplet
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - name: SSH and print diagnosis
        uses: appleboy/ssh-action@v1.2.0
        env:
          LOG_LINES: ${{ github.event.inputs.lines || '500' }}
        with:
          host: ${{ secrets.DROPLET_HOST }}
          username: ${{ secrets.DROPLET_USER }}
          key: ${{ secrets.DROPLET_SSH_KEY }}
          port: ${{ secrets.DROPLET_PORT || 22 }}
          command_timeout: 5m
          script_stop: false
          envs: LOG_LINES
          script: |
            APP=language-app
            case "$LOG_LINES" in ''|*[!0-9]*) LOG_LINES=500;; esac
            PM2_DIR="${PM2_HOME:-$HOME/.pm2}"

            echo "==> Process facts (named fields only)"
            pm2 jlist | node -e '
              let s = "";
              process.stdin.on("data", (d) => { s += d; }).on("end", () => {
                for (const p of JSON.parse(s).filter((x) => x.name === "language-app")) {
                  const e = p.pm2_env || {};
                  const iso = (t) => (t ? new Date(t).toISOString() : null);
                  console.log(JSON.stringify({
                    pm_id: p.pm_id, status: e.status,
                    restart_time: e.restart_time, unstable_restarts: e.unstable_restarts,
                    created_at: iso(e.created_at), pm_uptime: iso(e.pm_uptime),
                    exit_code: e.exit_code, exec_mode: e.exec_mode, instances: e.instances,
                    autorestart: e.autorestart, watch: e.watch,
                    max_memory_restart: e.max_memory_restart || null,
                    node_version: e.node_version,
                    NODE_ENV: e.NODE_ENV || (e.env && e.env.NODE_ENV) || null,
                    out_log: e.pm_out_log_path, err_log: e.pm_err_log_path,
                    memory_mb: p.monit ? Math.round(p.monit.memory / 1048576) : null,
                  }, null, 2));
                }
              });'

            LOGS=$(pm2 jlist | node -e '
              let s = "";
              process.stdin.on("data", (d) => { s += d; }).on("end", () => {
                const p = JSON.parse(s).find((x) => x.name === "language-app");
                const e = (p && p.pm2_env) || {};
                console.log((e.pm_out_log_path || "") + " " + (e.pm_err_log_path || ""));
              });')
            OUT_LOG=$(echo "$LOGS" | cut -d" " -f1)
            ERR_LOG=$(echo "$LOGS" | cut -d" " -f2)

            echo "==> Exits by code/signal (pm2.log, incl. rotated)"
            grep -h "\[$APP:" "$PM2_DIR"/pm2.log* 2>/dev/null \
              | grep -o "exited with code \[[0-9]*\] via signal \[[A-Z0-9]*\]" \
              | sort | uniq -c | sort -rn

            echo "==> Exits per day (pm2.log)"
            grep -h "\[$APP:.*exited with code" "$PM2_DIR"/pm2.log* 2>/dev/null \
              | cut -c1-10 | sort | uniq -c | tail -90

            echo "==> Operator stops per day (deploy restarts show up here)"
            grep -h "Stopping app:$APP" "$PM2_DIR"/pm2.log* 2>/dev/null \
              | cut -c1-10 | sort | uniq -c | tail -90

            echo "==> Last 40 exits"
            grep -h "\[$APP:.*exited with code" "$PM2_DIR"/pm2.log 2>/dev/null | tail -40

            echo "==> Crash markers in app logs (count per file)"
            for f in "$ERR_LOG"* "$OUT_LOG"*; do
              [ -f "$f" ] || continue
              printf '%s: ' "$f"
              grep -c -E "\[crash\]|Uncaught Exception|Unhandled Rejection|FATAL ERROR|heap out of memory|EADDRINUSE|MongooseServerSelectionError" "$f"
            done

            echo "==> Context around the last 15 crash markers"
            grep -h -B2 -A12 -E "\[crash\]|Uncaught Exception|FATAL ERROR|heap out of memory|EADDRINUSE" \
              "$ERR_LOG" "$OUT_LOG" 2>/dev/null | tail -300

            echo "==> pm2 logs language-app --err (last $LOG_LINES)"
            pm2 logs language-app --err --lines "$LOG_LINES" --nostream

            echo "==> Kernel OOM kills"
            (dmesg -T 2>/dev/null || journalctl -k --no-pager 2>/dev/null) \
              | grep -i -E "out of memory|killed process" | tail -20 \
              || echo "(kernel log not readable as this user)"

            echo "==> Host"
            uptime; free -m; df -h /
            echo "==> Deployed commit"
            git -C /home/language_exchange_backend_application log -1 --format='%h %cI %s'
```

- [ ] Step 4: run Step 2's command → 4 passing.
- [ ] Step 5: commit on backend `main` and push (owner pushes; the push also deploys once)
```
git add .github/workflows/diagnose.yml test/diagnoseWorkflow.test.js docs/REMAINING_WORK.md
git commit -m "ops: read-only diagnose workflow for PM2 restarts

Adds a manual workflow that prints restart counts, exit codes/signals per day,
crash markers and the error log without printing env values or touching the
droplet.

REMAINING_WORK: added 'Owner: run Actions -> Diagnose PM2 restarts, paste the
output into docs/ops/2026-10-pm2-restarts.md (O1b)'.
Still open: O1b diagnosis, O1c crash logging, announcements (B1-B11).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
`docs/REMAINING_WORK.md` edit (backend), new section at the top:
```md
## Ops (2026-10-12) — before the announcement job ships
- [ ] Owner: GitHub → Actions → "Diagnose PM2 restarts" → Run workflow; hand the log to Claude (O1b).
- [ ] Record the restart cause in `docs/ops/2026-10-pm2-restarts.md` and here; fix or ticket each crash (O1b/O1c).
```

### Task O1b: run the workflow, classify, record

**Files:** Create `BACKEND/docs/ops/2026-10-pm2-restarts.md`; Modify `BACKEND/docs/REMAINING_WORK.md`, `APP/docs/REMAINING_WORK.md`
**Interfaces:** Consumes the O1a run log. Produces the recorded diagnosis (spec §7 exit criterion).

- [ ] Step 1 (owner): GitHub → `language_exchange_backend_application` → Actions → "Diagnose PM2 restarts" → Run workflow (default 500 lines). Download the log (`gh run view --log <run-id> > /tmp/diagnose.log`) and give it to the implementer.
- [ ] Step 2: classify with this table (the first row whose evidence matches wins; several rows can apply):

| Evidence in the log | Cause | Action |
|---|---|---|
| `watch: true` | PM2 restarts on every file write (logs, uploads) | Fix now: `pm2 restart language-app --watch=false && pm2 save` (owner); record |
| `max_memory_restart` set and exits `code [0] via signal [SIGINT]` cluster on days with no "Stopping app" line | Memory-limit restarts | Record the limit and `memory_mb`; ticket "heap growth" with the per-day count |
| Kernel OOM lines naming `node` | Droplet OOM kill | Ticket: resize droplet or cap heap (`--max-old-space-size`); record |
| `exited with code [1]` lines, `[crash]`/`Uncaught Exception` context present | Crash | One REMAINING_WORK ticket per distinct stack (top frame + count + first/last date); each becomes its own fix task with a reproducing test |
| `EADDRINUSE` repeated within seconds | Crash loop at boot (a second process holds the port) | Record the burst size; check `pm2 jlist` for duplicate `language-app` entries; ticket |
| `MongooseServerSelectionError` before exits | DB unreachable at boot → exit → loop | Ticket: boot retry with backoff instead of exit |
| `code [0] via signal [SIGINT]` only on days that also have "Stopping app" lines, ≈ number of deploys | Deploy restarts | Nothing to fix; record |
| No exits in rotated pm2.log older than its retention | Counter predates log retention | Record "historical, cause unrecoverable"; `pm2 reset language-app` (owner) so the counter means something from now on |

- [ ] Step 3: write `BACKEND/docs/ops/2026-10-pm2-restarts.md` with exactly these sections: `## Run` (run URL, date, deployed commit), `## Facts` (the jlist JSON block verbatim), `## Exit histogram` (the two per-day tables verbatim, trimmed to non-zero days), `## Classification` (one row per table row that matched, with the counts that matched it), `## Actions` (each ticket text, identical to the REMAINING_WORK line).
- [ ] Step 4: verify the exit criterion: every exit counted in the histogram is attributed to a row in `## Classification` (sum of attributed exits = histogram total, or the remainder is stated as "older than pm2.log retention").
- [ ] Step 5: commit (backend, then app)
```
cd BACKEND
git add docs/ops/2026-10-pm2-restarts.md docs/REMAINING_WORK.md
git commit -m "docs(ops): PM2 restart diagnosis

Records the cause of the language-app restart count from the read-only
diagnose workflow, classified crash vs deploy vs memory.

REMAINING_WORK: ticked 'run diagnose workflow' and 'record restart cause';
added one ticket per distinct crash stack found (see docs/ops/2026-10-pm2-restarts.md).
Still open: crash tickets listed there, O1c, B1-B11.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"

cd APP
git add docs/REMAINING_WORK.md
git commit -m "docs: PM2 restart cause recorded in the backend repo

REMAINING_WORK: moved '7,533 PM2 restarts' out of 'Unexplained' with a link to
backend docs/ops/2026-10-pm2-restarts.md.
Still open: flutter: null lines (O2), announcement app work.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
App REMAINING_WORK edit: in "**Unexplained — no owner yet** (§0b)" replace `- 7,533 PM2 restarts on the droplet` with `- [x] PM2 restarts — cause recorded in backend docs/ops/2026-10-pm2-restarts.md (2026-10-12)`.

### Task O1c: every crash logs one `[crash]` line to stderr

**Files:** Create `BACKEND/lib/processGuards.js`; Modify `BACKEND/server.js` (replace the two `process.on('unhandledRejection'…)` / `process.on('uncaughtException'…)` blocks, currently lines 502–522); Test `BACKEND/test/processGuards.test.js`
**Interfaces:** Produces `installProcessGuards({ processRef, log, shutdown, env })`, `crashLine(kind, err)`, `CRASH_TAG`.

Behaviour is unchanged (production survives an unhandled rejection; an uncaught exception still shuts down) — only *where* it is logged changes, so the next diagnosis needs `pm2 logs --err` alone.

- [ ] Step 1: failing test `BACKEND/test/processGuards.test.js`
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const { installProcessGuards, CRASH_TAG } = require('../lib/processGuards');

const rig = (env) => {
  const proc = new EventEmitter();
  const lines = [];
  const shutdowns = [];
  installProcessGuards({
    processRef: proc, env,
    log: (l) => lines.push(l),
    shutdown: (signal, code) => shutdowns.push([signal, code]),
  });
  return { proc, lines, shutdowns };
};

test('an uncaught exception logs one [crash] line with its stack and shuts down with 1', () => {
  const { proc, lines, shutdowns } = rig('production');
  proc.emit('uncaughtException', new Error('boom'));
  assert.ok(lines[0].startsWith(`${CRASH_TAG} uncaughtException`));
  assert.ok(lines[0].includes('boom'));
  assert.ok(lines.some((l) => l.includes('processGuards.test.js')), 'stack is logged');
  assert.deepEqual(shutdowns, [['UNCAUGHT_EXCEPTION', 1]]);
});

test('production survives an unhandled rejection but still logs it as a crash line', () => {
  const { proc, lines, shutdowns } = rig('production');
  proc.emit('unhandledRejection', new Error('nope'));
  assert.ok(lines[0].startsWith(`${CRASH_TAG} unhandledRejection`));
  assert.deepEqual(shutdowns, []);
});

test('outside production an unhandled rejection shuts down (unchanged behaviour)', () => {
  const { proc, shutdowns } = rig('development');
  proc.emit('unhandledRejection', new Error('nope'));
  assert.deepEqual(shutdowns, [['UNHANDLED_REJECTION', 1]]);
});

test('a non-Error rejection reason is still logged', () => {
  const { proc, lines } = rig('production');
  proc.emit('unhandledRejection', 'plain string');
  assert.ok(lines[0].includes('plain string'));
});
```
- [ ] Step 2: run → fails `Cannot find module '../lib/processGuards'`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/processGuards.test.js`
- [ ] Step 3: create `BACKEND/lib/processGuards.js`
```js
'use strict';

/**
 * Process-level crash handlers. Every way the process dies writes ONE line
 * starting with CRASH_TAG to stderr (console.error), followed by the stack, so
 * `pm2 logs language-app --err` and .github/workflows/diagnose.yml can count
 * crashes. Before this they went to stdout via console.log and the error log
 * never showed them (docs/ops/2026-10-pm2-restarts.md).
 *
 * Behaviour is deliberately the same as before: production keeps running on
 * an unhandled rejection; an uncaught exception always shuts down.
 */
const CRASH_TAG = '[crash]';

function crashLine(kind, err) {
  const message = err && err.message ? err.message : String(err);
  return `${CRASH_TAG} ${kind} at ${new Date().toISOString()}: ${message}`;
}

function installProcessGuards({
  processRef = process,
  log = console.error,
  shutdown,
  env = process.env.NODE_ENV,
}) {
  processRef.on('unhandledRejection', (err) => {
    log(crashLine('unhandledRejection', err));
    if (err && err.stack) log(err.stack);
    if (env !== 'production') shutdown('UNHANDLED_REJECTION', 1);
  });

  processRef.on('uncaughtException', (err) => {
    log(crashLine('uncaughtException', err));
    if (err && err.stack) log(err.stack);
    shutdown('UNCAUGHT_EXCEPTION', 1);
  });
}

module.exports = { installProcessGuards, crashLine, CRASH_TAG };
```
`BACKEND/server.js`: delete the block from `// Handle unhandled promise rejections` through the closing `});` of the `uncaughtException` handler and put in its place:
```js
// Crash handlers: one `[crash]` line on stderr per crash (lib/processGuards.js).
require('./lib/processGuards').installProcessGuards({ shutdown: gracefulShutdown });
```
- [ ] Step 4: run Step 2's command → 4 passing; `node -e "require('./lib/processGuards')"` exits 0.
- [ ] Step 5: commit
```
git add lib/processGuards.js server.js test/processGuards.test.js docs/REMAINING_WORK.md
git commit -m "fix(ops): crashes log one [crash] line to stderr

uncaughtException/unhandledRejection were logged with console.log, so the
PM2 error log never showed the crashes behind the restart count. Same
shutdown behaviour, now on stderr with a countable tag.

REMAINING_WORK: ticked 'crash logging to stderr (O1c)'.
Still open: crash tickets from docs/ops/2026-10-pm2-restarts.md, B1-B11.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task O2: find and fix the bare `flutter: null` lines

**Files:** Create `APP/lib/utils/null_log_trap.dart`; Modify `APP/lib/main.dart`; Test `APP/test/utils/null_log_trap_test.dart`; Modify `APP/docs/REMAINING_WORK.md`
**Interfaces:** Produces `installNullLogTrap()`, `nullPrintZone()`, `wrapDebugPrint(DebugPrintCallback)`, `callerFrame(StackTrace)`, `kNullLogTag`.

Grep already done (2026-10-12): no `print(null)` / bare-variable `print`/`debugPrint` in `lib/`; every `print(` in `lib/` carries a literal prefix. So the line comes from a dependency or from an interpolation that evaluates to `"null"`. A debug-only trap names the caller on the next occurrence; it stays in the app (debug builds only) so a regression is self-locating.

- [ ] Step 1: failing test `APP/test/utils/null_log_trap_test.dart`
```dart
import 'dart:async';

import 'package:bananatalk_app/utils/null_log_trap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debugPrint(null) is followed by a line naming the caller', () {
    final lines = <String?>[];
    final trapped = wrapDebugPrint((String? m, {int? wrapWidth}) => lines.add(m));

    trapped(null);

    expect(lines, hasLength(2));
    expect(lines[0], isNull);
    expect(lines[1], startsWith(kNullLogTag));
    expect(lines[1], contains('null_log_trap_test.dart'));
  });

  test('the literal string "null" is trapped too', () {
    final lines = <String?>[];
    final trapped = wrapDebugPrint((String? m, {int? wrapWidth}) => lines.add(m));
    trapped('null');
    expect(lines.last, startsWith(kNullLogTag));
  });

  test('ordinary messages pass through untouched', () {
    final lines = <String?>[];
    final trapped = wrapDebugPrint((String? m, {int? wrapWidth}) => lines.add(m));
    trapped('🎯 Provider: hello');
    expect(lines, ['🎯 Provider: hello']);
  });

  test('print(null) inside the trap zone is followed by the caller line', () {
    final lines = <String>[];
    runZoned(
      () => runZoned(() => print(null), zoneSpecification: nullPrintZone()),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );
    expect(lines.first, 'null');
    expect(lines[1], startsWith(kNullLogTag));
    expect(lines[1], contains('null_log_trap_test.dart'));
  });

  test('callerFrame skips dart: and flutter frames', () {
    final frame = callerFrame(StackTrace.fromString(
      '#0 foo (dart:core/print.dart:1)\n'
      '#1 bar (package:flutter/src/foundation/print.dart:2)\n'
      '#2 baz (package:dio/src/log.dart:150:5)\n',
    ));
    expect(frame, contains('package:dio/src/log.dart:150'));
  });
}
```
- [ ] Step 2: run → fails (`null_log_trap.dart` not found): `cd APP && flutter test test/utils/null_log_trap_test.dart`
- [ ] Step 3: create `APP/lib/utils/null_log_trap.dart`
```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debug-only locator for bare `flutter: null` console lines.
///
/// Nothing in lib/ prints a bare null (grepped 2026-10-12), so the line comes
/// from a dependency or an interpolation that evaluates to "null". When one is
/// printed, the trap prints a second line naming the first stack frame outside
/// dart: and package:flutter/ — the code that logged it.
const String kNullLogTag = '[null-log]';

bool _isBareNull(String? message) => message == null || message.trim() == 'null';

/// First frame that is not the SDK, Flutter's print plumbing or this file.
String? callerFrame(StackTrace stack) {
  for (final raw in stack.toString().split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.contains('null_log_trap.dart')) continue;
    if (line.contains('(dart:') || line.contains('package:flutter/')) continue;
    return line;
  }
  return null;
}

String _report(String kind) =>
    '$kNullLogTag $kind from ${callerFrame(StackTrace.current) ?? 'unknown frame'}';

DebugPrintCallback wrapDebugPrint(DebugPrintCallback inner) {
  return (String? message, {int? wrapWidth}) {
    inner(message, wrapWidth: wrapWidth);
    if (_isBareNull(message)) inner(_report('debugPrint(null)'));
  };
}

ZoneSpecification nullPrintZone() => ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, line);
        if (_isBareNull(line)) parent.print(zone, _report('print(null)'));
      },
    );

/// Wraps [debugPrint] in debug builds; a no-op in profile/release.
void installNullLogTrap() {
  if (!kDebugMode) return;
  debugPrint = wrapDebugPrint(debugPrint);
}
```
`APP/lib/main.dart`: rename the existing `Future<void> main() async {` to `Future<void> _main() async {`, make `installNullLogTrap();` its first statement (before `WidgetsFlutterBinding.ensureInitialized();`), add `import 'package:bananatalk_app/utils/null_log_trap.dart';` with the other `package:bananatalk_app` imports, and add above `_main`:
```dart
/// Debug builds run inside a zone that names the caller of any bare
/// `print(null)` (lib/utils/null_log_trap.dart). The binding is initialized
/// inside `_main`, i.e. inside the same zone as `runApp`, so there is no zone
/// mismatch.
Future<void> main() => kDebugMode
    ? runZoned(_main, zoneSpecification: nullPrintZone())
    : _main();
```
- [ ] Step 4: run → 5 passing; `flutter analyze lib/main.dart lib/utils/null_log_trap.dart` → no issues.
- [ ] Step 5: locate and fix (debug run). `flutter run` on the iOS simulator, open a chat whose partner was last seen long ago (the 2026-10-09 repro: header ≈99px wide), watch the console. The `[null-log] … from <frame>` line names the source:
  - frame under `package:bananatalk_app/` → replace that call with a prefixed message that says what it is (`debugPrint('<File>: <what> is null')`) or delete it if it carries nothing; add the exact file:line to the commit body.
  - frame under another `package:` → not ours to change; record `package:<name> <file>:<line>` in REMAINING_WORK as known noise.
  - no `[null-log]` line while `flutter: null` still appears → it was printed by native code with the `flutter:` prefix (plugin channel log); record "native plugin log, not Dart" with the plugin name from the preceding line.
- [ ] Step 6: commit
```
git add lib/utils/null_log_trap.dart lib/main.dart test/utils/null_log_trap_test.dart docs/REMAINING_WORK.md
git commit -m "fix(debug): locate bare 'flutter: null' log lines

Debug-only trap: a bare print(null)/debugPrint(null) is followed by a
[null-log] line naming the calling frame. Source found: <frame from Step 5>.

REMAINING_WORK: ticked 'Two bare flutter: null lines' with the source.
Still open: announcement app work (A*), localization (L*), calls Phase 2 (C*).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
(`<frame from Step 5>` is the literal frame string the trap printed; the commit is not made until it is known.)
App REMAINING_WORK edits: in §0b replace `- Two bare \`flutter: null\` log lines after the chat app-bar overflow` with `- [x] \`flutter: null\` lines — source <frame>, <fixed | known package noise> (2026-10-12)`; tick the `- [ ] **Two bare \`flutter: null\` lines**` item further down with the same text.

---
## Backend (`BACKEND`, branch `feat/announcements`)

### Task B1: `Announcement` model

**Files:** Create `BACKEND/models/Announcement.js`; Test `BACKEND/test/announcementModel.test.js`
**Interfaces:** Produces model `Announcement` with the spec §5.1 fields exactly, plus `delivery.heartbeatAt`, `delivery.cursor`, `delivery.error` (resume bookkeeping the spec describes in prose). Exports `STATUSES`, `DELIVERY_STATES`, `PLATFORMS`, `LIMITS`, `BUTTON_URL_RE` as statics.

- [ ] Step 1: failing test `BACKEND/test/announcementModel.test.js`
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const Announcement = require('../models/Announcement');

const valid = (over = {}) => new Announcement({
  translations: { en: { title: 'Hello', body: 'World', buttonLabel: 'Open' } },
  defaultLocale: 'en',
  ...over,
});
// validate() (not validateSync) so the pre('validate') cross-field hook runs; no DB needed.
const errorsOf = async (doc) => {
  try { await doc.validate(); return []; } catch (err) { return Object.keys(err.errors || {}); }
};

test('defaults: draft, priority 0, all platforms, all languages, in-app on, notify off, delivery none', async () => {
  const a = valid();
  assert.deepEqual((await errorsOf(a)), []);
  assert.equal(a.status, 'draft');
  assert.equal(a.priority, 0);
  assert.deepEqual([...a.platforms], ['all']);
  assert.deepEqual([...a.languages], []);
  assert.equal(a.showInApp, true);
  assert.equal(a.notify, false);
  assert.equal(a.delivery.state, 'none');
  assert.equal(a.delivery.targeted, 0);
});

test('the default locale must have a translation', async () => {
  assert.ok((await errorsOf(valid({ defaultLocale: 'ko' }))).includes('translations'));
});

test('translation keys are limited to the 19 template locales', async () => {
  const a = valid({ translations: { en: { title: 'a', body: 'b' }, xx: { title: 'a', body: 'b' } } });
  assert.ok((await errorsOf(a)).includes('translations'));
});

test('text limits: title 100, body 1000, buttonLabel 40', async () => {
  const long = (n) => 'x'.repeat(n);
  assert.ok((await errorsOf(valid({ translations: { en: { title: long(101), body: 'b' } } }))).some((k) => k.endsWith('title')));
  assert.ok((await errorsOf(valid({ translations: { en: { title: 't', body: long(1001) } } }))).some((k) => k.endsWith('body')));
  assert.ok((await errorsOf(valid({ translations: { en: { title: 't', body: 'b', buttonLabel: long(41) } } }))).some((k) => k.endsWith('buttonLabel')));
  assert.deepEqual((await errorsOf(valid({ translations: { en: { title: long(100), body: long(1000), buttonLabel: long(40) } } }))), []);
});

test('title and body are required in every translation present', async () => {
  assert.ok((await errorsOf(valid({ translations: { en: { title: '', body: 'b' } } }))).some((k) => k.endsWith('title')));
});

test('buttonUrl: http(s), bananatalk:// or an app path; nothing else', async () => {
  for (const ok of ['https://banatalk.com/x', 'http://a.b', 'bananatalk://moment/1', '/study']) {
    assert.deepEqual((await errorsOf(valid({ buttonUrl: ok }))), [], ok);
  }
  for (const bad of ['javascript:alert(1)', 'ftp://x', 'banatalk.com']) {
    assert.ok((await errorsOf(valid({ buttonUrl: bad }))).includes('buttonUrl'), bad);
  }
});

test('enums: status, platforms, languages, delivery.state', async () => {
  assert.ok((await errorsOf(valid({ status: 'paused' }))).includes('status'));
  assert.ok((await errorsOf(valid({ platforms: ['web'] }))).some((k) => k.startsWith('platforms')));
  assert.ok((await errorsOf(valid({ languages: ['xx'] }))).some((k) => k.startsWith('languages')));
  assert.ok((await errorsOf(valid({ delivery: { state: 'sent' } }))).includes('delivery.state'));
});

test('endsAt must be after startsAt (except once ended)', async () => {
  const startsAt = new Date('2026-11-01T00:00:00Z');
  assert.ok((await errorsOf(valid({ startsAt, endsAt: startsAt }))).includes('endsAt'));
  assert.deepEqual((await errorsOf(valid({ status: 'ended', startsAt, endsAt: new Date('2026-10-01T00:00:00Z') }))), []);
});

test('the live-selection index exists', () => {
  const keys = Announcement.schema.indexes().map(([k]) => JSON.stringify(k));
  assert.ok(keys.includes(JSON.stringify({ status: 1, startsAt: 1, endsAt: 1 })));
});
```
- [ ] Step 2: run → fails `Cannot find module '../models/Announcement'`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/announcementModel.test.js`
- [ ] Step 3: create `BACKEND/models/Announcement.js`
```js
'use strict';

/**
 * Admin-managed announcement (spec 2026-10-12 §5.1). Several can be live at
 * once. Text is per template locale (lib/normalizeLocale.js SUPPORTED_LOCALES)
 * with `defaultLocale` as the fallback every reader uses.
 *
 * Live = status in (scheduled, live) && startsAt <= now && (endsAt null ||
 * endsAt > now). jobs/announcementJob.js moves the status to match.
 *
 * delivery.* is owned by services/announcementDelivery.js: `state` is claimed
 * atomically (none|queued -> running), `cursor` is the last User _id done and
 * `heartbeatAt` is touched every batch, so a restart resumes instead of
 * re-sending.
 */
const mongoose = require('mongoose');
const { SUPPORTED_LOCALES } = require('../lib/normalizeLocale');

const STATUSES = ['draft', 'scheduled', 'live', 'ended'];
const DELIVERY_STATES = ['none', 'queued', 'running', 'done', 'failed'];
const PLATFORMS = ['all', 'ios', 'android'];
const LIMITS = { title: 100, body: 1000, buttonLabel: 40, buttonUrl: 500, emoji: 16 };
// http(s) opens in the browser; bananatalk:// and "/path" go through the app router.
const BUTTON_URL_RE = /^(https?:\/\/\S+|bananatalk:\/\/\S+|\/\S*)$/;

const TranslationSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true, maxlength: LIMITS.title },
  body: { type: String, required: true, trim: true, maxlength: LIMITS.body },
  buttonLabel: { type: String, trim: true, maxlength: LIMITS.buttonLabel, default: '' },
}, { _id: false });

const AnnouncementSchema = new mongoose.Schema({
  status: { type: String, enum: STATUSES, default: 'draft' },
  priority: { type: Number, default: 0 },
  translations: { type: Map, of: TranslationSchema, default: () => new Map() },
  defaultLocale: { type: String, enum: SUPPORTED_LOCALES, default: 'en' },
  emoji: { type: String, trim: true, maxlength: LIMITS.emoji, default: '📢' },
  imageUrl: { type: String, default: null },
  buttonUrl: {
    type: String,
    trim: true,
    default: null,
    maxlength: LIMITS.buttonUrl,
    validate: {
      validator: (v) => v === null || v === undefined || v === '' || BUTTON_URL_RE.test(v),
      message: 'buttonUrl must be http(s)://…, bananatalk://… or an app path starting with /',
    },
  },
  platforms: { type: [{ type: String, enum: PLATFORMS }], default: ['all'] },
  // Empty = every app language.
  languages: { type: [{ type: String, enum: SUPPORTED_LOCALES }], default: [] },
  startsAt: { type: Date, default: null },
  endsAt: { type: Date, default: null },
  showInApp: { type: Boolean, default: true },
  notify: { type: Boolean, default: false },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  publishedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  publishedAt: { type: Date, default: null },
  endedAt: { type: Date, default: null },
  delivery: {
    state: { type: String, enum: DELIVERY_STATES, default: 'none' },
    targeted: { type: Number, default: 0 },
    pushed: { type: Number, default: 0 },
    listed: { type: Number, default: 0 },
    failed: { type: Number, default: 0 },
    startedAt: { type: Date, default: null },
    finishedAt: { type: Date, default: null },
    heartbeatAt: { type: Date, default: null },
    cursor: { type: mongoose.Schema.Types.ObjectId, default: null },
    error: { type: String, default: null },
  },
}, { timestamps: true });

AnnouncementSchema.index({ status: 1, startsAt: 1, endsAt: 1 });

AnnouncementSchema.pre('validate', function checkCrossFields(next) {
  const keys = this.translations ? [...this.translations.keys()] : [];
  const unknown = keys.filter((k) => !SUPPORTED_LOCALES.includes(k));
  if (unknown.length) {
    this.invalidate('translations', `Unsupported locale(s): ${unknown.join(', ')}`);
  } else if (!keys.includes(this.defaultLocale)) {
    this.invalidate('translations', `A translation for the default locale (${this.defaultLocale}) is required`);
  }
  if (this.status !== 'ended' && this.startsAt && this.endsAt && this.endsAt <= this.startsAt) {
    this.invalidate('endsAt', 'endsAt must be after startsAt');
  }
  next();
});

AnnouncementSchema.statics.STATUSES = STATUSES;
AnnouncementSchema.statics.DELIVERY_STATES = DELIVERY_STATES;
AnnouncementSchema.statics.PLATFORMS = PLATFORMS;
AnnouncementSchema.statics.LIMITS = LIMITS;
AnnouncementSchema.statics.BUTTON_URL_RE = BUTTON_URL_RE;

module.exports = mongoose.model('Announcement', AnnouncementSchema);
```
- [ ] Step 4: run → 9 passing.
- [ ] Step 5: commit
```
git add models/Announcement.js test/announcementModel.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): Announcement model

DB-backed announcements per spec 2026-10-12 §5.1: per-locale text with a
required default locale, platform/language targeting, schedule window,
in-app/notify switches and delivery bookkeeping for resumable sends.

REMAINING_WORK: added section 'Announcements (2026-10-12)' with B1-B11 and
W1-W5; ticked B1.
Still open: B2-B11, W1-W5, O1b crash tickets.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Backend REMAINING_WORK section added in this commit:
```md
## Announcements (2026-10-12) — plan bananatalk_app/docs/superpowers/plans/parts/10-ops-backend-web.md
- [x] B1 model
- [ ] B2 notification row + `announcements` setting · B3 selection service · B4 app-config list · B5 admin CRUD · B6 delivery · B7 publish/end/audience-count · B8 image upload · B9 minute job · B10 user detail route · B11 `banReason` field
- [ ] Owner, after deploy: `db.notifications.getIndexes()` shows `announcement_once_per_user`; `ANNOUNCEMENT_JOB_ENABLED` unset (= on) only after docs/ops/2026-10-pm2-restarts.md is written
```

### Task B2: `announcement` notification rows + `notificationSettings.announcements`

**Files:** Modify `BACKEND/models/Notification.js`, `BACKEND/models/User.js`, `BACKEND/controllers/notifications.js` (`updateSettings` whitelist), `BACKEND/jobs/notificationJobs.js` (`cleanupOldNotifications`), `BACKEND/test/notificationTypeEnum.test.js`; Test `BACKEND/test/announcementNotificationRow.test.js`
**Interfaces:** Produces `Notification { userId, type: 'announcement', title, body, data: { announcementId } }` with unique partial index `{ userId:1, type:1, 'data.announcementId':1 }` (contract says `user`; the real field is `userId` — see Contradictions), `Notification.ensureAnnouncementIndex()`, `notificationSettings.announcements` (Boolean, default true).

- [ ] Step 1: failing test `BACKEND/test/announcementNotificationRow.test.js`
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { startDb, stopDb, makeUser, asHandler, silence } = require('./helpers/callKit');

let Notification, User;
test.before(async () => {
  await startDb('announcementRow');
  Notification = require('../models/Notification');
  User = require('../models/User');
  await Notification.ensureAnnouncementIndex();
});
test.after(stopDb);

test('one announcement row per user per announcement (unique partial index)', async () => {
  const u = await makeUser('row-a');
  const announcementId = String(new mongoose.Types.ObjectId());
  const row = { userId: u._id, type: 'announcement', title: 't', body: 'b', data: { announcementId }, expiresAt: null };
  await Notification.create(row);
  await assert.rejects(Notification.create(row), (err) => err.code === 11000);
});

test('the index does not constrain other types', async () => {
  const u = await makeUser('row-b');
  const row = { userId: u._id, type: 'system', title: 't', body: 'b', data: {} };
  await Notification.create(row);
  await Notification.create(row);
  assert.equal(await Notification.countDocuments({ userId: u._id, type: 'system' }), 2);
});

test('announcement rows survive the 30-day cleanup; others do not', async () => {
  const restore = silence();
  try {
    const u = await makeUser('row-c');
    const old = new Date(Date.now() - 40 * 86400000);
    await Notification.create({ userId: u._id, type: 'announcement', title: 't', body: 'b', data: { announcementId: 'x1' }, sentAt: old, expiresAt: null });
    await Notification.create({ userId: u._id, type: 'system', title: 't', body: 'b', sentAt: old });
    const { cleanupOldNotifications } = require('../jobs/notificationJobs');
    await cleanupOldNotifications();
    assert.equal(await Notification.countDocuments({ userId: u._id, type: 'announcement' }), 1);
    assert.equal(await Notification.countDocuments({ userId: u._id, type: 'system' }), 0);
  } finally { restore(); }
});

test('notificationSettings.announcements defaults to true and is writable via updateSettings', async () => {
  const u = await makeUser('row-d');
  assert.equal(u.notificationSettings.announcements, true);
  const { updateSettings } = require('../controllers/notifications');
  const out = await asHandler(updateSettings)({ user: { id: String(u._id) }, body: { announcements: false } });
  assert.equal(out.status, 200);
  assert.equal((await User.findById(u._id)).notificationSettings.announcements, false);
});
```
- [ ] Step 2: run → fails (`ValidationError: type 'announcement' is not a valid enum value`)
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/announcementNotificationRow.test.js`
- [ ] Step 3: implement
  - `models/Notification.js`, append to the `type.enum` array after `'boost_receipt',`:
```js
      // Announcements (spec 2026-10-12 §5.1) — written by
      // services/announcementDelivery.js with Notification.create directly
      // (never via notificationService.send), one row per user, permanent
      // (expiresAt null, skipped by cleanupOldNotifications). NOT added to
      // fcmService.NOTIFICATION_TYPE_ENUM on purpose: a quiet-hours audit row
      // written by sendToUser must fall back to 'system', or it would collide
      // with the unique index below.
      'announcement',
```
    and after `NotificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });`:
```js
// Delivery idempotency: a resumed or doubled announcement send can never
// list (or push) twice for the same user. Partial, so no other type is touched.
const ANNOUNCEMENT_INDEX_KEY = { userId: 1, type: 1, 'data.announcementId': 1 };
const ANNOUNCEMENT_INDEX_OPTIONS = {
  unique: true,
  partialFilterExpression: { type: 'announcement' },
  name: 'announcement_once_per_user',
  background: true,
};
NotificationSchema.index(ANNOUNCEMENT_INDEX_KEY, ANNOUNCEMENT_INDEX_OPTIONS);

// Built explicitly, not via Model.init()/autoIndex: this schema declares
// expiresAt twice (`index: true` on the path AND the TTL index below it), so
// Mongoose's own index build fails on expiresAt_1 ("equivalent index already
// exists with different options") and never reaches later indexes. Idempotent.
NotificationSchema.statics.ensureAnnouncementIndex = function ensureAnnouncementIndex() {
  return this.collection.createIndex(ANNOUNCEMENT_INDEX_KEY, ANNOUNCEMENT_INDEX_OPTIONS);
};
```
  - `models/User.js`, inside `notificationSettings` after `dailyDropReminders: {…},`:
```js
    // Admin announcements (spec 2026-10-12 §5.1). Push only — the
    // notifications-list row is always written.
    announcements: {
      type: Boolean,
      default: true
    },
```
  - `controllers/notifications.js` `updateSettings`: change the last line of `allowedFields` to
```js
    'streakReminders', 'vocabularyReviewReminders', 'dailyDropReminders',
    // Admin announcements: push opt-out (the in-app row is always written).
    'announcements'
```
  - `jobs/notificationJobs.js` `cleanupOldNotifications`: replace the `deleteMany` filter with
```js
    const result = await Notification.deleteMany({
      sentAt: { $lt: thirtyDaysAgo },
      // Announcement rows are the permanent notifications-list entry
      // (spec 2026-10-12 §5.1) and carry expiresAt: null for the TTL index.
      type: { $ne: 'announcement' }
    });
```
  - `test/notificationTypeEnum.test.js`: add `'announcement'` to the `excluded` array in the last test with the comment `// services/announcementDelivery.js writes these rows itself (Notification.create) and sends raw fcmService.sendToUser; deliberately absent from fcmService.NOTIFICATION_TYPE_ENUM.`
- [ ] Step 4: run Step 2's command → 4 passing; also run `test/notificationTypeEnum.test.js` and `test/broadcastNotification.test.js` → passing.
- [ ] Step 5: commit
```
git add models/Notification.js models/User.js controllers/notifications.js jobs/notificationJobs.js test/announcementNotificationRow.test.js test/notificationTypeEnum.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): permanent per-user notification row + push opt-out

Notification type 'announcement' with a unique partial index (one row per
user per announcement), excluded from the 30-day cleanup; new
notificationSettings.announcements (default on) writable via settings.

REMAINING_WORK: ticked B2; added 'models/Notification.js declares expiresAt
twice (path index + TTL) so Mongoose autoIndex fails on it; drop the path-level
index: true after checking prod getIndexes()'.
Still open: B3-B11, W1-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task B3: `services/announcementService.js` — selection, public shape, audience

**Files:** Create `BACKEND/services/announcementService.js`; Test `BACKEND/test/announcementService.test.js`
**Interfaces:** Produces `liveAnnouncementsFor({ platform, language, now })`, `toPublic(doc, language)`, `audienceQuery(doc)`, plus `liveFilter(now)`, `requestLanguage(req, fallback)`.

- [ ] Step 1: failing test `BACKEND/test/announcementService.test.js`
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser } = require('./helpers/callKit');

let Announcement, User, svc;
const NOW = new Date('2026-10-20T12:00:00Z');
const H = 3600000;

test.before(async () => {
  await startDb('announcementService');
  Announcement = require('../models/Announcement');
  User = require('../models/User');
  svc = require('../services/announcementService');
});
test.after(stopDb);
test.beforeEach(() => Announcement.deleteMany({}));

const make = (over = {}) => Announcement.create({
  translations: {
    en: { title: 'EN title', body: 'EN body', buttonLabel: 'Go' },
    ko: { title: 'KO 제목', body: 'KO 본문', buttonLabel: '가기' },
  },
  defaultLocale: 'en',
  status: 'live',
  startsAt: new Date(NOW.getTime() - H),
  ...over,
});

test('only live-window, showInApp announcements are returned', async () => {
  await make({ priority: 1 });
  await make({ status: 'draft' });
  await make({ status: 'ended' });
  await make({ startsAt: new Date(NOW.getTime() + H), status: 'scheduled' });
  await make({ endsAt: NOW });
  await make({ showInApp: false });
  const due = await make({ status: 'scheduled' }); // job has not flipped it yet; still live by time
  const out = await svc.liveAnnouncementsFor({ platform: 'ios', language: 'en', now: NOW });
  assert.equal(out.length, 2);
  assert.ok(out.some((a) => a.id === String(due._id)));
});

test('sorted by priority desc, then startsAt desc', async () => {
  const low = await make({ priority: 0, startsAt: new Date(NOW.getTime() - 2 * H) });
  const newer = await make({ priority: 0, startsAt: new Date(NOW.getTime() - H) });
  const high = await make({ priority: 5, startsAt: new Date(NOW.getTime() - 3 * H) });
  const out = await svc.liveAnnouncementsFor({ platform: 'android', language: 'en', now: NOW });
  assert.deepEqual(out.map((a) => a.id), [high, newer, low].map((d) => String(d._id)));
});

test('platform targeting: all matches everyone; ios matches only ios', async () => {
  await make({ platforms: ['ios'] });
  await make({ platforms: ['all'] });
  assert.equal((await svc.liveAnnouncementsFor({ platform: 'ios', language: 'en', now: NOW })).length, 2);
  assert.equal((await svc.liveAnnouncementsFor({ platform: 'android', language: 'en', now: NOW })).length, 1);
  assert.equal((await svc.liveAnnouncementsFor({ platform: '', language: 'en', now: NOW })).length, 1);
});

test('language targeting and text fallback to the default locale', async () => {
  await make({ languages: ['ko'] });
  await make({ languages: [] });
  const ko = await svc.liveAnnouncementsFor({ platform: 'ios', language: 'ko-KR', now: NOW });
  assert.equal(ko.length, 2);
  assert.ok(ko.every((a) => a.title === 'KO 제목'));
  const fr = await svc.liveAnnouncementsFor({ platform: 'ios', language: 'fr', now: NOW });
  assert.equal(fr.length, 1);
  assert.equal(fr[0].title, 'EN title');
});

test('toPublic has exactly the contract keys', async () => {
  const doc = await make({ emoji: '🎉', imageUrl: 'https://cdn/x.png', buttonUrl: '/study', priority: 3 });
  const pub = svc.toPublic(doc, 'ko');
  assert.deepEqual(Object.keys(pub).sort(),
    ['body', 'buttonLabel', 'buttonUrl', 'emoji', 'id', 'imageUrl', 'priority', 'title']);
  assert.equal(pub.buttonLabel, '가기');
  assert.equal(pub.priority, 3);
  const lean = svc.toPublic(await Announcement.findById(doc._id).lean(), 'ko');
  assert.equal(lean.title, 'KO 제목');
});

test('audienceQuery: banned excluded, platform via token or signup, en includes unknown locale', async () => {
  await User.deleteMany({});
  const iosTok = await makeUser('ios-tok', { preferredLocale: 'ko', fcmTokens: [{ token: 't1', platform: 'ios', deviceId: 'd1' }] });
  const iosSignup = await makeUser('ios-signup', { preferredLocale: null, signupPlatform: 'ios' });
  const android = await makeUser('android', { preferredLocale: 'en', signupPlatform: 'android' });
  await makeUser('banned', { isBanned: true, signupPlatform: 'ios', preferredLocale: 'ko' });

  const ids = async (doc) => (await User.find(svc.audienceQuery(doc)).select('_id').lean()).map((u) => String(u._id)).sort();
  assert.deepEqual(await ids({ platforms: ['all'], languages: [] }), [iosTok, iosSignup, android].map((u) => String(u._id)).sort());
  assert.deepEqual(await ids({ platforms: ['ios'], languages: [] }), [iosTok, iosSignup].map((u) => String(u._id)).sort());
  assert.deepEqual(await ids({ platforms: ['all'], languages: ['ko'] }), [String(iosTok._id)]);
  assert.deepEqual(await ids({ platforms: ['all'], languages: ['en'] }), [iosSignup, android].map((u) => String(u._id)).sort());
});

test('requestLanguage: ?lang, then fallback, then Accept-Language, then en', () => {
  assert.equal(svc.requestLanguage({ query: { lang: 'zh-Hant-TW' }, headers: {} }), 'zh_TW');
  assert.equal(svc.requestLanguage({ query: {}, headers: {} }, 'ko'), 'ko');
  assert.equal(svc.requestLanguage({ query: {}, headers: { 'accept-language': 'ja-JP,ja;q=0.9' } }), 'ja');
  assert.equal(svc.requestLanguage({ query: { lang: 'klingon' }, headers: {} }), 'en');
});
```
- [ ] Step 2: run → fails `Cannot find module '../services/announcementService'`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/announcementService.test.js`
- [ ] Step 3: create `BACKEND/services/announcementService.js`
```js
'use strict';

/**
 * Read side of announcements (spec 2026-10-12 §5.1): which ones are live for
 * a caller, the public shape the app parses, and who a send targets.
 */
const Announcement = require('../models/Announcement');
const { normalizeLocale } = require('../lib/normalizeLocale');

const LIVE_STATUSES = ['scheduled', 'live'];

/** Live by time, whether or not the minute job has flipped the status yet. */
function liveFilter(now = new Date()) {
  return {
    status: { $in: LIVE_STATUSES },
    startsAt: { $ne: null, $lte: now },
    $or: [{ endsAt: null }, { endsAt: { $gt: now } }],
  };
}

/** Works for a Mongoose doc (Map) and a lean doc (plain object). */
function translationFor(doc, language) {
  const tr = doc.translations || {};
  const get = (key) => (typeof tr.get === 'function' ? tr.get(key) : tr[key]) || null;
  return get(language) || get(doc.defaultLocale) || { title: '', body: '', buttonLabel: '' };
}

/** PublicAnnouncement — the exact shape app-config and GET /announcements/:id return. */
function toPublic(doc, language) {
  const t = translationFor(doc, language);
  return {
    id: String(doc._id),
    title: t.title || '',
    body: t.body || '',
    emoji: doc.emoji || null,
    imageUrl: doc.imageUrl || null,
    buttonLabel: t.buttonLabel || null,
    buttonUrl: doc.buttonUrl || null,
    priority: doc.priority || 0,
  };
}

const matchesPlatform = (doc, platform) => {
  const p = doc.platforms || [];
  return p.length === 0 || p.includes('all') || (Boolean(platform) && p.includes(platform));
};

const matchesLanguage = (doc, language) =>
  !doc.languages || doc.languages.length === 0 || doc.languages.includes(language);

async function liveAnnouncementsFor({ platform, language, now = new Date() }) {
  const lang = normalizeLocale(language) || 'en';
  const docs = await Announcement.find({ ...liveFilter(now), showInApp: true })
    .sort({ priority: -1, startsAt: -1 })
    .lean();
  return docs
    .filter((d) => matchesPlatform(d, platform) && matchesLanguage(d, lang))
    .map((d) => toPublic(d, lang));
}

/**
 * Mongo filter on User for an announcement's targeting. Platform matches a
 * token registered on that platform OR the signup platform (65% hold no
 * token, and they still get the notifications-list row). A user with no
 * known locale reads English, so 'en' targeting includes preferredLocale null.
 */
function audienceQuery(doc) {
  const and = [{ isBanned: { $ne: true } }];
  const platforms = doc.platforms || [];
  if (platforms.length && !platforms.includes('all')) {
    and.push({ $or: [
      { 'fcmTokens.platform': { $in: platforms } },
      { signupPlatform: { $in: platforms } },
    ] });
  }
  const languages = doc.languages || [];
  if (languages.length) {
    const or = [{ preferredLocale: { $in: languages } }];
    if (languages.includes('en')) or.push({ preferredLocale: null });
    and.push({ $or: or });
  }
  return and.length === 1 ? and[0] : { $and: and };
}

/** ?lang → fallback (e.g. user.preferredLocale) → Accept-Language → 'en'. */
function requestLanguage(req, fallback = null) {
  const q = req && req.query ? req.query.lang : null;
  const fromQuery = normalizeLocale(typeof q === 'string' ? q : '');
  if (fromQuery) return fromQuery;
  const fromFallback = normalizeLocale(fallback || '');
  if (fromFallback) return fromFallback;
  const header = (req && req.headers && req.headers['accept-language']) || '';
  const first = String(header).split(',')[0].split(';')[0].trim();
  return normalizeLocale(first) || 'en';
}

module.exports = { liveAnnouncementsFor, toPublic, audienceQuery, liveFilter, requestLanguage, translationFor };
```
- [ ] Step 4: run → 7 passing.
- [ ] Step 5: commit
```
git add services/announcementService.js test/announcementService.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): live selection, public shape and audience query

REMAINING_WORK: ticked B3.
Still open: B4-B11, W1-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task B4: app-config `announcements` list + legacy `announcement` from the DB

**Files:** Modify `BACKEND/controllers/appConfig.js`; Test `BACKEND/test/appConfigAnnouncements.test.js`
**Interfaces:** Consumes `liveAnnouncementsFor`, `requestLanguage`. Produces `data.announcements: PublicAnnouncement[]` and the legacy `data.announcement` (`{active,id,title,body,emoji,buttonLabel,buttonUrl}`).

- [ ] Step 1: failing test `BACKEND/test/appConfigAnnouncements.test.js`
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, asHandler } = require('./helpers/callKit');

let Announcement, getAppConfig;
const ENV_KEYS = ['ANNOUNCEMENT_ACTIVE', 'ANNOUNCEMENT_ID', 'ANNOUNCEMENT_TITLE', 'ANNOUNCEMENT_BODY'];

test.before(async () => {
  await startDb('appConfigAnnouncements');
  Announcement = require('../models/Announcement');
  ({ getAppConfig } = require('../controllers/appConfig'));
});
test.after(stopDb);
test.beforeEach(async () => {
  await Announcement.deleteMany({});
  for (const k of ENV_KEYS) delete process.env[k];
});

const live = (over = {}) => Announcement.create({
  translations: { en: { title: 'DB en', body: 'b' }, ko: { title: 'DB ko', body: 'b' } },
  defaultLocale: 'en', status: 'live', startsAt: new Date(Date.now() - 60000), ...over,
});
const call = (query, headers = {}) => asHandler(getAppConfig)({ query, headers });

test('announcements lists live DB announcements in the caller language, highest priority first', async () => {
  const a = await live({ priority: 1 });
  const b = await live({ priority: 9 });
  const { body } = await call({ platform: 'ios', lang: 'ko' });
  assert.deepEqual(body.data.announcements.map((x) => x.id), [String(b._id), String(a._id)]);
  assert.equal(body.data.announcements[0].title, 'DB ko');
});

test('legacy single field = the top DB announcement', async () => {
  const top = await live({ priority: 9, emoji: '🎉', buttonUrl: '/study' });
  const { body } = await call({ platform: 'android' });
  assert.deepEqual(body.data.announcement, {
    active: true, id: String(top._id), title: 'DB en', body: 'b', emoji: '🎉', buttonLabel: '', buttonUrl: '/study',
  });
});

test('no DB announcement: legacy field and list fall back to the env one', async () => {
  Object.assign(process.env, { ANNOUNCEMENT_ACTIVE: 'true', ANNOUNCEMENT_ID: 'env-1', ANNOUNCEMENT_TITLE: 'Env', ANNOUNCEMENT_BODY: 'From env' });
  const { body } = await call({ platform: 'ios' });
  assert.equal(body.data.announcement.id, 'env-1');
  assert.equal(body.data.announcement.active, true);
  assert.deepEqual(body.data.announcements.map((x) => x.id), ['env-1']);
});

test('nothing anywhere: inactive legacy field, empty list', async () => {
  const { body } = await call({ platform: 'ios' });
  assert.equal(body.data.announcement.active, false);
  assert.deepEqual(body.data.announcements, []);
});

test('a DB failure never breaks app-config', async () => {
  const original = Announcement.find;
  Announcement.find = () => { throw new Error('db down'); };
  try {
    const { status, body } = await call({ platform: 'ios' });
    assert.equal(status, 200);
    assert.deepEqual(body.data.announcements, []);
  } finally { Announcement.find = original; }
});
```
- [ ] Step 2: run → fails (`body.data.announcements` is `undefined`)
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/appConfigAnnouncements.test.js`
- [ ] Step 3: implement in `BACKEND/controllers/appConfig.js`
  - add after the `REWARDED_FEATURES` require:
```js
const mongoose = require('mongoose');
const { liveAnnouncementsFor, requestLanguage } = require('../services/announcementService');

/**
 * DB announcements (spec 2026-10-12 §5.1). app-config is launch-critical and
 * unauthenticated, so any failure here — including no DB connection, which
 * would otherwise buffer for 10 s — degrades to "no DB announcements".
 */
async function dbAnnouncements(platform, language) {
  if (mongoose.connection.readyState !== 1) return [];
  try {
    return await liveAnnouncementsFor({ platform, language, now: new Date() });
  } catch (err) {
    console.error('[appConfig] announcements unavailable:', err.message);
    return [];
  }
}
```
  - in `getAppConfig`, rename the existing `const announcement = { … };` object to `const envAnnouncement = { … };` (contents unchanged) and add directly after it:
```js
  const announcements = await dbAnnouncements(platform, requestLanguage(req));
  if (announcements.length === 0 && envAnnouncement.active) {
    // New builds read only the list; keep the env fallback reachable there too.
    announcements.push({
      id: envAnnouncement.id, title: envAnnouncement.title, body: envAnnouncement.body,
      emoji: envAnnouncement.emoji || null, imageUrl: null,
      buttonLabel: envAnnouncement.buttonLabel || null, buttonUrl: envAnnouncement.buttonUrl || null,
      priority: 0,
    });
  }
  const top = announcements[0];
  // Live builds read only this single field; it must stay a string-valued
  // { active, id, title, body, emoji, buttonLabel, buttonUrl }.
  const announcement = top
    ? {
      active: true, id: top.id, title: top.title, body: top.body,
      emoji: top.emoji || '📢', buttonLabel: top.buttonLabel || '', buttonUrl: top.buttonUrl || '',
    }
    : envAnnouncement;
```
  - in the response `data`, after `announcement,` add `announcements,`.
- [ ] Step 4: run → 5 passing; `test/conversationCapKillSwitch.test.js` still passing (no DB connection there → `[]` without the 10 s buffer).
- [ ] Step 5: commit
```
git add controllers/appConfig.js test/appConfigAnnouncements.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): app-config returns live announcements

New 'announcements' list in the caller's language (?lang, Accept-Language,
en); legacy single 'announcement' is the top DB one, else the env one, so
live builds keep working.

REMAINING_WORK: ticked B4.
Still open: B5-B11, W1-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task B5: admin CRUD routes (list / get / create / update / delete), audited

**Files:** Create `BACKEND/controllers/adminAnnouncements.js`, `BACKEND/routes/adminAnnouncements.js`; Modify `BACKEND/server.js`; Test `BACKEND/test/adminAnnouncements.crud.test.js`
**Interfaces:** Produces `GET /api/v1/admin/announcements?status=`, `GET /:id`, `POST /`, `PUT /:id`, `DELETE /:id`, responses `{ success, data }`; audit actions `announcement.create|update|delete` (`targetType: 'announcement'`). Each `data` row is the full document with `translations` flattened to an object and `id`.

- [ ] Step 1: failing test `BACKEND/test/adminAnnouncements.crud.test.js`
```js
'use strict';
process.env.JWT_SECRET = process.env.JWT_SECRET && process.env.JWT_SECRET.length >= 32
  ? process.env.JWT_SECRET : 'test-secret-that-is-long-enough-to-pass-0123456789';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const express = require('express');
const request = require('supertest');
const { startDb, stopDb, makeUser } = require('./helpers/callKit');

let app, Announcement, AdminAuditLog, admin, user;
const tokenFor = (u) => jwt.sign({ id: String(u._id) }, process.env.JWT_SECRET, { expiresIn: '1h' });
const as = (u) => ({ Authorization: `Bearer ${tokenFor(u)}` });
const BASE = '/api/v1/admin/announcements';
const BODY = {
  translations: { en: { title: 'Hi', body: 'There', buttonLabel: 'Open' } },
  defaultLocale: 'en', buttonUrl: 'https://banatalk.com', platforms: ['ios'], languages: ['ko'],
  priority: 2, showInApp: true, notify: false,
};

test.before(async () => {
  await startDb('adminAnnouncementsCrud');
  Announcement = require('../models/Announcement');
  AdminAuditLog = require('../models/AdminAuditLog');
  admin = await makeUser('admin', { role: 'admin' });
  user = await makeUser('plain');
  app = express();
  app.use(express.json());
  app.use(BASE, require('../routes/adminAnnouncements'));
  app.use(require('../middleware/error'));
});
test.after(stopDb);
test.beforeEach(() => Promise.all([Announcement.deleteMany({}), AdminAuditLog.deleteMany({})]));

test('non-admins get 403, anonymous 401', async () => {
  assert.equal((await request(app).get(BASE)).status, 401);
  assert.equal((await request(app).get(BASE).set(as(user))).status, 403);
});

test('create makes a draft, records createdBy, audits', async () => {
  const res = await request(app).post(BASE).set(as(admin)).send({ ...BODY, status: 'live' });
  assert.equal(res.status, 201);
  assert.equal(res.body.data.status, 'draft', 'status is not writable');
  assert.equal(res.body.data.translations.en.title, 'Hi');
  assert.equal(String(res.body.data.createdBy), String(admin._id));
  const log = await AdminAuditLog.findOne({ action: 'announcement.create' }).lean();
  assert.equal(log.targetType, 'announcement');
  assert.equal(String(log.target), res.body.data.id);
});

test('validation errors are 400 with the field message', async () => {
  const noDefault = await request(app).post(BASE).set(as(admin)).send({ ...BODY, defaultLocale: 'ko' });
  assert.equal(noDefault.status, 400);
  const badDate = await request(app).post(BASE).set(as(admin)).send({ ...BODY, startsAt: 'tomorrow' });
  assert.equal(badDate.status, 400);
  assert.match(badDate.body.message, /startsAt/);
  const badUrl = await request(app).post(BASE).set(as(admin)).send({ ...BODY, buttonUrl: 'javascript:x' });
  assert.equal(badUrl.status, 400);
});

test('list filters by status, newest first; get by id; bad id 404', async () => {
  const a = await Announcement.create({ ...BODY, status: 'draft' });
  const b = await Announcement.create({ ...BODY, status: 'live', startsAt: new Date() });
  const all = await request(app).get(BASE).set(as(admin));
  assert.deepEqual(all.body.data.map((x) => x.id), [String(b._id), String(a._id)]);
  const live = await request(app).get(`${BASE}?status=live`).set(as(admin));
  assert.deepEqual(live.body.data.map((x) => x.id), [String(b._id)]);
  assert.equal((await request(app).get(`${BASE}/${a._id}`).set(as(admin))).body.data.id, String(a._id));
  assert.equal((await request(app).get(`${BASE}/nope`).set(as(admin))).status, 404);
  assert.equal((await request(app).get(`${BASE}/${new mongoose.Types.ObjectId()}`).set(as(admin))).status, 404);
});

test('update: draft/scheduled edit everything; live only text, endsAt, priority; ended nothing', async () => {
  const draft = await Announcement.create(BODY);
  const ok = await request(app).put(`${BASE}/${draft._id}`).set(as(admin)).send({ platforms: ['all'], priority: 7 });
  assert.equal(ok.status, 200);
  assert.deepEqual(ok.body.data.platforms, ['all']);

  const live = await Announcement.create({ ...BODY, status: 'live', startsAt: new Date() });
  const text = await request(app).put(`${BASE}/${live._id}`).set(as(admin))
    .send({ translations: { en: { title: 'Edited', body: 'There' } }, priority: 1 });
  assert.equal(text.status, 200);
  assert.equal(text.body.data.translations.en.title, 'Edited');
  const targeting = await request(app).put(`${BASE}/${live._id}`).set(as(admin)).send({ platforms: ['all'] });
  assert.equal(targeting.status, 400);

  const ended = await Announcement.create({ ...BODY, status: 'ended' });
  assert.equal((await request(app).put(`${BASE}/${ended._id}`).set(as(admin)).send({ priority: 1 })).status, 400);
  assert.ok(await AdminAuditLog.findOne({ action: 'announcement.update' }));
});

test('delete: drafts only', async () => {
  const live = await Announcement.create({ ...BODY, status: 'live', startsAt: new Date() });
  assert.equal((await request(app).delete(`${BASE}/${live._id}`).set(as(admin))).status, 400);
  const draft = await Announcement.create(BODY);
  assert.equal((await request(app).delete(`${BASE}/${draft._id}`).set(as(admin))).status, 200);
  assert.equal(await Announcement.countDocuments({ _id: draft._id }), 0);
  assert.ok(await AdminAuditLog.findOne({ action: 'announcement.delete' }));
});
```
- [ ] Step 2: run → fails `Cannot find module '../routes/adminAnnouncements'`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/adminAnnouncements.crud.test.js`
- [ ] Step 3: implement
  - create `BACKEND/controllers/adminAnnouncements.js` (B6 and B7 append to this file):
```js
'use strict';

/**
 * Admin announcements (spec 2026-10-12 §5.1). Every write is audit-logged
 * through AdminAuditLog.logAction (fire-and-forget, like adminContent.js).
 * Field validation is the model's; this file owns which fields may change in
 * which status.
 */
const mongoose = require('mongoose');
const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const Announcement = require('../models/Announcement');
const AdminAuditLog = require('../models/AdminAuditLog');

const EDITABLE = [
  'translations', 'defaultLocale', 'emoji', 'imageUrl', 'buttonUrl', 'platforms', 'languages',
  'startsAt', 'endsAt', 'showInApp', 'notify', 'priority',
];
// Once live, the audience has seen it: only wording, end time and ordering move.
const LIVE_EDITABLE = ['translations', 'endsAt', 'priority'];
const DATE_FIELDS = ['startsAt', 'endsAt'];

const serialize = (doc) => {
  const obj = doc.toObject({ flattenMaps: true, versionKey: false });
  return { ...obj, id: String(doc._id) };
};

const titleOf = (doc) => {
  const t = doc.translations && doc.translations.get(doc.defaultLocale);
  return t ? t.title : '';
};

const audit = (req, action, doc, details = {}) => AdminAuditLog.logAction({
  moderator: req.user._id,
  action,
  target: doc._id,
  targetType: 'announcement',
  source: 'manual',
  details: { title: titleOf(doc), status: doc.status, ...details },
});

/** A date string Mongoose would turn into a CastError (→ 404 in middleware/error.js) is a 400 here. */
function parseDate(key, value) {
  if (value === null || value === '' || value === undefined) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new ErrorResponse(`${key} is not a valid date`, 400);
  return date;
}

function applyFields(doc, body, allowed) {
  for (const key of allowed) {
    if (!Object.prototype.hasOwnProperty.call(body, key)) continue;
    const value = DATE_FIELDS.includes(key) ? parseDate(key, body[key]) : body[key];
    doc.set(key, value);
  }
}

async function loadById(id) {
  if (!mongoose.isValidObjectId(id)) return null;
  return Announcement.findById(id);
}

const notFound = () => new ErrorResponse('Announcement not found', 404);

// @route GET /api/v1/admin/announcements?status=
exports.listAnnouncements = asyncHandler(async (req, res) => {
  const filter = {};
  if (Announcement.STATUSES.includes(req.query.status)) filter.status = req.query.status;
  const docs = await Announcement.find(filter).sort({ createdAt: -1, _id: -1 }).limit(200);
  res.status(200).json({ success: true, data: docs.map(serialize) });
});

// @route GET /api/v1/admin/announcements/:id
exports.getAnnouncement = asyncHandler(async (req, res, next) => {
  const doc = await loadById(req.params.id);
  if (!doc) return next(notFound());
  res.status(200).json({ success: true, data: serialize(doc) });
});

// @route POST /api/v1/admin/announcements — always a draft
exports.createAnnouncement = asyncHandler(async (req, res) => {
  const doc = new Announcement({ status: 'draft', createdBy: req.user._id });
  applyFields(doc, req.body || {}, EDITABLE);
  await doc.save();
  audit(req, 'announcement.create', doc);
  res.status(201).json({ success: true, data: serialize(doc) });
});

// @route PUT /api/v1/admin/announcements/:id
exports.updateAnnouncement = asyncHandler(async (req, res, next) => {
  const doc = await loadById(req.params.id);
  if (!doc) return next(notFound());
  const body = req.body || {};
  if (doc.status === 'ended') {
    return next(new ErrorResponse('An ended announcement cannot be edited', 400));
  }
  if (doc.status === 'live') {
    const blocked = Object.keys(body).filter((k) => EDITABLE.includes(k) && !LIVE_EDITABLE.includes(k));
    if (blocked.length) {
      return next(new ErrorResponse(`While live only text, end time and priority can change (got: ${blocked.join(', ')})`, 400));
    }
  }
  applyFields(doc, body, doc.status === 'live' ? LIVE_EDITABLE : EDITABLE);
  await doc.save();
  audit(req, 'announcement.update', doc, { fields: Object.keys(body) });
  res.status(200).json({ success: true, data: serialize(doc) });
});

// @route DELETE /api/v1/admin/announcements/:id — drafts only
exports.deleteAnnouncement = asyncHandler(async (req, res, next) => {
  const doc = await loadById(req.params.id);
  if (!doc) return next(notFound());
  if (doc.status !== 'draft') {
    return next(new ErrorResponse('Only a draft can be deleted; end it instead', 400));
  }
  await doc.deleteOne();
  audit(req, 'announcement.delete', doc);
  res.status(200).json({ success: true, data: { id: String(doc._id) } });
});

exports._internals = { serialize, audit, loadById, parseDate, notFound };
```
  - create `BACKEND/routes/adminAnnouncements.js`:
```js
'use strict';
const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const c = require('../controllers/adminAnnouncements');

const router = express.Router();
router.use(protect, authorize('admin'));

router.route('/').get(c.listAnnouncements).post(c.createAnnouncement);
router.route('/:id').get(c.getAnnouncement).put(c.updateAnnouncement).delete(c.deleteAnnouncement);

module.exports = router;
```
  - `BACKEND/server.js`, directly after `app.use('/api/v1/admin/broadcast', broadcast);`:
```js
app.use('/api/v1/admin/announcements', require('./routes/adminAnnouncements'));
```
- [ ] Step 4: run → 6 passing.
- [ ] Step 5: commit
```
git add controllers/adminAnnouncements.js routes/adminAnnouncements.js server.js test/adminAnnouncements.crud.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): admin CRUD with per-status edit rules

/api/v1/admin/announcements list/get/create/update/delete, admin-only and
audit-logged; drafts and scheduled edit everything, live only text/endsAt/
priority, ended nothing; delete is draft-only.

REMAINING_WORK: ticked B5.
Still open: B6-B11, W1-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task B6: `services/announcementDelivery.js` — idempotent, resumable send

**Files:** Create `BACKEND/services/announcementDelivery.js`; Test `BACKEND/test/announcementDelivery.test.js`
**Interfaces:** Consumes `audienceQuery`, `toPublic`, `fcmService.sendToUser`, `isInQuietHours`. Produces `deliver(announcementId[, { now, batchSize }]) -> Promise<{ targeted, pushed, listed, failed }>` (adds `skipped: true` when this call did not claim the delivery), `STALE_MS`, `BATCH_SIZE`. Push data `{ type: 'announcement', announcementId, notificationId }`.

Rules: claim `delivery.state none|queued → running` with one conditional `findOneAndUpdate` (status `live`, `notify: true`); a `running` delivery whose `heartbeatAt` is > 10 min old is re-claimed by the same kind of conditional update and resumes after `delivery.cursor`. Users are read in `_id` order, 500 per batch; after each batch the cursor, heartbeat and counters are persisted. The row insert is the idempotency gate: E11000 → this user was handled by an earlier run → no second push. List row always; push only with `notificationSettings.enabled !== false`, `announcements !== false`, outside quiet hours and an active token.

- [ ] Step 1: failing test `BACKEND/test/announcementDelivery.test.js`
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, makeUser, silence } = require('./helpers/callKit');

let Announcement, Notification, User, fcmService, delivery, pushes, restoreLog;

test.before(async () => {
  await startDb('announcementDelivery');
  Announcement = require('../models/Announcement');
  Notification = require('../models/Notification');
  User = require('../models/User');
  fcmService = require('../services/fcmService');
  delivery = require('../services/announcementDelivery');
  await Notification.ensureAnnouncementIndex();
  restoreLog = silence();
});
test.after(async () => { restoreLog(); await stopDb(); });
test.beforeEach(async () => {
  await Promise.all([Announcement.deleteMany({}), Notification.deleteMany({}), User.deleteMany({})]);
  pushes = [];
  fcmService.sendToUser = async (userId, notification, data) => {
    pushes.push({ userId: String(userId), notification, data });
    return { success: true, delivered: 1, failed: 0 };
  };
});

let seq = 0;
const token = (platform = 'ios') => [{ token: `tok-${++seq}`, platform, deviceId: `dev-${seq}` }];
const hhmm = (d) => d.toISOString().slice(11, 16);
const quietNow = () => ({
  enabled: true, timezone: 'UTC',
  start: hhmm(new Date(Date.now() - 3600000)), end: hhmm(new Date(Date.now() + 3600000)),
});
const liveNotify = (over = {}) => Announcement.create({
  translations: { en: { title: 'Hello', body: 'Body en' }, ko: { title: '안녕', body: '본문' } },
  defaultLocale: 'en', status: 'live', startsAt: new Date(Date.now() - 60000), notify: true,
  imageUrl: 'https://cdn/a.png', ...over,
});
const sortedIds = (users) => users.map((u) => String(u._id)).sort();

test('one row per targeted user; push only where allowed; counters; done', async () => {
  const pushable = await makeUser('pushable', { fcmTokens: token(), preferredLocale: 'ko' });
  const noToken = await makeUser('no-token');
  await makeUser('opted-out', { fcmTokens: token(), notificationSettings: { announcements: false } });
  await makeUser('all-off', { fcmTokens: token(), notificationSettings: { enabled: false } });
  await makeUser('quiet', { fcmTokens: token(), quietHours: quietNow() });
  await makeUser('banned', { fcmTokens: token(), isBanned: true });
  const a = await liveNotify();

  const out = await delivery.deliver(a._id);

  assert.deepEqual(out, { targeted: 5, pushed: 1, listed: 5, failed: 0 });
  assert.equal(await Notification.countDocuments({ type: 'announcement' }), 5);
  assert.deepEqual(pushes.map((p) => p.userId), [String(pushable._id)]);
  assert.equal(pushes[0].notification.title, '안녕', 'push in the user language');
  assert.equal(pushes[0].data.type, 'announcement');
  assert.equal(pushes[0].data.announcementId, String(a._id));
  const row = await Notification.findOne({ userId: pushable._id, type: 'announcement' }).lean();
  assert.equal(row.title, '안녕');
  assert.equal(row.expiresAt, null, 'permanent list entry');
  assert.equal(row.data.announcementId, String(a._id));
  assert.equal(pushes[0].data.notificationId, String(row._id));
  assert.ok(row.deliveredAt);
  assert.equal((await User.findById(noToken._id)).badges.unreadNotifications, 1);
  const after = await Announcement.findById(a._id).lean();
  assert.equal(after.delivery.state, 'done');
  assert.ok(after.delivery.finishedAt);
});

test('two concurrent deliveries (double publish) send once', async () => {
  for (let i = 0; i < 3; i++) await makeUser(`dup-${i}`, { fcmTokens: token() });
  const a = await liveNotify();
  const results = await Promise.all([delivery.deliver(a._id), delivery.deliver(a._id)]);
  assert.equal(pushes.length, 3);
  assert.equal(await Notification.countDocuments({ type: 'announcement' }), 3);
  assert.equal(results.filter((r) => r.skipped === true).length, 1);
});

test('a stale running delivery resumes after its cursor and never re-pushes a listed user', async () => {
  const users = [];
  for (let i = 0; i < 4; i++) users.push(await makeUser(`res-${i}`, { fcmTokens: token() }));
  users.sort((x, y) => String(x._id).localeCompare(String(y._id)));
  const a = await liveNotify();
  // The dead run listed users[0] and users[1], but persisted the cursor only after users[0].
  for (const u of users.slice(0, 2)) {
    await Notification.create({ userId: u._id, type: 'announcement', title: 'Hello', body: 'Body en', data: { announcementId: String(a._id) }, expiresAt: null });
  }
  await Announcement.updateOne({ _id: a._id }, { $set: {
    'delivery.state': 'running', 'delivery.heartbeatAt': new Date(Date.now() - 11 * 60000),
    'delivery.cursor': users[0]._id, 'delivery.targeted': 1, 'delivery.listed': 1, 'delivery.pushed': 1,
  } });

  const out = await delivery.deliver(a._id);

  assert.deepEqual(pushes.map((p) => p.userId).sort(), sortedIds(users.slice(2)));
  assert.equal(await Notification.countDocuments({ type: 'announcement' }), 4);
  assert.equal(out.listed, 3);
  assert.equal(out.targeted, 4);
});

test('a running delivery with a fresh heartbeat is left alone', async () => {
  await makeUser('fresh', { fcmTokens: token() });
  const a = await liveNotify({ delivery: { state: 'running', heartbeatAt: new Date() } });
  const out = await delivery.deliver(a._id);
  assert.equal(out.skipped, true);
  assert.equal(pushes.length, 0);
});

test('batches walk _id order and persist the cursor', async () => {
  for (let i = 0; i < 5; i++) await makeUser(`batch-${i}`);
  const a = await liveNotify();
  const out = await delivery.deliver(a._id, { batchSize: 2 });
  assert.equal(out.listed, 5);
  const last = await User.findOne().sort({ _id: -1 }).lean();
  assert.equal(String((await Announcement.findById(a._id).lean()).delivery.cursor), String(last._id));
});

test('drafts, notify:false and unknown ids are never delivered', async () => {
  await makeUser('never', { fcmTokens: token() });
  assert.equal((await delivery.deliver((await liveNotify({ status: 'draft' }))._id)).skipped, true);
  assert.equal((await delivery.deliver((await liveNotify({ notify: false }))._id)).skipped, true);
  assert.equal((await delivery.deliver('64b000000000000000000000')).skipped, true);
  assert.equal(await Notification.countDocuments({}), 0);
});

test('a failed push counts as failed and keeps the row', async () => {
  await makeUser('fail', { fcmTokens: token() });
  fcmService.sendToUser = async () => ({ success: false, error: 'fcm down' });
  const a = await liveNotify();
  assert.deepEqual(await delivery.deliver(a._id), { targeted: 1, pushed: 0, listed: 1, failed: 1 });
  assert.equal(await Notification.countDocuments({ type: 'announcement' }), 1);
});
```
- [ ] Step 2: run → fails `Cannot find module '../services/announcementDelivery'`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/announcementDelivery.test.js`
- [ ] Step 3: create `BACKEND/services/announcementDelivery.js`
```js
'use strict';

/**
 * Sends an announcement to its audience (spec 2026-10-12 §5.1).
 *
 * Exactly-once per user, across restarts and double publishes:
 *  1. Claim: one conditional update moves delivery.state none|queued → running.
 *     Whoever loses the race gets null and stops. A `running` delivery whose
 *     heartbeat is older than STALE_MS is re-claimed the same way (the process
 *     that owned it died) and resumes after delivery.cursor.
 *  2. Per user, the Notification insert is the gate: the unique partial index
 *     announcement_once_per_user turns a repeat into E11000, and a user whose
 *     row already exists is not pushed again.
 *
 * The list row is always written (it is the only channel for users without a
 * token). Push respects notificationSettings.enabled/announcements and quiet
 * hours; the quiet-hours check happens here, before fcmService, so
 * sendToUser's own quiet-hours audit row is never written for this type.
 */
const Announcement = require('../models/Announcement');
const Notification = require('../models/Notification');
const User = require('../models/User');
const fcmService = require('./fcmService');
const { isInQuietHours } = require('../lib/quietHours');
const { audienceQuery, toPublic } = require('./announcementService');

const BATCH_SIZE = 500;
const PUSH_CONCURRENCY = 25;
const STALE_MS = 10 * 60 * 1000;
const USER_FIELDS = '_id preferredLocale notificationSettings quietHours fcmTokens';

async function claim(id, now) {
  const fresh = await Announcement.findOneAndUpdate(
    { _id: id, status: 'live', notify: true, 'delivery.state': { $in: ['none', 'queued'] } },
    { $set: { 'delivery.state': 'running', 'delivery.startedAt': now, 'delivery.heartbeatAt': now, 'delivery.error': null } },
    { new: true }
  );
  if (fresh) return fresh;
  return Announcement.findOneAndUpdate(
    {
      _id: id,
      status: { $in: ['live', 'ended'] }, // a send that started finishes even if the window closed
      notify: true,
      'delivery.state': 'running',
      'delivery.heartbeatAt': { $lt: new Date(now.getTime() - STALE_MS) },
    },
    { $set: { 'delivery.heartbeatAt': now } },
    { new: true }
  );
}

function wantsPush(user) {
  const s = user.notificationSettings || {};
  if (s.enabled === false || s.announcements === false) return false;
  if (isInQuietHours(user, new Date())) return false;
  return Array.isArray(user.fcmTokens) && user.fcmTokens.some((t) => t.active !== false);
}

async function deliverToUser(doc, user, counts) {
  const text = toPublic(doc, user.preferredLocale || 'en');
  let row;
  try {
    row = await Notification.create({
      userId: user._id,
      type: 'announcement',
      title: text.title,
      body: text.body,
      imageUrl: text.imageUrl,
      data: { announcementId: text.id },
      expiresAt: null,
    });
  } catch (err) {
    if (err && err.code === 11000) return; // handled by an earlier run
    counts.failed += 1;
    console.error('[announcementDelivery] row failed for', String(user._id), err.message);
    return;
  }
  counts.listed += 1;
  await User.updateOne({ _id: user._id }, { $inc: { 'badges.unreadNotifications': 1 } });

  if (!wantsPush(user)) return;
  const result = await fcmService.sendToUser(
    user._id,
    { title: text.title, body: text.body, imageUrl: text.imageUrl || undefined },
    { type: 'announcement', announcementId: text.id, notificationId: String(row._id) }
  );
  if (result && result.success && result.delivered > 0) {
    counts.pushed += 1;
    await Notification.updateOne({ _id: row._id }, { $set: { deliveredAt: new Date() } });
  } else if (!result || result.success === false) {
    counts.failed += 1;
  }
}

async function readCounters(id, extra = {}) {
  const doc = await Announcement.findById(id).select('delivery').lean();
  const d = (doc && doc.delivery) || {};
  return { targeted: d.targeted || 0, pushed: d.pushed || 0, listed: d.listed || 0, failed: d.failed || 0, ...extra };
}

async function deliver(announcementId, { now = new Date(), batchSize = BATCH_SIZE } = {}) {
  await Notification.ensureAnnouncementIndex(); // the idempotency gate must exist before the first insert
  const doc = await claim(announcementId, now);
  if (!doc) return readCounters(announcementId, { skipped: true });

  const base = audienceQuery(doc);
  let cursor = doc.delivery.cursor || null;
  try {
    for (;;) {
      const filter = cursor ? { $and: [base, { _id: { $gt: cursor } }] } : base;
      const users = await User.find(filter).select(USER_FIELDS).sort({ _id: 1 }).limit(batchSize).lean();
      if (users.length === 0) break;

      const counts = { listed: 0, pushed: 0, failed: 0 };
      for (let i = 0; i < users.length; i += PUSH_CONCURRENCY) {
        await Promise.all(users.slice(i, i + PUSH_CONCURRENCY).map((u) => deliverToUser(doc, u, counts)));
      }
      cursor = users[users.length - 1]._id;
      await Announcement.updateOne({ _id: doc._id }, {
        $set: { 'delivery.cursor': cursor, 'delivery.heartbeatAt': new Date() },
        $inc: {
          'delivery.targeted': users.length,
          'delivery.listed': counts.listed,
          'delivery.pushed': counts.pushed,
          'delivery.failed': counts.failed,
        },
      });
    }
    await Announcement.updateOne({ _id: doc._id }, { $set: { 'delivery.state': 'done', 'delivery.finishedAt': new Date() } });
  } catch (err) {
    console.error('[announcementDelivery] failed for', String(doc._id), err.message);
    await Announcement.updateOne({ _id: doc._id }, { $set: {
      'delivery.state': 'failed', 'delivery.error': String(err.message).slice(0, 500), 'delivery.finishedAt': new Date(),
    } });
  }
  return readCounters(doc._id);
}

module.exports = { deliver, STALE_MS, BATCH_SIZE };
```
- [ ] Step 4: run → 7 passing.
- [ ] Step 5: commit
```
git add services/announcementDelivery.js test/announcementDelivery.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): idempotent, resumable delivery

Atomic claim (none|queued -> running), 500-user _id batches with a persisted
cursor and heartbeat, stale (>10 min) runs resumed; one permanent list row per
user gated by the unique index, push in the user's language respecting the
announcements toggle and quiet hours.

REMAINING_WORK: ticked B6.
Still open: B7-B11, W1-W5. Known: a crash mid-batch re-counts that batch in
delivery.targeted (rows and pushes are not repeated).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
REMAINING_WORK (backend) add under the Announcements section: `- [ ] Known: a crash mid-batch re-counts that batch's users in delivery.targeted (rows/pushes are never repeated). Accept unless the stats are used for billing.`

### Task B7: publish / end / audience-count

**Files:** Modify `BACKEND/controllers/adminAnnouncements.js`, `BACKEND/routes/adminAnnouncements.js`; Test `BACKEND/test/adminAnnouncements.publish.test.js`
**Interfaces:** Consumes `audienceQuery`, `announcementDelivery.deliver`. Produces `POST /:id/publish` body `{ at?: ISO }`, `POST /:id/end`, `GET /:id/audience-count` → `{ count, listed }` (`count` = push audience per spec; `listed` = notifications-list audience, additive). Audit actions `announcement.publish`, `announcement.end`.

- [ ] Step 1: failing test `BACKEND/test/adminAnnouncements.publish.test.js`
```js
'use strict';
process.env.JWT_SECRET = process.env.JWT_SECRET && process.env.JWT_SECRET.length >= 32
  ? process.env.JWT_SECRET : 'test-secret-that-is-long-enough-to-pass-0123456789';

const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const express = require('express');
const request = require('supertest');
const { startDb, stopDb, makeUser } = require('./helpers/callKit');

let app, Announcement, AdminAuditLog, User, announcementDelivery, admin, delivered;
const as = (u) => ({ Authorization: `Bearer ${jwt.sign({ id: String(u._id) }, process.env.JWT_SECRET, { expiresIn: '1h' })}` });
const BASE = '/api/v1/admin/announcements';
const BODY = { translations: { en: { title: 'Hi', body: 'There' } }, defaultLocale: 'en' };
const tick = () => new Promise((r) => setImmediate(r));

test.before(async () => {
  await startDb('adminAnnouncementsPublish');
  Announcement = require('../models/Announcement');
  AdminAuditLog = require('../models/AdminAuditLog');
  User = require('../models/User');
  announcementDelivery = require('../services/announcementDelivery');
  announcementDelivery.deliver = async (id) => { delivered.push(String(id)); return {}; };
  admin = await makeUser('admin', { role: 'admin' });
  app = express();
  app.use(express.json());
  app.use(BASE, require('../routes/adminAnnouncements'));
  app.use(require('../middleware/error'));
});
test.after(stopDb);
test.beforeEach(async () => {
  delivered = [];
  await Promise.all([Announcement.deleteMany({}), AdminAuditLog.deleteMany({})]);
});

test('publish now with notify: live, startsAt now, queued and delivery kicked', async () => {
  const a = await Announcement.create({ ...BODY, notify: true });
  const res = await request(app).post(`${BASE}/${a._id}/publish`).set(as(admin)).send({});
  assert.equal(res.status, 200);
  assert.equal(res.body.data.status, 'live');
  assert.equal(res.body.data.delivery.state, 'queued');
  assert.equal(String(res.body.data.publishedBy), String(admin._id));
  assert.ok(Math.abs(new Date(res.body.data.startsAt) - Date.now()) < 5000);
  await tick();
  assert.deepEqual(delivered, [String(a._id)]);
  assert.ok(await AdminAuditLog.findOne({ action: 'announcement.publish', targetType: 'announcement' }));
});

test('publish at a future time schedules; nothing is delivered yet', async () => {
  const a = await Announcement.create({ ...BODY, notify: true });
  const at = new Date(Date.now() + 3600000).toISOString();
  const res = await request(app).post(`${BASE}/${a._id}/publish`).set(as(admin)).send({ at });
  assert.equal(res.body.data.status, 'scheduled');
  assert.equal(res.body.data.startsAt, at);
  await tick();
  assert.deepEqual(delivered, []);
});

test('publish without notify goes live without a delivery', async () => {
  const a = await Announcement.create(BODY);
  await request(app).post(`${BASE}/${a._id}/publish`).set(as(admin)).send({});
  await tick();
  assert.deepEqual(delivered, []);
  assert.equal((await Announcement.findById(a._id)).delivery.state, 'none');
});

test('publish refusals: no channel, wrong status, bad date, end before start', async () => {
  const silent = await Announcement.create({ ...BODY, showInApp: false, notify: false });
  assert.equal((await request(app).post(`${BASE}/${silent._id}/publish`).set(as(admin)).send({})).status, 400);
  const ended = await Announcement.create({ ...BODY, status: 'ended' });
  assert.equal((await request(app).post(`${BASE}/${ended._id}/publish`).set(as(admin)).send({})).status, 400);
  const draft = await Announcement.create(BODY);
  assert.equal((await request(app).post(`${BASE}/${draft._id}/publish`).set(as(admin)).send({ at: 'soon' })).status, 400);
  const past = await Announcement.create({ ...BODY, endsAt: new Date(Date.now() - 60000) });
  assert.equal((await request(app).post(`${BASE}/${past._id}/publish`).set(as(admin)).send({})).status, 400);
});

test('end: live → ended now; a draft cannot be ended', async () => {
  const a = await Announcement.create({ ...BODY, status: 'live', startsAt: new Date(Date.now() - 60000) });
  const res = await request(app).post(`${BASE}/${a._id}/end`).set(as(admin));
  assert.equal(res.status, 200);
  assert.equal(res.body.data.status, 'ended');
  assert.ok(res.body.data.endedAt);
  assert.ok(new Date(res.body.data.endsAt) <= new Date());
  assert.ok(await AdminAuditLog.findOne({ action: 'announcement.end' }));
  const draft = await Announcement.create(BODY);
  assert.equal((await request(app).post(`${BASE}/${draft._id}/end`).set(as(admin))).status, 400);
});

test('audience-count: push audience (token + allowed) and list audience', async () => {
  await User.deleteMany({ role: { $ne: 'admin' } });
  const tok = (p) => [{ token: `t-${Math.random()}`, platform: p, deviceId: 'd' }];
  await makeUser('ios-push', { fcmTokens: tok('ios') });
  await makeUser('ios-no-token', { signupPlatform: 'ios' });
  await makeUser('ios-opted-out', { fcmTokens: tok('ios'), notificationSettings: { announcements: false } });
  await makeUser('android-push', { fcmTokens: tok('android') });
  await makeUser('ios-banned', { fcmTokens: tok('ios'), isBanned: true });
  const a = await Announcement.create({ ...BODY, platforms: ['ios'] });
  const res = await request(app).get(`${BASE}/${a._id}/audience-count`).set(as(admin));
  assert.deepEqual(res.body, { success: true, data: { count: 1, listed: 3 } });
});
```
- [ ] Step 2: run → fails (publish route 404)
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/adminAnnouncements.publish.test.js`
- [ ] Step 3: implement
  - `controllers/adminAnnouncements.js`, after `const AdminAuditLog = require('../models/AdminAuditLog');` add:
```js
const User = require('../models/User');
const { audienceQuery } = require('../services/announcementService');
// Called through the module object so tests can replace deliver().
const announcementDelivery = require('../services/announcementDelivery');
```
  - append before `exports._internals = …`:
```js
// @route POST /api/v1/admin/announcements/:id/publish  body { at?: ISO }
// No `at` (or a past one) = live now; a future `at` = scheduled for then.
exports.publishAnnouncement = asyncHandler(async (req, res, next) => {
  const doc = await loadById(req.params.id);
  if (!doc) return next(notFound());
  if (!['draft', 'scheduled'].includes(doc.status)) {
    return next(new ErrorResponse(`This announcement is ${doc.status} and cannot be published`, 400));
  }
  if (!doc.showInApp && !doc.notify) {
    return next(new ErrorResponse('Turn on "Show in app" or "Send notification" first', 400));
  }
  const now = new Date();
  const at = parseDate('at', req.body && req.body.at);
  const startsAt = at && at > now ? at : now;
  doc.startsAt = startsAt;
  doc.status = startsAt > now ? 'scheduled' : 'live';
  doc.publishedBy = req.user._id;
  doc.publishedAt = now;
  if (doc.notify && doc.delivery.state === 'none') doc.delivery.state = 'queued';
  await doc.save(); // the model rejects endsAt <= startsAt
  audit(req, 'announcement.publish', doc, { startsAt: startsAt.toISOString(), notify: doc.notify });

  if (doc.status === 'live' && doc.notify) {
    // Answer the admin now; the minute job re-tries a 'queued' delivery if
    // this process dies before the claim.
    setImmediate(() => {
      Promise.resolve(announcementDelivery.deliver(doc._id))
        .catch((err) => console.error('[announcements] delivery failed:', err.message));
    });
  }
  res.status(200).json({ success: true, data: serialize(doc) });
});

// @route POST /api/v1/admin/announcements/:id/end
exports.endAnnouncement = asyncHandler(async (req, res, next) => {
  const doc = await loadById(req.params.id);
  if (!doc) return next(notFound());
  if (!['scheduled', 'live'].includes(doc.status)) {
    return next(new ErrorResponse('Only a scheduled or live announcement can be ended', 400));
  }
  const now = new Date();
  doc.status = 'ended';
  doc.endedAt = now;
  if (!doc.endsAt || doc.endsAt > now) doc.endsAt = now;
  await doc.save();
  audit(req, 'announcement.end', doc);
  res.status(200).json({ success: true, data: serialize(doc) });
});

// @route GET /api/v1/admin/announcements/:id/audience-count
// count = would get a push (active token, push allowed); listed = gets the list row.
exports.getAudienceCount = asyncHandler(async (req, res, next) => {
  const doc = await loadById(req.params.id);
  if (!doc) return next(notFound());
  const base = audienceQuery(doc);
  const [count, listed] = await Promise.all([
    User.countDocuments({ $and: [
      base,
      { fcmTokens: { $elemMatch: { active: true } } },
      { 'notificationSettings.enabled': { $ne: false } },
      { 'notificationSettings.announcements': { $ne: false } },
    ] }),
    User.countDocuments(base),
  ]);
  res.status(200).json({ success: true, data: { count, listed } });
});
```
  - `routes/adminAnnouncements.js`, after the `router.route('/:id')…` line:
```js
router.post('/:id/publish', c.publishAnnouncement);
router.post('/:id/end', c.endAnnouncement);
router.get('/:id/audience-count', c.getAudienceCount);
```
- [ ] Step 4: run → 6 passing; re-run `test/adminAnnouncements.crud.test.js` → passing.
- [ ] Step 5: commit
```
git add controllers/adminAnnouncements.js routes/adminAnnouncements.js test/adminAnnouncements.publish.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): publish now/scheduled, end, audience count

Publish without 'at' goes live and kicks delivery when notify is on; a future
'at' schedules. End closes the window now. audience-count returns the push
audience (count) and the list audience (listed).

REMAINING_WORK: ticked B7.
Still open: B8-B11, W1-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task B8: announcement image upload

**Files:** Modify `BACKEND/controllers/adminAnnouncements.js`, `BACKEND/routes/adminAnnouncements.js`; Test `BACKEND/test/adminAnnouncements.upload.test.js`
**Interfaces:** Consumes `compressImageBuffer` (middleware/uploadToSpaces.js), `storageService.uploadToSpaces` / `generateUniqueFilename`. Produces `POST /api/v1/admin/announcements/upload-image` (multipart field `image`, ≤5 MB, JPG/PNG/WebP/GIF) → `201 { success, data: { url } }`, audit `announcement.image_upload`.

- [ ] Step 1: failing test `BACKEND/test/adminAnnouncements.upload.test.js`
```js
'use strict';
process.env.JWT_SECRET = process.env.JWT_SECRET && process.env.JWT_SECRET.length >= 32
  ? process.env.JWT_SECRET : 'test-secret-that-is-long-enough-to-pass-0123456789';
// storageService returns a mock URL only when explicitly allowed and unconfigured.
process.env.ALLOW_MOCK_STORAGE = 'true';
for (const k of ['SPACES_ENDPOINT', 'DO_SPACES_ENDPOINT', 'DO_SPACES_KEY', 'SPACES_KEY', 'DO_SPACES_SECRET', 'SPACES_SECRET']) delete process.env[k];

const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const express = require('express');
const request = require('supertest');
const sharp = require('sharp');
const { startDb, stopDb, makeUser, silence } = require('./helpers/callKit');

let app, admin, user, restoreLog;
const as = (u) => ({ Authorization: `Bearer ${jwt.sign({ id: String(u._id) }, process.env.JWT_SECRET, { expiresIn: '1h' })}` });
const URL_PATH = '/api/v1/admin/announcements/upload-image';

test.before(async () => {
  await startDb('adminAnnouncementsUpload');
  admin = await makeUser('admin', { role: 'admin' });
  user = await makeUser('plain');
  app = express();
  app.use(express.json());
  app.use('/api/v1/admin/announcements', require('../routes/adminAnnouncements'));
  app.use(require('../middleware/error'));
  restoreLog = silence();
});
test.after(async () => { restoreLog(); await stopDb(); });

const png = () => sharp({ create: { width: 8, height: 8, channels: 3, background: '#ffcc00' } }).png().toBuffer();

test('an image is compressed and stored under bananatalk/announcements', async () => {
  const res = await request(app).post(URL_PATH).set(as(admin))
    .attach('image', await png(), { filename: 'a.png', contentType: 'image/png' });
  assert.equal(res.status, 201);
  assert.match(res.body.data.url, /^https:\/\/mock-storage\.local\/bananatalk\/announcements\/announcement_\d+_[0-9a-f]{16}\.(jpg|png)$/);
});

test('a non-image is a 400', async () => {
  const res = await request(app).post(URL_PATH).set(as(admin))
    .attach('image', Buffer.from('%PDF-1.4'), { filename: 'a.pdf', contentType: 'application/pdf' });
  assert.equal(res.status, 400);
});

test('no file is a 400; non-admin is a 403', async () => {
  assert.equal((await request(app).post(URL_PATH).set(as(admin))).status, 400);
  const res = await request(app).post(URL_PATH).set(as(user))
    .attach('image', await png(), { filename: 'a.png', contentType: 'image/png' });
  assert.equal(res.status, 403);
});
```
- [ ] Step 2: run → fails (404 on `/upload-image`)
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/adminAnnouncements.upload.test.js`
- [ ] Step 3: implement
  - `controllers/adminAnnouncements.js`, add to the requires:
```js
const multer = require('multer');
const { compressImageBuffer } = require('../middleware/uploadToSpaces');
const storageService = require('../services/storageService');
```
  - append before `exports._internals = …`:
```js
const IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const EXTENSION = { 'image/png': 'png', 'image/gif': 'gif', 'image/webp': 'webp' };

// Memory storage so the image goes through the same compressor as chat and
// moment images before it reaches Spaces. The 'File type not allowed' prefix
// is what middleware/error.js maps to a 400.
exports.imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_IMAGE_BYTES, files: 1 },
  fileFilter: (req, file, cb) => (IMAGE_TYPES.includes(file.mimetype)
    ? cb(null, true)
    : cb(new Error('File type not allowed: announcement images must be JPG, PNG, WebP or GIF'))),
}).single('image');

// @route POST /api/v1/admin/announcements/upload-image (multipart `image`)
exports.uploadAnnouncementImage = asyncHandler(async (req, res, next) => {
  if (!req.file) return next(new ErrorResponse('Attach an image in the "image" field', 400));
  const { buffer, contentType } = await compressImageBuffer(req.file.buffer, req.file.mimetype);
  const filename = storageService.generateUniqueFilename('announcement', EXTENSION[contentType] || 'jpg');
  const url = await storageService.uploadToSpaces(buffer, filename, contentType, 'bananatalk/announcements');
  AdminAuditLog.logAction({
    moderator: req.user._id, action: 'announcement.image_upload', targetType: 'announcement',
    source: 'manual', details: { url },
  });
  res.status(201).json({ success: true, data: { url } });
});
```
  - `routes/adminAnnouncements.js`, directly after `router.use(protect, authorize('admin'));`:
```js
router.post('/upload-image', c.imageUpload, c.uploadAnnouncementImage);
```
- [ ] Step 4: run → 3 passing.
- [ ] Step 5: commit
```
git add controllers/adminAnnouncements.js routes/adminAnnouncements.js test/adminAnnouncements.upload.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): admin image upload to Spaces

POST /admin/announcements/upload-image: image only, 5 MB, compressed like
chat/moment images, stored under bananatalk/announcements, audit-logged.

REMAINING_WORK: ticked B8.
Still open: B9-B11, W1-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task B9: minute job `runAnnouncementTick`

**Files:** Create `BACKEND/jobs/announcementJob.js`; Modify `BACKEND/jobs/scheduler.js`; Test `BACKEND/test/announcementJob.test.js`
**Interfaces:** Consumes `announcementDelivery.deliver`, `STALE_MS`. Produces `runAnnouncementTick(now) -> { started, ended, delivered }`, `start()`, `INTERVAL_MS`. Kill switch `ANNOUNCEMENT_JOB_ENABLED=false`.

- [ ] Step 1: failing test `BACKEND/test/announcementJob.test.js`
```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { startDb, stopDb, silence } = require('./helpers/callKit');

let Announcement, announcementDelivery, job, delivered, restoreLog;
const NOW = new Date('2026-10-20T12:00:00Z');
const M = 60000;

test.before(async () => {
  await startDb('announcementJob');
  Announcement = require('../models/Announcement');
  announcementDelivery = require('../services/announcementDelivery');
  job = require('../jobs/announcementJob');
  restoreLog = silence();
});
test.after(async () => { restoreLog(); await stopDb(); });
test.beforeEach(async () => {
  delivered = [];
  announcementDelivery.deliver = async (id) => { delivered.push(String(id)); return { targeted: 0, pushed: 0, listed: 0, failed: 0 }; };
  await Announcement.deleteMany({});
});

const make = (over) => Announcement.create({
  translations: { en: { title: 't', body: 'b' } }, defaultLocale: 'en', ...over,
});

test('flips scheduled→live and live→ended, and delivers newly-live notify ones', async () => {
  const due = await make({ status: 'scheduled', startsAt: new Date(NOW - M), notify: true });
  const later = await make({ status: 'scheduled', startsAt: new Date(+NOW + M), notify: true });
  const over = await make({ status: 'live', startsAt: new Date(NOW - 10 * M), endsAt: new Date(NOW - M) });
  const missed = await make({ status: 'scheduled', startsAt: new Date(NOW - 10 * M), endsAt: new Date(NOW - M), notify: true });
  const quiet = await make({ status: 'live', startsAt: new Date(NOW - M), notify: false });

  const out = await job.runAnnouncementTick(NOW);

  assert.deepEqual(out, { started: 1, ended: 2, delivered: 1 });
  assert.equal((await Announcement.findById(due._id)).status, 'live');
  assert.equal((await Announcement.findById(later._id)).status, 'scheduled');
  const ended = await Announcement.findById(over._id);
  assert.equal(ended.status, 'ended');
  assert.equal(+ended.endedAt, +NOW);
  assert.equal((await Announcement.findById(missed._id)).status, 'ended', 'a window that closed before the tick never goes live');
  assert.deepEqual(delivered, [String(due._id)]);
  assert.ok(!delivered.includes(String(quiet._id)));
});

test('queued deliveries are retried; done ones are not; stale running ones resume, fresh ones wait', async () => {
  const queued = await make({ status: 'live', startsAt: new Date(NOW - M), notify: true, delivery: { state: 'queued' } });
  await make({ status: 'live', startsAt: new Date(NOW - M), notify: true, delivery: { state: 'done' } });
  const stale = await make({ status: 'ended', startsAt: new Date(NOW - 60 * M), endsAt: new Date(NOW - M), notify: true,
    delivery: { state: 'running', heartbeatAt: new Date(NOW - 11 * M) } });
  await make({ status: 'live', startsAt: new Date(NOW - M), notify: true, delivery: { state: 'running', heartbeatAt: new Date(NOW - M) } });
  await job.runAnnouncementTick(NOW);
  assert.deepEqual(delivered.sort(), [String(queued._id), String(stale._id)].sort());
});

test('one failing delivery does not stop the tick', async () => {
  const a = await make({ status: 'live', startsAt: new Date(NOW - M), notify: true });
  const b = await make({ status: 'live', startsAt: new Date(NOW - 2 * M), notify: true });
  announcementDelivery.deliver = async (id) => {
    delivered.push(String(id));
    if (String(id) === String(a._id)) throw new Error('boom');
    return {};
  };
  await job.runAnnouncementTick(NOW);
  assert.deepEqual(delivered.sort(), [String(a._id), String(b._id)].sort());
});

test('runs every minute', () => {
  assert.equal(job.INTERVAL_MS, 60000);
  assert.equal(typeof job.start, 'function');
});
```
- [ ] Step 2: run → fails `Cannot find module '../jobs/announcementJob'`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/announcementJob.test.js`
- [ ] Step 3: implement
  - create `BACKEND/jobs/announcementJob.js`:
```js
'use strict';

/**
 * Announcements minute tick (spec 2026-10-12 §5.1).
 *
 *  1. scheduled|live with endsAt <= now → ended (first, so a window that
 *     closed before this tick never goes live and never sends).
 *  2. scheduled with startsAt <= now → live.
 *  3. live + notify with delivery none|queued → deliver; a running delivery
 *     with a heartbeat older than STALE_MS (its process died) → deliver
 *     resumes it. deliver() claims atomically, so overlap with a publish-now
 *     delivery in flight is harmless.
 *
 * Deliveries run inside the tick, one at a time; the `running` guard in
 * start() keeps ticks from overlapping while a long send is in progress.
 * Kill switch: ANNOUNCEMENT_JOB_ENABLED=false (jobs/scheduler.js).
 */
const Announcement = require('../models/Announcement');
const announcementDelivery = require('../services/announcementDelivery');

const INTERVAL_MS = 60 * 1000;

async function runAnnouncementTick(now = new Date()) {
  const ended = await Announcement.updateMany(
    { status: { $in: ['scheduled', 'live'] }, endsAt: { $ne: null, $lte: now } },
    { $set: { status: 'ended', endedAt: now } }
  );
  const started = await Announcement.updateMany(
    { status: 'scheduled', startsAt: { $ne: null, $lte: now } },
    { $set: { status: 'live' } }
  );

  const staleBefore = new Date(now.getTime() - announcementDelivery.STALE_MS);
  const due = await Announcement.find({
    notify: true,
    $or: [
      { status: 'live', 'delivery.state': { $in: ['none', 'queued'] } },
      { status: { $in: ['live', 'ended'] }, 'delivery.state': 'running', 'delivery.heartbeatAt': { $lt: staleBefore } },
    ],
  }).select('_id').sort({ priority: -1, startsAt: 1 }).lean();

  let delivered = 0;
  for (const { _id } of due) {
    try {
      const result = await announcementDelivery.deliver(_id, { now });
      if (!result || !result.skipped) delivered += 1;
    } catch (err) {
      console.error('[announcementJob] deliver failed for', String(_id), err.message);
    }
  }
  return { started: started.modifiedCount, ended: ended.modifiedCount, delivered };
}

function start() {
  let running = false;
  const tick = () => {
    if (running) return Promise.resolve();
    running = true;
    return runAnnouncementTick()
      .then((s) => {
        if (s.started || s.ended || s.delivered) console.log('[announcementJob]', JSON.stringify(s));
      })
      .catch((err) => console.error('[announcementJob] tick failed:', err.message))
      .finally(() => { running = false; });
  };
  setInterval(tick, INTERVAL_MS);
  setTimeout(tick, 10000);
  console.log('📅 Announcement job scheduled (every 60 s)');
}

module.exports = { runAnnouncementTick, start, INTERVAL_MS };
```
  - `BACKEND/jobs/scheduler.js`, in `startScheduler` directly after the `CALL_SWEEP_ENABLED` block:
```js
  // Admin announcements: scheduled → live → ended + notify deliveries (every 60 s)
  if (process.env.ANNOUNCEMENT_JOB_ENABLED !== 'false') {
    require('./announcementJob').start();
  }
```
- [ ] Step 4: run → 4 passing; `node -e "require('./jobs/scheduler')"` exits 0.
- [ ] Step 5: commit
```
git add jobs/announcementJob.js jobs/scheduler.js test/announcementJob.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): minute job for schedule windows and deliveries

Ends closed windows, starts due ones, delivers newly-live notify
announcements and resumes stale deliveries. Kill switch
ANNOUNCEMENT_JOB_ENABLED=false.

REMAINING_WORK: ticked B9; added 'Flags: ANNOUNCEMENT_JOB_ENABLED (default on)'.
Still open: B10-B11, W1-W5; deploy gated on docs/ops/2026-10-pm2-restarts.md.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
REMAINING_WORK (backend) "Flags" section: add `- \`ANNOUNCEMENT_JOB_ENABLED\` — default ON (unset); set \`false\` to stop the announcement minute job. Publish-now deliveries still run.`

### Task B10: `GET /api/v1/announcements/:id` for the detail screen

**Files:** Create `BACKEND/controllers/announcements.js`, `BACKEND/routes/announcements.js`; Modify `BACKEND/server.js`; Test `BACKEND/test/announcementDetail.test.js`
**Interfaces:** Consumes `toPublic`, `requestLanguage`. Produces `GET /api/v1/announcements/:id` → `{ success, data: PublicAnnouncement }` in `?lang`, else `user.preferredLocale`, else Accept-Language, else `en`; only `live` and `ended` announcements (a notification can outlive its window).

- [ ] Step 1: failing test `BACKEND/test/announcementDetail.test.js`
```js
'use strict';
process.env.JWT_SECRET = process.env.JWT_SECRET && process.env.JWT_SECRET.length >= 32
  ? process.env.JWT_SECRET : 'test-secret-that-is-long-enough-to-pass-0123456789';

const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const express = require('express');
const request = require('supertest');
const { startDb, stopDb, makeUser } = require('./helpers/callKit');

let app, Announcement, koUser;
const as = (u) => ({ Authorization: `Bearer ${jwt.sign({ id: String(u._id) }, process.env.JWT_SECRET, { expiresIn: '1h' })}` });

test.before(async () => {
  await startDb('announcementDetail');
  Announcement = require('../models/Announcement');
  koUser = await makeUser('ko', { preferredLocale: 'ko' });
  app = express();
  app.use(express.json());
  app.use('/api/v1/announcements', require('../routes/announcements'));
  app.use(require('../middleware/error'));
});
test.after(stopDb);

const make = (status) => Announcement.create({
  translations: { en: { title: 'EN', body: 'en body' }, ko: { title: 'KO', body: 'ko body' } },
  defaultLocale: 'en', status, startsAt: new Date(Date.now() - 60000), buttonUrl: '/study',
});

test('the user language by default, ?lang overrides, default locale as fallback', async () => {
  const a = await make('live');
  const mine = await request(app).get(`/api/v1/announcements/${a._id}`).set(as(koUser));
  assert.equal(mine.status, 200);
  assert.equal(mine.body.data.title, 'KO');
  assert.equal(mine.body.data.id, String(a._id));
  assert.equal(mine.body.data.buttonUrl, '/study');
  assert.equal((await request(app).get(`/api/v1/announcements/${a._id}?lang=en`).set(as(koUser))).body.data.title, 'EN');
  assert.equal((await request(app).get(`/api/v1/announcements/${a._id}?lang=fr`).set(as(koUser))).body.data.title, 'EN');
});

test('ended stays readable; draft and scheduled are 404; bad id 404; anonymous 401', async () => {
  assert.equal((await request(app).get(`/api/v1/announcements/${(await make('ended'))._id}`).set(as(koUser))).status, 200);
  assert.equal((await request(app).get(`/api/v1/announcements/${(await make('draft'))._id}`).set(as(koUser))).status, 404);
  assert.equal((await request(app).get(`/api/v1/announcements/${(await make('scheduled'))._id}`).set(as(koUser))).status, 404);
  assert.equal((await request(app).get('/api/v1/announcements/nope').set(as(koUser))).status, 404);
  assert.equal((await request(app).get(`/api/v1/announcements/${(await make('live'))._id}`)).status, 401);
});
```
- [ ] Step 2: run → fails `Cannot find module '../routes/announcements'`
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/announcementDetail.test.js`
- [ ] Step 3: implement
  - create `BACKEND/controllers/announcements.js`:
```js
'use strict';
const mongoose = require('mongoose');
const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const Announcement = require('../models/Announcement');
const { toPublic, requestLanguage } = require('../services/announcementService');

/**
 * @desc   One announcement for the app's AnnouncementScreen (notification tap).
 * @route  GET /api/v1/announcements/:id?lang=
 * @access Private
 * Ended announcements stay readable: the notifications-list row is permanent.
 */
exports.getAnnouncementForUser = asyncHandler(async (req, res, next) => {
  const notFound = () => next(new ErrorResponse('Announcement not found', 404));
  if (!mongoose.isValidObjectId(req.params.id)) return notFound();
  const doc = await Announcement.findOne({ _id: req.params.id, status: { $in: ['live', 'ended'] } }).lean();
  if (!doc) return notFound();
  const language = requestLanguage(req, req.user && req.user.preferredLocale);
  res.status(200).json({ success: true, data: toPublic(doc, language) });
});
```
  - create `BACKEND/routes/announcements.js`:
```js
'use strict';
const express = require('express');
const { protect } = require('../middleware/auth');
const { getAnnouncementForUser } = require('../controllers/announcements');

const router = express.Router();
router.get('/:id', protect, getAnnouncementForUser);

module.exports = router;
```
  - `BACKEND/server.js`, directly after `app.use('/api/v1/app-config', require('./routes/appConfig'));`:
```js
app.use('/api/v1/announcements', require('./routes/announcements'));
```
- [ ] Step 4: run → 2 passing.
- [ ] Step 5: commit
```
git add controllers/announcements.js routes/announcements.js server.js test/announcementDetail.test.js docs/REMAINING_WORK.md
git commit -m "feat(announcements): user detail endpoint in the user's language

REMAINING_WORK: ticked B10.
Still open: B11, W1-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task B11: suspension `banReason` as its own field

**Files:** Modify `BACKEND/utils/errorResponse.js`, `BACKEND/middleware/error.js`, `BACKEND/middleware/auth.js` (both ban branches), `BACKEND/socket/socketHandler.js` (suspended branch); Test `BACKEND/test/bannedCode.test.js` (rewritten, existing assertion kept)
**Interfaces:** Produces REST 403 `{ success:false, error, message, code:'ACCOUNT_BANNED', banReason: string|null }` and socket error `data: { reason, banReason }`. The `message` keeps its `" Reason: …"` suffix so live builds are unchanged.

- [ ] Step 1: failing test — replace `BACKEND/test/bannedCode.test.js` with:
```js
'use strict';
/**
 * Banned accounts answer 403 with code ACCOUNT_BANNED and the reason as its
 * own field (spec 2026-10-12 §5.1) — the app no longer parses "Reason:" out of
 * the message. The message keeps the suffix for builds already in stores.
 */
process.env.JWT_SECRET = process.env.JWT_SECRET && process.env.JWT_SECRET.length >= 32
  ? process.env.JWT_SECRET : 'test-secret-that-is-long-enough-to-pass-0123456789';

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const express = require('express');
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod, app, User, banned, noReason;
const tokenFor = (u) => jwt.sign({ id: String(u._id) }, process.env.JWT_SECRET, { expiresIn: '1h' });
const makeBanned = (name, banReason) => User.create({
  name, email: `${name}-${new mongoose.Types.ObjectId()}@example.com`,
  password: 'hashed-password-placeholder', birth_year: '2000', birth_month: '1',
  birth_day: '1', gender: 'other', native_language: 'English', language_to_learn: 'Korean',
  isBanned: true, banReason,
});

test.before(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'bannedCode' });
  User = require('../models/User');
  banned = await makeBanned('banned-user', 'terms violation');
  noReason = await makeBanned('banned-no-reason', null);

  const { protect, optionalAuth } = require('../middleware/auth');
  const ErrorResponse = require('../utils/errorResponse');
  app = express();
  app.get('/whoami', protect, (req, res) => res.json({ id: String(req.user._id) }));
  app.get('/maybe', optionalAuth, (req, res) => res.json({ ok: true }));
  app.get('/plain-error', (req, res, next) => next(new ErrorResponse('nope', 400)));
  app.use(require('../middleware/error'));
});

test.after(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});

test('a banned account gets 403 with code ACCOUNT_BANNED', async () => {
  const res = await request(app).get('/whoami').set('Authorization', `Bearer ${tokenFor(banned)}`);
  assert.equal(res.status, 403);
  assert.equal(res.body.code, 'ACCOUNT_BANNED');
});

test('the reason is its own field; the legacy message is unchanged', async () => {
  const res = await request(app).get('/whoami').set('Authorization', `Bearer ${tokenFor(banned)}`);
  assert.equal(res.body.banReason, 'terms violation');
  assert.equal(res.body.message, 'Your account has been suspended. Reason: terms violation');
});

test('no reason on the account → banReason null (present, not missing)', async () => {
  const res = await request(app).get('/whoami').set('Authorization', `Bearer ${tokenFor(noReason)}`);
  assert.ok(Object.prototype.hasOwnProperty.call(res.body, 'banReason'));
  assert.equal(res.body.banReason, null);
});

test('optionalAuth carries the field too', async () => {
  const res = await request(app).get('/maybe').set('Authorization', `Bearer ${tokenFor(banned)}`);
  assert.equal(res.status, 403);
  assert.equal(res.body.banReason, 'terms violation');
});

test('other errors carry no banReason', async () => {
  const res = await request(app).get('/plain-error');
  assert.equal(res.status, 400);
  assert.equal(Object.prototype.hasOwnProperty.call(res.body, 'banReason'), false);
});

test('the socket handshake error carries banReason (and the old reason key)', async () => {
  const { initializeSocket } = require('../socket/socketHandler');
  const middlewares = [];
  initializeSocket({
    use: (fn) => middlewares.push(fn), on: () => {},
    to: () => ({ emit: () => {} }), sockets: { sockets: new Map() },
  });
  const err = await new Promise((resolve) => middlewares[0](
    { handshake: { auth: { token: tokenFor(banned) }, query: {}, headers: {} }, on: () => {}, emit: () => {}, join: () => {} },
    (e) => resolve(e || null)
  ));
  assert.match(err.message, /Account suspended/);
  assert.deepEqual(err.data, { reason: 'terms violation', banReason: 'terms violation' });
});
```
- [ ] Step 2: run → the four new field tests fail (`banReason` undefined)
  `cd BACKEND && node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/bannedCode.test.js`
- [ ] Step 3: implement
  - `utils/errorResponse.js` (whole file):
```js
class ErrorResponse extends Error {
  /**
   * @param {string} message
   * @param {number} statusCode
   * @param {string|null} code   machine-readable code → response `code`
   * @param {object|null} extra  extra top-level response fields (e.g. { banReason })
   */
  constructor(message, statusCode, code = null, extra = null) {
    super(message);
    this.statusCode = statusCode;
    if (code) this.errorCode = code; // 'code' collides with Node err.code (Mongo uses 11000)
    if (extra && typeof extra === 'object') this.extra = extra;
  }
}
module.exports = ErrorResponse;
```
  - `middleware/error.js`: replace the final `res.status(statusCode).json({ … })` call with
```js
  res.status(statusCode).json({
    // Extra fields first, so they can never overwrite success/error/message/code.
    ...(err.extra && typeof err.extra === 'object' ? err.extra : {}),
    success: false,
    error: responseMessage,
    message: responseMessage,
    ...(errorCode ? { code: errorCode } : {}),
    ...(process.env.NODE_ENV === 'development' && {
      stack: err.stack,
      details: err.details || null
    })
  });
```
  - `middleware/auth.js`: add above `exports.protect`:
```js
// Spec 2026-10-12 §5.1: the reason travels as its own field; the message keeps
// the " Reason: …" suffix for builds that still parse it.
const bannedError = (user) => new ErrorResponse(
  `Your account has been suspended.${user.banReason ? ' Reason: ' + user.banReason : ''}`,
  403,
  'ACCOUNT_BANNED',
  { banReason: user.banReason || null }
);
```
    and replace both ban branches (`protect` and `optionalAuth`) with `return next(bannedError(req.user));`
  - `socket/socketHandler.js`, suspended branch: `err.data = { reason: account.banReason || null, banReason: account.banReason || null };` with the comment `// banReason is the field the app reads (spec 2026-10-12 §5.1); reason kept for live builds.`
- [ ] Step 4: run → 6 passing; also `test/authAudit.sessionRevocation.test.js`, `test/cookieAuthIntegration.test.js` → passing.
- [ ] Step 5: commit
```
git add utils/errorResponse.js middleware/error.js middleware/auth.js socket/socketHandler.js test/bannedCode.test.js docs/REMAINING_WORK.md
git commit -m "fix(auth): suspension reason travels as banReason

REST 403 ACCOUNT_BANNED responses (protect, optionalAuth) and the suspended
socket error carry banReason (string|null); the message keeps its 'Reason:'
suffix for live builds.

REMAINING_WORK: ticked B11; added 'App: read banReason instead of parsing the
message (L-tasks, spec §5.1)'.
Still open: W1-W5, app A*/L*, deploy + index check.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
## Web admin (`WEB`, branch `feat/admin-announcements`)

Conventions taken from the existing console: hooks come only from `src/store/slices/adminSlice.ts`; copy is `t("admin.…") || "English fallback"` (no admin keys exist in locale files; tests mock `t` to return `""`); destructive or broadcast actions go through `parts/ConfirmDialog`; `typescript@3.7.2` → no `import type`, no `export type { }` re-exports.

### Task W1: admin slice endpoints for announcements

**Files:** Modify `WEB/src/store/slices/adminSlice.ts`, `WEB/src/store/slices/apiSlice.ts` (tagTypes); Create `WEB/docs/REMAINING_WORK.md`; Test `WEB/src/store/slices/adminAnnouncementsEndpoints.test.ts`
**Interfaces:** Consumes backend B5/B7/B8 routes. Produces types `AnnouncementStatus`, `AnnouncementPlatform`, `AnnouncementTranslation`, `AdminAnnouncement`, `AnnouncementInput`, `AudienceCount` and hooks `useListAnnouncementsQuery`, `useGetAnnouncementQuery`, `useCreateAnnouncementMutation`, `useUpdateAnnouncementMutation`, `usePublishAnnouncementMutation`, `useEndAnnouncementMutation`, `useDeleteAnnouncementMutation`, `useLazyGetAnnouncementAudienceQuery`, `useUploadAnnouncementImageMutation`.

- [ ] Step 1: failing test `WEB/src/store/slices/adminAnnouncementsEndpoints.test.ts`
```ts
/**
 * Announcements endpoints (spec 2026-10-12 §5.3) — URL, method and body of
 * each request, asserted on the outgoing Request like adminSlice.test.ts.
 */
import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./apiSlice";
import { adminApiSlice } from "./adminSlice";

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: null }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

type Captured = { url: string; method: string; body: any };

function mockFetch(payload: any = { success: true, data: {} }): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    let body: any = req.body;
    if (body === undefined && req.clone) {
      try {
        body = await req.clone().text();
      } catch {
        // whatwg-fetch can't re-serialize a FormData body (the image upload);
        // only URL and method are asserted for it, as in momentsActionsEndpoints.test.ts.
        body = undefined;
      }
    }
    calls.push({ url: req.url, method: req.method, body });
    return new Response(JSON.stringify(payload), { status: 200, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

const ep = (name: string) => (adminApiSlice.endpoints as any)[name];

it("exports every announcements hook the pages use", () => {
  const slice = adminApiSlice as any;
  [
    "useListAnnouncementsQuery", "useGetAnnouncementQuery", "useCreateAnnouncementMutation",
    "useUpdateAnnouncementMutation", "usePublishAnnouncementMutation", "useEndAnnouncementMutation",
    "useDeleteAnnouncementMutation", "useLazyGetAnnouncementAudienceQuery", "useUploadAnnouncementImageMutation",
  ].forEach((hook) => expect(typeof slice[hook]).toBe("function"));
});

it("list -> GET /admin/announcements?status=", async () => {
  const calls = mockFetch({ success: true, data: [] });
  const result: any = await makeStore().dispatch(ep("listAnnouncements").initiate({ status: "live" }));
  const url = new URL(calls[0].url);
  expect(url.pathname).toBe("/api/v1/admin/announcements");
  expect(url.searchParams.get("status")).toBe("live");
  expect(result.data).toEqual([]);
});

it("create -> POST with the body; update -> PUT /:id without the id in the body", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("createAnnouncement").initiate({ defaultLocale: "en", notify: true }));
  expect(calls[0].method).toBe("POST");
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements");
  expect(JSON.parse(calls[0].body)).toEqual({ defaultLocale: "en", notify: true });

  await store.dispatch(ep("updateAnnouncement").initiate({ id: "a1", priority: 3 }));
  expect(calls[1].method).toBe("PUT");
  expect(new URL(calls[1].url).pathname).toBe("/api/v1/admin/announcements/a1");
  expect(JSON.parse(calls[1].body)).toEqual({ priority: 3 });
});

it("publish sends {at} only when scheduling; end and delete hit their routes", async () => {
  const calls = mockFetch();
  const store = makeStore();
  await store.dispatch(ep("publishAnnouncement").initiate({ id: "a1" }));
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements/a1/publish");
  expect(JSON.parse(calls[0].body)).toEqual({});

  await store.dispatch(ep("publishAnnouncement").initiate({ id: "a1", at: "2030-01-01T00:00:00.000Z" }));
  expect(JSON.parse(calls[1].body)).toEqual({ at: "2030-01-01T00:00:00.000Z" });

  await store.dispatch(ep("endAnnouncement").initiate("a1"));
  expect(calls[2].method).toBe("POST");
  expect(new URL(calls[2].url).pathname).toBe("/api/v1/admin/announcements/a1/end");

  await store.dispatch(ep("deleteAnnouncement").initiate("a1"));
  expect(calls[3].method).toBe("DELETE");
  expect(new URL(calls[3].url).pathname).toBe("/api/v1/admin/announcements/a1");
});

it("audience count -> GET /:id/audience-count, unwrapped", async () => {
  const calls = mockFetch({ success: true, data: { count: 12, listed: 40 } });
  const result: any = await makeStore().dispatch(ep("getAnnouncementAudience").initiate("a1"));
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements/a1/audience-count");
  expect(result.data).toEqual({ count: 12, listed: 40 });
});

it("image upload -> POST multipart to /upload-image", async () => {
  const calls = mockFetch({ success: true, data: { url: "https://cdn/x.jpg" } });
  const file = new File(["x"], "x.png", { type: "image/png" });
  const result: any = await makeStore().dispatch(ep("uploadAnnouncementImage").initiate(file));
  expect(calls[0].method).toBe("POST");
  expect(new URL(calls[0].url).pathname).toBe("/api/v1/admin/announcements/upload-image");
  expect(result.data).toEqual({ url: "https://cdn/x.jpg" });
});
```
- [ ] Step 2: run → fails (`useListAnnouncementsQuery` undefined / `endpoints.listAnnouncements` undefined)
  `cd WEB && CI=true npx react-scripts test --watchAll=false src/store/slices/adminAnnouncementsEndpoints.test.ts`
- [ ] Step 3: implement
  - `apiSlice.ts` `tagTypes`: after `"AdminReports",` add
```ts
    // Admin announcements (spec 2026-10-12 §5.3): the list, and one per id
    // for the editor, so saving one announcement doesn't refetch another.
    "AdminAnnouncements",
    "AdminAnnouncement",
```
  - `adminSlice.ts`, after the `AdminReportRow` interface block, add the types:
```ts
/** Announcements (spec 2026-10-12 §5.1/§5.3). Mirrors models/Announcement.js. */
export type AnnouncementStatus = "draft" | "scheduled" | "live" | "ended";
export type AnnouncementPlatform = "all" | "ios" | "android";

export interface AnnouncementTranslation {
  title: string;
  body: string;
  buttonLabel?: string;
}

/** A row of `GET /admin/announcements` (translations flattened to an object). */
export interface AdminAnnouncement {
  id: string;
  _id: string;
  status: AnnouncementStatus;
  priority: number;
  translations: { [locale: string]: AnnouncementTranslation };
  defaultLocale: string;
  emoji: string | null;
  imageUrl: string | null;
  buttonUrl: string | null;
  platforms: AnnouncementPlatform[];
  languages: string[];
  startsAt: string | null;
  endsAt: string | null;
  showInApp: boolean;
  notify: boolean;
  publishedAt: string | null;
  endedAt: string | null;
  delivery: {
    state: "none" | "queued" | "running" | "done" | "failed";
    targeted: number;
    pushed: number;
    listed: number;
    failed: number;
    startedAt: string | null;
    finishedAt: string | null;
  };
  createdAt: string;
  updatedAt: string;
}

/** `POST`/`PUT /admin/announcements` body — anything absent is unchanged. */
export interface AnnouncementInput {
  translations?: { [locale: string]: AnnouncementTranslation };
  defaultLocale?: string;
  emoji?: string;
  imageUrl?: string | null;
  buttonUrl?: string | null;
  platforms?: AnnouncementPlatform[];
  languages?: string[];
  startsAt?: string | null;
  endsAt?: string | null;
  showInApp?: boolean;
  notify?: boolean;
  priority?: number;
}

/** `GET /admin/announcements/:id/audience-count`: push audience and list audience. */
export interface AudienceCount {
  count: number;
  listed: number;
}
```
  - in `endpoints`, after `getAnalyticsVisits`:
```ts
    // --- Announcements (spec 2026-10-12 §5.3) --------------------------------
    // Writes are never retried: a publish that silently repeats is a second
    // push to every user (the backend dedupes per user, but it should never
    // have to).
    listAnnouncements: builder.query({
      query: (arg: { status?: AnnouncementStatus } = {}) => ({
        url: `${ADMIN_URL}/announcements`,
        params: params(arg),
      }),
      transformResponse: unwrap,
      providesTags: ["AdminAnnouncements"],
    }),
    getAnnouncement: builder.query({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}` }),
      transformResponse: unwrap,
      providesTags: (_r: any, _e: any, id: string) => [{ type: "AdminAnnouncement", id }],
    }),
    createAnnouncement: builder.mutation({
      query: (body: AnnouncementInput) => ({ url: `${ADMIN_URL}/announcements`, method: "POST", body }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminAnnouncements"],
    }),
    updateAnnouncement: builder.mutation({
      query: ({ id, ...body }: { id: string } & AnnouncementInput) => ({
        url: `${ADMIN_URL}/announcements/${id}`,
        method: "PUT",
        body,
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminAnnouncement", id: arg.id },
        "AdminAnnouncements",
      ],
    }),
    publishAnnouncement: builder.mutation({
      query: ({ id, at }: { id: string; at?: string }) => ({
        url: `${ADMIN_URL}/announcements/${id}/publish`,
        method: "POST",
        body: at ? { at } : {},
      }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, arg: { id: string }) => [
        { type: "AdminAnnouncement", id: arg.id },
        "AdminAnnouncements",
      ],
    }),
    endAnnouncement: builder.mutation({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}/end`, method: "POST" }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: (_r: any, _e: any, id: string) => [{ type: "AdminAnnouncement", id }, "AdminAnnouncements"],
    }),
    deleteAnnouncement: builder.mutation({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}`, method: "DELETE" }),
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
      invalidatesTags: ["AdminAnnouncements"],
    }),
    // Asked right before the confirm dialog; never served from cache.
    getAnnouncementAudience: builder.query({
      query: (id: string) => ({ url: `${ADMIN_URL}/announcements/${id}/audience-count` }),
      transformResponse: unwrap,
      keepUnusedDataFor: 0,
    }),
    uploadAnnouncementImage: builder.mutation({
      query: (file: File) => {
        const form = new FormData();
        form.append("image", file);
        return { url: `${ADMIN_URL}/announcements/upload-image`, method: "POST", body: form };
      },
      transformResponse: unwrap,
      extraOptions: { maxRetries: 0 },
    }),
```
  - in the `export const { … } = adminApiSlice;` list, after `useGetAnalyticsVisitsQuery,`:
```ts
  useListAnnouncementsQuery,
  useGetAnnouncementQuery,
  useCreateAnnouncementMutation,
  useUpdateAnnouncementMutation,
  usePublishAnnouncementMutation,
  useEndAnnouncementMutation,
  useDeleteAnnouncementMutation,
  useLazyGetAnnouncementAudienceQuery,
  useUploadAnnouncementImageMutation,
```
  - create `WEB/docs/REMAINING_WORK.md`:
```md
# Remaining work — web

Last updated: 2026-10-12. Tick items off in the same commit that finishes them.
The full owner/launch checklist lives in the app repo: `bananatalk_app/docs/REMAINING_WORK.md`.

## Admin announcements (2026-10-12) — plan bananatalk_app/docs/superpowers/plans/parts/10-ops-backend-web.md
- [x] W1 slice endpoints
- [ ] W2 form rules · W3 list page + nav · W4 editor · W5 publish/schedule/end with audience confirm
- [ ] Usable only after the backend announcements deploy (B1–B11)
```
- [ ] Step 4: run → 6 passing; `CI=true npx react-scripts test --watchAll=false src/store/slices/adminSlice.test.ts` → passing.
- [ ] Step 5: commit
```
git add src/store/slices/adminSlice.ts src/store/slices/apiSlice.ts src/store/slices/adminAnnouncementsEndpoints.test.ts docs/REMAINING_WORK.md
git commit -m "feat(admin): announcements endpoints in the admin slice

List/get/create/update/publish/end/delete, audience count and image upload
for /api/v1/admin/announcements; writes never retried.

REMAINING_WORK: created docs/REMAINING_WORK.md for this repo; ticked W1.
Still open: W2-W5; backend deploy of B1-B11.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task W2: form model and validation (mirrors the backend limits)

**Files:** Create `WEB/src/components/admin/parts/announcementForm.ts`; Test `WEB/src/components/admin/parts/announcementForm.test.ts`
**Interfaces:** Consumes `AdminAnnouncement`, `AnnouncementInput`, `AnnouncementPlatform`. Produces `ANNOUNCEMENT_LOCALES`, `LOCALE_LABELS`, `ANNOUNCEMENT_LIMITS`, `BUTTON_URL_RE`, `AnnouncementForm`, `TranslationDraft`, `FormErrors`, `emptyForm`, `fromAnnouncement`, `toInput`, `validateForm`, `toLocalInput`, `fromLocalInput`, `targetingSummary`, `defaultTitle`.

- [ ] Step 1: failing test `WEB/src/components/admin/parts/announcementForm.test.ts`
```ts
import {
  ANNOUNCEMENT_LOCALES, emptyForm, fromAnnouncement, toInput, validateForm,
  toLocalInput, fromLocalInput, targetingSummary, AnnouncementForm,
} from "./announcementForm";

const filled = (over: Partial<AnnouncementForm> = {}): AnnouncementForm => ({
  ...emptyForm(),
  translations: { en: { title: "Hello", body: "World", buttonLabel: "" } },
  ...over,
});

it("covers the 19 backend template locales", () => {
  expect(ANNOUNCEMENT_LOCALES).toHaveLength(19);
  expect(ANNOUNCEMENT_LOCALES).toContain("zh_TW");
});

it("an empty form needs title and body in the default language", () => {
  const errors = validateForm(emptyForm());
  expect(errors["translations.en.title"]).toBeTruthy();
  expect(errors["translations.en.body"]).toBeTruthy();
  expect(validateForm(filled())).toEqual({});
});

it("limits mirror the backend: title 100, body 1000, button label 40", () => {
  const long = (n: number) => "x".repeat(n);
  expect(validateForm(filled({ translations: { en: { title: long(101), body: "b", buttonLabel: "" } } }))["translations.en.title"]).toMatch(/100/);
  expect(validateForm(filled({ translations: { en: { title: "t", body: long(1001), buttonLabel: "" } } }))["translations.en.body"]).toMatch(/1000/);
  expect(validateForm(filled({ translations: { en: { title: "t", body: "b", buttonLabel: long(41) } }, buttonUrl: "/x" }))["translations.en.buttonLabel"]).toMatch(/40/);
});

it("a second language with any text needs both title and body", () => {
  const errors = validateForm(filled({
    translations: { en: { title: "t", body: "b", buttonLabel: "" }, ko: { title: "제목", body: "", buttonLabel: "" } },
  }));
  expect(errors["translations.ko.body"]).toBeTruthy();
});

it("button link: https, bananatalk:// or /path; a label needs a link", () => {
  expect(validateForm(filled({ buttonUrl: "javascript:alert(1)" })).buttonUrl).toBeTruthy();
  ["https://banatalk.com", "bananatalk://moment/1", "/study"].forEach((url) =>
    expect(validateForm(filled({ buttonUrl: url })).buttonUrl).toBeUndefined());
  expect(validateForm(filled({ translations: { en: { title: "t", body: "b", buttonLabel: "Open" } } })).buttonUrl).toBeTruthy();
});

it("end after start; at least one channel; at least one platform; whole-number priority", () => {
  expect(validateForm(filled({ startsAt: "2030-01-02T10:00", endsAt: "2030-01-02T09:00" })).endsAt).toBeTruthy();
  expect(validateForm(filled({ showInApp: false, notify: false })).channels).toBeTruthy();
  expect(validateForm(filled({ platforms: [] })).platforms).toBeTruthy();
  expect(validateForm(filled({ priority: "1.5" })).priority).toBeTruthy();
});

it("scheduling needs a future start", () => {
  const now = new Date("2030-01-01T00:00:00");
  expect(validateForm(filled(), { schedule: true, now }).startsAt).toBeTruthy();
  expect(validateForm(filled({ startsAt: "2029-12-31T10:00" }), { schedule: true, now }).startsAt).toBeTruthy();
  expect(validateForm(filled({ startsAt: "2030-01-02T10:00" }), { schedule: true, now }).startsAt).toBeUndefined();
});

it("toInput drops empty extra languages, trims, 'all' wins, dates to ISO", () => {
  const input = toInput(filled({
    translations: {
      en: { title: " Hello ", body: "World", buttonLabel: "" },
      ko: { title: "", body: "", buttonLabel: "" },
    },
    platforms: ["all", "ios"],
    startsAt: "2030-01-02T10:00",
    priority: "4",
  }));
  expect(Object.keys(input.translations || {})).toEqual(["en"]);
  expect(input.translations!.en.title).toBe("Hello");
  expect(input.platforms).toEqual(["all"]);
  expect(input.startsAt).toBe(new Date("2030-01-02T10:00").toISOString());
  expect(input.priority).toBe(4);
  expect(input.buttonUrl).toBeNull();
});

it("toInput for a live announcement sends only text, end time and priority", () => {
  expect(Object.keys(toInput(filled(), true)).sort()).toEqual(["endsAt", "priority", "translations"]);
});

it("local datetime round-trips", () => {
  const iso = new Date("2030-05-06T07:08:00").toISOString();
  expect(fromLocalInput(toLocalInput(iso))).toBe(iso);
  expect(toLocalInput(null)).toBe("");
  expect(fromLocalInput("")).toBeNull();
});

it("fromAnnouncement fills the form from a row", () => {
  const form = fromAnnouncement({
    id: "a1", _id: "a1", status: "draft", priority: 2, defaultLocale: "ko",
    translations: { ko: { title: "제목", body: "본문" } },
    emoji: null, imageUrl: null, buttonUrl: null, platforms: ["ios"], languages: ["ko"],
    startsAt: null, endsAt: null, showInApp: true, notify: true, publishedAt: null, endedAt: null,
    delivery: { state: "none", targeted: 0, pushed: 0, listed: 0, failed: 0, startedAt: null, finishedAt: null },
    createdAt: "", updatedAt: "",
  });
  expect(form.translations.ko).toEqual({ title: "제목", body: "본문", buttonLabel: "" });
  expect(form.priority).toBe("2");
  expect(form.notify).toBe(true);
});

it("targeting summary", () => {
  expect(targetingSummary({ platforms: ["all"], languages: [] })).toBe("All platforms · all languages");
  expect(targetingSummary({ platforms: ["ios", "android"], languages: ["ko", "ja"] })).toBe("iOS + Android · ko, ja");
});
```
- [ ] Step 2: run → fails `Cannot find module './announcementForm'`
  `cd WEB && CI=true npx react-scripts test --watchAll=false src/components/admin/parts/announcementForm.test.ts`
- [ ] Step 3: create `WEB/src/components/admin/parts/announcementForm.ts`
```ts
import { AdminAnnouncement, AnnouncementInput, AnnouncementPlatform } from "../../../store/slices/adminSlice";

/**
 * The announcement editor's form model. Every rule here mirrors
 * models/Announcement.js in the backend, so an admin learns about a too-long
 * title before the round trip, not after it.
 */

/** lib/normalizeLocale.js SUPPORTED_LOCALES, in the order the editor shows them. */
export const ANNOUNCEMENT_LOCALES = [
  "en", "ko", "ja", "zh", "zh_TW", "es", "fr", "de", "pt", "ru",
  "ar", "hi", "id", "it", "th", "tl", "tr", "vi", "tg",
];

export const LOCALE_LABELS: { [code: string]: string } = {
  en: "English", ko: "Korean", ja: "Japanese", zh: "Chinese (Simplified)", zh_TW: "Chinese (Traditional)",
  es: "Spanish", fr: "French", de: "German", pt: "Portuguese", ru: "Russian", ar: "Arabic", hi: "Hindi",
  id: "Indonesian", it: "Italian", th: "Thai", tl: "Tagalog", tr: "Turkish", vi: "Vietnamese", tg: "Tajik",
};

export const ANNOUNCEMENT_LIMITS = { title: 100, body: 1000, buttonLabel: 40, buttonUrl: 500, emoji: 16 };

export const BUTTON_URL_RE = /^(https?:\/\/\S+|bananatalk:\/\/\S+|\/\S*)$/;

export interface TranslationDraft {
  title: string;
  body: string;
  buttonLabel: string;
}

export interface AnnouncementForm {
  translations: { [locale: string]: TranslationDraft };
  defaultLocale: string;
  emoji: string;
  imageUrl: string;
  buttonUrl: string;
  platforms: AnnouncementPlatform[];
  languages: string[];
  /** `<input type="datetime-local">` values, in the admin's local time. */
  startsAt: string;
  endsAt: string;
  priority: string;
  showInApp: boolean;
  notify: boolean;
}

export type FormErrors = { [field: string]: string };

export const blankTranslation = (): TranslationDraft => ({ title: "", body: "", buttonLabel: "" });

export const emptyForm = (): AnnouncementForm => ({
  translations: { en: blankTranslation() },
  defaultLocale: "en",
  emoji: "📢",
  imageUrl: "",
  buttonUrl: "",
  platforms: ["all"],
  languages: [],
  startsAt: "",
  endsAt: "",
  priority: "0",
  showInApp: true,
  notify: false,
});

const two = (n: number) => ("0" + n).slice(-2);

export const toLocalInput = (iso: string | null | undefined): string => {
  if (!iso) return "";
  const d = new Date(iso);
  if (isNaN(d.getTime())) return "";
  return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())}T${two(d.getHours())}:${two(d.getMinutes())}`;
};

export const fromLocalInput = (value: string): string | null => {
  if (!value) return null;
  const d = new Date(value);
  return isNaN(d.getTime()) ? null : d.toISOString();
};

export const fromAnnouncement = (a: AdminAnnouncement): AnnouncementForm => {
  const translations: { [locale: string]: TranslationDraft } = {};
  Object.keys(a.translations || {}).forEach((locale) => {
    const t = a.translations[locale];
    translations[locale] = { title: t.title || "", body: t.body || "", buttonLabel: t.buttonLabel || "" };
  });
  return {
    translations,
    defaultLocale: a.defaultLocale || "en",
    emoji: a.emoji || "",
    imageUrl: a.imageUrl || "",
    buttonUrl: a.buttonUrl || "",
    platforms: a.platforms && a.platforms.length ? a.platforms : ["all"],
    languages: a.languages || [],
    startsAt: toLocalInput(a.startsAt),
    endsAt: toLocalInput(a.endsAt),
    priority: String(a.priority || 0),
    showInApp: a.showInApp !== false,
    notify: !!a.notify,
  };
};

const hasText = (t: TranslationDraft | undefined) =>
  !!t && (t.title.trim() !== "" || t.body.trim() !== "" || t.buttonLabel.trim() !== "");

/** `liveOnly`: a live announcement may change only text, end time and priority. */
export const toInput = (form: AnnouncementForm, liveOnly = false): AnnouncementInput => {
  const translations: { [locale: string]: TranslationDraft } = {};
  Object.keys(form.translations).forEach((locale) => {
    const t = form.translations[locale];
    if (locale === form.defaultLocale || hasText(t)) {
      translations[locale] = { title: t.title.trim(), body: t.body.trim(), buttonLabel: t.buttonLabel.trim() };
    }
  });
  const priority = parseInt(form.priority, 10) || 0;
  if (liveOnly) {
    return { translations, endsAt: fromLocalInput(form.endsAt), priority };
  }
  return {
    translations,
    defaultLocale: form.defaultLocale,
    emoji: form.emoji.trim(),
    imageUrl: form.imageUrl || null,
    buttonUrl: form.buttonUrl.trim() || null,
    platforms: form.platforms.indexOf("all") >= 0 ? ["all"] : form.platforms,
    languages: form.languages,
    startsAt: fromLocalInput(form.startsAt),
    endsAt: fromLocalInput(form.endsAt),
    showInApp: form.showInApp,
    notify: form.notify,
    priority,
  };
};

export interface ValidateOptions {
  /** Scheduling requires a start time in the future. */
  schedule?: boolean;
  now?: Date;
}

export const validateForm = (form: AnnouncementForm, opts: ValidateOptions = {}): FormErrors => {
  const errors: FormErrors = {};
  const L = ANNOUNCEMENT_LIMITS;
  const def = form.translations[form.defaultLocale];
  const key = (locale: string, field: string) => `translations.${locale}.${field}`;

  if (!def || !def.title.trim()) errors[key(form.defaultLocale, "title")] = "Title is required in the default language.";
  if (!def || !def.body.trim()) errors[key(form.defaultLocale, "body")] = "Body is required in the default language.";

  Object.keys(form.translations).forEach((locale) => {
    const t = form.translations[locale];
    if (locale !== form.defaultLocale && hasText(t)) {
      if (!t.title.trim()) errors[key(locale, "title")] = "Title is required once this language has text.";
      if (!t.body.trim()) errors[key(locale, "body")] = "Body is required once this language has text.";
    }
    if (t.title.trim().length > L.title) errors[key(locale, "title")] = `Title is limited to ${L.title} characters.`;
    if (t.body.trim().length > L.body) errors[key(locale, "body")] = `Body is limited to ${L.body} characters.`;
    if (t.buttonLabel.trim().length > L.buttonLabel) {
      errors[key(locale, "buttonLabel")] = `Button label is limited to ${L.buttonLabel} characters.`;
    }
  });

  const url = form.buttonUrl.trim();
  const anyLabel = Object.keys(form.translations).some((l) => form.translations[l].buttonLabel.trim() !== "");
  if (url && (url.length > L.buttonUrl || !BUTTON_URL_RE.test(url))) {
    errors.buttonUrl = "Use https://…, bananatalk://… or an app path starting with /.";
  } else if (anyLabel && !url) {
    errors.buttonUrl = "Add a link for the button, or clear the button label.";
  }

  if (form.emoji.length > L.emoji) errors.emoji = `Emoji is limited to ${L.emoji} characters.`;
  if (!form.platforms.length) errors.platforms = "Pick at least one platform.";
  if (!form.showInApp && !form.notify) errors.channels = "Turn on Show in app, Send notification, or both.";
  if (!/^-?\d+$/.test(form.priority.trim())) errors.priority = "Priority is a whole number.";

  const start = fromLocalInput(form.startsAt);
  const end = fromLocalInput(form.endsAt);
  if (form.startsAt && !start) errors.startsAt = "Not a valid date.";
  if (form.endsAt && !end) errors.endsAt = "Not a valid date.";
  if (start && end && new Date(end) <= new Date(start)) errors.endsAt = "End must be after start.";
  if (opts.schedule) {
    const now = opts.now || new Date();
    if (!start) errors.startsAt = "Pick a start time to schedule.";
    else if (new Date(start) <= now) errors.startsAt = "A scheduled start must be in the future.";
  }
  return errors;
};

export const targetingSummary = (a: { platforms?: string[]; languages?: string[] }): string => {
  const platforms = a.platforms || [];
  const p = !platforms.length || platforms.indexOf("all") >= 0
    ? "All platforms"
    : platforms.map((x) => (x === "ios" ? "iOS" : "Android")).join(" + ");
  const languages = a.languages || [];
  return `${p} · ${languages.length ? languages.join(", ") : "all languages"}`;
};

/** Title in the default language, for tables and audit-style labels. */
export const defaultTitle = (a: { translations?: { [l: string]: { title: string } }; defaultLocale?: string }): string => {
  const t = a.translations && a.defaultLocale ? a.translations[a.defaultLocale] : null;
  return (t && t.title) || "";
};
```
- [ ] Step 4: run → 12 passing.
- [ ] Step 5: commit
```
git add src/components/admin/parts/announcementForm.ts src/components/admin/parts/announcementForm.test.ts docs/REMAINING_WORK.md
git commit -m "feat(admin): announcement form model mirroring backend limits

REMAINING_WORK: ticked W2.
Still open: W3-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task W3: Announcements list page, nav item, routes

**Files:** Create `WEB/src/components/admin/pages/AdminAnnouncements.tsx`; Modify `WEB/src/components/admin/AdminLayout.tsx`, `WEB/src/router/routes.tsx`; Test `WEB/src/components/admin/pages/AdminAnnouncements.test.tsx`
**Interfaces:** Consumes `useListAnnouncementsQuery`, `targetingSummary`, `defaultTitle`. Produces routes `/admin/announcements` and `/admin/announcements/:id` (`:id` = `new` for create; the editor arrives in W4).

- [ ] Step 1: failing test `WEB/src/components/admin/pages/AdminAnnouncements.test.tsx`
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import AdminAnnouncements from "./AdminAnnouncements";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockList = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  useListAnnouncementsQuery: (...args: any[]) => mockList(...args),
}));

const ROWS = [
  {
    id: "a1", _id: "a1", status: "live", priority: 5, defaultLocale: "en", emoji: "🎉",
    translations: { en: { title: "Study Hub is here" } }, platforms: ["all"], languages: [],
    startsAt: "2026-10-12T09:00:00.000Z", endsAt: null, notify: true, showInApp: true,
    delivery: { state: "done", targeted: 1200, pushed: 410, listed: 1200, failed: 3 },
  },
  {
    id: "a2", _id: "a2", status: "draft", priority: 0, defaultLocale: "ko", emoji: null,
    translations: { ko: { title: "공지" } }, platforms: ["ios"], languages: ["ko"],
    startsAt: null, endsAt: null, notify: false, showInApp: true,
    delivery: { state: "none", targeted: 0, pushed: 0, listed: 0, failed: 0 },
  },
];

const ok = (data: any, extra: any = {}) => ({ data, isLoading: false, isFetching: false, isError: false, refetch: jest.fn(), ...extra });

const LocationProbe = () => {
  const location = useLocation();
  return <div data-testid="location">{location.pathname + location.search}</div>;
};

const renderPage = (path = "/admin/announcements") =>
  render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/admin/announcements" element={<><AdminAnnouncements /><LocationProbe /></>} />
        <Route path="/admin/announcements/:id" element={<LocationProbe />} />
      </Routes>
    </MemoryRouter>
  );

beforeEach(() => {
  mockList.mockReset().mockReturnValue(ok(ROWS));
});

it("renders heading, rows, status, audience and delivery stats", () => {
  renderPage();
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Announcements");
  expect(screen.getByText("🎉 Study Hub is here")).toBeInTheDocument();
  expect(screen.getByText("공지")).toBeInTheDocument();
  expect(screen.getByText("All platforms · all languages")).toBeInTheDocument();
  expect(screen.getByText("iOS · ko")).toBeInTheDocument();
  expect(screen.getByText("1,200 / 410 / 1,200 / 3")).toBeInTheDocument();
  expect(screen.getAllByTestId("announcement-status").map((n) => n.textContent)).toEqual(["live", "draft"]);
});

it("asks for every status by default and narrows by the status filter in the URL", () => {
  renderPage();
  expect(mockList).toHaveBeenLastCalledWith({});
  fireEvent.click(screen.getByRole("button", { name: "Live" }));
  expect(mockList).toHaveBeenLastCalledWith({ status: "live" });
  expect(screen.getByTestId("location")).toHaveTextContent("/admin/announcements?status=live");
});

it("opens the editor on row click and from New announcement", () => {
  renderPage();
  fireEvent.click(screen.getAllByTestId("data-row")[0]);
  expect(screen.getByTestId("location")).toHaveTextContent("/admin/announcements/a1");
});

it("New announcement links to the create editor", () => {
  renderPage();
  expect(screen.getByRole("link", { name: "New announcement" })).toHaveAttribute("href", "/admin/announcements/new");
});

it("shows an error state when the list fails, and a loading state while it loads", () => {
  mockList.mockReturnValue(ok(undefined, { isError: true }));
  const { unmount } = renderPage();
  expect(screen.getByRole("alert")).toHaveTextContent("Couldn't load announcements.");
  unmount();
  mockList.mockReturnValue(ok(undefined, { isLoading: true }));
  renderPage();
  expect(screen.getByText("Loading…")).toBeInTheDocument();
});
```
- [ ] Step 2: run → fails `Cannot find module './AdminAnnouncements'`
  `cd WEB && CI=true npx react-scripts test --watchAll=false src/components/admin/pages/AdminAnnouncements.test.tsx`
- [ ] Step 3: implement
  - create `WEB/src/components/admin/pages/AdminAnnouncements.tsx`:
```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useListAnnouncementsQuery } from "../../../store/slices/adminSlice";
import { Badge } from "../../../design";
import DataTable from "../parts/DataTable";
import RefreshButton from "../parts/RefreshButton";
import { targetingSummary, defaultTitle } from "../parts/announcementForm";

/**
 * Every announcement, newest first, with what it targets and what its send
 * did. The status filter lives in `?status=` (like AdminContent's `?tab=`)
 * so a refresh or a pasted link lands on the same view.
 */

const FILTERS = ["all", "draft", "scheduled", "live", "ended"];

const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString("en-US") : "—";

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

const AdminAnnouncements: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const requested = searchParams.get("status") || "all";
  const status = FILTERS.indexOf(requested) >= 0 ? requested : "all";

  const list = useListAnnouncementsQuery(status === "all" ? {} : { status });
  const rows: any[] = Array.isArray(list.data) ? list.data : [];

  const filterLabel = (value: string): string => {
    if (value === "all") return t("admin.announcements.all") || "All";
    if (value === "draft") return t("admin.announcements.draft") || "Draft";
    if (value === "scheduled") return t("admin.announcements.scheduled") || "Scheduled";
    if (value === "live") return t("admin.announcements.live") || "Live";
    return t("admin.announcements.ended") || "Ended";
  };

  const selectFilter = (value: string) => {
    const params = new URLSearchParams(searchParams);
    if (value === "all") params.delete("status");
    else params.set("status", value);
    setSearchParams(params, { replace: true });
  };

  const columns = [
    {
      key: "title",
      header: t("admin.announcements.title") || "Title",
      render: (row: any) => (
        <span className="font-medium text-ink-900 dark:text-ink-50">
          {row.emoji ? `${row.emoji} ` : ""}
          {defaultTitle(row) || "—"}
        </span>
      ),
    },
    {
      key: "status",
      header: t("admin.announcements.status") || "Status",
      render: (row: any) => (
        <span data-testid="announcement-status">
          <Badge tone={row.status === "live" || row.status === "scheduled" ? "brand" : "banana"}>{row.status}</Badge>
        </span>
      ),
    },
    {
      key: "targeting",
      header: t("admin.announcements.audience") || "Audience",
      render: (row: any) => targetingSummary(row),
    },
    {
      key: "window",
      header: t("admin.announcements.window") || "Start → end",
      className: "whitespace-nowrap",
      render: (row: any) =>
        `${formatWhen(row.startsAt)} → ${row.endsAt ? formatWhen(row.endsAt) : t("admin.announcements.noEnd") || "no end"}`,
    },
    {
      key: "delivery",
      header: t("admin.announcements.deliveryHeader") || "Targeted / pushed / listed / failed",
      className: "text-right tabular-nums",
      render: (row: any) => {
        const d = row.delivery || {};
        return row.notify ? `${num(d.targeted)} / ${num(d.pushed)} / ${num(d.listed)} / ${num(d.failed)}` : "—";
      },
    },
  ];

  const chipClass = (selected: boolean) =>
    [
      "rounded-chip px-3 py-1.5 text-sm font-medium transition-colors",
      selected
        ? "bg-brand-deep text-white"
        : "border border-line text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
    ].join(" ");

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-display-sm text-ink-900 dark:text-ink-50">
          {t("admin.nav.announcements") || "Announcements"}
        </h1>
        <div className="flex items-center gap-2">
          <RefreshButton
            label={t("admin.common.refresh") || "Refresh"}
            isFetching={list.isFetching}
            onRefresh={() => list.refetch()}
          />
          <Link
            to="/admin/announcements/new"
            className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-medium text-white hover:opacity-90"
          >
            {t("admin.announcements.new") || "New announcement"}
          </Link>
        </div>
      </header>

      <div className="flex flex-wrap gap-2" aria-label={t("admin.announcements.filter") || "Filter by status"}>
        {FILTERS.map((value) => (
          <button
            key={value}
            type="button"
            aria-pressed={status === value}
            className={chipClass(status === value)}
            onClick={() => selectFilter(value)}
          >
            {filterLabel(value)}
          </button>
        ))}
      </div>

      {list.isError ? (
        <p role="alert" className="rounded-card border border-line p-4 text-sm text-red-600 dark:border-line-dark">
          {t("admin.announcements.loadError") || "Couldn't load announcements."}
        </p>
      ) : list.isLoading ? (
        <p className="text-sm text-ink-500">{t("admin.common.loading") || "Loading…"}</p>
      ) : (
        <DataTable
          columns={columns}
          rows={rows}
          rowKey="id"
          onRowClick={(row: any) => navigate(`/admin/announcements/${row.id}`)}
          emptyText={t("admin.announcements.empty") || "No announcements yet."}
        />
      )}
    </div>
  );
};

export default AdminAnnouncements;
```
  - `AdminLayout.tsx` `SECTIONS`: after the `content` entry add
```ts
  { to: "/admin/announcements", key: "admin.nav.announcements", label: "Announcements" },
```
  - `routes.tsx`: after the `AdminAudit` lazy line add
```tsx
const AdminAnnouncements = lazyWithRetry("../components/admin/pages/AdminAnnouncements", () => import("../components/admin/pages/AdminAnnouncements"));
```
    and inside `<Route path="admin" …>` after the `audit` route:
```tsx
      <Route path="announcements" element={lazyAdminRoute(<AdminAnnouncements />)} />
```
    (the `announcements/:id` route is added in W4 together with its page.)
- [ ] Step 4: run → 5 passing; `npx eslint src/components/admin/pages/AdminAnnouncements.tsx src/router/routes.tsx src/components/admin/AdminLayout.tsx` → exit 0 (`tsc` on TS 3.7 cannot parse current node_modules typings, so lint + jest are the checks).
- [ ] Step 5: commit
```
git add src/components/admin/pages/AdminAnnouncements.tsx src/components/admin/pages/AdminAnnouncements.test.tsx src/components/admin/AdminLayout.tsx src/router/routes.tsx docs/REMAINING_WORK.md
git commit -m "feat(admin): Announcements list page and nav item

Title, status, audience, window and delivery stats per announcement;
status filter in ?status=; row opens the editor.

REMAINING_WORK: ticked W3.
Still open: W4-W5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task W4: editor page — per-language text, targeting, schedule, image, live preview, Save draft

**Files:** Create `WEB/src/components/admin/parts/AnnouncementPreview.tsx`, `WEB/src/components/admin/pages/AdminAnnouncementEditor.tsx`; Modify `WEB/src/router/routes.tsx`; Test `WEB/src/components/admin/pages/AdminAnnouncementEditor.test.tsx`
**Interfaces:** Consumes `useGetAnnouncementQuery`, `useCreateAnnouncementMutation`, `useUpdateAnnouncementMutation`, `useUploadAnnouncementImageMutation`, W2's form module. Produces route `/admin/announcements/:id` and the editor's `save({ schedule })` that W5 calls.

Rules: `:id === "new"` creates; draft/scheduled edit everything; live edits only text, end time and priority (other inputs disabled, `toInput(form, true)`); ended is read-only.

- [ ] Step 1: failing test `WEB/src/components/admin/pages/AdminAnnouncementEditor.test.tsx`
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import AdminAnnouncementEditor from "./AdminAnnouncementEditor";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockGet = jest.fn();
const mockCreate = jest.fn();
const mockUpdate = jest.fn();
const mockUpload = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  useGetAnnouncementQuery: (...args: any[]) => mockGet(...args),
  useCreateAnnouncementMutation: () => mockCreate(),
  useUpdateAnnouncementMutation: () => mockUpdate(),
  useUploadAnnouncementImageMutation: () => mockUpload(),
}));

const LIVE = {
  id: "a1", _id: "a1", status: "live", priority: 3, defaultLocale: "en",
  translations: { en: { title: "Live title", body: "Live body", buttonLabel: "" } },
  emoji: "🎉", imageUrl: null, buttonUrl: null, platforms: ["ios"], languages: [],
  startsAt: "2026-10-12T09:00:00.000Z", endsAt: null, showInApp: true, notify: false,
  publishedAt: null, endedAt: null, updatedAt: "2026-10-12T09:00:00.000Z", createdAt: "",
  delivery: { state: "none", targeted: 0, pushed: 0, listed: 0, failed: 0, startedAt: null, finishedAt: null },
};

let createTrigger: jest.Mock;
let updateTrigger: jest.Mock;
let uploadTrigger: jest.Mock;
const resolved = (value: any) => jest.fn(() => ({ unwrap: () => Promise.resolve(value) }));

const LocationProbe = () => <div data-testid="location">{useLocation().pathname}</div>;
const renderAt = (path: string) =>
  render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/admin/announcements/:id" element={<><AdminAnnouncementEditor /><LocationProbe /></>} />
      </Routes>
    </MemoryRouter>
  );

beforeEach(() => {
  mockGet.mockReset().mockReturnValue({ data: undefined, isLoading: false, isError: false });
  createTrigger = resolved({ ...LIVE, id: "a9", status: "draft" });
  updateTrigger = resolved(LIVE);
  uploadTrigger = resolved({ url: "https://cdn/up.jpg" });
  mockCreate.mockReset().mockReturnValue([createTrigger, { isLoading: false }]);
  mockUpdate.mockReset().mockReturnValue([updateTrigger, { isLoading: false }]);
  mockUpload.mockReset().mockReturnValue([uploadTrigger, { isLoading: false }]);
});

it("new: Save draft with no text shows the default-language errors and sends nothing", () => {
  renderAt("/admin/announcements/new");
  expect(mockGet).toHaveBeenLastCalledWith(null, { skip: true });
  fireEvent.click(screen.getByRole("button", { name: "Save draft" }));
  expect(screen.getByTestId("error-translations.en.title")).toBeInTheDocument();
  expect(screen.getByTestId("error-translations.en.body")).toBeInTheDocument();
  expect(createTrigger).not.toHaveBeenCalled();
});

it("new: a valid draft is created with the form payload and the URL moves to its id", async () => {
  renderAt("/admin/announcements/new");
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Hello" } });
  fireEvent.change(screen.getByLabelText("Body"), { target: { value: "World" } });
  fireEvent.click(screen.getByLabelText("Send notification"));
  fireEvent.click(screen.getByRole("button", { name: "Save draft" }));
  await waitFor(() => expect(screen.getByTestId("location")).toHaveTextContent("/admin/announcements/a9"));
  const body = createTrigger.mock.calls[0][0];
  expect(body.translations).toEqual({ en: { title: "Hello", body: "World", buttonLabel: "" } });
  expect(body.notify).toBe(true);
  expect(body.platforms).toEqual(["all"]);
});

it("an invalid button link is caught before the request", () => {
  renderAt("/admin/announcements/new");
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Hello" } });
  fireEvent.change(screen.getByLabelText("Body"), { target: { value: "World" } });
  fireEvent.change(screen.getByLabelText("Button link"), { target: { value: "javascript:x" } });
  fireEvent.click(screen.getByRole("button", { name: "Save draft" }));
  expect(screen.getByTestId("error-buttonUrl")).toBeInTheDocument();
  expect(createTrigger).not.toHaveBeenCalled();
});

it("per-language tabs edit their own text; the preview follows the open tab", () => {
  renderAt("/admin/announcements/new");
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Hello" } });
  fireEvent.click(screen.getByRole("tab", { name: "Korean" }));
  expect(screen.getByLabelText("Title")).toHaveValue("");
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: "안녕" } });
  expect(screen.getByTestId("announcement-preview")).toHaveTextContent("안녕");
  fireEvent.click(screen.getByRole("tab", { name: "English" }));
  expect(screen.getByLabelText("Title")).toHaveValue("Hello");
});

it("live: targeting is locked and Save sends only text, end time and priority", async () => {
  mockGet.mockReturnValue({ data: LIVE, isLoading: false, isError: false });
  renderAt("/admin/announcements/a1");
  expect(screen.getByLabelText("Title")).toHaveValue("Live title");
  expect(screen.getByLabelText("iOS")).toBeDisabled();
  expect(screen.getByLabelText("Starts")).toBeDisabled();
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Edited" } });
  fireEvent.click(screen.getByRole("button", { name: "Save" }));
  await waitFor(() => expect(updateTrigger).toHaveBeenCalled());
  const arg = updateTrigger.mock.calls[0][0];
  expect(Object.keys(arg).sort()).toEqual(["endsAt", "id", "priority", "translations"]);
  expect(arg.translations.en.title).toBe("Edited");
});

it("ended: read-only, no save button", () => {
  mockGet.mockReturnValue({ data: { ...LIVE, status: "ended" }, isLoading: false, isError: false });
  renderAt("/admin/announcements/a1");
  expect(screen.getByLabelText("Title")).toBeDisabled();
  expect(screen.queryByRole("button", { name: "Save" })).toBeNull();
});

it("image upload fills the image URL and the preview", async () => {
  renderAt("/admin/announcements/new");
  const file = new File(["x"], "x.png", { type: "image/png" });
  fireEvent.change(screen.getByLabelText("Image"), { target: { files: [file] } });
  await waitFor(() => expect(screen.getByTestId("preview-image")).toHaveAttribute("src", "https://cdn/up.jpg"));
  expect(uploadTrigger).toHaveBeenCalledWith(file);
});

it("a failed save shows the server message", async () => {
  createTrigger = jest.fn(() => ({ unwrap: () => Promise.reject({ data: { message: "endsAt must be after startsAt" } }) }));
  mockCreate.mockReturnValue([createTrigger, { isLoading: false }]);
  renderAt("/admin/announcements/new");
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Hello" } });
  fireEvent.change(screen.getByLabelText("Body"), { target: { value: "World" } });
  fireEvent.click(screen.getByRole("button", { name: "Save draft" }));
  expect(await screen.findByRole("alert")).toHaveTextContent("endsAt must be after startsAt");
});

it("shows an error state when the announcement fails to load", () => {
  mockGet.mockReturnValue({ data: undefined, isLoading: false, isError: true });
  renderAt("/admin/announcements/a1");
  expect(screen.getByRole("alert")).toHaveTextContent("Couldn't load this announcement.");
});
```
- [ ] Step 2: run → fails `Cannot find module './AdminAnnouncementEditor'`
  `cd WEB && CI=true npx react-scripts test --watchAll=false src/components/admin/pages/AdminAnnouncementEditor.test.tsx`
- [ ] Step 3: implement
  - create `WEB/src/components/admin/parts/AnnouncementPreview.tsx`:
```tsx
import React from "react";

export interface AnnouncementPreviewProps {
  emoji: string;
  imageUrl: string;
  title: string;
  body: string;
  buttonLabel: string;
}

/**
 * What the app's AnnouncementModal shows (lib/widgets/promo/announcement_modal.dart):
 * emoji, optional image, title, body and one button. A visual stand-in, not a
 * pixel copy — it exists so an admin sees line breaks and length before
 * publishing to everyone.
 */
const AnnouncementPreview: React.FC<AnnouncementPreviewProps> = ({ emoji, imageUrl, title, body, buttonLabel }) => (
  <div
    data-testid="announcement-preview"
    className="mx-auto w-full max-w-xs rounded-3xl border border-line bg-white p-5 text-center shadow-card dark:border-line-dark dark:bg-ink-900"
  >
    {emoji ? <div className="text-4xl" aria-hidden="true">{emoji}</div> : null}
    {imageUrl ? (
      <img data-testid="preview-image" src={imageUrl} alt="" className="mt-3 max-h-40 w-full rounded-card object-cover" />
    ) : null}
    <div className="mt-3 text-lg font-bold text-ink-900 dark:text-ink-50">{title || "Title"}</div>
    <p className="mt-2 whitespace-pre-line text-sm text-ink-600 dark:text-ink-300">{body || "Body"}</p>
    {buttonLabel ? (
      <div className="mt-4 rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white">{buttonLabel}</div>
    ) : null}
  </div>
);

export default AnnouncementPreview;
```
  - create `WEB/src/components/admin/pages/AdminAnnouncementEditor.tsx`:
```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import { Link, useNavigate, useParams } from "react-router-dom";
import {
  useGetAnnouncementQuery,
  useCreateAnnouncementMutation,
  useUpdateAnnouncementMutation,
  useUploadAnnouncementImageMutation,
  AdminAnnouncement,
} from "../../../store/slices/adminSlice";
import { Badge } from "../../../design";
import AnnouncementPreview from "../parts/AnnouncementPreview";
import {
  ANNOUNCEMENT_LOCALES,
  ANNOUNCEMENT_LIMITS,
  LOCALE_LABELS,
  AnnouncementForm,
  FormErrors,
  TranslationDraft,
  blankTranslation,
  emptyForm,
  fromAnnouncement,
  toInput,
  validateForm,
} from "../parts/announcementForm";

/**
 * Create or edit one announcement (spec 2026-10-12 §5.3).
 *
 * `/admin/announcements/new` creates a draft; after the first save the URL
 * moves to the real id (replace, so Back returns to the list). What may be
 * edited follows the backend: draft/scheduled everything, live only text,
 * end time and priority, ended nothing.
 */

const errorMessage = (err: any, fallback: string): string =>
  (err && err.data && err.data.message) || (err && err.message) || fallback;

const inputClass =
  "w-full rounded-card border border-line bg-white px-3 py-2 text-sm text-ink-900 disabled:opacity-60 dark:border-line-dark dark:bg-ink-900 dark:text-ink-50";
const labelClass = "block text-sm font-medium text-ink-700 dark:text-ink-200";

const FieldError: React.FC<{ errors: FormErrors; name: string }> = ({ errors, name }) =>
  errors[name] ? (
    <p data-testid={`error-${name}`} className="mt-1 text-xs text-red-600">
      {errors[name]}
    </p>
  ) : null;

const AdminAnnouncementEditor: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const params = useParams<{ id: string }>();
  const id = params.id && params.id !== "new" ? params.id : null;

  const existing = useGetAnnouncementQuery(id, { skip: !id });
  const [createAnnouncement, createState] = useCreateAnnouncementMutation();
  const [updateAnnouncement, updateState] = useUpdateAnnouncementMutation();
  const [uploadImage, uploadState] = useUploadAnnouncementImageMutation();

  const doc: AdminAnnouncement | null = id && existing.data ? existing.data : null;
  const status = doc ? doc.status : "draft";
  const liveOnly = status === "live";
  const readOnly = status === "ended";
  const lockTargeting = liveOnly || readOnly;

  const [form, setForm] = React.useState<AnnouncementForm>(emptyForm());
  const [tab, setTab] = React.useState("en");
  const [errors, setErrors] = React.useState<FormErrors>({});
  const [actionError, setActionError] = React.useState("");
  const [notice, setNotice] = React.useState("");

  // Re-seed the form only when a different document (or a newer save) arrives,
  // never on a refetch of the same version, so typing isn't overwritten.
  const docVersion = doc ? `${doc.id}:${doc.updatedAt}` : "";
  React.useEffect(() => {
    if (!doc) return;
    setForm(fromAnnouncement(doc));
    setTab(doc.defaultLocale || "en");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [docVersion]);

  const text: TranslationDraft = form.translations[tab] || blankTranslation();

  const setField = <K extends keyof AnnouncementForm>(key: K, value: AnnouncementForm[K]) =>
    setForm((f) => ({ ...f, [key]: value }));

  const setText = (field: keyof TranslationDraft, value: string) =>
    setForm((f) => ({
      ...f,
      translations: { ...f.translations, [tab]: { ...(f.translations[tab] || blankTranslation()), [field]: value } },
    }));

  const toggle = (list: string[], value: string): string[] =>
    list.indexOf(value) >= 0 ? list.filter((v) => v !== value) : list.concat(value);

  /** Validate, then create or update. Resolves to the saved row, or null. W5 reuses it. */
  const save = async (opts: { schedule?: boolean } = {}): Promise<AdminAnnouncement | null> => {
    const found = validateForm(form, { schedule: opts.schedule });
    setErrors(found);
    setActionError("");
    setNotice("");
    if (Object.keys(found).length) return null;
    try {
      const body = toInput(form, liveOnly);
      const saved: AdminAnnouncement = id
        ? await updateAnnouncement({ id, ...body }).unwrap()
        : await createAnnouncement(body).unwrap();
      if (!id) navigate(`/admin/announcements/${saved.id}`, { replace: true });
      return saved;
    } catch (err) {
      setActionError(errorMessage(err, t("admin.common.actionError") || "Something went wrong."));
      return null;
    }
  };

  const onSave = async () => {
    if (await save()) setNotice(t("admin.announcements.saved") || "Saved.");
  };

  const onImage = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files && event.target.files[0];
    if (!file) return;
    setActionError("");
    try {
      const result: { url: string } = await uploadImage(file).unwrap();
      setField("imageUrl", result.url);
    } catch (err) {
      setActionError(errorMessage(err, t("admin.announcements.uploadError") || "Couldn't upload the image."));
    }
  };

  if (id && existing.isError) {
    return (
      <p role="alert" className="rounded-card border border-line p-4 text-sm text-red-600 dark:border-line-dark">
        {t("admin.announcements.loadOneError") || "Couldn't load this announcement."}
      </p>
    );
  }
  if (id && (existing.isLoading || !doc)) {
    return <p className="text-sm text-ink-500">{t("admin.common.loading") || "Loading…"}</p>;
  }

  const busy = createState.isLoading || updateState.isLoading;
  const filled = (locale: string) => {
    const tr = form.translations[locale];
    return !!tr && (tr.title.trim() !== "" || tr.body.trim() !== "");
  };

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <Link to="/admin/announcements" className="text-sm text-brand-deep hover:underline dark:text-brand-light">
            {t("admin.announcements.back") || "← Announcements"}
          </Link>
          <h1 className="font-display text-display-sm text-ink-900 dark:text-ink-50">
            {id ? t("admin.announcements.edit") || "Edit announcement" : t("admin.announcements.new") || "New announcement"}
          </h1>
          <Badge tone={status === "live" || status === "scheduled" ? "brand" : "banana"}>{status}</Badge>
        </div>
      </header>

      {liveOnly ? (
        <p className="text-sm text-ink-600 dark:text-ink-300">
          {t("admin.announcements.liveHint") || "Live: only the text, end time and priority can change."}
        </p>
      ) : null}

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_20rem]">
        <form className="space-y-5" onSubmit={(e) => e.preventDefault()} noValidate>
          <div role="tablist" aria-label={t("admin.announcements.languages") || "Languages"} className="flex flex-wrap gap-1">
            {ANNOUNCEMENT_LOCALES.map((locale) => (
              <button
                key={locale}
                type="button"
                role="tab"
                aria-selected={tab === locale}
                aria-label={LOCALE_LABELS[locale]}
                onClick={() => setTab(locale)}
                className={[
                  "rounded-chip px-2.5 py-1 text-xs font-medium",
                  tab === locale ? "bg-brand-deep text-white" : "border border-line text-ink-700 dark:border-line-dark dark:text-ink-200",
                ].join(" ")}
              >
                {locale}
                {filled(locale) ? " •" : ""}
                {locale === form.defaultLocale ? " ★" : ""}
              </button>
            ))}
          </div>

          <div>
            <label htmlFor="ann-title" className={labelClass}>{t("admin.announcements.titleField") || "Title"}</label>
            <input id="ann-title" className={inputClass} value={text.title} disabled={readOnly}
              maxLength={ANNOUNCEMENT_LIMITS.title} onChange={(e) => setText("title", e.target.value)} />
            <FieldError errors={errors} name={`translations.${tab}.title`} />
          </div>
          <div>
            <label htmlFor="ann-body" className={labelClass}>{t("admin.announcements.bodyField") || "Body"}</label>
            <textarea id="ann-body" rows={5} className={inputClass} value={text.body} disabled={readOnly}
              maxLength={ANNOUNCEMENT_LIMITS.body} onChange={(e) => setText("body", e.target.value)} />
            <div className="text-right text-xs text-ink-400">{text.body.length}/{ANNOUNCEMENT_LIMITS.body}</div>
            <FieldError errors={errors} name={`translations.${tab}.body`} />
          </div>
          <div>
            <label htmlFor="ann-button-label" className={labelClass}>{t("admin.announcements.buttonLabel") || "Button label"}</label>
            <input id="ann-button-label" className={inputClass} value={text.buttonLabel} disabled={readOnly}
              maxLength={ANNOUNCEMENT_LIMITS.buttonLabel} onChange={(e) => setText("buttonLabel", e.target.value)} />
            <FieldError errors={errors} name={`translations.${tab}.buttonLabel`} />
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label htmlFor="ann-default" className={labelClass}>{t("admin.announcements.defaultLanguage") || "Default language"}</label>
              <select id="ann-default" className={inputClass} value={form.defaultLocale} disabled={lockTargeting}
                onChange={(e) => setField("defaultLocale", e.target.value)}>
                {ANNOUNCEMENT_LOCALES.map((l) => <option key={l} value={l}>{LOCALE_LABELS[l]}</option>)}
              </select>
            </div>
            <div>
              <label htmlFor="ann-emoji" className={labelClass}>{t("admin.announcements.emoji") || "Emoji"}</label>
              <input id="ann-emoji" className={inputClass} value={form.emoji} disabled={lockTargeting}
                onChange={(e) => setField("emoji", e.target.value)} />
              <FieldError errors={errors} name="emoji" />
            </div>
            <div>
              <label htmlFor="ann-image" className={labelClass}>{t("admin.announcements.image") || "Image"}</label>
              <input id="ann-image" type="file" accept="image/jpeg,image/png,image/webp,image/gif"
                disabled={lockTargeting || uploadState.isLoading} onChange={onImage} className="text-sm" />
              {form.imageUrl && !lockTargeting ? (
                <button type="button" className="ml-2 text-xs text-red-600" onClick={() => setField("imageUrl", "")}>
                  {t("admin.announcements.removeImage") || "Remove image"}
                </button>
              ) : null}
            </div>
            <div>
              <label htmlFor="ann-url" className={labelClass}>{t("admin.announcements.buttonUrl") || "Button link"}</label>
              <input id="ann-url" className={inputClass} value={form.buttonUrl} disabled={lockTargeting}
                placeholder="https://… · bananatalk://… · /study" onChange={(e) => setField("buttonUrl", e.target.value)} />
              <FieldError errors={errors} name="buttonUrl" />
            </div>
          </div>

          <fieldset>
            <legend className={labelClass}>{t("admin.announcements.platforms") || "Platforms"}</legend>
            <div className="mt-1 flex gap-4">
              {(["all", "ios", "android"] as Array<"all" | "ios" | "android">).map((p) => (
                <label key={p} className="flex items-center gap-1 text-sm">
                  <input type="checkbox" checked={form.platforms.indexOf(p) >= 0} disabled={lockTargeting}
                    onChange={() => setField("platforms", toggle(form.platforms, p) as Array<"all" | "ios" | "android">)} />
                  {p === "all" ? "All platforms" : p === "ios" ? "iOS" : "Android"}
                </label>
              ))}
            </div>
            <FieldError errors={errors} name="platforms" />
          </fieldset>

          <fieldset>
            <legend className={labelClass}>{t("admin.announcements.appLanguages") || "App languages (none = all)"}</legend>
            <div className="mt-1 grid grid-cols-2 gap-1 sm:grid-cols-4">
              {ANNOUNCEMENT_LOCALES.map((l) => (
                <label key={l} className="flex items-center gap-1 text-xs">
                  <input type="checkbox" aria-label={`Target ${LOCALE_LABELS[l]}`} checked={form.languages.indexOf(l) >= 0}
                    disabled={lockTargeting} onChange={() => setField("languages", toggle(form.languages, l))} />
                  {LOCALE_LABELS[l]}
                </label>
              ))}
            </div>
          </fieldset>

          <div className="grid gap-4 sm:grid-cols-3">
            <div>
              <label htmlFor="ann-start" className={labelClass}>{t("admin.announcements.starts") || "Starts"}</label>
              <input id="ann-start" type="datetime-local" className={inputClass} value={form.startsAt}
                disabled={lockTargeting} onChange={(e) => setField("startsAt", e.target.value)} />
              <FieldError errors={errors} name="startsAt" />
            </div>
            <div>
              <label htmlFor="ann-end" className={labelClass}>{t("admin.announcements.ends") || "Ends"}</label>
              <input id="ann-end" type="datetime-local" className={inputClass} value={form.endsAt}
                disabled={readOnly} onChange={(e) => setField("endsAt", e.target.value)} />
              <FieldError errors={errors} name="endsAt" />
            </div>
            <div>
              <label htmlFor="ann-priority" className={labelClass}>{t("admin.announcements.priority") || "Priority"}</label>
              <input id="ann-priority" type="number" step={1} className={inputClass} value={form.priority}
                disabled={readOnly} onChange={(e) => setField("priority", e.target.value)} />
              <FieldError errors={errors} name="priority" />
            </div>
          </div>

          <div className="flex flex-wrap gap-6">
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" role="switch" checked={form.showInApp} disabled={lockTargeting}
                onChange={(e) => setField("showInApp", e.target.checked)} />
              {t("admin.announcements.showInApp") || "Show in app"}
            </label>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" role="switch" checked={form.notify} disabled={lockTargeting}
                onChange={(e) => setField("notify", e.target.checked)} />
              {t("admin.announcements.notify") || "Send notification"}
            </label>
          </div>
          <FieldError errors={errors} name="channels" />

          {actionError ? (
            <p role="alert" className="text-sm text-red-600">{actionError}</p>
          ) : null}
          {notice ? <p className="text-sm text-ink-600 dark:text-ink-300">{notice}</p> : null}

          {!readOnly ? (
            <div className="flex flex-wrap gap-2" data-testid="editor-actions">
              <button type="button" disabled={busy} onClick={onSave}
                className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:opacity-60 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800">
                {status === "draft" ? t("admin.announcements.saveDraft") || "Save draft" : t("admin.announcements.save") || "Save"}
              </button>
            </div>
          ) : null}
        </form>

        <aside>
          <div className="mb-2 text-eyebrow uppercase text-ink-400">{t("admin.announcements.preview") || "Preview"}</div>
          <AnnouncementPreview
            emoji={form.emoji}
            imageUrl={form.imageUrl}
            title={text.title}
            body={text.body}
            buttonLabel={text.buttonLabel}
          />
        </aside>
      </div>
    </div>
  );
};

export default AdminAnnouncementEditor;
```
  - `routes.tsx`: after the `AdminAnnouncements` lazy line add
```tsx
const AdminAnnouncementEditor = lazyWithRetry("../components/admin/pages/AdminAnnouncementEditor", () => import("../components/admin/pages/AdminAnnouncementEditor"));
```
    and after the `announcements` route:
```tsx
      <Route path="announcements/:id" element={lazyAdminRoute(<AdminAnnouncementEditor />)} />
```
- [ ] Step 4: run → 9 passing; `npx eslint src/components/admin/pages/AdminAnnouncementEditor.tsx src/components/admin/parts/AnnouncementPreview.tsx src/router/routes.tsx` → exit 0.
- [ ] Step 5: commit
```
git add src/components/admin/parts/AnnouncementPreview.tsx src/components/admin/pages/AdminAnnouncementEditor.tsx src/components/admin/pages/AdminAnnouncementEditor.test.tsx src/router/routes.tsx docs/REMAINING_WORK.md
git commit -m "feat(admin): announcement editor with per-language text and live preview

Create and edit drafts: 19 language tabs with the default required, emoji,
image upload, button link, platform/language targeting, schedule window,
priority and channel switches; live announcements edit only text, end time
and priority; ended is read-only.

REMAINING_WORK: ticked W4.
Still open: W5 (schedule / publish now / end now with audience confirm).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task W5: Schedule · Publish now · End now, with the audience-count confirm

**Files:** Create `WEB/src/components/admin/parts/AnnouncementPublishBar.tsx`; Modify `WEB/src/components/admin/pages/AdminAnnouncementEditor.tsx`, `WEB/src/components/admin/pages/AdminAnnouncementEditor.test.tsx`; Test `WEB/src/components/admin/parts/AnnouncementPublishBar.test.tsx`
**Interfaces:** Consumes `usePublishAnnouncementMutation`, `useEndAnnouncementMutation`, `useLazyGetAnnouncementAudienceQuery`, `ConfirmDialog`, the editor's `save({ schedule })`. Produces `<AnnouncementPublishBar announcementId status notify startsAtIso prepare onDone />`.

Flow: Publish/Schedule → `prepare(mode)` (validate + save, returns id) → with `notify` on: fetch audience count → confirm dialog "Sends a push to N people and adds it to M notification lists" → publish; with `notify` off: publish directly. End now → confirm (danger) → end.

- [ ] Step 1: failing test `WEB/src/components/admin/parts/AnnouncementPublishBar.test.tsx`
```tsx
import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import AnnouncementPublishBar from "./AnnouncementPublishBar";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockPublish = jest.fn();
const mockEnd = jest.fn();
const mockAudience = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  usePublishAnnouncementMutation: () => mockPublish(),
  useEndAnnouncementMutation: () => mockEnd(),
  useLazyGetAnnouncementAudienceQuery: () => mockAudience(),
}));

let publishTrigger: jest.Mock;
let endTrigger: jest.Mock;
let audienceTrigger: jest.Mock;
let prepare: jest.Mock;
let onDone: jest.Mock;
const resolved = (value: any) => jest.fn(() => ({ unwrap: () => Promise.resolve(value) }));

const renderBar = (props: any = {}) =>
  render(
    <AnnouncementPublishBar
      announcementId="a1"
      status="draft"
      notify={true}
      startsAtIso="2030-01-02T10:00:00.000Z"
      prepare={prepare}
      onDone={onDone}
      {...props}
    />
  );

beforeEach(() => {
  publishTrigger = resolved({ status: "live" });
  endTrigger = resolved({ status: "ended" });
  audienceTrigger = resolved({ count: 120, listed: 300 });
  prepare = jest.fn(() => Promise.resolve("a1"));
  onDone = jest.fn();
  mockPublish.mockReset().mockReturnValue([publishTrigger, { isLoading: false }]);
  mockEnd.mockReset().mockReturnValue([endTrigger, { isLoading: false }]);
  mockAudience.mockReset().mockReturnValue([audienceTrigger, { isFetching: false }]);
});

it("publish now with notify: saves, counts the audience, confirms, then publishes", async () => {
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  expect(prepare).toHaveBeenCalledWith("publish");
  expect(audienceTrigger).toHaveBeenCalledWith("a1");
  expect(screen.getByText(/120/)).toHaveTextContent("Sends a push notification to 120 people now and adds it to 300 notification lists.");
  expect(publishTrigger).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() => expect(publishTrigger).toHaveBeenCalledWith({ id: "a1", at: undefined }));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Published."));
});

it("publish without notify skips the dialog", async () => {
  renderBar({ notify: false });
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(publishTrigger).toHaveBeenCalledWith({ id: "a1", at: undefined }));
  expect(audienceTrigger).not.toHaveBeenCalled();
});

it("schedule passes the start time and says when", async () => {
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Schedule" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  expect(prepare).toHaveBeenCalledWith("schedule");
  expect(screen.getByText(/at the scheduled start/)).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() => expect(publishTrigger).toHaveBeenCalledWith({ id: "a1", at: "2030-01-02T10:00:00.000Z" }));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Scheduled."));
});

it("nothing is sent when the save step fails validation", async () => {
  prepare = jest.fn(() => Promise.resolve(null));
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(prepare).toHaveBeenCalled());
  expect(audienceTrigger).not.toHaveBeenCalled();
  expect(publishTrigger).not.toHaveBeenCalled();
});

it("an audience-count failure is shown and nothing is published", async () => {
  audienceTrigger = jest.fn(() => ({ unwrap: () => Promise.reject({ data: { message: "count failed" } }) }));
  mockAudience.mockReturnValue([audienceTrigger, { isFetching: false }]);
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  expect(await screen.findByRole("alert")).toHaveTextContent("count failed");
  expect(publishTrigger).not.toHaveBeenCalled();
});

it("a publish failure stays in the dialog", async () => {
  publishTrigger = jest.fn(() => ({ unwrap: () => Promise.reject({ data: { message: "endsAt must be after startsAt" } }) }));
  mockPublish.mockReturnValue([publishTrigger, { isLoading: false }]);
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(await screen.findByTestId("confirm-dialog-error")).toHaveTextContent("endsAt must be after startsAt");
  expect(onDone).not.toHaveBeenCalled();
});

it("live: only End now, behind a confirm", async () => {
  renderBar({ status: "live" });
  expect(screen.queryByRole("button", { name: "Publish now" })).toBeNull();
  fireEvent.click(screen.getByRole("button", { name: "End now" }));
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() => expect(endTrigger).toHaveBeenCalledWith("a1"));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Ended."));
});

it("ended: no actions", () => {
  renderBar({ status: "ended" });
  expect(screen.queryAllByRole("button")).toHaveLength(0);
});
```
- [ ] Step 2: run → fails `Cannot find module './AnnouncementPublishBar'`
  `cd WEB && CI=true npx react-scripts test --watchAll=false src/components/admin/parts/AnnouncementPublishBar.test.tsx`
- [ ] Step 3: implement
  - create `WEB/src/components/admin/parts/AnnouncementPublishBar.tsx`:
```tsx
import React from "react";
import { useTranslation } from "react-i18next";
import {
  usePublishAnnouncementMutation,
  useEndAnnouncementMutation,
  useLazyGetAnnouncementAudienceQuery,
  AnnouncementStatus,
} from "../../../store/slices/adminSlice";
import ConfirmDialog from "./ConfirmDialog";

export interface AnnouncementPublishBarProps {
  /** null until the first save of a new announcement. */
  announcementId: string | null;
  status: AnnouncementStatus;
  /** The form's "Send notification" switch. */
  notify: boolean;
  /** The form's start time as ISO, sent as `at` when scheduling. */
  startsAtIso: string | null;
  /** Validate and save the form; resolves to the saved id, or null if it did not save. */
  prepare: (mode: "publish" | "schedule") => Promise<string | null>;
  onDone: (message: string) => void;
}

type Pending =
  | { kind: "publish"; mode: "publish" | "schedule"; id: string; count: number; listed: number }
  | { kind: "end"; id: string }
  | null;

const errorMessage = (err: any, fallback: string): string =>
  (err && err.data && err.data.message) || (err && err.message) || fallback;

/**
 * The three actions that reach users. Publishing with "Send notification" on
 * pushes to everyone in the audience, so it always asks first and shows how
 * many people that is — fetched fresh from the server, after the save, so the
 * number matches the targeting that will actually be used.
 */
const AnnouncementPublishBar: React.FC<AnnouncementPublishBarProps> = ({
  announcementId, status, notify, startsAtIso, prepare, onDone,
}) => {
  const { t } = useTranslation();
  const [publish, publishState] = usePublishAnnouncementMutation();
  const [end, endState] = useEndAnnouncementMutation();
  const [fetchAudience] = useLazyGetAnnouncementAudienceQuery();
  const [pending, setPending] = React.useState<Pending>(null);
  const [working, setWorking] = React.useState(false);
  const [error, setError] = React.useState("");
  const [dialogError, setDialogError] = React.useState("");

  const canPublish = status === "draft" || status === "scheduled";
  const canEnd = status === "scheduled" || status === "live";
  const fallback = t("admin.common.actionError") || "Something went wrong.";

  const doneMessage = (mode: "publish" | "schedule") =>
    mode === "schedule"
      ? t("admin.announcements.scheduledDone") || "Scheduled."
      : t("admin.announcements.publishedDone") || "Published.";
  const atFor = (mode: "publish" | "schedule") => (mode === "schedule" ? startsAtIso || undefined : undefined);

  const start = async (mode: "publish" | "schedule") => {
    setError("");
    setWorking(true);
    try {
      const id = await prepare(mode);
      if (!id) return;
      if (!notify) {
        // No push: nothing irreversible reaches anyone's phone, so no dialog.
        try {
          await publish({ id, at: atFor(mode) }).unwrap();
          onDone(doneMessage(mode));
        } catch (err) {
          setError(errorMessage(err, fallback));
        }
        return;
      }
      try {
        const audience: { count: number; listed: number } = await fetchAudience(id).unwrap();
        setDialogError("");
        setPending({ kind: "publish", mode, id, count: audience.count, listed: audience.listed });
      } catch (err) {
        setError(errorMessage(err, t("admin.announcements.audienceError") || "Couldn't count the audience."));
      }
    } finally {
      setWorking(false);
    }
  };

  const confirm = async () => {
    if (!pending) return;
    if (pending.kind === "publish") {
      try {
        await publish({ id: pending.id, at: atFor(pending.mode) }).unwrap();
        const mode = pending.mode;
        setPending(null);
        onDone(doneMessage(mode));
      } catch (err) {
        setDialogError(errorMessage(err, fallback));
      }
      return;
    }
    try {
      await end(pending.id).unwrap();
      setPending(null);
      onDone(t("admin.announcements.endedDone") || "Ended.");
    } catch (err) {
      setDialogError(errorMessage(err, fallback));
    }
  };

  const busy = working || publishState.isLoading || endState.isLoading;
  const buttonClass =
    "rounded-chip px-3 py-1.5 text-sm font-medium disabled:opacity-60";

  const dialogBody = () => {
    if (!pending) return null;
    if (pending.kind === "end") {
      return t("admin.announcements.endBody") || "It disappears from the app now. Notifications already sent stay in people's lists.";
    }
    const when = pending.mode === "schedule"
      ? t("admin.announcements.atStart") || "at the scheduled start"
      : t("admin.announcements.now") || "now";
    return `Sends a push notification to ${pending.count.toLocaleString("en-US")} people ${when} and adds it to ${pending.listed.toLocaleString("en-US")} notification lists.`;
  };

  if (!canPublish && !canEnd) return null;

  return (
    <div className="flex flex-wrap items-center gap-2" data-testid="publish-bar">
      {canPublish ? (
        <>
          <button type="button" disabled={busy} onClick={() => start("schedule")}
            className={`${buttonClass} border border-line text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200`}>
            {t("admin.announcements.schedule") || "Schedule"}
          </button>
          <button type="button" disabled={busy} onClick={() => start("publish")}
            className={`${buttonClass} bg-brand-deep text-white hover:opacity-90`}>
            {t("admin.announcements.publishNow") || "Publish now"}
          </button>
        </>
      ) : null}
      {canEnd && announcementId ? (
        <button type="button" disabled={busy} onClick={() => { setDialogError(""); setPending({ kind: "end", id: announcementId }); }}
          className={`${buttonClass} border border-red-300 text-red-700 hover:bg-red-50`}>
          {t("admin.announcements.endNow") || "End now"}
        </button>
      ) : null}
      {error ? <p role="alert" className="w-full text-sm text-red-600">{error}</p> : null}

      <ConfirmDialog
        open={!!pending}
        title={
          pending && pending.kind === "end"
            ? t("admin.announcements.endTitle") || "End this announcement?"
            : pending && pending.mode === "schedule"
              ? t("admin.announcements.scheduleTitle") || "Schedule this announcement?"
              : t("admin.announcements.publishTitle") || "Publish this announcement?"
        }
        body={dialogBody()}
        confirmLabel={
          pending && pending.kind === "end"
            ? t("admin.announcements.endNow") || "End now"
            : pending && pending.mode === "schedule"
              ? t("admin.announcements.schedule") || "Schedule"
              : t("admin.announcements.publishNow") || "Publish now"
        }
        cancelLabel={t("admin.common.cancel") || "Cancel"}
        danger={!!pending && pending.kind === "end"}
        busy={publishState.isLoading || endState.isLoading}
        error={dialogError || undefined}
        onConfirm={() => { confirm(); }}
        onCancel={() => setPending(null)}
      />
    </div>
  );
};

export default AnnouncementPublishBar;
```
  - `AdminAnnouncementEditor.tsx`:
    - import: `import AnnouncementPublishBar from "../parts/AnnouncementPublishBar";` and add `fromLocalInput` to the `../parts/announcementForm` import list.
    - replace the whole `{!readOnly ? ( <div … data-testid="editor-actions"> … </div> ) : null}` block with (the bar renders nothing for an ended announcement):
```tsx
          <div className="flex flex-wrap items-center gap-2" data-testid="editor-actions">
            {!readOnly ? (
              <button type="button" disabled={busy} onClick={onSave}
                className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:opacity-60 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800">
                {status === "draft" ? t("admin.announcements.saveDraft") || "Save draft" : t("admin.announcements.save") || "Save"}
              </button>
            ) : null}
            <AnnouncementPublishBar
              announcementId={id}
              status={status}
              notify={form.notify}
              startsAtIso={fromLocalInput(form.startsAt)}
              prepare={async (mode) => {
                const saved = await save({ schedule: mode === "schedule" });
                return saved ? saved.id : null;
              }}
              onDone={(message) => setNotice(message)}
            />
          </div>
```
  - `AdminAnnouncementEditor.test.tsx`: under the existing `jest.mock("../../../store/slices/adminSlice", …)` add
```tsx
jest.mock("../parts/AnnouncementPublishBar", () => ({
  __esModule: true,
  default: (props: any) => (
    <button type="button" data-testid="publish-bar" onClick={() => props.prepare("schedule")}>
      {props.status}
    </button>
  ),
}));
```
    and append:
```tsx
it("the publish bar gets the status and Schedule validates a future start before saving", () => {
  renderAt("/admin/announcements/new");
  expect(screen.getByTestId("publish-bar")).toHaveTextContent("draft");
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Hello" } });
  fireEvent.change(screen.getByLabelText("Body"), { target: { value: "World" } });
  fireEvent.click(screen.getByTestId("publish-bar"));
  expect(screen.getByTestId("error-startsAt")).toHaveTextContent("Pick a start time to schedule.");
  expect(createTrigger).not.toHaveBeenCalled();
});
```
- [ ] Step 4: run both test files → 8 + 10 passing; `npx eslint src/components/admin src/store/slices/adminSlice.ts` → exit 0; `CI=true npx react-scripts test --watchAll=false src/components/admin src/store/slices` → all passing.
- [ ] Step 5: commit
```
git add src/components/admin/parts/AnnouncementPublishBar.tsx src/components/admin/parts/AnnouncementPublishBar.test.tsx src/components/admin/pages/AdminAnnouncementEditor.tsx src/components/admin/pages/AdminAnnouncementEditor.test.tsx docs/REMAINING_WORK.md
git commit -m "feat(admin): schedule, publish now and end now with an audience confirm

Publishing with 'Send notification' on saves, asks the server for the push
and list audience, and confirms with both numbers before anything is sent;
End now confirms too. Errors stay in the dialog; nothing is retried.

REMAINING_WORK: ticked W5; added 'Owner: first real announcement end-to-end
(publish -> push -> notifications list -> in-app pop-up), docs/qa/onboarding-matrix.md'.
Still open: app A* (list parsing, AnnouncementScreen, settings toggle).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Contradictions found in the code, and how this part resolves them

1. **Contract `Notification { user, … }` / index `{ user:1, … }`** — the model's field is `userId` (models/Notification.js). Resolved: rows and the unique partial index use `userId`; every other contract name is kept.
2. **Spec "permanent notifications-list entry"** — Notification has a 30-day TTL default and `cleanupOldNotifications` deletes everything older than 30 days. Resolved (B2): announcement rows set `expiresAt: null` and the cleanup skips `type: 'announcement'`.
3. **fcmService quiet-hours audit row** — `sendToUser` writes its own Notification during quiet hours with the original type; for `announcement` that would collide with the unique index. Resolved: `announcement` is left out of `fcmService.NOTIFICATION_TYPE_ENUM` (falls back to `system`) and delivery checks quiet hours before calling fcmService.
4. **Contract `audience-count -> { count }`** — the editor also needs the list audience (65% hold no token). Resolved: `{ count, listed }`; `count` keeps the contract meaning (push audience).
5. **Env-var fallback vs new list** — new builds read only `announcements`, so an empty DB list would hide an active env announcement. Resolved (B4): when the DB list is empty, the env announcement is appended to the list too.
6. **Spec `pm2 describe` / `pm2 logs --err`** — `describe` prints secret env values into the Actions log, and crashes are logged to stdout, so `--err` alone misses them. Resolved: the workflow uses filtered `pm2 jlist` + pm2.log + both app logs (O1a), and crash logging moves to stderr (O1c).
7. **Spec "a minute job flips…" + delivery resume** — the spec field list has no resume bookkeeping. Resolved: additive `delivery.heartbeatAt/cursor/error`.
8. **Web `docs/REMAINING_WORK.md`** — did not exist. Resolved: created in W1.
9. **App `print(null)`** — grep finds none in `lib/`. Resolved: debug-only trap names the caller on the next occurrence (O2).
10. **`Notification` declares `expiresAt` twice** (`index: true` on the path and the TTL index), so `Model.init()`/autoIndex fails with "equivalent index already exists with different options" and builds nothing after it — verified on an in-memory Mongo. Resolved (B2): the announcement unique index is created explicitly by `Notification.ensureAnnouncementIndex()`, called by delivery before its first insert; the duplicate declaration itself is ticketed in REMAINING_WORK, not changed here.

Verification done while writing (2026-10-12, scratch copies, nothing in the repos touched): every backend test in this part passes against the real backend code with the plan's edits applied (O1a 4, O1c 4, B1 9, B2 4, B3 7, B4 5, B5 6, B6 7, B7 6, B8 3, B9 4, B10 2, B11 6), plus existing `notificationTypeEnum`, `conversationCapKillSwitch`, `authAudit.sessionRevocation`, `cookieAuthIntegration`, `broadcastNotification`, `adminContent`, `shouldSendNotification.gates`, `dailyDropDelivery`; `server.js` passes `node --check`. Web: all 37 suites / 384 tests in `src/components/admin` + `src/store/slices` pass with W1–W5 applied, eslint clean. App: O2's 5 tests pass.

# Part 2 — App: activation, guides, launch pop-ups, announcements

Spec: `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md` §3, §4, §5.2. Names: `parts/00-contract.md`.
Run everything from `APP=/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`
(the git root is its parent; `git add` with these relative paths works from `APP`). Tests: `flutter test <file>`.
Imports are `package:` only. A1 adds the §0d checklist to `docs/REMAINING_WORK.md`; every later task flips its
own `- [ ] A<n>` line to `- [x]` in the same commit.

Commit template used in every Step 5 (substitute paths, subject, body, `<next>`):

```bash
git add <paths> docs/REMAINING_WORK.md && git commit -m "$(cat <<'EOF'
<subject>

<body>

Remaining (docs/REMAINING_WORK.md §0d): <next>–A16 open; device QA in docs/qa/onboarding-matrix.md and native review of machine-drafted strings as before.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task A1: Analytics events for activation, guide retirement and priming

**Files:** Modify `lib/services/analytics_service.dart`, `docs/REMAINING_WORK.md` · Test (create) `test/services/onboarding_analytics_test.dart`
**Interfaces:** Produces `logActivationMilestone(String action, int count)`, `logGuideRetired(String surface, String reason)`, `logNotificationPrimeShown(String trigger)`, `logNotificationPrimeResult(String result)`; plus test seam `static AnalyticsService.debugLogSink`.

- [ ] Step 1: failing test `test/services/onboarding_analytics_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/analytics_service.dart';

void main() {
  final events = <(String, Map<String, Object>)>[];
  setUp(() {
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  test('the four onboarding events use the spec names and params', () async {
    final a = AnalyticsService.instance;
    await a.logActivationMilestone('lesson', 2);
    await a.logGuideRetired('moments', 'milestones');
    await a.logNotificationPrimeShown('first_matches');
    await a.logNotificationPrimeResult('later');

    expect(events.map((e) => e.$1), [
      'activation_milestone',
      'guide_retired',
      'notification_prime_shown',
      'notification_prime_result',
    ]);
    expect(events[0].$2, {'action': 'lesson', 'count': 2});
    expect(events[1].$2, {'surface': 'moments', 'reason': 'milestones'});
    expect(events[2].$2, {'trigger': 'first_matches'});
    expect(events[3].$2, {'result': 'later'});
  });
}
```

- [ ] Step 2: `flutter test test/services/onboarding_analytics_test.dart` → compile error: `debugLogSink` / `logActivationMilestone` not defined.
- [ ] Step 3: implement in `lib/services/analytics_service.dart`.
  - Below `static final AnalyticsService instance = AnalyticsService._();` add:

```dart
  /// Test seam: receives every event that passes through [_log], after nulls
  /// are dropped. Null in production.
  @visibleForTesting
  static void Function(String name, Map<String, Object> params)? debugLogSink;
```

  - In `_log`, directly after the `params.forEach(...)` block add `debugLogSink?.call(name, clean);`
  - Above `// ─── Step 13A events ───` add:

```dart
  // ─── Activation, guides, priming (spec 2026-10-12) ───────────
  //
  // activation_milestone fires once per action, when it is first recorded;
  // count is how many of the four are done after it. guide_retired fires
  // once per surface, the first time a guide that was shown stops showing.

  Future<void> logActivationMilestone(String action, int count) =>
      _log('activation_milestone', {'action': action, 'count': count});

  /// [reason] is 'acted' | 'milestones' | 'window'.
  Future<void> logGuideRetired(String surface, String reason) =>
      _log('guide_retired', {'surface': surface, 'reason': reason});

  Future<void> logNotificationPrimeShown(String trigger) =>
      _log('notification_prime_shown', {'trigger': trigger});

  /// [result] is 'granted' | 'declined' | 'later'.
  Future<void> logNotificationPrimeResult(String result) =>
      _log('notification_prime_result', {'result': result});
```

  - `docs/REMAINING_WORK.md`: insert immediately above `## 0c. First-session guidance (2026-10-09)`:

```markdown
## 0d. Activation, launch pop-ups, announcements — app (2026-10-12) — spec `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md` §3 §4 §5.2

- [x] A1 analytics: `activation_milestone`, `guide_retired`, `notification_prime_shown`, `notification_prime_result`
- [ ] A2 `ActivationStore` (4 actions, back-fill, fail closed, user-scoped)
- [ ] A3 hooks: message, moment (direct + upload queue), lesson / quiz / vocab review, profile complete
- [ ] A4 guide rule: 7 days, stop at 3 of 4, `isGuidePeriod`, `GuideSurface.chatTip`, `guide_retired` latch
- [ ] A5 strings: 6 keys × 19 locales + native-QA rows
- [ ] A6 guide UI: "Getting started · N of 4", retire on real action, CTA no longer retires, Matches on the same rule
- [ ] A7 chat tip under the first received text message
- [ ] A8 `PopupBudget` + `LaunchModalCoordinator`
- [ ] A9 priming: budget, triggers (first matches / first wave / first message sent / received), events; chat-open trigger removed
- [ ] A10 AI Study promo folded into the spotlight rotation; `AiStudyPromoModal` deleted
- [ ] A11 `Announcement` model, `appConfig.announcements`, `lang` on app-config, seen set
- [ ] A12 launch wiring: announcement / ads notice / spotlight candidates; version check reports the update dialog
- [ ] A13 `AnnouncementScreen` at `/announcement/:id`
- [ ] A14 notifications list `announcement` type + push routing
- [ ] A15 Settings → Notifications "Announcements" toggle
- [ ] A16 suspension screen reads `banReason`
- [ ] Device QA rows in `docs/qa/onboarding-matrix.md` (owner, after a release build)
```

- [ ] Step 4: `flutter test test/services/onboarding_analytics_test.dart` → All tests passed.
- [ ] Step 5: commit `lib/services/analytics_service.dart test/services/onboarding_analytics_test.dart`; subject `feat(analytics): activation, guide-retired and priming events`; body "Four typed events for spec §3/§4 and a debugLogSink test seam."; `<next>` = A2.

---

### Task A2: `ActivationStore`

**Files:** Create `lib/services/activation_store.dart`, `test/helpers/community_fixture.dart`, `test/activation/activation_store_test.dart` · Modify `lib/services/session_reset.dart`
**Interfaces:** Consumes `logActivationMilestone`, `kPrefHasMessaged`. Produces `ActivationAction`, `ActivationStore{markDone,isDone,doneCount}`, `activationStoreProvider`, `checkProfileComplete(Community user, {ActivationStore? store})`; additive: `ActivationStore.doneSet()`, `ActivationStore.changes`, `isProfileComplete`, `activationDoneProvider` (StreamProvider — guides need a live source, see Contradictions).

- [ ] Step 1: failing tests.

`test/helpers/community_fixture.dart`:

```dart
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

Community communityFixture({
  int daysOld = 1,
  String bio = '',
  List<String> imageUrls = const [],
}) =>
    Community(
      id: 'me',
      appleId: '',
      googleId: '',
      name: 'Me',
      email: '',
      mbti: '',
      bloodType: '',
      bio: bio,
      images: const [],
      birth_day: '',
      birth_month: '',
      gender: '',
      birth_year: '',
      native_language: 'English',
      language_to_learn: 'Korean',
      imageUrls: imageUrls,
      createdAt:
          DateTime.now().subtract(Duration(days: daysOld)).toIso8601String(),
      version: 0,
      followers: const [],
      followings: const [],
      location: Location.defaultLocation(),
    );
```

`test/activation/activation_store_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/session_prefs.dart';

import '../helpers/community_fixture.dart';

class _NoBiometric implements BiometricTokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> save(String token) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final events = <(String, Map<String, Object>)>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  List<Map<String, Object>> milestones() => [
        for (final e in events)
          if (e.$1 == 'activation_milestone') e.$2,
      ];

  test('markDone is idempotent and only a new set reports', () async {
    final s = ActivationStore();
    expect(await s.markDone(ActivationAction.moment), isTrue);
    expect(await s.markDone(ActivationAction.moment), isFalse);
    expect(await s.isDone(ActivationAction.moment), isTrue);
    expect(await s.doneCount(), 1);
    expect(milestones(), [
      {'action': 'moment', 'count': 1},
    ]);
  });

  test('count is the number done after this one', () async {
    final s = ActivationStore();
    await s.markDone(ActivationAction.lesson);
    await s.markDone(ActivationAction.profile);
    expect(milestones().last, {'action': 'profile', 'count': 2});
  });

  test('two concurrent marks report once', () async {
    final s = ActivationStore();
    final r = await Future.wait([
      s.markDone(ActivationAction.lesson),
      s.markDone(ActivationAction.lesson),
    ]);
    expect(r.where((x) => x), hasLength(1));
    expect(milestones(), hasLength(1));
  });

  test('an existing install that already messaged is back-filled silently',
      () async {
    SharedPreferences.setMockInitialValues({'first_conversation_done': true});
    final s = ActivationStore();
    expect(await s.isDone(ActivationAction.message), isTrue);
    expect(await s.doneCount(), 1);
    expect(milestones(), isEmpty);
  });

  test('a wrong-typed pref reads as not done instead of throwing', () async {
    SharedPreferences.setMockInitialValues({'activation_done_lesson': 'yes'});
    expect(await ActivationStore().isDone(ActivationAction.lesson), isFalse);
  });

  test('slugs and pref keys are append-only', () {
    expect(ActivationAction.values.map((a) => a.slug),
        ['message', 'moment', 'lesson', 'profile']);
    expect(ActivationAction.lesson.prefKey, 'activation_done_lesson');
  });

  test('profile counts only with a photo AND a bio', () async {
    await checkProfileComplete(
        communityFixture(imageUrls: const ['https://x/a.jpg'], bio: '  '));
    expect(await ActivationStore().isDone(ActivationAction.profile), isFalse);
    await checkProfileComplete(
        communityFixture(imageUrls: const ['https://x/a.jpg'], bio: 'Hi'));
    expect(await ActivationStore().isDone(ActivationAction.profile), isTrue);
  });

  test('logout clears activation state (user-scoped prefs)', () async {
    await ActivationStore().markDone(ActivationAction.moment);
    final prefs = await SharedPreferences.getInstance();
    await clearUserSessionPrefs(prefs: prefs, biometricStorage: _NoBiometric());
    expect(await ActivationStore().doneCount(), 0);
  });

  test('activationDoneProvider re-emits after markDone', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sub = c.listen(activationDoneProvider, (_, __) {});
    addTearDown(sub.close);
    expect(await c.read(activationDoneProvider.future), isEmpty);
    await ActivationStore().markDone(ActivationAction.lesson);
    await pumpEventQueue();
    expect(c.read(activationDoneProvider).valueOrNull,
        {ActivationAction.lesson});
  });
}
```

- [ ] Step 2: `flutter test test/activation/activation_store_test.dart` → compile error: `activation_store.dart` missing.
- [ ] Step 3: implement. `lib/services/activation_store.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// The four first-week actions that count as a real start (spec §3.1).
/// Recorded when they HAPPEN — a send that succeeded, a moment the server
/// created — never on a button tap.
enum ActivationAction {
  message('message'),
  moment('moment'),
  lesson('lesson'),
  profile('profile');

  const ActivationAction(this.slug);

  /// Reported to analytics and part of the pref key. Append-only.
  final String slug;

  String get prefKey => 'activation_done_$slug';
}

/// Local record of which [ActivationAction]s this user has done.
///
/// User-scoped: the keys are not device-level, so `clearUserSessionPrefs`
/// removes them on logout / account switch. Reads fail closed (an unreadable
/// store reports everything done, i.e. show no guide), like `GuideStore`.
class ActivationStore {
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  /// Fires after an action is newly recorded.
  static Stream<void> get changes => _changes.stream;

  /// Records [action]. Returns whether it was newly set; a new set logs
  /// `activation_milestone`. Never throws.
  Future<bool> markDone(ActivationAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backfill(prefs);
      if (_read(prefs, action.prefKey)) return false;
      // setBool updates the in-memory cache synchronously, so a concurrent
      // markDone resuming after this line already sees it done.
      final write = prefs.setBool(action.prefKey, true);
      AnalyticsService.instance
          .logActivationMilestone(action.slug, _count(prefs));
      _changes.add(null);
      await write;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDone(ActivationAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backfill(prefs);
      return _read(prefs, action.prefKey);
    } catch (_) {
      return true;
    }
  }

  Future<int> doneCount() async => (await doneSet()).length;

  Future<Set<ActivationAction>> doneSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backfill(prefs);
      return {
        for (final a in ActivationAction.values)
          if (_read(prefs, a.prefKey)) a,
      };
    } catch (_) {
      return ActivationAction.values.toSet();
    }
  }

  static int _count(SharedPreferences prefs) =>
      ActivationAction.values.where((a) => _read(prefs, a.prefKey)).length;

  static bool _read(SharedPreferences prefs, String key) {
    try {
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Someone who messaged before this store existed has already done it.
  /// Silent: a back-fill is not a milestone reached today.
  static void _backfill(SharedPreferences prefs) {
    final key = ActivationAction.message.prefKey;
    if (!_read(prefs, key) && _read(prefs, kPrefHasMessaged)) {
      prefs.setBool(key, true).ignore();
    }
  }
}

/// The completeness rule the Profile guide has always used: a photo AND a
/// line of bio (OAuth signups arrive with a photo already).
bool isProfileComplete(Community user) =>
    user.effectiveImageUrls.isNotEmpty && user.bio.trim().isNotEmpty;

Future<void> checkProfileComplete(Community user, {ActivationStore? store}) async {
  if (!isProfileComplete(user)) return;
  await (store ?? ActivationStore()).markDone(ActivationAction.profile);
}

final activationStoreProvider =
    Provider<ActivationStore>((ref) => ActivationStore());

/// Live set of done actions: re-emits whenever [ActivationStore.markDone]
/// records something, so a guide retires on the action rather than on the
/// next app run.
final activationDoneProvider =
    StreamProvider<Set<ActivationAction>>((ref) {
  final store = ref.watch(activationStoreProvider);
  final out = StreamController<Set<ActivationAction>>();
  void emit() => store.doneSet().then((s) {
        if (!out.isClosed) out.add(s);
      });
  final sub = ActivationStore.changes.listen((_) => emit());
  emit();
  ref.onDispose(() {
    sub.cancel();
    out.close();
  });
  return out.stream;
});
```

  `lib/services/session_reset.dart`: add `import 'package:bananatalk_app/services/activation_store.dart';` next to the `guide_store.dart` import; after `'guideRecordedProvider': guideRecordedProvider,` add:

```dart
  // Activation milestones (spec 2026-10-12 §3.1). The prefs are removed by
  // clearUserSessionPrefs (not device-level); these drop the cached reads.
  'activationStoreProvider': activationStoreProvider,
  'activationDoneProvider': activationDoneProvider,
```

- [ ] Step 4: `flutter test test/activation/activation_store_test.dart test/services/session_reset_test.dart` → All tests passed.
- [ ] Step 5: commit `lib/services/activation_store.dart lib/services/session_reset.dart test/helpers/community_fixture.dart test/activation/activation_store_test.dart`; subject `feat(activation): ActivationStore for the four first-week actions`; tick A2; `<next>` = A3.

---

### Task A3: Activation hooks

**Files:** Modify `lib/pages/community/first_session/first_message_reporter.dart`, `lib/pages/moments/create/create_moment.dart`, `lib/services/upload_queue_service.dart`, `lib/providers/provider_root/learning/lessons_providers.dart`, `.../learning/quizzes_providers.dart`, `.../learning/vocabulary_providers.dart`, `lib/pages/profile/profile_main.dart` · Test (create) `test/activation/activation_hooks_test.dart`
**Interfaces:** Consumes `ActivationStore.markDone`, `activationStoreProvider`, `checkProfileComplete`.

- [ ] Step 1: failing test

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/community/first_session/first_message_reporter.dart';
import 'package:bananatalk_app/services/activation_store.dart';

/// Source-level for the same reason as first_message_paths_test: the
/// failure is a hook bolted to a path users do not take.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the first successful send records the message milestone', () async {
    SharedPreferences.setMockInitialValues({});
    await reportFirstMessageIfFirst();
    expect(await ActivationStore().isDone(ActivationAction.message), isTrue);
  });

  const hooks = <String, (String, int)>{
    'lib/pages/moments/create/create_moment.dart': ('ActivationAction.moment', 1),
    'lib/services/upload_queue_service.dart': ('ActivationAction.moment', 2),
    'lib/providers/provider_root/learning/lessons_providers.dart':
        ('ActivationAction.lesson', 1),
    'lib/providers/provider_root/learning/quizzes_providers.dart':
        ('ActivationAction.lesson', 1),
    'lib/providers/provider_root/learning/vocabulary_providers.dart':
        ('ActivationAction.lesson', 1),
    'lib/pages/profile/profile_main.dart': ('checkProfileComplete(', 1),
  };
  for (final e in hooks.entries) {
    test('${e.key} records ${e.value.$1} on success (${e.value.$2}x)', () {
      final src = File(e.key).readAsStringSync();
      expect(e.value.$1.allMatches(src).length, e.value.$2);
    });
  }
}
```

- [ ] Step 2: `flutter test test/activation/activation_hooks_test.dart` → failures (counts 0, message not done).
- [ ] Step 3: implement.
  - `first_message_reporter.dart`: add `import 'package:bananatalk_app/services/activation_store.dart';`; after `await FirstSessionStore.markMessaged();` add `await ActivationStore().markDone(ActivationAction.message);`
  - `create_moment.dart` (create branch of `_createMoment`, edit mode untouched): add `import 'package:bananatalk_app/services/activation_store.dart';`; replace

```dart
              isReel: widget.isReel,
            );

        // Upload images if any
```
  with
```dart
              isReel: widget.isReel,
            );
        // The server created it: that is the milestone, uploads or not.
        ref.read(activationStoreProvider).markDone(ActivationAction.moment).ignore();

        // Upload images if any
```
  - `upload_queue_service.dart` (both `_uploadMoment` and `_uploadMomentWithVideo`; this is where `_createMomentWithBackgroundUpload`'s moment is really created): add the import; Edit with `replace_all: true`, old `      isReel: metadata['isReel'] == true,\n    );\n    _checkSession(gen);` → new `      isReel: metadata['isReel'] == true,\n    );\n    _checkSession(gen);\n    ActivationStore().markDone(ActivationAction.moment).ignore();`
  - `lessons_providers.dart`: add the import; in `_completeLesson` replace

```dart
    state = state.copyWith(
      isComplete: true,
      xpEarned: xpEarned,
    );
```
  with
```dart
    if (result['success'] == true) {
      ActivationStore().markDone(ActivationAction.lesson).ignore();
    }

    state = state.copyWith(
      isComplete: true,
      xpEarned: xpEarned,
    );
```
  - `quizzes_providers.dart`: add the import; in `submitQuiz` replace `    if (result['success'] == true && result['data'] != null) {\n      final data = result['data'];` with the same two lines followed by `      ActivationStore().markDone(ActivationAction.lesson).ignore();`
  - `vocabulary_providers.dart`: add the import; in `VocabularyReviewNotifier.submitAnswer` replace `      xpEarned: (state.xpEarned ?? 0) + xpEarned,\n    );\n  }` with `      xpEarned: (state.xpEarned ?? 0) + xpEarned,\n    );\n    if (isComplete && result['success'] == true) {\n      ActivationStore().markDone(ActivationAction.lesson).ignore();\n    }\n  }`
  - `profile_main.dart`: add `import 'package:bananatalk_app/services/activation_store.dart';`; in `initState` replace `    Future.microtask(() => ref.invalidate(userProvider));\n    _loadOwnStories();` with

```dart
    Future.microtask(() => ref.invalidate(userProvider));
    _loadOwnStories();
    // Profile complete is a milestone. TabsScreen builds this page eagerly
    // and every edit screen invalidates userProvider on save, so one
    // listener covers the first load and each save.
    ref.listenManual<AsyncValue<Community>>(userProvider, (_, next) {
      final u = next.valueOrNull;
      if (u != null) checkProfileComplete(u).ignore();
    }, fireImmediately: true);
```

- [ ] Step 4: `flutter test test/activation/activation_hooks_test.dart test/community/first_message_paths_test.dart` → All tests passed.
- [ ] Step 5: commit the 7 lib files + test; subject `feat(activation): record message, moment, lesson and profile when they really happen`; tick A3; `<next>` = A4.

---

### Task A4: Guide rule — 7 days, 3 of 4, guide period, chat-tip surface, retired latch

**Files:** Modify (full rewrite) `lib/services/guide_store.dart`; Modify `lib/pages/community/first_session/first_session_guidance.dart`, `lib/services/session_reset.dart`, `test/guides/guide_store_test.dart` · Test (create) `test/guides/guide_rule_test.dart`
**Interfaces:** Consumes `ActivationAction`, `ActivationStore`, `activationDoneProvider`, `activationStoreProvider`, `checkProfileComplete`, `logGuideRetired`, `userProvider`. Produces `GuideSurface.chatTip`, `kGuideWindowDays = 7`, `shouldShowGuide({withinWindow, acted, milestonesDone})`, `isGuidePeriod(Community?, ActivationStore)`, `isGuidePeriodProvider`; additive `kGuideMilestoneStop`, `GuideSurface.action`, `guideRetiredReason`, `GuideStore.recordRetired`.

- [ ] Step 1: failing test `test/guides/guide_rule_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';

import '../helpers/community_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final events = <(String, Map<String, Object>)>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  test('all guides stop at 3 of 4 actions', () {
    expect(shouldShowGuide(withinWindow: true, acted: false, milestonesDone: 2),
        isTrue);
    expect(shouldShowGuide(withinWindow: true, acted: false, milestonesDone: 3),
        isFalse);
  });

  test('the window is 7 days', () => expect(kGuideWindowDays, 7));

  test('each surface retires on its own real action', () {
    expect(GuideSurface.aiStudy.action, ActivationAction.lesson);
    expect(GuideSurface.moments.action, ActivationAction.moment);
    expect(GuideSurface.chats.action, ActivationAction.message);
    expect(GuideSurface.matches.action, ActivationAction.message);
    expect(GuideSurface.profile.action, ActivationAction.profile);
    expect(GuideSurface.chatTip.action, isNull);
    expect(GuideSurface.chatTip.slug, 'chat_tip');
    expect(GuideSurface.chatTip.actedKey, 'guide_acted_chat_tip');
  });

  test('guideRetiredReason', () {
    String? r({bool shown = true, bool win = true, bool acted = false, int n = 0}) =>
        guideRetiredReason(
            wasShown: shown, withinWindow: win, acted: acted, milestonesDone: n);
    expect(r(), isNull, reason: 'still showing');
    expect(r(shown: false, acted: true), isNull, reason: 'never shown');
    expect(r(acted: true, n: 3), 'acted');
    expect(r(n: 3), 'milestones');
    expect(r(win: false), 'window');
  });

  test('guide_retired is logged once per surface', () async {
    await GuideStore.recordRetired(GuideSurface.moments, 'acted');
    await GuideStore.recordRetired(GuideSurface.moments, 'acted');
    await GuideStore.recordRetired(GuideSurface.chats, 'window');
    final retired = [for (final e in events) if (e.$1 == 'guide_retired') e.$2];
    expect(retired, [
      {'surface': 'moments', 'reason': 'acted'},
      {'surface': 'chats', 'reason': 'window'},
    ]);
  });

  group('isGuidePeriod', () {
    test('no user, or past 7 days, is not the guide period', () async {
      final s = ActivationStore();
      expect(await isGuidePeriod(null, s), isFalse);
      expect(await isGuidePeriod(communityFixture(daysOld: 8), s), isFalse);
    });
    test('2 of 4 inside the window is; 3 of 4 is not', () async {
      final s = ActivationStore();
      await s.markDone(ActivationAction.lesson);
      await s.markDone(ActivationAction.moment);
      expect(await isGuidePeriod(communityFixture(), s), isTrue);
      await s.markDone(ActivationAction.message);
      expect(await isGuidePeriod(communityFixture(), s), isFalse);
    });
    test('the provider back-fills profile from the loaded user', () async {
      final c = ProviderContainer(overrides: [
        userProvider.overrideWith((ref) async => communityFixture(
            imageUrls: const ['https://x/a.jpg'], bio: 'Hi')),
      ]);
      addTearDown(c.dispose);
      expect(await c.read(isGuidePeriodProvider.future), isTrue);
      expect(await ActivationStore().isDone(ActivationAction.profile), isTrue);
    });
  });
}
```

- [ ] Step 2: `flutter test test/guides/guide_rule_test.dart` → compile errors (`milestonesDone`, `chatTip`, `isGuidePeriod` undefined).
- [ ] Step 3: implement. Rewrite `lib/services/guide_store.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// How long after signup guides keep appearing (spec §3.2: 7 days, which is
/// also `Community.isNewUser`). Guides stop earlier at [kGuideMilestoneStop].
const int kGuideWindowDays = 7;

/// All guides stop once this many of the four activation actions are done.
const int kGuideMilestoneStop = 3;

/// A surface that can carry a first-session guide.
enum GuideSurface {
  /// Matches predates this enum and keeps its original pref keys — renaming
  /// them would reset the state for everyone mid-rollout.
  matches(
    slug: 'matches',
    action: ActivationAction.message,
    shownKey: 'first_session_guidance_shown_count',
    actedKey: 'first_conversation_done',
  ),
  aiStudy(slug: 'ai_study', action: ActivationAction.lesson),
  chats(slug: 'chats', action: ActivationAction.message),
  moments(slug: 'moments', action: ActivationAction.moment),
  profile(slug: 'profile', action: ActivationAction.profile),

  /// The long-press hint under the first received message (spec §3.3). Not
  /// a tab: retired by the long-press itself or its ✕.
  chatTip(slug: 'chat_tip');

  const GuideSurface({
    required this.slug,
    this.action,
    String? shownKey,
    String? actedKey,
  })  : _shownKey = shownKey,
        _actedKey = actedKey;

  /// Stable analytics identifier. Append-only.
  final String slug;

  /// The real action that retires this surface's guide, if any.
  final ActivationAction? action;

  final String? _shownKey;
  final String? _actedKey;

  String get shownKey => _shownKey ?? 'guide_shown_count_$slug';
  String get actedKey => _actedKey ?? 'guide_acted_$slug';
  String get retiredKey => 'guide_retired_$slug';
}

@immutable
class GuideState {
  const GuideState({required this.acted, required this.timesShown});

  final bool acted;
  final int timesShown;

  /// Storage unreadable: someone who has already acted, i.e. show nothing.
  static const unknown = GuideState(acted: true, timesShown: 0);
}

/// Local persistence for page guides. Every read and write is wrapped; a
/// wrong-typed value from an older build reads as its default.
class GuideStore {
  static Future<GuideState> read(GuideSurface surface) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool acted = false;
      int shown = 0;
      try {
        acted = prefs.getBool(surface.actedKey) ?? false;
      } catch (_) {
        acted = false;
      }
      try {
        shown = prefs.getInt(surface.shownKey) ?? 0;
      } catch (_) {
        shown = 0;
      }
      return GuideState(acted: acted, timesShown: shown);
    } catch (_) {
      return GuideState.unknown;
    }
  }

  static Future<void> markActed(GuideSurface surface) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(surface.actedKey, true);
    } catch (_) {}
  }

  static Future<void> recordShown(GuideSurface surface) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await read(surface);
      await prefs.setInt(surface.shownKey, current.timesShown + 1);
    } catch (_) {}
  }

  /// Logs `guide_retired` the first time a shown guide stops showing, once
  /// per surface ever (pref latch). setBool updates the cache synchronously,
  /// so two builds in one frame log once.
  static Future<void> recordRetired(GuideSurface surface, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool done = false;
      try {
        done = prefs.getBool(surface.retiredKey) ?? false;
      } catch (_) {
        done = false;
      }
      if (done) return;
      final write = prefs.setBool(surface.retiredKey, true);
      AnalyticsService.instance.logGuideRetired(surface.slug, reason);
      await write;
    } catch (_) {}
  }
}

/// Whether a guide should be shown. Pure; every surface reads this.
bool shouldShowGuide({
  required bool withinWindow,
  required bool acted,
  required int milestonesDone,
}) =>
    withinWindow && !acted && milestonesDone < kGuideMilestoneStop;

/// Why a guide that was shown is now suppressed, or null when it still
/// shows or was never shown. Precedence: acted > milestones > window.
String? guideRetiredReason({
  required bool wasShown,
  required bool withinWindow,
  required bool acted,
  required int milestonesDone,
}) {
  if (!wasShown) return null;
  if (shouldShowGuide(
      withinWindow: withinWindow, acted: acted, milestonesDone: milestonesDone)) {
    return null;
  }
  if (acted) return 'acted';
  if (milestonesDone >= kGuideMilestoneStop) return 'milestones';
  return 'window';
}

/// The single "first week" predicate (spec §3.2), reused by the chat tip and
/// the launch coordinator.
Future<bool> isGuidePeriod(Community? user, ActivationStore store) async {
  if (user == null) return false;
  if (!user.joinedWithinDays(kGuideWindowDays)) return false;
  return await store.doneCount() < kGuideMilestoneStop;
}

/// Waits for the user (a still-loading user must not read as "not new"),
/// back-fills the profile milestone from it, and re-evaluates whenever an
/// action is recorded.
final isGuidePeriodProvider = FutureProvider<bool>((ref) async {
  ref.watch(activationDoneProvider);
  final store = ref.watch(activationStoreProvider);
  Community? user;
  try {
    user = await ref.watch(userProvider.future);
  } catch (_) {
    user = null;
  }
  if (user != null) await checkProfileComplete(user, store: store);
  return isGuidePeriod(user, store);
});

/// Read once per page mount. Deliberately NOT invalidated after
/// `recordShown`: refetching mid-view removed the Matches panel
/// milliseconds after it appeared.
final guideStateProvider =
    FutureProvider.family<GuideState, GuideSurface>((ref, surface) {
  return GuideStore.read(surface);
});

/// One-shot per-surface "shown" latches for this app run, held outside the
/// widget (tab pages are remounted far more often than a user visits them).
/// User-scoped in session_reset.dart.
final guideRecordedProvider =
    StateProvider.family<bool, GuideSurface>((ref, surface) => false);
```

  `first_session_guidance.dart`: replace the function with

```dart
bool shouldShowFirstSessionGuidance({
  required bool withinWindow,
  required bool hasMessaged,
  int milestonesDone = 0,
}) =>
    shouldShowGuide(
      withinWindow: withinWindow,
      acted: hasMessaged,
      milestonesDone: milestonesDone,
    );
```

  `session_reset.dart`: after `'activationDoneProvider': activationDoneProvider,` add `  'isGuidePeriodProvider': isGuidePeriodProvider,`

  `lib/widgets/guides/page_guide.dart` (bridge until A6 rewrites it): in its `shouldShowGuide(` call add `milestonesDone: 0,` after `acted: acted || state.acted,`.

  `test/guides/guide_store_test.dart`: in the four `shouldShowGuide(...)` calls of `group('shouldShowGuide')` and in the `unknown hides the guide` test add `milestonesDone: 0,`; replace `test('is three days, counted from signup', () { expect(kGuideWindowDays, 3); });` with `test('is seven days, counted from signup', () { expect(kGuideWindowDays, 7); });`; replace the whole `test('is shorter than the isNewUser cohort it sits inside', ...)` with

```dart
    test('matches the isNewUser cohort (spec 2026-10-12 §3.2)', () {
      // Was 3 < 7. Guides now stop on 3 of 4 actions instead, so the window
      // is only the outer bound and equals the new-user week.
      expect(joinedDaysAgo(kGuideWindowDays - 1).isNewUser, isTrue);
      expect(joinedDaysAgo(kGuideWindowDays + 1).isNewUser, isFalse);
    });
```

- [ ] Step 4: `flutter test test/guides test/community/first_session_guidance_test.dart test/community/matches_panel_widget_test.dart test/services/session_reset_test.dart` → All tests passed (the widget tests still pass: the window grew, and A6 adds the milestone overrides).
- [ ] Step 5: commit `lib/services/guide_store.dart lib/pages/community/first_session/first_session_guidance.dart lib/widgets/guides/page_guide.dart lib/services/session_reset.dart test/guides/guide_rule_test.dart test/guides/guide_store_test.dart`; subject `feat(guides): 7-day window, stop at 3 of 4, guide period, chat-tip surface`; tick A4; `<next>` = A5.

---

### Task A5: Strings for the new UI (6 keys × 19 locales)

**Files:** Modify all 19 `lib/l10n/app_*.arb`, generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv` · Test (create) `test/l10n/onboarding_strings_test.dart`
**Interfaces:** Produces `guideProgress(int count)`, `guideChatTip`, `announcementTitle`, `announcementUnavailable`, `notifyAnnouncementsTitle`, `notifyAnnouncementsSubtitle`. (`guide*` keys are also covered by `guide_strings_test.dart`.)

- [ ] Step 1: failing test

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strings added by spec 2026-10-12 (§3, §5.2). The localization tasks (L*)
/// append their keys to [keys].
const keys = [
  'guideProgress',
  'guideChatTip',
  'announcementTitle',
  'announcementUnavailable',
  'notifyAnnouncementsTitle',
  'notifyAnnouncementsSubtitle',
];

void main() {
  final arbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();

  test('19 locales', () => expect(arbs.length, 19));

  test('every locale defines every onboarding string', () {
    for (final f in arbs) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final k in keys) {
        expect(m[k] is String && (m[k] as String).trim().isNotEmpty, isTrue,
            reason: '${f.path} is missing $k');
      }
    }
  });

  test('guideProgress keeps {count} everywhere', () {
    for (final f in arbs) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      expect((m['guideProgress'] as String).contains('{count}'), isTrue,
          reason: f.path);
    }
  });

  test('the machine drafts are queued for native review', () {
    final csv = File('docs/l10n/native-qa-strings-2026-10.csv').readAsStringSync();
    for (final k in keys) {
      expect(RegExp('^app,ko,$k,', multiLine: true).hasMatch(csv), isTrue,
          reason: k);
    }
  });
}
```

- [ ] Step 2: `flutter test test/l10n/onboarding_strings_test.dart` → fails: keys missing.
- [ ] Step 3: run once from `APP`:

```bash
python3 - <<'PY'
import csv, io, json, pathlib
EN = {
 "guideProgress": "Getting started · {count} of 4",
 "guideChatTip": "Long-press to translate or correct",
 "announcementTitle": "Announcement",
 "announcementUnavailable": "This announcement is no longer available.",
 "notifyAnnouncementsTitle": "Announcements",
 "notifyAnnouncementsSubtitle": "News and updates from the BananaTalk team",
}
T = {
 "ar": ["البدء · {count} من 4","اضغط مطولاً للترجمة أو التصحيح","إعلان","هذا الإعلان لم يعد متاحًا.","الإعلانات","أخبار وتحديثات من فريق BananaTalk"],
 "de": ["Erste Schritte · {count} von 4","Lange drücken zum Übersetzen oder Korrigieren","Ankündigung","Diese Ankündigung ist nicht mehr verfügbar.","Ankündigungen","Neuigkeiten und Updates vom BananaTalk-Team"],
 "es": ["Primeros pasos · {count} de 4","Mantén pulsado para traducir o corregir","Anuncio","Este anuncio ya no está disponible.","Anuncios","Noticias y novedades del equipo de BananaTalk"],
 "fr": ["Premiers pas · {count} sur 4","Appui long pour traduire ou corriger","Annonce","Cette annonce n'est plus disponible.","Annonces","Actualités et nouveautés de l'équipe BananaTalk"],
 "hi": ["शुरुआत · 4 में से {count}","अनुवाद या सुधार के लिए देर तक दबाएँ","घोषणा","यह घोषणा अब उपलब्ध नहीं है।","घोषणाएँ","BananaTalk टीम की खबरें और अपडेट"],
 "id": ["Memulai · {count} dari 4","Tekan lama untuk menerjemahkan atau mengoreksi","Pengumuman","Pengumuman ini sudah tidak tersedia.","Pengumuman","Berita dan pembaruan dari tim BananaTalk"],
 "it": ["Primi passi · {count} di 4","Tieni premuto per tradurre o correggere","Annuncio","Questo annuncio non è più disponibile.","Annunci","Novità e aggiornamenti dal team di BananaTalk"],
 "ja": ["はじめの一歩 · {count}/4","長押しで翻訳・添削","お知らせ","このお知らせは現在ご覧いただけません。","お知らせ","BananaTalkチームからのニュースとアップデート"],
 "ko": ["시작하기 · 4개 중 {count}개","길게 눌러 번역하거나 교정하세요","공지","더 이상 볼 수 없는 공지입니다.","공지사항","BananaTalk 팀의 소식과 업데이트"],
 "pt": ["Primeiros passos · {count} de 4","Toque e segure para traduzir ou corrigir","Anúncio","Este anúncio não está mais disponível.","Anúncios","Novidades e atualizações da equipe BananaTalk"],
 "ru": ["Первые шаги · {count} из 4","Нажмите и удерживайте, чтобы перевести или исправить","Объявление","Это объявление больше недоступно.","Объявления","Новости и обновления от команды BananaTalk"],
 "tg": ["Оғоз · {count} аз 4","Барои тарҷума ё ислоҳ дароз пахш кунед","Эълон","Ин эълон дигар дастрас нест.","Эълонҳо","Хабарҳо ва навигариҳо аз дастаи BananaTalk"],
 "th": ["เริ่มต้นใช้งาน · {count} จาก 4","กดค้างเพื่อแปลหรือแก้ไข","ประกาศ","ประกาศนี้ไม่พร้อมใช้งานแล้ว","ประกาศ","ข่าวสารและอัปเดตจากทีม BananaTalk"],
 "tl": ["Pagsisimula · {count} sa 4","Pindutin nang matagal para isalin o itama","Anunsyo","Hindi na available ang anunsyong ito.","Mga anunsyo","Mga balita at update mula sa BananaTalk team"],
 "tr": ["Başlarken · {count}/4","Çevirmek veya düzeltmek için basılı tutun","Duyuru","Bu duyuru artık mevcut değil.","Duyurular","BananaTalk ekibinden haberler ve güncellemeler"],
 "vi": ["Bắt đầu · {count}/4","Nhấn giữ để dịch hoặc sửa","Thông báo","Thông báo này không còn khả dụng.","Thông báo","Tin tức và cập nhật từ đội ngũ BananaTalk"],
 "zh": ["新手入门 · {count}/4","长按可翻译或纠错","公告","此公告已不可用。","公告","来自 BananaTalk 团队的新闻和更新"],
 "zh_TW": ["新手入門 · {count}/4","長按可翻譯或修正","公告","此公告已無法查看。","公告","來自 BananaTalk 團隊的消息與更新"],
}
META = '"@guideProgress": {\n    "description": "Footer on every first-week guide card: how many of the four first actions are done",\n    "placeholders": {\n      "count": { "type": "int" }\n    }\n  }'
def insert(path, pairs, extra=None):
    p = pathlib.Path(path); text = p.read_text(encoding="utf-8").rstrip()
    existing = json.loads(text)
    lines = [f'  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}' for k, v in pairs if k not in existing]
    if extra and "@guideProgress" not in existing: lines.append("  " + extra)
    if not lines: return
    assert text.endswith("}")
    p.write_text(text[:-1].rstrip() + ",\n" + ",\n".join(lines) + "\n}\n", encoding="utf-8")
insert("lib/l10n/app_en.arb", list(EN.items()), META)
keys = list(EN)
rows = []
for loc, vals in T.items():
    insert(f"lib/l10n/app_{loc}.arb", list(zip(keys, vals)))
    rows += [["app", loc, k, EN[k], v, ""] for k, v in zip(keys, vals)]
buf = io.StringIO(); csv.writer(buf, lineterminator="\r\n").writerows(rows)
with open("docs/l10n/native-qa-strings-2026-10.csv", "a", encoding="utf-8", newline="") as f: f.write(buf.getvalue())
PY
flutter gen-l10n
```

- [ ] Step 4: `flutter test test/l10n/onboarding_strings_test.dart test/l10n/guide_strings_test.dart test/l10n/arb_integrity_test.dart` → All tests passed.
- [ ] Step 5: commit `lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/onboarding_strings_test.dart`; subject `i18n(onboarding): guide progress, chat tip, announcement strings in 19 locales`; body "Machine drafts; 108 rows queued for native review."; tick A5; `<next>` = A6.

---

### Task A6: Guide UI — progress footer, real-action retirement, Matches on the same rule

**Files:** Modify `lib/widgets/guides/guide_card.dart`, (full rewrite) `lib/widgets/guides/page_guide.dart`, `lib/pages/community/first_session/matches_first_session_panel.dart`, `lib/pages/community/tabs/matches_tab.dart`, `test/guides/page_guide_test.dart`, `test/guides/guide_card_test.dart`, `test/community/matches_panel_widget_test.dart`
**Interfaces:** Consumes `activationDoneProvider`, `ActivationAction`, `shouldShowGuide`, `guideRetiredReason`, `GuideStore.recordRetired`, `GuideSurface.action`, `guideProgress`.

- [ ] Step 1: failing tests.
  - `test/guides/guide_card_test.dart` append inside `main()`:

```dart
  testWidgets('renders the progress footer only when given', (tester) async {
    Widget card(String? footer) => MaterialApp(
          home: Scaffold(
            body: GuideCard(
              icon: Icons.add_a_photo_rounded,
              accent: const Color(0xFF7C4DFF),
              title: 't',
              body: 'b',
              footer: footer,
            ),
          ),
        );
    await tester.pumpWidget(card('Getting started · 2 of 4'));
    await tester.pumpAndSettle();
    expect(find.text('Getting started · 2 of 4'), findsOneWidget);
    await tester.pumpWidget(card(null));
    await tester.pumpAndSettle();
    expect(find.textContaining('Getting started'), findsNothing);
  });
```

  - `test/guides/page_guide_test.dart`: add imports `package:shared_preferences/shared_preferences.dart`, `package:bananatalk_app/l10n/app_localizations.dart`, `package:bananatalk_app/services/activation_store.dart`, `package:bananatalk_app/services/analytics_service.dart`. Change `_wrap` signature to add `Set<ActivationAction> done = const {}`; add to `overrides`: `activationDoneProvider.overrideWith((ref) => Stream.value(done)),`; change `MaterialApp(` to `MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,`. Append tests:

```dart
  testWidgets('every guide stops at 3 of 4 actions', (tester) async {
    await tester.pumpWidget(_wrap(daysOld: _insideWindow, done: {
      ActivationAction.lesson,
      ActivationAction.message,
      ActivationAction.profile,
    }));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNothing);
  });

  testWidgets('it retires on its own real action', (tester) async {
    await tester.pumpWidget(
        _wrap(daysOld: _insideWindow, done: {ActivationAction.moment}));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNothing);
  });

  testWidgets('another surface\'s action does not retire it, and the footer '
      'counts it', (tester) async {
    await tester.pumpWidget(
        _wrap(daysOld: _insideWindow, done: {ActivationAction.lesson}));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsOneWidget);
    expect(find.text('Getting started · 1 of 4'), findsOneWidget);
  });

  testWidgets('tapping the CTA no longer retires the guide', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_wrap(daysOld: _insideWindow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post a moment'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(_surface.actedKey), isNull);
  });

  testWidgets('a shown guide that retires logs guide_retired once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final events = <String>[];
    AnalyticsService.debugLogSink = (n, p) {
      if (n == 'guide_retired') events.add('${p['surface']}:${p['reason']}');
    };
    addTearDown(() => AnalyticsService.debugLogSink = null);
    await tester.pumpWidget(_wrap(
      daysOld: _insideWindow,
      state: const GuideState(acted: false, timesShown: 1),
      done: {ActivationAction.moment},
    ));
    await tester.pumpAndSettle();
    expect(events, ['moments:acted']);
  });
```

  - `test/community/matches_panel_widget_test.dart`: add import `package:bananatalk_app/services/activation_store.dart`; add `Set<ActivationAction> done = const {},` to `_wrap`'s params and `activationDoneProvider.overrideWith((ref) => Stream.value(done)),` to its overrides. Append:

```dart
  testWidgets('the panel stops at 3 of 4 and shows progress before that',
      (tester) async {
    await tester.pumpWidget(_wrap(
        daysOld: _insideWindow,
        session: _fresh,
        done: {ActivationAction.lesson}));
    await tester.pumpAndSettle();
    expect(find.text('Getting started · 1 of 4'), findsOneWidget);

    await tester.pumpWidget(_wrap(daysOld: _insideWindow, session: _fresh, done: {
      ActivationAction.lesson,
      ActivationAction.moment,
      ActivationAction.profile,
    }));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
  });
```

- [ ] Step 2: `flutter test test/guides/guide_card_test.dart test/guides/page_guide_test.dart test/community/matches_panel_widget_test.dart` → compile error (`footer` unknown) / new tests fail.
- [ ] Step 3: implement.
  - `guide_card.dart`: add constructor param `this.footer,` and field

```dart
  /// "Getting started · N of 4" (spec §3.2). Null hides it.
  final String? footer;
```
  and in `build`, directly after the first `Row(...)` (icon + title/body) and before `if (hasCta || hasSecondary) ...[`, insert:

```dart
            if (footer != null) ...[
              const SizedBox(height: 10),
              Text(
                footer!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
```
  - `page_guide.dart` full file:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/widgets/guides/guide_card.dart';

/// Mounts the first-week guide for one [GuideSurface], or nothing.
///
/// The guide retires on the surface's REAL action (spec §3.2), never on a
/// CTA tap, and every guide stops at 3 of 4 actions or 7 days. Renders
/// `SizedBox.shrink()` when ineligible.
class PageGuide extends ConsumerWidget {
  const PageGuide({
    super.key,
    required this.surface,
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
    this.secondaryLabel,
    this.onSecondary,
    this.acted = false,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  final GuideSurface surface;
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// A page-derived "already done" signal, OR-ed with the stored ones.
  final bool acted;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final withinWindow = userAsync.maybeWhen(
      data: (u) => u.joinedWithinDays(kGuideWindowDays),
      orElse: () => false,
    );
    final stateAsync = ref.watch(guideStateProvider(surface));
    final state = stateAsync.maybeWhen(
      data: (s) => s,
      orElse: () => GuideState.unknown,
    );
    final doneAsync = ref.watch(activationDoneProvider);
    // Loading or unreadable: everything done, i.e. show nothing.
    final done = doneAsync.maybeWhen(
      data: (d) => d,
      orElse: () => ActivationAction.values.toSet(),
    );
    final real = surface.action;
    final actedNow =
        acted || state.acted || (real != null && done.contains(real));
    final show = shouldShowGuide(
      withinWindow: withinWindow,
      acted: actedNow,
      milestonesDone: done.length,
    );

    if (kDebugMode) {
      debugPrint('[Guide:${surface.slug}] show=$show '
          '(within${kGuideWindowDays}d=$withinWindow acted=$actedNow '
          'done=${done.length} views=${state.timesShown})');
    }

    if (!show) {
      if (userAsync.hasValue && stateAsync.hasValue && doneAsync.hasValue) {
        final reason = guideRetiredReason(
          wasShown: state.timesShown > 0,
          withinWindow: withinWindow,
          acted: actedNow,
          milestonesDone: done.length,
        );
        if (reason != null) GuideStore.recordRetired(surface, reason).ignore();
      }
      return const SizedBox.shrink();
    }

    _recordAfterFrame(ref, state.timesShown);

    return Padding(
      padding: padding,
      child: GuideCard(
        icon: icon,
        accent: accent,
        title: title,
        body: body,
        ctaLabel: ctaLabel,
        onCta: onCta == null ? null : () => _onCta(),
        secondaryLabel: secondaryLabel,
        onSecondary:
            onSecondary == null ? null : () => _onCta(secondary: true),
        footer: AppLocalizations.of(context)?.guideProgress(done.length),
      ),
    );
  }

  void _onCta({bool secondary = false}) {
    // Logged, but no longer retires the guide: a tap followed by backing out
    // is not a start. The surface's real action retires it.
    AnalyticsService.instance.guideCtaTapped(
      surface: surface.slug,
      target: secondary ? 'secondary' : 'primary',
    );
    (secondary ? onSecondary! : onCta!)();
  }

  void _recordAfterFrame(WidgetRef ref, int timesShown) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final latch = ref.read(guideRecordedProvider(surface).notifier);
      if (latch.state) return;
      latch.state = true;
      AnalyticsService.instance.guideShown(
        surface: surface.slug,
        timesShown: timesShown + 1,
      );
      // Not invalidating guideStateProvider: that removed the card mid-view.
      GuideStore.recordShown(surface);
    });
  }
}
```
  - `matches_first_session_panel.dart`: add param `this.progressCount,` + field `final int? progressCount;` and pass `footer: progressCount == null ? null : l10n.guideProgress(progressCount!),` to `GuideCard`.
  - `matches_tab.dart`: add `import 'package:bananatalk_app/services/activation_store.dart';`; replace

```dart
        final session = ref
            .watch(firstSessionStateProvider)
            .maybeWhen(data: (s) => s, orElse: () => FirstSessionState.unknown);
        final showGuidance = shouldShowFirstSessionGuidance(
          withinWindow: withinWindow,
          hasMessaged: session.hasMessaged,
        );
```
  with
```dart
        final sessionAsync = ref.watch(firstSessionStateProvider);
        final session = sessionAsync.maybeWhen(
            data: (s) => s, orElse: () => FirstSessionState.unknown);
        final doneAsync = ref.watch(activationDoneProvider);
        final done = doneAsync.maybeWhen(
            data: (d) => d, orElse: () => ActivationAction.values.toSet());
        final messaged =
            session.hasMessaged || done.contains(ActivationAction.message);
        final showGuidance = shouldShowFirstSessionGuidance(
          withinWindow: withinWindow,
          hasMessaged: messaged,
          milestonesDone: done.length,
        );
        if (!showGuidance &&
            user.hasValue &&
            sessionAsync.hasValue &&
            doneAsync.hasValue) {
          final reason = guideRetiredReason(
            wasShown: session.timesShown > 0,
            withinWindow: withinWindow,
            acted: messaged,
            milestonesDone: done.length,
          );
          if (reason != null) {
            GuideStore.recordRetired(GuideSurface.matches, reason).ignore();
          }
        }
```
  and in `MatchesFirstSessionPanel(` add `progressCount: done.length,` after `matchCount: matches.length,`.
- [ ] Step 4: `flutter test test/guides test/community` → All tests passed.
- [ ] Step 5: commit the 4 lib files + 3 test files; subject `feat(guides): retire on real actions, stop at 3 of 4, "Getting started · N of 4"`; tick A6; `<next>` = A7.

---

### Task A7: Chat tip under the first received text message

**Files:** Create `lib/pages/chat/message/chat_tip_row.dart`, `test/chat/chat_tip_row_test.dart` · Modify `lib/pages/chat/message/message_bubble.dart`, `lib/services/session_reset.dart`
**Interfaces:** Consumes `isGuidePeriodProvider`, `guideStateProvider`, `guideRecordedProvider`, `GuideSurface.chatTip`, `GuideStore`, `guideShown`, `guideCtaTapped`, `guideChatTip`. Produces `ChatTipRow`, `retireChatTip(WidgetRef, {required String target})`, `chatTipClaimProvider`.

- [ ] Step 1: failing test `test/chat/chat_tip_row_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/message/chat_tip_row.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';

const _tip = 'Long-press to translate or correct';

Widget _wrap(List<Widget> children, {bool guidePeriod = true}) => ProviderScope(
      overrides: [isGuidePeriodProvider.overrideWith((ref) async => guidePeriod)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Column(children: children)),
      ),
    );

void main() {
  final events = <(String, Map<String, Object>)>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  testWidgets('one bubble per run shows it, and it logs guide_shown',
      (tester) async {
    await tester.pumpWidget(_wrap(const [
      ChatTipRow(messageId: 'a'),
      ChatTipRow(messageId: 'b'),
    ]));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsOneWidget);
    expect(
        events.where((e) => e.$1 == 'guide_shown' && e.$2['surface'] == 'chat_tip'),
        hasLength(1));
  });

  testWidgets('outside the guide period nothing shows', (tester) async {
    await tester.pumpWidget(
        _wrap(const [ChatTipRow(messageId: 'a')], guidePeriod: false));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
  });

  testWidgets('already retired: nothing shows', (tester) async {
    SharedPreferences.setMockInitialValues({'guide_acted_chat_tip': true});
    await tester.pumpWidget(_wrap(const [ChatTipRow(messageId: 'a')]));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
  });

  testWidgets('✕ retires it for good and logs target dismiss', (tester) async {
    await tester.pumpWidget(_wrap(const [ChatTipRow(messageId: 'a')]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_tip_dismiss')));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(GuideSurface.chatTip.actedKey), isTrue);
    expect(events.where((e) => e.$1 == 'guide_cta_tapped').single.$2,
        {'surface': 'chat_tip', 'target': 'dismiss'});
  });

  testWidgets('a long-press anywhere retires it with target primary',
      (tester) async {
    await tester.pumpWidget(_wrap([
      const ChatTipRow(messageId: 'a'),
      Consumer(
        builder: (_, ref, __) => TextButton(
          onPressed: () => retireChatTip(ref, target: 'primary'),
          child: const Text('long-press'),
        ),
      ),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('long-press'));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
    expect(events.where((e) => e.$1 == 'guide_cta_tapped').single.$2,
        {'surface': 'chat_tip', 'target': 'primary'});
  });
}
```

- [ ] Step 2: `flutter test test/chat/chat_tip_row_test.dart` → compile error: `chat_tip_row.dart` missing.
- [ ] Step 3: implement `lib/pages/chat/message/chat_tip_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Which message (if any) holds the tip this app run. A plain object, not
/// state: claiming happens during build, where a provider write is refused,
/// and nothing needs to rebuild when it changes. User-scoped.
class ChatTipClaim {
  String? messageId;

  /// True for the first id ever offered this run, and for it only.
  bool claim(String id) {
    messageId ??= id;
    return messageId == id;
  }
}

final chatTipClaimProvider = Provider<ChatTipClaim>((ref) => ChatTipClaim());

/// "Long-press to translate or correct" under the first received text
/// message the user sees during the guide period (spec §3.3). Once ever.
class ChatTipRow extends ConsumerWidget {
  const ChatTipRow({super.key, required this.messageId});

  final String messageId;

  static const _surface = GuideSurface.chatTip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(isGuidePeriodProvider).valueOrNull ?? false;
    final acted = ref
        .watch(guideStateProvider(_surface))
        .maybeWhen(data: (s) => s.acted, orElse: () => true);
    if (!period || acted) return const SizedBox.shrink();
    if (!ref.read(chatTipClaimProvider).claim(messageId)) {
      return const SizedBox.shrink();
    }
    _recordShownAfterFrame(ref);

    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 52, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.guideChatTip,
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
          InkResponse(
            key: const Key('chat_tip_dismiss'),
            radius: 16,
            onTap: () => retireChatTip(ref, target: 'dismiss'),
            child: Semantics(
              label: MaterialLocalizations.of(context).closeButtonTooltip,
              button: true,
              child: Icon(Icons.close_rounded,
                  size: 16, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _recordShownAfterFrame(WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final latch = ref.read(guideRecordedProvider(_surface).notifier);
      if (latch.state) return;
      latch.state = true;
      final s = await GuideStore.read(_surface);
      AnalyticsService.instance
          .guideShown(surface: _surface.slug, timesShown: s.timesShown + 1);
      await GuideStore.recordShown(_surface);
    });
  }
}

/// Retires the tip: the first context menu on any message (target
/// 'primary') or its ✕ ('dismiss'). The tap is logged only if the tip was
/// actually on screen this run.
Future<void> retireChatTip(WidgetRef ref, {required String target}) async {
  const surface = GuideSurface.chatTip;
  final state = ref.read(guideStateProvider(surface)).valueOrNull;
  if (state == null || state.acted) return;
  if (ref.read(chatTipClaimProvider).messageId != null) {
    AnalyticsService.instance
        .guideCtaTapped(surface: surface.slug, target: target);
  }
  await GuideStore.markActed(surface);
  ref.invalidate(guideStateProvider(surface));
}
```

  `message_bubble.dart`: add `import 'package:bananatalk_app/pages/chat/message/chat_tip_row.dart';`; replace

```dart
                      !widget.isSelectionMode) ...[
                    if (_inlineTranslation != null)
```
  with
```dart
                      !widget.isSelectionMode) ...[
                    ChatTipRow(messageId: widget.message.id),
                    if (_inlineTranslation != null)
```
  and replace `  void _showContextMenu(BuildContext context) {\n    _hideReactionPicker();` with `  void _showContextMenu(BuildContext context) {\n    retireChatTip(ref, target: 'primary').ignore();\n    _hideReactionPicker();`

  `session_reset.dart`: add `import 'package:bananatalk_app/pages/chat/message/chat_tip_row.dart';` and after `'isGuidePeriodProvider': isGuidePeriodProvider,` add `  'chatTipClaimProvider': chatTipClaimProvider,`
- [ ] Step 4: `flutter test test/chat/chat_tip_row_test.dart test/services/session_reset_test.dart` → All tests passed.
- [ ] Step 5: commit `lib/pages/chat/message/chat_tip_row.dart lib/pages/chat/message/message_bubble.dart lib/services/session_reset.dart test/chat/chat_tip_row_test.dart`; subject `feat(chat): long-press tip under the first received message`; tick A7; `<next>` = A8.

---

### Task A8: `PopupBudget` + `LaunchModalCoordinator`

**Files:** Create `lib/services/launch_modal_coordinator.dart`, `test/launch/launch_modal_coordinator_test.dart`
**Interfaces:** Produces `LaunchCandidate`, `LaunchModalCoordinator.run(context, {guidePeriod, updateShown})`, `PopupBudget.tryConsume()`, `PopupBudget.debugReset()`; additive `PopupBudget.spent`.

- [ ] Step 1: failing test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/launch_modal_coordinator.dart';

class _Fake implements LaunchCandidate {
  _Fake(this.id, this.log, {this.due = true, this.allowedForNewUsers = false});
  @override
  final String id;
  @override
  final bool allowedForNewUsers;
  final bool due;
  final List<String> log;
  @override
  Future<bool> isDue() async => due;
  @override
  Future<void> show(BuildContext context) async => log.add(id);
}

Future<BuildContext> _context(WidgetTester t) async {
  late BuildContext ctx;
  await t.pumpWidget(Builder(builder: (c) {
    ctx = c;
    return const SizedBox();
  }));
  return ctx;
}

void main() {
  setUp(PopupBudget.debugReset);

  testWidgets('shows only the first due candidate, in order', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log, due: false),
      _Fake('ads_notice', log, allowedForNewUsers: true),
      _Fake('feature_spotlight', log),
    ]).run(await _context(t), guidePeriod: false, updateShown: false);
    expect(log, ['ads_notice']);
    expect(PopupBudget.tryConsume(), isFalse, reason: 'budget spent');
  });

  testWidgets('guide period: only new-user-safe candidates', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log),
      _Fake('ads_notice', log, allowedForNewUsers: true),
    ]).run(await _context(t), guidePeriod: true, updateShown: false);
    expect(log, ['ads_notice']);
  });

  testWidgets('an update dialog was this launch\'s pop-up', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([_Fake('announcement', log)])
        .run(await _context(t), guidePeriod: false, updateShown: true);
    expect(log, isEmpty);
  });

  testWidgets('priming already took the budget: nothing, not even isDue',
      (t) async {
    expect(PopupBudget.tryConsume(), isTrue);
    final log = <String>[];
    await LaunchModalCoordinator([_Fake('announcement', log)])
        .run(await _context(t), guidePeriod: false, updateShown: false);
    expect(log, isEmpty);
  });

  testWidgets('nothing due leaves the budget for priming', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([_Fake('announcement', log, due: false)])
        .run(await _context(t), guidePeriod: false, updateShown: false);
    expect(PopupBudget.tryConsume(), isTrue);
  });
}
```

- [ ] Step 2: `flutter test test/launch/launch_modal_coordinator_test.dart` → compile error: file missing.
- [ ] Step 3: `lib/services/launch_modal_coordinator.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// One unrequested pop-up per process (spec §4.1): whichever shows first —
/// update dialog, a launch candidate, or notification priming — spends it,
/// so two never stack.
class PopupBudget {
  PopupBudget._();

  static bool _spent = false;

  static bool get spent => _spent;

  /// True if the caller may show a pop-up now (and the budget is spent).
  static bool tryConsume() {
    if (_spent) return false;
    _spent = true;
    return true;
  }

  @visibleForTesting
  static void debugReset() => _spent = false;
}

/// One launch pop-up. [isDue] keeps the pop-up's own throttle.
abstract class LaunchCandidate {
  String get id;

  /// Whether a user inside the guide period may see it (update, ads notice).
  bool get allowedForNewUsers;

  Future<bool> isDue();

  Future<void> show(BuildContext context);
}

/// Shows the first due candidate in [candidates] order, or nothing.
class LaunchModalCoordinator {
  const LaunchModalCoordinator(this.candidates);

  final List<LaunchCandidate> candidates;

  Future<void> run(
    BuildContext context, {
    required bool guidePeriod,
    required bool updateShown,
  }) async {
    if (updateShown || PopupBudget.spent) return;
    for (final candidate in candidates) {
      if (guidePeriod && !candidate.allowedForNewUsers) continue;
      bool due;
      try {
        due = await candidate.isDue();
      } catch (_) {
        due = false;
      }
      if (!due) continue;
      if (!context.mounted) return;
      if (!PopupBudget.tryConsume()) return;
      await candidate.show(context);
      return;
    }
  }
}
```

- [ ] Step 4: `flutter test test/launch/launch_modal_coordinator_test.dart` → All tests passed.
- [ ] Step 5: commit the 2 files; subject `feat(launch): PopupBudget and LaunchModalCoordinator`; tick A8; `<next>` = A9.

---

### Task A9: Notification priming — budget, triggers, events

**Files:** Modify (full rewrite) `lib/widgets/notifications/notification_priming_sheet.dart`, (full rewrite) `lib/pages/community/first_session/first_message_reporter.dart`; Modify `lib/pages/community/tabs/matches_tab.dart`, `lib/pages/community/tabs/waves_tab.dart`, `lib/pages/chat/conversation/chat_conversation_screen.dart` · Test (create) `test/notifications/priming_triggers_test.dart`
**Interfaces:** Consumes `PopupBudget.tryConsume`, `logNotificationPrimeShown`, `logNotificationPrimeResult`, `ActivationStore.markDone`. Produces `maybePrimeNotifications(BuildContext, {String trigger})`, `primeAfterFirstMatches`, `primeAfterFirstWave`, `primeResultFor`, `isLiveIncoming`, `primeAfterFirstMessage` (test seam).

- [ ] Step 1: failing test

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/community/first_session/first_message_reporter.dart';
import 'package:bananatalk_app/widgets/notifications/notification_priming_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('result mapping', () {
    expect(primeResultFor(accepted: true, granted: true), 'granted');
    expect(primeResultFor(accepted: true, granted: false), 'declined');
    expect(primeResultFor(accepted: false, granted: false), 'later');
    expect(primeResultFor(accepted: null, granted: false), 'later');
  });

  group('isLiveIncoming', () {
    final opened = DateTime.utc(2026, 10, 12, 10);
    bool live({String id = 'n', String sender = 'them', String at = '2026-10-12T10:00:05Z'}) =>
        isLiveIncoming(
          beforeIds: {'old'},
          id: id,
          senderId: sender,
          me: 'me',
          createdAt: at,
          openedAt: opened,
        );
    test('a new partner message after open is live', () => expect(live(), isTrue));
    test('history is not', () => expect(live(at: '2026-10-11T09:00:00Z'), isFalse));
    test('my own message is not', () => expect(live(sender: 'me'), isFalse));
    test('an already-listed id is not', () => expect(live(id: 'old'), isFalse));
  });

  test('the first send primes once with trigger first_message_sent', () async {
    SharedPreferences.setMockInitialValues({});
    final triggers = <String>[];
    primeAfterFirstMessage = (t) async => triggers.add(t);
    await reportFirstMessageIfFirst();
    await reportFirstMessageIfFirst();
    expect(triggers, ['first_message_sent']);
  });

  test('call sites carry their triggers; chat open no longer primes', () {
    final chat = File('lib/pages/chat/conversation/chat_conversation_screen.dart')
        .readAsStringSync();
    expect(chat.contains("trigger: 'first_message_received'"), isTrue);
    expect(chat.contains('if (mounted) maybePrimeNotifications(context);'), isFalse);
    expect(File('lib/pages/community/tabs/matches_tab.dart')
        .readAsStringSync()
        .contains('primeNotifications = primeAfterFirstMatches'), isTrue);
    expect(File('lib/pages/community/tabs/waves_tab.dart')
        .readAsStringSync()
        .contains('primeNotifications = primeAfterFirstWave'), isTrue);
    expect(File('lib/widgets/notifications/notification_priming_sheet.dart')
        .readAsStringSync()
        .contains('PopupBudget.tryConsume()'), isTrue);
  });
}
```

- [ ] Step 2: `flutter test test/notifications/priming_triggers_test.dart` → compile errors.
- [ ] Step 3: implement.
  - `notification_priming_sheet.dart` full file:

```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/services/notification_permission.dart';
import 'package:bananatalk_app/services/notification_service.dart';

/// Single-flight guard: `pendingAction` only clears after the sheet closes,
/// so without this a second caller could stack a sheet.
class PrimeGate {
  bool _inFlight = false;

  bool tryEnter() {
    if (_inFlight) return false;
    _inFlight = true;
    return true;
  }

  void exit() => _inFlight = false;
}

final PrimeGate _primeGate = PrimeGate();

/// `notification_prime_result` value for how the sheet closed.
String primeResultFor({required bool? accepted, required bool granted}) =>
    accepted == true ? (granted ? 'granted' : 'declined') : 'later';

/// Whether a message that just appeared in an open conversation is a live
/// incoming one (not history, not pagination, not mine).
bool isLiveIncoming({
  required Set<String> beforeIds,
  required String id,
  required String senderId,
  required String? me,
  required String createdAt,
  required DateTime openedAt,
}) {
  if (beforeIds.contains(id)) return false;
  if (me != null && senderId == me) return false;
  final at = DateTime.tryParse(createdAt);
  if (at == null) return false;
  return !at.isBefore(openedAt.subtract(const Duration(seconds: 10)));
}

/// Offer notification permission at a moment it is obviously useful
/// (spec §4.2: first match batch, first wave, first message sent or
/// received). Shows at most once ever, and only if this process's
/// [PopupBudget] is unspent.
Future<void> maybePrimeNotifications(
  BuildContext context, {
  String trigger = 'unspecified',
}) async {
  final service = NotificationService();
  if (!shouldPrimeNotifications(service.pendingAction)) return;
  if (!context.mounted) return;
  if (!_primeGate.tryEnter()) return;
  try {
    if (!PopupBudget.tryConsume()) return;
    AnalyticsService.instance.logNotificationPrimeShown(trigger);
    final l10n = AppLocalizations.of(context)!;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 40,
                color: Theme.of(sheetContext).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.notifyRepliesTitle,
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(l10n.notifyRepliesBody, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(l10n.notifyRepliesEnable),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(l10n.notifyRepliesLater),
              ),
            ],
          ),
        ),
      ),
    );

    if (accepted == true) {
      final granted = await service.requestFullAuthorization();
      AnalyticsService.instance.logNotificationPrimeResult(
          primeResultFor(accepted: true, granted: granted));
    } else {
      // Covers an explicit Later AND a swipe-dismiss (null).
      await service.markPromptDeclined();
      AnalyticsService.instance.logNotificationPrimeResult(
          primeResultFor(accepted: accepted, granted: false));
    }
  } finally {
    _primeGate.exit();
  }
}

/// Default for MatchesTab: after the first non-empty match batch.
Future<void> primeAfterFirstMatches(BuildContext context) =>
    maybePrimeNotifications(context, trigger: 'first_matches');

/// Default for WavesTab: after the first wave received.
Future<void> primeAfterFirstWave(BuildContext context) =>
    maybePrimeNotifications(context, trigger: 'first_wave');
```
  - `first_message_reporter.dart` full file:

```dart
import 'package:flutter/foundation.dart';

import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/widgets/notifications/notification_priming_sheet.dart';

/// Offers notification permission after the first message is sent. There is
/// no BuildContext on the send paths, so production reaches the app's
/// navigator through the router. Replaceable in tests.
@visibleForTesting
Future<void> Function(String trigger) primeAfterFirstMessage = _primeViaRouter;

Future<void> _primeViaRouter(String trigger) async {
  try {
    final ctx = goRouter.routerDelegate.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await maybePrimeNotifications(ctx, trigger: trigger);
  } catch (_) {}
}

/// Report the first message this user ever sends, once: `first_message_sent`,
/// the `message` activation milestone, and the priming offer.
///
/// Shared because there is no single send path (socket chat, HTTP wave and
/// replies). Fired on a send that SUCCEEDED, never on a Say hi tap. The
/// stored flag is the guard. Best effort: never fails a send.
Future<void> reportFirstMessageIfFirst() async {
  try {
    final state = await FirstSessionStore.read();
    if (state.hasMessaged) {
      if (kDebugMode) debugPrint('[FirstSession] send: not the first, no event');
      return;
    }
    await FirstSessionStore.markMessaged();
    await ActivationStore().markDone(ActivationAction.message);
    if (kDebugMode) {
      debugPrint('[FirstSession] FIRST MESSAGE SENT — panel retires');
    }
    AnalyticsService.instance.firstMessageSent();
    primeAfterFirstMessage('first_message_sent').ignore();
  } catch (_) {
    // Never let reporting break sending.
  }
}
```
  - `matches_tab.dart`: `this.primeNotifications = maybePrimeNotifications,` → `this.primeNotifications = primeAfterFirstMatches,`
  - `waves_tab.dart`: `this.primeNotifications = maybePrimeNotifications,` → `this.primeNotifications = primeAfterFirstWave,`
  - `chat_conversation_screen.dart`:
    - after `bool _rewardedLimitsFlagOn = false;` add

```dart
  // Priming on the first live incoming message (spec §4.2).
  final DateTime _openedAt = DateTime.now();
  bool _primedOnReceive = false;
```
    - delete the initState block from `    // Primed here rather than at splash. 43% of active users send a message in` through its `    );` (the `addPostFrameCallback` that calls `maybePrimeNotifications(context)`), replacing it with `    // Priming moved: first live incoming message (listener in build) and first message sent (first_message_reporter.dart). Every-open priming removed, spec §4.2.`
    - replace `    ref.listen<ChatState>(chatStateProvider(chatParams), (previous, next) {` with

```dart
    ref.listen<ChatState>(chatStateProvider(chatParams), (previous, next) {
      if (previous != null && !_primedOnReceive && !next.isLoading) {
        final before = {for (final m in previous.messages) m.id};
        final live = next.messages.any((m) => isLiveIncoming(
              beforeIds: before,
              id: m.id,
              senderId: m.sender.id,
              me: _currentUserId,
              createdAt: m.createdAt,
              openedAt: _openedAt,
            ));
        if (live) {
          _primedOnReceive = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              maybePrimeNotifications(context,
                  trigger: 'first_message_received');
            }
          });
        }
      }
```
- [ ] Step 4: `flutter test test/notifications/priming_triggers_test.dart test/growth/first_session_test.dart test/growth/reveal_gating_test.dart test/community/first_message_paths_test.dart test/activation/activation_hooks_test.dart` → All tests passed.
- [ ] Step 5: commit the 5 lib files + test; subject `feat(notifications): priming shares the launch budget; first message sent/received triggers; events`; tick A9; `<next>` = A10.

---

### Task A10: AI Study promo into the spotlight rotation

**Files:** Modify `lib/services/promo_service.dart`, `lib/widgets/promos/feature_spotlight_sheet.dart`, `lib/pages/menu_tab/TabBarMenu.dart` · Delete `lib/widgets/promo/ai_study_promo_modal.dart` · Test (create) `test/promos/promo_rotation_test.dart`
**Interfaces:** Produces `PromoType.aiStudy`, `pickPromo(WidgetRef, {bool lessonDone})`, `pickPromoFor({required bool coinsEligible, required bool lessonDone})`. Consumes `ActivationStore.isDone`.

- [ ] Step 1: failing test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/promo_service.dart';
import 'package:bananatalk_app/widgets/promos/feature_spotlight_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('aiStudy is appended so stored rotation indexes keep their meaning', () {
    expect(PromoType.values,
        [PromoType.coins, PromoType.rooms, PromoType.voice, PromoType.aiStudy]);
  });

  test('AI Study rotates in until a lesson is done', () async {
    final picks = [
      for (var i = 0; i < 4; i++)
        await pickPromoFor(coinsEligible: false, lessonDone: false),
    ];
    expect(picks,
        [PromoType.rooms, PromoType.voice, PromoType.aiStudy, PromoType.rooms]);
  });

  test('skipped after a lesson', () async {
    final picks = [
      for (var i = 0; i < 4; i++)
        await pickPromoFor(coinsEligible: false, lessonDone: true),
    ];
    expect(picks, isNot(contains(PromoType.aiStudy)));
  });

  testWidgets('the spotlight renders the AI Study promo', (t) async {
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () => showFeatureSpotlight(c, PromoType.aiStudy, onTry: () {}),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Practice with AI scenarios'), findsOneWidget);
  });
}
```

- [ ] Step 2: `flutter test test/promos/promo_rotation_test.dart` → compile error (`aiStudy`, `pickPromoFor`).
- [ ] Step 3: implement.
  - `promo_service.dart`: `enum PromoType { coins, rooms, voice }` → `enum PromoType { coins, rooms, voice, aiStudy }`; append `  PromoType.aiStudy,` as the last entry of `_rotationOrder`; replace the whole `pickPromo` function with

```dart
/// Picks the promo to show now, or null. [lessonDone] drops the AI Study
/// promo for someone who has already completed a lesson (spec §4.1).
Future<PromoType?> pickPromo(WidgetRef ref, {bool lessonDone = false}) {
  final coinsEnabled = ref.read(appConfigProvider).maybeWhen(
        data: (config) => config?.coinsEnabled ?? false,
        orElse: () => false,
      );
  // showAdsProvider is true for non-VIP users; VIPs skip the coins upsell.
  final showAds = ref.read(showAdsProvider);
  return pickPromoFor(
    coinsEligible: coinsEnabled && showAds,
    lessonDone: lessonDone,
  );
}

/// Rules, in order: global dismiss stop; once per day; eligibility; per-promo
/// snooze; rotation from the stored index, advanced past the pick.
Future<PromoType?> pickPromoFor({
  required bool coinsEligible,
  required bool lessonDone,
}) async {
  final prefs = await SharedPreferences.getInstance();

  final dismissCount = prefs.getInt(_dismissCountKey) ?? 0;
  if (dismissCount >= _maxDismissCount) return null;

  final today = _dateOnly(DateTime.now());
  if (prefs.getString(_lastShownDateKey) == today) return null;

  final eligible = <PromoType>{
    if (coinsEligible) PromoType.coins,
    PromoType.rooms,
    PromoType.voice,
    if (!lessonDone) PromoType.aiStudy,
  };

  final now = DateTime.now();
  final startIndex =
      (prefs.getInt(_rotationIndexKey) ?? 0) % _rotationOrder.length;

  for (var offset = 0; offset < _rotationOrder.length; offset++) {
    final idx = (startIndex + offset) % _rotationOrder.length;
    final type = _rotationOrder[idx];
    if (!eligible.contains(type)) continue;

    final hiddenUntilIso = prefs.getString(_hiddenUntilKey(type));
    if (hiddenUntilIso != null) {
      final hiddenUntil = DateTime.tryParse(hiddenUntilIso);
      if (hiddenUntil != null && now.isBefore(hiddenUntil)) continue;
    }

    await prefs.setInt(_rotationIndexKey, (idx + 1) % _rotationOrder.length);
    return type;
  }
  return null;
}
```
  - `feature_spotlight_sheet.dart` `_contentFor`: add after the `voice` case

```dart
    case PromoType.aiStudy:
      return _SpotlightContent(
        emoji: '🎭',
        headline: l10n.aiStudyPromoTitle,
        subtitle: l10n.aiStudyPromoBody,
        accent: AppColors.primary,
      );
```
  - `TabBarMenu.dart`: replace import `package:bananatalk_app/widgets/promo/ai_study_promo_modal.dart` with `package:bananatalk_app/pages/ai/tutor/scenario_picker_screen.dart` and add `package:bananatalk_app/services/activation_store.dart`; delete the 5 lines from `      // Weekly promo for AI Study / practice scenarios. Self-throttles to` through the closing `      }` of `AiStudyPromoModal.showIfDue(context);`; in `_maybeShowFeatureSpotlight` replace `    final promo = await pickPromo(ref);` with

```dart
    final lessonDone =
        await ref.read(activationStoreProvider).isDone(ActivationAction.lesson);
    if (!mounted) return;
    final promo = await pickPromo(ref, lessonDone: lessonDone);
```
    and in `_openPromoDestination` add

```dart
      case PromoType.aiStudy:
        Navigator.push(
          context,
          AppPageRoute(builder: (_) => const ScenarioPickerScreen()),
        );
```
  - `git rm lib/widgets/promo/ai_study_promo_modal.dart`
- [ ] Step 4: `flutter test test/promos/promo_rotation_test.dart` and `flutter analyze lib/pages/menu_tab/TabBarMenu.dart lib/services/promo_service.dart lib/widgets/promos` → tests pass, no errors.
- [ ] Step 5: commit `lib/services/promo_service.dart lib/widgets/promos/feature_spotlight_sheet.dart lib/pages/menu_tab/TabBarMenu.dart lib/widgets/promo/ai_study_promo_modal.dart test/promos/promo_rotation_test.dart`; subject `feat(promo): AI Study joins the spotlight rotation; weekly AI Study modal removed`; tick A10; `<next>` = A11.

---

### Task A11: `Announcement` model, app-config list, `lang`, seen set

**Files:** Create `lib/models/announcement.dart`, `lib/services/announcement_seen_store.dart`, `test/announcements/announcement_model_test.dart` · Modify `lib/models/app_config.dart`, `lib/services/app_config_service.dart`
**Interfaces:** Produces `Announcement` (contract fields + `fromJson`; additive `hasButton`, `fromLegacy`), `AppConfig.announcements`, `kAnnouncementsSeenKey = 'announcements_seen_ids'`, `AnnouncementSeenStore.read/add`, `pickAnnouncement`. Consumes backend `GET app-config?platform=&lang=`.

- [ ] Step 1: failing test

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/app_config_service.dart';

Announcement _a(String id, {int p = 0}) =>
    Announcement(id: id, title: 't$id', body: 'b', priority: p);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('app-config parses the announcements list', () {
    final c = AppConfig.fromJson({
      'announcements': [
        {'id': 'x', 'title': 'Hi', 'body': 'B', 'priority': 5, 'buttonUrl': '/boost', 'buttonLabel': 'Go'},
        {'title': 'no id'},
      ],
    });
    expect(c.announcements.map((a) => a.id), ['x']);
    expect(c.announcements.single.priority, 5);
    expect(c.announcements.single.hasButton, isTrue);
    expect(AppConfig.fromJson({}).announcements, isEmpty);
  });

  group('pickAnnouncement', () {
    test('highest priority unseen; ties keep server order', () {
      expect(pickAnnouncement(live: [_a('1'), _a('2', p: 3), _a('3', p: 3)],
              legacy: null, seen: {})!.id, '2');
      expect(pickAnnouncement(live: [_a('1'), _a('2', p: 3)],
              legacy: null, seen: {'2'})!.id, '1');
    });
    test('all seen: nothing', () {
      expect(pickAnnouncement(live: [_a('1')], legacy: null, seen: {'1'}), isNull);
    });
    test('old backend (no list): the legacy field', () {
      expect(pickAnnouncement(live: const [], legacy: _a('env'), seen: {})!.id, 'env');
    });
    test('a list present: legacy ignored', () {
      expect(pickAnnouncement(live: [_a('1')], legacy: _a('env'), seen: {'1'}), isNull);
    });
  });

  test('legacy announcement needs active, id and text', () {
    const a = AppAnnouncement(active: false, id: 'e', title: 'T', body: '',
        emoji: '📢', buttonLabel: '', buttonUrl: '');
    expect(Announcement.fromLegacy(a), isNull);
    expect(Announcement.fromLegacy(const AppAnnouncement(active: true, id: 'e',
            title: 'T', body: '', emoji: '📢', buttonLabel: '', buttonUrl: ''))!
        .id, 'e');
  });

  test('seen set: add, read, and old dismissed_announcement_ keys', () async {
    SharedPreferences.setMockInitialValues({'dismissed_announcement_env1': true});
    await AnnouncementSeenStore.add('db1');
    expect(await AnnouncementSeenStore.read(), {'db1', 'env1'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(kAnnouncementsSeenKey), ['db1']);
  });

  test('app-config is requested with the app language', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});
    Uri? asked;
    await http.runWithClient(
      () => AppConfigService().fetch(),
      () => MockClient((req) async {
        asked = req.url;
        return http.Response(jsonEncode({'data': {}}), 200);
      }),
    );
    expect(asked!.queryParameters['lang'], 'ko');
  });
}
```

- [ ] Step 2: `flutter test test/announcements/announcement_model_test.dart` → compile error.
- [ ] Step 3: implement. `lib/models/announcement.dart`:

```dart
import 'package:bananatalk_app/models/app_config.dart';

/// An admin announcement as the app sees it (backend `PublicAnnouncement`),
/// already resolved to the caller's language.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.emoji,
    this.imageUrl,
    this.buttonLabel,
    this.buttonUrl,
    this.priority = 0,
  });

  final String id;
  final String title;
  final String body;
  final String? emoji;
  final String? imageUrl;
  final String? buttonLabel;
  final String? buttonUrl;
  final int priority;

  bool get hasButton =>
      (buttonLabel ?? '').isNotEmpty && (buttonUrl ?? '').isNotEmpty;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    String? opt(String key) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final p = json['priority'];
    return Announcement(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      emoji: opt('emoji'),
      imageUrl: opt('imageUrl'),
      buttonLabel: opt('buttonLabel'),
      buttonUrl: opt('buttonUrl'),
      priority: p is num ? p.toInt() : 0,
    );
  }

  /// The single env-var `announcement` older servers send, or null when it
  /// is inactive, unnamed or empty.
  static Announcement? fromLegacy(AppAnnouncement? a) {
    if (a == null || !a.active || a.id.isEmpty) return null;
    if (a.title.isEmpty && a.body.isEmpty) return null;
    return Announcement(
      id: a.id,
      title: a.title,
      body: a.body,
      emoji: a.emoji.isEmpty ? null : a.emoji,
      buttonLabel: a.buttonLabel.isEmpty ? null : a.buttonLabel,
      buttonUrl: a.buttonUrl.isEmpty ? null : a.buttonUrl,
    );
  }
}
```

  `lib/services/announcement_seen_store.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/announcement.dart';

/// User-scoped (not device-level, so logout clears it).
const String kAnnouncementsSeenKey = 'announcements_seen_ids';

/// Key the env-var-only modal wrote per dismissed id; still honoured.
const String _legacyDismissedPrefix = 'dismissed_announcement_';

const int _maxSeenIds = 200;

class AnnouncementSeenStore {
  /// Seen ids, or null when storage is unreadable (callers then show
  /// nothing rather than repeat a pop-up).
  static Future<Set<String>?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = <String>{};
      try {
        seen.addAll(prefs.getStringList(kAnnouncementsSeenKey) ?? const []);
      } catch (_) {}
      for (final k in prefs.getKeys()) {
        if (k.startsWith(_legacyDismissedPrefix)) {
          seen.add(k.substring(_legacyDismissedPrefix.length));
        }
      }
      return seen;
    } catch (_) {
      return null;
    }
  }

  static Future<void> add(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> ids;
      try {
        ids = List.of(prefs.getStringList(kAnnouncementsSeenKey) ?? const []);
      } catch (_) {
        ids = [];
      }
      if (ids.contains(id)) return;
      ids.add(id);
      if (ids.length > _maxSeenIds) ids = ids.sublist(ids.length - _maxSeenIds);
      await prefs.setStringList(kAnnouncementsSeenKey, ids);
    } catch (_) {}
  }
}

/// Highest-priority unseen announcement (first wins a tie: the server
/// already sorts priority desc, startsAt desc). [live] empty means an old
/// backend or no DB announcement: fall back to the legacy single field.
Announcement? pickAnnouncement({
  required List<Announcement> live,
  required Announcement? legacy,
  required Set<String> seen,
}) {
  final pool = live.isNotEmpty ? live : [if (legacy != null) legacy];
  Announcement? best;
  for (final a in pool) {
    if (a.id.isEmpty || seen.contains(a.id)) continue;
    if (best == null || a.priority > best.priority) best = a;
  }
  return best;
}
```

  `lib/models/app_config.dart`: add `import 'package:bananatalk_app/models/announcement.dart';`; add field after `final AppAnnouncement? announcement;`:

```dart
  /// Every live in-app announcement for this platform + language, sorted by
  /// the server (spec §5.2). Empty on an older server.
  final List<Announcement> announcements;
```
  constructor: `this.announcements = const [],` after `this.announcement,`; in `fromJson` after the `announcement:` argument:

```dart
      announcements: json['announcements'] is List
          ? (json['announcements'] as List)
              .whereType<Map>()
              .map((m) => Announcement.fromJson(Map<String, dynamic>.from(m)))
              .where((a) => a.id.isNotEmpty)
              .toList()
          : const <Announcement>[],
```
  `lib/services/app_config_service.dart`: add `import 'package:bananatalk_app/services/language_service.dart';`; replace

```dart
      final base = '${Endpoints.baseURL}${Endpoints.appConfigURL}';
      final tag = _platformTag;
      final url = tag.isEmpty ? base : '$base?platform=$tag';
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
```
  with
```dart
      final base = '${Endpoints.baseURL}${Endpoints.appConfigURL}';
      final tag = _platformTag;
      // `lang` picks the announcement translations (spec §5.1).
      final lang = await LanguageService.getAppLanguage();
      final url = Uri.parse(base).replace(queryParameters: {
        if (tag.isNotEmpty) 'platform': tag,
        'lang': lang,
      });
      final res = await http.get(url).timeout(_timeout);
```
- [ ] Step 4: `flutter test test/announcements/announcement_model_test.dart test/growth/reveal_gating_test.dart` → All tests passed.
- [ ] Step 5: commit the 4 lib files + test; subject `feat(announcements): model, app-config list with lang, seen set and selection`; tick A11; `<next>` = A12.

---

### Task A12: Launch wiring — candidates, update report, `TabBarMenu`

**Files:** Create `lib/services/launch_candidates.dart`, `test/launch/launch_candidates_test.dart` · Modify (full rewrite) `lib/widgets/promo/announcement_modal.dart`, (full rewrite) `lib/services/version_check_coordinator.dart`; Modify `lib/widgets/promo/ads_notice_modal.dart`, `lib/pages/menu_tab/TabBarMenu.dart`
**Interfaces:** Consumes `LaunchCandidate`, `LaunchModalCoordinator`, `PopupBudget`, `isGuidePeriodProvider`, `pickPromo`, `pickAnnouncement`, `AnnouncementSeenStore`, `Announcement`. Produces `AnnouncementCandidate`, `AdsNoticeCandidate`, `FeatureSpotlightCandidate`, `standardLaunchCandidates`, `AnnouncementModal.show(BuildContext, Announcement)`, `openAnnouncementLink`, `announcementLinkKind`, `VersionCheckCoordinator.lastCheckShowedUpdate`, `Future<bool> VersionCheckCoordinator.check`.

- [ ] Step 1: failing test

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/launch_candidates.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';

const _cfg = AppConfig(
  minVersion: '0.0.0', latestVersion: '0.0.0', forceUpdate: false,
  iosUrl: '', androidUrl: '', releaseNotes: '',
  announcements: [Announcement(id: 'a1', title: 'Big news', body: 'Body', priority: 1)],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('order and new-user filter (spec §4.1)', () {
    final c = standardLaunchCandidates(
        config: null, pickSpotlight: () async => null, onSpotlightTry: (_) {});
    expect(c.map((x) => x.id), ['announcement', 'ads_notice', 'feature_spotlight']);
    expect(c.map((x) => x.allowedForNewUsers), [false, true, false]);
  });

  test('ads notice is due once per install', () async {
    expect(await AdsNoticeCandidate().isDue(), isTrue);
    SharedPreferences.setMockInitialValues({'ads_notice_shown_v1': true});
    expect(await AdsNoticeCandidate().isDue(), isFalse);
  });

  testWidgets('announcement: due when unseen, shown, then seen', (t) async {
    final c = AnnouncementCandidate(config: _cfg);
    expect(await c.isDue(), isTrue);
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (ctx) => TextButton(
          onPressed: () => c.show(ctx), child: const Text('go'))),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Big news'), findsOneWidget);
    expect(await AnnouncementSeenStore.read(), contains('a1'));
    expect(await AnnouncementCandidate(config: _cfg).isDue(), isFalse);
  });

  test('announcement links', () {
    expect(announcementLinkKind('/learning/daily'), AnnouncementLinkKind.inApp);
    expect(announcementLinkKind('https://banatalk.com/x'), AnnouncementLinkKind.external);
    expect(announcementLinkKind('  '), AnnouncementLinkKind.none);
  });

  test('the version check no longer owns the announcement; the shell runs the coordinator', () {
    expect(File('lib/services/version_check_coordinator.dart')
        .readAsStringSync().contains('AnnouncementModal'), isFalse);
    final shell = File('lib/pages/menu_tab/TabBarMenu.dart').readAsStringSync();
    expect(shell.contains('LaunchModalCoordinator('), isTrue);
    expect(shell.contains('AdsNoticeModal.showIfNeeded'), isFalse);
  });
}
```

- [ ] Step 2: `flutter test test/launch/launch_candidates_test.dart` → compile error.
- [ ] Step 3: implement.
  - `lib/widgets/promo/announcement_modal.dart` full file:

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/router/app_router.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

enum AnnouncementLinkKind { inApp, external, none }

/// `/path` is an app route; anything with a scheme opens outside the app.
AnnouncementLinkKind announcementLinkKind(String url) {
  final u = url.trim();
  if (u.isEmpty) return AnnouncementLinkKind.none;
  if (u.startsWith('/')) return AnnouncementLinkKind.inApp;
  final uri = Uri.tryParse(u);
  return uri != null && uri.hasScheme
      ? AnnouncementLinkKind.external
      : AnnouncementLinkKind.none;
}

Future<void> openAnnouncementLink(String url) async {
  switch (announcementLinkKind(url)) {
    case AnnouncementLinkKind.inApp:
      goRouter.push(url.trim());
    case AnnouncementLinkKind.external:
      await launchUrl(Uri.parse(url.trim()),
          mode: LaunchMode.externalApplication);
    case AnnouncementLinkKind.none:
      break;
  }
}

/// The in-app announcement sheet. Selection and the seen set live in
/// `AnnouncementCandidate`; this only renders.
class AnnouncementModal {
  static Future<void> show(BuildContext context, Announcement announcement) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AnnouncementSheet(announcement: announcement),
    );
  }
}

class _AnnouncementSheet extends StatelessWidget {
  const _AnnouncementSheet({required this.announcement});

  final Announcement announcement;

  static const _teal = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = announcement;
    final primaryButton = ElevatedButton.styleFrom(
      backgroundColor: _teal,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            if (a.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  a.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_teal, Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(a.emoji ?? '📢',
                      style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (a.title.isNotEmpty) ...[
              Text(
                a.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            if (a.body.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: isDark ? 0.10 : 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _teal.withValues(alpha: isDark ? 0.20 : 0.15)),
                ),
                child: Text(
                  a.body,
                  style: TextStyle(
                      fontSize: 14, color: context.textSecondary, height: 1.65),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: primaryButton,
                onPressed: () {
                  Navigator.pop(context);
                  if (a.hasButton) openAnnouncementLink(a.buttonUrl!);
                },
                child: Text(
                  a.hasButton ? a.buttonLabel! : l10n.ok,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (a.hasButton) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.dismiss,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```
  - `ads_notice_modal.dart`: replace the `AdsNoticeModal` class (keep `_AdsNoticeSheet`) with

```dart
/// One-time notice shown after ads were introduced. Now a launch candidate:
/// [isDue] is the old once-only check, [show] records and shows.
class AdsNoticeModal {
  static const _prefKey = 'ads_notice_shown_v1';

  static Future<bool> isDue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) != true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AdsNoticeSheet(),
    );
  }
}
```
  - `lib/services/launch_candidates.dart`:

```dart
import 'package:flutter/widgets.dart';

import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/services/promo_service.dart';
import 'package:bananatalk_app/widgets/promo/ads_notice_modal.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';
import 'package:bananatalk_app/widgets/promos/feature_spotlight_sheet.dart';

class AnnouncementCandidate implements LaunchCandidate {
  AnnouncementCandidate({required this.config});

  final AppConfig? config;
  Announcement? _picked;

  @override
  String get id => 'announcement';

  @override
  bool get allowedForNewUsers => false;

  @override
  Future<bool> isDue() async {
    final c = config;
    if (c == null) return false;
    final seen = await AnnouncementSeenStore.read();
    if (seen == null) return false;
    _picked = pickAnnouncement(
      live: c.announcements,
      legacy: Announcement.fromLegacy(c.announcement),
      seen: seen,
    );
    return _picked != null;
  }

  @override
  Future<void> show(BuildContext context) async {
    final a = _picked;
    if (a == null) return;
    await AnnouncementSeenStore.add(a.id);
    if (!context.mounted) return;
    await AnnouncementModal.show(context, a);
  }
}

class AdsNoticeCandidate implements LaunchCandidate {
  @override
  String get id => 'ads_notice';

  @override
  bool get allowedForNewUsers => true;

  @override
  Future<bool> isDue() => AdsNoticeModal.isDue();

  @override
  Future<void> show(BuildContext context) => AdsNoticeModal.show(context);
}

class FeatureSpotlightCandidate implements LaunchCandidate {
  FeatureSpotlightCandidate({required this.pick, required this.onTry});

  final Future<PromoType?> Function() pick;
  final void Function(PromoType) onTry;
  PromoType? _picked;

  @override
  String get id => 'feature_spotlight';

  @override
  bool get allowedForNewUsers => false;

  @override
  Future<bool> isDue() async {
    _picked = await pick();
    return _picked != null;
  }

  @override
  Future<void> show(BuildContext context) async {
    final p = _picked;
    if (p == null) return;
    await showFeatureSpotlight(context, p, onTry: () => onTry(p));
    await markShown(p);
  }
}

/// Spec §4.1 order after the update dialog (which ran in splash):
/// announcement → ads notice → feature spotlight.
List<LaunchCandidate> standardLaunchCandidates({
  required AppConfig? config,
  required Future<PromoType?> Function() pickSpotlight,
  required void Function(PromoType) onSpotlightTry,
}) =>
    [
      AnnouncementCandidate(config: config),
      AdsNoticeCandidate(),
      FeatureSpotlightCandidate(pick: pickSpotlight, onTry: onSpotlightTry),
    ];
```
  - `lib/services/version_check_coordinator.dart` full file:

```dart
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/services/app_config_service.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/widgets/update_dialog.dart';

/// Decides whether to prompt for an update (runs in splash).
///
/// - running < minVersion or forceUpdate → blocking dialog (always shown)
/// - running < latestVersion → soft prompt, once per [_softPromptCooldown],
///   and only if the launch's [PopupBudget] is unspent
///
/// The announcement moved to `LaunchModalCoordinator` (spec §4.1); this
/// reports whether it showed, so the coordinator stops.
class VersionCheckCoordinator {
  static const _lastSoftPromptKey = 'app_update_last_soft_prompt_ms';
  static const Duration _softPromptCooldown = Duration(hours: 24);

  /// Whether a [check] in this process put an update dialog on screen.
  static bool lastCheckShowedUpdate = false;

  final AppConfigService _service;

  VersionCheckCoordinator({AppConfigService? service})
      : _service = service ?? AppConfigService();

  Future<bool> check(BuildContext context) async {
    final config = await _service.fetch();
    if (config == null) return false;
    if (!context.mounted) return false;

    final running = (await PackageInfo.fromPlatform()).version;
    final mustForce =
        compareSemver(running, config.minVersion) < 0 || config.forceUpdate;
    final shouldSoftPrompt =
        !mustForce && compareSemver(running, config.latestVersion) < 0;

    if (mustForce) {
      if (!context.mounted) return false;
      PopupBudget.tryConsume(); // spends it; shown regardless
      lastCheckShowedUpdate = true;
      await showUpdateDialog(
        context: context,
        force: true,
        iosUrl: config.iosUrl,
        androidUrl: config.androidUrl,
        releaseNotes: config.releaseNotes,
      );
      return true;
    }

    if (shouldSoftPrompt) {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt(_lastSoftPromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastShown >= _softPromptCooldown.inMilliseconds) {
        if (!context.mounted) return false;
        if (!PopupBudget.tryConsume()) return false;
        lastCheckShowedUpdate = true;
        await showUpdateDialog(
          context: context,
          force: false,
          iosUrl: config.iosUrl,
          androidUrl: config.androidUrl,
          releaseNotes: config.releaseNotes,
        );
        await prefs.setInt(_lastSoftPromptKey, now);
        return true;
      }
    }
    return false;
  }
}
```
  - `TabBarMenu.dart`:
    - imports: delete `package:bananatalk_app/widgets/promo/ads_notice_modal.dart` and `package:bananatalk_app/widgets/promos/feature_spotlight_sheet.dart`; add `package:bananatalk_app/models/app_config.dart`, `package:bananatalk_app/providers/provider_root/app_config_providers.dart`, `package:bananatalk_app/services/guide_store.dart`, `package:bananatalk_app/services/launch_candidates.dart`, `package:bananatalk_app/services/launch_modal_coordinator.dart`, `package:bananatalk_app/services/version_check_coordinator.dart`.
    - replace the `_featureSpotlightAttemptedThisLaunch` doc comment + declaration with

```dart
/// The launch pop-ups run once per process (spec §4.1), even if TabsScreen
/// is rebuilt by a deep link.
bool _launchModalsRanThisProcess = false;
```
    - replace everything from `    WidgetsBinding.instance.addPostFrameCallback((_) {\n      ref.read(badgeCountProvider.notifier).fetchBadgeCount();` through the closing `  }` of `_maybeShowFeatureSpotlight()` (the line before `  /// Deep-link for the feature spotlight's "Try it" CTA.`) with

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(badgeCountProvider.notifier).fetchBadgeCount();
      _runLaunchModals();
    });
  }

  /// At most one pop-up per launch, chosen by [LaunchModalCoordinator]. The
  /// update dialog already ran in splash; inside the guide period only the
  /// ads notice can follow it.
  Future<void> _runLaunchModals() async {
    if (_launchModalsRanThisProcess) return;
    _launchModalsRanThisProcess = true;
    // Let the shell paint first (the ads notice always waited a second).
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    bool guidePeriod;
    try {
      guidePeriod = await ref.read(isGuidePeriodProvider.future);
    } catch (_) {
      guidePeriod = true; // unknown: the restrictive answer
    }
    AppConfig? config;
    try {
      config = await ref.read(appConfigProvider.future);
    } catch (_) {
      config = null;
    }
    if (!mounted) return;

    final store = ref.read(activationStoreProvider);
    await LaunchModalCoordinator(standardLaunchCandidates(
      config: config,
      pickSpotlight: () async => pickPromo(
        ref,
        lessonDone: await store.isDone(ActivationAction.lesson),
      ),
      onSpotlightTry: _openPromoDestination,
    )).run(
      context,
      guidePeriod: guidePeriod,
      updateShown: VersionCheckCoordinator.lastCheckShowedUpdate,
    );
  }
```
- [ ] Step 4: `flutter test test/launch` and `flutter analyze lib/pages/menu_tab lib/services lib/widgets/promo` → tests pass, no errors.
- [ ] Step 5: commit `lib/services/launch_candidates.dart lib/widgets/promo/announcement_modal.dart lib/widgets/promo/ads_notice_modal.dart lib/services/version_check_coordinator.dart lib/pages/menu_tab/TabBarMenu.dart test/launch/launch_candidates_test.dart`; subject `feat(launch): one pop-up per launch — update, announcement, ads notice, spotlight`; tick A12; `<next>` = A13.

---

### Task A13: `AnnouncementScreen` at `/announcement/:id`

**Files:** Create `lib/providers/announcement_provider.dart`, `lib/pages/announcements/announcement_screen.dart`, `test/announcements/announcement_screen_test.dart` · Modify `lib/router/app_router.dart`, `lib/services/session_reset.dart`
**Interfaces:** Consumes `GET announcements/:id?lang=` → `{success, data: PublicAnnouncement}`, `Announcement.fromJson`, `openAnnouncementLink`, `AnnouncementSeenStore.add`. Produces `announcementDetailProvider`, `AnnouncementScreen(id)`, route `/announcement/:id`.

- [ ] Step 1: failing test

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/pages/announcements/announcement_screen.dart';
import 'package:bananatalk_app/providers/announcement_provider.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';

Widget _wrap(Future<Announcement?> Function() load) => ProviderScope(
      overrides: [announcementDetailProvider('a1').overrideWith((ref) => load())],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AnnouncementScreen(id: 'a1'),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the announcement and marks it seen', (t) async {
    await t.pumpWidget(_wrap(() async => const Announcement(
        id: 'a1', title: 'Big news', body: 'Details', buttonLabel: 'Open',
        buttonUrl: 'https://banatalk.com')));
    await t.pumpAndSettle();
    expect(find.text('Big news'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(await AnnouncementSeenStore.read(), contains('a1'));
  });

  testWidgets('gone (404): unavailable, no retry', (t) async {
    await t.pumpWidget(_wrap(() async => null));
    await t.pumpAndSettle();
    expect(find.text('This announcement is no longer available.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('failure: unavailable with retry', (t) async {
    await t.pumpWidget(_wrap(() async => throw Exception('offline')));
    await t.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });

  test('the route exists', () {
    expect(File('lib/router/app_router.dart').readAsStringSync()
        .contains("path: '/announcement/:id'"), isTrue);
  });
}
```

- [ ] Step 2: `flutter test test/announcements/announcement_screen_test.dart` → compile error.
- [ ] Step 3: implement. `lib/providers/announcement_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/language_service.dart';

/// One announcement in the user's app language; null when it no longer
/// exists (404). Other failures throw so the screen can offer Retry.
final announcementDetailProvider =
    FutureProvider.family<Announcement?, String>((ref, id) async {
  final lang = await LanguageService.getAppLanguage();
  final res = await ApiClient()
      .get('announcements/$id', queryParams: {'lang': lang});
  if (res.statusCode == 404) return null;
  if (!res.success || res.data is! Map) {
    throw Exception(res.error ?? 'Could not load announcement');
  }
  return Announcement.fromJson(Map<String, dynamic>.from(res.data as Map));
});
```

  `lib/pages/announcements/announcement_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/providers/announcement_provider.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';

/// Opened from the notifications list or the push (spec §5.2).
class AnnouncementScreen extends ConsumerWidget {
  const AnnouncementScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(announcementDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.announcementTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Unavailable(
          onRetry: () => ref.invalidate(announcementDetailProvider(id)),
        ),
        data: (a) {
          if (a == null) return const _Unavailable();
          // Read here: the launch pop-up must not repeat it.
          AnnouncementSeenStore.add(a.id).ignore();
          return _Body(announcement: a);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (a.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              a.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (a.emoji != null) ...[
          Text(a.emoji!, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
        ],
        Text(
          a.title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SelectableText(
          a.body,
          style: TextStyle(fontSize: 15, height: 1.6, color: context.textSecondary),
        ),
        if (a.hasButton) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => openAnnouncementLink(a.buttonUrl!),
            child: Text(a.buttonLabel!),
          ),
        ],
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 48, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(l10n.announcementUnavailable, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
```

  `app_router.dart`: add `import 'package:bananatalk_app/pages/announcements/announcement_screen.dart';`; after the `/boost` `GoRoute(...)`, add

```dart

    // Announcement detail: notifications-list rows and `announcement` pushes.
    GoRoute(
      path: '/announcement/:id',
      pageBuilder: (context, state) => _buildSlideTransition(
        state: state,
        child: AnnouncementScreen(id: state.pathParameters['id']!),
      ),
    ),
```
  `session_reset.dart`: add `import 'package:bananatalk_app/providers/announcement_provider.dart';` and `  'announcementDetailProvider': announcementDetailProvider,` after `'notificationHistoryProvider': notificationHistoryProvider,`.
- [ ] Step 4: `flutter test test/announcements/announcement_screen_test.dart test/services/session_reset_test.dart` → All tests passed.
- [ ] Step 5: commit the 3 new lib/test files + `lib/router/app_router.dart lib/services/session_reset.dart`; subject `feat(announcements): detail screen at /announcement/:id`; tick A13; `<next>` = A14.

---

### Task A14: Notifications list type + push routing

**Files:** Modify `lib/services/notification_router.dart`, `lib/pages/notifications/notification_history_screen.dart` · Test (create) `test/notifications/announcement_notification_test.dart`
**Interfaces:** Consumes push data `{type: 'announcement', announcementId}` and `Notification{type:'announcement', data:{announcementId}}`. Produces `notificationTapPayload(NotificationItem)`.

- [ ] Step 1: failing test

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/pages/notifications/notification_history_screen.dart';
import 'package:bananatalk_app/services/notification_router.dart';

NotificationItem _item(String type, Map<String, dynamic> data) => NotificationItem(
    id: 'n1', type: type, title: 't', body: 'b', data: data, read: false,
    createdAt: DateTime(2026, 10, 12));

void main() {
  test('an announcement push opens its screen over home', () {
    final plan = NotificationRouter.planFor('announcement', {'announcementId': 'a1'});
    expect(plan.path, '/announcement/a1');
    expect(plan.usePushAfterHome, isTrue);
  });

  test('without an id it just opens home', () {
    expect(NotificationRouter.planFor('announcement', {}).path, '/home');
  });

  test('list rows carry the type the router needs', () {
    final p = notificationTapPayload(_item('announcement', {'announcementId': 'a1'}));
    expect(p, {'type': 'announcement', 'announcementId': 'a1', 'notificationId': 'n1'});
    expect(notificationTapPayload(_item('moment_like', {'momentId': 'm'})),
        {'momentId': 'm', 'notificationId': 'n1'});
  });

  test('announcement rows have their own icon and colour', () {
    final src = File('lib/pages/notifications/notification_history_screen.dart')
        .readAsStringSync();
    expect("case 'announcement':".allMatches(src).length, 2);
  });
}
```

- [ ] Step 2: `flutter test test/notifications/announcement_notification_test.dart` → compile error / failures.
- [ ] Step 3: implement.
  - `notification_router.dart` `targetPathForType`: before `      case 'missed_call':` add

```dart
      // Admin announcements (spec §5.2): push and notifications-list row.
      case 'announcement':
        final announcementId = data['announcementId']?.toString();
        return (announcementId != null && announcementId.isNotEmpty)
            ? '/announcement/$announcementId'
            : null;

```
  - `notification_history_screen.dart`: add top-level (above the screen class)

```dart
/// What a list-row tap hands the router. Announcement rows store only
/// `{announcementId}`, so their type is injected; other rows are unchanged.
/// The row's own id rides along as `notificationId` so the tap is reported.
Map<String, dynamic> notificationTapPayload(NotificationItem n) => {
      if (n.type == 'announcement') 'type': 'announcement',
      ...n.data,
      'notificationId': n.id,
    };
```
    replace
```dart
              NotificationRouter.handleNotification(context, {
                ...notification.data,
                'notificationId': notification.id,
              });
```
    with `              NotificationRouter.handleNotification(context, notificationTapPayload(notification));`
    In `_getNotificationIcon` before `default:` add `      case 'announcement':\n        return Icons.campaign_rounded;`; in `_getNotificationColor` before `default:` add `      case 'announcement':\n        return const Color(0xFFFF7043); // deep orange`
- [ ] Step 4: `flutter test test/notifications/announcement_notification_test.dart test/growth/lifecycle_links_test.dart` → All tests passed.
- [ ] Step 5: commit `lib/services/notification_router.dart lib/pages/notifications/notification_history_screen.dart test/notifications/announcement_notification_test.dart`; subject `feat(notifications): announcement rows and pushes open the announcement`; tick A14; `<next>` = A15.

---

### Task A15: Settings → Notifications "Announcements" toggle

**Files:** Modify `lib/models/notification_models.dart`, `lib/providers/notification_settings_provider.dart`, `lib/pages/notifications/notification_settings_screen.dart` · Test (create) `test/notifications/announcements_setting_test.dart`
**Interfaces:** Consumes/produces `notificationSettings.announcements` (Boolean, default true), toggle key `'announcements'`.

- [ ] Step 1: failing test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/pages/notifications/notification_settings_screen.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';

class _Fake extends StateNotifier<AsyncValue<NotificationSettings>>
    implements NotificationSettingsNotifier {
  _Fake() : super(AsyncValue.data(NotificationSettings.defaultSettings()));
  final toggles = <(String, bool)>[];
  @override
  Future<void> toggleSetting(String settingName, bool value) async =>
      toggles.add((settingName, value));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('announcements defaults on and round-trips', () {
    expect(NotificationSettings.defaultSettings().announcements, isTrue);
    expect(NotificationSettings.fromJson({}).announcements, isTrue);
    final off = NotificationSettings.fromJson({'announcements': false});
    expect(off.announcements, isFalse);
    expect(off.toJson()['announcements'], isFalse);
    expect(off.copyWith(announcements: true).announcements, isTrue);
  });

  testWidgets('the toggle writes the announcements setting', (t) async {
    final fake = _Fake();
    await t.pumpWidget(ProviderScope(
      overrides: [notificationSettingsProvider.overrideWith((ref) => fake)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationSettingsScreen(),
      ),
    ));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Announcements'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Announcements'));
    await t.pumpAndSettle();
    expect(fake.toggles.last, ('announcements', false));
  });
}
```

- [ ] Step 2: `flutter test test/notifications/announcements_setting_test.dart` → compile error (`announcements`).
- [ ] Step 3: implement.
  - `NotificationSettings`: add `final bool announcements;` after `final bool marketing;`; constructor `this.announcements = true,` after `required this.mutedConversations,`; `defaultSettings()` add `announcements: true,`; `fromJson` add `announcements: json['announcements'] ?? true,`; `toJson` add `'announcements': announcements,`; `copyWith` add parameter `bool? announcements,` and `announcements: announcements ?? this.announcements,`.
  - provider `toggleSetting`: after the `case 'marketing':` block add

```dart
      case 'announcements':
        updatedSettings = currentSettings.copyWith(announcements: value);
        break;
```
  - screen: replace

```dart
                    .toggleSetting('marketing', value);
              },
              isLast: true,
            ),
```
  with
```dart
                    .toggleSetting('marketing', value);
              },
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.campaign_outlined,
              iconColor: const Color(0xFFFF7043),
              title: l10n.notifyAnnouncementsTitle,
              subtitle: l10n.notifyAnnouncementsSubtitle,
              value: settings.announcements && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('announcements', value);
              },
              isLast: true,
            ),
```
- [ ] Step 4: `flutter test test/notifications/announcements_setting_test.dart` → All tests passed.
- [ ] Step 5: commit the 3 lib files + test; subject `feat(settings): Announcements notification toggle`; tick A15; `<next>` = A16.

---

### Task A16: Suspension screen reads `banReason`

**Files:** Modify `lib/services/api_client.dart`, `lib/pages/authentication/account_suspended_screen.dart` · Test (create) `test/authentication/suspension_reason_test.dart`
**Interfaces:** Consumes 403 body `{ error, banReason: string|null }`. Produces `Function(String? banReason)? onAccountSuspended` (callers in `main.dart` already pass the value straight to `AccountSuspendedScreen(reason:)`; unchanged).

- [ ] Step 1: failing test

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/account_suspended_screen.dart';
import 'package:bananatalk_app/services/api_client.dart';

Future<String?> _suspendedWith(Map<String, dynamic> body) async {
  final client = ApiClient();
  String? got = 'unset';
  client.onAccountSuspended = (r) => got = r;
  await http.runWithClient(
    () => client.get('probe/suspended-${body.hashCode}'),
    () => MockClient((_) async => http.Response(jsonEncode(body), 403)),
  );
  client.onAccountSuspended = null;
  return got;
}

Widget _screen(String? reason) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccountSuspendedScreen(reason: reason),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 't'});
    ApiClient().clearTokenCache();
  });

  test('the callback gets banReason, not the English message', () async {
    expect(
      await _suspendedWith({
        'error': 'Your account has been suspended. Reason: spam',
        'banReason': 'spam',
      }),
      'spam',
    );
    expect(
      await _suspendedWith({'error': 'Your account has been suspended.'}),
      isNull,
    );
  });

  testWidgets('a reason is shown under the localized label', (t) async {
    await t.pumpWidget(_screen('spam'));
    expect(find.text('Reason: spam'), findsOneWidget);
  });

  testWidgets('no reason: the generic line', (t) async {
    await t.pumpWidget(_screen(null));
    expect(find.text('Your account is no longer accessible.'), findsOneWidget);
  });
}
```

- [ ] Step 2: `flutter test test/authentication/suspension_reason_test.dart` → fails (callback receives the full message; screen shows the raw text).
- [ ] Step 3: implement.
  - `api_client.dart`: replace the doc + field

```dart
  /// Step 14: called when the server returns 403 with an error message
  /// starting with "Your account has been suspended" — the banned-user
  /// indicator from the protect middleware (Step 14 B1).
  Function(String reason)? onAccountSuspended;
```
  with
```dart
  /// Called when the server returns 403 "Your account has been suspended".
  /// Receives the server's `banReason` field (null when none); the English
  /// message is never parsed for it (spec §5.1).
  Function(String? banReason)? onAccountSuspended;
```
    and replace `          onAccountSuspended?.call(raw403);` with

```dart
          final banReason = body['banReason'];
          onAccountSuspended?.call(
            banReason is String && banReason.trim().isNotEmpty
                ? banReason.trim()
                : null,
          );
```
  - `account_suspended_screen.dart`: replace the whole `_displayReason` method with

```dart
  /// [raw] is the server's `banReason` (spec §5.1), already just the reason.
  String _displayReason(BuildContext context, String? raw) {
    final l10n = AppLocalizations.of(context)!;
    final reason = raw?.trim() ?? '';
    if (reason.isEmpty) return l10n.suspendedNoAccess;
    return '${l10n.suspendedReason} $reason';
  }
```
- [ ] Step 4: `flutter test test/authentication/suspension_reason_test.dart test/services/session_expiry_test.dart` → All tests passed. Then the part's full gate: `flutter analyze` (no new errors) and `flutter test test/activation test/guides test/community test/chat test/launch test/promos test/announcements test/notifications test/l10n test/services test/growth` → All tests passed.
- [ ] Step 5: commit `lib/services/api_client.dart lib/pages/authentication/account_suspended_screen.dart test/authentication/suspension_reason_test.dart`; subject `fix(auth): suspension screen shows banReason, never parses the English message`; tick A16; `<next>` text instead: "Remaining (docs/REMAINING_WORK.md §0d): device QA rows only."

---

## Contradictions between code and spec/contract, and resolutions

1. **Update candidate.** Spec puts "update" in the coordinator; the version check actually runs in `splash_screen.dart`, before `TabsScreen` exists. → `VersionCheckCoordinator.check` returns `bool`, sets `static lastCheckShowedUpdate`, spends `PopupBudget`; the coordinator takes `updateShown` (contract signature) and stops.
2. **Guides never refresh.** `guideStateProvider` is cached for the whole run and nothing else changes it, so "retire on the real action" would only happen on the next launch. → `activationDoneProvider` (StreamProvider fed by `ActivationStore.changes`). Additive names: `doneSet`, `changes`, `isProfileComplete`, `kGuideMilestoneStop`, `GuideSurface.action`, `guideRetiredReason`, `GuideStore.recordRetired`, `PopupBudget.spent`, `AnalyticsService.debugLogSink`, `checkProfileComplete(..., {store})`.
3. **Background moment.** `_createMomentWithBackgroundUpload` only queues; `createMoments` runs in `UploadQueueService` → hooked there (both paths).
4. **Profile "after each edit save".** Every edit screen invalidates `userProvider`, and ProfileMain is built eagerly → one `listenManual` plus the back-fill in `isGuidePeriodProvider`.
5. **Priming from `reportFirstMessageIfFirst`.** It has no BuildContext → router navigator context through a replaceable `primeAfterFirstMessage`.
6. **"First received message".** `ChatState` has no live flag → new id, not mine, `createdAt` ≥ open − 10 s.
7. **App-config `lang`.** The app never sent it → added (`LanguageService.getAppLanguage`).
8. **User scoping.** `clearUserSessionPrefs` already removes all non-device keys, so the new prefs need no extra code; only providers are registered.
9. **Tests that assumed a 3-day window** (`guide_store_test`: "shorter than isNewUser") are rewritten; `shouldShowFirstSessionGuidance` keeps `milestonesDone` optional (default 0) so its seven legacy test calls are unchanged.
10. **Suspension.** The app has no socket-suspended handler; only the REST 403 consumes `banReason`. `main.dart` is unchanged.
11. **Copy cleanup.** `AnnouncementModal`'s hardcoded "Dismiss" and "Got it 👍" become `l10n.dismiss` / `l10n.ok`. Not hooked: the WelcomeBack modal in splash (not in spec §4.1), the vocab-pack practice screen (it has no completion call to the server), and the now-unused `aiStudyPromoCTA` / `aiStudyPromoDismiss` keys.

# Part 3 — Localization and Calls Phase 2

Spec: `docs/superpowers/specs/2026-10-12-onboarding-announcements-design.md` §6, §8 · calls design: `docs/superpowers/specs/2026-10-08-calls-reliability-design.md` §3, §6 · contract: `docs/superpowers/plans/parts/00-contract.md`.
Order (contract): L* after A*, then C*. All app paths are relative to APP, backend paths to BACKEND.

## Localization

### What the re-grep found (2026-10-12, `main` @ `f3742650`)

The spec's "74 strings in 56 files" was a single-line `Text('…')` count. A tokenizer that also follows
multi-line `Text(\n  '…')` calls, adjacent-literal concatenation and `${…}` with nested quotes finds
**553 `Text`/`SelectableText` literals with English words in 170 files**. Of those:

| Bucket | Literals | Handling |
|---|---|---|
| Live, user-facing | **402 in 128 files** | L1–L12 (282 new keys, 113 rows reuse an existing key, 9 rows share a new key with another row) |
| Staff-only admin + debug (`lib/pages/admin/`, `pages/reports/admin_reports_screen.dart`, `screens/livekit_test_screen.dart`) | 55 | allowlisted in L13 |
| Files with no importer (19 files, list in L13) | 65 | allowlisted in L13, reason "unreachable" |
| Brand / unit only (`VIP`, `XP`, `Bananatalk`, `GIPHY`, `HD`, `MB`, `km`, `@firdavsDev`) | 29 | allowed by token rule in L13 |
| Diagnostic block `pages/vip/vip_payment_screen.dart` ("Debug Info:", "User ID: …") | 2 | allowlisted by exact text in L13 |

Property literals (`hintText:`, `labelText:`, `tooltip:`) are a further 54 and are **not** in this wave or
its guard (recorded as an open item in L13's commit).

Tasks are grouped by area, guide/announcement destinations first: chat (L1–L2), moments (L3), community/matches
(L4), learn (L5–L6), AI Study (L7–L8), notifications/profile (L9), then stories, money/pop-ups, shared.

### Standard L procedure (Step 3 of every L task)

1. **English.** For each row whose placeholders column is not "(existing key)", add the key to
   `lib/l10n/app_en.arb` with the English value exactly as in the table (`\n` stays the JSON escape `\n`).
   Every key with placeholders also gets metadata, e.g.
   ```json
   "chatSendingMedia": "Sending {mediaType}...",
   "@chatSendingMedia": { "placeholders": { "mediaType": { "type": "Object" } } },
   "learnWordsToReview": "{dueCount, plural, =1{1 word to review} other{{dueCount} words to review}}",
   "@learnWordsToReview": { "placeholders": { "dueCount": { "type": "int" } } }
   ```
   Type = what the table says (`Object` for anything interpolated, `int` for plural counts).
2. **18 other locales.** Add the same keys to every other `lib/l10n/app_*.arb` (`ar de es fr hi id it ja ko pt ru tg th tl tr vi zh zh_TW`)
   with a machine-drafted translation: same placeholder names, plural keeps `=1{…}`/`other{…}` (add `few`/`many`
   arms for `ar`/`ru` as existing plural keys in those files do), brand words (`VIP`, `XP`, `Bananatalk`) untouched.
   No `@key` metadata outside `app_en.arb`.
3. **Native-review record.** Append one row per key per non-English locale to
   `docs/l10n/native-qa-strings-2026-10.csv`: `app,<locale>,<key>,"<english>","<draft>",` (last column empty).
4. **Replace.** In each file:line of the table, replace the literal with the "replace the literal with"
   expression. Where `l10n` is not in scope add `final l10n = AppLocalizations.of(context)!;` at the top of that
   `build`/builder (import `package:bananatalk_app/l10n/app_localizations.dart`); drop `const` from any
   constructor whose child is now runtime. Lines are as of `f3742650` — match by text if they drifted.
5. `flutter gen-l10n` (must report no untranslated messages), then Step 4.

### Shared L test files (created in L1, extended by L2–L12)

`test/l10n/hardcoded_text_scanner.dart`:
```dart
import 'dart:io';

/// One English `Text('…')` / `SelectableText('…')` literal found in source.
class HardcodedText {
  HardcodedText(this.path, this.line, this.text);
  final String path;
  final int line;
  final String text;
  @override
  String toString() => '$path:$line  $text';
}

final _call = RegExp(r'(?<![\w.])(?:Text|SelectableText)\(\s*');
final _interp = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');
final _escape = RegExp(r'\\.');
final _letters = RegExp(r'[A-Za-z]{2,}');

int _commentStart(String line) {
  var quote = '';
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (quote.isNotEmpty) {
      if (c == r'\') {
        i++;
      } else if (c == quote) {
        quote = '';
      }
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
    } else if (c == '/' && line[i + 1] == '/') {
      return i;
    }
  }
  return -1;
}

String _stripLineComments(String src) => src.split('\n').map((line) {
      final i = _commentStart(line);
      return i < 0 ? line : line.substring(0, i).padRight(line.length);
    }).join('\n');

/// A Dart string literal at [i] (optionally raw / triple-quoted), with
/// `${…}` (which may hold quotes of its own) kept verbatim.
(String, int)? _literal(String s, int i) {
  var raw = false;
  if (s[i] == 'r') {
    raw = true;
    i++;
  }
  if (i >= s.length) return null;
  final q = s[i];
  if (q != "'" && q != '"') return null;
  final triple = s.startsWith(q * 3, i);
  i += triple ? 3 : 1;
  final out = StringBuffer();
  while (i < s.length) {
    if (triple ? s.startsWith(q * 3, i) : s[i] == q) {
      return (out.toString(), i + (triple ? 3 : 1));
    }
    if (!triple && s[i] == '\n') return null;
    if (!raw && s[i] == r'\' && i + 1 < s.length) {
      out.write(s.substring(i, i + 2));
      i += 2;
      continue;
    }
    if (!raw && s.startsWith(r'${', i)) {
      var depth = 0;
      var j = i + 1;
      for (; j < s.length; j++) {
        final c = s[j];
        if (c == '{') {
          depth++;
        } else if (c == '}') {
          if (--depth == 0) break;
        } else if (c == "'" || c == '"') {
          final inner = _literal(s, j);
          if (inner == null) return null;
          j = inner.$2 - 1;
        }
      }
      out.write(s.substring(i, j + 1));
      i = j + 1;
      continue;
    }
    out.write(s[i]);
    i++;
  }
  return null;
}

/// English-bearing Text literals in [source]; adjacent literals are joined.
List<HardcodedText> scanSource(String path, String source) {
  final src = _stripLineComments(source);
  final hits = <HardcodedText>[];
  for (final m in _call.allMatches(src)) {
    var i = m.end;
    final parts = <String>[];
    while (true) {
      while (i < src.length && ' \t\r\n'.contains(src[i])) {
        i++;
      }
      if (i >= src.length) break;
      final lit = _literal(src, i);
      if (lit == null) break;
      parts.add(lit.$1);
      i = lit.$2;
    }
    if (parts.isEmpty) continue;
    final text = parts.join();
    final bare = text.replaceAll(_interp, '').replaceAll(_escape, '');
    if (_letters.hasMatch(bare)) {
      final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
      hits.add(HardcodedText(path, line, text));
    }
  }
  return hits;
}

List<HardcodedText> scanFiles(Iterable<String> paths) =>
    [for (final p in paths) ...scanSource(p, File(p).readAsStringSync())];
```

`test/l10n/hardcoded_strings_test.dart`:
```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'hardcoded_text_scanner.dart';

/// New keys per localization task (plan part 30, L1–L12). Each task adds its entry.
const Map<String, List<String>> _keysByTask = {
  // L1..L12 entries go here.
};

/// Files (under lib/) each task must leave with no English Text literal.
const Map<String, List<String>> _filesByTask = {
  // L1..L12 entries go here.
};

/// Keys whose draft may legitimately equal the English in some locale
/// (loanwords). Add with a one-line reason; empty by default.
const Set<String> _mayMatchEnglish = {};

final _placeholder = RegExp(r'\{(\w+)[,}]');

void main() {
  final arbs = <String, Map<String, dynamic>>{
    for (final f in Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb')))
      f.uri.pathSegments.last: jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  };
  final en = arbs['app_en.arb']!;

  for (final task in _keysByTask.keys) {
    group(task, () {
      test('every key is in all 19 locales, translated, placeholders kept', () {
        expect(arbs.length, 19);
        final problems = <String>[];
        for (final key in _keysByTask[task]!) {
          final source = en[key];
          if (source is! String || source.trim().isEmpty) {
            problems.add('app_en.arb: $key missing');
            continue;
          }
          final names = _placeholder.allMatches(source).map((m) => m.group(1)!).toSet();
          arbs.forEach((file, map) {
            final value = map[key];
            if (value is! String || value.trim().isEmpty) {
              problems.add('$file: $key missing');
              return;
            }
            if (file != 'app_en.arb' && value == source && !_mayMatchEnglish.contains(key)) {
              problems.add('$file: $key left in English');
            }
            for (final n in names) {
              if (!value.contains('{$n')) problems.add('$file: $key lost {$n}');
            }
          });
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      test('its files have no English Text literal left', () {
        final left = scanFiles(_filesByTask[task]!.map((f) => 'lib/$f'));
        expect(left, isEmpty, reason: left.join('\n'));
      });
    });
  }
}
```


### Localization tasks

### Task L1: Localize Chat surface: list, input, conversation, paywall
**Files:**
  - `lib/pages/chat/chat_screen_wrapper.dart`
  - `lib/pages/chat/conversation/chat_conversation_screen.dart`
  - `lib/pages/chat/dialogs/translate_unlock_sheet.dart`
  - `lib/pages/chat/input/chat_input_bar.dart`
  - `lib/pages/chat/input/chat_input_section.dart`
  - `lib/pages/chat/list/chat_list_screen.dart`
  - `lib/pages/chat/list/chat_list_tile.dart`
  - `lib/pages/chat/panels/gif_picker_panel.dart`
  - `lib/widgets/connection_status_indicator.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 17 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

18 literals in 9 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/chat/chat_screen_wrapper.dart:111 | `chatDailyLimitBody` | Free users can chat with up to {count} people per day.\nUpgrade to VIP for unlimited conversations! | count:Object | `l10n.chatDailyLimitBody(DailyChatLimitService.maxDailyChats)` |
| pages/chat/conversation/chat_conversation_screen.dart:1334 | `chatCompressingVideo` | Compressing video... | — | `l10n.chatCompressingVideo` |
| pages/chat/conversation/chat_conversation_screen.dart:1501 | `chatShareLocationBody` | Send your current location to {name}. Only do this with people you trust. | name:Object | `l10n.chatShareLocationBody(widget.userName.isNotEmpty ? widget.userName : l10n.chatShareLocationThisChat) + new key chatShareLocationThisChat = "this chat"` |
| pages/chat/dialogs/translate_unlock_sheet.dart:20 | `chatTranslationLimitReached` | Translation limit reached | — | `l10n.chatTranslationLimitReached` |
| pages/chat/dialogs/translate_unlock_sheet.dart:22 | `chatTranslateLimitBody` | You've used up today's free translations in this chat. Unlock more instantly with coins. | — | `l10n.chatTranslateLimitBody` |
| pages/chat/input/chat_input_bar.dart:265 | `chatReplyingTo` | Replying to {name} | name:Object | `l10n.chatReplyingTo(widget.otherUserName ?? l10n.chatReplyingToFallback) + new key chatReplyingToFallback = "user"` |
| pages/chat/input/chat_input_section.dart:235 | `vipBenefitUnlimited` | Unlimited | (existing key) | `l10n.vipBenefitUnlimited` |
| pages/chat/input/chat_input_section.dart:315 | `chatSendingMedia` | Sending {mediaType}... | mediaType:Object | `l10n.chatSendingMedia(mediaType)` |
| pages/chat/list/chat_list_screen.dart:870 | `chatEnterUsernameStart` | Enter username to start a chat | — | `l10n.chatEnterUsernameStart` |
| pages/chat/list/chat_list_screen.dart:950 | `chatSearching` | Searching for @{username}... | username:Object | `l10n.chatSearching(username)` |
| pages/chat/list/chat_list_screen.dart:1074 | `chatDeleteConversationBody` | Delete your conversation with {name}? This cannot be undone. | name:Object | `l10n.chatDeleteConversationBody(partner.name)` |
| pages/chat/list/chat_list_screen.dart:1315 | `chatQrCode` | QR Code | — | `l10n.chatQrCode` |
| pages/chat/list/chat_list_tile.dart:129 | `chatDraft` | Draft:  | — | `l10n.chatDraft` |
| pages/chat/list/chat_list_tile.dart:160 | `chatTyping` | typing... | — | `l10n.chatTyping` |
| pages/chat/panels/gif_picker_panel.dart:348 | `noGifsFound` | No GIFs found | (existing key) | `l10n.noGifsFound` |
| pages/chat/panels/gif_picker_panel.dart:357 | `tryDifferentSearch` | Try a different search term | (existing key) | `l10n.tryDifferentSearch` |
| pages/chat/panels/gif_picker_panel.dart:404 | `chatPoweredBy` | Powered by  | — | `l10n.chatPoweredBy` |
| widgets/connection_status_indicator.dart:88 | `chatReconnecting` | Reconnecting to chat... | — | `l10n.chatReconnecting` |


Two extra keys used inside the replacements above: `chatShareLocationThisChat` = `this chat`, `chatReplyingToFallback` = `user` (no placeholders).

- [ ] **Step 1: failing test.** Create `test/l10n/hardcoded_text_scanner.dart` and `test/l10n/hardcoded_strings_test.dart` exactly as in "Shared L test files" above, then fill in the L1 entries:
```dart
// in _keysByTask:
  'L1': [
    'chatDailyLimitBody',
    'chatCompressingVideo',
    'chatShareLocationBody',
    'chatTranslationLimitReached',
    'chatTranslateLimitBody',
    'chatReplyingTo',
    'chatSendingMedia',
    'chatEnterUsernameStart',
    'chatSearching',
    'chatDeleteConversationBody',
    'chatQrCode',
    'chatDraft',
    'chatTyping',
    'chatPoweredBy',
    'chatReconnecting',
    'chatShareLocationThisChat',
    'chatReplyingToFallback',
  ],
// in _filesByTask:
  'L1': [
    'pages/chat/chat_screen_wrapper.dart',
    'pages/chat/conversation/chat_conversation_screen.dart',
    'pages/chat/dialogs/translate_unlock_sheet.dart',
    'pages/chat/input/chat_input_bar.dart',
    'pages/chat/input/chat_input_section.dart',
    'pages/chat/list/chat_list_screen.dart',
    'pages/chat/list/chat_list_tile.dart',
    'pages/chat/panels/gif_picker_panel.dart',
    'widgets/connection_status_indicator.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L1` → "app_en.arb: … missing" and 18 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/chat/chat_screen_wrapper.dart lib/pages/chat/conversation/chat_conversation_screen.dart lib/pages/chat/dialogs/translate_unlock_sheet.dart lib/pages/chat/input/chat_input_bar.dart lib/pages/chat/input/chat_input_section.dart lib/pages/chat/list/chat_list_screen.dart lib/pages/chat/list/chat_list_tile.dart lib/pages/chat/panels/gif_picker_panel.dart lib/widgets/connection_status_indicator.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/chat/chat_screen_wrapper.dart lib/pages/chat/conversation/chat_conversation_screen.dart lib/pages/chat/dialogs/translate_unlock_sheet.dart lib/pages/chat/input/chat_input_bar.dart lib/pages/chat/input/chat_input_section.dart lib/pages/chat/list/chat_list_screen.dart lib/pages/chat/list/chat_list_tile.dart lib/pages/chat/panels/gif_picker_panel.dart lib/widgets/connection_status_indicator.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 384 left**" (next: L2).
  Message: `i18n(l1): localize chat surface: list, input, conversation, paywall` — body: "17 new keys, 18 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 384 hardcoded literals (L2..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L2: Localize Chat messages, bubbles, wallpaper, translation sheet
**Files:**
  - `lib/pages/chat/message/bubble/bubble_actions_menu.dart`
  - `lib/pages/chat/message/message_bubble.dart`
  - `lib/pages/chat/message/message_bubble/image_message_view.dart`
  - `lib/pages/chat/message/message_bubble/story_share_message_view.dart`
  - `lib/pages/chat/message/message_bubble/text_message_view.dart`
  - `lib/pages/chat/message/message_bubble/voice_message_view.dart`
  - `lib/pages/chat/message/typing_indicator.dart`
  - `lib/pages/chat/wallpaper/wallpaper_picker_screen.dart`
  - `lib/widgets/correction_message_bubble.dart`
  - `lib/widgets/forwarded_message_indicator.dart`
  - `lib/widgets/translation_bottom_sheet.dart`
  - `lib/widgets/voice_message_player.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 20 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

31 literals in 12 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/chat/message/bubble/bubble_actions_menu.dart:38 | `chatMessageFailedToSend` | Message failed to send | — | `l10n.chatMessageFailedToSend` |
| pages/chat/message/message_bubble.dart:612 | `chatSendingEllipsis` | Sending... | — | `l10n.chatSendingEllipsis` |
| pages/chat/message/message_bubble.dart:639 | `chatFailedTapOptions` | Failed · Tap for options | — | `l10n.chatFailedTapOptions` |
| pages/chat/message/message_bubble/image_message_view.dart:89 | `chatMessageWasDeleted` | This message was deleted | — | `l10n.chatMessageWasDeleted` |
| pages/chat/message/message_bubble/image_message_view.dart:147 | `repliedToYourStory` | Replied to your story | (existing key) | `l10n.repliedToYourStory` |
| pages/chat/message/message_bubble/story_share_message_view.dart:247 | `chatStory` | Story | — | `l10n.chatStory` |
| pages/chat/message/message_bubble/text_message_view.dart:145 | `chatMessageWasDeleted` | This message was deleted | — | `l10n.chatMessageWasDeleted` |
| pages/chat/message/message_bubble/text_message_view.dart:188 | `chatHi` | Hi! | — | `l10n.chatHi` |
| pages/chat/message/message_bubble/text_message_view.dart:250 | `repliedToYourStory` | Replied to your story | (existing key) | `l10n.repliedToYourStory` |
| pages/chat/message/message_bubble/text_message_view.dart:414 | `chatEdited` | edited | — | `l10n.chatEdited` |
| pages/chat/message/message_bubble/voice_message_view.dart:78 | `chatMessageWasDeleted` | This message was deleted | — | `l10n.chatMessageWasDeleted` |
| pages/chat/message/typing_indicator.dart:135 | `typing` | typing | (existing key) | `l10n.typing` |
| pages/chat/message/typing_indicator.dart:214 | `typing` | typing | (existing key) | `l10n.typing` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:493 | `chatPremium` | Premium ✨ | — | `l10n.chatPremium` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:642 | `chatUnlockPremiumWallpapers` | Unlock all Premium ✨ wallpapers for 💎{cost} coins? This unlocks the whole pack for good. | cost:Object | `l10n.chatUnlockPremiumWallpapers(cost)` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:723 | `chatWallpaperForName` | Chat wallpaper for {userName} | userName:Object | `l10n.chatWallpaperForName(widget.userName)` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:730 | `solidColors` | Solid Colors | (existing key) | `l10n.solidColors` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:821 | `gradients` | Gradients | (existing key) | `l10n.gradients` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:908 | `customImage` | Custom Image | (existing key) | `l10n.customImage` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:948 | `chatChooseGallery` | Choose from gallery | — | `l10n.chatChooseGallery` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:962 | `preview` | Preview | (existing key) | `l10n.preview` |
| pages/chat/wallpaper/wallpaper_picker_screen.dart:1071 | `chatHiThere` | Hi there! 😊 | — | `l10n.chatHiThere` |
| widgets/correction_message_bubble.dart:147 | `chatCorrected` | {correctorName} corrected | correctorName:Object | `l10n.chatCorrected(correctorName)` |
| widgets/correction_message_bubble.dart:256 | `chatCorrectionAccepted` | Correction accepted ✓ | — | `l10n.chatCorrectionAccepted` |
| widgets/forwarded_message_indicator.dart:46 | `chatForwarded` | Forwarded from {senderName} | senderName:Object | `l10n.chatForwarded(senderName)` |
| widgets/translation_bottom_sheet.dart:557 | `chatCached` | Cached | — | `l10n.chatCached` |
| widgets/translation_bottom_sheet.dart:571 | `chatWordBreakdown` | Word Breakdown | — | `l10n.chatWordBreakdown` |
| widgets/translation_bottom_sheet.dart:634 | `chatAlternatives` | Alternatives | — | `l10n.chatAlternatives` |
| widgets/translation_bottom_sheet.dart:692 | `grammar` | Grammar | (existing key) | `l10n.grammar` |
| widgets/translation_bottom_sheet.dart:980 | `chatTranslationAlso` | Also: {items} | items:Object | `l10n.chatTranslationAlso(widget.word.alternatives.join(', '))` |
| widgets/voice_message_player.dart:189 | `chatAudioUnavailable` | Audio unavailable | — | `l10n.chatAudioUnavailable` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L2': [
    'chatMessageFailedToSend',
    'chatSendingEllipsis',
    'chatFailedTapOptions',
    'chatMessageWasDeleted',
    'chatStory',
    'chatHi',
    'chatEdited',
    'chatPremium',
    'chatUnlockPremiumWallpapers',
    'chatWallpaperForName',
    'chatChooseGallery',
    'chatHiThere',
    'chatCorrected',
    'chatCorrectionAccepted',
    'chatForwarded',
    'chatCached',
    'chatWordBreakdown',
    'chatAlternatives',
    'chatTranslationAlso',
    'chatAudioUnavailable',
  ],
// in _filesByTask:
  'L2': [
    'pages/chat/message/bubble/bubble_actions_menu.dart',
    'pages/chat/message/message_bubble.dart',
    'pages/chat/message/message_bubble/image_message_view.dart',
    'pages/chat/message/message_bubble/story_share_message_view.dart',
    'pages/chat/message/message_bubble/text_message_view.dart',
    'pages/chat/message/message_bubble/voice_message_view.dart',
    'pages/chat/message/typing_indicator.dart',
    'pages/chat/wallpaper/wallpaper_picker_screen.dart',
    'widgets/correction_message_bubble.dart',
    'widgets/forwarded_message_indicator.dart',
    'widgets/translation_bottom_sheet.dart',
    'widgets/voice_message_player.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L2` → "app_en.arb: … missing" and 31 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/chat/message/bubble/bubble_actions_menu.dart lib/pages/chat/message/message_bubble.dart lib/pages/chat/message/message_bubble/image_message_view.dart lib/pages/chat/message/message_bubble/story_share_message_view.dart lib/pages/chat/message/message_bubble/text_message_view.dart lib/pages/chat/message/message_bubble/voice_message_view.dart lib/pages/chat/message/typing_indicator.dart lib/pages/chat/wallpaper/wallpaper_picker_screen.dart lib/widgets/correction_message_bubble.dart lib/widgets/forwarded_message_indicator.dart lib/widgets/translation_bottom_sheet.dart lib/widgets/voice_message_player.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/chat/message/bubble/bubble_actions_menu.dart lib/pages/chat/message/message_bubble.dart lib/pages/chat/message/message_bubble/image_message_view.dart lib/pages/chat/message/message_bubble/story_share_message_view.dart lib/pages/chat/message/message_bubble/text_message_view.dart lib/pages/chat/message/message_bubble/voice_message_view.dart lib/pages/chat/message/typing_indicator.dart lib/pages/chat/wallpaper/wallpaper_picker_screen.dart lib/widgets/correction_message_bubble.dart lib/widgets/forwarded_message_indicator.dart lib/widgets/translation_bottom_sheet.dart lib/widgets/voice_message_player.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 353 left**" (next: L3).
  Message: `i18n(l2): localize chat messages, bubbles, wallpaper, translation sheet` — body: "20 new keys, 31 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 353 hardcoded literals (L3..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L3: Localize Moments and reels
**Files:**
  - `lib/pages/moments/card/moment_media_carousel.dart`
  - `lib/pages/moments/create/create_moment.dart`
  - `lib/pages/moments/feed/prompt_of_day_card.dart`
  - `lib/pages/moments/reels/reel_policy_dialog.dart`
  - `lib/pages/moments/reels/reels_feed_screen.dart`
  - `lib/pages/moments/reels/reels_grid_screen.dart`
  - `lib/pages/moments/viewer/video_player_widget.dart`
  - `lib/pages/profile/moments/moment_edit.dart`
  - `lib/pages/profile/moments/moments_list.dart`
  - `lib/widgets/video_player_screen.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 15 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

24 literals in 10 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/moments/card/moment_media_carousel.dart:125 | `momentsMore` | +{hidden} more | hidden:Object | `l10n.momentsMore(hidden)` |
| pages/moments/create/create_moment.dart:905 | `ok` | OK | (existing key) | `l10n.ok` |
| pages/moments/create/create_moment.dart:1096 | `momentsAllow` | Allow | — | `l10n.momentsAllow` |
| pages/moments/create/create_moment.dart:1129 | `cancel` | Cancel | (existing key) | `l10n.cancel` |
| pages/moments/create/create_moment.dart:2333 | `momentsCompressed` | Compressed | — | `l10n.momentsCompressed` |
| pages/moments/feed/prompt_of_day_card.dart:152 | `momentsPromptDay` | Prompt of the day | — | `l10n.momentsPromptDay` |
| pages/moments/feed/prompt_of_day_card.dart:218 | `momentsAnswer` | Answer | — | `l10n.momentsAnswer` |
| pages/moments/feed/prompt_of_day_card.dart:251 | `momentsAnswerCamera` | 🎥 Answer on camera | — | `l10n.momentsAnswerCamera` |
| pages/moments/feed/prompt_of_day_card.dart:322 | `momentsPracticeWriting` | Practice writing in {langName} | langName:Object | `l10n.momentsPracticeWriting(langName)` |
| pages/moments/reels/reel_policy_dialog.dart:106 | `momentsReelPolicyBody` | Reels are short language-learning videos — prompt answers, speaking practice, native-speaker explainers, and culture clips.\n\nBananatalk has zero tolerance for objectionable content: no nudity, hate speech, harassment, violence, or illegal content. Reported videos are automatically hidden pending review after 2 reports, and violations can result in content removal or account bans.\n\nYou can report or block from any reel at any time. | — | `l10n.momentsReelPolicyBody` |
| pages/moments/reels/reel_policy_dialog.dart:129 | `momentsIAgree` | I agree | — | `l10n.momentsIAgree` |
| pages/moments/reels/reels_feed_screen.dart:538 | `momentsWhyReportingReel` | Why are you reporting this reel? | — | `l10n.momentsWhyReportingReel` |
| pages/moments/reels/reels_grid_screen.dart:498 | `momentsNoReelsYet` | No reels yet | — | `l10n.momentsNoReelsYet` |
| pages/moments/reels/reels_grid_screen.dart:505 | `momentsNoReelsBody` | Be the first to answer today's prompt on camera, or record a free-form language-learning clip. | — | `l10n.momentsNoReelsBody` |
| pages/moments/viewer/video_player_widget.dart:209 | `failedToLoadVideo` | Failed to load video | (existing key) | `l10n.failedToLoadVideo` |
| pages/moments/viewer/video_player_widget.dart:271 | `video` | Video | (existing key) | `l10n.video` |
| pages/profile/moments/moment_edit.dart:351 | `unsavedChanges` | You have unsaved changes | (existing key) | `l10n.unsavedChanges` |
| pages/profile/moments/moment_edit.dart:500 | `clear` | Clear | (existing key) | `l10n.clear` |
| pages/profile/moments/moment_edit.dart:778 | `newUser` | NEW | (existing key) | `l10n.newUser` |
| pages/profile/moments/moment_edit.dart:851 | `add` | Add | (existing key) | `l10n.add` |
| pages/profile/moments/moments_list.dart:262 | `momentsPullDownRefresh` | Pull down to refresh | — | `l10n.momentsPullDownRefresh` |
| widgets/video_player_screen.dart:81 | `momentsErrorLoadingVideo` | Error loading video | — | `l10n.momentsErrorLoadingVideo` |
| widgets/video_player_screen.dart:197 | `momentsLoadingVideo` | Loading video... | — | `l10n.momentsLoadingVideo` |
| widgets/video_player_screen.dart:215 | `failedToLoadVideo` | Failed to load video | (existing key) | `l10n.failedToLoadVideo` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L3': [
    'momentsMore',
    'momentsAllow',
    'momentsCompressed',
    'momentsPromptDay',
    'momentsAnswer',
    'momentsAnswerCamera',
    'momentsPracticeWriting',
    'momentsReelPolicyBody',
    'momentsIAgree',
    'momentsWhyReportingReel',
    'momentsNoReelsYet',
    'momentsNoReelsBody',
    'momentsPullDownRefresh',
    'momentsErrorLoadingVideo',
    'momentsLoadingVideo',
  ],
// in _filesByTask:
  'L3': [
    'pages/moments/card/moment_media_carousel.dart',
    'pages/moments/create/create_moment.dart',
    'pages/moments/feed/prompt_of_day_card.dart',
    'pages/moments/reels/reel_policy_dialog.dart',
    'pages/moments/reels/reels_feed_screen.dart',
    'pages/moments/reels/reels_grid_screen.dart',
    'pages/moments/viewer/video_player_widget.dart',
    'pages/profile/moments/moment_edit.dart',
    'pages/profile/moments/moments_list.dart',
    'widgets/video_player_screen.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L3` → "app_en.arb: … missing" and 24 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/moments/card/moment_media_carousel.dart lib/pages/moments/create/create_moment.dart lib/pages/moments/feed/prompt_of_day_card.dart lib/pages/moments/reels/reel_policy_dialog.dart lib/pages/moments/reels/reels_feed_screen.dart lib/pages/moments/reels/reels_grid_screen.dart lib/pages/moments/viewer/video_player_widget.dart lib/pages/profile/moments/moment_edit.dart lib/pages/profile/moments/moments_list.dart lib/widgets/video_player_screen.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/moments/card/moment_media_carousel.dart lib/pages/moments/create/create_moment.dart lib/pages/moments/feed/prompt_of_day_card.dart lib/pages/moments/reels/reel_policy_dialog.dart lib/pages/moments/reels/reels_feed_screen.dart lib/pages/moments/reels/reels_grid_screen.dart lib/pages/moments/viewer/video_player_widget.dart lib/pages/profile/moments/moment_edit.dart lib/pages/profile/moments/moments_list.dart lib/widgets/video_player_screen.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 329 left**" (next: L4).
  Message: `i18n(l3): localize moments and reels` — body: "15 new keys, 24 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 329 hardcoded literals (L4..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L4: Localize Community and matching
**Files:**
  - `lib/pages/community/card/community_card_meta.dart`
  - `lib/pages/community/main/community_app_bar.dart`
  - `lib/pages/community/main/community_filter_chips.dart`
  - `lib/pages/community/main/community_main.dart`
  - `lib/pages/community/tabs/city_tab.dart`
  - `lib/pages/community/tabs/genders_tab.dart`
  - `lib/pages/community/tabs/topics_tab.dart`
  - `lib/pages/community/tabs/waves_archive_screen.dart`
  - `lib/pages/community/voice_rooms/post_room_connect_sheet.dart`
  - `lib/pages/matching/match_card_widget.dart`
  - `lib/widgets/community/partner_card.dart`
  - `lib/widgets/community/partner_list_item.dart`
  - `lib/widgets/voice_room/reaction_picker.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 15 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

25 literals in 13 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/community/card/community_card_meta.dart:84 | `following` | Following | (existing key) | `l10n.following` |
| pages/community/main/community_app_bar.dart:190 | `communityLive` | {count} live | count:Object | `l10n.communityLive(count)` |
| pages/community/main/community_filter_chips.dart:139 | `clear` | Clear | (existing key) | `l10n.clear` |
| pages/community/main/community_main.dart:632 | `communityFind` | Find | — | `l10n.communityFind` |
| pages/community/main/community_main.dart:707 | `communityFinding` | Finding @{username}... | username:Object | `l10n.communityFinding(username)` |
| pages/community/tabs/city_tab.dart:680 | `communitySeeAll` | See all | — | `l10n.communitySeeAll` |
| pages/community/tabs/genders_tab.dart:370 | `communitySeeWhoLikes` | See who likes you | — | `l10n.communitySeeWhoLikes` |
| pages/community/tabs/genders_tab.dart:378 | `communityUnlimitedBrowsingNoAds` | Unlimited browsing, no ads, priority matching | — | `l10n.communityUnlimitedBrowsingNoAds` |
| pages/community/tabs/genders_tab.dart:477 | `communityMembersCount` | {count} members | count:Object | `l10n.communityMembersCount(formatCompactCount(_femaleCount))` |
| pages/community/tabs/genders_tab.dart:545 | `communityMembersCount` | {count} members | count:Object | `l10n.communityMembersCount(formatCompactCount(_maleCount))` |
| pages/community/tabs/genders_tab.dart:824 | `newUser` | NEW | (existing key) | `l10n.newUser` |
| pages/community/tabs/topics_tab.dart:257 | `peopleInterestedInTopic` | People interested in this topic | (existing key) | `l10n.peopleInterestedInTopic` |
| pages/community/tabs/topics_tab.dart:391 | `beFirstToAddTopic` | Be the first to add this topic to your interests! | (existing key) | `l10n.beFirstToAddTopic` |
| pages/community/tabs/topics_tab.dart:458 | `communityPeopleCount` | {count} people | count:Object | `l10n.communityPeopleCount(formatCompactCount(topic.userCount))` |
| pages/community/tabs/waves_archive_screen.dart:103 | `communityFailedLoadArchivedWaves` | Failed to load archived waves | — | `l10n.communityFailedLoadArchivedWaves` |
| pages/community/voice_rooms/post_room_connect_sheet.dart:58 | `communityGreatChat` | Great chat! 🎉 | — | `l10n.communityGreatChat` |
| pages/community/voice_rooms/post_room_connect_sheet.dart:64 | `communityStayTouchPeopleJust` | Stay in touch with the people you just talked to | — | `l10n.communityStayTouchPeopleJust` |
| pages/community/voice_rooms/post_room_connect_sheet.dart:76 | `communityNotNow` | Not now | — | `l10n.communityNotNow` |
| pages/matching/match_card_widget.dart:115 | `communityPerfect` | Perfect | — | `l10n.communityPerfect` |
| pages/matching/match_card_widget.dart:138 | `communityLv` | Lv.{level} | level:Object | `l10n.communityLv(match.level)` |
| widgets/community/partner_card.dart:213 | `online` | Online | (existing key) | `l10n.online` |
| widgets/community/partner_card.dart:407 | `native` | Native | (existing key) | `l10n.native` |
| widgets/community/partner_card.dart:457 | `learning` | Learning | (existing key) | `l10n.learning` |
| widgets/community/partner_list_item.dart:437 | `newUser` | NEW | (existing key) | `l10n.newUser` |
| widgets/voice_room/reaction_picker.dart:51 | `communityReact` | React | — | `l10n.communityReact` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L4': [
    'communityLive',
    'communityFind',
    'communityFinding',
    'communitySeeAll',
    'communitySeeWhoLikes',
    'communityUnlimitedBrowsingNoAds',
    'communityMembersCount',
    'communityPeopleCount',
    'communityFailedLoadArchivedWaves',
    'communityGreatChat',
    'communityStayTouchPeopleJust',
    'communityNotNow',
    'communityPerfect',
    'communityLv',
    'communityReact',
  ],
// in _filesByTask:
  'L4': [
    'pages/community/card/community_card_meta.dart',
    'pages/community/main/community_app_bar.dart',
    'pages/community/main/community_filter_chips.dart',
    'pages/community/main/community_main.dart',
    'pages/community/tabs/city_tab.dart',
    'pages/community/tabs/genders_tab.dart',
    'pages/community/tabs/topics_tab.dart',
    'pages/community/tabs/waves_archive_screen.dart',
    'pages/community/voice_rooms/post_room_connect_sheet.dart',
    'pages/matching/match_card_widget.dart',
    'widgets/community/partner_card.dart',
    'widgets/community/partner_list_item.dart',
    'widgets/voice_room/reaction_picker.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L4` → "app_en.arb: … missing" and 25 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/community/card/community_card_meta.dart lib/pages/community/main/community_app_bar.dart lib/pages/community/main/community_filter_chips.dart lib/pages/community/main/community_main.dart lib/pages/community/tabs/city_tab.dart lib/pages/community/tabs/genders_tab.dart lib/pages/community/tabs/topics_tab.dart lib/pages/community/tabs/waves_archive_screen.dart lib/pages/community/voice_rooms/post_room_connect_sheet.dart lib/pages/matching/match_card_widget.dart lib/widgets/community/partner_card.dart lib/widgets/community/partner_list_item.dart lib/widgets/voice_room/reaction_picker.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/community/card/community_card_meta.dart lib/pages/community/main/community_app_bar.dart lib/pages/community/main/community_filter_chips.dart lib/pages/community/main/community_main.dart lib/pages/community/tabs/city_tab.dart lib/pages/community/tabs/genders_tab.dart lib/pages/community/tabs/topics_tab.dart lib/pages/community/tabs/waves_archive_screen.dart lib/pages/community/voice_rooms/post_room_connect_sheet.dart lib/pages/matching/match_card_widget.dart lib/widgets/community/partner_card.dart lib/widgets/community/partner_list_item.dart lib/widgets/voice_room/reaction_picker.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 304 left**" (next: L5).
  Message: `i18n(l4): localize community and matching` — body: "15 new keys, 25 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 304 hardcoded literals (L5..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L5: Localize Learn: lessons, vocabulary, exam study
**Files:**
  - `lib/pages/learning/exam_study/exam_picker_screen.dart`
  - `lib/pages/learning/exam_study/widgets/audio_recorder.dart`
  - `lib/pages/learning/lessons/exercises/fill_blank_widget.dart`
  - `lib/pages/learning/lessons/exercises/matching_widget.dart`
  - `lib/pages/learning/lessons/exercises/multiple_choice_widget.dart`
  - `lib/pages/learning/lessons/exercises/ordering_widget.dart`
  - `lib/pages/learning/main/sections/ai_tools_tab.dart`
  - `lib/pages/learning/main/sections/daily_practice_card.dart`
  - `lib/pages/learning/vocabulary/vocab_pack_practice_screen.dart`
  - `lib/pages/learning/vocabulary/vocab_packs_screen.dart`
  - `lib/pages/learning/vocabulary/vocabulary_add_screen.dart`
  - `lib/pages/learning/vocabulary/vocabulary_screen.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 20 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

28 literals in 12 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/learning/exam_study/exam_picker_screen.dart:126 | `vocabularyPacks` | Vocabulary Packs | (existing key) | `l10n.vocabularyPacks` |
| pages/learning/exam_study/exam_picker_screen.dart:135 | `learnThemedWordSetsBuild` | Themed word sets to build your vocabulary | — | `l10n.learnThemedWordSetsBuild` |
| pages/learning/exam_study/widgets/audio_recorder.dart:183 | `learnTapStartRecording` | Tap to start recording | — | `l10n.learnTapStartRecording` |
| pages/learning/exam_study/widgets/audio_recorder.dart:297 | `examSpeakingSubmit` | Submit recording | (existing key) | `l10n.examSpeakingSubmit` |
| pages/learning/lessons/exercises/fill_blank_widget.dart:131 | `learnWordBank` | Word Bank | — | `l10n.learnWordBank` |
| pages/learning/lessons/exercises/fill_blank_widget.dart:212 | `learnCorrectAnswer` | Correct answer: {correctAnswer} | correctAnswer:Object | `l10n.learnCorrectAnswer(widget.exercise.correctAnswer)` |
| pages/learning/lessons/exercises/matching_widget.dart:109 | `learnMatchingDataNotAvailable` | Matching data not available | — | `l10n.learnMatchingDataNotAvailable` |
| pages/learning/lessons/exercises/matching_widget.dart:114 | `learnExerciseCouldNotLoad` | This exercise could not load the matching pairs. Please try regenerating the lesson. | — | `l10n.learnExerciseCouldNotLoad` |
| pages/learning/lessons/exercises/matching_widget.dart:135 | `learnSkipExercise` | Skip Exercise | — | `l10n.learnSkipExercise` |
| pages/learning/lessons/exercises/matching_widget.dart:173 | `learnTapItemLeftThen` | Tap an item on the left, then tap its match on the right | — | `l10n.learnTapItemLeftThen` |
| pages/learning/lessons/exercises/matching_widget.dart:182 | `learnMatchedOfTotal` | {count}/{count2} matched | count:Object,count2:Object | `l10n.learnMatchedOfTotal(_matches.length, _leftItems.length)` |
| pages/learning/lessons/exercises/matching_widget.dart:429 | `learnCorrectOfTotal` | {correctCount}/{count} correct | correctCount:Object,count:Object | `l10n.learnCorrectOfTotal(_correctCount, _leftItems.length)` |
| pages/learning/lessons/exercises/multiple_choice_widget.dart:186 | `continueButton` | Continue | (existing key) | `l10n.continueButton` |
| pages/learning/lessons/exercises/ordering_widget.dart:130 | `learnDragDropReorderItems` | Drag and drop to reorder the items | — | `l10n.learnDragDropReorderItems` |
| pages/learning/lessons/exercises/ordering_widget.dart:193 | `learnCorrectOrder` | Correct order: {order} | order:Object | `l10n.learnCorrectOrder(_correctOrder.join(' → '))` |
| pages/learning/main/sections/ai_tools_tab.dart:776 | `learnWordsToReview` | {dueCount, plural, =1{1 word to review} other{{dueCount} words to review}} | dueCount:int | `l10n.learnWordsToReview(dueCount)` |
| pages/learning/main/sections/daily_practice_card.dart:42 | `aiDailyPracticeTitle` | Daily Practice | (existing key) | `l10n.aiDailyPracticeTitle` |
| pages/learning/main/sections/daily_practice_card.dart:58 | `packTranslatePrompt` | Translate this sentence | (existing key) | `l10n.packTranslatePrompt` |
| pages/learning/main/sections/daily_practice_card.dart:219 | `learnScore` | Score: {score} / 100 | score:Object | `l10n.learnScore(score)` |
| pages/learning/vocabulary/vocab_pack_practice_screen.dart:85 | `learnGotCorrect` | You got {correct} of {count} correct. | correct:Object,count:Object | `l10n.learnGotCorrect(_correct, widget.exercises.length)` |
| pages/learning/vocabulary/vocab_pack_practice_screen.dart:140 | `learnQuestionOf` | Question {number} of {total} | number:Object,total:Object | `l10n.learnQuestionOf(_index + 1, total)` |
| pages/learning/vocabulary/vocab_pack_practice_screen.dart:246 | `learnMatchEachWordIts` | Match each word to its meaning | — | `l10n.learnMatchEachWordIts` |
| pages/learning/vocabulary/vocab_packs_screen.dart:89 | `learnCouldNotLoadPacks` | Could not load packs | — | `l10n.learnCouldNotLoadPacks` |
| pages/learning/vocabulary/vocab_packs_screen.dart:236 | `learnWordsExercises` | {wordCount} words · {exerciseCount} exercises | wordCount:Object,exerciseCount:Object | `l10n.learnWordsExercises(pack.wordCount, pack.exerciseCount)` |
| pages/learning/vocabulary/vocabulary_add_screen.dart:167 | `addWord` | Add Word | (existing key) | `l10n.addWord` |
| pages/learning/vocabulary/vocabulary_add_screen.dart:180 | `save` | Save | (existing key) | `l10n.save` |
| pages/learning/vocabulary/vocabulary_add_screen.dart:244 | `learnAiAutoFill` | AI Auto-fill | — | `l10n.learnAiAutoFill` |
| pages/learning/vocabulary/vocabulary_screen.dart:59 | `vocabulary` | Vocabulary | (existing key) | `l10n.vocabulary` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L5': [
    'learnThemedWordSetsBuild',
    'learnTapStartRecording',
    'learnWordBank',
    'learnCorrectAnswer',
    'learnMatchingDataNotAvailable',
    'learnExerciseCouldNotLoad',
    'learnSkipExercise',
    'learnTapItemLeftThen',
    'learnMatchedOfTotal',
    'learnCorrectOfTotal',
    'learnDragDropReorderItems',
    'learnCorrectOrder',
    'learnWordsToReview',
    'learnScore',
    'learnGotCorrect',
    'learnQuestionOf',
    'learnMatchEachWordIts',
    'learnCouldNotLoadPacks',
    'learnWordsExercises',
    'learnAiAutoFill',
  ],
// in _filesByTask:
  'L5': [
    'pages/learning/exam_study/exam_picker_screen.dart',
    'pages/learning/exam_study/widgets/audio_recorder.dart',
    'pages/learning/lessons/exercises/fill_blank_widget.dart',
    'pages/learning/lessons/exercises/matching_widget.dart',
    'pages/learning/lessons/exercises/multiple_choice_widget.dart',
    'pages/learning/lessons/exercises/ordering_widget.dart',
    'pages/learning/main/sections/ai_tools_tab.dart',
    'pages/learning/main/sections/daily_practice_card.dart',
    'pages/learning/vocabulary/vocab_pack_practice_screen.dart',
    'pages/learning/vocabulary/vocab_packs_screen.dart',
    'pages/learning/vocabulary/vocabulary_add_screen.dart',
    'pages/learning/vocabulary/vocabulary_screen.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L5` → "app_en.arb: … missing" and 28 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/learning/exam_study/exam_picker_screen.dart lib/pages/learning/exam_study/widgets/audio_recorder.dart lib/pages/learning/lessons/exercises/fill_blank_widget.dart lib/pages/learning/lessons/exercises/matching_widget.dart lib/pages/learning/lessons/exercises/multiple_choice_widget.dart lib/pages/learning/lessons/exercises/ordering_widget.dart lib/pages/learning/main/sections/ai_tools_tab.dart lib/pages/learning/main/sections/daily_practice_card.dart lib/pages/learning/vocabulary/vocab_pack_practice_screen.dart lib/pages/learning/vocabulary/vocab_packs_screen.dart lib/pages/learning/vocabulary/vocabulary_add_screen.dart lib/pages/learning/vocabulary/vocabulary_screen.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/learning/exam_study/exam_picker_screen.dart lib/pages/learning/exam_study/widgets/audio_recorder.dart lib/pages/learning/lessons/exercises/fill_blank_widget.dart lib/pages/learning/lessons/exercises/matching_widget.dart lib/pages/learning/lessons/exercises/multiple_choice_widget.dart lib/pages/learning/lessons/exercises/ordering_widget.dart lib/pages/learning/main/sections/ai_tools_tab.dart lib/pages/learning/main/sections/daily_practice_card.dart lib/pages/learning/vocabulary/vocab_pack_practice_screen.dart lib/pages/learning/vocabulary/vocab_packs_screen.dart lib/pages/learning/vocabulary/vocabulary_add_screen.dart lib/pages/learning/vocabulary/vocabulary_screen.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 276 left**" (next: L6).
  Message: `i18n(l5): localize learn: lessons, vocabulary, exam study` — body: "20 new keys, 28 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 276 hardcoded literals (L6..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L6: Localize Learn: achievements, challenges, progress widgets
**Files:**
  - `lib/pages/learning/achievements/achievements_screen.dart`
  - `lib/pages/learning/challenges/challenges_screen.dart`
  - `lib/widgets/learning/achievement_card.dart`
  - `lib/widgets/learning/challenge_card.dart`
  - `lib/widgets/learning/daily_goal_widget.dart`
  - `lib/widgets/learning/lesson_card.dart`
  - `lib/widgets/learning/streak_widget.dart`
  - `lib/widgets/learning/vocabulary_card.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 19 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

20 literals in 8 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/learning/achievements/achievements_screen.dart:42 | `achievements` | Achievements | (existing key) | `l10n.achievements` |
| pages/learning/achievements/achievements_screen.dart:137 | `learnFailedLoadAchievements` | Failed to load achievements | — | `l10n.learnFailedLoadAchievements` |
| pages/learning/achievements/achievements_screen.dart:368 | `learnUnlockedOn` | Unlocked on {date} | date:Object | `l10n.learnUnlockedOn(_formatDate(achievement.unlockedAt!))` |
| pages/learning/challenges/challenges_screen.dart:43 | `learnChallenges` | Challenges | — | `l10n.learnChallenges` |
| pages/learning/challenges/challenges_screen.dart:118 | `learnFailedLoadChallenges` | Failed to load challenges | — | `l10n.learnFailedLoadChallenges` |
| pages/learning/challenges/challenges_screen.dart:235 | `learnNoChallenges` | No {type} Challenges | type:Object | `l10n.learnNoChallenges(type)` |
| pages/learning/challenges/challenges_screen.dart:244 | `learnCheckBackLater` | Check back later! | — | `l10n.learnCheckBackLater` |
| pages/learning/challenges/challenges_screen.dart:302 | `learnActiveCount` | Active ({count}) | count:Object | `l10n.learnActiveCount(active.length)` |
| pages/learning/challenges/challenges_screen.dart:331 | `learnCompletedCount` | Completed ({count}) | count:Object | `l10n.learnCompletedCount(completed.length)` |
| pages/learning/challenges/challenges_screen.dart:426 | `learnProgress` | Progress | — | `l10n.learnProgress` |
| pages/learning/challenges/challenges_screen.dart:494 | `learnXpReward` | XP Reward | — | `l10n.learnXpReward` |
| pages/learning/challenges/challenges_screen.dart:540 | `learnBonus` | Bonus | — | `l10n.learnBonus` |
| pages/learning/challenges/challenges_screen.dart:570 | `learnExpires` | Expires in {timeRemainingFormatted} | timeRemainingFormatted:Object | `l10n.learnExpires(challenge.timeRemainingFormatted)` |
| widgets/learning/achievement_card.dart:303 | `learnAchievementUnlocked` | Achievement Unlocked! | — | `l10n.learnAchievementUnlocked` |
| widgets/learning/achievement_card.dart:369 | `learnTapContinue` | Tap to continue | — | `l10n.learnTapContinue` |
| widgets/learning/challenge_card.dart:153 | `learnChallengeCompleted` | Completed | — | `l10n.learnChallengeCompleted` |
| widgets/learning/daily_goal_widget.dart:33 | `learnDailyGoals` | Daily Goals | — | `l10n.learnDailyGoals` |
| widgets/learning/lesson_card.dart:323 | `learnLessons` | {completedCount}/{lessonsCount} lessons | completedCount:Object,lessonsCount:Object | `l10n.learnLessons(unit.completedCount, unit.lessonsCount)` |
| widgets/learning/streak_widget.dart:114 | `learnLongestDays` | Longest: {longestStreak} days | longestStreak:Object | `l10n.learnLongestDays(longestStreak)` |
| widgets/learning/vocabulary_card.dart:319 | `learnTapReveal` | Tap to reveal | — | `l10n.learnTapReveal` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L6': [
    'learnFailedLoadAchievements',
    'learnUnlockedOn',
    'learnChallenges',
    'learnFailedLoadChallenges',
    'learnNoChallenges',
    'learnCheckBackLater',
    'learnActiveCount',
    'learnCompletedCount',
    'learnProgress',
    'learnXpReward',
    'learnBonus',
    'learnExpires',
    'learnAchievementUnlocked',
    'learnTapContinue',
    'learnChallengeCompleted',
    'learnDailyGoals',
    'learnLessons',
    'learnLongestDays',
    'learnTapReveal',
  ],
// in _filesByTask:
  'L6': [
    'pages/learning/achievements/achievements_screen.dart',
    'pages/learning/challenges/challenges_screen.dart',
    'widgets/learning/achievement_card.dart',
    'widgets/learning/challenge_card.dart',
    'widgets/learning/daily_goal_widget.dart',
    'widgets/learning/lesson_card.dart',
    'widgets/learning/streak_widget.dart',
    'widgets/learning/vocabulary_card.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L6` → "app_en.arb: … missing" and 20 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/learning/achievements/achievements_screen.dart lib/pages/learning/challenges/challenges_screen.dart lib/widgets/learning/achievement_card.dart lib/widgets/learning/challenge_card.dart lib/widgets/learning/daily_goal_widget.dart lib/widgets/learning/lesson_card.dart lib/widgets/learning/streak_widget.dart lib/widgets/learning/vocabulary_card.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/learning/achievements/achievements_screen.dart lib/pages/learning/challenges/challenges_screen.dart lib/widgets/learning/achievement_card.dart lib/widgets/learning/challenge_card.dart lib/widgets/learning/daily_goal_widget.dart lib/widgets/learning/lesson_card.dart lib/widgets/learning/streak_widget.dart lib/widgets/learning/vocabulary_card.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 256 left**" (next: L7).
  Message: `i18n(l6): localize learn: achievements, challenges, progress widgets` — body: "19 new keys, 20 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 256 hardcoded literals (L7..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L7: Localize AI Study: quizzes, tutor, lesson sheets
**Files:**
  - `lib/pages/ai/quiz/ai_quiz_screen.dart`
  - `lib/pages/ai/quiz/quiz_player_screen.dart`
  - `lib/pages/ai/tutor/tutor_chat_screen.dart`
  - `lib/widgets/ai/answer_feedback_sheet.dart`
  - `lib/widgets/ai/lesson_assistant_widget.dart`
  - `lib/widgets/ai/lesson_summary_sheet.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 36 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

49 literals in 6 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/ai/quiz/ai_quiz_screen.dart:201 | `aiQuizzes` | AI Quizzes | (existing key) | `l10n.aiQuizzes` |
| pages/ai/quiz/ai_quiz_screen.dart:226 | `aiGenerateNewQuiz` | Generate New Quiz | — | `l10n.aiGenerateNewQuiz` |
| pages/ai/quiz/ai_quiz_screen.dart:235 | `aiPreviousQuizzes` | Previous Quizzes | — | `l10n.aiPreviousQuizzes` |
| pages/ai/quiz/ai_quiz_screen.dart:270 | `aiGeneratingQuiz` | Generating your quiz… | — | `l10n.aiGeneratingQuiz` |
| pages/ai/quiz/ai_quiz_screen.dart:394 | `aiFocusArea` | Focus area: {name} | name:Object | `l10n.aiFocusArea(stats.weakAreas.first.name)` |
| pages/ai/quiz/ai_quiz_screen.dart:443 | `aiQuizType` | Quiz Type | — | `l10n.aiQuizType` |
| pages/ai/quiz/ai_quiz_screen.dart:506 | `language` | Language | (existing key) | `l10n.language` |
| pages/ai/quiz/ai_quiz_screen.dart:515 | `aiDifficulty` | Difficulty | — | `l10n.aiDifficulty` |
| pages/ai/quiz/ai_quiz_screen.dart:559 | `aiQuestionsLabel` | Questions: | — | `l10n.aiQuestionsLabel` |
| pages/ai/quiz/ai_quiz_screen.dart:611 | `aiGenerateQuiz` | Generate Quiz | — | `l10n.aiGenerateQuiz` |
| pages/ai/quiz/ai_quiz_screen.dart:644 | `loadingLanguages` | Loading languages... | (existing key) | `l10n.loadingLanguages` |
| pages/ai/quiz/ai_quiz_screen.dart:691 | `selectALanguage` | Select a language | (existing key) | `l10n.selectALanguage` |
| pages/ai/quiz/ai_quiz_screen.dart:752 | `aiQuizQuestionCount` | {questionCount, plural, =1{1 question} other{{questionCount} questions}} | questionCount:int | `l10n.aiQuizQuestionCount(quiz.questionCount)` |
| pages/ai/quiz/ai_quiz_screen.dart:899 | `aiCorrectOfTotal` | {correctCount}/{totalQuestions} correct | correctCount:Object,totalQuestions:Object | `l10n.aiCorrectOfTotal(result.correctCount, result.totalQuestions)` |
| pages/ai/quiz/ai_quiz_screen.dart:1023 | `aiNoQuizzesYet` | No quizzes yet | — | `l10n.aiNoQuizzesYet` |
| pages/ai/quiz/ai_quiz_screen.dart:1028 | `aiGenerateFirstQuizAbove` | Generate your first quiz above! | — | `l10n.aiGenerateFirstQuizAbove` |
| pages/ai/quiz/quiz_player_screen.dart:166 | `aiCorrectOutOf` | {correctCount} out of {totalQuestions} correct | correctCount:Object,totalQuestions:Object | `l10n.aiCorrectOutOf(result.correctCount, result.totalQuestions)` |
| pages/ai/quiz/quiz_player_screen.dart:230 | `vocabBonusEarned` | +10 Bonus XP earned! 🎉 | (existing key) | `l10n.vocabBonusEarned` |
| pages/ai/quiz/quiz_player_screen.dart:253 | `aiBackQuizHub` | Back to Quiz Hub | — | `l10n.aiBackQuizHub` |
| pages/ai/quiz/quiz_player_screen.dart:314 | `aiNoQuestionsAvailable` | No questions available | — | `l10n.aiNoQuestionsAvailable` |
| pages/ai/quiz/quiz_player_screen.dart:319 | `aiQuizHasNoQuestions` | This quiz has no questions to display. | — | `l10n.aiQuizHasNoQuestions` |
| pages/ai/quiz/quiz_player_screen.dart:401 | `aiQuestionOf` | Question {number} of {count} | number:Object,count:Object | `l10n.aiQuestionOf(state.currentIndex + 1, quiz.questions.length)` |
| pages/ai/quiz/quiz_player_screen.dart:745 | `aiYourAnswerLabel` | Your answer: | — | `l10n.aiYourAnswerLabel` |
| pages/ai/quiz/quiz_player_screen.dart:857 | `lessonYourTranslation` | Your translation: | (existing key) | `l10n.lessonYourTranslation` |
| pages/ai/tutor/tutor_chat_screen.dart:101 | `aiBonusXpWatching` | 🎉 +10 Bonus XP for watching! | — | `l10n.aiBonusXpWatching` |
| widgets/ai/answer_feedback_sheet.dart:164 | `aiNotQuiteRight` | Not quite right | — | `l10n.aiNotQuiteRight` |
| widgets/ai/answer_feedback_sheet.dart:199 | `examVocabQuizYourAnswer` | Your answer | (existing key) | `l10n.examVocabQuizYourAnswer` |
| widgets/ai/answer_feedback_sheet.dart:230 | `examVocabQuizCorrectAnswer` | Correct answer | (existing key) | `l10n.examVocabQuizCorrectAnswer` |
| widgets/ai/answer_feedback_sheet.dart:256 | `aiWhy` | Why? | — | `l10n.aiWhy` |
| widgets/ai/answer_feedback_sheet.dart:301 | `examQuestionExplanation` | Explanation | (existing key) | `l10n.examQuestionExplanation` |
| widgets/ai/answer_feedback_sheet.dart:374 | `aiGotIt` | Got It | — | `l10n.aiGotIt` |
| widgets/ai/lesson_assistant_widget.dart:129 | `aiHint` | Hint | — | `l10n.aiHint` |
| widgets/ai/lesson_assistant_widget.dart:136 | `aiLevel` | Level {hintLevel}/3 | hintLevel:Object | `l10n.aiLevel(hint.hintLevel)` |
| widgets/ai/lesson_assistant_widget.dart:214 | `aiAskQuestion` | Ask a Question | — | `l10n.aiAskQuestion` |
| widgets/ai/lesson_assistant_widget.dart:248 | `aiAsk` | Ask | — | `l10n.aiAsk` |
| widgets/ai/lesson_assistant_widget.dart:362 | `aiAssistantExamples` | Examples | — | `l10n.aiAssistantExamples` |
| widgets/ai/lesson_assistant_widget.dart:469 | `aiExplainConcept` | Explain Concept | — | `l10n.aiExplainConcept` |
| widgets/ai/lesson_assistant_widget.dart:583 | `aiAssistantExamples` | Examples | — | `l10n.aiAssistantExamples` |
| widgets/ai/lesson_assistant_widget.dart:643 | `aiRelatedConcepts` | Related Concepts | — | `l10n.aiRelatedConcepts` |
| widgets/ai/lesson_summary_sheet.dart:94 | `aiGeneratingLessonSummary` | Generating your lesson summary... | — | `l10n.aiGeneratingLessonSummary` |
| widgets/ai/lesson_summary_sheet.dart:123 | `skip` | Skip | (existing key) | `l10n.skip` |
| widgets/ai/lesson_summary_sheet.dart:171 | `aiLessonSummary` | Lesson Summary | — | `l10n.aiLessonSummary` |
| widgets/ai/lesson_summary_sheet.dart:187 | `aiKeyPoints` | Key Points | — | `l10n.aiKeyPoints` |
| widgets/ai/lesson_summary_sheet.dart:229 | `aiVocabularyRemember` | Vocabulary to Remember | — | `l10n.aiVocabularyRemember` |
| widgets/ai/lesson_summary_sheet.dart:287 | `aiGrammarRules` | Grammar Rules | — | `l10n.aiGrammarRules` |
| widgets/ai/lesson_summary_sheet.dart:346 | `aiWhatPracticeNext` | What to Practice Next | — | `l10n.aiWhatPracticeNext` |
| widgets/ai/lesson_summary_sheet.dart:388 | `vocabBonusEarned` | +10 Bonus XP earned! 🎉 | (existing key) | `l10n.vocabBonusEarned` |
| widgets/ai/lesson_summary_sheet.dart:406 | `continueButton` | Continue | (existing key) | `l10n.continueButton` |
| widgets/ai/lesson_summary_sheet.dart:443 | `aiPerfectScore` | Perfect Score! | — | `l10n.aiPerfectScore` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L7': [
    'aiGenerateNewQuiz',
    'aiPreviousQuizzes',
    'aiGeneratingQuiz',
    'aiFocusArea',
    'aiQuizType',
    'aiDifficulty',
    'aiQuestionsLabel',
    'aiGenerateQuiz',
    'aiQuizQuestionCount',
    'aiCorrectOfTotal',
    'aiNoQuizzesYet',
    'aiGenerateFirstQuizAbove',
    'aiCorrectOutOf',
    'aiBackQuizHub',
    'aiNoQuestionsAvailable',
    'aiQuizHasNoQuestions',
    'aiQuestionOf',
    'aiYourAnswerLabel',
    'aiBonusXpWatching',
    'aiNotQuiteRight',
    'aiWhy',
    'aiGotIt',
    'aiHint',
    'aiLevel',
    'aiAskQuestion',
    'aiAsk',
    'aiAssistantExamples',
    'aiExplainConcept',
    'aiRelatedConcepts',
    'aiGeneratingLessonSummary',
    'aiLessonSummary',
    'aiKeyPoints',
    'aiVocabularyRemember',
    'aiGrammarRules',
    'aiWhatPracticeNext',
    'aiPerfectScore',
  ],
// in _filesByTask:
  'L7': [
    'pages/ai/quiz/ai_quiz_screen.dart',
    'pages/ai/quiz/quiz_player_screen.dart',
    'pages/ai/tutor/tutor_chat_screen.dart',
    'widgets/ai/answer_feedback_sheet.dart',
    'widgets/ai/lesson_assistant_widget.dart',
    'widgets/ai/lesson_summary_sheet.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L7` → "app_en.arb: … missing" and 49 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/ai/quiz/ai_quiz_screen.dart lib/pages/ai/quiz/quiz_player_screen.dart lib/pages/ai/tutor/tutor_chat_screen.dart lib/widgets/ai/answer_feedback_sheet.dart lib/widgets/ai/lesson_assistant_widget.dart lib/widgets/ai/lesson_summary_sheet.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/ai/quiz/ai_quiz_screen.dart lib/pages/ai/quiz/quiz_player_screen.dart lib/pages/ai/tutor/tutor_chat_screen.dart lib/widgets/ai/answer_feedback_sheet.dart lib/widgets/ai/lesson_assistant_widget.dart lib/widgets/ai/lesson_summary_sheet.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 207 left**" (next: L8).
  Message: `i18n(l7): localize ai study: quizzes, tutor, lesson sheets` — body: "36 new keys, 49 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 207 hardcoded literals (L8..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L8: Localize AI Study: conversation, grammar, lesson builder, pronunciation, translation
**Files:**
  - `lib/pages/ai/conversation/conversation_history_screen.dart`
  - `lib/pages/ai/conversation/topic_selection_sheet.dart`
  - `lib/pages/ai/grammar/grammar_feedback_screen.dart`
  - `lib/pages/ai/lesson_builder/lesson_builder_screen.dart`
  - `lib/pages/ai/pronunciation/pronunciation_screen.dart`
  - `lib/pages/ai/translation/translation_screen.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 44 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

57 literals in 6 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/ai/conversation/conversation_history_screen.dart:119 | `aiFailedLoadHistory` | Failed to load history | — | `l10n.aiFailedLoadHistory` |
| pages/ai/conversation/conversation_history_screen.dart:245 | `aiConversationMessageCount` | {count, plural, =1{1 message} other{{count} messages}} | count:int | `l10n.aiConversationMessageCount(conversation.messages.length)` |
| pages/ai/conversation/conversation_history_screen.dart:298 | `aiStartNewConversationSee` | Start a new conversation to see it here | — | `l10n.aiStartNewConversationSee` |
| pages/ai/conversation/conversation_history_screen.dart:405 | `conversation` | Conversation | (existing key) | `l10n.conversation` |
| pages/ai/conversation/conversation_history_screen.dart:435 | `aiLoadingMessages` | Loading messages... | — | `l10n.aiLoadingMessages` |
| pages/ai/conversation/conversation_history_screen.dart:478 | `aiNoMessagesConversation` | No messages in this conversation | — | `l10n.aiNoMessagesConversation` |
| pages/ai/conversation/topic_selection_sheet.dart:155 | `startConversation` | Start Conversation | (existing key) | `l10n.startConversation` |
| pages/ai/conversation/topic_selection_sheet.dart:172 | `aiDifficultyLevel` | Difficulty Level | — | `l10n.aiDifficultyLevel` |
| pages/ai/conversation/topic_selection_sheet.dart:244 | `topics` | Topics | (existing key) | `l10n.topics` |
| pages/ai/conversation/topic_selection_sheet.dart:269 | `aiScenarios` | Scenarios | — | `l10n.aiScenarios` |
| pages/ai/conversation/topic_selection_sheet.dart:360 | `languages` | Languages | (existing key) | `l10n.languages` |
| pages/ai/grammar/grammar_feedback_screen.dart:174 | `aiGrammarCheck` | Grammar Check | — | `l10n.aiGrammarCheck` |
| pages/ai/grammar/grammar_feedback_screen.dart:235 | `aiRecentAnalysis` | Recent Analysis | — | `l10n.aiRecentAnalysis` |
| pages/ai/grammar/grammar_feedback_screen.dart:325 | `aiCheckGrammar` | Check Grammar | — | `l10n.aiCheckGrammar` |
| pages/ai/grammar/grammar_feedback_screen.dart:343 | `aiLanguageLabel` | Language: | — | `l10n.aiLanguageLabel` |
| pages/ai/grammar/grammar_feedback_screen.dart:370 | `aiLanguageLabel` | Language: | — | `l10n.aiLanguageLabel` |
| pages/ai/grammar/grammar_feedback_screen.dart:476 | `aiGrammarIssuesFound` | {count, plural, =1{1 issue found} other{{count} issues found}} | count:int | `l10n.aiGrammarIssuesFound(_feedback!.errorCount)` |
| pages/ai/grammar/grammar_feedback_screen.dart:529 | `aiPerfect` | Perfect! | — | `l10n.aiPerfect` |
| pages/ai/grammar/grammar_feedback_screen.dart:537 | `aiNoGrammarIssuesFound` | No grammar issues found in your text. | — | `l10n.aiNoGrammarIssuesFound` |
| pages/ai/grammar/grammar_feedback_screen.dart:573 | `aiGrammarSectionWell` | What You Did Well | (existing key) | `l10n.aiGrammarSectionWell` |
| pages/ai/grammar/grammar_feedback_screen.dart:630 | `aiIssuesFound` | Issues Found ({count}) | count:Object | `l10n.aiIssuesFound(_feedback!.errors.length)` |
| pages/ai/grammar/grammar_feedback_screen.dart:724 | `correctionOriginal` | Original | (existing key) | `l10n.correctionOriginal` |
| pages/ai/grammar/grammar_feedback_screen.dart:764 | `aiCorrected` | Corrected | — | `l10n.aiCorrected` |
| pages/ai/grammar/grammar_feedback_screen.dart:813 | `aiWhy` | Why? | — | `l10n.aiWhy` |
| pages/ai/grammar/grammar_feedback_screen.dart:855 | `aiGrammarExamples` | Examples: | — | `l10n.aiGrammarExamples` |
| pages/ai/grammar/grammar_feedback_screen.dart:916 | `aiGrammarSectionCorrected` | Corrected Text | (existing key) | `l10n.aiGrammarSectionCorrected` |
| pages/ai/grammar/grammar_feedback_screen.dart:973 | `aiImprovedSuggestions` | Improved Suggestions | — | `l10n.aiImprovedSuggestions` |
| pages/ai/grammar/grammar_feedback_screen.dart:1054 | `aiGrammarSectionSummary` | Summary | (existing key) | `l10n.aiGrammarSectionSummary` |
| pages/ai/grammar/grammar_feedback_screen.dart:1245 | `aiGrammarIssuesFound` | {count, plural, =1{1 issue found} other{{count} issues found}} | count:int | `l10n.aiGrammarIssuesFound(feedback.errorCount)` |
| pages/ai/grammar/grammar_feedback_screen.dart:1489 | `aiNoAnalysisHistoryYet` | No analysis history yet | — | `l10n.aiNoAnalysisHistoryYet` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:166 | `aiLessonBuilder` | AI Lesson Builder | — | `l10n.aiLessonBuilder` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:249 | `aiGenerateCustomLessons` | Generate Custom Lessons | — | `l10n.aiGenerateCustomLessons` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:258 | `aiCreatesPersonalizedLessonsAny` | AI creates personalized lessons on any topic | — | `l10n.aiCreatesPersonalizedLessonsAny` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:331 | `category` | Category | (existing key) | `l10n.category` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:402 | `aiExercises` | Exercises: {exerciseCount} | exerciseCount:Object | `l10n.aiExercises(_exerciseCount)` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:504 | `aiSuggestedTopics` | Suggested Topics | — | `l10n.aiSuggestedTopics` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:594 | `aiCreatingLesson` | Creating your lesson... | — | `l10n.aiCreatingLesson` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:599 | `aiGeneratingExercisesContent` | AI is generating exercises and content | — | `l10n.aiGeneratingExercisesContent` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:661 | `aiLessonGenerated` | Lesson Generated! | — | `l10n.aiLessonGenerated` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:739 | `aiGenerateAnother` | Generate Another | — | `l10n.aiGenerateAnother` |
| pages/ai/lesson_builder/lesson_builder_screen.dart:760 | `aiStartLesson` | Start Lesson | — | `l10n.aiStartLesson` |
| pages/ai/pronunciation/pronunciation_screen.dart:160 | `loadingLanguages` | Loading languages... | (existing key) | `l10n.loadingLanguages` |
| pages/ai/pronunciation/pronunciation_screen.dart:396 | `aiPronunciationPractice` | Pronunciation Practice | — | `l10n.aiPronunciationPractice` |
| pages/ai/pronunciation/pronunciation_screen.dart:427 | `aiPracticeHistory` | Practice History | — | `l10n.aiPracticeHistory` |
| pages/ai/pronunciation/pronunciation_screen.dart:528 | `aiTextPractice` | Text to Practice | — | `l10n.aiTextPractice` |
| pages/ai/pronunciation/pronunciation_screen.dart:764 | `aiWordAnalysis` | Word Analysis | — | `l10n.aiWordAnalysis` |
| pages/ai/pronunciation/pronunciation_screen.dart:1000 | `aiNoPracticeHistoryYet` | No practice history yet | — | `l10n.aiNoPracticeHistoryYet` |
| pages/ai/translation/translation_screen.dart:202 | `aiSmartTranslation` | Smart Translation | — | `l10n.aiSmartTranslation` |
| pages/ai/translation/translation_screen.dart:406 | `translate` | Translate | (existing key) | `l10n.translate` |
| pages/ai/translation/translation_screen.dart:521 | `aiWordBreakdown` | Word Breakdown | — | `l10n.aiWordBreakdown` |
| pages/ai/translation/translation_screen.dart:609 | `aiAlternativeTranslations` | Alternative Translations | — | `l10n.aiAlternativeTranslations` |
| pages/ai/translation/translation_screen.dart:696 | `aiGrammarNotes` | Grammar Notes | — | `l10n.aiGrammarNotes` |
| pages/ai/translation/translation_screen.dart:777 | `aiIdiomsExpressions` | Idioms & Expressions | — | `l10n.aiIdiomsExpressions` |
| pages/ai/translation/translation_screen.dart:803 | `aiLiteral` | Literal: {literalTranslation} | literalTranslation:Object | `l10n.aiLiteral(idiom.literalTranslation)` |
| pages/ai/translation/translation_screen.dart:808 | `aiMeaning` | Meaning: {meaning} | meaning:Object | `l10n.aiMeaning(idiom.meaning)` |
| pages/ai/translation/translation_screen.dart:823 | `aiEquivalent` | Equivalent: {equivalentIdiom} | equivalentIdiom:Object | `l10n.aiEquivalent(idiom.equivalentIdiom)` |
| pages/ai/translation/translation_screen.dart:857 | `aiCulturalContext` | Cultural Context | — | `l10n.aiCulturalContext` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L8': [
    'aiFailedLoadHistory',
    'aiConversationMessageCount',
    'aiStartNewConversationSee',
    'aiLoadingMessages',
    'aiNoMessagesConversation',
    'aiDifficultyLevel',
    'aiScenarios',
    'aiGrammarCheck',
    'aiRecentAnalysis',
    'aiCheckGrammar',
    'aiLanguageLabel',
    'aiGrammarIssuesFound',
    'aiPerfect',
    'aiNoGrammarIssuesFound',
    'aiIssuesFound',
    'aiCorrected',
    'aiWhy',
    'aiGrammarExamples',
    'aiImprovedSuggestions',
    'aiNoAnalysisHistoryYet',
    'aiLessonBuilder',
    'aiGenerateCustomLessons',
    'aiCreatesPersonalizedLessonsAny',
    'aiExercises',
    'aiSuggestedTopics',
    'aiCreatingLesson',
    'aiGeneratingExercisesContent',
    'aiLessonGenerated',
    'aiGenerateAnother',
    'aiStartLesson',
    'aiPronunciationPractice',
    'aiPracticeHistory',
    'aiTextPractice',
    'aiWordAnalysis',
    'aiNoPracticeHistoryYet',
    'aiSmartTranslation',
    'aiWordBreakdown',
    'aiAlternativeTranslations',
    'aiGrammarNotes',
    'aiIdiomsExpressions',
    'aiLiteral',
    'aiMeaning',
    'aiEquivalent',
    'aiCulturalContext',
  ],
// in _filesByTask:
  'L8': [
    'pages/ai/conversation/conversation_history_screen.dart',
    'pages/ai/conversation/topic_selection_sheet.dart',
    'pages/ai/grammar/grammar_feedback_screen.dart',
    'pages/ai/lesson_builder/lesson_builder_screen.dart',
    'pages/ai/pronunciation/pronunciation_screen.dart',
    'pages/ai/translation/translation_screen.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L8` → "app_en.arb: … missing" and 57 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/ai/conversation/conversation_history_screen.dart lib/pages/ai/conversation/topic_selection_sheet.dart lib/pages/ai/grammar/grammar_feedback_screen.dart lib/pages/ai/lesson_builder/lesson_builder_screen.dart lib/pages/ai/pronunciation/pronunciation_screen.dart lib/pages/ai/translation/translation_screen.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/ai/conversation/conversation_history_screen.dart lib/pages/ai/conversation/topic_selection_sheet.dart lib/pages/ai/grammar/grammar_feedback_screen.dart lib/pages/ai/lesson_builder/lesson_builder_screen.dart lib/pages/ai/pronunciation/pronunciation_screen.dart lib/pages/ai/translation/translation_screen.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 150 left**" (next: L9).
  Message: `i18n(l8): localize ai study: conversation, grammar, lesson builder, pronunciation, translation` — body: "44 new keys, 57 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 150 hardcoded literals (L9..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L9: Localize Notifications, profile, settings, reports
**Files:**
  - `lib/pages/menu_tab/TabBarMenu.dart`
  - `lib/pages/notifications/notification_history_screen.dart`
  - `lib/pages/notifications/notification_settings_screen.dart`
  - `lib/pages/profile/drawer/drawer_section.dart`
  - `lib/pages/profile/edit/language_edit.dart`
  - `lib/pages/profile/edit/picture_edit/photo_grid_tile.dart`
  - `lib/pages/profile/edit/privacy_edit.dart`
  - `lib/pages/profile/edit/topics_edit.dart`
  - `lib/pages/profile/profile_main.dart`
  - `lib/pages/profile/profile_main/sections/profile_about_tab.dart`
  - `lib/pages/profile/profile_main/sections/profile_highlights_tab.dart`
  - `lib/pages/profile/settings.dart`
  - `lib/pages/profile/theme.dart`
  - `lib/pages/profile/visitors_screen.dart`
  - `lib/pages/reports/my_reports_screen.dart`
  - `lib/pages/settings/account_deletion.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 25 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

33 literals in 16 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/menu_tab/TabBarMenu.dart:640 | `profileBuyMeCoffee` | Buy me a coffee | — | `l10n.profileBuyMeCoffee` |
| pages/menu_tab/TabBarMenu.dart:858 | `profileOr` | or | — | `l10n.profileOr` |
| pages/notifications/notification_history_screen.dart:380 | `profileLoadingNotifications` | Loading notifications... | — | `l10n.profileLoadingNotifications` |
| pages/notifications/notification_history_screen.dart:627 | `delete` | Delete | (existing key) | `l10n.delete` |
| pages/notifications/notification_settings_screen.dart:931 | `profileLoadingSettings` | Loading settings... | — | `l10n.profileLoadingSettings` |
| pages/profile/drawer/drawer_section.dart:179 | `profileAdmin` | ADMIN | — | `l10n.profileAdmin` |
| pages/profile/edit/language_edit.dart:419 | `profileSelected` | SELECTED | — | `l10n.profileSelected` |
| pages/profile/edit/picture_edit/photo_grid_tile.dart:221 | `newUser` | NEW | (existing key) | `l10n.newUser` |
| pages/profile/edit/privacy_edit.dart:446 | `unsavedChanges` | You have unsaved changes | (existing key) | `l10n.unsavedChanges` |
| pages/profile/edit/privacy_edit.dart:497 | `profilePrivacyIntro` | You control what others can see. Toggle items off to hide them from your public profile. | — | `l10n.profilePrivacyIntro` |
| pages/profile/edit/privacy_edit.dart:787 | `profileUpdate` | Update | — | `l10n.profileUpdate` |
| pages/profile/edit/topics_edit.dart:435 | `profileNoTopicsCategory` | No topics in this category | — | `l10n.profileNoTopicsCategory` |
| pages/profile/profile_main.dart:403 | `profileAdminTools` | Admin Tools | — | `l10n.profileAdminTools` |
| pages/profile/profile_main/sections/profile_about_tab.dart:259 | `native` | Native | (existing key) | `l10n.native` |
| pages/profile/profile_main/sections/profile_highlights_tab.dart:123 | `profileCompletion` | Profile Completion | (existing key) | `l10n.profileCompletion` |
| pages/profile/profile_main/sections/profile_highlights_tab.dart:173 | `profileCompletionAdd` | Add: {items} | items:Object | `l10n.profileCompletionAdd(missing.join(', '))` |
| pages/profile/profile_main/sections/profile_highlights_tab.dart:294 | `profileActive` | ACTIVE | — | `l10n.profileActive` |
| pages/profile/settings.dart:381 | `profileLoadingSettings` | Loading settings... | — | `l10n.profileLoadingSettings` |
| pages/profile/settings.dart:415 | `somethingWentWrong` | Something went wrong | (existing key) | `l10n.somethingWentWrong` |
| pages/profile/settings.dart:777 | `profileAutoSaveEnabled` | Auto-save enabled | — | `l10n.profileAutoSaveEnabled` |
| pages/profile/settings.dart:785 | `profileChangesSavedInstantlyWhen` | Changes are saved instantly when you toggle. | — | `l10n.profileChangesSavedInstantlyWhen` |
| pages/profile/settings.dart:1088 | `profileUpdate` | Update | — | `l10n.profileUpdate` |
| pages/profile/theme.dart:178 | `profileCurrentTheme` | Current theme | — | `l10n.profileCurrentTheme` |
| pages/profile/theme.dart:629 | `profileThemeChangesApplyInstantly` | Theme changes apply instantly across the entire app. | — | `l10n.profileThemeChangesApplyInstantly` |
| pages/profile/visitors_screen.dart:157 | `profileLoadingVisitors` | Loading visitors... | — | `l10n.profileLoadingVisitors` |
| pages/profile/visitors_screen.dart:427 | `momentsPullDownRefresh` | Pull down to refresh | — | `l10n.momentsPullDownRefresh` |
| pages/profile/visitors_screen.dart:502 | `profileSeeWhoChecked` | See who checked your profile | — | `l10n.profileSeeWhoChecked` |
| pages/profile/visitors_screen.dart:630 | `profileRecentVisitors` | Recent Visitors | — | `l10n.profileRecentVisitors` |
| pages/reports/my_reports_screen.dart:163 | `profileNoReportsSubmitted` | No reports submitted | — | `l10n.profileNoReportsSubmitted` |
| pages/reports/my_reports_screen.dart:170 | `profileReportsSubmitWillAppear` | Reports you submit will appear here | — | `l10n.profileReportsSubmitWillAppear` |
| pages/reports/my_reports_screen.dart:208 | `profileReportTypeTitle` | {type} Report | type:Object | `l10n.profileReportTypeTitle(_getTypeLabel(report['type']))` |
| pages/reports/my_reports_screen.dart:212 | `profileReportReason` | Reason: {reason} | reason:Object | `l10n.profileReportReason(_getReasonLabel(report['reason']))` |
| pages/settings/account_deletion.dart:59 | `profileDeleteAccountFinalBody` | All your data will be permanently deleted.\n\nAre you absolutely sure? | — | `'${l10n.thisActionCannotBeUndone} ${l10n.profileDeleteAccountFinalBody}'` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L9': [
    'profileBuyMeCoffee',
    'profileOr',
    'profileLoadingNotifications',
    'profileLoadingSettings',
    'profileAdmin',
    'profileSelected',
    'profilePrivacyIntro',
    'profileUpdate',
    'profileNoTopicsCategory',
    'profileAdminTools',
    'profileCompletionAdd',
    'profileActive',
    'profileAutoSaveEnabled',
    'profileChangesSavedInstantlyWhen',
    'profileCurrentTheme',
    'profileThemeChangesApplyInstantly',
    'profileLoadingVisitors',
    'momentsPullDownRefresh',
    'profileSeeWhoChecked',
    'profileRecentVisitors',
    'profileNoReportsSubmitted',
    'profileReportsSubmitWillAppear',
    'profileReportTypeTitle',
    'profileReportReason',
    'profileDeleteAccountFinalBody',
  ],
// in _filesByTask:
  'L9': [
    'pages/menu_tab/TabBarMenu.dart',
    'pages/notifications/notification_history_screen.dart',
    'pages/notifications/notification_settings_screen.dart',
    'pages/profile/drawer/drawer_section.dart',
    'pages/profile/edit/language_edit.dart',
    'pages/profile/edit/picture_edit/photo_grid_tile.dart',
    'pages/profile/edit/privacy_edit.dart',
    'pages/profile/edit/topics_edit.dart',
    'pages/profile/profile_main.dart',
    'pages/profile/profile_main/sections/profile_about_tab.dart',
    'pages/profile/profile_main/sections/profile_highlights_tab.dart',
    'pages/profile/settings.dart',
    'pages/profile/theme.dart',
    'pages/profile/visitors_screen.dart',
    'pages/reports/my_reports_screen.dart',
    'pages/settings/account_deletion.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L9` → "app_en.arb: … missing" and 33 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/menu_tab/TabBarMenu.dart lib/pages/notifications/notification_history_screen.dart lib/pages/notifications/notification_settings_screen.dart lib/pages/profile/drawer/drawer_section.dart lib/pages/profile/edit/language_edit.dart lib/pages/profile/edit/picture_edit/photo_grid_tile.dart lib/pages/profile/edit/privacy_edit.dart lib/pages/profile/edit/topics_edit.dart lib/pages/profile/profile_main.dart lib/pages/profile/profile_main/sections/profile_about_tab.dart lib/pages/profile/profile_main/sections/profile_highlights_tab.dart lib/pages/profile/settings.dart lib/pages/profile/theme.dart lib/pages/profile/visitors_screen.dart lib/pages/reports/my_reports_screen.dart lib/pages/settings/account_deletion.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/menu_tab/TabBarMenu.dart lib/pages/notifications/notification_history_screen.dart lib/pages/notifications/notification_settings_screen.dart lib/pages/profile/drawer/drawer_section.dart lib/pages/profile/edit/language_edit.dart lib/pages/profile/edit/picture_edit/photo_grid_tile.dart lib/pages/profile/edit/privacy_edit.dart lib/pages/profile/edit/topics_edit.dart lib/pages/profile/profile_main.dart lib/pages/profile/profile_main/sections/profile_about_tab.dart lib/pages/profile/profile_main/sections/profile_highlights_tab.dart lib/pages/profile/settings.dart lib/pages/profile/theme.dart lib/pages/profile/visitors_screen.dart lib/pages/reports/my_reports_screen.dart lib/pages/settings/account_deletion.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 117 left**" (next: L10).
  Message: `i18n(l9): localize notifications, profile, settings, reports` — body: "25 new keys, 33 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 117 hardcoded literals (L10..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L10: Localize Stories and video editor
**Files:**
  - `lib/pages/stories/create/create_story_screen.dart`
  - `lib/pages/stories/create/poll_sticker_editor.dart`
  - `lib/pages/stories/create/question_sticker_editor.dart`
  - `lib/pages/stories/create/studio/story_canvas.dart`
  - `lib/pages/stories/create/studio/text_overlay_editor.dart`
  - `lib/pages/stories/feed/stories_feed_widget.dart`
  - `lib/pages/stories/highlights/highlight_editor_sheet.dart`
  - `lib/pages/stories/viewer/story_share_sheet.dart`
  - `lib/pages/stories/viewer/story_viewer_screen.dart`
  - `lib/pages/stories/viewer/story_viewers_sheet.dart`
  - `lib/pages/video_editor/video_editor_screen.dart`
  - `lib/widgets/story/story_poll_widget.dart`
  - `lib/widgets/story/story_question_box_widget.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 24 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

52 literals in 13 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/stories/create/create_story_screen.dart:452 | `storyOptimizingBestExperience` | Optimizing for the best experience | — | `l10n.storyOptimizingBestExperience` |
| pages/stories/create/create_story_screen.dart:664 | `share` | Share | (existing key) | `l10n.share` |
| pages/stories/create/create_story_screen.dart:694 | `storyCreate` | Create a Story | — | `l10n.storyCreate` |
| pages/stories/create/create_story_screen.dart:703 | `shareMomentsThatDisappear` | Share moments that disappear in 24 hours | (existing key) | `l10n.shareMomentsThatDisappear` |
| pages/stories/create/create_story_screen.dart:991 | `change` | Change | (existing key) | `l10n.change` |
| pages/stories/create/create_story_screen.dart:1038 | `stickerMedia` | Sticker | (existing key) | `l10n.stickerMedia` |
| pages/stories/create/create_story_screen.dart:1222 | `storyAddTags` | Add tags | — | `l10n.storyAddTags` |
| pages/stories/create/create_story_screen.dart:1626 | `storyVideoSelected` | Video Selected | — | `l10n.storyVideoSelected` |
| pages/stories/create/poll_sticker_editor.dart:114 | `cancel` | Cancel | (existing key) | `l10n.cancel` |
| pages/stories/create/poll_sticker_editor.dart:117 | `storyAddPoll` | Add Poll | — | `l10n.storyAddPoll` |
| pages/stories/create/poll_sticker_editor.dart:121 | `done` | Done | (existing key) | `l10n.done` |
| pages/stories/create/poll_sticker_editor.dart:138 | `question` | Question | (existing key) | `l10n.question` |
| pages/stories/create/poll_sticker_editor.dart:170 | `storyOptions` | Options | — | `l10n.storyOptions` |
| pages/stories/create/poll_sticker_editor.dart:226 | `addOption` | Add option | (existing key) | `l10n.addOption` |
| pages/stories/create/question_sticker_editor.dart:59 | `cancel` | Cancel | (existing key) | `l10n.cancel` |
| pages/stories/create/question_sticker_editor.dart:62 | `storyAddQuestion` | Add Question | — | `l10n.storyAddQuestion` |
| pages/stories/create/question_sticker_editor.dart:66 | `done` | Done | (existing key) | `l10n.done` |
| pages/stories/create/question_sticker_editor.dart:83 | `storyPrompt` | Prompt | — | `l10n.storyPrompt` |
| pages/stories/create/studio/story_canvas.dart:94 | `storyTapAnywhereAddText` | Tap anywhere to add text | — | `l10n.storyTapAnywhereAddText` |
| pages/stories/create/studio/text_overlay_editor.dart:112 | `done` | Done | (existing key) | `l10n.done` |
| pages/stories/feed/stories_feed_widget.dart:451 | `yourStory` | Your Story | (existing key) | `l10n.yourStory` |
| pages/stories/highlights/highlight_editor_sheet.dart:499 | `storyHighlightStoryCount` | {storyCount, plural, =1{1 story} other{{storyCount} stories}} | storyCount:int | `l10n.storyHighlightStoryCount(h.storyCount)` |
| pages/stories/viewer/story_share_sheet.dart:185 | `storySendFriends` | Send to friends | — | `l10n.storySendFriends` |
| pages/stories/viewer/story_share_sheet.dart:192 | `storySelected` | {count} selected | count:Object | `l10n.storySelected(_selectedIds.length)` |
| pages/stories/viewer/story_viewer_screen.dart:979 | `noStories` | No stories | (existing key) | `l10n.noStories` |
| pages/stories/viewer/story_viewer_screen.dart:1195 | `closeFriends` | Close Friends | (existing key) | `l10n.closeFriends` |
| pages/stories/viewer/story_viewer_screen.dart:1324 | `storySendFriends` | Send to friends | — | `l10n.storySendFriends` |
| pages/stories/viewer/story_viewer_screen.dart:1361 | `storyShareSave` | Share/Save | — | `l10n.storyShareSave` |
| pages/stories/viewer/story_viewer_screen.dart:1379 | `addMoreToStory` | Add more to story | (existing key) | `l10n.addMoreToStory` |
| pages/stories/viewer/story_viewer_screen.dart:1763 | `replyToStory` | Reply to story... | (existing key) | `l10n.replyToStory` |
| pages/stories/viewer/story_viewer_screen.dart:1814 | `sent` | Sent! | (existing key) | `l10n.sent` |
| pages/stories/viewer/story_viewers_sheet.dart:183 | `storySeenBy` | Seen by {viewCount} | viewCount:Object | `l10n.storySeenBy(_viewCount)` |
| pages/stories/viewer/story_viewers_sheet.dart:227 | `storyNoViewsYet` | No views yet | — | `l10n.storyNoViewsYet` |
| pages/video_editor/video_editor_screen.dart:157 | `storyEditVideo` | Edit Video | — | `l10n.storyEditVideo` |
| pages/video_editor/video_editor_screen.dart:165 | `done` | Done | (existing key) | `l10n.done` |
| pages/video_editor/video_editor_screen.dart:323 | `filters` | Filters | (existing key) | `l10n.filters` |
| pages/video_editor/video_editor_screen.dart:423 | `processingVideo` | Processing video... | (existing key) | `l10n.processingVideo` |
| widgets/story/story_poll_widget.dart:105 | `storyVotes` | {totalVotes} votes | totalVotes:Object | `l10n.storyVotes(widget.poll.totalVotes)` |
| widgets/story/story_poll_widget.dart:293 | `storyCreatePoll` | Create Poll | — | `l10n.storyCreatePoll` |
| widgets/story/story_poll_widget.dart:354 | `addOption` | Add option | (existing key) | `l10n.addOption` |
| widgets/story/story_poll_widget.dart:372 | `anonymousVoting` | Anonymous voting | (existing key) | `l10n.anonymousVoting` |
| widgets/story/story_poll_widget.dart:384 | `cancel` | Cancel | (existing key) | `l10n.cancel` |
| widgets/story/story_question_box_widget.dart:141 | `storySendAnonymously` | Send anonymously | — | `l10n.storySendAnonymously` |
| widgets/story/story_question_box_widget.dart:166 | `send` | Send | (existing key) | `l10n.send` |
| widgets/story/story_question_box_widget.dart:172 | `answerSent` | Answer sent! | (existing key) | `l10n.answerSent` |
| widgets/story/story_question_box_widget.dart:177 | `storyResponseCount` | {count, plural, =1{1 response} other{{count} responses}} | count:int | `l10n.storyResponseCount(widget.questionBox.responses.length)` |
| widgets/story/story_question_box_widget.dart:194 | `storyViewResponses` | View responses | — | `l10n.storyViewResponses` |
| widgets/story/story_question_box_widget.dart:235 | `storyResponsesTitle` | Responses | — | `l10n.storyResponsesTitle` |
| widgets/story/story_question_box_widget.dart:251 | `storyNoResponsesYet` | No responses yet | — | `l10n.storyNoResponsesYet` |
| widgets/story/story_question_box_widget.dart:347 | `storyQuestionBox` | Question Box | — | `l10n.storyQuestionBox` |
| widgets/story/story_question_box_widget.dart:385 | `cancel` | Cancel | (existing key) | `l10n.cancel` |
| widgets/story/story_question_box_widget.dart:399 | `add` | Add | (existing key) | `l10n.add` |


- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L10': [
    'storyOptimizingBestExperience',
    'storyCreate',
    'storyAddTags',
    'storyVideoSelected',
    'storyAddPoll',
    'storyOptions',
    'storyAddQuestion',
    'storyPrompt',
    'storyTapAnywhereAddText',
    'storyHighlightStoryCount',
    'storySendFriends',
    'storySelected',
    'storyShareSave',
    'storySeenBy',
    'storyNoViewsYet',
    'storyEditVideo',
    'storyVotes',
    'storyCreatePoll',
    'storySendAnonymously',
    'storyResponseCount',
    'storyViewResponses',
    'storyResponsesTitle',
    'storyNoResponsesYet',
    'storyQuestionBox',
  ],
// in _filesByTask:
  'L10': [
    'pages/stories/create/create_story_screen.dart',
    'pages/stories/create/poll_sticker_editor.dart',
    'pages/stories/create/question_sticker_editor.dart',
    'pages/stories/create/studio/story_canvas.dart',
    'pages/stories/create/studio/text_overlay_editor.dart',
    'pages/stories/feed/stories_feed_widget.dart',
    'pages/stories/highlights/highlight_editor_sheet.dart',
    'pages/stories/viewer/story_share_sheet.dart',
    'pages/stories/viewer/story_viewer_screen.dart',
    'pages/stories/viewer/story_viewers_sheet.dart',
    'pages/video_editor/video_editor_screen.dart',
    'widgets/story/story_poll_widget.dart',
    'widgets/story/story_question_box_widget.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L10` → "app_en.arb: … missing" and 52 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/stories/create/create_story_screen.dart lib/pages/stories/create/poll_sticker_editor.dart lib/pages/stories/create/question_sticker_editor.dart lib/pages/stories/create/studio/story_canvas.dart lib/pages/stories/create/studio/text_overlay_editor.dart lib/pages/stories/feed/stories_feed_widget.dart lib/pages/stories/highlights/highlight_editor_sheet.dart lib/pages/stories/viewer/story_share_sheet.dart lib/pages/stories/viewer/story_viewer_screen.dart lib/pages/stories/viewer/story_viewers_sheet.dart lib/pages/video_editor/video_editor_screen.dart lib/widgets/story/story_poll_widget.dart lib/widgets/story/story_question_box_widget.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/stories/create/create_story_screen.dart lib/pages/stories/create/poll_sticker_editor.dart lib/pages/stories/create/question_sticker_editor.dart lib/pages/stories/create/studio/story_canvas.dart lib/pages/stories/create/studio/text_overlay_editor.dart lib/pages/stories/feed/stories_feed_widget.dart lib/pages/stories/highlights/highlight_editor_sheet.dart lib/pages/stories/viewer/story_share_sheet.dart lib/pages/stories/viewer/story_viewer_screen.dart lib/pages/stories/viewer/story_viewers_sheet.dart lib/pages/video_editor/video_editor_screen.dart lib/widgets/story/story_poll_widget.dart lib/widgets/story/story_question_box_widget.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 65 left**" (next: L11).
  Message: `i18n(l10): localize stories and video editor` — body: "24 new keys, 52 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 65 hardcoded literals (L11..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L11: Localize VIP, coins, limits, launch pop-ups
**Files:**
  - `lib/pages/coins/coin_history_screen.dart`
  - `lib/pages/coins/coin_shop_screen.dart`
  - `lib/pages/vip/visitor_upgrade_screen.dart`
  - `lib/utils/api_error_handler.dart`
  - `lib/utils/feature_gate.dart`
  - `lib/widgets/ads/ad_widgets.dart`
  - `lib/widgets/promo/ads_notice_modal.dart`
  - `lib/widgets/promo/announcement_modal.dart`
  - `lib/widgets/tutor/persona_upgrade_sheet.dart`
  - `lib/widgets/vip_locked_feature.dart`
  - `lib/widgets/vip_up_pill.dart`
  - `lib/widgets/visitor_limit_dialog.dart`
  - `lib/widgets/welcome_back_modal.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 27 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

39 literals in 13 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| pages/coins/coin_history_screen.dart:137 | `vipNoCoinActivityYet` | No coin activity yet | — | `l10n.vipNoCoinActivityYet` |
| pages/coins/coin_shop_screen.dart:272 | `vipCoinShopExplainer` | Coins are used to unlock extra uses of translations, AI tutor chats, and moments once you hit your free daily limit. Purchases are non-refundable once coins are spent. | — | `l10n.vipCoinShopExplainer` |
| pages/coins/coin_shop_screen.dart:560 | `vipLimitReached` | Limit reached | — | `l10n.vipLimitReached` |
| pages/coins/coin_shop_screen.dart:629 | `vipCoins` | coins | — | `l10n.vipCoins` |
| pages/coins/coin_shop_screen.dart:646 | `vipBestValue` | BEST VALUE | (existing key) | `l10n.vipBestValue` |
| pages/coins/coin_shop_screen.dart:661 | `vipBonusIncluded` | +{bonusCoins} bonus included | bonusCoins:Object | `l10n.vipBonusIncluded(pack.bonusCoins)` |
| pages/vip/visitor_upgrade_screen.dart:48 | `vipVisitorModeLimitReached` | Visitor Mode Limit Reached | — | `l10n.vipVisitorModeLimitReached` |
| pages/vip/visitor_upgrade_screen.dart:74 | `vipWhatGetFreeAccount` | What You Get with a Free Account | — | `l10n.vipWhatGetFreeAccount` |
| pages/vip/visitor_upgrade_screen.dart:137 | `vipCreateFreeAccount` | Create Free Account | — | `l10n.vipCreateFreeAccount` |
| pages/vip/visitor_upgrade_screen.dart:157 | `or` | OR | (existing key) | `l10n.or` |
| pages/vip/visitor_upgrade_screen.dart:177 | `vipGoUnlimitedAccess` | Go VIP for Unlimited Access | — | `l10n.vipGoUnlimitedAccess` |
| pages/vip/visitor_upgrade_screen.dart:233 | `vipContinueAsVisitor` | Continue as Visitor | — | `l10n.vipContinueAsVisitor` |
| utils/api_error_handler.dart:45 | `limitDailyReachedTitle` | Daily Limit Reached | (existing key) | `l10n.limitDailyReachedTitle` |
| utils/api_error_handler.dart:62 | `vipResets` | Resets at: {resetTime} | resetTime:Object | `l10n.vipResets(resetTime)` |
| utils/api_error_handler.dart:82 | `vipUsedToday` | {currentUsage} / {maxAllowed} used today | currentUsage:Object,maxAllowed:Object | `l10n.vipUsedToday(currentUsage, maxAllowed)` |
| utils/api_error_handler.dart:95 | `ok` | OK | (existing key) | `l10n.ok` |
| utils/api_error_handler.dart:113 | `upgradeToVip` | Upgrade to VIP | (existing key) | `l10n.upgradeToVip` |
| utils/feature_gate.dart:162 | `limitDailyReachedTitle` | Daily Limit Reached | (existing key) | `l10n.limitDailyReachedTitle` |
| utils/feature_gate.dart:170 | `ok` | OK | (existing key) | `l10n.ok` |
| utils/feature_gate.dart:182 | `upgradeToVip` | Upgrade to VIP | (existing key) | `l10n.upgradeToVip` |
| utils/feature_gate.dart:320 | `vipTierVisitor` | Visitor | — | `l10n.vipTierVisitor` |
| utils/feature_gate.dart:343 | `vipTierMember` | Member | — | `l10n.vipTierMember` |
| widgets/ads/ad_widgets.dart:257 | `vipAd` | Ad | — | `l10n.vipAd` |
| widgets/promo/ads_notice_modal.dart:86 | `promoAdsNoticeTitle` | A note from the developer | — | `l10n.promoAdsNoticeTitle` |
| widgets/promo/ads_notice_modal.dart:108 | `promoAdsNoticeBody` | Hey! I'm Firdavs, the solo developer behind Bananatalk. I've added a few small ads to the app to help keep it free and fund ongoing development.\n\nI know ads can be annoying — so I've made them optional and rewarding. Watch an ad to unlock extra messages, community filters, bonus XP after quizzes, and more.\n\nThank you for using Bananatalk. Your support means everything. 🙏 | — | `l10n.promoAdsNoticeBody` |
| widgets/promo/ads_notice_modal.dart:148 | `promoAdsNoticeGotIt` | Got it, thanks! 👍 | — | `l10n.promoAdsNoticeGotIt` |
| widgets/promo/announcement_modal.dart:184 | `dismiss` | Dismiss | (existing key) | `l10n.dismiss` |
| widgets/promo/announcement_modal.dart:207 | `promoAnnouncementGotIt` | Got it 👍 | — | `l10n.promoAnnouncementGotIt` |
| widgets/tutor/persona_upgrade_sheet.dart:92 | `upgradeToVip` | Upgrade to VIP | (existing key) | `l10n.upgradeToVip` |
| widgets/vip_locked_feature.dart:95 | `vipOnly` | VIP Only | — | `l10n.vipOnly` |
| widgets/vip_locked_feature.dart:105 | `vipTapUpgrade` | Tap to upgrade | — | `l10n.vipTapUpgrade` |
| widgets/vip_locked_feature.dart:229 | `vipUnlockFeatures` | Unlock VIP Features | — | `l10n.vipUnlockFeatures` |
| widgets/vip_locked_feature.dart:302 | `upgradeToVip` | Upgrade to VIP | (existing key) | `l10n.upgradeToVip` |
| widgets/vip_locked_feature.dart:316 | `maybeLater` | Maybe Later | (existing key) | `l10n.maybeLater` |
| widgets/vip_up_pill.dart:82 | `vipUpPillUp` | Up | — | `l10n.vipUpPillUp` |
| widgets/visitor_limit_dialog.dart:102 | `vipChooseOption` | Choose an option: | — | `l10n.vipChooseOption` |
| widgets/welcome_back_modal.dart:67 | `promoWelcomeBackTitle` | Welcome back! 👋 | — | `l10n.promoWelcomeBackTitle` |
| widgets/welcome_back_modal.dart:72 | `promoWelcomeBackBody` | We missed you. Here's what's waiting: | — | `l10n.promoWelcomeBackBody` |
| widgets/welcome_back_modal.dart:113 | `promoWelcomeBackCta` | Let's go! 🚀 | — | `l10n.promoWelcomeBackCta` |


`widgets/promo/announcement_modal.dart`, `ads_notice_modal.dart` and `welcome_back_modal.dart` are touched by the A tasks (launch coordinator, announcements) which run first: re-grep these three files before editing and localize whatever literal survives under the key named here.

- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L11': [
    'vipNoCoinActivityYet',
    'vipCoinShopExplainer',
    'vipLimitReached',
    'vipCoins',
    'vipBonusIncluded',
    'vipVisitorModeLimitReached',
    'vipWhatGetFreeAccount',
    'vipCreateFreeAccount',
    'vipGoUnlimitedAccess',
    'vipContinueAsVisitor',
    'vipResets',
    'vipUsedToday',
    'vipTierVisitor',
    'vipTierMember',
    'vipAd',
    'promoAdsNoticeTitle',
    'promoAdsNoticeBody',
    'promoAdsNoticeGotIt',
    'promoAnnouncementGotIt',
    'vipOnly',
    'vipTapUpgrade',
    'vipUnlockFeatures',
    'vipUpPillUp',
    'vipChooseOption',
    'promoWelcomeBackTitle',
    'promoWelcomeBackBody',
    'promoWelcomeBackCta',
  ],
// in _filesByTask:
  'L11': [
    'pages/coins/coin_history_screen.dart',
    'pages/coins/coin_shop_screen.dart',
    'pages/vip/visitor_upgrade_screen.dart',
    'utils/api_error_handler.dart',
    'utils/feature_gate.dart',
    'widgets/ads/ad_widgets.dart',
    'widgets/promo/ads_notice_modal.dart',
    'widgets/promo/announcement_modal.dart',
    'widgets/tutor/persona_upgrade_sheet.dart',
    'widgets/vip_locked_feature.dart',
    'widgets/vip_up_pill.dart',
    'widgets/visitor_limit_dialog.dart',
    'widgets/welcome_back_modal.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L11` → "app_en.arb: … missing" and 39 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/pages/coins/coin_history_screen.dart lib/pages/coins/coin_shop_screen.dart lib/pages/vip/visitor_upgrade_screen.dart lib/utils/api_error_handler.dart lib/utils/feature_gate.dart lib/widgets/ads/ad_widgets.dart lib/widgets/promo/ads_notice_modal.dart lib/widgets/promo/announcement_modal.dart lib/widgets/tutor/persona_upgrade_sheet.dart lib/widgets/vip_locked_feature.dart lib/widgets/vip_up_pill.dart lib/widgets/visitor_limit_dialog.dart lib/widgets/welcome_back_modal.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/pages/coins/coin_history_screen.dart lib/pages/coins/coin_shop_screen.dart lib/pages/vip/visitor_upgrade_screen.dart lib/utils/api_error_handler.dart lib/utils/feature_gate.dart lib/widgets/ads/ad_widgets.dart lib/widgets/promo/ads_notice_modal.dart lib/widgets/promo/announcement_modal.dart lib/widgets/tutor/persona_upgrade_sheet.dart lib/widgets/vip_locked_feature.dart lib/widgets/vip_up_pill.dart lib/widgets/visitor_limit_dialog.dart lib/widgets/welcome_back_modal.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 26 left**" (next: L12).
  Message: `i18n(l11): localize vip, coins, limits, launch pop-ups` — body: "27 new keys, 39 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 26 hardcoded literals (L12..L12), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L12: Localize Shared widgets, auth, calls, errors
**Files:**
  - `lib/core/widgets/app_loading.dart`
  - `lib/pages/authentication/register/register_screen.dart`
  - `lib/router/app_router.dart`
  - `lib/screens/active_call_screen.dart`
  - `lib/widgets/block_user_dialog.dart`
  - `lib/widgets/image_preview_dialog.dart`
  - `lib/widgets/qr_code_sheet.dart`
  - `lib/widgets/report_dialog.dart`
  - `lib/widgets/report_evidence_section.dart`
  - `lib/widgets/voice_recorder/voice_recorder_stub.dart`
  - `lib/l10n/app_*.arb` (19), generated `lib/l10n/app_localizations*.dart`, `docs/l10n/native-qa-strings-2026-10.csv`, `test/l10n/hardcoded_strings_test.dart`, `docs/REMAINING_WORK.md`

**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces 20 new `AppLocalizations` getters; reuses existing keys where the table says "(existing key)".

26 literals in 10 files (as of `f3742650`; line numbers drift — match by text):


| file:line | key | English (`app_en.arb`) | placeholders | replace the literal with |
|---|---|---|---|---|
| core/widgets/app_loading.dart:281 | `tryAgain` | Try Again | (existing key) | `l10n.tryAgain` |
| pages/authentication/register/register_screen.dart:647 | `commonContinueWhereLeftOff` | Continue where you left off? | — | `l10n.commonContinueWhereLeftOff` |
| router/app_router.dart:372 | `commonLanguageNotProvided` | Language not provided | — | `l10n.commonLanguageNotProvided` |
| router/app_router.dart:394 | `commonExamNotProvided` | Exam not provided | — | `l10n.commonExamNotProvided` |
| screens/active_call_screen.dart:581 | `commonMuted` | Muted | — | `l10n.commonMuted` |
| screens/active_call_screen.dart:626 | `commonPoorConnection` | Poor Connection | — | `l10n.commonPoorConnection` |
| screens/active_call_screen.dart:642 | `connecting` | Connecting... | (existing key) | `l10n.connecting` |
| widgets/block_user_dialog.dart:30 | `commonBlockUserConfirmBody` | Are you sure you want to block {targetUserName}?\n\nYou will no longer see their messages, posts, or appear in each other's searches. | targetUserName:Object | `l10n.commonBlockUserConfirmBody(targetUserName)` |
| widgets/image_preview_dialog.dart:119 | `preview` | Preview | (existing key) | `l10n.preview` |
| widgets/image_preview_dialog.dart:212 | `commonVideoFile` | Video File | — | `l10n.commonVideoFile` |
| widgets/qr_code_sheet.dart:332 | `commonPointCameraBananatalkQr` | Point your camera at a Bananatalk QR code | — | `l10n.commonPointCameraBananatalkQr` |
| widgets/report_dialog.dart:289 | `commonReportSubmittedButSome` | Report submitted, but some evidence failed to upload | — | `l10n.commonReportSubmittedButSome` |
| widgets/report_dialog.dart:385 | `commonReportTitle` | Report {typeLabel} | typeLabel:Object | `l10n.commonReportTitle(_typeLabel)` |
| widgets/report_dialog.dart:408 | `commonWhyReporting` | Why are you reporting this {typeLabel}? | typeLabel:Object | `l10n.commonWhyReporting(_typeLabel)` |
| widgets/report_dialog.dart:435 | `additionalDetailsOptional` | Additional details (optional) | (existing key) | `l10n.additionalDetailsOptional` |
| widgets/report_dialog.dart:459 | `commonAddEvidenceRequired` | Add Evidence (Required) | — | `l10n.commonAddEvidenceRequired` |
| widgets/report_dialog.dart:464 | `commonUploadScreenshotsTextFiles` | Upload screenshots or text files to support your report | — | `l10n.commonUploadScreenshotsTextFiles` |
| widgets/report_dialog.dart:476 | `commonAddEvidenceCount` | Add Evidence ({count}/{maxFiles}) | count:Object,maxFiles:Object | `l10n.commonAddEvidenceCount(_selectedFiles.length, maxFiles)` |
| widgets/report_dialog.dart:504 | `commonReportTotalSize` | Total: {used} / {max} | used:Object,max:Object | `l10n.commonReportTotalSize(_formatFileSize(_totalFileSize), _formatFileSize(maxTotalSize))` |
| widgets/report_dialog.dart:563 | `submitReport` | Submit Report | (existing key) | `l10n.submitReport` |
| widgets/report_evidence_section.dart:31 | `commonEvidence` | Evidence | — | `l10n.commonEvidence` |
| widgets/report_evidence_section.dart:165 | `commonImageFailed` | Image failed | — | `l10n.commonImageFailed` |
| widgets/report_evidence_section.dart:382 | `commonShowMore` | Show more | — | `l10n.commonShowMore` |
| widgets/voice_recorder/voice_recorder_stub.dart:49 | `commonVoiceRecordingNotAvailable` | Voice Recording Not Available | — | `l10n.commonVoiceRecordingNotAvailable` |
| widgets/voice_recorder/voice_recorder_stub.dart:58 | `commonVoiceRecordingOnlyAvailable` | Voice recording is only available on mobile devices. | — | `l10n.commonVoiceRecordingOnlyAvailable` |
| widgets/voice_recorder/voice_recorder_stub.dart:69 | `ok` | OK | (existing key) | `l10n.ok` |

`screens/active_call_screen.dart` is edited again by C9/C10; L12 runs first, so C9/C10 build on the localized file.

- [ ] **Step 1: failing test.** Add to `test/l10n/hardcoded_strings_test.dart`:
```dart
// in _keysByTask:
  'L12': [
    'commonContinueWhereLeftOff',
    'commonLanguageNotProvided',
    'commonExamNotProvided',
    'commonMuted',
    'commonPoorConnection',
    'commonBlockUserConfirmBody',
    'commonVideoFile',
    'commonPointCameraBananatalkQr',
    'commonReportSubmittedButSome',
    'commonReportTitle',
    'commonWhyReporting',
    'commonAddEvidenceRequired',
    'commonUploadScreenshotsTextFiles',
    'commonAddEvidenceCount',
    'commonReportTotalSize',
    'commonEvidence',
    'commonImageFailed',
    'commonShowMore',
    'commonVoiceRecordingNotAvailable',
    'commonVoiceRecordingOnlyAvailable',
  ],
// in _filesByTask:
  'L12': [
    'core/widgets/app_loading.dart',
    'pages/authentication/register/register_screen.dart',
    'router/app_router.dart',
    'screens/active_call_screen.dart',
    'widgets/block_user_dialog.dart',
    'widgets/image_preview_dialog.dart',
    'widgets/qr_code_sheet.dart',
    'widgets/report_dialog.dart',
    'widgets/report_evidence_section.dart',
    'widgets/voice_recorder/voice_recorder_stub.dart',
  ],
```
- [ ] **Step 2: run, expected fail.** `flutter test test/l10n/hardcoded_strings_test.dart --name L12` → "app_en.arb: … missing" and 26 scanner hits.
- [ ] **Step 3: implement** with the Standard L procedure (above) using this task's table.
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/l10n/ && flutter analyze lib/core/widgets/app_loading.dart lib/pages/authentication/register/register_screen.dart lib/router/app_router.dart lib/screens/active_call_screen.dart lib/widgets/block_user_dialog.dart lib/widgets/image_preview_dialog.dart lib/widgets/qr_code_sheet.dart lib/widgets/report_dialog.dart lib/widgets/report_evidence_section.dart lib/widgets/voice_recorder/voice_recorder_stub.dart` → all green, analyzer clean.
- [ ] **Step 5: commit.** `git add lib/core/widgets/app_loading.dart lib/pages/authentication/register/register_screen.dart lib/router/app_router.dart lib/screens/active_call_screen.dart lib/widgets/block_user_dialog.dart lib/widgets/image_preview_dialog.dart lib/widgets/qr_code_sheet.dart lib/widgets/report_dialog.dart lib/widgets/report_evidence_section.dart lib/widgets/voice_recorder/voice_recorder_stub.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/l10n/hardcoded_strings_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 change the hardcoded line to "**Hardcoded strings: 0 left**" (then tick it).
  Message: `i18n(l12): localize shared widgets, auth, calls, errors` — body: "20 new keys, 26 literals; 18 locales machine-drafted, rows appended to native-qa-strings-2026-10.csv. Open: 0 hardcoded literals (none), L13 guard, native review of every draft." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task L13: Guard — no new English `Text` literal outside an allowlist
**Files:** create `test/l10n/no_hardcoded_text_test.dart`; `docs/REMAINING_WORK.md`
**Interfaces:** Consumes `test/l10n/hardcoded_text_scanner.dart` (L1). Produces a `flutter test` failure for any new `Text('English…')`.

- [ ] **Step 1: failing test** — `test/l10n/no_hardcoded_text_test.dart`:
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'hardcoded_text_scanner.dart';

/// Paths (a file, or a directory ending in '/') that may keep English Text literals.
const _allowedPaths = <String, String>{
  'lib/pages/admin/': 'staff-only admin console, English by design',
  'lib/pages/reports/admin_reports_screen.dart': 'staff-only admin console',
  'lib/screens/livekit_test_screen.dart': 'debug-only test screen',
  // No importer as of 2026-10-12: localize (or delete) the file when one is revived.
  'lib/pages/ai/conversation/ai_conversation_screen.dart': 'unreachable',
  'lib/pages/chat/bookmarks/bookmarks_screen.dart': 'unreachable',
  'lib/pages/learning/quizzes/quizzes_screen.dart': 'unreachable',
  'lib/pages/settings/email_preferences_screen.dart': 'unreachable',
  'lib/providers/api_provider.dart': 'unreachable',
  'lib/utils/pagination_utils.dart': 'unreachable',
  'lib/widgets/create_poll_dialog.dart': 'unreachable',
  'lib/widgets/inline_translation_widget.dart': 'unreachable',
  'lib/widgets/learning/level_badge_widget.dart': 'unreachable',
  'lib/widgets/learning/xp_progress_widget.dart': 'unreachable',
  'lib/widgets/limit_indicator.dart': 'unreachable',
  'lib/widgets/poll_widget.dart': 'unreachable',
  'lib/widgets/quick_replies_panel.dart': 'unreachable',
  'lib/widgets/report_user_dialog.dart': 'unreachable',
  'lib/widgets/save_moment_button.dart': 'unreachable',
  'lib/widgets/story/story_reaction_bar.dart': 'unreachable',
  'lib/widgets/story/story_reply_sheet.dart': 'unreachable',
  'lib/widgets/upload/upload_progress_indicator.dart': 'unreachable',
  'lib/widgets/visitor_usage_indicator.dart': 'unreachable',
};

/// Exact literals allowed in one file (support diagnostics, not copy).
const _allowedTexts = <String, Set<String>>{
  'lib/pages/vip/vip_payment_screen.dart': {
    'Debug Info:',
    r'User ID: ${widget.userId}\nPlan: ${widget.plan.name}\nPayment: $selectedPaymentMethod',
  },
};

/// Words that are the same in every locale: brands and units.
const _brandTokens = {'VIP', 'XP', 'HD', 'MB', 'km', 'GIPHY', 'Bananatalk', 'BananaTalk', 'firdavsDev'};

final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');
final _word = RegExp(r'[A-Za-z]+');

bool _isAllowed(HardcodedText h) {
  if (_allowedPaths.keys.any((p) => p.endsWith('/') ? h.path.startsWith(p) : h.path == p)) {
    return true;
  }
  if (_allowedTexts[h.path]?.contains(h.text) ?? false) return true;
  final words = _word.allMatches(h.text.replaceAll(_interpolation, '')).map((m) => m.group(0)!);
  return words.every(_brandTokens.contains);
}

void main() {
  test('the scanner finds what it must and skips what it must', () {
    expect(scanSource('x.dart', "Text('Hello there')"), hasLength(1));
    expect(scanSource('x.dart', "Text(\n  'Multi ' 'line')").single.text, 'Multi line');
    expect(scanSource('x.dart', "Text('\${a ? 'yes' : 'no'} items')"), hasLength(1));
    expect(scanSource('x.dart', 'Text(l10n.hello)'), isEmpty);
    expect(scanSource('x.dart', "// Text('Hello')"), isEmpty);
    expect(scanSource('x.dart', "Text('\${n}')"), isEmpty);
    expect(scanSource('x.dart', "RichText(text: x)"), isEmpty);
  });

  test('every allowlisted path still exists', () {
    for (final p in [..._allowedPaths.keys, ..._allowedTexts.keys]) {
      final exists = p.endsWith('/') ? Directory(p).existsSync() : File(p).existsSync();
      expect(exists, isTrue, reason: '$p is allowlisted but gone: remove it from the list');
    }
  });

  test('no English Text literal in lib/ outside the allowlist', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/'))
        .where((p) => p.endsWith('.dart') && !p.startsWith('lib/l10n/') && !p.endsWith('.g.dart'));
    final offenders = scanFiles(files).where((h) => !_isAllowed(h)).toList();
    expect(offenders, isEmpty,
        reason: 'Hardcoded English reaches users of every language. Add a key to '
            'lib/l10n/app_en.arb + the 18 other app_*.arb files and use AppLocalizations:\n'
            '${offenders.join('\n')}');
  });
}
```
- [ ] **Step 2: run, expected fail only if an L task missed a literal.** `flutter test test/l10n/no_hardcoded_text_test.dart`. Sanity-check the guard itself: temporarily add `Text('Guard check')` to `lib/widgets/welcome_back_modal.dart`, run → FAIL naming that line; revert. (Against `f3742650` without L1–L12 the same test reports 402 offenders in 128 files.)
- [ ] **Step 3: implement** — fix whatever Step 2 names (a literal added after this plan was written: localize it with the Standard L procedure under the nearest task's prefix).
- [ ] **Step 4: run, pass.** `flutter test test/l10n/` → green.
- [ ] **Step 5: commit.** `git add test/l10n/no_hardcoded_text_test.dart docs/REMAINING_WORK.md`; in REMAINING_WORK §5 tick "Hardcoded strings", add "Guard: `test/l10n/no_hardcoded_text_test.dart`" to the guards line, and add open items: "[ ] 54 property literals (`hintText:`/`labelText:`/`tooltip:`) not yet covered by a guard", "[ ] 19 unreachable files allowlisted in the guard — delete or localize".
  Message: `test(l10n): fail on any new hardcoded English Text literal` — body: what the guard scans, the allowlist reasons; "Open: property literals (54), unreachable files (19), native review of L1–L12 drafts." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

---

## Calls Phase 2

Backend tasks C1–C4 (repo BACKEND; one new test file `test/callPhase2.test.js` created in C1, extended by C2–C3; C4 has its own push file). App tasks C5–C10, docs C11.
Run backend tests with `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js <file>` (never `npm test` — Node 25).
Ship order: C1–C4 deploy first (additive: live builds never send `message`, never call `/upgrade`, never declare `missed_call_actions`; `CALLEE_UNAVAILABLE` reaches live builds as an unknown 409 → their generic "call failed").

### Task C1: Backend — decline with a message
**Files:** `services/callMessageService.js`, `controllers/callController.js`, `routes/calls.js` (doc comment), create `test/callPhase2.test.js`, `docs/REMAINING_WORK.md`
**Interfaces:** Consumes `callStateService.transition('decline')` (writes the call message inside its awaited effects). Produces `POST /api/v1/calls/:id/decline` body `{ deviceId?, message?: string ≤ 200 }` → 400 if longer; `callMessageService.writeDeclineMessage(call, text, io)`.

- [ ] **Step 1: failing test** — create `test/callPhase2.test.js`:
```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { stub } = require('./helpers/authHarness');
const { startDb, stopDb, makeUser, fakeIo, asHandler, silence } = require('./helpers/callKit');

stub('services/livekitService', {
  mintRoomToken: async ({ identity }) => ({ token: `tok-${identity}`, url: 'wss://lk.test' }),
});
stub('services/livekitAdminService', {
  endRoom: async () => {},
  disconnectParticipant: async () => {},
  countParticipants: async () => ({ ok: true, count: 2, missing: false }),
});
const pushes = [];
stub('services/callPushService', {
  sendIncomingCall: async (a) => { pushes.push(['incoming', a]); },
  sendCallCancelled: async (a) => { pushes.push(['cancelled', a]); },
  sendMissedCall: async (a) => { pushes.push(['missed', a]); },
});

let restore, ctl, svc, Call, Message, User, io;

test.before(async () => {
  restore = silence();
  await startDb('callPhase2');
  ctl = require('../controllers/callController');
  svc = require('../services/callStateService');
  Call = require('../models/Call');
  Message = require('../models/Message');
  User = require('../models/User');
  await Promise.all([Call.syncIndexes(), Message.syncIndexes()]);
});
test.after(async () => { await stopDb(); restore(); });
test.beforeEach(() => { io = fakeIo(); require('../lib/callIo').setIo(io); pushes.length = 0; });

const user = (name, extra = {}) =>
  makeUser(name, { userMode: 'regular', timezone: 'UTC', profileCompleted: true, ...extra });
const req = (u, { params = {}, body = {} } = {}) => ({
  user: { id: String(u._id), _id: u._id, name: u.name }, params, body, query: {}, app: { get: () => io },
});
const run = (fn, u, opts) => asHandler(fn)(req(u, opts));
const ring = async (a, b, type = 'audio') => {
  const res = await run(ctl.initiateCall, a, { body: { receiverId: String(b._id), type } });
  assert.equal(res.status, 200, JSON.stringify(res.body || res.error));
  svc.clearRingTimer(res.body.data.call._id);
  return String(res.body.data.call._id);
};
const between = (a, b) => Message.find({
  $or: [{ sender: a._id, receiver: b._id }, { sender: b._id, receiver: a._id }],
}).sort({ createdAt: 1, _id: 1 });

test('decline with a message: the call message, then the receiver\'s text to the caller', async () => {
  const a = await user('ada'); const b = await user('bo');
  const id = await ring(a, b);
  const res = await run(ctl.declineCall, b, { params: { id }, body: { message: '  In a meeting, call you later  ' } });
  assert.equal(res.status, 200);
  const msgs = await between(a, b);
  assert.deepEqual(msgs.map((m) => m.messageType), ['call', 'text']);
  assert.equal(String(msgs[1].sender), String(b._id));
  assert.equal(String(msgs[1].receiver), String(a._id));
  assert.equal(msgs[1].message, 'In a meeting, call you later');
  assert.ok(msgs[1].createdAt > msgs[0].createdAt);
  const toCaller = io.eventsNamed('newMessage').filter((e) => e.rooms.includes(`user_${a._id}`));
  assert.equal(toCaller.at(-1).payload.message.message, 'In a meeting, call you later');
});

test('no message, a blank message, or > 200 chars', async () => {
  const a = await user('ada2'); const b = await user('bo2');
  const id = await ring(a, b);
  const tooLong = await run(ctl.declineCall, b, { params: { id }, body: { message: 'x'.repeat(201) } });
  assert.equal(tooLong.status, 400);
  assert.equal((await Call.findById(id)).status, 'ringing');
  const blank = await run(ctl.declineCall, b, { params: { id }, body: { message: '   ' } });
  assert.equal(blank.status, 200);
  assert.deepEqual((await between(a, b)).map((m) => m.messageType), ['call']);
});
```
- [ ] **Step 2: run, expected fail.** `node --test --test-force-exit --test-concurrency=1 --require ./test/helpers/nodeCompat.js test/callPhase2.test.js` → first test: `['call']` ≠ `['call','text']`; second: 200 ≠ 400.
- [ ] **Step 3: implement.** `services/callMessageService.js` — add and export:
```js
const MAX_DECLINE_MESSAGE = 200;

/**
 * Phase 2: the receiver declined with a message. A normal text message from
 * the receiver, strictly after the call message (transition() already wrote
 * that one inside its awaited effects). No chat push: the caller is in the app.
 */
const writeDeclineMessage = async (call, text, io) => {
  const callerId = call.initiator._id || call.initiator;
  const receiverId = receiverOf(call);
  const after = call.endTime ? new Date(call.endTime).getTime() + 1 : 0;
  const message = await Message.create({
    sender: receiverId,
    receiver: callerId,
    message: text,
    messageType: 'text',
    createdAt: new Date(Math.max(Date.now(), after)),
  });
  const conversation = await findOrCreateDm(callerId, receiverId);
  conversation.lastMessage = message._id;
  conversation.lastMessageAt = message.createdAt;
  if (Array.isArray(conversation.deletedBy) && conversation.deletedBy.length > 0) {
    conversation.deletedBy = conversation.deletedBy.filter((id) => String(id) !== String(callerId));
  }
  await conversation.updateUnreadCount(callerId, 1);
  await message.populate('sender', 'name username images userMode');
  await message.populate('receiver', 'name username images userMode');
  if (io) {
    const unread = await Message.countDocuments({ receiver: callerId, sender: receiverId, read: false });
    io.to(`user_${String(callerId)}`).emit('newMessage', {
      message, unreadCount: unread, senderId: String(receiverId), hasMedia: false, mediaType: null,
    });
    io.to(`user_${String(receiverId)}`).emit('messageSent', {
      message, unreadCount: 0, receiverId: String(callerId), hasMedia: false, mediaType: null,
    });
  }
  return message;
};
```
`module.exports = { LEGACY_STATUS, MAX_DECLINE_MESSAGE, fallbackText, buildCallData, writeCallMessage, writeDeclineMessage };`
`controllers/callController.js` — add `const callMessageService = require('../services/callMessageService');` and `const { getIo } = require('../lib/callIo');`, then replace `declineCall`:
```js
/**
 * @route   POST /api/v1/calls/:id/decline   body { deviceId?, message? (≤ 200) }
 */
exports.declineCall = asyncHandler(async (req, res, next) => {
  const userId = req.user.id;
  const raw = req.body && req.body.message;
  const text = typeof raw === 'string' ? raw.trim() : '';
  if (text.length > callMessageService.MAX_DECLINE_MESSAGE) {
    return next(new ErrorResponse('message must be 200 characters or fewer', 400));
  }
  const call = await callStateService.findCall(req.params.id);
  if (!call) return next(new ErrorResponse('Call not found', 404));
  const receiverId = callStateService.receiverOf(call);
  if (!receiverId || String(receiverId) !== userId) {
    return next(new ErrorResponse('Not authorized to decline this call', 403));
  }
  let updated;
  try {
    updated = await callStateService.transition(call._id, 'decline', { by: userId, deviceId: deviceIdFrom(req) });
  } catch (err) {
    if (err instanceof CallStateError) return respondCallState(res, err);
    throw err;
  }
  if (text) {
    try {
      await callMessageService.writeDeclineMessage(updated, text, req.app.get('io') || getIo());
    } catch (err) {
      console.error('[calls.decline] decline message failed:', err.message);
    }
  }
  return res.status(200).json({ success: true, data: { call: updated } });
});
```
Update the `routes/calls.js` doc comment for `/:id/decline` to `body { deviceId?, message? ≤ 200 }`.
- [ ] **Step 4: run, pass.** Same command → 2/2; also re-run `test/callController.test.js` and `test/callMessages.test.js` → green.
- [ ] **Step 5: commit** (BACKEND). `git add services/callMessageService.js controllers/callController.js routes/calls.js test/callPhase2.test.js docs/REMAINING_WORK.md` — REMAINING_WORK: under calls add "[ ] Calls Phase 2 backend" with "[x] decline with message" and open "[ ] calls on/off + quiet hours, [ ] upgrade, [ ] missed push actions, [ ] deploy". Message: `feat(calls): decline with a message` — body: endpoint, ordering after the call message, 200 limit; "Open: CALLEE_UNAVAILABLE, upgrade, missed push actions, deploy." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C2: Backend — calls on/off and quiet hours → `409 CALLEE_UNAVAILABLE`
**Files:** `models/User.js`, `controllers/notifications.js`, `services/callStateService.js`, `controllers/callController.js`, `routes/calls.js` (doc), `test/callPhase2.test.js`, `docs/REMAINING_WORK.md`
**Interfaces:** Consumes `lib/quietHours.isInQuietHours(user, now)`. Produces `User.notificationSettings.allowCalls` (Boolean, default true, writable via `PUT /notifications/settings`), `callStateService.recordUnavailable({ callerId, receiverId, type, now })`, initiate → `409 { success:false, code:'CALLEE_UNAVAILABLE', error }` with a `busy/unavailable` Call, no ring, no message, no push.

- [ ] **Step 1: failing test** — append to `test/callPhase2.test.js`:
```js
const hhmm = (d) => d.toISOString().slice(11, 16);
const quietNow = (now = new Date()) => ({
  enabled: true,
  start: hhmm(new Date(now.getTime() - 3600e3)),
  end: hhmm(new Date(now.getTime() + 3600e3)),
  timezone: 'UTC',
});

const assertUnavailable = async (a, b) => {
  io.sent.length = 0; pushes.length = 0;
  const res = await run(ctl.initiateCall, a, { body: { receiverId: String(b._id), type: 'audio' } });
  assert.equal(res.status, 409);
  assert.equal(res.body.code, 'CALLEE_UNAVAILABLE');
  const rec = await Call.findOne({ participants: { $all: [a._id, b._id] } }).sort({ createdAt: -1 });
  assert.equal(rec.status, 'busy');
  assert.equal(rec.endReason, 'unavailable');
  assert.equal(io.eventsNamed('call:incoming').length, 0);
  assert.equal(pushes.length, 0);
  assert.equal(await Message.countDocuments({ 'media.callData.callId': String(rec._id) }), 0);
  assert.equal((await User.findById(a._id)).activeCallId, null);
  assert.equal((await User.findById(b._id)).activeCallId, null);
};

test('calls switched off → 409 CALLEE_UNAVAILABLE, unavailable record, nothing rings', async () => {
  const a = await user('ca'); const b = await user('cb', { notificationSettings: { allowCalls: false } });
  await assertUnavailable(a, b);
});

test('inside quiet hours → CALLEE_UNAVAILABLE; quiet hours off → rings', async () => {
  const a = await user('qa'); const b = await user('qb', { quietHours: quietNow() });
  await assertUnavailable(a, b);
  await User.updateOne({ _id: b._id }, { $set: { 'quietHours.enabled': false } });
  const id = await ring(a, b);
  assert.equal((await Call.findById(id)).status, 'ringing');
});

test('PUT /notifications/settings writes allowCalls', async () => {
  const notifications = require('../controllers/notifications');
  const u = await user('sa');
  assert.equal((await User.findById(u._id)).notificationSettings.allowCalls, true);
  const res = await asHandler(notifications.updateSettings)({ user: { id: String(u._id) }, body: { allowCalls: false } });
  assert.equal(res.status, 200);
  assert.equal((await User.findById(u._id)).notificationSettings.allowCalls, false);
});
```
- [ ] **Step 2: run, expected fail.** → 200 ≠ 409; `allowCalls` undefined.
- [ ] **Step 3: implement.**
  `models/User.js`, inside `notificationSettings` after `showPreview`:
```js
    // Calls Phase 2: false = nobody can call this user (initiate → 409
    // CALLEE_UNAVAILABLE). Separate from notificationPreferences.calls, which
    // only switches the call pushes.
    allowCalls: {
      type: Boolean,
      default: true
    },
```
  `controllers/notifications.js` `updateSettings`: add `'allowCalls'` to `allowedFields`.
  `services/callStateService.js` — add and export:
```js
/**
 * Phase 2: the receiver has calls off or is in quiet hours. A terminal
 * busy/unavailable record for the caller's history only — outcomeFor() is
 * null, so no call message, no push, no event, and nobody is claimed.
 */
const recordUnavailable = ({ callerId, receiverId, type, now = new Date() }) => Call.create({
  participants: [callerId, receiverId],
  initiator: callerId,
  type,
  status: 'busy',
  endReason: 'unavailable',
  startTime: now,
  endTime: now,
  duration: 0,
  callUuid: crypto.randomUUID(),
});
```
  `controllers/callController.js` — `const { isInQuietHours } = require('../lib/quietHours');`; in `initiateCall` right after the conversation-start check and before `startCall`:
```js
  const callsOff = receiver.notificationSettings && receiver.notificationSettings.allowCalls === false;
  if (callsOff || isInQuietHours(receiver, new Date())) {
    await callStateService.recordUnavailable({ callerId, receiverId, type });
    return res.status(409).json({
      success: false,
      error: `${receiver.name || 'They'} isn't taking calls right now`,
      code: 'CALLEE_UNAVAILABLE',
    });
  }
```
  `routes/calls.js` initiate doc: add `409 CALLEE_UNAVAILABLE (calls off / quiet hours)`.
- [ ] **Step 4: run, pass.** `test/callPhase2.test.js` 5/5; re-run `test/callController.test.js`, `test/callHistory.test.js`, `test/quietHours.test.js` → green (history already excludes `endReason: 'unavailable'`).
- [ ] **Step 5: commit** (BACKEND). `git add models/User.js controllers/notifications.js services/callStateService.js controllers/callController.js routes/calls.js test/callPhase2.test.js docs/REMAINING_WORK.md` — tick "calls on/off + quiet hours". Message: `feat(calls): calls off and quiet hours answer CALLEE_UNAVAILABLE` — body notes quiet hours now also hold calls for users who enabled them for notifications; "Open: upgrade, missed push actions, deploy." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C3: Backend — `POST /calls/:id/upgrade` (voice → video)
**Files:** `services/callStateService.js`, `services/callEvents.js`, `controllers/callController.js`, `routes/calls.js`, `test/callPhase2.test.js`, `docs/REMAINING_WORK.md`
**Interfaces:** Produces `callStateService.upgradeToVideo(callId) → { call, changed }` (throws `CallStateError` unless active), `callEvents.emitState(io, call, ctx)`, `POST /api/v1/calls/:id/upgrade` → 200 `{ data: { call } }` (idempotent), 403 non-participant, 409 `CALL_STATE` when not active; emits only `call:state` (with `type: 'video'`), never `call:accepted`.

- [ ] **Step 1: failing test** — append:
```js
const activeCall = async (a, b) => {
  const id = await ring(a, b, 'audio');
  const acc = await run(ctl.acceptCall, b, { params: { id } });
  assert.equal(acc.status, 200);
  io.sent.length = 0;
  return id;
};

test('upgrade: active voice call becomes video; call:state carries the type; idempotent', async () => {
  const a = await user('ua'); const b = await user('ub');
  const id = await activeCall(a, b);
  const res = await run(ctl.upgradeCall, a, { params: { id } });
  assert.equal(res.status, 200);
  assert.equal(res.body.data.call.type, 'video');
  const states = io.eventsNamed('call:state');
  assert.equal(states.length, 1);
  assert.equal(states[0].payload.type, 'video');
  assert.equal(states[0].payload.status, 'active');
  assert.deepEqual(states[0].rooms.sort(), [`user_${a._id}`, `user_${b._id}`].sort());
  assert.equal(io.eventsNamed('call:accepted').length, 0);
  const again = await run(ctl.upgradeCall, b, { params: { id } });
  assert.equal(again.status, 200);
  assert.equal(io.eventsNamed('call:state').length, 1, 'no second emit');
  await run(ctl.endCall, a, { params: { id } });
  const msg = await Message.findOne({ 'media.callData.callId': id });
  assert.equal(msg.media.callData.type, 'video');
  assert.match(msg.message, /^📞 Video call · /);
});

test('upgrade: ringing → 409 CALL_STATE; stranger → 403', async () => {
  const a = await user('ra'); const b = await user('rb'); const c = await user('rc');
  const id = await ring(a, b);
  const ringing = await run(ctl.upgradeCall, a, { params: { id } });
  assert.equal(ringing.status, 409);
  assert.equal(ringing.body.code, 'CALL_STATE');
  const stranger = await run(ctl.upgradeCall, c, { params: { id } });
  assert.equal(stranger.status, 403);
});
```
- [ ] **Step 2: run, expected fail.** `ctl.upgradeCall` is not a function.
- [ ] **Step 3: implement.** `services/callStateService.js`, add + export:
```js
/** Phase 2: voice → video while active. Idempotent; never changes status. */
const upgradeToVideo = async (callId) => {
  const updated = await Call.findOneAndUpdate(
    { _id: callId, status: 'active', type: 'audio' },
    { $set: { type: 'video' } },
    { new: true }
  );
  if (updated) return { call: updated, changed: true };
  const current = await Call.findById(callId);
  if (!current) throw new CallStateError('not_found');
  if (current.status === 'active' && current.type === 'video') return { call: current, changed: false };
  throw new CallStateError(current.status);
};
```
  `services/callEvents.js`, add + export (only the new event: `call:accepted` would restart live builds' connect flow):
```js
/** A non-status change (Phase 2 upgrade): call:state to both, nothing legacy. */
const emitState = (io, call, ctx = {}) => {
  if (!io) return;
  io.to(roomOf(call.initiator)).to(roomOf(receiverOf(call))).emit('call:state', statePayload(call, ctx));
};
```
  `controllers/callController.js` — `const { emitState } = require('../services/callEvents');` and:
```js
/**
 * @desc    Camera turned on during a voice call: the call becomes video, so
 *          history and the call bubble say "Video call".
 * @route   POST /api/v1/calls/:id/upgrade
 */
exports.upgradeCall = asyncHandler(async (req, res, next) => {
  const userId = req.user.id;
  const call = await callStateService.findCall(req.params.id);
  if (!call) return next(new ErrorResponse('Call not found', 404));
  if (!isParticipant(call, userId)) return next(new ErrorResponse('Not authorized to change this call', 403));
  try {
    const { call: updated, changed } = await callStateService.upgradeToVideo(call._id);
    if (changed) emitState(req.app.get('io') || getIo(), updated, { by: userId });
    return res.status(200).json({ success: true, data: { call: updated } });
  } catch (err) {
    if (err instanceof CallStateError) return respondCallState(res, err);
    throw err;
  }
});
```
  `routes/calls.js`: import `upgradeCall`; add before `module.exports`:
```js
/**
 * @route   POST /api/v1/calls/:id/upgrade
 * @desc    Active voice call → video (:id = Mongo id or callUuid). Emits
 *          call:state with type. 409 CALL_STATE unless active.
 */
router.post('/:id/upgrade', upgradeCall);
```
- [ ] **Step 4: run, pass.** `test/callPhase2.test.js` 7/7; `test/callEvents.test.js` green.
- [ ] **Step 5: commit** (BACKEND). `git add services/callStateService.js services/callEvents.js controllers/callController.js routes/calls.js test/callPhase2.test.js docs/REMAINING_WORK.md` — tick "upgrade". Message: `feat(calls): upgrade an active voice call to video` — "Open: missed push actions, deploy." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C4: Backend — missed-call push actions
**Files:** `lib/pushCapabilities.js`, `services/fcmService.js`, `services/callPushService.js`, create `test/callMissedActions.test.js`, `docs/REMAINING_WORK.md`
**Interfaces:** Produces missed-call push data `{ type:'missed_call', callId, callUuid, callerId, callerName, callType, actions:['call_back','message'] }` (on the wire FCM stringifies the array to `'["call_back","message"]'`); iOS APNs `aps.category = 'MISSED_CALL'`; Android tokens that declared capability `missed_call_actions` get a **data-only** high-priority message with `title`/`body` in data (the app draws the notification with its buttons); every other token keeps today's visible push. `fcmService.sendToUser(userId, notification, data, { dataOnly?: (token) => bool })`.

- [ ] **Step 1: failing test** — `test/callMissedActions.test.js`:
```js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { stub } = require('./helpers/authHarness');
const { startDb, stopDb, makeUser, silence } = require('./helpers/callKit');

const fcmSent = [];
stub('config/firebase', {
  messaging: () => ({
    sendEach: async (messages) => {
      fcmSent.push(...messages);
      return { successCount: messages.length, failureCount: 0, responses: messages.map(() => ({ success: true })) };
    },
  }),
});

let restore, push, caps;
test.before(async () => {
  restore = silence();
  await startDb('callMissedActions');
  push = require('../services/callPushService');
  caps = require('../lib/pushCapabilities');
});
test.after(async () => { await stopDb(); restore(); });

const call = { _id: '0123456789abcdef01234567', callUuid: '6f1c2b8e-3c1d-4a8e-9b7f-0a1b2c3d4e5f', type: 'video' };
const caller = { _id: 'aaaaaaaaaaaaaaaaaaaaaaaa', name: 'Ada', images: [] };

test('missed_call_actions is a known capability', () => {
  assert.deepEqual(caps.parseCapabilities(['missed_call_actions', 'x']), ['missed_call_actions']);
});

test('missed push: actions in data, MISSED_CALL on iOS, data-only only for capable Android', async () => {
  const receiver = await makeUser('mr', {
    preferredLocale: 'en',
    fcmTokens: [
      { token: 'a-new', platform: 'android', deviceId: 'd1', active: true, capabilities: ['call_cancel', 'missed_call_actions'] },
      { token: 'a-old', platform: 'android', deviceId: 'd2', active: true, capabilities: [] },
      { token: 'i-1', platform: 'ios', deviceId: 'd3', active: true, capabilities: ['missed_call_actions'] },
    ],
  });
  await push.sendMissedCall({ call, caller, receiver });
  const by = Object.fromEntries(fcmSent.map((m) => [m.token, m]));
  assert.equal(by['a-new'].notification, undefined);
  assert.equal(by['a-new'].android.priority, 'high');
  assert.equal(by['a-new'].data.title, '📞 Ada');
  assert.equal(by['a-new'].data.body, 'Missed video call');
  assert.equal(by['a-new'].data.actions, '["call_back","message"]');
  assert.equal(by['a-new'].data.callType, 'video');
  assert.ok(by['a-old'].notification, 'live Android builds keep the visible push');
  assert.equal(by['i-1'].apns.payload.aps.category, 'MISSED_CALL');
  assert.equal(by['i-1'].data.callerId, caller._id);
});
```
- [ ] **Step 2: run, expected fail.** `parseCapabilities` drops `missed_call_actions`; `a-new` has a `notification`; category is `missed_call`.
- [ ] **Step 3: implement.**
  `lib/pushCapabilities.js`: `const KNOWN_CAPABILITIES = ['call_cancel', 'missed_call_actions'];`
  `services/fcmService.js`: add `missed_call: 'MISSED_CALL',` to `TYPE_TO_CATEGORY`; add
```js
/**
 * Android data-only: the app draws the notification itself (with action
 * buttons FCM cannot carry). Used only for tokens that declared they can.
 */
const _buildDataOnlyMessage = (token, notification, data) => ({
  token,
  data: _sanitizeData({ ...data, title: notification.title, body: notification.body, imageUrl: notification.imageUrl }),
  android: { priority: 'high' },
});
```
  change the signature to `const sendToUser = async (userId, notification, data = {}, options = {}) => {` and the message build to
```js
    const messages = activeTokens.map((tokenData) => (
      typeof options.dataOnly === 'function' && options.dataOnly(tokenData)
        ? _buildDataOnlyMessage(tokenData.token, notification, data)
        : _buildMessage(tokenData.token, notification, data, tokenData.platform, user.badges)
    ));
```
  `services/callPushService.js`: `const MISSED_ACTIONS_CAPABILITY = 'missed_call_actions';` (export it) and in `sendMissedCall` add `actions: ['call_back', 'message'],` to the data object and pass a 4th argument:
```js
    { dataOnly: (t) => t.platform === 'android' && Array.isArray(t.capabilities) && t.capabilities.includes(MISSED_ACTIONS_CAPABILITY) }
```
- [ ] **Step 4: run, pass.** `test/callMissedActions.test.js` 2/2; `test/callPush.test.js` green (its stub ignores the 4th argument).
- [ ] **Step 5: commit** (BACKEND). `git add lib/pushCapabilities.js services/fcmService.js services/callPushService.js test/callMissedActions.test.js docs/REMAINING_WORK.md` — tick "missed push actions"; open "[ ] deploy Calls Phase 2 backend (additive; safe before the app)". Message: `feat(calls): missed-call push carries Call back / Message actions` + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C5: App — call API + CallManager plumbing, Phase 2 strings
**Files:** `lib/services/call/call_api.dart`, `lib/services/call_manager.dart`, `lib/services/call/call_launcher.dart`, `lib/l10n/app_*.arb` (19) + generated, `docs/l10n/native-qa-strings-2026-10.csv`, `test/helpers/call_fakes.dart`, `test/services/call_api_test.dart`, create `test/services/call_phase2_test.dart`, `test/l10n/call_strings_test.dart`, `docs/REMAINING_WORK.md`
**Interfaces:** Consumes C1–C3 endpoints. Produces `CallApi.decline(callId, {deviceId, message})`, `CallApi.upgrade(callId)`, `CallApiResult.isCalleeUnavailable`, `InitiateStatus.calleeUnavailable`, `CallManager.rejectCall({String? message})`, `CallManager.upgradeToVideo() → Future<bool>`, `CallManager.onCallTypeChanged`; l10n keys below.

Strings (app_en.arb; 18 locales drafted + CSV rows per the Standard L procedure):
| key | English |
|---|---|
| `callUnavailable` | `{name} isn't taking calls right now` (`name`: String) |
| `callDeclineWithMessage` | `Message` |
| `callDeclineSheetTitle` | `Decline with a message` |
| `callDeclineCannedLater` | `Can't talk now. I'll call you back.` |
| `callDeclineCannedText` | `Can't talk now. Text me?` |
| `callDeclineCustomHint` | `Write a message…` |
| `callDeclineSend` | `Send` |
| `callBackAction` | `Call back` |
| `callMessageAction` | `Message` |
| `callsAllowTitle` | `Allow calls` |
| `callsAllowSubtitle` | `When off, calls to you don't ring. Callers see that you're not taking calls.` |
| `callsQuietHoursNote` | `Calls are held during quiet hours too.` |
| `callTurnOnCamera` | `Camera` |

- [ ] **Step 1: failing tests.**
  `test/helpers/call_fakes.dart` — in `FakeCallApi` add `final Map<String, String?> declineMessages = {};`, `CallApiResult upgradeResult = const CallApiResult(ok: true, statusCode: 200);` and change/add:
```dart
  @override
  Future<CallApiResult> decline(String callId, {String? deviceId, String? message}) async {
    calls.add('decline:$callId');
    deviceIds['decline'] = deviceId;
    declineMessages[callId] = message;
    return declineResult;
  }

  @override
  Future<CallApiResult> upgrade(String callId) async {
    calls.add('upgrade:$callId');
    return upgradeResult;
  }
```
  `test/services/call_api_test.dart` — add:
```dart
  test('decline sends a trimmed message; upgrade posts; CALLEE_UNAVAILABLE is recognised', () async {
    final seen = <http.Request>[];
    Future<CallApiResult> send(Future<CallApiResult> Function() body, {int status = 200, Map<String, dynamic>? json}) =>
        http.runWithClient(body, () => MockClient((req) async {
              seen.add(req);
              return http.Response(jsonEncode(json ?? {'success': true, 'data': {}}), status);
            }));
    await send(() => RestCallApi().decline('c1', deviceId: 'd', message: '  Later  '));
    expect(jsonDecode(seen.last.body), {'deviceId': 'd', 'message': 'Later'});
    await send(() => RestCallApi().upgrade('c1'));
    expect(seen.last.url.toString(), 'http://api.test/api/v1/calls/c1/upgrade');
    final r = await send(() => RestCallApi().initiate(receiverId: 'u', type: CallType.audio),
        status: 409, json: {'success': false, 'error': "Bo isn't taking calls right now", 'code': 'CALLEE_UNAVAILABLE'});
    expect(r.isCalleeUnavailable, isTrue);
  });
```
  `test/services/call_phase2_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  Future<CallHarness> connectedVoice() async {
    final h = CallHarness();
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    return h;
  }

  test('rejectCall(message:) forwards the message', () async {
    final h = CallHarness();
    await h.ringIncoming();
    await h.manager.rejectCall(message: 'Later');
    expect(h.api.calls, contains('decline:call-1'));
    expect(h.api.declineMessages['call-1'], 'Later');
  });

  test('409 CALLEE_UNAVAILABLE → InitiateStatus.calleeUnavailable, no call left', () async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLEE_UNAVAILABLE');
    expect((await h.startOutgoing()).status, InitiateStatus.calleeUnavailable);
    expect(h.manager.currentCall, isNull);
  });

  test('call:state active+video on a connected call changes the type only', () async {
    final h = await connectedVoice();
    final types = <CallType>[];
    h.manager.onCallTypeChanged = types.add;
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.manager.currentCall!.status, CallStatus.connected);
    expect(types, [CallType.video]);
    expect(h.finishes, isEmpty);
  });

  test('upgradeToVideo: camera on, POST /upgrade, type video; refused without permission', () async {
    final h = await connectedVoice();
    expect(await h.manager.upgradeToVideo(), isTrue);
    expect(h.liveKit.cameraCalls, [true]);
    expect(h.api.calls, contains('upgrade:call-1'));
    expect(h.manager.currentCall!.callType, CallType.video);
    expect(h.manager.isVideoEnabled, isTrue);

    final h2 = await connectedVoice();
    h2.platform.permissionsGranted = false;
    expect(await h2.manager.upgradeToVideo(), isFalse);
    expect(h2.liveKit.cameraCalls, isEmpty);
  });
}
```
  `test/l10n/call_strings_test.dart` — append the 13 keys above to `_callKeys`, and in 'generated getters…' add `expect(en.callUnavailable('Bo'), "Bo isn't taking calls right now");` and `expect(map['callUnavailable'], contains('{name}'), reason: file.path);` inside the locale loop.
- [ ] **Step 2: run, expected fail.** `flutter test test/services/call_phase2_test.dart test/services/call_api_test.dart test/l10n/call_strings_test.dart` → compile errors (`upgrade`, `message:`, `calleeUnavailable`, `onCallTypeChanged`), missing keys.
- [ ] **Step 3: implement.**
  `call_api.dart`: `bool get isCalleeUnavailable => statusCode == 409 && errorCode == 'CALLEE_UNAVAILABLE';`; abstract `Future<CallApiResult> decline(String callId, {String? deviceId, String? message});` and `Future<CallApiResult> upgrade(String callId);`; `RestCallApi`:
```dart
  @override
  Future<CallApiResult> decline(String callId, {String? deviceId, String? message}) async {
    final text = message?.trim();
    return CallApiResult.fromResponse(await _client.post('calls/$callId/decline', body: {
      ..._device(deviceId),
      if (text != null && text.isNotEmpty) 'message': text,
    }));
  }

  @override
  Future<CallApiResult> upgrade(String callId) async =>
      CallApiResult.fromResponse(await _client.post('calls/$callId/upgrade'));
```
  `call_manager.dart`: `enum InitiateStatus { started, calleeBusy, calleeUnavailable, callerBusy, permissionDenied, failed }`; callback `void Function(CallType type)? onCallTypeChanged;`; in `initiateCall` after the busy line: `if (res.isCalleeUnavailable) return const InitiateResult(InitiateStatus.calleeUnavailable);`; `rejectCall`:
```dart
  Future<void> rejectCall({String? message}) async {
    final call = currentCall;
    if (call == null) {
      _closeNow();
      return;
    }
    if (call.callId.isNotEmpty) {
      final deviceId = await _deps.platform.deviceId();
      unawaited(_deps.api.decline(call.callId, deviceId: deviceId, message: message));
      if (!_sameId(currentCall?.callId, call.callId)) return;
    }
    onCallRejected?.call(call.copyWith(status: CallStatus.rejected));
    await _finish(CallExitReason.declined);
  }
```
  In `_onCallState`, first lines of `if (status == 'active') {`:
```dart
      // Already past ringing: a repeat 'active' is a Phase 2 type change
      // (voice → video), never a second accept.
      if (cur.status != CallStatus.ringing) {
        if (m['type'] == 'video' && cur.callType != CallType.video) {
          currentCall = cur.copyWith(callType: CallType.video);
          onCallTypeChanged?.call(CallType.video);
        }
        return;
      }
```
  New method next to `setVideoEnabled`:
```dart
  /// Camera on during a voice call (either side). Publishes video and makes
  /// the call a video call on the server so history says "Video call".
  Future<bool> upgradeToVideo() async {
    final cur = currentCall;
    if (cur == null || cur.status == CallStatus.ringing) return false;
    if (!await _deps.platform.ensurePermissions(video: true)) {
      onCallError?.call(await _deps.platform.permissionError(video: true, accepting: false));
      return false;
    }
    if (!_sameId(currentCall?.callId, cur.callId)) return false;
    final wasVoice = cur.callType != CallType.video;
    setVideoEnabled(true);
    if (wasVoice) {
      currentCall = cur.copyWith(callType: CallType.video);
      onCallTypeChanged?.call(CallType.video);
      unawaited(_deps.platform.setWakelock(true));
      if (_deps.isAppResumed()) unawaited(_deps.platform.startCallService(video: true));
      unawaited(_deps.api.upgrade(cur.callId));
    }
    return true;
  }
```
  `call_launcher.dart` switch: `case InitiateStatus.calleeUnavailable: _snack(context, l10n.callUnavailable(userName));`
  Strings: Standard L procedure for the 13 keys (`callUnavailable` metadata `{"name": {"type": "String"}}`).
- [ ] **Step 4: run, pass.** `flutter gen-l10n && flutter test test/services/ test/screens/ test/l10n/` → green; `flutter analyze lib/services` clean.
- [ ] **Step 5: commit.** `git add lib/services/call/call_api.dart lib/services/call_manager.dart lib/services/call/call_launcher.dart lib/l10n docs/l10n/native-qa-strings-2026-10.csv test/helpers/call_fakes.dart test/services/call_api_test.dart test/services/call_phase2_test.dart test/l10n/call_strings_test.dart docs/REMAINING_WORK.md` — REMAINING_WORK §0b: split "Phase 2" into sub-items, tick "app plumbing". Message: `feat(calls): Phase 2 call API — decline message, upgrade, unavailable callee` — "Open: decline sheet, push actions, settings, camera button, self-view, device QA." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C6: App — decline-with-message sheet on `IncomingCallScreen`
**Files:** `lib/screens/incoming_call_screen.dart`, create `lib/widgets/call/decline_message_sheet.dart`, `test/screens/incoming_call_screen_test.dart`, `docs/REMAINING_WORK.md`
**Interfaces:** Consumes `CallManager.rejectCall(message:)`, keys `callDeclineWithMessage`…`callDeclineSend`. Produces `showDeclineMessageSheet(BuildContext) → Future<String?>`.

- [ ] **Step 1: failing test** — add to `test/screens/incoming_call_screen_test.dart`:
```dart
  testWidgets('Message → canned reply declines with that text and closes', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Decline with a message'), findsOneWidget);
    await tester.tap(find.text("Can't talk now. I'll call you back."));
    await tester.pumpAndSettle();
    expect(h.api.declineMessages['call-1'], "Can't talk now. I'll call you back.");
    expect(find.byType(IncomingCallScreen), findsNothing);
  });

  testWidgets('custom reply is capped at 200 characters and sent', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'y' * 250);
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(h.api.declineMessages['call-1'], 'y' * 200);
  });
```
- [ ] **Step 2: run, expected fail.** `flutter test test/screens/incoming_call_screen_test.dart` → no "Message" widget.
- [ ] **Step 3: implement.** `lib/widgets/call/decline_message_sheet.dart`:
```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

const int kDeclineMessageMax = 200;

/// Two canned replies + a custom one. Resolves to the text, or null if dismissed.
Future<String?> showDeclineMessageSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _DeclineMessageSheet(),
  );
}

class _DeclineMessageSheet extends StatefulWidget {
  const _DeclineMessageSheet();
  @override
  State<_DeclineMessageSheet> createState() => _DeclineMessageSheetState();
}

class _DeclineMessageSheetState extends State<_DeclineMessageSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canned = [l10n.callDeclineCannedLater, l10n.callDeclineCannedText];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(l10n.callDeclineSheetTitle, style: Theme.of(context).textTheme.titleMedium)),
          for (final text in canned)
            ListTile(title: Text(text), onTap: () => Navigator.pop(context, text)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: kDeclineMessageMax,
                  decoration: InputDecoration(hintText: l10n.callDeclineCustomHint, counterText: ''),
                ),
              ),
              TextButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) Navigator.pop(context, text);
                },
                child: Text(l10n.callDeclineSend),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
```
  `incoming_call_screen.dart`: in the actions `Row`, between Decline and Accept, add
```dart
                    _CallActionButton(
                      icon: Icons.message_rounded,
                      label: l10n.callDeclineWithMessage,
                      color: Colors.blueGrey,
                      onPressed: _busy ? null : _declineWithMessage,
                    ),
```
  and in the state:
```dart
  Future<void> _declineWithMessage() async {
    final text = await showDeclineMessageSheet(context);
    if (text == null || !mounted) return;
    await CallManager().rejectCall(message: text);
  }
```
  (`TextField.maxLength` truncates the 250 typed characters to 200.)
- [ ] **Step 4: run, pass.** `flutter test test/screens/incoming_call_screen_test.dart` green; `flutter analyze lib/screens lib/widgets/call` clean.
- [ ] **Step 5: commit.** `git add lib/screens/incoming_call_screen.dart lib/widgets/call/decline_message_sheet.dart test/screens/incoming_call_screen_test.dart docs/REMAINING_WORK.md` — tick "decline with message (app)". Message: `feat(calls): decline an incoming call with a message` + open items + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C7: App — missed-call push actions (iOS + Android), Call back from a killed app
**Files:** create `lib/services/call/missed_call_actions.dart`, `lib/services/notification_service.dart`, `lib/services/notification_router.dart`, `lib/services/notification_api_client.dart`, `lib/router/app_router.dart`, `lib/pages/chat/chat_screen_wrapper.dart`, `ios/Runner/AppDelegate.swift`, create `test/services/missed_call_actions_test.dart`, `docs/REMAINING_WORK.md`
**Interfaces:** Consumes C4 payload, `CallLauncher.start`, keys `callBackAction`/`callMessageAction`. Produces capability `'missed_call_actions'`; `missedCallActionRoute(Map data, String? actionId) → String?`; route `/chat/:userId?call=audio|video`; `ChatScreenWrapper(autoCall:)`; MethodChannel `bananatalk/missed_call_actions` (`takePending` → `{action, callerId, callType}` or null; native → Dart `action` with the same map).

- [ ] **Step 1: failing test** — `test/services/missed_call_actions_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/call/missed_call_actions.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';

void main() {
  const data = {'type': 'missed_call', 'callerId': 'u1', 'callType': 'video', 'actions': '["call_back","message"]'};

  test('Call back opens the chat and starts a call of the same type', () {
    expect(missedCallActionRoute(data, 'call_back'), '/chat/u1?call=video');
    expect(missedCallActionRoute({...data, 'callType': 'audio'}, 'call_back'), '/chat/u1?call=audio');
  });

  test('Message opens the chat; plain tap and other types are not ours', () {
    expect(missedCallActionRoute(data, 'message'), '/chat/u1');
    expect(missedCallActionRoute(data, null), isNull);
    expect(missedCallActionRoute({...data, 'type': 'chat_message'}, 'call_back'), isNull);
    expect(missedCallActionRoute({...data, 'callerId': ''}, 'call_back'), isNull);
  });

  test('actions parse from JSON or a comma list; this build declares the capability', () {
    expect(missedCallActions(data), ['call_back', 'message']);
    expect(missedCallActions({'actions': 'call_back,message'}), ['call_back', 'message']);
    expect(missedCallActions({}), isEmpty);
    expect(kCallPushCapabilities, containsAll(['call_cancel', 'missed_call_actions']));
  });
}
```
- [ ] **Step 2: run, expected fail.** `flutter test test/services/missed_call_actions_test.dart` → file not found / capability missing.
- [ ] **Step 3: implement.**
  `lib/services/call/missed_call_actions.dart`:
```dart
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String kMissedCallCategory = 'MISSED_CALL';
const String kMissedCallBack = 'call_back';
const String kMissedCallMessage = 'message';

List<String> missedCallActions(Map<String, dynamic> data) {
  final raw = data['actions'];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is! String || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.map((e) => e.toString()).toList();
  } catch (_) {}
  return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

/// Where a missed-call action goes. Call back carries `?call=` so the chat
/// screen starts the call once it has the user (works from a killed app).
String? missedCallActionRoute(Map<String, dynamic> data, String? actionId) {
  if (data['type']?.toString() != 'missed_call') return null;
  final callerId = data['callerId']?.toString() ?? '';
  if (callerId.isEmpty) return null;
  if (actionId == kMissedCallBack) {
    final type = data['callType']?.toString() == 'video' ? 'video' : 'audio';
    return '/chat/$callerId?call=$type';
  }
  if (actionId == kMissedCallMessage) return '/chat/$callerId';
  return null;
}

/// Android: the push is data-only for this build, so draw it with buttons.
Future<void> showMissedCallNotification(
  FlutterLocalNotificationsPlugin plugin,
  Map<String, dynamic> data, {
  required String callBackLabel,
  required String messageLabel,
}) async {
  if (!Platform.isAndroid) return;
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(kMissedCallBack, callBackLabel, showsUserInterface: true),
        AndroidNotificationAction(kMissedCallMessage, messageLabel, showsUserInterface: true),
      ],
    ),
  );
  await plugin.show(
    (data['callId']?.toString() ?? '').hashCode,
    data['title']?.toString() ?? '',
    data['body']?.toString() ?? '',
    details,
    payload: jsonEncode(data),
  );
}

/// iOS remote-notification action taps are caught natively (AppDelegate) and
/// handed over on this channel; a cold start asks for the pending one.
const MethodChannel missedCallActionsChannel = MethodChannel('bananatalk/missed_call_actions');
```
  `notification_api_client.dart`: `const List<String> kCallPushCapabilities = ['call_cancel', 'missed_call_actions'];` (update the doc comment).
  `notification_service.dart`:
  - top-level helper (usable from the background isolate):
```dart
AppLocalizations notificationL10n() {
  final locale = PlatformDispatcher.instance.locale;
  return AppLocalizations.delegate.isSupported(locale)
      ? lookupAppLocalizations(locale)
      : lookupAppLocalizations(const Locale('en'));
}
```
  - add to `notificationCategories`:
```dart
        DarwinNotificationCategory(
          kMissedCallCategory,
          actions: [
            DarwinNotificationAction.plain(kMissedCallBack, l10n.callBackAction,
                options: {DarwinNotificationActionOption.foreground}),
            DarwinNotificationAction.plain(kMissedCallMessage, l10n.callMessageAction,
                options: {DarwinNotificationActionOption.foreground}),
          ],
        ),
```
    (`final l10n = notificationL10n();` at the top of `_initializeLocalNotifications`; the categories list stops being `const`.)
  - `firebaseMessagingBackgroundHandler`: before the `incoming_call` branch,
```dart
  if (type == 'missed_call' && message.notification == null) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    final l10n = notificationL10n();
    await showMissedCallNotification(plugin, Map<String, dynamic>.from(message.data),
        callBackLabel: l10n.callBackAction, messageLabel: l10n.callMessageAction);
    return;
  }
```
  - foreground handler: where `notificationType == 'missed_call'`, after the badge refresh: if `message.notification == null` (data-only) → `await showMissedCallNotification(_localNotifications, data, …); return;`; else (iOS foreground) pass `DarwinNotificationDetails(categoryIdentifier: kMissedCallCategory, …)` in `_showLocalNotification` when `message.data['type'] == 'missed_call'`.
  - after `_localNotifications.initialize(...)`: deliver a killed-app action tap once the router exists:
```dart
    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationTap(response));
    }
    missedCallActionsChannel.setMethodCallHandler((call) async {
      if (call.method == 'action' && call.arguments is Map) {
        // Clear the native copy so the next cold start does not replay it.
        unawaited(missedCallActionsChannel.invokeMethod('takePending'));
        _routeNativeMissedCallAction(Map<String, dynamic>.from(call.arguments as Map));
      }
    });
    final pending = await missedCallActionsChannel.invokeMethod<Map>('takePending').catchError((_) => null);
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _routeNativeMissedCallAction(Map<String, dynamic>.from(pending)));
    }
```
    with
```dart
  void _routeNativeMissedCallAction(Map<String, dynamic> m) {
    NotificationRouter.handleNotification(null, {
      'type': 'missed_call', 'callerId': m['callerId'], 'callType': m['callType'], '_actionId': m['action'],
    });
  }
```
  `notification_router.dart`, right after the `actionId == 'profile'` block:
```dart
    final missedRoute = missedCallActionRoute(data, actionId);
    if (missedRoute != null) {
      appProviderContainer.read(missedCallsProvider.notifier).refresh();
      goRouter.go(missedRoute);
      return;
    }
```
  `app_router.dart` `/chat/:userId`: `final autoCall = state.uri.queryParameters['call'];` → `ChatScreenWrapper(userId: userId, prefillMessage: prefill, autoCall: autoCall)`.
  `chat_screen_wrapper.dart`: field `final String? autoCall;` (constructor `this.autoCall`), state `bool _autoCallDone = false;`, and in `_fetchUserData` after the successful `setState`:
```dart
      if (widget.autoCall != null && !_autoCallDone && mounted) {
        _autoCallDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          CallLauncher.start(context, ref,
              userId: widget.userId,
              userName: userData.name,
              avatar: userData.imageUrls.isNotEmpty ? userData.imageUrls.first : null,
              type: widget.autoCall == 'video' ? CallType.video : CallType.audio);
        });
      }
```
  `ios/Runner/AppDelegate.swift` (categories stay registered from Dart — `setNotificationCategories` replaces the whole set, so registering natively too would be overwritten): add `import UserNotifications`, a pending store and the channel, set the delegate, and intercept only remote (`gcm.message_id`) MISSED_CALL action taps:
```swift
  private var missedCallChannel: FlutterMethodChannel?
  private var pendingMissedCallAction: [String: Any]?

  // in didFinishLaunching, after GeneratedPluginRegistrant.register(with: self):
    UNUserNotificationCenter.current().delegate = self
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "bananatalk/missed_call_actions",
                                         binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "takePending" {
          result(self?.pendingMissedCallAction)
          self?.pendingMissedCallAction = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      missedCallChannel = channel
    }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let content = response.notification.request.content
    let action = response.actionIdentifier
    let isRemote = content.userInfo["gcm.message_id"] != nil
    if isRemote && content.categoryIdentifier == "MISSED_CALL"
      && (action == "call_back" || action == "message") {
      let payload: [String: Any] = [
        "action": action,
        "callerId": content.userInfo["callerId"] as? String ?? "",
        "callType": content.userInfo["callType"] as? String ?? "audio",
      ]
      // Cold start: Dart is not listening yet, so keep it for takePending.
      // Warm: Dart routes the invoke now; a later takePending finds the same
      // action and goRouter.go to the current location is a no-op.
      pendingMissedCallAction = payload
      missedCallChannel?.invokeMethod("action", arguments: payload)
      completionHandler()
      return
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
```
- [ ] **Step 4: run, pass.** `flutter test test/services/missed_call_actions_test.dart test/services/` green; `flutter analyze lib/services lib/router lib/pages/chat/chat_screen_wrapper.dart` clean; `cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO | tail -3` → `BUILD SUCCEEDED`.
- [ ] **Step 5: commit.** `git add lib/services/call/missed_call_actions.dart lib/services/notification_service.dart lib/services/notification_router.dart lib/services/notification_api_client.dart lib/router/app_router.dart lib/pages/chat/chat_screen_wrapper.dart ios/Runner/AppDelegate.swift test/services/missed_call_actions_test.dart docs/REMAINING_WORK.md` — tick "push actions (code)"; open "[ ] device QA CALL2-3..CALL2-6". Message: `feat(calls): Call back / Message on the missed-call notification` + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C8: App — "Allow calls" toggle and the quiet-hours note
**Files:** `lib/models/notification_models.dart`, `lib/providers/notification_settings_provider.dart`, `lib/pages/notifications/notification_settings_screen.dart`, create `test/settings/allow_calls_setting_test.dart`, `docs/REMAINING_WORK.md`
**Interfaces:** Consumes `notificationSettings.allowCalls` (C2). Produces `NotificationSettings.allowCalls`, `toggleSetting('allowCalls', v)`, `NotificationSettingsNotifier.forTest(NotificationSettings)`.

- [ ] **Step 1: failing test** — `test/settings/allow_calls_setting_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/pages/notifications/notification_settings_screen.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';

class _Recording extends NotificationSettingsNotifier {
  _Recording(super.initial) : super.forTest();
  final toggled = <String>[];
  @override
  Future<void> toggleSetting(String settingName, bool value) async {
    toggled.add('$settingName:$value');
    state = AsyncValue.data(state.value!.copyWith(allowCalls: value));
  }
}

void main() {
  test('allowCalls defaults to true and round-trips', () {
    expect(NotificationSettings.fromJson({}).allowCalls, isTrue);
    final off = NotificationSettings.fromJson({'allowCalls': false});
    expect(off.allowCalls, isFalse);
    expect(off.toJson()['allowCalls'], isFalse);
    expect(off.copyWith(allowCalls: true).allowCalls, isTrue);
  });

  testWidgets('the Allow calls switch writes allowCalls; quiet hours mention calls', (tester) async {
    final notifier = _Recording(NotificationSettings.defaultSettings()
        .copyWith(quietHours: const QuietHours(enabled: true)));
    await tester.pumpWidget(ProviderScope(
      overrides: [notificationSettingsProvider.overrideWith((ref) => notifier)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationSettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Allow calls'), 200);
    expect(find.text('Calls are held during quiet hours too.'), findsOneWidget);
    await tester.tap(find.text('Allow calls')); // the tile's InkWell toggles
    await tester.pumpAndSettle();
    expect(notifier.toggled, ['allowCalls:false']);
  });
}
```
- [ ] **Step 2: run, expected fail.** `flutter test test/settings/allow_calls_setting_test.dart` → no `allowCalls`, no `forTest`.
- [ ] **Step 3: implement.** Model: `final bool allowCalls;` (constructor default `true`), `fromJson`: `allowCalls: json['allowCalls'] ?? true`, `toJson`: `'allowCalls': allowCalls`, `copyWith(bool? allowCalls)` → `allowCalls: allowCalls ?? this.allowCalls`. Provider: `NotificationSettingsNotifier.forTest(NotificationSettings initial) : super(AsyncValue.data(initial));` and in `toggleSetting`:
```dart
      case 'allowCalls':
        updatedSettings = currentSettings.copyWith(allowCalls: value);
        break;
```
  Screen: after the "Notification types" container (before Quiet Hours) add a section:
```dart
          const SizedBox(height: 24),
          _buildSectionTitle(context, l10n.callsTitle, Icons.call_rounded, const Color(0xFF00BFA5)),
          const SizedBox(height: 10),
          _buildSectionContainer(context, [
            _buildToggleTile(
              context: context,
              icon: Icons.phone_in_talk_rounded,
              iconColor: const Color(0xFF00BFA5),
              title: l10n.callsAllowTitle,
              subtitle: l10n.callsAllowSubtitle,
              value: settings.allowCalls,
              enabled: true,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref.read(notificationSettingsProvider.notifier).toggleSetting('allowCalls', value);
              },
              isFirst: true,
              isLast: true,
            ),
          ]),
```
  (`enabled: true` — calls stay governed even when pushes are off.) Under the quiet-hours start/end tiles (inside `if (settings.quietHours.enabled) ...[`), add `Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: Text(l10n.callsQuietHoursNote, style: Theme.of(context).textTheme.bodySmall))`.
- [ ] **Step 4: run, pass.** test green; `flutter test test/l10n/` green; analyze clean.
- [ ] **Step 5: commit.** `git add lib/models/notification_models.dart lib/providers/notification_settings_provider.dart lib/pages/notifications/notification_settings_screen.dart test/settings/allow_calls_setting_test.dart docs/REMAINING_WORK.md` — tick "settings". Message: `feat(calls): Allow calls switch; quiet hours hold calls` + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C9: App — camera on during a voice call
**Files:** `lib/screens/active_call_screen.dart`, `test/screens/active_call_screen_test.dart`, `docs/REMAINING_WORK.md`
**Interfaces:** Consumes `CallManager.upgradeToVideo()`, `onCallTypeChanged`, key `callTurnOnCamera`. Produces a "Camera" control on voice calls; the screen follows the call type.

- [ ] **Step 1: failing test** — add to `test/screens/active_call_screen_test.dart`:
```dart
  testWidgets('voice call: Camera turns the camera on and the screen becomes a video call', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActiveCallScreen(call: h.manager.currentCall!),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Camera'));
    await tester.pump();
    expect(h.api.calls, contains('upgrade:call-1'));
    expect(h.liveKit.cameraCalls, [true]);
    expect(find.text('Camera'), findsNothing, reason: 'video controls replace the voice ones');
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('peer upgraded: call:state type video switches this screen too', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActiveCallScreen(call: h.manager.currentCall!),
      ),
    ));
    await tester.pump();
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    await tester.pump();
    expect(find.text('Camera'), findsNothing);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });
```
- [ ] **Step 2: run, expected fail.** `flutter test test/screens/active_call_screen_test.dart` → no "Camera".
- [ ] **Step 3: implement.** In `_ActiveCallScreenState`: `late CallType _callType;` set in `initState` to `widget.call.callType`; replace every `widget.call.callType == CallType.video` in `build` and `initState` with `_callType == CallType.video` (the finish banner keeps `finish.call.callType`); in the post-frame setup add
```dart
      callManager.onCallTypeChanged = (type) {
        if (!mounted) return;
        setState(() {
          _callType = type;
          _isSpeakerOn = true;
        });
      };
```
  and null it in `dispose` via `_cachedCallManager?.onCallTypeChanged = null;`. In the controls `Row`, for voice calls (the `else` branch that shows the speaker toggle) add after the speaker button:
```dart
                      if (!isVideoCall)
                        _ControlButton(
                          icon: Icons.videocam_rounded,
                          label: l10n.callTurnOnCamera,
                          onPressed: () async {
                            final ok = await callManager.upgradeToVideo();
                            if (ok && mounted) {
                              setState(() {
                                _callType = CallType.video;
                                _isVideoEnabled = true;
                              });
                            }
                          },
                          backgroundColor: Colors.white24,
                          iconColor: Colors.white,
                        ),
```
  (a separate collection-`if` entry after the existing `if (isVideoCall) … else …` pair). Change the existing video toggle's `onPressed` so turning the camera **on** runs the permission check (the peer of an upgraded call never had one):
```dart
                          onPressed: () async {
                            final next = !_isVideoEnabled;
                            if (next) {
                              if (!await callManager.upgradeToVideo()) return;
                            } else {
                              callManager.setVideoEnabled(false);
                            }
                            if (mounted) setState(() => _isVideoEnabled = next);
                          },
```
- [ ] **Step 4: run, pass.** `flutter test test/screens/ test/services/` green; analyze clean.
- [ ] **Step 5: commit.** `git add lib/screens/active_call_screen.dart test/screens/active_call_screen_test.dart docs/REMAINING_WORK.md` — tick "camera mid voice call". Message: `feat(calls): turn the camera on during a voice call` + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C10: App — draggable self-view that snaps to corners; tap to swap
**Files:** create `lib/widgets/call/swappable_video_layout.dart`, `lib/screens/active_call_screen.dart`, create `test/widgets/swappable_video_layout_test.dart`, `docs/REMAINING_WORK.md`
**Interfaces:** Produces `enum PipCorner`, `PipCorner nearestCorner(Offset center, Size area)`, `SwappableVideoLayout({required Widget remote, Widget? local})` with keys `call-main` / `call-pip`.

- [ ] **Step 1: failing test** — `test/widgets/swappable_video_layout_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/widgets/call/swappable_video_layout.dart';

void main() {
  test('nearestCorner picks the quadrant', () {
    const area = Size(400, 800);
    expect(nearestCorner(const Offset(10, 10), area), PipCorner.topLeft);
    expect(nearestCorner(const Offset(390, 10), area), PipCorner.topRight);
    expect(nearestCorner(const Offset(10, 790), area), PipCorner.bottomLeft);
    expect(nearestCorner(const Offset(390, 790), area), PipCorner.bottomRight);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: SwappableVideoLayout(remote: Text('REMOTE'), local: Text('LOCAL')),
    ));
  }

  testWidgets('starts top-right; drag to bottom-left snaps there', (tester) async {
    await pump(tester);
    expect(tester.getTopLeft(find.byKey(const Key('call-pip'))), const Offset(400 - 20 - 120, 20));
    await tester.drag(find.byKey(const Key('call-pip')), const Offset(-250, 550));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('call-pip'))), const Offset(20, 800 - 20 - 160));
  });

  testWidgets('tap swaps big and small', (tester) async {
    await pump(tester);
    expect(find.descendant(of: find.byKey(const Key('call-main')), matching: find.text('REMOTE')), findsOneWidget);
    await tester.tap(find.byKey(const Key('call-pip')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('call-main')), matching: find.text('LOCAL')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('call-pip')), matching: find.text('REMOTE')), findsOneWidget);
  });
}
```
- [ ] **Step 2: run, expected fail.** file missing.
- [ ] **Step 3: implement.** `lib/widgets/call/swappable_video_layout.dart`:
```dart
import 'package:flutter/material.dart';

enum PipCorner { topLeft, topRight, bottomLeft, bottomRight }

PipCorner nearestCorner(Offset center, Size area) {
  final left = center.dx < area.width / 2;
  final top = center.dy < area.height / 2;
  if (top) return left ? PipCorner.topLeft : PipCorner.topRight;
  return left ? PipCorner.bottomLeft : PipCorner.bottomRight;
}

/// Full-screen main video with a small self-view that can be dragged (it
/// snaps to the nearest corner) and tapped to swap which feed is big.
class SwappableVideoLayout extends StatefulWidget {
  const SwappableVideoLayout({
    super.key,
    required this.remote,
    this.local,
    this.pipSize = const Size(120, 160),
    this.margin = 20,
  });

  final Widget remote;
  final Widget? local;
  final Size pipSize;
  final double margin;

  @override
  State<SwappableVideoLayout> createState() => _SwappableVideoLayoutState();
}

class _SwappableVideoLayoutState extends State<SwappableVideoLayout> {
  PipCorner _corner = PipCorner.topRight;
  bool _swapped = false;
  Offset? _drag;

  Offset _cornerOffset(PipCorner c, Size area) {
    final m = widget.margin;
    final right = area.width - m - widget.pipSize.width;
    final bottom = area.height - m - widget.pipSize.height;
    switch (c) {
      case PipCorner.topLeft:
        return Offset(m, m);
      case PipCorner.topRight:
        return Offset(right, m);
      case PipCorner.bottomLeft:
        return Offset(m, bottom);
      case PipCorner.bottomRight:
        return Offset(right, bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.local;
    return LayoutBuilder(builder: (context, constraints) {
      final area = constraints.biggest;
      final main = _swapped && local != null ? local : widget.remote;
      final small = _swapped ? widget.remote : local;
      final pos = _drag ?? _cornerOffset(_corner, area);
      return Stack(children: [
        Positioned.fill(child: KeyedSubtree(key: const Key('call-main'), child: main)),
        if (small != null)
          AnimatedPositioned(
            duration: _drag == null ? const Duration(milliseconds: 200) : Duration.zero,
            curve: Curves.easeOut,
            left: pos.dx,
            top: pos.dy,
            width: widget.pipSize.width,
            height: widget.pipSize.height,
            child: GestureDetector(
              key: const Key('call-pip'),
              onTap: () => setState(() => _swapped = !_swapped),
              onPanUpdate: (d) => setState(() => _drag = (_drag ?? pos) + d.delta),
              onPanEnd: (_) => setState(() {
                final p = _drag ?? pos;
                _corner = nearestCorner(
                    p + Offset(widget.pipSize.width / 2, widget.pipSize.height / 2), area);
                _drag = null;
              }),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: small,
                ),
              ),
            ),
          ),
      ]);
    });
  }
}
```
  `active_call_screen.dart`: when `isVideoCall && !_isEnding`, replace the remote `Positioned.fill(...)` and the local "Picture in Picture" `Positioned(...)` with
```dart
                Positioned.fill(
                  child: SwappableVideoLayout(
                    remote: _isPeerVideoEnabled && remoteTrack != null
                        ? lk.VideoTrackRenderer(remoteTrack, fit: lk.VideoViewFit.cover,
                            mirrorMode: lk.VideoViewMirrorMode.off)
                        : _buildPeerPlaceholder(l10n),
                    local: _isVideoEnabled
                        ? (localTrack != null
                            ? lk.VideoTrackRenderer(localTrack, fit: lk.VideoViewFit.cover,
                                mirrorMode: lk.VideoViewMirrorMode.mirror)
                            : const ColoredBox(color: Colors.black54,
                                child: Center(child: Icon(Icons.videocam_off, color: Colors.white70))))
                        : null,
                  ),
                ),
```
  where `_buildPeerPlaceholder` is the existing avatar/name/status `Column` (extracted unchanged into a method so voice calls keep using it as today).
- [ ] **Step 4: run, pass.** `flutter test test/widgets/swappable_video_layout_test.dart test/screens/` green; analyze clean.
- [ ] **Step 5: commit.** `git add lib/widgets/call/swappable_video_layout.dart lib/screens/active_call_screen.dart test/widgets/swappable_video_layout_test.dart docs/REMAINING_WORK.md` — tick "self-view". Message: `feat(calls): draggable, swappable self-view` + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

### Task C11: Docs — Calls Phase 2 rows in the device QA matrix
**Files:** `docs/qa/calls-matrix.md`, `docs/REMAINING_WORK.md`
**Interfaces:** none (QA handoff).

- [ ] **Step 1: failing check.** `grep -c '^| CALL2-' docs/qa/calls-matrix.md` → `0`.
- [ ] **Step 2: run, expected fail.** (as above; the section does not exist).
- [ ] **Step 3: implement.** Append:
```markdown
## 5. Phase 2 (decline message, push actions, calls off, camera, self-view)

Backend with C1–C4 deployed; app with C5–C10. Record as above.

| ID | Scenario | Steps | Expected | Result |
|---|---|---|---|---|
| CALL2-1 | Decline with a canned reply | B's app open; A calls; B taps Message → first canned reply | A's screen shows "Declined"; A's chat shows the call bubble, then B's text below it; B sees the same order | |
| CALL2-2 | Decline with a custom reply | As CALL2-1, type 200+ chars | Field stops at 200; the 200-char text arrives | |
| CALL2-3 | Missed push actions, iOS killed | Kill B's app; A calls, cancels | Missed notification shows Call back / Message (long-press); Call back opens the app on A's chat and rings A (same voice/video type); Message opens the chat | |
| CALL2-4 | Missed push actions, iOS background + foreground | Repeat with B in background, then in foreground (banner) | Same as CALL2-3; no duplicate notification | |
| CALL2-5 | Missed push actions, Android 13+ killed / background / foreground | Repeat CALL2-3 on Android | One notification with two buttons; Call back starts the call after the app opens; Message opens the chat | |
| CALL2-6 | Live build unaffected | B on 2.6.1 (Android + iOS); A misses a call to B | B gets the same missed notification as today (no blank one) | |
| CALL2-7 | Calls off | B: Settings → Notifications → Allow calls off; A calls | A sees "B isn't taking calls right now"; B's phone does nothing; no bubble on either side; turning it back on lets A's next call ring | |
| CALL2-8 | Quiet hours | B: quiet hours covering now; A calls; then disable | Same as CALL2-7, then rings | |
| CALL2-9 | Camera on mid voice call | Voice call connected; A taps Camera (grant permission on first use) | B sees A's video; B's controls become video controls; B can turn its camera on; after hang-up both bubbles and the Calls list say "Video call" | |
| CALL2-10 | Camera on, permission denied | As CALL2-9 with camera permission denied | Permission message; the call continues as voice | |
| CALL2-11 | Upgrade against a live peer | A on the new build, B on 2.6.1; A taps Camera | B's call keeps going (audio); B shows no video — accepted limitation | |
| CALL2-12 | Self-view | Video call; drag the self-view to each corner; tap it | Snaps to the nearest corner; tap swaps big/small; tap again swaps back | |
| CALL2-13 | Android background after upgrade | CALL2-9 on Android 14, press Home for 1 min, return | Audio continues; camera pauses and returns; no crash (camera FGS type) | |
```
- [ ] **Step 4: run, pass.** `grep -c '^| CALL2-' docs/qa/calls-matrix.md` → `13`.
- [ ] **Step 5: commit.** `git add docs/qa/calls-matrix.md docs/REMAINING_WORK.md` — REMAINING_WORK §0b: tick the Phase 2 code item, add "[ ] Device QA CALL2-1…CALL2-13" and "[ ] deploy C1–C4 before the app release". Message: `docs(calls): Phase 2 device QA rows` — "Open: backend deploy, device QA CALL2-*, native review of call strings." + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

---

## Contradictions found and resolutions

1. **74 strings vs 402.** Spec §6 / REMAINING_WORK §5 say 74 in 56 files (single-line `Text('…')` count). A tokenizer that follows multi-line calls finds 553 in 170 files: 402 live in 128 files are localized (L1–L12), and 151 are allowlisted in L13 with a reason. REMAINING_WORK §5 gets the real number in L1's commit.
2. **"Fails CI".** The app has no CI workflow. The guard fails `flutter test`. Wiring CI is out of scope; recorded as open.
3. **`actions: ['call_back','message']`.** FCM data values must be strings. The service passes the array, as the contract says. `_sanitizeData` sends it as `'["call_back","message"]'`, and the app parses either form.
4. **"Android local-notification actions (push is data-only)".** The missed-call push is NOT data-only today: `fcmService.sendToUser` always sends a `notification` block, and Android draws that itself, without buttons. Making it data-only for everyone would leave live builds with a silent push. **Resolution:** a new capability `missed_call_actions`. Only new Android tokens that declare it get data-only; everyone else keeps the visible push.
5. **"iOS `UNNotificationCategory` registered natively".** `flutter_local_notifications` `setNotificationCategories` replaces the whole set, so a category registered only in native code would be wiped. **Resolution:** the category is declared in Dart next to `CHAT_MESSAGE`. AppDelegate natively handles the action taps on remote pushes, which the plugin does not deliver.
6. **Quiet hours now block calls.** `quietHours` was notification-only, and live users who enabled it will start refusing calls. This is what the spec intends. The settings note in C8 says so, and the C2 commit body records it.
7. **Upgrade event.** Re-emitting `call:accepted` would restart a live build's connect flow, and the new app's `_onCallState` would reset a connected caller to "connecting". **Resolution:** emit only `call:state`, and the app treats a repeat `active` as a type change (C5).
8. **Files edited in two waves.** A tasks edit `widgets/promo/*` and L11 must re-grep them. L12 localizes `active_call_screen.dart` before C9/C10 edit it.
