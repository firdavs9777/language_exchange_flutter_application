import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_hero_card.dart';

/// A learner who has never taken the placement test is served DEFAULT_LEVEL
/// (A2) and told nothing about it. Measured on prod 2026-09-14: 90% of users
/// are in that state and LevelPlacement has zero rows ever, because the only
/// way into the test is a "retake placement" button two screens deep.
///
/// The pack payload now carries `levelPlaced`, so the card can offer the test
/// to the people who have never seen it -- and stay quiet for everyone else.
DailyPack _pack({bool levelPlaced = true}) => DailyPack(
      needsLanguage: false,
      dateKey: '2026-09-14',
      weekKey: '2026-W38',
      dayInWeek: 1,
      requestedLevel: 'A2',
      servedLevel: 'A2',
      levelPlaced: levelPlaced,
      theme: const PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
      stations: const [
        PackStation(kind: 'vocabulary', status: StationStatus.todo),
        PackStation(kind: 'grammar', status: StationStatus.todo),
      ],
    );

Widget _host(DailyPack pack, {VoidCallback? onTakePlacement}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DailyPackHeroCard(
          pack: pack,
          mastery: null,
          onOpen: () {},
          onPickLanguage: () {},
          onOpenProgress: () {},
          onTakePlacement: onTakePlacement ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('offers the placement test when the level was never placed',
      (tester) async {
    await tester.pumpWidget(_host(_pack(levelPlaced: false)));
    expect(find.byKey(const Key('hero-take-placement')), findsOneWidget);
  });

  testWidgets('stays quiet once the learner has a level of their own',
      (tester) async {
    await tester.pumpWidget(_host(_pack(levelPlaced: true)));
    expect(find.byKey(const Key('hero-take-placement')), findsNothing);
  });

  testWidgets('tapping it opens the placement test', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(_pack(levelPlaced: false), onTakePlacement: () => taps++),
    );
    await tester.tap(find.byKey(const Key('hero-take-placement')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('levelPlaced round-trips from the server payload', (tester) async {
    expect(
      DailyPack.fromJson(const {'levelPlaced': false, 'dateKey': '2026-09-14'}).levelPlaced,
      false,
    );
    expect(
      DailyPack.fromJson(const {'levelPlaced': true, 'dateKey': '2026-09-14'}).levelPlaced,
      true,
    );
    // An older server that does not send the field must not nag every learner.
    expect(
      DailyPack.fromJson(const {'dateKey': '2026-09-14'}).levelPlaced,
      true,
    );
  });
}
