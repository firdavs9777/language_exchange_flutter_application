import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/pages/profile/edit/blood_type_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/hometown_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/mbti_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/topics_edit.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Renders the "Personal Information" card (MBTI, blood type, hometown)
/// and the "Interests" card (topics).
///
/// Stateless — all current values arrive via constructor; mutations are
/// reported through the corresponding callbacks.
class PersonalSection extends StatelessWidget {
  final String selectedMBTI;
  final String selectedBloodType;
  final String selectedAddress;
  final List<String> selectedTopics;
  final void Function(String) onMBTIChanged;
  final void Function(String) onBloodTypeChanged;
  final void Function(String) onAddressChanged;
  final void Function(List<String>) onTopicsChanged;

  const PersonalSection({
    super.key,
    required this.selectedMBTI,
    required this.selectedBloodType,
    required this.selectedAddress,
    required this.selectedTopics,
    required this.onMBTIChanged,
    required this.onBloodTypeChanged,
    required this.onAddressChanged,
    required this.onTopicsChanged,
  });

  // ─── Topics display helper ────────────────────────────────────────────────

  String _topicsDisplayText(AppLocalizations l10n) {
    if (selectedTopics.isEmpty) return l10n.notSet;
    final names = selectedTopics
        .map((id) {
          final topic = Topic.defaultTopics.firstWhere(
            (t) => t.id == id,
            orElse: () => Topic(id: id, name: id, icon: '', category: ''),
          );
          return topic.name;
        })
        .take(3)
        .toList();

    if (selectedTopics.length > 3) {
      return '${names.join(', ')} +${selectedTopics.length - 3} ${l10n.more}';
    }
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Personal Information ──────────────────────────────────────────
        _buildSectionHeader(
          context,
          l10n.personalInformation,
          Icons.info_rounded,
          AppColors.accent,
        ),
        _buildSectionContainer(context, [
          _buildModernEditTile(
            context: context,
            icon: Icons.psychology_rounded,
            iconColor: AppColors.accent,
            title: l10n.mbti,
            subtitle: selectedMBTI == 'Not Set' ? null : selectedMBTI,
            trailingChip: selectedMBTI != 'Not Set' ? selectedMBTI : null,
            isFirst: true,
            onTap: () async {
              final updated = await Navigator.push<String>(
                    context,
                    AppPageRoute(
                      builder: (context) =>
                          MBTIEdit(currentMBTI: selectedMBTI),
                    ),
                  ) ??
                  selectedMBTI;
              if (updated != selectedMBTI) onMBTIChanged(updated);
            },
          ),
          _buildDivider(context),
          _buildModernEditTile(
            context: context,
            icon: Icons.bloodtype_rounded,
            iconColor: AppColors.error,
            title: l10n.bloodType,
            subtitle:
                selectedBloodType == 'Not Set' ? null : selectedBloodType,
            trailingChip:
                selectedBloodType != 'Not Set' ? selectedBloodType : null,
            onTap: () async {
              final updated = await Navigator.push<String>(
                    context,
                    AppPageRoute(
                      builder: (context) => PersonBloodType(
                        currentSelectedBloodType: selectedBloodType,
                      ),
                    ),
                  ) ??
                  selectedBloodType;
              if (updated != selectedBloodType) onBloodTypeChanged(updated);
            },
          ),
          _buildDivider(context),
          _buildModernEditTile(
            context: context,
            icon: Icons.location_on_rounded,
            iconColor: AppColors.success,
            title: l10n.hometown,
            subtitle: selectedAddress == 'Not Set' ? null : selectedAddress,
            isLast: true,
            onTap: () async {
              final updated = await Navigator.push<String>(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileHometownEdit(
                        currentAddress: selectedAddress,
                      ),
                    ),
                  ) ??
                  selectedAddress;
              if (updated != selectedAddress) onAddressChanged(updated);
            },
          ),
        ]),

        // ── Interests ─────────────────────────────────────────────────────
        _buildSectionHeader(
          context,
          l10n.interests,
          Icons.favorite_rounded,
          const Color(0xFFE91E63),
        ),
        _buildSectionContainer(context, [
          _buildModernEditTile(
            context: context,
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFE91E63),
            title: l10n.topicsOfInterest,
            subtitle: selectedTopics.isEmpty
                ? null
                : _topicsDisplayText(l10n),
            trailingChip: selectedTopics.isNotEmpty
                ? '${selectedTopics.length}'
                : null,
            isFirst: true,
            isLast: true,
            onTap: () async {
              final result = await Navigator.push<List<String>>(
                context,
                AppPageRoute(
                  builder: (context) => ProfileTopicsEdit(
                    initialTopics: selectedTopics,
                    isStandalone: true,
                  ),
                ),
              );
              if (result != null) onTopicsChanged(result);
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
