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
      payload: const TranslatePayload(sentence: 'Her ambition showed.'),
      onSubmit: (text) async { sent = text; return _ok(); },
      onDone: () {},
    )));
    await tester.enterText(find.byKey(const Key('translate-input')), 'Su ambicion se notaba.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(sent, 'Su ambicion se notaba.');
  });

  testWidgets('translate submit is disabled while the field is empty', (tester) async {
    await tester.pumpWidget(_host(TranslateStation(
      payload: const TranslatePayload(sentence: 'Her ambition showed.'),
      onSubmit: (_) async => _ok(),
      onDone: () {},
    )));
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('station-submit'))).onPressed,
      isNull,
    );
  });

  testWidgets('a failed review submission offers a retry', (tester) async {
    await tester.pumpWidget(_host(ReviewStation(
      payload: const ReviewPayload(words: [
        ReviewWord(id: 'v1', word: 'reluctant', translation: 'unwilling', srsLevel: 2),
      ]),
      onSubmit: (_) async => throw Exception('offline'),
      onDone: () {},
    )));
    await tester.tap(find.byKey(const Key('review-reveal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-knew')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('station-error')), findsOneWidget);
  });

  testWidgets('the translate station shows the sentence and its hint', (tester) async {
    await tester.pumpWidget(_host(TranslateStation(
      payload: const TranslatePayload(
        sentence: 'Ella tiene mucha ambicion.', hint: 'Watch the article.',
      ),
      onSubmit: (_) async => _ok(),
      onDone: () {},
    )));
    expect(find.text('Ella tiene mucha ambicion.'), findsOneWidget);
    expect(find.byKey(const Key('translate-hint')), findsOneWidget);
  });

  testWidgets('a graded translation shows the feedback and the suggestion', (tester) async {
    await tester.pumpWidget(_host(TranslateStation(
      payload: const TranslatePayload(sentence: 'x'),
      onSubmit: (_) async => const StationResult(
        score: 1, total: 1, graded: true, aiScore: 92,
        feedback: 'Well done.', suggestedTranslation: 'She has ambition.',
      ),
      onDone: () {},
    )));
    await tester.enterText(find.byKey(const Key('translate-input')), 'She has ambition.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('translate-feedback')), findsOneWidget);
    expect(find.text('Well done.'), findsOneWidget);
    expect(find.byKey(const Key('translate-suggestion')), findsOneWidget);
  });

  testWidgets('an ungraded submission says so instead of showing a score', (tester) async {
    await tester.pumpWidget(_host(TranslateStation(
      payload: const TranslatePayload(sentence: 'x'),
      onSubmit: (_) async => const StationResult(score: 1, total: 1, graded: false),
      onDone: () {},
    )));
    await tester.enterText(find.byKey(const Key('translate-input')), 'anything');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(find.text('1/1'), findsNothing, reason: 'no mark was earned');
    expect(find.byKey(const Key('station-score')), findsOneWidget);
  });
}
