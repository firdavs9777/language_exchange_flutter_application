import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

enum ChatSnackBarType { success, error, info }

/// Show a styled snackbar matching the chat-flow convention:
/// floating, 14-radius, 16-margin, leading icon + message.
/// Shape intentionally matches profile_snackbar / auth_snackbar.
void showChatSnackBar(
  BuildContext context, {
  required String message,
  ChatSnackBarType type = ChatSnackBarType.success,
}) {
  switch (type) {
    case ChatSnackBarType.success:
      HapticFeedback.lightImpact();
      break;
    case ChatSnackBarType.error:
      HapticFeedback.mediumImpact();
      break;
    case ChatSnackBarType.info:
      break;
  }

  final (icon, color, duration) = switch (type) {
    ChatSnackBarType.success => (
      Icons.check_circle_rounded,
      AppColors.success,
      const Duration(seconds: 2),
    ),
    ChatSnackBarType.error => (
      Icons.error_rounded,
      AppColors.error,
      const Duration(seconds: 3),
    ),
    ChatSnackBarType.info => (
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
