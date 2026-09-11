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
  clips: [ListeningClip(id: 'c0', text: 'She is waiting outside.', word: 'waiting')],
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
        isNotNull, reason: 'the learner must be able to try again');
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
