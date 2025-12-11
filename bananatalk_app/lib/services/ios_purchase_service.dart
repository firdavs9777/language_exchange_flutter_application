import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';

class IOSPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static bool _purchasePending = false;
  static String? _queryProductError;

  // Product IDs for VIP subscriptions
  static const Set<String> _productIds = {
    'com.bananatalk.bananatalkApp.monthly',
    'com.bananatalk.bananatalkApp.quarterly',
    'com.bananatalk.bananatalkApp.yearly',
  };

  static final List<ProductDetails> _products = [];
  static final List<PurchaseDetails> _purchases = [];

  /// Initialize the StoreKit connection
  static Future<bool> initializeStore() async {
    if (!Platform.isIOS) {
      return false;
    }

    final bool available = await _inAppPurchase.isAvailable();
    print(available);
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
        print('Purchase stream error: $error');
      },
    );
    print("Hereeee");
    print(_subscription);

    // Load products
    await loadProducts();

    return true;
  }

  /// Load available products from App Store
  static Future<void> loadProducts() async {
    if (!_isAvailable) {
      await initializeStore();
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);

    print(response.notFoundIDs);
    if (response.error != null) {
      _queryProductError = response.error!.message;
      print('Error loading products: ${response.error!.message}');
      return;
    }

    if (response.productDetails.isEmpty) {
      _queryProductError = 'No products found';
      print('No products found');
      return;
    }

    _products.clear();
    _products.addAll(response.productDetails);
    _queryProductError = null;
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

  /// Initiate purchase for a product
  static Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      final initialized = await initializeStore();
      if (!initialized || !_isAvailable) {
        print('Store not available. Error: $_queryProductError');
        return false;
      }
    }

    // Ensure products are loaded
    if (_products.isEmpty) {
      print('No products loaded, loading products...');
      await loadProducts();
      if (_products.isEmpty) {
        print('Failed to load products. Error: $_queryProductError');
        return false;
      }
    }

    final ProductDetails? productDetails = getProduct(productId);
    if (productDetails == null) {
      print('Product not found: $productId');
      print('Available products: ${_products.map((p) => p.id).toList()}');
      return false;
    }

    if (_purchasePending) {
      print('Purchase already in progress');
      return false;
    }

    _purchasePending = true;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      // For subscriptions, use buyNonConsumable - the package treats subscriptions
      // as non-consumables. The subscription type is determined by the product
      // configuration in App Store Connect, not by the purchase method.
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _purchasePending = false;
        print('Failed to initiate subscription purchase');
        if (_queryProductError != null) {
          print('Query error: $_queryProductError');
        }
      }

      return success;
    } catch (e) {
      _purchasePending = false;
      print('Purchase error: $e');
      return false;
    }
  }

  /// Handle purchase updates
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;

        if (purchaseDetails.status == PurchaseStatus.error) {
          print('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Add to purchases list
          if (!_purchases.contains(purchaseDetails)) {
            _purchases.add(purchaseDetails);
          }
        }

        // Complete the purchase
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

  /// Get receipt data as base64 string
  /// Note: For iOS, we use transaction IDs for verification instead of full receipt
  /// The backend can verify purchases using Apple's verifyReceipt API
  static Future<String?> getReceiptData() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      // For iOS, receipt verification is typically done server-side
      // We can return a placeholder or use transaction ID
      // The backend will handle receipt verification using Apple's API
      // Return empty string to indicate iOS purchase (backend will handle verification)
      return '';
    } catch (e) {
      print('Error getting receipt: $e');
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
      print('Error restoring purchases: $e');
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
