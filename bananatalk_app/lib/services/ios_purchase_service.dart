import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Callback for purchase completion
typedef PurchaseCallback = void Function(PurchaseDetails details, bool success, String? error);

class IOSPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static bool _purchasePending = false;
  static String? _queryProductError;

  // Callback for when purchase completes
  static PurchaseCallback? _purchaseCallback;

  // Completer for purchase result
  static Completer<PurchaseDetails?>? _purchaseCompleter;

  // Product IDs for VIP subscriptions (must match App Store Connect)
  static const Set<String> _productIds = {
    'com.bananatalk.bananatalkApp.vip.month',
    'com.bananatalk.bananatalkApp.vip.quarter',
    'com.bananatalk.bananatalkApp.vip.year',
  };

  static final List<ProductDetails> _products = [];
  static final List<PurchaseDetails> _purchases = [];

  /// Initialize the StoreKit connection
  static Future<bool> initializeStore() async {
    if (!Platform.isIOS) {
      return false;
    }

    final bool available = await _inAppPurchase.isAvailable();
    debugPrint('$available');
    if (!available) {
      _queryProductError = 'Store not available';
      return false;
    }

    _isAvailable = available;

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );
    debugPrint("Hereeee");
    debugPrint('$_subscription');

    // Load products
    await loadProducts();

    return true;
  }

  /// Load available products from App Store
  static Future<void> loadProducts() async {
    if (!_isAvailable) {
      await initializeStore();
    }

    debugPrint('🛒 Querying products: $_productIds');

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);

    debugPrint('🛒 Query complete:');
    debugPrint('   - Products found: ${response.productDetails.length}');
    debugPrint('   - Products: ${response.productDetails.map((p) => '${p.id}: ${p.price}').toList()}');
    debugPrint('   - Not found IDs: ${response.notFoundIDs}');
    debugPrint('   - Has error: ${response.error != null}');

    if (response.error != null) {
      _queryProductError = response.error!.message;
      debugPrint('❌ Error loading products: ${response.error!.message}');
      debugPrint('   Error code: ${response.error!.code}');
      debugPrint('   Error details: ${response.error!.details}');
      return;
    }

    if (response.productDetails.isEmpty) {
      _queryProductError = 'No products found. Not found IDs: ${response.notFoundIDs}';
      debugPrint('⚠️ No products found');
      debugPrint('   This usually means:');
      debugPrint('   1. Products not yet configured in App Store Connect');
      debugPrint('   2. Paid Apps Agreement not signed');
      debugPrint('   3. Build not yet uploaded to App Store Connect');
      debugPrint('   4. Products not in "Ready to Submit" status');
      return;
    }

    _products.clear();
    _products.addAll(response.productDetails);
    _queryProductError = null;
    debugPrint('✅ Loaded ${_products.length} products successfully');
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
        debugPrint('Store not available. Error: $_queryProductError');
        return null;
      }
    }

    // Ensure products are loaded
    if (_products.isEmpty) {
      debugPrint('No products loaded, loading products...');
      await loadProducts();
      if (_products.isEmpty) {
        debugPrint('Failed to load products. Error: $_queryProductError');
        return null;
      }
    }

    final ProductDetails? productDetails = getProduct(productId);
    if (productDetails == null) {
      debugPrint('Product not found: $productId');
      debugPrint('Available products: ${_products.map((p) => p.id).toList()}');
      return null;
    }

    if (_purchasePending) {
      debugPrint('Purchase already in progress');
      return null;
    }

    _purchasePending = true;

    // Create a completer to wait for purchase result
    _purchaseCompleter = Completer<PurchaseDetails?>();

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      debugPrint('🛒 Initiating purchase for: $productId');

      // For subscriptions, use buyNonConsumable
      final bool initiated = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!initiated) {
        _purchasePending = false;
        _purchaseCompleter = null;
        debugPrint('❌ Failed to initiate subscription purchase');
        return null;
      }

      debugPrint('⏳ Waiting for purchase to complete...');

      // Wait for the purchase to complete (with timeout)
      final result = await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('⏰ Purchase timed out');
          return null;
        },
      );

      _purchaseCompleter = null;
      return result;
    } catch (e) {
      _purchasePending = false;
      _purchaseCompleter = null;
      debugPrint('❌ Purchase error: $e');
      return null;
    }
  }

  /// Initiate purchase for a product (legacy - doesn't wait)
  static Future<bool> purchaseProduct(String productId) async {
    final result = await purchaseProductAndWait(productId);
    return result != null;
  }

  /// Set callback for purchase updates
  static void setPurchaseCallback(PurchaseCallback callback) {
    _purchaseCallback = callback;
  }

  /// Clear purchase callback
  static void clearPurchaseCallback() {
    _purchaseCallback = null;
  }

  /// Handle purchase updates
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('🛒 Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
        debugPrint('⏳ Purchase pending...');
      } else {
        _purchasePending = false;

        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('❌ Purchase error: ${purchaseDetails.error?.message}');
          debugPrint('   Error code: ${purchaseDetails.error?.code}');
          debugPrint('   Error details: ${purchaseDetails.error?.details}');

          // Complete the completer with null to indicate failure
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(null);
          }

          // Call callback if set
          _purchaseCallback?.call(purchaseDetails, false, purchaseDetails.error?.message);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          debugPrint('✅ Purchase successful: ${purchaseDetails.productID}');
          debugPrint('   Transaction ID: ${purchaseDetails.purchaseID}');

          // Add to purchases list
          if (!_purchases.contains(purchaseDetails)) {
            _purchases.add(purchaseDetails);
          }

          // Complete the completer with the purchase details
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(purchaseDetails);
          }

          // Call callback if set
          _purchaseCallback?.call(purchaseDetails, true, null);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint('🚫 Purchase canceled');

          // Complete the completer with null
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(null);
          }

          // Call callback if set
          _purchaseCallback?.call(purchaseDetails, false, 'Purchase was canceled');
        }

        // Complete the purchase (acknowledge to App Store)
        if (purchaseDetails.pendingCompletePurchase) {
          debugPrint('📝 Completing purchase...');
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
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
      debugPrint('📄 Got server verification data (${serverData.length} chars)');
      return serverData;
    }

    // Fallback to local verification data
    final localData = purchase.verificationData.localVerificationData;
    if (localData.isNotEmpty) {
      debugPrint('📄 Got local verification data (${localData.length} chars)');
      return localData;
    }

    debugPrint('⚠️ No verification data available');
    return null;
  }

  /// Get receipt data from the latest purchase
  static Future<String?> getReceiptData() async {
    if (!Platform.isIOS) {
      return null;
    }

    if (_purchases.isEmpty) {
      debugPrint('⚠️ No purchases available for receipt');
      return null;
    }

    try {
      final latestPurchase = _purchases.last;
      return getReceiptFromPurchase(latestPurchase);
    } catch (e) {
      debugPrint('Error getting receipt: $e');
      return null;
    }
  }

  /// Restore previous purchases
  static Future<void> restorePurchases() async {
    if (!_isAvailable) {
      await initializeStore();
    }

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  /// Get purchase history
  static List<PurchaseDetails> getPurchases() {
    return List.unmodifiable(_purchases);
  }

  /// Check if purchase is pending
  static bool get isPurchasePending => _purchasePending;

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
    _purchasePending = false;
  }
}
