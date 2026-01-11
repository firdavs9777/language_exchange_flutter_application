import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey[50]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFA5).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: widget.onTap,
                      splashColor: const Color(0xFF00BFA5).withOpacity(0.1),
                      highlightColor: const Color(0xFF00BFA5).withOpacity(0.05),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildLanguageExchange(),
                            if (widget.community.bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildBio(),
                            ],
                            const SizedBox(height: 16),
                            _buildFooter(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        _buildModernAvatar(),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isFollowing) _buildFollowingBadge(),
                ],
              ),
              const SizedBox(height: 6),
              _buildMetaInfo(),
            ],
          ),
        ),
        _buildQuickAction(),
      ],
    );
  }

  Widget _buildModernAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.2),
            const Color(0xFF00ACC1).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.community.imageUrls.isEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.community.imageUrls.isNotEmpty
                    ? CachedImageWidget(
                        imageUrl: widget.community.imageUrls[0],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: _buildFallbackAvatar(),
                        placeholder: Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF00BFA5).withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : _buildFallbackAvatar(),
              ),
            ),
            // Flag badge with glassmorphism
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
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
                      color: Colors.white.withOpacity(0.9),
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
                    color: const Color(0xFF4CAF50),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.5),
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
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
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

  Widget _buildFollowingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.15),
            const Color(0xFF66BB6A).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
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
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Following',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo() {
    final locationText = PrivacyUtils.getLocationText(widget.community);

    return Row(
      children: [
        if (locationText.isNotEmpty) ...[
          Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              locationText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
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

  Widget _buildQuickAction() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withOpacity(0.4),
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
                backgroundColor: const Color(0xFF00BFA5),
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

  Widget _buildLanguageExchange() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.08),
            const Color(0xFF00ACC1).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageChip(
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                color: const Color(0xFF00BFA5),
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: _buildLanguageChip(
              widget.community.language_to_learn,
              false,
              _getLanguageFlag(widget.community.language_to_learn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String language, bool isNative, String flag) {
    return Column(
      children: [
        Text(flag, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          isNative ? 'Native' : 'Learning',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
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
            color: isNative ? const Color(0xFF00BFA5) : Colors.grey[700],
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBio() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.community.bio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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

  Widget _buildFooter() {
    return Row(
      children: [
        _buildStatChip(
          Icons.groups_rounded,
          '${_randomFollowers()}',
          'followers',
        ),
        const SizedBox(width: 12),
        _buildStatChip(Icons.chat_bubble_rounded, 'Active', 'status'),
        const Spacer(),
        _buildViewProfileButton(),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00BFA5)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewProfileButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'View Profile',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00BFA5),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: Color(0xFF00BFA5),
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

  int _randomFollowers() {
    // TODO: Replace with real follower count from backend
    return (widget.community.name.length * 17) % 999 + 50;
  }
}
