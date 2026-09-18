import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/language_flag_badge.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/widgets/story/story_gradient_ring.dart';
import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';

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
  /// Display name for the moment's own language (the language the post is
  /// written in), resolved from [FilterOptions.languages] — the full shared
  /// catalog once loaded, its static fallback before that — so it always
  /// matches what the filter bar shows. Falls back to the raw
  /// (upper-cased) code for anything not in the list.
  String _momentLanguageDisplayName(String code) {
    final normalized = code.toLowerCase();
    for (final lang in FilterOptions.languages) {
      if (lang['code'] == normalized) return lang['name']!;
    }
    return code.toUpperCase();
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
                // The ring is the same widget the chat list, community cards
                // and profile headers already use. moments.js simply never
                // sent the flag, so this avatar had nothing to ring -- the
                // fix was server-side, not here.
                StoryGradientRing(
                  hasStory: moment.user.hasActiveStory,
                  size: 48,
                  child: CachedCircleAvatar(
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
                    Flexible(
                      child: Text(
                        moment.user.name.toUpperCase(),
                        style: context.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _LanguageBadgeChip(
                      label: _momentLanguageDisplayName(moment.language),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // The shared pill. What stood here was a green-underlined
                // native code, an arrow, the learning code, and five dots
                // generated with `index < 3` -- a constant, so a beginner and
                // a C2 speaker rendered identically on every card in the feed.
                LanguageExchangePill(
                  nativeLanguage: moment.user.native_language,
                  learningLanguage: moment.user.language_to_learn,
                  languageLevel: moment.user.languageLevel,
                  dense: true,
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

/// Small pill chip showing the language a moment was posted in (e.g.
/// "Japanese"), resolved via [FilterOptions.languages] so it always
/// matches the language filter bar's naming. Purely presentational.
class _LanguageBadgeChip extends StatelessWidget {
  final String label;

  const _LanguageBadgeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderRound,
      ),
      child: Text(
        label,
        style: context.captionSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
