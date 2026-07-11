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
