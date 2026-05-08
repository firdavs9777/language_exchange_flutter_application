import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Meta block for [CommunityCard].
///
/// Displays:
/// - Name row (with optional "Following" badge)
/// - Location / meta sub-row
/// - Language-exchange section (native ↔ learning with flags)
/// - Optional bio snippet
/// - Footer stat chips + "View Profile" button
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
        const SizedBox(height: 6),
        _buildLocationRow(context),
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

  // ── Location sub-row ────────────────────────────────────────────────────────

  Widget _buildLocationRow(BuildContext context) {
    final locationText = PrivacyUtils.getLocationText(community);

    return Row(
      children: [
        if (locationText.isNotEmpty) ...[
          Icon(Icons.location_on_rounded, size: 14, color: context.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              locationText,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  // ── Language exchange block ─────────────────────────────────────────────────

  /// Standalone language-exchange widget, usable from the parent card's build.
  static Widget buildLanguageExchange(
    BuildContext context,
    Community community,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: context.isDarkMode ? 0.15 : 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageChip(
              context,
              community.native_language,
              isNative: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: context.isDarkMode
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: _buildLanguageChip(
              context,
              community.language_to_learn,
              isNative: false,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLanguageChip(
    BuildContext context,
    String language, {
    required bool isNative,
  }) {
    final flag = LanguageFlags.getFlagByName(language);
    return Column(
      children: [
        Text(flag, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          isNative ? 'Native' : 'Learning',
          style: TextStyle(
            fontSize: 10,
            color: context.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          language.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isNative ? AppColors.primary : context.textSecondary,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Bio snippet ─────────────────────────────────────────────────────────────

  static Widget buildBio(BuildContext context, String bio) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, size: 18, color: context.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer stat chips ───────────────────────────────────────────────────────

  static Widget buildFooter(BuildContext context, Community community) {
    return Row(
      children: [
        _buildStatChip(
          context,
          Icons.groups_rounded,
          '${community.followers.length}',
          'followers',
        ),
        const SizedBox(width: 12),
        _buildStatChip(context, Icons.chat_bubble_rounded, 'Active', 'status'),
        const Spacer(),
        _buildViewProfileButton(context),
      ],
    );
  }

  static Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.dividerColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildViewProfileButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View Profile',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
        ],
      ),
    );
  }
}
