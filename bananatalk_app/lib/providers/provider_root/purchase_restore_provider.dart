import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/models/coin_pack.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/android_purchase_service.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:bananatalk_app/services/purchase_redelivery.dart';
import 'package:bananatalk_app/services/purchase_restorer.dart';
import 'package:bananatalk_app/services/vip_service.dart';

/// Wires [PurchaseRestorer] and [PurchaseRedeliveryHandler] to the real
/// stores and backend.
///
/// Both send subscriptions through the SAME endpoints a new purchase uses
/// (`POST /purchases/ios/verify`, `POST /purchases/android/verify`), so the
/// server applies its usual checks: receipt/token verification with
/// Apple/Google, the VIP product allow-list, and the one-purchase-one-account
/// claim (a same-user restore passes, another live account gets 409).

/// Billing period of a VIP product, for spotting lapsed iOS subscriptions.
Duration? vipPlanPeriod(String productId) {
  for (final plan in VipPlan.values) {
    if (plan.iosProductId == productId || plan.androidProductId == productId) {
      switch (plan) {
        case VipPlan.monthly:
          return const Duration(days: 31);
        case VipPlan.quarterly:
          return const Duration(days: 92);
        case VipPlan.yearly:
          return const Duration(days: 366);
      }
    }
  }
  return null;
}

String? _currentUserId(WidgetRef ref, String? userId) {
  if (userId != null && userId.isNotEmpty) return userId;
  final id = ref.read(userProvider).valueOrNull?.id;
  return (id == null || id.isEmpty) ? null : id;
}

Future<bool> _isVipActive(String? userId) async {
  if (userId == null) return false;
  final status = await VipService.getVipStatus(userId: userId);
  return status['isVIP'] == true;
}

/// Sends a subscription to the backend verify a new purchase uses.
Future<RestoreVerifyResult> verifySubscriptionWithBackend(
    RestoredPurchase p) async {
  if (p.receipt.isEmpty) {
    return const RestoreVerifyResult.failure('missing receipt');
  }
  final Map<String, dynamic> result = Platform.isIOS
      ? await VipService.verifyIOSPurchase(
          receiptData: p.receipt,
          productId: p.productId,
          transactionId: p.transactionId,
        )
      : await VipService.verifyAndroidPurchase(
          purchaseToken: p.receipt,
          productId: p.productId,
          orderId: p.transactionId,
        );
  return result['success'] == true
      ? const RestoreVerifyResult.success()
      : RestoreVerifyResult.failure(result['error']?.toString());
}

void _refreshVip(WidgetRef ref, String? userId) {
  ref.invalidate(userProvider);
  if (userId != null) {
    ref.invalidate(vipStatusProvider(userId));
    ref.invalidate(userLimitsProvider(userId));
  }
}

/// Runs "Restore Purchases" on this device's store and refreshes VIP state.
Future<RestoreOutcome> restorePurchases(WidgetRef ref, {String? userId}) async {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return RestoreOutcome.failed;
  }
  final uid = _currentUserId(ref, userId);
  final restorer = PurchaseRestorer(
    restore: Platform.isIOS
        ? IOSPurchaseService.restoreAndCollect
        : AndroidPurchaseService.restoreAndCollect,
    vipProductIds: VipPlan.productIdsFor(Platform.isIOS),
    isVipActive: () => _isVipActive(uid),
    verify: verifySubscriptionWithBackend,
    planPeriod: vipPlanPeriod,
    checkExpiry: Platform.isIOS,
  );
  final outcome = await restorer.run();
  if (outcome == RestoreOutcome.restored ||
      outcome == RestoreOutcome.alreadyActive) {
    _refreshVip(ref, uid);
  }
  return outcome;
}

/// Starts listening to the store at launch and routes transactions nobody
/// is waiting for (redeliveries, renewals, deferred purchases, unfinished
/// coin packs) through backend verification. Call once the user is signed
/// in; pass the returned token to [uninstallPurchaseRedelivery] when that
/// screen goes away.
Object? installPurchaseRedelivery(WidgetRef ref) {
  final isIOS = Platform.isIOS;
  if (!isIOS && !Platform.isAndroid) return null;

  final handler = PurchaseRedeliveryHandler(
    vipProductIds: VipPlan.productIdsFor(isIOS),
    coinProductIds: CoinPack.all.map((p) => p.productId(isIOS)).toSet(),
    canVerify: () => _currentUserId(ref, null) != null,
    isVipActive: () => _isVipActive(_currentUserId(ref, null)),
    verifySubscription: (p) async =>
        (await verifySubscriptionWithBackend(p)).success,
    verifyCoinPack: (p) async {
      if (p.receipt.isEmpty) return false;
      // Same idempotency ids as the coin shop: iOS the StoreKit transaction
      // id, Android the purchase token. The server credits each id once.
      final transactionId = isIOS ? (p.transactionId ?? '') : p.receipt;
      if (transactionId.isEmpty) return false;
      final response = await ref.read(coinApiClientProvider).verifyPurchase(
            platform: isIOS ? 'ios' : 'android',
            productId: p.productId,
            receipt: p.receipt,
            transactionId: transactionId,
          );
      // A receipt another account already redeemed is final too: finish it
      // rather than leave it unfinished forever.
      return coinVerifyOutcome(response).finishesPurchase;
    },
    completeCoinPack: (p) async {
      final source = p.source;
      if (source is! PurchaseDetails) return;
      if (isIOS) {
        await IOSPurchaseService.completeCoinPurchase(source);
      } else {
        await AndroidPurchaseService.completeCoinPurchase(source);
      }
    },
    onVipChanged: () => _refreshVip(ref, _currentUserId(ref, null)),
    onCoinsChanged: () => refreshCoinBalance(ref),
  );

  void route(RestoredPurchase p) {
    handler.handle(p);
  }

  if (isIOS) {
    IOSPurchaseService.setRedeliveryHandler(route);
    IOSPurchaseService.initializeStore();
  } else {
    AndroidPurchaseService.setRedeliveryHandler(route);
    AndroidPurchaseService.initializeStore();
  }
  final token = Object();
  _activeRedeliveryToken = token;
  return token;
}

Object? _activeRedeliveryToken;

/// Removes the handler installed with [token]. A no-op when a newer screen
/// has installed its own since (e.g. the tab shell was replaced and the old
/// one is disposed after the new one mounted).
void uninstallPurchaseRedelivery(Object? token) {
  if (token == null || !identical(token, _activeRedeliveryToken)) return;
  _activeRedeliveryToken = null;
  if (Platform.isIOS) {
    IOSPurchaseService.setRedeliveryHandler(null);
  } else if (Platform.isAndroid) {
    AndroidPurchaseService.setRedeliveryHandler(null);
  }
}
