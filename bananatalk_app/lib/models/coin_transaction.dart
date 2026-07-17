/// Coins v1 — a single entry from `GET /coins/transactions`.
///
/// Mirrors the backend `CoinTransaction` ledger model: `{ userId, type,
/// amount(signed), balanceAfter, reason, relatedId, metadata, createdAt }`.
/// See `docs/superpowers/specs/2026-07-13-coins-v1-design.md` § Data model.
enum CoinTransactionType { purchase, spend, refund, unknown }

CoinTransactionType _parseType(dynamic raw) {
  switch (raw?.toString()) {
    case 'purchase':
      return CoinTransactionType.purchase;
    case 'spend':
      return CoinTransactionType.spend;
    case 'refund':
      return CoinTransactionType.refund;
    default:
      return CoinTransactionType.unknown;
  }
}

class CoinTransaction {
  final String id;
  final CoinTransactionType type;

  /// Signed amount: positive for purchase/refund, negative for spend.
  final int amount;
  final int balanceAfter;
  final String? reason;
  final String? relatedId;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.reason,
    this.relatedId,
    this.metadata,
    this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: _parseType(json['type']),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString(),
      relatedId: json['relatedId']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

/// Paginated response wrapper for `GET /coins/transactions?cursor=&limit=`.
class CoinTransactionPage {
  final List<CoinTransaction> transactions;
  final String? nextCursor;

  const CoinTransactionPage({required this.transactions, this.nextCursor});

  factory CoinTransactionPage.fromJson(Map<String, dynamic> json) {
    final rawList = json['transactions'] ?? json['data'] ?? json['items'];
    final list = rawList is List
        ? rawList
            .whereType<Map>()
            .map((e) => CoinTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CoinTransaction>[];
    return CoinTransactionPage(
      transactions: list,
      nextCursor: json['nextCursor']?.toString() ?? json['cursor']?.toString(),
    );
  }

  static const empty = CoinTransactionPage(transactions: []);
}

/// A single entry from `GET /coins/unlock-catalog` — the live cost/grant
/// for one featureKey. The app MUST read costs from here, never hardcode
/// them (reviewer requirement — costs are tunable server-side).
class CoinUnlockEntry {
  final String featureKey;
  final int cost;
  final int grant;

  const CoinUnlockEntry({
    required this.featureKey,
    required this.cost,
    required this.grant,
  });

  factory CoinUnlockEntry.fromJson(String featureKey, Map<String, dynamic> json) {
    return CoinUnlockEntry(
      featureKey: featureKey,
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      grant: (json['grant'] as num?)?.toInt() ?? 0,
    );
  }
}
