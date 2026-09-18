import 'package:bananatalk_app/core/theme/app_theme.dart';
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

  /// Whether the viewer already follows this author. Read from the provider by
  /// the card, never from local state: one author can appear in several posts
  /// in a single feed, and two of their cards must not disagree after a tap.
  final bool isFollowing;

  /// Null hides the pill entirely -- that is how a post of your own, or a feed
  /// with no signed-in viewer, renders no Follow affordance.
  final VoidCallback? onFollowToggle;

  const MomentCardHeader({
    super.key,
    required this.moment,
    required this.onAvatarTap,
    required this.onMenuTap,
    this.isFollowing = false,
    this.onFollowToggle,
  });

  // ---------------------------------------------------------------------------
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    // The post-language chip used to sit beside the name,
                    // costing 72pt. Measured at 320pt with Follow present, it
                    // squeezed the author's NAME to zero width. It was the
                    // weakest element there: the pill below already states the
                    // author's languages, and the feed has a language filter
                    // bar directly above it.
                    Text(
                      moment.user.name.toUpperCase(),
                      style: context.labelLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Follow, time and the overflow menu, on ONE line. The menu used to
              // sit stacked above the timestamp, which read as the time being a
              // caption of the button.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (onFollowToggle != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        key: const Key('moment-follow'),
                        onTap: onFollowToggle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.borderRound,
                            border: Border.all(
                              color: isFollowing
                                  ? context.dividerColor
                                  : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            isFollowing
                                ? AppLocalizations.of(context)!.following
                                : AppLocalizations.of(context)!.follow,
                            style: context.captionSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isFollowing
                                  ? context.textSecondary
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // A bare BoxConstraints() still let Material apply its 48pt
                  // minimum, which measured as 48 of the row's 296. Tightened
                  // explicitly; the whole avatar+name area is the tap target for
                  // the profile anyway, and the menu keeps a 32pt touch box.
                  IconButton(
                    onPressed: onMenuTap,
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    icon: Icon(Icons.more_horiz, color: context.iconColor),
                  ),
                ],
              ),
            ],
          ),

          // The pill gets its own full-width line. Sharing the header row, it
          // had a 95pt column against the ~138pt it needs, because Follow (89)
          // and the menu (48) take 143 of the row's 296 at 320pt. Indented to
          // sit under the name rather than the avatar.
          Padding(
            padding: const EdgeInsets.only(left: 58, top: 4),
            child: Row(
              children: [
                LanguageExchangePill(
                  nativeLanguage: moment.user.native_language,
                  learningLanguage: moment.user.language_to_learn,
                  languageLevel: moment.user.languageLevel,
                  dense: true,
                ),
                const Spacer(),
                // "16 hours ago" is ~90pt and was NOT flexible -- THAT is what
                // overflowed the name row at 320pt, not the pill and not
                // Follow. Here it has room, and it shrinks rather than pushing.
                Flexible(
                  child: Text(
                    _getRelativeTime(context, moment.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.captionSmall.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
