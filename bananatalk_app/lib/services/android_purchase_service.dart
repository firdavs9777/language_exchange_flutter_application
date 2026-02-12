import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Callback for purchase completion
typedef PurchaseCallback = void Function(
  PurchaseDetails details,
  bool success,
  String? error,
);

/// Service for handling Google Play Billing on Android
/// Mirrors the structure of IOSPurchaseService for consistency
class AndroidPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static bool _purchasePending = false;
  static String? _queryProductError;

  // Callback for when purchase completes
  static PurchaseCallback? _purchaseCallback;

  // Completer for purchase result
  static Completer<PurchaseDetails?>? _purchaseCompleter;

  // Product IDs for VIP subscriptions (must match Google Play Console)
  static const Set<String> _productIds = {
    'com.bananatalk.app.vip.monthly',
    'com.bananatalk.app.vip.quarterly',
    'com.bananatalk.app.vip.yearly',
  };

  static final List<ProductDetails> _products = [];
  static final List<PurchaseDetails> _purchases = [];

  /// Initialize the Google Play Billing connection
  static Future<bool> initializeStore() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final bool available = await _inAppPurchase.isAvailable();
    debugPrint('Google Play available: $available');
    if (!available) {
      _queryProductError = 'Google Play Store not available';
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

    debugPrint('Android purchase subscription initialized');

    // Load products
    await loadProducts();

    return true;
  }

  /// Load available products from Google Play
  static Future<void> loadProducts() async {
    if (!_isAvailable) {
      await initializeStore();
    }

    debugPrint('Querying Google Play products: $_productIds');

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);

    debugPrint('Query complete:');
    debugPrint('   - Products found: ${response.productDetails.length}');
    debugPrint(
        '   - Products: ${response.productDetails.map((p) => '${p.id}: ${p.price}').toList()}');
    debugPrint('   - Not found IDs: ${response.notFoundIDs}');
    debugPrint('   - Has error: ${response.error != null}');

    if (response.error != null) {
      _queryProductError = response.error!.message;
      debugPrint('Error loading products: ${response.error!.message}');
      return;
    }

    if (response.productDetails.isEmpty) {
      _queryProductError =
          'No products found. Not found IDs: ${response.notFoundIDs}';
      debugPrint('No products found');
      debugPrint('   This usually means:');
      debugPrint('   1. Products not yet configured in Google Play Console');
      debugPrint('   2. App not published or in testing track');
      debugPrint('   3. Product IDs do not match');
      debugPrint('   4. Billing library not properly initialized');
      return;
    }

    _products.clear();
    _products.addAll(response.productDetails);
    _queryProductError = null;
    debugPrint('Loaded ${_products.length} products successfully');
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
  static Future<PurchaseDetails?> purchaseProductAndWait(
      String productId) async {
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
      debugPrint('Initiating purchase for: $productId');

      // For subscriptions, use buyNonConsumable
      final bool initiated = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!initiated) {
        _purchasePending = false;
        _purchaseCompleter = null;
        debugPrint('Failed to initiate subscription purchase');
        return null;
      }

      debugPrint('Waiting for purchase to complete...');

      // Wait for the purchase to complete (with timeout)
      final result = await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('Purchase timed out');
          return null;
        },
      );

      _purchaseCompleter = null;
      return result;
    } catch (e) {
      _purchasePending = false;
      _purchaseCompleter = null;
      debugPrint('Purchase error: $e');
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

  /// Handle purchase updates from Google Play
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint(
          'Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
        debugPrint('Purchase pending...');
      } else {
        _purchasePending = false;

        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error?.message}');
          debugPrint('   Error code: ${purchaseDetails.error?.code}');
          debugPrint('   Error details: ${purchaseDetails.error?.details}');

          // Complete the completer with null to indicate failure
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(null);
          }

          // Call callback if set
          _purchaseCallback?.call(
              purchaseDetails, false, purchaseDetails.error?.message);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          debugPrint('Purchase successful: ${purchaseDetails.productID}');
          debugPrint('   Purchase ID: ${purchaseDetails.purchaseID}');

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
          debugPrint('Purchase canceled');

          // Complete the completer with null
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(null);
          }

          // Call callback if set
          _purchaseCallback?.call(
              purchaseDetails, false, 'Purchase was canceled');
        }

        // Complete/acknowledge the purchase (required for Google Play)
        if (purchaseDetails.pendingCompletePurchase) {
          debugPrint('Completing/acknowledging purchase...');
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Get the purchase token for backend verification
  /// This is the key data needed to verify the purchase with Google Play API
  static String? getPurchaseToken(PurchaseDetails purchase) {
    // For Android, serverVerificationData contains the purchase token
    final serverData = purchase.verificationData.serverVerificationData;
    if (serverData.isNotEmpty) {
      debugPrint('Got purchase token (${serverData.length} chars)');
      return serverData;
    }

    debugPrint('No purchase token available');
    return null;
  }

  /// Get the order ID from purchase details
  static String? getOrderId(PurchaseDetails purchase) {
    return purchase.purchaseID;
  }

  /// Get purchase token from the latest purchase
  static String? getLatestPurchaseToken() {
    if (_purchases.isEmpty) {
      debugPrint('No purchases available');
      return null;
    }

    try {
      final latestPurchase = _purchases.last;
      return getPurchaseToken(latestPurchase);
    } catch (e) {
      debugPrint('Error getting purchase token: $e');
      return null;
    }
  }

  /// Get order ID from the latest purchase
  static String? getLatestOrderId() {
    if (_purchases.isEmpty) return null;
    return _purchases.last.purchaseID;
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

  /// Get product IDs
  static Set<String> get productIds => _productIds;

  /// Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _products.clear();
    _purchases.clear();
    _purchasePending = false;
    _isAvailable = false;
    _queryProductError = null;
    _purchaseCallback = null;
    _purchaseCompleter = null;
  }
}
