import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Theme context extension for easy access to theme values
extension ThemeContext on BuildContext {
  // ============================================================================
  // TEXT COLORS (theme-aware)
  // ============================================================================
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get textMuted => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.6);
  Color get textHint => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.4);
  Color get textOnPrimary => Theme.of(this).colorScheme.onPrimary;

  // ============================================================================
  // BACKGROUND COLORS (theme-aware)
  // ============================================================================
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get cardBackground => Theme.of(this).cardColor;
  Color get scaffoldBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get containerColor => isDarkMode ? AppColors.gray800 : AppColors.gray100;
  Color get containerHighColor => isDarkMode ? AppColors.gray700 : AppColors.gray200;

  // ============================================================================
  // OTHER COLORS
  // ============================================================================
  Color get dividerColor => Theme.of(this).colorScheme.outlineVariant;
  Color get iconColor => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  // ============================================================================
  // HELPERS
  // ============================================================================
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}

/// App-wide text styles with consistent sizing and theme-aware colors
/// Uses system font (San Francisco on iOS, Roboto on Android)
/// Both have excellent multi-language support (Korean, Chinese, Japanese)
///
/// Usage: Text('Hello', style: context.titleLarge)
extension AppTextStylesExtension on BuildContext {
  // ============================================================================
  // DISPLAY STYLES - For hero text, large titles (Bold 700)
  // ============================================================================

  /// Display Large: 28px, bold - Use for page heroes, onboarding
  TextStyle get displayLarge => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
    color: textPrimary,
  );

  /// Display Medium: 24px, bold - Use for section heroes
  TextStyle get displayMedium => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.25,
    color: textPrimary,
  );

  /// Display Small: 20px, bold - Use for card headers
  TextStyle get displaySmall => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.3,
    color: textPrimary,
  );

  // ============================================================================
  // TITLE STYLES - For section headers, card titles (SemiBold 600)
  // ============================================================================

  /// Title Large: 18px, semibold - Use for section headers
  TextStyle get titleLarge => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: textPrimary,
  );

  /// Title Medium: 16px, semibold - Use for card titles, list item titles
  TextStyle get titleMedium => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: textPrimary,
  );

  /// Title Small: 15px, semibold - Use for smaller card titles
  TextStyle get titleSmall => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: textPrimary,
  );

  // ============================================================================
  // BODY STYLES - For paragraphs, descriptions, chat (Regular 400)
  // ============================================================================

  /// Body Large: 16px, regular - Use for primary body text
  TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.1,
    height: 1.5,
    color: textPrimary,
  );

  /// Body Medium: 15px, regular - Use for standard body text, chat messages
  TextStyle get bodyMedium => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.5,
    color: textPrimary,
  );

  /// Body Small: 14px, regular - Use for secondary body text
  TextStyle get bodySmall => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.45,
    color: textSecondary,
  );

  // ============================================================================
  // LABEL STYLES - For buttons, chips, badges (Medium 500)
  // ============================================================================

  /// Label Large: 14px, medium weight - Use for button text
  TextStyle get labelLarge => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: textPrimary,
  );

  /// Label Medium: 13px, medium weight - Use for chips, badges
  TextStyle get labelMedium => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.35,
    color: textPrimary,
  );

  /// Label Small: 12px, medium weight - Use for small badges, meta info
  TextStyle get labelSmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
    color: textSecondary,
  );

  // ============================================================================
  // CAPTION STYLES - For timestamps, helper text (Regular 400, muted)
  // ============================================================================

  /// Caption: 12px, regular - Use for timestamps, hints
  TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.35,
    color: textSecondary,
  );

  /// Caption Small: 11px, regular - Use for very small text
  TextStyle get captionSmall => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.3,
    color: textMuted,
  );
}

/// Static text styles class for cases where BuildContext is not available
/// or for defining const styles
class AppTextStyles {
  AppTextStyles._();

  // Display
  static TextStyle displayLarge(BuildContext context) => context.displayLarge;
  static TextStyle displayMedium(BuildContext context) => context.displayMedium;
  static TextStyle displaySmall(BuildContext context) => context.displaySmall;

  // Title
  static TextStyle titleLarge(BuildContext context) => context.titleLarge;
  static TextStyle titleMedium(BuildContext context) => context.titleMedium;
  static TextStyle titleSmall(BuildContext context) => context.titleSmall;

  // Body
  static TextStyle bodyLarge(BuildContext context) => context.bodyLarge;
  static TextStyle bodyMedium(BuildContext context) => context.bodyMedium;
  static TextStyle bodySmall(BuildContext context) => context.bodySmall;

  // Label
  static TextStyle labelLarge(BuildContext context) => context.labelLarge;
  static TextStyle labelMedium(BuildContext context) => context.labelMedium;
  static TextStyle labelSmall(BuildContext context) => context.labelSmall;

  // Caption
  static TextStyle caption(BuildContext context) => context.caption;
  static TextStyle captionSmall(BuildContext context) => context.captionSmall;
}

/// Spacing constants - Use these instead of hardcoded values
/// Usage: SizedBox(height: AppSpacing.sm) or Padding(padding: AppSpacing.cardPadding)
class Spacing {
  Spacing._();

  // Base spacing values
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Common gaps (SizedBox shortcuts)
  static const SizedBox gapXXS = SizedBox(height: xxs);
  static const SizedBox gapXS = SizedBox(height: xs);
  static const SizedBox gapSM = SizedBox(height: sm);
  static const SizedBox gapMD = SizedBox(height: md);
  static const SizedBox gapLG = SizedBox(height: lg);
  static const SizedBox gapXL = SizedBox(height: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl);

  // Horizontal gaps
  static const SizedBox hGapXXS = SizedBox(width: xxs);
  static const SizedBox hGapXS = SizedBox(width: xs);
  static const SizedBox hGapSM = SizedBox(width: sm);
  static const SizedBox hGapMD = SizedBox(width: md);
  static const SizedBox hGapLG = SizedBox(width: lg);

  // Padding presets
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Screen/card padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
}
