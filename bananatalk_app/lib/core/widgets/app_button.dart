// lib/core/widgets/app_button.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum AppButtonSize { small, medium, large }
enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// A customizable button widget following BananaTalk design system
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;
  final bool isDisabled;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(context, isEnabled),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall;
      case AppButtonSize.medium:
        return AppTypography.buttonMedium;
      case AppButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  Widget _buildButton(BuildContext context, bool isEnabled) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimaryButton(isEnabled);
      case AppButtonVariant.secondary:
        return _buildSecondaryButton(isEnabled);
      case AppButtonVariant.outline:
        return _buildOutlineButton(isEnabled);
      case AppButtonVariant.ghost:
        return _buildGhostButton(isEnabled);
      case AppButtonVariant.danger:
        return _buildDangerButton(isEnabled);
    }
  }

  Widget _buildPrimaryButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.gray300,
        disabledForegroundColor: AppColors.gray500,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMD,
        ),
        elevation: 0,
      ),
      child: _buildContent(AppColors.white, AppColors.gray500),
    );
  }

  Widget _buildSecondaryButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.gray200,
        disabledForegroundColor: AppColors.gray500,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMD,
        ),
        elevation: 0,
      ),
      child: _buildContent(AppColors.primary, AppColors.gray500),
    );
  }

  Widget _buildOutlineButton(bool isEnabled) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.gray300,
          width: 1.5,
        ),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMD,
        ),
      ),
      child: _buildContent(AppColors.primary, AppColors.gray500),
    );
  }

  Widget _buildGhostButton(bool isEnabled) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMD,
        ),
      ),
      child: _buildContent(AppColors.primary, AppColors.gray500),
    );
  }

  Widget _buildDangerButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.gray300,
        disabledForegroundColor: AppColors.gray500,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMD,
        ),
        elevation: 0,
      ),
      child: _buildContent(AppColors.white, AppColors.gray500),
    );
  }

  Widget _buildContent(Color activeColor, Color disabledColor) {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
        ),
      );
    }

    final color = isDisabled ? disabledColor : activeColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _getIconSize(), color: color),
          const SizedBox(width: 8),
        ],
        Text(text, style: _getTextStyle().copyWith(color: color)),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: _getIconSize(), color: color),
        ],
      ],
    );
  }
}

/// Icon button with consistent styling
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final bool hasBadge;
  final int badgeCount;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.hasBadge = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: AppRadius.borderRound,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.borderRound,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: size,
            color: color ?? AppColors.gray700,
          ),
        ),
      ),
    );

    if (hasBadge && badgeCount > 0) {
      button = Badge(
        label: Text(
          badgeCount > 99 ? '99+' : '$badgeCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        child: button,
      );
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
