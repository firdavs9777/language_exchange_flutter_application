import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The hero profile section: avatar (with camera tap-to-edit), name, username,
/// VIP badge and age/location chips.
///
/// Named [ProfileTabBar] because the spec targets this file for the visual
/// "top section" of the profile — analogous to a tab header area. No actual
/// [TabBar] widget is rendered; that may be added in a future iteration.
///
/// [onAvatarTap] should push [ProfilePictureEdit] and invalidate userProvider
/// on return. The callback pattern keeps navigation logic in the parent.
class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.user,
    required this.calculatedAge,
    required this.onAvatarTap,
  });

  final Community user;
  final int? calculatedAge;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final age = PrivacyUtils.getAge(user, calculatedAge);
    final locationText = PrivacyUtils.getLocationText(user);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar with camera badge
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                user.isVip
                    ? VipAvatarFrame(
                        isVip: true,
                        size: 124,
                        frameWidth: 4,
                        showGlow: true,
                        child: _AvatarInner(user: user, radius: 60),
                      )
                    : Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BFA5).withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            shape: BoxShape.circle,
                          ),
                          child: _AvatarInner(user: user, radius: 60),
                        ),
                      ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: context.surfaceColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name + verified badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.isVip) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFFFFD700),
                  size: 22,
                ),
              ],
            ],
          ),

          // Username
          if (user.displayUsername != null) ...[
            const SizedBox(height: 4),
            Text(
              user.displayUsername!,
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Info chips (age + location)
          if (age != null || locationText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (age != null)
                  _InfoChip(
                    icon: Icons.cake_rounded,
                    label: AppLocalizations.of(context)!
                        .yearsOld(age.toString()),
                    color: const Color(0xFF9C27B0),
                  ),
                if (locationText.isNotEmpty)
                  _InfoChip(
                    icon: Icons.location_on_rounded,
                    label: locationText,
                    color: const Color(0xFF2196F3),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _AvatarInner extends StatelessWidget {
  const _AvatarInner({required this.user, required this.radius});

  final Community user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: user.imageUrls.isNotEmpty
            ? CachedImageWidget(
                imageUrl: user.imageUrls[0],
                fit: BoxFit.cover,
              )
            : Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person_rounded,
                  size: radius,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
