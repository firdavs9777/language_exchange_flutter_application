/// Android VIP plan switching — the platform-neutral part.
///
/// On Google Play each VIP plan is its own subscription product, so a VIP
/// who buys a second plan the plain way pays for two subscriptions. A plan
/// change has to go through Play's replacement flow instead: the purchase
/// names the subscription it replaces (its purchase token) and a
/// replacement mode. `AndroidPurchaseService.switchVipPlanAndWait` does
/// that; this file decides when it is offered and with which mode.
///
/// iOS needs none of this: the VIP plans share one subscription group, and
/// StoreKit turns a purchase of another plan in the group into a switch.
library;

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import 'package:bananatalk_app/models/vip_subscription.dart';

/// Billing period of [plan], in months. A longer period is an upgrade.
int vipPlanMonths(VipPlan plan) {
  switch (plan) {
    case VipPlan.monthly:
      return 1;
    case VipPlan.quarterly:
      return 3;
    case VipPlan.yearly:
      return 12;
  }
}

/// The plan a Google Play product id belongs to, or null for anything else
/// (coin packs, unknown products).
VipPlan? vipPlanForAndroidProduct(String productId) {
  for (final plan in VipPlan.values) {
    if (plan.androidProductId == productId) return plan;
  }
  return null;
}

/// How Google Play should replace [from] with [to].
///
/// - To a longer period (monthly -> yearly): [ReplacementMode.chargeFullPrice].
///   The new plan starts now, the user pays its full price now and keeps the
///   unused time of the old plan on top. `chargeProratedPrice` is not usable
///   here: Play only allows it when the price per unit of time goes up, and
///   yearly is cheaper per month than monthly. `withTimeProration` would
///   start the yearly plan without a charge and bill weeks later, which reads
///   as "nothing happened" on a button that says Switch.
/// - To a shorter period (yearly -> monthly): [ReplacementMode.deferred].
///   The user keeps the period they already paid for; the new plan starts and
///   is first charged when it ends. Nothing is refunded or prorated, and VIP
///   never lapses in between.
ReplacementMode vipReplacementMode({
  required VipPlan from,
  required VipPlan to,
}) {
  return vipPlanMonths(to) > vipPlanMonths(from)
      ? ReplacementMode.chargeFullPrice
      : ReplacementMode.deferred;
}

/// What the plans screen offers for one plan.
enum VipPlanOffer {
  /// Not VIP: a normal purchase.
  buy,

  /// The plan the user is subscribed to. Never bought again.
  current,

  /// Another plan while subscribed to [current]: a Play plan switch.
  switchPlan,
}

/// [ownedPlan] is the VIP plan of the Play subscription on this device's
/// Google account, or null when there is none (VIP from iOS, a promo, an
/// admin grant, another Google account, or iOS itself). Without it there is
/// nothing to replace, so a VIP is not offered anything (the screen shows
/// the "already active" card instead) — buying would be a second charge.
VipPlanOffer? vipPlanOffer({
  required bool isVip,
  required VipPlan? ownedPlan,
  required VipPlan plan,
}) {
  if (!isVip) return VipPlanOffer.buy;
  if (ownedPlan == null) return null;
  return plan == ownedPlan ? VipPlanOffer.current : VipPlanOffer.switchPlan;
}

/// The VIP subscription purchase among [purchases] (Play's owned
/// purchases), or null. Pending purchases are skipped: Play cannot replace
/// a subscription that has not been paid for yet.
PurchaseDetails? ownedVipSubscription(Iterable<PurchaseDetails> purchases) {
  for (final p in purchases) {
    if (p.status == PurchaseStatus.pending) continue;
    if (vipPlanForAndroidProduct(p.productID) != null) return p;
  }
  return null;
}

/// Result of [VipPlanSwitcher.run].
enum VipPlanSwitchStatus {
  /// Play replaced the subscription now; [VipPlanSwitchResult.purchase] is
  /// the new purchase, to verify with the backend like any purchase.
  switched,

  /// A deferred switch (to a shorter plan) was accepted. Play reports it
  /// with no purchase: the new plan starts when the current one ends, so
  /// there is nothing to verify now.
  scheduled,

  /// The user closed the Play sheet, or the store failed.
  canceled,

  /// No Play subscription to replace on this Google account.
  noSubscription,

  /// The target is the plan the user already has.
  samePlan,
}

class VipPlanSwitchResult {
  const VipPlanSwitchResult(this.status, [this.purchase]);

  final VipPlanSwitchStatus status;
  final PurchaseDetails? purchase;
}

/// Plan-switch flow. Every store dependency is a function so it can be
/// tested without Google Play; `AndroidPurchaseService` wires the real ones.
class VipPlanSwitcher {
  VipPlanSwitcher({required this.queryOwned, required this.buy});

  /// The current VIP subscription purchase on this Google account, fresh
  /// from the store (its token is what Play replaces).
  final Future<PurchaseDetails?> Function() queryOwned;

  /// Launches Play's replacement flow and waits for the result: the new
  /// purchase, Play's anonymous "purchased" event for a deferred switch
  /// (empty product id), or null when canceled / failed / timed out.
  final Future<PurchaseDetails?> Function(
    VipPlan target,
    PurchaseDetails oldPurchase,
    ReplacementMode mode,
  )
  buy;

  Future<VipPlanSwitchResult> run(VipPlan target) async {
    final PurchaseDetails? owned;
    try {
      owned = await queryOwned();
    } catch (_) {
      return const VipPlanSwitchResult(VipPlanSwitchStatus.canceled);
    }
    final from = owned == null
        ? null
        : vipPlanForAndroidProduct(owned.productID);
    if (owned == null || from == null) {
      return const VipPlanSwitchResult(VipPlanSwitchStatus.noSubscription);
    }
    if (from == target) {
      return const VipPlanSwitchResult(VipPlanSwitchStatus.samePlan);
    }

    final mode = vipReplacementMode(from: from, to: target);
    final PurchaseDetails? result;
    try {
      result = await buy(target, owned, mode);
    } catch (_) {
      return const VipPlanSwitchResult(VipPlanSwitchStatus.canceled);
    }
    if (result == null) {
      return const VipPlanSwitchResult(VipPlanSwitchStatus.canceled);
    }
    if (result.productID.isEmpty) {
      return const VipPlanSwitchResult(VipPlanSwitchStatus.scheduled);
    }
    if (result.productID != target.androidProductId) {
      return const VipPlanSwitchResult(VipPlanSwitchStatus.canceled);
    }
    return VipPlanSwitchResult(VipPlanSwitchStatus.switched, result);
  }
}
