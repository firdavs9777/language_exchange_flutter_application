import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/main.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class ProfileTheme extends ConsumerStatefulWidget {
  const ProfileTheme({super.key});

  @override
  _ProfileThemeState createState() => _ProfileThemeState();
}

class _ProfileThemeState extends ConsumerState<ProfileTheme> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isAuto = themeMode == ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.profileThemeTitle,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderCard(l10n, themeMode, isDark),
            const SizedBox(height: 24),

            // Auto switch (system mode)
            _buildSectionTitle(
              'Automatic',
              Icons.brightness_auto_rounded,
              const Color(0xFF7C4DFF),
            ),
            const SizedBox(height: 10),
            _buildAutoModeCard(l10n, isAuto, isDark),

            const SizedBox(height: 24),

            // Manual selection
            _buildSectionTitle(
              'Manual',
              Icons.palette_rounded,
              AppColors.primary,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildThemePreview(
                    label: l10n.themeLightMode,
                    icon: Icons.light_mode_rounded,
                    isSelected: themeMode == ThemeMode.light,
                    isDarkPreview: false,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(themeProvider.notifier)
                          .setTheme(ThemeMode.light);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemePreview(
                    label: l10n.themeDarkMode,
                    icon: Icons.dark_mode_rounded,
                    isSelected: themeMode == ThemeMode.dark,
                    isDarkPreview: true,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info hint
            _buildInfoHint(l10n, isDark),
          ],
        ),
      ),
    );
  }

  // ========== HEADER CARD ==========
  Widget _buildHeaderCard(
    AppLocalizations l10n,
    ThemeMode themeMode,
    bool isDark,
  ) {
    final modeIcon = themeMode == ThemeMode.system
        ? Icons.brightness_auto_rounded
        : themeMode == ThemeMode.dark
        ? Icons.dark_mode_rounded
        : Icons.light_mode_rounded;

    final modeLabel = themeMode == ThemeMode.system
        ? 'Following system'
        : themeMode == ThemeMode.dark
        ? l10n.themeDarkMode
        : l10n.themeLightMode;

    final modeColor = themeMode == ThemeMode.system
        ? const Color(0xFF7C4DFF)
        : themeMode == ThemeMode.dark
        ? const Color(0xFF1976D2)
        : const Color(0xFFFF9800);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            modeColor.withValues(alpha: isDark ? 0.2 : 0.12),
            modeColor.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modeColor.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [modeColor, modeColor.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: modeColor.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(modeIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current theme',
                  style: context.captionSmall.copyWith(
                    color: modeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  modeLabel,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION TITLE ==========
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
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
          title,
          style: context.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ========== AUTO MODE CARD ==========
  Widget _buildAutoModeCard(AppLocalizations l10n, bool isAuto, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          final newMode = isAuto ? ThemeMode.light : ThemeMode.system;
          ref.read(themeProvider.notifier).setTheme(newMode);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isAuto
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(
                        0xFF7C4DFF,
                      ).withValues(alpha: isDark ? 0.18 : 0.1),
                      const Color(
                        0xFF7C4DFF,
                      ).withValues(alpha: isDark ? 0.06 : 0.03),
                    ],
                  )
                : null,
            color: isAuto ? null : context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAuto
                  ? const Color(0xFF7C4DFF).withValues(alpha: 0.4)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : context.dividerColor.withValues(alpha: 0.5)),
              width: isAuto ? 1.5 : 1,
            ),
            boxShadow: !isDark && !isAuto
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF7C4DFF,
                  ).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.brightness_auto_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.themeAutoSwitch,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.themeSystemHint,
                      style: context.captionSmall.copyWith(
                        color: context.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: isAuto,
                onChanged: (bool value) {
                  HapticFeedback.selectionClick();
                  final newMode = value ? ThemeMode.system : ThemeMode.light;
                  ref.read(themeProvider.notifier).setTheme(newMode);
                },
                activeThumbColor: const Color(0xFF7C4DFF),
                activeTrackColor: const Color(
                  0xFF7C4DFF,
                ).withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== THEME PREVIEW CARD ==========
  Widget _buildThemePreview({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDarkPreview,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDarkPreview
        ? const Color(0xFF1976D2)
        : const Color(0xFFFF9800);

    // Preview card colors (independent of current app theme)
    final previewBg = isDarkPreview
        ? const Color(0xFF1A1B1E)
        : const Color(0xFFF5F6F8);
    final previewSurface = isDarkPreview
        ? const Color(0xFF2A2B2F)
        : Colors.white;
    final previewText = isDarkPreview ? Colors.white : const Color(0xFF1A1B1E);
    final previewMuted = isDarkPreview
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF8A8B8F);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : context.dividerColor.withValues(alpha: 0.5)),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (!isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null),
          ),
          child: Column(
            children: [
              // Mini phone mockup
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: previewBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkPreview
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status bar mock
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 4,
                          decoration: BoxDecoration(
                            color: previewMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 12,
                          height: 4,
                          decoration: BoxDecoration(
                            color: previewMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Card mock
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: previewSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: previewText.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  width: 28,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: previewMuted,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Smaller card
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: previewSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 4,
                            decoration: BoxDecoration(
                              color: previewText.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: previewMuted,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bottom button mock
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Label row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    )
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.dividerColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== INFO HINT ==========
  Widget _buildInfoHint(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Theme changes apply instantly across the entire app.',
              style: context.captionSmall.copyWith(
                color: isDark
                    ? const Color(0xFF64B5F6)
                    : const Color(0xFF1976D2),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
