import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';
import '../../services/video_editor_service.dart';

/// Instagram-like video editor screen with trimming and filters
class VideoEditorScreen extends StatefulWidget {
  final File videoFile;
  final int maxDurationSeconds;

  const VideoEditorScreen({
    Key? key,
    required this.videoFile,
    this.maxDurationSeconds = 600, // 10 minutes default
  }) : super(key: key);

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final VideoEditorService _editorService = VideoEditorService();
  final Trimmer _trimmer = Trimmer();

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isPlaying = false;
  double _startValue = 0.0;
  double _endValue = 0.0;
  VideoFilter _selectedFilter = VideoFilter.none;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      await _trimmer.loadVideo(videoFile: widget.videoFile);

      // Set end value to full duration or max duration
      final duration = _trimmer.videoPlayerController?.value.duration.inMilliseconds.toDouble() ?? 0;
      final maxDuration = widget.maxDurationSeconds * 1000.0;

      setState(() {
        _endValue = duration > maxDuration ? maxDuration : duration;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveVideo() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop playback
      await _trimmer.videoPlayerController?.pause();

      String? savedPath;

      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        onSave: (String? path) {
          savedPath = path;
        },
      );

      // Wait for save to complete
      int attempts = 0;
      while (savedPath == null && attempts < 60) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      setState(() {
        _isProcessing = false;
      });

      if (savedPath != null && mounted) {
        // Return the edited video with filter info
        Navigator.of(context).pop(VideoEditorResult(
          videoFile: File(savedPath!),
          filter: _selectedFilter,
          startTimeMs: _startValue,
          endTimeMs: _endValue,
        ));
      } else {
        _showError('Failed to save video');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error saving video: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _trimmer.videoPlayerController?.pause();
    } else {
      await _trimmer.videoPlayerController?.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  String _formatDuration(double ms) {
    final duration = Duration(milliseconds: ms.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Video',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isProcessing)
            TextButton(
              onPressed: _saveVideo,
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        // Video Preview
                        Expanded(
                          child: GestureDetector(
                            onTap: _togglePlayback,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ColorFiltered(
                                  colorFilter: ColorFilter.matrix(
                                    _editorService.getFilterColorMatrix(_selectedFilter),
                                  ),
                                  child: VideoViewer(trimmer: _trimmer),
                                ),
                                // Play/Pause overlay
                                AnimatedOpacity(
                                  opacity: _isPlaying ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Trim duration display
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.black,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDuration(_startValue),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '-',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              Text(
                                _formatDuration(_endValue),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatDuration(_endValue - _startValue),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trimmer
                        Container(
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TrimViewer(
                            trimmer: _trimmer,
                            viewerHeight: 50,
                            viewerWidth: MediaQuery.of(context).size.width - 16,
                            maxVideoLength: Duration(seconds: widget.maxDurationSeconds),
                            onChangeStart: (value) {
                              setState(() {
                                _startValue = value;
                              });
                            },
                            onChangeEnd: (value) {
                              setState(() {
                                _endValue = value;
                              });
                            },
                            onChangePlaybackState: (value) {
                              setState(() {
                                _isPlaying = value;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Filters
                        Container(
                          height: 100,
                          color: Colors.black,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Filters',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: VideoFilter.values.length,
                                  itemBuilder: (context, index) {
                                    final filter = VideoFilter.values[index];
                                    final isSelected = _selectedFilter == filter;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                      },
                                      child: Container(
                                        width: 60,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.blue
                                                      : Colors.grey.shade700,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(7),
                                                child: ColorFiltered(
                                                  colorFilter: ColorFilter.matrix(
                                                    _editorService.getFilterColorMatrix(filter),
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.orange.shade300,
                                                          Colors.blue.shade300,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _editorService.getFilterName(filter),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.white70,
                                                fontSize: 10,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),

                    // Processing overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Processing video...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
}

/// Result returned from video editor
class VideoEditorResult {
  final File videoFile;
  final VideoFilter filter;
  final double startTimeMs;
  final double endTimeMs;

  VideoEditorResult({
    required this.videoFile,
    required this.filter,
    required this.startTimeMs,
    required this.endTimeMs,
  });

  Duration get trimmedDuration => Duration(
        milliseconds: (endTimeMs - startTimeMs).toInt(),
      );
}
