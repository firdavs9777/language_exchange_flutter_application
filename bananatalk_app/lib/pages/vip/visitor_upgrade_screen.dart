import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/authentication/register/register_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class VisitorUpgradeScreen extends StatelessWidget {
  final String userId;
  final String? limitMessage;

  const VisitorUpgradeScreen({
    Key? key,
    required this.userId,
    this.limitMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.upgradeYourAccount,
          style: context.titleLarge,
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: Spacing.paddingXXL,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.upgrade,
                    size: 80,
                    color: AppColors.white,
                  ),
                  Spacing.gapLG,
                  Text(
                    'Visitor Mode Limit Reached',
                    style: context.displayMedium.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Spacing.gapSM,
                  Text(
                    limitMessage ??
                        'Upgrade to unlock more features and unlimited access',
                    style: context.bodyLarge.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Benefits
            Padding(
              padding: Spacing.paddingXXL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What You Get with a Free Account',
                    style: context.titleLarge,
                  ),
                  Spacing.gapLG,
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.message,
                    title: AppLocalizations.of(context)!.moreMessages,
                    description: 'Send up to 50 messages per day',
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.visibility,
                    title: AppLocalizations.of(context)!.moreProfileViews,
                    description: 'View up to 100 profiles per day',
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.person_add,
                    title: AppLocalizations.of(context)!.connectWithFriends,
                    description: 'Add friends and build your network',
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.group,
                    title: 'Join Communities',
                    description: 'Participate in community discussions',
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.photo_library,
                    title: 'Share Moments',
                    description: 'Post and share your moments',
                  ),
                ],
              ),
            ),

            // Upgrade Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Register(
                          userEmail: '',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                  child: Text(
                    'Create Free Account',
                    style: context.titleMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),

            Spacing.gapLG,

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: Divider(color: context.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: context.labelMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: context.dividerColor)),
                ],
              ),
            ),

            Spacing.gapLG,

            // VIP Benefits
            Padding(
              padding: Spacing.paddingXXL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Go VIP for Unlimited Access',
                    style: context.titleLarge,
                  ),
                  Spacing.gapLG,
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.all_inclusive,
                    title: 'Unlimited Everything',
                    description: 'No daily limits on messages or profile views',
                    vip: true,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.trending_up,
                    title: 'Profile Boost',
                    description: 'Get more visibility in search results',
                    vip: true,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.block,
                    title: 'Ad-Free Experience',
                    description: 'Enjoy the app without advertisements',
                    vip: true,
                  ),
                ],
              ),
            ),

            // VIP Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to VIP plans
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium),
                      Spacing.hGapSM,
                      Text(
                        'Continue as Visitor',
                        style: context.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Spacing.gapXXL,
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    bool vip = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: Spacing.paddingMD,
            decoration: BoxDecoration(
              color: vip
                  ? AppColors.secondary.withOpacity(0.2)
                  : AppColors.info.withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
            ),
            child: Icon(
              icon,
              color: vip ? AppColors.secondaryDark : AppColors.info,
              size: 24,
            ),
          ),
          Spacing.hGapLG,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: context.titleMedium,
                    ),
                    if (vip) ...[
                      Spacing.hGapSM,
                      const Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                    ],
                  ],
                ),
                Spacing.gapXS,
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
}
