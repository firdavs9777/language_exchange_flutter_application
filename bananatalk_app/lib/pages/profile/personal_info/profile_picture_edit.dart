import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class ProfilePictureEdit extends ConsumerStatefulWidget {
  final Community user;

  const ProfilePictureEdit({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<ProfilePictureEdit> createState() => _ProfilePictureEditState();
}

class _ProfilePictureEditState extends ConsumerState<ProfilePictureEdit> {
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isUploading = false;
  bool _isRemoving = false;
  static const int maxImages = 10;

  @override
  void initState() {
    super.initState();
    _existingImageUrls = List<String>.from(widget.user.imageUrls);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

    if (pickedFiles != null) {
      final totalImages =
          _existingImageUrls.length + _selectedImages.length + pickedFiles.length;
      if (totalImages > maxImages) {
        final remaining = maxImages - (_existingImageUrls.length + _selectedImages.length);
        _showErrorSnackBar(l10n.canOnlyAddMoreImages(remaining, maxImages));
        return;
      }

      final imagesToAdd = pickedFiles.take(5).toList();
      if (pickedFiles.length > 5) {
        _showErrorSnackBar(l10n.maxImagesPerUpload);
      }

      setState(() {
        _selectedImages.addAll(imagesToAdd.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final totalImages = _existingImageUrls.length + _selectedImages.length + 1;
      if (totalImages > maxImages) {
        _showErrorSnackBar(l10n.canOnlyHaveMaxImages(maxImages));
        return;
      }

      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _removeExistingImage(int index) async {
    final l10n = AppLocalizations.of(context)!;

    if (_existingImageUrls.length == 1) {
      _showErrorSnackBar(l10n.mustKeepAtLeastOneProfilePicture);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.removeImage),
          content: Text(l10n.removeImageConfirm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel, style: TextStyle(color: context.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.remove, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _isRemoving = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
            ),
          );
        },
      );

      final token = await _getToken();
      if (token == null) {
        Navigator.pop(context);
        _showErrorSnackBar(l10n.authenticationTokenNotFound);
        setState(() => _isRemoving = false);
        return;
      }

      final userId = widget.user.id;
      final response = await http.delete(
        Uri.parse('${Endpoints.baseURL}auth/users/$userId/photo/$index'),
        headers: {'Authorization': 'Bearer $token'},
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['images'] != null) {
            _existingImageUrls = List<String>.from(data['images']);
          } else {
            _existingImageUrls.removeAt(index);
          }
        });
        ref.refresh(userProvider);
        _showSuccessSnackBar(data['message'] ?? l10n.imageRemovedSuccessfully);
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(errorData['error'] ?? l10n.failedToUpdate);
      }

      setState(() => _isRemoving = false);
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(l10n.failedToUpdate);
      setState(() => _isRemoving = false);
    }
  }

  Future<void> _uploadProfilePictures() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedImages.isEmpty) {
      _showErrorSnackBar(l10n.pleaseSelectAtLeastOneImage);
      return;
    }

    try {
      setState(() => _isUploading = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
            ),
          );
        },
      );

      final token = await _getToken();
      if (token == null) {
        Navigator.pop(context);
        _showErrorSnackBar(l10n.authenticationTokenNotFound);
        setState(() => _isUploading = false);
        return;
      }

      final userId = widget.user.id;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Endpoints.baseURL}auth/users/$userId/photos'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      for (var imageFile in _selectedImages) {
        final fileSize = await imageFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          Navigator.pop(context);
          _showErrorSnackBar(l10n.imageSizeExceedsLimit);
          setState(() => _isUploading = false);
          return;
        }

        final extension = imageFile.path.split('.').last.toLowerCase();
        String? mimeType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            Navigator.pop(context);
            _showErrorSnackBar('${l10n.unsupportedImageFormat}: $extension');
            setState(() => _isUploading = false);
            return;
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'photos',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          if (data['images'] != null) {
            _existingImageUrls = List<String>.from(data['images']);
          }
          _selectedImages.clear();
        });

        ref.refresh(userProvider);
        _showSuccessSnackBar(data['message'] ?? l10n.imagesUploadedSuccessfully);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(errorData['error'] ?? l10n.failedToUpdate);
      }

      setState(() => _isUploading = false);
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(l10n.failedToUpdate);
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removeAllProfilePictures() async {
    final l10n = AppLocalizations.of(context)!;

    if (_existingImageUrls.isEmpty && _selectedImages.isNotEmpty) {
      final confirmed = await _showRemoveConfirmDialog(
        l10n.removeAllSelectedImages,
        l10n.removeAllSelectedImagesConfirm,
      );
      if (confirmed != true) return;

      setState(() => _selectedImages.clear());
      _showSuccessSnackBar(l10n.selectedImagesCleared);
      return;
    }

    if (_existingImageUrls.length == 1 && _selectedImages.isNotEmpty) {
      final confirmed = await _showRemoveConfirmDialog(
        l10n.removeAllSelectedImages,
        '${l10n.removeAllSelectedImagesConfirm} (${l10n.yourProfilePictureWillBeKept})',
      );
      if (confirmed != true) return;

      setState(() => _selectedImages.clear());
      _showSuccessSnackBar(l10n.selectedImagesCleared);
      return;
    }

    if (_existingImageUrls.length == 1 && _selectedImages.isEmpty) {
      _showErrorSnackBar(l10n.mustKeepAtLeastOneProfilePicture);
      return;
    }

    final confirmed = await _showRemoveConfirmDialog(
      l10n.removeAllImages,
      l10n.removeAllImagesConfirm,
    );
    if (confirmed != true) return;

    try {
      if (_existingImageUrls.isEmpty && _selectedImages.isEmpty) {
        _showErrorSnackBar(l10n.noProfilePicturesToRemove);
        return;
      }

      setState(() => _isRemoving = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
            ),
          );
        },
      );

      final token = await _getToken();
      if (token == null) {
        Navigator.pop(context);
        _showErrorSnackBar(l10n.authenticationTokenNotFound);
        setState(() => _isRemoving = false);
        return;
      }

      final userId = widget.user.id;

      for (int i = _existingImageUrls.length - 1; i >= 1; i--) {
        await http.delete(
          Uri.parse('${Endpoints.baseURL}auth/users/$userId/photo/$i'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      Navigator.pop(context);

      final getUserResponse = await http.get(
        Uri.parse('${Endpoints.baseURL}auth/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getUserResponse.statusCode == 200) {
        final userData = json.decode(getUserResponse.body);
        setState(() {
          if (userData['images'] != null) {
            _existingImageUrls = List<String>.from(userData['images']);
          } else {
            _existingImageUrls = _existingImageUrls.take(1).toList();
          }
          _selectedImages.clear();
        });
      } else {
        setState(() {
          _existingImageUrls = _existingImageUrls.take(1).toList();
          _selectedImages.clear();
        });
      }

      ref.refresh(userProvider);
      _showSuccessSnackBar(l10n.extraImagesRemovedSuccessfully);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });

      setState(() => _isRemoving = false);
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(l10n.failedToUpdate);
      setState(() => _isRemoving = false);
    }
  }

  Future<bool?> _showRemoveConfirmDialog(String title, String content) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel, style: TextStyle(color: context.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.removeAll, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDone() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedImages.isNotEmpty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.saveChangesQuestion),
            content: Text(l10n.youHaveUnuploadedImages(_selectedImages.length)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.discard, style: TextStyle(color: context.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.upload, style: const TextStyle(color: Color(0xFF00BFA5))),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        await _uploadProfilePictures();
        return;
      } else {
        if (mounted) Navigator.pop(context);
        return;
      }
    }

    if (mounted) Navigator.pop(context);
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spacing.gapLG,
              Text(
                l10n.addImages,
                style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Spacing.gapSM,
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(l10n.chooseFromGallery),
                subtitle: Text(l10n.selectUpToImages),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(l10n.takeAPhoto),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              Spacing.gapSM,
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allImages = _existingImageUrls.length + _selectedImages.length;
    final canAddMore = allImages < maxImages;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.profilePictures, style: context.titleLarge),
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading || _isRemoving ? null : () => _handleDone(),
            child: Text(
              l10n.done,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Spacing.hGapSM,
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: Spacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: Spacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    Spacing.hGapSM,
                    Expanded(
                      child: Text(
                        l10n.maxImagesInfo(maxImages, allImages),
                        style: context.caption.copyWith(color: context.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Spacing.gapXL,

              if (_existingImageUrls.isNotEmpty) ...[
                Text(
                  l10n.currentImages,
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Spacing.gapMD,
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _existingImageUrls.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.borderMD,
                          child: CachedImageWidget(
                            imageUrl: _existingImageUrls[index],
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: context.containerColor,
                              child: Icon(Icons.broken_image, color: context.iconColor),
                            ),
                          ),
                        ),
                        if (_existingImageUrls.length > 1)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _removeExistingImage(index);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.profile,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                Spacing.gapXL,
              ],

              if (_selectedImages.isNotEmpty) ...[
                Text(
                  l10n.newImages,
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Spacing.gapMD,
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.borderMD,
                          child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeSelectedImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Spacing.gapXL,
              ],

              if (canAddMore)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading || _isRemoving ? null : () => _showImageSourceDialog(),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(
                      allImages > 0 ? l10n.addMoreImages : l10n.addImages,
                      style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: Spacing.paddingLG,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

              if (_selectedImages.isNotEmpty) ...[
                Spacing.gapMD,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading || _isRemoving ? null : () => _uploadProfilePictures(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: Spacing.paddingLG,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
                      elevation: 2,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.uploadImages(_selectedImages.length),
                            style: context.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],

              if ((_existingImageUrls.length > 1 || _selectedImages.isNotEmpty) &&
                  !(_existingImageUrls.length == 1 && _selectedImages.isEmpty)) ...[
                Spacing.gapMD,
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading || _isRemoving ? null : () => _removeAllProfilePictures(),
                    icon: _isRemoving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(
                      l10n.removeAll,
                      style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: Spacing.paddingLG,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
