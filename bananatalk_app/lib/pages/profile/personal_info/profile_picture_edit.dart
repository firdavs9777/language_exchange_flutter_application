import 'dart:io';
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

    if (pickedFiles.isNotEmpty) {
      final totalImages =
          _existingImageUrls.length +
          _selectedImages.length +
          pickedFiles.length;
      if (totalImages > maxImages) {
        final remaining =
            maxImages - (_existingImageUrls.length + _selectedImages.length);
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
      final totalImages =
          _existingImageUrls.length + _selectedImages.length + 1;
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
    HapticFeedback.lightImpact();
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

    final confirmed = await _showConfirmDialog(
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.red,
      title: l10n.removeImage,
      content: l10n.removeImageConfirm,
      confirmLabel: l10n.remove,
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      setState(() => _isRemoving = true);

      final token = await _getToken();
      if (token == null) {
        _showErrorSnackBar(l10n.authenticationTokenNotFound);
        setState(() => _isRemoving = false);
        return;
      }

      final userId = widget.user.id;
      final response = await http.delete(
        Uri.parse('${Endpoints.baseURL}auth/users/$userId/photo/$index'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['images'] != null) {
            _existingImageUrls = List<String>.from(data['images']);
          } else {
            _existingImageUrls.removeAt(index);
          }
          _isRemoving = false;
        });
        ref.invalidate(userProvider);
        _showSuccessSnackBar(data['message'] ?? l10n.imageRemovedSuccessfully);
      } else {
        final errorData = json.decode(response.body);
        setState(() => _isRemoving = false);
        _showErrorSnackBar(errorData['error'] ?? l10n.failedToUpdate);
      }
    } catch (e) {
      setState(() => _isRemoving = false);
      _showErrorSnackBar(l10n.failedToUpdate);
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

      final token = await _getToken();
      if (token == null) {
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['images'] != null) {
            _existingImageUrls = List<String>.from(data['images']);
          }
          _selectedImages.clear();
          _isUploading = false;
        });
        ref.invalidate(userProvider);
        _showSuccessSnackBar(
          data['message'] ?? l10n.imagesUploadedSuccessfully,
        );
      } else {
        final errorData = json.decode(response.body);
        setState(() => _isUploading = false);
        _showErrorSnackBar(errorData['error'] ?? l10n.failedToUpdate);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showErrorSnackBar(l10n.failedToUpdate);
    }
  }

  Future<void> _removeAllProfilePictures() async {
    final l10n = AppLocalizations.of(context)!;

    if (_existingImageUrls.isEmpty && _selectedImages.isNotEmpty) {
      final confirmed = await _showConfirmDialog(
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.red,
        title: l10n.removeAllSelectedImages,
        content: l10n.removeAllSelectedImagesConfirm,
        confirmLabel: l10n.removeAll,
        isDestructive: true,
      );
      if (confirmed != true) return;

      setState(() => _selectedImages.clear());
      _showSuccessSnackBar(l10n.selectedImagesCleared);
      return;
    }

    if (_existingImageUrls.length == 1 && _selectedImages.isNotEmpty) {
      final confirmed = await _showConfirmDialog(
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.red,
        title: l10n.removeAllSelectedImages,
        content:
            '${l10n.removeAllSelectedImagesConfirm}\n\n${l10n.yourProfilePictureWillBeKept}',
        confirmLabel: l10n.removeAll,
        isDestructive: true,
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

    final confirmed = await _showConfirmDialog(
      icon: Icons.delete_sweep_rounded,
      iconColor: Colors.red,
      title: l10n.removeAllImages,
      content: l10n.removeAllImagesConfirm,
      confirmLabel: l10n.removeAll,
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      if (_existingImageUrls.isEmpty && _selectedImages.isEmpty) {
        _showErrorSnackBar(l10n.noProfilePicturesToRemove);
        return;
      }

      setState(() => _isRemoving = true);

      final token = await _getToken();
      if (token == null) {
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
          _isRemoving = false;
        });
      } else {
        setState(() {
          _existingImageUrls = _existingImageUrls.take(1).toList();
          _selectedImages.clear();
          _isRemoving = false;
        });
      }

      ref.invalidate(userProvider);
      _showSuccessSnackBar(l10n.extraImagesRemovedSuccessfully);
    } catch (e) {
      setState(() => _isRemoving = false);
      _showErrorSnackBar(l10n.failedToUpdate);
    }
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: context.surfaceColor,
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
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: context.bodySmall.copyWith(
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: context.containerColor,
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isDestructive
                              ? Colors.red
                              : AppColors.primary,
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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

  Future<void> _handleDone() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedImages.isNotEmpty) {
      final shouldSave = await _showConfirmDialog(
        icon: Icons.cloud_upload_outlined,
        iconColor: AppColors.primary,
        title: l10n.saveChangesQuestion,
        content: l10n.youHaveUnuploadedImages(_selectedImages.length),
        confirmLabel: l10n.upload,
      );

      if (shouldSave == true) {
        await _uploadProfilePictures();
        if (mounted) Navigator.pop(context);
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSourceOption(
                          icon: Icons.photo_library_rounded,
                          label: l10n.chooseFromGallery,
                          subtitle: l10n.selectUpToImages,
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            _pickImages();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSourceOption(
                          icon: Icons.camera_alt_rounded,
                          label: l10n.takeAPhoto,
                          subtitle: '',
                          color: const Color(0xFF7C4DFF),
                          onTap: () {
                            Navigator.pop(context);
                            _takePhoto();
                          },
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
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
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

  void _showSuccessSnackBar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
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
                        (context, index) =>
                            _buildExistingImageTile(index, l10n),
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
                        (context, index) => _buildSelectedImageTile(index),
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

  Widget _buildExistingImageTile(int index, AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedImageWidget(
              imageUrl: _existingImageUrls[index],
              fit: BoxFit.cover,
              errorWidget: Container(
                color: context.containerColor,
                child: Icon(
                  Icons.broken_image_rounded,
                  color: context.iconColor,
                ),
              ),
            ),
          ),
          if (index == 0)
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
          if (_existingImageUrls.length > 1)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _removeExistingImage(index);
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
          if (index == 0)
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
                      l10n.profile,
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
        ],
      ),
    );
  }

  Widget _buildSelectedImageTile(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_selectedImages[index], fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeSelectedImage(index),
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

  Widget _buildAddButton(AppLocalizations l10n, int allImages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploading || _isRemoving ? null : _showImageSourceDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.3),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
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
