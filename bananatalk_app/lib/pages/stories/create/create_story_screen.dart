import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/widgets/stories_snackbar.dart';
import 'package:bananatalk_app/pages/stories/create/gradient_picker.dart';
import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';
import 'package:bananatalk_app/pages/stories/create/poll_sticker_editor.dart';
import 'package:bananatalk_app/pages/stories/create/question_sticker_editor.dart';
import 'package:bananatalk_app/pages/stories/create/studio/draw_layer.dart';
import 'package:bananatalk_app/pages/stories/create/studio/filter_bar.dart';
import 'package:bananatalk_app/pages/stories/create/studio/location_picker_sheet.dart';
import 'package:bananatalk_app/pages/stories/create/studio/mention_picker_sheet.dart';
import 'package:bananatalk_app/pages/stories/create/studio/overlay_draft.dart';
import 'package:bananatalk_app/pages/stories/create/studio/story_canvas.dart';
import 'package:bananatalk_app/pages/stories/create/studio/text_overlay_editor.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onStoryCreated;

  const CreateStoryScreen({
    super.key,
    this.onStoryCreated,
  });

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  File? _mediaFile;
  String _mediaType = 'image';
  final TextEditingController _captionController = TextEditingController();
  StoryPrivacy _privacy = StoryPrivacy.everyone;
  bool _isUploading = false;
  String? _selectedColor;
  bool _isTextStory = false;
  String _gradientId = StoryGradient.presets.first.id;

  // Overlay drafts added via the story studio canvas (tap-to-add, drag/pinch, trash-delete).
  final List<OverlayDraft> _overlays = [];

  // Image filters (Task 5): selected preset index into kStoryFilters, and the
  // key of the RepaintBoundary wrapping just the (filtered) image preview —
  // used by bakeImage() to flatten the filter into the uploaded file. It sits
  // inside StoryCanvas's `background` so overlays stay outside it and are
  // never baked in; they travel structurally via `_overlays`.
  int _filterIndex = 0;
  final GlobalKey _bakeKey = GlobalKey();

  // Width/height of the currently selected image, used to size the bake
  // RepaintBoundary to the image's actual displayed rect (see
  // _updateMediaAspect below) instead of inheriting StoryCanvas's
  // full-screen Stack.expand constraint, which would bake in letterbox
  // margins. Null while unknown (video, or decode failure) — falls back to
  // today's full-screen boundary behavior.
  double? _mediaAspect;

  // Freehand drawing (Task 6): strokes live in canvas coordinates and are
  // painted by DrawLayer inside the same RepaintBoundary as the filtered
  // image, so bakeImage() flattens them into the uploaded file exactly like
  // filters. Scoped to image stories only — video has no bake step wired up
  // for drawing, and text stories upload no media file at all (nothing to
  // bake into), so the brush toggle is hidden for both (see `_isVideo` gate
  // on the toolbar button below).
  final List<DrawStroke> _strokes = [];
  bool _drawMode = false;
  Color _drawColor = Colors.white;
  double _drawWidth = 5;
  bool _drawHighlighter = false;

  // Interactive stickers — a story carries at most one of these (matches backend).
  StoryPoll? _poll;
  StoryQuestionBox? _questionBox;

  // Location tag (Task 7) — independent of poll/questionBox, may be combined
  // with either.
  StoryLocation? _pickedLocation;

  // Mentions (Task 9) — up to 5, independent of poll/questionBox/location.
  final List<StoryMention> _mentions = [];
  static const int _maxMentions = 5;

  // Hashtags — chips-style input, capped at 10 (matches backend limit).
  final List<String> _hashtags = [];
  final TextEditingController _hashtagController = TextEditingController();
  static const int _maxHashtags = 10;
  // Whether the hashtag TextField is expanded. Starts collapsed so the
  // bottom toolbar (filter/draw bar + privacy pill + caption + hashtags)
  // doesn't stack a 5th always-visible pill; tapping the compact "Add tags"
  // affordance (or the add-more control once tags exist) reveals it.
  bool _showHashtagInput = false;

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
    _hashtagController.dispose();
    _videoController?.dispose();
    _videoCompressionService.deleteAllCache();
    super.dispose();
  }

  /// Adds the current hashtag field text as a chip (deduped, max [_maxHashtags]).
  void _addHashtag(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'^#+'), '').toLowerCase();
    _hashtagController.clear();
    if (cleaned.isEmpty) return;
    if (_hashtags.contains(cleaned)) return;
    if (_hashtags.length >= _maxHashtags) {
      showStoriesSnackBar(
        context,
        message: 'You can add up to $_maxHashtags hashtags',
        type: StoriesSnackBarType.info,
      );
      return;
    }
    setState(() => _hashtags.add(cleaned));
  }

  void _removeHashtag(String tag) {
    setState(() => _hashtags.remove(tag));
  }

  /// True when the currently selected media file is a video, by the same
  /// type/extension check `_buildPreview` uses. Hoisted out so the top bar's
  /// draw-mode brush button (which must hide for video, per the scope note
  /// on `_strokes` above) can check it without duplicating the preview's
  /// local logic.
  bool get _isVideo =>
      _mediaFile != null &&
      (_mediaType == 'video' ||
          _mediaFile!.path.toLowerCase().endsWith('.mp4') ||
          _mediaFile!.path.toLowerCase().endsWith('.mov') ||
          _mediaFile!.path.toLowerCase().endsWith('.avi') ||
          _mediaFile!.path.toLowerCase().endsWith('.mkv'));

  /// Decodes [file] to learn its width/height ratio and stores it in
  /// [_mediaAspect], so the bake RepaintBoundary can be sized to exactly the
  /// image's displayed rect (see field doc above). Falls back to null
  /// (today's full-screen boundary behavior) on decode failure.
  Future<void> _updateMediaAspect(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      if (mounted) {
        setState(() => _mediaAspect = decoded.width / decoded.height);
      }
      decoded.dispose();
    } catch (_) {
      if (mounted) setState(() => _mediaAspect = null);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _mediaFile = file;
          _mediaType = 'image';
          _isTextStory = false;
          _filterIndex = 0;
          _strokes.clear();
          _drawMode = false;
        });
        _updateMediaAspect(file);
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
        final file = File(pickedFile.path);
        setState(() {
          _mediaFile = file;
          _mediaType = 'image';
          _isTextStory = false;
          _filterIndex = 0;
          _strokes.clear();
          _drawMode = false;
        });
        _updateMediaAspect(file);
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

  /// Runs the current image through the already-shipped image_cropper and
  /// replaces the selected file on success. No-op if the user cancels.
  Future<void> _cropImage() async {
    if (_mediaFile == null) return;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: _mediaFile!.path,
      );
      if (cropped != null && mounted) {
        final file = File(cropped.path);
        setState(() {
          _mediaFile = file;
          _mediaType = 'image';
          _isTextStory = false;
          _filterIndex = 0;
          _strokes.clear();
          _drawMode = false;
          _mediaAspect = null;
        });
        _updateMediaAspect(file);
      }
    } catch (e) {
      if (mounted) {
        showStoriesSnackBar(
          context,
          message: 'Failed to crop image: $e',
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
      _mediaAspect = null;
      _selectedColor = _backgroundColors.first;
      _gradientId = StoryGradient.presets.first.id;
      _overlays.clear();
      _strokes.clear();
      _drawMode = false;
    });
  }

  /// Opens the studio's text overlay editor for [draft]. Shared by the media
  /// preview canvas and the text-story background canvas.
  void _editOverlay(OverlayDraft draft) {
    showTextOverlayEditor(
      context,
      draft,
      onDone: () => setState(() {}),
      onDeleteEmpty: () => setState(() => _overlays.remove(draft)),
    );
  }

  Future<void> _uploadStory() async {
    if (_isTextStory) {
      final hasVisibleOverlay = _overlays.any((o) => o.content.trim().isNotEmpty);
      if (!hasVisibleOverlay) {
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
        // Text-only stories must still send real `text` so older client
        // versions (which render only `story.text`, not `overlays[]`) show
        // the actual content instead of a blank story. Compose it from the
        // text-type overlay drafts; if there are none (e.g. the story is
        // emoji-only), fall back to a single space to satisfy the backend's
        // "media or text required" check — the viewer now suppresses the
        // duplicate centered-text render when overlays are present (see
        // story_viewer_screen.dart's `_buildStoryView`).
        final composedText = _overlays
            .where((o) => o.type == 'text')
            .map((o) => o.content)
            .join('\n');
        final result = await StoriesService.createTextStory(
          text: composedText.trim().isEmpty ? ' ' : composedText,
          backgroundColor: _gradientId,
          fontStyle: 'normal',
          privacy: _privacy,
          hashtags: _hashtags,
          overlays: _overlays.map((o) => o.toJson()).toList(),
          location: _pickedLocation,
          mentions: _mentions,
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
        // Flatten the selected filter into the uploaded file. The
        // RepaintBoundary (_bakeKey) wraps only the image preview inside
        // StoryCanvas's background, so overlays are never baked — they
        // upload structurally via `overlays` below.
        File uploadFile = _mediaFile!;
        if (_mediaType == 'image' &&
            (_filterIndex != 0 || _strokes.isNotEmpty)) {
          uploadFile = await bakeImage(_bakeKey, _mediaFile!);
        }

        // Create media story (image or video)
        final result = await StoriesService.createStory(
          mediaFiles: [uploadFile],
          text: _captionController.text.trim(),
          backgroundColor: _selectedColor,
          privacy: _privacy,
          overlays: _overlays.map((o) => o.toJson()).toList(),
          poll: _poll,
          questionBox: _questionBox,
          hashtags: _hashtags,
          location: _pickedLocation,
          mentions: _mentions,
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
    // The Stories creation flow is an intentionally-dark, Instagram-style
    // editor regardless of the device's system light/dark appearance. Most
    // widgets below hardcode their own dark colors, but forcing the ambient
    // Theme to AppTheme.dark here is belt-and-suspenders: it guarantees any
    // unstyled Material widget (TextField, Chip, etc.) added now or in the
    // future resolves its theme-derived defaults (fill color, chip color,
    // etc.) to dark values instead of silently inheriting the app's global
    // light theme and painting a stray near-white box (see the hashtag
    // input fix below for the concrete bug this caused).
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Text mode (`_buildTextEditor()`) renders its own top-right
          // custom "X" close control (different corner/scope: it exits
          // text mode back to the media picker, not the whole screen).
          // Suppress the auto-inserted back arrow only in that mode so the
          // two controls don't stack; the other modes (media picker, media
          // preview) have no close affordance of their own and still need
          // this back arrow.
          automaticallyImplyLeading: !(_mediaFile == null && _isTextStory),
          title: Text(AppLocalizations.of(context)!.createStory),
          actions: [
            // Drawing (Task 6) is scoped to image stories only — see the
            // `_strokes` field doc for why video/text are excluded.
            if (_mediaFile != null && !_isVideo)
              IconButton(
                tooltip: 'Draw',
                onPressed: () => setState(() => _drawMode = !_drawMode),
                icon: Icon(
                  Icons.brush_rounded,
                  color: _drawMode ? const Color(0xFF00BFA5) : Colors.white,
                ),
              ),
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
      ),
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
    final isVideo = _isVideo;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media preview + tap-to-add / drag / pinch / trash-delete overlays.
        // The RepaintBoundary wraps only the image itself (not the whole
        // canvas stack with its hint text / trash icon) so bakeImage() below
        // flattens just the filter; overlays sit outside it in StoryCanvas's
        // Stack and always travel structurally via `_overlays`.
        //
        // StoryCanvas gives `background` a full-screen Stack.expand
        // constraint, so a bare RepaintBoundary here would capture the
        // whole screen — including the letterbox margins BoxFit.contain
        // leaves around the image. When _mediaAspect is known, an
        // AspectRatio sized to it constrains the boundary to exactly the
        // image's displayed rect; BoxFit.cover then fills that
        // already-matching-aspect box identically to how contain would,
        // so the picture looks the same but bakeImage() captures no
        // margins. Falls back to the old full-screen boundary if the
        // aspect ratio isn't known yet (decode in flight/failed).
        StoryCanvas(
          overlays: _overlays,
          // While drawing, the background's own tap-to-add-overlay and the
          // overlays' drag/pinch must step aside so pan gestures reach the
          // DrawLayer painted inside the boundary below instead of getting
          // contested in the same gesture arena (see `interactive` doc on
          // StoryCanvas).
          interactive: !_drawMode,
          background: isVideo
              ? _buildVideoPreview()
              : Center(
                  child: _mediaAspect == null
                      ? RepaintBoundary(
                          key: _bakeKey,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              applyStoryFilter(
                                _filterIndex,
                                Image.file(
                                  _mediaFile!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // If image fails, it might be a video
                                    return _buildVideoPreview();
                                  },
                                ),
                              ),
                              DrawLayer(
                                strokes: _strokes,
                                enabled: _drawMode,
                                color: _drawColor,
                                width: _drawWidth,
                                highlighter: _drawHighlighter,
                                onChanged: () => setState(() {}),
                              ),
                            ],
                          ),
                        )
                      : AspectRatio(
                          aspectRatio: _mediaAspect!,
                          child: RepaintBoundary(
                            key: _bakeKey,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                applyStoryFilter(
                                  _filterIndex,
                                  Image.file(
                                    _mediaFile!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // If image fails, it might be a video
                                      return _buildVideoPreview();
                                    },
                                  ),
                                ),
                                DrawLayer(
                                  strokes: _strokes,
                                  enabled: _drawMode,
                                  color: _drawColor,
                                  width: _drawWidth,
                                  highlighter: _drawHighlighter,
                                  onChanged: () => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
          onChanged: () => setState(() {}),
          onEditText: _editOverlay,
        ),

        // Caption input at bottom
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              // Filter presets (image stories only) — swapped for the draw
              // toolbar while _drawMode is on.
              if (!isVideo) ...[
                if (_drawMode)
                  DrawToolbar(
                    color: _drawColor,
                    width: _drawWidth,
                    highlighter: _drawHighlighter,
                    onColor: (c) => setState(() => _drawColor = c),
                    onWidth: (w) => setState(() => _drawWidth = w),
                    onHighlighter: (h) => setState(() => _drawHighlighter = h),
                    onUndo: () => setState(() {
                      if (_strokes.isNotEmpty) _strokes.removeLast();
                    }),
                  )
                else
                  FilterBar(
                    selected: _filterIndex,
                    onSelect: (i) => setState(() => _filterIndex = i),
                    preview: FileImage(_mediaFile!),
                  ),
                const SizedBox(height: 8),
              ],

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
              const SizedBox(height: 12),
              _buildHashtagInput(),
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
                _mediaAspect = null;
                _isTextStory = false;
                _overlays.clear();
                _poll = null;
                _questionBox = null;
                _pickedLocation = null;
                _mentions.clear();
                _filterIndex = 0;
                _strokes.clear();
                _drawMode = false;
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

        // Crop + sticker buttons (top-right). Crop is image-only. Text/emoji
        // overlays are now added by tapping directly on the canvas above
        // (studio tap-to-add).
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isVideo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: _cropImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.crop_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _openStickerMenu,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text('Sticker', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Attached sticker chips (poll/question, location, mentions), with
        // quick remove. Independent attachments — several may be present at
        // once — so they stack in a column rather than overwriting the same
        // Positioned slot.
        if (_poll != null ||
            _questionBox != null ||
            _pickedLocation != null ||
            _mentions.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_poll != null || _questionBox != null) ...[
                  _buildAttachedStickerChip(),
                  const SizedBox(height: 8),
                ],
                if (_pickedLocation != null) ...[
                  _buildLocationChip(),
                  const SizedBox(height: 8),
                ],
                if (_mentions.isNotEmpty) _buildMentionChips(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAttachedStickerChip() {
    final isPoll = _poll != null;
    final label = isPoll ? 'Poll: ${_poll!.question}' : 'Question: ${_questionBox!.prompt}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPoll ? Icons.poll : Icons.chat_bubble_outline, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() {
              _poll = null;
              _questionBox = null;
            }),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _pickedLocation!.name,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _pickedLocation = null),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  /// Removable chips for tagged mentions — capped at [_maxMentions] in
  /// [_pickMention], so this only ever renders up to that many.
  Widget _buildMentionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _mentions.map((m) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alternate_email, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  m.username,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _mentions.remove(m)),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Chips-style hashtag input: type a tag and press enter/done to add a
  /// chip; tap the chip's close icon to remove. Capped at [_maxHashtags].
  /// Compact "Add tags" affordance shown instead of the always-visible
  /// hashtag input, so the bottom toolbar isn't stacking a 5th pill when
  /// there's nothing to show yet. Tapping it expands `_buildHashtagInput`'s
  /// full editor via `_showHashtagInput`.
  Widget _buildHashtagAffordance() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => setState(() => _showHashtagInput = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tag, color: Colors.white54, size: 16),
              SizedBox(width: 4),
              Text(
                'Add tags',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagInput() {
    final hasTags = _hashtags.isNotEmpty;
    final atCap = _hashtags.length >= _maxHashtags;
    final showField = _showHashtagInput && !atCap;

    // Collapsed + no tags yet: don't render a pill at all, just the small
    // tap-to-expand affordance (see _buildHashtagAffordance).
    if (!hasTags && !showField) {
      return _buildHashtagAffordance();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTags) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._hashtags.map((tag) {
                  return Chip(
                    label: Text(
                      '#$tag',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                    onDeleted: () => _removeHashtag(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }),
                // Collapsed-but-has-tags: small add-more control instead of
                // always rendering the TextField below.
                if (!showField && !atCap)
                  GestureDetector(
                    onTap: () => setState(() => _showHashtagInput = true),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white70, size: 14),
                    ),
                  ),
              ],
            ),
            if (showField) const SizedBox(height: 6),
          ],
          if (showField)
            TextField(
              controller: _hashtagController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add hashtags...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                // Explicitly disable the theme's default fill so this
                // doesn't inherit InputDecorationTheme.filled/fillColor from
                // whatever ambient Theme is in effect (previously painted a
                // stray near-white box under light system appearance — see
                // build()'s dark Theme wrapper, which is belt-and-suspenders
                // to this explicit override).
                filled: false,
                prefixIcon: Icon(Icons.tag, color: Colors.white54, size: 18),
                prefixIconConstraints: BoxConstraints(minWidth: 26, minHeight: 20),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                _addHashtag(value);
                // "Done" on the keyboard closes the editor back down to the
                // compact chips + add-more view (matches the collapsed
                // steady state once tags exist).
                setState(() => _showHashtagInput = false);
              },
              onChanged: (value) {
                // Also split on comma/space so quick typing "abc, def" works.
                if (value.endsWith(' ') || value.endsWith(',')) {
                  _addHashtag(value);
                }
              },
            ),
        ],
      ),
    );
  }

  void _openStickerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.poll, color: Color(0xFF00BFA5)),
              title: const Text('Poll', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Ask a question with options', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                _openPollEditor();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF00BFA5)),
              title: const Text('Question', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Let viewers send you answers', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                _openQuestionEditor();
              },
            ),
            ListTile(
              leading: const Icon(Icons.place_outlined, color: Color(0xFF00BFA5)),
              title: const Text('Location', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Tag where this story was taken', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                _pickLocation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email, color: Color(0xFF00BFA5)),
              title: const Text('Mention', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Tag someone you follow', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                _pickMention();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openPollEditor() async {
    final result = await Navigator.push<StoryPoll>(
      context,
      MaterialPageRoute(
        builder: (_) => PollStickerEditor(initial: _poll),
      ),
    );
    if (result != null) {
      setState(() {
        _poll = result;
        _questionBox = null; // Mutually exclusive with backend schema
      });
    }
  }

  Future<void> _openQuestionEditor() async {
    final result = await Navigator.push<StoryQuestionBox>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionStickerEditor(initial: _questionBox),
      ),
    );
    if (result != null) {
      setState(() {
        _questionBox = result;
        _poll = null; // Mutually exclusive with backend schema
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await showLocationPickerSheet(context);
    if (result != null && mounted) {
      setState(() => _pickedLocation = result);
    }
  }

  Future<void> _pickMention() async {
    if (_mentions.length >= _maxMentions) {
      showStoriesSnackBar(
        context,
        message: 'You can mention up to $_maxMentions people',
        type: StoriesSnackBarType.info,
      );
      return;
    }
    final result = await showMentionPickerSheet(context, ref);
    if (result != null && mounted) {
      if (_mentions.any((m) => m.userId == result.userId)) return;
      setState(() => _mentions.add(result));
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
                      _overlays.clear();
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

            // Tap anywhere to add a text/emoji overlay on the gradient
            // background; drag/pinch/trash-delete handled by StoryCanvas.
            Expanded(
              child: StoryCanvas(
                overlays: _overlays,
                background: const SizedBox.expand(),
                onChanged: () => setState(() {}),
                onEditText: _editOverlay,
              ),
            ),

            // Gradient picker
            GradientPicker(
              selectedId: _gradientId,
              onChanged: (id) => setState(() => _gradientId = id),
            ),

            // Hashtag chips input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHashtagInput(),
            ),
            const SizedBox(height: 8),

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
    // No full-area tap here: this widget is the `background` handed to
    // StoryCanvas, whose own GestureDetector needs taps to reach it in
    // order to add text/emoji overlays (see StoryCanvas's tap-to-add). A
    // full-area tap on top of it would win the gesture arena and swallow
    // every tap before StoryCanvas ever saw it. Playback is toggled instead
    // via the small button below, which only covers its own 48px circle.
    return Container(
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

          // Play/pause button — small and centered so it doesn't shadow the
          // canvas's tap-to-add gesture the way the old full-area tap did.
          if (_videoController != null && _videoController!.value.isInitialized)
            GestureDetector(
              onTap: _toggleVideoPlayback,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
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
