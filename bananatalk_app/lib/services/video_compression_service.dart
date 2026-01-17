import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Video compression service for Instagram-like video processing
/// Compresses videos before upload to reduce file size and improve upload speed
class VideoCompressionService {
  static final VideoCompressionService _instance = VideoCompressionService._internal();
  factory VideoCompressionService() => _instance;
  VideoCompressionService._internal();

  /// Subscription for compression progress updates
  Subscription? _subscription;

  /// Maximum video duration in seconds (10 minutes = 600 seconds)
  static const int maxDurationSeconds = 600;

  /// Maximum file size in bytes (1GB)
  static const int maxFileSizeBytes = 1024 * 1024 * 1024;

  /// Target file size after compression (100MB - good balance for mobile upload)
  static const int targetFileSizeBytes = 100 * 1024 * 1024;

  /// Get video information (duration, size, etc.)
  Future<MediaInfo?> getVideoInfo(File videoFile) async {
    try {
      return await VideoCompress.getMediaInfo(videoFile.path);
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }

  /// Check if video needs compression
  Future<bool> needsCompression(File videoFile) async {
    final fileSize = await videoFile.length();

    // If file is larger than target size, compress it
    if (fileSize > targetFileSizeBytes) {
      return true;
    }

    // Get video info to check resolution
    final info = await getVideoInfo(videoFile);
    if (info != null) {
      // Compress if resolution is higher than 1080p
      if ((info.width ?? 0) > 1920 || (info.height ?? 0) > 1080) {
        return true;
      }
    }

    return false;
  }

  /// Validate video duration (max 3 minutes)
  Future<bool> isValidDuration(File videoFile) async {
    final info = await getVideoInfo(videoFile);
    if (info == null) return true; // Allow if we can't get info

    final durationMs = info.duration ?? 0;
    final durationSeconds = durationMs / 1000;

    return durationSeconds <= maxDurationSeconds;
  }

  /// Get video duration in seconds
  Future<double> getVideoDuration(File videoFile) async {
    final info = await getVideoInfo(videoFile);
    if (info == null) return 0;
    return (info.duration ?? 0) / 1000;
  }

  /// Compress video with progress callback
  /// Returns compressed file or original if compression fails
  Future<File> compressVideo(
    File videoFile, {
    Function(double)? onProgress,
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    try {
      // Cancel any existing compression
      await cancelCompression();

      // Set up progress listener
      _subscription = VideoCompress.compressProgress$.subscribe((progress) {
        onProgress?.call(progress);
      });

      // Determine quality based on file size
      final fileSize = await videoFile.length();
      VideoQuality targetQuality = quality;

      if (fileSize > 80 * 1024 * 1024) {
        // Very large file - use lower quality
        targetQuality = VideoQuality.LowQuality;
      } else if (fileSize > 50 * 1024 * 1024) {
        // Large file - use medium quality
        targetQuality = VideoQuality.MediumQuality;
      } else {
        // Normal file - use default quality
        targetQuality = VideoQuality.DefaultQuality;
      }

      // Compress the video
      final MediaInfo? result = await VideoCompress.compressVideo(
        videoFile.path,
        quality: targetQuality,
        deleteOrigin: false, // Keep original file
        includeAudio: true,
        frameRate: 30,
      );

      // Clean up subscription
      _subscription?.unsubscribe();
      _subscription = null;

      if (result != null && result.path != null) {
        final compressedFile = File(result.path!);
        final compressedSize = await compressedFile.length();
        final originalSize = await videoFile.length();

        print('Video compression complete:');
        print('  Original: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');
        print('  Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB');
        print('  Savings: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%');

        return compressedFile;
      }

      // Return original if compression fails
      return videoFile;
    } catch (e) {
      print('Video compression error: $e');
      _subscription?.unsubscribe();
      _subscription = null;
      // Return original file on error
      return videoFile;
    }
  }

  /// Generate video thumbnail
  Future<File?> generateThumbnail(
    File videoFile, {
    int quality = 75,
    int position = 0, // Position in milliseconds
  }) async {
    try {
      final thumbnail = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: quality,
        position: position,
      );
      return thumbnail;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Cancel ongoing compression
  Future<void> cancelCompression() async {
    try {
      await VideoCompress.cancelCompression();
      _subscription?.unsubscribe();
      _subscription = null;
    } catch (e) {
      print('Error canceling compression: $e');
    }
  }

  /// Delete all temporary cache files
  Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      print('Error deleting video cache: $e');
    }
  }

  /// Process video for upload (validate, compress if needed)
  /// Returns processed file and status info
  Future<VideoProcessResult> processVideoForUpload(
    File videoFile, {
    Function(double)? onProgress,
    Function(String)? onStatus,
  }) async {
    try {
      // Check file exists
      if (!await videoFile.exists()) {
        return VideoProcessResult(
          success: false,
          error: 'Video file not found',
        );
      }

      // Check file size
      final originalSize = await videoFile.length();
      if (originalSize > maxFileSizeBytes) {
        onStatus?.call('Video is too large, compressing...');
      }

      // Check duration
      onStatus?.call('Checking video duration...');
      final isValid = await isValidDuration(videoFile);
      if (!isValid) {
        final duration = await getVideoDuration(videoFile);
        return VideoProcessResult(
          success: false,
          error: 'Video is too long (${duration.toStringAsFixed(0)}s). Maximum is ${maxDurationSeconds}s (10 minutes).',
        );
      }

      // Check if compression is needed
      final shouldCompress = await needsCompression(videoFile);

      File processedFile = videoFile;
      if (shouldCompress) {
        onStatus?.call('Compressing video...');
        processedFile = await compressVideo(
          videoFile,
          onProgress: onProgress,
        );
      }

      // Final size check
      final finalSize = await processedFile.length();
      if (finalSize > maxFileSizeBytes) {
        return VideoProcessResult(
          success: false,
          error: 'Video is still too large after compression (${(finalSize / 1024 / 1024).toStringAsFixed(1)}MB). Please use a shorter or lower quality video.',
        );
      }

      // Get final video info
      final info = await getVideoInfo(processedFile);

      onStatus?.call('Video ready for upload');

      return VideoProcessResult(
        success: true,
        processedFile: processedFile,
        originalSize: originalSize,
        processedSize: finalSize,
        duration: info?.duration != null ? info!.duration! / 1000 : null,
        wasCompressed: shouldCompress,
      );
    } catch (e) {
      return VideoProcessResult(
        success: false,
        error: 'Error processing video: $e',
      );
    }
  }
}

/// Result of video processing
class VideoProcessResult {
  final bool success;
  final File? processedFile;
  final int? originalSize;
  final int? processedSize;
  final double? duration;
  final bool wasCompressed;
  final String? error;

  VideoProcessResult({
    required this.success,
    this.processedFile,
    this.originalSize,
    this.processedSize,
    this.duration,
    this.wasCompressed = false,
    this.error,
  });

  /// Get compression savings percentage
  double get compressionSavings {
    if (originalSize == null || processedSize == null || originalSize == 0) {
      return 0;
    }
    return (1 - processedSize! / originalSize!) * 100;
  }

  /// Get file size in MB
  String get fileSizeMB {
    if (processedSize == null) return '0';
    return (processedSize! / 1024 / 1024).toStringAsFixed(1);
  }

  /// Get duration as formatted string
  String get durationFormatted {
    if (duration == null) return '0:00';
    final minutes = (duration! / 60).floor();
    final seconds = (duration! % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
