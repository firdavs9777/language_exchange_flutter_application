import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/services/vip_service.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// FutureProvider for VIP status
final vipStatusProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    return await VipService.getVipStatus(userId: userId);
  },
);

/// FutureProvider for iOS products
final iosProductsProvider = FutureProvider<List<ProductDetails>>(
  (ref) async {
    await IOSPurchaseService.initializeStore();
    await IOSPurchaseService.loadProducts();
    return IOSPurchaseService.getProducts();
  },
);

/// StateProvider for purchase flow state
final purchaseStateProvider = StateProvider<PurchaseState>(
  (ref) => PurchaseState.idle,
);

/// Purchase state enum
enum PurchaseState {
  idle,
  loading,
  purchasing,
  verifying,
  success,
  error,
}

/// StateProvider for purchase error message
final purchaseErrorProvider = StateProvider<String?>((ref) => null);

/// Helper provider to check if user is VIP
final isVipProvider = Provider.family<bool, String>(
  (ref, userId) {
    final vipStatusAsync = ref.watch(vipStatusProvider(userId));
    return vipStatusAsync.valueOrNull?['isVIP'] ?? false;
  },
);

/// Helper provider to get VIP subscription
final vipSubscriptionProvider = Provider.family<VipSubscription?, String>(
  (ref, userId) {
    final vipStatusAsync = ref.watch(vipStatusProvider(userId));
    return vipStatusAsync.valueOrNull?['vipSubscription'] as VipSubscription?;
  },
);

/// Helper provider to get VIP features
final vipFeaturesProvider = Provider.family<VipFeatures?, String>(
  (ref, userId) {
    final vipStatusAsync = ref.watch(vipStatusProvider(userId));
    return vipStatusAsync.valueOrNull?['vipFeatures'] as VipFeatures?;
  },
);

