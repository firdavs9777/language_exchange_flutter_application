# CLAUDE.md — BananaTalk Flutter

Working agreements for any Claude session in this repo. Read this end-to-end at the start of every session. Updated 2026-05-14.

---

## Project context

BananaTalk is a language-exchange mobile app at ~1K active users. The product is honest about the friendship / dating / cultural-exchange spectrum that language exchange actually occupies — competing with HelloTalk and Tandem, neither of whom acknowledge the social reality of the surface.

**Architecture:** this Flutter client (iOS + Android + web) talks to a Node.js/Express backend at `language_exchange_backend_application/` (paired repo, user-authorized for direct changes) over JWT-authenticated REST. Persistence (Atlas), voice rooms (LiveKit), email (Mailgun), push (Firebase), and AI (OpenAI) all live in the backend. The client is Riverpod-first, GoRouter-routed, with a global `callOverlayNavigatorKey` above GoRouter for system-level overlays.

**Monetization:** VIP subscription at $7.99/month via native Apple App Store + Google Play (no RevenueCat). Daily quotas gate AI Study chips for non-VIP users; voice rooms and waves have separate per-tier caps. The unit economics work above ~7% free→VIP conversion. Subscription state lives on `User.vipSubscription` server-side; client mirrors it via `userProvider` + `quotaSnapshotProvider`.

**Active areas:** AI Study (Step 9-13A — 5 tutor chips with daily quotas, paywall, analytics fully shipped to main 2026-05-13), Community (Step 14 in planning — voice room block enforcement + anonymous profile views + functional admin reporting). Recent waves are documented under `docs/superpowers/plans/` and `docs/superpowers/recon/`. Product surface descriptions in `docs/AI_STUDY_PROCESS.md` and `docs/COMMUNITY_PROCESS.md`.

---

## Working agreements

**Cadence.** Drive uninterrupted through plans. Surface only at task boundaries (G1 — the manual smoke gate) or on a genuine blocker (missing env var, file path doesn't exist, scope conflict). Don't stop mid-task to ask permission for things the plan already authorized.

**Recon → Plan → Execute → Smoke → Merge.** Never skip a step. Each step gets its own commit (or commit set). The recon makes the plan honest; the plan makes the execution mechanical; the smoke makes the merge safe.

**Plans are docs, not chat messages.** Plans live at `docs/superpowers/plans/YYYY-MM-DD-stepNN-name-plan.md`. Recons at `docs/superpowers/recon/YYYY-MM-DD-stepNN-name-recon.md`. Both committed before execution. The chat is for clarifying questions; the markdown is the contract.

**No execution without an approved plan.** Plan revisions happen on a `feat/stepNN-shortname-planning` branch, separate from the `feat/stepNN-shortname` execution branch. The user approves the plan before any code changes start.

**Scope discipline.** A wave handles a defined set of issues. Out-of-scope items go to `docs/manual-todos.md` under Queued engineering. No "while I'm here let me also fix..." Surface anything that looks like scope creep before expanding.

---

## Commit conventions

Conventional commits: `feat(area): subject` / `fix(area): subject` / `docs(area): subject` / `chore: subject` / `refactor: subject`. Areas in active use here: `tutor`, `vip`, `privacy`, `safety`, `analytics`, `livekit`, `plans`, `recon`, `manual-todos`.

- **Subject**: present tense, lowercase first letter after the colon, no trailing period, max 72 chars.
- **Body**: wrap at 72. Explain what + why + edge cases handled. Reference audit issues by number, plan task IDs, recon findings.
- **No `Co-Authored-By` lines.** No marketing copy. No emoji in commit messages.
- **Each plan task = one commit.** Don't bundle tasks. Don't split a task across commits unless the plan explicitly says so.
- **Multi-line bodies use HEREDOC** to preserve formatting: `git commit -m "$(cat <<'EOF' ... EOF\n)"`.

Examples (real, from the log):

```
feat(livekit): B4 — active_call_screen on LiveKit renderers + quality + reconnect banner
fix(livekit): C2 — iOS audio session defaults + Bluetooth permission
feat(tutor): paywall-shown analytics + persona-aware copy + CTA telemetry
docs(plans): Step 14 safety wave plan revision 3
```

---

## Branch naming

- **Feature work:** `feat/stepNN-shortname` (e.g. `feat/step13a-vip-gating`, `feat/step14-safety-wave`)
- **Planning:** `feat/stepNN-shortname-planning` — separate from execution; plan revisions happen here, never on the execution branch
- **Hotfix:** `fix/short-description`
- **Chore:** `chore/short-description` (this file, docs cleanups, etc.)
- **Merge to main:** always `--no-ff` to preserve branch history. Delete the local feature branch after merge.
- **Both repos use the same branch name** for a wave so the cross-repo correspondence is obvious.

---

## Tech stack defaults

When introducing something new in this repo, use the existing tool. Don't reinvent.

- **Framework:** Flutter 3.24+, Dart SDK 3.10+. Targets iOS, Android, and web (web is best-effort — voice + push + IAP don't work there).
- **State management:** Riverpod 2.x via `flutter_riverpod`. `Provider`, `StateNotifierProvider`, `FutureProvider`, `StreamProvider`. NO `Provider` package (the older one), NO `Bloc`, NO `GetX`, NO `setState` for shared state.
- **Routing:** GoRouter 14.x. Single `appRouter` instance at `lib/router/`. Routes are typed via the existing patterns. NO `Navigator.push`/`pushNamed` for normal navigation — use `context.go` / `context.push` / route names from `lib/router/route_names.dart`.
- **Global overlay navigator:** `callOverlayNavigatorKey` (`lib/main.dart`) — a separate `Navigator` above GoRouter for system-level overlays (incoming-call modal, paywall, suspended-account screen). The Step 13A canonical pattern. Use this for anything that needs to render *over* the current route regardless of which tab the user is on.
- **HTTP client:** `lib/services/api_client.dart` — central `ApiClient` with quota detection, 401 refresh, and global error handling. ALL backend calls go through it. NO direct `http.get`/`http.post` in feature code. NO bypass via `Dio`.
- **JSON serialization:** Manual `fromJson`/`toJson` in model classes. NO `json_serializable`, NO `built_value`, NO `freezed` (the existing models don't use them; don't introduce a code-gen dependency for one feature).
- **Local storage:** `shared_preferences` for key-value (auth token, user prefs, feature flags). `flutter_secure_storage` for credentials only. NO Hive, NO Isar, NO Drift/sqflite. If you think you need a local DB, you probably need a server endpoint instead.
- **Audio:** `just_audio` for playback, `flutter_sound` for recording. `audio_session` for routing/interruption handling. The canonical wrappers are `TutorVoiceService` / `PronunciationVoiceService` — mirror their lifecycle handling for new audio features.
- **Voice rooms:** `livekit_client` 2.7+. The canonical layer is `lib/services/call_livekit_manager.dart` for 1:1 calls and `lib/services/voice_room_manager.dart` for multi-party. Migration off the legacy `webrtc_service.dart` is in progress on the current `feat/step8-wave-bc` branch.
- **Incoming-call UI:** `flutter_callkit_incoming` — native CallKit on iOS, full-screen activity on Android. Initiated from FCM data messages by `lib/services/notification_service.dart`.
- **Push & analytics:** `firebase_messaging` (FCM data + notification messages) + `firebase_analytics` (typed wrapper at `lib/services/analytics_service.dart`). NO Mixpanel, NO Amplitude — Firebase Analytics is the canonical surface. Events documented in `analytics_service.dart`.
- **Localization:** Flutter's `gen_l10n` with `.arb` files at `lib/l10n/`. NO `easy_localization`, NO `i18n` package. New user-facing strings MUST go through `.arb` files; never hardcode English.
- **Imports:** ALWAYS `package:bananatalk_app/...`. NEVER relative imports (`../../../services/...`). Lint-enforced via `analysis_options.yaml` — `always_use_package_imports`. Aligned with the user's preference for explicit alias-style imports (see web-frontend convention).
- **Subscriptions:** `in_app_purchase: ^3.1.11` — native StoreKit (iOS) + Google Play Billing. Wrapper at `lib/services/subscription_service.dart`. NOT RevenueCat. Webhook race fix (3-attempt retry on `transactionId` race) is in the wrapper — don't remove it.

---

## Anti-patterns — don't do these

- **Don't add RevenueCat or any subscription wrapper.** Native APIs only.
- **Don't add new HTTP transport.** Everything goes through `ApiClient`. No raw `http.get` / `Dio` instance. Quota detection, 401 refresh, blocked-user banners all hang off `ApiClient`.
- **Don't use relative imports.** `package:bananatalk_app/...` always. Lint will fail; you'll fail the verify step anyway.
- **Don't access `BuildContext` after an async gap without `mounted`.** `if (!mounted) return;` after every `await` that's followed by a `context.*` call. The lint catches some but not all cases.
- **Don't call providers in `initState`.** Use `ref.read` in callbacks, `ref.watch` in `build`, or `ref.listen` in build. For init-time work, use a `FutureProvider` or a `ProviderObserver`. The "ref inside initState" pattern leaks listeners and breaks hot reload.
- **Don't introduce a new state-management library.** Riverpod is the answer. If something feels hard in Riverpod, it's usually a sign the state is in the wrong place, not that you need Bloc.
- **Don't bypass GoRouter.** `Navigator.of(context).push` works but breaks deep linking + the analytics layer. Use `context.push('/route')` or route-name constants. The only exception is the `callOverlayNavigatorKey` for overlays explicitly designed to live above GoRouter.
- **Don't hardcode strings.** Every user-facing string goes through `.arb`. New strings need an entry in `app_en.arb` minimum; the other locales fall back if untranslated.
- **Don't create new screens without an l10n entry.** The screen will ship broken for non-English users.
- **Don't add new dependencies without explicit user approval.** When in doubt, find an existing pattern. The repo already has more than enough surface area.
- **Don't refactor unrelated code during a feature wave.** Refactoring is its own wave with its own plan.
- **Don't catch errors silently.** Either handle + report to analytics + recover, or let it bubble to the global handler in `main.dart`. `catch (e) {}` is forbidden.
- **Don't add TODOs to `main`.** Open TODOs go to `docs/manual-todos.md`. Code comments that say "TODO" without a queued task are noise.
- **Don't trust client-side time/identity/money.** Server is source of truth for "what day is it" (UTC midnight resets), user IDs, and quota counts. Client mirrors server state, never overrides it.
- **Don't ship aspirational UI.** If the backend doesn't support it, don't add the screen. The product process docs (`docs/AI_STUDY_PROCESS.md`, `docs/COMMUNITY_PROCESS.md`) track what's actually working vs. aspirational — mark new features ❌ until they're verified end-to-end.

---

## Decision-making defaults

- **Time / identity / money: server is source of truth.** Client displays what the server returned. Don't compute quotas locally, don't trust client-side `DateTime.now()` for anything that resets daily.
- **Fail closed on auth, fail open on telemetry.** A 401 from `ApiClient` triggers refresh-or-logout. An analytics fire that throws is debug-logged and swallowed — never blocks the user.
- **Prefer existing primitives.** `ApiClient` for HTTP, `analyticsService` for events, `callOverlayNavigatorKey` for system overlays, `quotaSnapshotProvider` for quota state, `userProvider` for current user. Don't reinvent.
- **State location: as local as possible.** Page-scoped state stays in the page. Cross-page state lives in a Riverpod provider. Global state (auth, current user, quotas) lives in app-level providers wired in `main.dart`.
- **Privacy: server-resolve preferences.** Don't trust the client to send a privacy flag like `isAnonymous`. The server reads the user's `privacySettings` and resolves there.

---

## How to write a plan

Plans live at `docs/superpowers/plans/YYYY-MM-DD-stepNN-name-plan.md`. The canonical format is `2026-05-14-step14-safety-wave-plan.md` (revision 3). Required sections, in order:

1. **Header** — Goal + Architecture + Tech Stack + Recon reference + Branches + Estimated commits + Pacing note
2. **Hard constraints** — out of scope, no new deps, repo branches, commit-message style. Restate every wave so it doesn't drift.
3. **Edge cases handled** — enumerate explicitly. "X happens when Y → behavior is Z."
4. **Design decisions** — numbered, each with rationale and rejected alternatives. The rejected-alternatives section is the meta-skill; it forces the writer to explain *why not the other options*.
5. **File structure** — Modify / Create columns per repo. List every file that gets touched.
6. **Critical decisions** — separate from design decisions; these are architectural choices baked into the implementation (e.g., atomic check-and-increment via pipeline update).
7. **Numbered tasks** — `B1`, `B2`, ... for backend; `F1`, `F2`, ... for Flutter; `G1` for the manual smoke. Each task has explicit Steps (Read / Modify / Verify / Commit).
8. **Verification commands per task** — `flutter analyze`, `flutter test`, `node -c`, `npm test`. Show expected output.
9. **Conventional-commit-format messages drafted, not placeholders.** The executor pastes; the reviewer reads in `git log` later.
10. **Final G1 task** with manual smoke checklist (physical device + telemetry verification).
11. **Cadence guidance + Risk/rollback** at the end. Risk section names the highest-risk task explicitly + the rollback path.
12. **Appendices** — "what's NOT in this wave" restated + any operational notes (env vars to set, manual one-time steps).

If the executor discovers something that wants to expand scope during execution, it goes to `docs/manual-todos.md` Queued engineering, not into the current plan.

---

## How to write a recon

Recons live at `docs/superpowers/recon/YYYY-MM-DD-stepNN-name-recon.md`. The canonical format is `2026-05-14-step14-safety-wave-recon.md`. Required:

1. **Cross-cutting findings up front.** Existing infrastructure to reuse, primitives that the plan should mirror. Saves the planner from reinventing.
2. **Per-issue sections** — for each item under investigation, give file paths, line numbers, and actual code snippets. "What exists today" + "what's missing" + implications.
3. **Edge cases the plan must address** — these flow into the plan's Edge cases section.
4. **Three-option comparison for any meaningful design choice.** Don't pre-decide; lay out A/B/C with tradeoffs so the user can push back.
5. **Punted findings** — things found out of scope. Name them, file them to `docs/manual-todos.md` Queued engineering, and reference the file path in the recon.

Recon is read-only. No fixes proposed. No plan drafted. Just facts.

---

## Manual TODOs queue

`docs/manual-todos.md` has three sections:

- **👤 Humans only** — Firebase Console config, App Store submissions, OpenAI billing dashboard, physical-device smoke tests. Things only a real person can do.
- **🛠️ Queued engineering** — bugs/improvements found during recon that are out of scope for the current wave. The next agent session picks these up.
- **✅ Completed** — archive of done items (rare; mostly we just delete or move to Completed when a wave ships).

When a recon finds a bug out of scope, the recon's "Punted findings" section names it AND adds an entry to `manual-todos.md` Queued engineering. When a plan is approved, only the in-scope items execute; out-of-scope stays queued.

---

## Smoke test discipline

Every wave's G1 task has a real smoke checklist. Categories:

- **Backend curl smoke (15 min)** — token + endpoint test, dev server (`npm run dev`), `jq` verification of response shape.
- **Physical device smoke (30-60 min)** — iOS physical + Android physical, real user flows. Sandbox purchases on simulator/emulator are flaky and don't exercise the actual webhook race.
- **Telemetry verification** — Firebase DebugView for analytics events, email inbox for transactional, OpenAI dashboard for cost spikes.
- **Database verification** — query the actual records changed (use the MongoDB MCP server or `mongo` shell against Atlas).

Smoke test is non-negotiable. **Don't merge without it.** A passing `flutter analyze` is not a smoke test. "Looks fine in simulator" is not a smoke test. Especially on Android — `google-services.json` analytics_service block has gone missing before despite the Firebase Console showing the link.

---

## What to surface to the user

The agent drives uninterrupted through tasks. Surface only when:

- A required environment variable or external state is missing (Firebase Console settings, App Store Connect config, OpenAI API key).
- A plan task discovers the scope was wrong — the recon was inaccurate, the plan needs revision before continuing.
- The G1 smoke checklist is reached and needs the user to run physical device tests / inspect Firebase DebugView.
- Genuine blocker: file doesn't exist, dependency conflict, security concern, iOS/Android-specific platform issue that requires a Mac with Xcode / Android Studio installed.

**Do NOT surface for:**

- Routine questions about file paths (use `grep` / `Read`).
- Permission to make obvious changes the plan already approved.
- "Should I commit now?" — yes, after each plan task per the plan.
- "Should I run `flutter analyze`?" — yes, per the Verify step in each task.

---

## Things specific to this project

- **The `callOverlayNavigatorKey` is the Step 13A canonical pattern** for any UI that needs to render *over* the current route tree regardless of which tab the user is on (incoming-call modal, paywall, suspended-account screen). Don't try to integrate these into GoRouter — they'll fight the bottom-nav tab state.
- **`ApiClient` does global quota detection.** A 429 with `code: 'QUOTA_EXCEEDED'` from any chip endpoint triggers the paywall via the overlay navigator. Don't catch the 429 yourself in feature code — let it bubble; the global handler renders the paywall.
- **Roleplay sessions bypass chat quota.** Locked design decision from Step 13A: messages sent inside an active roleplay session don't count against the daily chat cap. The backend's `checkChatQuotaSessionAware` middleware handles this; the client doesn't need to special-case it.
- **iOS Podfile.lock is volatile.** `flutter run` / `pod install` regenerates it. Don't include `ios/Podfile.lock` modifications in feature commits unless an actual dependency change drove them. If `git status` shows it dirty mid-task, leave it alone.
- **The legacy `webrtc_service.dart` is being phased out** in favor of `call_livekit_manager.dart`. The current `feat/step8-wave-bc` branch is mid-migration. New 1:1 call code goes against the LiveKit manager only.
- **`flutter_callkit_incoming` requires native config.** iOS: `Info.plist` background modes + entitlements. Android: full-screen activity permission (Android 14+). Don't enable the package in `pubspec.yaml` without verifying the native config — it'll silently no-op.
- **Android `google-services.json` analytics_service block is fragile.** Has gone missing despite the Firebase Console showing analytics linked. If Firebase DebugView shows nothing on Android after a release-config rebuild, re-download `google-services.json` from the Firebase Console first.
- **`AI_QUOTA_ENABLED=false` on backend is the emergency kill switch** for tutor chip quotas. If users report unexpected paywall hits and the backend isn't down, check this env var before debugging client code.
- **Imports are lint-enforced as `package:bananatalk_app/...`.** Relative imports will fail `flutter analyze`. This is the explicit Flutter analogue of frontend's path-alias preference.

---

## Reference shortlist

- **Canonical plan format:** `docs/superpowers/plans/2026-05-14-step14-safety-wave-plan.md`
- **Canonical recon format:** `docs/superpowers/recon/2026-05-14-step14-safety-wave-recon.md`
- **Product process docs:** `docs/AI_STUDY_PROCESS.md`, `docs/COMMUNITY_PROCESS.md`
- **Manual TODOs queue:** `docs/manual-todos.md`
- **Global HTTP client:** `lib/services/api_client.dart`
- **Global overlay navigator:** `callOverlayNavigatorKey` in `lib/main.dart`
- **Analytics surface:** `lib/services/analytics_service.dart`
- **LiveKit transport (1:1):** `lib/services/call_livekit_manager.dart`
- **LiveKit transport (voice rooms):** `lib/services/voice_room_manager.dart`
- **Auth + current user state:** `lib/providers/user_provider.dart`
- **Quota state:** `lib/providers/quota_snapshot_provider.dart`
- **Backend repo (paired, authorized for direct changes):** `/Users/davis/Desktop/Personal/language_exchange_backend_application`
