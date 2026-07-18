import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/pages/community/single/single_community_topics.dart';
import 'package:bananatalk_app/pages/community/single/single_community_location_card.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';

/// About tab body: bio, story highlights, languages, interests, personal info.
class SingleCommunityAbout extends ConsumerWidget {
  final Community community;

  const SingleCommunityAbout({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      key: const PageStorageKey<String>('about'),
      padding: const EdgeInsets.all(16),
      children: [
        // Bio Section
        _buildBioSection(context, isDark),

        const SizedBox(height: 12),

        // Languages Section
        _buildLanguagesSection(context, isDark),

        const SizedBox(height: 12),

        // Interests (Mutual Interests card — folded in from the removed
        // Overview tab; reuses the same modular widget as before rather
        // than duplicating a second hand-rolled topics section here).
        SingleCommunityTopics(community: community),

        const SizedBox(height: 12),

        // Personal Info (MBTI, Blood Type)
        _buildPersonalInfoSection(context, isDark),

        const SizedBox(height: 12),

        // Location (city-level map preview; text-only fallback / hidden
        // entirely if no location data or privacy settings hide it)
        _buildLocationSection(context, isDark),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bio
  // ---------------------------------------------------------------------------

  Widget _buildBioSection(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final hasBio = community.bio.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.blue[700]!, Colors.blue[900]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.bio,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              hasBio ? community.bio : l10n.noBioYet,
              style: context.bodyMedium.copyWith(
                color: hasBio ? context.textPrimary : context.textMuted,
                fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Languages
  // ---------------------------------------------------------------------------

  Widget _buildLanguagesSection(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.green[700]!, Colors.teal[800]!]
                        : [Colors.green[400]!, Colors.teal[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.languages,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLanguageCard(
                  context,
                  label: l10n.native,
                  language: community.native_language,
                  flag: LanguageFlags.getFlagByName(community.native_language),
                  icon: Icons.home_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: context.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageCard(
                  context,
                  label: l10n.learning,
                  language: community.language_to_learn,
                  flag: LanguageFlags.getFlagByName(
                    community.language_to_learn,
                  ),
                  icon: Icons.school_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String label,
    required String language,
    required String flag,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.captionSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            language,
            style: context.labelMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Personal Info (MBTI / Blood Type)
  // ---------------------------------------------------------------------------

  Widget _buildPersonalInfoSection(BuildContext context, bool isDark) {
    final hasMbti = community.mbti.isNotEmpty;
    final hasBloodType = community.bloodType.isNotEmpty;
    final hasOccupation = community.occupation.isNotEmpty;
    final hasSchool = community.school.isNotEmpty;

    if (!hasMbti && !hasBloodType && !hasOccupation && !hasSchool) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.purple[700]!, Colors.indigo[800]!]
                        : [Colors.purple[400]!, Colors.indigo[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.aboutMe,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasMbti || hasBloodType)
            Row(
              children: [
                if (hasMbti)
                  Expanded(
                    child: _buildPersonalInfoChip(
                      context,
                      icon: '🧠',
                      label: AppLocalizations.of(context)!.communityAboutMBTI,
                      value: community.mbti.toUpperCase(),
                      color: Colors.indigo,
                      isDark: isDark,
                    ),
                  ),
                if (hasMbti && hasBloodType) const SizedBox(width: 12),
                if (hasBloodType)
                  Expanded(
                    child: _buildPersonalInfoChip(
                      context,
                      icon: '🩸',
                      label: AppLocalizations.of(context)!.bloodType,
                      value: community.bloodType.toUpperCase(),
                      color: Colors.red,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          // Occupation + school are full-width rows because their values
          // can be long strings (e.g. "High School Teacher", "Seoul National
          // University") that don't fit cleanly in the half-width MBTI /
          // Blood-Type chip layout.
          if (hasOccupation) ...[
            if (hasMbti || hasBloodType) const SizedBox(height: 12),
            _buildPersonalInfoChip(
              context,
              icon: '💼',
              label: AppLocalizations.of(context)!.occupation,
              value: community.occupation,
              color: const Color(0xFF2196F3),
              isDark: isDark,
            ),
          ],
          if (hasSchool) ...[
            if (hasMbti || hasBloodType || hasOccupation)
              const SizedBox(height: 12),
            _buildPersonalInfoChip(
              context,
              icon: '🎓',
              label: AppLocalizations.of(context)!.school,
              value: community.school,
              color: const Color(0xFF7C4DFF),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

  Widget _buildLocationSection(BuildContext context, bool isDark) {
    final coordinates = community.location.coordinates;
    final hasCoords = coordinates.length >= 2 &&
        (coordinates[0] != 0.0 || coordinates[1] != 0.0);
    final canShowMap = hasCoords && PrivacyUtils.shouldShowLocation(community);
    final locationText = PrivacyUtils.getLocationText(community);

    // Nothing to show at all — no coords and no city/country text.
    if (!canShowMap && locationText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.teal[700]!, Colors.cyan[900]!]
                        : [Colors.teal[400]!, Colors.cyan[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.location,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleCommunityLocationCard(community: community),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoChip(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          // Expanded so long values (occupation / school) ellipsis cleanly
          // instead of overflowing horizontally. Short values like MBTI /
          // BloodType still render at intrinsic width inside it.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.captionSmall.copyWith(
                    color: context.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
