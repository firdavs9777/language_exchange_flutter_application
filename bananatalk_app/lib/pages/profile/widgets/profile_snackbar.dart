import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum ProfileSnackBarType { success, error, warning, info }

/// Show a styled snackbar matching the profile-edit convention:
/// floating, 14-radius, 16-margin, leading icon + message.
/// Fires the haptic appropriate to the type.
void showProfileSnackBar(
  BuildContext context, {
  required String message,
  ProfileSnackBarType type = ProfileSnackBarType.success,
}) {
  switch (type) {
    case ProfileSnackBarType.success:
      HapticFeedback.lightImpact();
      break;
    case ProfileSnackBarType.error:
      HapticFeedback.mediumImpact();
      break;
    case ProfileSnackBarType.warning:
    case ProfileSnackBarType.info:
      break;
  }

  final (icon, color, duration) = switch (type) {
    ProfileSnackBarType.success => (
      Icons.check_circle_rounded,
      AppColors.success,
      const Duration(seconds: 2),
    ),
    ProfileSnackBarType.error => (
      Icons.error_rounded,
      AppColors.error,
      const Duration(seconds: 3),
    ),
    ProfileSnackBarType.warning => (
      Icons.warning_rounded,
      const Color(0xFFFF9800),
      const Duration(seconds: 2),
    ),
    ProfileSnackBarType.info => (
      Icons.info_rounded,
      const Color(0xFF2196F3),
      const Duration(seconds: 2),
    ),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: duration,
    ),
  );
}
