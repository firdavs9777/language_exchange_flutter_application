import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/pages/community/widgets/visitor_recall_card.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart';
import 'package:bananatalk_app/pages/profile/visitors_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/offers/offer.dart';
import 'package:bananatalk_app/services/offers/offers_provider.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';
import 'package:bananatalk_app/widgets/vip_upsell_banner.dart';

import '../support/community_fixture.dart';
import '../support/moment_fixture.dart';

typedef _Logged = ({PaywallFlow flow, String action, String? detail});

class _BoostClient implements BoostApiClient {
  @override
  Future<Boost> purchaseProfileBoost() => throw UnimplementedError();
  @override
  Future<Boost?> getActive() async => null;
  @override
  Future<List<Boost>> getHistory() async => const [];
}

class _BuyingBoostClient implements BoostApiClient {
  Boost? active;
  @override
  Future<Boost> purchaseProfileBoost() async => active = Boost(
    id: 'b1',
    kind: 'profile',
    startsAt: DateTime.now(),
    endsAt: DateTime.now().add(const Duration(hours: 23)),
    impressions: 0,
    coinsSpent: 150,
    status: 'active',
  );
  @override
  Future<Boost?> getActive() async => active;
  @override
  Future<List<Boost>> getHistory() async => const [];
}

class _CoinApi extends CoinApiClient {
  @override
  Future<ApiResponse> unlock(String featureKey) async =>
      ApiResponse(success: true, statusCode: 200);
  @override
  Future<int> getBalance() async => 500;
}

final List<Override> _coinOverrides = [
  coinApiClientProvider.overrideWithValue(_CoinApi()),
  coinUnlockCatalogProvider.overrideWith(
    (ref) async => const {
      'who_waved': CoinUnlockEntry(featureKey: 'who_waved', cost: 60, grant: 1),
    },
  ),
  coinBalanceProvider.overrideWith((ref) async => 500),
];

AppConfig _cfg({bool engine = false}) => AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  coinsEnabled: true,
  boostsEnabled: true,
  offerEngineEnabled: engine,
);

OfferGateShow _show(String surface, {String lead = OfferLead.vip}) {
  final offer = Offer(
    id: 'offer-1',
    surface: surface,
    placement: 'vip_entry',
    lead: lead,
    validUntil: DateTime.now().add(const Duration(hours: 1)),
  );
  return OfferGateShow(
    offer,
    PaywallFlow(
      placement: offer.placement,
      flowId: 'flow-1',
      offerId: offer.id,
      detail: surface,
    ),
  );
}

Map<String, dynamic> _visitor(String id) => {
  'user': {'_id': id, 'name': 'Visitor $id', 'imageUrls': <String>[]},
  'lastVisit': '2026-11-14T08:00:00.000Z',
  'visitCount': 1,
};

void main() {
  late List<_Logged> logged;
  List<String> actions() => [for (final l in logged) l.action];

  setUp(() {
    SharedPreferences.setMockInitialValues({'userId': 'me'});
    resetOfferProcessStateForTest();
    logged = [];
    paywallLogSpy = (flow, action, detail) =>
        logged.add((flow: flow, action: action, detail: detail));
  });
  tearDown(() => paywallLogSpy = null);

  Widget host(
    Widget home, {
    Map<String, OfferGate> gates = const {},
    bool engine = false,
    List<Override> extra = const [],
  }) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWith((ref) async => _cfg(engine: engine)),
      offerGateProvider.overrideWith(
        (ref, surface) => gates[surface] ?? const OfferGateLegacy(),
      ),
      authServiceProvider.overrideWith((ref) => AuthService()..userId = 'me'),
      ...extra,
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    ),
  );

  group('visitor recall card', () {
    late List<bool> seenArgs;
    Future<Map<String, dynamic>> fetch({
      required String userId,
      int limit = 20,
      int page = 1,
      bool reveal = false,
      bool seen = false,
    }) async {
      seenArgs.add(seen);
      return {
        'success': true,
        'count': 2,
        'visitors': [_visitor('a'), _visitor('b')],
      };
    }

    setUp(() => seenArgs = []);

    testWidgets('recall card: Hidden draws nothing and requests no visitors',
        (tester) async {
      await tester.pumpWidget(
        host(
          VisitorRecallCard(fetchVisitors: fetch),
          gates: {OfferSurface.visitorRecall: const OfferGateHidden()},
        ),
      );
      await tester.pumpAndSettle();
      expect(seenArgs, isEmpty);
      expect(find.byType(GestureDetector), findsNothing);
      expect(logged, isEmpty);
    });

    testWidgets(
      'recall card: Show logs shown once with offerId and detail visitor_recall, tap logs cta_vip',
      (tester) async {
        await tester.pumpWidget(
          host(
            VisitorRecallCard(fetchVisitors: fetch),
            gates: {OfferSurface.visitorRecall: _show(OfferSurface.visitorRecall)},
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(); // a rebuild must not log again
        expect(find.text('2 people visited your profile'), findsOneWidget);
        expect(actions(), ['shown']);
        expect(logged.single.flow.offerId, 'offer-1');
        expect(logged.single.detail, 'visitor_recall');
        expect(seenArgs, [false], reason: 'the card never sends seen=1');

        await tester.tap(find.text('2 people visited your profile'));
        await tester.pumpAndSettle();
        expect(actions(), ['shown', 'cta_vip']);
        expect(logged[1].flow.flowId, 'flow-1');
        expect(logged[1].flow.offerId, 'offer-1');
        expect(find.byType(ProfileVisitorsScreen), findsOneWidget);
      },
    );

    testWidgets('recall card: lead coins logs cta_coins; avatar taps log nothing',
        (tester) async {
      await tester.pumpWidget(
        host(
          VisitorRecallCard(fetchVisitors: fetch),
          gates: {
            OfferSurface.visitorRecall: _show(
              OfferSurface.visitorRecall,
              lead: OfferLead.coins,
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 people visited your profile'));
      await tester.pumpAndSettle();
      expect(actions(), ['shown', 'cta_coins']);
    });

    testWidgets('recall card: a second card for the same offer logs no second shown',
        (tester) async {
      final gates = {
        OfferSurface.visitorRecall: _show(OfferSurface.visitorRecall),
      };
      await tester.pumpWidget(
        host(VisitorRecallCard(fetchVisitors: fetch), gates: gates),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(const SizedBox(), gates: gates));
      await tester.pumpWidget(
        host(VisitorRecallCard(fetchVisitors: fetch), gates: gates),
      );
      await tester.pumpAndSettle();
      expect(actions(), ['shown']);
    });

    testWidgets('recall card: Legacy fetches and draws as today',
        (tester) async {
      await tester.pumpWidget(host(VisitorRecallCard(fetchVisitors: fetch)));
      await tester.pumpAndSettle();
      expect(seenArgs, [false]);
      expect(find.text('2 people visited your profile'), findsOneWidget);
      await tester.tap(find.text('2 people visited your profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileVisitorsScreen), findsOneWidget);
      expect(logged, isEmpty);
    });
  });

  group('offer flow carried into the next screen', () {
    Future<Map<String, dynamic>> maskedFetch({
      required String userId,
      int limit = 20,
      int page = 1,
      bool reveal = false,
      bool seen = false,
    }) async => {
      'success': true,
      'count': 2,
      'visitors': [
        {'revealed': false, 'lastVisit': '2026-11-14T08:00:00.000Z'},
        {'revealed': false, 'lastVisit': '2026-11-14T07:00:00.000Z'},
      ],
      'maskedCount': 2,
    };

    testWidgets(
      'recall card offer: unlocking visitors logs unlock_succeeded on the offer flow',
      (tester) async {
        await tester.pumpWidget(
          host(
            VisitorRecallCard(fetchVisitors: maskedFetch),
            gates: {OfferSurface.visitorRecall: _show(OfferSurface.visitorRecall)},
            extra: _coinOverrides,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('2 people visited your profile'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileVisitorsScreen), findsOneWidget);
        await tester.tap(find.text('💎60'));
        await tester.pumpAndSettle();
        final unlock = logged.singleWhere((l) => l.action == 'unlock_succeeded');
        expect(unlock.flow.flowId, 'flow-1');
        expect(unlock.flow.offerId, 'offer-1');
        for (final l in logged) {
          expect(l.flow.flowId, 'flow-1', reason: l.action);
        }
      },
    );

    testWidgets(
      'matches empty offer: a boost bought there logs unlock_succeeded on the offer flow',
      (tester) async {
        await tester.pumpWidget(
          host(
            const MatchesTab(),
            gates: {
              OfferSurface.matchesEmpty: _show(
                OfferSurface.matchesEmpty,
                lead: OfferLead.coins,
              ),
            },
            extra: [
              dailyMatchesProvider.overrideWith(
                (ref) async => DailyMatchesResult.fromJson({'matches': []}),
              ),
              boostApiClientProvider.overrideWithValue(_BuyingBoostClient()),
              ..._coinOverrides,
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('matches-empty-boost')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.byKey(const ValueKey('boost_confirm')));
        await tester.pump();
        await tester.pump();
        final unlock = logged.singleWhere((l) => l.action == 'unlock_succeeded');
        expect(unlock.flow.flowId, 'flow-1');
        expect(unlock.flow.offerId, 'offer-1');
        for (final l in logged) {
          expect(l.flow.flowId, 'flow-1', reason: l.action);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });

  group('profile banner and moments chip', () {
    Widget moments(Map<String, OfferGate> gates) => ProviderScope(
      overrides: [
        forYouMomentsProvider.overrideWith(
          () => PagedMomentsFeedNotifier(
            (ref, page) async => MomentsFeedPage(
              [buildMoment(id: 'm1', description: 'moment m1')],
              hasMore: false,
            ),
          ),
        ),
        userProvider.overrideWith((ref) async => buildCommunity()),
        appConfigProvider.overrideWith((ref) async => _cfg()),
        blockedUserIdsProvider.overrideWith((ref) async => <String>{}),
        promptOfDayProvider.overrideWith((ref) async => <String, dynamic>{}),
        offerGateProvider.overrideWith(
          (ref, surface) => gates[surface] ?? const OfferGateLegacy(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MomentsMain(),
      ),
    );

    testWidgets(
      'profile banner and moments chip: Hidden not drawn, Legacy drawn for a non-VIP',
      (tester) async {
        const banner = VipUpsellBanner(userName: 'Ana', isCurrentUserVip: false);
        await tester.pumpWidget(host(banner));
        await tester.pumpAndSettle();
        expect(find.text('Upgrade'), findsOneWidget);

        await tester.pumpWidget(const SizedBox()); // a fresh ProviderScope
        await tester.pumpWidget(
          host(
            banner,
            gates: {OfferSurface.profileBanner: const OfferGateHidden()},
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Upgrade'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(moments(const {}));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('moments-go-vip')), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          moments({OfferSurface.momentsChip: const OfferGateHidden()}),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('moments-go-vip')), findsNothing);
        expect(logged, isEmpty);
      },
    );

    testWidgets('profile banner: Show logs shown and opens plans on the offer flow',
        (tester) async {
      await tester.pumpWidget(
        host(
          const VipUpsellBanner(userName: 'Ana', isCurrentUserVip: false),
          gates: {OfferSurface.profileBanner: _show(OfferSurface.profileBanner)},
        ),
      );
      await tester.pumpAndSettle();
      expect(actions(), ['shown']);
      expect(logged.single.detail, 'profile_banner');
      await tester.tap(find.text('Upgrade'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(actions().take(2), ['shown', 'cta_vip']);
      expect(logged[1].flow.flowId, 'flow-1');
      expect(find.byType(VipPlansScreen), findsOneWidget);
    });

    testWidgets('profile banner: Show for a VIP draws nothing and logs nothing',
        (tester) async {
      await tester.pumpWidget(
        host(
          const VipUpsellBanner(userName: 'Ana', isCurrentUserVip: true),
          gates: {OfferSurface.profileBanner: _show(OfferSurface.profileBanner)},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Upgrade'), findsNothing);
      expect(logged, isEmpty);
    });

    testWidgets('moments chip: Show logs shown once with detail moments_chip',
        (tester) async {
      await tester.pumpWidget(
        moments({OfferSurface.momentsChip: _show(OfferSurface.momentsChip)}),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('moments-go-vip')), findsOneWidget);
      expect(actions(), ['shown']);
      expect(logged.single.flow.offerId, 'offer-1');
      expect(logged.single.detail, 'moments_chip');
    });
  });

  group('matches empty', () {
    Widget matches(Map<String, OfferGate> gates) => host(
      const MatchesTab(),
      gates: gates,
      extra: [
        dailyMatchesProvider.overrideWith(
          (ref) async => DailyMatchesResult.fromJson({'matches': []}),
        ),
        boostApiClientProvider.overrideWithValue(_BoostClient()),
      ],
    );

    testWidgets('matches empty: Legacy draws both buttons as today',
        (tester) async {
      await tester.pumpWidget(matches(const {}));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('matches-empty-boost')), findsOneWidget);
      expect(find.byKey(const Key('matches-empty-vip')), findsOneWidget);
      expect(logged, isEmpty);
    });

    testWidgets('matches empty: Hidden keeps the empty state but drops both buttons',
        (tester) async {
      await tester.pumpWidget(
        matches({OfferSurface.matchesEmpty: const OfferGateHidden()}),
      );
      await tester.pumpAndSettle();
      expect(find.text("That's everyone for today"), findsOneWidget);
      expect(find.byKey(const Key('matches-empty-boost')), findsNothing);
      expect(find.byKey(const Key('matches-empty-vip')), findsNothing);
      expect(logged, isEmpty);
    });

    testWidgets('matches empty: lead coins logs cta_coins on the Boost tap',
        (tester) async {
      await tester.pumpWidget(
        matches({
          OfferSurface.matchesEmpty: _show(
            OfferSurface.matchesEmpty,
            lead: OfferLead.coins,
          ),
        }),
      );
      await tester.pumpAndSettle();
      expect(actions(), ['shown']);
      expect(logged.single.detail, 'matches_empty');
      await tester.tap(find.byKey(const Key('matches-empty-boost')));
      await tester.pump();
      expect(actions().take(2), ['shown', 'cta_coins']);
      expect(logged[1].flow.offerId, 'offer-1');
      expect(logged[1].flow.flowId, 'flow-1');
      // Leave the boost screen (its own ticker / requests) behind.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('matches empty: the VIP tap opens plans on the offer flow',
        (tester) async {
      await tester.pumpWidget(
        matches({OfferSurface.matchesEmpty: _show(OfferSurface.matchesEmpty)}),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('matches-empty-vip')));
      await tester.pump();
      expect(actions().take(2), ['shown', 'cta_vip']);
      expect(logged[1].flow.flowId, 'flow-1');
    });
  });

  group('visitors screen', () {
    testWidgets('visitors screen sends seen=1 only with the engine on',
        (tester) async {
      final seenArgs = <bool>[];
      Future<Map<String, dynamic>> fetch({
        required String userId,
        int limit = 20,
        int page = 1,
        bool reveal = false,
        bool seen = false,
      }) async {
        seenArgs.add(seen);
        return {'success': true, 'visitors': [_visitor('a')]};
      }

      await tester.pumpWidget(
        host(ProfileVisitorsScreen(userId: 'me', fetchVisitors: fetch)),
      );
      await tester.pumpAndSettle();
      expect(seenArgs, [false]);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        host(
          ProfileVisitorsScreen(userId: 'me', fetchVisitors: fetch),
          engine: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(seenArgs, [false, true]);
    });
  });
}
