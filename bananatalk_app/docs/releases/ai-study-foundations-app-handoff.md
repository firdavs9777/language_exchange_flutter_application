# AI Study foundations (app side, Plan S2) - handoff

Branch `feat/ai-study-foundations-app` (base app main 0686aaac). Not built, not versioned, not submitted, not pushed. The server half is deployed with every switch off. Server guide: `docs/rollout/ai-study-foundations.md` in the backend repo.

**Nothing in this build was checked on a device.** Every claim below comes from reading the code, grep and automated tests. All paths are under `bananatalk_app/`.

Goal of this build: let the server record how people use the AI Study tab (events), make the tab tell the truth about the level the server serves, handle the tutor's new refusal reasons, fix hub parts that could never work, and paint the tab's top section from disk instead of a spinner.

One contract correction made during the build: the pack has **no top-level `level`**. With the server's level switch on, the level in force is `requestedLevel` (`levelMeasured` is present only then). `levelPlaced` keeps its old meaning and is not used to decide whether a level is measured when `levelMeasured` is present.

## 1. What changes for every user of this build, with no flag

These parts have no switch. They are the visible or behavioural differences from the current release:

1. **The recommended tile can appear.** The weak-areas answer is read in the server's real shape (`data.weakAreas`, items `{topic, category, score, mistakeRate}`), so a learner with a weak quiz area now sees the "recommended" tile; before, it could never show. Only quiz areas count. (`lib/services/ai_service.dart` `parseWeakAreas`, `lib/models/ai/ai_quiz_model.dart` `WeakArea.fromJson`, `pickRecommended` in `lib/pages/learning/main/study_features.dart`.)
2. **Challenges and the Achievements link are gone from the hub.** The Challenges tile (11 tiles now, not 12) and the progress card's Achievements shortcut are removed. The tab no longer requests achievements on open, and the achievement-unlock overlay no longer fires from the tab. The screens and routes still exist; the legacy Learn tab still links Challenges.
3. **Tutor notices.** A tutor `429` with `reason: conversation_full` shows an inline "This conversation is full." with a "Start a new conversation" button instead of the upgrade sheet. `conversation_starting` is retried once, silently, after 2 seconds; a second refusal shows the chat's existing send-failed banner with the text restored. `daily_conversations` (today's 5 conversations used), any other reason, and no reason open the upgrade sheet exactly as before. The same refusals are handled in roleplay.
4. **The tab's first paint.** The hub's top section (streak, language and level chip, a "Today's pack 2/4" row) paints from a per-user snapshot on disk while live data is loading, instead of a spinner. Live data replaces it and it never comes back in that session. It is used only while loading, only when the pack's date and the save day are today (device date) and it is under 24 hours old, and it is cleared on sign-out. The row's tap waits for the real pack and then does what the live row does.
5. **Roleplay now removes a failed message from the list and restores the text.** Before, a failed roleplay send left the message in the list. Now it is removed, the text goes back into the input, and a snackbar says it failed.
6. **The level chip and level check follow the server when it sends `levelMeasured`** (see section 3: with the switch off, nothing differs from today).
7. **"Start a new conversation" is one request per tap** (a second quick tap does nothing while the first is running).

Internal differences (no request, nothing visible):

- New prefs key `study_hub_v1_<userId>` (per account, removed on sign-out).
- `studyTrackerProvider` and `studyHubSnapshotProvider` are user-scoped, `studyEventsEnabledProvider` and `studyHubCacheProvider` app-scoped (`lib/services/session_reset.dart:203, 263, 332, 338`).
- With the events flag off `studyLog` builds nothing: no tracker, no client, no lifecycle observer.
- New strings: `tutorConversationFull`, `tutorStartNewConversation`, `studyLevelChanges` (19 locales each). The orphaned `studyTileChallenges` / `studyTileChallengesDesc` stay because the l10n tests enforce them.

## 2. What each server switch needs from this build

| Server switch (app-config key) | What the app does when it is on |
|---|---|
| `STUDY_EVENTS_ENABLED` (`studyEventsEnabled`) | The tracker batches events in memory and sends them to `POST /study/events` (flush at 20 queued, 10 s after the first, and when the app leaves the foreground; chunks of 50; failures dropped; nothing written to disk). Events: `tab_opened` (each time the tab becomes the selected one, once the first frame settled), `session_started`, `step_started`, `step_finished` (kind, score, total; scores omitted when the station has no questions), `session_finished`, `feature_opened` (kind is the tile slug; `detail` is `locked` or `exhausted` when a sheet follows the tap), `level_check_started`, `level_check_finished` (detail is the resulting level). Turn it on only after this build is out. |
| `STUDY_LEVELS_V2_ENABLED` (`levelMeasured` in the pack, `levelChange` on completions) | The chip shows `requestedLevel`; "Find your level" follows `levelMeasured`; a completion with `levelChange` shows "From tomorrow your practice moves to {level}." under the step result and on the day-complete sheet; the pack and mastery are refetched once, the moment a level check is saved. **This switch must stay off until this build is out.** Older builds would not show the level change and would keep the old pack after a level check. |
| `STUDY_NIGHTLY_TRIM_ENABLED` | Nothing in the app. |

Order: backend deployed (done), this build released and adopted, then `STUDY_EVENTS_ENABLED`, then `STUDY_LEVELS_V2_ENABLED` after watching events for a while (backend guide), then the nightly trim.

## 3. Flag-off and switch-off check: evidence

Verified by reading the code and by grep (`grep -rn "studyEventsURL\|StudyEventsApi\|study/events" lib/`, `grep -rn "studyLog(\|studyTrackerProvider\|studyEventsEnabledProvider" lib/`, `grep -rn "levelMeasured\|levelChange\|offersLevelCheck" lib/`).

**No call to `/study/events` while the flag is off.**
- The endpoint string is used in exactly one place, `StudyEventsApi.send` (`lib/services/study/study_events_api.dart:13`, `Endpoints.studyEventsURL` at `lib/service/endpoints.dart:52`). Its only caller is the tracker's `send` (`lib/services/study/study_tracker.dart:151-153`), built only by `studyTrackerProvider`.
- `studyTrackerProvider` is read in one place: `studyLog` (`study_tracker.dart:193`), after `if (!container.read(studyEventsEnabledProvider)) return;` (`:192`). Flag off: no tracker, no `StudyEventsApi`, no lifecycle observer is built.
- Every event point goes through `studyLog` (`daily_pack_flow.dart:96, 106, 113, 148`; `study_feature_groups.dart:117`; `placement_screen.dart:67, 97`; `study_tab_opened_reporter.dart:71`). No other caller.
- Defence in depth inside the tracker: `log` drops and clears the queue when `enabled()` is false (`study_tracker.dart:77-80`), `flush` re-checks it (`:108-111`), so a flag that turns off after events were queued sends nothing.
- The tab reporter returns before reading the pack when the flag is off (`study_tab_opened_reporter.dart:69`), so it starts no pack fetch.
- The flag is `json['studyEventsEnabled'] == true` with default false (`lib/models/app_config.dart:181, 225`), and `false` while app-config is loading or failed (`lib/providers/provider_root/app_config_providers.dart:55-60`). `studyEventsEnabledProvider` only watches `appConfigProvider`, which the app already loads; no new request.

**Without `levelMeasured` and `levelChange` the hub, pack row and completion screens take today's paths.**
- `levelMeasured` parses to `null` unless the server sends a bool (`lib/models/learning/daily_pack_model.dart:441`). `LevelChange.tryParse` returns null when the key is absent (`:460`, used at `:534`).
- Chip level: `packCefrLevel` (`lib/pages/learning/main/study_hub.dart:424-427`) uses the old order (`servedLevel`, then `requestedLevel`) whenever `levelMeasured` is null.
- "Find your level": `offersLevelCheck` is `!levelPlaced` when `levelMeasured` is null (`daily_pack_model.dart:384`); used by `today_pack_row.dart:46, 53` and `daily_pack_hero_card.dart:143`, replacing `!pack.levelPlaced`, so the result is the same.
- Completion screens: `daily_pack_flow.dart:144` and `:297` and the sheet (`day_complete_sheet.dart:38`) show the level line only when `result.levelChange != null`; absent, nothing is added and no space is taken.
- Level check: the pack and mastery are refetched when the check is saved (`placement_screen.dart:99`, `learn_tab.dart:587-590`). That is a refetch the app already did on return from the check; it now happens once, at save time, and not a second time on return. It does not depend on the switch.

**A tutor `429` without `reason` opens today's sheet.** `QuotaError.reason` is null when the body has none (`lib/services/api_client.dart:951`); `isHandledByChat` is true only for `conversation_full` or `conversation_starting` (`:941-942`); the global hook is called otherwise (`:484`), exactly as before. In the tutor service only the two handled reasons become `TutorSendRefused` (`lib/providers/tutor_provider.dart:142`); every other failure is the old `StateError`. `daily_conversations` also falls to the sheet.

**Result: no flag-safety failure found.** Parts 1 to 5 of section 1 are not behind a switch, by design (the plan's global constraint); they are listed there so none is a surprise.

## 4. Device checks before release (none run yet)

Use a test server. Switch by editing `config/config.env` and `pm2 restart language-app --update-env`; the app reads app-config at start and on resume.

Tutor (no flag):
- [ ] A tutor conversation to its tenth learner message, then one more: the inline "This conversation is full." notice and the new-conversation button; no upgrade sheet; the typed text is kept.
- [ ] A sixth conversation in a day (free user): today's upgrade sheet opens.
- [ ] "Start a new conversation" tapped twice quickly: one new conversation.
- [ ] Roleplay: a refused or failed send removes the message and restores the text; the voice path (see open item 2).
- [ ] The reminder push tap (type `daily_drop`) still opens the right screen.

Tab first paint (no flag):
- [ ] Cold open with the network off: chips and the "Today's pack" row from disk, no spinner; the row's tap does nothing harmful when the pack cannot load.
- [ ] Cold open with a slow network: the cached row shows, then live data replaces it; tapping the cached row shows its spinner and then opens the pack.
- [ ] The tab left open across midnight: yesterday's cached values do not come back.
- [ ] Sign out and sign in as another user: the second user never sees the first user's chips or row.

Level (server's level switch on, test environment):
- [ ] A level check, then the hub: the pack refetches once and the chip and "Find your level" reflect the new level.
- [ ] A station completion that reports a level change: the "from tomorrow" line under the result and on the day-complete sheet.
- [ ] A short screen with large text on a station that reports a level change: Continue stays reachable (the line sits above the scrolling station list).

Events (`STUDY_EVENTS_ENABLED` on):
- [ ] `tab_opened` on each selection of the tab, `session_started` / `step_started` / `step_finished` / `session_finished` through one pack, `feature_opened` on tile taps, `level_check_started` / `level_check_finished`; on the server `node scripts/studyFunnel.js 1` shows them. Flag off again: no request at all.

## 5. Known limits and open items

1. **Device checks above have not been run.**
2. **Machine-drafted strings.** `tutorConversationFull`, `tutorStartNewConversation` and `studyLevelChanges` in the 18 non-English locales (ar, de, es, fr, hi, id, it, ja, ko, pt, ru, tg, th, tl, tr, vi, zh, zh_TW) are machine-drafted and need a native read.
3. **Open items carried from the task reviews:**
   - After a level check, if the pack refetch fails, the pack row stays hidden until pull-to-refresh.
   - Roleplay's voice path overwrites the input field on failure.
   - `feature_opened` counts a blocked tap (a locked or exhausted tile); such taps carry `detail` `locked` / `exhausted` so they can be separated.
   - A learner whose only weak areas are vocabulary sees no recommended tile (`pickRecommended` considers quiz areas only).
   - The `attempts >= 3` rule of `pickRecommended` is skipped when the server reports no attempts.
   - Tapping the cached row while the pack is slow waits (with a small spinner) and does nothing if the load fails.
   - Only the latest `levelChange` of the day is shown.
   - The cached row shows no topic or "Find your level" (live data only); the XP-level chip ("Lv 3") is not cached.
   - `AchievementUnlockOverlay` is no longer shown from the tab; unlocks only show in the Achievements screen.
   - The tab reporter's wiring inside `LearningMain` is not covered by a test (the reporter itself is).
4. **Phases 2 and 3 of the AI Study path** (the spec) are not part of this build.
5. **The owner's server scripts** (none run yet; see the backend guide): `normalizeVocabularyLanguages.js` (dry run, then `--apply`), `pregeneratePlacementSets.js` (calls the AI provider), `studyContentGaps.js` (read-only, before the nightly trim), `studyFunnel.js` (read-only, once events flow).

## 6. Checks run on this branch

Final check on HEAD (before this handoff's commit):

- `flutter analyze`: 1,119 issues, 0 errors. 3 warnings, the same pre-existing ones in tests this work did not touch: `test/chat/chat_state_edit_failed_test.dart:3:8` (unused import) and `:92:18` (unused element parameter), `test/moments/moments_main_layout_test.dart:4:8` (unused import). The other 1,116 are infos.
- Full `flutter test`: 4,263 passed, 0 failed ("All tests passed!").

## 7. Release steps still to do (owner)

Merge, version bump, release build (the signed build is manual; see the release how-to), store submission, the device checks above, then the server switches in the order of section 2. Not pushed, not built, no version bump.
