import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/widgets/vip_upsell_banner.dart';
import 'package:bananatalk_app/widgets/community/language_match_card.dart';
import 'package:bananatalk_app/widgets/community/engagement_stats_bar.dart';
import 'package:bananatalk_app/widgets/community/conversation_starters_card.dart';

/// Overview tab body: VIP banner, language match, engagement stats, follower
/// counts, conversation starters, and a quick-chat CTA.
class SingleCommunityOverview extends ConsumerWidget {
  final Community community;
  final VoidCallback onMessage;

  const SingleCommunityOverview({
    super.key,
    required this.community,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      key: const PageStorageKey<String>('overview'),
      padding: const EdgeInsets.all(16),
      children: [
        // VIP Upsell Banner
        if (community.isVip) ...[
          Builder(
            builder: (context) {
              final userAsync = ref.watch(userProvider);
              final isCurrentUserVip = userAsync.valueOrNull?.isVip ?? false;
              return VipUpsellBanner(
                userName: community.name,
                isCurrentUserVip: isCurrentUserVip,
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Language Match Card
        LanguageMatchCard(profile: community),

        const SizedBox(height: 12),
        const SmallBannerAdWidget(),

        // Engagement Stats Bar
        EngagementStatsBar(profile: community),

        const SizedBox(height: 16),

        // Follower / following stat counters
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                context,
                '${community.followers.length}',
                l10n.followers,
                Icons.people_rounded,
                AppColors.accent,
              ),
              Container(height: 50, width: 1, color: context.dividerColor),
              _buildStatItem(
                context,
                '${community.followings.length}',
                l10n.following,
                Icons.person_add_rounded,
                Colors.blue[600]!,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Conversation Starters
        ConversationStartersCard(profile: community),

        const SizedBox(height: 16),

        // Quick chat button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(l10n.messageUser(community.name)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        Spacing.gapSM,
        Text(value, style: context.displaySmall),
        Spacing.gapXXS,
        Text(label, style: context.labelSmall),
      ],
    );
  }
}
