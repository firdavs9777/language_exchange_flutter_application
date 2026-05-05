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
    // Watch the themeProvider to get the current theme mode
    final themeMode = ref.watch(themeProvider);

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
      body: Padding(
        padding: Spacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto switch toggle for system theme with enhanced color
            Container(
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: AppRadius.borderMD,
              ),
              child: ListTile(
                title: Text(
                  l10n.themeAutoSwitch,
                  style: context.titleMedium,
                ),
                trailing: Switch(
                  value: themeMode == ThemeMode.system,
                  onChanged: (bool value) {
                    HapticFeedback.selectionClick();
                    final newMode = value ? ThemeMode.system : ThemeMode.light;
                    ref.read(themeProvider.notifier).setTheme(newMode);
                  },
                  activeColor: AppColors.primary,
                  inactiveThumbColor: AppColors.gray500,
                  inactiveTrackColor: AppColors.gray400,
                ),
              ),
            ),
            Spacing.gapMD,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.themeSystemHint,
                style: context.bodySmall,
              ),
            ),
            Spacing.gapLG,
            Container(
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: AppRadius.borderMD,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      l10n.themeLightMode,
                      style: context.titleMedium,
                    ),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          HapticFeedback.selectionClick();
                          ref.read(themeProvider.notifier).setTheme(value);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                    },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  ListTile(
                    title: Text(
                      l10n.themeDarkMode,
                      style: context.titleMedium,
                    ),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          HapticFeedback.selectionClick();
                          ref.read(themeProvider.notifier).setTheme(value);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
