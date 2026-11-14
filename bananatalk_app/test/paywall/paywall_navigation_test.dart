import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_navigation.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';

class _RouteSpy extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}

typedef _Logged = ({String placement, String action, String flowId});

void main() {
  late List<_Logged> logged;

  setUp(() {
    logged = [];
    paywallLogSpy = (flow, action, detail) => logged.add((
      placement: flow.placement,
      action: action,
      flowId: flow.flowId,
    ));
  });
  tearDown(() => paywallLogSpy = null);

  Future<_RouteSpy> pumpLauncher(
    WidgetTester tester,
    void Function(BuildContext) onTap,
  ) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final spy = _RouteSpy();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [coinBalanceProvider.overrideWith((ref) async => 10)],
        child: MaterialApp(
          navigatorObservers: [spy],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              key: const Key('go'),
              onPressed: () => onTap(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    return spy;
  }

  Future<void> tapGo(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('go')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  const flow = PaywallFlow(placement: PaywallPlacement.waveCap, flowId: 'f-1');

  testWidgets('openVipPlans logs cta_vip then plans_viewed with one flow id '
      'and pushes the screen', (tester) async {
    await pumpLauncher(tester, (c) => openVipPlans<void>(c, flow, userId: 'u'));
    await tapGo(tester);
    expect(find.byType(VipPlansScreen), findsOneWidget);
    expect(logged.map((e) => e.action).toList(), [
      PaywallAction.ctaVip,
      PaywallAction.plansViewed,
    ]);
    expect(logged.map((e) => e.flowId).toSet(), {'f-1'});
    expect(logged.map((e) => e.placement).toSet(), {'wave_cap'});
    expect(
      tester.widget<VipPlansScreen>(find.byType(VipPlansScreen)).userId,
      'u',
    );
  });

  testWidgets('openCoinShop logs cta_coins then shop_viewed', (tester) async {
    await pumpLauncher(tester, (c) => openCoinShop<void>(c, flow));
    await tapGo(tester);
    expect(find.byType(CoinShopScreen), findsOneWidget);
    expect(logged.map((e) => e.action).toList(), [
      PaywallAction.ctaCoins,
      PaywallAction.shopViewed,
    ]);
    expect(logged.map((e) => e.flowId).toSet(), {'f-1'});
  });

  testWidgets('logCta: false logs only the viewed event', (tester) async {
    await pumpLauncher(
      tester,
      (c) => openVipPlans<void>(c, flow, logCta: false),
    );
    await tapGo(tester);
    expect(logged.map((e) => e.action).toList(), [PaywallAction.plansViewed]);
  });

  testWidgets('a screen built without a flow reports placement other', (
    tester,
  ) async {
    await pumpLauncher(
      tester,
      (c) => Navigator.of(
        c,
      ).push(MaterialPageRoute<void>(builder: (_) => const VipPlansScreen())),
    );
    await tapGo(tester);
    expect(logged.single.action, PaywallAction.plansViewed);
    expect(logged.single.placement, PaywallPlacement.other);
  });

  testWidgets('PaywallRoute picks the route class', (tester) async {
    late BuildContext ctx;
    final spy = await pumpLauncher(tester, (c) => ctx = c);
    await tester.tap(find.byKey(const Key('go')));
    final base = spy.pushed.length;

    openVipPlans<void>(ctx, flow, route: PaywallRoute.app);
    await tester.pump();
    expect(spy.pushed[base], isA<AppPageRoute<void>>());
    expect(spy.pushed[base], isNot(isA<MaterialPageRoute<void>>()));
    await tester.pump(const Duration(milliseconds: 400));

    openCoinShop<void>(ctx, flow);
    await tester.pump();
    expect(spy.pushed[base + 1], isA<MaterialPageRoute<void>>());
  });

  test('a daily-limit type maps to its placement', () {
    const expected = {
      'moment': PaywallPlacement.momentCap,
      'comments': PaywallPlacement.commentCap,
      'story': PaywallPlacement.storyCap,
      'message': PaywallPlacement.dmCap,
      'profileView': PaywallPlacement.profileViewCap,
      'wave': PaywallPlacement.waveCap,
      'anything': PaywallPlacement.other,
    };
    expected.forEach(
      (limit, placement) =>
          expect(paywallPlacementForLimit(limit), placement, reason: limit),
    );
  });
}
