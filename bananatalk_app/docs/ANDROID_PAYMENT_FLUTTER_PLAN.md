# Android Payment Flutter Implementation Plan

## Overview

This document outlines the implementation plan for adding Google Play Billing support to the BananaTalk Flutter app. The iOS implementation (`IOSPurchaseService`) serves as a template.

## Current State

### What Exists
| Component | Status | Notes |
|-----------|--------|-------|
| `in_app_purchase` package | ✅ Installed | v3.1.11 - supports both platforms |
| `IOSPurchaseService` | ✅ Complete | Template for Android service |
| `VipPaymentScreen` | ⚠️ Partial | iOS real, Android mockup |
| `VipService` | ⚠️ Partial | Has iOS verify, no Android |
| VIP models | ✅ Complete | No changes needed |

### What's Missing
- `AndroidPurchaseService` class
- Android verification method in `VipService`
- Real billing flow in `VipPaymentScreen` for Android
- Google Play product ID configuration

---

## Implementation Tasks

### Phase 1: Create Android Purchase Service

**File:** `lib/services/android_purchase_service.dart`

Mirror the iOS service structure:

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

typedef PurchaseCallback = void Function(
  PurchaseDetails details,
  bool success,
  String? error,
);

class AndroidPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static bool _purchasePending = false;
  static String? _queryProductError;
  static PurchaseCallback? _purchaseCallback;
  static Completer<PurchaseDetails?>? _purchaseCompleter;

  // Product IDs (must match Google Play Console)
  static const Set<String> _productIds = {
    'com.bananatalk.app.vip.monthly',
    'com.bananatalk.app.vip.quarterly',
    'com.bananatalk.app.vip.yearly',
  };

  static final List<ProductDetails> _products = [];
  static final List<PurchaseDetails> _purchases = [];

  /// Initialize the Google Play connection
  static Future<bool> initializeStore() async {
    if (!Platform.isAndroid) return false;

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _queryProductError = 'Google Play not available';
      return false;
    }

    _isAvailable = available;

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    await loadProducts();
    return true;
  }

  /// Load products from Google Play
  static Future<void> loadProducts() async {
    if (!_isAvailable) await initializeStore();

    final response = await _inAppPurchase.queryProductDetails(_productIds);

    if (response.error != null) {
      _queryProductError = response.error!.message;
      return;
    }

    if (response.productDetails.isEmpty) {
      _queryProductError = 'No products found: ${response.notFoundIDs}';
      return;
    }

    _products.clear();
    _products.addAll(response.productDetails);
    _queryProductError = null;
  }

  /// Purchase a subscription product
  static Future<PurchaseDetails?> purchaseProductAndWait(String productId) async {
    if (!_isAvailable) {
      final initialized = await initializeStore();
      if (!initialized) return null;
    }

    if (_products.isEmpty) {
      await loadProducts();
      if (_products.isEmpty) return null;
    }

    final product = getProduct(productId);
    if (product == null) return null;

    if (_purchasePending) return null;

    _purchasePending = true;
    _purchaseCompleter = Completer<PurchaseDetails?>();

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // Use buyNonConsumable for subscriptions
      final initiated = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!initiated) {
        _purchasePending = false;
        _purchaseCompleter = null;
        return null;
      }

      // Wait for purchase with timeout
      final result = await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => null,
      );

      _purchaseCompleter = null;
      return result;
    } catch (e) {
      _purchasePending = false;
      _purchaseCompleter = null;
      return null;
    }
  }

  /// Handle purchase stream updates
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;

        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _purchases.add(purchase);
            _purchaseCompleter?.complete(purchase);
            _purchaseCallback?.call(purchase, true, null);
            break;
          case PurchaseStatus.error:
            _purchaseCompleter?.complete(null);
            _purchaseCallback?.call(purchase, false, purchase.error?.message);
            break;
          case PurchaseStatus.canceled:
            _purchaseCompleter?.complete(null);
            _purchaseCallback?.call(purchase, false, 'Canceled');
            break;
          default:
            break;
        }

        // Acknowledge the purchase (required for Google Play)
        if (purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }
      }
    }
  }

  /// Get purchase token for backend verification
  static String? getPurchaseToken(PurchaseDetails purchase) {
    return purchase.verificationData.serverVerificationData;
  }

  // ... Additional helper methods similar to iOS service
  static List<ProductDetails> getProducts() => List.unmodifiable(_products);
  static ProductDetails? getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
  static bool get isAvailable => _isAvailable;
  static bool get isPurchasePending => _purchasePending;
  static String? get queryError => _queryProductError;

  static Future<void> restorePurchases() async {
    if (_isAvailable) await _inAppPurchase.restorePurchases();
  }

  static void dispose() {
    _subscription?.cancel();
    _products.clear();
    _purchases.clear();
  }
}
```

---

### Phase 2: Update VipService

**File:** `lib/services/vip_service.dart`

Add Android verification method:

```dart
/// Verify Android purchase with backend
static Future<Map<String, dynamic>> verifyAndroidPurchase({
  required String purchaseToken,
  required String productId,
  required String? orderId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${Endpoints.baseUrl}/purchases/android/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await getAuthToken()}',
      },
      body: jsonEncode({
        'purchaseToken': purchaseToken,
        'productId': productId,
        'orderId': orderId,
        'packageName': 'com.bananatalk.app',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'error': error['message'] ?? 'Verification failed',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Network error: $e',
    };
  }
}

/// Check Android subscription status
static Future<Map<String, dynamic>> checkAndroidSubscriptionStatus({
  required String purchaseToken,
  required String productId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${Endpoints.baseUrl}/purchases/android/subscription-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await getAuthToken()}',
      },
      body: jsonEncode({
        'purchaseToken': purchaseToken,
        'productId': productId,
      }),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

---

### Phase 3: Update Endpoints

**File:** `lib/service/endpoints.dart`

Add Android endpoints:

```dart
// Android Purchase Endpoints
static String get androidVerifyPurchaseURL => '$baseUrl/purchases/android/verify';
static String get androidSubscriptionStatusURL => '$baseUrl/purchases/android/subscription-status';
```

---

### Phase 4: Update VipPaymentScreen

**File:** `lib/pages/vip/vip_payment_screen.dart`

Replace mockup payment with real Android flow:

```dart
// Add import
import 'package:bananatalk_app/services/android_purchase_service.dart';

// Update _processPayment method
Future<void> _processPayment() async {
  if (widget.userId.isEmpty) {
    // ... error handling
    return;
  }

  if (_isIOS) {
    await _processIOSPurchase();
    return;
  }

  // Android - use real Google Play purchase
  if (Platform.isAndroid) {
    await _processAndroidPurchase();
    return;
  }

  // Fallback for other platforms (web, etc.)
  await _processMockupPayment();
}

// Add new Android purchase method
Future<void> _processAndroidPurchase() async {
  setState(() => isProcessing = true);

  try {
    // Initialize store
    if (!AndroidPurchaseService.isAvailable) {
      final initialized = await AndroidPurchaseService.initializeStore();
      if (!initialized) {
        throw Exception('Google Play not available');
      }
    }

    // Load products
    await AndroidPurchaseService.loadProducts();
    final products = AndroidPurchaseService.getProducts();
    if (products.isEmpty) {
      throw Exception('Failed to load products: ${AndroidPurchaseService.queryError}');
    }

    // Get product ID for selected plan
    String productId;
    switch (widget.plan) {
      case VipPlan.monthly:
        productId = 'com.bananatalk.app.vip.monthly';
        break;
      case VipPlan.quarterly:
        productId = 'com.bananatalk.app.vip.quarterly';
        break;
      case VipPlan.yearly:
        productId = 'com.bananatalk.app.vip.yearly';
        break;
    }

    // Verify product exists
    final product = AndroidPurchaseService.getProduct(productId);
    if (product == null) {
      throw Exception('Product not found: $productId');
    }

    // Initiate purchase
    final purchaseDetails = await AndroidPurchaseService.purchaseProductAndWait(productId);

    if (purchaseDetails == null) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase was canceled or failed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get purchase token for verification
    final purchaseToken = AndroidPurchaseService.getPurchaseToken(purchaseDetails);
    final orderId = purchaseDetails.purchaseID;

    if (purchaseToken == null) {
      throw Exception('Failed to get purchase token');
    }

    // Verify with backend
    ref.read(purchaseStateProvider.notifier).state = PurchaseState.verifying;

    final verifyResult = await VipService.verifyAndroidPurchase(
      purchaseToken: purchaseToken,
      productId: productId,
      orderId: orderId,
    );

    setState(() => isProcessing = false);

    if (verifyResult['success'] == true) {
      ref.invalidate(userProvider);
      ref.invalidate(vipStatusProvider(widget.userId));
      ref.invalidate(userLimitsProvider(widget.userId));
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
      _showSuccessDialog();
    } else {
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
      _showErrorDialog('Verification Failed', verifyResult['error'] ?? 'Unknown error');
    }
  } catch (e) {
    setState(() => isProcessing = false);
    ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
    _showErrorDialog('Purchase Error', e.toString());
  }
}
```

Update the UI to show Google Play branding for Android:

```dart
// Update build method - replace iOS check with platform-aware branding
if (Platform.isAndroid)
  Padding(
    padding: const EdgeInsets.all(24),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.shop, size: 48, color: Colors.green[700]),
          const SizedBox(height: 12),
          const Text(
            'Purchase via Google Play',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your purchase will be processed securely through Google Play.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ),
```

---

### Phase 5: Update VIP Providers

**File:** `lib/providers/provider_root/vip_provider.dart`

Add Android products provider:

```dart
// Android products provider
final androidProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  if (!Platform.isAndroid) return [];

  await AndroidPurchaseService.initializeStore();
  await AndroidPurchaseService.loadProducts();
  return AndroidPurchaseService.getProducts();
});
```

---

### Phase 6: Update VIP Plans Screen

**File:** `lib/pages/vip/vip_plans_screen.dart`

Load products based on platform:

```dart
@override
void initState() {
  super.initState();
  _loadProducts();
}

Future<void> _loadProducts() async {
  if (Platform.isIOS) {
    await IOSPurchaseService.initializeStore();
  } else if (Platform.isAndroid) {
    await AndroidPurchaseService.initializeStore();
  }
}

// Update price display to use platform-specific products
String _getPrice(VipPlan plan) {
  final products = Platform.isIOS
    ? IOSPurchaseService.getProducts()
    : Platform.isAndroid
      ? AndroidPurchaseService.getProducts()
      : [];

  // Map plan to product ID and get price
  // ... implementation
}
```

---

## Product ID Configuration

### Google Play Console Setup

Create subscription products with these IDs:

| Product ID | Plan | Price |
|------------|------|-------|
| `com.bananatalk.app.vip.monthly` | Monthly | $14.99 |
| `com.bananatalk.app.vip.quarterly` | Quarterly | $19.99 |
| `com.bananatalk.app.vip.yearly` | Yearly | $49.99 |

**Important:** Product IDs in Flutter must exactly match Google Play Console.

---

## File Structure After Implementation

```
lib/
├── services/
│   ├── ios_purchase_service.dart      # Existing
│   ├── android_purchase_service.dart  # NEW
│   └── vip_service.dart               # Updated
├── pages/vip/
│   ├── vip_payment_screen.dart        # Updated
│   └── vip_plans_screen.dart          # Updated
├── providers/
│   └── provider_root/
│       └── vip_provider.dart          # Updated
└── service/
    └── endpoints.dart                 # Updated
```

---

## Testing Checklist

### Pre-Release Testing

- [ ] Test with Google Play license testers
- [ ] Verify products load correctly
- [ ] Test purchase flow completion
- [ ] Test purchase cancellation
- [ ] Verify backend receives purchase token
- [ ] Test subscription activation
- [ ] Test restore purchases
- [ ] Test on multiple Android versions (API 24+)

### Edge Cases

- [ ] Network failure during purchase
- [ ] Network failure during verification
- [ ] User cancels at payment sheet
- [ ] Duplicate purchase attempts
- [ ] Already subscribed user tries to purchase
- [ ] App killed during purchase flow

---

## Dependencies

No new dependencies required. The existing `in_app_purchase: ^3.1.11` supports both platforms.

Optional for enhanced Android features:
```yaml
# Already using cross-platform package
in_app_purchase: ^3.1.11

# Optional: For Android-specific features
in_app_purchase_android: ^0.3.0  # Included transitively
```

---

## Comparison: iOS vs Android

| Aspect | iOS | Android |
|--------|-----|---------|
| Verification Data | Receipt (base64) | Purchase Token |
| Transaction ID | `purchaseID` | `orderId` |
| Complete Purchase | Required | Required (acknowledge) |
| Restore | `restorePurchases()` | `restorePurchases()` |
| Subscription Type | Non-consumable | Non-consumable |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Google Play not available on device | Check `isAvailable` before purchase |
| Products not loading | Show error, allow retry |
| Purchase timeout | 5-minute timeout with user feedback |
| Backend verification fails | Show error, store purchase locally for retry |
| Duplicate purchases | Backend checks transaction history |

---

## Estimated Changes

| File | Change Type | Lines |
|------|-------------|-------|
| `android_purchase_service.dart` | New | ~200 |
| `vip_service.dart` | Add methods | ~50 |
| `vip_payment_screen.dart` | Update | ~100 |
| `vip_plans_screen.dart` | Update | ~30 |
| `vip_provider.dart` | Add provider | ~10 |
| `endpoints.dart` | Add endpoints | ~5 |

---

## Implementation Order

1. **Create `AndroidPurchaseService`** - Core billing logic
2. **Add endpoints to `endpoints.dart`** - API URLs
3. **Add verification to `VipService`** - Backend communication
4. **Update `VipPaymentScreen`** - Purchase flow
5. **Update `VipPlansScreen`** - Product loading
6. **Add provider to `vip_provider.dart`** - State management
7. **Test with license testing accounts**

---

## References

- [Flutter in_app_purchase](https://pub.dev/packages/in_app_purchase)
- [Google Play Billing](https://developer.android.com/google/play/billing)
- Existing iOS implementation: `lib/services/ios_purchase_service.dart`
- Backend plan: `../backend/docs/ANDROID_PAYMENT_IMPLEMENTATION_PLAN.md`
