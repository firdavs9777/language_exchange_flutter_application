import 'dart:io';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditMomentScreen extends ConsumerStatefulWidget {
  final Moments moment;
  const EditMomentScreen({Key? key, required this.moment}) : super(key: key);
  @override
  _EditMomentScreenState createState() => _EditMomentScreenState();
}

class _EditMomentScreenState extends ConsumerState<EditMomentScreen> {
  late TextEditingController descriptionController;
  late FocusNode _descriptionFocus;
  final List<File> _selectedImages = [];
  bool _isSaving = false;
  bool _isUploadingImages = false;
  bool _isFocused = false;

  late List<String> imageUrls;
  late List<String> originalImages;
  late List<String> _initialImageUrls;
  late String _initialDescription;
  late Map<String, String> _urlToFilenameMap;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController(
      text: widget.moment.description,
    );
    _initialDescription = widget.moment.description;
    imageUrls = List<String>.from(widget.moment.imageUrls);
    _initialImageUrls = List<String>.from(widget.moment.imageUrls);
    originalImages = List<String>.from(widget.moment.images);

    _urlToFilenameMap = {};
    for (int i = 0; i < imageUrls.length && i < originalImages.length; i++) {
      _urlToFilenameMap[imageUrls[i]] = originalImages[i];
    }

    _descriptionFocus = FocusNode();
    _descriptionFocus.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _descriptionFocus.hasFocus);
      }
    });

    descriptionController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (descriptionController.text.trim() != _initialDescription.trim()) {
      return true;
    }
    if (imageUrls.length != _initialImageUrls.length) return true;
    for (int i = 0; i < imageUrls.length; i++) {
      if (imageUrls[i] != _initialImageUrls[i]) return true;
    }
    if (_selectedImages.isNotEmpty) return true;
    return false;
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          pickedFiles.map((pickedFile) => File(pickedFile.path)),
        );
      });
    }
  }

  String _extractFilenameFromUrl(String url) {
    try {
      String decodedUrl = url;
      if (url.contains('%')) {
        decodedUrl = Uri.decodeComponent(url);
      }
      final uri = Uri.parse(decodedUrl);
      String path = uri.path;
      String filename = path.split('/').last;
      if (path.contains('uploads/')) {
        final uploadsIndex = path.indexOf('uploads/');
        filename = path.substring(uploadsIndex + 8);
      }
      filename = filename.split('?').first;
      return filename;
    } catch (e) {
      final parts = url.split('/');
      return parts.last.split('?').first;
    }
  }

  List<String> _getUpdatedImagesList() {
    final remainingFilenames = <String>[];
    for (final url in imageUrls) {
      final filename = _urlToFilenameMap[url] ?? _extractFilenameFromUrl(url);
      if (filename.isNotEmpty && !remainingFilenames.contains(filename)) {
        remainingFilenames.add(filename);
      }
    }
    return remainingFilenames;
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    if (descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar(l10n.momentEnterDescription);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      final updatedImages = _getUpdatedImagesList();

      final updatedMoment = await ref
          .read(momentsServiceProvider)
          .updateMoment(
            id: widget.moment.id,
            description: descriptionController.text.trim(),
            category: widget.moment.category,
            mood: widget.moment.mood,
            tags: widget.moment.tags,
            images: updatedImages,
          );

      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);

        try {
          await ref
              .read(momentsServiceProvider)
              .uploadMomentPhotos(widget.moment.id, _selectedImages);
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar(
              '${l10n.momentUpdatedImageFailed}: ${e.toString()}',
            );
          }
        } finally {
          if (mounted) setState(() => _isUploadingImages = false);
        }
      }

      if (mounted) {
        Navigator.pop(context, updatedMoment);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar(
          '${l10n.error}: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  void _removeImage(String url) {
    HapticFeedback.lightImpact();
    setState(() => imageUrls.remove(url));
  }

  void _removeSelectedImage(File file) {
    HapticFeedback.lightImpact();
    setState(() => _selectedImages.remove(file));
  }

  void _showErrorSnackBar(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSave =
        _hasChanges &&
        !_isSaving &&
        descriptionController.text.trim().isNotEmpty;
    final totalImages = imageUrls.length + _selectedImages.length;
    final hasImages = totalImages > 0;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.editMoment,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: canSave ? _saveChanges : null,
              style: TextButton.styleFrom(
                backgroundColor: canSave
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.save,
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description section
              _buildSectionTitle(
                l10n.momentDescriptionLabel,
                Icons.edit_note_rounded,
                AppColors.primary,
              ),
              const SizedBox(height: 10),
              _buildDescriptionField(l10n),

              const SizedBox(height: 24),

              // Images section
              _buildSectionTitle(
                l10n.momentImagesLabel,
                Icons.photo_library_rounded,
                const Color(0xFF7C4DFF),
                trailing: hasImages
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF7C4DFF,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalImages',
                          style: const TextStyle(
                            color: Color(0xFF7C4DFF),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : null,
                trailingLoading: _isUploadingImages,
              ),
              const SizedBox(height: 10),
              _buildImagesContainer(l10n, hasImages),

              if (_hasChanges) ...[
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: context.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'You have unsaved changes',
                        style: context.captionSmall.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ========== SECTION TITLE ==========
  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    Widget? trailing,
    bool trailingLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: context.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        if (trailingLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        else if (trailing != null)
          trailing,
      ],
    );
  }

  // ========== DESCRIPTION FIELD ==========
  Widget _buildDescriptionField(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = descriptionController.text.isNotEmpty;
    final charCount = descriptionController.text.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : context.dividerColor.withValues(alpha: 0.5)),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: descriptionController,
              focusNode: _descriptionFocus,
              maxLines: 8,
              minLines: 4,
              style: context.bodyMedium.copyWith(height: 1.5),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.momentDescriptionLabel,
                hintStyle: context.bodyMedium.copyWith(
                  color: context.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Bottom bar with char count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
            child: Row(
              children: [
                if (hasText)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      descriptionController.clear();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: context.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Clear',
                            style: context.captionSmall.copyWith(
                              color: context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '$charCount',
                  style: context.captionSmall.copyWith(
                    color: context.textMuted,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== IMAGES CONTAINER ==========
  Widget _buildImagesContainer(AppLocalizations l10n, bool hasImages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: hasImages
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: imageUrls.length + _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index < imageUrls.length) {
                  return _buildExistingImageTile(imageUrls[index], index);
                } else if (index < imageUrls.length + _selectedImages.length) {
                  final fileIndex = index - imageUrls.length;
                  return _buildSelectedImageTile(
                    _selectedImages[fileIndex],
                    fileIndex,
                  );
                } else {
                  return _buildAddTile();
                }
              },
            )
          : _buildEmptyImageState(l10n),
    );
  }

  // ========== EMPTY IMAGE STATE ==========
  Widget _buildEmptyImageState(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noImagesYet,
            style: context.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.addImages,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== EXISTING IMAGE TILE ==========
  Widget _buildExistingImageTile(String url, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: Duration(milliseconds: 200 + (index * 40).clamp(0, 240)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ImageUtils.normalizeImageUrl(url),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: context.containerColor,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: context.textMuted,
                  ),
                );
              },
            ),
          ),
          // Subtle gradient overlay for close button visibility
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _removeImage(url),
              child: Container(
                padding: const EdgeInsets.all(5),
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
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SELECTED IMAGE TILE (new image) ==========
  Widget _buildSelectedImageTile(File file, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: Duration(milliseconds: 200 + (index * 40).clamp(0, 240)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file, fit: BoxFit.cover),
          ),
          // "NEW" border ring
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
                ),
              ),
            ),
          ),
          // NEW badge
          Positioned(
            bottom: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _removeSelectedImage(file),
              child: Container(
                padding: const EdgeInsets.all(5),
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
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ADD TILE ==========
  Widget _buildAddTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add',
                style: context.captionSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
