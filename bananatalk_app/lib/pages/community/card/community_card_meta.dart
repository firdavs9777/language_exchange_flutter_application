import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Meta block for [CommunityCard].
///
/// Name row for [CommunityCard], with an optional "Following" badge.
///
/// This used to also own the location sub-row, the two grey language chips,
/// the bio, the follower/moment stat chips and a "View Profile" button. The
/// language pair moved to the shared [LanguageExchangePill], the reasons to
/// tap moved to [CommunityMatchTags], and the rest was removed: the stats are
/// not how anyone picks a language partner, and tapping the row already opens
/// the profile that the button opened.
class CommunityCardMeta extends StatelessWidget {
  const CommunityCardMeta({
    super.key,
    required this.community,
    this.isFollowing = false,
  });

  final Community community;
  final bool isFollowing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameRow(context),
      ],
    );
  }

  // ── Name + Following badge ──────────────────────────────────────────────────

  Widget _buildNameRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            community.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isFollowing) _buildFollowingBadge(context),
      ],
    );
  }

  Widget _buildFollowingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(
          alpha: context.isDarkMode ? 0.2 : 0.15,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Following',
            style: TextStyle(
              fontSize: 11,
              color: context.isDarkMode
                  ? AppColors.success
                  : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
