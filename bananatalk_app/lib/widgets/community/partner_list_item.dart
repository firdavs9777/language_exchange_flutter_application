import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/language_level_badge.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// List item for partner discovery (Tandem/HelloTalk style)
class PartnerListItem extends StatelessWidget {
  final Community user;
  final VoidCallback? onTap;
  final VoidCallback? onWave;
  final VoidCallback? onMessage;

  const PartnerListItem({
    super.key,
    required this.user,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return Stack(
      children: [
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: user.isOnline ? AppColors.success : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: user.profileImageUrl != null
                ? CachedImageWidget(
                    imageUrl: user.profileImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        // Online indicator dot
        if (user.isOnline)
          Positioned(
            right: 2,
            bottom: 2,
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
            if (user.age != null && user.age! > 0) ...[
              Text(
                ', ${user.age}',
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
            if (user.isVip) ...[
              const SizedBox(width: 6),
              _buildVipBadge(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        // Language exchange row
        _buildLanguageRow(context),
        const SizedBox(height: 2),
        // Location row
        _buildLocationRow(context),
      ],
    );
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
    final location = user.location;
    final parts = <String>[];
    if (location.city.isNotEmpty) {
      parts.add(location.city);
    }
    if (location.country.isNotEmpty) {
      parts.add(location.country);
    }

    if (parts.isEmpty) return const SizedBox.shrink();

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
            parts.join(', '),
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
