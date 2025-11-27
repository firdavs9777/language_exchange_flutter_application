import 'dart:io';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
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
  late TextEditingController titleController;
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
    titleController = TextEditingController(text: widget.moment.title);
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
    titleController.dispose();
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
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
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
        title: titleController.text.trim(),
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
                backgroundColor: Colors.orange,
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
            backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Moment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: descriptionController,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Images Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_isUploadingImages)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (imageUrls.isEmpty && _selectedImages.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No images yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.add_photo_alternate, size: 20),
                                label: const Text('Add Images'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFA5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ImageUtils.normalizeImageUrl(url),
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
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(url),
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
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
                          } else if (index < imageUrls.length + _selectedImages.length) {
                            final file = _selectedImages[index - imageUrls.length];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                          } else {
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate,
                                  size: 32,
                                  color: Color(0xFF00BFA5),
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
    );
  }
}
