import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/edit/bio_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/name_gender_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the "Basic Information" card: profile picture, name/gender, bio.
///
/// Owns no state — all current values flow in via constructor and mutations
/// are reported through [onNameGenderChanged] / [onBioChanged].
class BasicInfoSection extends ConsumerWidget {
  final String selectedName;
  final String selectedGender;
  final String selectedBio;
  final void Function(String name, String gender) onNameGenderChanged;
  final void Function(String bio) onBioChanged;

  const BasicInfoSection({
    super.key,
    required this.selectedName,
    required this.selectedGender,
    required this.selectedBio,
    required this.onNameGenderChanged,
    required this.onBioChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          l10n.basicInformation,
          Icons.person_rounded,
          AppColors.primary,
        ),
        _buildSectionContainer(context, [
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(userProvider).valueOrNull;
              if (user == null) return const SizedBox.shrink();
              return _buildModernEditTile(
                context: context,
                icon: Icons.photo_camera_rounded,
                iconColor: AppColors.primary,
                title: l10n.profilePicture,
                subtitle: user.imageUrls.isNotEmpty
                    ? l10n.tapToChange
                    : l10n.noPictureSet,
                isFirst: true,
                onTap: () async {
                  await Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfilePictureEdit(user: user),
                    ),
                  );
                  ref.invalidate(userProvider);
                },
              );
            },
          ),
          _buildDivider(context),
          _buildModernEditTile(
            context: context,
            icon: Icons.badge_rounded,
            iconColor: AppColors.info,
            title: l10n.nameAndGender,
            subtitle: selectedName == 'Not Set' ? null : selectedName,
            trailingChip: selectedGender != 'Not Set' ? selectedGender : null,
            onTap: () async {
              final result = await Navigator.push<Map<String, String>>(
                context,
                AppPageRoute(
                  builder: (context) => ProfileInfoSet(
                    userName: selectedName,
                    gender: selectedGender,
                  ),
                ),
              );
              if (result != null) {
                onNameGenderChanged(
                  result['userName'] ?? selectedName,
                  result['gender'] ?? selectedGender,
                );
              }
            },
          ),
          _buildDivider(context),
          _buildModernEditTile(
            context: context,
            icon: Icons.description_rounded,
            iconColor: AppColors.accent,
            title: l10n.bio,
            subtitle: selectedBio == 'Not Set'
                ? null
                : (selectedBio.length > 60
                      ? '${selectedBio.substring(0, 60)}...'
                      : selectedBio),
            isLast: true,
            onTap: () async {
              final updated = await Navigator.push<String>(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileBioEdit(
                        currentBio:
                            selectedBio == 'Not Set' ? '' : selectedBio,
                      ),
                    ),
                  ) ??
                  selectedBio;
              if (updated != selectedBio) onBioChanged(updated);
            },
          ),
        ]),
      ],
    );
  }
}

// ─── Shared tile helpers (file-private) ──────────────────────────────────────

Widget _buildSectionHeader(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 20, 12),
    child: Row(
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
          title,
          style: context.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionContainer(BuildContext context, List<Widget> children) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
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
    child: Column(children: children),
  );
}

Widget _buildDivider(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 68),
    child: Divider(
      height: 1,
      thickness: 1,
      color: context.dividerColor.withValues(alpha: 0.5),
    ),
  );
}

Widget _buildModernEditTile({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  String? subtitle,
  String? trailingChip,
  bool isFirst = false,
  bool isLast = false,
  required VoidCallback onTap,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isEmpty = subtitle == null;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final radius = BorderRadius.only(
    topLeft: Radius.circular(isFirst ? 20 : 0),
    topRight: Radius.circular(isFirst ? 20 : 0),
    bottomLeft: Radius.circular(isLast ? 20 : 0),
    bottomRight: Radius.circular(isLast ? 20 : 0),
  );

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodySmall.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isEmpty ? l10n.notSet : subtitle,
                    style: isEmpty
                        ? context.bodyMedium.copyWith(
                            color: context.textMuted,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          )
                        : context.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingChip != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingChip,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    ),
  );
}

