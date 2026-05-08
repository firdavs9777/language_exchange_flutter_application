import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum StoriesSnackBarType { info, success, error }

void showStoriesSnackBar(
  BuildContext context, {
  required String message,
  StoriesSnackBarType type = StoriesSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    StoriesSnackBarType.success => AppColors.primary,
    StoriesSnackBarType.error => AppColors.error,
    StoriesSnackBarType.info => Theme.of(context).colorScheme.surface,
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
