import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool matchesLayout,
  bool rooms = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith(
          (ref) async => AppConfig.fromJson({
            'matchesLayoutEnabled': matchesLayout,
            'roomsEnabled': rooms,
          }),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CommunityMain(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('flag off keeps the legacy 8-tab layout', (tester) async {
    await _pump(tester, matchesLayout: false);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Matches'), findsNothing);
    expect(find.byKey(const Key('community-chip-7')), findsOneWidget);
    expect(find.byKey(const Key('community-chip-8')), findsNothing);
  });

  testWidgets('flag on: Matches first, Gender and City gone', (tester) async {
    await _pump(tester, matchesLayout: true);
    expect(find.text('Matches'), findsOneWidget);
    expect(find.text('Partners'), findsOneWidget);
    expect(find.text('Gender'), findsNothing);
    expect(find.text('City'), findsNothing);
    // Matches · Partners · Gatherings · Rooms · Nearby · Topics · Waves
    expect(find.byKey(const Key('community-chip-6')), findsOneWidget);
    expect(find.byKey(const Key('community-chip-7')), findsNothing);
  });

  testWidgets('flag on without rooms: 6 tabs', (tester) async {
    await _pump(tester, matchesLayout: true, rooms: false);
    expect(find.byKey(const Key('community-chip-5')), findsOneWidget);
    expect(find.byKey(const Key('community-chip-6')), findsNothing);
  });

  group('remapTabIndexForMatchesLayout', () {
    int remap(int i, bool om, bool or, bool nm, bool nr) =>
        remapTabIndexForMatchesLayout(
          previousIndex: i,
          oldMatches: om,
          oldRooms: or,
          newMatches: nm,
          newRooms: nr,
        );

    test('still on first tab when flag turns on -> Matches', () {
      expect(remap(0, false, true, true, true), 0);
    });
    test('Nearby follows identity (legacy 4 -> new 4 with rooms)', () {
      expect(remap(4, false, true, true, true), 4);
    });
    test('Topics: legacy 6 -> new 5', () {
      expect(remap(6, false, true, true, true), 5);
    });
    test('Waves moves with the shorter list', () {
      expect(remap(7, false, true, true, true), 6);
      expect(remap(6, false, false, true, false), 5);
    });
    test('Gender/City fall back to Partners', () {
      expect(remap(1, false, true, true, true), 1);
      expect(remap(5, false, true, true, true), 1);
    });
    test('turning off from Matches lands on All', () {
      expect(remap(0, true, true, false, true), 0);
    });
    test('Gatherings and Rooms keep index 2 / 3 in both layouts', () {
      expect(remap(2, false, true, true, true), 2);
      expect(remap(3, false, true, true, true), 3);
      expect(remap(3, true, true, false, true), 3);
    });
  });
}
