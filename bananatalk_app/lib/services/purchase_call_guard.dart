import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Tracks the one store purchase call that may be in flight at a time, for
/// both purchase services.
///
/// It replaces a bare `_purchasePending` flag that was set when a purchase
/// started and only cleared by a later store event. A purchase that timed
/// out, was abandoned in the store sheet without an event, or sat in
/// "pending" (slow card, parental approval) never produced that event, so
/// the flag stayed set and every later attempt returned null (shown as
/// "canceled") until the app restarted. Here the call always releases the
/// guard when it finishes — success, failure, cancel or timeout.
///
/// It also only hands the waiting call a transaction for the product that
/// call is buying. StoreKit redelivers unfinished transactions whenever it
/// likes; previously the first one to arrive resolved whatever purchase
/// happened to be waiting, so buying VIP could "succeed" with an old coin
/// pack's receipt.
class PurchaseCallGuard {
  Completer<PurchaseDetails?>? _completer;
  String? _productId;
  bool _storePending = false;
  bool _acceptAnonymousSuccess = false;

  /// A purchase call is waiting for the store.
  bool get inFlight => _completer != null;

  /// The store reported the in-flight purchase as pending (deferred).
  bool get isPending => inFlight && _storePending;

  /// Product the in-flight call is buying.
  String? get productId => _productId;

  /// Starts a call for [productId]. Returns false (and changes nothing) when
  /// another call is already in flight.
  ///
  /// [acceptAnonymousSuccess]: a deferred Google Play plan switch succeeds
  /// with NO purchase, which the plugin reports as a "purchased" event with
  /// an empty product id. Only a plan-switch call expects that; any other
  /// call would wait for its product until the timeout.
  bool begin(String productId, {bool acceptAnonymousSuccess = false}) {
    if (inFlight) return false;
    _completer = Completer<PurchaseDetails?>();
    _productId = productId;
    _storePending = false;
    _acceptAnonymousSuccess = acceptAnonymousSuccess;
    return true;
  }

  /// The store reported a pending transaction for the in-flight product.
  void markStorePending() {
    if (inFlight) _storePending = true;
  }

  /// Offers a store transaction to the in-flight call. Returns true when the
  /// call took it: a purchased/restored transaction for the product being
  /// bought resolves the call with it; an error or cancel for that product
  /// resolves it with null. Anything else is left for the caller to route.
  bool offer(PurchaseDetails details) {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return false;
    final status = details.status;
    // Google Play reports a cancel/error that carries no purchase with an
    // EMPTY product id — it can only belong to the call in flight.
    final anonymousFailure = details.productID.isEmpty &&
        (status == PurchaseStatus.canceled || status == PurchaseStatus.error);
    final anonymousSuccess = _acceptAnonymousSuccess &&
        details.productID.isEmpty &&
        status == PurchaseStatus.purchased;
    if (details.productID != _productId &&
        !anonymousFailure &&
        !anonymousSuccess) {
      return false;
    }
    switch (status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        completer.complete(details);
        return true;
      case PurchaseStatus.error:
      case PurchaseStatus.canceled:
        completer.complete(null);
        return true;
      case PurchaseStatus.pending:
        _storePending = true;
        return true;
    }
  }

  /// Waits for the in-flight call to resolve, at most [timeout]. Always
  /// releases the guard, so the next [begin] works whatever happened.
  Future<PurchaseDetails?> wait({required Duration timeout}) async {
    final completer = _completer;
    if (completer == null) return null;
    try {
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } finally {
      _release(completer);
    }
  }

  /// Releases a call that never reached the store (e.g. `buy*` threw or
  /// returned false).
  void abort() {
    final completer = _completer;
    if (completer == null) return;
    if (!completer.isCompleted) completer.complete(null);
    _release(completer);
  }

  void _release(Completer<PurchaseDetails?> completer) {
    // Only clear state that still belongs to this call.
    if (identical(_completer, completer)) {
      _completer = null;
      _productId = null;
      _storePending = false;
      _acceptAnonymousSuccess = false;
    }
  }
}
