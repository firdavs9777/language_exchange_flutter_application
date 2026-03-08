import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';

class UserAvatar extends StatelessWidget {
  final String? profilePicture;
  final String userName;
  final double radius;
  final bool isVip;

  const UserAvatar({
    Key? key,
    this.profilePicture,
    required this.userName,
    required this.radius,
    this.isVip = false,
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
              backgroundColor: Colors.grey[300],
            ),
            placeholder: (context, url) => _buildShimmerAvatar(),
            errorWidget: (context, url, error) => _buildFallbackAvatar(),
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 100),
            memCacheWidth: (radius * 4).toInt(), // 2x for retina
            memCacheHeight: (radius * 4).toInt(),
            cacheManager: AppImageCacheManager.instance,
          )
        : _buildFallbackAvatar();

    if (isVip) {
      return VipAvatarFrameCompact(
        isVip: true,
        size: radius * 2,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShimmerAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
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
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
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
