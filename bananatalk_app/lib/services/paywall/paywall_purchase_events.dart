import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';

/// How a store purchase attempt moved, as the purchase screens see it.
enum PurchaseOutcome {
  started,
  succeeded,

  /// The store charged and the server accepted the receipt, but VIP is not
  /// confirmed yet (the pending dialog). Reported as a success.
  pending,
  verifyFailed,
  error,
  cancelled,
}

/// The funnel event for a purchase outcome. [productId] is the `detail` of
/// `purchase_started`; failures carry `verify` or `error`.
({String action, String? detail}) purchaseEventFor(
  PurchaseOutcome outcome, {
  String? productId,
}) {
  switch (outcome) {
    case PurchaseOutcome.started:
      return (action: PaywallAction.purchaseStarted, detail: productId);
    case PurchaseOutcome.succeeded:
      return (action: PaywallAction.purchaseSucceeded, detail: productId);
    case PurchaseOutcome.pending:
      return (action: PaywallAction.purchaseSucceeded, detail: 'pending');
    case PurchaseOutcome.verifyFailed:
      return (action: PaywallAction.purchaseFailed, detail: 'verify');
    case PurchaseOutcome.error:
      return (action: PaywallAction.purchaseFailed, detail: 'error');
    case PurchaseOutcome.cancelled:
      return (action: PaywallAction.dismissed, detail: null);
  }
}

/// Reports [outcome] on [flow]. No flow (screen opened without one): nothing.
void paywallLogPurchase(
  PaywallFlow? flow,
  PurchaseOutcome outcome, {
  String? productId,
}) {
  if (flow == null) return;
  final e = purchaseEventFor(outcome, productId: productId);
  paywallLog(flow, e.action, detail: e.detail);
}

/// One store purchase attempt: `purchase_started` is logged by [start] (call
/// it immediately before the store purchase is requested) and at most one
/// terminal event by [finish]; a second [finish], or a [finish] with no
/// [start], is ignored. Create one per attempt.
class PurchaseAttempt {
  PurchaseAttempt(this.flow);

  final PaywallFlow? flow;
  bool _started = false;
  bool _ended = false;

  void start(String productId) {
    if (_started) return;
    _started = true;
    paywallLogPurchase(flow, PurchaseOutcome.started, productId: productId);
  }

  void finish(PurchaseOutcome outcome, {String? productId}) {
    if (!_started || _ended) return;
    _ended = true;
    paywallLogPurchase(flow, outcome, productId: productId);
  }
}

/// A coin pack's verify answer as a purchase outcome. A receipt already
/// credited on this account counts as a success; one linked to another
/// account is a failure (nothing was granted here).
PurchaseOutcome purchaseOutcomeForCoinVerify(CoinVerifyOutcome outcome) {
  switch (outcome) {
    case CoinVerifyOutcome.credited:
    case CoinVerifyOutcome.alreadyCredited:
      return PurchaseOutcome.succeeded;
    case CoinVerifyOutcome.linkedToAnotherAccount:
    case CoinVerifyOutcome.failed:
      return PurchaseOutcome.verifyFailed;
  }
}
