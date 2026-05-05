import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/edit/language_edit.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the "Language Exchange" card: native language, language to learn,
/// and language level (with its bottom-sheet picker).
///
/// All current values arrive via constructor; mutations are reported through
/// [onNativeLanguageChanged], [onLanguageToLearnChanged], and
/// [onLanguageLevelChanged].
class LanguageSection extends ConsumerStatefulWidget {
  final String selectedNativeLanguage;
  final String selectedLanguageToLearn;
  final String? selectedLanguageLevel;
  final void Function(String) onNativeLanguageChanged;
  final void Function(String) onLanguageToLearnChanged;
  final void Function(String) onLanguageLevelChanged;

  const LanguageSection({
    super.key,
    required this.selectedNativeLanguage,
    required this.selectedLanguageToLearn,
    required this.selectedLanguageLevel,
    required this.onNativeLanguageChanged,
    required this.onLanguageToLearnChanged,
    required this.onLanguageLevelChanged,
  });

  @override
  ConsumerState<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends ConsumerState<LanguageSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          l10n.languageExchange,
          Icons.language_rounded,
          AppColors.info,
        ),
        _buildSectionContainer(context, [
          _buildModernEditTile(
            context: context,
            icon: Icons.translate_rounded,
            iconColor: AppColors.info,
            title: l10n.nativeLanguage,
            subtitle: widget.selectedNativeLanguage == 'Not Set'
                ? null
                : widget.selectedNativeLanguage,
            isFirst: true,
            onTap: () async {
              final updated = await Navigator.push<String>(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileLanguageEdit(
                        initialLanguage: widget.selectedNativeLanguage,
                        type: 'native',
                        otherLanguage: widget.selectedLanguageToLearn,
                      ),
                    ),
                  ) ??
                  widget.selectedNativeLanguage;
              if (updated != widget.selectedNativeLanguage) {
                widget.onNativeLanguageChanged(updated);
              }
            },
          ),
          _buildDivider(context),
          _buildModernEditTile(
            context: context,
            icon: Icons.school_rounded,
            iconColor: AppColors.warning,
            title: l10n.languageToLearn,
            subtitle: widget.selectedLanguageToLearn == 'Not Set'
                ? null
                : widget.selectedLanguageToLearn,
            onTap: () async {
              final updated = await Navigator.push<String>(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileLanguageEdit(
                        initialLanguage: widget.selectedLanguageToLearn,
                        type: 'learn',
                        otherLanguage: widget.selectedNativeLanguage,
                      ),
                    ),
                  ) ??
                  widget.selectedLanguageToLearn;
              if (updated != widget.selectedLanguageToLearn) {
                widget.onLanguageToLearnChanged(updated);
              }
            },
          ),
          _buildDivider(context),
          _buildModernEditTile(
            context: context,
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF7C4DFF),
            title: l10n.languageLevel,
            subtitle: widget.selectedLanguageLevel,
            trailingChip: widget.selectedLanguageLevel,
            isLast: true,
            onTap: _showLanguageLevelPicker,
          ),
        ]),
      ],
    );
  }

  // ─── Language level picker ────────────────────────────────────────────────

  String _levelDescription(String level, AppLocalizations l10n) {
    return switch (level) {
      'A1' => l10n.levelBeginner,
      'A2' => l10n.levelElementary,
      'B1' => l10n.levelIntermediate,
      'B2' => l10n.levelUpperIntermediate,
      'C1' => l10n.levelAdvanced,
      'C2' => l10n.levelProficient,
      _ => '',
    };
  }

  void _showLanguageLevelPicker() {
    final l10n = AppLocalizations.of(context)!;
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    const accent = Color(0xFF7C4DFF);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectYourLevel,
                        style: context.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.howWellDoYouSpeak(
                          widget.selectedLanguageToLearn != 'Not Set'
                              ? widget.selectedLanguageToLearn
                              : l10n.theLanguage,
                        ),
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: levels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final level = levels[i];
                      final isSelected =
                          widget.selectedLanguageLevel == level;
                      final desc = _levelDescription(level, l10n);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _onLevelSelected(ctx, level),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.1)
                                  : context.containerColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              accent,
                                              Color(0xFF9C7CFF),
                                            ],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : context.containerHighColor,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: accent.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    level,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : context.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    desc,
                                    style: context.titleSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: accent,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLevelSelected(BuildContext sheetCtx, String level) async {
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(sheetCtx);
    widget.onLanguageLevelChanged(level);
    try {
      await ref
          .read(authServiceProvider)
          .updateUserLanguageLevel(languageLevel: level);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.languageLevelSetTo(level))),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdate}: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
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
