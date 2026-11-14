import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/vip_payment_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/store_price_cache.dart';

import '../helpers/community_fixture.dart';

ProductDetails _product(VipPlan plan, String price, double raw, String code) =>
    ProductDetails(
      id: plan.productId(true),
      title: '',
      description: '',
      price: price,
      rawPrice: raw,
      currencyCode: code,
    );

SavedPrice _saved(String price, double raw, String code) =>
    SavedPrice(price: price, currencyCode: code, rawPrice: raw);

List<Override> _overrides({
  required Future<List<ProductDetails>> Function() products,
  Map<String, SavedPrice> saved = const {},
}) =>
    [
      appConfigProvider.overrideWith((ref) async => const AppConfig(
            minVersion: '0.0.0',
            latestVersion: '0.0.0',
            forceUpdate: false,
            iosUrl: '',
            androidUrl: '',
            releaseNotes: '',
            boostsEnabled: false,
          )),
      userProvider.overrideWith((ref) async => communityFixture()),
      androidOwnedVipPlanProvider.overrideWith((ref) async => null),
      iosProductsProvider.overrideWith((ref) => products()),
      savedStorePricesProvider.overrideWith((ref) async => saved),
    ];

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<ProductDetails>> Function() products,
  Map<String, SavedPrice> saved = const {},
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final app = MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const VipPlansScreen(userId: 'me', debugIsIOS: true),
    );
  await tester.pumpWidget(container == null
      ? ProviderScope(
          overrides: _overrides(products: products, saved: saved), child: app)
      : UncontrolledProviderScope(container: container, child: app));
}

void main() {
  final monthlyId = VipPlan.monthly.productId(true);
  final yearlyId = VipPlan.yearly.productId(true);

  testWidgets(
      'plans screen draws plan cards on the first frame while the store is still loading',
      (tester) async {
    final store = Completer<List<ProductDetails>>();
    await _pump(tester, products: () => store.future);
    // First frame, nothing has resolved yet.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('vip-plan-monthly')), findsOneWidget);
    expect(find.byKey(const ValueKey('vip-plan-yearly')), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text(r'$3.99'), findsOneWidget, reason: 'list-price fallback');
    // Still no spinner once the saved prices have been read.
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('plans screen swaps a saved price for the store price when it arrives',
      (tester) async {
    final store = Completer<List<ProductDetails>>();
    await _pump(
      tester,
      products: () => store.future,
      saved: {
        monthlyId: _saved('₩5,500', 5500, 'KRW'),
        yearlyId: _saved('₩39,000', 39000, 'KRW'),
      },
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('₩5,500'), findsOneWidget);
    expect(find.text('₩39,000'), findsOneWidget);
    expect(find.text(r'$3.99'), findsNothing);
    // The per-month figure and the savings badge come from the saved prices.
    expect(find.text('₩5,500 / mo'), findsOneWidget);
    expect(find.textContaining('41%'), findsOneWidget);

    store.complete([
      _product(VipPlan.monthly, '₩5,900', 5900, 'KRW'),
      _product(VipPlan.yearly, '₩42,000', 42000, 'KRW'),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('₩5,900'), findsOneWidget);
    expect(find.text('₩42,000'), findsOneWidget);
    expect(find.text('₩5,500'), findsNothing);
    expect(find.text('₩39,000'), findsNothing);
  });

  testWidgets('with neither store nor saved prices the figures are as before',
      (tester) async {
    final store = Completer<List<ProductDetails>>();
    await _pump(tester, products: () => store.future);
    await tester.pump();
    await tester.pump();
    expect(find.text(r'$24.99'), findsOneWidget);
    expect(find.textContaining('/ mo'), findsNothing,
        reason: 'no per-month guess in USD next to a store price');
  });

  testWidgets(
      'tapping Continue before the store product exists goes to the payment screen, as before',
      (tester) async {
    // Today: the plans screen does not check the store product on Continue;
    // it pushes VipPaymentScreen with the selected plan, and that screen
    // initializes the store, queries again and reports the failure itself.
    await _pump(tester, products: () async => const <ProductDetails>[]);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final pay = tester.widget<VipPaymentScreen>(find.byType(VipPaymentScreen));
    expect(pay.plan, VipPlan.yearly);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('an empty answer held by the provider on open is queried again once',
      (tester) async {
    var calls = 0;
    Future<List<ProductDetails>> store() async {
      calls++;
      return const <ProductDetails>[];
    }

    final container =
        ProviderContainer(overrides: _overrides(products: store));
    addTearDown(container.dispose);
    // An earlier visit left an empty answer in the provider.
    await container.read(iosProductsProvider.future);
    expect(calls, 1);
    await _pump(tester, products: store, container: container);
    await tester.pump();
    await tester.pump();
    expect(calls, 2, reason: 'asked again on open');
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 2, reason: 'once, not a loop');
  });

  testWidgets('a non-empty answer held by the provider on open is kept',
      (tester) async {
    var calls = 0;
    Future<List<ProductDetails>> store() async {
      calls++;
      return [_product(VipPlan.monthly, '₩5,900', 5900, 'KRW')];
    }

    final container =
        ProviderContainer(overrides: _overrides(products: store));
    addTearDown(container.dispose);
    await container.read(iosProductsProvider.future);
    await _pump(tester, products: store, container: container);
    await tester.pump();
    await tester.pump();
    expect(calls, 1);
    expect(find.text('₩5,900'), findsOneWidget);
  });
}
