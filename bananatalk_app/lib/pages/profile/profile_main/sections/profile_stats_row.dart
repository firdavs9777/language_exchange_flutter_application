import 'package:bananatalk_app/pages/profile/followers.dart';
import 'package:bananatalk_app/pages/profile/followings.dart';
import 'package:bananatalk_app/pages/profile/moments/moments_list.dart';
import 'package:bananatalk_app/pages/profile/visitors_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/profile_visitor_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays the four stat counters: Followers / Following / Moments / Visitors.
///
/// Moments and Visitor counts are fetched inline via [Consumer] so the card
/// can load them without blocking the parent scaffold.
class ProfileStatsRow extends ConsumerWidget {
  const ProfileStatsRow({super.key, required this.user});

  final Community user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Followers
            Expanded(
              child: _StatItem(
                value: user.followers.length.toString(),
                label: l10n.followers,
                icon: Icons.people_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileFollowers(
                        id: user.id,
                        followerIds: user.followers,
                      ),
                    ),
                  ).then(
                    (_) => ref.invalidate(userProvider),
                  );
                },
              ),
            ),
            _VerticalDivider(context),
            // Following
            Expanded(
              child: _StatItem(
                value: user.followings.length.toString(),
                label: l10n.following,
                icon: Icons.person_add_rounded,
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileFollowings(
                        id: user.id,
                        followingIds: user.followings,
                      ),
                    ),
                  ).then(
                    (_) => ref.invalidate(userProvider),
                  );
                },
              ),
            ),
            _VerticalDivider(context),
            // Moments (async count)
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final momentsAsync = ref.watch(userMomentsProvider(user.id));
                  return momentsAsync.when(
                    data: (moments) => _StatItem(
                      value: moments.length.toString(),
                      label: l10n.moments,
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ProfileMoments(id: user.id),
                          ),
                        ).then(
                          (_) => ref.invalidate(userMomentsProvider(user.id)),
                        );
                      },
                    ),
                    loading: () => _StatItem(
                      value: '...',
                      label: l10n.moments,
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF9C27B0),
                      onTap: () {},
                    ),
                    error: (_, __) => _StatItem(
                      value: '0',
                      label: l10n.moments,
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF9C27B0),
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
            _VerticalDivider(context),
            // Visitors (async, VIP-gated)
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final visitorStatsAsync = ref.watch(myVisitorStatsProvider);

                  void openVisitors() {
                    if (user.isVip) {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          builder: (_) =>
                              ProfileVisitorsScreen(userId: user.id),
                        ),
                      );
                    } else {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const VipUpgradeSheet(
                          featureName: 'Profile Visitors',
                          description:
                              'See who visited your profile! Upgrade to VIP to unlock visitor tracking with detailed stats.',
                        ),
                      );
                    }
                  }

                  return visitorStatsAsync.when(
                    loading: () => _StatItem(
                      value: '...',
                      label: l10n.visitors,
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFFFF9800),
                      onTap: () {},
                      lockedForVip: !user.isVip,
                    ),
                    error: (_, __) => _StatItem(
                      value: '0',
                      label: l10n.visitors,
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFFFF9800),
                      onTap: openVisitors,
                      lockedForVip: !user.isVip,
                    ),
                    data: (data) {
                      final stats = data['stats'];
                      final uniqueVisitors = stats?['uniqueVisitors'] ?? 0;
                      return _StatItem(
                        value: data['success'] == true
                            ? uniqueVisitors.toString()
                            : '0',
                        label: l10n.visitors,
                        icon: Icons.visibility_rounded,
                        color: const Color(0xFFFF9800),
                        onTap: openVisitors,
                        lockedForVip: !user.isVip,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

Widget _VerticalDivider(BuildContext context) {
  return Container(
    width: 1,
    margin: const EdgeInsets.symmetric(vertical: 8),
    color: context.dividerColor.withValues(alpha: 0.4),
  );
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.lockedForVip = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool lockedForVip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (lockedForVip)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: context.captionSmall.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
