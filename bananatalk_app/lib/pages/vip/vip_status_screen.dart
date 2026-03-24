import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class VipStatusScreen extends ConsumerStatefulWidget {
  final String userId;

  const VipStatusScreen({super.key, required this.userId});

  @override
  ConsumerState<VipStatusScreen> createState() => _VipStatusScreenState();
}

class _VipStatusScreenState extends ConsumerState<VipStatusScreen> {
  // VIP gradient colors (kept for branding)
  static const _vipGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _expiredGradient = LinearGradient(
    colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final vipStatusAsync = ref.watch(vipStatusProvider(widget.userId));

    return vipStatusAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.scaffoldBackground,
        appBar: AppBar(
          title: Text(localizations.vipStatus, style: context.titleLarge),
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
          title: Text(localizations.vipStatus, style: context.titleLarge),
          backgroundColor: context.surfaceColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: context.bodyMedium,
                ),
                SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(vipStatusProvider(widget.userId));
                  },
                  child: Text(localizations.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (vipStatus) {
        final isVip = vipStatus['isVIP'] == true;
        final userMode = vipStatus['userMode']?.toString() ?? 'regular';
        final subscription = vipStatus['vipSubscription'] as VipSubscription?;
        final rawData = vipStatus['data'] as Map<String, dynamic>?;


        // Check if user has VIP mode but subscription is not active
        // This could be an expired subscription or a sync issue
        if (!isVip && userMode == 'vip') {
          return _buildExpiredVipContent(localizations, subscription);
        }

        if (!isVip) {
          return Scaffold(
            backgroundColor: context.scaffoldBackground,
            appBar: AppBar(
              title: Text(localizations.vipStatus, style: context.titleLarge),
              backgroundColor: context.surfaceColor,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 64,
                    color: context.textSecondary,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    localizations.noActiveVIPSubscription,
                    style: context.bodyLarge.copyWith(color: context.textSecondary),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.gray900,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderXXL,
                      ),
                    ),
                    child: Text(localizations.becomeVIP),
                  ),
                ],
              ),
            ),
          );
        }

        // If we have subscription details, show full content
        if (subscription != null && subscription.isActive) {
          return _buildVipStatusContent(subscription, localizations);
        }

        // If isVIP=true but no subscription details, show basic VIP status
        return _buildBasicVipContent(localizations, rawData);
      },
    );
  }

  /// Build content for expired VIP subscription
  Widget _buildExpiredVipContent(AppLocalizations localizations, VipSubscription? subscription) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(localizations.vipStatus, style: context.titleLarge),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Expired VIP Header
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingXXL,
              decoration: BoxDecoration(
                gradient: _expiredGradient,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 80,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'VIP Expired',
                    style: context.displayMedium.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.borderXL,
                    ),
                    child: Text(
                      localizations.subscriptionExpired,
                      style: context.labelMedium.copyWith(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Renew Info
            Padding(
              padding: AppSpacing.paddingXXL,
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: AppColors.warning,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    localizations.vipExpiredMessage,
                    textAlign: TextAlign.center,
                    style: context.bodyLarge.copyWith(color: context.textSecondary),
                  ),
                  SizedBox(height: AppSpacing.xxl),

                  // Show previous end date if available
                  if (subscription?.endDate != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: Text(
                        '${localizations.expiredOn}: ${DateFormat('MMM dd, yyyy').format(subscription!.endDate)}',
                        style: context.bodySmall,
                      ),
                    ),

                  // Renew Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to VIP plans screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.gray900,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMD,
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            localizations.renewVIP,
                            style: context.titleMedium.copyWith(color: AppColors.gray900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // What you're missing section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.whatYoureMissing,
                    style: context.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildMissingFeatureItem(
                    icon: Icons.message,
                    title: localizations.unlimitedMessages,
                  ),
                  _buildMissingFeatureItem(
                    icon: Icons.visibility,
                    title: localizations.unlimitedProfileViews,
                  ),
                  _buildMissingFeatureItem(
                    icon: Icons.support_agent,
                    title: localizations.prioritySupport,
                  ),
                  _buildMissingFeatureItem(
                    icon: Icons.block,
                    title: localizations.adFreeExperience,
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xxxl),

            // Manage Subscription Button (iOS)
            if (Platform.isIOS)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: TextButton.icon(
                  onPressed: _openSubscriptionSettings,
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(localizations.manageInAppStore),
                ),
              ),

            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingFeatureItem({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.close,
            color: AppColors.error.withValues(alpha: 0.7),
            size: 20,
          ),
          SizedBox(width: AppSpacing.md),
          Icon(
            icon,
            color: context.textSecondary,
            size: 22,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Build basic VIP content when we have VIP status but no detailed subscription
  Widget _buildBasicVipContent(AppLocalizations localizations, Map<String, dynamic>? rawData) {
    final plan = rawData?['plan'] ?? 'VIP';
    final endDateStr = rawData?['vipEndDate'] ?? rawData?['endDate'];
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(localizations.vipStatus, style: context.titleLarge),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // VIP Badge Header
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingXXL,
              decoration: BoxDecoration(
                gradient: _vipGradient,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: AppColors.white,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'VIP Member',
                    style: context.displayLarge.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.borderXL,
                    ),
                    child: Text(
                      plan.toString().toUpperCase(),
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status Info
            Padding(
              padding: AppSpacing.paddingXXL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.subscriptionDetails,
                    style: context.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildDetailRow(
                    localizations.status,
                    localizations.active.toUpperCase(),
                    statusColor: AppColors.success,
                  ),
                  _buildDetailRow(
                    localizations.plan,
                    plan.toString(),
                  ),
                  if (endDate != null)
                    _buildDetailRow(
                      localizations.endDate,
                      DateFormat('MMM dd, yyyy').format(endDate),
                    ),
                ],
              ),
            ),

            // Active Features
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.activeFeatures,
                    style: context.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildFeatureItem(
                    icon: Icons.message,
                    title: localizations.unlimitedMessages,
                  ),
                  _buildFeatureItem(
                    icon: Icons.visibility,
                    title: localizations.unlimitedProfileViews,
                  ),
                  _buildFeatureItem(
                    icon: Icons.support_agent,
                    title: localizations.prioritySupport,
                  ),
                  _buildFeatureItem(
                    icon: Icons.search,
                    title: localizations.advancedSearch,
                  ),
                  _buildFeatureItem(
                    icon: Icons.trending_up,
                    title: localizations.profileBoost,
                  ),
                  _buildFeatureItem(
                    icon: Icons.block,
                    title: localizations.adFreeExperience,
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xxl),

            // Manage Subscription Button (iOS - redirects to App Store settings)
            if (Platform.isIOS)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _openSubscriptionSettings,
                    icon: const Icon(Icons.settings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      side: BorderSide(color: context.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
                    ),
                    label: Text(
                      localizations.manageSubscription,
                      style: context.titleMedium.copyWith(color: context.primaryColor),
                    ),
                  ),
                ),
              ),

            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildVipStatusContent(VipSubscription subscription, AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(localizations.vipStatus, style: context.titleLarge),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // VIP Badge Header
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingXXL,
              decoration: BoxDecoration(
                gradient: _vipGradient,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: AppColors.white,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'VIP Member',
                    style: context.displayLarge.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.borderXL,
                    ),
                    child: Text(
                      subscription.plan.toUpperCase(),
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subscription Details
            Padding(
              padding: AppSpacing.paddingXXL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.subscriptionDetails,
                    style: context.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildDetailRow(
                    localizations.status,
                    localizations.active.toUpperCase(),
                    statusColor: AppColors.success,
                  ),
                  _buildDetailRow(
                    localizations.plan,
                    subscription.plan,
                  ),
                  _buildDetailRow(
                    localizations.startDate,
                    DateFormat('MMM dd, yyyy').format(subscription.startDate),
                  ),
                  _buildDetailRow(
                    localizations.endDate,
                    DateFormat('MMM dd, yyyy').format(subscription.endDate),
                  ),
                  if (subscription.nextBillingDate != null)
                    _buildDetailRow(
                      localizations.nextBillingDate,
                      DateFormat('MMM dd, yyyy').format(subscription.nextBillingDate!),
                    ),
                  _buildDetailRow(
                    localizations.autoRenew,
                    subscription.autoRenew ? localizations.yes : localizations.no,
                    statusColor: subscription.autoRenew ? AppColors.success : AppColors.warning,
                  ),
                ],
              ),
            ),

            // Active Features
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.activeFeatures,
                    style: context.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildFeatureItem(
                    icon: Icons.message,
                    title: localizations.unlimitedMessages,
                  ),
                  _buildFeatureItem(
                    icon: Icons.visibility,
                    title: localizations.unlimitedProfileViews,
                  ),
                  _buildFeatureItem(
                    icon: Icons.support_agent,
                    title: localizations.prioritySupport,
                  ),
                  _buildFeatureItem(
                    icon: Icons.search,
                    title: localizations.advancedSearch,
                  ),
                  _buildFeatureItem(
                    icon: Icons.trending_up,
                    title: localizations.profileBoost,
                  ),
                  _buildFeatureItem(
                    icon: Icons.block,
                    title: localizations.adFreeExperience,
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xxl),

            // Legal Links
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
                      localizations.legalInformation,
                      style: context.titleMedium,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/terms-of-use'),
                            icon: Icon(Icons.description_outlined, size: 18, color: context.primaryColor),
                            label: Text(
                              localizations.termsOfUse,
                              style: context.labelMedium.copyWith(color: context.primaryColor),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/privacy-policy'),
                            icon: Icon(Icons.privacy_tip_outlined, size: 18, color: context.primaryColor),
                            label: Text(
                              localizations.privacyPolicy,
                              style: context.labelMedium.copyWith(color: context.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Manage Subscription Button (iOS - redirects to App Store settings)
            if (Platform.isIOS)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _openSubscriptionSettings,
                    icon: const Icon(Icons.settings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      side: BorderSide(color: context.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD,
                      ),
                    ),
                    label: Text(
                      localizations.manageSubscription,
                      style: context.titleMedium.copyWith(color: context.primaryColor),
                    ),
                  ),
                ),
              ),

            SizedBox(height: AppSpacing.md),

            // Cancel Info Text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                Platform.isIOS
                    ? localizations.manageSubscriptionInSettings
                    : localizations.contactSupportToCancel,
                style: context.caption,
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.bodyLarge.copyWith(color: context.textSecondary),
          ),
          Text(
            value,
            style: context.titleMedium.copyWith(
              color: statusColor ?? context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
          SizedBox(width: AppSpacing.md),
          Icon(
            icon,
            color: context.primaryColor,
            size: 24,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: context.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSubscriptionSettings() async {
    // Open iOS subscription settings
    final Uri url = Uri.parse('https://apps.apple.com/account/subscriptions');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
