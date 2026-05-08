import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum SettingsSnackBarType { info, success, error }

void showSettingsSnackBar(
  BuildContext context, {
  required String message,
  SettingsSnackBarType type = SettingsSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    SettingsSnackBarType.success => AppColors.primary,
    SettingsSnackBarType.error => AppColors.error,
    SettingsSnackBarType.info => Theme.of(context).colorScheme.surface,
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
      duration: duration,
    ),
  );
}
