import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum MatchType { perfect, youLearnTheirs, theyLearnYours, sameNative, none }

class LanguageMatchCard extends ConsumerWidget {
  final Community profile;

  const LanguageMatchCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(userProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        final matchType = _calculateMatchType(currentUser, profile);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.isDarkMode ? [] : AppShadows.sm,
            border: Border.all(
              color: context.dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Language Match',
                    style: context.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Language comparison
              _buildLanguageComparison(context),
              if (matchType != MatchType.none) ...[
                const SizedBox(height: 12),
                _buildMatchMessage(context, matchType),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  MatchType _calculateMatchType(Community currentUser, Community profile) {
    final iLearnTheirNative =
        currentUser.language_to_learn.toLowerCase() ==
        profile.native_language.toLowerCase();
    final theyLearnMyNative =
        profile.language_to_learn.toLowerCase() ==
        currentUser.native_language.toLowerCase();

    if (iLearnTheirNative && theyLearnMyNative) return MatchType.perfect;
    if (iLearnTheirNative) return MatchType.youLearnTheirs;
    if (theyLearnMyNative) return MatchType.theyLearnYours;
    if (currentUser.native_language.toLowerCase() ==
        profile.native_language.toLowerCase()) {
      return MatchType.sameNative;
    }
    return MatchType.none;
  }

  Widget _buildLanguageComparison(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildLanguageCard(
            context,
            profile.native_language,
            'Native',
            true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.containerColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: _buildLanguageCard(
            context,
            profile.language_to_learn,
            'Learning',
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    String language,
    String label,
    bool isNative,
  ) {
    final flag = _getLanguageFlag(language);
    final level = profile.languageLevel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNative ? AppColors.primary.withOpacity(0.3) : context.dividerColor,
          width: isNative ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(flag, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(
            language,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (level != null && isNative) ...[
            const SizedBox(height: 6),
            _buildLevelDots(context, level),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelDots(BuildContext context, String level) {
    final filledDots = _levelToDotsCount(level);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (i) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filledDots ? AppColors.primary : context.dividerColor,
          ),
        )),
        const SizedBox(width: 4),
        Text(
          level.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  int _levelToDotsCount(String? level) {
    switch (level?.toUpperCase()) {
      case 'A1':
        return 1;
      case 'A2':
        return 2;
      case 'B1':
        return 3;
      case 'B2':
        return 4;
      case 'C1':
      case 'C2':
        return 5;
      default:
        return 0;
    }
  }

  Widget _buildMatchMessage(BuildContext context, MatchType matchType) {
    String message;
    Color bgColor;
    IconData icon;

    switch (matchType) {
      case MatchType.perfect:
        message = 'Perfect language exchange match!';
        bgColor = AppColors.secondary;
        icon = Icons.auto_awesome;
        break;
      case MatchType.youLearnTheirs:
        message = "You're learning what they speak!";
        bgColor = AppColors.success;
        icon = Icons.school_rounded;
        break;
      case MatchType.theyLearnYours:
        message = "They're learning what you speak!";
        bgColor = AppColors.success;
        icon = Icons.record_voice_over_rounded;
        break;
      case MatchType.sameNative:
        message = 'You share the same native language';
        bgColor = AppColors.info;
        icon = Icons.handshake_rounded;
        break;
      case MatchType.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(context.isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: bgColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: bgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.isDarkMode ? bgColor : bgColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageFlag(String language) {
    if (language.isEmpty) return LanguageFlags.getFlag('');

    final langLower = language.toLowerCase().trim();

    final nameToCodeMap = {
      'english': 'en',
      'korean': 'ko',
      'japanese': 'ja',
      'chinese': 'zh',
      'spanish': 'es',
      'french': 'fr',
      'german': 'de',
      'italian': 'it',
      'portuguese': 'pt',
      'russian': 'ru',
      'arabic': 'ar',
      'hindi': 'hi',
      'thai': 'th',
      'vietnamese': 'vi',
    };

    if (nameToCodeMap.containsKey(langLower)) {
      return LanguageFlags.getFlag(nameToCodeMap[langLower]!);
    }

    if (langLower.length == 2) {
      return LanguageFlags.getFlag(langLower);
    }

    return LanguageFlags.getFlag('');
  }
}
