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
