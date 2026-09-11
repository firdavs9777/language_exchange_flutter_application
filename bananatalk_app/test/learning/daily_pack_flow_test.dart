import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_flow.dart';

DailyPack _pack({bool grammarDone = false}) => DailyPack(
      needsLanguage: false,
      dateKey: '2026-09-07',
      weekKey: '2026-W37',
      dayInWeek: 1,
      theme: const PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
      stations: [
        PackStation(
          kind: 'grammar',
          status: grammarDone ? StationStatus.done : StationStatus.todo,
          payload: const GrammarPayload(
            itemId: 'g1', unit: 1, section: 'Present', title: 'am / is / are',
            explanation: 'Match the verb to the subject.',
            examples: ['I am here.'],
            checks: [PackCheck(prompt: 'She ___ my sister.', options: ['am', 'is', 'are'])],
          ),
        ),
        const PackStation(kind: 'review', status: StationStatus.empty),
      ],
    );

Widget _host(DailyPack pack, {SubmitStation? submit}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DailyPackFlow(pack: pack, submit: submit),
    );

void main() {
  testWidgets('opens on the first outstanding station', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.text('am / is / are'), findsOneWidget);
  });

  testWidgets('shows the theme and the rail', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.text('Work & careers'), findsOneWidget);
    expect(find.byKey(const Key('rail-dot-0-current')), findsOneWidget);
  });

  testWidgets('an empty station is skipped rather than shown as a step', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    // Review is empty; the flow must not park the learner on an empty page.
    expect(find.byKey(const Key('review-reveal')), findsNothing);
  });

  testWidgets('a station submission routes to the right station kind', (tester) async {
    String? submitted;
    await tester.pumpWidget(_host(
      _pack(),
      submit: (station, {answers = const [], reviews = const []}) async {
        submitted = station;
        return const StationResult(score: 1, total: 1, packComplete: false);
      },
    ));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    expect(submitted, 'grammar');
  });

  testWidgets('completing the last station shows the completion sheet', (tester) async {
    await tester.pumpWidget(_host(
      _pack(),
      submit: (station, {answers = const [], reviews = const []}) async =>
          const StationResult(score: 1, total: 1, xpAwarded: 10, streak: 3, packComplete: true),
    ));
    await tester.tap(find.byKey(const Key('check-q0-opt1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-complete-sheet')), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets, reason: 'the streak is the reward');
  });

  testWidgets('the close button exits the flow', (tester) async {
    var exits = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DailyPackFlow(pack: _pack(), onExit: () => exits++),
    ));
    expect(find.byKey(const Key('pack-close')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pack-close')));
    await tester.pumpAndSettle();
    expect(exits, 1);
  });

  testWidgets('a pack with nothing outstanding goes straight to the sheet', (tester) async {
    await tester.pumpWidget(_host(_pack(grammarDone: true)));
    expect(find.byKey(const Key('day-complete-sheet')), findsOneWidget);
  });
}
