import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/review_station.dart';

/// The bug: "Show answer" revealed a single bare word.
///
/// The backend sent only { id, word, translation, srsLevel } even though 58% of
/// Vocabulary rows carry an example sentence and the model stores partOfSpeech
/// too. The context existed and was dropped on the way out, so the screen was a
/// word floating above a button, and the "answer" was one more word.
ReviewWord word({String? partOfSpeech, String? example}) => ReviewWord(
      id: 'v1',
      word: 'furthermore',
      translation: 'in addition to what has been said',
      partOfSpeech: partOfSpeech,
      example: example,
      srsLevel: 2,
    );

Widget host(ReviewWord w) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ReviewStation(
          payload: ReviewPayload(words: [w]),
          onSubmit: (_) async => const StationResult(score: 1, total: 1),
          onDone: () {},
        ),
      ),
    );

void main() {
  testWidgets('the answer is hidden until asked for', (tester) async {
    await tester.pumpWidget(host(word(example: 'The plan is risky.')));
    await tester.pumpAndSettle();
    expect(find.text('furthermore'), findsOneWidget);
    expect(find.byKey(const Key('review-translation')), findsNothing);
    expect(find.byKey(const Key('review-example')), findsNothing);
  });

  testWidgets('revealing shows the example sentence, not just a word',
      (tester) async {
    await tester.pumpWidget(host(
      word(partOfSpeech: 'adverb', example: 'The plan is expensive; furthermore, it is risky.'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-reveal')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-translation')), findsOneWidget);
    expect(find.byKey(const Key('review-pos')), findsOneWidget);
    expect(find.byKey(const Key('review-example')), findsOneWidget);
    expect(find.text('adverb'), findsOneWidget);
  });

  testWidgets('a word with no example reveals without an empty box',
      (tester) async {
    // 42% of rows have none. A blank container where a sentence should be is
    // the emptiness this fix exists to remove.
    await tester.pumpWidget(host(word()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-reveal')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-translation')), findsOneWidget);
    expect(find.byKey(const Key('review-example')), findsNothing);
    expect(find.byKey(const Key('review-pos')), findsNothing);
  });

  testWidgets('it says Review, not Word — this is recall, not teaching',
      (tester) async {
    await tester.pumpWidget(host(word()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Review 1 of 1'), findsOneWidget);
    expect(find.textContaining('Word 1 of'), findsNothing);
  });

  testWidgets('the learner is told what to do with the word', (tester) async {
    await tester.pumpWidget(host(word()));
    await tester.pumpAndSettle();
    expect(find.text('Do you remember this word?'), findsOneWidget);
  });
}
