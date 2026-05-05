import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// A single tile in the photo grid.
///
/// Handles two modes:
///  - [PhotoGridTile.existing] — an already-uploaded URL, with optional
///    profile-picture badge (index == 0) and delete button.
///  - [PhotoGridTile.pending]  — a locally-selected [File] not yet uploaded,
///    with a "NEW" badge and a delete button.
///
/// Both variants animate in with a scale-from-0.8 spring.
class PhotoGridTile extends StatelessWidget {
  /// The network URL to display (mutually exclusive with [localFile]).
  final String? imageUrl;

  /// The local file to display (mutually exclusive with [imageUrl]).
  final File? localFile;

  /// Position in the grid — used for the staggered entrance animation
  /// duration and to decide whether to show the profile-picture badge.
  final int index;

  /// Whether to show the delete/close button. Set false when only one
  /// existing image remains (can't delete the last profile picture).
  final bool showDeleteButton;

  /// Called when the user taps the delete button.
  final VoidCallback? onDelete;

  // Label shown on index == 0 existing tiles ("Profile").
  final String? profileLabel;

  const PhotoGridTile.existing({
    super.key,
    required String url,
    required this.index,
    required this.showDeleteButton,
    required this.onDelete,
    required this.profileLabel,
  })  : imageUrl = url,
        localFile = null;

  const PhotoGridTile.pending({
    super.key,
    required File file,
    required this.index,
    required this.onDelete,
  })  : imageUrl = null,
        localFile = file,
        showDeleteButton = true,
        profileLabel = null;

  bool get _isExisting => imageUrl != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Image -------------------------------------------------------
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isExisting
                ? CachedImageWidget(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: context.containerColor,
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: context.iconColor,
                      ),
                    ),
                  )
                : Image.file(localFile!, fit: BoxFit.cover),
          ),

          // ---- Profile-picture border (index 0 existing only) --------------
          if (_isExisting && index == 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2.5),
                  ),
                ),
              ),
            ),

          // ---- Pending-image border ----------------------------------------
          if (!_isExisting)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFF7C4DFF), width: 2),
                  ),
                ),
              ),
            ),

          // ---- Gradient scrim (existing only) ------------------------------
          if (_isExisting)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // ---- Delete button -----------------------------------------------
          if (showDeleteButton)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onDelete?.call();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // ---- Profile badge (index 0 existing) ----------------------------
          if (_isExisting && index == 0)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      profileLabel ?? l10n.profile,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ---- NEW badge (pending) -----------------------------------------
          if (!_isExisting)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
