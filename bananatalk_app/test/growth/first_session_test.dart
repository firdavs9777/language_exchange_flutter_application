import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/partner_discovery_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/nearby_tab.dart';
import 'package:bananatalk_app/pages/community/gatherings/gatherings_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/waves_tab.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/widgets/notifications/notification_priming_sheet.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/services/notification_permission.dart';

Future<ProviderContainer> _pump(WidgetTester tester,
    {required bool matchesLayout,
    int pending = communityMatchesSubTab,
    bool rooms = true,
    Duration delay = Duration.zero}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith(
          (ref) async {
            if (delay > Duration.zero) await Future<void>.delayed(delay);
            return AppConfig.fromJson({
              'matchesLayoutEnabled': matchesLayout,
              'roomsEnabled': rooms,
            });
          },
        ),
        dailyMatchesProvider.overrideWith(
          (ref) async => DailyMatchesResult.fromJson({'matches': []}),
        ),
        communityPendingSubTabProvider.overrideWith((ref) => pending),
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
  await tester.pump(const Duration(milliseconds: 100));
  // Not pumpAndSettle: other tabs (spinners) never go idle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  return ProviderScope.containerOf(tester.element(find.byType(CommunityMain)));
}

class _FakeCommunity implements CommunityService {
  _FakeCommunity(this.waves);
  final List<Wave> waves;
  @override
  Future<List<Wave>> getWavesReceived({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    bool archive = false,
    bool reveal = false,
  }) async =>
      waves;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _wrapTab(Widget child, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

Map<String, dynamic> _matchJson() => {
      'matches': [
        {
          'user': {
            '_id': 'u1',
            'name': 'Minji',
            'native_language': 'Korean',
            'language_to_learn': 'English',
          },
          'matchReasons': ['reciprocal_pair'],
          'reciprocal': true,
        },
      ],
    };

void main() {
  testWidgets('flag on + matches sub-tab request -> MatchesTab visible',
      (tester) async {
    await _pump(tester, matchesLayout: true);
    expect(find.byType(MatchesTab), findsOneWidget);
    expect(find.byType(PartnerDiscoveryTab), findsNothing);
  });

  testWidgets('pre-set pending sub-tab is consumed on mount (flag on)',
      (tester) async {
    final c = await _pump(tester,
        matchesLayout: true, pending: communityGatheringsSubTab);
    expect(find.byType(MatchesTab), findsNothing);
    expect(c.read(communityPendingSubTabProvider), isNull);
  });

  testWidgets('pending Waves survives a late-resolving config (flag on)',
      (tester) async {
    // Matches layout + rooms: Matches, Partners, Gatherings, Rooms, Nearby,
    // Topics, Waves -> Waves is index 6.
    final c = await _pump(tester,
        matchesLayout: true,
        pending: 6,
        delay: const Duration(milliseconds: 300));
    expect(find.byType(WavesTab), findsOneWidget);
    expect(c.read(communityPendingSubTabProvider), isNull);
  });

  testWidgets('pending Waves with flag off (legacy index 7)', (tester) async {
    final c = await _pump(tester,
        matchesLayout: false,
        pending: 7,
        delay: const Duration(milliseconds: 300));
    expect(find.byType(WavesTab), findsOneWidget);
    expect(c.read(communityPendingSubTabProvider), isNull);
  });

  testWidgets('pending Rooms with rooms disabled lands on the slot-2 tab',
      (tester) async {
    final c = await _pump(tester,
        matchesLayout: true,
        rooms: false,
        pending: communityRoomsSubTab,
        delay: const Duration(milliseconds: 300));
    expect(find.byType(NearbyTab), findsNothing);
    expect(find.byType(GatheringsTab), findsOneWidget);
    expect(c.read(communityPendingSubTabProvider), isNull);
  });

  testWidgets('MatchesTab primes exactly once after a non-empty load',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_wrapTab(
      MatchesTab(primeNotifications: (_) async => calls++),
      [
        selectedTabProvider.overrideWith((ref) => 1),
        dailyMatchesProvider.overrideWith(
            (ref) async => DailyMatchesResult.fromJson(_matchJson())),
      ],
    ));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('MatchesTab does not prime while Community is hidden; primes '
      'once when the user switches to it', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_wrapTab(
      MatchesTab(primeNotifications: (_) async => calls++),
      [
        selectedTabProvider.overrideWith((ref) => 0),
        dailyMatchesProvider.overrideWith(
            (ref) async => DailyMatchesResult.fromJson(_matchJson())),
      ],
    ));
    await tester.pumpAndSettle();
    expect(calls, 0);

    final c = ProviderScope.containerOf(tester.element(find.byType(MatchesTab)));
    c.read(selectedTabProvider.notifier).state = 1;
    await tester.pumpAndSettle();
    expect(calls, 1);

    c.read(selectedTabProvider.notifier).state = 0;
    await tester.pumpAndSettle();
    c.read(selectedTabProvider.notifier).state = 1;
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('MatchesTab does not prime after an empty load', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_wrapTab(
      MatchesTab(primeNotifications: (_) async => calls++),
      [
        selectedTabProvider.overrideWith((ref) => 1),
        dailyMatchesProvider.overrideWith(
            (ref) async => DailyMatchesResult.fromJson({'matches': []})),
      ],
    ));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  for (final n in [1, 0]) {
    testWidgets('WavesTab primes ${n == 1 ? 'once' : 'never'} with $n waves',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(_wrapTab(
        WavesTab(primeNotifications: (_) async => calls++),
        [
          communityServiceProvider.overrideWithValue(_FakeCommunity([
            for (var i = 0; i < n; i++)
              Wave.fromJson({'waveId': 'w$i', 'isRead': true}),
          ]) as CommunityService),
        ],
      ));
      await tester.pumpAndSettle();
      expect(calls, n);
    });
  }

  group('PrimeGate', () {
    test('second entry is refused until exit', () {
      final g = PrimeGate();
      expect(g.tryEnter(), isTrue);
      expect(g.tryEnter(), isFalse);
      g.exit();
      expect(g.tryEnter(), isTrue);
    });
  });

  testWidgets('flag off + same request -> legacy index 0 is Partners',
      (tester) async {
    await _pump(tester, matchesLayout: false);
    expect(find.byType(PartnerDiscoveryTab), findsOneWidget);
    expect(find.byType(MatchesTab), findsNothing);
  });

  group('homeRouteForNewUser', () {
    test('flag on -> Community tab', () {
      expect(homeRouteForNewUser(matchesLayoutEnabled: true), '/tabs/1');
    });
    test('flag off -> today\'s /home', () {
      expect(homeRouteForNewUser(matchesLayoutEnabled: false), '/home');
    });
  });

  group('shouldPrimeNotifications', () {
    test('only ask / upgrade prime', () {
      expect(shouldPrimeNotifications(NotificationAction.ask), isTrue);
      expect(shouldPrimeNotifications(NotificationAction.upgrade), isTrue);
    });
    test('none / recover / null never prime', () {
      expect(shouldPrimeNotifications(NotificationAction.none), isFalse);
      expect(shouldPrimeNotifications(NotificationAction.recover), isFalse);
      expect(shouldPrimeNotifications(null), isFalse);
    });
  });
}
