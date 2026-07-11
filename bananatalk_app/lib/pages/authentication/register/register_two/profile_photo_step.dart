import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/widgets/auth_gradient_button.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_picker_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Required profile-photo step in the register wizard. Tapping the avatar
/// opens the same picker bottom sheet used by the post-signup edit flow,
/// which runs the picked image through ImageCropper at a locked 1:1 aspect.
/// The chosen photo is reported up to the parent and uploaded after the
/// final register call. Continue is disabled until a photo is picked.
class ProfilePhotoStep extends StatelessWidget {
  final File? pickedPhoto;
  final void Function(File? photo) onPhotoChanged;
  final VoidCallback onContinue;

  const ProfilePhotoStep({
    super.key,
    required this.pickedPhoto,
    required this.onPhotoChanged,
    required this.onContinue,
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasPhoto
                          ? null
                          : context.surfaceColor,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    // ClipOval + CircleAvatar gives an explicit center-crop
                    // preview inside the circle (BoxFit.cover already
                    // center-crops, this just makes the crop boundary exact
                    // for a perfect circle rather than a rounded box).
                    child: hasPhoto
                        ? ClipOval(
                            child: CircleAvatar(
                              radius: 70,
                              backgroundImage: FileImage(pickedPhoto!),
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 72,
                            color: context.textMuted,
                          ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.scaffoldBackground,
                          width: 3,
                        ),
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
                        size: 20,
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
            onPressed: hasPhoto ? onContinue : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
