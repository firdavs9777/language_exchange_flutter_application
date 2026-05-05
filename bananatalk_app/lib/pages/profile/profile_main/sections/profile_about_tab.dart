import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The "About" content section of the own-profile page.
///
/// Renders two cards:
/// - Language exchange card (native + learning language with proficiency bar)
/// - About me card (bio, MBTI chip, blood type chip)
///
/// Both cards are hidden if their backing data is empty.
class ProfileAboutTab extends StatelessWidget {
  const ProfileAboutTab({super.key, required this.user});

  final Community user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LanguageCard(user: user),
        const SizedBox(height: 16),
        _AboutCard(user: user),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Language card
// ---------------------------------------------------------------------------

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.user});
  final Community user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionAccent(
            color: AppColors.primary,
            label: l10n.languageExchange,
          ),
          const SizedBox(height: 18),
          _LanguageRow(
            label: l10n.nativeLanguage,
            language: user.native_language.isEmpty
                ? l10n.notSet
                : user.native_language,
            flag: LanguageFlags.getFlagByName(user.native_language),
            color: AppColors.primary,
            level: 'Native',
            isNative: true,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: context.dividerColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          _LanguageRow(
            label: l10n.learning,
            language: user.language_to_learn.isEmpty
                ? l10n.notSet
                : user.language_to_learn,
            flag: LanguageFlags.getFlagByName(user.language_to_learn),
            color: const Color(0xFFFF9800),
            level: user.languageLevel,
            isNative: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.language,
    required this.flag,
    required this.color,
    required this.level,
    required this.isNative,
    required this.isDark,
  });

  final String label;
  final String language;
  final String flag;
  final Color color;
  final String? level;
  final bool isNative;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(flag, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                language,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isNative && level != null && level!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ProficiencyBar(level: level!, color: color, isDark: isDark),
              ] else if (isNative) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: color),
                      const SizedBox(width: 3),
                      Text(
                        'Native',
                        style: context.captionSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProficiencyBar extends StatelessWidget {
  const _ProficiencyBar({
    required this.level,
    required this.color,
    required this.isDark,
  });

  final String level;
  final Color color;
  final bool isDark;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  static String _levelDesc(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return 'Beginner';
      case 'A2':
        return 'Elementary';
      case 'B1':
        return 'Intermediate';
      case 'B2':
        return 'Upper Intermediate';
      case 'C1':
        return 'Advanced';
      case 'C2':
        return 'Proficient';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _levels.indexOf(level.toUpperCase());
    final desc = _levelDesc(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                level.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              desc,
              style: context.captionSmall.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(6, (index) {
            final isFilled = index <= currentIndex;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index < 5 ? 3 : 0),
                decoration: BoxDecoration(
                  color: isFilled
                      ? color
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : color.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// About card
// ---------------------------------------------------------------------------

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.user});
  final Community user;

  @override
  Widget build(BuildContext context) {
    if (user.bio.isEmpty && user.mbti.isEmpty && user.bloodType.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionAccent(
            color: const Color(0xFF9C27B0),
            label: AppLocalizations.of(context)!.aboutMe,
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : context.containerColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                user.bio,
                style: context.bodyMedium.copyWith(
                  color: context.textPrimary,
                  height: 1.55,
                ),
              ),
            ),
          ],
          if (user.mbti.isNotEmpty || user.bloodType.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.mbti.isNotEmpty)
                  _TagChip(
                    emoji: '🧠',
                    label: user.mbti.toUpperCase(),
                    color: const Color(0xFF673AB7),
                    isDark: isDark,
                  ),
                if (user.bloodType.isNotEmpty)
                  _TagChip(
                    emoji: '🩸',
                    label: user.bloodType.toUpperCase(),
                    color: const Color(0xFFE53935),
                    isDark: isDark,
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
// Shared private helpers
// ---------------------------------------------------------------------------

/// Coloured left-border accent with a section title — used by both cards.
class _SectionAccent extends StatelessWidget {
  const _SectionAccent({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: context.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String emoji;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
