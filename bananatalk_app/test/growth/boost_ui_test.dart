import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/pages/coins/boost_screen.dart';
import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/pages/community/card/match_card.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/services/notification_router.dart';

class _FakeBoostClient implements BoostApiClient {
  _FakeBoostClient({this.error});
  final BoostError? error;
  Boost? active;
  int purchases = 0;

  Boost _live() => Boost(
        id: 'b1',
        kind: 'profile',
        startsAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(hours: 23, minutes: 59)),
        impressions: 7,
        coinsSpent: 150,
        status: 'active',
      );

  @override
  Future<Boost> purchaseProfileBoost() async {
    purchases++;
    if (error != null) throw BoostException(error!);
    active = _live();
    return active!;
  }

  @override
  Future<Boost?> getActive() async => active;

  @override
  Future<List<Boost>> getHistory() async => const [];
}

Widget _app(Widget home, List<Override> overrides,
        {List<NavigatorObserver> observers = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        navigatorObservers: observers,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

List<Override> _ov(_FakeBoostClient c) => [
      boostApiClientProvider.overrideWithValue(c),
      coinBalanceProvider.overrideWith((ref) async => 480),
    ];

DailyMatch _match({bool? boosted}) => DailyMatch.fromJson({
      'user': {
        '_id': 'u1',
        'name': 'Minji',
        'native_language': 'Korean',
        'language_to_learn': 'English',
      },
      'matchReasons': ['reciprocal_pair'],
      if (boosted != null) 'boosted': boosted,
    });

class _RouteSpy extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}

void main() {
  testWidgets('BoostScreen shows cost 150 and the balance', (tester) async {
    await tester.pumpWidget(_app(const BoostScreen(), _ov(_FakeBoostClient())));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('150'), findsWidgets);
    expect(find.textContaining('480'), findsOneWidget);
  });

  testWidgets('Confirm purchases once and renders the active state',
      (tester) async {
    final c = _FakeBoostClient();
    await tester.pumpWidget(_app(const BoostScreen(), _ov(c)));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('boost_confirm')));
    await tester.pump();
    await tester.pump();
    expect(c.purchases, 1);
    expect(find.byKey(const ValueKey('boost_active')), findsOneWidget);
    expect(find.text('Seen by 7 people so far'), findsOneWidget);
    expect(find.byKey(const ValueKey('boost_confirm')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink()); // cancel countdown timer
  });

  testWidgets('already boosted on open shows the active state',
      (tester) async {
    final c = _FakeBoostClient()..active = _FakeBoostClient()._live();
    await tester.pumpWidget(_app(const BoostScreen(), _ov(c)));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('boost_active')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('insufficientCoins opens the coin shop', (tester) async {
    final spy = _RouteSpy();
    final c = _FakeBoostClient(error: BoostError.insufficientCoins);
    await tester
        .pumpWidget(_app(const BoostScreen(), _ov(c), observers: [spy]));
    await tester.pump();
    await tester.pump();
    final before = spy.pushed.length;
    await tester.tap(find.byKey(const ValueKey('boost_confirm')));
    await tester.pump();
    await tester.pump();
    expect(spy.pushed.length, greaterThan(before));
    expect(find.byType(CoinShopScreen), findsOneWidget);
  });

  testWidgets('capacityFull shows the capacity message', (tester) async {
    final c = _FakeBoostClient(error: BoostError.capacityFull);
    await tester.pumpWidget(_app(const BoostScreen(), _ov(c)));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('boost_confirm')));
    await tester.pump();
    await tester.pump();
    expect(
      find.text(
          'All boost slots are taken right now — try again in a few hours'),
      findsOneWidget,
    );
  });

  test('DailyMatch.boosted parses and defaults false', () {
    expect(_match(boosted: true).boosted, isTrue);
    expect(_match().boosted, isFalse);
    expect(_match(boosted: false).boosted, isFalse);
  });

  test('Boost.fromJson is tolerant', () {
    final b = Boost.fromJson({
      '_id': 'x',
      'endsAt': '2026-10-03T00:00:00.000Z',
      'impressions': '3',
    });
    expect(b.id, 'x');
    expect(b.impressions, 0);
    expect(b.endsAt, isNotNull);
    expect(Boost.fromJson({}).id, '');
  });

  testWidgets('MatchCard shows Boosted chip only when boosted', (tester) async {
    Widget card(DailyMatch m) => _app(
          Scaffold(
            body: SingleChildScrollView(
              child: MatchCard(
                  match: m, onSayHi: () {}, onWave: () {}, onSkip: () {}),
            ),
          ),
          const [],
        );
    await tester.pumpWidget(card(_match(boosted: true)));
    expect(find.text('Boosted'), findsOneWidget);
    await tester.pumpWidget(card(_match()));
    expect(find.text('Boosted'), findsNothing);
  });

  test('boost_receipt routes to /boost', () {
    expect(NotificationRouter.targetPathForType('boost_receipt', {}), '/boost');
  });
}
