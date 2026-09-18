import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/card/community_card_avatar.dart';
import 'package:bananatalk_app/pages/community/card/community_card_meta.dart';
import 'package:bananatalk_app/pages/community/card/community_card_actions.dart';
import 'package:bananatalk_app/pages/community/card/community_match_tags.dart';
import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';

export 'community_card_avatar.dart';
export 'community_card_meta.dart';
export 'community_card_actions.dart';

/// A card representing a single community/partner user.
///
/// Composes [CommunityCardAvatar], [CommunityCardMeta], and
/// [CommunityCardActions] into the full card layout with entrance animations
/// and press-scale feedback.
class CommunityCard extends StatefulWidget {
  final Community community;
  final VoidCallback onTap;
  final int animationDelay;
  final bool isFollowing;

  const CommunityCard({
    Key? key,
    required this.community,
    required this.onTap,
    this.animationDelay = 0,
    this.isFollowing = false,
  }) : super(key: key);

  @override
  _CommunityCardState createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // A 500ms staggered slide+scale was tuned for two large cards per screen.
    // At four rows it reads as the list lagging behind the scroll.
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              color: context.surfaceColor,
              boxShadow: context.isDarkMode ? [] : AppShadows.sm,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  onTap: widget.onTap,
                  splashColor: AppColors.primary.withValues(alpha: 0.1),
                  highlightColor: AppColors.primary.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildRow(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityCardAvatar(
          imageUrl: widget.community.profileImageUrl,
          name: widget.community.name,
          nativeLanguage: widget.community.native_language,
          // Country flag for identity; suppressed when the user hides their
          // country/region.
          country: (widget.community.privacySettings?.showCountryRegion ?? true)
              ? widget.community.location.country
              : null,
          isVip: widget.community.isVip,
          userId: PrivacyUtils.shouldShowOnlineStatus(widget.community)
              ? widget.community.id
              : null,
          size: 54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CommunityCardMeta(
                community: widget.community,
                isFollowing: widget.isFollowing,
              ),
              const SizedBox(height: 4),
              LanguageExchangePill(
                nativeLanguage: widget.community.native_language,
                learningLanguage: widget.community.language_to_learn,
                languageLevel: widget.community.languageLevel,
              ),
              if (widget.community.bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    widget.community.bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodySmall.copyWith(color: context.textSecondary),
                  ),
                ),
              CommunityMatchTags(community: widget.community),
            ],
          ),
        ),
        const SizedBox(width: 10),
        CommunityCardActions(
          community: widget.community,
          onMessageTap: widget.onTap,
        ),
      ],
    );
  }
}
