import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// Coins v1 — REST client for `/api/v1/coins/*`.
///
/// Thin wrapper over the shared [ApiClient] (auth, 401 refresh, rate-limit
/// parsing already handled there). Contract per
/// `docs/superpowers/specs/2026-07-13-coins-v1-design.md` § Backend API:
///   GET  /coins/balance          -> { balance }
///   GET  /coins/transactions     -> paginated ledger
///   GET  /coins/unlock-catalog   -> { featureKey: { cost, grant } }
///   POST /coins/verify-purchase  -> idempotent verify + credit
///   POST /coins/unlock           -> { featureKey } -> { newBalance, granted } | 402
///
/// Costs/grants are ALWAYS read from [getUnlockCatalog] — never hardcoded
/// client-side — so they can be tuned server-side without an app release.
class CoinApiClient {
  CoinApiClient([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Current coin balance. Throws [CoinApiException] on failure so callers
  /// (typically a Riverpod `FutureProvider`) surface it as `AsyncError`.
  Future<int> getBalance() async {
    final res = await _client.get(Endpoints.coinsBalanceURL);
    if (!res.success) {
      throw CoinApiException(
        res.error ?? 'Failed to load coin balance',
        statusCode: res.statusCode,
      );
    }
    return _extractBalance(res.data);
  }

  /// Paginated transaction history (purchase/spend/refund ledger entries).
  Future<CoinTransactionPage> getTransactions({
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _client.get(
      Endpoints.coinsTransactionsURL,
      queryParams: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit.toString(),
      },
    );
    if (!res.success) {
      throw CoinApiException(
        res.error ?? 'Failed to load coin history',
        statusCode: res.statusCode,
      );
    }
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CoinTransactionPage.fromJson(data);
    }
    return CoinTransactionPage.empty;
  }

  /// Live per-featureKey unlock cost/grant. Keys are the real featureKeys:
  /// `chat`/`roleplay`/`story`/`photo`/`pronunciation` (tutor chips, each
  /// independent), `translation`, `moment`.
  Future<Map<String, CoinUnlockEntry>> getUnlockCatalog() async {
    final res = await _client.get(Endpoints.coinsUnlockCatalogURL);
    if (!res.success) {
      throw CoinApiException(
        res.error ?? 'Failed to load unlock catalog',
        statusCode: res.statusCode,
      );
    }
    final map = <String, CoinUnlockEntry>{};
    final data = res.data;
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          map[key.toString()] = CoinUnlockEntry.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          );
        }
      });
    }
    return map;
  }

  /// Verifies a completed store purchase with the backend and credits
  /// coins on success. [transactionId] MUST be the identical
  /// per-purchase idempotency id sent on every retry of the *same*
  /// purchase:
  ///   - iOS: StoreKit `transactionId` of the consumable (NOT
  ///     `originalTransactionId`).
  ///   - Android: the `purchaseToken`.
  ///
  /// Returns the raw [ApiResponse] rather than throwing — the caller
  /// (purchase service) must only call `completePurchase`/`consumePurchase`
  /// on the underlying store transaction when `response.success == true`;
  /// on failure the IAP must be left un-consumed so the store can retry or
  /// refund it (Task 7 contract — never consume before verify succeeds).
  Future<ApiResponse> verifyPurchase({
    required String platform,
    required String productId,
    required String receipt,
    required String transactionId,
  }) {
    return _client.post(
      Endpoints.coinsVerifyPurchaseURL,
      body: {
        'platform': platform,
        'productId': productId,
        'receipt': receipt,
        'transactionId': transactionId,
      },
    );
  }

  /// Spends coins to unlock extra uses of [featureKey]. Returns the raw
  /// [ApiResponse] (not a thrown exception) because callers need to branch
  /// on the status code: 402 = insufficient balance (route to the coin
  /// shop), 400 = unknown featureKey, 200 = success with `{newBalance,
  /// granted}` in `response.data`.
  Future<ApiResponse> unlock(String featureKey) {
    return _client.post(
      Endpoints.coinsUnlockURL,
      body: {'featureKey': featureKey},
    );
  }

  int _extractBalance(dynamic data) {
    if (data is Map) {
      final direct = data['balance'];
      if (direct is num) return direct.toInt();
      final nested = data['data'];
      if (nested is Map && nested['balance'] is num) {
        return (nested['balance'] as num).toInt();
      }
    }
    return 0;
  }
}

/// Thrown by [CoinApiClient] read methods on a non-2xx response.
class CoinApiException implements Exception {
  const CoinApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
