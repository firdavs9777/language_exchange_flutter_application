import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/upload_manager_provider.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/pages/video_editor/video_editor_screen.dart';
import 'package:bananatalk_app/widgets/story/story_poll_widget.dart';
import 'package:bananatalk_app/widgets/story/story_question_box_widget.dart';

/// Screen for creating a new story with all sticker options
class StoryCreationScreen extends ConsumerStatefulWidget {
  const StoryCreationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends ConsumerState<StoryCreationScreen> {
  final ImagePicker _picker = ImagePicker();
  final VideoCompressionService _videoCompressionService = VideoCompressionService();

  // Content
  List<File> _mediaFiles = [];
  String? _text;
  String _backgroundColor = '#1A1A2E';
  String _textColor = '#FFFFFF';
  String _fontStyle = 'normal';

  // Video support
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isVideoMode = false;
  bool _isProcessingVideo = false;
  double _videoCompressionProgress = 0;
  String _videoProcessingStatus = '';
  VideoProcessResult? _videoProcessResult;

  // Settings
  StoryPrivacy _privacy = StoryPrivacy.everyone;
  bool _allowReplies = true;
  bool _allowSharing = true;

  // Stickers
  StoryPoll? _poll;
  StoryQuestionBox? _questionBox;
  StoryLocation? _location;
  StoryLink? _link;
  List<StoryMention> _mentions = [];
  List<String> _hashtags = [];
  StoryMusic? _music;

  bool _isCreating = false;
  bool _isTextMode = false;

  // Text mode controller
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    _videoCompressionService.deleteAllCache();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final pickedFiles = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _mediaFiles = pickedFiles.take(5).map((f) => File(f.path)).toList();
        _isTextMode = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _mediaFiles = [File(photo.path)];
        _isTextMode = false;
        _isVideoMode = false;
        _videoFile = null;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  /// Pick video from gallery with Instagram-like compression
  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60), // 60 seconds max for stories
    );

    if (video != null) {
      await _processVideo(File(video.path));
    }
  }

  /// Record video with camera
  Future<void> _recordVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );

    if (video != null) {
      await _processVideo(File(video.path));
    }
  }

  /// Process video with video editor and compression
  Future<void> _processVideo(File videoFile) async {
    // First, open the video editor for trimming and filters
    final editorResult = await Navigator.push<VideoEditorResult>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoEditorScreen(
          videoFile: videoFile,
          maxDurationSeconds: 60, // 60 seconds max for stories
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
        // Initialize video player
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(result.processedFile!)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController!.setLooping(true);
              _videoController!.play();
            }
          });

        setState(() {
          _videoFile = result.processedFile;
          _videoProcessResult = result;
          _isVideoMode = true;
          _isTextMode = false;
          _mediaFiles = [];
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
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        _isProcessingVideo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Optimizing for the best story experience',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _removeVideo() {
    _videoController?.dispose();
    setState(() {
      _videoFile = null;
      _videoController = null;
      _isVideoMode = false;
      _videoProcessResult = null;
    });
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _enableTextMode() {
    setState(() {
      _isTextMode = true;
      _isVideoMode = false;
      _mediaFiles = [];
      _videoFile = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  Future<void> _createStory() async {
    // Validate content - only images and videos are allowed
    if (_mediaFiles.isEmpty && !_isVideoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image or video for your story'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For video stories, use background upload for Instagram-like experience
    if (_isVideoMode && _videoFile != null) {
      await _createStoryWithBackgroundUpload();
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Determine media files to send (images only for direct upload)
      List<File> mediaToUpload = _mediaFiles;

      if (mediaToUpload.isEmpty) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image or video for your story'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await StoriesService.createStory(
        mediaFiles: mediaToUpload,
        privacy: _privacy,
      );

      print('Story creation result: success=${result.success}, error=${result.error}');

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story created successfully!'),
              backgroundColor: Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Handle specific video errors
        final errorMsg = result.error ?? 'Failed to create story';
        print('Story creation error: $errorMsg');

        if (errorMsg.contains('Video Service') ||
            errorMsg.contains('processing unavailable')) {
          _showVideoUploadErrorDialog(errorMsg);
        } else {
          // Show detailed error dialog for better debugging
          _showErrorDialog(errorMsg);
        }
        setState(() => _isCreating = false);
      }
    } catch (e) {
      print('Story creation exception: $e');
      if (mounted) {
        _showErrorDialog('Exception: $e');
        setState(() => _isCreating = false);
      }
    }
  }

  /// Create story with background video upload (Instagram-like experience)
  Future<void> _createStoryWithBackgroundUpload() async {
    try {
      // Queue the upload for background processing
      await ref.read(uploadManagerProvider.notifier).queueStoryUpload(
        mediaPath: _videoFile!.path,
        isVideo: true,
        text: _text,
        backgroundColor: _backgroundColor,
        privacy: _privacy,
      );

      // Navigate back immediately - upload continues in background
      if (mounted) {
        Navigator.pop(context, true);
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
                Text('Uploading story in background...'),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text('Story Creation Failed', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createStory(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showVideoUploadErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Upload Failed', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
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
                      'Try using a shorter video or try again later.',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createStory(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showStickerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StickerMenu(
        onPoll: () {
          Navigator.pop(context);
          _showPollCreator();
        },
        onQuestion: () {
          Navigator.pop(context);
          _showQuestionCreator();
        },
        onLocation: () {
          Navigator.pop(context);
          _showLocationPicker();
        },
        onLink: () {
          Navigator.pop(context);
          _showLinkEditor();
        },
        onMention: () {
          Navigator.pop(context);
          _showMentionPicker();
        },
        onMusic: () {
          Navigator.pop(context);
          _showMusicPicker();
        },
        onHashtag: () {
          Navigator.pop(context);
          _showHashtagEditor();
        },
      ),
    );
  }

  void _showPollCreator() {
    showDialog(
      context: context,
      builder: (context) => CreateStoryPollDialog(
        onPollCreated: (poll) => setState(() => _poll = poll),
      ),
    );
  }

  void _showQuestionCreator() {
    showDialog(
      context: context,
      builder: (context) => CreateQuestionBoxDialog(
        onCreated: (box) => setState(() => _questionBox = box),
      ),
    );
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => _LocationPickerDialog(
        onSelected: (location) => setState(() => _location = location),
      ),
    );
  }

  void _showLinkEditor() {
    showDialog(
      context: context,
      builder: (context) => _LinkEditorDialog(
        onCreated: (link) => setState(() => _link = link),
      ),
    );
  }

  void _showMentionPicker() {
    // For simplicity, show a basic dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mention picker coming soon')),
    );
  }

  void _showMusicPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Music picker coming soon')),
    );
  }

  void _showHashtagEditor() {
    showDialog(
      context: context,
      builder: (context) => _HashtagEditorDialog(
        initialTags: _hashtags,
        onSaved: (tags) => setState(() => _hashtags = tags),
      ),
    );
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PrivacyPicker(
        currentPrivacy: _privacy,
        onSelected: (privacy) {
          setState(() => _privacy = privacy);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ColorPicker(
        currentColor: _backgroundColor,
        onSelected: (color) {
          setState(() => _backgroundColor = color);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFontPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FontPicker(
        currentFont: _fontStyle,
        onSelected: (font) {
          setState(() => _fontStyle = font);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _mediaFiles.isNotEmpty || _isTextMode || _isVideoMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content preview
          if (hasContent)
            _buildContentPreview()
          else
            _buildMediaSelector(),

          // Top bar
          _buildTopBar(),

          // Sticker overlays
          if (hasContent) _buildStickerOverlays(),

          // Bottom bar
          if (hasContent) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildMediaSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          const Text(
            'Create Story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share moments that disappear in 24 hours',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 40),

          // Media buttons in grid
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              // Camera Photo
              _MediaButton(
                icon: Icons.camera_alt,
                label: 'Photo',
                onTap: _takePhoto,
              ),
              // Gallery Images
              _MediaButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickMedia,
              ),
              // Video from Gallery
              _MediaButton(
                icon: Icons.videocam,
                label: 'Video',
                onTap: _pickVideo,
                color: Colors.purple,
              ),
              // Record Video
              _MediaButton(
                icon: Icons.fiber_manual_record,
                label: 'Record',
                onTap: _recordVideo,
                color: Colors.red,
              ),
              // Text Story - disabled (backend only accepts images/videos)
              // _MediaButton(
              //   icon: Icons.text_fields,
              //   label: 'Text',
              //   onTap: _enableTextMode,
              //   color: Colors.blue,
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview() {
    // Text mode
    if (_isTextMode) {
      return Container(
        color: Color(int.parse(_backgroundColor.replaceFirst('#', '0xFF'))),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: TextField(
            controller: _textController,
            style: TextStyle(
              color: Color(int.parse(_textColor.replaceFirst('#', '0xFF'))),
              fontSize: 28,
              fontWeight: _fontStyle == 'bold' ? FontWeight.bold : FontWeight.normal,
              fontStyle: _fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
              fontFamily: _fontStyle == 'handwriting' ? 'Caveat' : null,
            ),
            textAlign: TextAlign.center,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Type something...',
              hintStyle: TextStyle(
                color: Color(int.parse(_textColor.replaceFirst('#', '0xFF')))
                    .withOpacity(0.5),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      );
    }

    // Video mode - show video player
    if (_isVideoMode && _videoController != null) {
      return GestureDetector(
        onTap: _toggleVideoPlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            Center(
              child: _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // Play/Pause overlay
            if (_videoController!.value.isInitialized &&
                !_videoController!.value.isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

            // Video info badge
            Positioned(
              bottom: 100,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _videoProcessResult != null
                          ? '${_videoProcessResult!.durationFormatted} | ${_videoProcessResult!.fileSizeMB}MB'
                          : 'Video',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (_videoProcessResult?.wasCompressed == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Remove video button
            Positioned(
              top: 100,
              right: 16,
              child: GestureDetector(
                onTap: _removeVideo,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),

            // Video progress bar
            if (_videoController!.value.isInitialized)
              Positioned(
                bottom: 80,
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
      );
    }

    // Single image
    if (_mediaFiles.length == 1) {
      return Image.file(_mediaFiles.first, fit: BoxFit.cover);
    }

    // Multiple images
    return PageView.builder(
      itemCount: _mediaFiles.length,
      itemBuilder: (context, index) {
        return Image.file(_mediaFiles[index], fit: BoxFit.cover);
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          if (_isTextMode) ...[
            IconButton(
              icon: const Icon(Icons.color_lens, color: Colors.white),
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: const Icon(Icons.text_format, color: Colors.white),
              onPressed: _showFontPicker,
            ),
          ],
          if (_mediaFiles.isNotEmpty || _isTextMode)
            IconButton(
              icon: const Icon(Icons.sticky_note_2, color: Colors.white),
              onPressed: _showStickerMenu,
            ),
        ],
      ),
    );
  }

  Widget _buildStickerOverlays() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_poll != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  StoryPollWidget(poll: _poll!, isOwner: true),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _poll = null),
                    ),
                  ),
                ],
              ),
            ),
          if (_questionBox != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  StoryQuestionBoxWidget(questionBox: _questionBox!, isOwner: true),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _questionBox = null),
                    ),
                  ),
                ],
              ),
            ),
          if (_location != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _DismissibleSticker(
                onDismiss: () => setState(() => _location = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 18),
                      const SizedBox(width: 4),
                      Text(_location!.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          if (_link != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _DismissibleSticker(
                onDismiss: () => setState(() => _link = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(_link!.displayText, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          if (_hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 8,
                children: _hashtags.map((tag) => Chip(
                  label: Text('#$tag', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                  onDeleted: () => setState(() => _hashtags.remove(tag)),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        child: Row(
          children: [
            // Privacy selector
            GestureDetector(
              onTap: _showPrivacyPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _privacy == StoryPrivacy.closeFriends
                      ? Colors.green.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: _privacy == StoryPrivacy.closeFriends
                      ? Border.all(color: Colors.green)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _privacy == StoryPrivacy.closeFriends
                          ? Icons.star
                          : _privacy == StoryPrivacy.friends
                              ? Icons.people
                              : Icons.public,
                      color: _privacy == StoryPrivacy.closeFriends
                          ? Colors.green
                          : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _privacy.displayName,
                      style: TextStyle(
                        color: _privacy == StoryPrivacy.closeFriends
                            ? Colors.green
                            : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Share button
            ElevatedButton(
              onPressed: _isCreating ? null : _createStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets
class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Colors.grey[700];
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: buttonColor!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: buttonColor.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerMenu extends StatelessWidget {
  final VoidCallback onPoll;
  final VoidCallback onQuestion;
  final VoidCallback onLocation;
  final VoidCallback onLink;
  final VoidCallback onMention;
  final VoidCallback onMusic;
  final VoidCallback onHashtag;

  const _StickerMenu({
    required this.onPoll,
    required this.onQuestion,
    required this.onLocation,
    required this.onLink,
    required this.onMention,
    required this.onMusic,
    required this.onHashtag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Add Sticker',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _StickerItem(icon: Icons.poll, label: 'Poll', onTap: onPoll),
            _StickerItem(icon: Icons.question_answer, label: 'Question', onTap: onQuestion),
            _StickerItem(icon: Icons.location_on, label: 'Location', onTap: onLocation),
            _StickerItem(icon: Icons.link, label: 'Link', onTap: onLink),
            _StickerItem(icon: Icons.alternate_email, label: 'Mention', onTap: onMention),
            _StickerItem(icon: Icons.music_note, label: 'Music', onTap: onMusic),
            _StickerItem(icon: Icons.tag, label: 'Hashtag', onTap: onHashtag),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StickerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StickerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PrivacyPicker extends StatelessWidget {
  final StoryPrivacy currentPrivacy;
  final Function(StoryPrivacy) onSelected;

  const _PrivacyPicker({required this.currentPrivacy, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Who can see this?',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _PrivacyOption(
          icon: Icons.public,
          title: 'Everyone',
          subtitle: 'Anyone can see this story',
          isSelected: currentPrivacy == StoryPrivacy.everyone,
          onTap: () => onSelected(StoryPrivacy.everyone),
        ),
        _PrivacyOption(
          icon: Icons.people,
          title: 'Friends Only',
          subtitle: 'Only your followers can see',
          isSelected: currentPrivacy == StoryPrivacy.friends,
          onTap: () => onSelected(StoryPrivacy.friends),
        ),
        _PrivacyOption(
          icon: Icons.star,
          title: 'Close Friends',
          subtitle: 'Only your close friends can see',
          isSelected: currentPrivacy == StoryPrivacy.closeFriends,
          onTap: () => onSelected(StoryPrivacy.closeFriends),
          isCloseFriends: true,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCloseFriends;

  const _PrivacyOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isCloseFriends = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCloseFriends 
              ? Colors.green.withOpacity(0.2)
              : Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isCloseFriends ? Colors.green : Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: onTap,
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String currentColor;
  final Function(String) onSelected;

  const _ColorPicker({required this.currentColor, required this.onSelected});

  static const List<String> colors = [
    '#1A1A2E', '#16213E', '#0F3460', '#533483',
    '#E94560', '#FF6B6B', '#4ECDC4', '#45B7D1',
    '#96CEB4', '#FFEEAD', '#FF6F61', '#6B5B95',
    '#88B04B', '#F7CAC9', '#92A8D1', '#034F84',
    '#000000', '#1A1A1A', '#333333', '#555555',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Background Color',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final isSelected = color.toUpperCase() == currentColor.toUpperCase();
              return GestureDetector(
                onTap: () => onSelected(color),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FontPicker extends StatelessWidget {
  final String currentFont;
  final Function(String) onSelected;

  const _FontPicker({required this.currentFont, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Font Style',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...[
          ('normal', 'Normal', FontWeight.normal, FontStyle.normal),
          ('bold', 'Bold', FontWeight.bold, FontStyle.normal),
          ('italic', 'Italic', FontWeight.normal, FontStyle.italic),
          ('handwriting', 'Handwriting', FontWeight.normal, FontStyle.normal),
        ].map((font) {
          return ListTile(
            title: Text(
              font.$2,
              style: TextStyle(
                color: Colors.white,
                fontWeight: font.$3,
                fontStyle: font.$4,
                fontFamily: font.$1 == 'handwriting' ? 'Caveat' : null,
                fontSize: 18,
              ),
            ),
            trailing: currentFont == font.$1
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : null,
            onTap: () => onSelected(font.$1),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LocationPickerDialog extends StatefulWidget {
  final Function(StoryLocation) onSelected;

  const _LocationPickerDialog({required this.onSelected});

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Add Location', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter location name',
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) return;
            widget.onSelected(StoryLocation(name: _controller.text.trim()));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _LinkEditorDialog extends StatefulWidget {
  final Function(StoryLink) onCreated;

  const _LinkEditorDialog({required this.onCreated});

  @override
  State<_LinkEditorDialog> createState() => _LinkEditorDialogState();
}

class _LinkEditorDialogState extends State<_LinkEditorDialog> {
  final _urlController = TextEditingController();
  final _textController = TextEditingController(text: 'Learn More');

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Add Link', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Button text',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: () {
            if (_urlController.text.trim().isEmpty) return;
            widget.onCreated(StoryLink(
              url: _urlController.text.trim(),
              displayText: _textController.text.trim().isEmpty 
                  ? 'Learn More' 
                  : _textController.text.trim(),
            ));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _HashtagEditorDialog extends StatefulWidget {
  final List<String> initialTags;
  final Function(List<String>) onSaved;

  const _HashtagEditorDialog({required this.initialTags, required this.onSaved});

  @override
  State<_HashtagEditorDialog> createState() => _HashtagEditorDialogState();
}

class _HashtagEditorDialogState extends State<_HashtagEditorDialog> {
  late List<String> _tags;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _controller.text.trim().replaceAll('#', '');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Add Hashtags', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add hashtag',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixText: '#',
                    prefixStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: _addTag,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text('#$tag', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.blue.withOpacity(0.3),
              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
              onDeleted: () => setState(() => _tags.remove(tag)),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSaved(_tags);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _DismissibleSticker extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _DismissibleSticker({required this.child, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

