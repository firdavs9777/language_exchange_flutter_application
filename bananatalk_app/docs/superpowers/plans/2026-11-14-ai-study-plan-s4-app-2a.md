# AI Study phase 2a (app): my words and mistakes, three doors, Say it — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The study tab gets a My words and mistakes screen fed by the learner's chats, a hub that leads with three doors instead of twelve equal tiles, and a Say it action that opens pronunciation with the learner's own sentence.

**Architecture:** Two app-config booleans gate everything; with both false the tab is exactly what `feat/ai-study-foundations-app` ships. A small injectable API class and one Riverpod provider feed a new screen; the hub chooses between today's layout and the doors layout by flag; the pronunciation screen gains three optional inputs.

**Tech Stack:** Flutter, Riverpod (`FutureProvider`, `ConsumerWidget`), `ApiClient`, ARB localisation (19 files, `flutter gen-l10n`).

**Spec:** `docs/superpowers/specs/2026-11-14-ai-study-doors-recap-check-design.md` (sections 3, 4, 4.1, 7, 8 phase 2a). Server side: backend plan `2026-11-14-ai-study-plan-s3-backend-2a.md`, built on backend branch `feat/ai-study-my-words`.

**Base:** app branch `feat/ai-study-foundations-app` (0a001c06). New branch `feat/ai-study-my-words-app`. All paths below are under `bananatalk_app/`.

## Global Constraints

- Both switches default false: `studyFromChatsEnabled`, `studyDoorsEnabled` (absent means false). With both false no widget, request or string visible to a person changes.
- `package:` imports only. Never run `dart format` on a file you did not create. Stage by path; no `git add -A`; no git stash. No Co-Authored-By or any AI attribution in commits.
- Every commit updates `docs/REMAINING_WORK.md` and lists open items in its body.
- Do not touch `lib/pages/moments/reels/`, `lib/providers/reels_provider.dart`, `lib/services/reel_view_tracker.dart`.
- New strings go in all 19 ARB files (English written here; the other 18 machine-drafted and listed for native review in the handoff). No hard-coded user-visible text (guard tests in `test/l10n/` must pass).
- No release build, version bump or store submission.
- `flutter analyze` stays at 0 errors and no new warnings (baseline 1119 issues, 3 warnings in test files).
- `StudyFeature` slugs are append-only (the server refers to them).

## Server contract (as built)

- `GET /api/v1/app-config` → `studyFromChatsEnabled`, `studyDoorsEnabled`.
- `GET /api/v1/study/my-words` → `200 { success, data: { counts: { candidates, mistakes, dueWords }, candidates: [ { id, text, translation, partOfSpeech?, language, seenCount, lastSeenAt } ], mistakes: [ { id, original, corrected, explanation, source, language, createdAt, successes } ] } }`. At most 20 of each; `counts` are full totals; `explanation` may be `""`; `source` is `partner` or `check`; `successes` is 0–2.
- `POST /study/candidates/:id/keep` → `{ success, data: { vocabularyId } }`. `POST /study/candidates/:id/dismiss` → `{ success: true }`. `POST /study/mistakes/:id/got-it` → `{ success, data: { successes, resolved } }`.
- All four answer `404 { success: false, error: 'Not found' }` while capture is off, and for a row that is gone.
- `POST /api/v1/speech/pronunciation/evaluate` accepts multipart field `source: 'own'`.

## Review Focus

1. The server answers 404 because the switch went off between app-config and the request → the screen and the hub card show the empty state, never an error page.
2. Keep, Dismiss or Got it fails (offline) → the row comes back and one message is shown; a double tap sends one request.
3. A candidate or mistake in a right-to-left or very long script → rows wrap; nothing overflows at the smallest supported width and at text scale 1.3.
4. Say it with a sentence in a language the pronunciation screen's picker does not list → the screen opens with the sentence and its own default language, and scoring still sends `source: 'own'`.
5. Doors on and the learner has no persona → the Talk door opens the persona picker first and then the tutor, exactly as the tutor tile does today.

---

### Task 1: Flags, API, models, provider, strings

**Files:**
- Modify: `lib/models/app_config.dart`, `lib/providers/provider_root/app_config_providers.dart`, `lib/services/session_reset.dart`, `lib/service/endpoints.dart`, all 19 `lib/l10n/app_*.arb`
- Create: `lib/models/study/my_words.dart`, `lib/services/study/my_words_api.dart`, `lib/providers/provider_root/learning/my_words_providers.dart`
- Test: `test/study/my_words_api_test.dart`, `test/study/my_words_flags_test.dart`

**Interfaces — Produces:**

```dart
// app_config.dart
final bool studyFromChatsEnabled; final bool studyDoorsEnabled;   // json[...] == true
// app_config_providers.dart
final studyFromChatsEnabledProvider = Provider<bool>(...);
final studyDoorsEnabledProvider = Provider<bool>(...);

// my_words.dart
class WordCandidate { final String id, text, translation, language; final String? partOfSpeech; final int seenCount; }
class StudyMistakeItem { final String id, original, corrected, explanation, source, language; final int successes; }
class MyWords { final int candidateCount, mistakeCount, dueWords; final List<WordCandidate> candidates; final List<StudyMistakeItem> mistakes;
  static const empty; factory MyWords.fromJson(Map<String, dynamic> data); }

// my_words_api.dart — same shape as lib/services/study/study_events_api.dart (injectable ApiClient)
class MyWordsApi {
  Future<MyWords> fetch();                       // 404 → MyWords.empty; other failures throw
  Future<String?> keep(String candidateId);      // returns vocabularyId; throws on failure
  Future<void> dismiss(String candidateId);
  Future<({int successes, bool resolved})> gotIt(String mistakeId);
}
final myWordsApiProvider = Provider<MyWordsApi>(...);

// my_words_providers.dart
final myWordsProvider = FutureProvider.autoDispose<MyWords>(...); // MyWords.empty without a request when studyFromChatsEnabled is false
```

`fromJson` never throws on a missing or wrongly typed field: a row without `id` or `text`/`original` is dropped; numbers default to 0; strings to `''`.

Strings (key → English; the plural ones use ICU plurals):

| key | English |
|---|---|
| `myWordsTitle` | My words and mistakes |
| `myWordsCountWords` | `{count, plural, =1{1 word} other{{count} words}}` |
| `myWordsCountMistakes` | `{count, plural, =1{1 mistake} other{{count} mistakes}}` |
| `myWordsCardBoth` | {words}, {mistakes} to look at (the two placeholders are the strings above) |
| `myWordsCardOne` | {items} to look at (one of the strings above) |
| `myWordsCardEmpty` | Words you look up in chats will appear here |
| `myWordsFromChats` | From your chats |
| `myWordsMistakes` | Mistakes |
| `myWordsToReview` | Words to review |
| `myWordsDueCount` | `{count, plural, =1{1 word is ready} other{{count} words are ready}}` |
| `myWordsKeep` | Keep |
| `myWordsDismiss` | Dismiss |
| `myWordsGotIt` | Got it |
| `myWordsGotItProgress` | {done} of 3 |
| `myWordsSayIt` | Say it |
| `myWordsReview` | Review |
| `myWordsEmpty` | Nothing waiting. Look up a word in a chat and it will show up here. |
| `myWordsActionFailed` | That didn't save. Try again. |
| `myWordsYouWrote` | You wrote |
| `myWordsCorrection` | Correction |
| `studyDoorTalk` | Talk |
| `studyDoorTalkSubtitle` | Practise speaking with your tutor |
| `studyDoorRoleplay` | Roleplay |
| `studyDoorMore` | More ways to study |

- [ ] **Step 1: Write the failing tests** (`http.runWithClient` + `MockClient`, as `test/study/tutor_quota_reason_test.dart` does):

```dart
test('both flags parse from app-config and default to false', ...);
test('fetch parses counts, candidates and mistakes', ...);          // the contract body above, verbatim
test('fetch returns empty on 404 and throws on 500', ...);
test('a row with no id or no text is dropped; a missing number is 0', ...);
test('keep posts to /study/candidates/<id>/keep and returns the vocabulary id', ...);
test('gotIt returns successes and resolved', ...);
test('myWordsProvider makes no request when studyFromChatsEnabled is false', ...);
```

- [ ] **Step 2: Run** `flutter test test/study/my_words_api_test.dart test/study/my_words_flags_test.dart`. Expected: FAIL (types missing).
- [ ] **Step 3: Implement**; add the two derived providers to the list in `lib/services/session_reset.dart`; add the strings to all 19 ARBs; `flutter gen-l10n`.
- [ ] **Step 4: Run** the two files plus `flutter test test/l10n/`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): my-words flags, API and strings (off by default)`.

---

### Task 2: Say it — pronunciation takes the learner's own sentence

**Files:**
- Modify: `lib/pages/ai/pronunciation/pronunciation_screen.dart`
- Test: `test/study/pronunciation_own_sentence_test.dart`

**Interfaces — Produces:** `const PronunciationScreen({super.key, this.initialText, this.initialLanguage, this.ownSentence = false})`. `AIService.evaluatePronunciation` already takes `source`; the screen passes `source: 'own'` when `ownSentence` is true and the text field still equals `initialText` trimmed, otherwise today's default.

Rules: with no arguments the screen is byte-for-byte today's behaviour. `initialText` replaces the first sample in the text field. `initialLanguage` selects that language only when the screen's own language list contains it (match on the base code before `-`); otherwise the screen's default stands.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('with no arguments the first sample sentence is shown', ...);
testWidgets('initialText is shown in the field', ...);
testWidgets('an unknown initialLanguage keeps the default language', ...);
test('source is own only while the text is still the given sentence', ...); // pure helper: pronunciationSource(initialText, currentText, ownSentence)
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** (`String pronunciationSource({String? initialText, required String currentText, required bool ownSentence})` as a top-level function in the screen's file).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): pronunciation can open with the learner's own sentence`.

---

### Task 3: My words and mistakes screen

**Files:**
- Create: `lib/pages/learning/my_words/my_words_screen.dart`, `lib/pages/learning/my_words/widgets/candidate_row.dart`, `lib/pages/learning/my_words/widgets/mistake_row.dart`
- Test: `test/study/my_words_screen_test.dart`

**Interfaces — Consumes:** `myWordsProvider`, `myWordsApiProvider`, `vocabularyStatsProvider(null)` (`dueToday`), `PronunciationScreen(initialText:, initialLanguage:, ownSentence: true)`, `VocabularyReviewScreen()`, `studyLog`. **Produces:** `const MyWordsScreen({super.key})`.

Rules:

- Three sections in this order, each hidden when empty: From your chats (candidates), Mistakes, Words to review (shown when `dueToday > 0`: the count line and a Review button opening `VocabularyReviewScreen`). All empty → `myWordsEmpty`. Loading → the app's usual progress indicator; a thrown error → the app's usual retry state.
- Candidate row: text, translation, part of speech when present; Keep, Dismiss, Say it (says `text`).
- Mistake row: "You wrote" + original, "Correction" + corrected, the explanation when not empty; Got it with `myWordsGotItProgress` when `successes > 0`; Say it (says `corrected`).
- Keep, Dismiss, Got it: the row is removed (or its progress updated) at once; while the request runs the row's buttons ignore taps; on failure the row is restored and `myWordsActionFailed` is shown once. Got it removes the row only when the server says `resolved`. After a successful Keep, `vocabularyStatsProvider` is invalidated.
- Pull to refresh re-fetches. Text wraps; no fixed heights around learner text.
- Events (existing names only): opening the screen logs `StudyEvent.featureOpened` with `kind: 'my_words'`; Say it logs `featureOpened` with `kind: 'say_it'`. Keep, Dismiss and Got it are not logged by the app (the server has them).

- [ ] **Step 1: Write the failing tests** (provider overrides with a fake `MyWordsApi`):

```dart
testWidgets('sections with nothing in them are hidden; all empty shows the empty line', ...);
testWidgets('keep removes the row and calls the api once on a double tap', ...);
testWidgets('a failed dismiss restores the row and shows the failure message', ...);
testWidgets('got it shows 1 of 3 and keeps the row until the server says resolved', ...);
testWidgets('say it on a mistake opens pronunciation with the corrected sentence', ...);
testWidgets('a long right-to-left sentence does not overflow at 320 wide, text scale 1.3', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): my words and mistakes screen`.

---

### Task 4: Three doors on the hub, and the More screen

**Files:**
- Modify: `lib/pages/learning/main/study_hub.dart`, `lib/pages/learning/main/sections/study_feature_groups.dart`
- Create: `lib/pages/learning/main/sections/study_doors.dart`, `lib/pages/learning/main/study_more_screen.dart`
- Test: `test/study/study_doors_test.dart`

**Interfaces — Consumes:** `studyDoorsEnabledProvider`, `myWordsProvider`, `vocabularyStatsProvider(null)`, `MyWordsScreen`, the existing `_open()` logic for a feature (persona picker first). **Produces:** `StudyFeatureGroups({..., Set<StudyFeature> exclude = const {}})`; `MyWordsDoorCard`, `TalkDoorCard`, `MoreDoorRow` in `study_doors.dart`; `const StudyMoreScreen({super.key})`.

Rules, with `studyDoorsEnabled` true (false → `study_hub.dart` builds exactly today's column; assert it in a test):

- Column order: first-week guide, announcements, Today row (or its snapshot) — all unchanged — then `MyWordsDoorCard`, `TalkDoorCard`, `MoreDoorRow`, `ProgressCard`, the ad. `VocabPacksCard`, `RecommendedTile` and `StudyFeatureGroups` are not on the hub.
- `MyWordsDoorCard`: the words number is `candidateCount` and the mistakes number is `mistakeCount` (`dueWords` is not added to either); one of them zero → the words-only or mistakes-only line; both zero → `myWordsCardEmpty`. While loading or on error it shows the title with no count line. Opens `MyWordsScreen`. Not part of `StudyHubCache`.
- `TalkDoorCard`: tap opens the tutor through the same path as the tutor tile (persona picker first when none is set — extract the existing `_open` body in `study_feature_groups.dart` into a top-level `openStudyFeature(context, ref, feature)` and use it from both). A text button `studyDoorRoleplay` opens roleplay through the same function. Keeps the tutor tile's existing badge (conversations left).
- `MoreDoorRow` opens `StudyMoreScreen`: `RecommendedTile`, `VocabPacksCard`, then `StudyFeatureGroups(exclude: {StudyFeature.tutor, StudyFeature.roleplay})`. A group left with no features is not drawn.
- The first-week guide's secondary action (`_scrollToGroups` today) opens `StudyMoreScreen` when doors are on.
- Pull to refresh also invalidates `myWordsProvider`.
- Events: Talk logs `featureOpened` with the tutor's slug as today (through the shared function); More logs `featureOpened` `kind: 'more'`.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('doors off: the hub column has today\'s widgets in today\'s order and no door', ...);
testWidgets('doors on: Today, My words, Talk, More, Progress in that order; no feature grid', ...);
testWidgets('the my-words card shows "2 words, 1 mistake to look at" and the empty line at zero', ...);
testWidgets('Talk with no persona opens the persona picker', ...);
testWidgets('More lists every feature except tutor and roleplay', ...);
testWidgets('StudyFeatureGroups with no exclude draws what it draws today', ...);
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** this file plus every existing test under `test/study/` and `test/learning/` that builds the hub. Expected: PASS.
- [ ] **Step 5: Commit** `feat(study): three doors on the study hub (studyDoorsEnabled, off)`.

---

### Task 5: Whole-suite check and handoff

**Files:**
- Create: `docs/releases/ai-study-my-words-app-handoff.md`
- Modify: `docs/REMAINING_WORK.md`

Handoff contents: what a person sees with each switch on; the order to switch (server capture first, doors only once a build with this branch is out); what was not device-tested; the 18 machine-drafted languages needing native review, with the string keys; calls made in this plan (below); open items.

- [ ] **Step 1: Run** `flutter analyze` (0 errors, no new warnings) and the full `flutter test`. Expected: PASS; record the totals.
- [ ] **Step 2: Write** the handoff and update `docs/REMAINING_WORK.md`.
- [ ] **Step 3: Commit** `docs(study): my words app handoff`.

---

## Calls made in this plan (not the owner's decisions)

- Roleplay is a text button on the Talk card rather than a choice inside the tutor screen; the tutor screen is not changed.
- The Review button opens the existing review screen as it is; "chat words first" needs a server ordering and is left for phase 2c.
- Using the learner's own sentence in the daily session's speaking step belongs with Today v2 (phase 2c), not here.
- The Recommended tile and Vocab packs card move to the More screen when doors are on.
- The explanation on a partner's correction is shown to everyone; the paid explanation in the design applies to the check (phase 2b).
- The free limit of 5 keeps a day is not enforced (phase 3).
