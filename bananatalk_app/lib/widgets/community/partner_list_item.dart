import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/language_level_badge.dart';
import 'package:bananatalk_app/utils/country_flags.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/story/story_gradient_ring.dart';

/// List item for partner discovery (Tandem/HelloTalk style)
class PartnerListItem extends StatelessWidget {
  final Community user;
  final Community? currentUser;
  final VoidCallback? onTap;
  final VoidCallback? onWave;
  /// Called when the avatar itself is tapped while [user.hasActiveStory] is
  /// true (opens the story viewer); other taps keep opening the profile via
  /// [onTap].
  final VoidCallback? onAvatarTap;

  const PartnerListItem({
    super.key,
    required this.user,
    this.currentUser,
    this.onTap,
    this.onWave,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray900 : Colors.white,
        ),
        child: Row(
          children: [
            // Profile picture with online indicator
            _buildAvatar(context),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: _buildUserInfo(context),
            ),
            // Action buttons
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final showOnline = PrivacyUtils.shouldShowOnlineStatus(user) && user.isOnline;
    final avatarStack = Stack(
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: showOnline ? AppColors.success : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: user.profileImageUrl != null
                ? CachedImageWidget(
                    imageUrl: user.profileImageUrl!,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        // Online indicator dot
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        // Identity flag overlay — bottom-left of avatar, matches the
        // chat-tile pattern. Country flag when known (a Brazilian shows
        // 🇧🇷, not Portuguese's 🇵🇹); falls back to the native-language
        // flag. Privacy: country suppressed when showCountryRegion is off.
        if (user.native_language.isNotEmpty)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                CountryFlags.userBadgeFlag(
                  country: (user.privacySettings?.showCountryRegion ?? true)
                      ? user.location.country
                      : null,
                  nativeLanguage: user.native_language,
                ),
                style: const TextStyle(fontSize: 14, height: 1.0),
              ),
            ),
          ),
      ],
    );

    // Wrap only the avatar in the story ring + its own tap target — the
    // rest of the tile still opens the profile via the outer InkWell.
    if (user.hasActiveStory) {
      return GestureDetector(
        onTap: onAvatarTap,
        child: StoryGradientRing(
          size: 80,
          strokeWidth: 2.5,
          hasStory: true,
          animate: false,
          child: avatarStack,
        ),
      );
    }
    return avatarStack;
  }

  Widget _buildUserInfo(BuildContext context) {
    final showAge = PrivacyUtils.shouldShowAge(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and age row
        Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showAge && user.age != null && user.age! > 0) ...[
              Text(
                ', ${user.age}',
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
            if (user.isNewUser) ...[
              const SizedBox(width: 6),
              _buildNewBadge(),
            ],
            if (user.isVip) ...[
              const SizedBox(width: 6),
              _buildVipBadge(),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Language exchange row
        _buildLanguageRow(context),
        const SizedBox(height: 4),
        // Location row
        _buildLocationRow(context),
        // Bio preview
        if (user.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              user.bio,
              style: context.bodySmall.copyWith(color: context.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Contextual tag chips (active status, responsiveness, shared interest, mbti, recency)
        _buildTagChips(context),
      ],
    );
  }

  /// Build up to 3 contextual chips ranked by signal strength.
  ///
  /// Priority: Active status → Responsiveness → Shared topic/language →
  /// MBTI → "Joined Xd ago" (only for the 7–30 day window; the NEW badge
  /// in the name row covers ≤6 days).
  Widget _buildTagChips(BuildContext context) {
    final showOnline = PrivacyUtils.shouldShowOnlineStatus(user);
    final l10n = AppLocalizations.of(context)!;
    final chips = <Widget>[];

    if (showOnline) {
      if (user.isOnline) {
        chips.add(_chip(context, l10n.partnerTagActiveNow, AppColors.success));
      } else if (user.lastActiveText.isNotEmpty) {
        chips.add(_chip(context, user.lastActiveText, context.textMuted));
      }
    }

    if (user.responseRate != null) {
      if (user.responseRate! >= 80) {
        chips.add(
          _chip(context, l10n.partnerTagVeryResponsive, AppColors.primary),
        );
      } else if (user.responseRate! >= 50) {
        chips.add(
          _chip(context, l10n.partnerTagQuickToReply, AppColors.primary),
        );
      }
    }

    final shared = _sharedSignal(context);
    if (shared != null) chips.add(_chip(context, shared, AppColors.primary));

    if (user.mbti.isNotEmpty) {
      chips.add(_chip(context, user.mbti, context.textSecondary));
    }

    if (!user.isNewUser) {
      final days = _daysSinceJoin();
      if (days != null && days <= 30) {
        chips.add(
          _chip(
            context,
            l10n.partnerTagJoinedDaysAgo(days),
            context.textSecondary,
          ),
        );
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips.take(3).toList(),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Shared signal: first overlapping topic with currentUser, falling back
  /// to a language-exchange match. Localized via [AppLocalizations].
  String? _sharedSignal(BuildContext context) {
    if (currentUser == null) return null;
    final l10n = AppLocalizations.of(context)!;

    if (user.topics.isNotEmpty && currentUser!.topics.isNotEmpty) {
      for (final topic in user.topics) {
        if (currentUser!.topics.contains(topic)) {
          return l10n.partnerTagBothLike(topic);
        }
      }
    }

    if (user.native_language.isNotEmpty &&
        currentUser!.language_to_learn.isNotEmpty &&
        user.native_language.toLowerCase() ==
            currentUser!.language_to_learn.toLowerCase()) {
      return l10n.partnerTagSpeaks(_formatLang(user.native_language));
    }

    if (user.language_to_learn.isNotEmpty &&
        currentUser!.native_language.isNotEmpty &&
        user.language_to_learn.toLowerCase() ==
            currentUser!.native_language.toLowerCase()) {
      return l10n.partnerTagLearning(_formatLang(user.language_to_learn));
    }

    return null;
  }

  int? _daysSinceJoin() {
    if (user.createdAt.isEmpty) return null;
    final joined = DateTime.tryParse(user.createdAt);
    if (joined == null) return null;
    return DateTime.now().difference(joined).inDays;
  }

  String _formatLang(String lang) {
    if (lang.isEmpty) return lang;
    return '${lang[0].toUpperCase()}${lang.substring(1).toLowerCase()}';
  }

  String _getLanguageFlag(String language) => LanguageFlags.getFlagByName(language);

  Widget _buildLanguageRow(BuildContext context) {
    final nativeFlag = _getLanguageFlag(user.native_language);
    final learningFlag = _getLanguageFlag(user.language_to_learn);

    return Row(
      children: [
        // Native language
        Text(
          nativeFlag,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.arrow_forward,
          size: 12,
          color: context.textSecondary,
        ),
        const SizedBox(width: 4),
        // Learning language
        Text(
          learningFlag,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 6),
        // Level badge
        if (user.languageLevel != null && user.languageLevel!.isNotEmpty)
          LanguageLevelBadge(
            level: user.languageLevel!,
            compact: true,
          ),
      ],
    );
  }

  Widget _buildLocationRow(BuildContext context) {
    final locationText = PrivacyUtils.getLocationText(user);

    if (locationText.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 14,
          color: context.textSecondary,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            locationText,
            style: context.bodySmall.copyWith(
              color: context.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF00C853)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'VIP',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return _WaveButton(
      onTap: () {
        HapticFeedback.lightImpact();
        onWave?.call();
      },
    );
  }
}

/// Primary CTA on the partner card. Teal gradient rounded-square with a
/// soft brand-tinted shadow — visually anchors the row as the single
/// most important action.
class _WaveButton extends StatelessWidget {
  const _WaveButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'Wave',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF00ACC1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
