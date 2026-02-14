import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/services/vip_service.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:bananatalk_app/services/android_purchase_service.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'dart:async';

class VipPaymentScreen extends ConsumerStatefulWidget {
  final String userId;
  final VipPlan plan;

  const VipPaymentScreen({
    Key? key,
    required this.userId,
    required this.plan,
  }) : super(key: key);

  @override
  ConsumerState<VipPaymentScreen> createState() => _VipPaymentScreenState();
}

class _VipPaymentScreenState extends ConsumerState<VipPaymentScreen> {
  String? selectedPaymentMethod;
  bool isProcessing = false;
  bool _isIOS = Platform.isIOS;
  bool _isAndroid = Platform.isAndroid;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
    },
    {
      'id': 'paypal',
      'name': 'PayPal',
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'google_pay',
      'name': 'Google Pay',
      'icon': Icons.payment,
    },
    {
      'id': 'apple_pay',
      'name': 'Apple Pay',
      'icon': Icons.apple,
    },
  ];

  Future<void> _processPayment() async {
    // Check if userId is valid
    if (widget.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.userIdNotFound),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // On iOS, use in-app purchase
    if (_isIOS) {
      await _processIOSPurchase();
      return;
    }

    // On Android, use Google Play Billing
    if (_isAndroid) {
      await _processAndroidPurchase();
      return;
    }

    // For other platforms, use mockup payment
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectAPaymentMethod),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      await _processMockupPayment();
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      if (!mounted) return;

      _showErrorDialog('Payment Error', 'An error occurred: ${e.toString()}');
    }
  }

  Future<void> _processIOSPurchase() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Initialize store if not already done
      if (!IOSPurchaseService.isAvailable) {
        debugPrint('Initializing store...');
        final initialized = await IOSPurchaseService.initializeStore();
        if (!initialized) {
          throw Exception('Store not available. Please check your internet connection and App Store settings.');
        }
      }

      // Load products
      debugPrint('Loading products...');
      await IOSPurchaseService.loadProducts();

      // Check if products loaded successfully
      final products = IOSPurchaseService.getProducts();
      if (products.isEmpty) {
        final error = IOSPurchaseService.queryError;
        throw Exception('Failed to load products from App Store. ${error ?? "Please try again later."}');
      }

      // Get product ID based on plan (must match App Store Connect)
      String productId;
      switch (widget.plan) {
        case VipPlan.monthly:
          productId = 'com.bananatalk.bananatalkApp.vip.month';
          break;
        case VipPlan.quarterly:
          productId = 'com.bananatalk.bananatalkApp.vip.quarter';
          break;
        case VipPlan.yearly:
          productId = 'com.bananatalk.bananatalkApp.vip.year';
          break;
      }

      // Verify product exists before attempting purchase
      final product = IOSPurchaseService.getProduct(productId);
      if (product == null) {
        throw Exception('Product "$productId" not found. Available products: ${products.map((p) => p.id).join(", ")}');
      }

      debugPrint('Starting purchase for: $productId (${product.price})');

      // Initiate purchase and wait for completion
      final purchaseDetails = await IOSPurchaseService.purchaseProductAndWait(productId);

      if (purchaseDetails == null) {
        // Purchase was canceled or failed
        setState(() {
          isProcessing = false;
        });
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase was canceled or failed. Please try again.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      debugPrint('Purchase completed, verifying with backend...');

      // Get receipt data from the purchase
      final receiptData = IOSPurchaseService.getReceiptFromPurchase(purchaseDetails);
      final transactionId = purchaseDetails.purchaseID;

      if (receiptData == null || receiptData.isEmpty) {
        throw Exception('Failed to get receipt data from purchase. Please contact support.');
      }

      debugPrint('Receipt data length: ${receiptData.length}');
      debugPrint('Transaction ID: $transactionId');

      // Verify purchase with backend
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.verifying;

      final verifyResult = await VipService.verifyIOSPurchase(
        receiptData: receiptData,
        productId: productId,
        transactionId: transactionId,
      );

      debugPrint('Verification result: $verifyResult');

      setState(() {
        isProcessing = false;
      });

      if (!mounted) return;

      if (verifyResult['success'] == true) {
        // Refresh user data and limits
        ref.invalidate(userProvider);
        ref.invalidate(vipStatusProvider(widget.userId));
        ref.invalidate(userLimitsProvider(widget.userId));

        ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
        _showSuccessDialog();
      } else {
        ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
        ref.read(purchaseErrorProvider.notifier).state = verifyResult['error'];
        _showErrorDialog('Purchase Verification Failed', verifyResult['error'] ?? 'Could not verify purchase with server. Please contact support.');
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      setState(() {
        isProcessing = false;
      });

      ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
      ref.read(purchaseErrorProvider.notifier).state = e.toString();

      if (!mounted) return;

      _showErrorDialog('Purchase Error', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _processAndroidPurchase() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Initialize store if not already done
      if (!AndroidPurchaseService.isAvailable) {
        debugPrint('Initializing Google Play store...');
        final initialized = await AndroidPurchaseService.initializeStore();
        if (!initialized) {
          throw Exception(
              'Google Play Store not available. Please check your internet connection and Google Play settings.');
        }
      }

      // Load products
      debugPrint('Loading products...');
      await AndroidPurchaseService.loadProducts();

      // Check if products loaded successfully
      final products = AndroidPurchaseService.getProducts();
      if (products.isEmpty) {
        final error = AndroidPurchaseService.queryError;
        throw Exception(
            'Failed to load products from Google Play. ${error ?? "Please try again later."}');
      }

      // Get product ID based on plan (must match Google Play Console)
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

      // Verify product exists before attempting purchase
      final product = AndroidPurchaseService.getProduct(productId);
      if (product == null) {
        throw Exception(
            'Product "$productId" not found. Available products: ${products.map((p) => p.id).join(", ")}');
      }

      debugPrint('Starting purchase for: $productId (${product.price})');

      // Initiate purchase and wait for completion
      final purchaseDetails =
          await AndroidPurchaseService.purchaseProductAndWait(productId);

      if (purchaseDetails == null) {
        // Purchase was canceled or failed
        setState(() {
          isProcessing = false;
        });
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase was canceled or failed. Please try again.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      debugPrint('Purchase completed, verifying with backend...');

      // Get purchase token for verification
      final purchaseToken =
          AndroidPurchaseService.getPurchaseToken(purchaseDetails);
      final orderId = purchaseDetails.purchaseID;

      if (purchaseToken == null || purchaseToken.isEmpty) {
        throw Exception(
            'Failed to get purchase token from Google Play. Please contact support.');
      }

      debugPrint('Purchase token length: ${purchaseToken.length}');
      debugPrint('Order ID: $orderId');

      // Verify purchase with backend
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.verifying;

      final verifyResult = await VipService.verifyAndroidPurchase(
        purchaseToken: purchaseToken,
        productId: productId,
        orderId: orderId,
      );

      debugPrint('Verification result: $verifyResult');

      setState(() {
        isProcessing = false;
      });

      if (!mounted) return;

      if (verifyResult['success'] == true) {
        // Refresh user data and limits
        ref.invalidate(userProvider);
        ref.invalidate(vipStatusProvider(widget.userId));
        ref.invalidate(userLimitsProvider(widget.userId));

        ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
        _showSuccessDialog();
      } else {
        ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
        ref.read(purchaseErrorProvider.notifier).state = verifyResult['error'];
        _showErrorDialog('Purchase Verification Failed',
            verifyResult['error'] ?? 'Could not verify purchase with server. Please contact support.');
      }
    } catch (e) {
      debugPrint('Android purchase error: $e');
      setState(() {
        isProcessing = false;
      });

      ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
      ref.read(purchaseErrorProvider.notifier).state = e.toString();

      if (!mounted) return;

      _showErrorDialog(
          'Purchase Error', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _processMockupPayment() async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Simulate payment success (mockup - no actual payment processing)
    // In production, this would integrate with a real payment gateway
    final result = await VipService.activateVip(
      userId: widget.userId,
      plan: widget.plan,
      paymentMethod: selectedPaymentMethod!,
    );

    setState(() {
      isProcessing = false;
    });

    if (!mounted) return;

    if (result['success']) {
      _showSuccessDialog();
    } else {
      _showErrorDialog('Payment Failed', result['error'] ?? 'Payment failed');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            Spacing.gapLG,
            Text(
              'Welcome to VIP!',
              style: context.displaySmall,
            ),
            Spacing.gapSM,
            Text(
              'Your VIP subscription is now active. Enjoy all premium features!',
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              AppLocalizations.of(context)!.startExploring,
              style: context.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
        ),
        title: Text(
          title,
          style: context.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An error occurred while processing your payment:',
                style: context.labelLarge,
              ),
              Spacing.gapMD,
              Text(
                message,
                style: context.bodyMedium,
              ),
              Spacing.gapMD,
              Text(
                'Debug Info:',
                style: context.labelSmall,
              ),
              Text(
                'User ID: ${widget.userId}\nPlan: ${widget.plan.name}\nPayment: $selectedPaymentMethod',
                style: context.captionSmall.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: context.labelLarge.copyWith(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processPayment(); // Retry
            },
            child: Text(
              AppLocalizations.of(context)!.retry,
              style: context.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.payment,
          style: context.titleLarge,
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Plan Summary
            Container(
              width: double.infinity,
              padding: Spacing.paddingXXL,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Summary',
                    style: context.titleLarge,
                  ),
                  Spacing.gapLG,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.plan.displayName,
                        style: context.bodyLarge,
                      ),
                      Text(
                        '\$${widget.plan.price}',
                        style: context.displaySmall,
                      ),
                    ],
                  ),
                  Spacing.gapSM,
                  Text(
                    widget.plan.description,
                    style: context.bodySmall,
                  ),
                ],
              ),
            ),

            // Payment Methods (only for platforms without native billing)
            if (!_isIOS && !_isAndroid)
              Padding(
                padding: Spacing.paddingXXL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Payment Method',
                      style: context.titleLarge,
                    ),
                    Spacing.gapLG,
                    ...paymentMethods.map((method) {
                      return _buildPaymentMethodCard(
                        id: method['id'],
                        name: method['name'],
                        icon: method['icon'],
                      );
                    }).toList(),
                  ],
                ),
              ),

            // iOS Purchase Info
            if (_isIOS)
              Padding(
                padding: Spacing.paddingXXL,
                child: Container(
                  padding: Spacing.paddingXL,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: AppRadius.borderMD,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.apple,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      Spacing.gapMD,
                      Text(
                        'Purchase via App Store',
                        style: context.titleMedium,
                      ),
                      Spacing.gapSM,
                      Text(
                        'Your purchase will be processed securely through the App Store.',
                        style: context.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Android Purchase Info
            if (_isAndroid)
              Padding(
                padding: Spacing.paddingXXL,
                child: Container(
                  padding: Spacing.paddingXL,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: AppRadius.borderMD,
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shop,
                        size: 48,
                        color: AppColors.success,
                      ),
                      Spacing.gapMD,
                      Text(
                        'Purchase via Google Play',
                        style: context.titleMedium,
                      ),
                      Spacing.gapSM,
                      Text(
                        'Your purchase will be processed securely through Google Play.',
                        style: context.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Subscription Information (required for App Store)
            Padding(
              padding: Spacing.paddingXXL,
              child: Container(
                padding: Spacing.paddingLG,
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: AppRadius.borderMD,
                  border: Border.all(color: context.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Information',
                      style: context.titleMedium,
                    ),
                    Spacing.gapMD,
                    _buildSubscriptionInfoRow('Title', widget.plan.displayName),
                    _buildSubscriptionInfoRow('Length', _getSubscriptionLength()),
                    _buildSubscriptionInfoRow('Price', '\$${widget.plan.price}'),
                    Spacing.gapLG,
                    Divider(color: context.dividerColor),
                    Spacing.gapMD,
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/terms-of-use'),
                            icon: Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                            label: Text(
                              'Terms of Use',
                              style: context.labelSmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/privacy-policy'),
                            icon: Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.primary),
                            label: Text(
                              'Privacy Policy',
                              style: context.labelSmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Terms and Conditions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'By completing this purchase, you agree to our Terms of Use and Privacy Policy. Your subscription will automatically renew unless cancelled at least 24 hours before the end of the current period.',
                style: context.caption,
                textAlign: TextAlign.center,
              ),
            ),

            // Pay Button
            Padding(
              padding: Spacing.paddingXXL,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          _isIOS
                              ? 'Purchase via App Store'
                              : _isAndroid
                                  ? 'Purchase via Google Play'
                                  : 'Pay \$${widget.plan.price}',
                          style: context.titleMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String id,
    required String name,
    required IconData icon,
  }) {
    final isSelected = selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? AppColors.primary : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.borderMD,
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : context.cardBackground,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: id,
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value;
                });
              },
              activeColor: AppColors.primary,
            ),
            Spacing.hGapMD,
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.primary
                  : context.textSecondary,
            ),
            Spacing.hGapLG,
            Text(
              name,
              style: context.titleSmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubscriptionLength() {
    switch (widget.plan) {
      case VipPlan.monthly:
        return '1 month';
      case VipPlan.quarterly:
        return '3 months';
      case VipPlan.yearly:
        return '1 year';
    }
  }

  Widget _buildSubscriptionInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.bodySmall,
          ),
          Text(
            value,
            style: context.labelLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
