import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/language_flag_badge.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? profilePicture;
  final String userName;
  final double radius;
  final bool isVip;

  /// When non-null, overlays a small flag badge at the bottom-left corner —
  /// matches the chat list / community card pattern so the partner's native
  /// language is visible at a glance next to every message bubble.
  final String? nativeLanguage;

  const UserAvatar({
    Key? key,
    this.profilePicture,
    required this.userName,
    required this.radius,
    this.isVip = false,
    this.nativeLanguage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = profilePicture != null && profilePicture!.isNotEmpty
        ? ImageUtils.normalizeImageUrl(profilePicture)
        : null;

    final avatar = normalizedUrl != null && normalizedUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: normalizedUrl,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: radius,
              backgroundImage: imageProvider,
              backgroundColor: context.containerColor,
            ),
            placeholder: (context, url) => _buildShimmerAvatar(context),
            errorWidget: (context, url, error) => _buildFallbackAvatar(context),
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 100),
            memCacheWidth: (radius * 4).toInt(), // 2x for retina
            memCacheHeight: (radius * 4).toInt(),
            cacheManager: AppImageCacheManager.instance,
          )
        : _buildFallbackAvatar(context);

    Widget result = avatar;
    if (isVip) {
      result = VipAvatarFrameCompact(
        isVip: true,
        size: radius * 2,
        child: result,
      );
    }

    if (nativeLanguage != null && nativeLanguage!.isNotEmpty) {
      // Tiny badges read better with a slightly larger glyph than the
      // proportional default — clamp the size to keep the overlay legible
      // on the 18 px avatar used next to message bubbles.
      final badgeSize = (radius * 0.85).clamp(14.0, 22.0);
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          result,
          LanguageFlagBadge(
            nativeLanguage: nativeLanguage,
            size: badgeSize,
            offset: isVip ? 2 : 0,
          ),
        ],
      );
    }

    return result;
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.containerColor,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShimmerAvatar(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.containerColor,
      child: _AvatarShimmer(radius: radius),
    );
  }
}

/// Lightweight shimmer effect for avatar loading
class _AvatarShimmer extends StatefulWidget {
  final double radius;

  const _AvatarShimmer({required this.radius});

  @override
  State<_AvatarShimmer> createState() => _AvatarShimmerState();
}

class _AvatarShimmerState extends State<_AvatarShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.of(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.containerColor,
                context.containerColor.withValues(alpha: 0.5),
                context.containerColor,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
