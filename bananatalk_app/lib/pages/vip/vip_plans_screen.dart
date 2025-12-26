import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/vip_payment_screen.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class VipPlansScreen extends ConsumerStatefulWidget {
  final String userId;

  const VipPlansScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<VipPlansScreen> createState() => _VipPlansScreenState();
}

class _VipPlansScreenState extends ConsumerState<VipPlansScreen> {
  VipPlan? selectedPlan;
  bool _isIOS = Platform.isIOS;

  @override
  void initState() {
    super.initState();
    // Initialize iOS store if on iOS
    if (_isIOS) {
      IOSPurchaseService.initializeStore();
      IOSPurchaseService.loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while products are loading on iOS
    if (_isIOS) {
      final productsAsync = ref.watch(iosProductsProvider);
      return productsAsync.when(
        data: (products) => _buildContent(),
        loading: () => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.upgradeToVIP),
            elevation: 0,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.upgradeToVIP),
            elevation: 0,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('${AppLocalizations.of(context)!.errorLoadingProducts}: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(iosProductsProvider);
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to VIP'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlock VIP Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get unlimited access to all premium features',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VIP Features',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.message,
                    title: AppLocalizations.of(context)!.unlimitedMessages,
                    description: 'Send unlimited messages to anyone',
                  ),
                  _buildFeatureItem(
                    icon: Icons.visibility,
                    title: AppLocalizations.of(context)!.unlimitedProfileViews,
                    description: 'View as many profiles as you want',
                  ),
                  _buildFeatureItem(
                    icon: Icons.support_agent,
                    title: AppLocalizations.of(context)!.prioritySupport,
                    description: 'Get faster responses from our team',
                  ),
                  _buildFeatureItem(
                    icon: Icons.search,
                    title: AppLocalizations.of(context)!.advancedSearch,
                    description: 'Access advanced search filters',
                  ),
                  _buildFeatureItem(
                    icon: Icons.trending_up,
                    title: AppLocalizations.of(context)!.profileBoost,
                    description: 'Get more visibility in search results',
                  ),
                  _buildFeatureItem(
                    icon: Icons.block,
                    title: AppLocalizations.of(context)!.adFreeExperience,
                    description: 'Enjoy the app without advertisements',
                  ),
                ],
              ),
            ),

            // Plans Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(VipPlan.monthly),
                  const SizedBox(height: 12),
                  _buildPlanCard(VipPlan.quarterly, popular: true),
                  const SizedBox(height: 12),
                  _buildPlanCard(VipPlan.yearly),
                ],
              ),
            ),

            // Subscription Information (required for App Store)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    if (selectedPlan != null) ...[
                      _buildSubscriptionInfoRow('Title', selectedPlan!.displayName),
                      _buildSubscriptionInfoRow('Length', _getSubscriptionLength(selectedPlan!)),
                      _buildSubscriptionInfoRow('Price', '\$${selectedPlan!.price}'),
                      const SizedBox(height: 12),
                    ] else
                      const Text(
                        'Please select a plan to see subscription details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
                    Text(
                      'Payment is charged to your iTunes Account or Google Play account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedPlan != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VipPaymentScreen(
                                userId: widget.userId,
                                plan: selectedPlan!,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(VipPlan plan, {bool popular = false}) {
    final isSelected = selectedPlan == plan;
    
    // Get product details from StoreKit if iOS
    String productId;
    switch (plan) {
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

    // Try to get product from StoreKit
    ProductDetails? product;
    if (_isIOS) {
      final productsAsync = ref.watch(iosProductsProvider);
      productsAsync.whenData((products) {
        try {
          product = products.firstWhere((p) => p.id == productId);
        } catch (e) {
          // Product not found, use default price
        }
      });
    }

    // Use StoreKit price if available, otherwise use default
    final priceText = product?.price ?? '\$${plan.price}';

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = plan;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.white,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Radio<VipPlan>(
                    value: plan,
                    groupValue: selectedPlan,
                    onChanged: (value) {
                      setState(() {
                        selectedPlan = value;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product != null && product!.description.isNotEmpty
                              ? product!.description
                              : plan.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (popular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSubscriptionLength(VipPlan plan) {
    switch (plan) {
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
