/// "Restore Purchases" — the platform-neutral part.
///
/// The purchase services turn store transactions into [RestoredPurchase]s;
/// [PurchaseRestorer] decides which (if any) goes to the backend and maps the
/// result to a [RestoreOutcome] the UI can show.
library;

/// One store transaction, reduced to what the backend verify endpoints need.
class RestoredPurchase {
  const RestoredPurchase({
    required this.productId,
    required this.receipt,
    this.transactionId,
    this.renewedAt,
    this.source,
  });

  final String productId;

  /// iOS: the base64 app receipt. Android: the Play purchase token.
  final String receipt;

  /// The id the backend looks the purchase up by. iOS: the ORIGINAL
  /// transaction's id for a restored transaction (a restore gets a fresh id
  /// that is not in the receipt). Android: the order id.
  final String? transactionId;

  /// When this period of the subscription started (latest renewal), if the
  /// store says. Used to spot lapsed subscriptions on iOS.
  final DateTime? renewedAt;

  /// The underlying store object (a `PurchaseDetails`), for completing it.
  final Object? source;
}

class RestoreVerifyResult {
  const RestoreVerifyResult.success()
      : success = true,
        error = null;
  const RestoreVerifyResult.failure(this.error) : success = false;

  final bool success;
  final String? error;
}

enum RestoreOutcome {
  /// The backend verified a subscription and granted VIP.
  restored,

  /// The user already has VIP; nothing was sent to the backend.
  alreadyActive,

  /// The store has no live subscription for this Apple ID / Google account.
  nothingToRestore,

  /// The store or the backend failed.
  failed,
}

/// Restore flow. Every dependency is a function so it can be tested without
/// a store; `purchase_restore_flow.dart` wires the real ones.
class PurchaseRestorer {
  PurchaseRestorer({
    required this.restore,
    required this.vipProductIds,
    required this.isVipActive,
    required this.verify,
    required this.planPeriod,
    this.checkExpiry = false,
    this.grace = const Duration(days: 3),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// Asks the store to restore, returning what it redelivered. Throws when
  /// the store fails.
  final Future<List<RestoredPurchase>> Function() restore;

  /// Only these are restorable. Coin packs are consumables: a restore never
  /// grants them (unfinished ones are recovered by the redelivery handler,
  /// which the server dedupes per transaction).
  final Set<String> vipProductIds;

  final Future<bool> Function() isVipActive;

  /// The same backend verify a new purchase uses.
  final Future<RestoreVerifyResult> Function(RestoredPurchase) verify;

  /// Length of one billing period for a VIP product.
  final Duration? Function(String productId) planPeriod;

  /// iOS restores return lapsed subscriptions too (every past transaction),
  /// and the backend treats an expired iOS receipt as a fresh activation, so
  /// the client skips subscriptions whose last period clearly ended. Google
  /// Play only returns subscriptions the user still owns, so Android leaves
  /// this off.
  final bool checkExpiry;
  final Duration grace;
  final DateTime Function() now;

  Future<RestoreOutcome> run() async {
    final List<RestoredPurchase> restored;
    try {
      restored = await restore();
    } catch (_) {
      return RestoreOutcome.failed;
    }

    final subs =
        restored.where((p) => vipProductIds.contains(p.productId)).toList();
    if (subs.isEmpty) return RestoreOutcome.nothingToRestore;

    // The backend extends an active subscription by a full period on every
    // verify call, so an active VIP must not re-verify.
    bool active = false;
    try {
      active = await isVipActive();
    } catch (_) {
      // Unknown — let the verify decide.
    }
    if (active) return RestoreOutcome.alreadyActive;

    final candidate = _pickCandidate(subs);
    if (candidate == null) return RestoreOutcome.nothingToRestore;

    try {
      final result = await verify(candidate);
      return result.success ? RestoreOutcome.restored : RestoreOutcome.failed;
    } catch (_) {
      return RestoreOutcome.failed;
    }
  }

  /// Exactly one subscription is verified: the most recently renewed one.
  /// Each extra verify would extend VIP again on the server.
  RestoredPurchase? _pickCandidate(List<RestoredPurchase> subs) {
    if (subs.isEmpty) return null;
    final sorted = [...subs]..sort((a, b) {
        final ad = a.renewedAt, bd = b.renewedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    final newest = sorted.first;
    if (checkExpiry && _clearlyLapsed(newest)) return null;
    return newest;
  }

  bool _clearlyLapsed(RestoredPurchase p) {
    final renewedAt = p.renewedAt;
    final period = planPeriod(p.productId);
    if (renewedAt == null || period == null) return false;
    return renewedAt.add(period).add(grace).isBefore(now());
  }
}
