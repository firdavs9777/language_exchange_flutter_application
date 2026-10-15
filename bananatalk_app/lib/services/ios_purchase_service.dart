import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:bananatalk_app/models/coin_pack.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/services/purchase_call_guard.dart';
import 'package:bananatalk_app/services/purchase_restorer.dart';

// Callback for purchase completion
typedef PurchaseCallback = void Function(PurchaseDetails details, bool success, String? error);

class IOSPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static String? _queryProductError;

  // Track initialization state to prevent multiple concurrent initializations
  static bool _isInitializing = false;
  static Completer<bool>? _initializationCompleter;
  static bool _isLoadingProducts = false;

  // Callback for when purchase completes
  static PurchaseCallback? _purchaseCallback;

  /// The one purchase call that may be waiting for the store. Always
  /// released when the call ends (success, failure, cancel or timeout), so a
  /// purchase abandoned in the store sheet no longer blocks the next one.
  static final PurchaseCallGuard _call = PurchaseCallGuard();

  /// Restore in progress: restored VIP transactions are collected here
  /// instead of going to the redelivery handler.
  static bool _restoring = false;
  static final List<RestoredPurchase> _restoreBuffer = [];
  static int _restoreEventCount = 0;

  /// Receives purchased/restored transactions no purchase call or restore is
  /// waiting for (see `PurchaseRedeliveryHandler`).
  static void Function(RestoredPurchase purchase)? _redeliveryHandler;

  /// VIP subscription product IDs (must match App Store Connect).
  ///
  /// Derived from [VipPlan] rather than listed here: a plan the screens can
  /// offer but this set omits is a product the store is never asked about, so
  /// the purchase fails with "Product not found".
  static Set<String> get _vipProductIds => VipPlan.productIdsFor(true);

  /// Coins v1 (Workstream F) — consumable coin-pack product IDs (must
  /// match App Store Connect). See `lib/models/coin_pack.dart` for the
  /// coins/price each maps to. Kept separate from [_vipProductIds] so
  /// [_onPurchaseUpdate] can tell a consumable purchase from a
  /// subscription and skip the auto-complete for the former (Task 7
  /// contract — only complete a coin pack after the backend has verified
  /// the receipt and credited coins).
  static Set<String> get _coinProductIds =>
      CoinPack.all.map((p) => p.iosProductId).toSet();

  /// Everything queried from the store in one call.
  static Set<String> get _productIds => {
        ..._vipProductIds,
        ..._coinProductIds,
      };

  static final List<ProductDetails> _products = [];
  static final List<PurchaseDetails> _purchases = [];

  /// Initialize the StoreKit connection
  static Future<bool> initializeStore() async {
    if (!Platform.isIOS) {
      return false;
    }

    // Already initialized successfully
    if (_isAvailable && _subscription != null) {
      return true;
    }

    // Initialization already in progress - wait for it
    if (_isInitializing && _initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _isInitializing = true;
    _initializationCompleter = Completer<bool>();

    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        _queryProductError = 'Store not available';
        _isInitializing = false;
        _initializationCompleter?.complete(false);
        return false;
      }

      _isAvailable = available;

      // Only set up the subscription if not already listening
      if (_subscription == null) {
        _subscription = _inAppPurchase.purchaseStream.listen(
          _onPurchaseUpdate,
          onDone: () => _subscription?.cancel(),
          onError: (error) {
          },
        );
      }

      // Load products inline to avoid deadlock
      await _loadProductsInternal();

      _isInitializing = false;
      _initializationCompleter?.complete(true);
      return true;
    } catch (e) {
      _isInitializing = false;
      _initializationCompleter?.complete(false);
      return false;
    }
  }

  /// Internal method to load products (called from initializeStore)
  static Future<void> _loadProductsInternal() async {

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);


    if (response.error != null) {
      _queryProductError = response.error!.message;
      return;
    }

    if (response.productDetails.isEmpty) {
      _queryProductError = 'No products found. Not found IDs: ${response.notFoundIDs}';
      return;
    }

    _products.clear();
    _products.addAll(response.productDetails);
    _queryProductError = null;
  }

  /// Load available products from App Store (public method for manual refresh)
  static Future<void> loadProducts() async {
    // If store not available, initialize first
    if (!_isAvailable) {
      await initializeStore();
      return; // initializeStore already loads products
    }

    // If already loading, skip
    if (_isLoadingProducts) {
      return;
    }

    _isLoadingProducts = true;
    await _loadProductsInternal();
    _isLoadingProducts = false;
  }

  /// Get available products
  static List<ProductDetails> getProducts() {
    return List.unmodifiable(_products);
  }

  /// Get product by ID
  static ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Initiate purchase for a product and wait for completion
  /// Returns the PurchaseDetails if successful, null otherwise
  static Future<PurchaseDetails?> purchaseProductAndWait(String productId) async {
    if (!_isAvailable) {
      final initialized = await initializeStore();
      if (!initialized || !_isAvailable) {
        return null;
      }
    }

    // Ensure products are loaded
    if (_products.isEmpty) {
      await loadProducts();
      if (_products.isEmpty) {
        return null;
      }
    }

    final ProductDetails? productDetails = getProduct(productId);
    if (productDetails == null) {
      return null;
    }

    if (!_call.begin(productId)) {
      return null;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      // For subscriptions, use buyNonConsumable
      final bool initiated = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!initiated) {
        _call.abort();
        return null;
      }

      // Wait for the purchase to complete (with timeout). wait() releases
      // the guard however it ends.
      return await _call.wait(timeout: const Duration(minutes: 5));
    } catch (e) {
      _call.abort();
      return null;
    }
  }

  /// Initiate purchase for a product (legacy - doesn't wait)
  static Future<bool> purchaseProduct(String productId) async {
    final result = await purchaseProductAndWait(productId);
    return result != null;
  }

  /// Coins v1 (Task 7) — purchase a consumable coin pack and wait for the
  /// store to report the result. Uses `buyConsumable(autoConsume: false)`:
  /// the transaction is NOT finished here. Call [completeCoinPurchase]
  /// only after the backend's `/coins/verify-purchase` call succeeds — a
  /// failed verify must leave the purchase un-finished so StoreKit
  /// redelivers it (via `purchaseStream`/`restorePurchases`) for retry,
  /// and so Apple can refund it if verification never succeeds.
  static Future<PurchaseDetails?> purchaseCoinPack(String productId) async {
    if (!_isAvailable) {
      final initialized = await initializeStore();
      if (!initialized || !_isAvailable) {
        return null;
      }
    }

    if (_products.isEmpty) {
      await loadProducts();
      if (_products.isEmpty) {
        return null;
      }
    }

    final ProductDetails? productDetails = getProduct(productId);
    if (productDetails == null) {
      return null;
    }

    if (!_call.begin(productId)) {
      return null;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      final bool initiated = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: false,
      );

      if (!initiated) {
        _call.abort();
        return null;
      }

      // Wait for the purchase to complete (with timeout). wait() releases
      // the guard however it ends.
      return await _call.wait(timeout: const Duration(minutes: 5));
    } catch (e) {
      _call.abort();
      return null;
    }
  }

  /// Finishes a coin-pack purchase whose receipt the backend has already
  /// verified and credited. Call ONLY after a successful
  /// `/coins/verify-purchase` response — this is the point at which the
  /// pack becomes repurchasable.
  static Future<void> completeCoinPurchase(PurchaseDetails purchase) async {
    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (e) {
      // Best-effort: a failure here just means StoreKit keeps the
      // transaction in the pending queue and redelivers it later. Coins
      // were already credited server-side, so this does not affect the
      // user's balance — the next completion attempt (e.g. on next
      // launch) will clear it.
    }
  }

  /// Set callback for purchase updates
  static void setPurchaseCallback(PurchaseCallback callback) {
    _purchaseCallback = callback;
  }

  /// Clear purchase callback
  static void clearPurchaseCallback() {
    _purchaseCallback = null;
  }

  /// Handle purchase updates from the App Store.
  ///
  /// Each transaction goes to exactly one owner:
  ///   1. the purchase call waiting for THIS product ([PurchaseCallGuard]);
  ///   2. else, during a restore, a restored VIP subscription is collected
  ///      for [restoreAndCollect];
  ///   3. else the redelivery handler (unfinished/renewed/deferred
  ///      transactions nobody is waiting for) — previously these were
  ///      dropped, so the backend never heard about them.
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    if (_restoring) _restoreEventCount++;
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      final takenByCall = _call.offer(purchaseDetails);
      final status = purchaseDetails.status;

      if (status == PurchaseStatus.pending) {
        continue;
      }

      if (status == PurchaseStatus.error) {
        _purchaseCallback?.call(
            purchaseDetails, false, purchaseDetails.error?.message);
      } else if (status == PurchaseStatus.purchased ||
          status == PurchaseStatus.restored) {
        if (!_purchases.contains(purchaseDetails)) {
          _purchases.add(purchaseDetails);
        }

        if (!takenByCall) {
          final restored = toRestoredPurchase(purchaseDetails);
          if (_restoring &&
              status == PurchaseStatus.restored &&
              _vipProductIds.contains(purchaseDetails.productID)) {
            _restoreBuffer.add(restored);
          } else {
            _redeliveryHandler?.call(restored);
          }
        }

        _purchaseCallback?.call(purchaseDetails, true, null);
      } else if (status == PurchaseStatus.canceled) {
        _purchaseCallback?.call(
            purchaseDetails, false, 'Purchase was canceled');
      }

      // Complete the purchase (acknowledge to App Store).
      // Coins v1 (Task 7): consumable coin-pack purchases are
      // deliberately excluded — they are finished via
      // [completeCoinPurchase] only after the backend verify succeeds
      // (coin shop, or the redelivery handler), so a failed verify leaves
      // the transaction retryable/refundable.
      if (purchaseDetails.pendingCompletePurchase &&
          !_coinProductIds.contains(purchaseDetails.productID)) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Routes transactions nobody is waiting for. Pass null to stop.
  static void setRedeliveryHandler(
      void Function(RestoredPurchase purchase)? handler) {
    _redeliveryHandler = handler;
  }

  /// Get transaction ID from latest purchase
  static String? getLatestTransactionId() {
    if (_purchases.isEmpty) return null;

    final latestPurchase = _purchases.last;

    return latestPurchase.purchaseID;
  }

  /// Get receipt/verification data from purchase details
  static String? getReceiptFromPurchase(PurchaseDetails purchase) {
    // For iOS, the verification data contains the receipt
    // serverVerificationData is the base64 encoded receipt for server verification
    final serverData = purchase.verificationData.serverVerificationData;
    if (serverData.isNotEmpty) {
      return serverData;
    }

    // Fallback to local verification data
    final localData = purchase.verificationData.localVerificationData;
    if (localData.isNotEmpty) {
      return localData;
    }

    return null;
  }

  /// Reduces a StoreKit transaction to what the backend verify needs.
  ///
  /// A RESTORED transaction carries a fresh transaction id that is not in the
  /// receipt — the backend looks the purchase up by id + product and would
  /// answer "Purchase not found in receipt". The original transaction (the
  /// purchase or renewal being restored) has the id the receipt knows, and
  /// its timestamp is when that period started.
  static RestoredPurchase toRestoredPurchase(PurchaseDetails purchase) {
    String? transactionId = purchase.purchaseID;
    DateTime? renewedAt = _parseMillis(purchase.transactionDate);
    if (purchase is AppStorePurchaseDetails &&
        purchase.status == PurchaseStatus.restored) {
      final original = purchase.skPaymentTransaction.originalTransaction;
      if (original != null) {
        transactionId = original.transactionIdentifier ?? transactionId;
        final ts = original.transactionTimeStamp;
        if (ts != null) {
          renewedAt =
              DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt());
        }
      }
    }
    return RestoredPurchase(
      productId: purchase.productID,
      receipt: getReceiptFromPurchase(purchase) ?? '',
      transactionId: transactionId,
      renewedAt: renewedAt,
      source: purchase,
    );
  }

  static DateTime? _parseMillis(String? millis) {
    final ms = int.tryParse(millis ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Get receipt data from the latest purchase
  static Future<String?> getReceiptData() async {
    if (!Platform.isIOS) {
      return null;
    }

    if (_purchases.isEmpty) {
      return null;
    }

    try {
      final latestPurchase = _purchases.last;
      return getReceiptFromPurchase(latestPurchase);
    } catch (e) {
      return null;
    }
  }

  /// Restore previous purchases and return the VIP subscriptions the store
  /// redelivered. Throws when the store is unavailable or the restore fails
  /// (the old fire-and-forget `restorePurchases` swallowed both).
  ///
  /// Coin packs are never returned here: they are consumables, so a restore
  /// does not grant them. An un-finished coin pack the store returns goes to
  /// the redelivery handler, whose verify the server dedupes per transaction.
  static Future<List<RestoredPurchase>> restoreAndCollect({
    Duration settle = const Duration(milliseconds: 1200),
    Duration maxWait = const Duration(seconds: 6),
  }) async {
    if (!_isAvailable) {
      final ok = await initializeStore();
      if (!ok) throw StateError(_queryProductError ?? 'Store not available');
    }
    if (_restoring) throw StateError('Restore already in progress');

    _restoring = true;
    _restoreBuffer.clear();
    _restoreEventCount = 0;
    try {
      await _inAppPurchase.restorePurchases();
      // Restored transactions can trail the future; wait until the stream
      // goes quiet.
      final deadline = DateTime.now().add(maxWait);
      var seen = -1;
      while (_restoreEventCount != seen && DateTime.now().isBefore(deadline)) {
        seen = _restoreEventCount;
        await Future<void>.delayed(settle);
      }
      return List<RestoredPurchase>.of(_restoreBuffer);
    } finally {
      _restoring = false;
      _restoreBuffer.clear();
    }
  }

  /// Get purchase history
  static List<PurchaseDetails> getPurchases() {
    return List.unmodifiable(_purchases);
  }

  /// Check if purchase is pending
  static bool get isPurchasePending => _call.inFlight;

  /// Check if store is available
  static bool get isAvailable => _isAvailable;

  /// Get query error
  static String? get queryError => _queryProductError;

  /// Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _products.clear();
    _purchases.clear();
    _call.abort();
    _restoring = false;
    _restoreBuffer.clear();
    _redeliveryHandler = null;
    _isAvailable = false;
    _isInitializing = false;
    _isLoadingProducts = false;
    _initializationCompleter = null;
    _queryProductError = null;
    _purchaseCallback = null;
  }
}
