import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum CommunitySnackBarType { info, success, error }

void showCommunitySnackBar(
  BuildContext context, {
  required String message,
  CommunitySnackBarType type = CommunitySnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    CommunitySnackBarType.success => AppColors.primary,
    CommunitySnackBarType.error => AppColors.error,
    CommunitySnackBarType.info => Theme.of(context).colorScheme.surface,
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
