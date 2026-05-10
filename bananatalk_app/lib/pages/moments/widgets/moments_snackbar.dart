import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum MomentsSnackBarType { info, success, error }

void showMomentsSnackBar(
  BuildContext context, {
  required String message,
  MomentsSnackBarType type = MomentsSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    MomentsSnackBarType.success => AppColors.primary,
    MomentsSnackBarType.error => AppColors.error,
    MomentsSnackBarType.info => Theme.of(context).colorScheme.surface,
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
