import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';

/// Shows a camera/gallery bottom sheet and returns the files chosen by the
/// user, or null if the user dismissed without picking.
///
/// [existingCount]  — number of already-uploaded images on the profile.
/// [pendingCount]   — number of locally-selected images not yet uploaded.
/// [maxImages]      — the per-profile cap (default 10).
///
/// Handles the "too many" guard and fires [onFilesSelected] with valid files.
/// The caller is responsible for updating state; this function is purely UI +
/// picker plumbing.
Future<List<File>?> showPhotoPickerSheet(
  BuildContext context, {
  required int existingCount,
  required int pendingCount,
  int maxImages = 10,
}) async {
  final l10n = AppLocalizations.of(context)!;
  List<File>? result;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return _PhotoPickerSheet(
        l10n: l10n,
        existingCount: existingCount,
        pendingCount: pendingCount,
        maxImages: maxImages,
        onFilesReady: (files) {
          result = files;
          Navigator.pop(sheetContext);
        },
        onError: (message) {
          Navigator.pop(sheetContext);
          if (context.mounted) {
            showProfileSnackBar(
              context,
              message: message,
              type: ProfileSnackBarType.error,
            );
          }
        },
      );
    },
  );

  return result;
}

// ---------------------------------------------------------------------------
// Private stateless sheet widget
// ---------------------------------------------------------------------------

class _PhotoPickerSheet extends StatelessWidget {
  final AppLocalizations l10n;
  final int existingCount;
  final int pendingCount;
  final int maxImages;
  final void Function(List<File> files) onFilesReady;
  final void Function(String message) onError;

  const _PhotoPickerSheet({
    required this.l10n,
    required this.existingCount,
    required this.pendingCount,
    required this.maxImages,
    required this.onFilesReady,
    required this.onError,
  });

  Future<void> _pickGallery(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
    if (pickedFiles.isEmpty) return;

    final totalImages = existingCount + pendingCount + pickedFiles.length;
    final remaining = maxImages - (existingCount + pendingCount);

    if (totalImages > maxImages) {
      onError(l10n.canOnlyAddMoreImages(remaining, maxImages));
      return;
    }

    final imagesToAdd = pickedFiles.take(5).toList();
    if (pickedFiles.length > 5) {
      // Fire the error after returning files so the caller sees both.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showProfileSnackBar(
            context,
            message: l10n.maxImagesPerUpload,
            type: ProfileSnackBarType.error,
          );
        }
      });
    }

    onFilesReady(imagesToAdd.map((f) => File(f.path)).toList());
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final totalImages = existingCount + pendingCount + 1;
    if (totalImages > maxImages) {
      onError(l10n.canOnlyHaveMaxImages(maxImages));
      return;
    }

    onFilesReady([File(pickedFile.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.addImages,
              style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_rounded,
                      label: l10n.chooseFromGallery,
                      subtitle: l10n.selectUpToImages,
                      color: AppColors.primary,
                      onTap: () => _pickGallery(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: l10n.takeAPhoto,
                      subtitle: '',
                      color: const Color(0xFF7C4DFF),
                      onTap: _pickCamera,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private source option card
// ---------------------------------------------------------------------------

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.captionSmall.copyWith(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
