import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/vip_payment_screen.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/ios_purchase_service.dart';
import 'package:bananatalk_app/services/android_purchase_service.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class VipPlansScreen extends ConsumerStatefulWidget {
  final String? userId;

  const VipPlansScreen({Key? key, this.userId}) : super(key: key);

  @override
  ConsumerState<VipPlansScreen> createState() => _VipPlansScreenState();
}

class _VipPlansScreenState extends ConsumerState<VipPlansScreen> {
  VipPlan? selectedPlan;
  bool _isIOS = Platform.isIOS;
  bool _isAndroid = Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    // Initialize store based on platform
    if (_isIOS) {
      IOSPurchaseService.initializeStore();
      IOSPurchaseService.loadProducts();
    } else if (_isAndroid) {
      AndroidPurchaseService.initializeStore();
      AndroidPurchaseService.loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while products are loading on iOS or Android
    if (_isIOS || _isAndroid) {
      final productsAsync = _isIOS
          ? ref.watch(iosProductsProvider)
          : ref.watch(androidProductsProvider);
      return productsAsync.when(
        data: (products) => _buildContent(),
        loading: () => Scaffold(
          backgroundColor: context.scaffoldBackground,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.upgradeToVIP, style: context.titleLarge),
            backgroundColor: context.surfaceColor,
            elevation: 0,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: context.scaffoldBackground,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.upgradeToVIP, style: context.titleLarge),
            backgroundColor: context.surfaceColor,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: AppSpacing.paddingLG,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    '${AppLocalizations.of(context)!.errorLoadingProducts}: $error',
                    style: context.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () {
                      if (_isIOS) {
                        ref.invalidate(iosProductsProvider);
                      } else {
                        ref.invalidate(androidProductsProvider);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text('Upgrade to VIP', style: context.titleLarge),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingXXL,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.7),
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
                    color: AppColors.white,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Unlock VIP Features',
                    style: context.displayMedium.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Get unlimited access to all premium features',
                    style: context.bodyLarge.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: AppSpacing.paddingXXL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIP Features',
                    style: context.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
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
              padding: AppSpacing.paddingXXL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Plan',
                    style: context.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildPlanCard(VipPlan.monthly),
                  SizedBox(height: AppSpacing.md),
                  _buildPlanCard(VipPlan.quarterly, popular: true),
                  SizedBox(height: AppSpacing.md),
                  _buildPlanCard(VipPlan.yearly),
                ],
              ),
            ),

            // Subscription Information (required for App Store)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Container(
                padding: AppSpacing.paddingLG,
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
                    SizedBox(height: AppSpacing.md),
                    if (selectedPlan != null) ...[
                      _buildSubscriptionInfoRow('Title', selectedPlan!.displayName),
                      _buildSubscriptionInfoRow('Length', _getSubscriptionLength(selectedPlan!)),
                      _buildSubscriptionInfoRow('Price', '\$${selectedPlan!.price}'),
                      SizedBox(height: AppSpacing.md),
                    ] else
                      Text(
                        'Please select a plan to see subscription details',
                        style: context.bodySmall,
                      ),
                    SizedBox(height: AppSpacing.md),
                    Divider(color: context.dividerColor),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/terms-of-use'),
                            icon: Icon(Icons.description_outlined, size: 18, color: context.primaryColor),
                            label: Text(
                              'Terms of Use',
                              style: context.labelMedium.copyWith(color: context.primaryColor),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/privacy-policy'),
                            icon: Icon(Icons.privacy_tip_outlined, size: 18, color: context.primaryColor),
                            label: Text(
                              'Privacy Policy',
                              style: context.labelMedium.copyWith(color: context.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Payment is charged to your iTunes Account or Google Play account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.',
                      style: context.captionSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: AppSpacing.paddingXXL,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedPlan != null
                      ? () {
                          // Get userId from widget or provider
                          final userId = widget.userId ?? ref.read(userProvider).valueOrNull?.id ?? '';
                          if (userId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please log in to continue')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VipPaymentScreen(
                                userId: userId,
                                plan: selectedPlan!,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                  child: Text(
                    'Continue to Payment',
                    style: context.titleMedium.copyWith(color: AppColors.white),
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
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderMD,
            ),
            child: Icon(
              icon,
              color: context.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.titleMedium,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: context.bodySmall,
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

    // Get product ID based on platform
    String productId;
    if (_isIOS) {
      // iOS product IDs
      switch (plan) {
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
    } else {
      // Android product IDs
      switch (plan) {
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
    }

    // Try to get product from store
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
    } else if (_isAndroid) {
      final productsAsync = ref.watch(androidProductsProvider);
      productsAsync.whenData((products) {
        try {
          product = products.firstWhere((p) => p.id == productId);
        } catch (e) {
          // Product not found, use default price
        }
      });
    }

    // Use store price if available, otherwise use default
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
                ? context.primaryColor
                : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.borderLG,
          color: isSelected
              ? context.primaryColor.withValues(alpha: 0.05)
              : context.surfaceColor,
        ),
        child: Stack(
          children: [
            Padding(
              padding: AppSpacing.paddingXL,
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
                    activeColor: context.primaryColor,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.displayName,
                          style: context.titleMedium,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          product != null && product!.description.isNotEmpty
                              ? product!.description
                              : plan.description,
                          style: context.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    priceText,
                    style: context.titleLarge,
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
                      EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    'POPULAR',
                    style: context.labelSmall.copyWith(
                      color: AppColors.white,
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
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
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
