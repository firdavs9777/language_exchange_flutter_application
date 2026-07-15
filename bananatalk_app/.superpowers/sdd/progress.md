# Workstream A: Auth — Progress Ledger
Plan: docs/superpowers/plans/2026-07-11-workstream-a-auth.md
Branches: workstream-a-auth (app base 82b7e17, backend base b8fd778)
Backend repo: /Users/davis/Desktop/Personal/language_exchange_backend_application

## Completed
TREE_AFTER_T1=20fcc4c8ee4363ee5b21bbdfea6338e980b98e8f
Task 1: complete (uncommitted working tree, review clean/approved)
  Minor (for final review triage): error.js dead-code fallback error.errorCode; duplicated split-comment in auth.js x2 (extract helper only on 3rd occurrence)
  Note for Task 8 dispatch: resetPassword endpoint errors carry NO code field — Flutter reset screen must not assume codes on that call
TREE_AFTER_T2=32cef9f9fd88bc826ba9d0174c4373c38cfce86e
Task 2: complete (uncommitted, review approved)
  Verified by controller: birth_year is String in schema (auth.js:224 default '') — reviewer's numeric-coercion concern moot
  Minor (final-review triage): whitespace-only values pass coreComplete presence checks (plan-snippet looseness; consider .trim()); console.log diagnostics removed; error msg wording cosmetic
TREE_AFTER_T3=30800814d1e6e29b76f5b0ddaf382ccda82fcf3c
## Prod baseline (measured 2026-07-11, users joined since 2026-06-11)
- 516 new users: apple 310 (51 incomplete), google 170 (60 incomplete), email 36 (19 incomplete) => 130 (25%) stuck incomplete
- Of incomplete: 98 abandoned at step 1 (no gender/birth/langs); 23 same-language pair (silent backend refusal); 41 still active last 7d
- Re-measure after Workstream A ships. Consider one-time nudge/migration for the 23 same-language users (they need the Task 12 picker fix to self-serve).
Task 3: complete (uncommitted, review approved)
  Minor (final-review triage): unconditional extra findById per logout (plan-prescribed); could restructure handler to single user fetch
TREE_AFTER_T4=8d0775599f929292e1974bda776c28891aa0a8b5
Task 4: complete (uncommitted, review approved, 5-scenario token matrix traced)
  Minor (final-review triage): add one-line comment noting fallback verify's errors deliberately handled by outer catch
  Deploy note: REFRESH_TOKEN_SECRET must be set on production host (config.env gitignored)
== BACKEND PHASE DONE (T1-T4) ==
APP_TREE_AFTER_T5=1c08f5ed539365ff54f02358ba076c7c9bb68d05
Task 5: complete (uncommitted, fix round 1 for test isolation + stale-state hook, re-review approved)
== PARALLEL MODE (user request): T6+T9 in flight; wave 2 = T7+T8; wave 3 = T10-T13 (T12 owns auth_step_progress.dart, T11 must not modify it); T14 last ==
Task 9: complete (uncommitted, Critical use-after-dispose fixed + regression test, re-review approved)
  Minor (final-review triage): reduce-motion renders fixed gradient (cosmetic); next-to-fill focus-box semantics flagged for integration awareness
Task 6: review NEEDS FIXES —
  CRITICAL: splash_screen.dart auto-login path ungated (splash lines ~95-136 go straight /home; live-session users — most of the 130 stuck — never rescued). Fix: gate session-restore path; spec intent "every login" includes auto-login.
  IMPORTANT: Users.profileCompleted is dead code (runtime model is Community). Controller resolution (plan deviation, intent-preserving): add profileCompleted to Community model, use it at splash+login gate+recheck, remove dead Users field.
  IMPORTANT: recheck asymmetry (hasCoreFields vs profileCompleted) — reconcile via Community.profileCompleted.
  T6 fix HELD until T8 releases login_screen.dart. T7 dispatched in parallel (disjoint files).
== PROCESS RESTART (model change): T7+T8 agents killed mid-flight. T8 left partial work (enum+test created; providers+2 verification screens modified; login_screen UNTOUCHED). T7 left nothing. Re-dispatched: T8-completion (login_screen enum swap DEFERRED to T10), T7 fresh, T6-fix (splash gate + Community.profileCompleted + remove dead Users field). All three file-disjoint, running parallel. ==
Task 8: complete (uncommitted, crash-recovered by second agent, review approved)
  Deferred to T10: login_screen error-region enum swap. Deferred (future/T11 candidate): register() error-map EMAIL_EXISTS threading.
  Minor (final-review triage): duplicated 3-string fallback across 2 verification screens; inert resetPassword 'code' key (documented).
Task 6: complete (uncommitted, fix round 1: splash gate + Community.profileCompleted + symmetry, re-review approved)
  Minor (final-review triage): 4 gate implementations across screens (extract shared helper); splash gate no local-prefs cache (extra API call per launch); fail-open empty catch mirrors pre-existing terms pattern
  UI wave: T10+T13 dispatched now; T11+T12 held for T7 verdict
Task 7: complete (uncommitted, review approved)
  Folded into T11 dispatch: await/unawaited cleanup in register_screen _startOver/submit. Folded into T12: step-index readability. Final-review triage: no wiring-level tests (brief-scoped); hardcoded banner headline needs l10n key (fast-follow, 19 arb files)
  UI WAVE: T10+T11+T12+T13 all dispatched in parallel (file-disjoint; T12 owns auth_step_progress)
== STREAMLINED (user request): per-task reviews dropped for T10-T13; controller runs combined analyze+test gate; single final whole-branch review + one batched fixer ==
Task 13: complete (uncommitted, self-verified 9/9 tests, 0 errors own files; per-task review skipped per streamline)
  For final review: background layered behind content (AuthScreenScaffold opaque bg); manual Verify button removed (OTP auto-submit)
Task 12: complete (uncommitted, self-verified 0 errors + 9/9 tests; per-task review skipped per streamline)
  For final review: picker sheet private (WS-C wants reuse later); finish haptic fires on tap not network success; segment labels plain-string fallbacks (no l10n keys)
Task 10: complete (uncommitted, self-verified 0 errors + 10/10 tests; per-task review skipped per streamline)
  Note: login enum swap was already present (T6 fixer added it). For final review: compact modes added to social/biometric buttons (backward compatible); "or continue with"/footer copy l10n keys missing (product follow-up)
== FINAL REVIEW: READY AFTER MUST-FIX ==
Must-fix batch (one fixer): C1 reset-screens layout crash; C2 same-language wizard loop (+backend msg); I2 verify button value; I3 wizard labels from _computeSteps; dark-mode account_suspended 2 colors; M1 dead enum local; M2 reentry guard; M3 retryAfter threading; M4 gender case on resume; M6 splash mounted guards.
OPEN DECISION (user): I1 Apple logout revocation inert (lib arg mismatch + no stored Apple refresh token; deletion path has same pre-existing defect). Options: real fix (store token at sign-in) or accept+amend smoke item 3.
Follow-up backlog (post-merge): l10n batch (M7 + banner + segment labels + footer copy), shared gate helper, M5 resume-step doc, M8 server-side same-lang guard on register, M9 null guard, picker extraction for WS-C, T2 trim, T3 findById.
Smoke checklist deltas recorded in final review (7 additions/amendments).
I1 DECISION (defaulted, user deferred): accept Apple revocation as inert-known-limitation for this branch (non-blocking, same as pre-branch). Backlog: store Apple refresh token at sign-in (getAuthorizationToken exchange), fix revokeAuthorizationToken args (clientID/clientSecret + user token positional) at BOTH logout and deletion paths. Smoke checklist item 3 amended: expect "clientID is empty" log, not APPLE_TOKEN_REVOKED_ON_LOGOUT.
Task 14: complete. Batched fixer closed all 13 must-fix items (revert-tested the C1 regression guard). Controller independent gate: analyze 0 err/0 warn, all auth+services tests pass, backend node --check OK. Scratch test files removed.
== WORKSTREAM A CODE-COMPLETE (uncommitted, both repos, branch workstream-a-auth) ==
Remaining: user device smoke checklist -> then commit on user go-ahead.

# ===== WORKSTREAM B: INTROS =====
Plan: docs/superpowers/plans/2026-07-12-workstream-b-intros.md
Branches: workstream-b-intros (app 0b8e8f8+plan, backend 911306a). Commits allowed per task.
Scout finding: wave->chat mirror + push ALREADY exist; B = last-mile fixes (parse bug, push route, strip, badge, icebreakers). No accept endpoint, no kill switch (documented deviation).
Wave 1 dispatch: T1(backend) + T2 + T3 + T6 parallel (disjoint); T4 after T2; T5 after T4.
USER INSTRUCTION mid-wave-1: NO per-task commits for B — single commit after ALL tasks complete. All 4 running agents redirected via message. Verify no stray commits at gate (branch tips must stay app=d78f15a, backend=911306a until final commit).
== WORKSTREAM B SHIPPED: merged+pushed main (backend 39692bb, app 357a5e6). Known-accepted: strip not live-updating mid-session; l10n batch grew (Intro requests header, icebreakers). Re-measure funnel ~1wk: baseline 1.1% read, 2/1091 mutual. ==

# ===== WORKSTREAM C: MOMENTS 2.0 + STORIES =====
Plan: docs/superpowers/plans/2026-07-12-workstream-c-moments.md (committed 070923e)
Branches: workstream-c-moments (app 070923e, backend 39692bb). NO commits until gate (standing instruction).
Two parallel tracks: moments (T1->T2+T3->T4 backend; T5->T6/T7/T8->T9 app) and stories (T10->T11->T12->T13 serial, story_viewer shared). T14 gate.
C progress: T1,T2,T3,T4,T10,T11 done. T5 running (feed tabs). T11 found+fixed service-side sticker bug; backend createStory never persisted poll/questionBox -> patch agent dispatched. T12 (highlights) running. Remaining: T6,T7,T8,T9 (after T5), T13 (after T12), sticker-backend-patch, T14 gate.
C completions since last entry: T5 (tabs+providers), T6 (prompt card+prefill), T7 (corrections UI, TDD diff engine), T8 (audio UI, MomentAudio model), T9 (crash-recovered: polish/edit/pagination/empty-states; fixed edit-voice-note bug + wrong provider invalidation), T12 (highlights both profiles, legacy impl retired), T13 (link pill, save/share, reduce-motion ring, hashtags), backend patches: story poll/questionBox persistence + hashtags read (both silent-drop bugs). ALL 15 IMPLEMENTATION ITEMS DONE. T14 gate starting.
== WORKSTREAM C SHIPPED: gate passed (analyze 0 err, 24/1 tests, stock-only failure), final review 3 Criticals + 3 Importants + 6 Minors all fixed in one batch, merged+pushed main both repos. Server step pending: node migrations/seedPrompts.js (+ REFRESH_TOKEN_SECRET still unset from A). ==

# ===== WORKSTREAM D: LANGUAGE ROOMS =====
Plan: docs/superpowers/plans/2026-07-12-workstream-d-language-rooms.md (committed 824a329)
Spec: docs/superpowers/specs/2026-07-12-workstream-d-language-rooms-design.md
Branches: workstream-d-rooms (app base 824a329, backend base 0581d6f). Per-task commits (subagent-driven-dev needs commit ranges).
Backend test runner: node:test (`npm test` globs services/*.test.js test/*.test.js). Place helper tests in test/*.test.js.
Phase 1 (backend, repo language_exchange_backend_application): T1 normalizeLanguage -> T2 Conversation hub fields+leftHubs+DM-exclusion -> T3 seedRooms -> T4 REST -> T5 sockets -> T6 daily prompt -> T7 kill switch/app-config/mention push.
Phase 2 (app): T8 socket client -> T9 Rooms tab+directory -> T10 room screen -> T11 moderation UI. T12 gate.
== PARALLEL MODE (user request): backend track || app track. Streamlined (per Workstream A precedent): no per-task reviewer, implementers self-verify (npm test / flutter analyze), single whole-branch review + batched fixer at gate. ==
Task 1: complete (backend commit e8cba56, normalizeLanguage 4/4 tests; 2 pre-existing unrelated failures remain). App-Batch-1 (T8+T9) dispatched in parallel.
Task 2+3: complete (backend 7d604dd hub fields+leftHubs+DM-exclusion +6 tests; 75b6c56 seedRooms). seedRooms only dry-run verified — real staging idempotency check pending at gate.
Backend T4+T5 (REST + sockets, coupled via online-count accessor) dispatched. App-Batch-1 still running.
App-Batch-1 (T8+T9): complete (851e641 socket client room methods+streams; 5a59473 Rooms tab+directory). analyze clean. Left _RoomScreenPlaceholder + unused RoomApiClient.removeMember/muteMember/updateRoom for T10/T11. Rooms tab label uses plain-string l10n fallback (follow-up).
App-Batch-2 (T10 room screen + T11 moderation UI) dispatched. Backend T4+T5 still running.
Task 4+5: complete (backend 0f23155 REST routes; d897d05 socket events+presence+broadcast; +27 unit tests). DEVIATION FOR FINAL REVIEW: agent added Message.conversationId (indexed) AND relaxed Message.receiver required validator — scrutinize impact on existing DM creation/validation at gate.
Backend T6+T7 (daily prompt job + ROOMS_ENABLED kill switch + app-config roomsEnabled + mention-only push) dispatched. App-Batch-2 still running.
App-Batch-2 (T10+T11): complete (6fe5893 room screen+multi-sender list; 42a91a9 per-message report+admin remove/mute). analyze clean. No hub-level report (Report.type has no room value — per-message report used, correct). APP TRACK DONE (T8-T11).
Waiting on backend T6+T7 to finish → then gate (whole-branch review + smoke).
Task 6+7: complete (backend 530cf20 daily prompt job; 13366d3 ROOMS_ENABLED+app-config+mention push; +32 tests, 107/109 pass, only 2 pre-existing failures). BACKEND PHASE DONE (T1-T7). ALL 11 IMPL TASKS DONE. Gate (T12) starting: whole-branch review + smoke.
== GATE (T12): whole-branch review done BY CONTROLLER (reviewer subagents hit session limit). Result: NO Critical/Important issues. ==
Automated gate GREEN: backend npm test 107/109 (only 2 pre-existing failures notificationCaps+profileVisitCleanup, zero new); app flutter analyze exit 0 (1500 issues all pre-existing repo-wide info lints, 0 errors/warnings in rooms files).
Reviewed high-risk items — all clean:
- Message.receiver relaxation is CONDITIONAL (required only when !isGroupMessage) — DMs still require receiver. Message.conversationId sparse-indexed. GOOD, minimal blast radius.
- ROOMS_ENABLED: roomsEnabledGuard wraps all room routes; protect after; appConfig emits roomsEnabled; socket gated. Route mounted /api/v1/rooms.
- Admin endpoints: shared owner/admin gate, 403 if neither owner nor admins[]. Correct (room admin != global admin).
- room_screen dispose: leaveRoom + all 3 stream subs .cancel(); mounted guards throughout. No use-after-dispose.
- ChatMessagesList: isGroup defaults false, 1-on-1 path unchanged (confirmed by code+comment).
Backend base 0581d6f..13366d3 (7 commits). App base 824a329..42a91a9 (4 commits). CODE-COMPLETE, uncommitted-to-main (branch workstream-d-rooms both repos).
REMAINING (manual, user): device smoke gate; prod deploy steps (node migrations/seedRooms.js, seedPrompts.js, set ROOMS_ENABLED + REFRESH_TOKEN_SECRET); then merge to main on user go-ahead.
Minor follow-ups (non-blocking): Rooms tab l10n plain-string fallback; no hub-level report (Report.type has no 'room' value — per-message report only).

# ===== WORKSTREAM E-CORE: PUSH REACH + NOTIFICATION CORRECTNESS + EMAIL COMPLIANCE =====
Plan: docs/superpowers/plans/2026-07-13-workstream-e-core-reach-correctness.md (committed fb7b60d)
Branches: workstream-e-core (app base fb7b60d, backend base 243eafa). Per-task commits. USER MANDATE: "fix them all" — E-core tasks + per-domain notification-audit findings (audit agent in flight, will extend plan as Phase 2).
Backend tests: node:test via nvm Node v24.18.0 ONLY (v25 breaks jsonwebtoken/SlowBuffer). Baseline 1 pre-existing failure (profileVisitCleanup).
T1 subscription-reminder crash | T2 SRS gating srs_review | T3 wire streak reminders | T4 wave summary KST | T5 enum sync | T6 unsubscribe compliance | T7 app FCM token capture (session restore = root cause) | T8 gate.
Plan review in flight; domain audit (chat/moments/community/profile triggers, zero-count types) in flight.
== USER INSTRUCTION: NO COMMITS for E-core. All tasks leave uncommitted working-tree changes; single commit at gate on user go-ahead. Branch tips must stay app=fb7b60d, backend=243eafa until then. Every implementer dispatch must carry this instruction. Note: plan-doc commit fb7b60d exists on LOCAL main only (unpushed) — hold push until go-ahead. ==
Plan review verdict: Issues Found — C1 (T3 wrong scheduler: use jobs/scheduler.js getMillisecondsUntil(20,0), not startLearningJobs), C2 (streaks bypass send(); decision: route through notificationService.send 'streak_reminder'), I1 (_shouldSendNotification not shouldNotify), I2/I3 (enum gap = silent history loss for wave/comment_*/room_mention/vip_renewal_warning; build test list from grep), M3 (digest check exists; promo URL injects in emailService). ALL FOLDED INTO PLAN (uncommitted edit).
Domain audit folded in as Phase 2: T9 new_follower type, T10 re-enable profile-visit sends, T11 wave overflow->daily summary, T12 router deep-links (room_mention, data.route fallback), T13 history icons. Root cause of 0-count types CONFIRMED: enum rejection silently swallowed in _saveToHistory (:617-634) while push fires + badge drifts. Deferred backlog in plan: partner-online, weekly progress digest, DM reactions, mutual-wave surface.
DISPATCHED (parallel, all NO-COMMIT): Track A = BE T1+T6 (notificationJobs import, email unsubscribe). Track B = BE T5->T2->T3->T4->T9->T10->T11 (notification core). Track C = APP T7+T12+T13 (token capture, router, history). File sets disjoint. Gate = T14 (verify tips fb7b60d/243eafa unmoved, review uncommitted diffs, smoke, single commit on user go-ahead).
Blanket Bash allow added to app .claude/settings.local.json (user request). learningJobs.js modified externally mid-flight (user/linter change: tiered vocab review reminders) — Track B informed via its own file reads; do not revert.
Track C (APP T7+T12+T13): COMPLETE. analyze 0 errors, zero commits, 6 files touched. NEW CONFIRMED BUG handed off: sendScheduledRoomStarted/Reminder (notificationService.js:896-945) gate on nonexistent singular user.fcmToken -> always early-return, NEVER send. Fix after Track B lands (same file). C concerns for gate review: stale duplicate cold-start switch in splash; room_mention/srs/streak route to best-available tabs; data.route fallback for /voicerooms/:id 404s (no GoRoute).
Tracks A + B still running.
Track A (BE T1+T6): COMPLETE. 139 tests: 138 pass, 1 pre-existing fail only. New: notificationJobs.imports 3/3, emailUnsubscribe 9/9. Zero commits. Gate-review concerns: API_BASE_URL env guess in unsubscribe URL; no rate-limit on unsubscribe GET.
Waiting on Track B, then: fcmToken-legacy fixer (scheduled-room senders) -> gate.
== GATE COMPLETE ==
Track B complete (T5->T2->T3->T4->T9->T10->T11, 26 new tests). Controller fixed scheduled-room fcmTokens-array bug inline.
Gate reviews: BACKEND Approved (0 Crit/Imp; 3 Minor — 2 applied by controller: API_BASE_URL added to gitignored config.env + isValidObjectId guard in verifyUnsubscribeToken; 3rd = rotate weak JWT_SECRET, user/prod action). APP Issues Found (2 Important, both FIXED by controller: I1 data.route fallback now resolves via _resolveKnownRoute allowlist/mapping — /voicerooms + /community map to /tabs/1, unknown -> stay home; I2 social-login registerToken catches now debugPrint). M1 (pre-existing splash duplicate cold-start switch, predates branch) left as recorded cleanup candidate.
Final verify: backend 139 tests 138 pass 1 pre-existing fail; flutter analyze 0 errors; tips frozen 243eafa/fb7b60d; zero commits anywhere.
E-CORE CODE-COMPLETE, ALL UNCOMMITTED. Awaiting user go-ahead for single commit per repo + push + merge. Server steps at ship: set API_BASE_URL on prod host (fallback already correct); recommend JWT_SECRET rotation (separate); ENABLE_SCHEDULER stays on.

# ===== WORKSTREAM G: REELS =====
Spec: docs/superpowers/specs/2026-07-14-reels-design.md (2 review rounds, approved). Plan: docs/superpowers/plans/2026-07-14-reels.md (review fixes applied).
Branches: workstream-g-reels both repos. PER-TASK COMMITS on branch; merge->main at gate on user go-ahead.
Tracks: BE agent T1(fields+5-feed exclusion+policy flag)->T2(reels feed endpoint, cursor=min RAW window, isLiked mapped, REELS_ENABLED)->T3(180s controller cap, auto-hide>=2 via Report collection, admin restore authorizeRole). APP agent T4(grid+segmented-enum tab+policy gate)->T5(swipe feed+3-controller pool+action rail; report via NEW POST /reports method — NOT /moments/:id/report)->T6(creation+prompt camera+composer re-enable). Gate T7.
CRITICAL CONTRACT: reels reports MUST post to /api/v1/reports (type moment) or auto-hide never fires (app's existing report path uses the per-moment array endpoint).
Node v24 for backend tests; baseline 1 pre-existing failure (profileVisitCleanup).
== USER INSTRUCTION ("make it automatic"): full-auto pipeline for Workstream G — gate review + fixes + MERGE TO MAIN + PUSH proceed WITHOUT further user confirmation once both tracks pass. Device smoke checklist delivered post-merge as user verification. ==
== WORKSTREAM G SHIPPED (full-auto per user instruction): gates BOTH Approved (backend 2 minors — dangling-url ordering FIXED e46b700, ms-tie cursor documented; app 4 minors — failed-controller eviction FIXED 64301ed, pool index-race/promptId-gating/like-double-fire recorded). Merged+pushed main: backend 3e307cf, app 890d218. App v1.7.0+10557. 216/217 backend tests (baseline), analyze 0 errors. Recorded minors for future pass: pool index-reuse race (narrow), promptId isReel-gating in background upload, like in-flight guard, Reels l10n key. ==
