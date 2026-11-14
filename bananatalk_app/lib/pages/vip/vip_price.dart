import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/store_price_cache.dart';

/// The store's product for [plan] on this platform, once the store answered.
ProductDetails? vipStoreProduct(
  WidgetRef ref,
  VipPlan plan, {
  required bool isIOS,
  required bool isAndroid,
}) {
  final productsAsync = isIOS
      ? ref.watch(iosProductsProvider)
      : isAndroid
          ? ref.watch(androidProductsProvider)
          : null;
  final id = plan.productId(isIOS);
  for (final p in productsAsync?.valueOrNull ?? const <ProductDetails>[]) {
    if (p.id == id) return p;
  }
  return null;
}

/// The price to show for [plan]: the store's own localized price (what the
/// store will actually charge, e.g. "₩14,000"), else the [saved] price from
/// an earlier launch, else the USD list price.
/// The payment screen used to always show the USD constant, so a Korean
/// account saw ₩14,000 on the plans screen and $3.99 one tap later.
String vipPriceText(
  WidgetRef ref,
  VipPlan plan, {
  required bool isIOS,
  required bool isAndroid,
  SavedPrice? saved,
}) {
  final product = vipStoreProduct(ref, plan, isIOS: isIOS, isAndroid: isAndroid);
  return product?.price ?? saved?.price ?? '\$${plan.price.toStringAsFixed(2)}';
}

/// The saved price of [plan] on this platform, once the cache has been read.
SavedPrice? vipSavedPrice(WidgetRef ref, VipPlan plan, {required bool isIOS}) =>
    ref.watch(savedStorePricesProvider).valueOrNull?[plan.productId(isIOS)];

/// Asks the store again when the products provider holds a failed or empty
/// answer, once: that answer is not kept as the result. Call after the first
/// frame (a provider must not be invalidated while the tree builds).
void retryEmptyProductQuery(
  WidgetRef ref, {
  required bool isIOS,
  required bool isAndroid,
}) {
  if (!isIOS && !isAndroid) return;
  final provider = isIOS ? iosProductsProvider : androidProductsProvider;
  final state = ref.read(provider);
  if (state.hasError || (state.hasValue && state.requireValue.isEmpty)) {
    ref.invalidate(provider);
  }
}
