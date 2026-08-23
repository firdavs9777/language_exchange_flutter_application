import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_drop_screen.dart';

final _item = DailyItem(
  id: 'g1', kind: 'grammar', level: 'A2', title: 'used to vs would',
  explanation: 'Both describe past habits.',
  examples: const [DailyExample(text: 'I used to live in Seoul.', translation: 'past state')],
  quickCheck: const [
    DailyQuickCheck(prompt: 'Q1', options: ['a', 'b']),
    DailyQuickCheck(prompt: 'Q2', options: ['a', 'b']),
    DailyQuickCheck(prompt: 'Q3', options: ['a', 'b']),
  ],
);

Widget _host({
  Future<DailyCompletionResult> Function(String, List<int>)? submit,
  Future<String> Function(String, String)? feedback,
}) =>
    MaterialApp(
      home: DailyDropScreen(
        item: _item,
        submitAnswers: submit ??
            (_, __) async => const DailyCompletionResult(
                  score: 2, total: 3, correctAnswers: [0, 0, 0], dayComplete: false,
                ),
        submitFeedback: feedback ?? (_, __) async => 'B1',
      ),
    );

void main() {
  testWidgets('shows the explanation and every example', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('Both describe past habits.'), findsOneWidget);
    expect(find.text('I used to live in Seoul.'), findsOneWidget);
  });

  testWidgets('submit is disabled until every question is answered', (tester) async {
    await tester.pumpWidget(_host());
    final submit = find.byKey(const Key('daily-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(Key('daily-q$i-opt0')));
      await tester.pump();
    }
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('submitting sends the chosen answers and shows the score', (tester) async {
    List<int>? sent;
    await tester.pumpWidget(_host(submit: (id, answers) async {
      sent = answers;
      return const DailyCompletionResult(
          score: 3, total: 3, correctAnswers: [1, 1, 1], dayComplete: true, streak: 4, xpAwarded: 20);
    }));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(Key('daily-q$i-opt1')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('daily-submit')));
    await tester.pumpAndSettle();

    expect(sent, [1, 1, 1]);
    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets('too hard reports the verdict', (tester) async {
    String? verdict;
    await tester.pumpWidget(_host(feedback: (id, v) async { verdict = v; return 'A1'; }));
    await tester.tap(find.byKey(const Key('daily-too-hard')));
    await tester.pumpAndSettle();
    expect(verdict, 'tooHard');
  });

  testWidgets('too easy reports the verdict', (tester) async {
    String? verdict;
    await tester.pumpWidget(_host(feedback: (id, v) async { verdict = v; return 'B1'; }));
    await tester.tap(find.byKey(const Key('daily-too-easy')));
    await tester.pumpAndSettle();
    expect(verdict, 'tooEasy');
  });
}
