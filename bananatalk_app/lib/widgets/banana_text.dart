import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class BananaText extends StatelessWidget {
  final String text;
  final TextStyle? BanaStyles;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;

  const BananaText(
    this.text, {
    Key? key,
    this.BanaStyles,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Apply theme-aware color if style doesn't have explicit color
    TextStyle? effectiveStyle = BanaStyles;
    if (effectiveStyle != null && effectiveStyle.color == null) {
      effectiveStyle = effectiveStyle.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

/// Centralized text styles for BananaTalk
/// Uses system font (San Francisco on iOS, Roboto on Android)
/// Both have excellent multi-language support (Korean, Chinese, Japanese)
class BananaTextStyles {
  BananaTextStyles._();

  // ============================================================================
  // DISPLAY STYLES - For hero text, large titles (Bold 700)
  // ============================================================================

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.3,
  );

  // ============================================================================
  // TITLE STYLES - For section headers, card titles (SemiBold 600)
  // ============================================================================

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  // ============================================================================
  // BODY STYLES - For paragraphs, descriptions, chat (Regular 400)
  // ============================================================================

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.1,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.45,
  );

  // ============================================================================
  // LABEL STYLES - For buttons, chips, badges (Medium 500)
  // ============================================================================

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.35,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
  );

  // ============================================================================
  // CAPTION STYLES - For timestamps, hints (Regular 400, muted)
  // ============================================================================

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.35,
    color: AppColors.gray600,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.gray500,
  );

  // ============================================================================
  // LEGACY STYLES - Mapped to new system for backwards compatibility
  // ============================================================================

  // Headings (mapped to display styles)
  static const TextStyle heading = displayMedium;
  static const TextStyle subheading = titleLarge;
  static const TextStyle title = displayMedium;

  // Body text (mapped to body styles)
  static const TextStyle body = bodyMedium;
  static const TextStyle largeText = bodyLarge;
  static const TextStyle smallText = labelSmall;
  static const TextStyle lightText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w300,
    height: 1.5,
  );
  static const TextStyle boldText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    height: 1.5,
  );

  // ============================================================================
  // BUTTON STYLES (SemiBold 600)
  // ============================================================================

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Colors.white,
  );

  static const TextStyle buttonTextDark = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle largeButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Colors.white,
  );

  static const TextStyle smallButton = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: Colors.white,
  );

  // ============================================================================
  // LINK STYLES (Medium 500)
  // ============================================================================

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle linkBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ============================================================================
  // STATUS STYLES
  // ============================================================================

  static const TextStyle error = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  static const TextStyle success = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle warning = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );

  // ============================================================================
  // INPUT STYLES
  // ============================================================================

  static const TextStyle labelText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.gray500,
  );

  // ============================================================================
  // APP BAR STYLES
  // ============================================================================

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // ============================================================================
  // CARD STYLES
  // ============================================================================

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.gray600,
  );

  // ============================================================================
  // PRICE STYLES
  // ============================================================================

  static const TextStyle price = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
  );

  static const TextStyle priceStrike = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.gray500,
    decoration: TextDecoration.lineThrough,
  );

  // ============================================================================
  // CHAT-SPECIFIC STYLES
  // ============================================================================

  static const TextStyle chatMessage = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.45,
  );

  static const TextStyle chatMessageEmphasis = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.45,
  );
}
