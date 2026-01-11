import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

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
  static const int maxImages = 10; // Backend supports max 10

  @override
  void initState() {
    super.initState();
    _existingImageUrls = List<String>.from(widget.user.imageUrls);
    print(_existingImageUrls.length);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

    if (pickedFiles != null) {
      final totalImages =
          _existingImageUrls.length +
          _selectedImages.length +
          pickedFiles.length;
      if (totalImages > maxImages) {
        final remaining =
            maxImages - (_existingImageUrls.length + _selectedImages.length);
        _showErrorSnackBar(
          'You can only add $remaining more image(s). Maximum is $maxImages images total.',
        );
        return;
      }

      // Limit to 5 images per upload batch (backend limit)
      final imagesToAdd = pickedFiles.take(5).toList();
      if (pickedFiles.length > 5) {
        _showErrorSnackBar(
          'You can upload maximum 5 images at once. Only first 5 will be added.',
        );
      }

      setState(() {
        _selectedImages.addAll(imagesToAdd.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final totalImages =
          _existingImageUrls.length + _selectedImages.length + 1;
      if (totalImages > maxImages) {
        _showErrorSnackBar('You can only have up to $maxImages images');
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
    // Prevent deletion if this is the last existing image
    if (_existingImageUrls.length == 1) {
      _showErrorSnackBar('You must keep at least one profile picture');
      return;
    }

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Image'),
          content: const Text('Are you sure you want to remove this image?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isRemoving = true;
      });

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
        _showErrorSnackBar('Authentication token not found');
        setState(() {
          _isRemoving = false;
        });
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

        // Refresh user data
        ref.refresh(userProvider);

        _showSuccessSnackBar(data['message'] ?? 'Image removed successfully');
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(errorData['error'] ?? 'Failed to remove image');
      }

      setState(() {
        _isRemoving = false;
      });
    } catch (e) {
      Navigator.pop(context);
      print('Error removing image: $e');
      _showErrorSnackBar('Failed to remove image');
      setState(() {
        _isRemoving = false;
      });
    }
  }

  Future<void> _uploadProfilePictures() async {
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please select at least one image to upload');
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

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
        _showErrorSnackBar('Authentication token not found');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final userId = widget.user.id;

      // Use the multiple photos endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Endpoints.baseURL}auth/users/$userId/photos'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Validate and add all image files
      for (var imageFile in _selectedImages) {
        final fileSize = await imageFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          Navigator.pop(context);
          _showErrorSnackBar(
            'Image size exceeds 10MB limit: ${imageFile.path.split('/').last}',
          );
          setState(() {
            _isUploading = false;
          });
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
            _showErrorSnackBar('Unsupported image format: $extension');
            setState(() {
              _isUploading = false;
            });
            return;
        }

        // IMPORTANT: Use 'photos' field name (not 'photo') for multiple upload
        request.files.add(
          await http.MultipartFile.fromPath(
            'photos', // Changed from 'photo' to 'photos'
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

        _showSuccessSnackBar(data['message'] ?? 'Images uploaded successfully');

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(errorData['error'] ?? 'Failed to upload images');
      }

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      Navigator.pop(context);
      print('Error uploading images: $e');
      _showErrorSnackBar('Failed to upload images');
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _removeAllProfilePictures() async {
    // If only selected images (not uploaded yet), just clear them (this is OK)
    if (_existingImageUrls.isEmpty && _selectedImages.isNotEmpty) {
      // Show confirmation dialog for selected images
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Remove All Selected Images'),
            content: const Text(
              'Are you sure you want to remove all selected images?',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      setState(() {
        _selectedImages.clear();
      });
      _showSuccessSnackBar('Selected images cleared');
      return;
    }

    // If there's only one existing image, only allow removing selected images
    if (_existingImageUrls.length == 1 && _selectedImages.isNotEmpty) {
      // Show confirmation dialog for selected images only
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Remove All Selected Images'),
            content: const Text(
              'Are you sure you want to remove all selected images? (Your existing profile picture will be kept)',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      setState(() {
        _selectedImages.clear();
      });
      _showSuccessSnackBar('Selected images cleared');
      return;
    }

    // Prevent removing all if there's only one existing image and no selected images
    if (_existingImageUrls.length == 1 && _selectedImages.isEmpty) {
      _showErrorSnackBar('You must keep at least one profile picture');
      return;
    }

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove All Images'),
          content: const Text(
            'Are you sure you want to remove all profile pictures?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Remove All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      if (_existingImageUrls.isEmpty && _selectedImages.isEmpty) {
        _showErrorSnackBar('No profile pictures to remove');
        return;
      }

      setState(() {
        _isRemoving = true;
      });

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
        _showErrorSnackBar('Authentication token not found');
        setState(() {
          _isRemoving = false;
        });
        return;
      }

      final userId = widget.user.id;

      // Remove all images one by one (backend doesn't have bulk delete)
      // Keep the first image (index 0) - remove from the end
      for (int i = _existingImageUrls.length - 1; i >= 1; i--) {
        await http.delete(
          Uri.parse('${Endpoints.baseURL}auth/users/$userId/photo/$i'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      Navigator.pop(context);

      // Get updated images list from backend
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
            // Fallback: keep only the first image
            _existingImageUrls = _existingImageUrls.take(1).toList();
          }
          _selectedImages.clear();
        });
      } else {
        // Fallback: keep only the first image
        setState(() {
          _existingImageUrls = _existingImageUrls.take(1).toList();
          _selectedImages.clear();
        });
      }

      ref.refresh(userProvider);

      _showSuccessSnackBar('Extra images removed successfully');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });

      setState(() {
        _isRemoving = false;
      });
    } catch (e) {
      Navigator.pop(context);
      print('Error removing images: $e');
      _showErrorSnackBar('Failed to remove images');
      setState(() {
        _isRemoving = false;
      });
    }
  }

  Future<void> _handleDone() async {
    // If there are selected images that haven't been uploaded, ask user
    if (_selectedImages.isNotEmpty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Save Changes?'),
            content: Text(
              'You have ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''} selected but not uploaded. Do you want to upload them now?',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Upload',
                  style: TextStyle(color: Color(0xFF00BFA5)),
                ),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        // Upload the images
        await _uploadProfilePictures();
        // Don't navigate back here - let _uploadProfilePictures handle navigation
        return;
      } else {
        // User chose to discard, just navigate back
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
    }

    // No pending changes, just navigate back
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Add Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF00BFA5),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select up to 5 images'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00BFA5)),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              const SizedBox(height: 8),
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
        backgroundColor: Colors.green,
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allImages = _existingImageUrls.length + _selectedImages.length;
    final canAddMore = allImages < maxImages;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile Pictures',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading || _isRemoving ? null : () => _handleDone(),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF00BFA5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can upload up to $maxImages images. Currently: $allImages/$maxImages\nMax 5 images per upload.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Existing Images Grid
              if (_existingImageUrls.isNotEmpty) ...[
                const Text(
                  'Current Images',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
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
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ImageUtils.normalizeImageUrl(
                              _existingImageUrls[index],
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        // Only show delete button if there's more than one image
                        if (_existingImageUrls.length > 1)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BFA5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Profile',
                                style: TextStyle(
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
                const SizedBox(height: 24),
              ],
              // New Selected Images Grid
              if (_selectedImages.isNotEmpty) ...[
                const Text(
                  'New Images',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
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
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                          ),
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
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              // Add Image Button
              if (canAddMore)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading || _isRemoving
                        ? null
                        : () => _showImageSourceDialog(),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(
                      'Add ${allImages > 0 ? 'More ' : ''}Images',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00BFA5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFF00BFA5)),
                    ),
                  ),
                ),
              // Upload Button
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading || _isRemoving
                        ? null
                        : () => _uploadProfilePictures(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Upload ${_selectedImages.length} Image${_selectedImages.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
              // Remove All Button - only show if there's more than 1 existing image or selected images
              if ((_existingImageUrls.length > 1 || _selectedImages.isNotEmpty) &&
                  !(_existingImageUrls.length == 1 && _selectedImages.isEmpty)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading || _isRemoving
                        ? null
                        : () => _removeAllProfilePictures(),
                    icon: _isRemoving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                            ),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text(
                      'Remove All',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
