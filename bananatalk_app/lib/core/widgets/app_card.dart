// lib/core/widgets/app_card.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// A customizable card widget following BananaTalk design system
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.onTap,
    this.onLongPress,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: borderRadius ?? AppRadius.borderLG,
        border: border,
        boxShadow: hasShadow ? (boxShadow ?? AppShadows.sm) : null,
      ),
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadius ?? AppRadius.borderLG,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// A gradient card with nice visual appeal
class AppGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: borderRadius ?? AppRadius.borderXL,
        boxShadow: AppShadows.colored,
      ),
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? AppRadius.borderXL,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// A list tile card for settings or options
class AppListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool showDivider;
  final bool showChevron;

  const AppListTile({
    super.key,
    this.leadingIcon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.showDivider = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                if (leadingIcon != null || leading != null) ...[
                  leading ?? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor ?? AppColors.gray100,
                      borderRadius: AppRadius.borderMD,
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 20,
                      color: iconColor ?? AppColors.gray700,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (showChevron && trailing == null)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.gray400,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: leadingIcon != null || leading != null ? 70 : 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

/// Stats card for displaying metrics
class AppStatsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const AppStatsCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;

    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderMD,
            ),
            child: Icon(icon, color: cardColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
