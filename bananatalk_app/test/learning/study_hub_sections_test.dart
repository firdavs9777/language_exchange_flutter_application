import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    testWidgets('not placed -> placement', (t) async {
      var placement = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(placed: false), onOpen: () {},
          onPickLanguage: () {}, onTakePlacement: () => placement = true)));
      await t.tap(find.byType(InkWell).first);
      expect(placement, isTrue);
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

  group('ProgressCard', () {
    testWidgets('Full report calls back', (t) async {
      var tapped = false;
      await t.pumpWidget(app(SingleChildScrollView(
          child: ProgressCard(progress: progress(), onFullReport: () => tapped = true))));
      expect(find.text('Lv 3'), findsOneWidget);
      await t.tap(find.text('Full report'));
      expect(tapped, isTrue);
    });
    testWidgets('no overflow at 320 wide, scale 1.3', (t) async {
      await t.pumpWidget(app(
          SingleChildScrollView(child: ProgressCard(progress: progress(), onFullReport: () {})),
          width: 320, scale: 1.3));
      expect(t.takeException(), isNull);
    });
  });
}
