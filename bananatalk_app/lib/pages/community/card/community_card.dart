import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'community_card_avatar.dart';
import 'community_card_meta.dart';
import 'community_card_actions.dart';

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
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500 + widget.animationDelay),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
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
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: context.surfaceColor,
                  boxShadow: context.isDarkMode ? [] : AppShadows.md,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: widget.onTap,
                      splashColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      highlightColor:
                          AppColors.primary.withValues(alpha: 0.05),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 16),
                            CommunityCardMeta.buildLanguageExchange(
                                context, widget.community),
                            if (widget.community.bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              CommunityCardMeta.buildBio(
                                  context, widget.community.bio),
                            ],
                            const SizedBox(height: 16),
                            CommunityCardMeta.buildFooter(
                                context, widget.community),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CommunityCardAvatar(
          imageUrl: widget.community.profileImageUrl,
          name: widget.community.name,
          nativeLanguage: widget.community.native_language,
          isVip: widget.community.isVip,
          userId: PrivacyUtils.shouldShowOnlineStatus(widget.community)
              ? widget.community.id
              : null,
          size: 64,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CommunityCardMeta(
            community: widget.community,
            isFollowing: widget.isFollowing,
          ),
        ),
        CommunityCardActions(
          community: widget.community,
          onMessageTap: widget.onTap,
        ),
      ],
    );
  }

}
