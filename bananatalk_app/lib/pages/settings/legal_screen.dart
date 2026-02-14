import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalScreen extends StatelessWidget {
  // Your actual URLs
  static const String termsUrl = 'https://banatalk.com/terms-of-use';
  static const String privacyUrl = 'https://banatalk.com/privacy-policy';

  const LegalScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.legalPrivacy2,
          style: context.titleLarge.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              context.scaffoldBackground,
            ],
          ),
        ),
        child: ListView(
          padding: Spacing.screenPadding,
          children: [
            // Terms of Use Card
            _buildLegalCard(
              context: context,
              icon: Icons.description_outlined,
              title: AppLocalizations.of(context)!.termsOfUseEULA,
              subtitle: AppLocalizations.of(context)!.viewOurTermsAndConditions,
              onTap: () => _launchURL(context, termsUrl),
            ),

            Spacing.gapMD,

            // Privacy Policy Card
            _buildLegalCard(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: AppLocalizations.of(context)!.privacyPolicy,
              subtitle: AppLocalizations.of(context)!.howWeHandleYourData,
              onTap: () => _launchURL(context, privacyUrl),
            ),

            Spacing.gapXXL,
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLG,
          child: Padding(
            padding: Spacing.paddingLG,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                Spacing.hGapLG,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.titleSmall,
                      ),
                      Spacing.gapXXS,
                      Text(
                        subtitle,
                        style: context.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  color: context.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionTier(BuildContext context, String period, String price, [String? badge]) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        Spacing.hGapSM,
        Text(
          '$period: ',
          style: context.labelLarge,
        ),
        Text(
          price,
          style: context.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        if (badge != null) ...[
          Spacing.hGapSM,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              badge,
              style: context.captionSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
