import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/language_level_badge.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// List item for partner discovery (Tandem/HelloTalk style)
class PartnerListItem extends StatelessWidget {
  final Community user;
  final Community? currentUser;
  final VoidCallback? onTap;
  final VoidCallback? onWave;
  final VoidCallback? onMessage;

  const PartnerListItem({
    super.key,
    required this.user,
    this.currentUser,
    this.onTap,
    this.onWave,
    this.onMessage,
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
    return Stack(
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
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final matchReason = _getMatchReason();
    final showAge = PrivacyUtils.shouldShowAge(user);
    final showOnline = PrivacyUtils.shouldShowOnlineStatus(user);

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
        // Location + last active row
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
        // Match reason + last active
        if (matchReason != null || (showOnline && !user.isOnline && user.lastActiveText.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                // Match reason badge
                if (matchReason != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        matchReason,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (matchReason != null && showOnline && !user.isOnline && user.lastActiveText.isNotEmpty)
                  const SizedBox(width: 8),
                // Last active time (only show if online status is visible)
                if (showOnline && !user.isOnline && user.lastActiveText.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: context.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        user.lastActiveText,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Get a match reason string based on language compatibility and shared topics
  String? _getMatchReason() {
    if (currentUser == null) return null;

    // Check language match
    if (user.native_language.isNotEmpty &&
        currentUser!.language_to_learn.isNotEmpty &&
        user.native_language.toLowerCase() == currentUser!.language_to_learn.toLowerCase()) {
      return 'Speaks ${_formatLang(user.native_language)}';
    }

    if (user.language_to_learn.isNotEmpty &&
        currentUser!.native_language.isNotEmpty &&
        user.language_to_learn.toLowerCase() == currentUser!.native_language.toLowerCase()) {
      return 'Learning ${_formatLang(user.language_to_learn)}';
    }

    // Check shared topics
    if (user.topics.isNotEmpty && currentUser!.topics.isNotEmpty) {
      for (final topic in user.topics) {
        if (currentUser!.topics.contains(topic)) {
          return 'Also likes $topic';
        }
      }
    }

    return null;
  }

  String _formatLang(String lang) {
    if (lang.isEmpty) return lang;
    return '${lang[0].toUpperCase()}${lang.substring(1).toLowerCase()}';
  }

  /// Get flag emoji for a language (handles both codes and names)
  String _getLanguageFlag(String language) {
    if (language.isEmpty) return LanguageFlags.getFlag('');

    // Common language name to code mappings
    const nameToCodeMap = {
      'english': 'en', 'spanish': 'es', 'french': 'fr', 'german': 'de',
      'italian': 'it', 'portuguese': 'pt', 'russian': 'ru', 'chinese': 'zh',
      'japanese': 'ja', 'korean': 'ko', 'arabic': 'ar', 'hindi': 'hi',
      'dutch': 'nl', 'turkish': 'tr', 'polish': 'pl', 'swedish': 'sv',
      'danish': 'da', 'norwegian': 'no', 'finnish': 'fi', 'czech': 'cs',
      'greek': 'el', 'hebrew': 'he', 'thai': 'th', 'vietnamese': 'vi',
      'indonesian': 'id', 'malay': 'ms', 'ukrainian': 'uk', 'romanian': 'ro',
      'hungarian': 'hu', 'bulgarian': 'bg', 'croatian': 'hr', 'serbian': 'sr',
    };

    final langLower = language.toLowerCase();

    // Try name mapping first
    if (nameToCodeMap.containsKey(langLower)) {
      return LanguageFlags.getFlag(nameToCodeMap[langLower]!);
    }
    // Try as code directly
    if (language.length <= 3) {
      return LanguageFlags.getFlag(langLower);
    }
    return LanguageFlags.getFlag('');
  }

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wave button
        _ActionButton(
          icon: Icons.waving_hand,
          color: const Color(0xFFFFB74D),
          onTap: () {
            HapticFeedback.lightImpact();
            onWave?.call();
          },
          tooltip: 'Wave',
        ),
        const SizedBox(width: 8),
        // Message button
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          color: const Color(0xFF00BFA5),
          onTap: () {
            HapticFeedback.lightImpact();
            onMessage?.call();
          },
          tooltip: 'Message',
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
