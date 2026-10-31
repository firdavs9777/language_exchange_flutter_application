import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/pages/community/gatherings/gatherings_tab.dart';
import 'package:bananatalk_app/pages/community/waves/waves_screen.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/pages/community/partners/partner_query.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required bool matchesLayout,
  bool rooms = true,
  CommunityDestination? pending,
  int wavesUnread = 0,
}) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (pending != null)
          communityPendingSubTabProvider.overrideWith((ref) => pending),
        wavesUnreadProvider.overrideWith((ref) async => wavesUnread),
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
        home: _Capture(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  container = ProviderScope.containerOf(
    tester.element(find.byType(CommunityMain, skipOffstage: false)),
  );
  return container;
}

class _Capture extends StatelessWidget {
  const _Capture();
  @override
  Widget build(BuildContext context) => const CommunityMain();
}

/// Community is four tabs (2026-10-31): Matches (flag) · Partners · Clubs ·
/// Rooms (flag). Nearby/City/Gender/Topics are Partners chips; Waves is a
/// header icon. Deep links name a destination, not an index.
void main() {
  group('communityTabLayout', () {
    const m = CommunityTabId.matches,
        p = CommunityTabId.partners,
        c = CommunityTabId.clubs,
        r = CommunityTabId.rooms;
    test('the four flag combinations', () {
      expect(communityTabLayout(matchesLayout: false, rooms: true), [p, c, r]);
      expect(communityTabLayout(matchesLayout: false, rooms: false), [p, c]);
      expect(communityTabLayout(matchesLayout: true, rooms: true), [m, p, c, r]);
      expect(communityTabLayout(matchesLayout: true, rooms: false), [m, p, c]);
    });

    test('a missing tab falls back: Matches -> Partners, Rooms -> Clubs', () {
      expect(indexOfTab(m, matchesLayout: false, rooms: true), 0);
      expect(indexOfTab(r, matchesLayout: false, rooms: false), 1);
      expect(indexOfTab(r, matchesLayout: true, rooms: true), 3);
    });
  });

  testWidgets('flag off: Partners · Clubs · Rooms, a waves icon', (tester) async {
    await _pump(tester, matchesLayout: false);
    expect(find.text('Partners'), findsOneWidget);
    expect(find.text('Matches'), findsNothing);
    expect(find.text('Gender'), findsNothing);
    expect(find.text('City'), findsNothing);
    expect(find.byKey(const Key('community-chip-2')), findsOneWidget);
    expect(find.byKey(const Key('community-chip-3')), findsNothing);
    expect(find.byKey(const Key('community-waves-button')), findsOneWidget);
  });

  testWidgets('flag on without rooms: Matches · Partners · Clubs', (tester) async {
    await _pump(tester, matchesLayout: true, rooms: false);
    expect(find.text('Matches'), findsOneWidget);
    expect(find.byKey(const Key('community-chip-2')), findsOneWidget);
    expect(find.byKey(const Key('community-chip-3')), findsNothing);
  });

  testWidgets('a waves destination opens the waves screen and is consumed',
      (tester) async {
    final c = await _pump(tester,
        matchesLayout: false, pending: CommunityDestination.waves);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(WavesScreen), findsOneWidget);
    expect(c.read(communityPendingSubTabProvider), isNull);
  });

  testWidgets('a rooms destination with rooms off lands on Clubs',
      (tester) async {
    final c = await _pump(tester,
        matchesLayout: false, rooms: false, pending: CommunityDestination.rooms);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(GatheringsTab), findsOneWidget);
    expect(c.read(communityPendingSubTabProvider), isNull);
  });

  testWidgets('the waves icon shows the unread count', (tester) async {
    await _pump(tester, matchesLayout: false, wavesUnread: 3);
    expect(
      find.descendant(
        of: find.byKey(const Key('community-waves-button')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  // Final review: with search open, turning Nearby on hid the close button
  // but left the search bar (which Nearby ignores) stuck open.
  testWidgets('turning Nearby on closes an open search', (tester) async {
    final c = await _pump(tester, matchesLayout: false);
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TextField), findsOneWidget);
    c.read(partnerQuickChipsProvider.notifier).state =
        const PartnerQuickChips(nearby: true);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(TextField), findsNothing);
  });
}
