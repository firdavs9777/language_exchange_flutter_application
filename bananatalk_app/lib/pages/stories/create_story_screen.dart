import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class CreateStoryScreen extends StatefulWidget {
  final VoidCallback? onStoryCreated;

  const CreateStoryScreen({
    Key? key,
    this.onStoryCreated,
  }) : super(key: key);

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
  final TextEditingController _textOverlayController = TextEditingController();

  // Video support
  final VideoCompressionService _videoCompressionService = VideoCompressionService();
  VideoPlayerController? _videoController;
  bool _isProcessingVideo = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToPickImage}: $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToTakePhoto}: $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToPickVideo}: $e')),
        );
      }
    }
  }

  /// Process video with compression (Instagram-like)
  Future<void> _processVideo(File videoFile) async {
    _showVideoProcessingDialog();

    setState(() {
      _isProcessingVideo = true;
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
          _isProcessingVideo = false;
        });

        if (mounted && result.wasCompressed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video optimized: ${result.fileSizeMB}MB (saved ${result.compressionSavings.toStringAsFixed(0)}%)',
              ),
              backgroundColor: const Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _isProcessingVideo = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to process video'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      setState(() => _isProcessingVideo = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    });
  }

  Future<void> _uploadStory() async {
    if (_isTextStory) {
      if (_textOverlayController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterSomeText)),
        );
        return;
      }
    } else if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectMedia)),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // For text stories, we need to create a solid color image
      // For now, we'll require a media file
      if (!_isTextStory && _mediaFile != null) {
        final result = await StoriesService.createStory(
          mediaFiles: [_mediaFile!],
          text: _captionController.text.trim().isEmpty 
              ? _textOverlayController.text.trim() 
              : _captionController.text.trim(),
          backgroundColor: _selectedColor,
          privacy: _privacy,
        );

        if (mounted) {
          if (result.success) {
            widget.onStoryCreated?.call();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.storyPosted),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() => _isUploading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.error ?? 'Failed to post story'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Text-only story would need special handling
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.textOnlyStoriesRequireAnImage)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          color: Colors.white.withOpacity(0.1),
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
      ],
    );
  }

  Widget _buildTextEditor() {
    final color = _selectedColor != null
        ? Color(int.parse(_selectedColor!.replaceFirst('#', '0xFF')))
        : Colors.blue;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background color
        Container(color: color),

        // Text input
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: TextField(
              controller: _textOverlayController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Type something...',
                hintStyle: TextStyle(
                  color: Colors.white54,
                  fontSize: 32,
                ),
                border: InputBorder.none,
              ),
              maxLines: 5,
            ),
          ),
        ),

        // Color picker
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 80,
          left: 16,
          right: 16,
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _backgroundColors.length,
              itemBuilder: (context, index) {
                final bgColor = _backgroundColors[index];
                final isSelected = bgColor == _selectedColor;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = bgColor),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(bgColor.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Privacy and share
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
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
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isTextStory = false;
                    _selectedColor = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
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
                  color: Colors.black.withOpacity(0.6),
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
                    color: Colors.black.withOpacity(0.7),
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

