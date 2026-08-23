import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/today_section.dart';

DailyItem _item(String kind, String title) => DailyItem(
      id: '$kind-1', kind: kind, level: 'A2', title: title,
      explanation: 'why', examples: const [],
      quickCheck: const [
        DailyQuickCheck(prompt: 'Q1', options: ['a', 'b']),
        DailyQuickCheck(prompt: 'Q2', options: ['a', 'b']),
        DailyQuickCheck(prompt: 'Q3', options: ['a', 'b']),
      ],
    );

Widget _host(DailyDropState state, {void Function(DailyItem)? onOpen, VoidCallback? onPick}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TodaySection(
          state: state,
          onOpen: onOpen ?? (_) {},
          onPickLanguage: onPick ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('shows both cards when both items are present', (tester) async {
    await tester.pumpWidget(_host(DailyDropState(
      needsLanguage: false, dateKey: '2026-08-23',
      grammar: _item('grammar', 'used to vs would'),
      vocabulary: _item('vocabulary', 'Work & careers'),
    )));
    expect(find.text('used to vs would'), findsOneWidget);
    expect(find.text('Work & careers'), findsOneWidget);
  });

  testWidgets('tapping a card reports the item', (tester) async {
    DailyItem? opened;
    await tester.pumpWidget(_host(
      DailyDropState(
        needsLanguage: false, dateKey: '2026-08-23',
        grammar: _item('grammar', 'used to vs would'),
      ),
      onOpen: (i) => opened = i,
    ));
    await tester.tap(find.text('used to vs would'));
    await tester.pumpAndSettle();
    expect(opened?.kind, 'grammar');
  });

  testWidgets('a completed kind renders its score and does not call onOpen', (tester) async {
    var opens = 0;
    await tester.pumpWidget(_host(
      DailyDropState(
        needsLanguage: false, dateKey: '2026-08-23',
        grammar: _item('grammar', 'used to vs would'),
        completedScores: const {'grammar': 3},
      ),
      onOpen: (_) => opens++,
    ));
    expect(find.text('3/3'), findsOneWidget);
    await tester.tap(find.text('used to vs would'));
    await tester.pumpAndSettle();
    expect(opens, 0);
  });

  testWidgets('needsLanguage shows the picker prompt instead of cards', (tester) async {
    var picked = 0;
    await tester.pumpWidget(_host(
      const DailyDropState(needsLanguage: true, dateKey: '2026-08-23'),
      onPick: () => picked++,
    ));
    expect(find.byKey(const Key('today-pick-language')), findsOneWidget);
    await tester.tap(find.byKey(const Key('today-pick-language')));
    await tester.pumpAndSettle();
    expect(picked, 1);
  });

  testWidgets('a level fallback is disclosed to the user', (tester) async {
    await tester.pumpWidget(_host(DailyDropState(
      needsLanguage: false, dateKey: '2026-08-23',
      requestedLevel: 'C1', servedLevel: 'B1',
      grammar: _item('grammar', 'used to vs would'),
    )));
    expect(find.byKey(const Key('today-level-fallback')), findsOneWidget);
  });

  testWidgets('explains itself rather than rendering nothing when both items are null',
      (tester) async {
    await tester.pumpWidget(_host(
      const DailyDropState(needsLanguage: false, dateKey: '2026-08-23'),
    ));
    final empty = find.byKey(const Key('today-empty'));
    expect(empty, findsOneWidget);
    // Every English user sees this until the bank is approved — it must say
    // something, not occupy zero height.
    expect(find.descendant(of: empty, matching: find.byType(Text)), findsOneWidget);
    expect(tester.getSize(empty).height, greaterThan(0));
  });
}
