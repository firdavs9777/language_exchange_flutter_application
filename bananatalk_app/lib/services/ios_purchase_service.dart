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

  // Track initialization state to prevent multiple concurrent initializations
  static bool _isInitializing = false;
  static Completer<bool>? _initializationCompleter;
  static bool _isLoadingProducts = false;

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

    if (_purchasePending) {
      return null;
    }

    _purchasePending = true;

    // Create a completer to wait for purchase result
    _purchaseCompleter = Completer<PurchaseDetails?>();

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {

      // For subscriptions, use buyNonConsumable
      final bool initiated = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!initiated) {
        _purchasePending = false;
        _purchaseCompleter = null;
        return null;
      }


      // Wait for the purchase to complete (with timeout)
      final result = await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          return null;
        },
      );

      _purchaseCompleter = null;
      return result;
    } catch (e) {
      _purchasePending = false;
      _purchaseCompleter = null;
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

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;

        if (purchaseDetails.status == PurchaseStatus.error) {

          // Complete the completer with null to indicate failure
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(null);
          }

          // Call callback if set
          _purchaseCallback?.call(purchaseDetails, false, purchaseDetails.error?.message);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

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

          // Complete the completer with null
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.complete(null);
          }

          // Call callback if set
          _purchaseCallback?.call(purchaseDetails, false, 'Purchase was canceled');
        }

        // Complete the purchase (acknowledge to App Store)
        if (purchaseDetails.pendingCompletePurchase) {
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
      return serverData;
    }

    // Fallback to local verification data
    final localData = purchase.verificationData.localVerificationData;
    if (localData.isNotEmpty) {
      return localData;
    }

    return null;
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

  /// Restore previous purchases
  static Future<void> restorePurchases() async {
    if (!_isAvailable) {
      await initializeStore();
    }

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
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
    _isAvailable = false;
    _isInitializing = false;
    _isLoadingProducts = false;
    _initializationCompleter = null;
    _queryProductError = null;
    _purchaseCallback = null;
    _purchaseCompleter = null;
  }
}
