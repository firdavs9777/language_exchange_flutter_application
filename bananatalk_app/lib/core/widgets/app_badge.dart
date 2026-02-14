// lib/core/widgets/app_badge.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum BadgeVariant { primary, secondary, success, warning, error, info }
enum BadgeSize { small, medium, large }

/// A badge/chip widget for labels and tags
class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final BadgeSize size;
  final IconData? icon;
  final bool outlined;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.size = BadgeSize.medium,
    this.icon,
    this.outlined = false,
    this.onTap,
    this.onDelete,
  });

  Color get _backgroundColor {
    if (outlined) return Colors.transparent;
    switch (variant) {
      case BadgeVariant.primary:
        return AppColors.primaryLight.withValues(alpha: 0.2);
      case BadgeVariant.secondary:
        return AppColors.gray200;
      case BadgeVariant.success:
        return AppColors.successLight;
      case BadgeVariant.warning:
        return AppColors.warningLight;
      case BadgeVariant.error:
        return AppColors.errorLight;
      case BadgeVariant.info:
        return AppColors.infoLight;
    }
  }

  Color get _textColor {
    switch (variant) {
      case BadgeVariant.primary:
        return AppColors.primary;
      case BadgeVariant.secondary:
        return AppColors.gray700;
      case BadgeVariant.success:
        return AppColors.success;
      case BadgeVariant.warning:
        return AppColors.warning;
      case BadgeVariant.error:
        return AppColors.error;
      case BadgeVariant.info:
        return AppColors.info;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double get _fontSize {
    switch (size) {
      case BadgeSize.small:
        return 11;
      case BadgeSize.medium:
        return 13;
      case BadgeSize.large:
        return 15;
    }
  }

  double get _iconSize {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 14;
      case BadgeSize.large:
        return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppRadius.borderRound,
        border: outlined ? Border.all(color: _textColor, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: _textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: _iconSize,
                color: _textColor,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badge);
    }

    return badge;
  }
}

/// Dot badge for notifications
class AppDotBadge extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final Color? color;
  final int? count;
  final Alignment alignment;

  const AppDotBadge({
    super.key,
    required this.child,
    this.showBadge = true,
    this.color,
    this.count,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft ? -2 : null,
          bottom: alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft ? -2 : null,
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? -2 : null,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? -2 : null,
          child: count != null && count! > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color ?? AppColors.error,
                    borderRadius: AppRadius.borderRound,
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    count! > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color ?? AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Language level badge (A1, A2, B1, B2, C1, C2)
class LanguageLevelBadge extends StatelessWidget {
  final String level;
  final bool compact;

  const LanguageLevelBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  Color get _color {
    switch (level.toUpperCase()) {
      case 'A1':
        return const Color(0xFF4CAF50); // Green
      case 'A2':
        return const Color(0xFF8BC34A); // Light green
      case 'B1':
        return const Color(0xFFFFEB3B); // Yellow
      case 'B2':
        return const Color(0xFFFF9800); // Orange
      case 'C1':
        return const Color(0xFFFF5722); // Deep orange
      case 'C2':
        return const Color(0xFF9C27B0); // Purple
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: AppRadius.borderSM,
        border: Border.all(color: _color, width: 1),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Online status indicator
class OnlineStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final bool showText;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.lastSeen,
    this.showText = false,
  });

  String get _statusText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final diff = now.difference(lastSeen!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return 'Long ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? AppColors.online : AppColors.offline,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            _statusText,
            style: AppTypography.caption.copyWith(
              color: isOnline ? AppColors.online : AppColors.gray500,
            ),
          ),
        ],
      ],
    );
  }
}
