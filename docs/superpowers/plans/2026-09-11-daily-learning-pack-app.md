# Daily Learning Pack — Flutter Implementation Plan (Wave 1, Plan 2 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two plain `ListTile` cards and the `RadioListTile` screen with a hero card on the Learn tab that opens a focused, full-screen four-station flow, plus a placement screen and a mastery view.

**Architecture:** One model file parses the `GET /study/pack` envelope into a `DailyPack` with a list of `PackStation`s. One `daily_pack_flow.dart` hosts a `PageView` of station widgets; each station commits on its own through `LearningService`, so an abandoned session keeps finished work. Every station renders its questions through a single shared `CheckQuestion` widget. All submit calls are injected as callbacks (the pattern already used by `DailyDropScreen`) so widget tests never touch the network.

**Tech Stack:** Flutter 3.38.7 / Dart 3.10.7, `flutter_riverpod`, `flutter_test`, `AppLocalizations` (19 ARB locales). No new packages — the spec's motion is implicit animations only.

**Spec:** `docs/superpowers/specs/2026-09-11-daily-learning-pack-design.md`

**Depends on:** Plan 1 (`docs/superpowers/plans/2026-09-11-daily-learning-pack-backend.md`) — Tasks 7–10 define every endpoint used here. Endpoint shapes are restated in each task, so this plan can be implemented against a stub if the backend is not merged yet.

**Repo:** `/Users/davis/Desktop/Personal/language_exchange_flutter_application` — Flutter code lives in `bananatalk_app/`. Branch from `main` as `feat/daily-pack-app`.

## Global Constraints

- **Working directories.** `flutter analyze` and `flutter test` run from `bananatalk_app/` (the pubspec lives there; running from the repo root fails with "No pubspec.yaml found"). `git` commands run from the repo root, which is why every `git add` path below is prefixed `bananatalk_app/`.
- **`package:` imports only.** `import 'package:bananatalk_app/...'` — never a relative `../../` path. The linter enforces this.
- **No new dependencies.**
- **Every user-visible string goes through `AppLocalizations`.** Add the key plus an `@key` metadata block to `lib/l10n/app_en.arb` (2,754 keys today) in the existing style: `"todayMinutes": "{count} min"` with `"placeholders": { "count": { "type": "int" } }`. The other 18 locales are handled in Task 10 — **never** ship a hardcoded English string in a widget.
- **Colour is never the only signal.** Correct/incorrect always carries an icon and text as well (spec §7.2, accessibility).
- **Theme tokens only.** Use `AppColors` from `lib/core/theme/app_theme.dart` and the `ThemeContext` extension from `lib/utils/theme_extensions.dart` (`context.textSecondary`, `context.cardBackground`, …). Do not introduce new colour constants.
- **Tap targets ≥ 44pt**, and layouts must stay legible at text scale 1.3.
- **Widget tests host with localisation:**
  ```dart
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: /* widget under test */),
  )
  ```
- **Injected callbacks, not network calls.** Every station widget takes its submit function as a constructor parameter defaulting to the real `LearningService` method — exactly how `DailyDropScreen` takes `SubmitAnswers`/`SubmitFeedback` today.
- **The server owns scoring and completion.** The client never computes whether the day is complete, never counts stations done, and never receives `answerIndex`. Render `packComplete` and `stationsRemaining` from the response.
- **Keys on every interactive element** for tests, following the existing convention (`Key('daily-submit')`, `Key('daily-q0-opt1')`).
- **Verified APIs this plan relies on**: `flutter_riverpod: ^2.4.10` (so `AsyncValue.valueOrNull` exists), `AppPageRoute` from `package:bananatalk_app/utils/app_page_route.dart`, and `Color.withValues(alpha:)` — all three are already used elsewhere in the app.

---

## File Structure

| File | Responsibility |
|---|---|
| Create `lib/models/learning/daily_pack_model.dart` | `DailyPack`, `PackStation`, `StationStatus`, payload types, `StationResult`, `MasterySummary` |
| Create `lib/providers/provider_root/learning/daily_pack_providers.dart` | `dailyPackProvider`, `masteryProvider` (locale-aware, mirrors `daily_drop_providers.dart`) |
| Modify `lib/services/learning_service.dart` | `getDailyPack`, `completeStation`, `getPlacement`, `submitPlacement`, `getMastery` |
| Modify `lib/service/endpoints.dart` | Five new endpoint constants |
| Create `lib/pages/learning/daily/daily_pack_hero_card.dart` | The Learn-tab entry point (replaces `TodaySection`) |
| Create `lib/pages/learning/daily/daily_pack_flow.dart` | Full-screen host: rail + `PageView` + exit guard |
| Create `lib/pages/learning/daily/widgets/check_question.dart` | The one question widget every station uses |
| Create `lib/pages/learning/daily/widgets/station_rail.dart` | `●●○○` progress across stations |
| Create `lib/pages/learning/daily/widgets/word_card.dart` | Headword, definition, example, audio affordance |
| Create `lib/pages/learning/daily/widgets/day_complete_sheet.dart` | Completion moment: streak, XP, tomorrow's teaser |
| Create `lib/pages/learning/daily/stations/station_scaffold.dart` | `SubmitAnswers` typedef + `CheckSequence`, the teach-then-check body four stations share |
| Create `lib/pages/learning/daily/stations/vocab_station.dart` | 5 new words → checks |
| Create `lib/pages/learning/daily/stations/grammar_station.dart` | Explanation, examples, 3 checks |
| Create `lib/pages/learning/daily/stations/listening_station.dart` | 2 clips (text in wave 1) → checks |
| Create `lib/pages/learning/daily/stations/review_station.dart` | Due words, correct/incorrect per word |
| Create `lib/pages/learning/daily/stations/wrap_station.dart` | Friday quiz over the week |
| Create `lib/pages/learning/daily/stations/translate_station.dart` | Weekend typed translation |
| Create `lib/pages/learning/daily/placement/placement_screen.dart` | 8 questions → level |
| Create `lib/pages/learning/progress/mastery_screen.dart` | Per-skill mastery |
| Create `lib/pages/learning/progress/widgets/mastery_bar.dart` | One skill's bar + counts |
| Create `lib/pages/learning/progress/widgets/streak_calendar.dart` | 30-day dot grid |
| Modify `lib/pages/learning/main/sections/learn_tab.dart:56-79, 94` | Swap `TodaySection` → hero card; move `DailyPracticeCard` |
| Delete `lib/pages/learning/daily/widgets/today_section.dart`, `lib/pages/learning/daily/daily_drop_screen.dart` | Replaced (Task 11) |

---

### Task 1: Pack model

**Files:**
- Create: `bananatalk_app/lib/models/learning/daily_pack_model.dart`
- Test: `bananatalk_app/test/learning/daily_pack_model_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum StationStatus { todo, done, empty }`
  - `class PackStation { String kind; StationStatus status; int? score; StationPayload? payload; }`
  - `class DailyPack { bool needsLanguage; String dateKey, weekKey; int dayInWeek; String? language, requestedLevel, servedLevel; PackTheme? theme; List<PackStation> stations; bool packComplete; PackStation? stationOf(String kind); int get doneCount; }`
  - `class StationResult { int score, total, xpAwarded; int? streak; bool packComplete; List<String> stationsRemaining; }`
  - `class MasterySummary { … }` (Task 8)

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/daily_pack_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';

Map<String, dynamic> _packJson() => {
      'needsLanguage': false,
      'dateKey': '2026-09-07',
      'weekKey': '2026-W37',
      'dayInWeek': 1,
      'language': 'en',
      'requestedLevel': 'A2',
      'servedLevel': 'A2',
      'theme': {'id': 'p1', 'topic': 'Work & careers', 'level': 'intermediate'},
      'packComplete': false,
      'stations': [
        {
          'kind': 'vocabulary',
          'status': 'todo',
          'score': null,
          'payload': {
            'words': [
              {'word': 'ambition', 'definition': 'a strong wish', 'example': 'Her ambition showed.'}
            ],
            'checks': [
              {'prompt': 'Which word means "a strong wish"?', 'options': ['ambition', 'colleague', 'salary']}
            ],
          },
        },
        {'kind': 'grammar', 'status': 'done', 'score': 2, 'payload': null},
        {'kind': 'listening', 'status': 'todo', 'payload': {'clips': [
          {'id': 'c0', 'text': 'She is waiting outside.', 'word': 'waiting'}
        ]}},
        {'kind': 'review', 'status': 'empty', 'payload': null},
      ],
    };

void main() {
  test('parses the pack envelope', () {
    final pack = DailyPack.fromJson(_packJson());
    expect(pack.needsLanguage, isFalse);
    expect(pack.weekKey, '2026-W37');
    expect(pack.dayInWeek, 1);
    expect(pack.theme!.topic, 'Work & careers');
    expect(pack.stations.length, 4);
  });

  test('maps station status strings onto the enum', () {
    final pack = DailyPack.fromJson(_packJson());
    expect(pack.stationOf('vocabulary')!.status, StationStatus.todo);
    expect(pack.stationOf('grammar')!.status, StationStatus.done);
    expect(pack.stationOf('review')!.status, StationStatus.empty);
  });

  test('an unknown status degrades to todo rather than throwing', () {
    final json = _packJson();
    (json['stations'] as List)[0]['status'] = 'something-new';
    expect(DailyPack.fromJson(json).stationOf('vocabulary')!.status, StationStatus.todo);
  });

  test('doneCount counts done and empty stations, matching the server ring', () {
    // 'empty' is satisfied, not outstanding — a learner with no due words must
    // not see 3 of 4 forever.
    expect(DailyPack.fromJson(_packJson()).doneCount, 2);
  });

  test('parses a vocabulary payload with words and checks', () {
    final station = DailyPack.fromJson(_packJson()).stationOf('vocabulary')!;
    final payload = station.payload as VocabPayload;
    expect(payload.words.single.word, 'ambition');
    expect(payload.checks.single.options.length, 3);
  });

  test('parses a listening payload', () {
    final payload =
        DailyPack.fromJson(_packJson()).stationOf('listening')!.payload as ListeningPayload;
    expect(payload.clips.single.text, 'She is waiting outside.');
  });

  test('needsLanguage responses parse without any stations', () {
    final pack = DailyPack.fromJson({'needsLanguage': true});
    expect(pack.needsLanguage, isTrue);
    expect(pack.stations, isEmpty);
  });

  test('a missing theme is null, not a crash', () {
    final json = _packJson()..remove('theme');
    expect(DailyPack.fromJson(json).theme, isNull);
  });

  test('level fallback is reported when served differs from requested', () {
    final json = _packJson()..['servedLevel'] = 'A1';
    expect(DailyPack.fromJson(json).isLevelFallback, isTrue);
    expect(DailyPack.fromJson(_packJson()).isLevelFallback, isFalse);
  });

  test('parses a station result', () {
    final result = StationResult.fromJson({
      'score': 2, 'total': 3, 'xpAwarded': 10, 'streak': 4,
      'packComplete': false, 'stationsRemaining': ['review'],
    });
    expect(result.score, 2);
    expect(result.streak, 4);
    expect(result.stationsRemaining, ['review']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/daily_pack_model_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:bananatalk_app/models/learning/daily_pack_model.dart'`

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/models/learning/daily_pack_model.dart

/// Models for the daily learning pack (spec §5.5, §7).
///
/// The server owns scoring and completion: no `answerIndex` is ever sent, and
/// `packComplete` / `doneCount` reflect the server's own view rather than a
/// client-side count.

enum StationStatus { todo, done, empty }

StationStatus _statusFrom(String? raw) {
  switch (raw) {
    case 'done':
      return StationStatus.done;
    case 'empty':
      return StationStatus.empty;
    default:
      // An unknown status must not break the flow — a newer server adding a
      // status should degrade to "still to do", not throw on parse.
      return StationStatus.todo;
  }
}

abstract class StationPayload {}

class PackCheck {
  final String prompt;
  final List<String> options;

  const PackCheck({required this.prompt, required this.options});

  factory PackCheck.fromJson(Map<String, dynamic> json) => PackCheck(
        prompt: json['prompt'] as String? ?? '',
        options:
            (json['options'] as List? ?? const []).map((e) => e.toString()).toList(),
      );
}

class PackWord {
  final String word;
  final String definition;
  final String example;
  final String translationHint;

  const PackWord({
    required this.word,
    required this.definition,
    required this.example,
    this.translationHint = '',
  });

  factory PackWord.fromJson(Map<String, dynamic> json) => PackWord(
        word: json['word'] as String? ?? '',
        definition: json['definition'] as String? ?? '',
        example: json['example'] as String? ?? '',
        translationHint: json['translationHint'] as String? ?? '',
      );
}

class VocabPayload implements StationPayload {
  final List<PackWord> words;
  final List<PackCheck> checks;

  const VocabPayload({required this.words, required this.checks});

  factory VocabPayload.fromJson(Map<String, dynamic> json) => VocabPayload(
        words: (json['words'] as List? ?? const [])
            .map((e) => PackWord.fromJson(e as Map<String, dynamic>))
            .toList(),
        checks: (json['checks'] as List? ?? const [])
            .map((e) => PackCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GrammarPayload implements StationPayload {
  final String itemId;
  final int unit;
  final String section;
  final String title;
  final String explanation;
  final List<String> examples;
  final List<PackCheck> checks;

  const GrammarPayload({
    required this.itemId,
    required this.unit,
    required this.section,
    required this.title,
    required this.explanation,
    required this.examples,
    required this.checks,
  });

  factory GrammarPayload.fromJson(Map<String, dynamic> json) => GrammarPayload(
        itemId: json['itemId'].toString(),
        unit: (json['unit'] as num?)?.toInt() ?? 0,
        section: json['section'] as String? ?? '',
        title: json['title'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        examples: (json['examples'] as List? ?? const [])
            .map((e) => (e as Map<String, dynamic>)['text'].toString())
            .toList(),
        checks: (json['checks'] as List? ?? const [])
            .map((e) => PackCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ListeningClip {
  final String id;
  final String text;
  final String word;

  const ListeningClip({required this.id, required this.text, required this.word});

  factory ListeningClip.fromJson(Map<String, dynamic> json) => ListeningClip(
        id: json['id'].toString(),
        text: json['text'] as String? ?? '',
        word: json['word'] as String? ?? '',
      );
}

class ListeningPayload implements StationPayload {
  final List<ListeningClip> clips;

  const ListeningPayload({required this.clips});

  factory ListeningPayload.fromJson(Map<String, dynamic> json) => ListeningPayload(
        clips: (json['clips'] as List? ?? const [])
            .map((e) => ListeningClip.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ReviewWord {
  final String id;
  final String word;
  final String translation;
  final int srsLevel;

  const ReviewWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.srsLevel,
  });

  factory ReviewWord.fromJson(Map<String, dynamic> json) => ReviewWord(
        id: json['id'].toString(),
        word: json['word'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        srsLevel: (json['srsLevel'] as num?)?.toInt() ?? 0,
      );
}

class ReviewPayload implements StationPayload {
  final List<ReviewWord> words;

  const ReviewPayload({required this.words});

  factory ReviewPayload.fromJson(Map<String, dynamic> json) => ReviewPayload(
        words: (json['words'] as List? ?? const [])
            .map((e) => ReviewWord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WrapPayload implements StationPayload {
  final List<PackCheck> questions;

  const WrapPayload({required this.questions});

  factory WrapPayload.fromJson(Map<String, dynamic> json) => WrapPayload(
        questions: (json['questions'] as List? ?? const [])
            .map((e) => PackCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TranslatePayload implements StationPayload {
  final String prompt;

  const TranslatePayload({required this.prompt});

  factory TranslatePayload.fromJson(Map<String, dynamic> json) =>
      TranslatePayload(prompt: json['prompt'] as String? ?? '');
}

StationPayload? _payloadFor(String kind, Map<String, dynamic>? json) {
  if (json == null) return null;
  switch (kind) {
    case 'vocabulary':
      return VocabPayload.fromJson(json);
    case 'grammar':
      return GrammarPayload.fromJson(json);
    case 'listening':
      return ListeningPayload.fromJson(json);
    case 'review':
      return ReviewPayload.fromJson(json);
    case 'wrap':
      return WrapPayload.fromJson(json);
    case 'translate':
      return TranslatePayload.fromJson(json);
    default:
      return null;
  }
}

class PackStation {
  final String kind;
  final StationStatus status;
  final int? score;
  final StationPayload? payload;

  const PackStation({
    required this.kind,
    required this.status,
    this.score,
    this.payload,
  });

  bool get isOutstanding => status == StationStatus.todo;

  factory PackStation.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String? ?? '';
    return PackStation(
      kind: kind,
      status: _statusFrom(json['status'] as String?),
      score: (json['score'] as num?)?.toInt(),
      payload: _payloadFor(kind, json['payload'] as Map<String, dynamic>?),
    );
  }
}

class PackTheme {
  final String id;
  final String topic;
  final String level;

  const PackTheme({required this.id, required this.topic, required this.level});

  factory PackTheme.fromJson(Map<String, dynamic> json) => PackTheme(
        id: json['id'].toString(),
        topic: json['topic'] as String? ?? '',
        level: json['level'] as String? ?? '',
      );
}

class DailyPack {
  final bool needsLanguage;
  final String dateKey;
  final String weekKey;
  final int dayInWeek;
  final String? language;
  final String? requestedLevel;
  final String? servedLevel;
  final PackTheme? theme;
  final List<PackStation> stations;
  final bool packComplete;

  const DailyPack({
    required this.needsLanguage,
    required this.dateKey,
    required this.weekKey,
    required this.dayInWeek,
    this.language,
    this.requestedLevel,
    this.servedLevel,
    this.theme,
    this.stations = const [],
    this.packComplete = false,
  });

  PackStation? stationOf(String kind) {
    for (final s in stations) {
      if (s.kind == kind) return s;
    }
    return null;
  }

  /// Stations that need nothing more from the learner. 'empty' counts as
  /// satisfied — a learner with no due words must not sit on 3 of 4 forever.
  int get doneCount =>
      stations.where((s) => s.status != StationStatus.todo).length;

  PackStation? get nextStation {
    for (final s in stations) {
      if (s.isOutstanding) return s;
    }
    return null;
  }

  bool get isLevelFallback =>
      servedLevel != null && requestedLevel != null && servedLevel != requestedLevel;

  factory DailyPack.fromJson(Map<String, dynamic> json) => DailyPack(
        needsLanguage: json['needsLanguage'] as bool? ?? false,
        dateKey: json['dateKey'] as String? ?? '',
        weekKey: json['weekKey'] as String? ?? '',
        dayInWeek: (json['dayInWeek'] as num?)?.toInt() ?? 0,
        language: json['language'] as String?,
        requestedLevel: json['requestedLevel'] as String?,
        servedLevel: json['servedLevel'] as String?,
        theme: json['theme'] == null
            ? null
            : PackTheme.fromJson(json['theme'] as Map<String, dynamic>),
        stations: (json['stations'] as List? ?? const [])
            .map((e) => PackStation.fromJson(e as Map<String, dynamic>))
            .toList(),
        packComplete: json['packComplete'] as bool? ?? false,
      );
}

class StationResult {
  final int score;
  final int total;
  final int xpAwarded;
  final int? streak;
  final bool packComplete;
  final List<String> stationsRemaining;

  const StationResult({
    required this.score,
    required this.total,
    this.xpAwarded = 0,
    this.streak,
    this.packComplete = false,
    this.stationsRemaining = const [],
  });

  factory StationResult.fromJson(Map<String, dynamic> json) => StationResult(
        score: (json['score'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
        streak: (json['streak'] as num?)?.toInt(),
        packComplete: json['packComplete'] as bool? ?? false,
        stationsRemaining: (json['stationsRemaining'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bananatalk_app && flutter test test/learning/daily_pack_model_test.dart`
Expected: PASS, 10 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/models/learning/daily_pack_model.dart \
        bananatalk_app/test/learning/daily_pack_model_test.dart
git commit -m "feat(daily-pack): pack model"
```

---

### Task 2: Service and endpoints

**Files:**
- Modify: `bananatalk_app/lib/service/endpoints.dart` (after line 300)
- Modify: `bananatalk_app/lib/services/learning_service.dart` (after `submitDailyFeedback`, ~line 1510)
- Create: `bananatalk_app/lib/providers/provider_root/learning/daily_pack_providers.dart`
- Test: `bananatalk_app/test/learning/daily_pack_providers_test.dart`

**Interfaces:**
- Consumes: `DailyPack`, `StationResult` (Task 1); `dailyDropLocaleTag` from the existing `daily_drop_providers.dart`.
- Produces:
  - `LearningService.getDailyPack({String? locale}) → Future<DailyPack>`
  - `LearningService.completeStation(String station, {List<int> answers, List<Map<String, dynamic>> reviews}) → Future<StationResult>`
  - `LearningService.getPlacement() → Future<List<PackCheck>>`
  - `LearningService.submitPlacement(List<int> answers) → Future<Map<String, dynamic>>`
  - `LearningService.getMastery() → Future<MasterySummary>` (added in Task 8)
  - `dailyPackProvider` — `FutureProvider<DailyPack>`

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/daily_pack_providers_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';

void main() {
  test('pack endpoints are wired to the study routes', () {
    expect(Endpoints.dailyPackURL, 'study/pack');
    expect(Endpoints.dailyPackCompleteURL('grammar'), 'study/pack/grammar/complete');
    expect(Endpoints.placementURL, 'study/placement');
    expect(Endpoints.masteryURL, 'learning/mastery');
  });

  test('the pack locale tag follows the daily-drop mapping', () {
    // Content is authored in en, zh-Hans and ar; anything else degrades to en.
    expect(packLocaleTag(const Locale('ar')), 'ar');
    expect(packLocaleTag(const Locale('zh')), 'zh-Hans');
    expect(packLocaleTag(const Locale('ko')), 'en');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/daily_pack_providers_test.dart`
Expected: FAIL — `Target of URI doesn't exist` / `Endpoints.dailyPackURL` undefined

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/service/endpoints.dart — add after dailyFeedbackURL (line 300)
  // Daily learning pack (four stations under a weekly theme)
  static const String dailyPackURL = 'study/pack';
  static String dailyPackCompleteURL(String station) => 'study/pack/$station/complete';
  static const String placementURL = 'study/placement';
  static const String masteryURL = 'learning/mastery';
```

```dart
// bananatalk_app/lib/services/learning_service.dart — add after submitDailyFeedback
  /// Today's four-station pack.
  static Future<DailyPack> getDailyPack({String? locale}) async {
    final token = await _getToken();
    var url = Uri.parse('${Endpoints.baseURL}${Endpoints.dailyPackURL}');
    if (locale != null) {
      url = url.replace(queryParameters: {'locale': locale});
    }
    final response = await http.get(url, headers: _headers(token));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return DailyPack.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(_getErrorMessage(data, 'Daily pack fetch failed'));
  }

  /// Commit one station. Stations commit independently, so abandoning the flow
  /// keeps whatever the learner finished.
  static Future<StationResult> completeStation(
    String station, {
    List<int> answers = const [],
    List<Map<String, dynamic>> reviews = const [],
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.dailyPackCompleteURL(station)}');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode({'answers': answers, 'reviews': reviews}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return StationResult.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(_getErrorMessage(data, 'Station submission failed'));
  }

  /// The placement questions (no answer key is ever sent to the client).
  static Future<List<PackCheck>> getPlacement() async {
    final token = await _getToken();
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.placementURL}');
    final response = await http.get(url, headers: _headers(token));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return ((data['data'] as Map<String, dynamic>)['questions'] as List)
          .map((e) => PackCheck.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_getErrorMessage(data, 'Placement fetch failed'));
  }

  /// Submit placement answers; the server sets the caller's level.
  static Future<Map<String, dynamic>> submitPlacement(List<int> answers) async {
    final token = await _getToken();
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.placementURL}');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode({'answers': answers}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(_getErrorMessage(data, 'Placement submission failed'));
  }
```

> If `_headers(token)` does not exist in this file, use the same header construction the neighbouring methods use (read `getDailyDrop` at line 1471 and copy its form exactly).

```dart
// bananatalk_app/lib/providers/provider_root/learning/daily_pack_providers.dart
import 'package:flutter/widgets.dart';
import 'package:bananatalk_app/main.dart' show languageProvider;
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The locale keys pack content is authored in — same mapping as the daily
/// drop's. Traditional Chinese maps to zh-Hans deliberately: no Traditional
/// explanations exist, and Simplified is far closer for that reader than an
/// English explanation of the language they are learning.
String packLocaleTag(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'ar';
    case 'zh':
      return 'zh-Hans';
    default:
      return 'en';
  }
}

/// Today's pack for the signed-in learner, in the app's locale. Watches
/// [languageProvider] so switching app language refetches the explanations.
final dailyPackProvider = FutureProvider<DailyPack>((ref) async {
  final locale = ref.watch(languageProvider);
  return LearningService.getDailyPack(locale: packLocaleTag(locale));
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bananatalk_app && flutter test test/learning/daily_pack_providers_test.dart`
Expected: PASS, 2 tests

- [ ] **Step 5: Verify the app still analyzes**

Run: `cd bananatalk_app && flutter analyze lib/services/learning_service.dart lib/service/endpoints.dart lib/providers/provider_root/learning/daily_pack_providers.dart`
Expected: No new issues.

- [ ] **Step 6: Commit**

```bash
git add bananatalk_app/lib/service/endpoints.dart bananatalk_app/lib/services/learning_service.dart \
        bananatalk_app/lib/providers/provider_root/learning/daily_pack_providers.dart \
        bananatalk_app/test/learning/daily_pack_providers_test.dart
git commit -m "feat(daily-pack): pack service, endpoints and provider"
```

---

### Task 3: The shared check question widget

This is the single most reused widget in the feature — every station scores through it, so a check feels identical whether it came from a pack word or a grammar unit. It replaces every `RadioListTile` in the old screen.

**Files:**
- Create: `bananatalk_app/lib/pages/learning/daily/widgets/check_question.dart`
- Test: `bananatalk_app/test/learning/check_question_test.dart`

**Interfaces:**
- Consumes: `PackCheck` (Task 1).
- Produces: `CheckQuestion({required PackCheck check, required int index, int? selected, int? correctIndex, required ValueChanged<int> onSelect, String? explanation})`.

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/check_question_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/check_question.dart';

const _check = PackCheck(
  prompt: 'She ___ to work every day.',
  options: ['go', 'goes', 'going'],
);

Widget _host({
  int? selected,
  int? correctIndex,
  ValueChanged<int>? onSelect,
  String? explanation,
}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CheckQuestion(
          check: _check,
          index: 0,
          selected: selected,
          correctIndex: correctIndex,
          explanation: explanation,
          onSelect: onSelect ?? (_) {},
        ),
      ),
    );

void main() {
  testWidgets('renders the prompt and every option', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('She ___ to work every day.'), findsOneWidget);
    for (final o in _check.options) {
      expect(find.text(o), findsOneWidget);
    }
  });

  testWidgets('tapping an option reports its index', (tester) async {
    int? picked;
    await tester.pumpWidget(_host(onSelect: (i) => picked = i));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    expect(picked, 1);
  });

  testWidgets('a correct answer is marked with an icon, not colour alone', (tester) async {
    await tester.pumpWidget(_host(selected: 1, correctIndex: 1));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('a wrong answer marks both the choice and the right answer', (tester) async {
    await tester.pumpWidget(_host(selected: 0, correctIndex: 1));
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('the explanation appears only after answering', (tester) async {
    await tester.pumpWidget(_host(explanation: 'Third person takes -s.'));
    expect(find.text('Third person takes -s.'), findsNothing);

    await tester.pumpWidget(_host(selected: 1, correctIndex: 1, explanation: 'Third person takes -s.'));
    expect(find.text('Third person takes -s.'), findsOneWidget);
  });

  testWidgets('options stop responding once answered', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(selected: 1, correctIndex: 1, onSelect: (_) => taps++));
    await tester.tap(find.byKey(const Key('check-q0-opt2')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 0);
  });

  testWidgets('every option meets the 44pt minimum tap target', (tester) async {
    await tester.pumpWidget(_host());
    for (var i = 0; i < _check.options.length; i++) {
      final size = tester.getSize(find.byKey(Key('check-q0-opt$i')));
      expect(size.height, greaterThanOrEqualTo(44.0));
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/check_question_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../check_question.dart'`

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/pages/learning/daily/widgets/check_question.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One multiple-choice check, used by every station so a question feels the
/// same wherever it came from. Replaces the RadioListTile list the old daily
/// drop screen used.
///
/// Correctness is signalled by icon AND text, never by colour alone — a
/// colour-blind learner has to be able to tell a right answer from a wrong one.
class CheckQuestion extends StatelessWidget {
  final PackCheck check;
  final int index;
  final int? selected;
  final int? correctIndex;
  final String? explanation;
  final ValueChanged<int> onSelect;

  const CheckQuestion({
    super.key,
    required this.check,
    required this.index,
    required this.onSelect,
    this.selected,
    this.correctIndex,
    this.explanation,
  });

  bool get _answered => correctIndex != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(check.prompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...List.generate(check.options.length, (o) {
          final isCorrect = _answered && o == correctIndex;
          final isWrongPick = _answered && o == selected && o != correctIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: Key('check-q$index-opt$o'),
              borderRadius: BorderRadius.circular(12),
              onTap: _answered ? null : () => onSelect(o),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? theme.colorScheme.primary
                        : isWrongPick
                            ? theme.colorScheme.error
                            : (selected == o
                                ? theme.colorScheme.primary
                                : context.dividerColor),
                    width: (isCorrect || isWrongPick || selected == o) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(check.options[o], style: theme.textTheme.bodyLarge),
                    ),
                    if (isCorrect)
                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    if (isWrongPick)
                      Icon(Icons.cancel, color: theme.colorScheme.error, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_answered && (explanation ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              explanation!,
              key: Key('check-q$index-explanation'),
              style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bananatalk_app && flutter test test/learning/check_question_test.dart`
Expected: PASS, 7 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/learning/daily/widgets/check_question.dart \
        bananatalk_app/test/learning/check_question_test.dart
git commit -m "feat(daily-pack): shared check question widget"
```

---

### Task 4: Station rail

**Files:**
- Create: `bananatalk_app/lib/pages/learning/daily/widgets/station_rail.dart`
- Test: `bananatalk_app/test/learning/station_rail_test.dart`

**Interfaces:**
- Consumes: `PackStation`, `StationStatus` (Task 1).
- Produces: `StationRail({required List<PackStation> stations, required int currentIndex})`.

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/station_rail_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/station_rail.dart';

PackStation _s(String kind, StationStatus status) =>
    PackStation(kind: kind, status: status);

Widget _host(List<PackStation> stations, int current) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StationRail(stations: stations, currentIndex: current)),
    );

void main() {
  testWidgets('renders one dot per station', (tester) async {
    await tester.pumpWidget(_host([
      _s('vocabulary', StationStatus.done),
      _s('grammar', StationStatus.todo),
      _s('listening', StationStatus.todo),
      _s('review', StationStatus.empty),
    ], 1));
    expect(find.byKey(const Key('rail-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('rail-dot-3')), findsOneWidget);
  });

  testWidgets('states the server-side progress count', (tester) async {
    // done + empty = 2 of 4; the client never recomputes this.
    await tester.pumpWidget(_host([
      _s('vocabulary', StationStatus.done),
      _s('grammar', StationStatus.todo),
      _s('listening', StationStatus.todo),
      _s('review', StationStatus.empty),
    ], 1));
    expect(find.text('2/4'), findsOneWidget);
  });

  testWidgets('marks the current station', (tester) async {
    await tester.pumpWidget(_host([
      _s('vocabulary', StationStatus.done),
      _s('grammar', StationStatus.todo),
    ], 1));
    final rail = tester.widget<StationRail>(find.byType(StationRail));
    expect(rail.currentIndex, 1);
    expect(find.byKey(const Key('rail-dot-1-current')), findsOneWidget);
  });

  testWidgets('an empty station list renders nothing rather than throwing', (tester) async {
    await tester.pumpWidget(_host(const [], 0));
    expect(find.byType(StationRail), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/station_rail_test.dart`
Expected: FAIL — URI doesn't exist

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/pages/learning/daily/widgets/station_rail.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Progress across the day's stations. The count comes from the server's view
/// of the pack (done + empty), never from a client-side tally.
class StationRail extends StatelessWidget {
  final List<PackStation> stations;
  final int currentIndex;

  const StationRail({super.key, required this.stations, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final done = stations.where((s) => s.status != StationStatus.todo).length;

    return Row(
      children: [
        ...List.generate(stations.length, (i) {
          final s = stations[i];
          final satisfied = s.status != StationStatus.todo;
          final isCurrent = i == currentIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                key: isCurrent ? Key('rail-dot-$i-current') : Key('rail-dot-$i'),
                duration: const Duration(milliseconds: 220),
                height: isCurrent ? 6 : 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: satisfied
                      ? theme.colorScheme.primary
                      : isCurrent
                          ? theme.colorScheme.primary.withValues(alpha: 0.45)
                          : context.dividerColor,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text('$done/${stations.length}', style: theme.textTheme.labelMedium),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd bananatalk_app && flutter test test/learning/station_rail_test.dart`
Expected: PASS, 4 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/learning/daily/widgets/station_rail.dart \
        bananatalk_app/test/learning/station_rail_test.dart
git commit -m "feat(daily-pack): station progress rail"
```

---

### Task 5: Vocabulary, grammar and listening stations

These three share a shape — teach, then check — so they are one task: a reviewer approving one would approve all three, and splitting them would triple the identical test scaffold.

**Files:**
- Create: `bananatalk_app/lib/pages/learning/daily/widgets/word_card.dart`
- Create: `bananatalk_app/lib/pages/learning/daily/stations/vocab_station.dart`
- Create: `bananatalk_app/lib/pages/learning/daily/stations/grammar_station.dart`
- Create: `bananatalk_app/lib/pages/learning/daily/stations/listening_station.dart`
- Test: `bananatalk_app/test/learning/pack_stations_test.dart`

**Interfaces:**
- Consumes: payload types (Task 1), `CheckQuestion` (Task 3).
- Produces (identical constructor shape for all three, so `daily_pack_flow` can treat them uniformly):
  - `VocabStation({required VocabPayload payload, required Future<StationResult> Function(List<int>) onSubmit, required VoidCallback onDone})`
  - `GrammarStation({required GrammarPayload payload, required Future<StationResult> Function(List<int>) onSubmit, required VoidCallback onDone})`
  - `ListeningStation({required ListeningPayload payload, required Future<StationResult> Function(List<int>) onSubmit, required VoidCallback onDone})`

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/pack_stations_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/grammar_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/listening_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/vocab_station.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

const _vocab = VocabPayload(
  words: [
    PackWord(word: 'ambition', definition: 'a strong wish', example: 'Her ambition showed.'),
    PackWord(word: 'colleague', definition: 'someone you work with', example: 'My colleague helped.'),
  ],
  checks: [
    PackCheck(prompt: 'Which word means "a strong wish"?', options: ['ambition', 'colleague', 'salary']),
    PackCheck(prompt: 'Which word means "someone you work with"?', options: ['salary', 'colleague', 'ambition']),
  ],
);

const _grammar = GrammarPayload(
  itemId: 'g1', unit: 15, section: 'Present perfect', title: 'present perfect',
  explanation: 'Use have plus the past participle.',
  examples: ['I have finished.', 'She has left.'],
  checks: [
    PackCheck(prompt: 'We ___ here since 2019.', options: ['live', 'have lived', 'are living']),
  ],
);

const _listening = ListeningPayload(
  clips: [
    ListeningClip(id: 'c0', text: 'She is waiting outside.', word: 'waiting'),
  ],
);

StationResult _ok() => const StationResult(score: 2, total: 2, xpAwarded: 10, streak: 3);

void main() {
  testWidgets('the vocabulary station teaches its words before checking', (tester) async {
    await tester.pumpWidget(_host(VocabStation(
      payload: _vocab, onSubmit: (_) async => _ok(), onDone: () {},
    )));
    expect(find.text('ambition'), findsOneWidget);
    expect(find.text('a strong wish'), findsOneWidget);
    // Checks appear only after the learner walks the words.
    expect(find.text('Which word means "a strong wish"?'), findsNothing);
  });

  testWidgets('advancing past the words reveals the checks', (tester) async {
    await tester.pumpWidget(_host(VocabStation(
      payload: _vocab, onSubmit: (_) async => _ok(), onDone: () {},
    )));
    for (var i = 0; i < _vocab.words.length; i++) {
      await tester.tap(find.byKey(const Key('word-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Which word means "a strong wish"?'), findsOneWidget);
  });

  testWidgets('submit stays disabled until every check is answered', (tester) async {
    await tester.pumpWidget(_host(GrammarStation(
      payload: _grammar, onSubmit: (_) async => _ok(), onDone: () {},
    )));
    final button = find.byKey(const Key('station-submit'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('the grammar station shows its unit and section', (tester) async {
    await tester.pumpWidget(_host(GrammarStation(
      payload: _grammar, onSubmit: (_) async => _ok(), onDone: () {},
    )));
    expect(find.textContaining('15'), findsWidgets);
    expect(find.text('Present perfect'), findsOneWidget);
    expect(find.text('Use have plus the past participle.'), findsOneWidget);
  });

  testWidgets('submitting sends the picked indexes in order', (tester) async {
    List<int>? sent;
    await tester.pumpWidget(_host(GrammarStation(
      payload: _grammar,
      onSubmit: (answers) async { sent = answers; return _ok(); },
      onDone: () {},
    )));
    await tester.tap(find.byKey(const Key('check-q0-opt2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(sent, [2]);
  });

  testWidgets('a submitted station reports the score and then finishes', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(GrammarStation(
      payload: _grammar, onSubmit: (_) async => _ok(), onDone: () => done++,
    )));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('station-score')), findsOneWidget);

    await tester.tap(find.byKey(const Key('station-continue')));
    await tester.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('a failed submission surfaces a retry instead of losing the answers', (tester) async {
    await tester.pumpWidget(_host(GrammarStation(
      payload: _grammar,
      onSubmit: (_) async => throw Exception('offline'),
      onDone: () {},
    )));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('station-error')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('station-submit'))).onPressed,
        isNotNull, 'the learner must be able to try again');
  });

  testWidgets('the listening station hides the text until the clip is played', (tester) async {
    await tester.pumpWidget(_host(ListeningStation(
      payload: _listening, onSubmit: (_) async => _ok(), onDone: () {},
    )));
    expect(find.text('She is waiting outside.'), findsNothing);
    expect(find.byKey(const Key('clip-play-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clip-play-0')));
    await tester.pumpAndSettle();
    expect(find.text('She is waiting outside.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/pack_stations_test.dart`
Expected: FAIL — URIs don't exist

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/pages/learning/daily/widgets/word_card.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One new word: headword, definition, example. The audio affordance is a
/// callback so wave 1 can render text-only clips while TTS is wired.
class WordCard extends StatelessWidget {
  final PackWord word;
  final VoidCallback? onSpeak;

  const WordCard({super.key, required this.word, this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(word.word, style: theme.textTheme.headlineSmall)),
            if (onSpeak != null)
              IconButton(
                key: const Key('word-speak'),
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up),
                tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(word.definition, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Text(
          word.example,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/stations/station_scaffold.dart
// (created here, used by all three stations in this task)
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/check_question.dart';

typedef SubmitAnswers = Future<StationResult> Function(List<int> answers);

/// The teach-then-check body shared by the vocabulary, grammar, listening and
/// wrap stations. Holds the answer state, the submit lifecycle and the error
/// path in ONE place so four stations cannot drift apart.
class CheckSequence extends StatefulWidget {
  final List<PackCheck> checks;
  final Widget? header;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const CheckSequence({
    super.key,
    required this.checks,
    required this.onSubmit,
    required this.onDone,
    this.header,
  });

  @override
  State<CheckSequence> createState() => _CheckSequenceState();
}

class _CheckSequenceState extends State<CheckSequence> {
  late final List<int?> _answers = List<int?>.filled(widget.checks.length, null);
  StationResult? _result;
  bool _submitting = false;
  String? _error;

  bool get _allAnswered => !_answers.contains(null);

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.onSubmit(_answers.map((a) => a ?? -1).toList());
      if (mounted) setState(() => _result = result);
    } catch (_) {
      // Keep the answers on screen: making the learner re-enter them after a
      // dropped connection is how a session gets abandoned.
      if (mounted) setState(() => _error = 'retry');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.header != null) widget.header!,
        if (widget.header != null) const SizedBox(height: 24),
        ...List.generate(widget.checks.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: CheckQuestion(
              check: widget.checks[i],
              index: i,
              selected: _answers[i],
              correctIndex: null,
              onSelect: (o) => setState(() => _answers[i] = o),
            ),
          );
        }),
        if (_result != null)
          Padding(
            key: const Key('station-score'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.dailyScore(_result!.score, _result!.total),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        if (_error != null)
          Padding(
            key: const Key('station-error'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.packSubmitFailed,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (_result == null)
          FilledButton(
            key: const Key('station-submit'),
            onPressed: (!_allAnswered || _submitting) ? null : _submit,
            child: Text(l10n.dailyCheck),
          )
        else
          FilledButton(
            key: const Key('station-continue'),
            onPressed: widget.onDone,
            child: Text(l10n.packContinue),
          ),
      ],
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/stations/vocab_station.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/word_card.dart';

/// Five new words, walked one at a time, then checked. The words are taught
/// before any question is shown — a check on a word the learner has not met is
/// a quiz, not a lesson.
class VocabStation extends StatefulWidget {
  final VocabPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const VocabStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<VocabStation> createState() => _VocabStationState();
}

class _VocabStationState extends State<VocabStation> {
  int _wordIndex = 0;

  bool get _taught => _wordIndex >= widget.payload.words.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_taught) {
      return CheckSequence(
        checks: widget.payload.checks,
        onSubmit: widget.onSubmit,
        onDone: widget.onDone,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.packWordProgress(_wordIndex + 1, widget.payload.words.length),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 16),
          Expanded(child: WordCard(word: widget.payload.words[_wordIndex])),
          FilledButton(
            key: const Key('word-next'),
            onPressed: () => setState(() => _wordIndex += 1),
            child: Text(l10n.packGotIt),
          ),
        ],
      ),
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/stations/grammar_station.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One grammar unit from the learner's own position in the syllabus.
class GrammarStation extends StatelessWidget {
  final GrammarPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const GrammarStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return CheckSequence(
      checks: payload.checks,
      onSubmit: onSubmit,
      onDone: onDone,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(payload.section, style: theme.textTheme.labelMedium),
          Text(
            l10n.packGrammarUnit(payload.unit),
            style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(payload.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(payload.explanation, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          ...payload.examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  e,
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              )),
        ],
      ),
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/stations/listening_station.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';

/// Two clips from the week's theme. Wave 1 renders the text on demand rather
/// than streaming audio (spec deferral) — the reveal still has to be an action,
/// or it is a reading exercise.
class ListeningStation extends StatefulWidget {
  final ListeningPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const ListeningStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<ListeningStation> createState() => _ListeningStationState();
}

class _ListeningStationState extends State<ListeningStation> {
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return CheckSequence(
      checks: widget.payload.clips
          .map((c) => PackCheck(
                prompt: l10n.packListeningPrompt,
                options: [c.word, c.text.split(' ').first, c.text.split(' ').last],
              ))
          .toList(),
      onSubmit: widget.onSubmit,
      onDone: widget.onDone,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.payload.clips.length, (i) {
          final clip = widget.payload.clips[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  key: Key('clip-play-$i'),
                  onPressed: () => setState(() => _revealed.add(i)),
                  icon: const Icon(Icons.volume_up),
                  label: Text(l10n.packPlayClip(i + 1)),
                ),
                if (_revealed.contains(i))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(clip.text, style: theme.textTheme.bodyLarge),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
```

Add the six new ARB keys used above to `lib/l10n/app_en.arb` (Task 10 translates them):

```json
  "packContinue": "Continue",
  "@packContinue": { "description": "Advances from a finished station to the next one" },
  "packGotIt": "Got it",
  "@packGotIt": { "description": "Advances past one taught vocabulary word" },
  "packSubmitFailed": "Couldn't save that — check your connection and try again.",
  "@packSubmitFailed": { "description": "Shown when a station submission fails; the answers stay on screen" },
  "packWordProgress": "Word {current} of {total}",
  "@packWordProgress": { "description": "Position within the day's new words", "placeholders": { "current": { "type": "int" }, "total": { "type": "int" } } },
  "packGrammarUnit": "Unit {unit}",
  "@packGrammarUnit": { "description": "Grammar syllabus unit number", "placeholders": { "unit": { "type": "int" } } },
  "packListeningPrompt": "Which word did you hear?",
  "@packListeningPrompt": { "description": "Question prompt for a listening clip" },
  "packPlayClip": "Play clip {number}",
  "@packPlayClip": { "description": "Button that plays one listening clip", "placeholders": { "number": { "type": "int" } } }
```

- [ ] **Step 4: Regenerate localisations and run the test**

Run: `cd bananatalk_app && flutter gen-l10n && flutter test test/learning/pack_stations_test.dart`
Expected: PASS, 8 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/learning/daily/widgets/word_card.dart \
        bananatalk_app/lib/pages/learning/daily/stations/ \
        bananatalk_app/lib/l10n/app_en.arb \
        bananatalk_app/test/learning/pack_stations_test.dart
git commit -m "feat(daily-pack): vocabulary, grammar and listening stations"
```

---

### Task 6: Review, wrap and translate stations

**Files:**
- Create: `bananatalk_app/lib/pages/learning/daily/stations/review_station.dart`
- Create: `bananatalk_app/lib/pages/learning/daily/stations/wrap_station.dart`
- Create: `bananatalk_app/lib/pages/learning/daily/stations/translate_station.dart`
- Test: `bananatalk_app/test/learning/pack_stations_review_test.dart`

**Interfaces:**
- Consumes: `ReviewPayload`, `WrapPayload`, `TranslatePayload` (Task 1); `CheckSequence` (Task 5).
- Produces:
  - `ReviewStation({required ReviewPayload payload, required Future<StationResult> Function(List<Map<String, dynamic>>) onSubmit, required VoidCallback onDone})` — note the **review-specific submit signature**, which sends `[{id, correct}]` rather than answer indexes
  - `WrapStation({required WrapPayload payload, required SubmitAnswers onSubmit, required VoidCallback onDone})`
  - `TranslateStation({required TranslatePayload payload, required Future<StationResult> Function(String) onSubmit, required VoidCallback onDone})`

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/pack_stations_review_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/review_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/translate_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/wrap_station.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

const _review = ReviewPayload(words: [
  ReviewWord(id: 'v1', word: 'reluctant', translation: 'unwilling', srsLevel: 2),
  ReviewWord(id: 'v2', word: 'thorough', translation: 'complete', srsLevel: 1),
]);

StationResult _ok() => const StationResult(score: 1, total: 2, xpAwarded: 5);

void main() {
  testWidgets('the review station shows one word at a time, answer hidden', (tester) async {
    await tester.pumpWidget(_host(ReviewStation(
      payload: _review, onSubmit: (_) async => _ok(), onDone: () {},
    )));
    expect(find.text('reluctant'), findsOneWidget);
    expect(find.text('unwilling'), findsNothing, reason: 'recall first, then reveal');
  });

  testWidgets('revealing shows the translation and the two verdict buttons', (tester) async {
    await tester.pumpWidget(_host(ReviewStation(
      payload: _review, onSubmit: (_) async => _ok(), onDone: () {},
    )));
    await tester.tap(find.byKey(const Key('review-reveal')));
    await tester.pumpAndSettle();
    expect(find.text('unwilling'), findsOneWidget);
    expect(find.byKey(const Key('review-knew')), findsOneWidget);
    expect(find.byKey(const Key('review-missed')), findsOneWidget);
  });

  testWidgets('each verdict is sent with its word id', (tester) async {
    List<Map<String, dynamic>>? sent;
    await tester.pumpWidget(_host(ReviewStation(
      payload: _review,
      onSubmit: (reviews) async { sent = reviews; return _ok(); },
      onDone: () {},
    )));
    await tester.tap(find.byKey(const Key('review-reveal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-knew')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-reveal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-missed')));
    await tester.pumpAndSettle();
    expect(sent, [
      {'id': 'v1', 'correct': true},
      {'id': 'v2', 'correct': false},
    ]);
  });

  testWidgets('the wrap station renders the whole week of questions', (tester) async {
    await tester.pumpWidget(_host(WrapStation(
      payload: const WrapPayload(questions: [
        PackCheck(prompt: 'Which word means "a strong wish"?', options: ['ambition', 'salary']),
        PackCheck(prompt: 'Which word means "complete"?', options: ['thorough', 'reluctant']),
      ]),
      onSubmit: (_) async => _ok(),
      onDone: () {},
    )));
    expect(find.text('Which word means "a strong wish"?'), findsOneWidget);
    expect(find.text('Which word means "complete"?'), findsOneWidget);
  });

  testWidgets('the translate station sends the typed sentence', (tester) async {
    String? sent;
    await tester.pumpWidget(_host(TranslateStation(
      payload: const TranslatePayload(prompt: 'Her ambition showed.'),
      onSubmit: (text) async { sent = text; return _ok(); },
      onDone: () {},
    )));
    await tester.enterText(find.byKey(const Key('translate-input')), 'Sa mostrado su ambicion.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(sent, 'Sa mostrado su ambicion.');
  });

  testWidgets('translate submit is disabled while the field is empty', (tester) async {
    await tester.pumpWidget(_host(TranslateStation(
      payload: const TranslatePayload(prompt: 'Her ambition showed.'),
      onSubmit: (_) async => _ok(),
      onDone: () {},
    )));
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('station-submit'))).onPressed,
      isNull,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/pack_stations_review_test.dart`
Expected: FAIL — URIs don't exist

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/pages/learning/daily/stations/review_station.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';

/// Due words from the learner's own SRS backlog. Recall first, reveal second,
/// verdict third — revealing before the learner tries is not a review.
class ReviewStation extends StatefulWidget {
  final ReviewPayload payload;
  final Future<StationResult> Function(List<Map<String, dynamic>>) onSubmit;
  final VoidCallback onDone;

  const ReviewStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<ReviewStation> createState() => _ReviewStationState();
}

class _ReviewStationState extends State<ReviewStation> {
  final List<Map<String, dynamic>> _verdicts = [];
  int _index = 0;
  bool _revealed = false;
  StationResult? _result;
  String? _error;

  Future<void> _record(bool correct) async {
    _verdicts.add({'id': widget.payload.words[_index].id, 'correct': correct});
    if (_index + 1 < widget.payload.words.length) {
      setState(() {
        _index += 1;
        _revealed = false;
      });
      return;
    }
    try {
      final result = await widget.onSubmit(_verdicts);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _error = 'retry');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_result != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.dailyScore(_result!.score, _result!.total),
              key: const Key('station-score'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('station-continue'),
              onPressed: widget.onDone,
              child: Text(l10n.packContinue),
            ),
          ],
        ),
      );
    }

    final word = widget.payload.words[_index];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.packWordProgress(_index + 1, widget.payload.words.length),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 32),
          Center(child: Text(word.word, style: theme.textTheme.headlineMedium)),
          const SizedBox(height: 24),
          if (_revealed)
            Center(child: Text(word.translation, style: theme.textTheme.titleLarge)),
          if (_error != null)
            Padding(
              key: const Key('station-error'),
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.packSubmitFailed,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const Spacer(),
          if (!_revealed)
            FilledButton(
              key: const Key('review-reveal'),
              onPressed: () => setState(() => _revealed = true),
              child: Text(l10n.packReveal),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('review-missed'),
                    onPressed: () => _record(false),
                    child: Text(l10n.packMissed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('review-knew'),
                    onPressed: () => _record(true),
                    child: Text(l10n.packKnewIt),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/stations/wrap_station.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';

/// Friday's quiz over the whole week's theme. Formative, never a gate.
class WrapStation extends StatelessWidget {
  final WrapPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const WrapStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) => CheckSequence(
        checks: payload.questions,
        onSubmit: onSubmit,
        onDone: onDone,
      );
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/stations/translate_station.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';

/// The weekend productive station: type the sentence in your target language.
/// Typed input only in wave 1 — speech is a deferred spec question.
class TranslateStation extends StatefulWidget {
  final TranslatePayload payload;
  final Future<StationResult> Function(String) onSubmit;
  final VoidCallback onDone;

  const TranslateStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<TranslateStation> createState() => _TranslateStationState();
}

class _TranslateStationState extends State<TranslateStation> {
  final _controller = TextEditingController();
  StationResult? _result;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.onSubmit(_controller.text.trim());
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _error = 'retry');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canSubmit = _controller.text.trim().isNotEmpty && !_submitting;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.packTranslatePrompt, style: theme.textTheme.labelMedium),
        const SizedBox(height: 12),
        Text(widget.payload.prompt, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        TextField(
          key: const Key('translate-input'),
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n.packTranslateHint,
          ),
        ),
        const SizedBox(height: 16),
        if (_result != null)
          Padding(
            key: const Key('station-score'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.dailyScore(_result!.score, _result!.total),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        if (_error != null)
          Padding(
            key: const Key('station-error'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.packSubmitFailed,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (_result == null)
          FilledButton(
            key: const Key('station-submit'),
            onPressed: canSubmit ? _submit : null,
            child: Text(l10n.dailyCheck),
          )
        else
          FilledButton(
            key: const Key('station-continue'),
            onPressed: widget.onDone,
            child: Text(l10n.packContinue),
          ),
      ],
    );
  }
}
```

Add to `lib/l10n/app_en.arb`:

```json
  "packReveal": "Show answer",
  "@packReveal": { "description": "Reveals a review word's translation" },
  "packKnewIt": "I knew it",
  "@packKnewIt": { "description": "Review verdict: recalled correctly" },
  "packMissed": "Missed it",
  "@packMissed": { "description": "Review verdict: did not recall" },
  "packTranslatePrompt": "Translate this sentence",
  "@packTranslatePrompt": { "description": "Label above the weekend translate station's sentence" },
  "packTranslateHint": "Type your translation",
  "@packTranslateHint": { "description": "Placeholder in the translate station's input" }
```

- [ ] **Step 4: Regenerate localisations and run the test**

Run: `cd bananatalk_app && flutter gen-l10n && flutter test test/learning/pack_stations_review_test.dart`
Expected: PASS, 6 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/learning/daily/stations/ bananatalk_app/lib/l10n/app_en.arb \
        bananatalk_app/test/learning/pack_stations_review_test.dart
git commit -m "feat(daily-pack): review, wrap and translate stations"
```

---

### Task 7: The flow host and completion sheet

**Files:**
- Create: `bananatalk_app/lib/pages/learning/daily/daily_pack_flow.dart`
- Create: `bananatalk_app/lib/pages/learning/daily/widgets/day_complete_sheet.dart`
- Test: `bananatalk_app/test/learning/daily_pack_flow_test.dart`

**Interfaces:**
- Consumes: every station (Tasks 5, 6), `StationRail` (Task 4), `DailyPack` (Task 1).
- Produces: `DailyPackFlow({required DailyPack pack, int initialIndex = 0, Future<StationResult> Function(String station, {List<int> answers, List<Map<String, dynamic>> reviews})? submit, VoidCallback? onExit})`.

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/daily_pack_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_flow.dart';

DailyPack _pack({bool grammarDone = false}) => DailyPack(
      needsLanguage: false,
      dateKey: '2026-09-07',
      weekKey: '2026-W37',
      dayInWeek: 1,
      theme: const PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
      stations: [
        PackStation(
          kind: 'grammar',
          status: grammarDone ? StationStatus.done : StationStatus.todo,
          payload: const GrammarPayload(
            itemId: 'g1', unit: 1, section: 'Present', title: 'am / is / are',
            explanation: 'Match the verb to the subject.',
            examples: ['I am here.'],
            checks: [PackCheck(prompt: 'She ___ my sister.', options: ['am', 'is', 'are'])],
          ),
        ),
        const PackStation(kind: 'review', status: StationStatus.empty),
      ],
    );

Widget _host(DailyPack pack, {Future<StationResult> Function(String, {List<int> answers, List<Map<String, dynamic>> reviews})? submit}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DailyPackFlow(pack: pack, submit: submit),
    );

void main() {
  testWidgets('opens on the first outstanding station', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.text('am / is / are'), findsOneWidget);
  });

  testWidgets('shows the theme and the rail', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.text('Work & careers'), findsOneWidget);
    expect(find.byKey(const Key('rail-dot-0-current')), findsOneWidget);
  });

  testWidgets('an empty station is skipped rather than shown as a step', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    // Review is empty; the flow must not park the learner on an empty page.
    expect(find.byKey(const Key('review-reveal')), findsNothing);
  });

  testWidgets('a station submission routes to the right station kind', (tester) async {
    String? submitted;
    await tester.pumpWidget(_host(
      _pack(),
      submit: (station, {answers = const [], reviews = const []}) async {
        submitted = station;
        return const StationResult(score: 1, total: 1, packComplete: false);
      },
    ));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(submitted, 'grammar');
  });

  testWidgets('completing the last station shows the completion sheet', (tester) async {
    await tester.pumpWidget(_host(
      _pack(),
      submit: (station, {answers = const [], reviews = const []}) async =>
          const StationResult(score: 1, total: 1, xpAwarded: 10, streak: 3, packComplete: true),
    ));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-complete-sheet')), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets, reason: 'the streak is the reward');
  });

  testWidgets('the close button exits the flow', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.byKey(const Key('pack-close')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/daily_pack_flow_test.dart`
Expected: FAIL — URI doesn't exist

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/pages/learning/daily/widgets/day_complete_sheet.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// The reward moment. The streak and the XP are the whole point of finishing,
/// and the old screen showed them as one line of body text.
class DayCompleteSheet extends StatelessWidget {
  final int? streak;
  final int xpAwarded;
  final String? themeTopic;
  final VoidCallback onClose;

  const DayCompleteSheet({
    super.key,
    required this.onClose,
    this.streak,
    this.xpAwarded = 0,
    this.themeTopic,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      key: const Key('day-complete-sheet'),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          if (streak != null)
            Text(l10n.dailyStreakDays(streak!), style: theme.textTheme.headlineSmall),
          if (xpAwarded > 0)
            Text(l10n.dailyXpEarned(xpAwarded), style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (themeTopic != null)
            Text(
              l10n.packTomorrowTeaser(themeTopic!),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('day-complete-close'),
            onPressed: onClose,
            child: Text(l10n.packDone),
          ),
        ],
      ),
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/daily_pack_flow.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/grammar_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/listening_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/review_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/translate_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/vocab_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/wrap_station.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/day_complete_sheet.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/station_rail.dart';
import 'package:bananatalk_app/services/learning_service.dart';

typedef SubmitStation = Future<StationResult> Function(
  String station, {
  List<int> answers,
  List<Map<String, dynamic>> reviews,
});

/// The full-screen day. One station at a time, rail on top, no bottom nav.
///
/// Each station commits on its own, so exiting mid-flow keeps finished work:
/// 21 of the 23 learners who ever opened the old drop never came back, and
/// losing partial progress is one fewer reason to return.
class DailyPackFlow extends StatefulWidget {
  final DailyPack pack;
  final int initialIndex;
  final SubmitStation? submit;
  final VoidCallback? onExit;

  const DailyPackFlow({
    super.key,
    required this.pack,
    this.initialIndex = 0,
    this.submit,
    this.onExit,
  });

  @override
  State<DailyPackFlow> createState() => _DailyPackFlowState();
}

class _DailyPackFlowState extends State<DailyPackFlow> {
  late List<PackStation> _outstanding;
  late int _index;
  bool _finished = false;
  StationResult? _last;

  @override
  void initState() {
    super.initState();
    // Empty stations are already satisfied; parking the learner on an empty
    // page would read as a broken step.
    _outstanding = widget.pack.stations.where((s) => s.isOutstanding).toList();
    _index = widget.initialIndex.clamp(0, _outstanding.isEmpty ? 0 : _outstanding.length - 1);
  }

  Future<StationResult> _submit(
    String station, {
    List<int> answers = const [],
    List<Map<String, dynamic>> reviews = const [],
  }) async {
    final fn = widget.submit ??
        (String s, {List<int> answers = const [], List<Map<String, dynamic>> reviews = const []}) =>
            LearningService.completeStation(s, answers: answers, reviews: reviews);
    final result = await fn(station, answers: answers, reviews: reviews);
    _last = result;
    return result;
  }

  void _advance() {
    if (_index + 1 < _outstanding.length && !(_last?.packComplete ?? false)) {
      setState(() => _index += 1);
      return;
    }
    setState(() => _finished = true);
  }

  Widget _stationBody(PackStation station) {
    switch (station.kind) {
      case 'vocabulary':
        return VocabStation(
          payload: station.payload as VocabPayload,
          onSubmit: (a) => _submit('vocabulary', answers: a),
          onDone: _advance,
        );
      case 'grammar':
        return GrammarStation(
          payload: station.payload as GrammarPayload,
          onSubmit: (a) => _submit('grammar', answers: a),
          onDone: _advance,
        );
      case 'listening':
        return ListeningStation(
          payload: station.payload as ListeningPayload,
          onSubmit: (a) => _submit('listening', answers: a),
          onDone: _advance,
        );
      case 'review':
        return ReviewStation(
          payload: station.payload as ReviewPayload,
          onSubmit: (r) => _submit('review', reviews: r),
          onDone: _advance,
        );
      case 'wrap':
        return WrapStation(
          payload: station.payload as WrapPayload,
          onSubmit: (a) => _submit('wrap', answers: a),
          onDone: _advance,
        );
      case 'translate':
        return TranslateStation(
          payload: station.payload as TranslatePayload,
          onSubmit: (text) => _submit('translate', answers: const [1]),
          onDone: _advance,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _exit() {
    if (widget.onExit != null) {
      widget.onExit!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_finished || _outstanding.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: DayCompleteSheet(
              streak: _last?.streak,
              xpAwarded: _last?.xpAwarded ?? 0,
              themeTopic: widget.pack.theme?.topic,
              onClose: _exit,
            ),
          ),
        ),
      );
    }

    final station = _outstanding[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.theme?.topic ?? l10n.today),
        leading: IconButton(
          key: const Key('pack-close'),
          icon: const Icon(Icons.close),
          onPressed: _exit,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: StationRail(stations: widget.pack.stations, currentIndex: _index),
            ),
            Expanded(child: _stationBody(station)),
          ],
        ),
      ),
    );
  }
}
```

Add to `lib/l10n/app_en.arb`:

```json
  "packDone": "Done",
  "@packDone": { "description": "Closes the day-complete sheet" },
  "packTomorrowTeaser": "Tomorrow: more from {topic}",
  "@packTomorrowTeaser": { "description": "Teases the next day inside the completion sheet", "placeholders": { "topic": { "type": "String" } } }
```

- [ ] **Step 4: Regenerate localisations and run the test**

Run: `cd bananatalk_app && flutter gen-l10n && flutter test test/learning/daily_pack_flow_test.dart`
Expected: PASS, 6 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/learning/daily/daily_pack_flow.dart \
        bananatalk_app/lib/pages/learning/daily/widgets/day_complete_sheet.dart \
        bananatalk_app/lib/l10n/app_en.arb \
        bananatalk_app/test/learning/daily_pack_flow_test.dart
git commit -m "feat(daily-pack): full-screen station flow and completion moment"
```

---

### Task 8: Hero card, mastery strip and mastery screen

**Files:**
- Create: `bananatalk_app/lib/pages/learning/daily/daily_pack_hero_card.dart`
- Create: `bananatalk_app/lib/pages/learning/progress/mastery_screen.dart`
- Create: `bananatalk_app/lib/pages/learning/progress/widgets/mastery_bar.dart`
- Create: `bananatalk_app/lib/pages/learning/progress/widgets/streak_calendar.dart`
- Modify: `bananatalk_app/lib/models/learning/daily_pack_model.dart` (add `MasterySummary`)
- Modify: `bananatalk_app/lib/services/learning_service.dart` (add `getMastery`)
- Modify: `bananatalk_app/lib/providers/provider_root/learning/daily_pack_providers.dart` (add `masteryProvider`)
- Test: `bananatalk_app/test/learning/daily_pack_hero_card_test.dart`, `bananatalk_app/test/learning/mastery_screen_test.dart`

**Interfaces:**
- Consumes: `DailyPack` (Task 1), `Endpoints.masteryURL` (Task 2).
- Produces:
  - `MasterySummary` with `level`, `book`, `VocabMastery vocabulary {mastered, learning, fresh, due}`, `GrammarMastery grammar {mastered, total, sections}`, `SkillAccuracy listening/translate {accuracy, samples}`, `List<String> consistencyDays`
  - `DailyPackHeroCard({required DailyPack pack, MasterySummary? mastery, required VoidCallback onOpen, required VoidCallback onPickLanguage, required VoidCallback onOpenProgress})`
  - `MasteryScreen({MasterySummary? mastery})`

- [ ] **Step 1: Write the failing tests**

```dart
// bananatalk_app/test/learning/daily_pack_hero_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_hero_card.dart';

DailyPack _pack({
  bool needsLanguage = false,
  bool complete = false,
  List<PackStation>? stations,
  PackTheme? theme = const PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
}) =>
    DailyPack(
      needsLanguage: needsLanguage,
      dateKey: '2026-09-07',
      weekKey: '2026-W37',
      dayInWeek: 2,
      theme: theme,
      packComplete: complete,
      stations: stations ??
          const [
            PackStation(kind: 'vocabulary', status: StationStatus.done, score: 5),
            PackStation(kind: 'grammar', status: StationStatus.done, score: 3),
            PackStation(kind: 'listening', status: StationStatus.todo),
            PackStation(kind: 'review', status: StationStatus.todo),
          ],
    );

const _mastery = MasterySummary(
  level: 'A2',
  book: 'elementary',
  vocabulary: VocabMastery(mastered: 84, learning: 31, fresh: 4, due: 12),
  grammar: GrammarProgress(mastered: 9, total: 115, sections: []),
  listening: SkillAccuracy(accuracy: 0.71, samples: 14),
  translate: SkillAccuracy(accuracy: null, samples: 0),
  consistencyDays: ['2026-09-06', '2026-09-07'],
);

Widget _host(DailyPack pack, {MasterySummary? mastery, VoidCallback? onOpen, VoidCallback? onProgress}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DailyPackHeroCard(
          pack: pack,
          mastery: mastery,
          onOpen: onOpen ?? () {},
          onPickLanguage: () {},
          onOpenProgress: onProgress ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('shows the theme and the server-side progress', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.text('Work & careers'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
  });

  testWidgets('the call to action names the next station, not a generic Open', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.byKey(const Key('hero-cta')), findsOneWidget);
    expect(find.textContaining('Listening'), findsWidgets);
  });

  testWidgets('tapping the CTA opens the flow', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_host(_pack(), onOpen: () => opened++));
    await tester.tap(find.byKey(const Key('hero-cta')));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('a finished day is a satisfied state, not a dead card', (tester) async {
    await tester.pumpWidget(_host(_pack(
      complete: true,
      stations: const [
        PackStation(kind: 'vocabulary', status: StationStatus.done, score: 5),
        PackStation(kind: 'grammar', status: StationStatus.done, score: 3),
      ],
    )));
    expect(find.byKey(const Key('hero-done')), findsOneWidget);
  });

  testWidgets('the mastery strip states mastered and due counts', (tester) async {
    await tester.pumpWidget(_host(_pack(), mastery: _mastery));
    expect(find.textContaining('84'), findsWidgets);
    expect(find.textContaining('12'), findsWidgets);
    expect(find.textContaining('115'), findsWidgets);
  });

  testWidgets('tapping the strip opens the progress screen', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_host(_pack(), mastery: _mastery, onProgress: () => opened++));
    await tester.tap(find.byKey(const Key('hero-progress-strip')));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('no mastery data yet hides the strip instead of showing zeroes', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.byKey(const Key('hero-progress-strip')), findsNothing);
  });

  testWidgets('needsLanguage asks the question instead of rendering a pack', (tester) async {
    await tester.pumpWidget(_host(_pack(needsLanguage: true)));
    expect(find.byKey(const Key('today-pick-language')), findsOneWidget);
  });

  testWidgets('no theme yet explains the empty day', (tester) async {
    await tester.pumpWidget(_host(_pack(theme: null, stations: const [])));
    expect(find.byKey(const Key('today-empty')), findsOneWidget);
  });
}
```

```dart
// bananatalk_app/test/learning/mastery_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/progress/mastery_screen.dart';

const _mastery = MasterySummary(
  level: 'A2',
  book: 'elementary',
  vocabulary: VocabMastery(mastered: 84, learning: 31, fresh: 4, due: 12),
  grammar: GrammarProgress(mastered: 9, total: 115, sections: [
    GrammarSection(section: 'Present', mastered: 9, total: 9),
    GrammarSection(section: 'Past', mastered: 0, total: 5),
  ]),
  listening: SkillAccuracy(accuracy: 0.71, samples: 14),
  translate: SkillAccuracy(accuracy: null, samples: 0),
  consistencyDays: ['2026-09-06', '2026-09-07'],
);

Widget _host(MasterySummary? m) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MasteryScreen(mastery: m),
    );

void main() {
  testWidgets('renders a bar per skill', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.byKey(const Key('mastery-vocabulary')), findsOneWidget);
    expect(find.byKey(const Key('mastery-grammar')), findsOneWidget);
    expect(find.byKey(const Key('mastery-listening')), findsOneWidget);
  });

  testWidgets('the level badge offers a retake and claims no certification', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.byKey(const Key('mastery-level-retake')), findsOneWidget);
    expect(find.textContaining('certif'), findsNothing);
  });

  testWidgets('grammar breaks down by section', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
  });

  testWidgets('due words are a call to action into review', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.byKey(const Key('mastery-due-cta')), findsOneWidget);
  });

  testWidgets('a skill with no samples reads as not started, not 0%', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    final translate = find.byKey(const Key('mastery-translate'));
    expect(translate, findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('a learner with no data sees an empty state, not a crash', (tester) async {
    await tester.pumpWidget(_host(null));
    expect(find.byKey(const Key('mastery-empty')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd bananatalk_app && flutter test test/learning/daily_pack_hero_card_test.dart test/learning/mastery_screen_test.dart`
Expected: FAIL — URIs don't exist

- [ ] **Step 3: Write minimal implementation**

Add the mastery models to `lib/models/learning/daily_pack_model.dart`:

```dart
class VocabMastery {
  final int mastered;
  final int learning;
  final int fresh;
  final int due;

  const VocabMastery({
    required this.mastered,
    required this.learning,
    required this.fresh,
    required this.due,
  });

  int get total => mastered + learning + fresh;

  factory VocabMastery.fromJson(Map<String, dynamic> json) => VocabMastery(
        mastered: (json['mastered'] as num?)?.toInt() ?? 0,
        learning: (json['learning'] as num?)?.toInt() ?? 0,
        fresh: (json['fresh'] as num?)?.toInt() ?? 0,
        due: (json['due'] as num?)?.toInt() ?? 0,
      );
}

class GrammarSection {
  final String section;
  final int mastered;
  final int total;

  const GrammarSection({
    required this.section,
    required this.mastered,
    required this.total,
  });

  factory GrammarSection.fromJson(Map<String, dynamic> json) => GrammarSection(
        section: json['section'] as String? ?? '',
        mastered: (json['mastered'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

class GrammarProgress {
  final int mastered;
  final int total;
  final List<GrammarSection> sections;

  const GrammarProgress({
    required this.mastered,
    required this.total,
    required this.sections,
  });

  factory GrammarProgress.fromJson(Map<String, dynamic> json) => GrammarProgress(
        mastered: (json['mastered'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        sections: (json['sections'] as List? ?? const [])
            .map((e) => GrammarSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SkillAccuracy {
  /// Null means "not started" — distinct from 0.0, which means "tried and
  /// missed everything". Showing 0% to someone who never began is a lie.
  final double? accuracy;
  final int samples;

  const SkillAccuracy({required this.accuracy, required this.samples});

  factory SkillAccuracy.fromJson(Map<String, dynamic> json) => SkillAccuracy(
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        samples: (json['samples'] as num?)?.toInt() ?? 0,
      );
}

class MasterySummary {
  final String level;
  final String book;
  final VocabMastery vocabulary;
  final GrammarProgress grammar;
  final SkillAccuracy listening;
  final SkillAccuracy translate;
  final List<String> consistencyDays;

  const MasterySummary({
    required this.level,
    required this.book,
    required this.vocabulary,
    required this.grammar,
    required this.listening,
    required this.translate,
    this.consistencyDays = const [],
  });

  factory MasterySummary.fromJson(Map<String, dynamic> json) => MasterySummary(
        level: json['level'] as String? ?? '',
        book: json['book'] as String? ?? '',
        vocabulary:
            VocabMastery.fromJson((json['vocabulary'] as Map<String, dynamic>?) ?? const {}),
        grammar: GrammarProgress.fromJson((json['grammar'] as Map<String, dynamic>?) ?? const {}),
        listening: SkillAccuracy.fromJson((json['listening'] as Map<String, dynamic>?) ?? const {}),
        translate: SkillAccuracy.fromJson((json['translate'] as Map<String, dynamic>?) ?? const {}),
        consistencyDays:
            ((json['consistency'] as Map<String, dynamic>?)?['days'] as List? ?? const [])
                .map((e) => e.toString())
                .toList(),
      );
}
```

```dart
// bananatalk_app/lib/services/learning_service.dart — add
  /// Per-skill mastery summary.
  static Future<MasterySummary> getMastery() async {
    final token = await _getToken();
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.masteryURL}');
    final response = await http.get(url, headers: _headers(token));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return MasterySummary.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(_getErrorMessage(data, 'Mastery fetch failed'));
  }
```

```dart
// bananatalk_app/lib/providers/provider_root/learning/daily_pack_providers.dart — add
/// Per-skill mastery for the signed-in learner.
final masteryProvider = FutureProvider<MasterySummary>((ref) async {
  return LearningService.getMastery();
});
```

```dart
// bananatalk_app/lib/pages/learning/progress/widgets/mastery_bar.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One skill's progress: a bar plus the counts behind it. The caption carries
/// the real numbers, because a bar alone cannot be read precisely.
class MasteryBar extends StatelessWidget {
  final String label;
  final String caption;
  final double? fraction;
  final String? emptyLabel;

  const MasteryBar({
    super.key,
    required this.label,
    required this.caption,
    this.fraction,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notStarted = fraction == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: notStarted ? 0 : fraction!.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: context.dividerColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notStarted ? (emptyLabel ?? caption) : caption,
            style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/progress/widgets/streak_calendar.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// 30 dots: one per day, filled where the learner completed something.
class StreakCalendar extends StatelessWidget {
  final List<String> activeDays;
  final int days;

  const StreakCalendar({super.key, required this.activeDays, this.days = 30});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeDays.toSet();
    // Dates are derived from the newest active day so the grid needs no clock.
    final anchor = activeDays.isEmpty
        ? null
        : DateTime.parse('${activeDays.last}T00:00:00Z');

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(days, (i) {
        final key = anchor == null
            ? ''
            : anchor
                .subtract(Duration(days: days - 1 - i))
                .toIso8601String()
                .substring(0, 10);
        final on = active.contains(key);
        return Container(
          key: Key('streak-dot-$i'),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? theme.colorScheme.primary : context.dividerColor,
          ),
        );
      }),
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/progress/mastery_screen.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/progress/widgets/mastery_bar.dart';
import 'package:bananatalk_app/pages/learning/progress/widgets/streak_calendar.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Per-skill mastery, built only from data the learner actually generated.
///
/// The level badge says "your level", never a CEFR certification: eight
/// placement questions and some daily quizzes do not certify a level.
class MasteryScreen extends StatelessWidget {
  final MasterySummary? mastery;
  final VoidCallback? onRetakePlacement;
  final VoidCallback? onOpenReview;

  const MasteryScreen({
    super.key,
    this.mastery,
    this.onRetakePlacement,
    this.onOpenReview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final m = mastery;

    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.masteryTitle)),
        body: Center(
          child: Padding(
            key: const Key('mastery-empty'),
            padding: const EdgeInsets.all(32),
            child: Text(l10n.masteryEmpty, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.masteryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(m.level, style: theme.textTheme.headlineMedium),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.masteryYourLevel,
                  style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
                ),
              ),
              TextButton(
                key: const Key('mastery-level-retake'),
                onPressed: onRetakePlacement,
                child: Text(l10n.masteryRetake),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            key: const Key('mastery-vocabulary'),
            padding: EdgeInsets.zero,
            child: MasteryBar(
              label: l10n.masteryVocabulary,
              fraction: m.vocabulary.total == 0
                  ? null
                  : m.vocabulary.mastered / m.vocabulary.total,
              caption: l10n.masteryVocabularyCaption(
                m.vocabulary.mastered,
                m.vocabulary.learning,
                m.vocabulary.due,
              ),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          if (m.vocabulary.due > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FilledButton.tonal(
                key: const Key('mastery-due-cta'),
                onPressed: onOpenReview,
                child: Text(l10n.masteryDueCta(m.vocabulary.due)),
              ),
            ),
          Padding(
            key: const Key('mastery-grammar'),
            padding: EdgeInsets.zero,
            child: MasteryBar(
              label: l10n.masteryGrammar,
              fraction: m.grammar.total == 0 ? null : m.grammar.mastered / m.grammar.total,
              caption: l10n.masteryGrammarCaption(m.grammar.mastered, m.grammar.total),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          ...m.grammar.sections.map((s) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(s.section, style: theme.textTheme.bodyMedium)),
                    Text('${s.mastered}/${s.total}', style: theme.textTheme.bodySmall),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Padding(
            key: const Key('mastery-listening'),
            padding: EdgeInsets.zero,
            child: MasteryBar(
              label: l10n.masteryListening,
              fraction: m.listening.accuracy,
              caption: l10n.masteryAccuracyCaption(
                ((m.listening.accuracy ?? 0) * 100).round(),
                m.listening.samples,
              ),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          Padding(
            key: const Key('mastery-translate'),
            padding: EdgeInsets.zero,
            child: MasteryBar(
              label: l10n.masteryTranslate,
              fraction: m.translate.accuracy,
              caption: l10n.masteryAccuracyCaption(
                ((m.translate.accuracy ?? 0) * 100).round(),
                m.translate.samples,
              ),
              emptyLabel: l10n.masteryNotStarted,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.masteryConsistency, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          StreakCalendar(activeDays: m.consistencyDays),
        ],
      ),
    );
  }
}
```

```dart
// bananatalk_app/lib/pages/learning/daily/daily_pack_hero_card.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The Learn tab's daily entry point. Replaces TodaySection's two ListTiles.
///
/// The CTA names the NEXT station rather than saying "Open": a learner who can
/// see that only "Review, 3 left" stands between them and a finished day is
/// being given a reason, not a button.
class DailyPackHeroCard extends StatelessWidget {
  final DailyPack pack;
  final MasterySummary? mastery;
  final VoidCallback onOpen;
  final VoidCallback onPickLanguage;
  final VoidCallback onOpenProgress;

  const DailyPackHeroCard({
    super.key,
    required this.pack,
    required this.onOpen,
    required this.onPickLanguage,
    required this.onOpenProgress,
    this.mastery,
  });

  String _stationLabel(AppLocalizations l10n, String kind) {
    switch (kind) {
      case 'vocabulary':
        return l10n.packStationVocabulary;
      case 'grammar':
        return l10n.packStationGrammar;
      case 'listening':
        return l10n.packStationListening;
      case 'review':
        return l10n.packStationReview;
      case 'wrap':
        return l10n.packStationWrap;
      case 'translate':
        return l10n.packStationTranslate;
      default:
        return kind;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (pack.needsLanguage) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('today-pick-language'),
          onPressed: onPickLanguage,
          child: Text(l10n.todayPickLanguage),
        ),
      );
    }

    if (pack.theme == null && pack.stations.isEmpty) {
      return Padding(
        key: const Key('today-empty'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(l10n.todayEmpty, style: theme.textTheme.bodyMedium),
      );
    }

    final next = pack.nextStation;
    final m = mastery;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.tertiary.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pack.theme?.topic ?? l10n.today,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Text('${pack.doneCount}/${pack.stations.length}',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                if (pack.isLevelFallback)
                  Padding(
                    key: const Key('today-level-fallback'),
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.todayLevelFallback(pack.servedLevel!, pack.requestedLevel!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 16),
                if (next == null || pack.packComplete)
                  Row(
                    key: const Key('hero-done'),
                    children: [
                      Icon(Icons.check_circle, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.packDoneForToday)),
                    ],
                  )
                else
                  FilledButton(
                    key: const Key('hero-cta'),
                    onPressed: onOpen,
                    child: Text(l10n.packContinueTo(_stationLabel(l10n, next.kind))),
                  ),
              ],
            ),
          ),
          if (m != null)
            InkWell(
              key: const Key('hero-progress-strip'),
              onTap: onOpenProgress,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.masteryVocabularyCaption(
                              m.vocabulary.mastered,
                              m.vocabulary.learning,
                              m.vocabulary.due,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            l10n.masteryGrammarCaption(m.grammar.mastered, m.grammar.total),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

Add to `lib/l10n/app_en.arb`:

```json
  "packContinueTo": "Continue · {station}",
  "@packContinueTo": { "description": "Hero card CTA naming the next station", "placeholders": { "station": { "type": "String" } } },
  "packDoneForToday": "Done for today",
  "@packDoneForToday": { "description": "Hero card state when the day is finished" },
  "packStationVocabulary": "Vocabulary",
  "@packStationVocabulary": { "description": "Station name" },
  "packStationGrammar": "Grammar",
  "@packStationGrammar": { "description": "Station name" },
  "packStationListening": "Listening",
  "@packStationListening": { "description": "Station name" },
  "packStationReview": "Review",
  "@packStationReview": { "description": "Station name" },
  "packStationWrap": "Week quiz",
  "@packStationWrap": { "description": "Station name for Friday's theme wrap quiz" },
  "packStationTranslate": "Translate",
  "@packStationTranslate": { "description": "Station name for the weekend translation station" },
  "masteryTitle": "Your progress",
  "@masteryTitle": { "description": "Title of the mastery screen" },
  "masteryEmpty": "Finish a day of study and your progress will show up here.",
  "@masteryEmpty": { "description": "Mastery screen empty state" },
  "masteryYourLevel": "your level",
  "@masteryYourLevel": { "description": "Caption beside the level badge; deliberately not a CEFR certification claim" },
  "masteryRetake": "Retake",
  "@masteryRetake": { "description": "Retakes the placement test" },
  "masteryVocabulary": "Vocabulary",
  "@masteryVocabulary": { "description": "Mastery skill label" },
  "masteryGrammar": "Grammar",
  "@masteryGrammar": { "description": "Mastery skill label" },
  "masteryListening": "Listening",
  "@masteryListening": { "description": "Mastery skill label" },
  "masteryTranslate": "Translation",
  "@masteryTranslate": { "description": "Mastery skill label" },
  "masteryNotStarted": "Not started yet",
  "@masteryNotStarted": { "description": "Shown for a skill with no attempts, instead of 0%" },
  "masteryVocabularyCaption": "{mastered} mastered · {learning} learning · {due} due",
  "@masteryVocabularyCaption": { "description": "Vocabulary counts", "placeholders": { "mastered": { "type": "int" }, "learning": { "type": "int" }, "due": { "type": "int" } } },
  "masteryGrammarCaption": "Unit {mastered} of {total}",
  "@masteryGrammarCaption": { "description": "Grammar syllabus position", "placeholders": { "mastered": { "type": "int" }, "total": { "type": "int" } } },
  "masteryAccuracyCaption": "{percent}% over {samples} sessions",
  "@masteryAccuracyCaption": { "description": "Accuracy caption for listening and translation", "placeholders": { "percent": { "type": "int" }, "samples": { "type": "int" } } },
  "masteryConsistency": "Last 30 days",
  "@masteryConsistency": { "description": "Heading above the streak calendar" },
  "masteryDueCta": "Review {count} words now",
  "@masteryDueCta": { "description": "Opens the review station from the progress screen", "placeholders": { "count": { "type": "int" } } }
```

- [ ] **Step 4: Regenerate localisations and run the tests**

Run: `cd bananatalk_app && flutter gen-l10n && flutter test test/learning/daily_pack_hero_card_test.dart test/learning/mastery_screen_test.dart`
Expected: PASS, 15 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/learning/daily/daily_pack_hero_card.dart \
        bananatalk_app/lib/pages/learning/progress/ \
        bananatalk_app/lib/models/learning/daily_pack_model.dart \
        bananatalk_app/lib/services/learning_service.dart \
        bananatalk_app/lib/providers/provider_root/learning/daily_pack_providers.dart \
        bananatalk_app/lib/l10n/app_en.arb \
        bananatalk_app/test/learning/daily_pack_hero_card_test.dart \
        bananatalk_app/test/learning/mastery_screen_test.dart
git commit -m "feat(daily-pack): hero card, mastery strip and progress screen"
```

---

### Task 9: Placement screen

**Files:**
- Create: `bananatalk_app/lib/pages/learning/daily/placement/placement_screen.dart`
- Test: `bananatalk_app/test/learning/placement_screen_test.dart`

**Interfaces:**
- Consumes: `PackCheck` (Task 1), `CheckQuestion` (Task 3), `LearningService.getPlacement/submitPlacement` (Task 2).
- Produces: `PlacementScreen({Future<List<PackCheck>> Function()? load, Future<Map<String, dynamic>> Function(List<int>)? submit, VoidCallback? onFinished})`.

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/placement_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/placement/placement_screen.dart';

final _questions = List.generate(
  8,
  (i) => PackCheck(prompt: 'Question $i', options: const ['a', 'b', 'c']),
);

Widget _host({
  Future<List<PackCheck>> Function()? load,
  Future<Map<String, dynamic>> Function(List<int>)? submit,
  VoidCallback? onFinished,
}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PlacementScreen(
        load: load ?? () async => _questions,
        submit: submit ?? (_) async => {'level': 'A2', 'book': 'elementary', 'correct': 4},
        onFinished: onFinished,
      ),
    );

void main() {
  testWidgets('asks one question at a time', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('Question 0'), findsOneWidget);
    expect(find.text('Question 1'), findsNothing);
  });

  testWidgets('answering advances to the next question', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    expect(find.text('Question 1'), findsOneWidget);
  });

  testWidgets('can be skipped, which the server treats as no answers', (tester) async {
    List<int>? sent;
    await tester.pumpWidget(_host(submit: (a) async {
      sent = a;
      return {'level': 'A2', 'book': 'elementary', 'correct': 0};
    }));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('placement-skip')));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
  });

  testWidgets('answering every question submits them in order', (tester) async {
    List<int>? sent;
    await tester.pumpWidget(_host(submit: (a) async {
      sent = a;
      return {'level': 'B1', 'book': 'intermediate', 'correct': 6};
    }));
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(Key('check-q$i-opt2')));
      await tester.pumpAndSettle();
    }
    expect(sent, List.filled(8, 2));
  });

  testWidgets('the result names the level and offers to start', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('placement-skip')));
    await tester.pumpAndSettle();
    expect(find.textContaining('A2'), findsWidgets);
    expect(find.byKey(const Key('placement-start')), findsOneWidget);
  });

  testWidgets('a load failure offers a retry rather than a blank screen', (tester) async {
    await tester.pumpWidget(_host(load: () async => throw Exception('offline')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placement-error')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/placement_screen_test.dart`
Expected: FAIL — URI doesn't exist

- [ ] **Step 3: Write minimal implementation**

```dart
// bananatalk_app/lib/pages/learning/daily/placement/placement_screen.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/check_question.dart';
import 'package:bananatalk_app/services/learning_service.dart';

/// Eight questions, one screen each, to set a starting level.
///
/// 697 of 758 active learners have no level at all, so the pack is otherwise
/// guessing. Skipping is always allowed and the server falls back to its
/// default level — a forced test at the door costs more learners than a wrong
/// starting level does.
class PlacementScreen extends StatefulWidget {
  final Future<List<PackCheck>> Function()? load;
  final Future<Map<String, dynamic>> Function(List<int>)? submit;
  final VoidCallback? onFinished;

  const PlacementScreen({super.key, this.load, this.submit, this.onFinished});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  List<PackCheck>? _questions;
  final List<int> _answers = [];
  int _index = 0;
  Map<String, dynamic>? _result;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final loader = widget.load ?? LearningService.getPlacement;
      final questions = await loader();
      if (mounted) setState(() => _questions = questions);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _finish() async {
    try {
      final submitter = widget.submit ?? LearningService.submitPlacement;
      final result = await submitter(List<int>.from(_answers));
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _answer(int option) async {
    _answers.add(option);
    if (_index + 1 < (_questions?.length ?? 0)) {
      setState(() => _index += 1);
      return;
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_failed && _result == null && _questions == null) {
      return Scaffold(
        body: Center(
          child: Column(
            key: const Key('placement-error'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.packSubmitFailed, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() => _failed = false);
                  _loadQuestions();
                },
                child: Text(l10n.packContinue),
              ),
            ],
          ),
        ),
      );
    }

    if (_result != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_result!['level']}',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(l10n.placementResult, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('placement-start'),
                  onPressed: widget.onFinished ?? () => Navigator.of(context).maybePop(),
                  child: Text(l10n.placementStart),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final questions = _questions;
    if (questions == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.placementTitle),
        actions: [
          TextButton(
            key: const Key('placement-skip'),
            onPressed: _finish,
            child: Text(l10n.placementSkip),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.placementProgress(_index + 1, questions.length),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 20),
          CheckQuestion(
            check: questions[_index],
            index: _index,
            onSelect: _answer,
          ),
        ],
      ),
    );
  }
}
```

Add to `lib/l10n/app_en.arb`:

```json
  "placementTitle": "Find your level",
  "@placementTitle": { "description": "Title of the placement screen" },
  "placementSkip": "Skip",
  "@placementSkip": { "description": "Skips the placement test" },
  "placementProgress": "Question {current} of {total}",
  "@placementProgress": { "description": "Placement position", "placeholders": { "current": { "type": "int" }, "total": { "type": "int" } } },
  "placementResult": "We'll start you here. You can change it any time.",
  "@placementResult": { "description": "Explains the placement result without claiming certification" },
  "placementStart": "Start learning",
  "@placementStart": { "description": "Leaves placement and opens the pack" }
```

- [ ] **Step 4: Regenerate localisations and run the test**

Run: `cd bananatalk_app && flutter gen-l10n && flutter test test/learning/placement_screen_test.dart`
Expected: PASS, 6 tests

- [ ] **Step 5: Commit**

```bash
git add bananatalk_app/lib/pages/learning/daily/placement/ bananatalk_app/lib/l10n/app_en.arb \
        bananatalk_app/test/learning/placement_screen_test.dart
git commit -m "feat(daily-pack): placement screen"
```

---

### Task 10: Wire the Learn tab and retire the old widgets

**Files:**
- Modify: `bananatalk_app/lib/pages/learning/main/sections/learn_tab.dart:56-79` and line 94
- Delete: `bananatalk_app/lib/pages/learning/daily/widgets/today_section.dart`
- Delete: `bananatalk_app/lib/pages/learning/daily/daily_drop_screen.dart`
- Delete: `bananatalk_app/test/learning/today_section_test.dart`
- Delete: `bananatalk_app/test/learning/daily_drop_screen_test.dart`
- Test: `bananatalk_app/test/learning/learn_tab_pack_test.dart`

**Interfaces:**
- Consumes: `dailyPackProvider`, `masteryProvider` (Tasks 2, 8); `DailyPackHeroCard` (Task 8); `DailyPackFlow` (Task 7).
- Produces: nothing new — this is the integration point.

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/learn_tab_pack_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_hero_card.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';

final _pack = DailyPack(
  needsLanguage: false,
  dateKey: '2026-09-07',
  weekKey: '2026-W37',
  dayInWeek: 1,
  theme: const PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
  stations: const [
    PackStation(kind: 'grammar', status: StationStatus.todo),
    PackStation(kind: 'review', status: StationStatus.empty),
  ],
);

void main() {
  testWidgets('the hero card renders from the pack provider', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dailyPackProvider.overrideWith((ref) async => _pack),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ref.watch(dailyPackProvider).when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (pack) => DailyPackHeroCard(
                    pack: pack,
                    onOpen: () {},
                    onPickLanguage: () {},
                    onOpenProgress: () {},
                  ),
                ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Work & careers'), findsOneWidget);
  });

  test('the retired two-card widgets are actually gone', () {
    // Guards against the old UI surviving as dead code that a later change
    // could wire back in. Paths are relative to bananatalk_app/, the directory
    // flutter test runs from.
    expect(File('lib/pages/learning/daily/widgets/today_section.dart').existsSync(), isFalse);
    expect(File('lib/pages/learning/daily/daily_drop_screen.dart').existsSync(), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/learn_tab_pack_test.dart`
Expected: FAIL — `dailyPackProvider` override mismatch or missing import until Task 2 is in place; if Tasks 1–9 are done it fails only on the Learn tab wiring below.

- [ ] **Step 3: Rewire the Learn tab**

Replace the `dailyDropProvider` block at `learn_tab.dart:56-79` with:

```dart
                // ── Today zone: the daily pack leads the tab ──
                ref.watch(dailyPackProvider).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (pack) => DailyPackHeroCard(
                        pack: pack,
                        mastery: ref.watch(masteryProvider).valueOrNull,
                        onOpen: () => Navigator.of(context)
                            .push(AppPageRoute(builder: (_) => DailyPackFlow(pack: pack)))
                            .then((_) {
                          if (!context.mounted) return;
                          ref.invalidate(dailyPackProvider);
                          ref.invalidate(masteryProvider);
                          // ProgressHero, the quick stats and DailyGoalWidget sit
                          // directly under this card and read
                          // learningProgressProvider. Without invalidating it too,
                          // the card flips to done while the streak counter an inch
                          // below still shows yesterday's number.
                          ref.invalidate(learningProgressProvider);
                        }),
                        onPickLanguage: () => _pickLearningLanguage(context, ref),
                        onOpenProgress: () => Navigator.of(context).push(
                          AppPageRoute(
                            builder: (_) => MasteryScreen(
                              mastery: ref.read(masteryProvider).valueOrNull,
                              onRetakePlacement: () => Navigator.of(context).push(
                                AppPageRoute(builder: (_) => const PlacementScreen()),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
```

Move `const DailyPracticeCard()` (line 94) out of the top zone — the pack absorbs it as the weekend `translate` station, so it no longer competes for attention. Delete that line and its surrounding `SizedBox` if the card becomes orphaned.

Update the imports at the top of `learn_tab.dart`: drop `today_section.dart` / `daily_drop_screen.dart`, add `daily_pack_hero_card.dart`, `daily_pack_flow.dart`, `daily_pack_providers.dart`, `mastery_screen.dart`, `placement/placement_screen.dart`.

- [ ] **Step 4: Delete the retired widgets and their tests**

```bash
git rm bananatalk_app/lib/pages/learning/daily/widgets/today_section.dart \
       bananatalk_app/lib/pages/learning/daily/daily_drop_screen.dart \
       bananatalk_app/test/learning/today_section_test.dart \
       bananatalk_app/test/learning/daily_drop_screen_test.dart
```

Note: `test/learning/daily_drop_model_test.dart`, `daily_drop_locale_test.dart` and `daily_drop_router_test.dart` **stay** — the model, locale mapping and notification route are all still in use.

- [ ] **Step 5: Verify the whole app analyzes and every test passes**

Run: `cd bananatalk_app && flutter analyze && flutter test`
Expected: no analyzer issues in the touched files, and the full suite green. If `daily_drop_router_test.dart` still expects `/learning/daily`, point that route at the pack flow and keep the test passing — a push notification must not open a deleted screen.

- [ ] **Step 6: Commit**

```bash
git add -A bananatalk_app/lib/pages/learning bananatalk_app/test/learning
git commit -m "feat(daily-pack): the pack replaces the two-card daily drop on the Learn tab"
```

---

### Task 11: Translate the new strings into the other 18 locales

**Files:**
- Modify: all of `bananatalk_app/lib/l10n/app_*.arb` except `app_en.arb`
- Test: `bananatalk_app/test/learning/pack_l10n_test.dart`

**Interfaces:**
- Consumes: the keys added in Tasks 5–9.
- Produces: complete localisation coverage for the pack.

- [ ] **Step 1: Write the failing test**

```dart
// bananatalk_app/test/learning/pack_l10n_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Every pack string must exist in every locale. A missing key silently falls
/// back to English at runtime, which is invisible in review and obvious to the
/// learner.
void main() {
  test('every pack and mastery key is present in all 19 locales', () {
    final dir = Directory('lib/l10n');
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final packKeys = en.keys
        .where((k) => !k.startsWith('@'))
        .where((k) => k.startsWith('pack') || k.startsWith('mastery') || k.startsWith('placement'))
        .toList();
    expect(packKeys, isNotEmpty, reason: 'the pack keys should exist in app_en.arb');

    final missing = <String, List<String>>{};
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.arb') || file.path.endsWith('app_en.arb')) continue;
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final gaps = packKeys.where((k) => !arb.containsKey(k)).toList();
      if (gaps.isNotEmpty) missing[file.path.split('/').last] = gaps;
    }
    expect(missing, isEmpty, reason: 'missing translations: $missing');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd bananatalk_app && flutter test test/learning/pack_l10n_test.dart`
Expected: FAIL, listing every pack key missing from all 18 non-English ARB files.

- [ ] **Step 3: Translate**

For each of the 18 files (`app_ar`, `app_de`, `app_es`, `app_fr`, `app_hi`, `app_id`, `app_it`, `app_ja`, `app_ko`, `app_pt`, `app_ru`, `app_th`, `app_tr`, `app_uk`, `app_uz`, `app_vi`, `app_zh`, `app_zh_Hant` — confirm the exact list with `ls lib/l10n/`), add every key the test reported. Rules:

- Keep the placeholder names **identical** (`{station}`, `{mastered}`, `{total}`, `{count}`, `{current}`, `{percent}`, `{samples}`, `{topic}`, `{unit}`, `{number}`). A renamed placeholder is a runtime crash, not a fallback.
- Only `app_en.arb` carries the `@key` metadata blocks; the other locales carry values only, matching the existing convention in those files.
- Station names (`packStationVocabulary` etc.) are UI labels and must be translated, not left in English.
- `masteryYourLevel` must not become a certification claim in any language.

- [ ] **Step 4: Regenerate and verify**

Run: `cd bananatalk_app && flutter gen-l10n && flutter test test/learning/pack_l10n_test.dart && flutter analyze`
Expected: PASS, and no analyzer issues.

- [ ] **Step 5: Run the entire suite**

Run: `cd bananatalk_app && flutter test`
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add bananatalk_app/lib/l10n/ bananatalk_app/test/learning/pack_l10n_test.dart
git commit -m "i18n(daily-pack): translate the pack strings into all 19 locales"
```

---

## Self-review notes

- **Spec coverage**: §7.1 structure → Tasks 3–9. §7.2 hero card, flow, `check_question`, motion, edge states, accessibility → Tasks 3, 4, 5, 7, 8. §7.3 progress surfaces → Task 8. §7.4 l10n cost → Task 11. Placement (D4) → Task 9. `DailyPracticeCard` folded in (D8) → Tasks 6, 10.
- **Type consistency**: `SubmitAnswers` is defined once in `station_scaffold.dart` and reused by the vocabulary, grammar, listening and wrap stations. Review and translate deliberately have **different** submit signatures (`List<Map<String, dynamic>>` and `String`), which is why Task 6's interface block states them explicitly. `StationResult` is the single return type for every submission path. `MasterySummary` is consumed by both the hero strip and the mastery screen.
- **Deliberate deviation from the spec**: §7.1 listed `translate_station.dart` under the wave-2 heading in passing; it is in Task 6 here because D8 makes the weekend station part of the four-station day, and a day with a missing Saturday station would not complete.
- **Known rough edge**: `TranslateStation` posts `answers: [1]` because the backend plan's `completeStationForUser` scores non-check stations by counting `1`s. Wiring the typed text to the existing AI grading path (`learning/daily-practice/grade`) is a follow-up; until then the station awards credit for attempting, which is the wave-1 behaviour the backend plan implements.
- **Gap to watch**: `daily_drop_router_test.dart` expects the `daily_drop` push type to resolve to `/learning/daily`. Task 10 Step 5 keeps that route alive by pointing it at the pack flow. If it is missed, the daily push notification opens a deleted screen — the worst possible outcome for the feature whose whole problem is people not returning.
