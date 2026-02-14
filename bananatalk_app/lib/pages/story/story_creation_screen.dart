import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

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
      _videoProcessingStatus = '';
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
                AppLocalizations.of(context)!.videoOptimized(result.fileSizeMB.toString(), result.compressionSavings.toStringAsFixed(0)),
              ),
              backgroundColor: AppColors.primary,
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
              content: Text(result.error ?? AppLocalizations.of(context)!.failedToProcessVideo),
              backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
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
        backgroundColor: AppColors.gray900,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Spacing.gapLG,
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
                    backgroundColor: AppColors.gray700,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                if (_videoCompressionProgress > 0)
                  Text(
                    '${_videoCompressionProgress.toStringAsFixed(0)}%',
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.videocam,
                    size: 32,
                    color: AppColors.primary,
                  ),
              ],
            ),
            Spacing.gapXL,
            Text(
              _videoProcessingStatus.isNotEmpty
                  ? _videoProcessingStatus
                  : AppLocalizations.of(context)!.processingVideo,
              style: context.titleSmall.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            Spacing.gapSM,
            Text(
              AppLocalizations.of(context)!.optimizingForBestExperience,
              style: context.bodySmall.copyWith(color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
            Spacing.gapLG,
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectImageOrVideo),
          backgroundColor: AppColors.warning,
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSelectImageOrVideo),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await StoriesService.createStory(
        mediaFiles: mediaToUpload,
        privacy: _privacy,
      );

      debugPrint('Story creation result: success=${result.success}, error=${result.error}');

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.storyCreatedSuccessfully),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Handle specific video errors
        final errorMsg = result.error ?? 'Failed to create story';
        debugPrint('Story creation error: $errorMsg');

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
      debugPrint('Story creation exception: $e');
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
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
                Spacing.hGapMD,
                Text(AppLocalizations.of(context)!.uploadingStoryInBackground),
              ],
            ),
            backgroundColor: AppColors.primary,
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
            backgroundColor: AppColors.error,
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
        backgroundColor: AppColors.gray900,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 28),
            Spacing.hGapMD,
            Expanded(
              child: Text(AppLocalizations.of(context)!.storyCreationFailed, style: context.titleMedium.copyWith(color: AppColors.white)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: Text(
                message,
                style: context.bodySmall.copyWith(color: AppColors.gray300),
              ),
            ),
            Spacing.gapLG,
            Text(
              AppLocalizations.of(context)!.pleaseCheckConnection,
              style: context.bodySmall.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createStory(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  void _showVideoUploadErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray900,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            Spacing.hGapMD,
            Text(AppLocalizations.of(context)!.uploadFailed, style: context.titleMedium.copyWith(color: AppColors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: context.bodyMedium.copyWith(color: AppColors.gray300),
            ),
            Spacing.gapLG,
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  Spacing.hGapSM,
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.tryShorterVideo,
                      style: context.bodySmall.copyWith(color: AppColors.info),
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
            child: Text(AppLocalizations.of(context)!.ok),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createStory(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  void _showStickerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
      SnackBar(content: Text(AppLocalizations.of(context)!.mentionPickerComingSoon)),
    );
  }

  void _showMusicPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.musicPickerComingSoon)),
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
      backgroundColor: AppColors.gray900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
      backgroundColor: AppColors.gray900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
      backgroundColor: AppColors.gray900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
      backgroundColor: AppColors.black,
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
          Text(
            AppLocalizations.of(context)!.createStory,
            style: context.displayMedium.copyWith(color: AppColors.white),
          ),
          Spacing.gapSM,
          Text(
            AppLocalizations.of(context)!.shareMomentsThatDisappear,
            style: context.bodySmall.copyWith(color: AppColors.gray400),
          ),
          Spacing.gapXXL,
          Spacing.gapLG,

          // Media buttons in grid
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.xl,
            alignment: WrapAlignment.center,
            children: [
              // Camera Photo
              _MediaButton(
                icon: Icons.camera_alt,
                label: AppLocalizations.of(context)!.photo,
                onTap: _takePhoto,
              ),
              // Gallery Images
              _MediaButton(
                icon: Icons.photo_library,
                label: AppLocalizations.of(context)!.gallery,
                onTap: _pickMedia,
              ),
              // Video from Gallery
              _MediaButton(
                icon: Icons.videocam,
                label: AppLocalizations.of(context)!.video,
                onTap: _pickVideo,
                color: AppColors.accent,
              ),
              // Record Video
              _MediaButton(
                icon: Icons.fiber_manual_record,
                label: AppLocalizations.of(context)!.record,
                onTap: _recordVideo,
                color: AppColors.error,
              ),
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
        padding: AppSpacing.paddingXXL,
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
              hintText: AppLocalizations.of(context)!.typeSomething,
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
                  : CircularProgressIndicator(color: AppColors.white),
            ),

            // Play/Pause overlay
            if (_videoController!.value.isInitialized &&
                !_videoController!.value.isPlaying)
              Center(
                child: Container(
                  padding: AppSpacing.paddingXL,
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: AppColors.white,
                    size: 50,
                  ),
                ),
              ),

            // Video info badge
            Positioned(
              bottom: 100,
              left: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.6),
                  borderRadius: AppRadius.borderXL,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: AppColors.white, size: 16),
                    Spacing.hGapSM,
                    Text(
                      _videoProcessResult != null
                          ? '${_videoProcessResult!.durationFormatted} | ${_videoProcessResult!.fileSizeMB}MB'
                          : 'Video',
                      style: context.labelSmall.copyWith(color: AppColors.white),
                    ),
                    if (_videoProcessResult?.wasCompressed == true) ...[
                      Spacing.hGapSM,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.borderXS,
                        ),
                        child: Text(
                          'HD',
                          style: context.captionSmall.copyWith(
                            color: AppColors.white,
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
              right: AppSpacing.lg,
              child: GestureDetector(
                onTap: _removeVideo,
                child: Container(
                  padding: AppSpacing.paddingSM,
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: AppColors.white, size: 24),
                ),
              ),
            ),

            // Video progress bar
            if (_videoController!.value.isInitialized)
              Positioned(
                bottom: 80,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: AppColors.white.withOpacity(0.3),
                    backgroundColor: AppColors.white.withOpacity(0.1),
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
      top: MediaQuery.of(context).padding.top + AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          if (_isTextMode) ...[
            IconButton(
              icon: Icon(Icons.color_lens, color: AppColors.white),
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: Icon(Icons.text_format, color: AppColors.white),
              onPressed: _showFontPicker,
            ),
          ],
          if (_mediaFiles.isNotEmpty || _isTextMode)
            IconButton(
              icon: Icon(Icons.sticky_note_2, color: AppColors.white),
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
              padding: AppSpacing.paddingLG,
              child: Stack(
                children: [
                  StoryPollWidget(poll: _poll!, isOwner: true),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppColors.white),
                      onPressed: () => setState(() => _poll = null),
                    ),
                  ),
                ],
              ),
            ),
          if (_questionBox != null)
            Padding(
              padding: AppSpacing.paddingLG,
              child: Stack(
                children: [
                  StoryQuestionBoxWidget(questionBox: _questionBox!, isOwner: true),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppColors.white),
                      onPressed: () => setState(() => _questionBox = null),
                    ),
                  ),
                ],
              ),
            ),
          if (_location != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: _DismissibleSticker(
                onDismiss: () => setState(() => _location = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.borderXL,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: AppColors.error, size: 18),
                      Spacing.hGapXS,
                      Text(_location!.name, style: context.labelMedium.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          if (_link != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: _DismissibleSticker(
                onDismiss: () => setState(() => _link = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: AppRadius.borderXL,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, color: AppColors.white, size: 18),
                      Spacing.hGapXS,
                      Text(_link!.displayText, style: context.labelMedium.copyWith(color: AppColors.white)),
                    ],
                  ),
                ),
              ),
            ),
          if (_hashtags.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                children: _hashtags.map((tag) => Chip(
                  label: Text('#$tag', style: context.labelSmall.copyWith(color: AppColors.white)),
                  backgroundColor: AppColors.info.withOpacity(0.8),
                  deleteIcon: Icon(Icons.close, size: 16, color: AppColors.white),
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
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
          top: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, AppColors.black.withOpacity(0.8)],
          ),
        ),
        child: Row(
          children: [
            // Privacy selector
            GestureDetector(
              onTap: _showPrivacyPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _privacy == StoryPrivacy.closeFriends
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.white.withOpacity(0.2),
                  borderRadius: AppRadius.borderXL,
                  border: _privacy == StoryPrivacy.closeFriends
                      ? Border.all(color: AppColors.success)
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
                          ? AppColors.success
                          : AppColors.white,
                      size: 18,
                    ),
                    Spacing.hGapXS,
                    Text(
                      _privacy.displayName,
                      style: context.labelSmall.copyWith(
                        color: _privacy == StoryPrivacy.closeFriends
                            ? AppColors.success
                            : AppColors.white,
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
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXXL),
              ),
              child: _isCreating
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                    )
                  : Text(AppLocalizations.of(context)!.share, style: context.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.black)),
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
    final buttonColor = color ?? AppColors.gray700;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.3),
              borderRadius: AppRadius.borderXL,
              border: Border.all(color: buttonColor.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color ?? AppColors.white, size: 32),
          ),
          Spacing.gapSM,
          Text(
            label,
            style: context.labelSmall.copyWith(
              color: color ?? AppColors.white,
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
          margin: AppSpacing.paddingMD,
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: AppRadius.borderXS,
          ),
        ),
        Padding(
          padding: AppSpacing.paddingLG,
          child: Text(
            AppLocalizations.of(context)!.addSticker,
            style: context.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          alignment: WrapAlignment.center,
          children: [
            _StickerItem(icon: Icons.poll, label: AppLocalizations.of(context)!.poll, onTap: onPoll),
            _StickerItem(icon: Icons.question_answer, label: AppLocalizations.of(context)!.question, onTap: onQuestion),
            _StickerItem(icon: Icons.location_on, label: AppLocalizations.of(context)!.location, onTap: onLocation),
            _StickerItem(icon: Icons.link, label: AppLocalizations.of(context)!.link, onTap: onLink),
            _StickerItem(icon: Icons.alternate_email, label: AppLocalizations.of(context)!.mention, onTap: onMention),
            _StickerItem(icon: Icons.music_note, label: AppLocalizations.of(context)!.music, onTap: onMusic),
            _StickerItem(icon: Icons.tag, label: AppLocalizations.of(context)!.hashtag, onTap: onHashtag),
          ],
        ),
        Spacing.gapXXL,
        Spacing.gapSM,
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
              color: AppColors.gray800,
              borderRadius: AppRadius.borderLG,
            ),
            child: Icon(icon, color: AppColors.white, size: 28),
          ),
          Spacing.gapXS,
          Text(label, style: context.labelSmall.copyWith(color: AppColors.white)),
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
          margin: AppSpacing.paddingMD,
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: AppRadius.borderXS,
          ),
        ),
        Padding(
          padding: AppSpacing.paddingLG,
          child: Text(
            AppLocalizations.of(context)!.whoCanSeeThis,
            style: context.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
        ),
        _PrivacyOption(
          icon: Icons.public,
          title: AppLocalizations.of(context)!.everyone,
          subtitle: AppLocalizations.of(context)!.anyoneCanSeeStory,
          isSelected: currentPrivacy == StoryPrivacy.everyone,
          onTap: () => onSelected(StoryPrivacy.everyone),
        ),
        _PrivacyOption(
          icon: Icons.people,
          title: AppLocalizations.of(context)!.friendsOnly,
          subtitle: AppLocalizations.of(context)!.onlyFollowersCanSee,
          isSelected: currentPrivacy == StoryPrivacy.friends,
          onTap: () => onSelected(StoryPrivacy.friends),
        ),
        _PrivacyOption(
          icon: Icons.star,
          title: AppLocalizations.of(context)!.closeFriends,
          subtitle: AppLocalizations.of(context)!.onlyCloseFriendsCanSee,
          isSelected: currentPrivacy == StoryPrivacy.closeFriends,
          onTap: () => onSelected(StoryPrivacy.closeFriends),
          isCloseFriends: true,
        ),
        Spacing.gapLG,
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
        padding: AppSpacing.paddingSM,
        decoration: BoxDecoration(
          color: isCloseFriends
              ? AppColors.success.withOpacity(0.2)
              : AppColors.gray800,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isCloseFriends ? AppColors.success : AppColors.white),
      ),
      title: Text(title, style: context.titleSmall.copyWith(color: AppColors.white)),
      subtitle: Text(subtitle, style: context.caption.copyWith(color: AppColors.gray500)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.info)
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
          margin: AppSpacing.paddingMD,
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: AppRadius.borderXS,
          ),
        ),
        Padding(
          padding: AppSpacing.paddingLG,
          child: Text(
            AppLocalizations.of(context)!.backgroundColor,
            style: context.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: AppSpacing.paddingLG,
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
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
                        ? Border.all(color: AppColors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: AppColors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        Spacing.gapLG,
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
          margin: AppSpacing.paddingMD,
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray600,
            borderRadius: AppRadius.borderXS,
          ),
        ),
        Padding(
          padding: AppSpacing.paddingLG,
          child: Text(
            AppLocalizations.of(context)!.fontStyle,
            style: context.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
        ),
        ...[
          ('normal', AppLocalizations.of(context)!.normal, FontWeight.normal, FontStyle.normal),
          ('bold', AppLocalizations.of(context)!.bold, FontWeight.bold, FontStyle.normal),
          ('italic', AppLocalizations.of(context)!.italic, FontWeight.normal, FontStyle.italic),
          ('handwriting', AppLocalizations.of(context)!.handwriting, FontWeight.normal, FontStyle.normal),
        ].map((font) {
          return ListTile(
            title: Text(
              font.$2,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: font.$3,
                fontStyle: font.$4,
                fontFamily: font.$1 == 'handwriting' ? 'Caveat' : null,
                fontSize: 18,
              ),
            ),
            trailing: currentFont == font.$1
                ? Icon(Icons.check_circle, color: AppColors.info)
                : null,
            onTap: () => onSelected(font.$1),
          );
        }),
        Spacing.gapLG,
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
      backgroundColor: AppColors.gray900,
      title: Text(AppLocalizations.of(context)!.addLocation, style: context.titleMedium.copyWith(color: AppColors.white)),
      content: TextField(
        controller: _controller,
        style: context.bodyMedium.copyWith(color: AppColors.white),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterLocationName,
          hintStyle: context.bodyMedium.copyWith(color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.gray800,
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderMD,
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: AppColors.gray400)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) return;
            widget.onSelected(StoryLocation(name: _controller.text.trim()));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: AppColors.white,
          ),
          child: Text(AppLocalizations.of(context)!.add),
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
  final _textController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.gray900,
      title: Text(l10n.addLink, style: context.titleMedium.copyWith(color: AppColors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            style: context.bodyMedium.copyWith(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: context.bodyMedium.copyWith(color: AppColors.gray500),
              filled: true,
              fillColor: AppColors.gray800,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Spacing.gapMD,
          TextField(
            controller: _textController,
            style: context.bodyMedium.copyWith(color: AppColors.white),
            decoration: InputDecoration(
              hintText: l10n.buttonText,
              hintStyle: context.bodyMedium.copyWith(color: AppColors.gray500),
              filled: true,
              fillColor: AppColors.gray800,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: TextStyle(color: AppColors.gray400)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_urlController.text.trim().isEmpty) return;
            widget.onCreated(StoryLink(
              url: _urlController.text.trim(),
              displayText: _textController.text.trim().isEmpty
                  ? l10n.learnMore
                  : _textController.text.trim(),
            ));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: AppColors.white,
          ),
          child: Text(l10n.add),
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.gray900,
      title: Text(l10n.addHashtags, style: context.titleMedium.copyWith(color: AppColors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: context.bodyMedium.copyWith(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: l10n.addHashtag,
                    hintStyle: context.bodyMedium.copyWith(color: AppColors.gray500),
                    prefixText: '#',
                    prefixStyle: context.bodyMedium.copyWith(color: AppColors.white),
                    filled: true,
                    fillColor: AppColors.gray800,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMD,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              Spacing.hGapSM,
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.info),
                onPressed: _addTag,
              ),
            ],
          ),
          Spacing.gapMD,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _tags.map((tag) => Chip(
              label: Text('#$tag', style: context.labelSmall.copyWith(color: AppColors.white)),
              backgroundColor: AppColors.info.withOpacity(0.3),
              deleteIcon: Icon(Icons.close, size: 16, color: AppColors.white),
              onDeleted: () => setState(() => _tags.remove(tag)),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: TextStyle(color: AppColors.gray400)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSaved(_tags);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: AppColors.white,
          ),
          child: Text(l10n.done),
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
              padding: AppSpacing.paddingXS,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: AppColors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}
