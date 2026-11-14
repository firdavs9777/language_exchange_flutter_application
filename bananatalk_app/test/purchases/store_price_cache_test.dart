import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/session_prefs.dart';
import 'package:bananatalk_app/services/store_price_cache.dart';

ProductDetails _p(String id, String price, double raw, String code) =>
    ProductDetails(
      id: id,
      title: '',
      description: '',
      price: price,
      rawPrice: raw,
      currencyCode: code,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save then read returns price, currency and raw price per product id',
      () async {
    await StorePriceCache().save([
      _p('vip.monthly', '₩5,500', 5500, 'KRW'),
      _p('coins.small', '₩1,200', 1200, 'KRW'),
    ]);
    final read = await StorePriceCache().read();
    expect(read.keys.toSet(), {'vip.monthly', 'coins.small'});
    expect(read['vip.monthly']!.price, '₩5,500');
    expect(read['vip.monthly']!.currencyCode, 'KRW');
    expect(read['vip.monthly']!.rawPrice, 5500);
    expect(read['coins.small']!.rawPrice, 1200);
  });

  test('nothing saved reads as empty', () async {
    expect(await StorePriceCache().read(), isEmpty);
  });

  test('corrupt JSON reads as empty and a later save repairs it', () async {
    SharedPreferences.setMockInitialValues(
        {StorePriceCache.prefsKey: '{not json'});
    expect(await StorePriceCache().read(), isEmpty);
    await StorePriceCache().save([_p('vip.monthly', '\$3.99', 3.99, 'USD')]);
    final read = await StorePriceCache().read();
    expect(read['vip.monthly']!.price, '\$3.99');
  });

  test('JSON of the wrong shape reads as empty, bad entries are skipped',
      () async {
    SharedPreferences.setMockInitialValues({StorePriceCache.prefsKey: '[1,2]'});
    expect(await StorePriceCache().read(), isEmpty);
    SharedPreferences.setMockInitialValues({
      StorePriceCache.prefsKey:
          '{"a":{"price":"\$1","currencyCode":"USD","rawPrice":1},"b":{"price":3}}'
    });
    expect((await StorePriceCache().read()).keys, ['a']);
  });

  test('saving an empty list keeps what was there', () async {
    await StorePriceCache().save([_p('vip.monthly', '\$3.99', 3.99, 'USD')]);
    await StorePriceCache().save(const []);
    expect((await StorePriceCache().read()).keys, ['vip.monthly']);
    SharedPreferences.setMockInitialValues({});
    await StorePriceCache().save(const []);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(StorePriceCache.prefsKey), isFalse);
  });

  test('a later save merges by id and replaces an entry in another currency',
      () async {
    await StorePriceCache().save([
      _p('vip.monthly', '\$3.99', 3.99, 'USD'),
      _p('vip.yearly', '\$24.99', 24.99, 'USD'),
    ]);
    await StorePriceCache().save([_p('vip.monthly', '₩5,500', 5500, 'KRW')]);
    final read = await StorePriceCache().read();
    expect(read['vip.monthly']!.currencyCode, 'KRW');
    expect(read['vip.monthly']!.price, '₩5,500');
    expect(read['vip.yearly']!.price, '\$24.99', reason: 'others are kept');
  });

  test('a saved price becomes a product with its symbol for the figures', () {
    const saved = SavedPrice(price: '₩5,500', currencyCode: 'KRW', rawPrice: 5500);
    final p = saved.toProductDetails('x');
    expect(p.rawPrice, 5500);
    expect(p.currencyCode, 'KRW');
    expect(p.currencySymbol, '₩');
  });

  test('store_prices_v1 survives clearUserScopedPrefs', () async {
    await StorePriceCache().save([_p('vip.monthly', '\$3.99', 3.99, 'USD')]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('some_user_key', 'x');
    expect(StorePriceCache.prefsKey, 'store_prices_v1');
    expect(kDeviceLevelPrefsKeys, contains('store_prices_v1'));
    await clearUserScopedPrefs(prefs);
    expect(prefs.containsKey('some_user_key'), isFalse);
    expect(prefs.containsKey('store_prices_v1'), isTrue);
    expect((await StorePriceCache().read()).keys, ['vip.monthly']);
  });
}
