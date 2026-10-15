import 'package:bananatalk_app/services/purchase_restorer.dart';

/// What [PurchaseRedeliveryHandler.handle] did with a transaction.
enum RedeliveryAction {
  verifiedSubscription,
  skippedAlreadyVip,
  verifiedCoinPack,
  verifyFailed,
  ignored,
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
  });

  final Set<String> vipProductIds;
  final Set<String> coinProductIds;

  /// False when signed out — nothing to credit it to yet.
  final bool Function() canVerify;
  final Future<bool> Function() isVipActive;
  final Future<bool> Function(RestoredPurchase) verifySubscription;
  final Future<bool> Function(RestoredPurchase) verifyCoinPack;
  final Future<void> Function(RestoredPurchase) completeCoinPack;
  final void Function()? onVipChanged;
  final void Function()? onCoinsChanged;

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
    if (active) return RedeliveryAction.skippedAlreadyVip;
    final ok = await verifySubscription(purchase);
    if (!ok) return RedeliveryAction.verifyFailed;
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
