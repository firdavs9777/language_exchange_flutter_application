import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';

// audit_a #18: the per-month line and the savings % were computed from USD
// constants and printed with a hardcoded '$', next to the store's localized
// price. They must come from the store's own price and currency.

ProductDetails _p(String id, double raw, String code, String symbol,
        String price) =>
    ProductDetails(
      id: id,
      title: id,
      description: '',
      price: price,
      rawPrice: raw,
      currencyCode: code,
      currencySymbol: symbol,
    );

void main() {
  group('vipPerMonthPrice', () {
    test('uses the store currency, never a dollar sign', () {
      final monthly = _p('m', 5500, 'KRW', '₩', '₩5,500');
      final text = vipPerMonthPrice(monthly, 1)!;
      expect(text, contains('₩'));
      expect(text, contains('5,500'));
      expect(text, isNot(contains(r'$')));
    });

    test('divides by the plan length in the store currency', () {
      final quarterly = _p('q', 29.97, 'EUR', '€', '€29.97');
      final text = vipPerMonthPrice(quarterly, 3)!;
      expect(text, contains('€'));
      expect(text, contains('9.99'));
    });

    test('no store details: nothing to show (no USD guess)', () {
      expect(vipPerMonthPrice(null, 1), isNull);
    });
  });

  group('vipSavingsPercent', () {
    test('computed from the store prices of both plans', () {
      final monthly = _p('m', 5500, 'KRW', '₩', '₩5,500');
      final yearly = _p('y', 33000, 'KRW', '₩', '₩33,000');
      // 33000/12 = 2750 per month vs 5500 -> 50%.
      expect(vipSavingsPercent(plan: yearly, monthly: monthly, months: 12), 50);
    });

    test('hidden when either store price is missing', () {
      final monthly = _p('m', 3.99, 'USD', r'$', r'$3.99');
      expect(vipSavingsPercent(plan: null, monthly: monthly, months: 12),
          isNull);
      final yearly = _p('y', 24.99, 'USD', r'$', r'$24.99');
      expect(vipSavingsPercent(plan: yearly, monthly: null, months: 12),
          isNull);
    });

    test('hidden below 5% and for the monthly plan itself', () {
      final monthly = _p('m', 10, 'USD', r'$', r'$10.00');
      final yearly = _p('y', 117, 'USD', r'$', r'$117.00');
      expect(vipSavingsPercent(plan: yearly, monthly: monthly, months: 12),
          isNull);
      expect(vipSavingsPercent(plan: monthly, monthly: monthly, months: 1),
          isNull);
    });

    test('mismatched currencies are not compared', () {
      final monthly = _p('m', 3.99, 'USD', r'$', r'$3.99');
      final yearly = _p('y', 33000, 'KRW', '₩', '₩33,000');
      expect(vipSavingsPercent(plan: yearly, monthly: monthly, months: 12),
          isNull);
    });
  });
}
