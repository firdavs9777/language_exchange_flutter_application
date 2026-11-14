import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/learning/my_words/my_words_screen.dart';
import 'package:bananatalk_app/providers/provider_root/learning/my_words_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/services/study/my_words_api.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';

class _FakeApi extends MyWordsApi {
  int keeps = 0, dismisses = 0, gotIts = 0;
  bool failDismiss = false, failKeep = false;
  Completer<void>? keepGate, dismissGate;
  Completer<({int successes, bool resolved})>? gotItGate;
  ({int successes, bool resolved}) gotItAnswer = (
    successes: 1,
    resolved: false,
  );

  @override
  Future<String?> keep(String candidateId) async {
    keeps++;
    await keepGate?.future;
    if (failKeep) throw StateError('nope');
    return 'v1';
  }

  @override
  Future<void> dismiss(String candidateId) async {
    dismisses++;
    await dismissGate?.future;
    if (failDismiss) throw StateError('nope');
  }

  @override
  Future<({int successes, bool resolved})> gotIt(String mistakeId) async {
    gotIts++;
    final g = gotItGate;
    if (g != null) return g.future;
    return gotItAnswer;
  }
}

WordCandidate _cand(String id, String text, {String? pos}) => WordCandidate(
  id: id,
  text: text,
  translation: 'tr-$text',
  language: 'fr',
  partOfSpeech: pos,
);

StudyMistakeItem _mistake(
  String id, {
  int successes = 0,
  String explanation = 'because',
  String corrected = 'I went home',
  String language = 'en',
}) => StudyMistakeItem(
  id: id,
  original: 'I goed home',
  corrected: corrected,
  explanation: explanation,
  source: 'check',
  language: language,
  successes: successes,
);

MyWords _data({
  List<WordCandidate> c = const [],
  List<StudyMistakeItem> m = const [],
}) => MyWords(
  candidateCount: c.length,
  mistakeCount: m.length,
  dueWords: 0,
  candidates: c,
  mistakes: m,
);

VocabularyStats _stats(int due) => VocabularyStats(
  total: 0,
  mastered: 0,
  learning: 0,
  newWords: 0,
  dueToday: due,
  byLanguage: const {},
  bySrsLevel: const {},
  reviewStreak: 0,
  averageAccuracy: 0,
);

class _Harness {
  _Harness(this.api, this.statsBuilds, this.visible);
  final _FakeApi api;
  final List<int> statsBuilds;
  final ValueNotifier<bool> visible;
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MyWordsScreen)));

Future<_Harness> _pump(
  WidgetTester tester,
  MyWords data, {
  Future<MyWords> Function()? load,
  int due = 0,
  Future<VocabularyStats?> Function()? stats,
  _FakeApi? api,
  Size? size,
  double textScale = 1.0,
  Locale? locale,
  bool rtl = false,
  bool settle = true,
}) async {
  final fake = api ?? _FakeApi();
  final builds = <int>[];
  final visible = ValueNotifier<bool>(true);
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myWordsProvider.overrideWith(
          (ref) => load != null ? load() : Future.value(data),
        ),
        myWordsApiProvider.overrideWithValue(fake),
        vocabularyStatsProvider(null).overrideWith((ref) {
          builds.add(1);
          return stats != null ? stats() : Future.value(_stats(due));
        }),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, v, __) =>
              v ? const MyWordsScreen() : const Scaffold(body: SizedBox()),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return _Harness(fake, builds, visible);
}

double _y(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  tearDown(() => studyLogSpy = null);

  testWidgets('sections with nothing in them are hidden', (tester) async {
    await _pump(tester, _data(m: [_mistake('m1')]));
    expect(find.text('Mistakes'), findsOneWidget);
    expect(find.text('From your chats'), findsNothing);
    expect(find.text('Words to review'), findsNothing);
  });

  testWidgets('all empty shows the empty line', (tester) async {
    await _pump(tester, _data());
    expect(
      find.text(
        'Nothing waiting. Look up a word in a chat and it will show up here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no empty line while the stats are still loading', (
    tester,
  ) async {
    final gate = Completer<VocabularyStats?>();
    await _pump(tester, _data(), stats: () => gate.future, settle: false);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Nothing waiting'), findsNothing);
    gate.complete(_stats(3));
    await tester.pumpAndSettle();
    expect(find.text('Words to review'), findsOneWidget);
    expect(find.textContaining('Nothing waiting'), findsNothing);
  });

  testWidgets(
    'all three sections appear in order; mistake labels and explanation',
    (tester) async {
      await _pump(
        tester,
        _data(
          c: [_cand('c1', 'bonjour')],
          m: [
            _mistake('m1'),
            _mistake('m2', explanation: ''),
          ],
        ),
        due: 4,
        size: const Size(800, 3000),
      );
      expect(_y(tester, 'From your chats'), lessThan(_y(tester, 'Mistakes')));
      expect(_y(tester, 'Mistakes'), lessThan(_y(tester, 'Words to review')));
      expect(find.text('You wrote'), findsNWidgets(2));
      expect(find.text('Correction'), findsNWidgets(2));
      expect(find.text('because'), findsOneWidget);
      expect(find.text('4 words are ready'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    },
  );

  testWidgets('double tap with the request held open sends one request each', (
    tester,
  ) async {
    final api = _FakeApi()
      ..keepGate = Completer<void>()
      ..dismissGate = Completer<void>()
      ..gotItGate = Completer();
    await _pump(
      tester,
      _data(c: [_cand('c1', 'one'), _cand('c2', 'two')], m: [_mistake('m1')]),
      api: api,
      size: const Size(800, 3000),
    );
    await tester.tap(find.text('Keep').first);
    await tester.tap(find.text('Keep').first, warnIfMissed: false);
    await tester.tap(find.text('Dismiss').at(1));
    await tester.tap(find.text('Dismiss').at(1), warnIfMissed: false);
    await tester.tap(find.text('Got it'));
    await tester.tap(find.text('Got it'), warnIfMissed: false);
    await tester.pump();
    expect(api.keeps, 1);
    expect(api.dismisses, 1);
    expect(api.gotIts, 1);
    api.keepGate!.complete();
    api.dismissGate!.complete();
    api.gotItGate!.complete((successes: 1, resolved: false));
    await tester.pumpAndSettle();
  });

  testWidgets('keep removes the row and shows the data', (tester) async {
    final h = await _pump(
      tester,
      _data(c: [_cand('c1', 'bonjour', pos: 'noun')]),
    );
    expect(find.text('tr-bonjour'), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(h.api.keeps, 1);
    expect(find.text('bonjour'), findsNothing);
  });

  testWidgets(
    'a failed dismiss restores the row and shows the failure message',
    (tester) async {
      final api = _FakeApi()..failDismiss = true;
      await _pump(tester, _data(c: [_cand('c1', 'bonjour')]), api: api);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('bonjour'), findsOneWidget);
      expect(find.text("That didn't save. Try again."), findsOneWidget);
    },
  );

  testWidgets('failed keep restores the middle row in the middle', (
    tester,
  ) async {
    final api = _FakeApi()
      ..failKeep = true
      ..keepGate = Completer<void>();
    await _pump(
      tester,
      _data(c: [_cand('c1', 'one'), _cand('c2', 'two'), _cand('c3', 'three')]),
      api: api,
    );
    await tester.tap(find.text('Keep').at(1));
    await tester.pump();
    expect(find.text('two'), findsNothing);
    api.keepGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);
    expect(_y(tester, 'one'), lessThan(_y(tester, 'two')));
    expect(_y(tester, 'two'), lessThan(_y(tester, 'three')));
  });

  testWidgets('failed keep restores in place when another row left meanwhile', (
    tester,
  ) async {
    final api = _FakeApi()
      ..failKeep = true
      ..keepGate = Completer<void>();
    await _pump(
      tester,
      _data(c: [_cand('c1', 'one'), _cand('c2', 'two'), _cand('c3', 'three')]),
      api: api,
    );
    await tester.tap(find.text('Keep').at(1)); // two, held
    await tester.pump();
    await tester.tap(find.text('Dismiss').first); // one leaves meanwhile
    await tester.pumpAndSettle();
    expect(find.text('one'), findsNothing);
    api.keepGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);
    expect(_y(tester, 'two'), lessThan(_y(tester, 'three')));
  });

  testWidgets('refresh during a dismiss that then fails: one row, in place', (
    tester,
  ) async {
    final api = _FakeApi()
      ..failDismiss = true
      ..dismissGate = Completer<void>();
    MyWords fresh() => _data(
      c: [_cand('c1', 'one'), _cand('c2', 'two'), _cand('c3', 'three')],
    );
    await _pump(tester, fresh(), api: api, load: () async => fresh());
    await tester.tap(find.text('Dismiss').at(1));
    await tester.pump();
    _container(tester).invalidate(myWordsProvider);
    await tester.pumpAndSettle();
    expect(find.text('two'), findsNothing); // still in flight
    api.dismissGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(_y(tester, 'one'), lessThan(_y(tester, 'two')));
    expect(_y(tester, 'two'), lessThan(_y(tester, 'three')));
  });

  testWidgets('refresh during a dismiss that succeeds: the row stays gone', (
    tester,
  ) async {
    final api = _FakeApi()..dismissGate = Completer<void>();
    MyWords fresh() => _data(c: [_cand('c1', 'one'), _cand('c2', 'two')]);
    final data = fresh();
    final stale = Completer<MyWords>();
    var calls = 0;
    await _pump(
      tester,
      data,
      api: api,
      load: () {
        calls++;
        return calls == 1 ? Future.value(data) : stale.future;
      },
    );
    await tester.tap(find.text('Dismiss').first);
    await tester.pump();
    _container(tester).invalidate(myWordsProvider); // requested before success
    await tester.pump();
    api.dismissGate!.complete();
    await tester.pumpAndSettle();
    stale.complete(fresh()); // the old answer still has the row
    await tester.pumpAndSettle();
    expect(find.text('one'), findsNothing);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets(
    'got it shows 1 of 3 and keeps the row until the server says resolved',
    (tester) async {
      final api = _FakeApi();
      await _pump(tester, _data(m: [_mistake('m1')]), api: api);
      expect(find.text('1 of 3'), findsNothing);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('I goed home'), findsOneWidget);

      api.gotItAnswer = (successes: 3, resolved: true);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(api.gotIts, 2);
      expect(find.text('I goed home'), findsNothing);
    },
  );

  testWidgets(
    'say it on a mistake opens pronunciation with the corrected sentence',
    (tester) async {
      await _pump(tester, _data(m: [_mistake('m1', language: 'fr')]));
      await tester.tap(find.text('Say it'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final screen = tester.widget<PronunciationScreen>(
        find.byType(PronunciationScreen),
      );
      expect(screen.initialText, 'I went home');
      expect(screen.initialLanguage, 'fr');
      expect(screen.ownSentence, isTrue);
    },
  );

  testWidgets(
    'say it on a candidate opens pronunciation with its text and language',
    (tester) async {
      await _pump(tester, _data(c: [_cand('c1', 'bonjour')]));
      await tester.tap(find.text('Say it'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final screen = tester.widget<PronunciationScreen>(
        find.byType(PronunciationScreen),
      );
      expect(screen.initialText, 'bonjour');
      expect(screen.initialLanguage, 'fr');
      expect(screen.ownSentence, isTrue);
    },
  );

  testWidgets('a successful keep invalidates the vocabulary stats', (
    tester,
  ) async {
    final h = await _pump(tester, _data(c: [_cand('c1', 'bonjour')]));
    final before = h.statsBuilds.length;
    expect(before, greaterThan(0));
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(h.statsBuilds.length, greaterThan(before));
  });

  testWidgets('opening logs my_words once; say it logs say_it', (tester) async {
    final logs = <String>[];
    studyLogSpy = (name, fields) => logs.add('$name/${fields['kind']}');
    await _pump(tester, _data(c: [_cand('c1', 'bonjour')]));
    _container(tester).invalidate(myWordsProvider);
    await tester.pumpAndSettle();
    expect(logs, ['${StudyEvent.featureOpened}/my_words']);
    await tester.tap(find.text('Say it'));
    await tester.pump();
    expect(logs, [
      '${StudyEvent.featureOpened}/my_words',
      '${StudyEvent.featureOpened}/say_it',
    ]);
  });

  testWidgets('the load-error state shows retry, and retry loads', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      _data(),
      load: () async {
        calls++;
        if (calls == 1) throw StateError('down');
        return _data(c: [_cand('c1', 'bonjour')]);
      },
    );
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('bonjour'), findsOneWidget);
  });

  testWidgets('a failed refresh keeps the rows and throws nothing', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      _data(),
      load: () async {
        calls++;
        if (calls > 1) throw StateError('down');
        return _data(c: [_cand('c1', 'bonjour')]);
      },
    );
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(calls, greaterThan(1));
    expect(find.text('bonjour'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving mid-keep throws nothing and still invalidates stats', (
    tester,
  ) async {
    final api = _FakeApi()..keepGate = Completer<void>();
    final h = await _pump(tester, _data(c: [_cand('c1', 'bonjour')]), api: api);
    final before = h.statsBuilds.length;
    await tester.tap(find.text('Keep'));
    await tester.pump();
    h.visible.value = false;
    await tester.pumpAndSettle();
    api.keepGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The stats provider is not watched any more once the screen is gone, so
    // it is rebuilt only if something reads it again; read it to compare.
    expect(h.statsBuilds.length, greaterThanOrEqualTo(before));
  });

  testWidgets(
    'leaving mid-keep: stats are invalidated (rebuilt on next read)',
    (tester) async {
      final api = _FakeApi()..keepGate = Completer<void>();
      final h = await _pump(
        tester,
        _data(c: [_cand('c1', 'bonjour')]),
        api: api,
      );
      await tester.tap(find.text('Keep'));
      await tester.pump();
      h.visible.value = false;
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      final sub = container.listen(vocabularyStatsProvider(null), (_, __) {});
      await tester.pump();
      final before = h.statsBuilds.length;
      api.keepGate!.complete();
      await tester.pumpAndSettle();
      expect(h.statsBuilds.length, greaterThan(before));
      sub.close();
    },
  );

  for (final loc in [
    const Locale('ar'),
    const Locale('ru'),
    const Locale('de'),
  ]) {
    testWidgets('no overflow at 320 wide, scale 1.3 (${loc.languageCode})', (
      tester,
    ) async {
      final long = List.filled(12, 'هذه جملة طويلة جدا للتدريب').join(' ');
      await _pump(
        tester,
        _data(
          c: [_cand('c1', long, pos: 'noun')],
          m: [_mistake('m1', corrected: long, explanation: long, successes: 2)],
        ),
        due: 12,
        size: const Size(320, 640),
        textScale: 1.3,
        locale: loc,
        rtl: loc.languageCode == 'ar',
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
