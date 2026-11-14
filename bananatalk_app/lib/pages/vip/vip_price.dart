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

/// A saved price is only a placeholder until the store answers. Once the
/// store has answered with a non-empty product list it is dropped: a product
/// missing from that list falls back to the plan price as before, never to
/// an old saved price. With no answer yet, an error or an empty list, [saved]
/// stays. The one rule for the plans screen, payment screen and coin shop.
SavedPrice? savedPlaceholder(List<ProductDetails>? answer, SavedPrice? saved) =>
    (answer != null && answer.isNotEmpty) ? null : saved;

/// Price text for product [id]: the store's price, else the [saved]
/// placeholder (see [savedPlaceholder]), else [fallback].
String storePriceText({
  required String id,
  required List<ProductDetails>? answer,
  required SavedPrice? saved,
  required String fallback,
}) {
  for (final p in answer ?? const <ProductDetails>[]) {
    if (p.id == id) return p.price;
  }
  return savedPlaceholder(answer, saved)?.price ?? fallback;
}

/// The price to show for [plan]: the store's own localized price (what the
/// store will actually charge, e.g. "₩14,000"), else the saved price from an
/// earlier launch while the store has not answered, else the USD list price.
/// [saved] is looked up from the cache when not given.
/// The payment screen used to always show the USD constant, so a Korean
/// account saw ₩14,000 on the plans screen and $3.99 one tap later.
String vipPriceText(
  WidgetRef ref,
  VipPlan plan, {
  required bool isIOS,
  required bool isAndroid,
  SavedPrice? saved,
}) {
  final answer = isIOS
      ? ref.watch(iosProductsProvider).valueOrNull
      : isAndroid
          ? ref.watch(androidProductsProvider).valueOrNull
          : null;
  return storePriceText(
    id: plan.productId(isIOS),
    answer: answer,
    saved: saved ?? ref.watch(savedStorePricesProvider).valueOrNull?[plan.productId(isIOS)],
    fallback: '\$${plan.price.toStringAsFixed(2)}',
  );
}

/// The saved price of [plan] to show as a placeholder: null once the store
/// has answered (see [savedPlaceholder]).
SavedPrice? vipSavedPrice(
  WidgetRef ref,
  VipPlan plan, {
  required bool isIOS,
  required bool isAndroid,
}) {
  // A host with neither store (desktop, tests) queries neither.
  final answer = isIOS
      ? ref.watch(iosProductsProvider).valueOrNull
      : isAndroid
          ? ref.watch(androidProductsProvider).valueOrNull
          : null;
  return savedPlaceholder(answer,
      ref.watch(savedStorePricesProvider).valueOrNull?[plan.productId(isIOS)]);
}

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
