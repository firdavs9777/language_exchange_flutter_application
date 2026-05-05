import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/language_level_badge.dart';
import 'package:bananatalk_app/widgets/community/topic_chip.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';

/// Swipeable partner card for discovery
class PartnerCard extends StatelessWidget {
  final Community user;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final VoidCallback? onWave;
  final VoidCallback? onMessage;

  const PartnerCard({
    super.key,
    required this.user,
    this.onTap,
    this.onSkip,
    this.onWave,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              _buildBackgroundImage(),
              // Gradient overlay
              _buildGradientOverlay(),
              // Content
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    // Use the model's profileImageUrl getter which handles fallback to images array
    final imageUrl = user.profileImageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return CachedImageWidget(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            quality: ImageQuality.high, // Use high quality for full-screen cards
            highQuality: true,
            errorWidget: _buildFallbackContent(),
          );
        },
      );
    }
    return _buildFallbackContent();
  }

  Widget _buildFallbackContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // Top section - Online status & VIP badge
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
              children: [
                if (PrivacyUtils.shouldShowOnlineStatus(user) && user.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF43A047).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (user.isVip) ...[
                  if (PrivacyUtils.shouldShowOnlineStatus(user) && user.isOnline) const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // More options button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom section - User info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name and age
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (PrivacyUtils.shouldShowAge(user) && user.age != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              '${user.age}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Location
                Builder(
                  builder: (context) {
                    final locationText = PrivacyUtils.getLocationText(user);
                    if (locationText.isEmpty) return const SizedBox.shrink();
                    return Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: Colors.white.withOpacity(0.75),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationText,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Language exchange
                _buildLanguageExchange(),
                const SizedBox(height: 12),
                // Topics
                if (user.topics.isNotEmpty) _buildTopics(),
                const SizedBox(height: 16),
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildLanguageExchange() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Native language
          Expanded(
            child: Column(
              children: [
                Text(
                  _getLanguageFlag(user.native_language),
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(height: 5),
                Text(
                  'Native',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatLanguageName(user.native_language),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Arrow
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          // Learning language
          Expanded(
            child: Column(
              children: [
                Text(
                  _getLanguageFlag(user.language_to_learn),
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Learning',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (user.languageLevel != null) ...[
                      const SizedBox(width: 4),
                      LanguageLevelBadge(
                        level: user.languageLevel,
                        compact: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _formatLanguageName(user.language_to_learn),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format language name with proper capitalization
  String _formatLanguageName(String language) {
    if (language.isEmpty) return '';
    // Capitalize first letter of each word
    return language
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  Widget _buildTopics() {
    final displayTopics = user.topics.take(3).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: displayTopics.map((topicId) {
        return SimpleTopicChip(topicId: topicId);
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip button
        _ActionButton(
          icon: Icons.close_rounded,
          color: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          onTap: onSkip,
          size: 56,
        ),
        const SizedBox(width: 16),
        // Wave button
        _ActionButton(
          icon: Icons.waving_hand_rounded,
          color: Colors.white,
          backgroundColor: const Color(0xFFFFB74D),
          onTap: onWave,
          size: 64,
        ),
        const SizedBox(width: 16),
        // Message button
        _ActionButton(
          icon: Icons.chat_bubble_rounded,
          color: Colors.white,
          backgroundColor: const Color(0xFF00BFA5),
          onTap: onMessage,
          size: 72,
          isPrimary: true,
        ),
      ],
    );
  }

  String _getLanguageFlag(String language) => LanguageFlags.getFlagByName(language);
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final double size;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.onTap,
    required this.size,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: color,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}
