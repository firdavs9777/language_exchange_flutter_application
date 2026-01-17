import 'dart:io';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Video filter types for applying color effects
enum VideoFilter {
  none,
  warm,
  cool,
  vintage,
  blackAndWhite,
  vivid,
  fade,
}

/// Parameters for video editing operations
class VideoEditParams {
  final File inputFile;
  final Duration? startTime;
  final Duration? endTime;
  final VideoFilter filter;

  VideoEditParams({
    required this.inputFile,
    this.startTime,
    this.endTime,
    this.filter = VideoFilter.none,
  });
}

/// Result of video editing operation
class VideoEditResult {
  final bool success;
  final File? outputFile;
  final String? error;
  final int? originalDurationMs;
  final int? trimmedDurationMs;

  VideoEditResult({
    required this.success,
    this.outputFile,
    this.error,
    this.originalDurationMs,
    this.trimmedDurationMs,
  });
}

/// Service for video editing operations (trimming, filters)
class VideoEditorService {
  static final VideoEditorService _instance = VideoEditorService._internal();
  factory VideoEditorService() => _instance;
  VideoEditorService._internal();

  final Trimmer _trimmer = Trimmer();
  final _uuid = const Uuid();

  /// Load a video file for editing
  Future<void> loadVideo(File videoFile) async {
    await _trimmer.loadVideo(videoFile: videoFile);
  }

  /// Get the trimmer instance for UI binding
  Trimmer get trimmer => _trimmer;

  /// Get video duration in milliseconds
  Future<int> getVideoDuration(File videoFile) async {
    await loadVideo(videoFile);
    // The duration is available after loading
    return _trimmer.videoPlayerController?.value.duration.inMilliseconds ?? 0;
  }

  /// Trim video to specified start and end times
  /// Returns the trimmed video file
  Future<VideoEditResult> trimVideo({
    required File inputFile,
    required double startValue,
    required double endValue,
    Function(String)? onProgress,
  }) async {
    try {
      // Load the video
      await loadVideo(inputFile);

      // Get output directory
      final outputDir = await getTemporaryDirectory();
      final outputFileName = 'trimmed_${_uuid.v4()}.mp4';
      final outputPath = '${outputDir.path}/$outputFileName';

      String? savedPath;

      await _trimmer.saveTrimmedVideo(
        startValue: startValue,
        endValue: endValue,
        onSave: (String? path) {
          savedPath = path;
        },
      );

      // Wait a bit for the save to complete
      await Future.delayed(const Duration(milliseconds: 500));

      if (savedPath != null && await File(savedPath!).exists()) {
        return VideoEditResult(
          success: true,
          outputFile: File(savedPath!),
          originalDurationMs: _trimmer.videoPlayerController?.value.duration.inMilliseconds,
          trimmedDurationMs: (endValue - startValue).toInt(),
        );
      } else {
        // Check if output file exists at expected path
        final expectedFile = File(outputPath);
        if (await expectedFile.exists()) {
          return VideoEditResult(
            success: true,
            outputFile: expectedFile,
            originalDurationMs: _trimmer.videoPlayerController?.value.duration.inMilliseconds,
            trimmedDurationMs: (endValue - startValue).toInt(),
          );
        }

        return VideoEditResult(
          success: false,
          error: 'Failed to save trimmed video',
        );
      }
    } catch (e) {
      print('Error trimming video: $e');
      return VideoEditResult(
        success: false,
        error: 'Error trimming video: $e',
      );
    }
  }

  /// Get color matrix for filter
  List<double> getFilterColorMatrix(VideoFilter filter) {
    switch (filter) {
      case VideoFilter.none:
        return [
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case VideoFilter.warm:
        return [
          1.2, 0.1, 0, 0, 10,
          0, 1.0, 0.1, 0, 5,
          0, 0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case VideoFilter.cool:
        return [
          0.9, 0, 0.1, 0, 0,
          0, 1.0, 0.1, 0, 5,
          0.1, 0.1, 1.2, 0, 10,
          0, 0, 0, 1, 0,
        ];
      case VideoFilter.vintage:
        return [
          0.9, 0.3, 0.1, 0, 20,
          0.1, 0.8, 0.1, 0, 10,
          0.1, 0.1, 0.6, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case VideoFilter.blackAndWhite:
        return [
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case VideoFilter.vivid:
        return [
          1.3, 0, 0, 0, 0,
          0, 1.3, 0, 0, 0,
          0, 0, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case VideoFilter.fade:
        return [
          1.0, 0.1, 0.1, 0, 30,
          0.1, 1.0, 0.1, 0, 30,
          0.1, 0.1, 1.0, 0, 30,
          0, 0, 0, 0.9, 0,
        ];
    }
  }

  /// Get display name for filter
  String getFilterName(VideoFilter filter) {
    switch (filter) {
      case VideoFilter.none:
        return 'Original';
      case VideoFilter.warm:
        return 'Warm';
      case VideoFilter.cool:
        return 'Cool';
      case VideoFilter.vintage:
        return 'Vintage';
      case VideoFilter.blackAndWhite:
        return 'B&W';
      case VideoFilter.vivid:
        return 'Vivid';
      case VideoFilter.fade:
        return 'Fade';
    }
  }

  /// Process video with all edits (trim + filter)
  /// Note: Filter is applied at render time via ColorFilter, not baked into the file
  Future<VideoEditResult> processVideo(VideoEditParams params) async {
    // If no trimming needed, return original file
    if (params.startTime == null && params.endTime == null) {
      return VideoEditResult(
        success: true,
        outputFile: params.inputFile,
      );
    }

    // Trim the video
    return await trimVideo(
      inputFile: params.inputFile,
      startValue: params.startTime?.inMilliseconds.toDouble() ?? 0,
      endValue: params.endTime?.inMilliseconds.toDouble() ??
          (await getVideoDuration(params.inputFile)).toDouble(),
    );
  }

  /// Dispose resources
  void dispose() {
    _trimmer.dispose();
  }
}
