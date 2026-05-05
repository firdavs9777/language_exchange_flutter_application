import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_confirm_dialog.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_grid_tile.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_picker_sheet.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_upload_handler.dart';

class ProfilePictureEdit extends ConsumerStatefulWidget {
  final Community user;

  const ProfilePictureEdit({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<ProfilePictureEdit> createState() => _ProfilePictureEditState();
}

class _ProfilePictureEditState extends ConsumerState<ProfilePictureEdit>
    with TickerProviderStateMixin {
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isUploading = false;
  bool _isRemoving = false;
  static const int maxImages = 10;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _existingImageUrls = List<String>.from(widget.user.imageUrls);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _openPhotoPicker() async {
    final files = await showPhotoPickerSheet(
      context,
      existingCount: _existingImageUrls.length,
      pendingCount: _selectedImages.length,
      maxImages: maxImages,
    );
    if (files != null && files.isNotEmpty) {
      setState(() => _selectedImages.addAll(files));
    }
  }

  void _removeSelectedImage(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _removeExistingImage(int index) async {
    final l10n = AppLocalizations.of(context)!;

    if (_existingImageUrls.length == 1) {
      showProfileSnackBar(
        context,
        message: l10n.mustKeepAtLeastOneProfilePicture,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    final confirmed = await showPhotoConfirmDialog(context,
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.red,
      title: l10n.removeImage,
      content: l10n.removeImageConfirm,
      confirmLabel: l10n.remove,
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isRemoving = true);

    final handler = PhotoUploadHandler(userId: widget.user.id);
    final result = await handler.deletePhoto(
      index,
      noTokenMessage: l10n.authenticationTokenNotFound,
      failedMessage: l10n.failedToUpdate,
      defaultSuccessMessage: l10n.imageRemovedSuccessfully,
    );

    if (!mounted) return;
    setState(() {
      if (result.success) {
        if (result.imageUrls != null && result.imageUrls!.isNotEmpty) {
          _existingImageUrls = result.imageUrls!;
        } else {
          _existingImageUrls.removeAt(index);
        }
      }
      _isRemoving = false;
    });

    if (result.success) {
      ref.invalidate(userProvider);
      showProfileSnackBar(context, message: result.message);
    } else {
      showProfileSnackBar(
        context,
        message: result.message,
        type: ProfileSnackBarType.error,
      );
    }
  }

  Future<void> _uploadProfilePictures() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedImages.isEmpty) {
      showProfileSnackBar(
        context,
        message: l10n.pleaseSelectAtLeastOneImage,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    setState(() => _isUploading = true);

    final handler = PhotoUploadHandler(userId: widget.user.id);
    final result = await handler.uploadPhotos(
      _selectedImages,
      noTokenMessage: l10n.authenticationTokenNotFound,
      fileTooLargeMessage: l10n.imageSizeExceedsLimit,
      unsupportedFormatPrefix: l10n.unsupportedImageFormat,
      failedMessage: l10n.failedToUpdate,
    );

    if (!mounted) return;
    setState(() {
      if (result.success) {
        if (result.imageUrls != null && result.imageUrls!.isNotEmpty) {
          _existingImageUrls = result.imageUrls!;
        }
        _selectedImages.clear();
      }
      _isUploading = false;
    });

    if (result.success) {
      ref.invalidate(userProvider);
      showProfileSnackBar(
        context,
        message: result.message.isNotEmpty
            ? result.message
            : l10n.imagesUploadedSuccessfully,
      );
    } else {
      showProfileSnackBar(
        context,
        message: result.message,
        type: ProfileSnackBarType.error,
      );
    }
  }

  Future<void> _removeAllProfilePictures() async {
    final l10n = AppLocalizations.of(context)!;

    // Only pending images queued
    if (_existingImageUrls.isEmpty && _selectedImages.isNotEmpty) {
      final confirmed = await showPhotoConfirmDialog(context,
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.red,
        title: l10n.removeAllSelectedImages,
        content: l10n.removeAllSelectedImagesConfirm,
        confirmLabel: l10n.removeAll,
        isDestructive: true,
      );
      if (confirmed != true) return;
      if (!mounted) return;
      setState(() => _selectedImages.clear());
      showProfileSnackBar(context, message: l10n.selectedImagesCleared);
      return;
    }

    // One existing + some pending — clear pending only
    if (_existingImageUrls.length == 1 && _selectedImages.isNotEmpty) {
      final confirmed = await showPhotoConfirmDialog(context,
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.red,
        title: l10n.removeAllSelectedImages,
        content:
            '${l10n.removeAllSelectedImagesConfirm}\n\n${l10n.yourProfilePictureWillBeKept}',
        confirmLabel: l10n.removeAll,
        isDestructive: true,
      );
      if (confirmed != true) return;
      if (!mounted) return;
      setState(() => _selectedImages.clear());
      showProfileSnackBar(context, message: l10n.selectedImagesCleared);
      return;
    }

    // Only one existing and no pending — can't delete
    if (_existingImageUrls.length == 1 && _selectedImages.isEmpty) {
      showProfileSnackBar(
        context,
        message: l10n.mustKeepAtLeastOneProfilePicture,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    if (_existingImageUrls.isEmpty && _selectedImages.isEmpty) {
      showProfileSnackBar(
        context,
        message: l10n.noProfilePicturesToRemove,
        type: ProfileSnackBarType.error,
      );
      return;
    }

    final confirmed = await showPhotoConfirmDialog(context,
      icon: Icons.delete_sweep_rounded,
      iconColor: Colors.red,
      title: l10n.removeAllImages,
      content: l10n.removeAllImagesConfirm,
      confirmLabel: l10n.removeAll,
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isRemoving = true);

    final handler = PhotoUploadHandler(userId: widget.user.id);
    final result = await handler.deleteAllExtras(
      existingCount: _existingImageUrls.length,
      noTokenMessage: l10n.authenticationTokenNotFound,
      failedMessage: l10n.failedToUpdate,
      successMessage: l10n.extraImagesRemovedSuccessfully,
    );

    if (!mounted) return;
    setState(() {
      if (result.success) {
        _existingImageUrls =
            result.imageUrls!.isNotEmpty ? result.imageUrls! : _existingImageUrls.take(1).toList();
        _selectedImages.clear();
      }
      _isRemoving = false;
    });

    if (result.success) {
      ref.invalidate(userProvider);
      showProfileSnackBar(context, message: result.message);
    } else {
      showProfileSnackBar(
        context,
        message: result.message,
        type: ProfileSnackBarType.error,
      );
    }
  }

  Future<void> _handleDone() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedImages.isNotEmpty) {
      final shouldSave = await showPhotoConfirmDialog(context,
        icon: Icons.cloud_upload_outlined,
        iconColor: AppColors.primary,
        title: l10n.saveChangesQuestion,
        content: l10n.youHaveUnuploadedImages(_selectedImages.length),
        confirmLabel: l10n.upload,
      );
      if (shouldSave == true) {
        await _uploadProfilePictures();
      }
    }

    if (mounted) Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allImages = _existingImageUrls.length + _selectedImages.length;
    final canAddMore = allImages < maxImages;
    final progress = allImages / maxImages;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          l10n.profilePictures,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isUploading || _isRemoving ? null : _handleDone,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                l10n.done,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeController,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildProgressCard(l10n, allImages, progress),
                  ),
                ),
                if (_existingImageUrls.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildSectionTitle(
                        l10n.currentImages,
                        Icons.photo_camera_rounded,
                        AppColors.primary,
                        '${_existingImageUrls.length}',
                      ),
                    ),
                  ),
                if (_existingImageUrls.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => PhotoGridTile.existing(
                          url: _existingImageUrls[index],
                          index: index,
                          showDeleteButton: _existingImageUrls.length > 1,
                          onDelete: () => _removeExistingImage(index),
                          profileLabel: l10n.profile,
                        ),
                        childCount: _existingImageUrls.length,
                      ),
                    ),
                  ),
                if (_selectedImages.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildSectionTitle(
                        l10n.newImages,
                        Icons.add_photo_alternate_rounded,
                        const Color(0xFF7C4DFF),
                        '${_selectedImages.length}',
                      ),
                    ),
                  ),
                if (_selectedImages.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => PhotoGridTile.pending(
                          file: _selectedImages[index],
                          index: index,
                          onDelete: () => _removeSelectedImage(index),
                        ),
                        childCount: _selectedImages.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      children: [
                        if (canAddMore) _buildAddButton(l10n, allImages),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildUploadButton(l10n),
                        ],
                        if ((_existingImageUrls.length > 1 ||
                                _selectedImages.isNotEmpty) &&
                            !(_existingImageUrls.length == 1 &&
                                _selectedImages.isEmpty)) ...[
                          const SizedBox(height: 12),
                          _buildRemoveAllButton(l10n),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading || _isRemoving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout helpers (screen-level only)
  // ---------------------------------------------------------------------------

  Widget _buildProgressCard(
    AppLocalizations l10n,
    int allImages,
    double progress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.collections_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$allImages / $maxImages',
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      l10n.maxImagesInfo(maxImages, allImages),
                      style: context.captionSmall.copyWith(
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withValues(
                    alpha: isDark ? 0.18 : 0.15,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color,
    String count,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: context.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(AppLocalizations l10n, int allImages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploading || _isRemoving ? null : _openPhotoPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.4 : 0.3,
                ),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  allImages > 0 ? l10n.addMoreImages : l10n.addImages,
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading || _isRemoving ? null : _uploadProfilePictures,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: _isUploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    l10n.uploadImages(_selectedImages.length),
                    style: context.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRemoveAllButton(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _isUploading || _isRemoving
            ? null
            : _removeAllProfilePictures,
        icon: _isRemoving
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              )
            : const Icon(Icons.delete_outline_rounded, size: 20),
        label: Text(
          l10n.removeAll,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.red.withValues(alpha: isDark ? 0.4 : 0.25),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isUploading ? 'Uploading...' : 'Removing...',
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
