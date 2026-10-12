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
              decoration: const BoxDecoration(
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
                    AppLocalizations.of(context)!.vipVisitorModeLimitReached,
                    style: context.displayMedium.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Spacing.gapSM,
                  Text(
                    limitMessage ??
                        AppLocalizations.of(context)!.vipUpgradeUnlockMore,
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
                    AppLocalizations.of(context)!.vipWhatGetFreeAccount,
                    style: context.titleLarge,
                  ),
                  Spacing.gapLG,
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.message,
                    title: AppLocalizations.of(context)!.moreMessages,
                    description: AppLocalizations.of(context)!.vipVisitorMessagesBenefit,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.visibility,
                    title: AppLocalizations.of(context)!.moreProfileViews,
                    description: AppLocalizations.of(context)!.vipVisitorProfilesBenefit,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.person_add,
                    title: AppLocalizations.of(context)!.connectWithFriends,
                    description: AppLocalizations.of(context)!.vipVisitorFriendsBenefit,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.group,
                    title: AppLocalizations.of(context)!.vipVisitorCommunitiesTitle,
                    description: AppLocalizations.of(context)!.vipVisitorCommunitiesBenefit,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.photo_library,
                    title: AppLocalizations.of(context)!.vipVisitorMomentsTitle,
                    description: AppLocalizations.of(context)!.vipVisitorMomentsBenefit,
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
                    AppLocalizations.of(context)!.vipCreateFreeAccount,
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
                      AppLocalizations.of(context)!.or,
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
                    AppLocalizations.of(context)!.vipGoUnlimitedAccess,
                    style: context.titleLarge,
                  ),
                  Spacing.gapLG,
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.all_inclusive,
                    title: AppLocalizations.of(context)!.vipUnlimitedEverythingTitle,
                    description: AppLocalizations.of(context)!.vipUnlimitedEverythingBenefit,
                    vip: true,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.trending_up,
                    title: AppLocalizations.of(context)!.profileBoost,
                    description: AppLocalizations.of(context)!.vipProfileBoostBenefit,
                    vip: true,
                  ),
                  _buildBenefitItem(
                    context: context,
                    icon: Icons.block,
                    title: AppLocalizations.of(context)!.adFreeExperience,
                    description: AppLocalizations.of(context)!.vipAdFreeExperienceBenefit,
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
                        AppLocalizations.of(context)!.vipContinueAsVisitor,
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
