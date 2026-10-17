import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/placement/placement_screen.dart';
import 'package:bananatalk_app/services/learning_service.dart';

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

  testWidgets('a failed submit shows a retry that resends the same eight answers',
      (tester) async {
    final sent = <List<int>>[];
    var fail = true;
    await tester.pumpWidget(_host(submit: (a) async {
      sent.add(a);
      if (fail) throw Exception('offline');
      return {'level': 'B1', 'book': 'intermediate', 'correct': 6};
    }));
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(Key('check-q$i-opt1')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('placement-submit-error')), findsOneWidget);

    // Tapping an option again must not grow the answer list past eight.
    await tester.tap(find.byKey(const Key('check-q7-opt2')));
    await tester.pumpAndSettle();

    fail = false;
    await tester.tap(find.byKey(const Key('placement-submit-retry')));
    await tester.pumpAndSettle();
    expect(sent.every((a) => a.length == 8), isTrue);
    expect(find.byKey(const Key('placement-start')), findsOneWidget);
  });

  testWidgets('a double tap on the last question submits once', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(submit: (a) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return {'level': 'B1', 'book': 'intermediate', 'correct': 6};
    }));
    await tester.pumpAndSettle();
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byKey(Key('check-q$i-opt1')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('check-q7-opt1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('check-q7-opt0')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('loading and load-error screens have a back button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PlacementScreen(load: () async => throw Exception('offline')),
          )),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placement-error')), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  Map<String, dynamic> reviewed() => {
        'level': 'A2',
        'book': 'elementary',
        'correct': 6,
        'total': 8,
        'review': List.generate(8, (i) {
          final wrong = i == 3 || i == 7;
          return {
            'prompt': 'Question $i',
            'options': ['a', 'b', 'c'],
            'given': i == 7 ? null : (wrong ? 2 : 1),
            'answerIndex': 1,
            'correct': !wrong,
            'topic': 'Topic $i',
            'explanation': 'Because $i',
          };
        }),
        'focus': {
          'level': 'A2',
          'topics': ['Topic 3', 'Topic 7'],
        },
      };

  Future<void> finishAll(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(Key('check-q$i-opt1')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('the result shows the score, what to work on and each answer',
      (tester) async {
    await tester.pumpWidget(_host(submit: (_) async => reviewed()));
    await tester.pumpAndSettle();
    await finishAll(tester);

    expect(find.byKey(const Key('placement-level')), findsOneWidget);
    expect(find.text('6 of 8 correct'), findsOneWidget);
    expect(find.text('What to work on next'), findsOneWidget);
    expect(find.text('Topic 3'), findsOneWidget);

    final review3 = find.byKey(const Key('placement-review-3'));
    await tester.scrollUntilVisible(review3, 200);
    expect(find.descendant(of: review3, matching: find.textContaining('Incorrect')),
        findsOneWidget);
    expect(find.descendant(of: review3, matching: find.text('Because 3')), findsOneWidget);
    expect(find.descendant(of: review3, matching: find.byIcon(Icons.cancel)), findsWidgets);
    // A right answer shows no explanation.
    expect(find.text('Because 0'), findsNothing);

    final review7 = find.byKey(const Key('placement-review-7'));
    await tester.scrollUntilVisible(review7, 200);
    expect(find.descendant(of: review7, matching: find.textContaining('Not answered')),
        findsOneWidget);
  });

  testWidgets('all right says so instead of listing topics', (tester) async {
    final all = reviewed()
      ..['correct'] = 8
      ..['focus'] = {'level': null, 'topics': <String>[]};
    await tester.pumpWidget(_host(submit: (_) async => all));
    await tester.pumpAndSettle();
    await finishAll(tester);
    expect(find.textContaining('Every answer was right'), findsOneWidget);
  });

  testWidgets('a skip (no review) shows only the level and the start button',
      (tester) async {
    await tester.pumpWidget(_host(submit: (_) async =>
        {'level': 'A2', 'book': 'elementary', 'correct': 0, 'total': 8, 'review': [], 'focus': null}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('placement-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placement-level')), findsOneWidget);
    expect(find.byKey(const Key('placement-score')), findsNothing);
    expect(find.byKey(const Key('placement-focus')), findsNothing);
    expect(find.byKey(const Key('placement-start')), findsOneWidget);
  });

  testWidgets('a language with no level test says so, with no retry', (tester) async {
    await tester.pumpWidget(
        _host(load: () async => throw const PlacementUnavailableException()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placement-unavailable')), findsOneWidget);
    expect(find.textContaining('no level test'), findsOneWidget);
    expect(find.byKey(const Key('placement-error')), findsNothing);
  });

  test('placementLocaleTag sends zh_TW for Traditional Chinese, else the language code', () {
    expect(placementLocaleTag(const Locale('ko')), 'ko');
    expect(placementLocaleTag(const Locale('zh', 'TW')), 'zh_TW');
    expect(placementLocaleTag(const Locale('zh')), 'zh');
    expect(placementLocaleTag(const Locale('pt', 'BR')), 'pt');
  });
}
