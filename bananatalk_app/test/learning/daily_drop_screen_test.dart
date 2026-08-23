import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  // The production layout uses default-density RadioListTiles (comfortable
  // touch targets for a screen used every day) which don't fit inside
  // flutter_test's default 800x600 surface. Rather than shrink the real
  // layout to fit the test, give the test a taller surface instead.
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 3000);
    view.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

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
    // The streak and XP the server awarded are what the feature is for.
    expect(find.byKey(const Key('daily-reward')), findsOneWidget);
    expect(find.text('4-day streak · +20 XP'), findsOneWidget);
  });

  testWidgets('no reward line when the day is not yet complete', (tester) async {
    await tester.pumpWidget(_host(submit: (_, __) async =>
        const DailyCompletionResult(
            score: 2, total: 3, correctAnswers: [0, 0, 0], dayComplete: false)));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(Key('daily-q$i-opt0')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('daily-submit')));
    await tester.pumpAndSettle();

    expect(find.text('2/3'), findsOneWidget);
    expect(find.byKey(const Key('daily-reward')), findsNothing);
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
