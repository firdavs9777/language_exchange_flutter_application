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
import 'package:bananatalk_app/services/analytics_service.dart';
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
      if (!mounted) return;
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog(
        AppLocalizations.of(context)!.vipErrorPaymentTitle,
        'An error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> _processIOSPurchase() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Initialize store if not already done
      if (!IOSPurchaseService.isAvailable) {
        final initialized = await IOSPurchaseService.initializeStore();
        if (!initialized) {
          throw Exception('Store not available. Please check your internet connection and App Store settings.');
        }
      }

      // Load products
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


      // Initiate purchase and wait for completion
      final purchaseDetails = await IOSPurchaseService.purchaseProductAndWait(productId);

      if (purchaseDetails == null) {
        // Purchase was canceled or failed
        if (!mounted) return;
        setState(() {
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.vipErrorPurchaseCanceled,
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }


      // Get receipt data from the purchase
      final receiptData = IOSPurchaseService.getReceiptFromPurchase(purchaseDetails);
      final transactionId = purchaseDetails.purchaseID;

      if (receiptData == null || receiptData.isEmpty) {
        throw Exception('Failed to get receipt data from purchase. Please contact support.');
      }


      // Verify purchase with backend
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.verifying;

      final verifyResult = await VipService.verifyIOSPurchase(
        receiptData: receiptData,
        productId: productId,
        transactionId: transactionId,
      );


      if (!mounted) return;
      setState(() {
        isProcessing = false;
      });

      if (verifyResult['success'] == true) {
        // Step 13A: webhook race fix. Apple/Google webhook may not have
        // processed by the time we re-fetch /vip/status. Retry up to 3
        // times over ~6 seconds. Only show success when backend
        // confirms isVIP === true.
        bool confirmedVip = false;
        for (int attempt = 1; attempt <= 3; attempt++) {
          ref.invalidate(userProvider);
          ref.invalidate(vipStatusProvider(widget.userId));
          ref.invalidate(userLimitsProvider(widget.userId));
          try {
            final status = await ref.read(vipStatusProvider(widget.userId).future);
            if (status['isVIP'] == true) {
              confirmedVip = true;
              break;
            }
          } catch (_) {
            // Soft-fail; retry until budget exhausted.
          }
          if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
        }
        if (!mounted) return;
        if (confirmedVip) {
          ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
          AnalyticsService.instance.subscriptionPurchased(
            plan: widget.plan.name,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
          _showSuccessDialog();
        } else {
          ref.read(purchaseStateProvider.notifier).state = PurchaseState.pending;
          _showPendingDialog();
        }
      } else {
        AnalyticsService.instance.subscriptionPurchaseFailed(
          plan: widget.plan.name,
          platform: Platform.isIOS ? 'ios' : 'android',
          errorCode: verifyResult['error']?.toString() ?? 'unknown',
        );
        ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
        ref.read(purchaseErrorProvider.notifier).state = verifyResult['error'];
        _showErrorDialog(
          AppLocalizations.of(context)!.vipErrorVerifyTitle,
          verifyResult['error'] ??
              AppLocalizations.of(context)!.vipErrorVerifyServer,
        );
      }
    } catch (e) {
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
      ref.read(purchaseErrorProvider.notifier).state = e.toString();

      if (!mounted) return;
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog(
        AppLocalizations.of(context)!.vipErrorPurchaseTitle,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.vipPendingTitle),
        content: Text(AppLocalizations.of(dialogContext)!.vipPendingBody),
        actions: [
          TextButton(
            onPressed: () {
              // Capture the navigator before the first pop. Reusing the
              // dialog's `context` after pop() is what caused the dark
              // screen on real devices — once the dialog route is gone,
              // the context can't reliably look up the Navigator again.
              final nav = Navigator.of(dialogContext, rootNavigator: true);
              nav.pop(); // close dialog
              if (nav.canPop()) nav.pop(); // close payment screen
            },
            child: Text(AppLocalizations.of(dialogContext)!.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _processAndroidPurchase() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Initialize store if not already done
      if (!AndroidPurchaseService.isAvailable) {
        final initialized = await AndroidPurchaseService.initializeStore();
        if (!initialized) {
          throw Exception(
              'Google Play Store not available. Please check your internet connection and Google Play settings.');
        }
      }

      // Load products
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


      // Initiate purchase and wait for completion
      final purchaseDetails =
          await AndroidPurchaseService.purchaseProductAndWait(productId);

      if (purchaseDetails == null) {
        // Purchase was canceled or failed
        if (!mounted) return;
        setState(() {
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.vipErrorPurchaseCanceled,
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }


      // Get purchase token for verification
      final purchaseToken =
          AndroidPurchaseService.getPurchaseToken(purchaseDetails);
      final orderId = purchaseDetails.purchaseID;

      if (purchaseToken == null || purchaseToken.isEmpty) {
        throw Exception(
            'Failed to get purchase token from Google Play. Please contact support.');
      }


      // Verify purchase with backend
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.verifying;

      final verifyResult = await VipService.verifyAndroidPurchase(
        purchaseToken: purchaseToken,
        productId: productId,
        orderId: orderId,
      );


      if (!mounted) return;
      setState(() {
        isProcessing = false;
      });

      if (verifyResult['success'] == true) {
        // Step 13A: webhook race fix — same pattern as iOS path.
        bool confirmedVip = false;
        for (int attempt = 1; attempt <= 3; attempt++) {
          ref.invalidate(userProvider);
          ref.invalidate(vipStatusProvider(widget.userId));
          ref.invalidate(userLimitsProvider(widget.userId));
          try {
            final status = await ref.read(vipStatusProvider(widget.userId).future);
            if (status['isVIP'] == true) {
              confirmedVip = true;
              break;
            }
          } catch (_) {}
          if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
        }
        if (!mounted) return;
        if (confirmedVip) {
          ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
          AnalyticsService.instance.subscriptionPurchased(
            plan: widget.plan.name, platform: 'android',
          );
          _showSuccessDialog();
        } else {
          ref.read(purchaseStateProvider.notifier).state = PurchaseState.pending;
          _showPendingDialog();
        }
      } else {
        AnalyticsService.instance.subscriptionPurchaseFailed(
          plan: widget.plan.name, platform: 'android',
          errorCode: verifyResult['error']?.toString() ?? 'unknown',
        );
        ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
        ref.read(purchaseErrorProvider.notifier).state = verifyResult['error'];
        _showErrorDialog(
          AppLocalizations.of(context)!.vipErrorVerifyTitle,
          verifyResult['error'] ??
              AppLocalizations.of(context)!.vipErrorVerifyServer,
        );
      }
    } catch (e) {
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
      ref.read(purchaseErrorProvider.notifier).state = e.toString();

      if (!mounted) return;
      setState(() {
        isProcessing = false;
      });
      _showErrorDialog(
        AppLocalizations.of(context)!.vipErrorPurchaseTitle,
        e.toString().replaceAll('Exception: ', ''),
      );
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

    if (!mounted) return;
    setState(() {
      isProcessing = false;
    });

    if (result['success']) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(
        AppLocalizations.of(context)!.vipErrorPaymentFailed,
        result['error'] ?? AppLocalizations.of(context)!.vipErrorPaymentFailed,
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
              AppLocalizations.of(dialogContext)!.vipSuccessTitle,
              style: dialogContext.displaySmall,
            ),
            Spacing.gapSM,
            Text(
              AppLocalizations.of(dialogContext)!.vipSuccessBody,
              style: dialogContext.bodyMedium.copyWith(
                color: dialogContext.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Capture navigator BEFORE the first pop so subsequent pops
              // don't rely on a context whose route has already been
              // disposed. canPop gates each step in case the caller's
              // route stack is shallower than expected. This is the fix
              // for the dark-screen-after-upgrade issue on real devices.
              final nav = Navigator.of(
                dialogContext,
                rootNavigator: true,
              );
              nav.pop(); // close dialog
              if (nav.canPop()) nav.pop(); // close payment screen
              if (nav.canPop()) nav.pop(); // close plans screen
            },
            child: Text(
              AppLocalizations.of(dialogContext)!.startExploring,
              style: dialogContext.labelLarge
                  .copyWith(color: AppColors.primary),
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
                AppLocalizations.of(context)!.vipErrorBodyPrefix,
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
                    AppLocalizations.of(context)!.vipPaymentPlanSummary,
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
                      AppLocalizations.of(context)!.vipPaymentSelectMethod,
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
                        AppLocalizations.of(context)!
                            .vipPaymentPurchaseAppStore,
                        style: context.titleMedium,
                      ),
                      Spacing.gapSM,
                      Text(
                        AppLocalizations.of(context)!.vipPaymentSecureAppStore,
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
                        AppLocalizations.of(context)!
                            .vipPaymentPurchaseGooglePlay,
                        style: context.titleMedium,
                      ),
                      Spacing.gapSM,
                      Text(
                        AppLocalizations.of(context)!
                            .vipPaymentSecureGooglePlay,
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
                      AppLocalizations.of(context)!.vipPaymentSubscriptionInfo,
                      style: context.titleMedium,
                    ),
                    Spacing.gapMD,
                    _buildSubscriptionInfoRow(
                      AppLocalizations.of(context)!.vipPaymentInfoLabelTitle,
                      widget.plan.displayName,
                    ),
                    _buildSubscriptionInfoRow(
                      AppLocalizations.of(context)!.vipPaymentInfoLabelLength,
                      _getSubscriptionLength(),
                    ),
                    _buildSubscriptionInfoRow(
                      AppLocalizations.of(context)!.vipPaymentInfoLabelPrice,
                      '\$${widget.plan.price}',
                    ),
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
                              AppLocalizations.of(context)!.termsOfUse,
                              style: context.labelSmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/privacy-policy'),
                            icon: Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.primary),
                            label: Text(
                              AppLocalizations.of(context)!.privacyPolicy,
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
                AppLocalizations.of(context)!.vipPaymentDisclosure,
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
                              ? AppLocalizations.of(context)!
                                  .vipPaymentPurchaseAppStore
                              : _isAndroid
                                  ? AppLocalizations.of(context)!
                                      .vipPaymentPurchaseGooglePlay
                                  : AppLocalizations.of(context)!
                                      .vipPaymentPayPrice(
                                      '\$${widget.plan.price}',
                                    ),
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
    final l10n = AppLocalizations.of(context)!;
    switch (widget.plan) {
      case VipPlan.monthly:
        return l10n.vipPlanLengthOneMonth;
      case VipPlan.quarterly:
        return l10n.vipPlanLengthThreeMonths;
      case VipPlan.yearly:
        return l10n.vipPlanLengthOneYear;
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
