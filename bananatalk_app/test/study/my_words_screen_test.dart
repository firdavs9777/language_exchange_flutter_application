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

class _FakeApi extends MyWordsApi {
  int keeps = 0, dismisses = 0, gotIts = 0;
  bool failDismiss = false;
  ({int successes, bool resolved}) gotItAnswer = (
    successes: 1,
    resolved: false,
  );

  @override
  Future<String?> keep(String candidateId) async {
    keeps++;
    return 'v1';
  }

  @override
  Future<void> dismiss(String candidateId) async {
    dismisses++;
    if (failDismiss) throw StateError('nope');
  }

  @override
  Future<({int successes, bool resolved})> gotIt(String mistakeId) async {
    gotIts++;
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

Future<_FakeApi> _pump(
  WidgetTester tester,
  MyWords data, {
  int due = 0,
  _FakeApi? api,
  Size? size,
  double textScale = 1.0,
}) async {
  final fake = api ?? _FakeApi();
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myWordsProvider.overrideWith((ref) async => data),
        myWordsApiProvider.overrideWithValue(fake),
        vocabularyStatsProvider(null).overrideWith((ref) async => _stats(due)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const MyWordsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets(
    'sections with nothing in them are hidden; all empty shows the empty line',
    (tester) async {
      await _pump(tester, _data(m: [_mistake('m1')]));
      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('From your chats'), findsNothing);
      expect(find.text('Words to review'), findsNothing);
    },
  );

  testWidgets('all empty shows the empty line', (tester) async {
    await _pump(tester, _data());
    expect(
      find.text(
        'Nothing waiting. Look up a word in a chat and it will show up here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('words to review shows when words are due', (tester) async {
    await _pump(tester, _data(c: [_cand('c1', 'bonjour')]), due: 4);
    expect(find.text('Words to review'), findsOneWidget);
    expect(find.text('4 words are ready'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('keep removes the row and calls the api once on a double tap', (
    tester,
  ) async {
    final api = await _pump(
      tester,
      _data(c: [_cand('c1', 'bonjour', pos: 'noun')]),
    );
    expect(find.text('bonjour'), findsOneWidget);
    expect(find.text('tr-bonjour'), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
    final keep = find.text('Keep');
    await tester.tap(keep);
    await tester.tap(keep, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(api.keeps, 1);
    expect(find.text('bonjour'), findsNothing);
  });

  testWidgets(
    'a failed dismiss restores the row and shows the failure message',
    (tester) async {
      final api = _FakeApi()..failDismiss = true;
      await _pump(tester, _data(c: [_cand('c1', 'bonjour')]), api: api);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(api.dismisses, 1);
      expect(find.text('bonjour'), findsOneWidget);
      expect(find.text("That didn't save. Try again."), findsOneWidget);
    },
  );

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
    'a long right-to-left sentence does not overflow at 320 wide, text scale 1.3',
    (tester) async {
      final long = List.filled(12, 'هذه جملة طويلة جدا للتدريب').join(' ');
      await _pump(
        tester,
        _data(
          c: [_cand('c1', long, pos: 'noun')],
          m: [_mistake('m1', corrected: long, explanation: long)],
        ),
        size: const Size(320, 640),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
