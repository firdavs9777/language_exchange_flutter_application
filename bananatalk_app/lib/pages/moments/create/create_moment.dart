import 'package:flutter/foundation.dart';
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
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/pages/moments/widgets/moments_snackbar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/moments/create/create_action_helpers.dart';
import 'package:bananatalk_app/pages/moments/create/create_tag_dialog.dart';
import 'package:bananatalk_app/widgets/voice_recorder/voice_recorder_mobile.dart';
import 'package:bananatalk_app/services/voice_message_service.dart';
import 'package:just_audio/just_audio.dart';

class CreateMoment extends ConsumerStatefulWidget {
  final Moments? momentToEdit; // If provided, we're editing an existing moment

  /// Optional prompt-of-the-day text to prefill into the composer (see
  /// `PromptOfDayCard`). Shown as a dismissible chip above the text field
  /// and, if present, prefills the description field itself.
  final String? prefillPrompt;

  /// Id of the prompt being answered, sent alongside the moment creation
  /// request so the backend can attribute the moment to the prompt.
  final String? prefillPromptId;

  const CreateMoment({
    Key? key,
    this.momentToEdit,
    this.prefillPrompt,
    this.prefillPromptId,
  }) : super(key: key);

  @override
  _CreateMomentState createState() => _CreateMomentState();
}

class _CreateMomentState extends ConsumerState<CreateMoment> {
  final descriptionController = TextEditingController();
  final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

  List<File> _selectedImages = [];
  File? _selectedVideo; // Video file for upload

  // Audio (voice-note) state
  File? _recordedAudio;
  int _recordedAudioDuration = 0; // seconds
  List<double> _recordedAudioWaveform = [];
  bool _isRecordingAudio = false;

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
  String _selectedBackgroundColor = '';

  // Prompt-of-the-day prefill state
  bool _showPromptChip = false;
  String? _promptId;

  static const int maxImages = 10;
  static const int maxDescriptionLength = 2000;

  final List<String> _privacyOptions = ['Public', 'Friends', 'Private'];
  final List<String> _categories = [
    'General',
    'Language Learning',
    'Travel',
    'Daily Life',
    'Food',
    'Culture',
    'Technology',
    'Entertainment',
    'Sports',
    'Music',
    'Books',
    'Movies',
    'Study',
    'Work',
    'Hobbies',
    'Question',
  ];

  // Category to backend format mapping (matching backend API and filter)
  final Map<String, String> _categoryToBackend = {
    'General': 'general',
    'Language Learning': 'language-learning',
    'Travel': 'travel',
    'Daily Life': 'daily-life',
    'Food': 'food',
    'Culture': 'culture',
    'Technology': 'technology',
    'Entertainment': 'entertainment',
    'Sports': 'sports',
    'Music': 'music',
    'Books': 'books',
    'Movies': 'movies',
    'Study': 'study',
    'Work': 'work',
    'Hobbies': 'hobbies',
    'Question': 'question',
  };
  // Language display name to ISO 639-1 code mapping (matching filter options)
  final Map<String, String> _languages = {
    'English': 'en',
    'Korean': 'ko',
    'Japanese': 'ja',
    'Chinese': 'zh',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Italian': 'it',
    'Portuguese': 'pt',
    'Russian': 'ru',
    'Arabic': 'ar',
    'Hindi': 'hi',
    'Tajik': 'tg',
    'Thai': 'th',
    'Vietnamese': 'vi',
    'Dutch': 'nl',
    'Swedish': 'sv',
  };
  // Moods matching filter options
  final Map<String, String> _moods = {
    '😊': 'happy',
    '🤩': 'excited',
    '🙏': 'grateful',
    '💪': 'motivated',
    '😌': 'relaxed',
    '🤔': 'curious',
    '😢': 'sad',
    '😍': 'love',
    '😂': 'funny',
    '💭': 'thoughtful',
    '😎': 'cool',
    '😴': 'tired',
  };

  @override
  bool get isEditMode => widget.momentToEdit != null;

  @override
  void initState() {
    super.initState();
    descriptionController.addListener(_updateButtonState);

    // Pre-fill form if editing
    if (widget.momentToEdit != null) {
      final moment = widget.momentToEdit!;
      descriptionController.text = moment.description;
      _tags = List<String>.from(moment.tags ?? []);

      // Map backend category to display category
      final backendCategory = moment.category?.toLowerCase() ?? '';
      _selectedCategory = _categoryToBackend.entries
          .firstWhere(
            (e) => e.value == backendCategory,
            orElse: () => const MapEntry('General', 'general'),
          )
          .key;

      // _selectedMood holds the emoji key (see _moods map: emoji -> word),
      // but moment.mood is the backend word (e.g. "happy") — reverse-lookup
      // the emoji so the mood picker shows the right selection and the
      // update payload (_moods[_selectedMood]) round-trips correctly.
      if (moment.mood.isNotEmpty) {
        final moodEntry = _moods.entries.firstWhere(
          (e) => e.value == moment.mood,
          orElse: () => const MapEntry('', ''),
        );
        _selectedMood = moodEntry.key.isNotEmpty ? moodEntry.key : null;
      }
      _selectedBackgroundColor = moment.backgroundColor;

      // Prefill language + privacy so edit mode reflects the moment as-is.
      final languageEntry = _languages.entries.firstWhere(
        (e) => e.value == moment.language,
        orElse: () => const MapEntry('English', 'en'),
      );
      _selectedLanguage = languageEntry.key;
      _selectedPrivacy = moment.privacy.isNotEmpty
          ? moment.privacy[0].toUpperCase() + moment.privacy.substring(1)
          : 'Public';
      if (!_privacyOptions.contains(_selectedPrivacy)) {
        _selectedPrivacy = 'Public';
      }

      // Button should be enabled immediately since description is prefilled.
      _updateButtonState();

      // Note: Images can't be easily pre-loaded as File objects since they're URLs
      // User can add new images but can't edit existing ones in this implementation
    } else if (widget.prefillPrompt != null && widget.prefillPrompt!.isNotEmpty) {
      // Prefill from prompt-of-the-day (see PromptOfDayCard)
      descriptionController.text = widget.prefillPrompt!;
      _promptId = widget.prefillPromptId;
      _showPromptChip = true;
      _updateButtonState();
    }
  }

  @override
  void dispose() {
    descriptionController.removeListener(_updateButtonState);
    descriptionController.dispose();
    isButtonEnabled.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    isButtonEnabled.value = descriptionController.text.isNotEmpty;
    // Trigger rebuild to update character counter
    if (mounted) setState(() {});
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
    if (_recordedAudio != null) {
      showMomentsSnackBar(
        context,
        message: 'Please remove the voice note first to add images',
      );
      return;
    }
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
        showMomentsSnackBar(
          context,
          message: 'Maximum $maxImages images allowed. Only $remainingSlots images added.',
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
      showMomentsSnackBar(
        context,
        message: AppLocalizations.of(context)!.pleaseRemoveImagesFirst,
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
          showMomentsSnackBar(
            context,
            message: 'Unsupported format. Use: ${allowedExtensions.join(", ").toUpperCase()}',
            type: MomentsSnackBarType.error,
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
      AppPageRoute(
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
          showMomentsSnackBar(
            context,
            message: 'Video compressed: ${result.fileSizeMB}MB (saved ${result.compressionSavings.toStringAsFixed(0)}%)',
            type: MomentsSnackBarType.success,
          );
        }
      } else {
        setState(() {
          _isProcessingVideo = false;
        });

        if (mounted) {
          showMomentsSnackBar(
            context,
            message: result.error ?? 'Failed to process video',
            type: MomentsSnackBarType.error,
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
        showMomentsSnackBar(
          context,
          message: 'Error processing video: $e',
          type: MomentsSnackBarType.error,
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
                        backgroundColor: context.containerColor,
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
                    color: context.textSecondary,
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
      showMomentsSnackBar(
        context,
        message: 'Please remove images first to record a video',
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

  /// Open the inline voice recorder (mic mode). Mutually exclusive with
  /// images/video, mirroring the existing image/video exclusivity rules.
  void _startRecordingAudio() {
    if (_selectedImages.isNotEmpty || _selectedVideo != null) {
      showMomentsSnackBar(
        context,
        message: 'Please remove images/video first to record audio',
      );
      return;
    }
    setState(() {
      _isRecordingAudio = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecorderWidget(
        onRecordingComplete: (file, durationSeconds, waveform) {
          Navigator.pop(context);
          // 60s cap enforced in UI (backend also enforces this).
          final cappedDuration = durationSeconds > 60 ? 60 : durationSeconds;
          setState(() {
            _isRecordingAudio = false;
            _recordedAudio = file;
            _recordedAudioDuration = cappedDuration;
            _recordedAudioWaveform = waveform;
          });
          if (durationSeconds > 60) {
            showMomentsSnackBar(
              context,
              message: 'Recording capped at 60 seconds',
            );
          }
          _updateButtonState();
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() {
            _isRecordingAudio = false;
          });
        },
      ),
    ).whenComplete(() {
      // Defensive reset: covers dismissal paths that bypass both
      // onRecordingComplete and onCancel (e.g. Android system back button),
      // which would otherwise leave _isRecordingAudio stuck at true.
      if (mounted && _isRecordingAudio) {
        setState(() {
          _isRecordingAudio = false;
        });
      }
    });
  }

  void _removeRecordedAudio() {
    setState(() {
      _recordedAudio = null;
      _recordedAudioDuration = 0;
      _recordedAudioWaveform = [];
    });
    _updateButtonState();
  }

  /// Show error dialog for audio upload failures with retry option.
  /// The moment already exists at this point (created without audio) —
  /// tell the user so they don't think the whole post failed.
  Future<void> _showAudioUploadErrorDialog(String momentId, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Audio upload failed')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Text(
              'Your moment was posted without the voice note.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    if (result == true && _recordedAudio != null) {
      try {
        await ref.read(momentsServiceProvider).uploadMomentAudio(
              momentId,
              _recordedAudio!,
              _recordedAudioDuration,
              waveform: _recordedAudioWaveform,
            );
        ref.invalidate(momentsProvider(1));
        ref.invalidate(momentsFeedProvider);
        if (mounted) {
          showMomentsSnackBar(
            context,
            message: 'Voice note uploaded',
            type: MomentsSnackBarType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          await _showAudioUploadErrorDialog(
            momentId,
            'Upload failed again: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
    }
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

      await setLocaleIdentifier('en_US');
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
        showMomentsSnackBar(
          context,
          message: '✓ Location added',
          type: MomentsSnackBarType.success,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        showMomentsSnackBar(
          context,
          message: 'Failed to get location: $e',
          type: MomentsSnackBarType.error,
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
              child: Text(AppLocalizations.of(context)!.momentsCancel, style: TextStyle(color: context.textSecondary)),
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
              child: Text(AppLocalizations.of(context)!.momentsNotNow, style: TextStyle(color: context.textSecondary)),
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
              child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
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
                            ? const Color(0xFF00BFA5).withValues(alpha: 0.1)
                            : context.containerColor,
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
                              color: context.textSecondary,
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
    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      return 'Caption is required';
    }
    if (description.length > maxDescriptionLength) {
      return 'Caption must be $maxDescriptionLength characters or less';
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
      debugPrint('Error formatting location: $e');
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
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.videoUploadFailed),
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
                color: Colors.blue.withValues(alpha: 0.1),
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
            child: Text(AppLocalizations.of(context)!.skipVideo),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: Text(AppLocalizations.of(context)!.retryUpload),
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
      showMomentsSnackBar(
        context,
        message: validationError,
      );
      return;
    }

    // Check limits before creating (skip for edit mode)
    if (!isEditMode) {
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
        debugPrint('Error checking limits: $e');
      }
    }

    // For video moments, use background upload for Instagram-like experience (only for new moments)
    if (_selectedVideo != null && !isEditMode) {
      await _createMomentWithBackgroundUpload();
      return;
    }

    // For non-video moments, use the regular flow
    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditMode) {
        // UPDATE existing moment
        await ref.read(momentsServiceProvider).updateMoment(
              id: widget.momentToEdit!.id,
              description: descriptionController.text.trim(),
              category: _categoryToBackend[_selectedCategory] ?? 'general',
              mood: _selectedMood != null ? _moods[_selectedMood] : null,
              tags: _tags.isNotEmpty ? _tags : null,
              backgroundColor: _selectedBackgroundColor.isNotEmpty ? _selectedBackgroundColor : null,
              language: _languages[_selectedLanguage] ?? 'en',
              privacy: _selectedPrivacy.toLowerCase(),
            );

        // Upload new images if any were added
        if (_selectedImages.isNotEmpty) {
          await ref.read(momentsServiceProvider).uploadMomentPhotos(
                widget.momentToEdit!.id,
                _selectedImages,
              );
        }

        // Refresh moments list
        ref.invalidate(momentsProvider(1));
        ref.invalidate(momentsFeedProvider);

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          showMomentsSnackBar(
            context,
            message: AppLocalizations.of(context)!.success,
            type: MomentsSnackBarType.success,
          );
        }
      } else {
        // CREATE new moment
        // Format location data if available
        final locationData = _formatLocationData();

        // Create moment with all fields (no userId - backend uses authenticated user)
        final moment = await ref.read(momentsServiceProvider).createMoments(
              description: descriptionController.text.trim(),
              privacy: _selectedPrivacy.toLowerCase(),
              category: _categoryToBackend[_selectedCategory] ?? 'general',
              language: _languages[_selectedLanguage] ?? 'en',
              mood: _selectedMood != null ? _moods[_selectedMood] : null,
              tags: _tags.isNotEmpty ? _tags : null,
              scheduledFor: _scheduledDate?.toIso8601String(),
              location: locationData,
              backgroundColor: _selectedBackgroundColor.isNotEmpty ? _selectedBackgroundColor : null,
              promptId: _showPromptChip ? _promptId : null,
            );

        // Upload images if any
        if (_selectedImages.isNotEmpty) {
          await ref.read(momentsServiceProvider).uploadMomentPhotos(
                moment.id,
                _selectedImages,
              );
        }

        // Upload recorded audio (voice note) if any. The moment already
        // exists at this point, so a failure here should not block the
        // user from seeing their post — surface a retry snackbar instead.
        bool audioUploadFailed = false;
        String? audioUploadError;
        if (_recordedAudio != null) {
          try {
            await ref.read(momentsServiceProvider).uploadMomentAudio(
                  moment.id,
                  _recordedAudio!,
                  _recordedAudioDuration,
                  waveform: _recordedAudioWaveform,
                );
          } catch (e) {
            audioUploadFailed = true;
            audioUploadError = e.toString().replaceFirst('Exception: ', '');
          }
        }

        // Refresh moments list (legacy feed plus the For You / Following
        // feeds so every entry point reflects the new moment).
        ref.invalidate(momentsProvider(1));
        ref.invalidate(momentsFeedProvider);
        ref.invalidate(forYouMomentsProvider);
        ref.invalidate(followingMomentsProvider);

        // Refresh limits after successful creation
        try {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('userId');
          if (userId != null) {
            ref.refresh(userLimitsProvider(userId));
          }
        } catch (e) {
          debugPrint('Error refreshing limits: $e');
        }

        if (mounted) {
          // Show the audio-upload-failure retry dialog *before* popping —
          // it needs a live State (uses `context`/`ref`/`setState` for its
          // own retry-upload flow), so it must run while this screen is
          // still mounted. A snackbar action fired after pop would be
          // calling back into an already-disposed State.
          if (audioUploadFailed) {
            await _showAudioUploadErrorDialog(
              moment.id,
              audioUploadError ?? 'Failed to upload audio',
            );
          }

          if (mounted) {
            Navigator.of(context).pop();
            showMomentsSnackBar(
              context,
              message: AppLocalizations.of(context)!.momentCreatedSuccessfully,
              type: MomentsSnackBarType.success,
            );
          }
        }
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
            debugPrint('Error handling limit error: $err');
          }
        } else {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          showMomentsSnackBar(
            context,
            message: errorMessage,
            type: MomentsSnackBarType.error,
            duration: const Duration(seconds: 4),
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
        description: descriptionController.text.trim(),
        privacy: _selectedPrivacy.toLowerCase(),
        category: _categoryToBackend[_selectedCategory] ?? 'general',
        language: _languages[_selectedLanguage] ?? 'en',
        mood: _selectedMood != null ? _moods[_selectedMood] : null,
        tags: _tags.isNotEmpty ? _tags : null,
        location: locationData,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
        videoPath: _selectedVideo?.path,
        backgroundColor: _selectedBackgroundColor.isNotEmpty ? _selectedBackgroundColor : null,
      );

      // Navigate back immediately - upload continues in background
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.uploadingMomentInBackground),
              ],
            ),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showMomentsSnackBar(
          context,
          message: 'Failed to queue upload: ${e.toString().replaceFirst('Exception: ', '')}',
          type: MomentsSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? AppLocalizations.of(context)!.edit : AppLocalizations.of(context)!.createMoment,
          style: context.titleLarge,
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
                        isEditMode
                            ? AppLocalizations.of(context)!.save
                            : AppLocalizations.of(context)!.post,
                        style: context.labelLarge.copyWith(
                          color: isEnabled
                              ? AppColors.primary
                              : context.textMuted,
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
            // Prompt-of-the-day chip (dismissible)
            if (_showPromptChip) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFC9A415)),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Answering the prompt of the day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC9A415),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPromptChip = false;
                            _promptId = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 16, color: Color(0xFFC9A415)),
                      ),
                    ],
                  ),
                ),
              ),
              Spacing.gapMD,
            ],
            // Privacy Selector
            Container(
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: AppRadius.borderMD,
                boxShadow: AppShadows.sm,
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
                          color: AppColors.primary,
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
            Spacing.gapMD,

            // Description Field with Counter + gradient preview
            () {
              final hasGradient = _selectedBackgroundColor.isNotEmpty && _selectedImages.isEmpty && _selectedVideo == null;
              final gradientColors = hasGradient
                  ? MomentGradients.getColors(_selectedBackgroundColor).map((c) => Color(c)).toList()
                  : null;

              return Container(
                decoration: BoxDecoration(
                  color: hasGradient ? null : context.cardBackground,
                  gradient: hasGradient
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors!,
                        )
                      : null,
                  borderRadius: AppRadius.borderMD,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: descriptionController,
                      maxLines: 8,
                      maxLength: maxDescriptionLength,
                      style: TextStyle(
                        color: hasGradient ? Colors.white : null,
                        fontWeight: hasGradient ? FontWeight.w600 : null,
                        fontSize: hasGradient ? 18 : null,
                        height: hasGradient ? 1.5 : null,
                        shadows: hasGradient
                            ? [const Shadow(blurRadius: 4, color: Colors.black26)]
                            : null,
                      ),
                      textAlign: hasGradient ? TextAlign.center : TextAlign.start,
                      decoration: InputDecoration(
                        hintText: hasGradient
                            ? AppLocalizations.of(context)!.whatsOnYourMind
                            : AppLocalizations.of(context)!.whatsOnYourMind,
                        hintStyle: TextStyle(
                          color: hasGradient ? Colors.white54 : context.textHint,
                        ),
                        filled: hasGradient,
                        fillColor: hasGradient ? Colors.black.withValues(alpha: 0.15) : null,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: Spacing.paddingLG,
                        counterText: '',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${descriptionController.text.length}/$maxDescriptionLength',
                          style: context.caption.copyWith(
                            color: descriptionController.text.length > maxDescriptionLength
                                ? AppColors.error
                                : descriptionController.text.length > maxDescriptionLength * 0.9
                                    ? Colors.orange
                                    : hasGradient ? Colors.white70 : context.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }(),
            // Background color picker (text-only posts)
            if (_selectedImages.isEmpty && _selectedVideo == null) ...[
              Spacing.gapMD,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.chooseBackground,
                      style: context.labelMedium.copyWith(color: context.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // "None" option
                          GestureDetector(
                            onTap: () => setState(() => _selectedBackgroundColor = ''),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                border: Border.all(
                                  color: _selectedBackgroundColor.isEmpty
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(Icons.block, size: 18, color: context.textMuted),
                            ),
                          ),
                          ...MomentGradients.presets.entries.map((entry) {
                            final colors = entry.value;
                            final isSelected = _selectedBackgroundColor == entry.key;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedBackgroundColor = entry.key),
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: colors.map((c) => Color(c)).toList(),
                                  ),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Spacing.gapXL,

            // Add to your moment section
            Text(
              AppLocalizations.of(context)!.momentsCreateAddTo,
              style: context.titleMedium,
            ),
            Spacing.gapMD,

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                createActionIcon(
                  context: context,
                  icon: Icons.image,
                  color: const Color(0xFF4CAF50),
                  onTap: _pickImages,
                ),
                createActionIcon(
                  context: context,
                  icon: Icons.emoji_emotions,
                  color: const Color(0xFFFFC107),
                  onTap: _showMoodPicker,
                  badge: _selectedMood,
                ),
                createActionIcon(
                  context: context,
                  icon: Icons.location_on,
                  color: const Color(0xFFF44336),
                  onTap: _requestLocationPermission,
                  isActive: _currentPosition != null,
                ),
                createActionIcon(
                  context: context,
                  icon: Icons.tag,
                  color: const Color(0xFF2196F3),
                  onTap: () async {
                    final updated = await showCreateTagDialog(
                      context,
                      existingTags: _tags,
                      maxTags: 5,
                    );
                    setState(() => _tags = updated);
                  },
                  badge: _tags.isNotEmpty ? '${_tags.length}' : null,
                ),
                // Voice notes aren't supported when editing an existing
                // moment yet (the update submit path doesn't upload audio),
                // so hide the control rather than silently drop a recording.
                if (!isEditMode)
                  createActionIcon(
                    context: context,
                    icon: Icons.mic,
                    color: const Color(0xFF9C27B0),
                    onTap: _isRecordingAudio ? () {} : _startRecordingAudio,
                    isActive: _recordedAudio != null,
                  ),
              ],
            ),
            Spacing.gapXL,

            // Recorded audio preview (voice note)
            if (!isEditMode && _recordedAudio != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: AppRadius.borderMD,
                  boxShadow: AppShadows.sm,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _LocalAudioPreviewPlayer(
                        file: _recordedAudio!,
                        durationSeconds: _recordedAudioDuration,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _removeRecordedAudio,
                      tooltip: 'Remove voice note',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Images Section
            if (_selectedImages.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: AppRadius.borderMD,
                  boxShadow: AppShadows.sm,
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
                              color: context.dividerColor,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                            borderRadius: AppRadius.borderSM,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  size: 32, color: context.iconColor),
                              Spacing.gapXS,
                              Text(
                                'Add More',
                                style: context.caption.copyWith(color: context.textSecondary),
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

            // TODO: Re-enable video preview section when needed (commented out to reduce app size)
            // Video Preview Section
            // if (_selectedVideo != null) ...[
            //   Container(
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(12),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black.withOpacity(0.04),
            //           blurRadius: 8,
            //           offset: const Offset(0, 2),
            //         ),
            //       ],
            //     ),
            //     padding: const EdgeInsets.all(12),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Container(
            //               padding: const EdgeInsets.all(8),
            //               decoration: BoxDecoration(
            //                 color: const Color(0xFF00BFA5).withOpacity(0.1),
            //                 borderRadius: BorderRadius.circular(8),
            //               ),
            //               child: const Icon(Icons.videocam, color: Color(0xFF00BFA5), size: 24),
            //             ),
            //             const SizedBox(width: 12),
            //             Expanded(
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   const Text(
            //                     'Video Ready',
            //                     style: TextStyle(
            //                       fontWeight: FontWeight.w600,
            //                       fontSize: 15,
            //                     ),
            //                   ),
            //                   const SizedBox(height: 4),
            //                   Row(
            //                     children: [
            //                       if (_videoProcessResult != null) ...[
            //                         Text(
            //                           '${_videoProcessResult!.fileSizeMB}MB',
            //                           style: TextStyle(
            //                             fontSize: 12,
            //                             color: Colors.grey[600],
            //                           ),
            //                         ),
            //                         if (_videoProcessResult!.duration != null) ...[
            //                           Text(
            //                             ' | ${_videoProcessResult!.durationFormatted}',
            //                             style: TextStyle(
            //                               fontSize: 12,
            //                               color: Colors.grey[600],
            //                             ),
            //                           ),
            //                         ],
            //                         if (_videoProcessResult!.wasCompressed) ...[
            //                           const SizedBox(width: 8),
            //                           Container(
            //                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            //                             decoration: BoxDecoration(
            //                               color: const Color(0xFF00BFA5).withOpacity(0.1),
            //                               borderRadius: BorderRadius.circular(4),
            //                             ),
            //                             child: Text(
            //                               'Compressed',
            //                               style: TextStyle(
            //                                 fontSize: 10,
            //                                 color: const Color(0xFF00BFA5),
            //                                 fontWeight: FontWeight.w600,
            //                               ),
            //                             ),
            //                           ),
            //                         ],
            //                       ] else
            //                         Text(
            //                           'Ready to upload',
            //                           style: TextStyle(
            //                             fontSize: 12,
            //                             color: Colors.grey[600],
            //                           ),
            //                         ),
            //                     ],
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             IconButton(
            //               icon: const Icon(Icons.close, size: 20),
            //               onPressed: _removeVideo,
            //               color: Colors.grey[600],
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 12),
            //         Container(
            //           height: 160,
            //           width: double.infinity,
            //           decoration: BoxDecoration(
            //             color: Colors.grey[900],
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           child: Stack(
            //             alignment: Alignment.center,
            //             children: [
            //               Container(
            //                 padding: const EdgeInsets.all(20),
            //                 decoration: BoxDecoration(
            //                   color: Colors.white.withOpacity(0.1),
            //                   shape: BoxShape.circle,
            //                 ),
            //                 child: const Icon(
            //                   Icons.play_arrow_rounded,
            //                   size: 48,
            //                   color: Colors.white,
            //                 ),
            //               ),
            //               // Duration badge
            //               Positioned(
            //                 bottom: 12,
            //                 left: 12,
            //                 child: Container(
            //                   padding: const EdgeInsets.symmetric(
            //                     horizontal: 10,
            //                     vertical: 5,
            //                   ),
            //                   decoration: BoxDecoration(
            //                     color: Colors.black.withOpacity(0.7),
            //                     borderRadius: BorderRadius.circular(6),
            //                   ),
            //                   child: Row(
            //                     mainAxisSize: MainAxisSize.min,
            //                     children: [
            //                       const Icon(
            //                         Icons.access_time,
            //                         size: 14,
            //                         color: Colors.white,
            //                       ),
            //                       const SizedBox(width: 4),
            //                       Text(
            //                         _videoProcessResult?.durationFormatted ?? 'Max 10:00',
            //                         style: const TextStyle(
            //                           color: Colors.white,
            //                           fontSize: 12,
            //                           fontWeight: FontWeight.w500,
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ),
            //               // File size badge
            //               Positioned(
            //                 bottom: 12,
            //                 right: 12,
            //                 child: Container(
            //                   padding: const EdgeInsets.symmetric(
            //                     horizontal: 10,
            //                     vertical: 5,
            //                   ),
            //                   decoration: BoxDecoration(
            //                     color: Colors.black.withOpacity(0.7),
            //                     borderRadius: BorderRadius.circular(6),
            //                   ),
            //                   child: Row(
            //                     mainAxisSize: MainAxisSize.min,
            //                     children: [
            //                       const Icon(
            //                         Icons.storage,
            //                         size: 14,
            //                         color: Colors.white,
            //                       ),
            //                       const SizedBox(width: 4),
            //                       Text(
            //                         _videoProcessResult != null
            //                             ? '${_videoProcessResult!.fileSizeMB}MB'
            //                             : 'Processing...',
            //                         style: const TextStyle(
            //                           color: Colors.white,
            //                           fontSize: 12,
            //                           fontWeight: FontWeight.w500,
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            //   const SizedBox(height: 20),
            // ],

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
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    labelStyle: context.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  );
                }).toList(),
              ),
              Spacing.gapXL,
            ],

            // Location Display
            if (_currentPosition != null) ...[
              Container(
                padding: Spacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSM,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary),
                    Spacing.hGapSM,
                    Expanded(
                      child: Text(
                        _formattedAddress ?? 'Location added',
                        style: context.bodyMedium.copyWith(
                          color: AppColors.primary,
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
              Spacing.gapXL,
            ],

            // Category and Language
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.momentsCreateCategory,
                        style: context.labelLarge,
                      ),
                      Spacing.gapSM,
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: AppRadius.borderMD,
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
                Spacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.momentsCreateLanguage,
                        style: context.labelLarge,
                      ),
                      Spacing.gapSM,
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: AppRadius.borderMD,
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
            Spacing.gapXL,

            // Schedule (Optional)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.momentsCreateSchedule,
                  style: context.labelLarge,
                ),
                Spacing.gapSM,
                InkWell(
                  onTap: _selectScheduleDate,
                  child: Container(
                    padding: Spacing.paddingLG,
                    decoration: BoxDecoration(
                      color: context.cardBackground,
                      borderRadius: AppRadius.borderMD,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: context.iconColor),
                        Spacing.hGapMD,
                        Expanded(
                          child: Text(
                            _scheduledDate != null
                                ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} at ${_scheduledDate!.hour}:${_scheduledDate!.minute.toString().padLeft(2, '0')}'
                                : AppLocalizations.of(context)!.momentsCreateScheduleForLater,
                            style: context.bodyMedium.copyWith(
                              color: _scheduledDate != null
                                  ? context.textPrimary
                                  : context.textMuted,
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
          color: context.surfaceColor,
          boxShadow: AppShadows.md,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              createBottomButton(
                context: context,
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context)!.photos,
                onTap: _pickImages,
                color: AppColors.primary,
              ),
              // TODO: Re-enable video upload when needed (commented out to reduce app size)
              // createBottomButton(
              //   context: context,
              //   icon: Icons.videocam_outlined,
              //   label: 'Video',
              //   onTap: _pickVideo,
              //   color: _selectedImages.isEmpty
              //       ? const Color(0xFF9C27B0)
              //       : Colors.grey,
              // ),
              createBottomButton(
                context: context,
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context)!.camera,
                onTap: _takePhoto,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Minimal local-file audio preview player for the composer's recorded
/// voice note, shown before posting. [VoiceMessagePlayer] (used on posted
/// moments and in chat) only supports remote URLs, so this widget plays
/// directly from the local recording file via `just_audio`.
class _LocalAudioPreviewPlayer extends StatefulWidget {
  final File file;
  final int durationSeconds;

  const _LocalAudioPreviewPlayer({
    required this.file,
    required this.durationSeconds,
  });

  @override
  State<_LocalAudioPreviewPlayer> createState() => _LocalAudioPreviewPlayerState();
}

class _LocalAudioPreviewPlayerState extends State<_LocalAudioPreviewPlayer> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_player.audioSource == null) {
        setState(() => _isLoading = true);
        await _player.setFilePath(widget.file.path);
      }
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayback,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF9C27B0),
              shape: BoxShape.circle,
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Text(
            _isPlaying || _position.inSeconds > 0
                ? '${VoiceMessageService.formatDuration(_position.inSeconds)} / ${VoiceMessageService.formatDuration(widget.durationSeconds)}'
                : VoiceMessageService.formatDuration(widget.durationSeconds),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
