import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'dart:ui';
import 'package:flutter/services.dart' show HapticFeedback;

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
                      splashColor: AppColors.primary.withOpacity(0.1),
                      highlightColor: AppColors.primary.withOpacity(0.05),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 16),
                            _buildLanguageExchange(context),
                            if (widget.community.bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildBio(context),
                            ],
                            const SizedBox(height: 16),
                            _buildFooter(context),
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
        _buildModernAvatar(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.community.name,
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
                  if (widget.isFollowing) _buildFollowingBadge(context),
                ],
              ),
              const SizedBox(height: 6),
              _buildMetaInfo(context),
            ],
          ),
        ),
        _buildQuickAction(context),
      ],
    );
  }

  Widget _buildModernAvatar(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            Builder(
              builder: (context) {
                final profileImage = widget.community.profileImageUrl;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: profileImage == null
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF00ACC1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: context.isDarkMode ? [] : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profileImage != null
                        ? CachedImageWidget(
                            imageUrl: profileImage,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: _buildFallbackAvatar(),
                            placeholder: Container(
                              color: context.containerColor,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : _buildFallbackAvatar(),
                  ),
                );
              },
            ),
            // Flag badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.surfaceColor,
                  boxShadow: context.isDarkMode ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: context.surfaceColor.withOpacity(0.9),
                      child: Center(
                        child: Text(
                          _getLanguageFlag(widget.community.native_language),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Online status indicator
            if (PrivacyUtils.shouldShowOnlineStatus(widget.community))
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.online,
                    border: Border.all(color: context.surfaceColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.online.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.community.name.isNotEmpty
              ? widget.community.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(context.isDarkMode ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
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
              color: context.isDarkMode ? AppColors.success : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    final locationText = PrivacyUtils.getLocationText(widget.community);

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

  Widget _buildQuickAction(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.isDarkMode ? [] : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.waving_hand,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('Waved to ${widget.community.name}! 👋'),
                  ],
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: const Icon(
            Icons.waving_hand_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageExchange(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(context.isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageChip(
              context,
              widget.community.native_language,
              true,
              _getLanguageFlag(widget.community.native_language),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: context.isDarkMode ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
              widget.community.language_to_learn,
              false,
              _getLanguageFlag(widget.community.language_to_learn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(BuildContext context, String language, bool isNative, String flag) {
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

  Widget _buildBio(BuildContext context) {
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
              widget.community.bio,
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

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        _buildStatChip(
          context,
          Icons.groups_rounded,
          '${widget.community.followers.length}',
          'followers',
        ),
        const SizedBox(width: 12),
        _buildStatChip(context, Icons.chat_bubble_rounded, 'Active', 'status'),
        const Spacer(),
        _buildViewProfileButton(context),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String value, String label) {
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

  Widget _buildViewProfileButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
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
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getLanguageFlag(String language) {
    if (language.isEmpty) return LanguageFlags.getFlag('');

    final langLower = language.toLowerCase().trim();

    final nameToCodeMap = {
      'english': 'en',
      'korean': 'ko',
      'japanese': 'ja',
      'japan': 'ja',
      'chinese': 'zh',
      'spanish': 'es',
      'french': 'fr',
      'german': 'de',
      'italian': 'it',
      'portuguese': 'pt',
      'russian': 'ru',
      'arabic': 'ar',
      'hindi': 'hi',
      'thai': 'th',
      'vietnamese': 'vi',
      'dutch': 'nl',
      'danish': 'da',
      'swedish': 'sv',
      'norwegian': 'no',
      'finnish': 'fi',
      'polish': 'pl',
      'turkish': 'tr',
      'greek': 'el',
      'hebrew': 'he',
      'indonesian': 'id',
      'malay': 'ms',
      'ukrainian': 'uk',
      'romanian': 'ro',
      'hungarian': 'hu',
      'czech': 'cs',
      'bulgarian': 'bg',
      'croatian': 'hr',
      'serbian': 'sr',
      'uzbek': 'uz',
    };

    if (nameToCodeMap.containsKey(langLower)) {
      return LanguageFlags.getFlag(nameToCodeMap[langLower]!);
    }

    for (var entry in nameToCodeMap.entries) {
      if (langLower.contains(entry.key) || entry.key.contains(langLower)) {
        return LanguageFlags.getFlag(entry.value);
      }
    }

    if (langLower.length == 2) {
      return LanguageFlags.getFlag(langLower);
    }

    if (langLower.length >= 2) {
      return LanguageFlags.getFlag(langLower.substring(0, 2));
    }

    return LanguageFlags.getFlag('');
  }
}
