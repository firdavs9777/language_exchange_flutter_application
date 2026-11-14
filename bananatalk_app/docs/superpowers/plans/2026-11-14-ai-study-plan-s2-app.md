# AI Study, Plan S2 (app, phase 1: foundations) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The AI Study tab stops showing things that cannot work, understands the server's new tutor and level answers, reports what learners do, and paints its top section at once.

**Architecture:** Small fixes go in place. A study event tracker reuses the batching approach of the paywall tracker behind a server flag. Level and tutor changes are additive readers of fields the server now sends. A per-user disk cache paints the hub's top section on first build only.

**Tech Stack:** Flutter, Riverpod, the existing `ApiClient`, `shared_preferences`.

**Spec:** `docs/superpowers/specs/2026-11-14-ai-study-path-design.md`, section 5. Server side is Plan S1 (built); its contract is repeated below and is binding.

**Repo and branch:** app repo, new worktree `/Users/davis/Desktop/Personal/wt-study-app`, branch `feat/ai-study-foundations-app` from `origin/main` (fetch first; another session pushes to main). Code lives in `bananatalk_app/`.

## Server contract (as built)

- `GET /api/v1/app-config` → `studyEventsEnabled` (boolean; absent means false).
- `POST /api/v1/study/events`, authenticated. Body `{ events: [{ name, language?, kind?, score?, total?, detail?, clientAt? }] }`, 1 to 50 items, at most 30 calls per 15 minutes; `201 { success, stored, dropped }`; `404` while off. `name` is one of `tab_opened`, `session_started`, `step_started`, `step_finished`, `session_finished`, `feature_opened`, `level_check_started`, `level_check_finished`. `detail` at most 40 characters, `kind` at most 24, `language` 2 to 10 characters, `score` and `total` whole numbers from 0 to 1000.
- `GET /api/v1/study/pack` → unchanged, plus `levelMeasured` (boolean) when the server's level switch is on; absent otherwise. With it on, `level` is the level for that language in force today; `levelPlaced` keeps its old meaning and must not be used to decide whether a level is measured.
- A station completion response carries `levelChange: { from, to }` only when a change happened; the new level applies from the next day.
- A level check takes effect at once: after it completes the app must fetch the pack again.
- Tutor send-message `429` bodies keep `error: 'quota_exceeded'` and may add `reason`: `daily_conversations` (today's 5 conversations are used), `conversation_full` (this conversation has its 10 learner messages), `conversation_starting` (another request is opening this conversation; retry after 2 seconds, header `Retry-After: 2`). The quota snapshot's `chat.remaining` now counts conversations left today.
- `GET /api/v1/learning/progress/weak-areas` → `{ success, data: { weakAreas: [...] } }`.
- The daily reminder push keeps `type: 'daily_drop'`.

## Global Constraints

- With `studyEventsEnabled` false the app sends no new request. Every other change in this plan either fixes something broken or reads a field the server sends only when its own switch is on; with those fields absent the app behaves as today.
- New user-facing strings are allowed in this plan. Each is added to all 19 `lib/l10n/app_*.arb` files, translated, and the non-English ones are listed in `docs/REMAINING_WORK.md` as machine-drafted. Run the project's localization generation and the existing l10n tests.
- Always `package:` imports. Never run `dart format` on a file you did not create. Stage files by path.
- Do not touch `lib/pages/moments/reels/`, `lib/providers/reels_provider.dart`, `lib/services/reel_view_tracker.dart`.
- Use `ApiClient` for new requests. Every new top-level provider is classified in `lib/services/session_reset.dart`; `test/services/session_reset_test.dart` passes on `main` and must keep passing.
- Per-user disk data is keyed by the signed-in user id, cleared on sign-out, and painted only on a provider's first build.
- Never add a Co-Authored-By or any Claude attribution line. Every commit updates `docs/REMAINING_WORK.md` and lists what is still open in its body.
- No version bump, no release build, no push to `main`.
- `flutter analyze` stays at 0 errors with no new warnings; the full `flutter test` stays green.

## Review Focus

1. The events flag turns off during a session: nothing queued is sent. Sign-out drops the queue. (Task 1)
2. The server's level switch is off (no `levelMeasured`, no `levelChange`): the hub and the pack look exactly as today. (Task 3)
3. A tutor `429` with an unknown `reason`, or none: today's upgrade sheet, unchanged. (Task 2)
4. `conversation_starting` twice in a row: one retry only, then a plain "try again" state, never a loop and never the upgrade sheet. (Task 2)
5. The cached hub top section belongs to another user, is from yesterday, or is corrupt: it is not painted. (Task 4)

---

### Task 1: Study events

**Files:**
- Modify: `lib/models/app_config.dart`, `lib/providers/provider_root/app_config_providers.dart`, `lib/service/endpoints.dart`, `lib/services/session_reset.dart`, the study screens named below
- Create: `lib/services/study/study_tracker.dart`, `lib/services/study/study_events_api.dart`
- Test: `test/study/study_tracker_test.dart`, `test/study/study_event_points_test.dart`

**Interfaces (Produces):**

```dart
final bool studyEventsEnabled;                      // json['studyEventsEnabled'] == true
final studyEventsEnabledProvider = Provider<bool>(...);
class StudyEvent { static const tabOpened = 'tab_opened', sessionStarted = 'session_started',
  stepStarted = 'step_started', stepFinished = 'step_finished', sessionFinished = 'session_finished',
  featureOpened = 'feature_opened', levelCheckStarted = 'level_check_started',
  levelCheckFinished = 'level_check_finished'; }
void studyLog(String name, {String? language, String? kind, int? score, int? total, String? detail});   // never throws
final studyTrackerProvider = Provider<StudyTracker>(...);      // user-scoped
```

Rules:

- The tracker has the same behaviour as `lib/services/paywall/paywall_tracker.dart` (queue in memory, flush after 10 seconds, at 20 queued, when the app leaves the foreground, chunks of 50, a failed send drops the chunk, nothing built or sent while the flag is off, a queue left when the flag turns off is dropped, dispose drops the queue). Share the mechanism if that is a small change (a generic batch queue both use); otherwise mirror it. Say which in the report.
- Where events are logged:
  - `tab_opened`: once each time the AI Study tab becomes the selected tab (not on every rebuild), with the pack's language when known.
  - `session_started`: when `DailyPackFlow` opens. `step_started` / `step_finished` per station with `kind` = station kind and, on finish, `score` and `total` from the completion response. `session_finished` when the day-complete sheet shows.
  - `feature_opened`: each tile in `StudyFeatureGroups`, with `kind` = the feature slug.
  - `level_check_started` / `level_check_finished` in `PlacementScreen`, with `detail` = the resulting level on finish.
- A test seam like `paywallLogSpy` is allowed.

- [ ] **Step 1: Write the failing tests** (tracker: mirror `test/paywall/paywall_tracker_test.dart`, including flush after the flag turns off and dispose; event points: widget tests with the spy):

```dart
testWidgets('opening the pack logs session_started once', ...);
testWidgets('a completed station logs step_started then step_finished with kind, score and total', ...);
testWidgets('the day-complete sheet logs session_finished', ...);
testWidgets('tapping a feature tile logs feature_opened with its slug', ...);
testWidgets('selecting the study tab logs tab_opened once, not on rebuild', ...);
```

- [ ] **Step 2: Run** `flutter test test/study/`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/study/ test/paywall/ test/services/session_reset_test.dart` and `flutter analyze`. Expected: PASS, 0 errors.
- [ ] **Step 5: Commit** `feat(study): study events behind studyEventsEnabled (off)`.

---

### Task 2: Things that could not work, and the tutor's new answers

**Files:**
- Modify: `lib/services/ai_service.dart` (weak areas, around line 1155), `lib/pages/learning/main/sections/recommended_tile.dart`, `lib/pages/learning/main/sections/study_features.dart` and `study_feature_groups.dart`, `lib/pages/learning/main/sections/progress_card.dart`, `lib/pages/learning/main/learning_main_screen.dart` (the achievements request on open), the tutor chat screen and its send path (`grep -rn "tutor/sessions" lib`), `lib/services/api_client.dart` only if the `QuotaError` needs the `reason`, `lib/l10n/app_*.arb`
- Test: `test/study/weak_areas_shape_test.dart`, `test/study/hub_tiles_test.dart`, `test/study/tutor_quota_reason_test.dart`

Rules:

- Weak areas: accept `data` as a list (old) or as `{ weakAreas: [...] }` (what the server sends). The recommended tile then appears when there is at least one weak area.
- The Challenges tile, and the Achievements link on the progress card, are removed from the hub; the tab no longer requests achievements when it opens. Their screens and routes stay in the code.
- Tutor `429`:
  - `reason == 'conversation_full'`: no upgrade sheet. The chat shows a short inline notice with one button that starts a new conversation with the same persona. New strings: `tutorConversationFull` = "This conversation is full." and `tutorStartNewConversation` = "Start a new conversation".
  - `reason == 'conversation_starting'`: wait 2 seconds and send the same message once more, silently. If that also fails with the same reason, show the chat's existing send-failed state. Never the upgrade sheet.
  - `reason == 'daily_conversations'`, any other reason, or none: today's upgrade sheet, unchanged.
- Where the hub or the tutor shows how much free use is left for chat, the wording counts conversations. If today's string already reads naturally for conversations, leave it and say so; otherwise add `tutorConversationsLeft` = "{count} conversations left today" (with a plural form).

- [ ] **Step 1: Write the failing tests.**

```dart
test('weak areas parse from the object shape and from the old list shape', ...);
testWidgets('the recommended tile shows when the server reports a weak area', ...);
testWidgets('the hub has no Challenges tile and the progress card no Achievements link', ...);
testWidgets('opening the tab does not request achievements', ...);
testWidgets('conversation_full shows the notice and the new-conversation button, not the upgrade sheet', ...);
testWidgets('conversation_starting retries once after 2 seconds and then succeeds silently', ...);   // fakeAsync
testWidgets('conversation_starting twice shows send-failed, no loop, no upgrade sheet', ...);
testWidgets('daily_conversations, an unknown reason and no reason all open the upgrade sheet', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Add the strings to all 19 ARB files and regenerate localizations.
- [ ] **Step 4: Run** `flutter test test/study/ test/learning/ test/l10n/ test/widgets/` and `flutter analyze`. Expected: PASS, 0 errors.
- [ ] **Step 5: Commit** `fix(study): the recommended tile shows, dead tiles go, and the tutor's new answers are understood`.

---

### Task 3: The level the server says

**Files:**
- Modify: the daily pack model (`grep -rn "levelPlaced" lib`), `lib/pages/learning/main/study_hub.dart` (header chips), `lib/pages/learning/main/sections/today_pack_row.dart`, `lib/pages/learning/daily/daily_pack_flow.dart` (completion handling and the day-complete sheet), the placement screen, `lib/l10n/app_*.arb`
- Test: `test/study/pack_level_test.dart`

Rules:

- The pack model reads `levelMeasured` (nullable: absent when the server's switch is off) and a completion's `levelChange` (`from`, `to`; absent or null means no change).
- Hub level chip: when the pack has loaded, it shows the pack's `level` for the pack's language instead of the profile's shared level. Before the pack loads, and when the pack has no level, it shows what it shows today.
- "Find your level" is offered on the pack row when `levelMeasured == false`; when `levelMeasured` is absent, today's rule (`levelPlaced`) applies unchanged.
- A completion with a `levelChange` shows one line on the step result and on the day-complete sheet: new string `studyLevelChanges` = "From tomorrow your practice moves to {level}." Nothing else changes that day.
- After a level check completes, the pack provider is refreshed before the learner returns to the hub.

- [ ] **Step 1: Write the failing tests.**

```dart
test('a pack without levelMeasured parses as null and a completion without levelChange as null', ...);
testWidgets('levelMeasured false offers Find your level; true does not; absent follows levelPlaced', ...);
testWidgets('the hub chip shows the pack level once the pack has loaded', ...);
testWidgets('a completion with levelChange B1 -> B2 shows the from-tomorrow line', ...);
testWidgets('a completion without levelChange shows no such line', ...);
testWidgets('finishing a level check refetches the pack', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/study/ test/learning/ test/l10n/` and `flutter analyze`. Expected: PASS, 0 errors.
- [ ] **Step 5: Commit** `feat(study): the tab shows the level the server serves and says when it will change`.

---

### Task 4: The tab paints at once

**Files:**
- Create: `lib/services/study/study_hub_cache.dart`
- Modify: the providers behind the hub's top section (the pack summary and learning progress providers), `lib/pages/learning/main/study_hub.dart`, `lib/providers/provider_root/auth_providers.dart` (sign-out clear, next to the other first-page caches), `lib/services/session_reset.dart`
- Test: `test/study/study_hub_cache_test.dart`, `test/study/study_hub_first_paint_test.dart`

**Interfaces (Produces):**

```dart
class StudyHubSnapshot { final String dateKey; final String? language; final String? level;
  final int streak; final int stationsDone; final int stationsTotal; final DateTime savedAt; }
class StudyHubCache {
  Future<StudyHubSnapshot?> read(String userId);       // null when missing, corrupt, or another user's
  Future<void> write(String userId, StudyHubSnapshot s);
  Future<void> clearAll();
}
```

Rules:

- Stored per user under `study_hub_v1_<userId>` (not device-level, so sign-out clears it; sign-out also calls `clearAll()` beside the other first-page caches).
- Follow `lib/services/community_first_page_cache.dart` for the shape: an epoch counter so a write that started before sign-out cannot land after it.
- Painted only on the hub's first build in a process, only when the snapshot's `dateKey` is today (the device's local date), and only for the signed-in user. It fills the streak chip, the level chip and the pack row's progress ("2 of 4 done") instead of the spinner. The live answer replaces it in place; a failed live request leaves the cached values on screen with today's error handling for the pack row.
- Written after each successful pack load and after each station completion.
- The cached pack row is tappable and opens the pack flow as usual (the flow loads the real pack).

- [ ] **Step 1: Write the failing tests.**

```dart
test('write then read returns the snapshot for that user only', ...);
test('corrupt data and another user id read as null', ...);
test('a write that started before clearAll does not land after it', ...);
testWidgets("today's snapshot paints streak, level and progress on the first frame, no spinner", ...);
testWidgets("yesterday's snapshot is not painted", ...);
testWidgets('the live answer replaces the cached values in place', ...);
testWidgets('a rebuild after live data does not repaint from disk', ...);
testWidgets('sign-out clears the snapshot', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/study/ test/learning/ test/services/` and `flutter analyze`. Expected: PASS, 0 errors.
- [ ] **Step 5: Commit** `perf(study): the study tab paints its top section from disk`.

---

### Task 5: Whole-app check and handoff

**Files:**
- Create: `docs/releases/ai-study-foundations-app-handoff.md`
- Modify: `docs/REMAINING_WORK.md`

- [ ] **Step 1: Run** `flutter analyze` and the full `flutter test`; record exact totals. Expected: 0 errors, no new warnings, all tests pass.
- [ ] **Step 2: Flag-off and switch-off check**, from the code, with file references in the handoff: no call to `/study/events` while the flag is off; with no `levelMeasured` and no `levelChange` in the server's answers the hub, pack row and completion screens take today's paths; a tutor `429` without `reason` opens today's sheet.
- [ ] **Step 3: Write the handoff:** what ships and what each server switch needs from this build (events flag; the server's level switch must stay off until this build is out); what changes for everyone with no flag (recommended tile, removed tiles, tutor notices, first paint); device checks (a tutor conversation to its tenth message and one more; a sixth conversation in a day; the reminder push tap; a level check then the hub; the tab on a cold open with the network off; sign out and in as another user); the machine-drafted strings; what is still open (phases 2 and 3, the owner's server scripts from the backend guide).
- [ ] **Step 4: Update** `docs/REMAINING_WORK.md`.
- [ ] **Step 5: Commit** `docs(study): app handoff and device checks for the foundations`.
