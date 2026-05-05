import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Generic confirm/cancel dialog used by logout and clear-cache flows.
///
/// Returns `true` if the user tapped the confirm button, `false` or `null`
/// if they cancelled or dismissed the dialog.
Future<bool?> showDrawerConfirmDialog({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String content,
  required String confirmLabel,
  required String cancelLabel,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (BuildContext ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: ctx.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: ctx.titleMedium.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: ctx.bodySmall.copyWith(
                  color: ctx.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: ctx.containerColor,
                      ),
                      child: Text(
                        cancelLabel,
                        style: TextStyle(
                          color: ctx.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: isDestructive
                            ? AppColors.error
                            : iconColor,
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows the logout confirmation dialog.
///
/// Returns `true` if the user confirmed, `false` / `null` on cancel.
/// The caller is responsible for performing the actual logout after confirming.
Future<bool?> showLogoutConfirmDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDrawerConfirmDialog(
    context: context,
    icon: Icons.logout_rounded,
    iconColor: AppColors.error,
    title: l10n.logout,
    content: l10n.logoutConfirmBody,
    confirmLabel: l10n.logout,
    cancelLabel: l10n.cancel,
    isDestructive: true,
  );
}
