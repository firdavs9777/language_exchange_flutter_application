import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/main.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class ProfileTheme extends ConsumerStatefulWidget {
  const ProfileTheme({super.key});

  @override
  _ProfileThemeState createState() => _ProfileThemeState();
}

class _ProfileThemeState extends ConsumerState<ProfileTheme> {
  @override
  Widget build(BuildContext context) {
    // Watch the themeProvider to get the current theme mode
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          'Profile Theme',
          style: context.titleLarge,
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
                  'Auto Switch (System Theme)',
                  style: context.titleMedium,
                ),
                trailing: Switch(
                  value: themeMode == ThemeMode.system,
                  onChanged: (bool value) {
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
                'When enabled, the app will follow your system theme settings',
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
                      'Light Mode',
                      style: context.titleMedium,
                    ),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          ref.read(themeProvider.notifier).setTheme(value);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                    },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  ListTile(
                    title: Text(
                      'Dark Mode',
                      style: context.titleMedium,
                    ),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          ref.read(themeProvider.notifier).setTheme(value);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
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
