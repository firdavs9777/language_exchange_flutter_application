import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/profile_completion.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_status_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:flutter/material.dart';

/// Contains the VIP status card and the profile completion card — the two
/// "highlight" banners shown between the stats row and language card.
///
/// Both sub-widgets are kept in this file as private classes because they have
/// no standalone reuse outside this section.
class ProfileHighlightsTab extends StatelessWidget {
  const ProfileHighlightsTab({super.key, required this.user});

  final Community user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileCompletionCard(user: user),
        const SizedBox(height: 20),
        _VipStatusCard(user: user),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile completion card
// ---------------------------------------------------------------------------

/// The status line under "Profile completion" for [percentage].
String profileCompletionStatus(AppLocalizations l10n, int percentage) {
  if (percentage < 50) return l10n.justGettingStarted;
  if (percentage < 80) return l10n.lookingGood;
  return l10n.almostThere;
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.user});
  final Community user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completion =
        calculateProfileCompletion(profileCompletionFieldsOf(user));
    final percentage = completion.percent;
    final missing = [for (final f in completion.missing.take(3)) f.label(l10n)];

    if (percentage >= 100) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusText = profileCompletionStatus(l10n, percentage);
    Color color;
    IconData statusIcon;
    if (percentage < 50) {
      color = const Color(0xFFFF9800);
      statusIcon = Icons.rocket_launch_rounded;
    } else if (percentage < 80) {
      color = const Color(0xFF2196F3);
      statusIcon = Icons.trending_up_rounded;
    } else {
      color = AppColors.primary;
      statusIcon = Icons.celebration_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileCompletion,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: context.captionSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: context.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.profileCompletionAdd(missing.join(', ')),
                    style: context.captionSmall.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
// VIP status card
// ---------------------------------------------------------------------------

class _VipStatusCard extends StatelessWidget {
  const _VipStatusCard({required this.user});
  final Community user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVip = user.isVip;
    // Free users get a rich card with the real perks (2026-10-18); the plain
    // white "upgrade" row was easy to scroll past.
    if (!isVip) return _VipUpsellCard(user: user);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => isVip
                    ? VipStatusScreen(userId: user.id)
                    : VipPlansScreen(userId: user.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isVip
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    )
                  : null,
              color: isVip ? null : context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: isVip
                  ? null
                  : Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
              boxShadow: isVip
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isVip
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFFFFD700).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: isVip ? Colors.white : const Color(0xFFFFD700),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isVip ? l10n.vipMember : l10n.upgradeToVip,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isVip
                                      ? Colors.white
                                      : context.textPrimary,
                                ),
                              ),
                            ),
                            if (isVip) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.profileActive,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVip
                              ? l10n.profileEnjoyingPremium
                              : l10n.profileUnlockUnlimited,
                          style: context.bodySmall.copyWith(
                            color: isVip
                                ? Colors.white.withValues(alpha: 0.9)
                                : context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isVip ? Colors.white : const Color(0xFFFFD700),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Free users' VIP card on their own profile: gold gradient, the three
/// strongest real perks, and a clear "Go VIP" button.
class _VipUpsellCard extends StatelessWidget {
  const _VipUpsellCard({required this.user});
  final Community user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void open() => Navigator.push(
          context,
          AppPageRoute(builder: (_) => VipPlansScreen(userId: user.id)),
        );
    Widget perk(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF7C2D12)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(
                    color: const Color(0xFF431407),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        key: const Key('profile-vip-upsell'),
        color: Colors.transparent,
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded,
                            color: Color(0xFF92400E), size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.upgradeToVip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF431407),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  perk(Icons.smart_toy_rounded, l10n.perkUnlimitedTutor),
                  perk(Icons.visibility_rounded, l10n.perkSeeVisitors),
                  perk(Icons.favorite_rounded, l10n.perkMoreMatches),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      key: const Key('profile-vip-go'),
                      onPressed: open,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF431407),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.goVip,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
