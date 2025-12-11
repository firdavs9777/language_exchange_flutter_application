import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/services/vip_service.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
        const SnackBar(
          content: Text('User ID not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // On iOS, use in-app purchase
    if (_isIOS) {
      await _processIOSPurchase();
      return;
    }

    // For other platforms, use mockup payment
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
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
        final initialized = await IOSPurchaseService.initializeStore();
        if (!initialized) {
          throw Exception('Store not available');
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

      // Get product ID based on plan
      String productId;
      switch (widget.plan) {
        case VipPlan.monthly:
          productId = 'com.bananatalk.bananatalkApp.monthly';
          break;
        case VipPlan.quarterly:
          productId = 'com.bananatalk.bananatalkApp.quarterly';
          break;
        case VipPlan.yearly:
          productId = 'com.bananatalk.bananatalkApp.yearly';
          break;
      }

      // Verify product exists before attempting purchase
      final product = IOSPurchaseService.getProduct(productId);
      if (product == null) {
        throw Exception('Product "$productId" not found. Available products: ${products.map((p) => p.id).join(", ")}');
      }

      // Initiate purchase
      final purchaseInitiated = await IOSPurchaseService.purchaseProduct(productId);
      if (!purchaseInitiated) {
        final error = IOSPurchaseService.queryError;
        throw Exception('Failed to initiate purchase. ${error ?? "Please check your App Store settings and try again."}');
      }

      // Wait for purchase to complete (this is handled by the purchase stream)
      // For now, we'll verify after a short delay
      await Future.delayed(const Duration(seconds: 2));

      // Get receipt data (may be empty for iOS - backend handles verification)
      final receiptData = await IOSPurchaseService.getReceiptData();
      final transactionId = IOSPurchaseService.getLatestTransactionId();

      // Verify purchase with backend
      ref.read(purchaseStateProvider.notifier).state = PurchaseState.verifying;
      
      final verifyResult = await VipService.verifyIOSPurchase(
        receiptData: receiptData ?? '',
        productId: productId,
        transactionId: transactionId,
      );

      setState(() {
        isProcessing = false;
      });

      if (!mounted) return;

      if (verifyResult['success'] == true) {
        // Refresh user data and limits
        ref.refresh(userProvider);
        ref.refresh(vipStatusProvider(widget.userId));
        ref.refresh(userLimitsProvider(widget.userId));
        
        ref.read(purchaseStateProvider.notifier).state = PurchaseState.success;
        _showSuccessDialog();
      } else {
        ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
        ref.read(purchaseErrorProvider.notifier).state = verifyResult['error'];
        _showErrorDialog('Purchase Failed', verifyResult['error'] ?? 'Purchase verification failed');
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      ref.read(purchaseStateProvider.notifier).state = PurchaseState.error;
      ref.read(purchaseErrorProvider.notifier).state = e.toString();

      if (!mounted) return;

      _showErrorDialog('Purchase Error', 'An error occurred: ${e.toString()}');
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
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to VIP!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your VIP subscription is now active. Enjoy all premium features!',
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
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'An error occurred while processing your payment:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 12),
              const Text(
                'Debug Info:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'User ID: ${widget.userId}\nPlan: ${widget.plan.name}\nPayment: $selectedPaymentMethod',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processPayment(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Plan Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.plan.displayName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '\$${widget.plan.price}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.plan.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Payment Methods (only for non-iOS platforms)
            if (!_isIOS)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.apple,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Purchase via App Store',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your purchase will be processed securely through the App Store.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Subscription Information (required for App Store)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subscription Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSubscriptionInfoRow('Title', widget.plan.displayName),
                    _buildSubscriptionInfoRow('Length', _getSubscriptionLength()),
                    _buildSubscriptionInfoRow('Price', '\$${widget.plan.price}'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/terms-of-use'),
                            icon: const Icon(Icons.description_outlined, size: 18),
                            label: const Text(
                              'Terms of Use',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/privacy-policy'),
                            icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                            label: const Text(
                              'Privacy Policy',
                              style: TextStyle(fontSize: 13),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Pay Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isIOS ? 'Purchase via App Store' : 'Pay \$${widget.plan.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.white,
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
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
            const SnackBar(
              content: Text('Could not open link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
