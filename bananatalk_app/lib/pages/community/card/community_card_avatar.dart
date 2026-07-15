import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/presence_provider.dart';
import 'package:bananatalk_app/utils/country_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Avatar section of [CommunityCard].
///
/// Renders a circular avatar with:
/// - A gradient ring border
/// - The user's profile image (or initials fallback)
/// - A country-flag badge at the bottom-right
/// - A reactive online-status dot at the top-right, driven by [presenceProvider]
///   when [userId] is provided, or by the legacy [isOnline] prop otherwise.
class CommunityCardAvatar extends StatelessWidget {
  const CommunityCardAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    required this.nativeLanguage,
    this.country,
    this.isVip = false,
    this.isOnline = false,
    this.userId,
    this.size = 64.0,
  });

  final String? imageUrl;
  final String name;
  final String nativeLanguage;

  /// The user's country display name (from `location.country`). When it
  /// resolves to a flag, the badge shows the COUNTRY flag (a Brazilian
  /// shows 🇧🇷, not Portuguese's 🇵🇹); otherwise it falls back to the
  /// native-language flag. Callers must pass null when the user's
  /// privacy settings hide the country (showCountryRegion == false).
  final String? country;

  /// Whether to render a VIP frame around the avatar.
  final bool isVip;

  /// Legacy prop for backwards-compatibility. Ignored when [userId] is set.
  final bool isOnline;

  /// When provided, the presence dot is driven reactively by [presenceProvider]
  /// instead of the static [isOnline] prop.
  final String? userId;

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
            ? Border.all(color: const Color(0xFFFFD700), width: 2.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            _buildCircleImage(context),
            _buildFlagBadge(context),
            if (userId != null)
              Consumer(
                builder: (_, ref, __) {
                  final online = ref.watch(
                    presenceProvider.select((p) => p.isOnline(userId!)),
                  );
                  if (!online) return const SizedBox.shrink();
                  return _buildOnlineDot(context);
                },
              )
            else if (isOnline)
              _buildOnlineDot(context),
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
      left: 0,
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
                  CountryFlags.userBadgeFlag(
                    country: country,
                    nativeLanguage: nativeLanguage,
                  ),
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
