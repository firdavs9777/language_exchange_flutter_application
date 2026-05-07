import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Avatar section of [CommunityCard].
///
/// Renders a circular avatar with:
/// - A gradient ring border
/// - The user's profile image (or initials fallback)
/// - A country-flag badge at the bottom-right
/// - An online-status dot at the top-right when [isOnline] is true
///
/// TODO(C18): Wire real presence data into [isOnline] once the presence system
/// lands in C18. Currently accepts the param and renders a green dot when true.
class CommunityCardAvatar extends StatelessWidget {
  const CommunityCardAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    required this.nativeLanguage,
    this.isVip = false,
    this.isOnline = false,
    this.size = 64.0,
  });

  final String? imageUrl;
  final String name;
  final String nativeLanguage;

  /// Whether to render a VIP frame around the avatar.
  final bool isVip;

  /// Whether to render a green online-status dot.
  ///
  /// TODO(C18): replace this manual param with a presence stream subscription.
  final bool isOnline;

  /// Diameter of the inner avatar circle.
  final double size;

  @override
  Widget build(BuildContext context) {
    // Outer container adds gradient ring (+6px total padding on each side).
    final outerSize = size + 6;

    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // VIP frame: an extra gold border when isVip is true.
        border: isVip
            ? Border.all(
                color: const Color(0xFFFFD700),
                width: 2.5,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            _buildCircleImage(context),
            _buildFlagBadge(context),
            if (isOnline) _buildOnlineDot(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl == null
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFF00ACC1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: context.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedImageWidget(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: _buildFallback(),
                placeholder: Container(
                  color: context.containerColor,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildFlagBadge(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.surfaceColor,
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: context.surfaceColor.withValues(alpha: 0.9),
              child: Center(
                child: Text(
                  LanguageFlags.getFlagByName(nativeLanguage),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineDot(BuildContext context) {
    // TODO(C18): presence wiring lands in C18; for now renders a static green dot.
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.online,
          border: Border.all(color: context.surfaceColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.online.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
