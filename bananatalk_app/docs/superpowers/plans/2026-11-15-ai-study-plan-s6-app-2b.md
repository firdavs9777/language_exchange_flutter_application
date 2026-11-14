# AI Study phase 2b app (Plan S6): check before you send, after-chat recap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Check control and sheet to the one-to-one chat composer, and the after-chat recap (hub card, My words card, a line on leaving a chat), each behind its own server flag, with nothing changed while the flags are off.

**Architecture:** A self-contained `StudyCheckButton` is handed to the shared composer through one new optional slot, so rooms and the flag-off chat build exactly today's row. The check and recap talk to the server through two small API classes that turn every failure into a value (never a throw into the UI). Recaps load through one provider that the hub, My words and the leave-chat hook share.

**Tech Stack:** Flutter, Riverpod, existing `ApiClient`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-11-14-ai-study-doors-recap-check-design.md` sections 5, 6, 7, 8 (branch `docs/ai-study-spec`). Server contract: backend repo `docs/rollout/ai-study-check-recap.md`, section "Server contract" (read-only at `/Users/davis/Desktop/Personal/be-integration/docs/rollout/ai-study-check-recap.md`).

## Global Constraints

- Flags `studyCheckEnabled`, `studyRecapEnabled` (app-config keys, default false). With both false, every screen builds the same widget tree as before this plan; a test in each UI task proves it for the surface it touches.
- The Check control never appears in rooms or group chats. `room_screen.dart` is not edited.
- The check never blocks sending: no await on the send path, the send button is never disabled by a check.
- Only the learner's own typed text is sent to `POST /study/check`. No partner text is sent anywhere by this plan.
- Until phase 3 there is nothing to buy: a used-up allowance says "more tomorrow" when the server's `upgradeAvailable` is false; the recap's `locked` flag is parsed but not shown (the locked line arrives with phase 3).
- API classes never throw to callers; they return values. 429 from these endpoints must not raise the global rate-limit toast (`suppressRateLimitToast: true` on posts).
- Tests never reach the network.
- Dart: `package:` imports only. Never run `dart format` on a file this branch did not create. Stage by path; no `git add -A`; no git stash.
- Do not touch `lib/pages/moments/reels/`, `lib/providers/reels_provider.dart`, `lib/services/reel_view_tracker.dart`.
- No Co-Authored-By or any AI attribution in commits. Every commit updates `docs/REMAINING_WORK.md` and lists open items in the commit body.
- No version bump, no release build.
- `flutter analyze` must stay at the baseline: 1119 issues, 0 errors.
- New strings exist in all 19 ARB files; every new key is quoted in a `test/l10n` test.

## Review Focus

1. The learner edits or sends the message while a check is in flight: the sheet's choice must not overwrite newer composer text silently. Expected: the sheet is modal so text cannot change under it; if the controller text differs from the checked text when a choice is tapped, the choice still applies (it is what the learner asked for) — but a check result arriving after the sheet was closed is dropped and changes nothing.
2. The chat screen is disposed before the leave-chat build returns: no `ref`/`context` use after dispose; the line still shows (or is silently dropped), never a crash.
3. App-config arrives late or fails: the Check control and recap cards stay absent; nothing is requested.
4. Server off or old (404), 503, timeout, malformed body, `rate_limited` 429: the check sheet says "not available"; recaps are an empty list; nothing throws.
5. Native language unknown, blank, or a variant name ("Portuguese (Brazil)", "한국어"): the guess treats unknown as "not native" (control appears) and variants as their base language.

---

### Task 1: Flags, event names, placement, strings

**Files:**
- Modify: `lib/models/app_config.dart`, `lib/providers/provider_root/app_config_providers.dart`, `lib/services/session_reset.dart`, `lib/services/study/study_tracker.dart`, `lib/services/paywall/paywall_flow.dart`, all 19 `lib/l10n/app_*.arb`
- Test: `test/study/check_recap_flags_test.dart`, `test/l10n/study_check_recap_strings_test.dart`

**Interfaces — Produces:**
- `AppConfig.studyCheckEnabled`, `AppConfig.studyRecapEnabled` (bool, `json[key] == true`); `studyCheckEnabledProvider`, `studyRecapEnabledProvider` (`Provider<bool>`, same shape as `studyDoorsEnabledProvider`); both names added to the flag list in `session_reset.dart` next to `studyDoorsEnabled`.
- `StudyEvent.checkUsed = 'check_used'`, `checkApplied = 'check_applied'`, `recapShown = 'recap_shown'`, `recapOpened = 'recap_opened'`.
- `PaywallPlacement.studyCheck = 'study_check'` (added to whatever list of known placements the class keeps).
- ARB keys (English text; other 18 languages machine-drafted in the same commit):

| Key | English |
|---|---|
| `studyCheckTooltip` | Check my message |
| `studyCheckTitle` | Check before you send |
| `studyCheckChecking` | Checking… |
| `studyCheckYouWrote` | You wrote |
| `studyCheckCorrected` | Corrected |
| `studyCheckNatural` | More natural |
| `studyCheckUseCorrected` | Use corrected |
| `studyCheckUseNatural` | Use natural |
| `studyCheckKeepMine` | Keep mine |
| `studyCheckFine` | Looks good. Nothing to fix. |
| `studyCheckUnavailable` | The check isn't available right now. You can still send your message. |
| `studyCheckLimit` | You've used today's checks. More tomorrow. |
| `studyCheckRemaining` | `{count, plural, =1{1 check left today} other{{count} checks left today}}` |
| `studyRecapTitle` | From your chat with {name} |
| `studyRecapSaved` | `{count, plural, =1{1 thing saved from this chat} other{{count} things saved from this chat}}` |
| `studyRecapReview` | Review |

- [ ] **Step 1:** Write `test/study/check_recap_flags_test.dart`: `AppConfig.fromJson({})` gives both false; `{'studyCheckEnabled': true, 'studyRecapEnabled': true}` gives both true; `'true'` (a string) gives false; each provider is false while `appConfigProvider` is loading or errored; the four `StudyEvent` values and `PaywallPlacement.studyCheck` equal the strings above. Follow `test/study/my_words_flags_test.dart`.
- [ ] **Step 2:** Run it; expect compile failure.
- [ ] **Step 3:** Implement flags, providers, session-reset entries, constants.
- [ ] **Step 4:** Add the 16 keys to all 19 ARBs (plural forms valid for each locale; placeholders `count` int, `name` String declared in `app_en.arb` metadata). Run `flutter gen-l10n`.
- [ ] **Step 5:** Write `test/l10n/study_check_recap_strings_test.dart` quoting all 16 keys, following the existing newest test in `test/l10n/` (every key present and non-empty in every ARB; placeholders preserved).
- [ ] **Step 6:** Run `flutter test test/study/check_recap_flags_test.dart test/l10n` — all pass. `flutter analyze` at baseline.
- [ ] **Step 7:** Commit (`feat(study): flags, events and strings for check and recap`), updating `docs/REMAINING_WORK.md` with a "Plan S6" section listing: native review of 16 strings in 18 languages.

### Task 2: Language guess, check and recap APIs, models, providers

**Files:**
- Create: `lib/utils/language_guess.dart`, `lib/models/study/study_check.dart`, `lib/models/study/study_recap.dart` (put models beside the existing `MyWords` model if it lives elsewhere), `lib/services/study/study_check_api.dart`, `lib/services/study/study_recap_api.dart`, `lib/providers/provider_root/learning/study_check_recap_providers.dart`
- Modify: `lib/services/session_reset.dart` (user-scoped providers), the endpoints file that holds `Endpoints.myWordsURL`
- Test: `test/utils/language_guess_test.dart`, `test/study/study_check_api_test.dart`, `test/study/study_recap_api_test.dart`, `test/study/study_recap_provider_test.dart`

**Interfaces — Consumes:** Task 1 flags; existing `WordCandidate.fromJson`, `StudyMistakeItem.fromJson`, `ApiClient`, `studyFromChatsEnabledProvider`.

**Interfaces — Produces:**

```dart
// lib/utils/language_guess.dart
/// True when text is probably NOT in nativeLanguage; true when unsure;
/// false when the text has no letters.
bool notNativeLanguage(String text, String? nativeLanguage);
/// The server's draft-size rule: 3+ words, or 4+ characters when the text
/// contains Han, Kana, Thai, Lao, Khmer or Myanmar; at most 500 characters.
bool isCheckableDraft(String text);
/// Both rules together: what decides whether the Check control shows.
bool shouldOfferCheck(String text, String? nativeLanguage);

// lib/models/study/study_check.dart
class CheckMistake { final String original; final String fix; final String? explanation; }
class CheckAllowance { final int? remaining; final int? limit; final DateTime? resetAt;
  bool get exhausted; /* remaining == 0 && resetAt is in the future */ }
sealed class CheckOutcome {}
class CheckResult extends CheckOutcome { final bool fine; final String corrected; final String? natural;
  final List<CheckMistake> mistakes; final CheckAllowance allowance; }
class CheckLimitReached extends CheckOutcome { final DateTime? resetAt; final bool upgradeAvailable; }
class CheckUnavailable extends CheckOutcome {}

// lib/services/study/study_check_api.dart
class StudyCheckApi { StudyCheckApi([ApiClient? client]);
  Future<CheckOutcome> check(String text); }
final studyCheckApiProvider = Provider<StudyCheckApi>(...);

// lib/models/study/study_recap.dart
class StudyRecap { final String id; final String partnerId; final String partnerName;
  final DateTime? createdAt; final List<WordCandidate> words; final StudyMistakeItem? mistake;
  final bool locked; int get itemCount; /* words.length + (mistake == null ? 0 : 1) */
  static StudyRecap? fromJson(Object? json); /* null when id is missing */ }

// lib/services/study/study_recap_api.dart
class StudyRecapApi { StudyRecapApi([ApiClient? client]);
  Future<List<StudyRecap>> fetch();
  Future<({int created, List<StudyRecap> recaps})> build({String? partnerId}); }
final studyRecapApiProvider = Provider<StudyRecapApi>(...);

// providers
final studyCheckAllowanceProvider = StateProvider<CheckAllowance?>((_) => null);
final studyRecapsProvider = FutureProvider.autoDispose<List<StudyRecap>>(...);
```

Rules the signatures do not determine:
- `language_guess.dart` is a port of the server's `lib/languageGuess.js` (read-only at `/Users/davis/Desktop/Personal/be-integration/lib/languageGuess.js`): same script table, same stop-word lists, same ru/uk and zh/kana rules, same thresholds. Dart: `RegExp(r'\p{Script=Han}', unicode: true)`. The native language arrives as a display name; map it to a base code with a private table covering every language in the server's `SCRIPTS` and `STOP_WORDS` (English names, plus the local names in the server's `lib/studyLanguage.js` `LOCAL_NAMES`), after `LanguageCodes.stripVariant` and lower-casing; a code-shaped value (`ko`, `pt-BR`) uses its part before the hyphen. Unknown, null or blank → return true. `isCheckableDraft` mirrors `controllers/studyCheck.js` (trimmed text; words split on whitespace).
- `StudyCheckApi.check`: `post` with `suppressRateLimitToast: true`, wrapped in `.timeout(const Duration(seconds: 9))` and a catch-all. Mapping: 200 with a `data` map containing a `corrected` string → `CheckResult`; `res.quotaError != null` → `CheckLimitReached` from it; everything else (404, 400, 503, other 429, timeout, exception, malformed) → `CheckUnavailable`.
- `StudyRecapApi.fetch`: `get(..., deduplicate: false)`; anything but a 200 with `data.recaps` as a list → `[]`; rows that fail to parse are skipped. `build`: same, `created` defaults to 0; body is `{partnerId}` only when non-null.
- `studyRecapsProvider`: returns `[]` without any request unless `studyRecapEnabledProvider` and `studyFromChatsEnabledProvider` are both true; otherwise `fetch()` with a 12 s timeout that yields `[]`. It never completes with an error.
- `studyCheckAllowanceProvider`, `studyRecapsProvider`, both API providers are registered as user-scoped in `session_reset.dart` the way `myWordsProvider`/`myWordsApiProvider` are.

- [ ] **Step 1:** Write `test/utils/language_guess_test.dart`. Port every case in the server's `test/languageGuess.test.js` (`/Users/davis/Desktop/Personal/be-integration/test/languageGuess.test.js`) with the same inputs and expected values, then add: native given as `'Korean'`, `'한국어'`, `'Portuguese (Brazil)'`, `'ko-KR'`; null/blank/unknown name → true; `isCheckableDraft('a b')` false, `'a b c'` true, `'你好吗'` false, `'你好吗？我'` true (4 characters after trim counts all characters as the server does — check the server function and match it exactly), 501 characters false, `'   '` false; `shouldOfferCheck('hello my friend', 'Korean')` true, `shouldOfferCheck('안녕하세요 저는 학생입니다', 'Korean')` false.
- [ ] **Step 2:** Write `test/study/study_check_api_test.dart` with a fake `ApiClient` (follow `test/study/my_words_api_test.dart`): the 200 example from the contract parses (remaining 2, limit 3, natural kept, explanation null); `natural: null`; VIP shape (`remaining: null`, explanation text); `fix: ''` kept; a quota 429 → `CheckLimitReached(upgradeAvailable: false)`; a `rate_limited` 429, 404, 503, 400, thrown exception, `data` missing, `corrected` not a string → `CheckUnavailable`; the post is made with `suppressRateLimitToast: true` and body `{'text': ...}`.
- [ ] **Step 3:** Write `test/study/study_recap_api_test.dart`: the contract's Recap example parses (partner name, 1 word, mistake, `locked`, `itemCount == 2`); `mistake: null`; a row without `id` is skipped; 404/429/exception → `[]`; `build(partnerId: 'p1')` sends `{'partnerId': 'p1'}`, `build()` sends no partnerId, `created` read, failure → `(created: 0, recaps: [])`.
- [ ] **Step 4:** Write `test/study/study_recap_provider_test.dart`: with either flag false the fake API's `fetch` is never called and the value is `[]`; both true → the fetched list; a fetch that throws → `[]`.
- [ ] **Step 5:** Run the four files; expect failures. Implement. Run again; all pass. `flutter analyze` at baseline.
- [ ] **Step 6:** Commit (`feat(study): check and recap data layer, on-device language guess`), `docs/REMAINING_WORK.md` updated.

### Task 3: Check control and sheet in the one-to-one chat

**Files:**
- Create: `lib/pages/chat/input/study_check_button.dart`, `lib/pages/chat/dialogs/study_check_sheet.dart`
- Modify: `lib/pages/chat/input/chat_input_bar.dart` (compose row only), `lib/pages/chat/input/chat_input_section.dart`, `lib/pages/chat/conversation/conversation_input_area.dart`, `lib/pages/chat/conversation/chat_conversation_screen.dart` (the one call site of `ConversationInputArea`)
- Test: `test/chat/study_check_button_test.dart`, `test/chat/study_check_sheet_test.dart`, `test/chat/chat_input_bar_send_leading_test.dart`

**Interfaces — Consumes:** Task 1 and 2 (`shouldOfferCheck`, `StudyCheckApi`, `CheckOutcome`, `studyCheckAllowanceProvider`, `studyCheckEnabledProvider`, strings, `StudyEvent.checkUsed/checkApplied`, `PaywallPlacement.studyCheck`); `userProvider` (`Community.native_language`, `language_to_learn`); `PronunciationScreen({initialText, initialLanguage, ownSentence})`; `studyLog`.

**Interfaces — Produces:**
```dart
// chat_input_bar.dart / chat_input_section.dart / conversation_input_area.dart
final Widget? sendLeading; // new optional constructor parameter, default null

// study_check_button.dart
class StudyCheckButton extends ConsumerStatefulWidget {
  const StudyCheckButton({super.key, required this.controller});
  final TextEditingController controller; }

// study_check_sheet.dart
/// Returns the text to put in the composer, or null to change nothing.
Future<String?> showStudyCheckSheet(BuildContext context,
    {required String text, required Future<CheckOutcome> outcome, String? learningLanguage});
```

Behaviour:
- `ChatInputBar`: in the compose row, `if (widget.sendLeading != null) ...[widget.sendLeading!, const SizedBox(width: 4)]` immediately before the send button. Nothing else in the file changes. `ChatInputSection` and `ConversationInputArea` pass it through. `ChatScreen` passes `ref.watch(studyCheckEnabledProvider) ? StudyCheckButton(controller: _messageController) : null`.
- `StudyCheckButton` listens to the controller and builds `SizedBox.shrink()` unless `shouldOfferCheck(text, me.native_language)` (while `userProvider` has no value: not shown). Otherwise a 36×36 `IconButton` (`Icons.spellcheck`, tooltip `studyCheckTooltip`, key `Key('study-check-button')`), styled like the tool-row icon buttons in `chat_input_bar.dart`.
- Tap: if `studyCheckAllowanceProvider` is known `exhausted`, open the sheet with an already-completed `CheckLimitReached(upgradeAvailable: false)` and make no request. Otherwise call `check(text)` once and open the sheet with that future. Taps while a sheet is open are ignored.
- After the outcome: `CheckResult` → store its allowance in `studyCheckAllowanceProvider` and `studyLog(StudyEvent.checkUsed, kind: fine ? 'fine' : 'mistakes')`; `CheckLimitReached` → store an exhausted allowance (`remaining: 0`, its `resetAt`). If the widget is unmounted by then, the provider write is skipped.
- When the sheet returns a non-null string: set the controller's text to it with the caret at the end; `studyLog(StudyEvent.checkApplied, kind: 'corrected' | 'natural')`. The message is not sent.
- Sheet (`showModalBottomSheet`, `showDragHandle: true`, `isScrollControlled: true`, layout and theming as `lib/pages/chat/dialogs/translate_unlock_sheet.dart`):
  - while waiting: title + `studyCheckChecking` with a progress indicator;
  - `CheckResult` with `fine`: `studyCheckFine` only, and the remaining line; no replace buttons;
  - `CheckResult` otherwise: "You wrote" + text; "Corrected" + corrected; "More natural" + natural when non-null; each mistake as `original → fix` (a `fix` of `''` shows the original struck through) with its explanation underneath when non-null; `studyCheckRemaining(count)` when `allowance.remaining != null`; buttons `Use corrected` (key `study-check-use-corrected`, pops `corrected`), `Use natural` (only when natural non-null, pops it), `Keep mine` (pops null). Beside the corrected and the natural text, a small Say it icon button (reuse the Say it icon/label used on the My words screen) that pushes `PronunciationScreen(initialText: thatText, initialLanguage: learningLanguage, ownSentence: true)` without closing the sheet;
  - `CheckLimitReached`: when `upgradeAvailable` is false, `studyCheckLimit` and a close button. When true, pop the sheet and open the VIP plans with `PaywallFlow.start(PaywallPlacement.studyCheck)` through `openVipPlans` (the way `translate_unlock_sheet.dart`'s caller does);
  - `CheckUnavailable`: `studyCheckUnavailable` and a close button.
  - Dismissing (drag, barrier, back) pops null.

- [ ] **Step 1:** Write `test/chat/chat_input_bar_send_leading_test.dart` using the harness in `test/rooms/room_rich_messages_test.dart`: with `sendLeading` null the compose row's children are exactly `[Expanded, SizedBox, <send button>]` (3 children); with `sendLeading: Text('L')` the widget is shown immediately before the send button.
- [ ] **Step 2:** Write `test/chat/study_check_button_test.dart` (ProviderScope overrides: `userProvider` with native `Korean`, learning `English`; a fake `StudyCheckApi`; `studyLogSpy`):
  - empty text, two words, Korean text, 501 characters → no `study-check-button`; `'I goed to school'` → shown; clearing the text hides it again;
  - `userProvider` still loading → not shown;
  - tap → fake `check` called once with the exact text; sheet shows corrected text; tapping `study-check-use-corrected` sets `controller.text` to the corrected text with the caret at the end, logs `check_used` then `check_applied` with kind `corrected`; nothing was sent;
  - `Keep mine` and barrier dismissal leave the text unchanged and log no `check_applied`;
  - result with `remaining: 0` → a second tap opens the limit text and `check` was still called only once;
  - `CheckLimitReached` from the server → `studyCheckLimit` text shown, no paywall route pushed;
  - a `check` future that completes after the sheet was dismissed changes nothing and does not throw; same when the button was removed from the tree first;
  - double tap opens one sheet and makes one request.
- [ ] **Step 3:** Write `test/chat/study_check_sheet_test.dart`: fine result shows only `studyCheckFine` and no `Use corrected`; natural null hides `Use natural`; a mistake with explanation shows it, with null explanation shows none; `fix: ''` renders; `remaining: null` shows no remaining line; `CheckUnavailable` shows `studyCheckUnavailable`; a long corrected text (500 characters) in a 320×480 surface does not overflow; the Say it button pushes a `PronunciationScreen` with `ownSentence: true` and the corrected text.
- [ ] **Step 4:** Run; expect failures. Implement. Run the three files plus `flutter test test/rooms test/chat` — all pass. `flutter analyze` at baseline.
- [ ] **Step 5:** Commit (`feat(chat): check before you send, behind studyCheckEnabled`), `docs/REMAINING_WORK.md` updated (add: no widget test pumps the whole `ChatScreen`; the wiring line there is verified by analysis and the device pass).

### Task 4: Recap cards, the leave-chat line, handoff

**Files:**
- Create: `lib/pages/learning/main/sections/study_recap_card.dart`, `lib/services/study/study_recap_leave.dart`, `docs/releases/ai-study-check-recap-app-handoff.md`
- Modify: `lib/pages/learning/main/study_hub.dart` (doors branch only), `lib/pages/learning/my_words/my_words_screen.dart`, `lib/pages/chat/conversation/chat_conversation_screen.dart` (`initState`/`dispose` and the place a message is sent), `docs/REMAINING_WORK.md`
- Test: `test/study/study_recap_card_test.dart`, `test/study/my_words_recap_test.dart`, `test/study/study_recap_leave_test.dart`

**Interfaces — Consumes:** `studyRecapsProvider`, `StudyRecapApi`, `StudyRecap`, flags, strings, `StudyEvent.recapShown/recapOpened`, `MyWordsScreen`, `myWordsProvider`.

**Interfaces — Produces:**
```dart
// study_recap_card.dart — the hub's compact card
class StudyRecapHubCard extends ConsumerWidget { const StudyRecapHubCard({super.key}); }

// study_recap_leave.dart
class StudyRecapLeave {
  StudyRecapLeave({required this.api, required this.enabled, required this.messenger,
      required this.navigator, required this.l10n, required this.onChanged});
  final StudyRecapApi api; final bool enabled;
  final ScaffoldMessengerState? messenger; final NavigatorState? navigator;
  final AppLocalizations l10n; final void Function() onChanged;
  /// Fire and forget. Never throws.
  void leftChat({required String partnerId, required int sentThisVisit});
}
```

Behaviour:
- **Hub.** In the doors branch only, directly above `MyWordsDoorCard`: `if (ref.watch(studyRecapEnabledProvider)) const StudyRecapHubCard()` followed by the usual gap only when the card shows something. `StudyRecapHubCard` watches `studyRecapsProvider`; while loading, on an empty list, it is `SizedBox.shrink()` (the hub never waits for it). With recaps it shows the newest one: title `studyRecapTitle(partnerName)`, subtitle `studyRecapSaved(itemCount)`, styled like `MyWordsDoorCard`; tap pushes `MyWordsScreen` and logs `recap_opened`. When first shown for a recap id it logs `recap_shown` (once per id per app run; keep the seen ids in a top-level set with a `@visibleForTesting` reset). A recap with `itemCount == 0` is not shown. The hub's pull-to-refresh also invalidates `studyRecapsProvider`.
- **My words.** When `studyRecapEnabledProvider` is on and `studyRecapsProvider` has recaps, the list's first children are one block per recap (newest first, `itemCount > 0` only): a header `studyRecapTitle(partnerName)`, then that recap's word rows and mistake row, built with the screen's existing row widgets and handlers (Keep, Dismiss, Say it; Got it, Say it). An id shown inside a recap block is left out of the "From your chats" and "Mistakes" sections below, so nothing is listed twice. The screen's existing empty text must not show while a recap block is shown. After any keep, dismiss or got-it, and on pull-to-refresh, invalidate `studyRecapsProvider` as well as `myWordsProvider`. Logs `recap_shown` through the same once-per-id helper. With the flag off the screen builds exactly as today and never reads `studyRecapsProvider`.
- **Leaving a chat.** `_ChatScreenState` counts messages the learner sent in this visit (increment where a send succeeds or is queued; one field). In `initState`/`didChangeDependencies` it caches what `dispose` needs (the API from `studyRecapApiProvider`, both flags, `ScaffoldMessenger.maybeOf(context)`, the root `Navigator`, `AppLocalizations`, and a closure that invalidates `studyRecapsProvider` and `myWordsProvider` through the cached `ProviderContainer`), following how `_chatPartnersNotifier` is cached. `dispose()` calls `leftChat(partnerId: widget.userId, sentThisVisit: n)` and nothing else new.
- `leftChat` does nothing unless `enabled` and `sentThisVisit >= 1`. Otherwise it calls `api.build(partnerId: partnerId)`; when `created > 0` and the returned list holds a recap for that partner with `itemCount > 0`, it calls `onChanged()` and shows a `SnackBar` on the cached messenger (if still mounted): `studyRecapSaved(itemCount)` with action `studyRecapReview` that pushes `MyWordsScreen` on the cached navigator (if mounted) and logs `recap_opened`. Any failure is swallowed.
- **Handoff doc** (`docs/releases/ai-study-check-recap-app-handoff.md`): what the two flags show; a device checklist (check appears only in one-to-one chats, only for 3+ words not in the native language; each sheet state; send while a check is pending; rooms unchanged; recap card on hub and My words; line on leaving a chat; all with flags off → no change); the 16 machine-drafted strings needing native review in 18 languages; plan calls (no locked line until phase 3; allowance is not fetched up front, it is learned from the first check; the line shows once, when the recap is created); nothing is device-tested.

- [ ] **Step 1:** Write `test/study/study_recap_card_test.dart` on the `_pumpHub` harness of `test/study/study_doors_test.dart`: recap flag off → no card and `studyRecapsProvider` never read (override it with a provider that fails the test if built); flag on + empty list → no card, hub children otherwise unchanged; flag on + a never-completing recaps future → the hub still shows `MyWordsDoorCard`; one recap (Mina, 2 words, 1 mistake) → title and "3 things saved from this chat" above the My words door, `recap_shown` logged once across two rebuilds; tap pushes `MyWordsScreen` and logs `recap_opened`; doors flag off + recap flag on → no card.
- [ ] **Step 2:** Write `test/study/my_words_recap_test.dart` on the `_pump` harness of `test/study/my_words_screen_test.dart`: flag off → identical children to the no-recap case; a recap whose word `w1` and mistake `m1` are also in `myWordsProvider` → each appears exactly once, under the recap header; Keep on the recap word calls the fake API's `keep('w1')` and invalidates the recaps provider (fetch count rises); a recap as the only content → the empty text is absent; a recap with zero items → no header.
- [ ] **Step 3:** Write `test/study/study_recap_leave_test.dart` (plain unit/widget test with a fake API and a real `ScaffoldMessenger` in a pumped `MaterialApp`): `enabled: false` → no call; `sentThisVisit: 0` → no call; `created: 0` → no snackbar; `created: 1` with a recap for partner `p1` of 3 items → snackbar text "3 things saved from this chat", `onChanged` called once, the Review action pushes `MyWordsScreen` and logs `recap_opened`; the returned list has no recap for `p1` → no snackbar; `build` throws → nothing shown, nothing thrown; the messenger's widget was removed from the tree before `build` completed → no throw.
- [ ] **Step 4:** Run; expect failures. Implement. Run `flutter test test/study test/chat test/learning test/rooms` — all pass. `flutter analyze` at baseline.
- [ ] **Step 5:** Write the handoff doc; update `docs/REMAINING_WORK.md` (device pass for check and recap; native review; locked recap line and upgrade prompt wait for phase 3; privacy line about checked text is the owner's call before `STUDY_CHECK_ENABLED`).
- [ ] **Step 6:** Commit (`feat(study): after-chat recap on the hub, my words and on leaving a chat; handoff`).
