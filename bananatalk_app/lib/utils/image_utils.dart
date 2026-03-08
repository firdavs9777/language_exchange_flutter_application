import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// Custom cache manager for images with optimized settings
class AppImageCacheManager {
  static const key = 'bananatalkImageCache';

  // Use the default cache manager
  static final BaseCacheManager instance = DefaultCacheManager();

  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }

  /// Remove specific image from cache
  static Future<void> removeFromCache(String url) async {
    await instance.removeFile(url);
  }
}

/// Image quality tiers for different use cases
enum ImageQuality {
  thumbnail, // 200x200 - avatars, grid previews
  medium, // 800x800 - moment full view, list items
  high, // 2400x2400 - full screen gallery, partner cards, chat full images
}

/// Utility class for handling image URLs
class ImageUtils {
  /// Gets the base server URL (without /api/v1/)
  static String get baseServerUrl {
    final baseUrl = Endpoints.baseURL;
    // Remove /api/v1/ from baseURL to get the server root
    if (baseUrl.contains('/api/v1/')) {
      return baseUrl.replaceAll('/api/v1/', '');
    }
    // If it doesn't contain /api/v1/, assume it's already the server root
    return baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  }

  /// Normalizes image URLs from the backend
  /// Handles both relative paths and full URLs
  /// For Google profile images, upgrades quality from 96x96 to 800x800
  static String normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // Decode URL if it's encoded (e.g., https%3A%2F%2F...)
    String decodedUrl = url;
    try {
      if (url.contains('%')) {
        decodedUrl = Uri.decodeComponent(url);
      }
    } catch (e) {
      // If decoding fails, use original URL
      decodedUrl = url;
    }

    // If it's already a full URL (starts with http:// or https://), process it
    if (decodedUrl.startsWith('http://') || decodedUrl.startsWith('https://')) {
      // Upgrade Google profile image quality from 96x96 to 800x800
      // Google URLs contain =s96-c for 96px, change to =s800-c for higher quality
      if (decodedUrl.contains('googleusercontent.com')) {
        // Replace size parameter: =s96-c, =s48-c, etc. → =s800-c
        decodedUrl = decodedUrl.replaceAllMapped(
          RegExp(r'=s\d+-c'),
          (match) => '=s800-c',
        );
      }
      return decodedUrl;
    }

    // If it starts with /, it's a relative path - construct full URL
    if (decodedUrl.startsWith('/')) {
      return '$baseServerUrl$decodedUrl';
    }

    // If it doesn't start with /, assume it's a filename in /uploads
    // Ensure the path starts with /uploads/
    if (!decodedUrl.startsWith('uploads/') && !decodedUrl.startsWith('/uploads/')) {
      return '$baseServerUrl/uploads/$decodedUrl';
    }
    return '$baseServerUrl/$decodedUrl';
  }

  /// Normalizes a list of image URLs
  static List<String> normalizeImageUrls(List<String>? urls) {
    if (urls == null || urls.isEmpty) {
      return [];
    }
    return urls
        .map((url) => normalizeImageUrl(url))
        .where((url) => url.isNotEmpty)
        .toList();
  }

  /// Checks if an image URL is valid
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    // Check if it's a valid URL format
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/') ||
        url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.gif') ||
        url.contains('.webp');
  }

  /// Get cache dimensions based on quality tier
  static int getCacheDimension(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.thumbnail:
        return 200;
      case ImageQuality.medium:
        return 800;
      case ImageQuality.high:
        return 2400; // Sharp on high-res phones (iPhone Pro Max, etc.)
    }
  }

  /// Preload a single image into cache
  static Future<void> preloadImage(
    String? url, {
    ImageQuality quality = ImageQuality.medium,
  }) async {
    if (url == null || url.isEmpty) return;

    final normalizedUrl = normalizeImageUrl(url);
    if (normalizedUrl.isEmpty) return;

    try {
      await AppImageCacheManager.instance.downloadFile(normalizedUrl);
    } catch (e) {
      // Silently fail - preloading is best effort
    }
  }

  /// Preload multiple images into cache
  static Future<void> preloadImages(
    List<String?> urls, {
    ImageQuality quality = ImageQuality.medium,
    int maxConcurrent = 3,
  }) async {
    final validUrls = urls
        .where((url) => url != null && url.isNotEmpty)
        .map((url) => normalizeImageUrl(url!))
        .where((url) => url.isNotEmpty)
        .toList();

    // Process in batches to avoid overwhelming the network
    for (var i = 0; i < validUrls.length; i += maxConcurrent) {
      final batch = validUrls.skip(i).take(maxConcurrent);
      await Future.wait(
        batch.map((url) async {
          try {
            await AppImageCacheManager.instance.downloadFile(url);
          } catch (e) {
            // Silently fail
          }
        }),
      );
    }
  }

  /// Preload images that are visible in a list
  static void preloadVisibleImages(
    BuildContext context,
    List<String?> urls, {
    int preloadCount = 5,
  }) {
    final imagesToPreload = urls.take(preloadCount).toList();
    preloadImages(imagesToPreload, quality: ImageQuality.thumbnail);
  }

  /// Precache image for Flutter's image cache (for immediate display)
  static Future<void> precacheImage(
    BuildContext context,
    String? url,
  ) async {
    if (url == null || url.isEmpty) return;

    final normalizedUrl = normalizeImageUrl(url);
    if (normalizedUrl.isEmpty) return;

    try {
      await precacheImage(
        context,
        normalizedUrl,
      );
    } catch (e) {
      // Silently fail
    }
  }
}

/// Extension for easy image preloading from providers
extension ImagePreloadExtension on List<String?> {
  /// Preload first N images
  Future<void> preloadFirst(int count) async {
    await ImageUtils.preloadImages(take(count).toList());
  }
}

