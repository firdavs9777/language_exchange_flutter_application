import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_hero_card.dart';

DailyPack _pack({
  bool needsLanguage = false,
  bool complete = false,
  List<PackStation>? stations,
  PackTheme? theme = const PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
}) =>
    DailyPack(
      needsLanguage: needsLanguage,
      dateKey: '2026-09-07',
      weekKey: '2026-W37',
      dayInWeek: 2,
      theme: theme,
      packComplete: complete,
      stations: stations ??
          const [
            PackStation(kind: 'vocabulary', status: StationStatus.done, score: 5),
            PackStation(kind: 'grammar', status: StationStatus.done, score: 3),
            PackStation(kind: 'listening', status: StationStatus.todo),
            PackStation(kind: 'review', status: StationStatus.todo),
          ],
    );

const _mastery = MasterySummary(
  level: 'A2',
  book: 'elementary',
  vocabulary: VocabMastery(mastered: 84, learning: 31, fresh: 4, due: 12),
  grammar: GrammarProgress(mastered: 9, total: 115, sections: []),
  listening: SkillAccuracy(accuracy: 0.71, samples: 14),
  translate: SkillAccuracy(accuracy: null, samples: 0),
  consistencyDays: ['2026-09-06', '2026-09-07'],
);

Widget _host(DailyPack pack,
        {MasterySummary? mastery, VoidCallback? onOpen, VoidCallback? onProgress}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DailyPackHeroCard(
          pack: pack,
          mastery: mastery,
          onOpen: onOpen ?? () {},
          onPickLanguage: () {},
          onOpenProgress: onProgress ?? () {},
          onTakePlacement: () {},
        ),
      ),
    );

void main() {
  testWidgets('shows the theme and the server-side progress', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.text('Work & careers'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
  });

  testWidgets('the call to action names the next station, not a generic Open', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.byKey(const Key('hero-cta')), findsOneWidget);
    expect(find.textContaining('Listening'), findsWidgets);
  });

  testWidgets('tapping the CTA opens the flow', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_host(_pack(), onOpen: () => opened++));
    await tester.tap(find.byKey(const Key('hero-cta')));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('a finished day is a satisfied state, not a dead card', (tester) async {
    await tester.pumpWidget(_host(_pack(
      complete: true,
      stations: const [
        PackStation(kind: 'vocabulary', status: StationStatus.done, score: 5),
        PackStation(kind: 'grammar', status: StationStatus.done, score: 3),
      ],
    )));
    expect(find.byKey(const Key('hero-done')), findsOneWidget);
  });

  testWidgets('the mastery strip states mastered and due counts', (tester) async {
    await tester.pumpWidget(_host(_pack(), mastery: _mastery));
    expect(find.textContaining('84'), findsWidgets);
    expect(find.textContaining('12'), findsWidgets);
    expect(find.textContaining('115'), findsWidgets);
  });

  testWidgets('tapping the strip opens the progress screen', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_host(_pack(), mastery: _mastery, onProgress: () => opened++));
    await tester.tap(find.byKey(const Key('hero-progress-strip')));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('no mastery data yet hides the strip instead of showing zeroes', (tester) async {
    await tester.pumpWidget(_host(_pack()));
    expect(find.byKey(const Key('hero-progress-strip')), findsNothing);
  });

  testWidgets('needsLanguage asks the question instead of rendering a pack', (tester) async {
    await tester.pumpWidget(_host(_pack(needsLanguage: true)));
    expect(find.byKey(const Key('today-pick-language')), findsOneWidget);
  });

  testWidgets('no theme yet explains the empty day', (tester) async {
    await tester.pumpWidget(_host(_pack(theme: null, stations: const [])));
    expect(find.byKey(const Key('today-empty')), findsOneWidget);
  });
}
