// lib/core/widgets/app_avatar.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum AvatarSize { xs, sm, md, lg, xl, xxl }

/// A customizable avatar widget with online status indicator
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AvatarSize size;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Widget? badge;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.md,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
    this.backgroundColor,
    this.badge,
  });

  double get _size {
    switch (size) {
      case AvatarSize.xs:
        return 24;
      case AvatarSize.sm:
        return 32;
      case AvatarSize.md:
        return 44;
      case AvatarSize.lg:
        return 56;
      case AvatarSize.xl:
        return 72;
      case AvatarSize.xxl:
        return 96;
    }
  }

  double get _statusSize {
    switch (size) {
      case AvatarSize.xs:
        return 8;
      case AvatarSize.sm:
        return 10;
      case AvatarSize.md:
        return 12;
      case AvatarSize.lg:
        return 14;
      case AvatarSize.xl:
        return 16;
      case AvatarSize.xxl:
        return 18;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.xs:
        return 10;
      case AvatarSize.sm:
        return 12;
      case AvatarSize.md:
        return 16;
      case AvatarSize.lg:
        return 20;
      case AvatarSize.xl:
        return 26;
      case AvatarSize.xxl:
        return 34;
    }
  }

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? _getBackgroundColor(),
        boxShadow: AppShadows.sm,
      ),
      child: ClipOval(
        child: _buildContent(),
      ),
    );

    if (showOnlineStatus || badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _statusSize,
                height: _statusSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.online : AppColors.offline,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
          if (badge != null)
            Positioned(
              right: -4,
              top: -4,
              child: badge!,
            ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (name == null || name!.isEmpty) return AppColors.gray400;

    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF2196F3), // Blue
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF009688), // Teal
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
    ];

    final hash = name!.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }
}

/// Avatar group for showing multiple users
class AppAvatarGroup extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String?> names;
  final int maxVisible;
  final AvatarSize size;
  final VoidCallback? onTap;

  const AppAvatarGroup({
    super.key,
    required this.imageUrls,
    this.names = const [],
    this.maxVisible = 3,
    this.size = AvatarSize.sm,
    this.onTap,
  });

  double get _size {
    switch (size) {
      case AvatarSize.xs:
        return 24;
      case AvatarSize.sm:
        return 32;
      case AvatarSize.md:
        return 44;
      case AvatarSize.lg:
        return 56;
      case AvatarSize.xl:
        return 72;
      case AvatarSize.xxl:
        return 96;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = imageUrls.length > maxVisible ? maxVisible : imageUrls.length;
    final overflow = imageUrls.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: _size,
        child: Stack(
          children: [
            for (int i = 0; i < visibleCount; i++)
              Positioned(
                left: i * (_size * 0.65),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: AppAvatar(
                    imageUrl: imageUrls[i],
                    name: names.length > i ? names[i] : null,
                    size: size,
                  ),
                ),
              ),
            if (overflow > 0)
              Positioned(
                left: visibleCount * (_size * 0.65),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gray200,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '+$overflow',
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontSize: _size * 0.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
