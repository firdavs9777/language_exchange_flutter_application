import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_picker_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Optional profile-photo step in the register wizard. Tapping the avatar
/// opens the same picker bottom sheet used by the post-signup edit flow,
/// which now runs single picks through ImageCropper. The chosen photo is
/// reported up to the parent and uploaded after the final register call.
class ProfilePhotoStep extends StatelessWidget {
  final File? pickedPhoto;
  final void Function(File? photo) onPhotoChanged;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const ProfilePhotoStep({
    super.key,
    required this.pickedPhoto,
    required this.onPhotoChanged,
    required this.onContinue,
    required this.onSkip,
  });

  Future<void> _pick(BuildContext context) async {
    final files = await showPhotoPickerSheet(
      context,
      existingCount: 0,
      pendingCount: pickedPhoto == null ? 0 : 1,
      maxImages: 1,
    );
    if (files == null || files.isEmpty) return;
    onPhotoChanged(files.first);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhoto = pickedPhoto != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.addProfilePhotoTitle,
            textAlign: TextAlign.center,
            style: context.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: () => _pick(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasPhoto
                          ? null
                          : context.surfaceColor,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      image: hasPhoto
                          ? DecorationImage(
                              image: FileImage(pickedPhoto!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasPhoto
                        ? null
                        : Icon(
                            Icons.person_rounded,
                            size: 80,
                            color: context.textMuted,
                          ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        hasPhoto ? Icons.edit_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          AuthGradientButton(
            label: l10n.nextButton,
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onSkip,
            child: Text(
              l10n.addProfilePhotoSkip,
              style: context.titleSmall.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
