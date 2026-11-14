import 'package:bananatalk_app/services/purchase_restorer.dart';

/// What [PurchaseRedeliveryHandler.handle] did with a transaction.
enum RedeliveryAction {
  verifiedSubscription,
  skippedAlreadyVip,
  verifiedCoinPack,
  verifyFailed,
  ignored,

  /// The server already refused this exact transaction as expired.
  skippedKnownExpired,

  /// The subscription's last period clearly ended; nothing was sent.
  skippedLapsed,
}

/// Handles store transactions that arrive with no purchase call waiting for
/// them: StoreKit redelivering an unfinished transaction at launch, a
/// renewal, a deferred ("pending") purchase that cleared after the purchase
/// call gave up, or an un-consumed coin pack Google Play returns on restore.
///
/// Before this, those were dropped: subscriptions were acknowledged without
/// the backend ever hearing about them (paid, no VIP), and coin packs whose
/// verify had failed were never retried although the UI promised it.
///
/// - Subscription: verified with the same endpoint as a new purchase, but
///   only when the user is not already VIP — the backend extends an active
///   subscription on every verify, so a re-send would grant a free period.
/// - Coin pack: verified with `/coins/verify-purchase`, which credits each
///   store transaction at most once (unique index on the transaction id), and
///   completed/consumed only after that succeeds. A failure leaves it
///   unfinished for the next redelivery.
class PurchaseRedeliveryHandler {
  PurchaseRedeliveryHandler({
    required this.vipProductIds,
    required this.coinProductIds,
    required this.canVerify,
    required this.isVipActive,
    required this.verifySubscription,
    required this.verifyCoinPack,
    required this.completeCoinPack,
    this.onVipChanged,
    this.onCoinsChanged,
    this.verifyWhenVipActive = false,
    this.isKnownExpired,
    this.rememberExpired,
    this.isLapsed,
  });

  final Set<String> vipProductIds;
  final Set<String> coinProductIds;

  /// False when signed out — nothing to credit it to yet.
  final bool Function() canVerify;
  final Future<bool> Function() isVipActive;
  final Future<RestoreVerifyResult> Function(RestoredPurchase)
      verifySubscription;
  final Future<bool> Function(RestoredPurchase) verifyCoinPack;
  final Future<void> Function(RestoredPurchase) completeCoinPack;
  final void Function()? onVipChanged;
  final void Function()? onCoinsChanged;

  /// Android: Play does not redeliver renewals, so a VIP purchase arriving
  /// for an active VIP is a plan switch whose result came after the payment
  /// screen stopped waiting. Verify it, or the server keeps following the
  /// replaced token. Safe since the backend dedupes by order id and takes
  /// the end date from the store (479b2d2).
  final bool verifyWhenVipActive;

  /// Expired-receipt memo (all optional; without them every subscription is
  /// verified as before). A transaction the server refused as expired is not
  /// sent again, and a clearly lapsed one is not sent at all.
  final Future<bool> Function(RestoredPurchase)? isKnownExpired;
  final Future<void> Function(RestoredPurchase)? rememberExpired;
  final bool Function(RestoredPurchase)? isLapsed;

  final Set<String> _inFlight = {};

  Future<RedeliveryAction> handle(RestoredPurchase purchase) async {
    final isCoin = coinProductIds.contains(purchase.productId);
    final isVip = vipProductIds.contains(purchase.productId);
    if (!isCoin && !isVip) return RedeliveryAction.ignored;
    if (!canVerify()) return RedeliveryAction.ignored;

    final key = purchase.transactionId ?? purchase.receipt;
    if (!_inFlight.add(key)) return RedeliveryAction.ignored;
    try {
      return isCoin ? await _handleCoin(purchase) : await _handleSub(purchase);
    } catch (_) {
      return RedeliveryAction.verifyFailed;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<RedeliveryAction> _handleSub(RestoredPurchase purchase) async {
    bool active = false;
    try {
      active = await isVipActive();
    } catch (_) {}
    if (active && !verifyWhenVipActive) return RedeliveryAction.skippedAlreadyVip;
    if (isKnownExpired != null && await isKnownExpired!(purchase)) {
      return RedeliveryAction.skippedKnownExpired;
    }
    if (isLapsed != null && isLapsed!(purchase)) {
      await rememberExpired?.call(purchase);
      return RedeliveryAction.skippedLapsed;
    }
    final result = await verifySubscription(purchase);
    if (!result.success) {
      if (result.expired) await rememberExpired?.call(purchase);
      return RedeliveryAction.verifyFailed;
    }
    onVipChanged?.call();
    return RedeliveryAction.verifiedSubscription;
  }

  Future<RedeliveryAction> _handleCoin(RestoredPurchase purchase) async {
    final ok = await verifyCoinPack(purchase);
    if (!ok) return RedeliveryAction.verifyFailed;
    await completeCoinPack(purchase);
    onCoinsChanged?.call();
    return RedeliveryAction.verifiedCoinPack;
  }
}
