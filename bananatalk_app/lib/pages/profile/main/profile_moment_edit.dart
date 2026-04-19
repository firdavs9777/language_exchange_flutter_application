import 'dart:io';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
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
  final List<File> _selectedImages = [];
  bool _isSaving = false;
  bool _isUploadingImages = false;

  late List<String> imageUrls;
  late List<String> originalImages; // Store original image filenames
  late Map<String, String> _urlToFilenameMap; // Map URL to filename

  @override
  void initState() {
    super.initState();
    descriptionController =
        TextEditingController(text: widget.moment.description);
    imageUrls = List<String>.from(widget.moment.imageUrls);
    originalImages = List<String>.from(widget.moment.images);

    // Create map of URL to filename (they should be in same order)
    _urlToFilenameMap = {};
    for (int i = 0; i < imageUrls.length && i < originalImages.length; i++) {
      _urlToFilenameMap[imageUrls[i]] = originalImages[i];
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _selectedImages
            .addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)));
      });
    }
  }

  /// Extract filename from URL
  /// Handles both full URLs and relative paths
  String _extractFilenameFromUrl(String url) {
    try {
      // Handle URL-encoded paths (e.g., Google images)
      String decodedUrl = url;
      if (url.contains('%')) {
        decodedUrl = Uri.decodeComponent(url);
      }

      // Parse URI
      final uri = Uri.parse(decodedUrl);
      String path = uri.path;

      // Extract filename from path
      String filename = path.split('/').last;

      // If path contains 'uploads/', extract everything after it
      if (path.contains('uploads/')) {
        final uploadsIndex = path.indexOf('uploads/');
        filename = path.substring(uploadsIndex + 8); // 8 = length of "uploads/"
      }

      // Remove query parameters if any
      filename = filename.split('?').first;

      return filename;
    } catch (e) {
      // Fallback: extract from URL string directly
      final parts = url.split('/');
      return parts.last.split('?').first;
    }
  }

  /// Get updated images list (filenames only) based on remaining imageUrls
  List<String> _getUpdatedImagesList() {
    // Build list of remaining filenames using the map
    final remainingFilenames = <String>[];

    for (final url in imageUrls) {
      // Get filename from map, or extract from URL as fallback
      final filename = _urlToFilenameMap[url] ?? _extractFilenameFromUrl(url);
      if (filename.isNotEmpty && !remainingFilenames.contains(filename)) {
        remainingFilenames.add(filename);
      }
    }

    return remainingFilenames;
  }

  Future<void> _saveChanges() async {
    // Validate inputs
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a description'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Get updated images list (filenames only) - excludes removed images
      final updatedImages = _getUpdatedImagesList();

      // Update moment with text content and updated images list
      final updatedMoment = await ref.read(momentsServiceProvider).updateMoment(
        id: widget.moment.id,
        description: descriptionController.text.trim(),
        category: widget.moment.category,
        mood: widget.moment.mood,
        tags: widget.moment.tags,
        images: updatedImages, // Send updated images array
      );

      // Upload new images if any
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });

        try {
          await ref
              .read(momentsServiceProvider)
              .uploadMomentPhotos(widget.moment.id, _selectedImages);
        } catch (e) {
          // Even if image upload fails, return the updated moment
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Moment updated but image upload failed: ${e.toString()}'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isUploadingImages = false;
            });
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, updatedMoment);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(String url) {
    setState(() {
      imageUrls.remove(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Moment',
          style: context.titleLarge,
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: Spacing.paddingLG,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: Text(
                'Save',
                style: context.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: Spacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description Field
              Container(
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: AppRadius.borderMD,
                  boxShadow: AppShadows.sm,
                ),
                child: TextField(
                  controller: descriptionController,
                  maxLines: 6,
                  style: context.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMD,
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: context.cardBackground,
                    contentPadding: Spacing.paddingLG,
                  ),
                ),
              ),
              Spacing.gapXXL,

              // Images Section
              Container(
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: AppRadius.borderMD,
                  boxShadow: AppShadows.sm,
                ),
                padding: Spacing.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Images',
                          style: context.titleLarge,
                        ),
                        const Spacer(),
                        if (_isUploadingImages)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    Spacing.gapMD,
                    if (imageUrls.isEmpty && _selectedImages.isEmpty)
                      Center(
                        child: Padding(
                          padding: Spacing.paddingXXL,
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 48, color: context.textHint),
                              Spacing.gapMD,
                              Text(
                                'No images yet',
                                style: context.bodyMedium.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                              Spacing.gapLG,
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.add_photo_alternate, size: 20),
                                label: const Text('Add Images'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderSM,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1,
                        ),
                        itemCount: imageUrls.length + _selectedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index < imageUrls.length) {
                            final url = imageUrls[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: AppRadius.borderSM,
                                  child: Image.network(
                                    ImageUtils.normalizeImageUrl(url),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: context.containerColor,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: context.textMuted,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(url),
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else if (index < imageUrls.length + _selectedImages.length) {
                            final file = _selectedImages[index - imageUrls.length];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: AppRadius.borderSM,
                                  child: Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedImages.remove(file);
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.containerColor,
                                  borderRadius: AppRadius.borderSM,
                                  border: Border.all(
                                    color: context.dividerColor,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
