import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/language_flag_badge.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Avatar + name + language chips + timestamp + menu row at the top of a
/// MomentCard. Pure render — no state. Navigation is handled by callbacks.
class MomentCardHeader extends StatelessWidget {
  final Moments moment;
  final VoidCallback onAvatarTap;
  final VoidCallback onMenuTap;

  const MomentCardHeader({
    super.key,
    required this.moment,
    required this.onAvatarTap,
    required this.onMenuTap,
  });

  // ---------------------------------------------------------------------------
  // Language helpers (duplicated from orchestrator; keep co-located so the
  // header remains self-contained).
  // ---------------------------------------------------------------------------

  String _getLanguageCode(String language) {
    final langLower = language.toLowerCase();
    if (langLower.contains('japan') || langLower == 'jp') return 'JP';
    if (langLower.contains('english') || langLower == 'en') return 'EN';
    if (langLower.contains('korean') || langLower == 'ko') return 'KO';
    if (langLower.contains('chinese') || langLower == 'zh') return 'ZH';
    if (langLower.contains('spanish') || langLower == 'es') return 'ES';
    if (langLower.contains('french') || langLower == 'fr') return 'FR';
    if (langLower.contains('german') || langLower == 'de') return 'DE';
    if (langLower.contains('italian') || langLower == 'it') return 'IT';
    if (langLower.contains('portuguese') || langLower == 'pt') return 'PT';
    if (langLower.contains('russian') || langLower == 'ru') return 'RU';
    if (langLower.contains('arabic') || langLower == 'ar') return 'AR';
    if (langLower.contains('hindi') || langLower == 'hi') return 'HI';
    if (langLower.contains('tajik') || langLower == 'tg') return 'TG';
    return language.toUpperCase().substring(
      0,
      language.length > 2 ? 2 : language.length,
    );
  }

  String _getRelativeTime(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo('${difference.inMinutes}');
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo('${difference.inHours}');
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return l10n.weeksAgo((difference.inDays / 7).floor());
    }
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CachedCircleAvatar(
                  imageUrl: moment.user.imageUrls.isNotEmpty
                      ? moment.user.imageUrls[0]
                      : null,
                  radius: 24,
                  backgroundColor: context.containerColor,
                  errorWidget: Icon(
                    Icons.person,
                    size: 22,
                    color: context.textSecondary,
                  ),
                ),
                LanguageFlagBadge(
                  nativeLanguage: moment.user.native_language,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      moment.user.name.toUpperCase(),
                      style: context.labelLarge,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Native language with underline
                    Container(
                      padding: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.success,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _getLanguageCode(moment.user.native_language),
                        style: context.captionSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: context.textMuted,
                    ),
                    const SizedBox(width: 6),
                    // Learning language
                    Text(
                      _getLanguageCode(moment.user.language_to_learn),
                      style: context.captionSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Language level dots (3 filled, 2 empty)
                    Row(
                      children: List.generate(5, (index) {
                        return Container(
                          margin: const EdgeInsets.only(left: 2),
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: index < 3
                                ? context.textSecondary
                                : context.dividerColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Time + More button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onMenuTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_horiz,
                  color: context.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getRelativeTime(context, moment.createdAt),
                style: context.captionSmall.copyWith(color: context.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
