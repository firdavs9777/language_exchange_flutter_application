import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

/// Storage breakdown by category
class StorageBreakdown {
  final int imageCache;
  final int voiceMessages;
  final int videoCache;
  final int otherCache;
  final int total;

  StorageBreakdown({
    required this.imageCache,
    required this.voiceMessages,
    required this.videoCache,
    required this.otherCache,
  }) : total = imageCache + voiceMessages + videoCache + otherCache;

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Auto-download options
enum AutoDownloadOption {
  always,
  wifiOnly,
  never,
}

/// Service for managing app storage and cache
class StorageService {
  // Preference keys
  static const String _autoDownloadImagesKey = 'auto_download_images';
  static const String _autoDownloadVideosKey = 'auto_download_videos';
  static const String _autoDownloadVoiceKey = 'auto_download_voice';
  static const String _autoDownloadDocumentsKey = 'auto_download_documents';

  /// Calculate total storage breakdown
  static Future<StorageBreakdown> calculateStorageBreakdown() async {
    int imageCache = 0;
    int voiceMessages = 0;
    int videoCache = 0;
    int otherCache = 0;

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Calculate voice recordings size
      final voiceDir = Directory('${tempDir.path}/voice_recordings');
      if (await voiceDir.exists()) {
        voiceMessages = await _getDirectorySize(voiceDir);
      }

      // Calculate video cache (edited videos, compressed videos)
      final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (videoExtensions.any((e) => ext.endsWith(e))) {
            videoCache += await entity.length();
          }
        }
      }

      // Calculate image cache from DefaultCacheManager
      // The cache is stored in a subdirectory
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      if (await cacheDir.exists()) {
        imageCache = await _getDirectorySize(cacheDir);
      }

      // Also check the default cache manager directory
      final defaultCacheDir = Directory('${tempDir.path}/flutter_cache');
      if (await defaultCacheDir.exists()) {
        imageCache += await _getDirectorySize(defaultCacheDir);
      }

      // Calculate other cache (everything else in temp)
      final totalTemp = await _getDirectorySize(tempDir);
      otherCache = totalTemp - imageCache - voiceMessages - videoCache;
      if (otherCache < 0) otherCache = 0;

    } catch (e) {
      debugPrint('Error calculating storage: $e');
    }

    return StorageBreakdown(
      imageCache: imageCache,
      voiceMessages: voiceMessages,
      videoCache: videoCache,
      otherCache: otherCache,
    );
  }

  /// Get directory size recursively
  static Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error getting directory size: $e');
    }
    return size;
  }

  /// Clear image cache
  static Future<void> clearImageCache() async {
    try {
      // Clear flutter_cache_manager cache
      await AppImageCacheManager.clearCache();

      // Clear Flutter's painting cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Also try to clear the cache directories manually
      final tempDir = await getTemporaryDirectory();

      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      final defaultCacheDir = Directory('${tempDir.path}/flutter_cache');
      if (await defaultCacheDir.exists()) {
        await defaultCacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
      rethrow;
    }
  }

  /// Clear voice messages cache
  static Future<void> clearVoiceCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final voiceDir = Directory('${tempDir.path}/voice_recordings');
      if (await voiceDir.exists()) {
        await voiceDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing voice cache: $e');
      rethrow;
    }
  }

  /// Clear video cache
  static Future<void> clearVideoCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];

      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (videoExtensions.any((e) => ext.endsWith(e))) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing video cache: $e');
      rethrow;
    }
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    await clearImageCache();
    await clearVoiceCache();
    await clearVideoCache();
  }

  // ============ Auto-Download Preferences ============

  /// Get auto-download option for images
  static Future<AutoDownloadOption> getAutoDownloadImages() async {
    return _getAutoDownloadOption(_autoDownloadImagesKey, AutoDownloadOption.always);
  }

  /// Set auto-download option for images
  static Future<void> setAutoDownloadImages(AutoDownloadOption option) async {
    await _setAutoDownloadOption(_autoDownloadImagesKey, option);
  }

  /// Get auto-download option for videos
  static Future<AutoDownloadOption> getAutoDownloadVideos() async {
    return _getAutoDownloadOption(_autoDownloadVideosKey, AutoDownloadOption.wifiOnly);
  }

  /// Set auto-download option for videos
  static Future<void> setAutoDownloadVideos(AutoDownloadOption option) async {
    await _setAutoDownloadOption(_autoDownloadVideosKey, option);
  }

  /// Get auto-download option for voice messages
  static Future<AutoDownloadOption> getAutoDownloadVoice() async {
    return _getAutoDownloadOption(_autoDownloadVoiceKey, AutoDownloadOption.always);
  }

  /// Set auto-download option for voice messages
  static Future<void> setAutoDownloadVoice(AutoDownloadOption option) async {
    await _setAutoDownloadOption(_autoDownloadVoiceKey, option);
  }

  /// Get auto-download option for documents
  static Future<AutoDownloadOption> getAutoDownloadDocuments() async {
    return _getAutoDownloadOption(_autoDownloadDocumentsKey, AutoDownloadOption.wifiOnly);
  }

  /// Set auto-download option for documents
  static Future<void> setAutoDownloadDocuments(AutoDownloadOption option) async {
    await _setAutoDownloadOption(_autoDownloadDocumentsKey, option);
  }

  /// Helper to get auto-download option from prefs
  static Future<AutoDownloadOption> _getAutoDownloadOption(
    String key,
    AutoDownloadOption defaultValue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);
    if (value == null) return defaultValue;

    switch (value) {
      case 'always':
        return AutoDownloadOption.always;
      case 'wifiOnly':
        return AutoDownloadOption.wifiOnly;
      case 'never':
        return AutoDownloadOption.never;
      default:
        return defaultValue;
    }
  }

  /// Helper to set auto-download option in prefs
  static Future<void> _setAutoDownloadOption(
    String key,
    AutoDownloadOption option,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (option) {
      case AutoDownloadOption.always:
        value = 'always';
        break;
      case AutoDownloadOption.wifiOnly:
        value = 'wifiOnly';
        break;
      case AutoDownloadOption.never:
        value = 'never';
        break;
    }
    await prefs.setString(key, value);
  }

  /// Check if should auto-download based on current network and preference
  static Future<bool> shouldAutoDownload(String mediaType) async {
    AutoDownloadOption option;

    switch (mediaType) {
      case 'image':
        option = await getAutoDownloadImages();
        break;
      case 'video':
        option = await getAutoDownloadVideos();
        break;
      case 'voice':
      case 'audio':
        option = await getAutoDownloadVoice();
        break;
      case 'document':
        option = await getAutoDownloadDocuments();
        break;
      default:
        option = AutoDownloadOption.always;
    }

    switch (option) {
      case AutoDownloadOption.always:
        return true;
      case AutoDownloadOption.never:
        return false;
      case AutoDownloadOption.wifiOnly:
        return await _isOnWifi();
    }
  }

  /// Check if currently on WiFi
  static Future<bool> _isOnWifi() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.wifi);
    } catch (e) {
      return true; // Default to allowing download on error
    }
  }

  /// Get current network type as string
  static Future<String> getCurrentNetworkType() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (result.contains(ConnectivityResult.mobile)) {
        return 'Mobile Data';
      } else if (result.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else if (result.contains(ConnectivityResult.none)) {
        return 'No Connection';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}
