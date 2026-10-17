import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/vip_price.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';

/// The plans screen showed the store price (₩14,000) and the payment screen
/// one tap later the USD constant ($3.99), 2026-10-18. Both read one helper.
void main() {
  Future<String> priceWith(WidgetTester tester, List<ProductDetails> products,
      {bool isIOS = true}) async {
    late String text;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        iosProductsProvider.overrideWith((ref) async => products),
        androidProductsProvider.overrideWith((ref) async => products),
      ],
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          text = vipPriceText(ref, VipPlan.monthly, isIOS: isIOS, isAndroid: !isIOS);
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
}
