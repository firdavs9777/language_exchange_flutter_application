import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/upload_manager_provider.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/utils/api_error_handler.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/pages/video_editor/video_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class CreateMoment extends ConsumerStatefulWidget {
  const CreateMoment({Key? key}) : super(key: key);

  @override
  _CreateMomentState createState() => _CreateMomentState();
}

class _CreateMomentState extends ConsumerState<CreateMoment> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final tagsController = TextEditingController();
  final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

  List<File> _selectedImages = [];
  File? _selectedVideo; // Video file for upload
  Position? _currentPosition;
  String? _formattedAddress;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double _uploadProgress = 0;

  // Video processing state
  bool _isProcessingVideo = false;
  double _videoCompressionProgress = 0;
  String _videoProcessingStatus = '';
  VideoProcessResult? _videoProcessResult;
  final VideoCompressionService _videoCompressionService = VideoCompressionService();

  // New fields matching web version
  String _selectedPrivacy = 'Public';
  String _selectedCategory = 'General';
  String _selectedLanguage = 'English';
  String? _selectedMood;
  List<String> _tags = [];
  DateTime? _scheduledDate;

  static const int maxImages = 10;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 2000;

  final List<String> _privacyOptions = ['Public', 'Friends', 'Private'];
  final List<String> _categories = [
    'General',
    'Language Learning',
    'Travel',
    'Music',
    'Food',
    'Culture',
    'Books',
    'Hobbies',
  ];

  // Category to backend format mapping (matching backend API)
  final Map<String, String> _categoryToBackend = {
    'General': 'general',
    'Language Learning': 'language-learning',
    'Travel': 'travel',
    'Music': 'music',
    'Food': 'food',
    'Culture': 'culture',
    'Books': 'books',
    'Hobbies': 'hobbies',
  };
  // Language display name to ISO 639-1 code mapping
  final Map<String, String> _languages = {
    'English': 'en',
    'Korean': 'ko',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Japanese': 'ja',
    'Chinese': 'zh',
    'Arabic': 'ar',
    'Portuguese': 'pt',
    'Russian': 'ru',
    'Italian': 'it',
    'Dutch': 'nl',
    'Hindi': 'hi',
    'Thai': 'th',
    'Vietnamese': 'vi',
  };
  // Moods matching backend API (happy, excited, grateful, motivated, relaxed, curious)
  final Map<String, String> _moods = {
    '😊': 'happy',
    '🥳': 'excited',
    '🙏': 'grateful',
    '💪': 'motivated',
    '😌': 'relaxed',
    '🤔': 'curious',
  };

  @override
  void initState() {
    super.initState();
    titleController.addListener(_updateButtonState);
    descriptionController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    titleController.removeListener(_updateButtonState);
    descriptionController.removeListener(_updateButtonState);
    titleController.dispose();
    descriptionController.dispose();
    tagsController.dispose();
    isButtonEnabled.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    isButtonEnabled.value = titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty;
  }

  void _addTag() {
    final tag = tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      // Enforce max 5 tags (backend limit)
      if (_tags.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 tags allowed'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _tags.add(tag);
        tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _selectScheduleDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00BFA5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF00BFA5),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= maxImages) {
      _showMaxImagesDialog();
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      final remainingSlots = maxImages - _selectedImages.length;
      final filesToAdd = pickedFiles
          .take(remainingSlots)
          .map((file) => File(file.path))
          .toList();

      if (pickedFiles.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Maximum $maxImages images allowed. Only $remainingSlots images added.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _selectedImages.addAll(filesToAdd);
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= maxImages) {
      _showMaxImagesDialog();
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  /// Pick video from gallery (max 10 minutes, max 1GB)
  /// Automatically compresses video like Instagram for faster uploads
  Future<void> _pickVideo() async {
    // Can't have both video and images
    if (_selectedImages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please remove images first to add a video'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10), // 10 minute limit
    );

    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);

      // Check file extension first
      final extension = pickedFile.path.split('.').last.toLowerCase();
      final allowedExtensions = ['mp4', 'mov', 'avi', 'webm', '3gp', 'm4v'];
      if (!allowedExtensions.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unsupported format. Use: ${allowedExtensions.join(", ").toUpperCase()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Show processing dialog and compress video
      await _processAndSetVideo(videoFile);
    }
  }

  /// Process video (compress if needed) and set it as selected
  /// Opens video editor for trimming and filters
  Future<void> _processAndSetVideo(File videoFile) async {
    // First, open the video editor for trimming and filters
    final editorResult = await Navigator.push<VideoEditorResult>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoEditorScreen(
          videoFile: videoFile,
          maxDurationSeconds: 600, // 10 minutes max
        ),
      ),
    );

    // User cancelled editing
    if (editorResult == null) {
      return;
    }

    // Use the edited video file
    final editedVideoFile = editorResult.videoFile;

    // Show processing dialog
    _showVideoProcessingDialog();

    setState(() {
      _isProcessingVideo = true;
      _videoCompressionProgress = 0;
      _videoProcessingStatus = 'Preparing video...';
    });

    try {
      // Process the video (validate and compress if needed)
      final result = await _videoCompressionService.processVideoForUpload(
        editedVideoFile,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _videoCompressionProgress = progress;
            });
          }
        },
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _videoProcessingStatus = status;
            });
          }
        },
      );

      // Close processing dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (result.success && result.processedFile != null) {
        setState(() {
          _selectedVideo = result.processedFile;
          _videoProcessResult = result;
          _isProcessingVideo = false;
        });

        // Show success message with compression info
        if (mounted && result.wasCompressed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video compressed: ${result.fileSizeMB}MB (saved ${result.compressionSavings.toStringAsFixed(0)}%)',
              ),
              backgroundColor: const Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _isProcessingVideo = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to process video'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close processing dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        _isProcessingVideo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing video: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Show video processing dialog with progress
  void _showVideoProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _videoCompressionProgress > 0
                            ? _videoCompressionProgress / 100
                            : null,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00BFA5),
                        ),
                      ),
                    ),
                    if (_videoCompressionProgress > 0)
                      Text(
                        '${_videoCompressionProgress.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BFA5),
                        ),
                      )
                    else
                      const Icon(
                        Icons.videocam,
                        size: 32,
                        color: Color(0xFF00BFA5),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _videoProcessingStatus.isNotEmpty
                      ? _videoProcessingStatus
                      : 'Processing video...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we optimize your video',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Record video with camera
  Future<void> _recordVideo() async {
    if (_selectedImages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please remove images first to record a video'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 10),
    );

    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);
      // Process and compress the recorded video
      await _processAndSetVideo(videoFile);
    }
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _videoProcessResult = null;
    });
    // Clean up video cache
    _videoCompressionService.deleteAllCache();
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showMaxImagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Maximum Images Reached',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'You can only upload up to $maxImages images per moment.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isGettingLocation = true;
    });

    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isGettingLocation = false);
      _showLocationServiceDisabledDialog();
      return;
    }

    // Use Geolocator's built-in permission handling (same as register_second.dart)
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isGettingLocation = false);
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isGettingLocation = false);
      _showPermissionPermanentlyDeniedDialog();
      return;
    }

    // Permission granted, get location
    await _getCurrentLocation();

    setState(() {
      _isGettingLocation = false;
    });
  }

  void _showPermissionRestrictedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Location Access Restricted',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Location access is restricted on this device. This may be due to parental controls or device policy.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Build formatted address
        final addressParts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        setState(() {
          _formattedAddress = addressParts.isNotEmpty 
              ? addressParts.join(', ')
              : "${place.locality ?? ''}, ${place.country ?? ''}";
        });
      } else {
        setState(() {
          _formattedAddress = "Location added";
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Location added'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearLocation() {
    setState(() {
      _currentPosition = null;
      _formattedAddress = null;
    });
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Location Services Disabled',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Please enable Location Services in your device settings to use this feature.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Location Permission Needed',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Bananatalk needs location permission to tag your moments with your current location.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Not Now', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission();
              },
              child: const Text(
                'Allow',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Location Permission Required',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Location permission has been permanently denied. Please enable it in app settings to tag your location in moments.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _moods.length,
                itemBuilder: (context, index) {
                  final emoji = _moods.keys.elementAt(index);
                  final mood = _moods[emoji]!;
                  final isSelected = _selectedMood == emoji;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMood = isSelected ? null : emoji;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00BFA5).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00BFA5)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(
                            mood[0].toUpperCase() + mood.substring(1),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Validate input before creating moment
  String? _validateInputs() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      return 'Title is required';
    }
    if (title.length > maxTitleLength) {
      return 'Title must be ${maxTitleLength} characters or less';
    }
    if (description.isEmpty) {
      return 'Description is required';
    }
    if (description.length > maxDescriptionLength) {
      return 'Description must be ${maxDescriptionLength} characters or less';
    }
    if (_tags.length > 5) {
      return 'Maximum 5 tags allowed';
    }
    if (_scheduledDate != null && _scheduledDate!.isBefore(DateTime.now())) {
      return 'Scheduled date must be in the future';
    }
    return null;
  }

  // Format location data for backend (GeoJSON format)
  Map<String, dynamic>? _formatLocationData() {
    if (_currentPosition == null) return null;

    try {
      // Get placemark for address details
      return {
        'coordinates': [
          _currentPosition!.longitude, // Note: [lng, lat] not [lat, lng]
          _currentPosition!.latitude,
        ],
        'formattedAddress': _formattedAddress ?? 'Location',
        // Additional fields can be added if needed from placemark
      };
    } catch (e) {
      print('Error formatting location: $e');
      return null;
    }
  }

  /// Show error dialog for video upload failures with retry option
  Future<bool> _showVideoUploadErrorDialog(String momentId, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Video Upload Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Try compressing your video or using a smaller file.',
                      style: TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip Video'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Retry Upload'),
          ),
        ],
      ),
    );

    if (result == true && _selectedVideo != null) {
      // Retry the upload
      try {
        await ref.read(momentsServiceProvider).uploadMomentVideo(
              momentId,
              _selectedVideo!,
            );
        return true;
      } catch (e) {
        // Show error again
        if (mounted) {
          return await _showVideoUploadErrorDialog(momentId, 'Upload failed again: ${e.toString().replaceFirst('Exception: ', '')}');
        }
      }
    }
    return false;
  }

  Future<void> _createMoment() async {
    if (_isLoading) return;

    // Validate inputs
    final validationError = _validateInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check limits before creating
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        final userAsync = ref.read(userProvider);
        final user = await userAsync;
        final limits = ref.read(currentUserLimitsProvider(userId));

        if (!FeatureGate.canCreateMoment(user, limits)) {
          await LimitExceededDialog.show(
            context: context,
            limitType: 'moments',
            limitInfo: limits?.moments,
            resetTime: limits?.resetTime,
            userId: userId,
          );
          return;
        }
      }
    } catch (e) {
      // If limit check fails, allow creating (fail open)
      print('Error checking limits: $e');
    }

    // For video moments, use background upload for Instagram-like experience
    if (_selectedVideo != null) {
      await _createMomentWithBackgroundUpload();
      return;
    }

    // For non-video moments, use the regular flow
    setState(() {
      _isLoading = true;
    });

    try {
      // Format location data if available
      final locationData = _formatLocationData();

      // Create moment with all fields (no userId - backend uses authenticated user)
      final moment = await ref.read(momentsServiceProvider).createMoments(
            title: titleController.text.trim(),
            description: descriptionController.text.trim(),
            privacy: _selectedPrivacy.toLowerCase(),
            category: _categoryToBackend[_selectedCategory] ?? 'general',
            language: _languages[_selectedLanguage] ?? 'en',
            mood: _selectedMood != null ? _moods[_selectedMood] : null,
            tags: _tags.isNotEmpty ? _tags : null,
            scheduledFor: _scheduledDate?.toIso8601String(),
            location: locationData,
          );

      // Upload images if any
      if (_selectedImages.isNotEmpty) {
        await ref.read(momentsServiceProvider).uploadMomentPhotos(
              moment.id,
              _selectedImages,
            );
      }

      // Refresh moments list
      ref.invalidate(momentsProvider(1));
      ref.invalidate(momentsFeedProvider);

      // Refresh limits after successful creation
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId != null) {
          ref.refresh(userLimitsProvider(userId));
        }
      } catch (e) {
        print('Error refreshing limits: $e');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moment created successfully'),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Handle 429 errors
        if (e.toString().contains('429') ||
            ApiErrorHandler.isLimitExceededError(e)) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('userId');
            await ApiErrorHandler.handleLimitExceededError(
              context: context,
              error: e,
              userId: userId,
            );
          } catch (err) {
            print('Error handling limit error: $err');
          }
        } else {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Create moment with background video upload (Instagram-like experience)
  Future<void> _createMomentWithBackgroundUpload() async {
    // Format location data if available
    final locationData = _formatLocationData();

    try {
      // Queue the upload for background processing
      await ref.read(uploadManagerProvider.notifier).queueMomentUpload(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        privacy: _selectedPrivacy.toLowerCase(),
        category: _categoryToBackend[_selectedCategory] ?? 'general',
        language: _languages[_selectedLanguage] ?? 'en',
        mood: _selectedMood != null ? _moods[_selectedMood] : null,
        tags: _tags.isNotEmpty ? _tags : null,
        location: locationData,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
        videoPath: _selectedVideo?.path,
      );

      // Navigate back immediately - upload continues in background
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading moment in background...'),
              ],
            ),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to queue upload: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Moment',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isButtonEnabled,
            builder: (context, isEnabled, child) {
              return TextButton(
                onPressed: isEnabled && !_isLoading ? _createMoment : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.post,
                        style: TextStyle(
                          color: isEnabled
                              ? const Color(0xFF00BFA5)
                              : Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Selector
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButton<String>(
                value: _selectedPrivacy,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: _privacyOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'Public'
                              ? Icons.public
                              : value == 'Friends'
                                  ? Icons.people
                                  : Icons.lock,
                          size: 20,
                          color: const Color(0xFF00BFA5),
                        ),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPrivacy = newValue;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Title Field with Counter
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
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    maxLength: maxTitleLength,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.addATitle,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${titleController.text.length}/$maxTitleLength',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Description Field with Counter
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
              child: Column(
                children: [
                  TextField(
                    controller: descriptionController,
                    maxLines: 8,
                    maxLength: maxDescriptionLength,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.whatsOnYourMind,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${descriptionController.text.length}/$maxDescriptionLength',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add to your moment section
            const Text(
              'Add to your moment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionIcon(
                  icon: Icons.image,
                  color: const Color(0xFF4CAF50),
                  onTap: _pickImages,
                ),
                _buildActionIcon(
                  icon: Icons.emoji_emotions,
                  color: const Color(0xFFFFC107),
                  onTap: _showMoodPicker,
                  badge: _selectedMood,
                ),
                _buildActionIcon(
                  icon: Icons.location_on,
                  color: const Color(0xFFF44336),
                  onTap: _requestLocationPermission,
                  isActive: _currentPosition != null,
                ),
                _buildActionIcon(
                  icon: Icons.tag,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildTagDialog(),
                    );
                  },
                  badge: _tags.isNotEmpty ? '${_tags.length}' : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Images Section
            if (_selectedImages.isNotEmpty) ...[
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
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _selectedImages.length < maxImages
                      ? _selectedImages.length + 1
                      : _selectedImages.length,
                  itemBuilder: (context, index) {
                    if (index < _selectedImages.length) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return InkWell(
                        onTap: _pickImages,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  size: 32, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                'Add More',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Video Preview Section
            if (_selectedVideo != null) ...[
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.videocam, color: Color(0xFF00BFA5), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Video Ready',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (_videoProcessResult != null) ...[
                                    Text(
                                      '${_videoProcessResult!.fileSizeMB}MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (_videoProcessResult!.duration != null) ...[
                                      Text(
                                        ' | ${_videoProcessResult!.durationFormatted}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    if (_videoProcessResult!.wasCompressed) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00BFA5).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Compressed',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: const Color(0xFF00BFA5),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ] else
                                    Text(
                                      'Ready to upload',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _removeVideo,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          // Duration badge
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _videoProcessResult?.durationFormatted ?? 'Max 10:00',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // File size badge
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.storage,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _videoProcessResult != null
                                        ? '${_videoProcessResult!.fileSizeMB}MB'
                                        : 'Processing...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tags Display
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF00BFA5),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Location Display
            if (_currentPosition != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF00BFA5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formattedAddress ?? 'Location added',
                        style: const TextStyle(
                          color: Color(0xFF00BFA5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _clearLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Category and Language
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _categories.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Language',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _languages.keys.map((String displayName) {
                            return DropdownMenuItem<String>(
                              value: displayName,
                              child: Text(displayName,
                                  style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLanguage = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Schedule (Optional)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectScheduleDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scheduledDate != null
                                ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} at ${_scheduledDate!.hour}:${_scheduledDate!.minute.toString().padLeft(2, '0')}'
                                : 'Schedule for later',
                            style: TextStyle(
                              color: _scheduledDate != null
                                  ? Colors.black87
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                        if (_scheduledDate != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _scheduledDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomButton(
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context)!.photos,
                onTap: _pickImages,
                color: _selectedVideo == null
                    ? const Color(0xFF00BFA5)
                    : Colors.grey,
              ),
              _buildBottomButton(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: _pickVideo,
                color: _selectedImages.isEmpty
                    ? const Color(0xFF9C27B0)
                    : Colors.grey,
              ),
              _buildBottomButton(
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context)!.camera,
                onTap: _takePhoto,
                color: _selectedVideo == null
                    ? const Color(0xFF00BFA5)
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey[200]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (badge != null && badge.isNotEmpty)
              Text(
                badge,
                style: TextStyle(fontSize: badge.length == 1 ? 28 : 16),
              )
            else
              Icon(icon, color: color, size: 28),
            if (badge != null && badge.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF44336),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(AppLocalizations.of(context)!.addTags),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tagsController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterTag,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (_) => _addTag(),
          ),
          const SizedBox(height: 12),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text('#$tag'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => _buildTagDialog(),
                    );
                  },
                );
              }).toList(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.done),
        ),
        ElevatedButton(
          onPressed: () {
            _addTag();
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => _buildTagDialog(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
          ),
          child: Text(AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}
