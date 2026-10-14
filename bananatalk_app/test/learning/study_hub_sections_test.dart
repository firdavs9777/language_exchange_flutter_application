import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/pages/learning/main/sections/progress_card.dart';
import 'package:bananatalk_app/pages/learning/main/sections/spotlight_carousel.dart';
import 'package:bananatalk_app/pages/learning/main/sections/today_pack_row.dart';

Widget app(Widget child, {double width = 400, double scale = 1.0}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child),
        ),
      ),
    );

DailyPack pack({bool needsLanguage = false, bool placed = true, bool complete = false}) => DailyPack(
      needsLanguage: needsLanguage,
      dateKey: '2026-10-14',
      weekKey: '2026-W42',
      dayInWeek: 2,
      theme: const PackTheme(id: 'p', topic: 'Travel', level: 'beginner'),
      stations: const [PackStation(kind: 'grammar', status: StationStatus.todo)],
      packComplete: complete,
      levelPlaced: placed,
    );

LearningProgress progress() => LearningProgress.fromJson({
      'totalXP': 120,
      'level': 3,
      'currentStreak': 5,
      'dailyXP': 20,
      'dailyGoal': 50,
    });

void main() {
  group('spotlightItems', () {
    Announcement a(String id) => Announcement.fromJson({'id': id, 'title': 't$id', 'body': ''});
    test('drops dismissed, keeps order, max 3', () {
      final all = [a('1'), a('2'), a('3'), a('4'), a('5')];
      expect(spotlightItems(all, {'2'}).map((x) => x.id), ['1', '3', '4']);
    });
  });

  group('TodayPackRow', () {
    testWidgets('normal: topic + Start', (t) async {
      var opened = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(), onOpen: () => opened = true,
          onPickLanguage: () {}, onTakePlacement: () {})));
      expect(find.text('Travel'), findsOneWidget);
      await t.tap(find.text('Start'));
      expect(opened, isTrue);
    });
    testWidgets('needs language -> picker prompt', (t) async {
      var picked = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(needsLanguage: true), onOpen: () {},
          onPickLanguage: () => picked = true, onTakePlacement: () {})));
      await t.tap(find.byType(InkWell).first);
      expect(picked, isTrue);
    });
    testWidgets('not placed -> can open the pack AND reach placement', (t) async {
      var placement = false, opened = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(placed: false), onOpen: () => opened = true,
          onPickLanguage: () {}, onTakePlacement: () => placement = true)));
      await t.tap(find.text('Start'));
      expect(opened, isTrue);
      await t.tap(find.byKey(const Key('today-take-placement')));
      expect(placement, isTrue);
    });
    testWidgets('needsLanguage beats unplaced', (t) async {
      var picked = false, placement = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(needsLanguage: true, placed: false),
          onOpen: () {}, onPickLanguage: () => picked = true,
          onTakePlacement: () => placement = true)));
      expect(find.byKey(const Key('today-take-placement')), findsNothing);
      await t.tap(find.byType(InkWell).first);
      expect(picked, isTrue);
      expect(placement, isFalse);
    });
    testWidgets('empty pack -> todayEmpty, no Start', (t) async {
      const empty = DailyPack(needsLanguage: false, dateKey: 'd', weekKey: 'w', dayInWeek: 1);
      await t.pumpWidget(app(TodayPackRow(pack: empty, onOpen: () {},
          onPickLanguage: () {}, onTakePlacement: () {})));
      expect(find.text("Today's items are still being prepared. Check back soon."), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
    testWidgets('all stations done (next == null) -> done', (t) async {
      const donePack = DailyPack(
        needsLanguage: false, dateKey: 'd', weekKey: 'w', dayInWeek: 1,
        theme: PackTheme(id: 'p', topic: 'Travel', level: 'beginner'),
        stations: [PackStation(kind: 'grammar', status: StationStatus.done)],
      );
      await t.pumpWidget(app(TodayPackRow(pack: donePack, onOpen: () {},
          onPickLanguage: () {}, onTakePlacement: () {})));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
    testWidgets('unplaced + 320/1.3: no overflow', (t) async {
      await t.pumpWidget(app(
          TodayPackRow(pack: pack(placed: false), onOpen: () {}, onPickLanguage: () {},
              onTakePlacement: () {}),
          width: 320, scale: 1.3));
      expect(t.takeException(), isNull);
    });
    testWidgets('complete -> done, opens review', (t) async {
      var opened = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(complete: true), onOpen: () => opened = true,
          onPickLanguage: () {}, onTakePlacement: () {})));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await t.tap(find.byType(InkWell).first);
      expect(opened, isTrue);
    });
    testWidgets('no overflow at 320 wide, scale 1.3', (t) async {
      await t.pumpWidget(app(
          TodayPackRow(pack: pack(), onOpen: () {}, onPickLanguage: () {}, onTakePlacement: () {}),
          width: 320, scale: 1.3));
      expect(t.takeException(), isNull);
    });
  });

  group('SpotlightCarousel', () {
    testWidgets('renders nothing while config never loads', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWith((ref) => Completer<AppConfig?>().future),
          spotlightDismissedProvider.overrideWith((ref) => Completer<Set<String>>().future),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SpotlightCarousel()),
        ),
      ));
      expect(find.byType(PageView), findsNothing);
    });
  });

  group('SpotlightCarousel content', () {
    AppConfig cfg(List<Announcement> a) => AppConfig(
          minVersion: '1.0.0', latestVersion: '1.0.0', forceUpdate: false,
          iosUrl: '', androidUrl: '', releaseNotes: '', announcements: a);
    final anns = [
      Announcement.fromJson({
        'id': 'a1',
        'title': 'A very long announcement title that wraps over several lines on a narrow phone',
        'body': 'b',
        'emoji': '🎉',
        'buttonLabel': 'Check it out now please',
        'buttonUrl': 'https://example.com',
      }),
      Announcement.fromJson({'id': 'a2', 'title': 'Second', 'body': 'b'}),
    ];
    Widget host({double width = 320, double scale = 1.3}) => ProviderScope(
          overrides: [appConfigProvider.overrideWith((ref) async => cfg(anns))],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
              child: const Scaffold(body: SpotlightCarousel()),
            ),
          ),
        );

    testWidgets('no overflow at 320 wide, scale 1.3', (t) async {
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(host());
      await t.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('dismiss removes the card and stores the id', (t) async {
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(host(width: 400, scale: 1.0));
      await t.pumpAndSettle();
      expect(find.textContaining('A very long'), findsOneWidget);
      await t.tap(find.byIcon(Icons.close_rounded));
      await t.pumpAndSettle();
      expect(find.textContaining('A very long'), findsNothing);
      expect(await SpotlightDismissStore.read(), {'a1'});
    });
  });

  group('ProgressCard', () {
    testWidgets('Full report calls back', (t) async {
      var tapped = false;
      await t.pumpWidget(app(SingleChildScrollView(
          child: ProgressCard(progress: progress(), onFullReport: () => tapped = true))));
      expect(find.text('Lv 3'), findsOneWidget);
      await t.tap(find.text('Full report'));
      expect(tapped, isTrue);
    });
    testWidgets('null progress: placeholder stats, chips still reachable', (t) async {
      var tapped = false;
      await t.pumpWidget(app(SingleChildScrollView(
          child: ProgressCard(progress: null, onFullReport: () => tapped = true))));
      expect(find.text('Your progress'), findsOneWidget);
      expect(find.text('–'), findsWidgets);
      expect(find.text('Achievements'), findsOneWidget);
      await t.tap(find.text('Full report'));
      expect(tapped, isTrue);
    });
    testWidgets('null progress: no overflow at 320 wide, scale 1.3', (t) async {
      await t.pumpWidget(app(
          SingleChildScrollView(child: ProgressCard(progress: null, onFullReport: () {})),
          width: 320, scale: 1.3));
      expect(t.takeException(), isNull);
    });
    testWidgets('no overflow at 320 wide, scale 1.3', (t) async {
      await t.pumpWidget(app(
          SingleChildScrollView(child: ProgressCard(progress: progress(), onFullReport: () {})),
          width: 320, scale: 1.3));
      expect(t.takeException(), isNull);
    });
  });
}
