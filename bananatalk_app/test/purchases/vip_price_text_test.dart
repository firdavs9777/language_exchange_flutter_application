import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/vip_price.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/store_price_cache.dart';

/// The plans screen showed the store price (₩14,000) and the payment screen
/// one tap later the USD constant ($3.99), 2026-10-18. Both read one helper.
void main() {
  Future<String> priceWith(WidgetTester tester, List<ProductDetails> products,
      {bool isIOS = true, SavedPrice? saved}) async {
    late String text;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        iosProductsProvider.overrideWith((ref) async => products),
        androidProductsProvider.overrideWith((ref) async => products),
      ],
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          text = vipPriceText(ref, VipPlan.monthly,
              isIOS: isIOS, isAndroid: !isIOS, saved: saved);
          return Text(text);
        }),
      ),
    ));
    await tester.pumpAndSettle();
    return text;
  }

  ProductDetails monthly(bool isIOS) => ProductDetails(
        id: VipPlan.monthly.productId(isIOS),
        title: 'BananaTalk VIP',
        description: '',
        price: '₩14,000',
        rawPrice: 14000,
        currencyCode: 'KRW',
      );

  testWidgets('the store price wins (what the store charges)', (tester) async {
    expect(await priceWith(tester, [monthly(true)]), '₩14,000');
    expect(await priceWith(tester, [monthly(false)], isIOS: false), '₩14,000');
  });

  testWidgets('no store answer yet: the USD list price', (tester) async {
    expect(await priceWith(tester, const []), '\$3.99');
  });

  const saved = SavedPrice(price: '₩5,500', currencyCode: 'KRW', rawPrice: 5500);

  testWidgets('vipPriceText prefers store over saved', (tester) async {
    expect(await priceWith(tester, [monthly(true)], saved: saved), '₩14,000');
  });

  testWidgets('vipPriceText: no store answer, the saved price', (tester) async {
    expect(await priceWith(tester, const [], saved: saved), '₩5,500');
  });

  testWidgets('vipPriceText: neither store nor saved, the plan fallback',
      (tester) async {
    expect(await priceWith(tester, const []), '\$3.99');
  });

  group('a saved price is only a placeholder until the store answers', () {
    final answered = [monthly(true)]; // non-empty, but not the yearly product
    const yearlyFallback = '\$24.99';

    test('no answer, an error or an empty list: the saved price', () {
      for (final answer in <List<ProductDetails>?>[null, const []]) {
        expect(
            storePriceText(
                id: 'p', answer: answer, saved: saved, fallback: 'fb'),
            '₩5,500');
      }
      expect(savedPlaceholder(null, saved), saved);
      expect(savedPlaceholder(const [], saved), saved);
    });

    test('a non-empty answer containing the product: the store price', () {
      expect(
          storePriceText(
              id: VipPlan.monthly.productId(true),
              answer: answered,
              saved: saved,
              fallback: 'fb'),
          '₩14,000');
    });

    test('a non-empty answer without it: the plan fallback, not the saved',
        () {
      expect(
          storePriceText(
              id: VipPlan.yearly.productId(true),
              answer: answered,
              saved: saved,
              fallback: yearlyFallback),
          yearlyFallback);
      expect(savedPlaceholder(answered, saved), isNull);
    });

    testWidgets('vipPriceText follows the same rule', (tester) async {
      expect(await priceWith(tester, answered, saved: saved), '₩14,000');
    });

    testWidgets('vipPriceText: answered without the plan, fallback not saved',
        (tester) async {
      late String text;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          iosProductsProvider.overrideWith((ref) async => answered),
        ],
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            text = vipPriceText(ref, VipPlan.yearly,
                isIOS: true, isAndroid: false, saved: saved);
            return Text(text);
          }),
        ),
      ));
      await tester.pumpAndSettle();
      expect(text, yearlyFallback);
    });
  });

  testWidgets('vipSavedPrice on a host with no store queries neither store',
      (tester) async {
    var androidBuilt = 0;
    var iosBuilt = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        iosProductsProvider.overrideWith((ref) async {
          iosBuilt++;
          return const <ProductDetails>[];
        }),
        androidProductsProvider.overrideWith((ref) async {
          androidBuilt++;
          return const <ProductDetails>[];
        }),
        savedStorePricesProvider.overrideWith((ref) async => const {}),
      ],
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          vipSavedPrice(ref, VipPlan.monthly, isIOS: false, isAndroid: false);
          return const SizedBox();
        }),
      ),
    ));
    await tester.pumpAndSettle();
    expect(androidBuilt, 0);
    expect(iosBuilt, 0);
  });
}
