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

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.user});
  final Community user;

  static Map<String, dynamic> _calculate(Community user) {
    final fields = <String, bool>{
      'Profile Picture': user.imageUrls.isNotEmpty,
      'Name': user.name.isNotEmpty,
      'Bio': user.bio.isNotEmpty,
      'Native Language': user.native_language.isNotEmpty,
      'Learning Language': user.language_to_learn.isNotEmpty,
      'Location':
          user.location.country.isNotEmpty || user.location.city.isNotEmpty,
      'Topics': user.topics.isNotEmpty,
      'MBTI': user.mbti.isNotEmpty,
      'Birth Year': user.birth_year.isNotEmpty,
    };
    final completed = fields.values.where((v) => v).length;
    final percentage = (completed / fields.length * 100).round();
    final missing = fields.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .take(3)
        .toList();
    return {'percentage': percentage, 'missing': missing};
  }

  @override
  Widget build(BuildContext context) {
    final completion = _calculate(user);
    final percentage = completion['percentage'] as int;
    final missing = completion['missing'] as List<String>;

    if (percentage >= 100) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    String statusText;
    IconData statusIcon;
    if (percentage < 50) {
      color = const Color(0xFFFF9800);
      statusText = 'Just getting started';
      statusIcon = Icons.rocket_launch_rounded;
    } else if (percentage < 80) {
      color = const Color(0xFF2196F3);
      statusText = 'Looking good!';
      statusIcon = Icons.trending_up_rounded;
    } else {
      color = AppColors.primary;
      statusText = 'Almost there!';
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
                      'Profile Completion',
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
                    'Add: ${missing.join(", ")}',
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
    final isVip = user.isVip;

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
                            Text(
                              isVip ? 'VIP Member' : 'Upgrade to VIP',
                              style: context.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isVip
                                    ? Colors.white
                                    : context.textPrimary,
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
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
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
                              ? 'Enjoying premium features'
                              : 'Unlock unlimited messages & AI tools',
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
