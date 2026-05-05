import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/language_level_badge.dart';
import 'package:bananatalk_app/widgets/community/quick_action_buttons.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';

/// Compact user tile for lists
class CompactUserTile extends StatelessWidget {
  final Community user;
  final VoidCallback? onTap;
  final VoidCallback? onWave;
  final bool showDistance;
  final double? distance; // in km

  const CompactUserTile({
    super.key,
    required this.user,
    this.onTap,
    this.onWave,
    this.showDistance = false,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and online status
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVip) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  size: 9,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'VIP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (PrivacyUtils.shouldShowAge(user) && user.age != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${user.age}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Language exchange
                    Row(
                      children: [
                        Text(
                          _getLanguageFlag(user.native_language),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          _getLanguageFlag(user.language_to_learn),
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (user.languageLevel != null) ...[
                          const SizedBox(width: 8),
                          LanguageLevelBadge(
                            level: user.languageLevel,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location or last active
                    Builder(
                      builder: (context) {
                        final locationText = PrivacyUtils.getLocationText(user);
                        final hasLocation = showDistance && distance != null || locationText.isNotEmpty;
                        return Row(
                          children: [
                            if (showDistance && distance != null) ...[
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatDistance(distance!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ] else if (locationText.isNotEmpty) ...[
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  locationText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (PrivacyUtils.shouldShowOnlineStatus(user) && user.lastActiveText.isNotEmpty) ...[
                              if (hasLocation)
                                Text(
                                  ' · ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              Text(
                                user.lastActiveText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: user.isOnline
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[500],
                                  fontWeight: user.isOnline
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Wave button
              WaveButton(
                onTap: onWave,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final profileImage = user.profileImageUrl;
    final avatarContent = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: profileImage == null
            ? const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: user.isVip
            ? null // VipAvatarFrame adds its own shadow
            : [
                BoxShadow(
                  color: const Color(0xFF00BFA5).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipOval(
        child: profileImage != null
            ? CachedImageWidget(
                imageUrl: profileImage,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: _buildFallbackAvatar(),
              )
            : _buildFallbackAvatar(),
      ),
    );

    return Stack(
      children: [
        // Avatar with optional VIP frame
        VipAvatarFrameCompact(
          isVip: user.isVip,
          size: 56,
          child: avatarContent,
        ),
        // Online indicator
        if (PrivacyUtils.shouldShowOnlineStatus(user) && user.isOnline)
          Positioned(
            right: user.isVip ? 2 : 0,
            bottom: user.isVip ? 2 : 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFF00BFA5),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  String _getLanguageFlag(String language) => LanguageFlags.getFlagByName(language);

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()}m';
    } else if (km < 10) {
      return '${km.toStringAsFixed(1)}km';
    } else {
      return '${km.round()}km';
    }
  }
}
