import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Blocking update dialog. Two modes:
/// - force: barrier non-dismissible, no Later button, BackButton blocked
/// - soft: dismissible, Later button visible
///
/// Returns true if user tapped Update, false if Later, null if dismissed.
Future<bool?> showUpdateDialog({
  required BuildContext context,
  required bool force,
  required String iosUrl,
  required String androidUrl,
  String? releaseNotes,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: !force,
    builder: (ctx) => PopScope(
      canPop: !force,
      child: _UpdateDialogContent(
        force: force,
        iosUrl: iosUrl,
        androidUrl: androidUrl,
        releaseNotes: releaseNotes,
      ),
    ),
  );
}

class _UpdateDialogContent extends StatelessWidget {
  final bool force;
  final String iosUrl;
  final String androidUrl;
  final String? releaseNotes;

  const _UpdateDialogContent({
    required this.force,
    required this.iosUrl,
    required this.androidUrl,
    this.releaseNotes,
  });

  Future<void> _openStore(BuildContext context) async {
    HapticFeedback.lightImpact();
    final url = Platform.isIOS ? iosUrl : androidUrl;
    if (url.isEmpty) {
      _showStoreFailure(context);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showStoreFailure(context);
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      _showStoreFailure(context);
      return;
    }

    // For soft updates, dismiss after launching. For force, leave dialog up.
    if (!force) Navigator.of(context).pop(true);
  }

  void _showStoreFailure(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.updateOpenStoreFailed),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = releaseNotes?.trim();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: context.surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              force ? l10n.updateRequiredTitle : l10n.updateAvailableTitle,
              textAlign: TextAlign.center,
              style: context.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              force ? l10n.updateRequiredBody : l10n.updateAvailableBody,
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notes,
                  style: context.captionSmall.copyWith(
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openStore(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.updateNow,
                            style: context.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!force) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  l10n.updateLater,
                  style: context.titleSmall.copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
