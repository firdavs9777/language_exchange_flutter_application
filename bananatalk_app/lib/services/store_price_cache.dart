import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store price remembered from an earlier launch, so the plans screen and
/// the coin shop can show a real local price on the first frame instead of
/// waiting for the store to answer.
class SavedPrice {
  const SavedPrice({
    required this.price,
    required this.currencyCode,
    required this.rawPrice,
  });

  final String price;
  final String currencyCode;
  final double rawPrice;

  Map<String, Object> toJson() => {
        'price': price,
        'currencyCode': currencyCode,
        'rawPrice': rawPrice,
      };

  static SavedPrice? fromJson(Object? json) {
    if (json is! Map) return null;
    final price = json['price'];
    final code = json['currencyCode'];
    final raw = json['rawPrice'];
    if (price is! String || price.isEmpty) return null;
    if (code is! String || raw is! num) return null;
    return SavedPrice(
        price: price, currencyCode: code, rawPrice: raw.toDouble());
  }

  /// This price as a [ProductDetails], for the per-month and savings figures
  /// that are written against store products. The symbol is what is left of
  /// [price] once digits and separators are removed ("₩5,500" gives "₩").
  ProductDetails toProductDetails(String id) {
    final symbol = price.replaceAll(RegExp(r'[0-9\s.,  ]'), '');
    return ProductDetails(
      id: id,
      title: '',
      description: '',
      price: price,
      rawPrice: rawPrice,
      currencyCode: currencyCode,
      currencySymbol: symbol.isEmpty ? currencyCode : symbol,
    );
  }
}

/// Last known store prices by product id, in SharedPreferences. Device-level:
/// a price describes the store storefront of this phone, not the account.
class StorePriceCache {
  static const prefsKey = 'store_prices_v1';

  /// Saved prices by product id; empty on missing or corrupt data.
  Future<Map<String, SavedPrice>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, SavedPrice>{};
      decoded.forEach((id, value) {
        final saved = SavedPrice.fromJson(value);
        if (id is String && saved != null) out[id] = saved;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Merges [products] into what is saved, by product id (a later price in
  /// another currency replaces the entry). An empty list changes nothing.
  Future<void> save(Iterable<ProductDetails> products) async {
    if (products.isEmpty) return;
    final merged = await read();
    for (final p in products) {
      merged[p.id] = SavedPrice(
          price: p.price, currencyCode: p.currencyCode, rawPrice: p.rawPrice);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefsKey,
      jsonEncode({for (final e in merged.entries) e.key: e.value.toJson()}),
    );
  }
}

/// Last known store prices, read once per run. App-scoped: see
/// `kAppScopedProviderNames` in session_reset.dart.
final savedStorePricesProvider = FutureProvider<Map<String, SavedPrice>>(
  (ref) => StorePriceCache().read(),
);
