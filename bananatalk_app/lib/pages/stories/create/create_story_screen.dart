import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/widgets/stories_snackbar.dart';
import 'package:bananatalk_app/pages/stories/create/gradient_picker.dart';
import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';
import 'package:bananatalk_app/pages/stories/widgets/overlay_editor.dart';

class CreateStoryScreen extends StatefulWidget {
  final VoidCallback? onStoryCreated;

  const CreateStoryScreen({
    super.key,
    this.onStoryCreated,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _mediaFile;
  String _mediaType = 'image';
  final TextEditingController _captionController = TextEditingController();
  StoryPrivacy _privacy = StoryPrivacy.everyone;
  bool _isUploading = false;
  String? _selectedColor;
  bool _isTextStory = false;
  String _gradientId = StoryGradient.presets.first.id;
  final TextEditingController _textOverlayController = TextEditingController();

  // Overlay elements added via the overlay editor
  List<OverlayElement> _overlays = [];

  // Video support
  final VideoCompressionService _videoCompressionService = VideoCompressionService();
  VideoPlayerController? _videoController;
  double _videoCompressionProgress = 0;
  String _videoProcessingStatus = '';
  VideoProcessResult? _videoProcessResult;

  final List<String> _backgroundColors = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DDA0DD', // Purple
    '#FF8C69', // Orange
    '#98D8C8', // Mint
    '#F7DC6F', // Gold
    '#BB8FCE', // Lavender
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _textOverlayController.dispose();
    _videoController?.dispose();
    _videoCompressionService.deleteAllCache();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          _mediaType = 'image';
          _isTextStory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showStoriesSnackBar(
          context,
          message: '${AppLocalizations.of(context)!.failedToPickImage}: $e',
          type: StoriesSnackBarType.error,
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          _mediaType = 'image';
          _isTextStory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showStoriesSnackBar(
          context,
          message: '${AppLocalizations.of(context)!.failedToTakePhoto}: $e',
          type: StoriesSnackBarType.error,
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60), // 60 seconds for stories
      );

      if (pickedFile != null) {
        await _processVideo(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        showStoriesSnackBar(
          context,
          message: '${AppLocalizations.of(context)!.failedToPickVideo}: $e',
          type: StoriesSnackBarType.error,
        );
      }
    }
  }

  /// Process video with compression (Instagram-like)
  Future<void> _processVideo(File videoFile) async {
    _showVideoProcessingDialog();

    setState(() {
      _videoCompressionProgress = 0;
      _videoProcessingStatus = 'Preparing video...';
    });

    try {
      final result = await _videoCompressionService.processVideoForUpload(
        videoFile,
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

      // Close dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (result.success && result.processedFile != null) {
        // Initialize video player for preview
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(result.processedFile!)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController!.setLooping(true);
            }
          });

        setState(() {
          _mediaFile = result.processedFile;
          _mediaType = 'video';
          _isTextStory = false;
          _videoProcessResult = result;
        });

        if (mounted && result.wasCompressed) {
          showStoriesSnackBar(
            context,
            message: 'Video optimized: ${result.fileSizeMB}MB (saved ${result.compressionSavings.toStringAsFixed(0)}%)',
            type: StoriesSnackBarType.success,
          );
        }
      } else {
        if (mounted) {
          showStoriesSnackBar(
            context,
            message: result.error ?? 'Failed to process video',
            type: StoriesSnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        showStoriesSnackBar(
          context,
          message: 'Error: $e',
          type: StoriesSnackBarType.error,
        );
      }
    }
  }

  void _showVideoProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
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
                    backgroundColor: Colors.grey[700],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
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
                  const Icon(Icons.videocam, size: 32, color: Color(0xFF00BFA5)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _videoProcessingStatus.isNotEmpty ? _videoProcessingStatus : 'Processing...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Optimizing for the best experience',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createTextStory() {
    setState(() {
      _isTextStory = true;
      _mediaFile = null;
      _selectedColor = _backgroundColors.first;
      _gradientId = StoryGradient.presets.first.id;
    });
  }

  Future<void> _uploadStory() async {
    if (_isTextStory) {
      if (_textOverlayController.text.trim().isEmpty) {
        showStoriesSnackBar(
          context,
          message: AppLocalizations.of(context)!.pleaseEnterSomeText,
          type: StoriesSnackBarType.info,
        );
        return;
      }
    } else if (_mediaFile == null) {
      showStoriesSnackBar(
        context,
        message: AppLocalizations.of(context)!.pleaseSelectMedia,
        type: StoriesSnackBarType.info,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (_isTextStory) {
        // Create text-only story
        final result = await StoriesService.createTextStory(
          text: _textOverlayController.text.trim(),
          backgroundColor: _gradientId,
          textColor: '#FFFFFF',
          fontStyle: 'normal',
          privacy: _privacy,
        );

        if (mounted) {
          if (result.success) {
            widget.onStoryCreated?.call();
            Navigator.pop(context);
            showStoriesSnackBar(
              context,
              message: AppLocalizations.of(context)!.storyPosted,
              type: StoriesSnackBarType.success,
            );
          } else {
            setState(() => _isUploading = false);
            showStoriesSnackBar(
              context,
              message: result.error ?? 'Failed to post story',
              type: StoriesSnackBarType.error,
            );
          }
        }
      } else if (_mediaFile != null) {
        // Create media story (image or video)
        final result = await StoriesService.createStory(
          mediaFiles: [_mediaFile!],
          text: _captionController.text.trim().isEmpty
              ? _textOverlayController.text.trim()
              : _captionController.text.trim(),
          backgroundColor: _selectedColor,
          privacy: _privacy,
          overlays: _overlays.map((e) => e.toJson()).toList(),
        );

        if (mounted) {
          if (result.success) {
            widget.onStoryCreated?.call();
            Navigator.pop(context);
            showStoriesSnackBar(
              context,
              message: AppLocalizations.of(context)!.storyPosted,
              type: StoriesSnackBarType.success,
            );
          } else {
            setState(() => _isUploading = false);
            showStoriesSnackBar(
              context,
              message: result.error ?? 'Failed to post story',
              type: StoriesSnackBarType.error,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        showStoriesSnackBar(
          context,
          message: 'Error: $e',
          type: StoriesSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.createStory),
        actions: [
          if (_mediaFile != null || _isTextStory)
            TextButton(
              onPressed: _isUploading ? null : _uploadStory,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _mediaFile != null
          ? _buildPreview()
          : _isTextStory
              ? _buildTextEditor()
              : _buildMediaPicker(),
    );
  }

  Widget _buildMediaPicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate,
            size: 80,
            color: Colors.white30,
          ),
          const SizedBox(height: 24),
          const Text(
            'Create a Story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share moments that disappear in 24 hours',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildPickerOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickImage,
              ),
              _buildPickerOption(
                icon: Icons.camera_alt,
                label: AppLocalizations.of(context)!.camera,
                onTap: _takePhoto,
              ),
              _buildPickerOption(
                icon: Icons.videocam,
                label: AppLocalizations.of(context)!.video,
                onTap: _pickVideo,
              ),
              _buildPickerOption(
                icon: Icons.text_fields,
                label: AppLocalizations.of(context)!.text,
                onTap: _createTextStory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final isVideo = _mediaType == 'video' || 
                    _mediaFile!.path.toLowerCase().endsWith('.mp4') ||
                    _mediaFile!.path.toLowerCase().endsWith('.mov') ||
                    _mediaFile!.path.toLowerCase().endsWith('.avi') ||
                    _mediaFile!.path.toLowerCase().endsWith('.mkv');
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media preview
        isVideo
            ? _buildVideoPreview()
            : Image.file(
                _mediaFile!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // If image fails, it might be a video
                  return _buildVideoPreview();
                },
              ),

        // Caption input at bottom
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              // Privacy selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<StoryPrivacy>(
                  value: _privacy,
                  dropdownColor: Colors.grey[900],
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: StoryPrivacy.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Icon(
                            _getPrivacyIcon(p),
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _privacy = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              
              // Caption input
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black54,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),

        // Change media button
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _mediaFile = null;
                _isTextStory = false;
                _overlays = [];
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Text('Change', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),

        // Add overlays button (top-right)
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _openOverlayEditor,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.text_fields, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _overlays.isEmpty ? 'Add Text' : 'Edit (${_overlays.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openOverlayEditor() async {
    if (_mediaFile == null) return;
    final result = await Navigator.push<List<OverlayElement>>(
      context,
      MaterialPageRoute(
        builder: (_) => _OverlayEditorScreen(
          backgroundImage: _mediaFile!,
          initial: List<OverlayElement>.from(_overlays),
        ),
      ),
    );
    if (result != null) {
      setState(() => _overlays = result);
    }
  }

  Widget _buildTextEditor() {
    final gradient = StoryGradient.byId(_gradientId);

    return Container(
      decoration: BoxDecoration(gradient: gradient.toLinearGradient()),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar: close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTextStory = false;
                      _selectedColor = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ),

            // Text input — fills available space
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    controller: _textOverlayController,
                    autofocus: true,
                    maxLength: 5000,
                    textAlign: TextAlign.center,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterTextHint,
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ),

            // Gradient picker
            GradientPicker(
              selectedId: _gradientId,
              onChanged: (id) => setState(() => _gradientId = id),
            ),

            // Privacy selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButton<StoryPrivacy>(
                      value: _privacy,
                      dropdownColor: Colors.grey[900],
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: StoryPrivacy.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _privacy = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _getPrivacyIcon(StoryPrivacy privacy) {
    switch (privacy) {
      case StoryPrivacy.everyone:
        return Icons.public;
      case StoryPrivacy.friends:
        return Icons.people;
      case StoryPrivacy.closeFriends:
        return Icons.star;
    }
  }

  Widget _buildVideoPreview() {
    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player or placeholder
            if (_videoController != null && _videoController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[900],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white70, size: 80),
                    const SizedBox(height: 16),
                    const Text(
                      'Video Selected',
                      style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _mediaFile!.path.split('/').last,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Play/Pause overlay
            if (_videoController != null &&
                _videoController!.value.isInitialized &&
                !_videoController!.value.isPlaying)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
              ),

            // Video info badge
            if (_videoProcessResult != null)
              Positioned(
                bottom: 120,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_videoProcessResult!.durationFormatted} | ${_videoProcessResult!.fileSizeMB}MB',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      if (_videoProcessResult!.wasCompressed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HD',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Video progress bar
            if (_videoController != null && _videoController!.value.isInitialized)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF00BFA5),
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Full-screen overlay editor screen
// ---------------------------------------------------------------------------

/// A full-screen screen that lets the user place, drag, scale, and rotate
/// [OverlayElement] objects on top of a background image preview.
/// Returns the final [List<OverlayElement>] when the user taps "Done".
class _OverlayEditorScreen extends StatefulWidget {
  final File backgroundImage;
  final List<OverlayElement> initial;

  const _OverlayEditorScreen({
    required this.backgroundImage,
    required this.initial,
  });

  @override
  State<_OverlayEditorScreen> createState() => _OverlayEditorScreenState();
}

class _OverlayEditorScreenState extends State<_OverlayEditorScreen> {
  late List<OverlayElement> _elements;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _elements = List<OverlayElement>.from(widget.initial);
  }

  void _addText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _elements.add(OverlayElement(
          type: 'text',
          content: text.trim(),
        ));
        _selectedIndex = _elements.length - 1;
      });
    }
  }

  void _addSticker() async {
    const stickers = ['😀', '😂', '❤️', '🔥', '👍', '✨', '🎉', '💯',
                       '😎', '🌈', '⭐', '🏆', '💪', '🙌', '🤩', '🥳'];
    final emoji = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Pick an Emoji', style: TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stickers
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, e),
                    child: Text(e, style: const TextStyle(fontSize: 36)),
                  ))
              .toList(),
        ),
      ),
    );
    if (emoji != null) {
      setState(() {
        _elements.add(OverlayElement(
          type: 'sticker',
          content: emoji,
        ));
        _selectedIndex = _elements.length - 1;
      });
    }
  }

  void _deleteSelected() {
    if (_selectedIndex == null) return;
    setState(() {
      _elements.removeAt(_selectedIndex!);
      _selectedIndex = null;
    });
  }

  void _changeColor(Color color) {
    if (_selectedIndex == null) return;
    setState(() => _elements[_selectedIndex!].color = color);
  }

  void _changeFont(String font) {
    if (_selectedIndex == null) return;
    setState(() => _elements[_selectedIndex!].fontStyle = font);
  }

  void _changeBgMode(String mode) {
    if (_selectedIndex == null) return;
    setState(() => _elements[_selectedIndex!].bgMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final selectedElement =
        _selectedIndex != null ? _elements[_selectedIndex!] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _elements),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = null),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      Image.file(
                        widget.backgroundImage,
                        fit: BoxFit.contain,
                      ),
                      // Draggable overlays
                      ..._elements.asMap().entries.map((entry) {
                        final i = entry.key;
                        final el = entry.value;
                        return DraggableOverlay(
                          key: ValueKey(i),
                          element: el,
                          containerSize: size,
                          isSelected: _selectedIndex == i,
                          onTap: () => setState(() => _selectedIndex = i),
                          onDelete: () {
                            setState(() {
                              _elements.removeAt(i);
                              _selectedIndex = null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          // Toolbar
          OverlayToolbar(
            selectedElement: selectedElement,
            onAddText: _addText,
            onAddSticker: _addSticker,
            onColorChanged: _changeColor,
            onFontChanged: _changeFont,
            onBgModeChanged: _changeBgMode,
            onDelete: _deleteSelected,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

